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
// ======================================================
// Runtime Variable Store (Blockly v12+ safe)
// -no prototype pollution,predictable namespace,room for future scopes (locals, stack, etc.)
// ======================================================
window.blocklyVars = {
	// All runtime variables live here
	runtime: Object.create(null)
};

// ======================================================================
// SEND COMMAND TO B4J using alert
// ======================================================================
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
    // console.log("Top blocks count:", topBlocks.length);
    const queue = [];
    for (const block of topBlocks) {
        await queueBlockAsync(block, queue);
    }
    await window.runBlockQueue(queue);
}


function runWorkspaceBlocks() {
    runWorkspaceBlocksAsync();
}

// ==========================
// SAVE / LOAD WORKSPACE (Base64, Blockly v12 compatible)
// ==========================
function saveWorkspaceBase64() {
    const ws = window.workspace;
    if (!ws) return '';
    try {
        // 1. Get the workspace state as a plain JS Object
		const state = Blockly.serialization.workspaces.save(ws);
		// const state = Blockly.serialization.workspaces.save(ws, { addIds: true });
        
        // 2. Convert to JSON String
        const jsonText = JSON.stringify(state);

		alert(jsonText);
        
        // 3. Convert to Base64 (UTF-8 safe)
        return btoa(unescape(encodeURIComponent(jsonText)));
    } catch (e) {
        console.error('[saveWorkspaceBase64] Failed:', e);
        return '';
    }
}

// Load workspace from Base64 (JSON based)
function loadWorkspaceBase64(base64Text) {
    const ws = window.workspace;
    if (!ws) return;
    try {
        // 1. Decode Base64 back to JSON string
        const jsonText = decodeURIComponent(escape(atob(base64Text)));
        
		alert(jsonText);
		
        // 2. Parse back to a JS Object
        const state = JSON.parse(jsonText);

		ws.clear();
        
        // 3. Clear and Load using the v12 serialization system
        // IMPORTANT: Delay load until Blockly is fully ready
		setTimeout(() => {
			Blockly.serialization.workspaces.load(state, ws);
			// Force full redraw
            workspace.refreshToolboxSelection();
            workspace.render();

		}, 50);
        
        console.log('[loadWorkspaceBase64] Workspace loaded via JSON');
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

// Clear the current workspace.
function clearWorkspace() {
	const ws = window.workspace;
	if (!ws) return;
	ws.clear();
	console.log("[Clear Workspace] Workspace cleared");
	if (window.sendCommandToB4JAsync) {
		window.sendCommandToB4JAsync({ command: 'workspace_cleared' });
	}
}	

// ========================================================
// CREATE VAR - Call from B4J when user enters a variable name
// ========================================================

// ============================================================================
// PRELOAD VARIABLES — REQUIRED FOR JSON LOADER + RUNTIME
// ============================================================================
function preLoadVariables() {
	const ws = window.workspace;
    if (!ws) return;
	
    const varMap = workspace.getVariableMap();

    // Define variables + initial values
    const fixedVars = {
        BLE_CONNECTED: false,
        COUNTER: 0
    };

    // Ensure runtime object exists
    window.blocklyVars.runtime = window.blocklyVars.runtime || {};

    Object.entries(fixedVars).forEach(([name, initialValue]) => {
        // 1. Ensure variable exists in Blockly workspace
        if (!varMap.getVariable(name)) {
            varMap.createVariable(name);
        }

		// 2. Ensure runtime store has initial value
        if (!(name in window.blocklyVars.runtime)) {
            window.blocklyVars.runtime[name] = initialValue;
        }
	});

	console.log(`[Blockly preloadVariables] ble_connected=${window.blocklyVars.runtime.BLE_CONNECTED}`); // should output: false
    console.log('[preLoadVariables] Loaded:', Object.keys(fixedVars));
}

function isValidVariableName(name) {
    return typeof name === 'string' && name.trim().length > 0;
}

function createVariable(name, type = '') {
    if (!isValidVariableName(name)) {
        console.warn('[Blockly] Invalid variable name:', name);
        return null;
    }

    const ws = window.workspace;
    if (!ws) return null;

    const varMap = ws.getVariableMap();
    let v = varMap.getVariable(name);

    if (!v) {
        v = varMap.createVariable(name, type);
        console.log('[Blockly] Variable created:', name);
    }
    return v;
}

function setVariable(name, value) {
    if (!name) {
        console.log("[setVariable][E] NO NAME");
        return false;
    }

    window.blocklyVars.runtime = window.blocklyVars.runtime || {};

    if (!(name in window.blocklyVars.runtime)) {
        console.warn(`[setVariable] Variable "${name}" not found in runtime store. Did you preload it?`);
        return false;
    } 
	
	window.blocklyVars.runtime[name] = value;
	console.log(`[setVariable][I] ${name} = ${value}`);
	return true;
}

function getVariable(name, defaultValue = undefined) {
    if (!name) return defaultValue;

    window.blocklyVars.runtime = window.blocklyVars.runtime || {};

    if (!(name in window.blocklyVars.runtime)) {
        console.warn(`[getVariable][E] Variable "${name}" not found in runtime store. Did you preload it?`);
        return defaultValue;
    }

    return window.blocklyVars.runtime[name];
}

function hasVariable(name) {
    return !!(name && window.blocklyVars.runtime.hasOwnProperty(name));
}

// ======================================================================
// ONLOAD: Inject Blockly
// ======================================================================
window.onload = function () {
    // 1. Inject workspace with JSON toolbox (replace toolboxJson with your JSON)
    window.workspace = Blockly.inject('blocklyDiv', {
		toolbox: toolboxJson,
		scrollbars: true,
		trashcan: true,
		renderer: 'zelos', // or 'geras' for old style
		maxBlocks: Infinity,
		sounds: false,
		move: {
			scrollbars: true,
			drag: true,
			wheel: true
		}
	});
	console.log("[Blockly] Workspace injected");

    // 2. Initialize JS generator
    Blockly.JavaScript.init(window.workspace);

	// 3. Variables Pre-Defined v12
    // This adds it to the internal Variable Map so it appears in the toolbox
	preLoadVariables();

	// NOW register your generators (workspace exists!)	
    // setupRuntimeGenerators();

    console.log("Blockly injected and generators registered.");

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

	// ============================================================================
	// BUTTONS
	// ============================================================================
	
	// Run button (if exists)
	(function() {
		const btn = document.getElementById("btnRun");
		if (!btn) return;

		btn.onclick = function() {
			window.runWorkspaceBlocks();
			
			// Example testing some other functions
			// base64 = 'PHhtbCB4bWxucz0iaHR0cHM6Ly9kZXZlbG9wZXJzLmdvb2dsZS5jb20vYmxvY2tseS94bWwiPjxibG9jayB0eXBlPSJsb2dfYmxvY2siIGlkPSJHbVZSKiRRMUN1Zl5IPXA0c0A3PSIgeD0iMTQ1IiB5PSIxNjIiPjx2YWx1ZSBuYW1lPSJURVhUIj48YmxvY2sgdHlwZT0idGV4dF9saXRlcmFsIiBpZD0ibHwsKk5ieGtTYWtQbSxLdTpiWVIiPjxmaWVsZCBuYW1lPSJURVhUIj5YPC9maWVsZD48L2Jsb2NrPjwvdmFsdWU+PC9ibG9jaz48L3htbD4=';
			// loadWorkspace(base64);
			// setVariable("BLE_CONNECTED", true);
			// setVariable("COUNTER", 1958);

		};
	})();

	// Clear workspace button (if exists)
	(function() {
		const btnClear = document.getElementById("btnClear");
		if (!btnClear) return;

		btnClear.onclick = function() {
			window.clearWorkspace();
		};
	})();


};
