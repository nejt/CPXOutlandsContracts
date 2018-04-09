pragma solidity ^0.4.18;

import "./CosmicCollection.sol";

contract Stats {
    function getXP(uint256 _hero) external view returns (uint256 XP);
}

contract HeroLevels {
    //constant for rarity of the level hash calculation
    uint256[31] internal levelRarity = [
      0, 
      8378469, 
      13166166, 
      15901993, 
      17465322,
      18358653,
      18869128,
      19160828,
      19327514,
      19422763,
      19477191,
      19508293,
      19526065,
      19536221,
      19542024,
      19545340,
      19547235,
      19548318,
      19548936,
      19549290,
      19549492,
      19549608,
      19549674,
      19549711,
      19549733,
      19549745,
      19549752,
      19549756,
      19549758,
      19549760,
      19549761
    ];
    uint256[21] public XPRequired = [0, 3000, 7500, 14000, 23000, 35000, 53000, 77000, 115000, 160000, 235000, 330000, 475000, 665000, 955000, 1350000, 1900000, 2700000, 3850000, 5350000, 10000000];
    
    function baseLevel(address token, uint256 hero)
    public view returns(uint8) {
        //first get hash
        bytes32 hash = CosmicCollectionTokens(token).getHash(hero);
        
        //convert first 4 of hash into number
        uint x = 0;
        for (uint i = 5; i+1 > 0; i--) {
            uint c = uint(hash[i]);
            uint to_inc = c * ( 16 ** ((5 - i-1) * 2));
            x += to_inc;
        }
        
        //base to max rarity
        x %= 19549761;
        
        //get rarity level
        for(i = 0; i < 31; i++) {
            //if it is less than the value - return the index
            if(x < levelRarity[i]) return uint8(i);
        }
    }
    
    function getLevel(uint256 XP) 
    public view returns(uint8) {
        for(uint8 i = 0; i < 20; i++) {
            //if it is less than the value - return the index
            if(XP < XPRequired[i]) return i;
        }
    }
    
    function getLevel(address token, address stats, uint256 hero) 
    public view returns(uint8 level) {
        //base level
        level = baseLevel(token, hero);
        //XP
        uint8 XPLevel = getLevel(Stats(stats).getXP(hero));
        //check which is greater
        if(XPLevel > level) level = XPLevel;
    }
}