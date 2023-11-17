// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC6909} from "@solmate/tokens/ERC6909.sol";
import {ERC6909Metadata} from "ERC-6909/ERC6909Metadata.sol";
import {ERC6909ib} from "ERC-6909/ERC6909ib.sol";
import "./ERC20Wrapper.sol";
import "./ERC4626Wrapper.sol";
import "./ERC1155Wrapper.sol";
/// @title Wrapper Factory

contract ERC6909WrapperFactory {
    event ERC20WrapperCreated(address indexed wrapper, uint256 indexed id, address indexed token);
    event ERC4626WrapperCreated(address indexed wrapper, uint256 indexed id, address indexed token);
    event ERC1155WrapperCreated(address indexed wrapper, address indexed token);

    mapping(address multiToken => mapping(uint256 id => address wrapper)) public erc20Wrapper;
    mapping(address multiToken => mapping(uint256 id => address wrapper)) public erc4626Wrapper;
    mapping(address multiToken => address wrapper) public erc1155Wrapper;

    constructor() {}

    function createERC20Wrapper(uint256 id, address token) external returns (ERC20Wrapper wrapper) {
        if (erc20Wrapper[token][id] != address(0)) return ERC20Wrapper(erc20Wrapper[token][id]);

        uint8 decimals = ERC6909Metadata(token).decimals(id);
        if (decimals == 0) revert("WRONG_DECIMALS"); // Token might not support 6909Metadata
        string memory name = ERC6909Metadata(token).name();
        string memory symbol = ERC6909Metadata(token).symbol();
        wrapper = new ERC20Wrapper(id, decimals, name, symbol, ERC6909(token));
        erc20Wrapper[token][id] = address(wrapper);
        emit ERC20WrapperCreated(address(wrapper), id, token);
    }

    function createERC4626Wrapper(uint256 id, address token) external returns (ERC4626Wrapper wrapper) {
        if (erc20Wrapper[token][id] != address(0)) return ERC4626Wrapper(erc20Wrapper[token][id]);

        uint8 decimals = ERC6909ib(token).decimals(id);
        if (decimals == 0) revert("WRONG_DECIMALS"); // Token might not support 6909ib
        address asset = address(ERC6909ib(token).asset(id));
        if (asset == address(0)) revert("NO_ASSET");
        string memory name = ERC6909ib(token).name();
        string memory symbol = ERC6909ib(token).symbol();
        wrapper = new ERC4626Wrapper(id, decimals,asset, name, symbol, address(token));
        erc4626Wrapper[token][id] = address(wrapper);
        emit ERC4626WrapperCreated(address(wrapper), id, token);
    }

    function createERC1155Wrapper(address token) external returns (ERC1155Wrapper wrapper) {
        if (erc1155Wrapper[token] != address(0)) return ERC1155Wrapper(erc1155Wrapper[token]);

        string memory name = ERC6909Metadata(token).name();
        string memory symbol = ERC6909Metadata(token).symbol();
        wrapper = new ERC1155Wrapper(name, symbol, ERC6909(token));
        erc1155Wrapper[token] = address(wrapper);
        emit ERC1155WrapperCreated(address(wrapper), token);
    }
}
