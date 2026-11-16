-- Wiener-Khinchin: for a stationary random signal with a continuous, absolutely integrable autocorrelation, the power spectrum (the limit of the averaged windowed transform squared, over the window length) is the Fourier transform of the autocorrelation, it is never negative with area equal to the mean square, and a stable filter multiplies it by its gain squared.
import Mathlib.Analysis.Fourier.FourierTransform
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.MeasureTheory.Integral.DominatedConvergence
import Mathlib.MeasureTheory.Group.Integral

/-! A random signal is `X : ℝ → Ω → ℝ`: its value in µV at time `t` (seconds) on the run `ω` of
the chance space `Ω`, which carries a probability measure `P`; `∫ ω, · ∂P` is the average `𝔼`.
"Stationary with autocorrelation `R`" is `𝔼[X(t + τ) X(t)] = R(τ)` for all `t` and `τ`, with
finite mean squares (`MemLp (X t) 2 P`), and `X` measurable in time and chance together.
`𝓕 f ξ` is Mathlib's Fourier transform in hertz, `∫ e^(−2πiξτ) f(τ) dτ`, the card's `f̂(ξ)`.
The windowed transform of one run is `X̂_T(ξ) = ∫_{−T/2}^{T/2} X(t) e^(−2πiξt) dt`, and the
card's power spectrum `S_X(ξ)` is the limit of `(1/T) 𝔼 |X̂_T(ξ)|²` as `T → ∞`. -/

open MeasureTheory Filter Topology FourierTransform Real

variable {Ω : Type*} [MeasurableSpace Ω]

/-- The windowed power `(1/T) 𝔼 |X̂_T(ξ)|²` of a random signal `X` at frequency `ξ`, for a window
of length `T` seconds centred at time 0. Its limit as `T → ∞` is the power spectrum `S_X(ξ)`. -/
noncomputable def windowedPower (P : Measure Ω) (X : ℝ → Ω → ℝ) (T ξ : ℝ) : ℝ :=
  (1 / T) * ∫ ω, ‖∫ t in (-(T / 2))..(T / 2),
    Complex.exp (-((2 * π * ξ * t : ℝ) : ℂ) * Complex.I) * (X t ω : ℂ)‖ ^ 2 ∂P


/-- The phase factor of a Fourier transform in hertz. -/
lemma wk_norm_exp_neg (r : ℝ) : ‖Complex.exp (-((r : ℝ) : ℂ) * Complex.I)‖ = 1 := by
  rw [← Complex.ofReal_neg, Complex.norm_exp_ofReal_mul_I]

lemma wk_exp_mul_conj (ξ t s : ℝ) :
    Complex.exp (-((2 * π * ξ * t : ℝ) : ℂ) * Complex.I) *
      (starRingEnd ℂ) (Complex.exp (-((2 * π * ξ * s : ℝ) : ℂ) * Complex.I)) =
    Complex.exp (↑(-2 * π * (t - s) * ξ) * Complex.I) := by
  rw [← Complex.exp_conj, ← Complex.exp_add]
  congr 1
  simp only [map_mul, map_neg, Complex.conj_ofReal, Complex.conj_I]
  push_cast; ring

lemma wk_abs_mul_le (x y : ℝ) : |x * y| ≤ (x ^ 2 + y ^ 2) / 2 := by
  rw [abs_mul]; nlinarith [sq_nonneg (|x| - |y|), sq_abs x, sq_abs y]

/-- The triangle weight: `T - 2|τ| ≤ ∫_{s ∈ I} 1_I(τ + s) ds ≤ T` for the window `I`. -/
lemma wk_weight_bounds (T τ : ℝ) (hT : 0 < T) :
    T - 2 * |τ| ≤ ∫ s in Set.Ioc (-(T / 2)) (T / 2),
        (Set.Ioc (-(T / 2)) (T / 2)).indicator (fun _ => (1 : ℝ)) (τ + s) ∧
    0 ≤ ∫ s in Set.Ioc (-(T / 2)) (T / 2),
        (Set.Ioc (-(T / 2)) (T / 2)).indicator (fun _ => (1 : ℝ)) (τ + s) ∧
    ∫ s in Set.Ioc (-(T / 2)) (T / 2),
        (Set.Ioc (-(T / 2)) (T / 2)).indicator (fun _ => (1 : ℝ)) (τ + s) ≤ T := by
  set I := Set.Ioc (-(T / 2)) (T / 2)
  have hind_nn : ∀ x, 0 ≤ I.indicator (fun _ => (1 : ℝ)) x :=
    fun x => Set.indicator_nonneg (fun _ _ => zero_le_one) x
  have hind_le : ∀ x, I.indicator (fun _ => (1 : ℝ)) x ≤ 1 := by
    intro x; by_cases hx : x ∈ I <;> simp [Set.indicator_of_mem, Set.indicator_of_notMem, hx]
  have hmeas : Measurable (fun s => I.indicator (fun _ => (1 : ℝ)) (τ + s)) :=
    (measurable_const.indicator measurableSet_Ioc).comp (measurable_const.add measurable_id)
  have hint : IntegrableOn (fun s => I.indicator (fun _ => (1 : ℝ)) (τ + s)) I := by
    refine Integrable.of_bound hmeas.aestronglyMeasurable 1 (ae_of_all _ fun s => ?_)
    rw [Real.norm_eq_abs, abs_of_nonneg (hind_nn _)]; exact hind_le _
  refine ⟨?_, setIntegral_nonneg measurableSet_Ioc (fun s _ => hind_nn _), ?_⟩
  · set J := Set.Ioc (-(T / 2) + |τ|) (T / 2 - |τ|)
    have hJI : J ⊆ I := by
      intro s hs; simp only [J, I, Set.mem_Ioc] at hs ⊢
      constructor <;> linarith [abs_nonneg τ]
    have h1 : ∫ s in J, I.indicator (fun _ => (1 : ℝ)) (τ + s) = ∫ s in J, (1 : ℝ) := by
      refine setIntegral_congr_fun measurableSet_Ioc (fun s hs => ?_)
      simp only [J, Set.mem_Ioc] at hs
      have : τ + s ∈ I := by
        simp only [I, Set.mem_Ioc]
        constructor <;> linarith [neg_abs_le τ, le_abs_self τ]
      simp [Set.indicator_of_mem this]
    have h2 : ∫ s in J, (1 : ℝ) = max (T - 2 * |τ|) 0 := by
      rw [setIntegral_const, smul_eq_mul, mul_one, Real.volume_real_Ioc]; congr 1; ring
    calc T - 2 * |τ| ≤ max (T - 2 * |τ|) 0 := le_max_left _ _
      _ = ∫ s in J, I.indicator (fun _ => (1 : ℝ)) (τ + s) := by rw [h1, h2]
      _ ≤ _ := setIntegral_mono_set hint (ae_of_all _ fun s => hind_nn _)
          (Eventually.of_forall hJI)
  · calc ∫ s in I, I.indicator (fun _ => (1 : ℝ)) (τ + s) ≤ ∫ s in I, (1 : ℝ) :=
          setIntegral_mono hint (integrableOn_const (by simp [I])) (fun s => hind_le _)
      _ = T := by
          rw [setIntegral_const, smul_eq_mul, mul_one, Real.volume_real_Ioc]
          rw [max_eq_left (by linarith)]; ring

lemma wk_integral_ofReal {α : Type*} [MeasurableSpace α] {μ : Measure α} (f : α → ℝ) :
    ∫ x, (f x : ℂ) ∂μ = ((∫ x, f x ∂μ : ℝ) : ℂ) :=
  integral_ofReal

lemma wk_meas_comp {X : ℝ → Ω → ℝ} (hX : Measurable (fun p : ℝ × Ω => X p.1 p.2))
    {β : Type*} [MeasurableSpace β] {f : β → ℝ} {g : β → Ω} (hf : Measurable f)
    (hg : Measurable g) : Measurable (fun b => X (f b) (g b)) :=
  hX.comp (hf.prodMk hg)

/-- The windowed power as a weighted integral of the transformed autocorrelation. -/
lemma wk_windowed_eq (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℝ → Ω → ℝ) (R : ℝ → ℝ)
    (hX : Measurable (fun p : ℝ × Ω => X p.1 p.2))
    (hL2 : ∀ t, MemLp (X t) 2 P)
    (hstat : ∀ t τ, ∫ ω, X (t + τ) ω * X t ω ∂P = R τ)
    (hRi : Integrable R) (ξ T : ℝ) (hT : 0 < T) :
    (windowedPower P X T ξ : ℂ) = ∫ τ,
      (((∫ s in Set.Ioc (-(T / 2)) (T / 2),
        (Set.Ioc (-(T / 2)) (T / 2)).indicator (fun _ => (1 : ℝ)) (τ + s)) / T : ℝ) : ℂ) *
      (Complex.exp (↑(-2 * π * τ * ξ) * Complex.I) * (R τ : ℂ)) := by
  set I := Set.Ioc (-(T / 2)) (T / 2) with hI
  set μ : Measure ℝ := volume.restrict I with hμ
  set k : ℝ → ℂ := fun τ => Complex.exp (↑(-2 * π * τ * ξ) * Complex.I) * (R τ : ℂ) with hk_def
  set e : ℝ → ℂ := fun t => Complex.exp (-((2 * π * ξ * t : ℝ) : ℂ) * Complex.I) with he_def
  have he : Continuous e := by rw [he_def]; fun_prop
  have hk : Integrable k := by
    refine hRi.norm.mono' ?_ (ae_of_all _ fun τ => ?_)
    · exact (Continuous.aestronglyMeasurable (by fun_prop)).mul hRi.ofReal.aestronglyMeasurable
    · simp only [hk_def]
      rw [norm_mul, Complex.norm_exp_ofReal_mul_I, one_mul, Complex.norm_real]
  have hsq : ∀ t, ∫ ω, X t ω ^ 2 ∂P = R 0 := by
    intro t; have := hstat t 0; simp only [add_zero] at this; rw [← this]
    congr 1; ext ω; ring
  -- Step A: the mean squared windowed transform as a double integral.
  have hsqint : ∀ (j : ℝ × ℝ → ℝ), Measurable j →
      Integrable (fun z : Ω × (ℝ × ℝ) => X (j z.2) z.1 ^ 2) (P.prod (μ.prod μ)) := by
    intro j hj
    refine (integrable_prod_iff'
      ((wk_meas_comp hX (hj.comp measurable_snd) measurable_fst).pow_const 2).aestronglyMeasurable).mpr
      ⟨ae_of_all _ fun p => (hL2 (j p)).integrable_sq, ?_⟩
    refine (integrable_const (R 0)).congr (ae_of_all _ fun p => ?_)
    dsimp only [Function.comp_apply]
    rw [← hsq (j p)]; congr 1; ext ω
    rw [Real.norm_eq_abs, abs_of_nonneg (sq_nonneg _)]
  have hΦ : Integrable (fun z : Ω × (ℝ × ℝ) =>
      (e z.2.1 * (X z.2.1 z.1 : ℂ)) * ((starRingEnd ℂ) (e z.2.2) * (X z.2.2 z.1 : ℂ)))
      (P.prod (μ.prod μ)) := by
    refine (((hsqint (fun p => p.1) measurable_fst).add
      (hsqint (fun p => p.2) measurable_snd)).div_const 2).mono' ?_ (ae_of_all _ fun z => ?_)
    · refine Measurable.aestronglyMeasurable ?_
      exact ((he.measurable.comp measurable_snd.fst).mul (Complex.measurable_ofReal.comp
        (wk_meas_comp hX measurable_snd.fst measurable_fst))).mul
        ((Complex.continuous_conj.measurable.comp (he.measurable.comp measurable_snd.snd)).mul
        (Complex.measurable_ofReal.comp (wk_meas_comp hX measurable_snd.snd measurable_fst)))
    · simp only [he_def, norm_mul, wk_norm_exp_neg, Complex.norm_conj, Complex.norm_real,
        Real.norm_eq_abs, one_mul]
      rw [← abs_mul]; exact wk_abs_mul_le _ _
  have hinner : ∀ p : ℝ × ℝ, ∫ ω, (e p.1 * (X p.1 ω : ℂ)) *
      ((starRingEnd ℂ) (e p.2) * (X p.2 ω : ℂ)) ∂P = k (p.1 - p.2) := by
    rintro ⟨t, s⟩
    have h1 : ∀ ω, (e t * (X t ω : ℂ)) * ((starRingEnd ℂ) (e s) * (X s ω : ℂ)) =
        (e t * (starRingEnd ℂ) (e s)) * ((X t ω * X s ω : ℝ) : ℂ) := by
      intro ω; push_cast; ring
    simp only [h1]
    rw [integral_const_mul, wk_integral_ofReal]
    have := hstat s (t - s); rw [add_sub_cancel] at this; rw [this]
    simp only [he_def, hk_def]; rw [wk_exp_mul_conj]
  have hkint : Integrable (fun p : ℝ × ℝ => k (p.1 - p.2)) (μ.prod μ) :=
    hΦ.integral_prod_right.congr (ae_of_all _ hinner)
  have hA : (windowedPower P X T ξ : ℂ) = (1 / T : ℂ) * ∫ s in I, ∫ t in I, k (t - s) := by
    have hF : ∀ ω, ((‖∫ t in (-(T / 2))..(T / 2), e t * (X t ω : ℂ)‖ ^ 2 : ℝ) : ℂ) =
        ∫ p, (e p.1 * (X p.1 ω : ℂ)) * ((starRingEnd ℂ) (e p.2) * (X p.2 ω : ℂ))
          ∂(μ.prod μ) := by
      intro ω
      rw [intervalIntegral.integral_of_le (by linarith), integral_prod_mul
        (fun t => e t * (X t ω : ℂ)) (fun s => (starRingEnd ℂ) (e s) * (X s ω : ℂ))]
      have hc : ∫ s in I, (starRingEnd ℂ) (e s) * (X s ω : ℂ) =
          (starRingEnd ℂ) (∫ s in I, e s * (X s ω : ℂ)) := by
        rw [← integral_conj]; congr 1; ext s; simp [map_mul]
      rw [hc, Complex.mul_conj, Complex.normSq_eq_norm_sq]
    show ((1 / T * ∫ ω, ‖∫ t in (-(T / 2))..(T / 2), e t * (X t ω : ℂ)‖ ^ 2 ∂P : ℝ) : ℂ) = _
    rw [Complex.ofReal_mul, ← wk_integral_ofReal]
    simp only [hF]
    rw [integral_integral_swap hΦ, ← integral_prod_symm _ hkint]
    push_cast
    congr 1
    exact integral_congr_ae (ae_of_all _ hinner)
  -- Step B: change the order of integration.
  set g : ℝ → ℝ → ℂ := fun s τ => ((I.indicator (fun _ => (1 : ℝ)) (τ + s) : ℝ) : ℂ) * k τ
    with hg_def
  have hgint : Integrable (Function.uncurry g) (μ.prod volume) := by
    refine ((integrable_const (1 : ℝ)).mul_prod hk.norm).mono' ?_ (ae_of_all _ fun z => ?_)
    · exact (Complex.measurable_ofReal.comp ((measurable_const.indicator measurableSet_Ioc).comp
        (measurable_snd.add measurable_fst))).aestronglyMeasurable.mul hk.aestronglyMeasurable.comp_snd
    · simp only [Function.uncurry, hg_def, norm_mul, Complex.norm_real, one_mul]
      refine mul_le_of_le_one_left (norm_nonneg _) ?_
      by_cases h : z.2 + z.1 ∈ I <;> simp [h]
  have hB1 : ∀ s, ∫ t in I, k (t - s) = ∫ τ, g s τ := by
    intro s
    rw [← integral_indicator measurableSet_Ioc,
      ← integral_add_right_eq_self (fun t => I.indicator (fun t => k (t - s)) t) s]
    congr 1; ext τ
    by_cases h : τ + s ∈ I <;> simp [hg_def, h]
  have hB2 : ∀ τ, ∫ s in I, g s τ = ((∫ s in I, I.indicator (fun _ => (1 : ℝ)) (τ + s) : ℝ) : ℂ)
      * k τ := by
    intro τ; simp only [hg_def]; rw [integral_mul_const, wk_integral_ofReal]
  rw [hA]
  simp only [hB1]
  rw [integral_integral_swap hgint, ← integral_const_mul]
  congr 1; ext τ
  rw [hB2, Complex.ofReal_div]; ring

/-- The core limit: the windowed power tends to the Fourier transform of the autocorrelation. -/
lemma wk_core (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℝ → Ω → ℝ) (R : ℝ → ℝ)
    (hX : Measurable (fun p : ℝ × Ω => X p.1 p.2))
    (hL2 : ∀ t, MemLp (X t) 2 P)
    (hstat : ∀ t τ, ∫ ω, X (t + τ) ω * X t ω ∂P = R τ)
    (hRi : Integrable R) (ξ : ℝ) :
    Tendsto (fun T => (windowedPower P X T ξ : ℂ)) atTop
      (𝓝 (𝓕 (fun τ => (R τ : ℂ)) ξ)) := by
  set k : ℝ → ℂ := fun τ => Complex.exp (↑(-2 * π * τ * ξ) * Complex.I) * (R τ : ℂ) with hk_def
  have hk : Integrable k := by
    refine hRi.norm.mono' ?_ (ae_of_all _ fun τ => ?_)
    · exact (Continuous.aestronglyMeasurable (by fun_prop)).mul hRi.ofReal.aestronglyMeasurable
    · simp only [hk_def]
      rw [norm_mul, Complex.norm_exp_ofReal_mul_I, one_mul, Complex.norm_real]
  set c : ℝ → ℝ → ℝ := fun T τ => ∫ s in Set.Ioc (-(T / 2)) (T / 2),
        (Set.Ioc (-(T / 2)) (T / 2)).indicator (fun _ => (1 : ℝ)) (τ + s) with hc_def
  have hcm : ∀ T, Measurable (c T) := by
    intro T
    refine (StronglyMeasurable.integral_prod_right
      (f := fun τ s => (Set.Ioc (-(T / 2)) (T / 2)).indicator (fun _ => (1 : ℝ)) (τ + s))
      ?_).measurable
    exact ((measurable_const.indicator measurableSet_Ioc).comp
      (measurable_fst.add measurable_snd)).stronglyMeasurable
  have hlim : Tendsto (fun T => ∫ τ, ((c T τ / T : ℝ) : ℂ) * k τ) atTop (𝓝 (∫ τ, k τ)) := by
    refine tendsto_integral_filter_of_dominated_convergence (fun τ => ‖k τ‖)
      (Eventually.of_forall fun T => ?_) ?_ hk.norm (ae_of_all _ fun τ => ?_)
    · exact (Complex.measurable_ofReal.comp ((hcm T).div_const T)).aestronglyMeasurable.mul
        hk.aestronglyMeasurable
    · filter_upwards [eventually_gt_atTop 0] with T hT
      refine ae_of_all _ fun τ => ?_
      obtain ⟨_, h0, h1⟩ := wk_weight_bounds T τ hT
      rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg (div_nonneg h0 hT.le)]
      refine mul_le_of_le_one_left (norm_nonneg _) ?_
      rw [div_le_one hT]; exact h1
    · have hr : Tendsto (fun T => c T τ / T) atTop (𝓝 1) := by
        have hlo : Tendsto (fun T : ℝ => 1 - 2 * |τ| / T) atTop (𝓝 1) := by
          simpa using tendsto_const_nhds.sub ((tendsto_const_nhds (x := 2 * |τ|)).div_atTop tendsto_id)
        refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlo tendsto_const_nhds ?_ ?_
        · filter_upwards [eventually_gt_atTop 0] with T hT
          obtain ⟨h, _, _⟩ := wk_weight_bounds T τ hT
          rw [le_div_iff₀ hT, sub_mul, one_mul, div_mul_cancel₀ _ hT.ne']; exact h
        · filter_upwards [eventually_gt_atTop 0] with T hT
          obtain ⟨_, _, h⟩ := wk_weight_bounds T τ hT
          rw [div_le_one hT]; exact h
      simpa using ((Complex.continuous_ofReal.tendsto 1).comp hr).mul_const (k τ)
  have hF : 𝓕 (fun τ => (R τ : ℂ)) ξ = ∫ τ, k τ := by
    rw [Real.fourier_real_eq_integral_exp_smul]; rfl
  rw [hF]
  refine hlim.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with T hT
  exact (wk_windowed_eq P X R hX hL2 hstat hRi ξ T hT).symm

/-- The filter rule for a measurable impulse response. -/
lemma wk_filter_meas (P : Measure Ω) [IsProbabilityMeasure P] (X : ℝ → Ω → ℝ) (R : ℝ → ℝ)
    (hX : Measurable (fun p : ℝ × Ω => X p.1 p.2))
    (hL2 : ∀ t, MemLp (X t) 2 P)
    (hstat : ∀ t τ, ∫ ω, X (t + τ) ω * X t ω ∂P = R τ)
    (hRc : Continuous R) (hRi : Integrable R)
    (h : ℝ → ℝ) (hhm : Measurable h) (hh : Integrable h) (ξ : ℝ) :
    Tendsto (fun T => (windowedPower P (fun t ω => ∫ u, h u * X (t - u) ω) T ξ : ℂ)) atTop
      (𝓝 ((‖𝓕 (fun t => (h t : ℂ)) ξ‖ ^ 2 : ℝ) * 𝓕 (fun τ => (R τ : ℂ)) ξ)) := by
  set Y : ℝ → Ω → ℝ := fun t ω => ∫ u, h u * X (t - u) ω with hY_def
  set RY : ℝ → ℝ := fun τ => ∫ p : ℝ × ℝ, h p.1 * h p.2 * R (τ - p.1 + p.2) with hRY_def
  have hsq : ∀ t, ∫ ω, X t ω ^ 2 ∂P = R 0 := by
    intro t; have := hstat t 0; simp only [add_zero] at this; rw [← this]
    congr 1; ext ω; ring
  have hA : ∀ (j : ℝ × ℝ → ℝ), Measurable j → Integrable (fun z : Ω × (ℝ × ℝ) =>
      |h z.2.1| * |h z.2.2| * X (j z.2) z.1 ^ 2) (P.prod (volume.prod volume)) := by
    intro j hj
    refine (integrable_prod_iff' (Measurable.aestronglyMeasurable ?_)).mpr
      ⟨ae_of_all _ fun p => ((hL2 (j p)).integrable_sq.const_mul (|h p.1| * |h p.2|)), ?_⟩
    · exact ((continuous_abs.measurable.comp (hhm.comp measurable_snd.fst)).mul
        (continuous_abs.measurable.comp (hhm.comp measurable_snd.snd))).mul
        ((wk_meas_comp hX (hj.comp measurable_snd) measurable_fst).pow_const 2)
    · refine ((hh.norm.mul_prod hh.norm).mul_const (R 0)).congr (ae_of_all _ fun p => ?_)
      dsimp only
      rw [← hsq (j p), ← integral_const_mul]; congr 1; ext ω
      simp only [norm_mul, norm_pow, Real.norm_eq_abs, abs_abs, sq_abs]
  have hΨ : ∀ a b : ℝ, Integrable (fun z : Ω × (ℝ × ℝ) =>
      (h z.2.1 * X (a - z.2.1) z.1) * (h z.2.2 * X (b - z.2.2) z.1))
      (P.prod (volume.prod volume)) := by
    intro a b
    refine (((hA (fun p => a - p.1) (measurable_const.sub measurable_fst)).add
      (hA (fun p => b - p.2) (measurable_const.sub measurable_snd))).div_const 2).mono'
      (Measurable.aestronglyMeasurable ?_) (ae_of_all _ fun z => ?_)
    · exact ((hhm.comp measurable_snd.fst).mul
        (wk_meas_comp hX (measurable_const.sub measurable_snd.fst) measurable_fst)).mul
        ((hhm.comp measurable_snd.snd).mul
        (wk_meas_comp hX (measurable_const.sub measurable_snd.snd) measurable_fst))
    · have h1 := wk_abs_mul_le (X (a - z.2.1) z.1) (X (b - z.2.2) z.1)
      have h2 : 0 ≤ |h z.2.1| * |h z.2.2| := by positivity
      rw [abs_mul] at h1
      simp only [Pi.add_apply]
      calc ‖h z.2.1 * X (a - z.2.1) z.1 * (h z.2.2 * X (b - z.2.2) z.1)‖
          = (|h z.2.1| * |h z.2.2|) * (|X (a - z.2.1) z.1| * |X (b - z.2.2) z.1|) := by
            simp only [norm_mul, Real.norm_eq_abs]; ring
        _ ≤ (|h z.2.1| * |h z.2.2|) * ((X (a - z.2.1) z.1 ^ 2 + X (b - z.2.2) z.1 ^ 2) / 2) :=
            mul_le_mul_of_nonneg_left h1 h2
        _ = _ := by ring
  have hYmeas : Measurable (fun p : ℝ × Ω => Y p.1 p.2) :=
    (StronglyMeasurable.integral_prod_right
      (f := fun (q : ℝ × Ω) (u : ℝ) => h u * X (q.1 - u) q.2)
      (Measurable.stronglyMeasurable ((hhm.comp measurable_snd).mul
        (wk_meas_comp hX (measurable_fst.fst.sub measurable_snd) measurable_fst.snd)))).measurable
  have hYY : ∀ a b ω, Y a ω * Y b ω = ∫ p, (h p.1 * X (a - p.1) ω) * (h p.2 * X (b - p.2) ω)
      ∂(volume.prod volume) := by
    intro a b ω
    rw [integral_prod_mul (fun u => h u * X (a - u) ω) (fun v => h v * X (b - v) ω)]
  have hYL2 : ∀ t, MemLp (Y t) 2 P := by
    intro t
    have hm : Measurable (Y t) := hYmeas.comp (measurable_const.prodMk measurable_id)
    rw [memLp_two_iff_integrable_sq hm.aestronglyMeasurable]
    refine (hΨ t t).integral_prod_left.congr (ae_of_all _ fun ω => ?_)
    dsimp only
    rw [sq, hYY]
  have hYstat : ∀ t τ, ∫ ω, Y (t + τ) ω * Y t ω ∂P = RY τ := by
    intro t τ
    simp only [hYY]
    rw [integral_integral_swap (hΨ (t + τ) t)]
    simp only [hRY_def]
    congr 1; ext p
    obtain ⟨u, v⟩ := p
    have h1 : ∀ ω, (h u * X (t + τ - u) ω) * (h v * X (t - v) ω) =
        (h u * h v) * (X (t + τ - u) ω * X (t - v) ω) := fun ω => by ring
    simp only [h1]; rw [integral_const_mul]
    have := hstat (t - v) (τ - u + v); rw [show t - v + (τ - u + v) = t + τ - u by ring] at this
    rw [this]
  have hΦR : Integrable (fun z : ℝ × (ℝ × ℝ) => h z.2.1 * h z.2.2 * R (z.1 - z.2.1 + z.2.2))
      (volume.prod (volume.prod volume)) := by
    refine (integrable_prod_iff' (Measurable.aestronglyMeasurable ?_)).mpr
      ⟨ae_of_all _ fun p => ?_, ?_⟩
    · exact ((hhm.comp measurable_snd.fst).mul (hhm.comp measurable_snd.snd)).mul
        (hRc.measurable.comp ((measurable_fst.sub measurable_snd.fst).add measurable_snd.snd))
    · have : Integrable (fun τ => R (τ + (p.2 - p.1))) := hRi.comp_add_right _
      refine (this.const_mul (h p.1 * h p.2)).congr (ae_of_all _ fun τ => ?_)
      dsimp only; rw [show τ - p.1 + p.2 = τ + (p.2 - p.1) by ring]
    · refine ((hh.norm.mul_prod hh.norm).mul_const (∫ τ, ‖R τ‖)).congr (ae_of_all _ fun p => ?_)
      dsimp only
      rw [← integral_add_right_eq_self (fun τ => ‖R τ‖) (p.2 - p.1), ← integral_const_mul]
      congr 1; ext x
      rw [norm_mul, norm_mul, show x - p.1 + p.2 = x + (p.2 - p.1) by ring]
  have hRYi : Integrable RY := hΦR.integral_prod_left
  -- The Fourier transform of the output autocorrelation.
  set E : ℝ → ℂ := fun x => Complex.exp (↑(-2 * π * x * ξ) * Complex.I) with hE_def
  have hEc : Continuous E := by rw [hE_def]; fun_prop
  have hEn : ∀ x, ‖E x‖ = 1 := fun x => Complex.norm_exp_ofReal_mul_I _
  have hEadd : ∀ s u v, E (s + (u - v)) = E s * (E u * (starRingEnd ℂ) (E v)) := by
    intro s u v
    simp only [hE_def]
    rw [← Complex.exp_conj, ← Complex.exp_add, ← Complex.exp_add]
    congr 1
    simp only [map_mul, Complex.conj_ofReal, Complex.conj_I]
    push_cast; ring
  have hFRY : 𝓕 (fun τ => (RY τ : ℂ)) ξ =
      ((‖𝓕 (fun t => (h t : ℂ)) ξ‖ ^ 2 : ℝ) : ℂ) * 𝓕 (fun τ => (R τ : ℂ)) ξ := by
    simp only [Real.fourier_real_eq_integral_exp_smul, smul_eq_mul]
    change ∫ τ, E τ * (RY τ : ℂ) = ((‖∫ t, E t * (h t : ℂ)‖ ^ 2 : ℝ) : ℂ) *
      ∫ τ, E τ * (R τ : ℂ)
    have h1 : ∀ τ, E τ * (RY τ : ℂ) =
        ∫ p : ℝ × ℝ, E τ * ((h p.1 * h p.2 * R (τ - p.1 + p.2) : ℝ) : ℂ) := by
      intro τ; simp only [hRY_def]; rw [← wk_integral_ofReal, ← integral_const_mul]
    have hint : Integrable (Function.uncurry fun (τ : ℝ) (p : ℝ × ℝ) =>
        E τ * ((h p.1 * h p.2 * R (τ - p.1 + p.2) : ℝ) : ℂ))
        (volume.prod (volume : Measure (ℝ × ℝ))) := by
      refine hΦR.norm.mono' ((hEc.aestronglyMeasurable.comp_fst).mul
        (Complex.measurable_ofReal.comp_aemeasurable hΦR.aestronglyMeasurable.aemeasurable
          ).aestronglyMeasurable) (ae_of_all _ fun z => ?_)
      simp only [Function.uncurry, norm_mul, hEn, Complex.norm_real, one_mul, le_refl]
    have h2 : ∀ p : ℝ × ℝ, ∫ τ, E τ * ((h p.1 * h p.2 * R (τ - p.1 + p.2) : ℝ) : ℂ) =
        (E p.1 * (h p.1 : ℂ)) * ((starRingEnd ℂ) (E p.2) * (h p.2 : ℂ)) *
          ∫ s, E s * (R s : ℂ) := by
      rintro ⟨u, v⟩
      dsimp only
      rw [← integral_const_mul]
      calc ∫ τ, E τ * ((h u * h v * R (τ - u + v) : ℝ) : ℂ)
          = ∫ x, (fun s => E (s + (u - v)) * ((h u * h v * R s : ℝ) : ℂ)) (x - (u - v)) := by
            congr 1; ext x; dsimp only
            rw [sub_add_cancel, show x - (u - v) = x - u + v by ring]
        _ = ∫ x, (fun s => E (s + (u - v)) * ((h u * h v * R s : ℝ) : ℂ)) x :=
            integral_sub_right_eq_self
              (fun s => E (s + (u - v)) * ((h u * h v * R s : ℝ) : ℂ)) (u - v)
        _ = _ := by
            congr 1; ext x; dsimp only
            rw [hEadd]; simp only [Complex.ofReal_mul]; ring
    have h3 : ∫ v, (starRingEnd ℂ) (E v) * (h v : ℂ) =
        (starRingEnd ℂ) (∫ v, E v * (h v : ℂ)) := by
      rw [← integral_conj]; congr 1; ext v; simp [map_mul]
    simp only [h1]
    rw [integral_integral_swap hint]
    simp only [h2]
    rw [integral_mul_const, Measure.volume_eq_prod, integral_prod_mul (fun u => E u * (h u : ℂ))
      (fun v => (starRingEnd ℂ) (E v) * (h v : ℂ)), h3, Complex.mul_conj,
      Complex.normSq_eq_norm_sq]
  have := wk_core P Y RY hYmeas hYL2 hYstat hRYi ξ
  rw [hFRY] at this
  exact this

/-- The filter rule for any integrable impulse response: pass to a measurable version. -/
lemma wk_filter (P : Measure Ω) [IsProbabilityMeasure P] (X : ℝ → Ω → ℝ) (R : ℝ → ℝ)
    (hX : Measurable (fun p : ℝ × Ω => X p.1 p.2))
    (hL2 : ∀ t, MemLp (X t) 2 P)
    (hstat : ∀ t τ, ∫ ω, X (t + τ) ω * X t ω ∂P = R τ)
    (hRc : Continuous R) (hRi : Integrable R)
    (h : ℝ → ℝ) (hh : Integrable h) (ξ : ℝ) :
    Tendsto (fun T => (windowedPower P (fun t ω => ∫ u, h u * X (t - u) ω) T ξ : ℂ)) atTop
      (𝓝 ((‖𝓕 (fun t => (h t : ℂ)) ξ‖ ^ 2 : ℝ) * 𝓕 (fun τ => (R τ : ℂ)) ξ)) := by
  obtain ⟨h', hh's, hae⟩ := hh.1
  have hY : (fun t ω => ∫ u, h u * X (t - u) ω) = (fun t ω => ∫ u, h' u * X (t - u) ω) := by
    funext t ω; exact integral_congr_ae (hae.mono fun u hu => by simp only [hu])
  have hF : 𝓕 (fun t => (h t : ℂ)) ξ = 𝓕 (fun t => (h' t : ℂ)) ξ :=
    Real.fourier_congr_ae (hae.mono fun u hu => by simp only [hu]) ξ
  rw [hY, hF]
  exact wk_filter_meas P X R hX hL2 hstat hRc hRi h' hh's.measurable (hh.congr hae) ξ

#print axioms wk_norm_exp_neg
#print axioms wk_exp_mul_conj
#print axioms wk_abs_mul_le
#print axioms wk_weight_bounds
#print axioms wk_integral_ofReal
#print axioms wk_meas_comp
#print axioms wk_windowed_eq
#print axioms wk_core
#print axioms wk_filter_meas
#print axioms wk_filter

/-- The Wiener-Khinchin theorem. Let `X` be a stationary random signal whose autocorrelation
`R(τ) = 𝔼[X(t + τ) X(t)]` is continuous and absolutely integrable. Then at every frequency `ξ`
the windowed power `(1/T) 𝔼 |X̂_T(ξ)|²` tends, as the window grows, to the Fourier transform of
the autocorrelation: the power spectrum is `S_X(ξ) = ∫ R(τ) e^(−2πiξτ) dτ`. -/
theorem power_spectrum_eq_fourier_of_autocorrelation (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℝ → Ω → ℝ) (R : ℝ → ℝ)
    (hX : Measurable (fun p : ℝ × Ω => X p.1 p.2))
    (hL2 : ∀ t, MemLp (X t) 2 P)
    (hstat : ∀ t τ, ∫ ω, X (t + τ) ω * X t ω ∂P = R τ)
    (hRc : Continuous R) (hRi : Integrable R) (ξ : ℝ) :
    Tendsto (fun T => (windowedPower P X T ξ : ℂ)) atTop
      (𝓝 (𝓕 (fun τ => (R τ : ℂ)) ξ)) := by
  exact wk_core P X R hX hL2 hstat hRi ξ

/-- What follows at once. Under the same conditions the power spectrum `S_X(ξ) = R̂(ξ)` is real
and never negative at every frequency, and when it is integrable its total area is the mean
square: `∫ S_X(ξ) dξ = R(0) = 𝔼[X(t)²]` at every time `t`. -/
theorem power_spectrum_nonneg_and_area_eq_mean_square (P : Measure Ω) [IsProbabilityMeasure P]
    (X : ℝ → Ω → ℝ) (R : ℝ → ℝ)
    (hX : Measurable (fun p : ℝ × Ω => X p.1 p.2))
    (hL2 : ∀ t, MemLp (X t) 2 P)
    (hstat : ∀ t τ, ∫ ω, X (t + τ) ω * X t ω ∂P = R τ)
    (hRc : Continuous R) (hRi : Integrable R) :
    (∀ ξ, (𝓕 (fun τ => (R τ : ℂ)) ξ).im = 0 ∧ 0 ≤ (𝓕 (fun τ => (R τ : ℂ)) ξ).re) ∧
    (Integrable (𝓕 (fun τ => (R τ : ℂ))) →
      ∀ t, ∫ ξ, 𝓕 (fun τ => (R τ : ℂ)) ξ = ((∫ ω, X t ω ^ 2 ∂P : ℝ) : ℂ)) := by
  refine ⟨fun ξ => ?_, fun hint t => ?_⟩
  · have hS : IsClosed {z : ℂ | z.im = 0 ∧ 0 ≤ z.re} :=
      (isClosed_eq Complex.continuous_im continuous_const).inter
        (isClosed_le continuous_const Complex.continuous_re)
    refine hS.mem_of_tendsto (wk_core P X R hX hL2 hstat hRi ξ) ?_
    filter_upwards [eventually_gt_atTop 0] with T hT
    refine ⟨Complex.ofReal_im _, ?_⟩
    rw [Complex.ofReal_re]
    unfold windowedPower
    exact mul_nonneg (by positivity) (integral_nonneg fun ω => by positivity)
  · have hinv := Continuous.fourierInv_fourier_eq (f := fun τ => (R τ : ℂ))
      (Complex.continuous_ofReal.comp hRc) hRi.ofReal hint
    have h0 := congrFun hinv 0
    rw [Real.fourierInv_eq'] at h0
    simp only [inner_zero_right, mul_zero, Complex.ofReal_zero, zero_mul, Complex.exp_zero,
      one_smul] at h0
    rw [h0]
    have := hstat t 0
    simp only [add_zero] at this
    rw [← this]
    congr 2; ext ω; ring

/-- The filter rule. Pass the stationary signal `X` (continuous, absolutely integrable
autocorrelation `R`) through a linear, time-invariant, stable filter: a real impulse response `h`
with `∫ |h| < ∞`, so the output is `Y(t) = (h * X)(t) = ∫ h(u) X(t − u) du`. Then the output's
windowed power tends to `|ĥ(ξ)|² S_X(ξ)`: the output's power spectrum is
`S_Y(ξ) = |ĥ(ξ)|² S_X(ξ)`, the input's multiplied by the filter's gain squared. -/
theorem filter_multiplies_power_spectrum_by_gain_squared (P : Measure Ω)
    [IsProbabilityMeasure P] (X : ℝ → Ω → ℝ) (R : ℝ → ℝ)
    (hX : Measurable (fun p : ℝ × Ω => X p.1 p.2))
    (hL2 : ∀ t, MemLp (X t) 2 P)
    (hstat : ∀ t τ, ∫ ω, X (t + τ) ω * X t ω ∂P = R τ)
    (hRc : Continuous R) (hRi : Integrable R)
    (h : ℝ → ℝ) (hh : Integrable h) (ξ : ℝ) :
    Tendsto (fun T => (windowedPower P (fun t ω => ∫ u, h u * X (t - u) ω) T ξ : ℂ)) atTop
      (𝓝 ((‖𝓕 (fun t => (h t : ℂ)) ξ‖ ^ 2 : ℝ) * 𝓕 (fun τ => (R τ : ℂ)) ξ)) := by
  exact wk_filter P X R hX hL2 hstat hRc hRi h hh ξ

-- The hiss filter, corner ξ_c = 5 kHz, gain squared 1/(1 + (ξ/ξ_c)²), white hiss N₀ = 100 µV²/Hz.
-- At 5 kHz the gain squared is 1/2 and S_Y = 50 µV²/Hz; at 10 kHz it is 1/5 and S_Y = 20 µV²/Hz.
example : 1 / (1 + ((5000 : ℚ) / 5000) ^ 2) = 1 / 2 ∧
    100 * (1 / (1 + ((5000 : ℚ) / 5000) ^ 2)) = 50 := by norm_num
example : 1 / (1 + ((10000 : ℚ) / 5000) ^ 2) = 1 / 5 ∧
    100 * (1 / (1 + ((10000 : ℚ) / 5000) ^ 2)) = 20 := by norm_num
-- The gain at 10 kHz is ĥ = 1/(1 + 2i), whose size squared is 1/5.
example : Complex.normSq (1 / (1 + 2 * Complex.I)) = 1 / 5 := by
  rw [one_div, map_inv₀]
  norm_num [Complex.normSq_apply]
-- The hiss in the audible band, −20 kHz to +20 kHz: 100 × 40,000 = 4,000,000 µV², rms 2000 µV.
example : (100 : ℚ) * (20000 - (-20000)) = 2000 ^ 2 := by norm_num
-- Sampled white noise has variance N₀ f_s: 5,000,000; 10,000,000; 20,000,000; 40,000,000 µV²
-- at 50, 100, 200 and 400 kHz.
example : 100 * 50000 = 5000000 ∧ 100 * 100000 = 10000000 ∧ 100 * 200000 = 20000000 ∧
    100 * 400000 = 40000000 := by norm_num
-- The 50 Hz hum, amplitude 1000 µV: windowed value 1000² T/4 is 25,000, 250,000 and
-- 2,500,000 µV²/Hz for T = 0.1 s, 1 s and 10 s.
example : (1000 : ℚ) ^ 2 * (1 / 10) / 4 = 25000 ∧ (1000 : ℚ) ^ 2 * 1 / 4 = 250000 ∧
    (1000 : ℚ) ^ 2 * 10 / 4 = 2500000 := by norm_num
-- Try changing: corner 2.5 kHz gives S_Y(10 kHz) = 100/(1 + 4²) = 100/17 µV²/Hz.
example : 100 / (1 + ((10000 : ℚ) / 2500) ^ 2) = 100 / 17 := by norm_num

#print axioms power_spectrum_eq_fourier_of_autocorrelation
#print axioms power_spectrum_nonneg_and_area_eq_mean_square
#print axioms filter_multiplies_power_spectrum_by_gain_squared
