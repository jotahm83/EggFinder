
-- ================================================
-- EGG FINDER V24
-- ANALIZADOR DE DATOS DE HUEVOS
-- INSPECCION + REINICIOS + EXPORTACION
-- ================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DURATION = 360
local INTERVAL = 2
local CHUNK_SIZE = 1800

local env = (getgenv and getgenv()) or _G

if type(env.EggFinderStop) == "function" then
    pcall(env.EggFinderStop)
end

local running = true
local generation = 0

env.EggFinderStop = function()
    running = false
    generation = generation + 1
end

local oldGui = playerGui:FindFirstChild("EggFinder")
if oldGui then
    oldGui:Destroy()
end

-- ================================================
-- VARIABLES
-- ================================================

local started = 0
local report = {}
local summary = {}
local resetCount = 0
local copyCount = 0
local partIndex = 1

local KEYWORDS = {
    "egg",
    "monster",
    "pet",
    "rarity",
    "secret",
    "eternal",
    "divine",
    "income",
    "money",
    "earn",
    "reward",
    "hatch",
    "spawn",
    "state"
}

local function elapsed()
    if started == 0 then
        return 0
    end

    return math.floor(os.clock() - started)
end

local function add(message, important)
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

local function matches(text)
    text = string.lower(tostring(text))

    for _, keyword in ipairs(KEYWORDS) do
        if string.find(text, keyword, 1, true) then
            return true
        end
    end

    return false
end

local function safeValue(value)
    local valueType = typeof(value)

    if valueType == "Instance" then
        return value:GetFullName()
    end

    local result = tostring(value)

    if #result > 160 then
        result = string.sub(result, 1, 160)
            .. "...[RECORTADO]"
    end

    return result
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
frame.Size = UDim2.new(0, 530, 0, 480)
frame.Position = UDim2.new(0.5, -265, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(16, 21, 31)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -42, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(29, 42, 56)
title.TextColor3 = Color3.fromRGB(65, 255, 170)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "EGG FINDER V24 | ANALIZADOR"
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
status.TextColor3 = Color3.fromRGB(240, 220, 135)
status.Font = Enum.Font.Code
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Preparando..."
status.Parent = frame

local copyStatus = Instance.new("TextLabel")
copyStatus.Size = UDim2.new(1, -12, 0, 24)
copyStatus.Position = UDim2.new(0, 6, 0, 62)
copyStatus.BackgroundTransparency = 1
copyStatus.TextColor3 = Color3.fromRGB(100, 220, 255)
copyStatus.Font = Enum.Font.Code
copyStatus.TextSize = 12
copyStatus.TextXAlignment = Enum.TextXAlignment.Left
copyStatus.Text = "COPIAS: 0"
copyStatus.Parent = frame

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
    "COPIAR TODO",
    0, 89,
    Color3.fromRGB(30, 125, 75)
)

local copySummary = makeButton(
    "COPIAR RESUMEN",
    0.5, 89,
    Color3.fromRGB(35, 135, 135)
)

local copyPart = makeButton(
    "COPIAR PARTE 1",
    0, 126,
    Color3.fromRGB(35, 100, 175)
)

local inspectButton = makeButton(
    "INSPECCIONAR AHORA",
    0.5, 126,
    Color3.fromRGB(125, 75, 175)
)

local saveButton = makeButton(
    "GUARDAR TXT",
    0, 163,
    Color3.fromRGB(130, 105, 45)
)

local restartButton = makeButton(
    "REINICIAR",
    0.5, 163,
    Color3.fromRGB(155, 65, 55)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -207)
scroll.Position = UDim2.new(0, 6, 0, 201)
scroll.BackgroundColor3 = Color3.fromRGB(10, 15, 23)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollingDirection = Enum.ScrollingDirection.XY
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(0, 1450, 0, 200)
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

    output.Size = UDim2.new(0, 1450, 0, height)
    scroll.CanvasSize = UDim2.new(0, 1450, 0, height)
end

-- ================================================
-- INSPECCION DE DATOS
-- ================================================

local function inspectAttributes(instance, prefix)
    local attrs = instance:GetAttributes()
    local found = 0

    for name, value in pairs(attrs) do
        if matches(name) or matches(value) then
            add(
                prefix .. " ATTRIBUTE "
                .. name .. "=" .. safeValue(value),
                true
            )

            found = found + 1
        end
    end

    return found
end

local function inspectValues(root, prefix, limit)
    local found = 0

    for _, obj in ipairs(root:GetDescendants()) do
        if found >= limit then
            add(
                prefix .. " LIMITE DE RESULTADOS: "
                .. limit
            )
            break
        end

        if obj:IsA("ValueBase") then
            if matches(obj.Name)
                or matches(obj.Parent.Name) then

                local ok, value = pcall(function()
                    return obj.Value
                end)

                if ok then
                    add(
                        prefix .. " VALUE "
                        .. obj:GetFullName()
                        .. "=" .. safeValue(value),
                        true
                    )

                    found = found + 1
                end
            end
        end
    end

    return found
end

local function inspectEggs()
    add("================================", true)
    add("INSPECCION DE HUEVOS", true)

    local folder = workspace:FindFirstChild(
        "AreaEggSlotsClient"
    )

    if not folder then
        add("ERROR: AreaEggSlotsClient no existe", true)
        return
    end

    local eggCount = 0
    local attrCount = 0
    local valueCount = 0

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model") then
            eggCount = eggCount + 1

            local foundAttributes = inspectAttributes(
                egg,
                "EGG " .. egg.Name
            )

            attrCount = attrCount + foundAttributes

            -- Buscar valores en descendientes.
            for _, obj in ipairs(egg:GetDescendants()) do
                if obj:IsA("ValueBase") then
                    local ok, value = pcall(function()
                        return obj.Value
                    end)

                    if ok and (
                        matches(obj.Name)
                        or matches(value)
                    ) then
                        add(
                            "EGG " .. egg.Name
                            .. " VALUE "
                            .. obj.Name
                            .. "=" .. safeValue(value),
                            true
                        )

                        valueCount = valueCount + 1
                    end
                end

                -- Algunos datos pueden estar
                -- guardados en atributos de hijos.
                if obj:IsA("Folder")
                    or obj:IsA("Configuration")
                    or obj:IsA("Model") then

                    attrCount = attrCount
                        + inspectAttributes(
                            obj,
                            "CHILD " .. egg.Name
                        )
                end
            end
        end
    end

    add(
        "HUEVOS INSPECCIONADOS: "
        .. eggCount,
        true
    )

    add(
        "ATRIBUTOS RELEVANTES: "
        .. attrCount,
        true
    )

    add(
        "VALORES RELEVANTES: "
        .. valueCount,
        true
    )

    add("FIN INSPECCION HUEVOS", true)
end

-- ================================================
-- BUSQUEDA EN REPLICATEDSTORAGE
-- ================================================

local function inspectReplicated()
    add("================================", true)
    add("BUSQUEDA EN REPLICATEDSTORAGE", true)

    local matchesFound = 0
    local limit = 120

    for _, obj in ipairs(
        ReplicatedStorage:GetDescendants()
    ) do
        if matchesFound >= limit then
            add("LIMITE DE RUTAS ALCANZADO", true)
            break
        end

        if matches(obj.Name) then
            matchesFound = matchesFound + 1

            add(
                "RUTA [" .. obj.ClassName .. "] "
                .. obj:GetFullName()
            )

            if obj:IsA("ValueBase") then
                local ok, value = pcall(function()
                    return obj.Value
                end)

                if ok then
                    add(
                        "  VALOR=" .. safeValue(value),
                        true
                    )
                end
            end

            inspectAttributes(
                obj,
                "REPLICATED"
            )
        end
    end

    add(
        "RUTAS RELEVANTES: "
        .. matchesFound,
        true
    )

    add(
        "NOTA: nombres de ModuleScript "
        .. "no revelan automaticamente "
        .. "sus tablas internas.",
        true
    )
end

-- ================================================
-- MONITOR DE REINICIOS
-- ================================================

local function eggSnapshot()
    local state = {}

    local folder = workspace:FindFirstChild(
        "AreaEggSlotsClient"
    )

    if not folder then
        return state
    end

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model") then
            state[egg] = {
                name = egg.Name,
                source = egg:GetAttribute(
                    "PreparedSourceName"
                )
            }
        end
    end

    return state
end

local function count(state)
    local n = 0

    for _ in pairs(state) do
        n = n + 1
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
    partIndex = 1

    add("================================", true)
    add("EGG FINDER V24", true)
    add("================================", true)
    add("DURACION: 360 SEGUNDOS", true)

    local previous = eggSnapshot()

    add(
        "HUEVOS INICIALES: "
        .. count(previous),
        true
    )

    inspectEggs()
    inspectReplicated()
    render()

    local resetPending = false
    local resetStart = 0
    local lastHeartbeat = -1

    while running
        and myGeneration == generation
        and gui.Parent
        and elapsed() < DURATION do

        task.wait(INTERVAL)

        if not running
            or myGeneration ~= generation then
            return
        end

        local current = eggSnapshot()

        local oldCount = count(previous)
        local newCount = count(current)

        local removed = 0

        for obj in pairs(previous) do
            if not current[obj] then
                removed = removed + 1
            end
        end

        if not resetPending
            and oldCount >= 40
            and removed >= 20 then

            resetPending = true
            resetStart = elapsed()

            add("================================", true)
            add("REINICIO DETECTADO", true)
            add(
                "HUEVOS ANTES: " .. oldCount,
                true
            )
            add(
                "DESAPARECIDOS: " .. removed,
                true
            )

            render()
        end

        if resetPending and newCount >= 60 then
            resetPending = false
            resetCount = resetCount + 1

            add("================================", true)
            add(
                "REINICIO COMPLETADO #"
                .. resetCount,
                true
            )

            add(
                "HUEVOS NUEVOS: "
                .. newCount,
                true
            )

            add(
                "TIEMPO DE RECARGA: "
                .. (elapsed() - resetStart)
                .. " SEGUNDOS",
                true
            )

            -- Inspeccionar nuevamente tras
            -- aparecer los huevos.
            inspectEggs()

            render()
        end

        if resetPending
            and elapsed() - resetStart > 45 then

            add(
                "REINICIO SIN RECARGA COMPLETA",
                true
            )

            resetPending = false
        end

        previous = current

        local sec = elapsed()

        if sec % 30 == 0
            and sec ~= lastHeartbeat then

            lastHeartbeat = sec

            add(
                "HEARTBEAT | huevos="
                .. newCount
                .. " | reinicios="
                .. resetCount,
                true
            )

            render()
        end

        status.Text = string.format(
            "Tiempo %ds/360 | Huevos %d | Reinicios %d",
            sec,
            newCount,
            resetCount
        )
    end

    if myGeneration ~= generation then
        return
    end

    add("================================", true)
    add("MONITOREO FINALIZADO", true)
    add(
        "REINICIOS: " .. resetCount,
        true
    )

    status.Text = "MONITOREO FINALIZADO"
    render()
end

-- ================================================
-- COPIAR Y GUARDAR
-- ================================================

local function copyText(value, label)
    copyCount = copyCount + 1

    local fn = setclipboard or toclipboard

    if type(fn) ~= "function" then
        copyStatus.Text = "PORTAPAPELES NO DISPONIBLE"
        return false
    end

    local ok, err = pcall(function()
        fn(value)
    end)

    if ok then
        copyStatus.Text = string.format(
            "CLIC #%d | %s | %d chars | ENVIADO",
            copyCount,
            label,
            #value
        )
    else
        copyStatus.Text = "ERROR: " .. tostring(err)
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

    local chunk = string.sub(
        text,
        startIndex,
        startIndex + CHUNK_SIZE - 1
    )

    local ok = copyText(
        chunk,
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

inspectButton.MouseButton1Click:Connect(function()
    add("INSPECCION MANUAL", true)

    inspectEggs()
    inspectReplicated()

    render()
end)

saveButton.MouseButton1Click:Connect(function()
    if type(writefile) ~= "function" then
        copyStatus.Text = "GUARDAR TXT NO DISPONIBLE"
        return
    end

    local filename = "EggFinder_V24_"
        .. os.date("%H%M%S")
        .. ".txt"

    local ok, err = pcall(function()
        writefile(
            filename,
            table.concat(report, "\n")
        )
    end)

    if ok then
        copyStatus.Text = "GUARDADO: " .. filename
    else
        copyStatus.Text = "ERROR: " .. tostring(err)
    end
end)

restartButton.MouseButton1Click:Connect(function()
    generation = generation + 1
    copyCount = 0
    partIndex = 1

    copyStatus.Text = "COPIAS: 0"
    copyPart.Text = "COPIAR PARTE 1"

    task.spawn(monitor)
end)

close.MouseButton1Click:Connect(function()
    running = false
    generation = generation + 1

    if env.EggFinderStop then
        env.EggFinderStop = nil
    end

    gui:Destroy()
end)

task.spawn(monitor)
