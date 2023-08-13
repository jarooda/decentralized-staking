pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  event Stake(address, uint256);
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // TODO: Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  mapping(address => uint256) public balances;

  uint256 public constant threshold = 1 ether;

  function stake() public payable {
    require(msg.value > 0, 'Cannot stake 0');
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // TODO: After some `deadline` allow anyone to call an `execute()` function
  //  It should call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  uint256 public deadline = block.timestamp + 72 hours;

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), 'Already completed');
    _;
  }

  bool public openForWithdrawal;
  bool public executed;

  function execute() external notCompleted {
    require(block.timestamp >= deadline, 'Deadline not reached');
    executed = true;
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      openForWithdrawal = false;
    } else {
      openForWithdrawal = true;
    }
  }

  // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() external notCompleted {
    require(block.timestamp >= deadline, 'Deadline not reached');
    require(address(this).balance < threshold, 'Threshold met');

    openForWithdrawal = true;
    payable(msg.sender).transfer(balances[msg.sender]);
  }

  // TODO: Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // TODO: Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}
