-- Quadratic forms: for a real symmetric matrix, the form x^T A x is above zero for every mix but all zeros exactly when every eigenvalue is above zero, and for a 2 by 2 matrix exactly when its first entry and its determinant are above zero; the card's matrix [[4, 1], [1, 9]] is checked number by number.
import Mathlib.Analysis.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff

open Matrix Polynomial

theorem qf_helper_expand (a b c x₁ x₂ : ℝ) :
    ![x₁, x₂] ⬝ᵥ (!![a, b; b, c] *ᵥ ![x₁, x₂]) = a * x₁ ^ 2 + 2 * b * x₁ * x₂ + c * x₂ ^ 2 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]; ring

#print axioms qf_helper_expand

theorem qf_helper_posdef_iff (n : ℕ) (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : A.IsHermitian) :
    (∀ x : Fin n → ℝ, x ≠ 0 → 0 < x ⬝ᵥ (A *ᵥ x)) ↔ ∀ i, 0 < hA.eigenvalues i := by
  rw [← hA.posDef_iff_eigenvalues_pos, Matrix.posDef_iff_dotProduct_mulVec]
  constructor
  · intro h
    exact ⟨hA, fun x hx => by simpa using h x hx⟩
  · intro h x hx
    simpa using h.2 hx

#print axioms qf_helper_posdef_iff

theorem qf_helper_two_by_two (A : Matrix (Fin 2) (Fin 2) ℝ)
    (hA : A.IsHermitian) :
    (∀ x : Fin 2 → ℝ, x ≠ 0 → 0 < x ⬝ᵥ (A *ᵥ x)) ↔ (0 < A 0 0 ∧ 0 < A.det) := by
  have hb : A 1 0 = A 0 1 := by
    have := congrFun (congrFun hA 0) 1
    simpa [Matrix.conjTranspose_apply] using this
  have hAe : A = !![A 0 0, A 0 1; A 0 1, A 1 1] := by
    ext i j; fin_cases i <;> fin_cases j <;> simp [hb]
  have hdet : A.det = A 0 0 * A 1 1 - A 0 1 * A 0 1 := by
    rw [Matrix.det_fin_two, hb]
  have hq : ∀ x : Fin 2 → ℝ, x ⬝ᵥ (A *ᵥ x) =
      A 0 0 * x 0 ^ 2 + 2 * A 0 1 * x 0 * x 1 + A 1 1 * x 1 ^ 2 := by
    intro x
    have hx : x = ![x 0, x 1] := by ext i; fin_cases i <;> simp
    rw [hx, hAe, qf_helper_expand]
    simp
  rw [hdet]
  constructor
  · intro h
    have h1 : 0 < A 0 0 := by
      have := h ![1, 0] (by
        intro h0; have := congrFun h0 0; simp at this)
      rw [hq] at this; simpa using this
    refine ⟨h1, ?_⟩
    have := h ![-A 0 1, A 0 0] (by
      intro h0; have := congrFun h0 1; simp at this; linarith)
    rw [hq] at this
    simp at this
    have e : A 0 0 * (-A 0 1) ^ 2 + 2 * A 0 1 * -A 0 1 * A 0 0 + A 1 1 * A 0 0 ^ 2
        = A 0 0 * (A 0 0 * A 1 1 - A 0 1 * A 0 1) := by ring
    have h3 : 0 < A 0 0 * (A 0 0 * A 1 1 - A 0 1 * A 0 1) := by nlinarith [this, e]
    exact pos_of_mul_pos_right h3 h1.le
  · rintro ⟨h1, h2⟩ x hx
    rw [hq]
    have key : A 0 0 * (A 0 0 * x 0 ^ 2 + 2 * A 0 1 * x 0 * x 1 + A 1 1 * x 1 ^ 2)
        = (A 0 0 * x 0 + A 0 1 * x 1) ^ 2 + (A 0 0 * A 1 1 - A 0 1 * A 0 1) * x 1 ^ 2 := by ring
    have hpos : 0 < A 0 0 * (A 0 0 * x 0 ^ 2 + 2 * A 0 1 * x 0 * x 1 + A 1 1 * x 1 ^ 2) := by
      rw [key]
      by_cases h1' : x 1 = 0
      · have h0 : x 0 ≠ 0 := by
          intro h0; apply hx; ext i; fin_cases i <;> simp [h0, h1']
        have hne : A 0 0 * x 0 + A 0 1 * x 1 ≠ 0 := by
          rw [h1']; simpa using mul_ne_zero h1.ne' h0
        have : 0 < (A 0 0 * x 0 + A 0 1 * x 1) ^ 2 :=
          lt_of_le_of_ne (sq_nonneg _) (Ne.symm (pow_ne_zero 2 hne))
        positivity
      · have : 0 < (A 0 0 * A 1 1 - A 0 1 * A 0 1) * x 1 ^ 2 := by positivity
        positivity
    exact pos_of_mul_pos_right hpos h1.le

#print axioms qf_helper_two_by_two

/-- Three tests, one verdict. For a real 2 by 2 symmetric matrix A (its two corner entries
equal), these three statements agree:
the definition, x^T A x above zero for every mix x except all zeros;
the eigenvalue test, both eigenvalues of A above zero;
the two-entry test, the first entry of A and the determinant of A both above zero. -/
theorem two_by_two_symmetric_three_tests_agree (A : Matrix (Fin 2) (Fin 2) ℝ)
    (hA : A.IsHermitian) :
    ((∀ x : Fin 2 → ℝ, x ≠ 0 → 0 < x ⬝ᵥ (A *ᵥ x)) ↔ (∀ i, 0 < hA.eigenvalues i)) ∧
    ((∀ x : Fin 2 → ℝ, x ≠ 0 → 0 < x ⬝ᵥ (A *ᵥ x)) ↔ (0 < A 0 0 ∧ 0 < A.det)) := by
  refine ⟨qf_helper_posdef_iff 2 A hA, qf_helper_two_by_two A hA⟩

/-- The eigenvalue test decides at any size. For every n and every real n by n symmetric
matrix A, x^T A x is above zero for every list of n weights except all zeros exactly when
every eigenvalue of A is above zero. -/
theorem pos_def_iff_all_eigenvalues_pos (n : ℕ) (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : A.IsHermitian) :
    (∀ x : Fin n → ℝ, x ≠ 0 → 0 < x ⬝ᵥ (A *ᵥ x)) ↔ ∀ i, 0 < hA.eigenvalues i := by
  exact qf_helper_posdef_iff n A hA

/-- The formula, with the 2 that is easy to drop. For the symmetric matrix [[a, b], [b, c]]
and the mix (x1, x2), the weights as a row times the matrix times the weights as a column is
a x1^2 + 2 b x1 x2 + c x2^2: the cross product arrives once from each corner. -/
theorem quadratic_form_two_by_two_expand (a b c x₁ x₂ : ℝ) :
    ![x₁, x₂] ⬝ᵥ (!![a, b; b, c] *ᵥ ![x₁, x₂]) = a * x₁ ^ 2 + 2 * b * x₁ * x₂ + c * x₂ ^ 2 := by
  exact qf_helper_expand a b c x₁ x₂

-- The departures, in percentage points: asset one 2, 2, 2, 2, -2, -2, -2, -2 and asset two
-- 5, 1, -1, -3, -5, -1, 1, 3. Squares summed are 32 and 72, products summed are 8;
-- over eight months that is variance 4, variance 9 and covariance 1.
example : ∑ i : Fin 8, (![2, 2, 2, 2, -2, -2, -2, -2] : Fin 8 → ℤ) i ^ 2 = 4 * 8 ∧
    ∑ i : Fin 8, (![5, 1, -1, -3, -5, -1, 1, 3] : Fin 8 → ℤ) i ^ 2 = 9 * 8 ∧
    ∑ i : Fin 8, (![2, 2, 2, 2, -2, -2, -2, -2] : Fin 8 → ℤ) i *
      (![5, 1, -1, -3, -5, -1, 1, 3] : Fin 8 → ℤ) i = 1 * 8 := by decide
-- Half and half by the matrix road: 4 × 1/4 + 2 × 1 × 1/4 + 9 × 1/4 = 15/4, that is 3.75.
example : ![(1 : ℚ) / 2, 1 / 2] ⬝ᵥ (!![4, 1; 1, 9] *ᵥ ![(1 : ℚ) / 2, 1 / 2]) = 15 / 4 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]; norm_num
-- Half and half by the table road: the blended departures, doubled, are 7, 3, 1, -1, -7, -3,
-- -1, 1; their squares sum to 120, and 120 / (4 × 8) = 15/4.
example : ∑ i : Fin 8, ((![2, 2, 2, 2, -2, -2, -2, -2] : Fin 8 → ℤ) i +
    (![5, 1, -1, -3, -5, -1, 1, 3] : Fin 8 → ℤ) i) ^ 2 = 120 := by decide
example : (120 : ℚ) / (4 * 8) = 15 / 4 := by norm_num
-- Determinant 4 × 9 - 1 × 1 = 35 and trace 4 + 9 = 13, so the eigenvalues solve
-- lambda^2 - 13 lambda + 35 = 0.
example : (!![4, 1; 1, 9] : Matrix (Fin 2) (Fin 2) ℚ).det = 35 := by
  rw [det_fin_two_of]; norm_num
example : (!![4, 1; 1, 9] : Matrix (Fin 2) (Fin 2) ℚ).trace = 13 := by
  simp [trace, Fin.sum_univ_two]; norm_num
example : (!![4, 1; 1, 9] : Matrix (Fin 2) (Fin 2) ℚ).charpoly = X ^ 2 - C 13 * X + C 35 := by
  rw [charpoly_fin_two, det_fin_two_of]; simp [trace, Fin.sum_univ_two]
  rw [← C_add, ← C_mul, ← C_1, ← C_sub]; norm_num
-- The two-entry test passes: first entry 4 above zero, determinant 35 above zero.
example : (0 : ℚ) < 4 ∧ (0 : ℚ) < 4 * 9 - 1 * 1 := by norm_num
-- Fully invested, the second weight 1 - w: the form is 11 w^2 - 16 w + 9,
-- with 11 = a - 2b + c, -16 = 2b - 2c, 9 = c.
example (w : ℚ) : ![w, 1 - w] ⬝ᵥ (!![4, 1; 1, 9] *ᵥ ![w, 1 - w]) = 11 * w ^ 2 - 16 * w + 9 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]; ring
example : (4 : ℚ) - 2 * 1 + 9 = 11 ∧ (2 : ℚ) * 1 - 2 * 9 = -16 := by norm_num
-- Completing the square: 11 w^2 - 16 w + 9 = 11 (w - 8/11)^2 + 35/11, so the calmest
-- fully invested mix is 8 parts to 3, at variance 35/11.
example (w : ℚ) : 11 * w ^ 2 - 16 * w + 9 = 11 * (w - 8 / 11) ^ 2 + 35 / 11 := by ring
example : (11 : ℚ) * (8 / 11) ^ 2 - 16 * (8 / 11) + 9 = 35 / 11 := by norm_num
-- Under both single assets: 35/11 is less than 4 and less than 9.
example : (35 : ℚ) / 11 < 4 ∧ (35 : ℚ) / 11 < 9 := by norm_num
-- What breaks: dropping the covariance gives 13/4 (3.25); counting the cross term once
-- gives 7/2 (3.5); holding nothing gives 0.
example : ![(1 : ℚ) / 2, 1 / 2] ⬝ᵥ (!![4, 0; 0, 9] *ᵥ ![(1 : ℚ) / 2, 1 / 2]) = 13 / 4 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]; norm_num
example : (4 : ℚ) * (1 / 4) + 1 / 4 + 9 * (1 / 4) = 7 / 2 := by norm_num
example : ![(0 : ℚ), 0] ⬝ᵥ (!![4, 1; 1, 9] *ᵥ ![(0 : ℚ), 0]) = 0 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]
-- Positive entries are not enough: [[1, 2], [2, 1]] has determinant -3, and the mix (1, -1)
-- scores -2.
example : (!![1, 2; 2, 1] : Matrix (Fin 2) (Fin 2) ℚ).det = -3 := by
  rw [det_fin_two_of]; norm_num
example : ![(1 : ℚ), -1] ⬝ᵥ (!![1, 2; 2, 1] *ᵥ ![(1 : ℚ), -1]) = -2 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]; norm_num
-- The determinant alone is not enough: [[-4, -1], [-1, -9]] has determinant 35, yet scores
-- -15/4 (-3.75) at half and half.
example : (!![-4, -1; -1, -9] : Matrix (Fin 2) (Fin 2) ℚ).det = 35 := by
  rw [det_fin_two_of]; norm_num
example : ![(1 : ℚ) / 2, 1 / 2] ⬝ᵥ (!![-4, -1; -1, -9] *ᵥ ![(1 : ℚ) / 2, 1 / 2]) = -15 / 4 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]; norm_num
-- Try changing: covariance 3 scores 19/4 (4.75) at half and half; covariance 6 makes the
-- determinant zero and the mix (3, -2) score zero.
example : ![(1 : ℚ) / 2, 1 / 2] ⬝ᵥ (!![4, 3; 3, 9] *ᵥ ![(1 : ℚ) / 2, 1 / 2]) = 19 / 4 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]; norm_num
example : (!![4, 6; 6, 9] : Matrix (Fin 2) (Fin 2) ℚ).det = 0 := by
  rw [det_fin_two_of]; norm_num
example : ![(3 : ℚ), -2] ⬝ᵥ (!![4, 6; 6, 9] *ᵥ ![(3 : ℚ), -2]) = 0 := by
  simp [dotProduct, mulVec, Fin.sum_univ_two]; norm_num

#print axioms two_by_two_symmetric_three_tests_agree
#print axioms pos_def_iff_all_eigenvalues_pos
#print axioms quadratic_form_two_by_two_expand
