import type { EvidenceDetails } from "./evidence.type";

export interface InventoryItem<AdditionalData> {
    imagePath: string;
    label: string;
    slot: number;
    details: EvidenceDetails
    additionalData: AdditionalData;
}

export interface Inventory<AdditionalData> {
    inventory: number | string;
    label: string;
    items: InventoryItem<AdditionalData>[];
}

export type InventoriesType<AdditionalData> = Inventory<AdditionalData>[];