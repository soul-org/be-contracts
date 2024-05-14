// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/staking/analytics/AnalyticsAPICaller.sol";
import "./mocks/MockFunctionsRouter.sol";

contract AnalyticsAPICallerTest is Test {
    AnalyticsAPICaller apiCaller;
    MockFunctionsRouter router;
    address owner;
    address user;

    function setUp() public {
        owner = address(this);
        user = vm.addr(0x1);
        router = new MockFunctionsRouter();
        apiCaller = new AnalyticsAPICaller(bytes32("123"), address(router));
    }

    function test_checkPublicMembers() external view {
        assertEq(apiCaller.donID(), bytes32("123"));
        assertEq(apiCaller.router(), address(router));
        assertEq(apiCaller.gasLimit(), 300000);
    }

    function testFail_sendRequest() external {
        string[] memory args = new string[](1);
        args[0] = "NY";

        bytes32 requestId = apiCaller.sendRequest(1234, args);

        assertEq(requestId,bytes32("123"));
    }
}
