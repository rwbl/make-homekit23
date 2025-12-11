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

    // Flatten top-level blocks into async functions
    for (const block of topBlocks) {
        await queueBlockAsync(block, queue);
    }

    // Execute sequentially
    await window.runBlockQueue(queue);
}

// Recursively push blocks into queue
async function queueBlockAsync(block, queue) {
    const gen = Blockly.JavaScript[block.type];
    if (gen) {
        queue.push(gen(block));
    }

    // Handle "next block" for top-level sequence
    const next = block.getNextBlock();
    if (next) {
        await queueBlockAsync(next, queue);
    }
}

async function runIfChain(startBlock) {
    let matched = await Blockly.JavaScript[startBlock.type](startBlock)();

    let next = startBlock.getNextBlock();
    while (next && next.type === 'logic_else_if') {
        matched = await Blockly.JavaScript['logic_else_if'](next)(matched);
        next = next.getNextBlock();
    }

    if (next && next.type === 'logic_else') {
        if (!matched) {
            const list = [];
            let c = next.getInputTargetBlock('DO');
            while (c) {
                list.push(Blockly.JavaScript[c.type](c));
                c = c.getNextBlock();
            }
            await runBlockQueue(list);
        }
    }
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
// VARIABLES
// ======================================================================

// getVariable
// Get the value of a workspace variable and send to B4J.
async function getVariable(varName) {
    // get value from workspaceVars
    const value = window.workspaceVars[varName];
    // send it back to B4J
    await sendCommandToB4JAsync({
        command: "getvariable",
        variable: varName,
        value: value
    });
}

// setVariable
// Set & refresh a workspace variable from B4J.
async function setVariable(varName, varValue) {
    window.workspaceVars = window.workspaceVars || {}; // ensure workspaceVars exists

    // Get the canonical Blockly variable from the workspace
    const variable = Blockly.Variables.getVariable(workspace, varName); // workspace = your Blockly workspace
    const name = variable ? variable.name : varName; // fallback to raw name

    window.workspaceVars[name] = varValue;
	
	// Refresh all variable blocks that reference this variable
    workspace.getAllBlocks(false).forEach(block => {
        if (block.type === 'variables_set' || block.type === 'variables_get') {
            const field = block.getField('VAR');

			// Compare using Blockly’s getVariableById to match canonical variable
			const blockVar = Blockly.Variables.getVariable(workspace, field.getValue()) || {};

            if (blockVar.name === name) {
                // For variables_set, update the VALUE input display (optional)
                const input = block.getInput('VALUE');
                if (input) {
                    const childBlock = input.connection.targetBlock();
                    if (childBlock && childBlock.type === 'math_number') {
                        childBlock.setFieldValue(varValue, 'NUM');
                        childBlock.render();
                    }
                }
                block.render(); // redraw the block
            }
        }
    });
}

// ======================================================================
// BLOCKLY WORKSPACE
// ======================================================================
window.onload = function () {

    // Inject Blockly
	window.workspace = Blockly.inject('blocklyDiv', {
		toolbox: document.getElementById('toolbox'),
		// enable variables
		collapse: false,
		comments: true,
		disable: false,
		sounds: false
	});

	// Initialize the generator (very important!)
    Blockly.JavaScript.init(window.workspace);
	
	// Workspace variable storage (for async execution)
	// Initialize workspaceVars as RAM for async blocks
	window.workspaceVars = {};  // { varName: value }
	
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

	// Button Run to execute the blocks on the workspace
	// This is used for testing in a webbrowser
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

	/*
		OLD CODE using HTML buttons
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
