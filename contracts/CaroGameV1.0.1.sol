// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CaroGame {
    address public owner;

    enum RoomStatus { Waiting, Ready, Started, Closed }

    struct Room {
        address player1;
        address player2;
        RoomStatus status;
        address winner;
    }

    mapping(uint256 => Room) public rooms;
    uint256 public nextRoomId;

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event RoomCreated(uint256 indexed roomId, address indexed player1);
    event RoomJoined(uint256 indexed roomId, address indexed player2);
    event PlayerReady(uint256 indexed roomId, address indexed player);
    event GameStarted(uint256 indexed roomId);
    event GameClosed(uint256 indexed roomId, address indexed winner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyRoomOwner(uint256 roomId) {
        require(msg.sender == rooms[roomId].player1, "Not room owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // --- Ownership ---
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // --- Room Logic ---
    function createRoom() external returns (uint256) {
        uint256 roomId = nextRoomId++;
        rooms[roomId] = Room({
            player1: msg.sender,
            player2: address(0),
            status: RoomStatus.Waiting,
            winner: address(0)
        });
        emit RoomCreated(roomId, msg.sender);
        return roomId;
    }

    function joinRoom(uint256 roomId) external {
        Room storage room = rooms[roomId];
        require(room.player1 != address(0), "Room does not exist");
        require(room.player2 == address(0), "Room already full");
        require(msg.sender != room.player1, "Owner cannot join own room");

        room.player2 = msg.sender;
        room.status = RoomStatus.Ready;

        emit RoomJoined(roomId, msg.sender);
    }

    function readyGame(uint256 roomId) external {
        Room storage room = rooms[roomId];
        require(msg.sender == room.player2, "Only player2 can ready");
        require(room.status == RoomStatus.Ready, "Room not ready");

        emit PlayerReady(roomId, msg.sender);
    }

    function startGame(uint256 roomId) external onlyRoomOwner(roomId) {
        Room storage room = rooms[roomId];
        require(room.player2 != address(0), "No opponent joined");
        require(room.status == RoomStatus.Ready, "Not ready to start");

        room.status = RoomStatus.Started;
        emit GameStarted(roomId);
    }

    function closeGame(uint256 roomId, address winner) external {
        Room storage room = rooms[roomId];
        require(room.status == RoomStatus.Started, "Game not started");
        require(
            msg.sender == winner &&
            (winner == room.player1 || winner == room.player2),
            "Only winner can close"
        );

        room.status = RoomStatus.Closed;
        room.winner = winner;

        emit GameClosed(roomId, winner);
    }
}
