// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;
import {ERC721, IERC721Errors} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721 {
    // Public array to store all minted token IDs. Useful for tracking and displaying all tokens.
    uint256[] public tokens;

    // Custom errors to provide specific revert messages for failed operations.
    error InvalidTokenQuantity(); // Error to be thrown if a function receives an invalid number of tokens.
    error TokensNotMinted(); // Error to be thrown if a token minting operation fails.

    // State variable to keep track of the total number of tokens minted.
    uint256 public totalSupply;

    /**
     * @dev Constructor for the NFT contract.
     * Initializes the ERC721 token with a name and a symbol.
     * @param name The name of the NFT collection.
     * @param symbol The symbol of the NFT collection.
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    /**
     * @dev Public function to mint a new token.
     * The function increments the total supply, mints the new token to the specified address,
     * and returns the new token ID.
     * @param to The address to which the new token will be minted.
     * @return The new token ID that was minted.
     */
    function mint(address to) public returns (uint256) {
        ++totalSupply; // Increment the total supply counter before minting to use as the new token ID.
        _safeMint(to, totalSupply); 
        tokens.push(totalSupply); 
        return totalSupply; 
    }
}
