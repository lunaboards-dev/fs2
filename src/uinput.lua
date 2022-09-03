local e = require "evdev"

local gp = e.Uinput()

gp:useEvent(e.EV_KEY)
gp:useEvent(e.EV_ABS)
gp:useAbsAxis(e.ABS_X, -128, 127)
gp:useAbsAxis(e.ABS_Y, -128, 127)
gp:useAbsAxis(e.ABS_RX, -128, 127)
gp:useAbsAxis(e.ABS_RY, -128, 127)
gp:useAbsAxis(e.ABS_RUDDER, -128, 127)
gp:useAbsAxis(e.ABS_THROTTLE, 0, 255)
gp:useAbsAxis(e.ABS_HAT1X, -1, 1)
gp:useAbsAxis(e.ABS_HAT1Y, -1, 1)
gp:useAbsAxis(e.ABS_HAT2X, -1, 1)
gp:useAbsAxis(e.ABS_HAT2Y, -1, 1)

gp:useKey(e.BTN_TRIGGER)
gp:useKey(e.BTN_THUMB)
gp:useKey(e.BTN_A)
gp:useKey(e.BTN_B)
gp:useKey(e.BTN_X)
gp:useKey(e.BTN_Y)
gp:useKey(e.BTN_C)
gp:useKey(e.BTN_BASE)
gp:useKey(e.BTN_THUMBL)
gp:useKey(e.BTN_TRIGGER_HAPPY)
gp:useKey(e.BTN_TRIGGER_HAPPY1)
gp:useKey(e.BTN_TRIGGER_HAPPY2)

gp:init("HORI FlightStick 2")

local button_map = {
	a = e.BTN_A,
	b = e.BTN_B,
	c = e.BTN_X,
	d = e.BTN_Y,
	launch = e.BTN_C,
	trigger = e.BTN_TRIGGER,
	sw1 = e.BTN_BASE,
	button_st = e.BTN_THUMBL,
	hat_press = e.BTN_THUMB
}

local mode_map = {
	e.BTN_TRIGGER_HAPPY,
	e.BTN_TRIGGER_HAPPY1,
	e.BTN_TRIGGER_HAPPY2
}

local function hat_axis(left, right)
	return (1-left)-(1-right)
end

local hat_map = {
	[e.ABS_HAT1X] = {"dpad1_left", "dpad1_right"},
	[e.ABS_HAT1Y] = {"dpad1_top", "dpad1_bottom"},
	[e.ABS_HAT2X] = {"dpad2_left", "dpad2_right"},
	[e.ABS_HAT2Y] = {"dpad2_top", "dpad2_bottom"}
}

local function update(state)
	for k, v in pairs(button_map) do
		gp:write(e.EV_KEY, v, 1-state.buttons[k])
	end
	for i=1, #mode_map do
		gp:write(e.EV_KEY, mode_map[i], state.mode_select == i and 1 or 0)
	end
	for k, v in pairs(hat_map) do
		gp:write(e.EV_ABS, k, hat_axis(state.buttons[v[1]], state.buttons[v[2]]))
	end
	gp:write(e.EV_ABS, e.ABS_X, state.stick.x-128)
	gp:write(e.EV_ABS, e.ABS_Y, state.stick.y-128)
	gp:write(e.EV_ABS, e.ABS_RX, state.hat.x-128)
	gp:write(e.EV_ABS, e.ABS_RY, state.hat.y-128)
	gp:write(e.EV_ABS, e.ABS_RUDDER, state.rudder-128)
	gp:write(e.EV_ABS, e.ABS_THROTTLE, state.throttle)
	gp:write(e.EV_SYN, e.SYN_REPORT, 0)
end

return update