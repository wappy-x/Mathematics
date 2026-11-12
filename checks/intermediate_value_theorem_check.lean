-- Intermediate value theorem: a function continuous on a closed interval [a, b] takes every value between f(a) and f(b).
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.NumberTheory.Real.Irrational

open Set

/-- A function that is continuous on a closed interval [a, b] takes every value y
between f(a) and f(b) (in either order): some input c in [a, b] has f(c) = y.
The theorem promises at least one such c, not exactly one. -/
theorem continuous_function_hits_every_value_between_end_values
    (f : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b) (hf : ContinuousOn f (Icc a b))
    (y : ℝ) (hy : y ∈ uIcc (f a) (f b)) :
    ∃ c ∈ Icc a b, f c = y := by
  have h := intermediate_value_Icc hab hf
  have h' := intermediate_value_Icc' hab hf
  rcases le_total (f a) (f b) with hle | hle
  · rw [uIcc_of_le hle] at hy
    exact h hy
  · rw [uIcc_of_ge hle] at hy
    exact h' hy

/-- Bolzano's form, target 0: if f is continuous on [a, b], below zero at a and above
zero at b, then f has a root somewhere in [a, b]. -/
theorem sign_change_gives_root
    (f : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b) (hf : ContinuousOn f (Icc a b))
    (ha : f a < 0) (hb : 0 < f b) :
    ∃ c ∈ Icc a b, f c = 0 := by
  exact intermediate_value_Icc hab hf ⟨ha.le, hb.le⟩

/-- The gap-free line is needed: on the fractions, x^2 - 2 is below zero at 1 and above
zero at 2, yet no fraction in [1, 2] makes it zero. -/
theorem no_fraction_in_one_two_squares_to_two :
    (1 : ℚ) ^ 2 - 2 < 0 ∧ 0 < (2 : ℚ) ^ 2 - 2 ∧
      ∀ q : ℚ, 1 ≤ q → q ≤ 2 → q ^ 2 - 2 ≠ 0 := by
  refine ⟨by norm_num, by norm_num, ?_⟩
  intro q h1 _ hq
  have hq2 : ((q : ℝ)) ^ 2 = 2 := by
    have : q ^ 2 = 2 := by linarith
    exact_mod_cast this
  have hq0 : (0 : ℝ) ≤ q := by exact_mod_cast (show (0 : ℚ) ≤ q by linarith)
  have hs : Real.sqrt 2 = q := by rw [← hq2, Real.sqrt_sq hq0]
  exact irrational_sqrt_two ⟨q, hs.symm⟩

-- The tile's miss x^2 - 2 changes sign on [1, 2]: -1 at side 1, 2 at side 2.
example : (1 : ℚ) ^ 2 - 2 = -1 := by norm_num
example : (2 : ℚ) ^ 2 - 2 = 2 := by norm_num
-- The first four halvings, as fractions: 3/2, 5/4, 11/8, 23/16.
example : (3 / 2 : ℚ) ^ 2 - 2 = 1 / 4 := by norm_num
example : (5 / 4 : ℚ) ^ 2 - 2 = -7 / 16 := by norm_num
example : (11 / 8 : ℚ) ^ 2 - 2 = -7 / 64 := by norm_num
example : (23 / 16 : ℚ) ^ 2 - 2 = 17 / 256 := by norm_num
-- After 12 halvings the bracket is [5792/4096, 5793/4096]: the sign test in whole numbers.
example : 5792 * 5792 < 2 * 4096 * 4096 ∧ 2 * 4096 * 4096 < 5793 * 5793 := by decide
-- Its width is (2 - 1)/2^12 = 1/4096, and the midpoint is within 1/8192 of the root.
example : ((2 : ℚ) - 1) / 2 ^ 12 = 1 / 4096 := by norm_num
example : (5793 : ℚ) / 4096 - 5792 / 4096 = 1 / 4096 := by norm_num
-- The cubic h(x) = x^3 - x: -6 at -2, 6 at 2, and roots -1, 0 and 1.
example : (-2 : ℤ) ^ 3 - (-2) = -6 ∧ (2 : ℤ) ^ 3 - 2 = 6 := by decide
example : (-1 : ℤ) ^ 3 - (-1) = 0 ∧ (0 : ℤ) ^ 3 - 0 = 0 ∧ (1 : ℤ) ^ 3 - 1 = 0 := by decide

#print axioms continuous_function_hits_every_value_between_end_values
#print axioms sign_change_gives_root
#print axioms no_fraction_in_one_two_squares_to_two
