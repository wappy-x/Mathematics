-- Collatz: the conjecture is stated exactly and left open; the file proves Terras's fact that the first k odd-or-even outcomes of the shortcut map depend only on the remainder mod 2^k and determine it, that every start dropping below itself would give the conjecture, and the card's whole-number examples.
import Mathlib.Logic.Function.Iterate
import Mathlib.Basic.ExistsUnique
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.Order.Group.Nat
import Mathlib.Data.Int.Init
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Fintype.EquivFin
import Mathlib.Data.Fintype.BigOperators

/-- The Collatz map T(n): halve an even number; triple an odd number and add one. -/
def collatz (n : ℕ) : ℕ := if n % 2 = 0 then n / 2 else 3 * n + 1

/-- The shortcut map S(n): halve an even number; send an odd number to (3n + 1)/2. -/
def shortcut (n : ℕ) : ℕ := if n % 2 = 0 then n / 2 else (3 * n + 1) / 2

/-- The 3n - 1 rule from the card's "What breaks": halve an even number, otherwise 3n - 1. -/
def collatzMinus (n : ℕ) : ℕ := if n % 2 = 0 then n / 2 else 3 * n - 1

/-- The 3n + 1 rule on all integers, used on the card for negative starts. -/
def collatzInt (n : ℤ) : ℤ := if n % 2 = 0 then n / 2 else 3 * n + 1

/-- The Collatz conjecture (open as of 2026-11-23; the card does not prove it): every whole
number n ≥ 1 reaches 1 after finitely many steps of the Collatz map. -/
def CollatzConjecture : Prop := ∀ n : ℕ, 1 ≤ n → ∃ i : ℕ, collatz^[i] n = 1

theorem shortcut_mod_step (k n n' : ℕ) (h : n % 2 = n' % 2) :
    shortcut n % 2 ^ k = shortcut n' % 2 ^ k ↔ n / 2 % 2 ^ k = n' / 2 % 2 ^ k := by
  rcases Nat.mod_two_eq_zero_or_one n with h0 | h1
  · have h0' : n' % 2 = 0 := by omega
    have e1 : shortcut n = n / 2 := by simp [shortcut, h0]
    have e2 : shortcut n' = n' / 2 := by simp [shortcut, h0']
    rw [e1, e2]
  · have h1' : n' % 2 = 1 := by omega
    have e1 : shortcut n = 3 * (n / 2) + 2 := by simp [shortcut, h1]; omega
    have e2 : shortcut n' = 3 * (n' / 2) + 2 := by simp [shortcut, h1']; omega
    rw [e1, e2]
    have hc : Nat.gcd (2 ^ k) 3 = 1 := Nat.Coprime.pow_left k (by decide : Nat.Coprime 2 3)
    constructor
    · intro hm
      have hm' : 3 * (n / 2) + 2 ≡ 3 * (n' / 2) + 2 [MOD 2 ^ k] := hm
      exact Nat.ModEq.cancel_left_of_coprime hc (Nat.ModEq.add_right_cancel' 2 hm')
    · intro hm
      have hm' : n / 2 ≡ n' / 2 [MOD 2 ^ k] := hm
      exact (hm'.mul_left 3).add_right 2

#print axioms shortcut_mod_step

theorem collatz_pos (n : ℕ) (hn : 1 ≤ n) : 1 ≤ collatz n := by
  unfold collatz; split_ifs <;> omega

#print axioms collatz_pos

theorem collatz_iterate_pos (i n : ℕ) (hn : 1 ≤ n) : 1 ≤ collatz^[i] n := by
  induction i generalizing n with
  | zero => simpa
  | succ i ih => rw [Function.iterate_succ_apply]; exact ih _ (collatz_pos n hn)

#print axioms collatz_iterate_pos

/-- Terras 1976: the parity string is a one-to-one function of the remainder mod 2^k.
For any k, two whole numbers n and n' are odd or even alike at each of the first k steps of
the shortcut map (at n, S(n), ..., S^(k-1)(n)) exactly when they leave the same remainder
after division by 2^k. -/
theorem parity_string_eq_iff_mod_two_pow_eq (k n n' : ℕ) :
    (∀ i < k, shortcut^[i] n % 2 = shortcut^[i] n' % 2) ↔ n % 2 ^ k = n' % 2 ^ k := by
  induction k generalizing n n' with
  | zero => simp [Nat.mod_one]
  | succ k ih =>
    rw [Nat.forall_lt_succ_left]
    simp only [Function.iterate_zero_apply, Function.iterate_succ_apply]
    rw [ih, pow_succ', Nat.mod_mul, Nat.mod_mul]
    constructor
    · rintro ⟨h1, h2⟩
      rw [h1, (shortcut_mod_step k n n' h1).1 h2]
    · intro h
      have h1 : n % 2 = n' % 2 := by omega
      refine ⟨h1, (shortcut_mod_step k n n' h1).2 ?_⟩
      omega

/-- Every parity string occurs exactly once: for any k and any string b of k odd-or-even
outcomes (true for odd), exactly one remainder r below 2^k has b as its parity string under
the shortcut map. So each string has share exactly 1/2^k, the fair-coin share. -/
theorem every_parity_string_occurs_once (k : ℕ) (b : Fin k → Bool) :
    ∃! r : ℕ, r < 2 ^ k ∧ ∀ i : Fin k, (shortcut^[i] r % 2 = 1 ↔ b i = true) := by
  let f : Fin (2 ^ k) → (Fin k → Bool) := fun r i => decide (shortcut^[i] (r : ℕ) % 2 = 1)
  have key : ∀ r r' : ℕ, (∀ i : Fin k, (shortcut^[i] r % 2 = 1 ↔ shortcut^[i] r' % 2 = 1)) →
      r % 2 ^ k = r' % 2 ^ k := by
    intro r r' h
    rw [← parity_string_eq_iff_mod_two_pow_eq]
    intro i hi
    have := h ⟨i, hi⟩
    simp only at this
    omega
  have hinj : Function.Injective f := by
    intro r r' hrr
    apply Fin.ext
    have := key r r' (fun i => by
      have := congrFun hrr i
      simpa [f] using this)
    rwa [Nat.mod_eq_of_lt r.2, Nat.mod_eq_of_lt r'.2] at this
  have hbij : Function.Bijective f :=
    (Fintype.bijective_iff_injective_and_card f).2 ⟨hinj, by simp⟩
  obtain ⟨r, hr⟩ := hbij.2 b
  refine ⟨r, ⟨r.2, fun i => ?_⟩, ?_⟩
  · rw [← hr]; simp [f]
  · rintro y ⟨hy, hyb⟩
    have := key y r (fun i => by
      rw [hyb i, ← hr]; simp [f])
    rwa [Nat.mod_eq_of_lt hy, Nat.mod_eq_of_lt r.2] at this

/-- Why dropping below the start would be enough (Step 3): if every start n ≥ 2 eventually
falls below n under the Collatz map, then strong induction gives the Collatz conjecture. -/
theorem collatz_conjecture_of_every_start_drops
    (hdrop : ∀ n : ℕ, 2 ≤ n → ∃ i : ℕ, collatz^[i] n < n) : CollatzConjecture := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro hn
    rcases Nat.lt_or_ge n 2 with h | h
    · exact ⟨0, by simp; omega⟩
    · obtain ⟨i, hi⟩ := hdrop n h
      obtain ⟨j, hj⟩ := ih _ hi (collatz_iterate_pos i n hn)
      exact ⟨j + i, by rw [Function.iterate_add_apply, hj]⟩

-- The first two steps from 27: 3 × 27 + 1 = 82, then 82 ÷ 2 = 41.
example : collatz 27 = 82 ∧ collatz 82 = 41 := by decide +kernel
-- 27 reaches 1 after 111 steps, not before.
example : collatz^[111] 27 = 1 ∧ ∀ i < 111, collatz^[i] 27 ≠ 1 := by decide +kernel
-- Its walk peaks at 9,232, reached at step 77.
example : collatz^[77] 27 = 9232 ∧ ∀ i ≤ 111, collatz^[i] 27 ≤ 9232 := by decide +kernel
-- 41 of the 111 steps are odd steps, so 70 are halvings.
example : ((List.range 111).filter fun i => collatz^[i] 27 % 2 = 1).length = 41 := by decide +kernel
-- Stopping time σ(27) = 96: the walk first drops below 27 at step 96, landing on 23.
example : collatz^[96] 27 = 23 ∧ ∀ i < 96, 27 ≤ collatz^[i] 27 := by decide +kernel
-- Under the shortcut map 27 takes 70 steps to reach 1, which is 111 − 41.
example : shortcut^[70] 27 = 1 ∧ ∀ i < 70, shortcut^[i] 27 ≠ 1 := by decide +kernel
-- The check line: 27 × ∏ (3n_i + 1) = 2^70 × ∏ n_i over the 41 odd values n_i of the walk.
example : 27 * (((List.range 111).map fun i => collatz^[i] 27).filter (· % 2 = 1)
      |>.map (3 * · + 1)).prod =
    2 ^ 70 * (((List.range 111).map fun i => collatz^[i] 27).filter (· % 2 = 1)).prod := by
  decide +kernel
-- Every start from 2 to 26 reaches 1 within 23 steps; 25 takes exactly 23.
example : ∀ n ∈ Finset.Icc 2 26, ∃ i ≤ 23, collatz^[i] n = 1 := by decide +kernel
example : collatz^[23] 25 = 1 ∧ ∀ i < 23, collatz^[i] 25 ≠ 1 := by decide +kernel
-- 28 takes 18 steps and peaks at 52.
example : collatz^[18] 28 = 1 ∧ (∀ i < 18, collatz^[i] 28 ≠ 1) ∧
    (∀ i ≤ 18, collatz^[i] 28 ≤ 52) ∧ ∃ i ≤ 18, collatz^[i] 28 = 52 := by decide +kernel
-- 97 takes 118 steps and peaks at 9,232.
example : collatz^[118] 97 = 1 ∧ (∀ i < 118, collatz^[i] 97 ≠ 1) ∧
    (∀ i ≤ 118, collatz^[i] 97 ≤ 9232) ∧ ∃ i ≤ 118, collatz^[i] 97 = 9232 := by decide +kernel
-- 871 takes 178 steps and peaks at 190,996.
example : collatz^[178] 871 = 1 ∧ (∀ i < 178, collatz^[i] 871 ≠ 1) ∧
    (∀ i ≤ 178, collatz^[i] 871 ≤ 190996) ∧ ∃ i ≤ 178, collatz^[i] 871 = 190996 := by decide +kernel
-- The parity strings for k = 3, remainder by remainder:
-- 0:000 1:101 2:010 3:110 4:001 5:100 6:011 7:111.
example : (List.range 8).map (fun r => (List.range 3).map fun i => shortcut^[i] r % 2) =
    [[0, 0, 0], [1, 0, 1], [0, 1, 0], [1, 1, 0], [0, 0, 1], [1, 0, 0], [0, 1, 1],
      [1, 1, 1]] := by decide +kernel
-- With 3n - 1 the start 5 loops: 5, 14, 7, 20, 10, 5.
example : (List.range 6).map (fun i => collatzMinus^[i] 5) = [5, 14, 7, 20, 10, 5] := by
  decide +kernel
-- With 3n - 1 the start 17 returns to itself after 18 steps, not before, peaking at 272.
example : collatzMinus^[18] 17 = 17 ∧ (∀ i, 1 ≤ i → i < 18 → collatzMinus^[i] 17 ≠ 17) ∧
    (∀ i ≤ 18, collatzMinus^[i] 17 ≤ 272) ∧ ∃ i ≤ 18, collatzMinus^[i] 17 = 272 := by decide +kernel
-- On negative numbers 3n + 1 has the cycle -5, -14, -7, -20, -10, -5.
example : (List.range 6).map (fun i => collatzInt^[i] (-5)) = [-5, -14, -7, -20, -10, -5] := by
  decide +kernel
-- The published bound: 2^71 = 2,361,183,241,434,822,606,848.
example : 2 ^ 71 = 2361183241434822606848 := by decide +kernel

#print axioms parity_string_eq_iff_mod_two_pow_eq
#print axioms every_parity_string_occurs_once
#print axioms collatz_conjecture_of_every_start_drops
