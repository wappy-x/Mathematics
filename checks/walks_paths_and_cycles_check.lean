-- Walks, paths and cycles: every walk in a graph contains a path with the same ends and no more steps, so on a connected graph the distance is the step count of a shortest path, it is symmetric and obeys the triangle rule, the radius is at most the diameter and the diameter at most twice the radius, and the card's metro map has the distances, diameter 3, radius 2 and girth 4 it claims.
import Mathlib.Combinatorics.SimpleGraph.Paths
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Combinatorics.SimpleGraph.Diam
import Mathlib.Combinatorics.SimpleGraph.Girth
import Mathlib.Combinatorics.SimpleGraph.Walk.Counting

open SimpleGraph

/-- Strip the repeats out of any journey and a repeat-free route with the same ends is left, no
longer than before: in any graph, every walk from u to v contains a path from u to v. The path
uses only stations and lines of the walk, and takes no more steps. -/
theorem every_walk_contains_a_path {V : Type*} (G : SimpleGraph V) {u v : V} (p : G.Walk u v) :
    ∃ q : G.Walk u v, q.IsPath ∧ q.length ≤ p.length ∧
      q.support ⊆ p.support ∧ q.edges ⊆ p.edges := by
  classical
  exact ⟨p.bypass, p.bypass_isPath, p.length_bypass_le_length, p.support_bypass_subset_support,
    p.edges_bypass_subset_edges⟩

/-- Distance is the fewest steps, and it behaves like distance. On a graph where every station
can be reached from every other, the distance d(u, v) is the length of some path from u to v and
no walk from u to v is shorter; d(u, v) = d(v, u); and going by way of a third station w never
saves a step: d(u, w) ≤ d(u, v) + d(v, w). -/
theorem distance_is_shortest_path_length {V : Type*} (G : SimpleGraph V) (hG : G.Connected)
    (u v w : V) :
    (∃ p : G.Walk u v, p.IsPath ∧ p.length = G.dist u v) ∧
      (∀ p : G.Walk u v, G.dist u v ≤ p.length) ∧
      G.dist u v = G.dist v u ∧
      G.dist u w ≤ G.dist u v + G.dist v w := by
  exact ⟨hG.exists_path_of_dist u v, fun p => G.dist_le p, G.dist_comm, hG.dist_triangle⟩

/-- The radius-diameter rule. On a graph where every station can be reached from every other,
the radius (smallest eccentricity) is at most the diameter (largest eccentricity), and the
diameter is at most twice the radius: rad(G) ≤ diam(G) ≤ 2 × rad(G). -/
theorem radius_le_diameter_le_two_mul_radius {V : Type*} (G : SimpleGraph V)
    (hG : G.Connected) :
    G.radius ≤ G.ediam ∧ G.ediam ≤ 2 * G.radius := by
  have := hG.nonempty
  exact ⟨radius_le_ediam, ediam_le_two_mul_radius⟩

/-! The card's metro map: stations A to F are 0 to 5, with the lines A-B, B-C, C-D, D-E, E-F,
F-A and the crossings B-E and C-F. -/

/-- The eight lines of the metro, each listed once. -/
def metroLines : List (Fin 6 × Fin 6) :=
  [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]

/-- The metro map as a graph: two stations are joined when a line runs between them. -/
def metro : SimpleGraph (Fin 6) where
  Adj a b := (a, b) ∈ metroLines ∨ (b, a) ∈ metroLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel metro.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ metroLines ∨ (b, a) ∈ metroLines))

/-- The walk A-B-A-B-C-D, which doubles back. -/
def walkABABCD : metro.Walk 0 3 :=
  .cons (v := 1) (by decide) <| .cons (v := 0) (by decide) <| .cons (v := 1) (by decide) <|
    .cons (v := 2) (by decide) <| .cons (v := 3) (by decide) .nil

/-- The path A-B-C-D, left when the stretch between the two B's is cut out. -/
def walkABCD : metro.Walk 0 3 :=
  .cons (v := 1) (by decide) <| .cons (v := 2) (by decide) <| .cons (v := 3) (by decide) .nil

/-- The journey B-A-F-C-B-E: no line twice, but B twice. -/
def walkBAFCBE : metro.Walk 1 4 :=
  .cons (v := 0) (by decide) <| .cons (v := 5) (by decide) <| .cons (v := 2) (by decide) <|
    .cons (v := 1) (by decide) <| .cons (v := 4) (by decide) .nil

/-- The loop A-B-C-F-A. -/
def loopABCFA : metro.Walk 0 0 :=
  .cons (v := 1) (by decide) <| .cons (v := 2) (by decide) <| .cons (v := 5) (by decide) <|
    .cons (v := 0) (by decide) .nil

/-- The repeat-free route A-B-C-D-E-F. -/
def walkABCDEF : metro.Walk 0 5 :=
  .cons (v := 1) (by decide) <| .cons (v := 2) (by decide) <| .cons (v := 3) (by decide) <|
    .cons (v := 4) (by decide) <| .cons (v := 5) (by decide) .nil

/-- The out-and-back B-C-B. -/
def walkBCB : metro.Walk 1 1 :=
  .cons (v := 2) (by decide) <| .cons (v := 1) (by decide) .nil

/-- Helper: a lower bound on a metro distance from the absence of short walks. -/
theorem metro_le_edist {u v : Fin 6} {n : ℕ}
    (h : ∀ k : Fin n, metro.finsetWalkLength k u v = ∅) : (n : ℕ∞) ≤ metro.edist u v := by
  rw [edist_eq_sInf]
  apply le_sInf
  rintro _ ⟨w, rfl⟩
  by_contra hlt
  have hlt' : (w.length : ℕ∞) < n := not_le.mp hlt
  have hk : w.length < n := by exact_mod_cast hlt'
  have hm : w ∈ metro.finsetWalkLength w.length u v := mem_finsetWalkLength_iff.mpr rfl
  rw [h ⟨w.length, hk⟩] at hm
  simp at hm

/-- Helper: an upper bound on a metro distance from a short walk. -/
theorem metro_edist_le {u v : Fin 6} {n : ℕ}
    (h : ∃ k : Fin (n + 1), (metro.finsetWalkLength k u v).Nonempty) :
    metro.edist u v ≤ n := by
  obtain ⟨k, w, hw⟩ := h
  rw [mem_finsetWalkLength_iff] at hw
  refine (edist_le w).trans ?_
  rw [hw]
  exact_mod_cast Nat.lt_succ_iff.mp k.isLt

/-- Helper: computing a metro eccentricity by walk counts. -/
theorem metro_eccent_eq (u : Fin 6) (e : ℕ)
    (hup : ∀ v, ∃ k : Fin (e + 1), (metro.finsetWalkLength k u v).Nonempty)
    (hlo : ∃ v, ∀ k : Fin e, metro.finsetWalkLength k u v = ∅) :
    metro.eccent u = e := by
  apply le_antisymm
  · rw [eccent_le_iff]
    exact fun v => metro_edist_le (hup v)
  · obtain ⟨v, hv⟩ := hlo
    exact (metro_le_edist hv).trans edist_le_eccent

/-- Helper: the six eccentricities of the metro. -/
theorem metro_eccent_values : metro.eccent 0 = 3 ∧ metro.eccent 1 = 2 ∧ metro.eccent 2 = 2 ∧
    metro.eccent 3 = 3 ∧ metro.eccent 4 = 2 ∧ metro.eccent 5 = 2 :=
  ⟨metro_eccent_eq 0 3 (by decide) (by decide), metro_eccent_eq 1 2 (by decide) (by decide),
    metro_eccent_eq 2 2 (by decide) (by decide), metro_eccent_eq 3 3 (by decide) (by decide),
    metro_eccent_eq 4 2 (by decide) (by decide), metro_eccent_eq 5 2 (by decide) (by decide)⟩

/-- Helper: the metro radius is 2. -/
theorem metro_radius : metro.radius = 2 := by
  obtain ⟨h0, h1, h2, h3, h4, h5⟩ := metro_eccent_values
  apply le_antisymm
  · exact h1 ▸ radius_le_eccent
  · apply le_iInf
    intro u
    fin_cases u <;> simp [h0, h1, h2, h3, h4, h5] <;> decide

/-- Helper: the metro extended diameter is 3. -/
theorem metro_ediam : metro.ediam = 3 := by
  obtain ⟨h0, h1, h2, h3, h4, h5⟩ := metro_eccent_values
  apply le_antisymm
  · apply iSup_le
    intro u
    fin_cases u <;> simp [h0, h1, h2, h3, h4, h5] <;> decide
  · exact h0 ▸ eccent_le_ediam

/-- Helper: the metro has no closed walk of three steps. -/
theorem metro_no_closed_three : ∀ a : Fin 6, metro.finsetWalkLength 3 a a = ∅ := by decide

-- Eight lines on six stations.
example : metro.edgeFinset.card = 8 := by decide
-- A-B-A-B-C-D is a walk of five steps that is not a path.
example : walkABABCD.length = 5 ∧ ¬ walkABABCD.IsPath := by
  refine ⟨rfl, ?_⟩
  rw [Walk.isPath_def]; decide
-- Cutting the detour leaves A-B-C-D: a path of three steps, same ends.
example : walkABCD.length = 3 ∧ walkABCD.IsPath := by
  refine ⟨rfl, ?_⟩
  rw [Walk.isPath_def]; decide
-- B-A-F-C-B-E repeats no line, so it is a trail, but it passes B twice, so it is not a path.
example : walkBAFCBE.IsTrail ∧ ¬ walkBAFCBE.IsPath := by
  rw [Walk.isTrail_def, Walk.isPath_def]; decide
-- A to D: no walk of two steps or fewer, and the distance is 3.
example : metro.finsetWalkLength 2 0 3 = ∅ := by decide
example : metro.dist 0 3 = 3 := by
  have h : metro.edist 0 3 = 3 :=
    le_antisymm (metro_edist_le (by decide)) (metro_le_edist (by decide))
  rw [dist, h]
  rfl
-- Four routes from A to D take three steps each: A-B-C-D, A-B-E-D, A-F-C-D, A-F-E-D.
example : (metro.finsetWalkLength 3 0 3).card = 4 := by decide
-- Counting stations instead of steps gives 4: A-B-C-D lists four stations.
example : walkABCD.support.length = 4 := by rfl
-- Eccentricities: 3 from A, 2 from B, and the full row 3, 2, 2, 3, 2, 2.
example : metro.eccent 0 = 3 ∧ metro.eccent 1 = 2 ∧ metro.eccent 2 = 2 ∧
    metro.eccent 3 = 3 ∧ metro.eccent 4 = 2 ∧ metro.eccent 5 = 2 := metro_eccent_values
-- The diameter is 3 and the radius 2.
example : metro.diam = 3 := by
  rw [diam, metro_ediam]
  rfl
example : metro.radius = 2 := metro_radius
-- The centre is B, C, E, F.
example : metro.center = {1, 2, 4, 5} := by
  obtain ⟨h0, h1, h2, h3, h4, h5⟩ := metro_eccent_values
  ext u
  rw [mem_center_iff, metro_radius]
  fin_cases u <;> simp [h0, h1, h2, h3, h4, h5]
-- The radius-diameter rule here: 2 ≤ 3 ≤ 4.
example : (2 : ℕ) ≤ 3 ∧ 3 ≤ 2 * 2 := by decide
-- The loop A-B-C-F-A is a cycle of four steps, and the girth is 4.
example : loopABCFA.IsCycle ∧ loopABCFA.length = 4 := by
  refine ⟨?_, rfl⟩
  rw [loopABCFA, Walk.cons_isCycle_iff, Walk.isPath_def]; decide
example : metro.girth = 4 := by
  have hc : loopABCFA.IsCycle := by
    rw [loopABCFA, Walk.cons_isCycle_iff, Walk.isPath_def]; decide
  have h : metro.egirth = 4 := by
    apply le_antisymm
    · exact hc.egirth_le_length
    · rw [le_egirth]
      intro a w hw
      have h3 := hw.three_le_length
      have hne : w.length ≠ 3 := by
        intro hl
        have hm : w ∈ metro.finsetWalkLength 3 a a := mem_finsetWalkLength_iff.mpr hl
        rw [metro_no_closed_three a] at hm
        simp at hm
      exact_mod_cast (show 4 ≤ w.length by omega)
  rw [girth, h]
  rfl
-- The longest repeat-free route, A-B-C-D-E-F, is a path of 5 steps, not the diameter 3.
example : walkABCDEF.IsPath ∧ walkABCDEF.length = 5 := by
  refine ⟨?_, rfl⟩
  rw [Walk.isPath_def]; decide
-- B-C-B closes in 2 steps but is not a cycle.
example : walkBCB.length = 2 ∧ ¬ walkBCB.IsCycle := by
  refine ⟨rfl, ?_⟩
  rw [Walk.isCycle_def, Walk.isTrail_def]; decide

#print axioms every_walk_contains_a_path
#print axioms distance_is_shortest_path_length
#print axioms radius_le_diameter_le_two_mul_radius
#print axioms metro_le_edist
#print axioms metro_edist_le
#print axioms metro_eccent_eq
#print axioms metro_eccent_values
#print axioms metro_radius
#print axioms metro_ediam
#print axioms metro_no_closed_three
