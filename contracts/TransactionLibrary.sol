// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TransactionLibrary {
    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        uint256 date;
        bytes32 id;
    }

    function addTransaction(
        Transaction[] storage self,
        address _sender,
        address _receiver,
        uint256 _amount,
        bytes32 _transactionId
    ) internal {
        Transaction memory newTransaction = Transaction({
            sender: _sender,
            receiver: _receiver,
            amount: _amount,
            date: block.timestamp,
            id: _transactionId
        });

        self.push(newTransaction);
    }

    function getTransactionById(
        Transaction[] storage self,
        bytes32 _transactionId
    ) internal view returns (TransactionLibrary.Transaction memory) {
        require(self.length > 0, "No transactions found for this address");

        for (uint i = 0; i < self.length; i++) {
            if (self[i].id == _transactionId) {
                return self[i];
            }
        }
        revert("No transaction found with the given ID for this address");
    }

    function containsTransaction(
        Transaction[] storage self,
        bytes32 _transactionId
    ) internal view returns (bool) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i].id == _transactionId) {
                return true;
            }
        }
        return false;
    }
}
