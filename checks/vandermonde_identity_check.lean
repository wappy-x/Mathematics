-- Vandermonde's identity: choosing r people from two groups that share no member is counted by splitting on how many come from the first group, multiplying the two counts in each split and adding the splits, so C(m + n, r) is the sum over k from 0 to r of C(m, k) × C(n, r − k), and with two equal groups the middle entry C(2n, n) is the sum of the squares C(n, k)².
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Nat.Choose.Vandermonde
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Algebra.BigOperators.Intervals

open Finset

/-- Vandermonde's identity, as a count of real choices. Take two groups A and B that share no
member, with A holding m people and B holding n. The number of ways to choose r people from the
two groups merged, order ignored, equals the sum over every split k from 0 to r of
(ways to choose k from A) × (ways to choose the other r − k from B). -/
theorem choosing_from_two_disjoint_groups_splits_by_first_group_count
    {α : Type*} [DecidableEq α] (A B : Finset α) (hAB : Disjoint A B) (r : ℕ) :
    (powersetCard r (A ∪ B)).card =
      ∑ k ∈ range (r + 1), (powersetCard k A).card * (powersetCard (r - k) B).card := by
  rw [card_powersetCard, card_union_of_disjoint hAB, Nat.add_choose_eq,
    Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk]
  simp only [card_powersetCard]

/-- The formula. For all whole numbers m, n and r,
C(m + n, r) = the sum over k from 0 to r of C(m, k) × C(n, r − k),
where a count of the impossible, such as C(4, 5), is 0. -/
theorem vandermonde_identity (m n r : ℕ) :
    (m + n).choose r = ∑ k ∈ range (r + 1), m.choose k * n.choose (r - k) := by
  rw [Nat.add_choose_eq, Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk]

/-- Equal groups turn the sum into a sum of squares: the middle entry of row 2n of Pascal's
triangle is every entry of row n squared and added, C(2n, n) = the sum over k from 0 to n of
C(n, k)². -/
theorem central_binomial_eq_sum_of_squares (n : ℕ) :
    (2 * n).choose n = ∑ k ∈ range (n + 1), (n.choose k) ^ 2 := by
  exact (Nat.sum_range_choose_sq n).symm

-- The band: 6 guitarists and 4 drummers, 5 seats. The pooled count is C(10, 5) = 252.
example : Nat.choose 10 5 = 252 := by decide
-- The six piles, k = 0 to 5 guitarists: 0, 6, 60, 120, 60, 6.
example : (List.range 6).map (fun k => Nat.choose 6 k * Nat.choose 4 (5 - k)) =
    [0, 6, 60, 120, 60, 6] := by decide
-- The no-guitarist term: C(6, 0) × C(4, 5) = 1 × 0 = 0.
example : Nat.choose 6 0 * Nat.choose 4 5 = 0 := by decide
-- The pile with 3 guitarists: C(6, 3) × C(4, 2) = 20 × 6 = 120.
example : Nat.choose 6 3 = 20 ∧ Nat.choose 4 2 = 6 ∧ 20 * 6 = 120 := by decide
-- The splits add to the pool: 0 + 6 + 60 + 120 + 60 + 6 = 252.
example : ∑ k ∈ range 6, Nat.choose 6 k * Nat.choose 4 (5 - k) = 252 := by decide
-- Row 10 of the triangle adds to 1,024.
example : ∑ k ∈ range 11, Nat.choose 10 k = 1024 := by decide
-- Equal pool, 5 and 5: the terms are 1, 25, 100, 100, 25, 1, the squares of row 5, adding to 252.
example : (List.range 6).map (fun k => Nat.choose 5 k * Nat.choose 5 (5 - k)) =
    [1, 25, 100, 100, 25, 1] := by decide
example : ∑ k ∈ range 6, (Nat.choose 5 k) ^ 2 = 252 := by decide
-- Mistake 1, the same k in both groups: 1 + 24 + 90 + 80 + 15 = 210, the four-piece count.
example : ∑ k ∈ range 5, Nat.choose 6 k * Nat.choose 4 k = 210 ∧ Nat.choose 10 4 = 210 := by decide
-- Mistake 2, k stopped at 4: 246.
example : ∑ k ∈ range 5, Nat.choose 6 k * Nat.choose 4 (5 - k) = 246 := by decide
-- Mistake 3, line-ups counted: 10 × 9 × 8 × 7 × 6 = 30,240 = 252 × 120.
example : 10 * 9 * 8 * 7 * 6 = 30240 ∧ 252 * 120 = 30240 := by decide
-- Mistake 4, one player on both lists: nine real people give C(9, 5) = 126 bands.
example : Nat.choose 9 5 = 126 := by decide

#print axioms choosing_from_two_disjoint_groups_splits_by_first_group_count
#print axioms vandermonde_identity
#print axioms central_binomial_eq_sum_of_squares
