-- Extreme value theorem: a function continuous on a closed interval [a, b] of real numbers, with a ≤ b, takes a largest and a smallest value at inputs in that interval; the bed's area x(1 - x) has top 1/4 at x = 1/2 only and bottom 0 at the ends; and dropping an end, continuity or a finite end can lose the extreme.
import Mathlib.Topology.Order.Compact
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- Extreme value theorem: if `f` is continuous at every point of the closed interval `[a, b]`
(at an end, judged from inside only), with `a` and `b` finite real numbers and `a ≤ b`, then
there are inputs `c` and `d` in `[a, b]` with `f d ≤ f x ≤ f c` for every `x` in `[a, b]`:
some allowed input gives an output nothing beats, and some gives an output nothing undercuts. -/
theorem continuous_on_closed_interval_attains_max_and_min (f : ℝ → ℝ) (a b : ℝ) (hab : a ≤ b)
    (hf : ContinuousOn f (Set.Icc a b)) :
    ∃ c ∈ Set.Icc a b, ∃ d ∈ Set.Icc a b, ∀ x ∈ Set.Icc a b, f d ≤ f x ∧ f x ≤ f c := by
  obtain ⟨c, hc, hmax⟩ := isCompact_Icc.exists_isMaxOn (Set.nonempty_Icc.mpr hab) hf
  obtain ⟨d, hd, hmin⟩ := isCompact_Icc.exists_isMinOn (Set.nonempty_Icc.mpr hab) hf
  exact ⟨c, hc, d, hd, fun x hx => ⟨hmin hx, hmax hx⟩⟩

/-- The bed: the area `x(1 - x)` equals `1/4 - (x - 1/2)^2`. On `[0, 1]` it lies between 0 and
1/4; the top 1/4 is reached at `x = 1/2` and nowhere else, and the bottom 0 at `x = 0` and `x = 1`. -/
theorem bed_area_top_quarter_at_half_bottom_zero_at_ends :
    (∀ x : ℝ, x * (1 - x) = 1 / 4 - (x - 1 / 2) ^ 2) ∧
      (∀ x ∈ Set.Icc (0 : ℝ) 1, 0 ≤ x * (1 - x) ∧ x * (1 - x) ≤ 1 / 4) ∧
      ((1 : ℝ) / 2 * (1 - 1 / 2) = 1 / 4) ∧
      (∀ x : ℝ, x * (1 - x) = 1 / 4 → x = 1 / 2) ∧
      ((0 : ℝ) * (1 - 0) = 0 ∧ (1 : ℝ) * (1 - 1) = 0) := by
  refine ⟨fun x => by ring, fun x hx => ⟨?_, ?_⟩, by norm_num, fun x hx => ?_, by norm_num⟩
  · obtain ⟨h0, h1⟩ := hx
    exact mul_nonneg h0 (by linarith)
  · nlinarith [sq_nonneg (x - 1 / 2)]
  · have h2 : (x - 1 / 2) ^ 2 = 0 := by nlinarith
    have h3 : x - 1 / 2 = 0 := pow_eq_zero_iff (two_ne_zero) |>.mp h2
    linarith

/-- Drop a hypothesis and the guarantee goes. Ends left out: `g(x) = x` on `(0, 1)` has no
largest value. A jump: the rule equal to `x` below 1 and 0 at `x = 1` has no largest value on
`[0, 1]`. No finite right end: `x(1 - x)` on `[0, ∞)` has no smallest value. -/
theorem dropping_a_hypothesis_loses_the_extreme :
    (¬ ∃ c ∈ Set.Ioo (0 : ℝ) 1, ∀ x ∈ Set.Ioo (0 : ℝ) 1, x ≤ c) ∧
      (¬ ∃ c ∈ Set.Icc (0 : ℝ) 1, ∀ x ∈ Set.Icc (0 : ℝ) 1,
          (if x < 1 then x else 0) ≤ (if c < 1 then c else 0)) ∧
      (¬ ∃ d ∈ Set.Ici (0 : ℝ), ∀ x ∈ Set.Ici (0 : ℝ), d * (1 - d) ≤ x * (1 - x)) := by
  refine ⟨?_, ?_, ?_⟩
  · rintro ⟨c, ⟨h0, h1⟩, h⟩
    have := h ((c + 1) / 2) ⟨by linarith, by linarith⟩
    linarith
  · rintro ⟨c, ⟨h0, h1⟩, h⟩
    by_cases hc : c < 1
    · have := h ((c + 1) / 2) ⟨by linarith, by linarith⟩
      have hx : (c + 1) / 2 < 1 := by linarith
      simp only [hx, hc, if_true] at this
      linarith
    · have := h (1 / 2) ⟨by norm_num, by norm_num⟩
      have hx : (1 : ℝ) / 2 < 1 := by norm_num
      simp only [hx, hc, if_true, if_false] at this
      linarith
  · rintro ⟨d, hd, h⟩
    have hd0 : (0 : ℝ) ≤ d := hd
    have := h (d + 2) (by simp only [Set.mem_Ici]; linarith)
    nlinarith

-- Worked numbers: x = 3/10 gives area 21/100; the top 1/4 at x = 1/2.
example : (3 : ℚ) / 10 * (1 - 3 / 10) = 21 / 100 := by norm_num
example : (1 : ℚ) / 2 * (1 - 1 / 2) = 1 / 4 := by norm_num
-- Whole-number form of the completed square, as the code checks at every k from 0 to 1000.
example (k : ℤ) : k * (1000 - k) = 250000 - (k - 500) ^ 2 := by ring
example : (500 : ℤ) * (1000 - 500) = 250000 ∧ (0 : ℤ) * (1000 - 0) = 0 ∧
    (1000 : ℤ) * (1000 - 1000) = 0 := by norm_num
-- Grids of step 1/N: the best grid point k beats every other, and misses 1/4 by (1/(2N))^2.
example : ∀ k ≤ 3, k * (3 - k) ≤ 1 * (3 - 1) := by decide
example : ∀ k ≤ 9, k * (9 - k) ≤ 4 * (9 - 4) := by decide
example : ∀ k ≤ 27, k * (27 - k) ≤ 13 * (27 - 13) := by decide
example : (1 : ℚ) / 4 - 1 * (3 - 1) / 3 ^ 2 = (1 / (2 * 3)) ^ 2 := by norm_num
example : (1 : ℚ) / 4 - 4 * (9 - 4) / 9 ^ 2 = (1 / (2 * 9)) ^ 2 := by norm_num
example : (1 : ℚ) / 4 - 13 * (27 - 13) / 27 ^ 2 = (1 / (2 * 27)) ^ 2 := by norm_num
example : (1 : ℚ) / 4 - 40 * (81 - 40) / 81 ^ 2 = (1 / (2 * 81)) ^ 2 := by norm_num
example : (1 : ℚ) / 4 - 121 * (243 - 121) / 243 ^ 2 = (1 / (2 * 243)) ^ 2 := by norm_num
-- Without a right end: f(10) = -90 and f(100) = -9900.
example : (10 : ℤ) * (1 - 10) = -90 ∧ (100 : ℤ) * (1 - 100) = -9900 := by norm_num

#print axioms continuous_on_closed_interval_attains_max_and_min
#print axioms bed_area_top_quarter_at_half_bottom_zero_at_ends
#print axioms dropping_a_hypothesis_loses_the_extreme
