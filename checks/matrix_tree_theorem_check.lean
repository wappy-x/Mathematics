-- The matrix-tree theorem: cutting any one row and its own column from a finite graph's Laplacian leaves a determinant equal to the number of spanning trees, the nonzero eigenvalues multiply to n times that count, and the complete graph on n vertices has n ^ (n - 2) spanning trees.
import Mathlib.Combinatorics.SimpleGraph.LapMatrix
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic

namespace MatrixTreeTheorem

open SimpleGraph Matrix

section parent
variable {V : Type*} (i : V) (F : V → V)

/-- `F` sends every vertex to `i` after finitely many steps. -/
def Reaches (v : V) : Prop := ∃ k, F^[k] v = i

/-- The number of steps from `v` to `i` under `F`. -/
noncomputable def depth (v : V) : ℕ := sInf {k | F^[k] v = i}

variable {i F}

lemma depth_spec {v : V} (h : Reaches i F v) : F^[depth i F v] v = i :=
  Nat.sInf_mem (s := {k | F^[k] v = i}) h

lemma depth_le {v : V} {k : ℕ} (h : F^[k] v = i) : depth i F v ≤ k := Nat.sInf_le h

lemma depth_self : depth i F i = 0 := Nat.le_zero.mp (depth_le (k := 0) rfl)

lemma depth_pos {v : V} (h : Reaches i F v) (hv : v ≠ i) : 0 < depth i F v := by
  rcases Nat.eq_zero_or_pos (depth i F v) with h0 | h0
  · have := depth_spec h; rw [h0] at this; exact absurd this hv
  · exact h0

lemma reaches_F {v : V} (h : Reaches i F v) (hv : v ≠ i) : Reaches i F (F v) := by
  have hd := depth_pos h hv
  refine ⟨depth i F v - 1, ?_⟩
  rw [← Function.iterate_succ_apply, Nat.succ_eq_add_one, Nat.sub_add_cancel hd]
  exact depth_spec h

lemma reaches_of_F {v : V} (h : Reaches i F (F v)) : Reaches i F v := by
  obtain ⟨k, hk⟩ := h
  exact ⟨k + 1, by rw [Function.iterate_succ_apply]; exact hk⟩

lemma depth_F {v : V} (h : Reaches i F v) (hv : v ≠ i) :
    depth i F (F v) + 1 = depth i F v := by
  have hd := depth_pos h hv
  apply le_antisymm
  · have : F^[depth i F v - 1] (F v) = i := by
      rw [← Function.iterate_succ_apply, Nat.succ_eq_add_one, Nat.sub_add_cancel hd]
      exact depth_spec h
    have := depth_le this
    omega
  · apply depth_le
    rw [Function.iterate_succ_apply]
    exact depth_spec (reaches_F h hv)

lemma depth_eq_zero {v : V} (h : Reaches i F v) (h0 : depth i F v = 0) : v = i := by
  have := depth_spec h; rwa [h0] at this

/-- The graph that joins each vertex to its parent `F v`. -/
def parentGraph (F : V → V) : SimpleGraph V := SimpleGraph.fromRel (fun v w => F v = w)

lemma parentGraph_adj {v w : V} : (parentGraph F).Adj v w ↔ v ≠ w ∧ (F v = w ∨ F w = v) :=
  SimpleGraph.fromRel_adj _ _ _

lemma parentGraph_adj_depth (hF : ∀ v, Reaches i F v) (hi : F i = i) {v w : V}
    (h : (parentGraph F).Adj v w) :
    depth i F v = depth i F w + 1 ∨ depth i F w = depth i F v + 1 := by
  rw [parentGraph_adj] at h
  obtain ⟨hne, h | h⟩ := h
  · have hv : v ≠ i := by rintro rfl; exact hne (hi ▸ h)
    subst h; exact Or.inl (depth_F (hF v) hv).symm
  · have hw : w ≠ i := by rintro rfl; exact hne (hi ▸ h).symm
    subst h; exact Or.inr (depth_F (hF w) hw).symm

lemma ne_F (hF : ∀ v, Reaches i F v) {v : V} (hv : v ≠ i) : v ≠ F v := by
  intro h
  have := depth_F (hF v) hv
  rw [← h] at this; omega

lemma parentGraph_connected [Nonempty V] (hF : ∀ v, Reaches i F v) :
    (parentGraph F).Connected := by
  have key : ∀ n, ∀ v, depth i F v = n → (parentGraph F).Reachable v i := by
    intro n
    induction n with
    | zero => intro v hv; rw [depth_eq_zero (hF v) hv]
    | succ n ih =>
      intro v hv
      have hvi : v ≠ i := by rintro rfl; rw [depth_self] at hv; omega
      have h1 := depth_F (hF v) hvi
      have hadj : (parentGraph F).Adj v (F v) := parentGraph_adj.2 ⟨ne_F hF hvi, Or.inl rfl⟩
      exact hadj.reachable.trans (ih _ (by omega))
  rw [connected_iff_exists_forall_reachable]
  exact ⟨i, fun v => (key _ v rfl).symm⟩

lemma card_edgeSet_parentGraph [Fintype V] [DecidableEq V] (hF : ∀ v, Reaches i F v)
    (hi : F i = i) : Nat.card (parentGraph F).edgeSet + 1 = Nat.card V := by
  let φ : {v // v ≠ i} → (parentGraph F).edgeSet := fun v =>
    ⟨s(v.1, F v.1), parentGraph_adj.2 ⟨ne_F hF v.2, Or.inl rfl⟩⟩
  have hφ : Function.Bijective φ := by
    constructor
    · rintro ⟨v, hv⟩ ⟨w, hw⟩ h
      have h := congrArg Subtype.val h
      simp only [φ, Sym2.eq_iff] at h
      rcases h with ⟨h1, -⟩ | ⟨h1, h2⟩
      · exact Subtype.ext h1
      · have a := depth_F (hF v) hv
        have b := depth_F (hF w) hw
        rw [h2] at a; rw [← h1] at b; omega
    · rintro ⟨e, he⟩
      induction e using Sym2.ind with
      | _ a b =>
        rw [mem_edgeSet, parentGraph_adj] at he
        obtain ⟨hne, h | h⟩ := he
        · have ha : a ≠ i := by rintro rfl; exact hne (hi ▸ h)
          exact ⟨⟨a, ha⟩, by simp [φ, h]⟩
        · have hb : b ≠ i := by rintro rfl; exact hne (hi ▸ h).symm
          exact ⟨⟨b, hb⟩, by simp [φ, h, Sym2.eq_swap]⟩
  rw [← Nat.card_congr (Equiv.ofBijective φ hφ)]
  simp [Nat.card_eq_fintype_card, Fintype.card_subtype_compl]
  have : 0 < Fintype.card V := Fintype.card_pos_iff.2 ⟨i⟩
  omega

lemma parentGraph_isTree [Fintype V] [DecidableEq V] (hF : ∀ v, Reaches i F v)
    (hi : F i = i) : (parentGraph F).IsTree := by
  have : Nonempty V := ⟨i⟩
  exact isTree_iff_connected_and_card.2 ⟨parentGraph_connected hF, card_edgeSet_parentGraph hF hi⟩

lemma depth_le_depth {F' : V → V} (hF : ∀ v, Reaches i F v) (hi : F i = i)
    (hF' : ∀ v, Reaches i F' v) (h : parentGraph F = parentGraph F') (v : V) :
    depth i F v ≤ depth i F' v := by
  suffices ∀ n, ∀ v, depth i F' v = n → depth i F v ≤ n from this _ v rfl
  intro n
  induction n with
  | zero => intro v hv; rw [depth_eq_zero (hF' v) hv, depth_self]
  | succ n ih =>
    intro v hv
    have hvi : v ≠ i := by rintro rfl; rw [depth_self] at hv; omega
    have h1 := depth_F (hF' v) hvi
    have hadj : (parentGraph F).Adj v (F' v) :=
      h ▸ parentGraph_adj.2 ⟨ne_F hF' hvi, Or.inl rfl⟩
    have h2 := ih (F' v) (by omega)
    rcases parentGraph_adj_depth hF hi hadj with h3 | h3 <;> omega

lemma parent_unique {F' : V → V} (hF : ∀ v, Reaches i F v) (hi : F i = i)
    (hF' : ∀ v, Reaches i F' v) (hi' : F' i = i) (h : parentGraph F = parentGraph F') :
    F = F' := by
  have hd : ∀ v, depth i F v = depth i F' v := fun v =>
    le_antisymm (depth_le_depth hF hi hF' h v) (depth_le_depth hF' hi' hF h.symm v)
  funext v
  by_cases hv : v = i
  · subst hv; rw [hi, hi']
  · have hadj : (parentGraph F).Adj v (F' v) :=
      h ▸ parentGraph_adj.2 ⟨ne_F hF' hv, Or.inl rfl⟩
    rw [parentGraph_adj] at hadj
    obtain ⟨hne, h1 | h1⟩ := hadj
    · exact h1
    · exfalso
      have hw : F' v ≠ i := by intro hw; rw [hw, hi] at h1; exact hv h1.symm
      have a := depth_F (hF (F' v)) hw
      rw [h1] at a
      have b := depth_F (hF' v) hv
      rw [← hd, ← hd] at b
      omega

lemma exists_parent {T : SimpleGraph V} (hT : T.Connected) {v : V} (hv : v ≠ i) :
    ∃ w, T.Adj v w ∧ T.dist w i < T.dist v i := by
  obtain ⟨p, hp⟩ := hT.exists_walk_length_eq_dist v i
  cases p with
  | nil => exact absurd rfl hv
  | cons h q =>
    refine ⟨_, h, ?_⟩
    have := dist_le q
    simp only [Walk.length_cons] at hp
    omega

open Classical in
/-- In a connected graph, a parent of each vertex one step nearer to `i`. -/
noncomputable def treeParent (i : V) {T : SimpleGraph V} (hT : T.Connected) (v : V) : V :=
  if h : v = i then i else Classical.choose (exists_parent hT h)

lemma treeParent_self {T : SimpleGraph V} (hT : T.Connected) : treeParent i hT i = i := by
  simp [treeParent]

lemma treeParent_spec {T : SimpleGraph V} (hT : T.Connected) {v : V} (hv : v ≠ i) :
    T.Adj v (treeParent i hT v) ∧ T.dist (treeParent i hT v) i < T.dist v i := by
  simp only [treeParent, hv, dite_false]
  exact Classical.choose_spec (exists_parent hT hv)

lemma treeParent_reaches {T : SimpleGraph V} (hT : T.Connected) (v : V) :
    Reaches i (treeParent i hT) v := by
  induction h : T.dist v i using Nat.strong_induction_on generalizing v with
  | _ n ih =>
    by_cases hv : v = i
    · exact ⟨0, hv⟩
    · exact reaches_of_F (ih _ (h ▸ (treeParent_spec hT hv).2) _ rfl)

lemma parentGraph_treeParent_le {T : SimpleGraph V} (hT : T.Connected) :
    parentGraph (treeParent i hT) ≤ T := by
  intro a b h
  rw [parentGraph_adj] at h
  obtain ⟨hne, h | h⟩ := h
  · have ha : a ≠ i := by rintro rfl; rw [treeParent_self] at h; exact hne h
    exact h ▸ (treeParent_spec hT ha).1
  · have hb : b ≠ i := by rintro rfl; rw [treeParent_self] at h; exact hne h.symm
    exact (h ▸ (treeParent_spec hT hb).1).symm

lemma eq_of_le_isTree [Finite V] {H T : SimpleGraph V} (hle : H ≤ T) (hH : H.IsTree)
    (hT : T.IsTree) : H = T := by
  have a := hH.ncard_edgeSet_add_one
  have b := hT.ncard_edgeSet_add_one
  rw [← edgeSet_inj]
  exact Set.eq_of_subset_of_ncard_le (edgeSet_subset_edgeSet.2 hle) (by omega) (Set.toFinite _)

end parent

section det
variable {V : Type*} [Fintype V] [DecidableEq V] (i : V)

/-- Extend a parent choice on the other vertices by sending `i` to itself. -/
def extend (f : {j // j ≠ i} → V) : V → V := fun v => if h : v = i then i else f ⟨v, h⟩

lemma extend_self (f : {j // j ≠ i} → V) : extend i f i = i := by simp [extend]

lemma extend_val (f : {j // j ≠ i} → V) (v : {j // j ≠ i}) : extend i f v = f v := by
  simp [extend, v.2]

/-- Row `v` is `e_v - e_(f v)`, with the column of `i` cut. -/
def choiceMatrix (f : {j // j ≠ i} → V) : Matrix {j // j ≠ i} {j // j ≠ i} ℤ :=
  fun v w => (if v = w then 1 else 0) - (if f v = w.val then 1 else 0)

variable {i}

lemma det_choiceMatrix_of_reaches {f : {j // j ≠ i} → V}
    (h : ∀ v, Reaches i (extend i f) v) : (choiceMatrix i f).det = 1 := by
  set F := extend i f with hFdef
  let b : {j // j ≠ i} → ℕᵒᵈ := fun v => OrderDual.toDual (depth i F v)
  have hb : (choiceMatrix i f).BlockTriangular b := by
    intro v w hlt
    change depth i F v < depth i F w at hlt
    have hd := depth_F (h v) v.2
    have h1 : v ≠ w := by rintro rfl; omega
    have h2 : f v ≠ w.val := by
      intro e; rw [show F v = f v from extend_val i f v, e] at hd; omega
    simp [choiceMatrix, h1, h2]
  rw [hb.det]
  apply Finset.prod_eq_one
  intro a _
  have : (choiceMatrix i f).toSquareBlock b a = 1 := by
    ext ⟨v, hv⟩ ⟨w, hw⟩
    have hvw : depth i F v = depth i F w := by
      have := hv.trans hw.symm
      exact OrderDual.toDual_inj.1 this
    have hd := depth_F (h v) v.2
    have h2 : f v ≠ w.val := by
      intro e; rw [show F v = f v from extend_val i f v, e] at hd; omega
    simp only [toSquareBlock, toSquareBlockProp, toBlock_apply, choiceMatrix, h2, ite_false, sub_zero]
    by_cases e : v = w
    · subst e; simp
    · rw [one_apply_ne (fun h => e (congrArg Subtype.val h))]; simp [e]
  rw [this, det_one]

lemma det_choiceMatrix_of_not {f : {j // j ≠ i} → V}
    (h : ¬ ∀ v, Reaches i (extend i f) v) : (choiceMatrix i f).det = 0 := by
  set F := extend i f with hFdef
  simp only [not_forall] at h
  obtain ⟨v0, hv0⟩ := h
  classical
  rw [← exists_mulVec_eq_zero_iff]
  let y : V → ℤ := fun u => if Reaches i F u then 0 else 1
  have hyi : y i = 0 := by simp [y, Reaches, show ∃ k, F^[k] i = i from ⟨0, rfl⟩]
  have hv0i : v0 ≠ i := by rintro rfl; exact hv0 ⟨0, rfl⟩
  refine ⟨fun w => y w.val, ?_, ?_⟩
  · intro hz
    have := congrFun hz ⟨v0, hv0i⟩
    simp [y, hv0] at this
  · funext v
    have key : ∑ w : {j // j ≠ i}, (if f v = ↑w then y ↑w else 0) = y (f v) := by
      by_cases hfv : f v = i
      · rw [hfv, hyi]
        apply Finset.sum_eq_zero
        intro w _
        have : i ≠ ↑w := fun e => w.2 e.symm
        simp [this]
      · rw [Finset.sum_eq_single ⟨f v, hfv⟩]
        · simp
        · intro w _ hw
          have : f v ≠ ↑w := fun e => hw (Subtype.ext e.symm)
          simp [this]
        · simp
    have hyv : y v = y (f v) := by
      rw [← extend_val i f v]
      simp only [y]
      have : Reaches i F v ↔ Reaches i F (F v) :=
        ⟨fun h => reaches_F h v.2, reaches_of_F⟩
      rw [this]
    simp only [mulVec, dotProduct, choiceMatrix, sub_mul, Finset.sum_sub_distrib, ite_mul,
      one_mul, zero_mul, Finset.sum_ite_eq, Finset.mem_univ, ite_true, key, hyv, sub_self,
      Pi.zero_apply]

variable (G : SimpleGraph V) [DecidableRel G.Adj]

lemma lap_submatrix_eq (i : V) :
    (G.lapMatrix ℤ).submatrix (Subtype.val : {j // j ≠ i} → V) Subtype.val =
      fun v => ∑ u ∈ G.neighborFinset v.val,
        (fun w : {j // j ≠ i} => (if v = w then 1 else 0) - (if u = w.val then (1 : ℤ) else 0)) := by
  ext v w
  simp [Finset.sum_apply, lapMatrix, degMatrix, adjMatrix_apply, Finset.sum_sub_distrib,
    diagonal_apply, Subtype.ext_iff]

lemma det_lap_sub_eq_sum (i : V) :
    ((G.lapMatrix ℤ).submatrix (Subtype.val : {j // j ≠ i} → V) Subtype.val).det =
      ∑ f ∈ Fintype.piFinset (fun v : {j // j ≠ i} => G.neighborFinset v.val),
        (choiceMatrix i f).det := by
  rw [lap_submatrix_eq]
  exact (detRowAlternating).toMultilinearMap.map_sum_finset _ _

omit [Fintype V] [DecidableEq V] in
lemma parentGraph_le {F : V → V} (hi : F i = i) (h : ∀ v, v ≠ i → G.Adj v (F v)) :
    parentGraph F ≤ G := by
  intro a b hab
  rw [parentGraph_adj] at hab
  obtain ⟨hne, e | e⟩ := hab
  · have ha : a ≠ i := by rintro rfl; exact hne (hi ▸ e)
    exact e ▸ h a ha
  · have hb : b ≠ i := by rintro rfl; exact hne (hi ▸ e).symm
    exact (e ▸ h b hb).symm

open Classical in
lemma card_good_eq (i : V) :
    ((Fintype.piFinset (fun v : {j // j ≠ i} => G.neighborFinset v.val)).filter
      (fun f => ∀ v, Reaches i (extend i f) v)).card =
      Nat.card {T : SimpleGraph V // T ≤ G ∧ T.IsTree} := by
  set S := (Fintype.piFinset (fun v : {j // j ≠ i} => G.neighborFinset v.val)).filter
      (fun f => ∀ v, Reaches i (extend i f) v)
  have mem : ∀ f, f ∈ S ↔ (∀ v : {j // j ≠ i}, G.Adj v.1 (f v)) ∧ ∀ v, Reaches i (extend i f) v := by
    intro f
    simp [S, Fintype.mem_piFinset]
  let φ : S → {T : SimpleGraph V // T ≤ G ∧ T.IsTree} := fun f =>
    ⟨parentGraph (extend i f.1),
      parentGraph_le G (extend_self i f.1) (fun v hv => by
        have := ((mem f.1).1 f.2).1 ⟨v, hv⟩
        rwa [← extend_val i f.1 ⟨v, hv⟩] at this),
      parentGraph_isTree ((mem f.1).1 f.2).2 (extend_self i f.1)⟩
  have hφ : Function.Bijective φ := by
    constructor
    · intro f g hfg
      have h1 := congrArg Subtype.val hfg
      have h2 := parent_unique ((mem f.1).1 f.2).2 (extend_self i f.1) ((mem g.1).1 g.2).2
        (extend_self i g.1) h1
      apply Subtype.ext
      funext v
      have := congrFun h2 v.1
      rwa [extend_val, extend_val] at this
    · rintro ⟨T, hle, hT⟩
      let F := treeParent i hT.connected
      let f : {j // j ≠ i} → V := fun v => F v.1
      have hext : extend i f = F := by
        funext v
        by_cases hv : v = i
        · rw [hv, extend_self]; exact (treeParent_self hT.connected).symm
        · exact extend_val i f ⟨v, hv⟩
      have hf : f ∈ S := by
        rw [mem, hext]
        exact ⟨fun v => hle (treeParent_spec hT.connected v.2).1, treeParent_reaches hT.connected⟩
      refine ⟨⟨f, hf⟩, Subtype.ext ?_⟩
      change parentGraph (extend i f) = T
      rw [hext]
      exact eq_of_le_isTree (parentGraph_treeParent_le hT.connected)
        (parentGraph_isTree (treeParent_reaches hT.connected) (treeParent_self hT.connected)) hT
  rw [← Nat.card_eq_finsetCard, Nat.card_congr (Equiv.ofBijective φ hφ)]

lemma det_cut_aux (i : V) :
    ((G.lapMatrix ℤ).submatrix (Subtype.val : {j // j ≠ i} → V) Subtype.val).det =
      (Nat.card {T : SimpleGraph V // T ≤ G ∧ T.IsTree} : ℤ) := by
  classical
  rw [det_lap_sub_eq_sum, ← card_good_eq, ← Finset.sum_boole]
  apply Finset.sum_congr rfl
  intro f _
  split_ifs with h
  · exact det_choiceMatrix_of_reaches h
  · exact det_choiceMatrix_of_not h

end det


section real
variable {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V) [DecidableRel G.Adj]

lemma det_cut_real (k : V) :
    ((G.lapMatrix ℝ).submatrix (Subtype.val : {j // j ≠ k} → V) Subtype.val).det =
      (Nat.card {T : SimpleGraph V // T ≤ G ∧ T.IsTree} : ℝ) := by
  have h : (G.lapMatrix ℝ).submatrix (Subtype.val : {j // j ≠ k} → V) Subtype.val =
      (Int.castRingHom ℝ).mapMatrix
        ((G.lapMatrix ℤ).submatrix (Subtype.val : {j // j ≠ k} → V) Subtype.val) := by
    ext a b
    simp only [RingHom.mapMatrix_apply, Matrix.map_apply, submatrix_apply, lapMatrix, degMatrix,
      Matrix.sub_apply, Matrix.diagonal_apply, adjMatrix_apply]
    split_ifs <;> simp
  rw [h, ← RingHom.map_det, det_cut_aux]
  simp

end real

lemma cayley_det {n : ℕ} (hn : 0 < n) :
    (((⊤ : SimpleGraph (Fin n)).lapMatrix ℤ).submatrix
      (Subtype.val : {j // j ≠ (⟨0, hn⟩ : Fin n)} → Fin n) Subtype.val).det =
      (n : ℤ) ^ (n - 2) := by
  set i : Fin n := ⟨0, hn⟩
  set M := ((⊤ : SimpleGraph (Fin n)).lapMatrix ℤ).submatrix
    (Subtype.val : {j // j ≠ i} → Fin n) Subtype.val
  have hm : Fintype.card {j // j ≠ i} = n - 1 := by simp [Fintype.card_subtype_compl]
  have hnq : (n : ℚ) ≠ 0 := by exact_mod_cast hn.ne'
  have key : (Int.castRingHom ℚ).mapMatrix M = (n : ℚ) • (1 + replicateCol Unit
      (fun _ : {j // j ≠ i} => -(n : ℚ)⁻¹) * replicateRow Unit (fun _ => (1 : ℚ))) := by
    ext j k
    by_cases h : j = k
    · subst h
      simp [M, Matrix.natCast_apply, Matrix.mul_apply]
      field_simp
      ring
    · have h' : j.1 ≠ k.1 := fun e => h (Subtype.ext e)
      simp [M, Matrix.natCast_apply, h', one_apply_ne h, Matrix.mul_apply]
      field_simp
  have : ((M.det : ℤ) : ℚ) = (n : ℚ) ^ (n - 2) := by
    rw [show ((M.det : ℤ) : ℚ) = Int.castRingHom ℚ M.det from rfl, RingHom.map_det, key,
      det_smul, det_one_add_replicateCol_mul_replicateRow, hm]
    simp [dotProduct, hm]
    rcases n with _ | k
    · omega
    rcases k with _ | j
    · simp
    · push_cast
      field_simp
      ring
  exact_mod_cast this


lemma adjugate_apply_self {V R : Type*} [Fintype V] [DecidableEq V] [CommRing R]
    (A : Matrix V V R) (k : V) :
    adjugate A k k = (A.submatrix (Subtype.val : {j // j ≠ k} → V) Subtype.val).det := by
  rw [adjugate_apply, twoBlockTriangular_det _ (fun j => j ≠ k)]
  · have h1 : toSquareBlockProp (A.updateRow k (Pi.single k 1)) (fun j => j ≠ k) =
        A.submatrix (Subtype.val : {j // j ≠ k} → V) Subtype.val := by
      ext a b
      simp [toSquareBlockProp, toBlock_apply, updateRow_ne a.2]
    have h2 : toSquareBlockProp (A.updateRow k (Pi.single k 1)) (fun j => ¬ j ≠ k) = 1 := by
      ext ⟨a, ha⟩ ⟨b, hb⟩
      simp only [not_not] at ha hb
      subst ha; subst hb
      simp [toSquareBlockProp, toBlock_apply]
    rw [h1, h2, det_one, mul_one]
  · intro r hr c hc
    simp only [not_not] at hr
    subst hr
    simp [hc]

lemma trace_adjugate_eq {V : Type*} [Fintype V] [DecidableEq V] {A : Matrix V V ℝ}
    (hA : A.IsHermitian) :
    (adjugate A).trace = ∑ k, ∏ l ∈ Finset.univ.erase k, hA.eigenvalues l := by
  conv_lhs => rw [hA.spectral_theorem, Unitary.conjStarAlgAut_apply]
  rw [adjugate_mul_distrib, adjugate_mul_distrib, ← Matrix.mul_assoc, trace_mul_cycle,
    ← adjugate_mul_distrib, Unitary.coe_star_mul_self, adjugate_one, Matrix.one_mul,
    adjugate_diagonal, trace_diagonal]
  simp

lemma sum_prod_erase_of_zero {V : Type*} [Fintype V] [DecidableEq V] (μ : V → ℝ) {j : V}
    (hj : μ j = 0) :
    ∑ k, ∏ l ∈ Finset.univ.erase k, μ l = ∏ l ∈ Finset.univ.erase j, μ l := by
  rw [Finset.sum_eq_single j]
  · intro k _ hk
    exact Finset.prod_eq_zero (Finset.mem_erase.2 ⟨fun e => hk e.symm, Finset.mem_univ _⟩) hj
  · simp


#print axioms depth_spec
#print axioms depth_le
#print axioms depth_self
#print axioms depth_pos
#print axioms reaches_F
#print axioms reaches_of_F
#print axioms depth_F
#print axioms depth_eq_zero
#print axioms parentGraph_adj
#print axioms parentGraph_adj_depth
#print axioms ne_F
#print axioms parentGraph_connected
#print axioms card_edgeSet_parentGraph
#print axioms parentGraph_isTree
#print axioms depth_le_depth
#print axioms parent_unique
#print axioms exists_parent
#print axioms treeParent_self
#print axioms treeParent_spec
#print axioms treeParent_reaches
#print axioms parentGraph_treeParent_le
#print axioms eq_of_le_isTree
#print axioms extend_self
#print axioms extend_val
#print axioms det_choiceMatrix_of_reaches
#print axioms det_choiceMatrix_of_not
#print axioms lap_submatrix_eq
#print axioms det_lap_sub_eq_sum
#print axioms parentGraph_le
#print axioms card_good_eq
#print axioms det_cut_aux
#print axioms det_cut_real
#print axioms cayley_det
#print axioms adjugate_apply_self
#print axioms trace_adjugate_eq
#print axioms sum_prod_erase_of_zero


/-- Kirchhoff's matrix-tree theorem. Take the Laplacian `L = D - A` of a finite graph `G`
(degrees on the diagonal, `-1` in the cell of each joined pair), cut any one vertex's row and its
own column, and the determinant of what is left is the number of spanning trees of `G`: the
subgraphs on all the vertices that use only `G`'s edges, reach every vertex and close no loop.
A graph in pieces has none, and the determinant is then 0. -/
theorem det_cut_laplacian_eq_card_spanning_trees {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (i : V) :
    ((G.lapMatrix ℤ).submatrix (Subtype.val : {j // j ≠ i} → V) Subtype.val).det =
      (Nat.card {T : SimpleGraph V // T ≤ G ∧ T.IsTree} : ℤ) := by
  exact det_cut_aux G i

/-- The eigenvalue form. One eigenvalue of the Laplacian is always 0; leave out one such 0,
multiply the other eigenvalues, and the product is `n` times the number of spanning trees,
where `n` is the number of vertices. -/
theorem card_mul_spanning_trees_eq_prod_eigenvalues {V : Type*} [Fintype V] [DecidableEq V]
    [Nonempty V] (G : SimpleGraph V) [DecidableRel G.Adj] :
    (∃ j, (G.isHermitian_lapMatrix ℝ).eigenvalues j = 0) ∧
    ∀ j, (G.isHermitian_lapMatrix ℝ).eigenvalues j = 0 →
      (Fintype.card V : ℝ) * (Nat.card {T : SimpleGraph V // T ≤ G ∧ T.IsTree} : ℝ) =
        ∏ k ∈ Finset.univ.erase j, (G.isHermitian_lapMatrix ℝ).eigenvalues k := by
  constructor
  · have h0 := G.det_lapMatrix_eq_zero (R := ℝ)
    rw [(G.isHermitian_lapMatrix ℝ).det_eq_prod_eigenvalues] at h0
    obtain ⟨j, -, hj⟩ := Finset.prod_eq_zero_iff.1 h0
    exact ⟨j, by simpa using hj⟩
  · intro j hj
    rw [← sum_prod_erase_of_zero _ hj, ← trace_adjugate_eq (G.isHermitian_lapMatrix ℝ)]
    simp only [trace, diag_apply, adjugate_apply_self, det_cut_real, Finset.sum_const,
      Finset.card_univ, nsmul_eq_mul]

/-- Cayley's formula, recovered from the complete graph's Laplacian: with every pair of the
`n` vertices joined, there are `n ^ (n - 2)` spanning trees. -/
theorem cayley_spanning_trees_complete {n : ℕ} (hn : 0 < n) :
    Nat.card {T : SimpleGraph (Fin n) // T ≤ ⊤ ∧ T.IsTree} = n ^ (n - 2) := by
  have h := det_cut_aux (⊤ : SimpleGraph (Fin n)) ⟨0, hn⟩
  rw [cayley_det hn] at h
  exact_mod_cast h.symm

/-! The card's worked numbers. The office: switches P, Q, R, W, every pair cabled but R-W. -/

/-- Cutting P's row and column from the office's Laplacian leaves determinant 12 - 2 - 2 = 8. -/
example : (!![3, -1, -1; -1, 2, 0; -1, 0, 2] : Matrix (Fin 3) (Fin 3) ℤ).det = 8 := by
  norm_num [det_fin_three]

/-- The office's eigenvalues 0, 2, 4, 4: the nonzero ones multiply to 32, and 32 / 4 = 8. -/
example : 2 * 4 * 4 = 4 * 8 := by norm_num

/-- Add the R-W cable, the full K4: the cut determinant is 16 = 4 ^ 2. -/
example : (((⊤ : SimpleGraph (Fin 4)).lapMatrix ℤ).submatrix
    (Fin.succAbove 0) (Fin.succAbove 0)).det = 16 := by
  simp [det_fin_three, lapMatrix, degMatrix]

/-- Cayley's count for K4: 4 ^ (4 - 2) = 16. -/
example : 4 ^ (4 - 2) = 16 := by norm_num

#print axioms det_cut_laplacian_eq_card_spanning_trees
#print axioms card_mul_spanning_trees_eq_prod_eigenvalues
#print axioms cayley_spanning_trees_complete

end MatrixTreeTheorem
