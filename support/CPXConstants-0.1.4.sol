pragma solidity 0.4.20;

import "./CPXAdmins-0.1.3.sol";

contract CPXConstants is hasCPXAdmin {
    mapping(bytes8 => uint) public value;
    
    function CPXConstants () public {
        //actual costs
        //base is szabo
        value["base"] = 1 szabo;
        value["register"] = 1000 * 1 szabo;
        value["link"] =  value["register"] / 8;
        value["dlink"] =  value["link"];
        value["join"] = value["register"] / 4;
        value["djoin"] =  value["join"];
    }
    
    function setConstant(bytes8 _what, uint _val, bool usebase) public onlyAdmin {
        //multiply by base balue
        if(usebase) value[_what] = _val * value["base"];
        else value[_what] = _val;
    }
    
    //kill the contract
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }
}

contract usesConstants is owned{
    CPXConstants cpxVal;
    function setConstantContract (address _contract) public onlyOwner { cpxVal = CPXConstants(_contract); }
}