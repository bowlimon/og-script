local placeRemote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StampAsset")



do
    local a = game:GetService("Lighting"):WaitForChild("Blur", 2)
    if a then a:Destroy() end
    game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
    local b = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainScreen", 2)
    if b then b:Destroy() end
end

game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("InitialSpawn"):FireServer()

if not game.Players.LocalPlayer.Character then
    game.Players.LocalPlayer.CharacterAdded:Wait()
    task.wait(2)
end



--check if another bot is in the server via a three way handshake
--do not accept a polo if we've surpassed 5 seconds to avoid players kicking us
do
    local chatRemote = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
    
    local function chat(msg)
        chatRemote:FireServer(msg, "All")
    end
    
    local botAlreadyHere = false
    local sentMessage = false
    
    local t1 = tick()
    
    --await message reply
    local connections = {}
    
    local function cleanup()
        for _, c in ipairs(connections) do
            c:Disconnect()
        end
        table.clear(connections)
    end
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player == game.Players.LocalPlayer then continue end
        connections[#connections + 1] = player.Chatted:Connect(function(msg)
            if msg == "polo" and sentMessage and math.abs(tick() - t1) <= 5 then
                botAlreadyHere = true
                cleanup()
            elseif msg == "marco" then
                chat("polo")
            end
        end)
    end
    
    chat("marco")
    sentMessage = true
end


local platePart = nil
for _, plate in next, workspace:WaitForChild("Plates"):GetChildren() do
    if plate.Owner.Value == game.Players.LocalPlayer then
        platePart = plate.Plate
        break
    end
end

if not platePart then
    return warn("Couldn't find your plate!")
end

local ASSET_NAME = "Weathervane" --has to be accurate!

local asset = nil
for _, category in next, game.ReplicatedStorage:WaitForChild("Sets"):GetChildren() do
    for _, v in next, category:GetChildren() do
        if v.Name == ASSET_NAME then
            asset = v
            break
        end
    end
end

if not asset then
    return warn("Couldn't find asset!")
end

local refPart = asset:FindFirstChildWhichIsA("BasePart", true)
local refPartId = refPart:GetAttribute("PartID")

local t1 = tick()
local teleported = false
task.spawn(function()
    repeat
        task.wait()
    until botAlreadyHere or #game:GetService("Players"):GetPlayers() <= 2 or math.abs(tick() - t1) > 190
    
    while not teleported do
        print("attempting to teleport")
        local x = {}
        for _, v in ipairs(game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data) do
            if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= game.JobId then
                x[#x + 1] = v.id
            end
        end
        if #x > 0 then
            local success, err = pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, x[math.random(1, #x)])
            end)
            if not success then
                warn(err)
            else
                teleported = true
            end
        end
        task.wait(2)
    end
end)

while true do
    local parts = {}
    local cache = {}
    
    for _, d in next, game.Players:GetPlayers() do
        if d.Character then
            for _, a in ipairs(d.Character:GetDescendants()) do
                if not a:IsA("BasePart") then continue end
                parts[#parts + 1] = a
                cache[a] = true
            end
        end
    end
    
    task.spawn(function()
        placeRemote:InvokeServer(
            asset.AssetId.Value,
            platePart.CFrame + Vector3.new(0, platePart.Position.Y - 100, 0),
            refPartId,
            parts,
            0
        )
    end)
    
    task.wait(0.3)
end