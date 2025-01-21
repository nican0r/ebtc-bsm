// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEbtcToken} from "./Dependencies/IEbtcToken.sol";
import {IActivePool} from "./Dependencies/IActivePool.sol";
import {IOracleModule} from "./Dependencies/IOracleModule.sol";
import {IAssetVault, BaseAssetVault} from "./BaseAssetVault.sol";

contract EbtcBSM is Pausable, AuthNoOwner {
    using SafeERC20 for IERC20;

    uint256 public constant BPS = 10000;
    uint256 public constant MAX_FEE = 2000;

    // Immutables
    IERC20 public immutable ASSET_TOKEN;
    IOracleModule public immutable ORACLE_MODULE;
    IEbtcToken public immutable EBTC_TOKEN;
    IActivePool public immutable ACTIVE_POOL;
    address public immutable FEE_RECIPIENT;

    uint256 public feeToBuyEbtcBPS;
    uint256 public feeToBuyAssetBPS;
    /// @notice minting cap % of ebtc total supply TWAP
    uint256 public mintingCapBPS;
    uint256 public totalMinted;
    mapping(address => bool) authorizedUsers;
    IAssetVault public assetVault;

    event AssetVaultUpdated(address indexed oldVault, address indexed newVault);
    event MintingCapUpdated(uint256 oldCap, uint256 newCap);
    event FeeToBuyEbtcUpdated(uint256 oldFee, uint256 newFee);
    event FeeToBuyAssetUpdated(uint256 oldFee, uint256 newFee);
    event AssetSold(uint256 ebtcAmountOut, uint256 assetAmountIn, uint256 feeAmount);
    event AssetBought(uint256 ebtcAmountIn, uint256 assetAmountOut, uint256 feeAmount);
    event AuthorizedUserAdded(address indexed user);
    event AuthorizedUserRemoved(address indexed user);

    error AboveMintingCap(
        uint256 amountToMint,
        uint256 newTotalToMint,
        uint256 maxMint
    );
    error BadOracleRate();
    error InsufficientAssetTokens(uint256 required, uint256 available);

    /**
     * @notice Contract constructor
     * @param _assetToken Address of the underlying asset token
     * @param _oracleModule Address of the oracle module
     * @param _ebtcToken Address of the eBTC token
     * @param _activePool Address of the active pool
     * @param _feeRecipient Address to receive fees
     * @param _governance Address of the eBTC governor
     */
    constructor(
        address _assetToken,
        address _oracleModule,
        address _ebtcToken,
        address _activePool,
        address _feeRecipient,
        address _governance
    ) {
        require(_assetToken != address(0));
        require(_oracleModule != address(0));
        require(_ebtcToken != address(0));
        require(_activePool != address(0));
        require(_feeRecipient != address(0));
        require(_governance != address(0));

        ASSET_TOKEN = IERC20(_assetToken);
        ORACLE_MODULE = IOracleModule(_oracleModule);
        EBTC_TOKEN = IEbtcToken(_ebtcToken);
        ACTIVE_POOL = IActivePool(_activePool);
        FEE_RECIPIENT = _feeRecipient;
        _initializeAuthority(_governance);

        assetVault = IAssetVault(
            address(
                new BaseAssetVault(
                    _assetToken,
                    address(this),
                    _governance,
                    FEE_RECIPIENT
                )
            )
        );
    }

    function _checkMintingCap(uint256 _amountToMint) private {
        uint256 totalEbtcSupply = ACTIVE_POOL.observe();
        uint256 maxMint = (totalEbtcSupply * mintingCapBPS) / BPS;
        uint256 newTotalToMint = totalMinted + _amountToMint;

        if (newTotalToMint > maxMint) {
            revert AboveMintingCap(_amountToMint, newTotalToMint, maxMint);
        }
    }

    function _feeToBuyAsset(uint256 _amount) private view returns (uint256) {
        if (authorizedUsers[msg.sender]) return 0;
        return (_amount * feeToBuyAssetBPS) / BPS;
    }

    function _feeToBuyEbtc(uint256 _amount) private view returns (uint256) {
        if (authorizedUsers[msg.sender]) return 0;
        uint256 fee = feeToBuyEbtcBPS;
        return _amount * fee / (fee + BPS);
    }

    /**
     * @notice Allows users to mint eBTC by depositing asset tokens
     * @dev This function assumes the exchange rate between the asset token and eBTC is 1:1
     * 
     * @param _assetAmountIn Amount of asset tokens to deposit
     * @return _ebtcAmountOut Amount of eBTC tokens minted to the user
     */
    function buyEbtcWithAsset(uint256 _assetAmountIn) external whenNotPaused returns (uint256 _ebtcAmountOut) {
        if (!ORACLE_MODULE.canMint()) {
            revert BadOracleRate();
        }

        uint256 feeAmount = _feeToBuyEbtc(_assetAmountIn);

        _ebtcAmountOut = _assetAmountIn - feeAmount;

        // asset to ebtc price is treated as 1 if oracle check passes
        _checkMintingCap(_ebtcAmountOut);

        // INVARIANT: _assetAmountIn >= _ebtcAmountOut
        ASSET_TOKEN.safeTransferFrom(
            msg.sender,
            address(assetVault),
            _assetAmountIn
        );
        assetVault.afterDeposit(_ebtcAmountOut, feeAmount); // depositAmount = _assetAmountIn - fee

        totalMinted += _ebtcAmountOut;

        EBTC_TOKEN.mint(msg.sender, _ebtcAmountOut);

        emit AssetSold(_ebtcAmountOut, _assetAmountIn, feeAmount);
    }

    /**
     * @notice Allows users to buy BSM owned asset tokens by burning their eBTC
     * @dev This function assumes the exchange rate between the asset token and eBTC is 1:1
     * 
     * @param _ebtcAmountIn Amount of eBTC tokens to burn
     * @return _assetAmountOut Amount of asset tokens sent to user
     */
    function buyAssetWithEbtc(uint256 _ebtcAmountIn) external whenNotPaused returns (uint256 _assetAmountOut) {
        // ebtc to asset price is treated as 1 for buyAsset
        uint256 depositAmount = assetVault.depositAmount();
        if (_ebtcAmountIn > depositAmount) {
            revert InsufficientAssetTokens(_ebtcAmountIn, depositAmount);
        }

        EBTC_TOKEN.burn(msg.sender, _ebtcAmountIn);

        totalMinted -= _ebtcAmountIn;

        uint256 feeAmount = _feeToBuyAsset(_ebtcAmountIn);
        _assetAmountOut = _ebtcAmountIn - feeAmount;
        assetVault.beforeWithdraw(_ebtcAmountIn, feeAmount);
        // INVARIANT: _assetAmountOut <= _ebtcAmountIn
        ASSET_TOKEN.safeTransferFrom(
            address(assetVault),
            msg.sender,
            _assetAmountOut
        );

        emit AssetBought(_ebtcAmountIn, _assetAmountOut, feeAmount);
    }

    function setFeeToBuyEbtc(uint256 _feeToBuyEbtcBPS) external requiresAuth {
        require(_feeToBuyEbtcBPS <= MAX_FEE);
        emit FeeToBuyEbtcUpdated(feeToBuyEbtcBPS, _feeToBuyEbtcBPS);
        feeToBuyEbtcBPS = _feeToBuyEbtcBPS;
    }

    function setFeeToBuyAsset(uint256 _feeToBuyAssetBPS) external requiresAuth {
        require(_feeToBuyAssetBPS <= MAX_FEE);
        emit FeeToBuyAssetUpdated(feeToBuyAssetBPS, _feeToBuyAssetBPS);
        feeToBuyAssetBPS = _feeToBuyAssetBPS;
    }

    function setMintingCap(uint256 _mintingCapBPS) external requiresAuth {
        require(_mintingCapBPS <= BPS);
        emit MintingCapUpdated(mintingCapBPS, _mintingCapBPS);
        mintingCapBPS = _mintingCapBPS;
    }

    function addAuthorizedUser(address _user) external requiresAuth {
        authorizedUsers[_user] = true;
        emit AuthorizedUserAdded(_user);
    }

    function removeAuthorizedUser(address _user) external requiresAuth {
        delete authorizedUsers[_user];
        emit AuthorizedUserRemoved(_user);
    }

    function updateAssetVault(address newVault) external requiresAuth {
        // only migrate user balance, accumulated fees will be claimed separately
        uint256 bal = assetVault.depositAmount();
        if (bal > 0) {
            assetVault.beforeWithdraw(bal, 0);
            ASSET_TOKEN.safeTransferFrom(address(assetVault), newVault, bal);
            IAssetVault(newVault).afterDeposit(bal, 0);
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
