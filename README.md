## Multi Party Lottery 🎰

### *Description*
 The Lottery contract facilitates a **decentralized** lottery game where participants commit to a choice, reveal it later, and potentially win a reward based on their choices. 🎲 

> This README provides an overview of the Lottery contract, including its functions, stages, events and variables. For detailed implementation, refer to the [Solidity code](https://github.com/biskitsx/multi-party-lottery/lottery.sol).


---

### *Etherscan.io*
You can see my contract and transaction on Ethereum’s Sepolia Testnet by clicking on the provided links below.

| **Account**          |Link Address                                                                              |
|---------------------------------------------|------------------------------------------------------------------------------|
| **Contract Owner:**                         | [0x3a0961A415ceD5848fF49ca9EdC719E904D80D9f](https://sepolia.etherscan.io/address/0x3a0961A415ceD5848fF49ca9EdC719E904D80D9f)           |
| **Player 1:**                               | [0x26bAc89Ca4B3c9a2511840FEed637154164FCdCb](https://sepolia.etherscan.io/address/0x26bAc89Ca4B3c9a2511840FEed637154164FCdCb)                   |
| **Player 2:**                               | [0xdf0a2E402329B6FB0E4E861864a6E741eb15eA88](https://sepolia.etherscan.io/address/0xdf0a2E402329B6FB0E4E861864a6E741eb15eA88)                   |
| **Player 3:**                               | [0x88DbeBAcA04cb45a26a33b8BBc7aBa18BA3ddD8f](https://sepolia.etherscan.io/address/0x88DbeBAcA04cb45a26a33b8BBc7aBa18BA3ddD8f)                   |


---
### *Game Conceptual*

The Lottery contract operates in four distinct stages:

1. ***Stage 1: Entering the Lottery Pool:*** (`T1` seconds)

    This stage allows participants to join the lottery pool by submitting their chosen numbers and paying the required entry fee `0.001 Ether`.

2. ***Stage 2: Revealing Choices:*** (`T2` seconds)

    This stage ensures transparency by allowing participants to reveal the numbers they committed to during Stage 1.

1. ***Stage 3: Determining Winners and Transfer Reward:*** (`T3` seconds)
  
    <!-- The contract owner determines the winner based on the XOR value of valid choices. -->
   * If valid choices exist, the winner receives 98% of the reward, while the contract owner receives 2%. The contract owner determines the winner based on the XOR value of valid choices.
        ```
            winner = (player[0].choice ⊕ player[1].choice  ⊕ ... ⊕ player[num_participant-1].choice ) % num_participant
        ```
   * If no valid choices exist, the contract owner receives the entire reward.
   * This stage ensures fairness in selecting the winner and distributing the reward.

2. ***Stage 4: Withdrawal:*** (After Stage 3)
    
    This stage allows participants to reclaim their entry fee in the event that contract owner fails to determine a winner within a specified time.
---

### *Contructor*

| Parameter | Type  | Description                              |
|-----------|-------|------------------------------------------|
| `_T1`     | `uint`| Duration of Stage 1 in seconds.         |
| `_T2`     | `uint`| Duration of Stage 2 in seconds.         |
| `_T3`     | `uint`| Duration of Stage 3 in seconds.         |
| `_N`      | `uint`| Maximum number of players allowed.      |


--- 
### *Functions References*

1. ***enterLotteryPool***

    Allows a participant to enter the lottery pool by committing to a choice along with salt and pay entry fee (`0.001 ether`).
    ```solidity
    function enterLotteryPool(uint choice, string memory salt) public  payable 
    ```

    | Parameter | Type | Description |
    | :-------- | :----| :---------- | 
    | `choice` | `int`| Choose a lottery number (0-999) |
    | `salt`   | `string` | Add salt for more security |

2. ***revealChoice***

    Participants can reveal their committed choice during the specified time frame.
    ```solidity
    function revealChoice(uint choice, string memory salt) public 
    ```

    | Parameter | Type | Description |
    | :-------- | :----| :---------- | 
    | `choice` | `uint`| Committed lottery number (0-999) |
    | `salt`   | `string` | Salt used during commitment |

3. ***findWinnerAndPay***

    The contract owner determines the winner based on revealed choices and distributes the reward accordingly.
    ```solidity
    function findWinnerAndPay() public payable 
    ```

4. ***withdraw***

    Participants can withdraw their entry fee after the contract owner didn't find winner in a time.
    ```solidity
    function withdraw() public payable 
    ```





### *Events*

| Event              | Description                                                                                  |
|--------------------|----------------------------------------------------------------------------------------------|
| `PlayerEntered`    | Fired when a participant enters the lottery pool.                                            |
| `ChoiceRevealed`   | Fired when a participant reveals their choice.                                                |
| `WinnerPaid`       | Fired when the winner is paid.                                                               |
| `ContractOwnerPaid`| Fired when the contract owner receives the all of reward                              |
| `EntryFeeWithdrawn`| Fired when a participant withdraws their entry fee.                                           |

---

### *Variables Reference*

| Variable          | Type     | Description                                                                                      |
|-------------------|----------|--------------------------------------------------------------------------------------------------|
| `T1`, `T2`, `T3` | `uint`   | Durations for each stage.                                                                       |
| `N`               | `uint`   | Maximum number of players allowed.                                                               |
| `numPlayer`       | `uint`   | Current number of players.                                                                       |
| `revealedCount`   | `uint`   | Number of players who have revealed their choices.                                                 |
| `contractOwner`   | `address`| Address of the contract owner.                                                                  |
| `reward`          | `uint`   | Total reward accumulated in the pool.                                                           |
| `entryFee`        | `uint`   | Cost of entry per player (`0.001 ether`).                                                                       |
| `lotteryTimeStart`| `uint`   | Timestamp when the lottery begins.                                                              |
| `isRewardTransfer`| `bool`   | Flag indicating if the reward has been transferred.                                              |
| `player`        | `mapping(uint => Player)` | Maps player index to player data.                                                             |
| `legalPlayer`   | `mapping(uint => Player)` | Maps legal player index to legal player data.                                                   |
| `addressToPlayer`| `mapping(address => uint)`| Maps player address to player index.                                                          |


