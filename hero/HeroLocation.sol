pragma solidity ^0.4.18;

import "./TracksPlaneLocation.sol";
import "./PaysBank.sol";
import "./TokenPayments.sol";
import "./Cooldown.sol";

contract Collectable {
    function ownerOf(uint256 _deedId) external view returns (address _owner);
}

contract HeroLocation is PaysBank, TracksPlaneLocation, TokenAndEtherPaymentProcessor {
    
    //have they been initialized
    mapping (uint256 => bool) public initialized;

    //cost for movement
    //ETH and CPX
    uint256[2] internal moveCost = [0.2 * 1 finney, 200];

    /*contract creation*/
    constructor () public {
        // Links - 0 Bank, 1 Collectable, 2 Cooldown, 3 CPX
        CLinks = [
            0x16e39D98A3f25B39eBdA681ECaE94418E1d20De2, 
            0x572403E42F7d787f3EA38eeCCCe7699c02e95f55, 
            0xc7602f54aF9e6Ef0637a6f83D0c32bDF949dad7f, 
            0xFD90bf0c7758F98269d59Dd908771f874C9A17f6
            ];
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
    function getCost () 
    public view returns (uint256[2] cost) {
        cost = moveCost;
    }

    /*External By Owner Admin Contract*/
    
    //initial move - one free move
    function setInitialLocation(uint256 hero, uint256 to)
    external {
        //require ownership
        require(msg.sender == Collectable(CLinks[1]).ownerOf(hero));
        require(!initialized[hero]);
        //initialize
        initialized[hero] = true;
        //set cooldown - one hour
        Cooldown(CLinks[2]).setCooldown(hero, now + 1 hours);
        //set location
        addItemToPlane(to, hero);
    }

    //allow movement from a plane to another
    function moveHero(uint256 hero, uint256 _to, uint256 _fromI)
    external payable {
        //require ownership
        require(msg.sender == Collectable(CLinks[1]).ownerOf(hero));
        //require cooldown
        require(Cooldown(CLinks[2]).cooldown(hero) < now);
        //get payment
        require(processPayment(CLinks[3], msg.sender, msg.value, moveCost));
        //set cooldown - one hour
        Cooldown(CLinks[2]).setCooldown(hero, now + 1 hours);
        //perform move
        moveItem(hero, _to, itemPlane[hero], _fromI);
    }
}
