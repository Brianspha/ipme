// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./IIPHolder.sol";
import {IPHolderData} from "../utils/IPHolderData.sol";
import {IIPHolder,IPHolder} from "./IPHolder.sol";

/**
 * @title IIPHolderRegistrar
 * @dev Interface for the IPHolderRegistrar contract that manages the deployment and registry of IPHolder contracts.
 * @dev It allows users to deploy IPHolder contracts with specific settings and maintains a registry of these contracts.
 */
interface IIPHolderRegistrar is IPHolderData {
    /**
     * @dev Deploys a new IPHolder contract with specified settings and registers it under the caller's address.
     * @param settings The settings for configuring the deployed IPHolder contract.
     * @return The address of the newly deployed IPHolder contract.
     */
    function deployIP(IPSettings memory settings) external returns (IPHolder);

    /**
     * @dev Returns the addresses of all IPHolder contracts deployed by a specified user.
     * @param user The address of the user whose IPHolder contracts are queried.
     * @return A list of addresses of the user's IPHolder contracts.
     */
    function userIps(address user) external view returns (address[] memory);

    /**
     * @dev Returns the addresses of all IPHolder contracts deployed.
     * @return A list of addresses of all deployed IPHolder contracts.
     */
    function allInstances() external view returns (address[] memory);

    /**
     * @dev Allows the owner to revoke admin privileges of an IPHolder contract from the IP attestation system.
     * @param ipHolder The address of the IPHolder contract whose admin privileges are to be revoked.
     */
    function revokeAdmin(address ipHolder) external;

    
}
