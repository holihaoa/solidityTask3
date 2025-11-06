// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@chainlink/contracts/src/v0.8/vendor/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract MyNFT is IERC721, IERC721Metadata {
    using strings for uint256;
    string public override name;
    string public override symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    error ERC721InvalidReceiver(address receiv);
    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool){
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner) external returns (uint256 balance){
        require(owner != address(0), "入参地址不应为0");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address owner){
        address owner = _owners[tokenId];
        require(owner != address(0),"owner是失效地址");
        return owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        address owner = this.ownerOf(tokenId);
        require(from == owner, "该地址非owner!");
        require(to != address(0),"接受地址为空!");
        require(msg.sender == owner || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[owner][msg.sender], "无权限操作!");
        _checkOnERC721Received(from,to,tokenId,data);
        _transferFrom(from,to,tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes calldata data) internal {
        if(to.code.length > 0){
            try IERC721Receiver(to).onERC721Received(msg.sender,from,tokenId,data) returns (bytes4 retval){
                if(retval != IERC721Receiver.onERC721Received.selector){
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if(reason.length == 0 ){
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        address owner = this.ownerOf(tokenId);
        require(from == owner, "该地址非owner!");
        require(to != address(0),"接受地址为空!");
        require(msg.sender == owner || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[owner][msg.sender], "无权限操作!");
        _checkOnERC721Received(from,to,tokenId,"");
        _transferFrom(from,to,tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = address(0);
        emit Approval(from, address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from,to,tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        address owner = this.ownerOf(tokenId);
        require(from == owner, "该地址非owner!");
        require(to != address(0),"接受地址为空!");
        require(msg.sender == owner || _tokenApprovals[tokenId] == msg.sender || _operatorApprovals[owner][msg.sender], "无权限操作!");
        _transferFrom(from,to,tokenId);
    }

    function approve(address to, uint256 tokenId) external {
        address owner = _owners[tokenId];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender],"无权限进行授权操作!");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender,"无需给自己授权");
        _operatorApprovals[msg.sender][operator] = true;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) external view returns (address operator) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory){
        require(_owners[tokenId] != address(0), "该nft不存在");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0? string(abi.encodePacked(baseURI,tokenId.toString())) : "" ;
    }

    function _baseURI() internal view virtual returns (string memory){
        return "";
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "不能给空地址铸造");
        require(_owners[tokenId] == address(0), "该tokenId已铸造");
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _owners[tokenId];
        require(owner == msg.sender,"无权限销毁币");
        _tokenApprovals[tokenId] = address(0);
        emit Approval(owner, address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
}