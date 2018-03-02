pragma solidity ^0.4.18;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./PullPayment.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Deed.sol";
import "./ERC721Metadata.sol";

/*
  Notes on this example implementation:

  For this example, each deed is associated with a name and a beneficiary, and the concept of "appropriation" is introduced: Deeds are permanently up for sale.
  Whoever is willing to pay more than the last price that was paid for a given deed, can take ownership of that deed.
  The previous owner is reimbursed with the amount he paid earlier, and additionally receives half of the amount that the price was increased by. The other half goes to the deed's beneficiary address.
 */

contract ExampleDeed is ERC721Deed, Pausable, PullPayment, ReentrancyGuard {

  using SafeMath for uint256;

  /* Events */

  // When a dead is created by the contract owner.
  event Creation(uint256 indexed id, bytes32 indexed name, address beneficiary);

  // When a deed is appropriated, the ownership of the deed is transferred to the new owner. The old owner is reimbursed, and he and the deed's beneficiary share the profit of the sale.
  event Appropriation(uint256 indexed id, address indexed oldOwner, uint256 oldPrice, address indexed newOwner, uint256 newPrice);

  // Payments to the deed's beneficiary address via PullPayment are also supported by this contract.
  event Payment(uint256 indexed id, address indexed sender, address indexed beneficiary, uint256 amount);

  // When a deed needs to be removed. Payments to benefeciaries are kept available for withdrawal. The contract owner needs to own the deed in order to be able to destroy it. So, deed owners are protected from involuntary loss of the potential reimbursement.
  event Destruction(uint256 indexed id);

  /* The actual deeds */

  // The data structure of the example deed
  struct Example {
    bytes32 name;
    uint256 price;
    uint256 created;
    uint256 deleted;
    bool forSale;
    bool pvt;
    bool closed;
  }

  // Mapping from _deedId to Example
  mapping (uint256 => Example) private deeds;

  // Mapping from deed name to boolean indicating if the name is already taken
  mapping (bytes32 => bool) private deedNameExists;

  // Needed to make all deeds discoverable. The length of this array also serves as our deed ID.
  uint256[] private deedIds;

  /* Variables in control of owner */

  // The contract owner can change the initial price of deeds at Creation.
  address private bank; 
  uint256 private creationPrice = 0.001 ether;
  uint256 private percentStep = 5;

  // The contract owner can change the base URL, in case it becomes necessary. It is needed for Metadata.
  string public url = "http://example.com/";

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


  function ExampleDeed() public {}

  // The contract owner can withdraw funds that were received this way.
  function() public payable {}
  
  modifier isForSale(uint256 _deedId) {
    require(deeds[_deedId].forSale);
    _;
  }

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
    return "ExampleDeed";
  }

  function symbol()
  external pure returns (string) {
    return "ED";
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

  function deed(uint256 _deedId)
  external view returns (bytes32) {
    return deeds[_deedId].name;
  }


  /* Core features of the example: Appropriation and Payment */

  // Forces the transfer of the deed to a new owner, if a higher price was paid. This functionality can be paused by the owner.
  function appropriate(uint256 _deedId)
  external whenNotPaused nonReentrant isForSale(_deedId) payable {
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

    // The profit is split between the previous deed owner and the deed beneficiary in equal parts.
    uint256 profitShare = newPrice.sub(oldPrice).div(2);

    // The deed beneficiary gets his share.
    asyncSend(bank, profitShare);

    // Reimburse previous owner with his share and the price he paid.
    asyncSend(oldOwner, profitShare.add(oldPrice));

    // Clear any outstanding approvals and transfer the deed.
    clearApprovalAndTransfer(oldOwner, newOwner, _deedId);
    Appropriation(_deedId, oldOwner, oldPrice, newOwner, newPrice);
  }

  // Send a PullPayment.
  function pay(uint256 _deedId)
  external nonReentrant payable {
    asyncSend(bank, msg.value);
    Payment(_deedId, msg.sender, bank, msg.value);
  }

  // The owner can only withdraw what has not been assigned to beneficiaries as PullPayments.
  function withdraw()
  external nonReentrant {
    withdrawPayments();
    if (msg.sender == owner) {
      // The contract's balance MUST stay backing the outstanding withdrawals. Only the surplus not needed for any backing can be withdrawn by the owner.
      uint256 surplus = this.balance.sub(totalPayments);
      if (surplus > 0) {
        owner.transfer(surplus);
      }
    }
  }


  /* Buy New */
  
  function currentPrice() 
  view public returns (uint) {
      uint mod = deedIds.length * percentStep;
      uint reg = creationPrice*(100+mod)/100;
      return(reg);
  }

  // The contract owner creates deeds. Newly created deeds are initialised with a name and a beneficiary.
  function create(string _name)
  public payable {
    //get cost
    uint price = currentPrice();
    //require the price
    require(msg.value >= price);
    uint256 deedId = deedIds.length;
    deedIds.push(deedId);
    bytes32 _hash = keccak256(block.number,deedId,msg.sender,_name);
    deedNameExists[_hash] = true;
    super._mint(msg.sender, deedId);
    deeds[deedId] = Example({
      name: _hash,
      price: price,
      created: now,
      deleted: 0,
      forSale: false,
      pvt: false,
      closed: false
    });
    Creation(deedId, _hash, msg.sender);
  }
  
  /* Owner Functions */

  // Deeds can only be burned if the contract owner is also the deed owner. This ensures that the deed owner is reimbursed when the contract owner needs to remove a deed from the contract.
  function destroy(uint256 _deedId)
  public onlyOwner notDeleted(_deedId) {
    // We deliberately let the name stay in use, so that each name remains a unique identifier forever.

    // We deliberately let any payments stored for the beneficiary. The contract owner cannot withdraw such deposits.

    // Iterating over an array of IDs is too expensive, so we mark the deed as deleted instead.
    deeds[_deedId].deleted = now;

    super._burn(_deedId);
    Destruction(_deedId);
  }

  function setPricing(uint256 _price, uint256 _step)
  public onlyOwner {
    creationPrice = _price;
    percentStep = _step;
  }
  
  function setBank(address _bank)
  public onlyOwner {
    bank = _bank;
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
