-- Default correlation: the correlation of two failure indicators turns the two single failure chances into the joint failure chance, is squeezed into a narrow range by those chances, and sets the variance of a pool's failure count.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory

/-- The default correlation of two failure events `A` and `B`: the ordinary correlation of their
failure indicators (1 if the borrower fails, 0 if not), that is the covariance of the two
indicators divided by the product of their standard deviations. -/
noncomputable def defaultCorrelation {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (A B : Set Ω) : ℝ :=
  covariance (A.indicator fun _ => (1 : ℝ)) (B.indicator fun _ => (1 : ℝ)) μ /
    (Real.sqrt (variance (A.indicator fun _ => (1 : ℝ)) μ) *
      Real.sqrt (variance (B.indicator fun _ => (1 : ℝ)) μ))

/-- A failure indicator has a finite second moment. -/
lemma dc_indicator_memLp {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsFiniteMeasure μ]
    {A : Set Ω} (hA : MeasurableSet A) :
    MemLp (A.indicator fun _ => (1 : ℝ)) 2 μ :=
  memLp_indicator_const 2 hA.nullMeasurableSet (1 : ℝ) (.inr (measure_ne_top μ A))

/-- The average of a failure indicator is the failure chance. -/
lemma dc_integral_indicator {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    {A : Set Ω} (hA : MeasurableSet A) :
    ∫ ω, A.indicator (fun _ => (1 : ℝ)) ω ∂μ = μ.real A := by
  rw [integral_indicator_const (1 : ℝ) hA, smul_eq_mul, mul_one]

/-- The product of two failure indicators is the indicator of joint failure. -/
lemma dc_indicator_mul {Ω : Type*} (A B : Set Ω) :
    (A.indicator fun _ => (1 : ℝ)) * (B.indicator fun _ => (1 : ℝ))
      = (A ∩ B).indicator fun _ => (1 : ℝ) := by
  funext ω
  by_cases hA : ω ∈ A <;> by_cases hB : ω ∈ B <;> simp [Set.indicator, hA, hB]

/-- The covariance of two failure indicators is `P(A ∩ B) - P(A) P(B)`. -/
lemma dc_covariance_indicator {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {A B : Set Ω} (hA : MeasurableSet A) (hB : MeasurableSet B) :
    covariance (A.indicator fun _ => (1 : ℝ)) (B.indicator fun _ => (1 : ℝ)) μ
      = μ.real (A ∩ B) - μ.real A * μ.real B := by
  rw [covariance_eq_sub (dc_indicator_memLp μ hA) (dc_indicator_memLp μ hB),
    dc_indicator_mul, dc_integral_indicator μ (hA.inter hB), dc_integral_indicator μ hA,
    dc_integral_indicator μ hB]

/-- The variance of a failure indicator is `p (1 - p)`. -/
lemma dc_variance_indicator {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {A : Set Ω} (hA : MeasurableSet A) :
    variance (A.indicator fun _ => (1 : ℝ)) μ = μ.real A * (1 - μ.real A) := by
  rw [← covariance_self (dc_indicator_memLp μ hA).aemeasurable,
    dc_covariance_indicator μ hA hA, Set.inter_self]
  ring

/-- The default correlation written through the chances. -/
lemma dc_defaultCorrelation_eq {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] {A B : Set Ω} (hA : MeasurableSet A) (hB : MeasurableSet B) :
    defaultCorrelation μ A B = (μ.real (A ∩ B) - μ.real A * μ.real B) /
      Real.sqrt (μ.real A * (1 - μ.real A) * (μ.real B * (1 - μ.real B))) := by
  have h1 : 0 ≤ μ.real A * (1 - μ.real A) :=
    mul_nonneg measureReal_nonneg (sub_nonneg.mpr measureReal_le_one)
  rw [defaultCorrelation, dc_covariance_indicator μ hA hB, dc_variance_indicator μ hA,
    dc_variance_indicator μ hB, Real.sqrt_mul h1]

/-- The joint-default identity. Let two borrowers fail on the events `A₁` and `A₂`, with failure
chances p₁ = P(A₁) and p₂ = P(A₂) both strictly between 0 and 1, and let j = P(A₁ ∩ A₂) be the
chance both fail. Then the chance both fail is the chance under independence plus the default
correlation times the scale √(p₁(1 − p₁) p₂(1 − p₂)):
j = p₁ p₂ + ρ_D √(p₁(1 − p₁) p₂(1 − p₂)), and run backwards,
ρ_D = (j − p₁ p₂) / √(p₁(1 − p₁) p₂(1 − p₂)). -/
theorem joint_default_eq_independent_add_correlation_mul_scale {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] {A₁ A₂ : Set Ω}
    (h₁ : MeasurableSet A₁) (h₂ : MeasurableSet A₂)
    (hp₁ : 0 < μ.real A₁) (hp₁' : μ.real A₁ < 1) (hp₂ : 0 < μ.real A₂) (hp₂' : μ.real A₂ < 1) :
    μ.real (A₁ ∩ A₂) = μ.real A₁ * μ.real A₂ + defaultCorrelation μ A₁ A₂ *
        Real.sqrt (μ.real A₁ * (1 - μ.real A₁) * (μ.real A₂ * (1 - μ.real A₂))) ∧
    defaultCorrelation μ A₁ A₂ = (μ.real (A₁ ∩ A₂) - μ.real A₁ * μ.real A₂) /
        Real.sqrt (μ.real A₁ * (1 - μ.real A₁) * (μ.real A₂ * (1 - μ.real A₂))) := by
  have hρ := dc_defaultCorrelation_eq μ h₁ h₂
  have hs : 0 < Real.sqrt (μ.real A₁ * (1 - μ.real A₁) * (μ.real A₂ * (1 - μ.real A₂))) := by
    apply Real.sqrt_pos.mpr
    have := mul_pos hp₁ (sub_pos.mpr hp₁')
    have := mul_pos hp₂ (sub_pos.mpr hp₂')
    positivity
  refine ⟨?_, hρ⟩
  rw [hρ, div_mul_cancel₀ _ hs.ne']
  ring

/-- Not every correlation is possible. For two failure events with chances p₁ and p₂ strictly
between 0 and 1, the chance j that both fail lies between max(0, p₁ + p₂ − 1) and min(p₁, p₂),
so the default correlation lies between the inverse formula at those two ends:
(max(0, p₁ + p₂ − 1) − p₁ p₂) / s ≤ ρ_D ≤ (min(p₁, p₂) − p₁ p₂) / s,
where s = √(p₁(1 − p₁) p₂(1 − p₂)). -/
theorem default_correlation_bounds {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] {A₁ A₂ : Set Ω}
    (h₁ : MeasurableSet A₁) (h₂ : MeasurableSet A₂)
    (hp₁ : 0 < μ.real A₁) (hp₁' : μ.real A₁ < 1) (hp₂ : 0 < μ.real A₂) (hp₂' : μ.real A₂ < 1) :
    (max 0 (μ.real A₁ + μ.real A₂ - 1) ≤ μ.real (A₁ ∩ A₂) ∧
      μ.real (A₁ ∩ A₂) ≤ min (μ.real A₁) (μ.real A₂)) ∧
    ((max 0 (μ.real A₁ + μ.real A₂ - 1) - μ.real A₁ * μ.real A₂) /
        Real.sqrt (μ.real A₁ * (1 - μ.real A₁) * (μ.real A₂ * (1 - μ.real A₂)))
        ≤ defaultCorrelation μ A₁ A₂ ∧
      defaultCorrelation μ A₁ A₂ ≤ (min (μ.real A₁) (μ.real A₂) - μ.real A₁ * μ.real A₂) /
        Real.sqrt (μ.real A₁ * (1 - μ.real A₁) * (μ.real A₂ * (1 - μ.real A₂)))) := by
  have hρ := dc_defaultCorrelation_eq μ h₁ h₂
  have hs : 0 < Real.sqrt (μ.real A₁ * (1 - μ.real A₁) * (μ.real A₂ * (1 - μ.real A₂))) := by
    apply Real.sqrt_pos.mpr
    have := mul_pos hp₁ (sub_pos.mpr hp₁')
    have := mul_pos hp₂ (sub_pos.mpr hp₂')
    positivity
  have hlo : max 0 (μ.real A₁ + μ.real A₂ - 1) ≤ μ.real (A₁ ∩ A₂) := by
    refine max_le measureReal_nonneg ?_
    have hu := measureReal_union_add_inter (μ := μ) (s := A₁) h₂
    have : μ.real (A₁ ∪ A₂) ≤ 1 := measureReal_le_one
    linarith
  have hhi : μ.real (A₁ ∩ A₂) ≤ min (μ.real A₁) (μ.real A₂) :=
    le_min (measureReal_mono Set.inter_subset_left) (measureReal_mono Set.inter_subset_right)
  refine ⟨⟨hlo, hhi⟩, ?_, ?_⟩
  · rw [hρ]
    exact div_le_div_of_nonneg_right (by linarith) hs.le
  · rw [hρ]
    exact div_le_div_of_nonneg_right (by linarith) hs.le

/-- The pool's spread. Take a pool of n alike loans, the i-th failing on the event `A i`, all with
one shared failure chance p strictly between 0 and 1 and one shared default correlation ρ_D for
every pair of distinct loans. Let S be the number of loans that fail. Then the average of S is
n p, whatever the correlation, and its variance is Var(S) = n p (1 − p) [1 + (n − 1) ρ_D]. -/
theorem pool_default_count_mean_and_variance {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (n : ℕ) (A : Fin n → Set Ω)
    (hA : ∀ i, MeasurableSet (A i)) (p ρ : ℝ) (hp : 0 < p) (hp' : p < 1)
    (hpA : ∀ i, μ.real (A i) = p)
    (hρ : ∀ i j, i ≠ j → defaultCorrelation μ (A i) (A j) = ρ) :
    ∫ ω, (∑ i, (A i).indicator (fun _ => (1 : ℝ)) ω) ∂μ = n * p ∧
    variance (fun ω => ∑ i, (A i).indicator (fun _ => (1 : ℝ)) ω) μ
      = n * p * (1 - p) * (1 + (n - 1) * ρ) := by
  have hv : ∀ i, variance ((A i).indicator fun _ => (1 : ℝ)) μ = p * (1 - p) := by
    intro i
    rw [dc_variance_indicator μ (hA i), hpA i]
  have hvpos : 0 < p * (1 - p) := mul_pos hp (sub_pos.mpr hp')
  have hcov : ∀ i j, covariance ((A i).indicator fun _ => (1 : ℝ))
      ((A j).indicator fun _ => (1 : ℝ)) μ
      = ρ * (p * (1 - p)) + (if i = j then (1 - ρ) * (p * (1 - p)) else 0) := by
    intro i j
    by_cases hij : i = j
    · subst hij
      rw [covariance_self (dc_indicator_memLp μ (hA i)).aemeasurable, hv i]
      simp only [ite_true]
      ring
    · have h := hρ i j hij
      rw [defaultCorrelation, hv i, hv j, Real.mul_self_sqrt hvpos.le] at h
      simp only [hij, ite_false]
      rw [← h, div_mul_cancel₀ _ hvpos.ne']
      ring
  constructor
  · rw [integral_finsetSum _ (fun i _ => (dc_indicator_memLp μ (hA i)).integrable one_le_two)]
    simp only [dc_integral_indicator μ (hA _), hpA, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul]
  · rw [variance_fun_sum (fun i => dc_indicator_memLp μ (hA i))]
    simp only [hcov, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ,
      Fintype.card_fin, nsmul_eq_mul, Finset.sum_ite_eq, Finset.mem_univ, ite_true]
    ring

/-! The card's worked numbers, as exact fractions: p = 5% = 1/20, ρ_D = 11/190. -/

-- Independent joint chance: 0.05 × 0.05 = 0.25% = 1/400.
example : (1 / 20 : ℚ) * (1 / 20) = 1 / 400 := by norm_num
-- The scale: √(0.05 × 0.95 × 0.05 × 0.95) = 0.05 × 0.95 = 0.0475 = 19/400.
example : (1 / 20 : ℚ) * (19 / 20) = 19 / 400 := by norm_num
example : Real.sqrt ((1 / 20 : ℝ) * (1 - 1 / 20) * ((1 / 20) * (1 - 1 / 20))) = 19 / 400 := by
  rw [show (1 / 20 : ℝ) * (1 - 1 / 20) * ((1 / 20) * (1 - 1 / 20)) = (19 / 400) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Extra from correlation: 11/190 × 0.0475 = 0.275%; joint chance 0.25% + 0.275% = 0.525% = 21/4000.
example : (11 / 190 : ℚ) * (19 / 400) = 11 / 4000 := by norm_num
example : (1 / 400 : ℚ) + 11 / 4000 = 21 / 4000 := by norm_num
-- Back again: (0.00525 − 0.0025) / 0.0475 = 11/190 = 0.057895.
example : ((21 / 4000 : ℚ) - 1 / 400) / (19 / 400) = 11 / 190 := by norm_num
-- With the rounded correlation 0.058: 0.0025 + 0.058 × 0.0475 = 0.5255%.
example : (1 / 400 : ℚ) + 58 / 1000 * (19 / 400) = 5255 / 1000000 := by norm_num
-- The four cells: one fails and the other survives 4.475%; neither fails 90.525%; they sum to 1.
example : (1 / 20 : ℚ) - 21 / 4000 = 179 / 4000 := by norm_num
example : (1 : ℚ) - 1 / 20 - 1 / 20 + 21 / 4000 = 3621 / 4000 := by norm_num
example : (21 / 4000 : ℚ) + 179 / 4000 + 179 / 4000 + 3621 / 4000 = 1 := by norm_num
-- Allowed range: j = 0 gives −1/19 = −0.052632; j = 5% gives exactly 1.
example : ((0 : ℚ) - 1 / 400) / (19 / 400) = -1 / 19 := by norm_num
example : ((1 / 20 : ℚ) - 1 / 400) / (19 / 400) = 1 := by norm_num
-- Pool of 100: average 5 failures; 4,950 distinct pairs.
example : (100 : ℚ) * (1 / 20) = 5 := by norm_num
example : 100 * 99 / 2 = 4950 := by decide
-- Independent variance 100 × 0.05 × 0.95 = 4.75; bracket 1 + 99 × 11/190 = 1279/190 = 6.731579;
-- clustered variance 4.75 × 1279/190 = 31.975.
example : (100 : ℚ) * (1 / 20) * (19 / 20) = 19 / 4 := by norm_num
example : (1 : ℚ) + 99 * (11 / 190) = 1279 / 190 := by norm_num
example : (19 / 4 : ℚ) * (1279 / 190) = 31975 / 1000 := by norm_num
-- The same variance from the pairs: 4.75 plus 100 × 99 ordered pairs, each 11/190 × 0.0475.
example : (19 / 4 : ℚ) + 100 * 99 * ((11 / 190) * (19 / 400)) = 31975 / 1000 := by norm_num
-- Money: each failure loses 60% of $100,000 = $60,000; expected loss 5 × $60,000 = $300,000.
example : (100000 : ℚ) * (1 - 40 / 100) = 60000 := by norm_num
example : 5 * 60000 = 300000 := by decide
-- Town model: bad spell with chance 11/51 (15% each), else 2.25% each.
-- One loan fails with chance 5%; two fail together with chance 0.525%.
example : (11 / 51 : ℚ) * (15 / 100) + (40 / 51) * (225 / 10000) = 1 / 20 := by norm_num
example : (11 / 51 : ℚ) * (15 / 100) ^ 2 + (40 / 51) * (225 / 10000) ^ 2 = 21 / 4000 := by
  norm_num
-- Copy model: 11/190 × 5% + 179/190 × 0.25% = 0.525%, the same pair.
example : (11 / 190 : ℚ) * (1 / 20) + (179 / 190) * (1 / 400) = 21 / 4000 := by norm_num
-- Mistakes: asset correlation 0.20 used as ρ_D gives 1.2%; scaling by p₁ p₂ gives 0.2645%.
example : (1 / 400 : ℚ) + (1 / 5) * (19 / 400) = 12 / 1000 := by norm_num
example : (1 / 400 : ℚ) + (11 / 190) * (1 / 400) = 201 / 76000 := by norm_num

#print axioms dc_indicator_memLp
#print axioms dc_integral_indicator
#print axioms dc_indicator_mul
#print axioms dc_covariance_indicator
#print axioms dc_variance_indicator
#print axioms dc_defaultCorrelation_eq
#print axioms joint_default_eq_independent_add_correlation_mul_scale
#print axioms default_correlation_bounds
#print axioms pool_default_count_mean_and_variance
