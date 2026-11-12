-- Diffie-Hellman key exchange: on any clock, with any base and any two kept counts, both sides of the exchange land on the same shared number, the base multiplied out the product of the counts.
import Mathlib.Algebra.Group.Nat.Defs
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Data.Finset.Image
import Mathlib.Data.Finset.Card

/-- The two sides agree: on a clock of size `n` with base `g`, Mia keeps the count `a` and posts
`g ^ a % n`, Ray keeps `b` and posts `g ^ b % n`. Mia multiplies Ray's posting out `a` times,
Ray multiplies Mia's posting out `b` times, and both land on the same number. -/
theorem diffie_hellman_shared_numbers_agree (n g a b : ℕ) :
    (g ^ b % n) ^ a % n = (g ^ a % n) ^ b % n := by
  rw [← Nat.pow_mod, ← Nat.pow_mod, ← pow_mul, ← pow_mul, Nat.mul_comm]

/-- Both routes are one pile: each side's shared number is the base multiplied out `a * b` times
on the clock, so dropping whole clocks along the way changes nothing. -/
theorem diffie_hellman_shared_number_eq_pow_mul (n g a b : ℕ) :
    (g ^ a % n) ^ b % n = g ^ (a * b) % n ∧ (g ^ b % n) ^ a % n = g ^ (a * b) % n := by
  refine ⟨?_, ?_⟩
  · rw [← Nat.pow_mod, ← pow_mul]
  · rw [← Nat.pow_mod, ← pow_mul, Nat.mul_comm]

/-- A product does not care how you group it: `g` multiplied out `a` times, then that answer
multiplied out `b` times, is `g` multiplied out `a * b` times. -/
theorem pow_multiplied_out_eq_pow_mul (g a b : ℕ) : (g ^ a) ^ b = g ^ (a * b) := by
  exact (pow_mul g a b).symm

-- The card's worked numbers: clock 23, base 5, Mia keeps 6, Ray keeps 15.
example : 5 ^ 6 = 15625 ∧ 15625 = 679 * 23 + 8 := by decide
example : 5 ^ 15 = 30517578125 ∧ 30517578125 = 1326851222 * 23 + 19 := by decide
example : 19 ^ 6 = 47045881 ∧ 47045881 = 2045473 * 23 + 2 := by decide
example : 5 ^ 6 % 23 = 8 ∧ 5 ^ 15 % 23 = 19 := by decide
example : 19 ^ 6 % 23 = 2 ∧ 8 ^ 15 % 23 = 2 := by decide
example : 6 * 15 = 90 ∧ 5 ^ 90 % 23 = 2 := by decide
-- The listener tries every count 1 to 22 against 8 and finds only 6; count 7 gives 17.
example : (Finset.Icc 1 22).filter (fun c => 5 ^ c % 23 = 8) = {6} := by decide
example : 5 ^ 7 % 23 = 17 := by decide
-- Mistakes: combining the postings gives 14; base 2 still agrees, on 4, with Mia posting 18.
example : 8 * 19 % 23 = 14 := by decide
example : (2 ^ 15 % 23) ^ 6 % 23 = 4 ∧ 2 ^ 6 % 23 = 18 := by decide
-- Base 5 tours all 22 non-zero slots; base 2 reaches only 11, so its search returns 6 and 17.
example : ((Finset.Icc 1 22).image (fun c => 5 ^ c % 23)).card = 22 := by decide
example : ((Finset.Icc 1 22).image (fun c => 2 ^ c % 23)).card = 11 := by decide
example : (Finset.Icc 1 22).filter (fun c => 2 ^ c % 23 = 18) = {6, 17} := by decide

#print axioms diffie_hellman_shared_numbers_agree
#print axioms diffie_hellman_shared_number_eq_pow_mul
#print axioms pow_multiplied_out_eq_pow_mul
