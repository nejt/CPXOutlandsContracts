pragma solidity ^0.4.18;

import "./Ownable.sol";

contract CommitReveal is Ownable {
    function CommitReveal() public {}
    
    bytes32[] public hash;
    
    function hashIndex ()
    public view returns (uint256 i) {
        i = hash.length;
    }

    function newHash (string random) 
    public onlyOwner {
        hash.push(keccak256(owner,hash.length,now,random));
    }
}