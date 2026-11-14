-- Diffie-Hellman and ElGamal: both sides of the exchange reach the same key g^(ab), ElGamal decryption always returns the message, and in a group of prime size every member except 1 generates the whole group.
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.GroupTheory.SpecificGroups.Cyclic
import Mathlib.Tactic.NormNum.Prime

/-- Diffie-Hellman agreement: powers commute. If laptop 1 posts `A = g ^ a` and laptop 2 posts
`B = g ^ b`, then laptop 1's key `B ^ a` and laptop 2's key `A ^ b` are the same member,
`g ^ (a * b)`, and since exponents wrap at the order of `g` (the group size `q`), it is also
`g ^ (a * b mod q)`, the card's third road. -/
theorem diffie_hellman_keys_agree {G : Type*} [Monoid G] (g A B : G) (a b : ℕ)
    (hA : A = g ^ a) (hB : B = g ^ b) :
    B ^ a = A ^ b ∧ A ^ b = g ^ (a * b) ∧ g ^ (a * b) = g ^ (a * b % orderOf g) := by
  subst hA hB
  refine ⟨?_, ?_, (pow_mod_orderOf g (a * b)).symm⟩
  · rw [← pow_mul, ← pow_mul, mul_comm]
  · rw [← pow_mul]

/-- ElGamal decryption always works: with public key `h = g ^ x`, ciphertext
`c₁ = g ^ r` and `c₂ = m * h ^ r`, dividing `c₂` by `c₁ ^ x` gives back the message `m`. -/
theorem elgamal_decrypt_correct {G : Type*} [Group G] (g h m c₁ c₂ : G) (x r : ℕ)
    (hh : h = g ^ x) (hc₁ : c₁ = g ^ r) (hc₂ : c₂ = m * h ^ r) :
    c₂ / c₁ ^ x = m := by
  subst hh hc₁ hc₂
  rw [← pow_mul, ← pow_mul, mul_comm x r, mul_div_cancel_right]

/-- In a group of prime size, every member's order divides that prime, so it is 1 or the prime:
every member except 1 generates the whole group. -/
theorem prime_order_group_every_nonidentity_generates {G : Type*} [Group G]
    (hq : (Nat.card G).Prime) (g : G) (hg : g ≠ 1) :
    Subgroup.zpowers g = ⊤ := by
  have : Fact (Nat.card G).Prime := ⟨hq⟩
  exact zpowers_eq_top_of_prime_card rfl hg

-- The card's toy group: clock p = 20123, group size q = 10061, generator g = 4.
example : Nat.Prime 20123 := by norm_num
example : Nat.Prime 10061 := by norm_num
example : 20123 = 2 * 10061 + 1 := by norm_num
-- g = 4 has prime order 10061; the primitive root 2 does not (2 ^ q lands on p - 1).
example : 4 ^ 10061 % 20123 = 1 := by decide +kernel
example : 2 ^ 10061 % 20123 = 20122 := by decide +kernel
-- The exchange: posts A and B, and the shared key 12254 three ways.
example : 4 ^ 6432 % 20123 = 4781 := by decide +kernel
example : 4 ^ 1602 % 20123 = 14957 := by decide +kernel
example : 14957 ^ 6432 % 20123 = 12254 := by decide +kernel
example : 4781 ^ 1602 % 20123 = 12254 := by decide +kernel
example : 4 ^ (6432 * 1602 % 10061) % 20123 = 12254 := by decide +kernel
-- Cutting the exponent by p instead of q gives the wrong key 1103.
example : 4 ^ (6432 * 1602 % 20123) % 20123 = 1103 := by decide +kernel
-- Baby-step giant-step splits the count as 63 giant steps of 101 plus 69.
example : 6432 = 63 * 101 + 69 := by norm_num
-- ElGamal: public key, PIN placed in the group, ciphertext, and decryption.
example : 4 ^ 1587 % 20123 = 7884 := by decide +kernel
example : 4071 ^ 10061 % 20123 = 20122 := by decide +kernel
example : 20123 - 4071 = 16052 := by norm_num
example : 4 ^ 3778 % 20123 = 14496 := by decide +kernel
example : 7884 ^ 3778 % 20123 = 4073 := by decide +kernel
example : 16052 * 4073 % 20123 = 169 := by norm_num
example : 14496 ^ 1587 % 20123 = 4073 := by decide +kernel
example : 4073 * 15217 % 20123 = 1 := by norm_num
example : 169 * 15217 % 20123 = 16052 := by norm_num
example : 20123 - 16052 = 4071 := by norm_num
-- The same PIN with a fresh r = 1321 encrypts as (4442, 3384).
example : 4 ^ 1321 % 20123 = 4442 := by decide +kernel
example : 16052 * (7884 ^ 1321 % 20123) % 20123 = 3384 := by decide +kernel
-- Reusing r = 3778 for PIN 9306 (placed as 10817): c₂ / c₂' = 13552, and the first PIN reveals the second.
example : 9306 ^ 10061 % 20123 = 20122 := by decide +kernel
example : 20123 - 9306 = 10817 := by norm_num
example : 13552 * (10817 * 4073 % 20123) % 20123 = 169 := by norm_num
example : 10817 * 13552 % 20123 = 16052 := by norm_num
-- A forged post B = 20122 forces laptop 1's key to 1.
example : 20122 ^ 6432 % 20123 = 1 := by decide +kernel
example : 20122 ^ 2 % 20123 = 1 := by norm_num

#print axioms diffie_hellman_keys_agree
#print axioms elgamal_decrypt_correct
#print axioms prime_order_group_every_nonidentity_generates
