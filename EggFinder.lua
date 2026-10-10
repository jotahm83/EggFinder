
--[[
 EGG FINDER V26.3
 - Panel compacto
 - Servidores con menos jugadores
 - Seleccion aleatoria entre servidores disponibles
 - Evita repetir servidores fallidos
 - Intenta gestionar errores Roblox 771 y 279
 - Continua con huevos menores al minimo
 - Se detiene solo ante un especial suficientemente grande
 - AUTO HOP puede reanudarse despues del aviso

 AVISO:
 Los efectos visuales permiten estimar candidatos
 Secret / Eternal / Divine, no verificar su rareza.
 Los errores de conexion de Roblox no siempre
 pueden recuperarse desde un script cliente.
]]

local G = getgenv()

for _, key in ipairs({
    "EggFinderStop",
    "EggFinderV26Stop",
    "EggFinderV262Stop",
    "EggFinderV263Stop"
}) do
    if type(G[key]) == "function" then
        pcall(G[key])
    end
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local URL =
    "https://raw.githubusercontent.com/jotahm83/EggFinder/main/EggFinder.lua"

local C = {
    minimum = 10,
    auto = true,
    scanEvery = 2,
    initialWait = 12,
    teleportTimeout = 20,
    minFree = 5,
    pages = 6,
    candidateLimit = 40,
    retryDelay = 3
}

local S = {
    running = true,
    found = false,
    hopping = false,
    teleporting = false,
    token = 0,
    checked = 1,
    visited = {},
    failed = {},
    candidates = {},
    eggCount = 0,
    unknown = 0,
    last = "",
    scanBusy = false,
    enteredAt = os.clock(),
    lastScan = 0,
    nextHop = 0,
    target = nil,
    errorAttempts = {},
    loaded = false
}

local connections = {}
local alert
local requestHop

local function bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local function ui(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    ui("UICorner", {
        CornerRadius = UDim.new(0, radius or 7)
    }, obj)
end

for _, name in ipairs({
    "EggFinderV26",
    "EggFinderV261",
    "EggFinderV262",
    "EggFinderV263"
}) do
    local old = pg:FindFirstChild(name)
    if old then old:Destroy() end
end

local screen = ui("ScreenGui", {
    Name = "EggFinderV263",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999
}, pg)

-- 260 x 350: aproximadamente 45% menos
-- superficie que el panel anterior de 340 x 490.
local panel = ui("Frame", {
    Size = UDim2.fromOffset(260, 350),
    Position = UDim2.new(0.5, -130, 0.5, -175),
    BackgroundColor3 = Color3.fromRGB(19, 24, 36),
    BorderSizePixel = 0,
    Active = true
}, screen)
round(panel, 10)

ui("UIStroke", {
    Color = Color3.fromRGB(55, 125, 190),
    Thickness = 1.2
}, panel)

local header = ui("Frame", {
    Size = UDim2.new(1, 0, 0, 33),
    BackgroundColor3 = Color3.fromRGB(29, 44, 70),
    BorderSizePixel = 0,
    Active = true
}, panel)
round(header, 10)

ui("TextLabel", {
    Text = "EGG FINDER V26.3",
    Position = UDim2.fromOffset(9, 0),
    Size = UDim2.new(1, -42, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(115, 220, 255),
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local function btn(text, x, y, w, h, color, parent)
    local b = ui("TextButton", {
        Text = text,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 =
            color or Color3.fromRGB(45, 77, 115),
        BorderSizePixel = 0,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = true
    }, parent or panel)
    round(b, 6)
    return b
end

local close = btn(
    "X", 230, 4, 26, 25,
    Color3.fromRGB(160, 50, 58), header
)

local function lbl(text, x, y, w, h, size, color)
    return ui("TextLabel", {
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

local status = lbl(
    "Iniciando...", 9, 39, 242, 31,
    11, Color3.fromRGB(255, 215, 110)
)

lbl("MINIMO (STUDS)", 9, 74, 200, 15, 10)

local presets = {6, 8, 10, 12, 15}
local presetButtons = {}

for i, n in ipairs(presets) do
    presetButtons[i] = btn(
        tostring(n),
        9 + (i - 1) * 49,
        94, 45, 25
    )
end

local minimumInput = ui("TextBox", {
    Position = UDim2.fromOffset(9, 125),
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
round(minimumInput, 6)

local autoBtn = btn(
    "AUTO: SI", 9, 161, 116, 27,
    Color3.fromRGB(30, 130, 95)
)

local scanBtn = btn(
    "ESCANEAR", 135, 161, 116, 27
)

local skipBtn = btn(
    "SALTAR", 9, 194, 116, 27,
    Color3.fromRGB(100, 80, 145)
)

local pauseBtn = btn(
    "PAUSAR", 135, 194, 116, 27,
    Color3.fromRGB(130, 90, 40)
)

local stats = lbl(
    "Servidores: 1 | Huevos: 0",
    9, 229, 242, 21,
    10, Color3.fromRGB(180, 220, 255)
)

local results = lbl(
    "Esperando escaneo...",
    9, 252, 242, 54, 10
)
results.TextYAlignment = Enum.TextYAlignment.Top

local copyBtn = btn(
    "COPIAR", 9, 313, 116, 27
)

local restartBtn = btn(
    "REINICIAR", 135, 313, 116, 27,
    Color3.fromRGB(95, 65, 130)
)

local function statusText(text, color)
    status.Text = text
    status.TextColor3 =
        color or Color3.fromRGB(255, 215, 110)
end

local function log(text)
    S.last = tostring(text)
    print("[EGG FINDER V26.3] " .. S.last)
end

local function refreshAuto()
    autoBtn.Text = C.auto and "AUTO: SI" or "AUTO: NO"
    autoBtn.BackgroundColor3 =
        C.auto
        and Color3.fromRGB(30, 130, 95)
        or Color3.fromRGB(125, 65, 70)
end

local function refreshPresets()
    for i, b in ipairs(presetButtons) do
        b.BackgroundColor3 =
            C.minimum == presets[i]
            and Color3.fromRGB(30, 145, 105)
            or Color3.fromRGB(45, 77, 115)
    end
end

for i, n in ipairs(presets) do
    bind(presetButtons[i].MouseButton1Click, function()
        C.minimum = n
        minimumInput.Text = tostring(n)
        refreshPresets()
    end)
end

bind(minimumInput.FocusLost, function()
    local n = tonumber(minimumInput.Text)
    if n and n > 0 and n <= 1000 then
        C.minimum = n
    else
        minimumInput.Text = tostring(C.minimum)
    end
    refreshPresets()
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
    return tostring(text or ""):lower():gsub("[^%w]", "")
end

local function matchZone(text)
    local n = normalize(text)
    for _, z in ipairs(zones) do
        for _, alias in ipairs(z.aliases) do
            if n:find(alias, 1, true) then
                return z.name
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

local function positionOf(obj)
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

local function getNests()
    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")
    local nests = {}

    if not guards then return nests end

    for _, obj in ipairs(guards:GetDescendants()) do
        if obj:IsA("BasePart")
        and obj.Name == "EggFitBounds" then
            table.insert(nests, {
                pos = obj.Position,
                zone = zoneFromTree(obj)
            })
        end
    end

    return nests
end

local function getZone(egg, nests)
    local direct = zoneFromTree(egg)
    if direct then return direct end

    local pos = positionOf(egg)
    if not pos then return nil end

    local nearest, distance = nil, math.huge

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

local function getHeight(egg)
    local low, high = math.huge, -math.huge
    local count = 0

    for _, part in ipairs(egg:GetDescendants()) do
        if part:IsA("BasePart")
        and part.Transparency < 0.98
        and part.Size.Magnitude > 0.05 then

            local cf = part.CFrame
            local s = part.Size

            local half =
                math.abs(cf.RightVector.Y) * s.X / 2
                + math.abs(cf.UpVector.Y) * s.Y / 2
                + math.abs(cf.LookVector.Y) * s.Z / 2

            low = math.min(low, cf.Position.Y - half)
            high = math.max(high, cf.Position.Y + half)
            count = count + 1
        end
    end

    if count > 0 then return high - low end

    if egg:IsA("Model") then
        local ok, _, size = pcall(function()
            return egg:GetBoundingBox()
        end)
        if ok then return size.Y end
    end

    return 0
end

local function effectsOf(egg)
    local particles, highlights = 0, 0
    local beams, trails, lights = 0, 0, 0
    local pink = false

    for _, obj in ipairs(egg:GetDescendants()) do
        if obj:IsA("ParticleEmitter") and obj.Enabled then
            particles = particles + 1

        elseif obj:IsA("Highlight") and obj.Enabled then
            highlights = highlights + 1

            local c = obj.OutlineColor
            if c.R > 0.65
            and c.B > 0.3
            and c.G < 0.55
            and obj.OutlineTransparency < 0.8 then
                pink = true
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

    return special,
        pink and "POSIBLE ETERNAL"
        or "ESPECIAL (SIN CONFIRMAR)"
end

local function dismissAlert()
    if alert then
        alert:Destroy()
        alert = nil
    end
end

local function playSound()
    pcall(function()
        local sound = ui("Sound", {
            SoundId = "rbxasset://sounds/electronicpingshort.wav",
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

    alert = ui("Frame", {
        Size = UDim2.new(0.9, 0, 0, 145),
        Position = UDim2.new(0.05, 0, 0.08, 0),
        BackgroundColor3 = Color3.fromRGB(20, 95, 55),
        BorderSizePixel = 0,
        ZIndex = 50
    }, screen)
    round(alert, 10)

    ui("UIStroke", {
        Color = Color3.fromRGB(75, 255, 150),
        Thickness = 3
    }, alert)

    ui("TextLabel", {
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
    }, alert)

    local dismiss = ui("TextButton", {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.new(0, 8, 1, -34),
        Text = "CERRAR AVISO",
        BackgroundColor3 = Color3.fromRGB(45, 145, 85),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        ZIndex = 51
    }, alert)
    round(dismiss, 6)

    bind(dismiss.MouseButton1Click, dismissAlert)

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
        task.delay((i - 1) * 0.7, function()
            if S.running and S.found then
                playSound()
            end
        end)
    end
end

local function scan()
    if not S.running or S.found
    or S.hopping or S.teleporting
    or S.scanBusy then
        return
    end

    S.scanBusy = true

    local ok, err = pcall(function()
        local folder =
            workspace:FindFirstChild("AreaEggSlotsClient")

        if not folder then
            S.eggCount = 0
            return
        end

        local eggs = {}

        for _, egg in ipairs(folder:GetChildren()) do
            if egg:IsA("Model")
            or egg:IsA("BasePart") then
                table.insert(eggs, egg)
            end
        end

        S.eggCount = #eggs

        local nests = getNests()
        local candidates = {}
        local unknown = 0
        local best

        for _, egg in ipairs(eggs) do
            local special, rarity = effectsOf(egg)

            if special then
                local zone = getZone(egg, nests)

                if zone then
                    local height = getHeight(egg)

                    local c = {
                        zone = zone,
                        height = height,
                        rarity = rarity
                    }

                    table.insert(candidates, c)

                    if height >= C.minimum
                    and (not best or height > best.height) then
                        best = c
                    end
                else
                    unknown = unknown + 1
                end
            end
        end

        S.candidates = candidates
        S.unknown = unknown

        stats.Text = string.format(
            "Servidores: %d | Huevos: %d | Esp.: %d",
            S.checked,
            S.eggCount,
            #candidates
        )

        if best then
            S.found = true
            C.auto = false
            refreshAuto()

            statusText(
                "¡HUEVO ENCONTRADO!",
                Color3.fromRGB(80, 255, 150)
            )

            results.Text = string.format(
                "%s\n%.2f studs | %s",
                best.zone,
                best.height,
                best.rarity
            )

            log("ENCONTRADO | "
                .. best.zone
                .. " | "
                .. best.height)

            showFound(best)
            return
        end

        table.sort(candidates, function(a, b)
            return a.height > b.height
        end)

        if #candidates > 0 then
            local c = candidates[1]

            results.Text = string.format(
                "Mayor: %s\n%.2f / %.2f studs\nNo cumple: continuar",
                c.zone,
                c.height,
                C.minimum
            )
        else
            results.Text =
                "Sin especiales validos.\nContinuar buscando..."
        end

        if unknown > 0 then
            results.Text = results.Text
                .. "\nSin zona: " .. unknown
        end

        statusText(
            "Buscando | Minimo " .. C.minimum
        )

        log(string.format(
            "SCAN | Huevos=%d | Especiales=%d | SinZona=%d",
            S.eggCount, #candidates, unknown
        ))
    end)

    S.scanBusy = false

    if not ok then
        warn("[EGG FINDER V26.3] " .. tostring(err))
        statusText("Error de escaneo")
    end
end

-- HTTP
local function httpGet(url)
    local req =
        (syn and syn.request)
        or http_request
        or request

    if type(req) == "function" then
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

-- Buscar servidores poco poblados.
-- Asc solicita primero los menos ocupados.
-- Se elige al azar entre candidatos validos.
local function findServers()
    local pool = {}
    local cursor = nil

    for page = 1, C.pages do
        local url =
            "https://games.roblox.com/v1/games/"
            .. tostring(game.PlaceId)
            .. "/servers/Public?sortOrder=Asc&limit=100"

        if cursor then
            url = url
                .. "&cursor="
                .. HttpService:UrlEncode(cursor)
        end

        local body = httpGet(url)
        if not body then
            return nil, "API de servidores inaccesible"
        end

        local ok, data = pcall(function()
            return HttpService:JSONDecode(body)
        end)

        if not ok or type(data) ~= "table" then
            return nil, "Lista de servidores invalida"
        end

        for _, server in ipairs(data.data or {}) do
            local free =
                (server.maxPlayers or 0)
                - (server.playing or 0)

            if server.id
            and server.id ~= game.JobId
            and not S.visited[server.id]
            and not S.failed[server.id]
            and free >= C.minFree then
                table.insert(pool, {
                    id = server.id,
                    free = free,
                    playing = server.playing or 0
                })
            end
        end

        cursor = data.nextPageCursor

        if not cursor or #pool >= C.candidateLimit then
            break
        end
    end

    table.sort(pool, function(a, b)
        return a.playing < b.playing
    end)

    -- Seleccion aleatoria entre los menos ocupados.
    local top = math.min(#pool, C.candidateLimit)
    local choices = {}

    for i = 1, top do
        table.insert(choices, pool[i])
    end

    return choices
end

local function queueNext()
    local queue =
        queue_on_teleport
        or (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)

    if type(queue) ~= "function" then
        return false
    end

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

    local data = HttpService:JSONEncode({
        minimum = C.minimum,
        auto = C.auto,
        checked = S.checked,
        visited = visited,
        failed = failed
    })

    local code =
        "getgenv().EggFinderV263Resume="
        .. string.format("%q", data)
        .. "\nloadstring(game:HttpGet("
        .. string.format("%q", URL)
        .. "))()"

    return pcall(function()
        queue(code)
    end)
end

local function markFailed(reason)
    if S.target then
        S.failed[S.target] = true
    end

    S.token = S.token + 1
    S.teleporting = false
    S.hopping = false
    S.target = nil
    S.nextHop = os.clock() + C.retryDelay

    statusText("Servidor fallido; siguiente...")
    log("SERVIDOR FALLIDO | " .. tostring(reason))
end

requestHop = function(force)
    if not S.running
    or S.found
    or S.hopping
    or S.teleporting then
        return
    end

    if not force and not C.auto then
        return
    end

    S.hopping = true
    statusText("Buscando servidor con pocos jugadores...")

    local servers, err = findServers()

    if not S.running then
        S.hopping = false
        return
    end

    if not servers then
        S.hopping = false
        C.auto = false
        refreshAuto()
        statusText(tostring(err))
        return
    end

    if #servers == 0 then
        S.hopping = false
        C.auto = false
        refreshAuto()
        statusText("Sin servidores nuevos disponibles")
        return
    end

    local target = servers[math.random(1, #servers)]

    S.visited[game.JobId] = true
    S.visited[target.id] = true
    S.target = target.id

    local queued = queueNext()

    S.token = S.token + 1
    local token = S.token

    S.hopping = false
    S.teleporting = true

    statusText(
        "Entrando | "
        .. target.playing
        .. " jugadores | "
        .. target.free
        .. " libres"
    )

    log("TELEPORT | "
        .. target.id
        .. " | Queue="
        .. tostring(queued))

    task.spawn(function()
        local ok, errorText = pcall(function()
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                target.id,
                player
            )
        end)

        if not ok
        and S.running
        and S.token == token then
            markFailed(errorText)
        end
    end)

    task.delay(C.teleportTimeout, function()
        if S.running
        and not S.found
        and S.token == token
        and S.teleporting then
            markFailed("TIMEOUT 20s")
        end
    end)
end

-- Evento oficial de error de teletransporte.
bind(TeleportService.TeleportInitFailed, function(
    failedPlayer, result, message
)
    if failedPlayer ~= player then return end
    if not S.running or S.found then return end

    markFailed(
        tostring(result) .. " | " .. tostring(message)
    )
end)

-- Intento limitado de cerrar dialogos de error
-- de Roblox. No busca botones fuera de CoreGui.
-- Activate() puede no ser suficiente en algunos
-- clientes; no se garantiza su funcionamiento.
local function tryHandleRobloxError()
    if not S.running or S.found then return end

    local ok, root = pcall(function()
        return CoreGui:FindFirstChild("RobloxGui")
    end)

    if not ok or not root then return end

    local errorContainers = {}

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("GuiObject")
        and (
            obj.Name == "ErrorPrompt"
            or obj.Name == "ErrorFrame"
        ) then
            table.insert(errorContainers, obj)
        end
    end

    for _, container in ipairs(errorContainers) do
        if not container.Visible then continue end

        local texts = {}
        local buttons = {}

        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("TextLabel") then
                table.insert(texts, obj.Text)
            elseif obj:IsA("TextButton") then
                table.insert(buttons, obj)
                table.insert(texts, obj.Text)
            end
        end

        local content = table.concat(texts, " "):lower()

        local is771 =
            content:find("771", 1, true) ~= nil

        local is279 =
            content:find("279", 1, true) ~= nil

        if not is771 and not is279 then
            continue
        end

        local key = is771 and "771" or "279"
        local now = os.clock()

        if now - (S.errorAttempts[key] or 0) < 6 then
            continue
        end

        S.errorAttempts[key] = now

        log("VENTANA ROBLOX | ERROR " .. key)

        -- Solo botones del propio dialogo de error.
        -- Preferimos Aceptar o Cancelar, no Reintentar,
        -- porque Reintentar podria repetir el mismo
        -- servidor que acaba de fallar.
        local chosen

        for _, b in ipairs(buttons) do
            local t = normalize(b.Text)

            if t == "aceptar"
            or t == "cancelar"
            or t == "ok"
            or t == "close" then
                chosen = b
                break
            end
        end

        if chosen then
            pcall(function()
                chosen:Activate()
            end)
        end

        -- Aunque la ventana siga visible, registrar
        -- el servidor fallido para no repetirlo.
        if S.target then
            markFailed("ROBLOX " .. key)
        end
    end
end

-- Reanudar despues de encontrar un huevo.
local function resume()
    S.found = false
    dismissAlert()

    C.auto = true
    refreshAuto()

    S.token = S.token + 1
    S.hopping = false
    S.teleporting = false
    S.target = nil
    S.nextHop = 0

    statusText(
        "AUTO REANUDADO",
        Color3.fromRGB(90, 235, 165)
    )

    task.spawn(function()
        requestHop(true)
    end)
end

bind(autoBtn.MouseButton1Click, function()
    if S.found then
        resume()
        return
    end

    C.auto = not C.auto
    refreshAuto()

    if C.auto then
        S.nextHop = 0
        statusText("AUTO ACTIVADO")

        if not S.teleporting then
            task.spawn(function()
                requestHop(true)
            end)
        end
    else
        statusText("AUTO PAUSADO")
    end
end)

bind(scanBtn.MouseButton1Click, function()
    if not S.found then
        task.spawn(scan)
    end
end)

bind(skipBtn.MouseButton1Click, function()
    if S.found then
        resume()
        return
    end

    if S.target then
        S.failed[S.target] = true
    end

    S.token = S.token + 1
    S.teleporting = false
    S.hopping = false
    S.target = nil

    task.spawn(function()
        requestHop(true)
    end)
end)

bind(pauseBtn.MouseButton1Click, function()
    C.auto = false
    refreshAuto()
    statusText("BUSQUEDA PAUSADA")
end)

bind(copyBtn.MouseButton1Click, function()
    local lines = {
        "EGG FINDER V26.3",
        "JobId: " .. game.JobId,
        "PlaceId: " .. game.PlaceId,
        "Minimo: " .. C.minimum,
        "Auto: " .. tostring(C.auto),
        "Huevos: " .. S.eggCount,
        "Servidores: " .. S.checked,
        "Encontrado: " .. tostring(S.found),
        "Sin zona: " .. S.unknown,
        "Ultimo: " .. S.last
    }

    for _, c in ipairs(S.candidates) do
        table.insert(lines, string.format(
            "%s | %.2f | %s",
            c.zone, c.height, c.rarity
        ))
    end

    local clipboard = setclipboard or toclipboard

    if type(clipboard) == "function" then
        local ok = pcall(function()
            clipboard(table.concat(lines, "\n"))
        end)

        statusText(
            ok and "RESUMEN COPIADO"
            or "ERROR AL COPIAR"
        )
    else
        statusText("SIN PORTAPAPELES")
    end
end)

bind(restartBtn.MouseButton1Click, function()
    S.found = false
    S.token = S.token + 1
    S.hopping = false
    S.teleporting = false
    S.target = nil

    dismissAlert()

    C.auto = false
    refreshAuto()

    statusText("REINICIADO")
    task.spawn(scan)
end)

local function stop()
    S.running = false
    C.auto = false
    S.token = S.token + 1

    for _, c in ipairs(connections) do
        pcall(function()
            c:Disconnect()
        end)
    end
end

G.EggFinderStop = stop
G.EggFinderV263Stop = stop

bind(close.MouseButton1Click, function()
    stop()
    screen:Destroy()
end)

-- Arrastrar panel.
do
    local dragging = false
    local dragStart
    local startPos
    local active

    bind(header.InputBegan, function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
        or input.UserInputType ==
            Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
            active = input
        end
    end)

    bind(UIS.InputChanged, function(input)
        if not dragging then return end

        if input.UserInputType ==
            Enum.UserInputType.MouseMovement
        or input == active then
            local delta = input.Position - dragStart

            panel.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    bind(UIS.InputEnded, function(input)
        if input == active
        or input.UserInputType ==
            Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Recuperar configuracion entre servidores.
do
    local saved = G.EggFinderV263Resume

    if type(saved) == "string" then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(saved)
        end)

        if ok and type(data) == "table" then
            C.minimum = tonumber(data.minimum) or 10
            C.auto = data.auto == true
            S.checked = (tonumber(data.checked) or 1) + 1

            for _, id in ipairs(data.visited or {}) do
                S.visited[id] = true
            end

            for _, id in ipairs(data.failed or {}) do
                S.failed[id] = true
            end
        end

        G.EggFinderV263Resume = nil
    end
end

S.visited[game.JobId] = true

minimumInput.Text = tostring(C.minimum)
refreshPresets()
refreshAuto()

log("V26.3 INICIADO | Minimo=" .. C.minimum)

-- Supervisor de ventanas de error.
task.spawn(function()
    while S.running do
        pcall(tryHandleRobloxError)
        task.wait(2)
    end
end)

-- Bucle principal.
task.spawn(function()
    statusText("Cargando huevos...")

    task.wait(C.initialWait)
    S.loaded = true

    while S.running do
        if not S.found
        and not S.hopping
        and not S.teleporting then

            if os.clock() - S.lastScan >= C.scanEvery then
                scan()
                S.lastScan = os.clock()
            end

            if C.auto
            and not S.found
            and not S.hopping
            and not S.teleporting
            and os.clock() >= S.nextHop then

                if S.eggCount >= 60 then
                    S.nextHop = os.clock() + 5

                    task.spawn(function()
                        requestHop(false)
                    end)

                elseif os.clock() - S.enteredAt > 35 then
                    -- Si la carpeta no termina de cargar,
                    -- pausar para no perder un huevo.
                    C.auto = false
                    refreshAuto()
                    statusText("CARGA INCOMPLETA")
                end
            end
        end

        task.wait(1)
    end
end)
