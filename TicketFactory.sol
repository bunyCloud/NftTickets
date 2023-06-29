// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./TicketNftV1.sol";


contract TicketFactory is OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private atContract;
    address public implementation;
    string  _name = "Daily Telos Ticket";
    string  _symbol = "DAIL";
    string  _animationUrl = "https://ipfs.io/ipfs/Qmd94YsrsK5jPbi675XiwyLwMhcM6HS6MULC7mqQGMnXtW";
    address payable public _organizerBank;
    uint256 public collectionCount = 0;
    event CreatedEdition(uint256 indexed editionId, address indexed creator, uint256 editionSize, address indexed editionContractAddress, uint256 minPlayers, uint256 maxTokens, uint256 salePrice);
    Collection[] public collection;



  struct Collection {
    string _name;
    address editionContractAddress;
    uint256 _editionSize;
    uint256 newId;
    uint256 _minPlayers;
    uint256 _maxTokens;
    uint256 _salePrice;
    string _animationUrl;
    string _imageUrl;
  }



    /// Initializes factory with address of implementation logic
    constructor(address _implementation, address payable organizerBank) {
        implementation = _implementation;
        _organizerBank = organizerBank;
    }

  function owner() public view override(OwnableUpgradeable) returns (address) {
    return super.owner();
  }

   
    function createEdition(
        string memory _description,
        //string memory _animationUrl,
        string memory _imageUrl,
        uint256 _editionSize,
        uint256 _salePrice,
        uint256 _minPlayers,
        uint256 _maxTokens
        ) external returns (uint256) {
        uint256 newId = atContract.current();
        address newContract = ClonesUpgradeable.cloneDeterministic(
            implementation,
            bytes32(abi.encodePacked(newId))
        );
        TicketNftV1(newContract).initialize(
            msg.sender,
            _name,
            _symbol,
            _description,
            _animationUrl,
            _imageUrl,
            _editionSize,
            _salePrice,
            _minPlayers,
            _organizerBank,
            _maxTokens
         
        );
        emit CreatedEdition(newId, msg.sender,  _editionSize, newContract, _minPlayers,  _maxTokens, _salePrice );
         atContract.increment();
         Collection memory x = Collection(_name, newContract, _editionSize, newId,  _minPlayers, _maxTokens, _salePrice, _animationUrl, _imageUrl);
    collection.push(x);
    collectionCount ++;
        return newId;
    }
   function setBunyBankAddress(address payable organizerBank) external onlyOwner {
        require(organizerBank != address(0), "Invalid address");
        _organizerBank = organizerBank;
    }
    

  function readAllCollections() public view  returns (Collection[] memory) {
    Collection[] memory result = new Collection[](collectionCount);
    for (uint256 i = 0; i < collectionCount; i++) {
      result[i] = collection[i];
    }
    return result;
  }

    function getEventAtId(uint256 raffleId)
        external
        view
        returns (TicketNftV1)
    {
        return
            TicketNftV1(
                ClonesUpgradeable.predictDeterministicAddress(
                    implementation,
                    bytes32(abi.encodePacked(raffleId)),
                    address(this)
                )
            );
    }


  
}
