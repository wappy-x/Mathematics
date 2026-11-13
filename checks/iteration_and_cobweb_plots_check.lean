-- Iteration: a settling orbit of a continuous rule settles on a point the rule leaves unchanged, and the card's two rules have the fixed points and error law it computes.
import Mathlib.Dynamics.FixedPoints.Topology
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

open Filter Topology

/-! The rule is a map `g : ℝ → ℝ`. The orbit from `x₀` is `x₀, g x₀, g (g x₀), …`;
its `n`-th value `xₙ = gⁿ(x₀)` is Mathlib's `g^[n] x₀` (apply `g` `n` times, not a power).
"The orbit settles on `x⋆`" is `Tendsto (fun n => g^[n] x₀) atTop (𝓝 x⋆)`.
A fixed point is a value with `g x⋆ = x⋆`.
The square-root rule is `x ↦ (x + 2/x)/2`; the logistic map is `x ↦ r x (1 - x)`. -/

/-- Step 3 of the card: if the orbit of a continuous rule settles on a number `x⋆`,
then the rule leaves `x⋆` unchanged, `g x⋆ = x⋆`. -/
theorem settling_orbit_settles_on_fixed_point (g : ℝ → ℝ) (hg : Continuous g)
    (x₀ xstar : ℝ) (h : Tendsto (fun n : ℕ => g^[n] x₀) atTop (𝓝 xstar)) :
    g xstar = xstar := by
  exact isFixedPt_of_tendsto_iterate h hg.continuousAt

/-- Step 4 of the card: for the square-root rule, the new error is the old error squared
over twice the guess, `xₙ₊₁ - √2 = (xₙ - √2)² / (2 xₙ)`, for every nonzero guess. -/
theorem sqrt_rule_error_squares (x : ℝ) (hx : x ≠ 0) :
    (x + 2 / x) / 2 - Real.sqrt 2 = (x - Real.sqrt 2) ^ 2 / (2 * x) := by
  have h2 : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have h2x : (2 : ℝ) * x ≠ 0 := mul_ne_zero two_ne_zero hx
  rw [eq_div_iff h2x]
  field_simp
  nlinarith [h2]

/-- The logistic map's resting levels: `r x (1 - x) = x` exactly when the lake is empty,
`x = 0`, or the stock sits at `x⋆ = 1 - 1/r`. -/
theorem logistic_fixed_points (r x : ℝ) (hr : r ≠ 0) :
    r * x * (1 - x) = x ↔ x = 0 ∨ x = 1 - 1 / r := by
  constructor
  · intro h
    have h' : x * (r * (1 - x) - 1) = 0 := by linear_combination h
    rcases mul_eq_zero.mp h' with h0 | h1
    · exact Or.inl h0
    · right
      field_simp
      linear_combination -h1
  · rintro (h0 | h1)
    · subst h0; ring
    · subst h1
      field_simp
      ring

-- The square-root rule from 1, as exact fractions: 3/2, 17/12, 577/408, 665857/470832.
example : (fun x : ℚ => (x + 2 / x) / 2)^[1] 1 = 3 / 2 := by
  norm_num
example : (fun x : ℚ => (x + 2 / x) / 2)^[2] 1 = 17 / 12 := by
  norm_num [Function.iterate_succ_apply']
example : (fun x : ℚ => (x + 2 / x) / 2)^[3] 1 = 577 / 408 := by
  norm_num [Function.iterate_succ_apply']
example : (fun x : ℚ => (x + 2 / x) / 2)^[4] 1 = 665857 / 470832 := by
  norm_num [Function.iterate_succ_apply']
-- The whole-number road: p/q goes to (p² + 2q²)/(2pq); four steps from 1/1 give 665857/470832.
example : (fun pq : ℕ × ℕ => (pq.1 * pq.1 + 2 * pq.2 * pq.2, 2 * pq.1 * pq.2))^[4] (1, 1)
    = (665857, 470832) := by
  decide
-- The fish stock at r = 2.8 = 14/5 from 0.2 = 1/5: year 1 is 0.448 = 56/125.
example : (14 / 5 : ℚ) * (1 / 5) * (1 - 1 / 5) = 56 / 125 := by norm_num
-- Year 2 is exactly 54096/78125 = 0.6924288, printed as 0.692429.
example : (14 / 5 : ℚ) * (56 / 125) * (1 - 56 / 125) = 54096 / 78125 := by norm_num
-- The resting level 1 - 1/2.8 = 9/14 = 0.642857..., and the rule leaves it unchanged.
example : (1 : ℚ) - 1 / (14 / 5) = 9 / 14 := by norm_num
example : (14 / 5 : ℚ) * (9 / 14) * (1 - 9 / 14) = 9 / 14 := by norm_num
-- Mistake 1: g(x) = 0 at 0 and 1, an empty lake and a full one, not the resting level.
example : (14 / 5 : ℚ) * 0 * (1 - 0) = 0 ∧ (14 / 5 : ℚ) * 1 * (1 - 1) = 0 := by norm_num
-- Mistake 2: the rule 2/x from 1 boxes 1, 2, 1, 2, 1.
example : (fun x : ℚ => 2 / x)^[1] 1 = 2 ∧ (fun x : ℚ => 2 / x)^[4] 1 = 1 := by
  norm_num [Function.iterate_succ_apply']
-- Mistake 3: g(0.2) squared is 0.200704 = 3136/15625, not g(g(0.2)).
example : ((14 / 5 : ℚ) * (1 / 5) * (1 - 1 / 5)) ^ 2 = 3136 / 15625 := by norm_num

#print axioms settling_orbit_settles_on_fixed_point
#print axioms sqrt_rule_error_squares
#print axioms logistic_fixed_points
