import { useEffect, useRef, useState } from "react";
import { useTranslation } from "../TranslationContext";


interface ItemChooserProps<AdditionalData> {
    selectionLabel: string;
    selected?: ItemContainerEntry<AdditionalData>;
    onUpdate: (selected: ItemContainerEntry<AdditionalData>) => void;
    items: ItemChooserInventory<AdditionalData>[];
    disabled?: boolean;
}

export interface ItemChooserInventory<AdditionalData> {
    label: string;
    inventory: number | string;
    items: ItemContainerEntry<AdditionalData>[];
}

export interface ItemContainerEntry<AdditionalData> {
    imagePath: string;
    label: string;
    slot: number;
    details?: Record<string, string>;
    additionalData?: AdditionalData;
}


export default function ItemChooser<AdditionalData>(props: ItemChooserProps<AdditionalData>) {
    const [dropdownOpen, setDropdownOpen] = useState<boolean>(false);
    const [cursorPos, setCursorPos] = useState<{ x: number; y: number }>({ x: 0, y: 0 });

    const containerRef = useRef<HTMLDivElement>(null);
    const { t } = useTranslation();


    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
                setDropdownOpen(false);
            }
        }

        document.addEventListener("mousedown", handleClickOutside);
        return () => {
            document.removeEventListener("mousedown", handleClickOutside);
        }
    }, []);


    const handleOpen = (e: React.MouseEvent) => {
        setCursorPos({ x: e.clientX, y: e.clientY });
        setDropdownOpen(prev => !prev);
    };


    const handleSelect = (selected: ItemContainerEntry<AdditionalData>) => {
        if (props.disabled) return;

        props.onUpdate(selected);
        setDropdownOpen(false);
    }
 

    return (<div ref={containerRef} className="w-full h-full relative">
        {/* Select div */}
        <div className={`flex justify-center items-center p-4 border-2 border-[black] ${props.disabled ? "" : "hoverable"}`} onClick={handleOpen}>
            {!props.selected ? (<div className="flex flex-col text-center">
                <p>&#43;</p>
                <p className="text-30 leading-none">{props.selectionLabel}</p>
            </div>) : <ItemDropdownEntry item={props.selected} handleSelect={() => {}} />}
        </div>

        {/* Dropdown */}
        {(dropdownOpen && !props.disabled) && 
            <div
                className="fixed max-h-80 p-3 flex flex-col z-1000 bg-window shadow-glass border-2 border-white/80 rounded-10 overflow-hidden hover:overflow-y-auto scrollbar scrollbar-gutter-stable"
                style={{ top: cursorPos.y, left: cursorPos.x }}
            >
                {(!props.items || props.items.length === 0) && <p className="text-30 leading-none italic">{t("laptop.desktop_screen.common.statuses.no_data")}</p>}
                {props.items.length !== 0 && props.items.map(container => <div className="flex flex-col gap-2 mb-3">
                    <p className="text-15 leading-none uppercase">{container.label}</p>
                    <div className="flex flex-col gap-2">
                        {container.items.map((item, index) => <ItemDropdownEntry<AdditionalData> key={index} handleSelect={handleSelect} item={item} />)}
                    </div>
                </div>)}
            </div>
        }
    </div>);
}



interface ItemDropdownEntryProps<AdditionalData> {
    item: ItemContainerEntry<AdditionalData>;
    handleSelect: (selected: ItemContainerEntry<AdditionalData>) => void;
}

function ItemDropdownEntry<AdditionalData>(props: ItemDropdownEntryProps<AdditionalData>) {
    return <div className="flex justify-center gap-2 hoverable" onClick={() => props.handleSelect(props.item)}>
        <img src={props.item.imagePath} className="w-7 h-7" />
        <div>
            <p className="text-30 leading-none">{props.item.label}</p>
            {props.item.details && Object.entries(props.item.details).map((key, value) => <p className="text-20 leading-none">{key}: {value}</p>)}
        </div>
        <p className="text-20 leading-none">{props.item.slot}</p>
    </div>
}