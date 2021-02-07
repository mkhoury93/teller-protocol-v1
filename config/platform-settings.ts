export type PlatformSetting = {
  processOnDeployment: boolean;
  value: number | string;
  min: number | string;
  max: number | string;
};

const platformSettingConfigsByNetwork: Record<string, Record<string, PlatformSetting>> = {
  mainnet: {
    RequiredSubmissionsPercentage: {
      processOnDeployment: true,
      value: 8000,
      min: 0,
      max: 10000,
    },
    MaximumTolerance: {
      processOnDeployment: true,
      value: 0,
      min: 0,
      max: 10000,
    },
    ResponseExpiryLength: {
      processOnDeployment: true,
      value: 900,
      min: 0,
      max: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
    },
    SafetyInterval: {
      processOnDeployment: true,
      value: 300,
      min: 0,
      max: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
    },
    TermsExpiryTime: {
      processOnDeployment: true,
      value: 3600,
      min: 0,
      max: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
    },
    LiquidateEthPrice: {
      processOnDeployment: true,
      value: 9500,
      min: 0,
      max: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
    },
    MaximumLoanDuration: {
      processOnDeployment: true,
      value: 5184000,
      min: 0,
      max: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
    },
    CollateralBuffer: {
      processOnDeployment: true,
      value: 1500,
      min: 0,
      max: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
    },
    OverCollateralizedBuffer: {
      processOnDeployment: true,
      value: 13000,
      min: 11000,
      max: 50000,
    },
    StartingBlockOffsetNumber: {
      processOnDeployment: true,
      value: 40,
      min: 0,
      max: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
    },
    RequestLoanTermsRateLimit: {
      processOnDeployment: true,
      value: 86400,
      min: 0,
      max: '115792089237316195423570985008687907853269984665640564039457584007913129639935',
    },
  },
};

export const platformSettings = (network: string) => platformSettingConfigsByNetwork[network];
