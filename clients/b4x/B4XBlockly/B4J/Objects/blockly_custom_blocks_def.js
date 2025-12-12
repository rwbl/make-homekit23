
const toolboxJson = {
  "kind": "categoryToolbox",
  "contents": [
    {
      "kind": "category",
      "name": "HomeKit32",
      "colour": "120",
      "contents": [
        { "kind": "block", "type": "connect" },
        { "kind": "block", "type": "disconnect" },
        { "kind": "block", "type": "yellow_led_on" },
        { "kind": "block", "type": "yellow_led_off" },
        { "kind": "block", "type": "yellow_led" },
        { "kind": "block", "type": "delay" },
        { "kind": "block", "type": "dht11_sensor" },
        { "kind": "block", "type": "open_door" }
      ]
    },
    {
      "kind": "category",
      "name": "Program Flow",
      "colour": "0",
      "contents": [
        { "kind": "block", "type": "start_block" },
        { "kind": "block", "type": "stop_block" },
        { "kind": "block", "type": "comment_block" },
        { "kind": "block", "type": "log_block" },
        { "kind": "block", "type": "text_literal" }
      ]
    },
    {
      "kind": "category",
      "name": "Loops",
      "colour": "120",
      "contents": [
        {
          "kind": "block",
          "type": "repeat_loop",
          "inputs": {
            "TIMES": {
              "shadow": {
                "type": "math_number",
                "fields": { "NUM": 5 }
              }
            }
          }
        },
        { "kind": "block", "type": "while_loop" }
      ]
    },
    {
      "kind": "category",
      "name": "Logic",
      "colour": "210",
      "contents": [
        { "kind": "block", "type": "logic_boolean" },
        { "kind": "block", "type": "logic_compare" },
        { "kind": "block", "type": "logic_operation" },
        { "kind": "block", "type": "logic_negate" },
        { "kind": "block", "type": "logic_if" },
        { "kind": "block", "type": "logic_if_else" },
        { "kind": "block", "type": "logic_else_if" }
      ]
    },
    {
      "kind": "category",
      "name": "Math",
      "colour": "230",
      "contents": [
        {
          "kind": "block",
          "type": "math_number",
          "fields": { "NUM": 0 }
        }
      ]
    },
    {
      "kind": "category",
      "name": "Variables",
      "custom": "VARIABLE",
      "colour": "330"
    }
  ]
};
