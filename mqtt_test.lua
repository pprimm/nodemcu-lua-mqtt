-- https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en
mqttOnline = false
mqttSubSuccess = false
COUNTER_CMD_UP = "up"
counterUp = true
COUNTER_MAX = 100
COUNTER_MIN = 0
counter = 0

-- timer vars
mainTimerId = 0 -- we have seven timers! 0..6
mainInterval = 1000 -- milliseconds
statusTimerID = 1
statusInterval = 10000
hackTimerID = 2
hackTimerInterval = 100
-- client ID, keepalive (seconds), user, password
m = mqtt.Client("ESP8266_dev", 30)

m:lwt("get/ESP8266/status", "offline", 0, 0)

m:on("connect", function(con)
   print("connected")
   mqttOnline = true
   m:publish("get/ESP8266/status", "online", 0, 1)
   -- hack to prevent stdio bomb calling subscribe in this callback
   tmr.alarm(hackTimerID, hackTimerInterval, 0, function()
      m:subscribe("set/ESP8266/#",0, function(con)
         print("subscribe success")
         mqttSubSuccess = true
      end)
   end)
end)

m:on("offline", function(con)
   print("offline")
   mqttOnline = false
   mqttSubSuccess = false
end)

counterValueGetTopic = "get/ESP8266/counterValue"
counterValueSetTopic = "set/ESP8266/counterValue"
function counterValueGetReceived(msg)
   newValue = tonumber(msg)
   if newValue ~= nil then
      counter = newValue
   end
end

counterCmdSetTopic = "set/ESP8266/counterCmd"
function counterCmdReceived(msg)
   if msg == COUNTER_CMD_UP then
      counterUp = true
   else
      counterUp = false
   end
end

echoGetTopic = "get/ESP8266/echo"
echoSetTopic = "set/ESP8266/echo"
function echoReceived(msg)
   if msg ~= nil then
      m:publish(echoGetTopic, msg, 0, 0)
   end
end

m:on("message", function(con, topic, msg)
   print("callback "..topic..":"..msg)
   if topic == echoSetTopic then
      echoReceived(msg)
   elseif topic == counterCmdSetTopic then
      counterCmdReceived(msg)
   elseif topic == counterValueSetTopic then
      counterValueGetReceived(msg)
   end
end)

function updateCounter()
   if counter >= COUNTER_MAX then
      counter = COUNTER_MAX
      counterUp = false
   elseif counter <= COUNTER_MIN then
      counter = COUNTER_MIN
      counterUp = true
   end
   if counterUp then
      counter = counter + 1
   else
      counter = counter - 1
   end
end

function updateMQTT()
   if wifi.sta.status() == 5 then
      if mqttOnline then
         m:publish(counterValueGetTopic, counter, 0, 0)
      else
         print("calling m:connect()")
         m:connect("10.10.101.24", 1883)
      end
   end
end

tmr.alarm(mainTimerId, mainInterval, 1, function()
   -- counter updates whether online or not
   updateCounter()
   updateMQTT()
end)

-- print status of wifi and online every 10 sec --
tmr.alarm(statusTimerID, statusInterval, 1, function()
   print("wifi status:"..wifi.sta.status()..", MQTT Online:"..tostring(mqttOnline))
end)