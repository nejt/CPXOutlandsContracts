pragma solidity ^0.4.18;

import "./PersonalPlanes-0.5.0.sol";
import "./Distributes.sol";

/*  @dev Contract handles privacy and open/closed state for private planes
*/
contract PersonalPlanesPrivacy is PaysBank{
    //requires planes contract
    PersonalPlane PPC;
    //basic plane privacy open state
    struct planePrivacy {
        bool pvt;
        bool isClosed;
    }
    //mapping to handle privacy struct 
    mapping (uint256 => planePrivacy) internal privacy;
    
    function PersonalPlanesPrivacy () public {}
    
    //constants
    uint public privatePlane = 1 finney / 2;
    uint public closedPlane = 1 finney / 2;
    
    /* Owner Functions */
    
    //set the contract
    function setPersonalPlaneContract (address _C)
    external onlyOwner {
        PPC = PersonalPlane(_C);
    }
    
    //set constants
    function setConstants(uint[2] _cost) 
    external onlyOwner {
        privatePlane = _cost[0];
        closedPlane = _cost[1];
    }
    
    /**
    * @dev Guarantees msg.sender is owner of the given deed
    * @param _deedId uint256 ID of the deed to validate its ownership belongs to msg.sender
    */
    modifier onlyOwnerOf(uint256 _deedId) {
        require(PPC.ownerOf(_deedId) == msg.sender);
        _;
    }
    
    //get information
    function getPrivacy(uint256 _deedID) 
    view external returns(bool _pvt, bool _isClosed){
        return(privacy[_deedID].pvt,privacy[_deedID].isClosed);
    }
    
    /* Plane Owners Set what they want */
    
    //allow owner to set privacy
    function setPrivate(uint256 _deedID, bool _pvt)
    external payable onlyOwnerOf(_deedID) {
        //check value
        require(msg.value >= privatePlane);
        //set privacy
        privacy[_deedID].pvt = _pvt;
    }
    
    //allow owner to set open state
    function setClosed(uint256 _deedID, bool _closed)
    external payable onlyOwnerOf(_deedID) {
        //check value
        require(msg.value >= closedPlane);
        //set privacy
        privacy[_deedID].isClosed = _closed;
    }
}