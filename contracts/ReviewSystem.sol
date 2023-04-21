// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

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

    // Tutte le transazioni per il loro id
    mapping(bytes32 => TransactionLibrary.Transaction) private transactionsById;
    // Tutte le review per l'id della transazione collegata
    mapping(bytes32 => ReviewLibrary.Review) private reviewsByTransactionId;
    // Mapping per ricerca address => arrayTransId
    mapping(address => bytes32[]) private reviewsBySender;
    mapping(address => bytes32[]) private reviewsByReceiver;

    function getNumberOfReviewsMade(address _sender) external view returns (uint256) {
        return reviewsBySender[_sender].length;
    }

    function getNumberOfReviewsReceived(address _receiver) external view returns (uint256) {
        return reviewsByReceiver[_receiver].length;
    }

    function getReviewTitle(bytes32 _reviewId) external view returns (string memory) {
        return reviewsByTransactionId[_reviewId].title;
    }

    function getReviewDate(bytes32 _reviewId) external view returns (uint256) {
        return reviewsByTransactionId[_reviewId].date;
    }

    function getReviewRating(bytes32 _reviewId) external view returns (uint8) {
        return reviewsByTransactionId[_reviewId].rating;
    }

    function getReviewText(bytes32 _reviewId) external view returns (string memory) {
        return reviewsByTransactionId[_reviewId].text;
    }

    function getReviewTransactionId(bytes32 _reviewId) external view returns (bytes32) {
        return reviewsByTransactionId[_reviewId].transactionId;
    }

    function sendTransaction(address _receiver) external payable {
        require(msg.value > 0, "The sent amount must be greater than 0");

        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, _receiver, msg.value, block.timestamp)
        );

        transactionsBySender[msg.sender].addTransaction(
            msg.sender,
            _receiver,
            msg.value,
            id
        );
        transactionsByReceiver[_receiver].addTransaction(
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

    function getTransactionForSender(
        address _sender,
        bytes32 _id
    ) public view returns (TransactionLibrary.Transaction memory) {
        require(
            TransactionLibrary.containsTransaction(
                transactionsBySender[_sender],
                _id
            ),
            "Transaction not found"
        );
        return transactionsBySender[_sender].getTransactionById(_id);
    }

    function getTransactionForReciver(
        address _reciver,
        bytes32 _id
    ) public view returns (TransactionLibrary.Transaction memory) {
        require(
            TransactionLibrary.containsTransaction(
                transactionsByReceiver[_reciver],
                _id
            ),
            "Transaction not found"
        );
        return transactionsByReceiver[_reciver].getTransactionById(_id);
    }

    function getUnreviewedTransactions(
        address _sender
    ) external view returns (TransactionLibrary.Transaction[] memory) {
        uint unreviewedCount = 0;

        for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
            if (
                bytes(reviews[transactionsBySender[_sender][i].id].text)
                    .length == 0
            ) {
                unreviewedCount++;
            }
        }

        TransactionLibrary.Transaction[]
            memory unreviewedTransactions = new TransactionLibrary.Transaction[](
                unreviewedCount
            );

        uint j = 0;
        for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
            if (
                bytes(reviews[transactionsBySender[_sender][i].id].text)
                    .length == 0
            ) {
                unreviewedTransactions[j] = transactionsBySender[_sender][i];
                j++;
            }
        }

        return unreviewedTransactions;
    }

    // UC09
    function getReviewsForSender(
        address _sender
    ) public view returns (ReviewLibrary.Review[] memory) {
        uint reviewCount = 0;

        for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
            if (
                bytes(reviews[transactionsBySender[_sender][i].id].text)
                    .length > 0
            ) {
                reviewCount++;
            }
        }

        ReviewLibrary.Review[]
            memory reviewsForAddress = new ReviewLibrary.Review[](reviewCount);

        uint j = 0;
        for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
            bytes32 id = transactionsBySender[_sender][i].id;
            if (bytes(reviews[id].text).length > 0) {
                reviewsForAddress[j] = reviews[id];
                j++;
            }
        }

        return reviewsForAddress;
    }

    function getReviewsForReciver(
        address _reciver
    ) public view returns (ReviewLibrary.Review[] memory) {
        uint reviewCount = 0;

        for (uint i = 0; i < transactionsByReceiver[_reciver].length; i++) {
            if (
                bytes(reviews[transactionsByReceiver[_reciver][i].id].text)
                    .length > 0
            ) {
                reviewCount++;
            }
        }

        ReviewLibrary.Review[]
            memory reviewsForAddress = new ReviewLibrary.Review[](reviewCount);

        uint j = 0;
        for (uint i = 0; i < transactionsByReceiver[_reciver].length; i++) {
            bytes32 id = transactionsByReceiver[_reciver][i].id;
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
                transactionsBySender[msg.sender],
                _id
            ),
            "Transaction sender is not authorized"
        );
        _;
    }
    modifier transactionExists(bytes32 _id) {
        require(
            transactionsBySender[msg.sender].length > 0,
            "No transactions found for this address"
        );

        TransactionLibrary.Transaction[]
            memory senderTransactions = transactionsBySender[msg.sender];
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
