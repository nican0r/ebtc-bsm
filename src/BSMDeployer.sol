// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import "./EbtcBSM.sol";
import "./ERC4626AssetVault.sol";

contract BSMDeployer {

    event ContractDeployed(address indexed bsm, address indexed assetVault);

    /** 
    @notice Deploy the BSM contract and the Asset vault in a single transaction.
    @dev Initializes the bsm with the recently deployed asset vault, prevents users from calling the bsm 
    until initialized.
     */
    function deploy(address _assetToken,
        address _oracleModule,
        address _ebtcToken,
        address _activePool,
        address _feeRecipient,
        address _governance,
        address _externalVault) external {

        EbtcBSM bsm = new EbtcBSM(
            address(_assetToken),
            address(_oracleModule),
            address(_ebtcToken),
            address(_activePool),
            address(_feeRecipient),
            address(_governance)
        );

        ERC4626AssetVault assetVault = new ERC4626AssetVault(
            address(_externalVault),
            address(_assetToken),
            address(bsm),
            address(_governance),
            bsm.FEE_RECIPIENT()
        );
        
        bsm.initialize(address(assetVault));

        emit ContractDeployed(address(bsm), address(assetVault));
    }
}