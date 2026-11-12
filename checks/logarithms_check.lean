-- Logarithms: for a base bigger than 1 and a number above 0 that is a whole power of the base, the log is exactly the count of the base multiplied together to reach the number, both as the whole-number count of divisions and as the real log, and no power of the base is 0 or negative.
import Mathlib.Data.Nat.Log
import Mathlib.Data.Nat.Digits.Lemmas
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.NatLog

/-- A logarithm is the answer to one question: how many of the base, multiplied together, got
me to this number? Take a base `b` bigger than 1 and a number `x` above 0 that is a whole power
of the base. Then the whole-number log `Nat.log b x` (divide by the base until you reach 1 and
count the divisions) is that count: `k` copies of the base multiply to `x` exactly when the log
of `x` is `k`. In particular the road back agrees: `b ^ (Nat.log b x) = x`. -/
theorem log_is_the_count_of_multiplies (b x : ℕ) (hb : 1 < b) (hx : 0 < x)
    (hpow : ∃ k : ℕ, b ^ k = x) :
    ∀ k : ℕ, b ^ k = x ↔ Nat.log b x = k := by
  intro k
  obtain ⟨m, rfl⟩ := hpow
  rw [Nat.log_pow hb]
  constructor
  · intro h
    exact (Nat.pow_right_injective hb h).symm
  · intro h
    rw [h]

/-- The same count is the logarithm of real numbers: for a real base `b` bigger than 1 and a
real number `x` above 0 that is a whole power of the base, `k` copies of the base multiply to
`x` exactly when the log base `b` of `x` is `k`. -/
theorem real_logb_is_the_count_of_multiplies (b x : ℝ) (hb : 1 < b) (hx : 0 < x)
    (hpow : ∃ k : ℕ, b ^ k = x) :
    ∀ k : ℕ, b ^ k = x ↔ Real.logb b x = k := by
  intro k
  obtain ⟨m, rfl⟩ := hpow
  have hb0 : 0 < b := by linarith
  have hlog : Real.logb b (b ^ m) = m := by
    rw [Real.logb_pow, Real.logb_self_eq_one hb]
    simp
  rw [hlog]
  constructor
  · intro h
    have : k = m := (pow_right_injective₀ hb0 (ne_of_gt hb) h)
    rw [this]
  · intro h
    have : m = k := by exact_mod_cast h
    rw [this]

/-- Why 0 and negative numbers have no log: multiply a base bigger than 1 by itself however
many times you like and the answer stays above 0, so it never lands on 0 or a negative
number. -/
theorem power_of_base_never_zero_or_negative (b : ℝ) (hb : 1 < b) (x : ℝ) (hx : x ≤ 0)
    (k : ℕ) : b ^ k ≠ x := by
  intro h
  have hpos : 0 < b ^ k := pow_pos (by linarith) k
  linarith

-- The magnitude scale: the swings for magnitudes 4 to 7 are 10^4 to 10^7.
example : 10 ^ 4 = 10000 ∧ 10 ^ 5 = 100000 ∧ 10 ^ 6 = 1000000 ∧ 10 ^ 7 = 10000000 := by
  norm_num
example : Nat.log 10 10000 = 4 := by norm_num
example : Nat.log 10 100000 = 5 := by norm_num
example : Nat.log 10 1000000 = 6 := by norm_num
example : Nat.log 10 10000000 = 7 := by norm_num
-- Seven tens multiplied make ten million.
example : 10 * 10 * 10 * 10 * 10 * 10 * 10 = 10000000 := by norm_num
-- Worked numbers: magnitude 5 is five tens; each step up is one more ten.
example : 10 * 10 * 10 * 10 * 10 = 100000 := by norm_num
example : 100000 * 10 = 1000000 ∧ 1000000 * 10 = 10000000 := by norm_num
-- Dividing ten million by ten: 1000000, 100000, 10000, 1000, 100, 10, 1, seven divisions.
example : 10000000 / 10 = 1000000 ∧ 1000000 / 10 = 100000 ∧ 100000 / 10 = 10000 ∧
    10000 / 10 = 1000 ∧ 1000 / 10 = 100 ∧ 100 / 10 = 10 ∧ 10 / 10 = 1 := by norm_num
-- A 7 against a 6 is ten times the swing; a 7 against a 5 is a hundred times.
example : 10000000 / 1000000 = 10 ∧ 10000000 % 1000000 = 0 := by norm_num
example : 10000000 / 100000 = 100 ∧ 10000000 % 100000 = 0 := by norm_num
-- A different base: five halvings from 32 down to 1, so the log base 2 of 32 is 5.
example : 32 / 2 = 16 ∧ 16 / 2 = 8 ∧ 8 / 2 = 4 ∧ 4 / 2 = 2 ∧ 2 / 2 = 1 := by norm_num
example : Nat.log 2 32 = 5 := by norm_num
-- The empty case: 1 needs no multiplying, so its log is 0.
example : Nat.log 10 1 = 0 := by norm_num
example : Nat.log 2 1 = 0 := by norm_num
-- The real log agrees on the card's numbers.
example : Real.logb 10 10000000 = 7 := by
  rw [show (10000000 : ℝ) = 10 ^ (7 : ℕ) by norm_num, Real.logb_pow,
    Real.logb_self_eq_one (by norm_num)]
  norm_num
example : Real.logb 2 32 = 5 := by
  rw [show (32 : ℝ) = 2 ^ (5 : ℕ) by norm_num, Real.logb_pow, Real.logb_self_eq_one (by norm_num)]
  norm_num
-- Mistake: subtracting the magnitudes gives 2, but the real ratio is 100.
example : 7 - 5 = 2 ∧ 10 ^ 7 / 10 ^ 5 = 100 := by norm_num
-- Mistake: 10,000,000 has eight digits but a log of 7.
example : (Nat.digits 10 10000000).length = 8 := by norm_num
-- Mistake: 32 divided by 2 is 16, not the log base 2 of 32.
example : 32 / 2 = 16 := by norm_num
-- Try changing: a magnitude 8 swing of 100,000,000 has log 8.
example : Nat.log 10 100000000 = 8 := by norm_num
-- Try changing: 5,000,000 divides down to 5 and stops, since 5 is not a multiple of ten.
example : 5000000 / 1000000 = 5 ∧ 5 % 10 ≠ 0 := by norm_num
example : ∀ k : ℕ, 10 ^ k ≠ 5000000 := by
  intro k h
  rcases lt_trichotomy k 6 with hk | rfl | hk
  · have : 10 ^ k ≤ 10 ^ 5 := Nat.pow_le_pow_right (by norm_num) (by omega)
    omega
  · norm_num at h
  · have : 10 ^ 7 ≤ 10 ^ k := Nat.pow_le_pow_right (by norm_num) hk
    omega

#print axioms log_is_the_count_of_multiplies
#print axioms real_logb_is_the_count_of_multiplies
#print axioms power_of_base_never_zero_or_negative
