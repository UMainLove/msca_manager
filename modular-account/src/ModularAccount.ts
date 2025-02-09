import { LocalAccountSigner, type SmartAccountSigner, sepolia } from "@alchemy/aa-core";
import { createModularAccountAlchemyClient } from "@alchemy/aa-alchemy";
import * as dotenv from "dotenv";
dotenv.config({ path: '.env.local' });


// Import the environment variables
const PRIV_KEY = process.env.NEXT_PUBLIC_METAMASK_PRIVATE_KEY!;
const ALCHEMY_API_KEY = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY!;
const GAS_ID = process.env.NEXT_PUBLIC_PAYMASTER_POLICY_ID!;

//Create another account to test 'MessagingPlugin'
const PRIV_KEY2 = process.env.NEXT_PUBLIC_METAMASK_PRIVATE_KEY2!;

// Define constants
const chain = sepolia;

const signer: SmartAccountSigner = LocalAccountSigner.privateKeyToAccountSigner(
    `0x${PRIV_KEY}`
);

// Create a singleton instance
let _smartAccountClient: Awaited<ReturnType<typeof createModularAccountAlchemyClient>> | null = null;


/**
 * @description Creates a modular smart contract account client with Gas Manager for sponsoring gas.
 */

export async function initializeSmartAccountClient() {
    if (!_smartAccountClient) {
        _smartAccountClient = await createModularAccountAlchemyClient({
            apiKey: ALCHEMY_API_KEY,
            chain,
            signer, // SmartAccountSigner
            gasManagerConfig: {
                policyId: GAS_ID,
            },
        });
    }
    return _smartAccountClient;
}

// For backward compatibility, export the client getter
export const getSmartAccountClient = () => _smartAccountClient;

// Initialize the client immediately but handle it as a Promise
export const smartAccountClientPromise = initializeSmartAccountClient();

