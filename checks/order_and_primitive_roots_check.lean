-- The order of a number and primitive roots: for a number sharing no factor above 1 with the clock size n, its powers return to 1 exactly at the multiples of its order, that order divides phi(n), an order equal to phi(n) makes the powers reach every remainder sharing no factor with n, and a shared factor stops the powers from ever reaching 1.
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Data.Nat.Totient

theorem sonnet_pow_modEq_one_iff (a n k : ℕ) : a ^ k ≡ 1 [MOD n] ↔ (a : ZMod n) ^ k = 1 := by
  rw [← ZMod.natCast_eq_natCast_iff]; push_cast; rfl

#print axioms sonnet_pow_modEq_one_iff

theorem sonnet_order_pos_dvd (a n : ℕ) (h : Nat.Coprime a n) :
    0 < orderOf (a : ZMod n) ∧ ∀ k : ℕ, ((a : ZMod n) ^ k = 1 ↔ orderOf (a : ZMod n) ∣ k) := by
  refine ⟨?_, fun k => orderOf_dvd_iff_pow_eq_one.symm⟩
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · have : a = 1 := by simpa using h
    subst this
    simp
  · have : NeZero n := ⟨hn.ne'⟩
    rw [← ZMod.coe_unitOfCoprime a h, orderOf_units]
    exact orderOf_pos _

#print axioms sonnet_order_pos_dvd

/-- The card's main claim. Take a clock of size n and a number a sharing no factor above 1 with
n. The order of a on the n-clock (the fewest multiplications by a that bring the remainder back
to 1) divides phi(n), the count of remainders from 1 to n sharing no factor above 1 with n. And
if the order equals phi(n), a is a primitive root: every remainder b sharing no factor above 1
with n is reached by some power of a. -/
theorem order_divides_totient_and_full_order_is_primitive_root (a n : ℕ) (h : Nat.Coprime a n) :
    orderOf (a : ZMod n) ∣ Nat.totient n ∧
      (orderOf (a : ZMod n) = Nat.totient n →
        ∀ b : ℕ, Nat.Coprime b n → ∃ k : ℕ, a ^ k ≡ b [MOD n]) := by
  have hdvd : orderOf (a : ZMod n) ∣ Nat.totient n := by
    rcases Nat.eq_zero_or_pos n with rfl | hn
    · have : a = 1 := by simpa using h
      subst this
      simp
    · have : NeZero n := ⟨hn.ne'⟩
      rw [← ZMod.card_units_eq_totient, ← ZMod.coe_unitOfCoprime a h, orderOf_units]
      exact orderOf_dvd_card
  refine ⟨hdvd, fun hord b hb => ?_⟩
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · have ha : a = 1 := by simpa using h
    have hb' : b = 1 := by simpa using hb
    subst ha; subst hb'
    exact ⟨0, rfl⟩
  · have : NeZero n := ⟨hn.ne'⟩
    set u := ZMod.unitOfCoprime a h with hu
    have hcard : Nat.card (Subgroup.zpowers u) = Nat.card (ZMod n)ˣ := by
      rw [Nat.card_zpowers, Nat.card_eq_fintype_card, ZMod.card_units_eq_totient,
        ← hord, ← ZMod.coe_unitOfCoprime a h, orderOf_units]
    have htop : Subgroup.zpowers u = ⊤ := Subgroup.eq_top_of_card_eq _ hcard
    have hmem : ZMod.unitOfCoprime b hb ∈ Subgroup.zpowers u := by rw [htop]; trivial
    rw [← mem_powers_iff_mem_zpowers] at hmem
    obtain ⟨k, hk⟩ := hmem
    refine ⟨k, ?_⟩
    rw [← ZMod.natCast_eq_natCast_iff]
    have := congrArg (fun x : (ZMod n)ˣ => (x : ZMod n)) hk
    simpa [hu, ZMod.coe_unitOfCoprime] using this

/-- Steps 0 and 1. When a and the clock size n share no factor above 1, the powers of a do come
back to 1, so the order is at least 1, and a run of k multiplications lands on 1 exactly when
the order divides k. -/
theorem powers_return_to_one_exactly_at_multiples_of_order (a n : ℕ) (h : Nat.Coprime a n) :
    0 < orderOf (a : ZMod n) ∧ ∀ k : ℕ, (a ^ k ≡ 1 [MOD n] ↔ orderOf (a : ZMod n) ∣ k) := by
  refine ⟨(sonnet_order_pos_dvd a n h).1, fun k => ?_⟩
  rw [sonnet_pow_modEq_one_iff]
  exact (sonnet_order_pos_dvd a n h).2 k

/-- Why the hypothesis matters. If a and the clock size n share a factor above 1, no run of one
or more multiplications by a ever lands on 1, as with 10 on the 14-clock. -/
theorem shared_factor_never_reaches_one (a n : ℕ) (h : ¬ Nat.Coprime a n) :
    ∀ k : ℕ, 0 < k → ¬ a ^ k ≡ 1 [MOD n] := by
  intro k hk hmod
  apply h
  rw [sonnet_pow_modEq_one_iff] at hmod
  have hu : IsUnit (a : ZMod n) := by
    refine IsUnit.of_mul_eq_one ((a : ZMod n) ^ (k - 1)) ?_
    rw [← pow_succ']
    rwa [Nat.sub_add_cancel hk]
  exact (ZMod.isUnit_iff_coprime a n).mp hu

-- The 7-clock: the powers of 10 run 3, 2, 6, 4, 5, 1.
example : (List.range 6).map (fun k => 10 ^ (k + 1) % 7) = [3, 2, 6, 4, 5, 1] := by decide
-- Six multiplications to reach 1, and no fewer: the order of 10 on the 7-clock is 6.
example : 10 ^ 6 % 7 = 1 ∧ ∀ k ∈ Finset.Ioo 0 6, 10 ^ k % 7 ≠ 1 := by decide
-- The 13-clock: 10, 9, 12, 3, 4, 1, also six steps home.
example : (List.range 6).map (fun k => 10 ^ (k + 1) % 13) = [10, 9, 12, 3, 4, 1] := by decide
example : 10 ^ 6 % 13 = 1 ∧ ∀ k ∈ Finset.Ioo 0 6, 10 ^ k % 13 ≠ 1 := by decide
-- phi(7) = 6, phi(13) = 12, phi(14) = 6.
example : Nat.totient 7 = 6 ∧ Nat.totient 13 = 12 ∧ Nat.totient 14 = 6 := by decide
-- The order divides phi(n): 6 divides 6 and 6 divides 12.
example : 6 ∣ 6 ∧ 6 ∣ 12 := by decide
-- On the 7-clock the powers of 10 reach all six remainders 1 to 6: a primitive root.
example : ∀ b ∈ [1, 2, 3, 4, 5, 6], b ∈ (List.range 6).map (fun k => 10 ^ (k + 1) % 7) := by
  decide
-- On the 13-clock they reach only six of the twelve: 9 and 10 yes, 2 no.
example : ((List.range 12).map (fun k => 10 ^ (k + 1) % 13)).dedup.length = 6 ∧
    2 ∉ (List.range 12).map (fun k => 10 ^ (k + 1) % 13) := by decide
-- The 7-clock has two primitive roots, 3 and 5; 10 is 3 in disguise.
example : (List.range 7).filter (fun a => decide (∀ b ∈ [1, 2, 3, 4, 5, 6],
    b ∈ (List.range 6).map (fun k => a ^ (k + 1) % 7))) = [3, 5] ∧ 10 % 7 = 3 := by decide
-- A shorter order misses remainders: 2 on the 7-clock goes 2, 4, 1, order 3, not 6.
example : (List.range 3).map (fun k => 2 ^ (k + 1) % 7) = [2, 4, 1] ∧
    ∀ k ∈ Finset.Ioo 0 3, 2 ^ k % 7 ≠ 1 := by decide
-- 10 on the 14-clock runs 10, 2, 6, 4, 12, 8 and never touches 1; 10 and 14 are both even.
example : (List.range 6).map (fun k => 10 ^ (k + 1) % 14) = [10, 2, 6, 4, 12, 8] ∧
    Nat.gcd 10 14 = 2 := by decide
-- The repeating decimals: 1/7 = 0.142857..., 1/13 = 0.076923..., both six digits,
-- because 10^6 - 1 = 999999 is 7 × 142857 and 13 × 076923.
example : 10 ^ 6 - 1 = 999999 ∧ 7 * 142857 = 999999 ∧ 13 * 76923 = 999999 := by decide
-- Try changing: more powers bring nothing new; the six repeat.
example : (List.range 12).map (fun k => 10 ^ (k + 1) % 7) =
    [3, 2, 6, 4, 5, 1, 3, 2, 6, 4, 5, 1] := by decide
-- Try changing: on the 3-clock the order of 10 is 1, and 1/3 repeats one digit.
example : 10 % 3 = 1 ∧ 3 * 3 = 9 := by decide

#print axioms order_divides_totient_and_full_order_is_primitive_root
#print axioms powers_return_to_one_exactly_at_multiples_of_order
#print axioms shared_factor_never_reaches_one
