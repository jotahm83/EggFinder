
-- EGG FINDER V22
-- INSPECTOR DE HUEVOS REALES
-- AreaEggSlotsClient
-- Solo lectura

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("EggFinder")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggFinder"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 530, 0, 445)
frame.Position = UDim2.new(0.5, -265, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(16, 19, 29)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -38, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
title.TextColor3 = Color3.fromRGB(0, 255, 145)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Text = "EGG FINDER V22 | HUEVOS REALES"
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 36, 0, 36)
close.Position = UDim2.new(1, -36, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(170, 40, 40)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "X"
close.Parent = frame

local function makeButton(txt, x, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.49, 0, 0, 35)
    b.Position = UDim2.new(x, 0, 0, 40)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = txt
    b.Parent = frame
    return b
end

local copy = makeButton(
    "COPIAR TODO",
    0,
    Color3.fromRGB(25, 110, 65)
)

local refresh = makeButton(
    "REINICIAR",
    0.51,
    Color3.fromRGB(40, 95, 160)
)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -86)
scroll.Position = UDim2.new(0, 6, 0, 80)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.Parent = frame

local output = Instance.new("TextLabel")
output.Size = UDim2.new(0, 1400, 0, 100)
output.BackgroundTransparency = 1
output.Font = Enum.Font.Code
output.TextSize = 12
output.TextColor3 = Color3.fromRGB(115, 255, 170)
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = false
output.Parent = scroll

local lines = {}
local busy = false

local function log(s)
    table.insert(lines, tostring(s))
end

local function render()
    output.Text = table.concat(lines, "\n")
    local height = math.max(100, #lines * 17 + 30)
    output.Size = UDim2.new(0, 1400, 0, height)
    scroll.CanvasSize = UDim2.new(0, 1400, 0, height)
end

local function str(value)
    local s = tostring(value)
    if #s > 180 then
        s = s:sub(1, 180) .. "..."
    end
    return s
end

local function positionOf(obj)
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
    if not p then return "DESCONOCIDA" end
    return string.format(
        "%.1f, %.1f, %.1f",
        p.X, p.Y, p.Z
    )
end

local function getPath(obj, root)
    local names = {}
    local current = obj

    while current and current ~= root do
        table.insert(names, 1, current.Name)
        current = current.Parent
    end

    if current == root then
        return table.concat(names, "/")
    end

    return obj:GetFullName()
end

local function inspect(obj, root)
    log("  OBJ: " .. getPath(obj, root))
    log("    CLASE: " .. obj.ClassName)

    local attrs = obj:GetAttributes()
    local keys = {}

    for k in pairs(attrs) do
        table.insert(keys, k)
    end

    table.sort(keys)

    for _, k in ipairs(keys) do
        log("    ATTR " .. k .. " = " .. str(attrs[k]))
    end

    local tags = CollectionService:GetTags(obj)
    if #tags > 0 then
        log("    TAGS: " .. table.concat(tags, ", "))
    end

    if obj:IsA("ValueBase") then
        local ok, v = pcall(function()
            return obj.Value
        end)

        if ok then
            log("    VALUE: " .. str(v))
        end
    end

    if obj:IsA("ProximityPrompt") then
        log("    ACTION: " .. obj.ActionText)
        log("    OBJECT: " .. obj.ObjectText)
        log("    ENABLED: " .. tostring(obj.Enabled))
        log("    DISTANCIA: " .. tostring(obj.MaxActivationDistance))
    end

    if obj:IsA("BasePart") then
        log("    POS: " .. fmt(obj.Position))
        log("    SIZE: " .. str(obj.Size))
        log("    TRANSPARENCIA: " .. tostring(obj.Transparency))
    end

    if obj:IsA("MeshPart") then
        log("    MESH ID: " .. str(obj.MeshId))
        log("    TEXTURE ID: " .. str(obj.TextureID))
    end

    if obj:IsA("SpecialMesh") then
        log("    MESH ID: " .. str(obj.MeshId))
        log("    TEXTURE ID: " .. str(obj.TextureId))
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        log("    TEXTURE: " .. str(obj.Texture))
    end
end

local function inspectEgg(egg, maxObjects)
    log("")
    log("======================================")
    log("HUEVO: " .. egg.Name)
    log("======================================")
    log("CLASE: " .. egg.ClassName)
    log("POSICION: " .. fmt(positionOf(egg)))

    local descendants = egg:GetDescendants()
    log("DESCENDIENTES: " .. #descendants)

    log("")
    log("=== ATRIBUTOS DEL MODELO ===")
    inspect(egg, egg.Parent)

    local classCounts = {}

    for _, obj in ipairs(descendants) do
        classCounts[obj.ClassName] =
            (classCounts[obj.ClassName] or 0) + 1
    end

    log("")
    log("=== TIPOS DE OBJETOS ===")

    local classes = {}

    for class in pairs(classCounts) do
        table.insert(classes, class)
    end

    table.sort(classes)

    for _, class in ipairs(classes) do
        log(class .. ": " .. classCounts[class])
    end

    log("")
    log("=== OBJETOS INTERNOS ===")

    local printed = 0

    for _, obj in ipairs(descendants) do
        if printed >= maxObjects then break end

        local interesting =
            obj:IsA("ValueBase")
            or obj:IsA("Folder")
            or obj:IsA("Model")
            or obj:IsA("ProximityPrompt")
            or obj:IsA("StringValue")
            or obj:IsA("ObjectValue")
            or obj:IsA("MeshPart")
            or obj:IsA("SpecialMesh")
            or obj:IsA("Decal")
            or obj:IsA("Texture")
            or obj:IsA("Configuration")
            or next(obj:GetAttributes()) ~= nil
            or #CollectionService:GetTags(obj) > 0

        if interesting then
            printed = printed + 1
            log("")
            inspect(obj, egg)
        end
    end

    log("")
    log("OBJETOS DETALLADOS: " .. printed)

    if printed >= maxObjects then
        log("AVISO: LIMITE DE DETALLE ALCANZADO")
    end
end

local function run()
    if busy then return end
    busy = true
    lines = {}

    local ok, err = pcall(function()
        log("EGG FINDER V22")
        log("INSPECTOR DE HUEVOS REALES")
        log("")

        local folder = workspace:FindFirstChild(
            "AreaEggSlotsClient"
        )

        log("=== FASE 1: CARPETA ===")

        if not folder then
            log("NO SE ENCONTRO AreaEggSlotsClient")
            log("Prueba acercarte a los huevos.")
            return
        end

        log("RUTA: " .. folder:GetFullName())
        log("OBJETOS DIRECTOS: " .. #folder:GetChildren())
        log("DESCENDIENTES: " .. #folder:GetDescendants())

        local eggs = {}

        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") then
                table.insert(eggs, obj)
            end
        end

        table.sort(eggs, function(a, b)
            return a.Name < b.Name
        end)

        log("")
        log("=== FASE 2: TODOS LOS HUEVOS ===")
        log("MODELOS: " .. #eggs)

        local zoneCounts = {}
        local forestEggs = {}

        for _, egg in ipairs(eggs) do
            local zone = egg.Name:match(
                "_([^_]+):Slot_%d+"
            )

            if not zone then
                zone = "SIN IDENTIFICAR"
            end

            zoneCounts[zone] =
                (zoneCounts[zone] or 0) + 1

            if zone == "Forest" then
                table.insert(forestEggs, egg)
            end
        end

        local zoneNames = {}

        for zone in pairs(zoneCounts) do
            table.insert(zoneNames, zone)
        end

        table.sort(zoneNames)

        for _, zone in ipairs(zoneNames) do
            log(zone .. ": " .. zoneCounts[zone])
        end

        log("")
        log("=== FASE 3: HUEVOS DE FOREST ===")
        log("HUEVOS EN FOREST: " .. #forestEggs)

        for _, egg in ipairs(forestEggs) do
            inspectEgg(egg, 65)
        end

        log("")
        log("=== FASE 4: OTROS HUEVOS ===")

        local shown = 0

        for _, egg in ipairs(eggs) do
            if not egg.Name:find("_Forest:Slot_", 1, true) then
                shown = shown + 1

                if shown <= 15 then
                    log("")
                    log("HUEVO: " .. egg.Name)
                    log("POS: " .. fmt(positionOf(egg)))
                    log("DESCENDIENTES: " ..
                        #egg:GetDescendants())

                    local attrs = egg:GetAttributes()

                    for k, v in pairs(attrs) do
                        log("ATTR " .. k .. " = " .. str(v))
                    end
                end
            end
        end

        if shown > 15 then
            log("OTROS OMITIDOS: " .. (shown - 15))
        end

        log("")
        log("=== FASE 5: MODULOS RELACIONADOS ===")

        local paths = {
            {"Client", "EggState"},
            {"Client", "Notifications", "RareSpawnText"},
            {"Data", "MonsterEgg"},
            {"Data", "LuminousEgg"},
            {"Data", "DragonEgg"},
            {"Data", "BrainrotEgg"},
            {"Data", "EggSkins"},
            {"Data", "LimitedEgg"},
            {"Data", "Rarity"},
            {"Data", "Rarity", "Configs", "Secret"},
            {"Data", "Rarity", "Configs", "Eternal"},
            {"Data", "Rarity", "Configs", "Divine"}
        }

        for _, path in ipairs(paths) do
            local obj = ReplicatedStorage

            for _, name in ipairs(path) do
                obj = obj and obj:FindFirstChild(name)
            end

            if obj then
                log("ENCONTRADO: " .. obj:GetFullName())
                log("CLASE: " .. obj.ClassName)

                for k, v in pairs(obj:GetAttributes()) do
                    log("  ATTR " .. k .. " = " .. str(v))
                end
            else
                log("NO ENCONTRADO: " ..
                    table.concat(path, "/"))
            end
        end

        log("")
        log("=== FIN DEL INFORME V22 ===")
        log("Copia todo y envia el resultado.")
    end)

    if not ok then
        log("ERROR: " .. tostring(err))
    end

    render()
    busy = false
end

copy.MouseButton1Click:Connect(function()
    local fn = setclipboard or toclipboard

    if fn then
        local ok = pcall(function()
            fn(table.concat(lines, "\n"))
        end)

        copy.Text = ok and "COPIADO!" or "ERROR"
    else
        copy.Text = "NO DISPONIBLE"
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
