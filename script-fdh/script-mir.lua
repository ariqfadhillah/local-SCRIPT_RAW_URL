local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- CONFIG
local REFRESH_INTERVAL = 8 -- detik (revisi dari 3 → 8)
local AVG_HISTORY = 6
local espEnabled = true

-- STATE
local filters = { Rarity = {}, Material = {} }
local uiButtons = { Rarity = {}, Material = {} }
local discoveredRarities, discoveredMaterials = {}, {}
local activeBillboards = {}
local scanTimes = {}

-- Colors
local rarityColors = {
    Mercury   = Color3.fromRGB(150,150,150),
    Obsidian  = Color3.fromRGB(80,80,80),
    Jade      = Color3.fromRGB(0,200,100),
    Diamond   = Color3.fromRGB(0,200,255),
    Iridium   = Color3.fromRGB(180,100,255),
    Emerald   = Color3.fromRGB(0,255,0),
    Sapphire  = Color3.fromRGB(0,128,255),
    Plutonium = Color3.fromRGB(255,0,255),
    Uranium   = Color3.fromRGB(255,215,0),
}

local function colorFromString(s)
    local sum = 0
    for i = 1, #s do sum = sum + string.byte(s,i) end
    local hue = (sum % 360) / 360
    return Color3.fromHSV(hue, 0.9, 0.95)
end

-- UI SETUP
local gui = Instance.new("ScreenGui")
gui.Name = "RocksESP_GUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 360, 0, 540)
mainFrame.Position = UDim2.new(0.6, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(24,24,26)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,10)

-- Titlebar (draggable)
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(40,40,44)
title.Text = "📦 Rocks ESP Control BY -- Ariqfadh"
title.TextColor3 = Color3.fromRGB(230,230,230)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
Instance.new("UICorner", title).CornerRadius = UDim.new(0,8)

-- manual drag
local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Info box
local infoBox = Instance.new("TextLabel", mainFrame)
infoBox.Size = UDim2.new(1, -16, 0, 84)
infoBox.Position = UDim2.new(0, 8, 0, 44)
infoBox.BackgroundColor3 = Color3.fromRGB(32,32,36)
infoBox.TextColor3 = Color3.fromRGB(220,220,220)
infoBox.TextXAlignment = Enum.TextXAlignment.Left
infoBox.TextYAlignment = Enum.TextYAlignment.Top
infoBox.Font = Enum.Font.SourceSansSemibold
infoBox.TextSize = 14
infoBox.TextWrapped = true
infoBox.Text = "ESP: ...\nTotal Rocks: 0\nUnique Rarity: 0\nUnique Materials: 0\nLast Scan: 0.000s | Avg: 0.000s"
Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0,8)

-- Buttons
local controls = Instance.new("Frame", mainFrame)
controls.Size = UDim2.new(1, -16, 0, 36)
controls.Position = UDim2.new(0, 8, 0, 136)
controls.BackgroundTransparency = 1

local btnToggleESP = Instance.new("TextButton", controls)
btnToggleESP.Size = UDim2.new(0.5, -6, 1, 0)
btnToggleESP.Text = espEnabled and "ESP: ON" or "ESP: OFF"
btnToggleESP.Font = Enum.Font.SourceSansBold
btnToggleESP.TextSize = 14
btnToggleESP.BackgroundColor3 = espEnabled and Color3.fromRGB(18,150,80) or Color3.fromRGB(80,80,80)
Instance.new("UICorner", btnToggleESP).CornerRadius = UDim.new(0,6)

local btnRefresh = Instance.new("TextButton", controls)
btnRefresh.Size = UDim2.new(0.5, -6, 1, 0)
btnRefresh.Position = UDim2.new(0.5, 6, 0, 0)
btnRefresh.Text = "Refresh"
btnRefresh.Font = Enum.Font.SourceSansBold
btnRefresh.TextSize = 14
btnRefresh.BackgroundColor3 = Color3.fromRGB(60,90,160)
Instance.new("UICorner", btnRefresh).CornerRadius = UDim.new(0,6)

-- Scroll area
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -16, 1, -200)
scroll.Position = UDim2.new(0, 8, 0, 180)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0,6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 12)
end)

-- Groups
local function makeGroup(titleText, titleColor)
    local header = Instance.new("TextLabel", scroll)
    header.Size = UDim2.new(1, -12, 0, 22)
    header.BackgroundTransparency = 1
    header.Text = "["..titleText.."]"
    header.TextColor3 = titleColor or Color3.fromRGB(200,200,200)
    header.Font = Enum.Font.SourceSansBold
    header.TextSize = 15
    header.TextXAlignment = Enum.TextXAlignment.Left

    local container = Instance.new("Frame", scroll)
    container.Size = UDim2.new(1, -12, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0,4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    return header, container
end

local _, contRarity = makeGroup("RARITY", Color3.fromRGB(0,220,120))
local _, contMaterial = makeGroup("MATERIAL", Color3.fromRGB(0,170,255))

-- Checkbox
local function registerCheckbox(category, name, initialState, color)
    if filters[category][name] ~= nil then return end
    filters[category][name] = (initialState == nil) and true or initialState

    local container = (category == "Rarity") and contRarity or contMaterial
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(36,36,38)
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local ind = Instance.new("Frame", btn)
    ind.Size = UDim2.new(0,18,0,18)
    ind.Position = UDim2.new(0,6,0,4)
    ind.BackgroundColor3 = color or Color3.fromRGB(90,90,90)
    Instance.new("UICorner", ind).CornerRadius = UDim.new(0,4)

    local label = Instance.new("TextLabel", btn)
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.Text = name
    label.TextColor3 = Color3.fromRGB(240,240,240)

    local stateBox = Instance.new("TextLabel", btn)
    stateBox.Size = UDim2.new(0,22,0,18)
    stateBox.Position = UDim2.new(1, -28, 0.5, -9)
    stateBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
    stateBox.TextColor3 = Color3.fromRGB(240,240,240)
    stateBox.Font = Enum.Font.SourceSansBold
    stateBox.TextSize = 14
    stateBox.Text = filters[category][name] and "✓" or ""
    Instance.new("UICorner", stateBox).CornerRadius = UDim.new(0,4)

    uiButtons[category][name] = {stateBox = stateBox}

    btn.MouseButton1Click:Connect(function()
        filters[category][name] = not filters[category][name]
        stateBox.Text = filters[category][name] and "✓" or ""
        scanAndUpdate(true)
    end)
end

-- Billboard
local function createBillboard(part, text, color)
    if not part or not part.Parent then return end
    if activeBillboards[part] then activeBillboards[part]:Destroy() end
    local bb = Instance.new("BillboardGui")
    bb.Name = "RocksESP_Billboard"
    bb.Adornee = part
    bb.Size = UDim2.new(0, 140, 0, 40)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 2.4, 0)
    bb.Parent = part
    local txt = Instance.new("TextLabel", bb)
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = color or Color3.fromRGB(255,255,255)
    txt.TextStrokeTransparency = 0.4
    txt.Font = Enum.Font.SourceSansBold
    txt.TextScaled = true
    activeBillboards[part] = bb
end

local function clearAllBillboards()
    for _, bb in pairs(activeBillboards) do
        if bb then bb:Destroy() end
    end
    activeBillboards = {}
end

-- Main scan
function scanAndUpdate(force)
    local rocksFolder = workspace:FindFirstChild("Rocks")
    if not rocksFolder then
        infoBox.Text = "Rocks folder not found (workspace.Rocks)"
        return
    end
    local t0 = tick()
    local total = 0

    for _, child in ipairs(rocksFolder:GetChildren()) do
        if child:IsA("BasePart") then
            total += 1
            local t = child:GetAttribute("Type")
            local m = tostring(child.Material)
            if t and not discoveredRarities[t] then
                discoveredRarities[t] = true
                registerCheckbox("Rarity", t, true, rarityColors[t] or colorFromString(t))
            end
            if m and m ~= "Rock" and not discoveredMaterials[m] then
                discoveredMaterials[m] = true
                registerCheckbox("Material", m, true, colorFromString(m))
            end
        end
    end

    clearAllBillboards()
    if espEnabled then
        for _, child in ipairs(rocksFolder:GetChildren()) do
            if child:IsA("BasePart") then
                local t = child:GetAttribute("Type")
                local m = tostring(child.Material)
                local show = false
                if t and filters.Rarity[t] then show = true end
                if m and m ~= "Rock" and filters.Material[m] then show = true end
                if show then
                    local color = rarityColors[t] or colorFromString(t)
                    local label = t or m
                    createBillboard(child, label, color)
                end
            end
        end
    end

    local elapsed = tick() - t0
    table.insert(scanTimes, 1, elapsed)
    if #scanTimes > AVG_HISTORY then table.remove(scanTimes) end
    local avg = 0 for _, v in ipairs(scanTimes) do avg += v end
    avg = (#scanTimes>0) and (avg / #scanTimes) or 0
    local uniqR, uniqM = 0,0
    for _ in pairs(discoveredRarities) do uniqR+=1 end
    for _ in pairs(discoveredMaterials) do uniqM+=1 end

    infoBox.Text = string.format(
        "ESP: %s\nTotal Rocks: %d\nUnique Rarity: %d\nUnique Materials: %d\nLast Scan: %.3fs | Avg: %.3fs",
        espEnabled and "ON" or "OFF",
        total, uniqR, uniqM, elapsed, avg
    )
end

-- Buttons
btnToggleESP.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    btnToggleESP.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    btnToggleESP.BackgroundColor3 = espEnabled and Color3.fromRGB(18,150,80) or Color3.fromRGB(80,80,80)
    if not espEnabled then clearAllBillboards() else scanAndUpdate(true) end
end)
btnRefresh.MouseButton1Click:Connect(function() scanAndUpdate(true) end)

-- Init
scanAndUpdate(true)
task.spawn(function()
    while true do
        task.wait(REFRESH_INTERVAL)
        scanAndUpdate()
    end
end)

RunService.Heartbeat:Connect(function()
    for part, bb in pairs(activeBillboards) do
        if (not part) or (not part.Parent) then
            if bb then bb:Destroy() end
            activeBillboards[part] = nil
        end
    end
end)