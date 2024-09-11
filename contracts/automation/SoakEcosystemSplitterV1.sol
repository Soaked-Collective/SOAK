//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IStakingContract {
    function depositRewards(uint256 amount) external;
}

contract SoakEcosystemSplitterV1 is AccessControl {

    address public immutable soakToken;

    struct SoakEcosystemAddresses {
        address charityAddress;
        address p2eRewardsAddress;
        address treasuryAddress;
        address soakStakingAddress;
        address soakProofOfContributionRewardAddress;
    }

    struct SoakEcosystemPercentages {
        uint256 charityPercentage;
        uint256 p2eRewardsPercentage;
        uint256 treasuryPercentage;
        uint256 soakStakingPercentage;
        uint256 soakProofOfContributionRewardPercentage;
    }

    uint256 public constant PERCENTAGE_DENOM = 10_000;

    SoakEcosystemAddresses public soakEcosystemAddresses;
    SoakEcosystemPercentages public soakEcosystemPercentages;


    bytes32 public constant TRIGGER_ROLE = keccak256("TRIGGER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Events
    event SoakEcosystemAddressesChanged();
    event SoakEcosystemPercentagesChanged();
    event ERC20TokenRescue();
    event EcosystemDistribution(uint256 amount);

    constructor(
        address soakToken_,
        address charityAddress_,
        address p2eRewardsAddress_,
        address treasuryAddress_,
        address soakStakingAddress_,
        address soakProofOfContributionRewardAddress_
    ) {
        require(
            soakToken_ != address(0) &&
            charityAddress_ != address(0) &&
            p2eRewardsAddress_ != address(0) &&
            treasuryAddress_ != address(0) &&
            soakStakingAddress_ != address(0) &&
            soakProofOfContributionRewardAddress_ != address(0),
            "Token & Distribution addresses cannot be zero address"
        );

        soakToken = soakToken_;

        soakEcosystemAddresses.charityAddress = charityAddress_;
        soakEcosystemAddresses.p2eRewardsAddress = p2eRewardsAddress_;
        soakEcosystemAddresses.treasuryAddress = treasuryAddress_;
        soakEcosystemAddresses.soakStakingAddress = soakStakingAddress_;
        soakEcosystemAddresses.soakProofOfContributionRewardAddress = soakProofOfContributionRewardAddress_;

        soakEcosystemPercentages.charityPercentage = 200;
        soakEcosystemPercentages.p2eRewardsPercentage = 3000;
        soakEcosystemPercentages.treasuryPercentage = 5000;
        soakEcosystemPercentages.soakStakingPercentage = 1000;
        soakEcosystemPercentages.soakProofOfContributionRewardPercentage = 800;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TRIGGER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function triggerEcosystemDistribution() public onlyRole(TRIGGER_ROLE) {
        uint256 balance = IERC20(soakToken).balanceOf(address(this));

        if (balance > 0) {
            uint256 charityBalance = (balance * soakEcosystemPercentages.charityPercentage) / PERCENTAGE_DENOM;
            uint256 p2eRewardsBalance = (balance * soakEcosystemPercentages.p2eRewardsPercentage) / PERCENTAGE_DENOM;
            uint256 treasuryBalance = (balance * soakEcosystemPercentages.treasuryPercentage) / PERCENTAGE_DENOM;
            uint256 soakStakingBalance = (balance * soakEcosystemPercentages.soakStakingPercentage) / PERCENTAGE_DENOM;
            uint256 soakProofOfContributionRewardBalance = (
                    balance * soakEcosystemPercentages.soakProofOfContributionRewardPercentage
                ) / PERCENTAGE_DENOM;

            // send to destinations
            if (charityBalance > 0) {
                IERC20(soakToken).transfer(soakEcosystemAddresses.charityAddress, charityBalance);
            }
            if (p2eRewardsBalance > 0) {
                IERC20(soakToken).transfer(soakEcosystemAddresses.p2eRewardsAddress, p2eRewardsBalance);
            }
            if (treasuryBalance > 0) {
                IERC20(soakToken).transfer(soakEcosystemAddresses.treasuryAddress, treasuryBalance);
            }

            if (soakStakingBalance > 0) {
                IStakingContract(soakEcosystemAddresses.soakStakingAddress).depositRewards(soakStakingBalance);
            }
            if (soakProofOfContributionRewardBalance > 0) {
                IStakingContract(soakEcosystemAddresses.soakProofOfContributionRewardAddress)
                    .depositRewards(soakProofOfContributionRewardBalance);
            }

            emit EcosystemDistribution(balance);
        }
    }

    function setSoakECosystemAddresses(
        address charityAddress_,
        address p2eRewardsAddress_,
        address treasuryAddress_,
        address soakStakingAddress_,
        address soakProofOfContributionRewardAddress_
    ) external onlyRole(ADMIN_ROLE) {
        require(
            charityAddress_ != address(0) &&
            p2eRewardsAddress_ != address(0) &&
            treasuryAddress_ != address(0) &&
            soakStakingAddress_ != address(0) &&
            soakProofOfContributionRewardAddress_ != address(0),
            "Token & Distribution addresses cannot be zero address"
        );

        soakEcosystemAddresses.charityAddress = charityAddress_;
        soakEcosystemAddresses.p2eRewardsAddress = p2eRewardsAddress_;
        soakEcosystemAddresses.treasuryAddress = treasuryAddress_;
        soakEcosystemAddresses.soakStakingAddress = soakStakingAddress_;
        soakEcosystemAddresses.soakProofOfContributionRewardAddress = soakProofOfContributionRewardAddress_;

        emit SoakEcosystemAddressesChanged();
    }

    function setEcosystemPercentage(
        uint256 charityPercentage_,
        uint256 p2eRewardsPercentage_,
        uint256 treasuryPercentage_,
        uint256 soakStakingPercentage_,
        uint256 soakProofOfContributionRewardPercentage_
    )
        external
        onlyRole(ADMIN_ROLE)
    {
        require(
            (
                charityPercentage_ +
                p2eRewardsPercentage_ +
                treasuryPercentage_ +
                soakStakingPercentage_ +
                soakProofOfContributionRewardPercentage_
            ) == PERCENTAGE_DENOM,
            "ECosystem percentages must equal 10,000"
        );
        soakEcosystemPercentages.charityPercentage = charityPercentage_;
        soakEcosystemPercentages.p2eRewardsPercentage = p2eRewardsPercentage_;
        soakEcosystemPercentages.treasuryPercentage = treasuryPercentage_;
        soakEcosystemPercentages.soakStakingPercentage = soakStakingPercentage_;
        soakEcosystemPercentages.soakProofOfContributionRewardPercentage = soakProofOfContributionRewardPercentage_;

        emit SoakEcosystemPercentagesChanged();
    }

    function approve(address spender, uint256 amount) external onlyRole(ADMIN_ROLE) {
        IERC20(soakToken).approve(spender, amount);
    }

    function rescueToken(address _token) external onlyRole(ADMIN_ROLE) {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );

        emit ERC20TokenRescue();
    }
}
