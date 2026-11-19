-- Lie algebra: exp of a skew-symmetric 3 by 3 matrix is a rotation given by Rodrigues' formula, and the bracket of two turn rates is their cross product.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Series
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Algebra.Lie.OfAssociative

open Matrix NormedSpace

/-! Here `LinearMap.toMatrix' (crossProduct ω)` is the card's `[ω]×`: the matrix that sends
every vector `v` to the cross product `ω × v`. The Euclidean length of `ω` is `√(ω ⬝ᵥ ω)`.
The bracket `⁅X, Y⁆` on matrices is Mathlib's commutator `X * Y - Y * X`. -/

open scoped Nat


theorem crossMatrix_smul (c : ℝ) (ω : Fin 3 → ℝ) :
    LinearMap.toMatrix' (crossProduct (c • ω)) = c • LinearMap.toMatrix' (crossProduct ω) := by
  rw [map_smul, map_smul]

theorem crossMatrix_eq (n : Fin 3 → ℝ) :
    LinearMap.toMatrix' (crossProduct n) = !![0, -n 2, n 1; n 2, 0, -n 0; -n 1, n 0, 0] := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [LinearMap.toMatrix'_apply, cross_apply]

theorem crossMatrix_pow_three (n : Fin 3 → ℝ) :
    LinearMap.toMatrix' (crossProduct n) ^ 3 = -(n ⬝ᵥ n) • LinearMap.toMatrix' (crossProduct n) := by
  rw [crossMatrix_eq, pow_succ, pow_two]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [dotProduct, Fin.sum_univ_three] <;> ring

theorem exp_smul_of_pow_three (K : Matrix (Fin 3) (Fin 3) ℝ) (hK : K ^ 3 = -K) (θ : ℝ) :
    exp (θ • K) = 1 + Real.sin θ • K + (1 - Real.cos θ) • K ^ 2 := by
  have hodd : ∀ k : ℕ, K ^ (2 * k + 1) = (-1 : ℝ) ^ k • K := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      rw [show 2 * (k + 1) + 1 = (2 * k + 1) + 2 by ring, pow_add, ih, smul_mul_assoc,
        ← pow_succ' K 2, hK, pow_succ, smul_neg, ← neg_smul, mul_neg_one]
  have heven : ∀ k : ℕ, K ^ (2 * (k + 1)) = (-1 : ℝ) ^ k • K ^ 2 := by
    intro k
    rw [show 2 * (k + 1) = (2 * k + 1) + 1 by ring, pow_succ, hodd, smul_mul_assoc, sq]
  rw [exp_eq_tsum ℝ]
  refine HasSum.tsum_eq ?_
  have h0 : HasSum (fun k : ℕ => if k = 0 then (1 + K ^ 2) else 0) (1 + K ^ 2) :=
    hasSum_ite_eq 0 (1 + K ^ 2)
  have hc : HasSum (fun k : ℕ => ((-1) ^ k * θ ^ (2 * k) / ↑(2 * k)!) • (-K ^ 2)) (Real.cos θ • (-K ^ 2)) :=
    (Real.hasSum_cos θ).smul_const (-K ^ 2)
  have hs : HasSum (fun k : ℕ => ((-1) ^ k * θ ^ (2 * k + 1) / ↑(2 * k + 1)!) • K) (Real.sin θ • K) :=
    (Real.hasSum_sin θ).smul_const K
  have hval : (1 : Matrix (Fin 3) (Fin 3) ℝ) + Real.sin θ • K + (1 - Real.cos θ) • K ^ 2 =
      (Real.cos θ • (-K ^ 2) + (1 + K ^ 2)) + Real.sin θ • K := by
    module
  rw [hval]
  refine HasSum.even_add_odd ?_ ?_
  · convert hc.add h0 using 1
    ext k : 1
    rcases k with _ | k
    · simp
    · rw [smul_pow, heven, ite_eq_right (Nat.succ_ne_zero k), add_zero]
      simp only [div_eq_mul_inv]
      module
  · convert hs using 1
    ext k : 1
    rw [smul_pow, hodd]
    simp only [div_eq_mul_inv]
    module

#print axioms crossMatrix_smul
#print axioms crossMatrix_eq
#print axioms crossMatrix_pow_three
#print axioms exp_smul_of_pow_three

/-- Exp of a skew-symmetric matrix is a rotation: if the 3 by 3 real matrix `X` satisfies
`Xᵀ = -X`, then `exp X` is in `SO(3)`, that is, `(exp X)ᵀ * exp X = I` and `det (exp X) = 1`. -/
theorem exp_mem_specialOrthogonalGroup_of_skew (X : Matrix (Fin 3) (Fin 3) ℝ) (hX : Xᵀ = -X) :
    exp X ∈ Matrix.specialOrthogonalGroup (Fin 3) ℝ := by
  have hO : (exp X)ᵀ * exp X = 1 := by
    rw [← Matrix.exp_transpose, hX, Matrix.exp_neg]
    exact Matrix.nonsing_inv_mul _ ((Matrix.isUnit_iff_isUnit_det _).mp (Matrix.isUnit_exp _))
  rw [Matrix.mem_specialOrthogonalGroup_iff]
  refine ⟨(Matrix.mem_orthogonalGroup_iff' (Fin 3) ℝ).mpr hO, ?_⟩
  have hdet2 : (exp X).det * (exp X).det = 1 := by
    rw [← det_one (n := Fin 3) (R := ℝ), ← hO, det_mul, det_transpose]
  have hhalf : X = 2 • ((1 / 2 : ℝ) • X) := by
    rw [two_nsmul, ← add_smul]; norm_num
  have hsq : (exp X).det = (exp ((1 / 2 : ℝ) • X)).det ^ 2 := by
    conv_lhs => rw [hhalf]
    rw [Matrix.exp_nsmul, det_pow]
  nlinarith [sq_nonneg (exp ((1 / 2 : ℝ) • X)).det]

/-- Rodrigues' formula: a turn rate `ω` held for time `t` gives the finished turn
`exp (t [ω]×) = I + sin θ K + (1 - cos θ) K²`, where `θ = |ω| t` is the angle and
`K = [n]×` for the unit axis `n = ω / |ω|`. -/
theorem rodrigues_formula (ω : Fin 3 → ℝ) (t : ℝ) :
    exp (t • LinearMap.toMatrix' (crossProduct ω)) =
      1 + Real.sin (√(ω ⬝ᵥ ω) * t) • LinearMap.toMatrix' (crossProduct ((√(ω ⬝ᵥ ω))⁻¹ • ω))
        + (1 - Real.cos (√(ω ⬝ᵥ ω) * t)) •
            LinearMap.toMatrix' (crossProduct ((√(ω ⬝ᵥ ω))⁻¹ • ω)) ^ 2 := by
  have hnn : 0 ≤ ω ⬝ᵥ ω := Finset.sum_nonneg fun i _ => mul_self_nonneg (ω i)
  by_cases hs : √(ω ⬝ᵥ ω) = 0
  · have h0 : ω ⬝ᵥ ω = 0 := (Real.sqrt_eq_zero hnn).mp hs
    have hω : ω = 0 := by
      simp only [dotProduct, Fin.sum_univ_three] at h0
      have e0 : ω 0 = 0 := by nlinarith [mul_self_nonneg (ω 0), mul_self_nonneg (ω 1), mul_self_nonneg (ω 2)]
      have e1 : ω 1 = 0 := by nlinarith [mul_self_nonneg (ω 0), mul_self_nonneg (ω 1), mul_self_nonneg (ω 2)]
      have e2 : ω 2 = 0 := by nlinarith [mul_self_nonneg (ω 0), mul_self_nonneg (ω 1), mul_self_nonneg (ω 2)]
      funext i
      fin_cases i <;> simp [e0, e1, e2]
    subst hω
    simp
  · have hss : √(ω ⬝ᵥ ω) * √(ω ⬝ᵥ ω) = ω ⬝ᵥ ω := Real.mul_self_sqrt hnn
    have hK : LinearMap.toMatrix' (crossProduct ((√(ω ⬝ᵥ ω))⁻¹ • ω)) ^ 3 =
        -LinearMap.toMatrix' (crossProduct ((√(ω ⬝ᵥ ω))⁻¹ • ω)) := by
      rw [crossMatrix_pow_three]
      have h1 : ((√(ω ⬝ᵥ ω))⁻¹ • ω) ⬝ᵥ ((√(ω ⬝ᵥ ω))⁻¹ • ω) = 1 := by
        rw [dotProduct_smul, smul_dotProduct, smul_eq_mul, smul_eq_mul]
        have key : ∀ s d : ℝ, s ≠ 0 → s * s = d → s⁻¹ * (s⁻¹ * d) = 1 := by
          intro s d hs h
          subst h
          field_simp
        exact key _ _ hs hss
      rw [h1, neg_smul, one_smul]
    rw [← exp_smul_of_pow_three _ hK, crossMatrix_smul, smul_smul]
    congr 2
    generalize √(ω ⬝ᵥ ω) = s at hs ⊢
    field_simp

/-- The bracket of two turn rates is their cross product: `[[a]×, [b]×] = [a × b]×`. -/
theorem lie_crossMatrix_eq_crossMatrix_cross (a b : Fin 3 → ℝ) :
    ⁅LinearMap.toMatrix' (crossProduct a), LinearMap.toMatrix' (crossProduct b)⁆ =
      LinearMap.toMatrix' (crossProduct (a ⨯₃ b)) := by
  rw [Ring.lie_def, crossMatrix_eq, crossMatrix_eq, crossMatrix_eq]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cross_apply] <;> ring

/-! Worked examples from the card, checked exactly. -/

-- The unit roll rate `Lx = [(1, 0, 0)]×` written out as a matrix.
example : LinearMap.toMatrix' (crossProduct (![1, 0, 0] : Fin 3 → ℤ)) =
    !![0, 0, 0; 0, 0, -1; 0, 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [LinearMap.toMatrix'_apply, cross_apply]

-- The unit roll, pitch and yaw rates and their bracket table.
-- `[Lx, Ly] = Lz`
example : ⁅!![(0 : ℤ), 0, 0; 0, 0, -1; 0, 1, 0], !![(0 : ℤ), 0, 1; 0, 0, 0; -1, 0, 0]⁆ =
    !![(0 : ℤ), -1, 0; 1, 0, 0; 0, 0, 0] := by
  decide
-- `[Ly, Lz] = Lx`
example : ⁅!![(0 : ℤ), 0, 1; 0, 0, 0; -1, 0, 0], !![(0 : ℤ), -1, 0; 1, 0, 0; 0, 0, 0]⁆ =
    !![(0 : ℤ), 0, 0; 0, 0, -1; 0, 1, 0] := by
  decide
-- `[Lz, Lx] = Ly`
example : ⁅!![(0 : ℤ), -1, 0; 1, 0, 0; 0, 0, 0], !![(0 : ℤ), 0, 0; 0, 0, -1; 0, 1, 0]⁆ =
    !![(0 : ℤ), 0, 1; 0, 0, 0; -1, 0, 0] := by
  decide

-- The gyro rate ω = (0.3, 0.4, 1.2) rad/s has size 1.3 rad/s: ω ⬝ ω = 1.69 = 1.3².
example : (![3/10, 2/5, 6/5] : Fin 3 → ℚ) ⬝ᵥ ![3/10, 2/5, 6/5] = (13/10) ^ 2 := by
  norm_num [dotProduct, Fin.sum_univ_three]

-- The unit axis is (3, 4, 12)/13, since 3² + 4² + 12² = 13².
example : (3 : ℕ) ^ 2 + 4 ^ 2 + 12 ^ 2 = 13 ^ 2 := by
  decide

-- ω × g for the gimbal's pitch rate g = (0, 0.5, 0) is (-0.6, 0, 0.15).
example : (![3/10, 2/5, 6/5] : Fin 3 → ℚ) ⨯₃ ![0, 1/2, 0] = ![-3/5, 0, 3/20] := by
  norm_num [cross_apply]

-- Swapping the gimbal's axis to a yaw rate (0, 0, 0.5) gives ω × g = (0.2, -0.15, 0).
example : (![3/10, 2/5, 6/5] : Fin 3 → ℚ) ⨯₃ ![0, 0, 1/2] = ![1/5, -3/20, 0] := by
  norm_num [cross_apply]

#print axioms exp_mem_specialOrthogonalGroup_of_skew
#print axioms rodrigues_formula
#print axioms lie_crossMatrix_eq_crossMatrix_cross
