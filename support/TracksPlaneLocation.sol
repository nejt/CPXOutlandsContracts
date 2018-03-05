pragma solidity ^0.4.18;

import "./Administered.sol";

contract TracksPlaneLocation is Administered {
    /* Handle Locations */
    
    // Mapping from Plane to Item 
    mapping (uint256 => uint256[]) internal planeDeeds;
    
    // Mapping from deed ID to plane
    mapping (uint256 => uint256) internal deedPlane;
    
    function TracksPlaneLocation() public {}
    
    
    /* Information Functions */
    /**
    * @dev Gets the owner of the specified deed ID
    * @param _deedID uint256 ID of the deed to query the owner of
    * @return owner address currently marked as the owner of the given deed ID
    */
    function planeOf(uint256 _deedID)
    external view returns (uint256 _planeID) {
      require(deedPlane[_deedID] != 0);
      _planeID = deedPlane[_deedID];
    }
    
    function countOfDeedsByPlane(uint256 _planeID)
    external view returns (uint256) {
        return(planeDeeds[_planeID].length);
    }
    
    function deedsOnPlane(uint256 _planeID)
    external view onlyAdmin returns (uint256[]) {
        return(planeDeeds[_planeID]);
    }
    
    
    /* working functions  */
    
    function addDeedToPlane(uint256 _planeID, uint256 _deedID)
    internal {
        planeDeeds[_planeID].push(_deedID);
        deedPlane[_deedID] = _planeID;
    }
}