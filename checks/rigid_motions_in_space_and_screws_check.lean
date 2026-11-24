-- Rigid motions in space: every turn of space in SO(3) leaves a direction alone (Euler's axis theorem), and every proper rigid motion x ↦ R x + t of space is a screw, a turn about one line plus a slide along it (Chasles's theorem).
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.LinearAlgebra.Matrix.Adjugate
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.ToLinearEquiv
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Algebra.Order.Star.Real
import Mathlib.Tactic.Module
import Mathlib.Tactic.LinearCombination

open Matrix

lemma rot_tR {R : Matrix (Fin 3) (Fin 3) ℝ} (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    Rᵀ * R = 1 :=
  (Matrix.mem_orthogonalGroup_iff' (Fin 3) ℝ).mp ((Matrix.mem_specialOrthogonalGroup_iff.mp hR).1)

lemma rot_Rt {R : Matrix (Fin 3) (Fin 3) ℝ} (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    R * Rᵀ = 1 :=
  (Matrix.mem_orthogonalGroup_iff (Fin 3) ℝ).mp ((Matrix.mem_specialOrthogonalGroup_iff.mp hR).1)

lemma rot_det {R : Matrix (Fin 3) (Fin 3) ℝ} (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    R.det = 1 :=
  (Matrix.mem_specialOrthogonalGroup_iff.mp hR).2

lemma rot_det_sub_one {R : Matrix (Fin 3) (Fin 3) ℝ}
    (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) : (R - 1).det = 0 := by
  have h1 : R - 1 = -(R * (R - 1)ᵀ) := by
    rw [transpose_sub, transpose_one, mul_sub, rot_Rt hR, mul_one, neg_sub]
  have h2 : (R - 1).det = -(R - 1).det := by
    conv_lhs => rw [h1]
    rw [det_neg, det_mul, det_transpose, rot_det hR]
    simp
    ring
  linarith

lemma ch_identity_fin_three (A : Matrix (Fin 3) (Fin 3) ℝ) :
    A * A - A.trace • A + (adjugate A).trace • (1 : Matrix (Fin 3) (Fin 3) ℝ) - adjugate A = 0 := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [adjugate_fin_three, Matrix.mul_apply, Fin.sum_univ_three, Matrix.trace_fin_three] <;> ring

lemma rot_adjugate {R : Matrix (Fin 3) (Fin 3) ℝ}
    (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) : adjugate R = Rᵀ := by
  calc adjugate R = adjugate R * (R * Rᵀ) := by rw [rot_Rt hR, mul_one]
    _ = (adjugate R * R) * Rᵀ := by rw [mul_assoc]
    _ = Rᵀ := by rw [adjugate_mul, rot_det hR, one_smul, one_mul]

lemma rot_sq {R : Matrix (Fin 3) (Fin 3) ℝ} (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    R * R = R.trace • R - R.trace • (1 : Matrix (Fin 3) (Fin 3) ℝ) + Rᵀ := by
  have h := ch_identity_fin_three R
  rw [rot_adjugate hR, trace_transpose] at h
  rw [← sub_eq_zero, ← h]
  abel

/-- `S = R + Rᵀ - (tr R - 1) I` is fixed by `R` on the left. -/
lemma rot_mul_S {R : Matrix (Fin 3) (Fin 3) ℝ} (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    R * (R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ)) =
      R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ) := by
  rw [mul_sub, mul_add, rot_sq hR, rot_Rt hR, mul_smul_comm, mul_one]
  module

lemma S_eq {R : Matrix (Fin 3) (Fin 3) ℝ} (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ) =
      R * R - (R.trace - 1) • R + 1 := by
  rw [rot_sq hR]
  module

lemma S_mul_S {R : Matrix (Fin 3) (Fin 3) ℝ} (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    (R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ)) *
      (R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ)) =
      (3 - R.trace) • (R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ)) := by
  set S := R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ) with hS
  have h1 : R * S = S := rot_mul_S hR
  have h2 : Rᵀ * S = S := by
    calc Rᵀ * S = Rᵀ * (R * S) := by rw [h1]
      _ = S := by rw [← mul_assoc, rot_tR hR, one_mul]
  calc S * S = R * S + Rᵀ * S - (R.trace - 1) • S := by
        rw [hS, sub_mul, add_mul, smul_mul_assoc, one_mul]
    _ = (3 - R.trace) • S := by rw [h1, h2]; module

lemma S_transpose (R : Matrix (Fin 3) (Fin 3) ℝ) :
    (R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ))ᵀ =
      R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ) := by
  rw [transpose_sub, transpose_add, transpose_transpose, transpose_smul, transpose_one]
  abel

lemma S_trace (R : Matrix (Fin 3) (Fin 3) ℝ) :
    (R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ)).trace = 3 - R.trace := by
  rw [trace_sub, trace_add, trace_smul, trace_one, trace_transpose]
  simp
  ring

lemma rot_eq_one_of_trace {R : Matrix (Fin 3) (Fin 3) ℝ}
    (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) (h : R.trace = 3) : R = 1 := by
  have key : ((R - 1)ᴴ * (R - 1)).trace = 0 := by
    rw [conjTranspose_eq_transpose_of_trivial, transpose_sub, transpose_one, sub_mul, mul_sub,
      mul_sub, rot_tR hR, mul_one, one_mul, mul_one, trace_sub, trace_sub, trace_sub,
      trace_transpose, h, trace_one]
    simp
  exact sub_eq_zero.mp (trace_conjTranspose_mul_self_eq_zero_iff.mp key)

lemma dot_sym_mulVec (P : Matrix (Fin 3) (Fin 3) ℝ) (hP : Pᵀ = P) (x y : Fin 3 → ℝ) :
    x ⬝ᵥ (P *ᵥ y) = (P *ᵥ x) ⬝ᵥ y := by
  rw [dotProduct_mulVec, ← vecMul_transpose, hP]

lemma normalize_facts (n t : Fin 3 → ℝ) (hn : n ≠ 0) :
    ((Real.sqrt (n ⬝ᵥ n))⁻¹ • n) ⬝ᵥ ((Real.sqrt (n ⬝ᵥ n))⁻¹ • n) = 1 ∧
      (t ⬝ᵥ ((Real.sqrt (n ⬝ᵥ n))⁻¹ • n)) • ((Real.sqrt (n ⬝ᵥ n))⁻¹ • n) =
        ((t ⬝ᵥ n) / (n ⬝ᵥ n)) • n := by
  have hpos : 0 < n ⬝ᵥ n := by
    rcases (dotProduct_self_star_nonneg n).lt_or_eq with h | h
    · simpa using h
    · exact absurd (dotProduct_self_eq_zero.mp (by simpa using h.symm)) hn
  have hs : Real.sqrt (n ⬝ᵥ n) * Real.sqrt (n ⬝ᵥ n) = n ⬝ᵥ n := Real.mul_self_sqrt hpos.le
  have hsne : Real.sqrt (n ⬝ᵥ n) ≠ 0 := (Real.sqrt_pos.mpr hpos).ne'
  constructor
  · rw [smul_dotProduct, dotProduct_smul, smul_eq_mul, smul_eq_mul, ← mul_assoc]
    field_simp
    linarith
  · rw [dotProduct_smul, smul_smul, smul_eq_mul]
    congr 1
    field_simp
    rw [Real.sq_sqrt hpos.le]
    ring

/-- Chasles's theorem. Every rigid motion of space without a mirror, `x ↦ R x + t` with `R` a
3 × 3 rotation matrix (`Rᵀ R = I`, `det R = 1`), is a screw: there is an axis direction `u` of
length 1 that `R` leaves alone, a point `c` on the axis, and a slide `s = t · u` such that the
move is a turn about the line through `c` in direction `u` followed by a slide `s` along it. -/
theorem every_rigid_motion_is_a_screw (R : Matrix (Fin 3) (Fin 3) ℝ)
    (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) (t : Fin 3 → ℝ) :
    ∃ (u c : Fin 3 → ℝ) (s : ℝ), u ⬝ᵥ u = 1 ∧ R *ᵥ u = u ∧ s = t ⬝ᵥ u ∧
      ∀ x : Fin 3 → ℝ, R *ᵥ x + t = R *ᵥ (x - c) + c + s • u := by
  by_cases h3 : R.trace = 3
  · -- R is the identity: slide straight along `t`.
    have hR1 : R = 1 := rot_eq_one_of_trace hR h3
    subst hR1
    by_cases ht : t = 0
    · subst ht
      refine ⟨Pi.single 0 1, 0, 0, ?_, ?_, ?_, ?_⟩
      · simp
      · rw [one_mulVec]
      · simp
      · intro x; simp
    · obtain ⟨hu, hproj⟩ := normalize_facts t t ht
      refine ⟨(Real.sqrt (t ⬝ᵥ t))⁻¹ • t, 0, _, hu, by simp, rfl, ?_⟩
      intro x
      have htt : t ⬝ᵥ t ≠ 0 := fun h => ht (dotProduct_self_eq_zero.mp h)
      rw [hproj, div_self htt, one_smul]
      simp
  · have h3' : (3 - R.trace) ≠ 0 := sub_ne_zero.mpr (Ne.symm h3)
    set S := R + Rᵀ - (R.trace - 1) • (1 : Matrix (Fin 3) (Fin 3) ℝ) with hS
    set P := (3 - R.trace)⁻¹ • S with hP
    have hRP : R * P = P := by rw [hP, mul_smul_comm, rot_mul_S hR]
    have hPP : P * P = P := by
      rw [hP, smul_mul_smul_comm, S_mul_S hR, smul_smul]
      congr 1
      field_simp
    have hPt : Pᵀ = P := by rw [hP, transpose_smul, S_transpose]
    have hPtr : P.trace = 1 := by
      rw [hP, trace_smul, S_trace, smul_eq_mul, inv_mul_cancel₀ h3']
    -- A vector `v` with `P v ≠ 0` that gives the right axis.
    have hPne : ∃ v, P *ᵥ v ≠ 0 ∧ ((t ⬝ᵥ (P *ᵥ v)) / ((P *ᵥ v) ⬝ᵥ (P *ᵥ v))) • (P *ᵥ v) = P *ᵥ t := by
      by_cases ht : P *ᵥ t = 0
      · have : ∃ v, P *ᵥ v ≠ 0 := by
          by_contra hc
          push Not at hc
          have hP0 : P = 0 := by
            ext i j
            have := congrFun (hc (Pi.single j 1)) i
            simpa [mulVec_single_one] using this
          rw [hP0, trace_zero] at hPtr
          exact zero_ne_one hPtr
        obtain ⟨v, hv⟩ := this
        refine ⟨v, hv, ?_⟩
        rw [dot_sym_mulVec P hPt, ht]
        simp
      · refine ⟨t, ht, ?_⟩
        have e1 : (P *ᵥ t) ⬝ᵥ (P *ᵥ t) = t ⬝ᵥ (P *ᵥ t) := by
          rw [dot_sym_mulVec P hPt, mulVec_mulVec, hPP, dotProduct_comm]
        have hne : (P *ᵥ t) ⬝ᵥ (P *ᵥ t) ≠ 0 := fun h => ht (dotProduct_self_eq_zero.mp h)
        rw [← e1, div_self hne, one_smul]
    obtain ⟨v, hv, hproj⟩ := hPne
    obtain ⟨hu, hproj2⟩ := normalize_facts (P *ᵥ v) t hv
    set u := (Real.sqrt ((P *ᵥ v) ⬝ᵥ (P *ᵥ v)))⁻¹ • (P *ᵥ v) with hu_def
    have hRu : R *ᵥ u = u := by rw [hu_def, mulVec_smul, mulVec_mulVec, hRP]
    have hsu : (t ⬝ᵥ u) • u = P *ᵥ t := by rw [hproj2, hproj]
    -- The part of `t` across the axis.
    set w := t - P *ᵥ t with hw
    have hPw : P *ᵥ w = 0 := by
      rw [hw, mulVec_sub, mulVec_mulVec, hPP, sub_self]
    have hSw : S *ᵥ w = 0 := by
      have : S = (3 - R.trace) • P := by rw [hP, smul_smul, mul_inv_cancel₀ h3', one_smul]
      rw [this, smul_mulVec, hPw, smul_zero]
    have hRRw : R *ᵥ (R *ᵥ w) = (R.trace - 1) • (R *ᵥ w) - w := by
      have h := hSw
      rw [hS, S_eq hR, add_mulVec, sub_mulVec, smul_mulVec, one_mulVec,
        ← mulVec_mulVec] at h
      rw [← sub_eq_zero, ← h]
      abel
    set β := (3 - R.trace)⁻¹ with hβ
    set α := 1 - β with hα
    set c := α • w + β • (R *ᵥ w) with hc
    have hcRc : c - R *ᵥ c = w := by
      have hb : β * (3 - R.trace) = 1 := inv_mul_cancel₀ h3'
      calc c - R *ᵥ c
          = (α + β) • w + (β - α - β * (R.trace - 1)) • (R *ᵥ w) := by
            rw [hc, mulVec_add, mulVec_smul, mulVec_smul, hRRw]
            module
        _ = w := by
            have e1 : α + β = 1 := by rw [hα]; ring
            have e2 : β - α - β * (R.trace - 1) = 0 := by
              rw [hα]; linear_combination hb
            rw [e1, e2, one_smul, zero_smul, add_zero]
    refine ⟨u, c, t ⬝ᵥ u, hu, hRu, rfl, ?_⟩
    intro x
    rw [hsu, mulVec_sub]
    have : t = (c - R *ᵥ c) + P *ᵥ t := by rw [hcRc, hw, sub_add_cancel]
    conv_lhs => rw [this]
    abel

/-- Euler's axis theorem. Every 3 × 3 rotation matrix leaves some nonzero direction alone:
1 is an eigenvalue of `R`. -/
theorem euler_axis_theorem (R : Matrix (Fin 3) (Fin 3) ℝ)
    (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    ∃ u : Fin 3 → ℝ, u ≠ 0 ∧ R *ᵥ u = u := by
  obtain ⟨v, hv, h⟩ := Matrix.exists_mulVec_eq_zero_iff.mpr (rot_det_sub_one hR)
  refine ⟨v, hv, ?_⟩
  rw [sub_mulVec, one_mulVec, sub_eq_zero] at h
  exact h

/-- The key step of Euler's theorem: for a 3 × 3 rotation matrix, `det (R - I) = 0`,
because it equals its own negative in three dimensions. -/
theorem det_rotation_sub_one_eq_zero (R : Matrix (Fin 3) (Fin 3) ℝ)
    (hR : R ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ) :
    (R - 1).det = 0 := by
  exact rot_det_sub_one hR

/-! The card's worked numbers: the drone's turn sends (x, y, z) to (-y, x, z), shift (1, 0, 2). -/

-- The drone's turn is a rotation matrix: Rᵀ R = I and det R = 1.
example : (!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ)ᵀ *
    !![0, -1, 0; 1, 0, 0; 0, 0, 1] = 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_three]

example : (!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ).det = 1 := by
  simp [Matrix.det_fin_three]

-- The drone at (2, 3, 5) ends at (-2, 2, 7).
example : (!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ) *ᵥ ![2, 3, 5]
    + ![1, 0, 2] = ![-2, 2, 7] := by
  ext i; fin_cases i <;> norm_num

-- The trace is 0 + 0 + 1 = 1, so cos θ = 0: a 90° turn.
example : (!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ).trace = 1 := by
  simp [Matrix.trace_fin_three]

-- det (R - I) = 0 for the drone's turn.
example : ((!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ) - 1).det = 0 := by
  rw [Matrix.det_fin_three]; simp

-- The axis direction u = (0, 0, 1) is left alone, and the slide is t · u = 2.
example : (!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ) *ᵥ ![0, 0, 1]
    = ![0, 0, 1] := by
  ext i; fin_cases i <;> simp

example : (![1, 0, 2] : Fin 3 → ℝ) ⬝ᵥ ![0, 0, 1] = 2 := by
  simp [dotProduct, Fin.sum_univ_three]

-- The axis point c = (1/2, 1/2, 0) solves (I - R) c = t⊥ = (1, 0, 0).
example : (1 - (!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ)) *ᵥ ![1/2, 1/2, 0]
    = ![1, 0, 0] := by
  ext i; fin_cases i <;> norm_num [Matrix.sub_mulVec]

-- The screw rebuilds the move at every point: R x + t = R (x - c) + c + 2 u.
example (x : Fin 3 → ℝ) : (!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ) *ᵥ x
    + ![1, 0, 2] = (!![0, -1, 0; 1, 0, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℝ) *ᵥ
      (x - ![1/2, 1/2, 0]) + ![1/2, 1/2, 0] + (2 : ℝ) • ![0, 0, 1] := by
  ext i; fin_cases i <;>
    simp [dotProduct, Fin.sum_univ_three, Matrix.vecHead, Matrix.vecTail]
  ring

-- The camera mount x → y → z → x: trace 0 (a 120° turn), and it leaves (1, 1, 1) alone.
example : (!![0, 0, 1; 1, 0, 0; 0, 1, 0] : Matrix (Fin 3) (Fin 3) ℝ).trace = 0 := by
  simp [Matrix.trace_fin_three]

example : (!![0, 0, 1; 1, 0, 0; 0, 1, 0] : Matrix (Fin 3) (Fin 3) ℝ) *ᵥ ![1, 1, 1]
    = ![1, 1, 1] := by
  ext i; fin_cases i <;> simp

#print axioms every_rigid_motion_is_a_screw
#print axioms euler_axis_theorem
#print axioms det_rotation_sub_one_eq_zero
#print axioms rot_tR
#print axioms rot_Rt
#print axioms rot_det
#print axioms rot_det_sub_one
#print axioms ch_identity_fin_three
#print axioms rot_adjugate
#print axioms rot_sq
#print axioms rot_mul_S
#print axioms S_eq
#print axioms S_mul_S
#print axioms S_transpose
#print axioms S_trace
#print axioms rot_eq_one_of_trace
#print axioms dot_sym_mulVec
#print axioms normalize_facts
