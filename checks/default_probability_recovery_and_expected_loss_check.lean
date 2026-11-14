-- Default probability, recovery and expected loss: over finitely many year-end states, expected loss equals PD times the default-weighted LGD times EAD, the break-even spread is (1 + r) ℓ / (1 - ℓ), and any one factor back-solves uniquely from the loss and the other two.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Algebra.BigOperators.Ring.Finset

open Finset

/-- Expected loss is the chance of default times the loss given default times the exposure,
exactly. The year ends in one of finitely many states `k` with chances `w k` (nonnegative,
summing to 1). In state `k` the default switch `I k` is 1 or 0, and `G k` is the fraction lost.
With `PD = ∑ w k I k` and `LGD = (∑ w k I k G k) / PD`, the average over the default states,
the expected loss `∑ w k (I k G k EAD)` equals `PD × LGD × EAD`. No independence is needed. -/
theorem expected_loss_eq_pd_mul_lgd_mul_ead {ι : Type*} [Fintype ι]
    (w I G : ι → ℝ) (EAD : ℝ)
    (hw : ∀ k, 0 ≤ w k) (hw1 : ∑ k, w k = 1)
    (hI : ∀ k, I k = 0 ∨ I k = 1) :
    ∑ k, w k * (I k * G k * EAD) =
      (∑ k, w k * I k) * ((∑ k, w k * I k * G k) / (∑ k, w k * I k)) * EAD := by
  have h1 : ∑ k, w k * (I k * G k * EAD) = (∑ k, w k * I k * G k) * EAD := by
    rw [Finset.sum_mul]
    refine Finset.sum_congr rfl ?_
    intro k _
    ring
  rw [h1]
  by_cases hP : ∑ k, w k * I k = 0
  · have hnn : ∀ k ∈ (univ : Finset ι), 0 ≤ w k * I k := fun k _ =>
      mul_nonneg (hw k) (by rcases hI k with h | h <;> simp [h])
    have hz := (Finset.sum_eq_zero_iff_of_nonneg hnn).1 hP
    have h0 : ∑ k, w k * I k * G k = 0 :=
      Finset.sum_eq_zero (fun k hk => by rw [hz k hk]; ring)
    rw [h0, hP]
    simp
  · field_simp

/-- The break-even loan rate. A one-year loan at rate `y` is repaid in full with chance
`1 - PD` and recovers the fraction `R` of everything owed with chance `PD`. If the average
receipt matches a riskless loan at rate `r`, and the expected-loss rate `ℓ = PD × (1 - R)`
is below 1, then the credit spread is `y - r = (1 + r) ℓ / (1 - ℓ)`. -/
theorem fair_credit_spread (PD R r y : ℝ)
    (hℓ : PD * (1 - R) < 1)
    (hfair : (1 + y) * ((1 - PD) + PD * R) = 1 + r) :
    y - r = (1 + r) * (PD * (1 - R)) / (1 - PD * (1 - R)) := by
  have hpos : 0 < 1 - PD * (1 - R) := by linarith
  rw [eq_div_iff hpos.ne']
  linear_combination hfair

/-- Running it backwards: when the other two factors are nonzero, the probability of default
is fixed by the expected loss, `PD × LGD × EAD = EL` exactly when `PD = EL / (LGD × EAD)`.
One division, one answer. -/
theorem pd_back_solve_unique (PD LGD EAD EL : ℝ) (hL : LGD ≠ 0) (hE : EAD ≠ 0) :
    PD * LGD * EAD = EL ↔ PD = EL / (LGD * EAD) := by
  rw [eq_div_iff (mul_ne_zero hL hE), mul_assoc]

-- The cafe: EAD $10,000, PD 5%, recovery 40%, riskless rate 5%.
example : (1 : ℝ) - 40 / 100 = 60 / 100 := by norm_num
example : (60 / 100 : ℝ) * 10000 = 6000 := by norm_num
example : (40 / 100 : ℝ) * 10000 = 4000 := by norm_num
example : (5 / 100 : ℝ) * (60 / 100) = 3 / 100 := by norm_num
example : (5 / 100 : ℝ) * (60 / 100) * 10000 = 300 := by norm_num
-- Listing the outcomes: 95% chance of losing 0, 5% chance of losing $6,000.
example : (95 / 100 : ℝ) * 0 + 5 / 100 * 6000 = 300 := by norm_num
-- Fair loan rate 1.05 / 0.97 - 1 = 8/97 (about 8.25%), spread 63/1940 (about 3.25%).
example : (1 + 5 / 100 : ℝ) / (1 - 3 / 100) - 1 = 8 / 97 := by norm_num
example : (8 / 97 : ℝ) - 5 / 100 = 63 / 1940 := by norm_num
example : (1 + 5 / 100 : ℝ) * (3 / 100) / (1 - 3 / 100) = 63 / 1940 := by norm_num
-- Spread with a riskless rate of 0: 1 / 0.97 - 1 = 3/97 (about 3.09%).
example : (1 : ℝ) / (1 - 3 / 100) - 1 = 3 / 97 := by norm_num
-- Back-solves.
example : (9 / 100 : ℝ) / (1 - 40 / 100) = 15 / 100 := by norm_num
example : (300 : ℝ) / (5 / 100 * 10000) = 60 / 100 := by norm_num
example : (300 : ℝ) / (5 / 100 * (60 / 100)) = 10000 := by norm_num
-- A 9% loss rate at 95% recovery asks for a 180% chance of default: impossible.
example : (9 / 100 : ℝ) / (1 - 95 / 100) = 18 / 10 ∧ (1 : ℝ) < 18 / 10 := by norm_num
-- Two kinds of year: good (80%, PD 2.5%, recovery 55%), bad (20%, PD 15%, recovery 30%).
example : (80 / 100 : ℝ) * (25 / 1000) + 20 / 100 * (15 / 100) = 5 / 100 := by norm_num
example : (80 / 100 : ℝ) * (55 / 100) + 20 / 100 * (30 / 100) = 50 / 100 := by norm_num
example : ((80 / 100 : ℝ) * (25 / 1000) * (55 / 100) + 20 / 100 * (15 / 100) * (30 / 100))
    / (5 / 100) = 40 / 100 := by norm_num
example : (80 / 100 : ℝ) * (25 / 1000) * (10000 * (1 - 55 / 100))
    + 20 / 100 * (15 / 100) * (10000 * (1 - 30 / 100)) = 300 := by norm_num
example : (5 / 100 : ℝ) * (1 - 50 / 100) * 10000 = 250 := by norm_num
-- What breaks: recovery used as the loss, and default treated as certain.
example : (5 / 100 : ℝ) * (40 / 100) * 10000 = 200 := by norm_num
example : (1 : ℝ) * (60 / 100) * 10000 = 6000 := by norm_num
-- Charging 5% + 3% = 8% leaves the lender 160/7 dollars (about $22.86) short in today's money.
example : (10000 : ℝ) * (108 / 100) * (1 - 3 / 100) / (1 + 5 / 100) - 10000 = -(160 / 7) := by
  norm_num
-- Try changing: PD 10%, recovery 0, and the fair rate at PD 20% (17/88, about 19.32%).
example : (10 / 100 : ℝ) * (60 / 100) * 10000 = 600 := by norm_num
example : (5 / 100 : ℝ) * 1 * 10000 = 500 := by norm_num
example : (1 + 5 / 100 : ℝ) / (1 - 20 / 100 * (60 / 100)) - 1 = 17 / 88 := by norm_num
-- The chart: EL on the $10,000 loan at recoveries 0%, 20%, ..., 100%, for PD 15%.
example : [0, 20, 40, 60, 80, 100].map (fun x : ℚ => 15 / 100 * (1 - x / 100) * 10000)
    = [1500, 1200, 900, 600, 300, 0] := by norm_num

#print axioms expected_loss_eq_pd_mul_lgd_mul_ead
#print axioms fair_credit_spread
#print axioms pd_back_solve_unique
