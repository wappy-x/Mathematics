-- Mantel and Turan: a simple graph on n vertices with no triangle has at most n^2/4 edges (rounded down), with equality exactly for two groups as equal as possible fully cross-linked, and with no r + 1 vertices all linked it has at most the edges of the Turan graph T(n, r), with equality exactly for T(n, r).
import Mathlib.Combinatorics.SimpleGraph.Extremal.Turan
import Mathlib.Tactic.NormNum
import Mathlib.Tactic

open SimpleGraph

/-- A graph that links exactly the pairs split by `A` has `|A| · (n − |A|)` links. -/
theorem card_edgeFinset_of_adj_iff_split {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (A : Finset V)
    (hA : ∀ v w : V, G.Adj v w ↔ (v ∈ A ↔ w ∉ A)) :
    G.edgeFinset.card = A.card * (Fintype.card V - A.card) := by
  have hdeg : ∀ v, G.degree v = if v ∈ A then Fintype.card V - A.card else A.card := by
    intro v
    rw [← G.card_neighborFinset_eq_degree, G.neighborFinset_eq_filter]
    split_ifs with hv
    · rw [← Finset.card_compl]
      congr 1; ext w; simp [hA, hv]
    · congr 1; ext w; simp [hA, hv]
  have h2 := G.sum_degrees_eq_twice_card_edges
  simp_rw [hdeg] at h2
  rw [Finset.sum_ite, Finset.sum_const, Finset.sum_const, smul_eq_mul, smul_eq_mul,
    Finset.filter_mem_eq_inter, Finset.univ_inter] at h2
  have hc : (Finset.univ.filter fun v => v ∉ A).card = Fintype.card V - A.card := by
    rw [Finset.filter_not, Finset.filter_mem_eq_inter, Finset.univ_inter, ← Finset.card_compl]
    simp [Finset.compl_eq_univ_sdiff]
  rw [hc] at h2
  have : A.card * (Fintype.card V - A.card) + (Fintype.card V - A.card) * A.card =
      2 * (A.card * (Fintype.card V - A.card)) := by ring
  omega

/-- `a · b = (a + b)^2 / 4` holds exactly when `a` and `b` differ by at most one. -/
theorem mul_eq_sq_div_four_iff (a b : ℕ) :
    a * b = (a + b) ^ 2 / 4 ↔ a ≤ b + 1 ∧ b ≤ a + 1 := by
  constructor
  · intro h
    have h1 : 4 * (a * b) ≤ (a + b) ^ 2 := by
      rw [h]; exact Nat.mul_div_le _ _
    have h2 : (a + b) ^ 2 < 4 * (a * b) + 4 := by
      rw [h]; have := Nat.lt_mul_div_succ ((a + b) ^ 2) (show 0 < 4 by norm_num); linarith
    constructor
    · by_contra hc; rw [not_le] at hc; nlinarith
    · by_contra hc; rw [not_le] at hc; nlinarith
  · rintro ⟨h1, h2⟩
    symm
    apply Nat.div_eq_of_lt_le
    · rcases Nat.lt_or_ge a b with h | h
      · obtain rfl : b = a + 1 := by omega
        ring_nf; omega
      · obtain ⟨c, rfl⟩ : ∃ c, a = b + c := ⟨a - b, by omega⟩
        nlinarith
    · rcases Nat.lt_or_ge a b with h | h
      · obtain rfl : b = a + 1 := by omega
        ring_nf; omega
      · obtain ⟨c, rfl⟩ : ∃ c, a = b + c := ⟨a - b, by omega⟩
        obtain rfl | rfl : c = 0 ∨ c = 1 := by omega
        · ring_nf; omega
        · ring_nf; omega

#print axioms card_edgeFinset_of_adj_iff_split
#print axioms mul_eq_sq_div_four_iff

/-- Turán's theorem with its equality case, read off Mathlib's `IsTuranMaximal` results. -/
theorem card_edgeFinset_le_turan_and_eq_iff {V : Type*} [Fintype V] (G : SimpleGraph V)
    [DecidableRel G.Adj] (r : ℕ) (h : G.CliqueFree (r + 1)) :
    G.edgeFinset.card ≤ (turanGraph (Fintype.card V) r).edgeFinset.card ∧
      (G.edgeFinset.card = (turanGraph (Fintype.card V) r).edgeFinset.card ↔
        Nonempty (G ≃g turanGraph (Fintype.card V) r)) := by
  have hle : G.edgeFinset.card ≤ (turanGraph (Fintype.card V) r).edgeFinset.card :=
    h.card_edgeFinset_le
  refine ⟨hle, ⟨fun heq => ?_, fun ⟨f⟩ => f.card_edgeFinset_eq⟩⟩
  rcases r.eq_zero_or_pos with rfl | hr
  · have hV : IsEmpty V := by rwa [cliqueFree_one] at h
    exact ⟨⟨Fintype.equivFin V, fun {a} => isEmptyElim a⟩⟩
  · refine (isTuranMaximal_iff_nonempty_iso_turanGraph hr).mp ⟨h, fun H _ hH => ?_⟩
    rw [heq]
    exact hH.card_edgeFinset_le

#print axioms card_edgeFinset_le_turan_and_eq_iff

/-- Mantel's theorem, as the card states it. A network of plain links (a simple graph: at most one
link per pair, no link from a point to itself) on `n` points with no triangle (no three points all
linked) has at most `n^2/4` links, rounded down. It reaches that count exactly when the points split
into two groups as equal as possible (sizes `⌊n/2⌋` and `⌈n/2⌉`) with every cross pair linked and no
pair inside a group linked. -/
theorem mantel_triangle_free_edges_le_sq_div_four {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] (h : G.CliqueFree 3) :
    G.edgeFinset.card ≤ Fintype.card V ^ 2 / 4 ∧
      (G.edgeFinset.card = Fintype.card V ^ 2 / 4 ↔
        ∃ A : Finset V, Fintype.card V / 2 ≤ A.card ∧ A.card ≤ (Fintype.card V + 1) / 2 ∧
          ∀ v w : V, G.Adj v w ↔ (v ∈ A ↔ w ∉ A)) := by
  have hT := card_edgeFinset_le_turan_and_eq_iff G 2 h
  have h2 : (turanGraph (Fintype.card V) 2).edgeFinset.card = Fintype.card V ^ 2 / 4 :=
    turanNumber_two
  rw [h2] at hT
  refine ⟨hT.1, ?_⟩
  rw [hT.2]
  constructor
  · rintro ⟨f⟩
    refine ⟨Finset.univ.filter fun v => (f v).val % 2 = 0, ?_⟩
    set A := Finset.univ.filter fun v => (f v).val % 2 = 0 with hAdef
    have hA : ∀ v w : V, G.Adj v w ↔ (v ∈ A ↔ w ∉ A) := by
      intro v w
      rw [← f.map_adj_iff, turanGraph_adj]
      simp only [hAdef, Finset.mem_filter, Finset.mem_univ, true_and]
      omega
    have hcard := card_edgeFinset_of_adj_iff_split G A hA
    rw [f.card_edgeFinset_eq, h2] at hcard
    have hAle : A.card ≤ Fintype.card V := Finset.card_le_univ A
    have key : A.card * (Fintype.card V - A.card) =
        (A.card + (Fintype.card V - A.card)) ^ 2 / 4 := by
      rw [Nat.add_sub_cancel' hAle]; exact hcard.symm
    rw [mul_eq_sq_div_four_iff] at key
    refine ⟨?_, ?_, hA⟩ <;> omega
  · rintro ⟨A, hA1, hA2, hA⟩
    have hcard := card_edgeFinset_of_adj_iff_split G A hA
    have hAle : A.card ≤ Fintype.card V := Finset.card_le_univ A
    have key : A.card * (Fintype.card V - A.card) =
        (A.card + (Fintype.card V - A.card)) ^ 2 / 4 := by
      rw [mul_eq_sq_div_four_iff]; omega
    rw [Nat.add_sub_cancel' hAle] at key
    rw [← hT.2, hcard, key]

/-- Turán's theorem, as the card states it. For any whole number `r`, a network of plain links on
`n` points with no `r + 1` points all linked (no clique `K(r+1)`) has at most as many links as the
Turán graph `T(n, r)`: `n` points in `r` groups whose sizes differ by at most one, every cross pair
linked. It reaches that count exactly when it is `T(n, r)`, up to relabelling the points. -/
theorem turan_clique_free_edges_le_turanGraph {V : Type*} [Fintype V] (G : SimpleGraph V)
    [DecidableRel G.Adj] (r : ℕ) (h : G.CliqueFree (r + 1)) :
    G.edgeFinset.card ≤ (turanGraph (Fintype.card V) r).edgeFinset.card ∧
      (G.edgeFinset.card = (turanGraph (Fintype.card V) r).edgeFinset.card ↔
        Nonempty (G ≃g turanGraph (Fintype.card V) r)) := by
  exact card_edgeFinset_le_turan_and_eq_iff G r h

/-- The Turán graph `T(n, r)`, for `r ≥ 1` groups, has no `r + 1` points all linked, and its links
number at most `(1 − 1/r) · n^2/2`. -/
theorem turanGraph_clique_free_and_edges_le (n r : ℕ) (hr : 0 < r) :
    (turanGraph n r).CliqueFree (r + 1) ∧
      ((turanGraph n r).edgeFinset.card : ℚ) ≤ (1 - 1 / (r : ℚ)) * (n : ℚ) ^ 2 / 2 := by
  refine ⟨turanGraph_cliqueFree hr, ?_⟩
  have h := mul_turanNumber_le (n := n) (r := r)
  have hq : (2 * r * (turanGraph n r).edgeFinset.card : ℚ) ≤ ((r - 1 : ℕ) : ℚ) * (n : ℚ) ^ 2 := by
    exact_mod_cast h
  rw [Nat.cast_sub (by omega : 1 ≤ r), Nat.cast_one] at hq
  have hr' : (0 : ℚ) < r := by exact_mod_cast hr
  rw [show (1 - 1 / (r : ℚ)) * (n : ℚ) ^ 2 / 2 = ((r : ℚ) - 1) * (n : ℚ) ^ 2 / (2 * r) by
    field_simp]
  rw [le_div_iff₀ (by positivity)]
  linarith

-- The rack of ten servers: 45 pairs, Mantel's cap 10 × 10 / 4 = 25, two groups of five give 5 × 5 = 25.
example : Nat.choose 10 2 = 45 := by decide
example : 10 ^ 2 / 4 = 25 ∧ 5 * 5 = 25 := by decide
-- T(10, 2), the two groups of five, has 25 links and no closed trio among its 120 trios.
example : (turanGraph 10 2).edgeFinset.card = 25 := by decide
example : ∀ a b c : Fin 10, ¬ ((turanGraph 10 2).Adj a b ∧ (turanGraph 10 2).Adj b c ∧
    (turanGraph 10 2).Adj a c) := by decide
-- A 26th link inside one group, say between servers 0 and 2: they share all five of the other
-- group as neighbours, so it closes five triangles.
example : (Finset.univ.filter fun w : Fin 10 =>
    (turanGraph 10 2).Adj 0 w ∧ (turanGraph 10 2).Adj 2 w).card = 5 := by decide
-- The degree squeeze: 4 × 25 × 25 / 10 = 250, ten degrees of 5 squared = 250, 10 × 25 = 250.
example : 4 * 25 * 25 / 10 = 250 ∧ 10 * 5 ^ 2 = 250 ∧ 10 * 25 = 250 := by decide
-- No four all linked, groups 4, 3, 3: 45 − 6 − 3 − 3 = 33 links, and T(10, 3) has 33.
example : Nat.choose 10 2 - Nat.choose 4 2 - Nat.choose 3 2 - Nat.choose 3 2 = 33 := by decide
example : (turanGraph 10 3).edgeFinset.card = 33 := by decide
-- Turán's share bound (1 − 1/3) × 100 / 2 = 100/3, just above 33.
example : (1 - 1 / (3 : ℚ)) * 100 / 2 = 100 / 3 ∧ (33 : ℚ) ≤ 100 / 3 := by norm_num
-- What breaks: splits 1+9 to 5+5 give 9, 16, 21, 24, 25; two groups with four forbidden give 25,
-- 8 short of 33; 9 servers give 81 / 4 rounded down = 20, groups of 4 and 5 give 20.
example : 1 * 9 = 9 ∧ 2 * 8 = 16 ∧ 3 * 7 = 21 ∧ 4 * 6 = 24 ∧ 5 * 5 = 25 := by decide
example : 33 - 25 = 8 := by decide
example : 9 ^ 2 / 4 = 20 ∧ 4 * 5 = 20 := by decide
-- The search over every network on 1 to 6 servers: the most links with no triangle are
-- 0, 1, 2, 4, 6, 9 = n^2/4 rounded down, and with no four all linked 0, 1, 3, 5, 8, 12 = links of T(n, 3).
example : [1, 2, 3, 4, 5, 6].map (fun n => n ^ 2 / 4) = [0, 1, 2, 4, 6, 9] := by decide
example : (turanGraph 1 3).edgeFinset.card = 0 ∧ (turanGraph 2 3).edgeFinset.card = 1 ∧
    (turanGraph 3 3).edgeFinset.card = 3 ∧ (turanGraph 4 3).edgeFinset.card = 5 ∧
    (turanGraph 5 3).edgeFinset.card = 8 ∧ (turanGraph 6 3).edgeFinset.card = 12 := by decide
-- Mantel's caps by the induction: 1, 4, 9, 16, 25 on 2, 4, 6, 8, 10 points.
example : [2, 4, 6, 8, 10].map (fun n => n ^ 2 / 4) = [1, 4, 9, 16, 25] := by decide

#print axioms mantel_triangle_free_edges_le_sq_div_four
#print axioms turan_clique_free_edges_le_turanGraph
#print axioms turanGraph_clique_free_and_edges_le
