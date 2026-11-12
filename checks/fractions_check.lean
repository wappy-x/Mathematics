-- Fractions: for whole-number tops and nonzero bottoms, fractions add and take away over the common bottom made by multiplying the bottoms, multiply tops by tops and bottoms by bottoms, divide by flipping the second one, keep their size when top and bottom are cut finer or tidied by the same number, and a top shared by a bottom is the whole share plus the leftover over the bottom.
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Data.Rat.Cast.CharZero
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

/-- The rules for fractions, as the card states them. For whole-number tops `a`, `c` and bottoms
`b`, `d` that are never zero:
to add, cut both into pieces of one size (the common bottom `b × d`) and add the tops;
taking away works the same way, taking the tops away over the common bottom;
to multiply, take tops times tops and bottoms times bottoms;
to divide, flip the second fraction and multiply. -/
theorem fraction_add_sub_mul_div_rules (a b c d : ℤ) (hb : b ≠ 0) (hd : d ≠ 0) :
    ((a : ℚ) / b + (c : ℚ) / d = ((a * d + c * b : ℤ) : ℚ) / ((b * d : ℤ) : ℚ)) ∧
    ((a : ℚ) / b - (c : ℚ) / d = ((a * d - c * b : ℤ) : ℚ) / ((b * d : ℤ) : ℚ)) ∧
    ((a : ℚ) / b * ((c : ℚ) / d) = ((a * c : ℤ) : ℚ) / ((b * d : ℤ) : ℚ)) ∧
    ((a : ℚ) / b / ((c : ℚ) / d) = (a : ℚ) / b * ((d : ℚ) / c)) := by
  have hb' : (b : ℚ) ≠ 0 := by exact_mod_cast hb
  have hd' : (d : ℚ) ≠ 0 := by exact_mod_cast hd
  refine ⟨?_, ?_, ?_, ?_⟩
  · push_cast
    field_simp
  · push_cast
    field_simp
  · push_cast
    field_simp
  · field_simp

/-- One amount spelt two ways: multiplying the top and the bottom by the same number cuts the
pieces finer without adding or throwing out anything (1/4 is 2/8), and dividing both by it goes
back, which is tidying. The bottom is never zero, so neither is the number used. -/
theorem fraction_scale_top_and_bottom (a b k : ℤ) (hb : b ≠ 0) (hk : k ≠ 0) :
    ((a * k : ℤ) : ℚ) / ((b * k : ℤ) : ℚ) = (a : ℚ) / b := by
  have hb' : (b : ℚ) ≠ 0 := by exact_mod_cast hb
  have hk' : (k : ℚ) ≠ 0 := by exact_mod_cast hk
  push_cast
  field_simp

/-- A fraction is a division nobody finished: sharing a pile of `n` whole things among `b` people
(`b` not zero) gives each the whole share `n / b` plus the leftover `n % b` cut into `b`-ths, so
the fraction `n / b` equals that share plus `(n % b) / b`. -/
theorem fraction_is_share_plus_leftover (n b : ℕ) (hb : b ≠ 0) :
    (n : ℚ) / b = ((n / b : ℕ) : ℚ) + ((n % b : ℕ) : ℚ) / b := by
  have hb' : (b : ℚ) ≠ 0 := by exact_mod_cast hb
  have h : (n : ℚ) = (b : ℚ) * ((n / b : ℕ) : ℚ) + ((n % b : ℕ) : ℚ) := by
    exact_mod_cast (Nat.div_add_mod n b).symm
  conv_lhs => rw [h]
  field_simp

-- The pizza in eighths: a quarter is two eighths.
example : (1 : ℚ) / 4 = 2 / 8 := by norm_num
-- Together: 3/8 + 1/4 = 3/8 + 2/8 = 5/8.
example : (3 : ℚ) / 8 + 1 / 4 = 3 / 8 + 2 / 8 := by norm_num
example : (3 : ℚ) / 8 + 2 / 8 = 5 / 8 := by norm_num
-- Left in the box: 8/8 − 5/8 = 3/8.
example : (8 : ℚ) / 8 - 5 / 8 = 3 / 8 := by norm_num
-- Half a batch of 3/4 cup: 1/2 × 3/4 = 3/8 cup.
example : (1 : ℚ) / 2 * (3 / 4) = 3 / 8 := by norm_num
-- In 1/8-cup scoops: 3/8 ÷ 1/8 = 3/8 × 8/1 = 3/1, which is 3.
example : (3 : ℚ) / 8 / (1 / 8) = 3 / 8 * (8 / 1) := by norm_num
example : (3 : ℚ) / 8 * (8 / 1) = 3 / 1 := by norm_num
example : (3 : ℚ) / 1 = 3 := by norm_num
-- A fair share of the 8 slices among 3: 8/3, which is 2 slices and 2/3 of a slice.
example : 8 / 3 = 2 ∧ 8 % 3 = 2 := by decide
example : (8 : ℚ) / 3 = 2 + 2 / 3 := by norm_num
-- Mistake: adding tops and bottoms gives 4/12, which tidies to 1/3, less than the 3/8 eaten alone.
example : (3 + 1 : ℚ) / (8 + 4) = 1 / 3 := by norm_num
example : (1 : ℚ) / 3 < 3 / 8 := by norm_num
example : (3 : ℚ) / 8 + 1 / 4 ≠ (3 + 1) / (8 + 4) := by norm_num
-- Mistake: dividing without the flip gives 3/64, a crumb, not 3 scoops.
example : (3 : ℚ) / 8 * (1 / 8) = 3 / 64 := by norm_num
-- Mistake: sharing 8 by 3 and dropping the leftover gives 2, and 3 lots of 2 is only 6.
example : 8 / 3 = 2 ∧ 3 * 2 = 6 := by decide
-- A bigger bottom means smaller pieces: 1/8 of a pizza is less than 1/4.
example : (1 : ℚ) / 8 < 1 / 4 := by norm_num
-- Try changing: a third of a batch is 1/4 cup, which is 2 one-eighth scoops.
example : (1 : ℚ) / 3 * (3 / 4) = 1 / 4 := by norm_num
example : (1 : ℚ) / 4 / (1 / 8) = 2 := by norm_num
-- Try changing: eating 4 of the 8 slices, together with a quarter is 3/4.
example : (4 : ℚ) / 8 + 1 / 4 = 3 / 4 := by norm_num

#print axioms fraction_add_sub_mul_div_rules
#print axioms fraction_scale_top_and_bottom
#print axioms fraction_is_share_plus_leftover
