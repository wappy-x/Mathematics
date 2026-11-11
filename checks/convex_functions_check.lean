-- Convex functions: a local minimum of a convex function on a convex set is a global minimum, a Hessian that is never negative in any direction makes a function convex, Jensen's inequality holds for k weighted points, and the card's seedling numbers are exact.
import Mathlib.Analysis.Convex.Extrema
import Mathlib.Analysis.Convex.Jensen
import Mathlib.Analysis.Convex.Deriv
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Set

/-- **A local minimum is the global minimum.** Let s be a set of points in n variables that
holds the whole segment between any two of its points (a convex set), and let f be convex on s:
for p, q in s and 0 ≤ t ≤ 1, f(t p + (1 − t) q) ≤ t f(p) + (1 − t) f(q), so every chord lies on
or above the graph. If p in s is a local minimum of f on s (no point of s close to p is lower),
then no point of s anywhere is lower: f(p) ≤ f(q) for every q in s. -/
theorem local_min_of_convex_is_global_min {n : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hf : ConvexOn ℝ s f) {p : EuclideanSpace ℝ (Fin n)}
    (hp : p ∈ s) (hloc : IsLocalMinOn f s p) :
    ∀ q ∈ s, f p ≤ f q := by
  intro q hq
  exact IsMinOn.of_isLocalMinOn_of_convexOn hp hloc hf hq

/-- **The Hessian test.** Let s be an open set in n variables that holds every segment between
its points, and let f have two derivatives on s: f is differentiable on s and so is its
derivative. If the Hessian's quadratic form v^T H v (f's second derivative along v) is at least
0 for every direction v, at every point of s, then f is convex on s: every chord lies on or
above the graph. -/
theorem convex_of_hessian_nonneg {n : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))}
    (hs : Convex ℝ s) (hopen : IsOpen s) {f : EuclideanSpace ℝ (Fin n) → ℝ}
    (hf : DifferentiableOn ℝ f s) (hf' : DifferentiableOn ℝ (fderiv ℝ f) s)
    (hH : ∀ x ∈ s, ∀ v : EuclideanSpace ℝ (Fin n), 0 ≤ fderiv ℝ (fderiv ℝ f) x v v) :
    ConvexOn ℝ s f := by
  refine ⟨hs, ?_⟩
  intro x hx y hy a b ha hb hab
  set v := y - x with hv
  let l : ℝ → EuclideanSpace ℝ (Fin n) := fun t => x + t • v
  have hl : ∀ t, HasDerivAt l v t := by
    intro t
    simpa [l] using ((hasDerivAt_id t).smul_const v).const_add x
  have hmem : ∀ t ∈ Icc (0:ℝ) 1, l t ∈ s := fun t ht => hs.add_smul_sub_mem hx hy ht
  have hg : ConvexOn ℝ (Icc (0:ℝ) 1) (f ∘ l) := by
    refine convexOn_of_hasDerivWithinAt2_nonneg (convex_Icc 0 1)
      (f' := fun t => fderiv ℝ f (l t) v) (f'' := fun t => fderiv ℝ (fderiv ℝ f) (l t) v v)
      ?_ ?_ ?_ ?_
    · intro t ht
      have h1 : DifferentiableAt ℝ f (l t) :=
        (hf _ (hmem t ht)).differentiableAt (hopen.mem_nhds (hmem t ht))
      exact (h1.hasFDerivAt.comp_hasDerivAt t (hl t)).continuousAt.continuousWithinAt
    · intro t ht
      rw [interior_Icc] at ht
      have ht' : t ∈ Icc (0:ℝ) 1 := Ioo_subset_Icc_self ht
      have h1 : DifferentiableAt ℝ f (l t) :=
        (hf _ (hmem t ht')).differentiableAt (hopen.mem_nhds (hmem t ht'))
      exact (h1.hasFDerivAt.comp_hasDerivAt t (hl t)).hasDerivWithinAt
    · intro t ht
      rw [interior_Icc] at ht
      have ht' : t ∈ Icc (0:ℝ) 1 := Ioo_subset_Icc_self ht
      have h2 : DifferentiableAt ℝ (fderiv ℝ f) (l t) :=
        (hf' _ (hmem t ht')).differentiableAt (hopen.mem_nhds (hmem t ht'))
      have h3 := (h2.hasFDerivAt.comp_hasDerivAt t (hl t)).clm_apply (hasDerivAt_const t v)
      simpa using h3.hasDerivWithinAt
    · intro t ht
      rw [interior_Icc] at ht
      exact hH _ (hmem t (Ioo_subset_Icc_self ht)) v
  have key := hg.2 (x := 0) (y := 1) (left_mem_Icc.2 zero_le_one) (right_mem_Icc.2 zero_le_one)
    ha hb hab
  have ha' : a = 1 - b := by linarith
  have e1 : a • x + b • y = l (a • (0:ℝ) + b • 1) := by
    simp only [l, hv, smul_eq_mul, mul_zero, mul_one, zero_add, ha', smul_sub, sub_smul, one_smul]
    abel
  rw [e1]
  simpa [l, hv] using key

/-- **Jensen's inequality for k points.** If f is convex on a convex set s, the points
p₁, …, p_k lie in s, and the weights θ₁, …, θ_k are at least 0 and add up to 1, then f at the
weighted average of the points is at most the weighted average of f's values:
f(θ₁ p₁ + … + θ_k p_k) ≤ θ₁ f(p₁) + … + θ_k f(p_k). -/
theorem jensen_inequality {n k : ℕ} {s : Set (EuclideanSpace ℝ (Fin n))}
    {f : EuclideanSpace ℝ (Fin n) → ℝ} (hf : ConvexOn ℝ s f)
    (θ : Fin k → ℝ) (p : Fin k → EuclideanSpace ℝ (Fin n))
    (hθ : ∀ i, 0 ≤ θ i) (hsum : ∑ i, θ i = 1) (hp : ∀ i, p i ∈ s) :
    f (∑ i, θ i • p i) ≤ ∑ i, θ i * f (p i) := by
  simpa [smul_eq_mul] using hf.map_sum_le (fun i _ => hθ i) hsum (fun i _ => hp i)

/-- The seedling's squared error: heights 1, 3, 4, 6 cm at weeks 0, 1, 2, 3, line a + b·week. -/
def seedlingS (a b : ℚ) : ℚ :=
  (1 - a - b * 0) ^ 2 + (3 - a - b * 1) ^ 2 + (4 - a - b * 2) ^ 2 + (6 - a - b * 3) ^ 2

/-- The same squared error with all four measurements taken in week 2. -/
def weekTwoS (a b : ℚ) : ℚ :=
  (1 - a - b * 2) ^ 2 + (3 - a - b * 2) ^ 2 + (4 - a - b * 2) ^ 2 + (6 - a - b * 2) ^ 2

-- Sums: weeks 6, squared weeks 14, heights 14, week × height 29.
example : (0 + 1 + 2 + 3 : ℚ) = 6 ∧ (0 ^ 2 + 1 ^ 2 + 2 ^ 2 + 3 ^ 2 : ℚ) = 14 ∧
    (1 + 3 + 4 + 6 : ℚ) = 14 ∧ (0 * 1 + 1 * 3 + 2 * 4 + 3 * 6 : ℚ) = 29 := by norm_num
-- Normal equations: b = (4 × 29 − 6 × 14) ÷ (4 × 14 − 6^2) = 32 ÷ 20 = 1.6, a = (14 − 1.6 × 6) ÷ 4 = 1.1.
example : ((4 * 29 - 6 * 14) / (4 * 14 - 6 ^ 2) : ℚ) = 8 / 5 ∧
    ((14 - 8 / 5 * 6) / 4 : ℚ) = 11 / 10 := by norm_num
-- The best line's squared error is 0.2 cm^2.
example : seedlingS (11 / 10) (8 / 5) = 1 / 5 := by norm_num [seedlingS]
-- S expanded: its Hessian is [[8, 12], [12, 28]] at every point.
example (a b : ℚ) : seedlingS a b = 4 * a ^ 2 + 12 * a * b + 14 * b ^ 2 - 28 * a - 58 * b + 62 := by
  simp only [seedlingS]; ring
-- v^T H v = 8c^2 + 24cd + 28d^2 = 2 Σ (c + d x_i)^2, a sum of squares.
example (c d : ℚ) : 8 * c ^ 2 + 24 * c * d + 28 * d ^ 2 =
    2 * ((c + d * 0) ^ 2 + (c + d * 1) ^ 2 + (c + d * 2) ^ 2 + (c + d * 3) ^ 2) := by ring
-- Determinant 80 and trace 36.
example : (8 * 28 - 12 ^ 2 : ℚ) = 80 ∧ (8 + 28 : ℚ) = 36 := by norm_num
-- Chord: S(0, 2) = 2, S(2, 1) = 2, midpoint S(1, 1.5) = 0.5; gap 1.5 two ways.
example : seedlingS 0 2 = 2 ∧ seedlingS 2 1 = 2 ∧ seedlingS 1 (3 / 2) = 1 / 2 := by
  norm_num [seedlingS]
example : (seedlingS 0 2 + seedlingS 2 1) / 2 - seedlingS 1 (3 / 2) = 3 / 2 ∧
    ((8 * 2 ^ 2 + 24 * 2 * (-1) + 28 * (-1) ^ 2) / 8 : ℚ) = 3 / 2 := by
  norm_num [seedlingS]
-- Jensen: weights 0.5, 0.3, 0.2 on (0, 2), (2, 1), (3, 0); average point (1.2, 1.3).
example : seedlingS 3 0 = 14 ∧
    ((1 / 2) * 0 + (3 / 10) * 2 + (1 / 5) * 3 : ℚ) = 6 / 5 ∧
    ((1 / 2) * 2 + (3 / 10) * 1 + (1 / 5) * 0 : ℚ) = 13 / 10 := by
  norm_num [seedlingS]
-- Average of S is 4.4, S at the average point is 1.14, gap 3.26.
example : (1 / 2) * seedlingS 0 2 + (3 / 10) * seedlingS 2 1 + (1 / 5) * seedlingS 3 0 = 22 / 5 ∧
    seedlingS (6 / 5) (13 / 10) = 57 / 50 ∧ (22 / 5 - 57 / 50 : ℚ) = 163 / 50 := by
  norm_num [seedlingS]
-- Not strict: all four measurements in week 2 gives determinant 0 and S(3.5, 0) = S(1.5, 1) = 13.
example : ((2 * 4) * (2 * (4 * 2 ^ 2)) - (2 * (4 * 2)) ^ 2 : ℚ) = 0 ∧
    weekTwoS (7 / 2) 0 = 13 ∧ weekTwoS (3 / 2) 1 = 13 := by
  norm_num [weekTwoS]

#print axioms local_min_of_convex_is_global_min
#print axioms convex_of_hessian_nonneg
#print axioms jensen_inequality
