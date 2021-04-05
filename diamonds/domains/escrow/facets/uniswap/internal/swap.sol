// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../data/escrow.sol";
import "../external/swap-with-router.sol";

abstract contract int_swap is int_swap_v1 {}

abstract contract int_swap_v1 is dat_Escrow, ext_swap_with_router {
    /**
     * @notice Swaps tokens using UniswapV2Router via the platform defined Uniswap contract.
     * @dev The source and destination tokens must be supported by the supplied PriceAggregator.
     * @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param sourceAmount amount of source token to swap.
     * @param minDestination The minimum amount of output tokens that must be received for the transaction not to revert.
     * @return uint256 The destination amount that was acquired from the swap.
     */
    function _swap(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minDestination
    ) private returns (uint256) {
        IPriceAggregator priceAggregator = IPriceAggregator(PROTOCOL);

        require(
            priceAggregator.isTokenSupported(path[0]),
            "UNI_SRC_NOT_SUPPORTED"
        );
        require(
            priceAggregator.isTokenSupported(path[path.length - 1]),
            "UNI_DST_NOT_SUPPORTED"
        );

        return swapWithRouter(path, sourceAmount, minDestination);
    }
}