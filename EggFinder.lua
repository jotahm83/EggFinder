
-- EGG FINDER V21
-- INSPECTOR DE HUEVOS DE FOREST
-- Solo lectura: no recoge ni modifica huevos

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("EggFinder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 520, 0, 440)
frame.Position = UDim2.new(0.5, -260, 0.13, 0)
frame.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -38, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(32, 40, 55)
title.TextColor3 = Color3.fromRGB(0, 255, 145)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Text = "EGG FINDER V21 | FOREST"
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 36, 0, 35)
close.Position = UDim2.new(1, -36, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "X"
close.Parent = frame

local function button(text, x, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.49, 0, 0, 35)
    b.Position = UDim2.new(x, 0, 0, 39)
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
    Color3.fromRGB(28, 115, 65)
)

local refresh = button(
    "REINICIAR ANALISIS",
    0.51,
    Color3.fromRGB(40, 95, 160)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -85)
scroll.Position = UDim2.new(0, 6, 0, 80)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new()
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(1, -15, 0, 100)
output.BackgroundTransparency = 1
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextColor3 = Color3.fromRGB(110, 255, 165)
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.Parent = scroll

local lines = {}
local running = false

local function log(s)
    table.insert(lines, tostring(s))
end

local function draw()
    output.Text = table.concat(lines, "\n")
    local h = math.max(100, #lines * 17 + 25)
    output.Size = UDim2.new(0, 1600, 0, h)
    scroll.CanvasSize = UDim2.new(0, 1600, 0, h)
end

local function posOf(obj)
    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Attachment") then
        return obj.WorldPosition
    end

    if obj:IsA("Model") then
        local ok, cf = pcall(function()
            return obj:GetPivot()
        end)
        if ok then return cf.Position end
    end

    return nil
end

local function fmt(p)
    if not p then return "SIN POSICION" end
    return string.format(
        "%.1f, %.1f, %.1f",
        p.X, p.Y, p.Z
    )
end

local function shortValue(v)
    local s = tostring(v)
    if #s > 110 then
        s = s:sub(1, 110) .. "..."
    end
    return s
end

local function info(obj, origin)
    local p = posOf(obj)
    local d = p and (p - origin).Magnitude or -1

    log("  " .. obj:GetFullName())
    log("    CLASE: " .. obj.ClassName)

    if d >= 0 then
        log(string.format(
            "    DISTANCIA: %.2f | POS: %s",
            d, fmt(p)
        ))
    end

    local attrs = obj:GetAttributes()
    local keys = {}

    for k in pairs(attrs) do
        table.insert(keys, k)
    end

    table.sort(keys)

    for _, k in ipairs(keys) do
        log(
            "    ATTR " .. k ..
            " = " .. shortValue(attrs[k])
        )
    end

    if obj:IsA("ValueBase") then
        local ok, value = pcall(function()
            return obj.Value
        end)
        if ok then
            log("    VALUE = " .. shortValue(value))
        end
    end

    local tags = CollectionService:GetTags(obj)
    if #tags > 0 then
        log("    TAGS = " .. table.concat(tags, ", "))
    end
end

local function getForest()
    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")
    local forest = guards and guards:FindFirstChild("Forest")
    return forest
end

local function run()
    if running then return end
    running = true

    lines = {}

    local ok, err = pcall(function()
        log("EGG FINDER V21")
        log("INSPECTOR DE FOREST")
        log("")

        local character = player.Character
        local root = character and
            character:FindFirstChild("HumanoidRootPart")

        if not root then
            log("ERROR: PERSONAJE NO DISPONIBLE")
            return
        end

        local playerPos = root.Position

        log("=== JUGADOR ===")
        log("Posicion: " .. fmt(playerPos))
        log("")

        local forest = getForest()

        if not forest then
            log("ERROR: NO SE ENCONTRO FOREST")
            return
        end

        local nestFolder = forest:FindFirstChild("Nests")

        if not nestFolder then
            log("ERROR: NO SE ENCONTRO Nests")
            return
        end

        local nests = {}

        for _, nest in ipairs(nestFolder:GetChildren()) do
            local p = posOf(nest)
            if p then
                table.insert(nests, {
                    obj = nest,
                    pos = p
                })
            end
        end

        table.sort(nests, function(a, b)
            return a.pos.X < b.pos.X
        end)

        log("=== NIDOS DE FOREST ===")
        log("Cantidad: " .. #nests)

        local closest
        local closestDist = math.huge

        for i, n in ipairs(nests) do
            local d = (playerPos - n.pos).Magnitude

            log(string.format(
                "NIDO %d | %s | Dist jugador %.1f",
                i, fmt(n.pos), d
            ))

            if d < closestDist then
                closestDist = d
                closest = i
            end
        end

        log("")
        log("NIDO MAS CERCANO: " .. tostring(closest))
        log(string.format(
            "DISTANCIA: %.1f studs",
            closestDist
        ))

        if closestDist > 30 then
            log("AVISO: ESTAS LEJOS DE LOS NIDOS")
        end

        log("")
        log("=== ANALISIS ESPACIAL ===")

        -- Consulta las piezas fisicas en un radio
        -- alrededor de cada nido.
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {
            character
        }
        params.MaxParts = 0

        local radius = 13
        local limitPerNest = 35

        local allCandidates = {}

        for i, nest in ipairs(nests) do
            log("")
            log("========== NIDO " .. i .. " ==========")
            log("Centro: " .. fmt(nest.pos))

            local parts = workspace:GetPartBoundsInRadius(
                nest.pos,
                radius,
                params
            )

            log("PIEZAS EN RADIO 13: " .. #parts)

            local groups = {}
            local seen = {}

            for _, part in ipairs(parts) do
                local model = part:FindFirstAncestorOfClass("Model")
                local target = model or part

                -- Si pertenece a un nido, conservar
                -- el grupo del nido como referencia.
                local nestAncestor = part

                while nestAncestor and
                    nestAncestor.Parent ~= nestFolder do
                    nestAncestor = nestAncestor.Parent
                end

                if nestAncestor and
                    nestAncestor.Parent == nestFolder then
                    target = nestAncestor
                end

                if not seen[target] then
                    seen[target] = true
                    table.insert(groups, target)
                end
            end

            table.sort(groups, function(a, b)
                return a:GetFullName() < b:GetFullName()
            end)

            log("GRUPOS DIFERENTES: " .. #groups)

            local printed = 0

            for _, obj in ipairs(groups) do
                if printed >= limitPerNest then
                    break
                end

                printed = printed + 1

                local p = posOf(obj)
                local dist = p and
                    (p - nest.pos).Magnitude or -1

                log("")
                log("GRUPO " .. printed)
                log("  " .. obj:GetFullName())
                log("  CLASE: " .. obj.ClassName)

                if dist >= 0 then
                    log(string.format(
                        "  DIST NIDO: %.2f",
                        dist
                    ))
                end

                local attrs = obj:GetAttributes()
                for k, v in pairs(attrs) do
                    log(
                        "  ATTR " .. k ..
                        " = " .. shortValue(v)
                    )
                end

                local tags = CollectionService:GetTags(obj)
                if #tags > 0 then
                    log("  TAGS: " ..
                        table.concat(tags, ", "))
                end

                if not allCandidates[obj] then
                    allCandidates[obj] = true
                end
            end

            if #groups > limitPerNest then
                log("... OTROS GRUPOS OMITIDOS: " ..
                    (#groups - limitPerNest))
            end
        end

        log("")
        log("=== INSPECCION ESPECIAL ===")

        if closest then
            local n = nests[closest]

            log("Nido seleccionado: " .. closest)
            log("Posicion: " .. fmt(n.pos))

            local objects = workspace:GetPartBoundsInRadius(
                n.pos,
                9,
                params
            )

            log("Piezas cercanas: " .. #objects)

            local inspected = {}
            local count = 0

            for _, part in ipairs(objects) do
                if count >= 35 then break end

                if not inspected[part] then
                    inspected[part] = true
                    count = count + 1

                    info(part, n.pos)

                    local parent = part.Parent

                    if parent and parent ~= workspace then
                        local attrs = parent:GetAttributes()
                        local tags = CollectionService:GetTags(parent)

                        if next(attrs) or #tags > 0 then
                            log("    DATOS DEL PADRE:")
                            info(parent, n.pos)
                        end
                    end
                end
            end
        end

        log("")
        log("=== OBJETOS CON NOMBRE DE HUEVO ===")

        local words = {
            "egg", "spawn", "pickup",
            "interact", "prompt", "rarity"
        }

        local count = 0

        for _, obj in ipairs(workspace:GetDescendants()) do
            local name = obj.Name:lower()
            local match = false

            for _, word in ipairs(words) do
                if name:find(word, 1, true) then
                    match = true
                    break
                end
            end

            if match then
                local p = posOf(obj)

                if p and
                    (p - playerPos).Magnitude <= 35 then

                    count = count + 1

                    if count <= 70 then
                        info(obj, playerPos)
                    end
                end
            end
        end

        log("COINCIDENCIAS CERCANAS: " .. count)

        log("")
        log("=== FIN V21 ===")
        log("Copia el informe y envialo.")
    end)

    if not ok then
        log("")
        log("ERROR: " .. tostring(err))
    end

    draw()
    running = false
end

copy.MouseButton1Click:Connect(function()
    local fn = setclipboard or toclipboard

    if fn then
        local ok = pcall(function()
            fn(table.concat(lines, "\n"))
        end)

        copy.Text = ok and "COPIADO!" or "ERROR"
    else
        copy.Text = "SIN PORTAPAPELES"
    end
end)

refresh.MouseButton1Click:Connect(function()
    copy.Text = "COPIAR TODO"
    task.spawn(run)
end)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

task.spawn(run)

