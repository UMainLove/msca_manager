/* eslint-disable max-len */
import { initializeSmartAccountClient } from "../src/ModularAccount";
import fs from "fs";
import path from "path";
import * as dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

// Constants
const FILENAME = "accountInfo.json";

// Directory handling (adaptable for different environments)
const __dirname = path.dirname(new URL(import.meta.url).pathname);

/**
 * 
 * @description This function is used to test the counterfactual address which is the address used by the smart account client. The address is saved into a file named accountInfo.json.
 */

export async function getCounterfactualAddress() {
    try {
        // Initialize and get the smart account client
        const smartAccountClient = await initializeSmartAccountClient();
        if (!smartAccountClient) {
            throw new Error("Failed to initialize smart account client");
        }
        // Retrieve the smart account client (configured with the Alchemy SDK)
        const signer = await smartAccountClient;

        // Fetch the counterfactual address
        const counterfactualAddress = signer.getAddress();

        // Path to save the file
        const filePath = path.join(__dirname, FILENAME);

        // Data to save
        const data = { counterfactualAddress };

        // Write to file (JSON format)
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2));

        console.log("Counterfactual address saved to:", filePath);
        console.log("Your counterfactual address:", counterfactualAddress);

        return counterfactualAddress;

    } catch (error) {
        console.error("Error fetching counterfactual address:", error);
        process.exit(1);
    }
}
// Only run if this is the main module
if (require.main === module) {
    getCounterfactualAddress()
        .catch((error) => {
            console.error("Failed to get counterfactual address:", error);
            process.exit(1);
        });
}