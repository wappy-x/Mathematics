-- Divisibility rules: for every whole number, 2, 4, 5, 8 and 10 are decided by its last one, two or three digits, 3 and 9 by its digit sum, and 6 by the 2 test and the 3 test together, while the digit sum works for no other divisor on the card.
import Mathlib.Data.Nat.Digits.Div
import Mathlib.Tactic.NormNum

/-- The card's table, for every whole number `n`. The last digit is `n % 10`, the last two
digits are `n % 100`, the last three are `n % 1000`, and the digit sum is the sum of the base-ten
digits of `n`.
- 2 divides `n` exactly when the last digit is even.
- 3 divides `n` exactly when 3 divides the digit sum.
- 4 divides `n` exactly when 4 divides the last two digits.
- 5 divides `n` exactly when the last digit is 0 or 5.
- 6 divides `n` exactly when `n` passes the 2 test and the 3 test.
- 8 divides `n` exactly when 8 divides the last three digits.
- 9 divides `n` exactly when 9 divides the digit sum.
- 10 divides `n` exactly when the last digit is 0. -/
theorem divisibility_rules_read_the_tail_or_the_digit_sum (n : ℕ) :
    (2 ∣ n ↔ Even (n % 10)) ∧
    (3 ∣ n ↔ 3 ∣ (Nat.digits 10 n).sum) ∧
    (4 ∣ n ↔ 4 ∣ n % 100) ∧
    (5 ∣ n ↔ n % 10 = 0 ∨ n % 10 = 5) ∧
    (6 ∣ n ↔ Even (n % 10) ∧ 3 ∣ (Nat.digits 10 n).sum) ∧
    (8 ∣ n ↔ 8 ∣ n % 1000) ∧
    (9 ∣ n ↔ 9 ∣ (Nat.digits 10 n).sum) ∧
    (10 ∣ n ↔ n % 10 = 0) := by
  have h3 := Nat.three_dvd_iff n
  have h9 := Nat.nine_dvd_iff n
  simp only [Nat.even_iff]
  refine ⟨by omega, h3, by omega, by omega, ?_, by omega, h9, by omega⟩
  rw [← h3]
  omega

/-- The digit sum only for 3 and 9. Among the card's divisors 2, 3, 4, 5, 6, 8, 9 and 10, the
digit-sum test gives the right answer for every whole number exactly when the divisor is 3 or 9.
For every other one, some number gets the wrong answer. -/
theorem digit_sum_test_works_only_for_three_and_nine (d : ℕ)
    (hd : d ∈ ({2, 3, 4, 5, 6, 8, 9, 10} : Finset ℕ)) :
    (∀ n : ℕ, d ∣ n ↔ d ∣ (Nat.digits 10 n).sum) ↔ d = 3 ∨ d = 9 := by
  simp only [Finset.mem_insert, Finset.mem_singleton] at hd
  constructor
  · intro h
    rcases hd with rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl
    · have := (h 11).mpr (by norm_num); omega
    · simp
    · have := (h 22).mpr (by norm_num); omega
    · have := (h 14).mpr (by norm_num); omega
    · have := (h 39).mpr (by norm_num); omega
    · have := (h 44).mpr (by norm_num); omega
    · simp
    · have := (h 19).mpr (by norm_num); omega
  · rintro (rfl | rfl)
    · exact Nat.three_dvd_iff
    · exact Nat.nine_dvd_iff

/-- The two ways to get the 8 test wrong. Two tail digits are not enough for 8: some number
is a multiple of 8 although its last two digits are not. And the 2 test and the 4 test together
are no test for 8: some number passes both and still is not a multiple of 8. -/
theorem eight_needs_three_digits_and_not_two_and_four :
    (∃ n : ℕ, ¬ (8 ∣ n ↔ 8 ∣ n % 100)) ∧
    (∃ n : ℕ, 2 ∣ n ∧ 4 ∣ n ∧ ¬ 8 ∣ n) := by
  exact ⟨⟨1136, by decide⟩, ⟨12, by decide, by decide, by decide⟩⟩

/-! The card's worked numbers for the $1,236 bill. -/

-- The digit sum: 1 + 2 + 3 + 6 = 12.
example : (Nat.digits 10 1236).sum = 12 := by norm_num

-- The table, row by row.
example : 1236 = 2 * 618 := by norm_num
example : 1236 = 3 * 412 := by norm_num
example : 1236 = 4 * 309 := by norm_num
example : 1236 = 5 * 247 + 1 := by norm_num
example : 1236 = 6 * 206 := by norm_num
example : 1236 = 8 * 154 + 4 := by norm_num
example : 1236 = 9 * 137 + 3 := by norm_num
example : 1236 = 10 * 123 + 6 := by norm_num

-- The verdicts: 2, 3, 4 and 6 divide the bill; 5, 8, 9 and 10 do not.
example : 2 ∣ 1236 ∧ 3 ∣ 1236 ∧ 4 ∣ 1236 ∧ 6 ∣ 1236 := by decide
example : ¬ 5 ∣ 1236 ∧ ¬ 8 ∣ 1236 ∧ ¬ 9 ∣ 1236 ∧ ¬ 10 ∣ 1236 := by decide

-- Where the rules cut: 1236 = 1230 + 6 = 1200 + 36 = 1000 + 236,
-- and 10 = 2 × 5, 100 = 4 × 25, 1000 = 8 × 125.
example : 1236 = 1230 + 6 ∧ 1236 = 1200 + 36 ∧ 1236 = 1000 + 236 := by norm_num
example : 10 = 2 * 5 ∧ 100 = 4 * 25 ∧ 1000 = 8 * 125 := by norm_num

-- The tails: 36 splits four ways; 236 leaves 4 over on 8, the bill's own leftover.
example : 1236 % 100 = 36 ∧ 36 = 4 * 9 := by norm_num
example : 1236 % 1000 = 236 ∧ 236 % 8 = 4 ∧ 1236 % 8 = 4 := by norm_num

-- Sweeping the nines: 1 × 999 + 2 × 99 + 3 × 9 = 1224 = 9 × 136, and 1236 = 1224 + 12.
example : 1 * 999 + 2 * 99 + 3 * 9 = 1224 ∧ 1224 = 9 * 136 ∧ 1236 = 1224 + 12 := by norm_num

-- The digit sum 12 is a multiple of 3 and runs 3 past 9.
example : 12 = 3 * 4 ∧ 12 = 9 + 3 := by norm_num

-- Two digits say no on a $1,136 bill, but 1,136 = 8 × 142.
example : 1136 = 8 * 142 ∧ ¬ 8 ∣ 1136 % 100 := by decide

-- 12 passes the 2 test and the 4 test, but fails 8.
example : 2 ∣ 12 ∧ 4 ∣ 12 ∧ ¬ 8 ∣ 12 := by decide

#print axioms divisibility_rules_read_the_tail_or_the_digit_sum
#print axioms digit_sum_test_works_only_for_three_and_nine
#print axioms eight_needs_three_digits_and_not_two_and_four
