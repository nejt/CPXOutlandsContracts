pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./Distributes.sol";
import "./ReentrancyGuard.sol";
import "./ERC721DeedNoBurn.sol";
import "./ERC721Metadata.sol";

/* Cosmic Collection Tokens
  Represents all collectables within CPX
  Planes, Planets, Bases, Proxies
  
  Notes on this example implementation:
  Every Deed has a type (uint16) tied to it - represents its type 
  Thre is a bank that the contract pays all the fees
  
  Creation is handled via "Maker Contracts" based upon type
  The type mapping provides links to the contracts that hold the basic statistics for the types
  
  Every deed can have a price set and it can be for sale or not 
  A pecent of the sale price (commission) goes to the bank  
  The previous owner gets the sale price minus the commission 
  
  All payements are pull payments
 */

contract CosmicCollectionTokens is ERC721DeedNoBurn, Pausable, PullToBank, ReentrancyGuard {

  using SafeMath for uint256;

  /* Events */

  // When a deed is created.
  event LogCreation(uint256 indexed id, uint16 indexed cosmicType, address owner);

  // When a deed is bought, the ownership of the deed is transferred to the new owner. 
  event LogPurchase(uint256 indexed id, address indexed oldOwner, address indexed newOwner, uint256 price);


  /* The actual deeds */

  // The data structure of the CosmicItem deed
  struct CosmicItem {
    uint16 cosmicType;
    uint256 price;
    uint256 created;
    bool forSale;
  }

  // Mapping from _deedId to Base
  mapping (uint256 => CosmicItem) private deeds;
  //mapping to track all deeds of a specific type
  mapping (uint16 => uint256[]) private deedsOfType;

  // Needed to make all deeds discoverable. The length of this array also serves as our deed ID.
  uint256[] private deedIds;


  /* Variables in control of owner */
  //cost - the initial cost for the new tokens
  uint256[] public Cost;
  
  //profit share on sale of Item
  uint8 commissionPercent = 1;

  // The contract owner can change the base URL, in case it becomes necessary. It is needed for Metadata.
  string public url = "https://www.cpx-outlands.com/";


  /* ERC-165 Metadata */
  
  bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = // 0x01ffc9a7
      bytes4(keccak256('supportsInterface(bytes4)'));

  bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = // 0xda671b9b
      bytes4(keccak256('ownerOf(uint256)')) ^
      bytes4(keccak256('countOfDeeds()')) ^
      bytes4(keccak256('countOfDeedsByOwner(address)')) ^
      bytes4(keccak256('deedOfOwnerByIndex(address,uint256)')) ^
      bytes4(keccak256('approve(address,uint256)')) ^
      bytes4(keccak256('takeOwnership(uint256)'));

  bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata = // 0x2a786f11
      bytes4(keccak256('name()')) ^
      bytes4(keccak256('symbol()')) ^
      bytes4(keccak256('deedUri(uint256)'));


    /* Contract Creation */

  function CosmicCollectionTokens() public {
      //fallback - bank is owner - othwerwise all profits go to 0
      bank = msg.sender;
      //initial cost for planes and heroes
      uint256 baseCost = 2 * 1 finney;
      Cost.push(baseCost);
      Cost.push(baseCost);
  }

  // The contract owner can withdraw funds that were received this way.
  function() public payable {}


   /* ERC721Metadata */

  function name()
  external pure returns (string) {
    return "CosmicCollectionTokens";
  }

  function symbol()
  external pure returns (string) {
    return "CPXT";
  }

  function supportsInterface(bytes4 _interfaceID)
  external pure returns (bool) {
    return (
      _interfaceID == INTERFACE_SIGNATURE_ERC165
      || _interfaceID == INTERFACE_SIGNATURE_ERC721
      || _interfaceID == INTERFACE_SIGNATURE_ERC721Metadata
    );
  }


    /* Data Views */

  /* Enable listing of all deeds (alternative to ERC721Enumerable to avoid having to work with arrays). */
  function ids()
  external view returns (uint256[]) {
    return deedIds;
  }
  
  function nextDeedID()
  external view returns (uint256) {
    return deedIds.length;
  }
  
  //returns if for sale and price
  function deedSaleData(uint256 _deedId) 
  external view returns (uint256, bool) {
      return (deeds[_deedId].price, deeds[_deedId].forSale);
  }
  
  function typeOf(uint256 _deedId)
  external view returns(uint16) {
      return(deeds[_deedId].cosmicType);
  }
  
  //get a list of all deeds of a type
  function allDeedsOfType (uint16 _type)
  external view returns(uint256[] allDeeds) {
      allDeeds = deedsOfType[_type];
  }
  
  //get a count of all deeds of a type
  function countOfDeedsOfType (uint16 _type)
  public view returns(uint256 count) {
      count = deedsOfType[_type].length;
  }
  
  //get a cost based upon number
  //doubles every 10
  function currentCost (uint16 _type)
  public view returns (uint256 cost) {
      require(Cost[_type] > 0);
      uint256 multi = 1 + countOfDeedsOfType(_type) / 10;
      cost = Cost[_type] * multi;
  }
  
  
  //hash standard - use the token contract, type id, time created, and id
  function getHash (uint256 _deedId)
  external view returns(bytes32 hash) {
      uint16 _type = deeds[_deedId].cosmicType;
      hash = keccak256(address(this), _type, deeds[_deedId].created, _deedId);
  }

  function deed(uint256 _deedId)
  external view 
  returns (uint16 _itype, uint256 _price, uint256 _created, bool _forSale) {
    _itype = deeds[_deedId].cosmicType;
    _price = deeds[_deedId].price;
    _created = deeds[_deedId].created;
    _forSale = deeds[_deedId].forSale;
  }
  

  /* Creation Functions */

  // Create a token based upon a type - type must cost something
  function create(uint16 _type)
  public whenNotPaused nonReentrant payable {
    //type must cost something or this will throw
    uint256 _cost = currentCost(_type);
    require(msg.value >= _cost);
    // The bank gets their share.
    asyncSend(bank, _cost);
    //create
    uint256 deedId = deedIds.length;
    //push to array
    deedIds.push(deedId);
    //create new token
    super._mint(msg.sender, deedId);
    //create deed
    deeds[deedId] = CosmicItem({
      cosmicType: _type,
      price: 0,
      created: now,
      forSale: false
    });
    //track the type of the deed
    deedsOfType[_type].push(deedId);
    //log
    emit LogCreation(deedId, _type, msg.sender);
  }
  
  
  /* Core features of the example: Purchase and Payment */

  // Forces the transfer of the deed to a new owner. This functionality can be paused by the owner.
  function purchase(uint256 _deedId)
  external whenNotPaused nonReentrant payable {
    //require for sale
    require(deeds[_deedId].forSale);
    // Require the right payment.
    uint256 oldPrice = deeds[_deedId].price;
    uint256 newPrice = msg.value;
    require(newPrice >= oldPrice);

    // The current owner is forbidden to appropriate himself.
    address oldOwner = this.ownerOf(_deedId);
    address newOwner = msg.sender;
    require(oldOwner != newOwner);

    // The contract gets a commission of every sale
    // commission is a percent
    uint256 profitShare = newPrice.mul(commissionPercent).div(100);

    // The bank gets their share.
    asyncSend(bank, profitShare);

    // Reimburse previous owner their price minus the profit share
    asyncSend(oldOwner, newPrice.sub(profitShare));

    // Clear any outstanding approvals and transfer the deed.
    clearApprovalAndTransfer(oldOwner, newOwner, _deedId);

    LogPurchase(_deedId, oldOwner, newOwner, newPrice);
  }
  
  /* Token owner functions */
  
  //owner gets to set sale data
  function setSaleData(uint256 _deedId, uint256 _price, bool _forSale) 
  external onlyOwnerOf(_deedId) {
      deeds[_deedId].price = _price;
      deeds[_deedId].forSale = _forSale;
  }

  /* Contract Owner Functions */

  function setCommission(uint8 _commission)
  public onlyOwner {
    commissionPercent = _commission;
  }
  
  function setUrl(string _url)
  public onlyOwner {
    url = _url;
  }
  
  function setCost(uint256 c) 
  external onlyOwner {
    Cost.push(c);
  }
  
  function setCost(uint256 i, uint256 c) 
  external onlyOwner {
    require(Cost[i] != 0);
    Cost[i] = c;
  }
}
