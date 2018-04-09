pragma solidity ^0.4.18;

import "./Ownable.sol";

contract Token {
    function ownerOf(uint256 _deedId) external view returns (address _owner);
}

contract Stats {
    function getXP(uint256 _hero) external view returns (uint256 XP);
}

contract Levels {
    uint256[21] public XPRequired;
    function getLevel(address token, address stats, uint256 hero) public view returns(uint8 level);
}

contract HeroFAStats is Ownable{
    // skills = 2 + level
    // approaches = 24 + 2 * (level / 4)
    
    //Track the number of available upgrades
    struct Upgrades {
        uint8 approaches;
        uint8 skills;
        uint8 feats;
        bool intialized;
        uint8 level;
        bool canSwitchFeat;
        bool canSwitchSkill;
    }
    //maps hero id to their upgrades
    mapping (uint256 => Upgrades) public heroUpgrades;
    
    //Use mappings for arrays to reduce memory overhead
    //approaches start at 0 - but that is equivalent to 8
    mapping (uint256 => uint8[6]) internal heroApproaches;
    //skills 
    mapping (uint256 => uint8[10]) internal heroSkills;
    //feats 
    //skill * 10 + approach
    //OR 1000 + (skill * 100 + element)
    struct Feat {
        uint16[] all;
        //internal mapping for quick lookup
        mapping(uint16 => bool) isPresent;    
    }
    //feats
    mapping (uint256 => Feat) internal heroFeats;
    
    function HeroFAStats() public {}
    
    /* Admin Only*/

    
    /* View functions */
    function getHero(address token, uint256 hero) 
    public view returns (uint8[6] approaches, uint8[10] skills,uint16[] feats) {
        //must own hero
        require(msg.sender == Token(token).ownerOf(hero));
        approaches = heroApproaches[hero];
        skills = heroSkills[hero];
        feats = heroFeats[hero].all;
    }
    
    function getStats(uint256 hero, uint8 a, uint8 s, uint8 e) 
    public view returns (uint8 ha, uint8 hs, uint8 hf) {
        hs = 4 + heroSkills[hero][s]*2;
        ha = 2 + heroApproaches[hero][a];
        hf = 0;
        //feat id
        uint16 fa = s*10 + a;
        uint16 fe = 1000 + (s*100 + e);
        
        //check for element feat
        if(heroFeats[hero].isPresent[fe]) hf = 6;
        else if (heroFeats[hero].isPresent[fa]) hf = 3;
    }
    
    /* Public functions */
    
    function initalizeHero(address token, address stats, address _level, uint256 hero) 
    public {
        //must own hero
        require(msg.sender == Token(token).ownerOf(hero));
        require(!heroUpgrades[hero].intialized);
        //get level
        uint8 level = Levels(_level).getLevel(token,stats,hero);
        //calculate upgrades
        uint8 approaches = 24 + (level/4) * 2;
        uint8 skills = 1 + level;
        uint8 feats = 1 + level;
        //initalize ther hero by giving upgrades
        heroUpgrades[hero] = Upgrades(approaches,skills,feats,true,level,false,false);
    } 
    
    function LevelUp(address token, address stats, address _level, uint256 hero)
    public {
        //must own hero
        require(msg.sender == Token(token).ownerOf(hero));
        //level stops at 20
        require(heroUpgrades[hero].level < 20);
        //require that they have the XP over the next level - level 1 starts at 0
        require(Stats(stats).getXP(hero) > Levels(_level).XPRequired(heroUpgrades[hero].level));
        //new level and skills, and feat
        heroUpgrades[hero].level++;
        heroUpgrades[hero].skills++;
        heroUpgrades[hero].feats++;
        //you can mod now
        heroUpgrades[hero].canSwitchFeat = true;
        heroUpgrades[hero].canSwitchSkill = true;
        //check for approaches
        if(heroUpgrades[hero].level % 4 == 0) heroUpgrades[hero].approaches += 2;
    }
    
    function upgradeSkills (address token, uint256 hero, uint8[] ids) 
    public {
        uint8 nupgrades = uint8(ids.length);
        //no more than 10 at a time
        require(nupgrades <= 10);
        //must own hero
        require(msg.sender == Token(token).ownerOf(hero));
        //check they can upgrade
        require(heroUpgrades[hero].skills >= nupgrades);
        //get max - skill rank must be less than 2 + level/4
        //uint8 max = 2 + (heroUpgrades[hero].level / 4);
        //loop through upgrades 
        for(uint8 i = 0; i < nupgrades; i++) {
            //reduce upgrade count
            heroUpgrades[hero].skills--;
            //upgrade
            heroSkills[hero][ids[i]]++;
        }
    } 
    
    function upgradeApproaches (address token, uint256 hero, uint8[] ids) 
    public {
        uint8 nupgrades = uint8(ids.length);
        //no more than 10 at a time
        require(nupgrades <= 10);
        //must own hero
        require(msg.sender == Token(token).ownerOf(hero));
        //check they can upgrade
        require(heroUpgrades[hero].approaches >= nupgrades);
        //loop through upgrades 
        for(uint8 i = 0; i < nupgrades; i++) {
            //approach rank must be less 20 which is 12 because 0 = 8
            //require(heroApproaches[hero][ids[i]] <= 12);
            //reduce upgrade count
            heroUpgrades[hero].approaches--;
            //upgrade
            heroApproaches[hero][ids[i]]++;
        }
    } 
    
    function addFeat (address token, uint256 hero, uint8 skill, uint8 aore, bool element) 
    public {
        //must own hero
        require(msg.sender == Token(token).ownerOf(hero));
        //create feat id
        //skill * 10 + approach
        //OR 1000 + (skill * 100 + element)
        uint16 id = element ? 1000 + (skill*100 + aore) : skill*10 + aore;
        //push to hero
        heroFeats[hero].all.push(id);
        heroFeats[hero].isPresent[id] = true;
    }
    
    function switchSkill  (address token, uint256 hero, uint8 _old, uint8 _new) 
    public {
        //must own hero
        require(msg.sender == Token(token).ownerOf(hero));
        //require switch
        require(heroUpgrades[hero].canSwitchSkill);
        heroUpgrades[hero].canSwitchSkill = false;
        //decrement
        heroSkills[hero][_old]--;
        //increase
        heroSkills[hero][_new]++;
    }
    
    function switchFeat  (address token, uint256 hero, uint8 i, uint8 skill, uint8 aore, bool element) 
    public {
        //must own hero
        require(msg.sender == Token(token).ownerOf(hero));
        //require switch
        require(heroUpgrades[hero].canSwitchFeat);
        heroUpgrades[hero].canSwitchFeat = false;
        //switch id
        uint16 switchid = heroFeats[hero].all[i];
        heroFeats[hero].isPresent[switchid] = false;
        //new id
        uint16 id = element ? 1000 + (skill*100 + aore) : skill*10 + aore;
        heroFeats[hero].all[i] = id;
        heroFeats[hero].isPresent[id] = true;
    }
}
