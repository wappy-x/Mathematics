-- Value at risk: the smallest loss level reached with chance at least α always exists, and for a normal P&L it equals minus the mean plus z standard deviations, scaling with the square root of the horizon over independent normal days.
import Mathlib.Probability.CDF
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic

open MeasureTheory ProbabilityTheory

/-- The standard normal cumulative distribution function is strictly increasing. -/
lemma var_helper_cdf_std_strictMono : StrictMono (cdf (gaussianReal 0 1)) := by
  intro a b hab
  have hpos : 0 < gaussianReal 0 1 (Set.Ioc a b) := by
    rw [pos_iff_ne_zero]
    intro h0
    have := gaussianReal_absolutelyContinuous' (0 : ℝ) (v := 1) one_ne_zero h0
    rw [Real.volume_Ioc, ENNReal.ofReal_eq_zero] at this
    linarith
  have hdiff : gaussianReal 0 1 (Set.Iic b \ Set.Iic a)
      = gaussianReal 0 1 (Set.Iic b) - gaussianReal 0 1 (Set.Iic a) :=
    measure_sdiff (Set.Iic_subset_Iic.mpr hab.le) measurableSet_Iic.nullMeasurableSet
      (measure_ne_top _ _)
  have hset : Set.Iic b \ Set.Iic a = Set.Ioc a b := by
    ext x; simp [and_comm]
  rw [← hset, hdiff, tsub_pos_iff_lt, ← ofReal_cdf, ← ofReal_cdf] at hpos
  exact (ENNReal.ofReal_lt_ofReal_iff'.mp hpos).1

/-- For a normal P&L with positive standard deviation, the chance that the loss is at most `ℓ`
is the standard normal cumulative distribution at `(ℓ + μ) / σ`. -/
lemma var_helper_normal_loss_prob {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (μ σ : ℝ) (hσ : 0 < σ)
    (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P) (ℓ : ℝ) :
    P.real {ω | -X ω ≤ ℓ} = cdf (gaussianReal 0 1) ((ℓ + μ) / σ) := by
  have hY : HasLaw (fun ω ↦ (μ - X ω) / σ) (gaussianReal 0 1) P := by
    have h1 := gaussianReal_div_const (gaussianReal_const_sub hX μ) σ
    convert h1 using 2
    · simp
    · ext
      simp [Real.coe_toNNReal _ (sq_nonneg σ), hσ.ne']
  have hset : {ω | -X ω ≤ ℓ} = {ω | (fun ω ↦ (μ - X ω) / σ) ω ≤ (ℓ + μ) / σ} := by
    ext ω
    simp only [Set.mem_ofPred_eq]
    rw [div_le_div_iff_of_pos_right hσ]
    constructor <;> intro h <;> linarith
  rw [hset, hY.measureReal_eq (p := fun y ↦ y ≤ (ℓ + μ) / σ) measurableSet_Iic, cdf_eq_real]
  rfl

/-- A sum of independent normal P&Ls over a finite set of days is normal, with mean and variance
multiplied by the number of days. -/
lemma var_helper_sum_hasLaw {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (h : ℕ) (X : Fin h → Ω → ℝ) (μ : ℝ) (v : NNReal)
    (hind : iIndepFun X P) (hX : ∀ i, HasLaw (X i) (gaussianReal μ v) P) (s : Finset (Fin h)) :
    HasLaw (∑ i ∈ s, X i) (gaussianReal (s.card * μ) (s.card * v)) P := by
  induction s using Finset.induction_on with
  | empty =>
    simp only [Finset.sum_empty, Finset.card_empty, Nat.cast_zero, zero_mul, gaussianReal_zero_var]
    refine ⟨aemeasurable_const, ?_⟩
    rw [show (0 : Ω → ℝ) = fun _ ↦ (0 : ℝ) from rfl, Measure.map_const]
    simp
  | insert a s ha ih =>
    have hind' : IndepFun (∑ j ∈ s, X j) (X a) P :=
      hind.indepFun_finsetSum_of_notMem₀ (fun i ↦ (hX i).aemeasurable) ha
    rw [Finset.sum_insert ha, add_comm, Finset.card_insert_of_notMem ha]
    refine ⟨by fun_prop, ?_⟩
    rw [gaussianReal_add_gaussianReal_of_indepFun hind' ih (hX a)]
    congr 1
    · push_cast; ring
    · push_cast; ring

/-- The definition of value at risk always gives an answer: for any loss distribution and any
confidence level `α` strictly between 0 and 1, there is a smallest loss level `ℓ` whose cumulative
chance `F_L(ℓ)` is at least `α`. -/
theorem var_definition_attained (ν : Measure ℝ) [IsProbabilityMeasure ν] (α : ℝ)
    (hα0 : 0 < α) (hα1 : α < 1) :
    ∃ ℓ : ℝ, IsLeast {ℓ : ℝ | α ≤ cdf ν ℓ} ℓ := by
  set S := {ℓ : ℝ | α ≤ cdf ν ℓ} with hS
  have hne : S.Nonempty := by
    obtain ⟨x, hx⟩ := ((tendsto_cdf_atTop ν).eventually (eventually_ge_nhds hα1)).exists
    exact ⟨x, hx⟩
  have hbdd : BddBelow S := by
    have := (tendsto_cdf_atBot ν).eventually (eventually_lt_nhds hα0)
    rw [Filter.eventually_atBot] at this
    obtain ⟨b, hb⟩ := this
    refine ⟨b, fun ℓ hℓ ↦ ?_⟩
    by_contra hlt
    rw [not_le] at hlt
    have h1 := hb ℓ hlt.le
    have h2 : α ≤ cdf ν ℓ := hℓ
    linarith
  refine ⟨sInf S, ?_, fun ℓ hℓ ↦ csInf_le hbdd hℓ⟩
  have hT : Filter.Tendsto (cdf ν) (nhdsWithin (sInf S) (Set.Ioi (sInf S)))
      (nhds (cdf ν (sInf S))) :=
    ((cdf ν).right_continuous _).mono Set.Ioi_subset_Ici_self
  show α ≤ cdf ν (sInf S)
  refine ge_of_tendsto hT ?_
  filter_upwards [self_mem_nhdsWithin] with x hx
  obtain ⟨s, hs, hsx⟩ := exists_lt_of_csInf_lt hne hx
  exact le_trans hs (monotone_cdf ν hsx.le)

/-- For a book whose one-day P&L `X` is normal with average `μ` and standard deviation `σ`, the
value at risk at confidence `α` (the smallest loss level that the loss `L = -X` stays at or below
with chance at least `α`) is `-μ + z σ`, where `z` is the standard normal quantile: `N(z) = α`. -/
theorem var_normal_eq_neg_mean_add_z_mul_sd {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (X : Ω → ℝ) (μ σ : ℝ) (hσ : 0 ≤ σ)
    (hX : HasLaw X (gaussianReal μ (σ ^ 2).toNNReal) P)
    (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) (z : ℝ) (hz : cdf (gaussianReal 0 1) z = α) :
    IsLeast {ℓ : ℝ | α ≤ P.real {ω | -X ω ≤ ℓ}} (-μ + z * σ) := by
  rcases hσ.eq_or_lt with h0 | hpos
  · subst h0
    have hX' : HasLaw X (Measure.dirac μ) P := by
      simpa [gaussianReal_zero_var] using hX
    have key : ∀ ℓ, P.real {ω | -X ω ≤ ℓ} = (Measure.dirac μ).real {x : ℝ | -x ≤ ℓ} := fun ℓ ↦
      hX'.measureReal_eq (p := fun x ↦ -x ≤ ℓ) (measurableSet_le (by fun_prop) measurable_const)
    refine ⟨?_, fun ℓ hℓ ↦ ?_⟩
    · show α ≤ P.real {ω | -X ω ≤ -μ + z * 0}
      rw [key, Measure.dirac_real_apply_of_mem (by simp)]
      exact hα1.le
    · have hℓ' : α ≤ P.real {ω | -X ω ≤ ℓ} := hℓ
      by_contra hlt
      rw [not_le] at hlt
      rw [key, Measure.dirac_real_apply, Set.indicator_of_notMem (by simp; linarith)] at hℓ'
      linarith
  · refine ⟨?_, fun ℓ hℓ ↦ ?_⟩
    · show α ≤ P.real {ω | -X ω ≤ -μ + z * σ}
      rw [var_helper_normal_loss_prob P X μ σ hpos hX]
      rw [show (-μ + z * σ + μ) / σ = z by field_simp; ring, hz]
    · have hℓ' : α ≤ P.real {ω | -X ω ≤ ℓ} := hℓ
      rw [var_helper_normal_loss_prob P X μ σ hpos hX] at hℓ'
      by_contra hlt
      rw [not_le] at hlt
      have hlt' : (ℓ + μ) / σ < z := by
        rw [div_lt_iff₀ hpos]; linarith
      have := var_helper_cdf_std_strictMono hlt'
      linarith

/-- Square-root-of-time rule: if the P&Ls of `h` days are independent and each normal with average
`μ` and standard deviation `σ`, the value at risk at confidence `α` of their sum is
`-h μ + z σ √h`, where `N(z) = α`. -/
theorem var_horizon_sqrt_rule {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    [IsProbabilityMeasure P] (h : ℕ) (X : Fin h → Ω → ℝ) (μ σ : ℝ) (hσ : 0 ≤ σ)
    (hind : iIndepFun X P) (hX : ∀ i, HasLaw (X i) (gaussianReal μ (σ ^ 2).toNNReal) P)
    (α : ℝ) (hα0 : 0 < α) (hα1 : α < 1) (z : ℝ) (hz : cdf (gaussianReal 0 1) z = α) :
    IsLeast {ℓ : ℝ | α ≤ P.real {ω | -(∑ i, X i ω) ≤ ℓ}} (-(h * μ) + z * σ * Real.sqrt h) := by
  have hsum := var_helper_sum_hasLaw P h X μ _ hind hX Finset.univ
  simp only [Finset.card_univ, Fintype.card_fin] at hsum
  have hfun : (∑ i, X i) = fun ω ↦ ∑ i, X i ω := by
    ext ω; simp [Finset.sum_apply]
  rw [hfun] at hsum
  have hvar : ((h : NNReal) * (σ ^ 2).toNNReal) = ((σ * Real.sqrt h) ^ 2).toNNReal := by
    ext
    rw [NNReal.coe_mul, Real.coe_toNNReal _ (sq_nonneg _), Real.coe_toNNReal _ (sq_nonneg _),
      mul_pow, Real.sq_sqrt (Nat.cast_nonneg _)]
    push_cast; ring
  rw [hvar] at hsum
  have := var_normal_eq_neg_mean_add_z_mul_sd P (fun ω ↦ ∑ i, X i ω) (h * μ) (σ * Real.sqrt h)
    (mul_nonneg hσ (Real.sqrt_nonneg _)) hsum α hα0 hα1 z hz
  simpa [mul_assoc] using this

-- A 99% VaR is broken on 1% of days: 2.5 days in a 250-day year.
example : (250 : ℚ) * (1 - 99 / 100) = 5 / 2 := by norm_num

#print axioms var_helper_cdf_std_strictMono
#print axioms var_helper_normal_loss_prob
#print axioms var_helper_sum_hasLaw
#print axioms var_definition_attained
#print axioms var_normal_eq_neg_mean_add_z_mul_sd
#print axioms var_horizon_sqrt_rule
