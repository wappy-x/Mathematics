-- RSA in outline: for two different primes, unlocking a locked message below their product brings it back, the hidden count is the totient of the product, and a private key exists exactly when the public exponent shares no factor with that count.
import Mathlib.Data.Nat.Totient
import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.NormNum.GCD
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.Tactic.IntervalCases

/-- Fermat in the form needed: x^(1 + (p-1) n) ≡ x mod p. -/
theorem fermat_aux {p : ℕ} (hp : p.Prime) (n x : ℕ) :
    x ^ (1 + (p - 1) * n) ≡ x [MOD p] := by
  haveI := Fact.mk hp
  rw [← ZMod.natCast_eq_natCast_iff]
  push_cast
  by_cases hx : (x : ZMod p) = 0
  · rw [hx]; simp
  · rw [pow_add, pow_mul, ZMod.pow_card_sub_one_eq_one hx]; simp

#print axioms fermat_aux

/-- RSA brings the message back: take two different primes p and q, a public exponent e and
a private exponent d with e × d one past a run of (p − 1)(q − 1), and any message m below the
clock size p × q. Raise m to the e-th power with the p × q's taken off, raise that to the d-th
power with the p × q's taken off, and m comes back. -/
theorem rsa_unlock_undoes_lock {p q e d m : ℕ} (hp : p.Prime) (hq : q.Prime) (hpq : p ≠ q)
    (hed : e * d ≡ 1 [MOD (p - 1) * (q - 1)]) (hm : m < p * q) :
    (m ^ e % (p * q)) ^ d % (p * q) = m := by
  have hp2 := hp.two_le
  have hq2 := hq.two_le
  have hcop : p.Coprime q := (Nat.coprime_primes hp hq).mpr hpq
  have hk1 : 2 ≤ (p - 1) * (q - 1) := by
    by_contra hlt
    have hpos : 0 < (p - 1) * (q - 1) := Nat.mul_pos (by omega) (by omega)
    have h1 : (p - 1) * (q - 1) = 1 := by omega
    rw [mul_eq_one] at h1
    omega
  have hmod : (e * d) % ((p - 1) * (q - 1)) = 1 := by
    have h := hed
    unfold Nat.ModEq at h
    rw [h]
    exact Nat.mod_eq_of_lt hk1
  have hdiv : e * d = 1 + (p - 1) * (q - 1) * (e * d / ((p - 1) * (q - 1))) := by
    have := Nat.mod_add_div (e * d) ((p - 1) * (q - 1))
    omega
  set n := e * d / ((p - 1) * (q - 1)) with hn
  have h1 : m ^ (e * d) ≡ m [MOD p] := by
    have h := fermat_aux hp ((q - 1) * n) m
    have e1 : e * d = 1 + (p - 1) * ((q - 1) * n) := by rw [hdiv, mul_assoc]
    rw [e1]; exact h
  have h2 : m ^ (e * d) ≡ m [MOD q] := by
    have h := fermat_aux hq ((p - 1) * n) m
    have e1 : e * d = 1 + (q - 1) * ((p - 1) * n) := by
      rw [hdiv, mul_comm (p - 1) (q - 1), mul_assoc]
    rw [e1]; exact h
  have h3 : m ^ (e * d) ≡ m [MOD p * q] :=
    (Nat.modEq_and_modEq_iff_modEq_mul hcop).mp ⟨h1, h2⟩
  have h4 : (m ^ e % (p * q)) ^ d ≡ m [MOD p * q] := by
    have : (m ^ e % (p * q)) ^ d ≡ (m ^ e) ^ d [MOD p * q] :=
      Nat.ModEq.pow d (Nat.mod_modEq _ _)
    rw [← pow_mul] at this
    exact this.trans h3
  unfold Nat.ModEq at h4
  rw [h4]
  exact Nat.mod_eq_of_lt hm

/-- The hidden count: for two different primes p and q, the numbers from 1 to p × q sharing no
factor above 1 with p × q number (p − 1)(q − 1). -/
theorem totient_mul_two_primes {p q : ℕ} (hp : p.Prime) (hq : q.Prime) (hpq : p ≠ q) :
    Nat.totient (p * q) = (p - 1) * (q - 1) := by
  rw [Nat.totient_mul ((Nat.coprime_primes hp hq).mpr hpq), Nat.totient_prime hp,
    Nat.totient_prime hq]

/-- A private key exists exactly when the public exponent shares no factor with the hidden
count: some d makes e × d one past a run of k precisely when e and k are coprime. -/
theorem private_key_exists_iff_coprime (e k : ℕ) :
    (∃ d, e * d ≡ 1 [MOD k]) ↔ Nat.Coprime e k := by
  constructor
  · rintro ⟨d, hd⟩
    exact Nat.coprime_of_mul_modEq_one d hd
  · intro h
    rcases Nat.lt_or_ge 1 k with hk | hk
    · obtain ⟨m, -, hm⟩ := Nat.exists_mul_mod_eq_one_of_coprime h hk
      exact ⟨m, by unfold Nat.ModEq; rw [hm, Nat.mod_eq_of_lt hk]⟩
    · interval_cases k
      · have : e = 1 := by simpa using h
        subst this
        exact ⟨1, by simp [Nat.ModEq]⟩
      · exact ⟨0, by simp [Nat.ModEq]⟩

-- Making the keys.
example : Nat.Prime 61 := by norm_num
example : Nat.Prime 53 := by norm_num
example : 61 * 53 = 3233 := by norm_num
example : (61 - 1) * (53 - 1) = 3120 := by norm_num
example : 3233 - 53 - 61 + 1 = 3120 := by norm_num
example : Nat.totient 3233 = 3120 := by decide +kernel
example : Nat.gcd 17 3120 = 1 := by norm_num
example : 17 * 2753 = 46801 ∧ 46801 = 15 * 3120 + 1 := by norm_num
example : 17 * 2753 ≡ 1 [MOD 3120] := by decide
-- Lock and unlock.
example : 65 ^ 17 % 3233 = 2790 := by decide +kernel
example : 2790 ^ 2753 % 3233 = 65 := by decide +kernel
example : 65 ^ 3120 % 3233 = 1 := by decide +kernel
example : 65 ^ 46801 % 3233 = 65 := by decide +kernel
-- What breaks if you drop a piece.
example : 2790 ^ 17 % 3233 = 1452 := by decide +kernel
example : 17 * 2092 % 3233 = 1 ∧ 2790 ^ 2092 % 3233 = 2699 := by decide +kernel
example : 3298 = 65 + 3233 ∧ (3298 ^ 17 % 3233) ^ 2753 % 3233 = 65 := by decide +kernel

#print axioms rsa_unlock_undoes_lock
#print axioms totient_mul_two_primes
#print axioms private_key_exists_iff_coprime
