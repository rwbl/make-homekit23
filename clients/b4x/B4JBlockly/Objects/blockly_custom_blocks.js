Blockly.defineBlocksWithJsonArray([
  {
    "type": "yellow_on",
    "message0": "yellow LED on",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 60
  },
  {
    "type": "yellow_off",
    "message0": "yellow LED off",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 60
  },
  {
    "type": "open_door",
    "message0": "Open Door",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 160
  },
  {
    "type": "delay",
    "message0": "wait %1 ms",
    "args0": [
      { "type": "field_number", "name": "DELAY", "value": 1000, "min": 0 }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 120
  },
// Repeat loop: has a value input TIMES (a number) and a statement input DO (stack of blocks)
{
  "type": "repeat_loop",
  "message0": "repeat %1 times do %2",
  "args0": [
    { "type": "input_value", "name": "TIMES", "check": "Number" },   // numeric input (can be math_number)
    { "type": "input_statement", "name": "DO" }                     // statement input for inner blocks
  ],
  "previousStatement": null,
  "nextStatement": null,
  "colour": 120
},

// While loop: has a value input COND (a boolean expression) and a statement input DO (stack of blocks)
{
  "type": "while_loop",
  "message0": "while %1 do %2",
  "args0": [
    { "type": "input_value", "name": "COND", "check": "Boolean" },  // boolean expression input
    { "type": "input_statement", "name": "DO" }                     // statement input for inner blocks
  ],
  "previousStatement": null,
  "nextStatement": null,
  "colour": 120
},
{
  "type": "logic_boolean_custom",
  "message0": "%1",
  "args0": [
    {
      "type": "field_dropdown",
      "name": "BOOL",
      "options": [
        ["true", "TRUE"],
        ["false", "FALSE"]
      ]
    }
  ],
  "output": "Boolean",
  "colour": 210
},

{
  "type": "logic_compare_custom",
  "message0": "%1 %2 %3",
  "args0": [
    { "type": "input_value", "name": "A" },
    {
      "type": "field_dropdown",
      "name": "OP",
      "options": [
        ["=", "EQ"],
        ["!=", "NEQ"],
        ["<", "LT"],
        [">", "GT"],
        ["<=", "LE"],
        [">=", "GE"]
      ]
    },
    { "type": "input_value", "name": "B" }
  ],
  "output": "Boolean",
  "colour": 210
}
  
]);

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

Blockly.JavaScript['delay'] = block => async () => {
    const ms = parseInt(block.getFieldValue("DELAY") || 1000);
    await sendCommandToB4JAsync({ command: "delay", value: ms });
    await new Promise(resolve => setTimeout(resolve, ms));
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
