import { parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { createWalletClient, http } from "viem";
import { sepolia } from "viem/chains";
import * as dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

import { counterfactualAddress } from "./accountInfo.json"; // replace with your ""./account2Info.json" if you have multiple accounts with different Metamask private keys
                                                            // Remember that you need to deploy first a new client with the new private key

const PRIV_KEY = process.env.NEXT_PUBLIC_METAMASK_PRIVATE_KEY!;
const ALCHEMY_API_URL = process.env.NEXT_PUBLIC_ALCHEMY_API_URL!;

//Create another account to test 'MessagingPlugin'
const PRIV_KEY2 = process.env.NEXT_PUBLIC_METAMASK_PRIVATE_KEY2!;

/**
 * @description Sends ETH from EOA that deployed the MSCA to the owned counterfactual address of the MSCA
 */

async function main() {
    const account = privateKeyToAccount(`0x${PRIV_KEY}`);

    const wallet = await createWalletClient({
        account: account,
        chain: sepolia,
        transport: http(ALCHEMY_API_URL),
    });

    const txHash = await wallet.sendTransaction({
        to: counterfactualAddress as `0x${string}`,
        value: parseEther("0.2"),
    });

    return txHash;
}

main().then((txHash) => {
    console.log("Transation hash: ", txHash);
});