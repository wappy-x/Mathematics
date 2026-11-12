-- Inclusion-exclusion: for any finite groups, the number in at least one is the group sizes added, minus every shared-by-two count, plus the shared-by-all-three count, and the card's class of 30 gives 23, 7, 28 and 2.
import Mathlib.Data.Finset.Card
import Mathlib.Data.Int.Basic
import Mathlib.Tactic.NormNum

/-- Three groups: for any three finite groups F, C and H, the number of people in at least
one group is the three sizes added, minus the three shared-by-two counts, plus the count
shared by all three. Singles in, pairs out, triple in. -/
theorem card_union_three {α : Type*} [DecidableEq α] (F C H : Finset α) :
    ((F ∪ C ∪ H).card : ℤ)
      = F.card + C.card + H.card - (F ∩ C).card - (F ∩ H).card - (C ∩ H).card
        + (F ∩ C ∩ H).card := by
  have h1 := Finset.card_union_add_card_inter (F ∪ C) H
  have h2 := Finset.card_union_add_card_inter F C
  have h3 := Finset.card_union_add_card_inter (F ∩ H) (C ∩ H)
  have e1 : (F ∪ C) ∩ H = (F ∩ H) ∪ (C ∩ H) := Finset.union_inter_distrib_right F C H
  have e2 : (F ∩ H) ∩ (C ∩ H) = F ∩ C ∩ H := by
    ext x; simp only [Finset.mem_inter]; tauto
  rw [e1] at h1
  rw [e2] at h3
  omega

/-- Two groups: for any two finite groups F and C, the number in at least one is the two
sizes added, minus the number in both, so the overlap is counted once, not twice. -/
theorem card_union_two {α : Type*} [DecidableEq α] (F C : Finset α) :
    ((F ∪ C).card : ℤ) = F.card + C.card - (F ∩ C).card := by
  have := Finset.card_union_add_card_inter F C
  omega

/-- None of the three: when every group sits inside the class U, the number in the class
who are in none of the groups is the class size minus the inclusion-exclusion count. -/
theorem card_none_of_three {α : Type*} [DecidableEq α] (U F C H : Finset α)
    (hF : F ⊆ U) (hC : C ⊆ U) (hH : H ⊆ U) :
    ((U \ (F ∪ C ∪ H)).card : ℤ)
      = U.card - (F.card + C.card + H.card - (F ∩ C).card - (F ∩ H).card - (C ∩ H).card
        + (F ∩ C ∩ H).card) := by
  have hs : F ∪ C ∪ H ⊆ U := Finset.union_subset (Finset.union_subset hF hC) hH
  have h := Finset.card_sdiff_add_card_eq_card hs
  have h3 := card_union_three F C H
  omega

-- The card's class of 30, numbered 0 to 29, with the same rosters as the card's code.
def klass : Finset ℕ := Finset.range 30
def foot : Finset ℕ := {0, 1, 2, 3, 4, 5, 6, 7, 8, 18, 19, 20, 21, 22, 23, 24, 26, 27}
def chess : Finset ℕ := {9, 10, 11, 12, 18, 19, 20, 21, 22, 25, 26, 27}
def choir : Finset ℕ := {13, 14, 15, 16, 17, 23, 24, 25, 26, 27}

-- The list sizes and shared counts: 18, 12, 10; then 7, 4, 3; then 2 in all three.
example : klass.card = 30 ∧ foot.card = 18 ∧ chess.card = 12 ∧ choir.card = 10 := by decide
example : (foot ∩ chess).card = 7 ∧ (foot ∩ choir).card = 4 ∧ (chess ∩ choir).card = 3 ∧
    (foot ∩ chess ∩ choir).card = 2 := by decide
example : foot ⊆ klass ∧ chess ⊆ klass ∧ choir ⊆ klass := by decide

-- Two groups: 18 + 12 - 7 = 23 play at least one game, and 30 - 23 = 7 play neither.
example : (18 : ℤ) + 12 - 7 = 23 ∧ (30 : ℤ) - 23 = 7 := by norm_num
example : (foot ∪ chess).card = 23 ∧ (klass \ (foot ∪ chess)).card = 7 := by decide

-- Three groups: 18 + 12 + 10 - 7 - 4 - 3 + 2 = 28 do something, and 30 - 28 = 2 do nothing.
example : (18 : ℤ) + 12 + 10 - 7 - 4 - 3 + 2 = 28 ∧ (30 : ℤ) - 28 = 2 := by norm_num
example : (foot ∪ chess ∪ choir).card = 28 ∧ (klass \ (foot ∪ chess ∪ choir)).card = 2 := by
  decide

-- The class sliced: 9, 4, 5 in one group only, 5, 2, 1 in exactly two, 2 in all three,
-- 2 in none, and the eight slices add to 30.
example : ((foot \ chess) \ choir).card = 9 ∧ ((chess \ foot) \ choir).card = 4 ∧
    ((choir \ foot) \ chess).card = 5 := by decide
example : ((foot ∩ chess) \ choir).card = 5 ∧ ((foot ∩ choir) \ chess).card = 2 ∧
    ((chess ∩ choir) \ foot).card = 1 := by decide
example : (9 : ℕ) + 4 + 5 + 5 + 2 + 1 + 2 = 28 ∧ (28 : ℕ) + 2 = 30 := by decide

-- The three mistakes: adding the lists gives 30, stopping after the pairs gives 26,
-- and taking the all-three count off instead of adding it gives 24.
example : (18 : ℤ) + 12 = 30 := by norm_num
example : (18 : ℤ) + 12 + 10 - 7 - 4 - 3 = 26 := by norm_num
example : (18 : ℤ) + 12 + 10 - 7 - 4 - 3 - 2 = 24 := by norm_num

#print axioms card_union_three
#print axioms card_union_two
#print axioms card_none_of_three
