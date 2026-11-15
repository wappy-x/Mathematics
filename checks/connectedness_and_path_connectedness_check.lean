-- Connected and path-connected: a space in which any two points are joined by a path is connected, the interval [0, 1] is connected, and the topologist's sine curve is connected yet no path joins its segment to its graph.
import Mathlib.Topology.Connected.PathConnected
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse

open Set

/-- The wavy graph `G`: the points `(x, sin (1/x))` with `0 < x ≤ 1`. -/
def sineGraph : Set (ℝ × ℝ) := {p | 0 < p.1 ∧ p.1 ≤ 1 ∧ p.2 = Real.sin (1 / p.1)}

/-- The upright segment `L`: the points `(0, y)` with `-1 ≤ y ≤ 1`. -/
def sineSegment : Set (ℝ × ℝ) := {p | p.1 = 0 ∧ -1 ≤ p.2 ∧ p.2 ≤ 1}

/-- The topologist's sine curve `S = G ∪ L`, a subset of the plane. -/
def sineCurve : Set (ℝ × ℝ) := sineGraph ∪ sineSegment

/-- Paths imply connected: if any two points of a space are joined by a continuous path
inside it, the space cannot be cut into two disjoint non-empty open sets.
(`PreconnectedSpace` is exactly the card's "no separation"; it makes no non-emptiness demand,
just as the card's definitions do not.) -/
theorem path_connected_implies_connected (X : Type*) [TopologicalSpace X]
    (h : ∀ p q : X, Joined p q) : PreconnectedSpace X := by
  refine ⟨?_⟩
  apply isPreconnected_of_forall_pair
  intro x _ y _
  obtain ⟨γ⟩ := h x y
  exact ⟨range γ, subset_univ _, ⟨0, γ.source⟩, ⟨1, γ.target⟩,
    (isConnected_range γ.continuous).isPreconnected⟩

/-- The interval `[0, 1]` of real numbers is connected. -/
theorem unit_interval_is_connected : IsConnected (Icc (0 : ℝ) 1) := by
  exact isConnected_Icc zero_le_one

/-- The topologist's sine curve is connected, but no path inside it runs from any point
of its segment to any point of its graph; so it is not path-connected. -/
theorem sine_curve_connected_not_path_connected :
    IsConnected sineCurve ∧
      ∀ p ∈ sineSegment, ∀ q ∈ sineGraph, ¬ JoinedIn sineCurve p q := by
  refine ⟨?_, ?_⟩
  · -- the graph is connected, and the curve lies between the graph and its closure
    have hG : sineGraph = (fun x : ℝ => (x, Real.sin (1 / x))) '' Ioc 0 1 := by
      ext ⟨a, b⟩
      simp only [sineGraph, mem_image, mem_Ioc, Prod.mk.injEq]
      constructor
      · rintro ⟨h1, h2, h3⟩
        exact ⟨a, ⟨h1, h2⟩, rfl, h3.symm⟩
      · rintro ⟨x, ⟨h1, h2⟩, rfl, rfl⟩
        exact ⟨h1, h2, rfl⟩
    have hGc : IsConnected sineGraph := by
      rw [hG]
      refine (isConnected_Ioc zero_lt_one).image _ ?_
      intro x hx
      have hx0 : x ≠ 0 := ne_of_gt hx.1
      exact (continuousAt_id.prodMk
        ((Real.continuous_sin.continuousAt).comp
          (continuousAt_const.div continuousAt_id hx0))).continuousWithinAt
    refine hGc.subset_closure subset_union_left ?_
    rintro ⟨a, b⟩ (hp | ⟨ha, hb1, hb2⟩)
    · exact subset_closure hp
    · simp only at ha hb1 hb2
      subst ha
      set t := Real.arcsin b with ht
      have hsin : Real.sin t = b := Real.sin_arcsin hb1 hb2
      have htlo : -(Real.pi / 2) ≤ t := Real.neg_pi_div_two_le_arcsin b
      have hpi : 2 ≤ Real.pi := Real.two_le_pi
      let u : ℕ → ℝ := fun n => t + ((n : ℝ) + 1) * (2 * Real.pi)
      have hu_pos : ∀ n : ℕ, 1 < u n := by
        intro n
        have : (0 : ℝ) ≤ n := Nat.cast_nonneg n
        simp only [u]
        nlinarith
      have hu_tend : Filter.Tendsto u Filter.atTop Filter.atTop := by
        apply Filter.tendsto_atTop_add_const_left
        apply Filter.Tendsto.atTop_mul_const (by positivity)
        exact Filter.tendsto_atTop_add_const_right _ 1 tendsto_natCast_atTop_atTop
      have hlim : Filter.Tendsto (fun n => ((u n)⁻¹, b)) Filter.atTop (nhds ((0 : ℝ), b)) :=
        (tendsto_inv_atTop_zero.comp hu_tend).prodMk_nhds tendsto_const_nhds
      apply mem_closure_of_tendsto hlim
      refine Filter.Eventually.of_forall (fun n => ?_)
      have h1 := hu_pos n
      refine ⟨by positivity, ?_, ?_⟩
      · exact inv_le_one_of_one_le₀ h1.le
      · simp only [one_div, inv_inv, u]
        rw [show ((n : ℝ) + 1) = ((n + 1 : ℕ) : ℝ) by push_cast; ring,
          Real.sin_add_nat_mul_two_pi, hsin]
  · rintro p hp q hq ⟨γ, hγ⟩
    have hpi : 2 ≤ Real.pi := Real.two_le_pi
    let f : ℝ → ℝ × ℝ := γ.extend
    have hf : Continuous f := γ.continuous_extend
    have hfS : ∀ s, f s ∈ sineCurve := fun s => hγ _
    -- a point of the curve with positive first coordinate lies on the graph
    have hgraph : ∀ s, 0 < (f s).1 → (f s).2 = Real.sin (1 / (f s).1) := by
      intro s hs
      rcases hfS s with h | h
      · exact h.2.2
      · exact absurd h.1 (ne_of_gt hs)
    -- every point of the curve has first coordinate ≥ 0
    have hnonneg : ∀ s, 0 ≤ (f s).1 := by
      intro s
      rcases hfS s with h | h
      · exact h.1.le
      · exact h.1.ge
    let A : Set ℝ := {s | (f s).1 = 0}
    have hAclosed : IsClosed A := isClosed_eq (continuous_fst.comp hf) continuous_const
    have hAopen : IsOpen A := by
      rw [Metric.isOpen_iff]
      intro s0 hs0
      have hg : Continuous (fun s => (f s).2) := continuous_snd.comp hf
      obtain ⟨δ, hδ, hδg⟩ := Metric.continuous_iff.1 hg s0 (1 / 2) (by norm_num)
      refine ⟨δ, hδ, fun s hs => ?_⟩
      by_contra hne
      have ha : 0 < (f s).1 := lt_of_le_of_ne (hnonneg s) (Ne.symm hne)
      set a := (f s).1 with ha_def
      -- the first coordinate takes every value in [0, a] between s0 and s
      have hivt := intermediate_value_uIcc
        (a := s0) (b := s) (f := fun s => (f s).1)
        ((continuous_fst.comp hf).continuousOn)
      have hs0' : (f s0).1 = 0 := hs0
      obtain ⟨n, hn⟩ := exists_nat_gt (1 / a)
      have hn0 : (0 : ℝ) ≤ n := Nat.cast_nonneg n
      have h1a : 0 < 1 / a := by positivity
      -- the value where sin (1/x) = 1, and the value where sin (1/x) = -1
      have key : ∀ c : ℝ, -(Real.pi / 2) ≤ c →
          ∃ s1 ∈ uIcc s0 s, (f s1).2 = Real.sin c := by
        intro c hc
        set w := c + ((n : ℝ) + 1) * (2 * Real.pi) with hw
        have hw1 : 1 / a < w := by nlinarith
        have hwpos : 0 < w := lt_trans h1a hw1
        have hx : 1 / w ∈ uIcc (f s0).1 (f s).1 := by
          rw [hs0', uIcc_of_le ha.le]
          refine ⟨by positivity, ?_⟩
          rw [div_le_iff₀ hwpos]
          rw [div_lt_iff₀ ha] at hw1
          linarith
        obtain ⟨s1, hs1, hs1x⟩ := hivt hx
        refine ⟨s1, hs1, ?_⟩
        simp only at hs1x
        rw [hgraph s1 (by rw [hs1x]; positivity), hs1x, one_div_one_div, hw,
          show ((n : ℝ) + 1) = ((n + 1 : ℕ) : ℝ) by push_cast; ring,
          Real.sin_add_nat_mul_two_pi]
      obtain ⟨s1, hs1, h1⟩ := key (Real.pi / 2) (by linarith)
      obtain ⟨s2, hs2, h2⟩ := key (-(Real.pi / 2)) le_rfl
      rw [Real.sin_pi_div_two] at h1
      rw [Real.sin_neg, Real.sin_pi_div_two] at h2
      have hd : ∀ r ∈ uIcc s0 s, dist r s0 < δ := by
        intro r hr
        rw [Real.dist_eq]
        have := abs_sub_left_of_mem_uIcc hr
        rw [Metric.mem_ball, Real.dist_eq] at hs
        linarith
      have e1 := hδg s1 (hd s1 hs1)
      have e2 := hδg s2 (hd s2 hs2)
      simp only [Real.dist_eq] at e1 e2
      rw [h1] at e1
      rw [h2] at e2
      have := abs_lt.1 e1
      have := abs_lt.1 e2
      linarith
    have hA0 : (0 : ℝ) ∈ A := by
      show (γ.extend 0).1 = 0
      rw [γ.extend_zero]
      exact hp.1
    have hA : A = univ := (IsClopen.eq_univ ⟨hAclosed, hAopen⟩ ⟨0, hA0⟩)
    have hA1 : (1 : ℝ) ∈ A := hA ▸ mem_univ _
    have : (γ.extend 1).1 = 0 := hA1
    rw [γ.extend_one] at this
    exact absurd this (ne_of_gt hq.1)

-- Step 1's halving: after 30 halvings the seam 1/√2 lies between 759250124/2^30 and
-- 759250125/2^30, i.e. 2·a² < 4^30 ≤ 2·(a+1)² for a = 759250124.
example : 2 * 759250124 ^ 2 < 4 ^ 30 ∧ 4 ^ 30 ≤ 2 * 759250125 ^ 2 := by norm_num
example : 2 * 724 ^ 2 < 4 ^ 10 ∧ 4 ^ 10 ≤ 2 * 725 ^ 2 := by norm_num
example : 2 * 741455 ^ 2 < 4 ^ 20 ∧ 4 ^ 20 ≤ 2 * 741456 ^ 2 := by norm_num

#print axioms path_connected_implies_connected
#print axioms unit_interval_is_connected
#print axioms sine_curve_connected_not_path_connected
