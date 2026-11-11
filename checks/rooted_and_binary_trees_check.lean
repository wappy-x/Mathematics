-- Rooted trees: a finite tree hung from a root, where every vertex has two children or none and every leaf sits at depth h, has 2^k vertices at each depth k, 2^(h+1) - 1 vertices in all, 2^h leaves and 2^h - 1 inner vertices, and in any such two-or-none tree the inner vertices run one behind the leaves.
import Mathlib.Combinatorics.SimpleGraph.Acyclic
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum

open SimpleGraph

/-- The children of `v` once the tree `G` hangs from the root `r`: the vertices joined to `v`
that sit one step deeper than `v`, depth being the distance from the root. -/
def children {V : Type*} (G : SimpleGraph V) (r v : V) : Set V :=
  {w | G.Adj v w ∧ G.dist r w = G.dist r v + 1}

lemma rbt_parent_unique {V : Type*} {G : SimpleGraph V} (hT : G.IsTree) (r : V) {v₁ v₂ w : V}
    (h₁ : G.Adj v₁ w) (e₁ : G.dist r w = G.dist r v₁ + 1)
    (h₂ : G.Adj v₂ w) (e₂ : G.dist r w = G.dist r v₂ + 1) : v₁ = v₂ := by
  obtain ⟨p₁, hp₁⟩ := hT.connected.exists_walk_length_eq_dist r v₁
  obtain ⟨p₂, hp₂⟩ := hT.connected.exists_walk_length_eq_dist r v₂
  have q₁ : (p₁.concat h₁).IsPath := Walk.isPath_of_length_eq_dist _ (by simp [hp₁, e₁])
  have q₂ : (p₂.concat h₂).IsPath := Walk.isPath_of_length_eq_dist _ (by simp [hp₂, e₂])
  have := (hT.existsUnique_path r w).unique q₁ q₂
  have := congrArg (fun p => p.reverse.getVert 1) this
  simpa [Walk.reverse_concat] using this

#print axioms rbt_parent_unique

lemma rbt_parent_exists {V : Type*} {G : SimpleGraph V} (hT : G.IsTree) (r : V) {w : V}
    (hw : w ≠ r) : ∃ v, G.Adj v w ∧ G.dist r w = G.dist r v + 1 := by
  obtain ⟨p, hp⟩ := hT.connected.exists_walk_length_eq_dist w r
  cases p with
  | nil => exact absurd rfl hw
  | @cons _ v _ h q =>
    refine ⟨v, h.symm, ?_⟩
    have h1 : G.dist v r ≤ q.length := dist_le q
    have h2 : G.dist w r ≤ G.dist v r + 1 := by
      have := hT.connected.dist_triangle (u := w) (v := v) (w := r)
      rw [dist_eq_one_iff_adj.mpr h] at this
      omega
    simp at hp
    rw [dist_comm, dist_comm (u := r)]
    omega

#print axioms rbt_parent_exists

open Classical in
lemma rbt_ncard_setOf {V : Type*} [Fintype V] (p : V → Prop) [DecidablePred p] :
    {v | p v}.ncard = (Finset.univ.filter p).card := by
  rw [← Set.ncard_coe_finset]; simp

#print axioms rbt_ncard_setOf

open Classical in
lemma rbt_children_card {V : Type*} [Fintype V] (G : SimpleGraph V) (r v : V) :
    (children G r v).ncard =
      (Finset.univ.filter fun w => G.Adj v w ∧ G.dist r w = G.dist r v + 1).card :=
  rbt_ncard_setOf _

#print axioms rbt_children_card

open Classical in
lemma rbt_card_biUnion {V : Type*} [Fintype V] {G : SimpleGraph V} (hT : G.IsTree) (r : V)
    (S : Finset V) :
    (S.biUnion fun v => Finset.univ.filter fun w => G.Adj v w ∧ G.dist r w = G.dist r v + 1).card
      = ∑ v ∈ S, (children G r v).ncard := by
  rw [Finset.card_biUnion]
  · exact Finset.sum_congr rfl fun v _ => (rbt_children_card G r v).symm
  intro x _ y _ hxy
  show Disjoint _ _
  rw [Finset.disjoint_left]
  intro w hx hy
  simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hx hy
  exact hxy (rbt_parent_unique hT r hx.1 hx.2 hy.1 hy.2)

#print axioms rbt_card_biUnion

open Classical in
lemma rbt_sum_all {V : Type*} [Fintype V] {G : SimpleGraph V} (hT : G.IsTree) (r : V) :
    ∑ v, (children G r v).ncard + 1 = Fintype.card V := by
  rw [← rbt_card_biUnion hT r]
  have : (Finset.univ.biUnion fun v =>
      Finset.univ.filter fun w => G.Adj v w ∧ G.dist r w = G.dist r v + 1) = Finset.univ.erase r := by
    ext w
    simp only [Finset.mem_biUnion, Finset.mem_univ, Finset.mem_filter, true_and,
      Finset.mem_erase, and_true]
    constructor
    · rintro ⟨v, -, hv⟩ rfl
      simp at hv
    · intro hw
      exact rbt_parent_exists hT r hw
  rw [this, Finset.card_erase_of_mem (Finset.mem_univ r), Finset.card_univ]
  have := Fintype.card_pos_iff.mpr ⟨r⟩
  omega

#print axioms rbt_sum_all

open Classical in
lemma rbt_level_succ {V : Type*} [Fintype V] {G : SimpleGraph V} (hT : G.IsTree) (r : V) (k : ℕ) :
    {v | G.dist r v = k + 1}.ncard = ∑ v ∈ Finset.univ.filter (fun v => G.dist r v = k),
      (children G r v).ncard := by
  rw [← rbt_card_biUnion hT r, rbt_ncard_setOf]
  congr 1
  ext w
  simp only [Finset.mem_biUnion, Finset.mem_univ, Finset.mem_filter, true_and]
  constructor
  · intro hw
    obtain ⟨v, hv, e⟩ := rbt_parent_exists hT r (w := w) (by
      rintro rfl; simp at hw)
    exact ⟨v, by omega, hv, e⟩
  · rintro ⟨v, hv, h, e⟩
    omega

#print axioms rbt_level_succ

open Classical in
lemma rbt_inner_add_one {V : Type*} [Fintype V] {G : SimpleGraph V} (hT : G.IsTree) (r : V)
    (hfull : ∀ v, (children G r v).ncard = 0 ∨ (children G r v).ncard = 2) :
    {v | (children G r v).ncard ≠ 0}.ncard + 1 = {v | (children G r v).ncard = 0}.ncard := by
  have hs := rbt_sum_all hT r
  rw [← Finset.sum_filter_add_sum_filter_not Finset.univ (fun v => (children G r v).ncard ≠ 0)]
    at hs
  have h1 : ∑ v ∈ Finset.univ.filter (fun v => (children G r v).ncard ≠ 0),
      (children G r v).ncard = ∑ v ∈ Finset.univ.filter (fun v => (children G r v).ncard ≠ 0), 2 :=
    Finset.sum_congr rfl (fun v hv => by
      simp only [Finset.mem_filter] at hv; rcases hfull v with h | h <;> omega)
  have h2 : ∑ v ∈ Finset.univ.filter (fun v => ¬ (children G r v).ncard ≠ 0),
      (children G r v).ncard = 0 :=
    Finset.sum_eq_zero (fun v hv => by simpa using hv)
  rw [h1, h2, Finset.sum_const, smul_eq_mul] at hs
  rw [rbt_ncard_setOf, rbt_ncard_setOf]
  have := Finset.card_filter_add_card_filter_not (s := Finset.univ)
    (fun v => (children G r v).ncard ≠ 0)
  simp only [not_not, Finset.card_univ] at this
  omega

#print axioms rbt_inner_add_one

open Classical in
lemma rbt_perfect {V : Type*} [Fintype V] {G : SimpleGraph V} (hT : G.IsTree) (r : V) (h : ℕ)
    (hfull : ∀ v, (children G r v).ncard = 0 ∨ (children G r v).ncard = 2)
    (hlevel : ∀ v, (children G r v).ncard = 0 → G.dist r v = h) :
    (∀ k ≤ h, {v | G.dist r v = k}.ncard = 2 ^ k) ∧
      {v | (children G r v).ncard = 0}.ncard = 2 ^ h ∧
      {v | (children G r v).ncard ≠ 0}.ncard = 2 ^ h - 1 ∧
      Fintype.card V = 2 ^ (h + 1) - 1 := by
  have hle : ∀ v, G.dist r v ≤ h := by
    obtain ⟨m, -, hm⟩ := Finset.exists_max_image Finset.univ (fun v => G.dist r v)
      ⟨r, Finset.mem_univ r⟩
    have hleaf : (children G r m).ncard = 0 := by
      rw [Set.ncard_eq_zero]
      ext w
      simp only [children, Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_and]
      intro _ hw
      have := hm w (Finset.mem_univ w)
      omega
    intro v
    have := hm v (Finset.mem_univ v)
    have := hlevel m hleaf
    omega
  have hleaf_iff : ∀ v, (children G r v).ncard = 0 ↔ G.dist r v = h := by
    intro v
    refine ⟨hlevel v, fun hv => ?_⟩
    rw [Set.ncard_eq_zero]
    ext w
    simp only [children, Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_and]
    intro _ hw
    have := hle w
    omega
  have hlev : ∀ k ≤ h, {v | G.dist r v = k}.ncard = 2 ^ k := by
    intro k
    induction k with
    | zero =>
      intro _
      rw [show {v | G.dist r v = 0} = {r} from ?_]
      · simp
      ext v
      simp [hT.connected.dist_eq_zero_iff, eq_comm]
    | succ k ih =>
      intro hk
      rw [rbt_level_succ hT r k, Finset.sum_congr rfl (g := fun _ => 2) ?_, Finset.sum_const,
        smul_eq_mul, ← rbt_ncard_setOf, ih (by omega), pow_succ]
      intro v hv
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hv
      rcases hfull v with h0 | h2
      · have := (hleaf_iff v).1 h0
        omega
      · exact h2
  have hleaves : {v | (children G r v).ncard = 0}.ncard = 2 ^ h := by
    rw [show {v | (children G r v).ncard = 0} = {v | G.dist r v = h} from
      Set.ext fun v => hleaf_iff v]
    exact hlev h le_rfl
  have hin := rbt_inner_add_one hT r hfull
  have htot : {v | (children G r v).ncard ≠ 0}.ncard + {v | (children G r v).ncard = 0}.ncard =
      Fintype.card V := by
    rw [rbt_ncard_setOf, rbt_ncard_setOf]
    have := Finset.card_filter_add_card_filter_not (s := Finset.univ)
      (fun v => (children G r v).ncard ≠ 0)
    simpa only [not_not, Finset.card_univ] using this
  refine ⟨hlev, hleaves, by omega, ?_⟩
  rw [pow_succ]
  omega

#print axioms rbt_perfect

/-- The vertex count of a perfect binary tree. Take a tree with finitely many vertices and name
one vertex `r` its root. If every vertex has two children or none, and every leaf (a vertex with
no children) sits at the same depth `h`, then the tree has `1 + 2 + 4 + ⋯ + 2^h = 2^(h+1) − 1`
vertices. -/
theorem perfect_binary_tree_card {V : Type*} [Finite V] (G : SimpleGraph V) (hT : G.IsTree)
    (r : V) (h : ℕ)
    (hfull : ∀ v, (children G r v).ncard = 0 ∨ (children G r v).ncard = 2)
    (hlevel : ∀ v, (children G r v).ncard = 0 → G.dist r v = h) :
    Nat.card V = 2 ^ (h + 1) - 1 := by
  have := Fintype.ofFinite V
  rw [Nat.card_eq_fintype_card]
  exact (rbt_perfect hT r h hfull hlevel).2.2.2

/-- The levels double. In the same perfect binary tree, depth `k` holds `2^k` vertices for every
`k` from `0` to `h`, the leaves number `2^h`, the inner vertices (those with children) number
`2^h − 1`, and the parent-child links, which are the edges, number `2^(h+1) − 2`, one fewer than
the vertices. -/
theorem perfect_binary_tree_levels {V : Type*} [Finite V] (G : SimpleGraph V) (hT : G.IsTree)
    (r : V) (h : ℕ)
    (hfull : ∀ v, (children G r v).ncard = 0 ∨ (children G r v).ncard = 2)
    (hlevel : ∀ v, (children G r v).ncard = 0 → G.dist r v = h) :
    (∀ k ≤ h, {v | G.dist r v = k}.ncard = 2 ^ k) ∧
      {v | (children G r v).ncard = 0}.ncard = 2 ^ h ∧
      {v | (children G r v).ncard ≠ 0}.ncard = 2 ^ h - 1 ∧
      G.edgeSet.ncard = 2 ^ (h + 1) - 2 := by
  have := Fintype.ofFinite V
  obtain ⟨h1, h2, h3, h4⟩ := rbt_perfect hT r h hfull hlevel
  refine ⟨h1, h2, h3, ?_⟩
  have he := hT.ncard_edgeSet_add_one
  rw [Nat.card_eq_fintype_card] at he
  omega

/-- Inner vertices run one behind leaves, whatever the height. In any rooted tree with finitely
many vertices where every vertex has two children or none, the inner vertices plus one equal the
leaves: sixteen teams need fifteen matches, however the draw is laid out. -/
theorem full_binary_tree_inner_add_one_eq_leaves {V : Type*} [Finite V] (G : SimpleGraph V)
    (hT : G.IsTree) (r : V)
    (hfull : ∀ v, (children G r v).ncard = 0 ∨ (children G r v).ncard = 2) :
    {v | (children G r v).ncard ≠ 0}.ncard + 1 = {v | (children G r v).ncard = 0}.ncard := by
  have := Fintype.ofFinite V
  exact rbt_inner_add_one hT r hfull

-- The cup draw, height 4: the five levels, the total, and its closed form.
example : [0, 1, 2, 3, 4].map (2 ^ ·) = [1, 2, 4, 8, 16] := by decide
example : 1 + 2 + 4 + 8 + 16 = 31 ∧ 2 ^ (4 + 1) - 1 = 31 := by norm_num
-- Leaves 2^4 = 16 teams, inner 2^4 - 1 = 15 matches, and the matches two ways: 31 - 16 and 16 - 1.
example : 2 ^ 4 = 16 ∧ 2 ^ 4 - 1 = 15 ∧ 31 - 16 = 15 ∧ 16 - 1 = 15 := by norm_num
-- Edges: 31 - 1 = 30.
example : 31 - 1 = 30 := by norm_num
-- The folder tree, height 2: 2^3 - 1 = 7 vertices, totals 4 + 2, 5 + 3, then 6 + 8 megabytes.
example : 2 ^ (2 + 1) - 1 = 7 ∧ 4 + 2 = 6 ∧ 5 + 3 = 8 ∧ 6 + 8 = 14 := by norm_num
-- The two mistakes: five levels read as the height gives 63, the ladder's depth 15 gives 65535.
example : 2 ^ (5 + 1) - 1 = 63 ∧ 2 ^ (15 + 1) - 1 = 65535 := by norm_num

#print axioms perfect_binary_tree_card
#print axioms perfect_binary_tree_levels
#print axioms full_binary_tree_inner_add_one_eq_leaves
