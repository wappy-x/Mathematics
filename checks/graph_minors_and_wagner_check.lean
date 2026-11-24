-- Graph minors: a flat drawing whose shortest ring has g lines obeys (g - 2) E <= g (V - 2), the Petersen graph has K(5) as a minor by contracting its five spokes, and a graph has no ring exactly when the triangle is not among its minors.
import Mathlib.Combinatorics.SimpleGraph.Girth
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Subgraph
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Combinatorics.SimpleGraph.Paths
import Mathlib.Tactic.FinCases
import Mathlib.Data.Fin.VecNotation

namespace GraphMinors

open SimpleGraph

/-- `H` is a minor of `G` (the card's Step 2): `G` has pairwise disjoint branch sets, one per dot
of `H`, each joined among itself (its induced graph is connected, so in particular not empty),
with a line of `G` between two branch sets wherever `H` has a line. Fusing each branch set into
one dot and deleting what is left over turns `G` into `H`. Mathlib has no graph minors, so the
card's own definition is written out here. -/
def IsMinor {W V : Type*} (H : SimpleGraph W) (G : SimpleGraph V) : Prop :=
  ∃ B : W → Set V,
    (∀ w, (G.induce (B w)).Connected) ∧
    Pairwise (fun a b => Disjoint (B a) (B b)) ∧
    ∀ a b, H.Adj a b → ∃ x ∈ B a, ∃ y ∈ B b, G.Adj x y

/-- The links of the Petersen board: an outer ring of five, five spokes, and an inner
five-pointed star. -/
def petersenLinks : List (Fin 10 × Fin 10) :=
  [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0),
   (0, 5), (1, 6), (2, 7), (3, 8), (4, 9),
   (5, 7), (6, 8), (7, 9), (8, 5), (9, 6)]

/-- The Petersen graph: ten processors, fifteen links. -/
def petersen : SimpleGraph (Fin 10) where
  Adj x y := (x, y) ∈ petersenLinks ∨ (y, x) ∈ petersenLinks
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel petersen.Adj := fun _ _ =>
  inferInstanceAs (Decidable (_ ∨ _))

theorem walk_in_set {V : Type*} (G : SimpleGraph V) {s : Set V} (hc : (G.induce s).Connected)
    {a b : V} (ha : a ∈ s) (hb : b ∈ s) :
    ∃ p : G.Walk a b, ∀ e ∈ p.edges, ∀ v ∈ e, v ∈ s := by
  obtain ⟨q⟩ := hc.preconnected ⟨a, ha⟩ ⟨b, hb⟩
  have key : ∀ e ∈ (q.map (Embedding.induce s).toHom).edges, ∀ v ∈ e, v ∈ s := by
    intro e he v hv
    rw [Walk.edges_map, List.mem_map] at he
    obtain ⟨e', _, rfl⟩ := he
    rw [Sym2.mem_map] at hv
    obtain ⟨w, _, rfl⟩ := hv
    exact w.2
  exact ⟨_, key⟩

#print axioms walk_in_set

theorem induce_singleton_connected' {V : Type*} (G : SimpleGraph V) (v : V) :
    (G.induce {v}).Connected := by
  simp

#print axioms induce_singleton_connected'

/-- The girth ceiling. Take a finite graph with at least one ring, so its girth `g` (the length
of its shortest ring) is at least 3. Suppose it has a flat drawing with `F` regions. Mathlib has
no flat drawings, so the drawing enters through the two facts the card's proof uses: every region
is walled by at least `g` sides, so `g F ≤ 2 E`, and Euler's formula gives at least
`E - V + 2` regions. Then the lines obey `(g - 2) E ≤ g (V - 2)`. -/
theorem edges_le_girth_ceiling {V : Type*} [Fintype V] (G : SimpleGraph V) [DecidableRel G.Adj]
    (hring : ¬ G.IsAcyclic) (F : ℕ)
    (hsides : G.girth * F ≤ 2 * G.edgeFinset.card)
    (heuler : G.edgeFinset.card + 2 ≤ F + Fintype.card V) :
    ((G.girth : ℤ) - 2) * G.edgeFinset.card ≤ (G.girth : ℤ) * ((Fintype.card V : ℤ) - 2) := by
  have h := Nat.mul_le_mul_left G.girth heuler
  have h1 : ((G.girth * F : ℕ) : ℤ) ≤ ((2 * G.edgeFinset.card : ℕ) : ℤ) := by exact_mod_cast hsides
  have h2 : ((G.girth * (G.edgeFinset.card + 2) : ℕ) : ℤ) ≤ ((G.girth * (F + Fintype.card V) : ℕ) : ℤ) := by
    exact_mod_cast h
  push_cast at h1 h2
  nlinarith

/-- Contracting the Petersen graph's five spokes leaves K(5): it has the complete graph on five
dots as a minor. -/
theorem petersen_has_K5_minor : IsMinor (⊤ : SimpleGraph (Fin 5)) petersen := by
  refine ⟨fun w => {x : Fin 10 | x.val % 5 = w.val}, ?_, ?_, ?_⟩
  · intro w
    have hs : {x : Fin 10 | x.val % 5 = w.val} =
        {(⟨w.val, by omega⟩ : Fin 10), (⟨w.val + 5, by omega⟩ : Fin 10)} := by
      ext x
      simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff, Fin.ext_iff]
      omega
    show (induce {x : Fin 10 | x.val % 5 = w.val} petersen).Connected
    rw [hs]
    apply induce_pair_connected_of_adj
    fin_cases w <;> decide
  · intro a b hab
    rw [Set.disjoint_left]
    intro x ha hb
    simp only [Set.mem_ofPred_eq] at ha hb
    exact hab (Fin.ext (by omega))
  · simp only [top_adj, Set.mem_ofPred_eq]
    decide

/-- Forests are the minor-closed family whose one forbidden minor is the triangle: a finite graph
has no ring exactly when the triangle K(3) is not a minor of it. -/
theorem isAcyclic_iff_not_triangle_minor {V : Type*} [Fintype V] (G : SimpleGraph V) :
    G.IsAcyclic ↔ ¬ IsMinor (⊤ : SimpleGraph (Fin 3)) G := by
  constructor
  · rintro hG ⟨B, hconn, hdisj, hadj⟩
    have d : ∀ a b : Fin 3, a ≠ b → ∀ x, x ∈ B a → x ∈ B b → False := fun a b hab x ha hb =>
      Set.disjoint_left.mp (hdisj hab) ha hb
    obtain ⟨x01, hx01, y01, hy01, h01⟩ := hadj 0 1 (by decide)
    obtain ⟨x12, hx12, y12, hy12, h12⟩ := hadj 1 2 (by decide)
    obtain ⟨x20, hx20, y20, hy20, h20⟩ := hadj 2 0 (by decide)
    obtain ⟨p1, hp1⟩ := walk_in_set G (hconn 1) hy01 hx12
    obtain ⟨p2, hp2⟩ := walk_in_set G (hconn 2) hy12 hx20
    obtain ⟨p0, hp0⟩ := walk_in_set G (hconn 0) hy20 hx01
    have hb := isAcyclic_iff_forall_adj_isBridge.mp hG h01
    rw [isBridge_iff_forall_walk_mem_edges] at hb
    have := hb (p1.append (Walk.cons h12 (p2.append (Walk.cons h20 p0)))).reverse
    simp only [Walk.edges_reverse, List.mem_reverse, Walk.edges_append, Walk.edges_cons,
      List.mem_append, List.mem_cons, Sym2.eq_iff] at this
    rcases this with h | (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩) | h | (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩) | h
    · exact d 0 1 (by decide) x01 hx01 (hp1 _ h x01 (Sym2.mem_mk_left _ _))
    · exact d 0 1 (by decide) _ hx01 hx12
    · exact d 0 2 (by decide) _ hx01 hy12
    · exact d 0 2 (by decide) x01 hx01 (hp2 _ h x01 (Sym2.mem_mk_left _ _))
    · exact d 0 2 (by decide) _ hx01 hx20
    · exact d 1 2 (by decide) _ hy01 hx20
    · exact d 0 1 (by decide) y01 (hp0 _ h y01 (Sym2.mem_mk_right _ _)) hy01
  · intro hm
    by_contra hG
    apply hm
    obtain ⟨v, c, hc⟩ := not_isAcyclic_iff_exists_isCycle.mp hG
    cases c with
    | nil => exact (Walk.not_isCycle_nil hc).elim
    | @cons _ u _ h p =>
      rw [Walk.cons_isCycle_iff] at hc
      obtain ⟨hp, hnot⟩ := hc
      cases p with
      | nil => exact absurd h (G.loopless.irrefl _)
      | @cons _ w _ h' p'' =>
        rw [Walk.cons_isPath_iff] at hp
        obtain ⟨hp'', hu⟩ := hp
        have hrp := hp''.reverse
        have hsupp : p''.reverse.support = p''.support.reverse := Walk.support_reverse _
        generalize hr : p''.reverse = r at hrp hsupp
        cases r with
        | nil =>
          exfalso
          have he := congrArg Walk.edges hr
          simp only [Walk.edges_reverse, Walk.edges_nil, List.reverse_eq_nil_iff] at he
          apply hnot
          simp [he, Sym2.eq_swap]
        | @cons _ z _ hvz q =>
          rw [Walk.cons_isPath_iff] at hrp
          have hvq : v ∉ q.support := hrp.2
          have huq : u ∉ q.support := by
            intro huq'
            apply hu
            have : u ∈ (Walk.cons hvz q).support := List.mem_cons_of_mem _ huq'
            rw [hsupp] at this
            exact List.mem_reverse.mp this
          have hvu : v ≠ u := G.ne_of_adj h
          refine ⟨![{v}, {u}, {x | x ∈ q.support}], ?_, ?_, ?_⟩
          · intro i
            fin_cases i
            · exact induce_singleton_connected' G v
            · exact induce_singleton_connected' G u
            · exact q.connected_induce_support
          · intro a b hab
            fin_cases a <;> fin_cases b <;>
              simp [hvu, hvu.symm, hvq, huq, Set.disjoint_singleton_left,
                Set.disjoint_singleton_right] at hab ⊢
          · intro a b hab
            fin_cases a <;> fin_cases b <;> simp at hab ⊢ <;>
              first
              | exact h | exact h.symm
              | exact ⟨_, q.start_mem_support, hvz⟩ | exact ⟨_, q.start_mem_support, hvz.symm⟩
              | exact ⟨_, q.end_mem_support, h'⟩ | exact ⟨_, q.end_mem_support, h'.symm⟩

-- The Petersen board: 10 dots, 15 lines, three at every dot (so no dot has the four lines a
-- K(5) subdivision needs).
example : Fintype.card (Fin 10) = 10 ∧ petersen.edgeFinset.card = 15 := by decide
example : ∀ v, petersen.degree v = 3 := by decide

-- The edge ceiling 3V - 6 = 24 is silent: 15 lines fit.
example : 3 * 10 - 6 = 24 ∧ 15 ≤ 3 * 10 - 6 := by norm_num

-- The ring-of-four ceiling 2V - 4 = 16 is silent too.
example : 2 * 10 - 4 = 16 ∧ 15 ≤ 2 * 10 - 4 := by norm_num

-- The girth-5 ceiling refuses: (5 - 2) * 15 = 45 is over 5 * (10 - 2) = 40.
example : (5 - 2) * 15 = 45 ∧ 5 * (10 - 2) = 40 ∧ 5 * (10 - 2) < (5 - 2) * 15 := by norm_num

-- 30 sides fill at most 6 regions of 5 sides, but Euler needs 15 - 10 + 2 = 7.
example : 2 * 15 / 5 = 6 ∧ 15 - 10 + 2 = 7 ∧ 2 * 15 / 5 < 15 - 10 + 2 := by norm_num

-- Contracting the 5 spokes: 10 - 5 = 5 dots and 15 - 5 = 10 lines, every one of the
-- 5 * 4 / 2 = 10 pairs joined.
example : 10 - 5 = 5 ∧ 15 - 5 = 10 ∧ 5 * 4 / 2 = 10 := by norm_num

#print axioms edges_le_girth_ceiling
#print axioms petersen_has_K5_minor
#print axioms isAcyclic_iff_not_triangle_minor

end GraphMinors
