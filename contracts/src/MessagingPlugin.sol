/// This file is part of Modular Account v1.0.0
///
///
///
/// SPDX-License-Identifier: MIT
///
///
/// @dev: note: MessagingPlugin works ONLY with Smart accounts who installed MultiOwnerPlugin.
/// That's one of the key benefits of using MultiOwnerPlugin as our validation dependency leveraging the MultiOwnerAccountFactory in deployment.
/// For example, multiple owners created with MultiOwnerPlugin can access to our MessagingPlugin operations by design.

pragma solidity ^0.8.22;

import {IERC1271} from "../lib/openzeppelin-contracts/contracts/interfaces/IERC1271.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import {Address} from "../lib/openzeppelin-contracts/contracts/utils/Address.sol";

import {
    UpgradeableModularAccount,
    UUPSUpgradeable
} from "../REPO_erc6900_smart_contracts_lib/src/account/UpgradeableModularAccount.sol";

import {CastLib} from "../REPO_erc6900_smart_contracts_lib/src/helpers/CastLib.sol";
import {UserOperation} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/erc4337/UserOperation.sol";

import {
    ManifestFunction,
    ManifestAssociatedFunction,
    ManifestAssociatedFunctionType,
    PluginManifest,
    PluginMetadata,
    SelectorPermission
} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/IPlugin.sol";

import {Call, IStandardExecutor} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/IStandardExecutor.sol";

import {
    AssociatedLinkedListSet,
    AssociatedLinkedListSetLib
} from "../REPO_erc6900_smart_contracts_lib/src/libraries/AssociatedLinkedListSetLib.sol";

import {
    SetValue,
    SIG_VALIDATION_PASSED,
    SIG_VALIDATION_FAILED
} from "../REPO_erc6900_smart_contracts_lib/src/libraries/Constants.sol";

import {IPlugin} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/IPlugin.sol";
import {IPluginExecutor} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/IPluginExecutor.sol";
import {BasePlugin} from "../REPO_erc6900_smart_contracts_lib/src/plugins/BasePlugin.sol";

import {IMessagingPlugin} from "./IMessagingPlugin.sol";

import {IMultiOwnerPlugin} from "../REPO_erc6900_smart_contracts_lib/src/plugins/owner/IMultiOwnerPlugin.sol";

contract MessagingPlugin is BasePlugin, IERC1271, IMessagingPlugin {

    // Libraries for linked list storage and casting values
    using AssociatedLinkedListSetLib for AssociatedLinkedListSet;
    using ECDSA for bytes32;
    using Address for address;

    // Plugin metadata
    string internal constant _NAME = "Messaging Plugin";
    string internal constant _VERSION = "0.0.1 | Alpha";
    string internal constant _AUTHOR = "Michele Galante";

    // EIP712 domain separator
    bytes32 private constant _TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
    );

    // Hashed values for EIP712 domain separator
    bytes32 private constant _HASHED_NAME = keccak256(bytes(_NAME));
    bytes32 private constant _HASHED_VERSION = keccak256(bytes(_VERSION));
    bytes32 private immutable _SALT = bytes32(bytes20(address(this)));

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant _1271_MAGIC_VALUE = 0x1626ba7e;
    bytes4 internal constant _1271_MAGIC_VALUE_FAILURE = 0xffffffff;

    // Typehashes for EIP-712
    bytes32 private constant MODULAR_ACCOUNT_TYPEHASH = keccak256("AlchemyModularAccountMessage(bytes message)");
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("Message(address from,address to,string content,uint256 nonce,uint256 timestamp)");

    // Helpers error messages
    bytes30 internal constant ACCOUNT_ENABLED_VALUE = bytes30(uint240(1));
    uint256 private constant MAX_UINT240 = type(uint240).max;

    // Manifest dependency indexes from MultiOwnerPlugin
    uint256 internal constant _MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION = 0;
    uint256 internal constant _MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION = 1;

    // Manifest dependency indexes as public functions so tests can access them
    function MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION() public pure returns (uint256) { return 0; }
    function MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION() public pure returns (uint256) { return 1; }

    // Message structure
    struct Message {
        address from;
        address to;
        string content;
        uint256 nonce;
        uint256 timestamp;
    }
    
    uint256 internal constant MAX_MESSAGE_LENGTH = 300; // Character limit reducing gas costs

    // Storage for messages and enabled accounts
    AssociatedLinkedListSet internal _messages;
    AssociatedLinkedListSet internal _enabledAccounts;

    // Nonces for messages and accounts
    mapping(address => uint256) private _messageNonces;
    mapping(address => uint256) private _accountNonces;

    // Messages stored by their full hash
    mapping(bytes32 => Message) private _messageDetails;

    // Additional mapping for timestamp-based retrieval
    mapping(address => mapping(address => bytes32[])) private _conversationMessages;

    // Plugin implementation 
    function moduleId() external pure returns (string memory) {
        return string(abi.encodePacked(_AUTHOR, ".", _NAME, ".", _VERSION));
    }


    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Execution function     ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function sendMessage(address to, string calldata msgContent) external override {

        // Check if the account is enabled
        if (!_isInitialized(msg.sender)) revert NotAuthorized(msg.sender);
        if (!_isInitialized(to)) revert InvalidRecipient(to);
        if (bytes(msgContent).length > MAX_MESSAGE_LENGTH) revert MessageTooLong();

        // Increment message nonce
        uint256 messageNonce = _messageNonces[msg.sender];
        if (messageNonce >= MAX_UINT240) revert MessageNonceOverflow(msg.sender);
        _messageNonces[msg.sender] = messageNonce + 1;

        // Create new message
        Message memory newMessage = Message({
            from: msg.sender,
            to: to,
            content: msgContent,
            nonce: messageNonce,
            timestamp: block.timestamp
        });

        // Store message details
        bytes32 messageHash = _hashMessage(newMessage);
        if (_messageDetails[messageHash].timestamp != 0) {
            revert MessageHashCollision(messageHash);
        }

        // Store full message details
        _messageDetails[messageHash] = newMessage;

        // Store full hash in conversation history
        _conversationMessages[msg.sender][to].push(messageHash);
        _conversationMessages[to][msg.sender].push(messageHash);

        // Convert messageHash to SetValue for linked list storage
        bytes30 truncatedHash = bytes30(uint240(uint256(messageHash)));
        SetValue messageValue = SetValue.wrap(truncatedHash);
        
        // Store message hash in both participants' lists
        bool senderAdded = _messages.tryAdd(msg.sender, messageValue);
        bool recipientAdded = _messages.tryAdd(to, messageValue);
        
        // Revert if either participant's list storage fails
        if (!senderAdded || !recipientAdded) {
            revert MessageStorageFailure(msg.sender, to);
        }

        emit MessageSent(msg.sender, to, msgContent);
    }


    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃  Execution view function    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function getChat(address with) external view override returns (string[] memory) {

        // Retrieve all message hashes for the conversation
        bytes32[] memory conversationHashes = _conversationMessages[msg.sender][with];
        
        // Create array for chronologically ordered messages
        Message[] memory orderedMessages = new Message[](conversationHashes.length);
        uint256 validCount = 0;

        // Retrieve all valid messages
        for (uint256 i = 0; i < conversationHashes.length; i++) {
            Message memory msg_ = _messageDetails[conversationHashes[i]];
            if (msg_.timestamp != 0 && 
                ((msg_.from == msg.sender && msg_.to == with) || 
                 (msg_.from == with && msg_.to == msg.sender))) {
                orderedMessages[validCount] = msg_;
                validCount++;
            }
        }

        // Sort messages by timestamp using insertion sort
        for (uint256 i = 1; i < validCount; i++) {
            Message memory key = orderedMessages[i];
            int256 j = int256(i) - 1;
            
            while (j >= 0 && orderedMessages[uint256(j)].timestamp > key.timestamp) {
                orderedMessages[uint256(j + 1)] = orderedMessages[uint256(j)];
                j--;
            }
            orderedMessages[uint256(j + 1)] = key;
        }

        // Create final array with message contents
        string[] memory chatMessages = new string[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            chatMessages[i] = orderedMessages[i].content;
        }

        return chatMessages;
    }


    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Plugin interface functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function _onInstall(bytes calldata) internal override isNotInitialized(msg.sender) {

        // Check if the caller is a smart account
        if (!Address.isContract(msg.sender)) revert NotContractCaller(msg.sender);

        // Increment account nonce
        uint256 nonce = _accountNonces[msg.sender];
        
        // Check for nonce overflow
        if (nonce >= MAX_UINT240) revert AccountNonceOverflow(msg.sender);
        _accountNonces[msg.sender] = nonce + 1;
        
        // Add account to enabled smart accounts with messaging plugin installed
        require(_enabledAccounts.tryAdd(msg.sender, SetValue.wrap(ACCOUNT_ENABLED_VALUE)), "Failed to initialize");
    }

    function onUninstall(bytes calldata) external override {

        // Clean up all messages for the account
        SetValue[] memory messageHashes = _messages.getAll(msg.sender);
        for (uint256 i = 0; i < messageHashes.length; i++) {
            _messages.tryRemove(msg.sender, messageHashes[i]);
        }
        
        // Remove account from enabled accounts
        require(_enabledAccounts.tryRemove(msg.sender, SetValue.wrap(ACCOUNT_ENABLED_VALUE)), "Failed to uninstall");
    }

     function _isInitialized(address account) internal view override returns (bool) {

        // Check if the smart account is enabled
        return _enabledAccounts.contains(account, SetValue.wrap(ACCOUNT_ENABLED_VALUE));
    }

    function _hashMessage(Message memory message) internal pure returns (bytes32) {

        // Hash the message data
        return keccak256(
            abi.encode(
                MESSAGE_TYPEHASH,
                message.from,
                message.to,
                keccak256(bytes(message.content)),
                message.nonce,
                message.timestamp
            )
        );
    }

    // ERC-1271 Implementation
    function eip712Domain()
        external
        view
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        // Return EIP712 domain data 
        return (
            hex"1f", // 11111 indicate salt field is also used
            _NAME,
            _VERSION,
            block.chainid,
            msg.sender,
            _SALT,
            new uint256[](0)
        );
    }

    function isValidSignature(bytes32 digest, bytes memory signature) external view override returns (bytes4) {

        // Recover the signer from the signature
        bytes32 messageHash = getMessageHash(msg.sender, abi.encode(digest));
        
        // Validate the signature or return failure
        (address signer, ECDSA.RecoverError error) = ECDSA.tryRecover(messageHash, signature);
        if (error == ECDSA.RecoverError.NoError && _isInitialized(signer)) {
            return _1271_MAGIC_VALUE;
        }
        return _1271_MAGIC_VALUE_FAILURE;
    }

    function userOpValidationFunction(uint8 /*functionId*/, UserOperation calldata /*userOp*/, bytes32 /*userOpHash*/) external pure override returns (uint256) {
        
/*
        // Validate the user operation and return the result or revert if the smart account is not implemented
        if (functionId == uint8(FunctionId.USER_OP_VALIDATION_OWNER)) {
            (address signer, ECDSA.RecoverError error) = 
                userOpHash.toEthSignedMessageHash().tryRecover(userOp.signature);
            
            if (error == ECDSA.RecoverError.NoError && _isInitialized(signer)) {
                return SIG_VALIDATION_PASSED;
            }
            return SIG_VALIDATION_FAILED;
        }
        revert NotImplemented(msg.sig, functionId);   
*/

        /// @dev We're using MultiOwnerPlugin's validation, so we shouldn't implement our own
        /// Instead, we should revert since we're using the dependency
        /// Note: according to ERC-6900, since we're using ManifestAssociatedFunctionType.DEPENDENCY
        /// we should actually let these standard-revert and delegate the runtime execution to MultiOwnerPlugin (without the NotImplemented error) 
        revert();
    }

    function runtimeValidationFunction(uint8 /*functionId*/, address /*sender*/, uint256 /*value*/, bytes calldata /*data*/) external pure override {

/*
        // Validate the runtime function and revert if the sender is not authorized or the function is not implemented for the smart account
        if (functionId == uint8(FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF)) {
            if (sender != msg.sender && !_isInitialized(sender)) {
                revert NotAuthorized(sender);
            }
            return;
        }
        revert NotImplemented(msg.sig, functionId); 
*/

        /// @dev Similar to runtime validation, we're using MultiOwnerPlugin's validation
        revert();
    }

    function encodeMessageData(address account, bytes memory message) public view returns (bytes memory) {

        // Encode the message data for EIP712 signing
        bytes32 messageHash = keccak256(abi.encode(MODULAR_ACCOUNT_TYPEHASH, keccak256(message)));
        return abi.encodePacked("\x19\x01", _domainSeparator(account), messageHash);
    }

    function getMessageHash(address account, bytes memory message) public view returns (bytes32) {

        // Return the message hash for EIP712 signing
        return keccak256(encodeMessageData(account, message));
    }

    function _domainSeparator(address account) internal view returns (bytes32) {

        // Return the EIP712 domain separator for the plugin
        return keccak256(
            abi.encode(
                _TYPE_HASH,
                _HASHED_NAME,
                _HASHED_VERSION,
                block.chainid,
                account,
                _SALT
            )
        );
    }


    function pluginManifest() external pure override returns (PluginManifest memory) {

        PluginManifest memory manifest;

        // Define dependencies on MultiOwnerPlugin - need two indices
        manifest.dependencyInterfaceIds = new bytes4[](2);
        manifest.dependencyInterfaceIds[_MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION] = 
            type(IMultiOwnerPlugin).interfaceId;
        manifest.dependencyInterfaceIds[_MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION] = 
            type(IMultiOwnerPlugin).interfaceId;

        // Define execution functions
        manifest.executionFunctions = new bytes4[](2);
        manifest.executionFunctions[0] = this.sendMessage.selector;
        manifest.executionFunctions[1] = this.getChat.selector;

        // User Operation Validation
        manifest.userOpValidationFunctions = new ManifestAssociatedFunction[](1);

        // For sendMessage - delegate to owner validation
        manifest.userOpValidationFunctions[0] = ManifestAssociatedFunction({
            executionSelector: this.sendMessage.selector,
            associatedFunction: ManifestFunction({
                functionType: ManifestAssociatedFunctionType.DEPENDENCY,
                functionId: 0, // unused since it's a dependency
                dependencyIndex: _MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION
            })
        });

        // Runtime Validation
        manifest.runtimeValidationFunctions = new ManifestAssociatedFunction[](2);

        // For sendMessage - delegate to owner validation
        manifest.runtimeValidationFunctions[0] = ManifestAssociatedFunction({
            executionSelector: this.sendMessage.selector,
            associatedFunction: ManifestFunction({
                functionType: ManifestAssociatedFunctionType.DEPENDENCY,
                functionId: 0, // unused since it's a dependency
                dependencyIndex: _MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION
            })
        });

        // For getChat - always allow as it's a read-only function
        manifest.runtimeValidationFunctions[1] = ManifestAssociatedFunction({
            executionSelector: this.getChat.selector,
            associatedFunction: ManifestFunction({
                functionType: ManifestAssociatedFunctionType.RUNTIME_VALIDATION_ALWAYS_ALLOW,
                functionId: 0,
                dependencyIndex: 0
            })
        });

        // Support for ERC1271 and MessagingPlugin interfaces
        manifest.interfaceIds = new bytes4[](2);
        manifest.interfaceIds[0] = type(IERC1271).interfaceId;
        manifest.interfaceIds[1] = type(IMessagingPlugin).interfaceId;

        manifest.permitAnyExternalAddress = false;     // This plugin doesn't need to call external contracts
        manifest.canSpendNativeToken = false;          // This plugin doesn't need to spend native tokens

        return manifest;
    }

    function pluginMetadata() external pure override returns (PluginMetadata memory) {
        PluginMetadata memory metadata;
        metadata.name = _NAME;
        metadata.version = _VERSION;
        metadata.author = _AUTHOR;

        // Define permissions for the plugin
        metadata.permissionDescriptors = new SelectorPermission[](1);
        metadata.permissionDescriptors[0] = SelectorPermission({
            functionSelector: this.sendMessage.selector,
            permissionDescription: "Send messages to other accounts"
        });

        return metadata;
    }


    // ┏━━━━━━━━━━━━━━━┓
    // ┃    EIP-165    ┃
    // ┗━━━━━━━━━━━━━━━┛

     function supportsInterface(bytes4 interfaceId) public view override returns (bool) {

        // Check if the smart account supports the interface for the plugin
        return 
            interfaceId == type(IMessagingPlugin).interfaceId || 
            interfaceId == type(IERC1271).interfaceId ||
            super.supportsInterface(interfaceId);
    
    }

}