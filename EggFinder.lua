
-- EGG FINDER V23.1
-- MONITOR GLOBAL DE HUEVOS
-- COPIAR TODO ILIMITADO
-- DURACION: 6 MINUTOS
-- SOLO LECTURA

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local DURATION = 360
local INTERVAL = 1
local MAX_DISTANCE = 5

local old = pg:FindFirstChild("EggFinder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 540, 0, 450)
frame.Position = UDim2.new(0.5, -270, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(17, 20, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(28, 39, 53)
title.TextColor3 = Color3.fromRGB(50, 255, 160)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Text = "EGG FINDER V23.1 | MONITOR GLOBAL"
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 40, 0, 35)
close.Position = UDim2.new(1, -40, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.Text = "X"
close.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -12, 0, 25)
status.Position = UDim2.new(0, 6, 0, 39)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(240, 220, 130)
status.Font = Enum.Font.Code
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Preparando..."
status.Parent = frame

local function createButton(text, x, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.49, -4, 0, 34)
    b.Position = UDim2.new(x, 4, 0, 68)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = text
    b.Parent = frame
    return b
end

local copy = createButton(
    "COPIAR TODO",
    0,
    Color3.fromRGB(30, 120, 70)
)

local restart = createButton(
    "REINICIAR ANALISIS",
    0.5,
    Color3.fromRGB(40, 95, 160)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -112)
scroll.Position = UDim2.new(0, 6, 0, 107)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(0, 1500, 0, 200)
output.BackgroundTransparency = 1
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextColor3 = Color3.fromRGB(125, 255, 175)
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.Parent = scroll

local lines = {}
local session = 0
local startTime = 0
local eventCount = 0
local copyCount = 0
local nests = {}

local function elapsed()
    if startTime == 0 then return 0 end
    return math.floor(os.clock() - startTime)
end

local function log(message)
    local stamp = string.format(
        "[%s | +%03ds]",
        os.date("%H:%M:%S"),
        elapsed()
    )

    table.insert(
        lines,
        stamp .. " " .. tostring(message)
    )
end

local function render()
    output.Text = table.concat(lines, "\n")

    local height = math.max(
        200,
        #lines * 17 + 30
    )

    output.Size = UDim2.new(
        0, 1500, 0, height
    )

    scroll.CanvasSize = UDim2.new(
        0, 1500, 0, height
    )
end

local function positionOf(obj)
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

local function posText(p)
    if not p then return "N/A" end

    return string.format(
        "%.1f,%.1f,%.1f",
        p.X, p.Y, p.Z
    )
end

local function metadata(obj)
    local result = {}

    for k, v in pairs(obj:GetAttributes()) do
        table.insert(
            result,
            k .. "=" .. tostring(v)
        )
    end

    local tags = CollectionService:GetTags(obj)

    for _, tag in ipairs(tags) do
        table.insert(result, "TAG=" .. tag)
    end

    table.sort(result)
    return table.concat(result, ";")
end

local function scanNests()
    nests = {}

    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")

    if not guards then
        log("ERROR: GuardAreas no encontrado")
        return
    end

    for _, area in ipairs(guards:GetChildren()) do
        local index = 0

        for _, obj in ipairs(area:GetDescendants()) do
            if obj.Name == "NestModel"
                and obj:IsA("Model") then

                index = index + 1

                local fit = obj:FindFirstChild(
                    "EggFitBounds",
                    true
                )

                local pos = fit and positionOf(fit)
                    or positionOf(obj)

                if pos then
                    table.insert(nests, {
                        name = area.Name .. ":Nido_" .. index,
                        position = pos
                    })
                end
            end
        end
    end

    log("NIDOS LOCALIZADOS: " .. #nests)
end

local function findNest(pos)
    if not pos then return "DESCONOCIDO" end

    local best = nil
    local distance = math.huge

    for _, nest in ipairs(nests) do
        local d = (
            nest.position - pos
        ).Magnitude

        if d < distance then
            distance = d
            best = nest
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
    local parts = 0

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("MeshPart") then
            parts = parts + 1

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
            table.insert(
                meshes,
                tostring(obj.MeshId)
            )

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
        parts
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
            local pos = positionOf(obj)
            local mesh, values, parts = getSignature(obj)

            state[obj] = {
                name = obj.Name,
                nest = findNest(pos),
                position = posText(pos),
                mesh = mesh,
                values = values,
                parts = parts,
                meta = metadata(obj)
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

local function describe(data)
    return data.nest
        .. " | " .. data.name
        .. " | pos=" .. data.position
        .. " | meshParts=" .. data.parts
end

local function detail(prefix, data)
    log(prefix .. " " .. describe(data))

    if data.mesh ~= "" then
        log("    MESH: " .. data.mesh)
    end

    if data.meta ~= "" then
        log("    META: " .. data.meta)
    end

    if data.values ~= "" then
        log("    VALUES: " .. data.values)
    end
end

local function summary(state)
    local totals = {}

    for _, data in pairs(state) do
        totals[data.nest] =
            (totals[data.nest] or 0) + 1
    end

    local names = {}

    for name in pairs(totals) do
        table.insert(names, name)
    end

    table.sort(names)

    for _, name in ipairs(names) do
        log("  " .. name .. " = " .. totals[name])
    end
end

local function monitor()
    session = session + 1
    local thisSession = session

    startTime = os.clock()
    eventCount = 0
    lines = {}

    log("================================")
    log("EGG FINDER V23.1")
    log("MONITOR GLOBAL DE HUEVOS")
    log("================================")
    log("DURACION: 360 SEGUNDOS")
    log("INTERVALO: 1 SEGUNDO")
    log("REINICIO DEL JUEGO: 300 SEGUNDOS")
    log("ZONAS: 13")
    log("")

    scanNests()

    local last, exists = snapshot()

    log("")
    log("=== ESTADO INICIAL ===")
    log("CARPETA DISPONIBLE: " .. tostring(exists))
    log("HUEVOS INICIALES: " .. count(last))

    summary(last)

    log("")
    log("=== IDENTIFICADORES INICIALES ===")

    for _, data in ipairs(sortedData(last)) do
        detail("INICIAL", data)
    end

    log("")
    log("=== MONITOREO EN TIEMPO REAL ===")

    render()

    local lastHeartbeat = -1

    while thisSession == session
        and gui.Parent
        and elapsed() < DURATION do

        task.wait(INTERVAL)

        if thisSession ~= session then
            return
        end

        local current, available = snapshot()

        if not available then
            status.Text = "Carpeta no disponible"
            continue
        end

        local removed = {}
        local added = {}
        local modified = {}

        for obj, data in pairs(last) do
            if not current[obj] then
                table.insert(removed, data)
            end
        end

        for obj, data in pairs(current) do
            local previous = last[obj]

            if not previous then
                table.insert(added, data)

            elseif data.name ~= previous.name
                or data.position ~= previous.position
                or data.mesh ~= previous.mesh
                or data.values ~= previous.values
                or data.meta ~= previous.meta then

                table.insert(modified, {
                    before = previous,
                    after = data
                })
            end
        end

        local changes =
            #removed + #added + #modified

        if changes > 0 then
            eventCount = eventCount + 1

            log("")
            log("================================")
            log("EVENTO #" .. eventCount)
            log("================================")
            log("ANTES: " .. count(last))
            log("AHORA: " .. count(current))
            log("DESAPARECIDOS: " .. #removed)
            log("NUEVOS: " .. #added)
            log("MODIFICADOS: " .. #modified)

            if #removed >= 15
                and #added >= 15 then

                log(">>> POSIBLE REINICIO GLOBAL <<<")
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
                log("MODIFICADO: " .. change.after.nest)
                log("  ANTES: " .. describe(change.before))
                log("  AHORA: " .. describe(change.after))

                if change.before.mesh ~= change.after.mesh then
                    log("  MESH ANTES: " .. change.before.mesh)
                    log("  MESH AHORA: " .. change.after.mesh)
                end

                if change.before.meta ~= change.after.meta then
                    log("  META ANTES: " .. change.before.meta)
                    log("  META AHORA: " .. change.after.meta)
                end

                if change.before.values ~= change.after.values then
                    log("  VALUES ANTES: " .. change.before.values)
                    log("  VALUES AHORA: " .. change.after.values)
                end
            end

            log("")
            log("=== ESTADO ACTUAL ===")
            summary(current)

            render()
        end

        last = current

        local sec = elapsed()

        if sec % 15 == 0
            and sec ~= lastHeartbeat then

            lastHeartbeat = sec

            log(
                "HEARTBEAT | huevos="
                .. count(current)
                .. " | eventos="
                .. eventCount
            )

            render()
        end

        status.Text = string.format(
            "Tiempo: %ds / 360s | Huevos: %d | Eventos: %d",
            sec,
            count(current),
            eventCount
        )
    end

    if thisSession ~= session then
        return
    end

    log("")
    log("================================")
    log("FIN DEL MONITOREO V23.1")
    log("================================")
    log("SEGUNDOS: " .. elapsed())
    log("EVENTOS: " .. eventCount)
    log("Puedes copiar el informe completo.")

    status.Text = "MONITOREO FINALIZADO"
    render()
end

-- =========================================
-- COPIAR TODO: SIN LIMITE DE PULSACIONES
-- =========================================

copy.MouseButton1Click:Connect(function()
    local fn = setclipboard or toclipboard

    -- Siempre mantiene disponible el boton
    copy.Text = "COPIAR TODO"

    if not fn then
        status.Text = "Portapapeles no disponible"
        return
    end

    -- Se reconstruye TODO el informe
    -- en cada pulsacion.
    local report = table.concat(lines, "\n")

    local ok, err = pcall(function()
        fn(report)
    end)

    if ok then
        copyCount = copyCount + 1

        status.Text = string.format(
            "Copia #%d solicitada | %d caracteres | %d lineas",
            copyCount,
            #report,
            #lines
        )
    else
        status.Text = "ERROR: " .. tostring(err)
    end

    -- Nunca cambia permanentemente a COPIADO
    copy.Text = "COPIAR TODO"
end)

restart.MouseButton1Click:Connect(function()
    copyCount = 0
    session = session + 1
    task.spawn(monitor)
end)

close.MouseButton1Click:Connect(function()
    session = session + 1
    gui:Destroy()
end)

task.spawn(monitor)
