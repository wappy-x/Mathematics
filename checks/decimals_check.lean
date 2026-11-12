-- Decimals: multiplying two stopping decimals is multiplying their whole-number digits and putting the point back by the total count of places, a fraction stops as a decimal exactly when its bottom in lowest terms has no prime factor but 2 and 5, and so one third never stops.
import Mathlib.Data.Rat.Lemmas
import Mathlib.Data.Rat.Cast.Defs
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Data.Nat.Factorization.Induction
import Mathlib.Algebra.Ring.Rat

/-- Helper: a whole number whose prime factors are all 2 or 5 divides some power of ten. -/
theorem aux_dvd_pow_ten (n : ℕ) :
    (∀ p : ℕ, p.Prime → p ∣ n → p = 2 ∨ p = 5) → ∃ k : ℕ, n ∣ 10 ^ k := by
  induction n using induction_on_primes with
  | zero =>
    intro h
    have := h 3 Nat.prime_three (dvd_zero 3)
    omega
  | one => intro _; exact ⟨0, by simp⟩
  | prime_mul p a hp ih =>
    intro h
    obtain ⟨k, hk⟩ := ih (fun q hq hqa => h q hq (dvd_mul_of_dvd_right hqa p))
    have hp' := h p hp (dvd_mul_right p a)
    have hp10 : p ∣ 10 := by
      rcases hp' with rfl | rfl <;> norm_num
    exact ⟨k + 1, by rw [pow_succ, mul_comm (10 ^ k)]; exact mul_dvd_mul hp10 hk⟩

#print axioms aux_dvd_pow_ten

/-- The card's method: a decimal with `m` places is the whole number `a` over ten to the `m`.
To multiply two of them, multiply the whole numbers and put the point back by both counts of
places together: `a` over ten to the `m`, times `b` over ten to the `n`, is `a × b` over ten to
the `m + n` (1.85 × 42.5 is 185 × 425 over a thousand). -/
theorem decimal_mul_clear_points (a b m n : ℕ) :
    ((a : ℚ) / 10 ^ m) * ((b : ℚ) / 10 ^ n) = ((a * b : ℕ) : ℚ) / 10 ^ (m + n) := by
  push_cast
  rw [div_mul_div_comm, pow_add]

/-- Why some fractions never land: a fraction can be written as a stopping decimal, a whole
number over a power of ten, exactly when its bottom in lowest terms is built only from twos and
fives. -/
theorem stops_as_decimal_iff_bottom_twos_and_fives (q : ℚ) :
    (∃ a : ℤ, ∃ m : ℕ, q = (a : ℚ) / 10 ^ m) ↔
      ∀ p : ℕ, p.Prime → p ∣ q.den → p = 2 ∨ p = 5 := by
  constructor
  · rintro ⟨a, m, hq⟩ p hp hpd
    have h1 : q * (10 : ℚ) ^ m = (a : ℚ) := by
      rw [hq]; field_simp
    have h8 : p ∣ 10 ^ m := by
      have h6 : (q.num : ℚ) * (10 ^ m : ℤ) = (a : ℚ) * q.den := by
        have : (q.num : ℚ) = q * q.den := (Rat.mul_den_eq_num q).symm
        rw [this]
        push_cast
        rw [← h1]; ring
      have h7 : q.num * (10 ^ m : ℤ) = a * q.den := by exact_mod_cast h6
      have h7' : (q.den : ℤ) ∣ q.num * (10 ^ m : ℤ) := ⟨a, by rw [h7]; ring⟩
      have h7'' : q.den ∣ q.num.natAbs * 10 ^ m := by
        have := Int.natAbs_dvd_natAbs.mpr h7'
        simpa [Int.natAbs_mul, Int.natAbs_pow] using this
      have hcop : q.den.Coprime q.num.natAbs := q.reduced.symm
      exact hpd.trans (hcop.dvd_of_dvd_mul_left h7'')
    have h9 : p ∣ 10 := hp.dvd_of_dvd_pow h8
    have h10 : p ∣ 2 * 5 := by simpa using h9
    rcases (Nat.Prime.dvd_mul hp).mp h10 with h | h
    · left; exact (Nat.prime_dvd_prime_iff_eq hp Nat.prime_two).mp h
    · right; exact (Nat.prime_dvd_prime_iff_eq hp Nat.prime_five).mp h
  · intro h
    obtain ⟨k, c, hc⟩ := aux_dvd_pow_ten q.den h
    refine ⟨q.num * c, k, ?_⟩
    have hd : (q.den : ℚ) ≠ 0 := by exact_mod_cast q.den_nz
    have hc' : (10 : ℚ) ^ k = q.den * c := by exact_mod_cast hc
    have hq : q = q.num / q.den := (Rat.num_div_den q).symm
    rw [hc']
    push_cast
    conv_lhs => rw [hq]
    have hc0 : (c : ℚ) ≠ 0 := by
      intro h0
      rw [h0] at hc'
      simp at hc'
    field_simp

/-- A third never stops: no whole number over any power of ten equals one third. -/
theorem one_third_never_stops :
    ¬ ∃ a : ℤ, ∃ m : ℕ, (1 / 3 : ℚ) = (a : ℚ) / 10 ^ m := by
  rintro ⟨a, m, h⟩
  have h1 : (10 : ℚ) ^ m = 3 * a := by
    field_simp at h; linarith
  have h2 : (10 : ℤ) ^ m = 3 * a := by exact_mod_cast h1
  have h3 : 3 ∣ 10 ^ m := by
    have : (3 : ℤ) ∣ 10 ^ m := ⟨a, h2⟩
    exact_mod_cast this
  have h4 : 3 ∣ 10 := Nat.prime_three.dvd_of_dvd_pow h3
  omega

-- The fill: $1.85 is 185 over 100, 42.5 litres is 425 over 10, and 185 × 425 = 78625.
example : 185 * 425 = 78625 := by norm_num
-- Two places plus one is three: 185/100 × 425/10 = 78625/1000.
example : (185 / 100 : ℚ) * (425 / 10) = 78625 / 1000 := by norm_num
example : (10 : ℕ) ^ 2 * 10 ^ 1 = 10 ^ 3 := by norm_num
-- The fraction road: 185/100 is 37/20, 425/10 is 85/2, and 37 × 85 over 20 × 2 is 3145/40.
example : (185 / 100 : ℚ) = 37 / 20 ∧ (425 / 10 : ℚ) = 85 / 2 := by norm_num
example : 37 * 85 = 3145 ∧ 20 * 2 = 40 := by norm_num
-- 3145/40 reduces to 629/8, and 629/8 is 78625 thousandths.
example : (3145 / 40 : ℚ) = 629 / 8 := by norm_num
example : (629 / 8 : ℚ) = 78625 / 1000 := by norm_num
example : 629 * 125 = 78625 := by norm_num
-- The bottom 8 is 2 × 2 × 2, built only from twos, so it lands.
example : 8 = 2 * 2 * 2 := by norm_num
-- The adding road in thousandths: 42 litres is 77700, the half litre 925, and they stack.
example : 185 * 420 = 77700 ∧ 185 * 5 = 925 ∧ 77700 + 925 = 78625 := by norm_num
-- The receipt in cents: a half cent goes up, so 78625 thousandths round to 7863 cents.
example : (78625 + 5) / 10 = 7863 := by norm_num
-- The mistakes: cutting gives 7862 cents; 43 litres gives 79550 thousandths, 7955 cents.
example : 78625 / 10 = 7862 := by norm_num
example : 185 * 430 = 79550 ∧ 185 * 430 / 10 = 7955 := by norm_num

#print axioms decimal_mul_clear_points
#print axioms stops_as_decimal_iff_bottom_twos_and_fives
#print axioms one_third_never_stops
