// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Impression is ERC20 {

    event Minted(address to, uint256 amount);

    constructor(uint256 initialSupply, address _admin)
        ERC20("Impression", "IMP")
    {
        _mint(_admin, initialSupply);
    }

    /**
     * @notice  Burn `amount` tokens and decreasing the total supply.
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}
