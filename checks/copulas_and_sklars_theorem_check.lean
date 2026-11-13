-- Copulas: every joint law on the plane with continuous margins has exactly one copula, any copula joined to any margins gives a joint law, and the Clayton copula's lower tail dependence is 2^(-1/θ).
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory Set Filter Topology

/-- A copula, as the card defines it: a joint law of two ranks `(U, V)` on the plane whose two
margins are both the uniform law on `[0, 1]`. Its value `C(u, v)` is `ν.real (Iic u ×ˢ Iic v)`. -/
def IsCopula (ν : Measure (ℝ × ℝ)) : Prop :=
  ν.map Prod.fst = volume.restrict (Icc (0 : ℝ) 1) ∧ ν.map Prod.snd = volume.restrict (Icc (0 : ℝ) 1)

/-- Two finite measures on the plane that agree on all quadrants `Iic a ×ˢ Iic b` (and on the whole
plane) are equal. -/
theorem copula_ext_prod_Iic (μ ν : Measure (ℝ × ℝ)) [IsFiniteMeasure μ]
    (huniv : μ univ = ν univ) (h : ∀ a b : ℝ, μ (Iic a ×ˢ Iic b) = ν (Iic a ×ˢ Iic b)) :
    μ = ν := by
  have hspan : IsCountablySpanning (range (Iic : ℝ → Set ℝ)) :=
    ⟨fun n : ℕ => Iic (n : ℝ), fun n => ⟨_, rfl⟩, by
      ext x; simp only [mem_iUnion, mem_Iic, mem_univ, iff_true]; exact exists_nat_ge x⟩
  have hR : MeasurableSpace.generateFrom (range (Iic : ℝ → Set ℝ)) =
      (inferInstance : MeasurableSpace ℝ) := by
    rw [← borel_eq_generateFrom_Iic ℝ]; exact BorelSpace.measurable_eq.symm
  refine ext_of_generate_finite _ (generateFrom_eq_prod hR hR hspan hspan).symm
    (isPiSystem_Iic.prod isPiSystem_Iic) ?_ huniv
  rintro _ ⟨_, ⟨a, rfl⟩, _, ⟨b, rfl⟩, rfl⟩
  exact h a b

theorem copula_vol_Icc_isProb : IsProbabilityMeasure (volume.restrict (Icc (0 : ℝ) 1)) :=
  ⟨by simp [Real.volume_Icc]⟩

theorem copula_isProb {ν : Measure (ℝ × ℝ)} (h : IsCopula ν) : IsProbabilityMeasure ν := by
  constructor
  have := congrArg (fun m : Measure ℝ => m univ) h.1
  rw [Measure.map_apply measurable_fst MeasurableSet.univ] at this
  simpa [Real.volume_Icc] using this

theorem copula_fst_preimage {ν : Measure (ℝ × ℝ)} (h : IsCopula ν) {s : Set ℝ}
    (hs : MeasurableSet s) : ν (Prod.fst ⁻¹' s) = volume (s ∩ Icc 0 1) := by
  rw [← Measure.map_apply measurable_fst hs, h.1, Measure.restrict_apply hs]

theorem copula_snd_preimage {ν : Measure (ℝ × ℝ)} (h : IsCopula ν) {s : Set ℝ}
    (hs : MeasurableSet s) : ν (Prod.snd ⁻¹' s) = volume (s ∩ Icc 0 1) := by
  rw [← Measure.map_apply measurable_snd hs, h.2, Measure.restrict_apply hs]

theorem copula_vol_compl_Ioo : volume ((Ioo (0 : ℝ) 1)ᶜ ∩ Icc 0 1) = 0 := by
  refine measure_mono_null (t := {0, 1}) ?_ ?_
  · rintro x ⟨hx1, hx2⟩
    simp only [mem_compl_iff, mem_Ioo, not_and, not_lt, mem_Icc] at hx1 hx2
    simp only [mem_insert_iff, mem_singleton_iff]
    rcases eq_or_lt_of_le hx2.1 with h | h
    · exact Or.inl h.symm
    · exact Or.inr (le_antisymm hx2.2 (hx1 h))
  · exact measure_union_null (Real.volume_singleton) (Real.volume_singleton)

theorem copula_null_compl {ν : Measure (ℝ × ℝ)} (h : IsCopula ν) :
    ν (Ioo (0 : ℝ) 1 ×ˢ Ioo (0 : ℝ) 1)ᶜ = 0 := by
  refine measure_mono_null (t := Prod.fst ⁻¹' (Ioo (0 : ℝ) 1)ᶜ ∪ Prod.snd ⁻¹' (Ioo (0 : ℝ) 1)ᶜ)
    ?_ (measure_union_null ?_ ?_)
  · rintro ⟨a, b⟩ hab
    simp only [mem_compl_iff, mem_prod, not_and_or] at hab
    simpa only [mem_union, mem_preimage, mem_compl_iff] using hab
  · rw [copula_fst_preimage h measurableSet_Ioo.compl]; exact copula_vol_compl_Ioo
  · rw [copula_snd_preimage h measurableSet_Ioo.compl]; exact copula_vol_compl_Ioo

theorem copula_apply_le_zero_left {ν : Measure (ℝ × ℝ)} (h : IsCopula ν) {u : ℝ} (hu : u ≤ 0)
    (v : ℝ) : ν (Iic u ×ˢ Iic v) = 0 := by
  refine measure_mono_null (prod_subset_preimage_fst _ _) ?_
  rw [copula_fst_preimage h measurableSet_Iic]
  refine measure_mono_null (t := {0}) ?_ Real.volume_singleton
  rintro x ⟨hx1, hx2⟩
  exact le_antisymm (le_trans hx1 hu) hx2.1

theorem copula_apply_le_zero_right {ν : Measure (ℝ × ℝ)} (h : IsCopula ν) (u : ℝ) {v : ℝ}
    (hv : v ≤ 0) : ν (Iic u ×ˢ Iic v) = 0 := by
  refine measure_mono_null (prod_subset_preimage_snd _ _) ?_
  rw [copula_snd_preimage h measurableSet_Iic]
  refine measure_mono_null (t := {0}) ?_ Real.volume_singleton
  rintro x ⟨hx1, hx2⟩
  exact le_antisymm (le_trans hx1 hv) hx2.1

theorem copula_apply_one_le_left {ν : Measure (ℝ × ℝ)} (h : IsCopula ν) {u : ℝ} (hu : 1 ≤ u)
    (v : ℝ) : ν (Iic u ×ˢ Iic v) = volume (Iic v ∩ Icc 0 1) := by
  rw [Set.prod_eq, inter_comm, measure_inter_conull, copula_snd_preimage h measurableSet_Iic]
  rw [← preimage_compl, copula_fst_preimage h measurableSet_Iic.compl]
  refine measure_mono_null (t := {1}) ?_ Real.volume_singleton
  rintro x ⟨hx1, hx2⟩
  simp only [mem_compl_iff, mem_Iic, not_le] at hx1
  exact le_antisymm hx2.2 (hu.trans hx1.le)

theorem copula_apply_one_le_right {ν : Measure (ℝ × ℝ)} (h : IsCopula ν) (u : ℝ) {v : ℝ}
    (hv : 1 ≤ v) : ν (Iic u ×ˢ Iic v) = volume (Iic u ∩ Icc 0 1) := by
  rw [Set.prod_eq, measure_inter_conull, copula_fst_preimage h measurableSet_Iic]
  rw [← preimage_compl, copula_snd_preimage h measurableSet_Iic.compl]
  refine measure_mono_null (t := {1}) ?_ Real.volume_singleton
  rintro x ⟨hx1, hx2⟩
  simp only [mem_compl_iff, mem_Iic, not_le] at hx1
  exact le_antisymm hx2.2 (hv.trans hx1.le)

/-- Two copulas that agree on all `Iic u ×ˢ Iic v` with `u, v` in the ranges of `F` and `G`, where
the ranges cover `(0, 1)`, are equal. -/
theorem copula_eq_of_agree {ν₁ ν₂ : Measure (ℝ × ℝ)} (h₁ : IsCopula ν₁) (h₂ : IsCopula ν₂)
    (F G : ℝ → ℝ) (hF : ∀ u ∈ Ioo (0 : ℝ) 1, ∃ x, F x = u) (hG : ∀ u ∈ Ioo (0 : ℝ) 1, ∃ y, G y = u)
    (h : ∀ x y, ν₁.real (Iic (F x) ×ˢ Iic (G y)) = ν₂.real (Iic (F x) ×ˢ Iic (G y))) :
    ν₁ = ν₂ := by
  have := copula_isProb h₁
  have := copula_isProb h₂
  refine copula_ext_prod_Iic ν₁ ν₂ (by simp) fun u v => ?_
  rcases le_or_gt u 0 with hu | hu
  · rw [copula_apply_le_zero_left h₁ hu, copula_apply_le_zero_left h₂ hu]
  rcases le_or_gt v 0 with hv | hv
  · rw [copula_apply_le_zero_right h₁ u hv, copula_apply_le_zero_right h₂ u hv]
  rcases le_or_gt 1 u with hu1 | hu1
  · rw [copula_apply_one_le_left h₁ hu1, copula_apply_one_le_left h₂ hu1]
  rcases le_or_gt 1 v with hv1 | hv1
  · rw [copula_apply_one_le_right h₁ u hv1, copula_apply_one_le_right h₂ u hv1]
  obtain ⟨x, rfl⟩ := hF u ⟨hu, hu1⟩
  obtain ⟨y, rfl⟩ := hG v ⟨hv, hv1⟩
  have := h x y
  rw [measureReal_def, measureReal_def] at this
  exact (ENNReal.toReal_eq_toReal_iff' (measure_ne_top _ _) (measure_ne_top _ _)).1 this

/-- A continuous cumulative distribution takes every value strictly between 0 and 1. -/
theorem copula_cdf_range (m : Measure ℝ) (hF : Continuous (cdf m)) :
    ∀ u ∈ Ioo (0 : ℝ) 1, ∃ x, cdf m x = u := by
  intro u hu
  obtain ⟨a, ha⟩ := ((tendsto_cdf_atBot m).eventually_lt_const hu.1).exists
  obtain ⟨b, hb⟩ := ((tendsto_cdf_atTop m).eventually_const_lt hu.2).exists
  exact intermediate_value_univ a b hF ⟨ha.le, hb.le⟩

/-- Probability integral transform: for a continuous cumulative distribution `F`,
`m (F ≤ u) = u` for `u` in `[0, 1]`. -/
theorem copula_pit (m : Measure ℝ) [IsProbabilityMeasure m] (hF : Continuous (cdf m)) {u : ℝ}
    (hu : 0 ≤ u) (hu1 : u ≤ 1) : m {x | cdf m x ≤ u} = ENNReal.ofReal u := by
  rcases eq_or_lt_of_le hu1 with rfl | hu1
  · have : {x | cdf m x ≤ 1} = univ := by
      ext x; simp only [mem_ofPred_eq, mem_univ, iff_true]; exact cdf_le_one m x
    simp [this]
  by_cases hne : {x | cdf m x ≤ u}.Nonempty
  · have hbdd : BddAbove {x | cdf m x ≤ u} := by
      obtain ⟨b, hb⟩ := ((tendsto_cdf_atTop m).eventually_const_lt hu1).exists
      refine ⟨b, fun x hx => ?_⟩
      by_contra hxb
      push Not at hxb
      have := (cdf m).mono hxb.le
      simp only [mem_ofPred_eq] at hx
      linarith
    have hclosed : IsClosed {x | cdf m x ≤ u} := isClosed_le hF continuous_const
    have hs : cdf m (sSup {x | cdf m x ≤ u}) ≤ u := hclosed.csSup_mem hne hbdd
    have hset : {x | cdf m x ≤ u} = Iic (sSup {x | cdf m x ≤ u}) := by
      ext x
      constructor
      · intro hx; exact le_csSup hbdd hx
      · intro hx; exact le_trans ((cdf m).mono hx) hs
    have hsu : u ≤ cdf m (sSup {x | cdf m x ≤ u}) := by
      have ht : Tendsto (cdf m) (𝓝[>] (sSup {x | cdf m x ≤ u}))
          (𝓝 (cdf m (sSup {x | cdf m x ≤ u}))) :=
        (hF.tendsto _).mono_left nhdsWithin_le_nhds
      refine ge_of_tendsto ht ?_
      filter_upwards [self_mem_nhdsWithin] with t ht
      by_contra hlt
      push Not at hlt
      exact absurd (le_csSup hbdd (show cdf m t ≤ u from hlt.le)) (not_le.2 ht)
    rw [hset, ← ofReal_cdf, le_antisymm hs hsu]
  · rw [not_nonempty_iff_eq_empty] at hne
    have hlt : ∀ x, u ≤ cdf m x := fun x => by
      by_contra h
      push Not at h
      have hx : x ∈ {x | cdf m x ≤ u} := h.le
      rw [hne] at hx
      exact hx
    have : u ≤ 0 := ge_of_tendsto' (tendsto_cdf_atBot m) hlt
    rw [hne, le_antisymm this hu]
    simp

theorem copula_pit_map (m : Measure ℝ) [IsProbabilityMeasure m] (hF : Continuous (cdf m)) :
    m.map (cdf m) = volume.restrict (Icc (0 : ℝ) 1) := by
  refine Measure.ext_of_Iic _ _ fun u => ?_
  rw [Measure.map_apply hF.measurable measurableSet_Iic, Measure.restrict_apply measurableSet_Iic]
  rcases lt_or_ge u 0 with hu | hu
  · have h1 : cdf m ⁻¹' Iic u = ∅ := by
      ext x; simp only [mem_preimage, mem_Iic, mem_empty_iff_false, iff_false, not_le]
      linarith [cdf_nonneg m x]
    have h2 : Iic u ∩ Icc (0 : ℝ) 1 = ∅ := by
      ext x; simp only [mem_inter_iff, mem_Iic, mem_Icc, mem_empty_iff_false, iff_false]
      intro h; linarith [h.2.1]
    rw [h1, h2]; simp
  rcases le_or_gt 1 u with hu1 | hu1
  · have h1 : cdf m ⁻¹' Iic u = univ := by
      ext x; simp only [mem_preimage, mem_Iic, mem_univ, iff_true]
      linarith [cdf_le_one m x]
    have h2 : Iic u ∩ Icc (0 : ℝ) 1 = Icc 0 1 := by
      ext x; simp only [mem_inter_iff, mem_Iic, mem_Icc, and_iff_right_iff_imp]
      intro h; linarith [h.2]
    rw [h1, h2]; simp [Real.volume_Icc]
  · have h2 : Iic u ∩ Icc (0 : ℝ) 1 = Icc 0 u := by
      ext x; simp only [mem_inter_iff, mem_Iic, mem_Icc]
      constructor
      · rintro ⟨h1, h2, _⟩; exact ⟨h2, h1⟩
      · rintro ⟨h1, h2⟩; exact ⟨h2, h1, by linarith⟩
    rw [h2, Real.volume_Icc, sub_zero]
    exact copula_pit m hF hu hu1.le

/-- For a continuous cumulative distribution `F`, the event `F t ≤ F x` differs from `t ≤ x` only on
a null set. -/
theorem copula_cdf_diff_null (m : Measure ℝ) [IsProbabilityMeasure m] (hF : Continuous (cdf m))
    (x : ℝ) : m ({t | cdf m t ≤ cdf m x} \ Iic x) = 0 := by
  rw [measure_sdiff (fun t ht => (cdf m).mono ht) measurableSet_Iic.nullMeasurableSet
    (measure_ne_top _ _), copula_pit m hF (cdf_nonneg m x) (cdf_le_one m x), ofReal_cdf, tsub_self]

/-- The quantile function (left-continuous inverse) of a measure on the line, set to 0 off `(0, 1)`. -/
noncomputable def copulaQf (m : Measure ℝ) (u : ℝ) : ℝ :=
  if u ∈ Ioo (0 : ℝ) 1 then sInf {x | u ≤ cdf m x} else 0

theorem copulaQf_le_iff (m : Measure ℝ) [IsProbabilityMeasure m] {u : ℝ} (hu : u ∈ Ioo (0 : ℝ) 1)
    (x : ℝ) : copulaQf m u ≤ x ↔ u ≤ cdf m x := by
  simp only [copulaQf, hu, ↓reduceIte]
  have hne : {x | u ≤ cdf m x}.Nonempty :=
    ((tendsto_cdf_atTop m).eventually_const_lt hu.2).exists.imp fun _ h => h.le
  obtain ⟨a, ha⟩ := ((tendsto_cdf_atBot m).eventually_lt_const hu.1).exists
  have hbdd : BddBelow {x | u ≤ cdf m x} := ⟨a, fun y hy => by
    by_contra h
    push Not at h
    have := (cdf m).mono h.le
    simp only [mem_ofPred_eq] at hy
    linarith⟩
  have hmem : u ≤ cdf m (sInf {x | u ≤ cdf m x}) := by
    have ht : Tendsto (cdf m) (𝓝[>] (sInf {x | u ≤ cdf m x}))
        (𝓝 (cdf m (sInf {x | u ≤ cdf m x}))) :=
      ((cdf m).right_continuous _).mono_left (nhdsWithin_mono _ Ioi_subset_Ici_self)
    refine ge_of_tendsto ht ?_
    filter_upwards [self_mem_nhdsWithin] with t ht
    obtain ⟨s, hsS, hst⟩ := exists_lt_of_csInf_lt hne ht
    exact le_trans hsS ((cdf m).mono hst.le)
  constructor
  · intro h; exact hmem.trans ((cdf m).mono h)
  · intro h; exact csInf_le hbdd h

theorem copulaQf_measurable (m : Measure ℝ) [IsProbabilityMeasure m] : Measurable (copulaQf m) := by
  refine measurable_of_Iic fun x => ?_
  have : copulaQf m ⁻¹' Iic x =
      (Ioo 0 1 ∩ Iic (cdf m x)) ∪ ((Ioo 0 1)ᶜ ∩ {_u | (0 : ℝ) ≤ x}) := by
    ext u
    by_cases hu : u ∈ Ioo (0 : ℝ) 1
    · simp only [mem_preimage, mem_Iic, mem_union, mem_inter_iff, hu, true_and, mem_compl_iff,
        not_true_eq_false, false_and, or_false]
      exact copulaQf_le_iff m hu x
    · simp only [mem_preimage, mem_Iic, mem_union, mem_inter_iff, hu, false_and, false_or,
        mem_compl_iff, not_false_eq_true, true_and, mem_ofPred_eq, copulaQf, ↓reduceIte]
  rw [this]
  exact (measurableSet_Ioo.inter measurableSet_Iic).union
    (measurableSet_Ioo.compl.inter (MeasurableSet.const _))

theorem copulaQf_map (m : Measure ℝ) [IsProbabilityMeasure m] :
    (volume.restrict (Icc (0 : ℝ) 1)).map (copulaQf m) = m := by
  have := copula_vol_Icc_isProb
  refine Measure.ext_of_Iic _ _ fun x => ?_
  rw [Measure.map_apply (copulaQf_measurable m) measurableSet_Iic,
    Measure.restrict_apply (copulaQf_measurable m measurableSet_Iic), ← ofReal_cdf]
  have h1 : copulaQf m ⁻¹' Iic x ∩ Icc 0 1 =ᵐ[volume] copulaQf m ⁻¹' Iic x ∩ Ioo 0 1 :=
    EventuallyEqSet.inter (by rfl) Ioo_ae_eq_Icc.symm
  have h2 : copulaQf m ⁻¹' Iic x ∩ Ioo 0 1 = Iic (cdf m x) ∩ Ioo 0 1 := by
    ext u
    simp only [mem_inter_iff, mem_preimage, mem_Iic]
    constructor
    · rintro ⟨h, hu⟩; exact ⟨(copulaQf_le_iff m hu x).1 h, hu⟩
    · rintro ⟨h, hu⟩; exact ⟨(copulaQf_le_iff m hu x).2 h, hu⟩
  have h3 : Iic (cdf m x) ∩ Ioo 0 1 =ᵐ[volume] Iic (cdf m x) ∩ Icc (0 : ℝ) 1 :=
    EventuallyEqSet.inter (by rfl) Ioo_ae_eq_Icc
  have h4 : Iic (cdf m x) ∩ Icc (0 : ℝ) 1 = Icc 0 (cdf m x) := by
    ext u
    simp only [mem_inter_iff, mem_Iic, mem_Icc]
    constructor
    · rintro ⟨h1, h2, _⟩; exact ⟨h2, h1⟩
    · rintro ⟨h1, h2⟩; exact ⟨h2, h1, h2.trans (cdf_le_one m x)⟩
  rw [measure_congr h1, h2, measure_congr h3, h4, Real.volume_Icc, sub_zero]

/-- Sklar's theorem for continuous margins. Let `H(x, y) = μ(X ≤ x, Y ≤ y)` be a joint law of two
real variables, with margins `F` and `G` (the cumulative distributions of `X` and of `Y`). If `F`
and `G` are continuous, there is exactly one copula `C` with `H(x, y) = C(F(x), G(y))` for all
`x` and `y`. -/
theorem sklar_unique_copula_of_continuous_margins (μ : Measure (ℝ × ℝ)) [IsProbabilityMeasure μ]
    (hF : Continuous (cdf (μ.map Prod.fst))) (hG : Continuous (cdf (μ.map Prod.snd))) :
    ∃! ν : Measure (ℝ × ℝ), IsCopula ν ∧
      ∀ x y : ℝ, μ.real (Iic x ×ˢ Iic y) =
        ν.real (Iic (cdf (μ.map Prod.fst) x) ×ˢ Iic (cdf (μ.map Prod.snd) y)) := by
  have : IsProbabilityMeasure (μ.map Prod.fst) := inferInstance
  have : IsProbabilityMeasure (μ.map Prod.snd) := inferInstance
  have hφ : Measurable (fun p : ℝ × ℝ => (cdf (μ.map Prod.fst) p.1, cdf (μ.map Prod.snd) p.2)) :=
    (hF.measurable.comp measurable_fst).prodMk (hG.measurable.comp measurable_snd)
  have hcop : IsCopula (μ.map (fun p : ℝ × ℝ => (cdf (μ.map Prod.fst) p.1, cdf (μ.map Prod.snd) p.2))) := by
    constructor
    · rw [Measure.map_map measurable_fst hφ]
      change μ.map (cdf (μ.map Prod.fst) ∘ Prod.fst) = _
      rw [← Measure.map_map hF.measurable measurable_fst, copula_pit_map _ hF]
    · rw [Measure.map_map measurable_snd hφ]
      change μ.map (cdf (μ.map Prod.snd) ∘ Prod.snd) = _
      rw [← Measure.map_map hG.measurable measurable_snd, copula_pit_map _ hG]
  have hjoint : ∀ x y : ℝ, μ.real (Iic x ×ˢ Iic y) =
      (μ.map (fun p : ℝ × ℝ => (cdf (μ.map Prod.fst) p.1, cdf (μ.map Prod.snd) p.2))).real
        (Iic (cdf (μ.map Prod.fst) x) ×ˢ Iic (cdf (μ.map Prod.snd) y)) := by
    intro x y
    rw [measureReal_def, measureReal_def, Measure.map_apply hφ (measurableSet_Iic.prod measurableSet_Iic)]
    congr 1
    have hD1 : μ (Prod.fst ⁻¹' ({t | cdf (μ.map Prod.fst) t ≤ cdf (μ.map Prod.fst) x} \ Iic x)) = 0 := by
      rw [← Measure.map_apply measurable_fst
        ((measurableSet_le hF.measurable measurable_const).diff measurableSet_Iic)]
      exact copula_cdf_diff_null _ hF x
    have hD2 : μ (Prod.snd ⁻¹' ({t | cdf (μ.map Prod.snd) t ≤ cdf (μ.map Prod.snd) y} \ Iic y)) = 0 := by
      rw [← Measure.map_apply measurable_snd
        ((measurableSet_le hG.measurable measurable_const).diff measurableSet_Iic)]
      exact copula_cdf_diff_null _ hG y
    apply le_antisymm
    · apply measure_mono
      rintro ⟨a, b⟩ ⟨ha, hb⟩
      exact ⟨(cdf _).mono ha, (cdf _).mono hb⟩
    · calc _ ≤ μ (Iic x ×ˢ Iic y ∪
            Prod.fst ⁻¹' ({t | cdf (μ.map Prod.fst) t ≤ cdf (μ.map Prod.fst) x} \ Iic x) ∪
            Prod.snd ⁻¹' ({t | cdf (μ.map Prod.snd) t ≤ cdf (μ.map Prod.snd) y} \ Iic y)) := by
            apply measure_mono
            rintro ⟨a, b⟩ hab
            simp only [mem_preimage, mem_prod, mem_Iic] at hab
            simp only [mem_union, mem_prod, mem_preimage, mem_Iic, Set.mem_sdiff, mem_ofPred_eq]
            by_cases hax : a ≤ x <;> by_cases hby : b ≤ y <;> tauto
        _ ≤ μ (Iic x ×ˢ Iic y) +
            μ (Prod.fst ⁻¹' ({t | cdf (μ.map Prod.fst) t ≤ cdf (μ.map Prod.fst) x} \ Iic x)) +
            μ (Prod.snd ⁻¹' ({t | cdf (μ.map Prod.snd) t ≤ cdf (μ.map Prod.snd) y} \ Iic y)) :=
            (measure_union_le _ _).trans (by gcongr; exact measure_union_le _ _)
        _ = μ (Iic x ×ˢ Iic y) := by rw [hD1, hD2, add_zero, add_zero]
  refine ⟨_, ⟨hcop, hjoint⟩, fun ν' ⟨hc', hj'⟩ => ?_⟩
  exact copula_eq_of_agree hc' hcop _ _ (copula_cdf_range _ hF) (copula_cdf_range _ hG)
    (fun x y => (hj' x y).symm.trans (hjoint x y))

/-- The converse of Sklar's theorem ("mix and match"): any copula `C` dressed in any margins `F`
and `G` is a joint law. There is a joint law with margins exactly `F` and `G` whose joint
cumulative distribution is `H(x, y) = C(F(x), G(y))`. -/
theorem copula_with_any_margins_is_joint_law (ν : Measure (ℝ × ℝ)) (hν : IsCopula ν)
    (f g : Measure ℝ) [IsProbabilityMeasure f] [IsProbabilityMeasure g] :
    ∃ μ : Measure (ℝ × ℝ), IsProbabilityMeasure μ ∧ μ.map Prod.fst = f ∧ μ.map Prod.snd = g ∧
      ∀ x y : ℝ, μ.real (Iic x ×ˢ Iic y) = ν.real (Iic (cdf f x) ×ˢ Iic (cdf g y)) := by
  have := copula_isProb hν
  have hq : Measurable (fun p : ℝ × ℝ => (copulaQf f p.1, copulaQf g p.2)) :=
    ((copulaQf_measurable f).comp measurable_fst).prodMk ((copulaQf_measurable g).comp measurable_snd)
  refine ⟨ν.map (fun p : ℝ × ℝ => (copulaQf f p.1, copulaQf g p.2)),
    inferInstance, ?_, ?_, ?_⟩
  · rw [Measure.map_map measurable_fst hq]
    change ν.map (copulaQf f ∘ Prod.fst) = f
    rw [← Measure.map_map (copulaQf_measurable f) measurable_fst, hν.1, copulaQf_map]
  · rw [Measure.map_map measurable_snd hq]
    change ν.map (copulaQf g ∘ Prod.snd) = g
    rw [← Measure.map_map (copulaQf_measurable g) measurable_snd, hν.2, copulaQf_map]
  · intro x y
    rw [measureReal_def, measureReal_def,
      Measure.map_apply hq (measurableSet_Iic.prod measurableSet_Iic)]
    congr 1
    refine (measure_inter_conull (copula_null_compl hν)).symm.trans
      (Eq.trans ?_ (measure_inter_conull (copula_null_compl hν)))
    congr 1
    ext ⟨a, b⟩
    simp only [mem_inter_iff, mem_preimage, mem_prod, mem_Iic]
    constructor
    · rintro ⟨⟨h1, h2⟩, ha, hb⟩
      exact ⟨⟨(copulaQf_le_iff f ha x).1 h1, (copulaQf_le_iff g hb y).1 h2⟩, ha, hb⟩
    · rintro ⟨⟨h1, h2⟩, ha, hb⟩
      exact ⟨⟨(copulaQf_le_iff f ha x).2 h1, (copulaQf_le_iff g hb y).2 h2⟩, ha, hb⟩

/-- Lower tail dependence of the Clayton copula `C(u, v) = (u^(-θ) + v^(-θ) - 1)^(-1/θ)` with
dial `θ > 0`: as the rarity `p` shrinks to 0, the chance `C(p, p) / p` that `B` has its worst
`p`-day given that `A` does tends to `2^(-1/θ)`, not to 0. -/
theorem clayton_lower_tail_dependence (θ : ℝ) (hθ : 0 < θ) :
    Tendsto (fun p : ℝ => (p ^ (-θ) + p ^ (-θ) - 1) ^ (-1 / θ) / p) (𝓝[>] 0)
      (𝓝 ((2 : ℝ) ^ (-1 / θ))) := by
  have h1 : Tendsto (fun p : ℝ => p ^ θ) (𝓝[>] 0) (𝓝 0) := by
    have := (Real.continuousAt_rpow_const 0 θ (Or.inr hθ.le)).tendsto
    rw [Real.zero_rpow hθ.ne'] at this
    exact this.mono_left nhdsWithin_le_nhds
  have h2 : Tendsto (fun p : ℝ => 2 - p ^ θ) (𝓝[>] 0) (𝓝 2) := by
    simpa using (tendsto_const_nhds (x := (2 : ℝ))).sub h1
  have hlim : Tendsto (fun p : ℝ => (2 - p ^ θ) ^ (-1 / θ)) (𝓝[>] 0) (𝓝 ((2 : ℝ) ^ (-1 / θ))) :=
    h2.rpow_const (Or.inl two_ne_zero)
  refine hlim.congr' ?_
  filter_upwards [Ioo_mem_nhdsGT (show (0 : ℝ) < 1 by norm_num)] with p hp
  have hp0 : 0 < p := hp.1
  have hq : 0 < p ^ θ := Real.rpow_pos_of_pos hp0 θ
  have hq1 : p ^ θ < 1 := Real.rpow_lt_one hp0.le hp.2 hθ
  have e1 : p ^ (-θ) = (p ^ θ)⁻¹ := Real.rpow_neg hp0.le θ
  have e2 : p ^ (-θ) + p ^ (-θ) - 1 = (2 - p ^ θ) / p ^ θ := by
    rw [e1]; field_simp; ring
  have e3 : (p ^ θ) ^ (-1 / θ) = p⁻¹ := by
    rw [← Real.rpow_mul hp0.le, show θ * (-1 / θ) = -1 by field_simp, Real.rpow_neg_one]
  rw [e2, Real.div_rpow (by linarith) hq.le, e3]
  field_simp

-- Kendall's tau 1/2 gives the Clayton dial θ = 2τ/(1 - τ) = 2.
example : 2 * (1 / 2 : ℚ) / (1 - 1 / 2) = 2 := by norm_num

-- Clayton with θ = 2 at the worst day in 100: each rank gives 0.01^(-2) = 10000, and
-- 10000 + 10000 - 1 = 19999.
example : ((1 : ℚ) / 100) ^ (-2 : ℤ) = 10000 := by norm_num
example : ((1 : ℚ) / 100) ^ (-2 : ℤ) + ((1 : ℚ) / 100) ^ (-2 : ℤ) - 1 = 19999 := by norm_num

-- Independent markets: the joint chance at the worst day in 100 is 0.01 × 0.01 = 0.0001.
example : (1 / 100 : ℚ) * (1 / 100) = 1 / 10000 := by norm_num

-- Two fair coins: the product copula uv and the patchwork copula agree at (1/2, 1/2), where both
-- give 1/4, but differ at (1/4, 1/4), where they give 1/16 and 1/8.
example :
    let patch : ℚ → ℚ → ℚ := fun u v =>
      (max 0 (min 1 (min (2 * u) (2 * v))) + max 0 (min 1 (min (2 * u - 1) (2 * v))) +
        max 0 (min 1 (min (2 * u) (2 * v - 1))) + max 0 (min 1 (min (2 * u - 1) (2 * v - 1)))) / 4
    (1 / 2 : ℚ) * (1 / 2) = 1 / 4 ∧ patch (1 / 2) (1 / 2) = 1 / 4 ∧
      (1 / 4 : ℚ) * (1 / 4) = 1 / 16 ∧ patch (1 / 4) (1 / 4) = 1 / 8 := by
  norm_num

-- Two fair coins: F(X) takes only the values 1/2 and 1, so F(X) ≤ 1/4 never happens.
example : ¬ ((1 / 2 : ℚ) ≤ 1 / 4) ∧ ¬ ((1 : ℚ) ≤ 1 / 4) := by norm_num

#print axioms copula_ext_prod_Iic
#print axioms copula_vol_Icc_isProb
#print axioms copula_isProb
#print axioms copula_fst_preimage
#print axioms copula_snd_preimage
#print axioms copula_vol_compl_Ioo
#print axioms copula_null_compl
#print axioms copula_apply_le_zero_left
#print axioms copula_apply_le_zero_right
#print axioms copula_apply_one_le_left
#print axioms copula_apply_one_le_right
#print axioms copula_eq_of_agree
#print axioms copula_cdf_range
#print axioms copula_pit
#print axioms copula_pit_map
#print axioms copula_cdf_diff_null
#print axioms copulaQf_le_iff
#print axioms copulaQf_measurable
#print axioms copulaQf_map
#print axioms sklar_unique_copula_of_continuous_margins
#print axioms copula_with_any_margins_is_joint_law
#print axioms clayton_lower_tail_dependence
