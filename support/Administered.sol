pragma solidity ^0.4.20;

import "./Ownable.sol";

contract Administered is Ownable {
    mapping (address => bool) public admins;
    
    function Administered() public { 
        admins[owner] = true;
    }
    
    //modifier to be used by inhereted contracts
    //only allows those in the admin or super list to do work
    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }
    
    function setAdmin (address _admin, bool isAdmin) public onlyAdmin {
        admins[_admin] = isAdmin;
    }
    
}