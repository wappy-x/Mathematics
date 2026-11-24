-- Every prime clock has a primitive root: on the p-clock, exactly phi(d) nonzero numbers have order d for each d dividing p - 1, so phi(p - 1) of them, never zero, are primitive roots, and a power test picks them out.
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.GroupTheory.SpecificGroups.Cyclic
import Mathlib.Data.Nat.Totient

open Finset

/-- The card's main claim: on a prime clock `p`, for each `d` dividing `p - 1`, exactly
`phi(d)` numbers on the clock have order `d`. -/
theorem card_order_eq_totient_mod_prime (p : ℕ) [Fact p.Prime] {d : ℕ} (hd : d ∣ p - 1) :
    (univ.filter fun a : ZMod p => orderOf a = d).card = Nat.totient d := by
  classical
  have hp := (Fact.out : p.Prime)
  have hd0 : d ≠ 0 := by
    rintro rfl
    have := Nat.eq_zero_of_zero_dvd hd
    have := hp.two_le
    omega
  have hunits : (univ.filter fun u : (ZMod p)ˣ => orderOf u = d).card = Nat.totient d := by
    apply IsCyclic.card_orderOf_eq_totient
    rw [ZMod.card_units p]
    exact hd
  rw [← hunits]
  have himg : (univ.filter fun a : ZMod p => orderOf a = d) =
      (univ.filter fun u : (ZMod p)ˣ => orderOf u = d).image Units.val := by
    ext a
    simp only [mem_filter, mem_univ, true_and, mem_image]
    constructor
    · intro h
      have ha : a ≠ 0 := by
        rintro rfl
        have h0 : orderOf (0 : ZMod p) = 0 := by
          rw [orderOf_eq_zero_iff']
          intro n hn h0
          rw [zero_pow hn.ne'] at h0
          exact zero_ne_one h0
        exact hd0 (h.symm.trans h0)
      exact ⟨Units.mk0 a ha, by rw [← orderOf_units]; simpa using h, by simp⟩
    · rintro ⟨u, hu, rfl⟩
      rw [orderOf_units]
      exact hu
  rw [himg, card_image_of_injective _ Units.val_injective]

/-- The primitive roots, the numbers of order `p - 1`, number exactly `phi(p - 1)`,
and that count is never zero: every prime clock has a primitive root. -/
theorem card_primitive_roots_eq_totient (p : ℕ) [Fact p.Prime] :
    (univ.filter fun a : ZMod p => orderOf a = p - 1).card = Nat.totient (p - 1) ∧
      0 < (univ.filter fun a : ZMod p => orderOf a = p - 1).card := by
  have hp := (Fact.out : p.Prime)
  have h := card_order_eq_totient_mod_prime p (dvd_refl (p - 1))
  refine ⟨h, ?_⟩
  rw [h]
  apply Nat.totient_pos.mpr
  have := hp.two_le
  omega

/-- Step 4, the power test: a nonzero number `a` on a prime clock is a primitive root
exactly when `a ^ ((p - 1) / q)` is not 1 for every prime `q` dividing `p - 1`. -/
theorem primitive_root_iff_power_test (p : ℕ) [Fact p.Prime] {a : ZMod p} (ha : a ≠ 0) :
    orderOf a = p - 1 ↔ ∀ q : ℕ, q.Prime → q ∣ p - 1 → a ^ ((p - 1) / q) ≠ 1 := by
  have hp := (Fact.out : p.Prime)
  have hp2 := hp.two_le
  constructor
  · intro h q hq hqd hpow
    have hpos : 0 < (p - 1) / q := Nat.div_pos (Nat.le_of_dvd (by omega) hqd) hq.pos
    have hle := orderOf_le_of_pow_eq_one hpos hpow
    rw [h] at hle
    have := Nat.div_lt_self (show 0 < p - 1 by omega) hq.one_lt
    omega
  · intro h
    set u := Units.mk0 a ha with hu
    have hua : (u : ZMod p) = a := rfl
    rw [← hua, orderOf_units]
    apply orderOf_eq_of_pow_and_pow_div_prime (by omega)
    · ext
      rw [Units.val_pow_eq_pow_val, hua, Units.val_one]
      exact ZMod.pow_card_sub_one_eq_one ha
    · intro q hq hqd hpow
      apply h q hq hqd
      rw [← hua, ← Units.val_pow_eq_pow_val, hpow, Units.val_one]

-- On the 13-clock the powers of 2 visit all twelve nonzero numbers; the powers of 3 loop 3, 9, 1.
example : (List.range' 1 12).map (fun k => (2 : ZMod 13) ^ k) =
    [2, 4, 8, 3, 6, 12, 11, 9, 5, 10, 7, 1] := by decide
example : (List.range' 1 3).map (fun k => (3 : ZMod 13) ^ k) = [3, 9, 1] := by decide
-- The orders of 2 and 3 on the 13-clock are 12 and 3.
example : orderOf (2 : ZMod 13) = 12 := by rw [orderOf_eq_iff (by norm_num)]; decide
example : orderOf (3 : ZMod 13) = 3 := by rw [orderOf_eq_iff (by norm_num)]; decide
-- The piles: numbers of order d (d-th power 1, no earlier power 1) for d = 1, 2, 3, 4, 6, 12.
example : [1, 2, 3, 4, 6, 12].map (fun d =>
    (univ.filter fun a : ZMod 13 => a ^ d = 1 ∧ ∀ m < d, 0 < m → a ^ m ≠ 1).card) =
    [1, 1, 2, 2, 2, 4] := by decide
-- phi(d) for the divisors of 12 is 1, 1, 2, 2, 2, 4, and these add up to 12.
example : Nat.divisors 12 = {1, 2, 3, 4, 6, 12} := by decide
example : [1, 2, 3, 4, 6, 12].map Nat.totient = [1, 1, 2, 2, 2, 4] := by decide
example : ∑ d ∈ Nat.divisors 12, Nat.totient d = 12 := by decide
-- The primitive roots of 13 are 2, 6, 7 and 11.
example : (univ.filter fun a : ZMod 13 => a ^ 12 = 1 ∧ ∀ m < 12, 0 < m → a ^ m ≠ 1) =
    {2, 6, 7, 11} := by decide
-- Step 4 on the 13-clock: 2^6 = 12 and 2^4 = 3, so 2 passes; 5 has 5^4 = 1, so it fails.
example : (2 : ZMod 13) ^ 6 = 12 ∧ (2 : ZMod 13) ^ 4 = 3 ∧ (5 : ZMod 13) ^ 4 = 1 := by decide
-- The full power test finds 2, 6, 7, 11; testing only the 6th power passes 6 numbers.
example : (univ.filter fun a : ZMod 13 => a ≠ 0 ∧ a ^ 6 ≠ 1 ∧ a ^ 4 ≠ 1) = {2, 6, 7, 11} := by
  decide
example : (univ.filter fun a : ZMod 13 => a ≠ 0 ∧ a ^ 6 ≠ 1).card = 6 := by decide
-- The 15-clock is not prime: x^2 - 1 has 4 roots, phi(15) = 8, phi(8) = 4, yet no number has order 8.
example : (univ.filter fun x : ZMod 15 => x ^ 2 = 1).card = 4 := by decide
example : Nat.totient 15 = 8 ∧ Nat.totient 8 = 4 := by decide
example : (univ.filter fun a : ZMod 15 => a ^ 8 = 1 ∧ ∀ m < 8, 0 < m → a ^ m ≠ 1).card = 0 := by
  decide

#print axioms card_order_eq_totient_mod_prime
#print axioms card_primitive_roots_eq_totient
#print axioms primitive_root_iff_power_test
