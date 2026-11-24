-- SVRG and SAGA: for an average of convex losses whose slopes change by at most L, both corrected gradient estimates are right on average with noise bounded by the heights above the best value, so it vanishes at the optimum, and one SVRG epoch with a step under 1/(2L) shrinks the expected excess by the ratio R; the card's two-day hand example is checked exactly.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.Convex.Strong
import Mathlib.Topology.EMetricSpace.Lipschitz
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.NormNum
import Mathlib

open scoped Gradient NNReal

/-! ### How the card's objects are written here

The weights are a point of `EuclideanSpace ℝ (Fin d)`. There are `n` days, numbered by `Fin n`,
and day `i` has loss `f i`. The fund minimises the average `fullLoss f w = (∑ i, f i w) / n`, and
`wstar` is a point where it is smallest, so `f* = fullLoss f wstar`. `∇ g w` is Mathlib's gradient.

"Each day's loss convex with curvature at most `L`" is: `f i` is convex, differentiable, and its
gradient changes by at most `L` times the distance moved (`LipschitzWith L (∇ (f i))`).

`E` over the day drawn is the plain average over all `n` days, each equally likely. Over a whole
epoch of `m` steps the days drawn are a list `s : Fin m → Fin n`, and all `n ^ m` lists are
equally likely, so `E` is the sum over all lists divided by `n ^ m`. -/

/-- The average loss over the `n` days: `f(w) = (1/n) ∑ f_i(w)`. -/
noncomputable def fullLoss {d n : ℕ} (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (w : EuclideanSpace ℝ (Fin d)) : ℝ :=
  (∑ i, f i w) / n

/-- SVRG's estimate when day `i` is drawn at the point `w`, with snapshot `wt`:
`∇f_i(w) − ∇f_i(w̃) + ∇f(w̃)`. -/
noncomputable def svrgEst {d n : ℕ} (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (wt : EuclideanSpace ℝ (Fin d)) (i : Fin n) (w : EuclideanSpace ℝ (Fin d)) :
    EuclideanSpace ℝ (Fin d) :=
  ∇ (f i) w - ∇ (f i) wt + ∇ (fullLoss f) wt

/-- SAGA's estimate when day `i` is drawn at the point `w`, with day `j`'s stored slope taken at
`φ j`: `∇f_i(w) − ∇f_i(φ_i) + (1/n) ∑_j ∇f_j(φ_j)`. -/
noncomputable def sagaEst {d n : ℕ} (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (φ : Fin n → EuclideanSpace ℝ (Fin d)) (i : Fin n) (w : EuclideanSpace ℝ (Fin d)) :
    EuclideanSpace ℝ (Fin d) :=
  ∇ (f i) w - ∇ (f i) (φ i) + (n : ℝ)⁻¹ • ∑ j, ∇ (f j) (φ j)

/-- One SVRG epoch: start at the snapshot `wt`, and at step `k < m` move from `w_k` to
`w_{k+1} = w_k − α g_k`, using the day `s k`. -/
noncomputable def svrgPath {d n m : ℕ} (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ) (α : ℝ)
    (wt : EuclideanSpace ℝ (Fin d)) (s : Fin m → Fin n) : ℕ → EuclideanSpace ℝ (Fin d)
  | 0 => wt
  | k + 1 =>
    if h : k < m then svrgPath f α wt s k - α • svrgEst f wt (s ⟨k, h⟩) (svrgPath f α wt s k)
    else svrgPath f α wt s k

/-! ### Helper lemmas -/

theorem vr_line_hasDerivAt {d : ℕ} {g : EuclideanSpace ℝ (Fin d) → ℝ}
    (y v : EuclideanSpace ℝ (Fin d)) (t : ℝ) (hg : DifferentiableAt ℝ g (y + t • v)) :
    HasDerivAt (fun t : ℝ => g (y + t • v)) (inner ℝ (∇ g (y + t • v)) v) t := by
  have h2 : HasDerivAt (fun t : ℝ => y + t • v) v t := by
    simpa using ((hasDerivAt_id t).smul_const v).const_add y
  have h3 := hg.hasFDerivAt.comp_hasDerivAt t h2
  rw [inner_gradient_left]
  exact h3

#print axioms vr_line_hasDerivAt

/-- The descent lemma: a function whose gradient changes by at most `L` lies under its tangent
plus `L/2` times the squared distance. -/
theorem vr_descent_lemma {d : ℕ} {g : EuclideanSpace ℝ (Fin d) → ℝ}
    (hdiff : Differentiable ℝ g) {L : ℝ≥0} (hL : LipschitzWith L (∇ g))
    (y z : EuclideanSpace ℝ (Fin d)) :
    g z ≤ g y + inner ℝ (∇ g y) (z - y) + (L : ℝ) / 2 * ‖z - y‖ ^ 2 := by
  set v := z - y with hv
  let h : ℝ → ℝ := fun t => g (y + t • v) - t * inner ℝ (∇ g y) v - (L : ℝ) / 2 * t ^ 2 * ‖v‖ ^ 2
  have hderiv : ∀ t : ℝ, HasDerivAt h
      (inner ℝ (∇ g (y + t • v)) v - inner ℝ (∇ g y) v - (L : ℝ) * t * ‖v‖ ^ 2) t := by
    intro t
    have h1 := vr_line_hasDerivAt y v t (hdiff _)
    have h2 := ((hasDerivAt_id t).mul_const (inner ℝ (∇ g y) v))
    have h3 := (((hasDerivAt_id t).pow 2).const_mul ((L : ℝ) / 2)).mul_const (‖v‖ ^ 2)
    convert (h1.sub h2).sub h3 using 1
    · funext u; simp only [h, Pi.sub_apply, id, Pi.pow_apply]
    · simp only [id, Nat.cast_ofNat, show (2:ℕ) - 1 = 1 from rfl, pow_one]; ring
  have hanti : AntitoneOn h (Set.Icc (0 : ℝ) 1) := by
    apply antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc 0 1)
    · exact fun t _ => (hderiv t).continuousAt.continuousWithinAt
    · intro t _
      exact (hderiv t).hasDerivWithinAt
    · intro t ht
      rw [interior_Icc] at ht
      have hlip := hL.dist_le_mul (y + t • v) y
      rw [dist_eq_norm, dist_eq_norm] at hlip
      simp only [add_sub_cancel_left, norm_smul, Real.norm_eq_abs, abs_of_pos ht.1] at hlip
      have hcs : inner ℝ (∇ g (y + t • v) - ∇ g y) v ≤ ‖∇ g (y + t • v) - ∇ g y‖ * ‖v‖ :=
        real_inner_le_norm _ _
      rw [inner_sub_left] at hcs
      have := mul_le_mul_of_nonneg_right hlip (norm_nonneg v)
      nlinarith
  have h01 := hanti (Set.left_mem_Icc.2 zero_le_one) (Set.right_mem_Icc.2 zero_le_one) zero_le_one
  simp only [h, zero_smul, add_zero, zero_mul, one_smul, one_mul, sub_zero, one_pow] at h01
  have : y + v = z := by rw [hv]; abel
  rw [this] at h01
  ring_nf at h01 ⊢
  linarith

#print axioms vr_descent_lemma

/-- First-order bound for a strongly convex differentiable function. -/
theorem vr_strong_first_order {d : ℕ} {g : EuclideanSpace ℝ (Fin d) → ℝ}
    {μ : ℝ} (hsc : StrongConvexOn Set.univ μ g)
    (x y : EuclideanSpace ℝ (Fin d)) (hgx : DifferentiableAt ℝ g x) :
    g x + inner ℝ (∇ g x) (y - x) + μ / 2 * ‖y - x‖ ^ 2 ≤ g y := by
  rw [strongConvexOn_iff_convex] at hsc
  have hc := hsc.comp_affineMap (AffineMap.lineMap x y)
  set v := y - x with hv
  let φ : ℝ → ℝ := fun t => g (x + t • v) - μ / 2 * ‖x + t • v‖ ^ 2
  have hφ : ((fun x => g x - μ / (2 : ℝ) * ‖x‖ ^ 2) ∘ AffineMap.lineMap x y) = φ := by
    funext t
    simp only [Function.comp, AffineMap.lineMap_apply_module', φ, hv, add_comm]
  rw [hφ] at hc
  have h0 : (0 : ℝ) ∈ (AffineMap.lineMap x y : ℝ →ᵃ[ℝ] _) ⁻¹' Set.univ := by simp
  have h1 : (1 : ℝ) ∈ (AffineMap.lineMap x y : ℝ →ᵃ[ℝ] _) ⁻¹' Set.univ := by simp
  have hgx' : DifferentiableAt ℝ g (x + (0 : ℝ) • v) := by simpa using hgx
  have hl := vr_line_hasDerivAt x v 0 hgx'
  have hn : HasDerivAt (fun t : ℝ => x + t • v) v 0 := by
    simpa using ((hasDerivAt_id (0 : ℝ)).smul_const v).const_add x
  have hder := hl.sub (hn.norm_sq.const_mul (μ / 2))
  have key := hc.le_slope_of_hasDerivAt h0 h1 zero_lt_one hder
  simp only [slope, φ, zero_smul, add_zero, one_smul, sub_zero, inv_one] at key
  have : x + v = y := by rw [hv]; abel
  rw [this] at key
  have hyn : ‖y‖ ^ 2 = ‖x‖ ^ 2 + 2 * inner ℝ x v + ‖v‖ ^ 2 := by
    rw [← this, norm_add_sq_real]
  rw [hyn, vsub_eq_sub] at key
  nlinarith [key]

#print axioms vr_strong_first_order

/-- A convex differentiable function lies above its tangent planes. -/
theorem vr_convex_first_order {d : ℕ} {g : EuclideanSpace ℝ (Fin d) → ℝ}
    (hc : ConvexOn ℝ Set.univ g) (hdiff : Differentiable ℝ g) (x y : EuclideanSpace ℝ (Fin d)) :
    g x + inner ℝ (∇ g x) (y - x) ≤ g y := by
  have := vr_strong_first_order (μ := 0) (strongConvexOn_zero.2 hc) x y (hdiff x)
  simpa using this

#print axioms vr_convex_first_order

/-- Co-coercivity: for a convex function whose gradient changes by at most `L`,
`‖∇g x − ∇g z‖² ≤ 2L (g x − g z − ⟨∇g z, x − z⟩)`. -/
theorem vr_cocoercive {d : ℕ} {g : EuclideanSpace ℝ (Fin d) → ℝ} (hc : ConvexOn ℝ Set.univ g)
    (hdiff : Differentiable ℝ g) {L : ℝ≥0} (hL : LipschitzWith L (∇ g))
    (x z : EuclideanSpace ℝ (Fin d)) :
    ‖∇ g x - ∇ g z‖ ^ 2 ≤ 2 * L * (g x - g z - inner ℝ (∇ g z) (x - z)) := by
  set v := ∇ g x - ∇ g z with hv
  have hfo := vr_convex_first_order hc hdiff z x
  rcases eq_or_lt_of_le (L.coe_nonneg) with h0 | hpos
  · have hle : ‖v‖ ≤ L * ‖x - z‖ := by simpa [dist_eq_norm] using hL.dist_le_mul x z
    rw [← h0, zero_mul] at hle
    have hv0 : ‖v‖ = 0 := le_antisymm hle (norm_nonneg _)
    rw [hv0, ← h0]; simp
  · set y := x - (L : ℝ)⁻¹ • v with hy
    have h1 := vr_convex_first_order hc hdiff z y
    have h2 := vr_descent_lemma hdiff hL x y
    have e1 : y - z = (x - z) - (L : ℝ)⁻¹ • v := by rw [hy]; abel
    have e2 : y - x = -((L : ℝ)⁻¹ • v) := by rw [hy]; abel
    rw [e1, inner_sub_right, inner_smul_right] at h1
    rw [e2, inner_neg_right, inner_smul_right, norm_neg, norm_smul, Real.norm_eq_abs, abs_inv,
      abs_of_pos hpos, mul_pow] at h2
    have hvv : inner ℝ (∇ g x) v - inner ℝ (∇ g z) v = ‖v‖ ^ 2 := by
      rw [← inner_sub_left, ← hv, real_inner_self_eq_norm_sq]
    have hvv' : (L : ℝ)⁻¹ * inner ℝ (∇ g x) v - (L : ℝ)⁻¹ * inner ℝ (∇ g z) v
        = (L : ℝ)⁻¹ * ‖v‖ ^ 2 := by rw [← mul_sub, hvv]
    have key : (L : ℝ)⁻¹ * ‖v‖ ^ 2 - (L : ℝ) / 2 * ((L : ℝ)⁻¹ ^ 2 * ‖v‖ ^ 2)
        ≤ g x - g z - inner ℝ (∇ g z) (x - z) := by linarith
    have e3 : (L : ℝ)⁻¹ * ‖v‖ ^ 2 - (L : ℝ) / 2 * ((L : ℝ)⁻¹ ^ 2 * ‖v‖ ^ 2)
        = ‖v‖ ^ 2 / (2 * L) := by field_simp; ring
    rw [e3, div_le_iff₀ (by positivity)] at key
    linarith

#print axioms vr_cocoercive

/-- `‖a − c‖² ≤ 2‖a‖² + 2‖c‖²`. -/
theorem vr_norm_sub_sq_le {d : ℕ} (a c : EuclideanSpace ℝ (Fin d)) :
    ‖a - c‖ ^ 2 ≤ 2 * ‖a‖ ^ 2 + 2 * ‖c‖ ^ 2 := by
  have h := norm_sub_le a c
  have h0 := norm_nonneg (a - c)
  nlinarith [norm_nonneg a, norm_nonneg c, sq_nonneg (‖a‖ - ‖c‖)]

#print axioms vr_norm_sub_sq_le

/-- The spread about the mean is at most the spread about zero. -/
theorem vr_var_le {d n : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d)) :
    ∑ i, ‖x i - (n : ℝ)⁻¹ • ∑ j, x j‖ ^ 2 ≤ ∑ i, ‖x i‖ ^ 2 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  set m := (n : ℝ)⁻¹ • ∑ j, x j with hm
  have hn' : (n : ℝ) ≠ 0 := by positivity
  have hS : ∑ j, x j = (n : ℝ) • m := by
    rw [hm, smul_smul, mul_inv_cancel₀ hn', one_smul]
  have e : ∀ i, ‖x i - m‖ ^ 2 = ‖x i‖ ^ 2 - 2 * inner ℝ (x i) m + ‖m‖ ^ 2 :=
    fun i => norm_sub_sq_real _ _
  simp_rw [e]
  rw [Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum, ← sum_inner, hS,
    inner_smul_left, real_inner_self_eq_norm_sq]
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
    RCLike.conj_to_real]
  nlinarith [sq_nonneg ‖m‖, (Nat.cast_pos.2 hn : (0 : ℝ) < n)]

#print axioms vr_var_le

/-- The average of the days' losses has gradient the average of their gradients. -/
theorem vr_hasGradient_fullLoss {d n : ℕ} (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (hdiff : ∀ i, Differentiable ℝ (f i)) (w : EuclideanSpace ℝ (Fin d)) :
    HasGradientAt (fullLoss f) ((n : ℝ)⁻¹ • ∑ i, ∇ (f i) w) w := by
  rw [hasGradientAt_iff_hasFDerivAt]
  have h : HasFDerivAt (fun w => ∑ i, f i w) (∑ i, fderiv ℝ (f i) w) w :=
    HasFDerivAt.fun_sum (fun i _ => (hdiff i w).hasFDerivAt)
  have h2 := h.const_mul ((n : ℝ)⁻¹)
  have e : (fun w => (n : ℝ)⁻¹ * ∑ i, f i w) = fullLoss f := by
    funext v; unfold fullLoss; ring
  rw [e] at h2
  convert h2 using 1
  ext v
  simp [map_sum, toDual_gradient, Finset.mul_sum]

#print axioms vr_hasGradient_fullLoss

theorem vr_grad_fullLoss {d n : ℕ} (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (hdiff : ∀ i, Differentiable ℝ (f i)) (w : EuclideanSpace ℝ (Fin d)) :
    ∇ (fullLoss f) w = (n : ℝ)⁻¹ • ∑ i, ∇ (f i) w :=
  (vr_hasGradient_fullLoss f hdiff w).gradient

#print axioms vr_grad_fullLoss

theorem vr_diff_fullLoss {d n : ℕ} (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (hdiff : ∀ i, Differentiable ℝ (f i)) : Differentiable ℝ (fullLoss f) :=
  fun w => (vr_hasGradient_fullLoss f hdiff w).differentiableAt

#print axioms vr_diff_fullLoss

/-- At a minimiser of the average, the days' gradients sum to zero. -/
theorem vr_sum_grad_star {d n : ℕ} (hn : 0 < n) (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (hdiff : ∀ i, Differentiable ℝ (f i))
    (wstar : EuclideanSpace ℝ (Fin d)) (hmin : ∀ v, fullLoss f wstar ≤ fullLoss f v) :
    ∑ i, ∇ (f i) wstar = 0 := by
  have hloc : IsLocalMin (fullLoss f) wstar := Filter.Eventually.of_forall hmin
  have h0 : ∇ (fullLoss f) wstar = 0 := by
    simp [gradient, hloc.fderiv_eq_zero]
  rw [vr_grad_fullLoss f hdiff] at h0
  exact (smul_eq_zero.1 h0).resolve_left (by positivity)

#print axioms vr_sum_grad_star

theorem vr_sum_eq_mul_fullLoss {d n : ℕ} (hn : 0 < n) (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (w : EuclideanSpace ℝ (Fin d)) : ∑ i, f i w = n * fullLoss f w := by
  unfold fullLoss
  have : (n : ℝ) ≠ 0 := by positivity
  field_simp

#print axioms vr_sum_eq_mul_fullLoss

/-- Summed co-coercivity against the minimiser:
`∑ ‖∇f_i(w) − ∇f_i(w*)‖² ≤ 2 L n (f(w) − f*)`. -/
theorem vr_sum_cocoercive {d n : ℕ} (hn : 0 < n)
    (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ) (L : ℝ≥0)
    (hconv : ∀ i, ConvexOn ℝ Set.univ (f i)) (hdiff : ∀ i, Differentiable ℝ (f i))
    (hsmooth : ∀ i, LipschitzWith L (∇ (f i)))
    (wstar : EuclideanSpace ℝ (Fin d)) (hmin : ∀ v, fullLoss f wstar ≤ fullLoss f v)
    (w : EuclideanSpace ℝ (Fin d)) :
    ∑ i, ‖∇ (f i) w - ∇ (f i) wstar‖ ^ 2 ≤
      2 * L * n * (fullLoss f w - fullLoss f wstar) := by
  calc ∑ i, ‖∇ (f i) w - ∇ (f i) wstar‖ ^ 2
      ≤ ∑ i, 2 * (L : ℝ) * (f i w - f i wstar - inner ℝ (∇ (f i) wstar) (w - wstar)) :=
        Finset.sum_le_sum (fun i _ => vr_cocoercive (hconv i) (hdiff i) (hsmooth i) w wstar)
    _ = 2 * L * (∑ i, f i w - ∑ i, f i wstar - inner ℝ (∑ i, ∇ (f i) wstar) (w - wstar)) := by
        rw [← Finset.mul_sum, Finset.sum_sub_distrib, Finset.sum_sub_distrib, sum_inner]
    _ = 2 * L * n * (fullLoss f w - fullLoss f wstar) := by
        rw [vr_sum_grad_star hn f hdiff wstar hmin, inner_zero_left,
          vr_sum_eq_mul_fullLoss hn, vr_sum_eq_mul_fullLoss hn]
        ring

#print axioms vr_sum_cocoercive

/-- SVRG's estimate averages to the true gradient. -/
theorem vr_svrg_mean {d n : ℕ} (hn : 0 < n) (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (hdiff : ∀ i, Differentiable ℝ (f i)) (w wt : EuclideanSpace ℝ (Fin d)) :
    (n : ℝ)⁻¹ • ∑ i, svrgEst f wt i w = ∇ (fullLoss f) w := by
  have hn' : (n : ℝ) ≠ 0 := by positivity
  simp only [svrgEst, Finset.sum_add_distrib, Finset.sum_sub_distrib, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, smul_add, smul_sub, ← vr_grad_fullLoss f hdiff]
  rw [← Nat.cast_smul_eq_nsmul ℝ, smul_smul, inv_mul_cancel₀ hn', one_smul]
  abel

#print axioms vr_svrg_mean

/-- SAGA's estimate averages to the true gradient. -/
theorem vr_saga_mean {d n : ℕ} (hn : 0 < n) (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ)
    (hdiff : ∀ i, Differentiable ℝ (f i)) (φ : Fin n → EuclideanSpace ℝ (Fin d))
    (w : EuclideanSpace ℝ (Fin d)) :
    (n : ℝ)⁻¹ • ∑ i, sagaEst f φ i w = ∇ (fullLoss f) w := by
  have hn' : (n : ℝ) ≠ 0 := by positivity
  simp only [sagaEst, Finset.sum_add_distrib, Finset.sum_sub_distrib, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, smul_add, smul_sub, ← vr_grad_fullLoss f hdiff]
  rw [← Nat.cast_smul_eq_nsmul ℝ, smul_smul, inv_mul_cancel₀ hn', one_smul]
  abel

#print axioms vr_saga_mean

/-- The second moment of SVRG's estimate:
`∑ ‖g_i‖² ≤ 4 L n (f(w) − f*) + 4 L n (f(w̃) − f*)`. -/
theorem vr_svrg_second_moment {d n : ℕ} (hn : 0 < n)
    (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ) (L : ℝ≥0)
    (hconv : ∀ i, ConvexOn ℝ Set.univ (f i)) (hdiff : ∀ i, Differentiable ℝ (f i))
    (hsmooth : ∀ i, LipschitzWith L (∇ (f i)))
    (wstar : EuclideanSpace ℝ (Fin d)) (hmin : ∀ v, fullLoss f wstar ≤ fullLoss f v)
    (w wt : EuclideanSpace ℝ (Fin d)) :
    ∑ i, ‖svrgEst f wt i w‖ ^ 2 ≤
      4 * L * n * (fullLoss f w - fullLoss f wstar) +
        4 * L * n * (fullLoss f wt - fullLoss f wstar) := by
  let a : Fin n → EuclideanSpace ℝ (Fin d) := fun i => ∇ (f i) w - ∇ (f i) wstar
  let b : Fin n → EuclideanSpace ℝ (Fin d) := fun i => ∇ (f i) wt - ∇ (f i) wstar
  have hb : (n : ℝ)⁻¹ • ∑ j, b j = ∇ (fullLoss f) wt := by
    simp only [b, Finset.sum_sub_distrib, vr_sum_grad_star hn f hdiff wstar hmin, sub_zero,
      vr_grad_fullLoss f hdiff]
  have hg : ∀ i, svrgEst f wt i w = a i - (b i - (n : ℝ)⁻¹ • ∑ j, b j) := by
    intro i; rw [hb]; simp only [svrgEst, a, b]; abel
  have h1 : ∑ i, ‖a i‖ ^ 2 ≤ 2 * L * n * (fullLoss f w - fullLoss f wstar) :=
    vr_sum_cocoercive hn f L hconv hdiff hsmooth wstar hmin w
  have h2 : ∑ i, ‖b i‖ ^ 2 ≤ 2 * L * n * (fullLoss f wt - fullLoss f wstar) :=
    vr_sum_cocoercive hn f L hconv hdiff hsmooth wstar hmin wt
  have h3 := vr_var_le b
  calc ∑ i, ‖svrgEst f wt i w‖ ^ 2
      ≤ ∑ i, (2 * ‖a i‖ ^ 2 + 2 * ‖b i - (n : ℝ)⁻¹ • ∑ j, b j‖ ^ 2) :=
        Finset.sum_le_sum fun i _ => by rw [hg i]; exact vr_norm_sub_sq_le _ _
    _ = 2 * ∑ i, ‖a i‖ ^ 2 + 2 * ∑ i, ‖b i - (n : ℝ)⁻¹ • ∑ j, b j‖ ^ 2 := by
        rw [Finset.sum_add_distrib, Finset.mul_sum, Finset.mul_sum]
    _ ≤ _ := by linarith

#print axioms vr_svrg_second_moment

/-- One SVRG step, averaged over the day drawn, in squared distance to the minimiser. -/
theorem vr_svrg_step {d n : ℕ} (hn : 0 < n)
    (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ) (L : ℝ≥0) (μ α : ℝ)
    (hconv : ∀ i, ConvexOn ℝ Set.univ (f i)) (hdiff : ∀ i, Differentiable ℝ (f i))
    (hsmooth : ∀ i, LipschitzWith L (∇ (f i)))
    (hμ : 0 ≤ μ) (hstrong : StrongConvexOn Set.univ μ (fullLoss f)) (hα : 0 ≤ α)
    (wstar : EuclideanSpace ℝ (Fin d)) (hmin : ∀ v, fullLoss f wstar ≤ fullLoss f v)
    (wt w : EuclideanSpace ℝ (Fin d)) :
    (n : ℝ)⁻¹ * ∑ i, ‖w - α • svrgEst f wt i w - wstar‖ ^ 2 ≤
      ‖w - wstar‖ ^ 2 - 2 * α * (1 - 2 * L * α) * (fullLoss f w - fullLoss f wstar) +
        4 * L * α ^ 2 * (fullLoss f wt - fullLoss f wstar) := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have e : ∀ i, ‖w - α • svrgEst f wt i w - wstar‖ ^ 2 = ‖w - wstar‖ ^ 2
      - 2 * α * inner ℝ (w - wstar) (svrgEst f wt i w) + α ^ 2 * ‖svrgEst f wt i w‖ ^ 2 := by
    intro i
    rw [show w - α • svrgEst f wt i w - wstar = (w - wstar) - α • svrgEst f wt i w by abel,
      norm_sub_sq_real, inner_smul_right, norm_smul, Real.norm_eq_abs, mul_pow, sq_abs]
    ring
  simp_rw [e]
  rw [Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum, ← Finset.mul_sum,
    ← inner_sum]
  have hsum : ∑ i, svrgEst f wt i w = (n : ℝ) • ∇ (fullLoss f) w := by
    rw [← vr_svrg_mean hn f hdiff w wt, smul_smul, mul_inv_cancel₀ hn'.ne', one_smul]
  rw [hsum, inner_smul_right]
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have hfo := vr_strong_first_order hstrong w wstar (vr_diff_fullLoss f hdiff w)
  have hneg : inner ℝ (∇ (fullLoss f) w) (wstar - w) = - inner ℝ (w - wstar) (∇ (fullLoss f) w) := by
    rw [show wstar - w = -(w - wstar) by abel, inner_neg_right, real_inner_comm]
  rw [hneg] at hfo
  have hI : fullLoss f w - fullLoss f wstar ≤ inner ℝ (w - wstar) (∇ (fullLoss f) w) := by
    nlinarith [sq_nonneg ‖wstar - w‖]
  have hM := vr_svrg_second_moment hn f L hconv hdiff hsmooth wstar hmin w wt
  have k1 := mul_le_mul_of_nonneg_left hI (by positivity : (0 : ℝ) ≤ 2 * α * n)
  have k2 := mul_le_mul_of_nonneg_left hM (by positivity : (0 : ℝ) ≤ α ^ 2)
  rw [inv_mul_le_iff₀ hn']
  nlinarith

#print axioms vr_svrg_step

/-- The SVRG path up to step `k` depends only on the days drawn before step `k`. -/
theorem vr_path_congr {d n m : ℕ} (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ) (α : ℝ)
    (wt : EuclideanSpace ℝ (Fin d)) (s s' : Fin m → Fin n) (k : ℕ)
    (h : ∀ j : Fin m, (j : ℕ) < k → s j = s' j) :
    svrgPath f α wt s k = svrgPath f α wt s' k := by
  induction k with
  | zero => rfl
  | succ k ih =>
    have ih' := ih (fun j hj => h j (Nat.lt_succ_of_lt hj))
    simp only [svrgPath]
    split_ifs with hk
    · rw [ih', h ⟨k, hk⟩ (Nat.lt_succ_self k)]
    · exact ih'

#print axioms vr_path_congr

/-- Averaging over all day lists: when the rest of the summand does not depend on the day in
slot `k`, that day may be replaced by a plain average over all days. -/
theorem vr_sum_shift {n m : ℕ} (hn : 0 < n) {X : Type*} (P : (Fin m → Fin n) → X) (k : Fin m)
    (hP : ∀ s s' : Fin m → Fin n, (∀ j, j ≠ k → s j = s' j) → P s = P s')
    (H : X → Fin n → ℝ) :
    ∑ s : Fin m → Fin n, H (P s) (s k) = ∑ s : Fin m → Fin n, (n : ℝ)⁻¹ * ∑ i, H (P s) i := by
  have : NeZero n := ⟨hn.ne'⟩
  have key : ∀ c : Fin n, ∑ s : Fin m → Fin n, H (P s) (s k + c) =
      ∑ s : Fin m → Fin n, H (P s) (s k) := by
    intro c
    let σ : (Fin m → Fin n) ≃ (Fin m → Fin n) :=
      Equiv.piCongrRight (fun j => if j = k then Equiv.addRight c else Equiv.refl (Fin n))
    have hσk : ∀ s, σ s k = s k + c := by intro s; simp [σ]
    have hσj : ∀ s j, j ≠ k → σ s j = s j := by intro s j hj; simp [σ, hj]
    symm
    rw [← Equiv.sum_comp σ]
    apply Finset.sum_congr rfl
    intro s _
    rw [hσk, hP (σ s) s (fun j hj => hσj s j hj)]
  have h2 : (n : ℝ) * ∑ s : Fin m → Fin n, H (P s) (s k) =
      ∑ s : Fin m → Fin n, ∑ i, H (P s) i := by
    calc (n : ℝ) * ∑ s : Fin m → Fin n, H (P s) (s k)
        = ∑ c : Fin n, ∑ s : Fin m → Fin n, H (P s) (s k + c) := by
          rw [Finset.sum_congr rfl (fun c _ => key c)]
          simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
      _ = ∑ s : Fin m → Fin n, ∑ c : Fin n, H (P s) (s k + c) := Finset.sum_comm
      _ = ∑ s : Fin m → Fin n, ∑ i, H (P s) i := by
          apply Finset.sum_congr rfl; intro s _
          exact Equiv.sum_comp (Equiv.addLeft (s k)) (fun i => H (P s) i)
  rw [← Finset.mul_sum, ← h2, ← mul_assoc, inv_mul_cancel₀ (by positivity), one_mul]

#print axioms vr_sum_shift

/-- **SVRG is unbiased and its noise dies at the optimum.** If every day's loss is convex with
slope changing by at most `L`, and `w*` minimises the average `f`, then averaged over the day
drawn the SVRG estimate equals the true gradient `∇f(w)`, and its mean squared error is at most
`4L (f(w) − f* + f(w̃) − f*)`, which is 0 when `w` and the snapshot `w̃` are both at `w*`. -/
theorem svrg_unbiased_and_variance_bound {d n : ℕ} (hn : 0 < n)
    (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ) (L : ℝ≥0)
    (hconv : ∀ i, ConvexOn ℝ Set.univ (f i)) (hdiff : ∀ i, Differentiable ℝ (f i))
    (hsmooth : ∀ i, LipschitzWith L (∇ (f i)))
    (wstar : EuclideanSpace ℝ (Fin d)) (hmin : ∀ v, fullLoss f wstar ≤ fullLoss f v)
    (w wt : EuclideanSpace ℝ (Fin d)) :
    (n : ℝ)⁻¹ • ∑ i, svrgEst f wt i w = ∇ (fullLoss f) w ∧
    (∑ i, ‖svrgEst f wt i w - ∇ (fullLoss f) w‖ ^ 2) / n ≤
      4 * L * (fullLoss f w - fullLoss f wstar + (fullLoss f wt - fullLoss f wstar)) := by
  have hmean := vr_svrg_mean hn f hdiff w wt
  refine ⟨hmean, ?_⟩
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  let z : Fin n → EuclideanSpace ℝ (Fin d) := fun i => ∇ (f i) w - ∇ (f i) wt
  have hz : ∀ i, svrgEst f wt i w - ∇ (fullLoss f) w = z i - (n : ℝ)⁻¹ • ∑ j, z j := by
    intro i
    simp only [z, svrgEst, Finset.sum_sub_distrib, smul_sub, ← vr_grad_fullLoss f hdiff]
    abel
  have h1 := vr_var_le z
  have h2 : ∑ i, ‖z i‖ ^ 2 ≤ ∑ i, (2 * ‖∇ (f i) w - ∇ (f i) wstar‖ ^ 2 +
      2 * ‖∇ (f i) wt - ∇ (f i) wstar‖ ^ 2) := by
    apply Finset.sum_le_sum; intro i _
    have : z i = (∇ (f i) w - ∇ (f i) wstar) - (∇ (f i) wt - ∇ (f i) wstar) := by
      simp only [z]; abel
    rw [this]; exact vr_norm_sub_sq_le _ _
  rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum] at h2
  have h3 := vr_sum_cocoercive hn f L hconv hdiff hsmooth wstar hmin w
  have h4 := vr_sum_cocoercive hn f L hconv hdiff hsmooth wstar hmin wt
  simp_rw [hz]
  rw [div_le_iff₀ hn']
  linarith

/-- **SAGA is unbiased and its noise dies at the optimum.** Under the same hypotheses, with day
`j`'s stored slope taken at `φ_j`, the SAGA estimate averages to `∇f(w)`, and its mean squared
error is at most `4L (f(w) − f*) + (2/n) ∑_j ‖∇f_j(φ_j) − ∇f_j(w*)‖²`, which is 0 once `w` and
every stored point are at `w*`. -/
theorem saga_unbiased_and_variance_bound {d n : ℕ} (hn : 0 < n)
    (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ) (L : ℝ≥0)
    (hconv : ∀ i, ConvexOn ℝ Set.univ (f i)) (hdiff : ∀ i, Differentiable ℝ (f i))
    (hsmooth : ∀ i, LipschitzWith L (∇ (f i)))
    (wstar : EuclideanSpace ℝ (Fin d)) (hmin : ∀ v, fullLoss f wstar ≤ fullLoss f v)
    (φ : Fin n → EuclideanSpace ℝ (Fin d)) (w : EuclideanSpace ℝ (Fin d)) :
    (n : ℝ)⁻¹ • ∑ i, sagaEst f φ i w = ∇ (fullLoss f) w ∧
    (∑ i, ‖sagaEst f φ i w - ∇ (fullLoss f) w‖ ^ 2) / n ≤
      4 * L * (fullLoss f w - fullLoss f wstar) +
        2 / n * ∑ j, ‖∇ (f j) (φ j) - ∇ (f j) wstar‖ ^ 2 := by
  have hmean := vr_saga_mean hn f hdiff φ w
  refine ⟨hmean, ?_⟩
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  let z : Fin n → EuclideanSpace ℝ (Fin d) := fun i => ∇ (f i) w - ∇ (f i) (φ i)
  have hz : ∀ i, sagaEst f φ i w - ∇ (fullLoss f) w = z i - (n : ℝ)⁻¹ • ∑ j, z j := by
    intro i
    simp only [z, sagaEst, Finset.sum_sub_distrib, smul_sub, ← vr_grad_fullLoss f hdiff]
    abel
  have h1 := vr_var_le z
  have h2 : ∑ i, ‖z i‖ ^ 2 ≤ ∑ i, (2 * ‖∇ (f i) w - ∇ (f i) wstar‖ ^ 2 +
      2 * ‖∇ (f i) (φ i) - ∇ (f i) wstar‖ ^ 2) := by
    apply Finset.sum_le_sum; intro i _
    have : z i = (∇ (f i) w - ∇ (f i) wstar) - (∇ (f i) (φ i) - ∇ (f i) wstar) := by
      simp only [z]; abel
    rw [this]; exact vr_norm_sub_sq_le _ _
  rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum] at h2
  have h3 := vr_sum_cocoercive hn f L hconv hdiff hsmooth wstar hmin w
  simp_rw [hz]
  rw [div_le_iff₀ hn']
  set X := ∑ j, ‖∇ (f j) (φ j) - ∇ (f j) wstar‖ ^ 2 with hX
  have e : 2 / (n : ℝ) * X * n = 2 * X := by field_simp
  linarith

/-- **SVRG's epoch rate.** Add that the average `f` has curvature at least `μ > 0`, take a step
`α` under `1/(2L)` and an epoch of `m ≥ 1` steps from the snapshot `w̃`, with each step's day
drawn uniformly at random, and let the new snapshot be the average of `w_0, …, w_{m−1}`. Then
`E f(w̃_new) − f* ≤ R (f(w̃) − f*)` with `R = 1/(μα(1 − 2Lα)m) + 2Lα/(1 − 2Lα)`. -/
theorem svrg_epoch_rate {d n m : ℕ} (hn : 0 < n) (hm : 0 < m)
    (f : Fin n → EuclideanSpace ℝ (Fin d) → ℝ) (L : ℝ≥0) (μ α : ℝ)
    (hconv : ∀ i, ConvexOn ℝ Set.univ (f i)) (hdiff : ∀ i, Differentiable ℝ (f i))
    (hsmooth : ∀ i, LipschitzWith L (∇ (f i)))
    (hμ : 0 < μ) (hstrong : StrongConvexOn Set.univ μ (fullLoss f))
    (hα : 0 < α) (hstep : 2 * L * α < 1)
    (wstar : EuclideanSpace ℝ (Fin d)) (hmin : ∀ v, fullLoss f wstar ≤ fullLoss f v)
    (wt : EuclideanSpace ℝ (Fin d)) :
    (∑ s : Fin m → Fin n,
        fullLoss f ((m : ℝ)⁻¹ • ∑ k : Fin m, svrgPath f α wt s k)) / (n : ℝ) ^ m
        - fullLoss f wstar ≤
      (1 / (μ * α * (1 - 2 * L * α) * m) + 2 * L * α / (1 - 2 * L * α)) *
        (fullLoss f wt - fullLoss f wstar) := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  have hD0 : 0 ≤ fullLoss f wt - fullLoss f wstar := sub_nonneg.2 (hmin wt)
  have hN0 : (0 : ℝ) < (n : ℝ) ^ m := by positivity
  have hc0 : 0 < 1 - 2 * (L : ℝ) * α := by linarith
  have hsum_const : ∀ x : ℝ, ∑ _s : Fin m → Fin n, x = (n : ℝ) ^ m * x := by
    intro x
    simp [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  let A : ℕ → ℝ := fun k => ∑ s : Fin m → Fin n, ‖svrgPath f α wt s k - wstar‖ ^ 2
  let B : ℕ → ℝ := fun k =>
    ∑ s : Fin m → Fin n, (fullLoss f (svrgPath f α wt s k) - fullLoss f wstar)
  have hstep : ∀ k, k < m → A (k + 1) ≤ A k - 2 * α * (1 - 2 * L * α) * B k +
      (n : ℝ) ^ m * (4 * L * α ^ 2 * (fullLoss f wt - fullLoss f wstar)) := by
    intro k hk
    have e1 : A (k + 1) = ∑ s : Fin m → Fin n,
        (fun (x : EuclideanSpace ℝ (Fin d)) (i : Fin n) =>
          ‖x - α • svrgEst f wt i x - wstar‖ ^ 2) (svrgPath f α wt s k) (s ⟨k, hk⟩) := by
      simp only [A, svrgPath, hk, ↓reduceDIte]
    have hP : ∀ s s' : Fin m → Fin n, (∀ j, j ≠ (⟨k, hk⟩ : Fin m) → s j = s' j) →
        svrgPath f α wt s k = svrgPath f α wt s' k := by
      intro s s' h
      apply vr_path_congr
      intro j hj
      apply h
      intro hjk
      rw [hjk] at hj
      exact lt_irrefl _ hj
    rw [e1]
    refine (vr_sum_shift hn (fun s => svrgPath f α wt s k) ⟨k, hk⟩ hP
      (fun (x : EuclideanSpace ℝ (Fin d)) (i : Fin n) =>
          ‖x - α • svrgEst f wt i x - wstar‖ ^ 2)).trans_le ?_
    calc _ ≤ ∑ s : Fin m → Fin n, (‖svrgPath f α wt s k - wstar‖ ^ 2 -
          2 * α * (1 - 2 * L * α) * (fullLoss f (svrgPath f α wt s k) - fullLoss f wstar) +
          4 * L * α ^ 2 * (fullLoss f wt - fullLoss f wstar)) :=
          Finset.sum_le_sum (fun s _ => vr_svrg_step hn f L μ α hconv hdiff hsmooth hμ.le hstrong
            hα.le wstar hmin wt (svrgPath f α wt s k))
      _ = _ := by
          simp only [A, B, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
            hsum_const]
  have htel : ∀ k, k ≤ m → A k + 2 * α * (1 - 2 * L * α) * ∑ j ∈ Finset.range k, B j ≤
      A 0 + k * ((n : ℝ) ^ m * (4 * L * α ^ 2 * (fullLoss f wt - fullLoss f wstar))) := by
    intro k
    induction k with
    | zero => intro _; simp
    | succ k ih =>
      intro hk
      have h1 := ih (by omega)
      have h2 := hstep k (by omega)
      rw [Finset.sum_range_succ]
      push_cast
      linarith
  have hA0 : A 0 = (n : ℝ) ^ m * ‖wt - wstar‖ ^ 2 := by
    simp only [A, svrgPath, hsum_const]
  have hAm : 0 ≤ A m := Finset.sum_nonneg (fun s _ => sq_nonneg _)
  -- strong convexity bounds the starting distance
  have hgrad0 : ∇ (fullLoss f) wstar = 0 := by
    rw [vr_grad_fullLoss f hdiff, vr_sum_grad_star hn f hdiff wstar hmin, smul_zero]
  have hsc := vr_strong_first_order hstrong wstar wt (vr_diff_fullLoss f hdiff wstar)
  rw [hgrad0, inner_zero_left, add_zero] at hsc
  have hdist : μ * ‖wt - wstar‖ ^ 2 ≤ 2 * (fullLoss f wt - fullLoss f wstar) := by linarith
  -- Jensen for each list of days
  have hconvF : ConvexOn ℝ Set.univ (fullLoss f) :=
    UniformConvexOn.convexOn hstrong (fun r => by simp only [Pi.zero_apply]; positivity)
  have hJ : ∀ s : Fin m → Fin n,
      fullLoss f ((m : ℝ)⁻¹ • ∑ k : Fin m, svrgPath f α wt s k) ≤
        (m : ℝ)⁻¹ * ∑ k : Fin m, fullLoss f (svrgPath f α wt s k) := by
    intro s
    have := hconvF.map_sum_le (t := Finset.univ) (w := fun _ => (m : ℝ)⁻¹)
      (p := fun k : Fin m => svrgPath f α wt s k) (fun _ _ => by positivity)
      (by simp [Finset.sum_const, Finset.card_univ, Fintype.card_fin]; field_simp)
      (fun _ _ => Set.mem_univ _)
    simpa [← Finset.smul_sum, ← Finset.mul_sum] using this
  set S := ∑ j ∈ Finset.range m, B j with hS
  have hBk : ∀ k : ℕ, ∑ s : Fin m → Fin n, fullLoss f (svrgPath f α wt s k) =
      B k + (n : ℝ) ^ m * fullLoss f wstar := by
    intro k
    simp only [B, Finset.sum_sub_distrib, hsum_const]
    ring
  have hT : ∑ s : Fin m → Fin n, (m : ℝ)⁻¹ * ∑ k : Fin m, fullLoss f (svrgPath f α wt s k) =
      (m : ℝ)⁻¹ * (S + m * ((n : ℝ) ^ m * fullLoss f wstar)) := by
    rw [← Finset.mul_sum, Finset.sum_comm]
    simp_rw [hBk]
    rw [Finset.sum_add_distrib, Fin.sum_univ_eq_sum_range (fun k => B k) m]
    simp [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, hS]
  have hfin := htel m le_rfl
  rw [hA0] at hfin
  have hSb : 2 * α * (1 - 2 * L * α) * S ≤ (n : ℝ) ^ m *
      (2 * (fullLoss f wt - fullLoss f wstar) / μ +
        4 * L * α ^ 2 * m * (fullLoss f wt - fullLoss f wstar)) := by
    have : ‖wt - wstar‖ ^ 2 ≤ 2 * (fullLoss f wt - fullLoss f wstar) / μ := by
      rw [le_div_iff₀ hμ]; linarith
    have := mul_le_mul_of_nonneg_left this hN0.le
    nlinarith
  have hS' : S ≤ (n : ℝ) ^ m * (2 * (fullLoss f wt - fullLoss f wstar) / μ +
        4 * L * α ^ 2 * m * (fullLoss f wt - fullLoss f wstar)) / (2 * α * (1 - 2 * L * α)) := by
    rw [le_div_iff₀ (by positivity)]; linarith
  have hsumJ := Finset.sum_le_sum (fun s (_ : s ∈ Finset.univ) => hJ s)
  rw [hT] at hsumJ
  calc (∑ s : Fin m → Fin n,
        fullLoss f ((m : ℝ)⁻¹ • ∑ k : Fin m, svrgPath f α wt s k)) / (n : ℝ) ^ m
        - fullLoss f wstar
      ≤ (m : ℝ)⁻¹ * (S + m * ((n : ℝ) ^ m * fullLoss f wstar)) / (n : ℝ) ^ m
        - fullLoss f wstar := by gcongr
    _ = S / (m * (n : ℝ) ^ m) := by field_simp; ring
    _ ≤ ((n : ℝ) ^ m * (2 * (fullLoss f wt - fullLoss f wstar) / μ +
        4 * L * α ^ 2 * m * (fullLoss f wt - fullLoss f wstar)) / (2 * α * (1 - 2 * L * α)))
          / (m * (n : ℝ) ^ m) := by gcongr
    _ = _ := by field_simp; ring

/-! The card's hand example: two days, `f₁ = (x − 1)²` and `f₂ = (x + 1)²`, with slopes
`2(x − 1)` and `2(x + 1)` and average slope `f'(x) = 2x`; best `x* = 0`. -/

-- At x = 0: SGD's slopes are −2 and +2, variance 4; SVRG with snapshot 0 corrects both to 0.
example :
    let d1 : ℚ → ℚ := fun x => 2 * (x - 1)
    let d2 : ℚ → ℚ := fun x => 2 * (x + 1)
    d1 0 = -2 ∧ d2 0 = 2 ∧ ((d1 0 - 2 * 0) ^ 2 + (d2 0 - 2 * 0) ^ 2) / 2 = 4 ∧
      d1 0 - d1 0 + (d1 0 + d2 0) / 2 = 0 ∧ d2 0 - d2 0 + (d1 0 + d2 0) / 2 = 0 := by
  norm_num

-- At x = 1/2: SGD's slopes are −1 and +3, variance still 4; SVRG with snapshot 0 gives +1 twice,
-- the true f'(1/2).
example :
    let d1 : ℚ → ℚ := fun x => 2 * (x - 1)
    let d2 : ℚ → ℚ := fun x => 2 * (x + 1)
    d1 (1/2) = -1 ∧ d2 (1/2) = 3 ∧
      ((d1 (1/2) - 2 * (1/2)) ^ 2 + (d2 (1/2) - 2 * (1/2)) ^ 2) / 2 = 4 ∧
      d1 (1/2) - d1 0 + (d1 0 + d2 0) / 2 = 2 * (1/2) ∧
      d2 (1/2) - d2 0 + (d1 0 + d2 0) / 2 = 2 * (1/2) := by
  norm_num

-- SAGA at x = 1/4 with both slopes stored at 1/2: +1/2 twice, the true f'(1/4).
example :
    let d1 : ℚ → ℚ := fun x => 2 * (x - 1)
    let d2 : ℚ → ℚ := fun x => 2 * (x + 1)
    d1 (1/4) - d1 (1/2) + (d1 (1/2) + d2 (1/2)) / 2 = 2 * (1/4) ∧
      d2 (1/4) - d2 (1/2) + (d1 (1/2) + d2 (1/2)) / 2 = 2 * (1/4) := by
  norm_num

-- Calls per SVRG epoch, n + 2m: 1,250 at m = 500 and 4,530 at m = 2,140.
example : 250 + 2 * 500 = 1250 ∧ 250 + 2 * 2140 = 4530 := by decide

#print axioms svrg_unbiased_and_variance_bound
#print axioms saga_unbiased_and_variance_bound
#print axioms svrg_epoch_rate
