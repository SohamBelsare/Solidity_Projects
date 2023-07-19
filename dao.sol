// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract demo{
    struct proposal{
        uint id;
        string description;
        uint amount;
        address payable receipient;
        uint votes;
        uint end;
        bool isexecuted;
    }

    mapping (address=>bool) private  isInvestor;
    mapping (address=>uint) public  numOfshares;
    mapping (address =>mapping (uint=>bool)) public isVoted;
    mapping (address =>mapping (address=>bool)) public withdrawlStatus;
    address[] public investorlist;
    mapping (uint=>proposal)public proposals;

    uint public totalShares;
    uint public availableFunds;
    uint public contributionTimeEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public manager;


    constructor(uint _contributionTimeEnd,uint _voteTime,uint _quorum){
        require(_quorum>0 && _quorum<100,"not valid values");
        contributionTimeEnd=block.timestamp+_contributionTimeEnd;
        voteTime=_voteTime;
        quorum=_quorum;
        manager=msg.sender;
    }

    modifier onlyInvestor(){
        require(isInvestor[msg.sender]==true,"you are not an investor");
        _;
    }
    modifier onlyManager(){
        require(manager==msg.sender,"you are not an manager");
        _;
    }



    function contribution() public payable {
        require(contributionTimeEnd>=block.timestamp,"contribution time ended");
        require(msg.value>0,"send more than 0 ether");
        isInvestor[msg.sender]=true;
        numOfshares[msg.sender]=numOfshares[msg.sender]+msg.value;
        totalShares=totalShares+msg.value;
        availableFunds=availableFunds+msg.value;
        investorlist.push(msg.sender);
    }


    function reedemShare(uint amount)public onlyInvestor{
        require(numOfshares[msg.sender]>=amount,"you don't have enough shares");
        require(availableFunds>=amount,"not enough funds");
        numOfshares[msg.sender]-=amount;
        if(numOfshares[msg.sender]==0){
            isInvestor[msg.sender]=false;
        }
        availableFunds-=amount;
        payable (msg.sender).transfer(amount);
    }


    function transferShare(uint amount,address to)public onlyInvestor{
        require(availableFunds>=amount,"not enough funds");
        require(numOfshares[msg.sender]>=amount,"not enough shares to transfer");
        numOfshares[msg.sender]-=amount;
        if(numOfshares[msg.sender]==0){
            isInvestor[msg.sender]=false;
        }
        numOfshares[to]+=amount;
        isInvestor[to]=true;
        investorlist.push(to);
    }


    function createProposal(string calldata description,uint amount,address payable receiptent)public onlyManager{
        require(availableFunds>=amount,"not enough funds");
        proposals[nextProposalId]=proposal(nextProposalId,description,amount,receiptent,0,block.timestamp+voteTime,false);
        nextProposalId++;
    }


    function voteProposal(uint proposalId)public onlyInvestor{
        proposal storage proposal1 = proposals[proposalId];
        require(isVoted[msg.sender][proposalId]==false,"you have alreaqdy voted");
        require(proposal1.end>=block.timestamp,"voting time ended");
        require(proposal1.isexecuted==false,"it is already executed");
        isVoted[msg.sender][proposalId]=true;
        proposal1.votes+=numOfshares[msg.sender];
    }


    function executeProposal(uint proposalId)public onlyManager{
        proposal storage proposal1=proposals[proposalId];
        require(((proposal1.votes*100)/totalShares)>=quorum,"MAJORITY DOESN'T SUPPORT");
        proposal1.isexecuted=true;
        availableFunds-=proposal1.amount;
        _transfer(proposal1.amount,proposal1.receipient);
    }


    function _transfer(uint amount,address payable receipient)private  {
        receipient.transfer(amount);
    }

    
    function proposalList()public view returns(proposal []memory){
        proposal[] memory arr=new proposal[](nextProposalId-1);
        for (uint i=0; i<=nextProposalId; i++){
            arr[i]=proposals[i];
        }
        return arr; 
    }



}


