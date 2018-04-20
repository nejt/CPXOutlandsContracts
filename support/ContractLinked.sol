pragma solidity ^0.4.18;

import "./Ownable.sol";

contract Owned {
    function transferOwnership(address newOwner) public;
}

contract ContractLinked is Ownable {
    address[] public CLinks;
    
    function ContractLinked () public {}
    
    function setContractLinks(address[] links)
    public onlyOwner{
        CLinks = links;
    }
    
    function setContractLinks(uint8 i, address link)
    public onlyOwner{
        CLinks[i] = link;
    }
}

contract OwnsLinkedContracts is ContractLinked {

    function OwnsLinkedContracts () public {}
    
    function setOwnedContractLinks(uint8 cli, address[] links)
    public onlyOwner{
        ContractLinked(CLinks[cli]).setContractLinks(links);
    }
    
    function transferOwnedOwnership(uint8 cli, address newOwner) 
    onlyOwner public {
        require(newOwner != address(0));
        Owned(CLinks[cli]).transferOwnership(newOwner);
    }
}