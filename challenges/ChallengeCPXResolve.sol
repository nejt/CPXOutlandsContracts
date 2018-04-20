pragma solidity ^0.4.18;

import "./ChallengeCPXAdmin.sol";
import "./Ownable.sol";

contract ChallengeCPXResolve is Ownable {
    /* Events */
    event Result (uint256 indexed challenge, address indexed player, uint8[] result, uint256[2] rewards);
    function resolve(uint id)
    public returns (bytes32 roll, uint8[] results, uint256[2] rewards){
        //challenge
        Challenge storage C = ChallengeCPX(CLinks[1]).getChallengeData(id);
        //require not finalized
        require(!C.finalized && C.players[msg.sender].commit > 0);
        //require not resolved
        require(!C.players[msg.sender].resolved);
        //set resolve
        C.players[msg.sender].resolved = true;
        //hero reference
        uint256[] storage heroes = C.players[msg.sender].heroes;

        //get hash for random 
        roll = keccak256(C.key, msg.sender);
        //resolve
        uint8[] storage turns;
        uint8 steps = 0;
        
        uint8[4] memory B;
        uint8 _B;
        uint8 feat;
        uint8 R;
        uint8 DCMod;
        
        while(turns.length < 30 || steps < C.skills.length) {
            //Determine Bonus
            //hero id, stats = approach, skill, element
            B = Stats(CLinks[2]).getBonus(heroes[C.skills[steps]], [(uint8(C.key[steps]) % 6),C.skills[steps],C.elements[steps]]);
            //feat bonus - if element is present use that - greater %
            feat = B[3] > 0 ? B[3]*2 : B[2];
            //total bonus - 2*approach + 5*skill + 10*feat
            _B = B[0]*2 + B[1]*5 + feat*10;
            //turns always increases
            turns.push(_B);
            //if DC is less - no mod - if greater - subtract difference
            DCMod = C.DC < _B ? 0 : DCMod - _B;
            //percentage roll
            R = (uint8(roll[steps]) % 100) + 1;
            
            //compare to Bonus
            if(R < (_B - DCMod)) {
                //next step
                steps++;
                //give rewards
                rewards[0] += C.rewards[0] * R/_B;
                rewards[1] += C.rewards[1] * R/_B;
            }
        }
        
        results = turns;

        
        
        //update turns if completed the Challenge
        if(steps == C.skills.length-1) {
            C.players[msg.sender].turns = uint8(turns.length);
            //determine if challengeWinner
            challengeWinner(id, msg.sender, uint8(turns.length), C.players[msg.sender].commit);
        }
        
        emit Result(id, msg.sender, results, rewards);
    }
}
