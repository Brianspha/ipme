// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;
import {IPHolder, IPHolderData, IPILPolicyFrameworkManager} from "../src/ip/IPHolder.sol";
import {IPHolderRegistrar} from "../src/ip/IPHolderRegistrar.sol";
import {NFT} from "../src/nft/NFT.sol";
import {Token} from "../src/token/Token.sol";
import {ERC6551Account} from "../src/ip/ERC6551Account.sol";
import {IP} from "@story-protocol/protocol-core/contracts/lib/IP.sol";
import {IPLicensingAttestation} from "../src/sign/IPLicensingAttestation.sol";
import {Attestation} from "@ethsign/sign-protocol-evm/src/models/Attestation.sol";
import {Schema, ISPHook} from "@ethsign/sign-protocol-evm/src/models/Schema.sol";
import {SP} from "@ethsign/sign-protocol-evm/src/core/SP.sol";
import {JsonDeploymentHandler} from "./JsonDeploymentHandler.sol";
import {DataLocation} from "@ethsign/sign-protocol-evm/src/models/DataLocation.sol";
import {ILicensingModule} from "@story-protocol/protocol-core/contracts/interfaces/modules/licensing/ILicensingModule.sol";
import "@story-protocol/protocol-core/contracts/interfaces/modules/licensing/IPILPolicyFrameworkManager.sol";
import "forge-std/Script.sol";

contract IPHolderRegistrarScript is Script, IPHolderData, JsonDeploymentHandler {
    uint256 public immutable defaultTokenBalance =
        1000000000000000000000000000000 ether;
    address public constant LICENSING_MODULE =
        address(0x950d766A1a0afDc33c3e653C861A8765cb42DbdC);
    address public constant PILPOLICY_FRAMEWORK_MANAGER =
        address(0xeAABf2b80B7e069EE449B5629590A1cc0F9bC9C2);
    address public constant REGISTRATION_MODULE =
        address(0x613128e88b568768764824f898C8135efED97fA6);
    address public constant Royalty_POLICY_LAP =
        address(0x16eF58e959522727588921A92e9084d36E5d3855);
    address public constant METADATA_PROVIDER_ADDR =
        address(0x31c65C12A6A3889cd08A055914931E2Fbe773dD6);
    address public constant IPA_REGISTRY_ADDR =
        address(0x292639452A975630802C17c9267169D93BD5a793);
    address public constant IP_RESOLVER_ADDR =
        address(0xEF808885355B3c88648D39c9DB5A0c08D99C6B71);
    address public constant STORY_PROTOCOL_GATEWAY_ADDR =
        address(0xf82EEe73c2c81D14DF9bC29DC154dD3c079d80a0);
    address public constant SIGN_PROTOCOL =
        address(0x878c92FD89d8E0B93Dc0a3c907A2adc7577e39c5);
    RegisterPILPolicyParams public policySettings;
    IPHolderRegistrar public registrar;
    NFT public ipIssuer;
    uint64 public SUBSCRIPTION_ID;
    uint96 public immutable BASEFEE = 100000000000000000;
    uint96 public immutable GASPRICELINK = 1000000000;
    Token public token;
    string[] public empty;
    address spha = address(0x73109Baf60baB74B9E8273DfD4236d17C56CFc67);
    address owner = address(0x8c458F7C2B3B9fbccbe2cEB60566F2B8e5384C95);
    address public constant VRF_CORDINATOR_SEPOLIA =
        address(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625);
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    uint96 MAX_INT = type(uint96).max;
    SP public signProtocol;
    IPLicensingAttestation licensingAttestation;

    function setUp() public {
        // vm.stopBroadcast();
    }

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        signProtocol = new SP();
        licensingAttestation = new IPLicensingAttestation();
        licensingAttestation.setSPInstance(address(signProtocol));
        registrar = new IPHolderRegistrar();
        registrar.initialize(licensingAttestation);
        licensingAttestation.addAdmin(address(registrar));
        token = new Token("FAKE USDC", "FUSDC", 18);
        ipIssuer = new NFT("My IP Issuing Token", "MP");
        _postdeploy("IPHolderRegistrar", address(registrar));
        _postdeploy("PaymentToken", address(token));
        _postdeploy("SignProtocol", address(signProtocol));
        _postdeploy("LicensingAttestation", address(licensingAttestation));
        _postdeploy("IPIssuer", address(ipIssuer));
        _postdeploy("LICENSING_MODULE", LICENSING_MODULE);
        _postdeploy("PILPOLICY_FRAMEWORK_MANAGER", PILPOLICY_FRAMEWORK_MANAGER);
        _postdeploy("REGISTRATION_MODULE", REGISTRATION_MODULE);
        _postdeploy("Royalty_POLICY_LAP", Royalty_POLICY_LAP);
        _postdeploy("METADATA_PROVIDER_ADDR", METADATA_PROVIDER_ADDR);
        _postdeploy("IPA_REGISTRY_ADDR", IPA_REGISTRY_ADDR);
        _postdeploy("IP_RESOLVER_ADDR", IP_RESOLVER_ADDR);
        _postdeploy("STORY_PROTOCOL_GATEWAY_ADDR", STORY_PROTOCOL_GATEWAY_ADDR);
        _writeDeployment(false);
        vm.label(vm.addr(deployerPrivateKey), "MSG_SENDER");
        token.mint(vm.addr(deployerPrivateKey), 10000000000 ether);
        registerIPAndAddPolicy(vm.addr(deployerPrivateKey));
    }

    function _mintIPs(
        NFT ipIssuer_,
        address to,
        uint96 count
    ) internal returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = ipIssuer_.mint(to);
            tokenIds[i] = tokenId;
        }
        return tokenIds;
    }

    function _postdeploy(
        string memory contractKey,
        address newAddress
    ) private {
        _writeAddress(contractKey, newAddress);
        console2.log(string.concat(contractKey, " deployed to:"), newAddress);
    }

    function registerIPAndAddPolicy(address to) public {
        IPHolder instance;
        (instance, ipIssuer) = _createIP(to);
        uint256[] memory tokenIds = _mintIPs(ipIssuer, to, 1);
        uint256 tokenId = tokenIds[0];
        instance.registerAndAddPolicy(
            IPSematicsWithPolicy({
                url: "google.com",
                ipName: "Special IP",
                policyId: 1,
                tokenId: tokenId,
                contentHash: bytes32("0x0"),
                policySettings: policySettings,
                attestationData: "test"
            })
        );

        IPDetails[] memory accountDetails = instance.accountIPDetails(to);
        assert(accountDetails.length == 1);
    }

    function _createIP(
        address to
    ) public returns (IPHolder instance, NFT ipIssuer_) {
        console.log("Creating IP",msg.sender);
        ipIssuer_ = ipIssuer;
        licensingAttestation.registerSchema(
            Schema({
                hook: ISPHook(address(0)), //@dev no hook for now
                revocable: false,
                registrant: address(licensingAttestation),
                maxValidFor: 0,
                timestamp: uint64(block.timestamp),
                data: "{"
                "name"
                ":"
                "XYZ Company License"
                ","
                "description"
                ":"
                "License for releasing media content using XXXX"
                ", "
                "data"
                ":"
                "[]"
                "}",
                dataLocation: DataLocation.ONCHAIN
            })
        );
        //Register IP
        instance = registrar.deployIP(
            IPSettings({
                ipAssetRegistry: IPA_REGISTRY_ADDR,
                resolver: IP_RESOLVER_ADDR,
                nftToken: address(ipIssuer),
                registrationModule: REGISTRATION_MODULE,
                policyRegistrar: PILPOLICY_FRAMEWORK_MANAGER,
                licensingModule: LICENSING_MODULE,
                spg: STORY_PROTOCOL_GATEWAY_ADDR,
                licenseCost: 10000e18, //@dev 10K of whatever token,
                licenseToken: address(token),
                licensingAttestation: address(licensingAttestation)
            })
        );
        console.log("id: ", ILicensingModule(LICENSING_MODULE).totalPolicies());
        //approve contract
        ipIssuer.setApprovalForAll(address(instance), true);
        assert(ipIssuer.isApprovedForAll(to, address(instance))== true);
        vm.label(address(instance), "IPHolder");
        vm.label(address(ipIssuer), "NFT");
        vm.label(address(licensingAttestation), "IPLicensingAttestation");
    }

    function _faucet(address user) internal {
        token.mint(user, defaultTokenBalance);
        console.log("balance of: %o", user);
        console.log(token.balanceOf(user));
        assert(token.balanceOf(user) == defaultTokenBalance);
    }
}
