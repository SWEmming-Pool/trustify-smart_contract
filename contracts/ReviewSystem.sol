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

    mapping(bytes32 => Transaction) private transactionsById;
    mapping(address => Transaction[]) private transactionsBySender;
    mapping(address => Transaction[]) private transactionsByReceiver;
    mapping(bytes32 => Review) private reviewsById;
    mapping(address => Review[]) private reviewsBySender;
    mapping(address => Review[]) private reviewsByReceiver;

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
            transactionsById[_transactionId].reviewed == false,
            "A review for this transaction already exists"
        );
        _;
    }

    // ==================
    // Public Functions
    // ==================

    function sendTransaction(address _receiver) external payable {
        require(msg.value > 0, "The sent amount must be greater than 0");

        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, _receiver, msg.value, block.timestamp)
        );

        transactionsById[id] = Transaction({
            sender: msg.sender,
            receiver: _receiver,
            amount: msg.value,
            date: block.timestamp,
            reviewed: false,
            id: id
        });

        transactionsBySender[msg.sender].push(transactionsById[id]);
        transactionsByReceiver[_receiver].push(transactionsById[id]);

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

        reviewsById[_transactionId] = Review({
            title: _title,
            date: block.timestamp,
            rating: _rating,
            text: _text,
            transactionId: _transactionId
        });

        transactionsById[_transactionId].reviewed = true;
        reviewsBySender[msg.sender].push(reviewsById[_transactionId]);
        reviewsByReceiver[transactionsById[_transactionId].receiver]
            .push(reviewsById[_transactionId]);
    }

    function getTransactionById(bytes32 _transactionId)
        external
        view
        returns (Transaction memory)
    {
        return transactionsById[_transactionId];
    }

    function getUnreviewedTransactions(address _addr) 
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
        return reviewsBySender[_sender];
    }

    function getReviewsForReceiver(address _receiver)
        external
        view
        returns (Review[] memory)
    {
        return reviewsByReceiver[_receiver];
    }

}