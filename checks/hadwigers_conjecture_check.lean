-- Hadwiger's conjecture: the conjecture is stated exactly and left open, and the file proves its case t = 3 (a finite graph with no triangle minor takes 2 colours), the peeling rule of Step 0, and that the Petersen graph needs exactly 3 colours while having K(5) as a minor, with the card's whole-number counts.
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Tactic.NormNum
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Subgraph
import Mathlib.Tactic.FinCases
import Mathlib.Data.Fin.VecNotation

namespace HadwigersConjecture

open SimpleGraph

/-- `H` is a minor of `G`: `G` has pairwise disjoint branch sets, one per dot of `H`, each
joined among itself (its induced graph is connected, so in particular not empty), with a line
of `G` between two branch sets wherever `H` has a line. Fusing each branch set into one dot and
deleting what is left over turns `G` into `H`. Mathlib has no graph minors, so the definition
of the card [Graph minors] is written out here. -/
def IsMinor {W V : Type*} (H : SimpleGraph W) (G : SimpleGraph V) : Prop :=
  ∃ B : W → Set V,
    (∀ w, (G.induce (B w)).Connected) ∧
    Pairwise (fun a b => Disjoint (B a) (B b)) ∧
    ∀ a b, H.Adj a b → ∃ x ∈ B a, ∃ y ∈ B b, G.Adj x y

/-- Hadwiger's conjecture (1943), open for t ≥ 7 as of 2026-11-24: every finite graph with no
K(t) minor can be coloured with t - 1 colours. It is stated here and not proved. -/
def HadwigerConjectureStatement : Prop :=
  ∀ (t : ℕ) (V : Type) [Fintype V] (G : SimpleGraph V),
    ¬ IsMinor (⊤ : SimpleGraph (Fin t)) G → G.Colorable (t - 1)

/-- The case t = 3, proved on the card: a finite graph with no triangle K(3) as a minor has no
ring, so it is a forest, and it can be coloured with 2 colours. -/
theorem colorable_two_of_not_K3_minor {V : Type*} [Fintype V] (G : SimpleGraph V)
    (h : ¬ IsMinor (⊤ : SimpleGraph (Fin 3)) G) : G.Colorable 2 := by
  apply IsAcyclic.colorable_two
  intro v c hc
  apply h
  cases c with
  | nil => exact absurd hc (Walk.not_isCycle_nil)
  | @cons _ u _ hvu p =>
    rw [Walk.cons_isCycle_iff] at hc
    obtain ⟨hp, hedge⟩ := hc
    cases p with
    | nil => exact absurd hvu (G.loopless.irrefl _)
    | @cons _ x _ hux q =>
      rw [Walk.cons_isPath_iff] at hp
      obtain ⟨hq, huq⟩ := hp
      have hxv : x ≠ v := by
        rintro rfl
        apply hedge
        simp [Sym2.eq_swap]
      have hrp : q.reverse.IsPath := hq.reverse
      have hur : u ∉ q.reverse.support := by simpa using huq
      generalize q.reverse = r at hrp hur
      cases r with
      | nil => exact absurd rfl hxv
      | cons hvy r' =>
        rw [Walk.cons_isPath_iff] at hrp
        obtain ⟨-, hvr⟩ := hrp
        rw [Walk.support_cons, List.mem_cons, not_or] at hur
        obtain ⟨huv, hur'⟩ := hur
        refine ⟨![{v}, {u}, {z | z ∈ r'.support}], ?_, ?_, ?_⟩
        · intro w
          fin_cases w
          · simp only [Fin.zero_eta, Fin.isValue, Matrix.cons_val_zero, induce_singleton_eq_top]
            exact connected_top
          · simp only [Fin.mk_one, Fin.isValue, Matrix.cons_val_one, Matrix.cons_val_zero,
              induce_singleton_eq_top]
            exact connected_top
          · exact r'.connected_induce_support
        · intro a b hab
          fin_cases a <;> fin_cases b <;> simp_all [Set.disjoint_left, eq_comm]
          all_goals rintro z hz rfl; contradiction
        · intro a b hab
          fin_cases a <;> fin_cases b <;> simp at hab
          · exact ⟨v, rfl, u, rfl, hvu⟩
          · exact ⟨v, rfl, _, r'.start_mem_support, hvy⟩
          · exact ⟨u, rfl, v, rfl, hvu.symm⟩
          · exact ⟨u, rfl, x, r'.end_mem_support, hux⟩
          · exact ⟨_, r'.start_mem_support, v, rfl, hvy.symm⟩
          · exact ⟨x, r'.end_mem_support, u, rfl, hux.symm⟩

/-- Step 0, peeling: if every nonempty set of dots of a finite graph contains a dot with at most
`d` neighbours inside that set, then `d + 1` colours suffice. -/
theorem colorable_succ_of_forall_exists_degree_le {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (d : ℕ)
    (h : ∀ s : Finset V, s.Nonempty → ∃ v ∈ s, (s.filter (G.Adj v)).card ≤ d) :
    G.Colorable (d + 1) := by
  have key : ∀ s : Finset V, ∃ f : V → Fin (d + 1),
      ∀ x ∈ s, ∀ y ∈ s, G.Adj x y → f x ≠ f y := by
    intro s
    induction s using Finset.strongInduction with
    | H s ih =>
      rcases s.eq_empty_or_nonempty with rfl | hs
      · exact ⟨fun _ => 0, by simp⟩
      obtain ⟨v, hv, hdeg⟩ := h s hs
      obtain ⟨f, hf⟩ := ih (s.erase v) (Finset.erase_ssubset hv)
      have hlt : ((s.filter (G.Adj v)).image f).card
          < (Finset.univ : Finset (Fin (d + 1))).card := by
        calc ((s.filter (G.Adj v)).image f).card ≤ (s.filter (G.Adj v)).card :=
              Finset.card_image_le
          _ ≤ d := hdeg
          _ < d + 1 := Nat.lt_succ_self d
          _ = _ := by simp
      obtain ⟨c, -, hc⟩ := Finset.exists_mem_notMem_of_card_lt_card hlt
      refine ⟨Function.update f v c, ?_⟩
      intro x hx y hy hxy
      by_cases hxv : x = v
      · subst hxv
        have hyv : y ≠ x := (G.ne_of_adj hxy).symm
        rw [Function.update_self, Function.update_of_ne hyv]
        intro hcy
        exact hc (Finset.mem_image.2 ⟨y, Finset.mem_filter.2 ⟨hy, hxy⟩, hcy.symm⟩)
      · by_cases hyv : y = v
        · subst hyv
          rw [Function.update_self, Function.update_of_ne hxv]
          intro hcx
          exact hc (Finset.mem_image.2 ⟨x, Finset.mem_filter.2 ⟨hx, hxy.symm⟩, hcx⟩)
        · rw [Function.update_of_ne hxv, Function.update_of_ne hyv]
          exact hf x (Finset.mem_erase.2 ⟨hxv, hx⟩) y (Finset.mem_erase.2 ⟨hyv, hy⟩) hxy
  obtain ⟨f, hf⟩ := key Finset.univ
  exact ⟨Coloring.mk f fun {x y} hxy => hf x (Finset.mem_univ _) y (Finset.mem_univ _) hxy⟩

/-- The links of the Petersen graph, numbered as on the card: an outer ring 0-1-2-3-4, five
spokes `i`-`(i+5)`, and an inner five-pointed star joining `5 + i` to `5 + (i + 2) % 5`. -/
def petersenLinks : List (Fin 10 × Fin 10) :=
  [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0),
   (5, 7), (6, 8), (7, 9), (8, 5), (9, 6),
   (0, 5), (1, 6), (2, 7), (3, 8), (4, 9)]

/-- The Petersen graph: 10 dots, 15 lines. -/
def petersen : SimpleGraph (Fin 10) where
  Adj x y := (x, y) ∈ petersenLinks ∨ (y, x) ∈ petersenLinks
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel petersen.Adj := fun _ _ =>
  inferInstanceAs (Decidable (_ ∨ _))

/-- The card's lead example: the Petersen graph needs exactly 3 colours, yet contracting its
five spokes gives K(5) as a minor, so its colour count sits below its largest complete minor. -/
theorem petersen_chromaticNumber_eq_three_and_K5_minor :
    petersen.chromaticNumber = 3 ∧ IsMinor (⊤ : SimpleGraph (Fin 5)) petersen := by
  constructor
  · have h3 : petersen.Colorable 3 := by
      let f : Fin 10 → Fin 3 := ![0, 1, 0, 1, 2, 1, 0, 2, 2, 1]
      have hf : ∀ u v : Fin 10, petersen.Adj u v → f u ≠ f v := by decide
      exact ⟨Coloring.mk f fun {u v} huv => hf u v huv⟩
    have h2 : ¬ petersen.Colorable 2 := by
      rintro ⟨C⟩
      have key : ∀ a b c d e : Fin 2, a ≠ b → b ≠ c → c ≠ d → d ≠ e → e ≠ a → False := by
        intro a b c d e h1 h2 h3 h4 h5
        fin_cases a <;> fin_cases b <;> fin_cases c <;> fin_cases d <;> fin_cases e <;> simp_all
      exact key _ _ _ _ _ (C.valid (by decide : petersen.Adj 0 1))
        (C.valid (by decide : petersen.Adj 1 2)) (C.valid (by decide : petersen.Adj 2 3))
        (C.valid (by decide : petersen.Adj 3 4)) (C.valid (by decide : petersen.Adj 4 0))
    have := (chromaticNumber_eq_iff_colorable_not_colorable (G := petersen) (n := 2)).2 ⟨h3, h2⟩
    exact_mod_cast this
  · refine ⟨![{0, 5}, {1, 6}, {2, 7}, {3, 8}, {4, 9}], ?_, ?_, ?_⟩
    · intro w
      fin_cases w <;> exact induce_pair_connected_of_adj (by decide)
    · intro a b hab
      fin_cases a <;> fin_cases b <;> simp at hab <;> simp [Set.disjoint_left]
    · intro a b hab
      fin_cases a <;> fin_cases b <;> simp at hab <;> simp <;> decide

-- Petersen: 10 dots and 15 lines.
example : (Finset.univ.filter (fun p : Fin 10 × Fin 10 => p.1 < p.2 ∧ petersen.Adj p.1 p.2)).card
    = 15 := by decide

-- K(2,2,2,2,2): 10 dots in 5 pairs, each joined to the 8 dots outside its pair, 40 lines.
example : (Finset.univ.filter (fun p : Fin 10 × Fin 10 =>
    p.1 < p.2 ∧ p.1.val / 2 ≠ p.2.val / 2)).card = 40 := by decide

-- Mader's line count at t = 8 allows 6 × 10 - 21 = 39 lines, fewer than 40.
example : (8 - 2) * 10 - (8 - 1) * (8 - 2) / 2 = 39 ∧ 39 < 40 := by norm_num

-- A K(6) branch set of s dots in the Petersen graph has at most s + 2 exits and needs 5, so
-- s ≥ 3, and six such sets need 18 dots, more than 10.
example : 3 * 3 - 2 * (3 - 1) = 5 ∧ 3 * 2 - 2 * (2 - 1) < 5 ∧ 6 * 3 = 18 ∧ 10 < 18 := by norm_num

-- The Moser spindle: 3^7 = 2,187 ways to give its 7 dots 3 colours.
example : 3 ^ 7 = 2187 := by norm_num

-- The table for t from 3 to 7: the conjecture's t - 1 and Mader's line count road 2t - 4.
example : (List.range 5).map (fun i => (i + 3 - 1, 2 * (i + 3) - 4))
    = [(2, 2), (3, 4), (4, 6), (5, 8), (6, 10)] := by decide

#print axioms colorable_two_of_not_K3_minor
#print axioms colorable_succ_of_forall_exists_degree_le
#print axioms petersen_chromaticNumber_eq_three_and_K5_minor

end HadwigersConjecture
