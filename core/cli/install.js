#!/usr/bin/env node

require('../api/node_modules/nocamel');
const Package = require('../api/src/package');

const packageSpec = process.argv[2];
if (!packageSpec) {
    console.error('Usage: install.js <language>[=<version>]');
    process.exit(2);
}

const [language, version = '*'] = packageSpec.split('=');
if (!language || !/^[a-z0-9+#.-]+$/i.test(language)) {
    console.error(`Invalid runtime package: ${packageSpec}`);
    process.exit(2);
}

async function install() {
    const pkg = await Package.get_package(language, version);
    if (!pkg) {
        throw new Error(`Runtime package not found: ${packageSpec}`);
    }

    const result = await pkg.install();
    const state = result.alreadyInstalled ? 'Already installed' : 'Installed';
    console.log(`${state}: ${result.language} ${result.version}`);
}

install().catch(error => {
    console.error(`Installation failed for ${packageSpec}: ${error.message}`);
    process.exitCode = 1;
});
