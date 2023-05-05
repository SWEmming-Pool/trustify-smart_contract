// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "remix_tests.sol";
import "../contracts/ReviewSystem.sol";
import "contracts/ReviewLibrary.sol";
import "remix_accounts.sol";

contract TestReviewSystem {
    ReviewSystem reviewSystem = new ReviewSystem();
    address acc0; //owner by default
    address recipient;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        recipient = TestsAccounts.getAccount(1);
    }

    /// #value: 1000000000000000000 1 Eth
    /// #sender: account-1
    function testSendTransaction() public payable {
        uint recipientOld = recipient.balance;
        Assert.equal(msg.value, 1000000000000000000, "value should be 1 Eth");
        reviewSystem.sendTransaction{value: 1 ether}(recipient);
        Assert.ok(recipientOld < recipient.balance, "asd");
    }

    function testAddReview() public {
        ReviewLibrary.Review[] memory rold = reviewSystem.getReviewsForSender(
            msg.sender
        );
        bytes32 transactionId = "0x1235312";
        string memory title = "Test Review";
        uint8 rating = 4;
        string memory text = "This is a test review.";
        reviewSystem.addReview(transactionId, title, rating, text);
        ReviewLibrary.Review[] memory rnew = reviewSystem.getReviewsForSender(
            msg.sender
        );
        Assert.equal(rold.length + 1, rnew.length, "Review not added");
    }
}
