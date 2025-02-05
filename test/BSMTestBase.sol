// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";
import {MockAssetOracle} from "./mocks/MockAssetOracle.sol";
import {MockActivePool} from "./mocks/MockActivePool.sol";
import "../src/Dependencies/Governor.sol";
import "../src/EbtcBSM.sol";
import "../src/OracleModule.sol";
import "../src/ERC4626AssetVault.sol";

contract BSMTestBase is Test {
    ERC20Mock internal mockAssetToken;
    ERC20Mock internal mockEbtcToken;
    ERC4626Mock internal externalVault;
    ERC4626AssetVault internal assetVault;
    MockAssetOracle internal mockAssetOracle;
    MockActivePool internal mockActivePool;
    OracleModule internal oracleModule;
    EbtcBSM internal bsmTester;
    address internal testMinter;
    address internal testBuyer;
    Governor internal authority;
    address internal defaultGovernance;
    address internal defaultFeeRecipient;
    address internal techOpsMultisig;
    address internal testAuthorizedUser;

    function setUp() public virtual {
        defaultGovernance = vm.addr(0x123456);
        defaultFeeRecipient = vm.addr(0x234567);
        authority = new Governor(defaultGovernance);
        mockAssetToken = new ERC20Mock();
        mockEbtcToken = new ERC20Mock();
        mockActivePool = new MockActivePool(mockEbtcToken);
        externalVault = new ERC4626Mock(address(mockAssetToken));
        mockAssetOracle = new MockAssetOracle(18);
        oracleModule = new OracleModule(
            address(mockAssetOracle),
            address(authority)
        );
        testMinter = vm.addr(0x11111);
        testBuyer = vm.addr(0x22222);
        testAuthorizedUser = vm.addr(0x33333);
        techOpsMultisig = 0x690C74AF48BE029e763E61b4aDeB10E06119D3ba;

        bsmTester = new EbtcBSM(
            address(mockAssetToken),
            address(oracleModule),
            address(mockEbtcToken),
            address(mockActivePool),
            address(defaultFeeRecipient),
            address(authority)
        );

        // create initial ebtc supply
        mockEbtcToken.mint(defaultGovernance, 50e18);
        mockAssetOracle.setPrice(1e18);
        mockAssetOracle.setUpdateTime(block.timestamp);

        assetVault = new ERC4626AssetVault(
            address(externalVault),
            address(mockAssetToken),
            address(bsmTester),
            address(authority),
            bsmTester.FEE_RECIPIENT()
        );

        vm.prank(testMinter);
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        mockAssetToken.mint(testMinter, 10e18);

        vm.startPrank(testAuthorizedUser);
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        mockEbtcToken.approve(address(bsmTester), type(uint256).max);
        vm.stopPrank();
        mockAssetToken.mint(testAuthorizedUser, 10e18);
        mockEbtcToken.mint(testAuthorizedUser,10e18);

        vm.prank(testBuyer);
        mockEbtcToken.mint(testBuyer, 10e18);

        vm.startPrank(defaultGovernance);
        // give eBTC minter and burner roles to BSM tester
        authority.setUserRole(address(bsmTester), 1, true);
        authority.setUserRole(address(bsmTester), 2, true);
        authority.setRoleName(15, "BSM: Governance");
        authority.setRoleName(16, "BSM: AuthorizedUser");
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setMintingCap.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setFeeToBuyAsset.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setFeeToBuyEbtc.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.updateAssetVault.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.pause.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.unpause.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setOracleModule.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(assetVault),
            assetVault.claimProfit.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(assetVault),
            assetVault.depositToExternalVault.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(assetVault),
            assetVault.redeemFromExternalVault.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(oracleModule),
            oracleModule.setMinPrice.selector,
            true
        );
        // Give ebtc tech ops role 15
        authority.setUserRole(techOpsMultisig, 15, true);
        authority.setRoleCapability(
            16,
            address(bsmTester),
            bsmTester.buyEbtcWithAssetNoFee.selector,
            true
        );
        authority.setRoleCapability(
            16,
            address(bsmTester),
            bsmTester.buyAssetWithEbtcNoFee.selector,
            true
        );
        // Give authorizedUser role 16
        authority.setUserRole(testAuthorizedUser, 16, true);
        vm.stopPrank();

        vm.startPrank(techOpsMultisig);
        bsmTester.updateAssetVault(address(assetVault));
        // Set minting cap to 10%
        bsmTester.setMintingCap(1000);
        vm.stopPrank();
    }
}
