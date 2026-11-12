-- Convergence rates: on a bowl whose curvatures run from μ > 0 up to L, gradient descent with step 1/L keeps at most the fraction 1 − 1/κ (κ = L/μ) of its error every step and exactly that fraction in the limit, Newton's error near a minimum with nonzero second derivative shrinks like M times its square, and each decimal digit costs between (κ − 1) ln 10 and κ ln 10 steps; the card's exact numbers are checked as fractions.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.LHopital
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecificLimits.Basic

open Filter Topology Real Matrix
open scoped Gradient RealInnerProductSpace

/-! The space is `EuclideanSpace ℝ (Fin n)`: n variables, with the straight-line distance.
The bowl's matrix `A` is a real symmetric matrix (`A.IsHermitian`), acting on a point as
`toEuclideanLin A`. Its curvatures are Mathlib's `hA.eigenvalues i`, with orthonormal
eigen-directions `hA.eigenvectorBasis i`. The bowl is
`f x = f(x*) + ½ (x − x*)ᵀ A (x − x*)`, and `∇ f x` is Mathlib's gradient of `f` at `x`.
`μ` is the gentlest curvature (the smallest eigenvalue, reached by some `i`) and `L` the
sharpest (the largest, reached by some `i`); the condition number is `κ = L / μ`.
Gradient descent with step `1/L` is `x (k + 1) = x k - (1 / L) • ∇ f (x k)`, and the error is
`e_k = ‖x k - x*‖`. -/

theorem quad_gradient_eq {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian)
    (f : EuclideanSpace ℝ (Fin n) → ℝ) (xstar : EuclideanSpace ℝ (Fin n)) (fstar : ℝ)
    (hf : ∀ x, f x = fstar + (1 / 2) * ⟪x - xstar, toEuclideanLin A (x - xstar)⟫)
    (y : EuclideanSpace ℝ (Fin n)) : ∇ f y = toEuclideanLin A (y - xstar) := by
  have hsym : (toEuclideanLin A).IsSymmetric := isSymmetric_toEuclideanLin_iff.mpr hA
  set B : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n) :=
    LinearMap.toContinuousLinearMap (toEuclideanLin A) with hB
  have hfB : f = fun x => fstar + (1 / 2) * ⟪x - xstar, B (x - xstar)⟫ := by
    funext x; rw [hf x]; rfl
  have d1 : HasFDerivAt (fun x : EuclideanSpace ℝ (Fin n) => x - xstar)
      (ContinuousLinearMap.id ℝ _) y := (hasFDerivAt_id y).sub_const xstar
  have d2 : HasFDerivAt (fun x : EuclideanSpace ℝ (Fin n) => B (x - xstar)) B y := by
    have := B.hasFDerivAt.comp y d1
    rwa [ContinuousLinearMap.comp_id] at this
  have d3 := ((d1.inner ℝ d2).const_mul (1 / 2 : ℝ)).const_add fstar
  apply HasGradientAt.gradient
  rw [hasGradientAt_iff_hasFDerivAt, hfB]
  convert d3 using 1
  ext v
  simp [fderivInnerCLM_apply]
  have hBv : ∀ w, B w = toEuclideanLin A w := fun w => rfl
  simp only [hBv]
  have h1 : ⟪y - xstar, toEuclideanLin A v⟫ =
      ⟪toEuclideanLin A y, v⟫ - ⟪toEuclideanLin A xstar, v⟫ := by
    rw [← hsym, map_sub, inner_sub_left]
  have h2 : ⟪v, toEuclideanLin A y - toEuclideanLin A xstar⟫ =
      ⟪toEuclideanLin A y, v⟫ - ⟪toEuclideanLin A xstar, v⟫ := by
    rw [real_inner_comm, inner_sub_left]
  rw [h1, h2]; ring

#print axioms quad_gradient_eq

theorem eig_coord_apply {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian)
    (i : Fin n) (v : EuclideanSpace ℝ (Fin n)) :
    ⟪hA.eigenvectorBasis i, toEuclideanLin A v⟫ = hA.eigenvalues i * ⟪hA.eigenvectorBasis i, v⟫ := by
  have hsym : (toEuclideanLin A).IsSymmetric := isSymmetric_toEuclideanLin_iff.mpr hA
  have hT : toEuclideanLin A (hA.eigenvectorBasis i) =
      hA.eigenvalues i • hA.eigenvectorBasis i := by
    rw [toLpLin_apply, hA.mulVec_eigenvectorBasis]
    rfl
  rw [← hsym, hT, real_inner_smul_left]

#print axioms eig_coord_apply

theorem eig_norm_sq {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian)
    (v : EuclideanSpace ℝ (Fin n)) :
    ‖v‖ ^ 2 = ∑ i, ⟪hA.eigenvectorBasis i, v⟫ ^ 2 := by
  rw [← real_inner_self_eq_norm_sq, ← hA.eigenvectorBasis.sum_inner_mul_inner v v]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [real_inner_comm v, sq]

#print axioms eig_norm_sq

/-- **Gradient descent pays for the stretch.** Take the bowl
`f(x) = f(x*) + ½ (x − x*)ᵀ A (x − x*)` with `A` symmetric, let `μ` and `L` be its smallest and
largest curvatures (eigenvalues), with `μ > 0` (a genuine bowl), and run gradient descent with
step `1/L` from any start. Then every step keeps at most the fraction `1 − 1/κ` of the error,
`κ = L/μ`: `e_{k+1} ≤ (1 − 1/κ) e_k`. And if the start has a nonzero share `a₁` along the
gentlest eigen-direction and `μ` is a simple eigenvalue (no other eigenvalue equals it), the
error ratio `e_{k+1}/e_k` tends to exactly `1 − 1/κ`: a linear rate with that constant. -/
theorem gradient_descent_rate_one_minus_inv_condition_number {n : ℕ}
    (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.IsHermitian)
    (f : EuclideanSpace ℝ (Fin n) → ℝ) (xstar : EuclideanSpace ℝ (Fin n)) (fstar : ℝ)
    (hf : ∀ x, f x = fstar + (1 / 2) * ⟪x - xstar, toEuclideanLin A (x - xstar)⟫)
    (μ L : ℝ) (hμ : ∀ i, μ ≤ hA.eigenvalues i) (hμmem : ∃ i, hA.eigenvalues i = μ)
    (hL : ∀ i, hA.eigenvalues i ≤ L) (hLmem : ∃ i, hA.eigenvalues i = L)
    (hμpos : 0 < μ)
    (x : ℕ → EuclideanSpace ℝ (Fin n)) (hstep : ∀ k, x (k + 1) = x k - (1 / L) • ∇ f (x k)) :
    (∀ k, ‖x (k + 1) - xstar‖ ≤ (1 - 1 / (L / μ)) * ‖x k - xstar‖) ∧
    (∀ i₀, hA.eigenvalues i₀ = μ → (∀ j, j ≠ i₀ → hA.eigenvalues j ≠ μ) →
      ⟪hA.eigenvectorBasis i₀, x 0 - xstar⟫ ≠ 0 →
      Tendsto (fun k => ‖x (k + 1) - xstar‖ / ‖x k - xstar‖) atTop
        (𝓝 (1 - 1 / (L / μ)))) := by
  obtain ⟨i1, hi1⟩ := hμmem
  have hLpos : 0 < L := lt_of_lt_of_le hμpos (hi1 ▸ hL i1)
  have hρ : 1 - 1 / (L / μ) = 1 - μ / L := by rw [one_div_div]
  rw [hρ]
  set ρ := 1 - μ / L with hρdef
  set b := hA.eigenvectorBasis with hb
  set r : Fin n → ℝ := fun i => 1 - hA.eigenvalues i / L with hr
  have he : ∀ k, x (k + 1) - xstar =
      (x k - xstar) - (1 / L) • toEuclideanLin A (x k - xstar) := by
    intro k
    rw [hstep, quad_gradient_eq A hA f xstar fstar hf]
    abel
  have hc : ∀ k i, ⟪b i, x (k + 1) - xstar⟫ = r i * ⟪b i, x k - xstar⟫ := by
    intro k i
    rw [he, inner_sub_right, real_inner_smul_right, eig_coord_apply A hA]
    simp only [hr]; ring
  have hr0 : ∀ i, 0 ≤ r i := by
    intro i
    have : hA.eigenvalues i / L ≤ 1 := (div_le_one hLpos).mpr (hL i)
    simp only [hr]; linarith
  have hrρ : ∀ i, r i ≤ ρ := by
    intro i
    have : μ / L ≤ hA.eigenvalues i / L := div_le_div_of_nonneg_right (hμ i) hLpos.le
    simp only [hr, hρdef]; linarith
  have hρ0 : 0 ≤ ρ := le_trans (hr0 i1) (hrρ i1)
  have part1 : ∀ k, ‖x (k + 1) - xstar‖ ≤ ρ * ‖x k - xstar‖ := by
    intro k
    have hsq : ‖x (k + 1) - xstar‖ ^ 2 ≤ (ρ * ‖x k - xstar‖) ^ 2 := by
      rw [eig_norm_sq A hA, mul_pow, eig_norm_sq A hA, Finset.mul_sum]
      apply Finset.sum_le_sum
      intro i _
      rw [hc, mul_pow]
      exact mul_le_mul_of_nonneg_right (pow_le_pow_left₀ (hr0 i) (hrρ i) 2) (sq_nonneg _)
    exact (pow_le_pow_iff_left₀ (norm_nonneg _) (mul_nonneg hρ0 (norm_nonneg _))
      two_ne_zero).mp hsq
  refine ⟨part1, ?_⟩
  intro i₀ hi₀ hsimple ha
  set a : Fin n → ℝ := fun i => ⟪b i, x 0 - xstar⟫ with hadef
  have hck : ∀ k i, ⟪b i, x k - xstar⟫ = r i ^ k * a i := by
    intro k i
    induction k with
    | zero => simp [hadef]
    | succ k ih => rw [hc, ih]; ring
  rcases hρ0.eq_or_lt with h0 | hpos
  · rw [← h0]
    refine tendsto_const_nhds.congr' (Eventually.of_forall fun k => ?_)
    have h1 := part1 k
    rw [← h0, zero_mul] at h1
    show _ = ‖x (k + 1) - xstar‖ / ‖x k - xstar‖
    rw [le_antisymm h1 (norm_nonneg _), zero_div]
  · set q : Fin n → ℝ := fun i => r i / ρ with hq
    set Tk : ℕ → ℝ := fun k => ∑ i, (q i ^ k * a i) ^ 2 with hTk
    have hnormk : ∀ k, ‖x k - xstar‖ = ρ ^ k * Real.sqrt (Tk k) := by
      intro k
      have hsq : ‖x k - xstar‖ ^ 2 = (ρ ^ k) ^ 2 * Tk k := by
        rw [eig_norm_sq A hA, hTk, Finset.mul_sum]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [hck, show r i = ρ * q i by simp only [hq]; field_simp]
        ring_nf
      rw [← Real.sqrt_sq (norm_nonneg _), hsq, Real.sqrt_mul (by positivity),
        Real.sqrt_sq (by positivity)]
    have hq1 : q i₀ = 1 := by
      simp only [hq, hr, hi₀, hρdef]; exact div_self hpos.ne'
    have hT : Tendsto Tk atTop (𝓝 (a i₀ ^ 2)) := by
      have hi : ∀ i, Tendsto (fun k => (q i ^ k * a i) ^ 2) atTop
          (𝓝 (if i = i₀ then a i ^ 2 else 0)) := by
        intro i
        by_cases hii : i = i₀
        · subst hii; simp [hq1]
        · have hlt : r i < ρ := by
            have hgt : μ < hA.eigenvalues i := lt_of_le_of_ne (hμ i) (hsimple i hii).symm
            have : μ / L < hA.eigenvalues i / L := div_lt_div_of_pos_right hgt hLpos
            simp only [hr, hρdef]; linarith
          have hq0 : 0 ≤ q i := div_nonneg (hr0 i) hpos.le
          have hqlt : q i < 1 := (div_lt_one hpos).mpr hlt
          have := ((tendsto_pow_atTop_nhds_zero_of_lt_one hq0 hqlt).mul_const (a i)).pow 2
          simpa [hii] using this
      have := tendsto_finsetSum Finset.univ (fun i _ => hi i)
      simpa [Finset.sum_ite_eq'] using this
    have hTne : Real.sqrt (a i₀ ^ 2) ≠ 0 := by
      rw [Real.sqrt_sq_eq_abs]; exact abs_ne_zero.mpr ha
    have lim := ((hT.comp (tendsto_add_atTop_nat 1)).sqrt.div hT.sqrt hTne).const_mul ρ
    rw [div_self hTne, mul_one] at lim
    refine lim.congr' (Eventually.of_forall fun k => ?_)
    show ρ * (√(Tk (k + 1)) / √(Tk k)) = ‖x (k + 1) - xstar‖ / ‖x k - xstar‖
    rw [hnormk, hnormk, pow_succ, mul_assoc, mul_div_mul_left _ _ (pow_ne_zero k hpos.ne'),
      mul_div_assoc]

/-- **Newton squares its error.** Let the height `h` of one variable have three continuous
derivatives near `x*`, with `h'(x*) = 0` and `h''(x*) ≠ 0` (an ordinary minimum: the second
derivative, the one-variable Hessian, is invertible). Let Newton's guesses
`x_{k+1} = x_k − h'(x_k)/h''(x_k)` tend to `x*` (the end of the run) without landing on it.
Then `e_{k+1}/e_k²` tends to `M = |h'''(x*) / (2 h''(x*))|`, where `e_k = |x_k − x*|`:
a quadratic rate. -/
theorem newton_error_ratio_to_square_tendsto {h : ℝ → ℝ} {xstar : ℝ} {x : ℕ → ℝ}
    (hh : ContDiffAt ℝ 3 h xstar) (hcrit : deriv h xstar = 0)
    (hinv : deriv (deriv h) xstar ≠ 0)
    (hstep : ∀ k, x (k + 1) = x k - deriv h (x k) / deriv (deriv h) (x k))
    (hne : ∀ k, x k ≠ xstar) (hlim : Tendsto x atTop (𝓝 xstar)) :
    Tendsto (fun k => |x (k + 1) - xstar| / |x k - xstar| ^ 2) atTop
      (𝓝 |deriv (deriv (deriv h)) xstar / (2 * deriv (deriv h) xstar)|) := by
  set g := deriv h with hg
  set g1 := deriv g with hg1
  set g2 := deriv g1 with hg2
  have c2 : ContDiffAt ℝ 2 g xstar := hh.derivWithin (by norm_num)
  have c1 : ContDiffAt ℝ 1 g1 xstar := c2.derivWithin (by norm_num)
  have c0 : ContinuousAt g2 xstar := (c1.derivWithin (m := 0) (by norm_num)).continuousAt
  have e2 : ∀ᶠ y in 𝓝 xstar, ContDiffAt ℝ 2 g y := c2.eventually (by simp)
  have e1 : ∀ᶠ y in 𝓝 xstar, ContDiffAt ℝ 1 g1 y := c1.eventually (by simp)
  have dg : ∀ᶠ y in 𝓝 xstar, HasDerivAt g (g1 y) y :=
    e2.mono fun y hy => (hy.differentiableAt (by norm_num)).hasDerivAt
  have dg1 : ∀ᶠ y in 𝓝 xstar, HasDerivAt g1 (g2 y) y :=
    e1.mono fun y hy => (hy.differentiableAt (by norm_num)).hasDerivAt
  have cg : ContinuousAt g xstar := c2.continuousAt
  have cg1 : ContinuousAt g1 xstar := c1.continuousAt
  set F : ℝ → ℝ := fun y => g1 y * (y - xstar) - g y with hF
  set G : ℝ → ℝ := fun y => (y - xstar) ^ 2 with hG
  have dF : ∀ᶠ y in 𝓝[≠] xstar, HasDerivAt F (g2 y * (y - xstar)) y := by
    refine nhdsWithin_le_nhds ((dg.and dg1).mono fun y ⟨h0, h1⟩ => ?_)
    have := (h1.mul ((hasDerivAt_id y).sub_const xstar)).sub h0
    convert this using 1
    · funext z; simp [hF]
    · simp
  have dG : ∀ᶠ y in 𝓝[≠] xstar, HasDerivAt G (2 * (y - xstar)) y := by
    refine Eventually.of_forall fun y => ?_
    have := ((hasDerivAt_id y).sub_const xstar).pow 2
    convert this using 1
    · funext z; simp [hG]
    · simp
  have nG : ∀ᶠ y in 𝓝[≠] xstar, 2 * (y - xstar) ≠ 0 := by
    filter_upwards [self_mem_nhdsWithin] with y hy
    exact mul_ne_zero two_ne_zero (sub_ne_zero.mpr hy)
  have tF : Tendsto F (𝓝[≠] xstar) (𝓝 0) := by
    have : ContinuousAt F xstar :=
      (cg1.mul (continuousAt_id.sub continuousAt_const)).sub cg
    have h0 : F xstar = 0 := by simp [hF, hcrit]
    rw [← h0]; exact this.tendsto.mono_left nhdsWithin_le_nhds
  have tG : Tendsto G (𝓝[≠] xstar) (𝓝 0) := by
    have : ContinuousAt G xstar := (continuousAt_id.sub continuousAt_const).pow 2
    have h0 : G xstar = 0 := by simp [hG]
    rw [← h0]; exact this.tendsto.mono_left nhdsWithin_le_nhds
  have tdiv : Tendsto (fun y => g2 y * (y - xstar) / (2 * (y - xstar))) (𝓝[≠] xstar)
      (𝓝 (g2 xstar / 2)) := by
    have : Tendsto (fun y => g2 y / 2) (𝓝[≠] xstar) (𝓝 (g2 xstar / 2)) :=
      (c0.tendsto.mono_left nhdsWithin_le_nhds).div_const 2
    refine this.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with y hy
    have : y - xstar ≠ 0 := sub_ne_zero.mpr hy
    field_simp
  have hL := HasDerivAt.lhopital_zero_nhdsNE dF dG nG tF tG tdiv
  have hx' : Tendsto x atTop (𝓝[≠] xstar) :=
    tendsto_nhdsWithin_iff.mpr ⟨hlim, Eventually.of_forall hne⟩
  have t1 : Tendsto (fun k => F (x k) / G (x k)) atTop (𝓝 (g2 xstar / 2)) := hL.comp hx'
  have t2 : Tendsto (fun k => g1 (x k)) atTop (𝓝 (g1 xstar)) := cg1.tendsto.comp hlim
  have t3 := (t1.abs).div (t2.abs) (abs_ne_zero.mpr hinv)
  have hlimval : |g2 xstar / 2| / |g1 xstar| = |g2 xstar / (2 * g1 xstar)| := by
    rw [abs_div, abs_div, abs_mul, div_div]
  rw [hlimval] at t3
  refine t3.congr' ?_
  have ev : ∀ᶠ k in atTop, g1 (x k) ≠ 0 := t2.eventually_ne hinv
  filter_upwards [ev] with k hk
  have hek : x k - xstar ≠ 0 := sub_ne_zero.mpr (hne k)
  show |F (x k) / G (x k)| / |g1 (x k)| = |x (k + 1) - xstar| / |x k - xstar| ^ 2
  have e1 : x (k + 1) - xstar = F (x k) / g1 (x k) := by
    rw [hstep k]; simp only [hF]; field_simp; ring
  have e2 : G (x k) = |x k - xstar| ^ 2 := by simp only [hG, sq_abs]
  rw [e1, e2, abs_div, abs_div, abs_pow, abs_abs, div_div, div_div, mul_comm]

/-- **About 2.3 κ steps per digit.** At the rate `1 − 1/κ` with `κ > 1`, one more correct
decimal digit takes `ln 10 / (−ln(1 − 1/κ))` steps, and that number lies between
`(κ − 1) ln 10` and `κ ln 10`: so it is about `2.303 κ`, growing in step with the stretch. -/
theorem steps_per_digit_about_ln_ten_times_kappa {κ : ℝ} (hκ : 1 < κ) :
    (κ - 1) * log 10 ≤ log 10 / -log (1 - 1 / κ) ∧
      log 10 / -log (1 - 1 / κ) ≤ κ * log 10 := by
  have hκ0 : 0 < κ := by linarith
  have hl10 : 0 < log 10 := Real.log_pos (by norm_num)
  have hpos : 0 < 1 - 1 / κ := by
    rw [sub_pos, div_lt_one hκ0]; exact hκ
  have h1 : log (1 - 1 / κ) ≤ -(1 / κ) := by
    have := Real.log_le_sub_one_of_pos hpos; linarith
  have h2 : -log (1 - 1 / κ) ≤ 1 / (κ - 1) := by
    have hinv : (1 - 1 / κ)⁻¹ = κ / (κ - 1) := by
      field_simp
    have := Real.log_le_sub_one_of_pos (inv_pos.mpr hpos)
    rw [Real.log_inv, hinv] at this
    have e : κ / (κ - 1) - 1 = 1 / (κ - 1) := by
      field_simp; ring
    linarith
  have hD : 0 < -log (1 - 1 / κ) := by
    have : 0 < 1 / κ := by positivity
    linarith
  constructor
  · rw [le_div_iff₀ hD]
    have hk1 : 0 < κ - 1 := by linarith
    have : (κ - 1) * -log (1 - 1 / κ) ≤ 1 := by
      have := mul_le_mul_of_nonneg_left h2 hk1.le
      rwa [mul_one_div_cancel hk1.ne'] at this
    nlinarith
  · rw [div_le_iff₀ hD]
    have : 1 ≤ κ * -log (1 - 1 / κ) := by
      have := mul_le_mul_of_nonneg_left (show 1 / κ ≤ -log (1 - 1 / κ) by linarith) hκ0.le
      rwa [mul_one_div_cancel hκ0.ne'] at this
    nlinarith

/-! The card's exact numbers. -/

-- Both errors start at 0.1. Halving: 0.05 after one step and 0.00625 after four.
example : (1 / 10 : ℚ) / 2 = 5 / 100 ∧ (1 / 10 : ℚ) / 2 ^ 4 = 625 / 100000 := by norm_num
-- Squaring: 0.01 after one step and 10^−16 after four (the digits go 1, 2, 4, 8, 16).
example : (1 / 10 : ℚ) ^ 2 = 1 / 100 ∧ (1 / 10 : ℚ) ^ (2 ^ 4) = 1 / 10 ^ 16 := by norm_num
example : [2 ^ 0, 2 ^ 1, 2 ^ 2, 2 ^ 3, 2 ^ 4] = [1, 2, 4, 8, 16] := by decide
-- Halving needs 37 steps to get below 10^−12: 0.1/2^k < 10^−12 means 2^k > 10^11,
-- and 2^36 ≤ 10^11 < 2^37.
example : 2 ^ 36 ≤ 10 ^ 11 ∧ 10 ^ 11 < 2 ^ 37 := by norm_num
-- Squaring needs 4 steps: 10^−(2^k) < 10^−12 means 2^k > 12, and 2^3 ≤ 12 < 2^4.
example : 2 ^ 3 ≤ 12 ∧ 12 < 2 ^ 4 := by norm_num

-- The Rosenbrock valley f = (1 − x1)² + 100 (x2 − x1²)², minimised at (1, 1):
-- the gradient there is zero.
example : -2 * (1 - (1 : ℚ)) - 400 * 1 * (1 - 1 ^ 2) = 0 ∧ 200 * (1 - (1 : ℚ) ^ 2) = 0 := by
  norm_num
-- The Hessian at (1, 1): 2 − 400 × 0 + 800 = 802, then −400 × 1 = −400, then 2 × 100 = 200.
example : (2 : ℚ) - 400 * (1 - 1 ^ 2) + 800 * 1 ^ 2 = 802 ∧ (-400 : ℚ) * 1 = -400 ∧
    (2 : ℚ) * 100 = 200 := by norm_num
-- Mean of the diagonal 501, half the gap 301, radius squared 301² + 400² = 250601.
example : ((802 : ℚ) + 200) / 2 = 501 ∧ ((802 : ℚ) - 200) / 2 = 301 ∧
    (301 : ℚ) ^ 2 + 400 ^ 2 = 250601 := by norm_num
-- L and μ are 501 ± radius: their sum is the trace 1002 and their product the determinant
-- 501² − 250601 = 400 = 802 × 200 − 400².
example : (501 : ℚ) ^ 2 - 250601 = 400 ∧ (802 : ℚ) * 200 - (-400) ^ 2 = 400 := by norm_num
example : (!![802, -400; -400, 200] : Matrix (Fin 2) (Fin 2) ℚ).det = 400 := by
  rw [det_fin_two_of]; norm_num
-- The start (−1.2, 1) is 2.2 from (1, 1).
example : ((-6 / 5 : ℚ) - 1) ^ 2 + (1 - 1) ^ 2 = (11 / 5) ^ 2 := by norm_num

-- The slice x2 = 1: h(x1) = (1 − x1)² + 100 (1 − x1²)² has slope 400 x1³ − 398 x1 − 2,
-- which is 0 at x1 = 1; its second derivative there is 1200 − 398 = 802, its third 2400.
example (t : ℚ) : -2 * (1 - t) + 100 * (2 * (1 - t ^ 2) * (-2 * t)) = 400 * t ^ 3 - 398 * t - 2 := by
  ring
example : (400 : ℚ) * 1 ^ 3 - 398 * 1 - 2 = 0 ∧ (1200 : ℚ) * 1 ^ 2 - 398 = 802 ∧
    (2400 : ℚ) * 1 = 2400 := by norm_num
-- Newton's constant on the slice: M = 2400 / (2 × 802) = 600/401 (1.4963).
example : (2400 : ℚ) / (2 * 802) = 600 / 401 := by norm_num

-- A round bowl (κ = 1): one step of size 1/L lands exactly on the answer.
example (L x xs : ℚ) (hL : L ≠ 0) : x - (1 / L) * (L * (x - xs)) = xs := by
  field_simp; ring
-- Flat bottom x⁴: Newton's step is x − 4x³/(12x²) = (2/3) x, a linear rate 2/3.
example (t : ℚ) (ht : t ≠ 0) : t - 4 * t ^ 3 / (12 * t ^ 2) = 2 / 3 * t := by
  field_simp; ring
-- From 1, it needs 35 steps to get below 10^−6: (2/3)^35 < 10^−6 ≤ (2/3)^34.
example : (2 / 3 : ℚ) ^ 35 < 1 / 10 ^ 6 ∧ 1 / 10 ^ 6 ≤ (2 / 3 : ℚ) ^ 34 := by norm_num

#print axioms gradient_descent_rate_one_minus_inv_condition_number
#print axioms newton_error_ratio_to_square_tendsto
#print axioms steps_per_digit_about_ln_ten_times_kappa
