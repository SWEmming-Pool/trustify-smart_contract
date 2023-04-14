// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransactionLibrary.sol";
import "./ReviewLibrary.sol";

contract ReviewSystem {
    using TransactionLibrary for TransactionLibrary.Transaction[];
    mapping(address => TransactionLibrary.Transaction[]) private transactions;
    mapping(bytes32 => ReviewLibrary.Review) private reviews;

    function sendTransaction(address _receiver) external payable {
        require(msg.value > 0, "The sent amount must be greater than 0");

        // Generate a unique ID for the transaction
        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, _receiver, msg.value, block.timestamp)
        );

        transactions[msg.sender].addTransaction(
            msg.sender,
            _receiver,
            msg.value,
            id
        );

        // Send the same amount of Ether to the specified receiver address
        payable(_receiver).transfer(msg.value);
    }

    modifier transactionSenderOnly(bytes32 _id) {
        require(
            TransactionLibrary.containsTransaction(
                transactions,
                msg.sender,
                _id
            ),
            "Transaction sender is not authorized"
        );
        _;
    }
    modifier transactionExists(bytes32 _id) {
        // Check that the transaction exists
        require(
            transactions[msg.sender].length > 0,
            "No transactions found for this address"
        );

        // Find the transaction with the given ID
        TransactionLibrary.Transaction[]
            memory senderTransactions = transactions[msg.sender];
        bool transactionFound = false;
        for (uint i = 0; i < senderTransactions.length; i++) {
            if (senderTransactions[i].id == _id) {
                transactionFound = true;
                break;
            }
        }
        require(
            transactionFound,
            "No transaction found with the given ID for this address"
        );
        _;
    }
    modifier reviewNotAlreadyExists(bytes32 _id) {
        // Check that a review for this transaction doesn't already exist
        require(
            bytes(reviews[_id].text).length == 0,
            "A review for this transaction already exists"
        );
        _;
    }

    function addReview(
        bytes32 _id,
        string memory _title,
        uint8 _rating,
        string memory _text
    )
        public
        transactionSenderOnly(_id)
        transactionExists(_id)
        reviewNotAlreadyExists(_id)
    {
        require(
            bytes(_title).length <= 50,
            "Title must be less than or equal to 50 characters"
        );

        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        require(
            bytes(_text).length <= 500,
            "Text must be less than or equal to 500 characters"
        );

        ReviewLibrary.Review memory newReview = ReviewLibrary.Review({
            title: _title,
            date: block.timestamp,
            rating: _rating,
            text: _text
        });

        reviews[_id] = newReview;
    }

    // function getUnreviewedTransactionIDs(
    //     address _address
    // ) external view returns (bytes32[] memory) {
    //     uint unreviewedCount = 0;

    //     for (uint i = 0; i < transactions[_address].length; i++) {
    //         if (bytes(reviews[transactions[_address][i].id].text).length == 0) {
    //             unreviewedCount++;
    //         }
    //     }

    //     bytes32[] memory unreviewedIDs = new bytes32[](unreviewedCount);

    //     uint j = 0;
    //     for (uint i = 0; i < transactions[_address].length; i++) {
    //         if (bytes(reviews[transactions[_address][i].id].text).length == 0) {
    //             unreviewedIDs[j] = transactions[_address][i].id;
    //             j++;
    //         }
    //     }

    //     return unreviewedIDs;
    // }
    function getUnreviewedTransactions(
        address _address
    ) external view returns (TransactionLibrary.Transaction[] memory) {
        uint unreviewedCount = 0;

        for (uint i = 0; i < transactions[_address].length; i++) {
            if (bytes(reviews[transactions[_address][i].id].text).length == 0) {
                unreviewedCount++;
            }
        }

        TransactionLibrary.Transaction[]
            memory unreviewedTransactions = new TransactionLibrary.Transaction[](
                unreviewedCount
            );

        uint j = 0;
        for (uint i = 0; i < transactions[_address].length; i++) {
            if (bytes(reviews[transactions[_address][i].id].text).length == 0) {
                unreviewedTransactions[j] = transactions[_address][i];
                j++;
            }
        }

        return unreviewedTransactions;
    }

    // function getReview(
    //     bytes32 _id
    // ) public view returns (ReviewLibrary.Review memory) {
    //     return ReviewLibrary.getReview(reviews, _id);
    // }

    // UC09
    function getReviewsForAddress(
        address _address
    ) public view returns (ReviewLibrary.Review[] memory) {
        uint reviewCount = 0;

        for (uint i = 0; i < transactions[_address].length; i++) {
            if (bytes(reviews[transactions[_address][i].id].text).length > 0) {
                reviewCount++;
            }
        }

        ReviewLibrary.Review[]
            memory reviewsForAddress = new ReviewLibrary.Review[](reviewCount);

        uint j = 0;
        for (uint i = 0; i < transactions[_address].length; i++) {
            bytes32 id = transactions[_address][i].id;
            if (bytes(reviews[id].text).length > 0) {
                reviewsForAddress[j] = reviews[id];
                j++;
            }
        }

        return reviewsForAddress;
    }

    // function getTransactionById(
    //     bytes32 _id,
    //     address _address
    // ) public view returns (TransactionLibrary.Transaction memory) {
    //     return
    //         TransactionLibrary.getTransactionById(transactions[_address], _id);
    // }
}
