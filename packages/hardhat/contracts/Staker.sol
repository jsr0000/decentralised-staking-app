// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	mapping(address => uint256) public balances;
	uint256 public constant threshold = 1 ether;
	uint256 public deadline = block.timestamp + 30 seconds;
	bool public openForWithdraw = false;

	ExampleExternalContract public exampleExternalContract;

	event Stake(address indexed sender, uint256 value);

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
	}

	modifier notCompleted() {
		require(!exampleExternalContract.completed(), "Funding Closed");
		_;
	}

	function stake() public payable notCompleted {
		balances[msg.sender] += msg.value;

		emit Stake(msg.sender, msg.value);
	}

	function execute() public notCompleted {
		if (block.timestamp >= deadline) {
			if (address(this).balance >= threshold) {
				exampleExternalContract.complete{
					value: address(this).balance
				}();
				return;
			}

			openForWithdraw = true;
		}
	}

	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) {
			return 0;
		}
		return deadline - block.timestamp;
	}

	function withdraw() public {
		if (block.timestamp >= deadline) {
			openForWithdraw = true;
		}
		require(openForWithdraw, "Cannot withdraw yet");
		(bool success, ) = msg.sender.call{ value: balances[msg.sender] }("");
		require(success, "Failed to return Ether");
	}

	receive() external payable {
		stake();
	}
}
