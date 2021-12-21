const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { utils, BigNumber } = ethers;

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});

describe("Guild Mode", function () {
  // assign address
  before(async function() {
    this.signers = await ethers.getSigners();
    this.alice = this.signers[0];
    this.bob = this.signers[1];
    this.carol = this.signers[2];
    this.minter = this.signers[4];
    
    // this.GuildMode = await ethers.getContractFactory("MechaGuild")
  })

  // initial Token
  this.beforeEach(async function() {
    this.AcceptedToken = await ethers.getContractFactory("InitialToken", this.minter);
    this.ttm = await this.AcceptedToken.deploy("TuanTTM", "TTM", utils.parseEther("100000000"));
    await this.ttm.deployed();
  })
  it("create a new guild", async function() {
    const GuildContract = await ethers.getContractFactory("MechGuild");
    // const guildContract = await GuildContract.deploy();
    // await guildContract.deployed();
    // await this.
    this.guild = await upgrades.deployProxy(GuildContract, [this.ttm.address], {
      initializer: '__MechaGuild_init'
    });
    this.guild.deployed();
    console.log(this.guild, 'this guild-------------------------')
  })
})