--[[
    StarMenu.lua
    Красивое детализированное пустое меню с анимированным звёздным фоном.
    При приближении курсора от звёзд тянутся линии точно к курсору.
    Открытие/закрытие — Right Shift.

    Помести как LocalScript в StarterPlayer -> StarterPlayerScripts.
--]]

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local GuiService        = game:GetService("GuiService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================================
-- НАСТРОЙКИ
--==================================================================
local CONFIG = {
    STAR_COUNT          = 110,
    STAR_MIN_SIZE       = 1.5,
    STAR_MAX_SIZE       = 5,
    STAR_MIN_SPEED      = 6,
    STAR_MAX_SPEED      = 26,
    TWINKLE_MIN         = 0.25,
    TWINKLE_MAX         = 1.0,
    TWINKLE_SPEED_MIN   = 0.6,
    TWINKLE_SPEED_MAX   = 2.6,

    SHOOTING_INTERVAL_MIN = 4.0,  -- секунды между падающими звёздами
    SHOOTING_INTERVAL_MAX = 9.0,
    SHOOTING_SPEED        = 1400,

    CURSOR_RADIUS       = 150,
    LINE_THICKNESS      = 1.2,

    MENU_TINT_TRANSP    = 0.22,   -- 0 = чёрный, 1 = невидимо
    MENU_BG_TRANSP      = 0.08,
    MENU_SIZE           = Vector2.new(520, 600),

    OPEN_KEY            = Enum.KeyCode.RightShift,
    TWEEN_TIME          = 0.55,
}

--==================================================================
-- ВСПОМОГАТЕЛЬНОЕ
--==================================================================
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

--==================================================================
-- ScreenGui + СЛОИ
--==================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarMenuGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 50
screenGui.Enabled = false
screenGui.Parent = playerGui

-- 1) Затемняющая подложка с вертикальным градиентом
local tint = Instance.new("Frame")
tint.Name = "Tint"
tint.Size = UDim2.fromScale(1, 1)
tint.BackgroundColor3 = Color3.fromRGB(5, 6, 14)
tint.BackgroundTransparency = 1
tint.BorderSizePixel = 0
tint.ZIndex = 1
tint.Parent = screenGui

local tintGradient = Instance.new("UIGradient")
tintGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(28, 18, 55)),
    ColorSequenceKeypoint.new(0.45, Color3.fromRGB(10, 10, 28)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(2, 2, 8)),
})
tintGradient.Rotation = 90
tintGradient.Parent = tint

-- 2) Виньетка — затемнение по краям
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
vignette.Parent = screenGui

-- 3) Слой со звёздами и линиями
local starLayer = Instance.new("Frame")
starLayer.Name = "StarLayer"
starLayer.Size = UDim2.fromScale(1, 1)
starLayer.BackgroundTransparency = 1
starLayer.BorderSizePixel = 0
starLayer.ZIndex = 3
starLayer.Parent = screenGui

-- 4) Слой падающих звёзд (поверх обычных)
local shootLayer = Instance.new("Frame")
shootLayer.Name = "ShootLayer"
shootLayer.Size = UDim2.fromScale(1, 1)
shootLayer.BackgroundTransparency = 1
shootLayer.BorderSizePixel = 0
shootLayer.ZIndex = 4
shootLayer.Parent = screenGui

--==================================================================
-- МЕНЮ (детализированное, пустое внутри)
--==================================================================
local menuHolder = Instance.new("Frame")
menuHolder.Name = "MenuHolder"
menuHolder.AnchorPoint = Vector2.new(0.5, 0.5)
menuHolder.Position = UDim2.fromScale(0.5, 0.5)
menuHolder.Size = UDim2.fromOffset(CONFIG.MENU_SIZE.X, CONFIG.MENU_SIZE.Y)
menuHolder.BackgroundTransparency = 1
menuHolder.BorderSizePixel = 0
menuHolder.ZIndex = 10
menuHolder.Parent = screenGui

-- Внешнее свечение / ореол
local glow = Instance.new("ImageLabel")
glow.Name = "Glow"
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.5)
glow.Size = UDim2.new(1, 220, 1, 220)
glow.BackgroundTransparency = 1
glow.BorderSizePixel = 0
glow.Image = "rbxasset://textures/ui/Controls/RadialGradient.png"
glow.ImageColor3 = Color3.fromRGB(120, 130, 255)
glow.ImageTransparency = 1
glow.ZIndex = 9
glow.Parent = menuHolder

-- Основная панель меню
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.Size = UDim2.fromScale(1, 1)
menu.BackgroundColor3 = Color3.fromRGB(16, 16, 30)
menu.BackgroundTransparency = 1
menu.BorderSizePixel = 0
menu.ZIndex = 10
menu.Parent = menuHolder

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 22)
menuCorner.Parent = menu

local menuGradient = Instance.new("UIGradient")
menuGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(48, 36, 90)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(22, 22, 50)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(12, 14, 28)),
})
menuGradient.Rotation = 135
menuGradient.Parent = menu

-- Внешняя обводка (двойная: тонкая + сияющая)
local outerStroke = Instance.new("UIStroke")
outerStroke.Color = Color3.fromRGB(140, 150, 240)
outerStroke.Thickness = 1.5
outerStroke.Transparency = 1
outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
outerStroke.Parent = menu

local outerStrokeGradient = Instance.new("UIGradient")
outerStrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(180, 140, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 200, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(180, 140, 255)),
})
outerStrokeGradient.Parent = outerStroke

-- Внутренняя рамка (тонкая декоративная)
local innerBorder = Instance.new("Frame")
innerBorder.Name = "InnerBorder"
innerBorder.AnchorPoint = Vector2.new(0.5, 0.5)
innerBorder.Position = UDim2.fromScale(0.5, 0.5)
innerBorder.Size = UDim2.new(1, -28, 1, -28)
innerBorder.BackgroundTransparency = 1
innerBorder.BorderSizePixel = 0
innerBorder.ZIndex = 11
innerBorder.Parent = menu

local innerBorderCorner = Instance.new("UICorner")
innerBorderCorner.CornerRadius = UDim.new(0, 16)
innerBorderCorner.Parent = innerBorder

local innerBorderStroke = Instance.new("UIStroke")
innerBorderStroke.Color = Color3.fromRGB(140, 150, 220)
innerBorderStroke.Thickness = 1
innerBorderStroke.Transparency = 1
innerBorderStroke.Parent = innerBorder

-- Декоративные «уголки» (4 штуки)
local function makeCorner(name, ax, ay, posX, posY, rot)
    local c = Instance.new("Frame")
    c.Name = name
    c.AnchorPoint = Vector2.new(ax, ay)
    c.Position = UDim2.new(posX, 0, posY, 0)
    c.Size = UDim2.fromOffset(32, 32)
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.Rotation = rot
    c.ZIndex = 12
    c.Parent = menu

    local h = Instance.new("Frame")
    h.AnchorPoint = Vector2.new(0, 0)
    h.Position = UDim2.fromOffset(0, 0)
    h.Size = UDim2.fromOffset(18, 1.5)
    h.BackgroundColor3 = Color3.fromRGB(200, 210, 255)
    h.BackgroundTransparency = 1
    h.BorderSizePixel = 0
    h.Parent = c

    local v = Instance.new("Frame")
    v.AnchorPoint = Vector2.new(0, 0)
    v.Position = UDim2.fromOffset(0, 0)
    v.Size = UDim2.fromOffset(1.5, 18)
    v.BackgroundColor3 = Color3.fromRGB(200, 210, 255)
    v.BackgroundTransparency = 1
    v.BorderSizePixel = 0
    v.Parent = c

    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0, 0)
    dot.Position = UDim2.fromOffset(-1, -1)
    dot.Size = UDim2.fromOffset(5, 5)
    dot.BackgroundColor3 = Color3.fromRGB(180, 200, 255)
    dot.BackgroundTransparency = 1
    dot.BorderSizePixel = 0
    dot.Parent = c
    local dotc = Instance.new("UICorner")
    dotc.CornerRadius = UDim.new(1, 0)
    dotc.Parent = dot

    return {frame = c, h = h, v = v, dot = dot}
end

local corners = {
    makeCorner("TL", 0, 0, 0, 0,   0),
    makeCorner("TR", 0, 0, 1, 0,  90),
    makeCorner("BR", 0, 0, 1, 1, 180),
    makeCorner("BL", 0, 0, 0, 1, 270),
}
-- Смещение уголков внутрь
corners[1].frame.Position = UDim2.fromOffset(14, 14)
corners[2].frame.Position = UDim2.new(1, -14, 0, 14)
corners[3].frame.Position = UDim2.new(1, -14, 1, -14)
corners[4].frame.Position = UDim2.fromOffset(14, -14) + UDim2.new(0, 0, 1, 0)

-- Декоративные горизонтальные линии-разделители сверху и снизу
local topLine = Instance.new("Frame")
topLine.Name = "TopLine"
topLine.AnchorPoint = Vector2.new(0.5, 0)
topLine.Position = UDim2.new(0.5, 0, 0, 60)
topLine.Size = UDim2.new(0.65, 0, 0, 1)
topLine.BackgroundColor3 = Color3.fromRGB(160, 170, 230)
topLine.BackgroundTransparency = 1
topLine.BorderSizePixel = 0
topLine.ZIndex = 12
topLine.Parent = menu

local topLineGrad = Instance.new("UIGradient")
topLineGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1,   1),
})
topLineGrad.Parent = topLine

local botLine = Instance.new("Frame")
botLine.Name = "BotLine"
botLine.AnchorPoint = Vector2.new(0.5, 1)
botLine.Position = UDim2.new(0.5, 0, 1, -60)
botLine.Size = UDim2.new(0.65, 0, 0, 1)
botLine.BackgroundColor3 = Color3.fromRGB(160, 170, 230)
botLine.BackgroundTransparency = 1
botLine.BorderSizePixel = 0
botLine.ZIndex = 12
botLine.Parent = menu

local botLineGrad = Instance.new("UIGradient")
botLineGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1,   1),
})
botLineGrad.Parent = botLine

-- Маленькие ромбы-разделители на концах линий
local function makeDiamond(parent, pos)
    local d = Instance.new("Frame")
    d.AnchorPoint = Vector2.new(0.5, 0.5)
    d.Position = pos
    d.Size = UDim2.fromOffset(8, 8)
    d.BackgroundColor3 = Color3.fromRGB(200, 210, 255)
    d.BackgroundTransparency = 1
    d.BorderSizePixel = 0
    d.Rotation = 45
    d.ZIndex = 12
    d.Parent = parent
    return d
end

local topDiamondL = makeDiamond(menu, UDim2.new(0.175, 0, 0, 60))
local topDiamondR = makeDiamond(menu, UDim2.new(0.825, 0, 0, 60))
local botDiamondL = makeDiamond(menu, UDim2.new(0.175, 0, 1, -60))
local botDiamondR = makeDiamond(menu, UDim2.new(0.825, 0, 1, -60))
local centerDiamond = makeDiamond(menu, UDim2.fromScale(0.5, 0.5))
centerDiamond.Size = UDim2.fromOffset(14, 14)

-- Декоративный круг по центру (за ромбом)
local centerRing = Instance.new("Frame")
centerRing.Name = "CenterRing"
centerRing.AnchorPoint = Vector2.new(0.5, 0.5)
centerRing.Position = UDim2.fromScale(0.5, 0.5)
centerRing.Size = UDim2.fromOffset(46, 46)
centerRing.BackgroundTransparency = 1
centerRing.BorderSizePixel = 0
centerRing.ZIndex = 11
centerRing.Parent = menu
local centerRingCorner = Instance.new("UICorner")
centerRingCorner.CornerRadius = UDim.new(1, 0)
centerRingCorner.Parent = centerRing
local centerRingStroke = Instance.new("UIStroke")
centerRingStroke.Color = Color3.fromRGB(180, 190, 255)
centerRingStroke.Thickness = 1
centerRingStroke.Transparency = 1
centerRingStroke.Parent = centerRing

-- Второй вращающийся «руноподобный» круг
local runeRing = Instance.new("Frame")
runeRing.Name = "RuneRing"
runeRing.AnchorPoint = Vector2.new(0.5, 0.5)
runeRing.Position = UDim2.fromScale(0.5, 0.5)
runeRing.Size = UDim2.fromOffset(90, 90)
runeRing.BackgroundTransparency = 1
runeRing.BorderSizePixel = 0
runeRing.ZIndex = 11
runeRing.Parent = menu
local runeRingCorner = Instance.new("UICorner")
runeRingCorner.CornerRadius = UDim.new(1, 0)
runeRingCorner.Parent = runeRing
local runeRingStroke = Instance.new("UIStroke")
runeRingStroke.Color = Color3.fromRGB(140, 160, 220)
runeRingStroke.Thickness = 1
runeRingStroke.Transparency = 1
runeRingStroke.Parent = runeRing

-- Маленькие точки-руны по периметру вращающегося круга
local runeDots = {}
for i = 1, 6 do
    local angle = (i - 1) * (math.pi * 2 / 6)
    local r = 45
    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(0.5, math.cos(angle) * r, 0.5, math.sin(angle) * r)
    dot.Size = UDim2.fromOffset(4, 4)
    dot.BackgroundColor3 = Color3.fromRGB(200, 220, 255)
    dot.BackgroundTransparency = 1
    dot.BorderSizePixel = 0
    dot.ZIndex = 11
    dot.Parent = runeRing
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = dot
    table.insert(runeDots, dot)
end

-- Внутренние плавающие звёздочки внутри меню (декор)
local innerStars = {}
for i = 1, 18 do
    local s = Instance.new("Frame")
    s.Name = "InnerStar"
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.Size = UDim2.fromOffset(rand:NextInteger(2, 4), rand:NextInteger(2, 4))
    s.BackgroundColor3 = pickStarColor()
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ZIndex = 11
    s.Parent = menu
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = s
    table.insert(innerStars, {
        gui = s,
        baseX = rand:NextNumber(0.06, 0.94),
        baseY = rand:NextNumber(0.16, 0.84),
        phase = rand:NextNumber(0, math.pi * 2),
        speed = rand:NextNumber(0.4, 1.2),
        amp   = rand:NextNumber(0.01, 0.03),
        twPhase = rand:NextNumber(0, math.pi * 2),
        twSpeed = rand:NextNumber(0.7, 2.2),
    })
end

--==================================================================
-- ЗВЁЗДЫ ФОНА
--==================================================================
local stars = {}

local function makeStarLineFrame()
    local line = Instance.new("Frame")
    line.Name = "Line"
    -- АНКОР В ЦЕНТРЕ — чтобы поворот шёл вокруг середины линии (исправление бага)
    line.AnchorPoint = Vector2.new(0.5, 0.5)
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
    frame.Name = "Star"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Size = UDim2.fromOffset(size, size)
    frame.BackgroundColor3 = pickStarColor()
    frame.BorderSizePixel = 0
    frame.ZIndex = 3
    frame.Parent = starLayer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local glowStroke = Instance.new("UIStroke")
    glowStroke.Color = frame.BackgroundColor3
    glowStroke.Thickness = math.max(1, size * 0.45)
    glowStroke.Transparency = 0.55
    glowStroke.Parent = frame

    local viewport = workspace.CurrentCamera.ViewportSize
    local angle = rand:NextNumber(0, math.pi * 2)
    local speed = rand:NextNumber(CONFIG.STAR_MIN_SPEED, CONFIG.STAR_MAX_SPEED)

    local star = {
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
    return star
end

for i = 1, CONFIG.STAR_COUNT do
    table.insert(stars, createStar())
end

--==================================================================
-- ПАДАЮЩИЕ ЗВЁЗДЫ
--==================================================================
local shootingStars = {}

local function spawnShootingStar()
    local viewport = workspace.CurrentCamera.ViewportSize
    -- Старт за пределами слева/сверху, летит вправо-вниз
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
        gui = frame,
        x = sx, y = sy,
        vx = vx, vy = vy,
        life = 0,
        maxLife = 1.8,
    })
end

local nextShootingTime = rand:NextNumber(CONFIG.SHOOTING_INTERVAL_MIN, CONFIG.SHOOTING_INTERVAL_MAX)
local shootingTimer = 0

--==================================================================
-- АНИМАЦИЯ ОТКРЫТИЯ / ЗАКРЫТИЯ
--==================================================================
local isOpen = false
local isAnimating = false

local function tweenAll(open)
    local ti = TweenInfo.new(CONFIG.TWEEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local fadeTi = TweenInfo.new(CONFIG.TWEEN_TIME * 0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    TweenService:Create(tint, ti, {
        BackgroundTransparency = open and CONFIG.MENU_TINT_TRANSP or 1,
    }):Play()

    TweenService:Create(vignette, ti, {
        ImageTransparency = open and 0.25 or 1,
    }):Play()

    TweenService:Create(glow, ti, {
        ImageTransparency = open and 0.45 or 1,
    }):Play()

    TweenService:Create(menu, ti, {
        BackgroundTransparency = open and CONFIG.MENU_BG_TRANSP or 1,
    }):Play()

    TweenService:Create(menuHolder, ti, {
        Size = open
            and UDim2.fromOffset(CONFIG.MENU_SIZE.X, CONFIG.MENU_SIZE.Y)
            or  UDim2.fromOffset(CONFIG.MENU_SIZE.X - 80, CONFIG.MENU_SIZE.Y - 80),
        Rotation = open and 0 or -3,
    }):Play()

    TweenService:Create(outerStroke,       ti, {Transparency = open and 0.05 or 1}):Play()
    TweenService:Create(innerBorderStroke, ti, {Transparency = open and 0.45 or 1}):Play()
    TweenService:Create(topLine,           ti, {BackgroundTransparency = open and 0.1 or 1}):Play()
    TweenService:Create(botLine,           ti, {BackgroundTransparency = open and 0.1 or 1}):Play()
    TweenService:Create(centerRingStroke,  ti, {Transparency = open and 0.3 or 1}):Play()
    TweenService:Create(runeRingStroke,    ti, {Transparency = open and 0.55 or 1}):Play()

    for _, d in ipairs({topDiamondL, topDiamondR, botDiamondL, botDiamondR, centerDiamond}) do
        TweenService:Create(d, ti, {BackgroundTransparency = open and 0.15 or 1}):Play()
    end

    for _, c in ipairs(corners) do
        TweenService:Create(c.h,   ti, {BackgroundTransparency = open and 0.05 or 1}):Play()
        TweenService:Create(c.v,   ti, {BackgroundTransparency = open and 0.05 or 1}):Play()
        TweenService:Create(c.dot, ti, {BackgroundTransparency = open and 0.0  or 1}):Play()
    end

    for _, dot in ipairs(runeDots) do
        TweenService:Create(dot, fadeTi, {BackgroundTransparency = open and 0.2 or 1}):Play()
    end

    for _, s in ipairs(innerStars) do
        TweenService:Create(s.gui, fadeTi, {BackgroundTransparency = open and 0.3 or 1}):Play()
    end
end

local function setOpen(open)
    if isAnimating then return end
    if open == isOpen then return end
    isAnimating = true
    isOpen = open
    screenGui.Enabled = true
    tweenAll(open)
    task.delay(CONFIG.TWEEN_TIME, function()
        isAnimating = false
        if not isOpen then
            screenGui.Enabled = false
        end
    end)
end

--==================================================================
-- ВВОД
--==================================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CONFIG.OPEN_KEY then
        setOpen(not isOpen)
    end
end)

--==================================================================
-- ГЛАВНЫЙ ЦИКЛ
--==================================================================
local timeAcc = 0

RunService.RenderStepped:Connect(function(dt)
    if not screenGui.Enabled then return end
    timeAcc = timeAcc + dt

    local cam = workspace.CurrentCamera
    if not cam then return end
    local viewport = cam.ViewportSize

    -- Мышь: компенсируем GUI inset, т.к. ScreenGui.IgnoreGuiInset = true
    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    local mx = mousePos.X
    local my = mousePos.Y + inset.Y

    -- ---- ОБЫЧНЫЕ ЗВЁЗДЫ ----
    local radius = CONFIG.CURSOR_RADIUS
    local radiusSq = radius * radius

    for _, s in ipairs(stars) do
        -- движение
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt

        -- упругое отражение от границ
        if s.x < 0 then s.x = 0; s.vx = -s.vx
        elseif s.x > viewport.X then s.x = viewport.X; s.vx = -s.vx end
        if s.y < 0 then s.y = 0; s.vy = -s.vy
        elseif s.y > viewport.Y then s.y = viewport.Y; s.vy = -s.vy end

        s.gui.Position = UDim2.fromOffset(s.x, s.y)

        -- мерцание
        s.twinklePhase = s.twinklePhase + s.twinkleSpeed * dt
        local t = (math.sin(s.twinklePhase) + 1) * 0.5
        local alpha = CONFIG.TWINKLE_MIN + (CONFIG.TWINKLE_MAX - CONFIG.TWINKLE_MIN) * t
        s.gui.BackgroundTransparency = 1 - alpha
        s.glow.Transparency = 1 - alpha * 0.45

        -- линия к курсору (исправлено: anchor в центре линии)
        local dx = mx - s.x
        local dy = my - s.y
        local distSq = dx * dx + dy * dy
        if distSq <= radiusSq and distSq > 1 then
            local dist = math.sqrt(distSq)
            local ratio = 1 - (dist / radius)
            local line = s.line

            -- ключевое исправление: размещаем линию по середине отрезка
            -- (звезда -> курсор) и поворачиваем вокруг этой середины,
            -- так как Rotation вращает GuiObject вокруг его центра.
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

    -- ---- ПАДАЮЩИЕ ЗВЁЗДЫ ----
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

        if sh.life >= sh.maxLife
           or sh.x > viewport.X + 200
           or sh.y > viewport.Y + 200 then
            sh.gui:Destroy()
            table.remove(shootingStars, i)
        end
    end

    -- ---- ВРАЩЕНИЕ РУННОГО КОЛЬЦА ----
    if isOpen then
        runeRing.Rotation = (runeRing.Rotation + dt * 18) % 360
        centerDiamond.Rotation = 45 + math.sin(timeAcc * 0.8) * 15
        -- лёгкая пульсация центрального кольца
        local p = 0.5 + math.sin(timeAcc * 1.4) * 0.5
        centerRingStroke.Transparency = 0.25 + p * 0.25
    end

    -- ---- ВНУТРЕННИЕ ЗВЁЗДЫ МЕНЮ ----
    if isOpen then
        for _, s in ipairs(innerStars) do
            s.phase = s.phase + s.speed * dt
            local ox = math.cos(s.phase) * s.amp
            local oy = math.sin(s.phase * 0.9) * s.amp
            s.gui.Position = UDim2.fromScale(s.baseX + ox, s.baseY + oy)

            s.twPhase = s.twPhase + s.twSpeed * dt
            local tw = (math.sin(s.twPhase) + 1) * 0.5
            s.gui.BackgroundTransparency = 0.15 + (1 - tw) * 0.55
        end
    end
end)

--==================================================================
-- ПОДДЕРЖКА ИЗМЕНЕНИЯ РАЗМЕРА ОКНА
--==================================================================
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local viewport = workspace.CurrentCamera.ViewportSize
    for _, s in ipairs(stars) do
        s.x = math.clamp(s.x, 0, viewport.X)
        s.y = math.clamp(s.y, 0, viewport.Y)
    end
end)
