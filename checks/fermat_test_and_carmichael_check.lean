-- The Fermat test: a base sharing no factor with n that, raised to n - 1 on the n clock, lands anywhere but 1 proves n composite, while landing on 1 proves nothing, as 341 and 561 show.
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Finset.Card
import Mathlib.Tactic.NormNum.Prime
import Mathlib.FieldTheory.Finite.Basic

/-- A fail proves the number composite. Take a number `n` and a base `a` sharing no factor
with it. Raise the base to one less than the number, on the `n` clock. If it lands anywhere
but 1, then `n` is not prime, and no factor of `n` has been named. -/
theorem fermat_test_fail_proves_composite (n a : ℕ) (ha : Nat.Coprime a n)
    (hfail : ¬ a ^ (n - 1) ≡ 1 [MOD n]) : ¬ n.Prime := by
  intro hp
  apply hfail
  have h := Nat.ModEq.pow_totient ha
  rwa [Nat.totient_prime hp] at h

/-- The test runs one way only. Landing on 1 does not prove a number prime, even with a base
other than 1 that shares no factor with it: base 2 on 341 lands on 1, yet 341 = 11 × 31. -/
theorem fermat_test_pass_does_not_prove_prime :
    ¬ ∀ n a : ℕ, a ≠ 1 → Nat.Coprime a n → a ^ (n - 1) ≡ 1 [MOD n] → n.Prime := by
  intro h
  have h341 := h 341 2 (by norm_num) (by decide +kernel) (by unfold Nat.ModEq; decide +kernel)
  norm_num at h341

/-- 561 fools the test every time. It is not prime, yet every base sharing no factor with
it, raised to 560 on the 561 clock, lands on 1. -/
theorem fermat_test_fooled_by_every_coprime_base_of_561 :
    ¬ Nat.Prime 561 ∧ ∀ a : ℕ, Nat.Coprime a 561 → a ^ 560 ≡ 1 [MOD 561] := by
  refine ⟨by norm_num, fun a ha => ?_⟩
  have key : ∀ b : ℕ, b < 561 → Nat.Coprime b 561 → b ^ 560 % 561 = 1 := by decide +kernel
  have hb : Nat.Coprime (a % 561) 561 := by
    rwa [ZMod.coprime_mod_iff_coprime]
  have := key (a % 561) (Nat.mod_lt _ (by norm_num)) hb
  unfold Nat.ModEq
  rw [Nat.pow_mod, this]

-- 341 = 11 × 31 and 561 = 3 × 11 × 17, both composite.
example : 11 * 31 = 341 ∧ 3 * 11 * 17 = 561 := by decide
example : ¬ Nat.Prime 341 ∧ ¬ Nat.Prime 561 := by norm_num
-- Base 2 on 341: 2 to the 10 is 1024 = 3 × 341 + 1, and 2 to the 340 lands on 1.
example : 2 ^ 10 = 1024 ∧ 1024 = 3 * 341 + 1 ∧ 340 = 34 * 10 := by decide
example : 2 ^ 340 % 341 = 1 := by decide +kernel
-- Base 3 on 341 lands on 56: 1 on the 11 clock, 25 on the 31 clock, glued back to 56.
example : 3 ^ 340 % 341 = 56 := by decide +kernel
example : 3 ^ 340 % 11 = 1 ∧ 3 ^ 340 % 31 = 25 := by decide +kernel
example : 3 ^ 10 = 59049 ∧ 59049 = 31 * 1904 + 25 ∧ 340 = 11 * 30 + 10 := by decide
example : 56 % 11 = 1 ∧ 56 % 31 = 25 := by decide
-- Base 1 passes 341; the exponent 341 instead of 340 lands on 2.
example : 1 ^ 340 % 341 = 1 ∧ 2 ^ 341 % 341 = 2 := by decide +kernel
-- 300 bases below 341 share no factor with it, and 100 of them land on 1.
example : ((Finset.range 341).filter (fun a => Nat.Coprime a 341)).card = 300 := by decide +kernel
example : ((Finset.range 341).filter
    (fun a => Nat.Coprime a 341 ∧ a ^ 340 % 341 = 1)).card = 100 := by decide +kernel
-- 320 bases below 561 share no factor with it, and all 320 land on 1; 320 = 2 × 10 × 16.
example : ((Finset.range 561).filter (fun a => Nat.Coprime a 561)).card = 320 := by decide +kernel
example : ((Finset.range 561).filter
    (fun a => Nat.Coprime a 561 ∧ a ^ 560 % 561 = 1)).card = 320 := by decide +kernel
example : 560 % 2 = 0 ∧ 560 % 10 = 0 ∧ 560 % 16 = 0 ∧ 2 * 10 * 16 = 320 := by decide
-- 1105 and 1729 do it too: all 768 and all 1296 of their coprime bases land on 1.
example : ((Finset.range 1105).filter (fun a => Nat.Coprime a 1105)).card = 768 := by decide +kernel
example : ((Finset.range 1105).filter
    (fun a => Nat.Coprime a 1105 ∧ a ^ 1104 % 1105 = 1)).card = 768 := by decide +kernel
example : ((Finset.range 1729).filter (fun a => Nat.Coprime a 1729)).card = 1296 := by decide +kernel
example : ((Finset.range 1729).filter
    (fun a => Nat.Coprime a 1729 ∧ a ^ 1728 % 1729 = 1)).card = 1296 := by decide +kernel

#print axioms fermat_test_fail_proves_composite
#print axioms fermat_test_pass_does_not_prove_prime
#print axioms fermat_test_fooled_by_every_coprime_base_of_561
