-- Combinations, n choose k: from n different things, the number of ways to pick k with the order thrown away is the number of ordered picks divided by k!, which is n!/(k! (n-k)!), and picking k is the same count as picking the n-k left out.
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Fintype.CardEmbedding
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.NormNum

open Nat

/-- Combinations, n choose k. Take a set `s` of n different things and a whole number k between
0 and n. The picks of k of them with the order thrown away (the k-element subsets of `s`) number
the ordered picks of k different things from `s` (the one-to-one lists of length k) divided by
k!, and that count is n!/(k! × (n-k)!). -/
theorem unordered_picks_eq_ordered_picks_div_factorial {α : Type*} [DecidableEq α]
    (s : Finset α) (k : ℕ) (hk : k ≤ s.card) :
    (s.powersetCard k).card = Fintype.card (Fin k ↪ s) / k ! ∧
      (s.powersetCard k).card = s.card ! / (k ! * (s.card - k)!) := by
  have hord : Fintype.card (Fin k ↪ s) = (s.powersetCard k).card * k ! := by
    rw [Fintype.card_embedding_eq, Fintype.card_fin, Fintype.card_coe, Finset.card_powersetCard,
      Nat.descFactorial_eq_factorial_mul_choose, Nat.mul_comm]
  refine ⟨?_, ?_⟩
  · rw [hord, Nat.mul_div_cancel _ (Nat.factorial_pos k)]
  · rw [Finset.card_powersetCard, Nat.choose_eq_factorial_div_factorial hk]

/-- The rule of division behind it. Every unordered pick of k things from `s` is counted exactly
k! times among the ordered picks, once for each order of its members, so the ordered picks
number the unordered picks times k!. -/
theorem ordered_picks_eq_unordered_picks_mul_factorial {α : Type*} [DecidableEq α]
    (s : Finset α) (k : ℕ) :
    Fintype.card (Fin k ↪ s) = (s.powersetCard k).card * k ! := by
  rw [Fintype.card_embedding_eq, Fintype.card_fin, Fintype.card_coe, Finset.card_powersetCard,
    Nat.descFactorial_eq_factorial_mul_choose, Nat.mul_comm]

/-- The symmetry identity. Choosing the k things that are picked also chooses the n-k left
behind, so from n different things there are as many picks of k as picks of n-k:
C(n, k) = C(n, n-k). -/
theorem picks_of_k_eq_picks_of_n_sub_k {α : Type*} [DecidableEq α]
    (s : Finset α) (k : ℕ) (hk : k ≤ s.card) :
    (s.powersetCard k).card = (s.powersetCard (s.card - k)).card := by
  rw [Finset.card_powersetCard, Finset.card_powersetCard, Nat.choose_symm hk]

-- The lottery: 49 × 48 × 47 × 46 × 45 × 44 = 10,068,347,520 ordered draws of six balls from 49.
example : (49 : ℕ).descFactorial 6 = 10068347520 := by decide
example : 49 * 48 * 47 * 46 * 45 * 44 = 10068347520 := by norm_num
-- The orders of one ticket: 6! = 720.
example : 6 ! = 720 := by decide
-- Divide the order out: 10,068,347,520 ÷ 720 = 13,983,816 tickets.
example : 10068347520 / 720 = 13983816 := by norm_num
example : Nat.choose 49 6 = 13983816 := by
  rw [Nat.choose_eq_descFactorial_div_factorial]; decide
-- The same count as sets: six-ball tickets from 49 numbered balls.
example : ((Finset.range 49).powersetCard 6).card = 13983816 := by
  rw [Finset.card_powersetCard, Finset.card_range, Nat.choose_eq_descFactorial_div_factorial]
  decide
-- The toy draw: 2 balls from 5 make 10 tickets.
example : ((Finset.range 5).powersetCard 2).card = 10 := by decide
-- The squad of 20: an eleven in order is 20 × 19 × ... × 10 = 6,704,425,728,000; 11! = 39,916,800.
example : (20 : ℕ).descFactorial 11 = 6704425728000 := by decide
example : 11 ! = 39916800 := by decide
example : 6704425728000 / 39916800 = 167960 := by norm_num
-- C(20, 11) = C(20, 9) = 167,960.
example : Nat.choose 20 11 = 167960 ∧ Nat.choose 20 9 = 167960 := by
  rw [Nat.choose_eq_descFactorial_div_factorial, Nat.choose_eq_descFactorial_div_factorial]
  decide
-- Five penalty takers in order: 20 × 19 × 18 × 17 × 16 = 1,860,480.
example : (20 : ℕ).descFactorial 5 = 1860480 := by decide
-- Row 20 of Pascal's triangle starts 1 20 190 1140 4845 15504 38760, and adds to 1,048,576.
example : (List.range 7).map (Nat.choose 20) = [1, 20, 190, 1140, 4845, 15504, 38760] := by
  decide
example : ∑ i ∈ Finset.range 21, Nat.choose 20 i = 1048576 := by
  rw [Nat.sum_range_choose]; norm_num
-- The mistakes: dividing by 6 gives 1,678,057,920; putting each ball back gives 49^6.
example : 10068347520 / 6 = 1678057920 := by norm_num
example : (49 : ℕ) ^ 6 = 13841287201 := by norm_num
example : 167960 * 11 ! = 6704425728000 := by decide

#print axioms unordered_picks_eq_ordered_picks_div_factorial
#print axioms ordered_picks_eq_unordered_picks_mul_factorial
#print axioms picks_of_k_eq_picks_of_n_sub_k
