-- Euler's theorem: a whole number that shares no factor with the clock size n, raised to the count phi(n) of numbers below n coprime to n, leaves 1 on the n-clock, so exponents can be cut by phi(n), and multiplying the coprime list by that number only reorders it.
import Mathlib.Data.Nat.Totient
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.Data.Nat.ModEq
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.NormNum.Pow

open Nat

/-- Euler's theorem. Take any clock size n and any whole number a that shares no factor above 1
with n. Raise a to phi(n), the count of numbers below n that share no factor with n, and the
n-clock reads 1: a to the phi(n) leaves remainder 1 on division by n. -/
theorem coprime_pow_totient_is_one_on_the_clock (a n : ℕ) (h : Nat.Coprime a n) :
    a ^ φ n ≡ 1 [MOD n] := by
  exact Nat.ModEq.pow_totient (Nat.Coprime.symm h.symm)

/-- Cutting the exponent. For a base a coprime to the clock size n, any exponent e can be cut by
the coprime count phi(n), not by n: a to the e and a to the (remainder of e on division by phi(n))
read the same on the n-clock. -/
theorem exponent_cuts_by_totient (a n e : ℕ) (h : Nat.Coprime a n) :
    a ^ e ≡ a ^ (e % φ n) [MOD n] := by
  have h1 : a ^ φ n ≡ 1 [MOD n] := Nat.ModEq.pow_totient h
  have h2 : (a ^ φ n) ^ (e / φ n) ≡ 1 ^ (e / φ n) [MOD n] := h1.pow _
  have h3 : a ^ e = (a ^ φ n) ^ (e / φ n) * a ^ (e % φ n) := by
    rw [← pow_mul, ← pow_add, Nat.div_add_mod]
  rw [h3]
  have h4 : (a ^ φ n) ^ (e / φ n) * a ^ (e % φ n) ≡ 1 * a ^ (e % φ n) [MOD n] := by
    have := h2
    rw [one_pow] at this
    exact this.mul_right _
  simpa using h4

/-- The shuffle behind the proof. For a base a coprime to the clock size n, multiplying each number
below n that is coprime to n by a, and keeping the remainder on division by n, gives back exactly
the same list of coprime numbers, only reordered. -/
theorem multiplying_the_coprime_list_only_shuffles_it (a n : ℕ) (h : Nat.Coprime a n) :
    Finset.image (fun u => a * u % n) {u ∈ Finset.range n | n.Coprime u} =
      {u ∈ Finset.range n | n.Coprime u} := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have hsub : Finset.image (fun u => a * u % n) {u ∈ Finset.range n | n.Coprime u} ⊆
      {u ∈ Finset.range n | n.Coprime u} := by
    intro x hx
    rw [Finset.mem_image] at hx
    obtain ⟨u, hu, rfl⟩ := hx
    rw [Finset.mem_filter, Finset.mem_range] at hu ⊢
    refine ⟨Nat.mod_lt _ hn, ?_⟩
    have hc : n.Coprime (a * u) := Nat.Coprime.mul_right h.symm hu.2
    have hg : Nat.gcd (a * u % n) n = Nat.gcd (a * u) n := (Nat.mod_modEq (a * u) n).gcd_eq
    unfold Nat.Coprime at hc ⊢
    rw [Nat.gcd_comm, hg, Nat.gcd_comm]
    exact hc
  have hinj : Set.InjOn (fun u => a * u % n) ↑{u ∈ Finset.range n | n.Coprime u} := by
    intro u hu v hv huv
    simp only [Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hu hv
    have h1 : a * u ≡ a * v [MOD n] := huv
    have h2 : u ≡ v [MOD n] := Nat.ModEq.cancel_left_of_coprime (by simpa [Nat.Coprime, Nat.gcd_comm] using h) h1
    unfold Nat.ModEq at h2
    rwa [Nat.mod_eq_of_lt hu.1, Nat.mod_eq_of_lt hv.1] at h2
  exact Finset.eq_of_subset_of_card_le hsub (by rw [Finset.card_image_of_injOn hinj])

-- 3 shares no factor with 100.
example : Nat.gcd 3 100 = 1 := by norm_num
-- The coprime count of 100 is 40, counted one by one.
example : φ 100 = 40 := by decide
-- The count from 100 = 2 × 2 × 5 × 5: half of 100, then four fifths of that.
example : 100 / 2 * (2 - 1) / 5 * (5 - 1) = 40 := by norm_num
-- Euler's promise: 3 to the 40 reads 1 on the 100-clock.
example : 3 ^ 40 % 100 = 1 := by norm_num
-- Multiplying the 40 coprime numbers below 100 by 3 gives back the same 40.
example : Finset.image (fun u => 3 * u % 100) {u ∈ Finset.range 100 | Nat.Coprime 100 u} =
    {u ∈ Finset.range 100 | Nat.Coprime 100 u} := by decide
-- Cut the exponent: 2026 = 50 × 40 + 26.
example : 2026 = 50 * 40 + 26 ∧ 2026 / 40 = 50 ∧ 2026 % 40 = 26 := by norm_num
-- What is left, and the answer: both 29.
example : 3 ^ 26 % 100 = 29 := by norm_num
set_option exponentiation.threshold 2026 in
example : 3 ^ 2026 % 100 = 29 := by norm_num
-- The mistakes: 2 to the 40 reads 76, 10 to the 40 reads 0, 3 to the 99 reads 67, 3 to the 50 reads 49.
example : 2 ^ 40 % 100 = 76 ∧ 10 ^ 40 % 100 = 0 ∧ 3 ^ 99 % 100 = 67 ∧ 3 ^ 50 % 100 = 49 := by
  norm_num
-- The 7-clock: the count is 6, 3 to the 10 reads 4, cut by 6 gives 4, cut by 7 gives 6.
example : φ 7 = 6 ∧ 3 ^ 10 % 7 = 4 ∧ 3 ^ (10 % 6) % 7 = 4 ∧ 3 ^ (10 % 7) % 7 = 6 := by
  decide

#print axioms coprime_pow_totient_is_one_on_the_clock
#print axioms exponent_cuts_by_totient
#print axioms multiplying_the_coprime_list_only_shuffles_it
