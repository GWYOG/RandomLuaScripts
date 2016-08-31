-- *****************************************
-- ******* Copyright GWYOG(JJN) 2016 *******
-- *****************************************
--
-- This script is for Open Computers' robot to milk the cow automatically.
-- You should put a empty bucket in the robot's equipment slot.
-- A cow should be stuck in front of the robot.
-- The robot will try to milk the cow and fill up the tank above itself. 
-- If the tank is full, the robot will stop milking.
--
-- Have fun!


local robot = require("robot")
local component = require("component")
local tc = component.tank_controller

while true do 
	tankCapacity = tc.getTankCapacity(1)
	if tankCapacity == 0 then
		os.sleep(1)
	else
		tankLevel = tc.getTankLevel(1)
		if tankLevel <= tankCapacity - 1000 then
			robot.use()
			robot.useUp()
		end
	end
end
