--[[
    StarMenu.lua
    Красивое детализированное меню с радующими звёздами на заднем фоне.
    При приближении курсора к звезде от неё идёт линия к курсору.
    Открытие/закрытие меню — правый Shift.

    Помести этот LocalScript в StarterPlayer -> StarterPlayerScripts
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--==================================================================
-- НАСТРОЙКИ
--==================================================================
local CONFIG = {
    STAR_COUNT          = 90,       -- количество звёзд
    STAR_MIN_SIZE       = 2,
    STAR_MAX_SIZE       = 5,
    STAR_MIN_SPEED      = 8,        -- пикс/сек (плавный дрейф)
    STAR_MAX_SPEED      = 28,
    TWINKLE_MIN         = 0.35,     -- мин/макс прозрачность звёзд (мерцание)
    TWINKLE_MAX         = 1.0,
    TWINKLE_SPEED_MIN   = 0.8,
    TWINKLE_SPEED_MAX   = 2.4,
    CURSOR_RADIUS       = 140,      -- радиус «притяжения» линии к курсору
    LINE_THICKNESS      = 1,
    MENU_TINT_TRANSP    = 0.25,     -- прозрачность тонирующей подложки (меньше = темнее)
    MENU_BG_TRANSP      = 0.15,     -- прозрачность панели меню
    OPEN_KEY            = Enum.KeyCode.RightShift,
    TWEEN_TIME          = 0.45,
}

--==================================================================
-- ВСПОМОГАТЕЛЬНОЕ
--==================================================================
local rand = Random.new()

local function randomStarColor()
    -- мягкие тёплые/холодные оттенки звёзд
    local palette = {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(200, 220, 255),
        Color3.fromRGB(255, 230, 200),
        Color3.fromRGB(220, 200, 255),
        Color3.fromRGB(180, 240, 255),
        Color3.fromRGB(255, 200, 220),
    }
    return palette[rand:NextInteger(1, #palette)]
end

--==================================================================
-- ИНТЕРФЕЙС
--==================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarMenuGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 50
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Тонирующая подложка (затемнение всего экрана)
local tint = Instance.new("Frame")
tint.Name = "Tint"
tint.Size = UDim2.fromScale(1, 1)
tint.BackgroundColor3 = Color3.fromRGB(5, 6, 14)
tint.BackgroundTransparency = 1
tint.BorderSizePixel = 0
tint.ZIndex = 1
tint.Parent = screenGui

-- Радиальный градиент для глубины фона
local tintGradient = Instance.new("UIGradient")
tintGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(20, 14, 40)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 8, 22)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(2, 2, 8)),
})
tintGradient.Rotation = 90
tintGradient.Parent = tint

-- Слой для звёзд и линий
local starLayer = Instance.new("Frame")
starLayer.Name = "StarLayer"
starLayer.Size = UDim2.fromScale(1, 1)
starLayer.BackgroundTransparency = 1
starLayer.BorderSizePixel = 0
starLayer.ZIndex = 2
starLayer.Parent = screenGui

-- Контейнер меню
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.Size = UDim2.fromOffset(440, 520)
menu.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
menu.BackgroundTransparency = 1
menu.BorderSizePixel = 0
menu.ZIndex = 5
menu.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 18)
menuCorner.Parent = menu

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(120, 130, 220)
menuStroke.Thickness = 1.5
menuStroke.Transparency = 1
menuStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
menuStroke.Parent = menu

local menuGradient = Instance.new("UIGradient")
menuGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(40, 30, 70)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(15, 18, 35)),
})
menuGradient.Rotation = 135
menuGradient.Parent = menu

-- Внутренний контент меню
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 24)
padding.PaddingBottom = UDim.new(0, 24)
padding.PaddingLeft = UDim.new(0, 24)
padding.PaddingRight = UDim.new(0, 24)
padding.Parent = menu

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 14)
layout.Parent = menu

-- Заголовок
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 56)
title.BackgroundTransparency = 1
title.Text = "✦  МЕНЮ  ✦"
title.Font = Enum.Font.GothamBold
title.TextSize = 32
title.TextColor3 = Color3.fromRGB(235, 235, 255)
title.TextTransparency = 1
title.LayoutOrder = 1
title.Parent = menu

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(120, 130, 255)
titleStroke.Thickness = 1
titleStroke.Transparency = 0.5
titleStroke.Parent = title

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, 0, 0, 22)
subtitle.BackgroundTransparency = 1
subtitle.Text = "правый shift — открыть/закрыть"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 13
subtitle.TextColor3 = Color3.fromRGB(160, 165, 200)
subtitle.TextTransparency = 1
subtitle.LayoutOrder = 2
subtitle.Parent = menu

-- Разделитель
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(0.85, 0, 0, 1)
divider.BackgroundColor3 = Color3.fromRGB(120, 130, 220)
divider.BackgroundTransparency = 1
divider.BorderSizePixel = 0
divider.LayoutOrder = 3
divider.Parent = menu

-- Кнопки
local buttonDefs = {
    {text = "Играть",     icon = "▶"},
    {text = "Настройки",  icon = "⚙"},
    {text = "Инвентарь",  icon = "★"},
    {text = "Магазин",    icon = "♦"},
    {text = "Выход",      icon = "✕"},
}

local buttons = {}
for i, def in ipairs(buttonDefs) do
    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. def.text
    btn.Size = UDim2.new(1, 0, 0, 52)
    btn.BackgroundColor3 = Color3.fromRGB(30, 32, 55)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = def.icon .. "   " .. def.text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(220, 225, 255)
    btn.TextTransparency = 1
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = 10 + i
    btn.Parent = menu

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 22)
    pad.Parent = btn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 130, 220)
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    stroke.Parent = btn

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 45, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 28, 50)),
    })
    grad.Rotation = 90
    grad.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), {
            BackgroundTransparency = 0.05,
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), {
            Transparency = 0.1,
            Thickness = 1.8,
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), {
            BackgroundTransparency = 0.25,
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), {
            Transparency = 0.55,
            Thickness = 1,
        }):Play()
    end)

    table.insert(buttons, {button = btn, stroke = stroke})
end

-- Нижний хинт
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.Size = UDim2.new(1, 0, 0, 18)
hint.BackgroundTransparency = 1
hint.Text = "v1.0  ·  made with ✦"
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextColor3 = Color3.fromRGB(130, 135, 170)
hint.TextTransparency = 1
hint.LayoutOrder = 100
hint.Parent = menu

--==================================================================
-- ЗВЁЗДЫ
--==================================================================
local stars = {}

local function createStar()
    local size = rand:NextNumber(CONFIG.STAR_MIN_SIZE, CONFIG.STAR_MAX_SIZE)
    local img = Instance.new("Frame")
    img.Name = "Star"
    img.AnchorPoint = Vector2.new(0.5, 0.5)
    img.Size = UDim2.fromOffset(size, size)
    img.BackgroundColor3 = randomStarColor()
    img.BorderSizePixel = 0
    img.ZIndex = 2
    img.Parent = starLayer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = img

    -- мягкое сияние
    local glow = Instance.new("UIStroke")
    glow.Color = img.BackgroundColor3
    glow.Thickness = math.max(1, size * 0.4)
    glow.Transparency = 0.6
    glow.Parent = img

    local viewport = workspace.CurrentCamera.ViewportSize
    local star = {
        gui = img,
        glow = glow,
        x = rand:NextNumber(0, viewport.X),
        y = rand:NextNumber(0, viewport.Y),
        vx = rand:NextNumber(-CONFIG.STAR_MAX_SPEED, CONFIG.STAR_MAX_SPEED),
        vy = rand:NextNumber(-CONFIG.STAR_MAX_SPEED, CONFIG.STAR_MAX_SPEED),
        size = size,
        twinklePhase = rand:NextNumber(0, math.pi * 2),
        twinkleSpeed = rand:NextNumber(CONFIG.TWINKLE_SPEED_MIN, CONFIG.TWINKLE_SPEED_MAX),
        line = nil,
    }
    -- нормируем скорость до диапазона
    local speedMag = math.sqrt(star.vx * star.vx + star.vy * star.vy)
    if speedMag > 0 then
        local target = rand:NextNumber(CONFIG.STAR_MIN_SPEED, CONFIG.STAR_MAX_SPEED)
        star.vx = star.vx / speedMag * target
        star.vy = star.vy / speedMag * target
    end
    return star
end

for i = 1, CONFIG.STAR_COUNT do
    table.insert(stars, createStar())
end

-- Контейнер для линий (рисуем как тонкие повёрнутые Frame'ы)
local function makeLine()
    local line = Instance.new("Frame")
    line.Name = "Line"
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = Color3.fromRGB(200, 210, 255)
    line.BackgroundTransparency = 1
    line.ZIndex = 2
    line.Visible = false
    line.Parent = starLayer
    return line
end

for _, s in ipairs(stars) do
    s.line = makeLine()
end

--==================================================================
-- АНИМАЦИЯ ОТКРЫТИЯ / ЗАКРЫТИЯ
--==================================================================
local isOpen = false
local isAnimating = false

local function setOpen(open)
    if isAnimating then return end
    isAnimating = true
    isOpen = open
    screenGui.Enabled = true

    local ti = TweenInfo.new(CONFIG.TWEEN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    TweenService:Create(tint, ti, {
        BackgroundTransparency = open and CONFIG.MENU_TINT_TRANSP or 1,
    }):Play()

    TweenService:Create(menu, ti, {
        BackgroundTransparency = open and CONFIG.MENU_BG_TRANSP or 1,
        Size = open and UDim2.fromOffset(440, 520) or UDim2.fromOffset(380, 460),
    }):Play()

    TweenService:Create(menuStroke, ti, {
        Transparency = open and 0.1 or 1,
    }):Play()

    TweenService:Create(title,    ti, {TextTransparency = open and 0   or 1}):Play()
    TweenService:Create(subtitle, ti, {TextTransparency = open and 0.1 or 1}):Play()
    TweenService:Create(hint,     ti, {TextTransparency = open and 0.3 or 1}):Play()
    TweenService:Create(divider,  ti, {BackgroundTransparency = open and 0.4 or 1}):Play()

    for _, b in ipairs(buttons) do
        TweenService:Create(b.button, ti, {
            BackgroundTransparency = open and 0.25 or 1,
            TextTransparency = open and 0 or 1,
        }):Play()
        TweenService:Create(b.stroke, ti, {
            Transparency = open and 0.55 or 1,
        }):Play()
    end

    task.delay(CONFIG.TWEEN_TIME, function()
        isAnimating = false
        if not open then
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
RunService.RenderStepped:Connect(function(dt)
    if not screenGui.Enabled then return end

    local viewport = workspace.CurrentCamera.ViewportSize
    local mousePos = UserInputService:GetMouseLocation() -- уже включает GUI inset = 0 здесь, но мы используем IgnoreGuiInset
    -- IgnoreGuiInset = true, но GetMouseLocation возвращает с учётом topbar inset (~36px).
    -- Компенсируем смещение, чтобы линии шли точно к курсору.
    local guiInset = game:GetService("GuiService"):GetGuiInset()
    local mx = mousePos.X
    local my = mousePos.Y + guiInset.Y

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
        local t = (math.sin(s.twinklePhase) + 1) * 0.5  -- 0..1
        local alpha = CONFIG.TWINKLE_MIN + (CONFIG.TWINKLE_MAX - CONFIG.TWINKLE_MIN) * t
        s.gui.BackgroundTransparency = 1 - alpha
        s.glow.Transparency = 1 - alpha * 0.5

        -- линия к курсору
        local dx = mx - s.x
        local dy = my - s.y
        local distSq = dx * dx + dy * dy
        if distSq <= radiusSq then
            local dist = math.sqrt(distSq)
            local ratio = 1 - (dist / radius)  -- ближе = ярче
            local line = s.line
            line.Visible = true
            line.Position = UDim2.fromOffset(s.x, s.y)
            line.Size = UDim2.fromOffset(dist, CONFIG.LINE_THICKNESS)
            line.Rotation = math.deg(math.atan2(dy, dx))
            line.BackgroundTransparency = 1 - (ratio * 0.6) * alpha
        else
            s.line.Visible = false
        end
    end
end)

--==================================================================
-- Поддержка изменения размера окна
--==================================================================
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local viewport = workspace.CurrentCamera.ViewportSize
    for _, s in ipairs(stars) do
        s.x = math.clamp(s.x, 0, viewport.X)
        s.y = math.clamp(s.y, 0, viewport.Y)
    end
end)
