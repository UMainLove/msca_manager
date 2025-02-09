// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

import {Create2} from "../lib/openzeppelin-contracts/contracts/utils/Create2.sol";

import {MessagingPlugin} from "../src/MessagingPlugin.sol";

contract DeployMessaging is Script {

    // Optional salt for create2 deployment
    bytes32 constant SALT = bytes32(uint256(0x44556677));

    function run() public {

        console.log("******** Deploying MessagingPlugin *********");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        //deployment
       address deployer = vm.addr(deployerPrivateKey);
        
        console.log("******** Deploying MessagingPlugin *********");
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy using CREATE2
        MessagingPlugin messagingPlugin = new MessagingPlugin{salt: SALT}();
        
        console.log("MessagingPlugin deployed at:", address(messagingPlugin));

        vm.stopBroadcast();
    }
}