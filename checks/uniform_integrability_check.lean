-- Uniform integrability: on a finite measure space a family of integrable random variables has tails that vanish uniformly exactly when its averages are bounded and no member hides much mass on a small event, bounds in a power p > 1 give this, and convergence in probability plus it is exactly convergence in mean (Vitali).
import Mathlib.MeasureTheory.Function.ConvergenceInMeasure
import Mathlib.MeasureTheory.Function.UniformIntegrable
import Mathlib.MeasureTheory.Integral.Bochner.Set

open MeasureTheory Filter Topology

/-- Helper: the `L^1` seminorm of a real function is the lower integral of `|f|`. -/
lemma ui_eLpNorm_one_real {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) (f : Ω → ℝ)
    (hf : AEStronglyMeasurable f μ) :
    eLpNorm f 1 μ = ∫⁻ ω, ENNReal.ofReal |f ω| ∂μ := by
  rw [eLpNorm_one_eq_lintegral_enorm hf]
  simp only [Real.enorm_eq_ofReal_abs]

/-- Helper: the mass of `|f|` on any set `A` is at most `K · P(A)` plus the tail beyond `K`. -/
lemma ui_setLIntegral_le {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) (f : Ω → ℝ)
    (hf : AEStronglyMeasurable f P) (K : ℝ) (A : Set Ω) :
    ∫⁻ ω in A, ENNReal.ofReal |f ω| ∂P ≤
      ENNReal.ofReal K * P A + ∫⁻ ω in {ω | K < |f ω|}, ENNReal.ofReal |f ω| ∂P := by
  have hS : NullMeasurableSet {ω | K < |f ω|} P :=
    nullMeasurableSet_lt aemeasurable_const
      (continuous_abs.comp_aestronglyMeasurable hf).aemeasurable
  calc ∫⁻ ω in A, ENNReal.ofReal |f ω| ∂P
      ≤ ∫⁻ ω in A, (ENNReal.ofReal K +
          {ω | K < |f ω|}.indicator (fun ω => ENNReal.ofReal |f ω|) ω) ∂P := by
        apply lintegral_mono
        intro ω
        dsimp only
        by_cases h : K < |f ω|
        · have h' : ω ∈ {ω | K < |f ω|} := h
          rw [Set.indicator_of_mem h']
          exact le_add_self
        · have h' : ω ∉ {ω | K < |f ω|} := h
          simp only [Set.indicator_of_notMem h', add_zero]
          exact ENNReal.ofReal_le_ofReal (not_lt.1 h)
    _ = ENNReal.ofReal K * P A +
          ∫⁻ ω in A, {ω | K < |f ω|}.indicator (fun ω => ENNReal.ofReal |f ω|) ω ∂P := by
        rw [lintegral_add_left measurable_const, setLIntegral_const]
    _ ≤ ENNReal.ofReal K * P A +
          ∫⁻ ω, {ω | K < |f ω|}.indicator (fun ω => ENNReal.ofReal |f ω|) ω ∂P := by
        exact add_le_add le_rfl (setLIntegral_le_lintegral _ _)
    _ = _ := by rw [lintegral_indicator₀ hS]

/-- Helper: the tail form of uniform integrability is equivalent to bounded averages plus
uniform absolute continuity (same statement as the theorem below). -/
lemma ui_tail_iff {Ω ι : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsFiniteMeasure P]
    (X : ι → Ω → ℝ) (hX : ∀ i, Integrable (X i) P) :
    Tendsto (fun K : ℝ => ⨆ i, ∫⁻ ω in {ω | K < |X i ω|}, ENNReal.ofReal |X i ω| ∂P)
        atTop (𝓝 0) ↔
    ((⨆ i, ∫⁻ ω, ENNReal.ofReal |X i ω| ∂P) < ⊤ ∧
      ∀ ε : ℝ, 0 < ε → ∃ δ : ℝ, 0 < δ ∧ ∀ A : Set Ω, MeasurableSet A →
        P A < ENNReal.ofReal δ →
        (⨆ i, ∫⁻ ω in A, ENNReal.ofReal |X i ω| ∂P) < ENNReal.ofReal ε) := by
  have hmeas : ∀ i, AEStronglyMeasurable (X i) P := fun i => (hX i).aestronglyMeasurable
  constructor
  · intro hT
    refine ⟨?_, ?_⟩
    · have hev := (ENNReal.tendsto_nhds_zero.1 hT) 1 one_pos
      rw [eventually_atTop] at hev
      obtain ⟨K, hK⟩ := hev
      have hfin : ENNReal.ofReal K * P Set.univ + 1 < ⊤ :=
        ENNReal.add_lt_top.2
          ⟨ENNReal.mul_lt_top ENNReal.ofReal_lt_top (measure_lt_top P _), ENNReal.one_lt_top⟩
      refine lt_of_le_of_lt (iSup_le fun i => ?_) hfin
      have h1 := ui_setLIntegral_le P (X i) (hmeas i) K Set.univ
      rw [Measure.restrict_univ] at h1
      refine h1.trans (add_le_add le_rfl ?_)
      exact (le_iSup (fun i => ∫⁻ ω in {ω | K < |X i ω|}, ENNReal.ofReal |X i ω| ∂P) i).trans
        (hK K le_rfl)
    · intro ε hε
      have hev := (ENNReal.tendsto_nhds_zero.1 hT) (ENNReal.ofReal (ε / 4))
        (by simp only [ENNReal.ofReal_pos]; linarith)
      rw [eventually_atTop] at hev
      obtain ⟨K₀, hK₀⟩ := hev
      set K := max K₀ 1 with hKdef
      have hKpos : 0 < K := lt_of_lt_of_le one_pos (le_max_right _ _)
      refine ⟨ε / (4 * K), by positivity, fun A _ hPA => ?_⟩
      have hb : ∀ i, ∫⁻ ω in A, ENNReal.ofReal |X i ω| ∂P ≤
          ENNReal.ofReal (ε / 4) + ENNReal.ofReal (ε / 4) := by
        intro i
        refine (ui_setLIntegral_le P (X i) (hmeas i) K A).trans (add_le_add ?_ ?_)
        · calc ENNReal.ofReal K * P A ≤ ENNReal.ofReal K * ENNReal.ofReal (ε / (4 * K)) := by
                gcongr
            _ = ENNReal.ofReal (ε / 4) := by
                rw [← ENNReal.ofReal_mul hKpos.le]
                congr 1
                field_simp
        · exact (le_iSup (fun i => ∫⁻ ω in {ω | K < |X i ω|}, ENNReal.ofReal |X i ω| ∂P) i).trans
            (hK₀ K (le_max_left _ _))
      calc (⨆ i, ∫⁻ ω in A, ENNReal.ofReal |X i ω| ∂P)
          ≤ ENNReal.ofReal (ε / 4) + ENNReal.ofReal (ε / 4) := iSup_le hb
        _ = ENNReal.ofReal (ε / 2) := by
            rw [← ENNReal.ofReal_add (by positivity) (by positivity)]
            ring_nf
        _ < ENNReal.ofReal ε := (ENNReal.ofReal_lt_ofReal_iff hε).2 (by linarith)
  · rintro ⟨hB, hAC⟩
    rw [ENNReal.tendsto_nhds_zero]
    intro ε hε
    by_cases hεtop : ε = ⊤
    · exact Eventually.of_forall fun _ => hεtop ▸ le_top
    have hε' : 0 < ε.toReal := ENNReal.toReal_pos hε.ne' hεtop
    obtain ⟨δ, hδ, hA⟩ := hAC ε.toReal hε'
    set B := ⨆ i, ∫⁻ ω, ENNReal.ofReal |X i ω| ∂P with hBdef
    rw [eventually_atTop]
    refine ⟨(B.toReal + 1) / δ, fun K hK => ?_⟩
    have hK0 : 0 < (B.toReal + 1) / δ := by positivity
    have hKpos : 0 < K := lt_of_lt_of_le hK0 hK
    have hBK : B.toReal < δ * K := by
      have := (div_le_iff₀ hδ).1 hK
      linarith
    refine iSup_le fun i => ?_
    set S := {ω | K < |X i ω|} with hSdef
    have hae : AEMeasurable (fun ω => ENNReal.ofReal |X i ω|) P :=
      (continuous_abs.comp_aestronglyMeasurable (hmeas i)).aemeasurable.ennreal_ofReal
    have hPS : P S < ENNReal.ofReal δ := by
      calc P S ≤ P {ω | ENNReal.ofReal K ≤ ENNReal.ofReal |X i ω|} := by
            apply measure_mono
            intro ω hω
            exact ENNReal.ofReal_le_ofReal (le_of_lt hω)
        _ ≤ (∫⁻ ω, ENNReal.ofReal |X i ω| ∂P) / ENNReal.ofReal K :=
            meas_ge_le_lintegral_div hae (by simp [hKpos]) ENNReal.ofReal_ne_top
        _ ≤ B / ENNReal.ofReal K := by
            gcongr
            exact le_iSup (fun i => ∫⁻ ω, ENNReal.ofReal |X i ω| ∂P) i
        _ < ENNReal.ofReal δ := by
            apply ENNReal.div_lt_of_lt_mul
            rw [← ENNReal.ofReal_mul hδ.le, ← ENNReal.ofReal_toReal hB.ne]
            exact (ENNReal.ofReal_lt_ofReal_iff (by positivity)).2 hBK
    have hT := hA (toMeasurable P S) (measurableSet_toMeasurable P S)
      (by rw [measure_toMeasurable]; exact hPS)
    rw [ENNReal.ofReal_toReal hεtop] at hT
    calc ∫⁻ ω in S, ENNReal.ofReal |X i ω| ∂P
        ≤ ∫⁻ ω in toMeasurable P S, ENNReal.ofReal |X i ω| ∂P :=
          lintegral_mono_set (subset_toMeasurable P S)
      _ ≤ ⨆ i, ∫⁻ ω in toMeasurable P S, ENNReal.ofReal |X i ω| ∂P :=
          le_iSup (fun i => ∫⁻ ω in toMeasurable P S, ENNReal.ofReal |X i ω| ∂P) i
      _ ≤ ε := hT.le

/-- Helper: bounded averages plus uniform absolute continuity is Mathlib's
`UniformIntegrable X 1 P`. -/
lemma ui_bdd_uac_iff_uniformIntegrable {Ω ι : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (X : ι → Ω → ℝ) (hX : ∀ i, Integrable (X i) P) :
    ((⨆ i, ∫⁻ ω, ENNReal.ofReal |X i ω| ∂P) < ⊤ ∧
      ∀ ε : ℝ, 0 < ε → ∃ δ : ℝ, 0 < δ ∧ ∀ A : Set Ω, MeasurableSet A →
        P A < ENNReal.ofReal δ →
        (⨆ i, ∫⁻ ω in A, ENNReal.ofReal |X i ω| ∂P) < ENNReal.ofReal ε) ↔
    UniformIntegrable X 1 P := by
  have hm : ∀ i, AEStronglyMeasurable (X i) P := fun i => (hX i).aestronglyMeasurable
  simp only [UniformIntegrable, ui_eLpNorm_one_real P _ (hm _)]
  constructor
  · rintro ⟨hB, hAC⟩
    refine ⟨?_, ⟨(⨆ i, ∫⁻ ω, ENNReal.ofReal |X i ω| ∂P).toNNReal, fun i => ?_⟩⟩
    · rw [unifIntegrable_iff']
      intro ε hε
      by_cases hεtop : ε = ⊤
      · exact ⟨1, one_pos, fun _ _ _ _ => hεtop ▸ le_top⟩
      obtain ⟨δ, hδ, hA⟩ := hAC ε.toReal (ENNReal.toReal_pos hε.ne' hεtop)
      refine ⟨ENNReal.ofReal (δ / 2), by simp only [gt_iff_lt, ENNReal.ofReal_pos]; linarith,
        fun i s hs hPs => ?_⟩
      rw [ui_eLpNorm_one_real _ _ (hm i).restrict]
      have hlt := hA s hs (hPs.trans_lt ((ENNReal.ofReal_lt_ofReal_iff hδ).2 (by linarith)))
      rw [ENNReal.ofReal_toReal hεtop] at hlt
      exact (le_iSup (fun i => ∫⁻ ω in s, ENNReal.ofReal |X i ω| ∂P) i).trans hlt.le
    · rw [ENNReal.coe_toNNReal hB.ne]
      exact le_iSup (fun i => ∫⁻ ω, ENNReal.ofReal |X i ω| ∂P) i
  · rintro ⟨hU, C, hC⟩
    refine ⟨lt_of_le_of_lt (iSup_le hC) ENNReal.coe_lt_top, fun ε hε => ?_⟩
    obtain ⟨δ, hδ, hs⟩ := unifIntegrable_iff'.1 hU (ENNReal.ofReal (ε / 2))
      (by simp only [gt_iff_lt, ENNReal.ofReal_pos]; linarith)
    obtain ⟨r, _, hr1, hr2⟩ := ENNReal.lt_iff_exists_real_btwn.1 hδ
    refine ⟨r, ENNReal.ofReal_pos.1 hr1, fun A hA hPA => ?_⟩
    refine lt_of_le_of_lt (iSup_le fun i => ?_)
      ((ENNReal.ofReal_lt_ofReal_iff hε).2 (by linarith : ε / 2 < ε))
    have := hs i A hA (hPA.le.trans hr2.le)
    rwa [ui_eLpNorm_one_real _ _ (hm i).restrict] at this

#print axioms ui_eLpNorm_one_real
#print axioms ui_setLIntegral_le
#print axioms ui_tail_iff
#print axioms ui_bdd_uac_iff_uniformIntegrable


/-- Vitali's theorem, as on the card: on a probability space (any finite measure works),
let `X n` be integrable random variables and `X` a random variable. Then `X n → X` in
probability and the family `{X n}` is uniformly integrable, meaning the worst tail
`sup_n E[|X n| 1{|X n| > K}]` tends to 0 as the cutoff `K` grows, exactly when `X` is
integrable and `E|X n - X| → 0`: convergence in probability upgrades to convergence in mean
exactly when the sequence is uniformly integrable. -/
theorem vitali_convergence_in_probability_and_ui_iff_convergence_in_mean
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsFiniteMeasure P]
    (X : ℕ → Ω → ℝ) (Xlim : Ω → ℝ)
    (hX : ∀ n, Integrable (X n) P) (hXlim : Measurable Xlim) :
    (TendstoInMeasure P X atTop Xlim ∧
      Tendsto (fun K : ℝ => ⨆ n, ∫⁻ ω in {ω | K < |X n ω|}, ENNReal.ofReal |X n ω| ∂P)
        atTop (𝓝 0)) ↔
    (Integrable Xlim P ∧
      Tendsto (fun n => ∫ ω, |X n ω - Xlim ω| ∂P) atTop (𝓝 0)) := by
  have hmeas : ∀ n, AEStronglyMeasurable (X n) P := fun n => (hX n).aestronglyMeasurable
  have hT_iff := (ui_tail_iff P X hX).trans (ui_bdd_uac_iff_uniformIntegrable P X hX)
  have hconv : ∀ g : Ω → ℝ, Integrable g P →
      (Tendsto (fun n => ∫ ω, |X n ω - g ω| ∂P) atTop (𝓝 0) ↔
        Tendsto (fun n => eLpNorm (X n - g) 1 P) atTop (𝓝 0)) := by
    intro g hg
    have heq : ∀ n, eLpNorm (X n - g) 1 P = ENNReal.ofReal (∫ ω, |X n ω - g ω| ∂P) := by
      intro n
      rw [eLpNorm_one_eq_lintegral_enorm ((hX n).sub hg).aestronglyMeasurable, ← ofReal_integral_norm_eq_lintegral_enorm ((hX n).sub hg)]
      simp [Real.norm_eq_abs]
    simp_rw [heq]
    constructor
    · intro h
      simpa using ENNReal.tendsto_ofReal h
    · intro h
      have := (ENNReal.tendsto_toReal ENNReal.zero_ne_top).comp h
      have hnn : ∀ n, 0 ≤ ∫ ω, |X n ω - g ω| ∂P := fun n => integral_nonneg fun ω => abs_nonneg _
      simpa [Function.comp_def, ENNReal.toReal_ofReal (hnn _)] using this
  rw [hT_iff]
  constructor
  · rintro ⟨hm, hUI⟩
    have hint : Integrable Xlim P := hUI.integrable_of_tendstoInMeasure hm
    refine ⟨hint, (hconv Xlim hint).2 ?_⟩
    exact tendsto_Lp_finite_of_tendstoInMeasure le_rfl ENNReal.one_ne_top hmeas
      (memLp_one_iff_integrable.2 hint) hUI.1 hm
  · rintro ⟨hint, hL⟩
    have hL' := (hconv Xlim hint).1 hL
    obtain ⟨hm, hU⟩ := (tendstoInMeasure_iff_tendsto_Lp_finite le_rfl ENNReal.one_ne_top
      (fun n => memLp_one_iff_integrable.2 (hX n)) (memLp_one_iff_integrable.2 hint)).2 hL'
    refine ⟨hm, hU, ?_⟩
    have hev := (ENNReal.tendsto_nhds_zero.1 hL') 1 one_pos
    rw [eventually_atTop] at hev
    obtain ⟨N, hN⟩ := hev
    set C : ENNReal := (∑ n ∈ Finset.range N, eLpNorm (X n) 1 P) + (1 + eLpNorm Xlim 1 P)
      with hCdef
    have hCfin : C ≠ ⊤ := by
      refine ENNReal.add_ne_top.2 ⟨?_, ?_⟩
      · exact ENNReal.sum_ne_top.2 fun n _ => (memLp_one_iff_integrable.2 (hX n)).eLpNorm_ne_top
      · exact ENNReal.add_ne_top.2 ⟨ENNReal.one_ne_top,
          (memLp_one_iff_integrable.2 hint).eLpNorm_ne_top⟩
    refine ⟨C.toNNReal, fun n => ?_⟩
    rw [ENNReal.coe_toNNReal hCfin]
    by_cases hn : n < N
    · refine le_trans ?_ le_self_add
      exact Finset.single_le_sum (f := fun n => eLpNorm (X n) 1 P) (fun _ _ => zero_le)
        (Finset.mem_range.2 hn)
    · refine le_trans ?_ le_add_self
      calc eLpNorm (X n) 1 P = eLpNorm ((X n - Xlim) + Xlim) 1 P := by rw [sub_add_cancel]
        _ ≤ eLpNorm (X n - Xlim) 1 P + eLpNorm Xlim 1 P := eLpNorm_add_le le_rfl
        _ ≤ 1 + eLpNorm Xlim 1 P := by gcongr; exact hN n (not_lt.1 hn)

/-- The equivalent form of uniform integrability: on a probability space (any finite
measure works), a family of integrable random variables has worst tail
`sup E[|X| 1{|X| > K}]` tending to 0 as `K` grows exactly when (i) the averages `E|X|` are
bounded over the family and (ii) for every `ε > 0` there is a `δ > 0` such that every event
`A` with `P(A) < δ` has `sup E[|X| 1_A] < ε`: uniform absolute continuity of the integral. -/
theorem uniformly_integrable_iff_bounded_and_uniformly_absolutely_continuous
    {Ω ι : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsFiniteMeasure P]
    (X : ι → Ω → ℝ) (hX : ∀ i, Integrable (X i) P) :
    Tendsto (fun K : ℝ => ⨆ i, ∫⁻ ω in {ω | K < |X i ω|}, ENNReal.ofReal |X i ω| ∂P)
        atTop (𝓝 0) ↔
    ((⨆ i, ∫⁻ ω, ENNReal.ofReal |X i ω| ∂P) < ⊤ ∧
      ∀ ε : ℝ, 0 < ε → ∃ δ : ℝ, 0 < δ ∧ ∀ A : Set Ω, MeasurableSet A →
        P A < ENNReal.ofReal δ →
        (⨆ i, ∫⁻ ω in A, ENNReal.ofReal |X i ω| ∂P) < ENNReal.ofReal ε) := by
  exact ui_tail_iff P X hX

/-- The `L^p` test: if `p > 1` and a family of integrable random variables is bounded in
`L^p`, that is `E|X|^p ≤ M` for every member, then the family is uniformly integrable: its
worst tail `sup E[|X| 1{|X| > K}]` tends to 0 as `K` grows (each tail is at most
`M / K^(p-1)`). -/
theorem uniformly_integrable_of_bounded_in_Lp
    {Ω ι : Type*} [MeasurableSpace Ω] (P : Measure Ω)
    (X : ι → Ω → ℝ) (hX : ∀ i, Integrable (X i) P)
    (p M : ℝ) (hp : 1 < p)
    (hM : ∀ i, ∫⁻ ω, ENNReal.ofReal (|X i ω| ^ p) ∂P ≤ ENNReal.ofReal M) :
    Tendsto (fun K : ℝ => ⨆ i, ∫⁻ ω in {ω | K < |X i ω|}, ENNReal.ofReal |X i ω| ∂P)
        atTop (𝓝 0) := by
  have hp1 : 0 < p - 1 := by linarith
  have hbound : ∀ K : ℝ, 0 < K →
      (⨆ i, ∫⁻ ω in {ω | K < |X i ω|}, ENNReal.ofReal |X i ω| ∂P) ≤
        ENNReal.ofReal M * (ENNReal.ofReal (K ^ (p - 1)))⁻¹ := by
    intro K hK
    have hKp : 0 < K ^ (p - 1) := Real.rpow_pos_of_pos hK _
    have hcinv : (ENNReal.ofReal (K ^ (p - 1)))⁻¹ ≠ ⊤ := by
      simp [hKp]
    refine iSup_le fun i => ?_
    have hS : NullMeasurableSet {ω | K < |X i ω|} P :=
      nullMeasurableSet_lt aemeasurable_const
        (continuous_abs.comp_aestronglyMeasurable (hX i).aestronglyMeasurable).aemeasurable
    calc ∫⁻ ω in {ω | K < |X i ω|}, ENNReal.ofReal |X i ω| ∂P
        ≤ ∫⁻ ω in {ω | K < |X i ω|},
            ENNReal.ofReal (|X i ω| ^ p) * (ENNReal.ofReal (K ^ (p - 1)))⁻¹ ∂P := by
          refine lintegral_mono_ae ?_
          filter_upwards [ae_restrict_mem₀ hS] with ω hω
          have hω' : K < |X i ω| := hω
          have hxpos : 0 < |X i ω| := hK.trans hω'
          have hsplit : |X i ω| ^ p = |X i ω| * |X i ω| ^ (p - 1) := by
            conv_lhs => rw [show p = 1 + (p - 1) by ring]
            rw [Real.rpow_add hxpos, Real.rpow_one]
          have key : |X i ω| ≤ |X i ω| ^ p / K ^ (p - 1) := by
            rw [le_div_iff₀ hKp, hsplit]
            gcongr
          calc ENNReal.ofReal |X i ω| ≤ ENNReal.ofReal (|X i ω| ^ p / K ^ (p - 1)) :=
                ENNReal.ofReal_le_ofReal key
            _ = ENNReal.ofReal (|X i ω| ^ p) * (ENNReal.ofReal (K ^ (p - 1)))⁻¹ := by
                rw [ENNReal.ofReal_div_of_pos hKp, div_eq_mul_inv]
      _ = (∫⁻ ω in {ω | K < |X i ω|}, ENNReal.ofReal (|X i ω| ^ p) ∂P) *
            (ENNReal.ofReal (K ^ (p - 1)))⁻¹ := lintegral_mul_const' _ _ hcinv
      _ ≤ (∫⁻ ω, ENNReal.ofReal (|X i ω| ^ p) ∂P) * (ENNReal.ofReal (K ^ (p - 1)))⁻¹ := by
          exact mul_le_mul' (setLIntegral_le_lintegral _ _) le_rfl
      _ ≤ ENNReal.ofReal M * (ENNReal.ofReal (K ^ (p - 1)))⁻¹ := by
          gcongr
          exact hM i
  have hlim : Tendsto (fun K : ℝ => ENNReal.ofReal M * (ENNReal.ofReal (K ^ (p - 1)))⁻¹)
      atTop (𝓝 0) := by
    have h1 : Tendsto (fun K : ℝ => K ^ (p - 1)) atTop atTop := tendsto_rpow_atTop hp1
    have h2 : Tendsto (fun K : ℝ => ENNReal.ofReal (K ^ (p - 1))) atTop (𝓝 ⊤) :=
      ENNReal.tendsto_ofReal_atTop.comp h1
    have h3 : Tendsto (fun K : ℝ => (ENNReal.ofReal (K ^ (p - 1)))⁻¹) atTop (𝓝 0) := by
      exact ENNReal.inv_top ▸ tendsto_inv_iff.2 h2
    simpa using ENNReal.Tendsto.const_mul h3 (Or.inr ENNReal.ofReal_ne_top)
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' tendsto_const_nhds hlim
    (Eventually.of_forall fun _ => zero_le) ?_
  filter_upwards [eventually_gt_atTop 0] with K hK using hbound K hK

/-! The card's exact worked numbers, as fractions. -/

-- lottery ticket 1,000: pays 1,000 dollars with probability 1/1,000, average 1 dollar
example : (1000 : ℚ) * (1 / 1000) = 1 := by norm_num

-- capped at 100: ticket 1,000 averages min(1000, 100) × 1/1,000 = 1/10 dollar;
-- on the event {U < 1/1000} a capped ticket carries at most 100 × 1/1000 = 1/10
example : (min 1000 100 : ℚ) * (1 / 1000) = 1 / 10 := by norm_num

-- square-root ticket: E R_n^2 = (√n)^2 × 1/n = n × 1/n = 1, here at n = 10,001
example : (10001 : ℚ) * (1 / 10001) = 1 := by norm_num

-- disjoint ticket: worst tail at K = 10 is ticket 11's, 11 × 1/(11 × 12) = 1/(10 + 2) = 1/12
example : (11 : ℚ) * (1 / (11 * 12)) = 1 / (10 + 2) := by norm_num

-- Vitali's bound for the capped tickets at n = 1,000, ε = 1/100:
-- ε + min(1, 100/1000) = 11/100, against the true error 1/10
example : (1 / 100 : ℚ) + min 1 (100 / 1000) = 11 / 100 ∧
    (1 / 10 : ℚ) ≤ 11 / 100 := by norm_num

#print axioms vitali_convergence_in_probability_and_ui_iff_convergence_in_mean
#print axioms uniformly_integrable_iff_bounded_and_uniformly_absolutely_continuous
#print axioms uniformly_integrable_of_bounded_in_Lp
