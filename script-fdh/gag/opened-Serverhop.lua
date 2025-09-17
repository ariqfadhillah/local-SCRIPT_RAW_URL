-- ================== Bootstrap ala Infinite Yield ==================
if getgenv().GUI_LOADED and not _G.GUI_DEBUG then
    return
end
pcall(function() getgenv().GUI_LOADED = true end)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- helper missing()
local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

cloneref = missing("function", cloneref, function(...) return ... end)
queueteleport = missing("function", queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))

-- services
local COREGUI = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TweenService = cloneref(game:GetService("TweenService"))

local PlaceId, JobId = game.PlaceId, game.JobId

-- auto reload setelah teleport
local SCRIPT_RAW_URL = "https://raw.githubusercontent.com/ariqfadhillah/local-SCRIPT_RAW_URL/refs/heads/main/script-fdh/gag/opened-Serverhop.lua"
pcall(function()
    if queueteleport then
        queueteleport(("loadstring(game:HttpGet('%s'))()"):format(SCRIPT_RAW_URL))
    end
end)

-- ================== Main Wrapper ==================
local success, err = pcall(function()
    -- Animasi "Selamat Bermain"
    local splashGui = Instance.new("ScreenGui")
    splashGui.IgnoreGuiInset = true
    splashGui.ResetOnSpawn = false
    splashGui.Parent = COREGUI

    local splashLabel = Instance.new("TextLabel")
    splashLabel.Size = UDim2.new(1, 0, 1, 0)
    splashLabel.BackgroundTransparency = 1
    splashLabel.Text = "🎉 Selamat Bermain 🎉"
    splashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    splashLabel.TextScaled = true
    splashLabel.Font = Enum.Font.SourceSansBold
    splashLabel.TextTransparency = 1
    splashLabel.Parent = splashGui

    -- fade in
    local tweenIn = TweenService:Create(splashLabel, TweenInfo.new(1), {TextTransparency = 0})
    tweenIn:Play()
    tweenIn.Completed:Wait()

    task.wait(2)

    -- fade out
    local tweenOut = TweenService:Create(splashLabel, TweenInfo.new(1), {TextTransparency = 1})
    tweenOut:Play()
    tweenOut.Completed:Wait()

    splashGui:Destroy()

    -- ================== GUI Serverhop ==================
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ServerHopGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = COREGUI

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 140)
    frame.AnchorPoint = Vector2.new(0, 1)
    frame.Position = UDim2.new(0, 10, 1, -10)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🌍 Server Tools"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame

    -- tombol Serverhop
    local hopButton = Instance.new("TextButton")
    hopButton.Size = UDim2.new(1, -20, 0, 35)
    hopButton.Position = UDim2.new(0, 10, 0, 45)
    hopButton.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
    hopButton.Text = "🔄 Serverhop"
    hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    hopButton.Font = Enum.Font.SourceSansBold
    hopButton.TextScaled = true
    hopButton.Parent = frame

    -- tombol Exit
    local exitButton = Instance.new("TextButton")
    exitButton.Size = UDim2.new(1, -20, 0, 35)
    exitButton.Position = UDim2.new(0, 10, 0, 85)
    exitButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    exitButton.Text = "❌ Exit Game"
    exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    exitButton.Font = Enum.Font.SourceSansBold
    exitButton.TextScaled = true
    exitButton.Parent = frame

    -- fungsi serverhop
    local function serverhop()
        local servers = {}
        local ok, hopErr = pcall(function()
            local req = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
            local body = HttpService:JSONDecode(req)
            if body and body.data then
                for _, v in next, body.data do
                    if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
                        table.insert(servers, 1, v.id)
                    end
                end
            end
        end)

        if not ok then
            warn("⚠️ Serverhop error:", hopErr)
            return
        end

        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], Players.LocalPlayer)
        else
            warn("⚠️ Serverhop: Tidak ada server kosong yang ditemukan.")
        end
    end

    -- fungsi exit
    local function exitGame()
        local ok, exitErr = pcall(function()
            game:Shutdown()
        end)
        if not ok then
            warn("⚠️ Exit error:", exitErr)
        end
    end

    -- event klik
    hopButton.MouseButton1Click:Connect(serverhop)
    exitButton.MouseButton1Click:Connect(exitGame)
end)

-- print error kalau gagal load GUI/animasi
if not success then
    warn("⚠️ GUI/Animasi gagal dijalankan:", err)
end

