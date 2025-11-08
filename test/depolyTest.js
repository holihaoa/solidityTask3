const {ethers, deployments, upgrades} = require("hardhat");
const {expect} = require("chai");

describe("Test upgrade", async function () {
    it("Should be able to deploy auction and proxy", async function () {
        await deployments.fixture("deployNFTAuction");
        const nftAuctionProxy = await deployments.get("NftAuctionProxy");
        console.log("获取信息成功:", nftAuctionProxy);
        const nftAuction = await ethers.getContractAt("NftAuction", nftAuctionProxy.address);
        console.log("获取合约成功!");
        await nftAuction.createAuction(10, 100, '0x0000000000000000000000000000000000000001', 1);
        const auction1 = await nftAuction.auctions(0);
        console.log("创建拍卖成功", auction1);
        const implAddress1 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);
        console.log("升级前拍卖合约地址", implAddress1);
        await deployments.fixture("upgradeNFTAuction");
        const auction2 = await nftAuction.auctions(0);
        const implAddress2 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);
        console.log("升级拍卖成功", auction2);
        console.log("升级后拍卖合约地址", implAddress2);
        const nftAuction2 = await ethers.getContractAt("NftAuctionV2", nftAuctionProxy.address);
        const testHello = await nftAuction2.testHello();
        console.log(testHello);

        expect(auction2.startTime).to.eq(auction1.startTime);
        expect(implAddress1).to.not.eq(implAddress2);
    })

    it("Should be able to deploy factory and proxy", async function () {
        //部署nft合约
        let [account1,account2] = await ethers.getSigners();
        const MyNFT = await ethers.getContractFactory("MyNFT");
        let MyNFTContract = await MyNFT.connect(account1).deploy("MyNFT","MyNFT");
        await MyNFTContract.waitForDeployment();
        const MyNFTAddress = await MyNFTContract.getAddress();
        console.log(MyNFTAddress,"==contractAddress==")
        await MyNFTContract.mint(account1,1);

        //部署工厂合约
        await deployments.fixture("deployAuctionFactory");
        const auctionFactoryProxy = await deployments.get("auctionFactoryProxy");
        console.log("获取信息成功:", auctionFactoryProxy);
        const auctionFactoryContract = await ethers.getContractAt("AuctionFactory", auctionFactoryProxy.address);
        //利用工厂合约创建拍卖合约
        await auctionFactoryContract.createNFTAuction(10, 100, MyNFTAddress, 1);
        //获得工厂合约创建的拍卖合约
        const auctionAddress = await auctionFactoryContract.getAuctionsByUser(account1);
        console.log("工厂部署合约地址:",auctionAddress);
        const nftAuctionContract = await ethers.getContractAt("NftAuction", auctionAddress[0]);
        const auction = await nftAuctionContract.currentAuction();
        console.log("拍卖信息:",auction);
        expect(auction.nftAddress).to.equal(MyNFTAddress);

        //部署升级合约
        const implAddress1 = await upgrades.erc1967.getImplementationAddress(auctionFactoryProxy.address);
        console.log("升级前工厂逻辑合约地址:", implAddress1);
        await deployments.fixture("upgradeAuctionFactory");
        const implAddress2 = await upgrades.erc1967.getImplementationAddress(auctionFactoryProxy.address);
        console.log("升级后工厂逻辑合约地址:", implAddress2);
        const auctionFactoryContract2 = await ethers.getContractAt("AuctionFactoryV2", auctionFactoryProxy.address);
        const testHello = await auctionFactoryContract2.testHello();
        console.log(testHello);
        const auctionAddress2 = await auctionFactoryContract2.getAuctionsByUser(account1);
        expect(auctionAddress[0]).to.eq(auctionAddress2[0]);

        //测试出价功能
        const auctionContract = await ethers.getContractAt("NftAuction",auctionAddress2[0]);

        const TestERC20 = await ethers.getContractFactory("MyERC20");
        const testERC20 = await TestERC20.deploy("MyERC20","MyERC20");
        await testERC20.waitForDeployment();
        const UsdcAddress = await testERC20.getAddress();
        await testERC20.connect(account1).mint(account1.address,ethers.parseEther("10000"));
        let tx = await testERC20.connect(account1).transfer(account2, ethers.parseEther("1000"))
        await tx.wait()

        const aggreagatorV3 = await ethers.getContractFactory("AggregatorV3")
        const priceFeedEthDeploy = await aggreagatorV3.deploy(ethers.parseEther("10000"))
        const priceFeedEth = await priceFeedEthDeploy.waitForDeployment()
        const priceFeedEthAddress = await priceFeedEth.getAddress()
        console.log("ethFeed: ", priceFeedEthAddress)
        const priceFeedUSDCDeploy = await aggreagatorV3.deploy(ethers.parseEther("1"))
        const priceFeedUSDC = await priceFeedUSDCDeploy.waitForDeployment()
        const priceFeedUSDCAddress = await priceFeedUSDC.getAddress()
        console.log("usdcFeed: ", await priceFeedUSDCAddress)

        const token2Usd = [{
            token: ethers.ZeroAddress,
            priceFeed: priceFeedEthAddress
        }, {
            token: UsdcAddress,
            priceFeed: priceFeedUSDCAddress
        }]

        for (let i = 0; i < token2Usd.length; i++) {
            const { token, priceFeed } = token2Usd[i];
            await auctionContract.setPriceFeed(token, priceFeed);
        }
        const latestBlock = await ethers.provider.getBlock("latest");
        console.log("当前区块时间戳:", latestBlock.timestamp);
        await auctionContract.connect(account2).priceBid(0,ethers.ZeroAddress,{value: ethers.parseEther("1.5")})
        const currentAuction = await auctionContract.currentAuction();
        console.log("拍卖信息:",currentAuction);
        expect(currentAuction.highestBidder).to.equal(account2.address);
        await ethers.provider.send("evm_increaseTime",[100+1]);
        await MyNFTContract.approve(auctionAddress2[0],1);
        await auctionContract.endAuction();
        const newOwner = await MyNFTContract.ownerOf(1);
        //验证拍卖后nft成功转移owner
        expect(newOwner).to.eq(account2);
    })
})