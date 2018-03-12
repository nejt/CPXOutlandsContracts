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
    uint256 private nullPlane = 999999;
    
    /* Contract creation */
    function PlayerManager() public {
        bank = 0x1e1a7f243df786d412fd048d7a093826db396ad9;
        PSC = PlayerStats(0x237bfb19ceb5c004a454b378adc37f205be05ae9);
    }
    function () public payable {}
    
    /*events */
    event LogNewPlayer(address _player);
    
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
    
    function setNullPlane(uint256 _null)
    external onlyAdmin {
        nullPlane = _null;
    }
    
    // this contract can be killed - it stores no data
    function killContract() 
    external onlyOwner {
        selfdestruct(bank);
    }
    
    
    /*internal control of PlayerStats*/ 
    //allow admin movement
    function adminMovePlayer(uint256 _toID, address _player, uint256 _fromID, uint256 _i)
    external onlyAdmin {
        //must be at the location
        require(PSC.playerAtIndex(_fromID,_i) == msg.sender);
        PSC.movePlayer(_toID,_player,_fromID,_i);
    }
    
    //increase KO
    function KO(address _player, uint256 _fromIndex)
    external onlyAdmin {
        //increase KO 
        PSC.KO(_player, nullPlane, _fromIndex);
    }
    
    //set cooldown
    function setCooldown(address _player, uint256 _cool)
    external onlyAdmin {
        PSC.setCooldown(_player, _cool);
    }
    
    
    /* External functions for players */
    function Activate(uint8 _c, uint256 _planeID, string _text) 
    external {
        //cannot be active
        require(!PSC.isActive(msg.sender));
        //activate
        PSC.Activate(msg.sender, _text);
        //set type
        PSC.setClass(msg.sender,_c);
        //set initial location
        PSC.movePlayer(_planeID,msg.sender);
        //log
        LogNewPlayer(msg.sender);
    }
    
    function Move(uint256 _toID, uint256 _fromID, uint256 _i) 
    external payable {
        //must be active & check cooldown 
        require(PSC.isActive(msg.sender) && PSC.getCooldown(msg.sender) < now);
        //must be at the location
        require(PSC.playerAtIndex(_fromID,_i) == msg.sender);
        //now get cost
        require(msg.value >= playerMoveCost);
        //now move
        PSC.movePlayer(_toID,msg.sender,_fromID,_i);
    }
    
    function changeClass(uint8 _c)
    external payable{
        //must be active & check cooldown 
        require(PSC.isActive(msg.sender) && PSC.getCooldown(msg.sender) < now);
        //must pay
        require(msg.value >= playerTypeCost);
        //make change
        PSC.setClass(msg.sender, _c);
    }
}
