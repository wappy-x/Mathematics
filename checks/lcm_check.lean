-- Least common multiple: for any two whole numbers of 1 or more, the smallest number both go into is their product divided by their greatest common divisor, so the gcd times that smallest shared multiple is the product, and every shared multiple is a multiple of the smallest one.
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Order.Bounds.Defs
import Mathlib.Tactic.NormNum

/-! The least common multiple is written here as the card defines it: the smallest number of 1 or
more that both `a` and `b` go into, `IsLeast {m | 0 < m ∧ a ∣ m ∧ b ∣ m}`. Mathlib's `Nat.lcm` is
used only to check the worked numbers. -/

theorem lcm_set_isLeast_aux (a b : ℕ) (ha : 0 < a) (hb : 0 < b) :
    IsLeast {m : ℕ | 0 < m ∧ a ∣ m ∧ b ∣ m} (a * b / Nat.gcd a b) := by
  have h : a * b / Nat.gcd a b = Nat.lcm a b := rfl
  rw [h]
  refine ⟨⟨Nat.lcm_pos ha hb, Nat.dvd_lcm_left a b, Nat.dvd_lcm_right a b⟩, ?_⟩
  rintro n ⟨_, h1, h2⟩
  exact Nat.le_of_dvd (by assumption) (Nat.lcm_dvd h1 h2)

#print axioms lcm_set_isLeast_aux

theorem lcm_set_eq_aux (a b m : ℕ) (ha : 0 < a) (hb : 0 < b)
    (hm : IsLeast {m : ℕ | 0 < m ∧ a ∣ m ∧ b ∣ m} m) : m = Nat.lcm a b :=
  hm.unique (lcm_set_isLeast_aux a b ha hb)

#print axioms lcm_set_eq_aux

/-- The card's main claim. For two whole loop lengths of 1 beat or more, the first beat both
loops come round on is the two lengths multiplied, divided by the biggest number going into
both. -/
theorem first_shared_multiple_eq_product_div_gcd (a b : ℕ) (ha : 0 < a) (hb : 0 < b) :
    IsLeast {m : ℕ | 0 < m ∧ a ∣ m ∧ b ∣ m} (a * b / Nat.gcd a b) := by
  exact lcm_set_isLeast_aux a b ha hb

/-- The title's link. Whatever the first shared beat of two loops of 1 beat or more is, the
greatest common divisor times it equals the two lengths multiplied. -/
theorem gcd_mul_first_shared_multiple_eq_product (a b m : ℕ) (ha : 0 < a) (hb : 0 < b)
    (hm : IsLeast {m : ℕ | 0 < m ∧ a ∣ m ∧ b ∣ m} m) :
    Nat.gcd a b * m = a * b := by
  rw [lcm_set_eq_aux a b m ha hb hm]
  exact Nat.gcd_mul_lcm a b

/-- Step 1. Every shared beat is a multiple of the first one: a number is a multiple of both
loop lengths exactly when the first shared beat goes into it. -/
theorem shared_multiples_are_multiples_of_first (a b m : ℕ) (ha : 0 < a) (hb : 0 < b)
    (hm : IsLeast {m : ℕ | 0 < m ∧ a ∣ m ∧ b ∣ m} m) (n : ℕ) :
    (a ∣ n ∧ b ∣ n) ↔ m ∣ n := by
  rw [lcm_set_eq_aux a b m ha hb hm]
  exact Nat.lcm_dvd_iff.symm

-- The drum (6 beats) and the bass (8 beats): 24 is in both lists and nothing from 1 to 23 is.
example : 6 ∣ 24 ∧ 8 ∣ 24 ∧ ∀ m < 24, 0 < m → ¬(6 ∣ m ∧ 8 ∣ m) := by decide
-- The drum's multiples 6, 12, 18, 24 and the bass's 8, 16, 24.
example : 6 * 1 = 6 ∧ 6 * 2 = 12 ∧ 6 * 3 = 18 ∧ 6 * 4 = 24 ∧ 8 * 1 = 8 ∧ 8 * 2 = 16 ∧ 8 * 3 = 24 := by
  decide
-- lcm(6, 8) = 24, gcd(6, 8) = 2, and 2 × 24 = 48 = 6 × 8.
example : Nat.lcm 6 8 = 24 ∧ Nat.gcd 6 8 = 2 ∧ Nat.gcd 6 8 * Nat.lcm 6 8 = 6 * 8 ∧ 6 * 8 = 48 := by
  decide
-- The short way: 48 ÷ 2 = 24. Dividing by 1 instead gives 48, a shared beat but not the first.
example : 48 / 2 = 24 ∧ 48 / 1 = 48 ∧ 6 ∣ 48 ∧ 8 ∣ 48 ∧ 24 < 48 := by decide
-- From the primes: 6 = 2 × 3, 8 = 2 × 2 × 2, and three 2s with one 3 make 24.
example : 2 * 3 = 6 ∧ 2 * 2 * 2 = 8 ∧ 2 * 2 * 2 * 3 = 24 := by decide
-- Over 24 beats the drum plays 4 loops and the bass 3; at 120 beats a minute that is 12 seconds.
example : 24 / 6 = 4 ∧ 24 / 8 = 3 ∧ 24 * 60 / 120 = 12 := by decide
-- The three mistakes: 6 × 8 = 48 (the second shared beat), 6 + 8 = 14 (neither comes round),
-- and 8 (the drum is mid-pattern).
example : 6 * 8 = 48 ∧ 6 + 8 = 14 ∧ ¬ 6 ∣ 14 ∧ ¬ 8 ∣ 14 ∧ ¬ 6 ∣ 8 := by decide
-- Start the bass a beat late: the drum only comes round on even beats, the bass then only on odd ones.
example : ∀ j < 24, ∀ k < 24, 6 * j ≠ 8 * k + 1 := by decide
-- Try changing: a 7-beat bass shares nothing but 1 with 6, so the first shared beat is 6 × 7;
-- a 4-beat drum goes into 8, so the first shared beat is 8 and the gcd is 4.
example : Nat.gcd 6 7 = 1 ∧ Nat.lcm 6 7 = 42 ∧ 6 * 7 = 42 := by decide
example : Nat.gcd 4 8 = 4 ∧ Nat.lcm 4 8 = 8 := by decide

#print axioms first_shared_multiple_eq_product_div_gcd
#print axioms gcd_mul_first_shared_multiple_eq_product
#print axioms shared_multiples_are_multiples_of_first
