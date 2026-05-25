--[[
    StarMenu.lua  —  Caves 2 Hub v9 интегрирован в звёздное меню
    -----------------------------------------------------------------
    Сохранено: звёздный фон, тонирование, виньетка, падающие звёзды,
               линии от звёзд к курсору (исправленные), Right Shift
               открывает/закрывает меню с плавной анимацией.
    Внутри панели: C2Hub (Points + Perfect Hit, MARK, T = TP item, P).
--]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService        = game:GetService("GuiService")
local W                 = game:GetService("Workspace")

local lplr  = Players.LocalPlayer
local Mouse = lplr:GetMouse()

-- GUI container (executor-aware)
local playerGui
do
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then
        playerGui = hui
    else
        local ok2, h2 = pcall(function() return game:GetService("CoreGui") end)
        playerGui = (ok2 and h2) or lplr:WaitForChild("PlayerGui")
    end
end

local function notify(t, txt, d)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = t or "", Text = txt or "", Duration = d or 3})
    end)
end

-- ===== Perfect Hit hook =====
local phOn = false
local idLvl = (syn and syn.get_thread_identity and syn.get_thread_identity())
           or (getidentity and getidentity()) or 3
local exploitOk = idLvl >= 4

if exploitOk then
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNC = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = function(self, ...)
            local mn = getnamecallmethod()
            local a = {...}
            if phOn and mn == "FireServer" and tostring(self) == "Attack" then
                if type(a[1]) == "table" then
                    a[1].Alpha = 1
                    a[1].ResponseTime = 0
                end
                return oldNC(self, table.unpack(a))
            end
            return oldNC(self, ...)
        end
        setreadonly(mt, true)
    end)
end

-- ===== Item TP via _Grab =====
local grabFolder
pcall(function() grabFolder = W:WaitForChild("Grab", 5) end)

local function findGrabModel()
    if not grabFolder then return nil end
    for _, p in ipairs(grabFolder:GetDescendants()) do
        if p.Name == "_Grab" then
            local c = p
            while c.Parent do
                c = c.Parent
                if c:IsA("Model") then return c end
            end
        end
    end
    return nil
end

local function tpPlayerTo(target)
    if not target then return end
    local hrp = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = target end
end

local function tpItemTo(targetCFrame)
    local m = findGrabModel()
    if not m then notify("", "No held item!", 2); return end
    if not m.PrimaryPart then
        local fp = m:FindFirstChildWhichIsA("BasePart")
        if fp then m.PrimaryPart = fp else notify("", "No BasePart", 2); return end
    end
    local hrp = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local startPos = hrp.CFrame
    local endPos = targetCFrame + Vector3.new(0, 3, 0)
    local steps, delay = 8, 0.04
    for i = 1, steps do
        local alpha = i / steps
        local t = alpha * alpha * (3 - 2 * alpha)
        local pos = startPos:Lerp(endPos, t)
        m:SetPrimaryPartCFrame(pos - Vector3.new(0, 3, 0))
        hrp.CFrame = pos
        task.wait(delay)
    end
    task.wait(0.08)
    local retStart = hrp.CFrame
    local retSteps = 6
    for i = 1, retSteps do
        local alpha = i / retSteps
        local t = alpha * alpha * (3 - 2 * alpha)
        hrp.CFrame = retStart:Lerp(startPos, t)
        task.wait(0.03)
    end
end

-- ===== Mark + Points =====
local markedPoint = nil
local ptsFolder = W:FindFirstChild("C2Hub_Pts")
if not ptsFolder then
    ptsFolder = Instance.new("Folder")
    ptsFolder.Name = "C2Hub_Pts"
    ptsFolder.Parent = W
end

local function mkPoint(nm)
    local p = Instance.new("Part")
    p.Name = nm or ("Point " .. (#ptsFolder:GetChildren() + 1))
    p.Anchored = true
    p.CanCollide = false
    p.Transparency = 0.5
    p.Color = Color3.fromRGB(0, 130, 255)
    p.Material = Enum.Material.Neon
    p.Size = Vector3.new(2, 0.2, 2)
    Instance.new("CylinderMesh").Parent = p
    p.Parent = ptsFolder
    return p
end

local function savePts()
    local d = {}
    for _, p in ipairs(ptsFolder:GetChildren()) do
        table.insert(d, {
            Name = p.Name,
            Pos = {p.Position.X, p.Position.Y, p.Position.Z},
            Col = {p.Color.R, p.Color.G, p.Color.B},
        })
    end
    pcall(function() writefile("c2hub_pts.json", HttpService:JSONEncode(d)) end)
end

local function loadPts()
    local ok, r = pcall(function() return readfile("c2hub_pts.json") end)
    if not ok then return end
    local ok2, pd = pcall(function() return HttpService:JSONDecode(r) end)
    if not ok2 then return end
    for _, p in ipairs(ptsFolder:GetChildren()) do p:Destroy() end
    for _, d in ipairs(pd) do
        local p = mkPoint(d.Name)
        if type(d.Pos) == "table" and type(d.Pos[1]) == "number" then
            p.Position = Vector3.new(d.Pos[1], d.Pos[2], d.Pos[3])
        end
        if type(d.Col) == "table" and type(d.Col[1]) == "number" then
            p.Color = Color3.new(d.Col[1], d.Col[2], d.Col[3])
        end
    end
end

--==================================================================
-- НАСТРОЙКИ И ПАЛИТРА
--==================================================================
local CONFIG = {
    STAR_COUNT            = 110,
    STAR_MIN_SIZE         = 1.5,
    STAR_MAX_SIZE         = 5,
    STAR_MIN_SPEED        = 6,
    STAR_MAX_SPEED        = 26,
    TWINKLE_MIN           = 0.25,
    TWINKLE_MAX           = 1.0,
    TWINKLE_SPEED_MIN     = 0.6,
    TWINKLE_SPEED_MAX     = 2.6,
    SHOOTING_INTERVAL_MIN = 4.0,
    SHOOTING_INTERVAL_MAX = 9.0,
    SHOOTING_SPEED        = 1400,
    CURSOR_RADIUS         = 150,
    LINE_THICKNESS        = 1.2,
    MENU_TINT_TRANSP      = 0.22,
    MENU_BG_TRANSP        = 0.05,
    MENU_SIZE             = Vector2.new(520, 600),
    OPEN_KEY              = Enum.KeyCode.RightShift,
    TWEEN_TIME            = 0.45,
}

local BG     = Color3.fromRGB(16, 18, 28)
local SEC    = Color3.fromRGB(22, 25, 38)
local CARD   = Color3.fromRGB(30, 34, 50)
local HOVER  = Color3.fromRGB(42, 48, 65)
local ACCENT = Color3.fromRGB(0, 130, 255)
local TXT    = Color3.fromRGB(230, 235, 248)
local DIM    = Color3.fromRGB(110, 118, 138)
local OKC    = Color3.fromRGB(40, 200, 100)
local ERRC   = Color3.fromRGB(230, 60, 60)

local rand = Random.new()
local STAR_PALETTE = {
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(200, 220, 255),
    Color3.fromRGB(255, 235, 210),
    Color3.fromRGB(220, 200, 255),
    Color3.fromRGB(180, 240, 255),
    Color3.fromRGB(255, 210, 230),
    Color3.fromRGB(255, 255, 200),
}
local function pickStarColor()
    return STAR_PALETTE[rand:NextInteger(1, #STAR_PALETTE)]
end

local function mkC(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

--==================================================================
-- ScreenGui + СЛОИ ФОНА
--==================================================================
if playerGui:FindFirstChild("StarMenuGui") then playerGui:FindFirstChild("StarMenuGui"):Destroy() end
if playerGui:FindFirstChild("C2Hub")        then playerGui:FindFirstChild("C2Hub"):Destroy()        end

local SG = Instance.new("ScreenGui")
SG.Name = "StarMenuGui"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 50
SG.Enabled = false
SG.Parent = playerGui

-- Тонирование (затемнение всего экрана + цветной градиент)
local tint = Instance.new("Frame")
tint.Name = "Tint"
tint.Size = UDim2.fromScale(1, 1)
tint.BackgroundColor3 = Color3.fromRGB(5, 6, 14)
tint.BackgroundTransparency = 1
tint.BorderSizePixel = 0
tint.ZIndex = 1
tint.Parent = SG

local tintGradient = Instance.new("UIGradient")
tintGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(28, 18, 55)),
    ColorSequenceKeypoint.new(0.45, Color3.fromRGB(10, 10, 28)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(2, 2, 8)),
})
tintGradient.Rotation = 90
tintGradient.Parent = tint

-- Виньетка
local vignette = Instance.new("ImageLabel")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.Image = "rbxasset://textures/ui/Controls/RadialGradient.png"
vignette.ScaleType = Enum.ScaleType.Stretch
vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
vignette.ImageTransparency = 1
vignette.ZIndex = 2
vignette.Parent = SG

-- Звёзды + линии
local starLayer = Instance.new("Frame")
starLayer.Name = "StarLayer"
starLayer.Size = UDim2.fromScale(1, 1)
starLayer.BackgroundTransparency = 1
starLayer.BorderSizePixel = 0
starLayer.ZIndex = 3
starLayer.Parent = SG

-- Падающие звёзды
local shootLayer = Instance.new("Frame")
shootLayer.Name = "ShootLayer"
shootLayer.Size = UDim2.fromScale(1, 1)
shootLayer.BackgroundTransparency = 1
shootLayer.BorderSizePixel = 0
shootLayer.ZIndex = 4
shootLayer.Parent = SG

--==================================================================
-- MENU SHELL (внутренние декорации удалены — внутрь идёт C2Hub)
--==================================================================
local menuHolder = Instance.new("Frame")
menuHolder.Name = "MenuHolder"
menuHolder.AnchorPoint = Vector2.new(0.5, 0.5)
menuHolder.Position = UDim2.fromScale(0.5, 0.5)
menuHolder.Size = UDim2.fromOffset(CONFIG.MENU_SIZE.X, CONFIG.MENU_SIZE.Y)
menuHolder.BackgroundTransparency = 1
menuHolder.BorderSizePixel = 0
menuHolder.ZIndex = 10
menuHolder.Parent = SG

local glow = Instance.new("ImageLabel")
glow.Name = "Glow"
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.5)
glow.Size = UDim2.new(1, 220, 1, 220)
glow.BackgroundTransparency = 1
glow.BorderSizePixel = 0
glow.Image = "rbxasset://textures/ui/Controls/RadialGradient.png"
glow.ImageColor3 = Color3.fromRGB(40, 100, 255)
glow.ImageTransparency = 1
glow.ZIndex = 9
glow.Parent = menuHolder

local Hub = Instance.new("Frame")
Hub.Name = "Hub"
Hub.AnchorPoint = Vector2.new(0.5, 0.5)
Hub.Position = UDim2.fromScale(0.5, 0.5)
Hub.Size = UDim2.fromScale(1, 1)
Hub.BackgroundColor3 = BG
Hub.BackgroundTransparency = 1
Hub.BorderSizePixel = 0
Hub.ClipsDescendants = true
Hub.ZIndex = 10
Hub.Parent = menuHolder
mkC(Hub, 16)

local HubGradient = Instance.new("UIGradient")
HubGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(28, 28, 50)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(18, 20, 36)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(12, 14, 26)),
})
HubGradient.Rotation = 135
HubGradient.Parent = Hub

local HubS = Instance.new("UIStroke")
HubS.Color = ACCENT
HubS.Thickness = 1.5
HubS.Transparency = 1
HubS.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
HubS.Parent = Hub

--==================================================================
-- C2Hub: TITLE BAR
--==================================================================
local TBar = Instance.new("Frame")
TBar.Name = "TitleBar"
TBar.Size = UDim2.new(1, 0, 0, 42)
TBar.BackgroundColor3 = SEC
TBar.BackgroundTransparency = 0.05
TBar.BorderSizePixel = 0
TBar.ZIndex = 11
TBar.Parent = Hub
mkC(TBar, 16)

local TFill = Instance.new("Frame")
TFill.Size = UDim2.new(1, 0, 0, 16)
TFill.Position = UDim2.new(0, 0, 1, -16)
TFill.BackgroundColor3 = SEC
TFill.BackgroundTransparency = 0.05
TFill.BorderSizePixel = 0
TFill.ZIndex = 10
TFill.Parent = TBar

local TL = Instance.new("TextLabel")
TL.Size = UDim2.new(1, -90, 1, 0)
TL.Position = UDim2.new(0, 14, 0, 0)
TL.BackgroundTransparency = 1
TL.Text = "✦  CAVES 2 HUB"
TL.TextColor3 = ACCENT
TL.TextSize = 14
TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left
TL.ZIndex = 12
TL.Parent = TBar

local CB = Instance.new("TextButton")
CB.Size = UDim2.new(0, 28, 0, 28)
CB.Position = UDim2.new(1, -36, 0, 7)
CB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CB.BackgroundTransparency = 0.85
CB.Text = "X"
CB.TextColor3 = DIM
CB.TextSize = 15
CB.Font = Enum.Font.GothamBold
CB.AutoButtonColor = false
CB.ZIndex = 12
CB.Parent = TBar
mkC(CB, 14)

--==================================================================
-- C2Hub: TABS
--==================================================================
local TBR = Instance.new("Frame")
TBR.Size = UDim2.new(1, -16, 0, 34)
TBR.Position = UDim2.new(0, 8, 0, 50)
TBR.BackgroundTransparency = 1
TBR.ZIndex = 11
TBR.Parent = Hub

local TBRL = Instance.new("UIListLayout")
TBRL.FillDirection = Enum.FillDirection.Horizontal
TBRL.Padding = UDim.new(0, 4)
TBRL.Parent = TBR

local TC = Instance.new("Frame")
TC.Size = UDim2.new(1, -16, 1, -100)
TC.Position = UDim2.new(0, 8, 0, 90)
TC.BackgroundTransparency = 1
TC.ZIndex = 5
TC.Parent = Hub

local tabs = {}
local activeTab = nil

local function mkTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 0, 0, 30)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundColor3 = CARD
    btn.Text = "  " .. name .. "  "
    btn.TextColor3 = DIM
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.ZIndex = 11
    btn.Parent = TBR
    mkC(btn, 8)

    local page = Instance.new("Frame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ZIndex = 5
    page.Parent = TC

    local scr = Instance.new("ScrollingFrame")
    scr.Size = UDim2.new(1, 0, 1, 0)
    scr.BackgroundTransparency = 1
    scr.ScrollBarThickness = 3
    scr.ScrollBarImageColor3 = ACCENT
    scr.BorderSizePixel = 0
    scr.CanvasSize = UDim2.new(0, 0, 0, 0)
    scr.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scr.ZIndex = 6
    scr.Parent = page

    local sp = Instance.new("UIPadding")
    sp.PaddingLeft = UDim.new(0, 8)
    sp.PaddingRight = UDim.new(0, 8)
    sp.PaddingBottom = UDim.new(0, 8)
    sp.Parent = scr

    local lo = Instance.new("UIListLayout")
    lo.Padding = UDim.new(0, 5)
    lo.SortOrder = Enum.SortOrder.LayoutOrder
    lo.Parent = scr

    tabs[name] = {btn = btn, page = page, scroll = scr}

    btn.MouseButton1Click:Connect(function()
        activeTab = name
        for tn, td in pairs(tabs) do
            td.page.Visible = (tn == name)
            TweenService:Create(td.btn, TweenInfo.new(0.15), {
                BackgroundColor3 = tn == name and ACCENT or CARD
            }):Play()
            td.btn.TextColor3 = tn == name and Color3.new(1, 1, 1) or DIM
        end
    end)
    return scr
end

--==================================================================
-- TAB: Points
--==================================================================
local ptScr = mkTab("Points")

local markInfo = Instance.new("Frame")
markInfo.Size = UDim2.new(1, 0, 0, 30)
markInfo.BackgroundColor3 = CARD
markInfo.BorderSizePixel = 0
markInfo.LayoutOrder = 0
markInfo.ZIndex = 7
markInfo.Parent = ptScr
mkC(markInfo, 8)

local markLbl = Instance.new("TextLabel")
markLbl.Size = UDim2.new(1, -16, 1, 0)
markLbl.Position = UDim2.new(0, 8, 0, 0)
markLbl.BackgroundTransparency = 1
markLbl.Text = "Mark: None  |  T = TP item here"
markLbl.TextColor3 = DIM
markLbl.TextSize = 10
markLbl.Font = Enum.Font.Gotham
markLbl.TextXAlignment = Enum.TextXAlignment.Left
markLbl.ZIndex = 8
markLbl.Parent = markInfo

local function updateMarkInfo()
    if markedPoint then
        markLbl.Text = "Mark: " .. markedPoint.Name .. "  |  T = TP item here"
        markLbl.TextColor3 = OKC
    else
        markLbl.Text = "Mark: None  |  T = TP item here"
        markLbl.TextColor3 = DIM
    end
end

local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(1, 0, 0, 34)
tpBtn.BackgroundColor3 = OKC
tpBtn.Text = "TELEPORT ITEM TO MARKED  [T]"
tpBtn.TextColor3 = Color3.new(1, 1, 1)
tpBtn.TextSize = 13
tpBtn.Font = Enum.Font.GothamBold
tpBtn.AutoButtonColor = false
tpBtn.LayoutOrder = 1
tpBtn.ZIndex = 7
tpBtn.Parent = ptScr
mkC(tpBtn, 8)
tpBtn.MouseEnter:Connect(function() tpBtn.BackgroundTransparency = 0.2 end)
tpBtn.MouseLeave:Connect(function() tpBtn.BackgroundTransparency = 0   end)

local function doItemTP()
    if not markedPoint then
        notify("", "No marked point!", 2)
        return
    end
    tpItemTo(markedPoint.CFrame)
    notify("", "Item -> " .. markedPoint.Name, 2)
end
tpBtn.MouseButton1Click:Connect(doItemTP)

local pointFrames = {}
local refreshPoints  -- forward declaration

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(1, 0, 0, 30)
addBtn.BackgroundColor3 = ACCENT
addBtn.Text = "+ ADD CURRENT LOCATION"
addBtn.TextColor3 = Color3.new(1, 1, 1)
addBtn.TextSize = 12
addBtn.Font = Enum.Font.GothamBold
addBtn.AutoButtonColor = false
addBtn.LayoutOrder = 2
addBtn.ZIndex = 7
addBtn.Parent = ptScr
mkC(addBtn, 8)
addBtn.MouseEnter:Connect(function() addBtn.BackgroundTransparency = 0.2 end)
addBtn.MouseLeave:Connect(function() addBtn.BackgroundTransparency = 0   end)

addBtn.MouseButton1Click:Connect(function()
    local ch = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
    if ch then
        local p = mkPoint()
        p.Position = ch.Position - Vector3.new(0, 3, 0)
        savePts()
        refreshPoints()
        notify("", "Point added!", 2)
    end
end)

refreshPoints = function()
    for _, f in ipairs(pointFrames) do f:Destroy() end
    pointFrames = {}
    for i, pt in ipairs(ptsFolder:GetChildren()) do
        local isMarked = (markedPoint == pt)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = isMarked and Color3.fromRGB(30, 50, 40) or CARD
        row.BorderSizePixel = 0
        row.LayoutOrder = i + 10
        row.ZIndex = 7
        row.Parent = ptScr
        mkC(row, 8)

        if isMarked then
            local mBar = Instance.new("Frame")
            mBar.Size = UDim2.new(0, 3, 1, 0)
            mBar.BackgroundColor3 = OKC
            mBar.BorderSizePixel = 0
            mBar.ZIndex = 9
            mBar.Parent = row
        end

        local rpad = Instance.new("UIPadding")
        rpad.PaddingLeft = UDim.new(0, 10)
        rpad.Parent = row

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new(0, 4, 0.5, -5)
        dot.BackgroundColor3 = pt.Color
        dot.BorderSizePixel = 0
        dot.ZIndex = 8
        dot.Parent = row
        mkC(dot, 5)

        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(1, -155, 1, 0)
        nl.Position = UDim2.new(0, 20, 0, 0)
        nl.BackgroundTransparency = 1
        nl.Text = (isMarked and ">> " or "") .. pt.Name .. (isMarked and " <<" or "")
        nl.TextColor3 = isMarked and OKC or TXT
        nl.TextSize = 12
        nl.Font = Enum.Font.GothamSemibold
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.TextTruncate = Enum.TextTruncate.AtEnd
        nl.ZIndex = 8
        nl.Parent = row

        local btnR = Instance.new("Frame")
        btnR.Size = UDim2.new(0, 140, 0, 24)
        btnR.Position = UDim2.new(1, -146, 0.5, -12)
        btnR.BackgroundTransparency = 1
        btnR.ZIndex = 8
        btnR.Parent = row

        local brl = Instance.new("UIListLayout")
        brl.FillDirection = Enum.FillDirection.Horizontal
        brl.HorizontalAlignment = Enum.HorizontalAlignment.Right
        brl.VerticalAlignment = Enum.VerticalAlignment.Center
        brl.Padding = UDim.new(0, 3)
        brl.Parent = btnR

        local colBtn = Instance.new("TextButton")
        colBtn.Size = UDim2.new(0, 20, 0, 20)
        colBtn.BackgroundColor3 = pt.Color
        colBtn.Text = ""
        colBtn.AutoButtonColor = false
        colBtn.ZIndex = 9
        colBtn.Parent = btnR
        mkC(colBtn, 5)

        local COLORS = {
            Color3.fromRGB(0, 130, 255),
            Color3.fromRGB(40, 200, 80),
            Color3.fromRGB(230, 60, 60),
            Color3.fromRGB(255, 200, 40),
            Color3.fromRGB(160, 80, 255),
            Color3.fromRGB(255, 130, 30),
            Color3.fromRGB(255, 80, 160),
            Color3.fromRGB(200, 200, 210),
        }
        colBtn.MouseButton1Click:Connect(function()
            local ci = 1
            for j, co in ipairs(COLORS) do
                if (pt.Color.R - co.R)^2 + (pt.Color.G - co.G)^2 + (pt.Color.B - co.B)^2 < 0.01 then
                    ci = j; break
                end
            end
            local ni = (ci % #COLORS) + 1
            pt.Color = COLORS[ni]
            dot.BackgroundColor3 = COLORS[ni]
            colBtn.BackgroundColor3 = COLORS[ni]
            savePts()
        end)

        local markBtn = Instance.new("TextButton")
        markBtn.Size = UDim2.new(0, 38, 0, 20)
        markBtn.BackgroundColor3 = isMarked and OKC or Color3.fromRGB(60, 65, 80)
        markBtn.Text = "MARK"
        markBtn.TextColor3 = Color3.new(1, 1, 1)
        markBtn.TextSize = 9
        markBtn.Font = Enum.Font.GothamBold
        markBtn.AutoButtonColor = false
        markBtn.ZIndex = 9
        markBtn.Parent = btnR
        mkC(markBtn, 5)

        markBtn.MouseButton1Click:Connect(function()
            if markedPoint == pt then markedPoint = nil else markedPoint = pt end
            updateMarkInfo()
            refreshPoints()
        end)

        local goBtn = Instance.new("TextButton")
        goBtn.Size = UDim2.new(0, 34, 0, 20)
        goBtn.BackgroundColor3 = ACCENT
        goBtn.Text = "GO"
        goBtn.TextColor3 = Color3.new(1, 1, 1)
        goBtn.TextSize = 10
        goBtn.Font = Enum.Font.GothamBold
        goBtn.AutoButtonColor = false
        goBtn.ZIndex = 9
        goBtn.Parent = btnR
        mkC(goBtn, 5)
        goBtn.MouseButton1Click:Connect(function()
            tpPlayerTo(pt.CFrame + Vector3.new(0, 3, 0))
        end)

        local itemBtn = Instance.new("TextButton")
        itemBtn.Size = UDim2.new(0, 26, 0, 20)
        itemBtn.BackgroundColor3 = OKC
        itemBtn.Text = "I"
        itemBtn.TextColor3 = Color3.new(1, 1, 1)
        itemBtn.TextSize = 10
        itemBtn.Font = Enum.Font.GothamBold
        itemBtn.AutoButtonColor = false
        itemBtn.ZIndex = 9
        itemBtn.Parent = btnR
        mkC(itemBtn, 5)
        itemBtn.MouseButton1Click:Connect(function()
            tpItemTo(pt.CFrame)
        end)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 20, 0, 20)
        delBtn.BackgroundColor3 = ERRC
        delBtn.Text = "X"
        delBtn.TextColor3 = Color3.new(1, 1, 1)
        delBtn.TextSize = 9
        delBtn.Font = Enum.Font.GothamBold
        delBtn.AutoButtonColor = false
        delBtn.ZIndex = 9
        delBtn.Parent = btnR
        mkC(delBtn, 5)
        delBtn.MouseButton1Click:Connect(function()
            if markedPoint == pt then
                markedPoint = nil
                updateMarkInfo()
            end
            pt:Destroy()
            savePts()
            refreshPoints()
        end)

        row.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton2 then
                local dlg = Instance.new("Frame")
                dlg.Size = UDim2.new(0, 240, 0, 70)
                dlg.Position = UDim2.new(0.5, -120, 0.5, -35)
                dlg.BackgroundColor3 = BG
                dlg.BorderSizePixel = 0
                dlg.ZIndex = 200
                dlg.Parent = SG
                mkC(dlg, 10)

                local ds = Instance.new("UIStroke")
                ds.Color = ACCENT
                ds.Parent = dlg

                local tb = Instance.new("TextBox")
                tb.Size = UDim2.new(1, -16, 0, 24)
                tb.Position = UDim2.new(0, 8, 0, 8)
                tb.BackgroundColor3 = CARD
                tb.Text = pt.Name
                tb.TextColor3 = TXT
                tb.TextSize = 12
                tb.Font = Enum.Font.Gotham
                tb.ClearTextOnFocus = false
                tb.ZIndex = 201
                tb.Parent = dlg
                mkC(tb, 6)

                local ob = Instance.new("TextButton")
                ob.Size = UDim2.new(1, -16, 0, 22)
                ob.Position = UDim2.new(0, 8, 0, 38)
                ob.BackgroundColor3 = OKC
                ob.Text = "Save"
                ob.TextColor3 = Color3.new(1, 1, 1)
                ob.TextSize = 11
                ob.Font = Enum.Font.GothamBold
                ob.ZIndex = 201
                ob.Parent = dlg
                mkC(ob, 6)

                ob.MouseButton1Click:Connect(function()
                    if tb.Text ~= "" then
                        pt.Name = tb.Text
                        savePts()
                        refreshPoints()
                    end
                    dlg:Destroy()
                end)
                tb:CaptureFocus()
            end
        end)

        table.insert(pointFrames, row)
    end
end

--==================================================================
-- TAB: Perfect Hit
--==================================================================
local phScr = mkTab("Perfect Hit")

local phH = Instance.new("Frame")
phH.Size = UDim2.new(1, 0, 0, 44)
phH.BackgroundColor3 = CARD
phH.BorderSizePixel = 0
phH.LayoutOrder = 0
phH.ZIndex = 7
phH.Parent = phScr
mkC(phH, 8)

local phP = Instance.new("UIPadding")
phP.PaddingLeft = UDim.new(0, 10)
phP.PaddingTop = UDim.new(0, 8)
phP.Parent = phH

local phT = Instance.new("TextLabel")
phT.Size = UDim2.new(1, -20, 0, 15)
phT.BackgroundTransparency = 1
phT.Text = "PERFECT HIT"
phT.TextColor3 = exploitOk and OKC or Color3.fromRGB(255, 180, 50)
phT.TextSize = 13
phT.Font = Enum.Font.GothamBold
phT.TextXAlignment = Enum.TextXAlignment.Left
phT.ZIndex = 8
phT.Parent = phH

local phD = Instance.new("TextLabel")
phD.Size = UDim2.new(1, -20, 0, 18)
phD.Position = UDim2.new(0, 0, 0, 16)
phD.BackgroundTransparency = 1
phD.Text = exploitOk and "Toggle ON = always perfect | P = single" or "Hook unsupported. Use button or P."
phD.TextColor3 = DIM
phD.TextSize = 10
phD.Font = Enum.Font.Gotham
phD.TextXAlignment = Enum.TextXAlignment.Left
phD.ZIndex = 8
phD.Parent = phH

local phRow = Instance.new("Frame")
phRow.Size = UDim2.new(1, 0, 0, 36)
phRow.BackgroundColor3 = CARD
phRow.BorderSizePixel = 0
phRow.LayoutOrder = 1
phRow.ZIndex = 7
phRow.Parent = phScr
mkC(phRow, 8)

local phRP = Instance.new("UIPadding")
phRP.PaddingLeft = UDim.new(0, 10)
phRP.Parent = phRow

local phLbl = Instance.new("TextLabel")
phLbl.Size = UDim2.new(1, -60, 1, 0)
phLbl.BackgroundTransparency = 1
phLbl.Text = "Always On"
phLbl.TextColor3 = TXT
phLbl.TextSize = 13
phLbl.Font = Enum.Font.GothamBold
phLbl.TextXAlignment = Enum.TextXAlignment.Left
phLbl.ZIndex = 8
phLbl.Parent = phRow

local phState = false
local phTog = Instance.new("Frame")
phTog.Size = UDim2.new(0, 44, 0, 22)
phTog.Position = UDim2.new(1, -52, 0.5, -11)
phTog.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
phTog.ZIndex = 8
phTog.Parent = phRow
mkC(phTog, 11)

local phDot = Instance.new("Frame")
phDot.Size = UDim2.new(0, 18, 0, 18)
phDot.Position = UDim2.new(0.05, 0, 0.111, 0)
phDot.BackgroundColor3 = Color3.new(1, 1, 1)
phDot.ZIndex = 9
phDot.Parent = phTog
mkC(phDot, 9)

local phTB = Instance.new("TextButton")
phTB.Size = UDim2.new(1, 0, 1, 0)
phTB.BackgroundTransparency = 1
phTB.Text = ""
phTB.AutoButtonColor = false
phTB.ZIndex = 10
phTB.Parent = phRow
phTB.MouseButton1Click:Connect(function()
    phState = not phState
    phOn = phState
    TweenService:Create(phTog, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = phState and OKC or Color3.fromRGB(50, 50, 55)
    }):Play()
    TweenService:Create(phDot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(phState and 0.545 or 0.05, 0, 0.111, 0)
    }):Play()
end)

local phB = Instance.new("TextButton")
phB.Size = UDim2.new(1, 0, 0, 34)
phB.BackgroundColor3 = CARD
phB.Text = "Single Perfect Hit  [P]"
phB.TextColor3 = TXT
phB.TextSize = 13
phB.Font = Enum.Font.GothamBold
phB.AutoButtonColor = false
phB.LayoutOrder = 2
phB.ZIndex = 7
phB.Parent = phScr
mkC(phB, 8)
phB.MouseEnter:Connect(function() phB.BackgroundColor3 = HOVER end)
phB.MouseLeave:Connect(function() phB.BackgroundColor3 = CARD  end)
phB.MouseButton1Click:Connect(function()
    pcall(function()
        ReplicatedStorage.Events.Tools.Attack:FireServer({Alpha = 1, ResponseTime = 0.76456})
    end)
end)

--==================================================================
-- DRAG (title bar — двигает menuHolder)
--==================================================================
local dg, dgs, dgp
TBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dg = true
        dgs = i.Position
        dgp = menuHolder.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dg and i.UserInputType == Enum.UserInputType.MouseMovement then
        menuHolder.Position = UDim2.new(
            dgp.X.Scale, dgp.X.Offset + (i.Position.X - dgs.X),
            dgp.Y.Scale, dgp.Y.Offset + (i.Position.Y - dgs.Y)
        )
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dg = false end
end)

--==================================================================
-- ЗВЁЗДЫ, ЛИНИИ, ПАДАЮЩИЕ ЗВЁЗДЫ
--==================================================================
local stars = {}

local function makeStarLineFrame()
    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)  -- центральная привязка — корректный поворот
    line.BorderSizePixel = 0
    line.BackgroundColor3 = Color3.fromRGB(200, 215, 255)
    line.BackgroundTransparency = 1
    line.ZIndex = 3
    line.Visible = false
    line.Parent = starLayer
    return line
end

local function createStar()
    local size = rand:NextNumber(CONFIG.STAR_MIN_SIZE, CONFIG.STAR_MAX_SIZE)
    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.fromOffset(size, size)
    frame.BackgroundColor3 = pickStarColor()
    frame.BorderSizePixel = 0
    frame.ZIndex = 3
    frame.Parent = starLayer

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = frame

    local glowStroke = Instance.new("UIStroke")
    glowStroke.Color = frame.BackgroundColor3
    glowStroke.Thickness = math.max(1, size * 0.45)
    glowStroke.Transparency = 0.55
    glowStroke.Parent = frame

    local viewport = workspace.CurrentCamera.ViewportSize
    local angle = rand:NextNumber(0, math.pi * 2)
    local speed = rand:NextNumber(CONFIG.STAR_MIN_SPEED, CONFIG.STAR_MAX_SPEED)
    return {
        gui = frame,
        glow = glowStroke,
        x = rand:NextNumber(0, viewport.X),
        y = rand:NextNumber(0, viewport.Y),
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        size = size,
        twinklePhase = rand:NextNumber(0, math.pi * 2),
        twinkleSpeed = rand:NextNumber(CONFIG.TWINKLE_SPEED_MIN, CONFIG.TWINKLE_SPEED_MAX),
        line = makeStarLineFrame(),
    }
end

for _ = 1, CONFIG.STAR_COUNT do
    table.insert(stars, createStar())
end

local shootingStars = {}
local function spawnShootingStar()
    local viewport = workspace.CurrentCamera.ViewportSize
    local fromTop = rand:NextNumber(0, 1) > 0.5
    local sx, sy
    if fromTop then
        sx = rand:NextNumber(-viewport.X * 0.2, viewport.X * 0.7)
        sy = -40
    else
        sx = -40
        sy = rand:NextNumber(-viewport.Y * 0.1, viewport.Y * 0.7)
    end
    local angleDeg = rand:NextNumber(25, 55)
    local rad = math.rad(angleDeg)
    local vx = math.cos(rad) * CONFIG.SHOOTING_SPEED
    local vy = math.sin(rad) * CONFIG.SHOOTING_SPEED

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromOffset(sx, sy)
    frame.Size = UDim2.fromOffset(rand:NextInteger(70, 120), 2)
    frame.BackgroundColor3 = Color3.fromRGB(255, 245, 220)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Rotation = angleDeg
    frame.ZIndex = 4
    frame.Parent = shootLayer

    local grad = Instance.new("UIGradient")
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    grad.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    table.insert(shootingStars, {
        gui = frame, x = sx, y = sy, vx = vx, vy = vy,
        life = 0, maxLife = 1.8,
    })
end

local nextShootingTime = rand:NextNumber(CONFIG.SHOOTING_INTERVAL_MIN, CONFIG.SHOOTING_INTERVAL_MAX)
local shootingTimer = 0

--==================================================================
-- АНИМАЦИЯ ОТКРЫТИЯ / ЗАКРЫТИЯ
--==================================================================
local isOpen = false
local isAnimating = false

local function setOpen(open)
    if isAnimating then return end
    if open == isOpen then return end
    isAnimating = true
    isOpen = open
    SG.Enabled = true

    local ti = TweenInfo.new(CONFIG.TWEEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    TweenService:Create(tint, ti, {
        BackgroundTransparency = open and CONFIG.MENU_TINT_TRANSP or 1,
    }):Play()
    TweenService:Create(vignette, ti, {
        ImageTransparency = open and 0.25 or 1,
    }):Play()
    TweenService:Create(glow, ti, {
        ImageTransparency = open and 0.55 or 1,
    }):Play()
    TweenService:Create(Hub, ti, {
        BackgroundTransparency = open and CONFIG.MENU_BG_TRANSP or 1,
    }):Play()
    TweenService:Create(HubS, ti, {
        Transparency = open and 0 or 1,
    }):Play()
    TweenService:Create(menuHolder, ti, {
        Size = open
            and UDim2.fromOffset(CONFIG.MENU_SIZE.X, CONFIG.MENU_SIZE.Y)
            or  UDim2.fromOffset(CONFIG.MENU_SIZE.X - 60, CONFIG.MENU_SIZE.Y - 60),
        Rotation = open and 0 or -2,
    }):Play()

    task.delay(CONFIG.TWEEN_TIME, function()
        isAnimating = false
        if not isOpen then SG.Enabled = false end
    end)
end

CB.MouseButton1Click:Connect(function() setOpen(false) end)

--==================================================================
-- KEYBINDS
--==================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == CONFIG.OPEN_KEY then
        setOpen(not isOpen)
        return
    end
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        doItemTP()
    elseif input.KeyCode == Enum.KeyCode.P then
        pcall(function()
            ReplicatedStorage.Events.Tools.Attack:FireServer({Alpha = 1, ResponseTime = 0.76456})
        end)
    end
end)

pcall(function()
    game:GetService("ContextActionService"):BindAction("C2Hub_Toggle",
        function(_, state)
            if state == Enum.UserInputState.Begin then
                setOpen(not isOpen)
            end
            return Enum.ContextActionResult.Pass
        end,
        false, Enum.KeyCode.RightShift
    )
end)

--==================================================================
-- INIT
--==================================================================
loadPts()
refreshPoints()
updateMarkInfo()

activeTab = "Points"
for tn, td in pairs(tabs) do
    td.page.Visible = (tn == "Points")
    td.btn.BackgroundColor3 = tn == "Points" and ACCENT or CARD
    td.btn.TextColor3 = tn == "Points" and Color3.new(1, 1, 1) or DIM
end

task.delay(1, function()
    notify("Caves 2 Hub", "RightShift = menu | T = item TP", 4)
end)

--==================================================================
-- ГЛАВНЫЙ ЦИКЛ (звёзды + линии + падающие звёзды)
--==================================================================
RunService.RenderStepped:Connect(function(dt)
    if not SG.Enabled then return end

    local cam = workspace.CurrentCamera
    if not cam then return end
    local viewport = cam.ViewportSize

    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    local mx = mousePos.X
    local my = mousePos.Y + inset.Y

    local radius = CONFIG.CURSOR_RADIUS
    local radiusSq = radius * radius

    for _, s in ipairs(stars) do
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt
        if s.x < 0 then s.x = 0; s.vx = -s.vx
        elseif s.x > viewport.X then s.x = viewport.X; s.vx = -s.vx end
        if s.y < 0 then s.y = 0; s.vy = -s.vy
        elseif s.y > viewport.Y then s.y = viewport.Y; s.vy = -s.vy end

        s.gui.Position = UDim2.fromOffset(s.x, s.y)

        s.twinklePhase = s.twinklePhase + s.twinkleSpeed * dt
        local t = (math.sin(s.twinklePhase) + 1) * 0.5
        local alpha = CONFIG.TWINKLE_MIN + (CONFIG.TWINKLE_MAX - CONFIG.TWINKLE_MIN) * t
        s.gui.BackgroundTransparency = 1 - alpha
        s.glow.Transparency = 1 - alpha * 0.45

        local dx = mx - s.x
        local dy = my - s.y
        local distSq = dx * dx + dy * dy
        if distSq <= radiusSq and distSq > 1 then
            local dist = math.sqrt(distSq)
            local ratio = 1 - (dist / radius)
            local line = s.line
            local midX = (s.x + mx) * 0.5
            local midY = (s.y + my) * 0.5
            line.Position = UDim2.fromOffset(midX, midY)
            line.Size = UDim2.fromOffset(dist, CONFIG.LINE_THICKNESS)
            line.Rotation = math.deg(math.atan2(dy, dx))
            line.BackgroundTransparency = 1 - (ratio * 0.65) * alpha
            line.Visible = true
        else
            s.line.Visible = false
        end
    end

    shootingTimer = shootingTimer + dt
    if shootingTimer >= nextShootingTime then
        shootingTimer = 0
        nextShootingTime = rand:NextNumber(CONFIG.SHOOTING_INTERVAL_MIN, CONFIG.SHOOTING_INTERVAL_MAX)
        spawnShootingStar()
    end
    for i = #shootingStars, 1, -1 do
        local sh = shootingStars[i]
        sh.life = sh.life + dt
        sh.x = sh.x + sh.vx * dt
        sh.y = sh.y + sh.vy * dt
        sh.gui.Position = UDim2.fromOffset(sh.x, sh.y)
        local t = sh.life / sh.maxLife
        sh.gui.BackgroundTransparency = math.min(1, 0.1 + t * 0.9)
        if sh.life >= sh.maxLife or sh.x > viewport.X + 200 or sh.y > viewport.Y + 200 then
            sh.gui:Destroy()
            table.remove(shootingStars, i)
        end
    end
end)

workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local viewport = workspace.CurrentCamera.ViewportSize
    for _, s in ipairs(stars) do
        s.x = math.clamp(s.x, 0, viewport.X)
        s.y = math.clamp(s.y, 0, viewport.Y)
    end
end)

print("Caves 2 Hub v9 + StarMenu loaded!")
