const { inputToConfig } = require("@ethereum-waffle/compiler");
const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("Token Contract", function () {
    let Token;
    let token;
    let owner;

    beforeEach(async function () {
        Token = await ethers.getContractFactory("Token");
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        token = await Token.deploy("https:://test.jp");

        //owner
        await token.connect(addr1).mintToken(20, { value: ethers.utils.parseEther("0.2") });
        //addr1
        await token.connect(addr2).mintToken(20, { value: ethers.utils.parseEther("0.2") });
    });

    describe("mintToken", async function () {
        it("Should revert invalid mintAmount entered", async function () {
            await expect(token.connect(addr3).mintToken(30, { value: ethers.utils.parseEther("0.3") })).to.be.revertedWith("Over max mint amount per person!");
        });

        it("Should revert not enough charge entered", async function () {
            await expect(token.connect(addr3).mintToken(10, { value: ethers.utils.parseEther("0.01") })).to.be.revertedWith("Insufficient charge!");
        });

        it("Should emit mintToken event", async function () {
            await token.connect(addr3).mintToken(10, { value: ethers.utils.parseEther("0.1") });
            // assert.equal(total, totalSupply);
            await expect(await token.totalSupply()).to.equal(50);
        })
    })

    describe("pause", function () {
        it("Should emit pause event (true)", async function () {
            await token.pause(true);
            await expect(token.connect(addr3).mintToken(10, { value: ethers.utils.parseEther("0.1") })).to.be.revertedWith("Not publish!");
        });

        it("Should emit pause event (false)", async function () {
            await token.pause(false);
            await token.connect(addr3).mintToken(10, { value: ethers.utils.parseEther("0.1") });
            await expect(await token.totalSupply()).to.equal(50);
        })
    });

    describe("From withdrawBalance to devidend", async function () {
        it("Should emit withdraw event", async function () {
            //withdraw contract balance by owner
            await token.connect(addr3).mintToken(20, { value: ethers.utils.parseEther("0.2") });

            //check owner balance = 0.6
            await expect(await token.withdrawBalance()).to.changeEtherBalance(owner, ethers.utils.parseEther("0.6"));

            //check contract balance = 0
            contractBalance = await token.provider.getBalance(token.address)
            await expect(contractBalance).to.equal(0);

            //owner deposit
            await expect(await token.depositDividend({ value: ethers.utils.parseEther("1") })).to.changeEtherBalance(owner, ethers.utils.parseEther("-1"));

            //check contract balance = 100
            contractBalance = await token.provider.getBalance(token.address);
            await expect(contractBalance).to.equal(ethers.utils.parseEther("1"));

            //check address balance after receive dividend
            await expect(await token.connect(addr1).withdrawDividend).to.changeEtherBalance(addr1, ethers.utils.parseEther("0.333333333333333333"));
            await expect(await token.connect(addr2).withdrawDividend).to.changeEtherBalance(addr2, ethers.utils.parseEther("0.333333333333333333"));
            await expect(await token.connect(addr3).withdrawDividend).to.changeEtherBalance(addr3, ethers.utils.parseEther("0.333333333333333333"));

        });

    });


});