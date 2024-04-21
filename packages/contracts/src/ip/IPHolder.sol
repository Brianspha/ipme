// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

// Imports from external and internal dependencies
import {IP} from "@story-protocol/protocol-core/contracts/lib/IP.sol";
import {IPAssetRegistry} from "@story-protocol/protocol-core/contracts/registries/IPAssetRegistry.sol";
import {IPResolver} from "@story-protocol/protocol-core/contracts/resolvers/IPResolver.sol";
import {RegistrationModule} from "@story-protocol/protocol-core/contracts/modules/RegistrationModule.sol";
import {ERC6551Account} from "./ERC6551Account.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {LicensingModule} from "@story-protocol/protocol-core/contracts/modules/licensing/LicensingModule.sol";
import {StoryProtocolGateway} from "@story-protocol/protocol-periphery/contracts/StoryProtocolGateway.sol";
import {IIPLicensingAttestation} from "../sign/IIPLicensingAttestation.sol";
import "./IIPHolder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/IPHolderData.sol";

contract IPHolder is IIPHolder {
    // Immutable contract addresses and modules used for IP management
    address public immutable NFT;
    address public immutable IP_RESOLVER;
    RegistrationModule public immutable REGISTRATION_MODULE;
    LicensingModule public immutable LICENSING_MODULE;
    IPILPolicyFrameworkManager public immutable IPIL_POLICY_MANAGER;
    StoryProtocolGateway public immutable storyProtocolGateway;
    IPAssetRegistry public immutable IPASSET_REGISTRATION_REGISTRATION;
    IIPLicensingAttestation public licensingAttestation;
    // Mapping to track user IP details and token transfer statuses
    mapping(address user => IPDetails[] mintedIPs) public userIPs;
    mapping(address ipAccount => IPDetails details) public ipDetails;
    mapping(address => mapping(uint256 => bool)) public tokensTransferred;
    mapping(address ipAccount => uint256[]) public licensesLeased;
    mapping(address user => IPDetails[] licensesOwned) public userLicenses;
    IPDetails[] public mintedIPs;
    // Licensing related variables
    uint256 public minLicenseCost;
    address public licenseToken;
    uint256 public mintedLicenses;

    /**
     * @dev Constructor for IPHolder contract.
     * Initializes contract with given settings for IP management.
     * @param settings Struct containing initialization settings.
     */
    constructor(IPSettings memory settings) {
        REGISTRATION_MODULE = RegistrationModule(settings.registrationModule);
        IP_RESOLVER = settings.resolver;
        NFT = settings.nftToken;
        IPIL_POLICY_MANAGER = IPILPolicyFrameworkManager(
            settings.policyRegistrar
        );
        IPASSET_REGISTRATION_REGISTRATION = IPAssetRegistry(
            settings.ipAssetRegistry
        );
        LICENSING_MODULE = LicensingModule(settings.licensingModule);
        storyProtocolGateway = StoryProtocolGateway(settings.spg);
        minLicenseCost = settings.licenseCost;
        licenseToken = settings.licenseToken;
        licensingAttestation = IIPLicensingAttestation(
            settings.licensingAttestation
        );
    }

    /**
     * @dev Transfers a specified token ID to the contract and marks it as transferred.
     * Reverts if the sender is not the owner of the token.
     * @param tokenId The ID of the token to be transferred.
     */
    function transfer(uint256 tokenId) internal {
        if (IERC721(NFT).ownerOf(tokenId) != msg.sender) {
            revert NotOwner();
        }
        tokensTransferred[msg.sender][tokenId] = true;
        IERC721(NFT).transferFrom(msg.sender, address(this), tokenId);
        IERC721(NFT).setApprovalForAll(address(this), true);
        if (IERC721(NFT).ownerOf(tokenId) != address(this)) {
            revert TokenNotTransferred();
        }
    }

    /**
     * @dev Claims IP ownership of a specified token ID back to the sender.
     * Reverts if the contract is not the current owner of the token.
     * @param tokenId The ID of the token to claim.
     */
    function claimIP(uint256 tokenId) internal {
        if (IERC721(NFT).ownerOf(tokenId) != address(this)) {
            revert ContractNotOwner();
        }
        tokensTransferred[msg.sender][tokenId] = false;
        IERC721(NFT).transferFrom(address(this), msg.sender, tokenId);
        if (IERC721(NFT).ownerOf(tokenId) != msg.sender) {
            revert TokenNotTransferred();
        }
    }

    /// @inheritdoc IIPHolder
    function registerAndAddPolicy(
        IPSematicsWithPolicy memory ipSemantics
    ) external override returns (address ipId) {
        if (IERC721(NFT).ownerOf(ipSemantics.tokenId) != address(this)) {
            //@dev not ideal
            transfer(ipSemantics.tokenId);
        }
        ipId = REGISTRATION_MODULE.registerRootIp(
            ipSemantics.policyId,
            NFT,
            ipSemantics.tokenId,
            ipSemantics.ipName,
            ipSemantics.contentHash,
            ipSemantics.url
        );
        uint256 policyId = IPIL_POLICY_MANAGER.registerPolicy(
            ipSemantics.policySettings
        );
        uint256 indexOnIpId = LICENSING_MODULE.addPolicyToIp(ipId, policyId);
        ipDetails[ipId] = IPDetails({
            ipName: ipSemantics.ipName,
            attestationData: ipSemantics.attestationData,
            url: ipSemantics.url,
            policyId: policyId,
            indexOnIpId: indexOnIpId,
            owner: msg.sender,
            ipIdAccount: ERC6551Account(payable(ipId))
        });
        userIPs[msg.sender].push(ipDetails[ipId]);
        mintedIPs.push(ipDetails[ipId]);
        bytes[] memory reciepients;
        licensingAttestation.attestLicenseOrIP(
            IIPLicensingAttestation.LicenseAttestion({
                ipId: ipId,
                licenseId: 0, //@dev 0 inidicates attestation of the actual IP we assume all token id will start at 1
                licensee: ipId,
                data: ipSemantics.attestationData,
                recipients: reciepients
            })
        );
        claimIP(ipSemantics.tokenId);
        return ipId;
    }

    /// @inheritdoc IIPHolder

    function metadata(
        address id
    ) public view override returns (IP.MetadataV1 memory) {
        return
            abi.decode(
                IPASSET_REGISTRATION_REGISTRATION.metadata(id),
                (IP.MetadataV1)
            );
    }

    /// @inheritdoc IIPHolder

    function issueLicense(
        IPLease memory leaseDetails
    ) public override returns (uint256 licenseId) {
        if (leaseDetails.amount == 0) {
            revert InvalidLeaseConfiguration();
        }

        bool success = ERC20(licenseToken).transferFrom( //@dev this could be  any stable coin on Gnosis Chain
            msg.sender,
            leaseDetails.licensorIpId,
            minLicenseCost * leaseDetails.amount
        );
        if (!success) {
            revert InsufficientBalance();
        }
        licenseId = LICENSING_MODULE.mintLicense(
            leaseDetails.policyId,
            leaseDetails.licensorIpId,
            leaseDetails.amount,
            leaseDetails.receiver,
            leaseDetails.royaltyContext
        );
        if (licenseId == 0) {
            revert InvalidTokenId();
        }
        bytes[] memory reciepients;
        licensingAttestation.attestLicenseOrIP(
            IIPLicensingAttestation.LicenseAttestion({
                ipId: leaseDetails.licensorIpId,
                licenseId: licenseId,
                licensee: leaseDetails.receiver,
                data: ipDetails[leaseDetails.licensorIpId].attestationData,
                recipients: reciepients
            })
        );
        licensesLeased[leaseDetails.licensorIpId].push(licenseId);
        userLicenses[msg.sender].push(ipDetails[leaseDetails.licensorIpId]); //@dev not ideal but for now ok ideally we want to query the SP protocol for details
    }

    /// @inheritdoc IIPHolder

    function accountLicenses(
        address account
    ) public view override returns (uint256[] memory) {
        return licensesLeased[account];
    }

    /// @inheritdoc IIPHolder

    function accountIPDetails(
        address account
    ) public view returns (IPDetails[] memory ip) {
        return userIPs[account];
    }

    /// @inheritdoc IIPHolder

    function accountIPDetail(
        address account
    ) public view override returns (IPDetails memory ip) {
        return ipDetails[account];
    }

    /// @inheritdoc IIPHolder

    function allMintedIPs() public view returns (IPDetails[] memory) {
        return mintedIPs;
    }

    /// @inheritdoc IIPHolder

    function boughtLicenses(
        address user
    ) public view override returns (IPDetails[] memory) {
        return userLicenses[user];
    }
}
