// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "../src/Dependencies/Governor.sol";
import "../src/EbtcBSM.sol";
import "../src/OracleModule.sol";
import "../src/RateLimiter.sol";

contract SellAssetTests is Test {
    ERC20Mock internal mockAssetToken;
    OracleModule internal oracleModule;
    RateLimiter internal rateLimiter;
    EbtcBSM internal bsmTester;
    address internal testMinter;
    Governor internal authority;
    address internal highSecTimelock;
    address internal techOpsMultisig;

    function setUp() public {
        mockAssetToken = new ERC20Mock();
        oracleModule = new OracleModule();
        rateLimiter = new RateLimiter();
        testMinter = vm.addr(0x11111);
        highSecTimelock = 0xaDDeE229Bd103bb5B10C3CdB595A01c425dd3264;
        techOpsMultisig = 0x690C74AF48BE029e763E61b4aDeB10E06119D3ba;

        bsmTester = new EbtcBSM(address(mockAssetToken), address(rateLimiter), address(oracleModule));

        authority = Governor(bsmTester.GOVERNANCE());

        vm.prank(testMinter);
        mockAssetToken.approve(address(bsmTester), type(uint256).max);
        mockAssetToken.mint(testMinter, 10e18);

        vm.startPrank(highSecTimelock);
        // give eBTC minter and burner roles to BSM tester
        authority.setUserRole(address(bsmTester), 1, true);
        authority.setUserRole(address(bsmTester), 2, true);
        authority.setRoleName(15, "BSM: Governance");
        authority.setRoleCapability(15, address(bsmTester), bsmTester.setMintingCap.selector, true);
        authority.setUserRole(techOpsMultisig, 15, true);
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

        vm.prank(testMinter);
        bsmTester.buyAsset(1e18);
    }
}