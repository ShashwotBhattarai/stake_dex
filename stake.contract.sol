// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract StakeContract {
   IERC20 public stakingToken;
    IERC20 public rewardsToken;

    address public owner;
    uint256 public rewardRate; // Fixed reward rate per token per second

    mapping(address => uint256) public stackedBalanceOf;
    mapping(address => uint256) public stakeTimestamps; // Track when each user last staked tokens
    mapping(address => uint256) public rewards; // Accrued rewards for each user

    uint256 public totalSupply;

    constructor() {
        owner = msg.sender;
        stakingToken = IERC20(0x9A4F639FF1c20Fe09371E07d0D48f8687B6Bed85);
        rewardsToken = IERC20(0x8c070420Fbe00D928d9AC558460676D9e5940C0A);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "amount = 0");
        uint256 sendersBalance = IERC20(stakingToken).balanceOf(msg.sender);
        require(sendersBalance>=_amount, "not enough token to stake");
        updateReward(msg.sender); // Update reward before changing the stake
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stackedBalanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        stakeTimestamps[msg.sender] = block.timestamp; // Update stake timestamp
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "amount = 0");
        updateReward(msg.sender); // Update reward before changing the stake
        stakingToken.transfer(msg.sender, _amount);
        stackedBalanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        if (stackedBalanceOf[msg.sender] == 0) {
            stakeTimestamps[msg.sender] = 0; // Reset stake timestamp if fully withdrawn
        }else{
            stakeTimestamps[msg.sender]= block.timestamp;
        }
        
    }

    function withDrawReward() external {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0; // Reset the reward
            rewardsToken.transfer(msg.sender, reward); // Transfer the accumulated reward
        }
    }

    function updateReward(address account) private {
        if (stackedBalanceOf[account] > 0) {
            uint256 rewardDuration = block.timestamp - stakeTimestamps[account];
            uint256 reward = rewardDuration * (rewardRate/100) * stackedBalanceOf[account];
            rewards[account] += reward; 
            stakeTimestamps[msg.sender] = block.timestamp;
            // Accumulate the reward
        }
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }
}


