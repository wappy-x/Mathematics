-- Ordered picks: the ways to fill k different places from a pool of n things, with nothing used twice, number n(n-1)...(n-k+1) = n!/(n-k)!, which is n times the picks of k-1 from n-1 and also (n choose k) times k!.
import Mathlib.Data.Fintype.CardEmbedding
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Factorial.BigOperators
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum

open Finset

/-- Helper: injective maps from Places to Pool number Pool's size falling-factorial Places's size. -/
theorem ordered_picks_card_eq_descFactorial {Places Pool : Type*} [Fintype Places] [Fintype Pool]
    [DecidableEq Places] [DecidableEq Pool] :
    Fintype.card {f : Places → Pool // Function.Injective f} =
      (Fintype.card Pool).descFactorial (Fintype.card Places) := by
  rw [Fintype.card_congr (Equiv.subtypeInjectiveEquivEmbedding Places Pool)]
  exact Fintype.card_embedding_eq

/-- Ordered picks. Fill k places that differ, in order, from a pool of n things that can be told
apart, using no thing twice, with at most as many places as things. Such a pick is a one-to-one
map from the places into the pool, and the number of them is the falling product
n(n-1)(n-2)...(n-k+1), k factors, which is also n! divided by (n-k)!. -/
theorem ordered_picks_count {Places Pool : Type*} [Fintype Places] [Fintype Pool]
    [DecidableEq Places] [DecidableEq Pool]
    (h : Fintype.card Places ≤ Fintype.card Pool) :
    Fintype.card {f : Places → Pool // Function.Injective f} =
        ∏ i ∈ range (Fintype.card Places), (Fintype.card Pool - i) ∧
      Fintype.card {f : Places → Pool // Function.Injective f} =
        (Fintype.card Pool).factorial / (Fintype.card Pool - Fintype.card Places).factorial := by
  rw [ordered_picks_card_eq_descFactorial]
  exact ⟨Nat.descFactorial_eq_prod_range _ _, Nat.descFactorial_eq_div h⟩

/-- One place filled, then a smaller pick: P(n,k) = n × P(n-1,k-1). The first place goes n ways,
and the k-1 places left draw on a pool of n-1. -/
theorem ordered_picks_first_place_then_smaller_pick (n k : ℕ) (hk : 1 ≤ k) :
    ∏ i ∈ range k, (n - i) = n * ∏ i ∈ range (k - 1), (n - 1 - i) := by
  obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
  rw [Nat.add_sub_cancel, prod_range_succ']
  simp only [Nat.sub_zero, Nat.sub_sub, Nat.add_comm 1]
  ring

/-- The other road: pick which k things are used (n choose k ways), then put them in order
(k! ways). So the ordered picks number (n choose k) × k!. -/
theorem ordered_picks_eq_choose_mul_factorial {Places Pool : Type*} [Fintype Places] [Fintype Pool]
    [DecidableEq Places] [DecidableEq Pool]
    (h : Fintype.card Places ≤ Fintype.card Pool) :
    Fintype.card {f : Places → Pool // Function.Injective f} =
      (Fintype.card Pool).choose (Fintype.card Places) * (Fintype.card Places).factorial := by
  rw [ordered_picks_card_eq_descFactorial, Nat.descFactorial_eq_factorial_mul_choose, Nat.mul_comm]

-- The picture: three runners A, B, C, two medals in order: 3 × 2 = 6 lists.
example : Fintype.card {f : Fin 2 → Fin 3 // Function.Injective f} = 6 := by decide
example : ∏ i ∈ range 2, (3 - i) = 6 := by decide
-- Eight runners, three medals: 8 × 7 × 6 = 336.
example : (8 : ℕ) * 7 * 6 = 336 := by norm_num
example : ∏ i ∈ range 3, (8 - i) = 336 := by decide
-- By factorials: 8! = 40,320, 5! = 120, and 40,320 ÷ 120 = 336.
example : Nat.factorial 8 = 40320 ∧ Nat.factorial 5 = 120 ∧ Nat.factorial 8 / Nat.factorial 5 = 336 := by
  decide
-- The last factor: 8 − 3 + 1 = 6.
example : (8 : ℕ) - 3 + 1 = 6 := by norm_num
-- Repeats allowed: 8 × 8 × 8 = 512. Order forgotten: 336 ÷ 6 = 56 = (8 choose 3), and 56 × 3! = 336.
example : (8 : ℕ) ^ 3 = 512 := by norm_num
example : Nat.choose 8 3 = 56 ∧ 336 / Nat.factorial 3 = 56 ∧ 56 * Nat.factorial 3 = 336 := by decide
-- The wrong division: 8! ÷ 3! = 6,720, not 336.
example : Nat.factorial 8 / Nat.factorial 3 = 6720 := by decide
-- The penalty takers: 20, 380, 6,840, 116,280, 1,860,480.
example : (20 : ℕ) * 19 = 380 ∧ 380 * 18 = 6840 ∧ 6840 * 17 = 116280 ∧ 116280 * 16 = 1860480 := by
  norm_num
example : ∏ i ∈ range 5, (20 - i) = 1860480 := by decide
example : Nat.factorial 20 / Nat.factorial 15 = 1860480 := by decide
example : 20 * ∏ i ∈ range 4, (19 - i) = 1860480 := by decide
-- If a player could shoot twice: 20^5 = 3,200,000.
example : (20 : ℕ) ^ 5 = 3200000 := by norm_num

#print axioms ordered_picks_card_eq_descFactorial
#print axioms ordered_picks_count
#print axioms ordered_picks_first_place_then_smaller_pick
#print axioms ordered_picks_eq_choose_mul_factorial
