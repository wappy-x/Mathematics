-- Induction: at a party of n people, n at least 1, where every pair shakes hands once, the handshakes number n × (n − 1) ÷ 2, proved from a base case and a step.
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Fintype.Fin
import Mathlib.Data.Fintype.Powerset
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-! The people at a party of `n` are `Fin n`. Every pair shakes hands once, so a handshake
is a two-person set `{a, b}` with `a ≠ b`: one handshake for each unordered pair, never
counted from both ends. The handshakes are `(univ : Finset (Fin n)).powersetCard 2`. -/

/-- The handshake count: at a party of `n` people, where every pair shakes hands once,
there are `n × (n − 1) ÷ 2` handshakes. The proof covers 1 person and every size after it. -/
theorem handshakes_eq_n_times_n_sub_one_div_two (n : ℕ) (hn : 1 ≤ n) :
    ((univ : Finset (Fin n)).powersetCard 2).card = n * (n - 1) / 2 := by
  rw [Finset.card_powersetCard, Finset.card_univ, Fintype.card_fin, Nat.choose_two_right]

/-- Proof by induction from a base case of 1: if a claim holds at 1, and holding at any
size `k` (from 1 on) hands it to `k + 1`, then it holds at every size from 1 on. -/
theorem induction_from_one (P : ℕ → Prop) (base : P 1)
    (step : ∀ k, 1 ≤ k → P k → P (k + 1)) :
    ∀ n, 1 ≤ n → P n := by
  intro n hn
  induction n, hn using Nat.le_induction with
  | base => exact base
  | succ k hk ih => exact step k hk ih

/-- The induction step at the door: a party of `k` with `k × (k − 1) ÷ 2` handshakes,
plus a new guest who shakes all `k` hands, gives the claim at `k + 1`,
namely `(k + 1) × ((k + 1) − 1) ÷ 2`. -/
theorem handshake_step (k : ℕ) :
    k * (k - 1) / 2 + k = (k + 1) * ((k + 1) - 1) / 2 := by
  rw [← Nat.add_mul_div_right _ _ (by norm_num : 0 < 2)]
  congr 1
  cases k with
  | zero => simp
  | succ m => simp only [Nat.add_sub_cancel]; ring

/-! The card's worked numbers. -/

-- The base case: a party of one has 0 handshakes, and 1 × 0 ÷ 2 = 0.
example : ((univ : Finset (Fin 1)).powersetCard 2).card = 0 := by decide
example : 1 * (1 - 1) / 2 = 0 := by norm_num
-- The chart: 2 people shake 1, 3 shake 3, 4 shake 6.
example : ((univ : Finset (Fin 2)).powersetCard 2).card = 1 := by decide
example : ((univ : Finset (Fin 3)).powersetCard 2).card = 3 := by decide
example : ((univ : Finset (Fin 4)).powersetCard 2).card = 6 := by decide
-- The party filling up: 0 + 1 + 2 = 3, 3 + 3 + 4 = 10, 10 + 5 + 6 = 21, 21 + 7 = 28.
example : 0 + 1 + 2 = 3 := by norm_num
example : 3 + 3 + 4 = 10 := by norm_num
example : 10 + 5 + 6 = 21 := by norm_num
example : 21 + 7 = 28 := by norm_num
-- Five people: 10. Seven people: 21. Eight friends: 8 × 7 ÷ 2 = 28.
example : ((univ : Finset (Fin 5)).powersetCard 2).card = 10 := by decide
example : 7 * (7 - 1) / 2 = 21 := by norm_num
example : 8 * (8 - 1) / 2 = 28 := by norm_num
-- Every pair at a party of eight, listed and counted: 28.
example : ((univ : Finset (Fin 8)).powersetCard 2).card = 28 := by decide
-- The mistakes: a spare 1 added gives 29; counting from both ends gives 8 × 7 = 56;
-- "never more than 28" fails at 9 people, with 9 × 8 ÷ 2 = 36.
example : 8 * (8 - 1) / 2 + 1 = 29 := by norm_num
example : 8 * 7 = 56 := by norm_num
example : 9 * (9 - 1) / 2 = 36 := by norm_num
example : ¬ (((univ : Finset (Fin 9)).powersetCard 2).card ≤ 28) := by decide
-- The spare 1 fails the base case: 1 × 0 ÷ 2 + 1 = 1, not 0.
example : 1 * (1 - 1) / 2 + 1 ≠ 0 := by norm_num

#print axioms handshakes_eq_n_times_n_sub_one_div_two
#print axioms induction_from_one
#print axioms handshake_step
