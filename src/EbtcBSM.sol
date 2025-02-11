// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEbtcToken} from "./Dependencies/IEbtcToken.sol";
import {IEbtcBSM} from "./Dependencies/IEbtcBSM.sol";
import {IMintingConstraint} from "./Dependencies/IMintingConstraint.sol";
import {IAssetVault} from "./Dependencies/IAssetVault.sol";
import {BaseAssetVault} from "./BaseAssetVault.sol";

contract EbtcBSM is IEbtcBSM, Pausable, AuthNoOwner, Initializable {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10000;
    uint256 public constant MAX_FEE = 2000;

    // Immutables
    IERC20 public immutable ASSET_TOKEN;
    IEbtcToken public immutable EBTC_TOKEN;
    address public immutable FEE_RECIPIENT;

    uint256 public feeToSellBPS;
    uint256 public feeToBuyBPS;
    uint256 public totalMinted;
    IAssetVault public assetVault;
    IMintingConstraint public oraclePriceConstraint;
    IMintingConstraint public rateLimitingConstraint;

    error InsufficientAssetTokens(uint256 required, uint256 available);

    /**
     * @notice Contract constructor
     * @param _assetToken Address of the underlying asset token
     * @param _oraclePriceConstraint Address of the oracle price constraint
     * @param _rateLimitingConstraint address of the rate limiting constraint
     * @param _ebtcToken Address of the eBTC token
     * @param _feeRecipient Address to receive fees
     * @param _governance Address of the eBTC governor
     */
    constructor(
        address _assetToken,
        address _oraclePriceConstraint,
        address _rateLimitingConstraint,
        address _ebtcToken,
        address _feeRecipient,
        address _governance
    ) {
        require(_assetToken != address(0));
        require(_oraclePriceConstraint != address(0));
        require(_rateLimitingConstraint != address(0));
        require(_ebtcToken != address(0));
        require(_feeRecipient != address(0));
        require(_governance != address(0));

        ASSET_TOKEN = IERC20(_assetToken);
        oraclePriceConstraint = IMintingConstraint(_oraclePriceConstraint);
        rateLimitingConstraint = IMintingConstraint(_rateLimitingConstraint);
        EBTC_TOKEN = IEbtcToken(_ebtcToken);
        FEE_RECIPIENT = _feeRecipient;
        _initializeAuthority(_governance);
    }
    
    // This function will be invoked only once within the same transaction as the deployment of this contract, 
    // thereby preventing any other user from executing this function.
    function initialize(address _assetVault) initializer external {
       assetVault = IAssetVault(_assetVault);
    }

    function _feeToBuy(uint256 _amount) private view returns (uint256) {
        return (_amount * feeToBuyBPS) / BPS;
    }

    function _feeToSell(uint256 _amount) private view returns (uint256) {
        uint256 fee = feeToSellBPS;
        return (_amount * fee) / (fee + BPS);
    }

    function _previewSellAsset(
        uint256 _assetAmountIn,
        uint256 feeAmount
    ) private view returns (uint256 _ebtcAmountOut) {
        // TODO: figure out if it's possible to check oracle and minting cap here
        _ebtcAmountOut = _assetAmountIn - feeAmount;
    }

    function _previewBuyAsset(
        uint256 _ebtcAmountIn,
        uint256 feeAmount
    ) private view returns (uint256 _assetAmountOut) {
        // ebtc to asset price is treated as 1 for buyAsset
        uint256 depositAmount = assetVault.depositAmount();
        if (_ebtcAmountIn > depositAmount) {
            revert InsufficientAssetTokens(_ebtcAmountIn, depositAmount);
        }

        _assetAmountOut = assetVault.previewWithdraw(_ebtcAmountIn) - feeAmount;
    }

    function _checkMintingConstraints(uint256 amountToMint) private {
        bool success;
        bytes memory errData;

        (success, errData) = oraclePriceConstraint.canMint(amountToMint, address(this));

        if (!success) {
            revert IMintingConstraint.MintingConstraintCheckFailed(
                address(oraclePriceConstraint),
                amountToMint,
                address(this),
                errData
            );
        }

        (success, errData) = rateLimitingConstraint.canMint(amountToMint, address(this));

        if (!success) {
            revert IMintingConstraint.MintingConstraintCheckFailed(
                address(rateLimitingConstraint),
                amountToMint,
                address(this),
                errData
            );
        }
    }

    function _sellAsset(
        uint256 _assetAmountIn,
        address recipient,
        uint256 feeAmount
    ) internal returns (uint256 _ebtcAmountOut) {
        _ebtcAmountOut = _assetAmountIn - feeAmount;

        _checkMintingConstraints(_ebtcAmountOut);

        // INVARIANT: _assetAmountIn >= _ebtcAmountOut
        ASSET_TOKEN.safeTransferFrom(
            msg.sender,
            address(assetVault),
            _assetAmountIn
        );
        assetVault.afterDeposit(_ebtcAmountOut, feeAmount); // depositAmount = _assetAmountIn - fee

        totalMinted += _ebtcAmountOut;

        EBTC_TOKEN.mint(recipient, _ebtcAmountOut);

        emit AssetSold(_assetAmountIn, _ebtcAmountOut, feeAmount);
    }

    function _buyAsset(
        uint256 _ebtcAmountIn,
        address recipient,
        uint256 feeAmount
    ) internal returns (uint256 _assetAmountOut) {
        // ebtc to asset price is treated as 1 for buyAsset
        uint256 depositAmount = assetVault.depositAmount();
        if (_ebtcAmountIn > depositAmount) {
            revert InsufficientAssetTokens(_ebtcAmountIn, depositAmount);
        }

        EBTC_TOKEN.burn(msg.sender, _ebtcAmountIn);

        totalMinted -= _ebtcAmountIn;

        uint256 redeemedAmount = assetVault.beforeWithdraw(
            _ebtcAmountIn,
            feeAmount
        );

        _assetAmountOut = redeemedAmount - feeAmount;
        // INVARIANT: _assetAmountOut <= _ebtcAmountIn
        ASSET_TOKEN.safeTransferFrom(
            address(assetVault),
            recipient,
            _assetAmountOut
        );

        emit AssetBought(_ebtcAmountIn, _assetAmountOut, feeAmount);
    }

    function previewSellAsset(
        uint256 _assetAmountIn
    ) external returns (uint256 _ebtcAmountOut) {
        return _previewSellAsset(_assetAmountIn, _feeToSell(_assetAmountIn));
    }

    function previewBuyAsset(
        uint256 _ebtcAmountIn
    ) external returns (uint256 _assetAmountOut) {
        return _previewBuyAsset(_ebtcAmountIn, _feeToBuy(_ebtcAmountIn));
    }

    /**
     * @notice Allows users to mint eBTC by depositing asset tokens
     * @dev This function assumes the exchange rate between the asset token and eBTC is 1:1
     *
     * @param _assetAmountIn Amount of asset tokens to deposit
     * @return _ebtcAmountOut Amount of eBTC tokens minted to the user
     */
    function sellAsset(
        uint256 _assetAmountIn,
        address recipient
    ) external whenNotPaused returns (uint256 _ebtcAmountOut) {
        return
            _sellAsset(_assetAmountIn, recipient, _feeToSell(_assetAmountIn));
    }

    /**
     * @notice Allows users to buy BSM owned asset tokens by burning their eBTC
     * @dev This function assumes the exchange rate between the asset token and eBTC is 1:1
     *
     * @param _ebtcAmountIn Amount of eBTC tokens to burn
     * @return _assetAmountOut Amount of asset tokens sent to user
     */
    function buyAsset(
        uint256 _ebtcAmountIn,
        address recipient
    ) external whenNotPaused returns (uint256 _assetAmountOut) {
        return _buyAsset(_ebtcAmountIn, recipient, _feeToBuy(_ebtcAmountIn));
    }

    function sellAssetNoFee(
        uint256 _assetAmountIn,
        address recipient
    ) external whenNotPaused requiresAuth returns (uint256 _ebtcAmountOut) {
        return _sellAsset(_assetAmountIn, recipient, 0);
    }

    function buyAssetNoFee(
        uint256 _ebtcAmountIn,
        address recipient
    ) external whenNotPaused requiresAuth returns (uint256 _assetAmountOut) {
        return _buyAsset(_ebtcAmountIn, recipient, 0);
    }

    function setFeeToSell(uint256 _feeToSellBPS) external requiresAuth {
        require(_feeToSellBPS <= MAX_FEE);
        emit FeeToSellUpdated(feeToSellBPS, _feeToSellBPS);
        feeToSellBPS = _feeToSellBPS;
    }

    function setFeeToBuy(uint256 _feeToBuyBPS) external requiresAuth {
        require(_feeToBuyBPS <= MAX_FEE);
        emit FeeToBuyUpdated(feeToBuyBPS, _feeToBuyBPS);
        feeToBuyBPS = _feeToBuyBPS;
    }

    function setRateLimitingConstraint(address _rateLimitingConstraint) external requiresAuth {
        require(_rateLimitingConstraint != address(0));
        emit IMintingConstraint.MintingConstraintUpdated(address(rateLimitingConstraint), _rateLimitingConstraint);
        rateLimitingConstraint = IMintingConstraint(_rateLimitingConstraint);
    }

    function setOraclePriceConstraint(address _oraclePriceConstraint) external requiresAuth {
        require(_oraclePriceConstraint != address(0));
        emit IMintingConstraint.MintingConstraintUpdated(address(oraclePriceConstraint), _oraclePriceConstraint);
        oraclePriceConstraint = IMintingConstraint(_oraclePriceConstraint);
    }

    /// @notice Updates the asset vault address and initiates a vault migration
    /// @param newVault new asset vault address
    function updateAssetVault(address newVault) external requiresAuth {
        require(newVault != address(0));

        uint256 totalBalance = assetVault.totalBalance();
        if (totalBalance > 0) {
            /// @dev cache deposit amount (will be set to 0 after migrateTo())
            uint256 depositAmount = assetVault.depositAmount();

            /// @dev transfer liquidity to new vault
            assetVault.migrateTo(newVault);

            /// @dev set depositAmount on the new vault (fee amount should be 0 here)
            IAssetVault(newVault).setDepositAmount(depositAmount);
        }

        emit AssetVaultUpdated(address(assetVault), newVault);
        assetVault = IAssetVault(newVault);
    }

    function pause() external requiresAuth {
        _pause();
    }

    function unpause() external requiresAuth {
        _unpause();
    }
}
