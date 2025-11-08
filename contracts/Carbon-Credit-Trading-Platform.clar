(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-not-authorized (err u104))
(define-constant err-already-verified (err u105))
(define-constant err-not-verified (err u106))
(define-constant err-listing-not-active (err u107))
(define-constant err-insufficient-payment (err u108))

(define-data-var next-credit-id uint u1)
(define-data-var next-listing-id uint u1)
(define-data-var platform-fee-percentage uint u250)

(define-map carbon-credits
  uint
  {
    owner: principal,
    amount: uint,
    project-name: (string-ascii 100),
    vintage-year: uint,
    verified: bool,
    created-at: uint
  }
)

(define-map credit-listings
  uint
  {
    credit-id: uint,
    seller: principal,
    price-per-credit: uint,
    amount: uint,
    active: bool,
    created-at: uint
  }
)

(define-map user-balances
  { user: principal, credit-id: uint }
  uint
)

(define-map verifiers
  principal
  bool
)

(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set verifiers verifier true))
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-delete verifiers verifier))
  )
)

(define-public (mint-carbon-credit (amount uint) (project-name (string-ascii 100)) (vintage-year uint))
  (let
    (
      (credit-id (var-get next-credit-id))
      (current-block stacks-block-height)
    )
    (asserts! (> amount u0) err-invalid-amount)
    (map-set carbon-credits credit-id {
      owner: tx-sender,
      amount: amount,
      project-name: project-name,
      vintage-year: vintage-year,
      verified: false,
      created-at: current-block
    })
    (map-set user-balances { user: tx-sender, credit-id: credit-id } amount)
    (var-set next-credit-id (+ credit-id u1))
    (ok credit-id)
  )
)

(define-public (verify-credit (credit-id uint))
  (let
    (
      (credit (unwrap! (map-get? carbon-credits credit-id) err-not-found))
      (is-verifier (default-to false (map-get? verifiers tx-sender)))
    )
    (asserts! is-verifier err-not-authorized)
    (asserts! (not (get verified credit)) err-already-verified)
    (ok (map-set carbon-credits credit-id (merge credit { verified: true })))
  )
)

(define-public (create-listing (credit-id uint) (price-per-credit uint) (amount uint))
  (let
    (
      (credit (unwrap! (map-get? carbon-credits credit-id) err-not-found))
      (user-balance (default-to u0 (map-get? user-balances { user: tx-sender, credit-id: credit-id })))
      (listing-id (var-get next-listing-id))
      (current-block stacks-block-height)
    )
    (asserts! (get verified credit) err-not-verified)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= user-balance amount) err-insufficient-balance)
    (map-set credit-listings listing-id {
      credit-id: credit-id,
      seller: tx-sender,
      price-per-credit: price-per-credit,
      amount: amount,
      active: true,
      created-at: current-block
    })
    (var-set next-listing-id (+ listing-id u1))
    (ok listing-id)
  )
)

(define-public (cancel-listing (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? credit-listings listing-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get seller listing)) err-not-authorized)
    (asserts! (get active listing) err-listing-not-active)
    (ok (map-set credit-listings listing-id (merge listing { active: false })))
  )
)

(define-public (purchase-credits (listing-id uint) (purchase-amount uint))
  (let
    (
      (listing (unwrap! (map-get? credit-listings listing-id) err-not-found))
      (credit-id (get credit-id listing))
      (seller (get seller listing))
      (price-per-credit (get price-per-credit listing))
      (available-amount (get amount listing))
      (total-cost (* purchase-amount price-per-credit))
      (platform-fee (/ (* total-cost (var-get platform-fee-percentage)) u10000))
      (seller-payment (- total-cost platform-fee))
      (seller-balance (default-to u0 (map-get? user-balances { user: seller, credit-id: credit-id })))
      (buyer-balance (default-to u0 (map-get? user-balances { user: tx-sender, credit-id: credit-id })))
    )
    (asserts! (get active listing) err-listing-not-active)
    (asserts! (> purchase-amount u0) err-invalid-amount)
    (asserts! (<= purchase-amount available-amount) err-insufficient-balance)
    (asserts! (>= seller-balance purchase-amount) err-insufficient-balance)
    (try! (stx-transfer? total-cost tx-sender seller))
    (if (> platform-fee u0)
      (try! (stx-transfer? platform-fee seller contract-owner))
      true
    )
    (map-set user-balances { user: seller, credit-id: credit-id } (- seller-balance purchase-amount))
    (map-set user-balances { user: tx-sender, credit-id: credit-id } (+ buyer-balance purchase-amount))
    (if (is-eq purchase-amount available-amount)
      (map-set credit-listings listing-id (merge listing { active: false, amount: u0 }))
      (map-set credit-listings listing-id (merge listing { amount: (- available-amount purchase-amount) }))
    )
    (ok purchase-amount)
  )
)

(define-public (retire-credits (credit-id uint) (amount uint))
  (let
    (
      (user-balance (default-to u0 (map-get? user-balances { user: tx-sender, credit-id: credit-id })))
    )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= user-balance amount) err-insufficient-balance)
    (map-set user-balances { user: tx-sender, credit-id: credit-id } (- user-balance amount))
    (ok amount)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u1000) err-invalid-amount)
    (ok (var-set platform-fee-percentage new-fee))
  )
)

(define-read-only (get-credit (credit-id uint))
  (map-get? carbon-credits credit-id)
)

(define-read-only (get-listing (listing-id uint))
  (map-get? credit-listings listing-id)
)

(define-read-only (get-user-balance (user principal) (credit-id uint))
  (ok (default-to u0 (map-get? user-balances { user: user, credit-id: credit-id })))
)

(define-read-only (is-verifier (user principal))
  (default-to false (map-get? verifiers user))
)

(define-read-only (get-platform-fee)
  (ok (var-get platform-fee-percentage))
)

(define-read-only (get-next-credit-id)
  (ok (var-get next-credit-id))
)

(define-read-only (get-next-listing-id)
  (ok (var-get next-listing-id))
)
