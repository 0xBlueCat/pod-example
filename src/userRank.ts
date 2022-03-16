import { ethers } from "ethers";
import userRankAbi from "../artifacts/contracts/UserRank.sol/UserRank.json";
import {provider, wallet} from "./airdrop";

const iface = new ethers.utils.Interface(userRankAbi.abi);
const userRankContractAddress = "0xdacdF224F4f9254dDFaed634c2e9906F6B05249c";
const userRankContract = new ethers.Contract(
  userRankContractAddress,
  iface,
  provider
).connect(wallet);

async function upgradeUserRank(): Promise<void> {
  const tx = await userRankContract.upgradeRank();
  tx.wait();

  const rcp = await provider.getTransactionReceipt(tx.hash);
  const parsedLog = await iface.parseLog(rcp.logs[1]);
  const newRank = parsedLog.args.newRank;
  console.log(`Address:${await wallet.getAddress()} newRank:${newRank}`);
}

async function getUserRank():Promise<number>{
  //query rank from chain
  const rank = await userRankContract.getUserRank(await wallet.getAddress());
  console.log(`Address:${await wallet.getAddress()} Rank:${rank}`);
  return rank;
}

export async function testUserRank():Promise<void>{
  await upgradeUserRank();
  await getUserRank();
}

async function main() {
  await testUserRank();
}

void main();
