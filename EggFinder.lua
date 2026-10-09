
-- ================================================
-- EGG FINDER V25
-- DETECTOR VISUAL DE HUEVOS ESPECIALES
-- SECRET / ETERNAL / DIVINE (PROVISIONAL)
-- ================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VERSION = "V25"
local DURATION = 360
local INTERVAL = 2
local CHUNK_SIZE = 1800
local NEST_DISTANCE = 12

local env = (getgenv and getgenv()) or _G

if type(env.EggFinderStop) == "function" then
    pcall(env.EggFinderStop)
end

local running = true
local generation = 0
local markersEnabled = true

local oldGui = playerGui:FindFirstChild("EggFinder")
if oldGui then
    oldGui:Destroy()
end

local oldMarkers = workspace:FindFirstChild(
    "EggFinderV25Markers"
)

if oldMarkers then
    oldMarkers:Destroy()
end

local markerFolder = Instance.new("Folder")
markerFolder.Name = "EggFinderV25Markers"
markerFolder.Parent = workspace

local report = {}
local summary = {}
local started = 0
local resetCount = 0
local partIndex = 1
local copyCount = 0

local nests = {}
local lastResults = {}
local lastSignature = ""
local lastEggCount = 0

local function elapsed()
    if started == 0 then
        return 0
    end

    return math.floor(os.clock() - started)
end

local function log(message, important)
    local line = string.format(
        "[+%03ds] %s",
        elapsed(),
        tostring(message)
    )

    table.insert(report, line)

    if important then
        table.insert(summary, line)
    end
end

local function formatNumber(n)
    return string.format("%.2f", n)
end

local function formatSize(size)
    return formatNumber(size.X)
        .. " x " .. formatNumber(size.Y)
        .. " x " .. formatNumber(size.Z)
end

-- ================================================
-- INTERFAZ
-- ================================================

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 540, 0, 490)
frame.Position = UDim2.new(0.5, -270, 0.10, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -42, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(28, 43, 55)
title.TextColor3 = Color3.fromRGB(65, 255, 170)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "EGG FINDER V25 | DETECTOR VISUAL"
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 42, 0, 35)
close.Position = UDim2.new(1, -42, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(175, 45, 45)
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -12, 0, 23)
status.Position = UDim2.new(0, 6, 0, 38)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(245, 215, 125)
status.Font = Enum.Font.Code
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Preparando..."
status.Parent = frame

local resultStatus = Instance.new("TextLabel")
resultStatus.Size = UDim2.new(1, -12, 0, 23)
resultStatus.Position = UDim2.new(0, 6, 0, 62)
resultStatus.BackgroundTransparency = 1
resultStatus.TextColor3 = Color3.fromRGB(105, 220, 255)
resultStatus.Font = Enum.Font.Code
resultStatus.TextSize = 12
resultStatus.TextXAlignment = Enum.TextXAlignment.Left
resultStatus.Text = "Analizando huevos..."
resultStatus.Parent = frame

local function makeButton(text, x, y, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.5, -6, 0, 32)
    button.Position = UDim2.new(x, 4, 0, y)
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.Text = text
    button.Parent = frame

    return button
end

local copyAll = makeButton(
    "COPIAR TODO", 0, 89,
    Color3.fromRGB(30, 125, 75)
)

local copySummary = makeButton(
    "COPIAR RESUMEN", 0.5, 89,
    Color3.fromRGB(35, 135, 135)
)

local copyPart = makeButton(
    "COPIAR PARTE 1", 0, 126,
    Color3.fromRGB(35, 100, 175)
)

local scanButton = makeButton(
    "ESCANEAR AHORA", 0.5, 126,
    Color3.fromRGB(125, 75, 175)
)

local markerButton = makeButton(
    "MARCADORES: ON", 0, 163,
    Color3.fromRGB(125, 100, 45)
)

local restartButton = makeButton(
    "REINICIAR", 0.5, 163,
    Color3.fromRGB(155, 65, 55)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -207)
scroll.Position = UDim2.new(0, 6, 0, 201)
scroll.BackgroundColor3 = Color3.fromRGB(9, 14, 22)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollingDirection = Enum.ScrollingDirection.XY
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(0, 1600, 0, 200)
output.BackgroundTransparency = 1
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextColor3 = Color3.fromRGB(140, 255, 180)
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.Parent = scroll

local function render()
    local visible = {}
    local first = math.max(1, #report - 79)

    for i = first, #report do
        table.insert(visible, report[i])
    end

    output.Text = table.concat(visible, "\n")

    local height = math.max(
        200,
        #visible * 17 + 20
    )

    output.Size = UDim2.new(0, 1600, 0, height)
    scroll.CanvasSize = UDim2.new(0, 1600, 0, height)
end

-- ================================================
-- LOCALIZACION DE NIDOS
-- ================================================

local function getPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Model") then
        local ok, cf = pcall(function()
            return obj:GetPivot()
        end)

        if ok then
            return cf.Position
        end
    end

    return nil
end

local function scanNests()
    nests = {}

    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild(
        "GuardAreas"
    )

    if not guards then
        log("ERROR: GuardAreas no encontrado", true)
        return
    end

    for _, area in ipairs(guards:GetChildren()) do
        local positions = {}

        for _, obj in ipairs(area:GetDescendants()) do
            if obj:IsA("Model")
                and obj.Name == "NestModel" then

                local fit = obj:FindFirstChild(
                    "EggFitBounds",
                    true
                )

                local pos = fit and getPosition(fit)
                    or getPosition(obj)

                if pos then
                    table.insert(positions, pos)
                end
            end
        end

        table.sort(positions, function(a, b)
            if math.abs(a.X - b.X) > 0.01 then
                return a.X < b.X
            end

            return a.Z < b.Z
        end)

        for i, pos in ipairs(positions) do
            table.insert(nests, {
                name = area.Name .. ":Nido_" .. i,
                position = pos
            })
        end
    end

    log("NIDOS ENCONTRADOS: " .. #nests, true)
end

local function nearestNest(position)
    if not position then
        return "SIN_POSICION"
    end

    local bestName = "SIN_NIDO"
    local bestDistance = math.huge

    for _, nest in ipairs(nests) do
        local distance = (
            nest.position - position
        ).Magnitude

        if distance < bestDistance then
            bestDistance = distance
            bestName = nest.name
        end
    end

    if bestDistance <= NEST_DISTANCE then
        return bestName
    end

    return "SIN_NIDO"
end

-- ================================================
-- ANALISIS DE COLOR
-- ================================================

local function colorCategory(color)
    local r = color.R
    local g = color.G
    local b = color.B

    local maxValue = math.max(r, g, b)
    local minValue = math.min(r, g, b)

    -- Blanco o muy claro.
    if minValue > 0.75 then
        return "WHITE"
    end

    -- Rosado / magenta.
    if r > 0.65
        and b > 0.40
        and g < r * 0.85 then

        return "PINK"
    end

    -- Dorado / amarillo.
    if r > 0.65
        and g > 0.38
        and b < g * 0.75 then

        return "GOLD"
    end

    if maxValue > 0.75 then
        return "BRIGHT"
    end

    return "OTHER"
end

local function analyzeColorSequence(sequence)
    local found = {
        PINK = false,
        GOLD = false,
        WHITE = false,
        BRIGHT = false
    }

    for _, keypoint in ipairs(
        sequence.Keypoints
    ) do
        local category = colorCategory(
            keypoint.Value
        )

        if found[category] ~= nil then
            found[category] = true
        end
    end

    return found
end

-- ================================================
-- ANALISIS VISUAL DEL HUEVO
-- ================================================

local function analyzeEgg(egg)
    local position = getPosition(egg)

    local size = Vector3.new(0, 0, 0)

    local ok, boxSize = pcall(function()
        local _, dimensions =
            egg:GetBoundingBox()

        return dimensions
    end)

    if ok then
        size = boxSize
    end

    local result = {
        instance = egg,
        name = egg.Name,
        nest = nearestNest(position),
        position = position,
        size = size,

        lights = 0,
        particles = 0,
        beams = 0,
        trails = 0,
        highlights = 0,

        pink = 0,
        gold = 0,
        white = 0,
        bright = 0,

        brightness = 0,
        particleRate = 0,

        classification = "NORMAL",
        score = 0
    }

    local function registerColor(category)
        if category == "PINK" then
            result.pink = result.pink + 1
        elseif category == "GOLD" then
            result.gold = result.gold + 1
        elseif category == "WHITE" then
            result.white = result.white + 1
        elseif category == "BRIGHT" then
            result.bright = result.bright + 1
        end
    end

    local function registerSequence(sequence)
        local categories =
            analyzeColorSequence(sequence)

        for category, present in pairs(categories) do
            if present then
                registerColor(category)
            end
        end
    end

    for _, obj in ipairs(egg:GetDescendants()) do

        if obj:IsA("PointLight")
            or obj:IsA("SpotLight")
            or obj:IsA("SurfaceLight") then

            if obj.Enabled then
                result.lights = result.lights + 1

                result.brightness =
                    result.brightness
                    + obj.Brightness

                registerColor(
                    colorCategory(obj.Color)
                )
            end

        elseif obj:IsA("ParticleEmitter") then
            if obj.Enabled then
                result.particles =
                    result.particles + 1

                result.particleRate =
                    result.particleRate
                    + obj.Rate

                registerSequence(obj.Color)
            end

        elseif obj:IsA("Beam") then
            if obj.Enabled then
                result.beams = result.beams + 1
                registerSequence(obj.Color)
            end

        elseif obj:IsA("Trail") then
            if obj.Enabled then
                result.trails = result.trails + 1
                registerSequence(obj.Color)
            end

        elseif obj:IsA("Highlight") then
            if obj.Enabled then
                result.highlights =
                    result.highlights + 1

                registerColor(
                    colorCategory(
                        obj.OutlineColor
                    )
                )

                registerColor(
                    colorCategory(
                        obj.FillColor
                    )
                )
            end
        end
    end

    local effects =
        result.lights
        + result.particles
        + result.beams
        + result.trails
        + result.highlights

    result.score =
        result.lights * 3
        + result.particles * 2
        + result.beams * 3
        + result.trails * 2
        + result.highlights * 3
        + math.min(result.brightness, 20)
        + math.min(result.particleRate / 20, 10)

    if effects > 0 then
        if result.gold > 0
            and result.score >= 8 then

            result.classification =
                "POSIBLE DIVINE"

        elseif result.pink > 0 then
            result.classification =
                "POSIBLE ETERNAL"

        else
            result.classification =
                "POSIBLE SECRET"
        end
    end

    return result
end

-- ================================================
-- MARCADORES VISUALES
-- ================================================

local function clearMarkers()
    for _, obj in ipairs(
        markerFolder:GetChildren()
    ) do
        obj:Destroy()
    end
end

local function markerColor(classification)
    if classification == "POSIBLE DIVINE" then
        return Color3.fromRGB(255, 205, 55)
    end

    if classification == "POSIBLE ETERNAL" then
        return Color3.fromRGB(255, 85, 205)
    end

    return Color3.fromRGB(80, 255, 170)
end

local function createMarker(result)
    if not markersEnabled then
        return
    end

    if result.classification == "NORMAL" then
        return
    end

    local egg = result.instance

    if not egg or not egg.Parent then
        return
    end

    local adornment = Instance.new("Highlight")
    adornment.Name = "EggFinderHighlight"
    adornment.Adornee = egg
    adornment.FillTransparency = 0.85
    adornment.OutlineTransparency = 0
    adornment.OutlineColor = markerColor(
        result.classification
    )
    adornment.FillColor = markerColor(
        result.classification
    )
    adornment.DepthMode =
        Enum.HighlightDepthMode.AlwaysOnTop

    adornment.Parent = markerFolder

    local adornee = egg.PrimaryPart

    if not adornee then
        adornee = egg:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end

    if not adornee then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EggFinderLabel"
    billboard.Adornee = adornee
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 230, 0, 65)
    billboard.StudsOffsetWorldSpace =
        Vector3.new(
            0,
            math.max(3, result.size.Y / 2 + 2),
            0
        )
    billboard.Parent = markerFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 =
        Color3.fromRGB(15, 20, 30)
    label.BackgroundTransparency = 0.25
    label.TextColor3 = markerColor(
        result.classification
    )
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextWrapped = true
    label.Text = result.classification
        .. "\n" .. result.nest
        .. "\nTamaño: "
        .. formatNumber(result.size.Y)

    label.Parent = billboard
end

-- ================================================
-- ESCANEO COMPLETO
-- ================================================

local function scanAll(reason)
    local folder = workspace:FindFirstChild(
        "AreaEggSlotsClient"
    )

    if not folder then
        log("ERROR: no existe AreaEggSlotsClient", true)
        return
    end

    local results = {}

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model") then
            table.insert(
                results,
                analyzeEgg(egg)
            )
        end
    end

    table.sort(results, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end

        return a.nest < b.nest
    end)

    lastResults = results
    lastEggCount = #results

    local secret = 0
    local eternal = 0
    local divine = 0
    local normal = 0

    local signatureParts = {}

    for _, result in ipairs(results) do
        if result.classification == "POSIBLE DIVINE" then
            divine = divine + 1
        elseif result.classification == "POSIBLE ETERNAL" then
            eternal = eternal + 1
        elseif result.classification == "POSIBLE SECRET" then
            secret = secret + 1
        else
            normal = normal + 1
        end

        table.insert(
            signatureParts,
            result.name .. ":"
            .. result.classification .. ":"
            .. math.floor(result.score * 10)
        )
    end

    table.sort(signatureParts)

    local signature = table.concat(
        signatureParts,
        "|"
    )

    if signature == lastSignature
        and reason == "AUTOMATICO" then
        return
    end

    lastSignature = signature

    clearMarkers()

    log("================================", true)
    log("ESCANEO VISUAL: " .. reason, true)
    log("HUEVOS: " .. #results, true)

    log(
        "POSIBLES: SECRET=" .. secret
        .. " ETERNAL=" .. eternal
        .. " DIVINE=" .. divine
        .. " NORMAL=" .. normal,
        true
    )

    log("================================", true)

    for _, result in ipairs(results) do
        if result.classification ~= "NORMAL" then

            log(
                "[" .. result.classification .. "] "
                .. result.nest
                .. " | TAM=" .. formatSize(result.size)
                .. " | SCORE="
                .. formatNumber(result.score),
                true
            )

            log(
                "  EFECTOS: "
                .. "L=" .. result.lights
                .. " P=" .. result.particles
                .. " B=" .. result.beams
                .. " T=" .. result.trails
                .. " H=" .. result.highlights
            )

            log(
                "  COLORES: "
                .. "PINK=" .. result.pink
                .. " GOLD=" .. result.gold
                .. " WHITE=" .. result.white
                .. " BRIGHT=" .. result.bright
            )

            createMarker(result)
        end
    end

    resultStatus.Text =
        "S:" .. secret
        .. " E:" .. eternal
        .. " D:" .. divine
        .. " N:" .. normal

    render()
end

-- ================================================
-- MONITOR DE REINICIOS
-- ================================================

local function getEggCount()
    local folder = workspace:FindFirstChild(
        "AreaEggSlotsClient"
    )

    if not folder then
        return 0
    end

    local n = 0

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model") then
            n = n + 1
        end
    end

    return n
end

local function monitor()
    generation = generation + 1
    local myGeneration = generation

    started = os.clock()
    report = {}
    summary = {}
    resetCount = 0
    lastSignature = ""

    log("EGG FINDER V25", true)
    log("DETECTOR VISUAL DE HUEVOS", true)

    scanNests()
    scanAll("INICIAL")

    local previousCount = getEggCount()
    local resetPending = false
    local resetStart = 0
    local lastHeartbeat = -1

    while running
        and generation == myGeneration
        and gui.Parent
        and elapsed() < DURATION do

        task.wait(INTERVAL)

        if not running
            or generation ~= myGeneration then
            return
        end

        local countNow = getEggCount()

        if not resetPending
            and previousCount >= 40
            and countNow <= 20 then

            resetPending = true
            resetStart = elapsed()

            log("REINICIO DETECTADO", true)
            log(
                "HUEVOS ANTES: "
                .. previousCount,
                true
            )

            clearMarkers()
            render()
        end

        if resetPending and countNow >= 60 then
            resetPending = false
            resetCount = resetCount + 1

            log(
                "REINICIO COMPLETADO #"
                .. resetCount,
                true
            )

            log(
                "RECARGA: "
                .. (elapsed() - resetStart)
                .. " SEGUNDOS",
                true
            )

            scanAll("DESPUES DEL REINICIO")
        elseif not resetPending then
            scanAll("AUTOMATICO")
        end

        previousCount = countNow

        local sec = elapsed()

        if sec % 30 == 0
            and sec ~= lastHeartbeat then

            lastHeartbeat = sec

            log(
                "HEARTBEAT | huevos="
                .. countNow
                .. " | reinicios="
                .. resetCount,
                true
            )

            render()
        end

        status.Text = string.format(
            "Tiempo %ds/360 | Huevos %d | Reinicios %d",
            sec,
            countNow,
            resetCount
        )
    end

    if generation ~= myGeneration then
        return
    end

    log("MONITOREO FINALIZADO", true)
    render()
end

-- ================================================
-- BOTONES
-- ================================================

local function copyText(value, label)
    copyCount = copyCount + 1

    local fn = setclipboard or toclipboard

    if type(fn) ~= "function" then
        resultStatus.Text = "CLIPBOARD NO DISPONIBLE"
        return false
    end

    local ok, err = pcall(function()
        fn(value)
    end)

    if ok then
        resultStatus.Text =
            label .. " ENVIADO | "
            .. #value .. " chars"
    else
        resultStatus.Text =
            "ERROR: " .. tostring(err)
    end

    return ok
end

copyAll.MouseButton1Click:Connect(function()
    copyText(
        table.concat(report, "\n"),
        "TODO"
    )
end)

copySummary.MouseButton1Click:Connect(function()
    copyText(
        table.concat(summary, "\n"),
        "RESUMEN"
    )
end)

copyPart.MouseButton1Click:Connect(function()
    local text = table.concat(report, "\n")

    local total = math.max(
        1,
        math.ceil(#text / CHUNK_SIZE)
    )

    if partIndex > total then
        partIndex = 1
    end

    local startIndex =
        (partIndex - 1) * CHUNK_SIZE + 1

    local part = string.sub(
        text,
        startIndex,
        startIndex + CHUNK_SIZE - 1
    )

    local ok = copyText(
        part,
        "PARTE " .. partIndex .. "/" .. total
    )

    if ok then
        partIndex = partIndex + 1
    end

    if partIndex > total then
        partIndex = 1
    end

    copyPart.Text = "COPIAR PARTE " .. partIndex
end)

scanButton.MouseButton1Click:Connect(function()
    scanAll("MANUAL")
end)

markerButton.MouseButton1Click:Connect(function()
    markersEnabled = not markersEnabled

    markerButton.Text = markersEnabled
        and "MARCADORES: ON"
        or "MARCADORES: OFF"

    clearMarkers()

    if markersEnabled then
        for _, result in ipairs(lastResults) do
            createMarker(result)
        end
    end
end)

restartButton.MouseButton1Click:Connect(function()
    generation = generation + 1
    partIndex = 1
    lastSignature = ""

    clearMarkers()
    task.spawn(monitor)
end)

close.MouseButton1Click:Connect(function()
    running = false
    generation = generation + 1

    clearMarkers()
    markerFolder:Destroy()

    if env.EggFinderStop then
        env.EggFinderStop = nil
    end

    gui:Destroy()
end)

task.spawn(monitor)
