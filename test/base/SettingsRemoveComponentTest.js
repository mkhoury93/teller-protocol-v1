// JS Libraries
const withData = require('leche').withData;
const { t, toBytes32 } = require('../utils/consts');
const { settings } = require('../utils/events');

// Mock contracts

// Smart contracts
const Settings = artifacts.require("./base/Settings.sol");

contract('SettingsRemoveComponentTest', function (accounts) {
    let instance;
    const COMPONENT_NAME = 'ComponentName';
    const INITIAL_VERSION = 12;
    const NOT_PRESENT = 0;

    beforeEach('Setup for each test', async () => {
        instance = await Settings.new(1, 1, 1, 1, 1, 1, 1);
        instance.addNewComponent(toBytes32(web3, COMPONENT_NAME), INITIAL_VERSION);
    });

    withData({
        _1_basic: [0, COMPONENT_NAME, undefined, false],
        _2_notOwner: [2, COMPONENT_NAME, 'PauserRole: caller does not have the Pauser role', true],
        _3_emptyComponentName: [0, '','MISSING_COMPONENT_NAME', true],
    }, function(senderIndex, componentName, expectedErrorMessage, mustFail) {
        it(t('user', 'removeComponent', 'Should (or not) be able to add a new node component.', mustFail), async function() {
            // Setup
            const sender = accounts[senderIndex];
            const byteComponentName = toBytes32(web3, componentName);
            try {
                // Invocation
                const result = await instance.removeComponent(byteComponentName, { from: sender });
                
                // Assertions
                assert(!mustFail, 'It should have failed because data is invalid.');
                assert(result);
                
                // Validating state variables were modified
                const componentVersion = await instance.minimumNodeRequirements(byteComponentName);
                assert.equal(componentVersion, NOT_PRESENT);
                
                // Validating events were emitted
                settings
                    .removeComponent(result)
                    .emitted(sender, byteComponentName, INITIAL_VERSION);

            } catch (error) {
                // Assertions
                assert(mustFail);
                assert(error);
                assert.equal(error.reason, expectedErrorMessage);
            }
        });
    });

});