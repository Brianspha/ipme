// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;
import "../utils/IPHolderData.sol";
import {IP} from "@story-protocol/protocol-core/contracts/lib/IP.sol";

/**
 * @title IIPHolder
 * @dev Interface for the IPHolder contract responsible for managing intellectual property (IP) assets 
 * @dev within the Story Protocol ecosystem.
 * @dev The contract also uses the Sign protocol to manage licensing attestations.
 */
interface IIPHolder is IPHolderData {
    /**
     * @dev Registers a new IP and adds a policy to it based on the provided IP semantics.
     * @notice Must only be called by the token owner. Transfers the token to the contract if not already owned by it.
     * @notice The token is returned to the user at the end of the transaction
     * @param ipSemantics The detailed structure containing all necessary data for IP registration and policy application.
     * @return ipId The address identifier of the newly registered IP  account (ERC6551).
     */
    function registerAndAddPolicy(
        IPSematicsWithPolicy memory ipSemantics
    ) external returns (address ipId);

    /**
     * @dev Retrieves metadata for a specific IP identified by its address.
     * @param id The address identifier of the IP.
     * @return metadata The metadata of the specified IP as a structured data type.
     */
    function metadata(address id) external view returns (IP.MetadataV1 memory);

    /**
     * @dev Issues a new license for an IP, transferring the required license fee and recording the transaction details.
     * @param leaseDetails The structure detailing the lease agreement, including the licensor, licensee, and terms.
     * @return licenseId The identifier of the newly issued license i.e. the NFT TokenId.
     */
    function issueLicense(
        IPLease memory leaseDetails
    ) external returns (uint256 licenseId);

    /**
     * @dev Retrieves all licenses issued to a specific IP  account (ERC6551).
     * @param account The address of the account whose licenses are to be retrieved.
     * @return An array of license identifiers.
     */
    function accountLicenses(
        address account
    ) external view returns (uint256[] memory);

    /**
     * @dev Retrieves details of all IPs associated with a specific IP  account (ERC6551).
     * @param account The address of the account whose IP details are to be retrieved.
     * @return An array of IPDetails structures containing detailed information about each IP.
     */
    function accountIPDetails(
        address account
    ) external view returns (IPDetails[] memory);

 
     /**
     * @dev Retrieves detailed information about the IP associated with a specific account.
     * @param account The address of the account for which IP details are required.
     * @return ip Details of the IP associated with the specified account.
     */
    function accountIPDetail(
        address account
    ) external view returns (IPDetails memory ip);

    /**
     * @dev Retrieves all IPs that have been minted by the contract.
     * @return A list of all IPDetails representing each minted IP  account (ERC6551) .
     */
    function allMintedIPs() external view returns (IPDetails[] memory);

    /**
     * @dev Retrieves all licenses bought by a specific user NOT IP  account (ERC6551).
     * @param user The address of the user whose licenses are to be retrieved.
     * @return A list of IPDetails representing each license bought by the user.
     */
    function boughtLicenses(
        address user
    ) external view returns (IPDetails[] memory);
}
