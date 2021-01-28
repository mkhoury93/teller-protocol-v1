import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { logicNames } from '../test/utils/logicNames'
import { Compound, EscrowFactory, Uniswap } from '../typechain'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {
    deployments: { execute, log, read, deploy, get },
    getNamedAccounts,
    ethers,
  } = hre
  const { deployer } = await getNamedAccounts()

  const settings_ProxyDeployment = await get('Settings_Proxy')
  const escrowFactory_ProxyDeployment = await get('EscrowFactory_Proxy')

  const uniswap_ProxyDeployment = await deploy('Uniswap_Proxy', {
    from: deployer,
    contract: 'DynamicProxy',
    args: [settings_ProxyDeployment.address, logicNames.Uniswap],
  })
  const compound_ProxyDeployment = await deploy('Compound_Proxy', {
    from: deployer,
    contract: 'DynamicProxy',
    args: [settings_ProxyDeployment.address, logicNames.Compound],
  })

  const escrowFactory = (await ethers.getContractAt('EscrowFactory', escrowFactory_ProxyDeployment.address)) as EscrowFactory
  const uniswap = (await ethers.getContractAt('Uniswap', uniswap_ProxyDeployment.address)) as Uniswap
  const compound = (await ethers.getContractAt('Compound', compound_ProxyDeployment.address)) as Compound

  await uniswap.initialize(settings_ProxyDeployment.address)
  await compound.initialize(settings_ProxyDeployment.address)

  await escrowFactory.addDapp(uniswap_ProxyDeployment.address, false)
  await escrowFactory.addDapp(compound_ProxyDeployment.address, true)
}
export default func
func.tags = ['test', 'live']
