import { defineConfig } from "@account-kit/plugingen";
import { sepolia } from "viem/chains";
import { MessagingPluginGenConfig } from "./index";
import path from "path";

import * as dotenv from "dotenv";
dotenv.config({ path: '.env.local' });

const ALCHEMY_API_KEY = process.env.NEXT_PUBLIC_ALCHEMY_API_KEY!;

export default defineConfig({
    chain: sepolia,
    rpcUrl: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
    outDir: path.join(__dirname, "generated"),
    plugins: [MessagingPluginGenConfig]
});