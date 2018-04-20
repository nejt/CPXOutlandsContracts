pragma solidity ^0.4.18;

import "./Administered.sol";

contract Cooldown is Administered{
    /* Tracks the cooldown given to a Token */
    mapping (uint256 => uint256) public cooldown;
    
    constructor() public {}
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    //admins may set the XP - meant to be called by the XP handler
    function setCooldown(uint256 id, uint256 cool) 
    public onlyAdmin {
        cooldown[id] = cool;
    }
}