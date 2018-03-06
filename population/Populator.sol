
pragma solidity ^0.4.18;

import "./Administered.sol";
import "./CosmicCollection.sol";
import "./PlaneAdmin-0.1.0.sol";

contract PlanePopulations is Ownable {
    address PPC;
    
    /* Structures to hold population */
    //plane to array of pop ids
    mapping (uint256 => uint256[]) internal planePopulation;
    //plane to array of creature ids
    mapping (uint256 => uint256[]) internal planeCreatures;
    
    
    /*Contract Creation */
    function PlanePopulations() public {}
    
    
    /* Modifiers */
    modifier onlyBySupportContract(address _C) {
        require(msg.sender == _C);
        _;
    }
    
    
    /*View Functions */
    function getPlanePopulation(uint256 _planeID) 
    view public returns(uint256[],uint256[]) {
        return(planePopulation[_planeID],planeCreatures[_planeID]);
    }
    
    function countOfPeople(uint256 _planeID) 
    view public returns(uint256) {
        return(planePopulation[_planeID].length);
    }
    
    function countOfCreatures(uint256 _planeID) 
    view public returns(uint256) {
        return(planeCreatures[_planeID].length);
    }
    
    
    /* Admin Functions */
    //set the contract
    function setRefContract (address _PPC)
    external onlyOwner {
      PPC = _PPC;
    }
    
    
    /*Functions to add and remove population
        Only allowed by contract
    */
    
    function pushPopulation(uint256 _planeID, uint256 _popID, bool _creature) 
    external onlyBySupportContract(address(PPC)) {
        if(_creature) {planeCreatures[_planeID].push(_popID);}
        else {planePopulation[_planeID].push(_popID);}
    }
    
    function pullPopulation(uint256 _planeID, uint256 _popID, uint256 _i, bool _creature) 
    external onlyBySupportContract(address(PPC)) {
        uint256 length = 0;
        if(_creature){
            //check it is correct
            require(planeCreatures[_planeID][_i] == _popID);
            //set last to index
            length = planeCreatures[_planeID].length;
            planeCreatures[_planeID][_i] = planeCreatures[_planeID][length-1];
            //delete last
            planeCreatures[_planeID].length--;    
        }
        else {
            //check it is correct
            require(planePopulation[_planeID][_i] == _popID);
            //set last to index
            length = planePopulation[_planeID].length;
            planePopulation[_planeID][_i] = planePopulation[_planeID][length-1];
            //delete last
            planePopulation[_planeID].length--;  
        }
    }
}

contract PlanePopulator is PaysBank, Administered {
  //plane data contract
  PlaneStats PSC;
  //plane population contract
  PlanePopulations PPC;
  //requires token contract
  CosmicCollectionTokens CCT;
  //requires maker
  PlaneAdmin PAC;

  /* Data structures for population requests */

  struct Request {
    uint256 block;
    uint256 planeID;
    address requestor; 
    bool creature;
  }

  //all active requests
  Request[] public activeRequests;
  //request id
  uint256 requestID;
  
  
  event LogNewPopulation(uint256 indexed _planeID, uint256 indexed _popID, bool creature);
  
  
  /*Constants */
  uint256 creationPrice = 1/8 * 1 finney;
  
  
  /* contract Creation */
  function PlanePopulator() public {
      bank = 0x1e1a7f243df786d412fd048d7a093826db396ad9;
      PSC = PlaneStats(0x5b4d3d9602a170be47044522b7d59596388d2048);
      CCT = CosmicCollectionTokens(0x08e448a9c19a4806c988e097828fd2efce9cc58a);
      PPC = PlanePopulations(0x5afd4b9e3b088cdeed863b67e66a9a8c6d6f7b26);
      PAC = PlaneAdmin(0x9660140527c7232227b6393d548ed88ad2bdd601);
  }
  function () public payable {}
  
  
  /* View functions */
  function countActiveRequests() 
  public view returns (uint256) {
    return(activeRequests.length);
  }
  
  function currentCost(uint256 _planeID)
  public view returns (uint256 _cost) {
    //find the number of people on the plane
    uint256 cp = PPC.countOfPeople(_planeID);
    //find the multiplier - for cost and probability
    //doubles for every people count
    uint256 npm = 2 ** (1 + cp);
    //determine cost
    _cost = npm * creationPrice;
  }
  
  
  /* Admin Functions */
  function setCost(uint256 _cost) 
  external onlyAdmin {
      creationPrice = _cost;
  }
  
  //set the contract
  function setRefContract (address _PSC, address _CCT, address _PPC, address _PAC)
  external onlyAdmin {
      PSC = PlaneStats(_PSC);
      CCT = CosmicCollectionTokens(_CCT);
      PPC = PlanePopulations(_PPC);
      PAC = PlaneAdmin(_PAC);
  }
  
  //admin management
  function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    // this contract can be killed - it stores no data
    function killContract() 
    external onlyOwner {
        selfdestruct(owner);
    }
  
  //fill request pushing population 
  function fillRequest(uint256 _active, uint256 _popID) 
  external onlyAdmin {
      uint256 _planeID =activeRequests[_active].planeID;
      bool _creature = activeRequests[_active].creature;
      //push population
      PPC.pushPopulation(_planeID,_popID,_creature);
      //now kill request
      uint256 length = activeRequests.length;
      activeRequests[_active] = activeRequests[length-1];
      activeRequests.length--;
      //log
      LogNewPopulation(_planeID, _popID, _creature);
  }
  
  //pull population based upon game event
  function pullPopulation(uint256 _planeID, uint256 _popID, uint256 _i, bool _creature)
  external onlyAdmin {
      PPC.pullPopulation(_planeID,_popID,_i,_creature);
  }
  
  
  /* Public functions for users */
  function populatePersonalPlane(uint256 _planeID, bool _creature) 
  public payable {
    //must be a plane and must own it & no cooldown
    require(CCT.typeOf(_planeID) == 1 && msg.sender == CCT.ownerOf(_planeID) && PSC.cooldown(_planeID) < block.number);
    //find the number of people on the plane
    uint256 cp = PPC.countOfPeople(_planeID);
    //automatically set cooldown - 360 blocks per people count
    PAC.setCooldown(_planeID,360 * (cp + 1) * 2);
    //find the multiplier - for cost and probability
    //doubles for every people count
    uint256 npm = 2 ** (1 + cp);
    //probability of finding a new people - it is cut in half each success
    uint256 pnp = 1;
    if(npm < 10000) {
      pnp = 10000 / npm;
    }
    //pseudo random 1 to 10000
    uint random_number = uint(block.blockhash(block.number-1))%10000 + 1;
    //if less than what was determined above create request
    //use require so funds are kicked back
    require(random_number <= pnp);
    //determine cost
    uint256 _cost = npm * creationPrice;
    //require payment
    require(msg.value >= _cost);
    //create request
    activeRequests.push(Request(block.number,_planeID,msg.sender,_creature));
  }
  
  
}