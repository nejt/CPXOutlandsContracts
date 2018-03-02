pragma solidity 0.4.20;

import "./CPXConstants-0.1.4.sol";

contract CPXPersonalPlanes is usesConstants, hasCPXAdmin, hasBalance{
    struct personalPlane {
        bytes32 id;
        address owner;
        bool pvt;
        bool closed;
    }
    
    personalPlane[] public planes;
    
    function() public payable { }
    
    function CPXPersonalPlanes() public { }
    
    //logs for events
    event LogCreate(bytes32 id);
    event LogDestroy(bytes32 id);
    event LogUpdate(bytes32 id);
    
    function nPlanes() view public returns (uint) {
        return(planes.length);
    }
    
    function currentCost() view public returns (uint reg) {
        uint mod = planes.length * 3;
        reg = cpxVal.value("register")*(100+mod)/100;
    }
    
    //up cost by 3% every buy
    function createPlane(string _name) public payable returns (bytes32){
        //calculate cost to register - base + nPlanes * 3%
        uint vReg = this.currentCost();
        //has to provide the funds - all are the same
        if(msg.value < vReg) revert();
        //make id
        bytes32 _id = keccak256(msg.sender,now,_name);
        //add to storage
        planes.push(personalPlane(_id,msg.sender,false,false));
        //log
        LogCreate(_id);
        //return the id
        return(_id);
    }
    
    //set privacy
    function setPrivate(uint _i, bytes32 _id, bool _pvt) public payable returns(bool){
        //validate cost
        if(_pvt && msg.value < cpxVal.value("pvtplane")) revert(); 
        //validate id, owner 
        require(planes[_i].id == _id && planes[_i].owner == msg.sender);
        //set state
        planes[_i].pvt = _pvt;
        //log
        LogUpdate(_id);
        //let them know
        return(true);
    }
    
    //set privacy
    function setClosed(uint _i, bytes32 _id, bool _closed) public payable returns(bool){
        //validate cost
        if(_closed && msg.value < cpxVal.value("clsdpln")) revert(); 
        //validate id, owner 
        require(planes[_i].id == _id && planes[_i].owner == msg.sender);
        //set state
        planes[_i].closed = _closed;
        //log
        LogUpdate(_id);
        //let them know
        return(true);
    }
    
    //change owner
    function transferPlane(uint _i, bytes32 _id, address _to) public returns(bool){
        //validate id and owner
        require(planes[_i].id == _id && planes[_i].owner == msg.sender);
        //transfer ownership
        planes[_i].owner = _to;
        //log
        LogUpdate(_id);
        //let them know
        return(true);
    }
    
    function destroyPlane(uint _i) public onlyAdmin {
        //log
        LogDestroy(planes[_i].id);    
        //check to make sure it is in array
        if (_i >= planes.length) return;
        //take last and put at they index
        planes[_i] = planes[planes.length-1];
        //delete last from array
        delete planes[planes.length-1];
        planes.length--;
    }
    
    //kill the contract
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }
}