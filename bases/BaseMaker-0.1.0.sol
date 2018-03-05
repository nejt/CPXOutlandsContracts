pragma solidity ^0.4.18;

import "./Administered.sol";
import "./CosmicCollection.sol";
import "./BaseStats.sol";

contract UnitStats {
    function planeOf(uint256 _uintID) public returns(uint256 _planeID);
}

//V0.1.0
contract BaseMaker is PaysBank, Administered {
    //requires token contract
    CosmicCollectionTokens CCT;
    //requires BaseStats
    BaseStats BSC;
    //requires UnitStats
    UnitStats USC;
    
    /* Admin Controlled Constants */

    //constants for pricing
    uint256 public creationCost = 1/10 * 1 ether;
    
    
    /* Contract creation */
    
    //fallback
    function () public payable {}
    //creation
    function BaseMaker() public {
        bank = msg.sender;
    }
    
    
   /* Events */
    event LogNewBase(uint256 indexed _planeID, address indexed _owner);


    /* Admin Functions */
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    function setConstants(uint256 _cost) 
    external onlyAdmin {
        creationCost = _cost;
    }
    
    //set the contract
    function setRefContracts (address _CCT, address _BSC, address _USC)
    external onlyOwner {
        CCT = CosmicCollectionTokens(_CCT);
        BSC = BaseStats(_BSC);
        USC = UnitStats(_USC);
    }
    
    //function that actually creates the base
    //used for personalPlane function to automatically create a base
    //also called by create function
    function adminSetBase(uint256 _planeID, address _owner)
    public onlyAdmin {
      //get the id from Cosmic 
      uint256 _baseID = CCT.nextDeedID();
      //Create core Base Stats - set location
      BSC.createBase(_baseID, _planeID);
      //create the base
      //token contract create - bases are type 2
      CCT.create(2, _owner);
    }
    
    
    /* player functions */
    
    //allows them to create a base on a plane where a unit is present
    function createBase(uint256 _uintID) 
    public payable {
        //it must be a unit
        require(CCT.typeOf(_uintID) == 3);
        //must be sender
        require(msg.sender == CCT.ownerOf(_uintID));
        //require funding
        require(msg.value >= creationCost);
        //Get plane id
        uint256 _planeID = USC.planeOf(_uintID);
        //create the base
        adminSetBase(_planeID, msg.sender);
    }
}