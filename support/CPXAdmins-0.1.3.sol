pragma solidity 0.4.20;

import "./CPXSupport-0.2.0.sol";

contract CPXAdmins is owned{
    // This declares a state variable that
    // stores a bool for each possible address.
    mapping(address => bool) public super;
    mapping(address => bool) public admins;
    
    //logginh
    event LogNewAdmin (address admin, bool super);
    event LogRemoveAdmin (address admin, bool super);
    
    function CPXAdmins () public {
        super[owner] = true;
        admins[owner] = true;
    }
    
    function addAdmin(address _a, bool _super) public onlyOwner {
        if(_super) super[_a] = true;
        
        admins[_a] = true;
        //Log
        LogNewAdmin (_a, _super);
    }
    function removeAdmin(address _a, bool _super) public onlyOwner {
        if(_super) super[_a] = false;
        
        admins[_a] = false;
        //Log 
        LogRemoveAdmin (_a, _super);
    }
    //kill the contract
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }
}

contract hasCPXAdmin is owned{
    CPXAdmins masterAdmins;
    
    //set the Admin contract
    function setAdminContract(address _contract) public onlyOwner {
        masterAdmins = CPXAdmins(_contract); 
    }

    //modifier to be used by inhereted contracts
    //only allows those in the admin or super list to do work
    modifier onlyAdmin {
        require(masterAdmins.admins(msg.sender) || masterAdmins.super(msg.sender));
        _;
    }
    
    //modifier to be used by inhereted contracts
    //only allows those in the super list to do work
    modifier onlySuper {
        require(masterAdmins.super(msg.sender));
        _;
    }
}

contract hasBalance is hasCPXAdmin{
    event LogWithdraw (
        address by,
        address to,
        uint amount
    );
    
    //balance check
    function checkBalance() public view onlyAdmin returns (uint256) {
        //return info
        return(this.balance);
    }
    
    //withdraw
    function withdraw(address _to, uint _val) public onlySuper {
        //require funds
        require(this.balance >= _val);
        //make transfer
        _to.transfer(_val);
        //log event
        LogWithdraw(msg.sender,_to,_val);
    }
}