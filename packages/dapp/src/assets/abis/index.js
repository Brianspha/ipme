const NFT_BYTECODE = require("../../../../contracts/out/NFT.sol/NFT.json").bytecode
  .object;
const NFT_ABI = require("../../../../contracts/out/NFT.sol/NFT.json").abi;
const TOKEN_ABI = require("../../../../contracts/out/Token.sol/Token.json").abi;
const IP_ATTESTATION_ABI =
  require("../../../../contracts/out/IPLicensingAttestation.sol/IPLicensingAttestation.json").abi;

const IP_HOLDER_ABI =
  require("../../../../contracts/out/IPHolder.sol/IPHolder.json").abi;
const IP_HOLDER_BYTECODE =
  require("../../../../contracts/out/IPHolder.sol/IPHolder.json").abi;
const IP_REGISTRAR_ABI =
  require("../../../../contracts/out/IPHolderRegistrar.sol/IPHolderRegistrar.json").abi;
module.exports = {
  IP_REGISTRAR_ABI,
  IP_HOLDER_BYTECODE, 
  IP_HOLDER_ABI,
  IP_ATTESTATION_ABI,
  TOKEN_ABI,
  NFT_ABI,
  NFT_BYTECODE,
};
