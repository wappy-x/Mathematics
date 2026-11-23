-- Karp's list: a three-literal formula can be made true exactly when its gadget graph of 2n + 3m vertices and n + 6m edges has a vertex cover of at most n + 2m vertices, that cover is a set cover of the edges, and a graph has a Hamiltonian cycle exactly when the 1-and-2 distance tour problem meets the budget N.
import Mathlib.Combinatorics.SimpleGraph.VertexCover
import Mathlib.Combinatorics.SimpleGraph.Hamiltonian
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Logic.Equiv.Fin.Rotate
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Tactic.Ring

open SimpleGraph

namespace KarpsList

/-- A literal over the variables `x_1, ..., x_n` (numbered from 0 in Lean): a variable and a sign,
`true` for `x_i` and `false` for `¬x_i`. -/
abbrev Literal (n : ℕ) := Fin n × Bool

/-- A 3-SAT formula with `n` variables and `m` clauses: each clause has exactly three literals. -/
abbrev Formula3 (n m : ℕ) := Fin m → Fin 3 → Literal n

/-- The formula can be made true: some assignment makes at least one literal true in every
clause (the literal `(i, b)` is true when `x_i` gets the value `b`). -/
def Satisfiable {n m : ℕ} (φ : Formula3 n m) : Prop :=
  ∃ a : Fin n → Bool, ∀ j : Fin m, ∃ p : Fin 3, a (φ j p).1 = (φ j p).2

/-- The vertices of the gadget graph: one per literal (`x_i` and `¬x_i`), and one triangle
corner per clause position. -/
abbrev GadgetVertex (n m : ℕ) := Literal n ⊕ (Fin m × Fin 3)

/-- The gadget's joins, one direction of each: the variable edge `x_i — ¬x_i`, the three sides
of each clause triangle, and the link from each corner to the vertex of its literal. -/
def gadgetLink {n m : ℕ} (φ : Formula3 n m) : GadgetVertex n m → GadgetVertex n m → Bool
  | .inl l, .inl l' => decide (l.1 = l'.1 ∧ l.2 ≠ l'.2)
  | .inr c, .inr c' => decide (c.1 = c'.1 ∧ c.2 ≠ c'.2)
  | .inr c, .inl l => decide (φ c.1 c.2 = l)
  | .inl _, .inr _ => false

/-- The graph `G_φ` built from the formula `φ` (Step 1 of the card). -/
def gadget {n m : ℕ} (φ : Formula3 n m) : SimpleGraph (GadgetVertex n m) :=
  SimpleGraph.fromRel fun u v => gadgetLink φ u v = true

instance {n m : ℕ} (φ : Formula3 n m) : DecidableRel (gadget φ).Adj := fun u v => by
  unfold gadget; simp only [fromRel_adj]; infer_instance

theorem gadget_adj_inl_inl {n m : ℕ} (φ : Formula3 n m) (l l' : Literal n) :
    (gadget φ).Adj (.inl l) (.inl l') ↔ l.1 = l'.1 ∧ l.2 ≠ l'.2 := by
  obtain ⟨i, b⟩ := l
  obtain ⟨i', b'⟩ := l'
  simp only [gadget, gadgetLink, fromRel_adj, ne_eq, Sum.inl.injEq, Prod.mk.injEq,
    decide_eq_true_eq]
  constructor
  · rintro ⟨-, h | h⟩
    · exact h
    · exact ⟨h.1.symm, fun e => h.2 e.symm⟩
  · rintro ⟨h1, h2⟩
    exact ⟨fun e => h2 e.2, Or.inl ⟨h1, h2⟩⟩

theorem gadget_adj_inr_inr {n m : ℕ} (φ : Formula3 n m) (c c' : Fin m × Fin 3) :
    (gadget φ).Adj (.inr c) (.inr c') ↔ c.1 = c'.1 ∧ c.2 ≠ c'.2 := by
  obtain ⟨i, b⟩ := c
  obtain ⟨i', b'⟩ := c'
  simp only [gadget, gadgetLink, fromRel_adj, ne_eq, Sum.inr.injEq, Prod.mk.injEq,
    decide_eq_true_eq]
  constructor
  · rintro ⟨-, h | h⟩
    · exact h
    · exact ⟨h.1.symm, fun e => h.2 e.symm⟩
  · rintro ⟨h1, h2⟩
    exact ⟨fun e => h2 e.2, Or.inl ⟨h1, h2⟩⟩

theorem gadget_adj_inr_inl {n m : ℕ} (φ : Formula3 n m) (c : Fin m × Fin 3) (l : Literal n) :
    (gadget φ).Adj (.inr c) (.inl l) ↔ φ c.1 c.2 = l := by
  simp [gadget, gadgetLink, fromRel_adj]

theorem gadget_adj_inl_inr {n m : ℕ} (φ : Formula3 n m) (l : Literal n) (c : Fin m × Fin 3) :
    (gadget φ).Adj (.inl l) (.inr c) ↔ φ c.1 c.2 = l := by
  rw [adj_comm, gadget_adj_inr_inl]

theorem gadget_card_split {n m : ℕ} (C : Finset (GadgetVertex n m)) :
    C.card = ∑ i : Fin n, ((if Sum.inl (i, true) ∈ C then 1 else 0) +
        (if Sum.inl (i, false) ∈ C then 1 else 0)) +
      ∑ j : Fin m, ((if Sum.inr (j, 0) ∈ C then 1 else 0) +
        (if Sum.inr (j, 1) ∈ C then 1 else 0) + (if Sum.inr (j, 2) ∈ C then 1 else 0)) := by
  calc C.card = (Finset.univ.filter (· ∈ C)).card := by congr 1; ext; simp
    _ = ∑ v, if v ∈ C then 1 else 0 := Finset.card_filter _ _
    _ = _ := by
      rw [Fintype.sum_sum_type, Fintype.sum_prod_type, Fintype.sum_prod_type]
      simp only [Fintype.sum_bool, Fin.sum_univ_three]

theorem gadget_edge_count {n m : ℕ} (φ : Formula3 n m) :
    (gadget φ).edgeFinset.card = n + 6 * m := by
  have h := (gadget φ).sum_degrees_eq_twice_card_edges
  have hdeg : ∀ v, (gadget φ).degree v = ∑ w, if (gadget φ).Adj v w then 1 else 0 := by
    intro v
    rw [← card_neighborFinset_eq_degree, neighborFinset_eq_filter, Finset.card_filter]
  simp only [hdeg, Fintype.sum_sum_type, gadget_adj_inl_inl, gadget_adj_inr_inr,
    gadget_adj_inr_inl, gadget_adj_inl_inr] at h
  have hLL : ∑ l : Literal n, ∑ l' : Literal n,
      (if l.1 = l'.1 ∧ l.2 ≠ l'.2 then 1 else 0) = 2 * n := by
    simp only [Fintype.sum_prod_type, Fintype.sum_bool]
    simp
    ring
  have hRR : ∑ c : Fin m × Fin 3, ∑ c' : Fin m × Fin 3,
      (if c.1 = c'.1 ∧ c.2 ≠ c'.2 then 1 else 0) = 6 * m := by
    simp only [Fintype.sum_prod_type, Fin.sum_univ_three]
    simp only [Fin.isValue, ne_eq, Fin.reduceEq, not_false_eq_true, and_true, not_true_eq_false,
      and_false, ite_false, add_zero, zero_add, Finset.sum_add_distrib, Finset.sum_ite_eq,
      Finset.mem_univ, ite_true]
    simp
    ring
  have hLR : ∑ l : Literal n, ∑ c : Fin m × Fin 3,
      (if φ c.1 c.2 = l then 1 else 0) = 3 * m := by
    rw [Finset.sum_comm]
    simp
    ring
  have hRL : ∑ c : Fin m × Fin 3, ∑ l : Literal n,
      (if φ c.1 c.2 = l then 1 else 0) = 3 * m := by
    simp
    ring
  rw [Finset.sum_add_distrib, Finset.sum_add_distrib, hLL, hRR, hLR, hRL] at h
  omega

#print axioms gadget_adj_inl_inl
#print axioms gadget_adj_inr_inr
#print axioms gadget_adj_inr_inl
#print axioms gadget_adj_inl_inr
#print axioms gadget_card_split
#print axioms gadget_edge_count

/-- 3-SAT to vertex cover. For every three-literal formula `φ` with `n` variables and `m`
clauses, the gadget graph `G_φ` has `2n + 3m` vertices and `n + 6m` edges, and `φ` can be made
true exactly when `G_φ` has a vertex cover of at most `k = n + 2m` vertices. -/
theorem three_sat_iff_gadget_vertex_cover {n m : ℕ} (φ : Formula3 n m) :
    Fintype.card (GadgetVertex n m) = 2 * n + 3 * m ∧
      (gadget φ).edgeFinset.card = n + 6 * m ∧
      (Satisfiable φ ↔
        ∃ C : Finset (GadgetVertex n m), C.card ≤ n + 2 * m ∧ (gadget φ).IsVertexCover ↑C) := by
  refine ⟨?_, gadget_edge_count φ, ?_⟩
  · simp [Fintype.card_sum, Fintype.card_prod]
    ring
  constructor
  · rintro ⟨a, ha⟩
    choose s hs using ha
    let C : Finset (GadgetVertex n m) := Finset.univ.filter fun v =>
      Sum.elim (fun l => decide (a l.1 = l.2)) (fun c => decide (c.2 ≠ s c.1)) v = true
    have hl : ∀ l : Literal n, Sum.inl l ∈ C ↔ a l.1 = l.2 := by intro l; simp [C]
    have hr : ∀ c : Fin m × Fin 3, Sum.inr c ∈ C ↔ c.2 ≠ s c.1 := by intro c; simp [C]
    refine ⟨C, ?_, ?_⟩
    · rw [gadget_card_split]
      have h1 : ∀ i : Fin n, ((if Sum.inl (i, true) ∈ C then 1 else 0) +
          (if Sum.inl (i, false) ∈ C then 1 else 0)) = 1 := by
        intro i
        simp only [hl]
        cases a i <;> simp
      have h2 : ∀ j : Fin m, ((if Sum.inr (j, 0) ∈ C then 1 else 0) +
          (if Sum.inr (j, 1) ∈ C then 1 else 0) + (if Sum.inr (j, 2) ∈ C then 1 else 0)) = 2 := by
        intro j
        simp only [hr]
        generalize s j = q
        revert q
        decide
      simp only [h1, h2]
      simp
      omega
    · intro u v huv
      rcases u with ⟨i, b⟩ | ⟨j, p⟩ <;> rcases v with ⟨i', b'⟩ | ⟨j', p'⟩
      · rw [gadget_adj_inl_inl] at huv
        obtain ⟨rfl, hb⟩ := huv
        simp only [Finset.mem_coe, hl]
        cases b <;> cases b' <;> cases a i <;> simp_all
      · rw [gadget_adj_inl_inr] at huv
        simp only [Finset.mem_coe, hl, hr]
        by_cases hp : p' = s j'
        · left; subst hp; have := hs j'; simp only at huv; rw [huv] at this; exact this
        · right; exact hp
      · rw [gadget_adj_inr_inl] at huv
        simp only [Finset.mem_coe, hl, hr]
        by_cases hp : p = s j
        · right; subst hp; have := hs j; simp only at huv; rw [huv] at this; exact this
        · left; exact hp
      · rw [gadget_adj_inr_inr] at huv
        obtain ⟨rfl, hp⟩ := huv
        simp only [Finset.mem_coe, hr]
        by_cases h : p = s j
        · right; rw [← h]; exact fun e => hp e.symm
        · left; exact h
  · rintro ⟨C, hcard, hC⟩
    refine ⟨fun i => decide (Sum.inl (i, true) ∈ C), ?_⟩
    rw [gadget_card_split] at hcard
    set f : Fin n → ℕ := fun i => (if Sum.inl (i, true) ∈ C then 1 else 0) +
        (if Sum.inl (i, false) ∈ C then 1 else 0) with hf
    set g : Fin m → ℕ := fun j => (if Sum.inr (j, 0) ∈ C then 1 else 0) +
          (if Sum.inr (j, 1) ∈ C then 1 else 0) + (if Sum.inr (j, 2) ∈ C then 1 else 0) with hg
    have hf1 : ∀ i, 1 ≤ f i := by
      intro i
      have := hC ((gadget_adj_inl_inl φ (i, true) (i, false)).mpr ⟨rfl, by simp⟩)
      simp only [Finset.mem_coe] at this
      simp only [hf]
      rcases this with h | h <;> simp [h]
    have hg2 : ∀ j, 2 ≤ g j := by
      intro j
      have e : ∀ p q : Fin 3, p ≠ q → Sum.inr (j, p) ∈ C ∨ Sum.inr (j, q) ∈ C := by
        intro p q hpq
        exact hC ((gadget_adj_inr_inr φ (j, p) (j, q)).mpr ⟨rfl, hpq⟩)
      have e01 := e 0 1 (by decide)
      have e02 := e 0 2 (by decide)
      have e12 := e 1 2 (by decide)
      simp only [hg]
      by_cases h0 : Sum.inr (j, (0 : Fin 3)) ∈ C <;> by_cases h1 : Sum.inr (j, (1 : Fin 3)) ∈ C <;>
        by_cases h2 : Sum.inr (j, (2 : Fin 3)) ∈ C <;> simp_all
    have hsumf : n ≤ Finset.univ.sum f := by
      calc n = ∑ _i : Fin n, 1 := by simp
        _ ≤ Finset.univ.sum f := Finset.sum_le_sum fun i _ => hf1 i
    have hsumg : 2 * m ≤ Finset.univ.sum g := by
      calc 2 * m = ∑ _j : Fin m, 2 := by simp [mul_comm]
        _ ≤ Finset.univ.sum g := Finset.sum_le_sum fun j _ => hg2 j
    intro j
    by_contra hj
    push Not at hj
    have key : (∃ i, 2 ≤ f i) ∨ 3 ≤ g j := by
      by_cases hall : ∀ p : Fin 3, Sum.inr (j, p) ∈ C
      · right
        simp [hg, hall]
      · push Not at hall
        obtain ⟨p, hp⟩ := hall
        have hlink := hC ((gadget_adj_inr_inl φ (j, p) (φ j p)).mpr rfl)
        simp only [Finset.mem_coe] at hlink
        have hin : Sum.inl (φ j p) ∈ C := hlink.resolve_left hp
        have hne := hj p
        generalize φ j p = q at hin hne
        obtain ⟨i, b⟩ := q
        cases b
        · left
          refine ⟨i, ?_⟩
          simp only [ne_eq, Bool.not_eq_false, decide_eq_true_eq] at hne
          simp [hf, hne, hin]
        · exfalso
          apply hne
          simpa using hin
    rcases key with ⟨i, hi⟩ | hj3
    · have : n < Finset.univ.sum f := by
        calc n = ∑ _i : Fin n, 1 := by simp
          _ < Finset.univ.sum f := Finset.sum_lt_sum (fun i _ => hf1 i) ⟨i, Finset.mem_univ _, Nat.lt_of_lt_of_le (by norm_num) hi⟩
      omega
    · have : 2 * m < Finset.univ.sum g := by
        calc 2 * m = ∑ _j : Fin m, 2 := by simp [mul_comm]
          _ < Finset.univ.sum g := Finset.sum_lt_sum (fun j _ => hg2 j) ⟨j, Finset.mem_univ _, Nat.lt_of_lt_of_le (by norm_num) hj3⟩
      omega

/-- Vertex cover to set cover, by restriction. Take the edges of a graph as the items and, for
each vertex, the set of edges touching it. Then `k` vertices touch every edge exactly when the
`k` matching sets together hold every item. -/
theorem vertex_cover_iff_edge_set_cover {V : Type*} (G : SimpleGraph V) (k : ℕ) :
    (∃ C : Finset V, C.card ≤ k ∧ G.IsVertexCover ↑C) ↔
      ∃ C : Finset V, C.card ≤ k ∧ ⋃ v ∈ C, G.incidenceSet v = G.edgeSet := by
  refine exists_congr fun C => and_congr_right fun _ => ?_
  constructor
  · intro hC
    apply Set.Subset.antisymm
    · exact Set.iUnion₂_subset fun v _ => G.incidenceSet_subset v
    · intro e he
      induction e using Sym2.ind with
      | _ v w =>
        rw [mem_edgeSet] at he
        rcases hC he with h | h
        · exact Set.mem_iUnion₂.mpr ⟨v, h, he, Sym2.mem_mk_left v w⟩
        · exact Set.mem_iUnion₂.mpr ⟨w, h, he, Sym2.mem_mk_right v w⟩
  · intro hC v w hvw
    have : s(v, w) ∈ ⋃ u ∈ C, G.incidenceSet u := hC ▸ hvw
    obtain ⟨u, hu, -, hm⟩ := Set.mem_iUnion₂.mp this
    rcases Sym2.mem_iff.mp hm with rfl | rfl
    · exact Or.inl hu
    · exact Or.inr hu

/-- The travelling-salesman distance built from a graph: 1 between joined cities, 2 between
cities with no edge. -/
def tspDist {V : Type*} (G : SimpleGraph V) [DecidableRel G.Adj] (u v : V) : ℕ :=
  if G.Adj u v then 1 else 2

/-- The cost of the round trip visiting the cities `t 0, t 1, ..., t (N - 1)` in turn and
returning to `t 0`. -/
def tourCost {V : Type*} {N : ℕ} (G : SimpleGraph V) [DecidableRel G.Adj] (t : Fin N ≃ V) : ℕ :=
  ∑ i : Fin N, tspDist G (t i) (t (finRotate N i))

/-- Helper: a tour costs at most `N` exactly when each step runs along an edge. -/
theorem tourCost_le_iff {V : Type*} {N : ℕ} (G : SimpleGraph V) [DecidableRel G.Adj]
    (t : Fin N ≃ V) : tourCost G t ≤ N ↔ ∀ i, G.Adj (t i) (t (finRotate N i)) := by
  have hN : N = ∑ _i : Fin N, 1 := by simp
  constructor
  · intro h i
    by_contra hi
    have : ∑ _i : Fin N, 1 < tourCost G t := by
      apply Finset.sum_lt_sum
      · intro j _; unfold tspDist; split_ifs <;> omega
      · exact ⟨i, Finset.mem_univ _, by simp only [tspDist, hi, ↓reduceIte]; omega⟩
    omega
  · intro h
    have : tourCost G t = ∑ _i : Fin N, 1 := by
      apply Finset.sum_congr rfl
      intro i _
      simp only [tspDist, h i, ↓reduceIte]
    omega

/-- Helper: with `N ≥ 3` vertices, a copy of the `N`-cycle is the same as an ordering of the
vertices whose neighbours (cyclically) are joined. -/
theorem cycleGraph_isContained_iff_tour {V : Type*} [Fintype V] (G : SimpleGraph V) (N : ℕ)
    (hN : 3 ≤ N) (hc : Fintype.card V = N) :
    cycleGraph N ⊑ G ↔ ∃ t : Fin N ≃ V, ∀ i, G.Adj (t i) (t (finRotate N i)) := by
  obtain ⟨n, rfl⟩ : ∃ n, N = n + 3 := ⟨N - 3, by omega⟩
  constructor
  · rintro ⟨f⟩
    have hbij : Function.Bijective f :=
      (Fintype.bijective_iff_injective_and_card f).mpr ⟨f.injective, by simp [hc]⟩
    refine ⟨Equiv.ofBijective f hbij, fun i => ?_⟩
    simp only [Equiv.ofBijective_apply]
    apply f.toHom.map_adj
    rw [finRotate_apply]
    exact (cycleGraph_adj (n := n + 1)).mpr (Or.inr (by simp))
  · rintro ⟨t, ht⟩
    refine ⟨⟨⟨t, fun {u v} huv => ?_⟩, t.injective⟩⟩
    rcases (cycleGraph_adj (n := n + 1)).mp huv with h | h
    · have : u = finRotate (n + 3) v := by rw [finRotate_apply, ← h]; simp
      subst this; exact (ht v).symm
    · have : v = finRotate (n + 3) u := by rw [finRotate_apply, ← h]; simp
      subst this; exact ht u

#print axioms tourCost_le_iff
#print axioms cycleGraph_isContained_iff_tour

/-- Hamiltonian cycle to travelling salesman. On a graph with `N ≥ 3` vertices (the size a
cycle needs), with distance 1 along edges and 2 elsewhere, the graph has a Hamiltonian cycle
exactly when some round trip through all `N` cities costs at most the budget `N`. -/
theorem hamiltonian_cycle_iff_tour_within_budget {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (hN : 3 ≤ Fintype.card V) :
    (∃ a : V, ∃ p : G.Walk a a, p.IsHamiltonianCycle) ↔
      ∃ t : Fin (Fintype.card V) ≃ V, tourCost G t ≤ Fintype.card V := by
  have h1 : (∃ a : V, ∃ p : G.Walk a a, p.IsHamiltonianCycle) ↔ G.IsHamiltonian :=
    ⟨fun h _ => h, fun h => h (by omega)⟩
  rw [h1, isHamiltonian_iff_cycleGraph_isContained hN,
    cycleGraph_isContained_iff_tour G _ hN rfl]
  simp only [tourCost_le_iff]

/-- The card's `φ = (x_1 ∨ x_2 ∨ x_3) ∧ (¬x_1 ∨ ¬x_2 ∨ x_3) ∧ (x_1 ∨ ¬x_2 ∨ ¬x_3)`. -/
def phi : Formula3 3 3 :=
  ![![(0, true), (1, true), (2, true)],
    ![(0, false), (1, false), (2, true)],
    ![(0, true), (1, false), (2, false)]]

/-- The card's `ψ`: all 8 clauses on `x_1, x_2, x_3`, one for each pattern of signs. -/
def psi : Formula3 3 8 := fun j p => (p, (j.val / 2 ^ p.val) % 2 == 1)

-- φ: 5 of the 8 assignments satisfy it.
example : (Finset.univ.filter fun a : Fin 3 → Bool =>
    ∀ j : Fin 3, ∃ p : Fin 3, a (phi j p).1 = (phi j p).2).card = 5 := by decide

-- ψ: no assignment satisfies it.
example : ¬ ∃ a : Fin 3 → Bool, ∀ j : Fin 8, ∃ p : Fin 3, a (psi j p).1 = (psi j p).2 := by
  decide

-- G_φ: 2·3 + 3·3 = 15 vertices, 3 + 6·3 = 21 edges, budget 3 + 2·3 = 9.
example : 2 * 3 + 3 * 3 = 15 ∧ 3 + 6 * 3 = 21 ∧ 3 + 2 * 3 = 9 := by norm_num
example : (gadget phi).edgeFinset.card = 21 := by decide

-- G_ψ: 30 vertices, 51 edges, budget 19.
example : 2 * 3 + 3 * 8 = 30 ∧ 3 + 6 * 8 = 51 ∧ 3 + 2 * 8 = 19 := by norm_num
example : (gadget psi).edgeFinset.card = 51 := by decide

/-- The cover built from the assignment `x_1` true, `x_2` false, `x_3` false: the vertices
`x_1, ¬x_2, ¬x_3` and two corners of each triangle (vertices 0, 3, 5, 7, 8, 9, 11, 13, 14). -/
def phiCover : Finset (GadgetVertex 3 3) :=
  {.inl (0, true), .inl (1, false), .inl (2, false), .inr (0, 1), .inr (0, 2), .inr (1, 0),
    .inr (1, 2), .inr (2, 1), .inr (2, 2)}

-- That cover has 9 vertices and touches all 21 edges.
set_option synthInstance.maxSize 1024 in
example : phiCover.card = 9 ∧
    ∀ u v : GadgetVertex 3 3, (gadget phi).Adj u v → u ∈ phiCover ∨ v ∈ phiCover := by decide

/-- The cube: 8 corners, joined when their 3-bit labels differ in one bit. -/
def cube : SimpleGraph (Fin 8) :=
  SimpleGraph.fromRel fun u v => (u.val ^^^ v.val) = 1 ∨ (u.val ^^^ v.val) = 2 ∨
    (u.val ^^^ v.val) = 4

instance : DecidableRel cube.Adj := fun u v => by
  unfold cube; simp only [fromRel_adj]; infer_instance

-- The cube has 12 edges.
example : cube.edgeFinset.card = 12 := by decide

/-- The tour 0, 1, 3, 2, 6, 7, 5, 4 round the cube. -/
def cubeTour : Fin 8 ≃ Fin 8 where
  toFun := ![0, 1, 3, 2, 6, 7, 5, 4]
  invFun := ![0, 1, 3, 2, 7, 6, 4, 5]
  left_inv := by decide
  right_inv := by decide

-- That tour costs 8, within the budget of 8.
example : tourCost cube cubeTour = 8 := by decide

-- Sizes of the built graph: vertices 2n + 3m and edges n + 6m.
example : 2 * 10 + 3 * 43 = 149 ∧ 10 + 6 * 43 = 268 ∧ 2 * 40 + 3 * 172 = 596 ∧
    40 + 6 * 172 = 1072 ∧ 2 * 100 + 3 * 430 = 1490 ∧ 100 + 6 * 430 = 2680 := by norm_num

-- Checking a filled sudoku reads 3g groups of g cells.
example : 3 * 9 * 9 = 243 ∧ 3 * 16 * 16 = 768 ∧ 3 * 25 * 25 = 1875 := by norm_num

#print axioms three_sat_iff_gadget_vertex_cover
#print axioms vertex_cover_iff_edge_set_cover
#print axioms hamiltonian_cycle_iff_tour_within_budget

end KarpsList
