import { Hash, Address, Hex } from "viem";
import { TransactionReceipt } from "@ethersproject/abstract-provider";
import { UserOperationReceipt as AlchemyUserOpReceipt } from "@alchemy/aa-core";
import { BigNumberish } from "ethers";

export interface UserOperationRequest_v7 {
    sender: Address;
    nonce: Hex;
    factory?: Address;
    factoryData?: Hex;
    callData: Hex;
    callGasLimit: Hex;
    verificationGasLimit: Hex;
    preVerificationGas: Hex;
    maxFeePerGas: Hex;
    maxPriorityFeePerGas: Hex;
    paymaster?: Address;
    paymasterVerificationGasLimit?: Hex;
    paymasterPostOpGasLimit?: Hex;
    paymasterData?: Hex;
    signature: Hex;
}

export interface ExtendedTransactionReceipt extends TransactionReceipt {
    confirmations: number;
    byzantium: boolean;
}

export interface UserOperation {
    hash: Hash;
    target: Address;
    value: string;
    timestamp: number;
    status: 'pending' | 'completed' | 'failed';
    userOpReceipt?: AlchemyUserOpReceipt | null;
    request?: UserOperationRequest_v7;
    txReceipt?: TransactionReceipt | null;
    failureReason?: string;
}

export interface UserOperationReceipt {
    userOpHash: Hash;
    entryPoint: Address;
    sender: Address;
    nonce: BigNumberish;
    paymaster?: Address;
    actualGasCost: BigNumberish;
    actualGasUsed: BigNumberish;
    success: boolean;
    reason?: string;
    logs: string[];
    receipt: TransactionReceipt;
}

export function replaceBigIntsWithStrings(obj: any): any {
    if (obj === null || obj === undefined) {
        return obj;
    }

    if (typeof obj === 'bigint') {
        return obj.toString();
    }

    if (Array.isArray(obj)) {
        return obj.map(replaceBigIntsWithStrings);
    }

    if (typeof obj === 'object') {
        const newObj: { [key: string]: any } = {};
        for (const key in obj) {
            newObj[key] = replaceBigIntsWithStrings(obj[key]);
        }
        return newObj;
    }

    return obj;
}