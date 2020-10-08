const core = require('@actions/core');
const github = require('@actions/github');

console.log(`github.workspace : ${ github.workspace }`);
console.log(`env.GITHUB_WORKSPACE : ${ env.GITHUB_WORKSPACE }`);
console.log(`github.repository : ${ github.repository }`);
const time = (new Date()).toTimeString();
core.setOutput("compiled_output", time);
