# Chain-Scrow 🔐

A simple and secure escrow service smart contract built on the Stacks blockchain using Clarity. Chain-Scrow holds STX funds until conditions are met, providing a trustless way to facilitate secure transactions between parties.

## Features

- ✅ **Simple & Secure**: Only authorized parties can interact with escrows
- ✅ **Multiple Creation Options**: Create escrows with entire balance or specific amounts
- ✅ **Emergency Protection**: Built-in refund mechanism after 1 week of inactivity
- ✅ **Status Tracking**: Real-time escrow status monitoring
- ✅ **Description Support**: Add context to each escrow transaction
- ✅ **Gas Efficient**: Optimized for minimal transaction costs

## How It Works

1. **Buyer** creates an escrow with the seller's address and optional description
2. **Funds** are locked in the smart contract
3. **Buyer** releases funds when conditions are met, OR **Seller** can refund if needed
4. **Emergency refund** available if seller becomes unresponsive after ~1 week

## Contract Functions

### Public Functions

#### `create-escrow`
Creates an escrow with the sender's entire STX balance.
```clarity
(create-escrow (seller principal) (description (string-ascii 256)))
```

#### `create-escrow-with-amount`
Creates an escrow with a specific amount.
```clarity
(create-escrow-with-amount (seller principal) (amount uint) (description (string-ascii 256)))
```

#### `release-escrow`
Releases funds to the seller (only callable by buyer).
```clarity
(release-escrow (escrow-id uint))
```

#### `refund-escrow`
Refunds funds to the buyer (only callable by seller).
```clarity
(refund-escrow (escrow-id uint))
```

#### `emergency-refund`
Emergency refund after 1008 blocks (~1 week) of inactivity (only callable by buyer).
```clarity
(emergency-refund (escrow-id uint))
```

### Read-Only Functions

#### `get-escrow`
Returns escrow details by ID.
```clarity
(get-escrow (escrow-id uint))
```

#### `get-escrow-status`
Returns the current status of an escrow.
```clarity
(get-escrow-status (escrow-id uint))
```

#### `is-escrow-active`
Checks if an escrow is currently active.
```clarity
(is-escrow-active (escrow-id uint))
```

#### `get-escrow-counter`
Returns the current escrow counter.
```clarity
(get-escrow-counter)
```

## Escrow Status

- **1 (ACTIVE)**: Escrow is active and funds are locked
- **2 (RELEASED)**: Funds have been released to the seller
- **3 (REFUNDED)**: Funds have been refunded to the buyer

## Error Codes

- `u401`: Not authorized to perform this action
- `u402`: Insufficient funds
- `u403`: Escrow already released
- `u404`: Escrow not found
- `u405`: Escrow already refunded
- `u406`: Invalid amount (must be greater than 0)

## Usage Examples

### Creating an Escrow

```clarity
;; Create escrow with specific amount
(contract-call? .chain-scrow create-escrow-with-amount 'SP1234...SELLER u1000000 "Payment for web development services")

;; Create escrow with entire balance
(contract-call? .chain-scrow create-escrow 'SP1234...SELLER "Marketplace purchase #12345")
```

### Releasing Funds

```clarity
;; Buyer releases funds to seller
(contract-call? .chain-scrow release-escrow u1)
```

### Refunding

```clarity
;; Seller refunds buyer
(contract-call? .chain-scrow refund-escrow u1)

;; Emergency refund (after 1 week)
(contract-call? .chain-scrow emergency-refund u1)
```

### Checking Escrow Status

```clarity
;; Get escrow details
(contract-call? .chain-scrow get-escrow u1)

;; Check if escrow is active
(contract-call? .chain-scrow is-escrow-active u1)
```

## Security Features

### Authorization
- Only the **buyer** can release funds or initiate emergency refunds
- Only the **seller** can refund the buyer
- No third-party intervention possible

### Emergency Protection
- Buyers can reclaim funds after 1008 blocks (~1 week) if seller is unresponsive
- Prevents funds from being permanently locked

### Status Validation
- Prevents double-spending through status checks
- Ensures escrows can only be resolved onces