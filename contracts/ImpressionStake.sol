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

    mapping(address => uint256) public nonces;

    bytes32 public immutable CLAIM_TYPEHASH =
        keccak256("claimMessage(uint256 _requestId)");
    bytes32 public immutable DOMAIN_SEPARATOR;
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
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Impression")),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns (string memory) {
        return "1";
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

    function claimMessage(
        uint256 _requestId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyEOA {
        require(
            deadline >= block.timestamp,
            "ImpressionStake: expired deadline"
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                CLAIM_TYPEHASH,
                requestId,
                nonces[msg.sender]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == msg.sender,
            "ImpressionStake: invalid signature"
        );
        _claimMessage(_requestId);
    }

    // Claim message and receive tokens
    function _claimMessage(uint256 _requestId) internal {
        // Get message request
        MessageRequest memory messageRequest = messageRequests[_requestId];
        // Require that the message request is not empty
        require(
            messageRequest.from != address(0),
            "ImpressionStake: message request does not exist"
        );
        // Require that the message request is for the user
        require(
            messageRequest.to == msg.sender,
            "ImpressionStake: message request is not for you"
        );
        // Transfer 99% of tokens to the user
        impressionTokenAddress.transfer(
            msg.sender,
            (messageRequest.amount * 99) / 100
        );
        // Transfer 1% of tokens to charity
        impressionTokenAddress.transfer(
            charityFund,
            messageRequest.amount / 100
        );
        // Delete message request
        delete messageRequests[_requestId];
    }

    function whitelistSigned(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return whitelistSignerAddress == hash.recover(signature);
    }

    // Set user cost
    function setUserCost(uint256 _cost) external {
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
