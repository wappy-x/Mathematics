-- The axiom of choice: for any family of non-empty boxes there is a choice function taking one member out of every box at once, every set can be lined up so that each non-empty part has a first member, and every vector space has a basis.
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.BigOperators
import Mathlib.LinearAlgebra.Basis.VectorSpace
import Mathlib.Order.Defs.Unbundled
import Mathlib.Tactic.NormNum
import Mathlib.SetTheory.Cardinal.Order

/-- The axiom of choice: take any pile of boxes, one box `box i` for each index `i` (finitely
or infinitely many), each box a set of things from `X`. If no box is empty, there is a choice
function: a function `f` that picks one member `f i` out of every box `box i`, all at once. -/
theorem axiom_of_choice {ι X : Type*} (box : ι → Set X) (h : ∀ i, (box i).Nonempty) :
    ∃ f : ι → X, ∀ i, f i ∈ box i := by
  exact ⟨fun i => (h i).some, fun i => (h i).some_mem⟩

/-- The well-ordering theorem: every set can be lined up (a total order `r`, where `r a b`
means `a` comes no later than `b`) so that every non-empty part of it has a first member. -/
theorem every_set_can_be_well_ordered (α : Type*) :
    ∃ r : α → α → Prop, IsLinearOrder α r ∧
      ∀ S : Set α, S.Nonempty → ∃ m ∈ S, ∀ x ∈ S, r m x := by
  let _ : LinearOrder α := (WellOrderingRel.isWellOrder (α := α)).linearOrder
  refine ⟨(· ≤ ·), inferInstance, ?_⟩
  intro S hS
  obtain ⟨m, hm, hmin⟩ := (WellOrderingRel.isWellOrder (α := α)).wf.has_min S hS
  exact ⟨m, hm, fun x hx => not_lt.mp (hmin x hx)⟩

/-- Every vector space has a basis: for every field `K` and every vector space `V` over `K`,
there is a set `s` of vectors in `V` that is a basis of `V`. -/
theorem every_vector_space_has_a_basis (K V : Type*) [Field K] [AddCommGroup V] [Module K V] :
    ∃ s : Set V, Nonempty (Module.Basis s K V) := by
  exact ⟨_, ⟨Module.Basis.ofVectorSpace K V⟩⟩

-- Ten boxes (rooms 1 to 10, here 0 to 9), two socks in each (0 = left, 1 = right).
-- Three boxes, by hand: 2 × 2 × 2 = 8 full picks.
example : 2 * 2 * 2 = 8 := by norm_num
example : (Fintype.piFinset fun _ : Fin 3 => (Finset.univ : Finset (Fin 2))).card = 8 := by
  decide
-- Ten boxes: ten twos multiplied, 1024 full picks; built and counted, also 1024.
example : 2 ^ 10 = 1024 := by norm_num
example : (Fintype.piFinset fun _ : Fin 10 => (Finset.univ : Finset (Fin 2))).card = 1024 := by
  rw [Fintype.card_piFinset]; simp
-- The shoe rule, "take the left one", names exactly 1 of the 1024 picks.
example : ((Fintype.piFinset fun _ : Fin 10 => (Finset.univ : Finset (Fin 2))).filter
    (fun p => p = fun _ => 0)).card = 1 := by
  rw [Finset.filter_eq']; simp
-- One of the ten boxes empty: 0 full picks.
example : (Fintype.piFinset fun i : Fin 10 =>
    if i = 9 then (∅ : Finset (Fin 2)) else Finset.univ).card = 0 := by
  rw [Fintype.card_piFinset]; decide

#print axioms axiom_of_choice
#print axioms every_set_can_be_well_ordered
#print axioms every_vector_space_has_a_basis
