-- Onto functions: the number of onto functions from n different items to k named recipients is the sieve sum of (-1)^j C(k, j) (k - j)^n, it equals k! times the Stirling number S(n, k), and the sum is 0 when there are fewer items than recipients.
import Mathlib.Combinatorics.Enumerative.Stirling
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Combinatorics.Enumerative.InclusionExclusion
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring
import Mathlib.Data.Fintype.Lattice
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Fintype.Card

open Finset

theorem sieve_sum_succ_succ (n k : ℕ) :
    ∑ j ∈ range (k + 1 + 1), (-1 : ℤ) ^ j * ((k + 1).choose j : ℤ) * ((k + 1 - j : ℕ) : ℤ) ^ (n + 1)
      = ((k : ℤ) + 1) *
        (∑ j ∈ range (k + 1 + 1), (-1 : ℤ) ^ j * ((k + 1).choose j : ℤ) * ((k + 1 - j : ℕ) : ℤ) ^ n
          + ∑ j ∈ range (k + 1), (-1 : ℤ) ^ j * (k.choose j : ℤ) * ((k - j : ℕ) : ℤ) ^ n) := by
  have hU1 : ∑ j ∈ range (k + 1 + 1),
      (-1 : ℤ) ^ j * ((k + 1).choose j : ℤ) * ((k + 1 - j : ℕ) : ℤ) ^ (n + 1)
      = ((k : ℤ) + 1) * ∑ j ∈ range (k + 1 + 1),
          (-1 : ℤ) ^ j * (k.choose j : ℤ) * ((k + 1 - j : ℕ) : ℤ) ^ n := by
    rw [mul_sum]
    refine sum_congr rfl fun j _ => ?_
    have h := Nat.choose_mul_succ_eq k j
    have h' : ((k.choose j : ℕ) : ℤ) * ((k : ℤ) + 1)
        = (((k + 1).choose j : ℕ) : ℤ) * ((k + 1 - j : ℕ) : ℤ) := by
      exact_mod_cast h
    rw [pow_succ]
    linear_combination (-(-1 : ℤ) ^ j * ((k + 1 - j : ℕ) : ℤ) ^ n) * h'
  have hU2 : ∑ j ∈ range (k + 1 + 1),
      (-1 : ℤ) ^ j * (k.choose j : ℤ) * ((k + 1 - j : ℕ) : ℤ) ^ n
      = ∑ j ∈ range (k + 1 + 1), (-1 : ℤ) ^ j * ((k + 1).choose j : ℤ) * ((k + 1 - j : ℕ) : ℤ) ^ n
          + ∑ j ∈ range (k + 1), (-1 : ℤ) ^ j * (k.choose j : ℤ) * ((k - j : ℕ) : ℤ) ^ n := by
    rw [sum_range_succ' _ (k + 1), sum_range_succ' (fun j => (-1 : ℤ) ^ j *
      ((k + 1).choose j : ℤ) * ((k + 1 - j : ℕ) : ℤ) ^ n) (k + 1)]
    have key : ∑ i ∈ range (k + 1), (-1 : ℤ) ^ (i + 1) * ((k + 1).choose (i + 1) : ℤ)
          * ((k + 1 - (i + 1) : ℕ) : ℤ) ^ n
        = ∑ i ∈ range (k + 1), (-1 : ℤ) ^ (i + 1) * (k.choose (i + 1) : ℤ)
          * ((k + 1 - (i + 1) : ℕ) : ℤ) ^ n
          - ∑ i ∈ range (k + 1), (-1 : ℤ) ^ i * (k.choose i : ℤ) * ((k - i : ℕ) : ℤ) ^ n := by
      rw [← sum_sub_distrib]
      refine sum_congr rfl fun i _ => ?_
      rw [Nat.choose_succ_succ', Nat.add_sub_add_right]
      push_cast
      ring
    rw [key]
    simp
    ring
  rw [hU1, hU2]

#print axioms sieve_sum_succ_succ

theorem sieve_sum_eq_factorial_mul_stirlingSecond (n k : ℕ) :
    ∑ j ∈ range (k + 1), (-1 : ℤ) ^ j * (k.choose j : ℤ) * ((k - j : ℕ) : ℤ) ^ n
      = ((k.factorial * Nat.stirlingSecond n k : ℕ) : ℤ) := by
  induction n generalizing k with
  | zero =>
    simp only [pow_zero, mul_one]
    rw [Int.alternating_sum_range_choose]
    cases k <;> simp
  | succ n ih =>
    cases k with
    | zero => simp
    | succ k =>
      rw [sieve_sum_succ_succ, ih (k + 1), ih k, Nat.stirlingSecond_succ_succ,
        Nat.factorial_succ]
      push_cast
      ring

#print axioms sieve_sum_eq_factorial_mul_stirlingSecond

/-- The sieve count of onto functions: handing out `n` different items to `k` named recipients so
that every recipient gets at least one item can be done in
`∑_{j=0}^{k} (-1)^j C(k, j) (k - j)^n` ways. Items are the points of `Fin n`, recipients the points
of `Fin k`, and a handout is a function `Fin n → Fin k`; nothing is assumed about `n` or `k`. -/
theorem card_onto_eq_sieve (n k : ℕ) :
    ((univ.filter (fun f : Fin n → Fin k => Function.Surjective f)).card : ℤ) =
      ∑ j ∈ range (k + 1), (-1 : ℤ) ^ j * (k.choose j : ℤ) * ((k - j : ℕ) : ℤ) ^ n := by

  have h := inclusion_exclusion_card_inf_compl (univ : Finset (Fin k))
    (fun b => univ.filter (fun f : Fin n → Fin k => ∀ x, f x ≠ b))
  have e1 : (univ.inf fun b => (univ.filter (fun f : Fin n → Fin k => ∀ x, f x ≠ b))ᶜ)
      = univ.filter (fun f : Fin n → Fin k => Function.Surjective f) := by
    ext f
    rw [mem_filter]; simp [Finset.mem_inf, Function.Surjective]
  have e2 : ∀ t : Finset (Fin k),
      (t.inf fun b => univ.filter (fun f : Fin n → Fin k => ∀ x, f x ≠ b))
        = Fintype.piFinset (fun _ : Fin n => tᶜ) := by
    intro t
    ext f
    simp [Finset.mem_inf]
    constructor
    · intro h x hx; exact h _ hx x rfl
    · intro h b hb x hx; exact h x (hx ▸ hb)
  rw [e1] at h
  rw [h]
  simp_rw [e2, Fintype.card_piFinset, prod_const, card_univ, Fintype.card_fin, card_compl,
    Fintype.card_fin]
  rw [sum_powerset_apply_card (fun m => (-1 : ℤ) ^ m * (((k - m : ℕ) ^ n : ℕ) : ℤ))]
  simp only [card_univ, Fintype.card_fin, nsmul_eq_mul]
  refine sum_congr rfl fun j _ => ?_
  push_cast
  ring

/-- The grouping road: every onto handout is one split of the `n` items into `k` unnamed nonempty
piles followed by one of the `k!` ways to name the piles, so the count is `k! × S(n, k)`. -/
theorem card_onto_eq_factorial_mul_stirlingSecond (n k : ℕ) :
    (univ.filter (fun f : Fin n → Fin k => Function.Surjective f)).card =
      k.factorial * Nat.stirlingSecond n k := by
  have h := sieve_sum_eq_factorial_mul_stirlingSecond n k
  rw [← card_onto_eq_sieve] at h
  exact_mod_cast h

/-- With fewer items than recipients the sieve sum returns 0: `n` jobs cannot keep `k > n`
mechanics busy. -/
theorem sieve_sum_eq_zero_of_lt (n k : ℕ) (h : n < k) :
    ∑ j ∈ range (k + 1), (-1 : ℤ) ^ j * (k.choose j : ℤ) * ((k - j : ℕ) : ℤ) ^ n = 0 := by
  rw [← card_onto_eq_sieve]
  have : (univ.filter (fun f : Fin n → Fin k => Function.Surjective f)) = ∅ := by
    rw [filter_eq_empty_iff]
    intro f _ hf
    have := Fintype.card_le_of_surjective f hf
    simp only [Fintype.card_fin] at this
    omega
  rw [this]
  simp

/-- The sieve sum as a function of `n` and `k`, used by the examples below. -/
def sieveSum (n k : ℕ) : ℤ :=
  ∑ j ∈ range (k + 1), (-1 : ℤ) ^ j * (k.choose j : ℤ) * ((k - j : ℕ) : ℤ) ^ n

-- The garage: 3^5 = 243 handouts, 3 × 2^5 = 96 taken off, 3 × 1^5 = 3 added back, 0^5 = 0.
example : (3 : ℤ) ^ 5 = 243 ∧ 3 * (2 : ℤ) ^ 5 = 96 ∧ 3 * (1 : ℤ) ^ 5 = 3 ∧ (0 : ℤ) ^ 5 = 0 := by
  norm_num
example : (243 : ℤ) - 96 + 3 - 0 = 150 := by norm_num
example : sieveSum 5 3 = 150 := by decide
-- Stopping after the subtraction gives 147, not 150.
example : (243 : ℤ) - 96 = 147 := by norm_num
-- The grouping road: S(5, 3) = 25 and 3! × 25 = 150.
example : Nat.stirlingSecond 5 3 = 25 := by decide
example : Nat.factorial 3 * Nat.stirlingSecond 5 3 = 150 := by decide
-- Six jobs: 540 of the 729 handouts reach all three mechanics, and 3! × S(6, 3) = 6 × 90 = 540.
example : sieveSum 6 3 = 540 ∧ (3 : ℤ) ^ 6 = 729 := by decide
example : Nat.stirlingSecond 6 3 = 90 ∧ Nat.factorial 3 * Nat.stirlingSecond 6 3 = 540 := by decide
-- Jobs n = 1 to 6, three mechanics: 0, 0, 6, 36, 150, 540.
example : (List.range 6).map (fun i => sieveSum (i + 1) 3) = [0, 0, 6, 36, 150, 540] := by decide
-- Five jobs, mechanics k = 1 to 6: 1, 30, 150, 240, 120, 0.
example : (List.range 6).map (fun i => sieveSum 5 (i + 1)) = [1, 30, 150, 240, 120, 0] := by decide
-- All 243 handouts split by mechanics used: 3 × 1 + 3 × 30 + 1 × 150 = 243.
example : 3 * sieveSum 5 1 + 3 * sieveSum 5 2 + 1 * sieveSum 5 3 = 243 := by decide

#print axioms card_onto_eq_sieve
#print axioms card_onto_eq_factorial_mul_stirlingSecond
#print axioms sieve_sum_eq_zero_of_lt
