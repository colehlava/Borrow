pragma solidity ^0.8.17;

/*
 * @title Borrow
 *
 * A simple decentralized protocol that allows an owner to rent out a
 * luxury watch in exchange for a fee and collateral from the borrower.
 *
 * This protocol enables trustless loans without selling collateral and incurring capital gains.
 *
 * - The owner sets the required rental fee, collateral, and expiration date.
 * - The borrower deposits ETH = fee + collateral.
 * - The owner can immediately withdraw the fee.
 * - The borrower receives the watch from the owner (off-chain).
 * - If the borrower returns the watch before the expiration, the owner calls `returnCollateral()` to return collateral to the borrower.
 * - If the borrower does not return the watch before the expiration, the owner can claim the borrower's collateral.
 */
contract Borrow {

    // The owner of the watch and deployer of this contract
    address public owner;

    // The fee amount the owner charges the borrower
    uint256 public feeAmount;

    // The collateral amount required to borrow the watch
    uint256 public collateralAmount;

    // The timestamp when the rental period expires
    uint256 public expirationTimestamp;

    // Track whether the borrower has deposited the required funds
    bool public isBorrowerFunded;

    // Track whether the collateral is locked
    bool public collateralLocked;

    // The address of the borrower (who deposited funds)
    address public borrower;


    event ContractDeployed(address indexed owner, uint256 collateralAmount, uint256 feeAmount, uint256 expirationTimestamp);
    event BorrowerFunded(address indexed borrower, uint256 totalAmount);
    event FeeWithdrawn(address indexed owner, uint256 feeAmount);
    event CollateralRefunded(address indexed borrower, uint256 collateralAmount);
    event CollateralClaimed(address indexed owner, uint256 collateralAmount);


    /*
     * @param _feeAmount The fee amount in wei
     * @param _collateralAmount The required collateral in wei
     * @param _expirationTimestamp The unix timestamp after which the collateral can be claimed
     */
    constructor(uint256 _feeAmount, uint256 _collateralAmount, uint256 _expirationTimestamp) {
        require(_expirationTimestamp > block.timestamp, "Expiration must be in the future");

        owner = msg.sender;
        feeAmount = _feeAmount;
        collateralAmount = _collateralAmount;
        expirationTimestamp = _expirationTimestamp;

        emit ContractDeployed(owner, collateralAmount, feeAmount, _expirationTimestamp);
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyBorrower() {
        require(msg.sender == borrower, "Only the borrower can call this function");
        _;
    }


    /*
     * Borrower calls this function to deposit fee + collateral
     */
    function deposit() external payable {
        require(!isBorrowerFunded, "Contract already funded");
        require(msg.value == collateralAmount + feeAmount, "Incorrect deposit amount");

        borrower = msg.sender;
        isBorrowerFunded = true;
        collateralLocked = true;

        emit BorrowerFunded(borrower, msg.value);
    }

    /*
     * Owner calls this function to withdraw the fee.
     */
    function withdrawFee() external onlyOwner {
        require(isBorrowerFunded, "Borrower has not yet funded the contract");
        
        // Transfer fee from contract to owner
        uint256 _fee = feeAmount;
        feeAmount = 0; // Reset fee to avoid re-entrancy

        (bool success, ) = owner.call{value: _fee}("");
        require(success, "Fee withdrawal failed");

        emit FeeWithdrawn(owner, _fee);
    }

    /*
     * After the watch is returned (off-chain), owner calls this function to return the borrower's collateral.
     */
    function returnCollateral() external onlyOwner {
        require(block.timestamp < expirationTimestamp, "Cannot return collateral after expiration");
        require(collateralLocked, "Collateral already returned");

        collateralLocked = false;

        uint256 _collateral = collateralAmount;
        collateralAmount = 0; // Reset to avoid re-entrancy

        (bool success, ) = borrower.call{value: _collateral}("");
        require(success, "Collateral refund failed");

        emit CollateralRefunded(borrower, _collateral);
    }

    /*
     * If the watch is not returned by the expiration time, the owner can claim the collateral by calling this function.
     */
    function claimCollateral() external onlyOwner {
        require(block.timestamp >= expirationTimestamp, "Expiration not yet reached");
        require(collateralLocked, "Collateral not locked");

        collateralLocked = false;

        uint256 _collateral = collateralAmount;
        collateralAmount = 0; // Reset to avoid re-entrancy

        (bool success, ) = owner.call{value: _collateral}("");
        require(success, "Collateral claim failed");

        emit CollateralClaimed(owner, _collateral);
    }
}

