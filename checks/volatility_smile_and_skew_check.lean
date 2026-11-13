-- The volatility smile and skew: a market's implied volatility is the same at every strike exactly when its price distribution is one lognormal, every call priced strictly inside its no-arbitrage bounds has exactly one implied volatility, and a two-leg crash market obeys put-call parity exactly when its legs average to the forward.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib

open MeasureTheory ProbabilityTheory

/-- The lognormal law centred on the forward `F` with volatility `σ` over `T` years: the price
`F · exp(σ √T Z − σ² T / 2)` with `Z` a standard bell curve. Its average is `F`. -/
noncomputable def lognormalLaw (F σ T : ℝ) : Measure ℝ :=
  (gaussianReal 0 1).map (fun z => F * Real.exp (σ * Real.sqrt T * z - σ ^ 2 * T / 2))

/-- The call price at strike `K` in a market whose year-end price has law `μ`:
the discounted average payoff `e^{−rT} · E[max(S_T − K, 0)]`. -/
noncomputable def callPrice (r T K : ℝ) (μ : Measure ℝ) : ℝ :=
  Real.exp (-r * T) * ∫ x, max (x - K) 0 ∂μ

/-- The put price at strike `K`: the discounted average payoff `e^{−rT} · E[max(K − S_T, 0)]`. -/
noncomputable def putPrice (r T K : ℝ) (μ : Measure ℝ) : ℝ :=
  Real.exp (-r * T) * ∫ x, max (K - x) 0 ∂μ

/-- The Black-Scholes call `C_BS(K, σ)` on the forward `F`: the call price when the year-end
price is one lognormal centred on `F` with volatility `σ`. -/
noncomputable def bsCall (r T F σ K : ℝ) : ℝ :=
  callPrice r T K (lognormalLaw F σ T)

/-- The crash market: with chance `p` the year ends in the crash leg (a lognormal centred on
`Fc` with volatility `σc`), otherwise in the calm leg (centred on `Fn` with volatility `σn`). -/
noncomputable def crashMarket (p Fc σc Fn σn T : ℝ) : Measure ℝ :=
  ENNReal.ofReal p • lognormalLaw Fc σc T + ENNReal.ofReal (1 - p) • lognormalLaw Fn σn T

section VolSmileHelpers

open Filter Topology Set

lemma vs_cdf_eq (x : ℝ) :
    cdf (gaussianReal 0 1) x = ∫ t in Iic x, gaussianPDFReal 0 1 t := by
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ _))]

lemma vs_tail (x : ℝ) :
    ∫ t in Ioi x, gaussianPDFReal 0 1 t = 1 - cdf (gaussianReal 0 1) x := by
  have := integral_add_compl (measurableSet_Iic (a := x)) (integrable_gaussianPDFReal 0 1)
  rw [compl_Iic, integral_gaussianPDFReal_eq_one 0 one_ne_zero] at this
  rw [vs_cdf_eq]; linarith

lemma vs_pdf_cont : Continuous (gaussianPDFReal 0 1) := by
  unfold gaussianPDFReal; fun_prop

lemma vs_cdf_deriv (x : ℝ) :
    HasDerivAt (cdf (gaussianReal 0 1)) (gaussianPDFReal 0 1 x) x := by
  have hI : ∀ y, IntegrableOn (gaussianPDFReal 0 1) (Iic y) :=
    fun y => (integrable_gaussianPDFReal 0 1).integrableOn
  have heq : cdf (gaussianReal 0 1) = fun y => cdf (gaussianReal 0 1) 0 +
      ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y
    rw [← intervalIntegral.integral_Iic_sub_Iic (hI 0) (hI y), vs_cdf_eq, vs_cdf_eq]; ring
  rw [heq]
  exact ((vs_pdf_cont.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add _

lemma vs_pdf_shift (s z : ℝ) :
    gaussianPDFReal 0 1 z * Real.exp (s * z - s ^ 2 / 2) = gaussianPDFReal 0 1 (z - s) := by
  unfold gaussianPDFReal
  rw [mul_assoc, ← Real.exp_add]
  congr 2
  push_cast; ring

lemma vs_shift_integral (d s : ℝ) :
    ∫ z in Ioi d, gaussianPDFReal 0 1 (z - s) = ∫ z in Ioi (d - s), gaussianPDFReal 0 1 z := by
  rw [← integral_indicator measurableSet_Ioi, ← integral_indicator measurableSet_Ioi]
  have : (Ioi d).indicator (fun z => gaussianPDFReal 0 1 (z - s)) =
      fun z => (Ioi (d - s)).indicator (gaussianPDFReal 0 1) (z - s) := by
    funext z
    simp only [indicator, mem_Ioi]
    split_ifs with h1 h2 h2 <;> first | rfl | (exfalso; linarith)
  rw [this, integral_sub_right_eq_self (fun z => (Ioi (d - s)).indicator (gaussianPDFReal 0 1) z) s]

lemma vs_closed_form (F K s : ℝ) (hF : 0 < F) (hK : 0 < K) (hs : 0 < s) :
    ∫ z, max (F * Real.exp (s * z - s ^ 2 / 2) - K) 0 ∂(gaussianReal 0 1) =
      F * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s - s / 2)) -
        K * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s + s / 2)) := by
  set a := Real.log (K / F)
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  have key : ∀ z, a / s + s / 2 < z ↔ K < F * Real.exp (s * z - s ^ 2 / 2) := by
    intro z
    rw [show a / s + s / 2 = (a + s ^ 2 / 2) / s by field_simp, div_lt_iff₀ hs,
      ← div_lt_iff₀' hF, ← Real.log_lt_iff_lt_exp (div_pos hK hF)]
    constructor <;> intro h <;> linarith
  have hpt : (fun z => gaussianPDFReal 0 1 z • max (F * Real.exp (s * z - s ^ 2 / 2) - K) 0) =
      (Ioi (a / s + s / 2)).indicator
        (fun z => F * gaussianPDFReal 0 1 (z - s) - K * gaussianPDFReal 0 1 z) := by
    funext z
    simp only [indicator, mem_Ioi, smul_eq_mul]
    split_ifs with h
    · rw [max_eq_left (by linarith [(key z).1 h]), ← vs_pdf_shift s z]; ring
    · rw [max_eq_right (by linarith [show ¬ K < _ from fun h' => h ((key z).2 h')])]; ring
  rw [hpt, integral_indicator measurableSet_Ioi, integral_sub, integral_const_mul,
    integral_const_mul, vs_shift_integral, vs_tail, vs_tail]
  · ring_nf
  · exact (((integrable_gaussianPDFReal 0 1).comp_sub_right s).const_mul F).integrableOn
  · exact ((integrable_gaussianPDFReal 0 1).const_mul K).integrableOn

lemma vs_pdf_ratio (F K s : ℝ) (hF : 0 < F) (hK : 0 < K) (hs : 0 < s) :
    F * gaussianPDFReal 0 1 (Real.log (K / F) / s - s / 2) =
      K * gaussianPDFReal 0 1 (Real.log (K / F) / s + s / 2) := by
  unfold gaussianPDFReal
  have : -(Real.log (K / F) / s - s / 2 - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) =
      -(Real.log (K / F) / s + s / 2 - 0) ^ 2 / (2 * ((1 : NNReal) : ℝ)) + Real.log (K / F) := by
    push_cast; field_simp; ring
  rw [this, Real.exp_add, Real.exp_log (div_pos hK hF)]
  field_simp

lemma vs_H_deriv (F K s : ℝ) (hF : 0 < F) (hK : 0 < K) (hs : 0 < s) :
    HasDerivAt (fun s => F * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s - s / 2)) -
        K * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s + s / 2)))
      (K * gaussianPDFReal 0 1 (Real.log (K / F) / s + s / 2)) s := by
  have hr := vs_pdf_ratio F K s hF hK hs
  set a := Real.log (K / F)
  have hu : HasDerivAt (fun s => a / s - s / 2) (-a / s ^ 2 - 1 / 2) s := by
    have := ((hasDerivAt_inv hs.ne').const_mul a).sub ((hasDerivAt_id s).div_const 2)
    convert this using 1
    · funext x; simp [div_eq_mul_inv]
    · field_simp
  have hw : HasDerivAt (fun s => a / s + s / 2) (-a / s ^ 2 + 1 / 2) s := by
    have := ((hasDerivAt_inv hs.ne').const_mul a).add ((hasDerivAt_id s).div_const 2)
    convert this using 1
    · funext x; simp [div_eq_mul_inv]
    · field_simp
  have h1 := (vs_cdf_deriv (a / s - s / 2)).comp s hu
  have h2 := (vs_cdf_deriv (a / s + s / 2)).comp s hw
  have := (((hasDerivAt_const s (1:ℝ)).sub h1).const_mul F).sub
    (((hasDerivAt_const s (1:ℝ)).sub h2).const_mul K)
  convert this using 1
  · funext x; simp
  · linear_combination (-a / s ^ 2 - 1 / 2) * hr

lemma vs_H_strictMono (F K : ℝ) (hF : 0 < F) (hK : 0 < K) :
    StrictMonoOn (fun s => F * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s - s / 2)) -
        K * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s + s / 2))) (Ioi 0) := by
  apply strictMonoOn_of_deriv_pos (convex_Ioi 0)
  · intro x hx
    exact (vs_H_deriv F K x hF hK hx).continuousAt.continuousWithinAt
  · intro x hx
    rw [interior_Ioi] at hx
    rw [(vs_H_deriv F K x hF hK hx).deriv]
    exact mul_pos hK (gaussianPDFReal_pos _ _ _ one_ne_zero)

lemma vs_H_tendsto_of {l : Filter ℝ} (F K A B : ℝ) (u w : ℝ → ℝ)
    (hA : Tendsto (fun s => cdf (gaussianReal 0 1) (u s)) l (𝓝 A))
    (hB : Tendsto (fun s => cdf (gaussianReal 0 1) (w s)) l (𝓝 B)) :
    Tendsto (fun s => F * (1 - cdf (gaussianReal 0 1) (u s)) - K * (1 - cdf (gaussianReal 0 1) (w s)))
      l (𝓝 (F * (1 - A) - K * (1 - B))) :=
  ((tendsto_const_nhds.sub hA).const_mul F).sub ((tendsto_const_nhds.sub hB).const_mul K)

lemma vs_half_zero : Tendsto (fun s : ℝ => s / 2) (𝓝[>] 0) (𝓝 0) := by
  have : Tendsto (fun s : ℝ => s / 2) (𝓝 0) (𝓝 (0 / 2)) := (continuous_id.div_const 2).tendsto 0
  rw [zero_div] at this
  exact this.mono_left nhdsWithin_le_nhds

lemma vs_H_lim_zero (F K : ℝ) (hF : 0 < F) (hK : 0 < K) :
    Tendsto (fun s => F * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s - s / 2)) -
        K * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s + s / 2))) (𝓝[>] 0)
      (𝓝 (max (F - K) 0)) := by
  set a := Real.log (K / F) with ha_def
  have hKF : K / F = Real.exp a := (Real.exp_log (div_pos hK hF)).symm
  rcases lt_trichotomy a 0 with ha | ha | ha
  · have h1 : Tendsto (fun s => a / s) (𝓝[>] 0) atBot :=
      (tendsto_inv_nhdsGT_zero.const_mul_atTop_of_neg ha).congr (fun s => by ring)
    have hu : Tendsto (fun s => a / s - s / 2) (𝓝[>] 0) atBot :=
      (h1.atBot_add vs_half_zero.neg).congr (fun s => by ring)
    have hw : Tendsto (fun s => a / s + s / 2) (𝓝[>] 0) atBot :=
      (h1.atBot_add vs_half_zero).congr (fun s => by ring)
    have := vs_H_tendsto_of F K 0 0 _ _ (Tendsto.comp (tendsto_cdf_atBot (μ := gaussianReal 0 1)) hu) (Tendsto.comp (tendsto_cdf_atBot (μ := gaussianReal 0 1)) hw)
    have hlt : K < F := by
      have : K / F < 1 := by rw [hKF]; exact Real.exp_lt_one_iff.mpr ha
      rwa [div_lt_one hF] at this
    convert this using 2
    rw [max_eq_left (by linarith)]; ring
  · have hKF' : K = F := by
      rw [ha, Real.exp_zero, div_eq_one_iff_eq hF.ne'] at hKF; exact hKF
    have hu : Tendsto (fun s => a / s - s / 2) (𝓝[>] 0) (𝓝 0) := by
      have := vs_half_zero.neg; simp only [neg_zero] at this
      exact this.congr (fun s => by rw [ha]; ring)
    have hw : Tendsto (fun s => a / s + s / 2) (𝓝[>] 0) (𝓝 0) :=
      vs_half_zero.congr (fun s => by rw [ha]; ring)
    have hc := (vs_cdf_deriv 0).continuousAt
    have := vs_H_tendsto_of F K _ _ _ _ (hc.tendsto.comp hu) (hc.tendsto.comp hw)
    convert this using 2
    rw [hKF', sub_self, max_self]; ring
  · have h1 : Tendsto (fun s => a / s) (𝓝[>] 0) atTop :=
      (tendsto_inv_nhdsGT_zero.const_mul_atTop ha).congr (fun s => by ring)
    have hu : Tendsto (fun s => a / s - s / 2) (𝓝[>] 0) atTop :=
      (h1.atTop_add vs_half_zero.neg).congr (fun s => by ring)
    have hw : Tendsto (fun s => a / s + s / 2) (𝓝[>] 0) atTop :=
      (h1.atTop_add vs_half_zero).congr (fun s => by ring)
    have := vs_H_tendsto_of F K 1 1 _ _ (Tendsto.comp (tendsto_cdf_atTop (μ := gaussianReal 0 1)) hu) (Tendsto.comp (tendsto_cdf_atTop (μ := gaussianReal 0 1)) hw)
    have hlt : F < K := by
      have : 1 < K / F := by rw [hKF]; exact Real.one_lt_exp_iff.mpr ha
      rwa [one_lt_div hF] at this
    convert this using 2
    rw [max_eq_right (by linarith)]; ring

lemma vs_H_lim_top (F K : ℝ) :
    Tendsto (fun s => F * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s - s / 2)) -
        K * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s + s / 2))) atTop (𝓝 F) := by
  set a := Real.log (K / F)
  have h1 : Tendsto (fun s : ℝ => a / s) atTop (𝓝 0) := by
    have := tendsto_inv_atTop_zero.const_mul a
    rw [mul_zero] at this
    exact this.congr (fun s => by ring)
  have h2 : Tendsto (fun s : ℝ => s / 2) atTop atTop := tendsto_id.atTop_div_const (by norm_num)
  have hu : Tendsto (fun s => a / s - s / 2) atTop atBot :=
    (h1.add_atBot (tendsto_neg_atTop_atBot.comp h2)).congr (fun s => by simp; ring)
  have hw : Tendsto (fun s => a / s + s / 2) atTop atTop := h1.add_atTop h2
  have := vs_H_tendsto_of F K 0 1 _ _ (Tendsto.comp (tendsto_cdf_atBot (μ := gaussianReal 0 1)) hu) (Tendsto.comp (tendsto_cdf_atTop (μ := gaussianReal 0 1)) hw)
  convert this using 2; ring

lemma vs_ramp_bound (x K h : ℝ) (hh : 0 < h) :
    0 ≤ max (x - K) 0 - max (x - (K + h)) 0 ∧ max (x - K) 0 - max (x - (K + h)) 0 ≤ h := by
  constructor
  · have : max (x - (K + h)) 0 ≤ max (x - K) 0 := max_le_max (by linarith) le_rfl
    linarith
  · have : max (x - K) 0 ≤ max (x - (K + h)) 0 + h :=
      max_le (by linarith [le_max_left (x - (K + h)) 0]) (by linarith [le_max_right (x - (K + h)) 0])
    linarith

lemma vs_tail_limit (m : Measure ℝ) [IsProbabilityMeasure m] (K : ℝ)
    (hint : ∀ K', K ≤ K' → Integrable (fun x => max (x - K') 0) m) :
    Tendsto (fun n : ℕ => ((∫ x, max (x - K) 0 ∂m) -
        ∫ x, max (x - (K + 1 / ((n : ℝ) + 1))) 0 ∂m) * ((n : ℝ) + 1)) atTop
      (𝓝 (m.real (Ioi K))) := by
  have hpos : ∀ n : ℕ, (0 : ℝ) < 1 / ((n : ℝ) + 1) := fun n => by positivity
  have hrw : ∀ n : ℕ, ((∫ x, max (x - K) 0 ∂m) -
        ∫ x, max (x - (K + 1 / ((n : ℝ) + 1))) 0 ∂m) * ((n : ℝ) + 1) =
      ∫ x, (max (x - K) 0 - max (x - (K + 1 / ((n : ℝ) + 1))) 0) * ((n : ℝ) + 1) ∂m := by
    intro n
    rw [integral_mul_const, integral_sub (hint K le_rfl) (hint _ (by linarith [hpos n]))]
  simp_rw [hrw]
  rw [← integral_indicator_one measurableSet_Ioi]
  apply tendsto_integral_of_dominated_convergence (fun _ => 1)
  · intro n; exact (by fun_prop : Continuous fun x : ℝ =>
      (max (x - K) 0 - max (x - (K + 1 / ((n : ℝ) + 1))) 0) * ((n : ℝ) + 1)).aestronglyMeasurable
  · exact integrable_const 1
  · intro n
    refine ae_of_all _ (fun x => ?_)
    obtain ⟨h0, h1⟩ := vs_ramp_bound x K (1 / ((n : ℝ) + 1)) (hpos n)
    have hn : (0 : ℝ) < (n : ℝ) + 1 := by positivity
    rw [Real.norm_eq_abs, abs_of_nonneg (mul_nonneg h0 hn.le)]
    calc _ ≤ 1 / ((n : ℝ) + 1) * ((n : ℝ) + 1) := mul_le_mul_of_nonneg_right h1 hn.le
      _ = 1 := by field_simp
  · refine ae_of_all _ (fun x => ?_)
    by_cases hx : K < x
    · rw [indicator_of_mem (mem_Ioi.mpr hx)]
      obtain ⟨N, hN⟩ := exists_nat_one_div_lt (sub_pos.mpr hx)
      apply tendsto_const_nhds.congr'
      filter_upwards [eventually_ge_atTop N] with n hn
      have hle : 1 / ((n : ℝ) + 1) ≤ 1 / ((N : ℝ) + 1) := by
        apply one_div_le_one_div_of_le (by positivity); exact_mod_cast Nat.add_le_add_right hn 1
      rw [max_eq_left (by linarith), max_eq_left (by linarith)]
      rw [Pi.one_apply]
      field_simp
      ring
    · rw [indicator_of_notMem (by simpa using hx)]
      apply tendsto_const_nhds.congr'
      filter_upwards with n
      rw [max_eq_right (by linarith), max_eq_right (by linarith [hpos n])]
      simp

lemma vs_H_pos (F K s : ℝ) (hF : 0 < F) (hK : 0 < K) (hs : 0 < s) :
    max (F - K) 0 < F * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s - s / 2)) -
        K * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s + s / 2)) := by
  have hmono := vs_H_strictMono F K hF hK
  have hlt := hmono (show (0:ℝ) < s / 2 by positivity) hs (by linarith)
  refine lt_of_le_of_lt ?_ hlt
  apply le_of_tendsto (vs_H_lim_zero F K hF hK)
  filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < s / 2 by positivity)] with t ht
  exact hmono.monotoneOn ht.1 (show (0:ℝ) < s / 2 by positivity) ht.2.le

lemma vs_lognormal_meas (F σ T : ℝ) :
    Measurable (fun z : ℝ => F * Real.exp (σ * Real.sqrt T * z - σ ^ 2 * T / 2)) := by
  fun_prop

lemma vs_lognormal_prob (F σ T : ℝ) : IsProbabilityMeasure (lognormalLaw F σ T) :=
  (Measure.isProbabilityMeasure_map_iff (vs_lognormal_meas F σ T).aemeasurable).mpr inferInstance

lemma vs_lognormal_integral (F σ T K : ℝ) (hT : 0 < T) (hF : 0 < F) (hσ : 0 < σ) (hK : 0 < K) :
    ∫ x, max (x - K) 0 ∂(lognormalLaw F σ T) =
      F * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / (σ * Real.sqrt T) - σ * Real.sqrt T / 2)) -
        K * (1 - cdf (gaussianReal 0 1)
          (Real.log (K / F) / (σ * Real.sqrt T) + σ * Real.sqrt T / 2)) := by
  unfold lognormalLaw
  rw [integral_map (vs_lognormal_meas F σ T).aemeasurable
    (by fun_prop : Continuous fun x : ℝ => max (x - K) 0).aestronglyMeasurable]
  have hs2 : σ ^ 2 * T = (σ * Real.sqrt T) ^ 2 := by rw [mul_pow, Real.sq_sqrt hT.le]
  simp_rw [hs2]
  have hsT : 0 < σ * Real.sqrt T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  exact vs_closed_form F K (σ * Real.sqrt T) hF hK hsT

lemma vs_lognormal_fun (F σ T : ℝ) :
    (fun z : ℝ => F * Real.exp (σ * Real.sqrt T * z - σ ^ 2 * T / 2)) =
      fun z => F * Real.exp (-(σ ^ 2 * T / 2)) * Real.exp (σ * Real.sqrt T * z) := by
  funext z
  rw [mul_assoc F (Real.exp _), ← Real.exp_add]; congr 2; ring

lemma vs_lognormal_integrable (F σ T : ℝ) : Integrable (fun x : ℝ => x) (lognormalLaw F σ T) := by
  unfold lognormalLaw
  rw [integrable_map_measure (by fun_prop : Continuous fun x : ℝ => x).aestronglyMeasurable
    (vs_lognormal_meas F σ T).aemeasurable]
  show Integrable (fun z : ℝ => F * Real.exp (σ * Real.sqrt T * z - σ ^ 2 * T / 2)) _
  rw [vs_lognormal_fun]
  exact (integrable_exp_mul_gaussianReal _).const_mul _

lemma vs_lognormal_mean (F σ T : ℝ) (hT : 0 ≤ T) : ∫ x, x ∂(lognormalLaw F σ T) = F := by
  unfold lognormalLaw
  rw [integral_map (vs_lognormal_meas F σ T).aemeasurable
    (by fun_prop : Continuous fun x : ℝ => x).aestronglyMeasurable, vs_lognormal_fun,
    integral_const_mul]
  have hm := congrFun (mgf_id_gaussianReal (μ := 0) (v := 1)) (σ * Real.sqrt T)
  simp only [mgf, id] at hm
  rw [hm, mul_assoc, ← Real.exp_add, mul_pow, Real.sq_sqrt hT]
  push_cast
  ring_nf
  simp

lemma vs_parity_general (r T K : ℝ) (m : Measure ℝ) [IsProbabilityMeasure m]
    (hm : Integrable (fun x : ℝ => x) m) :
    callPrice r T K m - putPrice r T K m = Real.exp (-r * T) * ((∫ x, x ∂m) - K) := by
  unfold callPrice putPrice
  have h1 : Integrable (fun x : ℝ => max (x - K) 0) m := (hm.sub (integrable_const K)).pos_part
  have h2 : Integrable (fun x : ℝ => max (K - x) 0) m := ((integrable_const K).sub hm).pos_part
  rw [← mul_sub, ← integral_sub h1 h2]
  have hpt : (fun x : ℝ => max (x - K) 0 - max (K - x) 0) = fun x => x - K := by
    funext x
    rcases le_total x K with h | h
    · rw [max_eq_right (by linarith), max_eq_left (by linarith)]; ring
    · rw [max_eq_left (by linarith), max_eq_right (by linarith)]; ring
  rw [hpt, integral_sub hm (integrable_const K), integral_const]
  simp

lemma vs_thm1 (r T F σ : ℝ) (hT : 0 < T) (hF : 0 < F) (hσ : 0 < σ)
    (μ : Measure ℝ) [IsProbabilityMeasure μ] :
    (∀ K : ℝ, 0 < K → callPrice r T K μ = bsCall r T F σ K) ↔ μ = lognormalLaw F σ T := by
  constructor
  swap
  · rintro rfl K _; rfl
  intro h
  have := vs_lognormal_prob F σ T
  set ν := lognormalLaw F σ T with hν
  have hE := Real.exp_pos (-r * T)
  have hsT : 0 < σ * Real.sqrt T := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have heq : ∀ K, 0 < K → ∫ x, max (x - K) 0 ∂μ = ∫ x, max (x - K) 0 ∂ν := by
    intro K hK
    have := h K hK
    unfold callPrice bsCall at this
    exact mul_left_cancel₀ hE.ne' this
  have hνint : ∀ K, Integrable (fun x : ℝ => max (x - K) 0) ν := fun K =>
    ((vs_lognormal_integrable F σ T).sub (integrable_const K)).pos_part
  have hμint : ∀ K, 0 < K → Integrable (fun x : ℝ => max (x - K) 0) μ := by
    intro K hK
    by_contra hn
    have h0 := integral_undef hn
    rw [heq K hK, hν, vs_lognormal_integral F σ T K hT hF hσ hK] at h0
    have := vs_H_pos F K _ hF hK hsT
    linarith [le_max_right (F - K) 0]
  have htail : ∀ K, 0 < K → μ (Ioi K) = ν (Ioi K) := by
    intro K hK
    have h1 := vs_tail_limit μ K (fun K' hK' => hμint K' (by linarith))
    have h2 := vs_tail_limit ν K (fun K' _ => hνint K')
    have h3 : μ.real (Ioi K) = ν.real (Ioi K) := by
      refine tendsto_nhds_unique h1 ?_
      convert h2 using 2 with n
      rw [heq K hK, heq _ (by positivity)]
    rw [measureReal_def, measureReal_def] at h3
    exact (ENNReal.toReal_eq_toReal_iff' (measure_ne_top _ _) (measure_ne_top _ _)).mp h3
  have hν0 : ν (Ioi 0) = 1 := by
    rw [hν, lognormalLaw, Measure.map_apply (vs_lognormal_meas F σ T) measurableSet_Ioi]
    have : (fun z : ℝ => F * Real.exp (σ * Real.sqrt T * z - σ ^ 2 * T / 2)) ⁻¹' Ioi 0 = univ := by
      ext z; simp only [mem_preimage, mem_Ioi, mem_univ, iff_true]; positivity
    rw [this, measure_univ]
  have hμ0 : μ (Ioi 0) = 1 := by
    have hU : (⋃ n : ℕ, Ioi (1 / ((n : ℝ) + 1))) = Ioi 0 := by
      ext x; simp only [mem_iUnion, mem_Ioi]
      constructor
      · rintro ⟨n, hn⟩; exact lt_trans (by positivity) hn
      · intro hx; obtain ⟨n, hn⟩ := exists_nat_one_div_lt hx; exact ⟨n, hn⟩
    have hmono : Monotone (fun n : ℕ => Ioi (1 / ((n : ℝ) + 1))) := by
      intro a b hab; apply Ioi_subset_Ioi
      apply one_div_le_one_div_of_le (by positivity); exact_mod_cast Nat.add_le_add_right hab 1
    have h1 := tendsto_measure_iUnion_atTop (μ := μ) hmono
    have h2 := tendsto_measure_iUnion_atTop (μ := ν) hmono
    rw [hU] at h1 h2
    rw [← hν0]
    refine tendsto_nhds_unique h1 ?_
    convert h2 using 1
    funext n
    exact htail _ (by positivity)
  have hall : ∀ a, μ (Ioi a) = ν (Ioi a) := by
    intro a
    rcases lt_or_ge 0 a with ha | ha
    · exact htail a ha
    · have e1 : μ (Ioi a) = 1 := le_antisymm prob_le_one (hμ0 ▸ measure_mono (Ioi_subset_Ioi ha))
      have e2 : ν (Ioi a) = 1 := le_antisymm prob_le_one (hν0 ▸ measure_mono (Ioi_subset_Ioi ha))
      rw [e1, e2]
  refine Measure.ext_of_Iic μ ν (fun a => ?_)
  rw [← compl_Ioi, prob_compl_eq_one_sub measurableSet_Ioi,
    prob_compl_eq_one_sub measurableSet_Ioi, hall a]

lemma vs_thm2 (r T F K c : ℝ) (hT : 0 < T) (hF : 0 < F)
    (hK : 0 < K) (hlo : Real.exp (-r * T) * max (F - K) 0 < c)
    (hhi : c < Real.exp (-r * T) * F) :
    ∃! σ : ℝ, 0 < σ ∧ bsCall r T F σ K = c := by
  obtain ⟨H, hH⟩ : ∃ H : ℝ → ℝ, H = fun s =>
      F * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s - s / 2)) -
        K * (1 - cdf (gaussianReal 0 1) (Real.log (K / F) / s + s / 2)) := ⟨_, rfl⟩
  have hmono : StrictMonoOn H (Ioi 0) := by rw [hH]; exact vs_H_strictMono F K hF hK
  have hlim0 : Tendsto H (𝓝[>] 0) (𝓝 (max (F - K) 0)) := by rw [hH]; exact vs_H_lim_zero F K hF hK
  have hlimT : Tendsto H atTop (𝓝 F) := by rw [hH]; exact vs_H_lim_top F K
  have hcont : ContinuousOn H (Ioi 0) := by
    intro x hx; rw [hH]; exact (vs_H_deriv F K x hF hK hx).continuousAt.continuousWithinAt
  have hE := Real.exp_pos (-r * T)
  have hsT : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hbs : ∀ σ, 0 < σ → bsCall r T F σ K = Real.exp (-r * T) * H (σ * Real.sqrt T) := by
    intro σ hσ; unfold bsCall callPrice; rw [vs_lognormal_integral F σ T K hT hF hσ hK, hH]
  set y := c / Real.exp (-r * T) with hy
  have hlo' : max (F - K) 0 < y := by rw [hy, lt_div_iff₀ hE, mul_comm]; exact hlo
  have hhi' : y < F := by rw [hy, div_lt_iff₀ hE, mul_comm]; exact hhi
  obtain ⟨s0, hs0pos, hs0⟩ : ∃ s0, 0 < s0 ∧ H s0 < y := by
    have h1 := hlim0.eventually (gt_mem_nhds hlo')
    have h2 : ∀ᶠ t in 𝓝[>] (0:ℝ), 0 < t := self_mem_nhdsWithin
    obtain ⟨t, ht1, ht2⟩ := (h1.and h2).exists
    exact ⟨t, ht2, ht1⟩
  obtain ⟨s1, hs01, hs1⟩ : ∃ s1, s0 ≤ s1 ∧ y < H s1 := by
    obtain ⟨t, ht1, ht2⟩ :=
      ((hlimT.eventually (lt_mem_nhds hhi')).and (eventually_ge_atTop s0)).exists
    exact ⟨t, ht2, ht1⟩
  have hcont' : ContinuousOn H (Icc s0 s1) :=
    hcont.mono (fun x hx => lt_of_lt_of_le hs0pos hx.1)
  obtain ⟨s, hs, hHs⟩ := intermediate_value_Icc hs01 hcont' ⟨hs0.le, hs1.le⟩
  have hspos : 0 < s := lt_of_lt_of_le hs0pos hs.1
  refine ⟨s / Real.sqrt T, ⟨div_pos hspos hsT, ?_⟩, ?_⟩
  · rw [hbs _ (div_pos hspos hsT), div_mul_cancel₀ s hsT.ne', hHs, hy]
    field_simp
  · rintro σ ⟨hσ, hσc⟩
    rw [hbs σ hσ] at hσc
    have heqH : H (σ * Real.sqrt T) = H s := by
      rw [hHs, hy, ← hσc]; field_simp
    have := hmono.injOn (show σ * Real.sqrt T ∈ Ioi 0 from mul_pos hσ hsT) hspos heqH
    rw [← this]; field_simp

lemma vs_thm3 (r T F p Fc σc Fn σn : ℝ)
    (hT : 0 < T) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    (∀ K : ℝ, 0 < K →
      callPrice r T K (crashMarket p Fc σc Fn σn T) - putPrice r T K (crashMarket p Fc σc Fn σn T)
        = Real.exp (-r * T) * (F - K)) ↔
      p * Fc + (1 - p) * Fn = F := by
  have hp1' : 0 ≤ 1 - p := by linarith
  have : IsProbabilityMeasure (crashMarket p Fc σc Fn σn T) := by
    have := vs_lognormal_prob Fc σc T
    have := vs_lognormal_prob Fn σn T
    constructor
    simp only [crashMarket, Measure.add_apply, Measure.smul_apply, measure_univ, smul_eq_mul,
      mul_one]
    rw [← ENNReal.ofReal_add hp0 hp1']; simp
  have hc := (vs_lognormal_integrable Fc σc T).smul_measure (ENNReal.ofReal_ne_top (r := p))
  have hn := (vs_lognormal_integrable Fn σn T).smul_measure (ENNReal.ofReal_ne_top (r := 1 - p))
  have hint : Integrable (fun x : ℝ => x) (crashMarket p Fc σc Fn σn T) := hc.add_measure hn
  have hmean : ∫ x, x ∂(crashMarket p Fc σc Fn σn T) = p * Fc + (1 - p) * Fn := by
    unfold crashMarket
    rw [integral_add_measure hc hn, integral_smul_measure, integral_smul_measure,
      vs_lognormal_mean _ _ _ hT.le, vs_lognormal_mean _ _ _ hT.le, ENNReal.toReal_ofReal hp0,
      ENNReal.toReal_ofReal hp1']
    simp [smul_eq_mul]
  have hE : 0 < Real.exp (-r * T) := Real.exp_pos _
  constructor
  · intro h
    have h1 := h 1 one_pos
    rw [vs_parity_general r T 1 _ hint, hmean] at h1
    have := mul_left_cancel₀ hE.ne' h1
    linarith
  · intro h K _
    rw [vs_parity_general r T K _ hint, hmean, h]

end VolSmileHelpers

/-- The smile is flat only for one lognormal. Take any market whose year-end price has the
probability law `μ`. Its implied volatility equals the same number `σ` at every positive strike
(every market call equals the Black-Scholes call at `σ`) exactly when the market's
distribution is the one lognormal centred on the forward `F` with volatility `σ`.
So any other distribution, such as the crash market, shows a smile or a skew. -/
theorem flat_smile_iff_lognormal (r T F σ : ℝ) (hT : 0 < T) (hF : 0 < F) (hσ : 0 < σ)
    (μ : Measure ℝ) [IsProbabilityMeasure μ] :
    (∀ K : ℝ, 0 < K → callPrice r T K μ = bsCall r T F σ K) ↔ μ = lognormalLaw F σ T := by
  exact vs_thm1 r T F σ hT hF hσ μ

/-- Every strike has exactly one implied volatility. A call priced strictly above its lower
bound `e^{−rT} max(F − K, 0)` and strictly below its upper bound `e^{−rT} F` is reproduced by
the Black-Scholes call at exactly one positive volatility. -/
theorem implied_volatility_exists_unique (r T F K c : ℝ) (hT : 0 < T) (hF : 0 < F)
    (hK : 0 < K) (hlo : Real.exp (-r * T) * max (F - K) 0 < c)
    (hhi : c < Real.exp (-r * T) * F) :
    ∃! σ : ℝ, 0 < σ ∧ bsCall r T F σ K = c := by
  exact vs_thm2 r T F K c hT hF hK hlo hhi

/-- The crash market obeys put-call parity, `C(K) − P(K) = e^{−rT}(F − K)` at every positive
strike, exactly when its two legs average to the forward: `p · Fc + (1 − p) · Fn = F`. -/
theorem crash_market_parity_iff_legs_average_to_forward (r T F p Fc σc Fn σn : ℝ)
    (hT : 0 < T) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    (∀ K : ℝ, 0 < K →
      callPrice r T K (crashMarket p Fc σc Fn σn T) - putPrice r T K (crashMarket p Fc σc Fn σn T)
        = Real.exp (-r * T) * (F - K)) ↔
      p * Fc + (1 - p) * Fn = F := by
  exact vs_thm3 r T F p Fc σc Fn σn hT hp0 hp1

/-- The card's strip: nine strikes, from $80 to $120 in $5 steps. -/
example : (Finset.range 9).image (fun i => 80 + 5 * i) = {80, 85, 90, 95, 100, 105, 110, 115, 120} := by
  decide

example : ((Finset.range 9).image (fun i => 80 + 5 * i)).card = 9 := by
  decide

#print axioms flat_smile_iff_lognormal
#print axioms implied_volatility_exists_unique
#print axioms crash_market_parity_iff_legs_average_to_forward
#print axioms vs_cdf_eq
#print axioms vs_tail
#print axioms vs_pdf_cont
#print axioms vs_cdf_deriv
#print axioms vs_pdf_shift
#print axioms vs_shift_integral
#print axioms vs_closed_form
#print axioms vs_pdf_ratio
#print axioms vs_H_deriv
#print axioms vs_H_strictMono
#print axioms vs_H_tendsto_of
#print axioms vs_half_zero
#print axioms vs_H_lim_zero
#print axioms vs_H_lim_top
#print axioms vs_ramp_bound
#print axioms vs_tail_limit
#print axioms vs_H_pos
#print axioms vs_lognormal_meas
#print axioms vs_lognormal_prob
#print axioms vs_lognormal_integral
#print axioms vs_lognormal_fun
#print axioms vs_lognormal_integrable
#print axioms vs_lognormal_mean
#print axioms vs_parity_general
#print axioms vs_thm1
#print axioms vs_thm2
#print axioms vs_thm3
