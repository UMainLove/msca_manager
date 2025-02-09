import { getUser } from "@account-kit/core";
import { config } from "../../../config";


// components/AccountDetails.tsx
interface AccountDetailsProps {
    userAddress?: string;
    configUserAddress?: string;
    mscaAddress?: string;
    factoryAddress: string;
    balance: string;
    isLoadingAccount: boolean;
    error: string | null;
}

export function AccountDetails({
    userAddress,
    configUserAddress,
    mscaAddress,
    factoryAddress,
    balance,
    isLoadingAccount,
    error,
}: AccountDetailsProps) {

    const userAddressToShow = userAddress || configUserAddress;


    return (
        <div className="bg-black-100 p-4 rounded-lg">
            <h3 className="font-semibold mb-4">Account Details:</h3>
            <div className="space-y-2 text-left">
                <p className="text-sm">
                    <span className="font-medium">Account Status: </span>
                    <span className={error ? "text-red-500" : "text-green-500"}>
                        {isLoadingAccount ? "Loading account..." : mscaAddress ? "Connected" : "Initializing..."}
                    </span>
                </p>
                <p className="text-sm break-all">
                    <span className="font-medium">EntryPoint (v0.6): </span>
                    0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789
                </p>
                <p className="text-sm break-all">
                    <span className="font-medium">Signer (EOA): </span>
                    {userAddressToShow}
                </p>
                <p className="text-sm break-all">
                    <span className="font-medium">Smart Account Address #1: </span>
                    {mscaAddress}
                </p>
                <p className="text-sm break-all">
                    <span className="font-medium">Modular Account Factory Address (Alchemy): </span>
                    {factoryAddress}
                </p>
                <p className="text-sm">
                    <span className="font-medium">Balance: </span>
                    {balance} ETH
                </p>
                <div className="border-t border-gray-700 mt-4 pt-4">
                    <h4 className="font-semibold mb-2">Network Information:</h4>
                    <p className="text-sm">
                        <span className="font-medium">Chain ID: </span>
                        Sepolia (11155111)
                    </p>
                    <p className="text-sm">
                        <span className="font-medium">Currency: </span>
                        ETH
                    </p>
                    {mscaAddress && (
                        <p className="text-sm">
                            <a
                                href={`https://sepolia.etherscan.io/address/${mscaAddress}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-purple-500 hover:text-blue-600"
                            >
                                View on Etherscan
                            </a>
                        </p>
                    )}
                </div>
            </div>
        </div>
    );
}