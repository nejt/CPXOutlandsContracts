pragma solidity ^0.4.18;

import "./Ownable.sol";

contract OwnedContract {
    function transferOwnership(address newOwner) public;
}

contract OwningContract is Ownable{
    function OwningContract () public {}
    
    function transferOCOwnership(address _contract, address _newOwner) 
    public onlyOwner {
        OwnedContract(_contract).transferOwnership(_newOwner);
    }
}