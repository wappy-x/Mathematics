-- Mean value theorem: a real function continuous on [a, b] and differentiable inside has, at some point strictly between a and b, a derivative equal to its average rate (f b - f a) / (b - a); with Rolle's theorem and "zero derivative on an unbroken stretch means constant".
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Set

/-- The mean value theorem. If a function has no jumps on the closed stretch from a to b and a
derivative at every inside point, then at some point c strictly between a and b the
instantaneous rate equals the average rate: f'(c) = (f(b) - f(a)) / (b - a). -/
theorem instantaneous_rate_equals_average_rate_somewhere (f : ℝ → ℝ) (a b : ℝ) (hab : a < b)
    (hcont : ContinuousOn f (Icc a b)) (hdiff : DifferentiableOn ℝ f (Ioo a b)) :
    ∃ c ∈ Ioo a b, deriv f c = (f b - f a) / (b - a) := by
  exact exists_deriv_eq_slope f hab hcont hdiff

/-- Rolle's theorem, the special case with equal ends. If f has no jumps on [a, b], a derivative
at every inside point, and f(a) = f(b), then some point strictly between a and b has a flat
tangent: f'(c) = 0. -/
theorem rolle_equal_ends_force_a_flat_point (f : ℝ → ℝ) (a b : ℝ) (hab : a < b)
    (hcont : ContinuousOn f (Icc a b)) (hdiff : DifferentiableOn ℝ f (Ioo a b))
    (hends : f a = f b) :
    ∃ c ∈ Ioo a b, deriv f c = 0 := by
  exact exists_deriv_eq_zero hab hcont hends

/-- Zero derivative means constant. If a function has derivative 0 at every point of one unbroken
stretch of the real line (a set with no gaps: whenever it holds x and y, it holds everything
between them), then it takes the same value at every point of that stretch. -/
theorem zero_derivative_on_unbroken_stretch_means_constant (f : ℝ → ℝ) (s : Set ℝ)
    (hs : s.OrdConnected) (hzero : ∀ x ∈ s, HasDerivWithinAt f 0 s x) :
    ∀ x ∈ s, ∀ y ∈ s, f x = f y := by
  intro x hx y hy
  have h := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f' := fun _ => (0 : ℝ)) (C := 0)
    hzero (fun _ _ => by simp) hs.convex hy hx
  have : ‖f x - f y‖ = 0 := le_antisymm (by simpa using h) (norm_nonneg _)
  exact sub_eq_zero.mp (norm_eq_zero.mp this)

-- The card's train: s(t) = 100 (3t^2 - 2t^3) km at t hours.
-- Positions at the ends: 0 km and 100 km.
example : (100 : ℝ) * (3 * 0 ^ 2 - 2 * 0 ^ 3) = 0 ∧ (100 : ℝ) * (3 * 1 ^ 2 - 2 * 1 ^ 3) = 100 := by
  norm_num
-- Average rate: (100 - 0) / (1 - 0) = 100 km/h.
example : ((100 : ℝ) - 0) / (1 - 0) = 100 := by norm_num
-- Speed at minutes 0, 6, ..., 60: with t = k/10 hours, v(t) = 600t(1 - t) = 6k(10 - k) km/h.
example : (List.range 11).map (fun k : ℕ => 6 * k * (10 - k)) =
    [0, 54, 96, 126, 144, 150, 144, 126, 96, 54, 0] := by decide
-- Setting the speed equal to the average: 600t - 600t^2 = 100 is 6t^2 - 6t + 1 = 0, times -100.
example (t : ℝ) : 600 * t - 600 * t ^ 2 - 100 = -100 * (6 * t ^ 2 - 6 * t + 1) := by ring
-- The discriminant under the quadratic formula: 36 - 24 = 12.
example : (6 : ℤ) ^ 2 - 4 * 6 * 1 = 12 := by decide
-- The two instants (3 - √3)/6 and (3 + √3)/6 hours both have speed exactly 100 km/h.
example : 600 * ((3 - Real.sqrt 3) / 6) - 600 * ((3 - Real.sqrt 3) / 6) ^ 2 = 100 ∧
    600 * ((3 + Real.sqrt 3) / 6) - 600 * ((3 + Real.sqrt 3) / 6) ^ 2 = 100 := by
  have h : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  constructor <;> ring_nf <;> rw [h] <;> norm_num
-- The lead over a steady 100 km/h, s(t) - 100t, is 0 km at both ends.
example : (100 : ℝ) * (3 * 0 ^ 2 - 2 * 0 ^ 3) - 100 * 0 = 0 ∧
    (100 : ℝ) * (3 * 1 ^ 2 - 2 * 1 ^ 3) - 100 * 1 = 0 := by norm_num
-- The corner trip (200 km/h for half an hour, then stopped) still averages 100 km/h.
example : ((200 : ℚ) * (1 / 2) - 0) / (1 - 0) = 100 := by norm_num

#print axioms instantaneous_rate_equals_average_rate_somewhere
#print axioms rolle_equal_ends_force_a_flat_point
#print axioms zero_derivative_on_unbroken_stretch_means_constant
