;; Title: 
;; BitOptions: Decentralized Options Trading Protocol on Stacks with Bitcoin Finality
;; Summary: 
;; A trustless, on-chain options trading platform enabling writing/buying of call/put options with 
;; SIP-010 token collateralization, price oracle integration, and Bitcoin-secured settlement.

;; Description:
;; BitOptions is a Layer 2 derivatives protocol built on Stacks that leverages Bitcoin's settlement 
;; finality for institutional-grade options trading. Key features include:
;; - Fully collateralized European-style options (call/put)
;; - SIP-010 compliant digital asset collateralization
;; - Decentralized price feeds with timestamp validation
;; - Compliance-focused design with KYC/AML-ready principal system
;; - Bitcoin timestamp-based expiration enforcement
;; - Protocol-controlled economic parameters with governance
;;
;; The contract implements:
;; 1. Options lifecycle management (write/buy/exercise/expire)
;; 2. Collateral health checks with real-time price feeds
;; 3. Multi-token support through SIP-010 whitelisting
;; 4. Position tracking with user-level accounting
;; 5. Administrative controls compliant with CFTC guidelines
;;
;; Built using Clarity's inherent security features and Bitcoin's proof-of-work finality,
;; BitOptions provides a transparent, non-custodial platform for sophisticated derivatives
;; trading while maintaining regulatory observability.

;; Define SIP-010 trait
(define-trait sip-010-trait
    (
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        (get-balance (principal) (response uint uint))
        (get-total-supply () (response uint uint))
        (get-decimals () (response uint uint))
        (get-token-uri () (response (optional (string-utf8 256)) uint))
        (get-name () (response (string-ascii 32) uint))
        (get-symbol () (response (string-ascii 32) uint))
    )
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1001))
(define-constant ERR-INVALID-EXPIRY (err u1002))
(define-constant ERR-INVALID-STRIKE-PRICE (err u1003))
(define-constant ERR-OPTION-NOT-FOUND (err u1004))
(define-constant ERR-OPTION-EXPIRED (err u1005))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u1006))
(define-constant ERR-ALREADY-EXERCISED (err u1007))
(define-constant ERR-INVALID-PREMIUM (err u1008))

;; Add new error constants for validation
(define-constant ERR-INVALID-TOKEN (err u1009))
(define-constant ERR-INVALID-SYMBOL (err u1010))
(define-constant ERR-INVALID-TIMESTAMP (err u1011))

;; Add validation for admin inputs

;; Add new error constants
(define-constant ERR-INVALID-ADDRESS (err u1012))
(define-constant ERR-ZERO-ADDRESS (err u1013))
(define-constant ERR-EMPTY-SYMBOL (err u1014))

;; Utility Functions
(define-private (get-min (a uint) (b uint))
    (if (< a b) a b))

;; Data Types
(define-map options
    uint
    {
        writer: principal,
        holder: (optional principal),
        collateral-amount: uint,
        strike-price: uint,
        premium: uint,
        expiry: uint,
        is-exercised: bool,
        option-type: (string-ascii 4),  ;; "CALL" or "PUT"
        state: (string-ascii 9)         ;; Changed to 9 to accommodate "EXERCISED"
    }
)

(define-map user-positions
    principal
    {
        written-options: (list 10 uint),
        held-options: (list 10 uint),
        total-collateral-locked: uint
    }
)

;; Add whitelist for approved tokens
(define-map approved-tokens
    principal
    bool
)

;; Counter for option IDs
(define-data-var next-option-id uint u1)

;; Governance
(define-data-var contract-owner principal tx-sender)
(define-data-var protocol-fee-rate uint u100) ;; 1% = 100 basis points

;; Price Oracle Integration
(define-map price-feeds
    (string-ascii 10)
    {
        price: uint,
        timestamp: uint,
        source: principal
    }
)