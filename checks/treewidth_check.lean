-- Treewidth: every cycle of 3 or more vertices has treewidth exactly 2, every tree with an edge has treewidth 1, and no graph has treewidth below its fewest neighbours.
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Order.ConditionallyCompleteLattice.Basic
import Mathlib.Order.Lattice.Nat
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

/-! Mathlib has no tree decompositions, so this file defines them as the card does.
The decomposition's tree has nodes `0, …, m - 1`; node `t` carries the bag `bag t`.
The three rules are the card's: cover the vertices, cover the edges, keep each vertex's bags
joined (the nodes whose bags hold `v` span a connected piece of the tree).
The width is the largest bag's size minus one; the treewidth is the smallest width. -/

namespace Treewidth

open SimpleGraph

/-- A tree decomposition of `G`: a tree `T` on the nodes `Fin m`, a bag of vertices at each
node, and the card's three rules. -/
structure TreeDecomposition {V : Type*} (G : SimpleGraph V) where
  /-- The number of nodes of the decomposition's tree. -/
  m : ℕ
  /-- The decomposition's tree. -/
  T : SimpleGraph (Fin m)
  isTree : T.IsTree
  /-- The bag at each node. -/
  bag : Fin m → Finset V
  /-- Rule 1: every vertex sits in at least one bag. -/
  cover_vertices : ∀ v, ∃ t, v ∈ bag t
  /-- Rule 2: both ends of every edge sit together in at least one bag. -/
  cover_edges : ∀ u v, G.Adj u v → ∃ t, u ∈ bag t ∧ v ∈ bag t
  /-- Rule 3: the nodes whose bags hold `v` form a connected piece of the tree. -/
  joined : ∀ v, (T.induce {t | v ∈ bag t}).Connected

/-- The width of a decomposition: its largest bag's size, minus one. -/
def TreeDecomposition.width {V : Type*} {G : SimpleGraph V} (D : TreeDecomposition G) : ℕ :=
  (Finset.univ.sup fun t => (D.bag t).card) - 1

/-- The treewidth of `G`: the smallest width any tree decomposition of `G` reaches. -/
noncomputable def treewidth {V : Type*} (G : SimpleGraph V) : ℕ :=
  sInf (Set.range (TreeDecomposition.width (G := G)))

/-! ### Helper lemmas -/

/-- In an acyclic graph two paths with the same ends are equal. -/
theorem tw_path_eq {α : Type*} {T : SimpleGraph α} (hT : T.IsAcyclic) {a b : α}
    (p q : T.Walk a b) (hp : p.IsPath) (hq : q.IsPath) : p = q :=
  congrArg Subtype.val ((hT.subsingleton_path a b).elim ⟨p, hp⟩ ⟨q, hq⟩)

/-- In a tree every path has length equal to the distance. -/
theorem tw_path_length_eq_dist {α : Type*} {T : SimpleGraph α} (hT : T.IsTree) {a b : α}
    (p : T.Walk a b) (hp : p.IsPath) : p.length = T.dist a b := by
  obtain ⟨w, hw⟩ := hT.connected.exists_walk_length_eq_dist a b
  classical
  have h2 : p = w.bypass := tw_path_eq hT.isAcyclic _ _ hp w.bypass_isPath
  have h3 := w.length_bypass_le_length
  have h4 := T.dist_le p
  rw [h2] at h4 ⊢
  omega

/-- A connected induced piece of a tree holds the whole path between any two of its nodes. -/
theorem tw_support_subset {α : Type*} {T : SimpleGraph α} (hT : T.IsAcyclic) {S : Set α}
    (hS : (T.induce S).Connected) {a b : α} (ha : a ∈ S) (hb : b ∈ S)
    (p : T.Walk a b) (hp : p.IsPath) : ∀ x ∈ p.support, x ∈ S := by
  classical
  obtain ⟨w⟩ := hS.preconnected ⟨a, ha⟩ ⟨b, hb⟩
  let w' : T.Walk a b := w.map (Embedding.induce S).toHom
  have hw' : ∀ x ∈ w'.support, x ∈ S := by
    intro x hx
    have hx' : x ∈ (w.map (Embedding.induce S).toHom).support := hx
    rw [Walk.support_map, List.mem_map] at hx'
    obtain ⟨y, -, rfl⟩ := hx'
    exact y.2
  have hp' : p = w'.bypass := tw_path_eq hT _ _ hp w'.bypass_isPath
  intro x hx
  rw [hp'] at hx
  exact hw' x (w'.support_bypass_subset_support hx)

/-- Nodes on a path from the root are no farther from the root than its end, and only the end
is exactly as far. -/
theorem tw_dist_le_of_mem {α : Type*} {T : SimpleGraph α} (hT : T.IsTree) {r a x : α}
    (Q : T.Walk r a) (hQ : Q.IsPath) (hx : x ∈ Q.support) :
    T.dist r x ≤ T.dist r a ∧ (T.dist r x = T.dist r a → x = a) := by
  classical
  have h1 := tw_path_length_eq_dist hT (Q.takeUntil x hx) (hQ.takeUntil hx)
  have h2 := tw_path_length_eq_dist hT Q hQ
  have h3 := congrArg Walk.length (Q.take_spec hx)
  rw [Walk.length_append] at h3
  refine ⟨by omega, fun h => ?_⟩
  have h4 : (Q.dropUntil x hx).length = 0 := by omega
  exact Walk.eq_of_length_eq_zero h4

/-- If `a` is the node of a connected piece `S` closest to the root `r`, then the path from `r`
to any node `t` of `S` runs through `a`, and its part after `a` stays in `S`. -/
theorem tw_path_through_top {α : Type*} {T : SimpleGraph α} (hT : T.IsTree) {S : Set α}
    (hS : (T.induce S).Connected) {r a t : α} (ha : a ∈ S) (ht : t ∈ S)
    (hmin : ∀ s ∈ S, T.dist r a ≤ T.dist r s) (R : T.Walk r t) (hR : R.IsPath) :
    ∃ (Q : T.Walk r a) (P : T.Walk a t), Q.IsPath ∧ R = Q.append P ∧ ∀ x ∈ P.support, x ∈ S := by
  classical
  obtain ⟨w1⟩ := hT.connected.preconnected r a
  obtain ⟨w2⟩ := hT.connected.preconnected a t
  set Q := w1.bypass
  set P := w2.bypass
  have hQ : Q.IsPath := w1.bypass_isPath
  have hP : P.IsPath := w2.bypass_isPath
  have hPS := tw_support_subset hT.isAcyclic hS ha ht P hP
  have hQP : (Q.append P).IsPath := by
    rw [Walk.isPath_def, Walk.support_append, List.nodup_append]
    refine ⟨(Walk.isPath_def _).1 hQ, ((Walk.isPath_def _).1 hP).sublist (List.tail_sublist _), ?_⟩
    intro x hxQ y hyP hxy
    subst hxy
    have hxS : x ∈ S := hPS x (List.mem_of_mem_tail hyP)
    have h1 := hmin x hxS
    have h2 := tw_dist_le_of_mem hT Q hQ hxQ
    have hxa : x = a := h2.2 (le_antisymm h2.1 h1)
    subst hxa
    have hnd := (Walk.isPath_def _).1 hP
    rw [← Walk.cons_tail_support, List.nodup_cons] at hnd
    exact hnd.1 hyP
  refine ⟨Q, P, hQ, ?_, hPS⟩
  exact tw_path_eq hT.isAcyclic _ _ hR hQP

/-- In any tree decomposition some vertex sits in a bag together with all its neighbours. -/
theorem tw_exists_closed_bag {V : Type*} [Fintype V] [Nonempty V] {G : SimpleGraph V}
    (D : TreeDecomposition G) : ∃ v t, v ∈ D.bag t ∧ ∀ u, G.Adj v u → u ∈ D.bag t := by
  classical
  have hT := D.isTree
  obtain ⟨r⟩ := hT.connected.nonempty
  have hne : ∀ v, (Finset.univ.filter fun t => v ∈ D.bag t).Nonempty := fun v => by
    obtain ⟨t, ht⟩ := D.cover_vertices v
    exact ⟨t, by simp [ht]⟩
  choose top htop using fun v => Finset.exists_min_image _ (fun t => D.T.dist r t) (hne v)
  obtain ⟨v, -, hv⟩ := Finset.exists_max_image Finset.univ (fun v => D.T.dist r (top v))
    Finset.univ_nonempty
  have hmem : ∀ w, w ∈ D.bag (top w) := fun w => by simpa using (htop w).1
  have hmin : ∀ w, ∀ s ∈ {t | w ∈ D.bag t}, D.T.dist r (top w) ≤ D.T.dist r s :=
    fun w s hs => (htop w).2 s (by simpa using hs)
  refine ⟨v, top v, hmem v, fun u huv => ?_⟩
  obtain ⟨t, hvt, hut⟩ := D.cover_edges v u huv
  obtain ⟨w⟩ := hT.connected.preconnected r t
  have hR := w.bypass_isPath
  obtain ⟨Qa, Pa, -, hRa, -⟩ :=
    tw_path_through_top hT (D.joined v) (hmem v) hvt (hmin v) w.bypass hR
  obtain ⟨Qb, Pb, hQb, hRb, hPb⟩ :=
    tw_path_through_top hT (D.joined u) (hmem u) hut (hmin u) w.bypass hR
  have ha : top v ∈ w.bypass.support := by
    rw [hRa, Walk.mem_support_append_iff]
    exact Or.inr Pa.start_mem_support
  rw [hRb, Walk.mem_support_append_iff] at ha
  rcases ha with ha | ha
  · have h1 := tw_dist_le_of_mem hT Qb hQb ha
    have h2 := hv u (Finset.mem_univ u)
    have : top v = top u := h1.2 (le_antisymm h1.1 h2)
    rw [this]
    exact hmem u
  · exact hPb _ ha

/-- No decomposition has width below the fewest neighbours. -/
theorem tw_minDegree_le_width {V : Type*} [Fintype V] (G : SimpleGraph V) [DecidableRel G.Adj]
    (D : TreeDecomposition G) : G.minDegree ≤ D.width := by
  classical
  cases isEmpty_or_nonempty V
  · simp [minDegree_of_subsingleton]
  obtain ⟨v, t, hv, hN⟩ := tw_exists_closed_bag D
  have hsub : insert v (G.neighborFinset v) ⊆ D.bag t := by
    intro x hx
    rw [Finset.mem_insert] at hx
    rcases hx with rfl | hx
    · exact hv
    · exact hN x ((G.mem_neighborFinset v x).1 hx)
  have hcard : (insert v (G.neighborFinset v)).card = G.degree v + 1 :=
    Finset.card_insert_of_notMem (by simp)
  have h1 := Finset.card_le_card hsub
  have h2 : (D.bag t).card ≤ Finset.univ.sup fun t => (D.bag t).card :=
    Finset.le_sup (f := fun t => (D.bag t).card) (Finset.mem_univ t)
  have h3 := G.minDegree_le_degree v
  unfold TreeDecomposition.width
  omega

/-- Every finite graph has a decomposition: one bag holding everything. -/
def tw_trivialDecomp {V : Type*} [Fintype V] (G : SimpleGraph V) : TreeDecomposition G where
  m := 1
  T := ⊥
  isTree := IsTree.of_subsingleton
  bag := fun _ => Finset.univ
  cover_vertices := fun _ => ⟨0, Finset.mem_univ _⟩
  cover_edges := fun _ _ _ => ⟨0, Finset.mem_univ _, Finset.mem_univ _⟩
  joined := fun v => by
    have : Nonempty {t : Fin 1 // t ∈ {t : Fin 1 | v ∈ (Finset.univ : Finset V)}} :=
      ⟨⟨0, by simp⟩⟩
    exact IsTree.of_subsingleton.connected

/-- The floor, as a helper: no finite graph has treewidth below its fewest neighbours. -/
theorem tw_minDegree_le_treewidth {V : Type*} [Fintype V] (G : SimpleGraph V)
    [DecidableRel G.Adj] : G.minDegree ≤ treewidth G := by
  have : Nonempty (TreeDecomposition G) := ⟨tw_trivialDecomp G⟩
  apply le_csInf (Set.range_nonempty _)
  rintro _ ⟨D, rfl⟩
  exact tw_minDegree_le_width G D

/-- An upper bound from a decomposition on any finite tree of nodes. -/
theorem tw_treewidth_le_of {V α : Type*} [Fintype α] {G : SimpleGraph V} (T : SimpleGraph α)
    (hT : T.IsTree) (bag : α → Finset V) (h1 : ∀ v, ∃ t, v ∈ bag t)
    (h2 : ∀ u v, G.Adj u v → ∃ t, u ∈ bag t ∧ v ∈ bag t)
    (h3 : ∀ v, (T.induce {t | v ∈ bag t}).Connected) (k : ℕ) (hk : ∀ t, (bag t).card ≤ k + 1) :
    treewidth G ≤ k := by
  let e := Fintype.equivFin α
  let ι : T.comap e.symm ≃g T := { toEquiv := e.symm, map_rel_iff' := Iff.rfl }
  let D : TreeDecomposition G :=
    { m := Fintype.card α
      T := T.comap e.symm
      isTree := ι.isTree_iff.mpr hT
      bag := fun i => bag (e.symm i)
      cover_vertices := fun v => by
        obtain ⟨t, ht⟩ := h1 v
        exact ⟨e t, by simpa using ht⟩
      cover_edges := fun u v huv => by
        obtain ⟨t, hu, hv⟩ := h2 u v huv
        exact ⟨e t, by simpa using hu, by simpa using hv⟩
      joined := fun v => by
        let φ : (T.comap e.symm).induce {i | v ∈ bag (e.symm i)} ≃g T.induce {t | v ∈ bag t} :=
          { toEquiv := e.symm.subtypeEquiv fun _ => Iff.rfl, map_rel_iff' := Iff.rfl }
        exact φ.connected_iff.mpr (h3 v) }
  have hw : D.width ≤ k := by
    have : (Finset.univ.sup fun i => (D.bag i).card) ≤ k + 1 :=
      Finset.sup_le fun i _ => hk _
    unfold TreeDecomposition.width
    omega
  exact (Nat.sInf_le (Set.mem_range_self D)).trans hw

/-- Every tree has bags `{v, parent v}`: width at most 1, with the tree itself as the tree. -/
theorem tw_tree_bags {V : Type*} {G : SimpleGraph V} (hG : G.IsTree) :
    ∃ bag : V → Finset V, (∀ v, v ∈ bag v) ∧ (∀ u v, G.Adj u v → ∃ t, u ∈ bag t ∧ v ∈ bag t) ∧
      (∀ v, (G.induce {t | v ∈ bag t}).Connected) ∧ ∀ t, (bag t).card ≤ 2 := by
  classical
  obtain ⟨r⟩ := hG.connected.nonempty
  let pth : ∀ v, G.Walk v r := fun v => (hG.existsUnique_path v r).exists.choose
  have hpth : ∀ v, (pth v).IsPath := fun v => (hG.existsUnique_path v r).exists.choose_spec
  have huniq : ∀ v (q : G.Walk v r), q.IsPath → q = pth v :=
    fun v q hq => (hG.existsUnique_path v r).unique hq (hpth v)
  let par : V → V := fun v => (pth v).snd
  have hpar_r : par r = r := by
    have : pth r = Walk.nil := Walk.eq_nil_iff_nil.mpr (Walk.isPath_iff_nil.mp (hpth r))
    simp [par, this]
  have hpar_adj : ∀ v, v ≠ r → G.Adj v (par v) := fun v hv =>
    (pth v).adj_snd (Walk.not_nil_of_ne hv)
  have hedge : ∀ u v, G.Adj u v → par u = v ∨ par v = u := by
    intro u v h
    by_cases hv : v ∈ (pth u).support
    · exact Or.inl (hG.isAcyclic.eq_snd_of_adj_start (hpth u) h hv).symm
    · right
      have hq : (Walk.cons h.symm (pth u)).IsPath := (hpth u).cons hv
      have := huniq v _ hq
      show (pth v).snd = u
      rw [← this]
      simp
  refine ⟨fun v => {v, par v}, fun v => by simp, ?_, ?_, fun t => Finset.card_le_two⟩
  · intro u v h
    rcases hedge u v h with h1 | h1
    · exact ⟨u, by simp, by simp [h1]⟩
    · exact ⟨v, by simp [h1], by simp⟩
  · intro x
    have hx : x ∈ {t | x ∈ ({t, par t} : Finset V)} := by simp
    have : Nonempty {t // t ∈ {t | x ∈ ({t, par t} : Finset V)}} := ⟨⟨x, hx⟩⟩
    have key : ∀ a, (G.induce {t | x ∈ ({t, par t} : Finset V)}).Reachable ⟨x, hx⟩ a := by
      rintro ⟨a, ha⟩
      have ha' : x = a ∨ x = par a := by simpa using ha
      by_cases hxa : x = a
      · subst hxa; rfl
      · have hpa : par a = x := (ha'.resolve_left hxa).symm
        have har : a ≠ r := by
          rintro rfl
          exact hxa (hpa ▸ hpar_r)
        apply SimpleGraph.Adj.reachable
        show G.Adj x a
        rw [← hpa]
        exact (hpar_adj a har).symm
    exact ⟨fun a b => (key a).symm.trans (key b)⟩

/-- Cycles score 2: the cycle on `n ≥ 3` vertices has treewidth exactly 2
(fan bags reach width 2, and every vertex has 2 neighbours, so nothing goes lower). -/
theorem treewidth_cycleGraph (n : ℕ) (hn : 3 ≤ n) : treewidth (cycleGraph n) = 2 := by
  classical
  obtain ⟨k, rfl⟩ : ∃ k, n = k + 3 := ⟨n - 3, by omega⟩
  have hP : (pathGraph (k + 3)).IsTree := isTree_pathGraph.mpr (by omega)
  obtain ⟨bag, h1, h2, h3, h4⟩ := tw_tree_bags hP
  have hadj : ∀ u v : Fin (k + 3), (cycleGraph (k + 3)).Adj u v →
      (pathGraph (k + 3)).Adj u v ∨ u = 0 ∨ v = 0 := by
    intro u v h
    grind [pathGraph_adj, cycleGraph_adj', Fin.coe_sub_iff_le, Fin.coe_sub_iff_lt]
  have hle : treewidth (cycleGraph (k + 3)) ≤ 2 := by
    refine tw_treewidth_le_of (pathGraph (k + 3)) hP (fun t => insert 0 (bag t))
      (fun v => ⟨v, Finset.mem_insert_of_mem (h1 v)⟩) ?_ ?_ 2
      (fun t => (Finset.card_insert_le _ _).trans (by have := h4 t; omega))
    · intro u v huv
      rcases hadj u v huv with h | rfl | rfl
      · obtain ⟨t, hu, hv⟩ := h2 u v h
        exact ⟨t, Finset.mem_insert_of_mem hu, Finset.mem_insert_of_mem hv⟩
      · exact ⟨v, Finset.mem_insert_self _ _, Finset.mem_insert_of_mem (h1 v)⟩
      · exact ⟨u, Finset.mem_insert_of_mem (h1 u), Finset.mem_insert_self _ _⟩
    · intro x
      by_cases hx : x = 0
      · subst hx
        have : {t : Fin (k + 3) | (0 : Fin (k + 3)) ∈ insert 0 (bag t)} = Set.univ := by
          ext; simp
        rw [this]
        exact (induceUnivIso _).connected_iff.mpr hP.connected
      · have : {t : Fin (k + 3) | x ∈ insert 0 (bag t)} = {t | x ∈ bag t} := by
          ext; simp [hx]
        rw [this]
        exact h3 x
  have hge : 2 ≤ (cycleGraph (k + 3)).minDegree :=
    le_minDegree_of_forall_le_degree _ _ fun v => cycleGraph_degree_three_le.ge
  exact le_antisymm hle (hge.trans (tw_minDegree_le_treewidth _))

/-- Trees score 1: a finite tree with at least two vertices has treewidth exactly 1
(one bag per edge reaches width 1, and an edge needs a bag of 2). -/
theorem treewidth_of_isTree {V : Type*} [Fintype V] [Nontrivial V] {G : SimpleGraph V}
    (hG : G.IsTree) : treewidth G = 1 := by
  classical
  obtain ⟨bag, h1, h2, h3, h4⟩ := tw_tree_bags hG
  have hle : treewidth G ≤ 1 := tw_treewidth_le_of G hG bag (fun v => ⟨v, h1 v⟩) h2 h3 1 h4
  have hge : 1 ≤ G.minDegree := by
    apply le_minDegree_of_forall_le_degree
    intro v
    obtain ⟨w, hw⟩ := exists_ne v
    obtain ⟨p⟩ := hG.connected.preconnected v w
    cases p with
    | nil => exact absurd rfl hw
    | cons h _ => exact (G.degree_pos_iff_exists_adj v).2 ⟨_, h⟩
  exact le_antisymm hle (hge.trans (tw_minDegree_le_treewidth G))

/-- The floor: no finite graph has treewidth below its fewest neighbours `δ(G)`. -/
theorem minDegree_le_treewidth {V : Type*} [Fintype V] (G : SimpleGraph V) [DecidableRel G.Adj] :
    G.minDegree ≤ treewidth G := by
  exact tw_minDegree_le_treewidth G

/-! ### The six masts: the 6-cycle 1-2-3-4-5-6, here vertices 0 to 5 -/

/-- The card's four bags {1, 2, 6}, {2, 3, 6}, {3, 5, 6}, {3, 4, 5}, in a row, shifted down by one. -/
def mastBags : Fin 4 → Finset (Fin 6) :=
  ![{0, 1, 5}, {1, 2, 5}, {2, 4, 5}, {2, 3, 4}]

-- Rule 1: all six masts appear.
example : ∀ v : Fin 6, ∃ t, v ∈ mastBags t := by decide

-- Rule 2: both ends of every edge of the ring sit together in some bag.
example : ∀ u v : Fin 6, (cycleGraph 6).Adj u v → ∃ t, u ∈ mastBags t ∧ v ∈ mastBags t := by
  decide

-- Rule 3 on a row of bags: each mast's bags run unbroken.
example : ∀ (v : Fin 6) (i j k : Fin 4), i ≤ j → j ≤ k →
    v ∈ mastBags i → v ∈ mastBags k → v ∈ mastBags j := by decide

-- The largest bag holds 3, so the width is 2.
example : (Finset.univ.sup fun t => (mastBags t).card) - 1 = 2 := by decide

-- The tables: 5, 6, 6 and 5 clash-free choices per bag, 22 entries, each at most 2^3 = 8.
example : (List.ofFn fun t => ((mastBags t).powerset.filter
    fun s : Finset (Fin 6) => (cycleGraph 6).IsIndepSet (s : Set (Fin 6))).card) =
    [5, 6, 6, 5] := by decide

-- Masts 1, 3, 5 share a frequency; no four masts can.
example : (cycleGraph 6).IsIndepSet ({0, 2, 4} : Finset (Fin 6)) := by decide
example : ∀ s : Finset (Fin 6), ¬ (cycleGraph 6).IsNIndepSet 4 s := by decide

-- All 64 subsets: 18 are independent.
example : (Finset.univ.filter fun s : Finset (Fin 6) =>
    (cycleGraph 6).IsIndepSet (s : Set (Fin 6))).card = 18 := by decide

-- Every subset of 60 masts: 2^60.
example : 2 ^ 60 = 1152921504606846976 := by norm_num

#print axioms tw_path_eq
#print axioms tw_path_length_eq_dist
#print axioms tw_support_subset
#print axioms tw_dist_le_of_mem
#print axioms tw_path_through_top
#print axioms tw_exists_closed_bag
#print axioms tw_minDegree_le_width
#print axioms tw_minDegree_le_treewidth
#print axioms tw_treewidth_le_of
#print axioms tw_tree_bags
#print axioms treewidth_cycleGraph
#print axioms treewidth_of_isTree
#print axioms minDegree_le_treewidth

end Treewidth
