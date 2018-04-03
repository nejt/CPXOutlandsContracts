pragma solidity ^0.4.18;

import "./Ownable.sol";

/*  @dev Contract handles the core stats for a private plane
*/
contract PlaneStats is Ownable{
    /* Plane Data */

    struct Plane {
        uint8 climate;
        uint8 terrain;
        uint8 powerMultiplier; 
        uint256 cooldown;
    }

    //maping to contain modified plane data
    mapping (uint256 => Plane) public planeData;
    

    /* Contract Creation */

    function PlaneStats () public {}
    
    
    /*View Individual data */
    function getCooldown (uint256 _planeID)
    public view returns (uint256 cooldown) {
        cooldown = planeData[_planeID].cooldown;
    }
    
    function getClimate (uint256 _planeID)
    public view returns (uint8 climate) {
        climate = planeData[_planeID].climate;
    }
    
    function getTerrain (uint256 _planeID)
    public view returns (uint8 terrain) {
        terrain = planeData[_planeID].terrain;
    }
    
    function getPowerMultiplier (uint256 _planeID)
    public view returns (uint8 powerMultiplier) {
        powerMultiplier = planeData[_planeID].powerMultiplier;
    }

    /* Individual plane data 
        Set by Maker contract - this contract is purely data
    */
    
    //set cooldown
    function setCooldown (uint256 _planeID, uint256 _cool)
    external onlyOwner {
      planeData[_planeID].cooldown = _cool;
    }
    
    function setClimate (uint256 _planeID, uint8 climate)
    external onlyOwner {
      planeData[_planeID].climate = climate;
    }
    
    function setTerrain (uint256 _planeID, uint8 terrain)
    external onlyOwner {
      planeData[_planeID].terrain = terrain;
    }
    
    function setPowerMultiplier (uint256 _planeID, uint8 powerMultiplier)
    external onlyOwner {
      planeData[_planeID].powerMultiplier = powerMultiplier;
    }
}