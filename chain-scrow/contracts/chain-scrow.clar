;; Chain-Scrow: Simple Escrow Service on Stacks
;; Holds STX funds until conditions are met

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-ESCROW-NOT-FOUND (err u404))
(define-constant ERR-INSUFFICIENT-FUNDS (err u402))
(define-constant ERR-ESCROW-ALREADY-RELEASED (err u403))
(define-constant ERR-ESCROW-ALREADY-REFUNDED (err u405))
(define-constant ERR-INVALID-AMOUNT (err u406))

;; Data variables
(define-data-var escrow-counter uint u0)

;; Escrow status constants
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-RELEASED u2)
(define-constant STATUS-REFUNDED u3)

;; Escrow data structure
(define-map escrows
  uint
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    status: uint,
    created-at: uint,
    description: (string-ascii 256)
  }
)

;; Get escrow details
(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows escrow-id)
)

;; Get current escrow counter
(define-read-only (get-escrow-counter)
  (var-get escrow-counter)
)

;; Create new escrow
(define-public (create-escrow (seller principal) (description (string-ascii 256)))
  (let (
    (escrow-id (+ (var-get escrow-counter) u1))
    (amount (stx-get-balance tx-sender))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set escrows escrow-id {
      buyer: tx-sender,
      seller: seller,
      amount: amount,
      status: STATUS-ACTIVE,
      created-at: block-height,
      description: description
    })
    (var-set escrow-counter escrow-id)
    (ok escrow-id)
  )
)

;; Create escrow with specific amount
(define-public (create-escrow-with-amount (seller principal) (amount uint) (description (string-ascii 256)))
  (let (
    (escrow-id (+ (var-get escrow-counter) u1))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= (stx-get-balance tx-sender) amount) ERR-INSUFFICIENT-FUNDS)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set escrows escrow-id {
      buyer: tx-sender,
      seller: seller,
      amount: amount,
      status: STATUS-ACTIVE,
      created-at: block-height,
      description: description
    })
    (var-set escrow-counter escrow-id)
    (ok escrow-id)
  )
)

;; Release funds to seller (only buyer can call)
(define-public (release-escrow (escrow-id uint))
  (let (
    (escrow-data (unwrap! (map-get? escrows escrow-id) ERR-ESCROW-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get buyer escrow-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status escrow-data) STATUS-ACTIVE) ERR-ESCROW-ALREADY-RELEASED)
    (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get seller escrow-data))))
    (map-set escrows escrow-id (merge escrow-data { status: STATUS-RELEASED }))
    (ok true)
  )
)

;; Refund to buyer (only seller can call)
(define-public (refund-escrow (escrow-id uint))
  (let (
    (escrow-data (unwrap! (map-get? escrows escrow-id) ERR-ESCROW-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (get seller escrow-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status escrow-data) STATUS-ACTIVE) ERR-ESCROW-ALREADY-REFUNDED)
    (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get buyer escrow-data))))
    (map-set escrows escrow-id (merge escrow-data { status: STATUS-REFUNDED }))
    (ok true)
  )
)

;; Emergency refund by buyer (if seller is unresponsive after certain blocks)
(define-public (emergency-refund (escrow-id uint))
  (let (
    (escrow-data (unwrap! (map-get? escrows escrow-id) ERR-ESCROW-NOT-FOUND))
    (blocks-passed (- block-height (get created-at escrow-data)))
  )
    (asserts! (is-eq tx-sender (get buyer escrow-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status escrow-data) STATUS-ACTIVE) ERR-ESCROW-ALREADY-REFUNDED)
    (asserts! (>= blocks-passed u1008) ERR-NOT-AUTHORIZED) ;; ~1 week in blocks
    (try! (as-contract (stx-transfer? (get amount escrow-data) tx-sender (get buyer escrow-data))))
    (map-set escrows escrow-id (merge escrow-data { status: STATUS-REFUNDED }))
    (ok true)
  )
)

;; Check if escrow is active
(define-read-only (is-escrow-active (escrow-id uint))
  (match (map-get? escrows escrow-id)
    escrow-data (is-eq (get status escrow-data) STATUS-ACTIVE)
    false
  )
)

;; Get escrow status
(define-read-only (get-escrow-status (escrow-id uint))
  (match (map-get? escrows escrow-id)
    escrow-data (ok (get status escrow-data))
    ERR-ESCROW-NOT-FOUND
  )
)

;; Get escrows by buyer
(define-read-only (get-buyer-escrows (buyer principal))
  (let (
    (counter (var-get escrow-counter))
  )
    (filter-escrows-by-buyer buyer u1 counter)
  )
)

;; Helper function to filter escrows by buyer
(define-private (filter-escrows-by-buyer (buyer principal) (start uint) (end uint))
  (fold check-escrow-buyer (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) (list))
)

;; Helper function to check if escrow belongs to buyer
(define-private (check-escrow-buyer (escrow-id uint) (acc (list 10 uint)))
  (match (map-get? escrows escrow-id)
    escrow-data (if (is-eq (get buyer escrow-data) tx-sender)
                    (unwrap-panic (as-max-len? (append acc escrow-id) u10))
                    acc)
    acc
  )
)