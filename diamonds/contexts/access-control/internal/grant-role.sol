// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../data.sol";
import "./has-role.sol";

abstract contract int_grantRole_AccessControl_v1 is
    dat_AccessControl_v1,
    int_hasRole_AccessControl_v1
{
    /**
     * @dev Should only use when circumventing admin checking. See {../entry/grant-role.sol}
     */
    function _grantRole(bytes32 role, address account) internal {
        if (_hasRole(role, account)) return;
        accessControlRolesStore().roles[role].members[account] = true;
        emit RoleGranted(role, account, msg.sender);
    }
}

abstract contract int_grantRole_AccessControl is
    int_grantRole_AccessControl_v1
{}
