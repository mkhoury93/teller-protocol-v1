// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../../../contexts/access-control/modifiers/authorized.sol";
import "../storage/tier.sol";
import "diamonds/Roles.sol";

abstract contract ent_Mint_v1 is
    mod_authorized_AccessControl_v1,
    sto_Tier_v1,
    Roles
{
    using Counters for Counters.Counter;

    function addTier(Tier memory newTier)
        external
        authorized(MINTER, msg.sender)
    {
        Tier storage tier =
            tierStore().tiers[tierStore().tierCounter.current()];
        require(
            tier.contributionAsset == address(0),
            "Teller: tier already exists"
        );

        tier.baseLoanSize = newTier.baseLoanSize;
        tier.hashes = newTier.hashes;
        tier.contributionAsset = newTier.contributionAsset;
        tier.contributionSize = newTier.contributionSize;
        tier.contributionMultiplier = newTier.contributionMultiplier;

        tierStore().tierCounter.increment();
    }
}