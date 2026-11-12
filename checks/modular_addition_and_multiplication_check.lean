-- Adding and multiplying on the clock: on every clock, reducing two whole numbers before adding or multiplying lands on the same remainder as reducing after, and on any clock where 10 leaves 1 a number leaves the same remainder as its digit sum.
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Nat.Digits.Lemmas
import Mathlib.Tactic.NormNum

/-- Remainders add and multiply on their own. On a clock with `n` hours, take any two whole
numbers `a` and `b`. Reduce them first and then add (or multiply) and reduce: you land on the
same remainder as adding (or multiplying) first and reducing at the end. -/
theorem reduce_before_or_after_same_remainder (n a b : ℕ) :
    (a + b) % n = (a % n + b % n) % n ∧ (a * b) % n = (a % n * (b % n)) % n := by
  exact ⟨Nat.add_mod a b n, Nat.mul_mod a b n⟩

/-- The card's formula, in the shorthand of congruence. If `a` leaves the same remainder as `a'`
and `b` leaves the same remainder as `b'` on the same clock, then `a + b` leaves the same
remainder as `a' + b'`, and `a × b` the same as `a' × b'`. -/
theorem congruent_numbers_add_and_multiply_to_congruent (n a a' b b' : ℕ)
    (ha : a ≡ a' [MOD n]) (hb : b ≡ b' [MOD n]) :
    a + b ≡ a' + b' [MOD n] ∧ a * b ≡ a' * b' [MOD n] := by
  exact ⟨ha.add hb, ha.mul hb⟩

/-- Why digit sums work. On any clock where 10 leaves the same remainder as 1 (the 9-clock is
one), every whole number leaves the same remainder as the sum of its decimal digits. -/
theorem digit_sum_same_remainder_when_ten_leaves_one (n m : ℕ) (h : 10 ≡ 1 [MOD n]) :
    m ≡ (Nat.digits 10 m).sum [MOD n] := by
  by_cases h1 : n = 1
  · subst h1
    exact Nat.modEq_one
  · have h10 : 10 % n = 1 := by
      have : 1 % n = 1 := by
        rcases Nat.eq_zero_or_pos n with h0 | h0
        · subst h0; rfl
        · exact Nat.mod_eq_of_lt (by omega)
      unfold Nat.ModEq at h
      omega
    exact Nat.modEq_digits_sum n 10 h10 m

-- The receipt: 47 leaves 2 and 23 leaves 5 on the 9-clock.
example : 47 % 9 = 2 ∧ 23 % 9 = 5 := by decide
-- Step 0: 47 = 45 + 2 with 45 five 9s; 23 = 18 + 5 with 18 two 9s.
example : 47 = 5 * 9 + 2 ∧ 23 = 2 * 9 + 5 := by decide
-- Multiplying: 47 × 23 = 1,081, and both roads land on 1.
example : 47 * 23 = 1081 ∧ 1081 % 9 = 1 ∧ (2 * 5) % 9 = 1 := by decide
-- 1,081 by taking 9s away 120 times leaves 1.
example : 1081 = 120 * 9 + 1 := by decide
-- Adding: 47 + 23 = 70, and 70 and 2 + 5 both leave 7.
example : 47 + 23 = 70 ∧ 70 % 9 = 7 ∧ (2 + 5) % 9 = 7 := by decide
-- Digit sums: 47 gives 11, then 2; 23 gives 5; 1,081 gives 10, then 1.
example : (Nat.digits 10 47).sum = 11 ∧ (Nat.digits 10 11).sum = 2 := by norm_num
example : (Nat.digits 10 23).sum = 5 := by norm_num
example : (Nat.digits 10 1081).sum = 10 ∧ (Nat.digits 10 10).sum = 1 := by norm_num
-- 10, 100 and 1,000 each leave 1 on the 9-clock.
example : 10 % 9 = 1 ∧ 100 % 9 = 1 ∧ 1000 % 9 = 1 := by decide
-- A digit total of 9 is remainder 0.
example : 9 % 9 = 0 ∧ 18 % 9 = 0 := by decide
-- The swapped 1,801 passes anyway; the slipped 1,061 leaves 8 and is caught.
example : 1801 % 9 = 1 ∧ 1801 ≠ 1081 := by decide
example : 1061 % 9 = 8 := by decide
-- Dividing does not carry over: 3 × 4 and 3 × 1 both leave 3, yet 4 and 1 do not match.
example : (3 * 4) % 9 = 3 ∧ (3 * 1) % 9 = 3 ∧ 4 % 9 ≠ 1 % 9 := by decide
-- On a 10-clock digit sums fail: 1,061 has digit sum 8, but leaves 1.
example : (Nat.digits 10 1061).sum = 8 ∧ 1061 % 10 = 1 := by norm_num
-- Try changing: 47 × 24 = 1,128 leaves 3, not 1.
example : 47 * 24 = 1128 ∧ 1128 % 9 = 3 := by decide

#print axioms reduce_before_or_after_same_remainder
#print axioms congruent_numbers_add_and_multiply_to_congruent
#print axioms digit_sum_same_remainder_when_ten_leaves_one
