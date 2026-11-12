-- The modular inverse: a key a has an inverse on a clock of size n, a number b with a × b ≡ 1 (mod n), exactly when a and n are coprime, that inverse is the only one up to whole turns of the clock, and so a coprime key can be cancelled.
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Int.ModEq
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Data.Int.GCD

/-- The modular inverse. On a clock of size n, a key a can be undone by multiplying, that is,
some whole number b gives a × b ≡ 1 (mod n), a whole number of turns plus 1, exactly when a and n
are coprime: they share no factor above 1. -/
theorem modular_inverse_exists_iff_coprime (a n : ℕ) :
    (∃ b : ℕ, a * b ≡ 1 [MOD n]) ↔ Nat.Coprime a n := by
  constructor
  · rintro ⟨b, hb⟩
    have h := hb.gcd_eq
    rw [Nat.gcd_one_left] at h
    exact (Nat.coprime_mul_iff_left.1 h).1
  · intro h
    rcases Nat.lt_or_ge 1 n with hn | hn
    · obtain ⟨m, -, hm⟩ := Nat.exists_mul_mod_eq_one_of_coprime h hn
      exact ⟨m, by rw [Nat.ModEq, hm, Nat.mod_eq_of_lt hn]⟩
    · rcases (by omega : n = 0 ∨ n = 1) with rfl | rfl
      · have : a = 1 := by simpa using h
        exact ⟨1, by subst this; exact Nat.ModEq.refl _⟩
      · exact ⟨0, Nat.modEq_one⟩

/-- Only one inverse. If a key a is coprime to the clock size n, it has an inverse b, and every
other number c with a × c ≡ 1 (mod n) lands on the same slot as b. -/
theorem modular_inverse_unique (a n : ℕ) (h : Nat.Coprime a n) :
    ∃ b : ℕ, a * b ≡ 1 [MOD n] ∧ ∀ c : ℕ, a * c ≡ 1 [MOD n] → c ≡ b [MOD n] := by
  obtain ⟨b, hb⟩ := (modular_inverse_exists_iff_coprime a n).2 h
  refine ⟨b, hb, fun c hc => ?_⟩
  exact Nat.ModEq.cancel_left_of_coprime (by rw [Nat.gcd_comm]; exact h) (hc.trans hb.symm)

/-- Cancelling is safe. If a key a is coprime to the clock size n, and a times one letter x lands
on the same slot as a times another letter y, then x and y are on the same slot. -/
theorem cancel_coprime_key (a n x y : ℕ) (h : Nat.Coprime a n) (hxy : a * x ≡ a * y [MOD n]) :
    x ≡ y [MOD n] := by
  exact Nat.ModEq.cancel_left_of_coprime (by rw [Nat.gcd_comm]; exact h) hxy

-- The cipher: H is 7 goes to 23 (X), I is 8 goes to 4 (E), so HI goes out as XE.
example : 7 * 7 = 49 ∧ 49 = 1 * 26 + 23 ∧ (7 * 7) % 26 = 23 ∧ (8 * 7) % 26 = 4 := by decide
-- Reading back with 15: X is 23, 23 × 15 = 345, thirteen alphabets and 7 over; E is 4 goes back to 8.
example : 23 * 15 = 345 ∧ 345 = 13 * 26 + 7 ∧ (4 * 15) % 26 = 8 ∧ 4 * 15 = 60 := by decide
-- The formula: 7 × 15 = 105 = 4 × 26 + 1, so 7 × 15 ≡ 1 (mod 26).
example : 7 * 15 = 105 ∧ 105 = 4 * 26 + 1 ∧ 7 * 15 ≡ 1 [MOD 26] := by decide
-- As plain numbers no whole number times 7 makes 1.
example : ∀ k : ℕ, 7 * k ≠ 1 := by omega
-- Key 7 and 26 are coprime; key 13 shares 13 with 26.
example : Nat.gcd 7 26 = 1 ∧ Nat.Coprime 7 26 ∧ Nat.gcd 13 26 = 13 := by norm_num
-- Euclid down: 26 = 3 × 7 + 5, 7 = 1 × 5 + 2, 5 = 2 × 2 + 1.
example : 26 = 3 * 7 + 5 ∧ 7 = 1 * 5 + 2 ∧ 5 = 2 * 2 + 1 := by decide
-- Euclid back up: 1 = 5 − 2 × 2 = 3 × 5 − 2 × 7 = 3 × 26 − 11 × 7 = 78 − 77.
example : (1 : ℤ) = 5 - 2 * 2 ∧ (1 : ℤ) = 3 * 5 - 2 * 7 ∧ (1 : ℤ) = 3 * 26 - 11 * 7 ∧
    (3 : ℤ) * 26 = 78 ∧ (11 : ℤ) * 7 = 77 := by decide
-- So 7 × (−11) + 26 × 3 = 1, and −11 + 26 = 15: −11 and 15 are the same slot.
example : (7 : ℤ) * (-11) + 26 * 3 = 1 ∧ (-11 : ℤ) + 26 = 15 ∧ (-11 : ℤ) ≡ 15 [ZMOD 26] := by decide
-- By search, 15 is the only k from 0 to 25 with 7 × k ≡ 1 (mod 26).
example : ∀ k < 26, (7 * k) % 26 = 1 ↔ k = 15 := by decide
-- Key 13: 13 times any letter lands only on 0 or 13, never on 1.
example : ∀ k < 26, (13 * k) % 26 = 0 ∨ (13 * k) % 26 = 13 := by decide
example : ∀ k < 26, (13 * k) % 26 ≠ 1 := by decide
-- Key 13 sends H (7) and J (9) both to 13, that is N.
example : (13 * 7) % 26 = 13 ∧ (13 * 9) % 26 = 13 := by decide
-- The three mistakes: reading X (23) with 7, 3 and 13 gives 5, 17 and 13.
example : (23 * 7) % 26 = 5 ∧ (23 * 3) % 26 = 17 ∧ (23 * 13) % 26 = 13 := by decide
-- Try changing: key 5 is coprime to 26 too, with inverse 21, and 5 × 21 = 105.
example : Nat.Coprime 5 26 ∧ 5 * 21 = 105 ∧ 5 * 21 ≡ 1 [MOD 26] := by norm_num [Nat.ModEq]

#print axioms modular_inverse_exists_iff_coprime
#print axioms modular_inverse_unique
#print axioms cancel_coprime_key
