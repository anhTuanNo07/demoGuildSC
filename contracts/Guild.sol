//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract MechGuild is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{

    using SafeERC20 for IERC20;
    using SafeCastUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint32 public constant OUT_GUILD_PENALTY_TIME = 2 days;
    // uint32 private lastGuildId = 0;

    // Detail information of guilds
    GuildInformation[] public guildInformation;

    // The accept token 
    IERC20 public guildAcceptedToken;

    struct GuildInformation {
        uint256 totalSupply;
        uint256 createdGuildTime;
        uint16 guildLevel;
        address guildMaster;
        uint256 guildTicket;
    }

    // map member with guild joined
    mapping(address => GuildInformation) memberToGuild;

    // modifier guildOwner (guildId) {
    //     require(msg.sender == guildInformation[guildId].guildMaster, 'Not the master of guild');
    //     _;
    // }

    // events
    event CreatedGuild(
        uint256 guildId, 
        address guildMaster, 
        uint256 createdGuildTime
    );

    event ChangedGuildMaster(
        uint256 guildId,
        address newGuildMaster
    );

    event AddMemberToGuild();


    function __MechaGuild_init(IERC20 _acceptedToken) public initializer {
        __Ownable_init();

        guildAcceptedToken = _acceptedToken;
    }

    function createGuild(
        uint256 _createdGuildTime,
        address _guildMaster
    ) external {
        guildInformation.push(
            GuildInformation({
                totalSupply: 0,
                createdGuildTime: _createdGuildTime,
                guildLevel: 1,
                guildMaster: _guildMaster,
                guildTicket: 0
            })
        );

        emit CreatedGuild(guildInformation.length - 1, _guildMaster, _createdGuildTime);
    }

    function changeMasterGuild(
        uint256 _guildId,
        address _newGuildMaster
    ) external {
        require(msg.sender == guildInformation[_guildId].guildMaster, 'Not the master of guild');
        guildInformation[_guildId].guildMaster = _newGuildMaster;

        emit ChangedGuildMaster(_guildId, _newGuildMaster);
    }

    // function addMemberToGuild(

    // ){};

    // function requestToJoinGuild(){};

    // function approveRequestJoinGuild(){};
}