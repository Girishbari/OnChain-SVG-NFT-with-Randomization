//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "base64-sol/base64.sol";

contract RandomSVG is ERC721URIStorage, VRFConsumerBase {
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public tokenCounter;

    //SVG parameters
    uint256 public maxNumberOfPaths;
    uint256 public maxNumberOfPathCommand;
    uint256 public size;
    string[] public pathCommands;
    string[] public colors;

    mapping(uint256 => uint256) public tokenIdtoRandomNumber;
    mapping(bytes32 => address) public requestBySender;
    mapping(bytes32 => uint256) public requestIdtoTokenId;

    event unfinishedRandomSVG(uint256 indexed tokenId, uint256 randomNumber);
    event requestRandomSVG(bytes32 indexed requestId, uint256 tokenId);
    event CreatedSVGNFT(uint256 indexed tokenId, string tokenURI);

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyhash,
        uint256 _fee
    )
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("RandomSVG", "R_NFT")
    {
        fee = _fee;
        keyHash = _keyhash;
        tokenCounter = 0;
        maxNumberOfPaths = 10;
        maxNumberOfPathCommand = 5;
        size = 500;
        pathCommands = ["M", "L"];
        colors = ["red", "blue", "green", "yellow", "black", "white"];
    }

    function create() public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee);
        requestBySender[requestId] = msg.sender;
        uint256 tokenId = tokenCounter;
        requestIdtoTokenId[requestId] = tokenId;
        tokenCounter++;
        emit requestRandomSVG(requestId, tokenId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        address nftOwner = requestBySender[requestId];
        uint256 tokenId = requestIdtoTokenId[requestId];
        _safeMint(nftOwner, tokenId);
        tokenIdtoRandomNumber[tokenId] = randomNumber;
        emit unfinishedRandomSVG(tokenId, randomNumber);
    }

    function finishMInt(uint256 tokenId) public {
        require(
            bytes(tokenURI(tokenId)).length <= 0,
            "Token URI is already set"
        );
        require(tokenCounter > tokenId, "TokenId has not been minted yet!");
        require(
            tokenIdtoRandomNumber[tokenId] > 0,
            "Need to wait for chainlink VRF"
        );
        uint256 randomNumber = tokenIdtoRandomNumber[tokenId];
        string memory svg = generateSVG(randomNumber);
        string memory imageURI = svgToImageURI(svg);
        string memory tokenURI = formatTokenURI(imageURI);
        _setTokenURI((tokenId), tokenURI);
        emit CreatedSVGNFT(tokenId, tokenURI);
    }

    function generateSVG(uint256 _randomNumber)
        public
        view
        returns (string memory finalSvg)
    {
        uint256 numberofPaths = (_randomNumber % maxNumberOfPaths) + 1;
        finalSvg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' height='",
                uint2str(size),
                "' width='",
                uint2str(size),
                "'>"
            )
        );
        for (uint256 i = 0; i < numberofPaths; i++) {
            uint256 newRNG = uint256(keccak256(abi.encode(_randomNumber, i)));
            string memory pathSvg = generatePath(newRNG);
            finalSvg = string(abi.encodePacked(finalSvg, pathSvg));
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }

    function generatePath(uint256 _randomNumber)
        public
        view
        returns (string memory pathSvg)
    {
        uint256 numberOfPathCommands = (_randomNumber %
            maxNumberOfPathCommand) + 1;
        pathSvg = "<path d='";
        for (uint256 i = 0; i < numberOfPathCommands; i++) {
            string memory pathCommand = generatePathCommand(
                uint256(keccak256(abi.encode(_randomNumber, size + i)))
            );
            pathSvg = string(abi.encodePacked(pathSvg, pathCommand));
        }
        string memory color = colors[_randomNumber % colors.length];
        pathSvg = string(
            abi.encodePacked(
                pathSvg,
                "' fill='transparent' stroke='",
                color,
                "'/>"
            )
        );
    }

    function generatePathCommand(uint256 _randomNumber)
        public
        view
        returns (string memory pathCommand)
    {
        pathCommand = pathCommands[_randomNumber % pathCommands.length];
        uint256 parameterOne = uint256(
            keccak256(abi.encodePacked(_randomNumber, size * 2))
        );
        uint256 parameterTwo = uint256(
            keccak256(abi.encodePacked(_randomNumber, size * 3))
        );
        pathCommand = string(
            abi.encodePacked(
                pathCommand,
                " ",
                uint2str(parameterOne),
                " ",
                uint2str(parameterTwo)
            )
        );
    }

    function svgToImageURI(string memory svg)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function formatTokenURI(string memory imageURI)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:application/json;base64,";
        return
            string(
                abi.encodePacked(
                    baseURL,
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "Girish NFT", // You can add whatever name here
                                '", "description":"An NFT based on SVG!", "attributes":"", "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
