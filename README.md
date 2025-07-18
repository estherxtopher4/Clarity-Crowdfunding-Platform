# Clarity Crowdfunding Platform

A decentralized crowdfunding platform built on Stacks blockchain using Clarity smart contracts.

## Overview

This platform enables creators to launch funding campaigns, backers to contribute funds, and automated milestone tracking with refund mechanisms. The system consists of five interconnected smart contracts that handle the complete crowdfunding lifecycle.

## Architecture

### Core Contracts

1. **Campaign Creation Contract** (`campaign-creation.clar`)
    - Creates new funding campaigns with goals and timelines
    - Manages campaign metadata and status
    - Validates campaign parameters

2. **Contribution Tracking Contract** (`contribution-tracking.clar`)
    - Records backer contributions and reward selections
    - Tracks total funding per campaign
    - Manages contributor lists and amounts

3. **Milestone Verification Contract** (`milestone-verification.clar`)
    - Defines and validates project progress markers
    - Enables milestone-based fund release
    - Tracks completion status

4. **Refund Processing Contract** (`refund-processing.clar`)
    - Handles automatic refunds for failed campaigns
    - Processes refund requests and validations
    - Manages refund distribution logic

5. **Reward Distribution Contract** (`reward-distribution.clar`)
    - Manages reward tiers and delivery
    - Tracks reward fulfillment status
    - Handles reward distribution to backers

## Features

- **Campaign Management**: Create campaigns with funding goals, deadlines, and reward tiers
- **Secure Contributions**: Track all contributions with transparent accounting
- **Milestone Tracking**: Progress-based fund release system
- **Automatic Refunds**: Built-in refund mechanism for failed campaigns
- **Reward System**: Comprehensive reward tier management and distribution

## Data Structures

### Campaign
- Campaign ID (uint)
- Creator (principal)
- Title and description (string-ascii)
- Funding goal (uint)
- Current funding (uint)
- Deadline (uint)
- Status (string-ascii)

### Contribution
- Campaign ID (uint)
- Contributor (principal)
- Amount (uint)
- Timestamp (uint)
- Reward tier (uint)

### Milestone
- Campaign ID (uint)
- Milestone ID (uint)
- Description (string-ascii)
- Target amount (uint)
- Completion status (bool)

## Usage

### Creating a Campaign
\`\`\`clarity
(contract-call? .campaign-creation create-campaign
"My Project"
"Project description"
u1000000
u144)
\`\`\`

### Contributing to a Campaign
\`\`\`clarity
(contract-call? .contribution-tracking contribute
u1
u1
u50000)
\`\`\`

### Verifying Milestones
\`\`\`clarity
(contract-call? .milestone-verification complete-milestone
u1
u1)
\`\`\`

## Error Codes

- `ERR-NOT-AUTHORIZED` (u100): Caller not authorized for action
- `ERR-CAMPAIGN-NOT-FOUND` (u101): Campaign does not exist
- `ERR-INVALID-AMOUNT` (u102): Invalid contribution amount
- `ERR-CAMPAIGN-ENDED` (u103): Campaign has ended
- `ERR-GOAL-REACHED` (u104): Funding goal already reached
- `ERR-INSUFFICIENT-FUNDS` (u105): Insufficient funds for operation
- `ERR-MILESTONE-NOT-FOUND` (u106): Milestone does not exist
- `ERR-ALREADY-COMPLETED` (u107): Milestone already completed
- `ERR-REFUND-NOT-AVAILABLE` (u108): Refund not available
- `ERR-REWARD-NOT-FOUND` (u109): Reward tier not found

## Testing

Run the test suite:
\`\`\`bash
npm test
\`\`\`

## Development

### Prerequisites
- Clarinet CLI
- Node.js 18+
- npm or yarn

### Setup
\`\`\`bash
npm install
clarinet check
clarinet test
\`\`\`

## Security Considerations

- All functions include proper authorization checks
- Input validation on all user-provided data
- Safe arithmetic operations to prevent overflow
- Proper error handling and meaningful error messages
- No cross-contract dependencies to minimize attack surface

## License

MIT License
