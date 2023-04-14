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
        bytes32 _id
    ) internal {
        // Create a new transaction struct
        Transaction memory newTransaction = Transaction({
            sender: _sender,
            receiver: _receiver,
            amount: _amount,
            date: block.timestamp,
            id: _id
        });

        // Add the transaction to the sender's list of transactions
        self.push(newTransaction);
    }

    function getTransactionIDs(
        Transaction[] storage self
    ) internal view returns (bytes32[] memory) {
        uint length = self.length;
        bytes32[] memory ids = new bytes32[](length);

        for (uint i = 0; i < length; i++) {
            ids[i] = self[i].id;
        }

        return ids;
    }

    function containsTransaction(
        mapping(address => Transaction[]) storage self,
        address sender,
        bytes32 transactionId
    ) public view returns (bool) {
        Transaction[] storage senderTransactions = self[sender];
        for (uint i = 0; i < senderTransactions.length; i++) {
            if (senderTransactions[i].id == transactionId) {
                return true;
            }
        }
        return false;
    }

    //     function getTransactionById(
    //         Transaction[] storage self,
    //         bytes32 id
    //     ) internal view returns (Transaction memory) {
    //         for (uint i = 0; i < self.length; i++) {
    //             if (self[i].id == id) {
    //                 return self[i];
    //             }
    //         }
    //         revert("Transaction not found.");
    //     }
}
