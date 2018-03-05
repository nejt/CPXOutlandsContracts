pragma solidity 0.4.20;

import "./Administered.sol";
import "./Distributes.sol";

//ropsten 
contract CPXLinks is Administered, PaysBank {
    //constants
    uint public clink = 1/8 * 1 finney;
    uint public dlink = clink;
    uint public cjoin = 1/4 * 1 finney;
    uint public djoin = cjoin;
    uint public dall = 2 * 1 finney;
    
    
    /* Core Link information */
    //struct to contain link and join data
    struct planeLinks {
        bytes32[] links;
        bytes32 join;
    }
    
    //mapping for planeLinks
    //has to use bytes32 because of Network Planes
    mapping (bytes32 => planeLinks) internal allLinks;
    
    
    /* Creation */
    
    function() public payable { }
    
    function CPXLinks() public { }
    
    
    /* Events */
    event LogLink(bytes32 indexed _from, bytes32 indexed _to, bool create);
    event LogJoin(bytes32 indexed _from, bytes32 join, bool create);


    /* View information */
    function getLinks(bytes32 _id) 
    view public returns(bytes32[] links, bytes32 join) {
        links = allLinks[_id].links;
        join = allLinks[_id].join;
    }
    

    /* Admin Functions */ 
    //set constants
    function setConstants(uint[4] _cost) 
    public onlyAdmin {
        clink = _cost[0];
        dlink = _cost[1];
        cjoin = _cost[2];
        djoin = _cost[3]; 
    }
    
    function setAdmin(address _admin, bool _isAdmin) 
    public onlyAdmin returns (bool success) {
        admins[_admin] = _isAdmin;
        return true;
    }
    
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }
    
    
    /* Core Functionality */
    
    /* internal creation functions */
    function makeJoin(bytes32 _from, bytes32 _to) 
    internal {
        //check if they have a join
        if(allLinks[_to].join != 0) {
            allLinks[_from].join = allLinks[_to].join;
        }
        else if (allLinks[_from].join != 0) {
            allLinks[_to].join = allLinks[_from].join;
        }
        //if not make join - joins are two way
        else {
            bytes32 _join = keccak256(_from,_to);
            allLinks[_from].join = _join;
            allLinks[_to].join = _join;
        }
        //log
        LogJoin(_from,allLinks[_from].join,true);
    }
    
    function makeLink(bytes32 _from, bytes32 _to) 
    internal {
        //push links - links are not two way
        allLinks[_from].links.push(_to);
        //log
        LogLink(_from,_to,true);
    }
    
    /* internal destruction function */
    function iDestroyLink(bytes32 _from, bytes32 _to, uint _i) 
    internal {
        //check for the same hash
        require(allLinks[_from].links[_i] == _to);
        //length
        uint l = allLinks[_from].links.length;
        //shift last to location
        allLinks[_from].links[_i] = allLinks[_from].links[l-1];
        //delete last
        allLinks[_from].links.length--;
        //log
        LogLink(_from,_to,false);
    }
    
    function iDestroyJoin(bytes32 _from) 
    internal {
        //destroy from join
        delete allLinks[_from].join;
        //log
        LogJoin(_from,0,false);
    }
    
    
    /* External Interface */
    function createLink(bytes32 _from, bytes32 _to, bool _join) 
    public payable {
        if(admins[msg.sender]){
            if(_join) makeJoin(_from, _to);
            else makeLink(_from, _to); 
        }
        else{
            //must pay
            require(msg.value >= clink);
            if(_join) {
                //has to provide the funds 
                require(msg.value >= cjoin);
                //make the join
                makeJoin(_from, _to);
            }
            else { 
                makeLink(_from, _to); 
            }
        }
    }
    
    function destroyLink(bytes32 _from, bytes32 _to, uint _i, bool _join) 
    public payable {
        if(admins[msg.sender]){
            if(_join) iDestroyJoin(_from);
            else iDestroyLink(_from, _to, _i); 
        }
        else{
            //must pay
            require(msg.value >= dlink);
            if(_join) {
                //has to provide the funds 
                require(msg.value >= djoin);
                //make the join
                iDestroyJoin(_from);
            }
            else { 
                iDestroyLink(_from, _to, _i); 
            }
        }
    }
    
    //destroy all links from a plane
    function destroyAllLinks(bytes32 _from) 
    public payable {
        if(admins[msg.sender]){
            allLinks[_from].links.length = 0;
        }
        require(msg.value >= dall);
        //destroy all links
        allLinks[_from].links.length = 0;
    }
}