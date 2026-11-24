-- Binary quadratic forms: a whole number n is reached with coprime inputs by some form ax² + bxy + cy² of discriminant D exactly when D is a square mod 4n, a renaming of cross number 1 keeps the discriminant, and the two forms of discriminant −20 take primes at 1 or 9 and at 3 or 7 mod 20.
import Mathlib.Algebra.QuadraticDiscriminant
import Mathlib.Data.Int.GCD
import Mathlib.RingTheory.Coprime.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Int.ModEq


/-- Residue check mod 20 for `x² + 5y²`. -/
theorem bqf_mod20_form_one : ∀ a b : ZMod 20,
    (a ^ 2 + 5 * b ^ 2).val % 2 = 1 → (a ^ 2 + 5 * b ^ 2).val % 5 ≠ 0 →
      (a ^ 2 + 5 * b ^ 2).val = 1 ∨ (a ^ 2 + 5 * b ^ 2).val = 9 := by
  decide

/-- Residue check mod 20 for `2x² + 2xy + 3y²`. -/
theorem bqf_mod20_form_two : ∀ a b : ZMod 20,
    (2 * a ^ 2 + 2 * a * b + 3 * b ^ 2).val % 2 = 1 →
      (2 * a ^ 2 + 2 * a * b + 3 * b ^ 2).val % 5 ≠ 0 →
      (2 * a ^ 2 + 2 * a * b + 3 * b ^ 2).val = 3 ∨
        (2 * a ^ 2 + 2 * a * b + 3 * b ^ 2).val = 7 := by
  decide

/-- An odd prime other than 5 is odd and prime to 5, read off mod 20. -/
theorem bqf_prime_mod20 (p : ℕ) (hp : p.Prime) (hp2 : p ≠ 2) (hp5 : p ≠ 5) :
    (p : ZMod 20).val % 2 = 1 ∧ (p : ZMod 20).val % 5 ≠ 0 := by
  rw [ZMod.val_natCast, Nat.mod_mod_of_dvd p (by norm_num : 2 ∣ 20),
    Nat.mod_mod_of_dvd p (by norm_num : 5 ∣ 20)]
  refine ⟨?_, ?_⟩
  · rcases Nat.mod_two_eq_zero_or_one p with h | h
    · exfalso
      have h2 : 2 ∣ p := Nat.dvd_of_mod_eq_zero h
      exact hp2 ((Nat.prime_dvd_prime_iff_eq Nat.prime_two hp).mp h2).symm
    · exact h
  · intro h
    have h5 : 5 ∣ p := Nat.dvd_of_mod_eq_zero h
    exact hp5 ((Nat.prime_dvd_prime_iff_eq Nat.prime_five hp).mp h5).symm

#print axioms bqf_mod20_form_one
#print axioms bqf_mod20_form_two
#print axioms bqf_prime_mod20

/-! A form `(a, b, c)` stands for `a x² + b x y + c y²` with whole `a, b, c`. Its discriminant
is Mathlib's `discrim a b c = b² − 4ac`. The form properly represents `n` when
`n = a x² + b x y + c y²` for some whole `x, y` with no common factor but 1 (`IsCoprime x y`). -/

/-- **The test.** A whole number `n` is properly represented by some form of discriminant `D`
(some whole `a, b, c` with `b² − 4ac = D`, and coprime whole `x, y` with
`a x² + b x y + c y² = n`) exactly when `D` is a square on a clock of `4n` hours:
`b² ≡ D (mod 4n)` for some whole `b`. -/
theorem properly_represented_iff_discrim_square_mod_four_n (n D : ℤ) :
    (∃ a b c : ℤ, discrim a b c = D ∧
        ∃ x y : ℤ, IsCoprime x y ∧ a * x ^ 2 + b * x * y + c * y ^ 2 = n) ↔
      ∃ b : ℤ, b ^ 2 ≡ D [ZMOD 4 * n] := by
  constructor
  · rintro ⟨a, b, c, hD, x, y, ⟨u, v, huv⟩, hn⟩
    refine ⟨2 * a * x * (-v) + b * (x * u + y * (-v)) + 2 * c * y * u, ?_⟩
    have hcross : x * u - y * (-v) = 1 := by linarith
    have key : (2 * a * x * (-v) + b * (x * u + y * (-v)) + 2 * c * y * u) ^ 2
        - 4 * (a * x ^ 2 + b * x * y + c * y ^ 2) * (a * (-v) ^ 2 + b * (-v) * u + c * u ^ 2)
        = (x * u - y * (-v)) ^ 2 * (b ^ 2 - 4 * a * c) := by ring
    rw [hcross, hn] at key
    rw [Int.modEq_iff_dvd]
    refine ⟨-(a * (-v) ^ 2 + b * (-v) * u + c * u ^ 2), ?_⟩
    rw [← hD]
    unfold discrim
    linarith
  · rintro ⟨b, hb⟩
    obtain ⟨k, hk⟩ := (Int.modEq_iff_dvd).mp hb
    refine ⟨n, b, -k, ?_, 1, 0, isCoprime_one_left, by ring⟩
    unfold discrim
    linarith

/-- **A renaming keeps the discriminant.** Substitute `x = pX + rY`, `y = qX + sY` with cross
number `ps − qr = 1`. The form `(a, b, c)` becomes the form
`(f(p, q), 2apr + b(ps + qr) + 2cqs, f(r, s))`, which gives the same value at `(X, Y)` as the old
form at `(x, y)` and has the same discriminant. -/
theorem renaming_keeps_discriminant (a b c p q r s : ℤ) (hcross : p * s - q * r = 1) :
    (∀ X Y : ℤ,
        (a * p ^ 2 + b * p * q + c * q ^ 2) * X ^ 2
            + (2 * a * p * r + b * (p * s + q * r) + 2 * c * q * s) * X * Y
            + (a * r ^ 2 + b * r * s + c * s ^ 2) * Y ^ 2 =
          a * (p * X + r * Y) ^ 2 + b * (p * X + r * Y) * (q * X + s * Y)
            + c * (q * X + s * Y) ^ 2) ∧
      discrim (a * p ^ 2 + b * p * q + c * q ^ 2)
          (2 * a * p * r + b * (p * s + q * r) + 2 * c * q * s)
          (a * r ^ 2 + b * r * s + c * s ^ 2) = discrim a b c := by
  refine ⟨fun X Y => by ring, ?_⟩
  have h : discrim (a * p ^ 2 + b * p * q + c * q ^ 2)
      (2 * a * p * r + b * (p * s + q * r) + 2 * c * q * s)
      (a * r ^ 2 + b * r * s + c * s ^ 2) = (p * s - q * r) ^ 2 * discrim a b c := by
    unfold discrim
    ring
  rw [h, hcross]
  ring

/-- **Which form gets which prime.** For a prime `p` other than 2 and 5: if `x² + 5y² = p` then
`p` is 1 or 9 mod 20, and if `2x² + 2xy + 3y² = p` then `p` is 3 or 7 mod 20. -/
theorem discrim_neg_twenty_forms_sort_primes_mod_twenty (p : ℕ) (hp : p.Prime)
    (hp2 : p ≠ 2) (hp5 : p ≠ 5) :
    (∀ x y : ℤ, x ^ 2 + 5 * y ^ 2 = (p : ℤ) → p % 20 = 1 ∨ p % 20 = 9) ∧
      (∀ x y : ℤ, 2 * x ^ 2 + 2 * x * y + 3 * y ^ 2 = (p : ℤ) → p % 20 = 3 ∨ p % 20 = 7) := by
  obtain ⟨hodd, h5⟩ := bqf_prime_mod20 p hp hp2 hp5
  have hv : (p : ZMod 20).val = p % 20 := ZMod.val_natCast 20 p
  refine ⟨fun x y h => ?_, fun x y h => ?_⟩
  · have hz := congrArg (fun t : ℤ => (t : ZMod 20)) h
    simp only [Int.cast_add, Int.cast_mul, Int.cast_pow, Int.cast_ofNat,
      Int.cast_natCast] at hz
    have := bqf_mod20_form_one (x : ZMod 20) (y : ZMod 20)
    rw [hz] at this
    rw [← hv]
    exact this hodd h5
  · have hz := congrArg (fun t : ℤ => (t : ZMod 20)) h
    simp only [Int.cast_add, Int.cast_mul, Int.cast_pow, Int.cast_ofNat,
      Int.cast_natCast] at hz
    have := bqf_mod20_form_two (x : ZMod 20) (y : ZMod 20)
    rw [hz] at this
    rw [← hv]
    exact this hodd h5

/-! The card's worked numbers. -/

-- Both forms have discriminant −20: 0² − 4 × 1 × 5 and 2² − 4 × 2 × 3.
example : discrim (1 : ℤ) 0 5 = -20 ∧ discrim (2 : ℤ) 2 3 = -20 := by norm_num [discrim]
-- 29 = 3² + 5 × 2², with 3 and 2 coprime; 7 = 2 + 2 + 3 at x = y = 1.
example : (3 : ℤ) ^ 2 + 5 * 2 ^ 2 = 29 ∧ Int.gcd 3 2 = 1 := by decide
example : 2 * (1 : ℤ) ^ 2 + 2 * 1 * 1 + 3 * 1 ^ 2 = 7 := by decide
-- Partner point (1, 1): cross number 3 × 1 − 2 × 1 = 1; the new form is (29, 26, 6).
example : (3 : ℤ) * 1 - 2 * 1 = 1 := by decide
example : (1 : ℤ) * 3 ^ 2 + 0 * 3 * 2 + 5 * 2 ^ 2 = 29 ∧
    2 * 1 * 3 * 1 + 0 * (3 * 1 + 2 * 1) + 2 * 5 * 2 * 1 = (26 : ℤ) ∧
    (1 : ℤ) * 1 ^ 2 + 0 * 1 * 1 + 5 * 1 ^ 2 = 6 := by decide
-- Its discriminant: 26² − 4 × 29 × 6 = −20. The test: 26² + 20 = 696 = 6 × 116, so 26² ≡ −20 (mod 116).
example : discrim (29 : ℤ) 26 6 = -20 := by norm_num [discrim]
example : (26 : ℤ) ^ 2 + 20 = 696 ∧ (696 : ℤ) = 6 * 116 := by decide
example : (26 : ℤ) ^ 2 ≡ -20 [ZMOD 4 * 29] := by decide
-- The converse for 23: b = 16, c = (16² + 20) ÷ 92 = 3, the form (23, 16, 3) of discriminant −20.
example : (16 : ℤ) ^ 2 ≡ -20 [ZMOD 4 * 23] ∧ ((16 : ℤ) ^ 2 + 20) / 92 = 3 := by decide
example : discrim (23 : ℤ) 16 3 = -20 := by norm_num [discrim]
-- 4 = 2² + 5 × 0² is not proper: −20 is no square mod 16, though mod 4 it has roots 0 and 2.
example : ∀ b : ZMod 16, b ^ 2 ≠ -20 := by decide
example : (0 : ℤ) ^ 2 ≡ -20 [ZMOD 4] ∧ (2 : ℤ) ^ 2 ≡ -20 [ZMOD 4] := by decide
-- 13 fails the test: −20 is no square mod 52.
example : ∀ b : ZMod (4 * 13), b ^ 2 ≠ -20 := by decide
-- Misreading the middle coefficient of 2xy as 1 gives 1 − 4 × 2 × 3 = −23.
example : discrim (2 : ℤ) 1 3 = -23 := by norm_num [discrim]
-- Primes below 100 reached by x² + 5y²: 29, 41, 61, 89, all 1 or 9 mod 20.
example : (3 : ℤ) ^ 2 + 5 * 2 ^ 2 = 29 ∧ (6 : ℤ) ^ 2 + 5 * 1 ^ 2 = 41 ∧
    (4 : ℤ) ^ 2 + 5 * 3 ^ 2 = 61 ∧ (3 : ℤ) ^ 2 + 5 * 4 ^ 2 = 89 := by decide
example : 29 % 20 = 9 ∧ 41 % 20 = 1 ∧ 61 % 20 = 1 ∧ 89 % 20 = 9 := by decide
-- Primes below 100 reached by 2x² + 2xy + 3y²: 3, 7, 23, 43, 47, 67, 83, all 3 or 7 mod 20.
example : 2 * (0 : ℤ) ^ 2 + 2 * 0 * 1 + 3 * 1 ^ 2 = 3 ∧
    2 * (1 : ℤ) ^ 2 + 2 * 1 * 1 + 3 * 1 ^ 2 = 7 ∧
    2 * (-1 : ℤ) ^ 2 + 2 * (-1) * 3 + 3 * 3 ^ 2 = 23 ∧
    2 * (4 : ℤ) ^ 2 + 2 * 4 * 1 + 3 * 1 ^ 2 = 43 ∧
    2 * (2 : ℤ) ^ 2 + 2 * 2 * 3 + 3 * 3 ^ 2 = 47 ∧
    2 * (-1 : ℤ) ^ 2 + 2 * (-1) * 5 + 3 * 5 ^ 2 = 67 ∧
    2 * (4 : ℤ) ^ 2 + 2 * 4 * 3 + 3 * 3 ^ 2 = 83 := by decide
example : 3 % 20 = 3 ∧ 7 % 20 = 7 ∧ 23 % 20 = 3 ∧ 43 % 20 = 3 ∧ 47 % 20 = 7 ∧
    67 % 20 = 7 ∧ 83 % 20 = 3 := by decide
-- 21 = 4² + 5 × 1² lands on the first form.
example : (4 : ℤ) ^ 2 + 5 * 1 ^ 2 = 21 := by decide

#print axioms properly_represented_iff_discrim_square_mod_four_n
#print axioms renaming_keeps_discriminant
#print axioms discrim_neg_twenty_forms_sort_primes_mod_twenty
