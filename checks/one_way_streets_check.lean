-- One-way streets: when a number's powers visit every non-zero slot on a prime clock, the exponent that lands on a slot is unique (and when they do not, two exponents land together), trial division only needs primes up to the square root, and the card's numbers 1,009 × 1,013 = 1,022,117 and 11 to the 613 on a clock of 1,009 landing on 956 check out.
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.Data.Nat.Digits.Defs
import Mathlib.FieldTheory.Finite.Basic

/-- The discrete logarithm is unique. On a clock of a prime size p, suppose the powers of g visit
every non-zero slot. Then for each non-zero slot a there is exactly one exponent k, from 0 up to
p - 2 (one full lap of p - 1 steps), with g raised to k landing on a. -/
theorem discrete_log_unique_when_powers_visit_every_slot (p : ℕ) [Fact p.Prime] (g : ZMod p)
    (hg : ∀ a : ZMod p, a ≠ 0 → ∃ k : ℕ, g ^ k = a) :
    ∀ a : ZMod p, a ≠ 0 → ∃! k : ℕ, k < p - 1 ∧ g ^ k = a := by
  have hp2 : 2 ≤ p := (Fact.out : p.Prime).two_le
  intro a ha
  by_cases hg0 : g = 0
  · subst hg0
    obtain ⟨k, hk⟩ := hg a ha
    have ha1 : a = 1 := by
      rcases Nat.eq_zero_or_pos k with h | h
      · subst h; simpa using hk.symm
      · rw [zero_pow (by omega)] at hk; exact absurd hk.symm ha
    subst ha1
    refine ⟨0, ⟨by omega, by simp⟩, ?_⟩
    rintro k ⟨_, hk⟩
    by_contra hne
    rw [zero_pow hne] at hk
    exact zero_ne_one hk
  · have hfermat : g ^ (p - 1) = 1 := ZMod.pow_card_sub_one_eq_one hg0
    have hred : ∀ m : ℕ, g ^ (m % (p - 1)) = g ^ m := by
      intro m
      conv_rhs => rw [← Nat.mod_add_div m (p - 1), pow_add, pow_mul, hfermat, one_pow, mul_one]
    have hcard : (Finset.univ.erase (0 : ZMod p)).card = p - 1 := by
      rw [Finset.card_erase_of_mem (Finset.mem_univ _), Finset.card_univ, ZMod.card]
    have hinj : ∀ j ∈ Finset.range (p - 1), ∀ k ∈ Finset.range (p - 1),
        g ^ j = g ^ k → j = k := by
      intro j hj k hk h
      exact Finset.inj_on_of_surj_on_of_card_le (s := Finset.range (p - 1))
        (t := Finset.univ.erase (0 : ZMod p)) (fun x _ => g ^ x)
        (fun x _ => by simp [pow_ne_zero x hg0])
        (fun b hb => by
          have hb0 : b ≠ 0 := Finset.ne_of_mem_erase hb
          obtain ⟨m, hm⟩ := hg b hb0
          refine ⟨m % (p - 1), Finset.mem_range.2 (Nat.mod_lt _ (by omega)), ?_⟩
          rw [← hm]
          exact hred m)
        (by rw [hcard, Finset.card_range]) hj hk h
    obtain ⟨m, hm⟩ := hg a ha
    refine ⟨m % (p - 1), ⟨Nat.mod_lt _ (by omega), ?_⟩, ?_⟩
    · rw [← hm]
      exact hred m
    · rintro k ⟨hk, hka⟩
      apply hinj k (Finset.mem_range.2 hk) _ (Finset.mem_range.2 (Nat.mod_lt _ (by omega)))
      rw [hka, ← hm]
      exact (hred m).symm

/-- A short walk is a broken lock. On a clock of a prime size p, if a non-zero g does not visit
every non-zero slot, then two different exponents within one lap, j < k < p - 1, land on the same
slot, so the exponent is no longer unique. -/
theorem exponent_not_unique_when_powers_miss_a_slot (p : ℕ) [Fact p.Prime] (g : ZMod p)
    (hg0 : g ≠ 0) (hmiss : ¬ ∀ a : ZMod p, a ≠ 0 → ∃ k : ℕ, g ^ k = a) :
    ∃ j k : ℕ, j < k ∧ k < p - 1 ∧ g ^ j = g ^ k := by
  have hp2 : 2 ≤ p := (Fact.out : p.Prime).two_le
  push Not at hmiss
  obtain ⟨a, ha0, ha⟩ := hmiss
  have hcard : ((Finset.univ.erase (0 : ZMod p)).erase a).card = p - 2 := by
    rw [Finset.card_erase_of_mem (by simp [ha0]), Finset.card_erase_of_mem (Finset.mem_univ _),
      Finset.card_univ, ZMod.card]
    omega
  have hmaps : ∀ x ∈ Finset.range (p - 1), g ^ x ∈ (Finset.univ.erase (0 : ZMod p)).erase a := by
    intro x _
    simp [pow_ne_zero x hg0, ha x]
  obtain ⟨x, _, y, _, hxy, h⟩ := Finset.exists_ne_map_eq_of_card_lt_of_maps_to
    (s := Finset.range (p - 1)) (t := (Finset.univ.erase (0 : ZMod p)).erase a)
    (by rw [hcard, Finset.card_range]; omega) hmaps (f := fun x => g ^ x)
  simp only [Finset.mem_range] at *
  rcases lt_or_gt_of_ne hxy with h1 | h1
  · exact ⟨x, y, h1, by assumption, h⟩
  · exact ⟨y, x, h1, by assumption, h.symm⟩

/-- Trial division can stop at the square root. A whole number n of at least 2 that is not prime
has a prime factor q with q × q at most n. -/
theorem composite_has_prime_factor_at_most_sqrt (n : ℕ) (hn : 2 ≤ n) (hnp : ¬ n.Prime) :
    ∃ q : ℕ, q.Prime ∧ q ∣ n ∧ q * q ≤ n := by
  refine ⟨n.minFac, Nat.minFac_prime (by omega), Nat.minFac_dvd n, ?_⟩
  have := Nat.minFac_sq_le_self (by omega) hnp
  nlinarith

-- The way out: 1,009 × 1,013 = 1,022,117, both prime.
example : 1009 * 1013 = 1022117 := by norm_num
example : Nat.Prime 1009 ∧ Nat.Prime 1013 := by norm_num
-- Four digits by four digits: 4 × 4 = 16 little multiplications.
example : (Nat.digits 10 1009).length * (Nat.digits 10 1013).length = 16 := by norm_num
-- The square root of 1,022,117 is a shade over 1,010.
example : 1010 * 1010 ≤ 1022117 ∧ 1022117 < 1011 * 1011 := by norm_num
-- The way back: nothing from 2 to 1,008 divides 1,022,117, and 1,009 is the first that does.
set_option maxRecDepth 100000 in
example : ∀ q ∈ Finset.Icc 2 1008, ¬ q ∣ 1022117 := by decide
example : Nat.minFac 1022117 = 1009 ∧ 1022117 / 1009 = 1013 := by norm_num
-- 1,009 is the 169th prime: 168 primes come before it, and every one fails.
set_option maxRecDepth 100000 in
example : (Nat.primesBelow 1009).card = 168 := by decide +kernel
-- Mistake: trial dividing only up to 100 finds no factor.
example : ∀ q ∈ Finset.Icc 2 100, ¬ q ∣ 1022117 := by decide
-- The clock: 11 to the 613 on a clock of 1,009 lands on 956.
example : (11 : ZMod 1009) ^ 613 = 956 := by decide
-- The fast way up: 613 is 1001100101 in binary, 10 squarings and 5 multiplies, 15 in all.
example : Nat.digits 2 613 = [1, 0, 1, 0, 0, 1, 1, 0, 0, 1] ∧
    (Nat.digits 2 613).length + (Nat.digits 2 613).sum = 15 := by norm_num
-- Walking back: no exponent below 613 lands on 956.
set_option maxRecDepth 100000 in
example : ∀ k ∈ Finset.range 613, (11 : ZMod 1009) ^ k ≠ 956 := by decide
-- 11 visits all 1,008 non-zero slots: no power from 1 to 1,007 comes back to 1.
set_option maxRecDepth 100000 in
example : ∀ k ∈ Finset.Icc 1 1007, (11 : ZMod 1009) ^ k ≠ 1 := by decide
-- Mistake: dividing 956 by 11 on the clock (times 367, the inverse of 11) gives 729.
example : (11 : ZMod 1009) * 367 = 1 ∧ (956 : ZMod 1009) * 367 = 729 := by decide
-- Try changing: the secret 614 lands on 426.
example : (11 : ZMod 1009) ^ 614 = 426 := by decide
-- Try changing: on a clock of 1,013, 11 to the 613 lands on 969, already reached at step 15,
-- because 11's powers there come back to 1 after 46 steps.
example : (11 : ZMod 1013) ^ 613 = 969 ∧ (11 : ZMod 1013) ^ 15 = 969 := by decide
example : ∀ k ∈ Finset.range 15, (11 : ZMod 1013) ^ k ≠ 969 := by decide
example : (11 : ZMod 1013) ^ 46 = 1 ∧ ∀ k ∈ Finset.Icc 1 45, (11 : ZMod 1013) ^ k ≠ 1 := by decide

#print axioms discrete_log_unique_when_powers_visit_every_slot
#print axioms exponent_not_unique_when_powers_miss_a_slot
#print axioms composite_has_prime_factor_at_most_sqrt
