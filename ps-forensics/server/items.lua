local resourceName = GetCurrentResourceName()

RegisterNetEvent(resourceName .. ':server:itemUsed', function(itemName, slot)
    local src = source
    if not src or not itemName then return end

    ForensicAuditLog(src, 'forensic_item_used', 'item', 0, {
        item = itemName,
        slot = slot,
    })
end)
