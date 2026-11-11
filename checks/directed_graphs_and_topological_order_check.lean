-- Directed graphs: a finite directed graph can be listed with every arrow pointing forward exactly when no run of arrows returns to its start, the in-degrees and the out-degrees each add up to the arrow count, a finite graph with no way back has a vertex nothing points at, and the card's recipe numbers come out as it says.
import Mathlib.Combinatorics.Digraph.Basic
import Mathlib.Logic.Relation
import Mathlib.Data.Fintype.Prod
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Order.Extension.Linear
import Mathlib.Data.Finset.Sort
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Algebra.BigOperators.Group.Finset.Piecewise

open Finset

/-- A directed graph on finitely many vertices has a topological order (a listing of all its
vertices, each once, as places `0` to `n − 1`, with every arrow's tail earlier than its head)
exactly when it has no directed cycle: no run of one or more arrows leads from a vertex back to
itself. An arrow from a vertex to itself counts as a cycle. Connectedness is not needed. -/
theorem has_topological_order_iff_no_directed_cycle {V : Type*} [Fintype V] (G : Digraph V) :
    (∃ f : V ≃ Fin (Fintype.card V), ∀ u v, G.Adj u v → f u < f v) ↔
      ∀ v, ¬ Relation.TransGen G.Adj v v := by
  constructor
  · rintro ⟨f, hf⟩ v hv
    have key : ∀ a b, Relation.TransGen G.Adj a b → f a < f b := by
      intro a b h
      induction h with
      | single h => exact hf _ _ h
      | tail _ h ih => exact ih.trans (hf _ _ h)
    exact lt_irrefl _ (key v v hv)
  · intro hcyc
    let P : PartialOrder V :=
      { le := Relation.ReflTransGen G.Adj
        le_refl := fun a => Relation.ReflTransGen.refl
        le_trans := fun a b c => Relation.ReflTransGen.trans
        le_antisymm := by
          intro a b hab hba
          rcases Relation.reflTransGen_iff_eq_or_transGen.mp hab with h1 | h1
          · exact h1.symm
          rcases Relation.reflTransGen_iff_eq_or_transGen.mp hba with h2 | h2
          · exact h2
          exact (hcyc a (h1.trans h2)).elim }
    let _ : Fintype (LinearExtension V) := inferInstanceAs (Fintype V)
    let e : Fin (Fintype.card V) ≃o LinearExtension V := Fintype.orderIsoFinOfCardEq _ rfl
    refine ⟨(Equiv.refl V).trans e.symm.toEquiv, ?_⟩
    intro u v huv
    have hne : u ≠ v := by
      rintro rfl
      exact hcyc u (Relation.TransGen.single huv)
    have hle : toLinearExtension u ≤ toLinearExtension v :=
      toLinearExtension.monotone (Relation.ReflTransGen.single huv : u ≤ v)
    have hlt : toLinearExtension u < toLinearExtension v := lt_of_le_of_ne hle hne
    exact e.symm.strictMono hlt

/-- Each arrow has one tail and one head, so the in-degrees added over every vertex and the
out-degrees added over every vertex both equal the number of arrows. -/
theorem sum_in_degree_eq_card_arcs_eq_sum_out_degree {V : Type*} [Fintype V] (G : Digraph V)
    [DecidableRel G.Adj] :
    ∑ v, #{u | G.Adj u v} = #{p : V × V | G.Adj p.1 p.2} ∧
      #{p : V × V | G.Adj p.1 p.2} = ∑ v, #{w | G.Adj v w} := by
  simp only [Finset.card_filter, Fintype.sum_prod_type]
  exact ⟨Finset.sum_comm, trivial⟩

/-- A directed graph with finitely many vertices, at least one, and no directed cycle has a
source: a vertex that no arrow points at. -/
theorem exists_source_of_no_directed_cycle {V : Type*} [Fintype V] [Nonempty V] (G : Digraph V)
    (h : ∀ v, ¬ Relation.TransGen G.Adj v v) : ∃ v, ∀ u, ¬ G.Adj u v := by
  have : IsTrans V (Relation.TransGen G.Adj) := ⟨fun _ _ _ => Relation.TransGen.trans⟩
  have : Std.Irrefl (Relation.TransGen G.Adj) := ⟨h⟩
  have wf := Finite.wellFounded_of_trans_of_irrefl (Relation.TransGen G.Adj)
  obtain ⟨v, -, hv⟩ := wf.has_min Set.univ Set.univ_nonempty
  exact ⟨v, fun u huv => hv u trivial (Relation.TransGen.single huv)⟩

/-- The recipe, steps numbered alphabetically: 0 bake, 1 boil the water, 2 chop the onion,
3 cook the pasta sheets, 4 grate the cheese, 5 heat the oven, 6 layer the dish, 7 simmer the
sauce. An arrow `u → v` means `u` before `v`. -/
def recipeArcs : List (Fin 8 × Fin 8) := [(1, 3), (2, 7), (3, 6), (4, 6), (7, 6), (4, 0), (5, 0), (6, 0)]
abbrev recipe : Digraph (Fin 8) := Digraph.mk' fun u v => decide ((u, v) ∈ recipeArcs)
/-- The recipe with one more rule: layer the dish before grating the cheese. -/
abbrev recipeBack : Digraph (Fin 8) := Digraph.mk' fun u v => decide ((u, v) ∈ (6, 4) :: recipeArcs)
/-- The metro map with every line one-way: the ring A→B→C→D→E→F→A plus B→E and C→F. -/
abbrev metro : Digraph (Fin 6) := Digraph.mk' fun u v =>
  decide ((u, v) ∈ [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)])

-- Eight arrows; arrows in at steps 0 to 7 are 3, 0, 0, 1, 0, 0, 3, 1 and arrows out
-- 0, 1, 1, 1, 2, 1, 1, 1, both adding to 8.
example : #{p : Fin 8 × Fin 8 | recipe.Adj p.1 p.2} = 8 := by decide
example : (List.finRange 8).map (fun v => #{u | recipe.Adj u v}) = [3, 0, 0, 1, 0, 0, 3, 1] := by
  decide
example : (List.finRange 8).map (fun v => #{w | recipe.Adj v w}) = [0, 1, 1, 1, 2, 1, 1, 1] := by
  decide
-- Four sources (boil, chop, grate, heat) and one sink (bake).
example : ({v | ∀ u, ¬ recipe.Adj u v} : Finset (Fin 8)) = {1, 2, 4, 5} := by decide
example : ({v | ∀ w, ¬ recipe.Adj v w} : Finset (Fin 8)) = {0} := by decide
-- Kahn's listing 1, 2, 3, 4, 5, 7, 6, 0 uses every step once and puts all 8 arrows forward.
example : [1, 2, 3, 4, 5, 7, 6, 0].Perm (List.finRange 8) := by decide
example : ∀ u v : Fin 8, recipe.Adj u v →
    [1, 2, 3, 4, 5, 7, 6, 0].idxOf u < [1, 2, 3, 4, 5, 7, 6, 0].idxOf v := by decide
-- Peeling sinks and writing them left to right gives 0, 5, 6, 3, 1, 4, 7, 2: no arrow forward.
example : ∀ u v : Fin 8, recipe.Adj u v →
    [0, 5, 6, 3, 1, 4, 7, 2].idxOf v < [0, 5, 6, 3, 1, 4, 7, 2].idxOf u := by decide
-- The extra rule closes the loop grate → layer → grate.
example : recipeBack.Adj 4 6 ∧ recipeBack.Adj 6 4 := by decide
-- After writing boil, chop, cook, heat and simmer, Kahn jams: bake, grate and layer are each
-- still pointed at by another of the three.
example : ∀ v ∈ ({0, 4, 6} : Finset (Fin 8)), ∃ u ∈ ({0, 4, 6} : Finset (Fin 8)), recipeBack.Adj u v := by
  decide
-- The one-way metro map: 8 arrows, and every station has an arrow pointing at it.
example : #{p : Fin 6 × Fin 6 | metro.Adj p.1 p.2} = 8 := by decide
example : ∀ v, ∃ u, metro.Adj u v := by decide

#print axioms has_topological_order_iff_no_directed_cycle
#print axioms sum_in_degree_eq_card_arcs_eq_sum_out_degree
#print axioms exists_source_of_no_directed_cycle
