-- The binomial theorem: for any whole power n, (a + b)^n is the sum of C(n, k) a^(n-k) b^k, and (a + b + c)^n is the sum of n!/(i! j! l!) a^i b^j c^l over all splits i + j + l = n, whenever the letters can be multiplied in either order.
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset Nat

/-- The binomial theorem. For every whole power n ≥ 0, multiplying out n brackets of
(a + b) gives one piece per k from 0 to n: C(n, k) copies of a^(n-k) b^k, where C(n, k)
counts the ways to choose which k brackets hand over b. The only condition is that a and b
can be multiplied in either order (a × b = b × a); a and b may be any numbers, negative
ones included, or anything else that adds and multiplies in the usual way. -/
theorem binomial_theorem_choice_counts {R : Type*} [Semiring R]
    (a b : R) (hab : Commute a b) (n : ℕ) :
    (a + b) ^ n = ∑ k ∈ range (n + 1), (n.choose k : R) * a ^ (n - k) * b ^ k := by
  rw [add_comm, hab.symm.add_pow]
  refine sum_congr rfl fun k _ => ?_
  rw [(hab.symm.pow_pow k (n - k)).eq, ← Nat.cast_comm, mul_assoc]

/-- The three-term version. For every whole power n ≥ 0, (a + b + c)^n is the sum, over
all whole i, j, l adding to n, of C(n; i, j, l) = n! / (i! j! l!) copies of a^i b^j c^l,
where C(n; i, j, l) counts the ways to split the n brackets into the groups that hand over
a, b and c. The condition is again that order of multiplication does not matter between
any two of a, b, c. -/
theorem trinomial_theorem_split_counts {R : Type*} [Semiring R]
    (a b c : R) (hab : Commute a b) (hac : Commute a c) (hbc : Commute b c) (n : ℕ) :
    (a + b + c) ^ n =
      ∑ x ∈ (range (n + 1) ×ˢ range (n + 1) ×ˢ range (n + 1)).filter
          (fun x => x.1 + x.2.1 + x.2.2 = n),
        ((n ! / (x.1 ! * x.2.1 ! * x.2.2 !) : ℕ) : R) * a ^ x.1 * b ^ x.2.1 * c ^ x.2.2 := by
  -- The split count n!/(i! j! l!) equals C(n, i+j) * C(i+j, j).
  have coef : ∀ i j l : ℕ,
      (i + j + l)! / (i ! * j ! * l !) = (i + j + l).choose (i + j) * (i + j).choose j := by
    intro i j l
    apply Nat.div_eq_of_eq_mul_left (by positivity)
    have h1 := Nat.choose_mul_factorial_mul_factorial (Nat.le_add_right (i + j) l)
    rw [Nat.add_sub_cancel_left] at h1
    have h2 := Nat.add_choose_mul_factorial_mul_factorial i j
    rw [← h1, ← h2]
    ring
  rw [(hac.add_left hbc).add_pow]
  simp_rw [binomial_theorem_choice_counts a b hab, sum_mul]
  rw [sum_sigma']
  symm
  apply sum_nbij' (fun x => (⟨x.1 + x.2.1, x.2.1⟩ : Σ _ : ℕ, ℕ))
    (fun y => (y.1 - y.2, y.2, n - y.1))
  · rintro ⟨i, j, l⟩ hx
    simp only [mem_filter, mem_product, mem_range] at hx
    simp only [mem_sigma, mem_range]
    omega
  · rintro ⟨m, j⟩ hx
    simp only [mem_sigma, mem_range] at hx
    simp only [mem_filter, mem_product, mem_range]
    omega
  · rintro ⟨i, j, l⟩ hx
    simp only [mem_filter, mem_product, mem_range] at hx
    simp only [Prod.mk.injEq, true_and]
    omega
  · rintro ⟨m, j⟩ hx
    simp only [mem_sigma, mem_range] at hx
    simp only [Sigma.mk.injEq, heq_eq_eq, and_true]
    omega
  · rintro ⟨i, j, l⟩ hx
    simp only [mem_filter, mem_product, mem_range] at hx
    obtain ⟨-, rfl⟩ := hx
    simp only [coef, Nat.add_sub_cancel, Nat.add_sub_cancel_left, Nat.cast_mul]
    simp only [mul_assoc]
    rw [(Nat.cast_commute ((i + j + l).choose (i + j)) (((i + j).choose j : ℕ) : R)).left_comm]
    congr 1
    rw [Nat.cast_comm]
    simp only [mul_assoc]

/-- Setting a = b = 1: row n of Pascal's triangle adds to 2^n. -/
theorem pascal_row_sums_to_two_pow (n : ℕ) :
    ∑ k ∈ range (n + 1), n.choose k = 2 ^ n := by
  exact Nat.sum_range_choose n

-- Row 4 of Pascal's triangle is 1, 4, 6, 4, 1.
example : (List.range 5).map (Nat.choose 4) = [1, 4, 6, 4, 1] := by decide

-- (10 + 1)^4 term by term: 10,000 + 4,000 + 600 + 40 + 1 = 14,641 = 11^4.
example : ∑ k ∈ range 5, Nat.choose 4 k * 10 ^ (4 - k) * 1 ^ k = 14641 := by decide
example : (11 : ℕ) ^ 4 = 14641 := by norm_num

-- (10 - 1)^4 with the sign riding in b^k: 10,000 - 4,000 + 600 - 40 + 1 = 6,561 = 9^4.
example : ∑ k ∈ range 5, (Nat.choose 4 k : ℤ) * 10 ^ (4 - k) * (-1) ^ k = 6561 := by decide
example : (9 : ℕ) ^ 4 = 6561 := by norm_num

-- Row 10 adds to 1,024, and with alternating signs to 0.
example : ∑ k ∈ range 11, Nat.choose 10 k = 1024 := by decide
example : ∑ k ∈ range 11, (-1 : ℤ) ^ k * Nat.choose 10 k = 0 := by decide

-- One bracket each: C(3; 1, 1, 1) = 3!/(1! 1! 1!) = 6, contributing 6 × 100 × 10 × 1 = 6,000.
example : 3 ! / (1 ! * 1 ! * 1 !) = 6 := by decide
example : 3 ! / (1 ! * 1 ! * 1 !) * 100 * 10 * 1 = 6000 := by decide

-- (100 + 10 + 1)^3 by split counts is 1,367,631 = 111^3.
example :
    ∑ x ∈ (range 4 ×ˢ range 4 ×ˢ range 4).filter (fun x => x.1 + x.2.1 + x.2.2 = 3),
      3 ! / (x.1 ! * x.2.1 ! * x.2.2 !) * 100 ^ x.1 * 10 ^ x.2.1 * 1 ^ x.2.2 = 1367631 := by
  decide
example : (111 : ℕ) ^ 3 = 1367631 := by norm_num

-- The usual mistake: (10 + 1)^4 read as 10^4 + 1^4 gives 10,001, not 14,641.
example : (10 : ℕ) ^ 4 + 1 ^ 4 = 10001 ∧ (10 + 1 : ℕ) ^ 4 ≠ 10 ^ 4 + 1 ^ 4 := by decide

#print axioms binomial_theorem_choice_counts
#print axioms trinomial_theorem_split_counts
#print axioms pascal_row_sums_to_two_pow
