-- The cheapest skeleton: in a connected graph with fixed real weights on its edges, a cheapest edge across any split of the vertices lies in some cheapest spanning tree, and stays addable to any kept set that already sits inside one, an edge dearer than every other on a loop lies in no cheapest spanning tree, and the card's seven-building campus gives Kruskal's and Prim's six runs at 39, with 141 of the 462 six-run sets joining all seven and only one of them at 39.
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

open SimpleGraph

variable {V : Type*} [Fintype V] [DecidableEq V]

open Classical in
/-- A minimum spanning tree of `G` for the weights `w`: a subgraph `T` of `G` that is a tree
(it joins every vertex and holds no loop), whose weights add up to no more than those of any
other spanning tree of `G`. -/
def IsMinSpanningTree (G T : SimpleGraph V) (w : Sym2 V → ℝ) : Prop :=
  T ≤ G ∧ T.IsTree ∧
    ∀ T' : SimpleGraph V, T' ≤ G → T'.IsTree →
      ∑ e ∈ T.edgeFinset, w e ≤ ∑ e ∈ T'.edgeFinset, w e


/-! ### Helper lemmas: swapping one tree edge for another -/

/-- From any vertex, a walk in `T` shows the vertex reaches `x` or `y` once the edge `xy` is
removed. -/
lemma mst_reach_x_or_y (T : SimpleGraph V) (x y : V) {z t : V} (p : T.Walk z t)
    (ht : (T.deleteEdges {s(x, y)}).Reachable t x ∨ (T.deleteEdges {s(x, y)}).Reachable t y) :
    (T.deleteEdges {s(x, y)}).Reachable z x ∨ (T.deleteEdges {s(x, y)}).Reachable z y := by
  induction p with
  | nil => exact ht
  | @cons a b c hab p ih =>
    have h := ih ht
    by_cases he : s(a, b) = s(x, y)
    · rcases Sym2.eq_iff.1 he with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
      · exact Or.inl Reachable.rfl
      · exact Or.inr Reachable.rfl
    · have hab' : (T.deleteEdges {s(x, y)}).Adj a b := by
        rw [deleteEdges_adj]; exact ⟨hab, by simpa using he⟩
      exact h.imp (hab'.reachable.trans ·) (hab'.reachable.trans ·)

/-- Swapping the tree edge `xy` for a new edge `uv`, where every tree walk from `u` to `v`
uses `xy`, gives a tree again, with the expected edge set. -/
lemma mst_swap_isTree (T : SimpleGraph V) (hT : T.IsTree) {x y u v : V} (hxy : T.Adj x y)
    (huv : u ≠ v) (hnr : ∀ p : T.Walk u v, s(x, y) ∈ p.edges) :
    (fromEdgeSet (insert s(u, v) (T.edgeSet \ {s(x, y)}))).IsTree ∧
    (fromEdgeSet (insert s(u, v) (T.edgeSet \ {s(x, y)}))).edgeSet =
      insert s(u, v) (T.edgeSet \ {s(x, y)}) ∧
    s(u, v) ∉ T.edgeSet \ {s(x, y)} := by
  set T' := fromEdgeSet (insert s(u, v) (T.edgeSet \ {s(x, y)})) with hT'def
  have hnr' : ¬ (T.deleteEdges {s(x, y)}).Reachable u v := by
    rw [reachable_deleteEdges_iff_exists_walk]; rintro ⟨p, hp⟩; exact hp (hnr p)
  have hnot : s(u, v) ∉ T.edgeSet \ {s(x, y)} := by
    rintro ⟨h1, h2⟩
    exact hnr' (deleteEdges_adj.2 ⟨h1, h2⟩).reachable
  have hES : T'.edgeSet = insert s(u, v) (T.edgeSet \ {s(x, y)}) := by
    rw [hT'def, edgeSet_fromEdgeSet]
    ext g
    constructor
    · exact fun h => h.1
    · intro h
      refine ⟨h, ?_⟩
      rcases h with rfl | ⟨hg, -⟩
      · simpa using huv
      · exact T.not_isDiag_of_mem_edgeSet hg
  have hle : T.deleteEdges {s(x, y)} ≤ T' := by
    intro a b hab
    rw [hT'def, fromEdgeSet_adj]
    rw [deleteEdges_adj] at hab
    exact ⟨Or.inr ⟨hab.1, hab.2⟩, hab.1.ne⟩
  have hT'uv : T'.Adj u v := by rw [hT'def, fromEdgeSet_adj]; exact ⟨Or.inl rfl, huv⟩
  have hall : ∀ z, (T.deleteEdges {s(x, y)}).Reachable z x ∨
      (T.deleteEdges {s(x, y)}).Reachable z y :=
    fun z => mst_reach_x_or_y T x y (hT.connected.preconnected z x).some (Or.inl Reachable.rfl)
  have hxy' : T'.Reachable x y := by
    rcases hall u with hu | hu <;> rcases hall v with hv | hv
    · exact absurd (hu.trans hv.symm) hnr'
    · exact ((hu.symm.mono hle).trans hT'uv.reachable).trans (hv.mono hle)
    · exact ((hv.symm.mono hle).trans hT'uv.symm.reachable).trans (hu.mono hle)
    · exact absurd (hu.trans hv.symm) hnr'
  have hconn : T'.Connected := by
    have : Nonempty V := ⟨u⟩
    have hx : ∀ a, T'.Reachable a x := fun a =>
      (hall a).elim (·.mono hle) (fun h => (h.mono hle).trans hxy'.symm)
    exact ⟨fun a b => (hx a).trans (hx b).symm⟩
  refine ⟨?_, hES, hnot⟩
  rw [isTree_iff_connected_and_card]
  refine ⟨hconn, ?_⟩
  rw [← hT.ncard_edgeSet_add_one, Nat.card_coe_set_eq, hES,
    Set.ncard_insert_of_notMem hnot (Set.toFinite _),
    Set.ncard_sdiff_singleton_of_mem (show s(x, y) ∈ T.edgeSet from hxy)]
  have : 0 < T.edgeSet.ncard := (Set.ncard_pos (Set.toFinite _)).2 ⟨s(x, y), (show s(x, y) ∈ T.edgeSet from hxy)⟩
  omega

open Classical in
/-- The weight after a swap: the old weight, less the removed edge, plus the added one. -/
lemma mst_swap_sum (T T' : SimpleGraph V) (w : Sym2 V → ℝ) (e f : Sym2 V)
    (hT' : T'.edgeSet = insert f (T.edgeSet \ {e})) (he : e ∈ T.edgeSet)
    (hf : f ∉ T.edgeSet \ {e}) :
    ∑ g ∈ T'.edgeFinset, w g = ∑ g ∈ T.edgeFinset, w g - w e + w f := by
  have h1 : T'.edgeFinset = insert f (T.edgeFinset.erase e) := by
    ext g
    simp only [mem_edgeFinset, Finset.mem_insert, Finset.mem_erase, hT', Set.mem_insert_iff,
      Set.mem_sdiff, Set.mem_singleton_iff]
    tauto
  have hf' : f ∉ T.edgeFinset.erase e := by
    simp only [Finset.mem_erase, mem_edgeFinset]; exact fun h => hf ⟨h.2, h.1⟩
  rw [h1, Finset.sum_insert hf', ← Finset.add_sum_erase _ _ (mem_edgeFinset.2 he)]
  ring

/-- The swapped graph stays inside `G` when `T` does and the new edge is an edge of `G`. -/
lemma mst_swap_le (G T : SimpleGraph V) (hTG : T ≤ G) {u v : V} (huv : G.Adj u v)
    (e : Sym2 V) : fromEdgeSet (insert s(u, v) (T.edgeSet \ {e})) ≤ G := by
  intro a b hab
  rw [fromEdgeSet_adj] at hab
  rcases hab with ⟨h | ⟨h, -⟩, -⟩
  · rcases Sym2.eq_iff.1 h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · exact huv
    · exact huv.symm
  · exact hTG h

open Classical in
/-- A connected graph on finitely many vertices has a minimum spanning tree. -/
lemma mst_exists (G : SimpleGraph V) (hG : G.Connected) (w : Sym2 V → ℝ) :
    ∃ T : SimpleGraph V, IsMinSpanningTree G T w := by
  obtain ⟨T0, hT0G, hT0⟩ := hG.exists_isTree_le
  let s := (Finset.univ : Finset (SimpleGraph V)).filter (fun T => T ≤ G ∧ T.IsTree)
  obtain ⟨T, hT, hmin⟩ := s.exists_min_image (fun T => ∑ e ∈ T.edgeFinset, w e)
    ⟨T0, by simp [s, hT0G, hT0]⟩
  simp only [s, Finset.mem_filter, Finset.mem_univ, true_and] at hT hmin
  exact ⟨T, hT.1, hT.2, fun T' h1 h2 => hmin T' ⟨h1, h2⟩⟩

#print axioms mst_reach_x_or_y
#print axioms mst_swap_isTree
#print axioms mst_swap_sum
#print axioms mst_swap_le
#print axioms mst_exists

open Classical in
/-- The exchange step behind the cut property (same content as the theorem below, proved here so
the cut property, which comes first, can use it). -/
lemma mst_kept_plus_safe (G : SimpleGraph V) (_hG : G.Connected)
    (w : Sym2 V → ℝ) (F : SimpleGraph V)
    (hF : ∃ T : SimpleGraph V, IsMinSpanningTree G T w ∧ F ≤ T)
    (S : Set V) (hFS : ∀ x y : V, F.Adj x y → (x ∈ S ↔ y ∈ S))
    {u v : V} (huv : G.Adj u v) (hu : u ∈ S) (hv : v ∉ S)
    (hmin : ∀ x y : V, G.Adj x y → x ∈ S → y ∉ S → w s(u, v) ≤ w s(x, y)) :
    ∃ T : SimpleGraph V, IsMinSpanningTree G T w ∧ F ≤ T ∧ T.Adj u v := by
  obtain ⟨T, ⟨hTG, hT, hTmin⟩, hFT⟩ := hF
  by_cases hTuv : T.Adj u v
  · exact ⟨T, ⟨hTG, hT, hTmin⟩, hFT, hTuv⟩
  obtain ⟨p⟩ := hT.connected.preconnected u v
  obtain ⟨d, hd, hdS, hdS'⟩ := p.bypass.exists_boundary_dart S hu hv
  have hpath : ∀ q : T.Walk u v, s(d.fst, d.snd) ∈ q.edges := by
    intro q
    have hpq : p.bypass = q.bypass :=
      congrArg Subtype.val ((hT.isAcyclic.subsingleton_path u v).elim
        ⟨p.bypass, p.bypass_isPath⟩ ⟨q.bypass, q.bypass_isPath⟩)
    apply q.edges_bypass_subset_edges
    rw [← hpq]
    exact Walk.edge_mem_edges_of_mem_darts hd
  obtain ⟨hT', hES, hnot⟩ := mst_swap_isTree T hT d.adj huv.ne hpath
  refine ⟨fromEdgeSet (insert s(u, v) (T.edgeSet \ {s(d.fst, d.snd)})),
    ⟨mst_swap_le G T hTG huv _, hT', ?_⟩, ?_, ?_⟩
  · intro T'' hT''G hT''
    rw [mst_swap_sum T _ w _ _ hES d.adj hnot]
    have h1 := hTmin T'' hT''G hT''
    have h2 := hmin d.fst d.snd (hTG d.adj) hdS hdS'
    linarith
  · intro a b hab
    rw [fromEdgeSet_adj]
    refine ⟨Or.inr ⟨hFT hab, ?_⟩, hab.ne⟩
    intro h
    rw [Set.mem_singleton_iff, Sym2.eq_iff] at h
    have := hFS a b hab
    rcases h with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ <;> tauto
  · rw [fromEdgeSet_adj]; exact ⟨Or.inl rfl, huv.ne⟩

#print axioms mst_kept_plus_safe

/-- The cut property. Take a graph with finitely many vertices in which some chain of edges joins
any two vertices, with a fixed weight on each edge (negative weights allowed, ties allowed). Split
the vertices into a group `S` and the rest. If the edge joining `u` in `S` to `v` outside it is a
cheapest edge crossing the split, then some minimum spanning tree holds it: the edge is safe. -/
theorem cheapest_crossing_edge_is_safe (G : SimpleGraph V) (hG : G.Connected)
    (w : Sym2 V → ℝ) (S : Set V) {u v : V} (huv : G.Adj u v) (hu : u ∈ S) (hv : v ∉ S)
    (hmin : ∀ x y : V, G.Adj x y → x ∈ S → y ∉ S → w s(u, v) ≤ w s(x, y)) :
    ∃ T : SimpleGraph V, IsMinSpanningTree G T w ∧ T.Adj u v := by
  obtain ⟨T0, hT0⟩ := mst_exists G hG w
  obtain ⟨T, hT, -, hTuv⟩ := mst_kept_plus_safe G hG w ⊥
    ⟨T0, hT0, bot_le⟩ S (fun x y h => h.elim) huv hu hv hmin
  exact ⟨T, hT, hTuv⟩

/-- The kept set stays inside one cheapest skeleton (Step 2, what licenses both walks). Suppose
the edges kept so far, `F`, all lie in some minimum spanning tree, and no kept edge crosses the
split of the vertices into `S` and the rest. Then a cheapest edge crossing the split can be kept
too: some minimum spanning tree holds every kept edge and the new one. -/
theorem kept_edges_plus_safe_edge_in_min_spanning_tree (G : SimpleGraph V) (hG : G.Connected)
    (w : Sym2 V → ℝ) (F : SimpleGraph V)
    (hF : ∃ T : SimpleGraph V, IsMinSpanningTree G T w ∧ F ≤ T)
    (S : Set V) (hFS : ∀ x y : V, F.Adj x y → (x ∈ S ↔ y ∈ S))
    {u v : V} (huv : G.Adj u v) (hu : u ∈ S) (hv : v ∉ S)
    (hmin : ∀ x y : V, G.Adj x y → x ∈ S → y ∉ S → w s(u, v) ≤ w s(x, y)) :
    ∃ T : SimpleGraph V, IsMinSpanningTree G T w ∧ F ≤ T ∧ T.Adj u v := by
  exact mst_kept_plus_safe G hG w F hF S hFS huv hu hv hmin

/-- The cycle property. An edge strictly dearer than every other edge on some loop of the graph
lies in no minimum spanning tree. -/
theorem dearest_edge_on_loop_in_no_min_spanning_tree (G : SimpleGraph V) (w : Sym2 V → ℝ)
    {x : V} (c : G.Walk x x) (hc : c.IsCycle) {e : Sym2 V} (he : e ∈ c.edges)
    (hdear : ∀ f ∈ c.edges, f ≠ e → w f < w e)
    (T : SimpleGraph V) (hT : IsMinSpanningTree G T w) :
    e ∉ T.edgeSet := by
  intro heT
  obtain ⟨hTG, hT, hTmin⟩ := hT
  induction e using Sym2.ind with
  | _ a b =>
  set H : SimpleGraph V := fromEdgeSet {f | f ∈ c.edges} with hHdef
  have hcH : ∀ f ∈ c.edges, f ∈ H.edgeSet := by
    intro f hf
    rw [hHdef, edgeSet_fromEdgeSet]
    exact ⟨hf, G.not_isDiag_of_mem_edgeSet (c.edges_subset_edgeSet hf)⟩
  have hab : H.Adj a b ∧ (H.deleteEdges {s(a, b)}).Reachable a b :=
    adj_and_reachable_delete_edges_iff_exists_cycle.2
      ⟨x, c.transfer H hcH, hc.transfer hcH, by rw [Walk.edges_transfer]; exact he⟩
  obtain ⟨q, hq⟩ := reachable_deleteEdges_iff_exists_walk.1 hab.2
  have hTab : T.Adj a b := heT
  have hbr : ¬ (T.deleteEdges {s(a, b)}).Reachable a b :=
    isBridge_iff.1 (isAcyclic_iff_forall_adj_isBridge.1 hT.isAcyclic hTab)
  obtain ⟨d, hd, hdS, hdS'⟩ :=
    q.exists_boundary_dart {z | (T.deleteEdges {s(a, b)}).Reachable a z} Reachable.rfl hbr
  have hdq : s(d.fst, d.snd) ∈ q.edges := Walk.edge_mem_edges_of_mem_darts hd
  have hfc : s(d.fst, d.snd) ∈ c.edges := by
    exact ((fromEdgeSet_adj _).1 d.adj).1
  have hfne : s(d.fst, d.snd) ≠ s(a, b) := fun h => hq (h ▸ hdq)
  have hGf : G.Adj d.fst d.snd := c.adj_of_mem_edges hfc
  have hnr : ∀ p : T.Walk d.fst d.snd, s(a, b) ∈ p.edges := by
    intro p
    by_contra hp
    exact hdS' (Reachable.trans hdS (reachable_deleteEdges_iff_exists_walk.2 ⟨p, hp⟩))
  obtain ⟨hT', hES, hnot⟩ := mst_swap_isTree T hT hTab d.adj.ne hnr
  have h1 := hTmin _ (mst_swap_le G T hTG hGf _) hT'
  rw [mst_swap_sum T _ w _ _ hES hTab hnot] at h1
  have h2 := hdear _ hfc hfne
  linarith

/-! ### The card's campus: buildings A to G are 0 to 6, prices in thousands of dollars -/

/-- The eleven priced runs: AB 7, AD 5, BC 8, BD 9, BE 7, CE 5, DE 15, DF 6, EF 8, EG 9, FG 11. -/
def runs : List (Fin 7 × Fin 7 × ℕ) :=
  [(0, 1, 7), (0, 3, 5), (1, 2, 8), (1, 3, 9), (1, 4, 7), (2, 4, 5), (3, 4, 15), (3, 5, 6),
   (4, 5, 8), (4, 6, 9), (5, 6, 11)]

/-- The price of a run, read from the list (0 for a pair with no run). -/
def price (e : Sym2 (Fin 7)) : ℕ :=
  ((runs.find? fun r => decide (s(r.1, r.2.1) = e)).map fun r => r.2.2).getD 0

/-- A graph on the seven buildings from a list of runs. -/
def ofRuns (l : List (Fin 7 × Fin 7 × ℕ)) : SimpleGraph (Fin 7) where
  Adj a b := a ≠ b ∧ ∃ r ∈ l, s(r.1, r.2.1) = s(a, b)
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.imp fun _ hr => ⟨hr.1, hr.2.trans Sym2.eq_swap⟩⟩⟩
  loopless := ⟨fun _ h => h.1 rfl⟩

instance (l : List (Fin 7 × Fin 7 × ℕ)) : DecidableRel (ofRuns l).Adj :=
  fun a b => inferInstanceAs (Decidable (a ≠ b ∧ ∃ r ∈ l, s(r.1, r.2.1) = s(a, b)))

/-- The campus map: seven buildings, eleven runs. -/
abbrev campus : SimpleGraph (Fin 7) := ofRuns runs

/-- The six runs both walks keep: AD 5, CE 5, DF 6, AB 7, BE 7, EG 9. -/
def skeletonRuns : List (Fin 7 × Fin 7 × ℕ) :=
  [(0, 3, 5), (2, 4, 5), (3, 5, 6), (0, 1, 7), (1, 4, 7), (4, 6, 9)]

/-- The cheapest skeleton as a graph on the seven buildings. -/
abbrev skeleton : SimpleGraph (Fin 7) := ofRuns skeletonRuns

/-- The total price of a list of runs. -/
def total (l : List (Fin 7 × Fin 7 × ℕ)) : ℕ := (l.map fun r => r.2.2).sum

/-- The buildings a list of runs links to building `a`: spread out from `a` seven times. -/
def linked (l : List (Fin 7 × Fin 7 × ℕ)) (a : Fin 7) : Fin 7 → Bool :=
  (fun f : Fin 7 → Bool => fun v =>
      f v || l.any fun r => (r.1 == v && f r.2.1) || (r.2.1 == v && f r.1))^[7]
    (fun v => v == a)

/-- Kruskal's walk over runs in the order given: keep a run only if its ends are not yet linked. -/
def kruskal (l : List (Fin 7 × Fin 7 × ℕ)) : List (Fin 7 × Fin 7 × ℕ) :=
  l.foldl (fun kept r => if linked kept r.1 r.2.1 then kept else kept ++ [r]) []

/-- Prim's walk from building `s`: six times, keep the cheapest run leaving the group (the first
listed on a tie) and move its far end in. -/
def prim (s : Fin 7) : List (Fin 7 × Fin 7 × ℕ) :=
  ((fun st : List (Fin 7) × List (Fin 7 × Fin 7 × ℕ) =>
      let out := runs.filter fun r => (r.1 ∈ st.1) != (r.2.1 ∈ st.1)
      match out.foldl (fun b r => match b with
          | none => some r
          | some b' => if r.2.2 < b'.2.2 then some r else some b') none with
      | none => st
      | some r => (st.1 ++ [if r.1 ∈ st.1 then r.2.1 else r.1], st.2 ++ [r]))^[6]
    ([s], [])).2

/-- The runs sorted cheap to dear, ties by name: AD, CE, DF, AB, BE, BC, EF, BD, EG, FG, DE. -/
def cheapToDear : List (Fin 7 × Fin 7 × ℕ) :=
  [(0, 3, 5), (2, 4, 5), (3, 5, 6), (0, 1, 7), (1, 4, 7), (1, 2, 8), (4, 5, 8), (1, 3, 9),
   (4, 6, 9), (5, 6, 11), (3, 4, 15)]

/-- The six-run sets that join all seven buildings (six runs on seven buildings, so no loop). -/
def networks : List (List (Fin 7 × Fin 7 × ℕ)) :=
  (runs.sublistsLen 6).filter fun t => (List.finRange 7).all (linked t 0)

-- The map has eleven runs, and `price` reads them back: AD 5, DE 15.
example : campus.edgeFinset.card = 11 ∧ price s(0, 3) = 5 ∧ price s(3, 4) = 15 := by decide
-- The sorted list is the eleven runs, cheap to dear.
example : cheapToDear.Perm runs ∧ (cheapToDear.map fun r => r.2.2).Pairwise (· ≤ ·) := by
  decide
-- Kruskal's walk keeps AD, CE, DF, AB, BE, EG and skips the other five; 39 in all.
example : kruskal cheapToDear = skeletonRuns ∧ total skeletonRuns = 39 := by decide
example : 5 + 5 + 6 + 7 + 7 + 9 = 39 := by norm_num
-- Prim from A keeps AD 5, DF 6, AB 7, BE 7, CE 5, EG 9: the same six, another order.
example : prim 0 = [(0, 3, 5), (3, 5, 6), (0, 1, 7), (1, 4, 7), (2, 4, 5), (4, 6, 9)] := by
  decide
-- From every start Prim keeps the same six runs, at 39.
example : ∀ s : Fin 7, (prim s).Perm skeletonRuns := by decide +kernel
-- The skeleton uses only the campus's runs, and its six edges price at 39.
example : skeleton ≤ campus := fun a b h => by revert a b; decide
example : skeleton.edgeFinset.card = 6 ∧ ∑ e ∈ skeleton.edgeFinset, price e = 39 := by decide
-- The split A, B, D, F against C, E, G: BE 7 is a cheapest crossing run, and the skeleton holds it.
example : ∀ x y : Fin 7, campus.Adj x y → x ∈ ({0, 1, 3, 5} : Finset (Fin 7)) →
    y ∉ ({0, 1, 3, 5} : Finset (Fin 7)) → price s(1, 4) ≤ price s(x, y) := by decide
example : price s(1, 4) = 7 ∧ skeleton.Adj 1 4 := by decide
-- Brute force: 462 six-run sets, 141 of them join all seven, the cheapest 39, the dearest 59,
-- and only one prices at 39, the skeleton.
example : Nat.choose 11 6 = 462 ∧ (runs.sublistsLen 6).length = 462 := by decide +kernel
example : networks.length = 141 := by decide +kernel
example : (∀ t ∈ networks, 39 ≤ total t ∧ total t ≤ 59) ∧
    (networks.filter fun t => total t = 39) =
      [[(0, 1, 7), (0, 3, 5), (1, 4, 7), (2, 4, 5), (3, 5, 6), (4, 6, 9)]] := by
  decide +kernel
-- The mistakes: the six cheapest runs cost 38 and leave two groups; five runs cost 30;
-- dear to cheap with the loop test builds the dearest skeleton, 59.
example : total (cheapToDear.take 6) = 38 ∧ (kruskal (cheapToDear.take 6)).length = 5 := by
  decide
example : total (skeletonRuns.take 5) = 30 ∧ total (kruskal cheapToDear.reverse) = 59 := by
  decide

#print axioms cheapest_crossing_edge_is_safe
#print axioms kept_edges_plus_safe_edge_in_min_spanning_tree
#print axioms dearest_edge_on_loop_in_no_min_spanning_tree
