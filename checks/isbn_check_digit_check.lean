-- ISBN-10 and the prime modulus 11: with weights 10 down to 1 and digits from 0 to 10, a swap shifts the total by the weight gap times the digit gap, so every swap of two different digits and every single wrong digit moves the total to a new remainder on 11.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Logic.Equiv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Data.Int.ModEq

open Finset

/-- The ISBN-10 weighted total: the digit in position `i`, counting from 0 at the left, is
multiplied by its weight `10 - i` (so 10, 9, ..., 1), and the products are added. -/
def isbnTotal (d : Fin 10 → ℕ) : ℕ := ∑ i : Fin 10, (10 - i.val) * d i

theorem isbn_aux_swap_shift (d : Fin 10 → ℕ) (i j : Fin 10) :
    (isbnTotal (d ∘ Equiv.swap i j) : ℤ) - isbnTotal d =
      ((10 - ((i : ℕ) : ℤ)) - (10 - ((j : ℕ) : ℤ))) * ((d j : ℤ) - d i) := by
  by_cases hij : i = j
  · subst hij
    simp
  have hw : ∀ k : Fin 10, ((10 - k.val : ℕ) : ℤ) = 10 - (k.val : ℤ) := fun k => by
    have := k.2
    omega
  have e : (isbnTotal (d ∘ Equiv.swap i j) : ℤ) - isbnTotal d =
      ∑ k : Fin 10, (10 - (k.val : ℤ)) * ((d (Equiv.swap i j k) : ℤ) - d k) := by
    unfold isbnTotal
    simp only [Nat.cast_sum, Nat.cast_mul, hw, Function.comp, ← Finset.sum_sub_distrib]
    apply Finset.sum_congr rfl
    intro k _
    ring
  rw [e, Finset.sum_eq_add i j hij]
  · simp [Equiv.swap_apply_left, Equiv.swap_apply_right]
    ring
  · intro c _ hc
    rw [Equiv.swap_apply_of_ne_of_ne hc.1 hc.2]
    simp
  · intro h
    exact absurd (Finset.mem_univ i) h
  · intro h
    exact absurd (Finset.mem_univ j) h

#print axioms isbn_aux_swap_shift

/-- Every swap is caught. Take ten digits, each from 0 to 10 (X counts as 10), and trade the
digits in two places that hold different digits. The weighted total moves to a new remainder
on 11, so a code that passed before is rejected after the swap. -/
theorem swap_of_two_different_digits_is_always_caught (d : Fin 10 → ℕ) (hd : ∀ k, d k ≤ 10)
    (i j : Fin 10) (hij : d i ≠ d j) :
    isbnTotal (d ∘ Equiv.swap i j) % 11 ≠ isbnTotal d % 11 := by
  have h := isbn_aux_swap_shift d i j
  have hne : (i : ℕ) ≠ j := by
    intro h'
    have : i = j := Fin.ext h'
    exact hij (by rw [this])
  have hi := i.2
  have hj := j.2
  have hdi := hd i
  have hdj := hd j
  have hdn : (d j : ℤ) - d i ≠ 0 := by omega
  intro hmod
  have hdiv : (11 : ℤ) ∣ ((isbnTotal (d ∘ Equiv.swap i j) : ℤ) - isbnTotal d) := by
    omega
  rw [h] at hdiv
  obtain ⟨k, hk⟩ := hdiv
  have hb1 : ((d j : ℤ) - d i) ≤ 10 := by omega
  have hb2 : ((d j : ℤ) - d i) ≥ -10 := by omega
  generalize hb : ((d j : ℤ) - d i) = b at *
  have ha1 : ((10 - ((i : ℕ) : ℤ)) - (10 - ((j : ℕ) : ℤ))) ≤ 9 := by omega
  have ha2 : ((10 - ((i : ℕ) : ℤ)) - (10 - ((j : ℕ) : ℤ))) ≥ -9 := by omega
  have ha3 : ((10 - ((i : ℕ) : ℤ)) - (10 - ((j : ℕ) : ℤ))) ≠ 0 := by omega
  generalize ((10 - ((i : ℕ) : ℤ)) - (10 - ((j : ℕ) : ℤ))) = a at *
  interval_cases a <;> omega

/-- A swap disturbs only the two places it touches: the total shifts by the gap between the two
weights times the gap between the two digits. -/
theorem swap_shifts_total_by_weight_gap_times_digit_gap (d : Fin 10 → ℕ) (i j : Fin 10) :
    (isbnTotal (d ∘ Equiv.swap i j) : ℤ) - isbnTotal d =
      ((10 - ((i : ℕ) : ℤ)) - (10 - ((j : ℕ) : ℤ))) * ((d j : ℤ) - d i) := by
  exact isbn_aux_swap_shift d i j

/-- One wrong digit is caught. Take ten digits, each from 0 to 10, and change the digit in one
place to a different digit from 0 to 10. The weighted total moves to a new remainder on 11. -/
theorem one_wrong_digit_is_always_caught (d : Fin 10 → ℕ) (hd : ∀ k, d k ≤ 10) (j : Fin 10)
    (a : ℕ) (ha : a ≤ 10) (hne : a ≠ d j) :
    isbnTotal (Function.update d j a) % 11 ≠ isbnTotal d % 11 := by
  have key : (isbnTotal (Function.update d j a) : ℤ) - isbnTotal d =
      (10 - ((j : ℕ) : ℤ)) * ((a : ℤ) - d j) := by
    fin_cases j <;>
      simp [isbnTotal, Fin.sum_univ_succ, Function.update_apply] <;> ring
  intro hmod
  have hdiv : (11 : ℤ) ∣ ((isbnTotal (Function.update d j a) : ℤ) - isbnTotal d) := by
    omega
  rw [key] at hdiv
  have hj := j.2
  have hdj := hd j
  have hne' : (a : ℤ) ≠ d j := by exact_mod_cast hne
  obtain ⟨k, hk⟩ := hdiv
  have hw1 : 0 < 10 - ((j : ℕ) : ℤ) := by omega
  have hw2 : 10 - ((j : ℕ) : ℤ) ≤ 10 := by omega
  generalize hw : (10 - ((j : ℕ) : ℤ)) = w at *
  interval_cases w <;> omega

-- The card's ISBN 0-306-40615-2: the weighted total is 132 = 12 x 11, so it passes.
example : isbnTotal ![0, 3, 0, 6, 4, 0, 6, 1, 5, 2] = 132 ∧ 132 = 12 * 11 := by decide
-- Second road: the running totals 0, 3, 3, 9, 13, 13, 19, 20, 25, 27 also add to 132.
example : [0, 3, 3, 9, 13, 13, 19, 20, 25, 27].sum = 132 := by decide
-- The first nine alone: 130 = 11 x 11 + 9, so the check digit is 11 - 9 = 2.
example : isbnTotal ![0, 3, 0, 6, 4, 0, 6, 1, 5, 0] = 130 ∧ 130 = 11 * 11 + 9 ∧
    (11 - 130 % 11) % 11 = 2 := by decide
-- The 1 and the 5 traded, 0-306-40651-2: 136 = 12 x 11 + 4, rejected; the shift is (3 - 2) x (5 - 1) = 4.
example : isbnTotal ![0, 3, 0, 6, 4, 0, 6, 5, 1, 2] = 136 ∧ 136 % 11 = 4 ∧
    136 - 132 = (3 - 2) * (5 - 1) := by decide
-- On a clock of 10, a weight gap of 2 and a digit gap of 5 move the total by 10, which leaves 0.
example : 2 * 5 = 10 ∧ 10 % 10 = 0 := by decide
-- What breaks if you drop a piece: the digits alone add to 27, 132 leaves 2 on 10, and 130 leaves 9 on 11.
example : [0, 3, 0, 6, 4, 0, 6, 1, 5, 2].sum = 27 ∧ 132 % 10 = 2 ∧ 130 % 11 = 9 := by decide
-- Try changing: a last digit of 3 makes the total 133, one past a multiple of 11.
example : isbnTotal ![0, 3, 0, 6, 4, 0, 6, 1, 5, 3] = 133 ∧ 133 % 11 = 1 := by decide

#print axioms swap_of_two_different_digits_is_always_caught
#print axioms swap_shifts_total_by_weight_gap_times_digit_gap
#print axioms one_wrong_digit_is_always_caught
