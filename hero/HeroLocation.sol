pragma solidity ^0.4.18;

import "./TracksPlaneLocation.sol";
import "./PaysBank.sol";
import "./CosmicPowerToken.sol";
import "./Cooldown.sol";

contract Token {
    function ownerOf(uint256 _deedId) external view returns (address _owner);
}

contract HeroLocation is PaysBank, TracksPlaneLocation {
    
    //have they been initialized
    mapping (uint256 => bool) public initialized;
    
    //tracks movement cooldown for a hero
    mapping (uint256 => uint256) public cooldown;
    
    //cost for movement
    //ETH and CPX
    uint256[2] public moveCost = [0.2 * 1 finney, 200];

    /*contract creation*/
    constructor () public {
        // Links - 0 Bank, 1 Token, 2 Cooldown, 3 CPX
        CLinks = [0x5EF476161F3769b5099d404e421Ce07604555D96,0xc5340D8d98592F995d288945868F3563c0f0bA7A,0x81C264028517440ab094B4fe929150A0940279eA,0x53794eD95785D44d64534551883d948C4BF95B1e];
    }
    
    
    /* Admin functions */
    // this contract can be killed
    function killContract() 
    external onlyOwner {
        CLinks[0].transfer(address(this).balance);
        //destroy
        selfdestruct(owner);
    }
    
    function setConstants(uint256[2] cost)
    external onlyOwner {
        moveCost = cost;
    }
    
    
    /* Information Functions 
        Many are admin only because player location is sensitive
    */

    /*External By Owner Admin Contract*/
    
    //initial move - one free move
    function setInitialLocation(uint256 hero, uint256 to)
    external {
        //require ownership
        require(msg.sender == Token(CLinks[1]).ownerOf(hero));
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
        require(msg.sender == Token(CLinks[1]).ownerOf(hero));
        //check for CPX allowance
        uint256 allowance = CosmicPowerToken(CLinks[3]).allowance(msg.sender,address(this));
        //require payment - CPX or msg
        require(allowance >= moveCost[1] || msg.value >= moveCost[0]);
        //if allowance - take
        if(CosmicPowerToken(CLinks[3]).transferFrom(msg.sender, address(this), moveCost[1])) {
            //burn
            CosmicPowerToken(CLinks[3]).transfer(address(0), moveCost[1]);
        }
        //require cooldown
        require(Cooldown(CLinks[2]).cooldown(hero) < now);
        //set cooldown - one hour
        Cooldown(CLinks[2]).setCooldown(hero, now + 1 hours);
        //perform move
        moveItem(hero, _to, itemPlane[hero], _fromI);
    }
}
