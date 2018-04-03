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
    uint256 internal planeChange = 1 finney;

    //allow purchasing of planes
    bool canPurchasePlanes = true;

    /* Events */
    event LogNewPlane(address indexed _creator, uint256 id);


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
    
    function setConstants(uint[3] _cost) 
    external onlyAdmin {
        if(_cost[0] != 0) creationCost = _cost[0];
        if(_cost[1] != 0) creationStep = _cost[1];
        if(_cost[2] != 0) planeChange = _cost[2];
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
    
    function getCurrentCost (address _token) 
    public view returns(uint256 cost) {
        //planes are type 0
        uint256 n = CosmicCollectionTokens(_token).countOfDeedsOfType(0);
        cost = creationCost * (100 + (creationStep * n)) / 100;
    }
    
    
    /* Public function */
    /* Creation of Planes */
    
    function createPlane(address _token) 
    public payable whenNotPaused {
      //only when they can be bought
      require(canPurchasePlanes);
      //pull currentCost
      uint256 _cost = getCurrentCost(_token);
      //must be paid
      require(msg.value >= _cost);
      //get the id
      uint256 _planeID = CosmicCollectionTokens(_token).nextDeedID();
      //token contract create - planes are type 0
      CosmicCollectionTokens(_token).create(0, msg.sender);
      //Log
      emit LogNewPlane(msg.sender,_planeID);
    }
    

    /* Plane Owners Set what they want */
    function setClimate(address _token, address _stats, uint256 _planeID, uint8 climate) 
    public payable {
        //only owner of plane
        require(msg.sender == CosmicCollectionTokens(_token).ownerOf(_planeID));
        //must be paid
        require(msg.value >= planeChange);
        //set value
        PlaneStats(_stats).setClimate(_planeID, climate);
    }
    
    function setTerrain(address _token, address _stats, uint256 _planeID, uint8 terrain) 
    public payable {
        //only owner of plane
        require(msg.sender == CosmicCollectionTokens(_token).ownerOf(_planeID));
        //must be paid
        require(msg.value >= planeChange);
        //set value
        PlaneStats(_stats).setClimate(_planeID, terrain);
    }
    
    function setPowerMultiplier(address _token, address _stats, uint256 _planeID, uint8 powerMultiplier) 
    public payable {
        //only owner of plane
        require(msg.sender == CosmicCollectionTokens(_token).ownerOf(_planeID));
        //validate multiplier is 10 or less - and greater than current
        uint8 _current = PlaneStats(_stats).getPowerMultiplier(_planeID);
        require(powerMultiplier <= 10 &&  _current < powerMultiplier);
        //cost is exponential - based new value
        uint256 _cost = planeChange * (2 ** uint(powerMultiplier));
        //must be paid
        require(msg.value >= _cost);
        //set value
        PlaneStats(_stats).setPowerMultiplier(_planeID, powerMultiplier);
    }
    
}