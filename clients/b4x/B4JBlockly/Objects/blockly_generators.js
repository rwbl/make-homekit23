// Run all blocks sequentially
async function runBlockQueue(blocks) {
    for (const fn of blocks) {
        if (typeof fn === "function") {
            await fn(); // execute async block
        }
    }
}

// Send command to B4J (here just alert for testing)
async function sendCommandToB4JAsync(obj) {
    alert(JSON.stringify(obj));
}

// ======================================================================
// GENERATORS
// ======================================================================

// --- Custom block generators ---

Blockly.JavaScript['yellow_on'] = block => async () => {
    await sendCommandToB4JAsync({ command: "yellow_on" });
};

Blockly.JavaScript['yellow_off'] = block => async () => {
    await sendCommandToB4JAsync({ command: "yellow_off" });
};

Blockly.JavaScript['yellow_led'] = block => async () => {
    const state = block.getFieldValue("STATE"); // "ON" or "OFF"
    await sendCommandToB4JAsync({ command: state === "ON" ? "yellow_on" : "yellow_off" });

    // Optional: dynamically change block color for visual feedback
    block.setColour(state === "ON" ? 90 : 60); // Green if ON, yellow if OFF
};

Blockly.JavaScript['delay'] = block => async () => {
    const ms = parseInt(block.getFieldValue("DELAY") || 1000);
    await sendCommandToB4JAsync({ command: "delay", value: ms });
    await new Promise(resolve => setTimeout(resolve, ms));
};

// Start block: returns async function that executes connected blocks
Blockly.JavaScript['start_block'] = block => async () => {
    const nextBlock = block.getNextBlock();
    const blocksToRun = [];
    let current = nextBlock;
    while (current) {
        const gen = Blockly.JavaScript[current.type];
        if (gen) blocksToRun.push(gen(current));
        current = current.getNextBlock();
    }
    await sendCommandToB4JAsync({ command: "start" });
    await runBlockQueue(blocksToRun);
};

// Stop block: just a placeholder (could be used for logic in the future)
Blockly.JavaScript['stop_block'] = block => async () => {
    await sendCommandToB4JAsync({ command: "stop" });
};

// Repeat loop
/*
<value name="TIMES">
  <block type="math_number">
    <field name="NUM">5</field>
  </block>
</value>
*/
Blockly.JavaScript['repeat_loop'] = block => async () => {
    // Get TIMES input block
    const timesBlock = block.getInputTargetBlock('TIMES');
    const times = (timesBlock && timesBlock.type === 'math_number') 
                  ? parseInt(timesBlock.getFieldValue('NUM') || 1)
                  : 1;

    // Build inner block queue
    const innerBlocks = [];
    let current = block.getInputTargetBlock('DO');
    while (current) {
        const gen = Blockly.JavaScript[current.type];
        if (gen) innerBlocks.push(gen(current));
        current = current.getNextBlock();
    }

    // Run inner blocks times times
    for (let i = 0; i < times; i++) {
        await runBlockQueue(innerBlocks);
    }
};

Blockly.JavaScript['while_loop'] = block => async () => {
    // Get condition
    let cond = block.getFieldValue('COND') === 'TRUE';

    // Build inner block queue
    const innerBlocks = [];
    let current = block.getInputTargetBlock('DO'); // later you can adapt input name
    while (current) {
        const gen = Blockly.JavaScript[current.type];
        if (gen) innerBlocks.push(gen(current));
        current = current.getNextBlock();
    }

    // Simple safety limit to prevent infinite loops
    const MAX_ITER = 1000;
    let iter = 0;

    // Run while condition is true
    while (cond && iter < MAX_ITER) {
        iter++;
        await runBlockQueue(innerBlocks);
        // For demo, checkbox condition does not change; in real usage you would update cond
    }
};

// Show the variable dialog and return a Promise with the result
function showVariableDialog(defaultName = "") {
    return new Promise((resolve) => {
        const dialog = document.getElementById('variableDialog');
        const input = document.getElementById('varNameInput');
        const btnOK = document.getElementById('btnVarOK');
        const btnCancel = document.getElementById('btnVarCancel');

        input.value = defaultName;
        dialog.style.display = 'block';
        input.focus();

        function cleanup() {
            dialog.style.display = 'none';
            btnOK.removeEventListener('click', okHandler);
            btnCancel.removeEventListener('click', cancelHandler);
        }

        function okHandler() {
            cleanup();
            resolve(input.value.trim());
        }

        function cancelHandler() {
            cleanup();
            resolve(null); // user canceled
        }

        btnOK.addEventListener('click', okHandler);
        btnCancel.addEventListener('click', cancelHandler);
    });
}

// Override Blockly's prompt for variable creation
Blockly.prompt = async function(message, defaultValue, callback) {
    const name = await showVariableDialog(defaultValue);
    callback(name); // pass the result back to Blockly
};

// Called from B4J to update block state
function updateDeviceState(blockType, state) {
    const allBlocks = workspace.getAllBlocks();
    allBlocks.forEach(block => {
        if (block.type === blockType) {
            // Update color or dropdown depending on state
            if (blockType === "yellow_led") {
                block.setFieldValue(state, "STATE");      // update dropdown
                block.setColour(state === "ON" ? 90 : 60); // update color
            }
        }
    });
}
