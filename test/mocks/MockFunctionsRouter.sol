// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@chainlink/contracts/v0.8/functions/dev/v1_0_0/interfaces/IFunctionsRouter.sol";

contract MockFunctionsRouter is IFunctionsRouter {
    function getAllowListId() external view override returns (bytes32) {}

    function setAllowListId(bytes32 allowListId) external override {}

    function getAdminFee() external view override returns (uint72 adminFee) {}

    function sendRequest(
        uint64 subscriptionId,
        bytes calldata data,
        uint16 dataVersion,
        uint32 callbackGasLimit,
        bytes32 donId
    ) external override returns (bytes32) {
        return bytes32("123");
    }

    function sendRequestToProposed(
        uint64 subscriptionId,
        bytes calldata data,
        uint16 dataVersion,
        uint32 callbackGasLimit,
        bytes32 donId
    ) external override returns (bytes32) {}

    function fulfill(
        bytes memory response,
        bytes memory err,
        uint96 juelsPerGas,
        uint96 costWithoutFulfillment,
        address transmitter,
        FunctionsResponse.Commitment memory commitment
    ) external override returns (FunctionsResponse.FulfillResult, uint96) {}

    function isValidCallbackGasLimit(uint64 subscriptionId, uint32 callbackGasLimit) external view override {}

    function getContractById(bytes32 id) external view override returns (address) {}

    function getProposedContractById(bytes32 id) external view override returns (address) {}

    function getProposedContractSet() external view override returns (bytes32[] memory, address[] memory) {}

    function proposeContractsUpdate(bytes32[] memory proposalSetIds, address[] memory proposalSetAddresses)
        external
        override
    {}

    function updateContracts() external override {}

    function pause() external override {}

    function unpause() external override {}
}
