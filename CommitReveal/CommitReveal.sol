pragma solidity ^0.4.18;

import "./Administered.sol";

contract CommitReveal is Administered {
    constructor() public {}
    
    bytes32[] public hash;
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    function hashIndex ()
    public view returns (uint256 i) {
        i = hash.length;
    }

    function newHash (string random) 
    public onlyAdmin {
        hash.push(keccak256(owner,hash.length,now,random));
    }
}