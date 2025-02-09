// components/NetworkInfo.tsx
import { sepolia } from "viem/chains";

interface NetworkInfoProps {
    mscaAddress?: string;
}

export function NetworkInfo({ mscaAddress }: NetworkInfoProps) {
    return (
        <div className="border-t border-gray-700 mt-4 pt-4" >
            <h4 className="font-semibold mb-2" > Network Information: </h4>
            < p className="text-sm" >
                <span className="font-medium" > Chain: </span>
                {sepolia.name} (ID: {sepolia.id})
            </p>
            < p className="text-sm" >
                <span className="font-medium" > Currency: </span>
                {sepolia.nativeCurrency.symbol}
            </p>
            < p className="text-sm" >
                <a
                    href={`${sepolia.blockExplorers.default.url}/address/${mscaAddress}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-purple-500 hover:text-blue-600"
                >
                    View on {sepolia.blockExplorers.default.name}
                </a>
            </p>
        </div>
    );
}