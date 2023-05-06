// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "remix_tests.sol";
import "../contracts/ReviewSystem.sol";
import "contracts/ReviewLibrary.sol";
import "remix_accounts.sol";
import "hardhat/console.sol";

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
        console.log(0);
        reviewSystem.sendTransaction{value: 100 wei}(recipient);

        uint lenghtOld = reviewSystem.getReviewsByReceiver(recipient).length;

        TransactionLibrary.Transaction[]
            memory unreviewedTransactions = reviewSystem
                .getUnreviewedTransactions(acc0);

        reviewSystem.addReview(unreviewedTransactions[0].id, "", 1, "");

        uint lenghtNew = reviewSystem.getReviewsByReceiver(recipient).length;

        Assert.ok(lenghtOld < lenghtNew, "increased review number");
    }
}
