// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {IRouterClient} from "@chainlink/contracts-ccip/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/v0.8/ccip/libraries/Client.sol";
import {MessageReceiver} from "../../src/staking/messenger/MessageReciever.sol";

contract MockCCIPRouter is IRouterClient {
    function isChainSupported(
        uint64 chainSelector
    ) external view override returns (bool supported) {
        return true;
    }

    function getSupportedTokens(
        uint64 chainSelector
    ) external view override returns (address[] memory tokens) {
        address[] memory _tokens = new address[](1);
        return _tokens;
    }

    function getFee(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage memory message
    ) external view override returns (uint256 fee) {
        return uint256(1);
    }

    function ccipSend(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage calldata message
    ) external payable override returns (bytes32) {
        address receiver = abi.decode(message.receiver, (address)); 
        bytes memory data = message.data;
        bytes32 messageId = "123";
        uint64 sourceChainSelector = 2;
        Client.EVMTokenAmount[] memory destTokenAmounts = new Client.EVMTokenAmount[](1);
        Client.Any2EVMMessage memory recievedMsg = Client.Any2EVMMessage({
            messageId: messageId,
            sourceChainSelector: sourceChainSelector, 
            sender: abi.encode(address(this)), 
            data: data, 
            destTokenAmounts: destTokenAmounts});
        MessageReceiver msgReceiver = MessageReceiver(receiver);
        msgReceiver.ccipReceive(recievedMsg);
        return messageId;
    }
}
