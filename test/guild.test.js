const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const { utils, BigNumber } = ethers;
const { time } = require('@openzeppelin/test-helpers')

describe("Guild basic function ", function () {
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
  beforeEach(async function() {
    this.AcceptedToken = await ethers.getContractFactory("InitialToken", this.minter);
    this.ttm = await this.AcceptedToken.deploy("GuildTicket", "GTK", utils.parseEther("100000000"));
    await this.ttm.deployed();

    // Deploy the guild contract and initialize TTM token
    const GuildContract = await ethers.getContractFactory("MechGuild");
    this.guild = await upgrades.deployProxy(GuildContract, [this.ttm.address], {
      initializer: '__MechaGuild_init'
    });
    this.guild.deployed();

    // create the first guild for minter
    await this.guild.connect(this.minter).createGuild(
      (await time.latest()).toNumber(),
      this.minter.address
    )
  })
  it("minter create a new guild", async function() {
    const guildArray = await this.guild.returnGuild()
    expect(guildArray[0].guildMaster).to.equal(this.minter.address)
  });

  it("change guild master to other address not in the guild", async function() {
    try {
      // change guild master to alice who is not inside the guild
      await this.guild.connect(this.minter).changeGuildMaster(this.alice.address)
    } catch (error) {
      expect(error.message)
        .to.equal(`VM Exception while processing transaction: reverted with reason string 'Not the same guild'`)
    }
  });

  it("change guild master to other address inside the guild", async function () {
    // add alice to the guild
    await this.guild.connect(this.minter).addMemberToGuild(this.alice.address)
    const aliceGuild = await this.guild.returnMemberGuild(this.alice.address)
    const minterGuild = await this.guild.returnMemberGuild(this.minter.address)

    // change master guild
    await this.guild.connect(this.minter).changeGuildMaster(this.alice.address)

    const guildArray = await this.guild.returnGuild()
    expect(guildArray[0].guildMaster).to.equal(this.alice.address)
  });

  it("remove member and add again", async function() {
    await this.guild.connect(this.minter).addMemberToGuild(this.alice.address)
    await this.guild.connect(this.minter).kickMember(this.alice.address)
    try {
      await this.guild.connect(this.minter).addMemberToGuild(this.alice.address)
    } catch(error) {
      expect(error.message)
        .to.equal(`VM Exception while processing transaction: reverted with reason string 'Have not ended penalty time'`)
    }
  });

  it("out of guild successfully", async function() {
    await this.guild.connect(this.minter).addMemberToGuild(this.alice.address)
    await this.guild.connect(this.alice).outOfGuild()
    const aliceGuild = await this.guild.returnMemberGuild(this.alice.address)

    expect(aliceGuild).to.equal(0)
  });

  it("request join private guild", async function() {
    try{
      await this.guild.connect(this.bob).requestJoinGuild(1)
    } catch (error) {
      expect(error.message)
        .to.equal(`VM Exception while processing transaction: reverted with reason string 'not a public guild'`)
    }
  })

  it("request join public guild", async function() {
    await this.guild.connect(this.minter).changePublicStatus(true)
    await this.guild.connect(this.bob).requestJoinGuild(1)
    const bobGuild = await this.guild.returnMemberGuild(this.bob.address)
    expect(bobGuild).to.equal(1)
  });

  it("create other guild while still be in certain guild", async function() {
    try {
      await this.guild.connect(this.minter).createGuild(
        (await time.latest()).toNumber(),
        this.minter.address
      )
    } catch(error) {
      expect(error.message)
        .to.equal(`VM Exception while processing transaction: reverted with reason string 'Must be not in certain guild'`)
    }
  })

  it("guild master out guild", async function() {
    try {
      await this.guild.connect(this.minter).outOfGuild()
    } catch (error) {
      expect(error.message)
        .to.equal(`VM Exception while processing transaction: reverted with reason string 'Be the master of guild'`)
    }
  })
})