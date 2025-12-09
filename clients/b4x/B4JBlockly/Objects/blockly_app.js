window.onload = function () {

    // Inject Blockly
    window.workspace = Blockly.inject('blocklyDiv', {
        toolbox: document.getElementById('toolbox')
    });

    // WebSocket for B4J
    window.b4j_ws = new WebSocket("ws://127.0.0.1:18888/hk32");

    b4j_ws.onopen  = () => console.log("WebSocket connected");
    b4j_ws.onclose = () => console.log("WebSocket closed");
    b4j_ws.onerror = e => console.log("WebSocket error", e);

	async function sendCommandToB4JAsync(obj) {
		window.b4j.JavaReceive(JSON.stringify(obj));
	}

    window.sendCodeToB4J = function(code) {
		// alert(code);
		// window.b4j_ws.send(JSON.stringify(obj));
		window.b4j.JavaReceive(JSON.stringify(obj));
    };

	document.getElementById('btnGenerate').onclick = async function() {
		const topBlocks = workspace.getTopBlocks(true);
		const queue = [];

		// Convert top-level blocks to async functions
		topBlocks.forEach(block => {
			const gen = Blockly.JavaScript[block.type];
			if (gen) queue.push(gen(block));
		});

		// Run everything sequentially
		await runBlockQueue(queue);
	};

	// Save Workspace Button
    document.getElementById('btnSaveWorkspace').onclick = function() {
        const xml = Blockly.Xml.workspaceToDom(workspace);
        const xmlText = Blockly.Xml.domToText(xml);
        alert(xmlText);
        // alert('[btnSaveWorkspace] xml=' + xmlText);
        // Optionally, send xmlText to B4J to save to file
    };

    // Load Workspace Button
    document.getElementById('btnLoadWorkspace').onclick = function() {
        const xmlText = prompt("Paste workspace XML here:");
        if (!xmlText) return;
        try {
            const xml = Blockly.Xml.textToDom(xmlText);
            workspace.clear();
            Blockly.Xml.domToWorkspace(xml, workspace);
        } catch(e) {
            alert("[btnLoadWorkspace][E] Failed to load workspace XML:", e);
            console.error("[btnLoadWorkspace][E] Failed to load workspace XML:", e);
        }
    };

};
