import { Signers } from '../types/custom/config-types'

export const signers: Record<string, Signers> = {
  kovan: [
    '0x0cA59Bd2255Ae40D4E1e3b939C3a97b5C9dE839b',
    '0x53E88c675f9cb51c8CB33edf090582ac2FFDa01F',
    '0xd380829600546D4B3b6aC5F0d9D5ED97cF799b92',
    '0x8bCd79c2AE760E70573fCFA4e4460a7B3C8A3134',
    '0x312a5217c12aD9b206A0380B4B134ef2b02d09A5',
  ],
  rinkeby: [
    '0x0cA59Bd2255Ae40D4E1e3b939C3a97b5C9dE839b',
    '0x53E88c675f9cb51c8CB33edf090582ac2FFDa01F',
    '0xd380829600546D4B3b6aC5F0d9D5ED97cF799b92',
    '0x8bCd79c2AE760E70573fCFA4e4460a7B3C8A3134',
    '0x312a5217c12aD9b206A0380B4B134ef2b02d09A5',
  ],
  ropsten: [],
  hardhat: [],
  localhost: [],
  mainnet: [],
}
