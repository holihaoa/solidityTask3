// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20 is IERC20 {
    mapping ( address => uint256 ) public balances;
    mapping (address => mapping (address => uint256)) public override allowance;
    uint256 private _totalSupply;
    string public name;
    string public symbol;

    constructor(string memory n,string memory sym){
        name = n;
        symbol = sym;
    }

    function transfer(address to, uint256 ammount) public override returns (bool){
        require(to != address(0),"to address is blank");
        balances[msg.sender] -= ammount;
        balances[to] += ammount;
        emit Transfer(msg.sender, to, ammount);
        return true;
    }
    function approve(address spender, uint256 amount) public override returns (bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public override returns (bool){
        require(allowance[from][msg.sender]>= amount,"allowance dont enough");
        allowance[from][msg.sender] -= amount;
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    function mint(address to, uint256 amount) public returns (bool){
        balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }
    function balanceOf(address account) public view override returns (uint256){
        return balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}