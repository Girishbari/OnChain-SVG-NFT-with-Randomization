// start from patrick video timestamp 2:15:12

let {
    networkConfig,
} = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
    const { deploy, get, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();
    let linkTokenAddress;
    let vrfCoordinatorAddress;

    if (chainId == 31337) {
        let linkToken = await get("LinkToken");
        let VRFCoordinatorMock = await get("VRFCoordinatorMock");
        linkTokenAddress = linkToken.address;
        vrfCoordinatorAddress = VRFCoordinatorMock.address;
    } else {
        linkTokenAddress = networkConfig[chainId]["linkToken"];
        vrfCoordinatorAddress = networkConfig[chainId]["vrfCoordinator"];
    }
    const keyHash = networkConfig[chainId]["keyHash"];
    const fee = networkConfig[chainId]["fee"];
    args = [vrfCoordinatorAddress, linkTokenAddress, keyHash, fee];
    log("----------------------------------------------------");

    const RandomSVG = await deploy("RandomSVG", {
        from: deployer,
        log: true,
        args: args
    })
    log(`Deployed simple RandomSVG NFT COntract ${RandomSVG.address}`)

    const networkName = networkConfig[chainId]["name"]
    log(`Verify with: \n npx hardhat verify --network ${networkName} ${RandomSVG.address} ${args.toString().replace(/,/g, " ")}`)

    //fund link
    const linkTokenContract = await ethers.getContractFactory("LinkToken")
    const accounts = await hre.ethers.getSigners()
    const signer = accounts[0]
    const linkToken = new ethers.Contract(
        linkTokenAddress,
        linkTokenContract.interface,
        signer
    )
    let fund_tx = await linkToken.transfer(RandomSVG.address, fee)
    await fund_tx.wait(1)

    // Creating an NFT using random number
    let RandomSVGContract = await ethers.getContractFactory("RandomSVG")
    const randomSVG = new ethers.Contract(RandomSVG.address, RandomSVGContract.interface, signer)
    let creation_tx = await randomSVG.create({ gasLimit: 300000 })
    let receipt = await creation_tx.wait(1)
    let tokenId = receipt.events[3].topics[2];
    // log(`NFT is made with ${tokenId.toString()}`)
    log(`let wait for chainlink Node to respond...`)
    if (chainId != 31337) {

    } else {
        const VRFCoordinatorMock = await deployments.get("VRFCoordinatorMock");
        vrfCoordinator = await ethers.getContractAt(
            "VRFCoordinatorMock",
            VRFCoordinatorMock.address,
            signer
        );
        let transactionResponse = await vrfCoordinator.callBackWithRandomness(
            receipt.logs[3].topics[1],
            77777,
            randomSVG.address
        );
        await transactionResponse.wait(1);
        log(`Now let's finish the mint...`);
        let finish_tx = await randomSVG.finishMInt(tokenId, { gasLimit: 2000000, gasPrice: 20000000000 });
        await finish_tx.wait(1);
        log(`You can view the tokenURI here ${await randomSVG.tokenURI(0)}`);

    }
};

module.exports.tags = ["all", "rsvg"];

