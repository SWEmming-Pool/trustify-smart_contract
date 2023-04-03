// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ReviewSystem {
    struct Transaction {
        address sender;
        address receiver;
        uint256 amount;
        uint256 date;
        string id;
    }
    struct Review {
        Transaction transaction;
        string title;
        uint256 date;
        uint8 rating;
        string text;
    }

    mapping(address => mapping(string => Review)) public reviews;

    modifier onlySender(address _sender, address _receiver) {
        require(msg.sender == _sender, "Only the sender can leave a review");
        _;
    }

    function addReview(
        Transaction memory _transaction,
        string memory _title,
        uint256 _date,
        uint8 _rating,
        string memory _text
    ) public onlySender(_transaction.sender, _transaction.receiver) {
        require(
            reviews[_transaction.receiver][_transaction.id].date == 0,
            "A review for this transaction already exists"
        );
        Review memory _review = Review(
            _transaction,
            _title,
            _date,
            _rating,
            _text
        );
        reviews[_transaction.receiver][_transaction.id] = _review;
    }

    function searchReview(
        address _receiver,
        string memory _id
    ) public view returns (Review memory) {
        return reviews[_receiver][_id];
    }

    function addTransaction(
        address _sender,
        address _receiver,
        uint256 _amount,
        string memory _id
    ) public {
        Transaction memory transaction = Transaction({
            sender: _sender,
            receiver: _receiver,
            amount: _amount,
            date: block.timestamp, // current block timestamp
            id: _id
        });

        // add the transaction to the reviews mapping
        reviews[_receiver][_id].transaction = transaction;
    }
}
