-- Order of operations: splitting the change and splitting the bill add back up to splitting the note when the change divides evenly, multiplying is repeated adding, dividing is multiplying by the reciprocal, and the card's worked numbers come out as it says.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Ring.Int
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum

/-- The money lands twice: if the change (cash minus bill) splits evenly between the friends,
then each friend's share of the bill plus each friend's share of the change is exactly
the cash split the same number of ways. Amounts are whole cents. -/
theorem split_bill_add_split_change_eq_split_cash (cash bill friends : ℤ)
    (h : friends ∣ cash - bill) :
    bill / friends + (cash - bill) / friends = cash / friends := by
  obtain ⟨k, hk⟩ := h
  have hc : cash = bill + friends * k := by omega
  by_cases hf : friends = 0
  · subst hf
    simp
  · have h1 : (cash - bill) / friends = k := by
      rw [hk]; exact Int.mul_ediv_cancel_left k hf
    rw [h1, hc, Int.add_mul_ediv_left bill k hf]

/-- Multiplying is shorthand for adding: `n × a` is `a` written out `n` times and added up. -/
theorem mul_eq_repeated_add (n : ℕ) (a : ℤ) :
    (n : ℤ) * a = ∑ _i ∈ Finset.range n, a := by
  simp

/-- Multiply and divide share a rung: dividing by `b` is the same as multiplying by `1 / b`. -/
theorem div_eq_mul_one_div_rung (a b : ℚ) : a / b = a * (1 / b) := by
  rw [mul_one_div]

-- The card's worked numbers, in whole cents (Lean reads these lines with the same rungs).
example : 12 * 75 = 900 := by decide
example : 1000 - 900 = 100 := by decide
example : 100 / 4 = 25 := by decide
example : (1000 - 12 * 75) / 4 = 25 := by decide
example : 1000 - 12 * 75 / 4 = 775 := by decide
example : 1000 - 12 * 75 = 100 := by decide
example : 12 * 75 / 4 = 225 := by decide
example : 12 * 75 / 4 + (1000 - 12 * 75) / 4 = 1000 / 4 := by decide
example : 1000 / 4 = 250 := by decide
example : 8 / 2 * 4 = 16 := by decide
example : 8 / (2 * 4) = 1 := by decide
example : (1000 - 12 * 75) / 5 = 20 := by decide
example : (1000 - 12 * 80) / 4 = 10 := by decide

#print axioms split_bill_add_split_change_eq_split_cash
#print axioms mul_eq_repeated_add
#print axioms div_eq_mul_one_div_rung
