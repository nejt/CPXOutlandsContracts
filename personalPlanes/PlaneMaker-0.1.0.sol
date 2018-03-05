pragma solidity ^0.4.18;

import "./PersonalPlanes-0.6.0.sol";
import "./BaseMaker-0.1.0.sol";

/*  @dev Contract handles creation of planes
*/
contract PlaneMaker is PaysBank, Administered{
    //requires planes contract
    CPXPersonalPlanes PPC;
    //requires base maker
    BaseMaker CB;

    /* Variables in control of owner */
  
    // The contract owner can change the initial price of deeds at Creation.
    uint256 private creationPrice = 1 finney;
    uint256 private percentStep = 5;

    /* Owner Functions */
    
    //set the contract
    function setRefContracts (address _P, address _B)
    external onlyOwner {
        PPC = CPXPersonalPlanes(_P);
        CB = BaseMaker(_B);
    }
    
    //set constants
    function setConstants(uint[2] _cost) 
    external onlyOwner {
        creationPrice = _cost[0];
        percentStep = _cost[1];
    }
    
    /* Creation Functions */
    
    function currentCost() 
    view public returns (uint reg) {
        uint mod = PPC.countOfDeeds() * percentStep;
        reg = creationPrice*(100+mod)/100;
    }
    
    function create(string _name) 
    public payable {
      //pull currentCost
      uint256 _cost = currentCost();
      //must be paid
      require(msg.value >= _cost);
      //get a name based on hash
      bytes32 hash = keccak256(_cost,msg.sender,_name);
      //if so create the plane
      PPC.create(hash, msg.sender, _cost);
      //create the base
      CB.adminSetBase(hash,msg.sender);
    }
}