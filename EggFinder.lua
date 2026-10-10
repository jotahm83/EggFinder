
--[[
 EGG FINDER V26.6
 ROBLOX: ROBA UN HUEVO

 OBJETIVO:
 Encontrar huevos especiales grandes en:
 - Cherry Blossom
 - Titan Temple
 - Demons / Angels / Light Dark
 - Enchanted Forest

 CAMBIOS V26.6:
 - Servidores publicos poco poblados
 - Seleccion aleatoria
 - Lista nueva antes de cada intento
 - Evita servidores visitados y fallidos
 - Solo un teletransporte activo
 - Reintentos tras fallos confirmados
 - Escaneo rapido de dos pasadas
 - Record de tamano
 - Panel compacto
 - AUTO HOP reanudable

 LIMITACIONES:
 - La rareza es una estimacion visual.
 - No conoce los huevos de servidores remotos.
 - No puede garantizar eliminar errores
   769, 771 o 279.
 - No puede cancelar un teleport interno
   que Roblox mantiene bloqueado.
]]

local G = getgenv()

for _, key in ipairs({
    "EggFinderStop",
    "EggFinderV26Stop",
    "EggFinderV262Stop",
    "EggFinderV263Stop",
    "EggFinderV264Stop",
    "EggFinderV265Stop",
    "EggFinderV266Stop"
}) do
    if type(G[key]) == "function" then
        pcall(G[key])
    end
end

local Players = game:GetService("Players")
local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local SG = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local LOADER =
    "https://raw.githubusercontent.com/jotahm83/EggFinder/main/EggFinder.lua"

local SAVE_FILE = "EggFinderV266_State.json"

local C = {
    minimum = 10,
    auto = true,

    minimumEggs = 60,
    stableSeconds = 1.2,
    secondScanDelay = 0.8,
    maxLoadSeconds = 35,

    minimumFreeSlots = 7,
    serverPages = 3,
    candidatePool = 40,

    teleportWarning = 20,
    retryBase = 3,
    retryMax = 18
}

local S = {
    running = true,
    found = false,
    busy = false,
    teleporting = false,
    scanBusy = false,

    token = 0,
    target = nil,

    visited = {},
    failed = {},

    checked = 1,
    failures = 0,
    consecutiveFailures = 0,

    eggs = 0,
    candidates = {},
    unknown = 0,

    record = {
        height = 0,
        zone = "-",
        rarity = "-"
    },

    lastLog = "",
    nextHop = 0,

    ready = false,
    dirty = true,
    stableCount = -1,
    stableSince = os.clock(),
    loadStarted = os.clock(),

    scanPass = 0,
    scanAt = 0,

    folder = nil,
    folderConnections = {},

    queuePrepared = false,
    sessionNonce = tostring(os.clock())
}

local connections = {}
local alertFrame

local scan
local hop

local function bind(signal, fn, collection)
    local c = signal:Connect(fn)
    table.insert(collection or connections, c)
    return c
end

local function make(class, properties, parent)
    local object = Instance.new(class)

    for key, value in pairs(properties or {}) do
        object[key] = value
    end

    object.Parent = parent
    return object
end

local function corner(object, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius or 7)
    }, object)
end

local function log(message)
    S.lastLog = tostring(message)
    print("[EGG FINDER V26.6] " .. S.lastLog)
end

-- LIMPIAR VERSIONES ANTERIORES

for _, name in ipairs({
    "EggFinderV26",
    "EggFinderV261",
    "EggFinderV262",
    "EggFinderV263",
    "EggFinderV264",
    "EggFinderV265",
    "EggFinderV266"
}) do
    local old = pg:FindFirstChild(name)

    if old then
        old:Destroy()
    end
end

-- INTERFAZ COMPACTA

local gui = make("ScreenGui", {
    Name = "EggFinderV266",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999
}, pg)

local panel = make("Frame", {
    Size = UDim2.fromOffset(260, 381),
    Position = UDim2.new(0.5, -130, 0.5, -190),
    BackgroundColor3 = Color3.fromRGB(19, 24, 36),
    BorderSizePixel = 0,
    Active = true
}, gui)

corner(panel, 10)

make("UIStroke", {
    Color = Color3.fromRGB(60, 130, 190),
    Thickness = 1.2
}, panel)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 33),
    BackgroundColor3 = Color3.fromRGB(29, 44, 70),
    BorderSizePixel = 0,
    Active = true
}, panel)

corner(header, 10)

make("TextLabel", {
    Text = "EGG FINDER V26.6",
    Position = UDim2.fromOffset(9, 0),
    Size = UDim2.new(1, -42, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(115, 220, 255),
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local function button(text, x, y, w, h, color, parent)
    local b = make("TextButton", {
        Text = text,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 =
            color or Color3.fromRGB(45, 77, 115),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 10
    }, parent or panel)

    corner(b, 6)
    return b
end

local closeButton = button(
    "X", 230, 4, 26, 25,
    Color3.fromRGB(165, 52, 60),
    header
)

local function label(text, x, y, w, h, size, color)
    return make("TextLabel", {
        Text = text,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundTransparency = 1,
        TextColor3 = color or Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = size or 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, panel)
end

local status = label(
    "Preparando...",
    9, 39, 242, 34, 11,
    Color3.fromRGB(255, 215, 110)
)

label(
    "ALTURA MINIMA (STUDS)",
    9, 77, 220, 15, 10
)

local presets = {6, 8, 10, 12, 15}
local presetButtons = {}

for i, value in ipairs(presets) do
    presetButtons[i] = button(
        tostring(value),
        9 + (i - 1) * 49,
        98, 45, 25
    )
end

local minimumInput = make("TextBox", {
    Position = UDim2.fromOffset(9, 129),
    Size = UDim2.fromOffset(242, 27),
    BackgroundColor3 = Color3.fromRGB(34, 45, 62),
    BorderSizePixel = 0,
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    Text = "10",
    ClearTextOnFocus = false,
    PlaceholderText = "Minimo personalizado"
}, panel)

corner(minimumInput, 6)

local autoButton = button(
    "AUTO: SI", 9, 165, 116, 27,
    Color3.fromRGB(30, 130, 95)
)

local scanButton = button(
    "ESCANEAR", 135, 165, 116, 27
)

local skipButton = button(
    "SALTAR", 9, 199, 116, 27,
    Color3.fromRGB(105, 80, 145)
)

local pauseButton = button(
    "PAUSAR", 135, 199, 116, 27,
    Color3.fromRGB(130, 90, 40)
)

local stats = label(
    "Servidores: 1 | Huevos: 0",
    9, 234, 242, 20, 10,
    Color3.fromRGB(180, 220, 255)
)

local recordLabel = label(
    "Record: 0.00 studs",
    9, 258, 242, 20, 10,
    Color3.fromRGB(255, 210, 115)
)

local results = label(
    "Esperando escaneo...",
    9, 284, 242, 50, 10
)

results.TextYAlignment = Enum.TextYAlignment.Top

local copyButton = button(
    "COPIAR", 9, 345, 116, 27
)

local restartButton = button(
    "REINICIAR", 135, 345, 116, 27,
    Color3.fromRGB(95, 65, 130)
)

local function setStatus(text, color)
    status.Text = text

    status.TextColor3 =
        color or Color3.fromRGB(255, 215, 110)
end

local function updateAuto()
    autoButton.Text =
        C.auto and "AUTO: SI" or "AUTO: NO"

    autoButton.BackgroundColor3 =
        C.auto
        and Color3.fromRGB(30, 130, 95)
        or Color3.fromRGB(125, 65, 70)
end

local function updatePresets()
    for i, b in ipairs(presetButtons) do
        b.BackgroundColor3 =
            C.minimum == presets[i]
            and Color3.fromRGB(30, 145, 105)
            or Color3.fromRGB(45, 77, 115)
    end
end

local function updateRecord()
    recordLabel.Text = string.format(
        "Record: %.2f studs | %s",
        S.record.height,
        S.record.zone
    )
end

-- ESTADO ENTRE SERVIDORES

local function snapshot()
    local visited = {}
    local failed = {}

    for id in pairs(S.visited) do
        table.insert(visited, id)
        if #visited >= 120 then break end
    end

    for id in pairs(S.failed) do
        table.insert(failed, id)
        if #failed >= 80 then break end
    end

    return {
        minimum = C.minimum,
        auto = C.auto,
        checked = S.checked,
        failures = S.failures,
        record = S.record,
        visited = visited,
        failed = failed
    }
end

local function saveState()
    if type(writefile) ~= "function" then
        return false
    end

    return pcall(function()
        writefile(
            SAVE_FILE,
            HS:JSONEncode(snapshot())
        )
    end)
end

local function restoreState()
    local saved = G.EggFinderV266Resume

    -- Leer archivo solo si se esta
    -- reanudando una busqueda.
    if type(saved) ~= "string" then
        return
    end

    if type(readfile) == "function" then
        local ok, contents = pcall(function()
            return readfile(SAVE_FILE)
        end)

        if ok and type(contents) == "string" then
            saved = contents
        end
    end

    local ok, data = pcall(function()
        return HS:JSONDecode(saved)
    end)

    if ok and type(data) == "table" then
        C.minimum = tonumber(data.minimum) or 10
        C.auto = data.auto == true

        S.checked =
            (tonumber(data.checked) or 1) + 1

        S.failures =
            tonumber(data.failures) or 0

        if type(data.record) == "table" then
            S.record = {
                height =
                    tonumber(data.record.height) or 0,
                zone =
                    tostring(data.record.zone or "-"),
                rarity =
                    tostring(data.record.rarity or "-")
            }
        end

        for _, id in ipairs(data.visited or {}) do
            S.visited[id] = true
        end

        for _, id in ipairs(data.failed or {}) do
            S.failed[id] = true
        end
    end

    G.EggFinderV266Resume = nil
end

restoreState()

S.visited[game.JobId] = true

local function prepareQueue()
    if S.queuePrepared then
        return true
    end

    local queue =
        queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)

    if type(queue) ~= "function" then
        return false
    end

    local fallback = HS:JSONEncode(snapshot())

    local code = [[
local g = getgenv()

if g.EggFinderV266Booted then
    return
end

g.EggFinderV266Booted = true

g.EggFinderV266Resume =
]] .. string.format("%q", fallback) .. [[

loadstring(game:HttpGet(
]] .. string.format("%q", LOADER) .. [[
))()
]]

    local ok = pcall(function()
        queue(code)
    end)

    if ok then
        S.queuePrepared = true
    end

    return ok
end

-- CONFIGURACION DEL MINIMO

for i, value in ipairs(presets) do
    bind(presetButtons[i].MouseButton1Click, function()
        C.minimum = value
        minimumInput.Text = tostring(value)

        S.dirty = true
        updatePresets()
        saveState()
    end)
end

bind(minimumInput.FocusLost, function()
    local value = tonumber(minimumInput.Text)

    if value and value > 0 and value <= 1000 then
        C.minimum = value
    else
        minimumInput.Text = tostring(C.minimum)
    end

    S.dirty = true
    updatePresets()
    saveState()
end)

-- ZONAS

local zones = {
    {
        name = "Cherry Blossom",
        aliases = {"cherryblossom", "cherry"}
    },
    {
        name = "Titan Temple",
        aliases = {"titantemple", "titan"}
    },
    {
        name = "Demons/Angels",
        aliases = {
            "lightdark", "demons", "angels",
            "demon", "angel"
        }
    },
    {
        name = "Enchanted Forest",
        aliases = {"enchantedforest", "enchanted"}
    }
}

local function normalize(text)
    return tostring(text or ""):lower()
        :gsub("[^%w]", "")
end

local function matchZone(text)
    local n = normalize(text)

    for _, zone in ipairs(zones) do
        for _, alias in ipairs(zone.aliases) do
            if n:find(alias, 1, true) then
                return zone.name
            end
        end
    end

    return nil
end

local function zoneFromTree(obj)
    local node = obj

    while node and node ~= workspace do
        local zone = matchZone(node.Name)

        if zone then return zone end

        for _, key in ipairs({
            "Area", "AreaName", "Zone",
            "ZoneName", "Biome", "BiomeName"
        }) do
            local ok, value = pcall(function()
                return node:GetAttribute(key)
            end)

            if ok and value then
                zone = matchZone(value)

                if zone then return zone end
            end
        end

        node = node.Parent
    end

    return nil
end

local function objectPosition(obj)
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

-- CACHE LOCAL DE NIDOS

local nestCache = {}
local nestCacheTime = 0

local function getNests()
    if #nestCache > 0
    and os.clock() - nestCacheTime < 60 then
        return nestCache
    end

    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards =
        areas and areas:FindFirstChild("GuardAreas")

    local nests = {}

    if guards then
        for _, obj in ipairs(guards:GetDescendants()) do
            if obj:IsA("BasePart")
            and obj.Name == "EggFitBounds" then
                table.insert(nests, {
                    pos = obj.Position,
                    zone = zoneFromTree(obj)
                })
            end
        end
    end

    nestCache = nests
    nestCacheTime = os.clock()

    return nests
end

local function eggZone(egg, nests)
    local direct = zoneFromTree(egg)

    if direct then return direct end

    local pos = objectPosition(egg)
    if not pos then return nil end

    local nearest
    local distance = math.huge

    for _, nest in ipairs(nests) do
        local d = (nest.pos - pos).Magnitude

        if d < distance then
            nearest = nest
            distance = d
        end
    end

    if nearest and distance <= 35 then
        return nearest.zone
    end

    return nil
end

-- ALTURA VISIBLE ESTIMADA

local function eggHeight(egg)
    local low = math.huge
    local high = -math.huge
    local count = 0

    for _, part in ipairs(egg:GetDescendants()) do
        if part:IsA("BasePart")
        and part.Transparency < 0.98
        and part.Size.Magnitude > 0.05 then

            local cf = part.CFrame
            local size = part.Size

            local half =
                math.abs(cf.RightVector.Y)
                    * size.X / 2
                + math.abs(cf.UpVector.Y)
                    * size.Y / 2
                + math.abs(cf.LookVector.Y)
                    * size.Z / 2

            low = math.min(
                low, cf.Position.Y - half
            )

            high = math.max(
                high, cf.Position.Y + half
            )

            count = count + 1
        end
    end

    if count > 0 then
        return high - low
    end

    if egg:IsA("Model") then
        local ok, _, size = pcall(function()
            return egg:GetBoundingBox()
        end)

        if ok then return size.Y end
    end

    return 0
end

-- DETECTOR VISUAL
-- Conserva criterios que funcionaron
-- con el Eternal encontrado.

local function inspectEffects(egg)
    local particles = 0
    local highlights = 0
    local beams = 0
    local trails = 0
    local lights = 0
    local pink = false

    for _, obj in ipairs(egg:GetDescendants()) do
        if obj:IsA("ParticleEmitter")
        and obj.Enabled then
            particles = particles + 1

        elseif obj:IsA("Highlight")
        and obj.Enabled then
            highlights = highlights + 1

            local c = obj.OutlineColor

            if c.R > 0.65
            and c.B > 0.3
            and c.G < 0.55
            and obj.OutlineTransparency < 0.8 then
                pink = true
            end

        elseif obj:IsA("Beam")
        and obj.Enabled then
            beams = beams + 1

        elseif obj:IsA("Trail")
        and obj.Enabled then
            trails = trails + 1

        elseif (
            obj:IsA("PointLight")
            or obj:IsA("SpotLight")
            or obj:IsA("SurfaceLight")
        ) and obj.Enabled then
            lights = lights + 1
        end
    end

    local special =
        particles >= 3
        or (
            highlights >= 1
            and particles >= 2
        )
        or (
            beams + trails >= 2
            and particles >= 1
        )
        or (
            lights >= 2
            and particles >= 2
        )

    local rarity =
        pink and "POSIBLE ETERNAL"
        or "ESPECIAL (SIN CONFIRMAR)"

    return special, rarity
end

-- ALERTA

local function dismissAlert()
    if alertFrame then
        alertFrame:Destroy()
        alertFrame = nil
    end
end

local function playSound()
    pcall(function()
        local sound = make("Sound", {
            SoundId =
                "rbxasset://sounds/electronicpingshort.wav",
            Volume = 1.5
        }, SoundService)

        sound:Play()

        task.delay(4, function()
            if sound then sound:Destroy() end
        end)
    end)
end

local function showFound(candidate)
    dismissAlert()

    alertFrame = make("Frame", {
        Size = UDim2.new(0.9, 0, 0, 145),
        Position = UDim2.new(0.05, 0, 0.08, 0),
        BackgroundColor3 =
            Color3.fromRGB(20, 95, 55),
        BorderSizePixel = 0,
        ZIndex = 50
    }, gui)

    corner(alertFrame, 10)

    make("UIStroke", {
        Color = Color3.fromRGB(75, 255, 150),
        Thickness = 3
    }, alertFrame)

    make("TextLabel", {
        Size = UDim2.new(1, -16, 1, -42),
        Position = UDim2.fromOffset(8, 5),
        BackgroundTransparency = 1,
        Text = string.format(
            "¡HUEVO ENCONTRADO!\n%s\n%.2f studs | Minimo %.2f\n%s\nAUTO HOP DETENIDO",
            candidate.zone,
            candidate.height,
            C.minimum,
            candidate.rarity
        ),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextWrapped = true,
        TextColor3 = Color3.new(1, 1, 1),
        ZIndex = 51
    }, alertFrame)

    local dismiss = make("TextButton", {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.new(0, 8, 1, -34),
        Text = "CERRAR AVISO",
        BackgroundColor3 =
            Color3.fromRGB(45, 145, 85),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        ZIndex = 51
    }, alertFrame)

    corner(dismiss, 6)

    bind(dismiss.MouseButton1Click, dismissAlert)

    pcall(function()
        SG:SetCore("SendNotification", {
            Title = "¡HUEVO ENCONTRADO!",
            Text = string.format(
                "%s | %.2f studs",
                candidate.zone,
                candidate.height
            ),
            Duration = 20
        })
    end)

    for i = 1, 3 do
        task.delay((i - 1) * 0.7, function()
            if S.running and S.found then
                playSound()
            end
        end)
    end
end

-- DETECCION DE CARGA DE HUEVOS

local function getEggFolder()
    return workspace:FindFirstChild(
        "AreaEggSlotsClient"
    )
end

local function getEggs()
    local folder = getEggFolder()
    local eggs = {}

    if not folder then return eggs end

    for _, egg in ipairs(folder:GetChildren()) do
        if egg:IsA("Model")
        or egg:IsA("BasePart") then
            table.insert(eggs, egg)
        end
    end

    return eggs
end

local function clearFolderConnections()
    for _, connection in ipairs(
        S.folderConnections
    ) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    S.folderConnections = {}
end

local function watchEggs()
    local folder = getEggFolder()

    if folder == S.folder then
        return
    end

    clearFolderConnections()

    S.folder = folder
    S.ready = false
    S.dirty = true
    S.stableCount = -1
    S.stableSince = os.clock()
    S.scanPass = 0

    if not folder then return end

    bind(folder.ChildAdded, function()
        S.dirty = true
        S.ready = false
        S.scanPass = 0
        S.stableSince = os.clock()
    end, S.folderConnections)

    bind(folder.ChildRemoved, function()
        S.dirty = true
        S.ready = false
        S.scanPass = 0
        S.stableSince = os.clock()
    end, S.folderConnections)

    bind(folder.DescendantAdded, function(obj)
        if obj:IsA("ParticleEmitter")
        or obj:IsA("Highlight")
        or obj:IsA("Beam")
        or obj:IsA("Trail")
        or obj:IsA("PointLight")
        or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") then
            S.dirty = true
            S.scanPass = 0
        end
    end, S.folderConnections)
end

local function updateLoading()
    watchEggs()

    local count = #getEggs()
    local now = os.clock()

    S.eggs = count

    if count ~= S.stableCount then
        S.stableCount = count
        S.stableSince = now
        S.ready = false
        S.dirty = true
        S.scanPass = 0
    end

    if count >= C.minimumEggs
    and now - S.stableSince
        >= C.stableSeconds then
        S.ready = true
    end

    return S.ready
end

-- ESCANEO DE HUEVOS

scan = function()
    if not S.running
    or S.found
    or S.busy
    or S.teleporting
    or S.scanBusy then
        return false
    end

    S.scanBusy = true

    local success = false

    local ok, err = pcall(function()
        local eggs = getEggs()
        local nests = getNests()

        S.eggs = #eggs

        local candidates = {}
        local unknown = 0
        local best = nil

        for _, egg in ipairs(eggs) do
            local special, rarity =
                inspectEffects(egg)

            if special then
                local zone = eggZone(egg, nests)

                if zone then
                    local height = eggHeight(egg)

                    local candidate = {
                        zone = zone,
                        height = height,
                        rarity = rarity
                    }

                    table.insert(
                        candidates,
                        candidate
                    )

                    if height > S.record.height then
                        S.record = {
                            height = height,
                            zone = zone,
                            rarity = rarity
                        }
                    end

                    if height >= C.minimum
                    and (
                        not best
                        or height > best.height
                    ) then
                        best = candidate
                    end
                else
                    unknown = unknown + 1
                end
            end
        end

        S.candidates = candidates
        S.unknown = unknown

        updateRecord()

        stats.Text = string.format(
            "Serv: %d | Huevos: %d | Fallos: %d",
            S.checked,
            S.eggs,
            S.failures
        )

        if best then
            S.found = true
            C.auto = false
            updateAuto()

            setStatus(
                "¡HUEVO ENCONTRADO!",
                Color3.fromRGB(80, 255, 150)
            )

            results.Text = string.format(
                "%s\n%.2f studs | %s",
                best.zone,
                best.height,
                best.rarity
            )

            log(
                "ENCONTRADO | "
                .. best.zone
                .. " | "
                .. tostring(best.height)
            )

            saveState()
            showFound(best)

            success = true
            return
        end

        table.sort(candidates, function(a, b)
            return a.height > b.height
        end)

        if #candidates > 0 then
            local largest = candidates[1]

            results.Text = string.format(
                "Mayor: %.2f studs\n%s\nMinimo: %.2f | CONTINUAR",
                largest.height,
                largest.zone,
                C.minimum
            )
        else
            results.Text =
                "Sin candidatos especiales.\nContinuar buscando..."
        end

        if unknown > 0 then
            results.Text =
                results.Text
                .. "\nSin zona: "
                .. tostring(unknown)
        end

        setStatus(
            "Analizando | Minimo "
            .. tostring(C.minimum)
        )

        log(string.format(
            "SCAN | Huevos=%d | Esp=%d | SinZona=%d",
            S.eggs,
            #candidates,
            unknown
        ))

        success = true
    end)

    S.scanBusy = false

    if not ok then
        warn(
            "[EGG FINDER V26.6] "
            .. tostring(err)
        )

        S.dirty = true
        S.scanPass = 0

        setStatus("Error al analizar huevos")
    end

    return success
end

-- SOLICITUD HTTP

local function httpGet(url)
    local requestFunction =
        (syn and syn.request)
        or http_request
        or request

    if type(requestFunction) == "function" then
        local ok, response = pcall(function()
            return requestFunction({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json"
                }
            })
        end)

        if ok and response
        and (
            response.StatusCode == 200
            or response.Success
        )
        and response.Body then
            return response.Body
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)

    if ok then return body end

    return nil
end

-- SELECCION DE SERVIDORES PUBLICOS
-- Se consulta una lista reciente antes de
-- iniciar cada intento de teletransporte.

local function chooseServer()
    local pool = {}
    local cursor = nil

    for page = 1, C.serverPages do
        local url =
            "https://games.roblox.com/v1/games/"
            .. tostring(game.PlaceId)
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor then
            url = url
                .. "&cursor="
                .. HS:UrlEncode(cursor)
        end

        local body = httpGet(url)

        if not body then
            return nil,
                "No se pudo consultar servidores"
        end

        local ok, data = pcall(function()
            return HS:JSONDecode(body)
        end)

        if not ok
        or type(data) ~= "table" then
            return nil,
                "Lista de servidores invalida"
        end

        for _, server in ipairs(
            data.data or {}
        ) do
            local free =
                (server.maxPlayers or 0)
                - (server.playing or 0)

            if server.id
            and server.id ~= game.JobId
            and not S.visited[server.id]
            and not S.failed[server.id]
            and free >= C.minimumFreeSlots then
                table.insert(pool, {
                    id = server.id,
                    free = free,
                    players = server.playing or 0
                })
            end
        end

        cursor = data.nextPageCursor

        if not cursor
        or #pool >= C.candidatePool then
            break
        end
    end

    if #pool == 0 then
        return nil, "Sin servidores nuevos"
    end

    table.sort(pool, function(a, b)
        return a.players < b.players
    end)

    local count = math.min(
        #pool, C.candidatePool
    )

    return pool[math.random(1, count)]
end

-- REINTENTOS CONTROLADOS

local function retryDelay()
    local exponent = math.min(
        math.max(
            S.consecutiveFailures - 1,
            0
        ),
        4
    )

    return math.min(
        C.retryBase * (2 ^ exponent),
        C.retryMax
    )
end

local function confirmedFailure(reason)
    if not S.running
    or S.found
    or not S.teleporting then
        return
    end

    if S.target then
        S.failed[S.target] = true
    end

    S.token = S.token + 1

    S.teleporting = false
    S.busy = false
    S.target = nil

    S.failures = S.failures + 1
    S.consecutiveFailures =
        S.consecutiveFailures + 1

    local delay = retryDelay()

    S.nextHop = os.clock() + delay

    setStatus(
        "Teleport fallido | Reintento "
        .. tostring(delay)
        .. "s"
    )

    results.Text =
        "Servidor descartado.\n"
        .. "Preparando otro destino..."

    log(
        "FALLO | "
        .. tostring(reason)
        .. " | Espera="
        .. tostring(delay)
    )

    saveState()
end

-- TELETRANSPORTE
-- Un intento cada vez.

hop = function(force)
    if not S.running
    or S.found
    or S.busy
    or S.teleporting then
        return
    end

    if not force and not C.auto then
        return
    end

    S.busy = true
    setStatus("Buscando servidor publico...")

    local target, err = chooseServer()

    if not S.running then
        S.busy = false
        return
    end

    if not target then
        S.busy = false

        S.nextHop = os.clock() + 12

        setStatus(
            "Buscando nuevos servidores..."
        )

        log(
            "SIN DESTINO | "
            .. tostring(err)
        )

        return
    end

    S.visited[game.JobId] = true
    S.visited[target.id] = true

    S.target = target.id

    saveState()

    local queued = prepareQueue()

    S.token = S.token + 1
    local currentToken = S.token

    S.busy = false
    S.teleporting = true

    setStatus(
        "Entrando | "
        .. tostring(target.players)
        .. " jugadores"
    )

    results.Text = string.format(
        "Plazas libres: %d\nAuto reinicio: %s",
        target.free,
        tostring(queued)
    )

    log(
        "TELEPORT | "
        .. target.id
        .. " | Queue="
        .. tostring(queued)
    )

    task.spawn(function()
        local ok, errText = pcall(function()
            TS:TeleportToPlaceInstance(
                game.PlaceId,
                target.id,
                player
            )
        end)

        if not ok
        and S.running
        and S.teleporting
        and S.token == currentToken then
            confirmedFailure(errText)
        end
    end)

    -- Timeout informativo:
    -- NO inicia otro teleport encima.
    task.delay(C.teleportWarning, function()
        if not S.running
        or S.found
        or not S.teleporting
        or S.token ~= currentToken then
            return
        end

        setStatus(
            "Teleport demorado",
            Color3.fromRGB(255, 175, 90)
        )

        results.Text =
            "Roblox sigue procesando.\n"
            .. "No se duplicara el intento.\n"
            .. "Esperando respuesta."

        log(
            "TELEPORT DEMORADO | "
            .. target.id
        )
    end)
end

-- ERROR OFICIAL DE ROBLOX

bind(TS.TeleportInitFailed, function(
    failedPlayer,
    result,
    message
)
    if failedPlayer ~= player then
        return
    end

    if not S.teleporting then
        return
    end

    confirmedFailure(
        tostring(result)
        .. " | "
        .. tostring(message)
    )
end)

-- REANUDAR BUSQUEDA

local function resume()
    if S.teleporting then
        setStatus(
            "Esperando teletransporte activo"
        )
        return
    end

    S.found = false
    dismissAlert()

    C.auto = true
    updateAuto()

    S.nextHop = 0

    saveState()

    setStatus(
        "AUTO HOP REANUDADO",
        Color3.fromRGB(90, 235, 165)
    )

    -- Saltar directamente para no volver
    -- a encontrar el mismo huevo.
    task.spawn(function()
        hop(true)
    end)
end

-- CONTROLES

bind(autoButton.MouseButton1Click, function()
    if S.found then
        resume()
        return
    end

    C.auto = not C.auto
    updateAuto()

    saveState()

    if C.auto then
        S.nextHop = 0

        setStatus("AUTO HOP ACTIVADO")

        if S.ready
        and S.scanPass >= 2
        and not S.teleporting
        and not S.busy then
            task.spawn(function()
                hop(true)
            end)
        end
    else
        setStatus("AUTO HOP PAUSADO")
    end
end)

bind(scanButton.MouseButton1Click, function()
    if not S.found
    and not S.teleporting then
        S.dirty = true
        S.scanPass = 0

        task.spawn(function()
            scan()
        end)
    end
end)

bind(skipButton.MouseButton1Click, function()
    if S.found then
        resume()
        return
    end

    if S.teleporting then
        setStatus(
            "Teleport activo: no duplicar",
            Color3.fromRGB(255, 175, 90)
        )
        return
    end

    task.spawn(function()
        hop(true)
    end)
end)

bind(pauseButton.MouseButton1Click, function()
    C.auto = false
    updateAuto()

    saveState()

    setStatus("BUSQUEDA PAUSADA")
end)

bind(copyButton.MouseButton1Click, function()
    local lines = {
        "EGG FINDER V26.6",
        "JobId: " .. tostring(game.JobId),
        "PlaceId: " .. tostring(game.PlaceId),

        "Minimo: " .. tostring(C.minimum),
        "AUTO: " .. tostring(C.auto),

        "Huevos: " .. tostring(S.eggs),
        "Servidores: " .. tostring(S.checked),
        "Fallos: " .. tostring(S.failures),

        "Teleport activo: "
            .. tostring(S.teleporting),

        "Record: "
            .. string.format(
                "%.2f",
                S.record.height
            ),

        "Record zona: " .. S.record.zone,
        "Record rareza: " .. S.record.rarity,

        "Sin zona: " .. tostring(S.unknown),
        "Ultimo: " .. S.lastLog
    }

    for _, candidate in ipairs(
        S.candidates
    ) do
        table.insert(lines, string.format(
            "%s | %.2f | %s",
            candidate.zone,
            candidate.height,
            candidate.rarity
        ))
    end

    local clipboard =
        setclipboard or toclipboard

    if type(clipboard) == "function" then
        local ok = pcall(function()
            clipboard(
                table.concat(lines, "\n")
            )
        end)

        setStatus(
            ok and "RESUMEN COPIADO"
            or "ERROR AL COPIAR"
        )
    else
        setStatus(
            "PORTAPAPELES NO DISPONIBLE"
        )
    end
end)

bind(restartButton.MouseButton1Click, function()
    if S.teleporting then
        setStatus(
            "Teleport activo: esperar"
        )
        return
    end

    S.found = false

    dismissAlert()

    C.auto = false
    updateAuto()

    S.ready = false
    S.dirty = true
    S.scanPass = 0
    S.stableCount = -1
    S.stableSince = os.clock()
    S.loadStarted = os.clock()

    saveState()

    setStatus("REINICIADO")
end)

local function stop()
    S.running = false
    C.auto = false
    S.token = S.token + 1

    clearFolderConnections()

    for _, connection in ipairs(
        connections
    ) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

G.EggFinderStop = stop
G.EggFinderV266Stop = stop

bind(closeButton.MouseButton1Click, function()
    stop()
    gui:Destroy()
end)

-- PANEL ARRASTRABLE

do
    local dragging = false
    local dragStart
    local startPos
    local activeInput

    bind(header.InputBegan, function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
        or input.UserInputType ==
            Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = panel.Position
            activeInput = input
        end
    end)

    bind(UIS.InputChanged, function(input)
        if not dragging then return end

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
        or input == activeInput then

            local delta =
                input.Position - dragStart

            panel.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    bind(UIS.InputEnded, function(input)
        if input == activeInput
        or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- INICIO

minimumInput.Text = tostring(C.minimum)

updatePresets()
updateAuto()
updateRecord()

log(
    "V26.6 INICIADO | Minimo="
    .. tostring(C.minimum)
)

task.spawn(function()
    setStatus("Esperando carga de huevos...")

    while S.running do
        if not S.found
        and not S.teleporting
        and not S.busy then

            local ready = updateLoading()
            local now = os.clock()

            if ready then
                -- Primera pasada.
                if S.scanPass == 0 then
                    local ok = scan()

                    if ok then
                        S.scanPass = 1
                        S.scanAt = now
                        S.dirty = false
                    end
                end

                -- Segunda pasada para comprobar
                -- efectos cargados mas tarde.
                if S.scanPass == 1
                and now - S.scanAt
                    >= C.secondScanDelay then

                    local ok = scan()

                    if ok then
                        S.scanPass = 2
                        S.dirty = false
                        S.nextHop =
                            os.clock() + 0.5
                    end
                end

                -- Si aparecen efectos nuevos
                -- antes del salto, reanalizar.
                if S.scanPass >= 2
                and S.dirty then

                    local ok = scan()

                    if ok then
                        S.dirty = false
                    end
                end

                if C.auto
                and S.scanPass >= 2
                and not S.dirty
                and not S.found
                and not S.teleporting
                and not S.busy
                and now >= S.nextHop then

                    S.nextHop = now + 5

                    task.spawn(function()
                        hop(false)
                    end)
                end

            elseif now - S.loadStarted
                >= C.maxLoadSeconds then

                setStatus(
                    "Carga incompleta: "
                    .. tostring(S.eggs)
                    .. " huevos"
                )

                -- Mantiene AUTO seleccionado.
                -- Continuara si termina de cargar.
            else
                setStatus(
                    "Cargando: "
                    .. tostring(S.eggs)
                    .. " huevos"
                )
            end
        end

        task.wait(0.25)
    end
end)
