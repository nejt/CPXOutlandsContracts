pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./TracksPlaneLocation.sol";

contract HeroStats is Ownable, TracksPlaneLocation {
    /* Activity and core stats*/
    struct Hero {
        bytes32 meta;
        uint256 lineage;
        uint256 gen;
        uint256 nKO;
        uint256 cooldown;
    }
    //map token id to the struct - for public view
    mapping (uint256 => Hero) public CPXHeroes;
    //list all heroes
    uint256[] private allHeroes;


    /*contract creation*/
    function HeroStats() public {}
    
    
    /* Information Functions 
        Many are admin only because player location is sensitive
    */
    //count of heroes
    function countOfHeroes() 
    external view returns (uint256 _count){
        _count = allHeroes.length;
    }
    
    //all hero token ids
    function allHeroTokens () 
    external view returns (uint256[] list){
        list = allHeroes;
    }

    //Checks whether it has been created    
    function isActive(uint256 _hero)
    public view returns (bool active) {
        active = CPXHeroes[_hero].meta != bytes32(0) ? true : false;
    }
    //easy meta reference
    function getMeta(uint256 _hero)
    external view returns (bytes32 meta) {
        meta = CPXHeroes[_hero].meta;
    }
    //easy cooldown reference
    function getCooldown(uint256 _hero)
    external view returns (uint256 cool) {
        cool = CPXHeroes[_hero].cooldown;
    }
    //easy nKO ref
    function getKO(uint256 _hero)
    external view returns (uint256 nKO) {
        nKO = CPXHeroes[_hero].nKO;
    }

    
    /*External By Owner Admin Contract*/
    
    //create a new hero - set meta
    function createHero(uint256 _hero, bytes32 _meta, uint256 _planeID) 
    external onlyOwner {
        //add to list
        allHeroes.push(_hero);
        //determine cooldown - always 2 hrs from creation
        uint256 cool = now + 2 * 1 hours;
        //create player
        CPXHeroes[_hero] = Hero(_meta, 0, 0, 0, cool);
        //set them on their plane
        addItemToPlane(_planeID, _hero);
    }
    
    //create a new hero from a lineage - set meta
    function createHero(uint256 _hero, bytes32 _meta, uint256 _lineage, uint256 _planeID) 
    external onlyOwner {
        //add to list
        allHeroes.push(_hero);
        //get lineage generation
        uint256 _gen = CPXHeroes[_lineage].gen;
        _gen++;
        //determine cooldown - always 2 hrs from creation
        uint256 cool = now + 2 * 1 hours;
        //lineage getts cooldown too
        CPXHeroes[_lineage].cooldown = cool;
        //create player
        CPXHeroes[_hero] = Hero(_meta, _lineage, _gen, 0, cool);
        //set them on their plane
        addItemToPlane(_planeID, _hero);
    }
    
    //increase KO
    function KO(uint256 _hero, uint256 _nullP, uint256 _i) 
    external onlyOwner{
        //increase KOP
        CPXHeroes[_hero].nKO++;
        //set cooldown - time 1 Hour per KO
        uint256 _cool = now + (CPXHeroes[_hero].nKO * 1 hours);
        CPXHeroes[_hero].cooldown = _cool;
        //move hero to null plane
        moveItem(_hero, _nullP, itemPlane[_hero], _i);
    }
    
    //set cooldown
    function setCooldown(uint256 _hero, uint256 _cool) 
    external onlyOwner {
        //set to cool
        CPXHeroes[_hero].cooldown = _cool;
    }
    
    //allow movement from a plane to another
    function moveHero(uint256 _hero, uint256 _to, uint256 _i)
    external onlyOwner {
        //perform move
        moveItem(_hero, _to, itemPlane[_hero], _i);
    }
}
