import { deployments } from 'hardhat'
import { getMarkets } from '../../config/markets'
import { Network } from '../../types/custom/config-types'
import { LendingPool, Loans } from '../../types/typechain'
import { getMarket } from '../../tasks'

interface DeployedMarketArgs {
  lendTokenSym: string
  collTokenSym: string
}

interface FundedMarketArgs {
  market?: DeployedMarketArgs
  amount?: number
}

interface FundedMarketReturn {
  loans: Loans
  lendingPool: LendingPool
}

export const fundedMarket = (args?: FundedMarketArgs): Promise<FundedMarketReturn> =>
  deployments.createFixture(async (hre) => {
    const { deployments, network } = hre
    await deployments.fixture('markets')

    let lendTokenSym: string
    let collTokenSym: string
    if (args?.market) {
      lendTokenSym = args.market.lendTokenSym
      collTokenSym = args.market.collTokenSym
    } else {
      const markets = await getMarkets(<Network>network.name)
      lendTokenSym = markets[0].borrowedToken
      collTokenSym = markets[0].collateralToken
    }

    const market = await getMarket(
      {
        lendTokenSym,
        collTokenSym,
      },
      hre
    )

    // TODO: Fund the market

    return market
  })()
