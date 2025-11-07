// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface INFTAuction{
    function initializeAuction(address user, uint256 _startPrice, uint256 _duration, address _nftAddress, uint256 _tokenId) external;
    function endAuction() external;
}