/// This file is part of Modular Account v1.0.0
///
///
///
/// SPDX-License-Identifier: MIT
///
///

pragma solidity ^0.8.22;

import {UserOperation} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/erc4337/UserOperation.sol";

interface IMessagingPlugin {

    enum FunctionId {
        RUNTIME_VALIDATION_OWNER_OR_SELF, // require owner or self access
        USER_OP_VALIDATION_OWNER // require owner access

    }

    /// @notice This event is emitted when a message is sent
    /// @param from The account sending the message
    /// @param to The account receiving the message
    /// @param content The content of the message
    event MessageSent(address indexed from, address indexed to, string content);

    /// @notice Thrown when an operation is attempted by an unauthorized account
    /// @param from The unauthorized account address
    error NotAuthorized(address from);

    /// @notice Thrown when a message exceeds the maximum allowed length
    error MessageTooLong();

    /// @notice Thrown when attempting to send a message to an invalid recipient
    /// @param to The invalid recipient address
    error InvalidRecipient(address to);

    /// @notice Thrown when a message hash collision occurs
    /// @param messageHash The conflicting message hash
    error MessageHashCollision(bytes32 messageHash);

    /// @notice Thrown when message storage fails
    /// @param sender The sender of the message
    /// @param recipient The intended recipient
    error MessageStorageFailure(address sender, address recipient);

    /// @notice Thrown when account nonce reaches maximum value
    /// @param account The account with nonce overflow
    error AccountNonceOverflow(address account);

    /// @notice Thrown when message nonce reaches maximum value
    /// @param account The account with message nonce overflow
    error MessageNonceOverflow(address account);

    /// @notice Send a message to another account
    /// @dev Only initialized accounts can send/receive messages
    /// @param to The recipient address
    /// @param content The message content
    /// @dev Emits MessageSent event on success
    /// @dev Reverts if:
    ///      - Sender is not initialized (NotAuthorized)
    ///      - Recipient is not initialized (InvalidRecipient)
    ///      - Message content exceeds MAX_MESSAGE_LENGTH (MessageTooLong)
    ///      - Message hash collision occurs (MessageHashCollision)
    ///      - Message storage fails (MessageStorageFailure)
    ///      - Message nonce overflows (MessageNonceOverflow)
    function sendMessage(address to, string calldata content) external;

    /// @notice Gets the EIP712 domain
    /// @dev This implementation is different from typical 712 via its use of msg.sender instead. 
    /// Should only be called from SCAs that have installed this. See ERC-5267.
    /// @return fields Domain fields bitmap
    /// @return name Domain name
    /// @return version Domain version
    /// @return chainId Chain ID
    /// @return verifyingContract Address of the verifying contract
    /// @return salt Domain salt
    /// @return extensions Domain extensions
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );

    /// @notice Get chat history with another account
    /// @dev Returns messages in chronological order by timestamp
    /// @param with The address to get chat history with
    /// @return messages Array of messages between the two accounts
    /// @dev Messages are sorted by timestamp in ascending order
    /// @dev Only returns messages where either:
    ///      - msg.sender is the sender and 'with' is the recipient
    ///      - 'with' is the sender and msg.sender is the recipient
    function getChat(address with) external view returns (string[] memory messages);

    /// @notice Get hash of message used in typed data signing
    /// @param account The account address
    /// @param message The message to hash
    /// @return The computed message hash
    function getMessageHash(address account, bytes memory message) external view returns (bytes32);

    /// @notice Encode message data according to EIP-712 specification
    /// @param account The account address
    /// @param message The message to encode
    /// @return The encoded message data
    function encodeMessageData(address account, bytes memory message) external view returns (bytes memory);
}
