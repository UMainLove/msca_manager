// src/plugins.ts
export interface KnownPlugin {
    name: string;
    version?: string;
    description?: string;
}

export const KNOWN_PLUGINS: { [address: string]: KnownPlugin } = {
    "0xcE0000007B008F50d762D155002600004cD6c647": {
        name: "Multi-Owner Plugin",
        version: "1.0.0",
        description: "Core plugin for managing multiple owners and signature validation"
    },
    "0x79050486765BE9573fDb341b0686576d32d73A9b": {
        name: "Messaging Plugin",
        version: "0.0.1 | Alpha",
        description: "Allows modular accounts to send and receive messages"
    } // Add more plugins here...
} as const;

// Helper function to normalize addresses for comparison
export function normalizeAddress(address: string): string {
    return address.toLowerCase();
}

// Helper function to get known plugin info
export function getKnownPluginInfo(address: string): KnownPlugin | undefined {
    // Convert both the input address and all known addresses to lowercase for comparison
    const normalizedInput = normalizeAddress(address);
    const normalizedPlugins = Object.keys(KNOWN_PLUGINS).reduce((acc, key) => {
        acc[normalizeAddress(key)] = KNOWN_PLUGINS[key];
        return acc;
    }, {} as { [key: string]: KnownPlugin });

    return normalizedPlugins[normalizedInput];
}