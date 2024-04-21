// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISP} from "@ethsign/sign-protocol-evm/src/interfaces/ISP.sol";
import {Attestation} from "@ethsign/sign-protocol-evm/src/models/Attestation.sol";
import {Schema} from "@ethsign/sign-protocol-evm/src/models/Schema.sol";
import {DataLocation} from "@ethsign/sign-protocol-evm/src/models/DataLocation.sol";
import {IIPLicensingAttestation} from "./IIPLicensingAttestation.sol"; // Ensure the path to interface is correct
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title IPLicensingAttestation
/// @notice Implements IIPLicensingAttestation for managing IP licensing and attestations
contract IPLicensingAttestation is AccessControl, IIPLicensingAttestation {
    modifier onlyWhenSpInitialized() {
        if (address(spInstance) == address(0)) {
            revert SPNotInitialized();
        }
        _;
    }

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    ISP public spInstance;
    uint64 public schemaId;
    mapping(address => address) public ipOwner;
    mapping(uint256 => Attestation) public licenses;

    constructor() {
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _grantRole(OWNER_ROLE, msg.sender);
    }

    /// @inheritdoc IIPLicensingAttestation
    function setSPInstance(
        address instance
    ) external override onlyRole(OWNER_ROLE) {
        spInstance = ISP(instance);
    }

    /// @inheritdoc IIPLicensingAttestation
    function registerSchema(
        Schema memory schema
    ) external override onlyRole(OWNER_ROLE) onlyWhenSpInitialized {
        schemaId = spInstance.register(schema, "");
    }

    /// @inheritdoc IIPLicensingAttestation
    function attestLicenseOrIP(
        LicenseAttestion memory attestation
    ) external override onlyRole(OWNER_ROLE) onlyWhenSpInitialized returns (uint64) {
        
        Attestation memory license = Attestation({
            schemaId: schemaId,
            linkedAttestationId: 0,
            attestTimestamp: 0,
            revokeTimestamp: 0,
            attester: address(this),
            validUntil: 0,
            dataLocation: DataLocation.ONCHAIN,
            revoked: false,
            recipients: attestation.recipients,
            data:attestation.data 
        });

        uint64 attestationId = spInstance.attest(license, "", "", "");
        licenses[attestation.licenseId] = license;
        emit LicenseIssued(
            attestation.ipId,
            attestation.licenseId,
            attestation.licensee,
            attestationId
        );
        return attestationId;
    }

    
    /// @inheritdoc IIPLicensingAttestation
    function addAdmin(address _admin) external override onlyRole(OWNER_ROLE) {
        grantRole(OWNER_ROLE, _admin);
    }

    /// @inheritdoc IIPLicensingAttestation
    function removeAdmin(
        address _admin
    ) external override onlyRole(OWNER_ROLE) {
        revokeRole(OWNER_ROLE, _admin);
    }
}
