// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {IPHolder, IPHolderData, IPILPolicyFrameworkManager, Licensing} from "../../ip/IPHolder.sol";
import {IPHolderRegistrar} from "../../ip/IPHolderRegistrar.sol";
import {NFT,IERC721Errors} from "../../nft/NFT.sol";
import {Token, ERC20, IERC20} from "../../token/Token.sol";
import {ERC6551Account} from "../../ip/ERC6551Account.sol";
import {IP} from "@story-protocol/protocol-core/contracts/lib/IP.sol";
import {SP} from "@ethsign/sign-protocol-evm/src/core/SP.sol";
import {Attestation} from "@ethsign/sign-protocol-evm/src/models/Attestation.sol";
import {Schema, ISPHook} from "@ethsign/sign-protocol-evm/src/models/Schema.sol";
import {DataLocation} from "@ethsign/sign-protocol-evm/src/models/DataLocation.sol";
import {PILFlavors} from "@story-protocol/protocol-core/contracts/lib/PILFlavors.sol";
import {ILicensingModule} from "@story-protocol/protocol-core/contracts/interfaces/modules/licensing/ILicensingModule.sol";
import {IPLicensingAttestation} from "../../sign/IPLicensingAttestation.sol";
import "forge-std/Test.sol";
import "@story-protocol/protocol-core/contracts/interfaces/modules/licensing/IPILPolicyFrameworkManager.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
abstract contract IPHolderBaseTest is Test, IPHolderData {
    using stdJson for string;
    bytes32 public immutable KEYHASH =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
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
    string public constant SEPOLIA_RPC =
        "https://ethereum-sepolia.blockpi.network/v1/rpc/public";
    uint256 sepoliaForkId;
    address owner;
    address spha;
    string[] public empty;
    IPHolderRegistrar public registrar;
    Token public token;
    RegisterPILPolicyParams public policySettings;
    uint256 public immutable defaultTokenBalance =
        1000000000000000000000000000000 ether;
    uint64 public immutable SUBSCRIPTION_ID = 10224;
    uint256 MAX_INT = 2 ** 256 - 1;
    address public constant SUBSCRIPTION_ID_OWNER =
        address(0xc699dc72Da10141eE105f9C70aDe50d3F72e81eb);
    address public constant SIGN_PROTOCOL =
        address(0x878c92FD89d8E0B93Dc0a3c907A2adc7577e39c5);
    uint64 public constant schemaId = 12;
    Schema public ipSchema;
    SP public signProtocol;
    IPLicensingAttestation licensingAttestation;

    function setUp() public virtual {
        policySettings = RegisterPILPolicyParams({
            transferable: true, // Whether or not attribution is required when reproducing the work
            royaltyPolicy: address(0), // Address of a royalty policy contract that will handle royalty payments
            mintingFee: 0,
            mintingFeeToken: address(0),
            policy: PILPolicy({
                attribution: true, // Whether or not attribution is required when reproducing the work
                commercialUse: false, // Whether or not the work can be used commercially
                commercialAttribution: false, // Whether or not attribution is required when reproducing the work commercially
                commercializerChecker: address(0), // commercializers that are allowed to commercially exploit the work. If zero address, then no restrictions is enforced
                commercializerCheckerData: "0x", // Additional calldata for the commercializer checker
                commercialRevShare: 0, // Percentage of revenue that must be shared with the licensor
                derivativesAllowed: true, // Whether or not the licensee can create derivatives of his work
                derivativesAttribution: true, // Whether or not attribution is required for derivatives of the work
                derivativesApproval: false, // Whether or not the licensor must approve derivatives of the work before they can be linked to the licensor IP ID
                derivativesReciprocal: false, // Whether or not the licensee must license derivatives of the work under the same terms
                territories: empty,
                distributionChannels: empty,
                contentRestrictions: empty
            })
        });
        //  sepoliaForkId = vm.createFork(SEPOLIA_RPC, 5713934);
        sepoliaForkId = vm.createFork("http://localhost:8545");
        vm.selectFork(sepoliaForkId);
        owner = _createUser("owner");
        spha = _createUser("spha");
        vm.startPrank(owner);
        signProtocol = new SP();
        licensingAttestation = new IPLicensingAttestation();
        licensingAttestation.setSPInstance(address(signProtocol));
        registrar = new IPHolderRegistrar();
        registrar.initialize(licensingAttestation);
        licensingAttestation.addAdmin(address(registrar));
        token = new Token("MY Token", "MYT", 18);

        vm.stopPrank();
        _faucet(spha);
        _faucet(owner);
    }

    function _createUser(
        string memory name
    ) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 1000 ether});
        vm.label(user, name);
        return user;
    }

    function _createUserWithTokenBalance(
        string memory name
    ) internal returns (address payable) {
        address payable user = _createUser(name);
        vm.startPrank(user);
        token.mint(user, defaultTokenBalance);
        assertEq(token.balanceOf(user), defaultTokenBalance);
        vm.stopPrank();
        return user;
    }

    function _faucetToken(
        address tokenAddress,
        address whale,
        address to,
        uint256 amount
    ) internal {
        vm.startPrank(whale);
        assert(ERC20(tokenAddress).balanceOf(whale) > 0);
        ERC20(tokenAddress).transfer(to, amount);
        vm.stopPrank();
    }

    function _faucet(address user) internal {
        vm.startPrank(user);
        token.mint(user, defaultTokenBalance);
        assertEq(token.balanceOf(user), defaultTokenBalance);
        vm.stopPrank();
    }

    function _createIP(
        address to,
        bool approveAll
    ) public returns (IPHolder instance, NFT ipIssuer) {
        ipIssuer = new NFT("My IP", "MP");
        ipSchema = Schema({
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
        });
        licensingAttestation.registerSchema(ipSchema);
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
        licensingAttestation.addAdmin(address(instance));
        console.log("id: ", ILicensingModule(LICENSING_MODULE).totalPolicies());
        //approve contract
        if(approveAll) {
            ipIssuer.setApprovalForAll(address(instance), true);
            assertEq(ipIssuer.isApprovedForAll(to, address(instance)), true);
        }
        vm.label(address(instance), "IPHolder");
        vm.label(address(ipIssuer), "NFT");
        vm.label(address(licensingAttestation), "IPLicensingAttestation");
    }


    function _mintIPs(
        NFT ipIssuer,
        address to,
        uint96 count
    ) internal returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = ipIssuer.mint(to);
            tokenIds[i] = tokenId;
        }
        return tokenIds;
    }

    modifier whenNotApprovedForAll() {
  
        _;
    }
}
