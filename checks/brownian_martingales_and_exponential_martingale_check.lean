-- Brownian martingales: a process that starts at 0 and moves by fresh mean-0 normal draws with variance equal to the elapsed time makes W, W^2 - t and exp(theta W - theta^2 t / 2) fair games, and with continuous paths it leaves the walls -a, +b on the right with chance a/(a+b) after a*b seconds on average, and reaches level b with discounted value e^(-b sqrt(2 lambda)).
import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Tactic.NormNum.RealSqrt
import Mathlib.Probability.ConditionalExpectation
import Mathlib.Probability.Martingale.OptionalSampling
import Mathlib.MeasureTheory.Function.UniformIntegrable
import Mathlib.MeasureTheory.Function.Floor

open MeasureTheory ProbabilityTheory Real
open scoped NNReal ENNReal

open Filter Topology

/-! Helper lemmas for the proofs below. -/

lemma gauss_sq_integral (v : ℝ≥0) : ∫ x, x ^ 2 ∂(gaussianReal 0 v) = v := by
  have h := variance_fun_id_gaussianReal (μ := 0) (v := v)
  rw [variance_eq_integral measurable_id'.aemeasurable] at h
  simpa [integral_id_gaussianReal] using h

#print axioms gauss_sq_integral

lemma bm_condExp_incr {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (W : ℝ≥0 → Ω → ℝ)
    (hadapt : Adapted ℱ W)
    (hindep : ∀ s t : ℝ≥0, s ≤ t →
      Indep (MeasurableSpace.comap (W t - W s) inferInstance) (ℱ s) P)
    {s t : ℝ≥0} (hst : s ≤ t) (φ : ℝ → ℝ) (hφ : Measurable φ) :
    P[fun ω => φ (W t ω - W s ω) | ℱ s] =ᵐ[P] fun _ => ∫ ω, φ (W t ω - W s ω) ∂P := by
  have hWm : ∀ u, Measurable (W u) := fun u => (hadapt u).mono (ℱ.le u) le_rfl
  have hD : Measurable (W t - W s) := (hWm t).sub (hWm s)
  refine condExp_indep_eq hD.comap_le (ℱ.le s) ?_ (hindep s t hst)
  exact (hφ.comp (comap_measurable (W t - W s))).stronglyMeasurable

#print axioms bm_condExp_incr

lemma dyadic_tendsto (x : ℝ≥0) :
    Tendsto (fun n : ℕ => ((⌈x * 2 ^ n⌉₊ : ℕ) : ℝ≥0) / 2 ^ n) atTop (𝓝 x) := by
  have hup : Tendsto (fun n : ℕ => x + (1 / 2 : ℝ≥0) ^ n) atTop (𝓝 x) := by
    simpa using tendsto_const_nhds.add
      (NNReal.tendsto_pow_atTop_nhds_zero_of_lt_one (r := 1 / 2) (by norm_num))
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds hup (fun n => ?_) (fun n => ?_)
  · rw [le_div_iff₀ (by positivity)]
    exact Nat.le_ceil _
  · rw [div_le_iff₀ (by positivity), add_mul, ← mul_pow]
    norm_num
    exact (Nat.ceil_lt_add_one zero_le).le

#print axioms dyadic_tendsto

lemma measurable_stopped {Ω : Type*} {mΩ : MeasurableSpace Ω} (M : ℝ≥0 → Ω → ℝ)
    (hMm : ∀ t, Measurable (M t)) (hcont : ∀ ω, Continuous fun t => M t ω)
    (τ : Ω → ℝ≥0) (hτ : Measurable τ) : Measurable fun ω => M (τ ω) ω := by
  refine measurable_of_tendsto_metrizable
    (f := fun n ω => M (((⌈τ ω * 2 ^ n⌉₊ : ℕ) : ℝ≥0) / 2 ^ n) ω) (fun n => ?_)
    (tendsto_pi_nhds.2 fun ω => ((hcont ω).tendsto _).comp (dyadic_tendsto _))
  have h1 : Measurable (fun p : ℕ × Ω => M ((p.1 : ℝ≥0) / 2 ^ n) p.2) :=
    measurable_from_prod_countable_right (fun k => hMm ((k : ℝ≥0) / 2 ^ n))
  have h2 : Measurable fun ω => ⌈τ ω * 2 ^ n⌉₊ := (hτ.mul_const _).nat_ceil
  exact h1.comp (h2.prodMk measurable_id)

#print axioms measurable_stopped

lemma optional_stopping_bounded {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (M : ℝ≥0 → Ω → ℝ)
    (hM : Martingale M ℱ P) (hcont : ∀ ω, Continuous fun t => M t ω)
    (τ : Ω → ℝ≥0) (hτ : ∀ t, MeasurableSet[ℱ t] {ω | τ ω ≤ t}) (N : ℕ)
    (hτN : ∀ ω, τ ω ≤ N) :
    ∫ ω, M (τ ω) ω ∂P = ∫ ω, M N ω ∂P := by
  let G : ℕ → Filtration ℕ mΩ := fun n =>
    ⟨fun k => ℱ ((k : ℝ≥0) / 2 ^ n), fun i j hij => ℱ.mono (by gcongr), fun k => ℱ.le _⟩
  have hX : ∀ n, Martingale (fun k : ℕ => M ((k : ℝ≥0) / 2 ^ n)) (G n) P := fun n =>
    ⟨fun k => hM.1 _, fun i j hij => hM.2 _ _ (by gcongr)⟩
  let σ : ℕ → Ω → WithTop ℕ := fun n ω => WithTop.some ⌈τ ω * 2 ^ n⌉₊
  have hσ : ∀ n, IsStoppingTime (G n) (σ n) := by
    intro n k
    have : {ω | σ n ω ≤ WithTop.some k} = {ω | τ ω ≤ (k : ℝ≥0) / 2 ^ n} := by
      ext ω
      simp only [σ, Set.mem_ofPred_eq, WithTop.coe_le_coe, Nat.ceil_le]
      rw [le_div_iff₀ (by positivity)]
    show MeasurableSet[ℱ ((k : ℝ≥0) / 2 ^ n)] {ω | σ n ω ≤ WithTop.some k}
    rw [this]
    exact hτ _
  have hσN : ∀ n ω, σ n ω ≤ WithTop.some (N * 2 ^ n) := by
    intro n ω
    simp only [σ, WithTop.coe_le_coe, Nat.ceil_le]
    push_cast
    gcongr
    exact hτN ω
  have hNint : Integrable (M N) P := hM.integrable _
  have hY : ∀ n, (fun ω => M (((⌈τ ω * 2 ^ n⌉₊ : ℕ) : ℝ≥0) / 2 ^ n) ω) =ᵐ[P]
      P[M N | (hσ n).measurableSpace] := by
    intro n
    have h := (hX n).stoppedValue_ae_eq_condExp_of_le_const (hσ n) (hσN n)
    have hc : (((N * 2 ^ n : ℕ) : ℝ≥0) / 2 ^ n) = N := by
      push_cast
      field_simp
    simp only [hc] at h
    exact h
  have hUI := hNint.uniformIntegrable_condExp (fun n => (hσ n).measurableSpace_le)
  have hconv : ∀ᵐ ω ∂P, Tendsto (fun n => P[M N | (hσ n).measurableSpace] ω) atTop
      (𝓝 (M (τ ω) ω)) := by
    filter_upwards [ae_all_iff.2 hY] with ω hω
    simp only [← hω]
    exact ((hcont ω).tendsto _).comp (dyadic_tendsto _)
  have hlim := hUI.integrable_of_ae_tendsto hconv
  have hL1 := tendsto_Lp_finite_of_tendsto_ae le_rfl ENNReal.one_ne_top
    (fun n => integrable_condExp.aestronglyMeasurable)
    (memLp_one_iff_integrable.2 hlim) hUI.1 hconv
  have hint := tendsto_integral_of_L1' (μ := P) _
    (Eventually.of_forall fun n => integrable_condExp) hL1
  simp only [integral_condExp (hσ _).measurableSpace_le] at hint
  exact tendsto_nhds_unique hint tendsto_const_nhds

#print axioms optional_stopping_bounded

lemma hit_isClosed {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (hcont : ∀ ω, Continuous fun t => W t ω)
    (g : ℝ → ℝ) (hg : Continuous g) (N : ℕ) (ω : Ω) :
    IsClosed {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t} :=
  (isClosed_le (hg.comp (hcont ω)) continuous_const).union (isClosed_le continuous_const continuous_id)

#print axioms hit_isClosed

lemma hit_mem {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (hcont : ∀ ω, Continuous fun t => W t ω)
    (g : ℝ → ℝ) (hg : Continuous g) (N : ℕ) (ω : Ω) :
    sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t} ∈
      {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t} :=
  (hit_isClosed W hcont g hg N ω).csInf_mem ⟨N, Or.inr le_rfl⟩ (OrderBot.bddBelow _)

#print axioms hit_mem

lemma hit_le {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (g : ℝ → ℝ) (N : ℕ) (ω : Ω) :
    sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t} ≤ N :=
  csInf_le (OrderBot.bddBelow _) (Or.inr le_rfl)

#print axioms hit_le

lemma hit_pos_before {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (g : ℝ → ℝ) (N : ℕ) (ω : Ω) (s : ℝ≥0)
    (hs : s < sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t}) : 0 < g (W s ω) := by
  have := notMem_of_lt_csInf' hs
  simp only [Set.mem_ofPred_eq, not_or, not_le] at this
  exact this.1

#print axioms hit_pos_before

lemma hit_nonneg {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (hcont : ∀ ω, Continuous fun t => W t ω)
    (g : ℝ → ℝ) (hg : Continuous g) (N : ℕ) (ω : Ω) (h0 : 0 < g (W 0 ω)) :
    0 ≤ g (W (sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t}) ω) := by
  set τ := sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t} with hτ
  rcases eq_or_lt_of_le (zero_le : 0 ≤ τ) with h | h
  · rw [← h]; exact h0.le
  · have hcl : τ ∈ closure (Set.Iio τ) := by
      rw [closure_Iio' (a := τ) ⟨0, h⟩]; exact Set.mem_Iic.2 le_rfl
    have := map_mem_closure (hg.comp (hcont ω)) hcl
      (t := Set.Ici 0) (fun s hs => (hit_pos_before W g N ω s hs).le)
    simpa [closure_Ici] using this

#print axioms hit_nonneg

lemma hit_eq_min {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (hcont : ∀ ω, Continuous fun t => W t ω)
    (g : ℝ → ℝ) (hg : Continuous g) (N : ℕ) (ω : Ω) (hne : ∃ t, g (W t ω) ≤ 0) :
    sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t} =
      min (sInf {t : ℝ≥0 | g (W t ω) ≤ 0}) N := by
  have hHc : IsClosed {t : ℝ≥0 | g (W t ω) ≤ 0} :=
    isClosed_le (hg.comp (hcont ω)) continuous_const
  have hHm := hHc.csInf_mem hne (OrderBot.bddBelow _)
  apply le_antisymm
  · rcases le_total (sInf {t : ℝ≥0 | g (W t ω) ≤ 0}) N with h | h
    · rw [min_eq_left h]; exact csInf_le (OrderBot.bddBelow _) (Or.inl hHm)
    · rw [min_eq_right h]; exact hit_le W g N ω
  · rcases hit_mem W hcont g hg N ω with h | h
    · exact min_le_of_left_le (csInf_le (OrderBot.bddBelow _) h)
    · exact min_le_of_right_le h

#print axioms hit_eq_min

lemma hit_eq_N {Ω : Type*} (W : ℝ≥0 → Ω → ℝ) (hcont : ∀ ω, Continuous fun t => W t ω)
    (g : ℝ → ℝ) (hg : Continuous g) (N : ℕ) (ω : Ω) (hne : ¬ ∃ t, g (W t ω) ≤ 0) :
    sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t} = N := by
  apply le_antisymm (hit_le W g N ω)
  rcases hit_mem W hcont g hg N ω with h | h
  · exact absurd ⟨_, h⟩ hne
  · exact h

#print axioms hit_eq_N

lemma hit_before_measurable {Ω : Type*} {mΩ : MeasurableSpace Ω} (ℱ : Filtration ℝ≥0 mΩ)
    (W : ℝ≥0 → Ω → ℝ) (hadapt : Adapted ℱ W) (hcont : ∀ ω, Continuous fun t => W t ω)
    (g : ℝ → ℝ) (hg : Continuous g) (t : ℝ≥0) :
    MeasurableSet[ℱ t] {ω | ∃ s ≤ t, g (W s ω) ≤ 0} := by
  let p : ℚ → ℝ≥0 := fun q => min t (Real.toNNReal q)
  have hp : Continuous fun r : ℝ => min t (Real.toNNReal r) :=
    continuous_const.min continuous_real_toNNReal
  have key : {ω | ∃ s ≤ t, g (W s ω) ≤ 0} =
      ⋂ m : ℕ, ⋃ q : ℚ, {ω | g (W (p q) ω) < 1 / ((m : ℝ) + 1)} := by
    ext ω
    simp only [Set.mem_ofPred_eq, Set.mem_iInter, Set.mem_iUnion]
    constructor
    · rintro ⟨s, hst, hs⟩ m
      have hc : Continuous fun r : ℝ => g (W (min t (Real.toNNReal r)) ω) :=
        hg.comp ((hcont ω).comp hp)
      have hU : IsOpen ((fun r : ℝ => g (W (min t (Real.toNNReal r)) ω)) ⁻¹'
          Set.Iio (1 / ((m : ℝ) + 1))) := isOpen_Iio.preimage hc
      have hsU : (s : ℝ) ∈ (fun r : ℝ => g (W (min t (Real.toNNReal r)) ω)) ⁻¹'
          Set.Iio (1 / ((m : ℝ) + 1)) := by
        simp only [Set.mem_preimage, Set.mem_Iio, Real.toNNReal_coe, min_eq_right hst]
        exact hs.trans_lt (by positivity)
      obtain ⟨q, hq⟩ := Rat.denseRange_cast.exists_mem_open hU ⟨_, hsU⟩
      exact ⟨q, hq⟩
    · intro h
      choose q hq using h
      have hmem : ∀ m, p (q m) ∈ Set.Icc (0 : ℝ≥0) t := fun m =>
        ⟨zero_le, min_le_left _ _⟩
      obtain ⟨s, hs, φ, hφ, hlim⟩ := isCompact_Icc.tendsto_subseq hmem
      refine ⟨s, hs.2, ?_⟩
      have h1 : Tendsto (fun k => g (W (p (q (φ k))) ω)) atTop (𝓝 (g (W s ω))) :=
        ((hg.comp (hcont ω)).tendsto s).comp hlim
      have h2 : Tendsto (fun k => 1 / ((φ k : ℝ) + 1)) atTop (𝓝 0) :=
        tendsto_one_div_add_atTop_nhds_zero_nat.comp hφ.tendsto_atTop
      exact le_of_tendsto_of_tendsto' h1 h2 (fun k => (hq (φ k)).le)
  rw [key]
  refine MeasurableSet.iInter fun m => MeasurableSet.iUnion fun q => ?_
  have hm : Measurable[ℱ t] (W (p q)) := (hadapt (p q)).mono (ℱ.mono (min_le_left _ _)) le_rfl
  exact measurableSet_lt (hg.measurable.comp hm) measurable_const

#print axioms hit_before_measurable

lemma hit_stopping {Ω : Type*} {mΩ : MeasurableSpace Ω} (ℱ : Filtration ℝ≥0 mΩ)
    (W : ℝ≥0 → Ω → ℝ) (hadapt : Adapted ℱ W) (hcont : ∀ ω, Continuous fun t => W t ω)
    (g : ℝ → ℝ) (hg : Continuous g) (N : ℕ) (t : ℝ≥0) :
    MeasurableSet[ℱ t] {ω | sInf {s : ℝ≥0 | g (W s ω) ≤ 0 ∨ (N : ℝ≥0) ≤ s} ≤ t} := by
  rcases le_or_gt (N : ℝ≥0) t with hN | hN
  · have : {ω | sInf {s : ℝ≥0 | g (W s ω) ≤ 0 ∨ (N : ℝ≥0) ≤ s} ≤ t} = Set.univ := by
      ext ω; simp only [Set.mem_ofPred_eq, Set.mem_univ, iff_true]
      exact (hit_le W g N ω).trans hN
    rw [this]; exact MeasurableSet.univ
  · have : {ω | sInf {s : ℝ≥0 | g (W s ω) ≤ 0 ∨ (N : ℝ≥0) ≤ s} ≤ t} =
        {ω | ∃ s ≤ t, g (W s ω) ≤ 0} := by
      ext ω; simp only [Set.mem_ofPred_eq]
      constructor
      · intro h
        rcases hit_mem W hcont g hg N ω with h' | h'
        · exact ⟨_, h, h'⟩
        · exact absurd (h'.trans h) (not_le.2 hN)
      · rintro ⟨s, hst, hs⟩
        exact (csInf_le (OrderBot.bddBelow _) (Or.inl hs)).trans hst
    rw [this]; exact hit_before_measurable ℱ W hadapt hcont g hg t

#print axioms hit_stopping

lemma mart_integral_eq {Ω : Type*} {mΩ : MeasurableSpace Ω} {P : Measure Ω}
    [IsProbabilityMeasure P] {ℱ : Filtration ℝ≥0 mΩ} {M : ℝ≥0 → Ω → ℝ}
    (hM : Martingale M ℱ P) (t : ℝ≥0) : ∫ ω, M t ω ∂P = ∫ ω, M 0 ω ∂P := by
  rw [← integral_condExp (ℱ.le 0)]
  exact integral_congr_ae (hM.2 0 t zero_le)

#print axioms mart_integral_eq

/-! Setting, as on the card. `W t ω` is the grain's position at time `t` on path `ω`.
`ℱ s` is what is known by time `s`; `W` is adapted to it. The card's "When it holds":
* `W` starts at 0;
* the move `W t - W s` after time `s` is a normal draw with mean 0 and variance `t - s`
  (law `gaussianReal 0 (t - s)`), independent of what is known by time `s`;
* for the exit facts, the paths are continuous. -/

/-- The card's main claim: Brownian motion carries three fair games. The position `W t`, the
squared position minus the clock `W t ^ 2 - t`, and, for every fixed number `θ`, the
clock-corrected exponential `exp (θ W t - θ² t / 2)` are all martingales. Only the independent
mean-0 normal moves with variance equal to elapsed time are used; no continuity is needed. -/
theorem brownian_martingales {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (W : ℝ≥0 → Ω → ℝ)
    (hadapt : Adapted ℱ W) (h0 : W 0 =ᵐ[P] 0)
    (hlaw : ∀ s t : ℝ≥0, s ≤ t → HasLaw (W t - W s) (gaussianReal 0 (t - s)) P)
    (hindep : ∀ s t : ℝ≥0, s ≤ t →
      Indep (MeasurableSpace.comap (W t - W s) inferInstance) (ℱ s) P) :
    Martingale W ℱ P ∧
      Martingale (fun t ω => W t ω ^ 2 - (t : ℝ)) ℱ P ∧
      ∀ θ : ℝ, Martingale (fun t ω => exp (θ * W t ω - θ ^ 2 * (t : ℝ) / 2)) ℱ P := by
  have hWm : ∀ u, Measurable (W u) := fun u => (hadapt u).mono (ℱ.le u) le_rfl
  have hWs : ∀ u, StronglyMeasurable[ℱ u] (W u) := fun u => (hadapt u).stronglyMeasurable
  -- law of W u
  have hlawW : ∀ u, HasLaw (W u) (gaussianReal 0 u) P := by
    intro u
    have h := hlaw 0 u zero_le
    simp only [tsub_zero] at h
    refine h.congr ?_
    filter_upwards [h0] with ω hω
    simp [hω]
  have hWL : ∀ u (p : ℝ≥0), MemLp (W u) p P := fun u p =>
    (hlawW u).memLp (memLp_id_gaussianReal p)
  have hWi : ∀ u, Integrable (W u) P := fun u => memLp_one_iff_integrable.1 (by exact_mod_cast hWL u 1)
  have hDL : ∀ s t, s ≤ t → ∀ p : ℝ≥0, MemLp (W t - W s) p P := fun s t hst p =>
    (hlaw s t hst).memLp (memLp_id_gaussianReal p)
  refine ⟨⟨hadapt.stronglyAdapted, ?_⟩, ⟨?_, ?_⟩, ?_⟩
  · intro s t hst
    have hsplit : W t = W s + (fun ω => id (W t ω - W s ω)) := by
      ext ω; simp
    rw [hsplit]
    have hDi : Integrable (fun ω => id (W t ω - W s ω)) P := (hWi t).sub (hWi s)
    refine (condExp_add (hWi s) hDi _).trans ?_
    rw [condExp_of_stronglyMeasurable (ℱ.le s) (hWs s) (hWi s)]
    filter_upwards [bm_condExp_incr P ℱ W hadapt hindep hst id measurable_id] with ω hω
    rw [Pi.add_apply, hω]
    have : ∫ ω, id (W t ω - W s ω) ∂P = 0 := by
      have := (hlaw s t hst).integral_eq (E := ℝ)
      simp only [integral_id_gaussianReal] at this
      simpa using this
    simp only [id] at this
    simp [this]
  · exact fun u => (((hadapt u).pow_const 2).sub_const _).stronglyMeasurable
  · intro s t hst
    have hD2 : MemLp (W t - W s) 2 P := by exact_mod_cast hDL s t hst 2
    have hcoe : ((t - s : ℝ≥0) : ℝ) = (t : ℝ) - s := NNReal.coe_sub hst
    have hsplit : (fun ω => W t ω ^ 2 - (t : ℝ)) =
        ((fun ω => W s ω ^ 2 - (s : ℝ)) + (fun ω => 2 * W s ω) * (fun ω => id (W t ω - W s ω)))
          + (fun ω => (fun x : ℝ => x ^ 2 - ((t : ℝ) - s)) (W t ω - W s ω)) := by
      ext ω; simp only [Pi.add_apply, Pi.mul_apply, id]; ring
    have hAi : Integrable (fun ω => W s ω ^ 2 - (s : ℝ)) P :=
      (by exact_mod_cast hWL s 2 : MemLp (W s) 2 P).integrable_sq.sub (integrable_const _)
    have hBi : Integrable ((fun ω => 2 * W s ω) * (fun ω => id (W t ω - W s ω))) P :=
      MemLp.integrable_mul (p := 2) (q := 2)
        ((by exact_mod_cast hWL s 2 : MemLp (W s) 2 P).const_mul 2) hD2
    have hCi : Integrable (fun ω => (fun x : ℝ => x ^ 2 - ((t : ℝ) - s)) (W t ω - W s ω)) P :=
      hD2.integrable_sq.sub (integrable_const _)
    have hDi : Integrable (fun ω => id (W t ω - W s ω)) P := (hWi t).sub (hWi s)
    show P[fun ω => W t ω ^ 2 - (t : ℝ) | ℱ s] =ᵐ[P] fun ω => W s ω ^ 2 - (s : ℝ)
    rw [hsplit]
    refine (condExp_add (hAi.add hBi) hCi _).trans ?_
    refine ((condExp_add hAi hBi _).add Filter.EventuallyEq.rfl).trans ?_
    rw [condExp_of_stronglyMeasurable (ℱ.le s)
      ((((hadapt s).pow_const 2).sub_const _).stronglyMeasurable) hAi]
    have hB := condExp_mul_of_stronglyMeasurable_left (m := ℱ s) (μ := P)
      (((hadapt s).const_mul 2).stronglyMeasurable) hBi hDi
    have hC := bm_condExp_incr P ℱ W hadapt hindep hst (fun x : ℝ => x ^ 2 - ((t : ℝ) - s))
      ((measurable_id.pow_const 2).sub_const _)
    have hDc := bm_condExp_incr P ℱ W hadapt hindep hst id measurable_id
    have hm1 : ∫ ω, id (W t ω - W s ω) ∂P = 0 := by
      have := (hlaw s t hst).integral_eq (E := ℝ)
      simp only [integral_id_gaussianReal] at this
      simpa using this
    have hm2 : ∫ ω, ((W t ω - W s ω) ^ 2 - ((t : ℝ) - s)) ∂P = 0 := by
      rw [integral_sub (f := fun ω => (W t ω - W s ω) ^ 2) hD2.integrable_sq (integrable_const _)]
      have := (hlaw s t hst).integral_comp (f := fun x : ℝ => x ^ 2)
        (measurable_id.pow_const 2).aestronglyMeasurable
      simp only [Function.comp_def, gauss_sq_integral, hcoe, Pi.sub_apply] at this
      simp [this]
    filter_upwards [hB, hC, hDc] with ω hBω hCω hDω
    simp only [Pi.add_apply] at hBω ⊢
    rw [hBω, hCω, hm2, Pi.mul_apply, hDω, hm1]
    simp
  · intro θ
    refine ⟨fun u => (((hadapt u).const_mul θ).sub_const _).exp.stronglyMeasurable, ?_⟩
    intro s t hst
    have hcoe : ((t - s : ℝ≥0) : ℝ) = (t : ℝ) - s := NNReal.coe_sub hst
    have hEi : ∀ u, Integrable (fun ω => exp (θ * W u ω - θ ^ 2 * (u : ℝ) / 2)) P := by
      intro u
      have h1 := (hlawW u).integrable_comp (integrable_exp_mul_gaussianReal (μ := 0) (v := u) θ)
      have h2 := h1.const_mul (exp (-(θ ^ 2 * (u : ℝ) / 2)))
      refine h2.congr (Filter.Eventually.of_forall fun ω => ?_)
      simp only [Function.comp_apply, ← exp_add]
      ring_nf
    let φ : ℝ → ℝ := fun x => exp (θ * x - θ ^ 2 * ((t : ℝ) - s) / 2)
    have hφm : Measurable φ := ((measurable_id.const_mul θ).sub_const _).exp
    have hφi : Integrable (fun ω => φ (W t ω - W s ω)) P := by
      have h1 := (hlaw s t hst).integrable_comp
        (integrable_exp_mul_gaussianReal (μ := 0) (v := t - s) θ)
      have h2 := h1.const_mul (exp (-(θ ^ 2 * ((t : ℝ) - s) / 2)))
      refine h2.congr (Filter.Eventually.of_forall fun ω => ?_)
      simp only [Function.comp_apply, ← exp_add, φ, Pi.sub_apply]
      ring_nf
    have hsplit : (fun ω => exp (θ * W t ω - θ ^ 2 * (t : ℝ) / 2)) =
        (fun ω => exp (θ * W s ω - θ ^ 2 * (s : ℝ) / 2)) * (fun ω => φ (W t ω - W s ω)) := by
      ext ω; simp only [Pi.mul_apply, φ, ← exp_add]; ring_nf
    have hint : ∫ ω, φ (W t ω - W s ω) ∂P = 1 := by
      have hm := mgf_gaussianReal (hlaw s t hst) θ
      simp only [mgf, hcoe] at hm
      have : (fun ω => φ (W t ω - W s ω)) =
          fun ω => exp (-(θ ^ 2 * ((t : ℝ) - s) / 2)) * exp (θ * (W t - W s) ω) := by
        ext ω; simp only [φ, ← exp_add, Pi.sub_apply]; ring_nf
      rw [this, integral_const_mul, hm, ← exp_add]
      simp only [zero_mul, zero_add, exp_eq_one_iff]
      ring
    show P[fun ω => exp (θ * W t ω - θ ^ 2 * (t : ℝ) / 2) | ℱ s] =ᵐ[P]
      fun ω => exp (θ * W s ω - θ ^ 2 * (s : ℝ) / 2)
    rw [hsplit]
    have hB := condExp_mul_of_stronglyMeasurable_left (m := ℱ s) (μ := P)
      ((((hadapt s).const_mul θ).sub_const _).exp.stronglyMeasurable) (hsplit ▸ hEi t) hφi
    filter_upwards [hB, bm_condExp_incr P ℱ W hadapt hindep hst φ hφm] with ω h1 h2
    rw [h1, Pi.mul_apply, h2, hint, mul_one]

/-- Leaving an interval: with walls at `-a` and `+b` (`a, b > 0`) and continuous paths, the grain
leaves by the right wall (touches `+b` while it has stayed strictly between the walls before) with
chance `a / (a + b)`, and the exit time `τ`, the first time it touches either wall, has average
`a * b`. The exit time is measured in `ℝ≥0∞` (an empty set gives `∞`), so the average being the
finite number `a * b` also says the exit comes. -/
theorem exit_side_and_mean_exit_time {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (W : ℝ≥0 → Ω → ℝ)
    (hadapt : Adapted ℱ W) (h0 : W 0 =ᵐ[P] 0)
    (hlaw : ∀ s t : ℝ≥0, s ≤ t → HasLaw (W t - W s) (gaussianReal 0 (t - s)) P)
    (hindep : ∀ s t : ℝ≥0, s ≤ t →
      Indep (MeasurableSpace.comap (W t - W s) inferInstance) (ℱ s) P)
    (hcont : ∀ ω, Continuous fun t => W t ω)
    (a b : ℝ) (ha : 0 < a) (hb : 0 < b) :
    P.real {ω | ∃ t : ℝ≥0, W t ω = b ∧ ∀ s < t, W s ω ∈ Set.Ioo (-a) b} = a / (a + b) ∧
      ∫⁻ ω, (⨅ (t : ℝ≥0) (_ : W t ω ≤ -a ∨ b ≤ W t ω), (t : ℝ≥0∞)) ∂P
        = ENNReal.ofReal (a * b) := by
  obtain ⟨hm1, hm2, -⟩ := brownian_martingales P ℱ W hadapt h0 hlaw hindep
  have hWm : ∀ u, Measurable (W u) := fun u => (hadapt u).mono (ℱ.le u) le_rfl
  set g : ℝ → ℝ := fun x => min (x + a) (b - x) with hg_def
  have hg : Continuous g :=
    (continuous_id.add continuous_const).min (continuous_const.sub continuous_id)
  have hgiff : ∀ x, g x ≤ 0 ↔ x ≤ -a ∨ b ≤ x := by
    intro x; simp only [g, min_le_iff]
    constructor
    · rintro (h | h)
      · left; linarith
      · right; linarith
    · rintro (h | h)
      · left; linarith
      · right; linarith
  have hgpos : ∀ x, 0 < g x → -a < x ∧ x < b := by
    intro x hx; simp only [g, lt_min_iff] at hx; constructor <;> linarith [hx.1, hx.2]
  have hsqb : ∀ x : ℝ, -a ≤ x → x ≤ b → x ^ 2 ≤ a ^ 2 + b ^ 2 := by
    intro x h1 h2
    rcases le_total 0 x with hx | hx
    · nlinarith
    · nlinarith
  have hgnn : ∀ x, 0 ≤ g x → -a ≤ x ∧ x ≤ b := by
    intro x hx; simp only [g, le_min_iff] at hx; constructor <;> linarith [hx.1, hx.2]
  set τN : ℕ → Ω → ℝ≥0 := fun N ω => sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t}
    with hτN_def
  have hstop : ∀ N t, MeasurableSet[ℱ t] {ω | τN N ω ≤ t} := fun N t =>
    hit_stopping ℱ W hadapt hcont g hg N t
  have hτNle : ∀ N ω, τN N ω ≤ N := fun N ω => hit_le W g N ω
  have hτNm : ∀ N, Measurable (τN N) := fun N =>
    measurable_of_Iic fun t => ℱ.le t _ (hstop N t)
  have hWτm : ∀ N, Measurable fun ω => W (τN N ω) ω := fun N =>
    measurable_stopped W hWm hcont _ (hτNm N)
  have hgood : ∀ᵐ ω ∂P, ∀ N, -a ≤ W (τN N ω) ω ∧ W (τN N ω) ω ≤ b := by
    filter_upwards [h0] with ω hω N
    have hg0 : 0 < g (W 0 ω) := by
      simp only [hω, Pi.zero_apply, g, zero_add, sub_zero]; exact lt_min ha hb
    exact hgnn _ (hit_nonneg W hcont g hg N ω hg0)
  have hWτi : ∀ N, Integrable (fun ω => W (τN N ω) ω) P := by
    intro N
    refine Integrable.of_bound (hWτm N).aestronglyMeasurable (a + b) ?_
    filter_upwards [hgood] with ω hω
    rw [Real.norm_eq_abs, abs_le]; constructor <;> linarith [(hω N).1, (hω N).2]
  have hWτ2i : ∀ N, Integrable (fun ω => W (τN N ω) ω ^ 2) P := by
    intro N
    refine Integrable.of_bound ((hWτm N).pow_const 2).aestronglyMeasurable (a ^ 2 + b ^ 2) ?_
    filter_upwards [hgood] with ω hω
    rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]
    exact hsqb _ (hω N).1 (hω N).2
  have hτNi : ∀ N, Integrable (fun ω => (τN N ω : ℝ)) P := by
    intro N
    refine Integrable.of_bound (hτNm N).coe_nnreal_real.aestronglyMeasurable N ?_
    filter_upwards with ω
    rw [Real.norm_eq_abs, NNReal.abs_eq]; exact_mod_cast hτNle N ω
  have hint0 : ∀ N, ∫ ω, W (τN N ω) ω ∂P = 0 := by
    intro N
    rw [optional_stopping_bounded P ℱ W hm1 hcont (τN N) (hstop N) N (hτNle N),
      mart_integral_eq hm1, integral_congr_ae h0]
    simp
  have hsq : ∀ N, ∫ ω, W (τN N ω) ω ^ 2 ∂P = ∫ ω, (τN N ω : ℝ) ∂P := by
    intro N
    have h := optional_stopping_bounded P ℱ (fun t ω => W t ω ^ 2 - (t : ℝ)) hm2
      (fun ω => ((hcont ω).pow 2).sub NNReal.continuous_coe) (τN N) (hstop N) N (hτNle N)
    rw [mart_integral_eq hm2] at h
    have h' : ∫ ω, (W 0 ω ^ 2 - ((0 : ℝ≥0) : ℝ)) ∂P = 0 := by
      rw [integral_congr_ae (g := fun _ => (0 : ℝ))]
      · simp
      · filter_upwards [h0] with ω hω; simp [hω]
    rw [h', integral_sub (hWτ2i N) (hτNi N)] at h
    linarith
  -- the exit time in ℝ≥0∞
  set τ : Ω → ℝ≥0∞ := fun ω => ⨅ (t : ℝ≥0) (_ : W t ω ≤ -a ∨ b ≤ W t ω), (t : ℝ≥0∞)
    with hτ_def
  have hmin : ∀ N ω, ((τN N ω : ℝ≥0) : ℝ≥0∞) = min (τ ω) (N : ℝ≥0∞) := by
    intro N ω
    by_cases hne : ∃ t, g (W t ω) ≤ 0
    · have hH := hit_eq_min W hcont g hg N ω hne
      simp only [τN] at hH ⊢
      rw [hH]
      have hHc : IsClosed {t : ℝ≥0 | g (W t ω) ≤ 0} :=
        isClosed_le (hg.comp (hcont ω)) continuous_const
      have hHm := hHc.csInf_mem hne (OrderBot.bddBelow _)
      have he : ((sInf {t : ℝ≥0 | g (W t ω) ≤ 0} : ℝ≥0) : ℝ≥0∞) = τ ω := by
        apply le_antisymm
        · exact le_iInf₂ fun t ht =>
            ENNReal.coe_le_coe.2 (csInf_le (OrderBot.bddBelow _) ((hgiff _).2 ht))
        · exact iInf₂_le (f := fun (t : ℝ≥0) (_ : W t ω ≤ -a ∨ b ≤ W t ω) => (t : ℝ≥0∞))
            (sInf {t : ℝ≥0 | g (W t ω) ≤ 0}) ((hgiff _).1 hHm)
      rw [← he]
      rcases le_total (sInf {t : ℝ≥0 | g (W t ω) ≤ 0}) N with h | h
      · rw [min_eq_left h, min_eq_left (by exact_mod_cast h)]
      · rw [min_eq_right h, min_eq_right (by exact_mod_cast h)]; simp
    · have hH := hit_eq_N W hcont g hg N ω hne
      simp only [τN] at hH ⊢
      rw [hH]
      have : τ ω = ⊤ :=
        le_antisymm le_top (le_iInf₂ fun t ht => absurd ⟨t, (hgiff _).2 ht⟩ hne)
      rw [this]; simp
  have hτsup : τ = fun ω => ⨆ N : ℕ, ((τN N ω : ℝ≥0) : ℝ≥0∞) := by
    ext ω; simp_rw [hmin]; rw [← inf_iSup_eq, ENNReal.iSup_natCast, inf_top_eq]
  have hτmeas : Measurable τ := by
    rw [hτsup]; exact Measurable.iSup fun N => (hτNm N).coe_nnreal_ennreal
  have hmono : Monotone fun N ω => ((τN N ω : ℝ≥0) : ℝ≥0∞) := by
    intro N M hNM ω
    simp only [hmin]
    exact min_le_min_left _ (by exact_mod_cast hNM)
  have hlin : ∀ N, ∫⁻ ω, ((τN N ω : ℝ≥0) : ℝ≥0∞) ∂P =
      ENNReal.ofReal (∫ ω, W (τN N ω) ω ^ 2 ∂P) := by
    intro N
    rw [hsq N, ofReal_integral_eq_lintegral_ofReal (hτNi N)
      (Filter.Eventually.of_forall fun ω => NNReal.coe_nonneg _)]
    simp [ENNReal.ofReal_coe_nnreal]
  have hlimτ : Tendsto (fun N => ∫⁻ ω, ((τN N ω : ℝ≥0) : ℝ≥0∞) ∂P) atTop
      (𝓝 (∫⁻ ω, τ ω ∂P)) := by
    rw [hτsup, lintegral_iSup (fun N => (hτNm N).coe_nnreal_ennreal) hmono]
    exact tendsto_atTop_iSup (fun N M h => lintegral_mono (hmono h))
  have hfin : ∫⁻ ω, τ ω ∂P ≠ ⊤ := by
    refine ne_top_of_le_ne_top ENNReal.ofReal_ne_top
      (le_of_tendsto' hlimτ (fun N => ?_) : _ ≤ ENNReal.ofReal (a ^ 2 + b ^ 2))
    rw [hlin N]
    refine ENNReal.ofReal_le_ofReal ?_
    have := integral_mono_ae (hWτ2i N) (integrable_const (a ^ 2 + b ^ 2)) (by
      filter_upwards [hgood] with ω hω
      exact hsqb _ (hω N).1 (hω N).2)
    simpa using this
  have hτfin : ∀ᵐ ω ∂P, τ ω < ⊤ := ae_lt_top hτmeas hfin
  set T : Ω → ℝ≥0 := fun ω => (τ ω).toNNReal with hT_def
  have hTm : Measurable T := hτmeas.ennreal_toNNReal
  have hWTm : Measurable fun ω => W (T ω) ω := measurable_stopped W hWm hcont T hTm
  have hev : ∀ ω, τ ω < ⊤ → ∀ᶠ N in atTop, τN N ω = T ω ∧ T ω < (N : ℝ≥0) := by
    intro ω hω
    obtain ⟨N0, hN0⟩ := exists_nat_gt (T ω)
    filter_upwards [eventually_ge_atTop N0] with N hN
    have hTN : T ω < (N : ℝ≥0) := hN0.trans_le (by exact_mod_cast hN)
    refine ⟨?_, hTN⟩
    have h1 := hmin N ω
    have hτT : τ ω = (T ω : ℝ≥0∞) := (ENNReal.coe_toNNReal hω.ne).symm
    rw [hτT, min_eq_left (by exact_mod_cast hTN.le)] at h1
    exact_mod_cast h1
  have hWT_vals : ∀ᵐ ω ∂P, W (T ω) ω = -a ∨ W (T ω) ω = b := by
    filter_upwards [hgood, hτfin] with ω hgω hfω
    obtain ⟨N, hN1, hN2⟩ := (hev ω hfω).exists
    have hb1 := hgω N
    rw [hN1] at hb1
    have hm : g (W (τN N ω) ω) ≤ 0 ∨ (N : ℝ≥0) ≤ τN N ω := hit_mem W hcont g hg N ω
    rw [hN1] at hm
    rcases hm with hm | hm
    · rcases (hgiff _).1 hm with h | h
      · left; linarith [hb1.1]
      · right; linarith [hb1.2]
    · exact absurd hm (not_le.2 hN2)
  have hconv : ∀ᵐ ω ∂P, Tendsto (fun N => W (τN N ω) ω) atTop (𝓝 (W (T ω) ω)) := by
    filter_upwards [hτfin] with ω hω
    exact tendsto_const_nhds.congr' ((hev ω hω).mono fun N hN => by
      show W (T ω) ω = W (τN N ω) ω
      rw [hN.1])
  have hEWT : ∫ ω, W (T ω) ω ∂P = 0 := by
    have := tendsto_integral_of_dominated_convergence (fun _ => a + b)
      (fun N => (hWτm N).aestronglyMeasurable) (integrable_const _) (fun N => by
        filter_upwards [hgood] with ω hω
        rw [Real.norm_eq_abs, abs_le]; constructor <;> linarith [(hω N).1, (hω N).2]) hconv
    simp only [hint0] at this
    exact tendsto_nhds_unique this tendsto_const_nhds
  have hEWT2 : Tendsto (fun N => ∫ ω, W (τN N ω) ω ^ 2 ∂P) atTop
      (𝓝 (∫ ω, W (T ω) ω ^ 2 ∂P)) :=
    tendsto_integral_of_dominated_convergence (fun _ => a ^ 2 + b ^ 2)
      (fun N => ((hWτm N).pow_const 2).aestronglyMeasurable) (integrable_const _) (fun N => by
        filter_upwards [hgood] with ω hω
        rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]
        exact hsqb _ (hω N).1 (hω N).2) (hconv.mono fun ω h => h.pow 2)
  set A : Set Ω := {ω | W (T ω) ω = b} with hA_def
  have hA : MeasurableSet A := measurableSet_eq_fun hWTm measurable_const
  have hWT_eq : (fun ω => W (T ω) ω) =ᵐ[P] fun ω => A.indicator (fun _ => a + b) ω - a := by
    filter_upwards [hWT_vals] with ω h
    by_cases hω : ω ∈ A
    · rw [Set.indicator_of_mem hω]
      have : W (T ω) ω = b := hω
      rw [this]; ring
    · rw [Set.indicator_of_notMem hω]
      rcases h with h | h
      · rw [h]; ring
      · exact absurd h hω
  have hWT2_eq : (fun ω => W (T ω) ω ^ 2) =ᵐ[P]
      fun ω => A.indicator (fun _ => b ^ 2 - a ^ 2) ω + a ^ 2 := by
    filter_upwards [hWT_vals] with ω h
    by_cases hω : ω ∈ A
    · rw [Set.indicator_of_mem hω]
      have : W (T ω) ω = b := hω
      rw [this]; ring
    · rw [Set.indicator_of_notMem hω]
      rcases h with h | h
      · rw [h]; ring
      · exact absurd h hω
  have hab : 0 < a + b := by linarith
  have hp : P.real A = a / (a + b) := by
    rw [integral_congr_ae hWT_eq, integral_sub ((integrable_const (a + b)).indicator hA)
      (integrable_const _), integral_indicator_const _ hA, integral_const] at hEWT
    simp only [smul_eq_mul, probReal_univ, one_mul] at hEWT
    field_simp
    linarith
  have hE2 : ∫ ω, W (T ω) ω ^ 2 ∂P = a * b := by
    rw [integral_congr_ae hWT2_eq, integral_add ((integrable_const _).indicator hA)
      (integrable_const _), integral_indicator_const _ hA, integral_const, hp]
    simp only [smul_eq_mul, probReal_univ, one_mul]
    field_simp
    ring
  have hEA : {ω | ∃ t : ℝ≥0, W t ω = b ∧ ∀ s < t, W s ω ∈ Set.Ioo (-a) b} =ᵐ[P] A := by
    filter_upwards [hτfin, hWT_vals] with ω hfω hvω
    apply propext
    show (∃ t : ℝ≥0, W t ω = b ∧ ∀ s < t, W s ω ∈ Set.Ioo (-a) b) ↔ W (T ω) ω = b
    obtain ⟨N, hN1, hN2⟩ := (hev ω hfω).exists
    have hτT : τ ω = (T ω : ℝ≥0∞) := (ENNReal.coe_toNNReal hfω.ne).symm
    constructor
    · rintro ⟨t, ht, hts⟩
      have hTt : T ω ≤ t := by
        have : τ ω ≤ t := iInf₂_le t (Or.inr ht.ge)
        rw [hτT] at this
        exact_mod_cast this
      rcases eq_or_lt_of_le hTt with h | h
      · rw [h]; exact ht
      · have := hts _ h
        rcases hvω with h' | h'
        · rw [h'] at this; exact absurd this.1 (lt_irrefl _)
        · rw [h'] at this; exact absurd this.2 (lt_irrefl _)
    · intro hT
      refine ⟨T ω, hT, fun s hs => ?_⟩
      have hs' : s < τN N ω := hN1 ▸ hs
      exact hgpos _ (hit_pos_before W g N ω s hs')
  refine ⟨by rw [measureReal_congr hEA, hp], tendsto_nhds_unique hlimτ ?_⟩
  simp_rw [hlin]
  rw [← hE2]
  exact (ENNReal.continuous_ofReal.tendsto _).comp hEWT2

/-- Pricing the crossing of one level, with no left wall: for a level `b > 0` and a rate
`λ > 0`, the first time `τ_b` the grain reaches `+b` satisfies `E[e^(-λ τ_b)] = e^(-b √(2λ))`.
Paths that never reach `b` would count 0 (that is `e^(-λ ∞)`), so the integral runs over the
paths that do reach `b`, with `τ_b` the least such time. -/
theorem level_crossing_laplace {Ω : Type*} {mΩ : MeasurableSpace Ω} (P : Measure Ω)
    [IsProbabilityMeasure P] (ℱ : Filtration ℝ≥0 mΩ) (W : ℝ≥0 → Ω → ℝ)
    (hadapt : Adapted ℱ W) (h0 : W 0 =ᵐ[P] 0)
    (hlaw : ∀ s t : ℝ≥0, s ≤ t → HasLaw (W t - W s) (gaussianReal 0 (t - s)) P)
    (hindep : ∀ s t : ℝ≥0, s ≤ t →
      Indep (MeasurableSpace.comap (W t - W s) inferInstance) (ℱ s) P)
    (hcont : ∀ ω, Continuous fun t => W t ω)
    (b lam : ℝ) (hb : 0 < b) (hlam : 0 < lam) :
    ∫ ω in {ω | ∃ t : ℝ≥0, b ≤ W t ω},
        exp (-lam * ((sInf {t : ℝ≥0 | b ≤ W t ω} : ℝ≥0) : ℝ)) ∂P
      = exp (-b * √(2 * lam)) := by
  obtain ⟨-, -, hm3⟩ := brownian_martingales P ℱ W hadapt h0 hlaw hindep
  have hWm : ∀ u, Measurable (W u) := fun u => (hadapt u).mono (ℱ.le u) le_rfl
  set θ : ℝ := √(2 * lam) with hθ_def
  have hθ0 : 0 ≤ θ := Real.sqrt_nonneg _
  have hθ2 : θ ^ 2 = 2 * lam := Real.sq_sqrt (by linarith)
  have hM := hm3 θ
  set M : ℝ≥0 → Ω → ℝ := fun t ω => exp (θ * W t ω - θ ^ 2 * (t : ℝ) / 2) with hM_def
  have hMcont : ∀ ω, Continuous fun t => M t ω := fun ω =>
    Real.continuous_exp.comp ((continuous_const.mul (hcont ω)).sub
      ((continuous_const.mul NNReal.continuous_coe).div_const 2))
  have hMm : ∀ t, Measurable (M t) := fun t => (((hWm t).const_mul θ).sub_const _).exp
  set g : ℝ → ℝ := fun x => b - x with hg_def
  have hg : Continuous g := continuous_const.sub continuous_id
  have hgiff : ∀ x, g x ≤ 0 ↔ b ≤ x := fun x => sub_nonpos
  set τN : ℕ → Ω → ℝ≥0 := fun N ω => sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t}
    with hτN_def
  have hstop : ∀ N t, MeasurableSet[ℱ t] {ω | τN N ω ≤ t} := fun N t =>
    hit_stopping ℱ W hadapt hcont g hg N t
  have hτNle : ∀ N ω, τN N ω ≤ N := fun N ω => hit_le W g N ω
  have hτNm : ∀ N, Measurable (τN N) := fun N =>
    measurable_of_Iic fun t => ℱ.le t _ (hstop N t)
  have hFm : ∀ N, Measurable fun ω => M (τN N ω) ω := fun N =>
    measurable_stopped M hMm hMcont _ (hτNm N)
  have hgood : ∀ᵐ ω ∂P, ∀ N, W (τN N ω) ω ≤ b := by
    filter_upwards [h0] with ω hω N
    have hg0 : 0 < g (W 0 ω) := by
      simp only [hω, Pi.zero_apply, g, sub_zero]; exact hb
    have := hit_nonneg W hcont g hg N ω hg0
    simp only [g] at this
    linarith
  have hMbound : ∀ t ω, W t ω ≤ b → ‖M t ω‖ ≤ exp (θ * b) := by
    intro t ω h
    rw [Real.norm_eq_abs, abs_of_pos (exp_pos _)]
    apply exp_le_exp.2
    have h1 : θ * W t ω ≤ θ * b := mul_le_mul_of_nonneg_left h hθ0
    have h2 : 0 ≤ θ ^ 2 * (t : ℝ) / 2 := by positivity
    linarith
  have hOS : ∀ N, ∫ ω, M (τN N ω) ω ∂P = 1 := by
    intro N
    rw [optional_stopping_bounded P ℱ M hM hMcont (τN N) (hstop N) N (hτNle N),
      mart_integral_eq hM, integral_congr_ae (g := fun _ => (1 : ℝ))]
    · simp
    · filter_upwards [h0] with ω hω
      simp [M, hω]
  set E : Set Ω := {ω | ∃ t : ℝ≥0, b ≤ W t ω} with hE_def
  have hEm : MeasurableSet E := by
    have : E = ⋃ N : ℕ, {ω | ∃ s ≤ (N : ℝ≥0), g (W s ω) ≤ 0} := by
      ext ω
      simp only [E, Set.mem_ofPred_eq, Set.mem_iUnion]
      constructor
      · rintro ⟨t, ht⟩
        exact ⟨⌈t⌉₊, t, Nat.le_ceil t, (hgiff _).2 ht⟩
      · rintro ⟨N, s, -, hs⟩
        exact ⟨s, (hgiff _).1 hs⟩
    rw [this]
    exact MeasurableSet.iUnion fun N => ℱ.le _ _ (hit_before_measurable ℱ W hadapt hcont g hg N)
  have hconv : ∀ᵐ ω ∂P, Tendsto (fun N => M (τN N ω) ω) atTop
      (𝓝 (E.indicator (fun ω =>
        exp (θ * b - lam * ((sInf {t : ℝ≥0 | b ≤ W t ω} : ℝ≥0) : ℝ))) ω)) := by
    filter_upwards [hgood] with ω hgω
    by_cases hE : ω ∈ E
    · rw [Set.indicator_of_mem hE]
      have hne : ∃ t, g (W t ω) ≤ 0 := hE.imp fun t ht => (hgiff _).2 ht
      have hHset : {t : ℝ≥0 | g (W t ω) ≤ 0} = {t : ℝ≥0 | b ≤ W t ω} :=
        Set.ext fun t => hgiff _
      have hHc : IsClosed {t : ℝ≥0 | b ≤ W t ω} := isClosed_le continuous_const (hcont ω)
      have hHm : b ≤ W (sInf {t : ℝ≥0 | b ≤ W t ω}) ω :=
        hHc.csInf_mem hE (OrderBot.bddBelow _)
      obtain ⟨N0, hN0⟩ := exists_nat_gt (sInf {t : ℝ≥0 | b ≤ W t ω})
      have hev : ∀ᶠ N in atTop, τN N ω = sInf {t : ℝ≥0 | b ≤ W t ω} := by
        filter_upwards [eventually_ge_atTop N0] with N hN
        have h1 := hit_eq_min W hcont g hg N ω hne
        rw [hHset] at h1
        show sInf {t : ℝ≥0 | g (W t ω) ≤ 0 ∨ (N : ℝ≥0) ≤ t} = _
        rw [h1, min_eq_left (hN0.le.trans (by exact_mod_cast hN))]
      obtain ⟨N1, hN1⟩ := hev.exists
      have hWT : W (sInf {t : ℝ≥0 | b ≤ W t ω}) ω = b := by
        have := hgω N1
        rw [hN1] at this
        linarith
      refine tendsto_const_nhds.congr' (hev.mono fun N hN => ?_)
      show _ = M (τN N ω) ω
      rw [hN]
      simp only [M, hWT, hθ2]
      ring_nf
    · rw [Set.indicator_of_notMem hE]
      have hne : ¬ ∃ t, g (W t ω) ≤ 0 := fun ⟨t, ht⟩ => hE ⟨t, (hgiff _).1 ht⟩
      have hτ : ∀ N, τN N ω = N := fun N => hit_eq_N W hcont g hg N ω hne
      have hlt : ∀ t, W t ω < b := fun t => not_le.1 fun h => hE ⟨t, h⟩
      have hdiv : Tendsto (fun N : ℕ => θ * b + -(lam * (N : ℝ))) atTop atBot :=
        tendsto_atBot_add_const_left _ _
          (tendsto_neg_atTop_atBot.comp (tendsto_natCast_atTop_atTop.const_mul_atTop hlam))
      have hup : Tendsto (fun N : ℕ => exp (θ * b + -(lam * (N : ℝ)))) atTop (𝓝 0) :=
        Real.tendsto_exp_atBot.comp hdiv
      refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds hup
        (fun N => (exp_pos _).le) (fun N => ?_)
      show M (τN N ω) ω ≤ _
      rw [hτ N]
      simp only [M]
      apply exp_le_exp.2
      have h1 : θ * W (N : ℝ≥0) ω ≤ θ * b := mul_le_mul_of_nonneg_left (hlt _).le hθ0
      rw [hθ2]
      push_cast
      linarith
  have hDCT := tendsto_integral_of_dominated_convergence (fun _ => exp (θ * b))
    (fun N => (hFm N).aestronglyMeasurable) (integrable_const _)
    (fun N => hgood.mono fun ω h => hMbound _ _ (h N)) hconv
  simp only [hOS] at hDCT
  have hlim := tendsto_nhds_unique hDCT tendsto_const_nhds
  rw [integral_indicator hEm] at hlim
  have hsplit : (fun ω => exp (θ * b - lam * ((sInf {t : ℝ≥0 | b ≤ W t ω} : ℝ≥0) : ℝ))) =
      fun ω => exp (θ * b) * exp (-lam * ((sInf {t : ℝ≥0 | b ≤ W t ω} : ℝ≥0) : ℝ)) := by
    ext ω; rw [← exp_add]; ring_nf
  rw [hsplit, integral_const_mul] at hlim
  have := eq_inv_of_mul_eq_one_right hlim
  rw [this, ← exp_neg]
  ring_nf

/-! The card's exact worked arithmetic: walls at -2 and +3, tracker rate 0.02 = 1/50. -/

-- The right-wall chance from E[W_τ] = 0: 3p - 2(1 - p) = 0 at p = 2/5.
example : (3 : ℚ) * (2 / 5) - 2 * (1 - 2 / 5) = 0 := by norm_num

-- The right-wall chance is a/(a+b) = 2/5 and the left-wall chance is 3/5.
example : (2 : ℚ) / (2 + 3) = 2 / 5 ∧ 1 - (2 : ℚ) / 5 = 3 / 5 := by norm_num

-- The mean exit time: 0.4 * 9 + 0.6 * 4 = 6 = 2 * 3.
example : (2 / 5 : ℚ) * 3 ^ 2 + (3 / 5) * 2 ^ 2 = 6 ∧ (2 : ℚ) * 3 = 6 := by norm_num

-- In general a/(a+b) b^2 + b/(a+b) a^2 = ab.
example (a b : ℚ) (h : a + b ≠ 0) : a / (a + b) * b ^ 2 + b / (a + b) * a ^ 2 = a * b := by
  field_simp; ring

-- The tilt for the tracker: θ = sqrt(2 * 0.02) = 0.2, so half θ squared is the rate 0.02.
example : √(2 * (1 / 50 : ℝ)) = 1 / 5 := by
  rw [show (2 * (1 / 50 : ℝ)) = (1 / 5) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : (1 / 2 : ℚ) * (1 / 5) ^ 2 = 1 / 50 := by norm_num

-- The level price exponent: b θ = 3 * 0.2 = 0.6; the stopped exponential stays below e^(θ b).
example : (3 : ℚ) * (1 / 5) = 3 / 5 := by norm_num

-- Interval: midpoint c = (b - a)/2 = 1/2, half-width 5/2; times θ they are 0.1 and 0.5.
example : ((3 : ℚ) - 2) / 2 = 1 / 2 ∧ ((2 : ℚ) + 3) / 2 = 5 / 2 := by norm_num
example : (1 / 5 : ℚ) * (1 / 2) = 1 / 10 ∧ (1 / 5 : ℚ) * (5 / 2) = 1 / 2 := by norm_num

-- At the exit, W_τ - c is +5/2 or -5/2: 3 - 1/2 = 5/2 and -2 - 1/2 = -5/2.
example : (3 : ℚ) - 1 / 2 = 5 / 2 ∧ (-2 : ℚ) - 1 / 2 = -(5 / 2) := by norm_num

-- Wrong side b/(a+b) gives 3/5 instead of 2/5.
example : (3 : ℚ) / (2 + 3) = 3 / 5 := by norm_num

-- Pushing the left wall out: mean exit times 60, 600, 6000 s, right-first chances 20/23, 200/203, 2000/2003.
example : (20 : ℚ) * 3 = 60 ∧ (200 : ℚ) * 3 = 600 ∧ (2000 : ℚ) * 3 = 6000 := by norm_num
example : (20 : ℚ) / (20 + 3) = 20 / 23 ∧ (200 : ℚ) / (200 + 3) = 200 / 203 ∧
    (2000 : ℚ) / (2000 + 3) = 2000 / 2003 := by norm_num

#print axioms brownian_martingales
#print axioms exit_side_and_mean_exit_time
#print axioms level_crossing_laplace
