// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Script.sol";
import "../../src/staking/token/TokenTransferor.sol";

contract DeployStaking is Script {
    //avax
    uint64 s_PolygonDestinationChainSelector = 16281711391670634445;
    address s_router = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address s_linkContract = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;


    function run() external returns (TokenTransferor) {
        vm.startBroadcast();
        // Deploy the Staking contract
        TokenTransferor tokenTransferor = new TokenTransferor(s_router, s_linkContract);
        tokenTransferor.allowlistDestinationChain(s_PolygonDestinationChainSelector, true);
        
        vm.stopBroadcast();
        return tokenTransferor;
    }
}