-- Barcode check digits: weighting the digits 1, 3, 1, 3 from the left, exactly one last digit puts an EAN-13's total on a multiple of 10, every single wrong digit is then caught, and a swap of neighbours slips through only when the two digits are equal or 5 apart.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Logic.Equiv.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Ring

open Finset

/-- The EAN weight of the digit in position `i`, counting from 0 at the left: 1, 3, 1, 3, ... -/
def eanWeight (i : ℕ) : ℕ := if i % 2 = 0 then 1 else 3

/-- The weighted sum of a row of digits: each digit times its weight, added up. -/
def eanTotal {n : ℕ} (c : Fin n → ℕ) : ℕ := ∑ i, eanWeight i.val * c i

/-- Helper: the total of thirteen digits written out term by term. -/
theorem eanTotal13 (f : Fin 13 → ℕ) : eanTotal f = f 0 + 3 * f 1 + f 2 + 3 * f 3 + f 4 + 3 * f 5 + f 6
    + 3 * f 7 + f 8 + 3 * f 9 + f 10 + 3 * f 11 + f 12 := by
  unfold eanTotal
  simp [Fin.sum_univ_succ, eanWeight]
  omega

#print axioms eanTotal13

/-- The check digit. Take any twelve digits and put a digit `d` from 0 to 9 after them. The
total of all thirteen lands on a multiple of 10 exactly when `d` is how far short of the next
multiple of 10 the twelve landed: 10 minus their remainder, or 0 if there is no remainder. So
there is one and only one check digit that works. -/
theorem check_digit_is_unique_and_lands_on_multiple_of_ten (x : Fin 12 → ℕ) (d : ℕ)
    (hd : d < 10) :
    10 ∣ eanTotal (Fin.snoc (α := fun _ => ℕ) x d) ↔ d = (10 - eanTotal x % 10) % 10 := by
  have h : eanTotal (Fin.snoc (α := fun _ => ℕ) x d) = eanTotal x + d := by
    unfold eanTotal
    rw [Fin.sum_univ_castSucc]
    have : Fin.snoc (α := fun _ => ℕ) x d (12 : Fin 13) = d := Fin.snoc_last _ _
    simp [eanWeight, this]
  rw [h]
  omega

/-- One wrong digit can never hide. Start from a good code: thirteen digits from 0 to 9 whose
total is a multiple of 10. Change one digit to a different digit from 0 to 9. The new total is
not a multiple of 10, so the scanner refuses it. -/
theorem one_wrong_digit_is_always_caught (c : Fin 13 → ℕ) (hc : ∀ i, c i < 10)
    (hvalid : 10 ∣ eanTotal c) (j : Fin 13) (d : ℕ) (hd : d < 10) (hne : d ≠ c j) :
    ¬ 10 ∣ eanTotal (Function.update c j d) := by
  have h0 := hc 0; have h1 := hc 1; have h2 := hc 2; have h3 := hc 3; have h4 := hc 4
  have h5 := hc 5; have h6 := hc 6; have h7 := hc 7; have h8 := hc 8; have h9 := hc 9
  have h10 := hc 10; have h11 := hc 11; have h12 := hc 12
  rw [eanTotal13] at hvalid ⊢
  fin_cases j <;> simp [Function.update] at hne ⊢ <;> omega

/-- The swap hole. Start from a good code of thirteen digits from 0 to 9 and swap two neighbours.
The swapped code still lands on a multiple of 10 exactly when the two digits are equal or 5
apart. -/
theorem swapped_neighbours_pass_iff_equal_or_five_apart (c : Fin 13 → ℕ) (hc : ∀ i, c i < 10)
    (hvalid : 10 ∣ eanTotal c) (i : Fin 12) :
    10 ∣ eanTotal (c ∘ Equiv.swap i.castSucc i.succ) ↔
      (c i.castSucc = c i.succ ∨ c i.castSucc + 5 = c i.succ ∨ c i.succ + 5 = c i.castSucc) := by
  have h0 := hc 0; have h1 := hc 1; have h2 := hc 2; have h3 := hc 3; have h4 := hc 4
  have h5 := hc 5; have h6 := hc 6; have h7 := hc 7; have h8 := hc 8; have h9 := hc 9
  have h10 := hc 10; have h11 := hc 11; have h12 := hc 12
  rw [eanTotal13] at hvalid ⊢
  fin_cases i <;> simp [Equiv.swap_apply_def] <;> omega

-- The card's barcode 5901234123457: the twelve weigh in at 83, the check digit is 7, all thirteen make 90.
example : eanTotal ![5, 9, 0, 1, 2, 3, 4, 1, 2, 3, 4, 5] = 83 := by decide
example : (10 - 83 % 10) % 10 = 7 ∧ 90 - 83 = 7 := by decide
example : eanTotal ![5, 9, 0, 1, 2, 3, 4, 1, 2, 3, 4, 5, 7] = 90 := by decide
-- One digit mistyped, 5901834123457: 96, refused.
example : eanTotal ![5, 9, 0, 1, 8, 3, 4, 1, 2, 3, 4, 5, 7] = 96 ∧ ¬ 10 ∣ 96 := by decide
-- The 9 and the 0 swapped, 5091234123457: 72, refused.
example : eanTotal ![5, 0, 9, 1, 2, 3, 4, 1, 2, 3, 4, 5, 7] = 72 ∧ ¬ 10 ∣ 72 := by decide
-- A 0 and a 5 side by side, 5905234123455: 100, valid. Swapped, 5950234123455: 90, still passes.
example : eanTotal ![5, 9, 0, 5, 2, 3, 4, 1, 2, 3, 4, 5, 5] = 100 := by decide
example : eanTotal ![5, 9, 5, 0, 2, 3, 4, 1, 2, 3, 4, 5, 5] = 90 := by decide
-- Try changing: the 9 made a 4 drops the total by 15, from 90 to 75.
example : eanTotal ![5, 4, 0, 1, 2, 3, 4, 1, 2, 3, 4, 5, 7] = 75 := by decide
-- Flattened weights: the twelve digits add to 39, and the check digit would be 1.
example : [5, 9, 0, 1, 2, 3, 4, 1, 2, 3, 4, 5].sum = 39 ∧ (10 - 39 % 10) % 10 = 1 := by decide
-- Luhn's fold: double 7 for 14, then 1 + 4 = 5.
example : 2 * 7 = 14 ∧ 14 / 10 + 14 % 10 = 5 := by decide

#print axioms check_digit_is_unique_and_lands_on_multiple_of_ten
#print axioms one_wrong_digit_is_always_caught
#print axioms swapped_neighbours_pass_iff_equal_or_five_apart
