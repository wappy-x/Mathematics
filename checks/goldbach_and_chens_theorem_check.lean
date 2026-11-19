-- Goldbach: if every even number from 4 up is two primes then every odd number from 7 up is three primes, the local factor counts p - 1 or p - 2 good remainders mod p, the circle-method integral counts the ordered prime pairs exactly, and the card's whole-number examples are exact.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.Simproc.Factors

open Complex

theorem integral_exp_two_pi_int (k : ℤ) :
    ∫ α in (0 : ℝ)..1, exp (2 * Real.pi * I * (k : ℂ) * (α : ℂ)) = if k = 0 then 1 else 0 := by
  split_ifs with hk
  · subst hk; simp
  · have hc : (2 * Real.pi * I * (k : ℂ)) ≠ 0 := by
      have : (k : ℂ) ≠ 0 := by exact_mod_cast hk
      have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
      simp [hpi, I_ne_zero, this]
    rw [integral_exp_mul_complex hc]
    have h1 : exp (2 * Real.pi * I * (k : ℂ)) = 1 := by
      rw [← exp_int_mul_two_pi_mul_I k]; congr 1; ring
    simp [h1]

#print axioms integral_exp_two_pi_int

/-- Two primes would give three: if every even number from 4 up is the sum of two primes
(binary Goldbach), then every odd number from 7 up is the sum of three primes
(ternary Goldbach). The binary claim is open; this implication is proved on the card. -/
theorem binary_goldbach_implies_ternary
    (hbin : ∀ n : ℕ, Even n → 4 ≤ n → ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p + q = n) :
    ∀ N : ℕ, Odd N → 7 ≤ N → ∃ p q r : ℕ, p.Prime ∧ q.Prime ∧ r.Prime ∧ p + q + r = N := by
  intro N hN h7
  obtain ⟨p, q, hp, hq, hpq⟩ := hbin (N - 3) (by
    obtain ⟨k, hk⟩ := hN; exact ⟨k - 1, by omega⟩) (by omega)
  exact ⟨p, q, 3, hp, hq, Nat.prime_three, by omega⟩

/-- The local factor is a count of remainders: for a prime p above 2, the remainders a mod p
with both a and n - a off the multiples of p number p - 1 when p divides n, and p - 2 when
it does not. -/
theorem local_factor_good_remainders (p n : ℕ) [Fact p.Prime] (hp : 2 < p) :
    (Finset.univ.filter (fun a : ZMod p => a ≠ 0 ∧ (n : ZMod p) - a ≠ 0)).card =
      if p ∣ n then p - 1 else p - 2 := by
  have hset : Finset.univ.filter (fun a : ZMod p => a ≠ 0 ∧ (n : ZMod p) - a ≠ 0) =
      ((Finset.univ.erase (0 : ZMod p)).erase (n : ZMod p)) := by
    ext a; simp [sub_ne_zero, and_comm, eq_comm]
  rw [hset]
  split_ifs with h
  · have h0 : (n : ZMod p) = 0 := (ZMod.natCast_eq_zero_iff n p).2 h
    rw [h0, Finset.erase_eq_of_notMem (by simp), Finset.card_erase_of_mem (by simp),
      Finset.card_univ, ZMod.card]
  · have h0 : (n : ZMod p) ≠ 0 := fun e => h ((ZMod.natCast_eq_zero_iff n p).1 e)
    rw [Finset.card_erase_of_mem (by simp [h0]), Finset.card_erase_of_mem (by simp),
      Finset.card_univ, ZMod.card]
    omega

/-- The circle method counts with waves: with F(α) the sum of e(pα) = exp(2πipα) over the
primes p up to n, the integral of F(α)² e(-nα) over one turn 0 ≤ α ≤ 1 is exactly the number
of ordered pairs (p, q) of primes with p + q = n. -/
theorem circle_method_counts_ordered_pairs (n : ℕ) :
    ∫ α in (0 : ℝ)..1,
        (∑ p ∈ (Finset.range (n + 1)).filter Nat.Prime,
            exp (2 * Real.pi * I * (p : ℂ) * (α : ℂ))) ^ 2 *
          exp (-(2 * Real.pi * I * (n : ℂ) * (α : ℂ))) =
      ((((Finset.range (n + 1)) ×ˢ (Finset.range (n + 1))).filter
          (fun x : ℕ × ℕ => x.1.Prime ∧ x.2.Prime ∧ x.1 + x.2 = n)).card : ℂ) := by
  set S := (Finset.range (n + 1)).filter Nat.Prime with hS
  have hfun : (fun α : ℝ => (∑ p ∈ S, exp (2 * Real.pi * I * (p : ℂ) * (α : ℂ))) ^ 2 *
          exp (-(2 * Real.pi * I * (n : ℂ) * (α : ℂ)))) =
      fun α : ℝ => ∑ x ∈ S ×ˢ S,
        exp (2 * Real.pi * I * (((x.1 + x.2 : ℕ) : ℤ) - (n : ℤ) : ℤ) * (α : ℂ)) := by
    funext α
    rw [sq, Finset.sum_mul_sum, Finset.sum_mul, Finset.sum_product]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [Finset.sum_mul]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [← exp_add, ← exp_add]; congr 1; push_cast; ring
  rw [hfun, intervalIntegral.integral_finsetSum]
  · simp_rw [integral_exp_two_pi_int]
    rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul, mul_one]
    congr 1
    norm_cast
    congr 1
    ext x
    simp [hS, Finset.mem_product]
    tauto
  · intro x _
    exact (Continuous.intervalIntegrable (by fun_prop) _ _)

/-! The card's whole-number examples. -/

-- 100 = 3 + 97 = 11 + 89 = 17 + 83 = 29 + 71, four of its six pairs.
example : (3 : ℕ).Prime ∧ (97 : ℕ).Prime ∧ 3 + 97 = 100 := by norm_num
example : (11 : ℕ).Prime ∧ (89 : ℕ).Prime ∧ 11 + 89 = 100 := by norm_num
example : (17 : ℕ).Prime ∧ (83 : ℕ).Prime ∧ 17 + 83 = 100 := by norm_num
example : (29 : ℕ).Prime ∧ (71 : ℕ).Prime ∧ 29 + 71 = 100 := by norm_num
-- R(100) = 6: pairs p ≤ q of primes adding to 100.
example : ((Finset.Icc 2 50).filter (fun p => p.Prime ∧ (100 - p).Prime)).card = 6 := by decide
-- The smallest pair of a million: 17 + 999,983.
example : (17 : ℕ).Prime ∧ (999983 : ℕ).Prime ∧ 17 + 999983 = 1000000 := by norm_num
-- Ternary: 7 = 2 + 2 + 3, and 1,000,001 = 3 + 19 + 999,979.
example : (2 : ℕ).Prime ∧ (3 : ℕ).Prime ∧ 2 + 2 + 3 = 7 := by norm_num
example : (3 : ℕ).Prime ∧ (19 : ℕ).Prime ∧ (999979 : ℕ).Prime ∧ 3 + 19 + 999979 = 1000001 := by
  norm_num
-- 1,000,001 has no pair: one prime would be 2, and 999,999 = 3³ × 7 × 11 × 13 × 37.
example : 999999 = 3 ^ 3 * 7 * 11 * 13 * 37 ∧ 1000001 - 2 = 999999 ∧ ¬ (999999 : ℕ).Prime := by
  norm_num
-- Step 1 at p = 3: 1,000,002 (divisible by 3) has 2 good remainders, 999,998 (not) has 1.
example : (Finset.univ.filter
    (fun a : ZMod 3 => a ≠ 0 ∧ ((1000002 : ℕ) : ZMod 3) - a ≠ 0)).card = 2 := by decide
example : (Finset.univ.filter
    (fun a : ZMod 3 => a ≠ 0 ∧ ((999998 : ℕ) : ZMod 3) - a ≠ 0)).card = 1 := by decide
-- The factorizations of the card's table: 999,998 = 2 × 31 × 127², 1,000,002 = 2 × 3 × 166,667.
example : 999998 = 2 * 31 * 127 ^ 2 ∧ 1000002 = 2 * 3 * 166667 ∧ (166667 : ℕ).Prime := by norm_num
-- A P₂: 6 = 2 × 3 has two prime factors, counted with repeats.
example : Nat.primeFactorsList 6 = [2, 3] ∧ (Nat.primeFactorsList 6).length = 2 := by
  simp [Nat.primeFactorsList_ofNat]

#print axioms binary_goldbach_implies_ternary
#print axioms local_factor_good_remainders
#print axioms circle_method_counts_ordered_pairs
