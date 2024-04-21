## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Installation

Before anything ensure you have node and npm install then run `npm i`

## Documentation

https://book.getfoundry.sh/ also ensure you have node with npm installed then run `yarn ` or `npm i`

## Usage

https://book.getfoundry.sh/

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test -vvvvv
```

### Deploy

- To deploy i would suggest you fork seploia by running the base file name <b>fork.bash</b> then copy the private keys from the console and add to the <b>.env</b> file see <b>env.example</b>
- Once the forked node has been started then run
  `forge clean;forge script script/IPHolderRegistrar.s.sol:IPHolderRegistrarScript --rpc-url  http://127.0.0.1:8545 --broadcast --verify --code-size-limit 31000  -vvvvv`
