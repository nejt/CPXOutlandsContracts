pragma solidity ^0.4.18;

import "./TracksPlaneLocation.sol";
import "./ContractLinked.sol";
import "./Distributes.sol";

contract Token {
    function ownerOf(uint256 _deedId) external view returns (address _owner);
}

contract HeroLocation is ContractLinked, PaysBank, TracksPlaneLocation {
    /* Links
      0 - Token
    */
    //have they been initialized
    mapping (uint256 => bool) public initialized;
    
    //tracks movement cooldown for a hero
    mapping (uint256 => uint256) public cooldown;
    
    //cost for movement
    uint256 public moveCost = 0.2 * 1 finney;

    /*contract creation*/
    constructor () public {}
    
    
    /* Admin functions */
    // this contract can be killed
    function killContract() 
    external onlyOwner {
        bank.transfer(address(this).balance);
        //destroy
        selfdestruct(owner);
    }
    
    function setConstants(uint256 _move)
    external onlyOwner {
        if(_move != 0) moveCost = _move;
    }
    
    
    /* Information Functions 
        Many are admin only because player location is sensitive
    */

    /*External By Owner Admin Contract*/
    
    //initial move - one free move
    function setInitialLocation(uint256 hero, uint256 to)
    external {
        //require ownership
        require(msg.sender == Token(CLinks[0]).ownerOf(hero));
        require(!initialized[hero]);
        //initialize
        initialized[hero] = true;
        //set cooldown - one hour
        cooldown[hero] = now + 1 hours;
        //set location
        addItemToPlane(to, hero);
    }

    //allow movement from a plane to another
    function moveHero(uint256 hero, uint256 _to, uint256 _fromI)
    external payable {
        //require ownership
        require(msg.sender == Token(CLinks[0]).ownerOf(hero));
        //require payment
        require(msg.value >= moveCost);
        //require no cooldown
        require(cooldown[hero] < now);
        //set cooldown - one hour
        cooldown[hero] = now + 1 hours;
        //perform move
        moveItem(hero, _to, itemPlane[hero], _fromI);
    }
}
