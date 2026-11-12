-- How primes thin out: the primes never run out, yet the share of numbers up to n that are prime falls to 0, every number that is not prime is caught by a smaller prime, and the card's whole-number counts are exact (the n over log n rule itself is left to the Python and Rust checks).
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.NumberTheory.Chebyshev
import Mathlib.Analysis.SpecialFunctions.Log.Base

open Filter Topology

/-- The primes never run out, but they spread out. Let pi(n) be how many primes there are up to n
(1 is not one). As n grows without end, pi(n) grows past every bound, while the share of the
numbers up to n that are prime, pi(n) ÷ n, sags all the way to 0. -/
theorem primes_never_run_out_but_their_share_falls_to_zero :
    Tendsto (fun n : ℕ => Nat.primeCounting n) atTop atTop ∧
      Tendsto (fun n : ℕ => (Nat.primeCounting n : ℝ) / n) atTop (𝓝 0) := by
  refine ⟨Nat.tendsto_primeCounting, ?_⟩
  have hreal : Tendsto (fun x : ℝ => (Real.log 4 + 1) / Real.log x) atTop (𝓝 0) :=
    by simpa [div_eq_mul_inv] using
      Real.tendsto_log_atTop.inv_tendsto_atTop.const_mul (Real.log 4 + 1)
  have hnat := hreal.comp tendsto_natCast_atTop_atTop
  have hb := tendsto_natCast_atTop_atTop.eventually (Chebyshev.eventually_primeCounting_le one_pos)
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hnat
    (Eventually.of_forall fun n => by positivity) ?_
  filter_upwards [hb, eventually_gt_atTop 1] with n hn h1
  simp only [Nat.floor_natCast] at hn
  have hpos : (0 : ℝ) < n := by exact_mod_cast (by omega : 0 < n)
  rw [Function.comp_apply, div_le_iff₀ hpos]
  calc (Nat.primeCounting n : ℝ) ≤ (Real.log 4 + 1) * n / Real.log n := hn
    _ = (Real.log 4 + 1) / Real.log n * n := by ring

/-- What the sieve lives on: every number from 2 up that is not prime has a smaller prime
dividing it. -/
theorem not_prime_has_smaller_prime_divisor (n : ℕ) (h2 : 2 ≤ n) (hn : ¬ n.Prime) :
    ∃ p, p.Prime ∧ p < n ∧ p ∣ n := by
  refine ⟨n.minFac, Nat.minFac_prime (by omega), ?_, Nat.minFac_dvd n⟩
  have hne : n.minFac ≠ n := fun h => hn (Nat.prime_def_minFac.mpr ⟨h2, h⟩)
  exact lt_of_le_of_ne (Nat.minFac_le (by omega)) hne

-- The card's counts: 25 primes up to 100, and 168 up to 1,000.
example : Nat.primeCounting 100 = 25 := by decide +kernel
example : Nat.primeCounting 1000 = 168 := by decide +kernel
-- Primes per hundred lockers: 25 in the first hundred and 14 among lockers 901 to 1,000.
-- (The 8 just under a million, pi(1,000,000) = 78,498 and the 1,000th prime 7,919 are too big
-- for the kernel to count; the Python and Rust checks cover them.)
example : ((Finset.Icc 1 100).filter Nat.Prime).card = 25 := by decide +kernel
example : ((Finset.Icc 901 1000).filter Nat.Prime).card = 14 := by decide +kernel
-- Ten thousand times the corridor, three times the log: ln 1,000,000 = 3 × ln 100.
example : Real.log 1000000 = 3 * Real.log 100 := by
  rw [show (1000000 : ℝ) = 100 ^ 3 by norm_num, Real.log_pow]; norm_num
-- Log base 10 instead of the natural log: 100 ÷ 2 = 50, 1,000 ÷ 3 and 1,000,000 ÷ 6.
example : (100 : ℝ) / Real.logb 10 100 = 50 := by
  rw [show (100 : ℝ) = 10 ^ (2 : ℕ) by norm_num, Real.logb_pow, Real.logb_self_eq_one (by norm_num)]
  norm_num
example : (1000 : ℝ) / Real.logb 10 1000 = 1000 / 3 ∧
    (1000000 : ℝ) / Real.logb 10 1000000 = 1000000 / 6 := by
  constructor
  · rw [show (1000 : ℝ) = 10 ^ (3 : ℕ) by norm_num, Real.logb_pow, Real.logb_self_eq_one (by norm_num)]
    norm_num
  · rw [show (1000000 : ℝ) = 10 ^ (6 : ℕ) by norm_num, Real.logb_pow,
      Real.logb_self_eq_one (by norm_num)]
    norm_num
-- The worked numbers: short by 78,498 − 72,382 = 6,116, and a flat 25 per hundred gives 250,000.
example : 78498 - 72382 = 6116 ∧ 25 * 10000 = 250000 := by decide

#print axioms primes_never_run_out_but_their_share_falls_to_zero
#print axioms not_prime_has_smaller_prime_divisor
