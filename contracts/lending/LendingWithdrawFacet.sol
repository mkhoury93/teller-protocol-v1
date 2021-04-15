// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../contexts2/access-control/roles/RolesMods.sol";
import "../contexts2/access-control/reentry/ReentryMods.sol";
import "../contexts2/pausable/PausableMods.sol";
import { AUTHORIZED } from "../shared/roles.sol";

// Libraries
import { LendingLib } from "./libraries/LendingLib.sol";

contract LendingWithdrawFacet is RolesMods, ReentryMods, PausableMods {
    bytes32 constant FACET_ID = keccak256("LendingFacet");

    /**
     * @notice This event is emitted when an user withdraws tokens from the pool.
     * @param sender address that withdrew the tokens.
     * @param amount of tokens.
     */
    event LendingWithdraw(
        address indexed sender,
        uint256 amount,
        uint256 tTokenAmount
    );

    /**
     * @notice
     */
    function lendingWithdraw(address asset, uint256 assetAmount)
        external
        nonReentry(FACET_ID)
        paused(FACET_ID, false)
    {
        require(assetAmount > 0, "Teller: cannot withdraw 0");

        // Get the current exchange rate
        uint256 rate = LendingLib.exchangeRateCurrent(asset);
        // Calculate Teller token value
        uint256 tTokenAmount = LendingLib.tTokenValue(assetAmount, rate);

        require(
            // TODO: get tToken
            tToken.balanceOf(msg.sender) > tTokenAmount,
            "Teller: withdraw insufficient balance"
        );

        // Perform withdraw
        _lendingWithdraw(assetAmount, tTokenAmount, rate);
    }

    /**
     * @notice
     */
    function lendingWithdrawAll(address asset)
        external
        nonReentry(FACET_ID)
        paused(FACET_ID, false)
        returns (uint256 assetAmount)
    {
        // Get the user's supply balance
        // TODO: get tToken
        uint256 tTokenAmount = tToken.balanceOf(msg.sender);
        require(tTokenAmount > 0, "Teller: withdraw no balance");

        // Get the current exchange rate
        uint256 rate = LendingLib.exchangeRateCurrent(asset);
        // Calculate their balance in lending token value
        assetAmount = LendingLib.assetValue(tTokenAmount, rate);

        // Perform withdraw
        _lendingWithdraw(assetAmount, tTokenAmount, rate);

        // Return how much was withdrawn
        // Note this is for testing purposes
        return assetAmount;
    }

    /**
     * @dev
     */
    function _lendingWithdraw(
        address asset,
        uint256 assetAmount,
        uint256 tTokenAmount,
        uint256 rate
    ) private {
        // Get the LP balance of the asset
        uint256 assetBalance = lendingToken.balanceOf(address(this));

        // Only withdraw how much is needed
        _withdrawFromCompoundIfSupported(assetAmount - assetBalance);

        // Calculate lender's interest earned
        uint256 lenderInterest =
            LendingLib.lenderInterestEarned(asset, rate, msg.sender);
        // Update total interest earned
        LendingLib.s(asset).lenderTotalInterest[msg.sender] += lenderInterest;

        // Update total supplied value taking into account earn interest
        LendingLib.s(asset).lenderTotalSupplied -= assetAmount > lenderInterest
            ? assetAmount - lenderInterest
            : lenderInterest - assetAmount;

        // Burn tToken tokens.
        // TODO: get tToken
        tToken.burn(msg.sender, tTokenAmount);

        // Transfers tokens
        // TODO: get escrow
        escrow.transferTo(asset, msg.sender, assetAmount);

        // Emit event.
        emit LendingWithdraw(msg.sender, assetAmount, tTokenAmount);
    }
}
