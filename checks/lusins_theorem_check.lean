-- Lusin's theorem: a measurable function on [a, b] that is finite almost everywhere is continuous on a closed set missing less than ε of the interval and agrees there with a continuous function no larger in size, and so continuous functions with compact support are dense in L¹.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Topology.Algebra.Support
import Mathlib.Data.Nat.Totient
import Mathlib.MeasureTheory.Measure.Regular
import Mathlib.MeasureTheory.Function.ContinuousMapDense
import Mathlib.Topology.TietzeExtension
import Mathlib.Analysis.SpecificLimits.Basic

open MeasureTheory Set

theorem lusin_aux_closed_pair (ν : Measure ℝ) [IsFiniteMeasure ν] {S : Set ℝ}
    (hS : MeasurableSet S) {δ : ENNReal} (hδ : δ ≠ 0) :
    ∃ K K' : Set ℝ, IsClosed K ∧ IsClosed K' ∧ K ⊆ S ∧ K' ⊆ Sᶜ ∧ ν (K ∪ K')ᶜ < δ := by
  have hδ2 : δ / 2 ≠ 0 := by simp [hδ]
  obtain ⟨K, hKS, hKc, hK⟩ := hS.exists_isClosed_sdiff_lt (measure_ne_top ν S) hδ2
  obtain ⟨K', hKS', hKc', hK'⟩ := hS.compl.exists_isClosed_sdiff_lt (measure_ne_top ν _) hδ2
  refine ⟨K, K', hKc, hKc', hKS, hKS', ?_⟩
  have hsub : (K ∪ K')ᶜ ⊆ (S \ K) ∪ (Sᶜ \ K') := by
    intro x hx
    simp only [mem_compl_iff, mem_union, not_or] at hx
    by_cases h : x ∈ S
    · exact Or.inl ⟨h, hx.1⟩
    · exact Or.inr ⟨h, hx.2⟩
  calc ν (K ∪ K')ᶜ ≤ ν ((S \ K) ∪ (Sᶜ \ K')) := measure_mono hsub
    _ ≤ ν (S \ K) + ν (Sᶜ \ K') := measure_union_le _ _
    _ < δ / 2 + δ / 2 := ENNReal.add_lt_add hK hK'
    _ = δ := ENNReal.add_halves δ
#print axioms lusin_aux_closed_pair

theorem lusin_aux_countable {ι : Type*} [Countable ι] (ν : Measure ℝ) [IsFiniteMeasure ν]
    (S : ι → Set ℝ) (hS : ∀ i, MeasurableSet (S i)) {δ : ENNReal} (hδ : δ ≠ 0) :
    ∃ F : Set ℝ, IsClosed F ∧ ν Fᶜ < δ ∧ ∀ i, ∃ O : Set ℝ, IsOpen O ∧ S i ∩ F = O ∩ F := by
  obtain ⟨δ', hδ'pos, hδ'sum⟩ := ENNReal.exists_pos_sum_of_countable' hδ ι
  choose K K' hK hK' hKS hKS' hKν using
    fun i => lusin_aux_closed_pair ν (hS i) (hδ'pos i).ne'
  refine ⟨⋂ i, (K i ∪ K' i), isClosed_iInter fun i => (hK i).union (hK' i), ?_, ?_⟩
  · rw [compl_iInter]
    calc ν (⋃ i, (K i ∪ K' i)ᶜ) ≤ ∑' i, ν (K i ∪ K' i)ᶜ := measure_iUnion_le _
      _ ≤ ∑' i, δ' i := tsum_le_tsum fun i => (hKν i).le
      _ < δ := hδ'sum
  · intro i
    refine ⟨(K' i)ᶜ, (hK' i).isOpen_compl, ?_⟩
    ext x
    simp only [mem_inter_iff, mem_compl_iff, mem_iInter, mem_union]
    constructor
    · rintro ⟨hx, hF⟩
      exact ⟨fun h => hKS' i h hx, hF⟩
    · rintro ⟨hx, hF⟩
      refine ⟨?_, hF⟩
      rcases hF i with h | h
      · exact hKS i h
      · exact absurd h hx
#print axioms lusin_aux_countable

theorem lusin_aux_real (ν : Measure ℝ) [IsFiniteMeasure ν] {h : ℝ → ℝ} (hh : Measurable h)
    {δ : ENNReal} (hδ : δ ≠ 0) :
    ∃ F : Set ℝ, IsClosed F ∧ ν Fᶜ < δ ∧ ContinuousOn h F := by
  let S : ℚ ⊕ ℚ → Set ℝ := fun i => match i with
    | Sum.inl q => h ⁻¹' Iio (q : ℝ)
    | Sum.inr q => h ⁻¹' Ioi (q : ℝ)
  have hS : ∀ i, MeasurableSet (S i) := by
    rintro (q | q)
    · exact hh measurableSet_Iio
    · exact hh measurableSet_Ioi
  obtain ⟨F, hFc, hFν, hO⟩ := lusin_aux_countable ν S hS hδ
  refine ⟨F, hFc, hFν, ?_⟩
  intro x hx
  rw [ContinuousWithinAt, tendsto_order]
  constructor
  · intro c hc
    obtain ⟨q, hcq, hqx⟩ := exists_rat_btwn hc
    obtain ⟨O, hOo, hOeq⟩ := hO (Sum.inr q)
    have hxO : x ∈ O ∩ F := hOeq ▸ ⟨(show q < h x from hqx), hx⟩
    filter_upwards [inter_mem_nhdsWithin F (hOo.mem_nhds hxO.1), self_mem_nhdsWithin] with y hy hyF
    have : y ∈ S (Sum.inr q) ∩ F := hOeq ▸ ⟨hy.2, hyF⟩
    exact lt_trans hcq this.1
  · intro c hc
    obtain ⟨q, hxq, hqc⟩ := exists_rat_btwn hc
    obtain ⟨O, hOo, hOeq⟩ := hO (Sum.inl q)
    have hxO : x ∈ O ∩ F := hOeq ▸ ⟨(show h x < q from hxq), hx⟩
    filter_upwards [inter_mem_nhdsWithin F (hOo.mem_nhds hxO.1), self_mem_nhdsWithin] with y hy hyF
    have : y ∈ S (Sum.inl q) ∩ F := hOeq ▸ ⟨hy.2, hyF⟩
    exact lt_trans this.1 hqc
#print axioms lusin_aux_real

/-- Lusin's theorem. Let `f` be a (Lebesgue) measurable function on `[a, b]` with values in the
extended reals, finite almost everywhere, and let `ε > 0`. Then there is a closed set
`F ⊆ [a, b]` with `λ([a, b] \ F) < ε` on which `f` is continuous, and a function `g` continuous on
`[a, b]` that equals `f` on `F` and is never larger in size than `f` is on `F`
(every bound `M ≥ 0` for `|f|` on `F` also bounds `|g|` on all of `[a, b]`, i.e.
`sup_[a,b] |g| ≤ sup_F |f|`). -/
theorem lusin_measurable_continuous_off_small_set (a b : ℝ) (f : ℝ → EReal)
    (hf : AEMeasurable f (volume.restrict (Icc a b)))
    (hfin : ∀ᵐ x ∂(volume.restrict (Icc a b)), f x ≠ ⊤ ∧ f x ≠ ⊥)
    (ε : ℝ) (hε : 0 < ε) :
    ∃ F : Set ℝ, IsClosed F ∧ F ⊆ Icc a b ∧
      volume (Icc a b \ F) < ENNReal.ofReal ε ∧ ContinuousOn f F ∧
      ∃ g : ℝ → ℝ, ContinuousOn g (Icc a b) ∧ (∀ x ∈ F, (g x : EReal) = f x) ∧
        ∀ M : ℝ, 0 ≤ M → (∀ y ∈ F, |g y| ≤ M) → ∀ x ∈ Icc a b, |g x| ≤ M := by
  set ν := volume.restrict (Icc a b) with hν
  have hεpos : ENNReal.ofReal ε ≠ 0 := by simpa using hε
  have hδ : ENNReal.ofReal ε / 2 ≠ 0 := by simp [hεpos]
  obtain ⟨f', hf'm, hff'⟩ := hf
  have hgood : ∀ᵐ x ∂ν, f x = f' x ∧ f x ≠ ⊤ ∧ f x ≠ ⊥ := by
    filter_upwards [hff', hfin] with x h1 h2 using ⟨h1, h2⟩
  set N := toMeasurable ν {x | ¬ (f x = f' x ∧ f x ≠ ⊤ ∧ f x ≠ ⊥)} with hNdef
  have hNm : MeasurableSet N := measurableSet_toMeasurable _ _
  have hN0 : ν N = 0 := by rw [hNdef, measure_toMeasurable]; exact ae_iff.1 hgood
  have hNsub : Nᶜ ⊆ {x | f x = f' x ∧ f x ≠ ⊤ ∧ f x ≠ ⊥} := by
    intro x hx
    by_contra hc
    exact hx (subset_toMeasurable _ _ hc)
  obtain ⟨h, hh, hhdef⟩ : ∃ h : ℝ → ℝ, Measurable h ∧ ∀ x, h x = (f' x).toReal :=
    ⟨_, measurable_ereal_toReal.comp hf'm, fun _ => rfl⟩
  obtain ⟨F1, hF1c, hF1ν, hF1cont⟩ := lusin_aux_real ν hh hδ
  obtain ⟨F2, hF2N, hF2c, hF2ν⟩ := hNm.compl.exists_isClosed_sdiff_lt (measure_ne_top ν _) hδ
  have hFc : IsClosed (F1 ∩ F2 ∩ Icc a b) := (hF1c.inter hF2c).inter isClosed_Icc
  set F := F1 ∩ F2 ∩ Icc a b with hFdef
  have hFsub : F ⊆ Icc a b := inter_subset_right
  have hFF1 : F ⊆ F1 := fun x hx => hx.1.1
  have hfF : ∀ x ∈ F, f x = ((h x : ℝ) : EReal) := by
    intro x hx
    obtain ⟨h1, h2, h3⟩ := hNsub (hF2N hx.1.2)
    rw [hhdef, ← h1]
    exact (EReal.coe_toReal h2 h3).symm
  have hI : ν (Icc a b)ᶜ = 0 := by
    rw [hν, Measure.restrict_apply measurableSet_Icc.compl, compl_inter_self, measure_empty]
  have hvol : volume (Icc a b \ F) < ENNReal.ofReal ε := by
    have heq : volume (Icc a b \ F) = ν Fᶜ := by
      rw [hν, Measure.restrict_apply hFc.measurableSet.compl, sdiff_eq, inter_comm]
    rw [heq]
    have hsub : Fᶜ ⊆ F1ᶜ ∪ (Nᶜ \ F2) ∪ N ∪ (Icc a b)ᶜ := by
      intro x hx
      simp only [hFdef, mem_compl_iff, mem_inter_iff, not_and_or, mem_union, mem_sdiff] at hx ⊢
      tauto
    calc ν Fᶜ ≤ ν (F1ᶜ ∪ (Nᶜ \ F2) ∪ N ∪ (Icc a b)ᶜ) := measure_mono hsub
      _ ≤ ν F1ᶜ + ν (Nᶜ \ F2) + ν N + ν (Icc a b)ᶜ := by
          refine (measure_union_le _ _).trans ?_
          gcongr
          refine (measure_union_le _ _).trans ?_
          gcongr
          exact measure_union_le _ _
      _ = ν F1ᶜ + ν (Nᶜ \ F2) := by rw [hN0, hI, add_zero, add_zero]
      _ < ENNReal.ofReal ε / 2 + ENNReal.ofReal ε / 2 := ENNReal.add_lt_add hF1ν hF2ν
      _ = ENNReal.ofReal ε := ENNReal.add_halves _
  have hcont : ContinuousOn f F :=
    (continuous_coe_real_ereal.comp_continuousOn (hF1cont.mono hFF1)).congr hfF
  have hFcpt : IsCompact F := isCompact_Icc.of_isClosed_subset hFc hFsub
  have : CompactSpace F := isCompact_iff_compactSpace.mp hFcpt
  let φ : BoundedContinuousFunction F ℝ := BoundedContinuousFunction.mkOfCompact
    ⟨fun x => h x, (hF1cont.mono hFF1).domRestrict⟩
  obtain ⟨G, hGnorm, hGφ⟩ :=
    BoundedContinuousFunction.exists_extension_norm_eq_of_isClosedEmbedding φ
      hFc.isClosedEmbedding_subtypeVal
  have hGF : ∀ x (hx : x ∈ F), G x = h x := fun x hx => congrFun hGφ ⟨x, hx⟩
  refine ⟨F, hFc, hFsub, hvol, hcont, G, G.continuous.continuousOn, ?_, ?_⟩
  · intro x hx
    rw [hGF x hx, hfF x hx]
  · intro M hM hbd x _
    have hφ : ‖φ‖ ≤ M := (BoundedContinuousFunction.norm_le hM).2 fun y => by
      show ‖h y‖ ≤ M
      rw [Real.norm_eq_abs, ← hGF y y.2]
      exact hbd y y.2
    calc |G x| = ‖G x‖ := (Real.norm_eq_abs _).symm
      _ ≤ ‖G‖ := G.norm_coe_le_norm x
      _ ≤ M := hGnorm ▸ hφ

/-- The open-set form of Lusin's theorem. Under the same hypotheses, `f` equals a continuous
function off an open set `U` of size less than `ε`: some `g` continuous on `[a, b]` agrees with
`f` at every point of `[a, b]` outside `U`. -/
theorem lusin_equals_continuous_off_open_set (a b : ℝ) (f : ℝ → EReal)
    (hf : AEMeasurable f (volume.restrict (Icc a b)))
    (hfin : ∀ᵐ x ∂(volume.restrict (Icc a b)), f x ≠ ⊤ ∧ f x ≠ ⊥)
    (ε : ℝ) (hε : 0 < ε) :
    ∃ U : Set ℝ, IsOpen U ∧ volume U < ENNReal.ofReal ε ∧
      ∃ g : ℝ → ℝ, ContinuousOn g (Icc a b) ∧ ∀ x ∈ Icc a b \ U, (g x : EReal) = f x := by
  obtain ⟨F, -, -, hvol, -, g, hg, hgF, -⟩ :=
    lusin_measurable_continuous_off_small_set a b f hf hfin ε hε
  obtain ⟨U, hUsup, hUo, hUv⟩ := Set.exists_isOpen_lt_of_lt (Icc a b \ F) _ hvol
  refine ⟨U, hUo, hUv, g, hg, fun x hx => hgF x ?_⟩
  by_contra hxF
  exact hx.2 (hUsup ⟨hx.1, hxF⟩)

/-- The density corollary. Every integrable function `f` on the line has a continuous function
`h` with compact support (zero outside a bounded interval) with `∫ |f - h| dλ < ε`: continuous
functions with compact support are dense in `L¹(ℝ)`. -/
theorem continuous_compact_support_dense_in_L1 (f : ℝ → ℝ) (hf : Integrable f volume)
    (ε : ℝ) (hε : 0 < ε) :
    ∃ h : ℝ → ℝ, Continuous h ∧ HasCompactSupport h ∧ ∫ x, |f x - h x| < ε := by
  obtain ⟨g, hgc, hint, hgcont, -⟩ := hf.exists_hasCompactSupport_integral_sub_le (half_pos hε)
  refine ⟨g, hgcont, hgc, ?_⟩
  have heq : (∫ x, |f x - g x|) = ∫ x, ‖f x - g x‖ := by simp only [Real.norm_eq_abs]
  rw [heq]
  linarith

-- Dirichlet function: deleted length inside [0, 1] is at most 0.01 × (1/4 + 1/8 + 1/4) = 0.00625.
example : (1 / 100 : ℚ) * (1 / 4 + 1 / 8 + 1 / 4) = 1 / 160 := by norm_num
-- The closed set left keeps at least 1 − 0.00625 = 0.99375 of [0, 1].
example : (1 : ℚ) - 1 / 160 = 159 / 160 := by norm_num
-- Widths of the first five rationals: 0.01 × 2^(−n) for n = 1, …, 5.
example : ((List.range 5).map fun n => (1 / 100 : ℚ) / 2 ^ (n + 1)) =
    [1 / 200, 1 / 400, 1 / 800, 1 / 1600, 1 / 3200] := by norm_num [List.range_succ]
-- 23 rationals in [0, 1] with denominator up to 8: 0 and 1, plus φ(2) + … + φ(8).
example : 2 + ∑ q ∈ Finset.Icc 2 8, Nat.totient q = 23 := by decide
-- 3045 rationals in [0, 1] with denominator up to 100, and 3045 − 23 = 3022 are left.
example : 2 + ∑ q ∈ Finset.Icc 2 100, Nat.totient q = 3045 := by decide +kernel
example : 3045 - 23 = 3022 := by norm_num
-- Tariff: gaps of width 0.0005 at 1/3 and 2/3 keep 1 − 2 × 0.0005 = 0.999 of the day.
example : (1 : ℚ) - 2 * (1 / 2000) = 999 / 1000 := by norm_num
-- Tariff: area between s and g is (20 + 10) × 0.0005 / 4 = 0.00375; the worst gap is 20 / 2 = 10.
example : ((20 + 10) * (1 / 2000) / 4 : ℚ) = 3 / 800 := by norm_num
example : (20 / 2 : ℚ) = 10 := by norm_num
-- Line: area between s and h is (10 + 20 + 10 + 20) × 0.0005 / 4 = 0.0075; proof's bound 60 × 0.002 = 0.12.
example : ((10 + 20 + 10 + 20) * (1 / 2000) / 4 : ℚ) = 3 / 400 := by norm_num
example : (60 * (1 / 500) : ℚ) = 3 / 25 := by norm_num

#print axioms lusin_measurable_continuous_off_small_set
#print axioms lusin_equals_continuous_off_open_set
#print axioms continuous_compact_support_dense_in_L1
