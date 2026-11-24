-- Feigenbaum renormalisation: the logistic map's first superstable dial for period 2 is exactly 1 + √5, with window (√5 - 1)/4, and the doubling operator keeps the top at height 1 exactly when alpha = -1/g(1).
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Dynamics.PeriodicPts.Defs
import Mathlib.Dynamics.PeriodicPts.Lemmas
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- The card's superstable dial `R_1`: for a positive dial `r`, the logistic map
`x ↦ r x (1 - x)` has a cycle of length exactly 2 through the top `x = 1/2`
if and only if `r = 1 + √5`. (The root `r = 2` is dropped because there
`1/2` is a fixed point, the period-1 dial `R_0`.) -/
theorem logistic_superstable_period_two_iff (r : ℝ) (hr : 0 < r) :
    Function.minimalPeriod (fun x : ℝ => r * x * (1 - x)) (1 / 2) = 2 ↔
      r = 1 + Real.sqrt 5 := by
  have : Fact (Nat.Prime 2) := Nat.fact_prime_two
  rw [Function.minimalPeriod_eq_prime_iff]
  simp only [Function.IsPeriodicPt, Function.IsFixedPt, Function.iterate_succ,
    Function.iterate_zero, Function.comp_apply, id]
  have hs : Real.sqrt 5 ^ 2 = 5 := Real.sq_sqrt (by norm_num)
  have hs0 : 0 ≤ Real.sqrt 5 := Real.sqrt_nonneg 5
  have hs1 : 1 < Real.sqrt 5 := by nlinarith
  constructor
  · rintro ⟨h1, h2⟩
    have h2' : r - 2 ≠ 0 := by
      intro h; apply h2; have : r = 2 := by linarith
      subst this; norm_num
    have hcub : (r - 2) * (r ^ 2 - 2 * r - 4) = 0 := by linear_combination (-16) * h1
    have hq : r ^ 2 - 2 * r - 4 = 0 := by
      rcases mul_eq_zero.mp hcub with h | h
      · exact absurd h h2'
      · exact h
    have hf : (r - (1 + Real.sqrt 5)) * (r - (1 - Real.sqrt 5)) = 0 := by
      linear_combination hq - hs
    rcases mul_eq_zero.mp hf with h | h
    · linarith
    · linarith
  · intro h
    subst h
    constructor
    · linear_combination ((1 - Real.sqrt 5) / 16) * hs
    · intro h
      linarith

/-- The card's first window `d_1`: at the dial `r = 1 + √5`, the distance from the
top `1/2` to the other cycle point `f(1/2)` is `(√5 - 1)/4` (about 0.309017). -/
theorem logistic_first_window (r : ℝ) (hr : r = 1 + Real.sqrt 5) :
    r * (1 / 2) * (1 - 1 / 2) - 1 / 2 = (Real.sqrt 5 - 1) / 4 := by
  subst hr
  ring

/-- Step 1 of the card: for a shape `g` with its top scaled to `g 0 = 1` (and
`g 1 ≠ 0`, so that `alpha = -1/g(1)` makes sense), the doubled shape
`(T g)(x) = -alpha * g (g (-x / alpha))` keeps height 1 at the top
exactly when `alpha = -1 / g 1`. -/
theorem doubling_operator_keeps_top_iff (g : ℝ → ℝ) (hg0 : g 0 = 1) (hg1 : g 1 ≠ 0)
    (α : ℝ) :
    (fun x : ℝ => -α * g (g (-x / α))) 0 = 1 ↔ α = -1 / g 1 := by
  simp only [neg_zero, zero_div, hg0]
  rw [eq_div_iff hg1]
  constructor
  · intro h; linarith
  · intro h; linarith

-- Worked numbers from the card.
-- The cubic for the period-2 superstable dial factors as (r - 2)(r^2 - 2r - 4).
example (r : ℝ) : r ^ 3 - 4 * r ^ 2 + 8 = (r - 2) * (r ^ 2 - 2 * r - 4) := by ring
-- Two steps from the top: f(f(1/2)) = r^2 (4 - r) / 16, so f(f(1/2)) = 1/2 is the cubic.
example (r : ℝ) :
    r * (r * (1 / 2) * (1 - 1 / 2)) * (1 - r * (1 / 2) * (1 - 1 / 2)) - 1 / 2
      = -(r ^ 3 - 4 * r ^ 2 + 8) / 16 := by ring
-- At the dial R_0 = 2 the top is a fixed point: 2 * (1/2) * (1 - 1/2) = 1/2.
example : (2 : ℚ) * (1 / 2) * (1 - 1 / 2) = 1 / 2 := by norm_num

#print axioms logistic_superstable_period_two_iff
#print axioms logistic_first_window
#print axioms doubling_operator_keeps_top_iff
