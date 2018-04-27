pragma solidity ^0.4.18;

import "./Administered.sol";
import "./PullToBank.sol";
import "./ReentrancyGuard.sol";
import "./ContractLinked.sol";
import "./CosmicCollection.sol";
import "./ChallengeCPX.sol";

contract HeroLocation{
    function planeOf(uint256 _itemID) external view returns (uint256 _planeID);
}

contract Mint {
    function mintToken(address token, address tokenOwner, uint256 amount) external;
}


contract ChallengeCPXCommit is Administered, PullToBank, ReentrancyGuard, OwnsLinkedContracts {
   
    struct PlayerCommit {
        uint256[] heroes;
        uint256 commit; 
        uint8 turns;
        uint8 resolved;
    }

    struct Player {
        uint256[] all;
        mapping (uint256 => PlayerCommit) challenge;
    }
    
    struct ChallengeCommit {
        uint256 value;
        address[] players;
    }
    
    //watch current winner
    mapping (uint256 => address) public currentWinner;
    //watch commits
    mapping (uint256 => ChallengeCommit) internal challengeCommits;
    //track players and their commits
    mapping (address => Player) internal playerCommits;
    
    //contain list of rewards for player
    mapping (address => uint256[2]) public playerRewards;
    
    //Costs
    uint256 public commitCost = 1 finney;
    
    
    function () public payable {}
    constructor () public {
        /* Links
        0 - Collectable, 1 - ChallengeCPX, 2 - Resolve, 3 location, 4 mint, 5 CPX, 6 XP
        */
        bank = 0x16e39D98A3f25B39eBdA681ECaE94418E1d20De2;
        CLinks=[
            0x572403E42F7d787f3EA38eeCCCe7699c02e95f55,
            0xF88F5D5203A59876da02855415113aDCaadcf72b,
            0xb472F8278c12959ED96868751471Bb1f44fB21D3,
            0x1D67f2216c04B829A6dda0a88eC5902efD9D31B6,
            0x6800E6627382afD13B736581E677107b03b6c02a,
            0xFD90bf0c7758F98269d59Dd908771f874C9A17f6,
            0x5afD4B9e3b088Cdeed863B67e66a9a8c6d6F7B26
            ];
    }
    
    
    /*Views */
    
    function isPlayerCommitted (uint256 id, address player) 
    public view returns(bool commited) {
        commited = playerCommits[player].challenge[id].commit > 0;
    }
    
    function isPlayerResolved (uint256 id, address player) 
    public view returns(bool resolved) {
        resolved = playerCommits[player].challenge[id].turns > 0;
    }
    
    function challengePlayers (uint256 id) 
    public view returns(address[] players) {
        players = challengeCommits[id].players;
    }
    
    function getPlayerChallenges (address player) 
    public view returns(uint256[] all) {
        all = playerCommits[player].all;
    }
    
    function getChallengeHeroes (uint256 id, address player) 
    public view returns(uint256[] heroes) {
        heroes = playerCommits[player].challenge[id].heroes;
    }
    
    function getChallengeCommit (address player, uint256 id) 
    public view returns(uint256[] heroes, uint256 commit, uint8 turns, uint8 resolved) {
        heroes = playerCommits[player].challenge[id].heroes;
        commit = playerCommits[player].challenge[id].commit;
        turns = playerCommits[player].challenge[id].turns;
        resolved = playerCommits[player].challenge[id].resolved;
    }
    
    
    /* internal */
    //check the winner
    //challenge, player to check, turns they completed the challenge in
    function challengeWinner(uint256 id, address player, uint8 turns) 
    internal {
        address cw = currentWinner[id];
        if(cw == address(0)) currentWinner[id] = player;
        else {
            uint8 nwt = playerCommits[cw].challenge[id].turns;
            
            //beats the number of successes
            if(turns < nwt) currentWinner[id] = player;
            else if(turns == nwt) {
                //beats their commit
                if(playerCommits[player].challenge[id].commit < playerCommits[cw].challenge[id].commit) currentWinner[id] = player;
            }
        }
    }
    
    
    /* Admin Functions */
    function setConstant (uint256 cost) 
    public onlyAdmin {
        if(cost != 0) commitCost = cost;
    }
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    //finalize the challenge - no more resolution - declares winner
    //id of challenge, and index to remove
    function finalizeChallenge(uint256 id, uint256 i)
    public onlyAdmin {
        //close out in the data 
        ChallengeCPX(CLinks[1]).finalizeChallenge(id, i);
        //determine total value of player commits
        uint256 totalCommit = challengeCommits[id].value;
        //benefactor gets 40%
        uint256 toBenefactor = totalCommit * 40 / 100;
        asyncSend(ChallengeCPX(CLinks[1]).getBenefactor(id), toBenefactor);
        //plane onwer gets 10%
        uint256 toPlane = totalCommit * 10 / 100;
        asyncSend(CosmicCollectionTokens(CLinks[0]).ownerOf(ChallengeCPX(CLinks[1]).getPlane(id)), toPlane);
        //winner gets half
        uint256 toWinner = totalCommit * 50 / 100;
        asyncSend(currentWinner[id], toWinner);
    }
    
    function resolve(uint256 id, address player, bool success, uint8 resolved, uint8 turns, uint256[2] rewards)
    public {
        //only the resolve contract may resolve
        require(msg.sender == CLinks[2]);
        //resovle
        playerCommits[player].challenge[id].resolved = resolved;
        playerCommits[player].challenge[id].turns = turns;
        //update player rewards - CPX and XP
        playerRewards[player][0] += rewards[0];
        playerRewards[player][1] += rewards[1];
        //check for winner
        if(success) challengeWinner(id, player, turns); 
    }
    
    
    /* Public player functions*/
    
    //commit to solve - one hero per skill 
    //hero can repeat
    function commit (uint256 id, uint256[12] heroes) 
    public payable {
        //cannot have key 
        require(ChallengeCPX(CLinks[1]).isOpen(id));
        //must pay
        require(msg.value >= commitCost);
        //pull plane for reference
        uint256 plane = ChallengeCPX(CLinks[1]).getPlane(id);
        for(uint8 i = 0; i < 10; i++){
            //must be heroes and must own them
            require(CosmicCollectionTokens(CLinks[0]).typeOf(heroes[i]) == 1 && msg.sender == CosmicCollectionTokens(CLinks[0]).ownerOf(heroes[i]));
            //must be on the plane
            require(plane == HeroLocation(CLinks[3]).planeOf(heroes[i]));
        }
        challengeCommits[id].value += commitCost;
        challengeCommits[id].players.push(msg.sender);
        //commit
        playerCommits[msg.sender].all.push(id);
        playerCommits[msg.sender].challenge[id].commit = now;
        //push heroes
        playerCommits[msg.sender].challenge[id].heroes = heroes;
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
        Mint(CLinks[4]).mintToken(CLinks[5], msg.sender, CPX);
        //XP
        Mint(CLinks[4]).mintToken(CLinks[6], msg.sender, XP);
    }
}