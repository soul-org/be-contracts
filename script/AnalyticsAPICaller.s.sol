// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {AnalyticsAPICaller} from "../src/staking/analytics/AnalyticsAPICaller.sol";

contract AnalyticsAPICallerScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes32 _dontID = vm.envBytes32("CHAINLINK_DONT_ID");
        address _router = vm.envAddress("CHAINLINK_ROUTER");

        AnalyticsAPICaller caller = new AnalyticsAPICaller(_dontID, _router);

        vm.stopBroadcast();
    }
}
