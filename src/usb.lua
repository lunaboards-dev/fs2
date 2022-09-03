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

function dev:get_vendor_request(size, req, idx)
	local ptr = musb.malloc(self.hand, 8+size)
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

function dev:worker()
	local ir = self:get_interrupt_transfer(input_raw.ir:packsize())
	local vr00 = self:get_vendor_request(input_raw.vr00:packsize(), 0, 1)
	local vr01 = self:get_vendor_request(input_raw.vr01:packsize(), 1, 1)
	--local vr02 = self:get_vendor_request(input_raw.vr01:packsize(), 2, 1)
	--print(ir, vr00, vr01)
	-- parse
	local stick_x, stick_y, rudder, throttle, hat_x, hat_y, button_a, button_b = input_raw.ir:unpack(ir)
	print(stick_x, stick_y, rudder, throttle, hat_x, hat_y, button_a, button_b)
end

return usb