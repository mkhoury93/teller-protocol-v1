// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../structs/Cache.sol";

library s_AssetSettings {
    struct Layout {
        mapping(address => Cache) assets;
    }

    bytes32 internal constant POSITION =
        keccak256("teller_protocol.storage.asset_settings");

    function get() internal pure returns (Layout storage l_) {
        bytes32 position = POSITION;

        assembly {
            l_.slot := position
        }
    }
}