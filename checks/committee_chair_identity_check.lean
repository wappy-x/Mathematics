-- Committee and chair: for every n at least 1, k C(n, k) = n C(n - 1, k - 1) across the whole row (with C(n - 1, -1) = 0), the weighted row sum k C(n, k) over k = 0..n is n 2^(n - 1), and the committee-and-chair pairs of n people number n 2^(n - 1), with the card's office-of-ten and front-room numbers checked.
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum

open Finset

/-- The absorption identity. For any whole number `n` at least 1 and any committee size `k`,
committees of size `k` times the `k` members each may promote equals the `n` possible chairs
times the ways to fill the `k − 1` seats left from the other `n − 1` people:
`k · C(n, k) = n · C(n − 1, k − 1)`. A count of something impossible is zero, so at `k = 0`
the right-hand choice count `C(n − 1, −1)` is `0`; Lean's subtraction stops at `0`, so that
convention is written out as the `if`. -/
theorem absorption_identity (n k : ℕ) (hn : 1 ≤ n) :
    k * n.choose k = n * (if k = 0 then 0 else (n - 1).choose (k - 1)) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  rcases k with _ | j
  · simp
  · have h := Nat.add_one_mul_choose_eq m j
    simp only [Nat.add_one_ne_zero, ite_false, Nat.add_sub_cancel]
    rw [h, mul_comm]

/-- The weighted row sum. For any whole number `n` at least 1, multiplying each entry
`C(n, k)` of row `n` by its size `k` and adding across every size `k = 0, 1, …, n`
gives `n · 2^(n − 1)`. -/
theorem weighted_row_sum (n : ℕ) (hn : 1 ≤ n) :
    ∑ k ∈ range (n + 1), k * n.choose k = n * 2 ^ (n - 1) := by
  exact Nat.sum_range_mul_choose n

/-- Committee-and-chair pairs. In an office of `n` people (`n` at least 1), the pairs made of
a committee (any set of the people, of any size) and one of its own members as chair number
`n · 2^(n − 1)`. -/
theorem committee_chair_pairs_card (n : ℕ) (hn : 1 ≤ n) :
    (univ.filter (fun p : Finset (Fin n) × Fin n => p.2 ∈ p.1)).card = n * 2 ^ (n - 1) := by
  rw [card_filter, ← univ_product_univ, sum_product]
  have h1 : ∀ S : Finset (Fin n), (∑ x : Fin n, if x ∈ S then 1 else 0) = S.card := by
    intro S
    rw [← card_filter, filter_mem_eq_inter, univ_inter]
  simp only [h1]
  have h2 := Finset.sum_powerset_apply_card (fun m => m) (x := (univ : Finset (Fin n)))
  rw [powerset_univ] at h2
  rw [h2, card_univ, Fintype.card_fin, ← Nat.sum_range_mul_choose n]
  refine sum_congr rfl fun k _ => ?_
  simp [mul_comm]

-- The office of ten: row 10 of the triangle, and it adds to 1,024.
example : (List.range 11).map (Nat.choose 10) = [1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1] := by
  decide
example : ∑ k ∈ range 11, Nat.choose 10 k = 1024 := by decide
-- The size-3 term both ways: 3 × 120 = 360 = 10 × C(9, 2) = 10 × 36.
example : Nat.choose 10 3 = 120 ∧ 3 * 120 = 360 := by decide
example : Nat.choose 9 2 = 36 ∧ 10 * 36 = 360 := by decide
-- All eleven terms, committee first and chair first, and their total.
example : (List.range 11).map (fun k => k * Nat.choose 10 k)
    = [0, 10, 90, 360, 840, 1260, 1260, 840, 360, 90, 10] := by decide
example : (List.range 11).map (fun k => if k = 0 then 0 else 10 * Nat.choose 9 (k - 1))
    = [0, 10, 90, 360, 840, 1260, 1260, 840, 360, 90, 10] := by decide
example : ∑ k ∈ range 11, k * Nat.choose 10 k = 5120 := by decide
example : 10 * 2 ^ 9 = 5120 ∧ 10 * 512 = 5120 ∧ 512 * 10 = 5120 := by decide
-- The average committee seats five: 5,120 over 1,024.
example : 5120 / 1024 = 5 ∧ 5120 = 5 * 1024 := by decide
-- The mistakes: a chair from the whole office, and the shifted index at size 3.
example : 10 * 1024 = 10240 := by decide
example : 10 * Nat.choose 9 3 = 840 := by decide
-- The front room of four: 4 + 12 + 12 + 4 = 32 = 4 × 2^3, listed and counted.
example : 4 + 12 + 12 + 4 = 32 ∧ 4 * 2 ^ 3 = 32 := by decide
example : (univ.filter (fun p : Finset (Fin 4) × Fin 4 => p.2 ∈ p.1)).card = 32 := by
  decide +kernel
example : (List.range 5).map (fun k =>
    (univ.filter (fun p : Finset (Fin 4) × Fin 4 => p.2 ∈ p.1 ∧ p.1.card = k)).card)
    = [0, 4, 12, 12, 4] := by
  decide +kernel

#print axioms absorption_identity
#print axioms weighted_row_sum
#print axioms committee_chair_pairs_card
