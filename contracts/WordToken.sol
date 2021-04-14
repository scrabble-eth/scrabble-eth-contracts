pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract WordToken is ERC721, VRFConsumerBase {
    struct Word {
        string word;
        uint256 wordId;
    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    address owner;

    EnumerableSet.AddressSet private currentPlayers;

    mapping(uint256 => uint256) lastUsed;
    bool inProgress;

    mapping(uint256 => string) words;
    mapping(uint256 => uint256) points;
    mapping(uint256 => uint256) availableCount;
    EnumerableSet.UintSet L1Cards;
    EnumerableSet.UintSet L2Cards;
    EnumerableSet.UintSet L3Cards;
    uint256 totalCount;

    Word[] public wordCards;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 seed;

    mapping(bytes32 => address) private requests;
    mapping(address => uint256) private randomResult;

    constructor(uint256 _seed)
        public
        ERC721("WordToken", "WTN")
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088 // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10**18; // 0.1 LINK
        seed = _seed;
        owner = msg.sender;
    }

    function setCards(
        uint256 _wordId,
        string memory _word,
        uint256 _points,
        uint256 _count,
        uint16 _category
    ) public returns (bool) {
        require(msg.sender == owner);
        words[_wordId] = _word;
        points[_wordId] = _points;
        availableCount[_wordId] = _count;
        if (_category == 1) {
            L1Cards.add(_wordId);
        } else if (_category == 2) {
            L2Cards.add(_wordId);
        } else if (_category == 3) {
            L3Cards.add(_wordId);
        }
        totalCount = totalCount + 1;
        return true;
    }

    function buyPack() public returns (bytes32 requestId) {
        requestId = requestRandomness(keyHash, fee, seed);
        requests[requestId] = msg.sender;
        mintCards();
    }

    function expand(
        uint256 randomValue,
        uint256 n,
        uint256 min,
        uint256 mod
    ) private pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] =
                (uint256(keccak256(abi.encode(randomValue, i))) % mod) +
                min;
        }
        return expandedValues;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult[requests[requestId]] = randomness;
        delete requests[requestId];
    }

    function mintCards() private returns (bool) {
        uint256[] memory cardL1 = expand(randomResult[msg.sender], 5, 1, L1Cards.length());
        uint256[] memory cardL2 = expand(randomResult[msg.sender], 3, 1, L2Cards.length());
        uint256[] memory cardL3 = expand(randomResult[msg.sender], 2, 1, L3Cards.length());

        for (uint16 i = 0; i < 5; i++) {
            _safeMint(msg.sender, wordCards.length);
            wordCards.push(
                Word(words[L1Cards.at(cardL1[i])], L1Cards.at(cardL1[i]))
            );
            availableCount[L1Cards.at(cardL1[i])] =
                availableCount[L1Cards.at(cardL1[i])] -
                1;
            if (availableCount[L1Cards.at(cardL1[i])] == 0)
                L1Cards.remove(cardL1[i]);
        }

        for (uint16 i = 0; i < 3; i++) {
            _safeMint(msg.sender, wordCards.length);
            wordCards.push(
                Word(words[L2Cards.at(cardL2[i])], L2Cards.at(cardL2[i]))
            );
            availableCount[L2Cards.at(cardL2[i])] =
                availableCount[L2Cards.at(cardL2[i])] -
                1;
            if (availableCount[L2Cards.at(cardL2[i])] == 0)
                L2Cards.remove(cardL2[i]);
        }

        for (uint16 i = 0; i < 2; i++) {
            _safeMint(msg.sender, wordCards.length);
            wordCards.push(
                Word(words[L3Cards.at(cardL3[i])], L3Cards.at(cardL3[i]))
            );
            availableCount[L3Cards.at(cardL3[i])] =
                availableCount[L3Cards.at(cardL3[i])] -
                1;
            if (availableCount[L3Cards.at(cardL3[i])] == 0)
                L3Cards.remove(cardL3[i]);
        }

        return true;
    }

    function newTournament() public returns (bool) {
        require(msg.sender == owner);
        require(currentPlayers.length() == 1);

        address last = currentPlayers.at(0);
        currentPlayers.remove(last);

        inProgress = false;
        return true;
    }

    function register(address player) public returns (bool) {
        require(inProgress == false);

        currentPlayers.add(player);
        return true;
    }

    function startTournament() public returns (bool) {
        require(msg.sender == owner);
        require(inProgress == false);

        inProgress = true;
        return true;
    }

    function updateWinners(address winner, address loser)
        public
        returns (bool)
    {
        require(msg.sender == owner);
        require(inProgress == true);
        require(
            currentPlayers.contains(winner) && currentPlayers.contains(loser)
        );

        currentPlayers.remove(loser);
        return true;
    }

    function checkRegistered(address player) public view returns (bool) {
        return currentPlayers.contains(player);
    }

    function getFinalWinner() public view returns (address) {
        require(currentPlayers.length() == 1);
        return currentPlayers.at(0);
    }

    function checkUsage(
        address player,
        uint256 tokenId,
        uint256 timestamp,
        uint256 cooldown
    ) public view returns (bool) {
        require(msg.sender == owner);
        address tokenOwner = ownerOf(tokenId);

        require(player == tokenOwner);
        require(lastUsed[tokenId] + cooldown < timestamp);

        return true;
    }
}
