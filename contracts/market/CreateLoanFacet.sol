// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { PausableMods } from "../contexts2/pausable/PausableMods.sol";
import { RolesMods } from "../contexts2/access-control/roles/RolesMods.sol";
import { AUTHORIZED } from "../shared/roles.sol";

// Libraries
import { LibLoans } from "./libraries/LibLoans.sol";
import { LibCollateral } from "./libraries/LibCollateral.sol";
import { LibConsensus } from "./libraries/LibConsensus.sol";
import { LendingLib } from "../lending/LendingLib.sol";
import {
    PlatformSettingsLib
} from "../settings/platform/PlatformSettingsLib.sol";
import { MaxDebtRatioLib } from "../settings/asset/MaxDebtRatioLib.sol";
import { MaxLoanAmountLib } from "../settings/asset/MaxLoanAmountLib.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { NumbersLib } from "../shared/libraries/NumbersLib.sol";

// Interfaces
import { ILoansEscrow } from "../escrow/interfaces/ILoansEscrow.sol";
// Proxy
import {
    BeaconProxy
} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ITellerNFT } from "../nft/ITellerNFT.sol";

// Storage
import {
    LoanRequest,
    LoanResponse,
    LoanStatus,
    LoanTerms,
    Loan,
    MarketStorageLib
} from "../storage/market.sol";
import { AppStorageLib } from "../storage/app.sol";
import { StakingStorageLib } from "../storage/staking.sol";

contract CreateLoanFacet is RolesMods, PausableMods {
    /**
     * @notice This event is emitted when loan terms have been successfully set
     * @param loanID ID of loan from which collateral was withdrawn
     * @param borrower Account address of the borrower
     * @param recipient Account address of the recipient
     */
    event LoanTermsSet(
        uint256 indexed loanID,
        address indexed borrower,
        address indexed recipient
    );

    /**
     * @notice This event is emitted when a loan has been successfully taken out
     * @param loanID ID of loan from which collateral was withdrawn
     * @param borrower Account address of the borrower
     * @param amountBorrowed Total amount taken out in the loan
     */
    event LoanTakenOut(
        uint256 indexed loanID,
        address indexed borrower,
        uint256 amountBorrowed
    );

    /**
     * @notice Creates a loan with the loan request and terms
     * @param request Struct of the protocol loan request
     * @param responses List of structs of the protocol loan responses
     * @param collateralToken Token address to use as collateral for the new loan
     * @param collateralAmount Amount of collateral required for the loan
     */
    function createLoanWithTerms(
        LoanRequest calldata request,
        LoanResponse[] calldata responses,
        address collateralToken,
        uint256 collateralAmount
    ) external payable paused("", false) authorized(AUTHORIZED, msg.sender) {
        // Perform loan request checks
        CreateLoanLib.validateRequest(request);

        // Get and increment new loan ID
        uint256 loanID = CreateLoanLib.newID();
        {
            Loan storage loan = MarketStorageLib.store().loans[loanID];
            require(
                loan.status == LoanStatus.NonExistent,
                "Teller: loan already exists"
            );

            // Get consensus values from request
            (
                uint256 interestRate,
                uint256 collateralRatio,
                uint256 maxLoanAmount
            ) = LibConsensus.processLoanTerms(request, responses);

            require(
                request.recipient == address(0) ||
                    LibLoans.canGoToEOAWithCollateralRatio(collateralRatio),
                "Teller: under collateralized loan with recipient"
            );

            // TODO: need to store on struct?
            loan.id = loanID;
            loan.status = LoanStatus.TermsSet;
            loan.lendingToken = request.assetAddress;
            loan.collateralToken = collateralToken;
            loan.termsExpiry =
                block.timestamp +
                PlatformSettingsLib.getTermsExpiryTimeValue();
            loan.loanTerms = LoanTerms({
                borrower: request.borrower,
                recipient: request.recipient,
                interestRate: interestRate,
                collateralRatio: collateralRatio,
                maxLoanAmount: maxLoanAmount,
                duration: request.duration
            });
        }

        // Add loanID to borrower list
        MarketStorageLib.store().borrowerLoans[request.borrower].push(loanID);

        // Verify collateral token is acceptable
        require(
            EnumerableSet.contains(
                MarketStorageLib.store().collateralTokens[request.assetAddress],
                collateralToken
            ),
            "Teller: collateral token not allowed"
        );
        // Pay in collateral
        if (collateralAmount > 0) {
            LibCollateral.depositCollateral(loanID, collateralAmount);
        }

        emit LoanTermsSet(loanID, msg.sender, request.recipient);
    }

    function takeOutLoanWithNFTs(
        uint256 loanID,
        uint256 amount,
        uint256[] calldata nftIDs
    ) external paused("", false) {
        Loan storage loan = MarketStorageLib.store().loans[loanID];
        CreateLoanLib.verifyTakeOut(loan, amount);

        EnumerableSet.UintSet storage userStakedNFTs =
            StakingStorageLib.store().stakedNFTs[msg.sender];
        ITellerNFT nft = AppStorageLib.store().nft;
        uint256 allowedLoanSize;
        for (uint256 i; i < nftIDs.length; i++) {
            // NFT must be currently staked
            require(
                EnumerableSet.contains(userStakedNFTs, nftIDs[i]),
                "Teller: borrower nft not staked"
            );
            // Remove NFT from being staked
            EnumerableSet.remove(userStakedNFTs, nftIDs[i]);

            EnumerableSet.add(
                StakingStorageLib.store().loanNFTs[loanID],
                nftIDs[i]
            );

            (, ITellerNFT.Tier memory tier) = nft.getTokenTier(nftIDs[i]);
            allowedLoanSize += ((tier.baseLoanSize *
                tier.contributionMultiplier) / 100);
        }
        require(
            amount <= allowedLoanSize,
            "Teller: insufficient NFT loan size"
        );

        CreateLoanLib.init(loan, amount);

        address loanEscrow = CreateLoanLib.createEscrow(loanID);
    }

    /**
     * @notice Take out a loan
     *
     * @dev collateral ratio is a percentage of the loan amount that's required in collateral
     * @dev the percentage will be *(10**2). I.e. collateralRatio of 5244 means 52.44% collateral
     * @dev is required in the loan. Interest rate is also a percentage with 2 decimal points.
     */
    function takeOutLoan(uint256 loanID, uint256 amount)
        external
        paused("", false)
        authorized(AUTHORIZED, msg.sender)
    {
        Loan storage loan = MarketStorageLib.store().loans[loanID];
        CreateLoanLib.verifyTakeOut(loan, amount);

        // Check that enough collateral has been provided for this loan
        (, int256 neededInCollateral, ) =
            LibLoans.getCollateralNeededInfo(loan.id);
        require(
            neededInCollateral <= int256(loan.collateral),
            "Teller: more collateral required"
        );
        require(
            loan.lastCollateralIn <=
                block.timestamp -
                    (PlatformSettingsLib.getSafetyIntervalValue()),
            "Teller: collateral deposited recently"
        );

        CreateLoanLib.init(loan, amount);

        address loanRecipient;
        bool eoaAllowed =
            LibLoans.canGoToEOAWithCollateralRatio(
                loan.loanTerms.collateralRatio
            );
        if (eoaAllowed) {
            loanRecipient = loan.loanTerms.recipient == address(0)
                ? loan.loanTerms.borrower
                : loan.loanTerms.recipient;
        } else {
            loanRecipient = CreateLoanLib.createEscrow(loanID);
        }

        // Transfer tokens to the borrower.
        // TODO: pull funds from lending escrow
        // TODO: transfer tokens to borrower
        // TODO: update lending total borrowed amount

        emit LoanTakenOut(loanID, loan.loanTerms.borrower, amount);
    }
}

library CreateLoanLib {
    function newID() internal returns (uint256 id_) {
        Counters.Counter storage counter =
            MarketStorageLib.store().loanIDCounter;
        id_ = Counters.current(counter);
        Counters.increment(counter);
    }

    function init(Loan storage loan, uint256 amount) internal {
        loan.borrowedAmount = amount;
        loan.principalOwed = amount;
        loan.interestOwed = LibLoans.getInterestOwedFor(loan.id, amount);
        loan.status = LoanStatus.Active;
        loan.loanStartTime = block.timestamp;
    }

    function createEscrow(uint256 loanID) internal returns (address escrow_) {
        // Create escrow
        escrow_ = AppStorageLib.store().loansEscrowBeacon.cloneProxy(
            abi.encode(ILoansEscrow.init.selector)
        );
        // Save escrow address for loan
        MarketStorageLib.store().loanEscrows[loanID] = ILoansEscrow(escrow_);
    }

    function validateRequest(LoanRequest memory request) internal {
        require(msg.sender == request.borrower, "Teller: not loan requester");
        require(
            LendingLib.debtRatioFor(request.assetAddress, request.amount) <
                MaxDebtRatioLib.get(request.assetAddress),
            "Teller: max supply-to-debt ratio exceeded"
        );
        require(
            MaxLoanAmountLib.get(request.assetAddress) > request.amount,
            "Teller: max loan amount exceeded"
        );
        require(
            PlatformSettingsLib.getMaximumLoanDurationValue() >=
                request.duration,
            "Teller: max loan duration exceeded"
        );
    }

    function verifyTakeOut(Loan storage loan, uint256 amount) internal {
        require(msg.sender == loan.loanTerms.borrower, "Teller: not borrower");
        require(loan.status == LoanStatus.TermsSet, "Teller: loan not set");
        require(
            loan.termsExpiry >= block.timestamp,
            "Teller: loan terms expired"
        );
        require(
            LendingLib.debtRatioFor(loan.lendingToken, amount) <=
                MaxDebtRatioLib.get(loan.lendingToken),
            "Teller: max supply-to-debt exceeded"
        );
        require(
            loan.loanTerms.maxLoanAmount >= amount,
            "Teller: max loan amount exceeded"
        );
    }
}
