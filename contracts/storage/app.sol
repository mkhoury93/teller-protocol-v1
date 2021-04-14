// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { TellerNFT } from "../nft/TellerNFT.sol";

// Interfaces
import { IUniswapV2Router } from "../shared/interfaces/IUniswapV2Router.sol";

// Libraries
import { PlatformSetting } from "../settings/platform/PlatformSettingsLib.sol";
import { Cache } from "../shared/libraries/CacheLib.sol";

struct AppStorage {
    bool initialized;
    bool platformRestricted;
    mapping(bytes32 => PlatformSetting) platformSettings;
    mapping(address => Cache) assetSettings;
    mapping(string => address) assetAddresses;
    mapping(address => bool) ctokenRegistry;
    IUniswapV2Router uniswapRouter;
    TellerNFT nft;
}

library AppStorageLib {
    function store() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}