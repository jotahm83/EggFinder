
--[[
 EGG FINDER V26.1
 Buscador de servidores con proteccion de teletransporte.

 Zonas prioritarias:
 - Cherry Blossom
 - Titan Temple
 - Demons / Angels / Light Dark
 - Enchanted Forest

 Detecta candidatos especiales por efectos visuales.
 No garantiza la rareza real ni los ingresos del huevo.
]]

local G = getgenv()

if type(G.EggFinderStop) == "function" then
    pcall(G.EggFinderStop)
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LOADER_URL =
    "https://raw.githubusercontent.com/jotahm83/EggFinder/main/EggFinder.lua"

local config = {
    minimum = 10,
    autoHop = true,
    scanInterval = 2,
    loadWait = 12,
    maxTeleportWait = 20,
    minimumFreeSlots = 3,
    serverPages = 5
}

local state = {
    running = true,
    found = false,
    hopping = false,
    teleporting = false,
    hopToken = 0,
    serversChecked = 1,
    visited = {},
    failed = {},
    candidates = {},
    eggCount = 0,
    unknownZones = 0,
    lastMessage = "",
    scanBusy = false,
    serverEnteredAt = os.clock(),
    lastScanAt = 0,
    nextHopAt = 0
}

local oldGui = playerGui:FindFirstChild("EggFinderV261")
if oldGui then oldGui:Destroy() end

local connections = {}

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end

local function create(class, properties, parent)
    local obj = Instance.new(class)

    for key, value in pairs(properties or {}) do
        obj[key] = value
    end

    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

local gui = create("ScreenGui", {
    Name = "EggFinderV261",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999
}, playerGui)

local panel = create("Frame", {
    Size = UDim2.fromOffset(340, 480),
    Position = UDim2.new(0.5, -170, 0.5, -240),
    BackgroundColor3 = Color3.fromRGB(18, 23, 35),
    BorderSizePixel = 0,
    Active = true
}, gui)

corner(panel, 12)

create("UIStroke", {
    Color = Color3.fromRGB(55, 125, 190),
    Thickness = 1.5
}, panel)

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = Color3.fromRGB(28, 44, 69),
    BorderSizePixel = 0,
    Active = true
}, panel)

corner(header, 12)

create("TextLabel", {
    Size = UDim2.new(1, -52, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "EGG FINDER V26.1",
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextColor3 = Color3.fromRGB(115, 220, 255),
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local function button(text, x, y, w, h, color)
    local obj = create("TextButton", {
        Text = text,
        Size = UDim2.fromOffset(w, h),
        Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = color or Color3.fromRGB(43, 77, 115),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = true
    }, panel)

    corner(obj, 7)
    return obj
end

local closeButton = create("TextButton", {
    Text = "X",
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -37, 0, 7),
    BackgroundColor3 = Color3.fromRGB(165, 53, 60),
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    BorderSizePixel = 0
}, header)

corner(closeButton, 7)

local function label(text, x, y, w, h, size, color)
    return create("TextLabel", {
        Text = text,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundTransparency = 1,
        TextColor3 = color or Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham,
        TextSize = size or 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, panel)
end

local status = label(
    "Preparando...", 12, 52, 316, 40,
    13, Color3.fromRGB(255, 220, 120)
)

label(
    "ALTURA MINIMA (STUDS)",
    12, 96, 260, 18, 12,
    Color3.fromRGB(175, 195, 215)
)

local presets = {6, 8, 10, 12, 15}
local presetButtons = {}

local minimumInput = create("TextBox", {
    Position = UDim2.fromOffset(12, 154),
    Size = UDim2.fromOffset(316, 32),
    Text = tostring(config.minimum),
    PlaceholderText = "Tamano personalizado",
    BackgroundColor3 = Color3.fromRGB(34, 45, 62),
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    ClearTextOnFocus = false,
    BorderSizePixel = 0
}, panel)

corner(minimumInput, 7)

local function updatePresets()
    for i, b in ipairs(presetButtons) do
        b.BackgroundColor3 =
            config.minimum == presets[i]
            and Color3.fromRGB(32, 145, 105)
            or Color3.fromRGB(43, 77, 115)
    end
end

for i, n in ipairs(presets) do
    local b = button(
        tostring(n),
        12 + (i - 1) * 64,
        119, 60, 29
    )

    presetButtons[i] = b

    connect(b.MouseButton1Click, function()
        config.minimum = n
        minimumInput.Text = tostring(n)
        updatePresets()
    end)
end

local autoButton = button(
    "AUTO HOP: SI",
    12, 196, 153, 33,
    Color3.fromRGB(30, 130, 95)
)

local scanButton = button(
    "ESCANEAR",
    175, 196, 153, 33
)

local skipButton = button(
    "SALTAR SERVIDOR",
    12, 238, 153, 33,
    Color3.fromRGB(105, 80, 145)
)

local pauseButton = button(
    "PAUSAR",
    175, 238, 153, 33,
    Color3.fromRGB(135, 95, 40)
)

local stats = label(
    "Servidores: 1 | Huevos: 0",
    12, 283, 316, 30, 12,
    Color3.fromRGB(180, 220, 255)
)

local results = label(
    "Esperando el primer escaneo...",
    12, 317, 316, 100, 12
)

results.TextYAlignment = Enum.TextYAlignment.Top

local copyButton = button(
    "COPIAR RESUMEN",
    12, 430, 153, 33
)

local restartButton = button(
    "REINICIAR",
    175, 430, 153, 33,
    Color3.fromRGB(95, 65, 130)
)

local function setStatus(text, color)
    status.Text = text
    status.TextColor3 =
        color or Color3.fromRGB(255, 220, 120)
end

local function log(message)
    state.lastMessage = tostring(message)
    print("[EGG FINDER V26.1] " .. tostring(message))
end

local function updateAuto()
    autoButton.Text =
        config.autoHop and "AUTO HOP: SI" or "AUTO HOP: NO"

    autoButton.BackgroundColor3 =
        config.autoHop
        and Color3.fromRGB(30, 130, 95)
        or Color3.fromRGB(125, 65, 70)
end

local function normalize(s)
    return tostring(s or ""):lower():gsub("[^%w]", "")
end

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
        local z = matchZone(node.Name)
        if z then return z end

        for _, key in ipairs({
            "Area", "AreaName", "Zone",
            "ZoneName", "Biome", "BiomeName"
        }) do
            local ok, value = pcall(function()
                return node:GetAttribute(key)
            end)

            if ok and value then
                z = matchZone(value)
                if z then return z end
            end
        end

        node = node.Parent
    end

    return nil
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

local function collectNests()
    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")

    local nests = {}

    if not guards then return nests end

    for _, obj in ipairs(guards:GetDescendants()) do
        if obj.Name == "EggFitBounds"
        and obj:IsA("BasePart") then
            table.insert(nests, {
                position = obj.Position,
                zone = zoneFromTree(obj)
            })
        end
    end

    return nests
end

local function eggZone(egg, nests)
    local direct = zoneFromTree(egg)

    if direct then return direct end

    local pos = getPosition(egg)
    if not pos then return nil end

    local closest = nil
    local distance = math.huge

    for _, nest in ipairs(nests) do
        local d = (nest.position - pos).Magnitude

        if d < distance then
            distance = d
            closest = nest
        end
    end

    if closest and distance <= 35 then
        return closest.zone
    end

    return nil
end

local function eggHeight(egg)
    local low = math.huge
    local high = -math.huge
    local parts = 0

    for _, obj in ipairs(egg:GetDescendants()) do
        if obj:IsA("BasePart")
        and obj.Transparency < 0.98
        and obj.Size.Magnitude > 0.05 then

            local cf = obj.CFrame
            local size = obj.Size

            local half =
                math.abs(cf.RightVector.Y) * size.X / 2
                + math.abs(cf.UpVector.Y) * size.Y / 2
                + math.abs(cf.LookVector.Y) * size.Z / 2

            low = math.min(low, cf.Position.Y - half)
            high = math.max(high, cf.Position.Y + half)
            parts = parts + 1
        end
    end

    if parts > 0 then
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

local function inspectEffects(egg)
    local particles = 0
    local highlights = 0
    local beams = 0
    local trails = 0
    local lights = 0
    local rate = 0
    local pinkOutline = false

    for _, obj in ipairs(egg:GetDescendants()) do
        if obj:IsA("ParticleEmitter") and obj.Enabled then
            particles = particles + 1
            rate = rate + math.min(obj.Rate, 100)

        elseif obj:IsA("Highlight") and obj.Enabled then
            highlights = highlights + 1

            local c = obj.OutlineColor

            if c.R > 0.65
            and c.B > 0.3
            and c.G < 0.55
            and obj.OutlineTransparency < 0.8 then
                pinkOutline = true
            end

        elseif obj:IsA("Beam") and obj.Enabled then
            beams = beams + 1

        elseif obj:IsA("Trail") and obj.Enabled then
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
        or (highlights >= 1 and particles >= 2)
        or (beams + trails >= 2 and particles >= 1)
        or (lights >= 2 and particles >= 2)

    local score =
        particles * 2
        + highlights * 3
        + beams * 3
        + trails * 2
        + lights * 2
        + math.min(rate / 25, 8)

    return {
        special = special,
        score = score,
        rarity = pinkOutline
            and "POSIBLE ETERNAL"
            or "ESPECIAL (SIN CONFIRMAR)"
    }
end

local alertFrame

local function soundAlert()
    pcall(function()
        local sound = create("Sound", {
            SoundId = "rbxasset://sounds/electronicpingshort.wav",
            Volume = 1.5
        }, SoundService)

        sound:Play()

        task.delay(4, function()
            if sound then sound:Destroy() end
        end)
    end)
end

local function showAlert(candidate)
    if alertFrame then alertFrame:Destroy() end

    alertFrame = create("Frame", {
        Size = UDim2.new(0.9, 0, 0, 170),
        Position = UDim2.new(0.05, 0, 0.08, 0),
        BackgroundColor3 = Color3.fromRGB(19, 92, 56),
        BorderSizePixel = 0,
        ZIndex = 50
    }, gui)

    corner(alertFrame, 12)

    create("UIStroke", {
        Color = Color3.fromRGB(75, 255, 150),
        Thickness = 3
    }, alertFrame)

    create("TextLabel", {
        Size = UDim2.new(1, -20, 1, -50),
        Position = UDim2.fromOffset(10, 8),
        BackgroundTransparency = 1,
        Text = string.format(
            "¡HUEVO ENCONTRADO!\n%s\nAltura: %.2f | Minimo: %.2f\n%s\nBUSQUEDA DETENIDA",
            candidate.zone,
            candidate.height,
            config.minimum,
            candidate.rarity
        ),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextWrapped = true,
        ZIndex = 51
    }, alertFrame)

    local dismiss = create("TextButton", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 1, -36),
        BackgroundColor3 = Color3.fromRGB(40, 140, 85),
        Text = "CERRAR AVISO",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 51
    }, alertFrame)

    corner(dismiss, 7)

    connect(dismiss.MouseButton1Click, function()
        if alertFrame then
            alertFrame:Destroy()
            alertFrame = nil
        end
    end)

    pcall(function()
        StarterGui:SetCore("SendNotification", {
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
        task.delay((i - 1) * 0.7, soundAlert)
    end
end

local function scan()
    if not state.running
    or state.found
    or state.hopping
    or state.scanBusy then
        return
    end

    state.scanBusy = true

    local ok, err = pcall(function()
        local folder =
            workspace:FindFirstChild("AreaEggSlotsClient")

        if not folder then
            state.eggCount = 0
            setStatus("Esperando carpeta de huevos...")
            return
        end

        local eggs = {}

        for _, obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model")
            or obj:IsA("BasePart") then
                table.insert(eggs, obj)
            end
        end

        state.eggCount = #eggs

        local nests = collectNests()
        local candidates = {}
        local unknown = 0
        local best = nil

        for _, egg in ipairs(eggs) do
            local effects = inspectEffects(egg)

            if effects.special then
                local zone = eggZone(egg, nests)

                if zone then
                    local height = eggHeight(egg)

                    local c = {
                        zone = zone,
                        height = height,
                        rarity = effects.rarity,
                        score = effects.score
                    }

                    table.insert(candidates, c)

                    if height >= config.minimum
                    and (not best or height > best.height) then
                        best = c
                    end
                else
                    unknown = unknown + 1
                end
            end
        end

        state.candidates = candidates
        state.unknownZones = unknown

        stats.Text = string.format(
            "Servidores: %d | Huevos: %d | Candidatos: %d",
            state.serversChecked,
            state.eggCount,
            #candidates
        )

        if best then
            state.found = true
            config.autoHop = false
            updateAuto()

            setStatus(
                "¡HUEVO ENCONTRADO! NO CAMBIAR",
                Color3.fromRGB(80, 255, 150)
            )

            results.Text = string.format(
                "Zona: %s\nAltura: %.2f studs\n%s",
                best.zone,
                best.height,
                best.rarity
            )

            log(string.format(
                "ENCONTRADO | %s | %.2f studs | %s",
                best.zone,
                best.height,
                best.rarity
            ))

            showAlert(best)
            return
        end

        table.sort(candidates, function(a, b)
            return a.height > b.height
        end)

        if #candidates > 0 then
            local largest = candidates[1]

            results.Text = string.format(
                "Mayor candidato: %s\nAltura: %.2f | Minimo: %.2f\nCandidatos: %d",
                largest.zone,
                largest.height,
                config.minimum,
                #candidates
            )
        else
            results.Text =
                "Sin candidatos especiales en las 4 zonas."
        end

        if unknown > 0 then
            results.Text = results.Text
                .. "\nEspeciales sin zona: "
                .. unknown
        end

        setStatus(
            "Escaneando | Minimo "
            .. tostring(config.minimum)
        )

        log(string.format(
            "SCAN | Huevos=%d | Candidatos=%d | SinZona=%d",
            state.eggCount,
            #candidates,
            unknown
        ))
    end)

    state.scanBusy = false

    if not ok then
        warn("[EGG FINDER] " .. tostring(err))
        setStatus("Error de escaneo; reintentando")
    end
end

-- Acceso HTTP. Si el executor no permite consultar
-- la API de servidores, se detiene el auto-hop.
local function getHttp(url)
    local req =
        (syn and syn.request)
        or http_request
        or request

    if req then
        local ok, response = pcall(function()
            return req({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json"
                }
            })
        end)

        if ok and response
        and (response.StatusCode == 200 or response.Success)
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

local function availableServers()
    local foundServers = {}
    local cursor = nil

    for page = 1, config.serverPages do
        local url =
            "https://games.roblox.com/v1/games/"
            .. tostring(game.PlaceId)
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor then
            url = url
                .. "&cursor="
                .. HttpService:UrlEncode(cursor)
        end

        local body = getHttp(url)

        if not body then
            return nil, "API de servidores inaccesible"
        end

        local ok, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)

        if not ok or type(data) ~= "table" then
            return nil, "Respuesta de servidores invalida"
        end

        for _, server in ipairs(data.data or {}) do
            local free =
                (server.maxPlayers or 0)
                - (server.playing or 0)

            if server.id
            and server.id ~= game.JobId
            and not state.visited[server.id]
            and not state.failed[server.id]
            and free >= config.minimumFreeSlots then
                table.insert(foundServers, {
                    id = server.id,
                    free = free
                })
            end
        end

        cursor = data.nextPageCursor

        if not cursor or #foundServers >= 25 then
            break
        end
    end

    table.sort(foundServers, function(a, b)
        return a.free > b.free
    end)

    return foundServers
end

local function saveForNextServer()
    local queue =
        queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)

    if type(queue) ~= "function" then
        return false
    end

    local ids = {}
    local failedIds = {}

    for id in pairs(state.visited) do
        table.insert(ids, id)
        if #ids >= 120 then break end
    end

    for id in pairs(state.failed) do
        table.insert(failedIds, id)
        if #failedIds >= 80 then break end
    end

    local saved = HttpService:JSONEncode({
        minimum = config.minimum,
        auto = config.autoHop,
        checked = state.serversChecked,
        visited = ids,
        failed = failedIds
    })

    local code =
        "getgenv().EggFinderV261Resume = "
        .. string.format("%q", saved)
        .. "\nloadstring(game:HttpGet("
        .. string.format("%q", LOADER_URL)
        .. "))()"

    return pcall(function()
        queue(code)
    end)
end

local function stopAuto(reason)
    config.autoHop = false
    updateAuto()
    setStatus(reason)
    log(reason)
end

local function attemptHop(force)
    if not state.running
    or state.found
    or state.hopping
    or state.teleporting then
        return
    end

    if not force and not config.autoHop then
        return
    end

    state.hopping = true
    setStatus("Buscando servidor disponible...")

    local servers, err = availableServers()

    if not servers then
        state.hopping = false
        stopAuto("AUTO HOP DETENIDO: " .. tostring(err))
        return
    end

    if #servers == 0 then
        state.hopping = false
        stopAuto("No hay servidores nuevos disponibles")
        return
    end

    local target = servers[1]

    state.visited[game.JobId] = true
    state.visited[target.id] = true

    local queued = saveForNextServer()

    state.hopToken = state.hopToken + 1
    local token = state.hopToken

    state.hopping = false
    state.teleporting = true

    setStatus(
        "Entrando a servidor | "
        .. tostring(target.free)
        .. " plazas libres"
    )

    log("TELEPORT | " .. target.id
        .. " | Queue=" .. tostring(queued))

    if not queued then
        results.Text =
            "ADVERTENCIA: no se pudo preparar\n"
            .. "el reinicio automatico en Delta.\n"
            .. "Puede requerir ejecutar el script otra vez."
    end

    -- Se registra el fallo sin bloquear todo el script.
    task.spawn(function()
        local ok, teleportErr = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                target.id,
                player
            )
        end)

        if not ok
        and state.running
        and state.hopToken == token then
            state.failed[target.id] = true
            state.teleporting = false
            state.nextHopAt = os.clock() + 3

            log("TELEPORT ERROR: " .. tostring(teleportErr))
            setStatus("Error de servidor; buscando otro")
        end
    end)

    -- Temporizador local: solo funciona mientras el
    -- cliente siga ejecutando Luau.
    task.delay(config.maxTeleportWait, function()
        if not state.running
        or state.found
        or state.hopToken ~= token
        or not state.teleporting then
            return
        end

        state.failed[target.id] = true
        state.teleporting = false
        state.nextHopAt = os.clock() + 3

        setStatus("Espera agotada; intentando recuperar")
        log("TIMEOUT | " .. target.id)

        -- Si Roblox mantiene una pantalla de cola
        -- bloqueante, este intento podria no funcionar.
    end)
end

-- Roblox puede avisar cuando un teletransporte
-- no consigue iniciarse.
connect(TeleportService.TeleportInitFailed, function(
    failedPlayer, result, message, placeId, options
)
    if failedPlayer ~= player then return end
    if not state.running or state.found then return end

    state.hopToken = state.hopToken + 1
    state.teleporting = false
    state.hopping = false
    state.nextHopAt = os.clock() + 3

    local reason =
        tostring(result) .. " | " .. tostring(message)

    setStatus("Servidor rechazado; probando otro")
    log("TeleportInitFailed: " .. reason)
end)

local function stop()
    state.running = false
    config.autoHop = false
    state.hopToken = state.hopToken + 1

    for _, c in ipairs(connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
end

G.EggFinderStop = stop

-- Controles.
connect(minimumInput.FocusLost, function()
    local n = tonumber(minimumInput.Text)

    if n and n > 0 and n <= 1000 then
        config.minimum = n
    else
        minimumInput.Text = tostring(config.minimum)
    end

    updatePresets()
end)

connect(autoButton.MouseButton1Click, function()
    if state.found then return end

    config.autoHop = not config.autoHop
    updateAuto()

    if config.autoHop then
        state.nextHopAt = os.clock() + 2
    end
end)

connect(scanButton.MouseButton1Click, function()
    task.spawn(scan)
end)

connect(skipButton.MouseButton1Click, function()
    if state.found then return end

    -- Invalida el intento anterior en el script.
    -- No cancela necesariamente una cola de Roblox.
    state.hopToken = state.hopToken + 1
    state.teleporting = false
    state.hopping = false
    state.nextHopAt = os.clock() + 2

    task.spawn(function()
        attemptHop(true)
    end)
end)

connect(pauseButton.MouseButton1Click, function()
    config.autoHop = false
    updateAuto()
    setStatus("Busqueda automatica pausada")
end)

connect(copyButton.MouseButton1Click, function()
    local lines = {
        "EGG FINDER V26.1",
        "JobId: " .. tostring(game.JobId),
        "PlaceId: " .. tostring(game.PlaceId),
        "Minimo: " .. tostring(config.minimum),
        "Huevos: " .. tostring(state.eggCount),
        "Servidores: " .. tostring(state.serversChecked),
        "Encontrado: " .. tostring(state.found),
        "Sin zona: " .. tostring(state.unknownZones),
        "Ultimo: " .. state.lastMessage
    }

    for _, c in ipairs(state.candidates) do
        table.insert(lines, string.format(
            "%s | %.2f | %s | Score %.1f",
            c.zone,
            c.height,
            c.rarity,
            c.score
        ))
    end

    local clipboard = setclipboard or toclipboard

    if clipboard then
        local ok = pcall(function()
            clipboard(table.concat(lines, "\n"))
        end)

        setStatus(
            ok and "Resumen enviado al portapapeles"
            or "Error al copiar"
        )
    else
        setStatus("Portapapeles no disponible")
    end
end)

connect(restartButton.MouseButton1Click, function()
    state.found = false
    state.hopping = false
    state.teleporting = false
    state.hopToken = state.hopToken + 1

    config.autoHop = false
    updateAuto()

    if alertFrame then
        alertFrame:Destroy()
        alertFrame = nil
    end

    setStatus("Reiniciado: escaneo manual")
    task.spawn(scan)
end)

connect(closeButton.MouseButton1Click, function()
    stop()
    gui:Destroy()
end)

-- Arrastrar panel.
do
    local dragging = false
    local dragStart
    local startPos
    local activeInput

    connect(header.InputBegan, function(input)
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

    connect(UserInputService.InputChanged, function(input)
        if not dragging then return end

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
        or input == activeInput then

            local delta = input.Position - dragStart

            panel.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input == activeInput
        or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Recuperar datos al entrar en otro servidor.
do
    local saved = G.EggFinderV261Resume

    if type(saved) == "string" then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(saved)
        end)

        if ok and type(data) == "table" then
            config.minimum = tonumber(data.minimum) or 10
            config.autoHop = data.auto == true
            state.serversChecked =
                (tonumber(data.checked) or 1) + 1

            for _, id in ipairs(data.visited or {}) do
                state.visited[id] = true
            end

            for _, id in ipairs(data.failed or {}) do
                state.failed[id] = true
            end
        end

        G.EggFinderV261Resume = nil
    end
end

state.visited[game.JobId] = true

minimumInput.Text = tostring(config.minimum)
updatePresets()
updateAuto()

log("V26.1 iniciado | Minimo=" .. config.minimum)

-- Bucle principal.
task.spawn(function()
    setStatus("Esperando carga de huevos...")

    task.wait(config.loadWait)

    while state.running do
        if not state.found and not state.teleporting then
            if os.clock() - state.lastScanAt
                >= config.scanInterval then

                scan()
                state.lastScanAt = os.clock()
            end

            if config.autoHop
            and not state.found
            and not state.hopping
            and os.clock() >= state.nextHopAt then

                if state.eggCount >= 60 then
                    if state.unknownZones > 0 then
                        stopAuto(
                            "Revision necesaria: zona desconocida"
                        )
                    else
                        state.nextHopAt = os.clock() + 5

                        task.spawn(function()
                            attemptHop(false)
                        end)
                    end

                elseif os.clock()
                    - state.serverEnteredAt > 35 then

                    -- No abandonar una zona con huevos
                    -- incompletos: podria estar cargando.
                    stopAuto(
                        "Carga incompleta: revisar servidor"
                    )
                end
            end
        end

        task.wait(1)
    end
end)
