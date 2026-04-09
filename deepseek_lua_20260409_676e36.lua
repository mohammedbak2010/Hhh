-- H2N - ULTIMATE SCRIPT (Silent Auto Play + Hit Circle Aimbot + Fixed Float + Enhanced Auto Track + Enhanced Auto Grab)
-- Features: Silent Auto Play Left/Right, Hit Circle (Aimbot + Purple Circle), Float (stops at height 12), Auto Track, Speed Boost, Anti Ragdoll, ESP, Xray, Spam Bat, Optimizer, Enhanced Auto Grab, etc.

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
    pcall(function() _grabCallbackCache = {} end)
end)

-- ============================================
-- STATE
-- ============================================
local State = {
    AutoPlayLeft = false, AutoPlayRight = false, AutoTrack = false,
    AntiRagdoll = false, InfiniteJump = false, XrayBase = false,
    ESP = false, AntiSentry = false, SpinBody = false, FloatEnabled = false,
    SpeedBoostEnabled = false, AutoGrab = false, SpamBat = false,
    HitCircle = false, Optimizer = false,
}

local SpeedSettings = { NormalSpeed = 52, StealSpeed = 27 }
local isSpeedBoostEnabled = false
local speedConn = nil
local speedBoostWasOnBeforeTrack = false
local speedBoostWasOnBeforeAutoPlay = false
local speedBoostWasOnBeforeDrop = false

-- ============================================
-- SPEED BOOST
-- ============================================
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
        local targetSpeed = isHoldingBrainrot() and SpeedSettings.StealSpeed or SpeedSettings.NormalSpeed
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * targetSpeed, hrp.AssemblyLinearVelocity.Y, moveDir.Z * targetSpeed)
        else
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
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

-- ============================================
-- FLOAT (Stops at height 12)
-- ============================================
local FloatHeight = 12
local FloatUpSpeed = 70
local FloatConn = nil
local floatTargetY = nil

local function startFloat()
    if State.FloatEnabled then return end
    pcall(function()
        if State.AutoTrack then StopTrackToggle() end
    end)
    if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
    State.FloatEnabled = true
    
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rayParams)
        local groundY = result and result.Position.Y or (hrp.Position.Y - FloatHeight)
        floatTargetY = groundY + FloatHeight
    end
    
    FloatConn = RunService.Heartbeat:Connect(function()
        if not State.FloatEnabled then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rayParams)
        local groundY = result and result.Position.Y or (hrp.Position.Y - FloatHeight)
        local targetY = groundY + FloatHeight
        
        local diff = targetY - hrp.Position.Y
        
        if math.abs(diff) < 0.5 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        elseif diff > 0.3 then
            local upSpeed = math.min(diff * 12, FloatUpSpeed)
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, upSpeed, hrp.AssemblyLinearVelocity.Z)
        elseif diff < -0.3 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -8, hrp.AssemblyLinearVelocity.Z)
        else
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end)
    Notify("FLOAT ON (Height: "..FloatHeight..")")
end

local function stopFloat()
    if not State.FloatEnabled then return end
    State.FloatEnabled = false
    if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
    Notify("FLOAT OFF")
end

-- ============================================
-- AUTO GRAB (ENHANCED VERSION)
-- ============================================
local EnhancedGrab = { Enabled = false, Radius = 11, Delay = 0.17, CurrentProgress = 0, _timer = 0, LoopConnection = nil }
local grabBarRef = {}
local sbFill = nil
local stealBarFrame = nil
local _grabCallbackCache = {}

local function _isOwnPrompt(p)
    return Char and p:IsDescendantOf(Char)
end

local function _getPromptPos(prompt)
    local pos
    pcall(function()
        local par = prompt.Parent
        if par:IsA("BasePart") then
            pos = par.Position
        elseif par:IsA("Attachment") then
            pos = par.WorldPosition
        elseif par:IsA("Model") then
            local pp = par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart")
            if pp then pos = pp.Position end
        else
            local bp = par:FindFirstChildWhichIsA("BasePart", true)
            if bp then pos = bp.Position end
        end
    end)
    return pos
end

local function _buildCallbacks(prompt)
    if _grabCallbackCache[prompt] then return end
    local data = {holdCBs = {}, triggerCBs = {}, ready = true}
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function) == "function" then
                table.insert(data.holdCBs, conn.Function)
            end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function) == "function" then
                table.insert(data.triggerCBs, conn.Function)
            end
        end
    end
    if #data.holdCBs > 0 or #data.triggerCBs > 0 then
        _grabCallbackCache[prompt] = data
    end
end

local function _execSteal(prompt)
    local data = _grabCallbackCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    task.spawn(function()
        for _, fn in ipairs(data.holdCBs) do
            task.spawn(fn)
        end
        task.wait(0.1)
        for _, fn in ipairs(data.triggerCBs) do
            task.spawn(fn)
        end
        task.wait(0.01)
        data.ready = true
    end)
    return true
end

local function _firePrompt(prompt)
    local fired = false
    pcall(function()
        if fireproximityprompt then
            prompt.HoldDuration = 0
            fireproximityprompt(prompt, 0, 0)
            fired = true
        end
    end)
    if fired then return end
    local ok, conns = pcall(getconnections, prompt.Triggered)
    if ok and type(conns) == "table" then
        for _, c in ipairs(conns) do
            if c.Function then task.spawn(c.Function) end
        end
        return
    end
    pcall(function()
        prompt:InputHoldBegin()
        task.delay(0.05, function()
            pcall(function() prompt:InputHoldEnd() end)
        end)
    end)
end

local function GetClosestPromptEnhanced()
    if not HRP then return nil end
    local bestPrompt, bestDist = nil, EnhancedGrab.Radius
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in pairs(plots:GetChildren()) do
            for _, desc in pairs(plot:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled and not _isOwnPrompt(desc) then
                    local pos = _getPromptPos(desc)
                    if pos then
                        local d = (HRP.Position - pos).Magnitude
                        if d < bestDist then
                            bestDist = d
                            bestPrompt = desc
                        end
                    end
                end
            end
        end
    end
    return bestPrompt
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
        grabBarRef.rateLbl.Text = string.format("%.2f", EnhancedGrab.Delay).."s"
    end
end

local function EnhancedGrabLoop(dt)
    if not EnhancedGrab.Enabled or not HRP then
        UpdateEnhancedGrabBar(0)
        return
    end
    local targetPrompt = GetClosestPromptEnhanced()
    if targetPrompt then
        EnhancedGrab._timer = EnhancedGrab._timer + dt
        local pct = math.min(EnhancedGrab._timer / EnhancedGrab.Delay, 1) * 100
        EnhancedGrab.CurrentProgress = pct
        UpdateEnhancedGrabBar(pct)
        if EnhancedGrab._timer >= EnhancedGrab.Delay then
            EnhancedGrab._timer = 0
            EnhancedGrab.CurrentProgress = 0
            _buildCallbacks(targetPrompt)
            if not _execSteal(targetPrompt) then
                _firePrompt(targetPrompt)
            end
        end
    else
        EnhancedGrab._timer = 0
        EnhancedGrab.CurrentProgress = 0
        UpdateEnhancedGrabBar(0)
    end
end

local function StartEnhancedGrab()
    if EnhancedGrab.Enabled then return end
    if EnhancedGrab.LoopConnection then EnhancedGrab.LoopConnection:Disconnect() end
    EnhancedGrab.Enabled = true
    EnhancedGrab.CurrentProgress = 0
    EnhancedGrab._timer = 0
    _grabCallbackCache = {}
    EnhancedGrab.LoopConnection = RunService.Heartbeat:Connect(EnhancedGrabLoop)
    UpdateEnhancedGrabBar(0)
    Notify("AUTO GRAB ON | Range: "..EnhancedGrab.Radius)
end

local function StopEnhancedGrab()
    if not EnhancedGrab.Enabled then return end
    EnhancedGrab.Enabled = false
    UpdateEnhancedGrabBar(0)
    if EnhancedGrab.LoopConnection then
        EnhancedGrab.LoopConnection:Disconnect()
        EnhancedGrab.LoopConnection = nil
    end
    Notify("AUTO GRAB OFF")
end

-- ============================================
-- DROP
-- ============================================
local dropIsActive = false
local lastDropTime = 0
local DROP_COOLDOWN = 2.5

local function executeDrop()
    local now = tick()
    if now - lastDropTime < DROP_COOLDOWN then
        Notify("DROP cooldown: "..string.format("%.1f", DROP_COOLDOWN - (now - lastDropTime)).."s")
        return
    end
    if dropIsActive then return end
    lastDropTime = now
    dropIsActive = true
    
    local speedWasOn = isSpeedBoostEnabled
    if speedWasOn then stopSpeedBoost() end
    
    local char = LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local VELOCITY_X = 105
        local VELOCITY_Y = 228
        local DURATION = 0.15
        local startTime = tick()
        
        task.spawn(function()
            while dropIsActive and (tick() - startTime) < DURATION do
                local c = LP.Character
                if not c or not c:FindFirstChild("HumanoidRootPart") then break end
                c.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(VELOCITY_X, VELOCITY_Y, c.HumanoidRootPart.AssemblyLinearVelocity.Z)
                task.wait(0.01)
            end
            dropIsActive = false
            if speedWasOn then
                task.wait(0.35)
                startSpeedBoost()
            end
            Notify("DROP!")
        end)
    else
        dropIsActive = false
        if speedWasOn then startSpeedBoost() end
    end
end

-- ============================================
-- AUTO TRACK (ENHANCED VERSION)
-- ============================================
local TrackSettings = {
    Enabled = false, LockSpeed = 80, TrackSpeed = 58, ForwardOffset = 2.3,
    ExtraForward = 0.45, TrackConn = nil, AntiWallConn = nil,
    AlignOri = nil, Attachment = nil, AutoBatActive = false, AutoBatLoop = nil,
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

local function StartTrack()
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
    
    local prevMoveDir = nil
    local prevMoveTick = 0
    
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
            prevMoveDir = nil
            return
        end
        
        if not TrackSettings.AutoBatActive then startAutoBatSpam() end
        
        local tv = target.AssemblyLinearVelocity
        local moveX = tv.X
        local moveZ = tv.Z
        local moveMag = math.sqrt(moveX*moveX + moveZ*moveZ)
        local turnSide = 0
        local now = tick()
        
        if moveMag > 2 then
            local curDirX = moveX / moveMag
            local curDirZ = moveZ / moveMag
            if prevMoveDir and (now - prevMoveTick) < 0.15 then
                local dt = now - prevMoveTick
                local cross = prevMoveDir.X * curDirZ - prevMoveDir.Z * curDirX
                local dot = prevMoveDir.X * curDirX + prevMoveDir.Z * curDirZ
                if dot < 0.9999 and dt > 0.01 then
                    local turnRate = cross / dt
                    turnSide = math.clamp(turnRate * 0.08, -0.5, 0.5)
                end
            end
            prevMoveDir = { X = curDirX, Z = curDirZ }
            prevMoveTick = now
        else
            prevMoveDir = nil
        end
        
        local offsetX, offsetZ
        if moveMag > 1 then
            local normX = moveX / moveMag
            local normZ = moveZ / moveMag
            local sideX = normZ
            local sideZ = -normX
            offsetX = normX * (TrackSettings.ForwardOffset + TrackSettings.ExtraForward) + sideX * turnSide
            offsetZ = normZ * (TrackSettings.ForwardOffset + TrackSettings.ExtraForward) + sideZ * turnSide
        else
            offsetX, offsetZ = 0, 0
        end
        
        local aimX = target.Position.X + offsetX
        local aimY = target.Position.Y
        local aimZ = target.Position.Z + offsetZ
        
        local dX = aimX - h.Position.X
        local dZ = aimZ - h.Position.Z
        local dY = aimY - h.Position.Y
        local flatDist = math.sqrt(dX*dX + dZ*dZ)
        local yVel = math.clamp(dY * 12, -35, 35)
        
        local velX, velZ
        if flatDist > 1.5 then
            velX = (dX / flatDist) * TrackSettings.TrackSpeed
            velZ = (dZ / flatDist) * TrackSettings.TrackSpeed
        else
            velX = tv.X + dX * 20
            velZ = tv.Z + dZ * 20
            local mag = math.sqrt(velX*velX + velZ*velZ)
            if mag > TrackSettings.LockSpeed then
                velX = velX / mag * TrackSettings.LockSpeed
                velZ = velZ / mag * TrackSettings.LockSpeed
            end
        end
        
        h.AssemblyLinearVelocity = Vector3.new(velX, yVel, velZ)
        
        if TrackSettings.AlignOri then
            local dirX = h.Position.X - target.Position.X
            local dirZ = h.Position.Z - target.Position.Z
            local dirMag = math.sqrt(dirX*dirX + dirZ*dirZ)
            if dirMag > 0.1 then
                TrackSettings.AlignOri.Enabled = true
                TrackSettings.AlignOri.CFrame = CFrame.lookAt(h.Position, h.Position + Vector3.new(dirX/dirMag, 0, dirZ/dirMag))
            end
        end
    end)
    
    if TrackSettings.AntiWallConn then TrackSettings.AntiWallConn:Disconnect() end
    TrackSettings.AntiWallConn = RunService.Heartbeat:Connect(function()
        if not TrackSettings.Enabled then return end
        local hrpPos = getHRPTrack()
        if not hrpPos then return end
        local char = LP.Character
        if not char then return end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local lookDir = hrpPos.CFrame.LookVector
        local frontRay = workspace:Raycast(hrpPos.Position, lookDir * 4, rayParams)
        if frontRay and frontRay.Distance < 2 then
            local currentVel = hrpPos.AssemblyLinearVelocity
            local pushDir = lookDir * -12
            hrpPos.AssemblyLinearVelocity = Vector3.new(pushDir.X, currentVel.Y, pushDir.Z)
            local slideDir = Vector3.new(lookDir.Z, 0, -lookDir.X)
            hrpPos.AssemblyLinearVelocity = hrpPos.AssemblyLinearVelocity + Vector3.new(slideDir.X * 5, 0, slideDir.Z * 5)
        end
        
        local rightDir = hrpPos.CFrame.RightVector
        local leftDir = -rightDir
        local rightRay = workspace:Raycast(hrpPos.Position, rightDir * 2.5, rayParams)
        local leftRay = workspace:Raycast(hrpPos.Position, leftDir * 2.5, rayParams)
        if rightRay and rightRay.Distance < 1.2 then
            local currentVel = hrpPos.AssemblyLinearVelocity
            hrpPos.AssemblyLinearVelocity = Vector3.new(currentVel.X - 4, currentVel.Y, currentVel.Z - 4)
        elseif leftRay and leftRay.Distance < 1.2 then
            local currentVel = hrpPos.AssemblyLinearVelocity
            hrpPos.AssemblyLinearVelocity = Vector3.new(currentVel.X + 4, currentVel.Y, currentVel.Z + 4)
        end
    end)
end

local function StopTrack()
    if TrackSettings.TrackConn then
        TrackSettings.TrackConn:Disconnect()
        TrackSettings.TrackConn = nil
    end
    if TrackSettings.AntiWallConn then
        TrackSettings.AntiWallConn:Disconnect()
        TrackSettings.AntiWallConn = nil
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

local function StartTrackToggle()
    if State.AutoTrack then return end
    if State.AutoPlayLeft or State.AutoPlayRight then
        if State.AutoPlayLeft then StopAutoPlayLeft() end
        if State.AutoPlayRight then StopAutoPlayRight() end
    end
    if State.FloatEnabled then stopFloat() end
    
    speedBoostWasOnBeforeTrack = isSpeedBoostEnabled
    if isSpeedBoostEnabled then stopSpeedBoost() end
    
    State.AutoTrack = true
    TrackSettings.Enabled = true
    task.wait(0.05)
    local hrp = getHRPTrack()
    if hrp then
        StartTrack()
    else
        task.spawn(function()
            while State.AutoTrack and not getHRPTrack() do task.wait(0.1) end
            if State.AutoTrack then StartTrack() end
        end)
    end
    Notify("AUTO TRACK ON")
end

local function StopTrackToggle()
    if not State.AutoTrack then return end
    State.AutoTrack = false
    TrackSettings.Enabled = false
    StopTrack()
    if speedBoostWasOnBeforeTrack then
        speedBoostWasOnBeforeTrack = false
        startSpeedBoost()
    end
    Notify("AUTO TRACK OFF")
end

-- ============================================
-- AUTO PLAY (WAYPOINTS VERSION)
-- ============================================
local L1 = Vector3.new(-476, -7, 93)
local L2 = Vector3.new(-485, -5, 95)
local L_END = Vector3.new(-475, -7, 18)
local R1 = Vector3.new(-476, -7, 28)
local R2 = Vector3.new(-485, -5, 26)
local R_END = Vector3.new(-476, -7, 101)

local LEFT_ROUTE = {"L1", "L2", "L1", "L_END"}
local RIGHT_ROUTE = {"R1", "R2", "R1", "R_END"}

local WP_PARTS = {}
local WP_BLUE = Color3.fromRGB(0,150,255)
local WP_COLORS = {L1=WP_BLUE, L2=WP_BLUE, L_END=WP_BLUE, R1=WP_BLUE, R2=WP_BLUE, R_END=WP_BLUE}

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
    return part
end

local function initWPParts()
    createWPPart("L1",L1,WP_COLORS.L1)
    createWPPart("L2",L2,WP_COLORS.L2)
    createWPPart("L_END",L_END,WP_COLORS.L_END)
    createWPPart("R1",R1,WP_COLORS.R1)
    createWPPart("R2",R2,WP_COLORS.R2)
    createWPPart("R_END",R_END,WP_COLORS.R_END)
end

local function getWP(name)
    local p = WP_PARTS[name]
    if p and p.Parent then return p.Position end
    if name=="L1" then return L1
    elseif name=="L2" then return L2
    elseif name=="L_END" then return L_END
    elseif name=="R1" then return R1
    elseif name=="R2" then return R2
    elseif name=="R_END" then return R_END
    end
end

local aplConn, aprConn = nil, nil
local aplPhase, aprPhase = 1, 1
local _switchingModes = false

local function getHRP2()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function MoveToPoint(hrp, targetPos, speed)
    if not hrp or not targetPos then return true end
    local myPos = hrp.Position
    local xzDist = Vector2.new(targetPos.X - myPos.X, targetPos.Z - myPos.Z).Magnitude
    if xzDist < 1.2 then
        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        return true
    end
    local direction = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z).Unit
    hrp.AssemblyLinearVelocity = Vector3.new(direction.X * speed, hrp.AssemblyLinearVelocity.Y, direction.Z * speed)
    return false
end

local function StopAutoPlayLeft()
    if not State.AutoPlayLeft then return end
    State.AutoPlayLeft = false
    if aplConn then aplConn:Disconnect(); aplConn = nil end
    aplPhase = 1
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
    if speedBoostWasOnBeforeAutoPlay then
        speedBoostWasOnBeforeAutoPlay = false
        startSpeedBoost()
    end
    Notify("AUTO DUEL LEFT OFF")
end

local function StopAutoPlayRight()
    if not State.AutoPlayRight then return end
    State.AutoPlayRight = false
    if aprConn then aprConn:Disconnect(); aprConn = nil end
    aprPhase = 1
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
    if speedBoostWasOnBeforeAutoPlay then
        speedBoostWasOnBeforeAutoPlay = false
        startSpeedBoost()
    end
    Notify("AUTO DUEL RIGHT OFF")
end

local function updateAutoPlayLeft()
    if not State.AutoPlayLeft then
        if aplConn then aplConn:Disconnect(); aplConn = nil end
        return
    end
    local h = getHRP2()
    if not h then return end
    local target = LEFT_ROUTE[aplPhase]
    if not target then aplPhase = 1; return end
    local targetPos = getWP(target)
    if not targetPos then return end
    local spd = (aplPhase <= 2) and SpeedSettings.NormalSpeed or SpeedSettings.StealSpeed
    local reached = MoveToPoint(h, targetPos, spd)
    if reached then
        aplPhase = aplPhase + 1
        if aplPhase > #LEFT_ROUTE then aplPhase = 1 end
    end
end

local function updateAutoPlayRight()
    if not State.AutoPlayRight then
        if aprConn then aprConn:Disconnect(); aprConn = nil end
        return
    end
    local h = getHRP2()
    if not h then return end
    local target = RIGHT_ROUTE[aprPhase]
    if not target then aprPhase = 1; return end
    local targetPos = getWP(target)
    if not targetPos then return end
    local spd = (aprPhase <= 2) and SpeedSettings.NormalSpeed or SpeedSettings.StealSpeed
    local reached = MoveToPoint(h, targetPos, spd)
    if reached then
        aprPhase = aprPhase + 1
        if aprPhase > #RIGHT_ROUTE then aprPhase = 1 end
    end
end

local function StartAutoPlayLeft()
    if State.AutoPlayLeft then return end
    if State.AutoTrack then
        StopTrackToggle()
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
    Notify("AUTO DUEL LEFT ON")
end

local function StartAutoPlayRight()
    if State.AutoPlayRight then return end
    if State.AutoTrack then
        StopTrackToggle()
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
    Notify("AUTO DUEL RIGHT ON")
end

-- ============================================
-- AUTO TP DOWN
-- ============================================
local TPSettings = {
    Enabled = true, TPHeight = 12.5, LastTPTime = 0, TP_COOLDOWN = 0.15,
    SavedLandingX = nil, SavedLandingZ = nil, WasAboveThreshold = false, MonitorConnection = nil,
}

local function getHRPTP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function findEmptySpot(hrp)
    if not hrp then return nil end
    local startX = hrp.Position.X
    local startZ = hrp.Position.Z
    local startY = hrp.Position.Y
    for y = -50, startY + 5, 2 do
        local checkPos = Vector3.new(startX, y, startZ)
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {LP.Character}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(checkPos, Vector3.new(0, 0.5, 0), rayParams)
        if not result then
            return checkPos.Y
        end
    end
    return hrp.Position.Y - 10
end

local function TeleportToGround()
    local hrp = getHRPTP()
    if not hrp then return false end
    local now = tick()
    if now - TPSettings.LastTPTime < TPSettings.TP_COOLDOWN then return false end
    if TPSettings.SavedLandingX == nil or TPSettings.SavedLandingZ == nil then
        TPSettings.SavedLandingX = hrp.Position.X
        TPSettings.SavedLandingZ = hrp.Position.Z
    end
    local safeY = findEmptySpot(hrp)
    if not safeY then return false end
    local targetPos = Vector3.new(TPSettings.SavedLandingX, safeY + 1.5, TPSettings.SavedLandingZ)
    TPSettings.LastTPTime = now
    pcall(function() hrp.CFrame = CFrame.new(targetPos) end)
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
-- SPAM BAT
-- ============================================
local spamBatConn = nil
local lastBatSwing = 0
local BAT_SWING_COOLDOWN = 0.12

local function findBat()
    local char = LP.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and (child.Name:lower():find("bat") or child.Name:lower():find("slap")) then
            return child
        end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, child in ipairs(bp:GetChildren()) do
            if child:IsA("Tool") and (child.Name:lower():find("bat") or child.Name:lower():find("slap")) then
                return child
            end
        end
    end
    return nil
end

local function startSpamBat()
    if spamBatConn then return end
    spamBatConn = RunService.Heartbeat:Connect(function()
        if not State.SpamBat then return end
        local char = LP.Character
        if not char then return end
        local bat = findBat()
        if not bat then return end
        local now = tick()
        if now - lastBatSwing < BAT_SWING_COOLDOWN then return end
        lastBatSwing = now
        pcall(function() bat:Activate() end)
    end)
    Notify("SPAM BAT ON")
end

local function stopSpamBat()
    if spamBatConn then
        spamBatConn:Disconnect()
        spamBatConn = nil
    end
    Notify("SPAM BAT OFF")
end

-- ============================================
-- HIT CIRCLE (AIMBOT + PURPLE CIRCLE)
-- ============================================
local Cebo = {Conn = nil, Circle = nil, Align = nil, Attach = nil}
local hitCircleEnabled = false

local function startHitCircleAimbot()
    if hitCircleEnabled then return end
    hitCircleEnabled = true
    
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    Cebo.Attach = Instance.new("Attachment", hrp)
    Cebo.Align = Instance.new("AlignOrientation", hrp)
    Cebo.Align.Attachment0 = Cebo.Attach
    Cebo.Align.Mode = Enum.OrientationAlignmentMode.OneAttachment
    Cebo.Align.RigidityEnabled = true
    
    Cebo.Circle = Instance.new("Part")
    Cebo.Circle.Shape = Enum.PartType.Cylinder
    Cebo.Circle.Material = Enum.Material.Neon
    Cebo.Circle.Size = Vector3.new(0.05, 14.5, 14.5)
    Cebo.Circle.Color = Color3.fromRGB(160, 100, 255)
    Cebo.Circle.CanCollide = false
    Cebo.Circle.Massless = true
    Cebo.Circle.Parent = workspace
    
    local weld = Instance.new("Weld")
    weld.Part0 = hrp
    weld.Part1 = Cebo.Circle
    weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(90))
    weld.Parent = Cebo.Circle
    
    Cebo.Conn = RunService.RenderStepped:Connect(function()
        if not State.HitCircle then return end
        
        local c = LP.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        
        local target, dmin = nil, 7.25
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local enemyHrp = p.Character.HumanoidRootPart
                local enemyHum = p.Character:FindFirstChildOfClass("Humanoid")
                if enemyHum and enemyHum.Health > 0 then
                    local d = (enemyHrp.Position - h.Position).Magnitude
                    if d <= dmin then
                        target = enemyHrp
                        dmin = d
                    end
                end
            end
        end
        
        if target then
            hum.AutoRotate = false
            Cebo.Align.Enabled = true
            Cebo.Align.CFrame = CFrame.lookAt(h.Position, Vector3.new(target.Position.X, h.Position.Y, target.Position.Z))
            
            local bat = c:FindFirstChild("Bat") or c:FindFirstChild("Medusa")
            if bat then
                pcall(function() bat:Activate() end)
            end
        else
            Cebo.Align.Enabled = false
            hum.AutoRotate = true
        end
    end)
    
    Notify("HIT CIRCLE AIMBOT ON")
end

local function stopHitCircleAimbot()
    if not hitCircleEnabled then return end
    hitCircleEnabled = false
    State.HitCircle = false
    
    if Cebo.Conn then
        Cebo.Conn:Disconnect()
        Cebo.Conn = nil
    end
    if Cebo.Circle then
        Cebo.Circle:Destroy()
        Cebo.Circle = nil
    end
    if Cebo.Align then
        Cebo.Align:Destroy()
        Cebo.Align = nil
    end
    if Cebo.Attach then
        Cebo.Attach:Destroy()
        Cebo.Attach = nil
    end
    
    local char = LP.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.AutoRotate = true
    end
    
    Notify("HIT CIRCLE AIMBOT OFF")
end

local function StartHitCircle()
    if State.HitCircle then return end
    State.HitCircle = true
    startHitCircleAimbot()
end

local function StopHitCircle()
    if not State.HitCircle then return end
    State.HitCircle = false
    stopHitCircleAimbot()
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
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.CastShadow = false
            end
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
    end)
    Notify("OPTIMIZER OFF")
end

-- ============================================
-- UNWALK
-- ============================================
local unwalkActive = false
local animatorConnection = nil

local function stopAnimationsOnly(model)
    if not model then return end
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChild("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop()
            end
        end
    end
end

local function startUnwalk()
    if unwalkActive then return end
    if animatorConnection then animatorConnection:Disconnect() end
    animatorConnection = RunService.RenderStepped:Connect(function()
        if not unwalkActive then return end
        local char = LP.Character
        if char then stopAnimationsOnly(char) end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                stopAnimationsOnly(player.Character)
            end
        end
    end)
    unwalkActive = true
    Notify("UNWALK ON")
end

local function stopUnwalk()
    if not unwalkActive then return end
    if animatorConnection then
        animatorConnection:Disconnect()
        animatorConnection = nil
    end
    unwalkActive = false
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

-- ============================================
-- ANTI RAGDOLL
-- ============================================
local antiRagdollConn = nil
local antiRagdollRecoveryActive = false
local antiRagdollRecoveryTimer = nil

local function forceRecoverFromRagdoll(hum, root)
    if not hum or not root then return end
    if antiRagdollRecoveryTimer then
        task.cancel(antiRagdollRecoveryTimer)
        antiRagdollRecoveryTimer = nil
    end
    antiRagdollRecoveryActive = true
    local char = hum.Parent
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and obj.Enabled == false then
                obj.Enabled = true
            end
        end
    end
    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
    root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)
    antiRagdollRecoveryTimer = task.delay(0.3, function()
        antiRagdollRecoveryActive = false
        antiRagdollRecoveryTimer = nil
    end)
end

local function StartAntiRagdoll()
    if State.AntiRagdoll then return end
    State.AntiRagdoll = true
    if antiRagdollConn then antiRagdollConn:Disconnect() end
    antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not State.AntiRagdoll then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end
        if hum.Health <= 0 then return end
        if antiRagdollRecoveryActive then return end
        local state = hum:GetState()
        local isRagdolled = (state == Enum.HumanoidStateType.Physics or 
                             state == Enum.HumanoidStateType.Ragdoll or 
                             state == Enum.HumanoidStateType.FallingDown)
        if isRagdolled then
            forceRecoverFromRagdoll(hum, root)
        end
    end)
    Notify("ANTI RAGDOLL ON")
end

local function StopAntiRagdoll()
    if not State.AntiRagdoll then return end
    State.AntiRagdoll = false
    if antiRagdollConn then
        antiRagdollConn:Disconnect()
        antiRagdollConn = nil
    end
    antiRagdollRecoveryActive = false
    if antiRagdollRecoveryTimer then
        task.cancel(antiRagdollRecoveryTimer)
        antiRagdollRecoveryTimer = nil
    end
    Notify("ANTI RAGDOLL OFF")
end

-- ============================================
-- INFINITE JUMP
-- ============================================
local jumpConn = nil
local function StartInfiniteJump()
    if State.InfiniteJump then return end
    State.InfiniteJump = true
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    jumpConn = UIS.JumpRequest:Connect(function()
        if not State.InfiniteJump or not HRP or not Hum then return end
        if Hum:GetState() == Enum.HumanoidStateType.Dead then return end
        local v = HRP.AssemblyLinearVelocity
        HRP.AssemblyLinearVelocity = Vector3.new(v.X, 50, v.Z)
    end)
    Notify("INFINITE JUMP ON")
end

local function StopInfiniteJump()
    State.InfiniteJump = false
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    Notify("INFINITE JUMP OFF")
end

-- ============================================
-- ANTI DIE
-- ============================================
local antiDieConn = nil
local function startPermanentAntiDie()
    if antiDieConn then antiDieConn:Disconnect() end
    antiDieConn = RunService.Heartbeat:Connect(function()
        if not Hum or not Hum.Parent then return end
        if Hum.Health <= 0 then pcall(function() Hum.Health = Hum.MaxHealth * 0.9 end) end
        pcall(function() Hum.RequiresNeck = false end)
        if HRP and HRP.Position.Y < -10 then HRP.CFrame = CFrame.new(HRP.Position.X, -4, HRP.Position.Z) end
    end)
end
task.spawn(function() task.wait(0.5); startPermanentAntiDie() end)

-- ============================================
-- XRAY BASE
-- ============================================
local baseOT = {}; local plotConns = {}; local xrayCon = nil
local XRAY_TRANSPARENCY = 0.68

local function applyXray(plot)
    if baseOT[plot] then return end; baseOT[plot] = {}
    for _, p in ipairs(plot:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 0.6 then
            baseOT[plot][p] = p.Transparency
            p.Transparency = XRAY_TRANSPARENCY
        end
    end
    plotConns[plot] = plot.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") and d.Transparency < 0.6 then
            baseOT[plot][d] = d.Transparency
            d.Transparency = XRAY_TRANSPARENCY
        end
    end)
end

local function StartXrayBase()
    if State.XrayBase then return end
    State.XrayBase = true
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do applyXray(plot) end
    xrayCon = plots.ChildAdded:Connect(function(p) task.wait(0.2); applyXray(p) end)
    Notify("XRAY BASE ON")
end

local function StopXrayBase()
    if not State.XrayBase then return end
    State.XrayBase = false
    for _, conn in pairs(plotConns) do conn:Disconnect() end
    plotConns = {}
    if xrayCon then xrayCon:Disconnect(); xrayCon = nil end
    for _, parts in pairs(baseOT) do
        for part, orig in pairs(parts) do
            if part and part.Parent then part.Transparency = orig end
        end
    end
    baseOT = {}
    Notify("XRAY BASE OFF")
end

-- ============================================
-- ESP
-- ============================================
local espHL = {}
local function ClearESP() for _, h in pairs(espHL) do if h and h.Parent then h:Destroy() end end; espHL = {} end

local function StartESP()
    if State.ESP then return end
    State.ESP = true
    Notify("ESP ON")
end

local function StopESP()
    if not State.ESP then return end
    State.ESP = false
    ClearESP()
    Notify("ESP OFF")
end

local function updateESP()
    if not State.ESP then return end
    for player, h in pairs(espHL) do
        if not player or not player.Character then
            if h and h.Parent then h:Destroy() end
            espHL[player] = nil
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and (not espHL[p] or not espHL[p].Parent) then
            local h = Instance.new("Highlight")
            h.FillColor = Colors.DarkGray
            h.OutlineColor = Colors.White
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.Adornee = p.Character
            h.Parent = p.Character
            espHL[p] = h
        end
    end
end

-- ============================================
-- ANTI SENTRY
-- ============================================
local antiSentryTarget = nil
local DETECTION_DISTANCE = 60
local PULL_DISTANCE = -5

local function findSentryTarget()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPos = char.HumanoidRootPart.Position
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:find("Sentry") and not obj.Name:lower():find("bullet") then
            local part = (obj:IsA("BasePart") and obj) or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
            if part and (rootPos - part.Position).Magnitude <= DETECTION_DISTANCE then
                return obj
            end
        end
    end
end

local function moveSentry(obj)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, p in pairs(obj:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
    local root = char.HumanoidRootPart
    local cf = root.CFrame * CFrame.new(0, 0, PULL_DISTANCE)
    if obj:IsA("BasePart") then
        obj.CFrame = cf
    elseif obj:IsA("Model") then
        local m = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if m then m.CFrame = cf end
    end
end

local function getWeapon()
    return LP.Backpack:FindFirstChild("Bat") or (LP.Character and LP.Character:FindFirstChild("Bat"))
end

local function attackSentry()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local weapon = getWeapon()
    if not weapon then return end
    if weapon.Parent == LP.Backpack then
        hum:EquipTool(weapon)
        task.wait(0.1)
    end
    pcall(function() weapon:Activate() end)
end

local function StartAntiSentry()
    if State.AntiSentry then return end
    State.AntiSentry = true
    Notify("ANTI SENTRY ON")
end

local function StopAntiSentry()
    if not State.AntiSentry then return end
    State.AntiSentry = false
    antiSentryTarget = nil
    Notify("ANTI SENTRY OFF")
end

local function updateAntiSentry()
    if not State.AntiSentry then return end
    if antiSentryTarget and antiSentryTarget.Parent == workspace then
        moveSentry(antiSentryTarget)
        attackSentry()
    else
        antiSentryTarget = findSentryTarget()
    end
end

-- ============================================
-- SPIN BODY
-- ============================================
local spinForce = nil
local SPIN_SPEED = 25

local function StartSpinBody()
    if State.SpinBody then return end
    State.SpinBody = true
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or spinForce then return end
    spinForce = Instance.new("BodyAngularVelocity")
    spinForce.Name = "SpinForce"
    spinForce.AngularVelocity = Vector3.new(0, SPIN_SPEED, 0)
    spinForce.MaxTorque = Vector3.new(0, math.huge, 0)
    spinForce.P = 1250
    spinForce.Parent = root
    Notify("SPIN BODY ON")
end

local function StopSpinBody()
    if not State.SpinBody then return end
    State.SpinBody = false
    if spinForce then spinForce:Destroy(); spinForce = nil end
    Notify("SPIN BODY OFF")
end

-- ============================================
-- DAMAGE TRACKING
-- ============================================
local damageConn = nil
local damageCooldown = false
local lastHealth = nil
local damageCooldownTimer = nil
local DAMAGE_COOLDOWN = 2.8

local function stopFeaturesOnDamage()
    if damageCooldown then return end
    damageCooldown = true
    
    if State.AutoPlayLeft then StopAutoPlayLeft() end
    if State.AutoPlayRight then StopAutoPlayRight() end
    if State.FloatEnabled then stopFloat() end
    
    if damageCooldownTimer then
        pcall(function() task.cancel(damageCooldownTimer) end)
        damageCooldownTimer = nil
    end
    damageCooldownTimer = task.delay(DAMAGE_COOLDOWN, function()
        damageCooldown = false
        damageCooldownTimer = nil
    end)
end

local function setupDamageTracking()
    if damageConn then damageConn:Disconnect(); damageConn = nil end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    lastHealth = hum.Health
    damageConn = RunService.Heartbeat:Connect(function()
        if not LP.Character or not hum or hum.Parent ~= LP.Character then
            if damageConn then damageConn:Disconnect(); damageConn = nil end
            return
        end
        local currentHealth = hum.Health
        if lastHealth and currentHealth < lastHealth - 0.5 and hum.Health > 0 then
            if not damageCooldown then
                stopFeaturesOnDamage()
            end
        end
        if currentHealth > 0 then lastHealth = currentHealth end
    end)
end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    damageCooldown = false
    lastHealth = nil
    if damageCooldownTimer then
        pcall(function() task.cancel(damageCooldownTimer) end)
        damageCooldownTimer = nil
    end
    setupDamageTracking()
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if unwalkActive then
        stopAnimationsOnly(char)
    end
end)

-- ============================================
-- KEYBINDS
-- ============================================
local Keys = {
    InfJump = Enum.KeyCode.J, AutoPlayLeft = Enum.KeyCode.G, AutoPlayRight = Enum.KeyCode.H,
    AntiRagdoll = Enum.KeyCode.K, Float = Enum.KeyCode.F, SpeedBoost = Enum.KeyCode.B,
    Unwalk = Enum.KeyCode.U, AutoTPDown = Enum.KeyCode.T,
}
local KeyEnabled = {
    InfJump = true, AutoPlayLeft = true, AutoPlayRight = true, AntiRagdoll = true,
    Float = true, SpeedBoost = true, Unwalk = true, AutoTPDown = true,
}

UIS.InputBegan:Connect(function(input, gpe)
    if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode
    if KeyEnabled.InfJump and k == Keys.InfJump then
        if State.InfiniteJump then StopInfiniteJump() else StartInfiniteJump() end
    elseif KeyEnabled.AutoPlayLeft and k == Keys.AutoPlayLeft then
        if State.AutoPlayLeft then StopAutoPlayLeft() else StartAutoPlayLeft() end
    elseif KeyEnabled.AutoPlayRight and k == Keys.AutoPlayRight then
        if State.AutoPlayRight then StopAutoPlayRight() else StartAutoPlayRight() end
    elseif KeyEnabled.AntiRagdoll and k == Keys.AntiRagdoll then
        if State.AntiRagdoll then StopAntiRagdoll() else StartAntiRagdoll() end
    elseif KeyEnabled.Float and k == Keys.Float then
        if State.FloatEnabled then stopFloat() else startFloat() end
    elseif KeyEnabled.SpeedBoost and k == Keys.SpeedBoost then
        if isSpeedBoostEnabled then stopSpeedBoost() else startSpeedBoost() end
    elseif KeyEnabled.Unwalk and k == Keys.Unwalk then
        if unwalkActive then stopUnwalk() else startUnwalk() end
    elseif KeyEnabled.AutoTPDown and k == Keys.AutoTPDown then
        if State.AutoTrack then
            Notify("Cannot toggle AUTO TP DOWN while AUTO TRACK is active")
            return
        end
        TPSettings.Enabled = not TPSettings.Enabled
        if TPSettings.Enabled then StartTPMonitoring() else StopTPMonitoring() end
        Notify(TPSettings.Enabled and "AUTO TP DOWN ON" or "AUTO TP DOWN OFF")
    end
end)

-- ============================================
-- DISCORD TAG
-- ============================================
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
    billboard.Size = UDim2.new(0, 260, 0, 32)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char
    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Colors.VeryDark
    frame.BackgroundTransparency = 0.15
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Colors.MediumGray
    stroke.Thickness = 1.5
    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = discordLink
    text.TextColor3 = Colors.DiscordBlue
    text.Font = Enum.Font.GothamBold
    text.TextSize = 14
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0)
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
local menuW, menuH = 350, 350
local StealBarVisible = true
local ButtonPositions = {}
local sideHiddenMap = {}
local menu = nil
local numberBoxReferences = {}
local toggleUpdaters = {}

local CFG = "H2N_Config.json"

local function Save()
    local menuPos = { X = 0.5, XO = 0, Y = 0.52, YO = 0 }
    if menu then
        menuPos = {
            X = menu.Position.X.Scale, XO = menu.Position.X.Offset,
            Y = menu.Position.Y.Scale, YO = menu.Position.Y.Offset,
        }
    end
    local data = {
        SideButtonSize = SideButtonSize, menuW = menuW, menuH = menuH, menuPos = menuPos,
        NormalSpeed = SpeedSettings.NormalSpeed, StealSpeed = SpeedSettings.StealSpeed,
        EnhancedGrab = { Radius = EnhancedGrab.Radius, Delay = EnhancedGrab.Delay, Enabled = EnhancedGrab.Enabled },
        TrackSettings = { Enabled = State.AutoTrack, TrackSpeed = TrackSettings.TrackSpeed, LockSpeed = TrackSettings.LockSpeed, ForwardOffset = TrackSettings.ForwardOffset },
        Keys = {
            InfJump = Keys.InfJump.Name, AutoPlayLeft = Keys.AutoPlayLeft.Name,
            AutoPlayRight = Keys.AutoPlayRight.Name, AntiRagdoll = Keys.AntiRagdoll.Name,
            Float = Keys.Float.Name, SpeedBoost = Keys.SpeedBoost.Name,
            Unwalk = Keys.Unwalk.Name, AutoTPDown = Keys.AutoTPDown.Name,
        },
        KeyEnabled = {
            InfJump = KeyEnabled.InfJump, AutoPlayLeft = KeyEnabled.AutoPlayLeft,
            AutoPlayRight = KeyEnabled.AutoPlayRight, AntiRagdoll = KeyEnabled.AntiRagdoll,
            Float = KeyEnabled.Float, SpeedBoost = KeyEnabled.SpeedBoost,
            Unwalk = KeyEnabled.Unwalk, AutoTPDown = KeyEnabled.AutoTPDown,
        },
        ST_AntiSentry = State.AntiSentry, ST_SpinBody = State.SpinBody,
        ST_AntiRagdoll = State.AntiRagdoll, ST_InfiniteJump = State.InfiniteJump,
        ST_FloatEnabled = State.FloatEnabled, ST_XrayBase = State.XrayBase,
        ST_ESP = State.ESP, ST_SpeedBoost = isSpeedBoostEnabled,
        ST_SpamBat = State.SpamBat, ST_HitCircle = State.HitCircle, ST_Optimizer = State.Optimizer,
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
    if d.menuW then menuW = d.menuW end
    if d.menuH then menuH = d.menuH end
    if d.NormalSpeed then SpeedSettings.NormalSpeed = d.NormalSpeed end
    if d.StealSpeed then SpeedSettings.StealSpeed = d.StealSpeed end
    if d.EnhancedGrab then
        if d.EnhancedGrab.Radius then EnhancedGrab.Radius = math.clamp(d.EnhancedGrab.Radius, 1, 100) end
        if d.EnhancedGrab.Delay then EnhancedGrab.Delay = math.max(d.EnhancedGrab.Delay, 0.05) end
        if d.EnhancedGrab.Enabled ~= nil then EnhancedGrab.Enabled = d.EnhancedGrab.Enabled end
    end
    if d.TrackSettings then
        if d.TrackSettings.Enabled ~= nil then State.AutoTrack = d.TrackSettings.Enabled end
        if d.TrackSettings.TrackSpeed then TrackSettings.TrackSpeed = math.clamp(d.TrackSettings.TrackSpeed, 1, 300) end
        if d.TrackSettings.LockSpeed then TrackSettings.LockSpeed = math.clamp(d.TrackSettings.LockSpeed, 1, 300) end
        if d.TrackSettings.ForwardOffset then TrackSettings.ForwardOffset = d.TrackSettings.ForwardOffset end
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
    if d.ST_SpamBat ~= nil then State.SpamBat = d.ST_SpamBat end
    if d.ST_HitCircle ~= nil then State.HitCircle = d.ST_HitCircle end
    if d.ST_Optimizer ~= nil then State.Optimizer = d.ST_Optimizer end
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
    task.defer(function()
        for id, boxRef in pairs(numberBoxReferences) do
            if boxRef and boxRef.TextBox then
                if id == "GrabRadius" then boxRef.TextBox.Text = tostring(EnhancedGrab.Radius)
                elseif id == "GrabDelay" then boxRef.TextBox.Text = string.format("%.2f", EnhancedGrab.Delay)
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
        if grabBarRef.rateLbl then grabBarRef.rateLbl.Text = string.format("%.2f", EnhancedGrab.Delay).."s" end
    end)
end

-- ============================================
-- STEAL BAR
-- ============================================
stealBarFrame = Instance.new("Frame", gui)
stealBarFrame.Name = "StealBar"
stealBarFrame.Size = UDim2.new(0, 340, 0, 36)
stealBarFrame.Position = UDim2.new(0.5, -170, 1, -55)
stealBarFrame.BackgroundColor3 = Colors.White
stealBarFrame.BackgroundTransparency = 0.15
stealBarFrame.ZIndex = 50
stealBarFrame.Visible = StealBarVisible
stealBarFrame.Active = true
Instance.new("UICorner", stealBarFrame).CornerRadius = UDim.new(0, 10)
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

local sbLabel = Instance.new("TextLabel", stealBarFrame)
sbLabel.Size = UDim2.new(0, 48, 1, 0)
sbLabel.BackgroundTransparency = 1
sbLabel.Text = "GRAB"
sbLabel.TextColor3 = Colors.DarkGray
sbLabel.Font = Enum.Font.GothamBold
sbLabel.TextSize = 12
sbLabel.ZIndex = 51

local sbBG = Instance.new("Frame", stealBarFrame)
sbBG.Size = UDim2.new(1, -160, 0, 14)
sbBG.Position = UDim2.new(0, 48, 0.5, -7)
sbBG.BackgroundColor3 = Colors.AlmostBlack
sbBG.ZIndex = 51
Instance.new("UICorner", sbBG).CornerRadius = UDim.new(0, 6)

sbFill = Instance.new("Frame", sbBG)
sbFill.Size = UDim2.new(0, 0, 1, 0)
sbFill.BackgroundColor3 = Colors.DarkGray
sbFill.ZIndex = 52
Instance.new("UICorner", sbFill).CornerRadius = UDim.new(0, 6)

local sbPct = Instance.new("TextLabel", stealBarFrame)
sbPct.Size = UDim2.new(0, 34, 1, 0)
sbPct.Position = UDim2.new(1, -110, 0, 0)
sbPct.BackgroundTransparency = 1
sbPct.Text = "0%"
sbPct.TextColor3 = Colors.Text
sbPct.Font = Enum.Font.GothamBold
sbPct.TextSize = 11
sbPct.ZIndex = 51

local sbRadius = Instance.new("TextLabel", stealBarFrame)
sbRadius.Size = UDim2.new(0, 38, 1, 0)
sbRadius.Position = UDim2.new(1, -76, 0, 0)
sbRadius.BackgroundTransparency = 1
sbRadius.Text = EnhancedGrab.Radius.."st"
sbRadius.TextColor3 = Colors.MediumGray
sbRadius.Font = Enum.Font.GothamBold
sbRadius.TextSize = 11
sbRadius.ZIndex = 51

local sbRate = Instance.new("TextLabel", stealBarFrame)
sbRate.Size = UDim2.new(0, 50, 1, 0)
sbRate.Position = UDim2.new(1, -50, 0, 0)
sbRate.BackgroundTransparency = 1
sbRate.Text = string.format("%.2f", EnhancedGrab.Delay).."s"
sbRate.TextColor3 = Colors.MediumGray
sbRate.Font = Enum.Font.GothamBold
sbRate.TextSize = 10
sbRate.ZIndex = 51

grabBarRef = { fill = sbFill, pct = sbPct, radiusLbl = sbRadius, rateLbl = sbRate }

-- ============================================
-- MENU BUTTON
-- ============================================
local menuBtn = Instance.new("Frame", gui)
menuBtn.Size = UDim2.new(0, 110, 0, 44)
menuBtn.Position = UDim2.new(0.5, -55, 0.07, 0)
menuBtn.BackgroundColor3 = Color3.fromRGB(60, 38, 170)
menuBtn.BackgroundTransparency = 0
menuBtn.Active = true
menuBtn.ZIndex = 60
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0, 12)
local mbStroke = Instance.new("UIStroke", menuBtn)
mbStroke.Color = Color3.fromRGB(130, 100, 255)
mbStroke.Thickness = 1.5

local menuBtnLabel = Instance.new("TextLabel", menuBtn)
menuBtnLabel.Size = UDim2.new(1, 0, 1, 0)
menuBtnLabel.BackgroundTransparency = 1
menuBtnLabel.Text = "H2N"
menuBtnLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
menuBtnLabel.Font = Enum.Font.GothamBold
menuBtnLabel.TextSize = 18
menuBtnLabel.ZIndex = 61

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

-- ============================================
-- MAIN MENU
-- ============================================
menu = Instance.new("Frame", gui)
menu.Size = UDim2.new(0, menuW, 0, menuH)
menu.Position = UDim2.new(0.5, -menuW/2, 0.5, -menuH/2)
menu.AnchorPoint = Vector2.new(0, 0)
menu.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
menu.BackgroundTransparency = 0
menu.Visible = false
menu.Active = true
menu.ZIndex = 55
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 14)
local menuStroke = Instance.new("UIStroke", menu)
menuStroke.Color = Color3.fromRGB(100, 70, 230)
menuStroke.Thickness = 1.5

local header = Instance.new("Frame", menu)
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(70, 45, 190)
header.BackgroundTransparency = 0
header.BorderSizePixel = 0
header.ZIndex = 56
local hCorner = Instance.new("UICorner", header)
hCorner.CornerRadius = UDim.new(0, 14)
local hFix = Instance.new("Frame", header)
hFix.Size = UDim2.new(1, 0, 0.5, 0)
hFix.Position = UDim2.new(0, 0, 0.5, 0)
hFix.BackgroundColor3 = Color3.fromRGB(70, 45, 190)
hFix.BorderSizePixel = 0
hFix.ZIndex = 56

local accentLine = Instance.new("Frame", menu)
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 0, 42)
accentLine.BackgroundColor3 = Color3.fromRGB(130, 100, 255)
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 57

local tl = Instance.new("TextLabel", header)
tl.Size = UDim2.new(1, -20, 1, 0)
tl.Position = UDim2.new(0, 14, 0, 0)
tl.BackgroundTransparency = 1
tl.Text = "H2N ULTIMATE"
tl.TextColor3 = Color3.fromRGB(255, 255, 255)
tl.Font = Enum.Font.GothamBold
tl.TextSize = 17
tl.TextXAlignment = Enum.TextXAlignment.Left
tl.ZIndex = 57

local verLbl = Instance.new("TextLabel", header)
verLbl.Size = UDim2.new(0, 60, 1, 0)
verLbl.Position = UDim2.new(1, -70, 0, 0)
verLbl.BackgroundTransparency = 1
verLbl.Text = "v7.0"
verLbl.TextColor3 = Color3.fromRGB(200, 180, 255)
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
tabBar.Size = UDim2.new(0, 108, 1, -48)
tabBar.Position = UDim2.new(0, 6, 0, 48)
tabBar.BackgroundColor3 = Color3.fromRGB(16, 14, 26)
tabBar.BackgroundTransparency = 0
tabBar.ZIndex = 56
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)
local tbStroke = Instance.new("UIStroke", tabBar)
tbStroke.Color = Color3.fromRGB(60, 45, 110)
tbStroke.Thickness = 1

local tabNames = { "Combat", "Protect", "Visual", "Settings" }
local tabFrames = {}
local tabBtns = {}

for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton", tabBar)
    tb.Size = UDim2.new(1, -12, 0, 38)
    tb.Position = UDim2.new(0, 6, 0, (i - 1) * 44 + 8)
    tb.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
    tb.Text = name
    tb.TextColor3 = Color3.fromRGB(160, 145, 210)
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 13
    tb.ZIndex = 57
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.AutoButtonColor = false
    local tbCorner = Instance.new("UICorner", tb)
    tbCorner.CornerRadius = UDim.new(0, 8)
    local tbStk = Instance.new("UIStroke", tb)
    tbStk.Color = Color3.fromRGB(50, 40, 90)
    tbStk.Thickness = 1
    local pad = Instance.new("UIPadding", tb)
    pad.PaddingLeft = UDim.new(0, 8)
    tabBtns[name] = tb
    local sf = Instance.new("ScrollingFrame", menu)
    sf.Size = UDim2.new(1, -124, 1, -50)
    sf.Position = UDim2.new(0, 118, 0, 48)
    sf.BackgroundTransparency = 1
    sf.Visible = (i == 1)
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(100, 80, 200)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ZIndex = 57
    tabFrames[name] = sf
    tb.MouseButton1Click:Connect(function()
        for _, f in pairs(tabFrames) do f.Visible = false end
        for _, b in pairs(tabBtns) do
            b.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
            b.TextColor3 = Color3.fromRGB(160, 145, 210)
        end
        sf.Visible = true
        tb.BackgroundColor3 = Color3.fromRGB(70, 45, 190)
        tb.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end
tabBtns["Combat"].BackgroundColor3 = Color3.fromRGB(70, 45, 190)
tabBtns["Combat"].TextColor3 = Color3.fromRGB(255, 255, 255)

-- ============================================
-- UI ELEMENTS
-- ============================================
local function MakeToggle(parent, text, order, cb, getState, featureName)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, order * 44 + 4)
    row.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
    row.BackgroundTransparency = 0
    row.ZIndex = 58
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = Color3.fromRGB(45, 38, 80)
    rowStroke.Thickness = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.58, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 200, 240)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0, 70, 0, 26)
    btn.Position = UDim2.new(1, -78, 0.5, -13)
    btn.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
    btn.BackgroundTransparency = 0
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(130, 120, 170)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local btnStk = Instance.new("UIStroke", btn)
    btnStk.Color = Color3.fromRGB(60, 50, 100)
    btnStk.Thickness = 1
    local function UpdateButton()
        if getState() then
            btn.Text = "ON"
            btn.BackgroundColor3 = Color3.fromRGB(70, 45, 190)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btnStk.Color = Color3.fromRGB(130, 100, 255)
            rowStroke.Color = Color3.fromRGB(80, 55, 180)
        else
            btn.Text = "OFF"
            btn.BackgroundColor3 = Color3.fromRGB(35, 30, 55)
            btn.TextColor3 = Color3.fromRGB(130, 120, 170)
            btnStk.Color = Color3.fromRGB(60, 50, 100)
            rowStroke.Color = Color3.fromRGB(45, 38, 80)
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
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, order * 44 + 4)
    row.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
    row.BackgroundTransparency = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local rowStk = Instance.new("UIStroke", row)
    rowStk.Color = Color3.fromRGB(45, 38, 80)
    rowStk.Thickness = 1
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 200, 240)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0, 70, 0, 26)
    box.Position = UDim2.new(1, -78, 0.5, -13)
    box.BackgroundColor3 = Color3.fromRGB(28, 24, 45)
    box.BackgroundTransparency = 0
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(200, 185, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 15
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
    Instance.new("UIStroke", box).Color = Color3.fromRGB(80, 60, 160)
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
    row.Size = UDim2.new(1, -10, 0, 40)
    row.Position = UDim2.new(0, 5, 0, order * 44 + 4)
    row.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
    row.BackgroundTransparency = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", row).Color = Color3.fromRGB(45, 38, 80)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.46, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(210, 200, 240)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size = UDim2.new(0, 52, 0, 26)
    keyBtn.Position = UDim2.new(0.47, 0, 0.5, -13)
    keyBtn.BackgroundColor3 = Color3.fromRGB(28, 24, 45)
    keyBtn.BackgroundTransparency = 0
    keyBtn.Text = Keys[keyName] and Keys[keyName].Name or "?"
    keyBtn.TextColor3 = Color3.fromRGB(200, 185, 255)
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 11
    keyBtn.AutoButtonColor = false
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 7)
    Instance.new("UIStroke", keyBtn).Color = Color3.fromRGB(80, 60, 160)
    local enableBtn = Instance.new("TextButton", row)
    enableBtn.Size = UDim2.new(0, 52, 0, 26)
    enableBtn.Position = UDim2.new(1, -60, 0.5, -13)
    enableBtn.BackgroundColor3 = KeyEnabled[keyName] and Color3.fromRGB(40, 160, 100) or Color3.fromRGB(160, 40, 40)
    enableBtn.Text = KeyEnabled[keyName] and "ON" or "OFF"
    enableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    enableBtn.Font = Enum.Font.GothamBold
    enableBtn.TextSize = 11
    enableBtn.AutoButtonColor = false
    Instance.new("UICorner", enableBtn).CornerRadius = UDim.new(0, 7)
    local listening = false
    local listenConn
    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
        if listenConn then listenConn:Disconnect() end
        listenConn = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Keys[keyName] = input.KeyCode
                keyBtn.Text = input.KeyCode.Name
                keyBtn.BackgroundColor3 = Color3.fromRGB(28, 24, 45)
                listening = false
                listenConn:Disconnect()
                Notify("Key " .. labelText .. " = " .. input.KeyCode.Name)
                Save()
            end
        end)
    end)
    enableBtn.MouseButton1Click:Connect(function()
        KeyEnabled[keyName] = not KeyEnabled[keyName]
        enableBtn.Text = KeyEnabled[keyName] and "ON" or "OFF"
        enableBtn.BackgroundColor3 = KeyEnabled[keyName] and Color3.fromRGB(40, 160, 100) or Color3.fromRGB(160, 40, 40)
        Save()
    end)
end

-- ============================================
-- COMBAT TAB
-- ============================================
local ci = 0
local combat = tabFrames["Combat"]

MakeToggle(combat, "AUTO GRAB", ci, function(s)
    if s then StartEnhancedGrab() else StopEnhancedGrab() end
end, function() return EnhancedGrab.Enabled end, "AutoGrab")
ci = ci + 1

MakeNumberBox(combat, "Grab Range", EnhancedGrab.Radius, ci, function(v)
    EnhancedGrab.Radius = math.clamp(v, 1, 100)
    if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = EnhancedGrab.Radius .. "st" end
    Notify("Grab Range = " .. EnhancedGrab.Radius)
end, 1, 100, "GrabRadius")
ci = ci + 1

MakeNumberBox(combat, "Grab Speed", EnhancedGrab.Delay, ci, function(v)
    EnhancedGrab.Delay = math.max(v, 0.05)
    if grabBarRef.rateLbl then grabBarRef.rateLbl.Text = string.format("%.2f", EnhancedGrab.Delay) .. "s" end
    Notify("Grab Speed = " .. string.format("%.2f", EnhancedGrab.Delay))
end, 0.05, 3.0, "GrabDelay")
ci = ci + 1

MakeToggle(combat, "AUTO TRACK", ci, function(s)
    if s then StartTrackToggle() else StopTrackToggle() end
end, function() return State.AutoTrack end, "AutoTrack")
ci = ci + 1

MakeNumberBox(combat, "Track Speed", TrackSettings.TrackSpeed, ci, function(v)
    TrackSettings.TrackSpeed = math.clamp(v, 1, 300)
    Notify("Track Speed = " .. TrackSettings.TrackSpeed)
end, 1, 300, "TrackSpeed")
ci = ci + 1

MakeToggle(combat, "SPAM BAT", ci, function(s)
    if s then startSpamBat() else stopSpamBat() end
    State.SpamBat = s
end, function() return State.SpamBat end, "SpamBat")
ci = ci + 1

MakeToggle(combat, "AUTO PLAY LEFT", ci, function(s)
    if s then StartAutoPlayLeft() else StopAutoPlayLeft() end
end, function() return State.AutoPlayLeft end, "AutoPlayLeft")
ci = ci + 1

MakeToggle(combat, "AUTO PLAY RIGHT", ci, function(s)
    if s then StartAutoPlayRight() else StopAutoPlayRight() end
end, function() return State.AutoPlayRight end, "AutoPlayRight")
ci = ci + 1

MakeToggle(combat, "ANTI SENTRY", ci, function(s)
    if s then StartAntiSentry() else StopAntiSentry() end
end, function() return State.AntiSentry end, "AntiSentry")
ci = ci + 1

MakeToggle(combat, "SPIN BODY", ci, function(s)
    if s then StartSpinBody() else StopSpinBody() end
end, function() return State.SpinBody end, "SpinBody")
ci = ci + 1

MakeToggle(combat, "SPEED BOOST", ci, function(s)
    if s then startSpeedBoost() else stopSpeedBoost() end
end, function() return isSpeedBoostEnabled end, "SpeedBoost")
ci = ci + 1

MakeNumberBox(combat, "Normal Speed", SpeedSettings.NormalSpeed, ci, function(v)
    SpeedSettings.NormalSpeed = math.clamp(v, 1, 200)
    Notify("Normal Speed = " .. SpeedSettings.NormalSpeed)
end, 1, 200, "NormalSpeed")
ci = ci + 1

MakeNumberBox(combat, "Steal Speed", SpeedSettings.StealSpeed, ci, function(v)
    SpeedSettings.StealSpeed = math.clamp(v, 1, 200)
    Notify("Steal Speed = " .. SpeedSettings.StealSpeed)
end, 1, 200, "StealSpeed")
ci = ci + 1

-- ============================================
-- PROTECT TAB
-- ============================================
local pi = 0
local protect = tabFrames["Protect"]

MakeToggle(protect, "ANTI RAGDOLL", pi, function(s)
    if s then StartAntiRagdoll() else StopAntiRagdoll() end
end, function() return State.AntiRagdoll end, "AntiRagdoll")
pi = pi + 1

MakeToggle(protect, "INFINITE JUMP", pi, function(s)
    if s then StartInfiniteJump() else StopInfiniteJump() end
end, function() return State.InfiniteJump end, "InfiniteJump")
pi = pi + 1

MakeToggle(protect, "FLOAT", pi, function(s)
    if s then startFloat() else stopFloat() end
end, function() return State.FloatEnabled end, "FloatEnabled")
pi = pi + 1

MakeToggle(protect, "UNWALK", pi, function(s)
    if s then startUnwalk() else stopUnwalk() end
end, function() return unwalkActive end, "Unwalk")
pi = pi + 1

MakeToggle(protect, "AUTO TP DOWN", pi, function(s)
    if State.AutoTrack then
        Notify("Cannot enable AUTO TP DOWN while AUTO TRACK is active")
        return
    end
    TPSettings.Enabled = s
    if s then StartTPMonitoring() else StopTPMonitoring() end
    Notify(s and "AUTO TP DOWN ON" or "AUTO TP DOWN OFF")
end, function() return TPSettings.Enabled end, "AutoTPDown")
pi = pi + 1

-- ============================================
-- VISUAL TAB
-- ============================================
local vi = 0
local visual = tabFrames["Visual"]

MakeToggle(visual, "ESP", vi, function(s)
    if s then StartESP() else StopESP() end
end, function() return State.ESP end, "ESP")
vi = vi + 1

MakeToggle(visual, "XRAY BASE", vi, function(s)
    if s then StartXrayBase() else StopXrayBase() end
end, function() return State.XrayBase end, "XrayBase")
vi = vi + 1

MakeToggle(visual, "HIT CIRCLE (Aimbot + Purple)", vi, function(s)
    if s then StartHitCircle() else StopHitCircle() end
end, function() return State.HitCircle end, "HitCircle")
vi = vi + 1

MakeToggle(visual, "OPTIMIZER", vi, function(s)
    if s then startOptimizer() else stopOptimizer() end
end, function() return State.Optimizer end, "Optimizer")
vi = vi + 1

local hideAllState = false
MakeToggle(visual, "Hide All Side Buttons", vi, function(state)
    hideAllState = state
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            local id = b:GetAttribute("ID")
            if state then
                b.Visible = false
                sideHiddenMap[id .. "_all"] = true
            else
                if not sideHiddenMap[id .. "_individual"] then b.Visible = true end
                sideHiddenMap[id .. "_all"] = false
            end
        end
    end
    Save()
end, function() return hideAllState end)
vi = vi + 1

local sideNames = { "AUTO PLAY LEFT", "AUTO PLAY RIGHT", "FLOAT", "SPEED BOOST", "AUTO TRACK", "DROP", "AUTO TP DOWN" }
for _, nm in ipairs(sideNames) do
    MakeToggle(visual, "Hide " .. nm, vi, function(state)
        sideHiddenMap[nm .. "_individual"] = state
        for _, b in pairs(gui:GetChildren()) do
            if b:IsA("Frame") and b.Name == "SideButton" and b:GetAttribute("ID") == nm then
                b.Visible = not state
            end
        end
        Save()
    end, function() return sideHiddenMap[nm .. "_individual"] == true end)
    vi = vi + 1
end

MakeToggle(visual, "Show Steal Bar", vi, function(s)
    StealBarVisible = s
    stealBarFrame.Visible = s
    Save()
end, function() return StealBarVisible end)
vi = vi + 1

MakeNumberBox(visual, "Side Button Size", SideButtonSize, vi, function(val)
    SideButtonSize = val
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            b.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
        end
    end
end, 40, 150, "SideBtnSize")
vi = vi + 1

MakeNumberBox(visual, "Menu Width", menuW, vi, function(v)
    menuW = math.clamp(v, 200, 750)
    menu.Size = UDim2.new(0, menuW, 0, menuH)
end, 200, 750, "MenuWidth")
vi = vi + 1

MakeNumberBox(visual, "Menu Height", menuH, vi, function(v)
    menuH = math.clamp(v, 200, 750)
    menu.Size = UDim2.new(0, menuW, 0, menuH)
end, 200, 750, "MenuHeight")
vi = vi + 1

-- ============================================
-- SETTINGS TAB
-- ============================================
local si = 0
local sTab = tabFrames["Settings"]

local copyBtn = Instance.new("TextButton", sTab)
copyBtn.Size = UDim2.new(1, -10, 0, 40)
copyBtn.Position = UDim2.new(0, 5, 0, si * 44 + 4)
copyBtn.BackgroundColor3 = Color3.fromRGB(70, 45, 190)
copyBtn.AutoButtonColor = false
copyBtn.Text = "COPY DISCORD LINK"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)
copyBtn.MouseButton1Click:Connect(function()
    setclipboard("discord.gg/UeKPQC7fq")
    copyBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 100)
    task.wait(0.8)
    copyBtn.BackgroundColor3 = Color3.fromRGB(70, 45, 190)
    Notify("Discord link copied!")
end)
si = si + 1

local sep = Instance.new("Frame", sTab)
sep.Size = UDim2.new(1, -10, 0, 28)
sep.Position = UDim2.new(0, 5, 0, si * 44 + 4)
sep.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
sep.BackgroundTransparency = 0
Instance.new("UICorner", sep).CornerRadius = UDim.new(0, 6)
local sepLbl = Instance.new("TextLabel", sep)
sepLbl.Size = UDim2.new(1, 0, 1, 0)
sepLbl.BackgroundTransparency = 1
sepLbl.Text = "KEYBINDS"
sepLbl.TextColor3 = Color3.fromRGB(130, 100, 255)
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

-- ============================================
-- SIDE BUTTONS
-- ============================================
local function CreateSideButton(text, side, index, getState, startFn, stopFn)
    local btn = Instance.new("Frame", gui)
    btn.Name = "SideButton"
    btn:SetAttribute("ID", text)
    btn.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
    btn.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
    btn.BackgroundTransparency = 0
    btn.Active = true
    btn.ZIndex = 100
    local isHidden = sideHiddenMap[text .. "_individual"] == true
    btn.Visible = not isHidden
    local saved = ButtonPositions[text]
    if saved then
        btn.Position = UDim2.new(saved.X, saved.XO, saved.Y, saved.YO)
    elseif side == "left" then
        btn.Position = UDim2.new(0, 10, 0.10 + index * 0.14, 0)
    else
        btn.Position = UDim2.new(1, -(SideButtonSize + 10), 0.10 + index * 0.14, 0)
    end
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(70, 55, 130)
    stroke.Thickness = 1.5
    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -6, 0.48, 0)
    lbl.Position = UDim2.new(0, 3, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(190, 180, 220)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextWrapped = true
    local descText = ""
    if text == "AUTO PLAY LEFT" then descText = "Left Lane"
    elseif text == "AUTO PLAY RIGHT" then descText = "Right Lane"
    elseif text == "FLOAT" then descText = "Hover"
    elseif text == "SPEED BOOST" then descText = "Speed"
    elseif text == "AUTO TRACK" then descText = "Track"
    elseif text == "DROP" then descText = "Throw"
    elseif text == "AUTO TP DOWN" then descText = "Auto Land"
    end
    local desc = Instance.new("TextLabel", btn)
    desc.Size = UDim2.new(1, -6, 0.28, 0)
    desc.Position = UDim2.new(0, 3, 0, 42)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = Color3.fromRGB(110, 95, 160)
    desc.Font = Enum.Font.GothamBold
    desc.TextSize = 9
    desc.TextWrapped = true
    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0.5, -5, 1, -13)
    dot.BackgroundColor3 = Color3.fromRGB(45, 38, 80)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local function RefreshVisual()
        if getState() then
            dot.BackgroundColor3 = Color3.fromRGB(160, 130, 255)
            btn.BackgroundColor3 = Color3.fromRGB(55, 35, 150)
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            desc.TextColor3 = Color3.fromRGB(180, 165, 230)
            stroke.Color = Color3.fromRGB(130, 100, 255)
            stroke.Thickness = 2
        else
            dot.BackgroundColor3 = Color3.fromRGB(45, 38, 80)
            btn.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
            lbl.TextColor3 = Color3.fromRGB(190, 180, 220)
            desc.TextColor3 = Color3.fromRGB(110, 95, 160)
            stroke.Color = Color3.fromRGB(70, 55, 130)
            stroke.Thickness = 1.5
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
        btn.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
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
        btn.Size = UDim2.new(0, SideButtonSize - 4, 0, SideButtonSize - 4)
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
            if getState() then
                stopFn()
            else
                startFn()
            end
            RefreshVisual()
        else
            ButtonPositions[text] = { X = savedPos.X.Scale, XO = savedPos.X.Offset, Y = savedPos.Y.Scale, YO = savedPos.Y.Offset }
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
end

CreateSideButton("AUTO PLAY LEFT", "left", 0, function() return State.AutoPlayLeft end, StartAutoPlayLeft, StopAutoPlayLeft)
CreateSideButton("AUTO PLAY RIGHT", "left", 1, function() return State.AutoPlayRight end, StartAutoPlayRight, StopAutoPlayRight)
CreateSideButton("AUTO TRACK", "right", 0, function() return State.AutoTrack end, StartTrackToggle, StopTrackToggle)
CreateSideButton("SPEED BOOST", "right", 1, function() return isSpeedBoostEnabled end, startSpeedBoost, stopSpeedBoost)
CreateSideButton("AUTO TP DOWN", "right", 2, function() return TPSettings.Enabled end,
    function()
        if State.AutoTrack then Notify("Cannot start AUTO TP DOWN while AUTO TRACK is active"); return end
        TPSettings.Enabled = true
        StartTPMonitoring()
        Notify("AUTO TP DOWN ON")
    end,
    function()
        TPSettings.Enabled = false
        StopTPMonitoring()
        Notify("AUTO TP DOWN OFF")
    end)
CreateSideButton("FLOAT", "right", 3, function() return State.FloatEnabled end, startFloat, stopFloat)
CreateSideButton("DROP", "right", 4, function() return false end,
    function()
        if State.AutoTrack then StopTrackToggle() end
        if State.AutoPlayLeft then StopAutoPlayLeft() end
        if State.AutoPlayRight then StopAutoPlayRight() end
        if State.FloatEnabled then stopFloat() end
        if unwalkActive then stopUnwalk() end
        task.spawn(function() task.wait(0.05); executeDrop() end)
    end,
    function() end)

-- ============================================
-- INITIALIZATION
-- ============================================
RunService.Heartbeat:Connect(function()
    if State.AntiSentry then updateAntiSentry() end
    if State.ESP then updateESP() end
end)

Load()
initWPParts()
stealBarFrame.Visible = StealBarVisible
menu.Size = UDim2.new(0, menuW, 0, menuH)

for _, b in pairs(gui:GetChildren()) do
    if b:IsA("Frame") and b.Name == "SideButton" then
        b.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
        local id = b:GetAttribute("ID")
        local sp = ButtonPositions[id]
        if sp then b.Position = UDim2.new(sp.X, sp.XO, sp.Y, sp.YO) end
        if sideHiddenMap[id .. "_individual"] == true then
            b.Visible = false
        else
            b.Visible = true
        end
    end
end

-- Auto-start saved features
if EnhancedGrab.Enabled then
    task.spawn(function() task.wait(3); EnhancedGrab.Enabled = false; StartEnhancedGrab() end)
end
if State.AutoTrack then
    task.spawn(function() task.wait(2.5); StartTrackToggle() end)
end
if State.SpamBat then
    task.spawn(function() task.wait(2); startSpamBat() end)
end
if State.HitCircle then
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
    
    -- Restore saved states
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
    local savedTrack = State.AutoTrack
    local savedUnwalk = unwalkActive
    local savedTP = TPSettings.Enabled
    local savedSpamBat = State.SpamBat
    local savedHitCircle = State.HitCircle
    local savedOptimizer = State.Optimizer
    
    -- Reset all
    State.AntiSentry = false
    State.SpinBody = false
    State.InfiniteJump = false
    State.FloatEnabled = false
    State.XrayBase = false
    State.ESP = false
    State.AntiRagdoll = false
    State.AutoPlayLeft = false
    State.AutoPlayRight = false
    State.SpamBat = false
    State.HitCircle = false
    State.Optimizer = false
    isSpeedBoostEnabled = false
    EnhancedGrab.Enabled = false
    State.AutoTrack = false
    TPSettings.Enabled = false
    if unwalkActive then stopUnwalk() end
    StopTPMonitoring()
    
    local function safeStart(fn, name)
        task.spawn(function() pcall(function() fn(); print("Auto-activated: " .. name) end) end)
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
    if savedSpamBat then safeStart(startSpamBat, "Spam Bat") end
    if savedHitCircle then safeStart(StartHitCircle, "Hit Circle") end
    if savedOptimizer then safeStart(startOptimizer, "Optimizer") end
    
    if savedAutoLeft then safeStart(StartAutoPlayLeft, "Auto Play Left") end
    if savedAutoRight then safeStart(StartAutoPlayRight, "Auto Play Right") end
    if savedGrab then safeStart(StartEnhancedGrab, "Auto Grab") end
    if savedTrack then safeStart(StartTrackToggle, "Auto Track") end
    
    if savedUnwalk then safeStart(startUnwalk, "Unwalk") end
    if savedTP then
        TPSettings.Enabled = true
        StartTPMonitoring()
    end
    
    task.wait(0.3)
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            local id = b:GetAttribute("ID")
            local isOn = false
            if id == "AUTO PLAY LEFT" then isOn = State.AutoPlayLeft
            elseif id == "AUTO PLAY RIGHT" then isOn = State.AutoPlayRight
            elseif id == "FLOAT" then isOn = State.FloatEnabled
            elseif id == "SPEED BOOST" then isOn = isSpeedBoostEnabled
            elseif id == "AUTO TRACK" then isOn = State.AutoTrack
            elseif id == "AUTO TP DOWN" then isOn = TPSettings.Enabled
            end
            b.BackgroundColor3 = isOn and Color3.fromRGB(55, 35, 150) or Color3.fromRGB(12, 10, 20)
        end
    end
    
    task.wait(0.2)
    if toggleUpdaters["AntiRagdoll"] then toggleUpdaters["AntiRagdoll"](State.AntiRagdoll) end
    if toggleUpdaters["InfiniteJump"] then toggleUpdaters["InfiniteJump"](State.InfiniteJump) end
    if toggleUpdaters["FloatEnabled"] then toggleUpdaters["FloatEnabled"](State.FloatEnabled) end
    if toggleUpdaters["SpeedBoost"] then toggleUpdaters["SpeedBoost"](isSpeedBoostEnabled) end
    if toggleUpdaters["AutoTrack"] then toggleUpdaters["AutoTrack"](State.AutoTrack) end
    if toggleUpdaters["AutoGrab"] then toggleUpdaters["AutoGrab"](EnhancedGrab.Enabled) end
    if toggleUpdaters["AntiSentry"] then toggleUpdaters["AntiSentry"](State.AntiSentry) end
    if toggleUpdaters["SpinBody"] then toggleUpdaters["SpinBody"](State.SpinBody) end
    if toggleUpdaters["XrayBase"] then toggleUpdaters["XrayBase"](State.XrayBase) end
    if toggleUpdaters["ESP"] then toggleUpdaters["ESP"](State.ESP) end
    if toggleUpdaters["AutoPlayLeft"] then toggleUpdaters["AutoPlayLeft"](State.AutoPlayLeft) end
    if toggleUpdaters["AutoPlayRight"] then toggleUpdaters["AutoPlayRight"](State.AutoPlayRight) end
    if toggleUpdaters["Unwalk"] then toggleUpdaters["Unwalk"](unwalkActive) end
    if toggleUpdaters["AutoTPDown"] then toggleUpdaters["AutoTPDown"](TPSettings.Enabled) end
    if toggleUpdaters["SpamBat"] then toggleUpdaters["SpamBat"](State.SpamBat) end
    if toggleUpdaters["HitCircle"] then toggleUpdaters["HitCircle"](State.HitCircle) end
    if toggleUpdaters["Optimizer"] then toggleUpdaters["Optimizer"](State.Optimizer) end
end)

Notify("H2N v7.0 - Silent Auto Play + Hit Circle Aimbot + Enhanced Auto Track + Enhanced Auto Grab")
print("===============================================================")
print("H2N ULTIMATE v7.0")
print("- Auto Play Left/Right: Waypoints with neon indicators")
print("- Auto Track: Enhanced with AutoBatSpam + Improved AntiWall")
print("- Auto Grab: Enhanced with callback execution")
print("- Hit Circle: Aimbot + Purple Neon Circle")
print("- Float: Fixed at height 12")
print("- Features: Spam Bat, Optimizer, Speed Boost, Anti Ragdoll, ESP, Xray, etc.")
print("===============================================================")