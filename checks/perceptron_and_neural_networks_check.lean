-- The perceptron and its stack: if a unit-length line separates labelled points with margin γ > 0 and every point has length at most R, the perceptron makes at most (R/γ)² fixes, while no single line, and no stack of layers without a squashing function, separates the XOR pattern.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Fin.VecNotation

open scoped RealInnerProductSpace
open Matrix

/-! Each order is written with its extra 1, `x̄ = (x₁, x₂, 1)`, so the bias is a third weight and
a line is a vector `w̄` in an inner product space `V` (for the card, `V = ℝ³`). The orders are
indexed by `ι`, with labels `y i = 1` (fraud) or `y i = -1` (normal). A run of the perceptron is
the list of orders `ord t` it fixes on, in the order it meets them, with the weights `w t`
before fix `t`: it starts at `w 0 = 0`, fixes only on a mistake (score times label `≤ 0`, so a
score of exactly 0 counts as wrong), and each fix adds `η • y • x̄`. -/

/-- The stopping promise (Block 1962). Suppose a line `u` of length 1 separates the
orders with margin `γ > 0`: every order has `y · (u · x̄) ≥ γ`; every `x̄` has length at most `R`;
and the learning rate `η` is positive. Then any run of the perceptron from zero weights, in any
order of visits, makes at most `(R / γ)²` fixes. -/
theorem perceptron_fixes_le_sq_radius_div_margin {V ι : Type*}
    [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (x : ι → V) (y : ι → ℝ) (hy : ∀ i, y i = 1 ∨ y i = -1)
    (R γ η : ℝ) (hη : 0 < η) (hR : ∀ i, ‖x i‖ ≤ R)
    (u : V) (hu : ‖u‖ = 1) (hγ : 0 < γ) (hsep : ∀ i, γ ≤ y i * ⟪u, x i⟫)
    (k : ℕ) (ord : ℕ → ι) (w : ℕ → V) (hw0 : w 0 = 0)
    (hmistake : ∀ t < k, y (ord t) * ⟪w t, x (ord t)⟫ ≤ 0)
    (hfix : ∀ t < k, w (t + 1) = w t + (η * y (ord t)) • x (ord t)) :
    (k : ℝ) ≤ (R / γ) ^ 2 := by
  have hinner : ∀ t ≤ k, η * γ * t ≤ ⟪u, w t⟫ := by
    intro t ht
    induction t with
    | zero => simp [hw0]
    | succ n ih =>
      have hn : n < k := ht
      rw [hfix n hn, inner_add_right, real_inner_smul_right]
      have h1 := ih hn.le
      have h2 := hsep (ord n)
      push_cast
      have : η * γ ≤ η * (y (ord n) * ⟪u, x (ord n)⟫) := mul_le_mul_of_nonneg_left h2 hη.le
      nlinarith
  have hnorm : ∀ t ≤ k, ‖w t‖ ^ 2 ≤ η ^ 2 * R ^ 2 * t := by
    intro t ht
    induction t with
    | zero => simp [hw0]
    | succ n ih =>
      have hn : n < k := ht
      rw [hfix n hn, norm_add_sq_real, real_inner_smul_right, norm_smul, Real.norm_eq_abs]
      have h1 := ih hn.le
      have h2 := hmistake n hn
      have hx : ‖x (ord n)‖ ^ 2 ≤ R ^ 2 :=
        pow_le_pow_left₀ (norm_nonneg _) (hR (ord n)) 2
      have hy2 : y (ord n) ^ 2 = 1 := by
        rcases hy (ord n) with h | h <;> rw [h] <;> norm_num
      have habs : |η * y (ord n)| ^ 2 = η ^ 2 := by
        rw [sq_abs, mul_pow, hy2, mul_one]
      push_cast
      rw [mul_pow, habs]
      have h3 : 2 * (η * y (ord n) * ⟪w n, x (ord n)⟫) ≤ 0 := by
        have := mul_nonpos_of_nonneg_of_nonpos hη.le h2
        nlinarith
      nlinarith [sq_nonneg η]
  have hk1 := hinner k le_rfl
  have hk2 := hnorm k le_rfl
  have hcs : ⟪u, w k⟫ ≤ ‖w k‖ := by
    have := real_inner_le_norm u (w k)
    rwa [hu, one_mul] at this
  have hpos : 0 ≤ η * γ * k := by positivity
  have hsq : (η * γ * k) ^ 2 ≤ η ^ 2 * R ^ 2 * k := by
    have : η * γ * k ≤ ‖w k‖ := hk1.trans hcs
    have := pow_le_pow_left₀ hpos this 2
    linarith
  rcases Nat.eq_zero_or_pos k with h0 | hkpos
  · subst h0; simp; positivity
  · have hkr : (0 : ℝ) < k := by exact_mod_cast hkpos
    have hη2 : 0 < η ^ 2 := by positivity
    have h4 : γ ^ 2 * k ≤ R ^ 2 := by
      have : η ^ 2 * k * (γ ^ 2 * k) ≤ η ^ 2 * k * R ^ 2 := by nlinarith
      exact le_of_mul_le_mul_left this (by positivity)
    rw [div_pow, le_div_iff₀ (by positivity)]
    linarith

/-- One line cannot split XOR, and neither can layers with nothing between them. With
`x₁, x₂ ∈ {0, 1}` (card abroad? device abroad?), no weights `w₁, w₂` and bias `b` give a
score `w₁ x₁ + w₂ x₂ + b` that is above 0 exactly on the two mismatches `x₁ ≠ x₂`. Nor does
any two-layer stack with no squashing function: hidden layer `W₁ x + b₁` of any width `m`,
output score `w₂ · (W₁ x + b₁) + b₂`. -/
theorem no_line_separates_xor :
    (¬ ∃ w₁ w₂ b : ℝ, ∀ a c : Fin 2,
        (0 < w₁ * (a : ℕ) + w₂ * (c : ℕ) + b ↔ a ≠ c)) ∧
    ∀ m : ℕ, ¬ ∃ (W₁ : Matrix (Fin m) (Fin 2) ℝ) (b₁ : Fin m → ℝ) (w₂ : Fin m → ℝ) (b₂ : ℝ),
        ∀ a c : Fin 2,
          (0 < w₂ ⬝ᵥ (W₁ *ᵥ ![((a : ℕ) : ℝ), ((c : ℕ) : ℝ)] + b₁) + b₂ ↔ a ≠ c) := by
  have h1 : ¬ ∃ w₁ w₂ b : ℝ, ∀ a c : Fin 2,
        (0 < w₁ * (a : ℕ) + w₂ * (c : ℕ) + b ↔ a ≠ c) := by
    rintro ⟨w₁, w₂, b, h⟩
    have h00 := h 0 0
    have h01 := h 0 1
    have h10 := h 1 0
    have h11 := h 1 1
    simp at h00 h01 h10 h11
    linarith
  refine ⟨h1, ?_⟩
  intro m
  rintro ⟨W₁, b₁, w₂, b₂, h⟩
  apply h1
  refine ⟨(w₂ ᵥ* W₁) 0, (w₂ ᵥ* W₁) 1, w₂ ⬝ᵥ b₁ + b₂, ?_⟩
  intro a c
  rw [← h a c, dotProduct_add, dotProduct_mulVec]
  simp only [dotProduct, Fin.sum_univ_two, Matrix.cons_val_zero, Matrix.cons_val_one]
  constructor <;> intro hh <;> linarith

/-- Without a squashing function two layers are one: for any sizes, the output
`W₂ (W₁ x + b₁) + b₂` equals one matrix `W₂ W₁` times `x` plus one bias `W₂ b₁ + b₂`. -/
theorem two_linear_layers_are_one_layer {n m p : Type*} [Fintype n] [Fintype m]
    (W₁ : Matrix m n ℝ) (b₁ : m → ℝ) (W₂ : Matrix p m ℝ) (b₂ : p → ℝ) (x : n → ℝ) :
    W₂ *ᵥ (W₁ *ᵥ x + b₁) + b₂ = (W₂ * W₁) *ᵥ x + (W₂ *ᵥ b₁ + b₂) := by
  rw [Matrix.mulVec_add, Matrix.mulVec_mulVec, add_assoc]

/-! The card's worked numbers, exactly. An order is `(x₁, x₂, y)`, centred on £400 and 300 km, in
hundreds; weights are `(w₁, w₂, b)`. `visit` is the perceptron rule with `η = 1`, counting fixes. -/

namespace PerceptronCard

def score (w o : ℤ × ℤ × ℤ) : ℤ := w.1 * o.1 + w.2.1 * o.2.1 + w.2.2

def visit (st : (ℤ × ℤ × ℤ) × ℕ) (o : ℤ × ℤ × ℤ) : (ℤ × ℤ × ℤ) × ℕ :=
  if o.2.2 * score st.1 o ≤ 0 then
    ((st.1.1 + o.2.2 * o.1, st.1.2.1 + o.2.2 * o.2.1, st.1.2.2 + o.2.2), st.2 + 1)
  else st

/-- One pass over the data: the weights at the end, and the number of fixes in the pass. -/
def pass (data : List (ℤ × ℤ × ℤ)) (w : ℤ × ℤ × ℤ) : (ℤ × ℤ × ℤ) × ℕ :=
  data.foldl visit (w, 0)

/-- Orders A to H; B, E and F are fraud. -/
def orders : List (ℤ × ℤ × ℤ) :=
  [(-3, -2, -1), (4, 3, 1), (3, -2, -1), (-2, 3, -1), (1, 2, 1), (2, 1, 1), (0, -1, -1), (-1, 1, -1)]

/-- XOR: (card abroad, device abroad, label). -/
def xorData : List (ℤ × ℤ × ℤ) := [(0, 0, -1), (0, 1, 1), (1, 0, 1), (1, 1, -1)]

end PerceptronCard

open PerceptronCard

-- The hand trace: 3 fixes in pass 1 ending at w = (2, 1), b = -3; 3 in pass 2 ending at
-- w = (2, 2), b = -4; then a clean pass 3. Six fixes in all.
example : pass orders (0, 0, 0) = ((2, 1, -3), 3) ∧ pass orders (2, 1, -3) = ((2, 2, -4), 3) ∧
    pass orders (2, 2, -4) = ((2, 2, -4), 0) := by decide

-- Settled scores: A −14, B +10, C −2, D −2, E +2, F +2, G −6, H −4.
example : orders.map (score (2, 2, -4)) = [-14, 10, -2, -2, 2, 2, -6, -4] := by decide

-- Step 0: order A's score falls from 0 to 3(−3) + 2(−2) − 1 = −14, that is by 9 + 4 + 1.
example : (3 : ℤ) * -3 + 2 * -2 - 1 = -14 ∧ (9 : ℤ) + 4 + 1 = 14 := by norm_num

-- The bound: R² = 16 + 9 + 1 = 26 (order B), |u|² = 4 + 4 + 16 = 24, closest score 2,
-- so (R/γ)² = 26 / (2² / 24) = 26 × 24 / 4 = 156, and 6 ≤ 156.
example : (4 : ℚ) ^ 2 + 3 ^ 2 + 1 = 26 ∧ (2 : ℚ) ^ 2 + 2 ^ 2 + (-4) ^ 2 = 24 ∧
    (26 : ℚ) / (2 ^ 2 / 24) = 156 ∧ (6 : ℚ) ≤ 156 := by norm_num

-- XOR, one perceptron: pass 1 from zero makes 4 fixes and returns to (0, 0, 0), so every pass
-- is the same 4 fixes.
example : pass xorData (0, 0, 0) = ((0, 0, 0), 4) := by decide

-- The two-layer network: h₁ = step(x₁ + x₂ − 1/2), h₂ = step(x₁ + x₂ − 3/2),
-- output step(h₁ − h₂ − 1/2), flags exactly the mismatches.
example : ∀ a c : Fin 2,
    let step : ℚ → ℚ := fun s => if 0 < s then 1 else 0
    let h₁ := step ((a : ℕ) + (c : ℕ) - 1 / 2)
    let h₂ := step ((a : ℕ) + (c : ℕ) - 3 / 2)
    step (h₁ - h₂ - 1 / 2) = if a ≠ c then 1 else 0 := by
  intro a c
  fin_cases a <;> fin_cases c <;> norm_num

-- Without squashing: W₂ W₁ = (1 − 1, 1 − 1) = (0, 0) and the bias is −1/2 + 3/2 − 1/2 = 1/2.
example : (1 : ℚ) * 1 + (-1) * 1 = 0 ∧ (1 : ℚ) * (-1 / 2) + (-1) * (-3 / 2) + (-1 / 2) = 1 / 2 := by
  norm_num

-- The shop's network, 12 inputs, 8 hidden units, 1 output: 96 + 8 + 8 + 1 = 113 numbers.
example : 8 * 12 + 8 + 8 + 1 = 113 := by norm_num

#print axioms perceptron_fixes_le_sq_radius_div_margin
#print axioms no_line_separates_xor
#print axioms two_linear_layers_are_one_layer
