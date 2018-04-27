pragma solidity ^0.4.18;

import "./HeroCPXStats.sol";
import "./ChallengeCPX.sol";
import "./ChallengeCPXCommit.sol";
import "./ContractLinked.sol";

contract ChallengeCPXResolve is ContractLinked {
    
    struct ChallengeData {
        bool finalized; 
        uint8 DC; 
        uint8[] skills; 
        uint8[] elements; 
        bytes32 key;
    }
    
    //rewards
    // 0 is CPX, 1 is XP
    uint256[25][2] internal rewards;
    //[15,35,55,75,100,135,175,220,285,350,460,600,775,1000,1300,1650,2200,1800,3500,4400,5400,6500,7800,9300,11000]
    //[40,60,80,120,160,240,320,480,640,960,1280,1920,2560,3840,5120,7680,10240,15360,20480,30720,40960,61440,81920,122880,163840]
    
    constructor () public {
        /* Links
        0 - Commit, Challenges, Stats
        */
        CLinks=[
            0x0,
            0xF88F5D5203A59876da02855415113aDCaadcf72b,
            0x8b04F452207240bb8caf95f4Fe699439225065eb
            ];
    }    
    
    /* Events */
    event Result (uint256 indexed challenge, address indexed player, bytes32 roll, uint8 resolved, uint8[] result, uint256[2] rewards);
    
    
    /* internal */ 
    function getResolveData (uint id)
    internal view returns (ChallengeData) {
        //challenge
        bool finalized;
        uint8 DC;
        uint8[] memory skills;
        uint8[] memory elements;
        bytes32 key;
        //get from challenge
        (finalized, DC, skills, elements, key) = ChallengeCPX(CLinks[1]).getResolveData(id);
        //return struct
        return(ChallengeData(finalized,DC,skills,elements,key));
    }
    
    
    /* Admin Only */
    function setConstants (uint8 i, uint256[25] c) 
    public {
        //admin 
        require(ChallengeCPXCommit(CLinks[0]).admins(msg.sender));
        rewards[i] = c;
    }
    
    
    /* View */
    function getRewards (uint id) 
    public view returns (uint256[2] baseReward){
        uint8 DC = ChallengeCPX(CLinks[1]).getDC(id);
        baseReward = [rewards[0][DC/5],rewards[1][DC/5]];
    }
    
    
    /* public */
    
    function resolve(uint id)
    public returns (bytes32 roll, uint8[] results, uint256[2] _rewards){
        //must be committed
        require(ChallengeCPXCommit(CLinks[0]).isPlayerCommitted(id, msg.sender));
        //not resolved
        require(!ChallengeCPXCommit(CLinks[0]).isPlayerResolved(id, msg.sender));
        
        ChallengeData memory C = getResolveData(id);
        //require not finalized
        require(!C.finalized);
        
        //hero reference
        uint256[] memory heroes = ChallengeCPXCommit(CLinks[0]).getChallengeHeroes(id, msg.sender);

        //get hash for random 
        roll = keccak256(C.key, msg.sender);
        //resolve
        uint8[] storage turns;
        uint8 step = 0;
        
        uint8[3] memory B;
        uint8 feat;

        while(turns.length < 30 || step < C.skills.length) {
            //Determine Bonus
            //getBonus(uint256 hero, uint8[3] stats) - skill, approach, element
            B = HeroCPXStats(CLinks[2]).getBonus(heroes[C.skills[step]], [C.skills[step], (uint8(C.key[step]) % 6), C.elements[step]]);
            //feat bonus - if element is present use that - greater %
            feat = B[2] > 0 ? B[2]*2 : B[1];
            //record total bonus - skill + 10*feat
            //turns always increases
            turns.push(B[0] + feat*10);

            //compare to Bonus
            // Roll Under = 50 + Bonus - DC
            if((uint8(roll[step]) % 100) + 1 < (50 + turns[step] - C.DC)) {
                //give rewards CPX, XP
                _rewards[0] += rewards[0][C.DC/5] * C.DC/turns[step];
                _rewards[1] += rewards[1][C.DC/5] * C.DC/turns[step];
                //next step
                step++;
            }
        }
        
        results = turns;

        emit Result(id, msg.sender, roll, step, turns, _rewards);
        
        //resolve(uint256 id, address player, bool success, uint8 resolved, uint8 turns, uint256[2] rewards)
        ChallengeCPXCommit(CLinks[0]).resolve(id, msg.sender, step == C.skills.length, step, uint8(turns.length), _rewards);
    }
}
