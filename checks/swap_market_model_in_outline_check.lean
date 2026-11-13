-- Swap market model: when two independent lognormal forwards move, the two-coupon swap rate's squared volatility changes with the rates, so no fixed swap-rate volatility can match it, and a lognormal swap rate can force the first forward below zero.
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

/-! The swap starts at `T_1` and pays fixed at `T_2` and `T_3`, one year's interest each time.
`x = L_1` is the forward rate from year 1 to 2 and `y = L_2` the forward rate from year 2 to 3.
One curve sets both the forwards and the discounting: `P(T_2) = P(T_1) / (1 + L_1)` and
`P(T_3) = P(T_2) / (1 + L_2)`. The swap rate is `S = (P(T_1) - P(T_3)) / A` with annuity
`A = P(T_2) + P(T_3)`.

Under the forward market model, with forward volatilities `σ_1`, `σ_2` and independent shocks,
Itô's lemma gives the swap rate's percentage volatility one piece per shock,
`Γ_1 = σ_1 x (1 + y) / (x + y + x y)` and `Γ_2 = σ_2 y (2 + x) / ((2 + y)(x + y + x y))`,
and the variance rate of `ln S` is `Γ_1² + Γ_2²`. The swap market model demands that this
variance rate be `γ²` for a volatility `γ` fixed in advance, never a function of the rates.
The stochastic steps (Itô, Girsanov, full support of the two lognormal forwards) are not
formalized here; the file states the exact algebra the clash rests on. -/

/-- The swap rate written in the two forward rates: `S = (x + y + x y) / (2 + y)`. -/
noncomputable def swapRate (x y : ℝ) : ℝ := (x + y + x * y) / (2 + y)

/-- The variance rate of `ln S` under the forward market model:
`Γ² = Γ_1² + Γ_2²` with `Γ_1 = σ_1 x (1 + y) / (x + y + x y)` and
`Γ_2 = σ_2 y (2 + x) / ((2 + y)(x + y + x y))`. -/
noncomputable def swapVolSq (σ₁ σ₂ x y : ℝ) : ℝ :=
  (σ₁ * x * (1 + y) / (x + y + x * y)) ^ 2
    + (σ₂ * y * (2 + x) / ((2 + y) * (x + y + x * y))) ^ 2

/-- The card's main claim, the clash. Unless every forward volatility is zero, the swap rate's
squared volatility under the forward market model is not one fixed number across the positive
rates: no deterministic swap-rate volatility `γ` gives `Γ² = γ²` at every pair of positive
forwards. Since both lognormal forwards can reach every positive pair, a lognormal forward model
and a lognormal swap model with fixed `γ` cannot both hold for the same two-coupon swap. -/
theorem swap_vol_not_deterministic (σ₁ σ₂ : ℝ) (hσ : σ₁ ≠ 0 ∨ σ₂ ≠ 0) :
    ¬ ∃ γ : ℝ, ∀ x y : ℝ, 0 < x → 0 < y → swapVolSq σ₁ σ₂ x y = γ ^ 2 := by
  rintro ⟨γ, h⟩
  have h1 := h 1 1 one_pos one_pos
  have h2 := h 2 1 two_pos one_pos
  have h3 := h (1 / 2) 1 (by norm_num) one_pos
  have e1 : swapVolSq σ₁ σ₂ 1 1 = 4 / 9 * σ₁ ^ 2 + 1 / 9 * σ₂ ^ 2 := by
    unfold swapVolSq; norm_num; ring
  have e2 : swapVolSq σ₁ σ₂ 2 1 = 16 / 25 * σ₁ ^ 2 + 16 / 225 * σ₂ ^ 2 := by
    unfold swapVolSq; norm_num; ring
  have e3 : swapVolSq σ₁ σ₂ (1 / 2) 1 = 1 / 4 * σ₁ ^ 2 + 25 / 144 * σ₂ ^ 2 := by
    unfold swapVolSq; norm_num; ring
  rw [e1] at h1
  rw [e2] at h2
  rw [e3] at h3
  have ha : σ₁ ^ 2 = 0 := by linarith
  have hb : σ₂ ^ 2 = 0 := by linarith
  rcases hσ with hσ | hσ
  · exact hσ (pow_eq_zero_iff two_ne_zero |>.mp ha)
  · exact hσ (pow_eq_zero_iff two_ne_zero |>.mp hb)

/-- Steps 0 and 1. With positive rates on one curve, the swap rate read off the bonds,
`(P(T_1) - P(T_3)) / (P(T_2) + P(T_3))`, equals `(L_1 + L_2 + L_1 L_2) / (2 + L_2)`, and it is
the average of the two forwards weighted by each payment date's share of the annuity,
`P(T_2)/A · L_1 + P(T_3)/A · L_2`. -/
theorem swap_rate_from_bonds (P₁ L₁ L₂ : ℝ) (hP : 0 < P₁) (h₁ : 0 < L₁) (h₂ : 0 < L₂) :
    (P₁ - P₁ / (1 + L₁) / (1 + L₂)) / (P₁ / (1 + L₁) + P₁ / (1 + L₁) / (1 + L₂))
        = swapRate L₁ L₂ ∧
      swapRate L₁ L₂
        = P₁ / (1 + L₁) / (P₁ / (1 + L₁) + P₁ / (1 + L₁) / (1 + L₂)) * L₁
          + P₁ / (1 + L₁) / (1 + L₂) / (P₁ / (1 + L₁) + P₁ / (1 + L₁) / (1 + L₂)) * L₂ := by
  have a : (1 + L₁) ≠ 0 := by positivity
  have b : (1 + L₂) ≠ 0 := by positivity
  have c : (2 + L₂) ≠ 0 := by positivity
  have d : P₁ ≠ 0 := hP.ne'
  unfold swapRate
  constructor
  · field_simp
    ring
  · field_simp
    ring

/-- Step 5, the converse. Given the swap rate `S` and a positive second forward `L_2`, the bonds
fix the first forward: `S = (L_1 + L_2 + L_1 L_2)/(2 + L_2)` exactly when
`L_1 = (S (2 + L_2) - L_2) / (1 + L_2)`. And for every positive `L_2` some positive swap rate
makes that first forward negative, so in a swap market model the forwards cannot all be
lognormal. -/
theorem first_forward_from_swap_rate (L₂ : ℝ) (h₂ : 0 < L₂) :
    (∀ S L₁ : ℝ, swapRate L₁ L₂ = S ↔ L₁ = (S * (2 + L₂) - L₂) / (1 + L₂)) ∧
      ∃ S : ℝ, 0 < S ∧ (S * (2 + L₂) - L₂) / (1 + L₂) < 0 := by
  have b : (0 : ℝ) < 1 + L₂ := by linarith
  have c : (0 : ℝ) < 2 + L₂ := by linarith
  refine ⟨fun S L₁ => ?_, ?_⟩
  · unfold swapRate
    rw [div_eq_iff c.ne', eq_div_iff b.ne']
    constructor <;> intro h <;> linarith
  · refine ⟨L₂ / (2 * (2 + L₂)), by positivity, ?_⟩
    apply div_neg_of_neg_of_pos _ b
    have : L₂ / (2 * (2 + L₂)) * (2 + L₂) = L₂ / 2 := by
      field_simp
    rw [this]
    linarith

/-! The card's worked numbers, exactly, in fractions. Forwards 3% and 4%, first-year rate 2.5%
so `P(T_1) = 40/41`, volatilities 20% and 10%. -/

-- Swap rate today: 0.0712 / 2.04 = 89/2550 (3.4902%), from the formula and from the bonds.
example : swapRate (3 / 100) (4 / 100) = 89 / 2550 := by norm_num [swapRate]
example : ((40 / 41 : ℝ) - 40 / 41 / (1 + 3 / 100) / (1 + 4 / 100))
    / (40 / 41 / (1 + 3 / 100) + 40 / 41 / (1 + 3 / 100) / (1 + 4 / 100)) = 89 / 2550 := by
  norm_num

-- Annuity weight of the first forward: P(T_2)/A = 26/51 (0.509804).
example : (40 / 41 / (1 + 3 / 100) : ℝ) / (40 / 41 / (1 + 3 / 100) + 40 / 41 / (1 + 3 / 100) / (1 + 4 / 100))
    = 26 / 51 := by
  norm_num

-- Γ_1 at L_1 = 3%: 0.20 × 0.03 × 1.04 / 0.0712 = 39/445 (8.7640%);
-- at L_1 = 6%: 0.20 × 0.06 × 1.04 / 0.1024 = 39/320 (12.1875%).
example : (1 / 5 : ℝ) * (3 / 100) * (1 + 4 / 100) / (3 / 100 + 4 / 100 + 3 / 100 * (4 / 100))
    = 39 / 445 := by norm_num
example : (1 / 5 : ℝ) * (6 / 100) * (1 + 4 / 100) / (6 / 100 + 4 / 100 + 6 / 100 * (4 / 100))
    = 39 / 320 := by norm_num

-- Moving L_1 from 3% to 6% raises the swap rate's squared volatility: Γ² is not fixed.
example : swapVolSq (1 / 5) (1 / 10) (3 / 100) (4 / 100)
    < swapVolSq (1 / 5) (1 / 10) (6 / 100) (4 / 100) := by
  norm_num [swapVolSq]

-- Step 5: swap rate 1%, second forward 4% force the first forward to -49/2600 (-1.8846%).
example : ((1 / 100 : ℝ) * (2 + 4 / 100) - 4 / 100) / (1 + 4 / 100) = -49 / 2600 := by norm_num
example : swapRate (-49 / 2600) (4 / 100) = 1 / 100 := by norm_num [swapRate]

#print axioms swap_vol_not_deterministic
#print axioms swap_rate_from_bonds
#print axioms first_forward_from_swap_rate
