// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*

 _____                _              _   _              ___  _                 
|_   _|              (_)            | | | |            / _ \| |                
  | | _ __  ___ _ __  _ _ __ ___  __| | | |__  _   _  / /_\ \ |_ ___ _ __ ___  
  | || '_ \/ __| '_ \| | '__/ _ \/ _` | | '_ \| | | | |  _  | __/ _ \ '_ ` _ \ 
 _| || | | \__ \ |_) | | | |  __/ (_| | | |_) | |_| | | | | | ||  __/ | | | | |
 \___/_| |_|___/ .__/|_|_|  \___|\__,_| |_.__/ \__, | \_| |_/\__\___|_| |_| |_|
               | |                              __/ |                          
               |_|                             |___/                           
                           
                                                                                                                                                                                                                                                                                                                                     
*/

/*
@author: chao
@notice Inspired by atem which use an unofficial ownable file,  lead to anyone can gain onwership.So I made this contract for fun.
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract DecentralizedOwnership is ERC721A, Ownable {

  string public baseURI = "http://www.TokenURIBASE.com";
  address private creatorAddress;
  uint256 public constant MAX_MINT_PER_ADDR = 10;
  uint256 public constant MAX_SUPPLY = 23;
  uint256 public constant PRICE = 0.01 * 10**18; // 0.01 ETH
  uint256 public constant TAKE_OWNERSHIP_FEE = 0.03 * 10**18; // 0.03 ETH
  uint256 public constant PERIOD = 300; // expired in 5 minutes
  uint256 public constant creatorShare = 50;

  uint256 public onwershipexpiredtime = 0;
  uint256 public creatorReserve = 12;

  event Minted(address minter, uint256 amount);
  event BaseURIChanged(string newBaseURI);

  constructor() ERC721A("Decentralized Ownership NFT", "DON") {
    creatorAddress = msg.sender;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 quantity) external payable {
    require(tx.origin == msg.sender, "EOA only");
    require(
      numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
      "can not mint this many"
    );
    require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");

    uint256 salePrice = totalSupply() < MAX_SUPPLY/2 ? 0 : PRICE; // it's fine...
    _safeMint(msg.sender, quantity);
    refundIfOver(salePrice * quantity);

    emit Minted(msg.sender, quantity);
  }

  function creatorMint(uint256 _amount) public {
    require(msg.sender == creatorAddress);
    require(_amount > 0 && _amount <= creatorReserve, "Not enough reserve");
    require(totalSupply() + _amount <= MAX_SUPPLY, "reached max supply");
    _safeMint(msg.sender, _amount);
    creatorReserve = creatorReserve - _amount;
    }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
    emit BaseURIChanged(newBaseURI);
  }

  function withdraw() external onlyOwner {
    require(tx.origin == msg.sender, "EOA only"); // precaution

    uint256 balance = address(this).balance;
    if (balance > 0){
      uint256 split = balance * creatorShare / 100;
      payable(creatorAddress).transfer(split);
      payable(msg.sender).transfer(balance - split);
    }
  }

  // utils
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  // ownerable override

  function takeOwnership() public payable {
    require(msg.sender != owner(), "you are already the owner");
    require(msg.value >= TAKE_OWNERSHIP_FEE, "must send few eth to take ownership");
    require(balanceOf(msg.sender) > 0, "having at least one nft");
    require(block.timestamp > onwershipexpiredtime, "must wait for previous onwership expired");
    onwershipexpiredtime = block.timestamp + msg.value / TAKE_OWNERSHIP_FEE * PERIOD; // expired after n * 10 minutes
    _transferOwnership(msg.sender);
  }

  function extendOwership() public payable onlyOwner {
    require(msg.value >= TAKE_OWNERSHIP_FEE);
    uint256 extendAt = max(onwershipexpiredtime, block.timestamp);
    onwershipexpiredtime = extendAt + msg.value / TAKE_OWNERSHIP_FEE * PERIOD;
  }

}