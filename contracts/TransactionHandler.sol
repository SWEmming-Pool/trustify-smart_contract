// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Transaction {
    string id;
    address sender;
    address payable receiver;
    uint256 amount;
    uint256 date;
}

contract TransactionHandler {
    mapping(address => Transaction[]) private transactions;

    // add transaction
    function addTransaction(
        string memory _id,
        address _sender,
        address payable _receiver,
        uint256 _date
    ) public {
        Transaction memory transaction = Transaction(
            _id,
            _sender,
            _receiver,
            this.getBalance(),
            _date
        );
        sendToReceiver(_receiver, this.getBalance());
        transactions[_sender].push(transaction);
    }

    // get transactions
    function getTransactions(address _sender) public view returns (Transaction[] memory) {
        return transactions[_sender];
    }

    // Default function, called when Ether is sent to the contract.
    receive() external payable { }

    // send to receiver the amount
    function sendToReceiver(address payable _receiver, uint256 _amount) private {
        // There is no need to check the balance, EVM will make sure that, if the balance is not enough, the transaction will be automatically reverted. 
        _receiver.transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        // Return the balance of the contract.
        return address(this).balance;
    }
}