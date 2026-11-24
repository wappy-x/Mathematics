-- Square roots on a prime clock: when p is a prime leaving 3 on division by 4, a^((p+1)/4) is a square root of every square a on the p clock, a nonzero square on an odd prime clock has exactly the two roots x and p - x, and two unrelated square roots of the same number on an n clock give a proper factor of n through a gcd.
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Group.Even
import Mathlib.Algebra.Field.ZMod
import Mathlib.Tactic.NormNum.GCD
import Mathlib.FieldTheory.Finite.Basic

/-- The shortcut: on a prime clock of size p, where p leaves 3 on division by 4, if a is a
square then a to the power (p + 1)/4 is a square root of a. -/
theorem pow_p_add_one_div_four_sq_eq {p : ℕ} [Fact p.Prime] (hp : p % 4 = 3) {a : ZMod p}
    (ha : IsSquare a) : (a ^ ((p + 1) / 4)) ^ 2 = a := by
  obtain ⟨r, rfl⟩ := ha
  have h4 : 4 * ((p + 1) / 4) = p + 1 := by omega
  calc ((r * r) ^ ((p + 1) / 4)) ^ 2 = r ^ (4 * ((p + 1) / 4)) := by ring
    _ = r ^ p * r := by rw [h4, pow_succ]
    _ = r * r := by rw [ZMod.pow_card]

/-- Two roots: on an odd prime clock, a nonzero square x × x has exactly two square roots,
x and p − x (that is, −x), and these two are different. -/
theorem sq_eq_sq_iff_eq_or_eq_neg_of_odd_prime {p : ℕ} [Fact p.Prime] (hp : p ≠ 2)
    {x : ZMod p} (hx : x ≠ 0) :
    (∀ y : ZMod p, y ^ 2 = x ^ 2 ↔ y = x ∨ y = -x) ∧ x ≠ -x := by
  refine ⟨fun y => sq_eq_sq_iff_eq_or_eq_neg, ?_⟩
  intro h
  have h2 : (2 : ZMod p) ≠ 0 := Ring.two_ne_zero (by rw [ZMod.ringChar_zmod_n]; exact hp)
  have : (2 : ZMod p) * x = 0 := by linear_combination h
  rcases mul_eq_zero.mp this with h' | h'
  · exact h2 h'
  · exact hx h'

/-- Roots give factors: if x and y are square roots of the same number on an n clock
(n divides x² − y²) and they are unrelated (n divides neither x − y nor x + y), then the
gcd of x − y and n is a factor of n strictly between 1 and n. -/
theorem gcd_sub_proper_factor_of_unrelated_roots {n : ℕ} {x y : ℤ}
    (hsq : (n : ℤ) ∣ x ^ 2 - y ^ 2) (hsub : ¬ (n : ℤ) ∣ x - y) (hadd : ¬ (n : ℤ) ∣ x + y) :
    1 < Int.gcd (x - y) n ∧ Int.gcd (x - y) n < n := by
  have hfac : x ^ 2 - y ^ 2 = (x - y) * (x + y) := by ring
  rw [hfac] at hsq
  have hn0 : n ≠ 0 := by
    rintro rfl
    simp only [Nat.cast_zero, zero_dvd_iff] at hsq hsub hadd
    rcases mul_eq_zero.mp hsq with h | h
    · exact hsub h
    · exact hadd h
  have hg_dvd : (Int.gcd (x - y) n : ℤ) ∣ (n : ℤ) := Int.gcd_dvd_right _ _
  have hg_dvd' : Int.gcd (x - y) n ∣ n := by exact_mod_cast hg_dvd
  have hg_pos : 0 < Int.gcd (x - y) n := Int.gcd_pos_of_ne_zero_right _ (by exact_mod_cast hn0)
  constructor
  · by_contra hle
    have hg1 : Int.gcd (x - y) n = 1 := by omega
    have hcop : IsCoprime (n : ℤ) (x - y) := by
      rw [Int.isCoprime_iff_gcd_eq_one, Int.gcd_comm]; exact hg1
    exact hadd (hcop.dvd_of_dvd_mul_left hsq)
  · rcases lt_or_eq_of_le (Nat.le_of_dvd (Nat.pos_of_ne_zero hn0) hg_dvd') with h | h
    · exact h
    · exfalso
      apply hsub
      have : (Int.gcd (x - y) n : ℤ) ∣ x - y := Int.gcd_dvd_left _ _
      rw [h] at this
      exact this

-- Mod 23 (23 leaves 3 on division by 4): the power is (23 + 1)/4 = 6, 2^6 = 64 = 2 × 23 + 18,
-- 18^2 = 324 = 14 × 23 + 2, the other root is 23 − 18 = 5, and 2^11 lands on 1.
example : 23 % 4 = 3 ∧ (23 + 1) / 4 = 6 ∧ 2 ^ 6 = 64 ∧ 64 = 2 * 23 + 18 ∧
    18 ^ 2 = 324 ∧ 324 = 14 * 23 + 2 ∧ 23 - 18 = 5 ∧ 2 ^ 11 % 23 = 1 := by norm_num
example : (2 : ZMod 23) ^ ((23 + 1) / 4) = 18 ∧ (18 : ZMod 23) ^ 2 = 2 ∧ (5 : ZMod 23) ^ 2 = 2 := by
  decide
-- On 23 the square roots of 2 are exactly 5 and 18, and 5 has none.
example : (List.range 23).filter (fun x => x * x % 23 = 2) = [5, 18] := by decide
example : (List.range 23).filter (fun x => x * x % 23 = 5) = [] := by decide
-- The curve y^2 = x^3 + 7 at x = 4: 71 = 3 × 23 + 2.
example : 4 ^ 3 + 7 = 71 ∧ 71 = 3 * 23 + 2 := by norm_num
-- Mod 41: 3^20 lands on 40 (3 is a non-square), 2^20 and 10^10 land on 1, and 40 = 2^3 × 5.
example : 41 % 4 = 1 ∧ 40 = 2 ^ 3 * 5 ∧ 3 ^ 20 % 41 = 40 ∧ 2 ^ 20 % 41 = 1 ∧ 10 ^ 10 % 41 = 1 := by
  norm_num
-- Tonelli-Shanks on 41: for 10, guess 10^3 = 16 with error 10^5 = 1; for 2, guess 2^3 = 8,
-- error 2^5 = 32, fix 3^5 = 38, and 8 × 38 lands on 17.
example : 10 ^ 3 % 41 = 16 ∧ 10 ^ 5 % 41 = 1 ∧ 2 ^ 3 = 8 ∧ 2 ^ 5 = 32 ∧ 3 ^ 5 % 41 = 38 ∧
    32 ^ 2 % 41 = 40 ∧ 38 ^ 2 % 41 = 9 ∧ 9 ^ 2 % 41 = 40 ∧ 8 * 38 % 41 = 17 := by norm_num
-- 16^2 = 256 = 6 × 41 + 10; the roots of 10 on 41 are 16 and 25, the roots of 2 are 17 and 24.
example : 16 ^ 2 = 256 ∧ 256 = 6 * 41 + 10 ∧ 17 ^ 2 % 41 = 2 := by norm_num
example : (List.range 41).filter (fun x => x * x % 41 = 10) = [16, 25] := by decide
example : (List.range 41).filter (fun x => x * x % 41 = 2) = [17, 24] := by decide
-- Mod 77 = 7 × 11: 4 has the four roots 2, 9, 68, 75; gcd(9 − 2, 77) = 7, gcd(75 − 2, 77) = 1.
example : 77 = 7 * 11 := by norm_num
example : (List.range 77).filter (fun x => x * x % 77 = 4) = [2, 9, 68, 75] := by decide
example : Nat.gcd (9 - 2) 77 = 7 ∧ Nat.gcd (68 - 2) 77 = 11 ∧ Nat.gcd (75 - 2) 77 = 1 ∧
    Nat.gcd (9 + 2) 77 = 11 := by norm_num

#print axioms pow_p_add_one_div_four_sq_eq
#print axioms sq_eq_sq_iff_eq_or_eq_neg_of_odd_prime
#print axioms gcd_sub_proper_factor_of_unrelated_roots
