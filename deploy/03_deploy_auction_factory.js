const {ethers, deployments, upgrades} = require("hardhat");
const fs = require("fs");
const path = require("path");

module.exports = async ({deployments, getNamedAccounts}) => {
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();
    console.log("部署用户地址:", deployer);
    const auctionFactory = await ethers.getContractFactory("AuctionFactory");
    const auctionFactoryProxy = await upgrades.deployProxy(auctionFactory, [], {initializer: "initialize"});
    await auctionFactoryProxy.waitForDeployment();

    const proxyAddress = await auctionFactoryProxy.getAddress();
    const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("工厂代理合约地址:", proxyAddress);
    console.log("工厂目标合约地址:", implAddress);

    const storePath = path.resolve(__dirname, "./.cache/proxyAuctionFactory.json");
    fs.writeFileSync(storePath, JSON.stringify({
        proxyAddress,
        implAddress,
        abi: auctionFactory.interface.format("json")
    }));

    await save("auctionFactoryProxy",{
        abi: auctionFactory.interface.format("json"),
        address: proxyAddress
    });
};
module.exports.tags = ['deployAuctionFactory'];