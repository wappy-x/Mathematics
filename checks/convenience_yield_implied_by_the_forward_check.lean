-- Convenience yield: for positive spot, positive forward and positive time, exactly one yield makes the carry formula hit the forward, it is r + u - ln(F/S)/T, and it is zero at the ceiling and negative above it.
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open Real

/-- The convenience yield implied by the forward exists and is unique, and the
card's formula gives it: with spot `S > 0`, market forward `F > 0` and time to
delivery `T > 0`, a yield `y` makes the carry formula `F = S e^{(r+u-y)T}` land
exactly on the market forward if and only if `y = r + u - ln(F/S)/T`. -/
theorem convenience_yield_unique_and_formula (S F T r u : ℝ)
    (hS : 0 < S) (hF : 0 < F) (hT : 0 < T) (y : ℝ) :
    F = S * exp ((r + u - y) * T) ↔ y = r + u - log (F / S) / T := by
  constructor
  · intro h
    have hl : log (F / S) = (r + u - y) * T := by
      rw [h, mul_div_cancel_left₀ _ hS.ne', log_exp]
    rw [hl]; field_simp; ring
  · intro h
    have hl : (r + u - y) * T = log (F / S) := by
      rw [h]; field_simp; ring
    rw [hl, exp_log (div_pos hF hS)]; field_simp

/-- Every yield is hit by exactly one forward: for `S > 0` and `T > 0`, the map
`f(y) = S e^{(r+u-y)T}` is strictly falling, and its values are exactly the
positive numbers. -/
theorem implied_forward_strictAnti_and_onto_positives (S T r u : ℝ)
    (hS : 0 < S) (hT : 0 < T) :
    StrictAnti (fun y : ℝ => S * exp ((r + u - y) * T)) ∧
      Set.range (fun y : ℝ => S * exp ((r + u - y) * T)) = Set.Ioi 0 := by
  refine ⟨?_, ?_⟩
  · intro a b hab
    exact mul_lt_mul_of_pos_left (exp_lt_exp.mpr (by nlinarith)) hS
  · ext x
    constructor
    · rintro ⟨y, rfl⟩
      exact mul_pos hS (exp_pos _)
    · intro hx
      exact ⟨r + u - log (x / S) / T,
        ((convenience_yield_unique_and_formula S x T r u hS hx hT _).mpr rfl).symm⟩

/-- The boundary cases: with `S > 0`, `F > 0`, `T > 0` and ceiling
`C = S e^{(r+u)T}`, a forward at the ceiling gives yield zero, a forward above
the ceiling gives a negative yield, and a forward at spot gives `y = r + u`. -/
theorem convenience_yield_boundary_cases (S F T r u : ℝ)
    (hS : 0 < S) (hF : 0 < F) (hT : 0 < T) :
    (r + u - log (S * exp ((r + u) * T) / S) / T = 0) ∧
      (S * exp ((r + u) * T) < F ↔ r + u - log (F / S) / T < 0) ∧
      (r + u - log (S / S) / T = r + u) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [mul_div_cancel_left₀ _ hS.ne', log_exp]; field_simp; ring
  · rw [log_div hF.ne' hS.ne', sub_neg, lt_div_iff₀ hT]
    rw [← log_lt_log_iff (mul_pos hS (exp_pos _)) hF, log_mul hS.ne' (exp_pos _).ne', log_exp]
    constructor <;> intro h <;> linarith
  · rw [div_self hS.ne', log_one]; simp

-- Card, Step 4: at spot, F = S = 80, with r = 5%, u = 2%, T = 1, the yield is 7%.
example : (1 / 20 : ℝ) + 1 / 50 - log (80 / 80) / 1 = 7 / 100 := by
  norm_num

-- Card, "What breaks": using F/S - 1 in place of ln(F/S) gives 2.00%.
example : (1 / 20 : ℚ) + 1 / 50 - (84 / 80 - 1) / 1 = 1 / 50 := by
  norm_num

#print axioms convenience_yield_unique_and_formula
#print axioms implied_forward_strictAnti_and_onto_positives
#print axioms convenience_yield_boundary_cases
