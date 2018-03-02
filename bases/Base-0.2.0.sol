pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./Distributes.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Deed.sol";
import "./ERC721Metadata.sol";
import "./Administered.sol";

/*
  Notes on this example implementation:
  Thre is a bank that the contract pays all the fees
  The concept of "appropriation" is introduced: Deeds are permanently up for sale.
  Whoever is willing to pay more than the last price that was paid for a given deed, can take ownership of that deed.
  The previous owner is reimbursed with the amount he paid earlier, and additionally receives half of the amount that the price was increased by. The other half goes to the deed's beneficiary address.
 */

contract CPXBases is ERC721Deed, Pausable, PullToBank, ReentrancyGuard, Administered {

  using SafeMath for uint256;

  /* Events */

  // When a deed is created.
  event LogCreation(uint256 indexed id, bytes32 indexed plane);

  // When a deed is bought, the ownership of the deed is transferred to the new owner. 
  event LogPurchase(uint256 indexed id, address indexed oldOwner, address indexed newOwner, uint256 price);

  /* The actual deeds */

  // The data structure of the example deed
  struct Base {
    uint256 price;
    uint256 created;
    uint256 deleted;
    bool forSale;
  }

  // Mapping from _deedId to Base
  mapping (uint256 => Base) private deeds;

  // Mapping from Plane to base - planes must use bytes32 address for CPXNetwork
  mapping (bytes32 => uint256[]) private planeBases;
  
  // Mapping from deed ID to plane
  mapping (uint256 => bytes32) private deedPlane;

  // Needed to make all deeds discoverable. The length of this array also serves as our deed ID.
  uint256[] private deedIds;


  /* Variables in control of owner */
  uint8 profitSharePercent = 1;

  // The contract owner can change the base URL, in case it becomes necessary. It is needed for Metadata.
  string public url = "https://www.cpx-outlands.com/";

  // ERC-165 Metadata
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


  function CPXBases() public {}

  // The contract owner can withdraw funds that were received this way.
  function() public payable {}

  modifier notDeleted(uint256 _deedId) {
    require(deeds[_deedId].deleted == 0);
    _;
  }


   /* ERC721Metadata */

  function name()
  external pure returns (string) {
    return "CPXBases";
  }

  function symbol()
  external pure returns (string) {
    return "CPXB";
  }

  function supportsInterface(bytes4 _interfaceID)
  external pure returns (bool) {
    return (
      _interfaceID == INTERFACE_SIGNATURE_ERC165
      || _interfaceID == INTERFACE_SIGNATURE_ERC721
      || _interfaceID == INTERFACE_SIGNATURE_ERC721Metadata
    );
  }

  /* Enable listing of all deeds (alternative to ERC721Enumerable to avoid having to work with arrays). */
  function ids()
  external view returns (uint256[]) {
    return deedIds;
  }
  
  function isDeedForSale(uint256 _deedId) 
  external view returns (bool) {
      return deeds[_deedId].forSale;
  }

  function deed(uint256 _deedId)
  external view returns (uint256 _price, uint256 _created, uint256 _deleted, bool _forSale) {
    _price = deeds[_deedId].price;
    _created = deeds[_deedId].created;
    _deleted = deeds[_deedId].deleted;
    _forSale = deeds[_deedId].forSale;
  }
  
  /**
  * @dev Gets the owner of the specified deed ID
  * @param _deedId uint256 ID of the deed to query the owner of
  * @return owner address currently marked as the owner of the given deed ID
  */
  function planeOf(uint256 _deedId)
  external view onlyAdmin returns (bytes32 _planeID) {
    require(deedPlane[_deedId] != 0);
    _planeID = deedPlane[_deedId];
  }
  
  function countOfDeedsByPlane(bytes32 _planeID)
  external view returns (uint256) {
      return(planeBases[_planeID].length);
  }
  
  function deedsOnPlane(bytes32 _planeID)
  external view onlyAdmin returns (uint256[]) {
      return(planeBases[_planeID]);
  }

  /* Core features of the example: Appropriation and Payment */

  // Forces the transfer of the deed to a new owner. This functionality can be paused by the owner.
  function purchase(uint256 _deedId)
  external whenNotPaused nonReentrant payable {
    //require for sale
    require(deeds[_deedId].forSale);
    // Require the right payment.
    uint256 oldPrice = priceOf(_deedId);
    uint256 newPrice = msg.value;
    require(newPrice >= oldPrice);

    // The current owner is forbidden to appropriate himself.
    address oldOwner = this.ownerOf(_deedId);
    address newOwner = msg.sender;
    require(oldOwner != newOwner);

    // The profit is split between the previous deed owner and the owner in equal parts.
    //Bank gets a percent of sale price
    uint256 profitShare = newPrice.mul(profitSharePercent).div(100);

    // The owner gets their share.
    asyncSend(bank, profitShare);

    // Reimburse previous owner their price minus the profit share
    asyncSend(oldOwner, newPrice.sub(profitShare));

    // Clear any outstanding approvals and transfer the deed.
    clearApprovalAndTransfer(oldOwner, newOwner, _deedId);
    LogPurchase(_deedId, oldOwner, newOwner, newPrice);
  }

  /* Creation Functions */

  // Only the admin can create bases - usually done by a support contract
  //may be used to create directy for private plane
  function create(bytes32 _planeID, address _owner)
  public onlyAdmin {
    require(_planeID != 0);
    //create
    uint256 deedId = deedIds.length;
    //push to array
    deedIds.push(deedId);
    super._mint(_owner, deedId);
    //push to plane 
    planeBases[_planeID].push(deedId);
    deedPlane[deedId] = _planeID;
    //create deed
    deeds[deedId] = Base({
      price: 0,
      created: now,
      deleted: 0,
      forSale: false
    });
    //log
    LogCreation(deedId, _planeID);
  }
  
  /* Base owner functions */
  
  //owner gets to set for sale
  function setForSale(uint256 _deedId, bool _forSale) 
  external onlyOwnerOf(_deedId) {
      deeds[_deedId].forSale = _forSale;
  }
  //owner gets to set price
  function setPrice(uint256 _deedId, uint256 _price) 
  external onlyOwnerOf(_deedId) {
      deeds[_deedId].price = _price;
  }
  
  /* Owner Functions */

  function setCost(uint8 _share)
  public onlyOwner {
    profitSharePercent = _share;
  }
  
  function setUrl(string _url)
  public onlyOwner {
    url = _url;
  }

  /* Other publicly available functions */

  // Returns the last paid price for this deed.
  function priceOf(uint256 _deedId)
  public view notDeleted(_deedId) returns (uint256 _price) {
    _price = deeds[_deedId].price;
  }
}
