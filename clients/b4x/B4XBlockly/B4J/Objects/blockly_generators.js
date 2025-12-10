/*
	Project:	HomeKit32
	File:		blockly_generators.js
	Brief:		Handle block actions.
				Actions, in form of commands (JSON string) are send to B4J using the redirected alert function.
				Example:
				Set the state of the Yellow LED by sending JSON formatted command { command: "yellow_led_on"  }.
				In B4J the JSON string is parsed and the command executed.
*/

// ======================================================================
// GENERATORS
// ======================================================================

// ======================================================================
// --- Custom block generators ---
// ======================================================================

Blockly.JavaScript['connect'] = block => async () => {
    await sendCommandToB4JAsync({ command: "connect" });
};

Blockly.JavaScript['disconnect'] = block => async () => {
    await sendCommandToB4JAsync({ command: "disconnect" });
};

Blockly.JavaScript['yellow_led_on'] = block => async () => {
    await sendCommandToB4JAsync({ command: "yellow_led_on" });
};

Blockly.JavaScript['yellow_led_off'] = block => async () => {
    await sendCommandToB4JAsync({ command: "yellow_led_off" });
};

Blockly.JavaScript['yellow_led'] = block => async () => {
    const state = block.getFieldValue("STATE"); // "ON" or "OFF"
    await sendCommandToB4JAsync({ command: state === "ON" ? "yellow_led_on" : "yellow_led_off" });

    // Optional: dynamically change block color for visual feedback
    block.setColour(state === "ON" ? 90 : 60); // Green if ON, yellow if OFF
};

Blockly.JavaScript['delay'] = block => async () => {
    const ms = parseInt(block.getFieldValue("DELAY") || 1000);
    await sendCommandToB4JAsync({ command: "delay", value: ms });
    await new Promise(resolve => setTimeout(resolve, ms));
};

// ======================================================================
// --- Standard block generators ---
// ======================================================================

Blockly.JavaScript['comment_block'] = function(block) {
    const comment = block.getFieldValue('COMMENT');
    return ''; // no code generated
};

/*
Blockly.JavaScript['log_block'] = block => async () => {
    const msg = Blockly.JavaScript.valueToCode(block, 'TEXT', Blockly.JavaScript.ORDER_ATOMIC) || '""';
    await sendCommandToB4JAsync({ command: msg });
    // return "console.log(${msg});\n";
};
*/

/*
	In B4J receiving like: 
	13:20:56 - [WebViewBlockly_Event] msg={"command":"log","value":"Setting LED ON"}
*/
Blockly.JavaScript['log_block'] = block => async () => {
    // Get the value of connected input block
    const inputBlock = block.getInputTargetBlock('TEXT');
    let msg = '';
    if (inputBlock) {
        const gen = Blockly.JavaScript[inputBlock.type];
        if (gen) {
            // Run the input block async function to get its result
            const resultFn = gen(inputBlock);
            if (typeof resultFn === "function") {
                // Await the result if the block itself returns a value
                msg = await resultFn();
            }
        }
    }

    // Fallback: use empty string if no input
    msg = msg || '[log empty]';

    // Output to console or send to B4J
    await sendCommandToB4JAsync({ command: "log", value: msg });
    // console.log(msg);
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

Blockly.JavaScript['text_literal'] = block => async () => {
    return block.getFieldValue('TEXT');
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
