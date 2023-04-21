// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// import "./TransactionLibrary.sol";
// import "./ReviewLibrary.sol";

contract ReviewSystem {
    // STRUCTS

    struct Review {
        string title;
        uint date;
        uint8 rating;
        string text;
        bytes32 transactionId;
    }

    struct Transaction {
        address sender;
        address receiver;
        uint amount;
        uint date;
        bool reviewed;
        bytes32 id;
    }

    // EVENTS

    event TransactionSent(
        address indexed _from,
        address indexed _to,
        uint _amount,
        bytes32 _id
    );

    event ReviewAdded(
        string title,
        uint timestamp,
        uint8 rating,
        string text,
        bytes32 id
    );

    // MAPPINGS

    // All transactions by id
    mapping(bytes32 => Transaction) private transactionsById;
    // All reviews by transaction id
    mapping(bytes32 => Review) private reviewsByTransactionId;
    // All transactions/reviews id by sender/receiver
    mapping(address => bytes32[]) private reviewsBySender;
    mapping(address => bytes32[]) private reviewsByReceiver;

    // GETTERS

    function getNumberOfReviewsMade(
        address _sender
    ) external view returns (uint) {
        uint num = reviewsBySender[_sender].length;
        return num;
    }

    function getNumberOfReviewsReceived(
        address _receiver
    ) external view returns (uint) {
        uint num = reviewsByReceiver[_receiver].length;
        return num;
    }

    // Getters for reviews

    function getReviewTitle(
        bytes32 _reviewId
    ) external view returns (string memory) {
        return reviewsByTransactionId[_reviewId].title;
    }

    function getReviewDate(bytes32 _reviewId) external view returns (uint) {
        return reviewsByTransactionId[_reviewId].date;
    }

    function getReviewRating(bytes32 _reviewId) external view returns (uint8) {
        return reviewsByTransactionId[_reviewId].rating;
    }

    function getReviewText(
        bytes32 _reviewId
    ) external view returns (string memory) {
        return reviewsByTransactionId[_reviewId].text;
    }

    function getReviewTransactionId(
        bytes32 _reviewId
    ) external view returns (bytes32) {
        return reviewsByTransactionId[_reviewId].transactionId;
    }

    // Getters for Transaction

    function getTransactionSenderById(
        bytes32 _id
    ) external view returns (address) {
        return transactionsById[_id].sender;
    }

    function getTransactionReceiverById(
        bytes32 _id
    ) external view returns (address) {
        return transactionsById[_id].receiver;
    }

    function getTransactionAmountById(
        bytes32 _id
    ) external view returns (uint) {
        return transactionsById[_id].amount;
    }

    function getTransactionDateById(bytes32 _id) external view returns (uint) {
        return transactionsById[_id].date;
    }

    // MODIFIERS

    modifier reviewNotAlreadyExists(bytes32 _id) {
        require(
            !transactionsById[_id].reviewed,
            "This transaction is already been reviewed"
        );

        _;
    }
    modifier transactionSenderOnly(bytes32 _id) {
        require(
            transactionsById[_id].sender == msg.sender,
            "Sender is not the transaction sender"
        );
        _;
    }

    modifier transactionExists(bytes32 _id) {
        require(transactionsById[_id].id != 0, "Transaction does not exist");
        _;
    }

    // FUNCTIONS

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

        payable(_receiver).transfer(msg.value);
        emit TransactionSent(msg.sender, _receiver, msg.value, id);
    }

    function review(
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

        reviewsByTransactionId[_transactionId] = Review({
            title: _title,
            date: block.timestamp,
            rating: _rating,
            text: _text,
            transactionId: _transactionId
        });

        reviewsBySender[msg.sender].push(_transactionId);
        reviewsByReceiver[transactionsById[_transactionId].receiver].push(
            _transactionId
        );

        transactionsById[_transactionId].reviewed = true;

        emit ReviewAdded(
            _title,
            block.timestamp,
            _rating,
            _text,
            _transactionId
        );
    }

    function getUnreviewedTransactions(
        address _sender
    ) public view returns (bytes32[] memory) {
        uint unreviewedCount = 0;
        bytes32[] storage transactionIds = reviewsBySender[_sender];

        for (uint i = 0; i < transactionIds.length; i++) {
            if (!transactionsById[transactionIds[i]].reviewed) {
                unreviewedCount++;
            }
        }

        bytes32[] memory unreviewedTransactionIds = new bytes32[](
            unreviewedCount
        );
        uint currentIndex = 0;
        for (uint i = 0; i < transactionIds.length; i++) {
            bytes32 transactionId = transactionIds[i];
            Transaction storage transaction = transactionsById[transactionId];
            if (!transaction.reviewed && transaction.sender == _sender) {
                unreviewedTransactionIds[currentIndex] = transactionId;
                currentIndex++;
            }
        }

        return unreviewedTransactionIds;
    }
}
