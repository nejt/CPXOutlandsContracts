pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./TracksPlaneLocation.sol";

contract HeroLocation is Ownable, TracksPlaneLocation {

    /*contract creation*/
    function HeroLocation() public {}
    
    /* Information Functions 
        Many are admin only because player location is sensitive
    */

    /*External By Owner Admin Contract*/

    //allow movement from a plane to another
    function moveHero(uint256 _hero, uint256 _to, uint256 _i)
    external onlyOwner {
        //perform move
        moveItem(_hero, _to, itemPlane[_hero], _i);
    }
}
