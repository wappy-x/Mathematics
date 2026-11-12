-- Embedded pairs: for the seven Dormand-Prince stages, the order conditions of every rooted tree with up to 5 nodes allow exactly one set of weights, those with up to 4 nodes allow a line of weights through the two published sets, and the fourth-order weights miss every 5-node condition.
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination

/-! A rooted tree is a root carrying a list of subtrees, written in brackets on the card:
`node []` is `[]`, a single node. The order of the subtrees in the list does not change any
number below, so each tree on the card appears here (perhaps several times, in different orders).

For a stage table `A` with `s` stages (numbered `0, …, s - 1` here, from 1 on the card):
* `Φ_i` of a single node is 1; for a root carrying subtrees, `Φ_i` multiplies, over the
  subtrees, `∑_j a_ij Φ_j(subtree)` (the card's Step 1).
* `γ` is the tree's node count times the `γ` of each subtree.
* The order condition of a tree is `∑_i b_i Φ_i(tree) = 1 / γ(tree)`; weights `b` have order
  `p` when they pass the condition of every tree with at most `p` nodes. -/

inductive RTree
  | node : List RTree → RTree

namespace RTree

mutual
/-- The number of nodes of a tree. -/
def nodes : RTree → ℕ
  | node ts => 1 + nodesList ts
/-- The total number of nodes of a list of trees. -/
def nodesList : List RTree → ℕ
  | [] => 0
  | t :: ts => nodes t + nodesList ts
end

mutual
/-- The density `γ`: node count times the density of each subtree. -/
def gamma : RTree → ℕ
  | node ts => (1 + nodesList ts) * gammaList ts
/-- The product of the densities of a list of trees. -/
def gammaList : List RTree → ℕ
  | [] => 1
  | t :: ts => gamma t * gammaList ts
end

mutual
/-- The elementary weight `Φ_i(tree)` of every stage `i`, built from the stage table alone. -/
def phi {s : ℕ} (A : Matrix (Fin s) (Fin s) ℝ) : RTree → Fin s → ℝ
  | node ts => phiList A ts
/-- The product, over a list of subtrees, of `∑_j a_ij Φ_j(subtree)`. -/
def phiList {s : ℕ} (A : Matrix (Fin s) (Fin s) ℝ) : List RTree → Fin s → ℝ
  | [] => fun _ => 1
  | t :: ts => fun i => (∑ j, A i j * phi A t j) * phiList A ts i
end

end RTree

open RTree

/-- The order condition of one tree: `∑_i b_i Φ_i(tree) = 1 / γ(tree)`. -/
def OrderCondition {s : ℕ} (A : Matrix (Fin s) (Fin s) ℝ) (b : Fin s → ℝ) (t : RTree) : Prop :=
  ∑ i, b i * phi A t i = 1 / (gamma t : ℝ)

/-- Weights `b` have order `p` on the stage table `A`: they pass the order condition of every
rooted tree with at most `p` nodes. -/
def HasOrder {s : ℕ} (A : Matrix (Fin s) (Fin s) ℝ) (b : Fin s → ℝ) (p : ℕ) : Prop :=
  ∀ t : RTree, t.nodes ≤ p → OrderCondition A b t

/-- The Dormand-Prince stage table `a_ij` (seven stages; its last row equals the fifth-order
weights). The stage times `c_i` are its row sums. -/
noncomputable def dpA : Matrix (Fin 7) (Fin 7) ℝ :=
  !![0, 0, 0, 0, 0, 0, 0;
     1/5, 0, 0, 0, 0, 0, 0;
     3/40, 9/40, 0, 0, 0, 0, 0;
     44/45, -56/15, 32/9, 0, 0, 0, 0;
     19372/6561, -25360/2187, 64448/6561, -212/729, 0, 0, 0;
     9017/3168, -355/33, 46732/5247, 49/176, -5103/18656, 0, 0;
     35/384, 0, 500/1113, 125/192, -2187/6784, 11/84, 0]

/-- The published fifth-order weights `b`. -/
noncomputable def dpB : Fin 7 → ℝ := ![35/384, 0, 500/1113, 125/192, -2187/6784, 11/84, 0]

/-- The published fourth-order weights `b̂`, the choice `b̂_7 = 1/40`. -/
noncomputable def dpBhat : Fin 7 → ℝ :=
  ![5179/57600, 0, 7571/16695, 393/640, -92097/339200, 187/2100, 1/40]

/-- The bushy tree `[[][][][]]`: a root with four leaves. -/
def bushy : RTree := node [node [], node [], node [], node []]

/-- The tall tree `[[[[[]]]]]`: a chain of five nodes. -/
def tall : RTree := node [node [node [node [node []]]]]

/-! ## Helper definitions and lemmas for the proofs below -/

namespace DPProof

/-- `Φ` of a tree, as a product over its subtrees. -/
theorem phi_node {s : ℕ} (A : Matrix (Fin s) (Fin s) ℝ) (ts : List RTree) :
    phi A (node ts) = fun i => (ts.map fun t => ∑ j, A i j * phi A t j).prod := by
  funext i
  rw [phi]
  induction ts with
  | nil => rfl
  | cons t ts ih => simp only [phiList, List.map_cons, List.prod_cons, ih]
#print axioms phi_node

theorem nodes_pos (t : RTree) : 1 ≤ t.nodes := by
  cases t with
  | node ts => rw [nodes]; omega
#print axioms nodes_pos

/-- Every ordered list of trees with `n` nodes in all, and every tree with `n + 1` nodes. -/
def F0 : List (List RTree) := [[]]
def T1 : List RTree := F0.map node
def F1 : List (List RTree) := T1.flatMap fun t => F0.map (t :: ·)
def T2 : List RTree := F1.map node
def F2 : List (List RTree) :=
  (T1.flatMap fun t => F1.map (t :: ·)) ++ (T2.flatMap fun t => F0.map (t :: ·))
def T3 : List RTree := F2.map node
def F3 : List (List RTree) :=
  (T1.flatMap fun t => F2.map (t :: ·)) ++ (T2.flatMap fun t => F1.map (t :: ·)) ++
    (T3.flatMap fun t => F0.map (t :: ·))
def T4 : List RTree := F3.map node
def F4 : List (List RTree) :=
  (T1.flatMap fun t => F3.map (t :: ·)) ++ (T2.flatMap fun t => F2.map (t :: ·)) ++
    (T3.flatMap fun t => F1.map (t :: ·)) ++ (T4.flatMap fun t => F0.map (t :: ·))
def T5 : List RTree := F4.map node

theorem mem_map_node (n : ℕ) {Fl : List (List RTree)} (hF : ∀ ts, nodesList ts = n → ts ∈ Fl)
    {t : RTree} (h : t.nodes = n + 1) : t ∈ Fl.map node := by
  cases t with
  | node ts =>
    rw [nodes] at h
    exact List.mem_map.2 ⟨ts, hF ts (by omega), rfl⟩
#print axioms mem_map_node

theorem mem_block {Tl : List RTree} {Fl : List (List RTree)} {t : RTree} {r : List RTree}
    (ht : t ∈ Tl) (hr : r ∈ Fl) : t :: r ∈ Tl.flatMap fun t => Fl.map (t :: ·) :=
  List.mem_flatMap.2 ⟨t, ht, List.mem_map.2 ⟨r, hr, rfl⟩⟩
#print axioms mem_block

theorem mem_F0 (ts : List RTree) (h : nodesList ts = 0) : ts ∈ F0 := by
  cases ts with
  | nil => simp [F0]
  | cons t r => rw [nodesList] at h; have := nodes_pos t; omega
#print axioms mem_F0

theorem mem_F1 (ts : List RTree) (h : nodesList ts = 1) : ts ∈ F1 := by
  cases ts with
  | nil => rw [nodesList] at h; omega
  | cons t r =>
    rw [nodesList] at h
    have := nodes_pos t
    obtain hk : t.nodes = 0 + 1 := by omega
    · exact mem_block (mem_map_node 0 mem_F0 hk) (mem_F0 r (by omega))
#print axioms mem_F1

theorem mem_F2 (ts : List RTree) (h : nodesList ts = 2) : ts ∈ F2 := by
  cases ts with
  | nil => rw [nodesList] at h; omega
  | cons t r =>
    rw [nodesList] at h
    have := nodes_pos t
    obtain hk | hk : t.nodes = 0 + 1 ∨ t.nodes = 1 + 1 := by omega
    · exact List.mem_append_left _ (mem_block (mem_map_node 0 mem_F0 hk) (mem_F1 r (by omega)))
    · exact List.mem_append_right _ (mem_block (mem_map_node 1 mem_F1 hk) (mem_F0 r (by omega)))
#print axioms mem_F2

theorem mem_F3 (ts : List RTree) (h : nodesList ts = 3) : ts ∈ F3 := by
  cases ts with
  | nil => rw [nodesList] at h; omega
  | cons t r =>
    rw [nodesList] at h
    have := nodes_pos t
    obtain hk | hk | hk : t.nodes = 0 + 1 ∨ t.nodes = 1 + 1 ∨ t.nodes = 2 + 1 := by omega
    · exact List.mem_append_left _ (List.mem_append_left _ (mem_block (mem_map_node 0 mem_F0 hk) (mem_F2 r (by omega))))
    · exact List.mem_append_left _ (List.mem_append_right _ (mem_block (mem_map_node 1 mem_F1 hk) (mem_F1 r (by omega))))
    · exact List.mem_append_right _ (mem_block (mem_map_node 2 mem_F2 hk) (mem_F0 r (by omega)))
#print axioms mem_F3

theorem mem_F4 (ts : List RTree) (h : nodesList ts = 4) : ts ∈ F4 := by
  cases ts with
  | nil => rw [nodesList] at h; omega
  | cons t r =>
    rw [nodesList] at h
    have := nodes_pos t
    obtain hk | hk | hk | hk : t.nodes = 0 + 1 ∨ t.nodes = 1 + 1 ∨ t.nodes = 2 + 1 ∨ t.nodes = 3 + 1 := by omega
    · exact List.mem_append_left _ (List.mem_append_left _ (List.mem_append_left _ (mem_block (mem_map_node 0 mem_F0 hk) (mem_F3 r (by omega)))))
    · exact List.mem_append_left _ (List.mem_append_left _ (List.mem_append_right _ (mem_block (mem_map_node 1 mem_F1 hk) (mem_F2 r (by omega)))))
    · exact List.mem_append_left _ (List.mem_append_right _ (mem_block (mem_map_node 2 mem_F2 hk) (mem_F1 r (by omega))))
    · exact List.mem_append_right _ (mem_block (mem_map_node 3 mem_F3 hk) (mem_F0 r (by omega)))
#print axioms mem_F4

theorem all_le_five_eq : T1 ++ T2 ++ T3 ++ T4 ++ T5 =
    [node [],
    node [node []],
    node [node [], node []],
    node [node [node []]],
    node [node [], node [], node []],
    node [node [], node [node []]],
    node [node [node []], node []],
    node [node [node [], node []]],
    node [node [node [node []]]],
    node [node [], node [], node [], node []],
    node [node [], node [], node [node []]],
    node [node [], node [node []], node []],
    node [node [], node [node [], node []]],
    node [node [], node [node [node []]]],
    node [node [node []], node [], node []],
    node [node [node []], node [node []]],
    node [node [node [], node []], node []],
    node [node [node [node []]], node []],
    node [node [node [], node [], node []]],
    node [node [node [], node [node []]]],
    node [node [node [node []], node []]],
    node [node [node [node [], node []]]],
    node [node [node [node [node []]]]]] := rfl
#print axioms all_le_five_eq

theorem all_le_four_eq : T1 ++ T2 ++ T3 ++ T4 =
    [node [],
    node [node []],
    node [node [], node []],
    node [node [node []]],
    node [node [], node [], node []],
    node [node [], node [node []]],
    node [node [node []], node []],
    node [node [node [], node []]],
    node [node [node [node []]]]] := rfl
#print axioms all_le_four_eq

theorem all_five_eq : T5 =
    [node [node [], node [], node [], node []],
    node [node [], node [], node [node []]],
    node [node [], node [node []], node []],
    node [node [], node [node [], node []]],
    node [node [], node [node [node []]]],
    node [node [node []], node [], node []],
    node [node [node []], node [node []]],
    node [node [node [], node []], node []],
    node [node [node [node []]], node []],
    node [node [node [], node [], node []]],
    node [node [node [], node [node []]]],
    node [node [node [node []], node []]],
    node [node [node [node [], node []]]],
    node [node [node [node [node []]]]]] := rfl
#print axioms all_five_eq

theorem forall_le_five {P : RTree → Prop} (h : ∀ t ∈ T1 ++ T2 ++ T3 ++ T4 ++ T5, P t)
    (t : RTree) (ht : t.nodes ≤ 5) : P t := by
  apply h
  obtain hk | hk | hk | hk | hk : t.nodes = 0 + 1 ∨ t.nodes = 1 + 1 ∨ t.nodes = 2 + 1 ∨ t.nodes = 3 + 1 ∨ t.nodes = 4 + 1 := by have := nodes_pos t; omega
  · exact List.mem_append_left _ (List.mem_append_left _ (List.mem_append_left _ (List.mem_append_left _ (mem_map_node 0 mem_F0 hk))))
  · exact List.mem_append_left _ (List.mem_append_left _ (List.mem_append_left _ (List.mem_append_right _ (mem_map_node 1 mem_F1 hk))))
  · exact List.mem_append_left _ (List.mem_append_left _ (List.mem_append_right _ (mem_map_node 2 mem_F2 hk)))
  · exact List.mem_append_left _ (List.mem_append_right _ (mem_map_node 3 mem_F3 hk))
  · exact List.mem_append_right _ (mem_map_node 4 mem_F4 hk)
#print axioms forall_le_five

theorem forall_le_four {P : RTree → Prop} (h : ∀ t ∈ T1 ++ T2 ++ T3 ++ T4, P t)
    (t : RTree) (ht : t.nodes ≤ 4) : P t := by
  apply h
  obtain hk | hk | hk | hk : t.nodes = 0 + 1 ∨ t.nodes = 1 + 1 ∨ t.nodes = 2 + 1 ∨ t.nodes = 3 + 1 := by have := nodes_pos t; omega
  · exact List.mem_append_left _ (List.mem_append_left _ (List.mem_append_left _ (mem_map_node 0 mem_F0 hk)))
  · exact List.mem_append_left _ (List.mem_append_left _ (List.mem_append_right _ (mem_map_node 1 mem_F1 hk)))
  · exact List.mem_append_left _ (List.mem_append_right _ (mem_map_node 2 mem_F2 hk))
  · exact List.mem_append_right _ (mem_map_node 3 mem_F3 hk)
#print axioms forall_le_four

theorem forall_eq_five {P : RTree → Prop} (h : ∀ t ∈ T5, P t) (t : RTree) (ht : t.nodes = 5) :
    P t :=
  h t (mem_map_node 4 mem_F4 ht)
#print axioms forall_eq_five

theorem phi_0 : phi dpA (node []) =
    ![(1 : ℝ), (1 : ℝ), (1 : ℝ), (1 : ℝ), (1 : ℝ), (1 : ℝ), (1 : ℝ)] := by
  rw [phi_node]
  funext i
  fin_cases i <;> rfl
#print axioms phi_0

theorem gamma_0 : gamma (node []) = 1 := by decide
#print axioms gamma_0

theorem oc_0 (w : Fin 7 → ℝ) : OrderCondition dpA w (node []) ↔
    w 0 * (1 : ℝ) + w 1 * (1 : ℝ) + w 2 * (1 : ℝ) + w 3 * (1 : ℝ) + w 4 * (1 : ℝ) + w 5 * (1 : ℝ) + w 6 * (1 : ℝ) = 1 / (1 : ℝ) := by
  rw [OrderCondition, phi_0, gamma_0, Fin.sum_univ_seven]
  norm_num
#print axioms oc_0

theorem phi_1 : phi dpA (node [node []]) =
    ![(0 : ℝ), (1/5 : ℝ), (3/10 : ℝ), (4/5 : ℝ), (8/9 : ℝ), (1 : ℝ), (1 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_1

theorem gamma_1 : gamma (node [node []]) = 2 := by decide
#print axioms gamma_1

theorem oc_1 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node []]) ↔
    w 1 * (1/5 : ℝ) + w 2 * (3/10 : ℝ) + w 3 * (4/5 : ℝ) + w 4 * (8/9 : ℝ) + w 5 * (1 : ℝ) + w 6 * (1 : ℝ) = 1 / (2 : ℝ) := by
  rw [OrderCondition, phi_1, gamma_1, Fin.sum_univ_seven]
  norm_num
#print axioms oc_1

theorem phi_2 : phi dpA (node [node [], node []]) =
    ![(0 : ℝ), (1/25 : ℝ), (9/100 : ℝ), (16/25 : ℝ), (64/81 : ℝ), (1 : ℝ), (1 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_2

theorem gamma_2 : gamma (node [node [], node []]) = 3 := by decide
#print axioms gamma_2

theorem oc_2 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [], node []]) ↔
    w 1 * (1/25 : ℝ) + w 2 * (9/100 : ℝ) + w 3 * (16/25 : ℝ) + w 4 * (64/81 : ℝ) + w 5 * (1 : ℝ) + w 6 * (1 : ℝ) = 1 / (3 : ℝ) := by
  rw [OrderCondition, phi_2, gamma_2, Fin.sum_univ_seven]
  norm_num
#print axioms oc_2

theorem phi_3 : phi dpA (node [node [node []]]) =
    ![(0 : ℝ), (0 : ℝ), (9/200 : ℝ), (8/25 : ℝ), (32/81 : ℝ), (1/2 : ℝ), (1/2 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_1]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_3

theorem gamma_3 : gamma (node [node [node []]]) = 6 := by decide
#print axioms gamma_3

theorem oc_3 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node []]]) ↔
    w 2 * (9/200 : ℝ) + w 3 * (8/25 : ℝ) + w 4 * (32/81 : ℝ) + w 5 * (1/2 : ℝ) + w 6 * (1/2 : ℝ) = 1 / (6 : ℝ) := by
  rw [OrderCondition, phi_3, gamma_3, Fin.sum_univ_seven]
  norm_num
#print axioms oc_3

theorem phi_4 : phi dpA (node [node [], node [], node []]) =
    ![(0 : ℝ), (1/125 : ℝ), (27/1000 : ℝ), (64/125 : ℝ), (512/729 : ℝ), (1 : ℝ), (1 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_4

theorem gamma_4 : gamma (node [node [], node [], node []]) = 4 := by decide
#print axioms gamma_4

theorem oc_4 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [], node [], node []]) ↔
    w 1 * (1/125 : ℝ) + w 2 * (27/1000 : ℝ) + w 3 * (64/125 : ℝ) + w 4 * (512/729 : ℝ) + w 5 * (1 : ℝ) + w 6 * (1 : ℝ) = 1 / (4 : ℝ) := by
  rw [OrderCondition, phi_4, gamma_4, Fin.sum_univ_seven]
  norm_num
#print axioms oc_4

theorem phi_5 : phi dpA (node [node [], node [node []]]) =
    ![(0 : ℝ), (0 : ℝ), (27/2000 : ℝ), (32/125 : ℝ), (256/729 : ℝ), (1/2 : ℝ), (1/2 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_1]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_5

theorem gamma_5 : gamma (node [node [], node [node []]]) = 8 := by decide
#print axioms gamma_5

theorem oc_5 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [], node [node []]]) ↔
    w 2 * (27/2000 : ℝ) + w 3 * (32/125 : ℝ) + w 4 * (256/729 : ℝ) + w 5 * (1/2 : ℝ) + w 6 * (1/2 : ℝ) = 1 / (8 : ℝ) := by
  rw [OrderCondition, phi_5, gamma_5, Fin.sum_univ_seven]
  norm_num
#print axioms oc_5

theorem phi_6 : phi dpA (node [node [node []], node []]) =
    ![(0 : ℝ), (0 : ℝ), (27/2000 : ℝ), (32/125 : ℝ), (256/729 : ℝ), (1/2 : ℝ), (1/2 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_1]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_6

theorem gamma_6 : gamma (node [node [node []], node []]) = 8 := by decide
#print axioms gamma_6

theorem oc_6 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node []], node []]) ↔
    w 2 * (27/2000 : ℝ) + w 3 * (32/125 : ℝ) + w 4 * (256/729 : ℝ) + w 5 * (1/2 : ℝ) + w 6 * (1/2 : ℝ) = 1 / (8 : ℝ) := by
  rw [OrderCondition, phi_6, gamma_6, Fin.sum_univ_seven]
  norm_num
#print axioms oc_6

theorem phi_7 : phi dpA (node [node [node [], node []]]) =
    ![(0 : ℝ), (0 : ℝ), (9/1000 : ℝ), (64/375 : ℝ), (512/2187 : ℝ), (1/3 : ℝ), (1/3 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_2]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_7

theorem gamma_7 : gamma (node [node [node [], node []]]) = 12 := by decide
#print axioms gamma_7

theorem oc_7 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [], node []]]) ↔
    w 2 * (9/1000 : ℝ) + w 3 * (64/375 : ℝ) + w 4 * (512/2187 : ℝ) + w 5 * (1/3 : ℝ) + w 6 * (1/3 : ℝ) = 1 / (12 : ℝ) := by
  rw [OrderCondition, phi_7, gamma_7, Fin.sum_univ_seven]
  norm_num
#print axioms oc_7

theorem phi_8 : phi dpA (node [node [node [node []]]]) =
    ![(0 : ℝ), (0 : ℝ), (0 : ℝ), (4/25 : ℝ), (424/1215 : ℝ), (21/55 : ℝ), (1/6 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_3]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_8

theorem gamma_8 : gamma (node [node [node [node []]]]) = 24 := by decide
#print axioms gamma_8

theorem oc_8 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [node []]]]) ↔
    w 3 * (4/25 : ℝ) + w 4 * (424/1215 : ℝ) + w 5 * (21/55 : ℝ) + w 6 * (1/6 : ℝ) = 1 / (24 : ℝ) := by
  rw [OrderCondition, phi_8, gamma_8, Fin.sum_univ_seven]
  norm_num
#print axioms oc_8

theorem phi_9 : phi dpA (node [node [], node [], node [], node []]) =
    ![(0 : ℝ), (1/625 : ℝ), (81/10000 : ℝ), (256/625 : ℝ), (4096/6561 : ℝ), (1 : ℝ), (1 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_9

theorem gamma_9 : gamma (node [node [], node [], node [], node []]) = 5 := by decide
#print axioms gamma_9

theorem oc_9 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [], node [], node [], node []]) ↔
    w 1 * (1/625 : ℝ) + w 2 * (81/10000 : ℝ) + w 3 * (256/625 : ℝ) + w 4 * (4096/6561 : ℝ) + w 5 * (1 : ℝ) + w 6 * (1 : ℝ) = 1 / (5 : ℝ) := by
  rw [OrderCondition, phi_9, gamma_9, Fin.sum_univ_seven]
  norm_num
#print axioms oc_9

theorem phi_10 : phi dpA (node [node [], node [], node [node []]]) =
    ![(0 : ℝ), (0 : ℝ), (81/20000 : ℝ), (128/625 : ℝ), (2048/6561 : ℝ), (1/2 : ℝ), (1/2 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_1]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_10

theorem gamma_10 : gamma (node [node [], node [], node [node []]]) = 10 := by decide
#print axioms gamma_10

theorem oc_10 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [], node [], node [node []]]) ↔
    w 2 * (81/20000 : ℝ) + w 3 * (128/625 : ℝ) + w 4 * (2048/6561 : ℝ) + w 5 * (1/2 : ℝ) + w 6 * (1/2 : ℝ) = 1 / (10 : ℝ) := by
  rw [OrderCondition, phi_10, gamma_10, Fin.sum_univ_seven]
  norm_num
#print axioms oc_10

theorem phi_11 : phi dpA (node [node [], node [node []], node []]) =
    ![(0 : ℝ), (0 : ℝ), (81/20000 : ℝ), (128/625 : ℝ), (2048/6561 : ℝ), (1/2 : ℝ), (1/2 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_1]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_11

theorem gamma_11 : gamma (node [node [], node [node []], node []]) = 10 := by decide
#print axioms gamma_11

theorem oc_11 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [], node [node []], node []]) ↔
    w 2 * (81/20000 : ℝ) + w 3 * (128/625 : ℝ) + w 4 * (2048/6561 : ℝ) + w 5 * (1/2 : ℝ) + w 6 * (1/2 : ℝ) = 1 / (10 : ℝ) := by
  rw [OrderCondition, phi_11, gamma_11, Fin.sum_univ_seven]
  norm_num
#print axioms oc_11

theorem phi_12 : phi dpA (node [node [], node [node [], node []]]) =
    ![(0 : ℝ), (0 : ℝ), (27/10000 : ℝ), (256/1875 : ℝ), (4096/19683 : ℝ), (1/3 : ℝ), (1/3 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_2]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_12

theorem gamma_12 : gamma (node [node [], node [node [], node []]]) = 15 := by decide
#print axioms gamma_12

theorem oc_12 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [], node [node [], node []]]) ↔
    w 2 * (27/10000 : ℝ) + w 3 * (256/1875 : ℝ) + w 4 * (4096/19683 : ℝ) + w 5 * (1/3 : ℝ) + w 6 * (1/3 : ℝ) = 1 / (15 : ℝ) := by
  rw [OrderCondition, phi_12, gamma_12, Fin.sum_univ_seven]
  norm_num
#print axioms oc_12

theorem phi_13 : phi dpA (node [node [], node [node [node []]]]) =
    ![(0 : ℝ), (0 : ℝ), (0 : ℝ), (16/125 : ℝ), (3392/10935 : ℝ), (21/55 : ℝ), (1/6 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_3]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_13

theorem gamma_13 : gamma (node [node [], node [node [node []]]]) = 30 := by decide
#print axioms gamma_13

theorem oc_13 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [], node [node [node []]]]) ↔
    w 3 * (16/125 : ℝ) + w 4 * (3392/10935 : ℝ) + w 5 * (21/55 : ℝ) + w 6 * (1/6 : ℝ) = 1 / (30 : ℝ) := by
  rw [OrderCondition, phi_13, gamma_13, Fin.sum_univ_seven]
  norm_num
#print axioms oc_13

theorem phi_14 : phi dpA (node [node [node []], node [], node []]) =
    ![(0 : ℝ), (0 : ℝ), (81/20000 : ℝ), (128/625 : ℝ), (2048/6561 : ℝ), (1/2 : ℝ), (1/2 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_1]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_14

theorem gamma_14 : gamma (node [node [node []], node [], node []]) = 10 := by decide
#print axioms gamma_14

theorem oc_14 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node []], node [], node []]) ↔
    w 2 * (81/20000 : ℝ) + w 3 * (128/625 : ℝ) + w 4 * (2048/6561 : ℝ) + w 5 * (1/2 : ℝ) + w 6 * (1/2 : ℝ) = 1 / (10 : ℝ) := by
  rw [OrderCondition, phi_14, gamma_14, Fin.sum_univ_seven]
  norm_num
#print axioms oc_14

theorem phi_15 : phi dpA (node [node [node []], node [node []]]) =
    ![(0 : ℝ), (0 : ℝ), (81/40000 : ℝ), (64/625 : ℝ), (1024/6561 : ℝ), (1/4 : ℝ), (1/4 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_1]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_15

theorem gamma_15 : gamma (node [node [node []], node [node []]]) = 20 := by decide
#print axioms gamma_15

theorem oc_15 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node []], node [node []]]) ↔
    w 2 * (81/40000 : ℝ) + w 3 * (64/625 : ℝ) + w 4 * (1024/6561 : ℝ) + w 5 * (1/4 : ℝ) + w 6 * (1/4 : ℝ) = 1 / (20 : ℝ) := by
  rw [OrderCondition, phi_15, gamma_15, Fin.sum_univ_seven]
  norm_num
#print axioms oc_15

theorem phi_16 : phi dpA (node [node [node [], node []], node []]) =
    ![(0 : ℝ), (0 : ℝ), (27/10000 : ℝ), (256/1875 : ℝ), (4096/19683 : ℝ), (1/3 : ℝ), (1/3 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_2]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_16

theorem gamma_16 : gamma (node [node [node [], node []], node []]) = 15 := by decide
#print axioms gamma_16

theorem oc_16 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [], node []], node []]) ↔
    w 2 * (27/10000 : ℝ) + w 3 * (256/1875 : ℝ) + w 4 * (4096/19683 : ℝ) + w 5 * (1/3 : ℝ) + w 6 * (1/3 : ℝ) = 1 / (15 : ℝ) := by
  rw [OrderCondition, phi_16, gamma_16, Fin.sum_univ_seven]
  norm_num
#print axioms oc_16

theorem phi_17 : phi dpA (node [node [node [node []]], node []]) =
    ![(0 : ℝ), (0 : ℝ), (0 : ℝ), (16/125 : ℝ), (3392/10935 : ℝ), (21/55 : ℝ), (1/6 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_0, phi_3]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_17

theorem gamma_17 : gamma (node [node [node [node []]], node []]) = 30 := by decide
#print axioms gamma_17

theorem oc_17 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [node []]], node []]) ↔
    w 3 * (16/125 : ℝ) + w 4 * (3392/10935 : ℝ) + w 5 * (21/55 : ℝ) + w 6 * (1/6 : ℝ) = 1 / (30 : ℝ) := by
  rw [OrderCondition, phi_17, gamma_17, Fin.sum_univ_seven]
  norm_num
#print axioms oc_17

theorem phi_18 : phi dpA (node [node [node [], node [], node []]]) =
    ![(0 : ℝ), (0 : ℝ), (9/5000 : ℝ), (124/1875 : ℝ), (1288/54675 : ℝ), (173/1650 : ℝ), (1/4 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_4]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_18

theorem gamma_18 : gamma (node [node [node [], node [], node []]]) = 20 := by decide
#print axioms gamma_18

theorem oc_18 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [], node [], node []]]) ↔
    w 2 * (9/5000 : ℝ) + w 3 * (124/1875 : ℝ) + w 4 * (1288/54675 : ℝ) + w 5 * (173/1650 : ℝ) + w 6 * (1/4 : ℝ) = 1 / (20 : ℝ) := by
  rw [OrderCondition, phi_18, gamma_18, Fin.sum_univ_seven]
  norm_num
#print axioms oc_18

theorem phi_19 : phi dpA (node [node [node [], node [node []]]]) =
    ![(0 : ℝ), (0 : ℝ), (0 : ℝ), (6/125 : ℝ), (212/3645 : ℝ), (21/220 : ℝ), (1/8 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_5]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_19

theorem gamma_19 : gamma (node [node [node [], node [node []]]]) = 40 := by decide
#print axioms gamma_19

theorem oc_19 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [], node [node []]]]) ↔
    w 3 * (6/125 : ℝ) + w 4 * (212/3645 : ℝ) + w 5 * (21/220 : ℝ) + w 6 * (1/8 : ℝ) = 1 / (40 : ℝ) := by
  rw [OrderCondition, phi_19, gamma_19, Fin.sum_univ_seven]
  norm_num
#print axioms oc_19

theorem phi_20 : phi dpA (node [node [node [node []], node []]]) =
    ![(0 : ℝ), (0 : ℝ), (0 : ℝ), (6/125 : ℝ), (212/3645 : ℝ), (21/220 : ℝ), (1/8 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_6]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_20

theorem gamma_20 : gamma (node [node [node [node []], node []]]) = 40 := by decide
#print axioms gamma_20

theorem oc_20 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [node []], node []]]) ↔
    w 3 * (6/125 : ℝ) + w 4 * (212/3645 : ℝ) + w 5 * (21/220 : ℝ) + w 6 * (1/8 : ℝ) = 1 / (40 : ℝ) := by
  rw [OrderCondition, phi_20, gamma_20, Fin.sum_univ_seven]
  norm_num
#print axioms oc_20

theorem phi_21 : phi dpA (node [node [node [node [], node []]]]) =
    ![(0 : ℝ), (0 : ℝ), (0 : ℝ), (4/125 : ℝ), (424/10935 : ℝ), (7/110 : ℝ), (1/12 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_7]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_21

theorem gamma_21 : gamma (node [node [node [node [], node []]]]) = 60 := by decide
#print axioms gamma_21

theorem oc_21 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [node [], node []]]]) ↔
    w 3 * (4/125 : ℝ) + w 4 * (424/10935 : ℝ) + w 5 * (7/110 : ℝ) + w 6 * (1/12 : ℝ) = 1 / (60 : ℝ) := by
  rw [OrderCondition, phi_21, gamma_21, Fin.sum_univ_seven]
  norm_num
#print axioms oc_21

theorem phi_22 : phi dpA (node [node [node [node [node []]]]]) =
    ![(0 : ℝ), (0 : ℝ), (0 : ℝ), (0 : ℝ), ((-848)/18225 : ℝ), ((-14)/275 : ℝ), (1/24 : ℝ)] := by
  rw [phi_node]
  simp only [List.map_cons, List.map_nil, List.prod_cons, List.prod_nil, phi_8]
  funext i
  fin_cases i <;> simp [Fin.sum_univ_seven, dpA] <;> norm_num
#print axioms phi_22

theorem gamma_22 : gamma (node [node [node [node [node []]]]]) = 120 := by decide
#print axioms gamma_22

theorem oc_22 (w : Fin 7 → ℝ) : OrderCondition dpA w (node [node [node [node [node []]]]]) ↔
    w 4 * ((-848)/18225 : ℝ) + w 5 * ((-14)/275 : ℝ) + w 6 * (1/24 : ℝ) = 1 / (120 : ℝ) := by
  rw [OrderCondition, phi_22, gamma_22, Fin.sum_univ_seven]
  norm_num
#print axioms oc_22

end DPProof

/-- The card's main claim, order 5 (Step 2): fix the seven Dormand-Prince stages and leave all
seven weights free. Then the weights pass the order condition of every rooted tree with at most
5 nodes exactly when they are the published fifth-order weights
`b = (35/384, 0, 500/1113, 125/192, -2187/6784, 11/84, 0)`: order 5 allows one set. -/
theorem dormand_prince_order_five_has_one_set_of_weights (w : Fin 7 → ℝ) :
    HasOrder dpA w 5 ↔ w = dpB := by
  constructor
  · intro H
    have h0 := (DPProof.oc_0 w).1 (H _ (by decide))
    have h1 := (DPProof.oc_1 w).1 (H _ (by decide))
    have h2 := (DPProof.oc_2 w).1 (H _ (by decide))
    have h3 := (DPProof.oc_3 w).1 (H _ (by decide))
    have h4 := (DPProof.oc_4 w).1 (H _ (by decide))
    have h5 := (DPProof.oc_5 w).1 (H _ (by decide))
    have h7 := (DPProof.oc_7 w).1 (H _ (by decide))
    have h8 := (DPProof.oc_8 w).1 (H _ (by decide))
    have h9 := (DPProof.oc_9 w).1 (H _ (by decide))
    have h10 := (DPProof.oc_10 w).1 (H _ (by decide))
    have h12 := (DPProof.oc_12 w).1 (H _ (by decide))
    have h13 := (DPProof.oc_13 w).1 (H _ (by decide))
    have h15 := (DPProof.oc_15 w).1 (H _ (by decide))
    have h18 := (DPProof.oc_18 w).1 (H _ (by decide))
    have h19 := (DPProof.oc_19 w).1 (H _ (by decide))
    have h21 := (DPProof.oc_21 w).1 (H _ (by decide))
    have h22 := (DPProof.oc_22 w).1 (H _ (by decide))
    have e0 : w 0 = (35/384 : ℝ) := by linear_combination (1 : ℝ) * h0 + ((-161)/24 : ℝ) * h1 + (357/32 : ℝ) * h2 + (31/4 : ℝ) * h3 + ((-1345)/96 : ℝ) * h4 + (75/16 : ℝ) * h9
    have e1 : w 1 = (0 : ℝ) := by linear_combination (25 : ℝ) * h2 + ((-50) : ℝ) * h3
    have e2 : w 2 = (500/1113 : ℝ) := by linear_combination (12800/1113 : ℝ) * h1 + ((-24320)/371 : ℝ) * h2 + (19840/371 : ℝ) * h3 + (48400/1113 : ℝ) * h4 + ((-6000)/371 : ℝ) * h9
    have e3 : w 3 = (125/192 : ℝ) := by linear_combination ((-75)/2 : ℝ) * h1 + (3895/16 : ℝ) * h2 + ((-155)/2 : ℝ) * h3 + ((-4925)/16 : ℝ) * h4 + (1125/8 : ℝ) * h9
    have e4 : w 4 = ((-2187)/6784 : ℝ) := by linear_combination (19683/424 : ℝ) * h1 + ((-518319)/1696 : ℝ) * h2 + (19683/212 : ℝ) * h3 + (688905/1696 : ℝ) * h4 + ((-164025)/848 : ℝ) * h9
    have e5 : w 5 = (11/84 : ℝ) := by linear_combination ((-18282)/497 : ℝ) * h1 + (121132/497 : ℝ) * h2 + ((-35970)/497 : ℝ) * h3 + ((-164450)/497 : ℝ) * h4 + (330/71 : ℝ) * h8 + (79200/497 : ℝ) * h9
    have e6 : w 6 = (0 : ℝ) := by linear_combination (1638/71 : ℝ) * h1 + ((-10803)/71 : ℝ) * h2 + (3252/71 : ℝ) * h3 + (14415/71 : ℝ) * h4 + ((-330)/71 : ℝ) * h8 + ((-6750)/71 : ℝ) * h9
    funext i
    fin_cases i <;> simp [dpB, e0, e1, e2, e3, e4, e5, e6]
  · rintro rfl
    apply DPProof.forall_le_five
    rw [DPProof.all_le_five_eq]
    simp only [List.forall_mem_cons, List.not_mem_nil, IsEmpty.forall_iff, implies_true, and_true]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [DPProof.oc_0]; norm_num [dpB]
    · rw [DPProof.oc_1]; norm_num [dpB]
    · rw [DPProof.oc_2]; norm_num [dpB]
    · rw [DPProof.oc_3]; norm_num [dpB]
    · rw [DPProof.oc_4]; norm_num [dpB]
    · rw [DPProof.oc_5]; norm_num [dpB]
    · rw [DPProof.oc_6]; norm_num [dpB]
    · rw [DPProof.oc_7]; norm_num [dpB]
    · rw [DPProof.oc_8]; norm_num [dpB]
    · rw [DPProof.oc_9]; norm_num [dpB]
    · rw [DPProof.oc_10]; norm_num [dpB]
    · rw [DPProof.oc_11]; norm_num [dpB]
    · rw [DPProof.oc_12]; norm_num [dpB]
    · rw [DPProof.oc_13]; norm_num [dpB]
    · rw [DPProof.oc_14]; norm_num [dpB]
    · rw [DPProof.oc_15]; norm_num [dpB]
    · rw [DPProof.oc_16]; norm_num [dpB]
    · rw [DPProof.oc_17]; norm_num [dpB]
    · rw [DPProof.oc_18]; norm_num [dpB]
    · rw [DPProof.oc_19]; norm_num [dpB]
    · rw [DPProof.oc_20]; norm_num [dpB]
    · rw [DPProof.oc_21]; norm_num [dpB]
    · rw [DPProof.oc_22]; norm_num [dpB]

/-- The card's main claim, order 4 (Step 3): on the same seven stages, the weights pass the
order condition of every rooted tree with at most 4 nodes exactly when they lie on the line
through the fifth-order weights `b` and the fourth-order weights `b̂`: order 4 allows a
one-parameter family. -/
theorem dormand_prince_order_four_weights_form_a_line (w : Fin 7 → ℝ) :
    HasOrder dpA w 4 ↔ ∃ x : ℝ, w = dpB + x • (dpBhat - dpB) := by
  constructor
  · intro H
    have h0 := (DPProof.oc_0 w).1 (H _ (by decide))
    have h1 := (DPProof.oc_1 w).1 (H _ (by decide))
    have h2 := (DPProof.oc_2 w).1 (H _ (by decide))
    have h3 := (DPProof.oc_3 w).1 (H _ (by decide))
    have h4 := (DPProof.oc_4 w).1 (H _ (by decide))
    have h5 := (DPProof.oc_5 w).1 (H _ (by decide))
    have h7 := (DPProof.oc_7 w).1 (H _ (by decide))
    have h8 := (DPProof.oc_8 w).1 (H _ (by decide))
    have e0 : w 0 = (35/384 : ℝ) + 40 * w 6 * ((5179/57600 : ℝ) - (35/384 : ℝ)) := by
      linear_combination (1 : ℝ) * h0 + ((-1337)/240 : ℝ) * h1 + (877/240 : ℝ) * h2 + (1201/120 : ℝ) * h3 + ((-4) : ℝ) * h4 + ((-11)/48 : ℝ) * h8
    have e1 : w 1 = (0 : ℝ) + 40 * w 6 * ((0 : ℝ) - (0 : ℝ)) := by
      linear_combination (25 : ℝ) * h2 + ((-50) : ℝ) * h3
    have e2 : w 2 = (500/1113 : ℝ) + 40 * w 6 * ((7571/16695 : ℝ) - (500/1113 : ℝ)) := by
      linear_combination (8432/1113 : ℝ) * h1 + ((-44152)/1113 : ℝ) * h2 + (7264/159 : ℝ) * h3 + (3320/371 : ℝ) * h4 + (880/1113 : ℝ) * h8
    have e3 : w 3 = (125/192 : ℝ) + 40 * w 6 * ((393/640 : ℝ) - (125/192 : ℝ)) := by
      linear_combination ((-27)/8 : ℝ) * h1 + (147/8 : ℝ) * h2 + ((-39)/4 : ℝ) * h3 + ((-15)/2 : ℝ) * h4 + ((-55)/8 : ℝ) * h8
    have e4 : w 4 = ((-2187)/6784 : ℝ) + 40 * w 6 * (((-92097)/339200 : ℝ) - ((-2187)/6784 : ℝ)) := by
      linear_combination ((-2187)/4240 : ℝ) * h1 + (16767/4240 : ℝ) * h2 + ((-729)/2120 : ℝ) * h3 + ((-729)/106 : ℝ) * h4 + (8019/848 : ℝ) * h8
    have e5 : w 5 = (11/84 : ℝ) + 40 * w 6 * ((187/2100 : ℝ) - (11/84 : ℝ)) := by
      linear_combination (66/35 : ℝ) * h1 + ((-396)/35 : ℝ) * h2 + (22/5 : ℝ) * h3 + (66/7 : ℝ) * h4 + ((-22)/7 : ℝ) * h8
    refine ⟨40 * w 6, ?_⟩
    funext i
    fin_cases i <;> simp [dpB, dpBhat, e0, e1, e2, e3, e4, e5]
    ring
  · rintro ⟨x, rfl⟩
    apply DPProof.forall_le_four
    rw [DPProof.all_le_four_eq]
    simp only [List.forall_mem_cons, List.not_mem_nil, IsEmpty.forall_iff, implies_true, and_true]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [DPProof.oc_0]; simp [dpB, dpBhat]; ring
    · rw [DPProof.oc_1]; simp [dpB, dpBhat]; ring
    · rw [DPProof.oc_2]; simp [dpB, dpBhat]; ring
    · rw [DPProof.oc_3]; simp [dpB, dpBhat]; ring
    · rw [DPProof.oc_4]; simp [dpB, dpBhat]; ring
    · rw [DPProof.oc_5]; simp [dpB, dpBhat]; ring
    · rw [DPProof.oc_6]; simp [dpB, dpBhat]; ring
    · rw [DPProof.oc_7]; simp [dpB, dpBhat]; ring
    · rw [DPProof.oc_8]; simp [dpB, dpBhat]; ring

/-- Step 3: the fourth-order weights `b̂` miss the order condition of every tree with 5 nodes;
on the bushy tree they miss by `-71/270000`, on the tall tree by `97/120000`. -/
theorem fourth_order_weights_miss_every_five_node_tree :
    (∀ t : RTree, t.nodes = 5 → ¬ OrderCondition dpA dpBhat t) ∧
    ∑ i, dpBhat i * phi dpA bushy i - 1 / (gamma bushy : ℝ) = -71 / 270000 ∧
    ∑ i, dpBhat i * phi dpA tall i - 1 / (gamma tall : ℝ) = 97 / 120000 := by
  refine ⟨?_, ?_, ?_⟩
  · apply DPProof.forall_eq_five
    rw [DPProof.all_five_eq]
    simp only [List.forall_mem_cons, List.not_mem_nil, IsEmpty.forall_iff, implies_true, and_true]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [DPProof.oc_9]; norm_num [dpBhat]
    · rw [DPProof.oc_10]; norm_num [dpBhat]
    · rw [DPProof.oc_11]; norm_num [dpBhat]
    · rw [DPProof.oc_12]; norm_num [dpBhat]
    · rw [DPProof.oc_13]; norm_num [dpBhat]
    · rw [DPProof.oc_14]; norm_num [dpBhat]
    · rw [DPProof.oc_15]; norm_num [dpBhat]
    · rw [DPProof.oc_16]; norm_num [dpBhat]
    · rw [DPProof.oc_17]; norm_num [dpBhat]
    · rw [DPProof.oc_18]; norm_num [dpBhat]
    · rw [DPProof.oc_19]; norm_num [dpBhat]
    · rw [DPProof.oc_20]; norm_num [dpBhat]
    · rw [DPProof.oc_21]; norm_num [dpBhat]
    · rw [DPProof.oc_22]; norm_num [dpBhat]
  · rw [show bushy = node [node [], node [], node [], node []] from rfl, DPProof.phi_9, DPProof.gamma_9, Fin.sum_univ_seven]
    norm_num [dpBhat]
  · rw [show tall = node [node [node [node [node []]]]] from rfl, DPProof.phi_22, DPProof.gamma_22, Fin.sum_univ_seven]
    norm_num [dpBhat]

/-! Worked examples from the card, in exact fractions. -/

-- The bushy and tall trees have 5 nodes; their densities are 5 and 120.
example : bushy.nodes = 5 ∧ tall.nodes = 5 ∧ gamma bushy = 5 ∧ gamma tall = 120 := by decide

-- The stage times, the row sums of the table: c = 0, 1/5, 3/10, 4/5, 8/9, 1, 1.
example : (fun i => ∑ j, dpA i j) = ![0, 1/5, 3/10, 4/5, 8/9, 1, 1] := by
  funext i
  fin_cases i <;> simp [dpA, Fin.sum_univ_seven] <;> norm_num

-- Row 7 of the stage table equals b, so stage 7 samples the rate at the kept answer.
example : dpA 6 = dpB := by
  funext j
  fin_cases j <;> simp [dpA, dpB]

-- The bushy tree's condition for b: the weights integrate t^4 exactly, ∑ b_i c_i^4 = 1/5.
example : (35/384 : ℚ) * 0 ^ 4 + 0 * (1/5) ^ 4 + 500/1113 * (3/10) ^ 4 + 125/192 * (4/5) ^ 4
    + (-2187/6784) * (8/9) ^ 4 + 11/84 * 1 ^ 4 + 0 * 1 ^ 4 = 1/5 := by norm_num

-- The bushy tree's condition for b̂ misses by -71/270000.
example : (5179/57600 : ℚ) * 0 ^ 4 + 0 * (1/5) ^ 4 + 7571/16695 * (3/10) ^ 4
    + 393/640 * (4/5) ^ 4 + (-92097/339200) * (8/9) ^ 4 + 187/2100 * 1 ^ 4 + 1/40 * 1 ^ 4
    - 1/5 = -71/270000 := by norm_num

-- Choosing b̂_7 = 0 on the order-4 line gives back b, so every error estimate is 0.
example : dpB + (0 : ℝ) • (dpBhat - dpB) = dpB := by simp

-- Both answers weight the first sample almost equally: 35/384 against 5179/57600,
-- a difference of 71/57600.
example : (35/384 : ℚ) - 5179/57600 = 71/57600 := by norm_num

#print axioms dormand_prince_order_five_has_one_set_of_weights
#print axioms dormand_prince_order_four_weights_form_a_line
#print axioms fourth_order_weights_miss_every_five_node_tree
