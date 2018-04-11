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
        bool initialized;
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
    //OR 500 + (skill * 100 + element)
    struct Feat {
        uint16[] all;
        //internal mapping for quick lookup
        mapping(uint16 => bool) isPresent;    
    }
    //feats
    mapping (uint256 => Feat) internal heroFeats;
    
    //available feats for player
    mapping (address => mapping(uint16 => uint8)) public availableFeats;
    
    
    function HeroFAStats() public {}
    
    /* Admin Only*/

    
    /* View functions */
    function isInitialized(uint256 hero) 
    public view returns (bool initialized) {
        initialized = heroUpgrades[hero].initialized;
    }
    
    function getHero(uint256 hero) 
    public view returns (uint8[6] approaches, uint8[10] skills, uint16[] feats) {
        approaches = heroApproaches[hero];
        skills = heroSkills[hero];
        feats = heroFeats[hero].all;
    }
    
    function hasFeat(uint256 hero, uint16 feat) 
    public view returns (bool isPresent) {
        isPresent = heroFeats[hero].isPresent[feat];
    }
    
    function getStats(uint256 hero, uint8 a, uint8 s, uint8 e) 
    public view returns (uint8[3] B) {
        B[0] = heroApproaches[hero][a];
        B[1] = heroSkills[hero][s];
        B[2] = 0;

        //feat id
        uint16 fa = s*10 + a;
        uint16 fe = 1000 + (s*100 + e);
        
        //check for element feat
        if(heroFeats[hero].isPresent[fe]) B[2] = 2;
        else if (heroFeats[hero].isPresent[fa]) B[2] = 3;
    }
    
    /* Public functions */
    function grantUpgrade(uint256 hero, uint8 uid, uint8 n) 
    public onlyOwner {
        if(uid == 0) heroUpgrades[hero].approaches += n;
        else if(uid == 1) heroUpgrades[hero].skills += n;
        else if(uid == 2) heroUpgrades[hero].feats += n;
        else if(uid == 3) heroUpgrades[hero].canSwitchFeat = true;
        else if(uid == 4) heroUpgrades[hero].canSwitchSkill = true;
    }
    
    //grant an array of feats to an owner
    function grantAvailableFeats(address player, uint16[] feats) 
    public onlyOwner {
        for(uint8 i = 0; i < feats.length; i++){
            availableFeats[player][feats[i]]++;
        }
    }
    
    function initalizeHero(address token, address stats, address _level, uint256 hero) 
    public onlyOwner {
        require(!heroUpgrades[hero].initialized);
        //get level
        uint8 level = Levels(_level).getLevel(token,stats,hero);
        //calculate upgrades
        uint8 approaches = 24 + (level/4) * 2;
        uint8 skills = 1 + level;
        uint8 feats = 1 + level;
        //initalize ther hero by giving upgrades
        heroUpgrades[hero] = Upgrades(approaches,skills,feats,true,level,false,false);
    } 
    
    function LevelUp(address stats, address _level, uint256 hero)
    public onlyOwner {
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
    
    function upgradeSkills (uint256 hero, uint8[] ids) 
    public onlyOwner {
        //loop through upgrades 
        for(uint8 i = 0; i < ids.length; i++) {
            //reduce upgrade count
            heroUpgrades[hero].skills--;
            //upgrade
            heroSkills[hero][ids[i]]++;
        }
    } 
    
    function upgradeApproaches (uint256 hero, uint8[] ids) 
    public onlyOwner {
        //loop through upgrades 
        for(uint8 i = 0; i < ids.length; i++) {
            //reduce upgrade count
            heroUpgrades[hero].approaches--;
            //upgrade
            heroApproaches[hero][ids[i]]++;
        }
    } 
    
    function switchSkill  (uint256 hero, uint8 _old, uint8 _new) 
    public onlyOwner {
        //decrement
        heroSkills[hero][_old]--;
        //increase
        heroSkills[hero][_new]++;
    }
    
    function addFeat (address player, uint256 hero, uint16 feat) 
    public onlyOwner {
        //reduce upgrades
        heroUpgrades[hero].feats--;
        //reduce available
        availableFeats[player][feat]--;
        //push to hero
        heroFeats[hero].all.push(feat);
        heroFeats[hero].isPresent[feat] = true;
    }
    
    function switchFeat  (address player, uint256 hero, uint8 i, uint16 feat) 
    public onlyOwner {
        //switch id
        uint16 switchid = heroFeats[hero].all[i];
        heroFeats[hero].isPresent[switchid] = false;
        //increase available
        availableFeats[player][switchid]++;
        //reduce available
        availableFeats[player][feat]--;
        //push to hero
        heroFeats[hero].all[i] = feat;
        heroFeats[hero].isPresent[feat] = true;
    }
    
}
