# Karoo Organics – Supplier Compliance Auditor (Capstone 2)

## Overview
This project implements an automated supplier compliance auditor for Karoo Organics.  
Its goal is to proactively identify suppliers that pose reputational or regulatory risk
due to certification expiry, low commercial activity, or declining agricultural yield.

The solution replaces manual audits with a repeatable, data-driven control process.

---

## Risk Logic
Suppliers are flagged for review if **any** of the following conditions are met:

- Certification has expired or will expire within 30 days
- No orders placed in the last 90 days
- Latest harvest yield is less than 80% of the rolling 3-harvest average

These thresholds reflect standard agricultural compliance practices and early-warning indicators.

---

## Files Included

### `auditor_views.sql`
Defines:
- `v_supplier_health` monitoring view
- Risk-flagging query using CASE logic and window functions

### `audit_suppliers.py`
Python automation script that:
- Executes the risk query
- Updates supplier status using parameterised SQL
- Commits or rolls back safely
- Outputs a concise audit summary

### Schema Safety
The audit script defensively ensures required audit columns
(`status`, `last_audit`) exist before performing updates.
This allows the auditor to run safely on fresh or restored databases.

### `test_data.sql`
Minimal test data to demonstrate:
- Certification expiry
- Order inactivity
- Yield decline detection

---

## Compliance & Governance
- Designed for South African agricultural operations
- Supports traceability and audit readiness
- Avoids hardcoded credentials
- Ensures no partial updates occur

---

## How to Run
1. Execute `auditor_views.sql`
2. Load `test_data.sql`
3. Run:
   ```bash
   python audit_suppliers.py
