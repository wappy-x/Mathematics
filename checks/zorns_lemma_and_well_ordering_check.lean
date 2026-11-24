-- Zorn's lemma and the well-ordering theorem: if every chain in an ordered collection has an upper bound in it, some member has nothing strictly above it; every set can be well-ordered; and a maximal partial pick from non-empty boxes picks from every box.
import Mathlib.Order.Zorn
import Mathlib.Order.RelClasses
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum
import Mathlib.SetTheory.Cardinal.Order

/-- Zorn's lemma: in a collection with an order ("inside" is one), if every chain
(every climb, a set of members that all compare) has a ceiling inside the collection,
then some member has nothing in the collection strictly above it. -/
theorem zorn_every_chain_bounded_gives_maximal {P : Type*} [PartialOrder P]
    (h : ∀ c : Set P, IsChain (· ≤ ·) c → ∃ u : P, ∀ x ∈ c, x ≤ u) :
    ∃ m : P, ∀ x : P, ¬ m < x := by
  obtain ⟨m, hm⟩ := zorn_le (fun c hc => by
    obtain ⟨u, hu⟩ := h c hc
    exact ⟨u, fun x hx => hu x hx⟩)
  exact ⟨m, fun x hx => hm.not_lt hx⟩

/-- The well-ordering theorem: every set has a well-ordering, a strict line-up in which
any two members compare and every non-empty part has a first member. -/
theorem every_set_has_a_well_ordering (α : Type*) :
    ∃ r : α → α → Prop, IsWellOrder α r := by
  exact ⟨WellOrderingRel, WellOrderingRel.isWellOrder⟩

/-- Zorn gives choice (Step 4): a partial pick is a set of pairs (box, member) with each
member taken from its box and at most one pick per box, ordered by "inside". If every
box is non-empty, a maximal partial pick misses no box: it picks from every box. -/
theorem maximal_partial_pick_picks_from_every_box {ι α : Type*} (S : ι → Set α)
    (hS : ∀ i, (S i).Nonempty) (g : Set (ι × α))
    (hg : Maximal (fun f : Set (ι × α) =>
        (∀ p ∈ f, p.2 ∈ S p.1) ∧ ∀ p ∈ f, ∀ q ∈ f, p.1 = q.1 → p = q) g) :
    ∀ i, ∃ a ∈ S i, (i, a) ∈ g := by
  intro i
  by_contra hne
  push Not at hne
  obtain ⟨a, ha⟩ := hS i
  have hprop : (∀ p ∈ insert (i, a) g, p.2 ∈ S p.1) ∧
      ∀ p ∈ insert (i, a) g, ∀ q ∈ insert (i, a) g, p.1 = q.1 → p = q := by
    refine ⟨?_, ?_⟩
    · intro p hp
      rcases Set.mem_insert_iff.mp hp with rfl | hp
      · exact ha
      · exact hg.prop.1 p hp
    · intro p hp q hq hpq
      rcases Set.mem_insert_iff.mp hp with rfl | hp' <;>
        rcases Set.mem_insert_iff.mp hq with rfl | hq'
      · rfl
      · obtain ⟨q1, q2⟩ := q
        simp only at hpq
        subst hpq
        exact absurd hq' (hne q2 (hg.prop.1 _ hq'))
      · obtain ⟨p1, p2⟩ := p
        simp only at hpq
        subst hpq
        exact absurd hp' (hne p2 (hg.prop.1 _ hp'))
      · exact hg.prop.2 p hp' q hq' hpq
  have hsub : insert (i, a) g ⊆ g := hg.2 hprop (Set.subset_insert _ _)
  exact hne a ha (hsub (Set.mem_insert _ _))

-- The card's worked numbers.
-- c = a + b: (2, 1, 0) = (1, 0, 0) + (1, 1, 0), so c is refused.
example : ((2, 1, 0) : ℤ × ℤ × ℤ) = (1, 0, 0) + (1, 1, 0) := by decide
-- c - a - b = (0, 0, 0).
example : ((2, 1, 0) : ℤ × ℤ × ℤ) - (1, 0, 0) - (1, 1, 0) = (0, 0, 0) := by decide
-- The three maximal sets abd, acd, bcd have nonzero determinant; abc has determinant 0.
example : (!![1, 0, 0; 1, 1, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℤ).det = 1 := by
  norm_num [Matrix.det_fin_three]
example : (!![1, 0, 0; 2, 1, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℤ).det = 1 := by
  norm_num [Matrix.det_fin_three]
example : (!![1, 1, 0; 2, 1, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℤ).det = -1 := by
  norm_num [Matrix.det_fin_three]
example : (!![1, 0, 0; 1, 1, 0; 2, 1, 0] : Matrix (Fin 3) (Fin 3) ℤ).det = 0 := by
  norm_num [Matrix.det_fin_three]
-- Sets of four arrows: 2 × 2 × 2 × 2 = 16; independent by size 0 to 4: 1 + 4 + 6 + 3 + 0 = 14.
example : 2 * 2 * 2 * 2 = 16 := by norm_num
example : 1 + 4 + 6 + 3 + 0 = 14 := by norm_num
-- 24 line-ups split evenly across 3 maximal sets: 8 each.
example : Nat.factorial 4 = 24 ∧ 24 / 3 = 8 := by decide

#print axioms zorn_every_chain_bounded_gives_maximal
#print axioms every_set_has_a_well_ordering
#print axioms maximal_partial_pick_picks_from_every_box
