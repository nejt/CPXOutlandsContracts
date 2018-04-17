pragma solidity ^0.4.18;

import "./Ownable.sol";

contract HeroCPXStats is Ownable {
    //mapping to track which heroes have initialized data
    mapping (uint256 => bool) public initialized;

    struct Data {
      uint8[6] approaches;
      uint8[10] skills;
      uint8 level;
    }
    mapping (uint256 => Data) internal heroCPX;
    
    //feats 
    struct Feat {
        uint16[] all;
        //internal mapping for quick lookup
        mapping(uint16 => bool) isPresent;    
    }
    //feats
    mapping (uint256 => Feat) internal heroFeats;
    
    //available feats for player
    mapping (address => mapping(uint16 => uint8)) availableFeats;
    
    
    /* Events */
    event FeatsGiven (address indexed player, uint16[] feats);
    
    function HeroCPXStats () public {}
    
    
    /* View functions */
    function getLevel(uint256 hero)
    public view returns (uint8 level) {
        level = heroCPX[hero].level;
    }
    
    function getHero(uint256 hero)
    public view returns (uint8[6] approaches, uint8[10] skills, uint16[] feats){
        approaches = heroCPX[hero].approaches;
        skills = heroCPX[hero].skills;
        feats = heroFeats[hero].all;
    }
    
    function getFeats(uint256 hero)
    public view returns (uint16[] feats) {
        feats = heroFeats[hero].all;
    }
    
    function getCountOfAvailableFeats(address player, uint16 feat)
    public view returns (uint8 count){
        count = availableFeats[player][feat];
    }
    
    function hasFeat(uint256 hero, uint16 feat) 
    public view returns (bool isPresent) {
        isPresent = heroFeats[hero].isPresent[feat];
    }
    
    function getBonus(uint256 hero, uint8[3] stats) 
    public view returns (uint8[4] B) {
        B[0] = heroCPX[hero].approaches[stats[0]];
        B[1] = heroCPX[hero].skills[stats[1]];
        
        //for approach feats it is 10 * skill + approach
        uint16 fa = (stats[1] * 10) + stats[0];
        //for element feats it is 200 + 100 * skill + element
        uint16 fe = 200 + (stats[1] * 100) + stats[2];

        //check for feats
        if(heroFeats[hero].isPresent[fa]) B[2] = 1;
        else if (heroFeats[hero].isPresent[fe]) B[3] = 1;
    }
    
    
    /* Public functions */
    function grantAvailableFeats(address player, uint16[] feats) 
    public onlyOwner {
        for(uint8 i = 0; i < feats.length; i++){
            //update
            availableFeats[player][feats[i]]++;
        }
        
        FeatsGiven(player, feats);
    }
    
    //draw feats - only if commit is less than the Commit Reveal
    function drawFeats(address player, bytes32 hash, bool element, uint8 maxe)
    public onlyOwner returns(uint16[] memory given, bytes32 _hash){
        //calculate hash
        _hash = keccak256(address(this), hash, msg.sender);
        given = new uint16[](15);
        uint16 feat;
        uint16 s;
        uint16 a;
        uint16 e;
        uint8 p;
        
        for(uint8 i = 0; i < 15; i++){
            p = 2*i;
            //for element feats it is 200 + 100 * skill + element
            //for approach feats it is 10 * skill + approach
            s = uint8(_hash[p]) % 10;
            a = uint8(_hash[p+1]) % 6;
            e = uint8(_hash[p+1]) % maxe;
            
            if(element) feat = e + 200 + (s*100);
            else feat = ((s*10) + a); 
            given[i] = feat;
            
            //now grant feat
            availableFeats[player][feat]++;
        }
        
        FeatsGiven(player, given);
    }
    
    function initalizeHero(uint256 hero, uint8 level) 
    public onlyOwner {
        initialized[hero] = true;
        heroCPX[hero].level = level;
    }
    
    function levelUp(uint256 hero)
    public onlyOwner {
        heroCPX[hero].level++;
    }
    
    function Upgrade (uint256 hero, uint8[] ids) 
    public onlyOwner {
        uint8 _l = uint8(ids.length);
        
        //loop through upgrades
        uint8 i = 0;
        if(_l == 6) {
            for(i; i < _l; i++) {
                heroCPX[hero].approaches[i] += ids[i];
            }
        }
        else {
            for(i; i < _l; i++) {
                heroCPX[hero].skills[i] += ids[i];
            }
        }
    }
    
    function switchSkill  (uint256 hero, uint8 _old, uint8 _new) 
    public onlyOwner {
        //decrement
        heroCPX[hero].skills[_old]--;
        //increase
        heroCPX[hero].skills[_new]++;
    }
    
    function addFeat (address player, uint256 hero, uint16 feat) 
    public onlyOwner {
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
        availableFeats[msg.sender][switchid]++;
        //reduce available
        availableFeats[player][feat]--;
        //put in old index 
        heroFeats[hero].all[i] = feat;
        //add feat
        heroFeats[hero].isPresent[feat] = true;
    }
}