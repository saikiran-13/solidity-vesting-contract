// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract vesting{

    IERC20 internal token;
    struct beneficiarydata{
        address addressOfToken;
        address beneficiary;
        uint8 noOfTokens;
        uint8 cliff;
        uint8 startTime;
        uint8 duration;
        uint8 slicePeriod;
        bool locked;
    }

    mapping (address => beneficiarydata[])public beneficiaryDetails; 
    mapping (address => uint[]) public releasedTokens;
    mapping (address => mapping(address => bool)) public whitelist;

    event tokensLocked(address beneficiary,address Tokenaddrress,uint tokens);
    event tokensWithdrawn(address beneficiary,address Tokenaddrress,uint tokens);

    // constructor(address _tokenaddress){
    //     token = IERC20(_tokenaddress);
    // }

    function whitelistTokens(address _tokenaddress) external{
        whitelist[msg.sender][_tokenaddress] = true;
    }

    function checkBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }

    function lockTokens(address _tokenaddress,uint8 _noOfTokens,uint8 _cliff,uint8 _duration,uint8 _sliceperiod) external{
        require(whitelist[msg.sender][_tokenaddress],"Token is not allowed");
        require(_noOfTokens>0);
        token = IERC20(_tokenaddress);
        beneficiarydata memory person = beneficiarydata({
            addressOfToken:_tokenaddress,
            beneficiary:msg.sender,
            noOfTokens:_noOfTokens,
            cliff:_cliff,
            startTime:uint8(block.timestamp)+_cliff,
            duration:_duration,
            slicePeriod:_sliceperiod,
            locked:true
        });
        beneficiaryDetails[msg.sender].push(person);

        require(person.startTime<_duration);
        // beneficiaryDetails[msg.sender] = person;
        token.transferFrom(msg.sender,address(this),_noOfTokens);
        emit tokensLocked(msg.sender,_tokenaddress,_noOfTokens);
    }
   
    function withdrawTokens(uint8 index) external{
        // require(block.timestamp>beneficiaryDetails[msg.sender].startTime);
        // require(releasedTokens[msg.sender]<beneficiaryDetails[msg.sender].noOfTokens,"Tokens already withdrawn");
        uint tokensLeft = unlockTokens(index);
        require(tokensLeft!=0);
        token.transfer(msg.sender,tokensLeft);
        releasedTokens[msg.sender][index]+=tokensLeft;
        address Tokenaddrress = beneficiaryDetails[msg.sender][index].addressOfToken;
        emit tokensWithdrawn(msg.sender,Tokenaddrress,releasedTokens[msg.sender][index]);
    }

    function unlockTokens(uint8 ind) internal view returns(uint) {
        uint8 totalNoOfPeriods = beneficiaryDetails[msg.sender][ind].duration/beneficiaryDetails[msg.sender][ind].slicePeriod;
        uint8 tokensPerPeriod = beneficiaryDetails[msg.sender][ind].noOfTokens/totalNoOfPeriods;
        uint8 timePeriodSinceStart = uint8(block.timestamp) - beneficiaryDetails[msg.sender][ind].startTime;
        uint8 noOfPeriodsTillNow = timePeriodSinceStart/beneficiaryDetails[msg.sender][ind].slicePeriod;
        uint noOfTokensTillNow = noOfPeriodsTillNow * tokensPerPeriod - releasedTokens[msg.sender][ind];
        
        if(noOfPeriodsTillNow >= totalNoOfPeriods){ //Exceeded the duration
            return tokensPerPeriod*totalNoOfPeriods - releasedTokens[msg.sender][ind];
        }
        return noOfTokensTillNow;
    }
}