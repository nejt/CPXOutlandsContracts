pragma solidity 0.4.20;

import "./CPXAdmins-0.1.3.sol";
import "./CPXConstants-0.1.4.sol";

//ropsten 
contract CPXLinks is usesConstants, hasBalance{
    //struct to contain link and join data
    struct planeLinks {
        bytes32[] links;
        bytes32 join;
    }
    
    //mapping for planeLinks
    mapping (bytes32 => planeLinks) allLinks;
    
    function() public payable { }
    
    function CPXLinks() public { }
    
    event LogLink(
        bytes32 indexed _from,
        bytes32 indexed _to,
        bool create
    );
    
    event LogJoin(
        bytes32 indexed _from,
        bytes32 join,
        bool create
    );
    
    function getLinks(bytes32 _id) view public returns(bytes32[] links, bytes32 join) {
        links = allLinks[_id].links;
        join = allLinks[_id].join;
    }

    function link(bytes32 _from, bytes32 _to, bool _join) public payable {
        //has to provide the funds or an admin
        if(msg.value < cpxVal.value("link") && !masterAdmins.admins(msg.sender) ){
            revert();
        }

        if(_join){
            //has to provide the funds or an admin
            if(msg.value < cpxVal.value("join") && !masterAdmins.admins(msg.sender)) revert(); 
            //check if they have a join
            if(allLinks[_to].join != 0) {
                allLinks[_from].join = allLinks[_to].join;
            }
            else if (allLinks[_from].join != 0) {
                allLinks[_to].join = allLinks[_from].join;
            }
            //if not make join - joins are two way
            else {
                bytes32 hjoin = keccak256(_from,_to);
                allLinks[_from].join = hjoin;
                allLinks[_to].join = hjoin;
            }
            //log
            LogJoin(_from,allLinks[_from].join,true);
        }
        else {
            //push links - links are not two way
            allLinks[_from].links.push(_to);
            //log
            LogLink(_from,_to,true);
        }
    }
    
    function destroyLink(bytes32 _from, bytes32 _to, uint _i, bool _join) public payable {
        //has to provide the funds or an admin
        if(msg.value < cpxVal.value("dlink") && !masterAdmins.admins(msg.sender) ){
            revert();
        }

        if(_join){
            if(msg.value < cpxVal.value("djoin") && !masterAdmins.admins(msg.sender)) revert(); 
            //destroy from join
            delete allLinks[_from].join;
            //log
            LogJoin(_from,0,false);
        }
        else {
            //check for the same hash
           if(allLinks[_from].links[_i] != _to) revert(); 
           //length
           uint l = allLinks[_from].links.length;
           //shift last to location
           allLinks[_from].links[_i] = allLinks[_from].links[l-1];
           //delete last
           delete allLinks[_from].links[l-1];
           allLinks[_from].links.length--;
           //log
           LogLink(_from,_to,false);
        }
    }
    
    function destroyAllLinks(bytes32 _from) public onlyAdmin {
        //destroy all links
        delete allLinks[_from].links;
        allLinks[_from].links.length = 0;
    }
    
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }
}