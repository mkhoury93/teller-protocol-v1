// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../shared/libraries/NumbersList.sol";

// Interfaces
import { ILoansEscrow } from "../escrow/interfaces/ILoansEscrow.sol";
import { ICollateralEscrow } from "../market/collateral/ICollateralEscrow.sol";
import { ITToken } from "../lending/ttoken/ITToken.sol";
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

enum LoanStatus { NonExistent, TermsSet, Active, Closed, Liquidated }

struct Loan {
    // The id of the loan for internal tracking
    uint256 id;
    // The asset lent out for the loan
    address lendingToken;
    // The token used as collateral for the loan
    address collateralToken;
    // The loan terms returned by the signers
    LoanTerms loanTerms;
    // The status of the loan
    LoanStatus status;
    // The total amount of the loan taken out by the borrower, reduces on loan repayments
    uint256 principalOwed;
    // The total interest owed by the borrower for the loan, reduces on loan repayments
    uint256 interestOwed;
    // The total amount of the loan size taken out
    uint256 borrowedAmount;
    // The timestamp at which the loan terms expire, after which if the loan is not yet active, cannot be taken out
    uint256 termsExpiry;
    // The timestamp at which the loan became active
    uint256 loanStartTime;
}

/**
 * @notice Borrower request object to take out a loan
 * @param borrower The wallet address of the borrower
 * @param recipient The address where funds will be sent, only applicable in over collateralized loans
 * @param assetAddress The address of the asset for the requested loan
 * @param requestNonce The nonce of the borrower wallet address required for authentication
 * @param amount The amount of tokens requested by the borrower for the loan
 * @param duration The length of time in seconds that the loan has been requested for
 * @param requestTime The timestamp at which the loan was requested
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
 * @notice Borrower response object to take out a loan
 * @param signer The wallet address of the signer validating the interest request of the lender
 * @param assetAddress The address of the asset for the requested loan
 * @param responseTime The timestamp at which the response was sent
 * @param interestRate The signed interest rate generated by the signer's Credit Risk Algorithm (CRA)
 * @param collateralRatio The ratio of collateral to loan amount that is generated by the signer's Credit Risk Algorithm (CRA)
 * @param maxLoanAmount The largest amount of tokens that can be taken out in the loan by the borrower
 * @param signature The signature generated by the signer in the format of the above Signature struct
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
 * @notice Represents a user signature
 * @param v The recovery identifier represented by the last byte of a ECDSA signature as an int
 * @param r The random point x-coordinate of the signature respresented by the first 32 bytes of the generated ECDSA signature
 * @param s The signature proof represented by the second 32 bytes of the generated ECDSA signature
 */
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @notice Represents loan terms based on consensus values
 * @param interestRate The consensus value for the interest rate based on all the loan responses from the signers
 * @param collateralRatio The consensus value for the ratio of collateral to loan amount required for the loan, based on all the loan responses from the signers
 * @param maxLoanAmount The consensus value for the largest amount of tokens that can be taken out in the loan, based on all the loan responses from the signers
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
    // Holds the index for the next loan ID
    Counters.Counter loanIDCounter;
    // Maps loanIDs to loan data
    mapping(uint256 => Loan) loans;
    // Maps loanIDs to escrow address to list of held tokens
    mapping(uint256 => ILoansEscrow) loanEscrows;
    // Maps loanIDs to list of tokens owned by a loan escrow
    mapping(uint256 => EnumerableSet.AddressSet) escrowTokens;
    // Maps collateral token address to a LoanCollateralEscrow that hold collateral funds
    mapping(address => ICollateralEscrow) collateralEscrows;
    // Maps accounts to owned loan IDs
    mapping(address => uint256[]) borrowerLoans;
    // Maps lending token to overall amount lent out for loans
    mapping(address => uint256) totalBorrowed;
    // Maps lending token to overall amount repaid from loans
    mapping(address => uint256) totalRepaid;
    // Maps lending token to overall amount of interest collected from loans
    mapping(address => uint256) totalInterestRepaid;
    // Maps lending token to overall amount of interest collected from loans
    mapping(address => ITToken) tTokens;
    // Maps lending token to list of signer addresses who are only ones allowed to verify loan requests
    mapping(address => EnumerableSet.AddressSet) signers;
    // Maps lending token to list of allowed collateral tokens
    mapping(address => EnumerableSet.AddressSet) collateralTokens;
}

bytes32 constant MARKET_STORAGE_POS = keccak256("teller.market.storage");

library MarketStorageLib {
    function store() internal pure returns (MarketStorage storage s) {
        bytes32 pos = MARKET_STORAGE_POS;
        assembly {
            s.slot := pos
        }
    }
}
