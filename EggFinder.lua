
--[[
    EGG FINDER V23
    MONITOR DE REINICIO GLOBAL
    Duracion: 6 minutos
    Intervalo: 1 segundo
    Solo lectura
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local VERSION = "V23"
local DURATION = 360
local INTERVAL = 1
local POSITION_TOLERANCE = 5

local previous = pg:FindFirstChild("EggFinder")
if previous then
    previous:Destroy()
end

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
title.Text = "EGG FINDER V23 | MONITOR GLOBAL"
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 40, 0, 35)
close.Position = UDim2.new(1, -40, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "X"
close.Font = Enum.Font.GothamBold
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

local function button(text, x, color)
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

local copy = button(
    "COPIAR TODO",
    0,
    Color3.fromRGB(30, 120, 70)
)

local restart = button(
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
scroll.CanvasSize = UDim2.new(0, 1500, 0, 200)
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
local running = false
local startTime = 0
local eventCount = 0
local cycleCandidates = 0

local function fmtPos(p)
    if not p then return "N/A" end
    return string.format(
        "%.1f,%.1f,%.1f",
        p.X, p.Y, p.Z
    )
end

local function elapsed()
    if startTime == 0 then return 0 end
    return math.floor(os.clock() - startTime)
end

local function stamp()
    return string.format(
        "[%s | +%03ds]",
        os.date("%H:%M:%S"),
        elapsed()
    )
end

local function log(s)
    table.insert(lines, stamp() .. " " .. tostring(s))
end

local function render()
    output.Text = table.concat(lines, "\n")
    local h = math.max(200, #lines * 17 + 30)
    output.Size = UDim2.new(0, 1500, 0, h)
    scroll.CanvasSize = UDim2.new(0, 1500, 0, h)
end

local function getPosition(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Model") then
        local ok, cf = pcall(function()
            return obj:GetPivot()
        end)
        if ok then return cf.Position end
    end

    return nil
end

local function getAttributes(obj)
    local result = {}
    local attrs = obj:GetAttributes()

    for k, v in pairs(attrs) do
        table.insert(result, k .. "=" .. tostring(v))
    end

    table.sort(result)
    return table.concat(result, ";")
end

local function getTags(obj)
    local ok, tags = pcall(function()
        return CollectionService:GetTags(obj)
    end)

    if not ok then return "" end

    table.sort(tags)
    return table.concat(tags, ",")
end

-- Localiza los 65 nidos por sus posiciones.
local nests = {}

local function scanNests()
    nests = {}

    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")

    if not guards then
        log("AVISO: No se encontro GuardAreas")
        return
    end

    for _, area in ipairs(guards:GetChildren()) do
        local count = 0

        for _, obj in ipairs(area:GetDescendants()) do
            if obj.Name == "NestModel" and obj:IsA("Model") then
                count = count + 1

                local pos = getPosition(obj)

                -- EggFitBounds suele representar mejor
                -- el centro del huevo en el nido.
                local fit = obj:FindFirstChild(
                    "EggFitBounds",
                    true
                )

                if fit then
                    pos = getPosition(fit) or pos
                end

                if pos then
                    table.insert(nests, {
                        zone = area.Name,
                        index = count,
                        position = pos
                    })
                end
            end
        end
    end

    log("NIDOS LOCALIZADOS: " .. #nests)
end

local function nearestNest(pos)
    if not pos then
        return "DESCONOCIDO", -1
    end

    local best = nil
    local bestDistance = math.huge

    for _, nest in ipairs(nests) do
        local d = (nest.position - pos).Magnitude

        if d < bestDistance then
            bestDistance = d
            best = nest
        end
    end

    if best and bestDistance <= POSITION_TOLERANCE then
        return best.zone .. ":Nido_" .. best.index,
            bestDistance
    end

    return "SIN_NIDO", bestDistance
end

-- Firma visual y de metadatos.
-- No representa necesariamente el animal
-- ni la rareza real del huevo.
local function signature(model)
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
            local ok, v = pcall(function()
                return obj.Value
            end)

            if ok then
                table.insert(
                    values,
                    obj.Name .. "=" .. tostring(v)
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
            local zone, dist = nearestNest(pos)
            local mesh, values, parts = signature(obj)

            -- Usamos la referencia del objeto como clave.
            -- Así distinguimos una instancia nueva
            -- aunque tenga exactamente el mismo nombre.
            result[obj] = {
                name = obj.Name,
                position = fmtPos(pos),
                zone = zone,
                distance = dist,
                mesh = mesh,
                values = values,
                parts = parts,
                attrs = getAttributes(obj),
                tags = getTags(obj)
            }
        end
    end

    return result, true
end

local function countEntries(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

local function describe(data)
    return string.format(
        "%s | %s | pos=%s | meshParts=%d",
        data.zone,
        data.name,
        data.position,
        data.parts
    )
end

local function detail(prefix, data)
    log(prefix .. " " .. describe(data))

    if data.mesh ~= "" then
        log("    MESH: " .. data.mesh)
    end

    if data.attrs ~= "" then
        log("    ATTR: " .. data.attrs)
    end

    if data.tags ~= "" then
        log("    TAGS: " .. data.tags)
    end

    if data.values ~= "" then
        log("    VALUES: " .. data.values)
    end
end

local function zoneSummary(state)
    local counts = {}

    for _, data in pairs(state) do
        counts[data.zone] = (counts[data.zone] or 0) + 1
    end

    local keys = {}

    for k in pairs(counts) do
        table.insert(keys, k)
    end

    table.sort(keys)

    for _, k in ipairs(keys) do
        log("  " .. k .. " = " .. counts[k])
    end
end

local function startMonitor()
    session = session + 1
    local mySession = session

    running = true
    startTime = os.clock()
    eventCount = 0
    cycleCandidates = 0
    lines = {}

    log("======================================")
    log("EGG FINDER V23")
    log("MONITOR GLOBAL DE HUEVOS")
    log("======================================")
    log("DURACION MAXIMA: 360 SEGUNDOS")
    log("INTERVALO: 1 SEGUNDO")
    log("REINICIO DEL JUEGO: CADA 300 SEGUNDOS")
    log("ZONAS: 13")
    log("NIDOS ESPERADOS: 65")
    log("")

    scanNests()

    local last, folderExists = snapshot()

    log("")
    log("=== ESTADO INICIAL ===")
    log("CARPETA DISPONIBLE: " .. tostring(folderExists))
    log("HUEVOS INICIALES: " .. countEntries(last))

    zoneSummary(last)

    log("")
    log("=== IDENTIFICADORES INICIALES ===")

    local sorted = {}

    for _, data in pairs(last) do
        table.insert(sorted, data)
    end

    table.sort(sorted, function(a, b)
        return a.zone .. a.name < b.zone .. b.name
    end)

    for _, data in ipairs(sorted) do
        detail("INICIAL", data)
    end

    log("")
    log("=== MONITOREO EN TIEMPO REAL ===")
    render()

    local lastHeartbeat = -1
    local previousFolderExists = folderExists

    while mySession == session
        and gui.Parent
        and elapsed() < DURATION do

        task.wait(INTERVAL)

        if mySession ~= session then
            break
        end

        local current, exists = snapshot()

        if exists ~= previousFolderExists then
            log("CARPETA CAMBIO: " .. tostring(exists))
            previousFolderExists = exists
        end

        -- Si la carpeta desaparece temporalmente,
        -- evitamos marcar falsamente los 65 huevos
        -- como recogidos.
        if not exists then
            status.Text = string.format(
                "Tiempo: %ds / 360s | Carpeta no disponible",
                elapsed()
            )
            render()
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
            local old = last[obj]

            if not old then
                table.insert(added, data)
            elseif
                data.name ~= old.name
                or data.position ~= old.position
                or data.mesh ~= old.mesh
                or data.values ~= old.values
                or data.attrs ~= old.attrs
                or data.tags ~= old.tags
            then
                table.insert(modified, {
                    old = old,
                    new = data
                })
            end
        end

        local changes =
            #removed + #added + #modified

        if changes > 0 then
            eventCount = eventCount + 1

            log("")
            log("======================================")
            log("EVENTO #" .. eventCount)
            log("======================================")

            log("ANTES: " .. countEntries(last))
            log("AHORA: " .. countEntries(current))
            log("DESAPARECIDOS: " .. #removed)
            log("NUEVOS: " .. #added)
            log("MODIFICADOS: " .. #modified)

            if #removed >= 15 and #added >= 15 then
                cycleCandidates = cycleCandidates + 1

                log(">>> POSIBLE REINICIO GLOBAL <<<")
                log("CANDIDATO #" .. cycleCandidates)
            end

            table.sort(removed, function(a, b)
                return a.zone .. a.name < b.zone .. b.name
            end)

            table.sort(added, function(a, b)
                return a.zone .. a.name < b.zone .. b.name
            end)

            for _, data in ipairs(removed) do
                detail("DESAPARECIO", data)
            end

            for _, data in ipairs(added) do
                detail("APARECIO", data)
            end

            for _, change in ipairs(modified) do
                log("MODIFICADO: " .. change.new.zone)
                log("  ANTES: " .. describe(change.old))
                log("  AHORA: " .. describe(change.new))

                if change.old.mesh ~= change.new.mesh then
                    log("  MESH ANTES: " .. change.old.mesh)
                    log("  MESH AHORA: " .. change.new.mesh)
                end

                if change.old.attrs ~= change.new.attrs then
                    log("  ATTR ANTES: " .. change.old.attrs)
                    log("  ATTR AHORA: " .. change.new.attrs)
                end

                if change.old.values ~= change.new.values then
                    log("  VALUE ANTES: " .. change.old.values)
                    log("  VALUE AHORA: " .. change.new.values)
                end
            end

            log("")
            log("=== CANTIDAD ACTUAL POR NIDO ===")
            zoneSummary(current)

            render()
        end

        last = current

        local sec = elapsed()

        if sec % 15 == 0 and sec ~= lastHeartbeat then
            lastHeartbeat = sec

            log(
                "HEARTBEAT | huevos="
                .. countEntries(current)
                .. " | eventos="
                .. eventCount
            )

            render()
        end

        status.Text = string.format(
            "Tiempo: %ds / 360s | Huevos: %d | Eventos: %d",
            sec,
            countEntries(current),
            eventCount
        )
    end

    if mySession ~= session then
        return
    end

    running = false

    log("")
    log("======================================")
    log("FIN DEL MONITOREO V23")
    log("======================================")
    log("SEGUNDOS: " .. elapsed())
    log("EVENTOS: " .. eventCount)
    log("POSIBLES REINICIOS: " .. cycleCandidates)
    log("NOTA: Un reinicio puede ocurrir en")
    log("varios eventos separados.")
    log("Puedes copiar el informe.")

    status.Text = "MONITOREO FINALIZADO"
    render()
end

copy.MouseButton1Click:Connect(function()
    local fn = setclipboard or toclipboard

    if fn then
        local ok = pcall(function()
            fn(table.concat(lines, "\n"))
        end)

        copy.Text = ok and "COPIADO!" or "ERROR AL COPIAR"
    else
        copy.Text = "CLIPBOARD NO DISPONIBLE"
    end
end)

restart.MouseButton1Click:Connect(function()
    copy.Text = "COPIAR TODO"
    session = session + 1
    task.spawn(startMonitor)
end)

close.MouseButton1Click:Connect(function()
    session = session + 1
    gui:Destroy()
end)

task.spawn(startMonitor)
