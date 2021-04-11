// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

import "../shared/libraries/AddressArrayLib.sol";
import "../shared/libraries/NumbersList.sol";

enum LoanStatus { NonExistent, TermsSet, Active, Closed, Liquidated }

/**
 * @notice Represents the terms of a loan based on the consensus of a LoanRequest
 * @param borrower The wallet address of the borrower
 * @param recipient The address where funds will be sent, only applicable in over collateralized loans
 * @param interestRate The consensus interest rate calculated based on all signer loan responses
 * @param collateralRatio The consensus ratio of collateral to loan amount calculated based on all signer loan responses
 * @param maxLoanAmount The consensus largest amount of tokens that can be taken out in the loan by the borrower, calculated based on all signer loan responses
 * @param duration The consensus length of loan time, calculated based on all signer loan responses
 */
struct LoanTerms {
    address payable borrower;
    address recipient;
    uint256 interestRate;
    uint256 collateralRatio;
    uint256 maxLoanAmount;
    uint256 duration;
}

/**
 * @notice Data per borrow as struct
 * @param id The id of the loan for internal tracking
 * @param loanTerms The loan terms returned by the signers
 * @param termsExpiry The timestamp at which the loan terms expire, after which if the loan is not yet active, cannot be taken out
 * @param loanStartTime The timestamp at which the loan became active
 * @param collateral The total amount of collateral deposited by the borrower to secure the loan
 * @param lastCollateralIn The amount of collateral that was last deposited by the borrower to keep the loan active
 * @param principalOwed The total amount of the loan taken out by the borrower, reduces on loan repayments
 * @param interestOwed The total interest owed by the borrower for the loan, reduces on loan repayments
 * @param borrowedAmount The total amount of the loan size taken out
 * @param escrow The address of the escrow contract that holds the funds taken out in the loan on behalf of the borrower
 * @param status The status of the loan currently based on the LoanStatus enum - NonExistent, TermsSet, Active, Closed
 * @param liquidated Flag marking if the loan has been liquidated or not
 */
struct Loan {
    uint256 id;
    address lendingToken;
    address collateralToken;
    LoanTerms loanTerms;
    uint256 termsExpiry;
    uint256 loanStartTime;
    uint256 collateral;
    uint256 lastCollateralIn;
    uint256 principalOwed;
    uint256 interestOwed;
    uint256 borrowedAmount;
    address escrow;
    LoanStatus status;
    bool liquidated;
}

/**
    @notice Borrower request object to take out a loan
    @param borrower The wallet address of the borrower
    @param recipient The address where funds will be sent, only applicable in over collateralized loans
    @param assetAddress The address of the asset for the requested loan
    @param requestNonce The nonce of the borrower wallet address required for authentication
    @param amount The amount of tokens requested by the borrower for the loan
    @param duration The length of time in seconds that the loan has been requested for
    @param requestTime The timestamp at which the loan was requested
 */
struct LoanRequest {
    address payable borrower;
    address recipient;
    address assetAddress;
    uint256 requestNonce;
    uint256 amount;
    uint256 duration;
    uint256 requestTime;
}

/**
    @notice Borrower response object to take out a loan
    @param signer The wallet address of the signer validating the interest request of the lender
    @param assetAddress The address of the asset for the requested loan
    @param responseTime The timestamp at which the response was sent
    @param interestRate The signed interest rate generated by the signer's Credit Risk Algorithm (CRA)
    @param collateralRatio The ratio of collateral to loan amount that is generated by the signer's Credit Risk Algorithm (CRA)
    @param maxLoanAmount The largest amount of tokens that can be taken out in the loan by the borrower
    @param signature The signature generated by the signer in the format of the above Signature struct
 */
struct LoanResponse {
    address signer;
    address assetAddress;
    uint256 responseTime;
    uint256 interestRate;
    uint256 collateralRatio;
    uint256 maxLoanAmount;
    Signature signature;
}

/**
    @notice Represents a user signature
    @param v The recovery identifier represented by the last byte of a ECDSA signature as an int
    @param r The random point x-coordinate of the signature respresented by the first 32 bytes of the generated ECDSA signature
    @param s The signature proof represented by the second 32 bytes of the generated ECDSA signature
 */
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
    @notice Represents loan terms based on consensus values
    @param interestRate The consensus value for the interest rate based on all the loan responses from the signers
    @param collateralRatio The consensus value for the ratio of collateral to loan amount required for the loan, based on all the loan responses from the signers
    @param maxLoanAmount The consensus value for the largest amount of tokens that can be taken out in the loan, based on all the loan responses from the signers
 */
struct AccruedLoanTerms {
    NumbersList.Values interestRate;
    NumbersList.Values collateralRatio;
    NumbersList.Values maxLoanAmount;
}

/**
 * @notice This struct defines the dapp address and data to execute in the callDapp function.
 * @dev It is executed using a delegatecall in the Escrow contract.
 * @param exists Flag marking whether the dapp is a Teller registered address
 * @param unsecured Flag marking if the loan allowed to be used in the dapp is a secured, or unsecured loan
 */
struct Dapp {
    bool exists;
    bool unsecured;
}

/**
 * @notice This struct defines the dapp address and data to execute in the callDapp function.
 * @dev It is executed using a delegatecall in the Escrow contract.
 * @param location The proxy contract address for the dapp that will be used by the Escrow contract delegatecall
 * @param data The encoded function signature with parameters for the dapp method in bytes that will be sent in the Escrow delegatecall
 */
struct DappData {
    address location;
    bytes data;
}

struct MarketStorage {
    mapping(uint256 => Loan) loans;
    uint256 loanIDCounter;
    mapping(address => uint256[]) borrowerLoans;
    AddressArrayLib.AddressArray signers;
    mapping(address => LendingPool) lendingPool;
    // TODO: Moving to an appropriate struct below based on lending asset
    uint256 totalCollateral;
    uint256 totalSupplied;
    uint256 totalBorrowed;
    uint256 totalRepaid;
}

struct LendingPool {
    // ^
    address lendingToken;
    uint256 totalSupplied;
    uint256 totalBorrowed;
    uint256 totalRepaid;
    address[] collateralTokens;
    uint256 totalCollateralInLendingTokens;
}

bytes32 constant MARKET_STORAGE_POS = keccak256("teller.market.storage");

library MarketStorageLib {
    function marketStore() internal pure returns (MarketStorage storage s) {
        bytes32 pos = MARKET_STORAGE_POS;
        assembly {
            s.slot := pos
        }
    }
}
