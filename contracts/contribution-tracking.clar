;; Contribution Tracking Contract
;; Records and manages backer contributions and reward selections

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-CAMPAIGN-ENDED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))

;; Data Variables
(define-data-var next-contribution-id uint u1)

;; Data Maps
(define-map contributions uint {
  campaign-id: uint,
  contributor: principal,
  amount: uint,
  reward-tier: uint,
  timestamp: uint,
  status: (string-ascii 20)
})

(define-map campaign-contributions uint (list 1000 uint))
(define-map contributor-campaigns principal (list 100 uint))
(define-map campaign-totals uint uint)

;; Reward tiers
(define-map reward-tiers { campaign-id: uint, tier-id: uint } {
  name: (string-ascii 50),
  description: (string-ascii 200),
  min-amount: uint,
  max-backers: uint,
  current-backers: uint
})

;; Public Functions

;; Add reward tier to campaign
(define-public (add-reward-tier (campaign-id uint) (tier-id uint) (name (string-ascii 50)) (description (string-ascii 200)) (min-amount uint) (max-backers uint))
  (begin
    (asserts! (> min-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (> max-backers u0) ERR-INVALID-AMOUNT)

    (map-set reward-tiers { campaign-id: campaign-id, tier-id: tier-id } {
      name: name,
      description: description,
      min-amount: min-amount,
      max-backers: max-backers,
      current-backers: u0
    })
    (ok true)))

;; Make a contribution to a campaign
(define-public (contribute (campaign-id uint) (reward-tier uint) (amount uint))
  (let ((contribution-id (var-get next-contribution-id))
        (reward-info (map-get? reward-tiers { campaign-id: campaign-id, tier-id: reward-tier })))

    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    ;; Validate reward tier if specified
    (if (> reward-tier u0)
      (begin
        (asserts! (is-some reward-info) ERR-CAMPAIGN-NOT-FOUND)
        (let ((tier (unwrap-panic reward-info)))
          (asserts! (>= amount (get min-amount tier)) ERR-INVALID-AMOUNT)
          (asserts! (< (get current-backers tier) (get max-backers tier)) ERR-INVALID-AMOUNT)

          ;; Update reward tier backer count
          (map-set reward-tiers { campaign-id: campaign-id, tier-id: reward-tier }
            (merge tier { current-backers: (+ (get current-backers tier) u1) }))))
      true)

    ;; Transfer STX from contributor
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Record contribution
    (map-set contributions contribution-id {
      campaign-id: campaign-id,
      contributor: tx-sender,
      amount: amount,
      reward-tier: reward-tier,
      timestamp: block-height,
      status: "active"
    })

    ;; Update campaign contributions list
    (let ((campaign-contribs (default-to (list) (map-get? campaign-contributions campaign-id))))
      (map-set campaign-contributions campaign-id
        (unwrap! (as-max-len? (append campaign-contribs contribution-id) u1000) ERR-INVALID-AMOUNT)))

    ;; Update contributor campaigns list
    (let ((contributor-camps (default-to (list) (map-get? contributor-campaigns tx-sender))))
      (map-set contributor-campaigns tx-sender
        (unwrap! (as-max-len? (append contributor-camps campaign-id) u100) ERR-INVALID-AMOUNT)))

    ;; Update campaign total
    (let ((current-total (default-to u0 (map-get? campaign-totals campaign-id))))
      (map-set campaign-totals campaign-id (+ current-total amount)))

    (var-set next-contribution-id (+ contribution-id u1))
    (ok contribution-id)))

;; Update contribution status
(define-public (update-contribution-status (contribution-id uint) (new-status (string-ascii 20)))
  (let ((contribution (unwrap! (map-get? contributions contribution-id) ERR-CAMPAIGN-NOT-FOUND)))
    (asserts! (is-eq (get contributor contribution) tx-sender) ERR-NOT-AUTHORIZED)
    (map-set contributions contribution-id (merge contribution { status: new-status }))
    (ok true)))

;; Read-only Functions

;; Get contribution details
(define-read-only (get-contribution (contribution-id uint))
  (map-get? contributions contribution-id))

;; Get campaign contributions
(define-read-only (get-campaign-contributions (campaign-id uint))
  (map-get? campaign-contributions campaign-id))

;; Get contributor campaigns
(define-read-only (get-contributor-campaigns (contributor principal))
  (map-get? contributor-campaigns contributor))

;; Get campaign total funding
(define-read-only (get-campaign-total (campaign-id uint))
  (default-to u0 (map-get? campaign-totals campaign-id)))

;; Get reward tier info
(define-read-only (get-reward-tier (campaign-id uint) (tier-id uint))
  (map-get? reward-tiers { campaign-id: campaign-id, tier-id: tier-id }))

;; Get contribution count for campaign
(define-read-only (get-contribution-count (campaign-id uint))
  (len (default-to (list) (map-get? campaign-contributions campaign-id))))

;; Check if user contributed to campaign
(define-read-only (has-contributed (campaign-id uint) (contributor principal))
  (is-some (index-of (default-to (list) (map-get? contributor-campaigns contributor)) campaign-id)))
