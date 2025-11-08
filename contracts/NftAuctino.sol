// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INFTAuction} from "../interfaces/INFTAuction.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {MyNFT} from "./MyNFT.sol";

contract NftAuction is Initializable, INFTAuction, UUPSUpgradeable {
    struct Auction {
        address seller;
        uint256 startTime;
        uint256 startPrice;
        uint256 duration;
        uint256 highestBid;
        address highestBidder;
        bool ended;
        address nftAddress;
        uint256 tokenId;
        address tokenAddress;
    }

    Auction public currentAuction;
    mapping(uint256 => Auction) public auctions;
    address public admin;
    address public factory;
    uint256 public nextAuctionId;
    mapping(address => AggregatorV3Interface) public priceFeed;

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can initialize");
        _;
    }

//    constructor(address _factory) {
//        factory = _factory;
//    }

    function initialize(address _factory) public initializer {
        admin = msg.sender;
        factory = _factory;
    }

    //ETH/USD:0x694AA1769357215DE4FAC081bf1f309aDC325306
    //USDC/USD:0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E
    function setPriceFeed(address tokenAddress, address _priceFeed) public {
        priceFeed[tokenAddress] = AggregatorV3Interface(_priceFeed);
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer(address toeknAddress) public view returns (int256) {
        AggregatorV3Interface dataFeed = priceFeed[toeknAddress];
        // prettier-ignore
        (
        /* uint80 roundId */
            ,
            int256 answer,
        /*uint256 startedAt*/
            ,
        /*uint256 updatedAt*/
            ,
        /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function initializeAuction(address user, uint256 _startPrice, uint256 _duration, address _nftAddress, uint256 _tokenId) external override onlyFactory {
        currentAuction = Auction({
            seller: user,
            startTime: block.timestamp,
            startPrice: _startPrice,
            duration: _duration,
            highestBid: 0,
            highestBidder: address(0),
            ended: false,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            tokenAddress: address(0)
        });
    }

    function createAuction(uint256 _startPrice, uint256 _duration, address _nftAddress, uint256 _tokenId) public {
        require(_startPrice > 0, "The starting auction price should be higher than 0");
        require(_duration >= 10, "The auction duration is longer than 10 seconds");
//        address owner = MyNFT(_nftAddress).ownerOf(_tokenId);
//        require(owner == msg.sender, "only owner can create auction");
        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            startTime: block.timestamp,
            startPrice: _startPrice,
            duration: _duration,
            highestBid: 0,
            highestBidder: address(0),
            ended: false,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            tokenAddress: address(0)
        });
        nextAuctionId++;
    }

    function auctionBid(uint256 _auctionId, uint256 price, address _tokenAddress) external payable {
        Auction storage auction = auctions[_auctionId];
        uint256 payValue ;
        if (_tokenAddress == address(0)) {
            price = msg.value;
            payValue = price * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        } else {
            payValue = price * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        }
        uint256 startPriceValue = auction.startPrice * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        uint256 highestBidValue = auction.highestBid * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        require(!auction.ended && auction.startTime < block.timestamp && block.timestamp < (auction.startTime + auction.duration), "The auction has ended or has not yet begun");
        require(payValue >= startPriceValue, "The bid cannot be less than the starting price");
        require(payValue > highestBidValue, "The bid is lower than the highest price of this auction");
        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), price);
        }
        if (auction.highestBid > 0) {
            if (auction.tokenAddress == address(0)) {
                payable(auction.highestBidder).transfer(auction.highestBid);
            } else {
                IERC20(auction.tokenAddress).transfer(auction.highestBidder, auction.highestBid);
            }
        }
        auction.highestBidder = msg.sender;
        auction.highestBid = price;
        auction.tokenAddress = _tokenAddress;
    }

    function priceBid(uint256 price, address _tokenAddress) external payable {
        uint256 payValue ;
        if (_tokenAddress == address(0)) {
            price = msg.value;
            payValue = price * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        } else {
            payValue = price * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        }
        uint256 startPriceValue = currentAuction.startPrice * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        uint256 highestBidValue = currentAuction.highestBid * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        require(!currentAuction.ended && currentAuction.startTime < block.timestamp && block.timestamp < (currentAuction.startTime + currentAuction.duration), "The auction has ended or has not yet begun");
        require(payValue >= startPriceValue, "The bid cannot be less than the starting price");
        require(payValue > highestBidValue, "The bid is lower than the highest price of this auction");
        if (_tokenAddress != address(0)) {
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), price);
        }
        if (currentAuction.highestBid > 0) {
            if (currentAuction.tokenAddress == address(0)) {
                payable(currentAuction.highestBidder).transfer(currentAuction.highestBid);
            } else {
                IERC20(currentAuction.tokenAddress).transfer(currentAuction.highestBidder, currentAuction.highestBid);
            }
        }
        currentAuction.highestBidder = msg.sender;
        currentAuction.highestBid = price;
        currentAuction.tokenAddress = _tokenAddress;
    }

    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(!auction.ended, "The auction has ended");
        require(auction.startTime + auction.duration <= block.timestamp, "The auction is not yet at its conclusion time");
        if (auction.highestBid > 0) {
            MyNFT(auction.nftAddress).safeTransferFrom(auction.seller, auction.highestBidder, auction.tokenId);
            if (auction.tokenAddress == address(0)) {
                payable(auction.seller).transfer(auction.highestBid);
            } else {
                IERC20(auction.tokenAddress).transfer(auction.seller, auction.highestBid);
            }}
        auction.ended = true;
    }

    function endAuction() external override {
        require(!currentAuction.ended, "The auction has ended");
        require(currentAuction.startTime + currentAuction.duration <= block.timestamp, "The auction is not yet at its conclusion time");
        if (currentAuction.highestBid > 0) {
            MyNFT(currentAuction.nftAddress).safeTransferFrom(currentAuction.seller, currentAuction.highestBidder, currentAuction.tokenId);
            if (currentAuction.tokenAddress == address(0)) {
                payable(currentAuction.seller).transfer(currentAuction.highestBid);
            } else {
                IERC20(currentAuction.tokenAddress).transfer(currentAuction.seller, currentAuction.highestBid);
            }
        }
        currentAuction.ended = true;
    }

    function _authorizeUpgrade(address) internal view override {
        // 只有管理员可以升级合约
        require(msg.sender == admin, "Only admin can upgrade");
    }
}