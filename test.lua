local gamestage = workspace.GameStage
local ball = gamestage.Ball
local RunService = game:GetService("RunService")

local killPlates = {}
local plates = {}

local RING_HEIGHT = 15
local SLOT_COUNT = 14
local SLOT_ANGLE = (2 * math.pi) / SLOT_COUNT

local FALL_COOLDOWN = 0.6
local CENTER_TOL = math.rad(9)

local GRAVITY = workspace.Gravity
local measuredGravity = GRAVITY

local function angleToSlotOf(a)
    if a < 0 then a += 2 * math.pi end
    return math.floor((a / SLOT_ANGLE) + 0.5) % SLOT_COUNT
end

local function angleToSlot(x, z)
    return angleToSlotOf(math.atan2(z, x))
end

local function updatePlates()
	killPlates = {}
	plates = {}
	for i, v in pairs(gamestage:GetChildren()) do
		if v:IsA("BasePart") and (v.Name == "KillPlate" or v.Name == "MovingPlate") then
			table.insert(killPlates, v)
		end
		if v:IsA("BasePart") and v.Name == "Segment" then
			table.insert(plates, v)
		end
	end
end

local function detectLayer()
	local closestLayer = nil
    local closestDistance = math.huge
	for _, segment in ipairs(plates) do
		local y = segment.CFrame.Position.Y
		if y > ball.CFrame.Position.Y then
			continue
		end
        local deltaY = ball.CFrame.Position.Y - y
        if deltaY < closestDistance then
            closestDistance = deltaY
            closestLayer = segment.CFrame.Position.Y
        end
	end
	return closestLayer
end

local function detectThreats(layerY)
    local threats = {}
    for _, plate in ipairs(killPlates) do
        local y = plate.CFrame.Position.Y
        if math.abs(y - layerY) < 5 then
            table.insert(threats, plate)
        end
    end
    return threats
end

local function detectSegments(layerY)
    local segments = {}
    for _, segment in ipairs(plates) do
        local y = segment.CFrame.Position.Y
        if math.abs(y - layerY) < 5 then
            table.insert(segments, segment)
        end
    end
    return segments
end

local function detectGap(layerY)
    local occupied = {}
    for _, segment in ipairs(plates) do
        local y = segment.CFrame.Position.Y
        if math.abs(y - layerY) < 5 then
            occupied[angleToSlot(segment.CFrame.Position.X, segment.CFrame.Position.Z)] = true
        end
    end

    local gaps = {}
    for slot = 0, SLOT_COUNT - 1 do
        if occupied[slot] then
            continue
        end
        local entry = {
            slot   = slot,
            angle  = slot * SLOT_ANGLE,
            unsafe = false,
        }
        for _, plate in ipairs(killPlates) do
            local py = plate.CFrame.Position.Y
            if math.abs(py - layerY) < 5
                and angleToSlot(plate.CFrame.Position.X, plate.CFrame.Position.Z) == slot then
                entry.unsafe = true
                break
            end
        end
        table.insert(gaps, entry)
    end
    return gaps
end

-- ============================
-- MATH HELPERS
-- ============================
local function normalizeAngle(a)
    return ((a % (2 * math.pi)) + 2 * math.pi) % (2 * math.pi)
end

local function signedDiff(a, b)
    return ((b - a + math.pi) % (2 * math.pi)) - math.pi
end

local function ballAngle()
    return math.atan2(ball.Position.Z, ball.Position.X)
end

local function angleOfPos(x, z)
    return math.atan2(z, x)
end

local function referenceAngle()
    local layerY = detectLayer()
    if not layerY then
        return nil
    end
    local ba = ballAngle()
    local best = math.huge
    local bestA = nil
    for _, seg in ipairs(plates) do
        local y = seg.CFrame.Position.Y
        if math.abs(y - layerY) < 5 then
            local s = signedDiff(ba, angleOfPos(seg.CFrame.Position.X, seg.CFrame.Position.Z))
            local dist = math.abs(s)
            if dist < best then
                best = dist
                bestA = angleOfPos(seg.CFrame.Position.X, seg.CFrame.Position.Z)
            end
        end
    end
    for _, g in ipairs(detectGap(layerY)) do
        local s = signedDiff(ba, g.angle)
        local dist = math.abs(s)
        if dist < best then
            best = dist
            bestA = g.angle
        end
    end
    return bestA
end

local function angleInRange(a, rangeStart, rangeEnd)
    local na = normalizeAngle(a)
    local ns = normalizeAngle(rangeStart)
    local ne = normalizeAngle(rangeEnd)
    if ns <= ne then
        return na >= ns and na <= ne
    else
        return na >= ns or na <= ne
    end
end

-- ============================
-- LOOKAHEAD: what the ball hits below
-- ============================
-- time for the ball to free-fall `dist` studs starting at downward speed `v`
local function fallTime(dist, v)
    if v < 0 then v = 0 end
    local g = measuredGravity
    local disc = v * v + 2 * g * dist
    return (-v + math.sqrt(disc)) / g
end

-- Y of the ring immediately below layerY (or nil)
local function layerBelow(layerY)
    local best = nil
    for _, seg in ipairs(plates) do
        local y = seg.CFrame.Position.Y
        if y < layerY - RING_HEIGHT * 0.5 and (not best or y > best) then
            best = y
        end
    end
    return best
end

-- what occupies a slot on a given layer: "plate", "segment", or "gap"
local function slotFeature(layerY, slot)
    for _, pl in ipairs(killPlates) do
        if math.abs(pl.CFrame.Position.Y - layerY) < 5
            and angleToSlotOf(angleOfPos(pl.CFrame.Position.X, pl.CFrame.Position.Z)) == slot then
            return "plate"
        end
    end
    for _, seg in ipairs(plates) do
        if math.abs(seg.CFrame.Position.Y - layerY) < 5
            and angleToSlotOf(angleOfPos(seg.CFrame.Position.X, seg.CFrame.Position.Z)) == slot then
            return "segment"
        end
    end
    return "gap"
end

-- Effort adjustment (radians, + = worse) for falling through the gap at angle g
-- on layer `ly` while the ball is already falling at downward speed v0 and the
-- tower spins at vel deg/s. The ball falls straight down at a fixed world angle,
-- but the rings keep rotating while it drops, so the slot it lands on 1 and 2
-- rings below is offset by the drift (vel * fall time). Steers away from plates:
--   * land on a segment  -> safe rest, speed resets       (big bonus)
--   * land in a gap      -> ball keeps falling (speeds up) (penalty)
--   * land on a plate    -> death                          (huge penalty)
-- Never blocks: a lethal gap just becomes the last resort.
local function landingPenalty(g, ly, v0, vel)
    local below1 = layerBelow(ly)
    if not below1 then
        return 0
    end
    local t1 = fallTime(RING_HEIGHT, v0)
    local slot1 = angleToSlotOf(g - math.rad(vel) * t1)
    local f1 = slotFeature(below1, slot1)
    if f1 == "plate" then
        return math.rad(400)
    elseif f1 == "segment" then
        -- safe landing: prefer resting, but avoid resting directly above a plate
        local pen = -math.rad(60)
        local below2 = layerBelow(below1)
        if below2 and slotFeature(below2, slot1) == "plate" then
            pen = pen + math.rad(40)
        end
        return pen
    end
    -- gap below: the ball keeps falling through ring below1, check ring below2
    local below2 = layerBelow(below1)
    if not below2 then
        return 0
    end
    local t2 = fallTime(RING_HEIGHT, v0 + measuredGravity * t1)
    local slot2 = angleToSlotOf(g - math.rad(vel) * (t1 + t2))
    local f2 = slotFeature(below2, slot2)
    if f2 == "plate" then
        return math.rad(200)
    elseif f2 == "segment" then
        return 0
    end
    return math.rad(100)
end

-- debug: what the ball will land on 1 and 2 rings below the gap at angle g
local function landingSummary(g, ly, v0, vel)
    local below1 = layerBelow(ly)
    if not below1 then
        return "no-layer-below"
    end
    local t1 = fallTime(RING_HEIGHT, v0)
    local drift1 = math.rad(vel) * t1
    local slot1 = angleToSlotOf(g - drift1)
    local s = string.format("drift=%+.1f slot%d=%s", math.deg(drift1), slot1, slotFeature(below1, slot1))
    local below2 = layerBelow(below1)
    if below2 then
        local t2 = fallTime(RING_HEIGHT, v0 + measuredGravity * t1)
        local slot2 = angleToSlotOf(g - math.rad(vel) * (t1 + t2))
        s = s .. string.format(" slot%d=%s", slot2, slotFeature(below2, slot2))
    end
    return s
end

-- debug: print the slot layout of the ring at `ly` and below, plus every
-- active plate with its slot / angle / Y so the map can be reconstructed.
local function dumpMap(ly)
    local dly = ly
    for depth = 0, 3 do
        if not dly then break end
        local parts = {}
        for slot = 0, SLOT_COUNT - 1 do
            table.insert(parts, slotFeature(dly, slot):sub(1, 1))
        end
        print(string.format("[dbg] LAYER y=%d | %s", dly, table.concat(parts, " ")))
        dly = layerBelow(dly)
    end
    local s = ""
    for _, pl in ipairs(killPlates) do
        if pl.CFrame.Position.Y < -500 then
            continue
        end
        local pa = angleOfPos(pl.CFrame.Position.X, pl.CFrame.Position.Z)
        s = s .. string.format(" [slot=%d %+05.1fdeg y=%.0f]", angleToSlotOf(pa), math.deg(pa), pl.CFrame.Position.Y)
    end
    print("[dbg] PLATES:" .. (s == "" and " none" or s))
end

-- True if rotating the ring to bring targetAng under the ball's fixed angle ba
-- does NOT sweep any plate under ba (no plate strictly between ba and target).
local function pathSafe(ba, targetAng, plateAngs)
    local dT = signedDiff(ba, targetAng)
    for _, p in ipairs(plateAngs) do
        local dp = signedDiff(ba, p)
        if math.abs(dp) < math.abs(dT) and (dp * dT) > 0 then
            return false
        end
    end
    return true
end

-- Route to bring targetAng under the ball's fixed angle ba.
-- Checks BOTH arcs: the short way and the long way around the ring.
-- Returns: reachable, goLeft (true=left key), effortRad (rotation needed).
-- A gap is reachable if either arc has no plate under the ball.
local function gapRoute(ba, targetAng, plateAngs, rotSign)
    local dT = signedDiff(ba, targetAng)
    local absT = math.abs(dT)

    -- short arc blocked by a plate strictly between ba and target?
    local shortBlocked = false
    for _, p in ipairs(plateAngs) do
        local dp = signedDiff(ba, p)
        if math.abs(dp) < absT and (dp * dT) > 0 then
            shortBlocked = true
            break
        end
    end
    if not shortBlocked then
        -- short way: ring rotates by (ba - targetAng) = -dT
        local wantSign = -((dT >= 0) and 1 or -1)
        return true, (wantSign == rotSign), absT
    end

    -- long arc = the rest of the circle; a plate on the long arc blocks it.
    -- A plate is on the long arc iff it is NOT on the short arc.
    local longBlocked = false
    for _, p in ipairs(plateAngs) do
        local dp = signedDiff(ba, p)
        if math.abs(dp) < absT and (dp * dT) > 0 then
            -- on short arc -> not on long arc
        else
            longBlocked = true
            break
        end
    end
    if not longBlocked then
        -- long way: rotate the opposite direction
        local wantSign = ((dT >= 0) and 1 or -1)
        return true, (wantSign == rotSign), (2 * math.pi - absT)
    end

    return false, nil, nil
end

-- ============================
-- KEY INFRASTRUCTURE
-- ============================
local keyMethods = {}
if type(keypress) == "function" then
    keyMethods.keypress = {
        down = function(k) keypress(k) end,
        up = function(k) keyrelease(k) end,
    }
end
pcall(function()
    local vim = game:GetService("VirtualInputManager")
    if vim and vim.SendKeyEvent then
        keyMethods.vim = {
            down = function(k) vim:SendKeyEvent(true, k, false, game) end,
            up = function(k) vim:SendKeyEvent(false, k, false, game) end,
        }
    end
end)

local LEFT  = { Enum.KeyCode.A, Enum.KeyCode.Left }
local RIGHT = { Enum.KeyCode.D, Enum.KeyCode.Right }

local holding = nil

local function releaseKeys()
    if not holding then return end
    for _, k in ipairs(holding == "left" and LEFT or RIGHT) do
        for _, m in pairs(keyMethods) do
            pcall(m.up, k)
        end
    end
    holding = nil
end

local function holdKeys(dir)
    if holding == dir then return end
    releaseKeys()
    for _, k in ipairs(dir == "left" and LEFT or RIGHT) do
        for _, m in pairs(keyMethods) do
            pcall(m.down, k)
        end
    end
    holding = dir
end

-- ============================
-- CALIBRATION STATE
-- ============================
local calibrated = false
local rotSign = 1
local calStep = 0
local calRef = 0
local calHoldUntil = 0
local calAttempt = 0
local fallUntil = 0

-- debug / velocity state
local debugLastPrint = 0
local prevRefAngle = nil
local prevRefTime = 0
local velTower = 0
local evadeDir = nil
local prevLayerY = nil
local prevBallY = nil
local detailDumpTime = 0
local riskLogTime = 0
local deathDumpTime = 0
local calRefPart = nil
local velRefPart = nil
local velRefLayer = nil
local prevTarget = nil
local lastHeartTime = 0
local ballVy = 0
local prevVy = 0
local forcedLeft = nil
local forcedLayer = nil
local backoutDir = nil

RunService.Heartbeat:Connect(function()
	ball = gamestage:FindFirstChild("Ball")
	if not ball or not ball:IsA("BasePart") then
		return
	end
	updatePlates()

    if not calibrated then
        if calStep == 0 then
            local clayer = detectLayer()
            local csegs = clayer and detectSegments(clayer) or {}
            calRefPart = csegs[1]
            calRef = calRefPart and angleOfPos(calRefPart.CFrame.Position.X, calRefPart.CFrame.Position.Z) or nil
            holdKeys("left")
            calHoldUntil = tick() + 0.25
            calStep = 1
        elseif tick() >= calHoldUntil then
            local ref2 = nil
            if calRefPart and calRefPart.Parent then
                ref2 = angleOfPos(calRefPart.CFrame.Position.X, calRefPart.CFrame.Position.Z)
            end
            releaseKeys()
            local d = 0
            if calRef and ref2 then
                d = math.deg(signedDiff(calRef, ref2))
            end
            if math.abs(d) < 0.5 and calAttempt < 3 then
                calAttempt += 1
                calStep = 0
            else
                rotSign = (d >= 0) and 1 or -1
                calibrated = true
                print("calibrated: left key moves ring by " .. string.format("%+.0f", d) .. " deg -> rotSign=" .. rotSign)
            end
        end
        return
    end

    local layerY = detectLayer()
    if not layerY then
        releaseKeys()
        return
    end
    local segments = detectSegments(layerY)
    local threats = detectThreats(layerY)
    local gaps = detectGap(layerY)

    local ba = ballAngle()
    local now = tick()

    -- tower angular velocity from a FIXED segment instance (ring rotation),
    -- not from the nearest feature to the ball (which stays ~constant).
    -- Reset only when the ring actually changes (layer wobbles a few studs
    -- from resting jitter must NOT reset the reference, or vel is always 0).
    if not velRefPart or not velRefPart.Parent or math.abs((velRefLayer or 0) - layerY) > RING_HEIGHT * 0.5 then
        velRefPart = segments[1]
        velRefLayer = layerY
        prevRefAngle = nil
    end
    local ref = nil
    if velRefPart then
        ref = angleOfPos(velRefPart.CFrame.Position.X, velRefPart.CFrame.Position.Z)
    end
    if ref then
        if prevRefAngle then
            local dt = now - prevRefTime
            if dt > 0.0001 then
                local inst = math.deg(signedDiff(prevRefAngle, ref)) / dt
                if math.abs(inst) < 720 then
                    velTower = velTower * 0.3 + inst * 0.7
                end
            end
        end
        prevRefAngle = ref
        prevRefTime = now
    else
        prevRefAngle = nil
        velTower = 0
    end

    if prevLayerY and layerY ~= prevLayerY then
        if now - debugLastPrint > 0.5 then
            debugLastPrint = now
            print(string.format("[dbg] >>> NEW LAYER Y=%.0f (was %.0f) ball=%.0f deg ballY=%.0f <<<",
                layerY, prevLayerY, math.deg(ba), ball.Position.Y))
        end
    end
    if prevBallY and ball.Position.Y < prevBallY - RING_HEIGHT * 0.5 then
        print(string.format("[dbg] >>> BALL DROPPED Y=%.0f -> %.0f <<<", prevBallY, ball.Position.Y))
    end
    local dtH = now - lastHeartTime
    if lastHeartTime > 0 and dtH > 0.0001 and dtH < 0.5 then
        ballVy = math.max(0, (prevBallY - ball.Position.Y) / dtH)
        if ballVy > 10 and ballVy > prevVy and ballVy < 600 then
            local gEst = (ballVy - prevVy) / dtH
            if gEst > 40 and gEst < 600 then
                measuredGravity = measuredGravity * 0.85 + gEst * 0.15
            end
        end
        prevVy = ballVy
    end
    lastHeartTime = now
    prevLayerY = layerY
    prevBallY = ball.Position.Y

    -- PLATE-RISK monitor: the ball is in the column of a plate on (or just
    -- below) the ring it is at / falling toward. This catches the crash live.
    if now - riskLogTime > 0.2 then
        for _, pl in ipairs(killPlates) do
            local py = pl.CFrame.Position.Y
            if ball.Position.Y > py - 4 and ball.Position.Y < py + RING_HEIGHT * 0.8 then
                local pAng = angleOfPos(pl.CFrame.Position.X, pl.CFrame.Position.Z)
                if math.abs(signedDiff(ba, pAng)) < math.rad(5) then
                    riskLogTime = now
                    local rState = (ballVy > 15) and "FALLING" or "RESTING"
                    print(string.format("[dbg] PLATE-RISK %s ball@%+05.1fdeg over plate@%+05.1fdeg slot=%d plateY=%.0f ballY=%.0f vy=%.0f vel=%+.0f tg=%s hold=%s",
                        rState, math.deg(ba), math.deg(pAng), angleToSlotOf(pAng),
                        py, ball.Position.Y, ballVy, velTower,
                        prevTarget and string.format("%.0f", math.deg(prevTarget)) or "none",
                        tostring(holding)))
                    if rState == "RESTING" and now - deathDumpTime > 2 then
                        deathDumpTime = now
                        dumpMap(layerY)
                    end
                    break
                end
            end
        end
    end

    -- never steer while the ball is airborne: holding a key mid-fall spins the
    -- ring under the falling ball and drags it into plates.
    if ballVy > 20 then
        releaseKeys()
        return
    end

    -- angular data for the current ring
    local segAngs = {}
    for _, seg in ipairs(segments) do
        table.insert(segAngs, angleOfPos(seg.CFrame.Position.X, seg.CFrame.Position.Z))
    end
    local plateAngs = {}
    for _, pl in ipairs(threats) do
        table.insert(plateAngs, angleOfPos(pl.CFrame.Position.X, pl.CFrame.Position.Z))
    end
    local gapAngs = {}
    for _, g in ipairs(gaps) do
        if not g.unsafe then
            table.insert(gapAngs, g.angle)
        end
    end

    local function angleNear(ang, list, tol)
        for _, a in ipairs(list) do
            if math.abs(signedDiff(ba, a)) < tol then
                return true
            end
        end
        return false
    end

    local THREAT_TOL = SLOT_ANGLE * 0.4
    local SLOT_TOL = CENTER_TOL

    -- BACKOUT: if a plate is dangerously close to the ball's angle while the
    -- ball is caged, rotating toward any gap drags the plate under the ball
    -- (death by drag-onto-plate). Instead, rotate AWAY from the nearest plate
    -- until there is real clearance (hysteresis 12 deg in / 25 deg out, so it
    -- cannot oscillate). If a gap is already under the ball, drop through it.
    local nearP, nearD = nil, math.huge
    for _, p in ipairs(plateAngs) do
        local dp = math.abs(signedDiff(ba, p))
        if dp < nearD then
            nearD = dp
            nearP = p
        end
    end
    if nearP and (nearD < math.rad(12) or backoutDir) then
        local overGap = angleNear(ba, gapAngs, SLOT_TOL)
        if overGap then
            releaseKeys()
            return
        end
        if not backoutDir then
            local dp = signedDiff(ba, nearP)
            local awaySign = (dp >= 0) and 1 or -1
            backoutDir = (awaySign == rotSign) and "left" or "right"
        end
        holdKeys(backoutDir)
        if now - riskLogTime > 0.2 then
            riskLogTime = now
            print(string.format("[dbg] BACKOUT plate@%+.1fdeg (%.0fdeg) -> %s | vel=%+.0f ba=%+.0f",
                math.deg(nearP), math.deg(nearD), backoutDir, velTower, math.deg(ba)))
        end
        if nearD > math.rad(25) then
            backoutDir = nil
        end
        return
    end
    backoutDir = nil

    local plateAtBall = angleNear(ba, plateAngs, THREAT_TOL)
    local plateTrigger = nil
    if plateAtBall then
        local bd = math.huge
        for _, p in ipairs(plateAngs) do
            local d = math.abs(signedDiff(ba, p))
            if d < bd then bd = d; plateTrigger = p end
        end
    end

    if plateAtBall then
        -- danger: a plate is under (or about to be under) the ball.
        -- bring the nearest segment under the ball along a plate-free path.
        local target, targetD = nil, math.huge
        for _, s in ipairs(segAngs) do
            local d = math.abs(signedDiff(ba, s))
            if d < targetD and pathSafe(ba, s, plateAngs) then
                targetD = d
                target = s
            end
        end
        if not target then
            -- no plate-free segment path; rotate AWAY from the nearest plate so
            -- the ball is not dragged onto it
            local away = (signedDiff(ba, plateTrigger or 0) >= 0) and -1 or 1
            for _, s in ipairs(segAngs) do
                local dp = signedDiff(ba, s)
                local d = math.abs(dp)
                if (dp * away) > 0 and d < targetD then
                    targetD = d
                    target = s
                end
            end
            if not target then
                for _, s in ipairs(segAngs) do
                    local d = math.abs(signedDiff(ba, s))
                    if d < targetD then
                        targetD = d
                        target = s
                    end
                end
            end
        end
        if target then
            local off = signedDiff(ba, target)
            local want = ((rotSign * off) > 0) and "left" or "right"
            if not evadeDir or (want ~= evadeDir and math.abs(off) > math.rad(8)) then
                evadeDir = want
            end
            holdKeys(evadeDir)
            if now - debugLastPrint > 0.5 then
                debugLastPrint = now
                print(string.format("[dbg] EVADE plate@%.0f -> seg@%.0f off=%+.0f -> %s | Y=%.0f ba=%.0f",
                    math.deg(plateTrigger or 0), math.deg(target), math.deg(off), evadeDir,
                    ball.Position.Y, math.deg(ba)))
            end
        else
            releaseKeys()
        end
        return
    end
    evadeDir = nil

    -- falling through a gap: release and let the ball drop
    local gapAtBall = angleNear(ba, gapAngs, SLOT_TOL)
    if gapAtBall then
        releaseKeys()
        return
    end

    -- pick the best reachable gap (short or long arc), re-selected EVERY frame.
    -- Bias toward the previous target's region so we keep following the SAME
    -- moving gap instead of flipping between two equidistant gaps (which makes
    -- the ring oscillate and wastes time at the gap edge).
    local bestGap, bestEffort, bestGoLeft = nil, math.huge, nil
    for _, g in ipairs(gapAngs) do
        local reachable, goLeft, effort = gapRoute(ba, g, plateAngs, rotSign)
        if reachable then
            if prevTarget and math.abs(signedDiff(prevTarget, g)) < math.rad(12) then
                effort = effort - math.rad(25)
            end
            effort = effort + landingPenalty(g, layerY, ballVy, velTower)
            if effort < bestEffort then
                bestEffort = effort
                bestGap = g
                bestGoLeft = goLeft
            end
        end
    end
    if bestGap then
        -- a normal route exists: clear the caged-direction latch
        forcedLeft = nil
        forcedLayer = nil
        backoutDir = nil
    end

    -- FALLBACK: if every gap is path-blocked (ball caged between plates), the
    -- rotating-ring route is impossible, so we must cross a plate. The ball
    -- survives plate sweeps but gets DRAGGED onto the nearest plate over time,
    -- so rotate AWAY from the nearest plate. CRITICALLY, LATCH the direction:
    -- re-picking every frame makes the ring oscillate in place next to a plate
    -- (stuck on edges) until the ball is dragged onto it. Commit to one way
    -- until the cage opens or the layer changes. Never blocks.
    if not bestGap then
        local bestScore = math.huge
        if forcedLayer ~= layerY then
            forcedLeft = nil
            forcedLayer = layerY
        end
        local choose = nil
        if forcedLeft ~= nil then
            -- keep rotating the latched direction; target the nearest gap that way
            local bd2 = math.huge
            for _, g in ipairs(gapAngs) do
                local s = signedDiff(ba, g)
                local wantSign = -((s >= 0) and 1 or -1)
                local gLeft = (wantSign == rotSign)
                if gLeft == forcedLeft and math.abs(s) < bd2 then
                    bd2 = math.abs(s)
                    choose = g
                end
            end
        end
        if not choose then
            -- first caged frame: pick the gap with the most plate-free clearance
            for _, g in ipairs(gapAngs) do
                local s = signedDiff(ba, g)
                local d = math.abs(s)
                local dir = (s >= 0) and 1 or -1
                local clearance = math.huge
                for _, p in ipairs(plateAngs) do
                    local dp = signedDiff(ba, p)
                    if (dp * dir) > 0 and math.abs(dp) < d then
                        clearance = math.min(clearance, math.abs(dp))
                    end
                end
                local score = d
                if clearance < d then
                    score = d + (d - clearance)
                end
                if score < bestScore then
                    bestScore = score
                    choose = g
                end
            end
        end
        if choose then
            bestGap = choose
            local s = signedDiff(ba, choose)
            local wantSign = -((s >= 0) and 1 or -1)
            bestGoLeft = (wantSign == rotSign)
            if forcedLeft == nil then
                forcedLeft = bestGoLeft
            end
        end
        if bestGap then
            local ds = {}
            for _, g in ipairs(gapAngs) do
                local s = signedDiff(ba, g)
                local d = math.abs(s)
                local dir = (s >= 0) and 1 or -1
                local cl = math.huge
                for _, p in ipairs(plateAngs) do
                    local dp = signedDiff(ba, p)
                    if (dp * dir) > 0 and math.abs(dp) < d then
                        cl = math.min(cl, math.abs(dp))
                    end
                end
                table.insert(ds, string.format("%.0f/%.0f/%.0f", math.deg(g), math.deg(d), math.deg(cl == math.huge and 999 or cl)))
            end
            local ps = {}
            for _, p in ipairs(plateAngs) do
                table.insert(ps, string.format("%.0f", math.deg(p)))
            end
            print(string.format("[dbg] FORCED gap=%.0f (rot=%.0f dir=%s) ba=%+.0f vel=%+.0f vy=%.0f | gaps=%s | plates=%s",
                math.deg(bestGap), math.deg(math.abs(signedDiff(ba, bestGap))), forcedLeft and "L" or "R", math.deg(ba), velTower, ballVy,
                table.concat(ds, ","), #ps > 0 and table.concat(ps, ",") or "none"))
        end
    end

    local target, toGap, goLeft
    if bestGap then
        target = bestGap
        goLeft = bestGoLeft
        toGap = signedDiff(ba, target)
    else
        target = nil
        toGap = 0
        goLeft = true
    end
    prevTarget = bestGap

    if now - detailDumpTime > 5 then
        detailDumpTime = now
        dumpMap(layerY)
        print(string.format("[dbg] ball=%+05.1fdeg y=%.0f vy=%.0f vel=%+.0f g=%.0f layerY=%d",
            math.deg(ba), ball.Position.Y, ballVy, velTower, measuredGravity, layerY))
    end

    -- release only when the gap center is under the ball, so the ball falls
    -- through the MIDDLE of the gap, not the edge
    local centered = target and math.abs(toGap) <= CENTER_TOL
    if centered then
        releaseKeys()
        print(string.format("[dbg] RELEASE gap=%+05.1f toGap=%+.0f vel=%+.0f vy=%.0f | %s | lay=%.0f ba=%+05.1f",
            math.deg(target), math.deg(toGap), velTower, ballVy,
            landingSummary(target, layerY, ballVy, velTower),
            layerY, math.deg(ba)))
        fallUntil = tick() + FALL_COOLDOWN
        return
    end

    if tick() < fallUntil then
        releaseKeys()
        return
    end

    if not target then
        releaseKeys()
        return
    end

    -- steer toward the gap (rotate ring so gap center reaches ball)
    holdKeys(goLeft and "left" or "right")
end)
