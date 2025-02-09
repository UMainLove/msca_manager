// components/NavigationButtons.tsx
import { useRouter } from "next/navigation";

interface NavigationButtonsProps {
    onLogout: () => void;
}

export function NavigationButtons({ onLogout }: NavigationButtonsProps) {
    const router = useRouter();

    return (
        <div className="mt-4 flex flex-col gap-2" >
            <button
                onClick={() => router.push("/")}
                className="btn btn-secondary"
            >
                Back to Home
            </button>
            < button
                onClick={onLogout}
                className="btn btn-primary mt-2"
            >
                Logout
            </button>
        </div>
    );
}
