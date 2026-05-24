if _G.RivalsLoaded then
    for _, conn in pairs(_G.RivalsConnections or {}) do conn:Disconnect() end
    if _G.RivalsGui then _G.RivalsGui:Destroy() end
    if _G.RivalsFOV then _G.RivalsFOV:Remove() end
    if _G.RivalsESP then for _, e in pairs(_G.RivalsESP) do
        e.Box:Remove(); e.Name:Remove(); e.Health:Remove(); e.Weapon:Remove(); e.Distance:Remove(); e.Tracer:Remove(); e.Snapline:Remove()
    end end
    if _G.RivalsTargetInfo then for _, d in pairs(_G.RivalsTargetInfo) do d:Remove() end end
    if _G.RivalsStars then for _, s in ipairs(_G.RivalsStars) do s.Drawing:Remove() end end
end
_G.RivalsLoaded = true
_G.RivalsConnections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local ConfigFolder = "RivalsConfigs"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local DefaultConfig = {
    AimbotEnabled = true,
    AimKey = "MouseButton2",
    AimKeyMode = "Hold",
    AimMode = "Custom",
    AimMethod = "Camera",
    SnapAim = false,
    FOV = 100,
    ShowFOV = true,
    Smoothness = 20,
    AimSpeed = 5,
    AimPart = "Head",
    TargetLock = true,
    TargetPriority = "FOV",
    TeamCheck = true,
    WallCheck = true,
    TriggerbotEnabled = false,
    TriggerbotDelay = 50,
    NoSpreadEnabled = false,
    ESPEnabled = true,
    BoxType = "2D",
    ShowNames = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowTracers = false,
    ShowSnaplines = false,
    ShowWeapon = true,
    ShowVisibility = true,
    MaxDistance = 1000,
    ESPUpdateRate = 3,
    TargetInfoEnabled = true,
    TargetInfoX = 10,
    TargetInfoY = 400,
    BoxColor = {255, 50, 50},
    NameColor = {255, 255, 255},
    HealthColor = {50, 255, 50},
    TracerColor = {255, 50, 50},
    FOVColor = {255, 255, 255},
    TargetInfoBg = {30, 30, 50},
    MenuTheme = "Dark",
    FriendList = {},
    AntiSmoke = false,
    AntiFlash = false,
    SlideSpeed = false,
    SlideBoost = 30,
    NoSpreadKey = "C",
    NoSpreadAutoRefresh = true,
    NoSpreadRefreshKey = "R",
    SlideSpeed = false, = true,
    ShowNames = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowTracers = false,
    ShowSnaplines = false,
    ShowWeapon = true,
    ShowVisibility = true,
    MaxDistance = 1000,
    ESPUpdateRate = 3,
    TargetInfoEnabled = true,
    TargetInfoX = 10,
    TargetInfoY = 400,
    BoxColor = {255, 50, 50},
    NameColor = {255, 255, 255},
    HealthColor = {50, 255, 50},
    TracerColor = {255, 50, 50},
    FOVColor = {255, 255, 255},
    TargetInfoBg = {30, 30, 50},
    MenuTheme = "Dark",
    FriendList = {},
    AntiSmoke = false,
    AntiFlash = false,
    SlideSpeed = false,
    SlideBoost = 30,
    InstantKillEnabled = false,
    InstantKillKey = "Z",
    InstantKillDelay = 15,
    InstantKillDistance = 2,
    InstantKillPreTeleportDistance = 0,
    InstantKillPreAttackPercent = 20,
    InstantKillPostAttackPercent = 80,
    InstantKillTriggerbotBlock = 1000
}

local Config = {}
for k, v in pairs(DefaultConfig) do
    if type(v) == "table" then
        Config[k] = {}
        for i, val in pairs(v) do Config[k][i] = val end
    else
        Config[k] = v
    end
end

local CurrentConfigName = "default"

local Themes = {
    Dark = {Main = Color3.fromRGB(20, 20, 30), Secondary = Color3.fromRGB(30, 30, 45), Accent = Color3.fromRGB(80, 120, 255), AccentAlt = Color3.fromRGB(120, 80, 255), Text = Color3.fromRGB(240, 240, 255), TextDim = Color3.fromRGB(130, 130, 160), Glass = Color3.fromRGB(255, 255, 255), GlassAlpha = 0.05},
    Purple = {Main = Color3.fromRGB(25, 15, 40), Secondary = Color3.fromRGB(40, 25, 65), Accent = Color3.fromRGB(160, 60, 255), AccentAlt = Color3.fromRGB(220, 100, 255), Text = Color3.fromRGB(240, 230, 255), TextDim = Color3.fromRGB(160, 130, 200), Glass = Color3.fromRGB(180, 120, 255), GlassAlpha = 0.06},
    Red = {Main = Color3.fromRGB(30, 15, 18), Secondary = Color3.fromRGB(50, 25, 30), Accent = Color3.fromRGB(255, 50, 70), AccentAlt = Color3.fromRGB(255, 100, 60), Text = Color3.fromRGB(255, 235, 240), TextDim = Color3.fromRGB(200, 140, 150), Glass = Color3.fromRGB(255, 100, 100), GlassAlpha = 0.05},
    Blue = {Main = Color3.fromRGB(15, 20, 38), Secondary = Color3.fromRGB(25, 35, 65), Accent = Color3.fromRGB(40, 140, 255), AccentAlt = Color3.fromRGB(80, 200, 255), Text = Color3.fromRGB(230, 240, 255), TextDim = Color3.fromRGB(130, 170, 220), Glass = Color3.fromRGB(80, 160, 255), GlassAlpha = 0.06},
    Green = {Main = Color3.fromRGB(15, 25, 20), Secondary = Color3.fromRGB(25, 45, 35), Accent = Color3.fromRGB(40, 220, 100), AccentAlt = Color3.fromRGB(100, 255, 150), Text = Color3.fromRGB(230, 255, 240), TextDim = Color3.fromRGB(130, 200, 160), Glass = Color3.fromRGB(80, 255, 140), GlassAlpha = 0.05}
}

local function GetTheme() return Themes[Config.MenuTheme] or Themes.Dark end

local function SaveConfig(name)
    writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(Config))
end

local function LoadConfig(name)
    if not isfile(ConfigFolder .. "/" .. name .. ".json") then return false end
    local data = readfile(ConfigFolder .. "/" .. name .. ".json")
    if data then
        local decoded = HttpService:JSONDecode(data)
        if decoded then
            for k, v in pairs(decoded) do Config[k] = v end
            CurrentConfigName = name
            return true
        end
    end
    return false
end

local function DeleteConfig(name) delfile(ConfigFolder .. "/" .. name .. ".json") end

local function GetConfigs()
    local configs = {}
    for _, file in ipairs(listfiles(ConfigFolder)) do
        local name = file:match("([^/\\]+)%.json$")
        if name then table.insert(configs, name) end
    end
    return configs
end

local function OpenConfigFolder() if setclipboard then setclipboard(ConfigFolder) end end

LoadConfig("_autosave")
task.spawn(function() while true do task.wait(10); SaveConfig("_autosave") end end)

local Aiming, AimToggled, LockedTarget = false, false, nil
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.5
local ESPCache = {}
local MenuOpen = false
local ESPUpdateCounter = 0
local PlayerListUpdateCounter = 0
local CachedMyRoot, CachedPlayers = nil, {}
local CurrentTab = "Aimbot"

local TargetInfo = {
    Bg = Drawing.new("Square"),
    Name = Drawing.new("Text"),
    HP = Drawing.new("Text"),
    HealthBg = Drawing.new("Square"),
    HealthFill = Drawing.new("Square")
}

TargetInfo.Bg.Filled = true
TargetInfo.Bg.Color = Color3.fromRGB(30, 30, 50)
TargetInfo.Bg.Transparency = 0.8
TargetInfo.Bg.Visible = false
TargetInfo.Name.Size = 16
TargetInfo.Name.Font = Drawing.Fonts.Plex
TargetInfo.Name.Color = Color3.new(1,1,1)
TargetInfo.Name.Outline = true
TargetInfo.Name.Visible = false
TargetInfo.HP.Size = 14
TargetInfo.HP.Font = Drawing.Fonts.Plex
TargetInfo.HP.Color = Color3.fromRGB(200, 200, 200)
TargetInfo.HP.Outline = true
TargetInfo.HP.Visible = false
TargetInfo.HealthBg.Filled = true
TargetInfo.HealthBg.Color = Color3.fromRGB(50, 50, 50)
TargetInfo.HealthBg.Visible = false
TargetInfo.HealthFill.Filled = true
TargetInfo.HealthFill.Color = Color3.fromRGB(150, 50, 255)
TargetInfo.HealthFill.Visible = false

_G.RivalsFOV = FOVCircle
_G.RivalsTargetInfo = TargetInfo

local function IsTeammate(p)
    if not Config.TeamCheck or not LocalPlayer.Team then return false end
    return p.Team == LocalPlayer.Team
end

local function IsFriend(p)
    for _, f in ipairs(Config.FriendList) do
        if p.Name == f or p.DisplayName == f or p.UserId == f then return true end
    end
    return false
end

local function StringToKey(s)
    if s == "MouseButton1" then return Enum.UserInputType.MouseButton1 end
    if s == "MouseButton2" then return Enum.UserInputType.MouseButton2 end
    return Enum.KeyCode[s]
end

local function C3(t) return Color3.fromRGB(t[1], t[2], t[3]) end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true
RayParams.RespectCanCollide = true

local function IsVisible(targetPart)
    if not targetPart then return false end
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = (targetPos - origin)
    local distance = direction.Magnitude
    RayParams.FilterDescendantsInstances = {myChar, Camera}
    RayParams.FilterType = Enum.RaycastFilterType.Exclude
    local maxAttempts = 5
    local currentFilter = {myChar, Camera}
    for attempt = 1, maxAttempts do
        RayParams.FilterDescendantsInstances = currentFilter
        local result = workspace:Raycast(origin, direction, RayParams)
        if not result then return true end
        local hit = result.Instance
        local targetChar = targetPart:FindFirstAncestorOfClass("Model")
        if targetChar and hit:IsDescendantOf(targetChar) then return true end
        local hitDistance = (result.Position - origin).Magnitude
        if math.abs(hitDistance - distance) < 1.5 then return true end
        if hit:IsA("BasePart") and (hit.Transparency >= 0.9 or not hit.CanCollide) then
            table.insert(currentFilter, hit)
        else
            return false
        end
    end
    return false
end

local function FindPart(char, partName)
    local part = char:FindFirstChild(partName)
    if part then return part end
    part = char:FindFirstChild(partName, true)
    if part then return part end
    for _, child in ipairs(char:GetDescendants()) do
        if child.Name == partName and child:IsA("BasePart") then return child end
    end
    return nil
end

local function GetEquippedWeaponName(player)
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    return nil
end

local function GetHealthColor(hp, maxHp)
    local ratio = hp / maxHp
    if ratio > 0.7 then return Color3.fromRGB(80, 220, 120) end
    if ratio > 0.4 then return Color3.fromRGB(255, 200, 60) end
    return Color3.fromRGB(255, 70, 80)
end

-- Snap Aim
local SnapAimActive = false
local SnapAimTarget = nil

local function GetSnapTarget()
    if not Config.AimbotEnabled then return nil end
    local mouse = UserInputService:GetMouseLocation()
    local best, bestValue = nil, math.huge
    for _, p in ipairs(CachedPlayers) do
        if p ~= LocalPlayer and not IsTeammate(p) and not IsFriend(p) then
            local char = p.Character
            if char then
                local part = char:FindFirstChild(Config.AimPart)
                local hum = char:FindFirstChild("Humanoid")
                if part and hum and hum.Health > 0 then
                    local pos, vis = Camera:WorldToViewportPoint(part.Position)
                    if vis then
                        local fovDist = (mouse - Vector2.new(pos.X, pos.Y)).Magnitude
                        if fovDist <= Config.FOV then
                            if not (Config.WallCheck and not IsVisible(part)) then
                                if fovDist < bestValue then
                                    bestValue = fovDist
                                    best = p
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function StartSnapAim()
    SnapAimActive = true
    SnapAimTarget = GetSnapTarget()
end

local function StopSnapAim()
    SnapAimActive = false
    SnapAimTarget = nil
end

local function UpdateSnapAim()
    if not SnapAimActive or not Config.SnapAim or not Config.AimbotEnabled then return end
    local target = GetSnapTarget()
    if not target then return end
    local char = target.Character
    if not char then return end
    local part = char:FindFirstChild(Config.AimPart)
    local hum = char:FindFirstChild("Humanoid")
    if not part or not hum or hum.Health <= 0 then return end
    local pos, vis = Camera:WorldToViewportPoint(part.Position)
    if not vis then return end
    local mouse = UserInputService:GetMouseLocation()
    local screenPos = Vector2.new(pos.X, pos.Y)
    local delta = screenPos - mouse
    if delta.Magnitude > 1 then
        if mousemoverel then
            mousemoverel(delta.X, delta.Y)
        end
    end
end

-- ESP System (lean: 7 objects per player)
local function CreateESP(player)
    if ESPCache[player] then return end
    ESPCache[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Weapon = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Snapline = Drawing.new("Line")
    }
    local e = ESPCache[player]
    e.Box.Thickness = 1
    e.Box.Filled = false
    e.Box.Transparency = 1
    e.Name.Size = 13
    e.Name.Center = true
    e.Name.Outline = true
    e.Name.Font = Drawing.Fonts.Plex
    e.Health.Size = 12
    e.Health.Center = true
    e.Health.Outline = true
    e.Health.Font = Drawing.Fonts.Plex
    e.Weapon.Size = 11
    e.Weapon.Center = true
    e.Weapon.Outline = true
    e.Weapon.Font = Drawing.Fonts.Plex
    e.Distance.Size = 12
    e.Distance.Center = true
    e.Distance.Outline = true
    e.Distance.Font = Drawing.Fonts.Plex
    e.Tracer.Thickness = 1
    e.Snapline.Thickness = 1
    e.Snapline.Color = Color3.fromRGB(255, 255, 255)
    e.Snapline.Transparency = 0.5
    -- Start hidden
    e.Box.Visible = false
    e.Name.Visible = false
    e.Health.Visible = false
    e.Weapon.Visible = false
    e.Distance.Visible = false
    e.Tracer.Visible = false
    e.Snapline.Visible = false
end

local function RemoveESP(player)
    local e = ESPCache[player]
    if not e then return end
    e.Box:Remove()
    e.Name:Remove()
    e.Health:Remove()
    e.Weapon:Remove()
    e.Distance:Remove()
    e.Tracer:Remove()
    e.Snapline:Remove()
    ESPCache[player] = nil
end

local function HideESP(e)
    e.Box.Visible = false
    e.Name.Visible = false
    e.Health.Visible = false
    e.Weapon.Visible = false
    e.Distance.Visible = false
    e.Tracer.Visible = false
    e.Snapline.Visible = false
end

local function UpdateESP(player, e)
    local char = player.Character
    if not char then HideESP(e); return end
    local hum, root, head = char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart"), char:FindFirstChild("Head")
    if not hum or not root or not head or hum.Health <= 0 or IsTeammate(player) or IsFriend(player) then
        HideESP(e); return
    end
    local dist = CachedMyRoot and (root.Position - CachedMyRoot.Position).Magnitude or 0
    if dist > Config.MaxDistance then HideESP(e); return end

    -- Visibility check for ESP indicator
    local espPart = char:FindFirstChild(Config.AimPart) or head
    local playerIsVisible = IsVisible(espPart)

    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
    local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
    local h, w = math.abs(headPos.Y - legPos.Y), math.abs(headPos.Y - legPos.Y) * 0.6
    local x, y = pos.X - w/2, headPos.Y
    local boxColor = C3(Config.BoxColor)

    -- 2D Box
    if onScreen then
        e.Box.Size = Vector2.new(w, h)
        e.Box.Position = Vector2.new(x, y)
        e.Box.Color = boxColor
        e.Box.Visible = true
    else
        e.Box.Visible = false
    end

    -- Name with visibility indicator
    if Config.ShowNames and onScreen then
        local visIcon = ""
        if Config.ShowVisibility then
            visIcon = playerIsVisible and " [OK]" or " [X]"
        end
        e.Name.Text = player.DisplayName .. visIcon
        e.Name.Position = Vector2.new(pos.X, y - 15)
        e.Name.Color = playerIsVisible and C3(Config.NameColor) or Color3.fromRGB(180, 180, 180)
        e.Name.Visible = true
    else
        e.Name.Visible = false
    end

    -- Health as text
    if Config.ShowHealth and onScreen then
        local hp = math.floor(hum.Health)
        local maxHp = math.floor(hum.MaxHealth)
        e.Health.Text = hp .. "/" .. maxHp
        e.Health.Position = Vector2.new(pos.X, y + h + 2)
        e.Health.Color = GetHealthColor(hum.Health, hum.MaxHealth)
        e.Health.Visible = true
    else
        e.Health.Visible = false
    end

    -- Weapon name
    if Config.ShowWeapon and onScreen then
        local weaponName = GetEquippedWeaponName(player)
        if weaponName then
            e.Weapon.Text = weaponName
            e.Weapon.Position = Vector2.new(pos.X, y + h + 16)
            e.Weapon.Color = Color3.fromRGB(180, 180, 220)
            e.Weapon.Visible = true
        else
            e.Weapon.Visible = false
        end
    else
        e.Weapon.Visible = false
    end

    -- Distance
    if Config.ShowDistance and onScreen then
        local distOffset = 0
        if Config.ShowHealth then distOffset = distOffset + 14 end
        if Config.ShowWeapon then distOffset = distOffset + 14 end
        e.Distance.Text = math.floor(dist) .. "m"
        e.Distance.Position = Vector2.new(pos.X, y + h + 2 + distOffset)
        e.Distance.Color = Color3.fromRGB(200, 200, 200)
        e.Distance.Visible = true
    else
        e.Distance.Visible = false
    end

    -- Tracers
    if Config.ShowTracers then
        local screen = Camera.ViewportSize
        e.Tracer.From = Vector2.new(screen.X / 2, screen.Y)
        e.Tracer.To = Vector2.new(pos.X, y + h)
        e.Tracer.Color = C3(Config.TracerColor)
        e.Tracer.Visible = true
    else
        e.Tracer.Visible = false
    end

    -- Snaplines
    if Config.ShowSnaplines then
        local screen = Camera.ViewportSize
        e.Snapline.From = Vector2.new(screen.X / 2, screen.Y)
        e.Snapline.To = Vector2.new(pos.X, legPos.Y)
        e.Snapline.Color = Color3.fromRGB(200, 200, 255)
        e.Snapline.Visible = true
    else
        e.Snapline.Visible = false
    end
end

local TargetInfoUpdateCounter = 0
local function UpdateTargetInfo(target)
    TargetInfoUpdateCounter = TargetInfoUpdateCounter + 1
    if TargetInfoUpdateCounter < 2 then return end
    TargetInfoUpdateCounter = 0
    if not Config.TargetInfoEnabled or not target then
        if TargetInfo.Bg.Visible then
            TargetInfo.Bg.Visible = false
            TargetInfo.Name.Visible = false
            TargetInfo.HP.Visible = false
            TargetInfo.HealthBg.Visible = false
            TargetInfo.HealthFill.Visible = false
        end
        return
    end
    local char = target.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not hum or hum.Health <= 0 then
        if TargetInfo.Bg.Visible then
            TargetInfo.Bg.Visible = false
            TargetInfo.Name.Visible = false
            TargetInfo.HP.Visible = false
            TargetInfo.HealthBg.Visible = false
            TargetInfo.HealthFill.Visible = false
        end
        return
    end
    local part = char:FindFirstChild(Config.AimPart)
    local isVisible = part and IsVisible(part) or false
    local visText = isVisible and "Visible" or "Behind Wall"
    local visColor = isVisible and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
    local x, y = Config.TargetInfoX, Config.TargetInfoY
    local width, height = 180, 80
    TargetInfo.Bg.Size = Vector2.new(width, height)
    TargetInfo.Bg.Position = Vector2.new(x, y)
    TargetInfo.Bg.Color = C3(Config.TargetInfoBg)
    TargetInfo.Bg.Visible = true
    TargetInfo.Name.Text = target.DisplayName
    TargetInfo.Name.Position = Vector2.new(x + 10, y + 8)
    TargetInfo.Name.Visible = true
    local hp, maxHp = math.floor(hum.Health), math.floor(hum.MaxHealth)
    TargetInfo.HP.Text = "HP: " .. hp .. "/" .. maxHp .. "\n" .. visText
    TargetInfo.HP.Position = Vector2.new(x + 10, y + 26)
    TargetInfo.HP.Color = visColor
    TargetInfo.HP.Visible = true
    TargetInfo.HealthBg.Size = Vector2.new(width - 20, 8)
    TargetInfo.HealthBg.Position = Vector2.new(x + 10, y + 60)
    TargetInfo.HealthBg.Visible = true
    local hpPercent = hum.Health / hum.MaxHealth
    TargetInfo.HealthFill.Size = Vector2.new((width - 20) * hpPercent, 8)
    TargetInfo.HealthFill.Position = Vector2.new(x + 10, y + 60)
    TargetInfo.HealthFill.Color = Color3.fromRGB(150, 50, 255)
    TargetInfo.HealthFill.Visible = true
end

-- ============================================
-- GUI MENU SYSTEM
-- ============================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "RivalsUI"
Gui.ResetOnSpawn = false
if syn then syn.protect_gui(Gui) end
Gui.Parent = gethui and gethui() or game.CoreGui
_G.RivalsGui = Gui

-- Background overlay with falling stars
local MenuOverlay = Instance.new("Frame")
MenuOverlay.Name = "Overlay"
MenuOverlay.Size = UDim2.new(1, 0, 1, 0)
MenuOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MenuOverlay.BackgroundTransparency = 0.5
MenuOverlay.Visible = false
MenuOverlay.ZIndex = 0
MenuOverlay.Parent = Gui

local StarsConnection = nil
local Stars = {}
_G.RivalsStars = Stars

local function CreateStars()
    for _, s in ipairs(Stars) do s.Drawing:Remove() end
    Stars = {}
    _G.RivalsStars = Stars
    for i = 1, 40 do
        local star = Drawing.new("Line")
        star.Thickness = math.random(1, 2)
        star.Color = Color3.fromRGB(
            math.random(180, 255),
            math.random(180, 255),
            math.random(200, 255)
        )
        star.Transparency = math.random(30, 80) / 100
        star.From = Vector2.new(math.random(0, 1920), math.random(-100, 0))
        star.To = Vector2.new(star.From.X + math.random(-2, 2), star.From.Y + math.random(8, 25))
        star.Visible = false
        table.insert(Stars, {
            Drawing = star,
            Speed = math.random(60, 200),
            Drift = math.random(-15, 15)
        })
    end
end

local function StartStars()
    CreateStars()
    if StarsConnection then StarsConnection:Disconnect() end
    StarsConnection = RunService.RenderStepped:Connect(function(dt)
        for _, data in ipairs(Stars) do
            local s = data.Drawing
            local spd = data.Speed * dt
            local drift = data.Drift * dt
            s.From = Vector2.new(s.From.X + drift, s.From.Y + spd)
            s.To = Vector2.new(s.From.X + math.random(-2, 2), s.From.Y + math.random(8, 25))
            local screenY = Camera.ViewportSize.Y
            if s.From.Y > screenY + 50 then
                s.From = Vector2.new(math.random(0, Camera.ViewportSize.X), math.random(-100, -10))
                s.To = Vector2.new(s.From.X + math.random(-2, 2), s.From.Y + math.random(8, 25))
            end
            s.Visible = MenuOpen
        end
    end)
end

StartStars()

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 480, 0, 380)
Main.Position = UDim2.new(0.5, -240, 0.5, -190)
Main.BorderSizePixel = 0
Main.Visible = false
Main.ZIndex = 10
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(80, 80, 120)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.5
MainStroke.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 11
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
local TitleBarFix = Instance.new("Frame")
TitleBarFix.Size = UDim2.new(1, 0, 0, 15)
TitleBarFix.Position = UDim2.new(0, 0, 1, -15)
TitleBarFix.BorderSizePixel = 0
TitleBarFix.ZIndex = 11
TitleBarFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 28)
TitleLabel.Position = UDim2.new(0, 0, 0, 4)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "RIVALS"
TitleLabel.TextSize = 20
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.ZIndex = 12
TitleLabel.Parent = TitleBar

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Size = UDim2.new(1, 0, 0, 16)
SubtitleLabel.Position = UDim2.new(0, 0, 1, -16)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = "v2.1  |  " .. game.PlaceId .. "  |  " .. #Players:GetPlayers() .. " players"
SubtitleLabel.TextSize = 10
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.ZIndex = 12
SubtitleLabel.Parent = TitleBar

local drag, dragStart, startPos
TitleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dragStart = i.Position; startPos = Main.Position end end)
TitleBar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dragStart; Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 110, 1, -54)
TabBar.Position = UDim2.new(0, 0, 0, 50)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 11
TabBar.Parent = Main

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -118, 1, -58)
Content.Position = UDim2.new(0, 114, 0, 54)
Content.BorderSizePixel = 0
Content.ZIndex = 11
Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 6)

local Pages = {}
local Tabs = {"Aimbot", "ESP", "Visuals", "Instant Kill", "Friends", "Config", "Theme", "Other"}
local TabIcons = {Aimbot = "🎯", ESP = "👁", Visuals = "🎨", ["Instant Kill"] = "💀", Friends = "👥", Config = "💾", Theme = "🎭", Other = "⚙"}
local TabButtons = {}

local function ApplyTheme()
    local theme = GetTheme()
    Main.BackgroundColor3 = theme.Main
    MainStroke.Color = theme.Accent
    TitleBar.BackgroundColor3 = theme.Secondary
    TitleLabel.TextColor3 = theme.Text
    SubtitleLabel.TextColor3 = theme.TextDim
    TabBar.BackgroundColor3 = theme.Main
    Content.BackgroundColor3 = theme.Secondary
    MenuOverlay.BackgroundTransparency = 0.6
    for _, btn in pairs(TabButtons) do
        if btn.Name == CurrentTab then
            btn.BackgroundColor3 = theme.Accent
        else
            btn.BackgroundColor3 = Color3.fromRGB(theme.Secondary.R * 255, theme.Secondary.G * 255, theme.Secondary.B * 255)
        end
        btn.TextColor3 = theme.Text
    end
    for name, page in pairs(Pages) do
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("Frame") then
                if child:GetAttribute("IsLabel") then
                    child.BackgroundColor3 = theme.Accent
                else
                    child.BackgroundColor3 = theme.Main
                end
            elseif child:IsA("TextLabel") then
                child.TextColor3 = theme.Text
            elseif child:IsA("TextButton") then
                if not TabButtons[child.Name] then
                    child.BackgroundColor3 = theme.Accent
                    child.TextColor3 = theme.Text
                end
            elseif child:IsA("TextBox") then
                child.BackgroundColor3 = theme.Main
                child.TextColor3 = theme.Text
            end
        end
    end
end

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, -10, 1, -10)
    page.Position = UDim2.new(0, 5, 0, 5)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = GetTheme().Accent
    page.Visible = (name == "Aimbot")
    page.ZIndex = 12
    page.Parent = Content
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = page
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10) end)
    Pages[name] = page
    return page
end

local function SwitchTab(name)
    CurrentTab = name
    for n, page in pairs(Pages) do page.Visible = (n == name) end
    ApplyTheme()
end

local function CreateTabButton(name, index)
    local theme = GetTheme()
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, 4 + (index - 1) * 34)
    btn.BackgroundColor3 = (name == "Aimbot") and theme.Accent or theme.Secondary
    btn.BorderSizePixel = 0
    btn.Text = (TabIcons[name] or "") .. " " .. name
    btn.TextColor3 = theme.Text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 12
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    TabButtons[name] = btn
end

for i, name in ipairs(Tabs) do
    CreateTabButton(name, i)
    CreatePage(name)
end

local function SectionDivider(page, text)
    local theme = GetTheme()
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -6, 0, 6)
    l.BackgroundColor3 = theme.Accent
    l.BackgroundTransparency = 0.7
    l.BorderSizePixel = 0
    l.Text = ""
    l.ZIndex = 13
    l.Parent = Pages[page]
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 3)
end

local function Toggle(page, name, key)
    local theme = GetTheme()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 26)
    f.BackgroundColor3 = theme.Main
    f.BorderSizePixel = 0
    f.ZIndex = 13
    f.Parent = Pages[page]
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.7, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = theme.Text
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = f
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 36, 0, 18)
    b.Position = UDim2.new(1, -42, 0.5, -9)
    b.BorderSizePixel = 0
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 14
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local function upd()
        b.BackgroundColor3 = Config[key] and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(180, 40, 40)
        b.Text = Config[key] and "ON" or "OFF"
        b.TextColor3 = Color3.new(1,1,1)
    end
    upd()
    b.MouseButton1Click:Connect(function() Config[key] = not Config[key]; upd() end)
end

local function Dropdown(page, name, key, opts)
    local theme = GetTheme()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 26)
    f.BackgroundColor3 = theme.Main
    f.BorderSizePixel = 0
    f.ZIndex = 13
    f.Parent = Pages[page]
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.5, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = theme.Text
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = f
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 80, 0, 18)
    b.Position = UDim2.new(1, -86, 0.5, -9)
    b.BackgroundColor3 = theme.Secondary
    b.BorderSizePixel = 0
    b.Text = tostring(Config[key])
    b.TextColor3 = theme.Text
    b.TextSize = 10
    b.Font = Enum.Font.Gotham
    b.ZIndex = 14
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local idx = table.find(opts, Config[key]) or 1
    b.MouseButton1Click:Connect(function() idx = idx % #opts + 1; Config[key] = opts[idx]; b.Text = tostring(opts[idx]) end)
end

local function Slider(page, name, key, min, max)
    local theme = GetTheme()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 36)
    f.BackgroundColor3 = theme.Main
    f.BorderSizePixel = 0
    f.ZIndex = 13
    f.Parent = Pages[page]
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6, 0, 0, 14)
    l.Position = UDim2.new(0, 10, 0, 2)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = theme.Text
    l.TextSize = 10
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = f
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.3, 0, 0, 14)
    v.Position = UDim2.new(0.7, -8, 0, 2)
    v.BackgroundTransparency = 1
    v.Text = tostring(Config[key])
    v.TextColor3 = theme.TextDim
    v.TextSize = 10
    v.Font = Enum.Font.Gotham
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.ZIndex = 14
    v.Parent = f
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -16, 0, 6)
    bg.Position = UDim2.new(0, 8, 0, 22)
    bg.BackgroundColor3 = theme.Secondary
    bg.BorderSizePixel = 0
    bg.ZIndex = 14
    bg.Parent = f
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 3)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Config[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = theme.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 15
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
    local dragging = false
    bg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    bg.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    bg.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            Config[key], v.Text, fill.Size = val, tostring(val), UDim2.new(rel, 0, 1, 0)
        end
    end)
end

local WaitingForKey, KeybindButton = false, nil

local function Keybind(page, name, key)
    local theme = GetTheme()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 26)
    f.BackgroundColor3 = theme.Main
    f.BorderSizePixel = 0
    f.ZIndex = 13
    f.Parent = Pages[page]
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.5, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = theme.Text
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 14
    l.Parent = f
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 90, 0, 18)
    b.Position = UDim2.new(1, -96, 0.5, -9)
    b.BackgroundColor3 = theme.Secondary
    b.BorderSizePixel = 0
    b.Text = "[" .. Config[key] .. "]"
    b.TextColor3 = theme.Text
    b.TextSize = 9
    b.Font = Enum.Font.Gotham
    b.ZIndex = 14
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(function() WaitingForKey = true; KeybindButton = {btn = b, key = key}; b.Text = "[...]"; b.BackgroundColor3 = theme.Accent end)
    return b
end

local function Label(page, text)
    local theme = GetTheme()
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -6, 0, 22)
    l.BackgroundColor3 = theme.Accent
    l.BackgroundTransparency = 0.6
    l.BorderSizePixel = 0
    l.Text = text
    l.TextColor3 = theme.Text
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.ZIndex = 13
    l.Parent = Pages[page]
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 5)
    l:SetAttribute("IsLabel", true)
end

local function Button(page, text, callback)
    local theme = GetTheme()
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -6, 0, 26)
    b.BackgroundColor3 = theme.Accent
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 13
    b.Parent = Pages[page]
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.MouseButton1Click:Connect(callback)
end

-- ============================================
-- MENU SECTIONS
-- ============================================

-- AIMBOT TAB
Label("Aimbot", "🎯  AIMBOT")
Toggle("Aimbot", "Enabled", "AimbotEnabled")
Keybind("Aimbot", "Aim Key", "AimKey")
Dropdown("Aimbot", "Key Mode", "AimKeyMode", {"Hold", "Toggle"})
Dropdown("Aimbot", "Aim Mode", "AimMode", {"Legit", "Custom", "Rage"})
Dropdown("Aimbot", "Aim Method", "AimMethod", {"Camera", "Mouse"})
Toggle("Aimbot", "Snap Aim (LMB)", "SnapAim")
Toggle("Aimbot", "Target Lock", "TargetLock")
Dropdown("Aimbot", "Priority", "TargetPriority", {"FOV", "Distance", "Health"})
Slider("Aimbot", "FOV", "FOV", 10, 400)
Toggle("Aimbot", "Show FOV", "ShowFOV")
Slider("Aimbot", "Smoothness", "Smoothness", 1, 100)
Slider("Aimbot", "Speed", "AimSpeed", 1, 15)
Dropdown("Aimbot", "Aim Part", "AimPart", {"Head", "HumanoidRootPart"})
Toggle("Aimbot", "Team Check", "TeamCheck")
Toggle("Aimbot", "Wall Check", "WallCheck")
SectionDivider("Aimbot", "")
Label("Aimbot", "🎯  TRIGGERBOT")
Toggle("Aimbot", "Triggerbot Enabled", "TriggerbotEnabled")
Slider("Aimbot", "Triggerbot Delay (ms)", "TriggerbotDelay", 0, 200)

-- ESP TAB
Label("ESP", "👁  ESP")
Toggle("ESP", "ESP Enabled", "ESPEnabled")
Toggle("ESP", "Names", "ShowNames")
Toggle("ESP", "Health (text)", "ShowHealth")
Toggle("ESP", "Distance", "ShowDistance")
Toggle("ESP", "Tracers", "ShowTracers")
Toggle("ESP", "Snaplines", "ShowSnaplines")
Toggle("ESP", "Weapon Name", "ShowWeapon")
Toggle("ESP", "Visibility Check", "ShowVisibility")
SectionDivider("ESP", "")
Label("ESP", "👁  PERFORMANCE")
Slider("ESP", "Update Rate (frames)", "ESPUpdateRate", 1, 10)
Slider("ESP", "Max Distance", "MaxDistance", 100, 2000)

-- VISUALS TAB
Label("Visuals", "🎨  TARGET INFO")
Toggle("Visuals", "Target Info Enabled", "TargetInfoEnabled")

local DragPreview = Instance.new("Frame")
DragPreview.Size = UDim2.new(0, 180, 0, 60)
DragPreview.Position = UDim2.new(0, Config.TargetInfoX, 0, Config.TargetInfoY)
DragPreview.BackgroundColor3 = Color3.new(0, 0, 0)
DragPreview.BorderSizePixel = 2
DragPreview.BorderColor3 = Color3.fromRGB(255, 255, 255)
DragPreview.Visible = false
DragPreview.ZIndex = 5
DragPreview.Parent = Gui
local DragLabel = Instance.new("TextLabel")
DragLabel.Size = UDim2.new(1, 0, 1, 0)
DragLabel.BackgroundTransparency = 1
DragLabel.Text = "TARGET HUD\nDrag me!"
DragLabel.TextColor3 = Color3.new(1, 1, 1)
DragLabel.TextSize = 14
DragLabel.Font = Enum.Font.GothamBold
DragLabel.ZIndex = 6
DragLabel.Parent = DragPreview
local DragMode = false

UserInputService.InputChanged:Connect(function(input)
    if DragMode and input.UserInputType == Enum.UserInputType.MouseMovement then
        local newX = math.clamp(input.Position.X - 90, 0, Camera.ViewportSize.X - 180)
        local newY = math.clamp(input.Position.Y - 30, 0, Camera.ViewportSize.Y - 60)
        DragPreview.Position = UDim2.new(0, newX, 0, newY)
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if DragMode and input.UserInputType == Enum.UserInputType.MouseButton1 then
        Config.TargetInfoX = math.floor(DragPreview.AbsolutePosition.X)
        Config.TargetInfoY = math.floor(DragPreview.AbsolutePosition.Y)
        DragMode = false
        DragPreview.Visible = false
    end
end)

Button("Visuals", "Drag Target HUD", function()
    DragMode = not DragMode
    DragPreview.Visible = DragMode
    DragPreview.Position = UDim2.new(0, Config.TargetInfoX, 0, Config.TargetInfoY)
end)

-- INSTANT KILL TAB
Label("Instant Kill", "💀  INSTANT KILL")
Toggle("Instant Kill", "Instant Kill Enabled", "InstantKillEnabled")
Keybind("Instant Kill", "Instant Kill Key", "InstantKillKey")
Slider("Instant Kill", "Total Time (ms)", "InstantKillDelay", 0, 1000)
Slider("Instant Kill", "Distance (studs)", "InstantKillDistance", 1, 10)
Slider("Instant Kill", "Pre-Teleport Distance", "InstantKillPreTeleportDistance", 0, 50)
Slider("Instant Kill", "Pre-Attack %", "InstantKillPreAttackPercent", 0, 100)
Slider("Instant Kill", "Post-Attack %", "InstantKillPostAttackPercent", 0, 100)
Slider("Instant Kill", "Triggerbot Block (ms)", "InstantKillTriggerbotBlock", 0, 5000)

-- FRIENDS TAB
Label("Friends", "👥  FRIEND LIST")
local FriendListLabel = Instance.new("TextLabel")
FriendListLabel.Size = UDim2.new(1, -6, 0, 50)
FriendListLabel.BackgroundColor3 = GetTheme().Main
FriendListLabel.BorderSizePixel = 0
FriendListLabel.TextColor3 = GetTheme().TextDim
FriendListLabel.TextSize = 10
FriendListLabel.Font = Enum.Font.Gotham
FriendListLabel.TextWrapped = true
FriendListLabel.ZIndex = 13
FriendListLabel.Parent = Pages["Friends"]
FriendListLabel.Text = "Friends: " .. (#Config.FriendList > 0 and table.concat(Config.FriendList, ", ") or "None")
Instance.new("UICorner", FriendListLabel).CornerRadius = UDim.new(0, 5)

local function UpdateFriendList() FriendListLabel.Text = "Friends: " .. (#Config.FriendList > 0 and table.concat(Config.FriendList, ", ") or "None") end

Label("Friends", "👥  ADD FROM SERVER")

local function RefreshPlayerButtons()
    for _, child in ipairs(Pages["Friends"]:GetChildren()) do if child:GetAttribute("PlayerButton") then child:Destroy() end end
    local theme = GetTheme()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local isFriend = table.find(Config.FriendList, player.Name)
            local btn = Instance.new("TextButton")
            btn:SetAttribute("PlayerButton", true)
            btn.Size = UDim2.new(1, -6, 0, 26)
            btn.BackgroundColor3 = isFriend and Color3.fromRGB(40, 160, 70) or theme.Main
            btn.BorderSizePixel = 0
            btn.TextColor3 = theme.Text
            btn.TextSize = 10
            btn.Font = Enum.Font.Gotham
            btn.ZIndex = 13
            btn.Parent = Pages["Friends"]
            btn.Text = player.DisplayName .. " (@" .. player.Name .. ")" .. (isFriend and " ✓" or "")
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
            btn.MouseButton1Click:Connect(function()
                local idx = table.find(Config.FriendList, player.Name)
                if idx then
                    table.remove(Config.FriendList, idx)
                    btn.BackgroundColor3 = theme.Main
                    btn.Text = player.DisplayName .. " (@" .. player.Name .. ")"
                else
                    table.insert(Config.FriendList, player.Name)
                    btn.BackgroundColor3 = Color3.fromRGB(40, 160, 70)
                    btn.Text = player.DisplayName .. " (@" .. player.Name .. ") ✓"
                end
                UpdateFriendList()
            end)
        end
    end
end

Button("Friends", "Refresh Players", function() RefreshPlayerButtons() end)
Button("Friends", "Clear All Friends", function() Config.FriendList = {}; UpdateFriendList(); RefreshPlayerButtons() end)
RefreshPlayerButtons()

-- CONFIG TAB
Label("Config", "💾  CONFIGS")
local ConfigList = Instance.new("TextLabel")
ConfigList.Size = UDim2.new(1, -6, 0, 60)
ConfigList.BackgroundColor3 = GetTheme().Main
ConfigList.BorderSizePixel = 0
ConfigList.TextColor3 = GetTheme().TextDim
ConfigList.TextSize = 10
ConfigList.Font = Enum.Font.Gotham
ConfigList.TextWrapped = true
ConfigList.ZIndex = 13
ConfigList.Parent = Pages["Config"]
ConfigList.Text = "Configs: " .. table.concat(GetConfigs(), ", ")
Instance.new("UICorner", ConfigList).CornerRadius = UDim.new(0, 5)

local ConfigInput = Instance.new("TextBox")
ConfigInput.Size = UDim2.new(1, -6, 0, 26)
ConfigInput.BackgroundColor3 = GetTheme().Main
ConfigInput.BorderSizePixel = 0
ConfigInput.Text = CurrentConfigName
ConfigInput.PlaceholderText = "Config name..."
ConfigInput.TextColor3 = GetTheme().Text
ConfigInput.TextSize = 11
ConfigInput.Font = Enum.Font.Gotham
ConfigInput.ZIndex = 13
ConfigInput.Parent = Pages["Config"]
Instance.new("UICorner", ConfigInput).CornerRadius = UDim.new(0, 5)

Button("Config", "Save Config", function()
    local name = ConfigInput.Text ~= "" and ConfigInput.Text or "default"
    SaveConfig(name)
    ConfigList.Text = "Configs: " .. table.concat(GetConfigs(), ", ")
end)
Button("Config", "Load Config", function()
    local name = ConfigInput.Text ~= "" and ConfigInput.Text or "default"
    if LoadConfig(name) then ApplyTheme() end
end)
Button("Config", "Delete Config", function()
    local name = ConfigInput.Text
    if name ~= "" then
        DeleteConfig(name)
        ConfigList.Text = "Configs: " .. table.concat(GetConfigs(), ", ")
    end
end)
Button("Config", "Copy Folder Path", function() OpenConfigFolder() end)

-- THEME TAB
Label("Theme", "🎭  MENU THEME")
Dropdown("Theme", "Theme", "MenuTheme", {"Dark", "Purple", "Red", "Blue", "Green"})
Button("Theme", "Apply Theme", function() ApplyTheme() end)
SectionDivider("Theme", "")
Label("Theme", "🎭  ESP COLORS")
Button("Theme", "Box: Red", function() Config.BoxColor = {255, 50, 50} end)
Button("Theme", "Box: Green", function() Config.BoxColor = {50, 255, 50} end)
Button("Theme", "Box: Blue", function() Config.BoxColor = {50, 100, 255} end)
Button("Theme", "Box: Purple", function() Config.BoxColor = {150, 50, 255} end)
Button("Theme", "Box: White", function() Config.BoxColor = {255, 255, 255} end)
Button("Theme", "Box: Cyan", function() Config.BoxColor = {50, 255, 255} end)
Button("Theme", "Box: Pink", function() Config.BoxColor = {255, 100, 200} end)

-- OTHER TAB
Label("Other", "⚙  ANTI EFFECTS")
Toggle("Other", "Anti Smoke", "AntiSmoke")
Toggle("Other", "Anti Flash", "AntiFlash")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
PlayerGui.ChildAdded:Connect(function(child)
    if Config.AntiFlash and child.Name == "FlashbangGui" then
        local bg = child:WaitForChild("Background", 1)
        if bg then bg.Parent = nil end
    end
end)

Lighting.ChildAdded:Connect(function(child)
    if Config.AntiFlash and child.Name == "Flashbang" then
        child.Enabled = false
    end
end)

SectionDivider("Other", "")
Label("Other", "⚙  MOVEMENT")
Toggle("Other", "Slide Speed", "SlideSpeed")
Slider("Other", "Slide Boost", "SlideBoost", 10, 100)

SectionDivider("Other", "")
Label("Other", "⚙  NO SPREAD")
Toggle("Other", "No Spread Enabled", "NoSpreadEnabled")
Keybind("Other", "NoSpread Toggle Key", "NoSpreadKey")
Toggle("Other", "Auto Refresh (5 sec)", "NoSpreadAutoRefresh")
Keybind("Other", "Manual Refresh Key", "NoSpreadRefreshKey")

SectionDivider("Other", "")
-- ============================================
-- GAME SYSTEMS
-- ============================================

local function SetupSlideSpeed(char)
    if not char then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    hrp.ChildAdded:Connect(function(child)
        if not Config.SlideSpeed then return end
        if child:IsA("BodyVelocity") and child.MaxForce.X < 10000 then
            local look = Camera.CFrame.LookVector
            local direction = Vector3.new(look.X, 0, look.Z).Unit
            local boostedVel = direction * Config.SlideBoost
            child.Velocity = Vector3.new(boostedVel.X + child.Velocity.X, child.Velocity.Y, boostedVel.Z + child.Velocity.Z)
            local conn
            conn = RunService.RenderStepped:Connect(function()
                if not child or not child.Parent then conn:Disconnect(); return end
                local currentVel = child.Velocity
                if currentVel.Magnitude > 3 then
                    local dir = Vector3.new(currentVel.X, 0, currentVel.Z).Unit
                    child.Velocity = Vector3.new(dir.X * Config.SlideBoost + currentVel.X * 0.5, currentVel.Y, dir.Z * Config.SlideBoost + currentVel.Z * 0.5)
                end
            end)
            child.Destroying:Connect(function() if conn then conn:Disconnect() end end)
        end
    end)
end

if LocalPlayer.Character then SetupSlideSpeed(LocalPlayer.Character) end
table.insert(_G.RivalsConnections, LocalPlayer.CharacterAdded:Connect(SetupSlideSpeed))

workspace.ChildAdded:Connect(function(obj)
    if Config.AntiSmoke and obj.Name == "Smoke Grenade" then
        task.wait()
        obj:Destroy()
    end
end)

ApplyTheme()

-- ============================================
-- AIMBOT TARGETING
-- ============================================

local function IsValidTarget(p)
    if not p or p == LocalPlayer or IsTeammate(p) or IsFriend(p) then return false end
    local char = p.Character
    if not char then return false end
    local part = char:FindFirstChild(Config.AimPart)
    local hum = char:FindFirstChild("Humanoid")
    if not part or not hum or hum.Health <= 0 then return false end

    if Config.AimMethod == "Camera" then
        if CachedMyRoot then
            local dist = (part.Position - CachedMyRoot.Position).Magnitude
            if dist > Config.MaxDistance then return false end
        end
        if Config.WallCheck and not IsVisible(part) then return false end
        return true
    else
        local pos, vis = Camera:WorldToViewportPoint(part.Position)
        if not vis then return false end
        local mouse = UserInputService:GetMouseLocation()
        local screenPos = Vector2.new(pos.X, pos.Y)
        if (mouse - screenPos).Magnitude > Config.FOV then return false end
        if Config.WallCheck and not IsVisible(part) then return false end
        return true
    end
end

local function GetTarget()
    if Config.TargetLock and LockedTarget and IsValidTarget(LockedTarget) then return LockedTarget end
    local best, bestValue = nil, math.huge
    local mouse = UserInputService:GetMouseLocation()

    if not CachedMyRoot and Config.AimMethod ~= "Camera" then return nil end

    for _, p in ipairs(CachedPlayers) do
        if p ~= LocalPlayer and not IsTeammate(p) and not IsFriend(p) then
            local char = p.Character
            if char then
                local part = char:FindFirstChild(Config.AimPart)
                local hum = char:FindFirstChild("Humanoid")
                if part and hum and hum.Health > 0 then
                    if Config.AimMethod == "Camera" then
                        if CachedMyRoot then
                            local dist = (part.Position - CachedMyRoot.Position).Magnitude
                            if dist <= Config.MaxDistance then
                                if not (Config.WallCheck and not IsVisible(part)) then
                                    local value = dist
                                    if Config.TargetPriority == "Health" then value = hum.Health end
                                    if value < bestValue then bestValue = value; best = p end
                                end
                            end
                        end
                    else
                        local pos, vis = Camera:WorldToViewportPoint(part.Position)
                        if vis then
                            local screenPos = Vector2.new(pos.X, pos.Y)
                            local fovDist = (mouse - screenPos).Magnitude
                            if fovDist <= Config.FOV then
                                if not (Config.WallCheck and not IsVisible(part)) then
                                    local value = fovDist
                                    if Config.TargetPriority == "Health" then value = hum.Health
                                    elseif Config.TargetPriority == "Distance" and CachedMyRoot then value = (part.Position - CachedMyRoot.Position).Magnitude end
                                    if value < bestValue then bestValue = value; best = p end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ============================================
-- TRIGGERBOT
-- ============================================

local LastTriggerTime = 0
local TriggerCounter = 0
local TriggerbotBlockUntil = 0

local function Triggerbot()
    if not Config.TriggerbotEnabled then return end
    if tick() < TriggerbotBlockUntil then return end
    TriggerCounter = TriggerCounter + 1
    if TriggerCounter < 3 then return end
    TriggerCounter = 0
    if tick() - LastTriggerTime < Config.TriggerbotDelay * 0.001 then return end
    local mouse = UserInputService:GetMouseLocation()
    for _, p in ipairs(CachedPlayers) do
        if p ~= LocalPlayer and not IsTeammate(p) and not IsFriend(p) then
            local char = p.Character
            if char then
                local head = char:FindFirstChild("Head")
                local torso = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                if head and torso and hum and hum.Health > 0 then
                    local headPos = Camera:WorldToViewportPoint(head.Position)
                    local torsoPos = Camera:WorldToViewportPoint(torso.Position)
                    if headPos.Z > 0 and torsoPos.Z > 0 then
                        local minX = math.min(headPos.X, torsoPos.X) - 30
                        local maxX = math.max(headPos.X, torsoPos.X) + 30
                        local minY = math.min(headPos.Y, torsoPos.Y) - 10
                        local maxY = math.max(headPos.Y, torsoPos.Y) + 10
                        if mouse.X >= minX and mouse.X <= maxX and mouse.Y >= minY and mouse.Y <= maxY then
                            if IsVisible(torso) then
                                mouse1click()
                                LastTriggerTime = tick()
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

_G.RivalsESP = ESPCache

-- ============================================
-- NO SPREAD SYSTEM
-- ============================================

local NoSpreadActive = false
local NoSpreadConnection = nil
local OriginalCameraFOV = nil
local ItemInterfacesBackup = nil
local NoSpreadToggleCounter = 0

local function NoSpreadRefresh()
    if not NoSpreadActive then return end
    print("[NoSpread] Refreshing aim mode...")
    mouse2release()
    task.wait(0.05)
    mouse2press()
    NoSpreadToggleCounter = 0
    print("[NoSpread] Refresh complete")
end

local function NoSpreadStart()
    if NoSpreadActive then return end
    NoSpreadActive = true
    print("[NoSpread] Activated")
    OriginalCameraFOV = Camera.FieldOfView
    local myChar = LocalPlayer.Character
    if not myChar then NoSpreadActive = false; return end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local mainGui = playerGui:FindFirstChild("MainGui")
        if mainGui then
            local mainFrame = mainGui:FindFirstChild("MainFrame")
            if mainFrame then
                local itemInterfaces = mainFrame:FindFirstChild("ItemInterfaces")
                if itemInterfaces then
                    ItemInterfacesBackup = itemInterfaces
                    itemInterfaces.Parent = nil
                    print("[NoSpread] ItemInterfaces removed")
                end
            end
        end
    end
    mouse2press()
    NoSpreadConnection = RunService.RenderStepped:Connect(function()
        if not NoSpreadActive then return end
        if Camera.FieldOfView ~= OriginalCameraFOV then
            Camera.FieldOfView = OriginalCameraFOV
        end
        if Config.NoSpreadAutoRefresh then
            NoSpreadToggleCounter = NoSpreadToggleCounter + 1
            if NoSpreadToggleCounter >= 300 then
                NoSpreadToggleCounter = 0
                mouse2release()
                task.wait(0.05)
                mouse2press()
                print("[NoSpread] Auto-refresh")
            end
        end
    end)
end

local function NoSpreadStop()
    if not NoSpreadActive then return end
    NoSpreadActive = false
    print("[NoSpread] Deactivated")
    if NoSpreadConnection then NoSpreadConnection:Disconnect(); NoSpreadConnection = nil end
    NoSpreadToggleCounter = 0
    mouse2release()
    if ItemInterfacesBackup then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local mainGui = playerGui:FindFirstChild("MainGui")
            if mainGui then
                local mainFrame = mainGui:FindFirstChild("MainFrame")
                if mainFrame then
                    ItemInterfacesBackup.Parent = mainFrame
                    print("[NoSpread] ItemInterfaces restored")
                end
            end
        end
        ItemInterfacesBackup = nil
    end
    if OriginalCameraFOV then Camera.FieldOfView = OriginalCameraFOV end
end

-- ============================================
-- INSTANT KILL SYSTEM
-- ============================================

local InstantKillCooldown = false

local function GetNearestEnemy()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local myPos = myRoot.Position
    local best, bestDist = nil, math.huge
    for _, p in ipairs(CachedPlayers) do
        if p ~= LocalPlayer and not IsTeammate(p) and not IsFriend(p) then
            local char = p.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local dist = (myPos - root.Position).Magnitude
                    if dist < bestDist then bestDist = dist; best = {character = char, player = p, distance = dist} end
                end
            end
        end
    end
    return best
end

local function DoInstantKill()
    if InstantKillCooldown then return end
    if not Config.InstantKillEnabled then return end
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local targetData = GetNearestEnemy()
    if not targetData then return end
    local target = targetData.character
    local targetHead = target:FindFirstChild("Head")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not targetHead or not targetRoot then return end
    local targetHum = target:FindFirstChild("Humanoid")
    if not targetHum or targetHum.Health <= 0 then return end

    InstantKillCooldown = true
    TriggerbotBlockUntil = tick() + (Config.InstantKillTriggerbotBlock / 1000)

    print(string.format("[InstantKill] Executing on %s (%.1f studs)", targetData.player.Name, targetData.distance))

    local savedPos = myRoot.CFrame
    local savedCamCF = Camera.CFrame
    local myHum = myChar:FindFirstChild("Humanoid")
    local savedAutoRotate = myHum and myHum.AutoRotate or true

    -- Disable AutoRotate so humanoid doesn't fight our rotation
    if myHum then myHum.AutoRotate = false end
    -- Zero out angular velocity so physics doesn't spin us
    myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

    -- Helper: set our position AND copy target's facing direction
    local function FaceSameAsTarget(position)
        local targetLook = targetRoot.CFrame.LookVector
        myRoot.CFrame = CFrame.new(position, position + targetLook)
    end

    -- Pre-teleport: move in front of target, face same direction as target
    if Config.InstantKillPreTeleportDistance > 0 then
        local lookVector = targetRoot.CFrame.LookVector
        local prePos = targetRoot.Position + lookVector * Config.InstantKillPreTeleportDistance
        FaceSameAsTarget(prePos)
        task.wait(0.05)
    end

    -- Teleport behind target, facing same direction as target
    local targetLook = targetRoot.CFrame.LookVector
    local behindOffset = -targetLook * Config.InstantKillDistance
    local behindPos = targetRoot.Position + behindOffset
    FaceSameAsTarget(behindPos)

    -- Lock camera on target head, keep character facing same direction as target every frame
    local lockConn
    lockConn = RunService.RenderStepped:Connect(function()
        if not targetHead.Parent or not targetRoot.Parent then return end
        local curLook = targetRoot.CFrame.LookVector
        local curBehind = targetRoot.Position + (-curLook * Config.InstantKillDistance)
        FaceSameAsTarget(curBehind)
        -- Force zero angular velocity every frame
        myRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        local myHead = myChar:FindFirstChild("Head")
        if myHead then Camera.CFrame = CFrame.new(myHead.Position, targetHead.Position) end
    end)

    -- Timing
    local totalTime = Config.InstantKillDelay / 1000
    local preTime = totalTime * (Config.InstantKillPreAttackPercent / 100)
    local postTime = totalTime * (Config.InstantKillPostAttackPercent / 100)

    RunService.RenderStepped:Wait()
    if preTime > 0 then task.wait(preTime) end

    mouse2press()
    task.wait(0.05)
    mouse1click()
    if postTime > 0 then task.wait(postTime) end
    mouse2release()

    -- Return
    myRoot.CFrame = savedPos
    Camera.CFrame = savedCamCF
    if lockConn then lockConn:Disconnect() end
    -- Restore AutoRotate
    if myHum then myHum.AutoRotate = savedAutoRotate end

    print("[InstantKill] Complete, returned to position")
    task.delay(0.5, function() InstantKillCooldown = false end)
end


-- ============================================
-- MAIN RENDER LOOP
-- ============================================

table.insert(_G.RivalsConnections, RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    CachedMyRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    PlayerListUpdateCounter = PlayerListUpdateCounter + 1
    if PlayerListUpdateCounter >= 30 then
        PlayerListUpdateCounter = 0
        CachedPlayers = Players:GetPlayers()
    end

    -- FOV Circle
    if Config.ShowFOV and Config.AimbotEnabled then
        if Config.WallCheck then
            FOVCircle.Color = Color3.fromRGB(255, 150, 50)
        else
            FOVCircle.Color = C3(Config.FOVColor)
        end
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Config.FOV
        FOVCircle.Visible = (Config.AimMethod ~= "Camera")
    else
        FOVCircle.Visible = false
    end

    -- Aimbot
    local active = (Config.AimKeyMode == "Hold" and Aiming) or (Config.AimKeyMode == "Toggle" and AimToggled)
    local currentTarget = nil

    if Config.AimbotEnabled and active then
        local t = GetTarget()
        if t then
            if Config.TargetLock then LockedTarget = t end
            currentTarget = t
            local char = t.Character
            if char then
                local part = char:FindFirstChild(Config.AimPart)
                if part then
                    local targetPos = part.Position
                    local camPos = Camera.CFrame.Position

                    if Config.AimMethod == "Camera" then
                        if Config.AimMode == "Rage" then
                            Camera.CFrame = CFrame.new(camPos, targetPos)
                        else
                            local speed = Config.AimMode == "Legit" and 0.1 or (Config.Smoothness * 0.01) * (Config.AimSpeed * 0.1)
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, targetPos), math.clamp(speed, 0.05, 1))
                        end
                    else
                        local pos, onScreen = Camera:WorldToViewportPoint(targetPos)
                        if onScreen then
                            local mouse = UserInputService:GetMouseLocation()
                            local screenPos = Vector2.new(pos.X, pos.Y)
                            local delta = screenPos - mouse
                            if delta.Magnitude <= Config.FOV then
                                local moveX, moveY
                                if Config.AimMode == "Rage" then
                                    moveX, moveY = delta.X, delta.Y
                                elseif Config.AimMode == "Legit" then
                                    moveX, moveY = delta.X * 0.15, delta.Y * 0.15
                                else
                                    local smoothFactor = math.max(0.01, 1 - (Config.Smoothness * 0.01))
                                    local speedFactor = Config.AimSpeed * 0.1
                                    local finalSpeed = smoothFactor * speedFactor
                                    moveX, moveY = delta.X * finalSpeed, delta.Y * finalSpeed
                                end
                                if math.abs(moveX) > math.abs(delta.X) then moveX = delta.X end
                                if math.abs(moveY) > math.abs(delta.Y) then moveY = delta.Y end
                                if mousemoverel then
                                    mousemoverel(moveX, moveY)
                                elseif mousemoveabs then
                                    mousemoveabs(mouse.X + moveX, mouse.Y + moveY)
                                else
                                    if Config.AimMode == "Rage" then
                                        Camera.CFrame = CFrame.new(camPos, targetPos)
                                    else
                                        local speed = Config.AimMode == "Legit" and 0.1 or (Config.Smoothness * 0.01) * (Config.AimSpeed * 0.1)
                                        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, targetPos), math.clamp(speed, 0.05, 1))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        LockedTarget = nil
    end

    UpdateTargetInfo(currentTarget or LockedTarget)
    UpdateSnapAim()
    Triggerbot()

    -- ESP
    ESPUpdateCounter = ESPUpdateCounter + 1
    if ESPUpdateCounter >= Config.ESPUpdateRate then
        ESPUpdateCounter = 0
        if Config.ESPEnabled then
            for p, e in pairs(ESPCache) do
                local ok, err = pcall(function() UpdateESP(p, e) end)
                if not ok then
                    HideESP(e)
                end
            end
        else
            for _, e in pairs(ESPCache) do
                HideESP(e)
            end
        end
    end
end))

-- ============================================
-- INPUT HANDLING
-- ============================================

table.insert(_G.RivalsConnections, UserInputService.InputBegan:Connect(function(input, gp)
    -- Menu toggle: Right Shift
    if input.KeyCode == Enum.KeyCode.RightShift then
        MenuOpen = not MenuOpen
        Main.Visible = MenuOpen
        MenuOverlay.Visible = MenuOpen
        return
    end
    -- Right Shift opens menu
    if input.KeyCode == Enum.KeyCode.RightShift then
        MenuOpen = not MenuOpen
        Main.Visible = MenuOpen
        MenuOverlay.Visible = MenuOpen
        return
    end

    if WaitingForKey and KeybindButton then
        local keyName
        if input.UserInputType == Enum.UserInputType.MouseButton1 then keyName = "MouseButton1"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then keyName = "MouseButton2"
        elseif input.KeyCode ~= Enum.KeyCode.Unknown then keyName = input.KeyCode.Name end
        if keyName then
            Config[KeybindButton.key] = keyName
            KeybindButton.btn.Text = "[" .. keyName .. "]"
            KeybindButton.btn.BackgroundColor3 = GetTheme().Secondary
            WaitingForKey, KeybindButton = false, nil
        end
        return
    end
    if gp then return end

    -- Snap Aim on LMB hold
    if Config.SnapAim and Config.AimbotEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        StartSnapAim()
    end

    -- Instant Kill
    local instantKillKey = StringToKey(Config.InstantKillKey)
    if input.KeyCode == instantKillKey or input.UserInputType == instantKillKey then
        DoInstantKill()
    end

    -- NoSpread Toggle
    local noSpreadKey = StringToKey(Config.NoSpreadKey)
    if input.KeyCode == noSpreadKey or input.UserInputType == noSpreadKey then
        if Config.NoSpreadEnabled then
            if NoSpreadActive then NoSpreadStop() else NoSpreadStart() end
        end
    end

    -- NoSpread Manual Refresh
    if not Config.NoSpreadAutoRefresh then
        local refreshKey = StringToKey(Config.NoSpreadRefreshKey)
        if input.KeyCode == refreshKey or input.UserInputType == refreshKey then
            if Config.NoSpreadEnabled and NoSpreadActive then NoSpreadRefresh() end
        end
    end

    -- Aim key
    local key = StringToKey(Config.AimKey)
    if input.KeyCode == key or input.UserInputType == key then
        if Config.AimKeyMode == "Hold" then Aiming = true else AimToggled = not AimToggled end
    end
end))

table.insert(_G.RivalsConnections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then StopSnapAim() end
    local key = StringToKey(Config.AimKey)
    if (input.KeyCode == key or input.UserInputType == key) and Config.AimKeyMode == "Hold" then Aiming = false end
end))

-- ============================================
-- ESP PLAYER TRACKING
-- ============================================

CachedPlayers = Players:GetPlayers()
for _, p in ipairs(CachedPlayers) do if p ~= LocalPlayer then CreateESP(p) end end
table.insert(_G.RivalsConnections, Players.PlayerAdded:Connect(function(p) CreateESP(p); CachedPlayers = Players:GetPlayers() end))
table.insert(_G.RivalsConnections, Players.PlayerRemoving:Connect(function(p) RemoveESP(p); CachedPlayers = Players:GetPlayers() end))

-- ============================================
-- STARTUP PRINTS
-- ============================================

print("[Rivals] RIGHT SHIFT - menu")
print("[Rivals] Configs: " .. ConfigFolder)
print("[Rivals] mousemoverel: " .. (mousemoverel and "AVAILABLE" or "NOT AVAILABLE - Use Camera method"))
print("[Rivals] hookmetamethod: " .. (hookmetamethod and "YES" or "NO"))
print("[Rivals] Camera Aim Method = 360 degree targeting")
print("[Rivals] Instant Kill: Press " .. Config.InstantKillKey .. " | Triggerbot block after: " .. Config.InstantKillTriggerbotBlock .. "ms")
print("[Rivals] NoSpread: Press " .. Config.NoSpreadKey .. " to toggle | Auto-refresh: " .. (Config.NoSpreadAutoRefresh and "ON (5 sec)" or "OFF - Use " .. Config.NoSpreadRefreshKey .. " to refresh"))
if not mousemoverel then
    warn("[Rivals] WARNING: Mouse Aimbot and Snap Aim will not work without mousemoverel!")
    warn("[Rivals] Please use Camera method instead or use a different executor")
end
