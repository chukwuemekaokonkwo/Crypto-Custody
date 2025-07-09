# Stacks Decentralized Banking System

A comprehensive blockchain-based banking platform built on the Stacks blockchain that provides secure digital financial services including account creation, fund deposits, withdrawals, peer-to-peer transfers, and advanced security features with configurable transaction limits and multi-layered account protection mechanisms.

## Features

### Core Banking Operations
- **Account Creation**: Secure account registration with automated initialization
- **Fund Deposits**: Direct STX token deposits into customer accounts
- **Fund Withdrawals**: Secure withdrawals with configurable fees and daily limits
- **Peer-to-Peer Transfers**: Direct transfers between registered customers
- **Transaction History**: Comprehensive ledger with pagination support

### Security Features
- **Account Locking**: Custom unlock codes with hash-based security
- **Failed Attempt Tracking**: Configurable maximum unlock attempts
- **Daily Withdrawal Limits**: Configurable daily transaction limits
- **Emergency Admin Controls**: Administrative override capabilities
- **Multi-layered Validation**: Comprehensive input validation and authorization

### Administrative Controls
- **System Status Toggle**: Enable/disable platform operations
- **Fee Configuration**: Adjustable withdrawal fees
- **Limit Management**: Configurable daily withdrawal limits
- **Emergency Functions**: System fund recovery and account unlock capabilities

## Contract Architecture

### Constants
- **Error Codes**: 16 predefined error constants for different failure scenarios
- **System Configuration**: Configurable limits, fees, and thresholds
- **Security Parameters**: Unlock attempt limits and validation thresholds

### Data Storage
- **Account Balances**: Primary balance tracking for all customers
- **Daily Withdrawal Records**: Time-based withdrawal tracking
- **Customer Registration**: Account registration status
- **Security Profiles**: Account lock status and unlock code management
- **Transaction Ledger**: Comprehensive transaction history

## Getting Started

### Prerequisites
- Stacks blockchain environment
- Clarity smart contract deployment tools
- STX tokens for testing

### Deployment
1. Deploy the contract to the Stacks blockchain
2. The deployer automatically becomes the contract owner
3. System starts in operational mode with default configurations

### Initial Configuration
Default settings upon deployment:
- **Withdrawal Fee**: 1 STX
- **Daily Withdrawal Limit**: 1,000 STX
- **Maximum Unlock Attempts**: 3
- **System Status**: Operational

## Public Functions

### Account Management

#### `create-customer-account()`
Creates a new customer account in the banking system.
- **Returns**: `(ok true)` on success
- **Errors**: `ERR-SYSTEM-DISABLED`, `ERR-ACCOUNT-ALREADY-EXISTS`

#### `secure-account-with-code(unlock-code-hash)`
Secures an account with a custom unlock code hash.
- **Parameters**: `unlock-code-hash` (buff 32) - Hash of the unlock code
- **Returns**: `(ok true)` on success
- **Errors**: `ERR-ACCOUNT-NOT-FOUND`, `ERR-ACCOUNT-LOCKED`, `ERR-INVALID-UNLOCK-CODE`

#### `unlock-account-with-code(provided-unlock-code)`
Unlocks a secured account with the correct unlock code.
- **Parameters**: `provided-unlock-code` (buff 32) - The unlock code to verify
- **Returns**: `(ok true)` on success
- **Errors**: `ERR-ACCOUNT-NOT-FOUND`, `ERR-UNAUTHORIZED-ACCESS`, `ERR-UNLOCK-ATTEMPTS-EXHAUSTED`, `ERR-INVALID-UNLOCK-CODE`

### Banking Operations

#### `deposit-funds(deposit-amount)`
Deposits STX tokens into the customer's account.
- **Parameters**: `deposit-amount` (uint) - Amount to deposit in micro-STX
- **Returns**: `(ok deposit-amount)` on success
- **Errors**: `ERR-SYSTEM-DISABLED`, `ERR-INVALID-AMOUNT`, `ERR-ACCOUNT-NOT-FOUND`, `ERR-ACCOUNT-LOCKED`

#### `withdraw-funds(withdrawal-amount)`
Withdraws STX tokens from the customer's account.
- **Parameters**: `withdrawal-amount` (uint) - Amount to withdraw in micro-STX
- **Returns**: `(ok withdrawal-amount)` on success
- **Errors**: `ERR-INSUFFICIENT-BALANCE`, `ERR-DAILY-LIMIT-EXCEEDED`, and others

#### `transfer-funds(recipient-address, transfer-amount)`
Transfers funds between customer accounts.
- **Parameters**: 
  - `recipient-address` (principal) - Recipient's account address
  - `transfer-amount` (uint) - Amount to transfer in micro-STX
- **Returns**: `(ok transfer-amount)` on success
- **Errors**: `ERR-SELF-TRANSFER-PROHIBITED`, `ERR-INSUFFICIENT-BALANCE`, and others

### Information Services

#### `get-account-balance(customer-address)`
Retrieves the current balance of a customer account.
- **Parameters**: `customer-address` (principal) - Customer's account address
- **Returns**: `(ok balance)` - Current account balance in micro-STX

#### `get-remaining-daily-limit(customer-address)`
Calculates the remaining daily withdrawal limit for a customer.
- **Parameters**: `customer-address` (principal) - Customer's account address
- **Returns**: `(ok remaining-limit)` - Remaining daily withdrawal amount

#### `get-transaction-history(customer-address, start-id, limit)`
Queries transaction history with pagination.
- **Parameters**:
  - `customer-address` (principal) - Customer's account address
  - `start-id` (uint) - Starting transaction ID
  - `limit` (uint) - Maximum number of results (≤ 50)
- **Returns**: Transaction history metadata
- **Authorization**: Customer or contract owner only

### Administrative Functions (Owner Only)

#### `set-system-operational-status(is-operational)`
Toggles the system operational status.
- **Parameters**: `is-operational` (bool) - New operational status
- **Returns**: `(ok is-operational)` on success

#### `configure-withdrawal-fee(new-fee)`
Updates the withdrawal transaction fee.
- **Parameters**: `new-fee` (uint) - New fee amount (≤ 10 STX)
- **Returns**: `(ok new-fee)` on success

#### `configure-daily-withdrawal-limit(new-limit)`
Updates the daily withdrawal limit.
- **Parameters**: `new-limit` (uint) - New daily limit (1-10,000 STX)
- **Returns**: `(ok new-limit)` on success

#### `emergency-unlock-account(locked-customer-address)`
Emergency unlock for customer accounts.
- **Parameters**: `locked-customer-address` (principal) - Account to unlock
- **Returns**: `(ok true)` on success

#### `emergency-withdraw-system-funds(emergency-amount)`
Emergency withdrawal of system funds.
- **Parameters**: `emergency-amount` (uint) - Amount to withdraw
- **Returns**: `(ok emergency-amount)` on success

## Read-Only Functions

### System Information
- `get-system-operational-status()` - Current operational status
- `get-active-withdrawal-fee()` - Current withdrawal fee
- `get-active-daily-withdrawal-limit()` - Current daily withdrawal limit
- `get-cumulative-system-deposits()` - Total system deposits
- `get-cumulative-system-withdrawals()` - Total system withdrawals
- `get-total-contract-balance()` - Total contract STX balance
- `get-comprehensive-system-overview()` - Complete system status

### Account Information
- `is-customer-account-registered(customer-address)` - Registration status
- `is-customer-account-locked(customer-address)` - Lock status
- `get-customer-security-profile(customer-address)` - Security profile
- `get-customer-failed-attempts(customer-address)` - Failed unlock attempts
- `get-customer-daily-withdrawal-amount(customer-address)` - Daily withdrawal total

### Transaction Information
- `get-total-system-transaction-count()` - Total transaction count
- `get-transaction-details(transaction-id)` - Specific transaction details
- `get-unlock-attempt-limit()` - Current unlock attempt limit

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-UNAUTHORIZED-ACCESS | Unauthorized access attempt |
| 101 | ERR-INSUFFICIENT-BALANCE | Insufficient account balance |
| 102 | ERR-INVALID-AMOUNT | Invalid transaction amount |
| 103 | ERR-DAILY-LIMIT-EXCEEDED | Daily withdrawal limit exceeded |
| 104 | ERR-SYSTEM-DISABLED | System is disabled |
| 105 | ERR-TRANSACTION-LIMIT-EXCEEDED | Transaction limit exceeded |
| 106 | ERR-ACCOUNT-NOT-FOUND | Account not found |
| 107 | ERR-ACCOUNT-ALREADY-EXISTS | Account already exists |
| 108 | ERR-SELF-TRANSFER-PROHIBITED | Self-transfer not allowed |
| 109 | ERR-EXCESSIVE-TRANSACTION-FEE | Transaction fee too high |
| 110 | ERR-MINIMUM-LIMIT-VIOLATION | Below minimum limit |
| 111 | ERR-MAXIMUM-LIMIT-VIOLATION | Above maximum limit |
| 112 | ERR-ACCOUNT-LOCKED | Account is locked |
| 113 | ERR-INVALID-UNLOCK-CODE | Invalid unlock code |
| 114 | ERR-UNLOCK-ATTEMPTS-EXHAUSTED | Too many unlock attempts |
| 115 | ERR-HISTORY-QUERY-LIMIT-EXCEEDED | History query limit exceeded |
| 116 | ERR-SECURITY-ATTEMPTS-OUT-OF-BOUNDS | Security attempts out of bounds |

## Security Considerations

### Account Security
- All sensitive operations require account registration
- Locked accounts cannot perform operations until unlocked
- Failed unlock attempts are tracked and limited
- Hash-based unlock code storage

### Transaction Security
- All amounts validated for positive values
- Daily withdrawal limits enforced
- Sufficient balance verification
- Self-transfer prevention

### Administrative Security
- Owner-only administrative functions
- Emergency controls for system management
- Configurable security parameters
- Comprehensive audit logging

## Usage Examples

### Creating an Account
```clarity
;; Create a new customer account
(contract-call? .banking-contract create-customer-account)
```

### Depositing Funds
```clarity
;; Deposit 100 STX (100,000,000 micro-STX)
(contract-call? .banking-contract deposit-funds u100000000)
```

### Withdrawing Funds
```clarity
;; Withdraw 50 STX (50,000,000 micro-STX)
(contract-call? .banking-contract withdraw-funds u50000000)
```

### Transferring Funds
```clarity
;; Transfer 25 STX to another account
(contract-call? .banking-contract transfer-funds 'ST1RECIPIENT... u25000000)
```

### Checking Balance
```clarity
;; Check account balance
(contract-call? .banking-contract get-account-balance 'ST1CUSTOMER...)
```

## Development Notes

### Unit Conversions
- 1 STX = 1,000,000 micro-STX
- All amounts in the contract are in micro-STX
- Convert accordingly when interacting with the contract

### Banking Day Calculation
- Banking days are calculated based on block height
- 144 blocks per day (approximately 10-minute block times)
- Daily limits reset each banking day

### Transaction Logging
- All operations are logged in the transaction ledger
- Each transaction gets a unique sequential ID
- Comprehensive metadata stored for audit purposes