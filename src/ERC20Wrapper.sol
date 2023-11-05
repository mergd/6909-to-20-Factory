// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC6909} from "@solmate/tokens/ERC6909.sol";
import {ERC6909Metadata} from "ERC-6909/ERC6909Metadata.sol";
/// @title Simple wrapper for 6906 to 20

contract ERC20Wrapper is ERC20 {
    uint256 public immutable id;
    ERC6909 public immutable token;

    constructor(uint256 _id, uint8 _decimals, string memory _name, string memory _symbol, ERC6909 _token)
        ERC20(_name, _symbol, _decimals)
    {
        id = _id;
        token = _token;
    }

    function mint(address receiver, uint256 amount) external {
        token.transferFrom(msg.sender, address(this), id, amount);
        _mint(receiver, amount);
    }

    function burn(address receiver, uint256 amount) external {
        _burn(receiver, amount);
        token.transferFrom(address(this), msg.sender, id, amount);
    }
}
