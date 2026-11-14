-- The TLS handshake: both ends of a Diffie–Hellman exchange reach the same secret g^ab mod p by every road, an honest RSA signature on the transcript passes the check σ^e mod n = h mod n, and the card's toy handshake numbers are exact.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.ReduceModChar
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum.NatSqrt
import Mathlib.FieldTheory.Finite.Basic

theorem fermat_pow_modEq_aux (p h k : ℕ) (hp : p.Prime) :
    h ^ (k * (p - 1) + 1) ≡ h [MOD p] := by
  have := Fact.mk hp
  rw [← ZMod.natCast_eq_natCast_iff]
  push_cast
  by_cases h0 : (h : ZMod p) = 0
  · rw [h0]; simp
  · rw [pow_succ, mul_comm k, pow_mul, ZMod.pow_card_sub_one_eq_one h0, one_pow, one_mul]

#print axioms fermat_pow_modEq_aux

/-- Diffie–Hellman agreement: whatever the modulus p, generator g and secret exponents a and b,
the laptop's value B^a mod p (with B = g^b mod p) equals the bank's value A^b mod p
(with A = g^a mod p), and both equal g^(ab) mod p. So both ends land on the same secret Z. -/
theorem diffie_hellman_shared_secret_agrees (p g a b : ℕ) :
    (g ^ b % p) ^ a % p = (g ^ a % p) ^ b % p ∧
      (g ^ a % p) ^ b % p = g ^ (a * b) % p := by
  refine ⟨?_, ?_⟩
  · rw [← Nat.pow_mod, ← Nat.pow_mod, ← pow_mul, ← pow_mul, mul_comm]
  · rw [← Nat.pow_mod, ← pow_mul]

/-- The exponent road: if the powers of g repeat after q steps (g^q mod p = 1, as when g has
order q), then g raised to (ab mod q) gives the same secret as g raised to ab, mod p. -/
theorem shared_secret_by_exponent_mod_order (p g q a b : ℕ) (hq : g ^ q % p = 1) :
    g ^ (a * b % q) % p = g ^ (a * b) % p := by
  have hp1 : p ≠ 1 := by
    rintro rfl
    rw [Nat.mod_one] at hq
    exact Nat.zero_ne_one hq
  conv_rhs => rw [← Nat.mod_add_div (a * b) q, pow_add, pow_mul, Nat.mul_mod, Nat.pow_mod (g ^ q), hq, one_pow]
  rw [Nat.one_mod_eq_one.mpr hp1, mul_one, Nat.mod_mod]

/-- The signature check: for an RSA key n = p·q with p and q distinct primes and
e·d ≡ 1 mod (p − 1)(q − 1), the honest signature σ = h^d mod n on any hash value h passes
the laptop's check σ^e mod n = h mod n. -/
theorem rsa_signature_verifies (p q e d h : ℕ) (hp : p.Prime) (hq : q.Prime) (hpq : p ≠ q)
    (hed : e * d % ((p - 1) * (q - 1)) = 1) :
    (h ^ d % (p * q)) ^ e % (p * q) = h % (p * q) := by
  rw [← Nat.pow_mod, ← pow_mul]
  have hsplit : d * e = (e * d / ((p - 1) * (q - 1)) * (q - 1)) * (p - 1) + 1 := by
    have := Nat.div_add_mod (e * d) ((p - 1) * (q - 1))
    rw [hed] at this
    rw [mul_comm d e]
    nth_rewrite 1 [← this]
    ring
  have hsplit' : d * e = (e * d / ((p - 1) * (q - 1)) * (p - 1)) * (q - 1) + 1 := by
    rw [hsplit]; ring
  have h1 : h ^ (d * e) ≡ h [MOD p] := by rw [hsplit]; exact fermat_pow_modEq_aux _ _ _ hp
  have h2 : h ^ (d * e) ≡ h [MOD q] := by rw [hsplit']; exact fermat_pow_modEq_aux _ _ _ hq
  exact (Nat.modEq_and_modEq_iff_modEq_mul ((Nat.coprime_primes hp hq).mpr hpq)).mp ⟨h1, h2⟩

-- The card's toy group: p = 2q + 1 with q above 2^60, and g = 4 has powers that repeat
-- after q steps. Arithmetic mod p is written in ZMod p, the integers mod p.
example : (2305843009213699919 : ℕ) = 2 * 1152921504606849959 + 1 := by norm_num
example : (2 : ℕ) ^ 60 < 1152921504606849959 := by norm_num
example : (4 : ZMod 2305843009213699919) ^ 1152921504606849959 = 1 := by reduce_mod_char

-- The laptop's share A = 4^a mod p and the bank's share B = 4^b mod p.
example : (4 : ZMod 2305843009213699919) ^ 1060721914930473132 = 1437164254505495502 := by
  reduce_mod_char
example : (4 : ZMod 2305843009213699919) ^ 17370367526383645 = 2024737343351428284 := by
  reduce_mod_char

-- The shared secret Z three ways: B^a, A^b and g^(ab mod q), all mod p.
example : (2024737343351428284 : ZMod 2305843009213699919) ^ 1060721914930473132
    = 1685396047651910608 := by reduce_mod_char
example : (1437164254505495502 : ZMod 2305843009213699919) ^ 17370367526383645
    = 1685396047651910608 := by reduce_mod_char
example : (1060721914930473132 * 17370367526383645 % 1152921504606849959 : ℕ)
    = 681595347508187921 := by norm_num
example : (4 : ZMod 2305843009213699919) ^ 681595347508187921 = 1685396047651910608 := by
  reduce_mod_char

-- Generic attacks cost about √q steps: √q lies between 2^30 and 2^31 in the toy.
example : 2 ^ 30 ≤ Nat.sqrt 1152921504606849959 ∧ Nat.sqrt 1152921504606849959 < 2 ^ 31 := by
  norm_num

-- A seed from a process number has 32768 = 2^15 possibilities: 15 bits.
example : (32768 : ℕ) = 2 ^ 15 := by norm_num

#print axioms diffie_hellman_shared_secret_agrees
#print axioms shared_secret_by_exponent_mod_order
#print axioms rsa_signature_verifies
