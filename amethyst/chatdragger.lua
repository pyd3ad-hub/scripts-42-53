-- Key Validation System (Auto-injected by 42-53.com)
local script_key = script_key or ""
if script_key == "" then
    game.Players.LocalPlayer:Kick("❌ No key provided. Please set script_key before running.")
    return
end

-- Get HWID from executor
local hwid = game:GetService("RbxAnalyticsService"):GetClientId() or ""
if not hwid or hwid == "" then
    hwid = tostring(game:GetService("HttpService"):GenerateGUID(false))
end

local validationUrl = "https://four253-api.onrender.com/api/validate-key?script_key=" .. script_key .. "&hwid=" .. hwid

local function validateKey()
    local HttpService = game:GetService("HttpService")
    local success, response = pcall(function()
        return game:HttpGet(validationUrl, true)
    end)
    
    if not success or not response then
        game.Players.LocalPlayer:Kick("❌ Key validation failed. Invalid key or connection error.")
        return false
    end
    
    local success2, validation = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success2 or not validation then
        game.Players.LocalPlayer:Kick("❌ Key validation error. Please contact support.")
        return false
    end
    
    if not validation.valid then
        local reason = validation.reason or "Invalid key"
        game.Players.LocalPlayer:Kick("❌ " .. reason)
        return false
    end
    
    return true
end

-- Validate key before executing script
if not validateKey() then
    return
end

-- Key validated, continue with script execution

-- 
-- 
-- 
-- 
-- 
g
