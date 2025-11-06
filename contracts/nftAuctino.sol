// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MyNFT} from "./MyNFT.sol";

contract nftAuction is MyNFT{
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
    }

    mapping(uint256 => Auction) public auctions;
    address public admin;
    uint256 public nextAuctionId;

    constructor(){
        admin = msg.sender;
    }

    function createAuction(uint256 _startPrice, uint256 _duration, address _nftAddress, uint256 _tokenId) public {
        require(msg.sender == admin, "");
        require(_startPrice > 0, "");
        require(_duration >= 10, "");
        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            startTime: block.timestamp,
            startPrice: _startPrice,
            duration: _duration,
            highestBid: 0,
            highestBidder: address(0),
            ended: false,
            nftAddress: _nftAddress,
            tokenId: _tokenId
        });
        nextAuctionId++;
    }

    function auctionBid(uint256 _auctionId,uint256 price) external payable {
        Auction auction = auctions[_auctionId];
        require(!auction.ended && auction.startTime < block.timestamp < auction.startTime + auction.duration,"拍卖已结束或还未开始");
        require(price >= auction.startPrice ,"出价不能小于起始价");
        require(price < auction.highestBid,"出价小于该拍卖最高价");
        if(auction.highestBid > 0){
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        auction.highestBidder = msg.sender;
        auction.highestBid = price;
    }

    function endAuction(uint256 _auctionId) external {
        Auction auction = auctions[_auctionId];
        require(!auction.ended,"拍卖已结束");
        require(auction.startTime + auction.duration <= block.timestamp,"拍卖还未到结束时间");
        MyNFT(auction.nftAddress).safeTransferFrom(address(this), msg.sender, auction.tokenId);
        auction.ended = true;
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == admin,"无权限铸币");
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory){
        return "ipfs://bafybeie6axsbf35fgbfhvscfzokyad3k3wdp3eu2qcxmpdccb6dj5ytclm/";
    }
}