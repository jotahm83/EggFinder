
-- ==============================================
-- EGG FINDER V23.3
-- MONITOR DE REINICIOS Y HUEVOS
-- INFORME COMPACTO / COPIA MEJORADA
-- ==============================================

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local DURATION = 360
local INTERVAL = 1
local MAX_DISTANCE = 5
local CHUNK_SIZE = 1800

-- Detener una version anterior
local env = (getgenv and getgenv()) or _G

if type(env.EggFinderStop) == "function" then
    pcall(env.EggFinderStop)
end

local running = true
local session = 0
local started = 0
local lines = {}
local summaryLines = {}
local nests = {}
local events = 0
local resets = 0
local copyClicks = 0
local chunkIndex = 1
local currentEggCount = 0

env.EggFinderStop = function()
    running = false
    session = session + 1
end

local old = pg:FindFirstChild("EggFinder")
if old then
    old:Destroy()
end

-- ==============================================
-- INTERFAZ
-- ==============================================

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 530, 0, 480)
frame.Position = UDim2.new(0.5, -265, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 21, 31)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 34)
title.BackgroundColor3 = Color3.fromRGB(28, 42, 54)
title.TextColor3 = Color3.fromRGB(70, 255, 170)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "EGG FINDER V23.3 | REINICIOS"
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 40, 0, 34)
close.Position = UDim2.new(1, -40, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.Parent = frame

local monitorStatus = Instance.new("TextLabel")
monitorStatus.Size = UDim2.new(1, -12, 0, 23)
monitorStatus.Position = UDim2.new(0, 6, 0, 37)
monitorStatus.BackgroundTransparency = 1
monitorStatus.TextColor3 = Color3.fromRGB(245, 215, 130)
monitorStatus.Font = Enum.Font.Code
monitorStatus.TextSize = 12
monitorStatus.TextXAlignment = Enum.TextXAlignment.Left
monitorStatus.Text = "Preparando..."
monitorStatus.Parent = frame

local copyStatus = Instance.new("TextLabel")
copyStatus.Size = UDim2.new(1, -12, 0, 24)
copyStatus.Position = UDim2.new(0, 6, 0, 60)
copyStatus.BackgroundTransparency = 1
copyStatus.TextColor3 = Color3.fromRGB(100, 220, 255)
copyStatus.Font = Enum.Font.Code
copyStatus.TextSize = 12
copyStatus.TextXAlignment = Enum.TextXAlignment.Left
copyStatus.Text = "COPIAS: 0"
copyStatus.Parent = frame

local function makeButton(text, x, y, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -6, 0, 32)
    b.Position = UDim2.new(x, 4, 0, y)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Text = text
    b.Parent = frame
    return b
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

local copyTest = makeButton(
    "COPIAR PRUEBA", 0.5, 126,
    Color3.fromRGB(125, 75, 170)
)

local saveButton = makeButton(
    "GUARDAR TXT", 0, 163,
    Color3.fromRGB(130, 105, 45)
)

local restart = makeButton(
    "REINICIAR ANALISIS", 0.5, 163,
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
output.Size = UDim2.new(0, 1350, 0, 200)
output.BackgroundTransparency = 1
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextColor3 = Color3.fromRGB(135, 255, 180)
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.Parent = scroll

-- ==============================================
-- REGISTRO COMPACTO
-- ==============================================

local function elapsed()
    if started == 0 then
        return 0
    end
    return math.floor(os.clock() - started)
end

local function log(message, important)
    local entry = string.format(
        "[+%03ds] %s",
        elapsed(),
        tostring(message)
    )

    table.insert(lines, entry)

    if important then
        table.insert(summaryLines, entry)
    end
end

local function render()
    local visible = {}
    local first = math.max(1, #lines - 79)

    for i = first, #lines do
        table.insert(visible, lines[i])
    end

    output.Text = table.concat(visible, "\n")

    local height = math.max(200, #visible * 17 + 20)

    output.Size = UDim2.new(0, 1350, 0, height)
    scroll.CanvasSize = UDim2.new(0, 1350, 0, height)
end

local function fullReport()
    return table.concat(lines, "\n")
end

local function summaryReport()
    return table.concat(summaryLines, "\n")
end

-- ==============================================
-- LOCALIZACION DE NIDOS
-- ==============================================

local function getPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Model") then
        local ok, pivot = pcall(function()
            return obj:GetPivot()
        end)

        if ok then
            return pivot.Position
        end
    end

    return nil
end

local function scanNests()
    nests = {}

    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")

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

    log("NIDOS LOCALIZADOS: " .. #nests, true)
end

local function nearestNest(pos)
    if not pos then
        return "SIN_POSICION"
    end

    local best = nil
    local minDistance = math.huge

    for _, nest in ipairs(nests) do
        local distance = (nest.position - pos).Magnitude

        if distance < minDistance then
            minDistance = distance
            best = nest
        end
    end

    if best and minDistance <= MAX_DISTANCE then
        return best.name
    end

    return "SIN_NIDO"
end

-- ==============================================
-- LECTURA DE HUEVOS
-- ==============================================

local function metadata(model)
    local attrs = {}

    for k, v in pairs(model:GetAttributes()) do
        -- RBX_ReimportId suele ser metadato de
        -- importacion, no una rareza.
        if k ~= "RBX_ReimportId" then
            table.insert(
                attrs,
                tostring(k) .. "=" .. tostring(v)
            )
        end
    end

    for _, tag in ipairs(CollectionService:GetTags(model)) do
        table.insert(attrs, "TAG=" .. tag)
    end

    table.sort(attrs)

    return table.concat(attrs, ";")
end

local function sourceName(model)
    local value = model:GetAttribute("PreparedSourceName")

    if value == nil then
        return "-"
    end

    return tostring(value)
end

local function signature(model)
    local meshes = {}

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("MeshPart") then
            table.insert(meshes, tostring(obj.MeshId))
        elseif obj:IsA("SpecialMesh") then
            table.insert(meshes, tostring(obj.MeshId))
        end
    end

    table.sort(meshes)

    -- Identificador visual compacto.
    return table.concat(meshes, "|")
end

local function snapshot()
    local result = {}

    local folder = workspace:FindFirstChild(
        "AreaEggSlotsClient"
    )

    if not folder then
        return result, false
    end

    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local pos = getPosition(obj)
            local nest = nearestNest(pos)

            result[obj] = {
                name = obj.Name,
                nest = nest,
                source = sourceName(obj),
                meta = metadata(obj),
                mesh = signature(obj)
            }
        end
    end

    return result, true
end

local function count(state)
    local n = 0

    for _ in pairs(state) do
        n = n + 1
    end

    return n
end

local function sorted(state)
    local items = {}

    for _, data in pairs(state) do
        table.insert(items, data)
    end

    table.sort(items, function(a, b)
        return a.nest .. a.name
            < b.nest .. b.name
    end)

    return items
end

local function describe(data)
    local text = data.nest .. " | " .. data.name

    if data.source ~= "-" then
        text = text .. " | SOURCE=" .. data.source
    end

    if data.meta ~= "" then
        text = text .. " | META=" .. data.meta
    end

    return text
end

local function logEggs(label, state)
    log("=== " .. label .. " ===", true)

    for _, data in ipairs(sorted(state)) do
        log(describe(data))
    end
end

-- ==============================================
-- COMPARACION POR NIDO
-- ==============================================

local function byNest(state)
    local result = {}

    for _, data in pairs(state) do
        result[data.nest] = data
    end

    return result
end

local function compareCycles(before, after)
    local oldByNest = byNest(before)
    local newByNest = byNest(after)

    log("=== COMPARACION DE CICLOS ===", true)

    local changed = 0
    local same = 0

    local names = {}

    for nest in pairs(oldByNest) do
        names[nest] = true
    end

    for nest in pairs(newByNest) do
        names[nest] = true
    end

    local ordered = {}

    for nest in pairs(names) do
        table.insert(ordered, nest)
    end

    table.sort(ordered)

    for _, nest in ipairs(ordered) do
        local oldEgg = oldByNest[nest]
        local newEgg = newByNest[nest]

        if oldEgg and newEgg then
            if oldEgg.name ~= newEgg.name
                or oldEgg.source ~= newEgg.source
                or oldEgg.mesh ~= newEgg.mesh then

                changed = changed + 1

                log("CAMBIO: " .. nest)
                log("  ANTES: " .. describe(oldEgg))
                log("  AHORA: " .. describe(newEgg))
            else
                same = same + 1
            end

        elseif oldEgg and not newEgg then
            changed = changed + 1
            log("SIN HUEVO NUEVO: " .. nest)

        elseif newEgg and not oldEgg then
            changed = changed + 1
            log("NUEVO NIDO OCUPADO: " .. nest)
        end
    end

    log(
        "RESULTADO: cambiados="
        .. changed .. " iguales=" .. same,
        true
    )
end

-- ==============================================
-- MONITOR PRINCIPAL
-- ==============================================

local function monitor()
    session = session + 1
    local mySession = session

    started = os.clock()
    lines = {}
    summaryLines = {}
    events = 0
    resets = 0
    chunkIndex = 1
    currentEggCount = 0

    log("================================", true)
    log("EGG FINDER V23.3", true)
    log("================================", true)
    log("MONITOREO: 360 SEGUNDOS", true)
    log("INTERVALO: 1 SEGUNDO", true)

    scanNests()

    local previous, available = snapshot()
    currentEggCount = count(previous)

    log(
        "CARPETA DISPONIBLE: "
        .. tostring(available),
        true
    )

    log(
        "HUEVOS INICIALES: "
        .. currentEggCount,
        true
    )

    logEggs("HUEVOS INICIALES", previous)
    render()

    local cycleBefore = nil
    local resetPending = false
    local resetStart = 0
    local lastHeartbeat = -1

    while running
        and mySession == session
        and gui.Parent
        and elapsed() < DURATION do

        task.wait(INTERVAL)

        if not running or mySession ~= session then
            return
        end

        local current, exists = snapshot()

        if not exists then
            monitorStatus.Text = "Carpeta no disponible"
            continue
        end

        local oldCount = count(previous)
        local newCount = count(current)
        currentEggCount = newCount

        local removed = {}
        local added = {}

        for obj, data in pairs(previous) do
            if not current[obj] then
                table.insert(removed, data)
            end
        end

        for obj, data in pairs(current) do
            if not previous[obj] then
                table.insert(added, data)
            end
        end

        -- Solo registrar cambios de presencia.
        -- No registrar animaciones o cambios
        -- visuales continuos.

        if #removed > 0 or #added > 0 then
            events = events + 1

            log(
                "EVENTO #" .. events
                .. " | huevos=" .. oldCount
                .. "->" .. newCount
                .. " | -" .. #removed
                .. " +" .. #added,
                true
            )
        end

        -- Detectar caida masiva de huevos.
        if not resetPending
            and oldCount >= 40
            and #removed >= 20 then

            resetPending = true
            resetStart = elapsed()
            cycleBefore = previous

            log("================================", true)
            log("POSIBLE REINICIO DETECTADO", true)
            log(
                "DESAPARECIERON "
                .. #removed .. " HUEVOS",
                true
            )
            log("================================", true)
        end

        -- Esperar a que reaparezcan los huevos.
        if resetPending then
            if newCount >= 60 then
                resets = resets + 1

                log("================================", true)
                log(
                    "REINICIO COMPLETADO #"
                    .. resets,
                    true
                )
                log(
                    "TIEMPO DE RECARGA: "
                    .. (elapsed() - resetStart)
                    .. " SEGUNDOS",
                    true
                )
                log(
                    "HUEVOS DESPUES: "
                    .. newCount,
                    true
                )

                if cycleBefore then
                    compareCycles(cycleBefore, current)
                end

                logEggs(
                    "HUEVOS DESPUES DEL REINICIO",
                    current
                )

                log("================================", true)

                resetPending = false
                cycleBefore = nil
                render()

            elseif elapsed() - resetStart > 45 then
                log(
                    "AVISO: reinicio sin recarga "
                    .. "completa en 45 segundos",
                    true
                )

                resetPending = false
                cycleBefore = nil
            end
        end

        -- Registrar huevos que aparecen fuera
        -- del proceso de reinicio.
        if not resetPending
            and #added > 0
            and #added < 20 then

            table.sort(added, function(a, b)
                return a.nest .. a.name
                    < b.nest .. b.name
            end)

            for _, data in ipairs(added) do
                log("APARECIO: " .. describe(data))
            end
        end

        previous = current

        local sec = elapsed()

        if sec % 15 == 0
            and sec ~= lastHeartbeat then

            lastHeartbeat = sec

            log(
                "HEARTBEAT | huevos="
                .. newCount
                .. " | reinicios="
                .. resets,
                true
            )

            render()
        end

        monitorStatus.Text = string.format(
            "Tiempo %ds/360 | Huevos %d | Reinicios %d",
            sec,
            newCount,
            resets
        )
    end

    if mySession ~= session then
        return
    end

    log("================================", true)
    log("FIN DEL MONITOREO", true)
    log("REINICIOS DETECTADOS: " .. resets, true)
    log("EVENTOS: " .. events, true)

    monitorStatus.Text = "MONITOREO FINALIZADO"
    render()
end

-- ==============================================
-- COPIADO Y EXPORTACION
-- ==============================================

local function copyText(value, label)
    copyClicks = copyClicks + 1

    local number = copyClicks

    copyStatus.Text = string.format(
        "CLIC #%d | %s | %d caracteres",
        number,
        label,
        #value
    )

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
            number,
            label,
            #value
        )
    else
        copyStatus.Text = "ERROR: " .. tostring(err)
    end

    return ok
end

copyAll.MouseButton1Click:Connect(function()
    copyText(fullReport(), "TODO")
end)

copySummary.MouseButton1Click:Connect(function()
    copyText(summaryReport(), "RESUMEN")
end)

copyTest.MouseButton1Click:Connect(function()
    copyText(
        "EGG FINDER V23.3 PRUEBA #"
        .. (copyClicks + 1)
        .. " TIEMPO=" .. elapsed(),
        "PRUEBA"
    )
end)

copyPart.MouseButton1Click:Connect(function()
    local report = fullReport()

    local total = math.max(
        1,
        math.ceil(#report / CHUNK_SIZE)
    )

    if chunkIndex > total then
        chunkIndex = 1
    end

    local first = (chunkIndex - 1) * CHUNK_SIZE + 1

    local part = string.sub(
        report,
        first,
        first + CHUNK_SIZE - 1
    )

    local selected = chunkIndex

    local ok = copyText(
        part,
        "PARTE " .. selected .. "/" .. total
    )

    if ok then
        chunkIndex = chunkIndex + 1
    end

    if chunkIndex > total then
        chunkIndex = 1
    end

    copyPart.Text = "COPIAR PARTE " .. chunkIndex
end)

saveButton.MouseButton1Click:Connect(function()
    if type(writefile) ~= "function" then
        copyStatus.Text = "GUARDAR TXT NO DISPONIBLE"
        return
    end

    local filename = "EggFinder_V23_3_"
        .. os.date("%H%M%S")
        .. ".txt"

    local ok, err = pcall(function()
        writefile(filename, fullReport())
    end)

    if ok then
        copyStatus.Text = "GUARDADO: " .. filename
    else
        copyStatus.Text = "ERROR: " .. tostring(err)
    end
end)

restart.MouseButton1Click:Connect(function()
    session = session + 1
    copyClicks = 0
    chunkIndex = 1

    copyStatus.Text = "COPIAS: 0"
    copyPart.Text = "COPIAR PARTE 1"

    task.spawn(monitor)
end)

close.MouseButton1Click:Connect(function()
    running = false
    session = session + 1

    if env.EggFinderStop then
        env.EggFinderStop = nil
    end

    gui:Destroy()
end)

task.spawn(monitor)
