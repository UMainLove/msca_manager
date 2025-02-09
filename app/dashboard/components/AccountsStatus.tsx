// components/AccountStatus.tsx
interface AccountStatusProps {
    isLoadingAccount: boolean;
    mscaAddress?: string;
    error: string | null;
}

export function AccountStatus({ isLoadingAccount, mscaAddress, error }: AccountStatusProps) {
    const getAccountStatus = () => {
        if (isLoadingAccount) return "Loading account...";
        if (mscaAddress) return `Account active at ${mscaAddress}`;
        if (error) return `Error: ${error}`;
        return "Connecting to account...";
    };

    return (
        <p className="text-sm" >
            <span className="font-medium" > Account Status: </span>
            < span className={error ? "text-red-500" : "text-green-500"} >
                {getAccountStatus()}
            </span>
        </p>
    );
}
