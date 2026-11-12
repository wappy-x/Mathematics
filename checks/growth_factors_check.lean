-- Growth factors: two percent changes, each taken of the price it meets, come to the start times the product of the two growth factors, which matches adding the percents only when the price or one change is zero; a rise and a cut of the same percent leave a positive price lower; a rise is undone by a smaller cut; and the card's jacket prices come out exactly as it says.
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

/-- Percent changes chain by multiplying the factors, never by adding the percents.
Start at price `p`. Apply a change `r` (a decimal, negative for a cut) of that price, giving
`p₁ = p + p × r`; then a change `s` of the price it meets, giving `p₂ = p₁ + p₁ × s`.
Then the result is the start times one growth factor, `(1 + r) × (1 + s)`. And it equals what
adding the percents would give, `p + p × (r + s)`, only when the price or one of the changes
is zero. -/
theorem percent_changes_chain_by_multiplying (p r s p₁ p₂ : ℝ)
    (h₁ : p₁ = p + p * r) (h₂ : p₂ = p₁ + p₁ * s) :
    p₂ = p * ((1 + r) * (1 + s)) ∧
      (p₂ = p + p * (r + s) ↔ p = 0 ∨ r = 0 ∨ s = 0) := by
  subst h₂ h₁
  refine ⟨by ring, ?_⟩
  constructor
  · intro h
    have h3 : p * r * s = 0 := by linarith
    rcases mul_eq_zero.mp h3 with h4 | h4
    · rcases mul_eq_zero.mp h4 with h5 | h5
      · exact Or.inl h5
      · exact Or.inr (Or.inl h5)
    · exact Or.inr (Or.inr h4)
  · rintro (h | h | h) <;> subst h <;> ring

/-- Same percent up, same percent down, lands below the start: for a positive price `p` and
any nonzero change `r`, a rise by `r` then a cut by `r` (factors `1 + r` and `1 - r`) leaves
the price strictly lower than it began. -/
theorem same_percent_up_then_down_lands_lower (p r : ℝ) (hp : 0 < p) (hr : r ≠ 0) :
    p * (1 + r) * (1 - r) < p := by
  have hr2 : 0 < r ^ 2 := by positivity
  have : p * (1 + r) * (1 - r) = p - p * r ^ 2 := by ring
  rw [this]
  nlinarith [mul_pos hp hr2]

/-- To undo a factor, divide by it, so a rise is undone by a smaller cut, never a matching
one: for a rise `r > 0`, the cut `r / (1 + r)` (factor `1 / (1 + r)`) brings the price
exactly back, and that cut is strictly smaller than the rise. -/
theorem rise_undone_by_smaller_cut (r : ℝ) (hr : 0 < r) :
    (1 + r) * (1 - r / (1 + r)) = 1 ∧ r / (1 + r) < r := by
  have h1 : (1 + r) ≠ 0 := by linarith
  refine ⟨?_, ?_⟩
  · field_simp
    ring
  · exact div_lt_self hr (by linarith)

-- The card's jacket, in exact fractions of a dollar: 1.25 = 5/4, 0.75 = 3/4, 0.80 = 4/5.
example : (80 : ℚ) * (1 + 1 / 4) = 100 := by norm_num              -- 25% rise
example : (100 : ℚ) * (1 - 1 / 4) = 75 := by norm_num              -- 25% sale
example : (5 / 4 : ℚ) * (3 / 4) = 15 / 16 := by norm_num           -- the season as one factor, 0.9375
example : (80 : ℚ) * (15 / 16) = 75 := by norm_num
example : (1 : ℚ) - 15 / 16 = 1 / 16 := by norm_num                -- 6.25% down
example : (80 : ℚ) * (3 / 4) * (5 / 4) = 75 := by norm_num         -- sale first, same $75
example : (80 : ℚ) * (3 / 4) = 60 := by norm_num
example : (1 : ℚ) / (5 / 4) = 4 / 5 := by norm_num                 -- undoing the rise
example : (100 : ℚ) * (4 / 5) = 80 := by norm_num
-- The second jacket: half off, then half on.
example : (80 : ℚ) * (1 / 2) = 40 := by norm_num
example : (40 : ℚ) * (3 / 2) = 60 := by norm_num
example : (1 / 2 : ℚ) * (3 / 2) = 3 / 4 := by norm_num
-- The three mistakes.
example : (80 : ℚ) * 1 = 80 := by norm_num                         -- +25 and -25 read as no change
example : (80 : ℚ) * (1 / 4) = 20 := by norm_num                   -- the part used as the factor
example : (80 : ℚ) * (5 / 4 + 3 / 4) = 160 := by norm_num          -- factors added
-- Try changing: a 20% sale after the rise is back to $80; half off needs a 100% rise.
example : (100 : ℚ) * (1 - 1 / 5) = 80 := by norm_num
example : (40 : ℚ) * (1 + 1) = 80 := by norm_num
-- A 5% rise is factor 1.05.
example : (1 : ℚ) + 5 / 100 = 105 / 100 := by norm_num

#print axioms percent_changes_chain_by_multiplying
#print axioms same_percent_up_then_down_lands_lower
#print axioms rise_undone_by_smaller_cut
