-- Place value: every whole number that fits in a given number of columns has exactly one way to be written with one digit 0 to 9 per column, biggest column first, each column worth ten times the one on its right, and the digits are the remainders from dividing by ten over and over.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Nat.Digits.Lemmas
import Mathlib.Tactic.NormNum

open Finset

/-- Helper: split off the last column (the ones). -/
theorem pv_sum_succ (k : ℕ) (d : Fin (k + 1) → Fin 10) :
    ∑ i : Fin (k + 1), (d i : ℕ) * 10 ^ (k + 1 - 1 - (i : ℕ)) =
      10 * ∑ i : Fin k, (d i.castSucc : ℕ) * 10 ^ (k - 1 - (i : ℕ)) + (d (Fin.last k) : ℕ) := by
  rw [Fin.sum_univ_castSucc, Finset.mul_sum]
  congr 1
  · refine Finset.sum_congr rfl fun i _ => ?_
    have hi := i.isLt
    have : k + 1 - 1 - (i : ℕ) = (k - 1 - (i : ℕ)) + 1 := by omega
    simp only [Fin.val_castSucc, this, pow_succ]
    ring
  · simp

#print axioms pv_sum_succ

/-- Place value, as the card states it: write a number in `k` columns, every column written
(an empty one gets a 0), one digit 0 to 9 in each, the biggest column first, and each column
worth ten times the one on its right (so the column in position `i` from the left is worth
`10 ^ (k - 1 - i)`). Then a digit's worth is the digit times its column's worth, and every
whole number that fits in those `k` columns has exactly one such numeral: the rule never gives
one number two numerals, or one numeral two meanings. -/
theorem place_value_numeral_exists_unique (k n : ℕ) (hn : n < 10 ^ k) :
    ∃! d : Fin k → Fin 10, ∑ i : Fin k, (d i : ℕ) * 10 ^ (k - 1 - (i : ℕ)) = n := by
  induction k generalizing n with
  | zero =>
    have hn0 : n = 0 := by simpa using hn
    subst hn0
    refine ⟨Fin.elim0, by simp, fun d _ => ?_⟩
    funext i; exact i.elim0
  | succ k ih =>
    have hn' : n / 10 < 10 ^ k := by
      rw [pow_succ] at hn; omega
    obtain ⟨d', hd', huniq⟩ := ih (n / 10) hn'
    refine ⟨Fin.snoc d' ⟨n % 10, by omega⟩, ?_, ?_⟩
    · beta_reduce
      rw [pv_sum_succ]
      simp only [Fin.snoc_castSucc, Fin.snoc_last]
      rw [hd']
      omega
    · intro e he
      rw [pv_sum_succ] at he
      have hlt := (e (Fin.last k)).isLt
      have hlast : (e (Fin.last k) : ℕ) = n % 10 := by omega
      have hrest : ∑ i : Fin k, (e i.castSucc : ℕ) * 10 ^ (k - 1 - (i : ℕ)) = n / 10 := by omega
      have := huniq (fun i => e i.castSucc) hrest
      funext i
      refine Fin.lastCases ?_ (fun j => ?_) i
      · simp only [Fin.snoc_last]; exact Fin.ext hlast
      · simp only [Fin.snoc_castSucc]; exact congrFun this j

/-- The picture: a column is always worth more than everything to its right can hold, even
with every column there filled with 9s. All 9s in the `k` columns right of a column add up to
exactly one less than that column's worth, `10 ^ k` (9999 still loses to 10000). -/
theorem column_beats_all_nines_to_its_right (k : ℕ) :
    ∑ i ∈ range k, 9 * 10 ^ i + 1 = 10 ^ k := by
  induction k with
  | zero => simp
  | succ k ih => rw [Finset.sum_range_succ, pow_succ]; omega

/-- Writing a quantity down: divide by ten over and over, keeping the remainder. The remainder
after `j` divisions, `n / 10 ^ j % 10`, is the digit in column `j` counting from the right
(0 is the ones), and putting each remainder back times its column's worth gives the number
again, for every number that fits in `k` columns. -/
theorem remainders_from_dividing_by_ten_rebuild_the_number (k n : ℕ) (hn : n < 10 ^ k) :
    ∑ j ∈ range k, (n / 10 ^ j % 10) * 10 ^ j = n := by
  induction k generalizing n with
  | zero => simp at hn; simp [hn]
  | succ k ih =>
    rw [Finset.sum_range_succ']
    have hn' : n / 10 < 10 ^ k := by rw [pow_succ] at hn; omega
    have h := ih (n / 10) hn'
    have e : ∀ j, n / 10 ^ (j + 1) % 10 * 10 ^ (j + 1) = 10 * (n / 10 / 10 ^ j % 10 * 10 ^ j) := by
      intro j
      rw [Nat.div_div_eq_div_mul, pow_succ, mul_comm (10 ^ j) 10]
      ring
    rw [Finset.sum_congr rfl (fun j _ => e j), ← Finset.mul_sum, h]
    simp only [pow_zero, Nat.div_one, mul_one]
    omega

-- The formula: 523 is five hundreds, two tens and three ones.
example : 5 * 100 + 2 * 10 + 3 * 1 = 523 := by norm_num
-- The same, as the main theorem reads a three-column numeral.
example : ∑ i : Fin 3, ((![5, 2, 3] : Fin 3 → Fin 10) i : ℕ) * 10 ^ (3 - 1 - (i : ℕ)) = 523 := by
  decide
-- An empty column is still written with a 0: 900.
example : 9 * 100 + 0 * 10 + 0 * 1 = 900 := by norm_num
example : ∑ i : Fin 3, ((![9, 0, 0] : Fin 3 → Fin 10) i : ℕ) * 10 ^ (3 - 1 - (i : ℕ)) = 900 := by
  decide
-- The apple stall, in cents.
example : 12 * 75 = 900 := by norm_num
example : 10 * 100 = 1000 := by norm_num
example : 1000 - 900 = 100 := by norm_num
example : 900 / 4 = 225 ∧ 900 % 4 = 0 := by norm_num
example : 225 * 4 = 900 := by norm_num
example : 2 * 100 + 2 * 10 + 5 * 1 = 225 := by norm_num
-- What one column is worth, against all 9s to its right.
example : (10 ^ 4 : ℕ) = 10000 ∧ ∑ i ∈ range 4, 9 * 10 ^ i = 9999 := by decide
-- Bundling backwards: 523 ÷ 10 = 52 r 3, 52 ÷ 10 = 5 r 2, 5 ÷ 10 = 0 r 5.
example : 523 / 10 = 52 ∧ 523 % 10 = 3 := by norm_num
example : 52 / 10 = 5 ∧ 52 % 10 = 2 := by norm_num
example : 5 / 10 = 0 ∧ 5 % 10 = 5 := by norm_num
-- Mathlib's own digit list (ones first) reads the remainders 3, 2, 5, and reads back as 523.
example : Nat.digits 10 523 = [3, 2, 5] := by norm_num
example : Nat.ofDigits 10 [3, 2, 5] = 523 := by norm_num [Nat.ofDigits]
-- What breaks: one zero dropped from 900 gives 90; read right to left 523 gives 325;
-- adding the digits gives 10.
example : 9 * 10 + 0 * 1 = 90 := by norm_num
example : 3 * 100 + 2 * 10 + 5 * 1 = 325 := by norm_num
example : 5 + 2 + 3 = 10 := by norm_num

#print axioms place_value_numeral_exists_unique
#print axioms column_beats_all_nines_to_its_right
#print axioms remainders_from_dividing_by_ten_rebuild_the_number
