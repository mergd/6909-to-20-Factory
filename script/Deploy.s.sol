// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";

import {ERC6909WrapperFactory} from "src/ERC6909WrapperFactory.sol";

contract Deploy is Script {
    ERC6909WrapperFactory public factory;

    function run() external returns (Greeter greeter) {
        uint256 deployerKey = vm.envUint("deployerKey");
        vm.startBroadcast(deployerKey);
        factory = new ERC6909WrapperFactory();
        vm.stopBroadcast();
    }
}
