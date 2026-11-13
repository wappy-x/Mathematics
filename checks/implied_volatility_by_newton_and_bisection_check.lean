-- Solving for implied volatility: for a Black–Scholes call quote strictly between its floor and ceiling there is exactly one volatility, vega rises below the peak-vega start and falls above it, and Newton's method started there never overshoots and converges to that volatility.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Order.Basic

open MeasureTheory ProbabilityTheory Real Filter Topology

namespace ImpliedVolNewtonBisection

/-! The model, as on the card. `N(x)` is Mathlib's `cdf (gaussianReal 0 1) x` and `φ(x)` is
Mathlib's `gaussianPDFReal 0 1 x`. Share price `S`, strike `K`, cash rate `r`, dividend yield
`q`, years to expiry `T`, volatility `σ`. The forward is `F = S e^((r - q) T)`. -/

/-- `d1 = (ln(S/K) + (r - q + σ²/2) T) / (σ √T)`; then `d2 = d1 - σ √T`. -/
noncomputable def bsD1 (S K r q T σ : ℝ) : ℝ :=
  (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T)

/-- The Black–Scholes call price `C(σ) = S e^(-qT) N(d1) - K e^(-rT) N(d2)`. -/
noncomputable def bsCall (S K r q T σ : ℝ) : ℝ :=
  S * exp (-(q * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q T σ) -
    K * exp (-(r * T)) * cdf (gaussianReal 0 1) (bsD1 S K r q T σ - σ * √T)

/-- Vega `𝒱(σ) = S e^(-qT) φ(d1) √T`: dollars gained per 1.00 of volatility. -/
noncomputable def bsVega (S K r q T σ : ℝ) : ℝ :=
  S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q T σ) * √T

/-- The peak-vega start `σ_c = √(2 |ln(F/K)| / T)` with `F = S e^((r - q) T)`. -/
noncomputable def peakVegaStart (S K r q T : ℝ) : ℝ :=
  √(2 * |log (S * exp ((r - q) * T) / K)| / T)

/-- Newton's guesses for the quote `Cmkt` from the start `σ₀`:
`σ_(n+1) = σ_n - (C(σ_n) - Cmkt) / 𝒱(σ_n)`. -/
noncomputable def newtonGuess (S K r q T Cmkt σ₀ : ℝ) : ℕ → ℝ
  | 0 => σ₀
  | n + 1 =>
    newtonGuess S K r q T Cmkt σ₀ n -
      (bsCall S K r q T (newtonGuess S K r q T Cmkt σ₀ n) - Cmkt) /
        bsVega S K r q T (newtonGuess S K r q T Cmkt σ₀ n)

lemma iv_cdf_eq_integral (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ t))]

lemma iv_continuous_pdf : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma iv_cdf_hasDerivAt (z : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 z) z := by
  have hI : ∀ a, IntegrableOn (gaussianPDFReal 0 1) (Set.Iic a) :=
    fun a => (integrable_gaussianPDFReal 0 1).integrableOn
  have hfun : (cdf (gaussianReal 0 1) : ℝ → ℝ) =
      fun x => cdf (gaussianReal 0 1) 0 + ∫ t in (0:ℝ)..x, gaussianPDFReal 0 1 t := by
    funext x
    rw [← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI x), iv_cdf_eq_integral,
      iv_cdf_eq_integral]
    ring
  rw [hfun]
  exact (intervalIntegral.integral_hasDerivAt_right
    (iv_continuous_pdf.intervalIntegrable _ _)
    (iv_continuous_pdf.stronglyMeasurableAtFilter _ _)
    iv_continuous_pdf.continuousAt).const_add _

lemma iv_cdf_continuous : Continuous (cdf (gaussianReal 0 1)) :=
  continuous_iff_continuousAt.2 fun z => (iv_cdf_hasDerivAt z).continuousAt

lemma iv_pdf_hasDerivAt (x : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-x * gaussianPDFReal 0 1 x) x := by
  have h : (gaussianPDFReal 0 1 : ℝ → ℝ) = fun y => (√(2 * π))⁻¹ * exp (-y ^ 2 / 2) := by
    funext y; simp [gaussianPDFReal_def]
  rw [h]
  have h2 : HasDerivAt (fun y : ℝ => -y ^ 2 / 2) (-x) x := by
    have := ((hasDerivAt_pow 2 x).neg).div_const 2
    convert this using 1; ring
  have := (h2.exp).const_mul (√(2 * π))⁻¹
  convert this using 1; ring

lemma iv_logF (S K r q T : ℝ) (hS : 0 < S) (hK : 0 < K) :
    log (S * exp ((r - q) * T) / K) = log (S / K) + (r - q) * T := by
  rw [mul_div_right_comm, log_mul (by positivity) (exp_pos _).ne', log_exp]

lemma iv_d1_eq (S K r q T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) :
    bsD1 S K r q T σ = log (S * exp ((r - q) * T) / K) / (σ * √T) + σ * √T / 2 := by
  unfold bsD1
  rw [iv_logF S K r q T hS hK]
  rcases eq_or_ne σ 0 with rfl | hσ
  · simp
  · have hsT : 0 < √T := Real.sqrt_pos.2 hT
    have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
    field_simp
    linear_combination (-σ ^ 2) * hsq

lemma iv_share_cash (S K r q T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    S * exp (-(q * T)) * gaussianPDFReal 0 1 (bsD1 S K r q T σ) =
      K * exp (-(r * T)) * gaussianPDFReal 0 1 (bsD1 S K r q T σ - σ * √T) := by
  unfold bsD1
  set d := (log (S / K) + (r - q + σ ^ 2 / 2) * T) / (σ * √T) with hd
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have key : d * (σ * √T) = log S - log K + (r - q + σ ^ 2 / 2) * T := by
    rw [hd, div_mul_cancel₀ _ (by positivity), Real.log_div hS.ne' hK.ne']
  simp only [gaussianPDFReal_def, NNReal.coe_one, sub_zero, mul_one]
  have h : log S + -(q * T) + -d ^ 2 / 2 = log K + -(r * T) + -(d - σ * √T) ^ 2 / 2 := by
    linear_combination (-1 : ℝ) * key + (σ ^ 2 / 2) * hsq
  have e1 : S * exp (-(q * T)) * ((√(2 * π))⁻¹ * exp (-d ^ 2 / 2)) =
      (√(2 * π))⁻¹ * exp (log S + -(q * T) + -d ^ 2 / 2) := by
    rw [exp_add, exp_add, exp_log hS]; ring
  have e2 : K * exp (-(r * T)) * ((√(2 * π))⁻¹ * exp (-(d - σ * √T) ^ 2 / 2)) =
      (√(2 * π))⁻¹ * exp (log K + -(r * T) + -(d - σ * √T) ^ 2 / 2) := by
    rw [exp_add, exp_add, exp_log hK]; ring
  rw [e1, e2, h]

lemma iv_d1_hasDerivAt (S K r q T σ : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun s : ℝ => bsD1 S K r q T s) (-(bsD1 S K r q T σ - σ * √T) / σ) σ := by
  unfold bsD1
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsq : √T ^ 2 = T := Real.sq_sqrt hT.le
  have hN : HasDerivAt (fun s : ℝ => log (S / K) + (r - q + s ^ 2 / 2) * T) (σ * T) σ := by
    have := (((hasDerivAt_pow 2 σ).div_const 2).const_add (r - q)).mul_const T |>.const_add
      (log (S / K))
    convert this using 1; push_cast; ring
  have hL : HasDerivAt (fun s : ℝ => s * √T) √T σ := by
    simpa using (hasDerivAt_id σ).mul_const √T
  have := hN.div hL (by positivity)
  convert this using 1
  field_simp
  rw [hsq]
  ring

lemma iv_call_hasDerivAt (S K r q T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ)
    (hT : 0 < T) :
    HasDerivAt (fun s : ℝ => bsCall S K r q T s) (bsVega S K r q T σ) σ := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hD := iv_d1_hasDerivAt S K r q T σ hσ hT
  have hL : HasDerivAt (fun s => s * √T) √T σ := by
    simpa using (hasDerivAt_id σ).mul_const √T
  have hD2 := hD.sub hL
  have hshare := iv_share_cash S K r q T σ hS hK hσ hT
  have hN1 := (iv_cdf_hasDerivAt (bsD1 S K r q T σ)).comp σ hD
  have hN2 := (iv_cdf_hasDerivAt (bsD1 S K r q T σ - σ * √T)).comp σ hD2
  have := (hN1.const_mul (S * exp (-(q * T)))).sub (hN2.const_mul (K * exp (-(r * T))))
  unfold bsCall bsVega
  convert this using 1
  · rfl
  · rw [← mul_assoc (K * exp (-(r * T))), ← hshare]
    field_simp
    ring

lemma iv_vega_hasDerivAt (S K r q T σ : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt (fun s : ℝ => bsVega S K r q T s)
      (bsVega S K r q T σ * bsD1 S K r q T σ * (bsD1 S K r q T σ - σ * √T) / σ) σ := by
  have h := (iv_pdf_hasDerivAt (bsD1 S K r q T σ)).comp σ (iv_d1_hasDerivAt S K r q T σ hσ hT)
  have := (h.const_mul (S * exp (-(q * T)))).mul_const √T
  unfold bsVega
  convert this using 1
  simp only [Function.comp_def]
  field_simp

lemma iv_vega_pos (S K r q T σ : ℝ) (hS : 0 < S) (hT : 0 < T) : 0 < bsVega S K r q T σ := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have := gaussianPDFReal_pos 0 1 (bsD1 S K r q T σ) one_ne_zero
  unfold bsVega; positivity

lemma iv_d1d2 (S K r q T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    bsD1 S K r q T σ * (bsD1 S K r q T σ - σ * √T) =
      log (S * exp ((r - q) * T) / K) ^ 2 / (σ ^ 2 * T) - σ ^ 2 * T / 4 := by
  rw [iv_d1_eq S K r q T σ hS hK hT]
  obtain ⟨t, ht, rfl⟩ : ∃ t, 0 < t ∧ T = t ^ 2 :=
    ⟨√T, Real.sqrt_pos.2 hT, (Real.sq_sqrt hT.le).symm⟩
  rw [Real.sqrt_sq ht.le]
  field_simp
  ring

lemma iv_d1d2_iff (S K r q T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    0 ≤ bsD1 S K r q T σ * (bsD1 S K r q T σ - σ * √T) ↔ σ ≤ peakVegaStart S K r q T := by
  rw [iv_d1d2 S K r q T σ hS hK hT hσ, peakVegaStart, Real.le_sqrt' hσ,
    le_div_iff₀ hT]
  set m := log (S * exp ((r - q) * T) / K)
  have hv : 0 < σ ^ 2 * T := by positivity
  have e : m ^ 2 / (σ ^ 2 * T) - σ ^ 2 * T / 4 =
      ((2 * |m|) ^ 2 - (σ ^ 2 * T) ^ 2) / (4 * (σ ^ 2 * T)) := by
    rw [mul_pow, sq_abs]; field_simp; ring
  rw [e, div_nonneg_iff]
  have h4 : 0 < 4 * (σ ^ 2 * T) := by positivity
  constructor
  · rintro (⟨h1, _⟩ | ⟨_, h2⟩)
    · have := (sq_le_sq₀ (a := σ ^ 2 * T) (b := 2 * |m|) hv.le (by positivity)).1 (by linarith)
      linarith
    · linarith
  · intro h
    left
    refine ⟨?_, h4.le⟩
    have := (sq_le_sq₀ (a := σ ^ 2 * T) (b := 2 * |m|) hv.le (by positivity)).2 (by linarith : σ ^ 2 * T ≤ 2 * |m|)
    linarith

lemma iv_ok (S K r q T x : ℝ) (hT : 0 < T) (hx : peakVegaStart S K r q T ≤ x) :
    0 < x ∨ log (S * exp ((r - q) * T) / K) = 0 := by
  rcases lt_or_ge 0 x with h | h
  · exact Or.inl h
  · right
    have h0 : peakVegaStart S K r q T = 0 :=
      le_antisymm (hx.trans h) (Real.sqrt_nonneg _)
    rw [peakVegaStart, Real.sqrt_eq_zero', div_le_iff₀ hT] at h0
    exact abs_nonpos_iff.1 (by linarith)

lemma iv_A_eq_B (S K r q T : ℝ) (hS : 0 < S) (hK : 0 < K)
    (hm : log (S * exp ((r - q) * T) / K) = 0) :
    S * exp (-(q * T)) = K * exp (-(r * T)) := by
  have h := Real.exp_log (show 0 < S * exp ((r - q) * T) / K by positivity)
  rw [hm, exp_zero] at h
  have hK' : K = S * exp ((r - q) * T) := by
    field_simp at h; linarith
  rw [hK', mul_assoc, ← exp_add]
  ring_nf

lemma iv_call_eq (S K r q T : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) :
    bsCall S K r q T = fun σ =>
      S * exp (-(q * T)) * cdf (gaussianReal 0 1)
          (log (S * exp ((r - q) * T) / K) / (σ * √T) + σ * √T / 2) -
        K * exp (-(r * T)) * cdf (gaussianReal 0 1)
          (log (S * exp ((r - q) * T) / K) / (σ * √T) - σ * √T / 2) := by
  funext σ
  rw [bsCall, iv_d1_eq S K r q T σ hS hK hT]
  ring_nf

lemma iv_call_zero (S K r q T : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hm : log (S * exp ((r - q) * T) / K) = 0) : bsCall S K r q T 0 = 0 := by
  rw [iv_call_eq S K r q T hS hK hT, iv_A_eq_B S K r q T hS hK hm]
  simp

lemma iv_call_cont (S K r q T x : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hx : 0 < x ∨ log (S * exp ((r - q) * T) / K) = 0) :
    ContinuousAt (bsCall S K r q T) x := by
  rcases hx with hx | hm
  · exact (iv_call_hasDerivAt S K r q T x hS hK hx hT).continuousAt
  · rw [iv_call_eq S K r q T hS hK hT, hm]
    simp only [zero_div, zero_add, zero_sub]
    have hc := iv_cdf_continuous
    exact ((continuous_const.mul (hc.comp (by fun_prop))).sub
      (continuous_const.mul (hc.comp (by fun_prop)))).continuousAt

lemma iv_vega_cont (S K r q T x : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hx : 0 < x ∨ log (S * exp ((r - q) * T) / K) = 0) :
    ContinuousAt (bsVega S K r q T) x := by
  rcases hx with hx | hm
  · exact (iv_vega_hasDerivAt S K r q T x hx hT).continuousAt
  · have e : bsVega S K r q T = fun σ =>
        S * exp (-(q * T)) * gaussianPDFReal 0 1 (σ * √T / 2) * √T := by
      funext σ; rw [bsVega, iv_d1_eq S K r q T σ hS hK hT, hm, zero_div, zero_add]
    rw [e]
    have hc := iv_continuous_pdf
    exact ((continuous_const.mul (hc.comp (by fun_prop))).mul continuous_const).continuousAt

lemma iv_call_strictMonoOn (S K r q T : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) :
    StrictMonoOn (bsCall S K r q T) (Set.Ioi 0) := by
  refine strictMonoOn_of_deriv_pos (convex_Ioi 0) ?_ ?_
  · exact fun x hx => (iv_call_cont S K r q T x hS hK hT (Or.inl hx)).continuousWithinAt
  · intro x hx
    rw [interior_Ioi] at hx
    rw [(iv_call_hasDerivAt S K r q T x hS hK hx hT).deriv]
    exact iv_vega_pos S K r q T x hS hT

lemma iv_vega_mono (S K r q T a b : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (ha : 0 < a)
    (hab : a ≤ b) (hb : b ≤ peakVegaStart S K r q T) :
    bsVega S K r q T a ≤ bsVega S K r q T b := by
  have hmono : MonotoneOn (bsVega S K r q T) (Set.Icc a b) := by
    refine monotoneOn_of_deriv_nonneg (convex_Icc a b) ?_ ?_ ?_
    · exact fun x hx => (iv_vega_cont S K r q T x hS hK hT
        (Or.inl (ha.trans_le hx.1))).continuousWithinAt
    · intro x hx
      rw [interior_Icc] at hx
      exact (iv_vega_hasDerivAt S K r q T x (ha.trans hx.1) hT).differentiableAt.differentiableWithinAt
    · intro x hx
      rw [interior_Icc] at hx
      have hx0 : 0 < x := ha.trans hx.1
      rw [(iv_vega_hasDerivAt S K r q T x hx0 hT).deriv]
      have h1 := (iv_d1d2_iff S K r q T x hS hK hT hx0).2 (hx.2.le.trans hb)
      have h2 := iv_vega_pos S K r q T x hS hT
      rw [mul_assoc]
      positivity
  exact hmono ⟨le_rfl, hab⟩ ⟨hab, le_rfl⟩ hab

lemma iv_vega_anti (S K r q T a b : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (ha : peakVegaStart S K r q T ≤ a) (hab : a ≤ b) :
    bsVega S K r q T b ≤ bsVega S K r q T a := by
  have hc0 : 0 ≤ peakVegaStart S K r q T := Real.sqrt_nonneg _
  have hanti : AntitoneOn (bsVega S K r q T) (Set.Icc a b) := by
    refine antitoneOn_of_deriv_nonpos (convex_Icc a b) ?_ ?_ ?_
    · exact fun x hx => (iv_vega_cont S K r q T x hS hK hT
        (iv_ok S K r q T x hT (ha.trans hx.1))).continuousWithinAt
    · intro x hx
      rw [interior_Icc] at hx
      exact (iv_vega_hasDerivAt S K r q T x (by linarith [hx.1]) hT).differentiableAt.differentiableWithinAt
    · intro x hx
      rw [interior_Icc] at hx
      have hx0 : 0 < x := by linarith [hx.1]
      rw [(iv_vega_hasDerivAt S K r q T x hx0 hT).deriv]
      have h1 : ¬ 0 ≤ bsD1 S K r q T x * (bsD1 S K r q T x - x * √T) := by
        rw [iv_d1d2_iff S K r q T x hS hK hT hx0]; linarith [hx.1]
      have h2 := iv_vega_pos S K r q T x hS hT
      rw [mul_assoc]
      exact div_nonpos_of_nonpos_of_nonneg
        (mul_nonpos_of_nonneg_of_nonpos h2.le (by linarith)) hx0.le
  exact hanti ⟨le_rfl, hab⟩ ⟨hab, le_rfl⟩ hab

lemma iv_exists_low (S K r q T Cmkt : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hfloor : max (S * exp (-(q * T)) - K * exp (-(r * T))) 0 < Cmkt) :
    ∃ a, 0 < a ∧ bsCall S K r q T a < Cmkt := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hsmall : Tendsto (fun σ : ℝ => σ * √T / 2) (𝓝[>] 0) (𝓝 0) := by
    have h : Tendsto (fun σ : ℝ => σ * √T / 2) (𝓝 0) (𝓝 (0 * √T / 2)) :=
      ((continuous_id.mul continuous_const).div_const 2).tendsto 0
    simpa using h.mono_left nhdsWithin_le_nhds
  have hsmall' : Tendsto (fun σ : ℝ => -(σ * √T / 2)) (𝓝[>] 0) (𝓝 0) := by
    simpa using hsmall.neg
  have hL : ∃ L, L ≤ max (S * exp (-(q * T)) - K * exp (-(r * T))) 0 ∧
      Tendsto (bsCall S K r q T) (𝓝[>] 0) (𝓝 L) := by
    rw [iv_call_eq S K r q T hS hK hT]
    set m := log (S * exp ((r - q) * T) / K)
    have hform : ∀ σ : ℝ, m / (σ * √T) = m / √T * σ⁻¹ := fun σ => by ring
    rcases lt_trichotomy m 0 with hneg | hzero | hpos
    · have h1 : Tendsto (fun σ : ℝ => m / (σ * √T)) (𝓝[>] 0) atBot := by
        have := tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg (div_neg_of_neg_of_pos hneg hsT)
        exact this.congr (fun σ => (hform σ).symm)
      have hd1 := h1.atBot_add hsmall
      have hd2 : Tendsto (fun σ : ℝ => m / (σ * √T) - σ * √T / 2) (𝓝[>] 0) atBot :=
        (h1.atBot_add hsmall').congr (fun σ => (sub_eq_add_neg _ _).symm)
      refine ⟨0, le_max_right _ _, ?_⟩
      have := (((tendsto_cdf_atBot (gaussianReal 0 1)).comp hd1).const_mul (S * exp (-(q * T)))).sub
        (((tendsto_cdf_atBot (gaussianReal 0 1)).comp hd2).const_mul (K * exp (-(r * T))))
      simpa using this
    · have hd1 : Tendsto (fun σ : ℝ => m / (σ * √T) + σ * √T / 2) (𝓝[>] 0) (𝓝 0) := by
        simpa [hzero] using hsmall
      have hd2 : Tendsto (fun σ : ℝ => m / (σ * √T) - σ * √T / 2) (𝓝[>] 0) (𝓝 0) := by
        simpa [hzero, sub_eq_add_neg] using hsmall'
      refine ⟨0, le_max_right _ _, ?_⟩
      have hc := iv_cdf_continuous.tendsto 0
      have := ((hc.comp hd1).const_mul (S * exp (-(q * T)))).sub
        ((hc.comp hd2).const_mul (K * exp (-(r * T))))
      have hAB := iv_A_eq_B S K r q T hS hK hzero
      rw [hAB]
      rw [hAB, sub_self] at this
      exact this
    · have h1 : Tendsto (fun σ : ℝ => m / (σ * √T)) (𝓝[>] 0) atTop := by
        have := tendsto_inv_nhdsGT_zero.const_mul_atTop (div_pos hpos hsT)
        exact this.congr (fun σ => (hform σ).symm)
      have hd1 := h1.atTop_add hsmall
      have hd2 : Tendsto (fun σ : ℝ => m / (σ * √T) - σ * √T / 2) (𝓝[>] 0) atTop :=
        (h1.atTop_add hsmall').congr (fun σ => (sub_eq_add_neg _ _).symm)
      refine ⟨_, le_max_left _ _, ?_⟩
      have := (((tendsto_cdf_atTop (gaussianReal 0 1)).comp hd1).const_mul (S * exp (-(q * T)))).sub
        (((tendsto_cdf_atTop (gaussianReal 0 1)).comp hd2).const_mul (K * exp (-(r * T))))
      simpa using this
  obtain ⟨L, hLle, hlim⟩ := hL
  obtain ⟨a, ha1, ha2⟩ :=
    ((hlim.eventually (gt_mem_nhds (hLle.trans_lt hfloor))).and
      (eventually_mem_nhdsWithin (a := (0 : ℝ)) (s := Set.Ioi 0))).exists
  exact ⟨a, ha2, ha1⟩

lemma iv_exists_high (S K r q T Cmkt a : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hceil : Cmkt < S * exp (-(q * T))) :
    ∃ b, a ≤ b ∧ Cmkt < bsCall S K r q T b := by
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hlim : Tendsto (bsCall S K r q T) atTop (𝓝 (S * exp (-(q * T)))) := by
    rw [iv_call_eq S K r q T hS hK hT]
    set m := log (S * exp ((r - q) * T) / K)
    have h0 : Tendsto (fun σ : ℝ => m / (σ * √T)) atTop (𝓝 0) := by
      have := (tendsto_inv_atTop_zero (𝕜 := ℝ)).const_mul (m / √T)
      rw [mul_zero] at this
      exact this.congr (fun σ => by ring)
    have hbig : Tendsto (fun σ : ℝ => σ * √T / 2) atTop atTop :=
      (tendsto_id.atTop_mul_const hsT).atTop_div_const two_pos
    have hd1 := h0.add_atTop hbig
    have hd2 : Tendsto (fun σ : ℝ => m / (σ * √T) - σ * √T / 2) atTop atBot :=
      (h0.add_atBot (tendsto_neg_atTop_atBot.comp hbig)).congr
        (fun σ => (sub_eq_add_neg _ _).symm)
    have := (((tendsto_cdf_atTop (gaussianReal 0 1)).comp hd1).const_mul (S * exp (-(q * T)))).sub
      (((tendsto_cdf_atBot (gaussianReal 0 1)).comp hd2).const_mul (K * exp (-(r * T))))
    simpa using this
  obtain ⟨b, hb1, hb2⟩ := ((hlim.eventually (lt_mem_nhds hceil)).and (eventually_ge_atTop a)).exists
  exact ⟨b, hb2, hb1⟩

lemma iv_exists (S K r q T Cmkt : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hfloor : max (S * exp (-(q * T)) - K * exp (-(r * T))) 0 < Cmkt)
    (hceil : Cmkt < S * exp (-(q * T))) :
    ∃ σ : ℝ, 0 < σ ∧ bsCall S K r q T σ = Cmkt := by
  obtain ⟨a, ha, hCa⟩ := iv_exists_low S K r q T Cmkt hS hK hT hfloor
  obtain ⟨b, hab, hCb⟩ := iv_exists_high S K r q T Cmkt a hS hK hT hceil
  have hcont : ContinuousOn (bsCall S K r q T) (Set.Icc a b) := fun x hx =>
    (iv_call_cont S K r q T x hS hK hT (Or.inl (ha.trans_le hx.1))).continuousWithinAt
  obtain ⟨σ, hσ, hσeq⟩ := intermediate_value_Icc hab hcont ⟨hCa.le, hCb.le⟩
  exact ⟨σ, ha.trans_le hσ.1, hσeq⟩

#print axioms iv_cdf_eq_integral
#print axioms iv_continuous_pdf
#print axioms iv_cdf_hasDerivAt
#print axioms iv_cdf_continuous
#print axioms iv_pdf_hasDerivAt
#print axioms iv_logF
#print axioms iv_d1_eq
#print axioms iv_share_cash
#print axioms iv_d1_hasDerivAt
#print axioms iv_call_hasDerivAt
#print axioms iv_vega_hasDerivAt
#print axioms iv_vega_pos
#print axioms iv_d1d2
#print axioms iv_d1d2_iff
#print axioms iv_ok
#print axioms iv_A_eq_B
#print axioms iv_call_eq
#print axioms iv_call_zero
#print axioms iv_call_cont
#print axioms iv_vega_cont
#print axioms iv_call_strictMonoOn
#print axioms iv_vega_mono
#print axioms iv_vega_anti
#print axioms iv_exists_low
#print axioms iv_exists_high
#print axioms iv_exists

/-- **Newton from the peak never overshoots** (Steps 2 and 3). Take a European call with share
price `S > 0`, strike `K > 0` and `T > 0` years left, and a quote `Cmkt` strictly between the
call's floor `max(S e^(-qT) - K e^(-rT), 0)` and its ceiling `S e^(-qT)`. Then there is a
volatility `σ* > 0` whose Black–Scholes price is the quote, and Newton's method started at the
peak-vega volatility `σ_c` never passes it: if `σ* ≤ σ_c` every guess falls and stays at or
above `σ*`; if `σ* ≥ σ_c` every guess climbs and stays at or below `σ*`; and the guesses
converge to `σ*`. -/
theorem newton_from_peak_vega_start_never_overshoots
    (S K r q T Cmkt : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hfloor : max (S * exp (-(q * T)) - K * exp (-(r * T))) 0 < Cmkt)
    (hceil : Cmkt < S * exp (-(q * T))) :
    ∃ σs : ℝ, 0 < σs ∧ bsCall S K r q T σs = Cmkt ∧
      (σs ≤ peakVegaStart S K r q T → ∀ n : ℕ,
        σs ≤ newtonGuess S K r q T Cmkt (peakVegaStart S K r q T) (n + 1) ∧
          newtonGuess S K r q T Cmkt (peakVegaStart S K r q T) (n + 1) ≤
            newtonGuess S K r q T Cmkt (peakVegaStart S K r q T) n) ∧
      (peakVegaStart S K r q T ≤ σs → ∀ n : ℕ,
        newtonGuess S K r q T Cmkt (peakVegaStart S K r q T) n ≤
            newtonGuess S K r q T Cmkt (peakVegaStart S K r q T) (n + 1) ∧
          newtonGuess S K r q T Cmkt (peakVegaStart S K r q T) (n + 1) ≤ σs) ∧
      Tendsto (newtonGuess S K r q T Cmkt (peakVegaStart S K r q T)) atTop (𝓝 σs) := by
  obtain ⟨σs, hσs, hCs⟩ := iv_exists S K r q T Cmkt hS hK hT hfloor hceil
  have hc0 : 0 ≤ peakVegaStart S K r q T := Real.sqrt_nonneg _
  have hCpos : 0 < Cmkt := lt_of_le_of_lt (le_max_right _ _) hfloor
  have hinj := (iv_call_strictMonoOn S K r q T hS hK hT).injOn
  set σc := peakVegaStart S K r q T with hσc
  set g := newtonGuess S K r q T Cmkt σc with hg
  have hg0 : g 0 = σc := rfl
  have hgs : ∀ n, g (n + 1) =
      g n - (bsCall S K r q T (g n) - Cmkt) / bsVega S K r q T (g n) := fun n => rfl
  have step1 : ∀ x, σs ≤ x → x ≤ σc →
      σs ≤ x - (bsCall S K r q T x - Cmkt) / bsVega S K r q T x ∧
        x - (bsCall S K r q T x - Cmkt) / bsVega S K r q T x ≤ x := by
    intro x h1 h2
    have hVx := iv_vega_pos S K r q T x hS hT
    rcases h1.eq_or_lt with h | h
    · subst h; simp [hCs]
    · obtain ⟨ξ, hξ, hξeq⟩ := exists_hasDerivAt_eq_slope (bsCall S K r q T)
        (bsVega S K r q T) h
        (fun t ht => (iv_call_cont S K r q T t hS hK hT
          (Or.inl (hσs.trans_le ht.1))).continuousWithinAt)
        (fun t ht => iv_call_hasDerivAt S K r q T t hS hK (hσs.trans ht.1) hT)
      have hVξ := iv_vega_mono S K r q T ξ x hS hK hT (hσs.trans hξ.1) hξ.2.le h2
      have hVξpos := iv_vega_pos S K r q T ξ hS hT
      rw [hCs, eq_div_iff (sub_pos.2 h).ne'] at hξeq
      have hnum : 0 ≤ bsCall S K r q T x - Cmkt := by
        rw [← hξeq]; exact mul_nonneg hVξpos.le (sub_pos.2 h).le
      have hle : (bsCall S K r q T x - Cmkt) / bsVega S K r q T x ≤ x - σs := by
        rw [div_le_iff₀ hVx, ← hξeq]; nlinarith
      exact ⟨by linarith, sub_le_self _ (div_nonneg hnum hVx.le)⟩
  have step2 : ∀ x, σc ≤ x → x ≤ σs →
      x ≤ x - (bsCall S K r q T x - Cmkt) / bsVega S K r q T x ∧
        x - (bsCall S K r q T x - Cmkt) / bsVega S K r q T x ≤ σs := by
    intro x h1 h2
    have hVx := iv_vega_pos S K r q T x hS hT
    rcases h2.eq_or_lt with h | h
    · subst h; simp [hCs]
    · obtain ⟨ξ, hξ, hξeq⟩ := exists_hasDerivAt_eq_slope (bsCall S K r q T)
        (bsVega S K r q T) h
        (fun t ht => (iv_call_cont S K r q T t hS hK hT
          (iv_ok S K r q T t hT (h1.trans ht.1))).continuousWithinAt)
        (fun t ht => iv_call_hasDerivAt S K r q T t hS hK (by linarith [ht.1]) hT)
      have hVξ := iv_vega_anti S K r q T x ξ hS hK hT h1 hξ.1.le
      have hVξpos := iv_vega_pos S K r q T ξ hS hT
      rw [hCs, eq_div_iff (sub_pos.2 h).ne'] at hξeq
      have hnum : bsCall S K r q T x - Cmkt ≤ 0 := by
        have : 0 ≤ Cmkt - bsCall S K r q T x := by
          rw [← hξeq]; exact mul_nonneg hVξpos.le (sub_pos.2 h).le
        linarith
      have hle : x - σs ≤ (bsCall S K r q T x - Cmkt) / bsVega S K r q T x := by
        rw [le_div_iff₀ hVx]; nlinarith
      exact ⟨le_sub_self_iff _ |>.2 (div_nonpos_of_nonpos_of_nonneg hnum hVx.le),
        by linarith⟩
  have inv1 : σs ≤ σc → ∀ n, σs ≤ g n ∧ g n ≤ σc := by
    intro hle n
    induction n with
    | zero => exact ⟨hle, le_rfl⟩
    | succ n ih =>
      rw [hgs]
      have := step1 (g n) ih.1 ih.2
      exact ⟨this.1, this.2.trans ih.2⟩
  have inv2 : σc ≤ σs → ∀ n, σc ≤ g n ∧ g n ≤ σs := by
    intro hle n
    induction n with
    | zero => exact ⟨le_rfl, hle⟩
    | succ n ih =>
      rw [hgs]
      have := step2 (g n) ih.1 ih.2
      exact ⟨ih.1.trans this.1, this.2⟩
  have hfix : ∀ L, (0 < L ∨ log (S * exp ((r - q) * T) / K) = 0) →
      Tendsto g atTop (𝓝 L) → bsCall S K r q T L = Cmkt := by
    intro L hL hlim
    have hV := iv_vega_pos S K r q T L hS hT
    have hΦ : ContinuousAt
        (fun x => x - (bsCall S K r q T x - Cmkt) / bsVega S K r q T x) L :=
      continuousAt_id.sub (((iv_call_cont S K r q T L hS hK hT hL).sub
        continuousAt_const).div (iv_vega_cont S K r q T L hS hK hT hL) hV.ne')
    have h1 : Tendsto (fun n => g (n + 1)) atTop (𝓝 L) :=
      hlim.comp (tendsto_add_atTop_nat 1)
    have h2 : Tendsto (fun n => g (n + 1)) atTop
        (𝓝 (L - (bsCall S K r q T L - Cmkt) / bsVega S K r q T L)) :=
      (hΦ.tendsto.comp hlim).congr (fun n => (hgs n).symm)
    have h3 := tendsto_nhds_unique h1 h2
    have h4 : (bsCall S K r q T L - Cmkt) / bsVega S K r q T L = 0 := by linarith
    rcases div_eq_zero_iff.1 h4 with h | h
    · linarith
    · exact absurd h hV.ne'
  have hlimit : Tendsto g atTop (𝓝 σs) := by
    rcases le_total σs σc with hle | hge
    · have hI := inv1 hle
      have hanti : Antitone g := antitone_nat_of_succ_le
        (fun n => by rw [hgs]; exact (step1 (g n) (hI n).1 (hI n).2).2)
      have hbdd : BddBelow (Set.range g) := ⟨σs, by rintro _ ⟨n, rfl⟩; exact (hI n).1⟩
      have hlim := tendsto_atTop_ciInf hanti hbdd
      have hL : σs ≤ ⨅ n, g n := le_ciInf (fun n => (hI n).1)
      have hCL := hfix _ (Or.inl (hσs.trans_le hL)) hlim
      have : (⨅ n, g n) = σs := hinj (hσs.trans_le hL) hσs (hCL.trans hCs.symm)
      rwa [this] at hlim
    · have hI := inv2 hge
      have hmono : Monotone g := monotone_nat_of_le_succ
        (fun n => by rw [hgs]; exact (step2 (g n) (hI n).1 (hI n).2).1)
      have hbdd : BddAbove (Set.range g) := ⟨σs, by rintro _ ⟨n, rfl⟩; exact (hI n).2⟩
      have hlim := tendsto_atTop_ciSup hmono hbdd
      have hL1 : σc ≤ ⨆ n, g n := le_ciSup_of_le hbdd 0 (hI 0).1
      have hok := iv_ok S K r q T _ hT hL1
      have hCL := hfix _ hok hlim
      have hLpos : 0 < ⨆ n, g n := by
        rcases hok with h | hm
        · exact h
        · rcases (hc0.trans hL1).lt_or_eq with h | h
          · exact h
          · rw [← h, iv_call_zero S K r q T hS hK hT hm] at hCL; linarith
      have : (⨆ n, g n) = σs := hinj hLpos hσs (hCL.trans hCs.symm)
      rwa [this] at hlim
  refine ⟨σs, hσs, hCs, fun hle n => ?_, fun hge n => ?_, hlimit⟩
  · have hI := inv1 hle n
    rw [hgs]
    exact step1 (g n) hI.1 hI.2
  · have hI := inv2 hge n
    rw [hgs]
    exact step2 (g n) hI.1 hI.2

/-- **One quote, one volatility** (Step 0). With `S > 0`, `K > 0`, `T > 0` and a quote strictly
between the call's floor `max(S e^(-qT) - K e^(-rT), 0)` and its ceiling `S e^(-qT)`, exactly
one positive volatility gives the quote as its Black–Scholes call price. -/
theorem implied_volatility_exists_and_is_unique
    (S K r q T Cmkt : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T)
    (hfloor : max (S * exp (-(q * T)) - K * exp (-(r * T))) 0 < Cmkt)
    (hceil : Cmkt < S * exp (-(q * T))) :
    ∃! σ : ℝ, 0 < σ ∧ bsCall S K r q T σ = Cmkt := by
  obtain ⟨σ, hσ, hσeq⟩ := iv_exists S K r q T Cmkt hS hK hT hfloor hceil
  refine ⟨σ, ⟨hσ, hσeq⟩, fun τ hτ => ?_⟩
  exact (iv_call_strictMonoOn S K r q T hS hK hT).injOn hτ.1 hσ (hτ.2.trans hσeq.symm)

/-- **Vomma, and where vega peaks** (Step 2). For `S, K, T, σ > 0`: vega's slope against
volatility is `𝒱 d1 d2 / σ`; the product `d1 d2` equals `ln(F/K)² / (σ² T) - σ² T / 4`; and it
is at least zero exactly when `σ ≤ σ_c`, so vega rises up to `σ_c` and falls after it. -/
theorem vomma_eq_vega_d1_d2_div_sigma_and_sign_changes_at_peak
    (S K r q T σ : ℝ) (hS : 0 < S) (hK : 0 < K) (hT : 0 < T) (hσ : 0 < σ) :
    HasDerivAt (fun s : ℝ => bsVega S K r q T s)
        (bsVega S K r q T σ * bsD1 S K r q T σ * (bsD1 S K r q T σ - σ * √T) / σ) σ ∧
      bsD1 S K r q T σ * (bsD1 S K r q T σ - σ * √T) =
        log (S * exp ((r - q) * T) / K) ^ 2 / (σ ^ 2 * T) - σ ^ 2 * T / 4 ∧
      (0 ≤ bsD1 S K r q T σ * (bsD1 S K r q T σ - σ * √T) ↔ σ ≤ peakVegaStart S K r q T) := by
  exact ⟨iv_vega_hasDerivAt S K r q T σ hσ hT, iv_d1d2 S K r q T σ hS hK hT hσ,
    iv_d1d2_iff S K r q T σ hS hK hT hσ⟩

/-! The card's exact numbers for the house call: `S = K = 100`, `r = 5/100`, `q = 2/100`,
`T = 1`, answer `σ* = 1/5`. -/

-- ln(F/K) = (r - q) T = 0.03.
example : log (100 * exp ((5 / 100 - 2 / 100) * 1) / 100) = (3 / 100 : ℝ) := by
  norm_num [Real.log_exp]

-- σ_c² = 2 × 0.03 / 1 = 0.06, so σ_c = √0.06 = 0.244948974278…
example : 2 * |((5 : ℚ) / 100 - 2 / 100) * 1| / 1 = 6 / 100 := by norm_num

-- At the answer, d1 = 0.25.
example : bsD1 100 100 (5 / 100) (2 / 100) 1 (1 / 5) = 1 / 4 := by
  norm_num [bsD1]

-- d1 d2 = 0.25 × 0.05 = 0.0125 matches ln(F/K)²/(σ²T) - σ²T/4 = 0.0225 - 0.01.
example : (1 / 4 : ℚ) * (1 / 20) = (3 / 100) ^ 2 / ((1 / 5) ^ 2 * 1) - (1 / 5) ^ 2 * 1 / 4 := by
  norm_num

-- Bisection on the bracket 0.01 to 5.00 needs 43 halvings to get under 10^-12, not 42.
example : (499 / 100 : ℚ) / 2 ^ 43 ≤ 1 / 10 ^ 12 ∧ 1 / 10 ^ 12 < (499 / 100 : ℚ) / 2 ^ 42 := by
  norm_num

#print axioms newton_from_peak_vega_start_never_overshoots
#print axioms implied_volatility_exists_and_is_unique
#print axioms vomma_eq_vega_d1_d2_div_sigma_and_sign_changes_at_peak

end ImpliedVolNewtonBisection
