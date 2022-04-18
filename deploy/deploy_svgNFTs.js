const fs = require("fs")
let { networkConfig } = require('../helper-hardhat-config')

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId
}) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = await getChainId()
    log("---------------------------------")
    const SVGNFT = await deploy("SVGNFT", {
        from: deployer,
        log: true
    })
    log(`Deployed simple SVG NFT COntract ${SVGNFT.address}`)
    let filepath = "./img/ecllipse.svg"
    let svg = fs.readFileSync(filepath, { encoding: "utf-8" })

    const svgNFTContract = await ethers.getContractFactory("SVGNFT")
    const accounts = await hre.ethers.getSigners()
    const signer = accounts[0]
    const svgNFT = new ethers.Contract(SVGNFT.address, svgNFTContract.interface, signer)
    const networkName = networkConfig[chainId]['name']
    log(`Verify with: \n npx hardhat verify --network ${networkName} ${svgNFT.address}`)

    let transactionRespone = await svgNFT.create(svg)
    let receipt = await transactionRespone.wait(1)
    log(`We have made an NFT`)
    log(`View your NFT ${await svgNFT.tokenURI(0)}`)


}

module.exports.tags = ['all', 'svg']