// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MessageReceiver} from "../src/staking/messenger/MessageReciever.sol";
import {MessageSender} from "../src/staking/messenger/MessageSender.sol";
import {MockCCIPRouter} from "./mocks/MockCCIPRouter.sol";
import {MockLinkToken} from "./mocks/MockLinkToken.sol";

contract MessengerTest is Test {
    MessageReceiver reciever;
    MessageSender sender;
    MockCCIPRouter router;
    MockLinkToken link;

    struct MessageDetails {
        bytes32 messageId;
        uint64 chainSelector;
        address sender;
        string message;
    }

    function setUp() public {
        link = new MockLinkToken();
        router = new MockCCIPRouter();
        sender = new MessageSender(address(router), address(link));
        reciever = new MessageReceiver(address(router));
    }

    function test_getLatestMessageDetails() external {
        bytes32 sendMsgId = sender.send(1, address(reciever), "Test", MessageSender.PayFeesIn.LINK);
        assertEq(sendMsgId, bytes32("123"));
        (bytes32 recvMsgId, uint64 chainSelector, address senderAddr, string memory message) =
            reciever.getLatestMessageDetails();
        assertEq(recvMsgId, sendMsgId);
        assertEq(message, "Test");
    }
}
