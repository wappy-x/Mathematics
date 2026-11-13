-- Gamma-Poisson: a Gamma(α, β) prior on a rate, updated with Poisson counts y_i over t_i hours, becomes Gamma(α + Σ y_i, β + Σ t_i), and averaging a Poisson count over a Gamma(A, B) rate gives the negative binomial law with chance p = B/(B + t), mean tA/B and variance tA/B + t²A/B².
import Mathlib.Probability.Distributions.Gamma
import Mathlib.Probability.Distributions.Poisson.Basic
import Mathlib.Analysis.Analytic.Binomial
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory
open scoped NNReal

lemma gp_integral_gammaPDFReal {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    ∫ x, gammaPDFReal a r x = 1 := by
  rw [integral_eq_lintegral_of_nonneg_ae (ae_of_all _ (gammaPDFReal_nonneg ha hr))
    (measurable_gammaPDFReal a r).aestronglyMeasurable]
  have : (fun x => ENNReal.ofReal (gammaPDFReal a r x)) = gammaPDF a r := rfl
  rw [this, lintegral_gammaPDF_eq_one ha hr, ENNReal.toReal_one]

#print axioms gp_integral_gammaPDFReal

lemma gp_rpow_mul {x : ℝ} (hx : 0 ≤ x) {a : ℝ} (ha : 0 < a) (n : ℕ) :
    x ^ n * x ^ (a - 1) = x ^ (a + (n : ℝ) - 1) := by
  rcases hx.eq_or_lt with h | h
  · subst h
    cases n with
    | zero => simp
    | succ n =>
      rw [zero_pow (Nat.succ_ne_zero n), zero_mul, Real.zero_rpow]
      apply ne_of_gt
      have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
      push_cast
      linarith
  · rw [← Real.rpow_natCast, ← Real.rpow_add h]; ring_nf

#print axioms gp_rpow_mul

lemma gp_prod_poisson {m : ℕ} (t : Fin m → ℝ≥0) (y : Fin m → ℕ) {x : ℝ} (hx : 0 ≤ x) :
    (∏ i, (poissonMeasure (t i * x.toNNReal)).real {y i}) =
      (∏ i, ((t i : ℝ) ^ (y i) / (y i).factorial)) * x ^ (∑ i, y i) *
        Real.exp (-((∑ i, (t i : ℝ)) * x)) := by
  simp_rw [poissonMeasure_real_singleton, NNReal.coe_mul, Real.coe_toNNReal _ hx]
  have : ∀ i, Real.exp (-((t i : ℝ) * x)) * ((t i : ℝ) * x) ^ (y i) / ((y i).factorial : ℝ) =
      ((t i : ℝ) ^ (y i) / (y i).factorial) * x ^ (y i) * Real.exp (-((t i : ℝ) * x)) :=
    fun i => by ring
  simp_rw [this, Finset.prod_mul_distrib, Finset.prod_pow_eq_pow_sum, ← Real.exp_sum,
    Finset.sum_neg_distrib, Finset.sum_mul]

#print axioms gp_prod_poisson

lemma gp_pointwise (α β : ℝ) (hα : 0 < α) (hβ : 0 < β)
    (m : ℕ) (t : Fin m → ℝ≥0) (y : Fin m → ℕ) (x : ℝ) :
    (∏ i, (poissonMeasure (t i * x.toNNReal)).real {y i}) * gammaPDFReal α β x =
      (∏ i, ((t i : ℝ) ^ (y i) / (y i).factorial)) * β ^ α *
            Real.Gamma (α + ∑ i, (y i : ℝ)) /
          (Real.Gamma α * (β + ∑ i, (t i : ℝ)) ^ (α + ∑ i, (y i : ℝ))) *
        gammaPDFReal (α + ∑ i, (y i : ℝ)) (β + ∑ i, (t i : ℝ)) x := by
  rcases lt_or_ge x 0 with hx | hx
  · simp [gammaPDFReal, not_le.mpr hx]
  have hH : 0 ≤ ∑ i, (t i : ℝ) := Finset.sum_nonneg (fun i _ => (t i).2)
  have hK : 0 ≤ ∑ i, (y i : ℝ) := Finset.sum_nonneg (fun i _ => Nat.cast_nonneg _)
  have hG1 := Real.Gamma_pos_of_pos hα
  have hG2 := Real.Gamma_pos_of_pos (show 0 < α + ∑ i, (y i : ℝ) by linarith)
  have hP := Real.rpow_pos_of_pos (show 0 < β + ∑ i, (t i : ℝ) by linarith) (α + ∑ i, (y i : ℝ))
  rw [gp_prod_poisson t y hx]
  simp only [gammaPDFReal, hx, ↓reduceIte]
  have hpow := gp_rpow_mul hx hα (∑ i, y i)
  push_cast at hpow
  rw [← hpow]
  have hexp : Real.exp (-((β + ∑ i, (t i : ℝ)) * x)) =
      Real.exp (-((∑ i, (t i : ℝ)) * x)) * Real.exp (-(β * x)) := by
    rw [← Real.exp_add]; ring_nf
  rw [hexp]
  field_simp

#print axioms gp_pointwise

lemma gp_coeff (a : ℝ) (ha : 0 < a) (n : ℕ) :
    Ring.choose (a + n - 1) n = Real.Gamma (a + n) / (Real.Gamma a * n.factorial) := by
  have h1 : (ascPochhammer ℝ n).eval a * Real.Gamma a = Real.Gamma (a + n) := by
    induction n with
    | zero => simp
    | succ n ih =>
      rw [ascPochhammer_succ_eval, mul_right_comm, ih]
      push_cast
      rw [← add_assoc, Real.Gamma_add_one (by positivity), mul_comm]
  rw [← Ring.multichoose_eq]
  have h2 := Ring.factorial_nsmul_multichoose_eq_ascPochhammer a n
  rw [Polynomial.ascPochhammer_smeval_eq_eval, nsmul_eq_mul] at h2
  have hG := Real.Gamma_pos_of_pos ha
  rw [← h1, ← h2]
  field_simp

#print axioms gp_coeff

lemma gp_series (a : ℝ) (ha : 0 < a) (z : ℝ) (hz0 : 0 ≤ z) (hz1 : z < 1) :
    HasSum (fun n : ℕ => Real.Gamma (a + n) / (Real.Gamma a * n.factorial) * z ^ n)
      (1 / (1 - z) ^ a) := by
  have hz : z ∈ Metric.eball (0 : ℝ) 1 := by
    rw [Metric.mem_eball, edist_zero_right]
    have : ‖z‖₊ < 1 := by
      rw [← NNReal.coe_lt_coe]; simpa [abs_of_nonneg hz0] using hz1
    simpa [enorm_eq_nnnorm] using this
  have h := (Real.one_div_one_sub_rpow_hasFPowerSeriesOnBall_zero a).hasSum hz
  simp only [FormalMultilinearSeries.ofScalars_apply_eq, zero_add, smul_eq_mul] at h
  simpa only [gp_coeff a ha] using h

#print axioms gp_series

lemma gp_coeff_shift (a : ℝ) (ha : 0 < a) (k : ℕ) :
    ((k + 1 : ℕ) : ℝ) * (Real.Gamma (a + (k + 1 : ℕ)) / (Real.Gamma a * (k + 1).factorial)) =
      a * (Real.Gamma ((a + 1) + k) / (Real.Gamma (a + 1) * k.factorial)) := by
  have hG := Real.Gamma_pos_of_pos ha
  rw [Real.Gamma_add_one ha.ne', Nat.factorial_succ]
  push_cast
  rw [show a + (k + 1) = a + 1 + k by ring]
  have : (0 : ℝ) < k.factorial := by positivity
  field_simp

#print axioms gp_coeff_shift

lemma gp_series_mean (a : ℝ) (ha : 0 < a) (z : ℝ) (hz0 : 0 ≤ z) (hz1 : z < 1) :
    HasSum (fun n : ℕ => (n : ℝ) * (Real.Gamma (a + n) / (Real.Gamma a * n.factorial) * z ^ n))
      (a * z * (1 / (1 - z) ^ (a + 1))) := by
  have h := (gp_series (a + 1) (by linarith) z hz0 hz1).mul_left (a * z)
  refine (hasSum_nat_add_iff' 1).mp ?_
  · convert h using 1
    · funext j
      rw [pow_succ, ← mul_assoc, ← mul_assoc, gp_coeff_shift a ha j]
      ring
    · simp

#print axioms gp_series_mean

lemma gp_series_fact2 (a : ℝ) (ha : 0 < a) (z : ℝ) (hz0 : 0 ≤ z) (hz1 : z < 1) :
    HasSum (fun n : ℕ => (n : ℝ) * ((n : ℝ) - 1) *
        (Real.Gamma (a + n) / (Real.Gamma a * n.factorial) * z ^ n))
      (a * z * ((a + 1) * z * (1 / (1 - z) ^ (a + 1 + 1)))) := by
  have h := (gp_series_mean (a + 1) (by linarith) z hz0 hz1).mul_left (a * z)
  refine (hasSum_nat_add_iff' 1).mp ?_
  · convert h using 1
    · funext j
      rw [pow_succ]
      have := gp_coeff_shift a ha j
      push_cast at this ⊢
      rw [show (j : ℝ) + 1 - 1 = j by ring]
      linear_combination (j : ℝ) * z ^ j * z * this
    · simp

#print axioms gp_series_fact2

/-- The conjugate update. Take a gamma prior Gamma(α, β) on the rate λ, with α > 0 and β > 0
(β a rate, not a scale), and a record of m windows: window i lasts t_i ≥ 0 hours and brings
y_i emails, with no email in a window of zero length. Given λ the counts are independent Poisson
counts with means t_i λ, so the likelihood is the product of the Poisson masses. Writing
K = Σ y_i and H = Σ t_i, the evidence (the integral of prior times likelihood) is
C β^α Γ(α + K) / (Γ(α) (β + H)^(α + K)) with C = Π t_i^(y_i) / y_i!, and Bayes' rule (prior times
likelihood, divided by the evidence) gives exactly the Gamma(α + K, β + H) density at every λ. -/
theorem gamma_poisson_conjugate_update (α β : ℝ) (hα : 0 < α) (hβ : 0 < β)
    (m : ℕ) (t : Fin m → ℝ≥0) (y : Fin m → ℕ) (hzero : ∀ i, t i = 0 → y i = 0) :
    (∫ x, (∏ i, (poissonMeasure (t i * x.toNNReal)).real {y i}) * gammaPDFReal α β x) =
        (∏ i, ((t i : ℝ) ^ (y i) / (y i).factorial)) * β ^ α *
            Real.Gamma (α + ∑ i, (y i : ℝ)) /
          (Real.Gamma α * (β + ∑ i, (t i : ℝ)) ^ (α + ∑ i, (y i : ℝ))) ∧
      ∀ lam : ℝ,
        (∏ i, (poissonMeasure (t i * lam.toNNReal)).real {y i}) * gammaPDFReal α β lam /
            (∫ x, (∏ i, (poissonMeasure (t i * x.toNNReal)).real {y i}) * gammaPDFReal α β x) =
          gammaPDFReal (α + ∑ i, (y i : ℝ)) (β + ∑ i, (t i : ℝ)) lam := by
  have hH : 0 ≤ ∑ i, (t i : ℝ) := Finset.sum_nonneg (fun i _ => (t i).2)
  have hK : 0 ≤ ∑ i, (y i : ℝ) := Finset.sum_nonneg (fun i _ => Nat.cast_nonneg _)
  have hint : (∫ x, (∏ i, (poissonMeasure (t i * x.toNNReal)).real {y i}) * gammaPDFReal α β x) =
      (∏ i, ((t i : ℝ) ^ (y i) / (y i).factorial)) * β ^ α *
            Real.Gamma (α + ∑ i, (y i : ℝ)) /
          (Real.Gamma α * (β + ∑ i, (t i : ℝ)) ^ (α + ∑ i, (y i : ℝ))) := by
    simp_rw [gp_pointwise α β hα hβ m t y]
    rw [integral_const_mul, gp_integral_gammaPDFReal (by linarith) (by linarith), mul_one]
  refine ⟨hint, fun lam => ?_⟩
  have hC : (∏ i, ((t i : ℝ) ^ (y i) / (y i).factorial)) ≠ 0 := by
    rw [Finset.prod_ne_zero_iff]
    intro i _
    apply div_ne_zero _ (by positivity)
    by_cases h : t i = 0
    · rw [hzero i h, pow_zero]; exact one_ne_zero
    · exact pow_ne_zero _ (by exact_mod_cast h)
  have hG1 := Real.Gamma_pos_of_pos hα
  have hG2 := Real.Gamma_pos_of_pos (show 0 < α + ∑ i, (y i : ℝ) by linarith)
  have hP := Real.rpow_pos_of_pos (show 0 < β + ∑ i, (t i : ℝ) by linarith) (α + ∑ i, (y i : ℝ))
  have hb := Real.rpow_pos_of_pos hβ α
  rw [hint, gp_pointwise α β hα hβ m t y lam, mul_div_cancel_left₀]
  exact div_ne_zero (mul_ne_zero (mul_ne_zero hC hb.ne') hG2.ne') (mul_pos hG1 hP).ne'

/-- The forecast is negative binomial. If the rate λ has the law Gamma(A, B), with A > 0 and
B > 0, and given λ the count N in a new window of t > 0 hours is Poisson with mean tλ, then the
chance that N = k, the Poisson mass averaged over the gamma density, is
Γ(A + k) / (Γ(A) k!) · p^A (1 - p)^k with p = B/(B + t), for every k = 0, 1, 2, .... -/
theorem gamma_poisson_forecast_negative_binomial (A B : ℝ) (hA : 0 < A) (hB : 0 < B)
    (t : ℝ≥0) (ht : 0 < t) (k : ℕ) :
    ∫ x, (poissonMeasure (t * x.toNNReal)).real {k} * gammaPDFReal A B x =
      Real.Gamma (A + k) / (Real.Gamma A * k.factorial) *
        (B / (B + t)) ^ A * (1 - B / (B + t)) ^ k := by
  have h := (gamma_poisson_conjugate_update A B hA hB 1 (fun _ => t) (fun _ => k) (fun _ h => absurd h ht.ne')).1
  simp only [Finset.univ_unique, Finset.prod_singleton, Finset.sum_singleton] at h
  rw [h]
  have ht' : (0 : ℝ) < t := ht
  have hBt : 0 < B + t := by linarith
  have hG1 := Real.Gamma_pos_of_pos hA
  rw [Real.div_rpow hB.le hBt.le, Real.rpow_add_natCast hBt.ne',
    show 1 - B / (B + t) = (t : ℝ) / (B + t) by field_simp; ring, div_pow]
  have : (0 : ℝ) < k.factorial := by positivity
  have := Real.rpow_pos_of_pos hBt A
  field_simp

/-- The forecast's total, mean and variance. With A > 0, B > 0, t > 0 and p = B/(B + t), the
negative binomial masses q_k = Γ(A + k) / (Γ(A) k!) · p^A (1 - p)^k add to 1, their mean is
tA/B, and their variance is tA/B + t²A/B²: the Poisson's own scatter tA/B plus the leftover
doubt about the rate, so the forecast is wider than a Poisson with the same mean. -/
theorem gamma_poisson_forecast_mean_variance (A B : ℝ) (hA : 0 < A) (hB : 0 < B)
    (t : ℝ) (ht : 0 < t) :
    let q : ℕ → ℝ := fun k => Real.Gamma (A + k) / (Real.Gamma A * k.factorial) *
        (B / (B + t)) ^ A * (1 - B / (B + t)) ^ k
    HasSum q 1 ∧ HasSum (fun k : ℕ => (k : ℝ) * q k) (t * A / B) ∧
      HasSum (fun k : ℕ => ((k : ℝ) - t * A / B) ^ 2 * q k) (t * A / B + t ^ 2 * A / B ^ 2) := by
  intro q
  have hBt : 0 < B + t := by linarith
  set p := B / (B + t) with hp_def
  have hp : 0 < p := by positivity
  have hz : 1 - p = t / (B + t) := by rw [hp_def]; field_simp; ring
  have hz0 : 0 ≤ 1 - p := by rw [hz]; positivity
  have hz1 : 1 - p < 1 := by linarith
  have h1p : 1 - (1 - p) = p := by ring
  have hpA : 0 < p ^ A := Real.rpow_pos_of_pos hp A
  have hq : ∀ k : ℕ, q k = p ^ A * (Real.Gamma (A + k) / (Real.Gamma A * k.factorial) *
      (1 - p) ^ k) := fun k => by simp only [q]; ring
  have S0 := (gp_series A hA (1 - p) hz0 hz1).mul_left (p ^ A)
  have S1 := (gp_series_mean A hA (1 - p) hz0 hz1).mul_left (p ^ A)
  have S2 := (gp_series_fact2 A hA (1 - p) hz0 hz1).mul_left (p ^ A)
  rw [h1p] at S0 S1 S2
  rw [Real.rpow_add_one hp.ne'] at S1
  rw [Real.rpow_add_one hp.ne', Real.rpow_add_one hp.ne'] at S2
  have e0 : p ^ A * (1 / p ^ A) = 1 := by field_simp
  have e1 : p ^ A * (A * (1 - p) * (1 / (p ^ A * p))) = t * A / B := by
    rw [hz, hp_def]; field_simp
  have e2 : p ^ A * (A * (1 - p) * ((A + 1) * (1 - p) * (1 / (p ^ A * p * p)))) =
      t ^ 2 * A * (A + 1) / B ^ 2 := by
    rw [hz, hp_def]; field_simp
  rw [e0] at S0
  rw [e1] at S1
  rw [e2] at S2
  have Q0 : HasSum q 1 := by
    convert S0 using 1; funext k; exact hq k
  have Q1 : HasSum (fun k : ℕ => (k : ℝ) * q k) (t * A / B) := by
    convert S1 using 1; funext k; rw [hq]; ring
  have Q2 : HasSum (fun k : ℕ => (k : ℝ) * ((k : ℝ) - 1) * q k) (t ^ 2 * A * (A + 1) / B ^ 2) := by
    convert S2 using 1; funext k; rw [hq]; ring
  refine ⟨Q0, Q1, ?_⟩
  have := (Q2.add (Q1.mul_left (1 - 2 * (t * A / B)))).add (Q0.mul_left ((t * A / B) ^ 2))
  convert this using 1
  · funext k; ring
  · field_simp; ring

/-! The card's worked numbers, as exact whole numbers and fractions. -/

-- Record: 28 emails in 2 hours, then 17 in 1 hour: K = 45, H = 3, the record's rate 45/3 = 15.
example : 28 + 17 = 45 ∧ 2 + 1 = 3 ∧ 45 / 3 = 15 := by decide

-- Prior Gamma(24, 2): mean 24/2 = 12, variance 24/2^2 = 6.
example : (24 : ℚ) / 2 = 12 ∧ (24 : ℚ) / 2 ^ 2 = 6 := by norm_num

-- Posterior Gamma(24 + 45, 2 + 3) = Gamma(69, 5): mean 69/5, variance 69/25.
example : 24 + 45 = 69 ∧ 2 + 3 = 5 := by decide
example : (69 : ℚ) / 5 ^ 2 = 69 / 25 := by norm_num

-- The posterior mean as a weighted average: (2/5) × 12 + (3/5) × 15 = 69/5.
example : (2 / 5 : ℚ) * (24 / 2) + (3 / 5) * (45 / 3) = 69 / 5 := by norm_num

-- Order does not matter: morning first gives Gamma(52, 4), then Gamma(69, 5); afternoon first
-- gives Gamma(41, 3), then the same Gamma(69, 5).
example : 24 + 28 = 52 ∧ 2 + 2 = 4 ∧ 52 + 17 = 69 ∧ 4 + 1 = 5 ∧
    24 + 17 = 41 ∧ 2 + 1 = 3 ∧ 41 + 28 = 69 ∧ 3 + 2 = 5 := by decide

-- Next hour (t = 1): p = 5/(5 + 1) = 5/6, mean 69/5, variance 69/5 + 69/25 = 414/25.
example : (5 : ℚ) / (5 + 1) = 5 / 6 := by norm_num
example : (1 : ℚ) * 69 / 5 + 1 ^ 2 * 69 / 5 ^ 2 = 414 / 25 := by norm_num

-- Mistake: windows (2) added to β instead of hours: mean 69/4 = 17.25.
example : (69 : ℚ) / (2 + 2) = 69 / 4 := by norm_num

-- Mistake: β = 2 read as a scale, rate 1/2: prior mean 48, posterior mean 69/(7/2) = 138/7.
example : (24 : ℚ) / (1 / 2) = 48 ∧ (69 : ℚ) / (1 / 2 + 3) = 138 / 7 := by norm_num

-- Mistake: morning entered twice: Gamma(97, 7), mean 97/7, variance 97/49.
example : (69 + 28 : ℚ) / (5 + 2) = 97 / 7 ∧ (69 + 28 : ℚ) / (5 + 2) ^ 2 = 97 / 49 := by norm_num

-- Try: prior Gamma(12/5, 1/5): mean (12/5 + 45)/(1/5 + 3) = 237/16.
example : (12 / 5 + 45 : ℚ) / (1 / 5 + 3) = 237 / 16 := by norm_num

-- Try: six hours, 90 emails: Gamma(114, 8), mean 57/4, variance 114/64.
example : (24 + 90 : ℚ) / (2 + 6) = 57 / 4 ∧ (24 + 90 : ℚ) / (2 + 6) ^ 2 = 114 / 64 := by norm_num

-- Try: half-hour window: mean (1/2)(69/5) = 69/10, variance 69/10 + (1/4)(69/25) = 759/100.
example : (1 / 2 : ℚ) * 69 / 5 = 69 / 10 ∧
    (1 / 2 : ℚ) * 69 / 5 + (1 / 2) ^ 2 * 69 / 5 ^ 2 = 759 / 100 := by norm_num

-- Try: a fourth hour with no email: Gamma(69, 6), mean 69/6 = 23/2.
example : (69 : ℚ) / (5 + 1) = 23 / 2 := by norm_num

#print axioms gamma_poisson_conjugate_update
#print axioms gamma_poisson_forecast_negative_binomial
#print axioms gamma_poisson_forecast_mean_variance
