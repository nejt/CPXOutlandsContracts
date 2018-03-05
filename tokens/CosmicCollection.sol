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
  event LogCreation(uint256 indexed id, address owner);

  // When a deed is bought, the ownership of the deed is transferred to the new owner. 
  event LogPurchase(uint256 indexed id, address indexed oldOwner, address indexed newOwner, uint256 price);


  /* The actual deeds */

  // The data structure of the CosmicItem deed
  struct CosmicItem {
    uint16 itype;
    uint256 price;
    uint256 created;
    bool forSale;
  }

  // Mapping from _deedId to Base
  mapping (uint256 => CosmicItem) private deeds;

  // Needed to make all deeds discoverable. The length of this array also serves as our deed ID.
  uint256[] private deedIds;

  
  /* Control of Types */
  
  struct CosmicType {
      address maker;
      address sats;
      string name;
  }
  mapping (uint16 => CosmicType) public typeData;

  /* Variables in control of owner */
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
  
  /* modifier */
  //only the maker contract of the type can create the token
  modifier onlyMaker(uint16 _type){
      require(typeData[_type].maker == msg.sender);
      _;
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
      return(deeds[_deedId].itype);
  }

  function deed(uint256 _deedId)
  external view 
  returns (uint16 _itype, uint256 _price, uint256 _created, bool _forSale) {
    _itype = deeds[_deedId].itype;
    _price = deeds[_deedId].price;
    _created = deeds[_deedId].created;
    _forSale = deeds[_deedId].forSale;
  }
  

  /* Creation Functions */

  // Only the admin can create bases
  // All Admins are "Maker Contracts" based upon types
  function create(uint16 _type, address _owner)
  public onlyMaker(_type) {
    //create
    uint256 deedId = deedIds.length;
    //push to array
    deedIds.push(deedId);
    //create new token
    super._mint(_owner, deedId);
    //create deed
    deeds[deedId] = CosmicItem({
      itype: _type,
      price: 0,
      created: now,
      forSale: false
    });
    //log
    LogCreation(deedId, _owner);
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

    // The owner gets their share.
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
  
  function setTypeData(uint16 _i, address _maker, address _stats, string _name) 
  external onlyOwner {
    typeData[_i] = CosmicType(_maker,_stats,_name); 
  }
}
