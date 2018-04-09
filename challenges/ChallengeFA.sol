pragma solidity ^0.4.18;

import "./Administered.sol";
import "./Distributes.sol";
import "./ReentrancyGuard.sol";

contract Stats {
    function getStats(uint256 hero, uint8 a, uint8 s, uint8 e) public view returns (uint8 ha, uint8 hs, uint8 hf);
}

contract ChallengeFA is Administered, PullToBank, ReentrancyGuard {

    struct Player {
        uint256[] heroes;
        uint256 commit; 
        uint8 successes;
        uint8 resolved;
    }

    struct Challenge {
        uint8 DC;
        uint8[] skills;
        uint8[] elements;
        uint256[2] rewards;
        bytes32 key;
        bool finalized;
        address currentWinner;
        mapping (address => Player) players;
    }
    
    //Contain all challenges
    mapping (uint256 => Challenge) internal challenges;
    //Track IDs
    uint256 internal challengeID;
    
    //contain list of rewards for player
    mapping (address => uint256[2]) internal playerRewards;
    
    //Costs
    uint256 public commitCost = 1 finney;
    
    function () public payable {}
    function ChallengeFA () public {}
    
    /*Views */
    function isOpen (uint256 id) 
    public view returns(bool open) {
        open = challenges[id].key == bytes32(0);
    }
    
    function getCoreSkill(uint256 id) 
    public view returns(uint8 skill) {
        skill = challenges[id].skills[0];
    }
    
    
    /* internal */
    function challengeWinner(uint256 id, address player, uint8 successes) 
    internal {
        if(challenges[id].currentWinner == address(0)) challenges[id].currentWinner = player;
        else {
            address cw = challenges[id].currentWinner;
            uint8 nws = challenges[id].players[cw].successes;
            
            //beats the number of successes
            if(successes > nws) challenges[id].currentWinner = player;
            else if(successes == nws) {
                uint256 when = challenges[id].players[cw].commit;
                //beats their commit
                if(challenges[id].players[player].commit < when) challenges[id].currentWinner = player;
            }
        }
    }
    
    
    /* Admin Functions */
    function setCost (uint256 cost) 
    public onlyAdmin {
        commitCost = cost;
    }
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    function createChallenge (uint8 DC, uint8[] skills, uint8[] elements, uint256[2] rewards) 
    public onlyAdmin {
        challenges[challengeID] = Challenge(DC, skills, elements, rewards, bytes32(0),false,address(0));
        //increase id
        challengeID++;
    }
    
    //sets the key for the challenge and locks it
    //no more commits 
    function setKey(uint256 id, string _key)
    public onlyAdmin {
        bytes32 key = keccak256(address(this),now,id, _key);
        challenges[id].key = key;
    }
    
    /* Public player functions*/
    
    //commit to solve - one hero per skill 
    //hero can repeat
    function commit (uint256 id, uint256[10] heroes) 
    public payable {
        //cannot have key 
        require(isOpen(id));
        //must pay
        require(msg.value >= commitCost);
        //push heroes
        challenges[id].players[msg.sender].heroes = heroes;
        challenges[id].players[msg.sender].commit = now;
    }
    
    function resolve(address stats, uint cid)
    public returns (uint8 successes, uint256[2] rewards){
        //challenge
        Challenge storage C = challenges[cid];
        //require not finalized
        require(!C.finalized && C.players[msg.sender].commit > 0);
        //hero reference
        uint256[] storage heroes = C.players[msg.sender].heroes;
        //must have commited heroes
        require(heroes.length == 10);

        //get hash for random 
        bytes32 roll = keccak256(C.key, msg.sender);
        //resolve
        successes = 0;
        
        uint8 s;
        uint8 a;
        uint8 R;
        uint8 ha;
        uint8 hs;
        uint8 hf;
        for(uint8 i = 0; i < C.skills.length; i++){
            s = C.skills[i];
            //approach
            a = uint8(C.key[i]) % 6;
            //stats
            (ha, hs, hf) = Stats(stats).getStats(heroes[s], a, s, C.elements[i]);
            //roll
            R = hf + uint8(roll[i]) % ha + uint8(roll[i+1]) % hs;
            //compare to DC
            if(R > C.DC) {
                successes++;
                //give rewards
                rewards[0] += C.rewards[0];
                rewards[1] += C.rewards[1];
            }
        }
        
        //update player rewards
        playerRewards[msg.sender][0] += rewards[0];
        playerRewards[msg.sender][1] += rewards[1];
        //update successes
        challenges[cid].players[msg.sender].successes = successes;
        
        //check for current winner
        if(successes > C.skills.length-2) challengeWinner(cid, msg.sender, successes);
    }
    
    //now mint rewards for player
    //nonReentrant
    function collectRewards() 
    public {
        //mint each
    }
}