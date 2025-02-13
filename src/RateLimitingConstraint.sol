// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {AuthNoOwner} from "./Dependencies/AuthNoOwner.sol";
import {IMintingConstraint} from "./Dependencies/IMintingConstraint.sol";
import {IActivePoolObserver} from "./Dependencies/IActivePoolObserver.sol";
import {IEbtcBSM} from "./Dependencies/IEbtcBSM.sol";

contract RateLimitingConstraint is IMintingConstraint, AuthNoOwner {
    struct MintingConfig {
        uint256 relativeCapBPS;
        uint256 absoluteCap;
        bool useAbsoluteCap;
    }

    uint256 public constant BPS = 10000;

    mapping(address => MintingConfig) internal mintingConfig;
    IActivePoolObserver public immutable ACTIVE_POOL_OBSERVER;

    event MintingConfigUpdated(address indexed minter, MintingConfig oldConfig, MintingConfig newConfig);

    error AboveMintingCap(
        uint256 amountToMint,
        uint256 newTotalToMint,
        uint256 maxMint
    );

    constructor(address _activePool, address _governance) {
        ACTIVE_POOL_OBSERVER = IActivePoolObserver(_activePool);
        _initializeAuthority(_governance);
    }

    function canMint(uint256 _amount, address _minter) external view returns (bool, bytes memory) {
        MintingConfig memory cap = mintingConfig[_minter];
        uint256 maxMint;

        if (cap.useAbsoluteCap) {
            maxMint = cap.absoluteCap;
        } else {
            /// @notice ACTIVE_POOL.observe returns the eBTC TWAP total supply
            uint256 totalEbtcSupply = ACTIVE_POOL_OBSERVER.observe();
            maxMint = (totalEbtcSupply * cap.relativeCapBPS) / BPS;
        }

        uint256 newTotalToMint = IEbtcBSM(_minter).totalMinted() + _amount;

        if (newTotalToMint > maxMint) {
            return (false, abi.encodeWithSelector(AboveMintingCap.selector, _amount, newTotalToMint, maxMint));
        }

        return (true, "");
    }

    function getMintingConfig(address _minter) external view returns (MintingConfig memory) {
        return mintingConfig[_minter];
    }

    function setMintingConfig(address _minter, MintingConfig calldata _newMintingConfig) external requiresAuth {
        require(_newMintingConfig.relativeCapBPS <= BPS);
        emit MintingConfigUpdated(_minter, mintingConfig[_minter], _newMintingConfig);
        mintingConfig[_minter] = _newMintingConfig;
    }
}
