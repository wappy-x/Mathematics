-- CAPM: if the market mix has the highest Sharpe ratio, every share's expected return above the bank rate is its beta times the market's, and a share's variance splits into a market part and a private part.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul

open Matrix ProbabilityTheory MeasureTheory

/-- Security market line. Shares `i : Fin n` have expected returns `μ`, an invertible
covariance matrix `C` (so positive definite), and the bank pays `rf`. Everyone sees the same
`μ`, `C` and `rf`, so in equilibrium the market mix `w` (weights summing to 1) is the tangency
mix: no mix `v` with weights summing to 1 has a higher Sharpe ratio
(expected return above the bank rate, divided by volatility).
Then every share's expected return above the bank rate equals its beta,
`Cov(R_i, R_M) / Var(R_M) = (C w)_i / (wᵀ C w)`, times the market's expected return
above the bank rate, `wᵀ μ - rf`. -/
theorem security_market_line (n : ℕ) (C : Matrix (Fin n) (Fin n) ℝ) (hC : C.PosDef)
    (μ : Fin n → ℝ) (rf : ℝ) (w : Fin n → ℝ) (hw : ∑ i, w i = 1)
    (htangency : ∀ v : Fin n → ℝ, ∑ i, v i = 1 →
      (v ⬝ᵥ μ - rf) / Real.sqrt (v ⬝ᵥ (C *ᵥ v)) ≤ (w ⬝ᵥ μ - rf) / Real.sqrt (w ⬝ᵥ (C *ᵥ w))) :
    ∀ i, μ i - rf = ((C *ᵥ w) i / (w ⬝ᵥ (C *ᵥ w))) * (w ⬝ᵥ μ - rf) := by
  intro i
  -- positivity of the quadratic form on mixes summing to 1
  have hQpos : ∀ v : Fin n → ℝ, ∑ j, v j = 1 → 0 < v ⬝ᵥ (C *ᵥ v) := by
    intro v hv
    have hv0 : v ≠ 0 := by
      rintro rfl
      simp at hv
    simpa using hC.dotProduct_mulVec_pos hv0
  -- symmetry
  have hsymm : ∀ x y : Fin n → ℝ, x ⬝ᵥ (C *ᵥ y) = y ⬝ᵥ (C *ᵥ x) := by
    intro x y
    have hT : Cᵀ = C := by
      have := hC.1
      rw [Matrix.IsHermitian, Matrix.conjTranspose_eq_transpose_of_trivial] at this
      exact this
    rw [dotProduct_mulVec, ← mulVec_transpose, hT, dotProduct_comm]
  set q := w ⬝ᵥ (C *ᵥ w) with hq_def
  set a := w ⬝ᵥ μ - rf with ha_def
  have hq : 0 < q := hQpos w hw
  have hsq : 0 < Real.sqrt q := Real.sqrt_pos.2 hq
  set d : Fin n → ℝ := Pi.single i 1 - w with hd
  have hdsum : ∑ j, d j = 0 := by
    simp [d, Finset.sum_sub_distrib, hw]
  set α := d ⬝ᵥ μ with hα
  set B := d ⬝ᵥ (C *ᵥ w) with hB
  set γ := d ⬝ᵥ (C *ᵥ d) with hγ
  have hQ : ∀ t : ℝ, (w + t • d) ⬝ᵥ (C *ᵥ (w + t • d)) = q + t * (2 * B) + t ^ 2 * γ := by
    intro t
    have := hsymm w d
    simp only [mulVec_add, mulVec_smul, dotProduct_add, add_dotProduct, smul_dotProduct,
      dotProduct_smul, smul_eq_mul]
    rw [this]
    ring
  have hA : ∀ t : ℝ, (w + t • d) ⬝ᵥ μ - rf = a + t * α := by
    intro t
    simp only [add_dotProduct, smul_dotProduct, smul_eq_mul, a, α]
    ring
  have hsum : ∀ t : ℝ, ∑ j, (w + t • d) j = 1 := by
    intro t
    simp [Finset.sum_add_distrib, ← Finset.mul_sum, hw, hdsum]
  -- the function that is minimised at 0
  let h : ℝ → ℝ := fun t => a * Real.sqrt (q + t * (2 * B) + t ^ 2 * γ) - Real.sqrt q * (a + t * α)
  have hnonneg : ∀ t, 0 ≤ h t := by
    intro t
    have h1 := htangency (w + t • d) (hsum t)
    have hpos := hQpos (w + t • d) (hsum t)
    rw [hQ t] at h1 hpos
    rw [hA t] at h1
    have hsqt : 0 < Real.sqrt (q + t * (2 * B) + t ^ 2 * γ) := Real.sqrt_pos.2 hpos
    rw [div_le_div_iff₀ hsqt hsq] at h1
    simp only [h]
    linarith
  have h0 : h 0 = 0 := by simp [h]; ring
  have hmin : IsLocalMin h 0 := by
    refine Filter.Eventually.of_forall fun t => ?_
    rw [h0]; exact hnonneg t
  have hderiv : HasDerivAt h (a * ((2 * B) / (2 * Real.sqrt q)) - Real.sqrt q * α) 0 := by
    have hin : HasDerivAt (fun t : ℝ => q + t * (2 * B) + t ^ 2 * γ) (2 * B) 0 := by
      have e1 := HasDerivAt.add (hasDerivAt_const (0 : ℝ) q) (HasDerivAt.mul_const (hasDerivAt_id (0 : ℝ)) (2 * B))
      have e2 := HasDerivAt.mul_const (hasDerivAt_pow 2 (0 : ℝ)) γ
      convert HasDerivAt.add e1 e2 using 1
      · funext t; simp
      · simp
    have hsq' := HasDerivAt.sqrt hin (by simp; exact hq.ne')
    have hlin : HasDerivAt (fun t : ℝ => a + t * α) α 0 := by
      convert HasDerivAt.add (hasDerivAt_const (0 : ℝ) a) (HasDerivAt.mul_const (hasDerivAt_id (0 : ℝ)) α) using 1
      · funext t; simp
      · simp
    convert HasDerivAt.sub (HasDerivAt.const_mul a hsq') (HasDerivAt.const_mul (Real.sqrt q) hlin) using 2
    simp
  have hzero := IsLocalMin.hasDerivAt_eq_zero hmin hderiv
  -- a * B = q * α
  have hkey : a * B = q * α := by
    field_simp at hzero
    rw [Real.sq_sqrt hq.le] at hzero
    linarith
  have hαv : α = μ i - w ⬝ᵥ μ := by
    simp [α, d, sub_dotProduct]
  have hBv : B = (C *ᵥ w) i - q := by
    simp [B, d, sub_dotProduct, q]
  rw [hαv, hBv] at hkey
  field_simp
  have : w ⬝ᵥ μ = a + rf := by simp [a]
  rw [this] at hkey
  linarith

/-- Where the rest of the risk went. Write a share's return as
`R_i = rf + α + β (R_M - rf) + ε`, where the leftover `ε` has zero covariance with the
market's return `R_M` (both with finite variance). Then the share's variance is the market
part plus the private part: `Var(R_i) = β² Var(R_M) + Var(ε)`. -/
theorem variance_splits_market_and_private {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (RM ε : Ω → ℝ) (hRM : MemLp RM 2 P) (hε : MemLp ε 2 P)
    (hcov : cov[ε, RM; P] = 0) (rf α β : ℝ) :
    Var[fun ω => rf + α + β * (RM ω - rf) + ε ω; P] = β ^ 2 * Var[RM; P] + Var[ε; P] := by
  have hβRM : MemLp (fun ω => β * RM ω) 2 P := hRM.const_mul β
  have h1 : (fun ω => rf + α + β * (RM ω - rf) + ε ω)
      = fun ω => (rf + α - β * rf) + (β * RM ω + ε ω) := by
    funext ω; ring
  have hm : AEStronglyMeasurable (fun ω => β * RM ω + ε ω) P := (hβRM.add hε).aestronglyMeasurable
  rw [h1, variance_const_add hm, variance_fun_add hβRM hε,
    covariance_const_mul_left, covariance_comm, hcov, variance_const_mul]
  ring

/-- Estimating beta is fitting a straight line. From `n` periods of market returns `x` and
share returns `y` (both above the bank rate), where the market's returns are not all equal,
the line `y = a + b x` with slope `b = Σ (x - x̄)(y - ȳ) / Σ (x - x̄)²` and intercept
`a = ȳ - b x̄` (the estimated alpha) has a strictly smaller sum of squared misses than
every other line: it is the least-squares line. -/
theorem least_squares_line_gives_beta_and_alpha (n : ℕ) (x y : Fin n → ℝ)
    (hx : ∃ s t, x s ≠ x t) :
    let xbar := (∑ t, x t) / n
    let ybar := (∑ t, y t) / n
    let b := (∑ t, (x t - xbar) * (y t - ybar)) / ∑ t, (x t - xbar) ^ 2
    let a := ybar - b * xbar
    ∀ a' b' : ℝ, (a', b') ≠ (a, b) →
      ∑ t, (y t - (a + b * x t)) ^ 2 < ∑ t, (y t - (a' + b' * x t)) ^ 2 := by
  intro xbar ybar b a a' b' hne
  obtain ⟨s, s', hss'⟩ := hx
  have hn : (n : ℝ) ≠ 0 := by
    have : 0 < n := Fin.pos s
    exact_mod_cast this.ne'
  have hsx : ∑ t, x t = n * xbar := by simp only [xbar]; field_simp
  have hsy : ∑ t, y t = n * ybar := by simp only [ybar]; field_simp
  have hSxx : 0 < ∑ t, (x t - xbar) ^ 2 := by
    by_contra hle
    push Not at hle
    have h0 : ∀ t ∈ Finset.univ, (x t - xbar) ^ 2 = 0 :=
      (Finset.sum_eq_zero_iff_of_nonneg (fun t _ => sq_nonneg _)).1
        (le_antisymm hle (Finset.sum_nonneg fun t _ => sq_nonneg _))
    have e1 := h0 s (Finset.mem_univ _)
    have e2 := h0 s' (Finset.mem_univ _)
    apply hss'
    have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 e1
    have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 e2
    linarith
  -- residuals
  set r : Fin n → ℝ := fun t => y t - (a + b * x t) with hr
  have hr0 : ∑ t, r t = 0 := by
    simp only [r, Finset.sum_sub_distrib, Finset.sum_add_distrib, Finset.sum_const,
      Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, ← Finset.mul_sum, hsx, hsy, a]
    ring
  have hrx : ∑ t, r t * x t = 0 := by
    have e : ∀ t, r t * x t = r t * xbar + ((x t - xbar) * (y t - ybar) - b * (x t - xbar) ^ 2
        - (x t - xbar) * (b * xbar + a - ybar)) := by
      intro t; simp only [r]; ring
    have hab : b * xbar + a - ybar = 0 := by simp only [a]; ring
    simp only [e, hab, mul_zero, sub_zero, Finset.sum_add_distrib, Finset.sum_sub_distrib,
      ← Finset.sum_mul, hr0, zero_mul, zero_add, ← Finset.mul_sum]
    simp only [b]
    field_simp
    ring
  have hpos : 0 < ∑ t, ((a - a') + (b - b') * x t) ^ 2 := by
    by_contra hle
    push Not at hle
    have h0 : ∀ t ∈ Finset.univ, ((a - a') + (b - b') * x t) ^ 2 = 0 :=
      (Finset.sum_eq_zero_iff_of_nonneg (fun t _ => sq_nonneg _)).1
        (le_antisymm hle (Finset.sum_nonneg fun t _ => sq_nonneg _))
    have e1 := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 (h0 s (Finset.mem_univ _))
    have e2 := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 (h0 s' (Finset.mem_univ _))
    have hb : b - b' = 0 := by
      have : (b - b') * (x s - x s') = 0 := by linarith
      rcases mul_eq_zero.1 this with h | h
      · exact h
      · exact absurd (sub_eq_zero.1 h) hss'
    have ha : a - a' = 0 := by rw [hb] at e1; linarith
    apply hne
    rw [Prod.mk.injEq]
    constructor <;> linarith
  have key : ∑ t, (y t - (a' + b' * x t)) ^ 2
      = ∑ t, r t ^ 2 + 2 * ((a - a') * ∑ t, r t + (b - b') * ∑ t, r t * x t)
        + ∑ t, ((a - a') + (b - b') * x t) ^ 2 := by
    simp only [Finset.mul_sum, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun t _ => ?_
    simp only [r]; ring
  rw [key, hr0, hrx]
  simp only [r]
  linarith

/-! Worked numbers from the card, as exact fractions (percent units). -/

-- Covariance matrix of Kestrel, Oakridge, Pinecrest times market weights 20, 40, 40 percent:
-- covariances with the market 480, 320, 440.
example : (!![900, 300, 450; 300, 400, 250; 450, 250, 625] : Matrix (Fin 3) (Fin 3) ℚ)
    *ᵥ ![1/5, 2/5, 2/5] = ![480, 320, 440] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_three]

-- Market variance 400 (volatility 20 percent).
example : (1/5 : ℚ) * 480 + 2/5 * 320 + 2/5 * 440 = 400 := by norm_num

-- Betas 1.2, 0.8, 1.1.
example : (480 : ℚ) / 400 = 6/5 ∧ (320 : ℚ) / 400 = 4/5 ∧ (440 : ℚ) / 400 = 11/10 := by norm_num

-- Expected returns on the line: Kestrel 8.8, Oakridge 7.2, Pinecrest 8.4 percent.
example : (4 : ℚ) + 6/5 * (8 - 4) = 44/5 ∧ (4 : ℚ) + 4/5 * (8 - 4) = 36/5 ∧
    (4 : ℚ) + 11/10 * (8 - 4) = 42/5 := by norm_num

-- The weighted average of the three lands back on the market's 8 percent.
example : (1/5 : ℚ) * (44/5) + 2/5 * (36/5) + 2/5 * (42/5) = 8 := by norm_num

-- Kestrel's variance split: 900 = 1.44 × 400 + 324.
example : (900 : ℚ) = (6/5) ^ 2 * 400 + 324 := by norm_num

-- Wrong roads: total volatility gives 10, correlation 0.8 gives 7.2, beta × whole return 9.6.
example : (4 : ℚ) + 30/20 * 4 = 10 ∧ (4 : ℚ) + 4/5 * 4 = 36/5 ∧ (6/5 : ℚ) * 8 = 48/5 := by
  norm_num

-- Four quarters: x = −2, −1, 1, 2 and y = −0.9, −2.7, 3.7, 1.9.
-- Averages 0 and 0.5; Sxx = 10; Sxy = 12; beta 1.2; alpha 0.5.
example : (∑ t : Fin 4, (![-2, -1, 1, 2] : Fin 4 → ℚ) t) / 4 = 0 ∧
    (∑ t : Fin 4, (![-9/10, -27/10, 37/10, 19/10] : Fin 4 → ℚ) t) / 4 = 1/2 := by
  norm_num [Fin.sum_univ_four]

example : ∑ t : Fin 4, ((![-2, -1, 1, 2] : Fin 4 → ℚ) t - 0) ^ 2 = 10 ∧
    ∑ t : Fin 4, ((![-2, -1, 1, 2] : Fin 4 → ℚ) t - 0) *
      ((![-9/10, -27/10, 37/10, 19/10] : Fin 4 → ℚ) t - 1/2) = 12 := by
  norm_num [Fin.sum_univ_four]

example : (12 : ℚ) / 10 = 6/5 ∧ (1/2 : ℚ) - 6/5 * 0 = 1/2 := by norm_num

#print axioms security_market_line
#print axioms variance_splits_market_and_private
#print axioms least_squares_line_gives_beta_and_alpha
