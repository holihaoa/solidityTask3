const {ethers, upgrades} = require('hardhat')
const path = require("path");
const fs = require("fs");

module.exports = async function ({getNamedAccounts, deployments}) {
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();
    console.log('部署用户地址:', deployer);

    const storePath = path.resolve(__dirname, "./.cache/proxyNftAction.json");
    const storeData = fs.readFileSync(storePath, "utf-8");
    const {proxyAddress, implementAddress, abi} = JSON.parse(storeData);

    const NftAuctionV2 = await ethers.getContractFactory("NftAuctionV2");

    const nftAuctionProxyV2 = await upgrades.upgradeProxy(proxyAddress, NftAuctionV2, {kind: 'uups'});
    await nftAuctionProxyV2.waitForDeployment();
    const proxyAddressV2 = await nftAuctionProxyV2.getAddress();
    const implAddressV2 = await upgrades.erc1967.getImplementationAddress(proxyAddressV2);
    console.log("目标合约地址升级:", implAddressV2);
    fs.writeFileSync(storePath, JSON.stringify({proxyAddress: proxyAddressV2, implementAddress: implAddressV2, abi}));

    await save("NftAuctionProxyV2", {abi,address: proxyAddressV2});
}
module.exports.tags = ['upgradeNFTAuction'];