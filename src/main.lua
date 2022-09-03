local usb = require("moonusb")
local usblib = require("usb")

--usb.trace_objects(true)
local ctx = usb.init()

-- replace this with values from one of your devices:
local vendor_id, product_id = 0x06d3, 0x0f10

local device, devhandle = ctx:open_device(vendor_id, product_id)
local dev = usblib.start(device, devhandle)
while true do dev:worker() end