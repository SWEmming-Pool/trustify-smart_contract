// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReviewSystem {
    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        uint256 date;
        bytes32 id;
    }

    struct Review {
        string title;
        uint256 date;
        uint8 rating;
        string text;
    }

    mapping(address => Transaction[]) public transactions;
    mapping(bytes32 => Review) public reviews;

    function _addTransaction(
        address _sender,
        address _receiver,
        uint256 _amount,
        bytes32 _id
    ) private {
        // Create a new transaction struct
        Transaction memory newTransaction = Transaction({
            sender: _sender,
            receiver: _receiver,
            amount: _amount,
            date: block.timestamp,
            id: _id
        });

        // Add the transaction to the sender's list of transactions
        transactions[_sender].push(newTransaction);
    }

    function sendTransaction(address _receiver) external payable {
        require(msg.value > 0, "The sent amount must be greater than 0");

        // Generate a unique ID for the transaction
        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, _receiver, msg.value, block.timestamp)
        );

        _addTransaction(msg.sender, _receiver, msg.value, id);

        // Send the same amount of Ether to the specified receiver address
        payable(_receiver).transfer(msg.value);
    }

    function addReview(
        bytes32 _id,
        string memory _title,
        uint8 _rating,
        string memory _text
    ) public {
        // Check that the transaction exists
        require(
            transactions[msg.sender].length > 0,
            "No transactions found for this address"
        );

        // Find the transaction with the given ID
        Transaction[] memory senderTransactions = transactions[msg.sender];
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

        // Check that a review for this transaction doesn't already exist
        require(
            bytes(reviews[_id].text).length == 0,
            "A review for this transaction already exists"
        );

        // Create a new review struct
        Review memory newReview = Review({
            title: _title,
            date: block.timestamp,
            rating: _rating,
            text: _text
        });

        // Add the review to the reviews mapping
        reviews[_id] = newReview;
    }

    function getTransactionIDs(
        address _address
    ) public view returns (bytes32[] memory) {
        uint length = transactions[_address].length;
        bytes32[] memory ids = new bytes32[](length);

        for (uint i = 0; i < length; i++) {
            ids[i] = transactions[_address][i].id;
        }

        return ids;
    }

    function getReviews(bytes32 _id) public view returns (Review[] memory) {
        // Check that a review for this transaction exists
        require(
            bytes(reviews[_id].text).length > 0,
            "No reviews found for this transaction"
        );

        // Create a new array to store the reviews
        Review[] memory reviewList = new Review[](1);

        // Add the review to the array
        reviewList[0] = reviews[_id];

        // Return the array of reviews
        return reviewList;
    }
}
