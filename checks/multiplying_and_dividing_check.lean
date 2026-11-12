-- Multiplying and dividing: any whole-number pile shared by one or more people splits into exactly one share and one leftover smaller than the number sharing, repeated adding gives the same total whichever way the block is turned, and no number of zeros adds up to a pile that is not empty.
import Mathlib.Basic.ExistsUnique
import Mathlib.Algebra.BigOperators.Group.List.Basic
import Mathlib.Tactic.NormNum

/-- The division theorem, as the card states it: for any pile of whole things shared by one or
more people, exactly one share-and-leftover pair fits, that is the pile is the number sharing
times the share, plus the leftover, with the leftover under the number sharing. -/
theorem share_and_leftover_exists_unique (pile sharers : ℕ) (h : 0 < sharers) :
    ∃! p : ℕ × ℕ, pile = sharers * p.1 + p.2 ∧ p.2 < sharers := by
  refine ⟨(pile / sharers, pile % sharers), ⟨(Nat.div_add_mod pile sharers).symm, Nat.mod_lt _ h⟩, ?_⟩
  rintro ⟨q, r⟩ ⟨h1, h2⟩
  simp only at h1 h2
  have hr : r = pile % sharers := by
    rw [h1, Nat.mul_add_mod]
    exact (Nat.mod_eq_of_lt h2).symm
  have hq : q = pile / sharers := by
    rw [h1, Nat.mul_add_div h, Nat.div_eq_of_lt h2]
    simp
  rw [hq, hr]

/-- Order does not matter when you multiply: a block of dots counts the same whichever way it is
turned, so adding `size` to itself `count` times gives the same total as adding `count` to itself
`size` times (twelve lots of 75 is 75 lots of twelve). -/
theorem repeated_adding_order_does_not_matter (count size : ℕ) :
    (List.replicate count size).sum = (List.replicate size count).sum := by
  rw [List.sum_replicate, List.sum_replicate]
  simp [mul_comm]

/-- Dividing by zero has no answer: for a pile that is not empty, no number of zeros adds up to
it; and for an empty pile every number of zeros fits, so there is no single answer either. -/
theorem dividing_by_zero_has_no_answer :
    (∀ pile : ℕ, pile ≠ 0 → ∀ q : ℕ, (List.replicate q 0).sum ≠ pile) ∧
      ∀ q : ℕ, (List.replicate q 0).sum = 0 := by
  have h0 : ∀ q : ℕ, (List.replicate q 0).sum = 0 := by
    intro q
    simp [List.sum_replicate]
  exact ⟨fun pile hp q => by rw [h0 q]; exact fun h => hp h.symm, h0⟩

-- Twelve apples at 75 cents: 900 cents, and adding 75 twelve times gives the same 900.
example : 12 * 75 = 900 := by norm_num
example : (List.replicate 12 75).sum = 900 := by decide
-- Turned a quarter turn: 75 lots of twelve is also 900.
example : (List.replicate 75 12).sum = 900 := by decide
-- A $10 bill is 1000 cents; the change is 100 cents.
example : 1000 - 12 * 75 = 100 := by norm_num
-- Twelve apples shared by four friends: three each, nothing over.
example : 12 / 4 = 3 ∧ 12 % 4 = 0 := by norm_num
-- 900 cents shared by four: 225 each, nothing over, and four lots of 225 rebuild the 900.
example : 900 / 4 = 225 ∧ 900 % 4 = 0 := by norm_num
example : 4 * 225 = 900 := by norm_num
example : (List.replicate 4 225).sum = 900 := by decide
-- Fourteen apples shared by four: three each and two over, so 14 = 4 × 3 + 2.
example : 14 / 4 = 3 ∧ 14 % 4 = 2 := by norm_num
example : 14 = 4 * 3 + 2 := by norm_num
-- Dropping the remainder: three each out of fourteen accounts for only twelve.
example : 4 * 3 = 12 := by norm_num
-- No number of zeros under 100 adds up to 12.
example : ∀ q, q < 100 → (List.replicate q 0).sum ≠ 12 := by decide

#print axioms share_and_leftover_exists_unique
#print axioms repeated_adding_order_does_not_matter
#print axioms dividing_by_zero_has_no_answer
