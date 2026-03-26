local magazine = lib.class("magazine", require "server.evidences.classes.evidence")
magazine.superClassName = "magazine"

function magazine:constructor(serial)
    self:super(serial)
end

return magazine