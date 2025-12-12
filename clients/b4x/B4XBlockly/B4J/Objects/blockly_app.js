/*
	Project: HomeKit32
	File:    blockly_app.js
	Brief:   Blockly v12 app for B4J integration
	Author:  Robert W.B. Linn (c) 2025 MIT
*/

// ======================================================================
// GLOBAL VARIABLES
// ======================================================================
window.workspace = null;
window.workspaceVars = {}; // RAM for variables
window.sendCommandToB4JAsync = async function(obj) {
    // Default implementation uses alert for testing
    alert(JSON.stringify(obj));
};

// ======================================================================
// RUN BLOCKS
// ======================================================================
window.runBlockQueue = async function(blocks) {
    console.log("runBlockQueue length:", blocks.length);
    for (const fn of blocks) {
        if (typeof fn === "function") {
            try {
                await fn();
            } catch(e) {
                console.error("Block execution error:", e);
            }
        } else {
            console.warn("Not a function in queue:", fn);
        }
    }
};

async function queueBlockAsync(block, queue) {
    const code = Blockly.JavaScript.blockToCode(block);

    if (!code) {
        console.warn("No code produced for block:", block.type);
        return;
    }

    // blockToCode may return array in case of statements + value blocks
    const js = Array.isArray(code) ? code[0] : code;

    // Wrap code in async function
    const fn = new Function("sendCommandToB4JAsync", `
        return (async () => {
            ${js}
        });
    `)(sendCommandToB4JAsync);

    queue.push(fn);

    const next = block.getNextBlock();
    if (next) await queueBlockAsync(next, queue);
}

// Execute all top-level blocks
async function runWorkspaceBlocksAsync() {
    const ws = window.workspace;
    if (!ws) return;
    const topBlocks = ws.getTopBlocks(true);
    console.log("Top blocks count:", topBlocks.length);
    const queue = [];
    for (const block of topBlocks) {
        await queueBlockAsync(block, queue);
    }
    await window.runBlockQueue(queue);
}


function runWorkspaceBlocks() {
    runWorkspaceBlocksAsync();
}

// ======================================================================
// VARIABLES (get/set)
// ======================================================================
async function getVariable(varName) {
    const value = window.workspaceVars[varName];
    await sendCommandToB4JAsync({ command: "getvariable", variable: varName, value: value });
}

async function setVariable(varName, varValue) {
    window.workspaceVars = window.workspaceVars || {};
    window.workspaceVars[varName] = varValue;

    const variable = Blockly.Variables.getVariable(window.workspace, varName);
    const name = variable ? variable.name : varName;

    window.workspace.getAllBlocks(false).forEach(block => {
        if (block.type === 'variables_set' || block.type === 'variables_get') {
            const field = block.getField('VAR');
            const blockVar = Blockly.Variables.getVariable(window.workspace, field.getValue()) || {};
            if (blockVar.name === name) {
                const input = block.getInput('VALUE');
                if (input) {
                    const childBlock = input.connection.targetBlock();
                    if (childBlock && childBlock.type === 'math_number') {
                        childBlock.setFieldValue(varValue, 'NUM');
                        childBlock.render();
                    }
                }
                block.render();
            }
        }
    });
}

// ==========================
// SAVE / LOAD WORKSPACE (Base64, Blockly v12 compatible)
// ==========================

// Helper: safe DOM parse for XML text (works in v12 and WebView)
function textToDomSafe(xmlText) {
    return new DOMParser().parseFromString(xmlText, 'text/xml').documentElement;
}

// Save workspace to Base64
function saveWorkspaceBase64() {
    const ws = window.workspace;
    if (!ws) return '';
    try {
        const xmlDom = Blockly.Xml.workspaceToDom(ws);
        const xmlText = Blockly.Xml.domToText(xmlDom);
        return btoa(unescape(encodeURIComponent(xmlText))); // UTF-8 safe Base64
    } catch (e) {
        console.error('[saveWorkspaceBase64] Failed:', e);
        return '';
    }
}

// Load workspace from Base64
function loadWorkspaceBase64(base64Text) {
    const ws = window.workspace;
    if (!ws) return;
    try {
        const xmlText = decodeURIComponent(escape(atob(base64Text))); // UTF-8 safe decode
        const xmlDom = textToDomSafe(xmlText);
        ws.clear();
        Blockly.Xml.domToWorkspace(xmlDom, ws);
        console.log('[loadWorkspaceBase64] Workspace loaded');
        alert('[loadWorkspaceBase64] Workspace loaded');
    } catch (e) {
        console.error('[loadWorkspaceBase64] Failed:', e);
        alert('[loadWorkspaceBase64] Failed: ' + (e.message || e));
    }
}

// Expose functions for B4J calls with alias for backward compatibility
window.saveWorkspaceBase64 = saveWorkspaceBase64;
window.saveWorkspace = saveWorkspaceBase64; 
window.loadWorkspaceBase64 = loadWorkspaceBase64;
window.loadWorkspace = loadWorkspaceBase64; 

// ========================================================
// CREATE VAR - Call from B4J when user enters a variable name
// ========================================================
function setNewVariable(name) {
    if (!name) return;

    // Add variable to Blockly workspace
    const ws = window.workspace || Blockly.getMainWorkspace();
    if (!ws) return;

    const varMap = ws.getVariableMap();
    const existing = varMap.getVariable(name);
    if (!existing) {
        ws.createVariable(name);
        console.log("Variable created from B4J:", name);
    } else {
        console.log("Variable already exists:", name);
    }
}

// ======================================================================
// ONLOAD: Inject Blockly
// ======================================================================
window.onload = function () {
    // Inject workspace with JSON toolbox (replace toolboxJson with your JSON)
    window.workspace = Blockly.inject('blocklyDiv', {
        toolbox: toolboxJson,
        collapse: false,
        comments: true,
        disable: false,
        sounds: false
    });

    // Initialize JS generator
    Blockly.JavaScript.init(window.workspace);

	// ============================================================================
	// RUNTIME DELEGATOR — forces use of new v12 async generators if available
	// ============================================================================

	// Patch runWorkspaceBlocks() so B4J calls use the v12 runtime
	window.runWorkspaceBlocks = function() {
		if (window._hk32_runWorkspaceBlocksAsync) {
			// Prefer new runtime from blockly_generators.js
			window._hk32_runWorkspaceBlocksAsync();
		} else if (typeof runWorkspaceBlocksAsync === 'function') {
			// Fallback to old legacy runner
			runWorkspaceBlocksAsync();
		} else {
			console.error("No runWorkspaceBlocks available");
		}
	};

	// Patch the RUN button (if it exists)
	(function() {
		const btn = document.getElementById("btnRun");
		if (!btn) return;

		btn.onclick = function() {
			window.runWorkspaceBlocks();
			
			// Example testing some other function
			// base64 = 'PHhtbCB4bWxucz0iaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vYmxvY2tseS94bWwiPjxibG9jayB0eXBlPSJsb2dfYmxvY2siIGlkPSJHbVZSKiRRMUN1Zl5IPXA0c0A3PSIgeD0iMTQ1IiB5PSIxNjIiPjx2YWx1ZSBuYW1lPSJURVhUIj48YmxvY2sgdHlwZT0idGV4dF9saXRlcmFsIiBpZD0ibHwsKk5ieGtTYWtQbSxLdTpiWVIiPjxmaWVsZCBuYW1lPSJURVhUIj5YPC9maWVsZD48L2Jsb2NrPjwvdmFsdWU+PC9ibG9jaz48L3htbD4=';
			// loadWorkspace(base64);
		};
	})();

};
