// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEbtcToken} from "./Dependencies/IEbtcToken.sol";
import {IEbtcBSM} from "./Dependencies/IEbtcBSM.sol";
import {IMintingConstraint} from "./Dependencies/IMintingConstraint.sol";
import {IEscrow} from "./Dependencies/IEscrow.sol";

contract EbtcBSM is IEbtcBSM, Pausable, Initializable, AuthNoOwner {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10000;
    uint256 public constant MAX_FEE = 2000;

    // Immutables
    IERC20 public immutable ASSET_TOKEN;
    IEbtcToken public immutable EBTC_TOKEN;

    uint256 public feeToSellBPS;
    uint256 public feeToBuyBPS;
    uint256 public totalMinted;
    IEscrow public escrow;
    IMintingConstraint public oraclePriceConstraint;
    IMintingConstraint public rateLimitingConstraint;

    error InsufficientAssetTokens(uint256 required, uint256 available);

    /**
     * @notice Contract constructor
     * @param _assetToken Address of the underlying asset token
     * @param _oraclePriceConstraint Address of the oracle price constraint
     * @param _rateLimitingConstraint address of the rate limiting constraint
     * @param _ebtcToken Address of the eBTC token
     * @param _governance Address of the eBTC governor
     */
    constructor(
        address _assetToken,
        address _oraclePriceConstraint,
        address _rateLimitingConstraint,
        address _ebtcToken,
        address _governance
    ) {
        require(_assetToken != address(0));
        require(_oraclePriceConstraint != address(0));
        require(_rateLimitingConstraint != address(0));
        require(_ebtcToken != address(0));
        require(_governance != address(0));

        ASSET_TOKEN = IERC20(_assetToken);
        oraclePriceConstraint = IMintingConstraint(_oraclePriceConstraint);
        rateLimitingConstraint = IMintingConstraint(_rateLimitingConstraint);
        EBTC_TOKEN = IEbtcToken(_ebtcToken);
        _initializeAuthority(_governance);
    }
    
    /// @notice This function will be invoked only once within the same transaction as the deployment of
    // this contract, thereby preventing any other user from executing this function.
    function initialize(address _escrow) initializer external {
        require(_escrow != address(0));
        escrow = IEscrow(_escrow);
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
        uint256 _feeAmount
    ) private view returns (uint256 _ebtcAmountOut) {
        _ebtcAmountOut = _assetAmountIn - _feeAmount;
        _checkMintingConstraints(_ebtcAmountOut);
    }

    function _previewBuyAsset(
        uint256 _ebtcAmountIn,
        uint256 _feeAmount
    ) private view returns (uint256 _assetAmountOut) {
        _checkTotalAssetsDeposited(_ebtcAmountIn);
        _assetAmountOut = escrow.previewWithdraw(_ebtcAmountIn) - _feeAmount;
    }

    function _checkTotalAssetsDeposited(uint256 amountToBuy) private view {
        // ebtc to asset price is treated as 1 for buyAsset
        uint256 totalAssetsDeposited = escrow.totalAssetsDeposited();
        if (amountToBuy > totalAssetsDeposited) {
            revert InsufficientAssetTokens(amountToBuy, totalAssetsDeposited);
        }
    }

    function _checkMintingConstraints(uint256 _amountToMint) private view {
        bool success;
        bytes memory errData;

        (success, errData) = oraclePriceConstraint.canMint(_amountToMint, address(this));

        if (!success) {
            revert IMintingConstraint.MintingConstraintCheckFailed(
                address(oraclePriceConstraint),
                _amountToMint,
                address(this),
                errData
            );
        }

        (success, errData) = rateLimitingConstraint.canMint(_amountToMint, address(this));

        if (!success) {
            revert IMintingConstraint.MintingConstraintCheckFailed(
                address(rateLimitingConstraint),
                _amountToMint,
                address(this),
                errData
            );
        }
    }

    function _sellAsset(
        uint256 _assetAmountIn,
        address _recipient,
        uint256 _feeAmount
    ) internal returns (uint256 _ebtcAmountOut) {
        _ebtcAmountOut = _assetAmountIn - _feeAmount;

        _checkMintingConstraints(_ebtcAmountOut);

        // INVARIANT: _assetAmountIn >= _ebtcAmountOut
        ASSET_TOKEN.safeTransferFrom(
            msg.sender,
            address(escrow),
            _assetAmountIn
        );
        escrow.onDeposit(_ebtcAmountOut); // ebtcMinted = _assetAmountIn - fee

        totalMinted += _ebtcAmountOut;

        EBTC_TOKEN.mint(_recipient, _ebtcAmountOut);

        emit AssetSold(_assetAmountIn, _ebtcAmountOut, _feeAmount);
    }

    function _buyAsset(
        uint256 _ebtcAmountIn,
        address _recipient,
        uint256 _feeAmount
    ) internal returns (uint256 _assetAmountOut) {
        _checkTotalAssetsDeposited(_ebtcAmountIn);

        EBTC_TOKEN.burn(msg.sender, _ebtcAmountIn);

        totalMinted -= _ebtcAmountIn;

        uint256 redeemedAmount = escrow.onWithdraw(
            _ebtcAmountIn
        );

        _assetAmountOut = redeemedAmount - _feeAmount;
        // INVARIANT: _assetAmountOut <= _ebtcAmountIn
        ASSET_TOKEN.safeTransferFrom(
            address(escrow),
            _recipient,
            _assetAmountOut
        );

        emit AssetBought(_ebtcAmountIn, _assetAmountOut, _feeAmount);
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
     * @param _recipient custom recipient for the minted eBTC
     * @return _ebtcAmountOut Amount of eBTC tokens minted to the user
     */
    function sellAsset(
        uint256 _assetAmountIn,
        address _recipient
    ) external whenNotPaused returns (uint256 _ebtcAmountOut) {
        return
            _sellAsset(_assetAmountIn, _recipient, _feeToSell(_assetAmountIn));
    }

    /**
     * @notice Allows users to buy BSM owned asset tokens by burning their eBTC
     * @dev This function assumes the exchange rate between the asset token and eBTC is 1:1
     *
     * @param _ebtcAmountIn Amount of eBTC tokens to burn
     * @param _recipient custom recipient for the asset
     * @return _assetAmountOut Amount of asset tokens sent to user
     */
    function buyAsset(
        uint256 _ebtcAmountIn,
        address _recipient
    ) external whenNotPaused returns (uint256 _assetAmountOut) {
        return _buyAsset(_ebtcAmountIn, _recipient, _feeToBuy(_ebtcAmountIn));
    }

    function sellAssetNoFee(
        uint256 _assetAmountIn,
        address _recipient
    ) external whenNotPaused requiresAuth returns (uint256 _ebtcAmountOut) {
        return _sellAsset(_assetAmountIn, _recipient, 0);
    }

    function buyAssetNoFee(
        uint256 _ebtcAmountIn,
        address _recipient
    ) external whenNotPaused requiresAuth returns (uint256 _assetAmountOut) {
        return _buyAsset(_ebtcAmountIn, _recipient, 0);
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

    function setRateLimitingConstraint(address _newRateLimitingConstraint) external requiresAuth {
        require(_newRateLimitingConstraint != address(0));
        emit IMintingConstraint.MintingConstraintUpdated(address(rateLimitingConstraint), _newRateLimitingConstraint);
        rateLimitingConstraint = IMintingConstraint(_newRateLimitingConstraint);
    }

    function setOraclePriceConstraint(address _newOraclePriceConstraint) external requiresAuth {
        require(_newOraclePriceConstraint != address(0));
        emit IMintingConstraint.MintingConstraintUpdated(address(oraclePriceConstraint), _newOraclePriceConstraint);
        oraclePriceConstraint = IMintingConstraint(_newOraclePriceConstraint);
    }

    /// @notice Updates the escrow address and initiates an escrow migration
    /// @param _newEscrow new escrow address
    function updateEscrow(address _newEscrow) external requiresAuth {
        require(_newEscrow != address(0));

        uint256 totalBalance = escrow.totalBalance();
        if (totalBalance > 0) {
            /// @dev cache deposit amount (will be set to 0 after migrateTo())
            uint256 totalAssetsDeposited = escrow.totalAssetsDeposited();

            /// @dev transfer liquidity to new vault
            escrow.onMigrateSource(_newEscrow);

            /// @dev set totalAssetsDeposited on the new vault (fee amount should be 0 here)
            IEscrow(_newEscrow).onMigrateTarget(totalAssetsDeposited);
        }

        emit EscrowUpdated(address(escrow), _newEscrow);
        escrow = IEscrow(_newEscrow);
    }

    function pause() external requiresAuth {
        _pause();
    }

    function unpause() external requiresAuth {
        _unpause();
    }
}
