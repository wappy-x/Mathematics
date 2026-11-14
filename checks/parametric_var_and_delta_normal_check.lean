-- Parametric VaR: if the risk-factor moves are jointly normal with mean zero, a book's linear P&L is normal with variance wᵀΣw, its loss quantile is z·√(wᵀΣw), the variance formula holds for any finite-variance factors, and component VaRs add back to the total.
import Mathlib.Probability.Distributions.Gaussian.HasGaussianLaw.Basic
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.LinearAlgebra.Matrix.Symmetric

open MeasureTheory ProbabilityTheory Matrix

lemma gaussianReal_real_Iic_neg_mul_sqrt (v : ℝ) (hv : 0 < v) (z : ℝ) :
    (gaussianReal 0 v.toNNReal).real (Set.Iic (-(z * Real.sqrt v)))
      = 1 - cdf (gaussianReal 0 1) z := by
  have hs : 0 < Real.sqrt v := Real.sqrt_pos.mpr hv
  have h1 : gaussianReal 0 v.toNNReal = (gaussianReal 0 1).map ((-Real.sqrt v) * ·) := by
    rw [gaussianReal_map_const_mul]
    congr 1
    · simp
    · ext; simp [Real.sq_sqrt hv.le, hv.le]
  have hpre : ((-Real.sqrt v) * ·) ⁻¹' Set.Iic (-(z * Real.sqrt v)) = Set.Ici z := by
    ext y
    simp only [Set.mem_preimage, Set.mem_Iic, Set.mem_Ici]
    constructor
    · intro h; nlinarith
    · intro h; nlinarith
  have hnull : NullSingletonClass (gaussianReal 0 (1 : NNReal)) :=
    nullSingletonClass_gaussianReal one_ne_zero
  rw [h1, map_measureReal_apply (by fun_prop) measurableSet_Iic, hpre, cdf_eq_real,
    ← Set.compl_Iio, probReal_compl_eq_one_sub measurableSet_Iio,
    measureReal_congr Iio_ae_eq_Iic]

#print axioms gaussianReal_real_Iic_neg_mul_sqrt

lemma variance_weighted_sum_aux
    {Ω ι : Type*} [MeasurableSpace Ω] [Fintype ι] {P : Measure Ω} [IsProbabilityMeasure P]
    (x : ι → Ω → ℝ) (hx : ∀ i, MemLp (x i) 2 P) (w : ι → ℝ) :
    Var[fun ω ↦ ∑ i, w i * x i ω; P] = ∑ i, ∑ j, w i * w j * cov[x i, x j; P] := by
  rw [variance_fun_sum (X := fun i ω ↦ w i * x i ω) (fun i ↦ (hx i).const_mul (w i))]
  refine Finset.sum_congr rfl fun i _ ↦ Finset.sum_congr rfl fun j _ ↦ ?_
  rw [covariance_const_mul_left, covariance_const_mul_right]
  ring

#print axioms variance_weighted_sum_aux

/-- Delta-normal VaR. Let the daily risk-factor moves `x i` be jointly normal with mean zero,
and let the book's one-day P&L be the straight-line sum `ΔV = ∑ i, w i * x i`. Write
`σ_P² = ∑ i, ∑ j, w i * w j * cov(x i, x j)` (that is, `wᵀ Σ w`), and assume it is positive.
Then `ΔV` is a bell curve with mean zero and variance `σ_P²`, and if `N(z) = c`
(for 99% VaR, `c = 99/100` and `z ≈ 2.33`), the chance of losing at least `z * σ_P` is `1 - c`:
the `c`-level VaR is `z * σ_P`. -/
theorem delta_normal_var_eq_z_mul_sigma
    {Ω ι : Type*} [MeasurableSpace Ω] [Fintype ι] {P : Measure Ω} [IsProbabilityMeasure P]
    (x : ι → Ω → ℝ) (hx : HasGaussianLaw (fun ω i ↦ x i ω) P)
    (hmean : ∀ i, P[x i] = 0)
    (w : ι → ℝ) (hσ : 0 < ∑ i, ∑ j, w i * w j * cov[x i, x j; P])
    (z c : ℝ) (hz : cdf (gaussianReal 0 1) z = c) :
    P.map (fun ω ↦ ∑ i, w i * x i ω)
        = gaussianReal 0 (∑ i, ∑ j, w i * w j * cov[x i, x j; P]).toNNReal ∧
      P.real {ω | ∑ i, w i * x i ω ≤ -(z * Real.sqrt (∑ i, ∑ j, w i * w j * cov[x i, x j; P]))}
        = 1 - c := by
  have hS : HasGaussianLaw (fun ω ↦ ∑ i, w i * x i ω) P := by
    have := hx.map_fun (∑ i, w i • ContinuousLinearMap.proj (R := ℝ) (φ := fun _ : ι ↦ ℝ) i)
    convert this using 2 with ω
    simp
  have hxi : ∀ i, HasGaussianLaw (x i) P := fun i ↦ hx.eval i
  have hmap : P.map (fun ω ↦ ∑ i, w i * x i ω)
      = gaussianReal 0 (∑ i, ∑ j, w i * w j * cov[x i, x j; P]).toNNReal := by
    rw [hS.map_eq_gaussianReal,
      variance_weighted_sum_aux x (fun i ↦ (hxi i).memLp_two) w]
    congr 1
    rw [integral_finsetSum _ (fun i _ ↦ ((hxi i).integrable).const_mul (w i))]
    simp [integral_const_mul, hmean]
  refine ⟨hmap, ?_⟩
  rw [← hz, ← gaussianReal_real_Iic_neg_mul_sqrt _ hσ z, ← hmap,
    map_measureReal_apply_of_aemeasurable hS.aemeasurable measurableSet_Iic]
  rfl

/-- The spread of a weighted sum. For any factor moves with finite variances (no normality
needed), the variance of the P&L `∑ i, w i * x i` is the sum over all pairs of
`w i * w j * cov(x i, x j)`, that is, `wᵀ Σ w`. -/
theorem variance_weighted_sum_eq_quadratic_form
    {Ω ι : Type*} [MeasurableSpace Ω] [Fintype ι] {P : Measure Ω} [IsProbabilityMeasure P]
    (x : ι → Ω → ℝ) (hx : ∀ i, MemLp (x i) 2 P) (w : ι → ℝ) :
    Var[fun ω ↦ ∑ i, w i * x i ω; P] = ∑ i, ∑ j, w i * w j * cov[x i, x j; P] := by
  exact variance_weighted_sum_aux x hx w

/-- Component VaR adds back to the total. Let `VaR(w) = z * √(wᵀ Σ w)` for a symmetric
covariance matrix `Σ` and exposures `w` with `wᵀ Σ w > 0`. The rate at which VaR changes as
exposure `i` grows is `z * (Σ w)_i / σ_P`, and the components `w i * z * (Σ w)_i / σ_P`
sum exactly to the total VaR `z * σ_P`. -/
theorem component_var_sum_eq_var
    {n : ℕ} (S : Matrix (Fin n) (Fin n) ℝ) (hS : S.IsSymm) (w : Fin n → ℝ)
    (hpos : 0 < w ⬝ᵥ (S *ᵥ w)) (z : ℝ) :
    (∀ i, HasDerivAt
        (fun t : ℝ ↦ z * Real.sqrt ((w + t • Pi.single i 1) ⬝ᵥ (S *ᵥ (w + t • Pi.single i 1))))
        (z * (S *ᵥ w) i / Real.sqrt (w ⬝ᵥ (S *ᵥ w))) 0) ∧
      ∑ i, w i * (z * (S *ᵥ w) i / Real.sqrt (w ⬝ᵥ (S *ᵥ w)))
        = z * Real.sqrt (w ⬝ᵥ (S *ᵥ w)) := by
  have hs : 0 < Real.sqrt (w ⬝ᵥ (S *ᵥ w)) := Real.sqrt_pos.mpr hpos
  refine ⟨fun i ↦ ?_, ?_⟩
  · set e : Fin n → ℝ := Pi.single i 1
    have hq : (fun t : ℝ ↦ (w + t • e) ⬝ᵥ (S *ᵥ (w + t • e)))
        = fun t ↦ w ⬝ᵥ (S *ᵥ w) + t * (e ⬝ᵥ (S *ᵥ w) + w ⬝ᵥ (S *ᵥ e))
            + t * t * (e ⬝ᵥ (S *ᵥ e)) := by
      ext t
      simp only [mulVec_add, mulVec_smul, add_dotProduct, dotProduct_add, smul_dotProduct,
        dotProduct_smul, smul_eq_mul]
      ring
    have hwe : w ⬝ᵥ (S *ᵥ e) = (S *ᵥ w) i := by
      rw [dotProduct_mulVec, ← mulVec_transpose, hS.eq, dotProduct_comm, single_dotProduct,
        one_mul]
    have hew : e ⬝ᵥ (S *ᵥ w) = (S *ᵥ w) i := by
      rw [single_dotProduct, one_mul]
    have hd : HasDerivAt (fun t : ℝ ↦ (w + t • e) ⬝ᵥ (S *ᵥ (w + t • e)))
        (2 * (S *ᵥ w) i) 0 := by
      rw [hq]
      have h1 := (hasDerivAt_id' (0 : ℝ)).mul_const (e ⬝ᵥ (S *ᵥ w) + w ⬝ᵥ (S *ᵥ e))
      have h2 := ((hasDerivAt_id' (0 : ℝ)).mul (hasDerivAt_id' (0 : ℝ))).mul_const
        (e ⬝ᵥ (S *ᵥ e))
      refine (((hasDerivAt_const (0 : ℝ) (w ⬝ᵥ (S *ᵥ w))).add h1).add h2).congr_deriv ?_
      rw [hwe, hew]; ring
    have h0 : (w + (0 : ℝ) • e) ⬝ᵥ (S *ᵥ (w + (0 : ℝ) • e)) ≠ 0 := by
      simpa using hpos.ne'
    have := (hd.sqrt h0).const_mul z
    convert this using 1
    simp only [zero_smul, add_zero]
    field_simp
  · simp_rw [← mul_div_assoc]
    rw [← Finset.sum_div]
    have : ∑ i, w i * (z * (S *ᵥ w) i) = z * (w ⬝ᵥ (S *ᵥ w)) := by
      simp only [dotProduct, Finset.mul_sum]
      refine Finset.sum_congr rfl fun i _ ↦ ?_
      ring
    rw [this, div_eq_iff hs.ne']
    conv_lhs => rw [← Real.sq_sqrt hpos.le]
    ring

-- The card's whole-number worked examples (decimals written as exact fractions).
-- Bond PV01: 5 × $5,000,000 × 0.0001 = $2,500 per basis point.
example : (5 : ℚ) * 5000000 * (1 / 10000) = 2500 := by norm_num
-- Dollar volatility of the shares: $10,000,000 × 1.35% = $135,000.
example : (10000000 : ℚ) * (135 / 10000) = 135000 := by norm_num
-- Dollar volatility of the bond: −$2,500 × 6 bp = −$15,000.
example : (-2500 : ℤ) * 6 = -15000 := by norm_num
-- Shares squared and bond squared.
example : (135000 : ℤ) * 135000 = 18225000000 := by norm_num
example : (15000 : ℤ) * 15000 = 225000000 := by norm_num
-- Shares with bond: 2 × 0.2 × 135,000 × (−15,000) = −810,000,000.
example : 2 * (1 / 5 : ℚ) * 135000 * (-15000) = -810000000 := by norm_num
-- The calls cover 1,000 contracts × 100 shares = 100,000 Acme shares.
example : (1000 : ℕ) * 100 = 100000 := by decide

#print axioms delta_normal_var_eq_z_mul_sigma
#print axioms variance_weighted_sum_eq_quadratic_form
#print axioms component_var_sum_eq_var
