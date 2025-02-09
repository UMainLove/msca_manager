// components/ModulesList.tsx
interface ModulesListProps {
    modules: string[];
}

export function ModulesList({ modules }: ModulesListProps) {
    return (
        <section className="mb-8" >
            <h2 className="text-xl font-semibold mb-4 text-center" > Installed Modules </h2>
            {
                modules.length > 0 ? (
                    <ul className="space-y-2" >
                        {
                            modules.map((module, index) => (
                                <li
                                    key={index}
                                    className="text-sm font-mono break-all bg-black-50 p-2 rounded"
                                >
                                    {module}
                                </li>
                            ))
                        }
                    </ul>
                ) : (
                    <p className="text-center" > No modules installed.</p>
                )
            }
        </section>
    );
}
