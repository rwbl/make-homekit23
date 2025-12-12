
## Overview
HomeKit32 Blockly Integration in B4J

Project Overview:
This B4J project integrates Google Blockly as a visual programming interface to control HomeKit32 devices. It allows users to drag-and-drop blocks representing devices (LEDs, sensors, DHT11, etc.), control device states, and send commands to a B4J backend.

Key Features:

Custom Blockly Blocks:

Device blocks (e.g., yellow_led_on/off, DHT11_sensor) with real-time state indicators.

Standard blocks like delay, connect, log.

Start and stop blocks to define the execution flow.

Asynchronous Command Execution:

Blocks generate async JavaScript functions.

Commands are sent to B4J via a centralized sendCommandToB4JAsync function, using redirected alert() messages in the WebView.

B4J parses commands in WebViewBlockly_Event, allowing logging, LED control, and sensor updates.

Real-time Device State Feedback:

Device state updates propagate from B4J to the Blockly workspace using custom JS functions like updateDeviceState('yellow_led', 'ON').

Sensor blocks (e.g., DHT11) update dynamically, including color changes based on thresholds.

Workspace Persistence:

Users can save and load Blockly workspace layouts via the system clipboard.

B4J buttons replace HTML buttons, calling JS functions (saveWorkspace, loadWorkspace) using WebView.executeScript.

Base64 encoding ensures safe transfer of XML workspace data between B4J and Blockly.

Technical Highlights:

Uses JavaObject in B4J to access the WebView engine and execute JS scripts.

Async block execution ensures sequential processing without freezing the GUI.

Fully modular JS architecture:

blockly_custom_blocks.js – custom device blocks

blockly_standard_blocks.js – standard blocks like delay and log

blockly_generators.js – block-to-code generation

blockly_device_states.js – dynamic state updates

Challenges and Solutions:

JS Alert Redirection: Since JavaFX WebView has limited JS dialog support, a custom sendCommandToB4JAsync function handles communication.

Async Execution & B4J: Async JavaScript functions execute blocks sequentially while ensuring B4J receives messages correctly.

Clipboard-based Workspace Management: Avoids browser security issues with direct file access, enabling reliable save/load operations.

Conclusion:
This solution enables a fully interactive visual programming environment for HomeKit32 devices directly within B4J. It bridges Blockly’s powerful visual interface with real-time device control, providing a robust framework for home automation experiments, learning, and prototyping.


## Blocks
Now that the variable dialog is working, the next big steps could be:

Add more HomeKit32-specific blocks (e.g., lights, shades, sensors).

Save/restore workspaces seamlessly in XML or JSON.

Execute complex sequences using repeat/while loops, conditions, and maybe custom functions.

Integrate BLE/HomeKit command conversion in a separate JS/B4J module.

Optional: Visual indicators in Blockly for device states (LED on/off, sensor triggered).

If you want, we can start building the next standard HomeKit32 block, like “turn red LED on/off” or “toggle a device,” using the same async queue pattern you have. That way you can slowly grow your control library without breaking what’s already working.


## Blockly Colors

| State / Device                | Suggested Hue | Color           | Notes                 |
| ----------------------------- | ------------- | --------------- | --------------------- |
| **Yellow LED off**            | 60            | Yellow          | Default LED color     |
| **Yellow LED on**             | 90            | Greenish-yellow | Shows active/on state |
| **Red LED / alert**           | 0             | Red             | Danger / triggered    |
| **Green LED / ok**            | 120           | Green           | Normal operation      |
| **Blue LED / info**           | 240           | Blue            | Informational state   |
| **Humidity high (DHT11)**     | 30            | Orange          | Warning threshold     |
| **Humidity normal**           | 60            | Yellow          | Safe range            |
| **Temperature high**          | 0             | Red             | Overheat alert        |
| **Temperature normal**        | 120           | Green           | Safe operating temp   |
| **Sensor inactive / off**     | 30–60         | Orange-Yellow   | Visual inactive       |
| **Sensor active / triggered** | 0             | Red             | Visual alert          |

## HTML Button Actions


Private Sub ButtonSave_Click
	AppLog($"[Button_Save] Start"$)

	Dim engine As JavaObject = GetEngine(WebViewBlockly)

	' Execute JS to get workspace XML
	Dim workspace As String = engine.RunMethod("executeScript", Array("saveWorkspace()"))
	AppLog($"[Button_Save] workspace=${workspace}"$)

	If workspace <> Null And workspace.Length > 0 Then
        
		' Save to file
		Try
			File.WriteString(File.DirApp, WORKSPACE_DEFAULT_FILE , workspace)
			AppLog($"[Button_Save] Workspace saved to ${WORKSPACE_DEFAULT_FILE }"$)
		Catch
			AppLog($"[Button_Save] Cannot save workspace: ${LastException}"$)
		End Try
	End If
End Sub

Sub ButtonLoad_Click
	If Not(File.Exists(File.DirApp, WORKSPACE_DEFAULT_FILE )) Then
		AppLog($"[Button_Load] Workspace file ${WORKSPACE_DEFAULT_FILE} not found."$)
		Return
	End If

	Dim workspace As String = File.ReadString(File.DirApp, "workspace.xml")
	fx.Clipboard.SetString(workspace)
	AppLog($"[Button_Load] Workspace copied to the clipboard ${workspace}"$)

	Dim engine As JavaObject = GetEngine(WebViewBlockly)
	engine.RunMethod("executeScript", Array("loadWorkspace()"))
	
	AppLog($"[Button_Load] Workspace loaded from ${WORKSPACE_DEFAULT_FILE}"$)
End Sub

'
'Private Sub ButtonLoad_Click
'	If File.Exists(File.DirApp, WORKSPACE_DEFAULT_FILE ) = False Then
'		AppLog($"[Button_Load] Workspace file ${WORKSPACE_DEFAULT_FILE} not found."$)
'		Return
'	End If
'
'	Dim xml As String
'	Try
'		xml = File.ReadString(File.DirApp, WORKSPACE_DEFAULT_FILE )
'		' Replace optional but safe
'		xml = xml.Replace(Chr(13), "").Replace(Chr(10), "\n") 
'
'		Dim engine As JavaObject = GetEngine(WebViewBlockly)
'
'		' Assign XML as template-literal
'		Dim jsSet As String = $"window.__HK32_XML_TO_LOAD = `${xml}`;"$
'		engine.RunMethod("executeScript", Array(jsSet))
'
'		' Load from JS
'		engine.RunMethod("executeScript", Array("loadWorkspaceFromVar();"))
'
'		AppLog($"[Button_Load] Workspace loaded from ${WORKSPACE_DEFAULT_FILE}"$)
'
'	Catch
'		AppLog($"[Button_Load] Cannot load workspace: ${LastException}"$)
'	End Try
'End Sub
'

## workspace	// Save workspace: returns XML text
	window.saveWorkspace = async function() {
		const xml = Blockly.Xml.workspaceToDom(window.workspace);
		const xmlText = Blockly.Xml.domToText(xml);
		return xmlText;
	}

	// Load workspace: B4J provides XML text via argument
	window.loadWorkspace = async function(xmlText) {
		try {
			const xml = Blockly.Xml.textToDom(xmlText);
			window.workspace.clear();
			Blockly.Xml.domToWorkspace(xml, window.workspace);
		} catch (e) {
			console.error("[loadWorkspace] XML error:", e);
		}
	}

## Vars
	// Do not use Blockly’s built-in variable system (because it breaks async).
	// Use a clean JS object called workspaceVars that acts like RAM:
	// The variable blocks simply read/write this object.
	window.workspaceVars = {};   // { varName: value }

	// -----------------------------------------------------
    // Create predefined variables (appear in Variables menu)
    // -----------------------------------------------------
    workspace.createVariable('x');
    workspace.createVariable('y');
    workspace.createVariable('z');

## isFXWebView

	// Detect if running inside B4J WebView
	window.isFXWebView = navigator.userAgent.includes("JavaFX");
	console.log("isFXWebView:" + window.isFXWebView);
	alert("isFXWebView:" + window.isFXWebView);

## Save/Load workspace

// ======================================================================
// SAVE / LOAD WORKSPACE
// ======================================================================
/*
function saveWorkspaceBase64() {
    const xml = Blockly.Xml.workspaceToDom(window.workspace);
    const xmlText = Blockly.Xml.domToText(xml);
    console.log("Saved Workspace XML:", xmlText);  // Debugging: log the XML
    alert("Saved Workspace XML:", xmlText);  // Debugging: log the XML
    return btoa(xmlText);  // Base64 encode the XML
}

function loadWorkspaceBase64(base64Text) {
    try {
        const xmlText = atob(base64Text);
        console.log("Loaded Workspace XML:", xmlText);  // Debugging: log the loaded XML
        alert("Loaded Workspace XML:", xmlText);  // Debugging: log the loaded XML
        const xml = Blockly.Xml.textToDom(xmlText);
        window.workspace.clear();
        Blockly.Xml.domToWorkspace(xml, window.workspace);
        console.log("[loadWorkspaceBase64] Workspace loaded");
        alert("[loadWorkspaceBase64] Workspace loaded");
    } catch (e) {
        console.error("[loadWorkspaceBase64] Failed:", e.message);
        console.error("Error Stack:", e.stack);
        alert("[loadWorkspaceBase64] Failed:", e.message);
        alert("Error Stack:", e.stack);
    }
}
*/

// Save workspace: returns XML text encoded in Base64
function saveWorkspace() {
    const xml = Blockly.Xml.workspaceToDom(window.workspace);
    const xmlText = Blockly.Xml.domToText(xml);
    alert("Saved Workspace XML:", xmlText);  // Debugging: log the XML
	// Base64 encode
    return btoa(xmlText); 
}

// Load workspace from Base64 string
function textToDomSafe(xmlText) {
    // In v12+, XML parsing uses DOMParser
    return new DOMParser().parseFromString(xmlText, 'text/xml').documentElement;
}
function loadWorkspace(base64Text) {
    const ws = window.workspace;
    if (!ws) return;
    try {
        const xmlText = atob(base64Text); // Base64 decode
        const xml = textToDomSafe(xmlText);
        ws.clear();
        Blockly.Xml.domToWorkspace(xml, ws);
        console.log("[loadWorkspaceBase64] Workspace loaded");
        alert("[loadWorkspaceBase64] Workspace loaded");
    } catch (e) {
        console.error("[loadWorkspaceBase64] Failed:", e);
        alert("[loadWorkspaceBase64] Failed:", e);
    }
}
