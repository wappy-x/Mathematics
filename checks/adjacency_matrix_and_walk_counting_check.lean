-- The adjacency matrix: in every finite simple graph the k-th power of the adjacency matrix counts, in row i and column j, the walks of exactly k edges from i to j, its square has the degrees down the diagonal, the trace of its cube is six times the number of triangles, and the card's six-station metro numbers check out.
import Mathlib.Combinatorics.SimpleGraph.AdjMatrix
import Mathlib.Combinatorics.SimpleGraph.Walk.Counting
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.LinearAlgebra.Matrix.Trace

namespace AdjacencyMatrixAndWalkCounting

open SimpleGraph

open Finset

/-- Helper: the trace of the cube counts ordered triples `(a, b, c)` with lines `a-b`, `b-c`, `c-a`. -/
theorem trace_cube_eq_card_triples {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    Matrix.trace (G.adjMatrix ℕ ^ 3) =
      (Finset.univ.filter (fun t : V × V × V => G.Adj t.1 t.2.1 ∧ G.Adj t.2.1 t.2.2 ∧ G.Adj t.2.2 t.1)).card := by
  rw [Finset.card_filter, ← Finset.univ_product_univ, Finset.sum_product,
    ← Finset.univ_product_univ]
  simp only [Matrix.trace, Matrix.diag, pow_three, Matrix.mul_apply, adjMatrix_apply,
    Finset.sum_product, Finset.mul_sum, ite_zero_mul_ite_zero, mul_one]

#print axioms trace_cube_eq_card_triples

/-- Helper: the ordered triples that ride around the triangle `{a, b, c}` are exactly six. -/
theorem fiber_card {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (a b c : V)
    (hab : G.Adj a b) (hac : G.Adj a c) (hbc : G.Adj b c) :
    #((univ.filter (fun t : V × V × V => G.Adj t.1 t.2.1 ∧ G.Adj t.2.1 t.2.2 ∧ G.Adj t.2.2 t.1)).filter
      (fun t => ({t.1, t.2.1, t.2.2} : Finset V) = {a, b, c})) = 6 := by
  have h1 := hab.ne
  have h2 := hac.ne
  have h3 := hbc.ne
  have key : (univ.filter (fun t : V × V × V => G.Adj t.1 t.2.1 ∧ G.Adj t.2.1 t.2.2 ∧ G.Adj t.2.2 t.1)).filter
      (fun t => ({t.1, t.2.1, t.2.2} : Finset V) = {a, b, c}) =
      {(a, b, c), (a, c, b), (b, a, c), (b, c, a), (c, a, b), (c, b, a)} := by
    ext ⟨x, y, z⟩
    simp only [mem_filter, mem_univ, true_and, mem_insert, mem_singleton, Prod.mk.injEq]
    constructor
    · rintro ⟨⟨hxy, hyz, hzx⟩, hs⟩
      have hx : x ∈ ({a, b, c} : Finset V) := hs ▸ by simp
      have hy : y ∈ ({a, b, c} : Finset V) := hs ▸ by simp
      have hz : z ∈ ({a, b, c} : Finset V) := hs ▸ by simp
      simp only [mem_insert, mem_singleton] at hx hy hz
      have := hxy.ne
      have := hyz.ne
      have := hzx.ne
      rcases hx with rfl | rfl | rfl <;> rcases hy with rfl | rfl | rfl <;>
        rcases hz with rfl | rfl | rfl <;> simp_all
    · rintro (⟨rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl⟩ |
        ⟨rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl⟩) <;>
      refine ⟨⟨?_, ?_, ?_⟩, ?_⟩ <;>
      first
        | assumption
        | exact hab.symm | exact hac.symm | exact hbc.symm
        | (ext; simp only [mem_insert, mem_singleton]; try tauto)
  rw [key]
  simp [h1, h2, h3, h1.symm, h2.symm, h3.symm]

#print axioms fiber_card

/-- The card's main result. Take any finite network with no loops (a simple graph `G` on a finite
set of stations `V`) and its adjacency matrix `A`: a 1 in row `i`, column `j` when a line joins
`i` and `j`, otherwise 0. Then for every length `k` and every two stations `i` and `j`, the entry
in row `i`, column `j` of `A ^ k` is the number of walks of exactly `k` lines from `i` to `j`
(stations and lines may repeat). -/
theorem adjMatrix_pow_entry_counts_walks {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (k : ℕ) (i j : V) :
    (G.adjMatrix ℕ ^ k) i j = Fintype.card {p : G.Walk i j | p.length = k} := by
  exact adjMatrix_pow_apply_eq_card_walk (G := G) k i j

/-- The diagonal of the square counts the rides "take a line, take it back": the entry in row `i`,
column `i` of `A ^ 2` is the degree of `i`, the number of lines meeting it. -/
theorem adjMatrix_sq_diagonal_eq_degree {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (i : V) :
    (G.adjMatrix ℕ ^ 2) i i = G.degree i := by
  rw [sq, adjMatrix_mul_self_apply_self]
  rfl

/-- With no loops, a closed walk of three lines is a triangle ridden from one of its three corners
in one of two directions, so the trace of `A ^ 3` (the sum of its diagonal) is six times the
number of triangles. -/
theorem trace_adjMatrix_cube_eq_six_mul_triangles {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    Matrix.trace (G.adjMatrix ℕ ^ 3) = 6 * (G.cliqueFinset 3).card := by
  rw [trace_cube_eq_card_triples,
    card_eq_sum_card_fiberwise (f := fun t : V × V × V => ({t.1, t.2.1, t.2.2} : Finset V))
      (t := G.cliqueFinset 3) ?_, sum_const_nat (m := 6) ?_, mul_comm]
  · intro s hs
    obtain ⟨a, b, c, hab, hac, hbc, rfl⟩ := is3Clique_iff.1 (mem_cliqueFinset_iff.1 hs)
    exact fiber_card G a b c hab hac hbc
  · intro t ht
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at ht
    exact mem_coe.2 <| mem_cliqueFinset_iff.2 (is3Clique_triple_iff.2 ⟨ht.1, ht.2.2.symm, ht.2.1⟩)

/-! The card's metro: stations A to F are `0` to `5`. -/

/-- The eight lines: A-B, B-C, C-D, D-E, E-F, F-A and the crossings B-E and C-F. -/
def metroLines : List (Fin 6 × Fin 6) :=
  [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]

/-- The metro as a simple graph. -/
def metro : SimpleGraph (Fin 6) where
  Adj x y := (x, y) ∈ metroLines ∨ (y, x) ∈ metroLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel metro.Adj := fun _ _ => inferInstanceAs (Decidable (_ ∨ _))

/-- The metro plus the line A-C: nine lines. -/
def metroPlusLines : List (Fin 6 × Fin 6) := (0, 2) :: metroLines

/-- The metro plus the line A-C, as a simple graph. -/
def metroPlus : SimpleGraph (Fin 6) where
  Adj x y := (x, y) ∈ metroPlusLines ∨ (y, x) ∈ metroPlusLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel metroPlus.Adj := fun _ _ => inferInstanceAs (Decidable (_ ∨ _))

-- Row A of the table is 0 1 0 0 0 1; the row sums (degrees) are 2 3 3 2 3 3.
example : (List.finRange 6).map (fun j => metro.adjMatrix ℕ 0 j) = [0, 1, 0, 0, 0, 1] := by
  decide
example : (List.finRange 6).map (fun i => metro.degree i) = [2, 3, 3, 2, 3, 3] := by decide
-- Row A of the square is 2 0 2 0 2 0; of the cube, 0 6 0 4 0 6.
example : (List.finRange 6).map (fun j => (metro.adjMatrix ℕ ^ 2) 0 j) = [2, 0, 2, 0, 2, 0] := by
  decide
example : (List.finRange 6).map (fun j => (metro.adjMatrix ℕ ^ 3) 0 j) = [0, 6, 0, 4, 0, 6] := by
  decide
-- The square's diagonal is 2 3 3 2 3 3 and its trace is 16 = 2 × 8 lines.
example : (List.finRange 6).map (fun i => (metro.adjMatrix ℕ ^ 2) i i) = [2, 3, 3, 2, 3, 3] := by
  decide
example : Matrix.trace (metro.adjMatrix ℕ ^ 2) = 16 ∧ 16 = 2 * 8 := by decide
-- Three-line routes A to F: 6 from the table, 6 walks when listed, 2 of them never repeat a station.
example : (metro.adjMatrix ℕ ^ 3) 0 5 = 6 := by decide
example : Fintype.card {p : metro.Walk 0 5 | p.length = 3} = 6 := by decide
example : ((metro.finsetWalkLength 3 0 5).filter (fun p => p.support.Nodup)).card = 2 := by decide
-- The cube's trace is 0, so no triangles; with A-C added it is 12, and 12 / 6 = 2 triangles.
example : Matrix.trace (metro.adjMatrix ℕ ^ 3) = 0 := by decide
example : Matrix.trace (metroPlus.adjMatrix ℕ ^ 3) = 12 ∧ 12 / 6 = 2 := by decide
example : (metro.cliqueFinset 3).card = 0 ∧ (metroPlus.cliqueFinset 3).card = 2 := by decide
-- The mistakes: squaring cell by cell gives 1 at (A, F), where the square holds 0;
-- a 1 down the diagonal to let a train wait gives 9 three-step rides A to F, not 6.
example : metro.adjMatrix ℕ 0 5 * metro.adjMatrix ℕ 0 5 = 1 := by decide
example : ((metro.adjMatrix ℕ + 1 : Matrix (Fin 6) (Fin 6) ℕ) ^ 3) 0 5 = 9 := by decide

#print axioms adjMatrix_pow_entry_counts_walks
#print axioms adjMatrix_sq_diagonal_eq_degree
#print axioms trace_adjMatrix_cube_eq_six_mul_triangles

end AdjacencyMatrixAndWalkCounting
