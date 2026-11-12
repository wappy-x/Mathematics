-- Set operations: for any universe and any two sets in it, "on neither" is "not on A and not on B" and "not on both" is "not on A or not on B" (De Morgan), a union counts the overlap once, the four piles add back to the universe, and the card's 12-film watchlist comes out as it says.
import Mathlib.Data.Set.Basic
import Mathlib.Data.Finset.Card

/-- De Morgan's law for sets, with the universe `U` named first and every complement taken
inside it. Not on either is not on A and not on B: `U − (A ∪ B) = (U − A) ∩ (U − B)`.
The mirror law: not on both is not on A or not on B: `U − (A ∩ B) = (U − A) ∪ (U − B)`. -/
theorem de_morgan_complement_in_universe {α : Type*} (U A B : Set α) :
    U \ (A ∪ B) = (U \ A) ∩ (U \ B) ∧ U \ (A ∩ B) = (U \ A) ∪ (U \ B) := by
  constructor
  · ext x; simp only [Set.mem_diff, Set.mem_union, Set.mem_inter_iff]; tauto
  · ext x; simp only [Set.mem_diff, Set.mem_union, Set.mem_inter_iff]; tauto

/-- The union counts the overlap once: for any two finite sets, the size of the union is the
two sizes added with the shared part taken off once, `#(A ∪ B) = #A + #B − #(A ∩ B)`. -/
theorem union_counts_overlap_once {α : Type*} [DecidableEq α] (A B : Finset α) :
    (A ∪ B).card = A.card + B.card - (A ∩ B).card := by
  have h := Finset.card_union_add_card_inter A B
  omega

/-- Two gates, four piles: when A and B sit inside a finite universe `U`, every thing lands in
exactly one of A only, both, B only and neither, so the four piles add back to the universe:
`#(A − B) + #(A ∩ B) + #(B − A) + #(U − (A ∪ B)) = #U`. -/
theorem four_piles_add_back_to_universe {α : Type*} [DecidableEq α] (U A B : Finset α)
    (hA : A ⊆ U) (hB : B ⊆ U) :
    (A \ B).card + (A ∩ B).card + (B \ A).card + (U \ (A ∪ B)).card = U.card := by
  have h1 : (A \ B).card + (A ∩ B).card = A.card := by
    have := Finset.card_sdiff_add_card_inter A B
    omega
  have h2 : (U \ (A ∪ B)).card + (A ∪ B).card = U.card := by
    have := Finset.card_sdiff_add_card_eq_card (Finset.union_subset hA hB)
    omega
  have h3 : (A ∪ B).card + (A ∩ B).card = A.card + B.card := Finset.card_union_add_card_inter A B
  have h4 : (B \ A).card + (A ∩ B).card = B.card := by
    have := Finset.card_sdiff_add_card_inter B A
    rw [Finset.inter_comm] at this
    omega
  omega

/-- The card's twelve films. -/
inductive Film
  | Drift | Ember | Fathom | Glint | Halo | Ivory
  | Kestrel | Lantern | Moth | Nectar | Onyx | Pike
  deriving DecidableEq

open Film

/-- The watchlist, the universe, named first: all twelve films. -/
def watchlist : Finset Film :=
  {Drift, Ember, Fathom, Glint, Halo, Ivory, Kestrel, Lantern, Moth, Nectar, Onyx, Pike}
/-- The films on service A. -/
def serviceA : Finset Film := {Drift, Ember, Fathom, Glint, Halo, Ivory}
/-- The films on service B. -/
def serviceB : Finset Film := {Halo, Ivory, Kestrel, Lantern, Moth}

-- The universe and the two lists: 12, 6 and 5 films.
example : watchlist.card = 12 := by decide
example : serviceA.card = 6 ∧ serviceB.card = 5 := by decide
-- The union: 9 films, the overlap counted once, 6 + 5 − 2 = 9.
example : serviceA ∪ serviceB =
    {Drift, Ember, Fathom, Glint, Halo, Ivory, Kestrel, Lantern, Moth} := by decide
example : (serviceA ∪ serviceB).card = 9 := by decide
example : 6 + 5 - 2 = 9 := by decide
-- The intersection: Halo and Ivory, 2 films.
example : serviceA ∩ serviceB = {Halo, Ivory} := by decide
example : (serviceA ∩ serviceB).card = 2 := by decide
-- The difference keeps its order: A − B is 4 films, B − A is 3.
example : serviceA \ serviceB = {Drift, Ember, Fathom, Glint} := by decide
example : (serviceA \ serviceB).card = 4 ∧ 6 - 2 = 4 := by decide
example : serviceB \ serviceA = {Kestrel, Lantern, Moth} := by decide
example : (serviceB \ serviceA).card = 3 ∧ 5 - 2 = 3 := by decide
-- Not on either, off the union: Nectar, Onyx, Pike, 12 − 9 = 3.
example : watchlist \ (serviceA ∪ serviceB) = {Nectar, Onyx, Pike} := by decide
example : (watchlist \ (serviceA ∪ serviceB)).card = 3 ∧ 12 - 9 = 3 := by decide
-- Not on either, one service at a time: not on A is 6 films, not on B is 7, on both lists 3.
example : (watchlist \ serviceA).card = 6 ∧ 12 - 6 = 6 := by decide
example : (watchlist \ serviceB).card = 7 ∧ 12 - 5 = 7 := by decide
example : (watchlist \ serviceA) ∩ (watchlist \ serviceB) = {Nectar, Onyx, Pike} := by decide
-- The mirror law: not on both services is 10 films.
example : (watchlist \ (serviceA ∩ serviceB)).card = 10 := by decide
example : ((watchlist \ serviceA) ∪ (watchlist \ serviceB)).card = 10 := by decide
-- The four piles add back to 12.
example : 4 + 2 + 3 + 3 = 12 := by decide
-- The three mistakes: 6 + 5 = 11, 6 − 5 = 1, and "or" for "and" gives 12 − 2 = 10.
example : serviceA.card + serviceB.card = 11 := by decide
example : serviceA.card - serviceB.card = 1 := by decide
example : watchlist.card - (serviceA ∩ serviceB).card = 10 := by decide

#print axioms de_morgan_complement_in_universe
#print axioms union_counts_overlap_once
#print axioms four_piles_add_back_to_universe
