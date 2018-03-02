pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./Distributes.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Deed.sol";
import "./ERC721Metadata.sol";

/*
  Notes on this example implementation:
  Thre is a bank that the contract pays all the fees
  The concept of "appropriation" is introduced: Deeds are permanently up for sale.
  Whoever is willing to pay more than the last price that was paid for a given deed, can take ownership of that deed.
  The previous owner is reimbursed with the amount he paid earlier, and additionally receives half of the amount that the price was increased by. The other half goes to the deed's beneficiary address.
 */

contract PersonalPlane is ERC721Deed, Pausable, PullToBank, ReentrancyGuard {

  using SafeMath for uint256;

  /* Events */

  // When a dead is created by the contract owner.
  event Creation(uint256 indexed id, bytes32 indexed name);

  // When a deed is appropriated, the ownership of the deed is transferred to the new owner. The old owner is reimbursed, and he and the deed's beneficiary share the profit of the sale.
  event Appropriation(uint256 indexed id, address indexed oldOwner, uint256 oldPrice, address indexed newOwner, uint256 newPrice);

  /* The actual deeds */

  // The data structure of the example deed
  struct Plane {
    bytes32 name;
    uint256 price;
    uint256 created;
    uint256 deleted;
    bool forSale;
  }

  // Mapping from _deedId to Example
  mapping (uint256 => Plane) private deeds;

  // Mapping from deed name to boolean indicating if the name is already taken
  mapping (bytes32 => bool) private deedNameExists;

  // Needed to make all deeds discoverable. The length of this array also serves as our deed ID.
  uint256[] private deedIds;


  /* Variables in control of owner */

  // The contract owner can change the initial price of deeds at Creation.
  uint256 private creationPrice = 1 finney;
  uint256 private percentStep = 5;

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


  function PersonalPlane() public {}

  // The contract owner can withdraw funds that were received this way.
  function() public payable {}

  modifier onlyExistingNames(uint256 _deedId) {
    require(deedNameExists[deeds[_deedId].name]);
    _;
  }

  modifier noExistingNames(bytes32 _name) {
    require(!deedNameExists[_name]);
    _;
  }

  modifier notDeleted(uint256 _deedId) {
    require(deeds[_deedId].deleted == 0);
    _;
  }


   /* ERC721Metadata */

  function name()
  external pure returns (string) {
    return "CPXPersonalPlane";
  }

  function symbol()
  external pure returns (string) {
    return "CPXP";
  }

  function supportsInterface(bytes4 _interfaceID)
  external pure returns (bool) {
    return (
      _interfaceID == INTERFACE_SIGNATURE_ERC165
      || _interfaceID == INTERFACE_SIGNATURE_ERC721
      || _interfaceID == INTERFACE_SIGNATURE_ERC721Metadata
    );
  }

  function deedUri(uint256 _deedId)
  external view onlyExistingNames(_deedId) returns (string _uri,bytes32 _name) {
    _uri = url;
    _name = deeds[_deedId].name;
  }

  function deedName(uint256 _deedId)
  external view onlyExistingNames(_deedId) returns (bytes32 _name) {
    _name = deeds[_deedId].name;
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
  external view returns (bytes32 _name, uint256 _price, uint256 _created, uint256 _deleted, bool _forSale) {
    _name = deeds[_deedId].name;
    _price = deeds[_deedId].price;
    _created = deeds[_deedId].created;
    _deleted = deeds[_deedId].deleted;
    _forSale = deeds[_deedId].forSale;
  }


  /* Core features of the example: Appropriation and Payment */

  // Forces the transfer of the deed to a new owner, if a higher price was paid. This functionality can be paused by the owner.
  function appropriate(uint256 _deedId)
  external whenNotPaused nonReentrant payable {
    //require for sale
    require(deeds[_deedId].forSale);
    // The new price must be greater than the old price.
    uint256 oldPrice = priceOf(_deedId);
    uint256 newPrice = msg.value;
    require(newPrice > oldPrice);

    // The current owner is forbidden to appropriate himself.
    address oldOwner = this.ownerOf(_deedId);
    address newOwner = msg.sender;
    require(oldOwner != newOwner);

    // Set new price of the deed.
    deeds[_deedId].price = newPrice;

    // The profit is split between the previous deed owner and the owner in equal parts.
    uint256 profitShare = newPrice.sub(oldPrice).div(2);

    // The owner gets their share.
    asyncSend(bank, profitShare);

    // Reimburse previous owner with his share and the price he paid.
    asyncSend(oldOwner, profitShare.add(oldPrice));

    // Clear any outstanding approvals and transfer the deed.
    clearApprovalAndTransfer(oldOwner, newOwner, _deedId);
    Appropriation(_deedId, oldOwner, oldPrice, newOwner, newPrice);
  }

  /* Creation Functions */
  
  function currentCost() 
  view public returns (uint reg) {
        uint mod = deedIds.length * percentStep;
        reg = creationPrice*(100+mod)/100;
    }

  // The contract owner creates deeds. Newly created deeds are initialised with a name and a beneficiary.
  function create(string _input)
  public payable {
    //set id
    uint256 deedId = deedIds.length;
    //check cost
    uint256 _cost = currentCost();
    //check payment
    require(msg.value >= _cost);
    // The bank gets their share.
    asyncSend(bank, _cost);
    //create name from hash
    bytes32 _name = keccak256(deedId,_input);
    //make sure it doesn't it exist
    require(!deedNameExists[_name]);
    //make it exist
    deedNameExists[_name] = true;
    //push to array
    deedIds.push(deedId);
    super._mint(msg.sender, deedId);
    deeds[deedId] = Plane({
      name: _name,
      price: creationPrice,
      created: now,
      deleted: 0,
      forSale: false
    });
    Creation(deedId, _name);
  }
  
  //owner gets to set for sale
  function setForSale(uint256 _deedId, bool _forSale) 
  external onlyOwnerOf(_deedId) {
      deeds[_deedId].forSale = _forSale;
  }
  
  /* Owner Functions */

  function setCreationPrice(uint256 _price, uint256 _step)
  public onlyOwner {
    creationPrice = _price;
    percentStep = _step;
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
