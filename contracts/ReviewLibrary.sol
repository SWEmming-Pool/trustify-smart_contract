// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ReviewLibrary {
    struct Review {
        string title;
        uint256 date;
        uint8 rating;
        string text;
    }

    function addReview(
        Review[] storage self,
        string _title;
        uint256 _date;
        uint8 _rating;
        string _text;
    ) internal {
        Review memory newReview = Review({
            title: _title,
            date: _date,
            rating: _rating,
            text: _text
        });

        self.push(newReview);
    }
}
