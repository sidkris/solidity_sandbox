// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// admin can begin a crowdfunding campaign with a specific funding target and deadline 
// contributors can then tranfer crytpo (ETH in this example) to the smart contract wallet
// if contributions do not meet the target by the deadline, contributors can demand their contributions back
// the admin will then need to create a spending request that can be voted on by contributors
// if more than 50% of contributors vote in favour of the spending request, then the admin is permitted to spend the amount specified in the spending request

contract CrowdFund{
    mapping(address => uint) public contributors;
    address public admin; 
    uint public contributorCount;    
    uint public targetContribution;
    uint public minimumContribution;
    uint public deadline;
    uint public amountRaised;
    struct Request {
        string descriptionOfRequest;
        address payable recipient;
        uint value;
        bool RequestedPaymentCompelted;
        uint numberOfVoters;
        mapping (address => bool) voters;
    }
    mapping (uint => Request) requests;
    uint public requestNumber;


    constructor(uint _targetContribution, uint _deadline){
            targetContribution = _targetContribution;
            deadline = block.timestamp + _deadline;
            minimumContribution = 1000 wei;
            admin = msg.sender;
    }

    modifier fundActive(){
        require(block.timestamp < deadline, "Fund closed.");
        _;
    }

    modifier fundFailure(){
        require(block.timestamp > deadline && amountRaised < targetContribution, "Fund active : you can still make a contribution!");
        _;
    }

    modifier fundSuccess(){
        require(block.timestamp > deadline && amountRaised >= targetContribution, "Fund failed.");
        _;
    }

    modifier minimumContributionCheck() {
        require(msg.value >= minimumContribution, "Please contribute 1000 wei or more.");
        _;
    }

    modifier isContributor() {
        require(contributors[msg.sender] > 0, "You are not a contributor to this fund.");
        _;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "You are not the admin. only the admin can trigger this function.");
        _;
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateSpendingRequestEvent(string _description, address _recipient, uint _value);
    event MakeApprovedPaymentEvent(address _recipient, uint _value);

    function contribute() public payable fundActive  minimumContributionCheck {

        if (contributors[msg.sender] == 0){
            contributorCount++;
        }

        contributors[msg.sender] += msg.value;
        amountRaised += msg.value;
        
        emit ContributeEvent(msg.sender, msg.value);

    }

    function getCurrentBalance() public view returns(uint) {
        return address(this).balance;
    }

    function refundContributions() public fundFailure isContributor {
        address payable recipient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recipient.transfer(value);
        contributors[msg.sender] = 0;
    }

    function createSpendingRequest(string memory _description, address payable _recipient, uint _value) public fundSuccess isAdmin {
        Request storage newRequest = requests[requestNumber];  
        requestNumber++;
        newRequest.descriptionOfRequest = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.RequestedPaymentCompelted = false; // defaults to false
        newRequest.numberOfVoters = 0; //set to zero at initiation of request

        emit CreateSpendingRequestEvent(_description, _recipient, _value);

    }


    function requestVoting(uint _requestNumber) public isContributor {
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.voters[msg.sender] == false, "you have already voted on this request.");
        thisRequest.voters[msg.sender] = true;
        thisRequest.numberOfVoters++;
    }


    function makeApprovedPayment(uint _requestNumber) public isAdmin fundSuccess {
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.RequestedPaymentCompelted == false, "this request has been completed already.");
        require(thisRequest.numberOfVoters > (contributorCount / 2));
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.RequestedPaymentCompelted = true;

        emit MakeApprovedPaymentEvent(thisRequest.recipient, thisRequest.value);

    }

}



