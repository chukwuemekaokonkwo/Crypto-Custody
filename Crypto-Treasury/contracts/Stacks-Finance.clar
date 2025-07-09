;; STACKS DECENTRALIZED BANKING SYSTEM SMART CONTRACT
;; A comprehensive blockchain-based banking platform that provides secure digital
;; financial services including account creation, fund deposits, withdrawals, 
;; peer-to-peer transfers, and advanced security features with configurable
;; transaction limits and multi-layered account protection mechanisms.

;; ERROR RESPONSE CONSTANTS

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-DAILY-LIMIT-EXCEEDED (err u103))
(define-constant ERR-SYSTEM-DISABLED (err u104))
(define-constant ERR-TRANSACTION-LIMIT-EXCEEDED (err u105))
(define-constant ERR-ACCOUNT-NOT-FOUND (err u106))
(define-constant ERR-ACCOUNT-ALREADY-EXISTS (err u107))
(define-constant ERR-SELF-TRANSFER-PROHIBITED (err u108))
(define-constant ERR-EXCESSIVE-TRANSACTION-FEE (err u109))
(define-constant ERR-MINIMUM-LIMIT-VIOLATION (err u110))
(define-constant ERR-MAXIMUM-LIMIT-VIOLATION (err u111))
(define-constant ERR-ACCOUNT-LOCKED (err u112))
(define-constant ERR-INVALID-UNLOCK-CODE (err u113))
(define-constant ERR-UNLOCK-ATTEMPTS-EXHAUSTED (err u114))
(define-constant ERR-HISTORY-QUERY-LIMIT-EXCEEDED (err u115))
(define-constant ERR-SECURITY-ATTEMPTS-OUT-OF-BOUNDS (err u116))

;; SYSTEM CONFIGURATION CONSTANTS

(define-constant contract-owner tx-sender)
(define-constant micro-stx-per-stx u1000000)
(define-constant standard-withdrawal-fee micro-stx-per-stx) ;; 1 STX
(define-constant standard-daily-withdrawal-limit (* u1000 micro-stx-per-stx)) ;; 1000 STX
(define-constant maximum-allowed-transaction-fee (* u10 micro-stx-per-stx)) ;; 10 STX
(define-constant minimum-allowed-daily-limit micro-stx-per-stx) ;; 1 STX
(define-constant maximum-allowed-daily-limit (* u10000 micro-stx-per-stx)) ;; 10,000 STX
(define-constant stacks-blocks-per-day u144)
(define-constant maximum-history-query-results u50)
(define-constant minimum-security-attempt-threshold u1)
(define-constant maximum-security-attempt-threshold u10)
(define-constant default-unlock-attempt-limit u3)
(define-constant empty-security-hash 0x0000000000000000000000000000000000000000000000000000000000000000)

;; SYSTEM STATE VARIABLES

(define-data-var platform-operational-status bool true)
(define-data-var active-withdrawal-fee uint standard-withdrawal-fee)
(define-data-var active-daily-withdrawal-limit uint standard-daily-withdrawal-limit)
(define-data-var cumulative-system-deposits uint u0)
(define-data-var cumulative-system-withdrawals uint u0)
(define-data-var next-transaction-identifier uint u0)
(define-data-var maximum-unlock-attempt-threshold uint default-unlock-attempt-limit)

;; DATA STORAGE STRUCTURES

;; Primary account balance storage
(define-map customer-account-balances principal uint)

;; Daily withdrawal tracking with composite key
(define-map daily-withdrawal-records 
  { customer-address: principal, banking-day: uint } 
  uint)

;; Customer registration tracking
(define-map registered-customer-accounts principal bool)

;; Account security and access control
(define-map account-security-profiles 
  principal 
  { 
    is-locked: bool, 
    failed-attempts: uint, 
    unlock-code-hash: (buff 32) 
  })

;; Comprehensive transaction ledger
(define-map system-transaction-ledger
  uint
  { 
    transaction-id: uint,
    customer-address: principal,
    operation-type: (string-ascii 30),
    amount-processed: uint,
    block-timestamp: uint,
    block-height: uint
  })

;; UTILITY AND HELPER FUNCTIONS

;; Calculate current banking day based on blockchain height
(define-private (get-current-banking-day)
  (/ block-height stacks-blocks-per-day))

;; Verify customer account lock status
(define-private (is-account-currently-locked (customer-address principal))
  (match (map-get? account-security-profiles customer-address)
    security-profile (get is-locked security-profile)
    false))

;; Retrieve current failed unlock attempts
(define-private (get-failed-unlock-attempts (customer-address principal))
  (match (map-get? account-security-profiles customer-address)
    security-profile (get failed-attempts security-profile)
    u0))

;; Validate customer registration status
(define-private (is-customer-registered (customer-address principal))
  (default-to false (map-get? registered-customer-accounts customer-address)))

;; Calculate today's withdrawal amount for customer
(define-private (get-todays-withdrawal-amount (customer-address principal))
  (default-to u0 
    (map-get? daily-withdrawal-records 
      { customer-address: customer-address, banking-day: (get-current-banking-day) })))

;; Update daily withdrawal tracking
(define-private (increment-daily-withdrawal-tracking (customer-address principal) (withdrawal-amount uint))
  (let ((current-day (get-current-banking-day))
        (existing-amount (get-todays-withdrawal-amount customer-address)))
    (map-set daily-withdrawal-records 
      { customer-address: customer-address, banking-day: current-day }
      (+ existing-amount withdrawal-amount))))

;; Record transaction in system ledger
(define-private (log-transaction-to-ledger (customer-address principal) (operation-type (string-ascii 30)) (amount uint))
  (let ((transaction-id (+ (var-get next-transaction-identifier) u1)))
    (map-set system-transaction-ledger transaction-id
      {
        transaction-id: transaction-id,
        customer-address: customer-address,
        operation-type: operation-type,
        amount-processed: amount,
        block-timestamp: block-height,
        block-height: block-height
      })
    (var-set next-transaction-identifier transaction-id)
    transaction-id))

;; CUSTOMER ACCOUNT MANAGEMENT

;; Create new customer account in banking system
(define-public (create-customer-account)
  (begin
    (asserts! (var-get platform-operational-status) ERR-SYSTEM-DISABLED)
    (asserts! (not (is-customer-registered tx-sender)) ERR-ACCOUNT-ALREADY-EXISTS)
    
    ;; Initialize customer account
    (map-set registered-customer-accounts tx-sender true)
    (map-set customer-account-balances tx-sender u0)
    
    ;; Setup security profile
    (map-set account-security-profiles tx-sender 
      { 
        is-locked: false, 
        failed-attempts: u0, 
        unlock-code-hash: empty-security-hash 
      })
    
    ;; Log account creation
    (log-transaction-to-ledger tx-sender "account-creation" u0)
    (ok true)))

;; Secure account with custom unlock code
(define-public (secure-account-with-code (unlock-code-hash (buff 32)))
  (begin
    (asserts! (is-customer-registered tx-sender) ERR-ACCOUNT-NOT-FOUND)
    (asserts! (not (is-account-currently-locked tx-sender)) ERR-ACCOUNT-LOCKED)
    (asserts! (not (is-eq unlock-code-hash empty-security-hash)) ERR-INVALID-UNLOCK-CODE)
    
    (map-set account-security-profiles tx-sender
      { 
        is-locked: true, 
        failed-attempts: u0, 
        unlock-code-hash: unlock-code-hash 
      })
    
    (log-transaction-to-ledger tx-sender "account-secured" u0)
    (ok true)))

;; Unlock account with correct security code
(define-public (unlock-account-with-code (provided-unlock-code (buff 32)))
  (begin
    (asserts! (is-customer-registered tx-sender) ERR-ACCOUNT-NOT-FOUND)
    (asserts! (is-account-currently-locked tx-sender) ERR-UNAUTHORIZED-ACCESS)
    
    (let ((security-profile (unwrap-panic (map-get? account-security-profiles tx-sender)))
          (stored-unlock-code (get unlock-code-hash security-profile))
          (current-failed-attempts (get failed-attempts security-profile))
          (max-attempts (var-get maximum-unlock-attempt-threshold)))
      
      (asserts! (< current-failed-attempts max-attempts) ERR-UNLOCK-ATTEMPTS-EXHAUSTED)
      
      (if (is-eq provided-unlock-code stored-unlock-code)
        (begin
          ;; Successful unlock
          (map-set account-security-profiles tx-sender
            { 
              is-locked: false, 
              failed-attempts: u0, 
              unlock-code-hash: empty-security-hash 
            })
          (log-transaction-to-ledger tx-sender "account-unlocked" u0)
          (ok true))
        (begin
          ;; Failed unlock attempt
          (map-set account-security-profiles tx-sender
            { 
              is-locked: true, 
              failed-attempts: (+ current-failed-attempts u1), 
              unlock-code-hash: stored-unlock-code 
            })
          ERR-INVALID-UNLOCK-CODE)))))

;; CORE BANKING OPERATIONS

;; Deposit funds into customer account
(define-public (deposit-funds (deposit-amount uint))
  (begin
    (asserts! (var-get platform-operational-status) ERR-SYSTEM-DISABLED)
    (asserts! (> deposit-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-customer-registered tx-sender) ERR-ACCOUNT-NOT-FOUND)
    (asserts! (not (is-account-currently-locked tx-sender)) ERR-ACCOUNT-LOCKED)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? deposit-amount tx-sender (as-contract tx-sender)))
    
    ;; Update account balance
    (let ((current-balance (default-to u0 (map-get? customer-account-balances tx-sender))))
      (map-set customer-account-balances tx-sender (+ current-balance deposit-amount))
      (var-set cumulative-system-deposits (+ (var-get cumulative-system-deposits) deposit-amount))
      (log-transaction-to-ledger tx-sender "deposit" deposit-amount)
      (ok deposit-amount))))

;; Withdraw funds from customer account
(define-public (withdraw-funds (withdrawal-amount uint))
  (begin
    (asserts! (var-get platform-operational-status) ERR-SYSTEM-DISABLED)
    (asserts! (> withdrawal-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-customer-registered tx-sender) ERR-ACCOUNT-NOT-FOUND)
    (asserts! (not (is-account-currently-locked tx-sender)) ERR-ACCOUNT-LOCKED)
    
    (let ((current-balance (default-to u0 (map-get? customer-account-balances tx-sender)))
          (transaction-fee (var-get active-withdrawal-fee))
          (total-cost (+ withdrawal-amount transaction-fee))
          (todays-withdrawn (get-todays-withdrawal-amount tx-sender))
          (daily-limit (var-get active-daily-withdrawal-limit)))
      
      ;; Validate withdrawal requirements
      (asserts! (>= current-balance total-cost) ERR-INSUFFICIENT-BALANCE)
      (asserts! (<= (+ todays-withdrawn withdrawal-amount) daily-limit) ERR-DAILY-LIMIT-EXCEEDED)
      
      ;; Process withdrawal
      (map-set customer-account-balances tx-sender (- current-balance total-cost))
      (increment-daily-withdrawal-tracking tx-sender withdrawal-amount)
      
      ;; Transfer funds to customer
      (try! (as-contract (stx-transfer? withdrawal-amount tx-sender tx-sender)))
      
      ;; Update system statistics
      (var-set cumulative-system-withdrawals (+ (var-get cumulative-system-withdrawals) withdrawal-amount))
      (log-transaction-to-ledger tx-sender "withdrawal" withdrawal-amount)
      
      (ok withdrawal-amount))))

;; Transfer funds between customers
(define-public (transfer-funds (recipient-address principal) (transfer-amount uint))
  (begin
    (asserts! (var-get platform-operational-status) ERR-SYSTEM-DISABLED)
    (asserts! (> transfer-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (is-customer-registered tx-sender) ERR-ACCOUNT-NOT-FOUND)
    (asserts! (is-customer-registered recipient-address) ERR-ACCOUNT-NOT-FOUND)
    (asserts! (not (is-eq tx-sender recipient-address)) ERR-SELF-TRANSFER-PROHIBITED)
    (asserts! (not (is-account-currently-locked tx-sender)) ERR-ACCOUNT-LOCKED)
    (asserts! (not (is-account-currently-locked recipient-address)) ERR-ACCOUNT-LOCKED)
    
    (let ((sender-balance (default-to u0 (map-get? customer-account-balances tx-sender)))
          (recipient-balance (default-to u0 (map-get? customer-account-balances recipient-address))))
      
      (asserts! (>= sender-balance transfer-amount) ERR-INSUFFICIENT-BALANCE)
      
      ;; Update account balances
      (map-set customer-account-balances tx-sender (- sender-balance transfer-amount))
      (map-set customer-account-balances recipient-address (+ recipient-balance transfer-amount))
      
      ;; Log transactions for both parties
      (log-transaction-to-ledger tx-sender "transfer-sent" transfer-amount)
      (log-transaction-to-ledger recipient-address "transfer-received" transfer-amount)
      
      (ok transfer-amount))))

;; ACCOUNT INFORMATION SERVICES

;; Retrieve customer account balance
(define-public (get-account-balance (customer-address principal))
  (ok (default-to u0 (map-get? customer-account-balances customer-address))))

;; Calculate remaining daily withdrawal limit
(define-public (get-remaining-daily-limit (customer-address principal))
  (begin
    (asserts! (is-customer-registered customer-address) ERR-ACCOUNT-NOT-FOUND)
    (let ((todays-withdrawn (get-todays-withdrawal-amount customer-address))
          (daily-limit (var-get active-daily-withdrawal-limit)))
      (ok (if (>= todays-withdrawn daily-limit)
              u0
              (- daily-limit todays-withdrawn))))))

;; Query transaction history with pagination
(define-public (get-transaction-history (customer-address principal) (start-id uint) (limit uint))
  (begin
    (asserts! (or (is-eq tx-sender customer-address) (is-eq tx-sender contract-owner)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-customer-registered customer-address) ERR-ACCOUNT-NOT-FOUND)
    (asserts! (<= limit maximum-history-query-results) ERR-HISTORY-QUERY-LIMIT-EXCEEDED)
    (asserts! (> start-id u0) ERR-INVALID-AMOUNT)
    
    (ok { 
      start-transaction-id: start-id, 
      query-limit: limit, 
      total-transactions: (var-get next-transaction-identifier) 
    })))

;; ADMINISTRATIVE FUNCTIONS

;; Toggle system operational status
(define-public (set-system-operational-status (is-operational bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (var-set platform-operational-status is-operational)
    (ok is-operational)))

;; Configure withdrawal transaction fee
(define-public (configure-withdrawal-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= new-fee maximum-allowed-transaction-fee) ERR-EXCESSIVE-TRANSACTION-FEE)
    (var-set active-withdrawal-fee new-fee)
    (ok new-fee)))

;; Configure daily withdrawal limit
(define-public (configure-daily-withdrawal-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (>= new-limit minimum-allowed-daily-limit) ERR-MINIMUM-LIMIT-VIOLATION)
    (asserts! (<= new-limit maximum-allowed-daily-limit) ERR-MAXIMUM-LIMIT-VIOLATION)
    (var-set active-daily-withdrawal-limit new-limit)
    (ok new-limit)))

;; Administrative emergency account unlock
(define-public (emergency-unlock-account (locked-customer-address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-customer-registered locked-customer-address) ERR-ACCOUNT-NOT-FOUND)
    
    (map-set account-security-profiles locked-customer-address
      { 
        is-locked: false, 
        failed-attempts: u0, 
        unlock-code-hash: empty-security-hash 
      })
    
    (log-transaction-to-ledger locked-customer-address "emergency-unlock" u0)
    (ok true)))

;; Configure maximum unlock attempts
(define-public (configure-unlock-attempt-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (and (>= new-limit minimum-security-attempt-threshold) 
                   (<= new-limit maximum-security-attempt-threshold)) ERR-SECURITY-ATTEMPTS-OUT-OF-BOUNDS)
    (var-set maximum-unlock-attempt-threshold new-limit)
    (ok new-limit)))

;; Emergency system fund withdrawal
(define-public (emergency-withdraw-system-funds (emergency-amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> emergency-amount u0) ERR-INVALID-AMOUNT)
    (try! (as-contract (stx-transfer? emergency-amount tx-sender contract-owner)))
    (log-transaction-to-ledger contract-owner "emergency-system-withdrawal" emergency-amount)
    (ok emergency-amount)))

;; READ-ONLY INFORMATION SERVICES

;; Get current system operational status
(define-read-only (get-system-operational-status)
  (var-get platform-operational-status))

;; Get active withdrawal fee
(define-read-only (get-active-withdrawal-fee)
  (var-get active-withdrawal-fee))

;; Get active daily withdrawal limit
(define-read-only (get-active-daily-withdrawal-limit)
  (var-get active-daily-withdrawal-limit))

;; Get cumulative system deposits
(define-read-only (get-cumulative-system-deposits)
  (var-get cumulative-system-deposits))

;; Get cumulative system withdrawals
(define-read-only (get-cumulative-system-withdrawals)
  (var-get cumulative-system-withdrawals))

;; Check customer registration status
(define-read-only (is-customer-account-registered (customer-address principal))
  (is-customer-registered customer-address))

;; Check customer account lock status
(define-read-only (is-customer-account-locked (customer-address principal))
  (is-account-currently-locked customer-address))

;; Get customer security profile
(define-read-only (get-customer-security-profile (customer-address principal))
  (map-get? account-security-profiles customer-address))

;; Get customer failed unlock attempts
(define-read-only (get-customer-failed-attempts (customer-address principal))
  (get-failed-unlock-attempts customer-address))

;; Get total system transaction count
(define-read-only (get-total-system-transaction-count)
  (var-get next-transaction-identifier))

;; Get specific transaction details
(define-read-only (get-transaction-details (transaction-id uint))
  (map-get? system-transaction-ledger transaction-id))

;; Get unlock attempt limit setting
(define-read-only (get-unlock-attempt-limit)
  (var-get maximum-unlock-attempt-threshold))

;; Get total contract balance
(define-read-only (get-total-contract-balance)
  (stx-get-balance (as-contract tx-sender)))

;; Get customer's daily withdrawal amount
(define-read-only (get-customer-daily-withdrawal-amount (customer-address principal))
  (get-todays-withdrawal-amount customer-address))

;; Get comprehensive system information
(define-read-only (get-comprehensive-system-overview)
  {
    system-operational: (var-get platform-operational-status),
    withdrawal-fee: (var-get active-withdrawal-fee),
    daily-withdrawal-limit: (var-get active-daily-withdrawal-limit),
    total-deposits: (var-get cumulative-system-deposits),
    total-withdrawals: (var-get cumulative-system-withdrawals),
    contract-balance: (stx-get-balance (as-contract tx-sender)),
    current-banking-day: (get-current-banking-day),
    transaction-count: (var-get next-transaction-identifier),
    unlock-attempt-limit: (var-get maximum-unlock-attempt-threshold)
  })