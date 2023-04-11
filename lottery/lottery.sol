//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery{

  address payable[] public players;
  address public manager;

  constructor(){
    manager = msg.sender;
  }

  // user enters the lottery by sending tokens to the smart contract wallet
  receive() external payable{
    require(msg.value == 0.1 ether);
    players.push(payable(msg.sender));
  }

  function getBalance() public view returns(uint){
    require(msg.sender == manager);
    return address(this).balance;
  }

  function random() public view returns(uint){
      // ideally you would want to use a proper random number generator (by using an oracle for instance)
      return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
  }       

   function pickWinner() public returns(address){
       require(msg.sender == manager);
       require(players.length >= 3);

       uint r = random();
       address payable winner;

       uint index = r % players.length;
       winner = players[index];

       winner.transfer(getBalance());
       
       // re-initialize lottery
       players = new address payable[](0);

       // confirm winner address
       return winner;

   } 

}