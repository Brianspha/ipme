// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "./base/IPHolderBaseTest.t.sol";

contract IPHolderRegistrarTest is IPHolderBaseTest {
    function setUp() public override {
        IPHolderBaseTest.setUp();
    }

    function test_deployIPHolderAndRegisterIP() public {
        vm.selectFork(sepoliaForkId);
        vm.startPrank(owner);

        IPHolder instance;
        NFT ipIssuer;

        (instance, ipIssuer) = _createIP(owner, true);
        assert(instance != IPHolder(address(0)));
        vm.stopPrank();
    }

    function test_mintNFTAndVerifyOwnership() public {
        vm.startPrank(owner);
        IPHolder instance;
        NFT ipIssuer;

        (instance, ipIssuer) = _createIP(owner, true);
        uint256[] memory tokenIds = _mintIPs(ipIssuer, owner, 1);
        uint256 tokenId = tokenIds[0];

        assertEq(ipIssuer.ownerOf(tokenId), owner);

        vm.stopPrank();
    }

    function test_issueLicenseAndValidate() public {
        vm.startPrank(owner);
        IPHolder instance;
        NFT ipIssuer;

        (instance, ipIssuer) = _createIP(owner, true);
        uint256[] memory tokenIds = _mintIPs(ipIssuer, owner, 1);
        uint256 tokenId = tokenIds[0];
        token.approve(address(instance), UINT256_MAX);
        instance.registerAndAddPolicy(
            IPSematicsWithPolicy({
                url: "google.com",
                ipName: "Special IP",
                policyId: 1,
                tokenId: tokenId,
                contentHash: bytes32(
                    abi.encodePacked(
                        '{"description": "Test SPG contract", ',
                        '"external_link": "https://storyprotocol.xyz", ',
                        '"image": "https://storyprotocol.xyz/ip.jpeg", ',
                        '"name": "SPG Default Collection"}'
                    )
                ),
                policySettings: policySettings,
                attestationData: "test"
            })
        );
        IPDetails[] memory accountDetails = instance.accountIPDetails(owner);
        IPDetails memory details = accountDetails[0];
        IP.MetadataV1 memory metada = instance.metadata(
            address(details.ipIdAccount)
        );

        console.log("IP Details");
        console.log(address(details.ipIdAccount));
        console.log(details.indexOnIpId);
        console.log(details.policyId);
        console.log(metada.name);
        vm.stopPrank();
        console.log("sphasBalance:%o", token.balanceOf(spha));
        vm.startPrank(spha);
        token.approve(address(instance), UINT256_MAX);
        instance.issueLicense(
            IPLease({
                receiver: spha,
                policyId: details.policyId,
                licensorIpId: address(details.ipIdAccount),
                amount: 1,
                royaltyContext: "0x"
            })
        );
        uint256[] memory licenseIds = instance.accountLicenses(
            address(details.ipIdAccount)
        );
        console.log("licenseIds: %o", licenseIds[0]);
        console.log(
            "ipIdAccount:%o",
            token.balanceOf(address(details.ipIdAccount))
        );
        assert(licenseIds.length > 0); // Check if a license was actually issued

        vm.stopPrank();
    }

    function test_registerIPAndAddPolicy() public {
        vm.startPrank(owner);
        IPHolder instance;
        NFT ipIssuer;

        (instance, ipIssuer) = _createIP(owner, true);
        uint256[] memory tokenIds = _mintIPs(ipIssuer, owner, 1);
        uint256 tokenId = tokenIds[0];

        instance.registerAndAddPolicy(
            IPSematicsWithPolicy({
                url: "google.com",
                ipName: "Special IP",
                policyId: 1,
                tokenId: tokenId,
                contentHash: bytes32(
                    abi.encodePacked(
                        '{"description": "Test SPG contract", ',
                        '"external_link": "https://storyprotocol.xyz", ',
                        '"image": "https://storyprotocol.xyz/ip.jpeg", ',
                        '"name": "SPG Default Collection"}'
                    )
                ),
                policySettings: policySettings,
                attestationData: "test"
            })
        );

        IPDetails[] memory accountDetails = instance.accountIPDetails(owner);
        assertEq(accountDetails.length, 1);

        vm.stopPrank();
    }

    function test_issueLicenseAndValidate_Revert()
        public
        whenNotApprovedForAll
    {
        vm.startPrank(owner);
        IPHolder instance;
        NFT ipIssuer;

        (instance, ipIssuer) = _createIP(owner, false);
        (owner, instance);
        uint256[] memory tokenIds = _mintIPs(ipIssuer, owner, 1);
        uint256 tokenId = tokenIds[0];
        token.approve(address(instance), UINT256_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InsufficientApproval.selector,
                address(instance),
                tokenId
            )
        );
        instance.registerAndAddPolicy(
            IPSematicsWithPolicy({
                url: "google.com",
                ipName: "Special IP",
                policyId: 1,
                tokenId: tokenId,
                contentHash: bytes32(
                    abi.encodePacked(
                        '{"description": "Test SPG contract", ',
                        '"external_link": "https://storyprotocol.xyz", ',
                        '"image": "https://storyprotocol.xyz/ip.jpeg", ',
                        '"name": "SPG Default Collection"}'
                    )
                ),
                policySettings: policySettings,
                attestationData: "test"
            })
        );

        vm.stopPrank();
    }
}
