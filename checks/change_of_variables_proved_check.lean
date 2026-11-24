-- Change of variables in n dimensions, proved: for a one-to-one C¹ map with nonzero Jacobian determinant on a Jordan region, the total of a continuous f over the places equals the total over the addresses weighted by |det J_T|, a linear map scales every volume by |det L|, and the round shaft's polar moment is exactly 8π.
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FinCases
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory Set Real

/-- **Change of variables in n dimensions.** A map T sends an address u, a list of n numbers,
to a place T(u). Its Jacobian matrix J_T(u) holds its partial derivatives: the entry in row i,
column j is ∂T_i/∂u_j, which is Mathlib's `LinearMap.toMatrix'` of the derivative
`fderiv ℝ T u`. Suppose:
* T is one-to-one on A;
* T has continuous partial derivatives (it is C¹) on an open set U holding A and its edge;
* det J_T is nonzero on U;
* A is a Jordan region: it is bounded and its edge has zero content (the edge is closed and
  bounded, so zero content is the same as zero volume);
* f is continuous on the places T covers from A and its edge.
Then the total of f over the places equals the total over the addresses, each address weighted
by f at its place and by the size of the Jacobian determinant there:
∫ over T(A) of f(x) dx = ∫ over A of f(T(u)) · |det J_T(u)| du. -/
theorem integral_image_eq_integral_comp_mul_abs_det_jacobian_jordan {n : ℕ}
    (T : (Fin n → ℝ) → (Fin n → ℝ)) (A U : Set (Fin n → ℝ)) (f : (Fin n → ℝ) → ℝ)
    (hinj : InjOn T A)
    (hU : IsOpen U) (hAU : closure A ⊆ U) (hT : ContDiffOn ℝ 1 T U)
    (hdet : ∀ u ∈ U,
      (LinearMap.toMatrix' (fderiv ℝ T u : (Fin n → ℝ) →ₗ[ℝ] (Fin n → ℝ))).det ≠ 0)
    (hA : Bornology.IsBounded A) (hedge : volume (frontier A) = 0)
    (hf : ContinuousOn f (T '' closure A)) :
    ∫ x in T '' A, f x =
      ∫ u in A, f (T u) *
        |(LinearMap.toMatrix' (fderiv ℝ T u : (Fin n → ℝ) →ₗ[ℝ] (Fin n → ℝ))).det| := by
  have hdiff : DifferentiableOn ℝ T U := hT.differentiableOn one_ne_zero
  -- A and its interior differ by a subset of the edge
  have hsub : A \ interior A ⊆ frontier A := by
    intro x ⟨hxA, hxi⟩; exact ⟨subset_closure hxA, hxi⟩
  have hAe : (interior A : Set _) =ᵐ[volume] A := by
    refine (ae_eq_set).2 ⟨by simp [sdiff_eq_empty.2 interior_subset], ?_⟩
    exact measure_mono_null hsub hedge
  have hfrU : frontier A ⊆ U := (frontier_subset_closure).trans hAU
  have himg_null : volume (T '' (A \ interior A)) = 0 := by
    have h0 : volume (A \ interior A) = 0 := measure_mono_null hsub hedge
    exact addHaar_image_eq_zero_of_differentiableOn_of_addHaar_eq_zero volume
      (hdiff.mono (hsub.trans hfrU)) h0
  have hTe : (T '' interior A : Set _) =ᵐ[volume] T '' A := by
    refine (ae_eq_set).2 ⟨by simp [sdiff_eq_empty.2 (image_mono interior_subset)], ?_⟩
    refine measure_mono_null ?_ himg_null
    rintro y ⟨⟨x, hxA, rfl⟩, hy⟩
    exact ⟨x, ⟨hxA, fun hxi => hy ⟨x, hxi, rfl⟩⟩, rfl⟩
  rw [← setIntegral_congr_set hTe, ← setIntegral_congr_set hAe]
  have hder : ∀ x ∈ interior A, HasFDerivWithinAt T (fderiv ℝ T x) (interior A) x := by
    intro x hx
    have hxU : x ∈ U := hAU (subset_closure (interior_subset hx))
    exact ((hdiff x hxU).differentiableAt (hU.mem_nhds hxU)).hasFDerivAt.hasFDerivWithinAt
  rw [integral_image_eq_integral_abs_det_fderiv_smul volume isOpen_interior.measurableSet hder
    (hinj.mono interior_subset)]
  refine integral_congr_ae (Filter.Eventually.of_forall fun u => ?_)
  simp only [smul_eq_mul, LinearMap.det_toMatrix', ContinuousLinearMap.det]
  ring

/-- **Linear maps scale volume by the size of the determinant.** For every n × n matrix L,
the linear map u ↦ L u sends any set A of addresses to a set whose volume is |det L| times the
volume of A. For the card's L, with rows (2, 1) and (0, 3), the unit square goes to a
parallelogram of area 6. -/
theorem volume_linear_image_eq_abs_det_mul {n : ℕ} (L : Matrix (Fin n) (Fin n) ℝ)
    (A : Set (Fin n → ℝ)) :
    volume (Matrix.toLin' L '' A) = ENNReal.ofReal |L.det| * volume A := by
  rw [Measure.addHaar_image_linearMap, LinearMap.det_toLin']

/-- **The shaft's polar moment.** The total of the squared distance x² + y² over the solid
round cross-section of radius 2 (the points with x² + y² ≤ 4) is exactly 8π: in polar
coordinates it is the integral of r² · r = r³, which is 2π × 2⁴/4. -/
theorem shaft_polar_moment :
    ∫ p in {p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ 4}, (p.1 ^ 2 + p.2 ^ 2) = 8 * π := by
  rw [← integral_indicator (measurableSet_le (by fun_prop) (by fun_prop)),
    ← integral_comp_polarCoord_symm, polarCoord_target]
  have key : ∀ q ∈ Ioi (0:ℝ) ×ˢ Ioo (-π) π,
      q.1 • ({p : ℝ × ℝ | p.1 ^ 2 + p.2 ^ 2 ≤ 4}.indicator (fun p => p.1 ^ 2 + p.2 ^ 2))
        (polarCoord.symm q) = (Iic (2:ℝ)).indicator (fun r => r ^ 3) q.1 * (1:ℝ) := by
    rintro ⟨r, θ⟩ ⟨hr, -⟩
    simp only [mem_Ioi] at hr
    have h : (r * cos θ) ^ 2 + (r * sin θ) ^ 2 = r ^ 2 := by
      have := sin_sq_add_cos_sq θ; nlinarith
    simp only [polarCoord_symm_apply, indicator, mem_ofPred_eq, mem_Iic, h, smul_eq_mul, mul_one]
    by_cases h2 : r ≤ 2
    · have : r ^ 2 ≤ 4 := by nlinarith
      simp [h2, this]; ring
    · have : ¬ r ^ 2 ≤ 4 := by nlinarith
      simp [h2, this]
  have hp := setIntegral_prod_mul (μ := (volume : Measure ℝ)) (ν := (volume : Measure ℝ))
    ((Iic (2:ℝ)).indicator (fun r => r ^ 3)) (fun _ : ℝ => (1:ℝ)) (Ioi 0) (Ioo (-π) π)
  rw [setIntegral_congr_fun (measurableSet_Ioi.prod measurableSet_Ioo) key,
    Measure.volume_eq_prod, hp]
  rw [setIntegral_indicator measurableSet_Iic, setIntegral_const]
  have hI : Ioi (0:ℝ) ∩ Iic 2 = Ioc 0 2 := Ioi_inter_Iic
  rw [hI, ← intervalIntegral.integral_of_le (by norm_num), integral_pow]
  simp [Real.volume_real_Ioo_of_le (by linarith [pi_pos] : -π ≤ π)]
  ring

-- L is the shear (add y/3 to x) after the stretch (x by 2, y by 3).
example : !![(1 : ℚ), 1 / 3; 0, 1] * !![2, 0; 0, 3] = !![2, 1; 0, 3] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- det of the stretch S is 2 × 3 = 6, det of the shear H is 1, det L is 6.
example : Matrix.det !![(2 : ℚ), 0; 0, 3] = 6 := by norm_num [Matrix.det_fin_two_of]
example : Matrix.det !![(1 : ℚ), 1 / 3; 0, 1] = 1 := by norm_num [Matrix.det_fin_two_of]
example : Matrix.det !![(2 : ℚ), 1; 0, 3] = 6 := by norm_num [Matrix.det_fin_two_of]
-- A swap after L has det -6.
example : Matrix.det !![(0 : ℚ), 3; 2, 1] = -6 := by norm_num [Matrix.det_fin_two_of]
-- Shoelace on the corners (0, 0), (2, 0), (3, 3), (1, 3) gives area 6.
example : ((0 * 0 - 2 * 0) + (2 * 3 - 3 * 0) + (3 * 3 - 1 * 3) + (1 * 0 - 0 * 3) : ℚ) / 2 = 6 := by
  norm_num
-- Mistake: side lengths multiplied give √4 × √10 = √40, not 6, since 4 × 10 ≠ 6².
example : (2 ^ 2 + 0 ^ 2) * (1 ^ 2 + 3 ^ 2) ≠ (6 : ℕ) ^ 2 := by norm_num
-- x² + y² in addresses: (2u + v)² + 9v² = 4u² + 4uv + 10v².
example (u v : ℚ) : (2 * u + v) ^ 2 + (3 * v) ^ 2 = 4 * u ^ 2 + 4 * u * v + 10 * v ^ 2 := by ring
-- Over the unit square: 4/3 + 4 × 1/4 + 10/3 = 17/3; the plate's polar moment is 6 × 17/3 = 34.
example : (4 / 3 + 4 * (1 / 4) + 10 / 3 : ℚ) = 17 / 3 := by norm_num
example : (6 * (17 / 3) : ℚ) = 34 := by norm_num
-- Shaft: the radial total 2⁴/4 is 4.
example : ((2 : ℚ) ^ 4 / 4) = 4 := by norm_num

#print axioms integral_image_eq_integral_comp_mul_abs_det_jacobian_jordan
#print axioms volume_linear_image_eq_abs_det_mul
#print axioms shaft_polar_moment
