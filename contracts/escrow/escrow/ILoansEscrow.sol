// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILoansEscrow {
    function init() external;

    /**
     * @notice it calls a dapp like YearnFinance at a target contract address with specified calldata
     * @param dappAddress address of the target contract address
     * @param dappData encoded abi of the function in our contract we want to call
     */
    function callDapp(address dappAddress, bytes calldata dappData)
        external
        returns (bytes memory);

    /**
     * @notice it approves the spender to spend a maximum amount of a respective token from a token address
     * @param token address of the respective ERC20 token to approve for the spender
     * @param spender address of the respective spender who is approved by the token contract
     */
    function setTokenAllowance(address token, address spender) external;

    /**
     * @notice it allows user to claim their escrow tokens from the RepayFacet
     * @param token address of the respective token contract to claim tokens from
     * @param to address where the tokens should be transferred to
     * @param amount uint256 amount of tokens to be claimed
     */
    function claimToken(
        address token,
        address to,
        uint256 amount
    ) external;
}
