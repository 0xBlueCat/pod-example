import {testUserRank} from "./userRank";
import {testAirdrop} from "./airdrop";

async function main():Promise<void>{
    await testUserRank();
    await testAirdrop();
}

void main();
