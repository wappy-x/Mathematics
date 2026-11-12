-- Convexity pays off: for a convex cost on a convex allowed set, a local minimiser is a global minimiser, the set of all minimisers is convex, and a strictly convex cost has at most one minimiser.
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Convex.Extrema

/-! A choice is a point `x` of `EuclideanSpace ℝ (Fin n)` (for the roaster, `n = 3`:
the Brazil, Colombia and Sumatra shares), and `‖x - xstar‖` is the straight-line
distance between two choices. `C` is the allowed set and `f` is the cost.
`xstar` is a local minimiser among allowed points: there is a radius `r > 0`
such that no allowed `x` within distance `r` of `xstar` is cheaper. -/

/-- Local minima are global when convex: if the allowed set `C` is convex and the cost
`f` is convex on `C`, and no allowed choice within some radius `r > 0` of the allowed
choice `xstar` is cheaper than `xstar`, then no allowed choice anywhere is cheaper. -/
theorem local_min_is_global_when_convex {n : ℕ} {C : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hC : Convex ℝ C) (hf : ConvexOn ℝ C f)
    {xstar : EuclideanSpace ℝ (Fin n)} (hxstar : xstar ∈ C) {r : ℝ} (hr : 0 < r)
    (hlocal : ∀ x ∈ C, ‖x - xstar‖ < r → f xstar ≤ f x) :
    ∀ y ∈ C, f xstar ≤ f y := by
  have hloc : IsLocalMinOn f C xstar := by
    have hball : Metric.ball xstar r ∈ nhds xstar := Metric.ball_mem_nhds xstar hr
    filter_upwards [inter_mem_nhdsWithin C hball] with x hx
    exact hlocal x hx.1 (by simpa [dist_eq_norm] using hx.2)
  intro y hy
  exact IsMinOn.of_isLocalMinOn_of_convexOn hxstar hloc hf hy

/-- The cheapest choices form a convex set: if the allowed set `C` is convex and the
cost `f` is convex on `C`, then the set of allowed choices that no allowed choice
beats is convex, so mixing two cheapest choices gives another cheapest choice. -/
theorem minimisers_form_convex_set {n : ℕ} {C : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hC : Convex ℝ C) (hf : ConvexOn ℝ C f) :
    Convex ℝ {x | x ∈ C ∧ ∀ y ∈ C, f x ≤ f y} := by
  intro x hx y hy a b ha hb hab
  refine ⟨hC hx.1 hy.1 ha hb hab, fun w hw => ?_⟩
  calc f (a • x + b • y) ≤ a • f x + b • f y := hf.2 hx.1 hy.1 ha hb hab
    _ ≤ a • f w + b • f w := by
        gcongr
        · exact hx.2 w hw
        · exact hy.2 w hw
    _ = f w := by rw [← add_smul, hab, one_smul]

/-- Strictly convex, for one answer: if the allowed set `C` is convex and the cost `f`
is strictly convex on `C`, then two cheapest allowed choices are the same choice. -/
theorem strictly_convex_minimiser_unique {n : ℕ} {C : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hC : Convex ℝ C) (hf : StrictConvexOn ℝ C f)
    {x y : EuclideanSpace ℝ (Fin n)} (hx : x ∈ C) (hy : y ∈ C)
    (hxmin : ∀ z ∈ C, f x ≤ f z) (hymin : ∀ z ∈ C, f y ≤ f z) :
    x = y := by
  exact hf.eq_of_isMinOn (fun z hz => hxmin z hz) (fun z hz => hymin z hz) hx hy

/-! The card's worked numbers, as exact fractions. The roaster's cost is
`f(x) = Σ (a_i x_i + 5 x_i^2)` with base prices `a = (6, 9, 11)`, and the strength is
`5 x_B + 6 x_C + 9 x_E`. The answer is `xstar = (7/20, 1/5, 9/20)`;
the corners of the allowed set are `E = (0, 0, 1)`, `P = (1/2, 0, 1/2)`, `Q = (0, 2/3, 1/3)`. -/

-- The answer's shares add to 1 and its strength is exactly 7.
example : (7/20 : ℚ) + 1/5 + 9/20 = 1 ∧ 5 * (7/20 : ℚ) + 6 * (1/5) + 9 * (9/20) = 7 := by
  norm_num

-- Base part 8.85 = 177/20, rise part 1.825 = 73/40, cost 10.675 = 427/40.
example : 6 * (7/20 : ℚ) + 9 * (1/5) + 11 * (9/20) = 177/20 ∧
    5 * ((7/20 : ℚ)^2 + (1/5)^2 + (9/20)^2) = 73/40 ∧
    (177/20 : ℚ) + 73/40 = 427/40 := by
  norm_num

-- Cost along the strength-7 edge, 11 - 3.25 c + 8.125 c^2, at c = 1/5 is 427/40,
-- and its slope -3.25 + 2 * 8.125 c is zero there.
example : (11 : ℚ) - 13/4 * (1/5) + 65/8 * (1/5)^2 = 427/40 ∧
    -(13/4 : ℚ) + 2 * (65/8) * (1/5) = 0 := by
  norm_num

-- Gradient a_i + 10 x_i at the answer: (9.5, 11, 15.5).
example : (6 : ℚ) + 10 * (7/20) = 19/2 ∧ (9 : ℚ) + 10 * (1/5) = 11 ∧
    (11 : ℚ) + 10 * (9/20) = 31/2 := by
  norm_num

-- Slopes from the answer toward the corners: 3 toward E, 0 toward P, 0 toward Q.
example : 19/2 * (0 - 7/20 : ℚ) + 11 * (0 - 1/5) + 31/2 * (1 - 9/20) = 3 ∧
    19/2 * (1/2 - 7/20 : ℚ) + 11 * (0 - 1/5) + 31/2 * (1/2 - 9/20) = 0 ∧
    19/2 * (0 - 7/20 : ℚ) + 11 * (2/3 - 1/5) + 31/2 * (1/3 - 9/20) = 0 := by
  norm_num

-- Corner costs: E costs 16, P costs 11.
example : 11 * (1 : ℚ) + 5 * 1^2 = 16 ∧
    6 * (1/2 : ℚ) + 11 * (1/2) + 5 * ((1/2)^2 + (1/2)^2) = 11 := by
  norm_num

-- Flat quote: each price is 2 + 1.5 times the bean's score, so a strength-7 blend costs 12.5.
example : (2 : ℚ) + 3/2 * 5 = 19/2 ∧ (2 : ℚ) + 3/2 * 6 = 11 ∧ (2 : ℚ) + 3/2 * 9 = 31/2 ∧
    (2 : ℚ) + 3/2 * 7 = 25/2 := by
  norm_num

#print axioms local_min_is_global_when_convex
#print axioms minimisers_form_convex_set
#print axioms strictly_convex_minimiser_unique
