-- Quantum advantage: under the mix noise model the expected cross-entropy score is the fidelity times a perfect device's score, a base built from two known odd primes has period 2 and its gcds return the primes, and every base of 15 other than 1 has period 2 or 4.
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Int.GCD
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.NormNum.PowMod
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.IntervalCases

open Finset

namespace QuantumAdvantage

/-- A prime that divides both `a - 1` and `a + 1` divides 2, so it is 2. -/
theorem prime_dvd_sub_one_and_add_one_eq_two (p : ℕ) (hp : p.Prime) (a : ℤ)
    (h1 : (p : ℤ) ∣ a - 1) (h2 : (p : ℤ) ∣ a + 1) : p = 2 := by
  have h : (p : ℤ) ∣ 2 := by
    have := dvd_sub h2 h1
    rwa [show a + 1 - (a - 1) = 2 by ring] at this
  have h' : p ∣ 2 := by exact_mod_cast h
  exact (Nat.prime_dvd_prime_iff_eq hp Nat.prime_two).mp h'

/-- Every unit of `ZMod 15` has fourth power 1. -/
theorem unit_pow_four_mod_fifteen (a : ZMod 15) (ha : IsUnit a) : a ^ 4 = 1 := by
  obtain ⟨u, rfl⟩ := ha
  have hc := ZMod.val_coe_unit_coprime u
  generalize (u : ZMod 15) = b at hc ⊢
  revert b
  decide


/-- The test-score identity (linear cross-entropy benchmark, XEB). Let `p x` be the ideal chance
of the `n`-bit string `x`. In the mix noise model a device returns an ideal sample with chance `f`
and a uniform random string otherwise, so it lands on `x` with chance
`q x = f p(x) + (1 − f) 2^(−n)`. Then the expected score `2^n ∑ₓ q(x) p(x) − 1` equals `f` times a
perfect device's score `2^n ∑ₓ p(x)² − 1`. -/
theorem xeb_expected_score_eq_fidelity_mul_perfect_score (n : ℕ) (p : (Fin n → Bool) → ℝ)
    (hp : ∀ x, 0 ≤ p x) (hsum : ∑ x, p x = 1) (f : ℝ) (hf0 : 0 ≤ f) (hf1 : f ≤ 1) :
    (2 : ℝ) ^ n * ∑ x, (f * p x + (1 - f) * ((2 : ℝ) ^ n)⁻¹) * p x - 1
      = f * ((2 : ℝ) ^ n * ∑ x, p x ^ 2 - 1) := by
  have h2 : (2 : ℝ) ^ n ≠ 0 := by positivity
  have hs : ∑ x, (f * p x + (1 - f) * ((2 : ℝ) ^ n)⁻¹) * p x
      = f * ∑ x, p x ^ 2 + (1 - f) * ((2 : ℝ) ^ n)⁻¹ * ∑ x, p x := by
    rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl (fun x _ => by ring)
  rw [hs, hsum]
  field_simp
  ring

/-- The compiled-factoring trick (Smolin, Smith and Vargo, 2013). Take two different odd primes
`s` and `t` and a base `a` with `a ≡ 1 (mod s)` and `a ≡ −1 (mod t)`. Then `a² ≡ 1 (mod s t)`, the
period of `a` modulo `s t` is exactly 2, `gcd(a − 1, s t) = s` and `gcd(a + 1, s t) = t`: the base
was built from the answer, and the gcds hand the primes back. -/
theorem compiled_base_has_period_two_and_gcds_return_primes (s t : ℕ) (hs : s.Prime)
    (ht : t.Prime) (hs2 : s ≠ 2) (ht2 : t ≠ 2) (hst : s ≠ t) (a : ℤ)
    (has : a ≡ 1 [ZMOD s]) (hat : a ≡ -1 [ZMOD t]) :
    a ^ 2 ≡ 1 [ZMOD (s * t : ℕ)] ∧ orderOf (a : ZMod (s * t)) = 2 ∧
      Int.gcd (a - 1) (s * t : ℕ) = s ∧ Int.gcd (a + 1) (s * t : ℕ) = t := by
  have hsd : (s : ℤ) ∣ a - 1 := (Int.ModEq.dvd has.symm)
  have htd : (t : ℤ) ∣ a + 1 := by
    have := Int.ModEq.dvd hat.symm
    rwa [sub_neg_eq_add] at this
  have hcop : s.Coprime t := (Nat.coprime_primes hs ht).mpr hst
  have hsq : a ^ 2 ≡ 1 [ZMOD (s * t : ℕ)] := by
    rw [Nat.cast_mul, ← Int.modEq_and_modEq_iff_modEq_mul (by simpa using hcop)]
    constructor
    · simpa using has.pow 2
    · simpa using hat.pow 2
  have hnt : ¬ (t : ℤ) ∣ a - 1 := fun h => ht2 (prime_dvd_sub_one_and_add_one_eq_two t ht a h htd)
  have hns : ¬ (s : ℤ) ∣ a + 1 := fun h => hs2 (prime_dvd_sub_one_and_add_one_eq_two s hs a hsd h)
  refine ⟨hsq, ?_, ?_, ?_⟩
  · have : Fact (Nat.Prime 2) := ⟨Nat.prime_two⟩
    apply orderOf_eq_prime
    · have := (ZMod.intCast_eq_intCast_iff (a ^ 2) 1 (s * t)).mpr hsq
      push_cast at this
      exact this
    · intro h
      have h' : ((a : ℤ) : ZMod (s * t)) = ((1 : ℤ) : ZMod (s * t)) := by simpa using h
      rw [ZMod.intCast_eq_intCast_iff] at h'
      have h3 : (t : ℤ) ∣ a - 1 := by
        have := Int.ModEq.dvd h'.symm
        have hd : ((t : ℕ) : ℤ) ∣ ((s * t : ℕ) : ℤ) := by
          exact_mod_cast Nat.dvd_mul_left t s
        exact hd.trans this
      exact hnt h3
  · rw [Int.gcd_eq_natAbs, Int.natAbs_natCast, Nat.Coprime.gcd_mul _ hcop]
    have e1 : Nat.gcd (a - 1).natAbs s = s := Nat.gcd_eq_right (Int.natCast_dvd.mp hsd)
    have e2 : Nat.gcd (a - 1).natAbs t = 1 := by
      apply Nat.Coprime.symm
      rw [Nat.Prime.coprime_iff_not_dvd ht]
      intro h
      exact hnt (Int.natCast_dvd.mpr h)
    rw [e1, e2, mul_one]
  · rw [Int.gcd_eq_natAbs, Int.natAbs_natCast, Nat.Coprime.gcd_mul _ hcop]
    have e1 : Nat.gcd (a + 1).natAbs t = t := Nat.gcd_eq_right (Int.natCast_dvd.mp htd)
    have e2 : Nat.gcd (a + 1).natAbs s = 1 := by
      apply Nat.Coprime.symm
      rw [Nat.Prime.coprime_iff_not_dvd hs]
      intro h
      exact hns (Int.natCast_dvd.mpr h)
    rw [e1, e2, one_mul]

/-- What a hardware run on 15 really needs: every base `a` of 15 (a unit modulo 15) other than 1
has period 2 or 4, so `a^x mod 15` depends only on `x mod 4`, the last 2 bits of `x`. -/
theorem every_base_of_fifteen_has_period_two_or_four (a : ZMod 15) (ha : IsUnit a)
    (h1 : a ≠ 1) :
    (orderOf a = 2 ∨ orderOf a = 4) ∧ ∀ x : ℕ, a ^ x = a ^ (x % 4) := by
  have h4 : a ^ 4 = 1 := unit_pow_four_mod_fifteen a ha
  refine ⟨?_, ?_⟩
  · have hd : orderOf a ∣ 2 ^ 2 := orderOf_dvd_of_pow_eq_one h4
    obtain ⟨k, hk, hk'⟩ := (Nat.dvd_prime_pow Nat.prime_two).mp hd
    interval_cases k
    · exact absurd (orderOf_eq_one_iff.mp (by simpa using hk')) h1
    · left; simpa using hk'
    · right; simpa using hk'
  · intro x
    conv_lhs => rw [← Nat.div_add_mod x 4, pow_add, pow_mul, h4, one_pow, one_mul]

end QuantumAdvantage

/-- The usable bases of 15: seven numbers from 2 to 14 share no factor with 15. -/
example : ((Finset.range 15).filter fun a => 2 ≤ a ∧ Nat.gcd a 15 = 1) = {2, 4, 7, 8, 11, 13, 14} := by
  decide

/-- Base 11 on 15: `11² = 121 = 8 × 15 + 1`, period 2, and the gcds are 5 and 3. -/
example : 11 ^ 2 % 15 = 1 ∧ 11 % 15 ≠ 1 ∧ Nat.gcd 10 15 = 5 ∧ Nat.gcd 12 15 = 3 := by decide

/-- Base 7 on 15: period 4; the halfway power `7² mod 15 = 4` gives gcds 3 and 5. -/
example : 7 ^ 4 % 15 = 1 ∧ 7 ^ 2 % 15 = 4 ∧ Nat.gcd 3 15 = 3 ∧ Nat.gcd 5 15 = 5 := by decide

/-- What breaks: base 14 has period 2, but its halfway power is `14 = 15 − 1`, so the gcds are the
trivial factors 1 and 15. -/
example : 14 ^ 2 % 15 = 1 ∧ Nat.gcd 13 15 = 1 ∧ Nat.gcd 15 15 = 15 := by decide

/-- The textbook circuit for 15: 8 counting qubits, since `2^7 < 15² ≤ 2^8`, plus 4 work qubits. -/
example : 2 ^ 7 < 15 ^ 2 ∧ 15 ^ 2 ≤ 2 ^ 8 ∧ 8 + 4 = 12 := by norm_num

set_option maxRecDepth 100000 in
/-- The coin-flip "factoring" of a 19-digit number: `s = 2,147,483,647` and `t = 4,294,967,291`
are prime, `N = s t = 9,223,372,021,822,390,277`, the base `a = 6,148,914,678,351,615,323` is
1 more than a multiple of `s` and 1 less than a multiple of `t`, `a² mod N = 1`, and the gcds
return `s` and `t`. The primality checks are trial division, deep enough to need a higher
recursion limit. -/
example :
    Nat.Prime 2147483647 ∧ Nat.Prime 4294967291 ∧
    2147483647 * 4294967291 = 9223372021822390277 ∧
    6148914678351615323 % 2147483647 = 1 ∧ (6148914678351615323 + 1) % 4294967291 = 0 ∧
    6148914678351615323 ^ 2 % 9223372021822390277 = 1 ∧
    Nat.gcd (6148914678351615323 - 1) 9223372021822390277 = 2147483647 ∧
    Nat.gcd (6148914678351615323 + 1) 9223372021822390277 = 4294967291 := by
  norm_num

/-- The 2019 claim against the chip: 10,000 years of 365.25 days against 200 seconds is a ratio
of 1,577,880,000; the 2022 run of 15 hours is 270 times the chip. -/
example : (10000 : ℚ) * (36525 / 100) * 86400 / 200 = 1577880000 ∧
    (15 * 3600 : ℚ) / 200 = 270 := by
  norm_num

/-- Storing 53 qubits: `2^53 = 9,007,199,254,740,992` amplitudes, at 8 bytes each
72,057,594,037,927,936 bytes; at 65 qubits, 295,147,905,179,352,825,856 bytes. -/
example : 2 ^ 53 = 9007199254740992 ∧ 8 * 2 ^ 53 = 72057594037927936 ∧
    8 * 2 ^ 65 = 295147905179352825856 := by
  norm_num

/-- Samples needed to see `f = 0.002` at 5 standard errors: `(5 / 0.002)² = 6,250,000`. -/
example : ((5 : ℚ) / (2 / 1000)) ^ 2 = 6250000 := by norm_num

namespace QuantumAdvantage

#print axioms prime_dvd_sub_one_and_add_one_eq_two
#print axioms unit_pow_four_mod_fifteen
#print axioms xeb_expected_score_eq_fidelity_mul_perfect_score
#print axioms compiled_base_has_period_two_and_gcds_return_primes
#print axioms every_base_of_fifteen_has_period_two_or_four

end QuantumAdvantage
