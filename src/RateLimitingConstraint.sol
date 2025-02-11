// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";
import {IMintingConstraint} from "./Dependencies/IMintingConstraint.sol";
import {IActivePool} from "./Dependencies/IActivePool.sol";
import {IEbtcBSM} from "./Dependencies/IEbtcBSM.sol";

contract RateLimitingConstraint is IMintingConstraint, AuthNoOwner {
    struct MintingCap {
        uint256 relativeCapBPS;
        uint256 absoluteCap;
        bool useAbsoluteCap;
    }

    uint256 public constant BPS = 10000;

    /// @notice minting cap % of ebtc total supply TWAP
    mapping(address => MintingCap) internal mintingCap;
    IActivePool public immutable ACTIVE_POOL;

    event MintingCapUpdated(address indexed minter, MintingCap oldCap, MintingCap newCap);

    error AboveMintingCap(
        uint256 amountToMint,
        uint256 newTotalToMint,
        uint256 maxMint
    );

    constructor(address _activePool, address _governance) {
        ACTIVE_POOL = IActivePool(_activePool);
        _initializeAuthority(_governance);
    }

    function canMint(uint256 amount, address minter) external returns (bool, bytes memory) {
        MintingCap memory cap = mintingCap[minter];
        uint256 maxMint;

        if (cap.useAbsoluteCap) {
            maxMint = cap.absoluteCap;
        } else {
            /// @notice ACTIVE_POOL.observe returns the eBTC TWAP total supply
            uint256 totalEbtcSupply = ACTIVE_POOL.observe();
            maxMint = (totalEbtcSupply * cap.relativeCapBPS) / BPS;
        }

        uint256 newTotalToMint = IEbtcBSM(minter).totalMinted() + amount;

        if (newTotalToMint > maxMint) {
            return (false, abi.encodeWithSelector(AboveMintingCap.selector, amount, newTotalToMint, maxMint));
        }

        return (true, "");
    }

    function getMintingCap(address minter) external view returns (MintingCap memory) {
        return mintingCap[minter];
    }

    function setMintingCap(address minter, MintingCap calldata newMintingCap) external requiresAuth {
        require(newMintingCap.relativeCapBPS <= BPS);
        emit MintingCapUpdated(minter, mintingCap[minter], newMintingCap);
        mintingCap[minter] = newMintingCap;
    }
}
