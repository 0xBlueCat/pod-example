// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "ethers";
const hre = require("hardhat");

//配置参数
const TagClassContractAddress = "0xD5341cc8B1BC711CEf0802D4Da97e7D341e9B1D2";
const TagContractAddress = "0xc126d23e45b7d1cAF93f3c0A2B0aC13b860d1533";
const PLCAddress = "0x3CFDa5D06941035B554AF88816F2C3ee0CEF48FC";
const GDSAddress = "0xa431AB99972106c78607725Fe327B5bC70ef469A";
const userRankPLCFees = ["0","0","0","0","0","0","0","0","0","0"];
const userRankGDSFees = ["0","0","0","0","0","0","0","0","0","0"];
const airdropPLCFee = "0";

export async function deploy():Promise<void>{
  await deployUserRank();
  await deployAirdropFactory();
}

export async function deployUserRank( ):Promise<string>{
  const userRankContract = await hre.ethers.getContractFactory("UserRank");
  const userRank = await userRankContract.deploy(TagClassContractAddress, TagContractAddress, PLCAddress, userRankPLCFees, GDSAddress, userRankGDSFees);
  await userRank.deployed();

  const deployTxHash = userRank.deployTransaction.hash;
  const rcp = await hre.ethers.provider.getTransactionReceipt(deployTxHash);

  const parsedLogs = await userRankContract.interface.parseLog(rcp.logs[2]);
  const userRankTagClassId = parsedLogs.args.userRankTagClassId

  console.log("UserRank deploy to:", userRank.address, " UserRankTagClassId:",userRankTagClassId);
  return userRank.address;
}

export async function deployAirdropFactory():Promise<string>{
  const airdropFactoryContract = await hre.ethers.getContractFactory("AirdropFactory");
  const airdropFactory = await airdropFactoryContract.deploy(TagClassContractAddress, TagContractAddress, PLCAddress, airdropPLCFee);
  await airdropFactory.deployed();

  console.log("AirdropFactory deploy to:", airdropFactory.address);
  return airdropFactory.address;
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  await deploy();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
