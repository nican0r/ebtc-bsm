// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";
import {ERC4626AssetVault} from "../src/ERC4626AssetVault.sol";
import "./BSMTestBase.sol";
// TODO check totalBalance before and after external len ding

contract ExternalLendingTests is BSMTestBase {
    ERC4626Mock internal newExternalVault;
    ERC4626AssetVault internal newAssetVault;
    uint256 constant ASSET_AMOUNT = 1e18;
    uint256 shares;

    /**
     * @notice Pranks the following call as techOpsMultisig
     * @dev Hevm does not allow the usage of startPrank, this was created 
     * to be used in the wrapper methods that need to be called by this user
     */
    modifier prankTechOpsMultisig() {
        vm.prank(techOpsMultisig);
        _;
    }

    function setUp() public virtual override {
        super.setUp();

        newExternalVault = new ERC4626Mock(address(mockAssetToken));
        newAssetVault = new ERC4626AssetVault(
            address(newExternalVault),
            address(bsmTester.ASSET_TOKEN()),
            address(bsmTester),
            address(bsmTester.authority()),
            address(assetVault.FEE_RECIPIENT())
        );
        shares = newExternalVault.previewDeposit(ASSET_AMOUNT);
        vm.prank(techOpsMultisig);
        bsmTester.updateAssetVault(address(newAssetVault));

        setRoleCapability(
            15,
            address(newAssetVault),
            assetVault.claimProfit.selector,
            true
        );
        setRoleCapability(
            15,
            address(newAssetVault),
            assetVault.depositToExternalVault.selector,
            true
        );

        setRoleCapability(
            15,
            address(newAssetVault),
            assetVault.redeemFromExternalVault.selector,
            true
        );

        mockAssetToken.mint(techOpsMultisig, 10e18);
        vm.prank(techOpsMultisig);
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
    }
    
    function testBasicExternalDeposit() public {
        uint256 beforeExternalVaultBalance = mockAssetToken.balanceOf(address(newExternalVault));
        uint256 beforeBalance = mockAssetToken.balanceOf(techOpsMultisig);
        uint256 beforeShares = newExternalVault.balanceOf(address(newAssetVault));

        sellAsset();

        uint256 beforeDepositAmount = newAssetVault.depositAmount();
        uint256 beforeTotalBalance = newAssetVault.totalBalance();
        depositToExternalVault(ASSET_AMOUNT, shares);

        uint256 afterExternalVaultBalance = mockAssetToken.balanceOf(address(newExternalVault));
        uint256 afterBalance = mockAssetToken.balanceOf(techOpsMultisig);
        uint256 afterShares = newExternalVault.balanceOf(address(newAssetVault));
        uint256 afterDepositAmount = newAssetVault.depositAmount();
        uint256 afterTotalBalance = newAssetVault.totalBalance();

        assertGt(afterExternalVaultBalance, beforeExternalVaultBalance);
        assertGt(beforeBalance, afterBalance);
        assertEq(beforeShares, 0);
        assertEq(afterShares, shares);
        assertEq(beforeDepositAmount, afterDepositAmount);
        assertEq(beforeTotalBalance, afterTotalBalance);
    }
    
    function testBasicExternalRedeem() public {
        sellAsset();
        depositToExternalVault(ASSET_AMOUNT, shares);

        uint256 beforeExternalVaultBalance = mockAssetToken.balanceOf(address(newExternalVault));
        uint256 beforeBalance = mockAssetToken.balanceOf(techOpsMultisig);
        uint256 beforeShares = newExternalVault.balanceOf(address(newAssetVault));
        uint256 beforeDepositAmount = newAssetVault.depositAmount();
        uint256 assets = newExternalVault.previewRedeem(shares);
        uint256 beforeTotalBalance = newAssetVault.totalBalance();

        redeemFromExternalVault(shares, assets);

        uint256 afterExternalVaultBalance = mockAssetToken.balanceOf(address(newExternalVault));
        uint256 afterBalance = mockAssetToken.balanceOf(techOpsMultisig);
        uint256 afterShares = newExternalVault.balanceOf(address(newAssetVault));
        uint256 afterDepositAmount = newAssetVault.depositAmount();
        uint256 afterTotalBalance = newAssetVault.totalBalance();

        assertGt(beforeExternalVaultBalance, afterExternalVaultBalance);
        assertEq(beforeBalance, afterBalance);
        assertEq(beforeShares, shares);
        assertEq(afterShares, 0);
        assertEq(beforeDepositAmount, afterDepositAmount);
        assertEq(beforeTotalBalance, afterTotalBalance);
    }

    function testPartialExternalRedeem() public {
        sellAsset();
        depositToExternalVault(ASSET_AMOUNT, shares);

        uint256 beforeExternalVaultBalance = mockAssetToken.balanceOf(address(newExternalVault));
        uint256 beforeBalance = mockAssetToken.balanceOf(techOpsMultisig);
        uint256 beforeShares = newExternalVault.balanceOf(address(newAssetVault));

        uint256 assets = newExternalVault.previewRedeem(shares);
        redeemFromExternalVault(shares / 2, assets / 2);

        uint256 afterExternalVaultBalance = mockAssetToken.balanceOf(address(newExternalVault));
        uint256 afterBalance = mockAssetToken.balanceOf(techOpsMultisig);
        uint256 afterShares = newExternalVault.balanceOf(address(newAssetVault));

        assertGt(beforeExternalVaultBalance, afterExternalVaultBalance);
        assertEq(beforeBalance, afterBalance);
        assertEq(afterShares, shares / 2);
    }
    
    function testInvalidExternalRedeem() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        newAssetVault.redeemFromExternalVault(1e18, 1);

        // Redeem before making deposit
        vm.expectRevert();
        redeemFromExternalVault(1e18, 1);

        sellAsset();

        depositToExternalVault(ASSET_AMOUNT, shares);

        uint256 assets = newExternalVault.previewRedeem(shares);
        vm.expectRevert(abi.encodeWithSelector(ERC4626AssetVault.TooFewAssetsReceived.selector, assets + 1, assets));
        redeemFromExternalVault(shares, assets + 1);
    }

    function testInvalidExternalDeposit() public {
        vm.expectRevert("Auth: UNAUTHORIZED");
        newAssetVault.depositToExternalVault(1e18, 1);
        
        //invalid asset amount sent
        vm.expectRevert(abi.encodeWithSelector(ERC4626AssetVault.TooFewSharesReceived.selector, 1, 0));
        depositToExternalVault(0, 1);
        
        //invalid expected shares amount
        sellAsset();
        vm.expectRevert(abi.encodeWithSelector(ERC4626AssetVault.TooFewSharesReceived.selector, shares + 1, shares));
        depositToExternalVault(ASSET_AMOUNT, shares + 1);
    }

    function sellAsset() internal prankTechOpsMultisig {
        bsmTester.sellAsset(ASSET_AMOUNT, address(this));
    }

    function depositToExternalVault(uint256 _assetsToDeposit, uint256 _minShares) internal prankTechOpsMultisig {
        newAssetVault.depositToExternalVault(_assetsToDeposit, _minShares);
    }

    function redeemFromExternalVault(uint256 _shares, uint256 _assets) internal prankTechOpsMultisig {
        newAssetVault.redeemFromExternalVault(_shares, _assets);
    }

}