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

    Transaction[] private transactions;
    mapping(bytes32 => uint) private trIndex;
    mapping(address => uint[]) private trIndexBySender;
    mapping(address => uint[]) private trIndexByReceiver;
    mapping(bytes32 => Review) private reviewById;
    
    // ==================
    // Modifiers
    // ==================

    modifier transactionSenderOnly(bytes32 _transactionId) {
        require(
            transactions[trIndex[_transactionId]].sender == msg.sender,
            "Only the sender of the transaction can add a review"
        );
        _;
    }

    modifier transactionExists(bytes32 _transactionId) {
        require(
            transactions[trIndex[_transactionId]].sender != address(0),
            "No transaction found with the given ID"
        );
        _;
    }

    modifier notReviewed(bytes32 _transactionId) {
        require(
            transactions[trIndex[_transactionId]].reviewed == false,
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

        uint index = transactions.length;

        transactions.push(
            Transaction({
                sender: msg.sender,
                receiver: _receiver,
                amount: msg.value,
                date: block.timestamp,
                reviewed: false,
                id: id
            })
        );

        trIndexBySender[msg.sender].push(index);
        trIndexByReceiver[_receiver].push(index);

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
        notReviewed(_transactionId)
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

        reviewById[_transactionId] = Review({
            title: _title,
            date: block.timestamp,
            rating: _rating,
            text: _text,
            transactionId: _transactionId
        });

        transactions[trIndex[_transactionId]].reviewed = true;
    }

    function getTransactionById(bytes32 _transactionId)
        external
        view
        returns (Transaction memory)
    {
        return transactions[trIndex[_transactionId]];
    }

    function getUnreviewedTransactions(address _addr) 
        external
        view
        returns (Transaction[] memory)
    {
        uint unreviewedCount = 0;
        for(uint i = 0; i < trIndexBySender[_addr].length; i++) {
            if(transactions[trIndexBySender[_addr][i]].reviewed == false) {
                unreviewedCount++;
            }
        }

        Transaction[] memory unreviewedTransactions = 
            new Transaction[](unreviewedCount);

        for(uint i = 0; i < trIndexBySender[_addr].length; i++) {
            if(transactions[trIndexBySender[_addr][i]].reviewed == false) {
                unreviewedTransactions[i] = transactions[trIndexBySender[_addr][i]];
            }
        }

        return unreviewedTransactions;
    }

    function getReviewsBySender(address _sender)
        external
        view
        returns (Review[] memory)
    {
        uint reviewCount = 0;
        for(uint i = 0; i < trIndexBySender[_sender].length; i++) {
            if(transactions[trIndexBySender[_sender][i]].reviewed == true) {
                reviewCount++;
            }
        }

        Review[] memory reviewsBySender = 
            new Review[](reviewCount);

        for(uint i = 0; i < trIndexBySender[_sender].length; i++) {
            if(transactions[trIndexBySender[_sender][i]].reviewed == true) {
                reviewsBySender[i] = reviewById[
                    transactions[trIndexBySender[_sender][i]].id
                ];
            }
        }

        return reviewsBySender;
    }

    function getReviewsByReceiver(address _receiver)
        external
        view
        returns (Review[] memory)
    {
        uint reviewCount = 0;
        for(uint i = 0; i < trIndexByReceiver[_receiver].length; i++) {
            if(transactions[trIndexByReceiver[_receiver][i]].reviewed == true) {
                reviewCount++;
            }
        }

        Review[] memory reviewsByReceiver = 
            new Review[](reviewCount);

        for(uint i = 0; i < trIndexByReceiver[_receiver].length; i++) {
            if(transactions[trIndexByReceiver[_receiver][i]].reviewed == true) {
                reviewsByReceiver[i] = reviewById[
                    transactions[trIndexByReceiver[_receiver][i]].id
                ];
            }
        }

        return reviewsByReceiver;
    }

}