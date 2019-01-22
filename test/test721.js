const ERC721 = artifacts.require("ERC721");
const assert = require("chai").assert;
const truffleAssert = require('truffle-assertions');

contract('ERC721', (accounts) => {
    let erc721;
    let mintedTokenId;
    let transferredTokenId;
    const account1 = accounts[0];
    const account2 = accounts[1];

    before(async () => {
        erc721 = await ERC721.new("token", "token", {from: account1});
        await erc721.setLotterySellerContract(account1, {from: account1});            
    });

    it("should not be able to set lottery address if not owner", async () => {
        await truffleAssert.reverts(
            erc721.setLotteryAddress(account2, {from: account2})
        );
    });

    it("should not be able to set lottery seller address if not owner", async () => {
        await truffleAssert.reverts(
            erc721.setLotterySellerContract(account2, {from: account2})
        );
    });

    it("should be able to mint token", async () => {
        let tx = await erc721.mint(account1, 0, 0, {from: account1});
        truffleAssert.eventEmitted(tx, 'Transfer', (ev) => {
            mintedTokenId = Number(ev.tokenId);
            return ev.to === account1;
        });
    });

    it("should not be able to view token owner of inexisting token", async () => {
        await truffleAssert.reverts(
            erc721.ownerOf((mintedTokenId + 1), {from: account1})
        );
    });

    it("should be able to view token owner", async () => {
        await erc721.ownerOf(mintedTokenId, {from: account1});
    });

    it("should not be able to view balance of 0", async () => {
        await truffleAssert.reverts(
            erc721.balanceOf(0, {from: account1})
        );
    });

    it("should be able to view own balance", async () => {
        let balance = await erc721.balanceOf(account1, {from: account1});
        assert.equal(balance, 1, "Account 1 got different amount of tokens than what was minted");
    });

    it("should not be able to transfer token that is not owned", async () => {
        await truffleAssert.reverts(
            erc721.transferFrom(account1, account2, mintedTokenId, {from: account2})
        );
    });

    it("should be transfer token", async () => {
        let tx = await erc721.transferFrom(account1, account2, mintedTokenId, {from: account1});
        truffleAssert.eventEmitted(tx, 'Transfer', (ev) => {
            transferredTokenId = Number(ev.tokenId);
            return ev.to === account2 && ev.from === account1;
        });
    });

    it("should be able to view transferred token", async () => {
        let balance = await erc721.balanceOf(account1, {from: account1});
        assert.equal(balance, 0, "Account 1 still has balance of 1 token after it's transfer");

        let newOwner = await erc721.ownerOf(transferredTokenId, {from: account2});
        assert.equal(newOwner, account2, "Account 2 didn't receive the transferred token");
    });
})
