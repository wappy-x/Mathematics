-- Hierarchical models: given the spread, a group's normal-normal estimate keeps the share τ²/(σ²+τ²) of its gap from the mean, the marginal likelihood peaks at the moment estimate V = S/(k−1), and the James-Stein share (k−3)σ²/S is an unbiased estimate of the pulled share B.
import Mathlib.Probability.Distributions.Gamma
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open MeasureTheory ProbabilityTheory Real

/-- The shrink formula given the spread (Step 1). Fix the common mean μ, the between-group
variance τ² > 0 and the known sampling variance σ² > 0, and let B = σ²/(σ² + τ²) be the
pulled share. The normal-normal posterior for a group with measured value y is the
precision-weighted average of the reading y (precision 1/σ²) and the prior centre μ
(precision 1/τ²), with variance one over the total precision. That centre is
μ + (1 − B)(y − μ): start at the common mean and keep the share 1 − B of the gap. Its
variance is (1 − B)σ², below the raw σ². -/
theorem shrink_formula_given_spread (μ y σ2 τ2 : ℝ) (hσ : 0 < σ2) (hτ : 0 < τ2) :
    let B := σ2 / (σ2 + τ2)
    (y / σ2 + μ / τ2) / (1 / σ2 + 1 / τ2) = μ + (1 - B) * (y - μ) ∧
      1 / (1 / σ2 + 1 / τ2) = (1 - B) * σ2 := by
  intro B
  have h1 : σ2 + τ2 ≠ 0 := by positivity
  simp only [B]
  constructor
  · field_simp
    ring
  · field_simp
    ring

/-- The moment estimate is the peak of the marginal likelihood (Step 2). With k ≥ 2 groups
and sum of squared gaps S > 0, the marginal likelihood of the total variance V = σ² + τ²,
up to a constant, is V^(−(k−1)/2) · exp(−S/(2V)) on V > 0. Its one and only peak is at
V = S/(k − 1): every other V > 0 gives a strictly smaller value. So the empirical-Bayes
between-group variance is S/(k − 1) − σ². -/
theorem marginal_likelihood_peak_at_moment_estimate (k : ℕ) (hk : 2 ≤ k) (S : ℝ) (hS : 0 < S) :
    let L : ℝ → ℝ := fun V => V ^ (-(((k : ℝ) - 1) / 2)) * exp (-(S / (2 * V)))
    0 < S / ((k : ℝ) - 1) ∧
      ∀ V : ℝ, 0 < V → V ≠ S / ((k : ℝ) - 1) → L V < L (S / ((k : ℝ) - 1)) := by
  intro L
  have hk' : (2 : ℝ) ≤ k := by exact_mod_cast hk
  have hm : 0 < (k : ℝ) - 1 := by linarith
  set m : ℝ := (k : ℝ) - 1 with hm_def
  have hV0 : 0 < S / m := div_pos hS hm
  refine ⟨hV0, ?_⟩
  intro V hV hne
  simp only [L]
  rw [rpow_def_of_pos hV, rpow_def_of_pos hV0, ← exp_add, ← exp_add, exp_lt_exp]
  have ht : 0 < S / m / V := div_pos hV0 hV
  have ht1 : S / m / V ≠ 1 := by
    intro h
    apply hne
    rw [div_eq_one_iff_eq hV.ne'] at h
    exact h.symm
  have hlog := log_lt_sub_one_of_pos ht ht1
  rw [log_div hV0.ne' hV.ne'] at hlog
  have key : S / (2 * (S / m)) = m / 2 := by field_simp
  rw [key]
  have e : S / m / V = (S / (2 * V)) * (2 / m) := by field_simp
  rw [e] at hlog
  have hmul := mul_lt_mul_of_pos_left hlog (by positivity : (0:ℝ) < m / 2)
  have e2 : m / 2 * (S / (2 * V) * (2 / m) - 1) = S / (2 * V) - m / 2 := by
    field_simp
  rw [e2] at hmul
  nlinarith [hmul]

/-- James-Stein is empirical Bayes with an unbiased pull (Step 3). Under the model,
S/(σ² + τ²) is a chi-square with k − 1 degrees of freedom, the gamma law with shape
(k − 1)/2 and rate 1/2; write S = (σ² + τ²)·X. With at least four groups, the average of
the James-Stein share (k − 3)σ²/S equals the pulled share B = σ²/(σ² + τ²) exactly. -/
theorem james_stein_share_unbiased (k : ℕ) (hk : 4 ≤ k) (σ2 τ2 : ℝ) (hσ : 0 < σ2)
    (hτ : 0 ≤ τ2) :
    ∫ x, ((k : ℝ) - 3) * σ2 / ((σ2 + τ2) * x) ∂(gammaMeasure (((k : ℝ) - 1) / 2) (1 / 2)) =
      σ2 / (σ2 + τ2) := by
  have hk' : (4 : ℝ) ≤ k := by exact_mod_cast hk
  set a : ℝ := ((k : ℝ) - 1) / 2 with ha_def
  have ha1 : 0 < a - 1 := by rw [ha_def]; linarith
  have ha : 0 < a := by linarith
  have hC : 0 < σ2 + τ2 := by linarith
  have hr : (0 : ℝ) < 1 / 2 := by norm_num
  set c : ℝ := ((k : ℝ) - 3) * σ2 with hc
  set C : ℝ := σ2 + τ2 with hC_def
  rw [gammaMeasure, integral_withDensity_eq_integral_toReal_smul
    (f := gammaPDF a (1/2)) (measurable_gammaPDFReal a _).ennreal_ofReal
    (ae_of_all _ fun _ => ENNReal.ofReal_lt_top)]
  have hfun : (fun x : ℝ => (gammaPDF a (1/2) x).toReal • (c / (C * x))) =
      fun x => gammaPDFReal a (1/2) x * (c / (C * x)) := by
    funext x
    rw [gammaPDF, ENNReal.toReal_ofReal (gammaPDFReal_nonneg ha hr x), smul_eq_mul]
  rw [hfun, ← setIntegral_eq_integral_of_forall_compl_eq_zero (s := Set.Ioi 0)]
  swap
  · intro x hx
    simp only [Set.mem_Ioi, not_lt] at hx
    rcases hx.lt_or_eq with h | h
    · simp [gammaPDFReal, not_le.mpr h]
    · simp [h]
  have hcongr : Set.EqOn (fun x : ℝ => gammaPDFReal a (1/2) x * (c / (C * x)))
      (fun x => ((1/2 : ℝ) ^ a / Gamma a * (c / C)) * (x ^ ((a - 1) - 1) * exp (-((1/2) * x))))
      (Set.Ioi 0) := by
    intro x hx
    simp only [Set.mem_Ioi] at hx
    simp only [gammaPDFReal, hx.le, ↓reduceIte]
    rw [rpow_sub_one hx.ne' (a - 1)]
    field_simp
  rw [setIntegral_congr_fun measurableSet_Ioi hcongr, integral_const_mul,
    integral_rpow_mul_exp_neg_mul_Ioi ha1 hr]
  have hG : Gamma a = (a - 1) * Gamma (a - 1) := by
    have := Gamma_add_one ha1.ne'
    rw [sub_add_cancel] at this
    exact this
  have hGp : 0 < Gamma (a - 1) := Gamma_pos_of_pos ha1
  have hpow : (1/2 : ℝ) ^ a * (1 / (1/2)) ^ (a - 1) = 1 / 2 := by
    rw [rpow_sub (by norm_num : (0:ℝ) < 1 / (1/2)), rpow_one, ← mul_div_assoc, ← mul_rpow (by norm_num) (by norm_num)]
    norm_num
  have hca : c = 2 * (a - 1) * σ2 := by rw [hc, ha_def]; ring
  rw [hG, hca]
  calc (1 / 2 : ℝ) ^ a / ((a - 1) * Gamma (a - 1)) * (2 * (a - 1) * σ2 / C) *
        ((1 / (1 / 2)) ^ (a - 1) * Gamma (a - 1))
      = ((1/2 : ℝ) ^ a * (1 / (1/2)) ^ (a - 1)) * 2 * σ2 / C := by
        field_simp
    _ = σ2 / C := by rw [hpow]; field_simp

/-! The card's worked numbers, with rates in thousandths (0.10 is 100) and variances in
millionths (0.0004 is 400), so every number is exact. -/

-- The average of the five rates is 0.12.
example : ((100 + 140 + 80 + 120 + 160 : ℚ) / 5) = 120 := by norm_num

-- The sum of squared gaps S is 0.004.
example : ((100 - 120) ^ 2 + (140 - 120) ^ 2 + (80 - 120) ^ 2 + (120 - 120) ^ 2
    + (160 - 120) ^ 2 : ℚ) = 4000 := by norm_num

-- Observed spread 0.001, between-shop variance 0.0006, pulled share 0.4, kept share 0.6.
example : (4000 : ℚ) / (5 - 1) = 1000 ∧ (1000 : ℚ) - 400 = 600 ∧
    (400 : ℚ) / (400 + 600) = 2 / 5 ∧ 1 - (2 : ℚ) / 5 = 3 / 5 := by norm_num

-- The five empirical-Bayes estimates 0.108, 0.132, 0.096, 0.12, 0.144.
example : ((120 : ℚ) + 3 / 5 * (100 - 120) = 108) ∧ ((120 : ℚ) + 3 / 5 * (140 - 120) = 132) ∧
    ((120 : ℚ) + 3 / 5 * (80 - 120) = 96) ∧ ((120 : ℚ) + 3 / 5 * (120 - 120) = 120) ∧
    ((120 : ℚ) + 3 / 5 * (160 - 120) = 144) := by norm_num

-- James-Stein keeps 1 − 2 × 0.0004/0.004 = 0.8 and moves shop 5 to 0.152.
example : (1 : ℚ) - (5 - 3) * 400 / 4000 = 4 / 5 ∧ (120 : ℚ) + 4 / 5 * (160 - 120) = 152 := by
  norm_num

-- What breaks: using the observed spread 0.001 as τ² keeps 0.001/0.0014 = 5/7 (0.7143);
-- dividing S by k gives τ² = 0.0004 and kept share 0.5, shop 5 at 0.140.
example : (1000 : ℚ) / (1000 + 400) = 5 / 7 ∧ (4000 : ℚ) / 5 - 400 = 400 ∧
    (400 : ℚ) / (400 + 400) = 1 / 2 ∧ (120 : ℚ) + 1 / 2 * (160 - 120) = 140 := by norm_num

#print axioms shrink_formula_given_spread
#print axioms marginal_likelihood_peak_at_moment_estimate
#print axioms james_stein_share_unbiased
