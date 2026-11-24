-- Frank-Wolfe: with steps 2/(k + 2) every iterate stays in the region and the error after k ≥ 1 steps is at most 2C/(k + 2), the Frank-Wolfe gap bounds the error, and a smooth cost on a bounded region has curvature constant at most L·diam(D)².
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Convex.Function
import Mathlib.Topology.EMetricSpace.Lipschitz
import Mathlib.Topology.MetricSpace.Bounded
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.FDeriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Pow

open InnerProductSpace
open scoped RealInnerProductSpace

/-! The weights live in a real inner product space `E` (the simplex sits inside `ℝⁿ`).
`D` is the region of allowed choices, `f` the cost, and `g w` the gradient `∇f(w)`, given by
Mathlib's `HasGradientAt`. `⟪a, b⟫` is the dot product `aᵀb`.

The **curvature constant** `C` is, as on the card's Step 3, any number with
`f(w + α(s − w)) ≤ f(w) + α ∇f(w)ᵀ(s − w) + (α²/2) C` for every `w`, `s` in `D` and every
`α` in `[0, 1]`. The card says a smooth cost on a bounded region makes `C` finite; the third
theorem proves that `C = L · diam(D)²` works when the gradient changes at rate at most `L`.

The **oracle** picks `s_k` in `D` with the smallest `∇f(w_k)ᵀ s` over all of `D`, and the
step is `w_{k+1} = w_k + (2/(k + 2)) (s_k − w_k)`, counting from `k = 0`. `w*` is a minimiser
of `f` over `D`, so `f* = f(w*)`. -/

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [CompleteSpace E]

theorem fw_line_hasDerivAt {f : E → ℝ} {x y : E} {t : ℝ} {gz : E}
    (hg : HasGradientAt f gz (x + t • (y - x))) :
    HasDerivAt (fun τ : ℝ => f (x + τ • (y - x))) ⟪gz, y - x⟫ t := by
  have h1 : HasDerivAt (fun τ : ℝ => x + τ • (y - x)) (y - x) t := by
    simpa using ((hasDerivAt_id t).smul_const (y - x)).const_add x
  have h2 := (hasGradientAt_iff_hasFDerivAt.mp hg).comp_hasDerivAt t h1
  simpa [Function.comp_def, toDual_apply_apply] using h2

#print axioms fw_line_hasDerivAt

theorem fw_gradient_inequality {D : Set E} {f : E → ℝ} (hf : ConvexOn ℝ D f) {x : E}
    (hx : x ∈ D) {gx : E} (hg : HasGradientAt f gx x) {y : E} (hy : y ∈ D) :
    f x + ⟪gx, y - x⟫ ≤ f y := by
  have hφ : HasDerivAt (fun τ : ℝ => f (x + τ • (y - x))) ⟪gx, y - x⟫ 0 :=
    fw_line_hasDerivAt (by simpa using hg)
  have ht := hφ.tendsto_slope_zero_right
  have hle : ⟪gx, y - x⟫ ≤ f y - f x := by
    refine le_of_tendsto ht ?_
    filter_upwards [Ioc_mem_nhdsGT (show (0:ℝ) < 1 by norm_num)] with t ht
    obtain ⟨ht0, ht1⟩ := ht
    have hc := hf.2 hx hy (show (0:ℝ) ≤ 1 - t by linarith) ht0.le (by ring)
    have heq : (1 - t) • x + t • y = x + t • (y - x) := by
      rw [smul_sub, sub_smul, one_smul]; abel
    rw [heq] at hc
    simp only [smul_eq_mul, zero_add, zero_smul, add_zero] at hc ⊢
    rw [inv_mul_le_iff₀ ht0]
    nlinarith
  linarith

#print axioms fw_gradient_inequality

/-- **Frank-Wolfe stays feasible and its error falls like 1/k.** Let the region `D` be convex,
the cost `f` convex on `D` with gradient `g`, and `C` a curvature constant for `f` on `D`.
Start at `w₀` in `D`, let each `s_k` be an exact oracle answer at `w_k`, and step with
`α_k = 2/(k + 2)`. Then every iterate `w_k` lies in `D`, and for every `k ≥ 1`
`f(w_k) − f* ≤ 2C/(k + 2)`. -/
theorem frank_wolfe_feasible_and_error_le_two_C_div_k_add_two
    {D : Set E} (hD : Convex ℝ D) {f : E → ℝ} (hf : ConvexOn ℝ D f) {g : E → E}
    (hg : ∀ x ∈ D, HasGradientAt f (g x) x) {C : ℝ}
    (hC : ∀ x ∈ D, ∀ y ∈ D, ∀ α ∈ Set.Icc (0 : ℝ) 1,
      f (x + α • (y - x)) ≤ f x + α * ⟪g x, y - x⟫ + α ^ 2 / 2 * C)
    {wstar : E} (hwstar : wstar ∈ D) (hmin : ∀ y ∈ D, f wstar ≤ f y)
    (w s : ℕ → E) (hw0 : w 0 ∈ D)
    (hs : ∀ k, s k ∈ D) (horacle : ∀ k, ∀ y ∈ D, ⟪g (w k), s k⟫ ≤ ⟪g (w k), y⟫)
    (hstep : ∀ k, w (k + 1) = w k + (2 / ((k : ℝ) + 2)) • (s k - w k)) :
    (∀ k, w k ∈ D) ∧
    (∀ k : ℕ, 1 ≤ k → f (w k) - f wstar ≤ 2 * C / ((k : ℝ) + 2)) := by
  have hαI : ∀ k : ℕ, (2 / ((k : ℝ) + 2)) ∈ Set.Icc (0 : ℝ) 1 := by
    intro k
    have hk : (0:ℝ) ≤ k := Nat.cast_nonneg k
    refine ⟨by positivity, ?_⟩
    rw [div_le_one (by positivity)]; linarith
  have hfeas : ∀ k, w k ∈ D := by
    intro k
    induction k with
    | zero => exact hw0
    | succ k ih => rw [hstep k]; exact hD.add_smul_sub_mem ih (hs k) (hαI k)
  refine ⟨hfeas, ?_⟩
  have hC0 : 0 ≤ C := by
    have := hC (w 0) hw0 (w 0) hw0 1 ⟨zero_le_one, le_rfl⟩
    simp at this
    linarith
  have hrec : ∀ k : ℕ, f (w (k + 1)) - f wstar ≤
      (1 - 2 / ((k : ℝ) + 2)) * (f (w k) - f wstar) + (2 / ((k : ℝ) + 2)) ^ 2 / 2 * C := by
    intro k
    have h1 := hC (w k) (hfeas k) (s k) (hs k) _ (hαI k)
    rw [← hstep k] at h1
    have h2 := horacle k wstar hwstar
    have h3 := fw_gradient_inequality hf (hfeas k) (hg _ (hfeas k)) hwstar
    have h4 : ⟪g (w k), s k - w k⟫ ≤ f wstar - f (w k) := by
      rw [inner_sub_right] at h3 ⊢; linarith
    have h5 := mul_le_mul_of_nonneg_left h4 (hαI k).1
    nlinarith
  intro k hk
  induction k, hk using Nat.le_induction with
  | base =>
    have := hrec 0
    norm_num at this ⊢
    linarith
  | succ k hk ih =>
    have := hrec k
    push_cast
    have hk' : (1:ℝ) ≤ k := by exact_mod_cast hk
    set a : ℝ := (k : ℝ) + 2 with ha
    have ha0 : 0 < a := by linarith
    have hcoef : 0 ≤ 1 - 2 / a := by
      rw [sub_nonneg, div_le_one ha0]; linarith
    have h1 := mul_le_mul_of_nonneg_left ih hcoef
    have hkey : (1 - 2 / a) * (2 * C / a) + (2 / a) ^ 2 / 2 * C ≤ 2 * C / ((k : ℝ) + 1 + 2) := by
      have : (k : ℝ) + 1 + 2 = a + 1 := by rw [ha]; ring
      rw [this]
      have e : (1 - 2 / a) * (2 * C / a) + (2 / a) ^ 2 / 2 * C = 2 * C * (a - 1) / a ^ 2 := by
        field_simp; ring
      rw [e, div_le_div_iff₀ (by positivity) (by positivity)]
      nlinarith [mul_nonneg hC0 (sq_nonneg a)]
    linarith

/-- **The Frank-Wolfe gap bounds the error.** Let `D` be convex and `f` convex on `D` with
gradient `g x` at a point `x` of `D`. If `s` in `D` is an exact oracle answer at `x`, then the
gap `G(x) = ∇f(x)ᵀ(x − s)` satisfies `f(x) − f(y) ≤ G(x)` for every `y` in `D`. So
`f(x) − G(x)` is a floor under the minimum, `f(x) − f* ≤ G(x)`, and a zero gap certifies that
`x` is a minimiser. -/
theorem frank_wolfe_gap_bounds_error
    {D : Set E} (hD : Convex ℝ D) {f : E → ℝ} (hf : ConvexOn ℝ D f) {x : E} (hx : x ∈ D)
    {gx : E} (hg : HasGradientAt f gx x) {s : E} (hs : s ∈ D)
    (horacle : ∀ y ∈ D, ⟪gx, s⟫ ≤ ⟪gx, y⟫) :
    ∀ y ∈ D, f x - f y ≤ ⟪gx, x - s⟫ := by
  intro y hy
  have h1 := fw_gradient_inequality hf hx hg hy
  have h2 := horacle y hy
  rw [inner_sub_right] at h1 ⊢
  linarith

/-- **A smooth cost on a bounded region has curvature constant at most `L · diam(D)²`.**
Let `D` be convex and bounded, `f` have gradient `g` at every point of `D`, and let `g` change
at rate at most `L` on `D` (`‖g x − g y‖ ≤ L‖x − y‖`). Then for all `w`, `s` in `D` and `α` in
`[0, 1]`, `f(w + α(s − w)) ≤ f(w) + α ∇f(w)ᵀ(s − w) + (α²/2) · L · diam(D)²`. -/
theorem curvature_constant_le_L_mul_diam_sq
    {D : Set E} (hD : Convex ℝ D) (hbdd : Bornology.IsBounded D) {f : E → ℝ} {g : E → E}
    (hg : ∀ x ∈ D, HasGradientAt f (g x) x) {L : NNReal} (hL : LipschitzOnWith L g D) :
    ∀ x ∈ D, ∀ y ∈ D, ∀ α ∈ Set.Icc (0 : ℝ) 1,
      f (x + α • (y - x)) ≤ f x + α * ⟪g x, y - x⟫ + α ^ 2 / 2 * ((L : ℝ) * Metric.diam D ^ 2) := by
  intro x hx y hy α hα
  set d := ‖y - x‖ with hd
  let φ : ℝ → ℝ := fun t => f (x + t • (y - x)) - f x - t * ⟪g x, y - x⟫ - (L : ℝ) * t ^ 2 / 2 * d ^ 2
  have hmem : ∀ t ∈ Set.Icc (0:ℝ) α, x + t • (y - x) ∈ D := fun t ht =>
    hD.add_smul_sub_mem hx hy ⟨ht.1, ht.2.trans hα.2⟩
  have hder : ∀ t ∈ Set.Icc (0:ℝ) α, HasDerivAt φ
      (⟪g (x + t • (y - x)), y - x⟫ - ⟪g x, y - x⟫ - (L : ℝ) * t * d ^ 2) t := by
    intro t ht
    have h1 := fw_line_hasDerivAt (hg _ (hmem t ht))
    have h2 := ((h1.sub_const (f x)).sub ((hasDerivAt_id t).mul_const ⟪g x, y - x⟫)).sub
      (((hasDerivAt_pow 2 t).const_mul ((L : ℝ) / 2)).mul_const (d ^ 2))
    convert h2 using 1
    · funext τ; simp only [φ, Pi.sub_apply, id]; ring
    · simp only [show (2:ℕ) - 1 = 1 from rfl, pow_one, Nat.cast_ofNat, one_mul]; ring
  have hanti : AntitoneOn φ (Set.Icc 0 α) := by
    apply antitoneOn_of_deriv_nonpos (convex_Icc 0 α)
    · intro t ht; exact (hder t ht).continuousAt.continuousWithinAt
    · intro t ht
      exact (hder t (interior_subset ht)).differentiableAt.differentiableWithinAt
    · intro t ht
      have ht' := interior_subset ht
      rw [(hder t ht').deriv]
      have hz := hmem t ht'
      have hlip : dist (g (x + t • (y - x))) (g x) ≤ L * dist (x + t • (y - x)) x :=
        hL.dist_le_mul _ hz _ hx
      rw [dist_eq_norm, dist_eq_norm, add_sub_cancel_left, norm_smul,
        Real.norm_of_nonneg ht'.1] at hlip
      have hcs : ⟪g (x + t • (y - x)) - g x, y - x⟫ ≤ ‖g (x + t • (y - x)) - g x‖ * d :=
        real_inner_le_norm _ _
      rw [inner_sub_left] at hcs
      have hd0 : 0 ≤ d := norm_nonneg _
      have := mul_le_mul_of_nonneg_right hlip hd0
      nlinarith
  have h0 : (0:ℝ) ∈ Set.Icc 0 α := ⟨le_rfl, hα.1⟩
  have hα' : α ∈ Set.Icc 0 α := ⟨hα.1, le_rfl⟩
  have key := hanti h0 hα' hα.1
  simp only [φ, zero_smul, add_zero, zero_mul, sub_self] at key
  have hdd : d ≤ Metric.diam D := by
    rw [hd, ← dist_eq_norm]; exact Metric.dist_le_diam_of_mem hbdd hy hx
  have hd0 : 0 ≤ d := norm_nonneg _
  have hsq : d ^ 2 ≤ Metric.diam D ^ 2 := pow_le_pow_left₀ hd0 hdd 2
  have hL0 : (0:ℝ) ≤ L := L.2
  have : (L : ℝ) * α ^ 2 / 2 * d ^ 2 ≤ α ^ 2 / 2 * ((L : ℝ) * Metric.diam D ^ 2) := by
    have := mul_le_mul_of_nonneg_left hsq (mul_nonneg hL0 (sq_nonneg α))
    nlinarith
  linarith

/-! The card's three-asset example, in exact fractions: target `t = (7/10, 4/10, −1/10)`,
cost `f(w) = ‖w − t‖²`, start `w₀ = (1, 0, 0)`. -/

/-- Cost at the start: `0.3² + 0.4² + 0.1² = 0.26`. -/
example : ((1 : ℚ) - 7/10) ^ 2 + (0 - 4/10) ^ 2 + (0 - (-1/10)) ^ 2 = 13/50 := by norm_num

/-- Gradient `2(w₀ − t) = (0.6, −0.8, 0.2)`; its smallest entry is the second, so the oracle
picks `e₂`. -/
example : (2 * ((1 : ℚ) - 7/10), 2 * ((0 : ℚ) - 4/10), 2 * ((0 : ℚ) - (-1/10)))
    = (3/5, -4/5, 1/5) ∧ (-4/5 : ℚ) < 3/5 ∧ (-4/5 : ℚ) < 1/5 := by norm_num

/-- Gap at the start: `∇f(w₀)ᵀ w₀ − (−0.8) = 1.4`. -/
example : (3/5 : ℚ) * 1 + (-4/5) * 0 + (1/5) * 0 - (-4/5) = 7/5 := by norm_num

/-- Line search along `e₂ − w₀ = (−1, 1, 0)`: step `0.7/2 = 0.35`. -/
example : -(((1 : ℚ) - 7/10) * (-1) + (0 - 4/10) * 1 + (0 - (-1/10)) * 0)
    / ((-1) ^ 2 + 1 ^ 2 + 0 ^ 2) = 7/20 := by norm_num

/-- New weights `w₁ = (0.65, 0.35, 0)` and new cost `0.015`. -/
example : ((1 : ℚ) + 7/20 * (-1), (0 : ℚ) + 7/20 * 1, (0 : ℚ) + 7/20 * 0) = (13/20, 7/20, 0) ∧
    ((13/20 : ℚ) - 7/10) ^ 2 + (7/20 - 4/10) ^ 2 + (0 - (-1/10)) ^ 2 = 3/200 := by norm_num

/-- At `w₁` the gradient is `(−0.1, −0.1, 0.2)`, the oracle's best entry is `−0.1`, and the
gap is `0`: the minimum is certified. -/
example : (2 * ((13/20 : ℚ) - 7/10), 2 * ((7/20 : ℚ) - 4/10), 2 * ((0 : ℚ) - (-1/10)))
    = (-1/10, -1/10, 1/5) ∧
    (-1/10 : ℚ) * (13/20) + (-1/10) * (7/20) + (1/5) * 0 - (-1/10) = 0 := by norm_num

/-- The error at the start, `0.26 − 0.015 = 0.245`, is under the gap `1.4`. -/
example : (13/50 : ℚ) - 3/200 = 49/200 ∧ (49/200 : ℚ) ≤ 7/5 := by norm_num

/-- Curvature constant of the toy: `L = 2` and the longest side `‖e₁ − e₂‖² = 2` give `C = 4`;
the first step's bound `C/2 = 2` is below `2C/3`. -/
example : (2 : ℚ) * ((1 - 0) ^ 2 + (0 - 1) ^ 2 + (0 - 0) ^ 2) = 4 ∧ (4 : ℚ) / 2 ≤ 2 * 4 / 3 := by
  norm_num

/-- The induction step's key fact, `(k + 1)(k + 3) ≤ (k + 2)²`, for every whole number `k`. -/
example (k : ℕ) : (k + 1) * (k + 3) ≤ (k + 2) ^ 2 := by nlinarith

/-- The concave cost `−‖w − c‖²` with `c` the centre: at corner `e₁` it is `−2/3`, so the
centre (cost `0`, gap `0`) is `2/3` above the minimum. -/
example : -(((1 : ℚ) - 1/3) ^ 2 + (0 - 1/3) ^ 2 + (0 - 1/3) ^ 2) = -2/3 := by norm_num

/-- The grid of weight lists in steps of `0.01` has `5,151` points: with `i` hundredths in
asset 1 there are `101 − i` choices for asset 2, and asset 3 takes the rest. -/
example : ∑ i ∈ Finset.range 101, (101 - i) = 5151 := by decide

#print axioms frank_wolfe_feasible_and_error_le_two_C_div_k_add_two
#print axioms frank_wolfe_gap_bounds_error
#print axioms curvature_constant_le_L_mul_diam_sq
