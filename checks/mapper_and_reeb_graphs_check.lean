-- Mapper and Reeb graphs: when neighbouring bands overlap by at least K times the link distance, the Mapper graph has exactly as many connected pieces as the cloud linked at that distance.
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Analysis.Normed.Group.Uniform
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Real.Basic

open SimpleGraph

namespace MapperReeb

variable {ι E : Type*} [PseudoMetricSpace E]


/-- The link network G on the windows: two windows are joined when they lie within ε. -/
def linkGraph (p : ι → E) (ε : ℝ) : SimpleGraph ι :=
  SimpleGraph.fromRel fun a b => dist (p a) (p b) ≤ ε

/-- Band j of width L and overlap O: the half-open interval [j(L - O), j(L - O) + L). -/
def band (L O : ℝ) (j : ℤ) : Set ℝ :=
  Set.Ico ((j : ℝ) * (L - O)) ((j : ℝ) * (L - O) + L)

/-- The windows whose lens value lands in band j, that is f⁻¹(I_j). -/
def inBand (p : ι → E) (f : E → ℝ) (L O : ℝ) (j : ℤ) : Set ι :=
  {i | f (p i) ∈ band L O j}

/-- A node of the Mapper graph: a band j together with one cluster of that band, a connected
piece of the link network restricted to the band's windows. -/
abbrev MapperNode (p : ι → E) (f : E → ℝ) (ε L O : ℝ) : Type _ :=
  Σ j : ℤ, ((linkGraph p ε).induce (inBand p f L O j)).ConnectedComponent

/-- The windows that make up a node. -/
def members (p : ι → E) (f : E → ℝ) (ε L O : ℝ) (u : MapperNode p f ε L O) : Set ι :=
  Subtype.val '' u.2.supp

/-- The Mapper graph M: one node per cluster of every band, and an edge between two different
nodes whenever they share a window. -/
def mapperGraph (p : ι → E) (f : E → ℝ) (ε L O : ℝ) : SimpleGraph (MapperNode p f ε L O) :=
  SimpleGraph.fromRel fun u v => (members p f ε L O u ∩ members p f ε L O v).Nonempty

/-- Helper: a function that agrees on linked vertices agrees on reachable vertices. -/
theorem eq_of_reachable_aux {V β : Type*} {G : SimpleGraph V} (g : V → β)
    (h : ∀ a b, G.Adj a b → g a = g b) {a b : V} (hr : G.Reachable a b) : g a = g b := by
  obtain ⟨w⟩ := hr
  induction w with
  | nil => rfl
  | cons hadj _ ih => exact (h _ _ hadj).trans ih

/-- Helper: a stretch of lens values no longer than the overlap lies inside one band. -/
theorem common_band_aux (L O a b : ℝ) (hOL : O < L) (hab : a ≤ b)
    (hba : b - a ≤ O) : ∃ j : ℤ, a ∈ band L O j ∧ b ∈ band L O j := by
  have hs : 0 < L - O := by linarith
  have hO : 0 ≤ O := by linarith
  refine ⟨⌊a / (L - O)⌋, ⟨?_, ?_⟩, ?_, ?_⟩
  · have := (le_div_iff₀ hs).mp (Int.floor_le (a / (L - O)))
    linarith
  · have := (div_lt_iff₀ hs).mp (Int.lt_floor_add_one (a / (L - O)))
    nlinarith
  · have := (le_div_iff₀ hs).mp (Int.floor_le (a / (L - O)))
    linarith
  · have := (div_lt_iff₀ hs).mp (Int.lt_floor_add_one (a / (L - O)))
    nlinarith

/-- Helper: every real number lies in some band when 0 ≤ O < L. -/
theorem exists_band_aux (L O x : ℝ) (hO : 0 ≤ O) (hOL : O < L) : ∃ j : ℤ, x ∈ band L O j := by
  obtain ⟨j, hj, -⟩ := common_band_aux L O x x hOL le_rfl (by linarith)
  exact ⟨j, hj⟩

/-- **Mapper keeps the pieces.** Take a finite cloud of windows in a metric space, a lens f that
changes by at most K times the distance, a link distance ε, and bands of width L that overlap
by O. If the overlap is at least K times the link distance, then the Mapper graph has exactly
as many separate pieces as the whole cloud linked at ε: β₀(M) = β₀(X linked at ε). -/
theorem mapper_pieces_eq_cloud_pieces [Finite ι] (p : ι → E) (f : E → ℝ) (K : NNReal)
    (hf : LipschitzWith K f) (ε L O : ℝ) (hε : 0 ≤ ε) (hOL : O < L)
    (hO : (K : ℝ) * ε ≤ O) :
    Nat.card (mapperGraph p f ε L O).ConnectedComponent =
      Nat.card (linkGraph p ε).ConnectedComponent := by
  classical
  set G := linkGraph p ε
  set M := mapperGraph p f ε L O
  have hO0 : 0 ≤ O := le_trans (mul_nonneg K.2 hε) hO
  -- every window lies in some band
  have hband : ∀ i : ι, ∃ j : ℤ, i ∈ inBand p f L O j := fun i =>
    exists_band_aux L O (f (p i)) hO0 hOL
  -- a chosen node containing each window
  let nodeOf : ι → MapperNode p f ε L O := fun i =>
    ⟨Classical.choose (hband i),
      ((G.induce (inBand p f L O (Classical.choose (hband i))))).connectedComponentMk
        ⟨i, Classical.choose_spec (hband i)⟩⟩
  have mem_iff : ∀ (u : MapperNode p f ε L O) (i : ι), i ∈ members p f ε L O u ↔
      ∃ h : i ∈ inBand p f L O u.1,
        (G.induce (inBand p f L O u.1)).connectedComponentMk ⟨i, h⟩ = u.2 := by
    intro u i
    constructor
    · rintro ⟨x, hx, rfl⟩
      exact ⟨x.2, hx⟩
    · rintro ⟨h, hx⟩
      exact ⟨⟨i, h⟩, hx, rfl⟩
  have mem_nodeOf : ∀ i, i ∈ members p f ε L O (nodeOf i) := fun i =>
    (mem_iff _ i).2 ⟨Classical.choose_spec (hband i), rfl⟩
  let ψ : ι → M.ConnectedComponent := fun i => M.connectedComponentMk (nodeOf i)
  have key : ∀ u i, i ∈ members p f ε L O u → M.connectedComponentMk u = ψ i := by
    intro u i hi
    by_cases huv : u = nodeOf i
    · rw [huv]
    · apply ConnectedComponent.connectedComponentMk_eq_of_adj
      show (SimpleGraph.fromRel _).Adj _ _
      rw [SimpleGraph.fromRel_adj]
      exact ⟨huv, Or.inl ⟨i, hi, mem_nodeOf i⟩⟩
  have ψadj : ∀ a b, G.Adj a b → ψ a = ψ b := by
    intro a b hab
    have hab' : a ≠ b ∧ (dist (p a) (p b) ≤ ε ∨ dist (p b) (p a) ≤ ε) := by
      simpa [G, linkGraph, SimpleGraph.fromRel_adj] using hab
    have hd : dist (p a) (p b) ≤ ε := by
      rcases hab'.2 with h | h
      · exact h
      · rwa [dist_comm] at h
    have hfd : |f (p a) - f (p b)| ≤ O := by
      have := hf.dist_le_mul (p a) (p b)
      rw [Real.dist_eq] at this
      calc |f (p a) - f (p b)| ≤ K * dist (p a) (p b) := this
        _ ≤ K * ε := mul_le_mul_of_nonneg_left hd K.2
        _ ≤ O := hO
    obtain ⟨j, hja, hjb⟩ : ∃ j : ℤ, a ∈ inBand p f L O j ∧ b ∈ inBand p f L O j := by
      rcases le_total (f (p a)) (f (p b)) with h | h
      · obtain ⟨j, h1, h2⟩ := common_band_aux L O _ _ hOL h
          (by rw [abs_sub_comm, abs_of_nonneg (by linarith)] at hfd; exact hfd)
        exact ⟨j, h1, h2⟩
      · obtain ⟨j, h1, h2⟩ := common_band_aux L O _ _ hOL h
          (by rw [abs_of_nonneg (by linarith)] at hfd; exact hfd)
        exact ⟨j, h2, h1⟩
    let w : MapperNode p f ε L O :=
      ⟨j, (G.induce (inBand p f L O j)).connectedComponentMk ⟨a, hja⟩⟩
    have ha : a ∈ members p f ε L O w := (mem_iff w a).2 ⟨hja, rfl⟩
    have hb : b ∈ members p f ε L O w := by
      refine (mem_iff w b).2 ⟨hjb, ?_⟩
      apply ConnectedComponent.connectedComponentMk_eq_of_adj
      rw [SimpleGraph.induce_adj]
      exact hab.symm
    rw [← key w a ha, ← key w b hb]
  -- the map from Mapper nodes to pieces of the cloud
  let φ : MapperNode p f ε L O → G.ConnectedComponent := fun u =>
    ConnectedComponent.lift (fun x : inBand p f L O u.1 => G.connectedComponentMk x.val)
      (fun v w q _ => eq_of_reachable_aux (G := G.induce (inBand p f L O u.1))
        (fun x : inBand p f L O u.1 => G.connectedComponentMk x.val)
        (fun a b hab => ConnectedComponent.connectedComponentMk_eq_of_adj hab) ⟨q⟩) u.2
  have φmem : ∀ u i, i ∈ members p f ε L O u → φ u = G.connectedComponentMk i := by
    intro u i hi
    obtain ⟨h, hx⟩ := (mem_iff u i).1 hi
    simp only [φ]
    rw [← hx]
    rfl
  have φadj : ∀ u v, M.Adj u v → φ u = φ v := by
    intro u v huv
    have : u ≠ v ∧ ((members p f ε L O u ∩ members p f ε L O v).Nonempty ∨
        (members p f ε L O v ∩ members p f ε L O u).Nonempty) := by
      simpa [M, mapperGraph, SimpleGraph.fromRel_adj] using huv
    rcases this.2 with ⟨i, hu, hv⟩ | ⟨i, hv, hu⟩
    · rw [φmem u i hu, φmem v i hv]
    · rw [φmem u i hu, φmem v i hv]
  let Φ : M.ConnectedComponent → G.ConnectedComponent :=
    ConnectedComponent.lift φ (fun v w q _ => eq_of_reachable_aux φ φadj ⟨q⟩)
  let Ψ : G.ConnectedComponent → M.ConnectedComponent :=
    ConnectedComponent.lift ψ (fun v w q _ => eq_of_reachable_aux ψ ψadj ⟨q⟩)
  have e : M.ConnectedComponent ≃ G.ConnectedComponent :=
    { toFun := Φ
      invFun := Ψ
      left_inv := by
        intro U
        induction U using ConnectedComponent.ind with
        | h u =>
          obtain ⟨x, hx⟩ := u.2.nonempty_supp
          have hxm : x.val ∈ members p f ε L O u := ⟨x, hx, rfl⟩
          show Ψ (φ u) = M.connectedComponentMk u
          rw [φmem u x.val hxm]
          exact (key u x.val hxm).symm
      right_inv := by
        intro C
        induction C using ConnectedComponent.ind with
        | h i =>
          show φ (nodeOf i) = G.connectedComponentMk i
          exact φmem _ i (mem_nodeOf i) }
  exact Nat.card_congr e

/-- **Any stretch of lens values no longer than the overlap lies inside one band.** -/
theorem interval_le_overlap_in_one_band (L O a b : ℝ) (hOL : O < L) (hab : a ≤ b)
    (hba : b - a ≤ O) : ∃ j : ℤ, a ∈ band L O j ∧ b ∈ band L O j := by
  exact common_band_aux L O a b hOL hab hba

/-- **The size lens has K = 1.** Two windows differ in size by at most their distance:
| |x| - |y| | ≤ |x - y|, for windows with any number of coordinates. -/
theorem size_lens_lipschitz_one (n : ℕ) :
    LipschitzWith 1 (fun x : EuclideanSpace ℝ (Fin n) => ‖x‖) := by
  exact lipschitzWith_one_norm

-- Worked numbers, in tenths of a percent. Window 807 = (-24, -21, -21): squared size 1458.
example : (-24 : ℤ) ^ 2 + (-21) ^ 2 + (-21) ^ 2 = 1458 := by norm_num
-- Window 806 = (-20, -22, -18): squared size 1208. Window 805 = (-15, -18, -20): squared size 949.
example : (-20 : ℤ) ^ 2 + (-22) ^ 2 + (-18) ^ 2 = 1208 := by norm_num
example : (-15 : ℤ) ^ 2 + (-18) ^ 2 + (-20) ^ 2 = 949 := by norm_num
-- Squared distances: 805 to 806 is 45 (0.67%), 806 to 807 is 26 (0.51%).
example : (-15 - -20 : ℤ) ^ 2 + (-18 - -22) ^ 2 + (-20 - -18) ^ 2 = 45 := by norm_num
example : (-20 - -24 : ℤ) ^ 2 + (-22 - -21) ^ 2 + (-18 - -21) ^ 2 = 26 := by norm_num
-- Cover A (L = 20, O = 10): band 2 is [20, 40) and band 3 is [30, 50); compared through squares,
-- all three sizes lie in both, [400, 1600) and [900, 2500).
example : ∀ s ∈ ([949, 1208, 1458] : List ℕ), 20 ^ 2 ≤ s ∧ s < 40 ^ 2 ∧ 30 ^ 2 ≤ s ∧ s < 50 ^ 2 := by
  decide
-- The Mapper graph of cover A: edges 0-1, 1-2, 2-3, 2-4, 4-5 on 6 nodes, so
-- loops = edges - nodes + pieces = 5 - 6 + 1 = 0; ends are nodes 0, 3, 5; node 2 has three edges: a Y.
example : let es : List (ℕ × ℕ) := [(0, 1), (1, 2), (2, 3), (2, 4), (4, 5)]
    let deg := fun v => es.countP (fun e => e.1 = v ∨ e.2 = v)
    (es.length : ℤ) - 6 + 1 = 0 ∧ (List.range 6).filter (fun v => deg v = 1) = [0, 3, 5] ∧
      (List.range 6).filter (fun v => 3 ≤ deg v) = [2] := by
  decide

#print axioms eq_of_reachable_aux
#print axioms common_band_aux
#print axioms exists_band_aux
#print axioms mapper_pieces_eq_cloud_pieces
#print axioms interval_le_overlap_in_one_band
#print axioms size_lens_lipschitz_one

end MapperReeb
