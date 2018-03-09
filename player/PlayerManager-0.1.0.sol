pragma solidity ^0.4.18;

import "./Administered.sol";
import "./Distributes.sol";
import "./PlayerStats.sol";

contract PlayerManager is PaysBank, Administered {
    // support contracts
    PlayerStats PSC;
    
    /* constants */
    uint256 public playerMoveCost = 0.1 * 1 finney;
    uint256 public playerTypeCost = 0.25 * 1 finney;
    
    /* Contract creation */
    function PlayerManager() public {}
    function () public payable {}
    
    /*Admin Functions*/
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    function setRefContract (address _PSC)
    external onlyOwner {
        PSC = PlayerStats(_PSC);
    }
    
    function setConstants(uint256 _move,uint256 _type) 
    external onlyAdmin{
        if(_move !=0) playerMoveCost = _move;
        if(_type !=0) playerTypeCost = _type;
    }
    
    
    /*internal control of PlayerStats*/ 
    //allow admin movement
    function adminMovePlayer(uint256 _toID, address _player, uint256 _fromID, uint256 _i)
    external onlyAdmin {
        //must be at the location
        require(PSC.playerAtIndex(_fromID,_i) == msg.sender);
        PSC.movePlayer(_toID,_player,_fromID,_i);
    }
    
    /* External functions for players */
    function Activate(uint8 _t, uint256 _planeID) 
    external {
        //cannot be active
        require(!PSC.isActive(msg.sender));
        //activate
        PSC.setActive(msg.sender);
        //set type
        PSC.setType(msg.sender,_t);
        //set initial location
        PSC.movePlayer(_planeID,msg.sender);
    }
    
    function Move(uint256 _toID, uint256 _fromID, uint256 _i) 
    external payable {
        //must be active
        require(PSC.isActive(msg.sender));
        //must be at the location
        require(PSC.playerAtIndex(_fromID,_i) == msg.sender);
        //now get cost
        require(msg.value >= playerMoveCost);
        //now move
        PSC.movePlayer(_toID,msg.sender,_fromID,_i);
    }
    
    function changeType(uint8 _t)
    external payable{
        //must be active
        require(PSC.isActive(msg.sender));
        //must pay
        require(msg.value >= playerTypeCost);
        //make change
        PSC.setType(msg.sender, _t);
    }
}
