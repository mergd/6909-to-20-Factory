// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC6909} from "@solmate/tokens/ERC6909.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
// Interest bearing ERC6909
// Direct fork of the Solmate implementation, but with extra TokenId field.

abstract contract ERC6909ib is ERC6909 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(uint256 indexed id, address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        uint256 indexed id,
        address caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The name of the token.
    string public name;

    /// @notice The symbol of the token.
    string public symbol;

    /// @notice The asset of the token.
    ERC20 public immutable asset;

    /// @notice The asset of the token.
    uint256 public immutable decimals;

    constructor(string memory _name, string memory _symbol, ERC20 _asset) {
        name = _name;
        symbol = _symbol;
        asset = _asset;
        decimals = _asset.decimals();
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
    function deposit(uint256 tokenId, uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(tokenId, assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, tokenId, shares);

        emit Deposit(tokenId, msg.sender, receiver, assets, shares);

        afterDeposit(tokenId, assets, shares);
    }

    function mint(uint256 tokenId, uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(tokenId, shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, tokenId, shares);

        emit Deposit(tokenId, msg.sender, receiver, assets, shares);

        afterDeposit(tokenId, assets, shares);
    }

    function withdraw(uint256 tokenId, uint256 assets, address receiver, address owner)
        public
        virtual
        returns (uint256 shares)
    {
        shares = previewWithdraw(tokenId, assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender][tokenId]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender][tokenId] = allowed - shares;
        }

        beforeWithdraw(tokenId, assets, shares);

        _burn(owner, tokenId, shares);

        emit Withdraw(tokenId, msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(uint256 tokenId, uint256 shares, address receiver, address owner)
        public
        virtual
        returns (uint256 assets)
    {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender][tokenId]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender][tokenId] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(tokenId, shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(tokenId, assets, shares);

        _burn(owner, tokenId, shares);

        emit Withdraw(tokenId, msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 tokenId, uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply[tokenId]; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 tokenId, uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply[tokenId]; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 tokenId, uint256 assets) public view virtual returns (uint256) {
        return convertToShares(tokenId, assets);
    }

    function previewMint(uint256 tokenId, uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply[tokenId]; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 tokenId, uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply[tokenId]; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 tokenId, uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(tokenId, shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(uint256, address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(uint256, address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(uint256 tokenId, address owner) public view virtual returns (uint256) {
        return convertToAssets(tokenId, balanceOf[owner][tokenId]);
    }

    function maxRedeem(uint256 tokenId, address owner) public view virtual returns (uint256) {
        return balanceOf[owner][tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 tokenId, uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 id, uint256 assets, uint256 shares) internal virtual {}
}
