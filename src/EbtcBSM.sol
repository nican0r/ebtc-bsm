// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEbtcToken} from "./Dependencies/IEbtcToken.sol";
import {IActivePool} from "./Dependencies/IActivePool.sol";
import {IAssetVault, BaseAssetVault} from "./BaseAssetVault.sol";

interface IRateLimiter {
    function canMint(uint256 amount) external returns (bool);
}

interface IOracleModule {
    function canMint() external returns (bool);
}

contract EbtcBSM is Pausable, AuthNoOwner {
    using SafeERC20 for IERC20;

    IEbtcToken public constant EBTC_TOKEN =
        IEbtcToken(0x661c70333AA1850CcDBAe82776Bb436A0fCfeEfB);
    IActivePool public constant ACTIVE_POOL =
        IActivePool(0x6dBDB6D420c110290431E863A1A978AE53F69ebC);
    address public immutable FEE_RECIPIENT =
        0x2CEB95D4A67Bf771f1165659Df3D11D8871E906f;
    address public immutable GOVERNANCE =
        0x2A095d44831C26cFB6aCb806A6531AE3CA32DBc1;
    uint256 public constant BPS = 10000;
    uint256 public constant MAX_FEE = 2000;

    //
    IERC20 public immutable ASSET_TOKEN;
    IRateLimiter public immutable RATE_LIMITER;
    IOracleModule public immutable ORACLE_MODULE;

    uint256 public feeToBuyBPS;
    uint256 public feeToSellBPS;
    /// @notice minting cap % of ebtc total supply TWAP
    uint256 public mintingCapBPS;
    uint256 public totalMinted;
    mapping(address => bool) authorizedUsers;
    IAssetVault public assetVault;

    event AssetVaultUpdated(address indexed oldVault, address indexed newVault);
    event MintingCapUpdatd(uint256 oldCap, uint256 newCap);
    event FeeToBuyUpdated(uint256 oldFee, uint256 newFee);
    event FeeToSellUpdated(uint256 oldFee, uint256 newFee);
    event AssetSold(uint256 assetAmount, uint256 feeAmount);
    event AssetBought(uint256 assetAmount, uint256 boughtAmount);
    event AuthorizedUserAdded(address indexed user);
    event AuthorizedUserRemoved(address indexed user);

    error AboveMintingCap(
        uint256 amountToMint,
        uint256 newTotalToMint,
        uint256 maxMint
    );
    error BadOracleRate();
    error RateLimited();

    constructor(
        address _assetToken,
        address _rateLimiter,
        address _oracleModule
    ) {
        ASSET_TOKEN = IERC20(_assetToken);
        RATE_LIMITER = IRateLimiter(_rateLimiter);
        ORACLE_MODULE = IOracleModule(_oracleModule);
        _initializeAuthority(GOVERNANCE);

        assetVault = IAssetVault(
            address(
                new BaseAssetVault(
                    _assetToken,
                    address(this),
                    GOVERNANCE,
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

    function _calcBuyFee(uint256 _amount) private view returns (uint256) {
        return (_amount * feeToBuyBPS) / BPS;
    }

    function _calcSellFee(uint256 _amount) private view returns (uint256) {
        return (_amount * feeToSellBPS) / BPS;
    }

    function sellAsset(uint256 _amount) external whenNotPaused {
        _checkMintingCap(_amount);
        if (!ORACLE_MODULE.canMint()) {
            revert BadOracleRate();
        }
        if (!RATE_LIMITER.canMint(_amount)) {
            revert RateLimited();
        }

        uint256 feeAmount = _calcBuyFee(_amount);
        uint256 transferInAmount = _amount + feeAmount;
        // INVARIANT: transferInAmount >= _amount
        ASSET_TOKEN.safeTransferFrom(
            msg.sender,
            address(assetVault),
            transferInAmount
        );
        assetVault.afterDeposit(_amount, feeAmount); // depositAmount = transferInAmount - fee

        totalMinted += _amount;

        EBTC_TOKEN.mint(msg.sender, _amount);

        emit AssetSold(_amount, feeAmount);
    }

    function buyAsset(uint256 _amount) external whenNotPaused {
        // TODO: figure out if we need to check oracle price here

        EBTC_TOKEN.burn(msg.sender, _amount);

        totalMinted -= _amount;

        uint256 feeAmount = _calcSellFee(_amount);
        uint256 transferOutAmount = _amount - feeAmount;
        assetVault.beforeWithdraw(_amount, feeAmount);
        // INVARIANT: transferOutAmount <= _amount
        ASSET_TOKEN.safeTransferFrom(
            address(assetVault),
            msg.sender,
            transferOutAmount
        );

        emit AssetBought(_amount, feeAmount);
    }

    function setFeeToBuy(uint256 _feeToBuyBPS) external requiresAuth {
        require(feeToBuyBPS <= MAX_FEE);
        emit FeeToBuyUpdated(feeToBuyBPS, _feeToBuyBPS);
        feeToBuyBPS = _feeToBuyBPS;
    }

    function setFeeToSell(uint256 _feeToSellBPS) external requiresAuth {
        require(feeToSellBPS <= MAX_FEE);
        emit FeeToSellUpdated(feeToSellBPS, _feeToSellBPS);
        feeToSellBPS = _feeToSellBPS;
    }

    function setMintingCap(uint256 _mintingCapBPS) external requiresAuth {
        require(_mintingCapBPS <= BPS);
        emit MintingCapUpdatd(mintingCapBPS, _mintingCapBPS);
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
        assetVault.beforeWithdraw(bal, 0);
        ASSET_TOKEN.safeTransferFrom(address(assetVault), newVault, bal);
        IAssetVault(newVault).afterDeposit(bal, 0);

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
