pragma solidity ^0.4.18;

import "./Administered.sol";
import "./OwningContract.sol";
import "./CosmicCollection.sol";
import "./PlaneStats.sol";

// Controller contract pass through
contract PlaneAdmin is Pausable, PaysBank, Administered, OwningContract {
    /* Constant Variables in control of owner */

    uint256 internal creationCost = 1 finney;
    uint256 internal creationStep = 5;
    uint public privatePlane = 1 finney / 2;
    uint public closedPlane = 1 finney / 2;
    
    //allow purchasing of planes
    bool canPurchasePlanes = true;

    /* Events */
    event LogNewPersonalPlane(address indexed _creator, uint256 id, bytes32 name);
    event LogNewNetworkPlane(address indexed _creator, uint256 id, uint16 indexed _netid, string paddress);


    /* Creation Functions */
    function () public payable {}
    function PlaneAdmin () public {}
    
    /* Admin Functions */
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    // this contract can be killed - it stores no data
    function killContract(address _stats, address _newOwner) 
    external onlyOwner {
        require(_stats != address(0) && _newOwner != address(0));
        //transfer ownership of stats to provided
        transferOCOwnership(_stats, _newOwner);
        //withdraw first
        withdraw();
        //destroy
        selfdestruct(owner);
    }
    
    function setConstants(uint[3] _cost, uint256 _step) 
    external onlyAdmin {
        if(_cost[0] != 0) creationCost = _cost[0];
        if(_cost[1] != 0) privatePlane = _cost[1];
        if(_cost[2] != 0) closedPlane = _cost[2];
        if(_step != 0) creationStep = _step;
    }
    
    function setCanPurchasePlanes(bool _canPurchase) 
    external onlyAdmin {
        canPurchasePlanes = _canPurchase;
    }
    
    function setCooldown (address _stats, uint256 _deedID, uint256 _cool)
    external onlyAdmin {
        PlaneStats(_stats).setCooldown(_deedID,_cool);
    }
    
    
    /* View Functions */
    
    function getCurrentCost (address _stats) 
    public view returns(uint256 cost) {
        uint256 n = PlaneStats(_stats).countOfPersonalPlanes();
        cost = creationCost * (100 + (creationStep * n)) / 100;
    }
    
    
    /* Public function */
    /* Creation of Planes */
    
    function createPersonalPlane(address _token, address _stats, string _name) 
    public payable whenNotPaused {
      //only when they can be bought
      require(canPurchasePlanes);
      //pull currentCost
      uint256 _cost = getCurrentCost(_stats);
      //must be paid
      require(msg.value >= _cost);
      //get the id
      uint256 _planeID = CosmicCollectionTokens(_token).nextDeedID();
      //get a name based on hash
      bytes32 hash = keccak256(_cost,msg.sender,_name);
      //token contract create - personalPlanes are type 1
      CosmicCollectionTokens(_token).create(1, msg.sender);
      //create the plane - stats contract
      PlaneStats(_stats).createPersonalPlane(_planeID, hash);
      //Log
      emit LogNewPersonalPlane(msg.sender,_planeID, hash);
    }
    
    function createNetworkPlane(address _token, address _stats, uint16 _netid, string _address) 
    public onlyAdmin whenNotPaused {
      //get the id
      uint256 _planeID = CosmicCollectionTokens(_token).nextDeedID();
      //token contract create - networ Planes are type 0
      //owner is owner of contract
      CosmicCollectionTokens(_token).create(0, owner);
      //create the plane - stats contract
      PlaneStats(_stats).createNetworkPlane(_planeID, _netid, _address);
      //Log
      emit LogNewNetworkPlane(msg.sender,_planeID,_netid,_address);
    }


    /* Plane Owners Set what they want */
    
    //allow owner to set privacy
    function setPrivate(address _token, address _stats, uint256 _planeID, bool _pvt)
    external payable whenNotPaused {
        //require ownership
        require(msg.sender == CosmicCollectionTokens(_token).ownerOf(_planeID));
        //must be a personalPlane
        require(CosmicCollectionTokens(_token).typeOf(_planeID) == 1);
        //check value
        require(msg.value >= privatePlane);
        //set privacy
        PlaneStats(_stats).setPrivacy(_planeID, _pvt);
    }
    
    //allow owner to set open state
    function setClosed(address _token, address _stats, uint256 _planeID, bool _isClosed)
    external payable whenNotPaused {
        //require ownership
        require(msg.sender == CosmicCollectionTokens(_token).ownerOf(_planeID));
        //must be a personalPlane
        require(CosmicCollectionTokens(_token).typeOf(_planeID) == 1);
        //check value
        require(msg.value >= closedPlane);
        //set closed
        PlaneStats(_stats).setClosed(_planeID, _isClosed);
    }
    
}