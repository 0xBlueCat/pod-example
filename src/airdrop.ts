import { ethers } from "ethers";
import airdropFactoryAbi from "../artifacts/contracts/AirdropFactory.sol/AirdropFactory.json";
import airdropAbi from "../artifacts/contracts/Airdrop.sol/Airdrop.json";

const airdropFace = new ethers.utils.Interface(airdropAbi.abi);
const airdropFactoryFace = new ethers.utils.Interface(airdropFactoryAbi.abi);
export const provider = new ethers.providers.JsonRpcProvider("https://data-seed-prebsc-1-s1.binance.org:8545/");
export const wallet = new ethers.Wallet(
  "xxxxx",
  provider
);
const airdropFactoryContractAddress =
  "0xAC6359357FC7e0b80F7A9c4b43f78bB9897835e7";
const airdropFactoryContract = new ethers.Contract(
  airdropFactoryContractAddress,
  airdropFactoryFace,
  provider
).connect(wallet);

async function createNewAirdrop(): Promise<string> {
  const tx = await airdropFactoryContract.createAirdropContract();
  tx.wait();

  const rcp = await provider.getTransactionReceipt(tx.hash);
  const parsedLog = await airdropFace.parseLog(rcp.logs[2]);
  return parsedLog.args.contractAddress;
}

async function activeUser(airdropContract: ethers.Contract): Promise<void> {
  const tx = await airdropContract.activate();
  tx.wait();

  const rcp = await provider.getTransactionReceipt(tx.hash);
  const parsedLog = await airdropFace.parseLog(rcp.logs[1]);
  console.log(
    `Activate TagClassId:${parsedLog.args.tagClassId} address:${parsedLog.args.user}`
  );
}

async function isActivate(airdropContract: ethers.Contract): Promise<void> {
  //query from chain
  const address = await wallet.getAddress();
  const activate = await airdropContract.isActivate(address);
  console.log(`Address:${address} isActivate:${activate}`);
}

export async function testAirdrop():Promise<void>{
  const airdropContractAddress = await createNewAirdrop();//调用createNewAirdrop这个合约方法的账户必须是合约部署的账户
  const airdropContract = new ethers.Contract(
      airdropContractAddress,
      airdropFace,
      provider
  ).connect(wallet);
  await activeUser(airdropContract);
  await isActivate(airdropContract);
}

async function main() {
  await testAirdrop();
}

void main();
