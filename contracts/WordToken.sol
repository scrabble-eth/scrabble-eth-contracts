pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract WordToken is ERC721 {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _tokenIds;
    EnumerableSet.AddressSet private currentPlayers;

    mapping(uint256 => uint256) lastUsed;
    bool inProgress;

    constructor() ERC721("WordToken", "WTN") {}

    function newTournament() public returns (bool) {
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
        require(inProgress == false);

        inProgress = true;
        return true;
    }

    function updateWinners(address winner, address loser)
        public
        returns (bool)
    {
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
        address owner = ownerOf(tokenId);

        require(player == owner);
        require(lastUsed[tokenId] + cooldown < timestamp);

        return true;
    }
}
