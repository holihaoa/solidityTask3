// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MyNFT} from "./MyNFT.sol";

contract nftAuction{
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

    mapping(uint256 => Auction) public auctions;
    address public admin;
    uint256 public nextAuctionId;

    constructor() {
        admin = msg.sender;
    }

    function createAuction(uint256 _startPrice, uint256 _duration, address _nftAddress, uint256 _tokenId) public {
        require(_startPrice > 0, "The starting auction price should be higher than 0");
        require(_duration >= 10, "The auction duration is longer than 10 seconds");
        address owner = MyNFT(_nftAddress).ownerOf(_tokenId);
        require(owner == msg.sender, "only owner can create auction");
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

    function auctionBid(uint256 _auctionId,uint256 price, address _tokenAddress) external payable {
        Auction storage auction = auctions[_auctionId];
        if(_tokenAddress == address(0)){
            price = msg.value;
        }
        require(!auction.ended && auction.startTime < block.timestamp && block.timestamp < (auction.startTime + auction.duration), "The auction has ended or has not yet begun");
        require(price >= auction.startPrice ,"The bid cannot be less than the starting price");
        require(price > auction.highestBid,"The bid is lower than the highest price of this auction");
        if(_tokenAddress != address(0)){
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), price);
        }
        if(auction.highestBid > 0){
            if(auction.tokenAddress == address(0)){
                payable(auction.highestBidder).transfer(auction.highestBid);
            } else {
                IERC20(auction.tokenAddress).transfer(auction.highestBidder, auction.highestBid);
            }
        }
        auction.highestBidder = msg.sender;
        auction.highestBid = price;
        auction.tokenAddress = _tokenAddress;
    }

    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(!auction.ended,"The auction has ended");
        require(auction.startTime + auction.duration <= block.timestamp,"The auction is not yet at its conclusion time");
        MyNFT(auction.nftAddress).safeTransferFrom(auction.seller, auction.highestBidder, auction.tokenId);
        if(auction.tokenAddress == address(0)){
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            IERC20(auction.tokenAddress).transfer(auction.seller, auction.highestBid);
        }
        auction.ended = true;
    }
}