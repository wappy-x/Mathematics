-- Uniform: a random variable spread evenly over a window [a, b] gives each stretch its length over b − a, has mean (a + b)/2, variance (b − a)²/12 and quantile a + (b − a)u, and any cumulative chance function's quantile applied to a uniform draw on [0, 1] produces that law.
import Mathlib.Probability.Distributions.Uniform
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory ProbabilityTheory Filter Topology

lemma uniform_integral_comp {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {X : Ω → ℝ} {a b : ℝ} (hab : a < b) (hX : pdf.IsUniform X (Set.Icc a b) P)
    (f : ℝ → ℝ) (hf : Continuous f) :
    ∫ ω, f (X ω) ∂P = (b - a)⁻¹ * ∫ x in a..b, f x := by
  rw [← integral_map hX.aemeasurable hf.aestronglyMeasurable, hX.map_eq, ProbabilityTheory.cond,
    integral_smul_measure, intervalIntegral.integral_of_le hab.le, ← integral_Icc_eq_integral_Ioc,
    Real.volume_Icc, smul_eq_mul, ENNReal.toReal_inv, ENNReal.toReal_ofReal (by linarith)]

lemma uniform_real_preimage {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    {X : Ω → ℝ} {a b : ℝ} (hab : a < b) (hX : pdf.IsUniform X (Set.Icc a b) P)
    {A : Set ℝ} (hA : MeasurableSet A) :
    P.real (X ⁻¹' A) = volume.real (Set.Icc a b ∩ A) / (b - a) := by
  rw [measureReal_def, hX.measure_preimage hA, ENNReal.toReal_div, Real.volume_Icc,
    ENNReal.toReal_ofReal (by linarith), measureReal_def]

lemma Icc_inter_Iic_of_le {a b x : ℝ} (hxb : x ≤ b) :
    Set.Icc a b ∩ Set.Iic x = Set.Icc a x := by
  ext y
  simp only [Set.mem_inter_iff, Set.mem_Icc, Set.mem_Iic]
  constructor
  · rintro ⟨⟨h1, _⟩, h3⟩
    exact ⟨h1, h3⟩
  · rintro ⟨h1, h2⟩
    exact ⟨⟨h1, h2.trans hxb⟩, h2⟩

lemma quantile_le_iff (G : ℝ → ℝ) (hmono : Monotone G)
    (hright : ∀ x, ContinuousWithinAt G (Set.Ici x) x)
    (hbot : Tendsto G atBot (𝓝 0)) (htop : Tendsto G atTop (𝓝 1))
    (u : ℝ) (hu : u ∈ Set.Ioo 0 1) (x : ℝ) :
    sInf {y : ℝ | u ≤ G y} ≤ x ↔ u ≤ G x := by
  have hne : ({y : ℝ | u ≤ G y}).Nonempty := by
    obtain ⟨y, hy⟩ := (htop.eventually (lt_mem_nhds hu.2)).exists
    exact ⟨y, hy.le⟩
  have hbdd : BddBelow {y : ℝ | u ≤ G y} := by
    obtain ⟨y0, hy0⟩ := Filter.eventually_atBot.1 (hbot.eventually (gt_mem_nhds hu.1))
    refine ⟨y0, fun y hy => ?_⟩
    by_contra h
    have := hy0 y (not_le.1 h).le
    have hy' : u ≤ G y := hy
    linarith
  constructor
  · intro h
    refine le_trans ?_ (hmono h)
    have hc : ContinuousWithinAt G (Set.Ioi (sInf {y : ℝ | u ≤ G y})) (sInf {y : ℝ | u ≤ G y}) :=
      (hright _).mono Set.Ioi_subset_Ici_self
    refine ge_of_tendsto hc (eventually_nhdsWithin_of_forall fun y hy => ?_)
    obtain ⟨s, hs, hsy⟩ := exists_lt_of_csInf_lt hne hy
    exact le_trans hs (hmono hsy.le)
  · intro h
    exact csInf_le hbdd h

#print axioms uniform_integral_comp
#print axioms uniform_real_preimage
#print axioms Icc_inter_Iic_of_le
#print axioms quantile_le_iff

/-- The uniform law on a finite window. Let a < b, and let X be a random variable that is
uniform on the window [a, b] under P: every stretch of the same length holds the same chance.
Then the chance that X lands in a stretch [c, d] inside the window is its length over the
window's length, (d − c)/(b − a); the mean of X is the midpoint (a + b)/2; and the variance of X
is the width squared over 12, (b − a)²/12. -/
theorem uniform_chance_mean_variance {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (X : Ω → ℝ) (a b : ℝ) (hab : a < b) (hX : pdf.IsUniform X (Set.Icc a b) P) :
    (∀ c d : ℝ, a ≤ c → c ≤ d → d ≤ b →
        P.real {ω | X ω ∈ Set.Icc c d} = (d - c) / (b - a)) ∧
    ∫ ω, X ω ∂P = (a + b) / 2 ∧
    variance X P = (b - a) ^ 2 / 12 := by
  have hba : b - a ≠ 0 := by linarith
  have hmean : ∫ ω, X ω ∂P = (a + b) / 2 := by
    have h := uniform_integral_comp hab hX id continuous_id
    simp only [id] at h
    rw [h, integral_id]
    field_simp
    ring
  refine ⟨?_, hmean, ?_⟩
  · intro c d hac hcd hdb
    change P.real (X ⁻¹' Set.Icc c d) = _
    rw [uniform_real_preimage hab hX measurableSet_Icc, Set.Icc_inter_Icc, max_eq_right hac,
      min_eq_right hdb, Real.volume_real_Icc_of_le hcd]
  · rw [variance_eq_integral hX.aemeasurable, hmean,
      uniform_integral_comp hab hX (fun x => (x - (a + b) / 2) ^ 2) (by fun_prop),
      intervalIntegral.integral_comp_sub_right (fun x => x ^ 2), integral_pow]
    field_simp
    ring

/-- The cumulative chance is a straight ramp and the quantile inverts it. Let a < b and X be
uniform on [a, b]. For every u strictly between 0 and 1, the one wait x in the window whose
cumulative chance P(X ≤ x) equals u is x = a + (b − a)u. -/
theorem uniform_quantile {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (X : Ω → ℝ) (a b : ℝ) (hab : a < b) (hX : pdf.IsUniform X (Set.Icc a b) P)
    (u : ℝ) (hu : u ∈ Set.Ioo 0 1) :
    ∀ x ∈ Set.Icc a b, P.real {ω | X ω ≤ x} = u ↔ x = a + (b - a) * u := by
  intro x hx
  have hba : b - a ≠ 0 := by linarith
  change P.real (X ⁻¹' Set.Iic x) = u ↔ _
  rw [uniform_real_preimage hab hX measurableSet_Iic, Icc_inter_Iic_of_le hx.2,
    Real.volume_real_Icc_of_le hx.1]
  constructor
  · intro h
    field_simp at h
    linarith
  · intro h
    rw [h]
    field_simp
    ring

/-- The inverse-transform rule. Let U be uniform on [0, 1], and let G be any cumulative chance
function: never decreasing, continuous from the right, tending to 0 far left and to 1 far right.
Its quantile sends u to the least x with G(x) ≥ u. Then the quantile of U has cumulative chance
G: for every x, the chance that it is at most x equals G(x). -/
theorem inverse_transform {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (U : Ω → ℝ) (hU : pdf.IsUniform U (Set.Icc 0 1) P)
    (G : ℝ → ℝ) (hmono : Monotone G) (hright : ∀ x, ContinuousWithinAt G (Set.Ici x) x)
    (hbot : Tendsto G atBot (𝓝 0)) (htop : Tendsto G atTop (𝓝 1)) :
    ∀ x : ℝ, P.real {ω | sInf {y : ℝ | U ω ≤ G y} ≤ x} = G x := by
  intro x
  have hG0 : 0 ≤ G x := hmono.le_of_tendsto hbot x
  have hG1 : G x ≤ 1 := hmono.ge_of_tendsto htop x
  have hae : ∀ᵐ ω ∂P, U ω ∈ Set.Ioo (0 : ℝ) 1 := by
    apply ae_of_ae_map hU.aemeasurable
    rw [hU.map_eq, ProbabilityTheory.cond]
    refine Measure.ae_smul_measure ?_ _
    rw [← Measure.restrict_congr_set Ioo_ae_eq_Icc]
    exact ae_restrict_mem measurableSet_Ioo
  have hset : {ω | sInf {y : ℝ | U ω ≤ G y} ≤ x} =ᵐ[P] (U ⁻¹' Set.Iic (G x)) :=
    hae.mono fun ω hω => propext (quantile_le_iff G hmono hright hbot htop (U ω) hω x)
  rw [measureReal_def, measure_congr hset, ← measureReal_def,
    uniform_real_preimage zero_lt_one hU measurableSet_Iic, Icc_inter_Iic_of_le hG1,
    Real.volume_real_Icc_of_le hG0]
  simp

-- The bus: a = 0, b = 10 minutes. Density 1/(10 − 0) = 1/10 per minute.
example : (1 : ℚ) / (10 - 0) = 1 / 10 := by norm_num
-- Chance the wait is at most 3 minutes: (3 − 0)/10 = 3/10.
example : ((3 : ℚ) - 0) / (10 - 0) = 3 / 10 := by norm_num
-- Chance of arriving between 8:04 and 8:07: (7 − 4)/10 = 3/10.
example : ((7 : ℚ) - 4) / (10 - 0) = 3 / 10 := by norm_num
-- Mean: (0 + 10)/2 = 5 minutes.
example : ((0 : ℚ) + 10) / 2 = 5 := by norm_num
-- Mean square: (0 + 0 + 100)/3 = 100/3.
example : ((0 : ℚ) ^ 2 + 0 * 10 + 10 ^ 2) / 3 = 100 / 3 := by norm_num
-- Variance two ways: 100/3 − 5² = 100/12 = (10 − 0)²/12.
example : (100 : ℚ) / 3 - 5 ^ 2 = 100 / 12 := by norm_num
example : ((10 : ℚ) - 0) ^ 2 / 12 = 100 / 12 := by norm_num
-- Median and 90th-percentile wait: Q(1/2) = 5 and Q(9/10) = 9 minutes.
example : (0 : ℚ) + (10 - 0) * (1 / 2) = 5 := by norm_num
example : (0 : ℚ) + (10 - 0) * (9 / 10) = 9 := by norm_num
-- Already waited 4 minutes: chance of a bus by 8:07 is (7 − 4)/(10 − 4) = 1/2,
-- and the mean still to wait is (10 − 4)/2 = 3 minutes.
example : ((7 : ℚ) - 4) / (10 - 4) = 1 / 2 := by norm_num
example : ((10 : ℚ) - 4) / 2 = 3 := by norm_num
-- Grid of n = 10 midpoints (k + 1/2), each with chance 1/10: mean 5, variance 33/4 = 8.25,
-- matching (100/12)(1 − 1/10²).
example : (∑ k ∈ Finset.range 10, ((k : ℚ) + 1 / 2)) / 10 = 5 := by
  norm_num [Finset.sum_range_succ]
example : (∑ k ∈ Finset.range 10, ((k : ℚ) + 1 / 2 - 5) ^ 2) / 10 = 33 / 4 := by
  norm_num [Finset.sum_range_succ]
example : (100 : ℚ) / 12 * (1 - 1 / 10 ^ 2) = 33 / 4 := by norm_num
-- What breaks: the 11 whole minutes 0 to 10 give variance 10, not 100/12.
example : (∑ k ∈ Finset.range 11, ((k : ℚ) - 5) ^ 2) / 11 = 10 := by
  norm_num [Finset.sum_range_succ]

#print axioms uniform_chance_mean_variance
#print axioms uniform_quantile
#print axioms inverse_transform
