window.onload = function() {

  // --- WebSocket bridge ---
  window.b4j_ws = new WebSocket("ws://127.0.0.1:18888/hk32");
  b4j_ws.onopen = () => console.log("B4J WebSocket connected");
  window.sendCodeToB4J = code => {
    if(b4j_ws.readyState === WebSocket.OPEN) b4j_ws.send(JSON.stringify({type:"code", payload:code}));
    else console.warn("WebSocket not connected!");
  };

  // --- Inject Blockly workspace ---
  var workspace = Blockly.inject('blocklyDiv', {
    toolbox: '<xml>' +
             '  <block type="open_door"></block>' +
             '  <block type="yellow_on"></block>' +
             '  <block type="delay"></block>' +
             '</xml>'
  });

  // --- Buttons ---
  window.generateCode = function() {
    const code = Blockly.JavaScript.workspaceToCode(workspace);
    console.log("Generated code:\n" + code);
    sendCodeToB4J(code);
  };

  window.saveWorkspace = function() {
    const xmlText = Blockly.Xml.domToText(Blockly.Xml.workspaceToDom(workspace));
    console.log("Workspace XML:\n" + xmlText);
    sendCodeToB4J(xmlText);
  };
};
