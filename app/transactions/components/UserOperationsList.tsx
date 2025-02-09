"use client";

import { UserOperation } from "./types";
import { UserOperationCard } from "./UserOperationCard";

interface UserOperationsListProps {
    operations: UserOperation[];
}

export function UserOperationsList({ operations }: UserOperationsListProps) {
    return (
        <section>
            <h2 className="text-xl font-bold mb-4">User Operations</h2>
            {operations.length > 0 ? (
                <div className="space-y-4">
                    {operations.map((operation) => (
                        <UserOperationCard
                            key={operation.hash}
                            operation={operation}
                        />
                    ))}
                </div>
            ) : (
                <p className="text-center text-gray-500">
                    No user operations yet
                </p>
            )}
        </section>
    );
}