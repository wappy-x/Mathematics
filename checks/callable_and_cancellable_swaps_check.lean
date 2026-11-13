-- Callable and cancellable swaps: on any binomial rate tree, the swap with an exit rolled back as one contract equals the plain swap plus (holder's exit) or minus (bank's exit) the Bermudan swaption struck at the swap's own rate, and the floating leg telescopes to one dollar now minus one dollar at the end.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

open Finset

/-! ## Setting

A binomial rate tree with `n` yearly steps. `R i j` is the one-year rate set at year `i`
at the node with `j` up-moves so far; from node `(i, j)` the tree moves to `(i+1, j)` or
`(i+1, j+1)`, each with pricing weight one half, and the same rate both projects the
floating payment and discounts it (one curve). `N` is the notional, `K` the fixed rate,
`S` the listed cancel years.

* `M i j`: the remaining swap to the fixed payer, payments `i+1 .. n`, valued at `(i, j)`.
* `B i j`: the receiver Bermudan swaption struck at `K`: on a listed year, the larger of the
  cancel saving `(-M)⁺` and the wait value; otherwise the wait value.
* `P i j`: the payer Bermudan swaption struck at `K`: reward `M⁺`.
* `V i j`: the callable swap rolled back as one contract, the fixed payer free to stop on a
  listed year (floored at zero there, no fee).
* `U i j`: the swap cancellable by the bank, rolled back as one contract (capped at zero
  on a listed year). -/

/-- **Callable swap = plain swap + receiver Bermudan swaption.** On any binomial rate tree
whose one-year rates stay above −100%, the swap the fixed payer may cancel on the listed
years, with no fee, rolled back as one contract, is worth at every node exactly the
remaining plain swap plus the receiver Bermudan swaption struck at the swap's own rate `K`
and exercised by the best rule (the rollback's max). In particular today:
`V_callable = V_swap + B_R`. -/
theorem callable_swap_eq_swap_add_receiver_bermudan
    (n : ℕ) (N K : ℝ) (S : Finset ℕ) (R M B V : ℕ → ℕ → ℝ)
    (hR : ∀ i < n, ∀ j, -1 < R i j)
    (hM_end : ∀ j, M n j = 0)
    (hM : ∀ i < n, ∀ j,
      M i j = (N * (R i j - K) + (M (i + 1) j + M (i + 1) (j + 1)) / 2) / (1 + R i j))
    (hB_end : ∀ j, B n j = 0)
    (hB : ∀ i < n, ∀ j,
      B i j = if i ∈ S then
          max (max (-M i j) 0) ((B (i + 1) j + B (i + 1) (j + 1)) / 2 / (1 + R i j))
        else (B (i + 1) j + B (i + 1) (j + 1)) / 2 / (1 + R i j))
    (hV_end : ∀ j, V n j = 0)
    (hV : ∀ i < n, ∀ j,
      V i j = if i ∈ S then
          max ((N * (R i j - K) + (V (i + 1) j + V (i + 1) (j + 1)) / 2) / (1 + R i j)) 0
        else (N * (R i j - K) + (V (i + 1) j + V (i + 1) (j + 1)) / 2) / (1 + R i j)) :
    ∀ i ≤ n, ∀ j, V i j = M i j + B i j := by
  intro i hi j
  have key : ∀ k, k ≤ n → ∀ j, V (n - k) j = M (n - k) j + B (n - k) j ∧ 0 ≤ B (n - k) j := by
    intro k
    induction k with
    | zero => intro _ j; simp [hV_end, hM_end, hB_end]
    | succ k ih =>
      intro hk j
      obtain ⟨i, hi_eq⟩ : ∃ i, i = n - (k + 1) := ⟨_, rfl⟩
      rw [← hi_eq]
      have hin : i < n := by omega
      have hi1 : n - k = i + 1 := by omega
      obtain ⟨h1, h1b⟩ := ih (by omega) j
      obtain ⟨h2, h2b⟩ := ih (by omega) (j + 1)
      rw [hi1] at h1 h1b h2 h2b
      have hpos : 0 < 1 + R i j := by linarith [hR i hin j]
      have eM := hM i hin j
      have eB := hB i hin j
      have eV := hV i hin j
      have hw : 0 ≤ (B (i + 1) j + B (i + 1) (j + 1)) / 2 / (1 + R i j) := by positivity
      have hsum : (N * (R i j - K) + (V (i + 1) j + V (i + 1) (j + 1)) / 2) / (1 + R i j)
          = M i j + (B (i + 1) j + B (i + 1) (j + 1)) / 2 / (1 + R i j) := by
        rw [h1, h2, eM]; field_simp; ring
      rw [hsum] at eV
      split_ifs at eB eV
      · rw [eV, eB]
        refine ⟨?_, ?_⟩
        · rw [max_def, max_def, max_def]; split_ifs <;> linarith
        · exact le_trans (le_max_right _ _) (le_max_left _ _)
      · exact ⟨by rw [eV, eB], by rw [eB]; exact hw⟩
  have := (key (n - i) (by omega) j).1
  rwa [show n - (n - i) = i by omega] at this

/-- **Cancellable by the bank = plain swap − payer Bermudan swaption.** On the same tree,
the swap that the fixed receiver (the bank) may cancel on the listed years, with no fee,
rolled back as one contract, is worth to the fixed payer at every node exactly the remaining
plain swap minus the payer Bermudan swaption struck at `K`, exercised by the bank's best
rule. In particular today: `V_cancellable by bank = V_swap − B_P`. -/
theorem bank_cancellable_swap_eq_swap_sub_payer_bermudan
    (n : ℕ) (N K : ℝ) (S : Finset ℕ) (R M P U : ℕ → ℕ → ℝ)
    (hR : ∀ i < n, ∀ j, -1 < R i j)
    (hM_end : ∀ j, M n j = 0)
    (hM : ∀ i < n, ∀ j,
      M i j = (N * (R i j - K) + (M (i + 1) j + M (i + 1) (j + 1)) / 2) / (1 + R i j))
    (hP_end : ∀ j, P n j = 0)
    (hP : ∀ i < n, ∀ j,
      P i j = if i ∈ S then
          max (max (M i j) 0) ((P (i + 1) j + P (i + 1) (j + 1)) / 2 / (1 + R i j))
        else (P (i + 1) j + P (i + 1) (j + 1)) / 2 / (1 + R i j))
    (hU_end : ∀ j, U n j = 0)
    (hU : ∀ i < n, ∀ j,
      U i j = if i ∈ S then
          min ((N * (R i j - K) + (U (i + 1) j + U (i + 1) (j + 1)) / 2) / (1 + R i j)) 0
        else (N * (R i j - K) + (U (i + 1) j + U (i + 1) (j + 1)) / 2) / (1 + R i j)) :
    ∀ i ≤ n, ∀ j, U i j = M i j - P i j := by
  intro i hi j
  have key : ∀ k, k ≤ n → ∀ j, U (n - k) j = M (n - k) j - P (n - k) j ∧ 0 ≤ P (n - k) j := by
    intro k
    induction k with
    | zero => intro _ j; simp [hU_end, hM_end, hP_end]
    | succ k ih =>
      intro hk j
      obtain ⟨i, hi_eq⟩ : ∃ i, i = n - (k + 1) := ⟨_, rfl⟩
      rw [← hi_eq]
      have hin : i < n := by omega
      have hi1 : n - k = i + 1 := by omega
      obtain ⟨h1, h1b⟩ := ih (by omega) j
      obtain ⟨h2, h2b⟩ := ih (by omega) (j + 1)
      rw [hi1] at h1 h1b h2 h2b
      have hpos : 0 < 1 + R i j := by linarith [hR i hin j]
      have eM := hM i hin j
      have eP := hP i hin j
      have eU := hU i hin j
      have hw : 0 ≤ (P (i + 1) j + P (i + 1) (j + 1)) / 2 / (1 + R i j) := by positivity
      have hsum : (N * (R i j - K) + (U (i + 1) j + U (i + 1) (j + 1)) / 2) / (1 + R i j)
          = M i j - (P (i + 1) j + P (i + 1) (j + 1)) / 2 / (1 + R i j) := by
        rw [h1, h2, eM]; field_simp; ring
      rw [hsum] at eU
      split_ifs at eP eU
      · rw [eU, eP]
        refine ⟨?_, ?_⟩
        · rw [min_def, max_def, max_def]; split_ifs <;> linarith
        · exact le_trans (le_max_right _ _) (le_max_left _ _)
      · exact ⟨by rw [eU, eP], by rw [eP]; exact hw⟩
  have := (key (n - i) (by omega) j).1
  rwa [show n - (n - i) = i by omega] at this

/-- **The floating leg telescopes.** Along any path of one-year rates `r k` (with
`1 + r k ≠ 0`), write `d k = 1/(1 + r k)`. The floating payments `r k`, paid at year `k+1`
for `k = i, …, n-1` and discounted back to year `i`, add up to
`1 − d i · d (i+1) ⋯ d (n-1)`: a dollar now minus a dollar at year `n`. -/
theorem floating_leg_telescopes (r : ℕ → ℝ) (i n : ℕ) (hr : ∀ k, 1 + r k ≠ 0) (hin : i ≤ n) :
    ∑ k ∈ Ico i n, (∏ m ∈ Icc i k, (1 + r m)⁻¹) * r k = 1 - ∏ m ∈ Ico i n, (1 + r m)⁻¹ := by
  induction n, hin using Nat.le_induction with
  | base => simp
  | succ n hn ih =>
    rw [Finset.sum_Ico_succ_top hn, Finset.prod_Ico_succ_top hn, ih,
      ← Finset.Ico_add_one_right_eq_Icc, Finset.prod_Ico_succ_top hn]
    have h := hr n
    have : (1 + r n)⁻¹ * r n = 1 - (1 + r n)⁻¹ := by field_simp; ring
    rw [mul_assoc, this]; ring

/-! ## The card's worked numbers that are exact

Flat curve at 5% with yearly compounding, so `D(t) = (20/21)^t`. The plain swap paying
`K = 5%` on `N = $10,000,000` for ten years is worth `N [1 − D(10) − K A] = $0.00`, where
`A = D(1) + ⋯ + D(10)`: the floating leg `1 − D(10)` equals the fixed leg `K A`. -/

example :
    (10000000 : ℚ) * (1 - (20 / 21) ^ 10 - 1 / 20 * ∑ t ∈ range 10, (20 / 21 : ℚ) ^ (t + 1)) = 0 := by
  norm_num [Finset.sum_range_succ]

/-- The tree has `2 ^ 9 = 512` rate paths through year 9 (Road 3 on the card). -/
example : 2 ^ 9 = 512 := by decide

#print axioms callable_swap_eq_swap_add_receiver_bermudan
#print axioms bank_cancellable_swap_eq_swap_sub_payer_bermudan
#print axioms floating_leg_telescopes
