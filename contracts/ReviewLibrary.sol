// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ReviewLibrary {
    struct Review {
        string title;
        uint256 date;
        uint8 rating;
        string text;
        bytes32 transactionId;
    }
}
