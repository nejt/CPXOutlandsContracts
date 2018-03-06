pragma solidity ^0.4.18;

import "./Administered.sol";
import "./CosmicCollection.sol";
import "./PlaneStats.sol";
import "./PlaneAdmin-0.1.0.sol";

/*  @dev Contract handles creation of planes
*/
contract PlaneMaker is Pausable, PaysBank, Administered{
    //requires token contract
    CosmicCollectionTokens CCT;
    //requires plane stats
    PlaneStats PSC;
    //requires plane admin
    PlaneAdmin PAC;


    /* Constant Variables in control of owner */

    uint256 public creationPrice = 1 finney;
    uint256 private percentStep = 5;
    uint public privatePlane = 1 finney / 2;
    uint public closedPlane = 1 finney / 2;
    
    //allow purchasing of planes
    bool canPurchasePlanes = true;


    /* Creation Functions */
    function () public payable {}
    function PlaneMaker () public {
        //initialize - known contracts will vary
        bank = 0x1e1a7f243df786d412fd048d7a093826db396ad9;
        CCT = CosmicCollectionTokens(0x08e448a9c19a4806c988e097828fd2efce9cc58a);
        PSC = PlaneStats(0x5b4d3d9602a170be47044522b7d59596388d2048);
        PAC = PlaneAdmin(0x9660140527c7232227b6393d548ed88ad2bdd601);
    }
    
    
    /* Modifiers */
    /**
    * @dev Guarantees msg.sender is owner of the given deed
    * @param _deedId uint256 ID of the deed to validate its ownership belongs to msg.sender
    */
    modifier onlyOwnerOf(uint256 _deedId) {
        require(CCT.ownerOf(_deedId) == msg.sender);
        _;
    }
    
    
    /* Events */
    event LogNewPersonalPlane(address indexed _creator, uint256 id, bytes32 name);
    event LogNewNetworkPlane(address indexed _creator, uint256 id, uint16 indexed _netid, string paddress);

    /* Admin Functions */
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    function setConstants(uint[3] _cost, uint256 _step) 
    external onlyAdmin {
        creationPrice = _cost[0];
        privatePlane = _cost[1];
        closedPlane = _cost[2];
        percentStep = _step;
    }
    
    //set the contract
    function setRefContracts (address _CCT, address _PSC, address _PAC)
    external onlyOwner {
        CCT = CosmicCollectionTokens(_CCT);
        PSC = PlaneStats(_PSC);
        PAC = PlaneAdmin(_PAC);
    }
    
    function setCanPurchasePlanes(bool _canPurchase) 
    external onlyAdmin {
        canPurchasePlanes = _canPurchase;
    }
    
    // this contract can be killed - it stores no data
    function killContract() 
    external onlyOwner {
        selfdestruct(bank);
    }
    
    
    /* View Functions */
    
    function currentCost() 
    view public returns (uint reg) {
        uint mod = PSC.countOfPersonalPlanes() * percentStep;
        reg = creationPrice*(100+mod)/100;
    }
    
    
    /* Creation of Planes */
    
    function createPersonalPlane(string _name) 
    public payable whenNotPaused {
      //only when they can be bought
      require(canPurchasePlanes);
      //pull currentCost
      uint256 _cost = currentCost();
      //must be paid
      require(msg.value >= _cost);
      //get the id
      uint256 _planeID = CCT.nextDeedID();
      //get a name based on hash
      bytes32 hash = keccak256(_cost,msg.sender,_name);
      //token contract create - personalPlanes are type 1
      CCT.create(1, msg.sender);
      //create the plane - stats contract
      PAC.createPersonalPlane(_planeID, hash);
      //Log
      LogNewPersonalPlane(msg.sender,_planeID, hash);
    }
    
    function createNetworkPlane(uint16 _netid, string _address) 
    public onlyAdmin whenNotPaused {
      //get the id
      uint256 _planeID = CCT.nextDeedID();
      //token contract create - networ Planes are type 0
      //owner is owner of contract
      CCT.create(0, owner);
      //create the plane - stats contract
      PAC.createNetworkPlane(_planeID, _netid, _address);
      //Log
      LogNewNetworkPlane(msg.sender,_planeID,_netid,_address);
    }


    /* Plane Owners Set what they want */
    
    //allow owner to set privacy
    function setPrivate(uint256 _deedID, bool _pvt)
    external payable whenNotPaused onlyOwnerOf(_deedID) {
        //must be a personalPlane
        require(CCT.typeOf(_deedID) == 1);
        //check value
        require(msg.value >= privatePlane);
        //set privacy
        PAC.setPrivacy(_deedID, _pvt);
    }
    
    //allow owner to set open state
    function setClosed(uint256 _deedID, bool _isClosed)
    external payable whenNotPaused onlyOwnerOf(_deedID) {
        //must be a personalPlane
        require(CCT.typeOf(_deedID) == 1);
        //check value
        require(msg.value >= closedPlane);
        //set closed
        PAC.setClosed(_deedID, _isClosed);
    }
}