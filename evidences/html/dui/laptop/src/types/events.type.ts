import type Citizen from "./citizen.type";
import type { Interception } from "./wiretap.type";


export interface EvidenceAnalysedEvent {
    inventory: number | string;
    slot: number;
    type: "fingerprint" | "dna";
}

export interface InterceptionStoredEvent {
    interception: Interception;
}

export interface BiometricDataLinkedEvent {
    type: "fingerprint" | "dna";
    identifier?: string;
    citizen: Citizen;
}