window.onload = function () {

    console.log("Blockly App.js loaded");

    // --- Inject Blockly ---
    window.workspace = Blockly.inject("blocklyDiv", {
        toolbox: document.getElementById("toolbox")
    });

    // --- Setup (overridden later by B4J) ---
    window.sendCodeToB4J = function(code) {
        console.log("sendCodeToB4J missing (waiting for B4J)");
        alert("B4J bridge not ready!");
    };

    // --- Generate Code button ---
    document.getElementById("btnGenerate").onclick = function() {
        const code = Blockly.JavaScript.workspaceToCode(window.workspace);
        console.log("Generated:", code);
        window.sendCodeToB4J(code);
    };
};
