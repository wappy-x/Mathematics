-- Data structures: a binary heap of n items stored in an array is exactly ⌊log₂ n⌋ levels tall, chained hashing under an even spread costs 1 + (n-1)/(2m) comparisons per hit and n/m per miss, and the fewest items N(h) in an AVL tree of height h satisfy N(h) + 1 = F(h + 3).
import Mathlib.Data.Nat.Log
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Order.Interval.Finset.Fin
import Mathlib.Tactic

/-- The fewest items an AVL tree of height `h` can hold, by the card's recurrence:
`N(0) = 1`, `N(1) = 2`, `N(h) = N(h-1) + N(h-2) + 1` (a root, one subtree of height `h-1`
and the thinnest the balance rule allows, one of height `h-2`). -/
def avlMinSize : ℕ → ℕ
  | 0 => 1
  | 1 => 2
  | h + 2 => avlMinSize (h + 1) + avlMinSize h + 1

lemma heap_iter_add_one (k j : ℕ) :
    (fun j : ℕ => (j - 1) / 2)^[k] j + 1 = max ((j + 1) / 2 ^ k) 1 := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [Function.iterate_succ_apply', pow_succ, ← Nat.div_div_eq_div_mul]
    generalize (fun j : ℕ => (j - 1) / 2)^[k] j = y at ih ⊢
    generalize (j + 1) / 2 ^ k = q at ih ⊢
    omega

lemma heap_iter_eq_zero_iff (k j : ℕ) :
    (fun j : ℕ => (j - 1) / 2)^[k] j = 0 ↔ j + 1 < 2 ^ (k + 1) := by
  have h := heap_iter_add_one k j
  have h2 : (j + 1) / 2 ^ k < 2 ↔ j + 1 < 2 * 2 ^ k := Nat.div_lt_iff_lt_mul (by positivity)
  rw [pow_succ, mul_comm (2 ^ k)]
  omega

lemma card_filter_fun_eq (n m : ℕ) (i : Fin n) (F : ({k // k ≠ i} → Fin m) → Fin m) :
    (Finset.univ.filter fun h : Fin n → Fin m => h i = F (fun k => h k)).card = m ^ (n - 1) := by
  have : (Finset.univ.filter fun h : Fin n → Fin m => h i = F (fun k => h k)).card
      = (Finset.univ : Finset ({k // k ≠ i} → Fin m)).card := by
    refine Finset.card_nbij' (fun h k => h k)
      (fun r k => if hk : k = i then F r else r ⟨k, hk⟩) ?_ ?_ ?_ ?_
    · intro a _; simp
    · intro r _
      simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq, dite_true]
      congr 1
      funext k
      simp [k.2]
    · intro h hh
      simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hh
      funext k
      by_cases hk : k = i
      · subst hk; simp [hh]
      · simp [hk]
    · intro r _
      funext k
      simp [k.2]
  rw [this, Finset.card_univ, Fintype.card_fun, Fintype.card_subtype_compl]
  simp

lemma hash_hit_sum (n m : ℕ) (j : Fin n) :
    ∑ h : Fin n → Fin m, (Finset.univ.filter fun i : Fin n => i < j ∧ h i = h j).card
      = (j : ℕ) * m ^ (n - 1) := by
  simp_rw [Finset.card_filter]
  rw [Finset.sum_comm]
  have : ∀ i : Fin n, (∑ h : Fin n → Fin m, if i < j ∧ h i = h j then 1 else 0)
      = if i < j then m ^ (n - 1) else 0 := by
    intro i
    by_cases hij : i < j
    · have hne : j ≠ i := ne_of_gt hij
      simp only [hij, true_and, ite_true]
      rw [← Finset.card_filter]
      exact card_filter_fun_eq n m i (fun r => r ⟨j, hne⟩)
    · simp [hij]
  rw [Finset.sum_congr rfl (fun i _ => this i), ← Finset.sum_filter, Finset.sum_const,
    smul_eq_mul, Finset.filter_gt_eq_Iio, Fin.card_Iio]

lemma hash_miss_sum (n m : ℕ) (b : Fin m) :
    ∑ h : Fin n → Fin m, (Finset.univ.filter fun i : Fin n => h i = b).card
      = n * m ^ (n - 1) := by
  simp_rw [Finset.card_filter]
  rw [Finset.sum_comm]
  have : ∀ i : Fin n, (∑ h : Fin n → Fin m, if h i = b then 1 else 0) = m ^ (n - 1) := by
    intro i
    rw [← Finset.card_filter]
    exact card_filter_fun_eq n m i (fun _ => b)
  rw [Finset.sum_congr rfl (fun i _ => this i)]
  simp

lemma sum_fin_val_rat (n : ℕ) : ∑ j : Fin n, ((j : ℕ) : ℚ) = (n : ℚ) * ((n : ℚ) - 1) / 2 := by
  rw [Fin.sum_univ_eq_sum_range (fun j => (j : ℚ)), ← Nat.cast_sum]
  have h := Finset.sum_range_id_mul_two n
  rcases n with _ | n
  · simp
  · have h' : ((∑ i ∈ Finset.range (n + 1), i : ℕ) : ℚ) * 2 = ((n + 1 : ℕ) : ℚ) * (n : ℚ) := by
      exact_mod_cast h
    push_cast at h' ⊢
    linarith

#print axioms heap_iter_add_one
#print axioms heap_iter_eq_zero_iff
#print axioms card_filter_fun_eq
#print axioms hash_hit_sum
#print axioms hash_miss_sum
#print axioms sum_fin_val_rat

/-- A binary heap of `n ≥ 1` items lives in array positions `0, …, n-1`, and the parent of
position `i` is `⌊(i-1)/2⌋`. Its height is exactly `⌊log₂ n⌋`: every position reaches the root
in at most `⌊log₂ n⌋` parent steps, and the last position needs all of them. So sift-up and
sift-down walk at most `⌊log₂ n⌋` levels. -/
theorem heap_height_eq_floor_log2 (n : ℕ) (hn : 0 < n) :
    (∀ i < n, (fun j : ℕ => (j - 1) / 2)^[Nat.log 2 n] i = 0) ∧
    (∀ k < Nat.log 2 n, (fun j : ℕ => (j - 1) / 2)^[k] (n - 1) ≠ 0) := by
  constructor
  · intro i hi
    rw [heap_iter_eq_zero_iff]
    have := Nat.lt_pow_succ_log_self (by norm_num : 1 < 2) n
    omega
  · intro k hk
    rw [Ne, heap_iter_eq_zero_iff]
    have h1 := Nat.pow_log_le_self 2 (Nat.pos_iff_ne_zero.mp hn)
    have h2 : 2 ^ (k + 1) ≤ 2 ^ Nat.log 2 n := Nat.pow_le_pow_right (by norm_num) hk
    omega

/-- Chained hashing with `n` items in `m` buckets, each item landing in each bucket with chance
`1/m`, independently (every hash `Fin n → Fin m` equally likely). The `j`-th stored item sits
behind the earlier items in its bucket, so finding it costs one plus that count. Averaged over
items and hashes, a hit costs `1 + (n-1)/(2m)`; a miss in any bucket compares the whole chain,
`n/m` on average. -/
theorem chained_hash_expected_costs (n m : ℕ) (hn : 0 < n) (hm : 0 < m) :
    (∑ h : Fin n → Fin m, ∑ j : Fin n,
        (1 + ((Finset.univ.filter fun i : Fin n => i < j ∧ h i = h j).card : ℚ)))
        / ((Fintype.card (Fin n → Fin m) : ℚ) * n)
      = 1 + ((n : ℚ) - 1) / (2 * m) ∧
    ∀ b : Fin m,
      (∑ h : Fin n → Fin m, ((Finset.univ.filter fun i : Fin n => h i = b).card : ℚ))
          / (Fintype.card (Fin n → Fin m) : ℚ)
        = (n : ℚ) / m := by
  obtain ⟨k, rfl⟩ : ∃ k, n = k + 1 := ⟨n - 1, by omega⟩
  have hm' : (m : ℚ) ≠ 0 := by exact_mod_cast hm.ne'
  constructor
  · rw [Finset.sum_comm]
    simp only [Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, nsmul_eq_mul,
      mul_one]
    have hs : ∀ j : Fin (k + 1), ∑ h : Fin (k + 1) → Fin m,
        ((Finset.univ.filter fun i : Fin (k + 1) => i < j ∧ h i = h j).card : ℚ)
          = ((j : ℕ) : ℚ) * (m : ℚ) ^ k := by
      intro j
      rw [← Nat.cast_sum, hash_hit_sum]
      simp
    rw [Finset.sum_congr rfl (fun j _ => hs j), ← Finset.sum_mul, sum_fin_val_rat]
    simp only [Fintype.card_fun, Fintype.card_fin]
    push_cast
    field_simp
    ring
  · intro b
    rw [← Nat.cast_sum, hash_miss_sum]
    simp only [Fintype.card_fun, Fintype.card_fin]
    push_cast
    field_simp
    ring

/-- The fewest items an AVL tree of height `h` can hold, plus one, is the Fibonacci number
`F(h+3)` (with `F(1) = F(2) = 1`). -/
theorem avl_min_size_add_one_eq_fib (h : ℕ) : avlMinSize h + 1 = Nat.fib (h + 3) := by
  induction h using Nat.strong_induction_on with
  | _ h ih =>
    match h with
    | 0 => decide
    | 1 => decide
    | h + 2 =>
      rw [avlMinSize, show h + 2 + 3 = (h + 3) + 2 by ring, Nat.fib_add_two,
        show h + 3 + 1 = h + 1 + 3 by ring, ← ih (h + 1) (by omega), ← ih h (by omega)]
      ring


-- The card's worked numbers.
example : Nat.log 2 480 = 8 := by decide
example : (fun j : ℕ => (j - 1) / 2)^[8] 479 = 0 := by decide
example : (fun j : ℕ => (j - 1) / 2)^[7] 479 ≠ 0 := by decide
example : (3 - 1) / 2 = 1 ∧ (4 - 1) / 2 = 1 := by decide
example : Nat.log 2 60000 + 1 = 16 := by decide
example : 480 * 479 / 2 = 114960 := by norm_num
example : 960 * 959 / 2 = 460320 := by norm_num
example : 1011 + 6215 = 7226 := by norm_num
example : ∑ k ∈ Finset.Icc 1 480, Nat.log 2 k = 3338 := by decide +kernel
example : 2 * ∑ k ∈ Finset.Icc 1 479, Nat.log 2 k = 6660 := by decide +kernel
example : 480 * 479 / 4 = 57480 := by norm_num
example : (60000 : ℚ) / 80000 = 3 / 4 := by norm_num
example : (List.range 12).map avlMinSize = [1, 2, 4, 7, 12, 20, 33, 54, 88, 143, 232, 376] := by decide
example : avlMinSize 11 ≤ 480 ∧ 480 < avlMinSize 12 := by decide
example : avlMinSize 21 ≤ 60000 ∧ 60000 < avlMinSize 22 := by decide

#print axioms heap_height_eq_floor_log2
#print axioms chained_hash_expected_costs
#print axioms avl_min_size_add_one_eq_fib
