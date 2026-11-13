-- Strike or spot from a target premium: with volatility and time positive, a Black-Scholes call premium names exactly one positive strike when it lies strictly between 0 and S e^(-qT), and exactly one positive spot when it is positive, the put has the mirror ranges, and the two slopes are -e^(-rT) N(d₂) in strike and e^(-qT) N(d₁) in spot.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Probability.Moments.Basic

open Real ProbabilityTheory

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- The helper `d₁ = (ln(S/K) + (r - q + σ²/2) T) / (σ√T)`; then `d₂ = d₁ - σ√T`. -/
noncomputable def bsD1 (S K r q σ T : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Black-Scholes call: `C = S e^(-qT) N(d₁) - K e^(-rT) N(d₂)`. -/
noncomputable def bsCall (S K r q σ T : ℝ) : ℝ :=
  S * exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T)
    - K * exp (-r * T) * stdNormalCDF (bsD1 S K r q σ T - σ * √T)

/-- The Black-Scholes put: `P = K e^(-rT) N(-d₂) - S e^(-qT) N(-d₁)`. -/
noncomputable def bsPut (S K r q σ T : ℝ) : ℝ :=
  K * exp (-r * T) * stdNormalCDF (-(bsD1 S K r q σ T - σ * √T))
    - S * exp (-q * T) * stdNormalCDF (-bsD1 S K r q σ T)

section Helpers

open Filter Topology Set MeasureTheory

lemma unique_root_anti {f : ℝ → ℝ} {L1 L2 : ℝ} (hf : StrictAntiOn f (Ioi 0))
    (hc : ContinuousOn f (Ioi 0)) (h0 : Tendsto f (𝓝[>] 0) (𝓝 L1))
    (hinf : Tendsto f atTop (𝓝 L2)) (v : ℝ) :
    (∃! x : ℝ, 0 < x ∧ f x = v) ↔ (L2 < v ∧ v < L1) := by
  constructor
  · rintro ⟨x, ⟨hx, rfl⟩, -⟩
    constructor
    · have h1 : f (x + 1) < f x := hf (mem_Ioi.2 hx) (mem_Ioi.2 (by linarith)) (by linarith)
      have h2 : L2 ≤ f (x + 1) := by
        refine le_of_tendsto hinf ?_
        filter_upwards [eventually_ge_atTop (x + 1)] with y hy
        exact hf.antitoneOn (mem_Ioi.2 (by linarith)) (mem_Ioi.2 (by linarith)) hy
      linarith
    · have h1 : f x < f (x / 2) := hf (mem_Ioi.2 (by linarith)) (mem_Ioi.2 hx) (by linarith)
      have h2 : f (x / 2) ≤ L1 := by
        refine ge_of_tendsto h0 ?_
        filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < x / 2 by linarith)] with y hy
        exact hf.antitoneOn (mem_Ioi.2 hy.1) (mem_Ioi.2 (by linarith)) hy.2.le
      linarith
  · rintro ⟨h1, h2⟩
    obtain ⟨x, hx, hxv⟩ := isPreconnected_Ioi.intermediate_value_Ioo
      (le_principal_iff.2 (Ioi_mem_atTop 0)) (le_principal_iff.2 self_mem_nhdsWithin) hc hinf h0 ⟨h1, h2⟩
    refine ⟨x, ⟨hx, hxv⟩, fun y hy => hf.injOn hy.1 hx (hy.2.trans hxv.symm)⟩

lemma unique_root_mono {f : ℝ → ℝ} {L : ℝ} (hf : StrictMonoOn f (Ioi 0))
    (hc : ContinuousOn f (Ioi 0)) (h0 : Tendsto f (𝓝[>] 0) (𝓝 L))
    (hinf : Tendsto f atTop atTop) (v : ℝ) :
    (∃! x : ℝ, 0 < x ∧ f x = v) ↔ L < v := by
  constructor
  · rintro ⟨x, ⟨hx, rfl⟩, -⟩
    have h1 : f (x / 2) < f x := hf (mem_Ioi.2 (by linarith)) (mem_Ioi.2 hx) (by linarith)
    have h2 : L ≤ f (x / 2) := by
      refine le_of_tendsto h0 ?_
      filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < x / 2 by linarith)] with y hy
      exact hf.monotoneOn (mem_Ioi.2 hy.1) (mem_Ioi.2 (by linarith)) hy.2.le
    linarith
  · intro h1
    obtain ⟨x, hx, hxv⟩ := isPreconnected_Ioi.intermediate_value_Ioi
      (le_principal_iff.2 self_mem_nhdsWithin) (le_principal_iff.2 (Ioi_mem_atTop 0)) hc h0 hinf h1
    refine ⟨x, ⟨hx, hxv⟩, fun y hy => hf.injOn hy.1 hx (hy.2.trans hxv.symm)⟩

/-- standard normal density -/
noncomputable def stdPDF (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

lemma stdPDF_eq (x : ℝ) : stdPDF x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [stdPDF, gaussianPDFReal]

lemma stdPDF_pos (x : ℝ) : 0 < stdPDF x := gaussianPDFReal_pos _ _ _ one_ne_zero

lemma stdPDF_neg (x : ℝ) : stdPDF (-x) = stdPDF x := by
  simp [stdPDF_eq]

lemma stdNormalCDF_eq_integral (x : ℝ) : stdNormalCDF x = ∫ t in Iic x, stdPDF t := by
  rw [stdNormalCDF, cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ _))]
  rfl

lemma stdPDF_integrable : Integrable stdPDF := integrable_gaussianPDFReal 0 1

lemma stdPDF_continuous : Continuous stdPDF := by
  have : stdPDF = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := funext stdPDF_eq
  rw [this]; fun_prop

lemma stdNormalCDF_eq' (x : ℝ) : stdNormalCDF x = stdNormalCDF 0 + ∫ t in (0:ℝ)..x, stdPDF t := by
  rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
    ← intervalIntegral.integral_Iic_sub_Iic stdPDF_integrable.integrableOn
      stdPDF_integrable.integrableOn]
  ring

lemma hasDerivAt_stdNormalCDF (x : ℝ) : HasDerivAt stdNormalCDF (stdPDF x) x := by
  have h := intervalIntegral.integral_hasDerivAt_right (a := 0) (b := x)
    (stdPDF_continuous.intervalIntegrable _ _)
    stdPDF_continuous.stronglyMeasurable.stronglyMeasurableAtFilter
    stdPDF_continuous.continuousAt
  have : stdNormalCDF = fun u => stdNormalCDF 0 + ∫ t in (0:ℝ)..u, stdPDF t :=
    funext stdNormalCDF_eq'
  rw [this]
  exact h.const_add _

lemma stdNormalCDF_strictMono : StrictMono stdNormalCDF :=
  strictMono_of_deriv_pos (fun x => by rw [(hasDerivAt_stdNormalCDF x).deriv]; exact stdPDF_pos x)

lemma stdNormalCDF_continuous : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.2 fun x => (hasDerivAt_stdNormalCDF x).continuousAt

lemma tendsto_stdNormalCDF_atTop : Tendsto stdNormalCDF atTop (𝓝 1) := tendsto_cdf_atTop _
lemma tendsto_stdNormalCDF_atBot : Tendsto stdNormalCDF atBot (𝓝 0) := tendsto_cdf_atBot _

lemma stdNormalCDF_pos (x : ℝ) : 0 < stdNormalCDF x := by
  have h1 : stdNormalCDF (x - 1) < stdNormalCDF x := stdNormalCDF_strictMono (by linarith)
  have h2 : 0 ≤ stdNormalCDF (x - 1) := by
    refine le_of_tendsto tendsto_stdNormalCDF_atBot ?_
    filter_upwards [eventually_le_atBot (x - 1)] with y hy
    exact stdNormalCDF_strictMono.monotone hy
  linarith

lemma stdNormalCDF_lt_one (x : ℝ) : stdNormalCDF x < 1 := by
  have h1 : stdNormalCDF x < stdNormalCDF (x + 1) := stdNormalCDF_strictMono (by linarith)
  have h2 : stdNormalCDF (x + 1) ≤ 1 := by
    refine ge_of_tendsto tendsto_stdNormalCDF_atTop ?_
    filter_upwards [eventually_ge_atTop (x + 1)] with y hy
    exact stdNormalCDF_strictMono.monotone hy
  linarith

lemma stdNormalCDF_neg (x : ℝ) : stdNormalCDF (-x) = 1 - stdNormalCDF x := by
  have hd : ∀ y, HasDerivAt (fun y => stdNormalCDF y + stdNormalCDF (-y)) 0 y := by
    intro y
    have h : HasDerivAt (fun y => stdNormalCDF y + stdNormalCDF (-y)) (stdPDF y + stdPDF (-y) * -1) y :=
      (hasDerivAt_stdNormalCDF y).add ((hasDerivAt_stdNormalCDF (-y)).comp y (hasDerivAt_neg y))
    convert h using 1
    rw [stdPDF_neg]; ring
  have hconst : ∀ y, stdNormalCDF y + stdNormalCDF (-y) = stdNormalCDF x + stdNormalCDF (-x) :=
    fun y => is_const_of_deriv_eq_zero (fun z => (hd z).differentiableAt) (fun z => (hd z).deriv) y x
  have hlim : Tendsto (fun y => stdNormalCDF y + stdNormalCDF (-y)) atTop (𝓝 (1 + 0)) :=
    tendsto_stdNormalCDF_atTop.add (tendsto_stdNormalCDF_atBot.comp tendsto_neg_atTop_atBot)
  have : stdNormalCDF x + stdNormalCDF (-x) = 1 := by
    have := tendsto_nhds_unique (tendsto_const_nhds.congr (fun y => (hconst y).symm)) hlim
    linarith
  linarith

/-- Chernoff tail -/
lemma stdNormalCDF_le_exp (x t : ℝ) (ht : t ≤ 0) :
    stdNormalCDF x ≤ exp (-t * x) * exp (t ^ 2 / 2) := by
  have h := measure_le_le_exp_mul_mgf (μ := gaussianReal 0 1) (X := id) x ht
    (integrable_exp_mul_gaussianReal t)
  rw [mgf_id_gaussianReal] at h
  rw [stdNormalCDF, cdf_eq_real]
  convert h using 2
  · rfl
  · simp

lemma tendsto_exp_mul_stdNormalCDF (a : ℝ) (ha : 0 < a) :
    Tendsto (fun x => exp (-a * x) * stdNormalCDF x) atBot (𝓝 0) := by
  have hup : ∀ x, exp (-a * x) * stdNormalCDF x ≤ exp (a * x + 2 * a ^ 2) := by
    intro x
    have h := stdNormalCDF_le_exp x (-2 * a) (by linarith)
    calc exp (-a * x) * stdNormalCDF x ≤ exp (-a * x) * (exp (-(-2 * a) * x) * exp ((-2 * a) ^ 2 / 2)) :=
          mul_le_mul_of_nonneg_left h (exp_pos _).le
      _ = exp (a * x + 2 * a ^ 2) := by rw [← exp_add, ← exp_add]; ring_nf
  have hlim : Tendsto (fun x => exp (a * x + 2 * a ^ 2)) atBot (𝓝 0) := by
    refine tendsto_exp_atBot.comp ?_
    exact tendsto_atBot_add_const_right _ _ (tendsto_id.const_mul_atBot ha)
  exact tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds hlim
    (fun x => mul_nonneg (exp_pos _).le (stdNormalCDF_pos x).le) hup

lemma bs_pdf_identity (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    S * exp (-q * T) * stdPDF (bsD1 S K r q σ T) =
      K * exp (-r * T) * stdPDF (bsD1 S K r q σ T - σ * √T) := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have ha2 : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, sq_sqrt hT.le]
  set d := bsD1 S K r q σ T with hd_def
  have hd : d * (σ * √T) = log (S / K) + (r - q + σ ^ 2 / 2) * T := by
    rw [hd_def, bsD1]; field_simp
  have key : -(d - σ * √T) ^ 2 / 2 = -d ^ 2 / 2 + log (S / K) + (-q * T) - (-r * T) := by
    linear_combination hd - ha2 / 2
  rw [stdPDF_eq, stdPDF_eq, key, exp_sub, exp_add, exp_add, exp_log (div_pos hS hK)]
  field_simp

lemma bsD1_differentiableAt_K (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) :
    DifferentiableAt ℝ (fun k => bsD1 S k r q σ T) K := by
  unfold bsD1
  have : DifferentiableAt ℝ (fun k => log (S / k)) K :=
    ((differentiableAt_const S).div differentiableAt_id hK.ne').log (div_pos hS hK).ne'
  fun_prop

lemma bsD1_differentiableAt_S (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) :
    DifferentiableAt ℝ (fun s => bsD1 s K r q σ T) S := by
  unfold bsD1
  have : DifferentiableAt ℝ (fun s => log (s / K)) S :=
    (differentiableAt_id.div (differentiableAt_const K) hK.ne').log (div_pos hS hK).ne'
  fun_prop

lemma bsCall_hasDerivAt_K (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun k => bsCall S k r q σ T)
        (-(exp (-r * T) * stdNormalCDF (bsD1 S K r q σ T - σ * √T))) K := by
  have hd := (bsD1_differentiableAt_K S K r q σ T hS hK).hasDerivAt
  set d' := deriv (fun k => bsD1 S k r q σ T) K
  have h1 := ((hasDerivAt_stdNormalCDF _).comp K hd).const_mul (S * exp (-q * T))
  have h2 := ((hasDerivAt_mul_const (exp (-r * T))).mul
    ((hasDerivAt_stdNormalCDF _).comp K (hd.sub_const (σ * √T))))
  unfold bsCall
  refine (h1.sub h2).congr_deriv ?_
  have key := bs_pdf_identity S K r q σ T hS hK hσ hT
  simp only [Function.comp]
  linear_combination d' * key

lemma bsCall_hasDerivAt_S (S K r q σ T : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun s => bsCall s K r q σ T)
        (exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T)) S := by
  have hd := (bsD1_differentiableAt_S S K r q σ T hS hK).hasDerivAt
  set d' := deriv (fun s => bsD1 s K r q σ T) S
  have h1 := (hasDerivAt_mul_const (exp (-q * T))).mul ((hasDerivAt_stdNormalCDF _).comp S hd)
  have h2 := ((hasDerivAt_stdNormalCDF _).comp S (hd.sub_const (σ * √T))).const_mul
    (K * exp (-r * T))
  unfold bsCall
  refine (h1.sub h2).congr_deriv ?_
  have key := bs_pdf_identity S K r q σ T hS hK hσ hT
  simp only [Function.comp]
  linear_combination d' * key

lemma bsD1_eq (S K r q σ T : ℝ) (hS : S ≠ 0) (hK : K ≠ 0) :
    bsD1 S K r q σ T = (log S - log K + (r - q + σ ^ 2 / 2) * T) / (σ * √T) := by
  rw [bsD1, log_div hS hK]

lemma bsD1_tendsto_K0 (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun k => bsD1 S k r q σ T) (𝓝[>] 0) atTop := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have h : Tendsto (fun k => (-log k + (log S + (r - q + σ ^ 2 / 2) * T)) / (σ * √T))
      (𝓝[>] 0) atTop :=
    ((tendsto_neg_atBot_atTop.comp tendsto_log_nhdsGT_zero).atTop_add
      tendsto_const_nhds).atTop_div_const ha
  refine h.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with k hk
  rw [bsD1_eq _ _ _ _ _ _ hS.ne' (ne_of_gt hk)]
  ring_nf

lemma bsD1_tendsto_Ktop (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun k => bsD1 S k r q σ T) atTop atBot := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have h : Tendsto (fun k => (-log k + (log S + (r - q + σ ^ 2 / 2) * T)) / (σ * √T))
      atTop atBot :=
    ((tendsto_neg_atTop_atBot.comp tendsto_log_atTop).atBot_add
      tendsto_const_nhds).atBot_div_const ha
  refine h.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with k hk
  rw [bsD1_eq _ _ _ _ _ _ hS.ne' hk.ne']
  ring_nf

lemma bsD1_tendsto_S0 (K r q σ T : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun s => bsD1 s K r q σ T) (𝓝[>] 0) atBot := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have h : Tendsto (fun s => (log s + (-log K + (r - q + σ ^ 2 / 2) * T)) / (σ * √T))
      (𝓝[>] 0) atBot :=
    (tendsto_log_nhdsGT_zero.atBot_add tendsto_const_nhds).atBot_div_const ha
  refine h.congr' ?_
  filter_upwards [self_mem_nhdsWithin] with s hs
  rw [bsD1_eq _ _ _ _ _ _ (ne_of_gt hs) hK.ne']
  ring_nf

lemma bsD1_tendsto_Stop (K r q σ T : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun s => bsD1 s K r q σ T) atTop atTop := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have h : Tendsto (fun s => (log s + (-log K + (r - q + σ ^ 2 / 2) * T)) / (σ * √T))
      atTop atTop :=
    (tendsto_log_atTop.atTop_add tendsto_const_nhds).atTop_div_const ha
  refine h.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with s hs
  rw [bsD1_eq _ _ _ _ _ _ hs.ne' hK.ne']
  ring_nf

lemma tendsto_sub_const_atTop {f : ℝ → ℝ} {l : Filter ℝ} (h : Tendsto f l atTop) (c : ℝ) :
    Tendsto (fun x => f x - c) l atTop := by
  simpa [sub_eq_add_neg] using tendsto_atTop_add_const_right l (-c) h

lemma tendsto_sub_const_atBot {f : ℝ → ℝ} {l : Filter ℝ} (h : Tendsto f l atBot) (c : ℝ) :
    Tendsto (fun x => f x - c) l atBot := by
  simpa [sub_eq_add_neg] using tendsto_atBot_add_const_right l (-c) h

lemma bsCall_tendsto_K0 (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun k => bsCall S k r q σ T) (𝓝[>] 0) (𝓝 (S * exp (-q * T))) := by
  have hd := bsD1_tendsto_K0 S r q σ T hS hσ hT
  have h1 := tendsto_stdNormalCDF_atTop.comp hd
  have h2 := tendsto_stdNormalCDF_atTop.comp (tendsto_sub_const_atTop hd (σ * √T))
  have hk : Tendsto (fun k : ℝ => k) (𝓝[>] 0) (𝓝 0) := tendsto_id.mono_left nhdsWithin_le_nhds
  have h := (tendsto_const_nhds (x := S * exp (-q * T))).mul h1 |>.sub
    ((hk.mul_const (exp (-r * T))).mul h2)
  simp only [mul_one, zero_mul, sub_zero] at h
  exact h

lemma bsCall_tendsto_Ktop (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun k => bsCall S k r q σ T) atTop (𝓝 0) := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have ha2 : (σ * √T) ^ 2 = σ ^ 2 * T := by rw [mul_pow, sq_sqrt hT.le]
  have hd := bsD1_tendsto_Ktop S r q σ T hS hσ hT
  have hd2 := tendsto_sub_const_atBot hd (σ * √T)
  have h1 := tendsto_stdNormalCDF_atBot.comp hd
  set a := σ * √T
  set B := (r - q + σ ^ 2 / 2) * T
  -- tail: k * N(d₂ k) → 0
  have htail := ((tendsto_exp_mul_stdNormalCDF a ha).comp hd2).const_mul (exp (log S + B - a ^ 2))
  have h2 : Tendsto (fun k => k * stdNormalCDF (bsD1 S k r q σ T - a)) atTop (𝓝 0) := by
    rw [mul_zero] at htail
    refine htail.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with k hk
    simp only [Function.comp]
    rw [← mul_assoc, ← exp_add]
    congr 1
    have : log S + B - a ^ 2 + -a * (bsD1 S k r q σ T - a) = log k := by
      rw [bsD1_eq _ _ _ _ _ _ hS.ne' hk.ne']
      field_simp
      ring
    rw [this, exp_log hk]
  have h := ((tendsto_const_nhds (x := S * exp (-q * T))).mul h1).sub
    (h2.const_mul (exp (-r * T)))
  simp only [mul_zero, sub_zero] at h
  refine h.congr' (Eventually.of_forall fun k => ?_)
  simp only [Function.comp, bsCall]
  ring

lemma bsCall_tendsto_S0 (K r q σ T : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun s => bsCall s K r q σ T) (𝓝[>] 0) (𝓝 0) := by
  have hd := bsD1_tendsto_S0 K r q σ T hK hσ hT
  have h1 := tendsto_stdNormalCDF_atBot.comp hd
  have h2 := tendsto_stdNormalCDF_atBot.comp (tendsto_sub_const_atBot hd (σ * √T))
  have hs : Tendsto (fun s : ℝ => s) (𝓝[>] 0) (𝓝 0) := tendsto_id.mono_left nhdsWithin_le_nhds
  have h := ((hs.mul_const (exp (-q * T))).mul h1).sub
    ((tendsto_const_nhds (x := K * exp (-r * T))).mul h2)
  simp only [mul_zero, zero_mul, sub_zero] at h
  exact h

lemma bsCall_tendsto_Stop (K r q σ T : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun s => bsCall s K r q σ T) atTop atTop := by
  have hd := bsD1_tendsto_Stop K r q σ T hK hσ hT
  have h1 := tendsto_stdNormalCDF_atTop.comp hd
  have hev : ∀ᶠ s in atTop, (1 / 2 : ℝ) < stdNormalCDF (bsD1 s K r q σ T) :=
    h1.eventually (lt_mem_nhds (by norm_num))
  have hlin : Tendsto (fun s => s * (exp (-q * T) / 2) - K * exp (-r * T)) atTop atTop :=
    tendsto_sub_const_atTop (tendsto_id.atTop_mul_const (by positivity)) _
  refine tendsto_atTop_mono' atTop ?_ hlin
  filter_upwards [hev, eventually_gt_atTop 0] with s hs hs0
  unfold bsCall
  have e1 := exp_pos (-q * T)
  have e2 := exp_pos (-r * T)
  have hN := stdNormalCDF_lt_one (bsD1 s K r q σ T - σ * √T)
  have : s * (exp (-q * T) / 2) ≤ s * exp (-q * T) * stdNormalCDF (bsD1 s K r q σ T) := by
    have := mul_le_mul_of_nonneg_left hs.le (mul_pos hs0 e1).le
    linarith
  have : K * exp (-r * T) * stdNormalCDF (bsD1 s K r q σ T - σ * √T) ≤ K * exp (-r * T) :=
    by have := mul_le_mul_of_nonneg_left hN.le (mul_pos hK e2).le; linarith
  linarith

lemma bsPut_eq (S K r q σ T : ℝ) :
    bsPut S K r q σ T = bsCall S K r q σ T - S * exp (-q * T) + K * exp (-r * T) := by
  unfold bsPut bsCall
  rw [stdNormalCDF_neg, stdNormalCDF_neg]
  ring

lemma bsPut_tendsto_Stop (K r q σ T : ℝ) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    Tendsto (fun s => bsPut s K r q σ T) atTop (𝓝 0) := by
  have ha : 0 < σ * √T := mul_pos hσ (sqrt_pos.2 hT)
  have hd := bsD1_tendsto_Stop K r q σ T hK hσ hT
  have hnd : Tendsto (fun s => -bsD1 s K r q σ T) atTop atBot := tendsto_neg_atTop_atBot.comp hd
  have hnd2 : Tendsto (fun s => -(bsD1 s K r q σ T - σ * √T)) atTop atBot :=
    tendsto_neg_atTop_atBot.comp (tendsto_sub_const_atTop hd (σ * √T))
  have h1 := tendsto_stdNormalCDF_atBot.comp hnd2
  set a := σ * √T
  set B := (r - q + σ ^ 2 / 2) * T
  have htail := ((tendsto_exp_mul_stdNormalCDF a ha).comp hnd).const_mul (exp (log K - B))
  have h2 : Tendsto (fun s => s * stdNormalCDF (-bsD1 s K r q σ T)) atTop (𝓝 0) := by
    rw [mul_zero] at htail
    refine htail.congr' ?_
    filter_upwards [eventually_gt_atTop 0] with s hs
    simp only [Function.comp]
    rw [← mul_assoc, ← exp_add]
    congr 1
    have : log K - B + -a * -bsD1 s K r q σ T = log s := by
      rw [bsD1_eq _ _ _ _ _ _ hs.ne' hK.ne']
      field_simp
      ring
    rw [this, exp_log hs]
  have h := ((tendsto_const_nhds (x := K * exp (-r * T))).mul h1).sub
    (h2.const_mul (exp (-q * T)))
  simp only [mul_zero, sub_zero] at h
  refine h.congr' (Eventually.of_forall fun s => ?_)
  simp only [Function.comp, bsPut]
  ring

lemma strictAntiOn_of_hasDerivAt {f f' : ℝ → ℝ} (hd : ∀ x ∈ Ioi (0:ℝ), HasDerivAt f (f' x) x)
    (hneg : ∀ x ∈ Ioi (0:ℝ), f' x < 0) : StrictAntiOn f (Ioi 0) ∧ ContinuousOn f (Ioi 0) := by
  have hc : ContinuousOn f (Ioi 0) := fun x hx => (hd x hx).continuousAt.continuousWithinAt
  refine ⟨strictAntiOn_of_deriv_neg (convex_Ioi 0) hc fun x hx => ?_, hc⟩
  rw [interior_Ioi] at hx
  rw [(hd x hx).deriv]; exact hneg x hx

lemma strictMonoOn_of_hasDerivAt {f f' : ℝ → ℝ} (hd : ∀ x ∈ Ioi (0:ℝ), HasDerivAt f (f' x) x)
    (hpos : ∀ x ∈ Ioi (0:ℝ), 0 < f' x) : StrictMonoOn f (Ioi 0) ∧ ContinuousOn f (Ioi 0) := by
  have hc : ContinuousOn f (Ioi 0) := fun x hx => (hd x hx).continuousAt.continuousWithinAt
  refine ⟨strictMonoOn_of_deriv_pos (convex_Ioi 0) hc fun x hx => ?_, hc⟩
  rw [interior_Ioi] at hx
  rw [(hd x hx).deriv]; exact hpos x hx

lemma call_premium_aux (r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ S v : ℝ, 0 < S →
      ((∃! K : ℝ, 0 < K ∧ bsCall S K r q σ T = v) ↔ (0 < v ∧ v < S * exp (-q * T)))) ∧
    (∀ K v : ℝ, 0 < K →
      ((∃! S : ℝ, 0 < S ∧ bsCall S K r q σ T = v) ↔ 0 < v)) := by
  constructor
  · intro S v hS
    obtain ⟨hanti, hc⟩ := strictAntiOn_of_hasDerivAt
      (fun k hk => bsCall_hasDerivAt_K S k r q σ T hS hk hσ hT)
      (fun k _ => neg_neg_of_pos (mul_pos (exp_pos _) (stdNormalCDF_pos _)))
    exact unique_root_anti hanti hc (bsCall_tendsto_K0 S r q σ T hS hσ hT)
      (bsCall_tendsto_Ktop S r q σ T hS hσ hT) v
  · intro K v hK
    obtain ⟨hmono, hc⟩ := strictMonoOn_of_hasDerivAt
      (fun s hs => bsCall_hasDerivAt_S s K r q σ T hs hK hσ hT)
      (fun s _ => mul_pos (exp_pos _) (stdNormalCDF_pos _))
    exact unique_root_mono hmono hc (bsCall_tendsto_S0 K r q σ T hK hσ hT)
      (bsCall_tendsto_Stop K r q σ T hK hσ hT) v

lemma put_premium_aux (r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ S v : ℝ, 0 < S →
      ((∃! K : ℝ, 0 < K ∧ bsPut S K r q σ T = v) ↔ 0 < v)) ∧
    (∀ K v : ℝ, 0 < K →
      ((∃! S : ℝ, 0 < S ∧ bsPut S K r q σ T = v) ↔ (0 < v ∧ v < K * exp (-r * T)))) := by
  constructor
  · intro S v hS
    have hd : ∀ k ∈ Ioi (0:ℝ), HasDerivAt (fun k => bsPut S k r q σ T)
        (-(exp (-r * T) * stdNormalCDF (bsD1 S k r q σ T - σ * √T)) + exp (-r * T)) k := by
      intro k hk
      have h := ((bsCall_hasDerivAt_K S k r q σ T hS hk hσ hT).sub_const (S * exp (-q * T))).add
        (hasDerivAt_mul_const (exp (-r * T)))
      exact h.congr_of_eventuallyEq (Eventually.of_forall fun x => bsPut_eq S x r q σ T)
    obtain ⟨hmono, hc⟩ := strictMonoOn_of_hasDerivAt hd (fun k _ => by
      have := stdNormalCDF_lt_one (bsD1 S k r q σ T - σ * √T)
      have e := exp_pos (-r * T)
      nlinarith)
    have h0 : Tendsto (fun k => bsPut S k r q σ T) (𝓝[>] 0) (𝓝 0) := by
      have hk : Tendsto (fun k : ℝ => k) (𝓝[>] 0) (𝓝 0) := tendsto_id.mono_left nhdsWithin_le_nhds
      have h := ((bsCall_tendsto_K0 S r q σ T hS hσ hT).sub_const (S * exp (-q * T))).add
        (hk.mul_const (exp (-r * T)))
      simp only [sub_self, zero_mul, add_zero, ← bsPut_eq] at h
      exact h
    have hinf : Tendsto (fun k => bsPut S k r q σ T) atTop atTop := by
      have h := ((bsCall_tendsto_Ktop S r q σ T hS hσ hT).sub_const (S * exp (-q * T))).add_atTop
        (tendsto_id.atTop_mul_const (exp_pos (-r * T)))
      exact h.congr' (Eventually.of_forall fun x => (bsPut_eq S x r q σ T).symm)
    exact unique_root_mono hmono hc h0 hinf v
  · intro K v hK
    have hd : ∀ s ∈ Ioi (0:ℝ), HasDerivAt (fun s => bsPut s K r q σ T)
        (exp (-q * T) * stdNormalCDF (bsD1 s K r q σ T) - exp (-q * T)) s := by
      intro s hs
      have h := (((bsCall_hasDerivAt_S s K r q σ T hs hK hσ hT).sub
        (hasDerivAt_mul_const (exp (-q * T)))).add_const (K * exp (-r * T)))
      exact h.congr_of_eventuallyEq (Eventually.of_forall fun x => bsPut_eq x K r q σ T)
    obtain ⟨hanti, hc⟩ := strictAntiOn_of_hasDerivAt hd (fun s _ => by
      have := stdNormalCDF_lt_one (bsD1 s K r q σ T)
      have e := exp_pos (-q * T)
      nlinarith)
    have h0 : Tendsto (fun s => bsPut s K r q σ T) (𝓝[>] 0) (𝓝 (K * exp (-r * T))) := by
      have hs : Tendsto (fun s : ℝ => s) (𝓝[>] 0) (𝓝 0) := tendsto_id.mono_left nhdsWithin_le_nhds
      have h := ((bsCall_tendsto_S0 K r q σ T hK hσ hT).sub
        (hs.mul_const (exp (-q * T)))).add_const (K * exp (-r * T))
      simp only [sub_self, zero_mul, zero_add, ← bsPut_eq] at h
      exact h
    exact unique_root_anti hanti hc h0 (bsPut_tendsto_Stop K r q σ T hK hσ hT) v


end Helpers

#print axioms unique_root_anti
#print axioms unique_root_mono
#print axioms stdPDF
#print axioms stdPDF_eq
#print axioms stdPDF_pos
#print axioms stdPDF_neg
#print axioms stdNormalCDF_eq_integral
#print axioms stdPDF_integrable
#print axioms stdPDF_continuous
#print axioms stdNormalCDF_eq'
#print axioms hasDerivAt_stdNormalCDF
#print axioms stdNormalCDF_strictMono
#print axioms stdNormalCDF_continuous
#print axioms tendsto_stdNormalCDF_atTop
#print axioms tendsto_stdNormalCDF_atBot
#print axioms stdNormalCDF_pos
#print axioms stdNormalCDF_lt_one
#print axioms stdNormalCDF_neg
#print axioms stdNormalCDF_le_exp
#print axioms tendsto_exp_mul_stdNormalCDF
#print axioms bs_pdf_identity
#print axioms bsD1_differentiableAt_K
#print axioms bsD1_differentiableAt_S
#print axioms bsCall_hasDerivAt_K
#print axioms bsCall_hasDerivAt_S
#print axioms bsD1_eq
#print axioms bsD1_tendsto_K0
#print axioms bsD1_tendsto_Ktop
#print axioms bsD1_tendsto_S0
#print axioms bsD1_tendsto_Stop
#print axioms tendsto_sub_const_atTop
#print axioms tendsto_sub_const_atBot
#print axioms bsCall_tendsto_K0
#print axioms bsCall_tendsto_Ktop
#print axioms bsCall_tendsto_S0
#print axioms bsCall_tendsto_Stop
#print axioms bsPut_eq
#print axioms bsPut_tendsto_Stop
#print axioms strictAntiOn_of_hasDerivAt
#print axioms strictMonoOn_of_hasDerivAt
#print axioms call_premium_aux
#print axioms put_premium_aux

/-- **Each call premium inside its range picks out exactly one strike and exactly one spot**
(the card's main claim; Why it works, Steps 0 to 3). Fix volatility `σ > 0` and time `T > 0`,
with the rate `r` and dividend yield `q` held fixed. With the spot `S > 0` fixed, a call premium
`v` is the price of exactly one positive strike if and only if `0 < v < S e^(-qT)`; at or beyond
those ends no positive strike has it. With the strike `K > 0` fixed, a call premium `v` is the
price at exactly one positive spot if and only if `v > 0`. -/
theorem call_premium_names_one_strike_and_one_spot (r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ S v : ℝ, 0 < S →
      ((∃! K : ℝ, 0 < K ∧ bsCall S K r q σ T = v) ↔ (0 < v ∧ v < S * exp (-q * T)))) ∧
    (∀ K v : ℝ, 0 < K →
      ((∃! S : ℝ, 0 < S ∧ bsCall S K r q σ T = v) ↔ 0 < v)) := by
  exact call_premium_aux r q σ T hσ hT

/-- **The put follows from parity** (Why it works, Step 4; the range table). Under the same
terms, with the spot `S > 0` fixed, a put premium `v` is the price of exactly one positive strike
if and only if `v > 0`; with the strike `K > 0` fixed, a put premium `v` is the price at exactly
one positive spot if and only if `0 < v < K e^(-rT)`. -/
theorem put_premium_names_one_strike_and_one_spot (r q σ T : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    (∀ S v : ℝ, 0 < S →
      ((∃! K : ℝ, 0 < K ∧ bsPut S K r q σ T = v) ↔ 0 < v)) ∧
    (∀ K v : ℝ, 0 < K →
      ((∃! S : ℝ, 0 < S ∧ bsPut S K r q σ T = v) ↔ (0 < v ∧ v < K * exp (-r * T)))) := by
  exact put_premium_aux r q σ T hσ hT

/-- **The two slopes** (The formula; Detailed proof). With `S > 0`, `K > 0`, `σ > 0`, `T > 0`,
one more dollar of strike changes the call by `∂C/∂K = -e^(-rT) N(d₂)`, and one more dollar of
spot changes it by `∂C/∂S = e^(-qT) N(d₁)`, the call's delta. -/
theorem call_strike_slope_and_spot_slope (S K r q σ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun k => bsCall S k r q σ T)
        (-(exp (-r * T) * stdNormalCDF (bsD1 S K r q σ T - σ * √T))) K ∧
      HasDerivAt (fun s => bsCall s K r q σ T)
        (exp (-q * T) * stdNormalCDF (bsD1 S K r q σ T)) S := by
  exact ⟨bsCall_hasDerivAt_K S K r q σ T hS hK hσ hT, bsCall_hasDerivAt_S S K r q σ T hS hK hσ hT⟩

-- Acme: S = K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1 year.
-- The drift inside d₁: (0.05 - 0.02 + 0.20²/2) · 1 = 0.05.
example : ((5 : ℚ) / 100 - 2 / 100 + (1 / 5) ^ 2 / 2) * 1 = 1 / 20 := by norm_num
-- At the money, d₁ = (ln(100/100) + 0.05) / (0.20 · √1) = 0.25 and d₂ = 0.25 - 0.20 = 0.05.
example : bsD1 100 100 (5 / 100) (2 / 100) (1 / 5) 1 = 1 / 4 := by norm_num [bsD1]
example : (1 / 4 : ℚ) - 1 / 5 * 1 = 1 / 20 := by norm_num
-- Expiry today: a call struck at $95 pays max(100 - 95, 0) = $5, the budget.
example : max ((100 : ℤ) - 95) 0 = 5 := by decide
-- A $99.00 target is above the $98.02 ceiling, so no strike exists.
example : (9802 : ℚ) / 100 < 99 := by norm_num
-- Parity at K = 100: call $9.23 minus put $6.33 equals $98.02 - $95.12 = $2.90.
example : (923 : ℚ) / 100 - 633 / 100 = 9802 / 100 - 9512 / 100 := by norm_num
-- The buyer gives up the first $10.60 of rise and pays $9.23 - $5.00 = $4.23 less.
example : (11060 : ℚ) / 100 - 100 = 1060 / 100 ∧ (923 : ℚ) / 100 - 5 = 423 / 100 := by norm_num

#print axioms call_premium_names_one_strike_and_one_spot
#print axioms put_premium_names_one_strike_and_one_spot
#print axioms call_strike_slope_and_spot_slope
