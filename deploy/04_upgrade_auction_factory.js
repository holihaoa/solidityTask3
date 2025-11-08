const {ethers,upgrades} = require('hardhat');
const fs = require('fs');
const path = require('path');

module.exports = async function({deployments,getNamedAccounts}) {
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();
    console.log('部署用户地址:', deployer);

    const storePath = path.resolve(__dirname, "./.cache/proxyAuctionFactory.json");
    const storeData = fs.readFileSync(storePath, 'utf8');
    const {proxyAddress, implAddress, abi}= JSON.parse(storeData);
    const auctionFactoryV2= await ethers.getContractFactory("AuctionFactoryV2");

    const auctionFactoryProxyV2 = await upgrades.upgradeProxy(proxyAddress, auctionFactoryV2);
    await auctionFactoryProxyV2.waitForDeployment();
    const proxyAddressV2 = await auctionFactoryProxyV2.getAddress();
    const implAddressV2 = await upgrades.erc1967.getImplementationAddress(proxyAddressV2);
    console.log("目标合约地址升级:", implAddressV2);
    fs.writeFileSync(storePath, JSON.stringify({proxyAddress: proxyAddressV2, implementAddress: implAddressV2, abi}));
    await save("auctionFactoryProxy",{
        abi: auctionFactoryV2.interface.format("json"),
        address: proxyAddressV2});
}
module.exports.tags = ['upgradeAuctionFactory'];