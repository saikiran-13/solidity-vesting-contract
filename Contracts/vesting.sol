// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";


contract vesting{

    IERC20 public token;
    uint public tokensLeft;
    using safeMath for uint256;


    struct beneficiarydata{
        address addressOfToken;
        address beneficiary;
        uint noOfTokens;
        uint cliff;
        uint startTime;
        uint duration;
        uint slicePeriod;
        bool locked;
    }

    mapping (address => beneficiarydata[]) public beneficiaryDetails; 
    mapping (address => mapping(uint => uint)) public releasedTokens;
    mapping (address => mapping(address => bool)) public whitelist;

    event tokensLocked(address Tokenaddrress,uint tokens,uint duration);
    event tokensWithdrawn(address beneficiary,uint tokens);
    event whitelisted(address);
    event tokensUnLocked(uint,uint,uint,uint,uint);


    function whitelistTokens(address _tokenaddress) external {
        whitelist[msg.sender][_tokenaddress] = true;
        emit whitelisted(_tokenaddress);

    }

    function checkBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }

    function lockTokens(address _tokenaddress,uint _noOfTokens,uint _cliff,uint _duration,uint _sliceperiod) external{
        
        require(whitelist[msg.sender][_tokenaddress],"Token is not allowed");
        require(_noOfTokens>0);
        token = IERC20(_tokenaddress);
        beneficiarydata memory person = beneficiarydata({
            addressOfToken:_tokenaddress,
            beneficiary:msg.sender,
            noOfTokens:_noOfTokens,
            cliff:_cliff,
            startTime: block.timestamp + _cliff,
            duration:_duration,
            slicePeriod:_sliceperiod,
            locked:true
        });

        beneficiaryDetails[msg.sender].push(person);
        token.transferFrom(msg.sender,address(this),_noOfTokens);
        emit tokensLocked(_tokenaddress,_noOfTokens,beneficiaryDetails[msg.sender][0].duration);
    }
   
    function withdrawTokens(uint8 index) external {
        // require(block.timestamp>beneficiaryDetails[msg.sender].startTime);
        // require(releasedTokens[msg.sender]<beneficiaryDetails[msg.sender].noOfTokens,"Tokens already withdrawn");
        // tokensLeft = unlockTokens(index);
        //require(tokensLeft!=0);
        token = IERC20(beneficiaryDetails[msg.sender][index].addressOfToken);
        tokensLeft=unlockTokens(index);
        token.transfer(msg.sender,tokensLeft);
        releasedTokens[msg.sender][index]+=tokensLeft;
        //address Tokenaddrress = beneficiaryDetails[msg.sender][index].addressOfToken;
        //emit tokensWithdrawn(msg.sender,releasedTokens[msg.sender][index]);
    }
    
    function unlockTokens(uint8 ind) internal returns(uint) {

        uint totalNoOfPeriods = beneficiaryDetails[msg.sender][ind].duration/beneficiaryDetails[msg.sender][ind].slicePeriod;
        uint tokensPerPeriod = beneficiaryDetails[msg.sender][ind].noOfTokens/totalNoOfPeriods;
        require(block.timestamp>beneficiaryDetails[msg.sender][ind].startTime,"No tokens unlocked");
        uint timePeriodSinceStart = block.timestamp - beneficiaryDetails[msg.sender][ind].startTime;
        uint noOfPeriodsTillNow = timePeriodSinceStart/beneficiaryDetails[msg.sender][ind].slicePeriod;
        uint noOfTokensTillNow = noOfPeriodsTillNow * tokensPerPeriod - releasedTokens[msg.sender][ind];
        emit tokensUnLocked(totalNoOfPeriods,tokensPerPeriod,timePeriodSinceStart,noOfPeriodsTillNow,noOfTokensTillNow);
       
        if(noOfPeriodsTillNow >= totalNoOfPeriods){ //Exceeded the duration
            return tokensPerPeriod*totalNoOfPeriods - releasedTokens[msg.sender][ind];
        }

        return noOfTokensTillNow;
    }


 }//0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//