// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20Wrapper.sol";
import {ERC4626} from "./interfaces/ERC4626.sol";
import {ERC6909ib} from "./interfaces/ERC6909ib.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

contract ERC4626Wrapper is ERC4626 {
    using SafeTransferLib for ERC20;

    uint256 public immutable id;
    ERC6909ib public immutable token;
    ERC20 public immutable asset;
    uint256 public override totalAssets;

    // Underlying 6909 should implement previewDeposits, previewWithdrawals, and totalAssets, with tokenId as an extra field
    // Wrapper

    constructor(
        uint256 _id,
        uint8 _decimals,
        address _asset,
        string memory _name,
        string memory _symbol,
        address _token
    ) ERC20(_name, _symbol, _decimals) {
        id = _id;
        token = ERC6909ib(_token);
        asset = ERC20(_asset);
        asset.approve(_token, type(uint256).max);
    }

    function totalSupply() public view override returns (uint256 totalShares) {
        return totalAssets;
    }

    function deposit(uint256 _assets, address _receiver) external override returns (uint256 shares) {
        token.transferFrom(msg.sender, address(this), id, _assets);
        shares = token.deposit(id, _assets, _receiver);
        emit Deposit(msg.sender, _receiver, _assets, shares);
    }

    function mint(uint256 _shares, address _receiver) external override returns (uint256 assets) {
        token.transferFrom(msg.sender, address(this), id, _shares);
        assets = token.mint(id, _shares, _receiver);
        _mint(_receiver, _shares);

        emit Deposit(msg.sender, _receiver, assets, _shares);
    }

    function withdraw(uint256 _assets, address _receiver, address _owner) external override returns (uint256 shares) {
        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[_owner][msg.sender] = allowed - shares;
        }
        shares = previewWithdraw(_assets);
        _burn(_owner, shares);
        token.withdraw(id, _assets, _receiver, address(this));
        emit Withdraw(msg.sender, _receiver, _owner, _assets, shares);
    }

    function redeem(uint256 _shares, address _receiver, address _owner) external override returns (uint256 assets) {
        if (msg.sender != _owner) {
            uint256 allowed = allowance[_owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[_owner][msg.sender] = allowed - _shares;
        }
        assets = previewRedeem(_shares);
        _burn(_owner, _shares);
        token.redeem(id, _shares, _receiver, address(this));
        emit Withdraw(msg.sender, _receiver, _owner, assets, _shares);
    }

    function maxMint(address _receiver) external view override returns (uint256 maxShares) {
        return token.maxMint(id, _receiver);
    }

    function previewMint(uint256 _shares) public view override returns (uint256 assets) {
        return token.previewMint(id, _shares);
    }

    function maxWithdraw(address _owner) public view override returns (uint256 maxAssets) {
        return previewWithdraw(balanceOf[_owner]);
    }

    function previewWithdraw(uint256 _assets) public view override returns (uint256 shares) {
        return token.previewWithdraw(id, _assets);
    }

    function maxRedeem(address _owner) public view override returns (uint256 maxShares) {
        return token.maxRedeem(id, _owner);
    }

    function previewRedeem(uint256 _shares) public view override returns (uint256 assets) {
        return token.previewRedeem(id, _shares);
    }

    function convertToShares(uint256 _assets) public view override returns (uint256 shares) {
        return token.convertToShares(id, _assets);
    }

    function convertToAssets(uint256 _shares) public view override returns (uint256 assets) {
        return token.convertToAssets(id, _shares);
    }

    function maxDeposit(address _receiver) public view override returns (uint256 maxAssets) {
        return token.maxDeposit(id, _receiver);
    }

    function previewDeposit(uint256 _assets) public view override returns (uint256 shares) {
        return token.previewDeposit(id, _assets);
    }
}
