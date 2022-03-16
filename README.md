# 部署

安装依赖
yarn install

编译合约
yarn compile 

配置参数
hardhat.config.ts 配置文件中配置 链的RPC和部署用的地址私钥
scripts/deploy.ts 文件中配置参数
```typescript
const TagClassContractAddress = "0xD5341cc8B1BC711CEf0802D4Da97e7D341e9B1D2";//TagClass合约地址
const TagContractAddress = "0xc126d23e45b7d1cAF93f3c0A2B0aC13b860d1533";//Tag合约地址
const PLCAddress = "0x3CFDa5D06941035B554AF88816F2C3ee0CEF48FC";//PLC合约地址
const GDSAddress = "0xa431AB99972106c78607725Fe327B5bC70ef469A";//GDS合约地址
const userRankPLCFees = ["0","0","0","0","0","0","0","0","0","0"];//用户升级PLC收费金额
const userRankGDSFees = ["0","0","0","0","0","0","0","0","0","0"];//用户升级GDS收费额金额
const airdropPLCFee = "0";//用户激活收费金额
```

部署BSC环境
npx hardhat run scripts/deploy.ts --network bsc 

部署BSC测试环境
npx hardhat run scripts/deploy.ts --network bscTestnet

# 运行

配置参数
src/airdrop.ts 
```typescript
export const provider = new ethers.providers.JsonRpcProvider("https://data-seed-prebsc-1-s1.binance.org:8545/");
export const wallet = new ethers.Wallet(
  "xxxxx",//运行账户的私钥
  provider
);
const airdropFactoryContractAddress = "0xAC6359357FC7e0b80F7A9c4b43f78bB9897835e7"; //airdropFactory合约的地址

const userRankContractAddress = "0xdacdF224F4f9254dDFaed634c2e9906F6B05249c";//userRank合约地址
```

运行测试代码
yarn start
