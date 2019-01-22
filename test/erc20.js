
const ERC20 = artifacts.require("./contracts/ERC20.sol");
const Crowdsale = artifacts.require("./contracts/Crowdsale.sol");

contract('ERC20', function(accounts) {
    beforeEach(async function() {
    token = await ERC20.deployed();
    crowsale =await Crowdsale.deployed();
});

    describe("Check initial values", function() {
        it("total supply should not be zero", async function() {
            let count = +(await token.totalSupply()).toString();
            assert.isTrue(count !== 0, "Wrong total supply");
        });

        it("total supply should be 100000", async function() {
            let count = +(await token.totalSupply()).toString();
            assert.isTrue(count == 100000 * 10e18, "Wrong total supply");
        });

        it("should put 15000 in the first account", async function() {
            account_balance = await token.balanceOf(accounts[10]);
            assert.isTrue(account_balance.toNumber() == 15000 * 10e18, "Wrong initial account balance");
        });

        it("should put 15000 in the second account", async function() {
            account_balance = await token.balanceOf(accounts[11]);
            assert.isTrue(account_balance.toNumber() == 15000 * 10e18, "Wrong initial account balance");
        });

        it("should put 15000 in the third account", async function() {
            account_balance = await token.balanceOf(accounts[12]);
            assert.isTrue(account_balance.toNumber() == 15000 * 10e18, "Wrong initial account balance");
        });

        it("should put 15000 in the fourth account", async function() {
            account_balance = await token.balanceOf(accounts[13]);
            assert.isTrue(account_balance.toNumber() == 15000 * 10e18, "Wrong initial account balance");
        });

    })

    describe("Check functions", function() {
        it("should send coin correctly", async function() {
            // Get initial balances of first and second account.
            var account_one = accounts[0];
            var account_two = accounts[1];

            var account_one_starting_balance;
            var account_two_starting_balance;
            var account_one_ending_balance;
            var account_two_ending_balance;

            var amount = 10 * 10e18;

            account_one_starting_balance = await token.balanceOf(account_one);
            account_two_starting_balance = await token.balanceOf(account_two);
            token.transfer(account_two, amount, {from: account_one});
            account_one_ending_balance = await token.balanceOf(account_one);
            account_two_ending_balance = await token.balanceOf(account_two);
        
            assert.equal(account_one_ending_balance.toNumber(), account_one_starting_balance.toNumber() - amount, "Amount wasn't correctly taken from the sender");
            assert.equal(account_two_ending_balance.toNumber(), account_two_starting_balance.toNumber() + amount, "Amount wasn't correctly sent to the receiver");
        });

        it("migration agents should not be set", async function() {
            let migrationAgent = await token.migrationAgent();
            assert.isTrue(migrationAgent == 0x0, "Migration agent is set");
        });

        it("crowdsale should not be set", async function() {
            let crowdsale = await token.crowdsale();
            assert.isTrue(crowdsale == 0x0, "Crowdsale is set");
        });

        it("crowdsale setup", async function() {
            await token.setCrowdsale(crowsale.address);
            let crowdsale = await token.crowdsale();
            assert.isTrue(crowdsale !== 0x0, "Crowdsale is not set");
            assert.isTrue(crowdsale == crowsale.address, "Crowdsale is wrang");
        });

        it("crowdsale balance", async function() {
            account_balance = await token.balanceOf(crowsale.address);
            assert.isTrue(account_balance.toNumber() == 40000 * 10e18, "Wrong crowdsale balance");
        });

    });

});
