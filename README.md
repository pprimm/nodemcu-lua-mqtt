
nodemcu-lua-mqtt
===========
Lua scripts for Nodemcu mostly testing MQTT protocol and CoAP (planned upon future Lua release by Nodemcu).  Please use at will to jump start your MQTT prototyping on the Nodemcu platform.  I use the following tools for Nodemcu and Lua:

 - [Nodemcu Lua API Reference](https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en)
 - [Nodemcu Flasher for firmware updates](https://github.com/nodemcu/nodemcu-flasher)
 - [Lua Uploader for Windows](https://github.com/hwiguna/g33k/tree/master/ArduinoProjects/Windows/ESP8266_Related)

> *A note on Nodemcu firmware*

> I have been unable to get the majority of my Lua test code to work properly on any Nodemcu firmware version after Version 0.9.5 build 20150127.  Issues with later firmware version have ranged from connection errors with broker to crashes of various sorts.  These Lua test scripts will probably only run on firmware **Version 0.9.5 build 20150127**!

mqtt_test.lua
----------------
This lua script creates an MQTT accessible counter service.  A service is defined as:

-  a list of ***get*** topics which indicate the service ***state***; observable by all MQTT clients
-  a list of ***set*** topics for requesting ***state*** be set to particular values; writable by all MQTT clients
-  a list of ***RPC*** topics for performing direct method calls on the service; responses are directed a calling MQTT client

> *Service API*
> 
> - **status**: state variable to show whether offline or online (enhanced by use of Last Will Testament)
> - **counterValue**: main state variable with value of counter (read: get/ESP8266/counterValue) (write: set/ESP8266/counterValue).  The allow value is clipped at 0..100.  The counterValue will cycle up/down between 0 and 100; inc/dec by 1 every second.
> - **counterCmd**: this set topic will control whether the counter goes up or down.  Allowed values are "up" or "down"
> - **echo**:  whatever you write to the set topic gets echoed to the get topic (read: get/ESP8266/echo) (write: set/ESP8266/echo)

The script also handles reconnecting to the MQTT broker after loss of connection.  

There is a bit of code that needs a little explanation: it's the following section for handeling subscribing to a MQTT topic in the connect callback:

```
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
```
The alarm timer callback is used to subscribe to the *set/ESP8266/#* topic from within the onConnect MQTT callback.  If I called the subscribe() function inline in the onConnect callback, the ESP8266 would crash on an stdin error.  I tried several different methods for triggering the subscribe whenever the MQTT client connects without success until I "decoupled" the subscribe() call from the callback(s) that were performing other MQTT calls.  This, I believe, is a bug; as one should be able to make a series of MQTT calls from the onConnect callback.

I hope this test script helps you do effective IoT prototyping with the Nodemcu.