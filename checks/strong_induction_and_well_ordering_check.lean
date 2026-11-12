-- Strong induction and the least element: every amount of 8 cents or more can be paid exactly with 3-cent and 5-cent stamps, the only amounts that can never be paid are 1, 2, 4 and 7, and every non-empty set of counting numbers has a smallest member.
import Mathlib.Data.Set.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- With only 3-cent and 5-cent stamps, every amount of 8 cents or more can be paid exactly:
for every whole number `n ≥ 8` there are counts `a` of 3-cent stamps and `b` of 5-cent stamps
with `n = 3a + 5b`. -/
theorem every_amount_from_eight_payable_with_three_and_five (n : ℕ) (h : 8 ≤ n) :
    ∃ a b : ℕ, n = 3 * a + 5 * b := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    by_cases h8 : n = 8
    · exact ⟨1, 1, by omega⟩
    by_cases h9 : n = 9
    · exact ⟨3, 0, by omega⟩
    by_cases h10 : n = 10
    · exact ⟨0, 2, by omega⟩
    obtain ⟨a, b, hab⟩ := ih (n - 3) (by omega) (by omega)
    exact ⟨a + 1, b, by omega⟩

/-- The well-ordering principle: every non-empty collection of counting numbers has a smallest
member. -/
theorem well_ordering_principle (S : Set ℕ) (hS : S.Nonempty) :
    ∃ m ∈ S, ∀ k ∈ S, m ≤ k := by
  classical
  exact ⟨Nat.find hS, Nat.find_spec hS, fun k hk => Nat.find_min' hS hk⟩

/-- The amounts that can never be paid with 3-cent and 5-cent stamps are exactly 1, 2, 4 and 7:
an amount `n` is `3a + 5b` for some counts `a`, `b` exactly when `n` is not one of those four. -/
theorem payable_iff_not_one_two_four_seven (n : ℕ) :
    (∃ a b : ℕ, n = 3 * a + 5 * b) ↔ n ∉ ({1, 2, 4, 7} : Finset ℕ) := by
  constructor
  · rintro ⟨a, b, h⟩ hm
    simp only [Finset.mem_insert, Finset.mem_singleton] at hm
    omega
  · intro hn
    simp only [Finset.mem_insert, Finset.mem_singleton] at hn
    by_cases h8 : 8 ≤ n
    · exact every_amount_from_eight_payable_with_three_and_five n h8
    · have : n = 0 ∨ n = 3 ∨ n = 5 ∨ n = 6 := by omega
      rcases this with h | h | h | h
      · exact ⟨0, 0, by omega⟩
      · exact ⟨1, 0, by omega⟩
      · exact ⟨0, 1, by omega⟩
      · exact ⟨2, 0, by omega⟩

-- The base cases, paid by hand: 8 = 3 + 5, 9 = 3 + 3 + 3, 10 = 5 + 5.
example : (8 : ℕ) = 3 * 1 + 5 * 1 := by norm_num
example : (9 : ℕ) = 3 * 3 + 5 * 0 := by norm_num
example : (10 : ℕ) = 3 * 0 + 5 * 2 := by norm_num
-- The strong step: 11 = 8 + 3, 12 = 9 + 3, 13 = 10 + 3.
example : (11 : ℕ) = 8 + 3 := by norm_num
example : (12 : ℕ) = 9 + 3 := by norm_num
example : (13 : ℕ) = 10 + 3 := by norm_num
-- 7 cents cannot be paid: no counts of 3s and 5s add up to 7.
example : ¬ ∃ a b : ℕ, 7 = 3 * a + 5 * b := by rintro ⟨a, b, h⟩; omega
-- Never payable at all: 1, 2, 4 and 7, four of them.
example : ({1, 2, 4, 7} : Finset ℕ).card = 4 := by decide
-- One base case, 8 alone: the step lands on 11, 14, 17, never 9.
example : ∀ k : ℕ, 8 + 3 * k ≠ 9 := by intro k; omega

#print axioms every_amount_from_eight_payable_with_three_and_five
#print axioms well_ordering_principle
#print axioms payable_iff_not_one_two_four_seven
