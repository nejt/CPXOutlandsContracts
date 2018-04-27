pragma solidity ^0.4.18;

import "./ContractLinked.sol";
import "./Distributes.sol";

contract Token {
    function ownerOf(uint256 _deedId) external view returns (address _owner);
}

/*  @dev Contract handles the core stats for a private plane
*/
contract PlaneStats is ContractLinked, PaysBank{
    /* Links
      0 - Token
    */
    /* Plane Data */

    struct Plane {
        uint8 climate;
        uint8 terrain;
        uint8 powerMultiplier; 
    }

    //maping to contain modified plane data
    mapping (uint256 => Plane) public planeData;
    
    /* Contract costs */
    uint256 public planeChange = 1 finney;
    

    /* Contract Creation */

    function PlaneStats () public {}
    
    
    /*View Individual data */
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
    
    
    /* Admin Functions */
    function setConstants(uint _change) 
    external onlyOwner {
        if(_change != 0) planeChange = _change;
    }
    

    /* Individual plane data 
        Set by Maker contract - this contract is purely data
    */
    
    function setClimate (uint256 _planeID, uint8 climate)
    external payable {
        //only owner of plane
        require(msg.sender == Token(CLinks[0]).ownerOf(_planeID));
        //must be paid
        require(msg.value >= planeChange);
        //set value
        planeData[_planeID].climate = climate;
    }
    
    function setTerrain (uint256 _planeID, uint8 terrain)
    external payable {
        //only owner of plane
        require(msg.sender == Token(CLinks[0]).ownerOf(_planeID));
        //must be paid
        require(msg.value >= planeChange);
        //set value
        planeData[_planeID].terrain = terrain;
    }
    
    function setPowerMultiplier (uint256 _planeID, uint8 powerMultiplier)
    external payable {
        //only owner of plane
        require(msg.sender == Token(CLinks[0]).ownerOf(_planeID));
        //validate multiplier is 10 or less - and greater than current
        uint8 _current = planeData[_planeID].powerMultiplier;
        require(powerMultiplier <= 10 &&  _current < powerMultiplier);
        //cost is exponential - based new value
        uint256 _cost = planeChange * (2 ** uint(powerMultiplier));
        //must be paid
        require(msg.value >= _cost);
        //set value
        planeData[_planeID].powerMultiplier = powerMultiplier;
    }
}