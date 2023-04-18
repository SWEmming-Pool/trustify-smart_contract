// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransactionLibrary.sol";
import "./ReviewLibrary.sol";

contract ReviewSystem {
    event TransactionSent(
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        bytes32 _id
    );

    event ReviewAdded(
        string title,
        uint256 timestamp,
        uint8 rating,
        string text,
        bytes32 id
    );

    using TransactionLibrary for TransactionLibrary.Transaction[];
    mapping(address => TransactionLibrary.Transaction[]) private transactions;
    mapping(bytes32 => ReviewLibrary.Review) private reviews;

    function sendTransaction(address _receiver) external payable {
        require(msg.value > 0, "The sent amount must be greater than 0");

        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, _receiver, msg.value, block.timestamp)
        );

        transactions[msg.sender].addTransaction(
            msg.sender,
            _receiver,
            msg.value,
            id
        );

        payable(_receiver).transfer(msg.value);
        emit TransactionSent(msg.sender, _receiver, msg.value, id);
    }

    function addReview(
        bytes32 _transactionId,
        string memory _title,
        uint8 _rating,
        string memory _text
    )
        public
        transactionSenderOnly(_transactionId)
        transactionExists(_transactionId)
        reviewNotAlreadyExists(_transactionId)
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
            text: _text,
            transactionId: _transactionId
        });

        reviews[_transactionId] = newReview;

        emit ReviewAdded(
            _title,
            block.timestamp,
            _rating,
            _text,
            _transactionId
        );
    }

    function getTransaction(
        address _address,
        bytes32 _id
    ) public view returns (TransactionLibrary.Transaction memory) {
        require(
            TransactionLibrary.containsTransaction(transactions[_address], _id),
            "Transaction not found"
        );
        return transactions[_address].getTransactionById(_id);
    }

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

    modifier transactionSenderOnly(bytes32 _id) {
        require(
            TransactionLibrary.containsTransaction(
                transactions[msg.sender],
                _id
            ),
            "Transaction sender is not authorized"
        );
        _;
    }
    modifier transactionExists(bytes32 _id) {
        require(
            transactions[msg.sender].length > 0,
            "No transactions found for this address"
        );

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
        require(
            bytes(reviews[_id].text).length == 0,
            "A review for this transaction already exists"
        );
        _;
    }
}
