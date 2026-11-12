-- The Kalman filter: for any prior covariance, any linear reading and any positive reading noise, the gain P Hᵀ S⁻¹ gives the smallest error covariance of every linear correction, that smallest covariance is (I - K H) P, and in precision form the precisions add.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation

open Matrix

lemma kf_alg {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m]
    [DecidableEq m] (P : Matrix n n ℝ) (H : Matrix m n ℝ) (R S Si : Matrix m m ℝ)
    (K : Matrix n m ℝ) (hPt : Pᵀ = P) (hSit : Siᵀ = Si) (h1 : Si * S = 1) (h2 : S * Si = 1)
    (hS : S = H * P * Hᵀ + R) :
    (1 - K * H) * P * (1 - K * H)ᵀ + K * R * Kᵀ =
        (P - P * Hᵀ * Si * H * P) + (K - P * Hᵀ * Si) * S * (K - P * Hᵀ * Si)ᵀ := by
  have hR : R = S - H * P * Hᵀ := by rw [hS]; abel
  subst hR
  have e1 : ∀ X : Matrix m n ℝ, S * (Si * X) = X := fun X => by rw [← Matrix.mul_assoc, h2, Matrix.one_mul]
  have e2 : ∀ X : Matrix m n ℝ, Si * (S * X) = X := fun X => by rw [← Matrix.mul_assoc, h1, Matrix.one_mul]
  simp only [Matrix.mul_sub, Matrix.sub_mul, transpose_sub, transpose_mul, transpose_one, transpose_transpose, hPt, hSit,
    Matrix.mul_one, Matrix.one_mul, Matrix.mul_assoc, e1, e2]
  abel

lemma kf_eq_zero_of_posDef {m : Type*} [Fintype m] [DecidableEq m] (S : Matrix m m ℝ) (hS : S.PosDef) {n : Type*} [Fintype n]
   (D : Matrix n m ℝ) (h : D * S * Dᵀ = 0) : D = 0 := by
  ext i j
  have hi : D i = 0 := by
    by_contra hne
    have := hS.dotProduct_mulVec_pos hne
    have e : (D * S * Dᵀ) i i = ∑ x, ∑ y, D i x * (S x y * D i y) := by
      simp only [Matrix.mul_apply, Matrix.transpose_apply, Finset.sum_mul]
      rw [Finset.sum_comm]
      refine Finset.sum_congr rfl fun x _ => Finset.sum_congr rfl fun y _ => by ring
    simp [dotProduct, mulVec, Finset.mul_sum] at this
    have h0 : ∑ x, ∑ y, D i x * (S x y * D i y) = 0 := by rw [← e, h]; rfl
    linarith
  simp [hi]

lemma kf_woodbury {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m]
    [DecidableEq m] (P Pi : Matrix n n ℝ) (H : Matrix m n ℝ) (R Ri S Si : Matrix m m ℝ)
    (hP : P * Pi = 1) (hR : R * Ri = 1) (h1 : Si * S = 1)
    (hS : S = H * P * Hᵀ + R) :
    (P - P * Hᵀ * Si * H * P) * (Pi + Hᵀ * Ri * H) = 1 := by
  have e : Si * (H * P * Hᵀ) = 1 - Si * R := by
    rw [show H * P * Hᵀ = S - R by rw [hS]; abel, Matrix.mul_sub, h1]
  have e' : P * Hᵀ * Si * H * P * Hᵀ * Ri * H = P * Hᵀ * Ri * H - P * Hᵀ * Si * H := by
    calc P * Hᵀ * Si * H * P * Hᵀ * Ri * H = P * Hᵀ * (Si * (H * P * Hᵀ)) * Ri * H := by
          simp only [Matrix.mul_assoc]
      _ = _ := by
          rw [e, Matrix.mul_sub, Matrix.sub_mul, Matrix.sub_mul, Matrix.mul_one]
          simp only [Matrix.mul_assoc, hR, Matrix.one_mul]
  have e'' : P * Hᵀ * Si * H * P * Pi = P * Hᵀ * Si * H := by
    rw [Matrix.mul_assoc _ P Pi, hP, Matrix.mul_one]
  rw [Matrix.sub_mul, Matrix.mul_add, Matrix.mul_add, hP, e'']
  rw [show P * Hᵀ * Si * H * P * (Hᵀ * Ri * H) = P * Hᵀ * Si * H * P * Hᵀ * Ri * H by
    simp only [Matrix.mul_assoc], e', show P * (Hᵀ * Ri * H) = P * Hᵀ * Ri * H by
    simp only [Matrix.mul_assoc]]
  abel

lemma kf_S_posDef {n m : Type*} [Fintype n] [Fintype m]
    (P : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (hP : P.PosSemidef) (hR : R.PosDef) : (H * P * Hᵀ + R).PosDef := by
  have h := hP.mul_mul_conjTranspose_same H
  rw [conjTranspose_eq_transpose_of_trivial] at h
  exact PosDef.posSemidef_add h hR

lemma kf_square {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m]
    [DecidableEq m] (P : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (hP : P.PosSemidef) (hR : R.PosDef) (K : Matrix n m ℝ) :
    (1 - K * H) * P * (1 - K * H)ᵀ + K * R * Kᵀ =
        (P - P * Hᵀ * (H * P * Hᵀ + R)⁻¹ * H * P) +
          (K - P * Hᵀ * (H * P * Hᵀ + R)⁻¹) * (H * P * Hᵀ + R) *
            (K - P * Hᵀ * (H * P * Hᵀ + R)⁻¹)ᵀ := by
  have hS := kf_S_posDef P H R hP hR
  have hdet := (isUnit_iff_isUnit_det _).mp hS.isUnit
  have hPt : Pᵀ = P := by
    have := hP.isHermitian; rwa [IsHermitian, conjTranspose_eq_transpose_of_trivial] at this
  have hSt : (H * P * Hᵀ + R)ᵀ = H * P * Hᵀ + R := by
    have := hS.isHermitian; rwa [IsHermitian, conjTranspose_eq_transpose_of_trivial] at this
  exact kf_alg P H R _ _ K hPt (by rw [transpose_nonsing_inv, hSt]) (nonsing_inv_mul _ hdet)
    (mul_nonsing_inv _ hdet) rfl

/-- Step 3, the card's claim that the Kalman gain is the best linear gain: take a predicted error
covariance P (positive semidefinite), a reading matrix H and a reading-noise covariance R (positive
definite), and let S = H P Hᵀ + R and K* = P Hᵀ S⁻¹. For any gain K, the corrected error covariance
(I - K H) P (I - K H)ᵀ + K R Kᵀ minus the one at K* is positive semidefinite, so no linear correction
does better on any state, and the two are equal only when K is the formula's gain K*. -/
theorem kalman_gain_is_best_linear_gain {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m]
    [DecidableEq m] (P : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (hP : P.PosSemidef) (hR : R.PosDef) (K : Matrix n m ℝ) :
    let S := H * P * Hᵀ + R
    let Kstar := P * Hᵀ * S⁻¹
    let err := fun G : Matrix n m ℝ => (1 - G * H) * P * (1 - G * H)ᵀ + G * R * Gᵀ
    (err K - err Kstar).PosSemidef ∧ (err K = err Kstar ↔ K = Kstar) := by
  intro S Kstar err
  have hS : S.PosDef := kf_S_posDef P H R hP hR
  have hdiff : err K - err Kstar = (K - Kstar) * S * (K - Kstar)ᵀ := by
    simp only [err]
    rw [kf_square P H R hP hR K, kf_square P H R hP hR Kstar]
    simp [Kstar, S]
  refine ⟨?_, ?_⟩
  · rw [hdiff]
    have := hS.posSemidef.mul_mul_conjTranspose_same (K - Kstar)
    rwa [conjTranspose_eq_transpose_of_trivial] at this
  · constructor
    · intro h
      have h0 : (K - Kstar) * S * (K - Kstar)ᵀ = 0 := by rw [← hdiff, h, sub_self]
      exact sub_eq_zero.mp (kf_eq_zero_of_posDef S hS _ h0)
    · intro h; rw [h]

/-- Completing the square and Step 2's corrected covariance: with S = H P Hᵀ + R and
K* = P Hᵀ S⁻¹, every gain K has error covariance
(I - K H) P (I - K H)ᵀ + K R Kᵀ = (P - P Hᵀ S⁻¹ H P) + (K - K*) S (K - K*)ᵀ,
and the first term, the covariance left after conditioning on the reading, equals (I - K* H) P. -/
theorem kalman_completing_the_square {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m]
    [DecidableEq m] (P : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (hP : P.PosSemidef) (hR : R.PosDef) (K : Matrix n m ℝ) :
    let S := H * P * Hᵀ + R
    let Kstar := P * Hᵀ * S⁻¹
    (1 - K * H) * P * (1 - K * H)ᵀ + K * R * Kᵀ =
        (P - P * Hᵀ * S⁻¹ * H * P) + (K - Kstar) * S * (K - Kstar)ᵀ ∧
      P - P * Hᵀ * S⁻¹ * H * P = (1 - Kstar * H) * P := by
  intro S Kstar
  refine ⟨kf_square P H R hP hR K, ?_⟩
  simp only [Kstar, Matrix.sub_mul, Matrix.one_mul]

/-- The precision form: when the predicted covariance P and the reading noise R are positive
definite, the corrected covariance (I - K* H) P is the inverse of P⁻¹ + Hᵀ R⁻¹ H, so the
precisions (inverse covariances) add. -/
theorem kalman_precisions_add {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m]
    [DecidableEq m] (P : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (hP : P.PosDef) (hR : R.PosDef) :
    let S := H * P * Hᵀ + R
    let Kstar := P * Hᵀ * S⁻¹
    ((1 - Kstar * H) * P)⁻¹ = P⁻¹ + Hᵀ * R⁻¹ * H := by
  intro S Kstar
  have hS : S.PosDef := kf_S_posDef P H R hP.posSemidef hR
  apply inv_eq_right_inv
  have e : (1 - Kstar * H) * P = P - P * Hᵀ * S⁻¹ * H * P := by
    simp only [Kstar, Matrix.sub_mul, Matrix.one_mul]
  rw [e]
  exact kf_woodbury P P⁻¹ H R R⁻¹ S S⁻¹
    (mul_nonsing_inv _ ((isUnit_iff_isUnit_det _).mp hP.isUnit))
    (mul_nonsing_inv _ ((isUnit_iff_isUnit_det _).mp hR.isUnit))
    (nonsing_inv_mul _ ((isUnit_iff_isUnit_det _).mp hS.isUnit)) rfl

-- The pendulum's rate-of-change matrix A = [[0, 1], [16, 0]] squares to 16 I, which is why
-- one 0.01 s step e^(0.01 A) works out to cosh and sinh of 0.04.
example : !![(0 : ℤ), 1; 16, 0] * !![0, 1; 16, 0] = (16 : ℤ) • (1 : Matrix (Fin 2) (Fin 2) ℤ) := by
  simp [Matrix.mul_fin_two, Matrix.one_fin_two]

#print axioms kalman_gain_is_best_linear_gain
#print axioms kalman_completing_the_square
#print axioms kalman_precisions_add
#print axioms kf_alg
#print axioms kf_eq_zero_of_posDef
#print axioms kf_woodbury
#print axioms kf_S_posDef
#print axioms kf_square
