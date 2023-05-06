pragma solidity ^0.8.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/ReviewSystem.sol";
import "../contracts/ReviewLibrary.sol";
import "../contracts/TransactionLibrary.sol";
import "hardhat/console.sol";

// SPDX-License-Identifier: MIT

contract TestReviewSystem {
    ReviewSystem reviewSystem;
    address acc0; //owner by default
    address acc1;
    address acc2;
    address recipient;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);

        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        recipient = TestsAccounts.getAccount(3);
    }

    /// #value: 1000000000000000000 1 Eth
    /// #sender: account-1

    function testSendTransaction() public payable {
        uint recipientOld = recipient.balance;
        Assert.equal(msg.value, 1000000000000000000, "value should be 1 Eth");
        reviewSystem.sendTransaction{value: 100 wei}(recipient);
        Assert.ok(
            recipientOld < recipient.balance,
            "increased transaction number"
        );
    }

    function testAddReview() public {
        console.log(0);
        reviewSystem.sendTransaction{value: 100 wei}(acc2);

        uint lenghtOld = reviewSystem.getReviewsByReceiver(acc2).length;

        TransactionLibrary.Transaction[]
            memory unreviewedTransactions = reviewSystem
                .getUnreviewedTransactions(acc2);

        bytes32 id = unreviewedTransactions[0].id;
        uint8 rate = 2;

        reviewSystem.addReview(id, "", rate, "");

        uint lenghtnew = reviewSystem.getReviewsByReceiver(acc2).length;

        Assert.ok(lenghtOld < lenghtnew, "increased review number");
    }
}
