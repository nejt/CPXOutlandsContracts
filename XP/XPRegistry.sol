pragma solidity ^0.4.18;

import "./Administered.sol";

contract XPRegistry is Administered{
    /* Tracks the XP given to a Token */
    mapping (uint256 => uint256) public XP;
    
    function XPRegistry() public {}
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    //admins may set the XP - meant to be called by the XP handler
    function giveXP(uint256 id, uint256 _xp) 
    public onlyAdmin {
        XP[id] += _xp;
    }
}