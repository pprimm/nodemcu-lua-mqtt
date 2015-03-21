-- https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en


mOnline = 0
m = mqtt.Client("ESP8266_dev", 120)

m:on("connect", function(con)
	mOnline = 1
	print("connected")
end)

m:on("offline", function(con)
	mOnline = 0
	print("offline")
end)


-- Blink using timer alarm --
timerId = 0 -- we have seven timers! 0..6
interval = 1000 -- milliseconds
counter = 0

tmr.alarm(timerId, interval, 1, function()
	counter = counter + 1
	-- print(wifi.sta.status())
	if wifi.sta.status() == 5 then
		if mOnline == 1 then
			-- print("send msg")
			m:publish("get/ESP8266/counter", counter , 0, 0)
		else
			print("connect")
			m:connect("10.10.101.24", 1883)
		end
	end
end)

tmr.alarm(1, 60000, 1, function()
   print(wifi.sta.status())
   print(mOnline);
end)
