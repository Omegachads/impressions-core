// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// Import IERC20 from openzeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ImpressionStake is Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    address private whitelistSignerAddress;
    // Impression token address
    IERC20 public impressionTokenAddress;
    // Charity Fund
    address public charityFund;
    // Variable to track the an increasing requestId
    uint256 public requestId;
    // Variable to track charity param
    uint256 public charityParam;
    // Struct of a message request
    struct MessageRequest {
        address from;
        address to;
        uint256 amount;
    }
    // Mapping of message requests
    mapping(uint256 => MessageRequest) private messageRequests;
    // Mapping of user address to cost
    mapping(address => uint256) public userCost;

    // Events
    // Event of message request created
    event MessageRequestCreated(
        uint256 indexed requestId,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes32 msgHash
    );

    // Modifiers

    /**
     * @dev Prevent Smart Contracts from calling the functions with this modifier
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "ImpressionStake: must use EOA");
        _;
    }

    constructor(
        address _owner,
        address _charity,
        address _whitelistSignerAddress,
        address _impressionTokenAddress
    ) {
        impressionTokenAddress = IERC20(_impressionTokenAddress);
        setCharity(_charity);
        setWhitelistSignerAddress(_whitelistSignerAddress);
        transferOwnership(_owner);
    }

    // -------------------- FUNCTIONS --------------------------

    // Request message
    function requestMessage(
        address _to,
        uint256 _amount,
        bytes32 _msgHash
    ) public onlyEOA {
        require(_to != address(0), "ImpressionStake: to address cannot be 0");
        // Require that user has a cost
        require(
            userCost[_to] > 0,
            "ImpressionStake: user cost must be greater than 0"
        );
        // Check user's price and require that the amount is greater than that
        require(
            _amount >= userCost[_to],
            "ImpressionStake: amount must be greater than receiver cost"
        );
        // Create message request
        uint256 _requestId = uint256(keccak256(abi.encodePacked(_msgHash)));
        messageRequests[_requestId] = MessageRequest(msg.sender, _to, _amount);

        // Transfer Impression tokens to this contract
        impressionTokenAddress.transferFrom(msg.sender, address(this), _amount);
        // Emit event
        emit MessageRequestCreated(
            _requestId,
            msg.sender,
            _to,
            _amount,
            _msgHash
        );
    }

    // Batch request message
    function batchRequestMessage(
        address[] calldata _to,
        uint256[] calldata _amount,
        bytes32 _msgHash
    ) external onlyEOA {
        require(
            _to.length == _amount.length,
            "ImpressionStake: to and amount arrays must be the same length"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            requestMessage(_to[i], _amount[i], _msgHash);
        }
    }

    // Get message request
    function getMessageRequest(
        uint256 _requestId
    ) external view returns (MessageRequest memory) {
        return messageRequests[_requestId];
    }

    // Claim message only after signature is verified
    function claimMessage(
        uint256 _requestId,
        bytes memory _signature,
        bytes memory _messageHash
    ) external onlyEOA {
        // Get message request
        MessageRequest memory _messageRequest = messageRequests[_requestId];
        // Require that the message request exists
        require(
            _messageRequest.to != address(0),
            "ImpressionStake: message request does not exist"
        );
        // Require that the message request is not claimed
        require(
            _messageRequest.amount > 0,
            "ImpressionStake: message request already claimed"
        );
        // Verify signature
        bytes32 _hash = keccak256(
            abi.encodePacked(_requestId, _messageRequest.to, _messageHash) //uint256, address, bytes
        );
        address _signer = ECDSA.toEthSignedMessageHash(_hash).recover(
            _signature
        );
        require(
            _signer == whitelistSignerAddress,
            "ImpressionStake: invalid signature"
        );
        // Transfer 99% of Impression tokens to receiver
        impressionTokenAddress.transfer(
            _messageRequest.to,
            (_messageRequest.amount * (100 - charityParam)) / 100
        );
        // Transfer 1% of Impression tokens to charity
        impressionTokenAddress.transfer(
            charityFund,
            (_messageRequest.amount * charityParam) / 100
        );

        // Set message request amount to 0
        messageRequests[_requestId].amount = 0;
    }

    // Set user cost
    function setUserCost(uint256 _cost) external {
        // cannot be 0
        require(_cost > 0, "ImpressionStake: cost cannot be 0");
        // Set user cost
        userCost[msg.sender] = _cost;
    }

    // ------------------------- OWNER FUNCTIONS ----------------------------

    function setWhitelistSignerAddress(address signer) public onlyOwner {
        whitelistSignerAddress = signer;
    }

    // Set charityParam
    function setCharityParam(uint256 _charityParam) public onlyOwner {
        // Cannot be greater than 100
        require(
            _charityParam <= 100,
            "ImpressionStake: charity param cannot be greater than 100"
        );
        charityParam = _charityParam;
    }

    /**
     * @notice Sets the charity fund address
     */
    function setCharity(address _charityFund) public onlyOwner {
        charityFund = _charityFund;
    }
}
