-- *****************************************
-- ******* Copyright GWYOG(JJN) 2016 *******
-- *****************************************
--
-- This script is for Open Computers' robot to harvest crops such as wheats or carrots automatically.
-- EnderCore or other mods that can let players harvest crops by right-clicking must be installed.
-- The farmland is a rectangle and the robot should be placed above the right-down corner's crop
-- Farmland pattern (for example 3*4)
--      FFFF
--      FFFF
--      FFFF
-- The robot should be placed facing the farmland (in this example, there's two 'F' in front of it)
-- A chest should be placed behind the robot. 
-- And a Open Computers' recharger should be placed on the right side of the robot.
--
-- Have fun!

local robot = require("robot")
local shell = require("shell")

-- load arguments
local args, options = shell.parse(...)
if #args < 2 then
    io.write("Usage: princessClamBreeding <front length> <left side length>\n")
    io.write("'front length' is the length of the field which in front of the robot.")
    io.write("'left side length' is the length of the field which on the left side of the robot.")
    return
end

local frontLength = tonumber(args[1])
local leftSideLength = tonumber(args[2])
if not frontLength or not leftSideLength then
    io.stderr:write("invalid size")
    return
end

-- initialize varibles
local stepCount = 1
local cycleCount = 1
local maxStep = frontLength * leftSideLength

-- judge if robot has walked over all the area
local function isFinished()
    if stepCount == maxStep then
        return true
    else
        return false
    end
end

-- unload all the items to the chest from the internal inventory of the robot
local function unloadItems()
    for slot = 1,16 do 
        robot.select(slot)
        robot.drop()
    end
    robot.select(1)
end

-- judge whether the robot should turn right when it's leaving the working area
local function judgeTurnRight()
    -- leftSideLength is odd or even leads to different judgement. 
    if leftSideLength % 2 == 1    then
        if stepCount % (2 * frontLength) == 0 then
            return true
        else
            return false
        end
    else
        if cycleCount % 2 == 1 and stepCount % (2 * frontLength) == 0 then
            return true
        elseif cycleCount % 2 == 0 and stepCount % (2 * frontLength) ~= 0 then
            return true
        else 
            return false
        end
    end
end

-- looping until robot has moved forward
local function robotForward()
    while true do 
        if robot.forward() then
            break
        end
    end
end

-- robot moves to it's next position
local function moveToNext()
    if isFinished() then
        -- check if the robot has gone back to the recharge point
        if cycleCount % 2 == 0 then
            unloadItems()
            os.sleep(10)
        end
        -- update varibles
        stepCount = 2
        cycleCount = cycleCount + 1
        -- robot move
        robot.turnAround()
        robotForward()
    else
        -- check if the robot will leave the working area
        if stepCount % frontLength == 0 then
            if judgeTurnRight() then
                robot.turnRight()
                robotForward()
                robot.turnRight()
            else
                robot.turnLeft()
                robotForward()
                robot.turnLeft()
            end
        else 
            robotForward()
        end
        stepCount = stepCount + 1
    end
end

-- harvest the crops
local function harvestCrops()
    robot.useDown()
    -- No need to absorb the items on the ground because Ender Core has been installed 
    -- so the items will directly go into the robot's inventory after the crop being harvested
end

while true do
    harvestCrops()
    moveToNext()
end