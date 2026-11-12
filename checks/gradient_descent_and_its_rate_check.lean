-- Gradient descent: with a step under 2/L on a convex region where the gradient changes by at most L per unit moved, every step lowers the height by a guaranteed amount, the smallest slope squared in K steps is at most (height above the floor) / (K α (1 − Lα/2)), and with strong convexity μ the height still to lose shrinks by the factor 1 − 2μα(1 − Lα/2) per step; the card's exact banana-valley numbers are checked as fractions.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Strong
import Mathlib.Topology.EMetricSpace.Lipschitz
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Analysis.Convex.Deriv
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Topology.MetricSpace.Lipschitz

open scoped Gradient NNReal

/-! The map is `EuclideanSpace ℝ (Fin n)`: n chosen numbers. `f` is the height and `∇ f x` is
Mathlib's gradient of `f` at `x`. The walk is `x : ℕ → E`, with `x 0` the start and
`x (k + 1) = x k - α • ∇ f (x k)`: a fixed step `α` straight against the gradient.

"Curvature at most L on the ground the walk covers" is the card's own form from the detailed
proof: on a convex region `s` that holds every iterate, `f` has a gradient at every point and the
gradient changes by at most `L` times the distance moved (`LipschitzOnWith L (∇ f) s`).
"A step under 2/L" is written `L * α < 2`, which is the same thing when `L > 0` and also allows
`L = 0`. -/

theorem gd_line_hasDerivAt {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    (y d : EuclideanSpace ℝ (Fin n)) (t : ℝ) (hf : DifferentiableAt ℝ f (y + t • d)) :
    HasDerivAt (fun t : ℝ => f (y + t • d)) (inner ℝ (∇ f (y + t • d)) d) t := by
  have h2 : HasDerivAt (fun t : ℝ => y + t • d) d t := by
    simpa using ((hasDerivAt_id t).smul_const d).const_add y
  have h3 := hf.hasFDerivAt.comp_hasDerivAt t h2
  rw [inner_gradient_left]
  exact h3

theorem gd_descent_lemma {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {s : Set (EuclideanSpace ℝ (Fin n))} (hs : Convex ℝ s)
    (hdiff : ∀ y ∈ s, DifferentiableAt ℝ f y) {L : ℝ≥0} (hL : LipschitzOnWith L (∇ f) s)
    {y z : EuclideanSpace ℝ (Fin n)} (hy : y ∈ s) (hz : z ∈ s) :
    f z ≤ f y + inner ℝ (∇ f y) (z - y) + (L : ℝ) / 2 * ‖z - y‖ ^ 2 := by
  set d := z - y with hd
  have hmem : ∀ t ∈ Set.Icc (0 : ℝ) 1, y + t • d ∈ s := fun t ht => hs.add_smul_sub_mem hy hz ht
  let h : ℝ → ℝ := fun t => f (y + t • d) - t * inner ℝ (∇ f y) d - (L : ℝ) / 2 * t ^ 2 * ‖d‖ ^ 2
  have hderiv : ∀ t ∈ Set.Icc (0 : ℝ) 1, HasDerivAt h
      (inner ℝ (∇ f (y + t • d)) d - inner ℝ (∇ f y) d - (L : ℝ) * t * ‖d‖ ^ 2) t := by
    intro t ht
    have h1 := gd_line_hasDerivAt y d t (hdiff _ (hmem t ht))
    have h2 := ((hasDerivAt_id t).mul_const (inner ℝ (∇ f y) d))
    have h3 := (((hasDerivAt_id t).pow 2).const_mul ((L : ℝ) / 2)).mul_const (‖d‖ ^ 2)
    convert (h1.sub h2).sub h3 using 1
    · funext u; simp only [h, Pi.sub_apply, id, Pi.pow_apply]
    · simp only [id, Nat.cast_ofNat, show (2:ℕ) - 1 = 1 from rfl, pow_one]; ring
  have hanti : AntitoneOn h (Set.Icc (0 : ℝ) 1) := by
    apply antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc 0 1)
    · exact fun t ht => (hderiv t ht).continuousAt.continuousWithinAt
    · intro t ht
      exact (hderiv t (interior_subset ht)).hasDerivWithinAt
    · intro t ht
      rw [interior_Icc] at ht
      have ht' : t ∈ Set.Icc (0 : ℝ) 1 := Set.Ioo_subset_Icc_self ht
      have hlip := hL.dist_le_mul _ (hmem t ht') _ hy
      rw [dist_eq_norm, dist_eq_norm] at hlip
      simp only [add_sub_cancel_left, norm_smul, Real.norm_eq_abs, abs_of_pos ht.1] at hlip
      have hcs : inner ℝ (∇ f (y + t • d) - ∇ f y) d ≤ ‖∇ f (y + t • d) - ∇ f y‖ * ‖d‖ :=
        real_inner_le_norm _ _
      rw [inner_sub_left] at hcs
      have := mul_le_mul_of_nonneg_right hlip (norm_nonneg d)
      nlinarith
  have h01 := hanti (Set.left_mem_Icc.2 zero_le_one) (Set.right_mem_Icc.2 zero_le_one) zero_le_one
  simp only [h, zero_smul, add_zero, zero_mul, one_smul, one_mul, sub_zero, one_pow] at h01
  have : y + d = z := by rw [hd]; abel
  rw [this] at h01
  ring_nf at h01 ⊢
  linarith

#print axioms gd_line_hasDerivAt
#print axioms gd_descent_lemma

theorem gd_one_step {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {s : Set (EuclideanSpace ℝ (Fin n))} (hs : Convex ℝ s)
    (hdiff : ∀ y ∈ s, DifferentiableAt ℝ f y) {L : ℝ≥0} (hL : LipschitzOnWith L (∇ f) s)
    {α : ℝ} {y : EuclideanSpace ℝ (Fin n)} (hy : y ∈ s) (hz : y - α • ∇ f y ∈ s) :
    f (y - α • ∇ f y) ≤ f y - α * (1 - L * α / 2) * ‖∇ f y‖ ^ 2 := by
  have h := gd_descent_lemma hs hdiff hL hy hz
  have e : y - α • ∇ f y - y = -(α • ∇ f y) := by abel
  rw [e, inner_neg_right, inner_smul_right, real_inner_self_eq_norm_sq, norm_neg, norm_smul,
    Real.norm_eq_abs, mul_pow, sq_abs] at h
  linarith [h]

#print axioms gd_one_step

theorem gd_strong_first_order {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {s : Set (EuclideanSpace ℝ (Fin n))} {μ : ℝ} (hsc : StrongConvexOn s μ f)
    {x y : EuclideanSpace ℝ (Fin n)} (hx : x ∈ s) (hy : y ∈ s) (hfx : DifferentiableAt ℝ f x) :
    f x + inner ℝ (∇ f x) (y - x) + μ / 2 * ‖y - x‖ ^ 2 ≤ f y := by
  rw [strongConvexOn_iff_convex] at hsc
  have hc := hsc.comp_affineMap (AffineMap.lineMap x y)
  set d := y - x with hd
  let φ : ℝ → ℝ := fun t => f (x + t • d) - μ / 2 * ‖x + t • d‖ ^ 2
  have hφ : ((fun x => f x - μ / (2 : ℝ) * ‖x‖ ^ 2) ∘ AffineMap.lineMap x y) = φ := by
    funext t
    simp only [Function.comp, AffineMap.lineMap_apply_module', φ, hd, add_comm]
  rw [hφ] at hc
  have h0 : (0 : ℝ) ∈ (AffineMap.lineMap x y : ℝ →ᵃ[ℝ] _) ⁻¹' s := by
    simp [AffineMap.lineMap_apply_zero, hx]
  have h1 : (1 : ℝ) ∈ (AffineMap.lineMap x y : ℝ →ᵃ[ℝ] _) ⁻¹' s := by
    simp [AffineMap.lineMap_apply_one, hy]
  have hfx' : DifferentiableAt ℝ f (x + (0 : ℝ) • d) := by simpa using hfx
  have hl := gd_line_hasDerivAt x d 0 hfx'
  have hn : HasDerivAt (fun t : ℝ => x + t • d) d 0 := by
    simpa using ((hasDerivAt_id (0 : ℝ)).smul_const d).const_add x
  have hder := hl.sub (hn.norm_sq.const_mul (μ / 2))
  have key := hc.le_slope_of_hasDerivAt h0 h1 zero_lt_one hder
  simp only [slope, φ, zero_smul, add_zero, one_smul, sub_zero, inv_one] at key
  have : x + d = y := by rw [hd]; abel
  rw [this] at key
  have hyn : ‖y‖ ^ 2 = ‖x‖ ^ 2 + 2 * inner ℝ x d + ‖d‖ ^ 2 := by
    rw [← this, norm_add_sq_real]
  rw [hyn, vsub_eq_sub] at key
  nlinarith [key]

#print axioms gd_strong_first_order

/-- **The descent guarantee.** Let `f` have a gradient at every point of a convex region `s`,
and let the gradient change by at most `L` times the distance moved inside `s`. Run gradient
descent with a fixed step `α`, `0 < α` and `α` under `2/L`, and suppose the walk stays in `s`.
Then every step lowers the height by at least the step size, times the safety factor
`1 − Lα/2`, times the slope's length squared:
`f(x_{k+1}) ≤ f(x_k) − α (1 − Lα/2) ‖∇f(x_k)‖²`.
In particular the height falls strictly at every step where the slope is not zero. -/
theorem gradient_descent_step_lowers_height {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {s : Set (EuclideanSpace ℝ (Fin n))} (hs : Convex ℝ s)
    (hdiff : ∀ y ∈ s, DifferentiableAt ℝ f y) {L : ℝ≥0} (hL : LipschitzOnWith L (∇ f) s)
    {α : ℝ} (hα : 0 < α) (hαL : (L : ℝ) * α < 2)
    (x : ℕ → EuclideanSpace ℝ (Fin n)) (hstep : ∀ k, x (k + 1) = x k - α • ∇ f (x k))
    (hin : ∀ k, x k ∈ s) :
    ∀ k, f (x (k + 1)) ≤ f (x k) - α * (1 - L * α / 2) * ‖∇ f (x k)‖ ^ 2 ∧
      (∇ f (x k) ≠ 0 → f (x (k + 1)) < f (x k)) := by
  intro k
  have hz : x k - α • ∇ f (x k) ∈ s := by rw [← hstep]; exact hin (k + 1)
  have h := gd_one_step hs hdiff hL (hin k) hz
  rw [← hstep] at h
  refine ⟨h, fun hg => ?_⟩
  have hc : 0 < α * (1 - L * α / 2) := mul_pos hα (by linarith)
  have hn : 0 < ‖∇ f (x k)‖ ^ 2 := pow_pos (norm_pos_iff.2 hg) 2
  nlinarith [mul_pos hc hn]

/-- **The gradient bound.** Same walk and the same conditions, and in addition `f` never goes
below a number `f_low`. Then after `K` steps (`K ≥ 1`), at some step `k` among the first `K` the
slope was small: `‖∇f(x_k)‖² ≤ (f(x_0) − f_low) / (K α (1 − Lα/2))`. This is the card's
`min_{0 ≤ k < K} ‖∇f(x_k)‖² ≤ …`, since the smallest of the K numbers is one of them. No bowl
shape is needed, only the floor. -/
theorem gradient_descent_min_slope_bound {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {s : Set (EuclideanSpace ℝ (Fin n))} (hs : Convex ℝ s)
    (hdiff : ∀ y ∈ s, DifferentiableAt ℝ f y) {L : ℝ≥0} (hL : LipschitzOnWith L (∇ f) s)
    {α : ℝ} (hα : 0 < α) (hαL : (L : ℝ) * α < 2)
    (x : ℕ → EuclideanSpace ℝ (Fin n)) (hstep : ∀ k, x (k + 1) = x k - α • ∇ f (x k))
    (hin : ∀ k, x k ∈ s) {flow : ℝ} (hfloor : ∀ y, flow ≤ f y) {K : ℕ} (hK : 0 < K) :
    ∃ k < K, ‖∇ f (x k)‖ ^ 2 ≤ (f (x 0) - flow) / (K * α * (1 - L * α / 2)) := by
  have hstep' := gradient_descent_step_lowers_height hs hdiff hL hα hαL x hstep hin
  have h1 : 0 < 1 - (L : ℝ) * α / 2 := by linarith
  have hc : 0 < α * (1 - L * α / 2) := mul_pos hα h1
  have tele : ∀ m, f (x m) ≤
      f (x 0) - ∑ k ∈ Finset.range m, α * (1 - L * α / 2) * ‖∇ f (x k)‖ ^ 2 := by
    intro m
    induction m with
    | zero => simp
    | succ m ih =>
      rw [Finset.sum_range_succ]
      have := (hstep' m).1
      linarith
  by_contra hcon
  push Not at hcon
  have hKpos : (0 : ℝ) < K := by exact_mod_cast hK
  have hden : (K : ℝ) * α * (1 - L * α / 2) ≠ 0 := (mul_pos (mul_pos hKpos hα) h1).ne'
  set B := (f (x 0) - flow) / (K * α * (1 - L * α / 2)) with hB
  have hlt : ∑ k ∈ Finset.range K, α * (1 - L * α / 2) * B <
      ∑ k ∈ Finset.range K, α * (1 - L * α / 2) * ‖∇ f (x k)‖ ^ 2 :=
    Finset.sum_lt_sum_of_nonempty (Finset.nonempty_range_iff.2 hK.ne')
      (fun k hk => mul_lt_mul_of_pos_left (hcon k (Finset.mem_range.1 hk)) hc)
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul] at hlt
  have hKB : (K : ℝ) * (α * (1 - L * α / 2) * B) = f (x 0) - flow := by
    have hcancel := div_mul_cancel₀ (f (x 0) - flow) hden
    rw [hB]; linear_combination hcancel
  linarith [tele K, hfloor (x K)]

/-- **The linear rate.** Same walk and the same conditions, and in addition `f` is strongly
convex on `s` with constant `μ > 0` (curvature at least `μ` in every direction:
Mathlib's `StrongConvexOn s μ f`), and `x*` in `s` is the minimiser of `f` on `s`. Then the
height still to lose shrinks by a fixed factor every step:
`f(x_{k+1}) − f(x*) ≤ (1 − 2μα(1 − Lα/2)) (f(x_k) − f(x*))`. -/
theorem gradient_descent_linear_rate {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {s : Set (EuclideanSpace ℝ (Fin n))} (hs : Convex ℝ s)
    (hdiff : ∀ y ∈ s, DifferentiableAt ℝ f y) {L : ℝ≥0} (hL : LipschitzOnWith L (∇ f) s)
    {α : ℝ} (hα : 0 < α) (hαL : (L : ℝ) * α < 2)
    (x : ℕ → EuclideanSpace ℝ (Fin n)) (hstep : ∀ k, x (k + 1) = x k - α • ∇ f (x k))
    (hin : ∀ k, x k ∈ s) {μ : ℝ} (hμ : 0 < μ) (hsc : StrongConvexOn s μ f)
    {xstar : EuclideanSpace ℝ (Fin n)} (hxstar : xstar ∈ s) (hmin : ∀ y ∈ s, f xstar ≤ f y) :
    ∀ k, f (x (k + 1)) - f xstar ≤
      (1 - 2 * μ * α * (1 - L * α / 2)) * (f (x k) - f xstar) := by
  intro k
  have h := (gradient_descent_step_lowers_height hs hdiff hL hα hαL x hstep hin k).1
  have hfo := gd_strong_first_order hsc (hin k) hxstar (hdiff _ (hin k))
  have hsq : 0 ≤ ‖∇ f (x k) + μ • (xstar - x k)‖ ^ 2 := sq_nonneg _
  rw [norm_add_sq_real, inner_smul_right, norm_smul, Real.norm_eq_abs, abs_of_pos hμ,
    mul_pow] at hsq
  have h2 := mul_le_mul_of_nonneg_left hfo (by linarith : (0 : ℝ) ≤ 2 * μ)
  have hPL : 2 * μ * (f (x k) - f xstar) ≤ ‖∇ f (x k)‖ ^ 2 := by nlinarith
  have hc : 0 ≤ α * (1 - L * α / 2) := (mul_pos hα (by linarith)).le
  have h3 := mul_le_mul_of_nonneg_left hPL hc
  nlinarith

/-! The card's exact numbers on the Rosenbrock banana `f(a, b) = (1 − a)² + 100 (b − a²)²`,
as fractions. Its gradient is `(−2(1 − a) − 400 a (b − a²), 200 (b − a²))`. -/

/-- The Rosenbrock height. -/
def rosen (a b : ℚ) : ℚ := (1 - a) ^ 2 + 100 * (b - a ^ 2) ^ 2

/-- First part of the Rosenbrock gradient. -/
def rosenGa (a b : ℚ) : ℚ := -2 * (1 - a) - 400 * a * (b - a ^ 2)

/-- Second part of the Rosenbrock gradient. -/
def rosenGb (a b : ℚ) : ℚ := 200 * (b - a ^ 2)

-- Height at the start (−1.2, 1): 4.84 + 19.36 = 24.2.
example : (1 - (-6 / 5 : ℚ)) ^ 2 = 121 / 25 ∧ 100 * (1 - (-6 / 5 : ℚ) ^ 2) ^ 2 = 484 / 25 ∧
    rosen (-6 / 5) 1 = 121 / 5 := by norm_num [rosen]

-- Gradient at the start: (−215.6, −88).
example : rosenGa (-6 / 5) 1 = -1078 / 5 ∧ rosenGb (-6 / 5) 1 = -88 := by
  norm_num [rosenGa, rosenGb]

-- Step 1 with step 0.001 lands at (−0.9844, 1.0880).
example : (-6 / 5 : ℚ) - 1 / 1000 * rosenGa (-6 / 5) 1 = -2461 / 2500 ∧
    (1 : ℚ) - 1 / 1000 * rosenGb (-6 / 5) 1 = 136 / 125 := by
  norm_num [rosenGa, rosenGb]

-- Step 1 drops the height from 24.2 to 5.3529 (to four places): it lies between 5.35 and 5.36.
example : 535 / 100 < rosen (-2461 / 2500) (136 / 125) ∧
    rosen (-2461 / 2500) (136 / 125) < 536 / 100 := by norm_num [rosen]

-- Slope length squared at the start: 215.6² + 88² = 46483.36 + 7744 = 54227.36.
example : (1078 / 5 : ℚ) ^ 2 = 1162084 / 25 ∧ (88 : ℚ) ^ 2 = 7744 ∧
    (1078 / 5 : ℚ) ^ 2 + 88 ^ 2 = 1355684 / 25 := by norm_num

-- Step 0.002 from the start climbs: 24.2 up to 37.3449 (between 37 and 38).
example : 37 < rosen (-6 / 5 - 2 / 1000 * rosenGa (-6 / 5) 1) (1 - 2 / 1000 * rosenGb (-6 / 5) 1) ∧
    rosen (-6 / 5 - 2 / 1000 * rosenGa (-6 / 5) 1) (1 - 2 / 1000 * rosenGb (-6 / 5) 1) < 38 := by
  norm_num [rosen, rosenGa, rosenGb]

-- Far start (−2, 2): height 409, and step 0.001 climbs to 505.8398 (between 505 and 506).
example : rosen (-2) 2 = 409 ∧
    505 < rosen (-2 - 1 / 1000 * rosenGa (-2) 2) (2 - 1 / 1000 * rosenGb (-2) 2) ∧
    rosen (-2 - 1 / 1000 * rosenGa (-2) 2) (2 - 1 / 1000 * rosenGb (-2) 2) < 506 := by
  norm_num [rosen, rosenGa, rosenGb]

-- At (−2, 2) the Hessian is [[4002, 800], [800, 200]]; its curvatures solve
-- λ² − 4202 λ + 160400 = 0, and that polynomial is negative at 2000, so the largest curvature
-- (4163.4745) is above 2000 and the step 0.001 is above 2/L there.
example : (1200 * (-2) ^ 2 - 400 * 2 + 2 : ℚ) = 4002 ∧ (-400 * (-2) : ℚ) = 800 ∧
    (4002 + 200 : ℚ) = 4202 ∧ (4002 * 200 - 800 ^ 2 : ℚ) = 160400 ∧
    (2000 : ℚ) ^ 2 - 4202 * 2000 + 160400 < 0 := by norm_num

-- The certificate: the height is 0 at (1, 1) with zero gradient there, and never below 0.
example : rosen 1 1 = 0 ∧ rosenGa 1 1 = 0 ∧ rosenGb 1 1 = 0 := by
  norm_num [rosen, rosenGa, rosenGb]
example (a b : ℚ) : 0 ≤ rosen a b := by unfold rosen; positivity

-- At the bottom the Hessian is [[802, −400], [−400, 200]]: trace 1002, determinant 400, so
-- both curvatures (1001.6006 and 0.3994) are positive; the polynomial λ² − 1002 λ + 400 is
-- negative at 1000, so the steep curvature is above 1000 and 2/L there is below 0.002.
example : (1200 * 1 ^ 2 - 400 * 1 + 2 : ℚ) = 802 ∧ (802 + 200 : ℚ) = 1002 ∧
    (802 * 200 - (-400) ^ 2 : ℚ) = 400 ∧ (1000 : ℚ) ^ 2 - 1002 * 1000 + 400 < 0 := by norm_num

#print axioms gradient_descent_step_lowers_height
#print axioms gradient_descent_min_slope_bound
#print axioms gradient_descent_linear_rate
