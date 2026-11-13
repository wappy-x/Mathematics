-- Two assets: a mix of two returns has the weighted average of their means, a variance with a cross term of twice the product of the weights times the covariance, a spread never above the weighted average of the spreads, and a unique least-risk weight.
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.QuadraticDiscriminant

open MeasureTheory ProbabilityTheory Real

/-- Variance of a general two-term linear combination. -/
lemma two_asset_var_lin
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (RA RB : Ω → ℝ) (hA : MemLp RA 2 μ) (hB : MemLp RB 2 μ) (p q : ℝ) :
    Var[fun ω => p * RA ω + q * RB ω; μ]
      = p ^ 2 * Var[RA; μ] + q ^ 2 * Var[RB; μ] + 2 * p * q * cov[RA, RB; μ] := by
  have h := variance_fun_add (hA.const_mul p) (hB.const_mul q)
  rw [h, variance_const_mul, variance_const_mul, covariance_const_mul_left,
    covariance_const_mul_right]
  ring

/-- Cauchy–Schwarz for covariance: `cov² ≤ Var A · Var B`. -/
lemma two_asset_cov_sq_le
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (RA RB : Ω → ℝ) (hA : MemLp RA 2 μ) (hB : MemLp RB 2 μ) :
    cov[RA, RB; μ] ^ 2 ≤ Var[RA; μ] * Var[RB; μ] := by
  have h : ∀ t : ℝ, 0 ≤ Var[RA; μ] * (t * t) + (-2 * cov[RA, RB; μ]) * t + Var[RB; μ] := by
    intro t
    have := two_asset_var_lin RA RB hA hB t (-1)
    have h0 := variance_nonneg (fun ω => t * RA ω + (-1) * RB ω) μ
    nlinarith
  have := discrim_le_zero h
  rw [discrim] at this
  nlinarith

/-- The covariance is at most the product of the spreads. -/
lemma two_asset_cov_le_sqrt_mul
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (RA RB : Ω → ℝ) (hA : MemLp RA 2 μ) (hB : MemLp RB 2 μ) :
    cov[RA, RB; μ] ≤ √(Var[RA; μ]) * √(Var[RB; μ]) := by
  rw [← Real.sqrt_mul (variance_nonneg _ _)]
  calc cov[RA, RB; μ] ≤ |cov[RA, RB; μ]| := le_abs_self _
    _ = √(cov[RA, RB; μ] ^ 2) := (Real.sqrt_sq_eq_abs _).symm
    _ ≤ _ := Real.sqrt_le_sqrt (two_asset_cov_sq_le RA RB hA hB)

/-- **Mean adds, variance does not.** Take two random returns `R_A` and `R_B` on one
probability space, each with a finite variance, and put a fraction `w` of the money in the
first and `1 - w` in the second (any real `w`, short sales allowed). The mix's return
`w R_A + (1 - w) R_B` has expected return `w μ_A + (1 - w) μ_B`, and variance
`w² σ_A² + (1 - w)² σ_B² + 2 w (1 - w) c`, where `c` is the covariance of the two returns. -/
theorem two_asset_mean_adds_variance_has_cross_term
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (RA RB : Ω → ℝ) (hA : MemLp RA 2 μ) (hB : MemLp RB 2 μ) (w : ℝ) :
    μ[fun ω => w * RA ω + (1 - w) * RB ω] = w * μ[RA] + (1 - w) * μ[RB] ∧
    Var[fun ω => w * RA ω + (1 - w) * RB ω; μ]
      = w ^ 2 * Var[RA; μ] + (1 - w) ^ 2 * Var[RB; μ] + 2 * w * (1 - w) * cov[RA, RB; μ] := by
  constructor
  · rw [integral_add (hA.integrable one_le_two |>.const_mul w)
      (hB.integrable one_le_two |>.const_mul (1 - w)), integral_const_mul, integral_const_mul]
  · exact two_asset_var_lin RA RB hA hB w (1 - w)

/-- **Diversification.** For weights between 0 and 1, the spread (standard deviation) of the
mix is never more than the weighted average of the two spreads,
`σ_p ≤ w σ_A + (1 - w) σ_B`; and it is strictly less whenever both weights are positive and
the correlation is below 1, that is, whenever the covariance is below `σ_A σ_B`. -/
theorem two_asset_spread_le_weighted_average_of_spreads
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (RA RB : Ω → ℝ) (hA : MemLp RA 2 μ) (hB : MemLp RB 2 μ) (w : ℝ)
    (hw0 : 0 ≤ w) (hw1 : w ≤ 1) :
    √(Var[fun ω => w * RA ω + (1 - w) * RB ω; μ])
        ≤ w * √(Var[RA; μ]) + (1 - w) * √(Var[RB; μ]) ∧
    (0 < w → w < 1 → cov[RA, RB; μ] < √(Var[RA; μ]) * √(Var[RB; μ]) →
      √(Var[fun ω => w * RA ω + (1 - w) * RB ω; μ])
        < w * √(Var[RA; μ]) + (1 - w) * √(Var[RB; μ])) := by
  have hV := two_asset_var_lin RA RB hA hB w (1 - w)
  have hc := two_asset_cov_le_sqrt_mul RA RB hA hB
  have ha := Real.sq_sqrt (variance_nonneg RA μ)
  have hb := Real.sq_sqrt (variance_nonneg RB μ)
  have sa := Real.sqrt_nonneg (Var[RA; μ])
  have sb := Real.sqrt_nonneg (Var[RB; μ])
  have hR : 0 ≤ w * √(Var[RA; μ]) + (1 - w) * √(Var[RB; μ]) := by
    have : 0 ≤ 1 - w := by linarith
    positivity
  have key : Var[fun ω => w * RA ω + (1 - w) * RB ω; μ]
      = (w * √(Var[RA; μ]) + (1 - w) * √(Var[RB; μ])) ^ 2
        - 2 * w * (1 - w) * (√(Var[RA; μ]) * √(Var[RB; μ]) - cov[RA, RB; μ]) := by
    rw [hV]; nlinarith [ha, hb]
  constructor
  · rw [← Real.sqrt_sq hR]
    apply Real.sqrt_le_sqrt
    have : 0 ≤ w * (1 - w) := mul_nonneg hw0 (by linarith)
    nlinarith
  · intro h0 h1 hlt
    rw [← Real.sqrt_sq hR]
    apply Real.sqrt_lt_sqrt (variance_nonneg _ _)
    have : 0 < w * (1 - w) := mul_pos h0 (by linarith)
    nlinarith

/-- **The least-risk mix.** Let `d = σ_A² + σ_B² - 2c` be the variance of the gap between the
two returns. When `d > 0`, the weight `w* = (σ_B² - c) / d` gives the mix the smallest
variance of all real weights, and every other weight gives a strictly larger variance. -/
theorem two_asset_least_risk_weight
    {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    (RA RB : Ω → ℝ) (hA : MemLp RA 2 μ) (hB : MemLp RB 2 μ)
    (hd : 0 < Var[RA; μ] + Var[RB; μ] - 2 * cov[RA, RB; μ]) :
    let wstar := (Var[RB; μ] - cov[RA, RB; μ]) / (Var[RA; μ] + Var[RB; μ] - 2 * cov[RA, RB; μ])
    ∀ w : ℝ, w ≠ wstar →
      Var[fun ω => wstar * RA ω + (1 - wstar) * RB ω; μ]
        < Var[fun ω => w * RA ω + (1 - w) * RB ω; μ] := by
  intro wstar w hw
  have hd' : (Var[RA; μ] + Var[RB; μ] - 2 * cov[RA, RB; μ]) ≠ 0 := ne_of_gt hd
  have hws : (Var[RA; μ] + Var[RB; μ] - 2 * cov[RA, RB; μ]) * wstar
      = Var[RB; μ] - cov[RA, RB; μ] := by
    simp only [wstar]; field_simp
  clear_value wstar
  rw [two_asset_var_lin RA RB hA hB, two_asset_var_lin RA RB hA hB]
  have hdiff : w ^ 2 * Var[RA; μ] + (1 - w) ^ 2 * Var[RB; μ] + 2 * w * (1 - w) * cov[RA, RB; μ]
      - (wstar ^ 2 * Var[RA; μ] + (1 - wstar) ^ 2 * Var[RB; μ]
        + 2 * wstar * (1 - wstar) * cov[RA, RB; μ])
      = (Var[RA; μ] + Var[RB; μ] - 2 * cov[RA, RB; μ]) * (w - wstar) ^ 2 := by
    linear_combination 2 * (w - wstar) * hws
  have hpos : 0 < (w - wstar) ^ 2 := by
    have : w - wstar ≠ 0 := sub_ne_zero.mpr hw
    positivity
  nlinarith [mul_pos hd hpos]

/-! ### The card's worked numbers, exactly (percentages written as fractions) -/

-- 60-40 mean: 0.6 × 8% + 0.4 × 4% = 6.40%.
example : (3 / 5 : ℚ) * (8 / 100) + (2 / 5) * (4 / 100) = 64 / 1000 := by norm_num

-- Covariance c = 0.2 × 0.20 × 0.06 = 0.0024.
example : (2 / 10 : ℚ) * (20 / 100) * (6 / 100) = 24 / 10000 := by norm_num

-- 60-40 variance: 0.0144 + 0.000576 + 0.001152 = 0.016128.
example : (3 / 5 : ℚ) ^ 2 * (20 / 100) ^ 2 + (2 / 5) ^ 2 * (6 / 100) ^ 2
    + 2 * (3 / 5) * (2 / 5) * (24 / 10000) = 16128 / 1000000 := by norm_num

-- Weighted average of spreads: 0.6 × 20% + 0.4 × 6% = 14.40%.
example : (3 / 5 : ℚ) * (20 / 100) + (2 / 5) * (6 / 100) = 144 / 1000 := by norm_num

-- Ledger in dollars: $600 and $400 after each outcome, and the four totals.
example : (600 : ℕ) * 128 / 100 = 768 ∧ 600 * 88 / 100 = 528 ∧
    400 * 110 / 100 = 440 ∧ 400 * 98 / 100 = 392 := by decide
example : (768 + 440 : ℕ) = 1208 ∧ 768 + 392 = 1160 ∧ 528 + 440 = 968 ∧ 528 + 392 = 920 := by
  decide

-- Ledger mean 6.40% and ledger variance 0.016128, from the four outcomes.
example : (3 / 10 : ℚ) * (208 / 1000) + (2 / 10) * (160 / 1000) + (2 / 10) * (-32 / 1000)
    + (3 / 10) * (-80 / 1000) = 64 / 1000 := by norm_num
example : (3 / 10 : ℚ) * (208 / 1000 - 64 / 1000) ^ 2 + (2 / 10) * (160 / 1000 - 64 / 1000) ^ 2
    + (2 / 10) * (-32 / 1000 - 64 / 1000) ^ 2 + (3 / 10) * (-80 / 1000 - 64 / 1000) ^ 2
    = 16128 / 1000000 := by norm_num

-- d = 0.04 + 0.0036 - 2 × 0.0024 = 0.0388, and w* = (0.0036 - 0.0024) / 0.0388 = 3/97.
example : (4 / 100 : ℚ) + 36 / 10000 - 2 * (24 / 10000) = 388 / 10000 := by norm_num
example : ((36 / 10000 : ℚ) - 24 / 10000) / (388 / 10000) = 3 / 97 := by norm_num

-- Variance check: V(w*) + d (0.6 - w*)² = V(0.6) = 0.016128.
example : (3 / 97 : ℚ) ^ 2 * (4 / 100) + (1 - 3 / 97) ^ 2 * (36 / 10000)
    + 2 * (3 / 97) * (1 - 3 / 97) * (24 / 10000)
    + (388 / 10000) * (3 / 5 - 3 / 97) ^ 2 = 16128 / 1000000 := by norm_num

-- Correlation -1: zero-risk weight 6 / 26 = 3/13, with mean 16/325 (about 4.92%) and no variance.
example : (6 : ℚ) / (20 + 6) = 3 / 13 := by norm_num
example : (3 / 13 : ℚ) * (8 / 100) + (10 / 13) * (4 / 100) = 16 / 325 := by norm_num
example : ((3 / 13 : ℚ) * (20 / 100) - (10 / 13) * (6 / 100)) ^ 2 = 0 := by norm_num

#print axioms two_asset_var_lin
#print axioms two_asset_cov_sq_le
#print axioms two_asset_cov_le_sqrt_mul
#print axioms two_asset_mean_adds_variance_has_cross_term
#print axioms two_asset_spread_le_weighted_average_of_spreads
#print axioms two_asset_least_risk_weight
