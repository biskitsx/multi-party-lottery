// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "commit_reveal.sol";

contract Lottery is CommitReveal {
    struct Player {
        address addr;
        uint timestamp;
        int choice; // [0-999: valid choice]; [-1: didnt reveal or illegal choice]
        bool withdraw ;
    }

    // variables
    address payable private contractOwner;
    uint private T1; 
    uint private T2; 
    uint private T3;
    uint private N;
    uint private numPlayer = 0;
    uint public revealedCount = 0;
    uint private reward = 0;
    uint private entryFee = 0.001 ether;
    uint private lotteryTimeStart = 0;
    bool private isRewardTransfer = false;
    mapping(uint => Player) public player;
    mapping(uint => Player) public legalPlayer;
    mapping(address => uint) public addressToPlayer;
    
     // Events
    event PlayerEntered(address indexed playerAddress, uint indexed playerIdx, uint timestamp);
    event ChoiceRevealed(address indexed playerAddress, uint indexed playerIdx, int choice);
    event WinnerPaid(address indexed winnerAddress, uint amount);
    event EntryFeeWithdrawn(address indexed playerAddress, uint indexed playerIdx, uint amount);

    constructor(uint _T1, uint _T2, uint _T3, uint _N) {
        T1 = _T1;
        T2 = _T2;
        T3 = _T3;
        N = _N;
        contractOwner = payable(msg.sender);
    }

    // [STAGE 1]
    function enterLotteryPool(uint choice, string memory salt) public  payable {
        // validate stage 1
        require(lotteryTimeStart == 0 || (block.timestamp >= lotteryTimeStart && block.timestamp < lotteryTimeStart + T1), "Lottery::enterLotteryPool:: wrong stage");
        require(numPlayer < N, "Lottery::enterLotteryPool: Cannot add more player");
        require(msg.value == entryFee,"Lottery::enterLotteryPool: Please fill only 0.001 ether" );
        require(commits[msg.sender].block == 0,"Lottery::enterLotteryPool: You already entered" );

        // create player
        player[numPlayer].addr = msg.sender;
        player[numPlayer].timestamp = block.timestamp;
        player[numPlayer].choice = -1; 
        player[numPlayer].withdraw = false;
        addressToPlayer[msg.sender] = numPlayer;
        reward += msg.value;
        numPlayer++;

        // commit choice
        bytes32 hashSalt = bytes32(abi.encodePacked(salt));
        bytes32 hashChoice = bytes32(abi.encodePacked(choice));
        bytes32 hashCommit = getSaltedHash(hashChoice, hashSalt) ;
        commit(hashCommit);

        // start timer
        if (numPlayer == 1) {
            lotteryTimeStart = block.timestamp;
        }

        emit PlayerEntered(msg.sender, numPlayer - 1, block.timestamp);
    }

    // [STAGE 2]
    function revealChoice(int choice, string memory salt) public {
        // validate stage 2
        uint idx = addressToPlayer[msg.sender];
        require(block.timestamp >= lotteryTimeStart + T1 && block.timestamp < lotteryTimeStart + T1 + T2, "Lottery::revealChoice:: wrong stage");
        require(player[idx].addr == msg.sender, "Lottery::revealChoice:: You are unautorize");
        require(player[idx].choice == -1, "Lottery::revealChoice:: You already reveal your choice");

        // reveal choice
        bytes32 hashSalt = bytes32(abi.encodePacked(salt));
        bytes32 hashChoice = bytes32(abi.encodePacked(choice));
        revealAnswer(hashChoice, hashSalt);
        
        // save valid choice to player
        if (choice >= 0 && choice <= 999) {
            player[idx].choice = choice;
        }
        revealedCount++;

        emit ChoiceRevealed(msg.sender, idx, choice);
    }

    // [STAGE 3]
    function findWinnerAndPay() public payable  {
        // validate stage 3
        require(isRewardTransfer == false, "Lottery:: findWinnerAndPay:: reward is already transfer");
        require(msg.sender == contractOwner, "Lottery::findWinnerAndPay:: You are not the owner");
        require(block.timestamp >= lotteryTimeStart + T1 + T2 && block.timestamp < lotteryTimeStart + T1 + T2 + T3, "Lottery::findWinnerAndPay:: wrong stage");

        // find winner
        int xorVal = 0;
        uint legalPlayerNumber=0;
        for (uint idx = 0; idx < numPlayer; idx++) {
            if (player[idx].choice != -1) {
                xorVal = xorVal ^ player[idx].choice;
                legalPlayer[legalPlayerNumber++]=player[idx];
            }
        }

        // case 1: no one is legal -> contract owner get entire of reward
        if (legalPlayerNumber == 0) {
            contractOwner.transfer(reward);
            emit WinnerPaid(contractOwner, reward);
        } 
        // case 2: someone is legal -> winner get 98 % of reward and owner get 2 % of reward
        else {
            uint hash = uint(keccak256(abi.encodePacked(xorVal)));
            uint winnerNumber = hash % legalPlayerNumber;
            address payable winnerAddr = payable(player[uint(winnerNumber)].addr);
            winnerAddr.transfer((reward * 98) / 100);
            contractOwner.transfer((reward * 2) / 100);
            emit WinnerPaid(winnerAddr, (reward * 98) / 100);
            
        }

        reward = 0;
        isRewardTransfer = true;
    }

    // [STAGE 4]
    function withdraw() public payable {
        // validate stage 4
        uint idx = addressToPlayer[msg.sender];
        require(block.timestamp >= lotteryTimeStart + T1 +T2 + T3, "Lottery:: withdraw:: wrong stage");
        require(player[idx].addr == msg.sender, "Lottery:: withdraw: You are unautorize");
        require(isRewardTransfer == false, "Lottery:: withdraw:: reward is already transfer");
        require(player[idx].withdraw == false, "Lottery:: withdraw:: You already withdraw");

        // withdraw entry fee
        address payable playerAddr = payable(player[idx].addr);
        playerAddr.transfer(entryFee);   
        player[idx].withdraw = true;
        reward -= entryFee;
        emit EntryFeeWithdrawn(msg.sender, idx, entryFee);
    }
}
