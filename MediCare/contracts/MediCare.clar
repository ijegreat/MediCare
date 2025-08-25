;; Healthcare Voucher System Contract
;; A community-centered healthcare system that uses blockchain to issue vouchers and promote equal access to medical services

;; Define constants
(define-constant HEALTH-COORDINATOR tx-sender)
(define-constant ERROR-NOT-HEALTH-COORDINATOR (err u100))
(define-constant ERROR-VOUCHER-ALREADY-CLAIMED (err u101))
(define-constant ERROR-PATIENT-NOT-ELIGIBLE (err u102))
(define-constant ERROR-INSUFFICIENT-VOUCHER-SUPPLY (err u103))
(define-constant ERROR-HEALTH-PROGRAM-INACTIVE (err u104))
(define-constant ERROR-INVALID-VOUCHER-VALUE (err u105))
(define-constant ERROR-TREATMENT-PERIOD-NOT-ENDED (err u106))
(define-constant ERROR-INVALID-PATIENT (err u107))
(define-constant ERROR-INVALID-PROGRAM-DURATION (err u108))

;; Define data variables
(define-data-var is-health-program-active bool true)
(define-data-var total-vouchers-distributed uint u0)
(define-data-var voucher-value-per-patient uint u100)
(define-data-var health-program-start-block uint stacks-block-height)
(define-data-var treatment-cycle-duration uint u10000) ;; Number of blocks after which unused vouchers can be reallocated

;; Define data maps
(define-map eligible-healthcare-patients principal bool)
(define-map distributed-voucher-amounts principal uint)

;; Define fungible token
(define-fungible-token health-voucher-token)

;; Define events
(define-data-var next-medical-record-id uint u0)
(define-map medical-records uint {record-type: (string-ascii 20), notes: (string-ascii 256)})

;; Medical record logging function
(define-private (log-medical-record (record-type (string-ascii 20)) (notes (string-ascii 256)))
  (let ((record-id (var-get next-medical-record-id)))
    (map-set medical-records record-id {record-type: record-type, notes: notes})
    (var-set next-medical-record-id (+ record-id u1))
    record-id))

;; Health coordinator functions

(define-public (register-eligible-patient (patient-address principal))
  (begin
    (asserts! (is-eq tx-sender HEALTH-COORDINATOR) ERROR-NOT-HEALTH-COORDINATOR)
    (asserts! (is-none (map-get? eligible-healthcare-patients patient-address)) ERROR-INVALID-PATIENT)
    (log-medical-record "registered" "new patient registered for healthcare vouchers")
    (ok (map-set eligible-healthcare-patients patient-address true))))

(define-public (remove-patient-eligibility (patient-address principal))
  (begin
    (asserts! (is-eq tx-sender HEALTH-COORDINATOR) ERROR-NOT-HEALTH-COORDINATOR)
    (asserts! (is-some (map-get? eligible-healthcare-patients patient-address)) ERROR-PATIENT-NOT-ELIGIBLE)
    (log-medical-record "removed" "patient healthcare eligibility revoked")
    (ok (map-delete eligible-healthcare-patients patient-address))))

(define-public (bulk-register-patients (patient-addresses (list 200 principal)))
  (begin
    (asserts! (is-eq tx-sender HEALTH-COORDINATOR) ERROR-NOT-HEALTH-COORDINATOR)
    (log-medical-record "bulk-registered" "multiple patients registered")
    (ok (map register-eligible-patient patient-addresses))))

(define-public (update-voucher-value (new-value uint))
  (begin
    (asserts! (is-eq tx-sender HEALTH-COORDINATOR) ERROR-NOT-HEALTH-COORDINATOR)
    (asserts! (> new-value u0) ERROR-INVALID-VOUCHER-VALUE)
    (var-set voucher-value-per-patient new-value)
    (log-medical-record "value-updated" "healthcare voucher value per patient updated")
    (ok new-value)))

(define-public (update-treatment-duration (new-duration uint))
  (begin
    (asserts! (is-eq tx-sender HEALTH-COORDINATOR) ERROR-NOT-HEALTH-COORDINATOR)
    (asserts! (> new-duration u0) ERROR-INVALID-PROGRAM-DURATION)
    (var-set treatment-cycle-duration new-duration)
    (log-medical-record "duration-updated" "treatment cycle duration updated")
    (ok new-duration)))

;; Voucher distribution function

(define-public (claim-health-voucher)
  (let (
    (patient-address tx-sender)
    (voucher-allocation (var-get voucher-value-per-patient))
  )
    (asserts! (var-get is-health-program-active) ERROR-HEALTH-PROGRAM-INACTIVE)
    (asserts! (is-some (map-get? eligible-healthcare-patients patient-address)) ERROR-PATIENT-NOT-ELIGIBLE)
    (asserts! (is-none (map-get? distributed-voucher-amounts patient-address)) ERROR-VOUCHER-ALREADY-CLAIMED)
    (asserts! (<= voucher-allocation (ft-get-balance health-voucher-token HEALTH-COORDINATOR)) ERROR-INSUFFICIENT-VOUCHER-SUPPLY)
    (try! (ft-transfer? health-voucher-token voucher-allocation HEALTH-COORDINATOR patient-address))
    (map-set distributed-voucher-amounts patient-address voucher-allocation)
    (var-set total-vouchers-distributed (+ (var-get total-vouchers-distributed) voucher-allocation))
    (log-medical-record "voucher-claimed" "healthcare voucher distributed to patient")
    (ok voucher-allocation)))

;; Voucher reallocation function

(define-public (reallocate-unused-vouchers)
  (let (
    (current-block stacks-block-height)
    (reallocation-allowed-after (+ (var-get health-program-start-block) (var-get treatment-cycle-duration)))
  )
    (asserts! (is-eq tx-sender HEALTH-COORDINATOR) ERROR-NOT-HEALTH-COORDINATOR)
    (asserts! (>= current-block reallocation-allowed-after) ERROR-TREATMENT-PERIOD-NOT-ENDED)
    (let (
      (total-minted (ft-get-supply health-voucher-token))
      (total-distributed (var-get total-vouchers-distributed))
      (unused-amount (- total-minted total-distributed))
    )
      (try! (ft-burn? health-voucher-token unused-amount HEALTH-COORDINATOR))
      (log-medical-record "vouchers-reallocated" "unused healthcare vouchers reallocated")
      (ok unused-amount))))

;; Read-only functions

(define-read-only (get-health-program-status)
  (var-get is-health-program-active))

(define-read-only (is-patient-eligible (patient-address principal))
  (default-to false (map-get? eligible-healthcare-patients patient-address)))

(define-read-only (has-patient-claimed-voucher (patient-address principal))
  (is-some (map-get? distributed-voucher-amounts patient-address)))

(define-read-only (get-patient-voucher-amount (patient-address principal))
  (default-to u0 (map-get? distributed-voucher-amounts patient-address)))

(define-read-only (get-total-vouchers-distributed)
  (var-get total-vouchers-distributed))

(define-read-only (get-voucher-value-per-patient)
  (var-get voucher-value-per-patient))

(define-read-only (get-treatment-cycle-duration)
  (var-get treatment-cycle-duration))

(define-read-only (get-health-program-start-block)
  (var-get health-program-start-block))

(define-read-only (get-medical-record (record-id uint))
  (map-get? medical-records record-id))

;; Contract initialization

(begin
  (ft-mint? health-voucher-token u1000000000 HEALTH-COORDINATOR))