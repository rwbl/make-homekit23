/*
	Project:	HomeKit32
	File:		blockly_app.js
	Brief:		Button handler and communication with B4J using redirected alert function.
*/


// ======================================================================
// GLOBAL FUNCTIONS
// ======================================================================
// Notes
// B4J executeScript() requires a synchronous return value (do not define as async)

// ======================================================================
// Run all blocks in the workspace
// ======================================================================
function runWorkspaceBlocks() {
	runWorkspaceBlocksAsync();
}

async function runWorkspaceBlocksAsync() {
    const topBlocks = window.workspace.getTopBlocks(true);
    const queue = [];

    // Convert top-level blocks to async functions
    topBlocks.forEach(block => {
        const gen = Blockly.JavaScript[block.type];
        if (gen) queue.push(gen(block));
    });

    // Execute sequentially
    await window.runBlockQueue(queue);
}

// ======================================================================
// BASE64 SAVE/LOAD
// ======================================================================

// Save workspace: returns XML text encoded in Base64
function saveWorkspaceBase64() {
    const xml = Blockly.Xml.workspaceToDom(window.workspace);
    const xmlText = Blockly.Xml.domToText(xml);
	// Base64 encode
    return btoa(xmlText); 
}

// Load workspace from Base64 string
function loadWorkspaceBase64(base64Text) {
    try {
        const xmlText = atob(base64Text); // Base64 decode
        const xml = Blockly.Xml.textToDom(xmlText);
        window.workspace.clear();
        Blockly.Xml.domToWorkspace(xml, window.workspace);
        console.log("[loadWorkspaceBase64] Workspace loaded");
    } catch (e) {
        console.error("[loadWorkspaceBase64] Failed:", e);
    }
}

// ======================================================================
// BLOCKLY WORKSPACE
// ======================================================================
window.onload = function () {

    // Inject Blockly
    window.workspace = Blockly.inject('blocklyDiv', {
        toolbox: document.getElementById('toolbox')
    });

	// Run all blocks sequentially
	window.runBlockQueue = async function(blocks) {
		for (const fn of blocks) {
			if (typeof fn === "function") {
				await fn(); // execute async block
			}
		}
	}

	// Send command to B4J using alert
	window.sendCommandToB4JAsync = async function(obj) {
		alert(JSON.stringify(obj));
	};

	/*
		OLD CODE using HTML buttons

	// Button Run to execute the blocks on the workspace
	document.getElementById('btnRun').onclick = async function() {
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

	// Button Save Workspace
    document.getElementById('btnSaveWorkspace').onclick = function() {
        const xml = Blockly.Xml.workspaceToDom(workspace);
        const xmlText = Blockly.Xml.domToText(xml);
        alert(xmlText);
    };

    // Button Load Workspace
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
	*/
};
