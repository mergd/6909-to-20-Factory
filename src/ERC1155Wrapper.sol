// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC1155} from "@solmate/tokens/ERC1155.sol";
import {ERC6909} from "@solmate/tokens/ERC6909.sol";
import {ERC6909MetadataURI} from "ERC-6909/ERC6909MetadataURI.sol";
/// @title Simple wrapper for 6906 to 1155

contract ERC1155Wrapper is ERC1155 {
    ERC6909 public immutable token;
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol, ERC6909 _token) {
        token = _token;
        name = _name;
        symbol = _symbol;
    }

    function mint(uint256 id, address receiver, uint256 amount) external {
        token.transferFrom(msg.sender, address(this), id, amount);
        _mint(receiver, id, amount, "");
    }

    function burn(uint256 id, address receiver, uint256 amount) external {
        _burn(receiver, id, amount);
        token.transferFrom(address(this), msg.sender, id, amount);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return ERC6909MetadataURI(address(token)).tokenURI(id);
    }
}
