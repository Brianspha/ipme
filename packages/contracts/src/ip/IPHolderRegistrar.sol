// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

// Importing necessary components from OpenZeppelin for upgradeability and ownership, as well as local contracts.
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IPHolderData} from "../utils/IPHolderData.sol";
import {IPHolder} from "./IPHolder.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IIPLicensingAttestation} from "../sign/IIPLicensingAttestation.sol";
import {IIPHolderRegistrar} from "./IIPHolderRegistrar.sol";

/**
 * @title IPHolderRegistrar
 * @dev This contract serves as a factory and registry for IPHolder contracts. It allows users to deploy IPHolder
 * contracts with specific settings and maintains a registry of deployed contracts for each user. The contract
 * is upgradeable using the UUPS pattern and ensures that only the owner can perform upgrades.
 */
contract IPHolderRegistrar is
    IIPHolderRegistrar,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    // Mapping from user addresses to their deployed IPHolder contract addresses.
    mapping(address => address[]) public userIPCollection;
    IIPLicensingAttestation public ipAttestor;
    address[] public ipInstances;
    // events
    event IPDeployed(address indexed user, address indexed ipHolder);

    /**
     * @dev Initializes the contract by setting up UUPS upgradeability and ownership.
     * It is meant to be called once by the factory or deployer of the contract instance.
     */
    function initialize(
        IIPLicensingAttestation ipAttestor_
    ) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(msg.sender);
        ipAttestor = ipAttestor_;
    }

    /// @inheritdoc IIPHolderRegistrar
    function deployIP(
        IPSettings memory settings
    ) public override returns (IPHolder) {
        IPHolder instance = new IPHolder(settings);
        userIPCollection[msg.sender].push(address(instance));
        ipAttestor.addAdmin(address(instance));
        ipInstances.push(address(instance));
        emit IPDeployed(msg.sender, address(instance));
        return instance;
    }

    /// @inheritdoc IIPHolderRegistrar
    function userIps(
        address user
    ) public view override returns (address[] memory) {
        return userIPCollection[user];
    }

    /// @inheritdoc IIPHolderRegistrar
    function allInstances() public view override returns (address[] memory) {
        return ipInstances;
    }

    /// @inheritdoc IIPHolderRegistrar
    function revokeAdmin(address ipHolder) public override onlyOwner {
        revert("Not implemented");
    }

    /**
     * @dev Overrides the _authorizeUpgrade function from UUPSUpgradeable to include access control.
     * Ensures that only the owner of the contract can authorize upgrades.
     * @param newImplementation The address of the new contract implementation to upgrade to.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
