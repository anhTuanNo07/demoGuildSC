//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
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

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeCastUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint32 public constant OUT_GUILD_PENALTY_TIME = 2 days;

    // Detail information of guilds
    GuildInformation[] public guildInformation;

    // The accept token 
    IERC20Upgradeable public guildAcceptedToken;

    struct GuildInformation {
        uint256 totalSupply;
        uint256 createdGuildTime;
        uint16 guildHallLevel;
        address guildMaster;
        uint256 guildTicket;
        bool guildPublic;
    }

    // mapping
    mapping(address => uint256) memberToGuild;

    mapping(address => uint256) lastTimeOutGuild;

    // Modifiers
    modifier inGuild() {
        require(
            memberToGuild[msg.sender] != 0,
            'Must be in certain guild'
        );
        _;
    }

    modifier notInGuild() {
        require(
            memberToGuild[msg.sender] == 0,
            'Must be not in certain guild'
        );
        _;
    }

    modifier inTheSameGuild() {
        require(
            msg.sender == guildInformation[memberToGuild[msg.sender] - 1].guildMaster, 
            'Not the master of guild'
        );
        _;
    }

    modifier guildMaster() {
        require(
            msg.sender == guildInformation[memberToGuild[msg.sender] - 1].guildMaster, 
            'Not the master of guild'
        );
        _;
    }

    modifier notGuildMaster() {
        require(
            msg.sender != guildInformation[memberToGuild[msg.sender] - 1].guildMaster, 
            'Be the master of guild'
        );
        _;
    }

    modifier outOfPenaltyTime(address _address) {
        require(
            block.timestamp >= lastTimeOutGuild[_address] + OUT_GUILD_PENALTY_TIME,
            'Have not ended penalty time'
        );
        _;
    }

    modifier publicGuild(uint256 _guildId) {
        require(
            guildInformation[_guildId - 1].guildPublic == true,
            'not a public guild'
        );
        _;
    }

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

    event AddMemberToGuild(
        uint256 guildId,
        address memberAddress    
    );

    event OutOfGuild(
        address memberAddress
    );


    function __MechaGuild_init(IERC20Upgradeable _acceptedToken) public initializer {
        __Ownable_init();

        guildAcceptedToken = _acceptedToken;
    }

    function createGuild(
        uint256 _createdGuildTime,
        address _guildMaster
    ) public notInGuild() {
        guildInformation.push(
            GuildInformation({
                totalSupply: 0,
                createdGuildTime: _createdGuildTime,
                guildHallLevel: 1,
                guildMaster: _guildMaster,
                guildTicket: 0,
                guildPublic: false
            })
        );

        memberToGuild[msg.sender] = guildInformation.length;

        emit AddMemberToGuild(guildInformation.length, msg.sender);
        emit CreatedGuild(guildInformation.length, _guildMaster, _createdGuildTime);
    }

    function changeGuildMaster(
        address _newGuildMaster
    ) external inGuild() inTheSameGuild() guildMaster() {
        guildInformation[memberToGuild[msg.sender] - 1].guildMaster = _newGuildMaster;

        emit ChangedGuildMaster(memberToGuild[msg.sender], _newGuildMaster);
    }

    function returnGuild() public view returns(GuildInformation[] memory) {
        return guildInformation;
    }

    function returnMemberGuild(address _memberAddress) public view returns(uint256) {
        return memberToGuild[_memberAddress];
    }

    function addMemberToGuild(
        address _memberAddress
    ) public inGuild() guildMaster() outOfPenaltyTime(_memberAddress) {
        _addMemberToGuild(memberToGuild[msg.sender], _memberAddress);
    }

    function requestJoinGuild(
        uint256 _guildId
    ) public publicGuild(_guildId) {
        _addMemberToGuild(_guildId, msg.sender);
    }

    function outOfGuild() public inGuild() notGuildMaster() {
        _outOfGuild(msg.sender);
    }

    function kickMember(
        address _memberAddress
    ) public inGuild() guildMaster() inTheSameGuild() {
        _outOfGuild(_memberAddress);
    }

    function changePublicStatus(
        bool status
    ) public inGuild() guildMaster() {
        guildInformation[memberToGuild[msg.sender] - 1].guildPublic = status;
    }

    // function donateGuild

    // function levelUp

    // private function
    function _outOfGuild(address _address) private {
        memberToGuild[_address] = 0;
        lastTimeOutGuild[_address] = block.timestamp;

        emit OutOfGuild(_address);
    }

    function _addMemberToGuild(
        uint256 _guildId,
        address _memberAddress
    ) private {
        memberToGuild[_memberAddress] = _guildId;

        emit AddMemberToGuild(
            _guildId, 
            _memberAddress
        );
    }
}