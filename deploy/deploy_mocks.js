module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = await getChainId()

    if (chainId == 31337) {
        log("Local Network detected! Deploying mocks.....")
        const LinkToken = await deploy('LinkToken', { from: deployer, log: true })
        //VRFCoordinatorMock takes parameter in contract's constructor
        const VRFCoordinatorMock = await deploy('VRFCoordinatorMock',
            {
                from: deployer,
                log: true,
                args: [LinkToken.address]
            })
        log("Mock Contract Deployed")
    }
}

module.exports.tags = ["all", "rsvg", "svg"]