pragma solidity ^0.4.18;

import "./Administered.sol";
import "./Distributes.sol";
import "./ReentrancyGuard.sol";
import "./ContractLinked.sol";

contract Token {
    function ownerOf(uint256 _deedId) external view returns (address _owner);
    function typeOf(uint256 _deedId) external view returns(uint16);
}

contract Stats {
    function getBonus(uint256 hero, uint8[3] stats) public view returns (uint8[4] B);
}

contract HeroLocation{
    function planeOf(uint256 _itemID) external view returns (uint256 _planeID);
}

contract Mint {
    function mintToken(address token, address tokenOwner, uint256 amount) external;
}

contract ChallengeCPX is Administered, PullToBank, ReentrancyGuard, ContractLinked {

    struct Player {
        uint256[] heroes;
        uint256 commit; 
        uint8 turns;
        bool resolved;
    }

    struct Challenge {
        uint256 plane;
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
    uint256[] public openChallenges;
    //Track IDs
    uint256 internal challengeID;
    //watch commits 
    mapping (uint256 => uint256) internal challengeCommits;
    
    //contain list of rewards for player
    mapping (address => uint256[2]) internal playerRewards;
    
    //Costs
    uint256 public commitCost = 1 finney;
    
    /* Events */
    event Result (uint256 indexed challenge, address indexed player, uint8[] result, uint256[2] rewards);
    
    
    function () public payable {}
    function ChallengeCPX () public {
        /* 
        0 - token, 1 location, 2 Stats, 3 mint, 4 CPX, 5 XP
        */
    }
    
    /*Views */

    function getChallengeData (uint256 id) 
    public view returns(uint256 plane, uint8 DC, uint8[] skills, uint8[] elements, uint256[2] rewards, bytes32 key, address currentWinner) {
        plane = challenges[id].plane;
        DC = challenges[id].DC;
        skills = challenges[id].skills;
        elements = challenges[id].elements;
        rewards = challenges[id].rewards;
        key = challenges[id].key;
        currentWinner = challenges[id].currentWinner;
    }
    
    function isFinalized (uint256 id) 
    public view returns(bool finalized) {
        finalized = challenges[id].finalized;
    }
    
    function isOpen (uint256 id) 
    public view returns(bool open) {
        open = challenges[id].key == bytes32(0);
    }
    
    
    /* internal */
    function challengeWinner(uint256 id, address player, uint8 turns, uint256 commit) 
    internal {
        if(challenges[id].currentWinner == address(0)) challenges[id].currentWinner = player;
        else {
            address cw = challenges[id].currentWinner;
            uint8 nwt = challenges[id].players[cw].turns;
            
            //beats the number of successes
            if(turns < nwt) challenges[id].currentWinner = player;
            else if(turns == nwt) {
                uint256 when = challenges[id].players[cw].commit;
                //beats their commit
                if(commit < when) challenges[id].currentWinner = player;
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
    
    function createChallenge (uint8 DC, uint8 skill, uint256 plane) 
    public onlyAdmin {
        challenges[challengeID].DC = DC;
        challenges[challengeID].skills.push(skill);
        challenges[challengeID].plane = plane;
        //push to open
        openChallenges.push(challengeID);
        //increase id
        challengeID++;
    }
    
    //sets the key for the challenge and locks it
    //no more commits 
    function setKey(uint256 id, uint8[] skills, uint8[] elements, uint256[2] rewards, string _key)
    public onlyAdmin {
        //create key
        bytes32 key = keccak256(address(this),now,id, _key);
        //set skills, elements, rewards, key
        challenges[id].skills = skills;
        challenges[id].elements = elements;
        challenges[id].rewards = rewards;
        challenges[id].key = key;
    }
    
    //finalize the challenge - no more resolution - declares winner
    //id of challenge, and index to remove
    function finalizeChallenge(uint256 id, uint256 i)
    public onlyAdmin {
        challenges[id].finalized = true;
        //get length
        uint256 l = openChallenges.length;
        //move last to index
        openChallenges[i] = openChallenges[l-1];
        //delete last
        openChallenges.length--;
        //calculate profit split
        uint256 split = challengeCommits[id] / 2;
        //push half to bank
        asyncSend(bank, split);
        //push half to winner
        asyncSend(challenges[id].currentWinner, split);
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
        //pull plane for reference
        uint256 plane = challenges[id].plane;
        for(uint8 i = 0; i < 10; i++){
            //must be heroes and must own them
            require(Token(CLinks[0]).typeOf(heroes[i]) == 1 && msg.sender == Token(CLinks[0]).ownerOf(heroes[i]));
            //must be on the plane
            require(plane == HeroLocation(CLinks[1]).planeOf(heroes[i]));
        }
        challengeCommits[id] += msg.value;
        //commit
        challenges[id].players[msg.sender].commit = now;
        //push heroes
        challenges[id].players[msg.sender].heroes = heroes;
    }
    
    function resolve(uint cid)
    public returns (bytes32 roll, uint8[] results, uint256[2] rewards){
        //challenge
        Challenge storage C = challenges[cid];
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

        //update player rewards
        playerRewards[msg.sender][0] += rewards[0];
        playerRewards[msg.sender][1] += rewards[1];
        
        //update turns if completed the Challenge
        if(steps == C.skills.length-1) {
            C.players[msg.sender].turns = uint8(turns.length);
            //determine if challengeWinner
            challengeWinner(cid, msg.sender, uint8(turns.length), C.players[msg.sender].commit);
        }
        
        emit Result(cid, msg.sender, results, rewards);
    }
    
    //now mint rewards for player
    //nonReentrant
    function collectRewards() 
    public nonReentrant{
        uint256 CPX = playerRewards[msg.sender][0];
        uint256 XP = playerRewards[msg.sender][1];
        //decrease each
        playerRewards[msg.sender][0] = 0;
        playerRewards[msg.sender][1] = 0;
        //mint each
        //CPX
        Mint(CLinks[3]).mintToken(CLinks[4], msg.sender, CPX);
        //XP
        Mint(CLinks[3]).mintToken(CLinks[5], msg.sender, XP);
    }
}