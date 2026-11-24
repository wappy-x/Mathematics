-- Beyond Turan: a graph on n vertices with no 4-cycle has at most (n/4)(1 + sqrt(4n - 3)) edges, and for any H the Turan graph with chi(H) - 1 parts is H-free, the easy half of Erdos-Stone.
import Mathlib.Combinatorics.SimpleGraph.Extremal.Turan
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Combinatorics.SimpleGraph.Coloring.Constructions
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Algebra.Order.Chebyshev
import Mathlib.Data.Nat.Choose.Cast
import Mathlib.Algebra.BigOperators.Field

open Finset SimpleGraph

/-- The cherry count, stated before the main theorems so they can use it. -/
theorem sum_choose_degree_le_choose_card_aux
    {V : Type*} [Fintype V] (G : SimpleGraph V) [DecidableRel G.Adj]
    (hG : (cycleGraph 4).Free G) :
    ∑ v, (G.degree v).choose 2 ≤ (Fintype.card V).choose 2 := by
  classical
  have hL : ∑ v, (G.degree v).choose 2 = #(univ.sigma fun v => (G.neighborFinset v).powersetCard 2) := by
    rw [card_sigma]
    simp [card_powersetCard]
  rw [hL]
  calc _ ≤ #((univ : Finset V).powersetCard 2) := ?_
    _ = _ := by simp [card_powersetCard]
  refine card_le_card_of_injOn (fun x => x.2) ?_ ?_
  · intro x hx
    simp only [coe_sigma, Set.mem_sigma_iff, mem_coe, mem_univ, true_and, mem_powersetCard] at hx ⊢
    exact ⟨subset_univ _, hx.2⟩
  · rintro ⟨v, s⟩ hv ⟨w, t⟩ hw (hst : s = t)
    subst hst
    simp only [coe_sigma, Set.mem_sigma_iff, mem_coe, mem_univ, true_and, mem_powersetCard] at hv hw
    obtain ⟨hsv, hs2⟩ := hv
    obtain ⟨hsw, -⟩ := hw
    by_contra hne
    have hvw : v ≠ w := fun h => hne (by subst h; rfl)
    obtain ⟨a, b, hab, rfl⟩ := card_eq_two.mp hs2
    have hva : G.Adj v a := (mem_neighborFinset _ _ _).mp (hsv (by simp))
    have hvb : G.Adj v b := (mem_neighborFinset _ _ _).mp (hsv (by simp))
    have hwa : G.Adj w a := (mem_neighborFinset _ _ _).mp (hsw (by simp))
    have hwb : G.Adj w b := (mem_neighborFinset _ _ _).mp (hsw (by simp))
    apply hG
    refine ⟨⟨⟨![v, a, w, b], ?_⟩, ?_⟩⟩
    · intro i j h
      fin_cases i <;> fin_cases j <;>
        first | (exfalso; revert h; decide) | simp [hva, hva.symm, hvb, hvb.symm, hwa, hwa.symm, hwb, hwb.symm]
    · intro i j h
      fin_cases i <;> fin_cases j <;> simp at h ⊢ <;>
        first | exact hva.ne h | exact hva.ne h.symm | exact hvb.ne h | exact hvb.ne h.symm | exact hwa.ne h | exact hwa.ne h.symm | exact hwb.ne h | exact hwb.ne h.symm | exact hvw h | exact hvw h.symm | exact hab h | exact hab h.symm

#print axioms sum_choose_degree_le_choose_card_aux

/-- **Kovari-Sos-Turan for the 4-cycle.** A simple graph on `n` vertices with no 4-cycle
(any copy of the 4-cycle counts, not only an induced one) has at most
`(n/4)(1 + sqrt(4n - 3))` edges: `ex(n, C₄) ≤ (n/4)(1 + √(4n - 3))`. -/
theorem extremalNumber_cycleGraph_four_le (n : ℕ) :
    (extremalNumber n (cycleGraph 4) : ℝ) ≤ (n : ℝ) / 4 * (1 + Real.sqrt (4 * n - 3)) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp [extremalNumber]
  have hnn : (0 : ℝ) ≤ (n : ℝ) / 4 * (1 + Real.sqrt (4 * n - 3)) := by positivity
  suffices key : ∀ ⦃G : SimpleGraph (Fin n)⦄ [DecidableRel G.Adj], (cycleGraph 4).Free G →
      (#G.edgeFinset : ℝ) ≤ (n : ℝ) / 4 * (1 + Real.sqrt (4 * n - 3)) by
    simpa using (extremalNumber_le_iff_of_nonneg (V := Fin n) (cycleGraph 4) hnn).mpr key
  intro G _ hG
  have h2 := sum_choose_degree_le_choose_card_aux G hG
  have h2' : ((∑ v, (G.degree v).choose 2 : ℕ) : ℝ) ≤ ((Fintype.card (Fin n)).choose 2 : ℕ) := by
    exact_mod_cast h2
  simp only [Nat.cast_sum, Nat.cast_choose_two, Fintype.card_fin] at h2'
  have hsum : (∑ v, (G.degree v : ℝ)) = 2 * #G.edgeFinset := by
    exact_mod_cast G.sum_degrees_eq_twice_card_edges
  have hcs := sq_sum_le_card_mul_sum_sq (s := (univ : Finset (Fin n))) (f := fun v => (G.degree v : ℝ))
  simp only [card_univ, Fintype.card_fin] at hcs
  rw [hsum] at hcs
  have hq : (∑ v, (G.degree v : ℝ) ^ 2) - ∑ v, (G.degree v : ℝ) ≤ n * (n - 1) := by
    have : ∑ v, (G.degree v : ℝ) * (G.degree v - 1) / 2 = ((∑ v, (G.degree v : ℝ) ^ 2) - ∑ v, (G.degree v : ℝ)) / 2 := by
      rw [← Finset.sum_sub_distrib, Finset.sum_div]
      congr 1; ext v; ring
    rw [this] at h2'
    linarith
  rw [hsum] at hq
  set e : ℝ := (#G.edgeFinset : ℝ)
  set Q := ∑ v, (G.degree v : ℝ) ^ 2
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hineq : (4 * e - n) ^ 2 ≤ (n : ℝ) ^ 2 * (4 * n - 3) := by nlinarith
  set s := Real.sqrt (4 * n - 3)
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hss : s ^ 2 = 4 * n - 3 := Real.sq_sqrt (by linarith)
  by_contra hc
  push Not at hc
  have ha : 0 < 4 * e - n - n * s := by linarith
  have hb : 0 < 4 * e - n + n * s := by nlinarith
  nlinarith [mul_pos ha hb]

/-- **The cherry count.** In a simple graph with no 4-cycle, every pair of vertices is the
pair of ends of at most one cherry, so the cherries counted by their middles,
`∑ v, C(d(v), 2)`, number at most `C(n, 2)`, the pairs of vertices. -/
theorem sum_choose_degree_le_choose_card_of_cycleGraph_four_free
    {V : Type*} [Fintype V] (G : SimpleGraph V) [DecidableRel G.Adj]
    (hG : (cycleGraph 4).Free G) :
    ∑ v, (G.degree v).choose 2 ≤ (Fintype.card V).choose 2 := by
  exact sum_choose_degree_le_choose_card_aux G hG

/-- **Erdos-Stone, the easy half.** If `H` needs exactly `r + 1` colours with `r ≥ 1`, the
Turan graph on `n` vertices with `r = χ(H) - 1` parts contains no copy of `H`, so its edge
count is a lower bound for `ex(n, H)`. -/
theorem card_edgeFinset_turanGraph_le_extremalNumber
    {W : Type*} (H : SimpleGraph W) {r : ℕ} (hr : 0 < r)
    (hχ : H.chromaticNumber = r + 1) (n : ℕ) :
    #(turanGraph n r).edgeFinset ≤ extremalNumber n H := by
  have hfree : H.Free (turanGraph n r) := by
    rintro ⟨f⟩
    have : NeZero r := ⟨hr.ne'⟩
    have hc : H.Colorable r := Colorable.of_hom f.toHom (Colorable.turanGraph n r)
    have := hc.chromaticNumber_le
    rw [hχ] at this
    norm_cast at this
    omega
  simpa using card_edgeFinset_le_extremalNumber hfree

-- The cap on 10 points is 17.71, so at most 17 edges: in whole numbers,
-- 4e ≤ n(1 + √(4n - 3)) with 4e ≥ n means (4e - n)² ≤ n²(4n - 3).
example : (4 * 17 - 10) ^ 2 ≤ 10 ^ 2 * (4 * 10 - 3) := by norm_num
example : ¬ ((4 * 18 - 10) ^ 2 ≤ 10 ^ 2 * (4 * 10 - 3)) := by norm_num

-- The Petersen graph: 10 middles of degree 3 give 10 × C(3, 2) = 30 cherries, at most C(10, 2) = 45.
example : 10 * Nat.choose 3 2 = 30 ∧ Nat.choose 10 2 = 45 ∧ 30 ≤ 45 := by decide

-- Average-degree test for the Petersen graph: a(a - 1) = 3 × 2 = 6 ≤ n - 1 = 9.
example : 3 * (3 - 1) ≤ 10 - 1 := by decide

-- Polarity graphs: q(q + 1)²/2 edges, 9 for q = 2 and 24 for q = 3, on q² + q + 1 = 7 and 13 points.
example : 2 * (2 + 1) ^ 2 / 2 = 9 ∧ 3 * (3 + 1) ^ 2 / 2 = 24 := by decide
example : 2 ^ 2 + 2 + 1 = 7 ∧ 3 ^ 2 + 3 + 1 = 13 := by decide

-- Caps rounded down for the polarity graphs: 9 ≤ 10 on 7 points, 24 ≤ 26 on 13 points.
example : (4 * 10 - 7) ^ 2 ≤ 7 ^ 2 * (4 * 7 - 3) ∧ ¬ ((4 * 11 - 7) ^ 2 ≤ 7 ^ 2 * (4 * 7 - 3)) := by
  norm_num
example : (4 * 26 - 13) ^ 2 ≤ 13 ^ 2 * (4 * 13 - 3) ∧ ¬ ((4 * 27 - 13) ^ 2 ≤ 13 ^ 2 * (4 * 13 - 3)) := by
  norm_num

-- Easy half on 1,000 points with two groups of 500: 500 × 500 = 250,000 cross links.
example : 500 * 500 = 250000 := by norm_num

-- Mantel's 25 on 10 points: the Turan graph with 2 parts on 10 vertices has 25 edges.
example : #(turanGraph 10 2).edgeFinset = 25 := by decide

#print axioms extremalNumber_cycleGraph_four_le
#print axioms sum_choose_degree_le_choose_card_of_cycleGraph_four_free
#print axioms card_edgeFinset_turanGraph_le_extremalNumber
