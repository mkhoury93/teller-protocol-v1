// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Storage
import { LibLoans } from "./libraries/LibLoans.sol";

contract LoanDataFacet {
    /**
     * @notice Returns the total amount owed for a specified loan.
     * @param loanID The loan ID to get the total amount owed.
     * @return uint256 The total owed amount.
     */
    function getTotalOwed(uint256 loanID) public view returns (uint256) {
        return LibLoans.getTotalOwed(loanID);
    }

    /**
     * @notice Returns the amount of interest owed for a given loan and loan amount.
     * @param loanID The loan ID to get the owed interest.
     * @param amountBorrow The principal of the loan to take out.
     * @return uint256 The interest owed.
     */
    function getInterestOwedFor(uint256 loanID, uint256 amountBorrow)
        public
        view
        returns (uint256)
    {
        return LibLoans.getInterestOwedFor(loanID, amountBorrow);
    }

    function getCollateralNeededInfo(uint256 loanID)
        external
        view
        returns (
            int256 neededInLendingTokens,
            int256 neededInCollateralTokens,
            uint256 escrowLoanValue
        )
    {
        return LibLoans.getCollateralNeededInfo(loanID);
    }

    /**
     * @notice It gets the current liquidation reward for a given loan.
     * @param loanID The loan ID to get the info.
     * @return The value the liquidator will receive denoted in collateral tokens.
     */
    function getLiquidationReward(uint256 loanID) public view returns (int256) {
        return LibLoans.getLiquidationReward(loanID);
    }
}