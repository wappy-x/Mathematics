-- Colouring: in every finite graph the chromatic number is at least the size of the largest all-joined set and at most one more than the largest degree, the dot count is at most the chromatic number times the largest unjoined set, and the card's six exams need exactly three sessions.
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Combinatorics.SimpleGraph.CycleGraph
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Combinatorics.SimpleGraph.Coloring.Constructions
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open SimpleGraph

/-- Greedy colouring: every finite graph can be coloured with one colour more than its largest
degree. -/
theorem colorable_maxDegree_add_one_aux {V : Type*} [Fintype V] (G : SimpleGraph V)
    [DecidableRel G.Adj] : G.Colorable (G.maxDegree + 1) := by
  classical
  have key : ∀ s : Finset V, ∃ f : V → Fin (G.maxDegree + 1),
      ∀ u ∈ s, ∀ v ∈ s, G.Adj u v → f u ≠ f v := by
    intro s
    induction s using Finset.induction_on with
    | empty => exact ⟨fun _ => 0, by simp⟩
    | insert a s ha ih =>
      obtain ⟨f, hf⟩ := ih
      have hlt : ((G.neighborFinset a).image f).card <
          (Finset.univ : Finset (Fin (G.maxDegree + 1))).card := by
        calc _ ≤ (G.neighborFinset a).card := Finset.card_image_le
          _ = G.degree a := G.card_neighborFinset_eq_degree a
          _ ≤ G.maxDegree := G.degree_le_maxDegree a
          _ < _ := by simp
      obtain ⟨c, -, hc⟩ := Finset.exists_mem_notMem_of_card_lt_card hlt
      have hcne : ∀ w, G.Adj a w → c ≠ f w := fun w hw h =>
        hc (Finset.mem_image.mpr ⟨w, by simpa using hw, h.symm⟩)
      refine ⟨Function.update f a c, ?_⟩
      intro u hu v hv huv
      rw [Finset.mem_insert] at hu hv
      by_cases hua : u = a
      · subst hua
        have hva : v ≠ u := (G.ne_of_adj huv).symm
        rw [Function.update_self, Function.update_of_ne hva]
        exact hcne v huv
      · by_cases hvb : v = a
        · subst hvb
          rw [Function.update_self, Function.update_of_ne hua]
          exact (hcne u huv.symm).symm
        · rw [Function.update_of_ne hua, Function.update_of_ne hvb]
          exact hf u (hu.resolve_left hua) v (hv.resolve_left hvb) huv
  obtain ⟨f, hf⟩ := key Finset.univ
  exact ⟨Coloring.mk f fun {u v} h => hf u (Finset.mem_univ _) v (Finset.mem_univ _) h⟩

/-- The two bounds. In every finite graph (no dot joined to itself, which `SimpleGraph` builds
in), a proper colouring needs at least as many colours as its largest set of dots joined in
every pair, and never more than one past the largest line count at a single dot:
ω(G) ≤ χ(G) ≤ Δ(G) + 1. -/
theorem cliqueNum_le_chromaticNumber_le_maxDegree_add_one {V : Type*} [Fintype V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    (G.cliqueNum : ℕ∞) ≤ G.chromaticNumber ∧ G.chromaticNumber ≤ G.maxDegree + 1 := by
  refine ⟨cliqueNum_le_chromaticNumber, ?_⟩
  have h := (colorable_maxDegree_add_one_aux G).chromaticNumber_le
  exact_mod_cast h

/-- The second floor. Each colour's dots form a set with no line inside, so in every finite
graph the dot count n is at most χ(G) times the size α(G) of the largest such set; that is,
χ(G) is at least n ÷ α(G), rounded up. -/
theorem card_le_chromaticNumber_mul_indepNum {V : Type*} [Fintype V] (G : SimpleGraph V) :
    (Fintype.card V : ℕ∞) ≤ G.chromaticNumber * G.indepNum := by
  classical
  have hC := G.colorable_chromaticNumber_of_fintype
  have hne : G.chromaticNumber ≠ ⊤ := chromaticNumber_ne_top_iff_exists.mpr ⟨_, hC⟩
  obtain ⟨C⟩ := hC
  have key : Fintype.card V ≤ G.chromaticNumber.toNat * G.indepNum := by
    rw [← Finset.card_univ, Finset.card_eq_sum_card_fiberwise (f := C) (t := Finset.univ)
      (fun _ _ => Finset.mem_univ _)]
    calc _ ≤ ∑ _c : Fin G.chromaticNumber.toNat, G.indepNum := Finset.sum_le_sum fun c _ => ?_
      _ = G.chromaticNumber.toNat * G.indepNum := by simp
    apply IsIndepSet.card_le_indepNum
    intro u hu v hv _ hadj
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hu hv
    exact C.valid hadj (hu.trans hv.symm)
  rw [← ENat.natCast_toNat hne]
  exact_mod_cast key

/-! The card's exam graph: Algebra, Biology, Chemistry, Drama, Economics, French as `0` to `5`.
Students sit A B C, D E F, A D, B E and C F; two exams clash when one student sits both. -/

/-- Each exam's clashes, from the five students' enrolments. -/
def clashes : Fin 6 → List (Fin 6)
  | 0 => [1, 2, 3]   -- Algebra: Biology, Chemistry, Drama
  | 1 => [0, 2, 4]   -- Biology: Algebra, Chemistry, Economics
  | 2 => [0, 1, 5]   -- Chemistry: Algebra, Biology, French
  | 3 => [4, 5, 0]   -- Drama: Economics, French, Algebra
  | 4 => [3, 5, 1]   -- Economics: Drama, French, Biology
  | 5 => [3, 4, 2]   -- French: Drama, Economics, Chemistry

/-- The clash graph: a dot per exam, a line per clashing pair. -/
def exam : SimpleGraph (Fin 6) where
  Adj u v := v ∈ clashes u
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel exam.Adj := fun u v => inferInstanceAs (Decidable (v ∈ clashes u))

-- Nine clashing pairs: 3 + 3 + 1 + 1 + 1 = 9.
example : exam.edgeFinset.card = 9 ∧ 3 + 3 + 1 + 1 + 1 = 9 := by refine ⟨by decide, by norm_num⟩
-- Every exam has three clashes, so Δ = 3.
example : (∀ v, exam.degree v = 3) ∧ exam.maxDegree = 3 := by
  have h : ∀ v, exam.degree v = 3 := by decide
  exact ⟨h, le_antisymm (maxDegree_le_of_forall_degree_le _ 3 fun v => (h v).le)
    ((h 0).symm.le.trans (degree_le_maxDegree _ 0))⟩
-- Algebra, Biology, Chemistry clash in every pair: ω = 3.
example : exam.IsClique ({0, 1, 2} : Finset (Fin 6)) ∧ exam.cliqueNum = 3 := by
  have hcl : exam.IsClique ({0, 1, 2} : Finset (Fin 6)) := by decide
  refine ⟨hcl, le_antisymm ?_ ?_⟩
  · have hval : ∀ u v, exam.Adj u v →
        (![0, 1, 2, 1, 2, 0] : Fin 6 → Fin 3) u ≠ (![0, 1, 2, 1, 2, 0] : Fin 6 → Fin 3) v := by
      decide
    have hcol : exam.Colorable 3 := ⟨Coloring.mk _ fun h => hval _ _ h⟩
    have h := (cliqueNum_le_chromaticNumber (G := exam)).trans hcol.chromaticNumber_le
    exact_mod_cast h
  · have h := hcl.card_le_cliqueNum
    simpa using h
-- Biology and Drama do not clash, and no three exams are clash-free: α = 2, and 6 ÷ 2 = 3.
example : exam.IsIndepSet ({1, 3} : Finset (Fin 6)) ∧ exam.indepNum = 2 ∧ 6 = 3 * 2 := by
  have hind : exam.IsIndepSet ({1, 3} : Finset (Fin 6)) := by decide
  refine ⟨hind, le_antisymm ?_ ?_, by norm_num⟩
  · obtain ⟨s, hs⟩ := exam.exists_isNIndepSet_indepNum
    rw [← hs.card_eq]
    have hall : ∀ t : Finset (Fin 6), exam.IsIndepSet t → t.card ≤ 2 := by decide
    exact hall s hs.isIndepSet
  · have h := hind.card_le_indepNum
    simpa using h
-- Greedy in the listed order: colours 1, 2, 3, 2, 1, 4, proper, four sessions, within Δ + 1 = 4.
example : (∀ u v, exam.Adj u v →
    (![1, 2, 3, 2, 1, 4] : Fin 6 → ℕ) u ≠ (![1, 2, 3, 2, 1, 4] : Fin 6 → ℕ) v) ∧ 3 + 1 = 4 := by
  exact ⟨by decide, by norm_num⟩
-- The timetable: Algebra and French in session 1, Biology and Drama in 2, Chemistry and
-- Economics in 3; no clash inside a session.
example : ∀ u v, exam.Adj u v →
    (![1, 2, 3, 2, 3, 1] : Fin 6 → ℕ) u ≠ (![1, 2, 3, 2, 3, 1] : Fin 6 → ℕ) v := by decide
-- Brooks' test on the exam graph: one piece, not complete (Algebra and Economics do not clash).
example : exam.Connected ∧ ¬ exam.Adj 0 4 := by
  have h0 : ∀ v, exam.Reachable 0 v := by
    intro v
    fin_cases v
    · exact Reachable.refl _
    · exact Adj.reachable (by decide)
    · exact Adj.reachable (by decide)
    · exact Adj.reachable (by decide)
    · exact (Adj.reachable (show exam.Adj 0 1 by decide)).trans
        (Adj.reachable (show exam.Adj 1 4 by decide))
    · exact (Adj.reachable (show exam.Adj 0 2 by decide)).trans
        (Adj.reachable (show exam.Adj 2 5 by decide))
  exact ⟨(connected_iff _).mpr ⟨fun u v => (h0 u).symm.trans (h0 v), ⟨0⟩⟩, by decide⟩
-- Floor 3 meets ceiling 3: the exams need exactly three sessions.
example : exam.chromaticNumber = 3 := by
  have hval : ∀ u v, exam.Adj u v →
      (![0, 1, 2, 1, 2, 0] : Fin 6 → Fin 3) u ≠ (![0, 1, 2, 1, 2, 0] : Fin 6 → Fin 3) v := by
    decide
  have hcol : exam.Colorable 3 := ⟨Coloring.mk _ fun h => hval _ _ h⟩
  have hcl : exam.IsClique ({0, 1, 2} : Finset (Fin 6)) := by decide
  refine le_antisymm hcol.chromaticNumber_le ?_
  have h := hcl.card_le_chromaticNumber
  simpa using h
-- Mistake 2: the triangle alone has busiest count 2 and still needs 3 colours.
example : (cycleGraph 3).maxDegree = 2 ∧ (cycleGraph 3).chromaticNumber = 3 := by
  have h : ∀ v, (cycleGraph 3).degree v = 2 := fun v => cycleGraph_degree_three_le
  refine ⟨le_antisymm (maxDegree_le_of_forall_degree_le _ 2 fun v => (h v).le)
    ((h 0).symm.le.trans (degree_le_maxDegree _ 0)), ?_⟩
  exact chromaticNumber_cycleGraph_of_odd 3 (by norm_num) (by decide)
-- Mistake 3: the ring of five exams has no clashing triple (ω = 2) and still needs 3.
example : (cycleGraph 5).cliqueNum = 2 ∧ (cycleGraph 5).chromaticNumber = 3 := by
  refine ⟨le_antisymm ?_ ?_, chromaticNumber_cycleGraph_of_odd 5 (by norm_num) (by decide)⟩
  · obtain ⟨s, hs⟩ := (cycleGraph 5).exists_isNClique_cliqueNum
    rw [← hs.card_eq]
    have hall : ∀ t : Finset (Fin 5), (cycleGraph 5).IsClique t → t.card ≤ 2 := by decide
    exact hall s hs.isClique
  · have hcl : (cycleGraph 5).IsClique ({0, 1} : Finset (Fin 5)) := by decide
    have h := hcl.card_le_cliqueNum
    simpa using h

#print axioms colorable_maxDegree_add_one_aux
#print axioms cliqueNum_le_chromaticNumber_le_maxDegree_add_one
#print axioms card_le_chromaticNumber_mul_indepNum
