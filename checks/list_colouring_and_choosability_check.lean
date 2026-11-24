-- List colouring: in every finite graph the choice number is at least the chromatic number and at most one past the largest degree, and K(2,4) colours with two shared colours yet needs lists of three, as the card's six licences show.
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.Fintype.Sum
import Mathlib.Tactic.NormNum

open SimpleGraph

namespace SimpleGraph

variable {V : Type*} (G : SimpleGraph V)

/-- A list assignment `L` hands each vertex `v` its own finite list `L v` of allowed colours
(whole numbers). An `L`-colouring is a proper colouring `c` (joined vertices differ) with each
`c v` taken from `L v`. -/
def ListColorable (L : V → Finset ℕ) : Prop :=
  ∃ C : G.Coloring ℕ, ∀ v, C v ∈ L v

/-- `G` is `k`-choosable when it has an `L`-colouring for every list assignment whose lists all
hold at least `k` colours. Only the lengths are bounded: together the lists may name any colours. -/
def Choosable (k : ℕ) : Prop :=
  ∀ L : V → Finset ℕ, (∀ v, k ≤ (L v).card) → G.ListColorable L

/-- The choice number ch(G): the smallest `k` for which `G` is `k`-choosable (`⊤` if none). -/
noncomputable def choiceNumber : ℕ∞ :=
  ⨅ k ∈ Set.ofPred G.Choosable, (k : ℕ∞)

end SimpleGraph

/-- Greedy step: every finite graph is `(Δ + 1)`-choosable. -/
theorem SimpleGraph.choosable_maxDegree_add_one {V : Type*} [Fintype V]
    (G : SimpleGraph V) [DecidableRel G.Adj] : G.Choosable (G.maxDegree + 1) := by
  classical
  intro L hL
  have key : ∀ S : Finset V, ∃ f : V → ℕ, (∀ v ∈ S, f v ∈ L v) ∧
      ∀ u ∈ S, ∀ v ∈ S, G.Adj u v → f u ≠ f v := by
    intro S
    induction S using Finset.induction_on with
    | empty => exact ⟨fun _ => 0, by simp, by simp⟩
    | @insert a S ha ih =>
      obtain ⟨f, hf1, hf2⟩ := ih
      have hcard : ((G.neighborFinset a).image f).card < (L a).card := by
        calc ((G.neighborFinset a).image f).card ≤ (G.neighborFinset a).card :=
              Finset.card_image_le
          _ = G.degree a := G.card_neighborFinset_eq_degree a
          _ ≤ G.maxDegree := G.degree_le_maxDegree a
          _ < G.maxDegree + 1 := Nat.lt_succ_self _
          _ ≤ (L a).card := hL a
      obtain ⟨x, hxL, hxn⟩ := Finset.exists_mem_notMem_of_card_lt_card hcard
      have hx : ∀ w, G.Adj a w → f w ≠ x := by
        intro w hw h
        apply hxn
        rw [Finset.mem_image]
        exact ⟨w, (G.mem_neighborFinset a w).2 hw, h⟩
      refine ⟨Function.update f a x, ?_, ?_⟩
      · intro v hv
        rcases Finset.mem_insert.1 hv with rfl | hv
        · simpa using hxL
        · have : v ≠ a := fun h => ha (h ▸ hv)
          simpa [Function.update_of_ne this] using hf1 v hv
      · intro u hu v hv huv
        have hu' := Finset.mem_insert.1 hu
        have hv' := Finset.mem_insert.1 hv
        by_cases hua : u = a <;> by_cases hva : v = a
        · subst hua; subst hva; exact absurd huv (G.irrefl)
        · subst hua
          have hvS : v ∈ S := hv'.resolve_left hva
          rw [Function.update_self, Function.update_of_ne hva]
          exact (hx v huv).symm
        · subst hva
          rw [Function.update_self, Function.update_of_ne hua]
          exact hx u huv.symm
        · rw [Function.update_of_ne hua, Function.update_of_ne hva]
          exact hf2 u (hu'.resolve_left hua) v (hv'.resolve_left hva) huv
  obtain ⟨f, hf1, hf2⟩ := key Finset.univ
  exact ⟨Coloring.mk f (fun {u v} h => hf2 u (Finset.mem_univ _) v (Finset.mem_univ _) h),
    fun v => hf1 v (Finset.mem_univ _)⟩

/-- A `k`-choosable graph is `k`-colourable: give every vertex the list `0, …, k - 1`. -/
theorem SimpleGraph.Choosable.colorable {V : Type*} {G : SimpleGraph V} {k : ℕ}
    (h : G.Choosable k) : G.Colorable k := by
  obtain ⟨C, hC⟩ := h (fun _ => Finset.range k) (fun _ => by simp)
  exact (G.colorable_iff_exists_bdd_nat_coloring k).2 ⟨C, fun v => Finset.mem_range.1 (hC v)⟩

#print axioms SimpleGraph.choosable_maxDegree_add_one
#print axioms SimpleGraph.Choosable.colorable

/-- The card's formula. In every finite graph, lists never need fewer colours than one shared box,
and never more than one past the busiest vertex's line count: χ(G) ≤ ch(G) ≤ Δ(G) + 1. -/
theorem chromaticNumber_le_choiceNumber_le_maxDegree_add_one {V : Type*} [Fintype V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    G.chromaticNumber ≤ G.choiceNumber ∧ G.choiceNumber ≤ G.maxDegree + 1 := by
  refine ⟨?_, ?_⟩
  · unfold SimpleGraph.choiceNumber
    refine le_iInf₂ fun k hk => ?_
    exact (SimpleGraph.Choosable.colorable hk).chromaticNumber_le
  · unfold SimpleGraph.choiceNumber
    have := iInf₂_le (f := fun (k : ℕ) (_ : k ∈ Set.ofPred G.Choosable) => (k : ℕ∞))
      (G.maxDegree + 1) (G.choosable_maxDegree_add_one)
    simpa using this

/-! The card's example: two masts P, Q (`inl 0`, `inl 1`) and four stations A, B, C, D
(`inr 0` to `inr 3`), every mast joined to every station: the graph K(2,4). -/

/-- K(2,4): two masts, four stations, every cross pair joined. -/
abbrev K24 : SimpleGraph (Fin 2 ⊕ Fin 4) := completeBipartiteGraph (Fin 2) (Fin 4)

instance : DecidableRel K24.Adj := fun u v =>
  inferInstanceAs (Decidable (u.isLeft ∧ v.isRight ∨ u.isRight ∧ v.isLeft))

/-- The card's six licences: P {1, 2}, Q {3, 4}, A {1, 3}, B {1, 4}, C {2, 3}, D {2, 4}. -/
def badLicences : Fin 2 ⊕ Fin 4 → Finset ℕ
  | .inl 0 => {1, 2}
  | .inl 1 => {3, 4}
  | .inr 0 => {1, 3}
  | .inr 1 => {1, 4}
  | .inr 2 => {2, 3}
  | .inr 3 => {2, 4}

/-- Lists can block where one shared box cannot: K(2,4) colours with two shared colours, and every
list of two is long enough on each vertex, yet the card's six licences admit no plan. -/
theorem k24_not_listColorable_badLicences :
    K24.Colorable 2 ∧ (∀ v, 2 ≤ (badLicences v).card) ∧ ¬ K24.ListColorable badLicences := by
  refine ⟨by simpa using (CompleteBipartiteGraph.bicoloring (Fin 2) (Fin 4)).colorable,
    by decide, ?_⟩
  rintro ⟨C, hC⟩
  have h0 := hC (.inl 0)
  have h1 := hC (.inl 1)
  have h2 := hC (.inr 0)
  have h3 := hC (.inr 1)
  have h4 := hC (.inr 2)
  have h5 := hC (.inr 3)
  simp only [badLicences, Finset.mem_insert, Finset.mem_singleton] at h0 h1 h2 h3 h4 h5
  have a0 := C.valid (show K24.Adj (.inl 0) (.inr 0) by decide)
  have a1 := C.valid (show K24.Adj (.inl 0) (.inr 1) by decide)
  have a2 := C.valid (show K24.Adj (.inl 0) (.inr 2) by decide)
  have a3 := C.valid (show K24.Adj (.inl 0) (.inr 3) by decide)
  have b0 := C.valid (show K24.Adj (.inl 1) (.inr 0) by decide)
  have b1 := C.valid (show K24.Adj (.inl 1) (.inr 1) by decide)
  have b2 := C.valid (show K24.Adj (.inl 1) (.inr 2) by decide)
  have b3 := C.valid (show K24.Adj (.inl 1) (.inr 3) by decide)
  omega

/-- K(2,4) needs two shared colours but lists of three: χ(K(2,4)) = 2 and ch(K(2,4)) = 3. -/
theorem k24_chromaticNumber_eq_two_choiceNumber_eq_three :
    K24.chromaticNumber = 2 ∧ K24.choiceNumber = 3 := by
  refine ⟨CompleteBipartiteGraph.chromaticNumber, ?_⟩
  have h3 : K24.Choosable 3 := by
    intro L hL
    have hp : ∀ i : Fin 2, ∃ x, x ∈ L (.inl i) := fun i =>
      Finset.card_pos.1 (lt_of_lt_of_le (by norm_num) (hL (.inl i)))
    choose p hp using hp
    have hs : ∀ j : Fin 4, ∃ x, x ∈ L (.inr j) ∧ x ∉ ({p 0, p 1} : Finset ℕ) := fun j =>
      Finset.exists_mem_notMem_of_card_lt_card
        (lt_of_lt_of_le (lt_of_le_of_lt Finset.card_le_two (by norm_num)) (hL (.inr j)))
    choose s hs hs' using hs
    refine ⟨Coloring.mk (Sum.elim p s) ?_, ?_⟩
    · intro u v h
      rcases u with i | j <;> rcases v with i' | j' <;>
        simp only [completeBipartiteGraph_adj, Sum.isLeft_inl, Sum.isRight_inr, Sum.isLeft_inr,
          Sum.isRight_inl] at h <;> simp at h
      · have := hs' j'
        simp only [Finset.mem_insert, Finset.mem_singleton, not_or] at this
        fin_cases i <;> simp [Ne.symm this.1, Ne.symm this.2]
      · have := hs' j
        simp only [Finset.mem_insert, Finset.mem_singleton, not_or] at this
        fin_cases i' <;> simp [this.1, this.2]
    · rintro (i | j)
      · exact hp i
      · exact hs j
  have hn : ∀ k, k ≤ 2 → ¬ K24.Choosable k := fun k hk h =>
    k24_not_listColorable_badLicences.2.2
      (h badLicences fun v => le_trans hk (k24_not_listColorable_badLicences.2.1 v))
  unfold SimpleGraph.choiceNumber
  refine le_antisymm ?_ ?_
  · have := iInf₂_le (f := fun (k : ℕ) (_ : k ∈ Set.ofPred K24.Choosable) => (k : ℕ∞)) 3 h3
    simpa using this
  · refine le_iInf₂ fun k hk => ?_
    have : 3 ≤ k := by
      by_contra hlt
      exact hn k (by omega) hk
    exact_mod_cast this

-- K(2,4) has 6 vertices, 8 lines, and 4 lines at each mast.
example : Fintype.card (Fin 2 ⊕ Fin 4) = 6 ∧ K24.edgeFinset.card = 8 ∧
    K24.degree (.inl 0) = 4 := by decide
-- Each of the masts' 2 × 2 = 4 choices is exactly one station's licence, so that station is blocked.
example : ∀ p ∈ badLicences (.inl 0), ∀ q ∈ badLicences (.inl 1),
    ∃ s : Fin 4, badLicences (.inr s) = {p, q} := by decide
-- All 2 ^ 6 = 64 ways to pick from the six licences of two.
example : (Finset.univ : Finset (Fin 2 ⊕ Fin 4)).prod (fun v => (badLicences v).card) = 64 ∧
    2 ^ 6 = 64 := by decide
-- Licence sets: 6 ^ 6 = 46,656 from four channels, 6 × 24 = 144 bad; 3 ^ 6 = 729 from three
-- channels; 4 ^ 6 = 4,096 sets of three-channel licences from four channels.
example : 6 ^ 6 = 46656 ∧ 6 * 24 = 144 ∧ 4 * 3 * 2 * 1 = 24 ∧ 3 ^ 6 = 729 ∧ 4 ^ 6 = 4096 := by
  norm_num

/-- The plan Thomassen's proof finds on licences of five: P1 Q5 A3 B4 C3 D2. -/
def plan : Fin 2 ⊕ Fin 4 → ℕ
  | .inl 0 => 1
  | .inl 1 => 5
  | .inr 0 => 3
  | .inr 1 => 4
  | .inr 2 => 3
  | .inr 3 => 2

-- Thomassen's result on licences of five (the bad ones plus 5, 6, 7): P1 Q5 A3 B4 C3 D2 is proper
-- on K(2,4) and on the added lines A-B, B-C, C-D, and each channel is on its licence.
example : (∀ u v, K24.Adj u v → plan u ≠ plan v) ∧
    (plan (.inr 0) ≠ plan (.inr 1) ∧ plan (.inr 1) ≠ plan (.inr 2) ∧
      plan (.inr 2) ≠ plan (.inr 3)) ∧
    ∀ v, plan v ∈ badLicences v ∪ {5, 6, 7} := by decide

#print axioms chromaticNumber_le_choiceNumber_le_maxDegree_add_one
#print axioms k24_not_listColorable_badLicences
#print axioms k24_chromaticNumber_eq_two_choiceNumber_eq_three
