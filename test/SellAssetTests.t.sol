// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "@openzeppelin/contracts/mocks/token/ERC4626Mock.sol";
import {MockAssetOracle} from "./mocks/MockAssetOracle.sol";
import {MockActivePool} from "./mocks/MockActivePool.sol";
import "../src/Dependencies/Governor.sol";
import "../src/Dependencies/IPriceFeed.sol";
import "../src/EbtcBSM.sol";
import "../src/OracleModule.sol";
import "../src/RateLimiter.sol";
import "../src/ERC4626AssetVault.sol";

contract SellAssetTests is Test {
    ERC20Mock internal mockAssetToken;
    ERC20Mock internal mockEbtcToken;
    ERC4626Mock internal externalVault;
    ERC4626AssetVault internal assetVault;
    MockAssetOracle internal mockAssetOracle;
    MockAssetOracle internal mockEbtcOracle;
    MockActivePool internal mockActivePool;
    OracleModule internal oracleModule;
    RateLimiter internal rateLimiter;
    IPriceFeed internal priceFeed;
    EbtcBSM internal bsmTester;
    address internal testMinter;
    Governor internal authority;
    address internal defaultGovernance;
    address internal defaultFeeRecipient;
    address internal highSecTimelock;
    address internal techOpsMultisig;

    function setUp() public {
        defaultGovernance = vm.addr(0x123456);
        defaultFeeRecipient = vm.addr(0x234567);
        authority = new Governor(defaultGovernance);
        mockAssetToken = new ERC20Mock();
        mockEbtcToken = new ERC20Mock();
        mockActivePool = new MockActivePool(mockEbtcToken);
        externalVault = new ERC4626Mock(address(mockAssetToken));
        mockAssetOracle = new MockAssetOracle(18);
        mockEbtcOracle = new MockAssetOracle(18);
        oracleModule = new OracleModule(address(mockAssetOracle), address(mockEbtcOracle), address(authority));
        rateLimiter = new RateLimiter();
        testMinter = vm.addr(0x11111);
        highSecTimelock = 0xaDDeE229Bd103bb5B10C3CdB595A01c425dd3264;
        techOpsMultisig = 0x690C74AF48BE029e763E61b4aDeB10E06119D3ba;

        bsmTester = new EbtcBSM(
            address(mockAssetToken),
            address(rateLimiter),
            address(oracleModule),
            address(mockEbtcToken),
            address(mockActivePool),
            address(defaultFeeRecipient),
            address(authority)
        );

//        priceFeed = IPriceFeed(oracleModule.PRICE_FEED());

        mockAssetOracle.setPrice(int256(priceFeed.fetchPrice()));

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

        vm.startPrank(highSecTimelock);
        // give eBTC minter and burner roles to BSM tester
        authority.setUserRole(address(bsmTester), 1, true);
        authority.setUserRole(address(bsmTester), 2, true);
        authority.setRoleName(15, "BSM: Governance");
        authority.setRoleCapability(
            15,
            address(bsmTester),
            bsmTester.setMintingCap.selector,
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
            bsmTester.updateAssetVault.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(assetVault),
            assetVault.withdrawProfit.selector,
            true
        );
        authority.setRoleCapability(
            15,
            address(assetVault),
            assetVault.setLiquidityBuffer.selector,
            true
        );
        authority.setUserRole(techOpsMultisig, 15, true);
        vm.stopPrank();

        vm.startPrank(techOpsMultisig);
        bsmTester.updateAssetVault(address(assetVault));
        assetVault.setLiquidityBuffer(5000);
        vm.stopPrank();

        // Set minting cap to 10%
        vm.prank(techOpsMultisig);
        bsmTester.setMintingCap(1000);
    }

    function testSellSuccess() public {
        assertEq(mockAssetToken.balanceOf(testMinter), 10e18);
        vm.prank(testMinter);
        bsmTester.sellAsset(1e18);
        assertEq(mockAssetToken.balanceOf(testMinter), 9e18);

        assertEq(externalVault.balanceOf(address(bsmTester.assetVault())), 0.5e18);
        assertEq(mockAssetToken.balanceOf(address(bsmTester.assetVault())), 0.5e18);

        vm.prank(testMinter);
        bsmTester.buyAsset(0.5e18);

        assertEq(externalVault.balanceOf(address(bsmTester.assetVault())), 0.25e18);
        assertEq(mockAssetToken.balanceOf(address(bsmTester.assetVault())), 0.25e18);
    }
}
