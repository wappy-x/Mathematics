-- The chromatic polynomial: the number of proper colourings of a finite simple graph with q colours equals the count with one edge deleted minus the count with that edge contracted, it is a monic polynomial in q whose degree is the number of vertices and whose next coefficient is minus the number of edges, a ring of n rooms has (q - 1)^n + (-1)^n (q - 1) colourings, and the card's counts 24, 18, 6, 12 and 30 check out.
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Combinatorics.SimpleGraph.Hasse
import Mathlib.Combinatorics.SimpleGraph.DeleteEdges
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Combinatorics.SimpleGraph.Operations
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Algebra.Polynomial.Monic
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

open SimpleGraph Polynomial

/-- Contraction G/e of the edge from u to v: the dot v is fused into the dot u. The dots of G/e
are the dots of G other than v; every line of G is carried over with v renamed to u. The line
from u to v itself becomes a line from a dot to itself and is dropped, and two lines that land on
the same pair count as one (Mathlib's `SimpleGraph.map` does both). -/
def contractEdge {V : Type*} [DecidableEq V] (G : SimpleGraph V) {u v : V} (huv : u ≠ v) :
    SimpleGraph {x : V // x ≠ v} :=
  G.map (fun x => if h : x = v then ⟨u, huv⟩ else ⟨x, h⟩)

/-- Colourings are the same as functions that give joined dots different colours. -/
def coloringEquivSubtype {V α : Type*} (G : SimpleGraph V) :
    G.Coloring α ≃ {f : V → α // ∀ x y, G.Adj x y → f x ≠ f y} where
  toFun C := ⟨C, fun _ _ h => C.valid h⟩
  invFun f := Coloring.mk f.1 (fun h => f.2 _ _ h)
  left_inv C := by ext; rfl
  right_inv f := rfl

theorem card_coloring_eq_filter {V α : Type*} [Fintype V] [Fintype α] [DecidableEq V]
    [DecidableEq α] (G : SimpleGraph V) [DecidableRel G.Adj] :
    Fintype.card (G.Coloring α) =
      (Finset.univ.filter (fun f : V → α => ∀ x y, G.Adj x y → f x ≠ f y)).card := by
  rw [← Fintype.card_subtype]
  exact Fintype.card_congr (coloringEquivSubtype G)

theorem card_coloring_congr {V W α : Type*} [Fintype V] [Fintype W] [Fintype α]
    {G : SimpleGraph V} {G' : SimpleGraph W} (e : G ≃g G') :
    Fintype.card (G.Coloring α) = Fintype.card (G'.Coloring α) :=
  Fintype.card_congr
    { toFun := fun C => C.comp e.symm.toHom
      invFun := fun C => C.comp e.toHom
      left_inv := fun C => by ext; simp
      right_inv := fun C => by ext; simp }

/-- The fusing map of the contraction. -/
def fuse {V : Type*} [DecidableEq V] {u v : V} (huv : u ≠ v) (x : V) : {x : V // x ≠ v} :=
  if h : x = v then ⟨u, huv⟩ else ⟨x, h⟩

section Fuse
variable {V : Type*} [DecidableEq V] {u v : V} (huv : u ≠ v)

theorem contractEdge_eq_map (G : SimpleGraph V) : contractEdge G huv = G.map (fuse huv) := rfl

theorem fuse_val (x : V) : (fuse huv x).1 = if x = v then u else x := by
  unfold fuse; split_ifs <;> rfl

theorem fuse_coe (w : {x : V // x ≠ v}) : fuse huv w.1 = w := by
  simp [fuse, w.2]

theorem fuse_v : fuse huv v = ⟨u, huv⟩ := by simp [fuse]

theorem fuse_u : fuse huv u = ⟨u, huv⟩ := by simp [fuse, huv]

theorem fuse_eq_fuse {x y : V} (hxy : fuse huv x = fuse huv y) : x = y ∨ s(x, y) = s(u, v) := by
  have h := congrArg Subtype.val hxy
  rw [fuse_val, fuse_val] at h
  by_cases hx : x = v <;> by_cases hy : y = v <;> simp only [hx, hy, ite_true, ite_false] at h
  · left; rw [hx, hy]
  · right; subst hx; subst h; exact Sym2.eq_swap
  · right; subst hy; subst h; rfl
  · left; exact h

theorem fuse_comp {α : Type*} (f : V → α) (hf : f u = f v) (z : V) : f (fuse huv z).1 = f z := by
  rw [fuse_val]; split_ifs with hz
  · rw [hz, hf]
  · rfl

end Fuse

theorem card_coloring_del_con {V α : Type*} [Fintype V] [DecidableEq V] [Fintype α]
    [DecidableEq α] (G : SimpleGraph V) {u v : V} (h : G.Adj u v) :
    Fintype.card ((G.deleteEdges {s(u, v)}).Coloring α) =
      Fintype.card (G.Coloring α) + Fintype.card ((contractEdge G h.ne).Coloring α) := by
  classical
  set H := G.deleteEdges {s(u, v)} with hHdef
  have hH : ∀ x y, H.Adj x y ↔ G.Adj x y ∧ ¬ s(x, y) = s(u, v) := by
    intro x y; simp [H]
  let P : (V → α) → Prop := fun f => ∀ x y, H.Adj x y → f x ≠ f y
  have e1 : G.Coloring α ≃ {f : V → α // P f ∧ f u ≠ f v} :=
    (coloringEquivSubtype G).trans (Equiv.subtypeEquivRight (fun f => by
      constructor
      · intro hf; exact ⟨fun x y hxy => hf x y ((hH x y).1 hxy).1, hf u v h⟩
      · rintro ⟨hf, huv⟩ x y hxy
        by_cases he : s(x, y) = s(u, v)
        · rcases Sym2.eq_iff.1 he with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
          · exact huv
          · exact Ne.symm huv
        · exact hf x y ((hH x y).2 ⟨hxy, he⟩)))
  have e2 : (contractEdge G h.ne).Coloring α ≃ {f : V → α // P f ∧ f u = f v} :=
    (coloringEquivSubtype _).trans
    { toFun := fun d => ⟨fun x => d.1 (fuse h.ne x), by
        refine ⟨fun x y hxy => d.2 _ _ ?_, by simp only [fuse_u, fuse_v]⟩
        rw [hH] at hxy
        refine ⟨?_, x, y, hxy.1, rfl, rfl⟩
        intro heq
        rcases fuse_eq_fuse h.ne heq with rfl | he
        · exact hxy.1.ne rfl
        · exact hxy.2 he⟩
      invFun := fun f => ⟨fun w => f.1 w.1, by
        rintro a b ⟨hab, x, y, hxy, rfl, rfl⟩
        change fuse h.ne x ≠ fuse h.ne y at hab
        show f.1 (fuse h.ne x).1 ≠ f.1 (fuse h.ne y).1
        rw [fuse_comp h.ne f.1 f.2.2, fuse_comp h.ne f.1 f.2.2]
        apply f.2.1 x y
        rw [hH]
        refine ⟨hxy, fun he => hab ?_⟩
        rcases Sym2.eq_iff.1 he with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
        · rw [fuse_u, fuse_v]
        · rw [fuse_u, fuse_v]⟩
      left_inv := fun d => by
        apply Subtype.ext; funext w
        show d.1 (fuse h.ne w.1) = d.1 w
        rw [fuse_coe]
      right_inv := fun f => by
        apply Subtype.ext; funext x
        exact fuse_comp h.ne f.1 f.2.2 x }
  rw [Fintype.card_congr e1, Fintype.card_congr e2, Fintype.card_congr (coloringEquivSubtype H)]
  simp only [Fintype.card_subtype]
  rw [add_comm, ← Finset.filter_filter, ← Finset.filter_filter]
  exact (Finset.card_filter_add_card_filter_not _).symm

universe uV

theorem card_fin_ne {q : ℕ} (b : Fin q) : Fintype.card {a : Fin q // a ≠ b} = q - 1 := by
  rw [Fintype.card_subtype_compl, Fintype.card_subtype_eq, Fintype.card_fin]

theorem card_coloring_of_no_edges {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    (hE : ∀ x y, ¬ G.Adj x y) (q : ℕ) :
    Fintype.card (G.Coloring (Fin q)) = q ^ Fintype.card V := by
  rw [Fintype.card_congr ((coloringEquivSubtype G).trans
    (Equiv.subtypeUnivEquiv (fun f x y hxy => absurd hxy (hE x y))))]
  simp

theorem contract_edges_le {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    {u v : V} (h : G.Adj u v) :
    Nat.card (contractEdge G h.ne).edgeSet ≤ Nat.card (G.deleteEdges {s(u, v)}).edgeSet := by
  rw [Nat.card_coe_set_eq, Nat.card_coe_set_eq]
  have hsub : (contractEdge G h.ne).edgeSet ⊆
      Sym2.map (fuse h.ne) '' (G.deleteEdges {s(u, v)}).edgeSet := by
    intro e he
    induction e using Sym2.ind with
    | _ a b =>
      obtain ⟨hab, x, y, hxy, rfl, rfl⟩ := he
      change fuse h.ne x ≠ fuse h.ne y at hab
      refine ⟨s(x, y), ?_, Sym2.map_mk _ _ _⟩
      rw [mem_edgeSet, deleteEdges_adj]
      refine ⟨hxy, fun he => hab ?_⟩
      rw [Set.mem_singleton_iff] at he
      rcases Sym2.eq_iff.1 he with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
      · rw [fuse_u, fuse_v]
      · rw [fuse_u, fuse_v]
  exact (Set.ncard_le_ncard hsub (Set.toFinite _)).trans (Set.ncard_image_le (Set.toFinite _))

theorem chromatic_poly_aux (m : ℕ) : ∀ {V : Type uV} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V), Nat.card G.edgeSet = m →
    ∃ P : ℤ[X], P.Monic ∧ P.natDegree = Fintype.card V ∧ P.nextCoeff = -(m : ℤ) ∧
      ∀ q : ℕ, P.eval (q : ℤ) = Fintype.card (G.Coloring (Fin q)) := by
  induction m using Nat.strong_induction_on with
  | _ m ih =>
  intro V _ _ G hm
  by_cases hE : ∃ u v, G.Adj u v
  · obtain ⟨u, v, h⟩ := hE
    have hmem : s(u, v) ∈ G.edgeSet := h
    have hm1 : Nat.card (G.deleteEdges {s(u, v)}).edgeSet = m - 1 := by
      rw [edgeSet_deleteEdges, Nat.card_coe_set_eq, Set.ncard_sdiff_singleton_of_mem hmem,
        ← Nat.card_coe_set_eq, hm]
    have hpos : 0 < m := by
      rw [← hm, Nat.card_coe_set_eq]
      exact Set.ncard_pos (Set.toFinite _) |>.2 ⟨_, hmem⟩
    have hm2 := contract_edges_le G h
    rw [hm1] at hm2
    obtain ⟨P1, hP1m, hP1d, hP1n, hP1e⟩ := ih (m - 1) (by omega) (G.deleteEdges {s(u, v)}) hm1
    obtain ⟨P2, hP2m, hP2d, -, hP2e⟩ := ih _ (by omega) (contractEdge G h.ne) rfl
    have hcard : Fintype.card {x : V // x ≠ v} = Fintype.card V - 1 := by
      rw [Fintype.card_subtype_compl, Fintype.card_subtype_eq]
    have hn : 0 < Fintype.card V := Fintype.card_pos_iff.2 ⟨u⟩
    rw [hcard] at hP2d
    have hlt : P2.natDegree < P1.natDegree := by rw [hP1d, hP2d]; omega
    have hdeg : P2.natDegree = P1.natDegree - 1 := by rw [hP1d, hP2d]
    have hPd : (P1 - P2).natDegree = Fintype.card V := by
      rw [natDegree_sub_eq_left_of_natDegree_lt hlt, hP1d]
    refine ⟨P1 - P2, hP1m.sub_of_left (degree_lt_degree hlt), hPd, ?_, ?_⟩
    · rw [nextCoeff_of_natDegree_pos (by rw [hPd]; omega), hPd, coeff_sub]
      rw [nextCoeff_of_natDegree_pos (by rw [hP1d]; omega), hP1d] at hP1n
      rw [hP1n, ← hP2d, hP2m.coeff_natDegree]
      have : ((m - 1 : ℕ) : ℤ) = (m : ℤ) - 1 := by omega
      rw [this]; ring
    · intro q
      rw [eval_sub, hP1e, hP2e, card_coloring_del_con G h]
      push_cast; ring
  · push Not at hE
    have hm0 : m = 0 := by
      rw [← hm, Nat.card_coe_set_eq, Set.ncard_eq_zero (Set.toFinite _)]
      ext e
      induction e using Sym2.ind with
      | _ x y => simp [hE x y]
    subst hm0
    refine ⟨X ^ Fintype.card V, monic_X_pow _, natDegree_X_pow _, ?_, ?_⟩
    · unfold nextCoeff
      rw [natDegree_X_pow, coeff_X_pow]
      split_ifs with h1 h2 <;> first | rfl | omega
    · intro q
      rw [eval_pow, eval_X, card_coloring_of_no_edges G hE q]
      push_cast; rfl

theorem cycleGraph_adj_val {n : ℕ} (hn : 2 ≤ n) {a b : Fin n} :
    (cycleGraph n).Adj a b ↔ a.val + 1 = b.val ∨ b.val + 1 = a.val ∨
      (a.val = 0 ∧ b.val + 1 = n) ∨ (b.val = 0 ∧ a.val + 1 = n) := by
  rw [cycleGraph_adj']
  have ha := a.isLt
  have hb := b.isLt
  have h1 : ((a - b : Fin n) : ℕ) = if b.val ≤ a.val then a.val - b.val else n + a.val - b.val := by
    split_ifs with h
    · exact Fin.coe_sub_iff_le.2 h
    · exact Fin.coe_sub_iff_lt.2 (by simp only [Fin.lt_def]; omega)
  have h2 : ((b - a : Fin n) : ℕ) = if a.val ≤ b.val then b.val - a.val else n + b.val - a.val := by
    split_ifs with h
    · exact Fin.coe_sub_iff_le.2 h
    · exact Fin.coe_sub_iff_lt.2 (by simp only [Fin.lt_def]; omega)
  rw [h1, h2]
  split_ifs <;> omega

theorem pathGraph_coloring_iff {α : Type*} {m : ℕ} (f : Fin (m + 1) → α) :
    (∀ x y, (pathGraph (m + 1)).Adj x y → f x ≠ f y) ↔
      ∀ i : Fin m, f i.castSucc ≠ f i.succ := by
  constructor
  · intro hf i
    exact hf _ _ (pathGraph_adj.2 (Or.inl (by simp)))
  · intro hf x y hxy
    rw [pathGraph_adj] at hxy
    rcases hxy with hxy | hxy
    · obtain ⟨i, rfl, rfl⟩ : ∃ i : Fin m, x = i.castSucc ∧ y = i.succ :=
        ⟨⟨x.val, by omega⟩, Fin.ext rfl, Fin.ext (by simp; omega)⟩
      exact hf i
    · obtain ⟨i, rfl, rfl⟩ : ∃ i : Fin m, y = i.castSucc ∧ x = i.succ :=
        ⟨⟨y.val, by omega⟩, Fin.ext rfl, Fin.ext (by simp; omega)⟩
      exact (hf i).symm

theorem card_path_functions (q : ℕ) : ∀ m : ℕ,
    Fintype.card {f : Fin (m + 1) → Fin q // ∀ i : Fin m, f i.castSucc ≠ f i.succ} =
      q * (q - 1) ^ m
  | 0 => by
    rw [Fintype.card_congr (Equiv.subtypeUnivEquiv (fun f i => i.elim0))]
    simp
  | m + 1 => by
    have e : {f : Fin (m + 2) → Fin q // ∀ i : Fin (m + 1), f i.castSucc ≠ f i.succ} ≃
        Σ g : {g : Fin (m + 1) → Fin q // ∀ i : Fin m, g i.castSucc ≠ g i.succ},
          {a : Fin q // a ≠ g.1 0} :=
      { toFun := fun f => ⟨⟨Fin.tail f.1, fun i => by
            have := f.2 i.succ
            have e : i.castSucc.succ = i.succ.castSucc := Fin.ext rfl
            show f.1 i.castSucc.succ ≠ f.1 i.succ.succ
            rw [e]; exact this⟩,
          ⟨f.1 0, by simpa [Fin.tail] using f.2 0⟩⟩
        invFun := fun p => ⟨Fin.cons p.2.1 p.1.1, fun i => by
            induction i using Fin.cases with
            | zero => simpa using p.2.2
            | succ i =>
              have := p.1.2 i
              have e : i.succ.castSucc = i.castSucc.succ := Fin.ext rfl
              rw [e, Fin.cons_succ, Fin.cons_succ]; exact this⟩
        left_inv := fun f => by
          apply Subtype.ext
          simp
        right_inv := fun p => by
          rcases p with ⟨⟨g, hg⟩, ⟨a, ha⟩⟩
          exact Sigma.subtype_ext (Subtype.ext (by funext i; simp [Fin.tail])) (by simp) }
    rw [Fintype.card_congr e, Fintype.card_sigma]
    simp only [card_fin_ne, Finset.sum_const, Finset.card_univ, smul_eq_mul]
    rw [card_path_functions q m]
    ring

theorem card_pathGraph_coloring (q m : ℕ) :
    Fintype.card ((pathGraph (m + 1)).Coloring (Fin q)) = q * (q - 1) ^ m := by
  rw [Fintype.card_congr ((coloringEquivSubtype _).trans
    (Equiv.subtypeEquivRight pathGraph_coloring_iff)), card_path_functions]

theorem card_pathGraph_coloring_int (q m : ℕ) :
    (Fintype.card ((pathGraph (m + 1)).Coloring (Fin q)) : ℤ) = q * ((q : ℤ) - 1) ^ m := by
  rw [card_pathGraph_coloring]
  rcases q with _ | q
  · simp
  · push_cast; simp

theorem cycle_deleteEdges_eq_path {n : ℕ} (hn : 2 ≤ n) :
    (cycleGraph (n + 1)).deleteEdges {s(0, Fin.last n)} = pathGraph (n + 1) := by
  ext a b
  rw [deleteEdges_adj, cycleGraph_adj_val (by omega), pathGraph_adj, Set.mem_singleton_iff,
    Sym2.eq_iff]
  simp only [Fin.ext_iff, Fin.val_zero, Fin.val_last]
  have := a.isLt
  have := b.isLt
  omega

/-- Renumbering the dots of the fused ring. -/
def fusedRingEquiv (n : ℕ) : {x : Fin (n + 1) // x ≠ Fin.last n} ≃ Fin n where
  toFun x := ⟨x.1.val, by
    have h1 := x.1.isLt
    have h2 : x.1.val ≠ n := fun h => x.2 (Fin.ext (by simp [h]))
    omega⟩
  invFun i := ⟨i.castSucc, Fin.castSucc_ne_last i⟩
  left_inv x := by apply Subtype.ext; apply Fin.ext; rfl
  right_inv i := by apply Fin.ext; rfl

theorem fusedRingEquiv_val (n : ℕ) (x : {x : Fin (n + 1) // x ≠ Fin.last n}) :
    (fusedRingEquiv n x).val = x.1.val := rfl

/-- Fusing two neighbouring rooms of a ring of n + 1 rooms gives a ring of n rooms. -/
def contractCycleIso {n : ℕ} (hn : 2 ≤ n) (h : (0 : Fin (n + 1)) ≠ Fin.last n) :
    contractEdge (cycleGraph (n + 1)) h ≃g cycleGraph n where
  toEquiv := fusedRingEquiv n
  map_rel_iff' := by
    intro a b
    have hv : ∀ z : Fin (n + 1), ((fuse h z).1.val : ℕ) = if z.val = n then 0 else z.val := by
      intro z
      rw [fuse_val]
      by_cases hz : z = Fin.last n
      · have : z.val = n := by rw [hz]; simp
        simp [hz]
      · have : z.val ≠ n := fun h' => hz (Fin.ext (by simp [h']))
        simp [hz, this]
    change (cycleGraph n).Adj (fusedRingEquiv n a) (fusedRingEquiv n b) ↔ _
    rw [cycleGraph_adj_val hn, fusedRingEquiv_val, fusedRingEquiv_val]
    have ha1 := a.1.isLt
    have hb1 := b.1.isLt
    have ha2 : a.1.val ≠ n := fun h' => a.2 (Fin.ext (by simp [h']))
    have hb2 : b.1.val ≠ n := fun h' => b.2 (Fin.ext (by simp [h']))
    constructor
    · intro hab
      have hne : a ≠ b := by
        rintro rfl; omega
      refine ⟨hne, ?_⟩
      rcases hab with hab | hab | ⟨h1, h2⟩ | ⟨h1, h2⟩
      · refine ⟨a.1, b.1, ?_, fuse_coe h a, fuse_coe h b⟩
        rw [cycleGraph_adj_val (by omega)]; omega
      · refine ⟨a.1, b.1, ?_, fuse_coe h a, fuse_coe h b⟩
        rw [cycleGraph_adj_val (by omega)]; omega
      · refine ⟨Fin.last n, b.1, ?_, ?_, fuse_coe h b⟩
        · rw [cycleGraph_adj_val (by omega)]; simp only [Fin.val_last]; omega
        · show fuse h (Fin.last n) = a
          apply Subtype.ext; apply Fin.ext; rw [hv]; simp [h1]
      · refine ⟨a.1, Fin.last n, ?_, fuse_coe h a, ?_⟩
        · rw [cycleGraph_adj_val (by omega)]; simp only [Fin.val_last]; omega
        · show fuse h (Fin.last n) = b
          apply Subtype.ext; apply Fin.ext; rw [hv]; simp [h1]
    · rintro ⟨hne, x, y, hxy, hx, hy⟩
      change fuse h x = a at hx
      change fuse h y = b at hy
      subst hx hy
      have hne' : (fuse h x).1.val ≠ (fuse h y).1.val := fun e =>
        hne (Subtype.ext (Fin.ext e))
      rw [hv, hv] at hne' ⊢
      rw [cycleGraph_adj_val (by omega)] at hxy
      have := x.isLt
      have := y.isLt
      split_ifs at hne' ⊢ <;> omega

theorem ring_aux (n : ℕ) (hn : 2 ≤ n) (q : ℕ) :
    (Fintype.card ((cycleGraph n).Coloring (Fin q)) : ℤ) =
      ((q : ℤ) - 1) ^ n + (-1) ^ n * ((q : ℤ) - 1) := by
  induction n, hn using Nat.le_induction with
  | base =>
    have e : cycleGraph 2 = pathGraph 2 := by
      ext a b
      revert a b
      decide
    rw [e, card_pathGraph_coloring_int]
    ring
  | succ n hn ih =>
    have hadj : (cycleGraph (n + 1)).Adj 0 (Fin.last n) := by
      rw [cycleGraph_adj_val (by omega)]; simp
    have key := card_coloring_del_con (α := Fin q) (cycleGraph (n + 1)) hadj
    rw [cycle_deleteEdges_eq_path hn, card_coloring_congr (contractCycleIso hn hadj.ne)] at key
    have key' : (Fintype.card ((pathGraph (n + 1)).Coloring (Fin q)) : ℤ) =
        Fintype.card ((cycleGraph (n + 1)).Coloring (Fin q)) +
          Fintype.card ((cycleGraph n).Coloring (Fin q)) := by
      exact_mod_cast key
    rw [card_pathGraph_coloring_int, ih] at key'
    rw [pow_succ, pow_succ]
    linear_combination -key'

/-- Decidable joins for the fused network, so small cases can be counted by the kernel. -/
instance contractEdge_decRel {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V)
    [DecidableRel G.Adj] {u v : V} (huv : u ≠ v) : DecidableRel (contractEdge G huv).Adj :=
  fun a b => decidable_of_iff (a ≠ b ∧ ∃ x y, G.Adj x y ∧ fuse huv x = a ∧ fuse huv y = b) Iff.rfl

/-- Decidable joins for the hatch from room 2 to room 4. -/
instance edge_one_three_decRel : DecidableRel (edge (1 : Fin 4) 3).Adj :=
  fun _ _ => decidable_of_iff _ (edge_adj ..).symm

#print axioms coloringEquivSubtype
#print axioms card_coloring_eq_filter
#print axioms card_coloring_congr
#print axioms fuse
#print axioms contractEdge_eq_map
#print axioms fuse_val
#print axioms fuse_coe
#print axioms fuse_v
#print axioms fuse_u
#print axioms fuse_eq_fuse
#print axioms fuse_comp
#print axioms card_coloring_del_con
#print axioms card_fin_ne
#print axioms card_coloring_of_no_edges
#print axioms contract_edges_le
#print axioms chromatic_poly_aux
#print axioms cycleGraph_adj_val
#print axioms pathGraph_coloring_iff
#print axioms card_path_functions
#print axioms card_pathGraph_coloring
#print axioms card_pathGraph_coloring_int
#print axioms cycle_deleteEdges_eq_path
#print axioms fusedRingEquiv
#print axioms fusedRingEquiv_val
#print axioms contractCycleIso
#print axioms ring_aux
#print axioms contractEdge_decRel
#print axioms edge_one_three_decRel

/-- Deletion and contraction. Take any finite network G and any line e of it, joining u and v.
For every whole number q of colours, the proper colourings of G (joined dots get different
colours) number the proper colourings of G - e (the line rubbed out) less the proper colourings
of G/e (its two ends fused into one dot): P(G, q) = P(G - e, q) - P(G/e, q). -/
theorem chromatic_count_deletion_contraction {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) {u v : V} (h : G.Adj u v) (q : ℕ) :
    (Fintype.card (G.Coloring (Fin q)) : ℤ) =
      Fintype.card ((G.deleteEdges {s(u, v)}).Coloring (Fin q)) -
        Fintype.card ((contractEdge G h.ne).Coloring (Fin q)) := by
  have key := card_coloring_del_con (α := Fin q) G h
  rw [key]; push_cast; ring

/-- The count is a polynomial. For every finite network G with n dots there is one polynomial
P with whole-number coefficients that gives the number of proper colourings from q colours at
every whole number q. Its highest power is q^n with a 1 in front, and the coefficient just below
it is minus the number of lines. -/
theorem chromatic_count_is_polynomial {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    ∃ P : ℤ[X], P.Monic ∧ P.natDegree = Fintype.card V ∧
      P.nextCoeff = -(G.edgeFinset.card : ℤ) ∧
      ∀ q : ℕ, P.eval (q : ℤ) = Fintype.card (G.Coloring (Fin q)) := by
  obtain ⟨P, h1, h2, h3, h4⟩ := chromatic_poly_aux G.edgeFinset.card G
    (by rw [edgeFinset_card, Nat.card_eq_fintype_card])
  exact ⟨P, h1, h2, h3, h4⟩

/-- A ring of n rooms, from the triangle up (n at least 3), has (q - 1)^n + (-1)^n (q - 1)
proper colourings from q colours, for every whole number q. -/
theorem ring_chromatic_count (n : ℕ) (hn : 3 ≤ n) (q : ℕ) :
    (Fintype.card ((cycleGraph n).Coloring (Fin q)) : ℤ) =
      ((q : ℤ) - 1) ^ n + (-1) ^ n * ((q : ℤ) - 1) := by
  exact ring_aux n (by omega) q

-- The row of four rooms, three tins: 3 × 2 × 2 × 2 = 24 schemes.
example : Fintype.card ((pathGraph 4).Coloring (Fin 3)) = 24 := by
  rw [card_coloring_eq_filter]; decide +kernel
-- The ring of four rooms (the courtyard), three tins: 18 schemes.
example : Fintype.card ((cycleGraph 4).Coloring (Fin 3)) = 18 := by
  rw [card_coloring_eq_filter]; decide +kernel
-- The triangle, three tins: 3 × 2 × 1 = 6 schemes.
example : Fintype.card ((cycleGraph 3).Coloring (Fin 3)) = 6 := by
  rw [card_coloring_eq_filter]; decide +kernel
-- The courtyard with the wall from room 4 to room 1 rubbed out is the row: 24 schemes.
example : Fintype.card (((cycleGraph 4).deleteEdges {s(3, 0)}).Coloring (Fin 3)) = 24 := by
  rw [card_coloring_eq_filter]; decide +kernel
-- Fusing rooms 4 and 1 of the courtyard leaves a triangle: 6 schemes.
example : Fintype.card ((contractEdge (cycleGraph 4) (u := (0 : Fin 4)) (v := 3)
    (by decide)).Coloring (Fin 3)) = 6 := by
  rw [card_coloring_eq_filter]; decide +kernel
-- The ring, deletion less contraction: 24 - 6 = 18.
example : (24 : ℤ) - 6 = 18 := by norm_num
-- The ring by the recurrence: q(q-1)^3 - q(q-1)(q-2) = q^4 - 4q^3 + 6q^2 - 3q = (q-1)^4 + (q-1).
example (q : ℤ) : q * (q - 1) ^ 3 - q * (q - 1) * (q - 2) = q ^ 4 - 4 * q ^ 3 + 6 * q ^ 2 - 3 * q := by
  ring
example (q : ℤ) : (q - 1) ^ 4 + (q - 1) = q ^ 4 - 4 * q ^ 3 + 6 * q ^ 2 - 3 * q := by ring
-- The ring's polynomial at q = 3: 18.
example : (3 : ℤ) ^ 4 - 4 * 3 ^ 3 + 6 * 3 ^ 2 - 3 * 3 = 18 := by norm_num
-- The triangle base of the ring formula: (q-1)^3 - (q-1) = q(q-1)(q-2).
example (q : ℤ) : (q - 1) ^ 3 - (q - 1) = q * (q - 1) * (q - 2) := by ring
-- A three-room row, three tins: 12 schemes.
example : Fintype.card ((pathGraph 3).Coloring (Fin 3)) = 12 := by
  rw [card_coloring_eq_filter]; decide +kernel
-- A hatch joins rooms 2 and 4 of the courtyard: 18 - 12 = 6 schemes, and q(q-1)(q-2)^2 = 6.
example : Fintype.card (((cycleGraph 4) ⊔ SimpleGraph.edge 1 3).Coloring (Fin 3)) = 6 := by
  rw [card_coloring_eq_filter]; decide +kernel
example : (3 : ℕ) * (3 - 1) * (3 - 2) ^ 2 = 6 := by norm_num
-- Rings of 3, 4 and 5 rooms: three tins give 6, 18, 30; two tins give 0, 2, 0.
example : Fintype.card ((cycleGraph 5).Coloring (Fin 3)) = 30 := by
  rw [card_coloring_eq_filter]; decide +kernel
example : Fintype.card ((cycleGraph 3).Coloring (Fin 2)) = 0 := by
  rw [card_coloring_eq_filter]; decide +kernel
example : Fintype.card ((cycleGraph 4).Coloring (Fin 2)) = 2 := by
  rw [card_coloring_eq_filter]; decide +kernel
example : Fintype.card ((cycleGraph 5).Coloring (Fin 2)) = 0 := by
  rw [card_coloring_eq_filter]; decide +kernel
-- Mistake: the recurrence read with a plus gives 24 + 6 = 30, more than the 24 with the wall gone.
example : (24 : ℕ) + 6 = 30 ∧ 24 < 24 + 6 := by norm_num

#print axioms chromatic_count_deletion_contraction
#print axioms chromatic_count_is_polynomial
#print axioms ring_chromatic_count
