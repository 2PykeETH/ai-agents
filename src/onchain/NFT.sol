// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NFT
 * @dev Simplified Test NFT contract for basic functionality testing
 */
contract NFT is ERC721 {
    using Strings for uint256;

    uint256 private _tokenIdCounter;
    uint256 private _version = 4;

    // Simplified NFT State
    struct NFTState {
        uint256 userActionCount;
        string currentWeather;
        string currentTimeOfDay;
        uint256 createdAt;
    }

    // Storage
    mapping(uint256 => NFTState) public nftStates;

    // Events
    event NFTMinted(uint256 indexed tokenId, address indexed owner);
    event NFTUpdated(uint256 indexed tokenId, string updateType, string newValue);

    // Predefined weather and time options for testing
    string[] private weatherOptions = ["sunny", "rainy", "cloudt", "snowy", "foggy"];
    string[] private timeOptions = ["morning", "afternoon", "evening", "night"];

    constructor() ERC721("Simple Dynamic NFT", "SDYNFT") {}

    /**
     * @dev Mint a new NFT - anyone can mint for testing
     */
    function mint(address to) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);

        // Initialize NFT state with random values
        nftStates[tokenId] = NFTState({
            userActionCount: 0,
            currentWeather: weatherOptions[_pseudoRandom(tokenId, "weather") % weatherOptions.length],
            currentTimeOfDay: timeOptions[_pseudoRandom(tokenId, "time") % timeOptions.length],
            createdAt: block.timestamp
        });

        emit NFTMinted(tokenId, to);
        return tokenId;
    }

    /**
     * @dev Update weather - anyone can call for testing
     */
    function updateWeather(uint256 tokenId) external {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        string memory newWeather = weatherOptions[_pseudoRandom(block.timestamp, "weather") % weatherOptions.length];
        nftStates[tokenId].currentWeather = newWeather;

        emit NFTUpdated(tokenId, "weather", newWeather);
    }

    /**
     * @dev Update time of day - anyone can call for testing
     */
    function updateTimeOfDay(uint256 tokenId) external {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        string memory newTimeOfDay = timeOptions[_pseudoRandom(block.timestamp, "time") % timeOptions.length];
        nftStates[tokenId].currentTimeOfDay = newTimeOfDay;

        emit NFTUpdated(tokenId, "timeOfDay", newTimeOfDay);
    }

    /**
     * @dev Perform user action - anyone can call for testing
     */
    function performUserAction(uint256 tokenId) external {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        nftStates[tokenId].userActionCount++;

        emit NFTUpdated(tokenId, "userAction", Strings.toString(nftStates[tokenId].userActionCount));
    }

    /**
     * @dev Simple pseudo-random function for testing
     */
    function _pseudoRandom(uint256 seed, string memory salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, seed, salt)));
    }

    /**
     * @dev Override tokenURI to return dynamic metadata
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        NFTState memory state = nftStates[tokenId];

        // Create simple JSON metadata
        string memory json = string(
            abi.encodePacked(
                '{"name": "Simple Dynamic NFT #',
                tokenId.toString(),
                '", "description": "A simple dynamic NFT for testing", "attributes": [',
                '{"trait_type": "Weather", "value": "',
                state.currentWeather,
                '"}, {"trait_type": "Time of Day", "value": "',
                state.currentTimeOfDay,
                '"}, {"trait_type": "User Actions", "value": ',
                state.userActionCount.toString(),
                "}]}"
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", _base64Encode(bytes(json))));
    }

    /**
     * @dev Get NFT state for a token
     */
    function getNFTState(uint256 tokenId) external view returns (NFTState memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return nftStates[tokenId];
    }

    /**
     * @dev Get total supply
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev Simple base64 encoding for metadata
     */
    function _base64Encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, mload(data)) { i := add(i, 3) } {
                let input :=
                    add(
                        add(shl(16, byte(0, mload(add(add(data, i), 32)))), shl(8, byte(1, mload(add(add(data, i), 32))))),
                        byte(2, mload(add(add(data, i), 32)))
                    )

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}