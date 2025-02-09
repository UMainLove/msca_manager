// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";

import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import {IEntryPoint} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/erc4337/IEntryPoint.sol";
import {EntryPoint} from "../lib/account-abstraction/contracts/core/EntryPoint.sol";

import {UpgradeableModularAccount} from "../REPO_erc6900_smart_contracts_lib/src/account/UpgradeableModularAccount.sol";
import {UserOperation} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/erc4337/UserOperation.sol";

import {FunctionReference} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/IPluginManager.sol";
import {FunctionReferenceLib} from "../REPO_erc6900_smart_contracts_lib/src/helpers/FunctionReferenceLib.sol";

import {Call} from "../REPO_erc6900_smart_contracts_lib/src/interfaces/IStandardExecutor.sol";

import {MultiOwnerModularAccountFactory} from "../REPO_erc6900_smart_contracts_lib/src/factory/MultiOwnerModularAccountFactory.sol";

import {IMultiOwnerPlugin} from "../REPO_erc6900_smart_contracts_lib/src/plugins/owner/IMultiOwnerPlugin.sol";
import {MultiOwnerPlugin} from "../REPO_erc6900_smart_contracts_lib/src/plugins/owner/MultiOwnerPlugin.sol";

import {IMessagingPlugin} from "../src/IMessagingPlugin.sol";
import {MessagingPlugin} from "../src/MessagingPlugin.sol";

contract MessagingPluginWithMultiOwnerTest is Test {
    using ECDSA for bytes32;

    IEntryPoint entryPoint;
    address payable beneficiary;
    MultiOwnerPlugin multiOwnerPlugin;
    MultiOwnerModularAccountFactory factory;
    MessagingPlugin messagingPlugin;

    address owner1;
    uint256 owner1Key;
    address[] public owners;
    UpgradeableModularAccount account1;

    uint256 constant CALL_GAS_LIMIT = 20000000;
    uint256 constant VERIFICATION_GAS_LIMIT = 200000000;

    address recipient;
    address recipient2;

    // Event re-declarations for use with `vm.expectEmit()`
    event MessageSent(address indexed from, address indexed to, string content);

    function setUp() public {
        entryPoint = IEntryPoint(address(new EntryPoint()));
        (owner1, owner1Key) = makeAddrAndKey("owner1");
        beneficiary = payable(makeAddr("beneficiary"));
        recipient = makeAddr("recipient");
        recipient2 = makeAddr("recipient2");
        
        vm.deal(beneficiary, 1 ether);
        vm.deal(recipient, 1 ether);
        vm.deal(recipient2, 1 ether);

        // Deploy plugins and factory
        multiOwnerPlugin = new MultiOwnerPlugin();
        messagingPlugin = new MessagingPlugin();
        
        // Set up factory with implementation
        address impl = address(new UpgradeableModularAccount(entryPoint));

        // Create factory with MultiOwnerPlugin
        factory = new MultiOwnerModularAccountFactory(
            address(this),
            address(multiOwnerPlugin),
            impl,
            keccak256(abi.encode(multiOwnerPlugin.pluginManifest())),
            entryPoint
        );

        // Create account1 with owner1
        owners = new address[](1);
        owners[0] = owner1;
        account1 = UpgradeableModularAccount(payable(factory.createAccount(0, owners)));
        vm.deal(address(account1), 100 ether);

        // Get manifest hash and dependencies for plugin installation
        // The plugin needs dependency on MultiOwnerPlugin's validation functions
        bytes32 manifestHash = keccak256(abi.encode(messagingPlugin.pluginManifest()));

        // Create dependencies array matching the manifest's dependency order
        // Important: This must match the order in the plugin's manifest
        FunctionReference[] memory dependencies = new FunctionReference[](2);

        // MultiOwnerPlugin's USER_OP_VALIDATION_OWNER function
        // We need only one dependency for both runtime and userOp validation
        // For runtime validation
        dependencies[messagingPlugin.MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION()] = FunctionReferenceLib.pack(
            address(multiOwnerPlugin),
            uint8(IMultiOwnerPlugin.FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF)
        );
        // For userOp validation 
        dependencies[messagingPlugin.MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION()] = FunctionReferenceLib.pack(
            address(multiOwnerPlugin), 
            uint8(IMultiOwnerPlugin.FunctionId.USER_OP_VALIDATION_OWNER)
        );

        // Install messaging plugin with dependencies 
        vm.prank(owner1);
        account1.installPlugin({
            plugin: address(messagingPlugin),
            manifestHash: manifestHash,
            pluginInstallData: "",
            dependencies: dependencies
        });

        // For tests that need a recipient account, we'll create it when needed
        // This is to avoid the PluginAlreadyInstalled error
        vm.label(address(account1), "Account1");
        vm.label(address(messagingPlugin), "MessagingPlugin");
        vm.label(address(multiOwnerPlugin), "MultiOwnerPlugin");
        vm.label(owner1, "Owner1");
        vm.label(recipient, "Recipient");
        vm.label(recipient2, "Recipient2");
    }

    function _setupRecipientAccount(address recipientAddress) internal returns (UpgradeableModularAccount) {
        // Create recipient owner array
        address[] memory recipientOwners = new address[](1);
        recipientOwners[0] = recipientAddress;
        
        // Create recipient account with MultiOwnerPlugin
        UpgradeableModularAccount recipientAccount = UpgradeableModularAccount(
            payable(factory.createAccount(1, recipientOwners))
        );
        vm.deal(address(recipientAccount), 100 ether);

        // Install messaging plugin
        bytes32 manifestHash = keccak256(abi.encode(messagingPlugin.pluginManifest()));

        // Create dependencies array matching the manifest's dependency order (MultiOwnerPlugin)
        FunctionReference[] memory dependencies = new FunctionReference[](2);
        
        // Runtime validation
        dependencies[messagingPlugin.MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION()] = FunctionReferenceLib.pack(
            address(multiOwnerPlugin),
            uint8(IMultiOwnerPlugin.FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF)
        );
        
        // UserOp validation
        dependencies[messagingPlugin.MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION()] = FunctionReferenceLib.pack(
            address(multiOwnerPlugin),
            uint8(IMultiOwnerPlugin.FunctionId.USER_OP_VALIDATION_OWNER)  
        );

        // Install plugin
        vm.prank(recipientAddress);
        recipientAccount.installPlugin({
            plugin: address(messagingPlugin),
            manifestHash: manifestHash,
            pluginInstallData: "",
            dependencies: dependencies
        });

        return recipientAccount;
    }

    function test_messaging_sendMessageSuccess() public {

        // Setup recipient account first
        UpgradeableModularAccount recipientAccount = _setupRecipientAccount(recipient);

        // Send message from account1 to recipient
        string memory message = "Hello World";
        
        vm.expectEmit(true, true, true, true);
        emit MessageSent(address(account1), address(recipientAccount), message);
        
        vm.prank(owner1);
        IMessagingPlugin(address(account1)).sendMessage(address(recipientAccount), message);

        // Verify message was stored
        string[] memory messages = IMessagingPlugin(address(account1)).getChat(address(recipientAccount));
        assertEq(messages.length, 1);
        assertEq(messages[0], message);
    }

    function test_messaging_userOpValidation() public {

        // Setup recipient account first
        UpgradeableModularAccount recipientAccount = _setupRecipientAccount(recipient);

        // Create UserOperation to send message
        string memory message = "Hello via UserOp";

        // Create the UserOperation
        bytes memory callData = abi.encodeCall(
            IMessagingPlugin(address(messagingPlugin)).sendMessage,
            (address(recipientAccount), message)
        );

        UserOperation memory userOp = UserOperation({
            sender: address(account1),
            nonce: 0,
            initCode: "",
            callData: callData,
            callGasLimit: CALL_GAS_LIMIT,
            verificationGasLimit: VERIFICATION_GAS_LIMIT,
            preVerificationGas: 0,
            maxFeePerGas: 2,
            maxPriorityFeePerGas: 1,
            paymasterAndData: "",
            signature: ""
        });

        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(owner1Key, userOpHash.toEthSignedMessageHash());
        userOp.signature = abi.encodePacked(r, s, v);

        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        // Execute the UserOperation
        vm.expectEmit(true, true, true, true);
        emit MessageSent(address(account1), address(recipientAccount), message);
        entryPoint.handleOps(userOps, beneficiary);

        // Verify message was stored
        string[] memory messages = IMessagingPlugin(address(account1)).getChat(address(recipientAccount));
        assertEq(messages.length, 1);
        assertEq(messages[0], message);
    }

    function test_messaging_multipleMessages() public {

        // Setup recipient account first
        UpgradeableModularAccount recipientAccount = _setupRecipientAccount(recipient);
        
        string memory message1 = "Message 1";
        string memory message2 = "Message 2";
        
        vm.startPrank(owner1);
        IMessagingPlugin(address(account1)).sendMessage(address(recipientAccount), message1);
        IMessagingPlugin(address(account1)).sendMessage(address(recipientAccount), message2);
        vm.stopPrank();

        // Verify messages were stored in order
        string[] memory messages = IMessagingPlugin(address(account1)).getChat(address(recipientAccount));
        assertEq(messages.length, 2);
        assertEq(messages[0], message1);
        assertEq(messages[1], message2);
    }

    function test_messaging_getChat() public {
        
        // Setup: Create recipient account
        UpgradeableModularAccount recipientAccount = _setupRecipientAccount(recipient);
        
        // Send messages between accounts
        string memory message1 = "Hi from account1";
        string memory message2 = "Hi back from recipient";
        
        vm.prank(owner1);
        IMessagingPlugin(address(account1)).sendMessage(address(recipientAccount), message1);
        
        vm.prank(recipient);
        IMessagingPlugin(address(recipientAccount)).sendMessage(address(account1), message2);

        // Verify chat history from account1's perspective
        string[] memory messages = IMessagingPlugin(address(account1)).getChat(address(recipientAccount));
        assertEq(messages.length, 2);
        assertEq(messages[0], message1);
        assertEq(messages[1], message2);

        // Verify chat history from recipient's perspective
        messages = IMessagingPlugin(address(recipientAccount)).getChat(address(account1));
        assertEq(messages.length, 2);
        assertEq(messages[0], message1);
        assertEq(messages[1], message2);
    }

    function testFail_messaging_unauthorized() public {
        string memory message = "Unauthorized message";
        
        // Try to send message from unauthorized address
        vm.prank(recipient);
        IMessagingPlugin(address(account1)).sendMessage(recipient2, message);
    }

    function testFail_messaging_messageTooLong() public {
        // Create a message that exceeds MAX_MESSAGE_LENGTH
        string memory longMessage = new string(301); // MAX_MESSAGE_LENGTH is 300
        
        vm.prank(owner1);
        IMessagingPlugin(address(account1)).sendMessage(recipient, longMessage);
    }
}