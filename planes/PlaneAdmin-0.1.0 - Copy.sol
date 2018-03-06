pragma solidity ^0.4.18;

import "./Administered.sol";
import "./PlaneStats.sol";

// Controller contract pass through
contract PlaneAdmin is Administered {
    // support contracts
    PlaneStats PSC;
    
    /* Creation Functions */
    function PlaneAdmin () public {}
    
    /* Admin Functions */
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    //set the contract
    function setRefContracts (address _PSC)
    external onlyOwner {
        PSC = PlaneStats(_PSC);
    }
    
    // this contract can be killed - it stores no data
    function killContract() 
    external onlyOwner {
        selfdestruct(owner);
    }
    
    /* Public function called by other contracts */
    function createPersonalPlane (uint256 _deedID, bytes32 _name)
    external onlyAdmin {
        PSC.createPersonalPlane(_deedID,_name);
    }
    
    function createNetworkPlane (uint256 _deedID, uint16 _netid, string _address)
    external onlyAdmin {
        PSC.createNetworkPlane(_deedID,_netid,_address);
    }
    
    function setCooldown (uint256 _deedID, uint256 _cool)
    external onlyAdmin {
        PSC.setCooldown(_deedID,_cool);
    }
    
    function setPrivacy (uint256 _deedID, bool _pvt)
    external onlyAdmin {
        PSC.setPrivacy(_deedID,_pvt);
    }
    
    function setClosed (uint256 _deedID, bool _isClosed)
    external onlyAdmin {
        PSC.setClosed(_deedID,_isClosed);
    }
}