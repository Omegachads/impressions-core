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
        uint256 amount
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
        address _whitelistSignerAddress,
        address _impressionTokenAddress
    ) {
        impressionTokenAddress = IERC20(_impressionTokenAddress);
        setCharity(_owner);
        setWhitelistSignerAddress(_whitelistSignerAddress);
        transferOwnership(_owner);
    }

    // -------------------- FUNCTIONS --------------------------

    // Request message
    function requestMessage(address _to, uint256 _amount)
        external
        payable
        onlyEOA
    {
        require(_to != address(0), "ImpressionStake: to address cannot be 0");
        // Require that user has a cost
        require(
            userCost[msg.sender] > 0,
            "ImpressionStake: user cost must be greater than 0"
        );
        // Check user's price and require that the amount is greater than that
        require(
            _amount >= userCost[_to],
            "ImpressionStake: amount must be greater than receiver cost"
        );
        // Create message request
        uint256 _requestId = uint256(
            keccak256(abi.encodePacked(_to, _amount, block.timestamp))
        );
        messageRequests[_requestId] = MessageRequest(msg.sender, _to, _amount);

        // Transfer Impression tokens to this contract
        impressionTokenAddress.transferFrom(msg.sender, address(this), _amount);
        // Emit event
        emit MessageRequestCreated(_requestId, msg.sender, _to, _amount);
    }

    // Get message request
    function getMessageRequest(uint256 _requestId)
        external
        view
        returns (MessageRequest memory)
    {
        return messageRequests[_requestId];
    }

    // Claim message only after signature is verified
    function claimMessage(
        uint256 _requestId,
        bytes memory _signature,
        string memory _message
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
            abi.encodePacked(_requestId, _messageRequest.to, _message)
        );
        address _signer = _hash.recover(_signature);
        require(
            _signer == _messageRequest.from,
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

    /**
     * @notice Sets the charity fund address
     */
    function setCharity(address _charityFund) public onlyOwner {
        charityFund = _charityFund;
    }
}
