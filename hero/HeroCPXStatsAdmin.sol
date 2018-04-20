pragma solidity ^0.4.18;

import "./Administered.sol";
import "./Distributes.sol";
import "./ContractLinked.sol";
import "./HeroCPXStats.sol";

contract Token {
    function ownerOf(uint256 _deedId) external view returns (address _owner);
    function typeOf(uint256 _deedId) external view returns(uint16);
}

contract XPRegistry {
    mapping (uint256 => uint256) public XP;
}

contract Levels {
    uint256[21] public XPRequired;
    function getLevel(uint256 hero) public view returns(uint8 level);
}

contract CommitReveal {
    bytes32[] public hash;
    function hashIndex () public view returns (uint256 i);
}


contract HeroCPXStatsAdmin is Administered, PaysBank, OwnsLinkedContracts{
    //Track the number of available upgrades
    struct Upgrades {
        uint8 approaches;
        uint8 skills;
        uint8 feats;
    }
    //maps hero id to their upgrades
    mapping (uint256 => Upgrades) public heroUpgrades;
    
    //to get feats - they must commit
    mapping (address => uint256) public playerFeatCommit;
    
    
    /* Costs */
    uint256 public costToDrawFeats = 1 finney;
    uint256 public costToChange = 0.2 * 1 finney;
    //max element index
    uint8 maxE = 53;
    
    function () payable public {}
    function HeroCPXStatsAdmin() public {
        /* Links
        0 - Token, 1- HeroCPXStats, 2 - XPRegistry, 3 - Level, 4 - CommitReveal
        //ropsten
        CLinks[0] = 0x49dfD59BA04F81D01e51e7CD6B07f3B4F1D892F9;
        CLinks[1] = 0xd6008b35e079BF378ec19826966868e495ab7150;
        CLinks[2] = 0x13BD746d636e325E03673EBea8B35bD5003fF1c8;
        CLinks[3] = 0xe338a172C6d678458a9e8f75747D58a5A157B16F;
        CLinks[4] = 0xb810234ba133eC5E4d2702A551f2578dF1fE7156;
        */
    }
    

    /* Admin functions 
        Granting upgrades and available feats
    */
    function grantUpgrade(uint256 hero, uint8 uid, uint8 n) 
    public onlyAdmin {
        if(uid == 0) heroUpgrades[hero].approaches += n;
        else if(uid == 1) heroUpgrades[hero].skills += n;
        else if(uid == 2) heroUpgrades[hero].feats += n;
    }
    
    //grant an array of feats to an owner
    function grantAvailableFeats(address player, uint16[] feats) 
    public onlyAdmin {
        HeroCPXStats(CLinks[1]).grantAvailableFeats(player, feats);
    }
    
    //set constants
    function setConstants(uint[3] c) 
    public onlyAdmin {
        if(c[0] != 0) costToDrawFeats = c[0];
        if(c[1] != 0) costToChange = c[1];
        if(c[2] != 0) maxE = uint8(c[2]);
    }
    
    
    /* Public functions */
    
    /*Feats
        Player commit
    */ 
    function commitToDrawFeats()
    public payable {
        //there is a cost
        require(msg.value >= costToDrawFeats);
        //set commit
        playerFeatCommit[msg.sender] = CommitReveal(CLinks[4]).hashIndex();
    }
    
    //draw feats - only if commit is less than the Commit Reveal
    function drawFeats(bool element)
    public {
        //shows that they have committed
        require(playerFeatCommit[msg.sender] != 0);
        //make sure that they use a hash that they could not predict
        require(playerFeatCommit[msg.sender] < CommitReveal(CLinks[4]).hashIndex());
        //remove commit
        playerFeatCommit[msg.sender] = 0;
        //do the draw
        HeroCPXStats(CLinks[1]).drawFeats(msg.sender, CommitReveal(CLinks[4]).hash(playerFeatCommit[msg.sender]), element, maxE);
    }
    
    /* initalize */
    function initalizeHero(uint256 hero) 
    public {
        require(!HeroCPXStats(CLinks[1]).initialized(hero) && Token(CLinks[0]).typeOf(hero) == 1);
        //initalize ther hero - everyone starts at level 1
        heroUpgrades[hero] = Upgrades(24, 8, 2);
        //initialize stat
        HeroCPXStats(CLinks[1]).initalizeHero(hero, 1);
    } 
    
    // Level up - give upgrades
    function levelUp(uint256 hero)
    public {
        uint8 level = HeroCPXStats(CLinks[1]).getLevel(hero);
        //level stops at 20
        require(level < 20);
        //require that they have the XP over the next level - level 1 starts at 0
        require(XPRegistry(CLinks[2]).XP(hero) > Levels(CLinks[3]).XPRequired(level));
        //new level and skills, and feat
        heroUpgrades[hero].skills += 2;
        heroUpgrades[hero].feats++;
        //check for approaches
        if(level+1 % 4 == 0) heroUpgrades[hero].approaches += 2;
        //Level up
        HeroCPXStats(CLinks[1]).levelUp(hero);
    }
    
    //Upgrade skills and approaches
    function Upgrade (uint256 hero, uint8[] ids) 
    public {
        //must own hero
        require(msg.sender == Token(CLinks[0]).ownerOf(hero));
        uint8 _l = uint8(ids.length);
        uint8 _n;
        for(uint8 i = 0; i < _l; i++) _n += ids[i];
        //check they can upgrade
        uint8 what = _l == 6 ? heroUpgrades[hero].approaches : heroUpgrades[hero].skills;
        require(what >= _n);
        //reduce upgrades
        if(_l == 6) heroUpgrades[hero].approaches -= _n;
        else heroUpgrades[hero].skills -= _n;
        //upgrade
        HeroCPXStats(CLinks[1]).Upgrade(hero, ids);
    } 
    
    function switchSkill  (uint256 hero, uint8 _old, uint8 _new) 
    public payable {
        require(msg.value >= costToChange);
        //must own hero
        require(msg.sender == Token(CLinks[0]).ownerOf(hero));
        //switch
        HeroCPXStats(CLinks[1]).switchSkill(hero,_old,_new);
    }
    
    function addFeat (uint256 hero, uint16 feat) 
    public  {
        //must own hero
        require(msg.sender == Token(CLinks[0]).ownerOf(hero));
        //must have upgrades
        require(heroUpgrades[hero].feats > 0);
        //must have feat
        require(HeroCPXStats(CLinks[1]).getCountOfAvailableFeats(msg.sender, feat) > 0);
        //reduce upgrades
        heroUpgrades[hero].feats--;
        //add feat
        HeroCPXStats(CLinks[1]).addFeat(msg.sender, hero, feat);
    }
    
    function switchFeat  (uint256 hero, uint8 i, uint16 feat) 
    public payable {
        require(msg.value >= costToChange);
        //must own hero
        require(msg.sender == Token(CLinks[0]).ownerOf(hero));
        //must have feat
        require(HeroCPXStats(CLinks[1]).getCountOfAvailableFeats(msg.sender, feat) > 0);
        //switch
        HeroCPXStats(CLinks[1]).switchFeat(msg.sender, hero, i, feat);
    }
    
}
