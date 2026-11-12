-- Second-order cone programs: any budget price, non-negative floor prices and a risk-price list inside the ice cream cone give a ceiling on the return of every allowed mix (weak conic duality), the cone is its own dual, and the hyperbola x1 x2 >= 1 is one cone constraint.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum

open Matrix

/-- The second-order ("ice cream") cone. The card's `𝒬^(m+1)` holds every point `(h, v)` made of a
height `h` and a list `v` of `m` numbers whose length (square root of the sum of squares) is at most
the height. -/
def secondOrderCone (m : ℕ) : Set (ℝ × EuclideanSpace ℝ (Fin m)) :=
  {p | ‖p.2‖ ≤ p.1}

/-- Weak conic duality, the ceiling (Step 2). Take any mix `w` of `n` assets that is fully invested
(weights add to 1), has no negative weight, and whose risk list `A (w - w_b)` lies in the cone at
height `δ` (tracking error at most `δ`). Take any budget price `ν`, any floor prices `λ ≥ 0` and any
cone point `(z, u)` with `Aᵀ u + ν 1 - λ = μ`. Then the expected return of the mix is at most
`ν + δ z + uᵀ A w_b`: no mix inside the limits beats any such price set. -/
theorem weak_conic_duality {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (μ w w_b lam : Fin n → ℝ) (u : Fin m → ℝ) (δ ν z : ℝ)
    (h_budget : ∑ i, w i = 1)
    (h_floor : ∀ i, 0 ≤ w i)
    (h_risk : (δ, WithLp.toLp 2 (A *ᵥ (w - w_b))) ∈ secondOrderCone m)
    (h_lam : ∀ i, 0 ≤ lam i)
    (h_dual_cone : (z, WithLp.toLp 2 u) ∈ secondOrderCone m)
    (h_stationary : Aᵀ *ᵥ u + (fun _ => ν) - lam = μ) :
    μ ⬝ᵥ w ≤ ν + δ * z + u ⬝ᵥ (A *ᵥ w_b) := by
  simp only [secondOrderCone, Set.mem_ofPred_eq] at h_risk h_dual_cone
  have hlw : 0 ≤ lam ⬝ᵥ w := by
    unfold dotProduct
    exact Finset.sum_nonneg fun i _ => mul_nonneg (h_lam i) (h_floor i)
  have hnu : (fun _ : Fin n => ν) ⬝ᵥ w = ν := by
    unfold dotProduct
    rw [← Finset.mul_sum, h_budget, mul_one]
  have hT : (Aᵀ *ᵥ u) ⬝ᵥ w = u ⬝ᵥ (A *ᵥ (w - w_b)) + u ⬝ᵥ (A *ᵥ w_b) := by
    rw [mulVec_transpose, ← dotProduct_mulVec, ← dotProduct_add, ← mulVec_add, sub_add_cancel]
  have hcs : u ⬝ᵥ (A *ᵥ (w - w_b)) ≤ ‖WithLp.toLp 2 u‖ * ‖WithLp.toLp 2 (A *ᵥ (w - w_b))‖ := by
    have := real_inner_le_norm (WithLp.toLp 2 (A *ᵥ (w - w_b)) : EuclideanSpace ℝ (Fin m))
      (WithLp.toLp 2 u)
    rw [EuclideanSpace.inner_toLp_toLp] at this
    simpa [mul_comm] using this
  have h1 : μ ⬝ᵥ w = (Aᵀ *ᵥ u) ⬝ᵥ w + (fun _ : Fin n => ν) ⬝ᵥ w - lam ⬝ᵥ w := by
    rw [← h_stationary, sub_dotProduct, add_dotProduct]
  rw [h1, hT, hnu]
  have n1 := norm_nonneg (WithLp.toLp 2 u : EuclideanSpace ℝ (Fin m))
  have n2 := norm_nonneg (WithLp.toLp 2 (A *ᵥ (w - w_b)) : EuclideanSpace ℝ (Fin m))
  nlinarith [mul_le_mul h_dual_cone h_risk n2 (n1.trans h_dual_cone)]

/-- The second-order cone is self-dual (Step 0): a point `(z, u)` is in the cone exactly when its
inner product `h z + vᵀ u` with every cone point `(h, v)` is at least 0. So prices for a cone
constraint live in the same cone. -/
theorem second_order_cone_self_dual {m : ℕ} (z : ℝ) (u : EuclideanSpace ℝ (Fin m)) :
    (z, u) ∈ secondOrderCone m ↔
      ∀ p ∈ secondOrderCone m, 0 ≤ p.1 * z + inner ℝ p.2 u := by
  simp only [secondOrderCone, Set.mem_ofPred_eq]
  constructor
  · rintro hu ⟨h, v⟩ hv
    simp only at hv ⊢
    have := neg_le_of_abs_le (abs_real_inner_le_norm v u)
    have n1 := norm_nonneg u
    have n2 := norm_nonneg v
    nlinarith [mul_le_mul hv hu n1 (n2.trans hv)]
  · intro H
    have h0 := H (1, 0) (by simp)
    simp at h0
    have h1 := H (‖u‖, -u) (by simp)
    simp only [inner_neg_left, real_inner_self_eq_norm_sq] at h1
    rcases (norm_nonneg u).eq_or_lt with h | h
    · rw [← h]; exact h0
    · nlinarith

/-- The hyperbola as one cone constraint: `x₁ x₂ ≥ 1` with `x₁, x₂ ≥ 0` holds exactly when the point
`(x₁ + x₂, (x₁ - x₂, 2))` lies in the three-dimensional cone `𝒬³`. -/
theorem hyperbola_is_second_order_cone (x₁ x₂ : ℝ) :
    (0 ≤ x₁ ∧ 0 ≤ x₂ ∧ 1 ≤ x₁ * x₂) ↔
      (x₁ + x₂, WithLp.toLp 2 ![x₁ - x₂, 2]) ∈ secondOrderCone 2 := by
  simp only [secondOrderCone, Set.mem_ofPred_eq, EuclideanSpace.norm_eq, Fin.sum_univ_two]
  simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Real.norm_eq_abs, sq_abs]
  rw [Real.sqrt_le_iff]
  constructor
  · rintro ⟨h1, h2, h3⟩
    constructor
    · linarith
    · nlinarith
  · rintro ⟨h1, h2⟩
    have hp : 1 ≤ x₁ * x₂ := by nlinarith
    refine ⟨?_, ?_, hp⟩
    · by_contra hc
      push Not at hc
      nlinarith
    · by_contra hc
      push Not at hc
      nlinarith

-- The benchmark weights 25%, 30%, 10%, 20%, 15% add to 100%.
example : (25 : ℕ) + 30 + 10 + 20 + 15 = 100 := by decide
-- Benchmark return: 0.25 × 6 + 0.30 × 7 + 0.10 × 8.5 + 0.20 × 4 + 0.15 × 4.8 = 5.97 (% a year).
example : (25 : ℚ) / 100 * 6 + 30 / 100 * 7 + 10 / 100 * (17 / 2) + 20 / 100 * 4
    + 15 / 100 * (24 / 5) = 597 / 100 := by norm_num
-- Hyperbola, Step 5: x₂ = 10, 100, 1000 force x₁ = 1/10, 1/100, 1/1000, and each point sits on the
-- rim of the cone: (x₁ - x₂)² + 2² = (x₁ + x₂)².
example : (1 / 10 : ℚ) * 10 = 1 ∧ (1 / 100 : ℚ) * 100 = 1 ∧ (1 / 1000 : ℚ) * 1000 = 1 := by norm_num
example : ((1 / 10 : ℚ) - 10) ^ 2 + 2 ^ 2 = (1 / 10 + 10) ^ 2 := by norm_num
example : ((1 / 100 : ℚ) - 100) ^ 2 + 2 ^ 2 = (1 / 100 + 100) ^ 2 := by norm_num
example : ((1 / 1000 : ℚ) - 1000) ^ 2 + 2 ^ 2 = (1 / 1000 + 1000) ^ 2 := by norm_num
-- The hyperbola's dual point (1/2, 1/2, 0) is on the rim: its list (1/2, 0) has length exactly 1/2.
example : (1 / 2 : ℚ) ^ 2 + 0 ^ 2 = (1 / 2) ^ 2 := by norm_num

#print axioms weak_conic_duality
#print axioms second_order_cone_self_dual
#print axioms hyperbola_is_second_order_cone
