// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract ReviewSystem {
    
    // ==================
    //  Data Structures
    // ==================

    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        uint256 date;
        bool reviewed;
        bytes32 id;
    }

    struct Review {
        string title;
        uint256 date;
        uint8 rating;
        string text;
        bytes32 transactionId;
    }

    // ==================
    // Storage
    // ==================

    mapping(bytes32 => Review) private reviewsById;
    mapping(bytes32 => Transaction) private transactionsById;
    mapping(address => Transaction[]) private transactionsBySender;
    mapping(address => Transaction[]) private transactionsByReceiver;

    // ==================
    // Modifiers
    // ==================

    modifier transactionSenderOnly(bytes32 _transactionId) {
        require(
            transactionsById[_transactionId].sender == msg.sender,
            "Only the sender of the transaction can add a review"
        );
        _;
    }

    modifier transactionExists(bytes32 _transactionId) {
        require(
            transactionsById[_transactionId].sender != address(0),
            "No transaction found with the given ID"
        );
        _;
    }

    modifier reviewNotAlreadyExists(bytes32 _transactionId) {
        require(
            transactionsById[_transactionId].reviewed == true,
            "A review for this transaction already exists"
        );
        _;
    }

    // ==================
    // Public Functions
    // ==================

    function sendeTransaction(address _receiver) external payable {
        require(msg.value > 0, "The sent amount must be greater than 0");

        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, _receiver, msg.value, block.timestamp)
        );

        Transaction memory newTransaction = Transaction({
            sender: msg.sender,
            receiver: _receiver,
            amount: msg.value,
            date: block.timestamp,
            reviewed: false,
            id: id
        });

        transactionsById[id] = newTransaction;
        transactionsBySender[msg.sender].push(newTransaction);
        transactionsByReceiver[_receiver].push(newTransaction);

        payable(_receiver).transfer(msg.value);
    }

    function addReview(
        bytes32 _transactionId,
        string memory _title,
        uint8 _rating,
        string memory _text
    )
        external
        transactionSenderOnly(_transactionId)
        transactionExists(_transactionId)
        reviewNotAlreadyExists(_transactionId)
    {
        require(
            bytes(_title).length <= 50,
            "Title must be less than or equal to 50 characters"
        );

        require(
            _rating >= 1 && _rating <= 5,
            "Rating must be between 1 and 5"
        );

        require(
            bytes(_text).length <= 500,
            "Text must be less than or equal to 500 characters"
        );

        Review memory newReview = Review({
            title: _title,
            date: block.timestamp,
            rating: _rating,
            text: _text,
            transactionId: _transactionId
        });

        reviewsById[_transactionId] = newReview;
        transactionsById[_transactionId].reviewed = true;
    }

    function getTransactionById(bytes32 _transactionId)
        external
        view
        returns (Transaction memory)
    {
        return transactionsById[_transactionId];
    }

    function getUnreviewedTransaction(address _addr) 
        external
        view
        returns (Transaction[] memory)
    {
        uint unreviewedCount = 0;
        for (uint i = 0; i < transactionsBySender[_addr].length; i++) {
            if (transactionsBySender[_addr][i].reviewed == false) {
                unreviewedCount++;
            }
        }

        Transaction[] memory unreviewedTransactions = 
            new Transaction[](unreviewedCount);

        uint j = 0;
        for (uint i = 0; i < transactionsBySender[_addr].length; i++) {
            if (transactionsBySender[_addr][i].reviewed == false) {
                unreviewedTransactions[j] = transactionsBySender[_addr][i];
                j++;
            }
        }

        return unreviewedTransactions;
    }

    function getReviewsForSender(address _sender)
        external
        view
        returns (Review[] memory)
    {
        uint reviewCount = 0;
        for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
            if (transactionsBySender[_sender][i].reviewed == true) {
                reviewCount++;
            }
        }

        Review[] memory reviews = new Review[](reviewCount);

        uint j = 0;
        for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
            if (transactionsBySender[_sender][i].reviewed == true) {
                reviews[j] = reviewsById[transactionsBySender[_sender][i].id];
                j++;
            }
        }

        return reviews;
    }

    function getReviewsForReceiver(address _receiver)
        external
        view
        returns (Review[] memory)
    {
        uint reviewCount = 0;
        for (uint i = 0; i < transactionsByReceiver[_receiver].length; i++) {
            if (transactionsByReceiver[_receiver][i].reviewed == true) {
                reviewCount++;
            }
        }

        Review[] memory reviews = new Review[](reviewCount);

        uint j = 0;
        for (uint i = 0; i < transactionsByReceiver[_receiver].length; i++) {
            if (transactionsByReceiver[_receiver][i].reviewed == true) {
                reviews[j] = reviewsById[transactionsByReceiver[_receiver][i].id];
                j++;
            }
        }

        return reviews;
    }

}