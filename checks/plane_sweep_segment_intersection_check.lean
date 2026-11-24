-- Sweeping a line across the plane: two segments that cross are next-door in the up-down order on a vertical sweep line just before they cross, two segments only swap order by crossing, and the card's four crossings and pair counts are exact.
import Mathlib.Analysis.Convex.Segment
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Analysis.Normed.Module.Convex
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.FunProp

open Set

/-- A closed segment in the plane is a closed set. -/
theorem planeSweep_isClosed_segment (p q : ℝ × ℝ) : IsClosed (segment ℝ p q) := by
  rw [segment_eq_image']
  exact (isCompact_Icc.image (by fun_prop)).isClosed

/-- A non-vertical segment meets each vertical line in at most one point. -/
theorem planeSweep_segment_y_unique {p q : ℝ × ℝ} (hpq : p.1 ≠ q.1) {x y₁ y₂ : ℝ}
    (h₁ : (x, y₁) ∈ segment ℝ p q) (h₂ : (x, y₂) ∈ segment ℝ p q) : y₁ = y₂ := by
  rw [segment_eq_image'] at h₁ h₂
  obtain ⟨t₁, -, e₁⟩ := h₁
  obtain ⟨t₂, -, e₂⟩ := h₂
  simp only [Prod.ext_iff, Prod.fst_add, Prod.snd_add, Prod.smul_fst, Prod.smul_snd,
    Prod.fst_sub, Prod.snd_sub, smul_eq_mul] at e₁ e₂
  have hd : q.1 - p.1 ≠ 0 := sub_ne_zero.2 (Ne.symm hpq)
  have ht : t₁ = t₂ := mul_right_cancel₀ hd (by linarith [e₁.1, e₂.1])
  subst ht
  linarith [e₁.2, e₂.2]

/-- Near the x of an inside point P of a non-vertical segment, each vertical line cuts the
segment at a height within ε of P's height. -/
theorem planeSweep_eventually_on_segment {p q P : ℝ × ℝ} (hpq : p.1 ≠ q.1)
    (hP : P ∈ openSegment ℝ p q) {ε : ℝ} (hε : 0 < ε) :
    ∀ᶠ x in nhds P.1, ∃ y, (x, y) ∈ segment ℝ p q ∧ |y - P.2| < ε := by
  rw [openSegment_eq_image'] at hP
  obtain ⟨t₀, ht₀, hP⟩ := hP
  have hd : q.1 - p.1 ≠ 0 := sub_ne_zero.2 (Ne.symm hpq)
  set τ : ℝ → ℝ := fun x => t₀ + (x - P.1) / (q.1 - p.1) with hτ
  set g : ℝ → ℝ × ℝ := fun x => p + τ x • (q - p) with hg
  have hτc : Continuous τ := by rw [hτ]; fun_prop
  have hgc : Continuous g := by rw [hg]; fun_prop
  have hτP : τ P.1 = t₀ := by simp [hτ]
  have hgP : g P.1 = P := by simp only [hg, hτP]; exact hP
  have hP1 : P.1 = p.1 + t₀ * (q.1 - p.1) := by
    rw [← hP]; simp
  have h1 : ∀ᶠ x in nhds P.1, τ x ∈ Ioo (0 : ℝ) 1 := by
    have := hτc.continuousAt (x := P.1)
    rw [ContinuousAt, hτP] at this
    exact this (isOpen_Ioo.mem_nhds ht₀)
  have h2 : ∀ᶠ x in nhds P.1, g x ∈ Metric.ball P ε := by
    have := hgc.continuousAt (x := P.1)
    rw [ContinuousAt, hgP] at this
    exact this (Metric.ball_mem_nhds P hε)
  filter_upwards [h1, h2] with x hx1 hx2
  refine ⟨(g x).2, ?_, ?_⟩
  · have hfst : (g x).1 = x := by
      simp only [hg, hτ, Prod.fst_add, Prod.smul_fst, Prod.fst_sub, smul_eq_mul]
      field_simp
      linarith
    have : (x, (g x).2) = g x := Prod.ext hfst.symm rfl
    rw [this, segment_eq_image']
    exact ⟨τ x, Ioo_subset_Icc_self hx1, rfl⟩
  · rw [Metric.mem_ball, Prod.dist_eq] at hx2
    have := lt_of_le_of_lt (le_max_right _ _) hx2
    rwa [Real.dist_eq] at this

#print axioms planeSweep_isClosed_segment
#print axioms planeSweep_segment_y_unique
#print axioms planeSweep_eventually_on_segment

/-- Step 0, the key fact behind the sweep. Take a finite family of straight segments in
general position: no segment is vertical, no two event points (segment ends and crossing
points) share an x, no three segments pass through one point, and no two overlap along a
line. If segments A and B cross at a point P, then just left of P the vertical sweep line
cuts both A and B, and no segment C is cut by that line strictly between them: A and B are
next-door in the up-down order. A segment is given by its two end points, and two segments
cross at P when P lies inside both (not at an end). -/
theorem crossing_segments_are_next_door_before_crossing
    {ι : Type*} [Finite ι] (seg : ι → (ℝ × ℝ) × (ℝ × ℝ))
    -- no segment is vertical
    (h_not_vertical : ∀ i, (seg i).1.1 ≠ (seg i).2.1)
    -- no two event points share an x; event points are the ends and the crossing points
    (h_events : ∀ E F : ℝ × ℝ,
      ((∃ i, E = (seg i).1 ∨ E = (seg i).2) ∨
        (∃ i j, i ≠ j ∧ E ∈ openSegment ℝ (seg i).1 (seg i).2 ∧
          E ∈ openSegment ℝ (seg j).1 (seg j).2)) →
      ((∃ i, F = (seg i).1 ∨ F = (seg i).2) ∨
        (∃ i j, i ≠ j ∧ F ∈ openSegment ℝ (seg i).1 (seg i).2 ∧
          F ∈ openSegment ℝ (seg j).1 (seg j).2)) →
      E.1 = F.1 → E = F)
    -- no three segments through one point
    (h_no_triple : ∀ i j k (Q : ℝ × ℝ), i ≠ j → j ≠ k → i ≠ k →
      Q ∈ segment ℝ (seg i).1 (seg i).2 → Q ∈ segment ℝ (seg j).1 (seg j).2 →
      Q ∉ segment ℝ (seg k).1 (seg k).2)
    -- no two segments overlap along a line
    (h_no_overlap : ∀ i j, i ≠ j →
      (segment ℝ (seg i).1 (seg i).2 ∩ segment ℝ (seg j).1 (seg j).2).Subsingleton)
    (a b : ι) (hab : a ≠ b) (P : ℝ × ℝ)
    (hPa : P ∈ openSegment ℝ (seg a).1 (seg a).2)
    (hPb : P ∈ openSegment ℝ (seg b).1 (seg b).2) :
    ∃ x₀ < P.1, ∀ x ∈ Ioo x₀ P.1,
      (∃ ya, (x, ya) ∈ segment ℝ (seg a).1 (seg a).2) ∧
      (∃ yb, (x, yb) ∈ segment ℝ (seg b).1 (seg b).2) ∧
      ∀ c (ya yb yc : ℝ), (x, ya) ∈ segment ℝ (seg a).1 (seg a).2 →
        (x, yb) ∈ segment ℝ (seg b).1 (seg b).2 → (x, yc) ∈ segment ℝ (seg c).1 (seg c).2 →
        ¬ (min ya yb < yc ∧ yc < max ya yb) := by
  have ha := h_not_vertical a
  have hb := h_not_vertical b
  -- every other segment misses P, so a whole ball around P misses them
  have hU : ∀ᶠ z in nhds P, ∀ c, c ≠ a → c ≠ b → z ∉ segment ℝ (seg c).1 (seg c).2 := by
    refine Filter.eventually_all.2 fun c => ?_
    by_cases hc : c ≠ a ∧ c ≠ b
    · have hPc : P ∉ segment ℝ (seg c).1 (seg c).2 :=
        h_no_triple a b c P hab (Ne.symm hc.2) (Ne.symm hc.1)
          (openSegment_subset_segment ℝ _ _ hPa) (openSegment_subset_segment ℝ _ _ hPb)
      filter_upwards [(planeSweep_isClosed_segment _ _).isOpen_compl.mem_nhds hPc] with z hz
      exact fun _ _ => hz
    · exact Filter.Eventually.of_forall fun z h1 h2 => absurd ⟨h1, h2⟩ hc
  obtain ⟨ε, hε, hball⟩ := Metric.eventually_nhds_iff.1 hU
  have hev : ∀ᶠ x in nhds P.1,
      (∃ y, (x, y) ∈ segment ℝ (seg a).1 (seg a).2 ∧ |y - P.2| < ε) ∧
      (∃ y, (x, y) ∈ segment ℝ (seg b).1 (seg b).2 ∧ |y - P.2| < ε) ∧
      dist x P.1 < ε := by
    filter_upwards [planeSweep_eventually_on_segment ha hPa hε,
      planeSweep_eventually_on_segment hb hPb hε, Metric.ball_mem_nhds P.1 hε]
      with x h1 h2 h3
    exact ⟨h1, h2, h3⟩
  obtain ⟨δ, hδ, hδx⟩ := Metric.eventually_nhds_iff.1 hev
  refine ⟨P.1 - δ, by linarith, fun x hx => ?_⟩
  have hxd : dist x P.1 < δ := by
    rw [Real.dist_eq, abs_sub_lt_iff]
    constructor <;> linarith [hx.1, hx.2]
  obtain ⟨⟨ya', hya', hya'ε⟩, ⟨yb', hyb', hyb'ε⟩, hxε⟩ := hδx hxd
  refine ⟨⟨ya', hya'⟩, ⟨yb', hyb'⟩, ?_⟩
  intro c ya yb yc hya hyb hyc hbetw
  have e1 : ya = ya' := planeSweep_segment_y_unique ha hya hya'
  have e2 : yb = yb' := planeSweep_segment_y_unique hb hyb hyb'
  subst e1 e2
  obtain ⟨hlo, hhi⟩ := hbetw
  rw [min_lt_iff] at hlo
  rw [lt_max_iff] at hhi
  by_cases hca : c = a
  · subst hca
    have := planeSweep_segment_y_unique ha hyc hya
    subst this
    rcases hlo with h | h <;> rcases hhi with h' | h' <;> linarith
  by_cases hcb : c = b
  · subst hcb
    have := planeSweep_segment_y_unique hb hyc hyb
    subst this
    rcases hlo with h | h <;> rcases hhi with h' | h' <;> linarith
  have hyε : |yc - P.2| < ε := by
    rw [abs_lt] at hya'ε hyb'ε ⊢
    constructor <;> rcases hlo with h | h <;> rcases hhi with h' | h' <;> linarith
  have hdist : dist (x, yc) P < ε := by
    rw [Prod.dist_eq]
    exact max_lt hxε (by rw [Real.dist_eq]; exact hyε)
  exact hball hdist c hca hcb hyc

/-- Step 1: the up-down order changes only at a crossing. If the sweep line at x₁ cuts
segment A below segment B, and the sweep line at a later x₂ cuts A above B, then A and B
meet at a point strictly between the two sweep lines. -/
theorem order_changes_only_at_crossings (p q r s : ℝ × ℝ) {x₁ x₂ ya₁ yb₁ ya₂ yb₂ : ℝ}
    (hx : x₁ < x₂)
    (ha₁ : (x₁, ya₁) ∈ segment ℝ p q) (hb₁ : (x₁, yb₁) ∈ segment ℝ r s)
    (ha₂ : (x₂, ya₂) ∈ segment ℝ p q) (hb₂ : (x₂, yb₂) ∈ segment ℝ r s)
    (h₁ : ya₁ < yb₁) (h₂ : yb₂ < ya₂) :
    ∃ P ∈ segment ℝ p q ∩ segment ℝ r s, x₁ < P.1 ∧ P.1 < x₂ := by
  obtain ⟨u, hu, hu'⟩ : ∃ u, 0 < u ∧ u = yb₁ - ya₁ := ⟨_, by linarith, rfl⟩
  obtain ⟨v, hv, hv'⟩ : ∃ v, 0 < v ∧ v = ya₂ - yb₂ := ⟨_, by linarith, rfl⟩
  set l : ℝ := u / (u + v) with hl
  have huv : 0 < u + v := by linarith
  have hl0 : 0 < l := div_pos hu huv
  have hl1 : l < 1 := (div_lt_one huv).2 (by linarith)
  have hsubA : segment ℝ (x₁, ya₁) (x₂, ya₂) ⊆ segment ℝ p q :=
    (convex_segment p q).segment_subset ha₁ ha₂
  have hsubB : segment ℝ (x₁, yb₁) (x₂, yb₂) ⊆ segment ℝ r s :=
    (convex_segment r s).segment_subset hb₁ hb₂
  have hy : (1 - l) * ya₁ + l * ya₂ = (1 - l) * yb₁ + l * yb₂ := by
    have : (1 - l) * (ya₁ - yb₁) + l * (ya₂ - yb₂) = 0 := by
      rw [hl]; field_simp; rw [hu', hv']; ring
    linarith
  refine ⟨((1 - l) * x₁ + l * x₂, (1 - l) * ya₁ + l * ya₂), ⟨hsubA ?_, hsubB ?_⟩, ?_, ?_⟩
  · exact ⟨1 - l, l, by linarith, hl0.le, by ring, by ext <;> simp⟩
  · refine ⟨1 - l, l, by linarith, hl0.le, by ring, ?_⟩
    ext <;> simp [hy]
  · show x₁ < (1 - l) * x₁ + l * x₂
    nlinarith
  · show (1 - l) * x₁ + l * x₂ < x₂
    nlinarith

/-- Testing every pair of n segments means n(n - 1)/2 tests: that is the number of
two-segment sets. -/
theorem number_of_pairs (ι : Type*) [Fintype ι] [DecidableEq ι] :
    ((Finset.univ : Finset ι).powersetCard 2).card =
      Fintype.card ι * (Fintype.card ι - 1) / 2 := by
  rw [Finset.card_powersetCard, Finset.card_univ, Nat.choose_two_right]

-- The four crossings of the worked example, each strictly inside both tracks.
-- S1 (0, 0)-(6, 4), S2 (0, 4)-(6, 0), S3 (1, 3)-(5, 3), S4 (5, 0)-(6, 1).
-- S2 and S3 meet at (1.5, 3)
example : ((3 / 2 : ℝ), (3 : ℝ)) ∈ openSegment ℝ ((0 : ℝ), (4 : ℝ)) ((6 : ℝ), (0 : ℝ)) ∧
    ((3 / 2 : ℝ), (3 : ℝ)) ∈ openSegment ℝ ((1 : ℝ), (3 : ℝ)) ((5 : ℝ), (3 : ℝ)) :=
  ⟨⟨3 / 4, 1 / 4, by norm_num, by norm_num, by norm_num, by ext <;> norm_num⟩,
   ⟨7 / 8, 1 / 8, by norm_num, by norm_num, by norm_num, by ext <;> norm_num⟩⟩
-- S1 and S2 meet at (3, 2)
example : ((3 : ℝ), (2 : ℝ)) ∈ openSegment ℝ ((0 : ℝ), (0 : ℝ)) ((6 : ℝ), (4 : ℝ)) ∧
    ((3 : ℝ), (2 : ℝ)) ∈ openSegment ℝ ((0 : ℝ), (4 : ℝ)) ((6 : ℝ), (0 : ℝ)) :=
  ⟨⟨1 / 2, 1 / 2, by norm_num, by norm_num, by norm_num, by ext <;> norm_num⟩,
   ⟨1 / 2, 1 / 2, by norm_num, by norm_num, by norm_num, by ext <;> norm_num⟩⟩
-- S1 and S3 meet at (4.5, 3)
example : ((9 / 2 : ℝ), (3 : ℝ)) ∈ openSegment ℝ ((0 : ℝ), (0 : ℝ)) ((6 : ℝ), (4 : ℝ)) ∧
    ((9 / 2 : ℝ), (3 : ℝ)) ∈ openSegment ℝ ((1 : ℝ), (3 : ℝ)) ((5 : ℝ), (3 : ℝ)) :=
  ⟨⟨1 / 4, 3 / 4, by norm_num, by norm_num, by norm_num, by ext <;> norm_num⟩,
   ⟨1 / 8, 7 / 8, by norm_num, by norm_num, by norm_num, by ext <;> norm_num⟩⟩
-- S2 and S4 meet at (5.4, 0.4) = (27/5, 2/5)
example : ((27 / 5 : ℝ), (2 / 5 : ℝ)) ∈ openSegment ℝ ((0 : ℝ), (4 : ℝ)) ((6 : ℝ), (0 : ℝ)) ∧
    ((27 / 5 : ℝ), (2 / 5 : ℝ)) ∈ openSegment ℝ ((5 : ℝ), (0 : ℝ)) ((6 : ℝ), (1 : ℝ)) :=
  ⟨⟨1 / 10, 9 / 10, by norm_num, by norm_num, by norm_num, by ext <;> norm_num⟩,
   ⟨3 / 5, 2 / 5, by norm_num, by norm_num, by norm_num, by ext <;> norm_num⟩⟩

-- Pair counts: 4 tracks make 6 pairs, 1,000 tracks make 499,500.
example : Nat.choose 4 2 = 6 := by decide
example : Nat.choose 1000 2 = 499500 := by norm_num [Nat.choose_two_right]
example : 1000 * (1000 - 1) / 2 = 499500 := by norm_num
-- Events on the big board: 2n + k = 2 * 1000 + 186 = 2186.
example : 2 * 1000 + 186 = 2186 := by norm_num

#print axioms crossing_segments_are_next_door_before_crossing
#print axioms order_changes_only_at_crossings
#print axioms number_of_pairs
