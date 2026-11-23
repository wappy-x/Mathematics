-- Cycle double cover: the conjecture is stated exactly and left open, and the file proves that a graph with a bridge has no cycle double cover, that a cubic graph whose lines take three colours has one, and that six pentagons cover the Petersen graph, with the card's whole-number examples.
import Mathlib.Combinatorics.SimpleGraph.Paths
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Subgraph
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.SimpleGraph.LineGraph
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Combinatorics.SimpleGraph.Matching

open SimpleGraph

theorem length_filter_toList_eq_card {α : Type*} (s : Finset α) (p : α → Prop) [DecidablePred p] :
    (s.toList.filter (fun a => p a)).length = (s.filter p).card := by
  rw [Finset.card_def, Finset.filter_val, ← Finset.coe_toList s, Multiset.filter_coe,
    Multiset.coe_card]

theorem exists_cycle_mem_edges_of_even_degree {V : Type*} [Fintype V] [DecidableEq V]
    (H : SimpleGraph V) [DecidableRel H.Adj] (heven : ∀ v, Even (H.degree v)) {u v : V}
    (huv : H.Adj u v) : ∃ (w : V) (p : H.Walk w w), p.IsCycle ∧ s(u, v) ∈ p.edges := by
  by_contra hcon
  push Not at hcon
  have hb : H.IsBridge s(u, v) :=
    (isBridge_iff_forall_cycle_notMem huv).2 (fun w p hp => hcon w p hp)
  rw [isBridge_iff] at hb
  classical
  set H' := H.deleteEdges {s(u, v)} with hH'
  let K : SimpleGraph V :=
    { Adj := fun x y => H'.Adj x y ∧ H'.Reachable u x
      symm := ⟨fun x y h => ⟨h.1.symm, h.2.trans h.1.reachable⟩⟩
      loopless := ⟨fun x h => h.1.ne rfl⟩ }
  have hKadj : ∀ x y, K.Adj x y ↔ H'.Adj x y ∧ H'.Reachable u x := fun _ _ => Iff.rfl
  have key : (Finset.univ.filter fun x => Odd (K.degree x)) = {u} := by
    ext x
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_singleton]
    constructor
    · intro hx
      by_contra hxu
      by_cases hr : H'.Reachable u x
      · have hxv : x ≠ v := by rintro rfl; exact hb hr
        have hN : K.neighborFinset x = H.neighborFinset x := by
          ext y
          simp only [mem_neighborFinset, hKadj, hH', deleteEdges_adj, Set.mem_singleton_iff,
            Sym2.eq_iff]
          constructor
          · exact fun h => h.1.1
          · intro h; refine ⟨⟨h, ?_⟩, hr⟩; rintro (⟨rfl, -⟩ | ⟨rfl, -⟩) <;> simp_all
        rw [← card_neighborFinset_eq_degree, hN, card_neighborFinset_eq_degree] at hx
        exact (Nat.not_odd_iff_even.2 (heven x)) hx
      · have hN : K.neighborFinset x = ∅ := by
          ext y; simp [mem_neighborFinset, hKadj, hr]
        rw [← card_neighborFinset_eq_degree, hN] at hx
        simp at hx
    · rintro rfl
      have hN : K.neighborFinset x = (H.neighborFinset x).erase v := by
        ext y
        simp only [mem_neighborFinset, hKadj, hH', deleteEdges_adj, Set.mem_singleton_iff,
          Finset.mem_erase, Reachable.refl, and_true]
        constructor
        · rintro ⟨h1, h2⟩; exact ⟨fun h => h2 (by rw [h]), h1⟩
        · rintro ⟨h1, h2⟩; exact ⟨h2, fun h => h1 (Sym2.congr_right.1 h)⟩
      rw [← card_neighborFinset_eq_degree, hN, Finset.card_erase_of_mem
        ((mem_neighborFinset _ _ _).2 huv), card_neighborFinset_eq_degree]
      obtain ⟨k, hk⟩ := heven x
      have : 1 ≤ H.degree x := H.degree_pos_iff_exists_adj x |>.2 ⟨v, huv⟩
      exact ⟨k - 1, by omega⟩
  have := K.even_card_odd_degree_vertices
  rw [key] at this
  simp at this

theorem mem_edges_of_isCycle_of_degree_le_two {V : Type*} [Fintype V] [DecidableEq V]
    (H : SimpleGraph V) [DecidableRel H.Adj] (hdeg : ∀ v, H.degree v ≤ 2) {w : V}
    {p : H.Walk w w} (hp : p.IsCycle) {x y : V} (hx : x ∈ p.support) (hxy : H.Adj x y) :
    s(x, y) ∈ p.edges := by
  rw [← Walk.adj_toSubgraph_iff_mem_edges]
  have h2 := hp.ncard_neighborSet_toSubgraph_eq_two hx
  have hsub : p.toSubgraph.neighborSet x ⊆ H.neighborSet x := p.toSubgraph.neighborSet_subset x
  have heq : p.toSubgraph.neighborSet x = H.neighborSet x := by
    apply Set.eq_of_subset_of_ncard_le hsub _ (Set.toFinite _)
    rw [h2, ← coe_neighborFinset, Set.ncard_coe_finset, card_neighborFinset_eq_degree]
    exact hdeg x
  have : y ∈ p.toSubgraph.neighborSet x := by rw [heq]; exact hxy
  exact this

theorem edges_subset_of_isCycle_of_degree_le_two {V : Type*} [Fintype V] [DecidableEq V]
    (H : SimpleGraph V) [DecidableRel H.Adj] (hdeg : ∀ v, H.degree v ≤ 2) {a b : V}
    {p : H.Walk a a} {q : H.Walk b b} (hp : p.IsCycle) {e : Sym2 V} (hep : e ∈ p.edges)
    (heq : e ∈ q.edges) : q.edges.toFinset ⊆ p.edges.toFinset := by
  have hclosed : ∀ {x y : V} (r : H.Walk x y), x ∈ p.support → y ∈ p.support := by
    intro x y r
    induction r with
    | nil => exact id
    | cons h r ih =>
      intro hx
      exact ih (p.snd_mem_support_of_mem_edges
        (mem_edges_of_isCycle_of_degree_le_two H hdeg hp hx h))
  induction e using Sym2.ind with
  | _ c d =>
  have hcq : c ∈ q.support := q.fst_mem_support_of_mem_edges heq
  have hb : b ∈ p.support := hclosed (q.dropUntil c hcq) (p.fst_mem_support_of_mem_edges hep)
  intro f hf
  rw [List.mem_toFinset] at hf ⊢
  induction f using Sym2.ind with
  | _ x y =>
  have hxq : x ∈ q.support := q.fst_mem_support_of_mem_edges hf
  exact mem_edges_of_isCycle_of_degree_le_two H hdeg hp (hclosed (q.takeUntil x hxq) hb)
    (q.adj_of_mem_edges hf)

#print axioms length_filter_toList_eq_card
#print axioms exists_cycle_mem_edges_of_even_degree
#print axioms mem_edges_of_isCycle_of_degree_le_two
#print axioms edges_subset_of_isCycle_of_degree_le_two

/-! A graph is a finite simple graph `G : SimpleGraph V` (dots `V`, lines `G.edgeSet`).
A cycle is recorded by the set of its lines; the cover is a `List`, so repeats are allowed. -/

/-- `C` is the set of lines of some cycle of `G`: a closed walk that repeats no dot. -/
def IsCycleEdges {V : Type*} [DecidableEq V] (G : SimpleGraph V) (C : Finset (Sym2 V)) : Prop :=
  ∃ (u : V) (p : G.Walk u u), p.IsCycle ∧ p.edges.toFinset = C

/-- A cycle double cover of `G`: a list of cycles of `G` (repeats allowed) such that every
line of `G` lies on exactly two cycles of the list. -/
def IsCycleDoubleCover {V : Type*} [DecidableEq V] (G : SimpleGraph V)
    (L : List (Finset (Sym2 V))) : Prop :=
  (∀ C ∈ L, IsCycleEdges G C) ∧ ∀ e ∈ G.edgeSet, (L.filter (fun C => e ∈ C)).length = 2

/-- The cycle double cover conjecture (Szekeres 1973, Seymour 1979; claimed proved in
July 2026, not refereed as of 2026-11-23, so the card does not prove it): every finite graph
with no bridge has a list of cycles passing along every line exactly twice. -/
def CycleDoubleCoverConjecture : Prop :=
  ∀ (V : Type) [Fintype V] [DecidableEq V] (G : SimpleGraph V),
    (∀ e ∈ G.edgeSet, ¬ G.IsBridge e) → ∃ L, IsCycleDoubleCover G L

/-- A graph with a bridge has no cycle double cover: a bridge lies on no cycle, so no list of
cycles passes along it at all. This is why the conjecture asks for a graph with no bridge. -/
theorem not_exists_cycleDoubleCover_of_isBridge {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) (e : Sym2 V) (he : e ∈ G.edgeSet) (hb : G.IsBridge e) :
    ¬ ∃ L, IsCycleDoubleCover G L := by
  rintro ⟨L, hcyc, hcount⟩
  have h2 := hcount e he
  have hne : L.filter (fun C => e ∈ C) ≠ [] := by
    intro h; rw [h] at h2; simp at h2
  obtain ⟨C, hC⟩ := List.exists_mem_of_ne_nil _ hne
  rw [List.mem_filter, decide_eq_true_eq] at hC
  obtain ⟨u, p, hp, rfl⟩ := hcyc C hC.1
  exact hb.notMem_edges_of_isCycle hp (List.mem_toFinset.1 hC.2)

/-- Three colours give a cover: if every dot of `G` meets exactly three lines and the lines
can be coloured with three colours so that the lines at each dot all differ, then `G` has a
cycle double cover (the cycles made by each pair of colours). -/
theorem exists_cycleDoubleCover_of_cubic_of_edge_three_colorable {V : Type*} [Fintype V]
    [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj] (hcubic : ∀ v, G.degree v = 3)
    (hcol : G.lineGraph.Colorable 3) :
    ∃ L, IsCycleDoubleCover G L := by
  classical
  obtain ⟨c⟩ := hcol
  let col : Sym2 V → Fin 3 := fun e => if h : e ∈ G.edgeSet then c ⟨e, h⟩ else 0
  have hcol_ne : ∀ {v w w' : V}, G.Adj v w → G.Adj v w' → w ≠ w' →
      col s(v, w) ≠ col s(v, w') := by
    intro v w w' h h' hne
    simp only [col, show s(v, w) ∈ G.edgeSet from h, show s(v, w') ∈ G.edgeSet from h',
      ↓reduceDIte]
    apply c.valid
    rw [lineGraph_adj_iff_exists]
    refine ⟨?_, v, by simp, by simp⟩
    intro heq
    exact hne (Sym2.congr_right.1 (congrArg Subtype.val heq))
  let H : Fin 3 → SimpleGraph V := fun k => G.deleteEdges {e | col e = k}
  have hHle : ∀ k, H k ≤ G := fun k => deleteEdges_le _
  have hHedge : ∀ k e, e ∈ (H k).edgeSet ↔ e ∈ G.edgeSet ∧ col e ≠ k := by
    intro k e
    simp [H, edgeSet_deleteEdges]
  have hdeg : ∀ k v, (H k).degree v = 2 := by
    intro k v
    have hN : (H k).neighborFinset v =
        (G.neighborFinset v).filter (fun w => col s(v, w) ≠ k) := by
      ext w; simp [H, mem_neighborFinset]
    rw [← card_neighborFinset_eq_degree, hN]
    have hinj : Set.InjOn (fun w => col s(v, w)) (G.neighborFinset v : Set V) := by
      intro w hw w' hw' heq
      by_contra hne
      exact hcol_ne ((mem_neighborFinset _ _ _).1 hw) ((mem_neighborFinset _ _ _).1 hw') hne heq
    have himg : (G.neighborFinset v).image (fun w => col s(v, w)) = Finset.univ := by
      apply Finset.eq_univ_of_card
      rw [Finset.card_image_of_injOn hinj, card_neighborFinset_eq_degree, hcubic]
      simp
    have hfi : ((G.neighborFinset v).filter (fun w => col s(v, w) ≠ k)).image
        (fun w => col s(v, w)) = Finset.univ.filter (fun x => x ≠ k) := by
      rw [← himg, Finset.filter_image]
    rw [← Finset.card_image_of_injOn
      (hinj.mono (Finset.coe_subset.2 (Finset.filter_subset _ _))), hfi,
      Finset.filter_ne' Finset.univ k, Finset.card_erase_of_mem (Finset.mem_univ _)]
    simp
  let P : Fin 3 → Sym2 V → Prop := fun k e =>
    ∃ (w : V) (p : (H k).Walk w w), p.IsCycle ∧ e ∈ p.edges
  have hP : ∀ k e, e ∈ (H k).edgeSet → P k e := by
    intro k e he
    induction e using Sym2.ind with
    | _ x y =>
    exact exists_cycle_mem_edges_of_even_degree (H k) (fun v => by rw [hdeg]; decide) he
  let cyc : Fin 3 → Sym2 V → Finset (Sym2 V) := fun k e =>
    if h : P k e then h.choose_spec.choose.edges.toFinset else ∅
  have hcyc_spec : ∀ k e, e ∈ (H k).edgeSet →
      ∃ (w : V) (p : (H k).Walk w w), p.IsCycle ∧ e ∈ p.edges ∧
        cyc k e = p.edges.toFinset := by
    intro k e he
    have h := hP k e he
    refine ⟨h.choose, h.choose_spec.choose, h.choose_spec.choose_spec.1,
      h.choose_spec.choose_spec.2, ?_⟩
    simp only [cyc, h, ↓reduceDIte]
  have hdeg2 : ∀ k v, (H k).degree v ≤ 2 := fun k v => (hdeg k v).le
  -- each chosen cycle is a cycle of `G` and contains its line
  have hF1 : ∀ k e, e ∈ (H k).edgeSet → e ∈ cyc k e ∧ IsCycleEdges G (cyc k e) := by
    intro k e he
    obtain ⟨w, p, hp, hep, hc⟩ := hcyc_spec k e he
    refine ⟨by rw [hc]; exact List.mem_toFinset.2 hep, w, p.mapLe (hHle k), hp.mapLe _, ?_⟩
    rw [Walk.edges_mapLe_eq_edges, hc]
  have hF2 : ∀ k e e', e ∈ (H k).edgeSet → e' ∈ cyc k e → cyc k e' = cyc k e := by
    intro k e e' he he'
    obtain ⟨w, p, hp, hep, hc⟩ := hcyc_spec k e he
    rw [hc] at he' ⊢
    have he'p : e' ∈ p.edges := List.mem_toFinset.1 he'
    obtain ⟨w', q, hq, heq, hc'⟩ := hcyc_spec k e' (p.edges_subset_edgeSet he'p)
    rw [hc']
    exact Finset.Subset.antisymm
      (edges_subset_of_isCycle_of_degree_le_two (H k) (hdeg2 k) hp he'p heq)
      (edges_subset_of_isCycle_of_degree_le_two (H k) (hdeg2 k) hq heq he'p)
  have hF3 : ∀ k e e', e' ∈ cyc k e → e' ∈ (H k).edgeSet := by
    intro k e e' he'
    by_cases h : P k e
    · simp only [cyc, h, ↓reduceDIte] at he'
      exact Walk.edges_subset_edgeSet _ (List.mem_toFinset.1 he')
    · simp [cyc, h] at he'
  let S : Fin 3 → Finset (Finset (Sym2 V)) := fun k => (H k).edgeFinset.image (cyc k)
  have hS : ∀ k e, (S k).filter (fun C => e ∈ C) =
      if e ∈ (H k).edgeSet then {cyc k e} else ∅ := by
    intro k e
    split_ifs with he
    · ext C
      simp only [Finset.mem_filter, Finset.mem_image, mem_edgeFinset, Finset.mem_singleton, S]
      constructor
      · rintro ⟨⟨e', he', rfl⟩, hC⟩
        exact (hF2 k e' e he' hC).symm
      · rintro rfl
        exact ⟨⟨e, he, rfl⟩, (hF1 k e he).1⟩
    · ext C
      simp only [Finset.mem_filter, Finset.mem_image, mem_edgeFinset, Finset.notMem_empty,
        iff_false, not_and, S]
      rintro ⟨e', -, rfl⟩ hC
      exact he (hF3 k e' e hC)
  refine ⟨(S 0).toList ++ (S 1).toList ++ (S 2).toList, ?_, ?_⟩
  · intro C hC
    have hmem : ∀ k, C ∈ (S k).toList → IsCycleEdges G C := by
      intro k hk
      rw [Finset.mem_toList] at hk
      obtain ⟨e, he, rfl⟩ := Finset.mem_image.1 hk
      exact (hF1 k e (mem_edgeFinset.1 he)).2
    simp only [List.mem_append] at hC
    rcases hC with (h | h) | h
    · exact hmem 0 h
    · exact hmem 1 h
    · exact hmem 2 h
  · intro e he
    simp only [List.filter_append, List.length_append]
    rw [length_filter_toList_eq_card (S 0) (fun C => e ∈ C),
      length_filter_toList_eq_card (S 1) (fun C => e ∈ C),
      length_filter_toList_eq_card (S 2) (fun C => e ∈ C), hS, hS, hS]
    simp only [hHedge, he, true_and]
    generalize col e = j
    fin_cases j <;> simp

/-- The Petersen graph, numbered as on the card: outer pentagon 0-1-2-3-4, spokes `i`-`(i+5)`,
inner star `5+i`-`5+((i+2) mod 5)`. -/
def petersenRel (a b : Fin 10) : Prop :=
  (a.val < 5 ∧ b.val < 5 ∧ b.val = (a.val + 1) % 5) ∨
  (a.val < 5 ∧ b.val = a.val + 5) ∨
  (5 ≤ a.val ∧ 5 ≤ b.val ∧ b.val = 5 + (a.val - 5 + 2) % 5)

instance : DecidableRel petersenRel := fun a b => by unfold petersenRel; infer_instance

/-- The Petersen graph: 10 dots, 15 lines. -/
def petersen : SimpleGraph (Fin 10) := SimpleGraph.fromRel petersenRel

instance : DecidableRel petersen.Adj := by unfold petersen; infer_instance

theorem isCycleEdges_of_five {V : Type*} [DecidableEq V] {G : SimpleGraph V} {a b c d f : V}
    (h1 : G.Adj a b) (h2 : G.Adj b c) (h3 : G.Adj c d) (h4 : G.Adj d f) (h5 : G.Adj f a)
    (hnd : [b, c, d, f, a].Nodup) (hed : [s(a, b), s(b, c), s(c, d), s(d, f), s(f, a)].Nodup) :
    IsCycleEdges G {s(a, b), s(b, c), s(c, d), s(d, f), s(f, a)} := by
  refine ⟨a, .cons h1 (.cons h2 (.cons h3 (.cons h4 (.cons h5 .nil)))), ?_, ?_⟩
  · rw [Walk.isCycle_def, Walk.isTrail_def]
    exact ⟨hed, by simp, hnd⟩
  · ext x; simp

#print axioms isCycleEdges_of_five

/-- The Petersen graph has a cycle double cover made of six pentagons (cycles of 5 lines),
although it has no flat drawing and no 3-colouring of its lines. -/
theorem petersen_cycleDoubleCover_six_pentagons :
    ∃ L, IsCycleDoubleCover petersen L ∧ L.length = 6 ∧ ∀ C ∈ L, C.card = 5 := by
  refine ⟨[{s(0, 1), s(1, 2), s(2, 3), s(3, 4), s(4, 0)},
    {s(0, 4), s(4, 9), s(9, 7), s(7, 5), s(5, 0)},
    {s(2, 3), s(3, 8), s(8, 5), s(5, 7), s(7, 2)},
    {s(0, 1), s(1, 6), s(6, 8), s(8, 5), s(5, 0)},
    {s(3, 4), s(4, 9), s(9, 6), s(6, 8), s(8, 3)},
    {s(1, 2), s(2, 7), s(7, 9), s(9, 6), s(6, 1)}], ⟨?_, ?_⟩, rfl, ?_⟩
  · intro C hC
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hC
    rcases hC with rfl | rfl | rfl | rfl | rfl | rfl <;>
      exact isCycleEdges_of_five (by decide) (by decide) (by decide) (by decide) (by decide)
        (by decide) (by decide)
  · intro e he
    rw [← mem_edgeFinset] at he
    revert e
    decide
  · intro C hC
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hC
    rcases hC with rfl | rfl | rfl | rfl | rfl | rfl <;> decide

/-- The card's six pentagons, as sets of lines: 0-1-2-3-4, 0-4-9-7-5, 2-3-8-5-7, 0-1-6-8-5,
3-4-9-6-8, 1-2-7-9-6. -/
def petersenPentagons : List (Finset (Sym2 (Fin 10))) :=
  [{s(0, 1), s(1, 2), s(2, 3), s(3, 4), s(4, 0)},
   {s(0, 4), s(4, 9), s(9, 7), s(7, 5), s(5, 0)},
   {s(2, 3), s(3, 8), s(8, 5), s(5, 7), s(7, 2)},
   {s(0, 1), s(1, 6), s(6, 8), s(8, 5), s(5, 0)},
   {s(3, 4), s(4, 9), s(9, 6), s(6, 8), s(8, 3)},
   {s(1, 2), s(2, 7), s(7, 9), s(9, 6), s(6, 1)}]

-- The Petersen graph has 15 lines.
example : petersen.edgeFinset.card = 15 := by decide

-- Every line of the Petersen graph lies on exactly two of the six pentagons (line slots 30).
example : ∀ e ∈ petersen.edgeFinset, (petersenPentagons.filter (fun C => e ∈ C)).length = 2 := by
  decide

-- Each pentagon has 5 lines.
example : petersenPentagons.map Finset.card = [5, 5, 5, 5, 5, 5] := by decide

-- Together the pentagons use exactly the 15 lines of the Petersen graph.
example : petersenPentagons.foldr (· ∪ ·) ∅ = petersen.edgeFinset := by decide

-- Line slots: six pentagons give 6 × 5 = 30 = 2 × 15.
example : 6 * 5 = 2 * 15 := by norm_num

-- The pentagons as faces: V − E + F = 10 − 15 + 6 = 1, the projective plane.
example : (10 : ℤ) - 15 + 6 = 1 := by norm_num

-- The smallest cover found: lengths 5 + 5 + 5 + 6 + 9 = 30 = 2 × 15.
example : 5 + 5 + 5 + 6 + 9 = 2 * 15 := by norm_num

-- Fewest cycles possible: longest cycle 9, so at least 30 ÷ 9 rounded up, which is 4.
example : (30 + 9 - 1) / 9 = 4 := by norm_num

-- Not flat: a flat drawing with faces of at least 5 sides has 3 × E ≤ 5 × (V − 2); 45 > 40.
example : ¬ (3 * 15 ≤ 5 * (10 - 2)) := by norm_num

-- The flat cube: Euler's count gives F = E − V + 2 = 12 − 8 + 2 = 6 faces.
example : 12 - 8 + 2 = 6 := by norm_num

#print axioms not_exists_cycleDoubleCover_of_isBridge
#print axioms exists_cycleDoubleCover_of_cubic_of_edge_three_colorable
#print axioms petersen_cycleDoubleCover_six_pentagons
