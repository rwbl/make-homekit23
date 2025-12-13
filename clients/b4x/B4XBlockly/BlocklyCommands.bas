B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' Class:        BlocklyCommands
' Brief:        Registry of Blockly command definitions.
' Date:         2025-12-13
' Author:       Robert W.B. Linn (c) 2025 MIT
' Description:  Provides Blockly TBlocklyCommand definitions and utilities.
#End Region

Private Sub Class_Globals
	Public LastState As Boolean
	Public LastMessage As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	
End Sub

' ------------------------------
' Helper to access the WebEngine via JavaObject
' ------------------------------
Public Sub GetEngine(wv As WebView) As JavaObject
	Dim jo As JavaObject = wv
	Return jo.RunMethod("getEngine", Null)
End Sub

' RunScript
' Execute a Javascript (see blockly_apps js).
' Parameters:
'	wv WebView
'	script String
' Example:
'	Blockly.RunScript("clearWorkspace()")
Public Sub RunScript(wv As WebView, script As String) As Boolean
	Dim result As Boolean = False
	Dim engine As JavaObject = GetEngine(wv)
	
	Try
		engine.RunMethod("executeScript", Array(script))
		LastMessage = $"[BlocklyCommands.RunScript][I] OK"$
		result = True
	Catch
		LastMessage = $"[BlocklyCommands.RunScript][E] ${LastException}"$
		result = True
	End Try
	LastState = result
	Return result
End Sub

' RunWorkspaceBlocks
' Run all the blocks top-down from the current workspace.
' Parameters:
'	wv WebView
Public Sub RunWorkspaceBlocks(wv As WebView) As Boolean
	Return RunScript(wv, ("runWorkspaceBlocks()"))
End Sub

' SetVariable
' Set the value of a variable.
' Note that the block "show_variable" is refreshed if exists.
' Parameters:
'	wv WebView
'	variable String - Blockly variable
'	value Object - Can be any type
' Example:
Public Sub SetVariable(wv As WebView, variable As String, value As Object) As Boolean
	Dim result As Boolean
	Dim jsValue As String

	jsValue = "null"

	If value Is Boolean Then
		jsValue = IIf(value, "true", "false")
	End If
	
	If value Is Int Or value Is Long Or value Is Double Then
		jsValue = value
	End If

	If value Is String Then
		jsValue = $""${value}""$  ' wrap string in quotes
	End If

	Dim js As String = $"setVariable("${variable}", ${jsValue}); refreshShowVariableBlocks();"$
	Log($"[BlocklySetVariable] ${js}"$)

	Dim engine As JavaObject = GetEngine(wv)
	Try
		engine.RunMethod("executeScript", Array(js))
		LastMessage = $"[BlocklyCommands.SetVariable][I] OK"$
		result = True
	Catch
		LastMessage = $"[BlocklyCommands.SetVariable][E] ${LastException}"$
		result = True
	End Try
	LastState = result
	Return result
End Sub

' GetVariable
' Get the value of a variable.
' Parameters:
'	wv WebView
'	variable String - Blockly variable
' Return:
'	String
' Example:
Public Sub GetVariable(wv As WebView, variable As String) As String
	Return RunScript(wv, variable)
End Sub

' CreateVariable
' Create a new variable.
' Parameters:
'	wv WebView
'	variable String - Blockly variable
' Example:
Public Sub CreateVariable(wv As WebView, variable As String) As Boolean
	Return RunScript(wv, $"createVariable("${variable}")"$)
End Sub

' Save
' Save workspace to Base64 coded string.
' Parameters:
'	wv WebView
' Returns:
'	base64 String
' Example:
Public Sub Save(wv As WebView) As String
	Dim result As String
	Dim engine As JavaObject = GetEngine(wv)

	Try
		Dim base64 As String = engine.RunMethod("executeScript", Array("saveWorkspace()"))
		If base64 <> Null And base64.Length > 0 Then
			result = base64
			LastState = True
			LastMessage = $"[BlocklyCommands.Save][I] OK"$
		Else
			result = base64
			LastMessage = $"[BlocklyCommands.Save][E] Failed workspace empty."$
			LastState = False
		End If
	Catch
		result = ""
		LastMessage = $"[BlocklyCommands.Save][E] ${LastException}"$
		LastState = False
	End Try
	Return result
End Sub

' Load
' Load workspace from Base64 coded string.
' Parameters:
'	wv WebView
'	base64 String
' Returns:
'	Boolean
' Example:
Public Sub Load(wv As WebView, base64 As String) As Boolean
	Dim result As Boolean
	Dim engine As JavaObject = GetEngine(wv)

	Try
		engine.RunMethod("executeScript", Array($"loadWorkspace("${base64}")"$))
		LastMessage = $"[BlocklyCommands.Load][I] OK"$
		result = True
	Catch
		LastMessage = $"[BlocklyCommands.Load][E] ${LastException}"$
		result = True
	End Try
	LastState = result
	Return result
End Sub

' Clear
' Clear the workspace.
Public Sub Clear(wv As WebView) As Boolean
	Return RunScript(wv, $"clearWorkspace()"$)
End Sub

#end region
