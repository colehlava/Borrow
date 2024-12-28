# Borrow

## Description
A simple decentralized protocol that allows an owner to rent out a luxury watch in exchange for a fee and collateral from the borrower.

## Purpose
This protocol enables trustless loans without selling collateral and incurring capital gains.

### Usage
- The owner sets the required rental fee, collateral, and expiration date.
- The borrower deposits ETH = fee + collateral.
- The owner can immediately withdraw the fee.
- The borrower receives the watch from the owner (off-chain).
- If the borrower returns the watch before the expiration, the owner calls `returnCollateral()` to return collateral to the borrower.
- If the borrower does not return the watch before the expiration, the owner can claim the borrower's collateral.
