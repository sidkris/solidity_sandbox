//SPDX-License-Identifier: GPL-3.0

// smart contract for a decentralized auction

// bidding increment is 100 wei

pragma solidity ^0.8.0;

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    uint public highestBindingBid;
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;


    constructor(){
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number; // current block (on ethereum, it takes approx. 15 secs for a new block to be created)
        endBlock = startBlock + 40320; // there are roughly 40320 blocks created in a week (the duration of this auction)
        ipfsHash = "";
        bidIncrement = 100;
    }


    modifier onlyOwner(){
        require(owner == msg.sender);
        _; // this ensures that a function executes only when the owner calls the function else throws an error
    }

    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    modifier auctionRunning(){
        require(auctionState == State.Running);
        _;
    }

    modifier bidValidation(){
        require(msg.value >= 100);
        _;
    }


    function min(uint a, uint b) pure internal returns(uint){
        if(a <= b){
            return a;
        }
        else{
            return b;
        }
    }

    function placeBid() public payable notOwner afterStart beforeEnd auctionRunning bidValidation{
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);
        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }
        else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);
        
        address payable recipient;
        uint value;

        if (auctionState == State.Canceled) {
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }
        else { // if the auction completed successfully
            if(msg.sender == owner){
                recipient = owner;
                value = highestBindingBid;
            }
            else{
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }
                else{
                    recipient = payable(msg.sender);
                    value =  bids[msg.sender];
                }
            }
        }
        // reset recipient bid to zero so as to not allow participants to exploit withdrawals
        bids[recipient] = 0;
        recipient.transfer(value);

    }   

}



