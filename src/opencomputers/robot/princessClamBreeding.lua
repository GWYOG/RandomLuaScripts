-- *****************************************
-- ******* Copyright GWYOG(JJN) 2016 *******
-- *****************************************
--
-- This script is for Open Computers' robot to breed princess clam from Apple Milk Tea automatically.
-- Before running this script, you should put 56(can be configured in this script) sands in the robot's 1st slot,
-- a sand with a weak clam in the 15th slot and a sand with a princess clam in the 16th slot.
-- (these two blocks can be harvested by any tool with a silk touch enchantment)
-- Also, you should place some clams in the robot's equipment slot.   
-- The breeding area should be like this pattern (in this example, the area is 5*3)
-- 		SSSSS
-- 		SSSSS
-- 		SSSSS
-- , in which 'S' represents the sand with a clam. 
-- (Actually, there's no need to place these things manually, since the robot will do so.)
-- (The only thing you need to do is placing water block on the top of these sands with clams.)
-- The robot should be placed beneath the pattern's right-down corner's sand.
-- The robot should be placed facing the front area and you should place a chest behind the robot with some clams
-- in order to provide new clams and store the princess clam.
-- Also, it's highly recommended to place some sands in the chest in case of emergency. 
--
-- Have fun!


local robot = require("robot")
local computer = require("computer")
local component = require("component")
local shell = require("shell")
local ic = component.inventory_controller
local tb = component.tractor_beam

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
local sandCount = 56
local sandFlag = false
local beamFlag = false
local exitFlag = false

-- check if there's a chest in front of the robot
local function checkChestExist()
	chestSlotCount = ic.getInventorySize(3)
	if chestSlotCount == nil then
		print("Error: No storage chest was found.")
		print("Logging debug message...")
		print("Current Cycle: "..cycleCount)
		print("Current Step: "..stepCount)
		print("Logging Done.")
		print("Program will exit automatically.")
		exitFlag = true
		return false
	else
		return true
	end
end

-- unload items from the robot to the storage chest
local function unloadItems()
	-- unload extra sands in the first slot 
		stack = ic.getStackInInternalSlot(1)
		if stack and stack.size > sandCount then
			robot.drop(stack.size - sandCount)
		end
	-- unload from 2nd slot to 13th slot
	for slot = 2,13 do 
		stack = ic.getStackInInternalSlot(slot)
		-- unload robot's internal inventory
		if stack then
			robot.select(slot)
			robot.drop()
		end
		-- unload robot's equipment
		robot.select(2)
		ic.equip()
		robot.drop()
	end
end

-- load sands from the storage chest to the robot's 1st slot
local function loadSands()
	--load as many sands as possible (but must no more than 'sandCount')
	local robotSandCount = 0
	local sandStack = ic.getStackInInternalSlot(1)
	if sandStack then
		robotSandCount = sandStack.size
	end
	if robotSandCount >= sandCount then
		return
	end
	robot.select(1)
	chestSlotCount = ic.getInventorySize(3)
	for slot = 1,chestSlotCount do
		stack = ic.getStackInSlot(3,slot)
		if stack and stack.name == "minecraft:sand" then
			if stack.size + robotSandCount >= sandCount then
				ic.suckFromSlot(3, slot, sandCount-robotSandCount)
				return
			else
				robotSandCount = robotSandCount + stack.size
				ic.suckFromSlot(3,slot,stack.size)
			end
		end
	end
end

-- load items from the storage chest to the robot
local function loadClams()
	--load as many clams as possible (but must less than a full stack)
	local robotClamCount = 0
	robot.select(2)
	chestSlotCount = ic.getInventorySize(3)
	for slot = 1,chestSlotCount do
		stack = ic.getStackInSlot(3,slot)
		if stack and stack.name == "DCsAppleMilk:defeatedcrow.clam" then
			if stack.size + robotClamCount >= 64 then
				ic.suckFromSlot(3, slot, 64-robotClamCount)
					-- equip the clams 
					robot.select(2)
					ic.equip()
				return
			else
				robotClamCount = robotClamCount + stack.size
				ic.suckFromSlot(3,slot,stack.size)
			end
		end
	end
end

-- judge if the robot has walk over all the field
-- sorry since I can't come up with a better name 
local function isFinished()
	if stepCount == maxStep then
		return true
	else
		return false
	end
end

-- if there's a sand on the robot's way, remove it!
local function forceForward()
	robot.select(1)
	if beamFlag == true then
		tb.suck()
		if ic.getStackInInternalSlot(1).size >= sandCount then
			beamFlag = false
		end
	end
	if robot.compare() then
		robot.swing()
		sandFlag = true
	end
	-- make sure the robot does move forward in this function
	while true do 
		if robot.forward() then
			break
		end
	end
end

-- judge whether the robot should turn right when it's leaving the working area
local function judgeTurnRight()
	-- leftSideLength is odd or even leads to different judgement. 
	if leftSideLength % 2 == 1	then
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

-- robot moves to the next block
local function moveToNext()
	if isFinished() then
		-- check if the robot has gone back to the recharge point
		if cycleCount % 2 == 0 then
			if checkChestExist() then 
				unloadItems()
				loadSands()
				loadClams()
				os.sleep(2)
			else
				return
			end
		end
		-- robot move
		robot.turnAround()
		forceForward()
		-- update varibles
		stepCount = 2
		cycleCount = cycleCount + 1
	else
		-- check if the robot will leave the working area
		if stepCount % frontLength == 0 then
			if judgeTurnRight() then
				robot.turnRight()
				forceForward()
				robot.turnRight()
			else
				robot.turnLeft()
				forceForward()
				robot.turnLeft()
			end
		else 
			forceForward()
		end
		stepCount = stepCount + 1
	end
end

-- this function's name is self-explain
local function placeSandWithClam()
	robot.select(1)
	robot.placeUp()
	robot.useUp()
end

-- act on the block above the robot
local function actionOnBlock()
	if sandFlag then
		placeSandWithClam()
		sandFlag = false
	else
		-- judge if sand is falling while robot move forward first
		-- str == "air" means the robot is initializing the area
		bool, str = robot.detectUp()
		if str == "liquid" or str == "air" then 
			placeSandWithClam()
			beamFlag = true
		else
			local flag = false
			robot.select(15)
			flag = robot.compareUp()
			robot.select(16)
			flag = flag or robot.compareUp() 
			-- get the weak clam out of the sand and put it into the sand again
			-- or harvest the princess clam
			if flag then 	
				robot.select(9)
				ic.equip()
				robot.useUp()
				ic.equip()
				robot.useUp()
			end
		end
	end
end

while not exitFlag do
	actionOnBlock()
	moveToNext()
end