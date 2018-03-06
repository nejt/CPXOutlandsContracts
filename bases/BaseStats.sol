pragma solidity ^0.4.18;

import "./Administered.sol";
import "./TracksPlaneLocation.sol";
import "./CosmicCollection.sol";

contract BaseStats is TracksPlaneLocation {
    //requires token contract
    CosmicCollectionTokens CCT;
    //requires base maker/admin contract - as lookup to allow functionality
    address BMC;
    address BAC;
    
    /* Rank and Upgrades */
    struct Base {
        uint8 rank;
        bool ruined;
        uint256[] upgrades;
        uint256 cooldown;
    }
    
    //rank mapping
    mapping (uint256 => Base) private bases;
    //mapping for plane - to track total rank without loop
    mapping (uint256 => uint256) public planeTotalRank;
    //to keep all ids
    uint256[] deedIds;


    /* Contract Creation */
    //creation
    function BaseStats() public {}
    
    
    /* Modifiers */
    modifier onlyBySupportContract(address _C) {
        require(msg.sender == _C);
        _;
    }
    
    modifier OwnerOrAdmin (uint256 _deedId) {
      require(admins[msg.sender] || msg.sender == CCT.ownerOf(_deedId));
      _;
    }
    
    /* Information View Functions */
    function countOfBases() 
    public view returns(uint256) {
        return(deedIds.length);
    }
    
    function allBases() 
    public view returns(uint256[] _bases){
        return(deedIds);
    }
    
    function rank(uint256 _baseID)
    public view returns(uint8) {
      return(bases[_baseID].rank);
    }
    
    function planeOf(uint256 _baseID)
    external view OwnerOrAdmin(_baseID) returns (uint256 _planeID) {
      //must have a rank
      require(bases[_baseID].rank != 0);
      _planeID = deedPlane[_baseID];
    }
    
    function ownerOf(uint256 _deedId)
    external view returns(address _owner) {
        return(CCT.ownerOf(_deedId));
    }
    
    //get base Information
    function getBase(uint256 _baseID)
    view public OwnerOrAdmin(_baseID) returns(uint256 _plane, uint8 _rank, bool _ruined, uint256 _cooldown, uint256[] _upgrades) {
        //if pass then give list
        _plane = deedPlane[_baseID];
        _rank = bases[_baseID].rank;
        _ruined = bases[_baseID].ruined;
        _cooldown = bases[_baseID].cooldown;
        _upgrades = bases[_baseID].upgrades;
    }
    
    
    /* admin functions */
    
    //set the contract
    function setRefContract (address _M, address _A,address _CCT)
    external onlyOwner {
        BMC = _M;
        BAC = _A;
        CCT = CosmicCollectionTokens(_CCT);
    }
    
    //initializes a base at a location - only called by the maker
    function createBase(uint256 _baseID, uint256 _planeID)
    external onlyBySupportContract(BMC) {
      //cannot already be set
      require(bases[_baseID].rank == 0);
      //store deedIds
      deedIds.push(_baseID);
      //add to deed to plane and vice versa 
      addDeedToPlane(_planeID, _baseID);
      //make the base
      bases[_baseID] = Base(1,false,new uint256[](0), 0);
      //increase rank on plane
      planeTotalRank[_planeID]++;
    }
    
    function setCooldown(uint256 _baseID,uint256 _cool)
    external onlyBySupportContract(BAC) {
        bases[_baseID].cooldown = _cool;
    }
    
    /* functions initialized by player on admin contract */
    
    //basic upgrade functionality
    function upgradeRank(uint256 _baseID) 
    external onlyBySupportContract(BAC) {
        //upgrade rank
        bases[_baseID].rank++;
        //get plane
        uint256 _planeID = deedPlane[_baseID];
        //increase rank on plane
        planeTotalRank[_planeID]++;
    }
    
    function degradeRank(uint256 _baseID) 
    external onlyBySupportContract(BAC) {
        //degrade rank
        bases[_baseID].rank--;
        //get plane
        uint256 _planeID = deedPlane[_baseID];
        //decrease rank on plane
        planeTotalRank[_planeID]--;
    }
    
    function addUpgrade(uint256 _baseID, uint256 _upgradeID)
    external onlyBySupportContract(BAC) {
        bases[_baseID].upgrades.push(_upgradeID);
    }
    
    function removeUpgrade(uint256 _baseID, uint256 _upgradeID, uint256 _index)
    external onlyBySupportContract(BAC) {
        require(bases[_baseID].upgrades[_index] == _upgradeID);
        //move last tp index
        uint256 length = bases[_baseID].upgrades.length;
        bases[_baseID].upgrades[_index] = bases[_baseID].upgrades[length-1];
        //delete last
        bases[_baseID].upgrades.length--;
    }
    
    function ruin(uint256 _baseID) 
    external onlyBySupportContract(BAC) {
        bases[_baseID].ruined = true;
    }
    
    function rebuild(uint256 _baseID) 
    external onlyBySupportContract(BAC) {
        bases[_baseID].ruined = false;
    }

}