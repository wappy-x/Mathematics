-- Bayes factors: the posterior odds of two models equal the Bayes factor, the ratio of the chances each model gave the data, times the prior odds, and a uniform prior on a coin's chance gives every count of heads in n flips the same evidence 1/(n + 1).
import Mathlib.Probability.ConditionalProbability
import Mathlib.Probability.Distributions.Beta
import Mathlib.RingTheory.Polynomial.Pochhammer
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

theorem gamma_add_nat_eq_mul_ascPochhammer (a : ℝ) (ha : 0 < a) (n : ℕ) :
    Real.Gamma (a + n) = Real.Gamma a * (ascPochhammer ℝ n).eval a := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Nat.cast_succ, ← add_assoc, Real.Gamma_add_one (by positivity), ih,
      ascPochhammer_succ_eval]
    ring

theorem integral_betaPDFReal_eq_one (α β : ℝ) (hα : 0 < α) (hβ : 0 < β) :
    ∫ x, betaPDFReal α β x = 1 := by
  have hnn : ∀ x, 0 ≤ betaPDFReal α β x := by
    intro x
    by_cases hx : 0 < x ∧ x < 1
    · exact (betaPDFReal_pos hx.1 hx.2 hα hβ).le
    · simp [betaPDFReal, hx]
  rw [integral_eq_lintegral_of_nonneg_ae (Filter.Eventually.of_forall hnn)
    (measurable_betaPDFReal α β).aestronglyMeasurable]
  have : ∫⁻ x, ENNReal.ofReal (betaPDFReal α β x) = 1 := lintegral_betaPDF_eq_one hα hβ
  rw [this]; simp

theorem beta_shift_ratio (a : ℝ) (ha : 0 < a) (n k : ℕ) (hk : k ≤ n) :
    beta (a + k) (a + (n - k : ℕ)) / beta a a =
      (ascPochhammer ℝ k).eval a * (ascPochhammer ℝ (n - k)).eval a /
        (ascPochhammer ℝ n).eval (2 * a) := by
  have h2 : a + k + (a + (n - k : ℕ)) = 2 * a + n := by
    rw [Nat.cast_sub hk]; ring
  unfold beta
  rw [h2, gamma_add_nat_eq_mul_ascPochhammer a ha, gamma_add_nat_eq_mul_ascPochhammer a ha,
    gamma_add_nat_eq_mul_ascPochhammer (2 * a) (by positivity), two_mul]
  have g1 := Real.Gamma_pos_of_pos ha
  have g2 := Real.Gamma_pos_of_pos (add_pos ha ha)
  have p1 : 0 < (ascPochhammer ℝ n).eval (a + a) := ascPochhammer_pos n (a + a) (by positivity)
  field_simp

theorem beta_prior_evidence_aux (a : ℝ) (ha : 0 < a) (n k : ℕ) (hk : k ≤ n) :
    ∫ θ, (n.choose k : ℝ) * θ ^ k * (1 - θ) ^ (n - k) * betaPDFReal a a θ =
      (n.choose k : ℝ) * (ascPochhammer ℝ k).eval a * (ascPochhammer ℝ (n - k)).eval a /
        (ascPochhammer ℝ n).eval (2 * a) := by
  have hB := beta_pos ha ha
  have hB' := beta_pos (α := a + k) (β := a + (n - k : ℕ)) (by positivity) (by positivity)
  have key : ∀ θ, (n.choose k : ℝ) * θ ^ k * (1 - θ) ^ (n - k) * betaPDFReal a a θ =
      ((n.choose k : ℝ) * (beta (a + k) (a + (n - k : ℕ)) / beta a a)) *
        betaPDFReal (a + k) (a + (n - k : ℕ)) θ := by
    intro θ
    by_cases hθ : 0 < θ ∧ θ < 1
    · simp only [betaPDFReal, hθ, and_self, ↓reduceIte]
      have h1 : 0 < 1 - θ := by linarith [hθ.2]
      have e1 : θ ^ (a + k - 1) = θ ^ k * θ ^ (a - 1) := by
        rw [← Real.rpow_natCast, ← Real.rpow_add hθ.1]; ring_nf
      have e2 : (1 - θ) ^ (a + (n - k : ℕ) - 1) = (1 - θ) ^ (n - k) * (1 - θ) ^ (a - 1) := by
        rw [← Real.rpow_natCast, ← Real.rpow_add h1]; ring_nf
      rw [e1, e2]
      field_simp
    · simp [betaPDFReal, hθ]
  simp_rw [key]
  rw [integral_const_mul, integral_betaPDFReal_eq_one _ _ (by positivity) (by positivity),
    mul_one, beta_shift_ratio a ha n k hk]
  ring

#print axioms gamma_add_nat_eq_mul_ascPochhammer
#print axioms integral_betaPDFReal_eq_one
#print axioms beta_shift_ratio
#print axioms beta_prior_evidence_aux

/-- The Bayes factor turns prior odds into posterior odds. Take two models `M₀` and `M₁` (events
in one probability space, so each has a prior chance) and data `D`. If both models give the data
a real chance, `P(D | M₀) > 0` and `P(D | M₁) > 0`, then the posterior odds `P(M₀ | D) / P(M₁ | D)`
equal the Bayes factor `B₀₁ = P(D | M₀) / P(D | M₁)` times the prior odds `P(M₀) / P(M₁)`. -/
theorem bayes_factor_times_prior_odds_is_posterior_odds {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (M₀ M₁ D : Set Ω)
    (hM₀ : MeasurableSet M₀) (hM₁ : MeasurableSet M₁) (hD : MeasurableSet D)
    (h₀ : μ[D | M₀] ≠ 0) (h₁ : μ[D | M₁] ≠ 0) :
    μ[M₀ | D] / μ[M₁ | D] = (μ[D | M₀] / μ[D | M₁]) * (μ M₀ / μ M₁) := by
  rw [cond_apply hD, cond_apply hD, cond_apply hM₀, cond_apply hM₁] at *
  have hx : μ (M₀ ∩ D) ≠ 0 := fun h => h₀ (by simp [h])
  have hy : μ (M₁ ∩ D) ≠ 0 := fun h => h₁ (by simp [h])
  have ha : μ M₀ ≠ 0 := fun h => hx (measure_mono_null Set.inter_subset_left h)
  have hb : μ M₁ ≠ 0 := fun h => hy (measure_mono_null Set.inter_subset_left h)
  have hd : μ D ≠ 0 := fun h => hx (measure_mono_null Set.inter_subset_right h)
  rw [Set.inter_comm D M₀, Set.inter_comm D M₁]
  have fa : μ M₀ ≠ ⊤ := measure_ne_top _ _
  have fb : μ M₁ ≠ ⊤ := measure_ne_top _ _
  have fd : μ D ≠ ⊤ := measure_ne_top _ _
  have fx : μ (M₀ ∩ D) ≠ ⊤ := measure_ne_top _ _
  have fy : μ (M₁ ∩ D) ≠ ⊤ := measure_ne_top _ _
  rw [← ENNReal.toReal_eq_toReal_iff']
  · simp only [ENNReal.toReal_div, ENNReal.toReal_mul, ENNReal.toReal_inv]
    have : (μ M₀).toReal ≠ 0 := ENNReal.toReal_ne_zero.mpr ⟨ha, fa⟩
    have : (μ M₁).toReal ≠ 0 := ENNReal.toReal_ne_zero.mpr ⟨hb, fb⟩
    have : (μ D).toReal ≠ 0 := ENNReal.toReal_ne_zero.mpr ⟨hd, fd⟩
    have : (μ (M₀ ∩ D)).toReal ≠ 0 := ENNReal.toReal_ne_zero.mpr ⟨hx, fx⟩
    have : (μ (M₁ ∩ D)).toReal ≠ 0 := ENNReal.toReal_ne_zero.mpr ⟨hy, fy⟩
    field_simp
  · exact ENNReal.div_ne_top (ENNReal.mul_ne_top (ENNReal.inv_ne_top.mpr hd) fx)
      (mul_ne_zero (ENNReal.inv_ne_zero.mpr fd) hy)
  · exact ENNReal.mul_ne_top
      (ENNReal.div_ne_top (ENNReal.mul_ne_top (ENNReal.inv_ne_top.mpr ha) fx)
        (mul_ne_zero (ENNReal.inv_ne_zero.mpr fb) hy))
      (ENNReal.div_ne_top fa hb)

/-- The open model's evidence under a uniform prior. If the coin's chance θ is uniform on 0 to 1,
the chance of `k` heads in `n` independent flips, the binomial chance `C(n, k) θ^k (1 - θ)^(n - k)`
averaged over θ, is `1/(n + 1)` for every `k` from 0 to `n`. -/
theorem uniform_prior_evidence_eq_one_div_succ (n k : ℕ) (hk : k ≤ n) :
    ∫ θ in (0 : ℝ)..1, (n.choose k : ℝ) * θ ^ k * (1 - θ) ^ (n - k) = 1 / (n + 1) := by
  have h := beta_prior_evidence_aux 1 one_pos n k hk
  have hb : beta 1 1 = 1 := by
    simp [beta, Real.Gamma_one, Real.Gamma_add_one one_ne_zero]
  have hind : ∀ θ : ℝ, (n.choose k : ℝ) * θ ^ k * (1 - θ) ^ (n - k) * betaPDFReal 1 1 θ =
      (Set.Ioo (0 : ℝ) 1).indicator (fun θ => (n.choose k : ℝ) * θ ^ k * (1 - θ) ^ (n - k)) θ := by
    intro θ
    by_cases hθ : 0 < θ ∧ θ < 1
    · simp [betaPDFReal, hθ, hb]
    · rw [Set.indicator_of_notMem (show θ ∉ Set.Ioo (0 : ℝ) 1 from hθ)]
      simp [betaPDFReal, hθ]
  simp_rw [hind] at h
  rw [integral_indicator measurableSet_Ioo, ← integral_Ioc_eq_integral_Ioo,
    ← intervalIntegral.integral_of_le zero_le_one] at h
  rw [show (2 : ℝ) * 1 = 2 by norm_num] at h
  rw [h, ascPochhammer_eval_one, ascPochhammer_eval_one]
  have e := factorial_mul_ascPochhammer ℝ 1 n
  have e2 : ((1 : ℕ) + 1 : ℝ) = 2 := by norm_num
  rw [e2] at e
  simp only [Nat.factorial_one, Nat.cast_one, one_mul] at e
  rw [e, add_comm 1 n]
  have hc := Nat.choose_mul_factorial_mul_factorial hk
  have hc' : (n.choose k : ℝ) * (k.factorial : ℝ) * ((n - k).factorial : ℝ) = n.factorial := by
    exact_mod_cast hc
  rw [hc', Nat.factorial_succ, Nat.cast_mul]
  have : (n.factorial : ℝ) ≠ 0 := by positivity
  field_simp
  push_cast; ring

/-- The open model's evidence under a Beta(a, a) prior, with `a > 0`. The chance of `k` heads in
`n` independent flips, averaged over θ with the Beta(a, a) density, is the ratio of rising products
`C(n, k) · a(a+1)⋯(a+k-1) · a(a+1)⋯(a+n-k-1) / (2a(2a+1)⋯(2a+n-1))`. -/
theorem beta_prior_evidence_eq_rising_products (a : ℝ) (ha : 0 < a) (n k : ℕ) (hk : k ≤ n) :
    ∫ θ, (n.choose k : ℝ) * θ ^ k * (1 - θ) ^ (n - k) * betaPDFReal a a θ =
      (n.choose k : ℝ) * (ascPochhammer ℝ k).eval a * (ascPochhammer ℝ (n - k)).eval a /
        (ascPochhammer ℝ n).eval (2 * a) := by
  exact beta_prior_evidence_aux a ha n k hk

/-! The card's worked numbers, as exact whole numbers and fractions. -/

-- Evidence for fair: C(10, 7)/2^10 = 120/1024.
example : Nat.choose 10 7 = 120 ∧ 2 ^ 10 = 1024 := by decide

-- Evidence for open: 120 × 7! 3!/11! = 1/11.
example : (120 * Nat.factorial 7 * Nat.factorial 3 : ℚ) / Nat.factorial 11 = 1 / 11 := by
  norm_num [Nat.factorial]

-- Bayes factor, fair over open: (120/1024)/(1/11) = 1320/1024; reverse 1024/1320.
example : ((120 : ℚ) / 1024) / (1 / 11) = 1320 / 1024 := by norm_num
example : (1 : ℚ) / (1320 / 1024) = 1024 / 1320 := by norm_num

-- Posterior chance of fair at even odds: 1.2891/2.2891 = 165/293.
example : ((1320 : ℚ) / 1024) / (1 + 1320 / 1024) = 165 / 293 := by norm_num

-- Prior odds 9: posterior odds 9 × 1320/1024 = 1485/128, chance 1485/1613.
example : (9 : ℚ) * (1320 / 1024) = 1485 / 128 ∧ ((1485 : ℚ) / 128) / (1 + 1485 / 128) = 1485 / 1613 := by
  norm_num

-- Prior odds 1/9: posterior chance of fair 55/439.
example : ((1 : ℚ) / 9 * (1320 / 1024)) / (1 + 1 / 9 * (1320 / 1024)) = 55 / 439 := by norm_num

-- Two-sided p-value for fair: 2 × 176/1024, from C(10, 7) + C(10, 8) + C(10, 9) + C(10, 10) = 176.
example : (Finset.Icc 7 10).sum (fun j => Nat.choose 10 j) = 176 := by decide

-- Beta(a, a) priors at 7 heads in 10: evidence by rising products, then the Bayes factor for fair.
-- a = 1/2: evidence 2145/32768, Bayes factor 256/143.
example : (120 * (Finset.range 7).prod (fun j => (1 / 2 + j : ℚ)) *
      (Finset.range 3).prod (fun j => (1 / 2 + j : ℚ)) /
      (Finset.range 10).prod (fun j => (1 + j : ℚ))) = 2145 / 32768 ∧
    ((120 : ℚ) / 1024) / (2145 / 32768) = 256 / 143 := by
  norm_num [Finset.prod_range_succ]
-- a = 2: evidence 16/143, Bayes factor 2145/2048.
example : (120 * (Finset.range 7).prod (fun j => (2 + j : ℚ)) *
      (Finset.range 3).prod (fun j => (2 + j : ℚ)) /
      (Finset.range 10).prod (fun j => (4 + j : ℚ))) = 16 / 143 ∧
    ((120 : ℚ) / 1024) / (16 / 143) = 2145 / 2048 := by
  norm_num [Finset.prod_range_succ]
-- a = 10: evidence 1760/14007, Bayes factor 42021/45056, below 1.
example : (120 * (Finset.range 7).prod (fun j => (10 + j : ℚ)) *
      (Finset.range 3).prod (fun j => (10 + j : ℚ)) /
      (Finset.range 10).prod (fun j => (20 + j : ℚ))) = 1760 / 14007 ∧
    ((120 : ℚ) / 1024) / (1760 / 14007) = 42021 / 45056 := by
  norm_num [Finset.prod_range_succ]
-- a = 50: Bayes factor 121330189/124467200, close to 1.
example : ((120 : ℚ) / 1024) / (120 * (Finset.range 7).prod (fun j => (50 + j : ℚ)) *
      (Finset.range 3).prod (fun j => (50 + j : ℚ)) /
      (Finset.range 10).prod (fun j => (100 + j : ℚ))) = 121330189 / 124467200 := by
  norm_num [Finset.prod_range_succ]

-- Posterior means (a + 7)/(2a + 10) for a = 1/2, 1, 2, 10: 15/22, 2/3, 9/14, 17/30.
example : ((1 / 2 + 7 : ℚ) / (1 + 10) = 15 / 22) ∧ ((1 + 7 : ℚ) / (2 + 10) = 2 / 3) ∧
    ((2 + 7 : ℚ) / (4 + 10) = 9 / 14) ∧ ((10 + 7 : ℚ) / (20 + 10) = 17 / 30) := by norm_num

-- Try lines: 5 of 10 gives 252 × 11/1024 = 2772/1024; 10 of 10 gives 11/1024.
example : Nat.choose 10 5 * 11 = 2772 ∧ Nat.choose 10 10 * 11 = 11 := by decide

#print axioms bayes_factor_times_prior_odds_is_posterior_odds
#print axioms uniform_prior_evidence_eq_one_div_succ
#print axioms beta_prior_evidence_eq_rising_products
