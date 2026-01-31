-- Key Validation System (42-53.com)
local script_key = script_key or ""
if script_key == "" then
    game.Players.LocalPlayer:Kick("❌ No key provided. Please set script_key before running.")
    return
end

-- Get HWID from executor
local hwid = ""
local success_hwid, hwid_result = pcall(function()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end)
if success_hwid and hwid_result then
    hwid = tostring(hwid_result)
end
if hwid == "" then
    hwid = tostring(game:GetService("HttpService"):GenerateGUID(false))
end

local validationUrl = "https://webs-p0d5fm6fs-pyd3ad-hubs-projects.vercel.app/api/validate-key?script_key=" .. script_key .. "&hwid=" .. hwid

local function validateKey()
    local HttpService = game:GetService("HttpService")
    local success, response = pcall(function()
        return game:HttpGet(validationUrl, true)
    end)
    
    if not success then
        game.Players.LocalPlayer:Kick("❌ Key validation failed. Connection error: " .. tostring(response))
        return false
    end
    
    if not response or response == "" then
        game.Players.LocalPlayer:Kick("❌ Key validation failed. No response from server.")
        return false
    end
    
    -- Try to decode JSON
    local success2, validation = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not success2 then
        -- If JSON decode fails, the API might be returning HTML or an error page
        -- Check if it's a Vercel error page or HTML
        if string.find(response, "<!DOCTYPE", 1, true) or string.find(response, "<html", 1, true) then
            game.Players.LocalPlayer:Kick("❌ Key validation error. API endpoint not found. Please check Vercel deployment.")
        elseif string.find(response, "404", 1, true) or string.find(response, "NOT_FOUND", 1, true) then
            game.Players.LocalPlayer:Kick("❌ Key validation error. API endpoint not deployed. Please deploy to Vercel.")
        else
            -- Show first 100 chars of response for debugging
            local preview = string.sub(response, 1, 100)
            game.Players.LocalPlayer:Kick("❌ Key validation error. Invalid response: " .. preview)
        end
        return false
    end
    
    if not validation then
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

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CONFIG_FILE = "AmethystDragSafe.txt"
local DRAG_SPEED = 0.05

local savedPositions = {}
local connections = {}

if isfile(CONFIG_FILE) then
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if success and type(result) == "table" then
        savedPositions = result
    end
end

local function saveConfig()
    writefile(CONFIG_FILE, HttpService:JSONEncode(savedPositions))
end

local function makeDraggable(frame, uniqueId)
    if not frame then return end
    
    if connections[uniqueId] then
        for _, conn in pairs(connections[uniqueId]) do
            conn:Disconnect()
        end
        connections[uniqueId] = {}
    else
        connections[uniqueId] = {}
    end

    if savedPositions[uniqueId] then
        local posData = savedPositions[uniqueId]
        frame.Position = UDim2.new(posData.Xs, posData.Xo, posData.Ys, posData.Yo)
    end

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local inputBegan = frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    
                    savedPositions[uniqueId] = {
                        Xs = frame.Position.X.Scale,
                        Xo = frame.Position.X.Offset,
                        Ys = frame.Position.Y.Scale,
                        Yo = frame.Position.Y.Offset
                    }
                    saveConfig()
                end
            end)
        end
    end)

    local inputChanged = frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local globalInputChanged = UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            
            local targetPos = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
            
            frame.Position = targetPos
        end
    end)

    table.insert(connections[uniqueId], inputBegan)
    table.insert(connections[uniqueId], inputChanged)
    table.insert(connections[uniqueId], globalInputChanged)
end

local function hookPlayerList()
    local path = CoreGui:FindFirstChild("PlayerList")
    if not path then return end
    
    local function setup(child)
        if child.Name == "Children" and child:IsA("Frame") then
            task.wait() 
            makeDraggable(child, "PlayerList_Children")
        end
    end

    if path:FindFirstChild("Children") then
        setup(path.Children)
    end

    path.ChildAdded:Connect(setup)
end

local function hookExperienceChat()
    local path = CoreGui:FindFirstChild("ExperienceChat")
    if not path then return end

    local function setup(child)
        if child.Name == "appLayout" and child:IsA("Frame") then
            task.wait()
            makeDraggable(child, "ExperienceChat_AppLayout")
        end
    end

    if path:FindFirstChild("appLayout") then
        setup(path.appLayout)
    end

    path.ChildAdded:Connect(setup)
end

task.spawn(hookPlayerList)
task.spawn(hookExperienceChat)

CoreGui.ChildAdded:Connect(function(child)
    if child.Name == "PlayerList" then
        hookPlayerList()
    elseif child.Name == "ExperienceChat" then
        hookExperienceChat()
    end
end)
