;; Milestone Verification Contract
;; Manages project progress markers and milestone-based fund release

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u101))
(define-constant ERR-MILESTONE-NOT-FOUND (err u106))
(define-constant ERR-ALREADY-COMPLETED (err u107))
(define-constant ERR-INVALID-AMOUNT (err u102))

;; Data Variables
(define-data-var next-milestone-id uint u1)

;; Data Maps
(define-map milestones uint {
  campaign-id: uint,
  milestone-id: uint,
  title: (string-ascii 100),
  description: (string-ascii 300),
  target-amount: uint,
  completion-status: bool,
  completed-at: (optional uint),
  evidence-url: (optional (string-ascii 200))
})

(define-map campaign-milestones uint (list 20 uint))
(define-map milestone-votes { milestone-id: uint, voter: principal } bool)
(define-map milestone-vote-counts uint { yes: uint, no: uint, total: uint })

;; Public Functions

;; Create a milestone for a campaign
(define-public (create-milestone (campaign-id uint) (title (string-ascii 100)) (description (string-ascii 300)) (target-amount uint))
  (let ((milestone-id (var-get next-milestone-id)))
    (asserts! (> target-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= (len title) u100) ERR-INVALID-AMOUNT)
    (asserts! (<= (len description) u300) ERR-INVALID-AMOUNT)

    (map-set milestones milestone-id {
      campaign-id: campaign-id,
      milestone-id: milestone-id,
      title: title,
      description: description,
      target-amount: target-amount,
      completion-status: false,
      completed-at: none,
      evidence-url: none
    })

    ;; Add to campaign milestones list
    (let ((campaign-miles (default-to (list) (map-get? campaign-milestones campaign-id))))
      (map-set campaign-milestones campaign-id
        (unwrap! (as-max-len? (append campaign-miles milestone-id) u20) ERR-INVALID-AMOUNT)))

    ;; Initialize vote counts
    (map-set milestone-vote-counts milestone-id { yes: u0, no: u0, total: u0 })

    (var-set next-milestone-id (+ milestone-id u1))
    (ok milestone-id)))

;; Submit milestone completion with evidence
(define-public (submit-milestone-completion (milestone-id uint) (evidence-url (string-ascii 200)))
  (let ((milestone (unwrap! (map-get? milestones milestone-id) ERR-MILESTONE-NOT-FOUND)))
    (asserts! (not (get completion-status milestone)) ERR-ALREADY-COMPLETED)

    (map-set milestones milestone-id (merge milestone {
      evidence-url: (some evidence-url)
    }))
    (ok true)))

;; Vote on milestone completion
(define-public (vote-on-milestone (milestone-id uint) (vote bool))
  (let ((milestone (unwrap! (map-get? milestones milestone-id) ERR-MILESTONE-NOT-FOUND))
        (vote-key { milestone-id: milestone-id, voter: tx-sender })
        (existing-vote (map-get? milestone-votes vote-key))
        (vote-counts (unwrap! (map-get? milestone-vote-counts milestone-id) ERR-MILESTONE-NOT-FOUND)))

    (asserts! (is-none existing-vote) ERR-ALREADY-COMPLETED)

    ;; Record the vote
    (map-set milestone-votes vote-key vote)

    ;; Update vote counts
    (let ((new-yes (if vote (+ (get yes vote-counts) u1) (get yes vote-counts)))
          (new-no (if vote (get no vote-counts) (+ (get no vote-counts) u1)))
          (new-total (+ (get total vote-counts) u1)))

      (map-set milestone-vote-counts milestone-id {
        yes: new-yes,
        no: new-no,
        total: new-total
      })

      ;; Check if milestone should be marked complete (simple majority)
      (if (and (> new-total u2) (> new-yes (/ new-total u2)))
        (begin
          (map-set milestones milestone-id (merge milestone {
            completion-status: true,
            completed-at: (some block-height)
          }))
          (ok "milestone-completed"))
        (ok "vote-recorded")))))

;; Mark milestone as verified (for campaign creator)
(define-public (verify-milestone (milestone-id uint))
  (let ((milestone (unwrap! (map-get? milestones milestone-id) ERR-MILESTONE-NOT-FOUND)))
    (asserts! (not (get completion-status milestone)) ERR-ALREADY-COMPLETED)

    (map-set milestones milestone-id (merge milestone {
      completion-status: true,
      completed-at: (some block-height)
    }))
    (ok true)))

;; Read-only Functions

;; Get milestone details
(define-read-only (get-milestone (milestone-id uint))
  (map-get? milestones milestone-id))

;; Get campaign milestones
(define-read-only (get-campaign-milestones (campaign-id uint))
  (map-get? campaign-milestones campaign-id))

;; Get milestone vote counts
(define-read-only (get-milestone-votes (milestone-id uint))
  (map-get? milestone-vote-counts milestone-id))

;; Check if user voted on milestone
(define-read-only (has-voted (milestone-id uint) (voter principal))
  (is-some (map-get? milestone-votes { milestone-id: milestone-id, voter: voter })))

;; Get user's vote on milestone
(define-read-only (get-user-vote (milestone-id uint) (voter principal))
  (map-get? milestone-votes { milestone-id: milestone-id, voter: voter }))

;; Calculate milestone completion percentage for campaign
(define-read-only (get-campaign-progress (campaign-id uint))
  (let ((milestone-list (default-to (list) (map-get? campaign-milestones campaign-id))))
    (if (is-eq (len milestone-list) u0)
      u0
      (let ((completed-count (fold count-completed-milestones milestone-list u0)))
        (/ (* completed-count u100) (len milestone-list))))))

;; Helper function for counting completed milestones
(define-private (count-completed-milestones (milestone-id uint) (acc uint))
  (match (map-get? milestones milestone-id)
    milestone (if (get completion-status milestone) (+ acc u1) acc)
    acc))
