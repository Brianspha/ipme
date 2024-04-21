// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@ethsign/sign-protocol-evm/src/interfaces/ISP.sol";
import {Attestation} from "@ethsign/sign-protocol-evm/src/models/Attestation.sol";
import {Schema} from "@ethsign/sign-protocol-evm/src/models/Schema.sol";

/// @title Interface for IPLicensingAttestation Contract
/// @notice Provides an interface for managing intellectual property (IP) licensing with attestation support
interface IIPLicensingAttestation {
    // errors
    error SPNotInitialized();

    //structs
    /// @notice Issues a license for using the registered IP
    /// @dev Requires that the caller is the registered owner of the IP or has the owner role
    /// @param ipId The IP for which a license is being issued
    /// @param licenseId A unique identifier for the new license
    /// @param recipients An array of addresses that are authorized under this license (if applicable for other chains or services)
    /// @param licensee The address of the licensee
    /// @param data Additional data or terms associated with the license
    /// @return attestationId The unique identifier of the attestation for this licensing transaction
    /// @notice Struct for attesting a license
    struct LicenseAttestion {
        address ipId;
        uint256 licenseId;
        address licensee;
        bytes data;
        bytes[] recipients;
    }

    /// @notice Emitted when a license is successfully issued
    /// @param ipAccount The IP Account issuing the license
    /// @param licenseId Unique identifier for the license issued
    /// @param licensee Address of the entity receiving the license
    /// @param attestationId The unique ID of the attestation linked to this license
    event LicenseIssued(
        address indexed ipAccount,
        uint256 indexed licenseId,
        address indexed licensee,
        uint64 attestationId
    );

    /// @notice Sets the instance of the Sign Protocol to be used
    /// @param instance Address of the Sign Protocol instance
    function setSPInstance(address instance) external;

    /// @notice Registers and sets a new schema ID to be used to attest IPs
    /// @param schema The schema used for creating attestations
    function registerSchema(Schema memory schema) external;

    //@notice Issues a license for using the registered IP
    //@dev see LicenseAttestion for documentation
    function attestLicenseOrIP(
        LicenseAttestion memory attestation
    ) external returns (uint64);

    /// @notice Adds a new administrator to the contract
    /// @dev Grants administrative privileges to the `_admin` address.
    /// This function can only be called by the contract owner or current administrators, depending on the access control implementation.
    /// @param _admin The address to grant administrative privileges to
    function addAdmin(address _admin) external;

    /// @notice Removes an administrator from the contract
    /// @dev Revokes administrative privileges from the `_admin` address.
    /// This function can only be called by the contract owner or current administrators, depending on the access control implementation.
    /// Ensures that `_admin` is currently an administrator before removal to prevent errors.
    /// @param _admin The address to remove administrative privileges from
    function removeAdmin(address _admin) external;
}
