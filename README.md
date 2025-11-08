# 🌍 Carbon Credit Trading Platform

A decentralized marketplace for carbon credits built on the Stacks blockchain using Clarity smart contracts.

## 📋 Overview

This platform enables organizations and individuals to mint, verify, trade, and retire carbon credits in a transparent and trustless manner. The smart contract handles the entire lifecycle of carbon credits from creation to retirement.

## ✨ Features

### 🪙 Carbon Credit Management
- **Mint Credits**: Create new carbon credits with project details and vintage year
- **Verification System**: Authorized verifiers can validate carbon credits
- **Balance Tracking**: Per-user, per-credit balance management

### 🛒 Marketplace
- **Create Listings**: List verified carbon credits for sale
- **Purchase Credits**: Buy carbon credits with STX tokens
- **Cancel Listings**: Sellers can cancel active listings
- **Platform Fees**: Configurable fee system (default 2.5%)

### ♻️ Retirement
- **Retire Credits**: Permanently remove credits from circulation
- **Transparent Tracking**: On-chain record of all retired credits

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity and Stacks blockchain

### Installation

```bash
git clone <repository-url>
cd Carbon-Credit-Trading-Platform
clarinet check
```

### Running Tests

```bash
npm install
npm test
```

## 📖 Contract Functions

### Public Functions

#### `mint-carbon-credit`
```clarity
(mint-carbon-credit (amount uint) (project-name (string-ascii 100)) (vintage-year uint))
```
Creates a new carbon credit. Returns the credit ID.

#### `verify-credit`
```clarity
(verify-credit (credit-id uint))
```
Verifies a carbon credit (verifier only).

#### `create-listing`
```clarity
(create-listing (credit-id uint) (price-per-credit uint) (amount uint))
```
Lists verified credits for sale. Returns listing ID.

#### `purchase-credits`
```clarity
(purchase-credits (listing-id uint) (purchase-amount uint))
```
Buys carbon credits from a listing using STX.

#### `retire-credits`
```clarity
(retire-credits (credit-id uint) (amount uint))
```
Permanently retires carbon credits from circulation.

#### `cancel-listing`
```clarity
(cancel-listing (listing-id uint))
```
Cancels an active listing (seller only).

### Admin Functions

#### `add-verifier`
```clarity
(add-verifier (verifier principal))
```
Adds a new verifier (owner only).

#### `remove-verifier`
```clarity
(remove-verifier (verifier principal))
```
Removes a verifier (owner only).

#### `set-platform-fee`
```clarity
(set-platform-fee (new-fee uint))
```
Sets the platform fee in basis points (owner only). Max 10%.

### Read-Only Functions

- `get-credit`: Retrieve carbon credit details
- `get-listing`: Retrieve listing information
- `get-user-balance`: Check user balance for a specific credit
- `is-verifier`: Check if an address is a verifier
- `get-platform-fee`: Get current platform fee percentage
- `get-next-credit-id`: Get next credit ID
- `get-next-listing-id`: Get next listing ID

## 🔐 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Action requires contract owner |
| u101 | err-not-found | Resource not found |
| u102 | err-insufficient-balance | Insufficient credit balance |
| u103 | err-invalid-amount | Invalid amount provided |
| u104 | err-not-authorized | Not authorized for this action |
| u105 | err-already-verified | Credit already verified |
| u106 | err-not-verified | Credit not yet verified |
| u107 | err-listing-not-active | Listing is not active |
| u108 | err-insufficient-payment | Insufficient payment |

## 💡 Usage Examples

### Mint a Carbon Credit
```clarity
(contract-call? .Carbon-Credit-Trading-Platform mint-carbon-credit u1000 "Reforestation Project" u2024)
```

### Verify a Credit (as verifier)
```clarity
(contract-call? .Carbon-Credit-Trading-Platform verify-credit u1)
```

### Create a Listing
```clarity
(contract-call? .Carbon-Credit-Trading-Platform create-listing u1 u50000 u500)
```

### Purchase Credits
```clarity
(contract-call? .Carbon-Credit-Trading-Platform purchase-credits u1 u100)
```

### Retire Credits
```clarity
(contract-call? .Carbon-Credit-Trading-Platform retire-credits u1 u50)
```

## 🏗️ Architecture

### Data Structures

**Carbon Credits**
- owner: principal
- amount: uint
- project-name: string-ascii 100
- vintage-year: uint
- verified: bool
- created-at: uint

**Credit Listings**
- credit-id: uint
- seller: principal
- price-per-credit: uint
- amount: uint
- active: bool
- created-at: uint

**User Balances**
- Composite key: {user: principal, credit-id: uint}
- Value: uint (balance)

## 🔒 Security Features

- **Authorization checks**: Owner-only functions protected
- **Verification required**: Only verified credits can be listed
- **Balance validation**: Prevents overselling of credits
- **Platform fee limits**: Maximum 10% platform fee

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License

## 🌟 Acknowledgments

Built with Clarity on the Stacks blockchain for a sustainable future.

