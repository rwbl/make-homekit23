/*
    Project:    HomeKit32
    File:       blockly_generators.js
    Brief:      Handle Blockly block actions for Blockly v12 (runtime async model).
                This file implements a compatibility adapter and registers runtime
                async generators for blocks. Each generator returns an async
                function that will be executed by the runtime (not string JS code).

    Notes:
      - Designed to be a drop-in replacement for your previous generators.
      - Use registerRuntimeGenerator(name, fn) to add new generators.
      - sendCommandToB4JAsync(obj) must exist (fallback alerts are provided).
*/

// ============================================================================
// Fallbacks & runtime registry
// ============================================================================
if (typeof window.sendCommandToB4JAsync !== 'function') {
    window.sendCommandToB4JAsync = async function(obj) {
        // fallback to alert — your B4J app already intercepts alert messages
        alert(JSON.stringify(obj));
    };
}

// Runtime generators storage
const runtimeGenerators = {};

// Ensure Blockly v12 generator hook exists
Blockly.JavaScript = Blockly.JavaScript || {};
Blockly.JavaScript.forBlock = Blockly.JavaScript.forBlock || {};

// Helper: register a runtime generator
function registerRuntimeGenerator(name, fn) {
    // store the runtime generator
    runtimeGenerators[name] = fn;

    // register a minimal v12 generator so Blockly doesn't complain.
    // It returns a harmless marker string. v12 expects a string return.
    Blockly.JavaScript.forBlock[name] = function(block, generator) {
        // The exact string is unimportant to runtime; it's only for Blockly internals.
        return `// RUNTIME:${name}:${block.id}`;
    };
}

// Helper: get runtime async function for block instance
function getRuntimeFn(block) {
    const gen = runtimeGenerators[block.type];
    if (!gen) {
        console.error("No runtime generator for block:", block.type);
        throw new Error("Unknown runtime block: " + block.type);
    }
    const maybeFn = gen(block);
    if (typeof maybeFn !== 'function') {
        console.error("Runtime generator did not return a function for block:", block.type, maybeFn);
        throw new Error("Runtime generator must return a function");
    }
    return maybeFn;
}

// ============================================================================
// Helpers for evaluating inputs (value blocks)
// ============================================================================

// Try to evaluate a value code string safely-ish. Accepts outputs like 123 or "text".
function tryEvalValueCode(code) {
    if (code == null) return null;
    // Trim
    const s = String(code).trim();
    if (!s) return null;
    // If it looks like a quoted string, return without eval
    if ((s[0] === '"' && s[s.length - 1] === '"') || (s[0] === "'" && s[s.length - 1] === "'")) {
        try { return JSON.parse(s.replace(/'/g, '"')); } catch(e) { return s.slice(1, -1); }
    }
    // If it looks like a number
    if (/^-?\d+(\.\d+)?$/.test(s)) return Number(s);
    // Fallback: attempt to use Function to evaluate
    try {
        return Function('return (' + s + ')')();
    } catch(e) {
        return s;
    }
}

async function evalInputAsync(block, inputName, defaultValue = null) {
    const inputBlock = block.getInputTargetBlock(inputName);
    if (!inputBlock) return defaultValue;

    // If a runtime generator exists for that block type, call it
    const runtimeGen = runtimeGenerators[inputBlock.type];
    if (runtimeGen) {
        let val = await runtimeGen(inputBlock)(); // <-- important: call the returned function
        // unwrap nested functions (some generators may return functions)
        while (typeof val === 'function') val = await val();
        return val === undefined ? defaultValue : val;
    }

    // fallback: evaluate as string or number
    try {
        const codeValue = Blockly.JavaScript.valueToCode(inputBlock, '', Blockly.JavaScript.ORDER_ATOMIC);
        const v = tryEvalValueCode(codeValue);
        return v === undefined ? defaultValue : v;
    } catch (e) {
        return defaultValue;
    }
}

/*
// Evaluate an input which may be a runtime-generated async function, or a built-in value block
async function evalInputAsync(block, inputName, defaultValue = null) {
    let inputBlock = block.getInputTargetBlock(inputName);

    // If no real block, check if a shadow block exists
    if (!inputBlock) {
        const inputConnection = block.getInput(inputName)?.connection;
        if (inputConnection?.shadowDom) {
            // Convert shadow DOM to block instance in workspace
            inputBlock = Blockly.Xml.domToBlock(inputConnection.shadowDom, block.workspace);
        } else {
            return defaultValue;
        }
    }

    // If a runtime generator exists, call it
    const runtimeGen = runtimeGenerators[inputBlock.type];
    if (runtimeGen) {
        const fn = runtimeGen(inputBlock);
        if (typeof fn === 'function') {
            let res = await fn();
            // Unwrap nested functions (some generators return functions)
            while (typeof res === 'function') res = await res();
            return res === undefined ? defaultValue : res;
        }
        return runtimeGen(inputBlock);
    }

    // Otherwise fallback to valueToCode + tryEvalValueCode
    try {
        const codeValue = Blockly.JavaScript.valueToCode(inputBlock, '', Blockly.JavaScript.ORDER_ATOMIC);
        const v = tryEvalValueCode(codeValue);
        return v === undefined ? defaultValue : v;
    } catch (e) {
        console.error('[evalInputAsync] Failed:', e);
        return defaultValue;
    }
}
*/

// ============================================================================
// Runtime execution helpers
// ============================================================================

// Execute a list of runtime functions sequentially
async function runBlockQueue(blockFns) {
    for (const fn of blockFns) {
        if (typeof fn === 'function') {
            try {
                await fn();
            } catch (e) {
                console.error('Error executing block function:', e);
            }
        }
    }
}

// Build a linear sequence (linked by next connections) of runtime functions from a starting block
function buildSequenceFrom(block, queue) {
    let cur = block;
    while (cur) {
        // If this block has a runtime generator, push its function
        const gen = runtimeGenerators[cur.type];
        if (gen) {
            queue.push(gen(cur));
        } else {
            console.warn('No runtime generator for block in sequence:', cur.type);
        }
        cur = cur.getNextBlock();
    }
}

// Execute all top-level blocks (keeps compatibility with your run button)
async function runWorkspaceBlocksAsync() {
    const ws = window.workspace || window.blocklyWorkspace || Blockly.getMainWorkspace && Blockly.getMainWorkspace();
    if (!ws) {
        console.error('No workspace available');
        return;
    }
    const topBlocks = ws.getTopBlocks(true);
    console.log('Top blocks count:', topBlocks.length);

    const queue = [];
    for (const block of topBlocks) {
        buildSequenceFrom(block, queue);
    }

    console.log('runBlockQueue length:', queue.length);
    await runBlockQueue(queue);
}

// Expose the run function globally (B4J may call this)
window.runWorkspaceBlocksAsync = runWorkspaceBlocksAsync;
window.runWorkspaceBlocks = function() { runWorkspaceBlocksAsync(); };

// ============================================================================
// GENERATORS (registered via registerRuntimeGenerator)
// These are your original runtime-style generators converted to use the
// registerRuntimeGenerator helper. They keep the same behavior as before.
// ============================================================================

// Utility / flow
registerRuntimeGenerator('start_block', block => async () => {
    const toRun = [];
    let cur = block.getNextBlock();
    while (cur) {
        if (runtimeGenerators[cur.type]) toRun.push(runtimeGenerators[cur.type](cur));
        cur = cur.getNextBlock();
    }
    await sendCommandToB4JAsync({ command: 'start' });
    await runBlockQueue(toRun);
});

registerRuntimeGenerator('stop_block', block => async () => {
    await sendCommandToB4JAsync({ command: 'stop' });
});

// Logging / text
/*
registerRuntimeGenerator('log_block', block => async () => {
    // Evaluate the 'TEXT' input asynchronously
    const value = await evalInputAsync(block, 'TEXT', '[log empty]');

    // Keep original value for logging
    console.log("[log_block]", value);

    // Send to B4J — convert to string only here
    await sendCommandToB4JAsync({ command: 'log', value: (value === undefined || value === null) ? '[log empty]' : String(value) });
});
*/
registerRuntimeGenerator('log_block', block => async () => {
    const inputBlock = block.getInputTargetBlock('TEXT');
    let msg = '';
    if (inputBlock) {
        if (runtimeGenerators[inputBlock.type]) {
            const valFn = runtimeGenerators[inputBlock.type](inputBlock);
            if (typeof valFn === 'function') msg = await valFn();
            else msg = valFn;
        } else {
            const codeValue = Blockly.JavaScript.valueToCode(inputBlock, '', Blockly.JavaScript.ORDER_ATOMIC);
            msg = tryEvalValueCode(codeValue) || '';
        }
    } else {
        msg = block.getFieldValue('TEXT') || '[log empty]';
    }
	// console.log("[log_block]" + msg);
    await sendCommandToB4JAsync({ command: 'log', value: msg });
});

registerRuntimeGenerator('text_literal', block => async () => {
    return block.getFieldValue('TEXT') || '';
});

// Devices / simple actions
registerRuntimeGenerator('connect', block => async () => {
    await sendCommandToB4JAsync({ command: 'connect' });
});

registerRuntimeGenerator('disconnect', block => async () => {
    await sendCommandToB4JAsync({ command: 'disconnect' });
});

registerRuntimeGenerator('yellow_led_on', block => async () => {
    await sendCommandToB4JAsync({ command: 'yellow_led_on' });
});

registerRuntimeGenerator('yellow_led_off', block => async () => {
    await sendCommandToB4JAsync({ command: 'yellow_led_off' });
});

registerRuntimeGenerator('yellow_led', block => async () => {
    const s = block.getFieldValue('STATE');
    await sendCommandToB4JAsync({ command: s === 'ON' ? 'yellow_led_on' : 'yellow_led_off' });
    try { block.setColour(s === 'ON' ? 90 : 60); } catch (e) { /* ignore render errors */ }
});

registerRuntimeGenerator('door_open', block => async () => {
    await sendCommandToB4JAsync({ command: 'door_open' });
});

registerRuntimeGenerator('door_close', block => async () => {
    await sendCommandToB4JAsync({ command: 'door_close' });
});

registerRuntimeGenerator('dht11_sensor', block => async () => {
    // placeholder — adjust to your needs
    return;
});

registerRuntimeGenerator('delay', block => async () => {
    const ms = Number(block.getFieldValue('DELAY') || 1000);
    await sendCommandToB4JAsync({ command: 'delay', value: ms });
    return new Promise(resolve => setTimeout(resolve, ms));
});

// Logic primitives
registerRuntimeGenerator('logic_boolean', block => async () => {
    return block.getFieldValue('BOOL') === 'TRUE';
});

registerRuntimeGenerator('logic_compare', block => async () => {
    const A = await evalInputAsync(block, 'A', 0);
    const B = await evalInputAsync(block, 'B', 0);
    const op = block.getFieldValue('OP');
    switch (op) {
        case 'EQ': return A == B;
        case 'NEQ': return A != B;
        case 'LT': return A < B;
        case 'LTE': return A <= B;
        case 'GT': return A > B;
        case 'GTE': return A >= B;
        default: return false;
    }
});

registerRuntimeGenerator('logic_operation', block => async () => {
    const A = await evalInputAsync(block, 'A', false);
    const B = await evalInputAsync(block, 'B', false);
    const op = block.getFieldValue('OP');
    if (op === 'AND') return A && B;
    return A || B;
});

registerRuntimeGenerator('logic_negate', block => async () => {
    const x = await evalInputAsync(block, 'BOOL', false);
    return !x;
});

// If / If-Else / Else-if runtime
registerRuntimeGenerator('logic_if', block => async () => {
    const cond = await evalInputAsync(block, 'COND', false);
    if (!cond) return false;
    const list = [];
    let c = block.getInputTargetBlock('DO');
    while (c) {
        if (runtimeGenerators[c.type]) list.push(runtimeGenerators[c.type](c));
        c = c.getNextBlock();
    }
    await runBlockQueue(list);
    return true;
});

registerRuntimeGenerator('logic_if_else', block => async () => {
    const cond = await evalInputAsync(block, 'COND', false);
    const list = [];
    let c = cond ? block.getInputTargetBlock('DO') : block.getInputTargetBlock('ELSE');
    while (c) {
        if (runtimeGenerators[c.type]) list.push(runtimeGenerators[c.type](c));
        c = c.getNextBlock();
    }
    await runBlockQueue(list);
});

registerRuntimeGenerator('logic_else_if', block => async (prevExecuted = false) => {
    if (prevExecuted) return true;
    const cond = await evalInputAsync(block, 'COND', false);
    if (!cond) return false;
    const list = [];
    let c = block.getInputTargetBlock('DO');
    while (c) {
        if (runtimeGenerators[c.type]) list.push(runtimeGenerators[c.type](c));
        c = c.getNextBlock();
    }
    await runBlockQueue(list);
    return true;
});

// math_number runtime
registerRuntimeGenerator('math_number', block => async () => {
    return Number(block.getFieldValue('NUM'));
});

registerRuntimeGenerator('math_arithmetic', block => async () => {
    const A = await evalInputAsync(block, 'A', 0);
    const B = await evalInputAsync(block, 'B', 0);
    const op = block.getFieldValue('OP');
    switch(op) {
        case 'ADD': return A + B;
        case 'MINUS': return A - B;
        case 'MULTIPLY': return A * B;
        case 'DIVIDE': return A / B;
    }
    return 0;
});

registerRuntimeGenerator('math_random_int', block => async () => {
    const from = Number(await evalInputAsync(block, 'FROM', 0));
    const to = Number(await evalInputAsync(block, 'TO', 1));
    return Math.floor(Math.random() * (to - from + 1)) + from;
});

registerRuntimeGenerator('math_random_float', block => async () => {
    return Math.random();
});

registerRuntimeGenerator('math_round', block => async () => {
    const op = block.getFieldValue('OP'); // ROUND, ROUNDUP, ROUNDDOWN
    const num = await evalInputAsync(block, 'NUM', 0);
    switch(op) {
        case 'ROUND': return Math.round(num);
        case 'ROUNDUP': return Math.ceil(num);
        case 'ROUNDDOWN': return Math.floor(num);
    }
    return num;
});

registerRuntimeGenerator('math_modulo', block => async () => {
    const dividend = await evalInputAsync(block, 'DIVIDEND', 0);
    const divisor = await evalInputAsync(block, 'DIVISOR', 1);
    return dividend % divisor;
});

// Loops runtime
registerRuntimeGenerator('repeat_loop', block => async () => {
    const times = Number(await evalInputAsync(block, 'TIMES', 1)) || 0;
    const inner = [];
    let cur = block.getInputTargetBlock('DO');
    while (cur) {
        if (runtimeGenerators[cur.type]) inner.push(runtimeGenerators[cur.type](cur));
        cur = cur.getNextBlock();
    }
    for (let i = 0; i < times; i++) {
        await runBlockQueue(inner);
    }
});

registerRuntimeGenerator('while_loop', block => async () => {
    let iter = 0, MAX_ITER = 1000;
    while (await evalInputAsync(block, 'COND', false) && iter++ < MAX_ITER) {
        const inner = [];
        let cur = block.getInputTargetBlock('DO');
        while (cur) {
            if (runtimeGenerators[cur.type]) inner.push(runtimeGenerators[cur.type](cur));
            cur = cur.getNextBlock();
        }
        await runBlockQueue(inner);
    }
});

// Variables
registerRuntimeGenerator('variables_set', block => {
    const variable = Blockly.Variables.getVariable(block.workspace, block.getFieldValue('VAR'));
    const varName = variable ? variable.name : block.getFieldValue('VAR');
    return async function() {
        const val = await evalInputAsync(block, 'VALUE');
        window.workspaceVars = window.workspaceVars || {};
        window.workspaceVars[varName] = val;
        console.log(`Variable ${varName} set to`, val);
    };
});

registerRuntimeGenerator('variables_get', block => {
    const variable = Blockly.Variables.getVariable(block.workspace, block.getFieldValue('VAR'));
    const varName = variable ? variable.name : block.getFieldValue('VAR');
    return async function() {
        const val = (window.workspaceVars || {})[varName];
        console.log(`Variable ${varName} retrieved:`, val);
        return val;
    };
});

// ============================================================================
// Variable dialog override (keeps your custom dialog behavior)
// ============================================================================

// showVariableDialog stays the same but we attach listeners only once
function showVariableDialog(defaultName = "") {
    return new Promise(resolve => {
        const dialog = document.getElementById('variableDialog');
        const input = document.getElementById('varNameInput');
        const btnOK = document.getElementById('btnVarOK');
        const btnCancel = document.getElementById('btnVarCancel');

        input.value = defaultName;
        dialog.style.display = 'block';

        // Ensure webview has focus
        try { input.focus({ preventScroll: true }); } catch(e){}

        function cleanup() {
            dialog.style.display = 'none';
            btnOK.removeEventListener('click', okHandler);
            btnCancel.removeEventListener('click', cancelHandler);
        }

        function okHandler() { cleanup(); resolve(input.value.trim()); }
        function cancelHandler() { cleanup(); resolve(null); }

        btnOK.addEventListener('click', okHandler);
        btnCancel.addEventListener('click', cancelHandler);
    });
}

// override Blockly.prompt
Blockly.prompt = async function(message, defaultValue, callback) {
    const name = await showVariableDialog(defaultValue);
    callback(name);
};

// ============================================================================
// Expose some internals for debugging (optional)
// ============================================================================
window._hk32_runtimeGenerators = runtimeGenerators;
window._hk32_evalInputAsync = evalInputAsync;
window._hk32_runWorkspaceBlocksAsync = runWorkspaceBlocksAsync;
