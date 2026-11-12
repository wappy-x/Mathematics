-- Quadratic programs: when the cost matrix Q is positive semidefinite, any point that meets the KKT conditions (balanced slope, limits met, non-negative multipliers that push only where a variable is zero) is a global minimum of the quadratic cost over all allowed points, and for the long-only fund this means equal portfolio covariance on every held asset certifies the least variance.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum

open Matrix

lemma quad_lower_bound_of_posSemidef {n : ℕ} (Q : Matrix (Fin n) (Fin n) ℝ) (hQ : Q.PosSemidef)
    (x y : Fin n → ℝ) :
    x ⬝ᵥ (Q *ᵥ x) + 2 * ((y - x) ⬝ᵥ (Q *ᵥ x)) ≤ y ⬝ᵥ (Q *ᵥ y) := by
  set d := y - x with hd_def
  have hy : y = x + d := by rw [hd_def]; abel
  have hT : Qᵀ = Q := by
    have := hQ.1
    rw [IsHermitian, conjTranspose_eq_transpose_of_trivial] at this
    exact this
  have hsym : x ⬝ᵥ (Q *ᵥ d) = d ⬝ᵥ (Q *ᵥ x) := by
    rw [dotProduct_mulVec, ← mulVec_transpose, hT, dotProduct_comm]
  have hnn : 0 ≤ d ⬝ᵥ (Q *ᵥ d) := by
    have := hQ.dotProduct_mulVec_nonneg d
    simpa using this
  rw [hy, mulVec_add, dotProduct_add, add_dotProduct, add_dotProduct, hsym]
  linarith

lemma dot_transpose_mulVec_eq_zero {n m : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (x y : Fin n → ℝ) (ν : Fin m → ℝ) (hx : A *ᵥ x = b) (hy : A *ᵥ y = b) :
    (y - x) ⬝ᵥ (Aᵀ *ᵥ ν) = 0 := by
  rw [dotProduct_mulVec, vecMul_transpose, mulVec_sub, hx, hy, sub_self, zero_dotProduct]

#print axioms quad_lower_bound_of_posSemidef
#print axioms dot_transpose_mulVec_eq_zero

/-- The card's theorem: the printed conditions certify a global minimum when the bowl is convex.
Take the quadratic program "minimise ½ xᵀQx + cᵀx subject to Ax = b and x ≥ 0" with Q positive
semidefinite. If x, together with multipliers ν (one per equation) and lam (one per bound),
satisfies Qx + c + Aᵀν − lam = 0, Ax = b, x ≥ 0, lam ≥ 0 and lamᵢ xᵢ = 0 for every i, then no
point y with Ay = b and y ≥ 0 has a lower cost. -/
theorem kkt_conditions_certify_global_minimum {n m : ℕ}
    (Q : Matrix (Fin n) (Fin n) ℝ) (hQ : Q.PosSemidef) (c : Fin n → ℝ)
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (x : Fin n → ℝ) (ν : Fin m → ℝ) (lam : Fin n → ℝ)
    (h_stat : Q *ᵥ x + c + Aᵀ *ᵥ ν - lam = 0)
    (h_eq : A *ᵥ x = b) (h_x : 0 ≤ x) (h_lam : 0 ≤ lam)
    (h_comp : ∀ i, lam i * x i = 0) :
    ∀ y : Fin n → ℝ, A *ᵥ y = b → 0 ≤ y →
      (1 / 2 : ℝ) * (x ⬝ᵥ (Q *ᵥ x)) + c ⬝ᵥ x ≤ (1 / 2 : ℝ) * (y ⬝ᵥ (Q *ᵥ y)) + c ⬝ᵥ y := by
  intro y hy hy0
  have hb := quad_lower_bound_of_posSemidef Q hQ x y
  have hg : Q *ᵥ x = lam - Aᵀ *ᵥ ν - c := by
    rw [← sub_eq_zero, ← h_stat]; abel
  have hA := dot_transpose_mulVec_eq_zero A b x y ν h_eq hy
  have hxl : x ⬝ᵥ lam = 0 := by
    simp only [dotProduct]
    exact Finset.sum_eq_zero fun i _ => by rw [mul_comm]; exact h_comp i
  have hyl : 0 ≤ y ⬝ᵥ lam := by
    simp only [dotProduct]
    exact Finset.sum_nonneg fun i _ => mul_nonneg (hy0 i) (h_lam i)
  have key : (y - x) ⬝ᵥ (Q *ᵥ x) = y ⬝ᵥ lam - x ⬝ᵥ lam - (y - x) ⬝ᵥ (Aᵀ *ᵥ ν) - (c ⬝ᵥ y - c ⬝ᵥ x) := by
    rw [hg, dotProduct_sub, dotProduct_sub, sub_dotProduct, dotProduct_comm (y - x) c,
      dotProduct_sub]
  rw [key, hA, hxl] at hb
  linarith

/-- Equations only, one linear system: with Q positive semidefinite, if x and ν solve the KKT
system Qx + c + Aᵀν = 0, Ax = b, then x has the lowest cost ½ xᵀQx + cᵀx among all points
meeting Ay = b. -/
theorem kkt_system_solution_minimises_under_equations {n m : ℕ}
    (Q : Matrix (Fin n) (Fin n) ℝ) (hQ : Q.PosSemidef) (c : Fin n → ℝ)
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (x : Fin n → ℝ) (ν : Fin m → ℝ)
    (h_stat : Q *ᵥ x + c + Aᵀ *ᵥ ν = 0) (h_eq : A *ᵥ x = b) :
    ∀ y : Fin n → ℝ, A *ᵥ y = b →
      (1 / 2 : ℝ) * (x ⬝ᵥ (Q *ᵥ x)) + c ⬝ᵥ x ≤ (1 / 2 : ℝ) * (y ⬝ᵥ (Q *ᵥ y)) + c ⬝ᵥ y := by
  intro y hy
  have hb := quad_lower_bound_of_posSemidef Q hQ x y
  have hg : Q *ᵥ x = -(Aᵀ *ᵥ ν) - c := by
    rw [← sub_eq_zero, ← h_stat]; abel
  have hA := dot_transpose_mulVec_eq_zero A b x y ν h_eq hy
  have key : (y - x) ⬝ᵥ (Q *ᵥ x) = -((y - x) ⬝ᵥ (Aᵀ *ᵥ ν)) - (c ⬝ᵥ y - c ⬝ᵥ x) := by
    rw [hg, dotProduct_sub, dotProduct_neg, dotProduct_comm (y - x) c, dotProduct_sub]
  rw [key, hA] at hb
  linarith

/-- The fund's reading of the conditions. Let S be a positive semidefinite covariance matrix and
w a long-only, fully invested split (w ≥ 0, weights add to 1). If, asset by asset,
(Sw)ᵢ = V + lamᵢ with lamᵢ ≥ 0 and lamᵢ = 0 wherever wᵢ > 0 (every held asset has the same
covariance V with the portfolio, every asset left out has at least V), then V is the portfolio's
variance wᵀSw, and no long-only, fully invested split has a lower variance. -/
theorem markowitz_equal_covariance_certifies_least_variance {n : ℕ}
    (S : Matrix (Fin n) (Fin n) ℝ) (hS : S.PosSemidef)
    (w : Fin n → ℝ) (h_w : 0 ≤ w) (h_sum : ∑ i, w i = 1)
    (V : ℝ) (lam : Fin n → ℝ) (h_lam : 0 ≤ lam)
    (h_row : ∀ i, (S *ᵥ w) i = V + lam i) (h_comp : ∀ i, lam i * w i = 0) :
    V = w ⬝ᵥ (S *ᵥ w) ∧
      ∀ y : Fin n → ℝ, 0 ≤ y → ∑ i, y i = 1 → V ≤ y ⬝ᵥ (S *ᵥ y) := by
  have hdot : ∀ z : Fin n → ℝ, z ⬝ᵥ (S *ᵥ w) = V * ∑ i, z i + z ⬝ᵥ lam := by
    intro z
    simp only [dotProduct, h_row, Finset.mul_sum, ← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl fun i _ => by ring
  have hwl : w ⬝ᵥ lam = 0 := by
    simp only [dotProduct]
    exact Finset.sum_eq_zero fun i _ => by rw [mul_comm]; exact h_comp i
  have hV : V = w ⬝ᵥ (S *ᵥ w) := by rw [hdot, h_sum, hwl]; ring
  refine ⟨hV, fun y hy0 hy1 => ?_⟩
  have hb := quad_lower_bound_of_posSemidef S hS w y
  have hyl : 0 ≤ y ⬝ᵥ lam := by
    simp only [dotProduct]
    exact Finset.sum_nonneg fun i _ => mul_nonneg (hy0 i) (h_lam i)
  rw [sub_dotProduct, hdot, hdot, hy1, h_sum, hwl] at hb
  linarith

/-! ### The card's worked numbers, checked exactly

The covariance entries (percent squared) are 256, 216, 201.6 = 1008/5, 225, 135, 324,
43.2 = 216/5, 64, 33.6 = 168/5, 42, 50.4 = 252/5, 196. All arithmetic below is exact. -/

/-- Equal weights, 1/5 each: the variance is the sum of all 25 covariance entries over 25,
which is 100.344 exactly. -/
example :
    ((256 + 216 + 1008 / 5 + 0 + 0) + (216 + 225 + 135 + 0 + 42)
      + (1008 / 5 + 135 + 324 + 216 / 5 + 252 / 5) + (0 + 0 + 216 / 5 + 64 + 168 / 5)
      + (0 + 42 + 252 / 5 + 168 / 5 + 196) : ℚ) / 25 = 12543 / 125 := by
  norm_num

/-- By hand, pass 2: the determinant of the gilts–gold block is 11415.04. -/
example : (64 * 196 - (168 / 5) ^ 2 : ℚ) = 285376 / 25 := by norm_num

/-- Gilts' row of the inverse times the determinant is 162.4; gold's is 30.4. -/
example : (196 - 168 / 5 : ℚ) = 812 / 5 ∧ (64 - 168 / 5 : ℚ) = 152 / 5 := by norm_num

/-- Pass 2 exactly: with world shares and property at zero, V = 1141504/23739 (about 48.0856) and
weights UK 4459/23739, gilts 16240/23739, gold 3040/23739 solve the KKT rows
256 w_UK = V, 64 w_G + 33.6 w_Au = V, 33.6 w_G + 196 w_Au = V, and add to 1. -/
example :
    let V : ℚ := 1141504 / 23739
    let wUK : ℚ := 4459 / 23739
    let wG : ℚ := 16240 / 23739
    let wAu : ℚ := 3040 / 23739
    256 * wUK = V ∧ 64 * wG + 168 / 5 * wAu = V ∧ 168 / 5 * wG + 196 * wAu = V ∧
      wUK + wG + wAu = 1 := by
  norm_num

/-- World shares' multiplier at pass 2 is negative (exactly −50680/23739, about −2.1349): their
covariance with the portfolio, 216 w_UK + 42 w_Au, is below V, so the bound on them comes off. -/
example :
    (216 * (4459 / 23739) + 42 * (3040 / 23739) - 1141504 / 23739 : ℚ) = -50680 / 23739 ∧
      (216 * (4459 / 23739) + 42 * (3040 / 23739) - 1141504 / 23739 : ℚ) < 0 := by
  norm_num

#print axioms kkt_conditions_certify_global_minimum
#print axioms kkt_system_solution_minimises_under_equations
#print axioms markowitz_equal_covariance_certifies_least_variance
