pragma solidity ^0.4.20;

import './ContractLinked.sol';

contract PaysBank is ContractLinked {

    event LogWithdraw(uint256 block, address who);

    constructor() public {
        //make sure money can be recovered
        CLinks = [msg.sender];
    }
    
    //withdraw
    function withdraw() 
    public onlyOwner {
        //bank contract has to be set
        require(CLinks[0] != address(0));
        CLinks[0].transfer(address(this).balance);
        emit LogWithdraw(block.number,msg.sender);
    }
}