--!strict
-- Payload Sanitization & Validation Helpers (Anti-Exploit Contract)

local Validator = {}

function Validator.isFiniteNumber(value: any): boolean
    return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Validator.isBoolean(value: any): boolean
    return typeof(value) == "boolean"
end

function Validator.isNonEmptyString(value: any, maxLength: number?): boolean
    if typeof(value) ~= "string" then
        return false
    end
    local limit = maxLength or 64
    return #value > 0 and #value <= limit
end

function Validator.isUnitOrZeroVector3(value: any): boolean
    if typeof(value) ~= "Vector3" then
        return false
    end
    local mag = value.Magnitude
    if mag ~= mag or mag == math.huge then
        return false
    end
    return mag <= 1.05
end

function Validator.isInArray(value: any, list: { string }): boolean
    if typeof(value) ~= "string" then
        return false
    end
    for _, item in list do
        if item == value then
            return true
        end
    end
    return false
end

function Validator.isKeyInTable(value: any, dict: { [string]: any }): boolean
    if typeof(value) ~= "string" then
        return false
    end
    return dict[value] ~= nil
end

return table.freeze(Validator)
