// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ReviewLibrary {
    struct Review {
        string title;
        uint256 date;
        uint8 rating;
        string text;
    }

    //     function getReview(
    //         mapping(bytes32 => Review) storage self,
    //         bytes32 _id
    //     ) internal view returns (Review memory) {
    //         // Check that a review for this transaction exists
    //         require(
    //             bytes(self[_id].text).length > 0,
    //             "No reviews found for this transaction"
    //         );

    //         Review memory myreview = self[_id];

    //         return myreview;
    //     }
}
