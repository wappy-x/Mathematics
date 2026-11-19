-- Rotation group: the quaternion cos(θ/2) + sin(θ/2)u turns a vector by Rodrigues' formula as v ↦ q v q̄, every rotation of space fixes an axis, and slerp stays on the unit sphere at angle tΩ from its start.
import Mathlib.Algebra.Quaternion
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv

open Matrix Quaternion

/-- A vector `v = (v_x, v_y, v_z)` as the pure quaternion `v_x i + v_y j + v_z k`. -/
def vecQ (v : Fin 3 → ℝ) : ℍ[ℝ] := ⟨0, v 0, v 1, v 2⟩

/-- The unit quaternion of a turn by `θ` about the axis `u`:
`cos(θ/2) + sin(θ/2)(u_x i + u_y j + u_z k)`. -/
noncomputable def axisAngleQ (u : Fin 3 → ℝ) (θ : ℝ) : ℍ[ℝ] :=
  ⟨Real.cos (θ / 2), Real.sin (θ / 2) * u 0, Real.sin (θ / 2) * u 1, Real.sin (θ / 2) * u 2⟩

/-- The dot product of two quaternions as points of four-dimensional space. -/
def qdot (p q : ℍ[ℝ]) : ℝ := p.re * q.re + p.imI * q.imI + p.imJ * q.imJ + p.imK * q.imK

/-- The card's main claim: for a unit axis `u` and any angle `θ`, the quaternion
`q = cos(θ/2) + sin(θ/2)u` has length 1, and the sandwich `v ↦ q v q̄` is the turn by `θ`
about `u` given by Rodrigues' formula `v + sin θ (u × v) + (1 - cos θ) u × (u × v)`. -/
theorem quaternion_sandwich_is_rodrigues_turn (u v : Fin 3 → ℝ) (θ : ℝ) (hu : u ⬝ᵥ u = 1) :
    Quaternion.normSq (axisAngleQ u θ) = 1 ∧
    axisAngleQ u θ * vecQ v * star (axisAngleQ u θ) =
      vecQ (v + Real.sin θ • (u ⨯₃ v) + (1 - Real.cos θ) • (u ⨯₃ (u ⨯₃ v))) := by
  have hu' : u 0 * u 0 + u 1 * u 1 + u 2 * u 2 = 1 := by
    simpa [dotProduct, Fin.sum_univ_three] using hu
  have hθ : θ = 2 * (θ / 2) := by ring
  have hs : Real.sin θ = 2 * Real.sin (θ / 2) * Real.cos (θ / 2) := by
    rw [hθ, Real.sin_two_mul]; ring_nf
  have hc : Real.cos θ = 1 - 2 * Real.sin (θ / 2) ^ 2 := by
    rw [hθ, Real.cos_two_mul, ← Real.sin_sq_add_cos_sq (2 * (θ / 2) / 2)]; ring_nf
  have hsc := Real.sin_sq_add_cos_sq (θ / 2)
  refine ⟨?_, ?_⟩
  · rw [Quaternion.normSq_def']
    simp only [axisAngleQ]
    linear_combination hsc + Real.sin (θ / 2) ^ 2 * hu'
  · rw [hs, hc]
    set s := Real.sin (θ / 2)
    set c := Real.cos (θ / 2)
    ext <;> simp only [axisAngleQ, vecQ, cross_apply, Quaternion.re_mul, Quaternion.imI_mul,
      Quaternion.imJ_mul, Quaternion.imK_mul, Quaternion.re_star, Quaternion.imI_star,
      Quaternion.imJ_star, Quaternion.imK_star, Pi.add_apply, Pi.smul_apply, smul_eq_mul,
      Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_two, Matrix.head_cons,
      Matrix.tail_cons]
    · ring
    · linear_combination (v 0) * hsc + (v 0) * s ^ 2 * hu'
    · linear_combination (v 1) * hsc + (v 1) * s ^ 2 * hu'
    · linear_combination (v 2) * hsc + (v 2) * s ^ 2 * hu'

/-- Euler's rotation theorem: every rotation of space, a 3 by 3 real matrix `R` with
`Rᵀ R = I` and `det R = 1`, fixes some nonzero vector, its axis. -/
theorem every_rotation_has_an_axis (R : Matrix (Fin 3) (Fin 3) ℝ)
    (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    ∃ v : Fin 3 → ℝ, v ≠ 0 ∧ R *ᵥ v = v := by
  rw [Matrix.mem_specialOrthogonalGroup_iff, Matrix.mem_orthogonalGroup_iff] at hR
  obtain ⟨hO, hdet⟩ := hR
  have key : (R - 1).det = 0 := by
    have h1 : R - 1 = R * (1 - Rᵀ) := by
      rw [Matrix.mul_sub, Matrix.mul_one]
      have : R * Rᵀ = 1 := by simpa [Matrix.star_eq_conjTranspose] using hO
      rw [this]
    have h2 : (R - 1).det = -(R - 1).det := by
      calc (R - 1).det = (R * (1 - Rᵀ)).det := by rw [h1]
        _ = (1 - R).det := by
          rw [Matrix.det_mul, hdet, one_mul, ← Matrix.det_transpose]
          simp [Matrix.transpose_sub]
        _ = (-(R - 1)).det := by rw [neg_sub]
        _ = -(R - 1).det := by
          rw [Matrix.det_neg]; simp [Fintype.card_fin]; norm_num
    linarith
  obtain ⟨v, hv, hRv⟩ := Matrix.exists_mulVec_eq_zero_iff.mpr key
  refine ⟨v, hv, ?_⟩
  rw [Matrix.sub_mulVec, Matrix.one_mulVec, sub_eq_zero] at hRv
  exact hRv

/-- Slerp walks the great circle: for unit quaternions `q_A`, `q_B` an angle `Ω` apart,
`cos Ω = q_A · q_B` with `0 < Ω < π`, the blend
`(sin((1 - t)Ω) q_A + sin(tΩ) q_B) / sin Ω` has length 1, lies at angle `tΩ` from `q_A`
and at angle `(1 - t)Ω` from `q_B`. -/
theorem slerp_is_unit_at_angle (qA qB : ℍ[ℝ]) (Ω t : ℝ)
    (hA : Quaternion.normSq qA = 1) (hB : Quaternion.normSq qB = 1)
    (hΩ : Real.cos Ω = qdot qA qB) (hΩ0 : 0 < Ω) (hΩπ : Ω < Real.pi) :
    let p : ℍ[ℝ] := (Real.sin ((1 - t) * Ω) / Real.sin Ω) • qA + (Real.sin (t * Ω) / Real.sin Ω) • qB
    Quaternion.normSq p = 1 ∧ qdot p qA = Real.cos (t * Ω) ∧ qdot p qB = Real.cos ((1 - t) * Ω) := by
  intro p
  have hS : 0 < Real.sin Ω := Real.sin_pos_of_pos_of_lt_pi hΩ0 hΩπ
  have hS' : Real.sin Ω ≠ 0 := hS.ne'
  rw [Quaternion.normSq_def'] at hA hB
  simp only [qdot] at hΩ
  have e1 : (1 - t) * Ω = Ω - t * Ω := by ring
  simp only [p]
  rw [e1, Real.sin_sub, Real.cos_sub]
  set x := t * Ω
  have hx := Real.sin_sq_add_cos_sq x
  have hO := Real.sin_sq_add_cos_sq Ω
  refine ⟨?_, ?_, ?_⟩
  · rw [Quaternion.normSq_def']
    simp only [Quaternion.re_add, Quaternion.imI_add, Quaternion.imJ_add, Quaternion.imK_add,
      Quaternion.re_smul, Quaternion.imI_smul, Quaternion.imJ_smul, Quaternion.imK_smul, smul_eq_mul]
    field_simp
    linear_combination (Real.sin Ω * Real.cos x - Real.cos Ω * Real.sin x) ^ 2 * hA - 2 * (Real.sin Ω * Real.cos x - Real.cos Ω * Real.sin x) * Real.sin x * hΩ + Real.sin x ^ 2 * hB - Real.sin x ^ 2 * hO
      + Real.sin Ω ^ 2 * hx
  · simp only [qdot, Quaternion.re_add, Quaternion.imI_add, Quaternion.imJ_add, Quaternion.imK_add,
      Quaternion.re_smul, Quaternion.imI_smul, Quaternion.imJ_smul, Quaternion.imK_smul, smul_eq_mul]
    field_simp
    linear_combination (Real.sin Ω * Real.cos x - Real.cos Ω * Real.sin x) * hA - Real.sin x * hΩ
  · simp only [qdot, Quaternion.re_add, Quaternion.imI_add, Quaternion.imJ_add, Quaternion.imK_add,
      Quaternion.re_smul, Quaternion.imI_smul, Quaternion.imJ_smul, Quaternion.imK_smul, smul_eq_mul]
    field_simp
    linear_combination -(Real.sin Ω * Real.cos x - Real.cos Ω * Real.sin x) * hΩ + Real.sin x * hB - Real.sin x * hO

/-- The quaternion units: `i² = j² = k² = ijk = -1`. -/
example : (⟨0, 1, 0, 0⟩ : ℍ[ℝ]) * ⟨0, 1, 0, 0⟩ = -1 ∧
    (⟨0, 0, 1, 0⟩ : ℍ[ℝ]) * ⟨0, 0, 1, 0⟩ = -1 ∧
    (⟨0, 0, 0, 1⟩ : ℍ[ℝ]) * ⟨0, 0, 0, 1⟩ = -1 ∧
    (⟨0, 1, 0, 0⟩ : ℍ[ℝ]) * ⟨0, 0, 1, 0⟩ * ⟨0, 0, 0, 1⟩ = -1 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> ext <;> norm_num

/-- `ij = k` and `ji = -k`: order matters. -/
example : (⟨0, 1, 0, 0⟩ : ℍ[ℝ]) * ⟨0, 0, 1, 0⟩ = ⟨0, 0, 0, 1⟩ ∧
    (⟨0, 0, 1, 0⟩ : ℍ[ℝ]) * ⟨0, 1, 0, 0⟩ = ⟨0, 0, 0, -1⟩ := by
  refine ⟨?_, ?_⟩ <;> ext <;> norm_num

/-- A 360° turn about the down axis gives `q = -1`; a 720° turn gives `q = +1`. -/
example : axisAngleQ ![0, 0, 1] (2 * Real.pi) = -1 ∧ axisAngleQ ![0, 0, 1] (4 * Real.pi) = 1 := by
  refine ⟨?_, ?_⟩ <;> ext <;>
    norm_num [axisAngleQ, show 2 * Real.pi / 2 = Real.pi by ring,
      show 4 * Real.pi / 2 = 2 * Real.pi by ring]

#print axioms quaternion_sandwich_is_rodrigues_turn
#print axioms every_rotation_has_an_axis
#print axioms slerp_is_unit_at_angle
