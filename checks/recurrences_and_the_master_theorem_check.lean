-- Recurrences: the merge sort rule T(n) = T(⌊n/2⌋) + T(⌈n/2⌉) + (n − 1), T(1) = 0, totals exactly n·k − 2^k + 1 with k = ⌈log₂ n⌉, and the two shapes outside the master theorem total n(n − 1)/2 and n·k(k + 1)/2.
import Mathlib.Data.Nat.Log
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith

/-- Helper: the closed form holds for any exponent j with n ≤ 2^j ≤ 2n. -/
theorem merge_sort_closed_form_aux (T : ℕ → ℕ) (h1 : T 1 = 0)
    (hrec : ∀ n, 2 ≤ n → T n = T (n / 2) + T (n - n / 2) + (n - 1)) :
    ∀ n : ℕ, 1 ≤ n → ∀ j : ℕ, n ≤ 2 ^ j → 2 ^ j ≤ 2 * n →
      (T n : ℤ) = (n : ℤ) * (j : ℤ) - (2 : ℤ) ^ j + 1 := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro hn j hj1 hj2
    rcases Nat.lt_or_ge n 2 with h | h
    · have hn1 : n = 1 := by omega
      subst hn1
      rcases j with _ | _ | j
      · simp [h1]
      · simp [h1]
      · exfalso
        have : 2 ^ (j + 2) = 4 * 2 ^ j := by ring
        have : 1 ≤ 2 ^ j := Nat.one_le_two_pow
        omega
    · rcases j with _ | i
      · simp at hj1; omega
      have hp : 2 ^ (i + 1) = 2 * 2 ^ i := by ring
      have hab : n / 2 + (n - n / 2) = n := by omega
      have hcond : n / 2 ≤ 2 ^ i ∧ 2 ^ i ≤ 2 * (n / 2) ∧
          n - n / 2 ≤ 2 ^ i ∧ 2 ^ i ≤ 2 * (n - n / 2) := by
        rcases i with _ | i
        · simp at *; omega
        · have : 2 ^ (i + 1) = 2 * 2 ^ i := by ring
          omega
      have ha := ih (n / 2) (by omega) (by omega) i hcond.1 hcond.2.1
      have hb := ih (n - n / 2) (by omega) (by omega) i hcond.2.2.1 hcond.2.2.2
      rw [hrec n h]
      have habz : ((n / 2 : ℕ) : ℤ) + ((n - n / 2 : ℕ) : ℤ) = (n : ℤ) := by exact_mod_cast hab
      have hn1z : ((n - 1 : ℕ) : ℤ) = (n : ℤ) - 1 := by omega
      have : (2 : ℤ) ^ (i + 1) = 2 * 2 ^ i := by ring
      rw [Nat.cast_add, Nat.cast_add, hn1z, ha, hb, this, Nat.cast_add, Nat.cast_one]
      linear_combination (↑i : ℤ) * habz

#print axioms merge_sort_closed_form_aux

/-- Merge sort's worst case, solved exactly. If a cost satisfies the rule read off the code,
T(n) = T(⌊n/2⌋) + T(⌈n/2⌉) + (n − 1) for n ≥ 2 with T(1) = 0, then for every n ≥ 1
the total is n·k − 2^k + 1, where k = ⌈log₂ n⌉ is the number of depths in the call tree.
(⌈n/2⌉ is written n − ⌊n/2⌋; the closed form is stated over the integers so nothing is cut off.) -/
theorem merge_sort_worst_case_closed_form (T : ℕ → ℕ) (h1 : T 1 = 0)
    (hrec : ∀ n, 2 ≤ n → T n = T (n / 2) + T (n - n / 2) + (n - 1)) :
    ∀ n, 1 ≤ n → (T n : ℤ) = n * Nat.clog 2 n - 2 ^ Nat.clog 2 n + 1 := by
  intro n hn
  apply merge_sort_closed_form_aux T h1 hrec n hn
  · exact Nat.le_pow_clog (by norm_num) n
  · rcases Nat.lt_or_ge n 2 with h | h
    · have : n = 1 := by omega
      subst this
      simp
    · have hlt := Nat.pow_pred_clog_lt_self (b := 2) (by norm_num) (x := n) (by omega)
      have hpos := Nat.clog_pos (b := 2) (n := n) (by norm_num) (by omega)
      obtain ⟨c, hc⟩ : ∃ c, Nat.clog 2 n = c + 1 := ⟨Nat.clog 2 n - 1, by omega⟩
      rw [hc] at hlt ⊢
      simp only [Nat.pred_succ] at hlt
      have : 2 ^ (c + 1) = 2 * 2 ^ c := by ring
      omega

/-- Subtract one, not divide: quicksort with the first track as pivot on a sorted playlist.
If T(n) = T(n − 1) + (n − 1) for n ≥ 2 with T(1) = 0, then T(n) = n(n − 1)/2 for every n ≥ 1. -/
theorem subtract_one_rule_total (T : ℕ → ℕ) (h1 : T 1 = 0)
    (hrec : ∀ n, 2 ≤ n → T n = T (n - 1) + (n - 1)) :
    ∀ n, 1 ≤ n → T n = n * (n - 1) / 2 := by
  have key : ∀ m, T (m + 1) * 2 = (m + 1) * m := by
    intro m
    induction m with
    | zero => simp [h1]
    | succ m ih =>
      have h := hrec (m + 2) (by omega)
      simp only [show m + 2 - 1 = m + 1 by omega] at h
      rw [show m + 1 + 1 = m + 2 by omega, h, add_mul, ih]
      ring
  intro n hn
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  rw [show m + 1 - 1 = m by omega, ← key m, Nat.mul_div_cancel _ (by norm_num)]

/-- Outside work of n log n: if T(n) = 2T(n/2) + n·log₂ n on sizes n = 2^k, with T(1) = 0,
then T(n) = n·k(k + 1)/2, which grows like n log² n, not n log n. -/
theorem n_log_n_work_total (T : ℕ → ℕ) (h1 : T 1 = 0)
    (hrec : ∀ k, T (2 ^ (k + 1)) = 2 * T (2 ^ k) + 2 ^ (k + 1) * (k + 1)) :
    ∀ k, T (2 ^ k) = 2 ^ k * k * (k + 1) / 2 := by
  have key : ∀ k, 2 * T (2 ^ k) = 2 ^ k * k * (k + 1) := by
    intro k
    induction k with
    | zero => simp [h1]
    | succ k ih =>
      calc 2 * T (2 ^ (k + 1)) = 2 * (2 * T (2 ^ k)) + 2 * (2 ^ (k + 1) * (k + 1)) := by
            rw [hrec]; ring
        _ = 2 * (2 ^ k * k * (k + 1)) + 2 * (2 ^ (k + 1) * (k + 1)) := by rw [ih]
        _ = 2 ^ (k + 1) * (k + 1 : ℕ) * (k + 1 + 1) := by ring
  intro k
  rw [← key k, Nat.mul_div_cancel_left _ (by norm_num)]

-- The card's worked numbers.
-- 1,000,000 tracks take k = 20 depths.
example : Nat.clog 2 1000000 = 20 := by decide
-- Depth 0 costs 999,999 and depth 19 costs 1,000,000 − 2^19 = 475,712.
example : 1000000 - 2 ^ 0 = 999999 := by norm_num
example : 1000000 - 2 ^ 19 = 475712 := by norm_num
-- The ceiling, what the depths give back, and the worst case.
example : 20 * 1000000 = 20000000 := by norm_num
example : 2 ^ 20 - 1 = 1048575 := by norm_num
example : (1000000 * 20 - 2 ^ 20 + 1 : ℤ) = 18951425 := by norm_num
-- At N = 2^20 the worst case becomes 19,922,945.
example : (2 ^ 20 * 20 - 2 ^ 20 + 1 : ℤ) = 19922945 := by norm_num
-- Comparing every pair of 1,000,000 tracks; the sorted-playlist quicksort on 1,000 tracks.
example : 1000000 * (1000000 - 1) / 2 = 499999500000 := by norm_num
example : 1000 * (1000 - 1) / 2 = 499500 := by norm_num
-- Karatsuba's middle term from one product, on the card's 4-digit numbers 3141 and 2718.
example : (31 * 18 + 41 * 27 : ℤ) = (31 - 41) * (18 - 27) + 31 * 27 + 41 * 18 := by norm_num
example : (3141592653589793 : ℕ) * 2718281828459045 = 8539734222673565677848730527685 := by norm_num
-- Karatsuba at 1,024 digits against the schoolbook and the n log n misreading.
example : 3 ^ 10 = 59049 ∧ 1024 ^ 2 = 1048576 ∧ 1024 * 10 = 10240 := by norm_num
-- Karatsuba's counts at 4, 8 and 16 digits.
example : 3 ^ 2 = 9 ∧ 3 ^ 3 = 27 ∧ 3 ^ 4 = 81 := by norm_num
-- Strassen at 1,024 by 1,024: seven block products against eight.
example : 7 ^ 10 = 282475249 ∧ 8 ^ 10 = 1073741824 := by norm_num
-- Outside work of n log n at 2^20 items, against the n log n misreading.
example : 2 ^ 20 * 20 * (20 + 1) / 2 = 220200960 := by norm_num
example : 2 ^ 20 * 20 = 20971520 := by norm_num

#print axioms merge_sort_worst_case_closed_form
#print axioms subtract_one_rule_total
#print axioms n_log_n_work_total
