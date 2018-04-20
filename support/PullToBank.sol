pragma solidity ^0.4.20;

import './Ownable.sol';
import './PullPayment.sol';

contract PullToBank is Ownable, PullPayment {
    //sets up bank and distributor
    address internal bank;

    function PullToBank() public {
        bank = msg.sender;
    }
    
    function setBankContract(address _bank) 
    external onlyOwner {
        bank = _bank;
    }
    //withdraw
    // The owner can only withdraw what has not been assigned to plane owners as PullPayments.
    function withdrawToBank()
    external onlyOwner {
        //withdraw bank account
        uint256 payment = payments[bank];
        require(payment != 0);
        require(this.balance >= payment);

        totalPayments = totalPayments.sub(payment);
        payments[bank] = 0;

        assert(bank.send(payment));
        // The contract's balance MUST stay backing the outstanding withdrawals. Only the surplus not needed for any backing can be withdrawn by the owner.
        uint256 surplus = this.balance.sub(totalPayments);
        if (surplus > 0) {
            bank.transfer(surplus);
        }
    }
}



