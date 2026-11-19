-- Large gaps: the proved lower-bound roads to long prime gaps (n! + 2 to n! + n and the primorial run are all composite) and the fact that the longest gap is at least the average gap.
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.NumberTheory.Primorial
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.NormNum.Prime

open Finset

/-- Below 92, every number has a prime within the next 8 numbers. -/
theorem prime_within_nine : ∀ p, p < 92 → ∃ m, p < m ∧ m < p + 9 ∧ m.Prime := by
  intro p hp
  interval_cases p <;>
    first
    | exact ⟨2, by omega, by omega, by norm_num⟩
    | exact ⟨3, by omega, by omega, by norm_num⟩
    | exact ⟨5, by omega, by omega, by norm_num⟩
    | exact ⟨7, by omega, by omega, by norm_num⟩
    | exact ⟨11, by omega, by omega, by norm_num⟩
    | exact ⟨13, by omega, by omega, by norm_num⟩
    | exact ⟨17, by omega, by omega, by norm_num⟩
    | exact ⟨19, by omega, by omega, by norm_num⟩
    | exact ⟨23, by omega, by omega, by norm_num⟩
    | exact ⟨29, by omega, by omega, by norm_num⟩
    | exact ⟨31, by omega, by omega, by norm_num⟩
    | exact ⟨37, by omega, by omega, by norm_num⟩
    | exact ⟨41, by omega, by omega, by norm_num⟩
    | exact ⟨43, by omega, by omega, by norm_num⟩
    | exact ⟨47, by omega, by omega, by norm_num⟩
    | exact ⟨53, by omega, by omega, by norm_num⟩
    | exact ⟨59, by omega, by omega, by norm_num⟩
    | exact ⟨61, by omega, by omega, by norm_num⟩
    | exact ⟨67, by omega, by omega, by norm_num⟩
    | exact ⟨71, by omega, by omega, by norm_num⟩
    | exact ⟨73, by omega, by omega, by norm_num⟩
    | exact ⟨79, by omega, by omega, by norm_num⟩
    | exact ⟨83, by omega, by omega, by norm_num⟩
    | exact ⟨89, by omega, by omega, by norm_num⟩
    | exact ⟨97, by omega, by omega, by norm_num⟩

#print axioms prime_within_nine

/-- The factorial road: for every n, the numbers n! + 2, n! + 3, ..., n! + n are all composite,
since k divides n! + k. So there is a gap of at least n just after n!. -/
theorem factorial_plus_k_composite (n k : ℕ) (hk2 : 2 ≤ k) (hkn : k ≤ n) :
    1 < Nat.factorial n + k ∧ ¬ (Nat.factorial n + k).Prime := by
  have hk0 : 0 < k := by omega
  have hdvd : k ∣ Nat.factorial n := Nat.dvd_factorial hk0 hkn
  have hf : 0 < Nat.factorial n := Nat.factorial_pos n
  refine ⟨by omega, fun hp => ?_⟩
  have hk : k ∣ Nat.factorial n + k := dvd_add hdvd dvd_rfl
  rcases hp.eq_one_or_self_of_dvd k hk with h | h <;> omega

/-- The primorial road: if every number from 2 to k has a prime factor at most q, then each of
q# + 2, ..., q# + k is composite, where q# is the product of the primes up to q. -/
theorem primorial_plus_j_composite (q k : ℕ)
    (hcover : ∀ j, 2 ≤ j → j ≤ k → ∃ r, r.Prime ∧ r ≤ q ∧ r ∣ j) :
    ∀ j, 2 ≤ j → j ≤ k → 1 < primorial q + j ∧ ¬ (primorial q + j).Prime := by
  intro j hj2 hjk
  obtain ⟨r, hr, hrq, hrj⟩ := hcover j hj2 hjk
  have hpos : 0 < primorial q := primorial_pos q
  have hrP : r ∣ primorial q := hr.dvd_primorial_iff.2 hrq
  have hrle : r ≤ j := Nat.le_of_dvd (by omega) hrj
  have hr2 : 2 ≤ r := hr.two_le
  refine ⟨by omega, fun hp => ?_⟩
  rcases hp.eq_one_or_self_of_dvd r (dvd_add hrP hrj) with h | h <;> omega

/-- The gaps telescope and the longest is at least the average: with p_0 = 2, p_1 = 3, ... the
primes in order, the first N gaps add up to p_N − 2, and one of them is at least (p_N − 2)/N. -/
theorem longest_gap_ge_average_gap (N : ℕ) (hN : 1 ≤ N) :
    (∑ i ∈ range N, (Nat.nth Nat.Prime (i + 1) - Nat.nth Nat.Prime i) = Nat.nth Nat.Prime N - 2) ∧
    ∃ i < N, Nat.nth Nat.Prime N - 2 ≤ N * (Nat.nth Nat.Prime (i + 1) - Nat.nth Nat.Prime i) := by
  have hmono : StrictMono (Nat.nth Nat.Prime) := Nat.nth_strictMono Nat.infinite_setOfPred_prime
  have hsum : ∑ i ∈ range N, (Nat.nth Nat.Prime (i + 1) - Nat.nth Nat.Prime i)
      = Nat.nth Nat.Prime N - 2 := by
    rw [Finset.sum_range_tsub hmono.monotone, Nat.nth_prime_zero_eq_two]
  refine ⟨hsum, ?_⟩
  by_contra hcon
  push Not at hcon
  have hne : (range N).Nonempty := ⟨0, by simp; omega⟩
  have hlt := Finset.sum_lt_sum_of_nonempty hne (fun i hi => hcon i (Finset.mem_range.1 hi))
  rw [← Finset.mul_sum, hsum, Finset.sum_const, Finset.card_range, smul_eq_mul] at hlt
  exact lt_irrefl _ hlt

-- The card's example G(100) = 8: the gap from 89 to 97 has seven composites inside it ...
example : Nat.Prime 89 ∧ Nat.Prime 97 ∧ ∀ m, 89 < m → m < 97 → ¬ Nat.Prime m := by
  refine ⟨by norm_num, by norm_num, fun m h1 h2 => ?_⟩
  interval_cases m <;> norm_num

-- ... and no gap between consecutive primes up to 100 is longer than 8.
example : ∀ p q, p < q → q ≤ 100 → p.Prime → q.Prime → (∀ m, p < m → m < q → ¬ m.Prime) →
    q - p ≤ 8 := by
  intro p q hpq hq hp hqp hgap
  by_contra hcon
  obtain ⟨m, hm1, hm2, hm⟩ := prime_within_nine p (by omega)
  exact hgap m hm1 (by omega) hm

#print axioms factorial_plus_k_composite
#print axioms primorial_plus_j_composite
#print axioms longest_gap_ge_average_gap
