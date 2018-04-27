pragma solidity ^0.4.18;

import "./Administered.sol";
import "./ContractLinked.sol";
import "./CosmicExperiencePoints.sol";

contract XPRegistry is Administered, ContractLinked{
    /* Tracks the XP given to a Token */
    mapping (uint256 => uint256) public XP;
    
    constructor() public {
        // Links - 0 CXP
        CLinks = [0xFD90bf0c7758F98269d59Dd908771f874C9A17f6];
    }
    
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
    
    function transferXP(uint256 id, uint256 _xp) 
    public {
        CosmicExperiencePoints CXP = CosmicExperiencePoints(CLinks[0]);
        //check for CPX allowance
        uint256 allowance = CXP.allowance(msg.sender,address(this));
        //require payment - CPX or msg
        require(allowance >= _xp);
        //if allowance - take and burn
        if(CXP.transferFrom(msg.sender, address(this), _xp)) {
            //burn
            CXP.transfer(address(0), _xp);
            //give to token
            XP[id] += _xp;
        }
    }
}