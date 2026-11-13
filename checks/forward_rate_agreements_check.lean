-- Forward rate agreements: the fixed rate that makes the agreement worth nothing today is exactly the forward rate the two discount factors contain, and the start-of-period settlement leaves a borrower repaying the locked rate whatever the fixing.
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-! Notation, as on the card. `D₁` and `D₂` are today's prices of one dollar paid at the start
`T₁` and the end `T₂` of the period. `α` is the year fraction, `N` the notional, `K` the fixed
rate in the contract and `L` the fixing read at `T₁`. Rates are simple.

* the forward rate: `F = (D₁ / D₂ - 1) / α`;
* the value today of the side that pays `K` and receives the fixing:
  `V = N * (D₁ - (1 + α * K) * D₂)`;
* the interest difference due at `T₂`: `X = N * α * (L - K)`;
* the settlement actually paid at `T₁`: `S = N * α * (L - K) / (1 + α * L)`. -/

/-- The card's main claim. Two discount factors pin the rate for the period between them, and
an FRA locks it. With a positive price `D₂` of a dollar at the end of the period and a contract
that is not empty (nonzero notional and nonzero year fraction), the agreement is worth nothing
today exactly when its fixed rate `K` is the forward rate `(D₁ / D₂ - 1) / α`. And whenever a
dollar deposited over the period does not vanish (`1 + α L > 0`), a borrower who takes the
settlement `S` at the start, borrows `N - S` at the fixing `L`, and repays it at the end repays
exactly `N (1 + α K)`: the notional at the locked rate, whatever the fixing. -/
theorem fra_locks_forward_rate (N α D₁ D₂ K L : ℝ) (hD₂ : 0 < D₂) (hN : N ≠ 0) (hα : α ≠ 0)
    (hL : 0 < 1 + α * L) :
    (N * (D₁ - (1 + α * K) * D₂) = 0 ↔ K = (D₁ / D₂ - 1) / α) ∧
    (N - N * α * (L - K) / (1 + α * L)) * (1 + α * L) = N * (1 + α * K) := by
  constructor
  · have hD : D₂ ≠ 0 := ne_of_gt hD₂
    constructor
    · intro h
      have h' : D₁ - (1 + α * K) * D₂ = 0 := (mul_eq_zero.mp h).resolve_left hN
      rw [eq_div_iff hα, eq_sub_iff_add_eq, eq_div_iff hD]
      linarith
    · intro h
      rw [eq_div_iff hα, eq_sub_iff_add_eq, eq_div_iff hD] at h
      have h' : D₁ - (1 + α * K) * D₂ = 0 := by linarith
      rw [h', mul_zero]
  · have hL' : 1 + α * L ≠ 0 := ne_of_gt hL
    field_simp
    ring

/-- The value of an agreement already on the books, written two ways, is the same number: the
rate gap `F - K` turned into money over the period and discounted, `N α D₂ (F - K)`, equals one
dollar per unit of notional at `T₁` against a dollar plus locked interest at `T₂`,
`N (D₁ - (1 + α K) D₂)`. Paying the end-of-period amount `X` at the start instead, shrunk by the
forward growth `1 + α F`, has the same value today. Here both prices are positive and the year
fraction is nonzero. -/
theorem fra_value_two_forms (N α D₁ D₂ K X : ℝ) (hD₁ : 0 < D₁) (hD₂ : 0 < D₂) (hα : α ≠ 0) :
    N * α * D₂ * ((D₁ / D₂ - 1) / α - K) = N * (D₁ - (1 + α * K) * D₂) ∧
    D₁ * (X / (1 + α * ((D₁ / D₂ - 1) / α))) = D₂ * X := by
  have hD₂' : D₂ ≠ 0 := ne_of_gt hD₂
  have hD₁' : D₁ ≠ 0 := ne_of_gt hD₁
  constructor
  · field_simp
    ring
  · have h : 1 + α * ((D₁ / D₂ - 1) / α) = D₁ / D₂ := by
      field_simp
      ring
    rw [h]
    field_simp

/-- The early payment is the same deal as the late one. With `1 + α L > 0`, the settlement `S`
paid at `T₁`, deposited at the fixing for the period, grows to exactly the interest difference
`X = N α (L - K)` due at `T₂`. And on the fixing date itself, where `D(T₁) = 1` and
`D(T₂) = 1 / (1 + α L)`, the value of the agreement equals that settlement. -/
theorem fra_settlement_at_start (N α K L : ℝ) (hL : 0 < 1 + α * L) :
    N * α * (L - K) / (1 + α * L) * (1 + α * L) = N * α * (L - K) ∧
    N * (1 - (1 + α * K) * (1 / (1 + α * L))) = N * α * (L - K) / (1 + α * L) := by
  have hL' : 1 + α * L ≠ 0 := ne_of_gt hL
  constructor
  · field_simp
  · field_simp
    ring

/-! The card's worked numbers, in exact fractions. Kestrel Dairy: notional 1,000,000, year
fraction 1, one-year growth 105/100, two-year growth 1113/1000, locked at 6/100, fixing 8/100. -/

-- Growth across the second year: 1.113 / 1.05 = 1.06, so the forward rate is 6 percent.
example : ((1113 / 1000 : ℚ) / (105 / 100) - 1) / 1 = 6 / 100 := by norm_num

-- The same from the discount factors D(1) = 1 / 1.05 and D(2) = 1 / 1.113.
example : (((1 / (105 / 100) : ℚ)) / (1 / (1113 / 1000)) - 1) / 1 = 6 / 100 := by norm_num

-- Growth multiplies, it does not add: 1.05 × 1.06 = 1.113, while 5 + 6 ≠ 11.3 percent.
example : (105 / 100 : ℚ) * (106 / 100) = 1113 / 1000 := by norm_num
example : (5 / 100 : ℚ) + 6 / 100 ≠ 113 / 1000 := by norm_num

-- The wrong forward from subtracting rates: 0.113 - 0.05 = 0.063, so 63,000 of interest.
example : (1000000 : ℚ) * 1 * (113 / 1000 - 5 / 100) = 63000 := by norm_num

-- The ledger: borrow 1,000,000 / 1.05 for two years; it costs 1,060,000 at year two.
example : (1000000 / (105 / 100) : ℚ) * (1113 / 1000) = 1060000 := by norm_num

-- Interest locked in, interest at the fixing, and the difference X at year two.
example : (1000000 : ℚ) * 1 * (6 / 100) = 60000 := by norm_num
example : (1000000 : ℚ) * 1 * (8 / 100) = 80000 := by norm_num
example : (1000000 : ℚ) * 1 * (8 / 100 - 6 / 100) = 20000 := by norm_num

-- The settlement at year one: 20,000 / 1.08 = 500000/27 (18,518.52).
example : (1000000 : ℚ) * 1 * (8 / 100 - 6 / 100) / (1 + 1 * (8 / 100)) = 500000 / 27 := by
  norm_num

-- Borrow the million less the settlement at 8 percent: repay exactly 1,060,000.
example : ((1000000 : ℚ) - 500000 / 27) * (1 + 1 * (8 / 100)) = 1060000 := by norm_num

-- At a 4 percent fixing Kestrel pays 250000/13 (19,230.77).
example : (1000000 : ℚ) * 1 * (4 / 100 - 6 / 100) / (1 + 1 * (4 / 100)) = -(250000 / 13) := by
  norm_num

-- A contract struck at 5 percent on today's curve: worth 10,000,000/1,113 (8,984.73), in both forms.
example : (1000000 : ℚ) * (1 / (105 / 100) - (1 + 1 * (5 / 100)) * (1 / (1113 / 1000))) =
    10000000 / 1113 := by norm_num
example : (1000000 : ℚ) * 1 * (1 / (1113 / 1000)) * (6 / 100 - 5 / 100) = 10000000 / 1113 := by
  norm_num

-- Paying the 20,000 a year early without shrinking it: 21,600 by year two, 1,600 over.
example : (20000 : ℚ) * (1 + 1 * (8 / 100)) = 21600 := by norm_num

-- Shrinking at the curve's 6 percent instead of the fixing: 20000/1.06 grows to 20,377.36 at 8 percent.
example : (20000 : ℚ) / (106 / 100) * (108 / 100) = 1080000 / 53 := by norm_num

-- A 3-against-9 with year fraction 183/360: the difference is 30500/3 (10,166.67), not 20,000.
example : (1000000 : ℚ) * (183 / 360) * (8 / 100 - 6 / 100) = 30500 / 3 := by norm_num

#print axioms fra_locks_forward_rate
#print axioms fra_value_two_forms
#print axioms fra_settlement_at_start
