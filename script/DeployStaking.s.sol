// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Script.sol";
import {Staking} from "../src/staking/Staking.sol";

contract DeployStaking is Script {
    address s_stakingToken = 0x83595a293426Cc9c49F8C13aFaa55e166433fbCB;
    address s_rewardToken = 0xA39152F694d5dcCd34C6B64b46bBe9232BE4945d;

    function run() external returns (Staking) {
        vm.startBroadcast();
        // Deploy the Staking contract
        Staking staking = new Staking(s_stakingToken, s_rewardToken);
        vm.stopBroadcast();
        return staking;
    }
}
