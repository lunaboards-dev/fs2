local usb = {}
local musb = require "moonusb"
local input_raw = require "input_raw"

local dev = {}

local req_size = 256

function usb.start(_dev, devh)
	devh:reset_device()
	--local desc, config = usb.get_dev_desc(_dev, devh)
	--for k, v in pairs(config.interface[1][1].endpoint[1]) do print(k, v) end
	local desc, config = _dev:get_device_descriptor(), _dev:get_active_config_descriptor()
	local devo = {
		dev = _dev,
		hand = devh,
		inpipe = config.interface[1][1].endpoint[1],
		outpipe = nil, -- ???
		desc = desc,
		config = config
	}
	print(devo.dev)
	return setmetatable(devo, {__index=dev})
end

function dev:get_interrupt_transfer(size)
	local ptr = musb.malloc(self.hand, size)
	self.hand:interrupt_transfer(self.inpipe.address, ptr:ptr(), type(size) == "number" and size or #size, 0)
	local dat = ptr:read()
	ptr:free()
	return dat
end

function dev:get_vendor_request(size, req, idx, data)
	local ptr = musb.malloc(self.hand, 8+size)
	ptr:write(0, nil, string.rep("\xff", 8+size))
	--if data then ptr:write(8, nil, data) end
	musb.encode_control_setup(ptr:ptr(), {
		request_type = "vendor",
		request_recipient = "endpoint",
		direction = "in",
		request = req,
		index = idx,
		length = size,
		value = 0
	})
	--print(ptr:ptr())
	self.hand:control_transfer(ptr:ptr(), 8+size, 0)
	local ret = ptr:read()
	ptr:free()
	return ret
end

local inputs = {}

function dev:worker()
	local ir = self:get_interrupt_transfer(input_raw.ir:packsize())
	local vr00 = self:get_vendor_request(input_raw.vr00:packsize(), 0, 1, "\xff")
	local vr01 = self:get_vendor_request(input_raw.vr01:packsize(), 1, 1, "\xff")
	--local vr02 = self:get_vendor_request(input_raw.vr01:packsize(), 2, 1)
	--print(ir, vr00, vr01)
	-- parse
	local stick_x, stick_y, rudder, throttle, hat_x, hat_y, button_a, button_b = input_raw.ir:unpack(ir)
	--print(stick_x, stick_y, rudder, throttle, hat_x, hat_y, button_a, button_b)
	local vr00_1, vr00_2 = input_raw.vr00:unpack(vr00:sub(9))
	local vr01_1, vr01_2 = input_raw.vr01:unpack(vr01:sub(9))
	--local inputs = {
	inputs.stick = {
		x = stick_x,
		y = stick_y
	}
	inputs.rudder = rudder
	inputs.throttle = throttle
	inputs.hat = {
		x = hat_x,
		y = hat_y
	}
	inputs.a = button_a
	inputs.b = button_b
	inputs.buttons = {}
	--}

	inputs.buttons.a = (inputs.a < 200) and 0 or 1
	inputs.buttons.a_hard = (inputs.a < 100) and 0 or 1

	inputs.buttons.b = (inputs.b < 200) and 0 or 1
	inputs.buttons.b_hard = (inputs.b < 100) and 0 or 1

	inputs.buttons.c = vr00_1 & 1
	inputs.buttons.d = (vr00_1 >> 1) & 1
	inputs.buttons.hat_press = (vr00_1 >> 2) & 1
	inputs.buttons.button_st = (vr00_1 >> 3) & 1
	inputs.buttons.dpad1_top = (vr00_1 >> 4) & 1
	inputs.buttons.dpad1_right = (vr00_1 >> 5) & 1
	inputs.buttons.dpad1_bottom = (vr00_1 >> 6) & 1
	inputs.buttons.dpad1_left = (vr00_1 >> 7) & 1

	inputs.buttons.launch = (vr00_2 >> 5) & 1
	inputs.buttons.trigger = (vr00_2 >> 6) & 1

	inputs.buttons.dpad3_right = (vr01_1 >> 4) & 1
	inputs.buttons.dpad3_middle = (vr01_1 >> 5) & 1
	inputs.buttons.dpad3_left = (vr01_1 >> 6) & 1

	inputs.mode_select = (vr01_2) & 3
	inputs.buttons.sw1 = (vr01_2 >> 3) & 1
	inputs.buttons.dpad2_top = (vr01_2 >> 4) & 1
	inputs.buttons.dpad2_right = (vr01_2 >> 5) & 1
	inputs.buttons.dpad2_bottom = (vr01_2 >> 6) & 1
	inputs.buttons.dpad2_left = (vr01_2 >> 7) & 1

	print("stick", inputs.stick.x, inputs.stick.y)
	print("hat", inputs.hat.x, inputs.hat.y)
	print("rudder", inputs.rudder)
	print("throttle", inputs.throttle)
	print("a", inputs.a)
	print("b", inputs.b)
	print("mode_select", inputs.mode_select)

	local buttons = {}
	for k, v in pairs(inputs.buttons) do table.insert(buttons, k) end
	local things = {}
	for i=1, #buttons do
		if inputs.buttons[buttons[i]] == 0 then
			table.insert(things, buttons[i])
		end
	end
	print(table.unpack(things))
	print("================================")
	return inputs
end

return usb