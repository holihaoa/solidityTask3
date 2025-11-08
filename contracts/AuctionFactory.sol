// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./NftAuctino.sol";

contract AuctionFactory is UUPSUpgradeable,Initializable {
    address[] public auctions;
    mapping(address => address[]) public usersAuction;
    mapping(address => mapping(uint256 => NftAuction)) public nftToAuction;
    address public admin;

    event CreateNFTAuction(address indexed auctionAddress, address indexed nftAddress, address indexed seller, uint256 tokenId);
    event EndNFTAuction(address indexed auctionAddress, address indexed winner, uint256 highestPrice);

    function initialize() public initializer {
        admin = msg.sender;
    }

    function createNFTAuction(uint256 _startPrice, uint256 _duration, address _nftAddress, uint256 _tokenId) public {
        require(_startPrice > 0, "The starting auction price should be higher than 0");
        require(_duration >= 10, "The auction duration is longer than 10 seconds");
        address owner = MyNFT(_nftAddress).ownerOf(_tokenId);
        require(owner == msg.sender, "only owner can create auction");
        NftAuction auctionContract = new NftAuction();
        auctionContract.initialize(address(this));
        auctionContract.initializeAuction(owner, _startPrice, _duration, _nftAddress, _tokenId);
        auctions.push(address(auctionContract));
        usersAuction[msg.sender].push(address(auctionContract));
        nftToAuction[_nftAddress][_tokenId] = auctionContract;
        emit CreateNFTAuction(address(auctionContract), _nftAddress,msg.sender,_tokenId);
    }

    function getAuctionsByUser(address user) public view returns(address[] memory){
        return usersAuction[user];
    }

    function getNFTAuction(address nftAddress,uint256 tokenId) public view returns(NftAuction){
        return nftToAuction[nftAddress][tokenId];
    }

    function getAuctions() public view returns(address[] memory){
        return auctions;
    }

    function endAuction(address auctionAddress) public {
        INFTAuction(auctionAddress).endAuction();
    }

    function _authorizeUpgrade(address) internal view override {
        // 只有管理员可以升级合约
        require(msg.sender == admin, "Only admin can upgrade");
    }
}