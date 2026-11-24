-- Saddle-point systems: a symmetric matrix with a zero on its diagonal and a nonzero entry in that row has no
-- Cholesky factor; Bunch-Kaufman's threshold balances its two growth bounds; every 2-by-2 pivot it accepts has a
-- negative determinant, so it carries one positive and one negative direction; and the loop network's factor holds.
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Matrix.Mul
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic

open Matrix

/-- No Cholesky factor past a zero diagonal entry. If `A = L Lᵀ` for any real matrix `L` and `a_ii = 0`,
then every entry of row `i` is zero. So `[[0, 1], [1, 0]]`, and any matrix of the form `[[R, Eᵀ], [E, 0]]`
with `E ≠ 0`, is not `L Lᵀ` for any `L`. -/
theorem row_zero_of_diag_zero {n : ℕ} (A L : Matrix (Fin n) (Fin n) ℝ) (hA : A = L * Lᵀ) (i : Fin n)
    (h0 : A i i = 0) : ∀ j, A i j = 0 := by
  have hsum : ∑ k, L i k * L i k = 0 := by
    have := h0; rw [hA, Matrix.mul_apply] at this; simpa [transpose_apply] using this
  have hz : ∀ k, L i k = 0 := by
    intro k
    have hnn : ∀ k ∈ Finset.univ, 0 ≤ L i k * L i k := fun k _ => mul_self_nonneg _
    have := (Finset.sum_eq_zero_iff_of_nonneg hnn).mp hsum k (Finset.mem_univ _)
    exact mul_self_eq_zero.mp this
  intro j
  rw [hA, Matrix.mul_apply]
  simp [transpose_apply, hz]

theorem swap_has_no_cholesky : ¬ ∃ L : Matrix (Fin 2) (Fin 2) ℝ, !![(0 : ℝ), 1; 1, 0] = L * Lᵀ := by
  rintro ⟨L, hL⟩
  have := row_zero_of_diag_zero _ L hL 0 (by simp) 1
  simp at this

/-- Bunch-Kaufman's threshold. `α = (1 + √17)/8` lies in (0, 1), solves `4α² − α − 1 = 0`, and makes two
1-by-1 steps (growth at most `1 + 1/α` each) cost the same as one 2-by-2 step (growth at most `1 + 2/(1 − α)`). -/
theorem bk_alpha_balance :
    let α : ℝ := (1 + Real.sqrt 17) / 8
    0 < α ∧ α < 1 ∧ 4 * α ^ 2 - α - 1 = 0 ∧ (1 + 1 / α) ^ 2 = 1 + 2 / (1 - α) := by
  intro α
  have h17 : Real.sqrt 17 ^ 2 = 17 := Real.sq_sqrt (by norm_num)
  have hlo : 4 < Real.sqrt 17 := by
    rw [show (4 : ℝ) = Real.sqrt 16 by rw [show (16 : ℝ) = 4 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]]
    exact Real.sqrt_lt_sqrt (by norm_num) (by norm_num)
  have hhi : Real.sqrt 17 < 7 := by nlinarith
  have hq : 4 * α ^ 2 - α - 1 = 0 := by simp only [α]; nlinarith
  have ha0 : 0 < α := by simp only [α]; linarith
  have ha1 : α < 1 := by simp only [α]; linarith
  refine ⟨ha0, ha1, hq, ?_⟩
  have hne : (1 - α) ≠ 0 := by linarith
  field_simp
  nlinarith

/-- Every 2-by-2 pivot Bunch-Kaufman accepts has a negative determinant. Its block is `[[p, q], [q, t]]` with
`|q| = λ > 0` the largest entry below the first pivot, `σ > 0` the largest off-diagonal entry in row `r`, and it
is chosen only when `|p| σ < α λ²` and `|t| < α σ`, for some `0 < α < 1`. Then `p t − q² < 0`. -/
theorem bk_two_by_two_det_neg (p q t lam sig α : ℝ) (hl : 0 < lam) (hs : 0 < sig) (ha0 : 0 < α) (ha1 : α < 1)
    (hq : |q| = lam) (h1 : |p| * sig < α * lam ^ 2) (h2 : |t| < α * sig) : p * t - q ^ 2 < 0 := by
  have hpt : |p| * sig * |t| ≤ |p| * sig * (α * sig) := mul_le_mul_of_nonneg_left h2.le (by positivity)
  have hb : |p| * sig * (α * sig) ≤ α * lam ^ 2 * (α * sig) := mul_le_mul_of_nonneg_right h1.le (by positivity)
  have h3 : (|p| * |t|) * sig ≤ (α * α * lam ^ 2) * sig := by linarith [hpt.trans hb]
  have h4 : |p| * |t| ≤ α * α * lam ^ 2 := le_of_mul_le_mul_right h3 hs
  have hαα : α * α < 1 := by nlinarith
  have h5 : α * α * lam ^ 2 < lam ^ 2 := mul_lt_of_lt_one_left (by positivity) hαα
  have hq2 : q ^ 2 = lam ^ 2 := by rw [← sq_abs, hq]
  have : p * t ≤ |p| * |t| := by rw [← abs_mul]; exact le_abs_self _
  linarith

/-- A symmetric 2-by-2 block with a negative determinant takes both signs: it has one positive and one
negative direction, so it adds one to each count of the inertia. -/
theorem neg_det_block_both_signs (p q t : ℝ) (h : p * t - q ^ 2 < 0) :
    (∃ x y : ℝ, 0 < p * x ^ 2 + 2 * q * x * y + t * y ^ 2) ∧
    (∃ x y : ℝ, p * x ^ 2 + 2 * q * x * y + t * y ^ 2 < 0) := by
  rcases lt_trichotomy p 0 with hp | hp | hp
  · exact ⟨⟨-q, p, by nlinarith⟩, ⟨1, 0, by nlinarith⟩⟩
  · subst hp
    have hq : q ≠ 0 := by rintro rfl; nlinarith
    refine ⟨⟨(1 - t) / (2 * q), 1, ?_⟩, ⟨(-1 - t) / (2 * q), 1, ?_⟩⟩
    · have e : 0 * ((1 - t) / (2 * q)) ^ 2 + 2 * q * ((1 - t) / (2 * q)) * 1 + t * 1 ^ 2 = 1 := by field_simp; ring
      rw [e]; norm_num
    · have e : 0 * ((-1 - t) / (2 * q)) ^ 2 + 2 * q * ((-1 - t) / (2 * q)) * 1 + t * 1 ^ 2 = -1 := by field_simp; ring
      rw [e]; norm_num
  · exact ⟨⟨1, 0, by nlinarith⟩, ⟨-q, p, by nlinarith⟩⟩

/-- The loop rule. Three pipes from a reservoir at head `H`: pipe 1 to junction 1, pipe 2 from junction 1 to
junction 2, pipe 3 to junction 2, with resistances `r₁, r₂, r₃ > 0` and demands `d₁, d₂`. The five equations
of `[[R, Eᵀ], [E, 0]] (q, h) = (g, d)` force `q₂ = (d₂ r₃ − d₁ r₁)/(r₁ + r₂ + r₃)`. -/
theorem loop_rule (r1 r2 r3 H d1 d2 q1 q2 q3 h1 h2 : ℝ) (hr1 : 0 < r1) (hr2 : 0 < r2) (hr3 : 0 < r3)
    (e1 : r1 * q1 + h1 = H) (e2 : r2 * q2 - h1 + h2 = 0) (e3 : r3 * q3 + h2 = H)
    (e4 : q1 - q2 = d1) (e5 : q2 + q3 = d2) : q2 = (d2 * r3 - d1 * r1) / (r1 + r2 + r3) := by
  rw [eq_div_iff (by linarith)]
  have hq1 : q1 = d1 + q2 := by linarith
  have hq3 : q3 = d2 - q2 := by linarith
  subst hq1 hq3
  nlinarith

/-! The card's worked numbers: the loop with r = (0.1, 0.3, 0.4), H = 60 m, demands 20 and 30 L/s.
Unknowns in Bunch-Kaufman's order (q₁, h₁, q₃, h₂, q₂). -/

-- The reordered matrix P A Pᵀ equals L D Lᵀ, with two 2-by-2 pivots and one 1-by-1 pivot of 0.8.
example :
    !![(1 : ℝ), 0, 0, 0, 0; 0, 1, 0, 0, 0; 0, 0, 1, 0, 0; 0, 0, 0, 1, 0; -1, 1 / 10, 1, -2 / 5, 1] *
      !![(1 / 10 : ℝ), 1, 0, 0, 0; 1, 0, 0, 0, 0; 0, 0, 2 / 5, 1, 0; 0, 0, 1, 0, 0; 0, 0, 0, 0, 4 / 5] *
      (!![(1 : ℝ), 0, 0, 0, 0; 0, 1, 0, 0, 0; 0, 0, 1, 0, 0; 0, 0, 0, 1, 0; -1, 1 / 10, 1, -2 / 5, 1])ᵀ =
    !![(1 / 10 : ℝ), 1, 0, 0, 0; 1, 0, 0, 0, -1; 0, 0, 2 / 5, 1, 0; 0, 0, 1, 0, 1; 0, -1, 0, 1, 3 / 10] := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_five] <;> norm_num

-- Both 2-by-2 pivots have determinant −1, and the flows and heads (32.5, 12.5, 17.5; 56.75, 53) solve the system.
example : (1 / 10 : ℝ) * 0 - 1 ^ 2 = -1 ∧ (2 / 5 : ℝ) * 0 - 1 ^ 2 = -1 := by norm_num
example :
    !![(1 / 10 : ℝ), 0, 0, 1, 0; 0, 3 / 10, 0, -1, 1; 0, 0, 2 / 5, 0, 1; 1, -1, 0, 0, 0; 0, 1, 1, 0, 0] *ᵥ
      ![(65 / 2 : ℝ), 25 / 2, 35 / 2, 227 / 4, 53] = ![60, 0, 60, 20, 30] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_five] <;> norm_num

-- The loop rule on the card's numbers: q₂ = (30 × 0.4 − 20 × 0.1)/0.8 = 12.5 L/s.
example : ((30 : ℝ) * (2 / 5) - 20 * (1 / 10)) / (1 / 10 + 3 / 10 + 2 / 5) = 25 / 2 := by norm_num

#print axioms row_zero_of_diag_zero
#print axioms swap_has_no_cholesky
#print axioms bk_alpha_balance
#print axioms bk_two_by_two_det_neg
#print axioms neg_det_block_both_signs
#print axioms loop_rule
