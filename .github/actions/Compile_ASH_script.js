const core = require('@actions/core');

console.log("Hello");
const time = (new Date()).toTimeString();
core.setOutput("compiled_output", time);
