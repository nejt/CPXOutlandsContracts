pragma solidity 0.4.20;

import "./administered.sol";
import "./Base-0.1.0.sol";

contract CPXDistributor is administered {
    //supporting contract
    CPXBases internal CB;
    //planes to max CPX they can claim per day
    mapping (bytes32 => uint8) private planeValue;
    //players to last time they claimed
    mapping (address => uint) private lastClaim;
    //total values set by admins 
    //total CPX that can be claimed
    uint public totalPerDay;
    //sum of the total current plane value
    uint public totalPlaneValue;
    
    function () payable public {}
    
    function CPXDistributor() public {}
    
    function checkBalance() view public onlyAdmin returns(uint) {
        return(this.balance);
    }
    
    function claimCPX(bytes32 _plane, uint _baseid) public returns(uint){
        //no 0 value planes allowed
        require(planeValue[_plane] > 0);
        address _owner;
        uint _R;
        (_owner,_R) = CB.getBase(_plane,_baseid);
        //only the owner can call
        require(msg.sender == _owner);
        //only call after 180 blocks ~ 1 hour
        require(block.number-lastClaim[msg.sender] >= 180);
        //total base rank
        uint totalR = CB.planeTotalR(_plane);
        uint val = 0;
        //check if over or under
        if(totalR < planeValue[_plane]){
            val = _R * totalPerDay / totalPlaneValue;
        }
        else {
            uint _rv = 1000 * _R * planeValue[_plane] / totalR;
            val = _rv * totalPerDay / totalPlaneValue;
        }
        //set claim date
        lastClaim[msg.sender] = block.number;
        return(val);
    }
    
    function adminSetConstants (uint _tPerDay, uint _tPlaneVal) public onlyAdmin {
        totalPerDay = _tPerDay;
        totalPlaneValue = _tPlaneVal;
    }
    
}