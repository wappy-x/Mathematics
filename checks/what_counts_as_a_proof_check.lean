-- Proof: a check up to any bound says nothing beyond it, and Liouville's running score L(n) reaches 1 at 906,150,257 once it sits at 0 just before.
import Mathlib.NumberTheory.ArithmeticFunction.Liouville
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.Simproc.Factors
import Mathlib.Tactic.IntervalCases

open ArithmeticFunction
open scoped ArithmeticFunction.Omega ArithmeticFunction.omega

/-- The running score `L(n) = λ(1) + λ(2) + ... + λ(n)`, where Liouville's sign `λ(k)`
is `+1` when `k` has an even number of prime factors counted with repeats and `-1` when odd. -/
def liouvilleScore (n : ℕ) : ℤ := ∑ k ∈ Finset.Icc 1 n, liouville k

/-- A sum over `1, ..., n` is the sum of the list of the first `n` shifted values. -/
theorem sum_Icc_one_eq_list_sum (f : ℕ → ℤ) (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, f k = ((List.range n).map (fun i => f (i + 1))).sum := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih, List.range_succ]
    simp

/-- For `n ≤ m`, the sum over `1, ..., n` is the sum of the first `n` entries of a list of length `m`. -/
theorem sum_Icc_one_eq_take {f : ℕ → ℤ} {n m : ℕ} (h : n ≤ m) :
    ∑ k ∈ Finset.Icc 1 n, f k = (((List.range m).map (fun i => f (i + 1))).take n).sum := by
  rw [sum_Icc_one_eq_list_sum, ← List.map_take, List.take_range, min_eq_left h]

/-- The signs `λ(1), ..., λ(10)`. -/
theorem liouville_one_to_ten :
    (List.range 10).map (fun i => liouville (i + 1)) = [1, -1, -1, 1, -1, 1, -1, -1, 1, 1] := by
  simp [List.range_succ, liouville_apply, cardFactors_apply, Nat.primeFactorsList_ofNat]

/-- The distinct-prime counts `ω(1), ..., ω(51)`. -/
theorem omega_one_to_51 :
    (List.range 51).map (fun i => ω (i + 1)) =
      [0, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 2, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2, 1, 2, 1, 2, 1, 3,
       1, 1, 2, 2, 2, 2, 1, 2, 2, 2, 1, 3, 1, 2, 2, 2, 1, 2, 1, 2, 2] := by
  simp [List.range_succ, cardDistinctFactors_apply, Nat.primeFactorsList_ofNat]

#print axioms sum_Icc_one_eq_list_sum
#print axioms sum_Icc_one_eq_take
#print axioms liouville_one_to_ten
#print axioms omega_one_to_51

/-- A check proves the cases it checked and nothing beyond them: whatever claim `P` has
passed every check from 0 to `N`, there is another claim `Q` that gives exactly the same
answer on every checked case and yet fails at `N + 1`. So agreement up to `N` carries no
information about the next number. -/
theorem check_up_to_bound_proves_nothing_beyond (N : ℕ) (P : ℕ → Prop)
    (hP : ∀ n ≤ N, P n) :
    ∃ Q : ℕ → Prop, (∀ n ≤ N, Q n ↔ P n) ∧ ¬ Q (N + 1) := by
  have _ := hP
  refine ⟨fun n => n ≤ N ∧ P n, fun n hn => ⟨fun h => h.2, fun h => ⟨hn, h⟩⟩, ?_⟩
  rintro ⟨h, -⟩
  omega

/-- One verified failure disproves Pólya's claim: if the score is `0` at 906,150,256
(the value the card's code computes), then `906,150,257 = 10,039 × 90,263` has two prime
factors, so the score there is `1`, and "`L(n) ≤ 0` for every `n ≥ 2`" is false. -/
theorem polya_fails_at_906150257 (h : liouvilleScore 906150256 = 0) :
    liouvilleScore 906150257 = 1 ∧ ¬ ∀ n ≥ 2, liouvilleScore n ≤ 0 := by
  have hlam : liouville 906150257 = 1 := by
    rw [show (906150257 : ℕ) = 10039 * 90263 by norm_num, liouville_apply_mul,
      liouville_apply (by norm_num), liouville_apply (by norm_num),
      cardFactors_apply_prime (by norm_num), cardFactors_apply_prime (by norm_num)]
    norm_num
  have hL : liouvilleScore 906150257 = 1 := by
    rw [liouvilleScore, show (906150257 : ℕ) = 906150256 + 1 from rfl,
      Finset.sum_Icc_succ_top (by norm_num), ← liouvilleScore, h, hlam]
    norm_num
  refine ⟨hL, fun hall => ?_⟩
  have := hall 906150257 (by norm_num)
  rw [hL] at this
  norm_num at this

/-- The boundary case: started at `n = 1`, Pólya's claim fails at once, because `1` has
zero prime factors, an even count, so `L(1) = 1`. -/
theorem polya_claim_from_one_fails : ¬ ∀ n ≥ 1, liouvilleScore n ≤ 0 := by
  intro hall
  have h := hall 1 le_rfl
  simp [liouvilleScore, liouville_apply_one] at h

-- Worked numbers: 12 = 2 × 2 × 3 has three prime factors, so its sign is -1.
example : Ω 12 = 3 := by simp [cardFactors_apply, Nat.primeFactorsList_ofNat]
example : liouville 12 = -1 := by
  simp [liouville_apply, cardFactors_apply, Nat.primeFactorsList_ofNat]

-- The running score L(1) to L(10): 1 0 -1 0 -1 0 -1 -2 -1 0.
example : (List.range 10).map (fun i => liouvilleScore (i + 1)) =
    [1, 0, -1, 0, -1, 0, -1, -2, -1, 0] := by
  have h : ∀ n ≤ 10, liouvilleScore n =
      (([1, -1, -1, 1, -1, 1, -1, -1, 1, 1] : List ℤ).take n).sum := by
    intro n hn
    rw [liouvilleScore, sum_Icc_one_eq_take hn, liouville_one_to_ten]
  simp only [List.range_succ, List.range_zero, List.nil_append, List.map_append, List.map_cons,
    List.map_nil]
  rw [h 1 (by norm_num), h 2 (by norm_num), h 3 (by norm_num), h 4 (by norm_num),
    h 5 (by norm_num), h 6 (by norm_num), h 7 (by norm_num), h 8 (by norm_num),
    h 9 (by norm_num), h 10 (by norm_num)]
  decide

-- The finite claim from 2 to 10 holds, checked case by case.
example : ∀ n ∈ Finset.Icc 2 10, liouvilleScore n ≤ 0 := by
  intro n hn
  rw [Finset.mem_Icc] at hn
  rw [liouvilleScore, sum_Icc_one_eq_take hn.2, liouville_one_to_ten]
  obtain ⟨h1, h2⟩ := hn
  interval_cases n <;> decide

-- The failure's factorization: 906,150,257 = 10,039 × 90,263, both prime, sign +1.
example : (906150257 : ℕ) = 10039 * 90263 := by norm_num
example : Nat.Prime 10039 := by norm_num
example : Nat.Prime 90263 := by norm_num
example : liouville 906150257 = 1 := by
  rw [show (906150257 : ℕ) = 10039 * 90263 by norm_num, liouville_apply_mul,
    liouville_apply (by norm_num), liouville_apply (by norm_num),
    cardFactors_apply_prime (by norm_num), cardFactors_apply_prime (by norm_num)]
  norm_num

-- Counting each prime once instead: that score first goes above 0 at n = 51, with value 1.
example : (∑ k ∈ Finset.Icc 1 51, (-1 : ℤ) ^ ω k) = 1 ∧
    ∀ n ∈ Finset.Icc 2 50, (∑ k ∈ Finset.Icc 1 n, (-1 : ℤ) ^ ω k) ≤ 0 := by
  have h : ∀ n ≤ 51, (∑ k ∈ Finset.Icc 1 n, (-1 : ℤ) ^ ω k) =
      ((([0, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 2, 2, 1, 1, 2, 1, 2, 2, 2, 1, 2, 1, 2, 1, 2, 1, 3,
       1, 1, 2, 2, 2, 2, 1, 2, 2, 2, 1, 3, 1, 2, 2, 2, 1, 2, 1, 2, 2] : List ℕ).map
        (fun c => (-1 : ℤ) ^ c)).take n).sum := by
    intro n hn
    rw [sum_Icc_one_eq_take (f := fun k => (-1 : ℤ) ^ ω k) hn, ← omega_one_to_51, List.map_map]
    rfl
  refine ⟨by rw [h 51 le_rfl]; decide, ?_⟩
  intro n hn
  rw [Finset.mem_Icc] at hn
  obtain ⟨h1, h2⟩ := hn
  rw [h n (by omega)]
  interval_cases n <;> decide

-- Trusting a pattern: n^2 + n + 41 is prime for n = 0 to 39, but n = 40 gives 41 × 41.
example : ∀ n < 40, Nat.Prime (n ^ 2 + n + 41) := by
  intro n hn
  interval_cases n <;> norm_num
example : 40 ^ 2 + 40 + 41 = 41 * 41 ∧ ¬ Nat.Prime (40 ^ 2 + 40 + 41) := by norm_num

#print axioms check_up_to_bound_proves_nothing_beyond
#print axioms polya_fails_at_906150257
#print axioms polya_claim_from_one_fails
