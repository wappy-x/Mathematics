-- Percentages: a cut or a rise by a percent is one multiply by 100 minus or plus that percent over 100, dividing by the same multiply undoes it, a cut then a rise never equals the single cut you get by adding the percents unless one of them is zero, and the card's jacket and dinner numbers come out as it says.
import Mathlib.Algebra.Field.Rat
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-- A cut or a rise in one multiply: an amount with `p` percent added on is the amount
times `100 + p`, divided by 100; an amount with `p` percent taken off is the amount
times `100 - p`, divided by 100. (The part, `p` percent of `a`, is `a × p ÷ 100`.) -/
theorem percent_rise_and_cut_in_one_multiply (a p : ℚ) :
    a + a * p / 100 = a * (100 + p) / 100 ∧
    a - a * p / 100 = a * (100 - p) / 100 := by
  constructor <;> ring

/-- To undo a step, divide by the same multiply: if a step multiplied the amount by `m`
and divided by 100 (`m = 100 + p` for a rise, `100 - p` for a cut), then multiplying
the result by 100 and dividing by `m` gives back the amount. -/
theorem undo_percent_step_by_same_multiply (a m : ℚ) (hm : m ≠ 0) :
    a * m / 100 * 100 / m = a := by
  field_simp

/-- Percents do not add: a cut of `p` percent followed by a rise of `q` percent, each taken
of the amount it meets, equals a single cut of `p - q` percent only when the amount is zero
or one of the two percents is zero. -/
theorem percents_do_not_add (a p q : ℚ) :
    a * (100 - p) / 100 * (100 + q) / 100 = a * (100 - (p - q)) / 100 ↔
      a = 0 ∨ p = 0 ∨ q = 0 := by
  have key : a * (100 - p) / 100 * (100 + q) / 100 - a * (100 - (p - q)) / 100
      = -(a * p * q) / 10000 := by ring
  constructor
  · intro h
    have h0 : -(a * p * q) / 10000 = 0 := by rw [← key, h]; ring
    have h1 : a * p * q = 0 := by linarith
    rcases mul_eq_zero.mp h1 with h2 | h2
    · rcases mul_eq_zero.mp h2 with h3 | h3
      · exact Or.inl h3
      · exact Or.inr (Or.inl h3)
    · exact Or.inr (Or.inr h2)
  · intro h
    have h1 : a * p * q = 0 := by
      rcases h with h | h | h <;> simp [h]
    have : a * (100 - p) / 100 * (100 + q) / 100 - a * (100 - (p - q)) / 100 = 0 := by
      rw [key, h1]; ring
    linarith

-- The card's worked numbers, in whole cents.
example : 8000 * 25 / 100 = 2000 := by decide            -- 25% of the $80.00 tag
example : 8000 - 2000 = 6000 := by decide                -- sale price
example : 8000 * (100 - 25) / 100 = 6000 := by decide    -- the same, in one multiply
example : 6000 * 8 / 100 = 480 := by decide              -- 8% tax on the sale price
example : 6000 + 480 = 6480 := by decide                 -- total at the till
example : 6000 * (100 + 8) / 100 = 6480 := by decide     -- the same, in one multiply
example : 6480 * 100 / 108 = 6000 := by decide           -- undo the tax
example : 6000 * 100 / 75 = 8000 := by decide            -- undo the cut
example : 8000 * 108 / 100 * 75 / 100 = 6480 := by decide -- tax first, then the sale
example : 4600 * 15 / 100 = 690 := by decide             -- 15% tip on the $46.00 dinner
example : 4600 * 18 / 100 = 828 := by decide             -- the same tip at 18%
example : 75 * 108 / 100 = 81 := by decide               -- 25% off then 8% on is 81% of the tag
-- The mistakes.
example : 8000 * (100 - 17) / 100 = 6640 := by decide    -- adding the percents
example : 6000 * (100 + 25) / 100 = 7500 := by decide    -- adding 25% back
example : (690 * 103 + 50) / 100 = 711 := by decide      -- "3% more tip", to the nearest cent

#print axioms percent_rise_and_cut_in_one_multiply
#print axioms undo_percent_step_by_same_multiply
#print axioms percents_do_not_add
