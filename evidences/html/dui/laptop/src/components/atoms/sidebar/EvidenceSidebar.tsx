import { useEffect } from "react";
import useLuaCallback from "@/hooks/useLuaCallback";
import { Sidebar, SidebarItem, SidebarSection } from "./Sidebar";
import type { Evidence, EvidenceDetails } from "@/types/evidence.type";
import type { EvidenceAnalysedEvent } from "@/types/events.type";
import { useTranslation } from "@/components/TranslationContext";
import type { InventoriesType } from "@/types/inventory.type";


interface EvidenceSidebarProps {
    type: "fingerprint" | "dna";
    evidence: Evidence | null;
    translations: {
        noItemsWithEvidences: string;
    };
    onEvidenceSelection: (label: string, imagePath: string, inventory: number | string, slot: number, identifier: string, analysed: boolean, details: EvidenceDetails) => void;
    onDataChange: (dataAvailable: boolean) => void;
}


export default function EvidenceSidebar(props: EvidenceSidebarProps) {
    const { t } = useTranslation();

    const { trigger, data: inventories, setData: setInventories, loading } = useLuaCallback<{ type: "fingerprint" | "dna" }, InventoriesType<{ identifier: string, analysed: boolean }>>({
        name: "evidences:getPlayersItemsWithBiometricData",
        defaultData: [],
        onSuccess: (data) => props.onDataChange(data.length > 0)
    });

    useEffect(() => {
        trigger({ type: props.type });
 
        const handleMessage = (event: MessageEvent) => {
            if (event.data.action && event.data.action == "focus") {
                trigger({ type: props.type });
            }
        };

        const handleAnalysed = (e: Event) => {
            const event = e as CustomEvent<EvidenceAnalysedEvent>;
            const { inventory, slot, type } = event.detail;

            if (type != props.type) return;

            setInventories(prev => {
                if (!prev) return prev;

                return prev.map(inv => {
                    if (inv.inventory != inventory) return inv;

                    return {
                        ...inv,
                        items: inv.items.map(item => {
                            if (item.slot != slot) return item;

                            return {
                                ...item,
                                additionalData: {
                                    ...item.additionalData,
                                    analysed: true
                                }
                            };
                        })
                    };
                });
            });
        };

        window.addEventListener("message", handleMessage);
        window.addEventListener("evidences:analysed", handleAnalysed);

        return () => {
            window.removeEventListener("message", handleMessage);
            window.removeEventListener("evidences:analysed", handleAnalysed);
        };
    }, []);

    const evidencesByScene = (inventories || []).reduce((acc, inventory) => {
        inventory.items.forEach((item) => {
            const sceneName = (item.details?.crimeScene || "").trim() || t("laptop.desktop_screen.common.crime_scene_placeholder");

            if (!acc[sceneName]) {
                acc[sceneName] = [];
            }

            acc[sceneName].push({
                ...item,
                inventory: inventory.inventory
            });
        });

        return acc;
    }, {} as Record<string, Array<InventoriesType<{ identifier: string, analysed: boolean }>[number]["items"][number] & { inventory: number | string }>>);

    return <Sidebar className="w-70 h-full shrink-0">
        {(!inventories || (inventories.length == 0 && !loading))
            ? <div className="w-full h-full flex justify-center items-center">
                <p className="text-20 leading-none text-center">{props.translations.noItemsWithEvidences}</p>
            </div>
            : (inventories.length == 0 && loading)
                ? <div className="w-full h-full flex justify-center items-center">
                    <p className="text-20 leading-none text-center">{t("laptop.desktop_screen.common.statuses.loading")}</p>
                </div>
                : Object.entries(evidencesByScene).map(([sceneName, items]) => (
                    <SidebarSection key={sceneName} title={sceneName}>
                        {items.map((item) => {
                            const active = props.evidence
                                && item.inventory == props.evidence.inventory
                                && item.slot == props.evidence.slot
                                && item.additionalData.identifier == props.evidence.identifier

                            return <SidebarItem
                                key={`${item.inventory}-${item.slot}-${item.additionalData.identifier}`}
                                active={!!active}
                                imagePath={item.imagePath}
                                description={item.additionalData.analysed ? t("laptop.desktop_screen.common.statuses.analysed") : undefined}
                                onClick={() => props.onEvidenceSelection(item.label, item.imagePath, item.inventory, item.slot, item.additionalData.identifier, item.additionalData.analysed, item.details)}
                            >
                                {item.label}
                            </SidebarItem>
                        })}
                    </SidebarSection>
                ))
        }
    </Sidebar>
}
