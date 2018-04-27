pragma solidity ^0.4.18;

contract Token {
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function transfer(address to, uint tokens) public returns (bool success);
}

contract TokenPaymentProcessor {
    function processTokenPayment(address token, address player, uint256 cost)
    internal returns(bool paid) {
        //check for CPX allowance
        uint256 allowance = Token(token).allowance(player,address(this));
        //require payment -  if allowance - take
        if(allowance >= cost && Token(token).transferFrom(player, address(this), cost)) {
            //burn
            Token(token).transfer(address(0), cost);
            //paid
            paid = true;
        }
    }
}

contract TokenAndEtherPaymentProcessor {

    function processPayment(address token, address player, uint256 msgVal, uint256[2] cost)
    internal returns(bool paid) {
        //check for CPX allowance
        uint256 allowance = Token(token).allowance(player,address(this));
        //require payment -  if allowance - take
        if(allowance >= cost[1] && Token(token).transferFrom(player, address(this), cost[1])) {
            //burn
            Token(token).transfer(address(0), cost[1]);
            //paid
            paid = true;
        }
        else if(msgVal >= cost[0]) paid = true;
    }
}
