export interface Evidence {
    label: string;
    imagePath: string;
    inventory: number | string;
    slot: number;
    identifier: string;
    analysed: boolean;
}

export interface EvidenceDetails {
    crimeScene: string;
    collectionTime: string;
    additionalData: string;
}

export interface EvidenceData {
    identifier: string;
    firstname: string;
    lastname: string;
    birthdate: string;
}