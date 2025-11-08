// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./AuctionFactory.sol";

contract AuctionFactoryV2 is AuctionFactory {
    function testHello() public pure returns (string memory) {
        return "Hello, Factory!";
    }
}