import { Hash, Address, Hex } from "viem";
import { BigNumberish } from "ethers";
import { TransactionReceipt } from "@ethersproject/abstract-provider";
import { UserOperationReceipt as AlchemyUserOpReceipt } from "@alchemy/aa-core";


export interface UserOperationRequest_v6 {
    sender: string;
    nonce: BigNumberish;
    initCode: string | "0x";
    callData: string | Hex;
    /*callGasLimit?: BigNumberish;
    verificationGasLimit?: BigNumberish;
    preVerificationGas?: BigNumberish;
    maxFeePerGas?: BigNumberish;
    maxPriorityFeePerGas?: BigNumberish;*/
    paymasterAndData: Hex;
    signature: Hex;
}

export interface ExtendedTransactionReceipt extends TransactionReceipt {
    confirmations: number;
    byzantium: boolean;
}

export interface MessageOperation {
    hash: Hash;
    target: Address;
    value: string;
    timestamp: number;
    status: 'pending' | 'completed' | 'failed';
    content: string;
    recipientAddress: string;
    userOpReceipt?: AlchemyUserOpReceipt | null;
    request?: UserOperationRequest_v6;
    txReceipt?: TransactionReceipt | null;
    failureReason?: string;
}

/*export interface UserOperationReceipt {
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
}*/

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