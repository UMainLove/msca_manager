export const MessagingPluginAbi = [
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "AccountNonceOverflow",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "AlreadyInitialized",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "InvalidAction",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "to",
                "type": "address"
            }
        ],
        "name": "InvalidRecipient",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "bytes32",
                "name": "messageHash",
                "type": "bytes32"
            }
        ],
        "name": "MessageHashCollision",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "MessageNonceOverflow",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "sender",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "recipient",
                "type": "address"
            }
        ],
        "name": "MessageStorageFailure",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "MessageTooLong",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "from",
                "type": "address"
            }
        ],
        "name": "NotAuthorized",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "caller",
                "type": "address"
            }
        ],
        "name": "NotContractCaller",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "bytes4",
                "name": "selector",
                "type": "bytes4"
            },
            {
                "internalType": "uint8",
                "name": "functionId",
                "type": "uint8"
            }
        ],
        "name": "NotImplemented",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "NotInitialized",
        "type": "error"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "from",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "to",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "string",
                "name": "content",
                "type": "string"
            }
        ],
        "name": "MessageSent",
        "type": "event"
    },
    {
        "inputs": [],
        "name": "MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "eip712Domain",
        "outputs": [
            {
                "internalType": "bytes1",
                "name": "fields",
                "type": "bytes1"
            },
            {
                "internalType": "string",
                "name": "name",
                "type": "string"
            },
            {
                "internalType": "string",
                "name": "version",
                "type": "string"
            },
            {
                "internalType": "uint256",
                "name": "chainId",
                "type": "uint256"
            },
            {
                "internalType": "address",
                "name": "verifyingContract",
                "type": "address"
            },
            {
                "internalType": "bytes32",
                "name": "salt",
                "type": "bytes32"
            },
            {
                "internalType": "uint256[]",
                "name": "extensions",
                "type": "uint256[]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            },
            {
                "internalType": "bytes",
                "name": "message",
                "type": "bytes"
            }
        ],
        "name": "encodeMessageData",
        "outputs": [
            {
                "internalType": "bytes",
                "name": "",
                "type": "bytes"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "with",
                "type": "address"
            }
        ],
        "name": "getChat",
        "outputs": [
            {
                "internalType": "string[]",
                "name": "",
                "type": "string[]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            },
            {
                "internalType": "bytes",
                "name": "message",
                "type": "bytes"
            }
        ],
        "name": "getMessageHash",
        "outputs": [
            {
                "internalType": "bytes32",
                "name": "",
                "type": "bytes32"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes32",
                "name": "digest",
                "type": "bytes32"
            },
            {
                "internalType": "bytes",
                "name": "signature",
                "type": "bytes"
            }
        ],
        "name": "isValidSignature",
        "outputs": [
            {
                "internalType": "bytes4",
                "name": "",
                "type": "bytes4"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "moduleId",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
            }
        ],
        "name": "onInstall",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes",
                "name": "",
                "type": "bytes"
            }
        ],
        "name": "onUninstall",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "pluginManifest",
        "outputs": [
            {
                "components": [
                    {
                        "internalType": "bytes4[]",
                        "name": "interfaceIds",
                        "type": "bytes4[]"
                    },
                    {
                        "internalType": "bytes4[]",
                        "name": "dependencyInterfaceIds",
                        "type": "bytes4[]"
                    },
                    {
                        "internalType": "bytes4[]",
                        "name": "executionFunctions",
                        "type": "bytes4[]"
                    },
                    {
                        "internalType": "bytes4[]",
                        "name": "permittedExecutionSelectors",
                        "type": "bytes4[]"
                    },
                    {
                        "internalType": "bool",
                        "name": "permitAnyExternalAddress",
                        "type": "bool"
                    },
                    {
                        "internalType": "bool",
                        "name": "canSpendNativeToken",
                        "type": "bool"
                    },
                    {
                        "components": [
                            {
                                "internalType": "address",
                                "name": "externalAddress",
                                "type": "address"
                            },
                            {
                                "internalType": "bool",
                                "name": "permitAnySelector",
                                "type": "bool"
                            },
                            {
                                "internalType": "bytes4[]",
                                "name": "selectors",
                                "type": "bytes4[]"
                            }
                        ],
                        "internalType": "struct ManifestExternalCallPermission[]",
                        "name": "permittedExternalCalls",
                        "type": "tuple[]"
                    },
                    {
                        "components": [
                            {
                                "internalType": "bytes4",
                                "name": "executionSelector",
                                "type": "bytes4"
                            },
                            {
                                "components": [
                                    {
                                        "internalType": "enum ManifestAssociatedFunctionType",
                                        "name": "functionType",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint8",
                                        "name": "functionId",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint256",
                                        "name": "dependencyIndex",
                                        "type": "uint256"
                                    }
                                ],
                                "internalType": "struct ManifestFunction",
                                "name": "associatedFunction",
                                "type": "tuple"
                            }
                        ],
                        "internalType": "struct ManifestAssociatedFunction[]",
                        "name": "userOpValidationFunctions",
                        "type": "tuple[]"
                    },
                    {
                        "components": [
                            {
                                "internalType": "bytes4",
                                "name": "executionSelector",
                                "type": "bytes4"
                            },
                            {
                                "components": [
                                    {
                                        "internalType": "enum ManifestAssociatedFunctionType",
                                        "name": "functionType",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint8",
                                        "name": "functionId",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint256",
                                        "name": "dependencyIndex",
                                        "type": "uint256"
                                    }
                                ],
                                "internalType": "struct ManifestFunction",
                                "name": "associatedFunction",
                                "type": "tuple"
                            }
                        ],
                        "internalType": "struct ManifestAssociatedFunction[]",
                        "name": "runtimeValidationFunctions",
                        "type": "tuple[]"
                    },
                    {
                        "components": [
                            {
                                "internalType": "bytes4",
                                "name": "executionSelector",
                                "type": "bytes4"
                            },
                            {
                                "components": [
                                    {
                                        "internalType": "enum ManifestAssociatedFunctionType",
                                        "name": "functionType",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint8",
                                        "name": "functionId",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint256",
                                        "name": "dependencyIndex",
                                        "type": "uint256"
                                    }
                                ],
                                "internalType": "struct ManifestFunction",
                                "name": "associatedFunction",
                                "type": "tuple"
                            }
                        ],
                        "internalType": "struct ManifestAssociatedFunction[]",
                        "name": "preUserOpValidationHooks",
                        "type": "tuple[]"
                    },
                    {
                        "components": [
                            {
                                "internalType": "bytes4",
                                "name": "executionSelector",
                                "type": "bytes4"
                            },
                            {
                                "components": [
                                    {
                                        "internalType": "enum ManifestAssociatedFunctionType",
                                        "name": "functionType",
                                        "type": "uint8"
                                },
                                    {
                                        "internalType": "uint8",
                                        "name": "functionId",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint256",
                                        "name": "dependencyIndex",
                                        "type": "uint256"
                                    }
                                ],
                                "internalType": "struct ManifestFunction",
                                "name": "associatedFunction",
                                "type": "tuple"
                            }
                        ],
                        "internalType": "struct ManifestAssociatedFunction[]",
                        "name": "preRuntimeValidationHooks",
                        "type": "tuple[]"
                    },
                    {
                        "components": [
                            {
                                "internalType": "bytes4",
                                "name": "executionSelector",
                                "type": "bytes4"
                            },
                            {
                                "components": [
                                    {
                                        "internalType": "enum ManifestAssociatedFunctionType",
                                        "name": "functionType",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint8",
                                        "name": "functionId",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint256",
                                        "name": "dependencyIndex",
                                        "type": "uint256"
                                    }
                                ],
                                "internalType": "struct ManifestFunction",
                                "name": "preExecHook",
                                "type": "tuple"
                            },
                            {
                                "components": [
                                    {
                                        "internalType": "enum ManifestAssociatedFunctionType",
                                        "name": "functionType",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint8",
                                        "name": "functionId",
                                        "type": "uint8"
                                    },
                                    {
                                        "internalType": "uint256",
                                        "name": "dependencyIndex",
                                        "type": "uint256"
                                    }
                                ],
                                "internalType": "struct ManifestFunction",
                                "name": "postExecHook",
                                "type": "tuple"
                            }
                        ],
                        "internalType": "struct ManifestExecutionHook[]",
                        "name": "executionHooks",
                        "type": "tuple[]"
                    }
                ],
                "internalType": "struct PluginManifest",
                "name": "",
                "type": "tuple"
            }
        ],
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "inputs": [], "name": "pluginMetadata",
        "outputs": [
            {
                "components": [
                    {
                        "internalType": "string",
                        "name": "name",
                        "type": "string"
                    },
                    {
                        "internalType": "string",
                        "name": "version",
                        "type": "string"
                    },
                    {
                        "internalType": "string",
                        "name": "author",
                        "type": "string"
                    },
                {
                    "components": [
                        {
                            "internalType": "bytes4",
                            "name": "functionSelector",
                            "type": "bytes4"
                        },
                        {
                            "internalType": "string",
                            "name": "permissionDescription",
                            "type": "string"
                        }
                    ],
                    "internalType": "struct SelectorPermission[]",
                    "name": "permissionDescriptors",
                    "type": "tuple[]"
                    }
                ],
                "internalType": "struct PluginMetadata",
                "name": "",
                "type": "tuple"
            }
        ],
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint8",
                "name": "functionId",
                "type": "uint8"
            },
            {
                "internalType": "bytes",
                "name": "preExecHookData",
                "type": "bytes"
            }
        ],
        "name": "postExecutionHook",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint8",
                "name": "functionId",
                "type": "uint8"
            },
            {
                "internalType": "address",
                "name": "sender",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "value",
                "type": "uint256"
            },
            {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
            }
        ],
        "name": "preExecutionHook",
        "outputs": [
            {
                "internalType": "bytes",
                "name": "",
                "type": "bytes"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint8",
                "name": "functionId",
                "type": "uint8"
            },
            {
                "internalType": "address",
                "name": "sender",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "value",
                "type": "uint256"
            },
            {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
            }
        ],
        "name": "preRuntimeValidationHook",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint8",
                "name": "functionId",
                "type": "uint8"
            },
            {
                "components": [
                    {
                        "internalType": "address",
                        "name": "sender",
                        "type": "address"
                    },
                    {
                        "internalType": "uint256",
                        "name": "nonce",
                        "type": "uint256"
                    },
                    {
                        "internalType": "bytes",
                        "name": "initCode",
                        "type": "bytes"
                    },
                    {
                        "internalType": "bytes",
                        "name": "callData",
                        "type": "bytes"
                    },
                    {
                        "internalType": "uint256",
                        "name": "callGasLimit",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "verificationGasLimit",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "preVerificationGas",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "maxFeePerGas",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "maxPriorityFeePerGas",
                        "type": "uint256"
                    },
                    {
                        "internalType": "bytes",
                        "name": "paymasterAndData",
                        "type": "bytes"
                    },
                    {
                        "internalType": "bytes",
                        "name": "signature",
                        "type": "bytes"
                    }
                ],
                "internalType": "struct UserOperation",
                "name": "userOp",
                "type": "tuple"
            },
            {
                "internalType": "bytes32",
                "name": "userOpHash",
                "type": "bytes32"
            }
        ],
        "name": "preUserOpValidationHook",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint8",
                "name": "",
                "type": "uint8"
            },
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            },
            {
                "internalType": "bytes",
                "name": "",
                "type": "bytes"
            }
        ],
        "name": "runtimeValidationFunction",
        "outputs": [],
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "to",
                "type": "address"
            },
            {
                "internalType": "string",
                "name": "msgContent",
                "type": "string"
            }
        ],
        "name": "sendMessage",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes4",
                "name": "interfaceId",
                "type": "bytes4"
            }
        ],
        "name": "supportsInterface",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint8",
                "name": "",
                "type": "uint8"
            },
            {
                "components": [
                    {
                        "internalType": "address",
                        "name": "sender",
                        "type": "address"
                    },
                    {
                        "internalType": "uint256",
                        "name": "nonce",
                        "type": "uint256"
                    },
                    {
                        "internalType": "bytes",
                        "name": "initCode",
                        "type": "bytes"
                    },
                    {
                        "internalType": "bytes",
                        "name": "callData",
                        "type": "bytes"
                    },
                    {
                        "internalType": "uint256",
                        "name": "callGasLimit",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "verificationGasLimit",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "preVerificationGas",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "maxFeePerGas",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "maxPriorityFeePerGas",
                        "type": "uint256"
                    },
                    {
                        "internalType": "bytes",
                        "name": "paymasterAndData",
                        "type": "bytes"
                    },
                    {
                        "internalType": "bytes",
                        "name": "signature",
                        "type": "bytes"
                    }
                ],
                "internalType": "struct UserOperation",
                "name": "",
                "type": "tuple"
            },
            {
                "internalType": "bytes32",
                "name": "",
                "type": "bytes32"
            }
        ],
        "name": "userOpValidationFunction",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "pure",
        "type": "function"
    }
] as const;