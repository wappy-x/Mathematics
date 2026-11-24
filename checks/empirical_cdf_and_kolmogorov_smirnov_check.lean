-- The empirical CDF: for independent draws from one law the staircase F_n closes in on the true CDF at every point at once with probability 1 (Glivenko-Cantelli), at each point it is a binomial average with mean F(x) and variance F(x)(1 - F(x))/n, and for a continuous CDF the law of the Kolmogorov-Smirnov gap is the same as for uniform draws.
import Mathlib.Probability.CDF
import Mathlib.Probability.IdentDistrib
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.StrongLaw
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Filter Topology

/-- The empirical CDF (the staircase) of the first `n` draws `X 0 ω, …, X (n-1) ω` at the point
`x`: the share of those draws at or below `x`, `F_n(x) = (1/n) Σ 1{X_i ≤ x}`. -/
noncomputable def empiricalCDF {Ω : Type*} (X : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) (x : ℝ) : ℝ :=
  (1 / (n : ℝ)) * ∑ i ∈ Finset.range n, (Set.Iic x).indicator (fun _ => (1 : ℝ)) (X i ω)

lemma ecdf_indicator_measurable (x : ℝ) :
    Measurable ((Set.Iic x).indicator (fun _ : ℝ => (1 : ℝ))) :=
  measurable_const.indicator measurableSet_Iic

#print axioms ecdf_indicator_measurable

lemma ecdf_integral_indicator {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (Y : Ω → ℝ) (hY : AEMeasurable Y P) (x : ℝ) :
    ∫ ω, (Set.Iic x).indicator (fun _ => (1 : ℝ)) (Y ω) ∂P = cdf (P.map Y) x := by
  rw [← integral_map hY (ecdf_indicator_measurable x).aestronglyMeasurable]
  rw [cdf_eq_real]
  exact integral_indicator_one measurableSet_Iic

#print axioms ecdf_integral_indicator

lemma ecdf_memLp {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (Y : Ω → ℝ) (hY : AEMeasurable Y P) (x : ℝ) :
    MemLp (fun ω => (Set.Iic x).indicator (fun _ => (1 : ℝ)) (Y ω)) 2 P := by
  refine MemLp.of_bound ((ecdf_indicator_measurable x).comp_aemeasurable hY).aestronglyMeasurable
    1 (Eventually.of_forall fun ω => ?_)
  by_cases h : Y ω ∈ Set.Iic x <;> simp [Set.indicator, h]

#print axioms ecdf_memLp

/-- Left limit of the cdf is the mass of the open half-line. -/
lemma ecdf_measureReal_Iio (μ : Measure ℝ) [IsProbabilityMeasure μ] (y : ℝ) :
    μ.real (Set.Iio y) = Function.leftLim (cdf μ) y := by
  have h := StieltjesFunction.measure_Iio (cdf μ) (tendsto_cdf_atBot μ) y
  rw [measure_cdf, sub_zero] at h
  rw [measureReal_def, h, ENNReal.toReal_ofReal]
  exact le_trans (cdf_nonneg μ (y - 1))
    (Monotone.le_leftLim (monotone_cdf μ) (show y - 1 < y by linarith))

#print axioms ecdf_measureReal_Iio

/-- A finite grid adapted to the law: every point is bracketed within `ε`. -/
lemma ecdf_grid (μ : Measure ℝ) [IsProbabilityMeasure μ] {ε : ℝ} (hε : 0 < ε) :
    ∃ T : Finset ℝ, ∀ x : ℝ,
      (cdf μ x ≤ ε ∨ ∃ s ∈ T, s ≤ x ∧ cdf μ x - cdf μ s ≤ ε) ∧
      (1 - cdf μ x ≤ ε ∨ ∃ t ∈ T, x < t ∧ μ.real (Set.Iio t) - cdf μ x ≤ ε) := by
  classical
  set F := cdf μ with hF
  have hFL : ∀ x t, x < t → F x ≤ μ.real (Set.Iio t) := fun x t h => by
    rw [hF, cdf_eq_real]; exact measureReal_mono (Set.Iic_subset_Iio.2 h)
  have hLF : ∀ t, μ.real (Set.Iio t) ≤ F t := fun t => by
    rw [hF, cdf_eq_real]; exact measureReal_mono Set.Iio_subset_Iic_self
  have hmono : Monotone F := monotone_cdf μ
  have hleft : ∀ y, ∃ s, s < y ∧ μ.real (Set.Iio y) - F s ≤ ε := by
    intro y
    have ht := Monotone.tendsto_leftLim hmono y
    rw [← ecdf_measureReal_Iio] at ht
    have hev : ∀ᶠ s in 𝓝[<] y, μ.real (Set.Iio y) - ε < F s :=
      ht.eventually (lt_mem_nhds (by linarith))
    obtain ⟨s, hs1, hs2⟩ := (hev.and self_mem_nhdsWithin).exists
    exact ⟨s, hs2, by linarith⟩
  have hright : ∀ y, ∃ t, y < t ∧ F t - F y ≤ ε := by
    intro y
    have ht : Tendsto F (𝓝[>] y) (𝓝 (F y)) :=
      ((cdf μ).right_continuous y).mono Set.Ioi_subset_Ici_self
    have hev : ∀ᶠ t in 𝓝[>] y, F t < F y + ε := ht.eventually (gt_mem_nhds (by linarith))
    obtain ⟨t, ht1, ht2⟩ := (hev.and self_mem_nhdsWithin).exists
    exact ⟨t, ht2, by linarith⟩
  obtain ⟨a, ha⟩ : ∃ a, F a ≤ ε :=
    ((tendsto_cdf_atBot μ).eventually (gt_mem_nhds hε)).exists.imp fun _ h => h.le
  obtain ⟨b, hb⟩ : ∃ b, 1 - F b ≤ ε := by
    obtain ⟨b, hb⟩ := ((tendsto_cdf_atTop μ).eventually
      (lt_mem_nhds (show 1 - ε < 1 by linarith))).exists
    exact ⟨b, by linarith⟩
  choose sL hsL hsL' using hleft
  choose tR htR htR' using hright
  obtain ⟨I, -, hI⟩ := (isCompact_Icc (a := a) (b := b)).elim_nhds_subcover
    (fun y => Set.Ioo (sL y) (tR y)) (fun y _ => Ioo_mem_nhds (hsL y) (htR y))
  refine ⟨{a, b} ∪ I ∪ I.image sL ∪ I.image tR, fun x => ?_⟩
  have hF0 : 0 ≤ F x := cdf_nonneg μ x
  rcases lt_or_ge x a with hxa | hxa
  · refine ⟨Or.inl (le_trans (hmono hxa.le) ha), Or.inr ⟨a, by simp, hxa, ?_⟩⟩
    linarith [hLF a]
  rcases le_or_gt x b with hxb | hxb
  · have hx : x ∈ ⋃ y ∈ I, Set.Ioo (sL y) (tR y) := hI ⟨hxa, hxb⟩
    simp only [Set.mem_iUnion, Set.mem_Ioo] at hx
    obtain ⟨y, hyI, hsx, hxt⟩ := hx
    rcases lt_or_ge x y with hxy | hxy
    · refine ⟨Or.inr ⟨sL y, Finset.mem_union_left _ (Finset.mem_union_right _ (Finset.mem_image_of_mem sL hyI)), hsx.le, ?_⟩, Or.inr ⟨y, Finset.mem_union_left _ (Finset.mem_union_left _ (Finset.mem_union_right _ hyI)), hxy, ?_⟩⟩
      · linarith [hFL x y hxy, hsL' y]
      · linarith [hmono hsx.le, hsL' y]
    · refine ⟨Or.inr ⟨y, Finset.mem_union_left _ (Finset.mem_union_left _ (Finset.mem_union_right _ hyI)), hxy, ?_⟩, Or.inr ⟨tR y, Finset.mem_union_right _ (Finset.mem_image_of_mem tR hyI), hxt, ?_⟩⟩
      · linarith [hmono hxt.le, htR' y]
      · linarith [hLF (tR y), hmono hxy, htR' y]
  · refine ⟨Or.inr ⟨b, by simp, hxb.le, ?_⟩, Or.inl ?_⟩
    · linarith [cdf_le_one μ x]
    · linarith [hmono hxb.le]

#print axioms ecdf_grid

/-- The strong law for the share of draws landing in a fixed measurable set. -/
lemma ecdf_slln_set {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P) {S : Set ℝ} (hS : MeasurableSet S) :
    ∀ᵐ ω ∂P, Tendsto (fun n : ℕ => (1 / (n : ℝ)) *
      ∑ i ∈ Finset.range n, S.indicator (fun _ => (1 : ℝ)) (X i ω)) atTop
      (𝓝 ((P.map (X 0)).real S)) := by
  set g := S.indicator (fun _ : ℝ => (1 : ℝ)) with hg
  have hgm : Measurable g := measurable_const.indicator hS
  have hX0 : AEMeasurable (X 0) P := (hident 0).aemeasurable_fst
  have hint : Integrable (fun ω => g (X 0 ω)) P := by
    refine Integrable.of_bound (hgm.comp_aemeasurable hX0).aestronglyMeasurable 1
      (Eventually.of_forall fun ω => ?_)
    by_cases h : X 0 ω ∈ S <;> simp [hg, h]
  have hval : ∫ ω, g (X 0 ω) ∂P = (P.map (X 0)).real S := by
    rw [← integral_map hX0 hgm.aestronglyMeasurable]
    exact integral_indicator_one hS
  have h := strong_law_ae_real (fun i ω => g (X i ω)) hint
    (fun i j hij => (hind.comp (fun _ => g) (fun _ => hgm)).indepFun hij)
    (fun i => (hident i).comp hgm)
  filter_upwards [h] with ω hω
  rw [← hval]
  refine hω.congr fun n => ?_
  rw [div_eq_inv_mul, one_div]

#print axioms ecdf_slln_set

/-- The sandwich: control at the grid points gives control everywhere. -/
lemma ecdf_sandwich (F L Fn Ln : ℝ → ℝ) (T : Finset ℝ) {ε δ : ℝ}
    (hmono : Monotone Fn) (hFnL : ∀ x t, x < t → Fn x ≤ Ln t)
    (hFn0 : ∀ x, 0 ≤ Fn x) (hFn1 : ∀ x, Fn x ≤ 1)
    (hT : ∀ x : ℝ, (F x ≤ ε ∨ ∃ s ∈ T, s ≤ x ∧ F x - F s ≤ ε) ∧
      (1 - F x ≤ ε ∨ ∃ t ∈ T, x < t ∧ L t - F x ≤ ε))
    (hS : ∀ s ∈ T, |Fn s - F s| ≤ δ) (hL : ∀ t ∈ T, |Ln t - L t| ≤ δ) (hδ : 0 ≤ δ) (x : ℝ) :
    |Fn x - F x| ≤ ε + δ := by
  rw [abs_le]
  obtain ⟨h1, h2⟩ := hT x
  constructor
  · rcases h1 with h1 | ⟨s, hs, hsx, h1⟩
    · linarith [hFn0 x]
    · have := (abs_le.1 (hS s hs)).1
      linarith [hmono hsx]
  · rcases h2 with h2 | ⟨t, ht, hxt, h2⟩
    · linarith [hFn1 x]
    · have := (abs_le.1 (hL t ht)).2
      linarith [hFnL x t hxt]

#print axioms ecdf_sandwich

lemma ecdf_indicator_le_one (S : Set ℝ) (y : ℝ) :
    S.indicator (fun _ => (1 : ℝ)) y ≤ 1 := by
  by_cases h : y ∈ S <;> simp [Set.indicator, h]

#print axioms ecdf_indicator_le_one

lemma ecdf_avg_nonneg (n : ℕ) (f : ℕ → ℝ) (hf : ∀ i, 0 ≤ f i) :
    0 ≤ (1 / (n : ℝ)) * ∑ i ∈ Finset.range n, f i :=
  mul_nonneg (by positivity) (Finset.sum_nonneg fun i _ => hf i)

#print axioms ecdf_avg_nonneg

lemma ecdf_avg_le_one (n : ℕ) (f : ℕ → ℝ) (hf : ∀ i, f i ≤ 1) :
    (1 / (n : ℝ)) * ∑ i ∈ Finset.range n, f i ≤ 1 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  have hnr : (0 : ℝ) < n := by exact_mod_cast hn
  have : ∑ i ∈ Finset.range n, f i ≤ n := by
    calc ∑ i ∈ Finset.range n, f i ≤ ∑ _i ∈ Finset.range n, (1 : ℝ) :=
          Finset.sum_le_sum fun i _ => hf i
      _ = n := by simp
  rw [one_div, inv_mul_le_iff₀ hnr]
  linarith

#print axioms ecdf_avg_le_one

lemma ecdf_avg_mono (n : ℕ) (f g : ℕ → ℝ) (hfg : ∀ i, f i ≤ g i) :
    (1 / (n : ℝ)) * ∑ i ∈ Finset.range n, f i ≤ (1 / (n : ℝ)) * ∑ i ∈ Finset.range n, g i :=
  mul_le_mul_of_nonneg_left (Finset.sum_le_sum fun i _ => hfg i) (by positivity)

#print axioms ecdf_avg_mono

/-- The staircase is never below 0. -/
lemma ecdf_nonneg {Ω : Type*} (W : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) (u : ℝ) :
    0 ≤ empiricalCDF W n ω u :=
  ecdf_avg_nonneg n _ fun _ => Set.indicator_nonneg (fun _ _ => zero_le_one) _

#print axioms ecdf_nonneg

/-- The staircase is never above 1. -/
lemma ecdf_le_one {Ω : Type*} (W : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) (u : ℝ) :
    empiricalCDF W n ω u ≤ 1 :=
  ecdf_avg_le_one n _ fun _ => ecdf_indicator_le_one _ _

#print axioms ecdf_le_one

/-- A gap between the staircase and a function with values in `[0, 1]` is at most 1. -/
lemma ecdf_gap_bdd {Ω : Type*} (W : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) (c : ℝ → ℝ)
    (hc0 : ∀ u, 0 ≤ c u) (hc1 : ∀ u, c u ≤ 1) :
    BddAbove (Set.range fun u => |empiricalCDF W n ω u - c u|) := by
  refine ⟨1, ?_⟩
  rintro _ ⟨u, rfl⟩
  rw [abs_le]
  constructor <;> linarith [hc0 u, hc1 u, ecdf_nonneg W n ω u, ecdf_le_one W n ω u]

#print axioms ecdf_gap_bdd

/-- The cdf of the uniform law on `[0, 1]` clamps to `[0, 1]`. -/
lemma ecdf_cdf_uniform (ν : Measure ℝ) [IsProbabilityMeasure ν]
    (h : ν = volume.restrict (Set.Icc (0 : ℝ) 1)) (u : ℝ) :
    cdf ν u = max 0 (min u 1) := by
  rw [cdf_eq_real, measureReal_def, h, Measure.restrict_apply measurableSet_Iic]
  rcases lt_or_ge u 0 with hu | hu
  · have : Set.Iic u ∩ Set.Icc (0 : ℝ) 1 = ∅ := by
      ext y
      simp only [Set.mem_inter_iff, Set.mem_Iic, Set.mem_Icc, Set.mem_empty_iff_false, iff_false]
      rintro ⟨h1, h2, _⟩
      linarith
    rw [this, measure_empty, ENNReal.toReal_zero, min_eq_left (by linarith), max_eq_left hu.le]
  rcases le_or_gt u 1 with hu1 | hu1
  · have : Set.Iic u ∩ Set.Icc (0 : ℝ) 1 = Set.Icc 0 u := by
      ext y
      simp only [Set.mem_inter_iff, Set.mem_Iic, Set.mem_Icc]
      constructor
      · rintro ⟨h1, h2, _⟩; exact ⟨h2, h1⟩
      · rintro ⟨h1, h2⟩; exact ⟨h2, h1, by linarith⟩
    rw [this, Real.volume_Icc, ENNReal.toReal_ofReal (by linarith), min_eq_left hu1,
      max_eq_right hu]
    ring
  · have : Set.Iic u ∩ Set.Icc (0 : ℝ) 1 = Set.Icc 0 1 := by
      ext y
      simp only [Set.mem_inter_iff, Set.mem_Iic, Set.mem_Icc]
      constructor
      · rintro ⟨_, h2⟩; exact h2
      · rintro ⟨h1, h2⟩; exact ⟨by linarith, h1, h2⟩
    rw [this, Real.volume_Icc, ENNReal.toReal_ofReal (by norm_num), min_eq_right hu1.le]
    norm_num

#print axioms ecdf_cdf_uniform

/-- For a continuous cdf `F`, the chance that `F(X) ≤ a` is `a` clamped to `[0, 1]`. -/
lemma ecdf_measure_cdf_le (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (hcont : Continuous (cdf μ)) (a : ℝ) :
    μ ((cdf μ) ⁻¹' Set.Iic a) = ENNReal.ofReal (max 0 (min a 1)) := by
  rcases lt_or_ge a 0 with ha | ha
  · have : (cdf μ) ⁻¹' Set.Iic a = ∅ := by
      ext x
      simp only [Set.mem_preimage, Set.mem_Iic, Set.mem_empty_iff_false, iff_false, not_le]
      linarith [cdf_nonneg μ x]
    rw [this, measure_empty, min_eq_left (by linarith), max_eq_left ha.le, ENNReal.ofReal_zero]
  rcases le_or_gt 1 a with ha1 | ha1
  · have : (cdf μ) ⁻¹' Set.Iic a = Set.univ := by
      ext x
      simp only [Set.mem_preimage, Set.mem_Iic, Set.mem_univ, iff_true]
      linarith [cdf_le_one μ x]
    rw [this, measure_univ, min_eq_right ha1, max_eq_right zero_le_one, ENNReal.ofReal_one]
  rw [min_eq_left ha1.le, max_eq_right ha]
  rcases ((cdf μ) ⁻¹' Set.Iic a).eq_empty_or_nonempty with hAe | hAne
  · have hle : a ≤ 0 := by
      by_contra hpos
      push Not at hpos
      obtain ⟨x, hx⟩ := ((tendsto_cdf_atBot μ).eventually (gt_mem_nhds hpos)).exists
      have hxA : x ∈ (cdf μ) ⁻¹' Set.Iic a := hx.le
      rw [hAe] at hxA
      exact hxA
    rw [hAe, measure_empty, ENNReal.ofReal_of_nonpos hle]
  · obtain ⟨b, hb⟩ := eventually_atTop.1 ((tendsto_cdf_atTop μ).eventually (lt_mem_nhds ha1))
    have hbdd : BddAbove ((cdf μ) ⁻¹' Set.Iic a) := by
      refine ⟨b, fun x hx => ?_⟩
      by_contra hxb
      push Not at hxb
      have h1 := hb x hxb.le
      have h2 : cdf μ x ≤ a := hx
      linarith
    have hclosed : IsClosed ((cdf μ) ⁻¹' Set.Iic a) := isClosed_Iic.preimage hcont
    have hcA := hclosed.csSup_mem hAne hbdd
    set c := sSup ((cdf μ) ⁻¹' Set.Iic a) with hc
    have hAeq : (cdf μ) ⁻¹' Set.Iic a = Set.Iic c := by
      ext x
      constructor
      · exact fun hx => le_csSup hbdd hx
      · intro hx
        exact (monotone_cdf μ hx).trans hcA
    have hgt : ∀ y, c < y → a < cdf μ y := by
      intro y hy
      by_contra h
      push Not at h
      exact absurd (le_csSup hbdd (show y ∈ (cdf μ) ⁻¹' Set.Iic a from h)) (not_le.2 hy)
    have hFc : cdf μ c = a := le_antisymm hcA
      (ge_of_tendsto ((hcont.tendsto c).mono_left nhdsWithin_le_nhds)
        (eventually_nhdsWithin_of_forall (s := Set.Ioi c) fun y hy => (hgt y hy).le))
    rw [hAeq, ← ofReal_cdf μ c, hFc]

#print axioms ecdf_measure_cdf_le

/-- **Probability integral transform**: for a continuous cdf, `F(X)` is uniform on `[0, 1]`. -/
lemma ecdf_map_cdf_uniform (μ : Measure ℝ) [IsProbabilityMeasure μ]
    (hcont : Continuous (cdf μ)) (ν : Measure ℝ) [IsProbabilityMeasure ν]
    (hν : ν = volume.restrict (Set.Icc (0 : ℝ) 1)) :
    μ.map (cdf μ) = ν := by
  refine Measure.ext_of_Iic _ _ fun a => ?_
  rw [Measure.map_apply hcont.measurable measurableSet_Iic, ecdf_measure_cdf_le μ hcont a,
    ← ofReal_cdf ν a, ecdf_cdf_uniform ν hν a]

#print axioms ecdf_map_cdf_uniform

/-- The staircase is constant just to the right of any point. -/
lemma ecdf_eventually_right {Ω : Type*} (W : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) (u : ℝ) :
    ∀ᶠ q in 𝓝[>] u, empiricalCDF W n ω q = empiricalCDF W n ω u := by
  have h : ∀ i ∈ Finset.range n, ∀ᶠ q in 𝓝[>] u,
      (Set.Iic q).indicator (fun _ => (1 : ℝ)) (W i ω) =
        (Set.Iic u).indicator (fun _ => (1 : ℝ)) (W i ω) := by
    intro i _
    rcases le_or_gt (W i ω) u with h | h
    · filter_upwards [self_mem_nhdsWithin] with q hq
      rw [Set.indicator_of_mem (show W i ω ∈ Set.Iic q from h.trans (le_of_lt hq)),
        Set.indicator_of_mem (show W i ω ∈ Set.Iic u from h)]
    · filter_upwards [Ioo_mem_nhdsGT h] with q hq
      rw [Set.indicator_of_notMem (show W i ω ∉ Set.Iic q from not_le.2 hq.2),
        Set.indicator_of_notMem (show W i ω ∉ Set.Iic u from not_le.2 h)]
  filter_upwards [(eventually_all_finset _).2 h] with q hq
  unfold empiricalCDF
  rw [Finset.sum_congr rfl hq]

#print axioms ecdf_eventually_right

/-- The gap between the staircase and a cdf is right-continuous. -/
lemma ecdf_tendsto_right {Ω : Type*} (W : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) (c : StieltjesFunction ℝ)
    (u : ℝ) :
    Tendsto (fun q => |empiricalCDF W n ω q - c q|) (𝓝[>] u)
      (𝓝 (|empiricalCDF W n ω u - c u|)) := by
  have h1 : Tendsto (fun q => empiricalCDF W n ω q) (𝓝[>] u) (𝓝 (empiricalCDF W n ω u)) :=
    tendsto_const_nhds.congr' ((ecdf_eventually_right W n ω u).mono fun q hq => hq.symm)
  have h2 : Tendsto (fun q => c q) (𝓝[>] u) (𝓝 (c u)) :=
    (c.right_continuous u).mono Set.Ioi_subset_Ici_self
  exact (h1.sub h2).abs

#print axioms ecdf_tendsto_right

/-- A bounded right-continuous function has the same supremum over the rationals. -/
lemma ecdf_iSup_rat (φ : ℝ → ℝ) (hbdd : BddAbove (Set.range φ))
    (hr : ∀ u, Tendsto φ (𝓝[>] u) (𝓝 (φ u))) :
    ⨆ u, φ u = ⨆ q : ℚ, φ q := by
  have hbddq : BddAbove (Set.range fun q : ℚ => φ q) := by
    obtain ⟨M, hM⟩ := hbdd
    exact ⟨M, by rintro _ ⟨q, rfl⟩; exact hM ⟨q, rfl⟩⟩
  apply le_antisymm
  · refine ciSup_le fun u => ?_
    by_contra hlt
    push Not at hlt
    have hev : ∀ᶠ q in 𝓝[>] u, (⨆ q : ℚ, φ q) < φ q := (hr u).eventually (lt_mem_nhds hlt)
    obtain ⟨u', hu', hsub⟩ := mem_nhdsGT_iff_exists_Ioo_subset.1 hev
    obtain ⟨q, hq1, hq2⟩ := exists_rat_btwn (show u < u' from hu')
    have hq : (⨆ q : ℚ, φ q) < φ q := hsub ⟨hq1, hq2⟩
    exact absurd (le_ciSup hbddq q) (not_le.2 hq)
  · exact ciSup_le fun q => le_ciSup hbdd (q : ℝ)

#print axioms ecdf_iSup_rat

/-- Reading `n` coordinates as a sample gives the same staircase. -/
lemma ecdf_pad_eq {Ω : Type*} (W : ℕ → Ω → ℝ) (n : ℕ) (ω : Ω) (u : ℝ) :
    empiricalCDF (fun i (v : Fin n → ℝ) => if h : i < n then v ⟨i, h⟩ else 0) n
      (fun j : Fin n => W j ω) u = empiricalCDF W n ω u := by
  unfold empiricalCDF
  congr 1
  refine Finset.sum_congr rfl fun i hi => ?_
  simp only [Finset.mem_range.1 hi, ↓reduceDIte]

#print axioms ecdf_pad_eq

/-- The KS gap is a measurable function of the sample. -/
lemma ecdf_ks_measurable (n : ℕ) (C : StieltjesFunction ℝ) (hC0 : ∀ u, 0 ≤ C u)
    (hC1 : ∀ u, C u ≤ 1) :
    Measurable (fun v : Fin n → ℝ => ⨆ u : ℝ,
      |empiricalCDF (fun i (v : Fin n → ℝ) => if h : i < n then v ⟨i, h⟩ else 0) n v u - C u|) := by
  have hE : ∀ i, Measurable (fun v : Fin n → ℝ => if h : i < n then v ⟨i, h⟩ else 0) := by
    intro i
    by_cases h : i < n
    · simp only [h, ↓reduceDIte]
      exact measurable_pi_apply _
    · simp only [h, ↓reduceDIte]
      exact measurable_const
  have hq : ∀ u : ℝ, Measurable (fun v : Fin n → ℝ =>
      empiricalCDF (fun i (v : Fin n → ℝ) => if h : i < n then v ⟨i, h⟩ else 0) n v u) := by
    intro u
    unfold empiricalCDF
    exact (Finset.measurable_sum _ fun i _ =>
      (measurable_const.indicator measurableSet_Iic).comp (hE i)).const_mul _
  have heq : (fun v : Fin n → ℝ => ⨆ u : ℝ,
      |empiricalCDF (fun i (v : Fin n → ℝ) => if h : i < n then v ⟨i, h⟩ else 0) n v u - C u|) =
      fun v => ⨆ q : ℚ,
      |empiricalCDF (fun i (v : Fin n → ℝ) => if h : i < n then v ⟨i, h⟩ else 0) n v q - C q| :=
    funext fun v => ecdf_iSup_rat _ (ecdf_gap_bdd _ n v C hC0 hC1)
      (fun u => ecdf_tendsto_right _ n v C u)
  rw [heq]
  exact Measurable.iSup fun q => continuous_abs.measurable.comp ((hq q).sub_const _)

#print axioms ecdf_ks_measurable

/-- **The Glivenko-Cantelli theorem.** Let `X 0, X 1, X 2, …` be independent draws, all with the
same law, and let `F` be the CDF of that law (`F x` is the chance that one draw is at most `x`).
Then with probability 1 the largest vertical gap between the staircase and the true CDF,
`sup_x |F_n(x) - F(x)|`, tends to 0 as the sample size `n` grows. -/
theorem glivenko_cantelli {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P) :
    ∀ᵐ ω ∂P, Tendsto
      (fun n : ℕ => ⨆ x : ℝ, |empiricalCDF X n ω x - cdf (P.map (X 0)) x|) atTop (𝓝 0) := by
  set μ := P.map (X 0) with hμ
  have hpos : ∀ k : ℕ, (0 : ℝ) < 1 / ((k : ℝ) + 1) := fun k => by positivity
  choose T hT using fun k : ℕ => ecdf_grid μ (hpos k)
  have hae : ∀ᵐ ω ∂P, ∀ k, ∀ t ∈ T k,
      Tendsto (fun n : ℕ => empiricalCDF X n ω t) atTop (𝓝 (cdf μ t)) ∧
      Tendsto (fun n : ℕ => (1 / (n : ℝ)) *
        ∑ i ∈ Finset.range n, (Set.Iio t).indicator (fun _ => (1 : ℝ)) (X i ω)) atTop
        (𝓝 (μ.real (Set.Iio t))) := by
    rw [ae_all_iff]
    intro k
    rw [eventually_all_finset]
    intro t _
    have h1 := ecdf_slln_set X hind hident (measurableSet_Iic (a := t))
    have h2 := ecdf_slln_set X hind hident (measurableSet_Iio (a := t))
    filter_upwards [h1, h2] with ω hω1 hω2
    refine ⟨?_, hω2⟩
    rw [cdf_eq_real]
    exact hω1
  filter_upwards [hae] with ω hω
  set D := fun n : ℕ => ⨆ x : ℝ, |empiricalCDF X n ω x - cdf μ x| with hD
  have hD0 : ∀ n, 0 ≤ D n := fun n => Real.iSup_nonneg fun x => abs_nonneg _
  have hsmall : ∀ ε > 0, ∀ᶠ n in atTop, D n ≤ ε := by
    intro ε hε
    obtain ⟨k, hk⟩ := exists_nat_one_div_lt (half_pos hε)
    have hev : ∀ᶠ n in atTop, ∀ t ∈ T k,
        |empiricalCDF X n ω t - cdf μ t| ≤ ε / 2 ∧
        |(1 / (n : ℝ)) * ∑ i ∈ Finset.range n, (Set.Iio t).indicator (fun _ => (1 : ℝ)) (X i ω)
          - μ.real (Set.Iio t)| ≤ ε / 2 := by
      rw [eventually_all_finset]
      intro t ht
      obtain ⟨h1, h2⟩ := hω k t ht
      have e1 := Metric.tendsto_nhds.1 h1 (ε / 2) (half_pos hε)
      have e2 := Metric.tendsto_nhds.1 h2 (ε / 2) (half_pos hε)
      filter_upwards [e1, e2] with n hn1 hn2
      rw [Real.dist_eq] at hn1 hn2
      exact ⟨hn1.le, hn2.le⟩
    filter_upwards [hev] with n hn
    have key : ∀ x, |empiricalCDF X n ω x - cdf μ x| ≤ 1 / ((k : ℝ) + 1) + ε / 2 := by
      refine ecdf_sandwich (cdf μ) (fun t => μ.real (Set.Iio t)) (fun x => empiricalCDF X n ω x)
        (fun t => (1 / (n : ℝ)) *
          ∑ i ∈ Finset.range n, (Set.Iio t).indicator (fun _ => (1 : ℝ)) (X i ω)) (T k)
        ?_ ?_ ?_ ?_ (hT k) (fun s hs => (hn s hs).1) (fun t ht => (hn t ht).2)
        (half_pos hε).le
      · intro x y hxy
        exact ecdf_avg_mono n _ _ fun i =>
          Set.indicator_le_indicator_of_subset (Set.Iic_subset_Iic.2 hxy) (fun _ => zero_le_one) _
      · intro x t hxt
        exact ecdf_avg_mono n _ _ fun i =>
          Set.indicator_le_indicator_of_subset (Set.Iic_subset_Iio.2 hxt) (fun _ => zero_le_one) _
      · intro x
        exact ecdf_avg_nonneg n _ fun i => Set.indicator_nonneg (fun _ _ => zero_le_one) _
      · intro x
        exact ecdf_avg_le_one n _ fun i => ecdf_indicator_le_one _ _
    refine ciSup_le fun x => (key x).trans ?_
    linarith
  refine tendsto_order.2 ⟨fun a ha => Eventually.of_forall fun n => lt_of_lt_of_le ha (hD0 n),
    fun a ha => (hsmall (a / 2) (half_pos ha)).mono fun n hn => lt_of_le_of_lt hn (half_lt_self ha)⟩

/-- **At one point the staircase is a binomial average.** Let `X 0, X 1, …` be independent draws,
all with the same law with CDF `F`, and fix a point `x` and a sample size `n ≥ 1`. Then the
staircase's height `F_n(x)` is right on average, `E[F_n(x)] = F(x)`, and its variance is
`F(x)(1 - F(x))/n`. -/
theorem empirical_cdf_mean_and_variance {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (X : ℕ → Ω → ℝ)
    (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P) (x : ℝ) {n : ℕ} (hn : 1 ≤ n) :
    ∫ ω, empiricalCDF X n ω x ∂P = cdf (P.map (X 0)) x ∧
      variance (fun ω => empiricalCDF X n ω x) P =
        cdf (P.map (X 0)) x * (1 - cdf (P.map (X 0)) x) / n := by
  set g := (Set.Iic x).indicator (fun _ : ℝ => (1 : ℝ)) with hg
  have hgm : Measurable g := ecdf_indicator_measurable x
  have hXm : ∀ i, AEMeasurable (X i) P := fun i => (hident i).aemeasurable_fst
  have hint : ∀ i, ∫ ω, g (X i ω) ∂P = cdf (P.map (X 0)) x := by
    intro i
    rw [ecdf_integral_indicator _ (hXm i), (hident i).map_eq]
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  have hmem : ∀ i, MemLp (fun ω => g (X i ω)) 2 P := fun i => ecdf_memLp _ (hXm i) x
  set p := cdf (P.map (X 0)) x with hp
  constructor
  · unfold empiricalCDF
    rw [integral_const_mul, integral_finsetSum _ (fun i _ => (hmem i).integrable one_le_two)]
    simp only [hint, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    field_simp
  · unfold empiricalCDF
    rw [variance_const_mul]
    have hsum : (fun ω => ∑ i ∈ Finset.range n, g (X i ω))
        = ∑ i ∈ Finset.range n, (fun ω => g (X i ω)) := by
      ext ω; simp
    rw [hsum, IndepFun.variance_sum (fun i _ => hmem i)]
    · have hv : ∀ i, variance (fun ω => g (X i ω)) P = p * (1 - p) := by
        intro i
        rw [variance_eq_sub (hmem i)]
        have hsq : ((fun ω => g (X i ω)) ^ 2) = fun ω => g (X i ω) := by
          ext ω
          rw [Pi.pow_apply]
          rcases em (X i ω ∈ Set.Iic x) with h | h
          · rw [hg, Set.indicator_of_mem h]; norm_num
          · rw [hg, Set.indicator_of_notMem h]; norm_num
        rw [hsq, hint i]
        ring
      simp only [hv, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
      field_simp
    · intro i _ j _ hij
      exact (hind.comp (fun _ => g) (fun _ => hgm)).indepFun hij

/-- **The null law of the KS gap does not depend on the shape.** Let `X 0, X 1, …` be independent
draws, all with one law whose CDF `F` is continuous, and let `U 0, U 1, …` be independent draws,
all uniform on `[0, 1]` (on any probability space). Then for every sample size `n`, the
one-sample KS gap `D_n = sup_x |F_n(x) - F(x)|` of the `X`s has exactly the same law as the KS gap
of the uniforms against the uniform CDF. So one table serves every continuous model. -/
theorem ks_null_law_distribution_free {Ω Ω' : Type*} [MeasurableSpace Ω] [MeasurableSpace Ω']
    {P : Measure Ω} [IsProbabilityMeasure P] {P' : Measure Ω'} [IsProbabilityMeasure P']
    (X : ℕ → Ω → ℝ) (hind : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    (hcont : Continuous (cdf (P.map (X 0))))
    (U : ℕ → Ω' → ℝ) (hindU : iIndepFun U P')
    (hidentU : ∀ i, IdentDistrib (U i) (U 0) P' P')
    (hunif : P'.map (U 0) = volume.restrict (Set.Icc (0 : ℝ) 1)) (n : ℕ) :
    P.map (fun ω => ⨆ x : ℝ, |empiricalCDF X n ω x - cdf (P.map (X 0)) x|) =
      P'.map (fun ω => ⨆ u : ℝ, |empiricalCDF U n ω u - cdf (P'.map (U 0)) u|) := by
  set μ := P.map (X 0) with hμ
  set F := cdf μ with hF
  set C := cdf (P'.map (U 0)) with hC
  have hCval : ∀ u, C u = max 0 (min u 1) := ecdf_cdf_uniform _ hunif
  have hCF : ∀ x, C (F x) = F x := fun x => by
    rw [hCval, min_eq_left (cdf_le_one μ x), max_eq_right (cdf_nonneg μ x)]
  have hXm : ∀ i, AEMeasurable (X i) P := fun i => (hident i).aemeasurable_fst
  have hUm : ∀ i, AEMeasurable (U i) P' := fun i => (hidentU i).aemeasurable_fst
  have hFm : Measurable F := hcont.measurable
  -- each `F(X i)` is uniform
  have hlaw : ∀ i, P.map (fun ω => F (X i ω)) = P'.map (U 0) := by
    intro i
    rw [show (fun ω => F (X i ω)) = F ∘ X i from rfl,
      ← AEMeasurable.map_map_of_aemeasurable hFm.aemeasurable (hXm i), (hident i).map_eq]
    exact ecdf_map_cdf_uniform μ hcont _ hunif
  -- the joint laws of the first `n` coordinates agree
  have hVm : AEMeasurable (fun ω (j : Fin n) => F (X j ω)) P :=
    AEMeasurable.of_eval fun j => hFm.comp_aemeasurable (hXm j)
  have hWm : AEMeasurable (fun ω (j : Fin n) => U j ω) P' :=
    AEMeasurable.of_eval fun j => hUm j
  have hindV : iIndepFun (fun (j : Fin n) ω => F (X j ω)) P :=
    (hind.comp (fun _ => F) (fun _ => hFm)).precomp Fin.val_injective
  have hindW : iIndepFun (fun (j : Fin n) ω => U j ω) P' := hindU.precomp Fin.val_injective
  have hlawV : P.map (fun ω (j : Fin n) => F (X j ω)) =
      Measure.pi (fun _ : Fin n => P'.map (U 0)) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map (f := fun (j : Fin n) ω => F (X j ω))
      (fun j => hFm.comp_aemeasurable (hXm j))).1 hindV]
    congr 1
    funext j
    exact hlaw j
  have hlawW : P'.map (fun ω (j : Fin n) => U j ω) =
      Measure.pi (fun _ : Fin n => P'.map (U 0)) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map (f := fun (j : Fin n) ω => U j ω)
      (fun j => hUm j)).1 hindW]
    congr 1
    funext j
    exact (hidentU j).map_eq
  -- the gap as a function of the sample
  have hHm := ecdf_ks_measurable n C (cdf_nonneg _) (cdf_le_one _)
  set H := (fun v : Fin n → ℝ => ⨆ u : ℝ,
      |empiricalCDF (fun i (v : Fin n → ℝ) => if h : i < n then v ⟨i, h⟩ else 0) n v u - C u|)
    with hH
  have hDU : (fun ω => ⨆ u : ℝ, |empiricalCDF U n ω u - C u|) =
      H ∘ (fun ω (j : Fin n) => U j ω) := by
    funext ω
    simp only [Function.comp, hH, ecdf_pad_eq U n ω]
  -- almost surely no draw lands on a flat stretch of `F`
  have hgood : ∀ᵐ ω ∂P, ∀ i, ∀ q : ℚ, F (X i ω) ≠ F q := by
    rw [ae_all_iff]
    intro i
    rw [ae_all_iff]
    intro q
    have h0 : P ((fun ω => F (X i ω)) ⁻¹' {F q}) = 0 := by
      rw [← Measure.map_apply_of_aemeasurable
        (show AEMeasurable (fun ω => F (X i ω)) P from hFm.comp_aemeasurable (hXm i))
        (measurableSet_singleton _), hlaw i, hunif,
        Measure.restrict_apply (measurableSet_singleton _)]
      exact measure_mono_null Set.inter_subset_left (Real.volume_singleton)
    rw [ae_iff]
    exact measure_mono_null (fun ω hω => by simpa using hω) h0
  have hae : (fun ω => ⨆ x : ℝ, |empiricalCDF X n ω x - F x|) =ᵐ[P]
      H ∘ (fun ω (j : Fin n) => F (X j ω)) := by
    filter_upwards [hgood] with ω hω
    simp only [Function.comp, hH, ecdf_pad_eq (fun i ω => F (X i ω)) n ω]
    have hK : ∀ x, empiricalCDF X n ω x = empiricalCDF (fun i ω => F (X i ω)) n ω (F x) := by
      intro x
      unfold empiricalCDF
      congr 1
      refine Finset.sum_congr rfl fun i _ => ?_
      have hiff : X i ω ≤ x ↔ F (X i ω) ≤ F x := by
        constructor
        · exact fun h => monotone_cdf μ h
        · intro h
          by_contra hlt
          push Not at hlt
          obtain ⟨q, hq1, hq2⟩ := exists_rat_btwn hlt
          have e1 : F x ≤ F q := monotone_cdf μ hq1.le
          have e2 : F q ≤ F (X i ω) := monotone_cdf μ hq2.le
          exact hω i q (le_antisymm (h.trans e1) e2)
      by_cases h : X i ω ≤ x
      · rw [Set.indicator_of_mem (show X i ω ∈ Set.Iic x from h),
          Set.indicator_of_mem (show F (X i ω) ∈ Set.Iic (F x) from hiff.1 h)]
      · rw [Set.indicator_of_notMem (show X i ω ∉ Set.Iic x from h),
          Set.indicator_of_notMem (show F (X i ω) ∉ Set.Iic (F x) from fun h' => h (hiff.2 h'))]
    have hbddD := ecdf_gap_bdd X n ω F (cdf_nonneg μ) (cdf_le_one μ)
    have hbddG := ecdf_gap_bdd (fun i ω => F (X i ω)) n ω C (cdf_nonneg _) (cdf_le_one _)
    have hD0 : 0 ≤ ⨆ x : ℝ, |empiricalCDF X n ω x - F x| :=
      Real.iSup_nonneg fun _ => abs_nonneg _
    have hDge : ∀ x, |empiricalCDF X n ω x - F x| ≤ ⨆ x : ℝ, |empiricalCDF X n ω x - F x| :=
      fun x => le_ciSup hbddD x
    apply le_antisymm
    · refine ciSup_le fun x => ?_
      have h1 := le_ciSup hbddG (F x)
      rw [hCF x] at h1
      rw [hK x]
      exact h1
    · refine ciSup_le fun u => ?_
      rcases lt_or_ge u 0 with hu | hu
      · have hG : empiricalCDF (fun i ω => F (X i ω)) n ω u = 0 := by
          unfold empiricalCDF
          rw [Finset.sum_eq_zero fun i _ => Set.indicator_of_notMem
            (show F (X i ω) ∉ Set.Iic u from not_le.2 (lt_of_lt_of_le hu (cdf_nonneg μ _))) _,
            mul_zero]
        rw [hG, hCval, min_eq_left (by linarith), max_eq_left hu.le, sub_zero, abs_zero]
        exact hD0
      rcases le_or_gt 1 u with hu1 | hu1
      · rcases Nat.eq_zero_or_pos n with hn | hn
        · have hG : empiricalCDF (fun i ω => F (X i ω)) n ω u = 0 := by
            simp [empiricalCDF, hn]
          rw [hG, hCval, min_eq_right hu1, max_eq_right zero_le_one]
          rw [zero_sub, abs_neg, abs_one]
          refine le_of_tendsto (tendsto_cdf_atTop μ) (Eventually.of_forall fun x => ?_)
          have h1 := hDge x
          have e : empiricalCDF X n ω x = 0 := by simp [empiricalCDF, hn]
          rwa [e, zero_sub, abs_neg, abs_of_nonneg (cdf_nonneg μ x)] at h1
        · have hG : empiricalCDF (fun i ω => F (X i ω)) n ω u = 1 := by
            unfold empiricalCDF
            rw [Finset.sum_congr rfl fun i _ => Set.indicator_of_mem
              (show F (X i ω) ∈ Set.Iic u from (cdf_le_one μ _).trans hu1) _]
            have hnr : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
            simp only [Finset.sum_const, Finset.card_range, nsmul_eq_mul, mul_one]
            field_simp
          rw [hG, hCval, min_eq_right hu1, max_eq_right zero_le_one, sub_self, abs_zero]
          exact hD0
      · refine le_of_tendsto (ecdf_tendsto_right (fun i ω => F (X i ω)) n ω C u) ?_
        filter_upwards [Ioo_mem_nhdsGT hu1] with q hq
        have hq0 : (0 : ℝ) < q := lt_of_le_of_lt hu hq.1
        obtain ⟨x, hx⟩ := mem_range_of_exists_le_of_exists_ge hcont
          (((tendsto_cdf_atBot μ).eventually (gt_mem_nhds hq0)).exists.imp fun _ h => h.le)
          (((tendsto_cdf_atTop μ).eventually (lt_mem_nhds hq.2)).exists.imp fun _ h => h.le)
        rw [← hx, ← hK x, hCF x]
        exact hDge x
  rw [Measure.map_congr hae, ← AEMeasurable.map_map_of_aemeasurable hHm.aemeasurable hVm, hlawV,
    hDU, ← AEMeasurable.map_map_of_aemeasurable hHm.aemeasurable hWm, hlawW]

-- The coffee shops, waits in tenths of a minute: A 1.2, …, 5.0 min and B 2.6, …, 7.0 min.
-- By 3.1 min, 5 of A's 8 customers and 1 of B's 8 have coffee: gap 5/8 - 1/8 = 4/8 = 1/2.
example : ([12, 19, 24, 28, 31, 35, 42, 50].filter (fun t : ℕ => t ≤ 31)).length = 5 := by decide
example : ([26, 33, 39, 44, 48, 55, 61, 70].filter (fun t : ℕ => t ≤ 31)).length = 1 := by decide
example : (5 / 8 - 1 / 8 : ℚ) = 1 / 2 := by norm_num
-- Read at every one of the 16 pooled waits, the largest count gap is 4 (of 8), and no gap is larger.
example : ∀ t ∈ [12, 19, 24, 28, 31, 35, 42, 50, 26, 33, 39, 44, 48, 55, 61, 70],
    Int.natAbs (([12, 19, 24, 28, 31, 35, 42, 50].filter (fun s : ℕ => s ≤ t)).length -
      ([26, 33, 39, 44, 48, 55, 61, 70].filter (fun s : ℕ => s ≤ t)).length : ℤ) ≤ 4 := by
  decide
example : Int.natAbs (([12, 19, 24, 28, 31, 35, 42, 50].filter (fun s : ℕ => s ≤ 35)).length -
      ([26, 33, 39, 44, 48, 55, 61, 70].filter (fun s : ℕ => s ≤ 35)).length : ℤ) = 4 ∧
    Int.natAbs (([12, 19, 24, 28, 31, 35, 42, 50].filter (fun s : ℕ => s ≤ 42)).length -
      ([26, 33, 39, 44, 48, 55, 61, 70].filter (fun s : ℕ => s ≤ 42)).length : ℤ) = 4 := by
  decide
-- All splits of the 16 waits into two groups of 8, and the lattice-path count: paths of 8 up and
-- 8 right steps that never stray 4 or more from the diagonal number 9,232, so 3,638 splits
-- have a gap of at least 4/8.
example : Nat.choose 16 8 = 12870 := by decide

/-- One row of the lattice-path count. Entry `i` of row `j` counts the paths of up and right
unit steps from `(0, 0)` to `(i, j)` that keep every point within distance 3 of the diagonal
(`|i - j| ≤ 3`), that is, whose gap never reaches 4/8; it adds the entry below and the entry to
the left. -/
def ksStep (j : ℕ) (prev : List ℕ) : List ℕ :=
  (List.range 9).foldl
    (fun acc i => acc ++ [if i ≤ j + 3 ∧ j ≤ i + 3 then prev.getD i 0 + acc.getLastD 0 else 0]) []

/-- Rows `0, 1, …, j` of the lattice-path count, built one on top of the other. -/
def ksRows : ℕ → List ℕ
  | 0 => ksStep 0 [1]
  | j + 1 => ksStep (j + 1) (ksRows j)

example : (ksRows 8).getD 8 0 = 9232 := by decide
example : Nat.choose 16 8 - 9232 = 3638 := by decide
-- Kolmogorov's scale for two samples of 8: nm/(n+m) = 64/16 = 4 = 2², so λ = 2 · 1/2 = 1.
example : ((8 * 8 : ℚ) / (8 + 8) = 2 ^ 2) ∧ (2 * (1 / 2) : ℚ) = 1 := by norm_num
-- The DKW band at n = 8, α = 5%: ε² = ln 40 / 16 makes the Massart bound 2e^(-2nε²) exactly 1/20.
example : 2 * Real.exp (-(2 * 8 * (Real.log 40 / 16))) = 1 / 20 := by
  rw [show 2 * 8 * (Real.log 40 / 16) = Real.log 40 by ring, Real.exp_neg,
    Real.exp_log (by norm_num)]
  norm_num

#print axioms glivenko_cantelli
#print axioms empirical_cdf_mean_and_variance
#print axioms ks_null_law_distribution_free
