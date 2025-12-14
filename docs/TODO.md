# TODO make-homekit32

---

### NEW: Set Onboard LED
Check out if there is an onboard led.
Use like
```
OnboardLed.Initialize(ONBOARDLED_PIN, OnboardLed.MODE_OUTPUT)
OnboardLed.DigitalWrite(False)
Log("[DeviceMgr.InitDevices] OnboardLed OK")
```
#### Status
Not started.

### NEW: Home Assistant Client
Develop simple Home Assistant (HA) client using MQTT protocol.
Consider creating MQTT Autodiscovery Topics.
Example from [HomeAssistant Workbook Experiments](github.com/rwbl/Home-Assistant-Workbook-Experiments) experiment **50-Hawe_LegoTrain**.
- Syntax configuration topic: homeassistant/component/entity_name/config
- Syntax state topic: hawe/legotrain/control/state , with control like speed, headlights
- Syntax command topic: hawe/legotrain/control/set , with control like speed, headlights
- Check the MQTT discovery created entities in HA: http://NNN.NNN.NNN.NNN:8123/config/entities

```
' SPEED CONTROL
' Light switch to control the speed
' Important color_mode is brightness only as used to set the speed
Private MQTT_CONFIG_TOPIC_SPEED As String = "homeassistant/light/hawe_legotrain_speed/config"
Private MQTT_CONFIG_PAYLOAD_SPEED As String = _
	"{" _
	  """name"":""HaWe LegoTrain Speed""," _
	  """object_id"":""hawe_legotrain_speed""," _
	  """unique_id"":""hawe_legotrain_speed""," _
	  """schema"":""json""," _
	  """state_topic"":""hawe/legotrain/speed/state""," _
	  """command_topic"":""hawe/legotrain/speed/set""," _
	  """brightness"":true," _
	  """supported_color_modes"":[""brightness""]," _
	  """device_class"":""light""," _  
	  """device"":{""identifiers"":[""legotrain""],""name"":""Hawe LEGO Train""}" _
	"}"
Private MQTT_STATE_TOPIC_SPEED As String	= "hawe/legotrain/speed/state"
Private MQTT_COMMAND_TOPIC_SPEED As String	= "hawe/legotrain/speed/set"
```
#### Status
Not started.

### UPD: Blockly Client
The Blockly client is experimental.
Enhancements:
- Menubar with File (open, save, export [JSON format]), Tools (clear), Help
- Custom Blocks: BLE_Connect
#### Status
Not started.



