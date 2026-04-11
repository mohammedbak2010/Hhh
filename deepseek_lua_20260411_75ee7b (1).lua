-- H2N v5.8 - FULL SCRIPT

repeat task.wait() until game:IsLoaded()
if not game.PlaceId then repeat task.wait(1) until game.PlaceId end

pcall(function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name and (v.Name:find("H2N_WP_") or v.Name:find("H2N_Duel_")) then
            v:Destroy()
        end
    end
end)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Char, HRP, Hum

local fireproximityprompt = fireproximityprompt or function(prompt)
    if not prompt then return end
    pcall(function()
        if prompt.InputHoldBegin then
            prompt.InputHoldBegin()
            task.wait(0.05)
            prompt.InputHoldEnd()
        end
    end)
end

local function SafeWriteFile(name, data)
    pcall(function() if writefile then writefile(name, data) end end)
end

local function SafeReadFile(name)
    local success, result = pcall(function() if readfile then return readfile(name) end end)
    if success and result then return result end
    return nil
end

local Colors = {
    White = Color3.fromRGB(14,14,20), LightGray = Color3.fromRGB(22,22,32),
    MediumGray = Color3.fromRGB(90,60,220), DarkGray = Color3.fromRGB(70,45,190),
    VeryDark = Color3.fromRGB(8,8,14), AlmostBlack = Color3.fromRGB(5,5,10),
    Border = Color3.fromRGB(110,80,255), Text = Color3.fromRGB(230,225,255),
    SubText = Color3.fromRGB(150,130,220), Success = Color3.fromRGB(60,210,130),
    Error = Color3.fromRGB(255,75,75), DotOff = Color3.fromRGB(35,30,60),
    DotOn = Color3.fromRGB(130,100,255), DiscordBlue = Color3.fromRGB(140,110,255),
}

local _notifyQueue = {}
local gui = nil

local function Notify(txt)
    if gui then
        local f = Instance.new("Frame", gui)
        f.Size = UDim2.new(0,270,0,42)
        f.Position = UDim2.new(1,-290,1,-100)
        f.AnchorPoint = Vector2.new(0,1)
        f.BackgroundColor3 = Colors.White
        f.BackgroundTransparency = 0.1
        f.ZIndex = 70
        Instance.new("UICorner", f).CornerRadius = UDim.new(0,10)
        Instance.new("UIStroke", f).Color = Colors.MediumGray
        local fl = Instance.new("TextLabel", f)
        fl.Size = UDim2.new(1,0,1,0)
        fl.BackgroundTransparency = 1
        fl.Text = txt
        fl.TextColor3 = Colors.Text
        fl.Font = Enum.Font.GothamBold
        fl.TextSize = 14
        task.spawn(function() task.wait(3); f:Destroy() end)
    else
        table.insert(_notifyQueue, txt)
    end
end

local function Setup(c)
    Char = c
    HRP = c:WaitForChild("HumanoidRootPart")
    Hum = c:WaitForChild("Humanoid")
    pcall(function() HRP:SetNetworkOwner(LP) end)
end

if LP.Character then Setup(LP.Character) end
LP.CharacterAdded:Connect(function(c)
    task.wait(0.1)
    Setup(c)
    pcall(function()
        _grabCallbackCache = {}
    end)
end)

local State = {
    AutoPlayLeft = false, AutoPlayRight = false, AutoBat = false,
    AntiRagdoll = false, InfiniteJump = false, XrayBase = false,
    ESP = false, AntiSentry = false, SpinBody = false, FloatEnabled = false,
    SpeedBoostEnabled = false, AutoGrab = false, Optimizer = false,
    HitCircle = false, SpamBat = false,
}

local SpeedSettings = { NormalSpeed = 59, StealSpeed = 30 }
local isSpeedBoostEnabled = false
local speedConn = nil
local speedBoostWasOnBeforeAutoBat = false
local speedBoostWasOnBeforeAutoPlay = false

local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isHoldingBrainrot()
    local char = LP.Character
    if not char then return false end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and (child.Name:lower():find("brainrot") or child.Name:lower():find("brain")) then
            return true
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed < 27 then return true end
    return false
end

local function startSpeedBoost()
    if isSpeedBoostEnabled then return end
    isSpeedBoostEnabled = true
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not isSpeedBoostEnabled then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            local targetSpeed = isHoldingBrainrot() and SpeedSettings.StealSpeed or SpeedSettings.NormalSpeed
            local targetX = moveDir.X * targetSpeed
            local targetZ = moveDir.Z * targetSpeed
            local curVel = hrp.AssemblyLinearVelocity
            local diffX = targetX - curVel.X
            local diffZ = targetZ - curVel.Z
            if math.abs(diffX) > targetSpeed * 0.5 or math.abs(diffZ) > targetSpeed * 0.5 then
                hrp.AssemblyLinearVelocity = Vector3.new(targetX, curVel.Y, targetZ)
            else
                local smooth = 0.7
                hrp.AssemblyLinearVelocity = Vector3.new(
                    curVel.X + diffX * smooth,
                    curVel.Y,
                    curVel.Z + diffZ * smooth
                )
            end
        else
            local curVel = hrp.AssemblyLinearVelocity
            if math.abs(curVel.X) > 1 or math.abs(curVel.Z) > 1 then
                hrp.AssemblyLinearVelocity = Vector3.new(curVel.X * 0.7, curVel.Y, curVel.Z * 0.7)
            end
        end
    end)
    if Hum then Hum.UseJumpPower = true; Hum.JumpPower = 45 end
    Notify("SPEED BOOST ON")
end

local function stopSpeedBoost()
    if not isSpeedBoostEnabled then return end
    isSpeedBoostEnabled = false
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
    end
    Notify("SPEED BOOST OFF")
end

-- FLOAT
local FloatConn = nil
local FLOAT_TARGET_HEIGHT = 10

local function startFloat()
    if State.FloatEnabled then return end
    pcall(function()
        if State.AutoBat then
            _switchingModes = true
            StopAutoBat()
            _switchingModes = false
        end
    end)
    local char = LP.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local floatOriginY = hrp.Position.Y + FLOAT_TARGET_HEIGHT
    State.FloatEnabled = true
    if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
    FloatConn = RunService.Heartbeat:Connect(function()
        if not State.FloatEnabled then return end
        local c2 = LP.Character if not c2 then return end
        local h = c2:FindFirstChild("HumanoidRootPart") if not h then return end
        local hum2 = c2:FindFirstChildOfClass("Humanoid")
        local moveDir = hum2 and hum2.MoveDirection or Vector3.zero
        local diff = floatOriginY - h.Position.Y
        local vertVel
        if diff > 0.3 then vertVel = math.clamp(diff * 8, 5, 50)
        elseif diff < -0.3 then vertVel = math.clamp(diff * 8, -50, -5)
        else vertVel = 0 end
        h.AssemblyLinearVelocity = Vector3.new(h.AssemblyLinearVelocity.X, vertVel, h.AssemblyLinearVelocity.Z)
    end)
    Notify("FLOAT ON")
end

local function stopFloat()
    if not State.FloatEnabled then return end
    State.FloatEnabled = false
    if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
    end
    Notify("FLOAT OFF")
end

-- AUTO GRAB
local EnhancedGrab = { Enabled = false, Radius = 8, LoopConnection = nil }
local grabBarRef = {}
local sbFill = nil
local stealBarFrame = nil
local _grabStealCache = {}
local _grabIsStealing = false

local function _isMyPlot(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if not sign then return false end
    local yb = sign:FindFirstChild("YourBase")
    if yb and yb:IsA("BillboardGui") then return yb.Enabled end
    return false
end

local function _findNearestPodiumPrompt()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local bestPrompt, bestDist, bestName = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if not _isMyPlot(plot.Name) then
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, pod in ipairs(podiums:GetChildren()) do
                    pcall(function()
                        local base = pod:FindFirstChild("Base")
                        local spawnPart = base and base:FindFirstChild("Spawn")
                        if spawnPart then
                            local dist = (spawnPart.Position - hrp.Position).Magnitude
                            if dist < bestDist and dist <= EnhancedGrab.Radius then
                                for _, child in ipairs(spawnPart:GetDescendants()) do
                                    if child:IsA("ProximityPrompt") and child.Enabled then
                                        bestPrompt = child
                                        bestDist = dist
                                        bestName = pod.Name
                                        break
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end
    return bestPrompt, bestName
end

local function _buildGrabCallbacks(prompt)
    if _grabStealCache[prompt] then return end
    local data = { holdCBs = {}, triggerCBs = {}, ready = true }
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function) == "function" then table.insert(data.holdCBs, conn.Function) end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function) == "function" then table.insert(data.triggerCBs, conn.Function) end
        end
    end
    if #data.holdCBs > 0 or #data.triggerCBs > 0 then _grabStealCache[prompt] = data end
end

local function _execGrabSteal(prompt, name)
    local data = _grabStealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    _grabIsStealing = true
    if grabBarRef.fill then grabBarRef.fill.Size = UDim2.new(1, 0, 1, 0) end
    if grabBarRef.pct then grabBarRef.pct.Text = "100%" end
    task.spawn(function()
        for _, fn in ipairs(data.holdCBs) do task.spawn(fn) end
        task.wait(0.2)
        for _, fn in ipairs(data.triggerCBs) do task.spawn(fn) end
        task.wait(0.05)
        data.ready = true
        _grabIsStealing = false
        _grabStealCache[prompt] = nil
        if grabBarRef.fill then grabBarRef.fill.Size = UDim2.new(0, 0, 1, 0) end
        if grabBarRef.pct then grabBarRef.pct.Text = "0%" end
    end)
    return true
end

local function UpdateEnhancedGrabBar(percent)
    if grabBarRef and grabBarRef.fill then
        grabBarRef.fill.Size = UDim2.new(math.clamp(percent/100,0,1),0,1,0)
    end
    if grabBarRef and grabBarRef.pct then
        grabBarRef.pct.Text = math.floor(percent).."%"
    end
    if grabBarRef and grabBarRef.radiusLbl then
        grabBarRef.radiusLbl.Text = EnhancedGrab.Radius.."st"
    end
    if grabBarRef and grabBarRef.rateLbl then
        grabBarRef.rateLbl.Text = "instant"
    end
end

local function StartEnhancedGrab()
    if EnhancedGrab.Enabled then return end
    EnhancedGrab.Enabled = true
    _grabStealCache = {}
    _grabIsStealing = false
    if EnhancedGrab.LoopConnection then EnhancedGrab.LoopConnection:Disconnect() end
    EnhancedGrab.LoopConnection = RunService.Heartbeat:Connect(function()
        if not EnhancedGrab.Enabled or _grabIsStealing then return end
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local s = hum:GetState()
            if s == Enum.HumanoidStateType.Ragdoll
            or s == Enum.HumanoidStateType.FallingDown
            or s == Enum.HumanoidStateType.Physics then return end
        end
        local prompt, animalName = _findNearestPodiumPrompt()
        if prompt then
            _buildGrabCallbacks(prompt)
            _execGrabSteal(prompt, animalName)
        else
            UpdateEnhancedGrabBar(0)
        end
    end)
    UpdateEnhancedGrabBar(0)
    Notify("AUTO GRAB ON | Range: "..EnhancedGrab.Radius)
end

local function StopEnhancedGrab()
    if not EnhancedGrab.Enabled then return end
    EnhancedGrab.Enabled = false
    _grabIsStealing = false
    _grabStealCache = {}
    UpdateEnhancedGrabBar(0)
    if EnhancedGrab.LoopConnection then
        EnhancedGrab.LoopConnection:Disconnect()
        EnhancedGrab.LoopConnection = nil
    end
    Notify("AUTO GRAB OFF")
end

-- DROP
local DropState = { active = false, lastTime = 0, COOLDOWN = 2.5 }
local _dropBlockAutoPlay = false
local _wfConns = {}
local _wfActive = false

local function startWalkFling()
    _wfActive = true
    table.insert(_wfConns, RunService.Stepped:Connect(function()
        if not _wfActive then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                for _, part in ipairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end))
    local co = coroutine.create(function()
        while _wfActive do
            RunService.Heartbeat:Wait()
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local vel = root.Velocity
                root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                if root and root.Parent then root.Velocity = vel end
                RunService.Stepped:Wait()
                if root and root.Parent then root.Velocity = vel + Vector3.new(0, 0.1, 0) end
            else
                RunService.Heartbeat:Wait()
            end
        end
    end)
    coroutine.resume(co)
    table.insert(_wfConns, co)
end

local function stopWalkFling()
    _wfActive = false
    for _, c in ipairs(_wfConns) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect()
        elseif typeof(c) == "thread" then pcall(task.cancel, c) end
    end
    _wfConns = {}
end

local function executeDrop()
    local now = tick()
    if now - DropState.lastTime < DropState.COOLDOWN then
        Notify("DROP cooldown: "..string.format("%.1f", DropState.COOLDOWN - (now - DropState.lastTime)).."s")
        return
    end
    if DropState.active then Notify("DROP busy...") return end
    DropState.lastTime = now
    DropState.active = true
    _dropBlockAutoPlay = true
    task.spawn(function()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local savedHealth
        if hum then
            savedHealth = hum.Health
            pcall(function() hum.Health = hum.MaxHealth end)
        end
        startWalkFling()
        task.wait(0.4)
        stopWalkFling()
        if hum and hum.Parent then
            pcall(function()
                if hum.Health < savedHealth then
                    hum.Health = math.max(savedHealth * 0.5, 1)
                end
            end)
        end
        DropState.active = false
        task.wait(1.0)
        _dropBlockAutoPlay = false
        Notify("DROP!")
    end)
end

-- ============================================
-- AUTO BAT (AUTO TRACK FROM ZYPHROT)
-- ============================================
local TrackSettings = {
    Enabled = false, TrackSpeed = 59, LockSpeed = 80,
    TrackConn = nil, AlignOri = nil, Attachment = nil,
    AutoBatActive = false, AutoBatLoop = nil,
}

local function getHRPTrack()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumTrack()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function startAutoBatSpam()
    if TrackSettings.AutoBatActive then return end
    TrackSettings.AutoBatActive = true
    TrackSettings.AutoBatLoop = task.spawn(function()
        while TrackSettings.AutoBatActive and TrackSettings.Enabled do
            local char = LP.Character
            if char then
                local bat = char:FindFirstChild("Bat")
                if bat and bat:IsA("Tool") then
                    pcall(function() bat:Activate() end)
                end
            end
            task.wait(0.2)
        end
    end)
end

local function stopAutoBatSpam()
    TrackSettings.AutoBatActive = false
    if TrackSettings.AutoBatLoop then
        task.cancel(TrackSettings.AutoBatLoop)
        TrackSettings.AutoBatLoop = nil
    end
end

local function getClosestEnemy()
    local hrp = getHRPTrack()
    if not hrp then return nil end
    local closest, best = nil, 9999
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local d = (hrp.Position - root.Position).Magnitude
                if d < best then best = d; closest = root end
            end
        end
    end
    return closest
end

local function StartAutoBat()
    local hrp = getHRPTrack()
    local hum = getHumTrack()
    if not hrp then return end

    hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)

    if TrackSettings.Attachment then pcall(function() TrackSettings.Attachment:Destroy() end) end
    if TrackSettings.AlignOri then pcall(function() TrackSettings.AlignOri:Destroy() end) end

    TrackSettings.Attachment = Instance.new("Attachment")
    TrackSettings.Attachment.Parent = hrp

    TrackSettings.AlignOri = Instance.new("AlignOrientation")
    TrackSettings.AlignOri.Attachment0 = TrackSettings.Attachment
    TrackSettings.AlignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
    TrackSettings.AlignOri.RigidityEnabled = true
    TrackSettings.AlignOri.MaxTorque = 1000000
    TrackSettings.AlignOri.Responsiveness = 200
    TrackSettings.AlignOri.Enabled = false
    TrackSettings.AlignOri.Parent = hrp

    if hum then hum.AutoRotate = false end

    if TrackSettings.TrackConn then TrackSettings.TrackConn:Disconnect() end

    TrackSettings.TrackConn = RunService.Heartbeat:Connect(function()
        if not TrackSettings.Enabled then return end

        local h = getHRPTrack()
        local hm = getHumTrack()
        if not h then return end

        local target = getClosestEnemy()
        if not target then
            h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0)
            if TrackSettings.AlignOri then TrackSettings.AlignOri.Enabled = false end
            if hm then hm.AutoRotate = true end
            stopAutoBatSpam()
            return
        end

        if not TrackSettings.AutoBatActive then startAutoBatSpam() end

        local dX = target.Position.X - h.Position.X
        local dZ = target.Position.Z - h.Position.Z
        local dY = target.Position.Y - h.Position.Y
        local flatDist = math.sqrt(dX*dX + dZ*dZ)
        local yVel = math.clamp(dY * 12, -35, 35)

        local tv = target.AssemblyLinearVelocity
        local velX, velZ
        if flatDist > 1.5 then
            local predX = dX + tv.X * 0.1
            local predZ = dZ + tv.Z * 0.1
            local predDist = math.sqrt(predX*predX + predZ*predZ)
            if predDist > 0.1 then
                velX = (predX / predDist) * TrackSettings.TrackSpeed
                velZ = (predZ / predDist) * TrackSettings.TrackSpeed
            else
                velX = (dX / flatDist) * TrackSettings.TrackSpeed
                velZ = (dZ / flatDist) * TrackSettings.TrackSpeed
            end
        else
            velX = tv.X + dX * 20
            velZ = tv.Z + dZ * 20
            local mag = math.sqrt(velX*velX + velZ*velZ)
            if mag > TrackSettings.LockSpeed then
                velX = velX / mag * TrackSettings.LockSpeed
                velZ = velZ / mag * TrackSettings.LockSpeed
            end
        end

        local curVel = h.AssemblyLinearVelocity
        local smooth = 0.4
        h.AssemblyLinearVelocity = Vector3.new(
            curVel.X + (velX - curVel.X) * smooth,
            yVel,
            curVel.Z + (velZ - curVel.Z) * smooth
        )

        if TrackSettings.AlignOri then
            local dirMag = math.sqrt(dX*dX + dZ*dZ)
            if dirMag > 0.1 then
                TrackSettings.AlignOri.Enabled = true
                TrackSettings.AlignOri.CFrame = CFrame.lookAt(
                    h.Position,
                    h.Position + Vector3.new(dX/dirMag, 0, dZ/dirMag)
                )
            end
        end
    end)
end

local function StopAutoBat()
    if TrackSettings.TrackConn then
        TrackSettings.TrackConn:Disconnect()
        TrackSettings.TrackConn = nil
    end
    if TrackSettings.AlignOri then
        pcall(function() TrackSettings.AlignOri:Destroy() end)
        TrackSettings.AlignOri = nil
    end
    if TrackSettings.Attachment then
        pcall(function() TrackSettings.Attachment:Destroy() end)
        TrackSettings.Attachment = nil
    end
    stopAutoBatSpam()
    local hrp = getHRPTrack()
    local hm = getHumTrack()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
    end
    if hm then
        hm.AutoRotate = true
    end
end

-- ============================================
-- AUTO TP DOWN
-- ============================================
local TPSettings = {
    Enabled = true, TPHeight = 12.5, LastTPTime = 0, TP_COOLDOWN = 0.15,
    SavedLandingX = nil, SavedLandingZ = nil, WasAboveThreshold = false, MonitorConnection = nil,
}
local tpDownWasOnBeforeAutoBat = false

local function getHRPTP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function TeleportToGround()
    local hrp = getHRPTP()
    if not hrp then return false end
    local now = tick()
    if now - TPSettings.LastTPTime < TPSettings.TP_COOLDOWN then return false end
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LP.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    local result = workspace:Raycast(hrp.Position, Vector3.new(0, -1000, 0), rayParams)
    local targetY
    if result then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        local hipH = (hum and hum.HipHeight) or 2
        targetY = result.Position.Y + hipH + (hrp.Size.Y / 2) + 0.3
    else
        targetY = hrp.Position.Y - 30
    end
    
    local landX = TPSettings.SavedLandingX or hrp.Position.X
    local landZ = TPSettings.SavedLandingZ or hrp.Position.Z
    TPSettings.LastTPTime = now
    
    local flash = Instance.new("Part")
    flash.Shape = Enum.PartType.Ball
    flash.Size = Vector3.new(1,1,1)
    flash.Position = hrp.Position
    flash.Anchored = true
    flash.CanCollide = false
    flash.Material = Enum.Material.Neon
    flash.Color = Color3.fromRGB(130,100,255)
    flash.Transparency = 0.3
    flash.Parent = workspace
    TweenService:Create(flash, TweenInfo.new(0.15), {Size = Vector3.new(2,2,2), Transparency = 1}):Play()
    task.delay(0.2, function() pcall(function() flash:Destroy() end) end)
    
    pcall(function()
        hrp.CFrame = CFrame.new(Vector3.new(landX, targetY, landZ))
    end)
    return true
end

local function StartTPMonitoring()
    if TPSettings.MonitorConnection then return end
    TPSettings.MonitorConnection = RunService.Heartbeat:Connect(function()
        if not TPSettings.Enabled then return end
        local hrp = getHRPTP()
        if not hrp then
            TPSettings.WasAboveThreshold = false
            return
        end
        local currentHeight = hrp.Position.Y
        local isAbove = currentHeight >= TPSettings.TPHeight
        if isAbove and not TPSettings.WasAboveThreshold then
            TPSettings.SavedLandingX = hrp.Position.X
            TPSettings.SavedLandingZ = hrp.Position.Z
            TPSettings.WasAboveThreshold = true
        end
        if isAbove then
            TeleportToGround()
        end
        if not isAbove and TPSettings.WasAboveThreshold then
            TPSettings.WasAboveThreshold = false
        end
    end)
end

local function StopTPMonitoring()
    if TPSettings.MonitorConnection then
        TPSettings.MonitorConnection:Disconnect()
        TPSettings.MonitorConnection = nil
    end
    TPSettings.WasAboveThreshold = false
end

-- ============================================
-- AUTO PLAY LEFT/RIGHT
-- ============================================
local AP_L1     = Vector3.new(-476,    -7,      93)
local AP_LEND   = Vector3.new(-484,    -5,      96)
local AP_LFINAL = Vector3.new(-475,    -7,      16)
local AP_R1     = Vector3.new(-476,    -7,      27)
local AP_REND   = Vector3.new(-484,    -5,      24)
local AP_RFINAL = Vector3.new(-476,    -7,      105)

local AP_FSPD = 60.36
local AP_RSPD = 30.46
local AP_ESPD = 30.46

local WP_PARTS = {}
local WP_META = { BLUE = Color3.fromRGB(0,150,255) }

local function createWPPart(name, pos, color)
    local old = workspace:FindFirstChild("H2N_WP_"..name)
    if old then old:Destroy() end
    local part = Instance.new("Part")
    part.Name = "H2N_WP_"..name
    part.Size = Vector3.new(0.8,0.8,0.8)
    part.Shape = Enum.PartType.Ball
    part.Position = pos
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.15
    local light = Instance.new("PointLight", part)
    light.Color = color
    light.Range = 3
    light.Brightness = 1
    local bg = Instance.new("BillboardGui", part)
    bg.Size = UDim2.new(0,50,0,20)
    bg.StudsOffset = Vector3.new(0,1.2,0)
    bg.AlwaysOnTop = true
    bg.LightInfluence = 0
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundColor3 = Colors.AlmostBlack
    lbl.BackgroundTransparency = 0.4
    lbl.Text = name
    lbl.TextColor3 = Colors.DiscordBlue
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,6)
    part.Parent = workspace
    WP_PARTS[name] = part
end

local function initWPParts()
    createWPPart("L1",    AP_L1,     WP_META.BLUE)
    createWPPart("LEND",  AP_LEND,   WP_META.BLUE)
    createWPPart("LFIN",  AP_LFINAL, WP_META.BLUE)
    createWPPart("R1",    AP_R1,     WP_META.BLUE)
    createWPPart("REND",  AP_REND,   WP_META.BLUE)
    createWPPart("RFIN",  AP_RFINAL, WP_META.BLUE)
end

local aplConn, aprConn = nil, nil
local aplPhase, aprPhase = 1, 1
local _switchingModes = false

local function getHRP2()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum2()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function apMoveToward(h, hum, targetPos, speed)
    local d = Vector3.new(targetPos.X - h.Position.X, 0, targetPos.Z - h.Position.Z)
    if d.Magnitude < 1 then return true end
    local md = d.Unit
    if hum then hum:Move(md, false) end
    h.AssemblyLinearVelocity = Vector3.new(md.X * speed, h.AssemblyLinearVelocity.Y, md.Z * speed)
    return false
end

-- دوال AUTO PLAY LEFT
local function StopAutoPlayLeft()
    if not State.AutoPlayLeft then return end
    State.AutoPlayLeft = false
    if aplConn then aplConn:Disconnect(); aplConn = nil end
    aplPhase = 1
    local h = getHRP2()
    local hum = getHum2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if hum then hum:Move(Vector3.zero, false); hum.AutoRotate = true end
    if Hum then Hum.AutoRotate = true end
    if speedBoostWasOnBeforeAutoPlay then
        speedBoostWasOnBeforeAutoPlay = false
        startSpeedBoost()
    end
    Notify("AUTO PLAY LEFT OFF")
    -- تحديث الزر الجانبي (إخفاؤه عند إيقاف الخاصية من المينيو)
    if sideButtonRefs and sideButtonRefs.AutoPlayLeft then
        sideButtonRefs.AutoPlayLeft(false)
    end
end

local function StartAutoPlayLeft()
    if State.AutoPlayLeft then return end
    if _dropBlockAutoPlay then Notify("AutoPlay blocked — DROP cooldown active"); return end
    if TrackSettings.Enabled then
        if sideButtonRefs and sideButtonRefs.AutoBat then sideButtonRefs.AutoBat(false) end
        StopAutoBat()
    end
    if State.AutoPlayRight then StopAutoPlayRight() end
    if State.FloatEnabled then stopFloat() end

    speedBoostWasOnBeforeAutoPlay = isSpeedBoostEnabled
    if isSpeedBoostEnabled then
        stopSpeedBoost()
    end

    State.AutoPlayLeft = true
    aplPhase = 1
    if Hum then Hum.AutoRotate = false end
    if aplConn then aplConn:Disconnect() end
    aplConn = RunService.Heartbeat:Connect(updateAutoPlayLeft)
    Notify("AUTO PLAY LEFT ON")
    -- تحديث الزر الجانبي (إظهاره عند تفعيل الخاصية)
    if sideButtonRefs and sideButtonRefs.AutoPlayLeft then
        sideButtonRefs.AutoPlayLeft(true)
    end
end

local function updateAutoPlayLeft()
    if not State.AutoPlayLeft then
        if aplConn then aplConn:Disconnect(); aplConn = nil end
        return
    end
    local h, hum = getHRP2(), getHum2()
    if not h then return end
    if aplPhase == 1 then
        if apMoveToward(h, hum, AP_L1, AP_FSPD) then aplPhase = 2 end
    elseif aplPhase == 2 then
        if apMoveToward(h, hum, AP_LEND, AP_FSPD) then aplPhase = 3 end
    elseif aplPhase == 3 then
        if apMoveToward(h, hum, AP_L1, AP_ESPD) then aplPhase = 4 end
    elseif aplPhase == 4 then
        if apMoveToward(h, hum, AP_LFINAL, AP_RSPD) then
            StopAutoPlayLeft()
        end
    end
end

-- دوال AUTO PLAY RIGHT
local function StopAutoPlayRight()
    if not State.AutoPlayRight then return end
    State.AutoPlayRight = false
    if aprConn then aprConn:Disconnect(); aprConn = nil end
    aprPhase = 1
    local h = getHRP2()
    local hum = getHum2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if hum then hum:Move(Vector3.zero, false); hum.AutoRotate = true end
    if Hum then Hum.AutoRotate = true end
    if speedBoostWasOnBeforeAutoPlay then
        speedBoostWasOnBeforeAutoPlay = false
        startSpeedBoost()
    end
    Notify("AUTO PLAY RIGHT OFF")
    if sideButtonRefs and sideButtonRefs.AutoPlayRight then
        sideButtonRefs.AutoPlayRight(false)
    end
end

local function StartAutoPlayRight()
    if State.AutoPlayRight then return end
    if _dropBlockAutoPlay then Notify("AutoPlay blocked — DROP cooldown active"); return end
    if TrackSettings.Enabled then
        if sideButtonRefs and sideButtonRefs.AutoBat then sideButtonRefs.AutoBat(false) end
        StopAutoBat()
    end
    if State.AutoPlayLeft then StopAutoPlayLeft() end
    if State.FloatEnabled then stopFloat() end

    speedBoostWasOnBeforeAutoPlay = isSpeedBoostEnabled
    if isSpeedBoostEnabled then
        stopSpeedBoost()
    end

    State.AutoPlayRight = true
    aprPhase = 1
    if Hum then Hum.AutoRotate = false end
    if aprConn then aprConn:Disconnect() end
    aprConn = RunService.Heartbeat:Connect(updateAutoPlayRight)
    Notify("AUTO PLAY RIGHT ON")
    if sideButtonRefs and sideButtonRefs.AutoPlayRight then
        sideButtonRefs.AutoPlayRight(true)
    end
end

local function updateAutoPlayRight()
    if not State.AutoPlayRight then
        if aprConn then aprConn:Disconnect(); aprConn = nil end
        return
    end
    local h, hum = getHRP2(), getHum2()
    if not h then return end
    if aprPhase == 1 then
        if apMoveToward(h, hum, AP_R1, AP_FSPD) then aprPhase = 2 end
    elseif aprPhase == 2 then
        if apMoveToward(h, hum, AP_REND, AP_FSPD) then aprPhase = 3 end
    elseif aprPhase == 3 then
        if apMoveToward(h, hum, AP_R1, AP_ESPD) then aprPhase = 4 end
    elseif aprPhase == 4 then
        if apMoveToward(h, hum, AP_RFINAL, AP_RSPD) then
            StopAutoPlayRight()
        end
    end
end

-- دوال AUTO BAT
local function StopAutoBat()
    if not TrackSettings.Enabled then return end
    TrackSettings.Enabled = false
    StopAutoBat()
    if speedBoostWasOnBeforeAutoBat then
        speedBoostWasOnBeforeAutoBat = false
        startSpeedBoost()
    end
    if tpDownWasOnBeforeAutoBat then
        tpDownWasOnBeforeAutoBat = false
        TPSettings.Enabled = true
        StartTPMonitoring()
    end
    Notify("AUTO BAT OFF")
    if sideButtonRefs and sideButtonRefs.AutoBat then
        sideButtonRefs.AutoBat(false)
    end
end

local function StartAutoBat()
    if TrackSettings.Enabled then return end
    if State.AutoPlayLeft or State.AutoPlayRight then
        if sideButtonRefs and sideButtonRefs.AutoPlayLeft then sideButtonRefs.AutoPlayLeft(false) end
        if sideButtonRefs and sideButtonRefs.AutoPlayRight then sideButtonRefs.AutoPlayRight(false) end
        if State.AutoPlayLeft then StopAutoPlayLeft() end
        if State.AutoPlayRight then StopAutoPlayRight() end
    end
    if State.FloatEnabled then stopFloat() end

    speedBoostWasOnBeforeAutoBat = isSpeedBoostEnabled
    if isSpeedBoostEnabled then stopSpeedBoost() end

    if TPSettings.Enabled then
        TPSettings.Enabled = false
        StopTPMonitoring()
    end

    TrackSettings.Enabled = true
    task.spawn(function()
        local hrp = getHRPTrack()
        if not hrp then
            while TrackSettings.Enabled and not getHRPTrack() do task.wait(0.1) end
        end
        if TrackSettings.Enabled then StartAutoBat() end
    end)
    Notify("AUTO BAT ON")
    if sideButtonRefs and sideButtonRefs.AutoBat then
        sideButtonRefs.AutoBat(true)
    end
end

-- دوال SPEED BOOST
local function ToggleSpeedBoost()
    if isSpeedBoostEnabled then
        stopSpeedBoost()
        if sideButtonRefs and sideButtonRefs.SpeedBoost then
            sideButtonRefs.SpeedBoost(false)
        end
    else
        startSpeedBoost()
        if sideButtonRefs and sideButtonRefs.SpeedBoost then
            sideButtonRefs.SpeedBoost(true)
        end
    end
end

-- دوال FLOAT
local function ToggleFloat()
    if State.FloatEnabled then
        stopFloat()
        if sideButtonRefs and sideButtonRefs.FloatEnabled then
            sideButtonRefs.FloatEnabled(false)
        end
    else
        if TrackSettings.Enabled then
            if sideButtonRefs and sideButtonRefs.AutoBat then sideButtonRefs.AutoBat(false) end
            StopAutoBat()
        end
        if State.AutoPlayLeft then StopAutoPlayLeft() end
        if State.AutoPlayRight then StopAutoPlayRight() end
        startFloat()
        if sideButtonRefs and sideButtonRefs.FloatEnabled then
            sideButtonRefs.FloatEnabled(true)
        end
    end
end

-- دوال AUTO TP DOWN
local function ToggleAutoTPDown()
    if TPSettings.Enabled then
        TPSettings.Enabled = false
        StopTPMonitoring()
        Notify("AUTO TP DOWN OFF")
        if sideButtonRefs and sideButtonRefs.AutoTPDown then
            sideButtonRefs.AutoTPDown(false)
        end
    else
        if TrackSettings.Enabled then
            Notify("Cannot enable AUTO TP DOWN while AUTO BAT is active")
            return
        end
        TPSettings.Enabled = true
        StartTPMonitoring()
        Notify("AUTO TP DOWN ON")
        if sideButtonRefs and sideButtonRefs.AutoTPDown then
            sideButtonRefs.AutoTPDown(true)
        end
    end
end

-- ============================================
-- HIT CIRCLE
-- ============================================
local HitCircleState = { Enabled = false }
local _hitCircleData = { Conn = nil, Circle = nil, Align = nil, Attach = nil }

local function StartHitCircle()
    if HitCircleState.Enabled then return end
    HitCircleState.Enabled = true
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    if _hitCircleData.Attach then pcall(function() _hitCircleData.Attach:Destroy() end) end
    if _hitCircleData.Align then pcall(function() _hitCircleData.Align:Destroy() end) end
    if _hitCircleData.Circle then pcall(function() _hitCircleData.Circle:Destroy() end) end
    _hitCircleData.Attach = Instance.new("Attachment", hrp)
    _hitCircleData.Align = Instance.new("AlignOrientation", hrp)
    _hitCircleData.Align.Attachment0 = _hitCircleData.Attach
    _hitCircleData.Align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    _hitCircleData.Align.RigidityEnabled = true
    local circle = Instance.new("Part")
    circle.Shape = Enum.PartType.Cylinder
    circle.Material = Enum.Material.Neon
    circle.Size = Vector3.new(0.05, 14.5, 14.5)
    circle.Color = Color3.fromRGB(130, 100, 255)
    circle.CanCollide = false
    circle.Massless = true
    circle.Parent = workspace
    local weld = Instance.new("Weld")
    weld.Part0 = hrp; weld.Part1 = circle
    weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(90))
    weld.Parent = circle
    _hitCircleData.Circle = circle
    if _hitCircleData.Conn then _hitCircleData.Conn:Disconnect() end
    _hitCircleData.Conn = RunService.RenderStepped:Connect(function()
        if not HitCircleState.Enabled then return end
        local c = LP.Character if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart") if not h then return end
        local target, dmin = nil, 7.25
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - h.Position).Magnitude
                if d <= dmin then target = p.Character.HumanoidRootPart; dmin = d end
            end
        end
        if target then
            c.Humanoid.AutoRotate = false
            _hitCircleData.Align.Enabled = true
            _hitCircleData.Align.CFrame = CFrame.lookAt(h.Position, Vector3.new(target.Position.X, h.Position.Y, target.Position.Z))
            local bat = c:FindFirstChild("Bat") or c:FindFirstChild("Medusa")
            if bat then pcall(function() bat:Activate() end) end
        else
            _hitCircleData.Align.Enabled = false
            if c.Humanoid then c.Humanoid.AutoRotate = true end
        end
    end)
    Notify("HIT CIRCLE ON")
end

local function StopHitCircle()
    if not HitCircleState.Enabled then return end
    HitCircleState.Enabled = false
    if _hitCircleData.Conn then _hitCircleData.Conn:Disconnect(); _hitCircleData.Conn = nil end
    if _hitCircleData.Circle then pcall(function() _hitCircleData.Circle:Destroy() end); _hitCircleData.Circle = nil end
    if _hitCircleData.Align then pcall(function() _hitCircleData.Align:Destroy() end); _hitCircleData.Align = nil end
    if _hitCircleData.Attach then pcall(function() _hitCircleData.Attach:Destroy() end); _hitCircleData.Attach = nil end
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid.AutoRotate = true end
    Notify("HIT CIRCLE OFF")
end

function ToggleHitCircle()
    if HitCircleState.Enabled then
        StopHitCircle()
    else
        StartHitCircle()
    end
end

-- ============================================
-- SPAM BAT
-- ============================================
local SpamBatState = { conn = nil, lastSwing = 0, COOLDOWN = 0.12, enabled = false }

local function _findBatForSpam()
    local c = LP.Character if not c then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    for _, ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _, ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    local slapList = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
    for _, name in ipairs(slapList) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    return nil
end

local function StartSpamBat()
    if SpamBatState.enabled then return end
    SpamBatState.enabled = true
    if SpamBatState.conn then SpamBatState.conn:Disconnect() end
    SpamBatState.conn = RunService.Heartbeat:Connect(function()
        if not SpamBatState.enabled then return end
        local c = LP.Character if not c then return end
        local bat = _findBatForSpam() if not bat then return end
        if bat.Parent ~= c then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:EquipTool(bat) end) end
        end
        local now = tick()
        if now - SpamBatState.lastSwing < SpamBatState.COOLDOWN then return end
        SpamBatState.lastSwing = now
        pcall(function() bat:Activate() end)
    end)
    Notify("SPAM BAT ON")
end

local function StopSpamBat()
    if not SpamBatState.enabled then return end
    SpamBatState.enabled = false
    if SpamBatState.conn then SpamBatState.conn:Disconnect(); SpamBatState.conn = nil end
    Notify("SPAM BAT OFF")
end

function ToggleSpamBat()
    if SpamBatState.enabled then
        StopSpamBat()
    else
        StartSpamBat()
    end
end

-- ============================================
-- OPTIMIZER
-- ============================================
local function startOptimizer()
    if State.Optimizer then return end
    State.Optimizer = true
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").Brightness = 3
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                end
            end)
        end
    end)
    Notify("OPTIMIZER ON")
end

local function stopOptimizer()
    if not State.Optimizer then return end
    State.Optimizer = false
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level08
        game:GetService("Lighting").GlobalShadows = true
        game:GetService("Lighting").Brightness = 2
    end)
    Notify("OPTIMIZER OFF")
end

function ToggleOptimizer()
    if State.Optimizer then
        stopOptimizer()
    else
        startOptimizer()
    end
end

-- ============================================
-- XRAY BASE
-- ============================================
local baseOT = {}; local plotConns = {}; local xrayCon = nil
local XRAY_TRANSPARENCY = 0.68

local function applyXray(plot)
    if baseOT[plot] then return end; baseOT[plot] = {}
    for _, p in ipairs(plot:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 0.6 then baseOT[plot][p] = p.Transparency; p.Transparency = XRAY_TRANSPARENCY end
    end
    plotConns[plot] = plot.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and d.Transparency < 0.6 then baseOT[plot][d] = d.Transparency; d.Transparency = XRAY_TRANSPARENCY end
    end)
end

local function StartXrayBase()
    if State.XrayBase then return end
    State.XrayBase = true
    local plots = workspace:FindFirstChild("Plots"); if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do applyXray(plot) end
    xrayCon = plots.ChildAdded:Connect(function(p) task.wait(0.2); applyXray(p) end)
    Notify("XRAY BASE ON")
end

local function StopXrayBase()
    if not State.XrayBase then return end
    State.XrayBase = false
    for _, conn in pairs(plotConns) do conn:Disconnect() end; plotConns = {}
    if xrayCon then xrayCon:Disconnect(); xrayCon = nil end
    for _, parts in pairs(baseOT) do
        for part, orig in pairs(parts) do if part and part.Parent then part.Transparency = orig end end
    end
    baseOT = {}
    Notify("XRAY BASE OFF")
end

function ToggleXrayBase()
    if State.XrayBase then
        StopXrayBase()
    else
        StartXrayBase()
    end
end

-- ============================================
-- ESP
-- ============================================
local ESPState = { hl = {} }
local function ClearESP() for _, h in pairs(ESPState.hl) do if h and h.Parent then h:Destroy() end end; ESPState.hl = {} end
local function StartESP()
    if State.ESP then return end
    State.ESP = true; Notify("ESP ON")
end
local function StopESP()
    if not State.ESP then return end
    State.ESP = false; ClearESP(); Notify("ESP OFF")
end
local function updateESP()
    if not State.ESP then return end
    for player, h in pairs(ESPState.hl) do
        if not player or not player.Character then if h and h.Parent then h:Destroy() end; ESPState.hl[player] = nil end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and (not ESPState.hl[p] or not ESPState.hl[p].Parent) then
            local h = Instance.new("Highlight")
            h.FillColor = Colors.DarkGray; h.OutlineColor = Colors.White
            h.FillTransparency = 0.5; h.OutlineTransparency = 0; h.Adornee = p.Character; h.Parent = p.Character
            ESPState.hl[p] = h
        end
    end
end

function ToggleESP()
    if State.ESP then
        StopESP()
    else
        StartESP()
    end
end

-- ============================================
-- ANTI SENTRY
-- ============================================
local SentryState = { target = nil, DETECT_DIST = 60, PULL_DIST = -5 }
local function findSentryTarget()
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPos = char.HumanoidRootPart.Position
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:find("Sentry") and not obj.Name:lower():find("bullet") then
            local part = (obj:IsA("BasePart") and obj) or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
            if part and (rootPos - part.Position).Magnitude <= SentryState.DETECT_DIST then return obj end
        end
    end
end
local function moveSentry(obj)
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, p in pairs(obj:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
    local root = char.HumanoidRootPart; local cf = root.CFrame * CFrame.new(0,0,SentryState.PULL_DIST)
    if obj:IsA("BasePart") then obj.CFrame = cf
    elseif obj:IsA("Model") then local m = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); if m then m.CFrame = cf end end
end
local function getWeapon() return LP.Backpack:FindFirstChild("Bat") or (LP.Character and LP.Character:FindFirstChild("Bat")) end
local function attackSentry()
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local weapon = getWeapon(); if not weapon then return end
    if weapon.Parent == LP.Backpack then hum:EquipTool(weapon); task.wait(0.1) end
    pcall(function() weapon:Activate() end)
    for _, r in pairs(weapon:GetDescendants()) do if r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end end
end
local function StartAntiSentry() if State.AntiSentry then return end; State.AntiSentry = true; Notify("ANTI SENTRY ON") end
local function StopAntiSentry() if not State.AntiSentry then return end; State.AntiSentry = false; SentryState.target = nil; Notify("ANTI SENTRY OFF") end
local function updateAntiSentry() if not State.AntiSentry then return end; if SentryState.target and SentryState.target.Parent == workspace then moveSentry(SentryState.target); attackSentry() else SentryState.target = findSentryTarget() end end

function ToggleAntiSentry()
    if State.AntiSentry then
        StopAntiSentry()
    else
        StartAntiSentry()
    end
end

-- ============================================
-- SPIN BODY
-- ============================================
local SpinState = { force = nil, SPEED = 25 }
local function StartSpinBody()
    if State.SpinBody then return end
    State.SpinBody = true
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root or SpinState.force then return end
    SpinState.force = Instance.new("BodyAngularVelocity")
    SpinState.force.Name = "SpinForce"; SpinState.force.AngularVelocity = Vector3.new(0,SpinState.SPEED,0)
    SpinState.force.MaxTorque = Vector3.new(0,math.huge,0); SpinState.force.P = 1250; SpinState.force.Parent = root
    Notify("SPIN BODY ON")
end
local function StopSpinBody()
    if not State.SpinBody then return end
    State.SpinBody = false; if SpinState.force then SpinState.force:Destroy(); SpinState.force = nil end
    Notify("SPIN BODY OFF")
end

function ToggleSpinBody()
    if State.SpinBody then
        StopSpinBody()
    else
        StartSpinBody()
    end
end

-- ============================================
-- ANTI RAGDOLL
-- ============================================
local ARState = { conn = nil, recoveryActive = false, recoveryTimer = nil }

local function forceRecoverFromRagdoll(hum, root)
    if not hum or not root then return end
    if ARState.recoveryTimer then task.cancel(ARState.recoveryTimer) end
    ARState.recoveryActive = true
    local char = hum.Parent
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
        end
    end
    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)
    if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = hum end
    pcall(function()
        local PlayerModule = LP.PlayerScripts:FindFirstChild("PlayerModule")
        if PlayerModule then
            local Controls = require(PlayerModule:FindFirstChild("ControlModule"))
            Controls:Enable()
        end
    end)
    ARState.recoveryTimer = task.delay(0.3, function() ARState.recoveryActive = false end)
end

local function StartAntiRagdoll()
    if State.AntiRagdoll then return end
    State.AntiRagdoll = true
    if ARState.conn then ARState.conn:Disconnect() end
    ARState.conn = RunService.Heartbeat:Connect(function()
        if not State.AntiRagdoll then return end
        local char = LP.Character if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum.Health <= 0 then return end
        if ARState.recoveryActive then return end
        local state = hum:GetState()
        local isRagdolled = (state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.GettingUp or state == Enum.HumanoidStateType.Stunned)
        local hasBrokenJoints = false
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then hasBrokenJoints = true; break end
        end
        local angularVel = root.AssemblyAngularVelocity
        local isSpinning = math.abs(angularVel.Y) > 15
        if isRagdolled or hasBrokenJoints or isSpinning then forceRecoverFromRagdoll(hum, root) end
    end)
    Notify("ANTI RAGDOLL ON")
end

local function StopAntiRagdoll()
    if not State.AntiRagdoll then return end
    State.AntiRagdoll = false
    if ARState.conn then ARState.conn:Disconnect(); ARState.conn = nil end
    ARState.recoveryActive = false
    if ARState.recoveryTimer then task.cancel(ARState.recoveryTimer) end
    Notify("ANTI RAGDOLL OFF")
end

function ToggleAntiRagdoll()
    if State.AntiRagdoll then
        StopAntiRagdoll()
    else
        StartAntiRagdoll()
    end
end

-- ============================================
-- INFINITE JUMP
-- ============================================
local JumpState = { conn = nil }
local function StartInfiniteJump()
    if State.InfiniteJump then return end
    State.InfiniteJump = true
    if JumpState.conn then JumpState.conn:Disconnect(); JumpState.conn = nil end
    JumpState.conn = UIS.JumpRequest:Connect(function()
        if not State.InfiniteJump or not HRP or not Hum then return end
        if Hum:GetState() == Enum.HumanoidStateType.Dead then return end
        local v = HRP.AssemblyLinearVelocity
        HRP.AssemblyLinearVelocity = Vector3.new(v.X, 50, v.Z)
    end)
    Notify("INFINITE JUMP ON")
end

local function StopInfiniteJump()
    State.InfiniteJump = false
    if JumpState.conn then JumpState.conn:Disconnect(); JumpState.conn = nil end
    Notify("INFINITE JUMP OFF")
end

function ToggleInfiniteJump()
    if State.InfiniteJump then
        StopInfiniteJump()
    else
        StartInfiniteJump()
    end
end

-- ============================================
-- ANTI DIE
-- ============================================
local AntiDieState = { conn = nil }
local function startPermanentAntiDie()
    if AntiDieState.conn then AntiDieState.conn:Disconnect() end
    AntiDieState.conn = RunService.Heartbeat:Connect(function()
        if not Hum or not Hum.Parent then return end
        if Hum.Health <= 0 then pcall(function() Hum.Health = Hum.MaxHealth * 0.9 end) end
        pcall(function() Hum.RequiresNeck = false end)
        if HRP and HRP.Position.Y < -10 then HRP.CFrame = CFrame.new(HRP.Position.X, -4, HRP.Position.Z) end
    end)
end
task.spawn(function() task.wait(0.5); startPermanentAntiDie() end)

-- ============================================
-- UNWALK
-- ============================================
local UnwalkState = { active = false, animConn = nil }

local function stopAnimationsOnly(model)
    if not model then return end
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChild("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop() end
        end
    end
    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("AnimationTrack") then descendant:Stop() end
    end
end

local function startUnwalk()
    if UnwalkState.active then return end
    if UnwalkState.animConn then UnwalkState.animConn:Disconnect() end
    UnwalkState.animConn = RunService.RenderStepped:Connect(function()
        if not UnwalkState.active then return end
        local char = LP.Character
        if char then
            stopAnimationsOnly(char)
            for _, tool in pairs(char:GetChildren()) do if tool:IsA("Tool") then stopAnimationsOnly(tool) end end
        end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then stopAnimationsOnly(player.Character) end
        end
    end)
    UnwalkState.active = true
    Notify("UNWALK ON")
end

local function stopUnwalk()
    if not UnwalkState.active then return end
    if UnwalkState.animConn then UnwalkState.animConn:Disconnect(); UnwalkState.animConn = nil end
    UnwalkState.active = false
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local animateScript = player.Character:FindFirstChild("Animate")
            if animateScript and animateScript:IsA("LocalScript") then
                animateScript.Disabled = true
                task.wait(0.1)
                animateScript.Disabled = false
            end
        end
    end
    Notify("UNWALK OFF")
end

function ToggleUnwalk()
    if UnwalkState.active then
        stopUnwalk()
    else
        startUnwalk()
    end
end

-- ============================================
-- DAMAGE TRACKING
-- ============================================
local DmgState = { conn = nil, cooldown = false, lastHealth = nil, cooldownTimer = nil, COOLDOWN = 2.8 }

local function stopFeaturesOnDamage()
    if DmgState.cooldown then return end
    DmgState.cooldown = true
    _switchingModes = true
    if State.AutoPlayLeft then StopAutoPlayLeft() end
    if State.AutoPlayRight then StopAutoPlayRight() end
    _switchingModes = false
    if State.FloatEnabled then stopFloat() end
    if DmgState.cooldownTimer then pcall(function() task.cancel(DmgState.cooldownTimer) end) end
    DmgState.cooldownTimer = task.delay(DmgState.COOLDOWN, function() DmgState.cooldown = false end)
end

local function setupDamageTracking()
    if DmgState.conn then DmgState.conn:Disconnect(); DmgState.conn = nil end
    local char = LP.Character if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid") if not hum then return end
    DmgState.lastHealth = hum.Health
    DmgState.conn = RunService.Heartbeat:Connect(function()
        if not LP.Character or not hum or hum.Parent ~= LP.Character then
            if DmgState.conn then DmgState.conn:Disconnect(); DmgState.conn = nil end
            return
        end
        local currentHealth = hum.Health
        if DmgState.lastHealth and currentHealth < DmgState.lastHealth - 0.5 and hum.Health > 0 then
            if not DmgState.cooldown then stopFeaturesOnDamage() end
        end
        local currentState = hum:GetState()
        if currentState == Enum.HumanoidStateType.Physics or currentState == Enum.HumanoidStateType.Ragdoll or currentState == Enum.HumanoidStateType.FallingDown then
            if not DmgState.cooldown then stopFeaturesOnDamage() end
        end
        if currentHealth > 0 then DmgState.lastHealth = currentHealth end
    end)
end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    DmgState.cooldown = false
    DmgState.lastHealth = nil
    if DmgState.cooldownTimer then pcall(function() task.cancel(DmgState.cooldownTimer) end) end
    setupDamageTracking()
    if UnwalkState.active then stopAnimationsOnly(char) end
    if HitCircleState.Enabled then HitCircleState.Enabled = false; task.wait(0.5); StartHitCircle() end
end)

-- ============================================
-- KEYBINDS
-- ============================================
local Keys = {
    InfJump = Enum.KeyCode.J, AutoPlayLeft = Enum.KeyCode.G, AutoPlayRight = Enum.KeyCode.H,
    AntiRagdoll = Enum.KeyCode.K, Float = Enum.KeyCode.F, SpeedBoost = Enum.KeyCode.B,
    Unwalk = Enum.KeyCode.U, AutoTPDown = Enum.KeyCode.T,
    AutoBat = Enum.KeyCode.X,
}
local KeyEnabled = {
    InfJump = true, AutoPlayLeft = true, AutoPlayRight = true, AntiRagdoll = true,
    Float = true, SpeedBoost = true, Unwalk = true, AutoTPDown = true,
    AutoBat = true,
}

UIS.InputBegan:Connect(function(input, gpe)
    if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode
    if KeyEnabled.InfJump and k == Keys.InfJump then
        ToggleInfiniteJump()
    elseif KeyEnabled.AutoPlayLeft and k == Keys.AutoPlayLeft then
        if State.AutoPlayLeft then StopAutoPlayLeft() else StartAutoPlayLeft() end
    elseif KeyEnabled.AutoPlayRight and k == Keys.AutoPlayRight then
        if State.AutoPlayRight then StopAutoPlayRight() else StartAutoPlayRight() end
    elseif KeyEnabled.AntiRagdoll and k == Keys.AntiRagdoll then
        ToggleAntiRagdoll()
    elseif KeyEnabled.Float and k == Keys.Float then
        ToggleFloat()
    elseif KeyEnabled.SpeedBoost and k == Keys.SpeedBoost then
        ToggleSpeedBoost()
    elseif KeyEnabled.Unwalk and k == Keys.Unwalk then
        ToggleUnwalk()
    elseif KeyEnabled.AutoTPDown and k == Keys.AutoTPDown then
        ToggleAutoTPDown()
    elseif KeyEnabled.AutoBat and k == Keys.AutoBat then
        if TrackSettings.Enabled then StopAutoBat() else StartAutoBat() end
    end
end)

local discordLink = "discord.gg/UeKPQC7fq"

local function CreateDiscordTag()
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local oldTag = char:FindFirstChild("H2N_DiscordTag")
    if oldTag then oldTag:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "H2N_DiscordTag"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0,260,0,32)
    billboard.StudsOffset = Vector3.new(0,2.5,0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char
    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = Colors.VeryDark
    frame.BackgroundTransparency = 0.15
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Colors.MediumGray
    stroke.Thickness = 1.5
    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1,0,1,0)
    text.BackgroundTransparency = 1
    text.Text = discordLink
    text.TextColor3 = Colors.DiscordBlue
    text.Font = Enum.Font.GothamBold
    text.TextSize = 14
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        setclipboard(discordLink)
        text.Text = "COPIED!"
        text.TextColor3 = Colors.Success
        task.wait(1.2)
        text.Text = discordLink
        text.TextColor3 = Colors.DiscordBlue
        Notify("Discord link copied!")
    end)
end

CreateDiscordTag()
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    CreateDiscordTag()
end)

-- ============================================
-- GUI
-- ============================================
gui = Instance.new("ScreenGui")
gui.Name = "H2N"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = LP:WaitForChild("PlayerGui")

task.spawn(function()
    task.wait(0.1)
    for _, msg in ipairs(_notifyQueue) do
        Notify(msg)
        task.wait(0.3)
    end
    _notifyQueue = {}
end)

local SideButtonSize = 80
local SideButtonShape = "rect"
local menuW, menuH = 350, 350
local StealBarVisible = true
local ButtonPositions = {}
local sideHiddenMap = {}
local menu = nil
local numberBoxReferences = {}
local toggleUpdaters = {}
local sideButtonRefs = {}

local CFG = "H2N_Config.json"

local function Save()
    local menuPos = {X=0.5, XO=0, Y=0.52, YO=0}
    if menu then
        menuPos = {
            X = menu.Position.X.Scale, XO = menu.Position.X.Offset,
            Y = menu.Position.Y.Scale, YO = menu.Position.Y.Offset,
        }
    end
    local stealBarPos = {X=0.5, XO=-170, Y=1, YO=-55}
    if stealBarFrame and stealBarFrame.Parent then
        stealBarPos = {
            X = stealBarFrame.Position.X.Scale, XO = stealBarFrame.Position.X.Offset,
            Y = stealBarFrame.Position.Y.Scale, YO = stealBarFrame.Position.Y.Offset,
        }
    end
    local data = {
        SideButtonSize = SideButtonSize, SideButtonShape = SideButtonShape, menuW = menuW, menuH = menuH,
        menuPos = menuPos, stealBarPos = stealBarPos,
        NormalSpeed = SpeedSettings.NormalSpeed, StealSpeed = SpeedSettings.StealSpeed,
        EnhancedGrab = { Radius = EnhancedGrab.Radius, Enabled = EnhancedGrab.Enabled },
        TrackSettings = { Enabled = TrackSettings.Enabled, TrackSpeed = TrackSettings.TrackSpeed },
        Keys = {
            InfJump = Keys.InfJump.Name, AutoPlayLeft = Keys.AutoPlayLeft.Name,
            AutoPlayRight = Keys.AutoPlayRight.Name, AntiRagdoll = Keys.AntiRagdoll.Name,
            Float = Keys.Float.Name, SpeedBoost = Keys.SpeedBoost.Name,
            Unwalk = Keys.Unwalk.Name, AutoTPDown = Keys.AutoTPDown.Name,
            AutoBat = Keys.AutoBat.Name,
        },
        KeyEnabled = {
            InfJump = KeyEnabled.InfJump, AutoPlayLeft = KeyEnabled.AutoPlayLeft,
            AutoPlayRight = KeyEnabled.AutoPlayRight, AntiRagdoll = KeyEnabled.AntiRagdoll,
            Float = KeyEnabled.Float, SpeedBoost = KeyEnabled.SpeedBoost,
            Unwalk = KeyEnabled.Unwalk, AutoTPDown = KeyEnabled.AutoTPDown,
            AutoBat = KeyEnabled.AutoBat,
        },
        ST_AntiSentry = State.AntiSentry, ST_SpinBody = State.SpinBody,
        ST_AntiRagdoll = State.AntiRagdoll, ST_InfiniteJump = State.InfiniteJump,
        ST_FloatEnabled = State.FloatEnabled, ST_XrayBase = State.XrayBase,
        ST_ESP = State.ESP, ST_SpeedBoost = isSpeedBoostEnabled,
        ST_Optimizer = State.Optimizer,
        ST_Unwalk = UnwalkState.active,
        ST_HitCircle = HitCircleState.Enabled,
        ST_SpamBat = SpamBatState.enabled,
        StealBarVisible = StealBarVisible, sideHiddenMap = sideHiddenMap,
        ButtonPositions = ButtonPositions,
        TPSettings = { Enabled = TPSettings.Enabled, TPHeight = TPSettings.TPHeight },
    }
    SafeWriteFile(CFG, HttpService:JSONEncode(data))
end

local function Load()
    local raw = SafeReadFile(CFG)
    if not raw or raw == "" then return end
    local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(d) ~= "table" then return end
    if d.SideButtonSize then SideButtonSize = d.SideButtonSize end
    if d.SideButtonShape then SideButtonShape = d.SideButtonShape end
    if d.menuW then menuW = d.menuW end
    if d.menuH then menuH = d.menuH end
    if d.NormalSpeed then SpeedSettings.NormalSpeed = d.NormalSpeed end
    if d.StealSpeed then SpeedSettings.StealSpeed = d.StealSpeed end
    if d.EnhancedGrab then
        if d.EnhancedGrab.Radius then EnhancedGrab.Radius = math.clamp(d.EnhancedGrab.Radius, 1, 100) end
        if d.EnhancedGrab.Enabled ~= nil then EnhancedGrab.Enabled = d.EnhancedGrab.Enabled end
    end
    if d.TrackSettings then
        if d.TrackSettings.Enabled ~= nil then TrackSettings.Enabled = d.TrackSettings.Enabled end
        if d.TrackSettings.TrackSpeed then TrackSettings.TrackSpeed = math.clamp(d.TrackSettings.TrackSpeed, 1, 300) end
    end
    if type(d.Keys) == "table" then
        for k, v in pairs(d.Keys) do
            local e = Enum.KeyCode[v]
            if e and Keys[k] ~= nil then Keys[k] = e end
        end
    end
    if type(d.KeyEnabled) == "table" then
        for k, v in pairs(d.KeyEnabled) do
            if KeyEnabled[k] ~= nil then KeyEnabled[k] = v end
        end
    end
    if d.ST_AntiSentry ~= nil then State.AntiSentry = d.ST_AntiSentry end
    if d.ST_SpinBody ~= nil then State.SpinBody = d.ST_SpinBody end
    if d.ST_AntiRagdoll ~= nil then State.AntiRagdoll = d.ST_AntiRagdoll end
    if d.ST_InfiniteJump ~= nil then State.InfiniteJump = d.ST_InfiniteJump end
    if d.ST_FloatEnabled ~= nil then State.FloatEnabled = d.ST_FloatEnabled end
    if d.ST_XrayBase ~= nil then State.XrayBase = d.ST_XrayBase end
    if d.ST_ESP ~= nil then State.ESP = d.ST_ESP end
    if d.ST_SpeedBoost ~= nil then isSpeedBoostEnabled = d.ST_SpeedBoost end
    if d.ST_Optimizer ~= nil then State.Optimizer = d.ST_Optimizer end
    if d.ST_Unwalk ~= nil then UnwalkState.active = d.ST_Unwalk end
    if d.ST_HitCircle ~= nil then HitCircleState.Enabled = d.ST_HitCircle end
    if d.ST_SpamBat ~= nil then SpamBatState.enabled = d.ST_SpamBat end
    if d.StealBarVisible ~= nil then StealBarVisible = d.StealBarVisible end
    if type(d.sideHiddenMap) == "table" then sideHiddenMap = d.sideHiddenMap end
    if type(d.ButtonPositions) == "table" then ButtonPositions = d.ButtonPositions end
    if d.TPSettings then
        if d.TPSettings.Enabled ~= nil then TPSettings.Enabled = d.TPSettings.Enabled end
        if d.TPSettings.TPHeight then TPSettings.TPHeight = d.TPSettings.TPHeight end
    end
    if type(d.menuPos) == "table" then
        task.defer(function()
            if menu then
                menu.Position = UDim2.new(d.menuPos.X, d.menuPos.XO, d.menuPos.Y, d.menuPos.YO)
            end
        end)
    end
    if type(d.stealBarPos) == "table" then
        task.defer(function()
            if stealBarFrame then
                stealBarFrame.Position = UDim2.new(d.stealBarPos.X, d.stealBarPos.XO, d.stealBarPos.Y, d.stealBarPos.YO)
            end
        end)
    end
    task.defer(function()
        for id, boxRef in pairs(numberBoxReferences) do
            if boxRef and boxRef.TextBox then
                if id == "GrabRadius" then boxRef.TextBox.Text = tostring(EnhancedGrab.Radius)
                elseif id == "NormalSpeed" then boxRef.TextBox.Text = tostring(SpeedSettings.NormalSpeed)
                elseif id == "StealSpeed" then boxRef.TextBox.Text = tostring(SpeedSettings.StealSpeed)
                elseif id == "SideBtnSize" then boxRef.TextBox.Text = tostring(SideButtonSize)
                elseif id == "MenuWidth" then boxRef.TextBox.Text = tostring(menuW)
                elseif id == "MenuHeight" then boxRef.TextBox.Text = tostring(menuH)
                elseif id == "TrackSpeed" then boxRef.TextBox.Text = tostring(TrackSettings.TrackSpeed)
                end
            end
        end
        if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = EnhancedGrab.Radius.."st" end
    end)
end

-- STEAL BAR
stealBarFrame = Instance.new("Frame", gui)
stealBarFrame.Name = "StealBar"
stealBarFrame.Size = UDim2.new(0,340,0,36)
stealBarFrame.Position = UDim2.new(0.5,-170,1,-55)
stealBarFrame.BackgroundColor3 = Colors.White
stealBarFrame.BackgroundTransparency = 0.15
stealBarFrame.ZIndex = 50
stealBarFrame.Visible = StealBarVisible
stealBarFrame.Active = true
Instance.new("UICorner", stealBarFrame).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", stealBarFrame).Color = Colors.MediumGray

do
    local sbDrag, sbDS, sbPS, sbActiveInput = false, nil, nil, nil
    stealBarFrame.InputBegan:Connect(function(inp)
        local t = inp.UserInputType
        if (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) and not sbDrag then
            sbDrag = true
            sbActiveInput = inp
            sbDS = inp.Position
            sbPS = stealBarFrame.Position
        end
    end)
    stealBarFrame.InputChanged:Connect(function(inp)
        if not sbDrag or inp ~= sbActiveInput then return end
        local t = inp.UserInputType
        if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
        local d = inp.Position - sbDS
        stealBarFrame.Position = UDim2.new(sbPS.X.Scale, sbPS.X.Offset + d.X, sbPS.Y.Scale, sbPS.Y.Offset + d.Y)
    end)
    stealBarFrame.InputEnded:Connect(function(inp)
        local t = inp.UserInputType
        if (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) and inp == sbActiveInput then
            sbDrag = false
            sbActiveInput = nil
        end
    end)
end

sbLabel = Instance.new("TextLabel", stealBarFrame)
sbLabel.Size = UDim2.new(0,48,1,0)
sbLabel.BackgroundTransparency = 1
sbLabel.Text = "GRAB"
sbLabel.TextColor3 = Colors.DarkGray
sbLabel.Font = Enum.Font.GothamBold
sbLabel.TextSize = 12
sbLabel.ZIndex = 51

sbBG = Instance.new("Frame", stealBarFrame)
sbBG.Size = UDim2.new(1,-160,0,14)
sbBG.Position = UDim2.new(0,48,0.5,-7)
sbBG.BackgroundColor3 = Colors.AlmostBlack
sbBG.ZIndex = 51
Instance.new("UICorner", sbBG).CornerRadius = UDim.new(0,6)

sbFill = Instance.new("Frame", sbBG)
sbFill.Size = UDim2.new(0,0,1,0)
sbFill.BackgroundColor3 = Colors.DarkGray
sbFill.ZIndex = 52
Instance.new("UICorner", sbFill).CornerRadius = UDim.new(0,6)

sbPct = Instance.new("TextLabel", stealBarFrame)
sbPct.Size = UDim2.new(0,34,1,0)
sbPct.Position = UDim2.new(1,-110,0,0)
sbPct.BackgroundTransparency = 1
sbPct.Text = "0%"
sbPct.TextColor3 = Colors.Text
sbPct.Font = Enum.Font.GothamBold
sbPct.TextSize = 11
sbPct.ZIndex = 51

sbRadius = Instance.new("TextLabel", stealBarFrame)
sbRadius.Size = UDim2.new(0,38,1,0)
sbRadius.Position = UDim2.new(1,-76,0,0)
sbRadius.BackgroundTransparency = 1
sbRadius.Text = EnhancedGrab.Radius.."st"
sbRadius.TextColor3 = Colors.MediumGray
sbRadius.Font = Enum.Font.GothamBold
sbRadius.TextSize = 11
sbRadius.ZIndex = 51

sbRate = Instance.new("TextLabel", stealBarFrame)
sbRate.Size = UDim2.new(0,50,1,0)
sbRate.Position = UDim2.new(1,-50,0,0)
sbRate.BackgroundTransparency = 1
sbRate.Text = "instant"
sbRate.TextColor3 = Colors.MediumGray
sbRate.Font = Enum.Font.GothamBold
sbRate.TextSize = 10
sbRate.ZIndex = 51

grabBarRef = { fill = sbFill, pct = sbPct, radiusLbl = sbRadius, rateLbl = sbRate }

-- MENU BUTTON
local menuBtn = Instance.new("Frame", gui)
menuBtn.Size = UDim2.new(0,110,0,44)
menuBtn.Position = UDim2.new(0.5,-55,0.07,0)
menuBtn.BackgroundColor3 = Color3.fromRGB(60,38,170)
menuBtn.BackgroundTransparency = 0
menuBtn.Active = true
menuBtn.ZIndex = 60
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0,12)
mbStroke = Instance.new("UIStroke", menuBtn)
mbStroke.Color = Color3.fromRGB(130,100,255)
mbStroke.Thickness = 1.5

menuBtnLabel = Instance.new("TextLabel", menuBtn)
menuBtnLabel.Size = UDim2.new(1,0,1,0)
menuBtnLabel.BackgroundTransparency = 1
menuBtnLabel.Text = "H2N"
menuBtnLabel.TextColor3 = Color3.fromRGB(255,255,255)
menuBtnLabel.Font = Enum.Font.GothamBold
menuBtnLabel.TextSize = 18
menuBtnLabel.ZIndex = 61

local menuGlowOverlay = Instance.new("Frame", menuBtn)
menuGlowOverlay.Size = UDim2.new(1,0,1,0)
menuGlowOverlay.BackgroundColor3 = Color3.fromRGB(255,255,255)
menuGlowOverlay.BackgroundTransparency = 1
menuGlowOverlay.ZIndex = 60
menuGlowOverlay.BorderSizePixel = 0
Instance.new("UICorner", menuGlowOverlay).CornerRadius = UDim.new(0,12)

task.spawn(function()
    local t = 0
    local purpleColors = {
        Color3.fromRGB(160,120,255),
        Color3.fromRGB(130,90,255),
        Color3.fromRGB(200,160,255),
        Color3.fromRGB(110,70,230),
        Color3.fromRGB(180,140,255),
    }
    local shakeAmp = 1.2
    while true do
        t = t + 0.04
        local ci = math.floor(t * 1.5) % #purpleColors + 1
        local cn = ci % #purpleColors + 1
        local f = (t * 1.5) % 1
        local col = purpleColors[ci]:Lerp(purpleColors[cn], f)
        menuBtnLabel.TextColor3 = col
        mbStroke.Color = col
        local shimmer = math.abs(math.sin(t * 2.5))
        menuGlowOverlay.BackgroundTransparency = 1 - (shimmer * 0.13)
        local shakeX = math.sin(t * 5) * shakeAmp
        local shakeY = math.cos(t * 7) * (shakeAmp * 0.5)
        menuBtnLabel.Position = UDim2.new(0, shakeX, 0, shakeY)
        menuBtnLabel.Size = UDim2.new(1, -shakeX, 1, -shakeY)
        task.wait(0.04)
    end
end)

do
    local mbDragging = false
    local mbMoved = false
    local mbDragStart = nil
    local mbStartPos = nil
    local mbActiveInput = nil
    menuBtn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if (t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1) and not mbDragging then
            mbDragging = true
            mbMoved = false
            mbActiveInput = input
            mbDragStart = input.Position
            mbStartPos = menuBtn.Position
        end
    end)
    menuBtn.InputChanged:Connect(function(input)
        if not mbDragging or input ~= mbActiveInput then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement then return end
        local delta = input.Position - mbDragStart
        if delta.Magnitude > 6 then
            mbMoved = true
            menuBtn.Position = UDim2.new(mbStartPos.X.Scale, mbStartPos.X.Offset + delta.X, mbStartPos.Y.Scale, mbStartPos.Y.Offset + delta.Y)
        end
    end)
    menuBtn.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if (t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1) then return end
        if input ~= mbActiveInput then return end
        local didMove = mbMoved
        mbDragging = false
        mbMoved = false
        mbActiveInput = nil
        if not didMove then
            menu.Visible = not menu.Visible
        else
            Save()
        end
    end)
end

-- MAIN MENU
menu = Instance.new("Frame", gui)
menu.Size = UDim2.new(0, menuW, 0, menuH)
menu.Position = UDim2.new(0.5, -menuW/2, 0.5, -menuH/2)
menu.BackgroundColor3 = Color3.fromRGB(10,10,16)
menu.BackgroundTransparency = 0
menu.Visible = false
menu.Active = true
menu.ZIndex = 55
Instance.new("UICorner", menu).CornerRadius = UDim.new(0,14)
menuStroke = Instance.new("UIStroke", menu)
menuStroke.Color = Color3.fromRGB(100,70,230)
menuStroke.Thickness = 1.5

task.spawn(function()
    local t = 0
    while true do
        t = t + 0.05
        local glow = 0.5 + 0.5 * math.sin(t * 2)
        menuStroke.Color = Color3.fromRGB(
            math.floor(80 + glow * 80),
            math.floor(50 + glow * 40),
            math.floor(200 + glow * 55)
        )
        menuStroke.Thickness = 1.5 + glow * 1.2
        task.wait(0.05)
    end
end)

local header = Instance.new("Frame", menu)
header.Size = UDim2.new(1,0,0,42)
header.BackgroundColor3 = Color3.fromRGB(70,45,190)
header.BackgroundTransparency = 0
header.BorderSizePixel = 0
header.ZIndex = 56
hCorner = Instance.new("UICorner", header)
hCorner.CornerRadius = UDim.new(0,14)
hFix = Instance.new("Frame", header)
hFix.Size = UDim2.new(1,0,0.5,0)
hFix.Position = UDim2.new(0,0,0.5,0)
hFix.BackgroundColor3 = Color3.fromRGB(70,45,190)
hFix.BorderSizePixel = 0
hFix.ZIndex = 56

accentLine = Instance.new("Frame", menu)
accentLine.Size = UDim2.new(1,0,0,2)
accentLine.Position = UDim2.new(0,0,0,42)
accentLine.BackgroundColor3 = Color3.fromRGB(130,100,255)
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 57

task.spawn(function()
    local t = 0
    while true do
        t = t + 0.05
        local g = 0.5 + 0.5 * math.sin(t * 3)
        accentLine.BackgroundColor3 = Color3.fromRGB(
            math.floor(110 + g * 80),
            math.floor(70 + g * 50),
            math.floor(220 + g * 35)
        )
        accentLine.Size = UDim2.new(1,0,0, math.floor(2 + g * 1.5))
        task.wait(0.05)
    end
end)

tl = Instance.new("TextLabel", header)
tl.Size = UDim2.new(1,-20,1,0)
tl.Position = UDim2.new(0,14,0,0)
tl.BackgroundTransparency = 1
tl.Text = "H2N"
tl.TextColor3 = Color3.fromRGB(200,185,255)
tl.Font = Enum.Font.GothamBold
tl.TextSize = 17
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.ZIndex = 57

local h2nGlowLabel = Instance.new("TextLabel", header)
h2nGlowLabel.Size = UDim2.new(0,60,1,0)
h2nGlowLabel.Position = UDim2.new(0,14,0,0)
h2nGlowLabel.BackgroundTransparency = 1
h2nGlowLabel.Text = "H2N"
h2nGlowLabel.Font = Enum.Font.GothamBold
h2nGlowLabel.TextSize = 17
h2nGlowLabel.TextXAlignment = Enum.TextXAlignment.Left
h2nGlowLabel.ZIndex = 58

task.spawn(function()
    local t = 0
    local glowColors = {
        Color3.fromRGB(180,140,255),
        Color3.fromRGB(220,200,255),
        Color3.fromRGB(150,100,255),
        Color3.fromRGB(255,230,255),
        Color3.fromRGB(160,120,255),
    }
    while h2nGlowLabel.Parent do
        t = t + 0.05
        local ci = math.floor(t * 1.2) % #glowColors + 1
        local cn = ci % #glowColors + 1
        local f = (t * 1.2) % 1
        h2nGlowLabel.TextColor3 = glowColors[ci]:Lerp(glowColors[cn], f)
        h2nGlowLabel.TextStrokeColor3 = glowColors[ci]:Lerp(glowColors[cn], f)
        h2nGlowLabel.TextStrokeTransparency = 0.4 - math.abs(math.sin(t * 2)) * 0.3
        task.wait(0.05)
    end
end)

local verLbl = Instance.new("TextLabel", header)
verLbl.Size = UDim2.new(0,60,1,0)
verLbl.Position = UDim2.new(1,-70,0,0)
verLbl.BackgroundTransparency = 1
verLbl.Text = "v5.8"
verLbl.TextColor3 = Color3.fromRGB(200,180,255)
verLbl.Font = Enum.Font.GothamBold
verLbl.TextSize = 12
verLbl.TextXAlignment = Enum.TextXAlignment.Right
verLbl.ZIndex = 57

do
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local activeInput = nil
    header.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) and not dragging then
            dragging = true
            activeInput = input
            dragStart = input.Position
            startPos = menu.Position
        end
    end)
    header.InputChanged:Connect(function(input)
        if not dragging or input ~= activeInput then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end)
    header.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if (t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch) then return end
        if input ~= activeInput then return end
        dragging = false
        activeInput = nil
        Save()
    end)
end

local tabBar = Instance.new("Frame", menu)
tabBar.Size = UDim2.new(0,108,1,-48)
tabBar.Position = UDim2.new(0,6,0,48)
tabBar.BackgroundColor3 = Color3.fromRGB(16,14,26)
tabBar.BackgroundTransparency = 0
tabBar.ZIndex = 56
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0,10)
tbStroke = Instance.new("UIStroke", tabBar)
tbStroke.Color = Color3.fromRGB(60,45,110)
tbStroke.Thickness = 1

local tabNames = {"Combat", "Protect", "Visual", "Settings"}
local tabFrames = {}
local tabBtns = {}

for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton", tabBar)
    tb.Size = UDim2.new(1,-12,0,38)
    tb.Position = UDim2.new(0,6,0,(i-1)*44+8)
    tb.BackgroundColor3 = Color3.fromRGB(20,18,32)
    tb.Text = name
    tb.TextColor3 = Color3.fromRGB(160,145,210)
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 13
    tb.ZIndex = 57
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.AutoButtonColor = false
    local tbCorner = Instance.new("UICorner", tb)
    tbCorner.CornerRadius = UDim.new(0,8)
    local tbStk = Instance.new("UIStroke", tb)
    tbStk.Color = Color3.fromRGB(50,40,90)
    tbStk.Thickness = 1
    local pad = Instance.new("UIPadding", tb)
    pad.PaddingLeft = UDim.new(0,8)
    tabBtns[name] = tb
    local sf = Instance.new("ScrollingFrame", menu)
    sf.Size = UDim2.new(1,-124,1,-50)
    sf.Position = UDim2.new(0,118,0,48)
    sf.BackgroundTransparency = 1
    sf.Visible = (i==1)
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(100,80,200)
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ZIndex = 57
    tabFrames[name] = sf
    tb.MouseButton1Click:Connect(function()
        for _, f in pairs(tabFrames) do f.Visible = false end
        for _, b in pairs(tabBtns) do
            b.BackgroundColor3 = Color3.fromRGB(20,18,32)
            b.TextColor3 = Color3.fromRGB(160,145,210)
        end
        sf.Visible = true
        tb.BackgroundColor3 = Color3.fromRGB(70,45,190)
        tb.TextColor3 = Color3.fromRGB(255,255,255)
    end)
end
tabBtns["Combat"].BackgroundColor3 = Color3.fromRGB(70,45,190)
tabBtns["Combat"].TextColor3 = Color3.fromRGB(255,255,255)

local function MakeToggle(parent, text, order, cb, getState, featureName)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-10,0,40)
    row.Position = UDim2.new(0,5,0,order*44+4)
    row.BackgroundColor3 = Color3.fromRGB(18,16,28)
    row.BackgroundTransparency = 0
    row.ZIndex = 58
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = Color3.fromRGB(45,38,80)
    rowStroke.Thickness = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.58,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210,200,240)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0,70,0,26)
    btn.Position = UDim2.new(1,-78,0.5,-13)
    btn.BackgroundColor3 = Color3.fromRGB(35,30,55)
    btn.BackgroundTransparency = 0
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(130,120,170)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local btnStk = Instance.new("UIStroke", btn)
    btnStk.Color = Color3.fromRGB(60,50,100)
    btnStk.Thickness = 1
    local function UpdateButton()
        if getState() then
            btn.Text = "ON"
            btn.BackgroundColor3 = Color3.fromRGB(70,45,190)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btnStk.Color = Color3.fromRGB(130,100,255)
            rowStroke.Color = Color3.fromRGB(80,55,180)
        else
            btn.Text = "OFF"
            btn.BackgroundColor3 = Color3.fromRGB(35,30,55)
            btn.TextColor3 = Color3.fromRGB(130,120,170)
            btnStk.Color = Color3.fromRGB(60,50,100)
            rowStroke.Color = Color3.fromRGB(45,38,80)
        end
    end
    UpdateButton()
    btn.MouseButton1Click:Connect(function()
        cb(not getState())
        UpdateButton()
        Save()
    end)
    RunService.RenderStepped:Connect(UpdateButton)
    if featureName then
        toggleUpdaters[featureName] = function(state) cb(state); UpdateButton() end
    end
    return btn
end

local function MakeNumberBox(parent, text, default, order, cb, minVal, maxVal, id)
    minVal = minVal or 1
    maxVal = maxVal or 200
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-10,0,40)
    row.Position = UDim2.new(0,5,0,order*44+4)
    row.BackgroundColor3 = Color3.fromRGB(18,16,28)
    row.BackgroundTransparency = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local rowStk = Instance.new("UIStroke", row)
    rowStk.Color = Color3.fromRGB(45,38,80)
    rowStk.Thickness = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210,200,240)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0,70,0,26)
    box.Position = UDim2.new(1,-78,0.5,-13)
    box.BackgroundColor3 = Color3.fromRGB(28,24,45)
    box.BackgroundTransparency = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(200,185,255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 15
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke", box).Color = Color3.fromRGB(80,60,160)
    if id then
        numberBoxReferences[id] = { TextBox = box, cb = cb, minVal = minVal, maxVal = maxVal }
    end
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            n = math.clamp(n, minVal, maxVal)
            cb(n)
            box.Text = tostring(n)
        else
            box.Text = tostring(default)
        end
        Save()
    end)
    return box
end

local function MakeKeybind(parent, labelText, keyName, order)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-10,0,40)
    row.Position = UDim2.new(0,5,0,order*44+4)
    row.BackgroundColor3 = Color3.fromRGB(18,16,28)
    row.BackgroundTransparency = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", row).Color = Color3.fromRGB(45,38,80)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.46,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(210,200,240)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size = UDim2.new(0,52,0,26)
    keyBtn.Position = UDim2.new(0.47,0,0.5,-13)
    keyBtn.BackgroundColor3 = Color3.fromRGB(28,24,45)
    keyBtn.BackgroundTransparency = 0
    keyBtn.Text = Keys[keyName] and Keys[keyName].Name or "?"
    keyBtn.TextColor3 = Color3.fromRGB(200,185,255)
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 11
    keyBtn.AutoButtonColor = false
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0,7)
    Instance.new("UIStroke", keyBtn).Color = Color3.fromRGB(80,60,160)
    local enableBtn = Instance.new("TextButton", row)
    enableBtn.Size = UDim2.new(0,52,0,26)
    enableBtn.Position = UDim2.new(1,-60,0.5,-13)
    enableBtn.BackgroundColor3 = KeyEnabled[keyName] and Color3.fromRGB(40,160,100) or Color3.fromRGB(160,40,40)
    enableBtn.Text = KeyEnabled[keyName] and "ON" or "OFF"
    enableBtn.TextColor3 = Color3.fromRGB(255,255,255)
    enableBtn.Font = Enum.Font.GothamBold
    enableBtn.TextSize = 11
    enableBtn.AutoButtonColor = false
    Instance.new("UICorner", enableBtn).CornerRadius = UDim.new(0,7)
    local listening = false
    local listenConn
    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = Color3.fromRGB(50,40,80)
        if listenConn then listenConn:Disconnect() end
        listenConn = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Keys[keyName] = input.KeyCode
                keyBtn.Text = input.KeyCode.Name
                keyBtn.BackgroundColor3 = Color3.fromRGB(28,24,45)
                listening = false
                listenConn:Disconnect()
                Notify("Key "..labelText.." = "..input.KeyCode.Name)
                Save()
            end
        end)
    end)
    enableBtn.MouseButton1Click:Connect(function()
        KeyEnabled[keyName] = not KeyEnabled[keyName]
        enableBtn.Text = KeyEnabled[keyName] and "ON" or "OFF"
        enableBtn.BackgroundColor3 = KeyEnabled[keyName] and Color3.fromRGB(40,160,100) or Color3.fromRGB(160,40,40)
        Save()
    end)
end

-- ============================================
-- COMBAT TAB
-- ============================================
local ci = 0
local combat = tabFrames["Combat"]
MakeToggle(combat, "AUTO GRAB", ci, function(s) if s then StartEnhancedGrab() else StopEnhancedGrab() end end, function() return EnhancedGrab.Enabled end, "AutoGrab")
ci = ci + 1
MakeNumberBox(combat, "Grab Radius", EnhancedGrab.Radius, ci, function(v)
    EnhancedGrab.Radius = math.clamp(v, 1, 100)
    if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = EnhancedGrab.Radius.."st" end
    Notify("Grab Radius = "..EnhancedGrab.Radius)
end, 1, 100, "GrabRadius")
ci = ci + 1
MakeToggle(combat, "AUTO BAT", ci, function(s) if s then StartAutoBat() else StopAutoBat() end end, function() return TrackSettings.Enabled end, "AutoBat")
ci = ci + 1
MakeNumberBox(combat, "Track Speed", TrackSettings.TrackSpeed, ci, function(v) TrackSettings.TrackSpeed = math.clamp(v,1,300); Notify("Track Speed = "..TrackSettings.TrackSpeed) end, 1, 300, "TrackSpeed")
ci = ci + 1
MakeToggle(combat, "AUTO PLAY LEFT", ci, function(s) if s then StartAutoPlayLeft() else StopAutoPlayLeft() end end, function() return State.AutoPlayLeft end, "AutoPlayLeft")
ci = ci + 1
MakeToggle(combat, "AUTO PLAY RIGHT", ci, function(s) if s then StartAutoPlayRight() else StopAutoPlayRight() end end, function() return State.AutoPlayRight end, "AutoPlayRight")
ci = ci + 1
MakeToggle(combat, "ANTI SENTRY", ci, function(s) if s then ToggleAntiSentry() else ToggleAntiSentry() end end, function() return State.AntiSentry end, "AntiSentry")
ci = ci + 1
MakeToggle(combat, "SPIN BODY", ci, function(s) if s then ToggleSpinBody() else ToggleSpinBody() end end, function() return State.SpinBody end, "SpinBody")
ci = ci + 1
MakeToggle(combat, "SPEED BOOST", ci, function(s) if s then ToggleSpeedBoost() else ToggleSpeedBoost() end end, function() return isSpeedBoostEnabled end, "SpeedBoost")
ci = ci + 1
MakeNumberBox(combat, "Normal Speed", SpeedSettings.NormalSpeed, ci, function(v) SpeedSettings.NormalSpeed = math.clamp(v,1,200); Notify("Normal Speed = "..SpeedSettings.NormalSpeed) end, 1, 200, "NormalSpeed")
ci = ci + 1
MakeNumberBox(combat, "Steal Speed", SpeedSettings.StealSpeed, ci, function(v) SpeedSettings.StealSpeed = math.clamp(v,1,200); Notify("Steal Speed = "..SpeedSettings.StealSpeed) end, 1, 200, "StealSpeed")
ci = ci + 1

-- DROP Button
do
    local dropRow = Instance.new("Frame", combat)
    dropRow.Size = UDim2.new(1,-10,0,40)
    dropRow.Position = UDim2.new(0,5,0,ci*44+4)
    dropRow.BackgroundColor3 = Color3.fromRGB(18,16,28)
    dropRow.BackgroundTransparency = 0
    dropRow.ZIndex = 58
    Instance.new("UICorner", dropRow).CornerRadius = UDim.new(0,8)
    local dropRowStroke = Instance.new("UIStroke", dropRow)
    dropRowStroke.Color = Color3.fromRGB(45,38,80)
    dropRowStroke.Thickness = 1
    local dropLbl = Instance.new("TextLabel", dropRow)
    dropLbl.Size = UDim2.new(0.58,0,1,0)
    dropLbl.Position = UDim2.new(0,10,0,0)
    dropLbl.BackgroundTransparency = 1
    dropLbl.Text = "DROP"
    dropLbl.TextColor3 = Color3.fromRGB(210,200,240)
    dropLbl.Font = Enum.Font.GothamBold
    dropLbl.TextSize = 13
    dropLbl.TextXAlignment = Enum.TextXAlignment.Left
    local dropBtn = Instance.new("TextButton", dropRow)
    dropBtn.Size = UDim2.new(0,70,0,26)
    dropBtn.Position = UDim2.new(1,-78,0.5,-13)
    dropBtn.BackgroundColor3 = Color3.fromRGB(70,45,190)
    dropBtn.BackgroundTransparency = 0
    dropBtn.Text = "FIRE"
    dropBtn.TextColor3 = Color3.fromRGB(255,255,255)
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.TextSize = 12
    dropBtn.AutoButtonColor = false
    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0,7)
    local dropBtnStk = Instance.new("UIStroke", dropBtn)
    dropBtnStk.Color = Color3.fromRGB(130,100,255)
    dropBtnStk.Thickness = 1
    dropBtn.MouseButton1Click:Connect(function()
        _switchingModes = true
        if TrackSettings.Enabled then StopAutoBat() end
        if State.AutoPlayLeft then StopAutoPlayLeft() end
        if State.AutoPlayRight then StopAutoPlayRight() end
        _switchingModes = false
        if State.FloatEnabled then stopFloat() end
        dropBtn.BackgroundColor3 = Color3.fromRGB(40,160,100)
        task.spawn(function()
            task.wait(0.05)
            executeDrop()
            task.wait(0.4)
            dropBtn.BackgroundColor3 = Color3.fromRGB(70,45,190)
        end)
    end)
    ci = ci + 1
end

MakeToggle(combat, "HIT CIRCLE", ci, function(s) if s then ToggleHitCircle() else ToggleHitCircle() end end, function() return HitCircleState.Enabled end, "HitCircle")
ci = ci + 1
MakeToggle(combat, "SPAM BAT", ci, function(s) if s then ToggleSpamBat() else ToggleSpamBat() end end, function() return SpamBatState.enabled end, "SpamBat")
ci = ci + 1
MakeToggle(combat, "OPTIMIZER", ci, function(s) if s then ToggleOptimizer() else ToggleOptimizer() end end, function() return State.Optimizer end, "Optimizer")
ci = ci + 1

-- ============================================
-- PROTECT TAB
-- ============================================
local pi = 0
local protect = tabFrames["Protect"]
MakeToggle(protect, "ANTI RAGDOLL", pi, function(s) if s then ToggleAntiRagdoll() else ToggleAntiRagdoll() end end, function() return State.AntiRagdoll end, "AntiRagdoll")
pi = pi + 1
MakeToggle(protect, "INFINITE JUMP", pi, function(s) if s then ToggleInfiniteJump() else ToggleInfiniteJump() end end, function() return State.InfiniteJump end, "InfiniteJump")
pi = pi + 1
MakeToggle(protect, "FLOAT", pi, function(s) if s then ToggleFloat() else ToggleFloat() end end, function() return State.FloatEnabled end, "FloatEnabled")
pi = pi + 1
MakeToggle(protect, "UNWALK", pi, function(s) if s then ToggleUnwalk() else ToggleUnwalk() end end, function() return UnwalkState.active end, "Unwalk")
pi = pi + 1
MakeToggle(protect, "AUTO TP DOWN", pi, function(s) if s then ToggleAutoTPDown() else ToggleAutoTPDown() end end, function() return TPSettings.Enabled end, "AutoTPDown")
pi = pi + 1

-- ============================================
-- VISUAL TAB
-- ============================================
local vi = 0
local visual = tabFrames["Visual"]

local function GetCornerForShape(shape)
    if shape == "circle" then return UDim.new(1, 0)
    elseif shape == "rect" then return UDim.new(0, 18)
    else return UDim.new(0, 14) end
end

local _allSideButtonCorners = {}

local function ApplyShapeToAllSideButtons(shape)
    SideButtonShape = shape
    for _, data in ipairs(_allSideButtonCorners) do
        data.corner.CornerRadius = GetCornerForShape(shape)
        if shape == "rect" then
            data.btn.Size = UDim2.new(0, math.floor(SideButtonSize * 1.7), 0, SideButtonSize)
        else
            data.btn.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
        end
    end
    Save()
end

MakeToggle(visual, "ESP", vi, function(s) if s then ToggleESP() else ToggleESP() end end, function() return State.ESP end, "ESP")
vi = vi + 1
MakeToggle(visual, "XRAY BASE", vi, function(s) if s then ToggleXrayBase() else ToggleXrayBase() end end, function() return State.XrayBase end, "XrayBase")
vi = vi + 1

-- تم إزالة جميع أزرار "Hide" من تبويب Visual

MakeToggle(visual, "Show Steal Bar", vi, function(s) StealBarVisible = s; stealBarFrame.Visible = s; Save() end, function() return StealBarVisible end)
vi = vi + 1
MakeNumberBox(visual, "Side Button Size", SideButtonSize, vi, function(val)
    SideButtonSize = val
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            local btnW = (SideButtonShape == "rect") and math.floor(SideButtonSize * 1.7) or SideButtonSize
            b.Size = UDim2.new(0, btnW, 0, SideButtonSize)
        end
    end
end, 40, 150, "SideBtnSize")
vi = vi + 1
MakeNumberBox(visual, "Menu Width", menuW, vi, function(v) menuW = math.clamp(v,200,750); menu.Size = UDim2.new(0,menuW,0,menuH) end, 200, 750, "MenuWidth")
vi = vi + 1
MakeNumberBox(visual, "Menu Height", menuH, vi, function(v) menuH = math.clamp(v,200,750); menu.Size = UDim2.new(0,menuW,0,menuH) end, 200, 750, "MenuHeight")
vi = vi + 1

-- Button Shape Picker
do
    local shapeRow = Instance.new("Frame", visual)
    shapeRow.Size = UDim2.new(1,-10,0,40)
    shapeRow.Position = UDim2.new(0,5,0,vi*44+4)
    shapeRow.BackgroundColor3 = Color3.fromRGB(18,16,28)
    shapeRow.BackgroundTransparency = 0
    shapeRow.ZIndex = 58
    Instance.new("UICorner", shapeRow).CornerRadius = UDim.new(0,8)
    local shapeStk = Instance.new("UIStroke", shapeRow)
    shapeStk.Color = Color3.fromRGB(45,38,80)
    shapeStk.Thickness = 1
    local shapeLbl = Instance.new("TextLabel", shapeRow)
    shapeLbl.Size = UDim2.new(0.42,0,1,0)
    shapeLbl.Position = UDim2.new(0,10,0,0)
    shapeLbl.BackgroundTransparency = 1
    shapeLbl.Text = "Btn Shape"
    shapeLbl.TextColor3 = Color3.fromRGB(210,200,240)
    shapeLbl.Font = Enum.Font.GothamBold
    shapeLbl.TextSize = 13
    shapeLbl.TextXAlignment = Enum.TextXAlignment.Left
    shapeLbl.ZIndex = 59

    local shapes = {
        {id="square", label="■", tip="Square"},
        {id="circle", label="●", tip="Circle"},
        {id="rect",   label="▬", tip="Rect"},
    }
    local shapeBtns = {}

    local function refreshShapeBtns()
        for _, sb in ipairs(shapeBtns) do
            if sb.id == SideButtonShape then
                sb.btn.BackgroundColor3 = Color3.fromRGB(70,45,190)
                sb.btn.TextColor3 = Color3.fromRGB(255,255,255)
                sb.stroke.Color = Color3.fromRGB(130,100,255)
            else
                sb.btn.BackgroundColor3 = Color3.fromRGB(28,24,45)
                sb.btn.TextColor3 = Color3.fromRGB(160,145,210)
                sb.stroke.Color = Color3.fromRGB(80,60,160)
            end
        end
    end

    for i, sh in ipairs(shapes) do
        local sb = Instance.new("TextButton", shapeRow)
        sb.Size = UDim2.new(0, 38, 0, 26)
        sb.Position = UDim2.new(1, -14 - (4 - i) * 44, 0.5, -13)
        sb.BackgroundColor3 = Color3.fromRGB(28,24,45)
        sb.Text = sh.label
        sb.TextColor3 = Color3.fromRGB(160,145,210)
        sb.Font = Enum.Font.GothamBold
        sb.TextSize = 16
        sb.AutoButtonColor = false
        sb.ZIndex = 59
        Instance.new("UICorner", sb).CornerRadius = UDim.new(0,7)
        local sbStroke = Instance.new("UIStroke", sb)
        sbStroke.Color = Color3.fromRGB(80,60,160)
        sbStroke.Thickness = 1
        table.insert(shapeBtns, { id = sh.id, btn = sb, stroke = sbStroke })
        local shId = sh.id
        sb.MouseButton1Click:Connect(function()
            ApplyShapeToAllSideButtons(shId)
            refreshShapeBtns()
        end)
    end
    refreshShapeBtns()
    vi = vi + 1
end

-- ============================================
-- SETTINGS TAB
-- ============================================
local si = 0
local sTab = tabFrames["Settings"]
copyBtn = Instance.new("TextButton", sTab)
copyBtn.Size = UDim2.new(1,-10,0,40)
copyBtn.Position = UDim2.new(0,5,0,si*44+4)
copyBtn.BackgroundColor3 = Color3.fromRGB(70,45,190)
copyBtn.AutoButtonColor = false
copyBtn.Text = "COPY DISCORD LINK"
copyBtn.TextColor3 = Color3.fromRGB(255,255,255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,8)
copyBtn.MouseButton1Click:Connect(function()
    setclipboard("discord.gg/UeKPQC7fq")
    copyBtn.BackgroundColor3 = Color3.fromRGB(40,160,100)
    task.wait(0.8)
    copyBtn.BackgroundColor3 = Color3.fromRGB(70,45,190)
    Notify("Discord link copied!")
end)
si = si + 1
sep = Instance.new("Frame", sTab)
sep.Size = UDim2.new(1,-10,0,28)
sep.Position = UDim2.new(0,5,0,si*44+4)
sep.BackgroundColor3 = Color3.fromRGB(18,16,28)
sep.BackgroundTransparency = 0
Instance.new("UICorner", sep).CornerRadius = UDim.new(0,6)
sepLbl = Instance.new("TextLabel", sep)
sepLbl.Size = UDim2.new(1,0,1,0)
sepLbl.BackgroundTransparency = 1
sepLbl.Text = "KEYBINDS"
sepLbl.TextColor3 = Color3.fromRGB(130,100,255)
sepLbl.Font = Enum.Font.GothamBold
sepLbl.TextSize = 13
si = si + 1
MakeKeybind(sTab, "Inf Jump (J)", "InfJump", si); si = si + 1
MakeKeybind(sTab, "Auto Left (G)", "AutoPlayLeft", si); si = si + 1
MakeKeybind(sTab, "Auto Right (H)", "AutoPlayRight", si); si = si + 1
MakeKeybind(sTab, "Anti Ragdoll (K)", "AntiRagdoll", si); si = si + 1
MakeKeybind(sTab, "Float (F)", "Float", si); si = si + 1
MakeKeybind(sTab, "Speed Boost (B)", "SpeedBoost", si); si = si + 1
MakeKeybind(sTab, "Unwalk (U)", "Unwalk", si); si = si + 1
MakeKeybind(sTab, "Auto TP Down (T)", "AutoTPDown", si); si = si + 1
MakeKeybind(sTab, "Auto Bat (X)", "AutoBat", si); si = si + 1

-- ============================================
-- SIDE BUTTONS
-- ============================================
local function CreateSideButton(text, side, index, getState, startFn, stopFn, stateKey)
    local btnW = (SideButtonShape == "rect") and math.floor(SideButtonSize * 1.7) or SideButtonSize
    local btn = Instance.new("Frame", gui)
    btn.Name = "SideButton"
    btn:SetAttribute("ID", text)
    btn.Size = UDim2.new(0, btnW, 0, SideButtonSize)
    btn.BackgroundColor3 = Color3.fromRGB(12,10,20)
    btn.BackgroundTransparency = 0
    btn.Active = true
    btn.ZIndex = 100
    
    -- الزر الجانبي يبدأ مخفي
    btn.Visible = false
    
    local saved = ButtonPositions[text]
    if saved then
        btn.Position = UDim2.new(saved.X, saved.XO, saved.Y, saved.YO)
    elseif side == "left" then
        btn.Position = UDim2.new(0,10,0.10+index*0.14,0)
    else
        btn.Position = UDim2.new(1,-(btnW+10),0.10+index*0.14,0)
    end
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = GetCornerForShape(SideButtonShape)
    table.insert(_allSideButtonCorners, { corner = corner, btn = btn })
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(70,55,130)
    stroke.Thickness = 1.5

    task.spawn(function()
        local t2 = math.random() * math.pi * 2
        while btn and btn.Parent do
            t2 = t2 + 0.06
            local g2 = 0.5 + 0.5 * math.sin(t2 * 1.8)
            if getState() then
                stroke.Color = Color3.fromRGB(
                    math.floor(120 + g2 * 70),
                    math.floor(80 + g2 * 40),
                    math.floor(230 + g2 * 25)
                )
                stroke.Thickness = 2 + g2 * 1.5
            else
                stroke.Color = Color3.fromRGB(
                    math.floor(50 + g2 * 40),
                    math.floor(38 + g2 * 28),
                    math.floor(100 + g2 * 60)
                )
                stroke.Thickness = 1 + g2 * 0.8
            end
            task.wait(0.06)
        end
    end)
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1,-6,0.48,0)
    lbl.Position = UDim2.new(0,3,0,4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(190,180,220)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextWrapped = true
    local descText = ""
    if text == "AUTO PLAY LEFT" then descText = "Left Lane"
    elseif text == "AUTO PLAY RIGHT" then descText = "Right Lane"
    elseif text == "FLOAT" then descText = "Hover"
    elseif text == "SPEED BOOST" then descText = "Speed"
    elseif text == "AUTO BAT" then descText = "Auto Bat"
    elseif text == "DROP" then descText = "Throw"
    elseif text == "AUTO TP DOWN" then descText = "Auto Land"
    end
    local desc = Instance.new("TextLabel", btn)
    desc.Size = UDim2.new(1,-6,0.28,0)
    desc.Position = UDim2.new(0,3,0,42)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = Color3.fromRGB(110,95,160)
    desc.Font = Enum.Font.GothamBold
    desc.TextSize = 9
    desc.TextWrapped = true
    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0,10,0,10)
    dot.Position = UDim2.new(0.5,-5,1,-13)
    dot.BackgroundColor3 = Color3.fromRGB(45,38,80)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local function RefreshVisual()
        if getState() then
            dot.BackgroundColor3 = Color3.fromRGB(160,130,255)
            btn.BackgroundColor3 = Color3.fromRGB(55,35,150)
            lbl.TextColor3 = Color3.fromRGB(255,255,255)
            desc.TextColor3 = Color3.fromRGB(180,165,230)
            -- الزر الجانبي يظهر فقط إذا كانت الخاصية مفعلة
            btn.Visible = true
        else
            dot.BackgroundColor3 = Color3.fromRGB(45,38,80)
            btn.BackgroundColor3 = Color3.fromRGB(12,10,20)
            lbl.TextColor3 = Color3.fromRGB(190,180,220)
            desc.TextColor3 = Color3.fromRGB(110,95,160)
            btn.Visible = false
        end
    end
    local pressing = false
    local hasMoved = false
    local dragStart = nil
    local btnStart = nil
    local activeInputId = nil
    local function resetState()
        pressing = false
        hasMoved = false
        dragStart = nil
        btnStart = nil
        activeInputId = nil
        local bW = (SideButtonShape == "rect") and math.floor(SideButtonSize * 1.7) or SideButtonSize
        btn.Size = UDim2.new(0, bW, 0, SideButtonSize)
    end
    btn.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        if pressing then return end
        pressing = true
        hasMoved = false
        activeInputId = input
        dragStart = input.Position
        btnStart = btn.Position
        local bW = (SideButtonShape == "rect") and math.floor(SideButtonSize * 1.7) or SideButtonSize
        btn.Size = UDim2.new(0, bW - 4, 0, SideButtonSize - 4)
    end)
    btn.InputChanged:Connect(function(input)
        if not pressing or input ~= activeInputId then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseMovement then return end
        if not dragStart or not btnStart then return end
        local delta = input.Position - dragStart
        if delta.Magnitude > 8 then
            hasMoved = true
            btn.Position = UDim2.new(btnStart.X.Scale, btnStart.X.Offset + delta.X, btnStart.Y.Scale, btnStart.Y.Offset + delta.Y)
        end
    end)
    local function handleRelease()
        if not pressing then return end
        local didMove = hasMoved
        local savedPos = btn.Position
        resetState()
        if not didMove then
            if getState() then stopFn() else startFn() end
            RefreshVisual()
        else
            ButtonPositions[text] = {X = savedPos.X.Scale, XO = savedPos.X.Offset, Y = savedPos.Y.Scale, YO = savedPos.Y.Offset}
            Save()
        end
    end
    btn.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        if input ~= activeInputId then return end
        handleRelease()
    end)
    UIS.InputEnded:Connect(function(input)
        if not pressing or input ~= activeInputId then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        handleRelease()
    end)
    RunService.RenderStepped:Connect(RefreshVisual)
    if stateKey then sideButtonRefs[stateKey] = function(state) if state then startFn() else stopFn() end; RefreshVisual() end end
end

CreateSideButton("AUTO PLAY LEFT", "left", 0, function() return State.AutoPlayLeft end, StartAutoPlayLeft, StopAutoPlayLeft, "AutoPlayLeft")
CreateSideButton("AUTO PLAY RIGHT", "left", 1, function() return State.AutoPlayRight end, StartAutoPlayRight, StopAutoPlayRight, "AutoPlayRight")
CreateSideButton("AUTO BAT", "right", 0, function() return TrackSettings.Enabled end, StartAutoBat, StopAutoBat, "AutoBat")
CreateSideButton("SPEED BOOST", "right", 1, function() return isSpeedBoostEnabled end, ToggleSpeedBoost, ToggleSpeedBoost, "SpeedBoost")
CreateSideButton("AUTO TP DOWN", "right", 2, function() return TPSettings.Enabled end, ToggleAutoTPDown, ToggleAutoTPDown, "AutoTPDown")
CreateSideButton("FLOAT", "right", 3, function() return State.FloatEnabled end, ToggleFloat, ToggleFloat, "FloatEnabled")
CreateSideButton("DROP", "right", 4, function() return false end,
    function()
        _switchingModes = true
        if TrackSettings.Enabled then StopAutoBat() end
        if State.AutoPlayLeft then StopAutoPlayLeft() end
        if State.AutoPlayRight then StopAutoPlayRight() end
        _switchingModes = false
        if State.FloatEnabled then stopFloat() end
        task.spawn(function() task.wait(0.05); executeDrop() end)
    end,
    function() end, nil)

-- ============================================
-- INITIALIZATION
-- ============================================
RunService.Heartbeat:Connect(function(dt)
    if State.AntiSentry then updateAntiSentry() end
    if State.ESP then updateESP() end
end)

Load()
initWPParts()
stealBarFrame.Visible = StealBarVisible
menu.Size = UDim2.new(0, menuW, 0, menuH)

-- تطبيق الشكل الأساسي (مستطيل)
ApplyShapeToAllSideButtons("rect")

for _, b in pairs(gui:GetChildren()) do
    if b:IsA("Frame") and b.Name == "SideButton" then
        local btnW = (SideButtonShape == "rect") and math.floor(SideButtonSize * 1.7) or SideButtonSize
        b.Size = UDim2.new(0, btnW, 0, SideButtonSize)
        local id = b:GetAttribute("ID")
        local sp = ButtonPositions[id]
        if sp then b.Position = UDim2.new(sp.X, sp.XO, sp.Y, sp.YO) end
        local corner = b:FindFirstChildOfClass("UICorner")
        if corner then corner.CornerRadius = GetCornerForShape(SideButtonShape) end
        b.Visible = false
    end
end

-- Auto-start saved features
if EnhancedGrab.Enabled then
    task.spawn(function() task.wait(3); EnhancedGrab.Enabled = false; StartEnhancedGrab() end)
end
if TrackSettings.Enabled then
    task.spawn(function() task.wait(2.5); StartAutoBat() end)
end
if SpamBatState.enabled then
    task.spawn(function() task.wait(2); StartSpamBat() end)
end
if HitCircleState.Enabled then
    task.spawn(function() task.wait(2); StartHitCircle() end)
end
if State.Optimizer then
    task.spawn(function() task.wait(2); startOptimizer() end)
end

task.spawn(function()
    task.wait(1)
    setupDamageTracking()
end)

task.spawn(function()
    while not (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character:FindFirstChildOfClass("Humanoid")) do
        task.wait(0.2)
    end
    task.wait(0.5)
    
    local savedSentry = State.AntiSentry
    local savedSpin = State.SpinBody
    local savedRagdoll = State.AntiRagdoll
    local savedJump = State.InfiniteJump
    local savedFloat = State.FloatEnabled
    local savedXray = State.XrayBase
    local savedESP = State.ESP
    local savedSpeed = isSpeedBoostEnabled
    local savedAutoLeft = State.AutoPlayLeft
    local savedAutoRight = State.AutoPlayRight
    local savedGrab = EnhancedGrab.Enabled
    local savedAutoBat = TrackSettings.Enabled
    local savedUnwalk = UnwalkState.active
    local savedTP = TPSettings.Enabled
    local savedOptimizer = State.Optimizer
    local savedHitCircle = HitCircleState.Enabled
    local savedSpamBat = SpamBatState.enabled
    
    State.AntiSentry = false
    State.SpinBody = false
    State.InfiniteJump = false
    State.FloatEnabled = false
    State.XrayBase = false
    State.ESP = false
    State.AntiRagdoll = false
    State.AutoPlayLeft = false
    State.AutoPlayRight = false
    State.Optimizer = false
    isSpeedBoostEnabled = false
    EnhancedGrab.Enabled = false
    TrackSettings.Enabled = false
    TPSettings.Enabled = false
    HitCircleState.Enabled = false
    SpamBatState.enabled = false
    if UnwalkState.active then stopUnwalk() end
    StopTPMonitoring()
    
    local function safeStart(fn, name)
        task.spawn(function() pcall(function() fn(); print("Auto-activated: "..name) end) end)
        task.wait(0.05)
    end
    
    if savedSentry then safeStart(StartAntiSentry, "Anti Sentry") end
    if savedSpin then safeStart(StartSpinBody, "Spin Body") end
    if savedRagdoll then safeStart(StartAntiRagdoll, "Anti Ragdoll") end
    if savedJump then safeStart(StartInfiniteJump, "Infinite Jump") end
    if savedFloat then safeStart(startFloat, "Float") end
    if savedXray then safeStart(StartXrayBase, "Xray Base") end
    if savedESP then safeStart(StartESP, "ESP") end
    if savedSpeed then safeStart(startSpeedBoost, "Speed Boost") end
    if savedOptimizer then safeStart(startOptimizer, "Optimizer") end
    if savedHitCircle then safeStart(StartHitCircle, "Hit Circle") end
    if savedSpamBat then safeStart(StartSpamBat, "Spam Bat") end
    
    _switchingModes = true
    if savedAutoLeft then safeStart(StartAutoPlayLeft, "Auto Play Left") end
    if savedAutoRight then safeStart(StartAutoPlayRight, "Auto Play Right") end
    if savedGrab then safeStart(StartEnhancedGrab, "Auto Grab") end
    if savedAutoBat then safeStart(StartAutoBat, "Auto Bat") end
    _switchingModes = false
    
    if savedUnwalk then safeStart(startUnwalk, "Unwalk") end
    if savedTP then ToggleAutoTPDown() end
    
    task.wait(0.3)
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            local id = b:GetAttribute("ID")
            local isOn = false
            if id == "AUTO PLAY LEFT" then isOn = State.AutoPlayLeft
            elseif id == "AUTO PLAY RIGHT" then isOn = State.AutoPlayRight
            elseif id == "FLOAT" then isOn = State.FloatEnabled
            elseif id == "SPEED BOOST" then isOn = isSpeedBoostEnabled
            elseif id == "AUTO BAT" then isOn = TrackSettings.Enabled
            elseif id == "AUTO TP DOWN" then isOn = TPSettings.Enabled
            end
            b.BackgroundColor3 = isOn and Color3.fromRGB(55,35,150) or Color3.fromRGB(12,10,20)
            b.Visible = isOn
        end
    end
    
    task.wait(0.2)
    if toggleUpdaters["AntiRagdoll"] then toggleUpdaters["AntiRagdoll"](State.AntiRagdoll) end
    if toggleUpdaters["InfiniteJump"] then toggleUpdaters["InfiniteJump"](State.InfiniteJump) end
    if toggleUpdaters["FloatEnabled"] then toggleUpdaters["FloatEnabled"](State.FloatEnabled) end
    if toggleUpdaters["SpeedBoost"] then toggleUpdaters["SpeedBoost"](isSpeedBoostEnabled) end
    if toggleUpdaters["AutoBat"] then toggleUpdaters["AutoBat"](TrackSettings.Enabled) end
    if toggleUpdaters["AutoGrab"] then toggleUpdaters["AutoGrab"](EnhancedGrab.Enabled) end
    if toggleUpdaters["AntiSentry"] then toggleUpdaters["AntiSentry"](State.AntiSentry) end
    if toggleUpdaters["SpinBody"] then toggleUpdaters["SpinBody"](State.SpinBody) end
    if toggleUpdaters["XrayBase"] then toggleUpdaters["XrayBase"](State.XrayBase) end
    if toggleUpdaters["ESP"] then toggleUpdaters["ESP"](State.ESP) end
    if toggleUpdaters["AutoPlayLeft"] then toggleUpdaters["AutoPlayLeft"](State.AutoPlayLeft) end
    if toggleUpdaters["AutoPlayRight"] then toggleUpdaters["AutoPlayRight"](State.AutoPlayRight) end
    if toggleUpdaters["Unwalk"] then toggleUpdaters["Unwalk"](UnwalkState.active) end
    if toggleUpdaters["AutoTPDown"] then toggleUpdaters["AutoTPDown"](TPSettings.Enabled) end
    if toggleUpdaters["Optimizer"] then toggleUpdaters["Optimizer"](State.Optimizer) end
    if toggleUpdaters["HitCircle"] then toggleUpdaters["HitCircle"](HitCircleState.Enabled) end
    if toggleUpdaters["SpamBat"] then toggleUpdaters["SpamBat"](SpamBatState.enabled) end
end)

Notify("H2N v5.8 - Side buttons appear when feature is ON")
print("===============================================================")
print("H2N v5.8")
print("- Side buttons appear when feature is enabled")
print("- Side buttons disappear when feature is disabled")
print("- AUTO BAT from Zyphrot")
print("- Full save/load system")
print("===============================================================")