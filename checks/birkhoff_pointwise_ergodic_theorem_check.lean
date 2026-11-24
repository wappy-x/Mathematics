-- Birkhoff's ergodic theorem: for a map that keeps a probability measure and an integrable f, the orbit averages of f converge almost everywhere and in L1 to the conditional expectation of f on the invariant sets, which is the integral of f when the map is ergodic.
import Mathlib.Dynamics.BirkhoffSum.Average
import Mathlib.Dynamics.Ergodic.Ergodic
import Mathlib.MeasureTheory.MeasurableSpace.Invariants
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Dynamics.BirkhoffSum.QuasiMeasurePreserving
import Mathlib.Dynamics.Ergodic.Function
import Mathlib.Dynamics.Ergodic.AddCircle
import Mathlib.MeasureTheory.Function.Floor

open MeasureTheory Filter Topology

section BirkhoffHelpers

variable {X : Type*} [MeasurableSpace X] {μ : Measure X} {T : X → X}

theorem bk_measurable_birkhoffSum (hT : Measurable T) {f : X → ℝ} (hf : Measurable f) (n : ℕ) :
    Measurable (birkhoffSum T f n) :=
  Finset.measurable_sum _ fun k _ => hf.comp (hT.iterate k)

theorem bk_integrable_birkhoffSum (hT : MeasurePreserving T μ μ) {f : X → ℝ}
    (hf : Integrable f μ) (n : ℕ) : Integrable (birkhoffSum T f n) μ :=
  integrable_finsetSum _ fun k _ => (hT.iterate k).integrable_comp_of_integrable hf

theorem bk_integral_comp (hT : MeasurePreserving T μ μ) {g : X → ℝ}
    (hg : AEStronglyMeasurable g μ) : ∫ x, g (T x) ∂μ = ∫ x, g x ∂μ := by
  rw [← integral_map hT.measurable.aemeasurable (by rwa [hT.map_eq]), hT.map_eq]

theorem bk_maximal_of_measurable (hT : MeasurePreserving T μ μ) {f : X → ℝ}
    (hfm : Measurable f) (hf : Integrable f μ) (N : ℕ) :
    0 ≤ ∫ x in {x | ∃ n ∈ Finset.Icc 1 N, 0 < birkhoffSum T f n x}, f x ∂μ := by
  set E := {x | ∃ n ∈ Finset.Icc 1 N, 0 < birkhoffSum T f n x} with hE
  have hS : ∀ n, Measurable (birkhoffSum T f n) := bk_measurable_birkhoffSum hT.measurable hfm
  have hEm : MeasurableSet E := by
    have : E = ⋃ n ∈ Finset.Icc 1 N, {x | 0 < birkhoffSum T f n x} := by ext x; simp [E]
    rw [this]
    exact Finset.measurableSet_biUnion _ fun n _ => measurableSet_lt measurable_const (hS n)
  set M : X → ℝ := fun x =>
    (Finset.range (N + 1)).sup' Finset.nonempty_range_add_one (fun n => birkhoffSum T f n x)
    with hM
  have hMm : Measurable M := by
    have := Finset.measurable_range_sup' (f := fun n => birkhoffSum T f n) (n := N)
      (fun k _ => hS k)
    convert this using 1
    ext x
    simp [M, Finset.sup'_apply]
  have hM0 : ∀ x, 0 ≤ M x := fun x => by
    have := Finset.le_sup' (fun n => birkhoffSum T f n x)
      (Finset.mem_range.2 (Nat.succ_pos N))
    simpa [birkhoffSum_zero_apply] using this
  have hMle : ∀ x, M x ≤ ∑ n ∈ Finset.range (N + 1), |birkhoffSum T f n x| := fun x =>
    Finset.sup'_le _ _ fun n hn =>
      (le_abs_self _).trans (Finset.single_le_sum (f := fun i => |birkhoffSum T f i x|) (fun i _ => abs_nonneg _) hn)
  have hMi : Integrable M μ := by
    refine Integrable.mono' (g := fun x => ∑ n ∈ Finset.range (N + 1), |birkhoffSum T f n x|)
      ?_ hMm.aestronglyMeasurable ?_
    · exact integrable_finsetSum _ fun n _ => (bk_integrable_birkhoffSum hT hf n).abs
    · exact Eventually.of_forall fun x => by
        rw [Real.norm_eq_abs, abs_of_nonneg (hM0 x)]; exact hMle x
  have hMTi : Integrable (fun x => M (T x)) μ := hT.integrable_comp_of_integrable hMi
  have key : ∀ x, M x - M (T x) ≤ E.indicator f x := by
    intro x
    by_cases hx : x ∈ E
    · rw [Set.indicator_of_mem hx]
      obtain ⟨m, hm, hmeq⟩ := Finset.exists_mem_eq_sup' Finset.nonempty_range_add_one
        (fun n => birkhoffSum T f n x)
      obtain ⟨n, hn, hpos⟩ := hx
      have hnM : birkhoffSum T f n x ≤ M x :=
        Finset.le_sup' (fun n => birkhoffSum T f n x)
          (by simp only [Finset.mem_Icc] at hn; simp only [Finset.mem_range]; omega)
      have hMx : M x = birkhoffSum T f m x := hmeq
      obtain ⟨k, rfl⟩ : ∃ k, m = k + 1 := by
        rcases m with _ | k
        · rw [hMx, birkhoffSum_zero_apply] at hnM; linarith
        · exact ⟨k, rfl⟩
      have hk : birkhoffSum T f k (T x) ≤ M (T x) :=
        Finset.le_sup' (fun n => birkhoffSum T f n (T x))
          (by simp only [Finset.mem_range] at hm ⊢; omega)
      rw [hMx, birkhoffSum_succ_apply']
      linarith
    · rw [Set.indicator_of_notMem hx]
      have hle : M x ≤ 0 := by
        refine Finset.sup'_le _ _ fun n hn => ?_
        rcases n with _ | n
        · simp [birkhoffSum_zero_apply]
        · by_contra hc
          exact hx ⟨n + 1, by simp only [Finset.mem_range] at hn; simp; omega, by linarith⟩
      linarith [hM0 (T x)]
  have h1 : ∫ x, (M x - M (T x)) ∂μ = 0 := by
    rw [integral_sub hMi hMTi, bk_integral_comp hT hMi.1, sub_self]
  have h2 := integral_mono (hMi.sub hMTi) (hf.indicator hEm) key
  rw [integral_indicator hEm] at h2
  have : ∫ x, (M - fun x => M (T x)) x ∂μ = ∫ x, (M x - M (T x)) ∂μ := rfl
  linarith

theorem bk_maximal (hT : MeasurePreserving T μ μ) {f : X → ℝ} (hf : Integrable f μ) (N : ℕ) :
    0 ≤ ∫ x in {x | ∃ n ∈ Finset.Icc 1 N, 0 < birkhoffSum T f n x}, f x ∂μ := by
  set g := hf.1.mk f
  have hfg : f =ᵐ[μ] g := hf.1.ae_eq_mk
  have hgm : Measurable g := hf.1.stronglyMeasurable_mk.measurable
  have hgi : Integrable g μ := hf.congr hfg
  have hS : ∀ᵐ x ∂μ, ∀ n, birkhoffSum T f n x = birkhoffSum T g n x :=
    ae_all_iff.2 fun n => hT.quasiMeasurePreserving.birkhoffSum_ae_eq_of_ae_eq hfg n
  have hset : {x | ∃ n ∈ Finset.Icc 1 N, 0 < birkhoffSum T f n x} =ᵐ[μ]
      {x | ∃ n ∈ Finset.Icc 1 N, 0 < birkhoffSum T g n x} := by
    refine eventuallyEqSet_iff.2 ?_
    filter_upwards [hS] with x hx
    simp only [hx]
  rw [setIntegral_congr_set hset, integral_congr_ae (ae_restrict_of_ae hfg)]
  exact bk_maximal_of_measurable hT hgm hgi N

theorem bk_invariant_bound [IsFiniteMeasure μ] (hT : MeasurePreserving T μ μ) {f : X → ℝ}
    (hfm : Measurable f) (hf : Integrable f μ) {D : Set X} (hDm : MeasurableSet D)
    (hDT : T ⁻¹' D = D) (c : ℝ)
    (hD : ∀ x ∈ D, ∃ n : ℕ, 1 ≤ n ∧ (n : ℝ) * c < birkhoffSum T f n x) :
    c * μ.real D ≤ ∫ x in D, f x ∂μ := by
  set g : X → ℝ := D.indicator (fun x => f x - c) with hg
  have hgm : Measurable g := (hfm.sub measurable_const).indicator hDm
  have hgi : Integrable g μ := (hf.sub (integrable_const c)).indicator hDm
  have hiter : ∀ k x, T^[k] x ∈ D ↔ x ∈ D := by
    intro k
    induction k with
    | zero => intro x; rfl
    | succ k ih =>
      intro x
      rw [Function.iterate_succ_apply, ih]
      exact Set.ext_iff.1 hDT x
  have hSg : ∀ n x, birkhoffSum T g n x =
      D.indicator (fun x => birkhoffSum T f n x - n * c) x := by
    intro n x
    by_cases hx : x ∈ D
    · rw [Set.indicator_of_mem hx]
      rw [show birkhoffSum T g n x = ∑ k ∈ Finset.range n, (f (T^[k] x) - c) from
        Finset.sum_congr rfl fun k _ => Set.indicator_of_mem ((hiter k x).2 hx) _]
      simp [Finset.sum_sub_distrib, birkhoffSum]
    · rw [Set.indicator_of_notMem hx]
      exact Finset.sum_eq_zero fun k _ =>
        Set.indicator_of_notMem (fun h => hx ((hiter k x).1 h)) _
  set E : ℕ → Set X := fun N => {x | ∃ n ∈ Finset.Icc 1 N, 0 < birkhoffSum T g n x} with hE
  have hEsub : ∀ N, E N ⊆ D := by
    rintro N x ⟨n, _, hn⟩
    by_contra hx
    rw [hSg, Set.indicator_of_notMem hx] at hn
    exact lt_irrefl _ hn
  have hSm := bk_measurable_birkhoffSum hT.measurable hgm
  have hEm : ∀ N, MeasurableSet (E N) := by
    intro N
    have : E N = ⋃ n ∈ Finset.Icc 1 N, {x | 0 < birkhoffSum T g n x} := by ext x; simp [E]
    rw [this]
    exact Finset.measurableSet_biUnion _ fun n _ => measurableSet_lt measurable_const (hSm n)
  have hmono : Monotone E := by
    rintro N M hNM x ⟨n, hn, h⟩
    exact ⟨n, by simp only [Finset.mem_Icc] at hn ⊢; omega, h⟩
  have hU : ⋃ N, E N = D := by
    apply Set.Subset.antisymm (Set.iUnion_subset hEsub)
    intro x hx
    obtain ⟨n, hn1, hn⟩ := hD x hx
    refine Set.mem_iUnion.2 ⟨n, n, by simp only [Finset.mem_Icc]; omega, ?_⟩
    rw [hSg, Set.indicator_of_mem hx]
    linarith
  have h0 : ∀ N, 0 ≤ ∫ x in E N, (f x - c) ∂μ := by
    intro N
    calc 0 ≤ ∫ x in E N, g x ∂μ := bk_maximal_of_measurable hT hgm hgi N
      _ = ∫ x in E N, (f x - c) ∂μ :=
        setIntegral_congr_fun (hEm N) (fun x hx => Set.indicator_of_mem (hEsub N hx) _)
  have hlim := tendsto_setIntegral_of_monotone (μ := μ) (f := fun x => f x - c) hEm hmono
    (by rw [hU]; exact (hf.sub (integrable_const c)).integrableOn)
  rw [hU] at hlim
  have h1 : 0 ≤ ∫ x in D, (f x - c) ∂μ := ge_of_tendsto' hlim h0
  rw [integral_sub hf.integrableOn (integrable_const c), setIntegral_const, smul_eq_mul] at h1
  linarith

theorem bk_upper [IsFiniteMeasure μ] (hT : MeasurePreserving T μ μ) {h : X → ℝ}
    (hm : Measurable h) (hi : Integrable h μ)
    (h0 : ∀ D, MeasurableSet D → T ⁻¹' D = D → ∫ x in D, h x ∂μ = 0) {c : ℝ} (hc : 0 < c) :
    ∀ᵐ x ∂μ, ∃ K : ℕ, ∀ n : ℕ, birkhoffSum T h n x ≤ c * n + K := by
  set D : Set X := {x | ∀ K : ℕ, ∃ n : ℕ, (K : ℝ) < birkhoffSum T h n x - c * n} with hD
  have hS := bk_measurable_birkhoffSum hT.measurable hm
  have hDm : MeasurableSet D := by
    have : D = ⋂ K : ℕ, ⋃ n : ℕ, {x | (K : ℝ) < birkhoffSum T h n x - c * n} := by
      ext x; simp [D]
    rw [this]
    exact MeasurableSet.iInter fun K => MeasurableSet.iUnion fun n =>
      measurableSet_lt measurable_const ((hS n).sub measurable_const)
  have hDT : T ⁻¹' D = D := by
    ext x
    simp only [Set.mem_preimage, D, Set.mem_ofPred_eq]
    constructor
    · intro hx K
      obtain ⟨K', hK'⟩ := exists_nat_ge ((K : ℝ) - (h x - c))
      obtain ⟨n, hn⟩ := hx K'
      refine ⟨n + 1, ?_⟩
      rw [birkhoffSum_succ_apply']
      push_cast
      linarith
    · intro hx K
      obtain ⟨K', hK'⟩ := exists_nat_ge ((K : ℝ) + (h x - c))
      obtain ⟨n, hn⟩ := hx K'
      rcases n with _ | k
      · exfalso
        rw [birkhoffSum_zero_apply, Nat.cast_zero, mul_zero, sub_zero] at hn
        exact absurd hn (not_lt.2 (Nat.cast_nonneg _))
      · refine ⟨k, ?_⟩
        rw [birkhoffSum_succ_apply'] at hn
        push_cast at hn
        linarith
  have hDbound : c * μ.real D ≤ ∫ x in D, h x ∂μ := by
    refine bk_invariant_bound hT hm hi hDm hDT c fun x hx => ?_
    obtain ⟨n, hn⟩ := hx 0
    rcases n with _ | k
    · exfalso
      rw [birkhoffSum_zero_apply] at hn
      simp at hn
    · exact ⟨k + 1, by omega, by push_cast at hn ⊢; linarith⟩
  have hμD : μ D = 0 := by
    rw [h0 D hDm hDT] at hDbound
    have hle : μ.real D ≤ 0 := by
      by_contra hcon
      linarith [mul_pos hc (lt_of_not_ge hcon)]
    exact (measureReal_eq_zero_iff).1 (le_antisymm hle measureReal_nonneg)
  filter_upwards [measure_eq_zero_iff_ae_notMem.1 hμD] with x hx
  simp only [D, Set.mem_ofPred_eq, not_forall, not_exists, not_lt] at hx
  obtain ⟨K, hK⟩ := hx
  exact ⟨K, fun n => by linarith [hK n]⟩

theorem bk_tendsto_zero [IsFiniteMeasure μ] (hT : MeasurePreserving T μ μ) {h : X → ℝ}
    (hm : Measurable h) (hi : Integrable h μ)
    (h0 : ∀ D, MeasurableSet D → T ⁻¹' D = D → ∫ x in D, h x ∂μ = 0) :
    ∀ᵐ x ∂μ, Tendsto (fun n => birkhoffAverage ℝ T h n x) atTop (𝓝 0) := by
  have hup : ∀ j : ℕ, ∀ᵐ x ∂μ, ∃ K : ℕ, ∀ n : ℕ,
      birkhoffSum T h n x ≤ 1 / ((j : ℝ) + 1) * n + K :=
    fun j => bk_upper hT hm hi h0 (by positivity)
  have hlow : ∀ j : ℕ, ∀ᵐ x ∂μ, ∃ K : ℕ, ∀ n : ℕ,
      birkhoffSum T (-h) n x ≤ 1 / ((j : ℝ) + 1) * n + K :=
    fun j => bk_upper hT hm.neg hi.neg
      (fun D hD hDT => by simp [integral_neg, h0 D hD hDT]) (by positivity)
  filter_upwards [ae_all_iff.2 hup, ae_all_iff.2 hlow] with x hxu hxl
  rw [tendsto_order]
  constructor
  · intro a ha
    have ha2 : 0 < -a / 2 := by linarith
    obtain ⟨j, hj⟩ := exists_nat_one_div_lt ha2
    obtain ⟨K, hK⟩ := hxl j
    have hK0 : Tendsto (fun n : ℕ => (K : ℝ) / n) atTop (𝓝 0) :=
      tendsto_const_div_atTop_nhds_zero_nat (K : ℝ)
    filter_upwards [hK0.eventually (gt_mem_nhds ha2), eventually_ge_atTop 1] with n hn hn1
    have hnpos : (0 : ℝ) < n := by exact_mod_cast hn1
    have hS := hK n
    rw [birkhoffSum_neg_apply] at hS
    simp only [birkhoffAverage, smul_eq_mul]
    rw [← div_eq_inv_mul, lt_div_iff₀ hnpos]
    have h1 : (K : ℝ) < -a / 2 * n := by rwa [div_lt_iff₀ hnpos] at hn
    have h2 := mul_lt_mul_of_pos_right hj hnpos
    linarith
  · intro a ha
    have ha2 : 0 < a / 2 := by linarith
    obtain ⟨j, hj⟩ := exists_nat_one_div_lt ha2
    obtain ⟨K, hK⟩ := hxu j
    have hK0 : Tendsto (fun n : ℕ => (K : ℝ) / n) atTop (𝓝 0) :=
      tendsto_const_div_atTop_nhds_zero_nat (K : ℝ)
    filter_upwards [hK0.eventually (gt_mem_nhds ha2), eventually_ge_atTop 1] with n hn hn1
    have hnpos : (0 : ℝ) < n := by exact_mod_cast hn1
    have hS := hK n
    simp only [birkhoffAverage, smul_eq_mul]
    rw [← div_eq_inv_mul, div_lt_iff₀ hnpos]
    have h1 : (K : ℝ) < a / 2 * n := by rwa [div_lt_iff₀ hnpos] at hn
    have h2 := mul_lt_mul_of_pos_right hj hnpos
    linarith

theorem bk_ae_tendsto_of_measurable [IsFiniteMeasure μ] (hT : MeasurePreserving T μ μ)
    {f : X → ℝ} (hfm : Measurable f) (hf : Integrable f μ) :
    ∀ᵐ x ∂μ, Tendsto (fun n => birkhoffAverage ℝ T f n x) atTop
      (𝓝 ((μ[f | MeasurableSpace.invariants T]) x)) := by
  set g := μ[f | MeasurableSpace.invariants T] with hg
  have hgI : Measurable[MeasurableSpace.invariants T] g := stronglyMeasurable_condExp.measurable
  have hgT : g ∘ T = g := MeasurableSpace.comp_eq_of_measurable_invariants hgI
  have hgm : Measurable g := hgI.mono (MeasurableSpace.invariants_le T) le_rfl
  have hgi : Integrable g μ := integrable_condExp
  have hB := bk_tendsto_zero hT (hfm.sub hgm) (hf.sub hgi) (fun D hD hDT => by
    simp only [Pi.sub_apply]
    rw [integral_sub hf.integrableOn hgi.integrableOn,
      setIntegral_condExp (MeasurableSpace.invariants_le T) hf ⟨hD, hDT⟩, sub_self])
  filter_upwards [hB] with x hx
  have := hx.add_const (g x)
  rw [zero_add] at this
  refine this.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have hn' : (n : ℝ) ≠ 0 := by positivity
  rw [birkhoffAverage_sub_apply, birkhoffAverage_apply_of_comp_eq ℝ hgT hn']
  ring

theorem bk_ae_tendsto [IsFiniteMeasure μ] (hT : MeasurePreserving T μ μ) {f : X → ℝ}
    (hf : Integrable f μ) :
    ∀ᵐ x ∂μ, Tendsto (fun n => birkhoffAverage ℝ T f n x) atTop
      (𝓝 ((μ[f | MeasurableSpace.invariants T]) x)) := by
  set g := hf.1.mk f
  have hfg : f =ᵐ[μ] g := hf.1.ae_eq_mk
  have hgm : Measurable g := hf.1.stronglyMeasurable_mk.measurable
  have hgi : Integrable g μ := hf.congr hfg
  have hA : ∀ᵐ x ∂μ, ∀ n, birkhoffAverage ℝ T f n x = birkhoffAverage ℝ T g n x :=
    ae_all_iff.2 fun n => hT.quasiMeasurePreserving.birkhoffAverage_ae_eq_of_ae_eq ℝ hfg n
  filter_upwards [hA, bk_ae_tendsto_of_measurable hT hgm hgi,
    condExp_congr_ae (m := MeasurableSpace.invariants T) hfg] with x hx hlim hce
  rw [hce]
  simp only [hx]
  exact hlim

theorem bk_integrable_birkhoffAverage (hT : MeasurePreserving T μ μ) {f : X → ℝ}
    (hf : Integrable f μ) (n : ℕ) : Integrable (birkhoffAverage ℝ T f n) μ :=
  (bk_integrable_birkhoffSum hT hf n).smul ((n : ℝ)⁻¹)

theorem bk_integral_birkhoffAverage (hT : MeasurePreserving T μ μ) {f : X → ℝ}
    (hf : Integrable f μ) {n : ℕ} (hn : n ≠ 0) :
    ∫ x, birkhoffAverage ℝ T f n x ∂μ = ∫ x, f x ∂μ := by
  simp only [birkhoffAverage, smul_eq_mul]
  rw [integral_const_mul]
  have hk : ∀ k, ∫ x, f (T^[k] x) ∂μ = ∫ x, f x ∂μ := fun k => by
    have h := hT.iterate k
    rw [← integral_map h.measurable.aemeasurable (by rw [h.map_eq]; exact hf.1), h.map_eq]
  have : ∫ x, birkhoffSum T f n x ∂μ = n * ∫ x, f x ∂μ := by
    simp only [birkhoffSum]
    rw [integral_finsetSum (f := fun k x => f (T^[k] x)) _ fun k _ => (hT.iterate k).integrable_comp_of_integrable hf]
    simp [hk]
  rw [this]
  field_simp

theorem bk_scheffe {u : ℕ → X → ℝ} {v : X → ℝ} (hu : ∀ n, Integrable (u n) μ)
    (hv : Integrable v μ) (hu0 : ∀ n x, 0 ≤ u n x)
    (hlim : ∀ᵐ x ∂μ, Tendsto (fun n => u n x) atTop (𝓝 (v x)))
    (hint : ∀ᶠ n in atTop, ∫ x, u n x ∂μ = ∫ x, v x ∂μ) :
    Tendsto (fun n => ∫ x, |u n x - v x| ∂μ) atTop (𝓝 0) := by
  have hdom : Tendsto (fun n => ∫ x, max (v x - u n x) 0 ∂μ) atTop (𝓝 (∫ x, (0 : ℝ) ∂μ)) := by
    refine tendsto_integral_of_dominated_convergence (fun x => |v x|)
      (fun n => (hv.sub (hu n)).pos_part.1) hv.abs (fun n => Eventually.of_forall fun x => ?_) ?_
    · rw [Real.norm_eq_abs, abs_of_nonneg (le_max_right _ _)]
      exact max_le (by linarith [le_abs_self (v x), hu0 n x]) (abs_nonneg _)
    · filter_upwards [hlim] with x hx
      have : Tendsto (fun n => max (v x - u n x) 0) atTop (𝓝 (max (v x - v x) 0)) :=
        (tendsto_const_nhds.sub hx).max tendsto_const_nhds
      simpa using this
  rw [integral_zero] at hdom
  have h2 : Tendsto (fun n => 2 * ∫ x, max (v x - u n x) 0 ∂μ) atTop (𝓝 0) := by
    simpa using hdom.const_mul 2
  refine h2.congr' ?_
  filter_upwards [hint] with n hn
  have hpt : ∀ x, |u n x - v x| = (u n x - v x) + 2 * max (v x - u n x) 0 := by
    intro x
    rcases le_total (u n x) (v x) with h | h
    · rw [abs_of_nonpos (by linarith), max_eq_left (by linarith)]; ring
    · rw [abs_of_nonneg (by linarith), max_eq_right (by linarith)]; ring
  simp_rw [hpt]
  rw [integral_add (f := fun x => u n x - v x) (g := fun x => 2 * max (v x - u n x) 0)
    ((hu n).sub hv) ((hv.sub (hu n)).pos_part.const_mul 2),
    integral_sub (hu n) hv, hn, integral_const_mul]
  ring

end BirkhoffHelpers

theorem bk_doubling_ergodic :
    Ergodic (fun y : ℝ => Int.fract (2 * y)) (volume.restrict (Set.Ico (0 : ℝ) 1)) := by
  have : Fact ((0 : ℝ) < 1) := ⟨one_pos⟩
  set L : AddCircle (1 : ℝ) → ℝ := fun z => (AddCircle.equivIco 1 0 z : ℝ) with hL
  have hLm : Measurable L :=
    measurable_subtype_coe.comp (AddCircle.measurableEquivIco 1 0).measurable
  have hLmk : ∀ y : ℝ, L (y : AddCircle (1 : ℝ)) = Int.fract y := fun y => by
    simp [L, AddCircle.coe_equivIco_mk_apply]
  have hLmp : MeasurePreserving L volume (volume.restrict (Set.Ico (0 : ℝ) 1)) := by
    refine ⟨hLm, ?_⟩
    ext s hs
    rw [Measure.map_apply hLm hs, Measure.restrict_apply hs,
      AddCircle.add_projection_respects_measure 1 0 (hLm hs), zero_add]
    have hpre : (QuotientAddGroup.mk : ℝ → AddCircle (1 : ℝ)) ⁻¹' (L ⁻¹' s) =
        {y : ℝ | Int.fract y ∈ s} := by
      ext y
      simp only [Set.mem_preimage]
      rw [show ((QuotientAddGroup.mk y : AddCircle (1 : ℝ))) = (y : AddCircle (1 : ℝ)) from rfl,
        hLmk]
      rfl
    rw [hpre, measure_congr (EventuallyEqSet.inter EventuallyEqSet.rfl
      ((Ioc_ae_eq_Icc).trans Ico_ae_eq_Icc.symm))]
    congr 1
    ext y
    simp only [Set.mem_inter_iff, Set.mem_Ico]
    constructor
    · rintro ⟨h1, h2⟩
      rw [Set.mem_ofPred_eq, Int.fract_eq_self.2 h2] at h1
      exact ⟨h1, h2⟩
    · rintro ⟨h1, h2⟩
      refine ⟨?_, h2⟩
      show Int.fract y ∈ s
      rwa [Int.fract_eq_self.2 h2]
  have hTm : Measurable (fun y : ℝ => Int.fract (2 * y)) :=
    measurable_fract.comp (measurable_const.mul measurable_id)
  have hsemi : Function.Semiconj L (fun z : AddCircle (1 : ℝ) => 2 • z)
      (fun y : ℝ => Int.fract (2 * y)) := by
    intro z
    induction z using QuotientAddGroup.induction_on with
    | H y =>
      show L (2 • (y : AddCircle (1 : ℝ))) = Int.fract (2 * L (y : AddCircle (1 : ℝ)))
      rw [← AddCircle.coe_nsmul, hLmk, hLmk, nsmul_eq_mul]
      have : (2 : ℝ) * Int.fract y = 2 * y - ((2 * ⌊y⌋ : ℤ) : ℝ) := by
        rw [Int.fract]; push_cast; ring
      rw [this, Int.fract_sub_intCast]
      norm_num
  exact hLmp.ergodic_of_ergodic_semiconj (AddCircle.ergodic_nsmul (n := 2) (by norm_num)) hTm hsemi

/-- Birkhoff's ergodic theorem. Let `T` keep the probability measure `μ` and let `f` be
integrable. Then the average `A_n f(x) = (f(x) + f(T x) + ... + f(T^(n-1) x)) / n` converges,
for almost every start `x`, to the conditional expectation `E[f | I]` of `f` given the
invariant sets `I`; the mean distance `∫ |A_n f - E[f | I]| dμ` tends to 0; and when `T` is
ergodic the limit at almost every start is the plain integral `∫ f dμ`. -/
theorem birkhoff_ergodic_theorem {X : Type*} [MeasurableSpace X] {μ : Measure X}
    [IsProbabilityMeasure μ] {T : X → X} (hT : MeasurePreserving T μ μ) {f : X → ℝ}
    (hf : Integrable f μ) :
    (∀ᵐ x ∂μ, Tendsto (fun n => birkhoffAverage ℝ T f n x) atTop
        (𝓝 ((μ[f | MeasurableSpace.invariants T]) x))) ∧
    Tendsto (fun n => ∫ x, |birkhoffAverage ℝ T f n x - (μ[f | MeasurableSpace.invariants T]) x| ∂μ)
        atTop (𝓝 0) ∧
    (Ergodic T μ →
      ∀ᵐ x ∂μ, Tendsto (fun n => birkhoffAverage ℝ T f n x) atTop (𝓝 (∫ y, f y ∂μ))) := by
  have hI := MeasurableSpace.invariants_le T
  have hpt := bk_ae_tendsto hT hf
  refine ⟨hpt, ?_, ?_⟩
  · set fp : X → ℝ := fun x => max (f x) 0 with hfp_def
    set fn : X → ℝ := fun x => max (-f x) 0 with hfn_def
    have hfp : Integrable fp μ := hf.pos_part
    have hfn : Integrable fn μ := hf.neg_part
    have hfeq : f = fp - fn := by
      funext x; simp only [fp, fn, Pi.sub_apply, max_zero_sub_max_neg_zero_eq_self]
    have hS : ∀ φ : X → ℝ, Integrable φ μ → (∀ x, 0 ≤ φ x) →
        Tendsto (fun n => ∫ x, |birkhoffAverage ℝ T φ n x -
          (μ[φ | MeasurableSpace.invariants T]) x| ∂μ) atTop (𝓝 0) := by
      intro φ hφ hφ0
      refine bk_scheffe (fun n => bk_integrable_birkhoffAverage hT hφ n) integrable_condExp
        ?_ (bk_ae_tendsto hT hφ) ?_
      · intro n x
        simp only [birkhoffAverage, birkhoffSum, smul_eq_mul]
        exact mul_nonneg (by positivity) (Finset.sum_nonneg fun k _ => hφ0 _)
      · filter_upwards [eventually_ge_atTop 1] with n hn
        rw [bk_integral_birkhoffAverage hT hφ (by omega), integral_condExp hI]
    have hp := hS fp hfp (fun x => le_max_right _ _)
    have hn := hS fn hfn (fun x => le_max_right _ _)
    have hce : μ[f | MeasurableSpace.invariants T] =ᵐ[μ]
        μ[fp | MeasurableSpace.invariants T] - μ[fn | MeasurableSpace.invariants T] :=
      (condExp_congr_ae (EventuallyEq.of_eq hfeq)).trans (condExp_sub hfp hfn _)
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds
      (by simpa using hp.add hn) (fun n => integral_nonneg fun x => abs_nonneg _) (fun n => ?_)
    have i0 : Integrable (fun x => |birkhoffAverage ℝ T f n x -
        (μ[f | MeasurableSpace.invariants T]) x|) μ :=
      ((bk_integrable_birkhoffAverage hT hf n).sub integrable_condExp).abs
    have i1 : Integrable (fun x => |birkhoffAverage ℝ T fp n x -
        (μ[fp | MeasurableSpace.invariants T]) x|) μ :=
      ((bk_integrable_birkhoffAverage hT hfp n).sub integrable_condExp).abs
    have i2 : Integrable (fun x => |birkhoffAverage ℝ T fn n x -
        (μ[fn | MeasurableSpace.invariants T]) x|) μ :=
      ((bk_integrable_birkhoffAverage hT hfn n).sub integrable_condExp).abs
    rw [← integral_add i1 i2]
    refine integral_mono_ae i0 (i1.add i2) ?_
    filter_upwards [hce] with x hx
    have hA : birkhoffAverage ℝ T f n x =
        birkhoffAverage ℝ T fp n x - birkhoffAverage ℝ T fn n x := by
      conv_lhs => rw [hfeq]
      rw [birkhoffAverage_sub_apply]
    simp only [Pi.sub_apply] at hx
    rw [hA, hx]
    calc _ = |(birkhoffAverage ℝ T fp n x - (μ[fp | MeasurableSpace.invariants T]) x) -
          (birkhoffAverage ℝ T fn n x - (μ[fn | MeasurableSpace.invariants T]) x)| := by
          ring_nf
      _ ≤ _ := abs_sub _ _
  · intro hE
    set g := μ[f | MeasurableSpace.invariants T] with hg
    have hgI : Measurable[MeasurableSpace.invariants T] g := stronglyMeasurable_condExp.measurable
    have hgT : g ∘ T = g := MeasurableSpace.comp_eq_of_measurable_invariants hgI
    have hgm : Measurable g := hgI.mono hI le_rfl
    obtain ⟨c, hc⟩ := hE.ae_eq_const_of_ae_eq_comp_ae hgm.aestronglyMeasurable
      (EventuallyEq.of_eq hgT)
    have hcf : c = ∫ y, f y ∂μ := by
      have h1 := integral_congr_ae hc
      rw [hg, integral_condExp hI] at h1
      simp at h1
      exact h1.symm
    filter_upwards [hpt, hc] with x hx hcx
    rw [hcx, hcf] at hx
    exact hx

/-- The maximal ergodic theorem (Garsia's proof). Let `T` keep the probability measure `μ`
and let `f` be integrable. For every horizon `N`, on the set `E_N` of starts whose running sum
`S_n f = f + f ∘ T + ... + f ∘ T^(n-1)` is positive at some step `n` from 1 to `N`, the
function itself has a nonnegative integral: `∫_{E_N} f dμ ≥ 0`. -/
theorem maximal_ergodic_theorem {X : Type*} [MeasurableSpace X] {μ : Measure X}
    [IsProbabilityMeasure μ] {T : X → X} (hT : MeasurePreserving T μ μ) {f : X → ℝ}
    (hf : Integrable f μ) (N : ℕ) :
    0 ≤ ∫ x in {x | ∃ n ∈ Finset.Icc 1 N, 0 < birkhoffSum T f n x}, f x ∂μ := by
  exact bk_maximal hT hf N

/-- The house example. The doubling map `x ↦ 2x mod 1` on `[0, 1)` with length, and `f` the
first binary digit (1 on `[1/2, 1)`, 0 below): for almost every start, the share of 1s among
the first `n` binary digits tends to 1/2. -/
theorem doubling_map_digit_share_tendsto_half :
    ∀ᵐ x ∂(volume.restrict (Set.Ico (0 : ℝ) 1)),
      Tendsto (fun n => birkhoffAverage ℝ (fun y : ℝ => Int.fract (2 * y))
        ((Set.Ici (1 / 2 : ℝ)).indicator fun _ => (1 : ℝ)) n x) atTop (𝓝 (1 / 2)) := by
  have : IsProbabilityMeasure (volume.restrict (Set.Ico (0 : ℝ) 1)) :=
    ⟨by rw [Measure.restrict_apply_univ, Real.volume_Ico]; norm_num⟩
  have hE := bk_doubling_ergodic
  have hf : Integrable ((Set.Ici (1 / 2 : ℝ)).indicator fun _ => (1 : ℝ))
      (volume.restrict (Set.Ico (0 : ℝ) 1)) :=
    (integrable_const (1 : ℝ)).indicator measurableSet_Ici
  have h := (birkhoff_ergodic_theorem hE.toMeasurePreserving hf).2.2 hE
  have hint : ∫ y, (Set.Ici (1 / 2 : ℝ)).indicator (fun _ => (1 : ℝ)) y
      ∂(volume.restrict (Set.Ico (0 : ℝ) 1)) = 1 / 2 := by
    rw [integral_indicator measurableSet_Ici, setIntegral_const, smul_eq_mul, mul_one,
      Measure.real, Measure.restrict_apply measurableSet_Ici]
    have : Set.Ici (1 / 2 : ℝ) ∩ Set.Ico 0 1 = Set.Ico (1 / 2) 1 := by
      ext y; simp only [Set.mem_inter_iff, Set.mem_Ici, Set.mem_Ico]; constructor <;>
        rintro ⟨h1, h2⟩ <;> [exact ⟨h1, h2.2⟩; exact ⟨h1, by linarith, h2⟩]
    rw [this, Real.volume_Ico]
    norm_num
  rwa [hint] at h

-- The start 1/3 = 0.0101... in binary: binary digit k is ⌊2^k / 3⌋ mod 2,
-- and 500 of its first 1,000 digits are 1.
example : ((List.range 1000).map (fun k => (2 ^ (k + 1) / 3) % 2)).sum = 500 := by decide +kernel

-- The start 1/7 = 0.001001... in binary: 333 of its first 1,000 digits are 1.
example : ((List.range 1000).map (fun k => (2 ^ (k + 1) / 7) % 2)).sum = 333 := by decide +kernel

-- Exactly 301 of the powers 2^0, ..., 2^999 begin with the digit 1
-- (2^k begins with 1 when 10^j ≤ 2^k < 2 · 10^j for some j).
example : ((List.range 1000).filter
    (fun k => decide (∃ j < 302, 10 ^ j ≤ 2 ^ k ∧ 2 ^ k < 2 * 10 ^ j))).length = 301 := by
  decide +kernel

#print axioms bk_measurable_birkhoffSum
#print axioms bk_integrable_birkhoffSum
#print axioms bk_integral_comp
#print axioms bk_maximal_of_measurable
#print axioms bk_maximal
#print axioms bk_invariant_bound
#print axioms bk_upper
#print axioms bk_tendsto_zero
#print axioms bk_ae_tendsto_of_measurable
#print axioms bk_ae_tendsto
#print axioms bk_integrable_birkhoffAverage
#print axioms bk_integral_birkhoffAverage
#print axioms bk_scheffe
#print axioms bk_doubling_ergodic
#print axioms birkhoff_ergodic_theorem
#print axioms maximal_ergodic_theorem
#print axioms doubling_map_digit_share_tendsto_half
