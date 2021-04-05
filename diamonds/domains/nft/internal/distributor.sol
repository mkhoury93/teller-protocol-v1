// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../storage/distributor.sol";

contract int_distributor_NFT_v1 is sto_Distributor {
    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param tierIndex Index of the tier.
     * @param nodeIndex Index of the node in the merkle root.
     */
    function _setClaimed(uint256 tierIndex, uint256 nodeIndex) internal {
        uint256 claimedWordIndex = nodeIndex / 256;
        uint256 claimedBitIndex = nodeIndex % 256;
        distributorStore().claimedBitMap[tierIndex][claimedWordIndex] =
            distributorStore().claimedBitMap[tierIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /**
     * @notice It checks the merkle root for a tier if it has already been claimed.
     * @param tierIndex Index of the tier.
     * @param nodeIndex Index of the node in the merkle root.
     */
    function _isClaimed(uint256 tierIndex, uint256 nodeIndex)
        internal
        view
        returns (bool)
    {
        uint256 claimedWordIndex = nodeIndex / 256;
        uint256 claimedBitIndex = nodeIndex % 256;
        uint256 claimedWord =
            distributorStore().claimedBitMap[tierIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }
}
