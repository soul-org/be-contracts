// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../lib/forge-std/src/Script.sol";
import "../../src/staking/token/TokenTransferor.sol";

contract DeployPolygonTokenTransferor is Script {
    //matic
    uint64 s_AvaxDestinationChainSelector = 14767482510784806043;
    address s_maticRouter = 0x9C32fCB86BF0f4a1A8921a9Fe46de3198bb884B2;
    address s_linkContract = 0x0Fd9e8d3aF1aaee056EB9e802c3A762a667b1904;

    function run() external returns (TokenTransferor) {
        vm.startBroadcast();
        // Deploy the Staking contract
        TokenTransferor tokenTransferor = new TokenTransferor(s_maticRouter, s_linkContract);
        tokenTransferor.allowlistDestinationChain(s_AvaxDestinationChainSelector, true);

        vm.stopBroadcast();
        return tokenTransferor;
    }
}