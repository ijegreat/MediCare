# Healthcare Voucher System

A decentralized healthcare voucher distribution system built on the Stacks blockchain. This smart contract enables community-centered healthcare access by issuing blockchain-based vouchers to eligible patients, promoting equal access to medical services.

## Overview

The Healthcare Voucher System uses fungible tokens to represent healthcare vouchers that can be distributed to eligible patients. The system is managed by a health coordinator who can register patients, distribute vouchers, and manage the overall program.

## Features

- **Patient Registration**: Health coordinators can register eligible patients for healthcare vouchers
- **Voucher Distribution**: Eligible patients can claim their allocated healthcare vouchers
- **Medical Record Logging**: All system activities are logged with medical records
- **Flexible Configuration**: Voucher values and treatment durations can be updated
- **Bulk Operations**: Support for registering multiple patients at once
- **Voucher Reallocation**: Unused vouchers can be reallocated after treatment cycles end

## Contract Architecture

### Constants
- `HEALTH-COORDINATOR`: The principal address that manages the system
- Error codes for various failure scenarios (100-108)

### Data Variables
- `is-health-program-active`: Boolean flag for program status
- `total-vouchers-distributed`: Total number of vouchers distributed
- `voucher-value-per-patient`: Amount of vouchers each patient receives (default: 100)
- `health-program-start-block`: Block height when the program started
- `treatment-cycle-duration`: Duration in blocks for treatment cycles (default: 10,000)

### Data Maps
- `eligible-healthcare-patients`: Maps patient addresses to eligibility status
- `distributed-voucher-amounts`: Tracks voucher amounts distributed to each patient
- `medical-records`: Stores medical record entries with types and notes

## Functions

### Health Coordinator Functions

#### `register-eligible-patient`
Registers a new patient as eligible for healthcare vouchers.
```clarity
(register-eligible-patient principal)
```

#### `remove-patient-eligibility`
Removes a patient's eligibility for healthcare vouchers.
```clarity
(remove-patient-eligibility principal)
```

#### `bulk-register-patients`
Registers multiple patients in a single transaction (up to 200 patients).
```clarity
(bulk-register-patients (list 200 principal))
```

#### `update-voucher-value`
Updates the voucher value per patient.
```clarity
(update-voucher-value uint)
```

#### `update-treatment-duration`
Updates the treatment cycle duration.
```clarity
(update-treatment-duration uint)
```

### Patient Functions

#### `claim-health-voucher`
Allows eligible patients to claim their healthcare vouchers.
```clarity
(claim-health-voucher)
```

### Administrative Functions

#### `reallocate-unused-vouchers`
Reallocates unused vouchers after treatment period ends (coordinator only).
```clarity
(reallocate-unused-vouchers)
```

### Read-Only Functions

- `get-health-program-status`: Returns program active status
- `is-patient-eligible`: Checks if a patient is eligible
- `has-patient-claimed-voucher`: Checks if patient has claimed vouchers
- `get-patient-voucher-amount`: Returns voucher amount for a patient
- `get-total-vouchers-distributed`: Returns total distributed vouchers
- `get-voucher-value-per-patient`: Returns current voucher value
- `get-treatment-cycle-duration`: Returns treatment cycle duration
- `get-health-program-start-block`: Returns program start block
- `get-medical-record`: Retrieves medical record by ID

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | NOT-HEALTH-COORDINATOR | Only health coordinator can perform this action |
| 101 | VOUCHER-ALREADY-CLAIMED | Patient has already claimed their voucher |
| 102 | PATIENT-NOT-ELIGIBLE | Patient is not eligible for vouchers |
| 103 | INSUFFICIENT-VOUCHER-SUPPLY | Not enough vouchers available |
| 104 | HEALTH-PROGRAM-INACTIVE | Health program is not active |
| 105 | INVALID-VOUCHER-VALUE | Voucher value must be greater than 0 |
| 106 | TREATMENT-PERIOD-NOT-ENDED | Cannot reallocate before treatment period ends |
| 107 | INVALID-PATIENT | Patient address is invalid |
| 108 | INVALID-PROGRAM-DURATION | Program duration must be greater than 0 |

## Usage Examples

### Deploying the Contract
The contract automatically mints 1,000,000,000 health voucher tokens to the health coordinator upon deployment.

### Registering Patients
```clarity
;; Register a single patient
(contract-call? .healthcare-voucher register-eligible-patient 'SP1ABCDEF...)

;; Register multiple patients
(contract-call? .healthcare-voucher bulk-register-patients 
  (list 'SP1ABCDEF... 'SP2GHIJKL... 'SP3MNOPQR...))
```

### Claiming Vouchers
```clarity
;; Patient claims their vouchers
(contract-call? .healthcare-voucher claim-health-voucher)
```

### Updating System Parameters
```clarity
;; Update voucher value to 150 tokens per patient
(contract-call? .healthcare-voucher update-voucher-value u150)

;; Update treatment cycle duration to 15,000 blocks
(contract-call? .healthcare-voucher update-treatment-duration u15000)
```

## Medical Record System

The contract includes a medical record logging system that tracks all major activities:
- Patient registrations
- Voucher claims
- System parameter updates
- Voucher reallocations

Each record includes a type (up to 20 ASCII characters) and notes (up to 256 ASCII characters).

## Security Considerations

- Only the health coordinator can register patients and modify system parameters
- Patients can only claim vouchers once
- Voucher reallocation is time-locked to prevent premature redistribution
- All major operations are logged for audit purposes

## Development

### Prerequisites
- Stacks blockchain environment
- Clarity smart contract development tools

### Testing
Ensure to test all functions with various scenarios:
- Valid and invalid patient registrations
- Voucher claiming by eligible and ineligible patients
- System parameter updates
- Voucher reallocation timing

