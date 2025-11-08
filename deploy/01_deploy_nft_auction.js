const {upgrades, ethers} = require('hardhat');
const fs = require('fs');
const path = require('path');

module.exports = async ({getNamedAccounts, deployments}) => {
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();
    console.log("部署用户地址:", deployer);
    const NftAuction = await ethers.getContractFactory("NftAuction");

    const nftAuctionProxy = await upgrades.deployProxy(NftAuction, ['0x0000000000000000000000000000000000000000'], {initializer: "initialize",kind: 'uups'});

    await nftAuctionProxy.waitForDeployment();

    const proxyAddress = await nftAuctionProxy.getAddress();
    const implementAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
    console.log("代理合约地址:", proxyAddress);
    console.log("目标合约地址:", implementAddress);

    const storePath = path.resolve(__dirname, "./.cache/proxyNftAction.json");

    fs.writeFileSync(storePath, JSON.stringify({
        proxyAddress,
        implementAddress,
        abi: NftAuction.interface.format("json")
    }));

    await save("NftAuctionProxy",{
        abi: NftAuction.interface.format("json"),
        address: proxyAddress,
    })
};
module.exports.tags = ['deployNFTAuction'];