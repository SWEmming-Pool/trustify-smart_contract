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

    // using TransactionLibrary for TransactionLibrary.Transaction[];

    // All transactions by id
    mapping(bytes32 => Transaction) private transactionsById;
    // All reviews by transaction id
    mapping(bytes32 => Review) private reviewsByTransactionId;
    // All transactions/reviews id by sender/receiver
    mapping(address => bytes32[]) private reviewsBySender;
    mapping(address => bytes32[]) private reviewsByReceiver;

    // GETTERS

    function getNumberOfReviewsMade(address _sender) external view returns (uint) {
        uint num = reviewsBySender[_sender].length;
        return num;
    }

    function getNumberOfReviewsReceived(address _receiver) external view returns (uint) {
        uint num = reviewsByReceiver[_receiver].length;
        return num;
    }

    // Getters for reviews by ID

    function getReviewTitle(bytes32 _reviewId) external view returns (string memory) {
        return reviewsByTransactionId[_reviewId].title;
    }

    function getReviewDate(bytes32 _reviewId) external view returns (uint) {
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

    // Getters for transaction by ID
    // getTransactionById serve? Divisa in più getter

    function getTransactionSenderById(bytes32 _id) external view returns (address) {
        return transactionsById[_id].sender;
    }

    function getTransactionReceiverById(bytes32 _id) external view returns (address) {
        return transactionsById[_id].receiver;
    }

    function getTransactionAmountById(bytes32 _id) external view returns (uint) {
        return transactionsById[_id].amount;
    }

    function isTransactionReviewed(bytes32 _id) external view returns (bool) {
        return transactionsById[_id].reviewed;
    }

    function getTransactionDateById(bytes32 _id) external view returns (uint) {
        return transactionsById[_id].date;
    }

    // MODIFIERS

    modifier reviewIsPossible(bytes32 _id) {
        require(
            !transactionsById[_id].reviewed,
            "This transaction is already been reviewed"
        );

        _;
    }

    // modifier transactionSenderOnly(bytes32 _id) {
    //     require(
    //         getTransactionSenderById(_id) == msg.sender,
    //         "Transaction sender is not authorized"
    //     );
    //     _;
    // }

    // modifier transactionExists(bytes32 _id) {
    //     require(
    //         transactionsById[_id],
    //         "No transaction found with the given ID for this address"
    //     );
    //     _;
    // }

    // modifier reviewNotAlreadyExists(bytes32 _id) {
    //     require(
    //         reviewsByTransactionId[_id],
    //         "A review for this transaction already exists"
    //     );
    //     _;
    // }

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

        // transactionsBySender[msg.sender].addTransaction(
        //     msg.sender,
        //     _receiver,
        //     msg.value,
        //     id
        // );
        // transactionsByReceiver[_receiver].addTransaction(
        //     msg.sender,
        //     _receiver,
        //     msg.value,
        //     id
        // );

        payable(_receiver).transfer(msg.value);
        emit TransactionSent(msg.sender, _receiver, msg.value, id);
    }

    function addReview(
        bytes32 _transactionId,
        string memory _title,
        uint8 _rating,
        string memory _text
    ) public reviewIsPossible(_transactionId) {
        // transactionSenderOnly(_transactionId)
        // transactionExists(_transactionId)
        // reviewNotAlreadyExists(_transactionId)
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

    // Non servono più perchè ci sono già le mapping divise

    // function getTransactionForSender(
    //     address _sender,
    //     bytes32 _id
    // ) public view returns (TransactionLibrary.Transaction memory) {
    //     require(
    //         TransactionLibrary.containsTransaction(
    //             transactionsBySender[_sender],
    //             _id
    //         ),
    //         "Transaction not found"
    //     );
    //     return transactionsBySender[_sender].getTransactionById(_id);
    // }

    // function getTransactionForReciver(
    //     address _reciver,
    //     bytes32 _id
    // ) public view returns (TransactionLibrary.Transaction memory) {
    //     require(
    //         TransactionLibrary.containsTransaction(
    //             transactionsByReceiver[_reciver],
    //             _id
    //         ),
    //         "Transaction not found"
    //     );
    //     return transactionsByReceiver[_reciver].getTransactionById(_id);
    // }

    // Non dovrebbe servire l'attributo sender perchè è già nella chiamata al metodo
    // Ritornare un array di bytes32 non dovrebbe rompere web3j per le api

    function getUnreviewdTransactions() external view returns (bytes32[] memory) {
        uint unreviewedCount = 0;
        for(uint i = 0; i < reviewsBySender[msg.sender].length; i++) {
            if(!transactionsById[reviewsBySender[msg.sender][i]].reviewed) {
                unreviewedCount++;
            }
        }

        bytes32[] memory unreviewedTransactions = new bytes32[](unreviewedCount);

        for(uint i = 0; i < unreviewedCount; i++) {
            unreviewedTransactions[i] = reviewsBySender[msg.sender][i];
        }

        return unreviewedTransactions;
    }

    // function getUnreviewedTransactions(
    //     address _sender
    // ) external view returns (TransactionLibrary.Transaction[] memory) {
    //     uint unreviewedCount = 0;

    //     for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
    //         if (
    //             bytes(reviews[transactionsBySender[_sender][i].id].text)
    //                 .length == 0
    //         ) {
    //             unreviewedCount++;
    //         }
    //     }

    //     TransactionLibrary.Transaction[]
    //         memory unreviewedTransactions = new TransactionLibrary.Transaction[](
    //             unreviewedCount
    //         );

    //     uint j = 0;
    //     for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
    //         if (
    //             bytes(reviews[transactionsBySender[_sender][i].id].text)
    //                 .length == 0
    //         ) {
    //             unreviewedTransactions[j] = transactionsBySender[_sender][i];
    //             j++;
    //         }
    //     }

    //     return unreviewedTransactions;
    // }

    // UC09

    // Anche questi coperti dalle mapping divise

    // function getReviewsForSender(
    //     address _sender
    // ) public view returns (ReviewLibrary.Review[] memory) {
    //     uint reviewCount = 0;

    //     for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
    //         if (
    //             bytes(reviews[transactionsBySender[_sender][i].id].text)
    //                 .length > 0
    //         ) {
    //             reviewCount++;
    //         }
    //     }

    //     ReviewLibrary.Review[]
    //         memory reviewsForAddress = new ReviewLibrary.Review[](reviewCount);

    //     uint j = 0;
    //     for (uint i = 0; i < transactionsBySender[_sender].length; i++) {
    //         bytes32 id = transactionsBySender[_sender][i].id;
    //         if (bytes(reviews[id].text).length > 0) {
    //             reviewsForAddress[j] = reviews[id];
    //             j++;
    //         }
    //     }

    //     return reviewsForAddress;
    // }

    // function getReviewsForReciver(
    //     address _reciver
    // ) public view returns (ReviewLibrary.Review[] memory) {
    //     uint reviewCount = 0;

    //     for (uint i = 0; i < transactionsByReceiver[_reciver].length; i++) {
    //         if (
    //             bytes(reviews[transactionsByReceiver[_reciver][i].id].text)
    //                 .length > 0
    //         ) {
    //             reviewCount++;
    //         }
    //     }

    //     ReviewLibrary.Review[]
    //         memory reviewsForAddress = new ReviewLibrary.Review[](reviewCount);

    //     uint j = 0;
    //     for (uint i = 0; i < transactionsByReceiver[_reciver].length; i++) {
    //         bytes32 id = transactionsByReceiver[_reciver][i].id;
    //         if (bytes(reviews[id].text).length > 0) {
    //             reviewsForAddress[j] = reviews[id];
    //             j++;
    //         }
    //     }

    //     return reviewsForAddress;
    // }

}
