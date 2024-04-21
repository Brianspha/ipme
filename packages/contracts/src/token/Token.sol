// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Token
 * @dev This contract extends an ERC20 implementation from OpenZeppelin to provide basic token functionalities with customizable decimals.
 * It allows for token minting with flexible decimal places, different from the standard 18 decimals used by most ERC20 tokens.
 */
contract Token is ERC20 {
    // State variable to store the number of decimal places for the token
    uint8 private _decimals;

    /**
     * @dev Constructor for the Token contract.
     * Initializes the ERC20 token with a name, symbol, and a custom number of decimals.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals_ The number of decimal places the token uses.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;  // Set the number of decimals for this instance
    }

    /**
     * @dev Mints new tokens to a specified address.
     * This function is public and allows new tokens to be created and assigned to the `to` address.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);  // Call the internal _mint function from the ERC20 contract.
    }

    /**
     * @dev Returns the number of decimal places used by the token.
     * Overrides the `decimals` function in the ERC20 implementation.
     * @return The number of decimals the token uses.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;  // Return the custom number of decimals.
    }
}
