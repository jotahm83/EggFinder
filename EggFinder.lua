
-- ============================================
-- EGG FINDER V23.2
-- MONITOR DE HUEVOS + DIAGNOSTICO DE COPIADO
-- 13 ZONAS / 6 MINUTOS
-- ============================================

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local DURATION = 360
local INTERVAL = 1
local MAX_DISTANCE = 5
local CHUNK_SIZE = 2500

-- Evitar monitores anteriores duplicados
local env = (getgenv and getgenv()) or _G

if env.EggFinderStop then
    pcall(env.EggFinderStop)
end

local running = true
local session = 0
local lines = {}
local summaryLines = {}
local nests = {}
local eventCount = 0
local copyAttempts = 0
local chunkIndex = 1
local startTime = 0

env.EggFinderStop = function()
    running = false
    session = session + 1
end

local old = pg:FindFirstChild("EggFinder")
if old then
    old:Destroy()
end

-- ============================================
-- INTERFAZ
-- ============================================

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 540, 0, 485)
frame.Position = UDim2.new(0.5, -270, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 20, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -42, 0, 34)
title.BackgroundColor3 = Color3.fromRGB(28, 39, 53)
title.TextColor3 = Color3.fromRGB(50, 255, 160)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "EGG FINDER V23.2 | DIAGNOSTICO"
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 42, 0, 34)
close.Position = UDim2.new(1, -42, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.Parent = frame

local monitorStatus = Instance.new("TextLabel")
monitorStatus.Size = UDim2.new(1, -12, 0, 23)
monitorStatus.Position = UDim2.new(0, 6, 0, 37)
monitorStatus.BackgroundTransparency = 1
monitorStatus.TextColor3 = Color3.fromRGB(240, 220, 130)
monitorStatus.Font = Enum.Font.Code
monitorStatus.TextSize = 12
monitorStatus.TextXAlignment = Enum.TextXAlignment.Left
monitorStatus.Text = "Preparando monitor..."
monitorStatus.Parent = frame

local copyStatus = Instance.new("TextLabel")
copyStatus.Size = UDim2.new(1, -12, 0, 24)
copyStatus.Position = UDim2.new(0, 6, 0, 60)
copyStatus.BackgroundTransparency = 1
copyStatus.TextColor3 = Color3.fromRGB(90, 220, 255)
copyStatus.Font = Enum.Font.Code
copyStatus.TextSize = 12
copyStatus.TextXAlignment = Enum.TextXAlignment.Left
copyStatus.Text = "COPIAS: 0 | Esperando pulsacion"
copyStatus.Parent = frame

local function button(text, x, y, w, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(w, -6, 0, 32)
    b.Position = UDim2.new(x, 4, 0, y)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Text = text
    b.Parent = frame
    return b
end

local copyAll = button(
    "COPIAR TODO", 0, 89, 0.5,
    Color3.fromRGB(30, 125, 75)
)

local copyTest = button(
    "COPIAR PRUEBA", 0.5, 89, 0.5,
    Color3.fromRGB(130, 75, 175)
)

local copyPart = button(
    "COPIAR PARTE 1", 0, 126, 0.5,
    Color3.fromRGB(35, 100, 175)
)

local copySummary = button(
    "COPIAR RESUMEN", 0.5, 126, 0.5,
    Color3.fromRGB(35, 135, 135)
)

local saveButton = button(
    "GUARDAR TXT", 0, 163, 0.5,
    Color3.fromRGB(125, 100, 45)
)

local restart = button(
    "REINICIAR ANALISIS", 0.5, 163, 0.5,
    Color3.fromRGB(150, 65, 55)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -207)
scroll.Position = UDim2.new(0, 6, 0, 201)
scroll.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollingDirection = Enum.ScrollingDirection.XY
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(0, 1300, 0, 200)
output.BackgroundTransparency = 1
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextColor3 = Color3.fromRGB(125, 255, 175)
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.Parent = scroll

-- ============================================
-- REGISTROS
-- ============================================

local function elapsed()
    if startTime == 0 then
        return 0
    end
    return math.floor(os.clock() - startTime)
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
    -- Mostrar solo las ultimas 90 lineas.
    -- El historial completo permanece en lines.
    local first = math.max(1, #lines - 89)
    local visible = {}

    for i = first, #lines do
        table.insert(visible, lines[i])
    end

    output.Text = table.concat(visible, "\n")

    local height = math.max(200, #visible * 17 + 20)

    output.Size = UDim2.new(0, 1300, 0, height)
    scroll.CanvasSize = UDim2.new(0, 1300, 0, height)
end

local function fullReport()
    return table.concat(lines, "\n")
end

local function summaryReport()
    return table.concat(summaryLines, "\n")
end

-- ============================================
-- FUNCIONES DE ESCANEO
-- ============================================

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

local function posText(p)
    if not p then
        return "N/A"
    end

    return string.format(
        "%.1f,%.1f,%.1f",
        p.X, p.Y, p.Z
    )
end

local function getMetadata(obj)
    local data = {}

    for k, v in pairs(obj:GetAttributes()) do
        table.insert(
            data,
            tostring(k) .. "=" .. tostring(v)
        )
    end

    for _, tag in ipairs(CollectionService:GetTags(obj)) do
        table.insert(data, "TAG=" .. tag)
    end

    table.sort(data)

    return table.concat(data, ";")
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
        local found = {}

        for _, obj in ipairs(area:GetDescendants()) do
            if obj.Name == "NestModel"
                and obj:IsA("Model") then

                local fit = obj:FindFirstChild(
                    "EggFitBounds",
                    true
                )

                local pos = fit and getPosition(fit)
                    or getPosition(obj)

                if pos then
                    table.insert(found, pos)
                end
            end
        end

        table.sort(found, function(a, b)
            if math.abs(a.X - b.X) > 0.01 then
                return a.X < b.X
            end
            return a.Z < b.Z
        end)

        for index, pos in ipairs(found) do
            table.insert(nests, {
                name = area.Name .. ":Nido_" .. index,
                position = pos
            })
        end
    end

    log("NIDOS LOCALIZADOS: " .. #nests, true)
end

local function nearestNest(pos)
    if not pos then
        return "DESCONOCIDO"
    end

    local best = nil
    local distance = math.huge

    for _, nest in ipairs(nests) do
        local d = (nest.position - pos).Magnitude

        if d < distance then
            best = nest
            distance = d
        end
    end

    if best and distance <= MAX_DISTANCE then
        return best.name
    end

    return "SIN_NIDO"
end

local function getSignature(model)
    local meshes = {}
    local values = {}
    local meshParts = 0

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("MeshPart") then
            meshParts = meshParts + 1

            table.insert(
                meshes,
                tostring(obj.MeshId)
                .. "@"
                .. string.format(
                    "%.2f,%.2f,%.2f",
                    obj.Size.X,
                    obj.Size.Y,
                    obj.Size.Z
                )
            )

        elseif obj:IsA("SpecialMesh") then
            table.insert(meshes, tostring(obj.MeshId))

        elseif obj:IsA("ValueBase") then
            local ok, value = pcall(function()
                return obj.Value
            end)

            if ok then
                table.insert(
                    values,
                    obj.Name .. "=" .. tostring(value)
                )
            end
        end
    end

    table.sort(meshes)
    table.sort(values)

    return table.concat(meshes, "|"),
        table.concat(values, "|"),
        meshParts
end

local function snapshot()
    local state = {}

    local folder = workspace:FindFirstChild(
        "AreaEggSlotsClient"
    )

    if not folder then
        return state, false
    end

    for _, obj in ipairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local pos = getPosition(obj)
            local mesh, values, parts = getSignature(obj)

            state[obj] = {
                name = obj.Name,
                nest = nearestNest(pos),
                position = posText(pos),
                mesh = mesh,
                values = values,
                parts = parts,
                meta = getMetadata(obj)
            }
        end
    end

    return state, true
end

local function count(state)
    local n = 0

    for _ in pairs(state) do
        n = n + 1
    end

    return n
end

local function describe(data)
    return data.nest
        .. " | " .. data.name
        .. " | pos=" .. data.position
        .. " | meshParts=" .. data.parts
end

local function detail(prefix, data)
    log(prefix .. " " .. describe(data))

    if data.meta ~= "" then
        log("  META: " .. data.meta, true)
    end

    if data.values ~= "" then
        log("  VALUES: " .. data.values)
    end

    if data.mesh ~= "" then
        log("  MESH: " .. data.mesh)
    end
end

local function sortedData(state)
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

-- ============================================
-- MONITOREO
-- ============================================

local function monitor()
    session = session + 1
    local mySession = session

    lines = {}
    summaryLines = {}
    eventCount = 0
    chunkIndex = 1
    startTime = os.clock()

    log("================================", true)
    log("EGG FINDER V23.2", true)
    log("================================", true)
    log("DURACION: 360 SEGUNDOS", true)
    log("INTERVALO: 1 SEGUNDO", true)

    scanNests()

    local previous, available = snapshot()

    log("CARPETA DISPONIBLE: " .. tostring(available), true)
    log("HUEVOS INICIALES: " .. count(previous), true)
    log("=== IDENTIFICADORES INICIALES ===")

    for _, data in ipairs(sortedData(previous)) do
        detail("INICIAL", data)
    end

    log("=== INICIO DEL MONITOREO ===", true)
    render()

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

        local removed = {}
        local added = {}
        local modified = {}

        for obj, data in pairs(previous) do
            if not current[obj] then
                table.insert(removed, data)
            end
        end

        for obj, data in pairs(current) do
            local oldData = previous[obj]

            if not oldData then
                table.insert(added, data)

            elseif data.name ~= oldData.name
                or data.position ~= oldData.position
                or data.mesh ~= oldData.mesh
                or data.values ~= oldData.values
                or data.meta ~= oldData.meta then

                table.insert(modified, {
                    before = oldData,
                    after = data
                })
            end
        end

        local changes =
            #removed + #added + #modified

        if changes > 0 then
            eventCount = eventCount + 1

            log("", true)
            log("EVENTO #" .. eventCount, true)

            log(
                "HUEVOS: " .. count(previous)
                .. " -> " .. count(current),
                true
            )

            log(
                "DESAPARECIDOS=" .. #removed
                .. " NUEVOS=" .. #added
                .. " MODIFICADOS=" .. #modified,
                true
            )

            if #removed >= 15 and #added >= 15 then
                log(
                    ">>> POSIBLE REINICIO GLOBAL <<<",
                    true
                )
            end

            table.sort(removed, function(a, b)
                return a.nest .. a.name
                    < b.nest .. b.name
            end)

            table.sort(added, function(a, b)
                return a.nest .. a.name
                    < b.nest .. b.name
            end)

            for _, data in ipairs(removed) do
                detail("DESAPARECIO", data)
            end

            for _, data in ipairs(added) do
                detail("APARECIO", data)
            end

            for _, change in ipairs(modified) do
                log(
                    "MODIFICADO: "
                    .. describe(change.after)
                )

                if change.before.meta ~= change.after.meta then
                    log(
                        "META ANTES: "
                        .. change.before.meta,
                        true
                    )
                    log(
                        "META AHORA: "
                        .. change.after.meta,
                        true
                    )
                end

                if change.before.values ~= change.after.values then
                    log(
                        "VALUES ANTES: "
                        .. change.before.values
                    )
                    log(
                        "VALUES AHORA: "
                        .. change.after.values
                    )
                end

                if change.before.mesh ~= change.after.mesh then
                    log(
                        "MESH ANTES: "
                        .. change.before.mesh
                    )
                    log(
                        "MESH AHORA: "
                        .. change.after.mesh
                    )
                end
            end

            render()
        end

        previous = current

        local sec = elapsed()

        if sec % 15 == 0 and sec ~= lastHeartbeat then
            lastHeartbeat = sec

            log(
                "HEARTBEAT | huevos="
                .. count(current)
                .. " | eventos="
                .. eventCount,
                true
            )

            render()
        end

        monitorStatus.Text = string.format(
            "Tiempo: %ds / 360s | Huevos: %d | Eventos: %d",
            sec,
            count(current),
            eventCount
        )
    end

    if mySession ~= session then
        return
    end

    log("================================", true)
    log("FIN DEL MONITOREO", true)
    log("EVENTOS: " .. eventCount, true)

    monitorStatus.Text = "MONITOREO FINALIZADO"
    render()
end

-- ============================================
-- SISTEMA DE COPIADO INDEPENDIENTE
-- ============================================

local function copyText(text, description)
    -- Se incrementa ANTES de llamar al portapapeles.
    -- Permite comprobar si el boton responde.
    copyAttempts = copyAttempts + 1

    local number = copyAttempts
    local length = #text

    copyStatus.Text = string.format(
        "CLIC #%d | %s | %d caracteres",
        number,
        description,
        length
    )

    local fn = setclipboard or toclipboard

    if type(fn) ~= "function" then
        copyStatus.Text = "CLIC #" .. number
            .. " | PORTAPAPELES NO DISPONIBLE"
        return false
    end

    local ok, err = pcall(function()
        fn(text)
    end)

    if ok then
        copyStatus.Text = string.format(
            "CLIC #%d | %s | %d caracteres | ENVIADO",
            number,
            description,
            length
        )
    else
        copyStatus.Text = "CLIC #" .. number
            .. " | ERROR: " .. tostring(err)
    end

    -- ENVIADO no garantiza que el sistema
    -- operativo haya actualizado el portapapeles.
    return ok
end

-- COPIAR TODO
copyAll.MouseButton1Click:Connect(function()
    local report = fullReport()

    copyText(
        report,
        "TODO"
    )
end)

-- COPIAR PRUEBA
copyTest.MouseButton1Click:Connect(function()
    local nextNumber = copyAttempts + 1

    local test = "EGG FINDER V23.2 - PRUEBA #"
        .. nextNumber
        .. " - TIEMPO "
        .. elapsed()
        .. " SEGUNDOS"

    copyText(
        test,
        "PRUEBA"
    )
end)

-- COPIAR POR PARTES
copyPart.MouseButton1Click:Connect(function()
    local report = fullReport()

    local totalParts = math.max(
        1,
        math.ceil(#report / CHUNK_SIZE)
    )

    if chunkIndex > totalParts then
        chunkIndex = 1
    end

    local first = (chunkIndex - 1) * CHUNK_SIZE + 1
    local last = math.min(
        #report,
        first + CHUNK_SIZE - 1
    )

    local part = string.sub(report, first, last)

    local currentPart = chunkIndex

    local ok = copyText(
        part,
        "PARTE " .. currentPart .. "/" .. totalParts
    )

    if ok then
        chunkIndex = chunkIndex + 1
    end

    if chunkIndex > totalParts then
        chunkIndex = 1
    end

    copyPart.Text = "COPIAR PARTE " .. chunkIndex
end)

-- COPIAR RESUMEN
copySummary.MouseButton1Click:Connect(function()
    copyText(
        summaryReport(),
        "RESUMEN"
    )
end)

-- GUARDAR INFORME EN ARCHIVO
saveButton.MouseButton1Click:Connect(function()
    if type(writefile) ~= "function" then
        copyStatus.Text = "GUARDAR TXT NO DISPONIBLE EN DELTA"
        return
    end

    local filename = "EggFinder_V23_2_"
        .. os.date("%H%M%S")
        .. ".txt"

    local ok, err = pcall(function()
        writefile(filename, fullReport())
    end)

    if ok then
        copyStatus.Text = "TXT GUARDADO: " .. filename
    else
        copyStatus.Text = "ERROR TXT: " .. tostring(err)
    end
end)

-- REINICIAR
restart.MouseButton1Click:Connect(function()
    session = session + 1
    copyAttempts = 0
    chunkIndex = 1

    copyStatus.Text = "COPIAS: 0 | Nuevo analisis"
    copyPart.Text = "COPIAR PARTE 1"

    task.spawn(monitor)
end)

-- CERRAR
close.MouseButton1Click:Connect(function()
    running = false
    session = session + 1

    if env.EggFinderStop then
        env.EggFinderStop = nil
    end

    gui:Destroy()
end)

task.spawn(monitor)
