// this is easier doen with initialFunds because they will be inheriting everthing equally

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract initialFunds {
    uint256 startgameTimer; // = 0
    uint256 gameinitializationTS; // time stamp of when the game was created
    address bank;

    struct playerType {
        address player;
        uint256 share; // we want all players to start with a fair share of the funds
    }

    playerType [] public funds;

    modifier onlyBank() {
        require(address(0) != bank);
        require(msg.sender == bank);
        _;
    }

    constructor () {
        bank = tx.origin;
    }

    function numPlayers() public view returns (uint256) {
        return funds.length;
    }

    function addPlayer(address player, uint256 share) public onlyBank {
        funds.push(playerType(player, share));        
    }

    function resetFunds() public onlyBank {
        delete(funds);
    }

    // Timer is set in seconds thus 100 days = 100 * 24 * 60 * 60
    function setstartgameTimer(uint256 timer) public onlyBank {
        startgameTimer = timer;
        gameinitializationTS = block.timestamp;
    }

    /* This would allow the initalizer to reset the time on filling the lobby, however that is unnecesary
    function resetTimer() public onlyBank {
        gameinitializationTS = block.timestamp;
    }
    */

    function timeLeft() public view returns (uint256) {
        if (0 == startgameTimer) return (0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        if (block.timestamp > gameinitializationTS + startgameTimer) return (0);
        return gameinitializationTS + startgameTimer - block.timestamp;
    }

    // Notes: 
    //  The bank must be initialized with the Arrow token address specified in the "token" parameter. *IMPORTANT: This evenly distributes the money of the bank
        // so in order to keep the game fair, the numPlayers will determine how many Arrows the bank has - otherwise in-game costs would need to be adjusted*
    //  Also the bank has to set call each token's "approve(address of this contract, amount)" with amount set to at least the total initialFunds,
    //  so this contract can transfer the initialFunds. Practically it's best to call 
        //  "approve(this contract, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)".
    function executeFunds(address token) public {
        require(0 != startgameTimer);
        require(block.timestamp > gameinitializationTS + startgameTimer);
        uint256 shares;
        uint256 i;
        uint256 initialFunds = IERC20(token).balanceOf(bank);
        if (IERC20(token).allowance(bank, address(this)) < initialFunds) initialFunds = IERC20(token).allowance(bank, address(this));
        for (i=0; i<funds.length; i++) {
            shares += funds[i].share;
        }
        for (i=0; i<funds.length; i++) {
            require(IERC20(token).transferFrom(bank, funds[i].player, (initialFunds * funds[i].share) / shares));
        }
    }
}