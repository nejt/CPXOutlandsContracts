pragma solidity ^0.4.18;

import "./Administered.sol";
import "./OwningContract.sol";
import "./Distributes.sol";
import "./CosmicCollection.sol";
import "./HeroStats.sol";

contract HeroAdmin is Administered, OwningContract, PaysBank {
    
    uint256 internal creationCost = 1 finney;
    //step percentage for cost increase
    uint256 internal creationStep = 1;
    //cost for movement
    uint256 public moveCost = 0.2 * 1 finney;
    
    function () payable public {}
    function HeroAdmin () public {}
    
    
    /*Events */
    event HeroCreated (address indexed owner, uint256 id, bytes32 meta);
    event HeroKOed (uint256 indexed _id);
    
    /* Admin functions */
    function setConstants(uint256[3] _c)
    external onlyAdmin {
        if(_c[0] != 0) creationCost = _c[0];
        if(_c[1] != 0) creationStep = _c[1];
        if(_c[2] != 0) moveCost = _c[2];
    }
    // this contract can be killed - it stores no data
    function killContract(address _stats, address _newOwner) 
    external onlyOwner {
        require(_stats != address(0) && _newOwner != address(0));
        //transfer ownership of stats to provided
        transferOCOwnership(_stats, _newOwner);
        //withdraw first
        withdraw();
        //destroy
        selfdestruct(owner);
    }
    
    /* Admin Heroes */
    //increase KO
    function KO(address _stats, uint256 _hero, uint256 _nullP, uint256 _i) 
    external onlyAdmin {
        uint256 _planeID = HeroStats(_stats).planeOf(_hero);
        //must be at location provided - ensures move
        require(HeroStats(_stats).itemAtIndex(_planeID, _i) == _hero);
        //KO hero
        HeroStats(_stats).KO(_hero, _nullP, _i);
        //log
        emit HeroKOed(_hero);
    }
    //set cooldown
    function setCooldown(address _stats, uint256 _hero, uint256 _cool) 
    external onlyAdmin {
        //set to cool
        HeroStats(_stats).setCooldown(_hero, _cool);
    }
    //set canTrain
    function setCanTrain(address _stats, uint256 _hero, bool _canTrain) 
    external onlyAdmin {
        //set to cool
        HeroStats(_stats).setCanTrain(_hero, _canTrain);
    }
    //give XP to hero
    function giveXP(address _stats, uint256 _hero, uint256 _XP) 
    external onlyAdmin {
        //give XP to hero
        HeroStats(_stats).giveXP(_hero, _XP);
    }
    
    
    /* View Functions */
    function getCurrentCost (address _stats) 
    public view returns(uint256 cost) {
        uint256 n = HeroStats(_stats).countOfHeroes();
        cost = creationCost * (100 + (creationStep * n)) / 100;
    }
    
    
    /*Core player functions */
    
    function createHero (address _token, address _stats, uint256 _planeID) 
    public payable returns (uint256 _id) {
        uint256 _cost = getCurrentCost(_stats);
        //require payment
        require(msg.value >= _cost);
        //create meta
        bytes32 meta = keccak256(_cost,msg.sender,_planeID);
        //create the token
        _id = CosmicCollectionTokens(_token).nextDeedID();
        //type 2 is hero
        CosmicCollectionTokens(_token).create(2, msg.sender);
        //createHero(uint256 _hero, bytes32 _meta, uint256 _planeID) 
        HeroStats(_stats).createHero(_id, meta, _planeID);
        //Log
        emit HeroCreated(msg.sender, _id, meta);
    }
    
    //train a hero - creates a lineage of heroes
    function trainNewHero (address _token, address _stats, uint256 _lineage) 
    public payable returns (uint256 id) {
        //require can train
        require(HeroStats(_stats).getCanTrain(_lineage));
        //require cooldown
        require(HeroStats(_stats).getCooldown(_lineage) < now);
        //current cost
        uint256 _cost = getCurrentCost(_stats);
        //require payment
        require(msg.value >= _cost);
        uint256 _planeID = HeroStats(_stats).planeOf(_lineage);
        //create meta
        bytes32 meta = keccak256(_cost,msg.sender,_planeID,_lineage);
        //create the token
        id = CosmicCollectionTokens(_token).nextDeedID();
        //type 2 is hero
        CosmicCollectionTokens(_token).create(2, msg.sender);
        //trainNewHero(uint256 _hero, bytes32 _meta, uint256 _lineage, uint256 _planeID)
        HeroStats(_stats).trainNewHero(id, meta, _lineage, _planeID);
        //Log
        emit HeroCreated(msg.sender, id, meta);
    }
    
    function moveHero (address _token, address _stats, uint256 _hero, uint256 _planeID, uint256 _fromI)
    public payable {
        //require ownership
        require(msg.sender == CosmicCollectionTokens(_token).ownerOf(_hero));
        //require past cooldown
        require(HeroStats(_stats).getCooldown(_hero) < now);
        //require payment
        require(msg.value >= moveCost);
        //moveHero(uint256 _hero, uint256 _to, uint256 _i)
        HeroStats(_stats).moveHero(_hero, _planeID, _fromI);
    }
}