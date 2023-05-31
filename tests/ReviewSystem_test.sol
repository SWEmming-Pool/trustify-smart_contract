// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/ReviewSystem.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {

    ReviewSystem reviewSystem;
    address owner; // By default linked to account(0)
    address sender; // Account 1
    address receiver; // Account 2

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        reviewSystem = new ReviewSystem();
        owner = TestsAccounts.getAccount(0);
        sender = TestsAccounts.getAccount(1);
        receiver = TestsAccounts.getAccount(2);
    }

    /// #value: 1000000000000000000 => 1 ether
    function checkAddress() public payable {
        Assert.equal(msg.value, 1 ether, "Value should be 1ETH");
        Assert.equal(owner, TestsAccounts.getAccount(0), "Invalid owner");
        Assert.equal(sender, TestsAccounts.getAccount(1), "Invalid sender");
        Assert.equal(receiver, TestsAccounts.getAccount(2), "Invalid receiver");
    }

    /// #sender: account-1
    /// #value: 1000000000000000000 => 1 ether 
    function checkSendTransactionOnValidSenderAndValue() public payable {
        uint receiverOldBalance = receiver.balance;
        Assert.equal(msg.sender, sender, "Sender should be account(1)");
        Assert.equal(msg.value, 1 ether, "Value should be 1ETH");
        reviewSystem.sendTransaction{value: 1 ether}(receiver);
        Assert.ok(receiver.balance > receiverOldBalance, "Receiver did not receive the fund");
    }

}
    