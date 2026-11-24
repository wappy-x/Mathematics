-- Change of variables for Lebesgue measure: a matrix multiplies the volume of every Borel set by |det A|, a C^1 diffeomorphism moves integrals by the determinant of its Jacobian matrix, and the unit sphere and ball in R^n have area 2π^(n/2)/Γ(n/2) and volume π^(n/2)/Γ(n/2 + 1).
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Constructions.HaarToSphere
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic

open MeasureTheory Matrix

/-- Linear maps: for every n by n matrix `A` and every Borel set `E` in `ℝⁿ`, the Lebesgue
measure of the image `A(E)` is `|det A|` times the Lebesgue measure of `E`. -/
theorem volume_image_matrix_eq_abs_det_mul {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (E : Set (Fin n → ℝ)) (hE : MeasurableSet E) :
    volume ((fun x => A *ᵥ x) '' E) = ENNReal.ofReal |A.det| * volume E := by
  have h := Measure.addHaar_image_linearMap (volume : Measure (Fin n → ℝ)) (Matrix.toLin' A) E
  rw [LinearMap.det_toLin'] at h
  rw [← h]
  rfl

/-- Smooth maps: if `T` is a `C¹` diffeomorphism from an open set `U` onto an open set `V` of `ℝⁿ`
(one-to-one onto `V`, with a `C¹` inverse `S`), then for every integrable `f` on `V`,
`∫_V f(y) dy = ∫_U f(T x) |det DT(x)| dx`, where `DT(x)` is the Jacobian matrix of `T` at `x`. -/
theorem integral_diffeomorph_eq_integral_abs_det_jacobian {n : ℕ}
    (T S : (Fin n → ℝ) → (Fin n → ℝ)) (U V : Set (Fin n → ℝ))
    (hU : IsOpen U) (hV : IsOpen V)
    (hTmaps : Set.MapsTo T U V) (hSmaps : Set.MapsTo S V U)
    (hleft : Set.LeftInvOn S T U) (hright : Set.RightInvOn S T V)
    (hT : ContDiffOn ℝ 1 T U) (hS : ContDiffOn ℝ 1 S V)
    (f : (Fin n → ℝ) → ℝ) (hf : IntegrableOn f V) :
    ∫ y in V, f y =
      ∫ x in U, f (T x) *
        |(LinearMap.toMatrix' (fderiv ℝ T x : (Fin n → ℝ) →ₗ[ℝ] (Fin n → ℝ))).det| := by
  have himg : T '' U = V := by
    apply Set.Subset.antisymm (hTmaps.image_subset)
    intro y hy
    exact ⟨S y, hSmaps hy, hright hy⟩
  have hd : ∀ x ∈ U, HasFDerivWithinAt T (fderiv ℝ T x) U x := fun x hx =>
    ((hT.differentiableOn one_ne_zero x hx).differentiableAt
      (hU.mem_nhds hx)).hasFDerivAt.hasFDerivWithinAt
  have hinj : Set.InjOn T U := hleft.injOn
  rw [← himg, integral_image_eq_integral_abs_det_fderiv_smul volume hU.measurableSet hd hinj f]
  refine setIntegral_congr_fun hU.measurableSet (fun x _ => ?_)
  simp only [smul_eq_mul, LinearMap.det_toMatrix']
  rw [mul_comm]

/-- Sphere and ball: in `ℝⁿ`, surface measure `σ` on the unit sphere (a set of directions gets
`n` times the volume of its cone) gives the whole sphere `σ(Sⁿ⁻¹) = 2π^(n/2)/Γ(n/2)`, and the
ball of radius 1 has volume `Vₙ = π^(n/2)/Γ(n/2 + 1)`. -/
theorem sphere_area_and_unit_ball_volume (n : ℕ) :
    (volume : Measure (EuclideanSpace ℝ (Fin n))).toSphere Set.univ =
        ENNReal.ofReal (2 * Real.pi ^ ((n : ℝ) / 2) / Real.Gamma ((n : ℝ) / 2)) ∧
      volume (Metric.ball (0 : EuclideanSpace ℝ (Fin n)) 1) =
        ENNReal.ofReal (Real.pi ^ ((n : ℝ) / 2) / Real.Gamma ((n : ℝ) / 2 + 1)) := by
  have hball : volume (Metric.ball (0 : EuclideanSpace ℝ (Fin n)) 1) =
        ENNReal.ofReal (Real.pi ^ ((n : ℝ) / 2) / Real.Gamma ((n : ℝ) / 2 + 1)) := by
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · have : Metric.ball (0 : EuclideanSpace ℝ (Fin 0)) 1 = Set.univ := by
        ext x; simp [Subsingleton.elim x 0]
      rw [this, ← (PiLp.volume_preserving_toLp (Fin 0)).measure_preimage
        MeasurableSet.univ.nullMeasurableSet, Set.preimage_univ, volume_pi, Measure.pi_univ]
      simp
    · have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
      rw [EuclideanSpace.volume_ball, Fintype.card_fin, ENNReal.ofReal_one, one_pow, one_mul]
      congr 2
      rw [Real.sqrt_eq_rpow, ← Real.rpow_natCast, ← Real.rpow_mul Real.pi_pos.le]
      ring_nf
  refine ⟨?_, hball⟩
  rw [Measure.toSphere_apply_univ, finrank_euclideanSpace, Fintype.card_fin, hball]
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  · have hn' : ((n : ℝ) / 2) ≠ 0 := by positivity
    rw [Real.Gamma_add_one hn', ← ENNReal.ofReal_natCast, ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    have hG : 0 < Real.Gamma ((n : ℝ) / 2) := Real.Gamma_pos_of_pos (by positivity)
    field_simp

-- The card's matrix A = [[3, 1], [0, 2]] has determinant 6.
example : Matrix.det !![(3 : ℤ), 1; 0, 2] = 6 := by norm_num [Matrix.det_fin_two_of]
-- The columns swapped, [[1, 3], [2, 0]], has determinant -6, and the area factor is |-6| = 6.
example : Matrix.det !![(1 : ℤ), 3; 2, 0] = -6 := by norm_num [Matrix.det_fin_two_of]
example : |Matrix.det !![(1 : ℤ), 3; 2, 0]| = 6 := by norm_num [Matrix.det_fin_two_of]
-- A sends the corners (1, 0), (1, 1), (0, 1) of the unit square to (3, 0), (4, 2), (1, 2).
example : !![(3 : ℤ), 1; 0, 2] *ᵥ ![1, 0] = ![3, 0] := by decide
example : !![(3 : ℤ), 1; 0, 2] *ᵥ ![1, 1] = ![4, 2] := by decide
example : !![(3 : ℤ), 1; 0, 2] *ᵥ ![0, 1] = ![1, 2] := by decide
-- Stretch by 3 and 2, then the shear [[1, 1/2], [0, 1]], gives A.
example : !![(1 : ℚ), 1 / 2; 0, 1] * !![3, 0; 0, 2] = !![3, 1; 0, 2] := by
  norm_num [Matrix.mul_fin_two]
-- Γ(6) = 5! = 120, the denominator of V₁₀ = π⁵/120.
example : Real.Gamma 6 = 120 := by
  norm_num [show (6 : ℝ) = (5 : ℕ) + 1 by norm_num, Real.Gamma_nat_eq_factorial, Nat.factorial]

#print axioms volume_image_matrix_eq_abs_det_mul
#print axioms integral_diffeomorph_eq_integral_abs_det_jacobian
#print axioms sphere_area_and_unit_ball_volume
