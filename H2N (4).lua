-- H2N

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
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Char, HRP, Hum

-- ========== [ حماية قوية — غير قابلة للكشف ] ==========

-- 1. إخفاء namecall: منع Kick/Ban من الـ server
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local old_nc = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local m = getnamecallmethod()
        if type(m) == "string" then
            local ml = m:lower()
            if ml == "kick" or ml == "ban" or ml:find("kick") then
                return nil
            end
        end
        return old_nc(self, ...)
    end)
    setreadonly(mt, true)
end)

-- 2. تعطيل Kick على LP و game مباشرة
pcall(function()
    game.Kick = function() end
    if LP then LP.Kick = function() end end
end)

-- 3. تعطيل RemoteEvents المشبوهة في ReplicatedStorage
pcall(function()
    local rep = game:GetService("ReplicatedStorage")
    local function blockSuspect(obj)
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = (obj.Name or ""):lower()
            if n:find("kick") or n:find("ban") or n:find("detect")
            or n:find("cheat") or n:find("anticheat") or n:find("log") then
                pcall(function() obj.FireServer  = function() end end)
                pcall(function() obj.InvokeServer = function() end end)
            end
        end
    end
    for _, v in pairs(rep:GetDescendants()) do blockSuspect(v) end
    rep.DescendantAdded:Connect(blockSuspect)
end)

-- 4. إخفاء index غير عادية على game (بعض الـ anti-cheat تقرأ properties)
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local old_index = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if type(key) == "string" then
            local kl = key:lower()
            if kl:find("script") and kl:find("detect") then return nil end
        end
        return old_index(self, key)
    end)
    setreadonly(mt, true)
end)

-- 5. تمويه velocity — حركة تدريجية مش مفاجئة (يقلل الكشف بالـ velocity spikes)
local function clampedVelocity(hrp, velX, velY, velZ, maxSpd)
    if not hrp then return end
    local cur = hrp.AssemblyLinearVelocity
    local smoothX = cur.X + (velX - cur.X) * 0.85
    local smoothZ = cur.Z + (velZ - cur.Z) * 0.85
    local spd = math.sqrt(smoothX*smoothX + smoothZ*smoothZ)
    if spd > maxSpd then
        smoothX = smoothX / spd * maxSpd
        smoothZ = smoothZ / spd * maxSpd
    end
    hrp.AssemblyLinearVelocity = Vector3.new(smoothX, velY, smoothZ)
end

-- 6. حماية الـ GUI من الحذف
local function protectGUI(guiObj)
    pcall(function()
        local function pd(obj)
            local op = obj.Parent
            obj:GetPropertyChangedSignal("Parent"):Connect(function()
                if obj.Parent ~= op then
                    task.defer(function() pcall(function() obj.Parent = op end) end)
                end
            end)
        end
        pd(guiObj)
        guiObj.DescendantAdded:Connect(pd)
    end)
end

-- 7. منع ScreenGui من الإزالة بواسطة CoreGui
pcall(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local old_nc = rawget(mt, "__namecall")
    if not old_nc then return end
    -- تم التعامل معها في الـ namecall hook أعلاه
end)

-- ========== [ الألوان ] ==========
local Colors = {
    White = Color3.fromRGB(8, 8, 12),
    LightGray = Color3.fromRGB(13, 13, 20),
    MediumGray = Color3.fromRGB(0, 120, 220),
    DarkGray = Color3.fromRGB(0, 100, 200),
    VeryDark = Color3.fromRGB(5, 5, 10),
    AlmostBlack = Color3.fromRGB(3, 3, 8),
    Border = Color3.fromRGB(0, 150, 255),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(120, 200, 255),
    Success = Color3.fromRGB(0, 200, 120),
    Error = Color3.fromRGB(255, 70, 70),
    DotOff = Color3.fromRGB(30, 30, 50),
    DotOn = Color3.fromRGB(0, 180, 255),
    DiscordBlue = Color3.fromRGB(0, 170, 255),
}

-- ========== [ Notify - Forward Declaration ] ==========
-- Notify تحتاج gui لكنها تُستدعى قبل إنشائه
-- الحل: نخزّن الإشعارات مؤقتاً ونعرضها بعد ما gui يتعرّف
local _notifyQueue = {}
local gui = nil  -- سيتم تعيينه لاحقاً

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
LP.CharacterAdded:Connect(function(c) task.wait(0.1); Setup(c) end)

-- ========== [ الحالة العامة ] ==========
local State = {
    AutoPlayLeft = false,
    AutoPlayRight = false,
    AutoTrack = false,
    AntiRagdoll = false,
    InfiniteJump = false,
    XrayBase = false,
    ESP = false,
    AntiSentry = false,
    SpinBody = false,
    FloatEnabled = false,
    SpeedBoostEnabled = false,
    AutoGrab = false,
}

local function setOnlyThisFeature(activeFeature)
    if activeFeature == "Left" then
        State.AutoPlayLeft = true
        State.AutoPlayRight = false
        State.AutoTrack = false
    elseif activeFeature == "Right" then
        State.AutoPlayLeft = false
        State.AutoPlayRight = true
        State.AutoTrack = false
    elseif activeFeature == "Track" then
        State.AutoPlayLeft = false
        State.AutoPlayRight = false
        State.AutoTrack = true
    elseif activeFeature == "None" then
        State.AutoPlayLeft = false
        State.AutoPlayRight = false
        State.AutoTrack = false
    end
end

-- ========== [ SPEED BOOST — نظام FlameHub Queue+Lerp ] ==========
local SpeedSettings = { NormalSpeed = 52, StealSpeed = 27 }
local IsHoldingBrainrot  = false
local isSpeedBoostEnabled = false
local speedConn  = nil
local speedPaused = false

-- نظام Queue للحركة (FlameHub)
local SPEED_SMOOTH   = 0.30
local PATH_TOLERANCE = 0.8
local moveConn   = nil
local moveQueue  = {}
local moveActive = false

local function StopMove()
    if moveConn then moveConn:Disconnect(); moveConn = nil end
    moveQueue  = {}
    moveActive = false
    local c = LP.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
        if hum then hum:Move(Vector3.zero, false) end
    end
end

local function QueuePoint(target, spd)
    table.insert(moveQueue, { target = target, spd = spd })
end

local function RunQueue(stopFlag)
    if moveConn then moveConn:Disconnect(); moveConn = nil end
    moveActive = true
    moveConn = RunService.Heartbeat:Connect(function()
        if stopFlag() or not HRP or not Hum then StopMove(); return end
        if #moveQueue == 0 then
            local v = HRP.AssemblyLinearVelocity
            HRP.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            Hum:Move(Vector3.zero, false)
            moveActive = false; return
        end
        local step  = moveQueue[1]
        local diff  = step.target - HRP.Position
        local hDist = Vector2.new(diff.X, diff.Z).Magnitude
        if hDist < PATH_TOLERANCE then
            table.remove(moveQueue, 1); return
        end
        local dir  = Vector3.new(diff.X, 0, diff.Z).Unit
        Hum:Move(dir, false)
        local cur  = HRP.AssemblyLinearVelocity
        local newH = Vector3.new(cur.X, 0, cur.Z):Lerp(dir * step.spd, SPEED_SMOOTH)
        HRP.AssemblyLinearVelocity = Vector3.new(newH.X, cur.Y, newH.Z)
    end)
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

local function updateCarryStatus()
    local newState = isHoldingBrainrot()
    if newState ~= IsHoldingBrainrot then IsHoldingBrainrot = newState end
end

local function startSpeedBoost()
    if isSpeedBoostEnabled then return end
    isSpeedBoostEnabled = true
    speedPaused = false
    updateCarryStatus()
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not isSpeedBoostEnabled or speedPaused then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        updateCarryStatus()
        local targetSpeed = IsHoldingBrainrot and SpeedSettings.StealSpeed or SpeedSettings.NormalSpeed
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            -- نستخدم Lerp بدل تعيين مباشر (أقل كشفاً)
            local cur = hrp.AssemblyLinearVelocity
            local targetV = Vector3.new(moveDir.X * targetSpeed, cur.Y, moveDir.Z * targetSpeed)
            hrp.AssemblyLinearVelocity = cur:Lerp(targetV, 0.4)
        else
            local cur = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(cur.X * 0.7, cur.Y, cur.Z * 0.7)
        end
    end)
    if Hum then Hum.UseJumpPower = true; Hum.JumpPower = 45 end
    Notify("🔵 SPEED BOOST ON")
end

local function stopSpeedBoost()
    if not isSpeedBoostEnabled then return end
    isSpeedBoostEnabled = false
    speedPaused = false
    if speedConn then speedConn:Disconnect(); speedConn = nil end
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
    end
    Notify("⚫ SPEED BOOST OFF")
end

local function pauseSpeed() if isSpeedBoostEnabled then speedPaused = true end end
local function resumeSpeed() if isSpeedBoostEnabled then speedPaused = false end end

-- ========== [ FLOAT ] ==========
local FloatHeight = 14
local FloatUpSpeed = 70
local FloatConn = nil
local floatPaused = false

local function startFloat()
    if State.FloatEnabled then return end
    if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
    State.FloatEnabled = true
    floatPaused = false
    FloatConn = RunService.Heartbeat:Connect(function()
        if not State.FloatEnabled then return end
        if floatPaused then return end
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = { char }
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rayParams)
        local groundY = result and result.Position.Y or (hrp.Position.Y - FloatHeight)
        local targetY = groundY + FloatHeight
        local diff = targetY - hrp.Position.Y
        if diff > 0.3 then
            local upSpeed = math.min(diff * 12, FloatUpSpeed)
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, upSpeed, hrp.AssemblyLinearVelocity.Z)
        elseif diff < -0.3 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -8, hrp.AssemblyLinearVelocity.Z)
        else
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end
    end)
    Notify("🔵 FLOAT ON")
end

local function stopFloat()
    if not State.FloatEnabled then return end
    State.FloatEnabled = false
    floatPaused = false
    if FloatConn then FloatConn:Disconnect(); FloatConn = nil end
    Notify("⚫ FLOAT OFF")
end

local function pauseFloat() if State.FloatEnabled then floatPaused = true end end
local function resumeFloat() if State.FloatEnabled then floatPaused = false end end

-- ========== [ AUTO GRAB — نظام FlameHub ] ==========
local AutoGrabEnabled   = false
local AutoGrabProgress  = 0
local GrabRadius        = 10
local grabLoopThread    = nil
local grabPromptCache   = {}

local grabBarRef  = {}
local sbFill      = nil
local stealBarFrame = nil

local function UpdateGrabBar(pct)
    AutoGrabProgress = pct
    if grabBarRef.fill then grabBarRef.fill.Size = UDim2.new(pct / 100, 0, 1, 0) end
    if grabBarRef.pct  then grabBarRef.pct.Text  = math.floor(pct) .. "%" end
    if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = GrabRadius .. "st" end
end

local function GrabScanPrompts()
    grabPromptCache = {}
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, plot in pairs(plots:GetChildren()) do
        for _, desc in pairs(plot:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled and desc.ActionText == "Steal" then
                local pos
                local par = desc.Parent
                if par:IsA("BasePart") then
                    pos = par.Position
                elseif par:IsA("Model") then
                    local pp = par.PrimaryPart or par:FindFirstChildWhichIsA("BasePart")
                    if pp then pos = pp.Position end
                elseif par:IsA("Attachment") then
                    pos = par.WorldPosition
                else
                    local bp = par:FindFirstChildWhichIsA("BasePart", true)
                    if bp then pos = bp.Position end
                end
                if pos then
                    table.insert(grabPromptCache, { Prompt = desc, Position = pos })
                end
            end
        end
    end
end

local function StartEnhancedGrab()
    if AutoGrabEnabled then return end
    AutoGrabEnabled = true
    AutoGrabProgress = 0
    UpdateGrabBar(0)
    grabPromptCache = {}
    GrabScanPrompts()
    grabLoopThread = task.spawn(function()
        while AutoGrabEnabled do
            GrabScanPrompts()
            if HRP then
                local fired = false
                for _, cached in ipairs(grabPromptCache) do
                    local p = cached.Prompt
                    if not (p and p.Parent and p:IsDescendantOf(workspace) and p.Enabled) then continue end
                    if (HRP.Position - cached.Position).Magnitude > GrabRadius then continue end
                    fired = true
                    task.spawn(function()
                        pcall(function() fireproximityprompt(p, 1000, math.huge) end)
                        pcall(function() p:InputHoldBegin() end)
                        task.wait(0.04)
                        pcall(function() p:InputHoldEnd() end)
                    end)
                end
                UpdateGrabBar(fired and 100 or 0)
            end
            task.wait(0.05)
        end
    end)
    Notify("🔵 AUTO GRAB ON | Range: " .. GrabRadius)
end

local function StopEnhancedGrab()
    if not AutoGrabEnabled then return end
    AutoGrabEnabled = false
    if grabLoopThread then task.cancel(grabLoopThread); grabLoopThread = nil end
    UpdateGrabBar(0)
    grabPromptCache = {}
    Notify("⚫ AUTO GRAB OFF")
end

-- wrapper بسيط للتوافق مع Save/Load والـ UI
local EnhancedGrab = {
    Enabled = false,
    Radius  = GrabRadius,
    Delay   = 0.05,
}

-- مزامنة EnhancedGrab.Enabled مع الوظائف الحقيقية
local _origStartGrab = StartEnhancedGrab
local _origStopGrab  = StopEnhancedGrab
StartEnhancedGrab = function()
    EnhancedGrab.Enabled = true
    GrabRadius = EnhancedGrab.Radius
    _origStartGrab()
end
StopEnhancedGrab = function()
    EnhancedGrab.Enabled = false
    _origStopGrab()
end

-- ========== [ DROP ] ==========
local dropIsActive = false
local lastDropTime = 0
local DROP_COOLDOWN = 1.5

local function executeDrop()
    local now = tick()
    if now - lastDropTime < DROP_COOLDOWN then
        Notify("⚠️ كولداون " .. string.format("%.1f", DROP_COOLDOWN - (now - lastDropTime)) .. " ثانية")
        return 
    end
    if dropIsActive then 
        Notify("⚠️ DROP مشغول")
        return 
    end
    lastDropTime = now
    dropIsActive = true
    local speedWasOn = isSpeedBoostEnabled
    local floatWasOn = State.FloatEnabled
    if speedWasOn then pauseSpeed() end
    if floatWasOn then pauseFloat() end
    local char = LP.Character
    if not char then 
        if speedWasOn then resumeSpeed() end
        if floatWasOn then resumeFloat() end
        dropIsActive = false
        return 
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        if speedWasOn then resumeSpeed() end
        if floatWasOn then resumeFloat() end
        dropIsActive = false
        return 
    end
    local VELOCITY_X = 300
    local VELOCITY_Y = 650
    local DURATION = 0.1
    local MAX_FORCE = 20000
    local startTime = tick()
    task.spawn(function()
        while dropIsActive and (tick() - startTime) < DURATION do
            local c = LP.Character
            if not c then break end
            local r = c:FindFirstChild("HumanoidRootPart")
            if not r then break end
            for _, v in pairs(r:GetChildren()) do if v:IsA("BodyVelocity") then v:Destroy() end end
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1, 1, 1) * MAX_FORCE
            bv.Velocity = Vector3.new(VELOCITY_X, VELOCITY_Y, 0)
            bv.Parent = r
            task.wait(0.01)
        end
        local c = LP.Character
        if c then
            local r = c:FindFirstChild("HumanoidRootPart")
            if r then for _, v in pairs(r:GetChildren()) do if v:IsA("BodyVelocity") then v:Destroy() end end end
        end
        if speedWasOn then resumeSpeed() end
        if floatWasOn then resumeFloat() end
        dropIsActive = false
        Notify("💥 DROP!")
    end)
end

-- ========== [ AUTO TRACK ] ==========
local TrackSettings = {
    Enabled = false,
    LockSpeed = 80,
    TrackSpeed = 58,
    ForwardOffset = 2.3,
    TrackConn = nil,
    AntiWallConn = nil,
    AlignOri = nil,
    Attachment = nil,
}

local function getHRPTrack() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumTrack() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end

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
        local tv = target.AssemblyLinearVelocity
        local moveX = tv.X
        local moveZ = tv.Z
        local moveMag = math.sqrt(moveX * moveX + moveZ * moveZ)
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
            offsetX = normX * TrackSettings.ForwardOffset + sideX * turnSide
            offsetZ = normZ * TrackSettings.ForwardOffset + sideZ * turnSide
        else
            offsetX, offsetZ = 0, 0
        end
        local aimX = target.Position.X + offsetX
        local aimY = target.Position.Y
        local aimZ = target.Position.Z + offsetZ
        local dX = aimX - h.Position.X
        local dZ = aimZ - h.Position.Z
        local dY = aimY - h.Position.Y
        local flatDist = math.sqrt(dX * dX + dZ * dZ)
        local yVel = math.clamp(dY * 12, -35, 35)
        local velX, velZ
        if flatDist > 1.5 then
            velX = (dX / flatDist) * TrackSettings.TrackSpeed
            velZ = (dZ / flatDist) * TrackSettings.TrackSpeed
        else
            velX = tv.X + dX * 20
            velZ = tv.Z + dZ * 20
            local mag = math.sqrt(velX * velX + velZ * velZ)
            if mag > TrackSettings.LockSpeed then
                velX = velX / mag * TrackSettings.LockSpeed
                velZ = velZ / mag * TrackSettings.LockSpeed
            end
        end
        h.AssemblyLinearVelocity = Vector3.new(velX, yVel, velZ)
        if TrackSettings.AlignOri then
            local dirX = h.Position.X - target.Position.X
            local dirZ = h.Position.Z - target.Position.Z
            local dirMag = math.sqrt(dirX * dirX + dirZ * dirZ)
            if dirMag > 0.1 then
                TrackSettings.AlignOri.Enabled = true
                TrackSettings.AlignOri.CFrame = CFrame.lookAt(h.Position, h.Position + Vector3.new(dirX / dirMag, 0, dirZ / dirMag))
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
    if TrackSettings.TrackConn then TrackSettings.TrackConn:Disconnect(); TrackSettings.TrackConn = nil end
    if TrackSettings.AntiWallConn then TrackSettings.AntiWallConn:Disconnect(); TrackSettings.AntiWallConn = nil end
    if TrackSettings.AlignOri then pcall(function() TrackSettings.AlignOri:Destroy() end); TrackSettings.AlignOri = nil end
    if TrackSettings.Attachment then pcall(function() TrackSettings.Attachment:Destroy() end); TrackSettings.Attachment = nil end
    local hrp = getHRPTrack()
    local hm = getHumTrack()
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
    if hm then hm.AutoRotate = true end
end

local function StartTrackToggle()
    if TrackSettings.Enabled then return end
    setOnlyThisFeature("Track")
    TrackSettings.Enabled = true
    if State.AutoPlayLeft or State.AutoPlayRight then
        if State.AutoPlayLeft then StopAutoPlayLeft() end
        if State.AutoPlayRight then StopAutoPlayRight() end
    end
    task.wait(0.05)
    local hrp = getHRPTrack()
    if hrp then StartTrack()
    else task.spawn(function() while TrackSettings.Enabled and not getHRPTrack() do task.wait(0.1) end; if TrackSettings.Enabled then StartTrack() end end) end
    Notify("🔵 AUTO TRACK ON")
end

local function StopTrackToggle()
    if not TrackSettings.Enabled then return end
    TrackSettings.Enabled = false
    setOnlyThisFeature("None")
    StopTrack()
    Notify("⚫ AUTO TRACK OFF")
end

-- ========== [ WAYPOINTS ] ==========
local L1    = Vector3.new(-476, -7,  93)
local L2    = Vector3.new(-484, -5,  95)
local L_END = Vector3.new(-476, -6,  21)
local R1    = Vector3.new(-476, -7,  28)
local R2    = Vector3.new(-484, -5,  25)
local R_END = Vector3.new(-476, -6, 100)

local LEFT_ROUTE = {"L1", "L2", "L1", "L_END"}
local RIGHT_ROUTE = {"R1", "R2", "R1", "R_END"}

local WP_PARTS = {}
local WP_BLUE = Color3.fromRGB(0, 150, 255)
local WP_COLORS = {
    L1=WP_BLUE, L2=WP_BLUE, L_END=WP_BLUE,
    R1=WP_BLUE, R2=WP_BLUE, R_END=WP_BLUE,
}

local function createWPPart(name, pos, color)
    local old = workspace:FindFirstChild("H2N_WP_"..name)
    if old then old:Destroy() end
    local part = Instance.new("Part")
    part.Name="H2N_WP_"..name
    part.Size=Vector3.new(0.8, 0.8, 0.8)
    part.Shape = Enum.PartType.Ball
    part.Position=pos
    part.Anchored=true
    part.CanCollide=false
    part.CanQuery=false
    part.CastShadow=false
    part.Material=Enum.Material.Neon
    part.Color=color
    part.Transparency=0.15
    local light = Instance.new("PointLight", part)
    light.Color = color
    light.Range = 3
    light.Brightness = 1
    local bg=Instance.new("BillboardGui",part)
    bg.Size=UDim2.new(0,50,0,20)
    bg.StudsOffset=Vector3.new(0,1.2,0)
    bg.AlwaysOnTop=true
    bg.LightInfluence=0
    local lbl=Instance.new("TextLabel",bg)
    lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundColor3=Colors.AlmostBlack
    lbl.BackgroundTransparency=0.4
    lbl.Text=name
    lbl.TextColor3=Colors.DiscordBlue
    lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=12
    Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,6)
    part.Parent=workspace
    WP_PARTS[name]=part
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
    local p=WP_PARTS[name]
    if p and p.Parent then return p.Position end
    if name=="L1" then return L1
    elseif name=="L2" then return L2
    elseif name=="L_END" then return L_END
    elseif name=="R1" then return R1
    elseif name=="R2" then return R2
    elseif name=="R_END" then return R_END
    end
end

-- ========== [ AUTO DUEL — نظام FlameHub Queue ] ==========
local function DUEL_APPROACH_SPD() return SpeedSettings.NormalSpeed end
local function DUEL_RETURN_SPD()   return SpeedSettings.StealSpeed  end

local aplConn, aprConn = nil, nil
local aplActive, aprActive = false, false

local function getHRP2()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function StopAutoPlayLeft()
    if not State.AutoPlayLeft then return end
    State.AutoPlayLeft = false
    aplActive = false
    StopMove()
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
    Save()
end

local function StopAutoPlayRight()
    if not State.AutoPlayRight then return end
    State.AutoPlayRight = false
    aprActive = false
    StopMove()
    local h = getHRP2()
    if h then h.AssemblyLinearVelocity = Vector3.new(0, h.AssemblyLinearVelocity.Y, 0) end
    if Hum then Hum.AutoRotate = true end
    Save()
end

local function StartAutoPlayLeft()
    if State.AutoPlayRight then StopAutoPlayRight() end
    if TrackSettings.Enabled then StopTrackToggle() end
    if isSpeedBoostEnabled then stopSpeedBoost() end
    setOnlyThisFeature("Left")
    State.AutoPlayLeft = true
    aplActive = true
    if Hum then Hum.AutoRotate = false end
    Save()
    Notify("🔵 AUTO DUEL LEFT ON")
    task.spawn(function()
        while aplActive and State.AutoPlayLeft do
            StopMove()
            QueuePoint(getWP("L1"),    DUEL_APPROACH_SPD())
            QueuePoint(getWP("L2"),    DUEL_APPROACH_SPD())
            QueuePoint(getWP("L1"),    DUEL_RETURN_SPD())
            QueuePoint(getWP("L_END"), DUEL_RETURN_SPD())
            RunQueue(function() return not aplActive or not State.AutoPlayLeft end)
            while moveActive and aplActive and State.AutoPlayLeft do task.wait(0.05) end
        end
        StopMove()
    end)
end

local function StartAutoPlayRight()
    if State.AutoPlayLeft then StopAutoPlayLeft() end
    if TrackSettings.Enabled then StopTrackToggle() end
    if isSpeedBoostEnabled then stopSpeedBoost() end
    setOnlyThisFeature("Right")
    State.AutoPlayRight = true
    aprActive = true
    if Hum then Hum.AutoRotate = false end
    Save()
    Notify("🔵 AUTO DUEL RIGHT ON")
    task.spawn(function()
        while aprActive and State.AutoPlayRight do
            StopMove()
            QueuePoint(getWP("R1"),    DUEL_APPROACH_SPD())
            QueuePoint(getWP("R2"),    DUEL_APPROACH_SPD())
            QueuePoint(getWP("R1"),    DUEL_RETURN_SPD())
            QueuePoint(getWP("R_END"), DUEL_RETURN_SPD())
            RunQueue(function() return not aprActive or not State.AutoPlayRight end)
            while moveActive and aprActive and State.AutoPlayRight do task.wait(0.05) end
        end
        StopMove()
    end)
end

-- ========== [ نظام كشف الضربات ] ==========
local damageConn = nil
local damageCooldown = false
local lastHealth = nil
local lastKnockbackTime = 0

local function stopFeaturesOnDamage()
    if damageCooldown then return end
    damageCooldown = true
    if State.AutoPlayLeft then StopAutoPlayLeft() end
    if State.AutoPlayRight then StopAutoPlayRight() end
    if State.FloatEnabled then stopFloat() end
    task.delay(0.8, function() damageCooldown = false end)
end

local function setupDamageTracking()
    if damageConn then damageConn:Disconnect(); damageConn = nil end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    lastHealth = hum.Health
    lastKnockbackTime = 0
    damageConn = RunService.Heartbeat:Connect(function()
        if not LP.Character or not hum or hum.Parent ~= LP.Character then
            if damageConn then damageConn:Disconnect(); damageConn = nil end
            return
        end
        local currentHealth = hum.Health
        local currentTime = tick()
        -- كشف نقص الصحة فقط (الضربات الحقيقية)
        if lastHealth and currentHealth < lastHealth - 0.5 and hum.Health > 0 then
            stopFeaturesOnDamage()
        end
        -- كشف الكنوكباك: نتجاهل السرعة العالية لو Speed Boost أو DROP شغالين
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and not isSpeedBoostEnabled and not dropIsActive then
            local currentVel = hrp.AssemblyLinearVelocity.Magnitude
            if currentVel > 45 and (currentTime - lastKnockbackTime) > 0.3 then
                if State.AutoPlayLeft or State.AutoPlayRight or State.FloatEnabled then
                    stopFeaturesOnDamage()
                    lastKnockbackTime = currentTime
                end
            end
        end
        -- كشف الراغدول / الصعق
        local currentState = hum:GetState()
        if currentState == Enum.HumanoidStateType.Physics or
           currentState == Enum.HumanoidStateType.Ragdoll or
           currentState == Enum.HumanoidStateType.FallingDown then
            stopFeaturesOnDamage()
        end
        if currentHealth > 0 then lastHealth = currentHealth end
    end)
end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    damageCooldown = false
    lastHealth = nil
    lastKnockbackTime = 0
    setupDamageTracking()
end)

-- ========== [ ANTI RAGDOLL ] ==========
local antiRagdollConn = nil
local isRagdollRecovering = false

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
        local state = hum:GetState()
        local isRagdoll = (state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown)
        if isRagdoll and not isRagdollRecovering then
            isRagdollRecovering = true
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint") then pcall(function() obj:Destroy() end)
                elseif obj:IsA("Motor6D") and obj.Enabled == false then obj.Enabled = true end
            end
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
            if workspace.CurrentCamera then workspace.CurrentCamera.CameraSubject = hum end
            pcall(function()
                if LP.Character then
                    local playerModule = LP.PlayerScripts:FindFirstChild("PlayerModule")
                    if playerModule then
                        local controls = require(playerModule:FindFirstChild("ControlModule"))
                        controls:Enable()
                    end
                end
            end)
            task.wait(0.1)
            isRagdollRecovering = false
        end
    end)
    Notify("🔵 ANTI RAGDOLL ON")
end

local function StopAntiRagdoll()
    if not State.AntiRagdoll then return end
    State.AntiRagdoll = false
    if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
    isRagdollRecovering = false
    Notify("⚫ ANTI RAGDOLL OFF")
end

-- ========== [ INFINITE JUMP ] ==========
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
    Notify("🔵 INFINITE JUMP ON")
end

local function StopInfiniteJump()
    State.InfiniteJump = false
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
    Notify("⚫ INFINITE JUMP OFF")
end

-- ========== [ ANTI DIE ] ==========
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

-- ========== [ XRAY ] ==========
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
    Notify("🔵 XRAY BASE ON")
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
    Notify("⚫ XRAY BASE OFF")
end

-- ========== [ ESP ] ==========
local espHL = {}
local function ClearESP() for _, h in pairs(espHL) do if h and h.Parent then h:Destroy() end end; espHL = {} end
local function StartESP()
    if State.ESP then return end
    State.ESP = true; Notify("🔵 ESP ON")
end
local function StopESP()
    if not State.ESP then return end
    State.ESP = false; ClearESP(); Notify("⚫ ESP OFF")
end
local function updateESP()
    if not State.ESP then return end
    for player, h in pairs(espHL) do
        if not player or not player.Character then if h and h.Parent then h:Destroy() end; espHL[player] = nil end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and (not espHL[p] or not espHL[p].Parent) then
            local h = Instance.new("Highlight")
            h.FillColor = Colors.DarkGray; h.OutlineColor = Colors.White
            h.FillTransparency = 0.5; h.OutlineTransparency = 0; h.Adornee = p.Character; h.Parent = p.Character
            espHL[p] = h
        end
    end
end

-- ========== [ ANTI SENTRY ] ==========
local antiSentryTarget = nil
local DETECTION_DISTANCE = 60
local PULL_DISTANCE = -5
local function findSentryTarget()
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPos = char.HumanoidRootPart.Position
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:find("Sentry") and not obj.Name:lower():find("bullet") then
            local ownerId = obj.Name:match("Sentry_(%d+)")
            if ownerId and tonumber(ownerId) == LP.UserId then continue end
            local part = (obj:IsA("BasePart") and obj) or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
            if part and (rootPos - part.Position).Magnitude <= DETECTION_DISTANCE then return obj end
        end
    end
end
local function moveSentry(obj)
    local char = LP.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, p in pairs(obj:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
    local root = char.HumanoidRootPart; local cf = root.CFrame * CFrame.new(0,0,PULL_DISTANCE)
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
local function StartAntiSentry() if State.AntiSentry then return end; State.AntiSentry = true; Notify("🔵 ANTI SENTRY ON") end
local function StopAntiSentry() if not State.AntiSentry then return end; State.AntiSentry = false; antiSentryTarget = nil; Notify("⚫ ANTI SENTRY OFF") end
local function updateAntiSentry() if not State.AntiSentry then return end; if antiSentryTarget and antiSentryTarget.Parent == workspace then moveSentry(antiSentryTarget); attackSentry() else antiSentryTarget = findSentryTarget() end end

-- ========== [ SPIN BODY ] ==========
local spinForce = nil
local SPIN_SPEED = 25
local function StartSpinBody()
    if State.SpinBody then return end
    State.SpinBody = true
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root or spinForce then return end
    spinForce = Instance.new("BodyAngularVelocity")
    spinForce.Name = "SpinForce"; spinForce.AngularVelocity = Vector3.new(0,SPIN_SPEED,0)
    spinForce.MaxTorque = Vector3.new(0,math.huge,0); spinForce.P = 1250; spinForce.Parent = root
    Notify("🔵 SPIN BODY ON")
end
local function StopSpinBody()
    if not State.SpinBody then return end
    State.SpinBody = false; if spinForce then spinForce:Destroy(); spinForce = nil end
    Notify("⚫ SPIN BODY OFF")
end

-- ========== [ KEYBINDS ] ==========
local Keys = {
    InfJump = Enum.KeyCode.J,
    AutoPlayLeft = Enum.KeyCode.G,
    AutoPlayRight = Enum.KeyCode.H,
    AntiRagdoll = Enum.KeyCode.K,
    Float = Enum.KeyCode.F,
    SpeedBoost = Enum.KeyCode.B,
}
local KeyEnabled = {
    InfJump = true, AutoPlayLeft = true, AutoPlayRight = true,
    AntiRagdoll = true, Float = true, SpeedBoost = true,
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
        -- Speed Boost keybind معطل
        -- if isSpeedBoostEnabled then stopSpeedBoost() else startSpeedBoost() end
    end
end)

-- ========== [ CONFIG VARIABLES ] ==========
local SideButtonSize = 80
local menuW, menuH = 350, 350
local StealBarVisible = true
local ButtonPositions = {}
local sideHiddenMap = {}
local menu = nil
local numberBoxReferences = {}
local toggleUpdaters = {}

-- ========== [ SAVE SYSTEM (نفس القديم) ] ==========
local CFG = "H2N_Config.json"

local function Save()
    local menuPos = {X=0.5, XO=0, Y=0.52, YO=0}
    if menu then
        menuPos = {
            X = menu.Position.X.Scale,
            XO = menu.Position.X.Offset,
            Y = menu.Position.Y.Scale,
            YO = menu.Position.Y.Offset,
        }
    end
    local data = {
        SideButtonSize = SideButtonSize,
        menuW = menuW,
        menuH = menuH,
        menuPos = menuPos,
        FloatHeight = FloatHeight,
        FloatUpSpeed = FloatUpSpeed,
        NormalSpeed = SpeedSettings.NormalSpeed,
        StealSpeed = SpeedSettings.StealSpeed,
        EnhancedGrab = {
            Radius = EnhancedGrab.Radius,
            Delay = EnhancedGrab.Delay,
            Enabled = EnhancedGrab.Enabled,
        },
        TrackSettings = {
            Enabled = TrackSettings.Enabled,
            TrackSpeed = TrackSettings.TrackSpeed,
        },
        Keys = {
            InfJump = Keys.InfJump.Name,
            AutoPlayLeft = Keys.AutoPlayLeft.Name,
            AutoPlayRight = Keys.AutoPlayRight.Name,
            AntiRagdoll = Keys.AntiRagdoll.Name,
            Float = Keys.Float.Name,
            SpeedBoost = Keys.SpeedBoost.Name,
        },
        KeyEnabled = {
            InfJump = KeyEnabled.InfJump,
            AutoPlayLeft = KeyEnabled.AutoPlayLeft,
            AutoPlayRight = KeyEnabled.AutoPlayRight,
            AntiRagdoll = KeyEnabled.AntiRagdoll,
            Float = KeyEnabled.Float,
            SpeedBoost = KeyEnabled.SpeedBoost,
        },
        ST_AntiSentry = State.AntiSentry,
        ST_SpinBody = State.SpinBody,
        ST_AntiRagdoll = State.AntiRagdoll,
        ST_InfiniteJump = State.InfiniteJump,
        ST_FloatEnabled = State.FloatEnabled,
        ST_XrayBase = State.XrayBase,
        ST_ESP = State.ESP,
        ST_SpeedBoost = isSpeedBoostEnabled,
        StealBarVisible = StealBarVisible,
        sideHiddenMap = sideHiddenMap,
        ButtonPositions = ButtonPositions,
    }
    pcall(function() writefile(CFG, HttpService:JSONEncode(data)) end)
end

local function Load()
    local ok, raw = pcall(readfile, CFG)
    if not ok or not raw or raw == "" then return end
    local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(d) ~= "table" then return end

    if d.SideButtonSize then SideButtonSize = d.SideButtonSize end
    if d.menuW then menuW = d.menuW end
    if d.menuH then menuH = d.menuH end
    if d.FloatHeight then FloatHeight = d.FloatHeight end
    if d.FloatUpSpeed then FloatUpSpeed = math.clamp(d.FloatUpSpeed, 5, 125) end
    if d.NormalSpeed then SpeedSettings.NormalSpeed = d.NormalSpeed end
    if d.StealSpeed  then SpeedSettings.StealSpeed  = d.StealSpeed  end
    
    if d.EnhancedGrab then
        if d.EnhancedGrab.Radius then EnhancedGrab.Radius = math.clamp(d.EnhancedGrab.Radius, 5, 50) end
        if d.EnhancedGrab.Delay then EnhancedGrab.Delay = math.clamp(d.EnhancedGrab.Delay, 0.05, 1.0) end
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

    if d.StealBarVisible ~= nil then StealBarVisible = d.StealBarVisible end
    if type(d.sideHiddenMap) == "table" then sideHiddenMap = d.sideHiddenMap end
    if type(d.ButtonPositions) == "table" then ButtonPositions = d.ButtonPositions end

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
                if id == "GrabRadius" then
                    boxRef.TextBox.Text = tostring(EnhancedGrab.Radius)
                elseif id == "GrabDelay" then
                    boxRef.TextBox.Text = string.format("%.2f", EnhancedGrab.Delay)
                elseif id == "DuelApproach" then
                    boxRef.TextBox.Text = tostring(SpeedSettings.NormalSpeed)
                elseif id == "DuelReturn" then
                    boxRef.TextBox.Text = tostring(SpeedSettings.StealSpeed)
                elseif id == "NormalSpeed" then
                    boxRef.TextBox.Text = tostring(SpeedSettings.NormalSpeed)
                elseif id == "StealSpeed" then
                    boxRef.TextBox.Text = tostring(SpeedSettings.StealSpeed)
                elseif id == "FloatHeight" then
                    boxRef.TextBox.Text = tostring(FloatHeight)
                elseif id == "FloatUpSpeed" then
                    boxRef.TextBox.Text = tostring(FloatUpSpeed)
                elseif id == "SideBtnSize" then
                    boxRef.TextBox.Text = tostring(SideButtonSize)
                elseif id == "MenuWidth" then
                    boxRef.TextBox.Text = tostring(menuW)
                elseif id == "MenuHeight" then
                    boxRef.TextBox.Text = tostring(menuH)
                elseif id == "TrackSpeed" then
                    boxRef.TextBox.Text = tostring(TrackSettings.TrackSpeed)
                end
            end
        end
        if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = EnhancedGrab.Radius.."st" end
        if grabBarRef.rateLbl then grabBarRef.rateLbl.Text = string.format("%.2f", EnhancedGrab.Delay).."s" end
    end)
end

-- ========== [ DISCORD TAG ] ==========
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

-- ========== [ GUI - تم إصلاح اختفاء الأزرار ] ==========
gui = Instance.new("ScreenGui")
gui.Name = "H2N"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  -- ✅ إصلاح ZIndex المينيو
gui.DisplayOrder = 999
gui.Parent = LP:WaitForChild("PlayerGui")
protectGUI(gui)

-- ✅ إرسال أي إشعارات كانت مخزّنة قبل إنشاء gui
task.spawn(function()
    task.wait(0.1)
    for _, msg in ipairs(_notifyQueue) do
        Notify(msg)
        task.wait(0.3)
    end
    _notifyQueue = {}
end)

-- Steal Bar
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

local sbLabel = Instance.new("TextLabel", stealBarFrame)
sbLabel.Size = UDim2.new(0,48,1,0)
sbLabel.BackgroundTransparency = 1
sbLabel.Text = "GRAB"
sbLabel.TextColor3 = Colors.DarkGray
sbLabel.Font = Enum.Font.GothamBold
sbLabel.TextSize = 12
sbLabel.ZIndex = 51

local sbBG = Instance.new("Frame", stealBarFrame)
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

local sbPct = Instance.new("TextLabel", stealBarFrame)
sbPct.Size = UDim2.new(0,34,1,0)
sbPct.Position = UDim2.new(1,-110,0,0)
sbPct.BackgroundTransparency = 1
sbPct.Text = "0%"
sbPct.TextColor3 = Colors.Text
sbPct.Font = Enum.Font.GothamBold
sbPct.TextSize = 11
sbPct.ZIndex = 51

local sbRadius = Instance.new("TextLabel", stealBarFrame)
sbRadius.Size = UDim2.new(0,38,1,0)
sbRadius.Position = UDim2.new(1,-76,0,0)
sbRadius.BackgroundTransparency = 1
sbRadius.Text = EnhancedGrab.Radius .. "st"
sbRadius.TextColor3 = Colors.MediumGray
sbRadius.Font = Enum.Font.GothamBold
sbRadius.TextSize = 11
sbRadius.ZIndex = 51

local sbRate = Instance.new("TextLabel", stealBarFrame)
sbRate.Size = UDim2.new(0,50,1,0)
sbRate.Position = UDim2.new(1,-50,0,0)
sbRate.BackgroundTransparency = 1
sbRate.Text = string.format("%.2f", EnhancedGrab.Delay) .. "s"
sbRate.TextColor3 = Colors.MediumGray
sbRate.Font = Enum.Font.GothamBold
sbRate.TextSize = 10
sbRate.ZIndex = 51

grabBarRef = {
    fill = sbFill,
    pct = sbPct,
    radiusLbl = sbRadius,
    rateLbl = sbRate
}

-- Menu Button — سحب خاص وتوغل صحيح
local menuBtn = Instance.new("Frame", gui)
menuBtn.Size = UDim2.new(0, 100, 0, 45)
menuBtn.Position = UDim2.new(0.5, -50, 0.07, 0)
menuBtn.BackgroundColor3 = Colors.White
menuBtn.BackgroundTransparency = 0.1
menuBtn.Active = true
menuBtn.ZIndex = 60
Instance.new("UICorner", menuBtn).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", menuBtn).Color = Colors.MediumGray

local menuBtnLabel = Instance.new("TextLabel", menuBtn)
menuBtnLabel.Size = UDim2.new(1, 0, 1, 0)
menuBtnLabel.BackgroundTransparency = 1
menuBtnLabel.Text = "H2N"
menuBtnLabel.TextColor3 = Colors.DiscordBlue
menuBtnLabel.Font = Enum.Font.GothamBold
menuBtnLabel.TextSize = 18
menuBtnLabel.ZIndex = 61

-- سحب زر المينيو — يتبع الأصبع اللي عليه فقط
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
        -- toggle فقط لو ما صار سحب
        if not didMove then
            menu.Visible = not menu.Visible
        else
            Save()
        end
    end)
end

-- Menu Frame
menu = Instance.new("Frame", gui)
menu.Size = UDim2.new(0, menuW, 0, menuH)
menu.Position = UDim2.new(0.5, -menuW/2, 0.5, -menuH/2)
menu.AnchorPoint = Vector2.new(0, 0)
menu.BackgroundColor3 = Colors.White
menu.BackgroundTransparency = 0.05
menu.Visible = false
menu.Active = true
menu.ZIndex = 55
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", menu).Color = Colors.MediumGray

-- Header
local header = Instance.new("Frame", menu)
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Colors.White
header.BackgroundTransparency = 0.85
header.BorderSizePixel = 0
header.ZIndex = 56
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local tl = Instance.new("TextLabel", header)
tl.Size = UDim2.new(1,-20,0,30)
tl.Position = UDim2.new(0,10,0,3)
tl.BackgroundTransparency = 1
tl.Text = "H2N ULTIMATE"
tl.TextColor3 = Colors.DiscordBlue
tl.Font = Enum.Font.GothamBold
tl.TextSize = 17
tl.TextXAlignment = Enum.TextXAlignment.Left

-- سحب المينيو — يتبع الأصبع اللي على الهيدر فقط
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

-- Tabs
local tabBar = Instance.new("Frame", menu)
tabBar.Size = UDim2.new(0,110,1,-44)
tabBar.Position = UDim2.new(0,8,0,44)
tabBar.BackgroundColor3 = Colors.White
tabBar.BackgroundTransparency = 0.85
tabBar.ZIndex = 56
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0,10)

local tabNames = {"Combat", "Protect", "Visual", "Settings"}
local tabFrames = {}
local tabBtns = {}

for i, name in ipairs(tabNames) do
    local tb = Instance.new("TextButton", tabBar)
    tb.Size = UDim2.new(1,-12,0,38)
    tb.Position = UDim2.new(0,6,0,(i-1)*44+8)
    tb.BackgroundColor3 = Colors.LightGray
    tb.Text = name
    tb.TextColor3 = Colors.Text
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 14
    tb.ZIndex = 57
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,8)
    tabBtns[name] = tb

    local sf = Instance.new("ScrollingFrame", menu)
    sf.Size = UDim2.new(1,-128,1,-44)
    sf.Position = UDim2.new(0,122,0,44)
    sf.BackgroundTransparency = 1
    sf.Visible = (i == 1)
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Colors.MediumGray
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.ZIndex = 57
    tabFrames[name] = sf

    tb.MouseButton1Click:Connect(function()
        for _, f in pairs(tabFrames) do f.Visible = false end
        for _, b in pairs(tabBtns) do b.BackgroundColor3 = Colors.LightGray end
        sf.Visible = true
        tb.BackgroundColor3 = Colors.MediumGray
    end)
end
tabBtns["Combat"].BackgroundColor3 = Colors.MediumGray

-- ========== [ MAKE TOGGLE ] ==========
local function MakeToggle(parent, text, order, cb, getState, featureName)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-10,0,40)
    row.Position = UDim2.new(0,5,0,order*44+4)
    row.BackgroundTransparency = 1
    row.ZIndex = 58
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.60,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Colors.Text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(0.34,0,0.75,0)
    btn.Position = UDim2.new(0.63,0,0.12,0)
    btn.BackgroundColor3 = Colors.White
    btn.BackgroundTransparency = 0.1
    btn.Text = "OFF"
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", btn).Color = Colors.Border
    
    local function UpdateButton()
        if getState() then
            btn.Text = "ON"
            btn.BackgroundColor3 = Colors.DarkGray
            btn.TextColor3 = Colors.White
        else
            btn.Text = "OFF"
            btn.BackgroundColor3 = Colors.White
            btn.TextColor3 = Colors.Text
        end
    end
    UpdateButton()
    
    btn.MouseButton1Click:Connect(function()
        local newState = not getState()
        cb(newState)
        UpdateButton()
        Save()
    end)

    RunService.RenderStepped:Connect(UpdateButton)
    
    if featureName then
        toggleUpdaters[featureName] = function(state)
            if state then cb(true) else cb(false) end
            UpdateButton()
        end
    end
    
    return btn
end

local function MakeNumberBox(parent, text, default, order, cb, minVal, maxVal, id)
    minVal = minVal or 1
    maxVal = maxVal or 200
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-10,0,40)
    row.Position = UDim2.new(0,5,0,order*44+4)
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.55,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Colors.Text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.36,0,0.75,0)
    box.Position = UDim2.new(0.60,0,0.12,0)
    box.BackgroundColor3 = Colors.White
    box.BackgroundTransparency = 0.1
    box.Text = tostring(default)
    box.TextColor3 = Colors.Text
    box.Font = Enum.Font.GothamBold
    box.TextSize = 16
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", box).Color = Colors.Border
    
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
    row.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.45,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Colors.Text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local keyBtn = Instance.new("TextButton", row)
    keyBtn.Size = UDim2.new(0.2,0,0.75,0)
    keyBtn.Position = UDim2.new(0.45,0,0.12,0)
    keyBtn.BackgroundColor3 = Colors.White
    keyBtn.BackgroundTransparency = 0.1
    keyBtn.Text = Keys[keyName] and Keys[keyName].Name or "?"
    keyBtn.TextColor3 = Colors.Text
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextSize = 12
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", keyBtn).Color = Colors.Border
    
    local enableBtn = Instance.new("TextButton", row)
    enableBtn.Size = UDim2.new(0.2,0,0.75,0)
    enableBtn.Position = UDim2.new(0.68,0,0.12,0)
    enableBtn.BackgroundColor3 = KeyEnabled[keyName] and Colors.Success or Colors.Error
    enableBtn.Text = KeyEnabled[keyName] and "ON" or "OFF"
    enableBtn.TextColor3 = Colors.White
    enableBtn.Font = Enum.Font.GothamBold
    enableBtn.TextSize = 12
    Instance.new("UICorner", enableBtn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", enableBtn).Color = Colors.Border
    
    local listening = false
    local listenConn
    
    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        keyBtn.BackgroundColor3 = Colors.LightGray
        if listenConn then listenConn:Disconnect() end
        listenConn = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Keys[keyName] = input.KeyCode
                keyBtn.Text = input.KeyCode.Name
                keyBtn.BackgroundColor3 = Colors.White
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
        enableBtn.BackgroundColor3 = KeyEnabled[keyName] and Colors.Success or Colors.Error
        Save()
    end)
end

-- ====== COMBAT TAB ======
local ci = 0
local combat = tabFrames["Combat"]

MakeToggle(combat, "AUTO GRAB", ci, function(s) if s then StartEnhancedGrab() else StopEnhancedGrab() end end, function() return EnhancedGrab.Enabled end, "AutoGrab")
ci = ci + 1

MakeNumberBox(combat, "Grab Range", EnhancedGrab.Radius, ci, function(v) 
    EnhancedGrab.Radius = math.clamp(v, 5, 50)
    GrabRadius = EnhancedGrab.Radius
    if grabBarRef.radiusLbl then grabBarRef.radiusLbl.Text = GrabRadius.."st" end
    Notify("Grab Range = " .. GrabRadius)
end, 5, 50, "GrabRadius")
ci = ci + 1

MakeNumberBox(combat, "Grab Speed", EnhancedGrab.Delay, ci, function(v) 
    EnhancedGrab.Delay = math.clamp(v, 0.05, 1.0)
    if grabBarRef.rateLbl then grabBarRef.rateLbl.Text = string.format("%.2f", EnhancedGrab.Delay).."s" end
    Notify("Grab Speed = " .. string.format("%.2f", EnhancedGrab.Delay) .. "s")
end, 0.05, 1.0, "GrabDelay")
ci = ci + 1

MakeToggle(combat, "Auto Track", ci, function(s) if s then StartTrackToggle() else StopTrackToggle() end end, function() return TrackSettings.Enabled end, "AutoTrack")
ci = ci + 1

MakeNumberBox(combat, "Track Speed", TrackSettings.TrackSpeed, ci, function(v)
    TrackSettings.TrackSpeed = math.clamp(v, 1, 300)
    Notify("Track Speed = " .. TrackSettings.TrackSpeed)
end, 1, 300, "TrackSpeed")
ci = ci + 1

MakeToggle(combat, "Auto Play Left", ci, function(s) if s then StartAutoPlayLeft() else StopAutoPlayLeft() end end, function() return State.AutoPlayLeft end, "AutoPlayLeft")
ci = ci + 1

MakeToggle(combat, "Auto Play Right", ci, function(s) if s then StartAutoPlayRight() else StopAutoPlayRight() end end, function() return State.AutoPlayRight end, "AutoPlayRight")
ci = ci + 1

MakeToggle(combat, "Anti Sentry", ci, function(s) if s then StartAntiSentry() else StopAntiSentry() end end, function() return State.AntiSentry end, "AntiSentry")
ci = ci + 1

MakeToggle(combat, "Spin Body", ci, function(s) if s then StartSpinBody() else StopSpinBody() end end, function() return State.SpinBody end, "SpinBody")
ci = ci + 1

MakeToggle(combat, "Speed Boost", ci, function(s) if s then startSpeedBoost() else stopSpeedBoost() end end, function() return isSpeedBoostEnabled end, "SpeedBoost")
ci = ci + 1

MakeNumberBox(combat, "Normal Speed", SpeedSettings.NormalSpeed, ci, function(v) SpeedSettings.NormalSpeed = math.clamp(v,1,200); Notify("Normal Speed = "..SpeedSettings.NormalSpeed) end, 1, 200, "NormalSpeed")
ci = ci + 1

MakeNumberBox(combat, "Steal Speed", SpeedSettings.StealSpeed, ci, function(v) SpeedSettings.StealSpeed = math.clamp(v,1,200); Notify("Steal Speed = "..SpeedSettings.StealSpeed) end, 1, 200, "StealSpeed")
ci = ci + 1

-- ====== PROTECT TAB ======
local pi = 0
local protect = tabFrames["Protect"]

MakeToggle(protect, "Anti Ragdoll", pi, function(s) if s then StartAntiRagdoll() else StopAntiRagdoll() end end, function() return State.AntiRagdoll end, "AntiRagdoll")
pi = pi + 1

MakeToggle(protect, "Infinite Jump", pi, function(s) if s then StartInfiniteJump() else StopInfiniteJump() end end, function() return State.InfiniteJump end, "InfiniteJump")
pi = pi + 1

MakeToggle(protect, "FLOAT", pi, function(s) if s then startFloat() else stopFloat() end end, function() return State.FloatEnabled end, "FloatEnabled")
pi = pi + 1

MakeNumberBox(protect, "Float Height", FloatHeight, pi, function(v) FloatHeight = math.clamp(v, 3, 50); if State.FloatEnabled then stopFloat(); task.wait(0.1); startFloat() end; Notify("Float Height = "..FloatHeight) end, 3, 50, "FloatHeight")
pi = pi + 1

MakeNumberBox(protect, "Float Up Speed", FloatUpSpeed, pi, function(v) FloatUpSpeed = math.clamp(v, 5, 125); Notify("Float Up Speed = "..FloatUpSpeed) end, 5, 125, "FloatUpSpeed")
pi = pi + 1

-- ====== VISUAL TAB ======
local vi = 0
local visual = tabFrames["Visual"]

MakeToggle(visual, "ESP", vi, function(s) if s then StartESP() else StopESP() end end, function() return State.ESP end, "ESP")
vi = vi + 1

MakeToggle(visual, "Xray Base", vi, function(s) if s then StartXrayBase() else StopXrayBase() end end, function() return State.XrayBase end, "XrayBase")
vi = vi + 1

local hideAllState = false
MakeToggle(visual, "Hide All Side Btns", vi, function(state)
    hideAllState = state
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            local id = b:GetAttribute("ID")
            if state then 
                b.Visible = false
                sideHiddenMap[id.."_all"] = true
            else 
                if not sideHiddenMap[id.."_individual"] then 
                    b.Visible = true 
                end
                sideHiddenMap[id.."_all"] = false
            end
        end
    end
    Save()
end, function() return hideAllState end)
vi = vi + 1

local sideNames = {"AUTO PLAY LEFT", "AUTO PLAY RIGHT", "FLOAT", "SPEED BOOST", "AUTO TRACK", "DROP"}
for _, nm in ipairs(sideNames) do
    MakeToggle(visual, "Hide "..nm, vi, function(state)
        sideHiddenMap[nm.."_individual"] = state
        for _, b in pairs(gui:GetChildren()) do
            if b:IsA("Frame") and b.Name == "SideButton" and b:GetAttribute("ID") == nm then
                b.Visible = not state
            end
        end
        Save()
    end, function() return sideHiddenMap[nm.."_individual"] == true end)
    vi = vi + 1
end

MakeToggle(visual, "Show Steal Bar", vi, function(s) StealBarVisible = s; stealBarFrame.Visible = s; Save() end, function() return StealBarVisible end)
vi = vi + 1

MakeNumberBox(visual, "Side Btn Size", SideButtonSize, vi, function(val) 
    SideButtonSize = val
    for _, b in pairs(gui:GetChildren()) do 
        if b:IsA("Frame") and b.Name == "SideButton" then 
            b.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
        end 
    end
end, 40, 150, "SideBtnSize")
vi = vi + 1

MakeNumberBox(visual, "Menu Width", menuW, vi, function(v) menuW = math.clamp(v,200,750); menu.Size = UDim2.new(0,menuW,0,menuH) end, 200, 750, "MenuWidth")
vi = vi + 1

MakeNumberBox(visual, "Menu Height", menuH, vi, function(v) menuH = math.clamp(v,200,750); menu.Size = UDim2.new(0,menuW,0,menuH) end, 200, 750, "MenuHeight")
vi = vi + 1

-- ====== SETTINGS TAB ======
local si = 0
local sTab = tabFrames["Settings"]

local copyBtn = Instance.new("TextButton", sTab)
copyBtn.Size = UDim2.new(1, -10, 0, 40)
copyBtn.Position = UDim2.new(0, 5, 0, si * 44 + 4)
copyBtn.BackgroundColor3 = Colors.LightGray
copyBtn.Text = "COPY DISCORD LINK"
copyBtn.TextColor3 = Colors.Text
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 13
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 8)
copyBtn.MouseButton1Click:Connect(function()
    setclipboard("discord.gg/UeKPQC7fq")
    copyBtn.BackgroundColor3 = Colors.MediumGray
    task.wait(0.5)
    copyBtn.BackgroundColor3 = Colors.LightGray
    Notify("Discord link copied!")
end)
si = si + 1

local sep = Instance.new("TextLabel", sTab)
sep.Size = UDim2.new(1,-10,0,20)
sep.Position = UDim2.new(0,5,0,si*44+4)
sep.BackgroundTransparency = 1
sep.Text = "───────── KEYBINDS ─────────"
sep.TextColor3 = Colors.MediumGray
sep.Font = Enum.Font.GothamBold
sep.TextSize = 12
si = si + 1

MakeKeybind(sTab, "Inf Jump Key (J)", "InfJump", si); si = si + 1
MakeKeybind(sTab, "Auto Left Key (G)", "AutoPlayLeft", si); si = si + 1
MakeKeybind(sTab, "Auto Right Key (H)", "AutoPlayRight", si); si = si + 1
MakeKeybind(sTab, "Anti Ragdoll Key (K)", "AntiRagdoll", si); si = si + 1
MakeKeybind(sTab, "Float Key (F)", "Float", si); si = si + 1
MakeKeybind(sTab, "Speed Boost Key (B)", "SpeedBoost", si); si = si + 1

-- ====== SIDE BUTTONS (6 أزرار - تم إصلاح اختفائها نهائياً) ======
local function CreateSideButton(text, side, index, getState, startFn, stopFn)
    local btn = Instance.new("Frame", gui)
    btn.Name = "SideButton"
    btn:SetAttribute("ID", text)
    btn.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
    btn.BackgroundColor3 = Colors.White
    btn.BackgroundTransparency = 0.05
    btn.Active = true
    btn.ZIndex = 100
    
    local isHidden = sideHiddenMap[text.."_individual"] == true
    btn.Visible = not isHidden

    local saved = ButtonPositions[text]
    if saved then
        btn.Position = UDim2.new(saved.X, saved.XO, saved.Y, saved.YO)
    elseif side == "left" then
        btn.Position = UDim2.new(0, 10, 0.12 + index * 0.17, 0)
    else
        btn.Position = UDim2.new(1, -(SideButtonSize + 10), 0.12 + index * 0.17, 0)
    end

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Colors.Border
    stroke.Thickness = 2

    local lbl = Instance.new("TextLabel", btn)
    lbl.Size = UDim2.new(1, -6, 0.48, 0)
    lbl.Position = UDim2.new(0, 3, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Colors.Text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextWrapped = true

    local descText = ""
    if text == "AUTO PLAY LEFT" then descText = "يسار"
    elseif text == "AUTO PLAY RIGHT" then descText = "يمين"
    elseif text == "FLOAT" then descText = "طفو"
    elseif text == "SPEED BOOST" then descText = "سرعة"
    elseif text == "AUTO TRACK" then descText = "تتبع"
    elseif text == "DROP" then descText = "رمي"
    end

    local desc = Instance.new("TextLabel", btn)
    desc.Size = UDim2.new(1, -6, 0.28, 0)
    desc.Position = UDim2.new(0, 3, 0, 42)
    desc.BackgroundTransparency = 1
    desc.Text = descText
    desc.TextColor3 = Colors.SubText
    desc.Font = Enum.Font.GothamBold
    desc.TextSize = 9
    desc.TextWrapped = true

    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0.5, -6, 1, -14)
    dot.BackgroundColor3 = Colors.DotOff
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local function RefreshVisual()
        if getState() then
            dot.BackgroundColor3 = Colors.DotOn
            btn.BackgroundColor3 = Colors.DarkGray
            lbl.TextColor3 = Colors.White
            desc.TextColor3 = Colors.LightGray
        else
            dot.BackgroundColor3 = Colors.DotOff
            btn.BackgroundColor3 = Colors.White
            lbl.TextColor3 = Colors.Text
            desc.TextColor3 = Colors.SubText
        end
    end

    -- كل متغير محلي لهذا الزر فقط — لا تداخل بين الأزرار
    local pressing = false
    local hasMoved = false
    local dragStart = nil
    local btnStart = nil
    local activeInputId = nil  -- محلي لهذا الزر فقط

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

    btn.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        if input ~= activeInputId then return end
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
    end)

    -- Safety net: لو الإصبع طار برا الزر — موقع فقط، بدون toggle
    UIS.InputEnded:Connect(function(input)
        if not pressing or input ~= activeInputId then return end
        local t = input.UserInputType
        if t ~= Enum.UserInputType.Touch and t ~= Enum.UserInputType.MouseButton1 then return end
        local didMove = hasMoved
        local savedPos = btn.Position
        resetState()
        -- حفظ موقع فقط — بدون toggle هنا عشان btn.InputEnded هو المسؤول
        if didMove then
            ButtonPositions[text] = {X = savedPos.X.Scale, XO = savedPos.X.Offset, Y = savedPos.Y.Scale, YO = savedPos.Y.Offset}
            Save()
        end
        -- لو ما تحرك ونطّ برا الزر، نسكت — ما نسوي toggle
    end)

    RunService.RenderStepped:Connect(RefreshVisual)
end

-- إنشاء الأزرار الجانبية (6 أزرار)
CreateSideButton("AUTO PLAY LEFT", "left", 0, function() return State.AutoPlayLeft end, StartAutoPlayLeft, StopAutoPlayLeft)
CreateSideButton("AUTO PLAY RIGHT", "left", 1, function() return State.AutoPlayRight end, StartAutoPlayRight, StopAutoPlayRight)
CreateSideButton("FLOAT", "right", 0, function() return State.FloatEnabled end, startFloat, stopFloat)
CreateSideButton("SPEED BOOST", "right", 1, function() return isSpeedBoostEnabled end, startSpeedBoost, stopSpeedBoost)
-- Speed Boost مخفي — ما يظهر للمستخدم
do
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        task.defer(function()
            for _, b in pairs(gui:GetChildren()) do
                if b:IsA("Frame") and b.Name == "SideButton" and b:GetAttribute("ID") == "SPEED BOOST" then
                    b.Visible = false
                end
            end
        end)
    end
end
CreateSideButton("AUTO TRACK", "right", 2, function() return TrackSettings.Enabled end, StartTrackToggle, StopTrackToggle)
CreateSideButton("DROP", "right", 3, function() return false end, executeDrop, function() end)

-- ====== MAIN HEARTBEAT ======
RunService.Heartbeat:Connect(function(dt)
    -- Auto Duel يعمل في task.spawn منفصل (بدون لاق)
    if State.AntiSentry then updateAntiSentry() end
    if State.ESP then updateESP() end
end)

-- ====== INIT ======
Load()
initWPParts()
stealBarFrame.Visible = StealBarVisible
menu.Size = UDim2.new(0, menuW, 0, menuH)

-- ✅ إصلاح اختفاء الأزرار: التأكد من ظهورها وضبطها
for _, b in pairs(gui:GetChildren()) do
    if b:IsA("Frame") and b.Name == "SideButton" then
        b.Size = UDim2.new(0, SideButtonSize, 0, SideButtonSize)
        local id = b:GetAttribute("ID")
        local sp = ButtonPositions[id]
        if sp then
            b.Position = UDim2.new(sp.X, sp.XO, sp.Y, sp.YO)
        end
        -- ✅ التأكيد على ظهور الزر (ما لم يتم إخفاؤه يدوياً)
        if sideHiddenMap[id.."_individual"] == true then
            b.Visible = false
        else
            b.Visible = true
        end
    end
end

if EnhancedGrab.Enabled then
    task.spawn(function()
        task.wait(3)
        EnhancedGrab.Enabled = false
        StartEnhancedGrab()
        print("✅ Auto Grab activated from save")
    end)
end

if TrackSettings.Enabled then
    task.spawn(function()
        task.wait(2.5)
        StartTrackToggle()
        print("✅ Auto Track activated from save")
    end)
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
    
    local savedSentry    = State.AntiSentry
    local savedSpin      = State.SpinBody
    local savedRagdoll   = State.AntiRagdoll
    local savedJump      = State.InfiniteJump
    local savedFloat     = State.FloatEnabled
    local savedXray      = State.XrayBase
    local savedESP       = State.ESP
    local savedSpeed     = isSpeedBoostEnabled
    local savedAutoLeft  = State.AutoPlayLeft
    local savedAutoRight = State.AutoPlayRight
    local savedGrab      = EnhancedGrab.Enabled
    local savedTrack     = TrackSettings.Enabled

    State.AntiSentry     = false
    State.SpinBody       = false
    State.InfiniteJump   = false
    State.FloatEnabled   = false
    State.XrayBase       = false
    State.ESP            = false
    State.AntiRagdoll    = false
    State.AutoPlayLeft   = false
    State.AutoPlayRight  = false
    isSpeedBoostEnabled  = false
    EnhancedGrab.Enabled  = false
    TrackSettings.Enabled = false

    local function safeStart(fn, name)
        task.spawn(function()
            pcall(function()
                fn()
                print("✅ تم تفعيل تلقائياً: " .. name)
            end)
        end)
        task.wait(0.05)
    end

    if savedSentry    then safeStart(StartAntiSentry,    "Anti Sentry")    end
    if savedSpin      then safeStart(StartSpinBody,      "Spin Body")      end
    if savedRagdoll   then safeStart(StartAntiRagdoll,   "Anti Ragdoll")   end
    if savedJump      then safeStart(StartInfiniteJump,  "Infinite Jump")  end
    if savedFloat     then safeStart(startFloat,         "Float")          end
    if savedXray      then safeStart(StartXrayBase,      "Xray Base")      end
    if savedESP       then safeStart(StartESP,           "ESP")            end
    if savedSpeed     then safeStart(startSpeedBoost,    "Speed Boost")    end
    if savedAutoLeft  then safeStart(StartAutoPlayLeft,  "Auto Play Left") end
    if savedAutoRight then safeStart(StartAutoPlayRight, "Auto Play Right")end
    if savedGrab      then safeStart(StartEnhancedGrab,  "Auto Grab")      end
    if savedTrack     then safeStart(StartTrackToggle,   "Auto Track")     end
    
    task.wait(0.3)
    for _, b in pairs(gui:GetChildren()) do
        if b:IsA("Frame") and b.Name == "SideButton" then
            local id = b:GetAttribute("ID")
            if id == "AUTO PLAY LEFT" then
                b.BackgroundColor3 = State.AutoPlayLeft and Colors.DarkGray or Colors.White
            elseif id == "AUTO PLAY RIGHT" then
                b.BackgroundColor3 = State.AutoPlayRight and Colors.DarkGray or Colors.White
            elseif id == "FLOAT" then
                b.BackgroundColor3 = State.FloatEnabled and Colors.DarkGray or Colors.White
            elseif id == "SPEED BOOST" then
                b.BackgroundColor3 = isSpeedBoostEnabled and Colors.DarkGray or Colors.White
            elseif id == "AUTO TRACK" then
                b.BackgroundColor3 = TrackSettings.Enabled and Colors.DarkGray or Colors.White
            end
        end
    end
    
    task.wait(0.2)
    if toggleUpdaters["AntiRagdoll"] then toggleUpdaters["AntiRagdoll"](State.AntiRagdoll) end
    if toggleUpdaters["InfiniteJump"] then toggleUpdaters["InfiniteJump"](State.InfiniteJump) end
    if toggleUpdaters["FloatEnabled"] then toggleUpdaters["FloatEnabled"](State.FloatEnabled) end
    if toggleUpdaters["SpeedBoost"] then toggleUpdaters["SpeedBoost"](isSpeedBoostEnabled) end
    if toggleUpdaters["AutoTrack"] then toggleUpdaters["AutoTrack"](TrackSettings.Enabled) end
    if toggleUpdaters["AutoGrab"] then toggleUpdaters["AutoGrab"](EnhancedGrab.Enabled) end
    if toggleUpdaters["AntiSentry"] then toggleUpdaters["AntiSentry"](State.AntiSentry) end
    if toggleUpdaters["SpinBody"] then toggleUpdaters["SpinBody"](State.SpinBody) end
    if toggleUpdaters["XrayBase"] then toggleUpdaters["XrayBase"](State.XrayBase) end
    if toggleUpdaters["ESP"] then toggleUpdaters["ESP"](State.ESP) end
    if toggleUpdaters["AutoPlayLeft"] then toggleUpdaters["AutoPlayLeft"](State.AutoPlayLeft) end
    if toggleUpdaters["AutoPlayRight"] then toggleUpdaters["AutoPlayRight"](State.AutoPlayRight) end
end)

Notify("H2N Ultimate | ✅ Menu Fixed | ✅ ZIndex Fixed | ✅ All Features")
print("=" .. string.rep("=", 65))
print("✅ H2N ULTIMATE - ZIndex & Menu FIXED")
print("1. ✅ Menu visible - ZIndexBehavior + DisplayOrder=999")
print("2. ✅ Notify forward declaration - no crash before GUI")
print("3. ✅ Touch support for menu open/drag")
print("4. ✅ Auto Play Left/Right saved states restored")
print("5. ✅ Auto Grab + Auto Track saved states restored")
print("6. ✅ Save system - UNCHANGED")
print("=" .. string.rep("=", 65))
print("📌 KEYBINDS:")
print("✓ G = Auto Play Left | H = Auto Play Right | F = Float")
print("✓ B = Speed Boost | J = Infinite Jump | K = Anti Ragdoll")
print("=" .. string.rep("=", 65))