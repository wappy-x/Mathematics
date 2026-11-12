-- Robust and chance constraints: the worst return over a ball of estimates is the estimate minus the radius times the length of the weights, a box of errors instead costs the radius times the sum of the absolute weights, and a normal chance constraint is exactly the same kind of worst case shaped by the risk.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Probability.Distributions.Gaussian.Multivariate
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Matrix
open scoped RealInnerProductSpace

/-- The standard normal distribution function is strictly increasing. -/
lemma gaussianReal_Iic_lt_of_lt {a b : ℝ} (hab : a < b) :
    gaussianReal 0 1 (Set.Iic a) < gaussianReal 0 1 (Set.Iic b) := by
  have hpos : 0 < gaussianReal 0 1 (Set.Ioc a b) := by
    rw [pos_iff_ne_zero]
    intro h
    have := gaussianReal_absolutelyContinuous' (0 : ℝ) (v := 1) one_ne_zero h
    simp [Real.volume_Ioc] at this
    linarith
  rw [← Set.Iic_union_Ioc_eq_Iic hab.le, measure_union (Set.Iic_disjoint_Ioc le_rfl)
    measurableSet_Ioc]
  exact ENNReal.lt_add_right (measure_ne_top _ _) hpos.ne'

lemma gaussianReal_Iic_le_iff (a b : ℝ) :
    gaussianReal 0 1 (Set.Iic a) ≤ gaussianReal 0 1 (Set.Iic b) ↔ a ≤ b := by
  constructor
  · intro h
    by_contra hc
    exact absurd h (not_le.mpr (gaussianReal_Iic_lt_of_lt (not_le.mp hc)))
  · intro h
    exact measure_mono (Set.Iic_subset_Iic.mpr h)

lemma gaussianReal_Iio_le_iff {ε z : ℝ} (hε1 : ε < 1)
    (hz : gaussianReal 0 1 (Set.Iic z) = ENNReal.ofReal (1 - ε)) (t : ℝ) :
    gaussianReal 0 1 (Set.Iio t) ≤ ENNReal.ofReal ε ↔ t ≤ -z := by
  have hneg : gaussianReal 0 1 (Set.Iio t) = gaussianReal 0 1 (Set.Ioi (-t)) := by
    conv_lhs => rw [← neg_zero, ← gaussianReal_map_neg (μ := (0:ℝ)) (v := 1)]
    rw [Measure.map_apply measurable_neg measurableSet_Iio]
    congr 1
    ext x; simp
  rw [hneg, ← Set.compl_Iic, prob_compl_eq_one_sub measurableSet_Iic]
  have hε : ENNReal.ofReal ε = 1 - ENNReal.ofReal (1 - ε) := by
    rw [← ENNReal.ofReal_one, ← ENNReal.ofReal_sub _ (by linarith)]
    congr 1; ring
  rw [hε, ← hz, ENNReal.sub_le_sub_iff_left prob_le_one ENNReal.one_ne_top,
    gaussianReal_Iic_le_iff]
  constructor <;> intro h <;> linarith

#print axioms gaussianReal_Iic_lt_of_lt
#print axioms gaussianReal_Iic_le_iff
#print axioms gaussianReal_Iio_le_iff

/-- Robust counterpart for a ball. Let the uncertainty set be every estimate list
`μ̂ + δ • u` with `‖u‖ ≤ 1`, a ball of radius `δ ≥ 0` around the analysts' estimates `μ̂`.
For any weight list `w`, the worst expected return `μᵀw` over that set exists and equals the
estimate's return minus the radius times the length of the weights:
`min over μ in U of μᵀw = μ̂ᵀw - δ‖w‖`. -/
theorem worst_case_over_ball_eq_estimate_minus_radius_times_length
    {ι : Type*} [Fintype ι] (μhat w : EuclideanSpace ℝ ι) {δ : ℝ} (hδ : 0 ≤ δ) :
    IsLeast ((fun μ => ⟪μ, w⟫) '' {μ | ∃ u : EuclideanSpace ℝ ι, ‖u‖ ≤ 1 ∧ μ = μhat + δ • u})
      (⟪μhat, w⟫ - δ * ‖w‖) := by
  constructor
  · by_cases hw : w = 0
    · refine ⟨μhat, ⟨0, by simp, by simp⟩, by simp [hw]⟩
    · have hn : ‖w‖ ≠ 0 := norm_ne_zero_iff.mpr hw
      refine ⟨μhat + δ • (-(‖w‖⁻¹ • w)), ⟨-(‖w‖⁻¹ • w), ?_, rfl⟩, ?_⟩
      · rw [norm_neg, norm_smul, norm_inv, norm_norm, inv_mul_cancel₀ hn]
      · simp only [inner_add_left, inner_smul_left, inner_neg_left, real_inner_self_eq_norm_sq,
          RCLike.conj_to_real]
        field_simp
        ring
  · rintro _ ⟨μ, ⟨u, hu, rfl⟩, rfl⟩
    simp only [inner_add_left, real_inner_smul_left]
    have h1 : -(‖u‖ * ‖w‖) ≤ ⟪u, w⟫ := by
      have := abs_real_inner_le_norm u w
      linarith [neg_abs_le ⟪u, w⟫]
    have h2 : ‖u‖ * ‖w‖ ≤ ‖w‖ := by
      have := norm_nonneg w
      nlinarith
    nlinarith

/-- The box contrast. If each estimate may be out by up to `δ ≥ 0`, all at the same time
(the set of `μ` with `|μ i - μ̂ i| ≤ δ` for every asset `i`), the worst expected return exists and
equals the estimate's return minus `δ` times the sum of the absolute weights. With no shorting and
full investment that sum is 1, so the box only subtracts `δ` from every plan and moves no weight. -/
theorem worst_case_over_box_eq_estimate_minus_radius_times_sum_abs
    {ι : Type*} [Fintype ι] (μhat w : ι → ℝ) {δ : ℝ} (hδ : 0 ≤ δ) :
    IsLeast ((fun μ : ι → ℝ => ∑ i, μ i * w i) '' {μ | ∀ i, |μ i - μhat i| ≤ δ})
      (∑ i, μhat i * w i - δ * ∑ i, |w i|) := by
  constructor
  · refine ⟨fun i => μhat i - δ * SignType.sign (w i), fun i => ?_, ?_⟩
    · simp only [sub_sub_cancel_left, abs_neg, abs_mul, abs_of_nonneg hδ]
      rcases lt_trichotomy (w i) 0 with h | h | h <;> simp [h, hδ]
    · simp only [Finset.mul_sum, ← Finset.sum_sub_distrib]
      refine Finset.sum_congr rfl fun i _ => ?_
      rcases lt_trichotomy (w i) 0 with h | h | h
      · simp [h, abs_of_neg h]; ring
      · simp [h]
      · simp [h, abs_of_pos h]; ring
  · rintro _ ⟨μ, hμ, rfl⟩
    simp only [Finset.mul_sum, ← Finset.sum_sub_distrib]
    refine Finset.sum_le_sum fun i _ => ?_
    have h := hμ i
    have : |(μ i - μhat i) * w i| ≤ δ * |w i| := by
      rw [abs_mul]; exact mul_le_mul_of_nonneg_right h (abs_nonneg _)
    have := neg_abs_le ((μ i - μhat i) * w i)
    nlinarith

/-- The normal chance constraint. Let the year's returns `ξ` be normal with mean `μ̂` and
covariance matrix `S`, and let `C` be any matrix with `C Cᵀ = S`. Let `0 < ε < 1` and let `z`
be the point with `1 - ε` of the standard bell-curve area to its left, `z = N⁻¹(1 - ε)`.
Then for any weights `w` and loss limit `ℓ`, the chance of losing more than `ℓ` is at most `ε`
exactly when the expected return, less `z` standard deviations `‖Cᵀw‖`, is at least `-ℓ`:
`Pr(ξᵀw < -ℓ) ≤ ε ↔ μ̂ᵀw - z‖Cᵀw‖ ≥ -ℓ`. -/
theorem normal_chance_constraint_iff_worst_case_over_ellipsoid
    {ι κ : Type*} [Fintype ι] [DecidableEq ι] [Fintype κ]
    (μhat w : EuclideanSpace ℝ ι) (S : Matrix ι ι ℝ) (C : Matrix ι κ ℝ) (hC : C * Cᵀ = S)
    {ε z ℓ : ℝ} (hε0 : 0 < ε) (hε1 : ε < 1)
    (hz : gaussianReal 0 1 (Set.Iic z) = ENNReal.ofReal (1 - ε)) :
    multivariateGaussian μhat S {ξ | ⟪ξ, w⟫ < -ℓ} ≤ ENNReal.ofReal ε ↔
      -ℓ ≤ ⟪μhat, w⟫ - z * ‖Matrix.toEuclideanLin Cᵀ w‖ := by
  have hS : S.PosSemidef := by
    rw [← hC]
    simpa [conjTranspose_eq_transpose_of_trivial] using posSemidef_self_mul_conjTranspose C
  set P := multivariateGaussian μhat S with hP
  set σ := ‖Matrix.toEuclideanLin Cᵀ w‖ with hσ
  set m := ⟪μhat, w⟫ with hm
  let L : StrongDual ℝ (EuclideanSpace ℝ ι) := innerSL ℝ w
  have hL : ∀ x, L x = ⟪x, w⟫ := fun x => by simp [L, real_inner_comm]
  have hmean : P[L] = m := by
    rw [L.integral_comp_id_comm IsGaussian.integrable_id, hP, integral_id_multivariateGaussian,
      hL]
  have hvar : Var[L; P] = σ ^ 2 := by
    have h1 := covarianceBilin_self (μ := P) IsGaussian.memLp_two_id w
    rw [hP, covarianceBilin_multivariateGaussian hS] at h1
    have h2 : (L : EuclideanSpace ℝ ι → ℝ) = fun u => ⟪w, u⟫ := by
      funext u; simp [L]
    rw [h2, ← h1, hσ, EuclideanSpace.norm_eq, Real.sq_sqrt (by positivity), ← hC]
    rw [← mulVec_mulVec, dotProduct_mulVec, ← mulVec_transpose]
    simp [Real.norm_eq_abs, dotProduct, pow_two]
  have hmap : P.map L = gaussianReal m (σ ^ 2).toNNReal := by
    rw [IsGaussian.map_eq_gaussianReal L, hmean, hvar]
  have hset : P {ξ | ⟪ξ, w⟫ < -ℓ} = gaussianReal m (σ ^ 2).toNNReal (Set.Iio (-ℓ)) := by
    rw [← hmap, Measure.map_apply L.continuous.measurable measurableSet_Iio]
    congr 1
    ext x; simp [hL]
  rw [hset]
  rcases (norm_nonneg (Matrix.toEuclideanLin Cᵀ w)).eq_or_lt with h0 | hpos
  · rw [← hσ] at h0
    have : ((σ ^ 2).toNNReal : NNReal) = 0 := by ext; simp [← h0]
    rw [this, gaussianReal_zero_var, Measure.dirac_apply' _ measurableSet_Iio, ← h0]
    by_cases hlt : m < -ℓ
    · simp only [Set.indicator_of_mem (Set.mem_Iio.mpr hlt), Pi.one_apply]
      constructor
      · intro h
        exfalso
        rw [← ENNReal.ofReal_one, ENNReal.ofReal_le_ofReal_iff hε0.le] at h
        linarith
      · intro h; linarith
    · simp only [Set.indicator_of_notMem (fun h => hlt (Set.mem_Iio.mp h)), zero_le, true_iff]
      linarith
  · rw [← hσ] at hpos
    have hg : gaussianReal m (σ ^ 2).toNNReal =
        ((gaussianReal 0 1).map (σ * ·)).map (m + ·) := by
      rw [gaussianReal_map_const_mul, gaussianReal_map_const_add]
      congr 1
      · simp
      · ext; simp [sq_nonneg]
    rw [hg, Measure.map_apply (measurable_const_add m) measurableSet_Iio,
      Measure.map_apply (measurable_const_mul σ) (measurableSet_Iio.preimage
        (measurable_const_add m))]
    have hpre : (σ * ·) ⁻¹' ((m + ·) ⁻¹' Set.Iio (-ℓ)) = Set.Iio ((-ℓ - m) / σ) := by
      ext x
      simp only [Set.mem_preimage, Set.mem_Iio]
      rw [lt_div_iff₀ hpos]
      constructor <;> intro h <;> linarith
    rw [hpre, gaussianReal_Iio_le_iff hε1 hz, div_le_iff₀ hpos]
    constructor <;> intro h <;> linarith

-- The card's figure: half the money in UK shares (estimate 7.0) and half in world shares
-- (estimate 7.4). The box's worst point is the corner, both a full point low: 6.2.
example : (7 : ℚ) * (1 / 2) + (37 / 5) * (1 / 2) - 1 * (|(1 / 2 : ℚ)| + |(1 / 2 : ℚ)|) = 31 / 5 := by
  norm_num
-- The same plan's squared length is 1/2, so the ball charges only 1/√2 of a point, not 1.
example : (1 / 2 : ℚ) ^ 2 + (1 / 2) ^ 2 = 1 / 2 := by norm_num
-- With no shorting and full investment, the box's bracket |w₁| + ... + |w₅| is 1, for example
-- for the even split of 1/5 in each asset.
example : 5 * |(1 / 5 : ℚ)| = 1 := by norm_num

#print axioms worst_case_over_ball_eq_estimate_minus_radius_times_length
#print axioms worst_case_over_box_eq_estimate_minus_radius_times_sum_abs
#print axioms normal_chance_constraint_iff_worst_case_over_ellipsoid
