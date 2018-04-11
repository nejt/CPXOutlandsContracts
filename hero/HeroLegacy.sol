pragma solidity ^0.4.18;

import "./Ownable.sol";

contract HeroLegacy is Ownable {
    /* Activity and core stats*/
    struct Legacy {
        uint256 lineage;
        bool canTrain;
    }
    //map token id to the struct - for public view
    mapping (uint256 => Legacy) public legacies;


    /*contract creation*/
    function HeroLegacy() public {}
    
    
    /* Information Functions 
        Many are admin only because player location is sensitive
    */
    //easy canTrain reference
    function getCanTrain(uint256 _hero)
    external view returns (bool canTrain) {
        canTrain = legacies[_hero].canTrain;
    }

    
    /*External By Owner Admin Contract*/

    //create a new hero from a lineage - set meta
    function trainNewHero(uint256 _hero, uint256 _lineage) 
    external onlyOwner {
        //set lineage
        legacies[_hero].lineage = _lineage;
    }

    //set canTrain
    function setCanTrain(uint256 _hero, bool _canTrain) 
    external onlyOwner {
        legacies[_hero].canTrain = _canTrain;
    }
    
}
