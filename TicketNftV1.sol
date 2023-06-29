//bunyNFt

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {  IERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import {  IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SharedNFTLogic } from "./SharedNFTLogic.sol";
import { IEditionSingleMintable } from "./IEditionSingleMintable.sol";

contract TicketNftV1 is ERC721Upgradeable, IEditionSingleMintable,  OwnableUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  SharedNFTLogic private immutable sharedNFTLogic;
  CountersUpgradeable.Counter private atEditionId;
  event Eventstarted(address minter, uint256 startTime);
  event TicketSold(uint256 price, address owner, uint256 EntryCount, uint256 entryTime);
  string public description;
  string public animationUrl;
  string public imageUrl;
  uint256 public editionSize;
  uint256 public salePrice;
  uint256 public minCustomers;
  uint256 public maxTokens;
  bool public active = false;
  bool public isComplete = false;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public EntryCount = 0;
  address payable public bunyBank;
  Entry[] private entry;
 	uint256[] public nftTokenIds;
  mapping(address => bool) public mintedTokens;
  mapping(address => bool) public allowedMinters;


  struct Entry {
    address customer;
    uint256 EntryNumber;
    uint256 entryTime;
  }


  constructor( SharedNFTLogic _sharedNFTLogic)  {
    sharedNFTLogic = _sharedNFTLogic;
      
       }

  function initialize(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _description,
    string memory _animationUrl,
    string memory _imageUrl,
    uint256 _editionSize,
    uint256 _salePrice,
    uint256 _minCustomers,
    address payable _bunyBank,
    uint256 _maxTokens


  ) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init();
    // Set ownership to original sender of contract call
    transferOwnership(_owner);
    description = _description;
    animationUrl = _animationUrl;
    imageUrl = _imageUrl;
    editionSize = _editionSize;
    salePrice = _salePrice;
    minCustomers = _minCustomers;
    bunyBank = _bunyBank;
    maxTokens = _maxTokens;
      atEditionId.increment();
  }

  /// @dev returns the number of minted tokens within the edition
   function totalSupply() public view returns (uint256) {
     return atEditionId.current() - 1;
    }

     
 // return balance in wei
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

  

  function purchase() external payable returns (uint256) {
    require(balanceOf(msg.sender) < maxTokens, "You have reached the maximum tokens allowed per address");
    require(active, "Event has not started. Owner must setApprovedMinter");
    require(msg.value == salePrice, "No soup for you!");
    address[] memory toMint = new address[](1);
    toMint[0] = msg.sender;
    mintedTokens[msg.sender] = true;
    EntryCount ++;
    nftTokenIds.push(EntryCount);
    uint256 entryTime = block.timestamp;
    Entry memory x = Entry(msg.sender, EntryCount, entryTime);
    entry.push(x);
      if (EntryCount == editionSize) {
            isComplete = true;
            active = false;
        }
    emit TicketSold(salePrice, msg.sender, EntryCount, entryTime);
    return _mintEditions(toMint);
  }


function purchaseMultiple(uint256 numTokens) external payable returns (uint256) {
    require(numTokens <= maxTokens, "You are trying to mint more tokens than allowed in one transaction");
    require(numTokens <= numberCanMint(), "The number of tokens you are trying to mint exceeds the number of tokens left");
    require(balanceOf(msg.sender) + numTokens <= maxTokens, "The total number of tokens you are trying to own exceeds the maximum tokens allowed per address");
    require(active, "Event has not started. Owner must setApprovedMinter");
    require(msg.value == numTokens * salePrice, "Insufficient ether sent for the number of tokens");
    address[] memory toMint = new address[](numTokens);
    for (uint256 i = 0; i < numTokens; i++) {
        toMint[i] = msg.sender;
    }
    mintedTokens[msg.sender] = true;
    EntryCount += numTokens;
    nftTokenIds.push(EntryCount);
    uint256 entryTime = block.timestamp;
    for (uint256 i = 0; i < numTokens; i++) {
        Entry memory x = Entry(msg.sender, EntryCount - i, entryTime);
        entry.push(x);
    }
    if (EntryCount >= editionSize) {
        isComplete = true;
        active = false;
    }
    emit TicketSold(salePrice, msg.sender, EntryCount, entryTime);
    return _mintEditions(toMint);
}


   

function getOwner(uint _id) public view returns (address) {
    return ownerOf(_id);
  }




  function _isAllowedToMint() internal view returns (bool) {
    if (owner() == msg.sender) {
      return true;
    }
    if (allowedMinters[address(0x0)]) {
      return true;
    }
    return allowedMinters[msg.sender];
  }

  function mintEdition(address to) external override returns (uint256) {
    require(_isAllowedToMint(), "Needs to be an allowed minter");
    address[] memory toMint = new address[](1);
    toMint[0] = to;
    return _mintEditions(toMint);
  }

  function mintEditions(address[] memory recipients) external override returns (uint256) {
    require(_isAllowedToMint(), "Needs to be an allowed minter");
    return _mintEditions(recipients);
  }

  function owner() public view override(OwnableUpgradeable, IEditionSingleMintable) returns (address) {
    return super.owner();
  }

  // helper function starts event once setApprovedMinter. 
  function enableEvent() public onlyOwner {
      active = true;
    }

    
     function readAllEntries() public view  returns (Entry[] memory) {
    Entry[] memory result = new Entry[](EntryCount);
    for (uint256 i = 0; i < EntryCount; i++) {
      result[i] = entry[i];
    }
    return result;
  }
  
  // set contract address as Approved minter
  // set active state to false
  // log and emit current time
  function setApprovedMinter(address minter, bool allowed) public onlyOwner {
    allowedMinters[minter] = allowed;
    enableEvent();
    startTime = block.timestamp;
    emit Eventstarted(minter, startTime);
  }

  


  /// Returns the number of editions allowed to mint (max_uint256 when open edition)
  function numberCanMint() public view override returns (uint256) {
    // Return max int if open edition
    if (editionSize == 0) {
      return type(uint256).max;
    }
    // atEditionId is one-indexed hence the need to remove one here
    return editionSize + 1 - atEditionId.current();
  }

  /**
      @dev Private function to mint als without any access checks.
           Called by the public edition minting functions.
     */
  function _mintEditions(address[] memory recipients) internal returns (uint256) {
    uint256 startAt = atEditionId.current();
    uint256 endAt = startAt + recipients.length - 1;
    require(editionSize == 0 || endAt <= editionSize, "Sold out");
    while (atEditionId.current() <= endAt) {
      _mint(recipients[atEditionId.current() - startAt], atEditionId.current());
      atEditionId.increment();
    }
    return atEditionId.current();
  }

 
   
    function withdrawToBunyBank() internal {
        uint256 amount = address(this).balance;
        require(isComplete, "Event sale must be complete before withdraw function is enabled");
        require(amount > 0, "Contract has no balance to withdraw");

        bunyBank.transfer(amount);
    }


  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "No token");

    return sharedNFTLogic.createMetadataEdition(name(), description, imageUrl, animationUrl, tokenId, editionSize);
  }


     function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override( ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }



}
