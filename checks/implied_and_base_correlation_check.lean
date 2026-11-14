-- Implied correlation: in the large-pool one-factor Gaussian copula a first-loss slice's expected loss falls strictly with correlation, so its quote has exactly one implied correlation when it lies strictly inside the end values, while a mezzanine slice's expected loss rises to a single peak at ρ* = 1 - ((b_A + b_B)/(2c))² and then falls, so a quote under the peak and above both ends has exactly two.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib

namespace ImpliedAndBaseCorrelation

open Real ProbabilityTheory MeasureTheory Set

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def stdNormalCDF (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `φ(x)`: the bell curve's height at `x`, the standard normal density. -/
noncomputable def stdNormalPDF (x : ℝ) : ℝ := gaussianPDFReal 0 1 x

/-- Vasicek's large-pool loss once the market factor is `x`, as a fraction of the pool:
`L = g N((c - √ρ x)/√(1 - ρ))`, with loss given default `g`, default threshold `c = N⁻¹(p)`
and asset correlation `ρ`. -/
noncomputable def poolLoss (g c ρ x : ℝ) : ℝ :=
  g * stdNormalCDF ((c - √ρ * x) / √(1 - ρ))

/-- `H_ρ(K) = E[min(L, K)]`: the expected loss of the first-loss slice from 0 to `K`, in pool
units, averaged over a standard-normal market factor. -/
noncomputable def firstLossEL (g c K ρ : ℝ) : ℝ :=
  ∫ x, min (poolLoss g c ρ x) K ∂(gaussianReal 0 1)

/-- `EL_{A,B}(ρ) = (H_ρ(B) - H_ρ(A))/(B - A)`: the expected loss of the tranche from `A` to `B`,
as a share of its own width. -/
noncomputable def trancheEL (g c A B ρ : ℝ) : ℝ :=
  (firstLossEL g c B ρ - firstLossEL g c A ρ) / (B - A)

/-- `z_K = (c - √(1 - ρ) b_K)/√ρ`: the market factor value at which pool loss equals `K`,
where `b_K = N⁻¹(K/g)`. -/
noncomputable def marketCut (c b ρ : ℝ) : ℝ :=
  (c - √(1 - ρ) * b) / √ρ

/-- `ρ* = 1 - ((b_A + b_B)/(2c))²`: the correlation at which the mezzanine's expected loss peaks. -/
noncomputable def peakCorrelation (c bA bB : ℝ) : ℝ :=
  1 - ((bA + bB) / (2 * c)) ^ 2

section Helpers
open Filter Topology

lemma stdNormalPDF_eq (x : ℝ) : stdNormalPDF x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [stdNormalPDF, gaussianPDFReal]

lemma stdNormalPDF_fun : stdNormalPDF = fun x => (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) :=
  funext stdNormalPDF_eq

lemma stdNormalPDF_pos (x : ℝ) : 0 < stdNormalPDF x :=
  gaussianPDFReal_pos _ _ _ one_ne_zero

lemma stdNormalPDF_le_one (x : ℝ) : stdNormalPDF x ≤ 1 := by
  rw [stdNormalPDF_eq]
  have h1 : (√(2 * π))⁻¹ ≤ 1 := by
    apply inv_le_one_of_one_le₀
    rw [Real.one_le_sqrt]; linarith [pi_gt_three]
  have h2 : exp (-x ^ 2 / 2) ≤ 1 := exp_le_one_iff.mpr (by nlinarith [sq_nonneg x])
  calc _ ≤ 1 * 1 := mul_le_mul h1 h2 (exp_pos _).le zero_le_one
    _ = 1 := by ring

lemma continuous_stdNormalPDF : Continuous stdNormalPDF := by
  rw [stdNormalPDF_fun]; fun_prop

lemma hasDerivAt_stdNormalPDF (x : ℝ) : HasDerivAt stdNormalPDF (-x * stdNormalPDF x) x := by
  rw [stdNormalPDF_fun]
  have h1 : HasDerivAt (fun y : ℝ => -y ^ 2 / 2) (-x) x := by
    have := (hasDerivAt_pow 2 x).const_mul (-1 / 2 : ℝ)
    convert this using 1
    · funext y; ring
    · simp; ring
  have h := h1.exp.const_mul (√(2 * π))⁻¹
  convert h using 1; ring

lemma integrable_stdNormalPDF : Integrable stdNormalPDF :=
  integrable_gaussianPDFReal 0 1

lemma stdNormalCDF_eq_integral (x : ℝ) : stdNormalCDF x = ∫ t in Iic x, stdNormalPDF t := by
  rw [stdNormalCDF, cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg measurableSet_Iic
      (fun t _ => gaussianPDFReal_nonneg _ _ _))]
  rfl

lemma stdNormalCDF_eq_add (x : ℝ) :
    stdNormalCDF x = stdNormalCDF 0 + ∫ t in (0 : ℝ)..x, stdNormalPDF t := by
  rw [stdNormalCDF_eq_integral, stdNormalCDF_eq_integral,
    ← intervalIntegral.integral_Iic_sub_Iic integrable_stdNormalPDF.integrableOn
      integrable_stdNormalPDF.integrableOn]
  ring

lemma hasDerivAt_stdNormalCDF (x : ℝ) : HasDerivAt stdNormalCDF (stdNormalPDF x) x := by
  have h := ((continuous_stdNormalPDF.integral_hasStrictDerivAt 0 x).hasDerivAt).const_add
    (stdNormalCDF 0)
  have e : stdNormalCDF = fun x => stdNormalCDF 0 + ∫ t in (0 : ℝ)..x, stdNormalPDF t :=
    funext stdNormalCDF_eq_add
  rw [e]; exact h

lemma continuous_stdNormalCDF : Continuous stdNormalCDF :=
  continuous_iff_continuousAt.mpr fun x => (hasDerivAt_stdNormalCDF x).continuousAt

lemma strictMono_stdNormalCDF : StrictMono stdNormalCDF :=
  strictMono_of_hasDerivAt_pos hasDerivAt_stdNormalCDF stdNormalPDF_pos

lemma stdNormalCDF_nonneg (x : ℝ) : 0 ≤ stdNormalCDF x := cdf_nonneg _ _

lemma stdNormalCDF_le_one (x : ℝ) : stdNormalCDF x ≤ 1 := cdf_le_one _ _

lemma tendsto_stdNormalCDF_atTop : Tendsto stdNormalCDF atTop (𝓝 1) := tendsto_cdf_atTop _

lemma tendsto_stdNormalCDF_atBot : Tendsto stdNormalCDF atBot (𝓝 0) := tendsto_cdf_atBot _

lemma exists_stdNormalCDF_eq {y : ℝ} (h0 : 0 < y) (h1 : y < 1) : ∃ b, stdNormalCDF b = y := by
  have hlo : ∃ a, stdNormalCDF a ≤ y :=
    (tendsto_stdNormalCDF_atBot.eventually (gt_mem_nhds h0)).exists.imp fun _ h => h.le
  have hhi : ∃ a, y ≤ stdNormalCDF a :=
    (tendsto_stdNormalCDF_atTop.eventually (lt_mem_nhds h1)).exists.imp fun _ h => h.le
  exact mem_range_of_exists_le_of_exists_ge continuous_stdNormalCDF hlo hhi

lemma pdf_mul_pdf_marketCut (c b ρ : ℝ) (h0 : 0 < ρ) (h1 : ρ < 1) :
    stdNormalPDF b * stdNormalPDF (marketCut c b ρ) =
      (2 * π)⁻¹ * exp (-(b ^ 2 - 2 * c * √(1 - ρ) * b + c ^ 2) / (2 * ρ)) := by
  have hr : 0 < √ρ := Real.sqrt_pos.mpr h0
  have hr2 : √ρ ^ 2 = ρ := Real.sq_sqrt h0.le
  have hs2 : √(1 - ρ) ^ 2 = 1 - ρ := Real.sq_sqrt (by linarith)
  rw [stdNormalPDF_eq, stdNormalPDF_eq, marketCut]
  have e1 : (√(2 * π))⁻¹ * (√(2 * π))⁻¹ = (2 * π)⁻¹ := by
    rw [← mul_inv, Real.mul_self_sqrt (by positivity)]
  have e2 : -b ^ 2 / 2 + -((c - √(1 - ρ) * b) / √ρ) ^ 2 / 2 =
      -(b ^ 2 - 2 * c * √(1 - ρ) * b + c ^ 2) / (2 * ρ) := by
    rw [div_pow, hr2]
    field_simp
    linear_combination (-b ^ 2) * hs2
  calc _ = ((√(2 * π))⁻¹ * (√(2 * π))⁻¹) *
        exp (-b ^ 2 / 2 + -((c - √(1 - ρ) * b) / √ρ) ^ 2 / 2) := by rw [exp_add]; ring
    _ = _ := by rw [e1, e2]

lemma pdf_prod_lt_iff (c x y ρ : ℝ) (h0 : 0 < ρ) (h1 : ρ < 1) :
    stdNormalPDF x * stdNormalPDF (marketCut c x ρ) <
        stdNormalPDF y * stdNormalPDF (marketCut c y ρ) ↔
      y ^ 2 - 2 * c * √(1 - ρ) * y < x ^ 2 - 2 * c * √(1 - ρ) * x := by
  rw [pdf_mul_pdf_marketCut c x ρ h0 h1, pdf_mul_pdf_marketCut c y ρ h0 h1,
    mul_lt_mul_iff_right₀ (by positivity), exp_lt_exp,
    div_lt_div_iff_of_pos_right (by positivity), neg_lt_neg_iff]
  constructor <;> intro h <;> linarith

lemma hasDerivAt_arg (c x ρ : ℝ) (h0 : 0 < ρ) (h1 : ρ < 1) :
    HasDerivAt (fun ρ => (c - √ρ * x) / √(1 - ρ))
      ((√ρ * c - x) / (2 * √ρ * √(1 - ρ) ^ 3)) ρ := by
  have hr : 0 < √ρ := Real.sqrt_pos.mpr h0
  have hs : 0 < √(1 - ρ) := Real.sqrt_pos.mpr (by linarith)
  have hr2 : √ρ ^ 2 = ρ := Real.sq_sqrt h0.le
  have hs2 : √(1 - ρ) ^ 2 = 1 - ρ := Real.sq_sqrt (by linarith)
  have d1 : HasDerivAt (fun ρ => √ρ) (1 / (2 * √ρ)) ρ := Real.hasDerivAt_sqrt h0.ne'
  have d2 : HasDerivAt (fun ρ => √(1 - ρ)) (-1 / (2 * √(1 - ρ))) ρ := by
    have := ((hasDerivAt_id ρ).const_sub 1).sqrt (by simp; linarith)
    simpa using this
  have d := ((d1.mul_const x).const_sub c).div d2 hs.ne'
  convert d using 1
  field_simp
  linear_combination x * hr2 + x * hs2

lemma hasDerivAt_poolLoss (g c x ρ : ℝ) (h0 : 0 < ρ) (h1 : ρ < 1) :
    HasDerivAt (fun ρ => poolLoss g c ρ x)
      (g * (stdNormalPDF ((c - √ρ * x) / √(1 - ρ)) *
        ((√ρ * c - x) / (2 * √ρ * √(1 - ρ) ^ 3)))) ρ :=
  ((hasDerivAt_stdNormalCDF _).comp ρ (hasDerivAt_arg c x ρ h0 h1)).const_mul g

lemma arg_lt_iff (c b ρ x : ℝ) (h0 : 0 < ρ) (h1 : ρ < 1) :
    (c - √ρ * x) / √(1 - ρ) < b ↔ marketCut c b ρ < x := by
  have hr : 0 < √ρ := Real.sqrt_pos.mpr h0
  have hs : 0 < √(1 - ρ) := Real.sqrt_pos.mpr (by linarith)
  rw [marketCut, div_lt_iff₀ hs, div_lt_iff₀ hr]
  constructor <;> intro h <;> linarith

lemma lt_arg_iff (c b ρ x : ℝ) (h0 : 0 < ρ) (h1 : ρ < 1) :
    b < (c - √ρ * x) / √(1 - ρ) ↔ x < marketCut c b ρ := by
  have hr : 0 < √ρ := Real.sqrt_pos.mpr h0
  have hs : 0 < √(1 - ρ) := Real.sqrt_pos.mpr (by linarith)
  rw [marketCut, lt_div_iff₀ hs, lt_div_iff₀ hr]
  constructor <;> intro h <;> linarith

lemma arg_marketCut (c b ρ : ℝ) (h0 : 0 < ρ) (h1 : ρ < 1) :
    (c - √ρ * marketCut c b ρ) / √(1 - ρ) = b := by
  have hr : 0 < √ρ := Real.sqrt_pos.mpr h0
  have hs : 0 < √(1 - ρ) := Real.sqrt_pos.mpr (by linarith)
  rw [marketCut]; field_simp; ring

lemma tendsto_stdNormalPDF_atTop : Tendsto stdNormalPDF atTop (𝓝 0) := by
  rw [stdNormalPDF_fun]
  have h : Tendsto (fun x : ℝ => -x ^ 2 / 2) atTop atBot :=
    (tendsto_neg_atTop_atBot.comp (tendsto_pow_atTop two_ne_zero)).atBot_div_const two_pos
  simpa using (Real.tendsto_exp_atBot.comp h).const_mul (√(2 * π))⁻¹

lemma integrable_abs_mul_stdNormalPDF : Integrable (fun x => |x| * stdNormalPDF x) := by
  have := ((integrable_mul_exp_neg_mul_sq (by norm_num : (0 : ℝ) < 1 / 2)).norm).const_mul
    (√(2 * π))⁻¹
  refine this.congr (ae_of_all _ fun x => ?_)
  simp only [stdNormalPDF_eq, norm_mul, Real.norm_eq_abs, abs_of_pos (exp_pos _)]
  ring_nf

lemma integrable_abs_id_gaussian : Integrable (fun x : ℝ => |x|) (gaussianReal 0 1) :=
  ((memLp_id_gaussianReal 1).integrable le_rfl).abs

lemma hasDerivAt_firstLossEL (g c b ρ₀ : ℝ) (hg : 0 < g) (h0 : 0 < ρ₀) (h1 : ρ₀ < 1) :
    HasDerivAt (firstLossEL g c (g * stdNormalCDF b))
      (-(g / (2 * √ρ₀ * √(1 - ρ₀))) *
        (stdNormalPDF b * stdNormalPDF (marketCut c b ρ₀))) ρ₀ := by
  have : NullSingletonClass (gaussianReal 0 1) := nullSingletonClass_gaussianReal one_ne_zero
  set K := g * stdNormalCDF b with hK
  have hK0 : 0 ≤ K := mul_nonneg hg.le (stdNormalCDF_nonneg b)
  set z := marketCut c b ρ₀ with hz
  have harg : (c - √ρ₀ * z) / √(1 - ρ₀) = b := arg_marketCut c b ρ₀ h0 h1
  have hr : 0 < √ρ₀ := Real.sqrt_pos.mpr h0
  have hs : 0 < √(1 - ρ₀) := Real.sqrt_pos.mpr (by linarith)
  have hr2 : √ρ₀ ^ 2 = ρ₀ := Real.sq_sqrt h0.le
  have hs2 : √(1 - ρ₀) ^ 2 = 1 - ρ₀ := Real.sq_sqrt (by linarith)
  set h : ℝ → ℝ := fun x => g * (stdNormalPDF ((c - √ρ₀ * x) / √(1 - ρ₀)) *
        ((√ρ₀ * c - x) / (2 * √ρ₀ * √(1 - ρ₀) ^ 3))) with hh
  have hcont_h : Continuous h := by
    rw [hh]; have := continuous_stdNormalPDF; fun_prop
  set F' : ℝ → ℝ := (Ioi z).indicator h with hF'
  set ε := min ρ₀ (1 - ρ₀) / 2 with hε
  have hεpos : 0 < ε := by
    have : 0 < min ρ₀ (1 - ρ₀) := lt_min h0 (by linarith)
    positivity
  have hball : ∀ ρ ∈ Metric.ball ρ₀ ε, ρ₀ / 2 < ρ ∧ (1 - ρ₀) / 2 < 1 - ρ := by
    intro ρ hρ
    rw [Metric.mem_ball, Real.dist_eq, abs_lt] at hρ
    have := min_le_left ρ₀ (1 - ρ₀); have := min_le_right ρ₀ (1 - ρ₀)
    constructor <;> linarith
  set D := 2 * (ρ₀ / 2) * ((1 - ρ₀) / 2) ^ 2 with hD
  have hDpos : 0 < D := by
    have : 0 < 1 - ρ₀ := by linarith
    positivity
  set bound : ℝ → ℝ := fun x => g * (|c| + |x|) / D with hbound
  have hderiv_bound : ∀ x, ∀ ρ ∈ Metric.ball ρ₀ ε,
      |g * (stdNormalPDF ((c - √ρ * x) / √(1 - ρ)) *
        ((√ρ * c - x) / (2 * √ρ * √(1 - ρ) ^ 3)))| ≤ bound x := by
    intro x ρ hρ
    obtain ⟨hlo, hhi⟩ := hball ρ hρ
    have hρ0 : 0 < ρ := by linarith
    have hρ1 : ρ < 1 := by linarith
    have hrr : 0 < √ρ := Real.sqrt_pos.mpr hρ0
    have hss : 0 < √(1 - ρ) := Real.sqrt_pos.mpr (by linarith)
    have hrr2 : √ρ ^ 2 = ρ := Real.sq_sqrt hρ0.le
    have hss2 : √(1 - ρ) ^ 2 = 1 - ρ := Real.sq_sqrt (by linarith)
    have hr1 : √ρ ≤ 1 := Real.sqrt_le_one.mpr hρ1.le
    have hs1 : √(1 - ρ) ≤ 1 := Real.sqrt_le_one.mpr (by linarith)
    have hsr : ρ ≤ √ρ := by nlinarith
    have hs3 : (1 - ρ) ^ 2 ≤ √(1 - ρ) ^ 3 := by
      calc (1 - ρ) ^ 2 = (√(1 - ρ) ^ 2) ^ 2 := by rw [hss2]
        _ = √(1 - ρ) ^ 3 * √(1 - ρ) := by ring
        _ ≤ √(1 - ρ) ^ 3 * 1 := by gcongr
        _ = √(1 - ρ) ^ 3 := by ring
    have hden : D ≤ 2 * √ρ * √(1 - ρ) ^ 3 := by
      rw [hD]
      have e1 : ρ₀ / 2 ≤ √ρ := by linarith
      have e2 : ((1 - ρ₀) / 2) ^ 2 ≤ √(1 - ρ) ^ 3 := by
        have : 0 ≤ (1 - ρ₀) / 2 := by linarith
        nlinarith
      have : 0 ≤ ((1 - ρ₀) / 2) ^ 2 := by positivity
      nlinarith
    have hnum : |√ρ * c - x| ≤ |c| + |x| := by
      calc |√ρ * c - x| ≤ |√ρ * c| + |x| := abs_sub _ _
        _ ≤ |c| + |x| := by
          rw [abs_mul, abs_of_pos hrr]
          have := abs_nonneg c
          nlinarith
    have hden0 : 0 < 2 * √ρ * √(1 - ρ) ^ 3 := by positivity
    rw [abs_mul, abs_mul, abs_div, abs_of_pos hg, abs_of_pos (stdNormalPDF_pos _),
      abs_of_pos hden0, hbound]
    have hφ := stdNormalPDF_le_one ((c - √ρ * x) / √(1 - ρ))
    have hq : |√ρ * c - x| / (2 * √ρ * √(1 - ρ) ^ 3) ≤ (|c| + |x|) / D :=
      div_le_div₀ (by positivity) hnum hDpos hden
    calc g * (stdNormalPDF ((c - √ρ * x) / √(1 - ρ)) *
          (|√ρ * c - x| / (2 * √ρ * √(1 - ρ) ^ 3)))
        ≤ g * (1 * ((|c| + |x|) / D)) := by
          gcongr
      _ = g * (|c| + |x|) / D := by ring
  have hlip : ∀ x, LipschitzOnWith (Real.nnabs (bound x))
      (fun ρ => min (poolLoss g c ρ x) K) (Metric.ball ρ₀ ε) := by
    intro x
    have hG : LipschitzOnWith (Real.nnabs (bound x)) (fun ρ => poolLoss g c ρ x)
        (Metric.ball ρ₀ ε) := by
      refine (convex_ball ρ₀ ε).lipschitzOnWith_of_nnnorm_hasDerivWithin_le
        (f' := fun ρ => g * (stdNormalPDF ((c - √ρ * x) / √(1 - ρ)) *
          ((√ρ * c - x) / (2 * √ρ * √(1 - ρ) ^ 3))))
        (fun ρ hρ => ?_) (fun ρ hρ => ?_)
      · obtain ⟨hlo, hhi⟩ := hball ρ hρ
        exact (hasDerivAt_poolLoss g c x ρ (by linarith) (by linarith)).hasDerivWithinAt
      · rw [← NNReal.coe_le_coe, coe_nnnorm, Real.coe_nnabs, Real.norm_eq_abs]
        exact (hderiv_bound x ρ hρ).trans (le_abs_self _)
    have := (LipschitzWith.id.min_const K).comp_lipschitzOnWith hG
    simpa [Function.comp_def] using this
  have hdiff : ∀ᵐ x ∂(gaussianReal 0 1),
      HasDerivAt (fun ρ => min (poolLoss g c ρ x) K) (F' x) ρ₀ := by
    filter_upwards [Measure.ae_ne (gaussianReal 0 1) z] with x hx
    have hd := hasDerivAt_poolLoss g c x ρ₀ h0 h1
    have hc := hd.continuousAt
    rcases lt_or_gt_of_ne hx with hlt | hgt
    · have hgtK : K < poolLoss g c ρ₀ x :=
        mul_lt_mul_of_pos_left (strictMono_stdNormalCDF ((lt_arg_iff c b ρ₀ x h0 h1).mpr hlt)) hg
      have hev : ∀ᶠ ρ in 𝓝 ρ₀, K < poolLoss g c ρ x := hc.eventually (lt_mem_nhds hgtK)
      have : F' x = 0 := Set.indicator_of_notMem (by simp; linarith) h
      rw [this]
      exact (hasDerivAt_const ρ₀ K).congr_of_eventuallyEq
        (hev.mono fun ρ hρ => min_eq_right hρ.le)
    · have hltK : poolLoss g c ρ₀ x < K :=
        mul_lt_mul_of_pos_left (strictMono_stdNormalCDF ((arg_lt_iff c b ρ₀ x h0 h1).mpr hgt)) hg
      have hev : ∀ᶠ ρ in 𝓝 ρ₀, poolLoss g c ρ x < K := hc.eventually (gt_mem_nhds hltK)
      have : F' x = h x := Set.indicator_of_mem hgt h
      rw [this]
      exact hd.congr_of_eventuallyEq (hev.mono fun ρ hρ => min_eq_left hρ.le)
  have hcontF : ∀ ρ, Continuous (fun x => min (poolLoss g c ρ x) K) := by
    intro ρ; unfold poolLoss; have := continuous_stdNormalCDF; fun_prop
  have hint : Integrable (fun x => min (poolLoss g c ρ₀ x) K) (gaussianReal 0 1) :=
    Integrable.of_bound (hcontF ρ₀).aestronglyMeasurable K (ae_of_all _ fun x => by
      have hnn : 0 ≤ min (poolLoss g c ρ₀ x) K :=
        le_min (mul_nonneg hg.le (stdNormalCDF_nonneg _)) hK0
      rw [Real.norm_eq_abs, abs_of_nonneg hnn]
      exact min_le_right _ _)
  have hbint : Integrable bound (gaussianReal 0 1) :=
    (((integrable_const |c|).add integrable_abs_id_gaussian).const_mul g).div_const D
  have main := hasDerivAt_integral_of_dominated_loc_of_lip (μ := gaussianReal 0 1)
    (F := fun ρ x => min (poolLoss g c ρ x) K) (F' := F') (x₀ := ρ₀) (bound := bound)
    (Metric.ball_mem_nhds ρ₀ hεpos) (Eventually.of_forall fun ρ => (hcontF ρ).aestronglyMeasurable)
    hint ((hcont_h.measurable.indicator measurableSet_Ioi).aestronglyMeasurable)
    (ae_of_all _ hlip) hbint hdiff
  have hval : ∫ x, F' x ∂(gaussianReal 0 1) =
      -(g / (2 * √ρ₀ * √(1 - ρ₀))) * (stdNormalPDF b * stdNormalPDF z) := by
    rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
    have e : ∀ x, gaussianPDFReal 0 1 x • F' x =
        (Ioi z).indicator (fun x => stdNormalPDF x * h x) x := by
      intro x; rw [smul_eq_mul, hF']
      by_cases hx : x ∈ Ioi z
      · rw [Set.indicator_of_mem hx, Set.indicator_of_mem hx]; rfl
      · rw [Set.indicator_of_notMem hx, Set.indicator_of_notMem hx, mul_zero]
    simp_rw [e]
    rw [integral_indicator measurableSet_Ioi]
    set Ψ : ℝ → ℝ := fun x => g / (2 * √ρ₀ * √(1 - ρ₀)) *
      (stdNormalPDF x * stdNormalPDF ((c - √ρ₀ * x) / √(1 - ρ₀))) with hΨdef
    have hΨ : ∀ x, HasDerivAt Ψ (stdNormalPDF x * h x) x := by
      intro x
      have ha : HasDerivAt (fun x => (c - √ρ₀ * x) / √(1 - ρ₀)) (-(√ρ₀ * 1) / √(1 - ρ₀)) x :=
        (((hasDerivAt_id x).const_mul √ρ₀).const_sub c).div_const _
      have hp := (hasDerivAt_stdNormalPDF x).mul ((hasDerivAt_stdNormalPDF _).comp x ha)
      have := hp.const_mul (g / (2 * √ρ₀ * √(1 - ρ₀)))
      convert this using 1
      all_goals try rfl
      simp only [hh, Function.comp_apply]
      field_simp
      linear_combination
        (stdNormalPDF x * stdNormalPDF ((c - √ρ₀ * x) / √(1 - ρ₀)) * x) * hr2 +
        (stdNormalPDF x * stdNormalPDF ((c - √ρ₀ * x) / √(1 - ρ₀)) * x) * hs2
    have hΨint : IntegrableOn (fun x => stdNormalPDF x * h x) (Ioi z) := by
      refine Integrable.integrableOn ?_
      set C := g / (2 * √ρ₀ * √(1 - ρ₀) ^ 3) with hC
      have hb : Integrable (fun x => C * (|√ρ₀ * c| * stdNormalPDF x + |x| * stdNormalPDF x)) :=
        ((integrable_stdNormalPDF.const_mul _).add integrable_abs_mul_stdNormalPDF).const_mul C
      refine hb.mono' ((continuous_stdNormalPDF.mul hcont_h).aestronglyMeasurable)
        (ae_of_all _ fun x => ?_)
      have hden0 : 0 < 2 * √ρ₀ * √(1 - ρ₀) ^ 3 := by positivity
      rw [Real.norm_eq_abs, hh]
      simp only
      rw [abs_mul, abs_mul, abs_mul, abs_div, abs_of_pos (stdNormalPDF_pos x), abs_of_pos hg,
        abs_of_pos (stdNormalPDF_pos _), abs_of_pos hden0]
      have h1' := stdNormalPDF_le_one ((c - √ρ₀ * x) / √(1 - ρ₀))
      have h2' : |√ρ₀ * c - x| ≤ |√ρ₀ * c| + |x| := abs_sub _ _
      have hφx := (stdNormalPDF_pos x).le
      calc stdNormalPDF x * (g * (stdNormalPDF ((c - √ρ₀ * x) / √(1 - ρ₀)) *
            (|√ρ₀ * c - x| / (2 * √ρ₀ * √(1 - ρ₀) ^ 3))))
          ≤ stdNormalPDF x * (g * (1 * ((|√ρ₀ * c| + |x|) / (2 * √ρ₀ * √(1 - ρ₀) ^ 3)))) := by
            gcongr
        _ = C * (|√ρ₀ * c| * stdNormalPDF x + |x| * stdNormalPDF x) := by
            rw [hC]; field_simp
    have hΨlim : Tendsto Ψ atTop (𝓝 0) := by
      have h1 : Tendsto (fun x => stdNormalPDF x *
          stdNormalPDF ((c - √ρ₀ * x) / √(1 - ρ₀))) atTop (𝓝 0) :=
        tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds tendsto_stdNormalPDF_atTop
          (fun x => (mul_pos (stdNormalPDF_pos _) (stdNormalPDF_pos _)).le)
          (fun x => mul_le_of_le_one_right (stdNormalPDF_pos _).le (stdNormalPDF_le_one _))
      simpa using h1.const_mul (g / (2 * √ρ₀ * √(1 - ρ₀)))
    rw [integral_Ioi_of_hasDerivAt_of_tendsto' (fun x _ => hΨ x) hΨint hΨlim]
    simp only [hΨdef, harg]
    ring
  rw [← hval]
  exact main.2

lemma continuous_poolLoss_min (g c K ρ : ℝ) : Continuous (fun x => min (poolLoss g c ρ x) K) := by
  unfold poolLoss; have := continuous_stdNormalCDF; fun_prop

lemma poolLoss_min_abs_le (g c K ρ x : ℝ) (hg : 0 ≤ g) (hK : 0 ≤ K) :
    ‖min (poolLoss g c ρ x) K‖ ≤ K := by
  have hnn : 0 ≤ min (poolLoss g c ρ x) K :=
    le_min (mul_nonneg hg (stdNormalCDF_nonneg _)) hK
  rw [Real.norm_eq_abs, abs_of_nonneg hnn]
  exact min_le_right _ _

lemma tendsto_firstLossEL_zero (g c K : ℝ) (hg : 0 ≤ g) (hK : 0 ≤ K) :
    Tendsto (firstLossEL g c K) (𝓝[>] 0) (𝓝 (min (g * stdNormalCDF c) K)) := by
  have h := tendsto_integral_filter_of_dominated_convergence (μ := gaussianReal 0 1)
    (l := 𝓝[>] (0 : ℝ)) (F := fun ρ x => min (poolLoss g c ρ x) K)
    (f := fun _ => min (g * stdNormalCDF c) K) (fun _ => K)
    (Eventually.of_forall fun ρ => (continuous_poolLoss_min g c K ρ).aestronglyMeasurable)
    (Eventually.of_forall fun ρ => ae_of_all _ fun x => poolLoss_min_abs_le g c K ρ x hg hK)
    (integrable_const K) (ae_of_all _ fun x => ?_)
  · unfold firstLossEL; simpa using h
  · have harg : ContinuousAt (fun ρ : ℝ => (c - √ρ * x) / √(1 - ρ)) 0 := by
      fun_prop (disch := norm_num)
    have := ((((continuous_stdNormalCDF.tendsto _).comp harg.tendsto).const_mul g).min (tendsto_const_nhds (x := K)))
    simpa [poolLoss, Function.comp_def] using this.mono_left nhdsWithin_le_nhds

lemma tendsto_sqrt_one_sub : Tendsto (fun ρ : ℝ => √(1 - ρ)) (𝓝[<] 1) (𝓝[>] 0) := by
  refine tendsto_nhdsWithin_iff.mpr ⟨?_, ?_⟩
  · have hc : Continuous (fun ρ : ℝ => √(1 - ρ)) := by fun_prop
    have := hc.tendsto 1
    simpa using this.mono_left nhdsWithin_le_nhds
  · filter_upwards [self_mem_nhdsWithin] with ρ hρ
    exact Real.sqrt_pos.mpr (by simp at hρ; linarith)

lemma tendsto_num_one (c x : ℝ) : Tendsto (fun ρ : ℝ => c - √ρ * x) (𝓝[<] 1) (𝓝 (c - x)) := by
  have hc : Continuous (fun ρ : ℝ => c - √ρ * x) := by fun_prop
  have := hc.tendsto 1
  simpa using this.mono_left nhdsWithin_le_nhds

lemma tendsto_arg_atTop (c x : ℝ) (hx : x < c) :
    Tendsto (fun ρ : ℝ => (c - √ρ * x) / √(1 - ρ)) (𝓝[<] 1) atTop := by
  simp_rw [div_eq_mul_inv]
  exact (tendsto_num_one c x).pos_mul_atTop (by linarith)
    (tendsto_inv_nhdsGT_zero.comp tendsto_sqrt_one_sub)

lemma tendsto_arg_atBot (c x : ℝ) (hx : c < x) :
    Tendsto (fun ρ : ℝ => (c - √ρ * x) / √(1 - ρ)) (𝓝[<] 1) atBot := by
  simp_rw [div_eq_mul_inv]
  exact (tendsto_num_one c x).neg_mul_atTop (by linarith)
    (tendsto_inv_nhdsGT_zero.comp tendsto_sqrt_one_sub)

lemma tendsto_firstLossEL_one (g c K : ℝ) (hK : 0 ≤ K) (hKg : K ≤ g) :
    Tendsto (firstLossEL g c K) (𝓝[<] 1) (𝓝 (stdNormalCDF c * K)) := by
  have : NullSingletonClass (gaussianReal 0 1) := nullSingletonClass_gaussianReal one_ne_zero
  have hg : 0 ≤ g := hK.trans hKg
  have h := tendsto_integral_filter_of_dominated_convergence (μ := gaussianReal 0 1)
    (l := 𝓝[<] (1 : ℝ)) (F := fun ρ x => min (poolLoss g c ρ x) K)
    (f := (Iic c).indicator fun _ => K) (fun _ => K)
    (Eventually.of_forall fun ρ => (continuous_poolLoss_min g c K ρ).aestronglyMeasurable)
    (Eventually.of_forall fun ρ => ae_of_all _ fun x => poolLoss_min_abs_le g c K ρ x hg hK)
    (integrable_const K) ?_
  · have e : ∫ x, (Iic c).indicator (fun _ => K) x ∂(gaussianReal 0 1) = stdNormalCDF c * K := by
      rw [integral_indicator_const _ measurableSet_Iic, smul_eq_mul, stdNormalCDF, cdf_eq_real]
    rw [e] at h
    unfold firstLossEL; exact h
  · filter_upwards [Measure.ae_ne (gaussianReal 0 1) c] with x hx
    rcases lt_or_gt_of_ne hx with hlt | hgt
    · rw [Set.indicator_of_mem (show x ∈ Iic c from hlt.le)]
      have := (((tendsto_stdNormalCDF_atTop.comp (tendsto_arg_atTop c x hlt)).const_mul g).min (tendsto_const_nhds (x := K)))
      simpa [poolLoss, Function.comp_def, min_eq_right hKg] using this
    · rw [Set.indicator_of_notMem (show x ∉ Iic c by simp; linarith)]
      have := (((tendsto_stdNormalCDF_atBot.comp (tendsto_arg_atBot c x hgt)).const_mul g).min (tendsto_const_nhds (x := K)))
      simpa [poolLoss, Function.comp_def, min_eq_left hK] using this

lemma unique_iff_of_strictAntiOn {H : ℝ → ℝ} {L0 L1 : ℝ}
    (hanti : StrictAntiOn H (Ioo 0 1)) (hcont : ContinuousOn H (Ioo 0 1))
    (h0 : Tendsto H (𝓝[>] 0) (𝓝 L0)) (h1 : Tendsto H (𝓝[<] 1) (𝓝 L1)) (Q : ℝ) :
    (∃! ρ, ρ ∈ Ioo (0 : ℝ) 1 ∧ H ρ = Q) ↔ L1 < Q ∧ Q < L0 := by
  constructor
  · rintro ⟨ρ, ⟨⟨hρ0, hρ1⟩, hQ⟩, -⟩
    subst hQ
    constructor
    · have hm : (ρ + 1) / 2 ∈ Ioo (0 : ℝ) 1 := ⟨by linarith, by linarith⟩
      have hle : L1 ≤ H ((ρ + 1) / 2) := by
        apply le_of_tendsto h1
        filter_upwards [Ioo_mem_nhdsLT (show (ρ + 1) / 2 < 1 by linarith)] with t ht
        exact hanti.antitoneOn hm ⟨by linarith [ht.1], ht.2⟩ ht.1.le
      have hlt : H ((ρ + 1) / 2) < H ρ := hanti ⟨hρ0, hρ1⟩ hm (by linarith)
      linarith
    · have hm : ρ / 2 ∈ Ioo (0 : ℝ) 1 := ⟨by linarith, by linarith⟩
      have hle : H (ρ / 2) ≤ L0 := by
        apply ge_of_tendsto h0
        filter_upwards [Ioo_mem_nhdsGT (show (0 : ℝ) < ρ / 2 by linarith)] with t ht
        exact hanti.antitoneOn ⟨ht.1, by linarith [ht.2]⟩ hm ht.2.le
      have hlt : H ρ < H (ρ / 2) := hanti hm ⟨hρ0, hρ1⟩ (by linarith)
      linarith
  · rintro ⟨hL1, hL0⟩
    obtain ⟨a, haQ, ha⟩ := ((h0.eventually (lt_mem_nhds hL0)).and
      (Ioo_mem_nhdsGT (show (0 : ℝ) < 1 / 2 by norm_num))).exists
    obtain ⟨b, hbQ, hb⟩ := ((h1.eventually (gt_mem_nhds hL1)).and
      (Ioo_mem_nhdsLT (show (1 / 2 : ℝ) < 1 by norm_num))).exists
    have hab : a ≤ b := by linarith [ha.2, hb.1]
    have hsub : Icc a b ⊆ Ioo 0 1 := fun t ht => ⟨by linarith [ha.1, ht.1], by linarith [hb.2, ht.2]⟩
    obtain ⟨ρ, hρ, hρQ⟩ := intermediate_value_Icc' hab (hcont.mono hsub) ⟨hbQ.le, haQ.le⟩
    exact ⟨ρ, ⟨hsub hρ, hρQ⟩, fun ρ' ⟨hm', hQ'⟩ => hanti.injOn hm' (hsub hρ) (hQ'.trans hρQ.symm)⟩

lemma hasDerivAt_firstLossEL' (g c b K ρ : ℝ) (hg : 0 < g) (hK : K = g * stdNormalCDF b)
    (hρ : ρ ∈ Ioo (0 : ℝ) 1) :
    HasDerivAt (firstLossEL g c K)
      (-(g / (2 * √ρ * √(1 - ρ))) * (stdNormalPDF b * stdNormalPDF (marketCut c b ρ))) ρ := by
  rw [hK]; exact hasDerivAt_firstLossEL g c b ρ hg hρ.1 hρ.2

lemma deriv_coef_pos (g ρ : ℝ) (hg : 0 < g) (hρ : ρ ∈ Ioo (0 : ℝ) 1) :
    0 < g / (2 * √ρ * √(1 - ρ)) := by
  have h1 : 0 < √ρ := Real.sqrt_pos.mpr hρ.1
  have h2 : 0 < √(1 - ρ) := Real.sqrt_pos.mpr (by linarith [hρ.2])
  positivity

lemma tendsto_trancheEL_zero (g c A B : ℝ) (hg : 0 ≤ g) (hA0 : 0 ≤ A) (hB0 : 0 ≤ B) :
    Tendsto (trancheEL g c A B) (𝓝[>] 0)
      (𝓝 ((min (g * stdNormalCDF c) B - min (g * stdNormalCDF c) A) / (B - A))) :=
  ((tendsto_firstLossEL_zero g c B hg hB0).sub
    (tendsto_firstLossEL_zero g c A hg hA0)).div_const (B - A)

lemma tendsto_trancheEL_one (g c A B : ℝ) (hA0 : 0 ≤ A) (hAg : A ≤ g) (hB0 : 0 ≤ B)
    (hBg : B ≤ g) (hAB : A < B) :
    Tendsto (trancheEL g c A B) (𝓝[<] 1) (𝓝 (stdNormalCDF c)) := by
  have := ((tendsto_firstLossEL_one g c B hB0 hBg).sub
    (tendsto_firstLossEL_one g c A hA0 hAg)).div_const (B - A)
  have e : (stdNormalCDF c * B - stdNormalCDF c * A) / (B - A) = stdNormalCDF c := by
    have : B - A ≠ 0 := by linarith
    field_simp
  rw [e] at this; exact this

end Helpers

#print axioms stdNormalPDF_eq
#print axioms stdNormalPDF_fun
#print axioms stdNormalPDF_pos
#print axioms stdNormalPDF_le_one
#print axioms continuous_stdNormalPDF
#print axioms hasDerivAt_stdNormalPDF
#print axioms integrable_stdNormalPDF
#print axioms stdNormalCDF_eq_integral
#print axioms stdNormalCDF_eq_add
#print axioms hasDerivAt_stdNormalCDF
#print axioms continuous_stdNormalCDF
#print axioms strictMono_stdNormalCDF
#print axioms stdNormalCDF_nonneg
#print axioms stdNormalCDF_le_one
#print axioms tendsto_stdNormalCDF_atTop
#print axioms tendsto_stdNormalCDF_atBot
#print axioms exists_stdNormalCDF_eq
#print axioms pdf_mul_pdf_marketCut
#print axioms pdf_prod_lt_iff
#print axioms hasDerivAt_arg
#print axioms hasDerivAt_poolLoss
#print axioms arg_lt_iff
#print axioms lt_arg_iff
#print axioms arg_marketCut
#print axioms tendsto_stdNormalPDF_atTop
#print axioms integrable_abs_mul_stdNormalPDF
#print axioms integrable_abs_id_gaussian
#print axioms hasDerivAt_firstLossEL
#print axioms continuous_poolLoss_min
#print axioms poolLoss_min_abs_le
#print axioms tendsto_firstLossEL_zero
#print axioms tendsto_sqrt_one_sub
#print axioms tendsto_num_one
#print axioms tendsto_arg_atTop
#print axioms tendsto_arg_atBot
#print axioms tendsto_firstLossEL_one
#print axioms unique_iff_of_strictAntiOn
#print axioms hasDerivAt_firstLossEL'
#print axioms deriv_coef_pos
#print axioms tendsto_trancheEL_zero
#print axioms tendsto_trancheEL_one


/-- **A first-loss slice's implied correlation is unique.** In the large-pool one-factor
Gaussian copula, take loss given default `g > 0`, any default threshold `c` (so the default
chance is `p = N(c)`), and a first-loss slice from 0 to `K` with `0 < K < g`. Then its expected
loss `H_ρ(K)` falls strictly as the correlation `ρ` rises through `(0, 1)`, and a quote `Q` has
exactly one implied correlation in `(0, 1)` precisely when it lies strictly between the
full-correlation value `p K` and the zero-correlation value `min(g p, K)`; a quote at or outside
those ends has none. -/
theorem first_loss_implied_correlation_unique
    (g c K : ℝ) (hg : 0 < g) (hK : 0 < K) (hKg : K < g) :
    StrictAntiOn (firstLossEL g c K) (Ioo 0 1) ∧
    ∀ Q : ℝ, (∃! ρ, ρ ∈ Ioo (0 : ℝ) 1 ∧ firstLossEL g c K ρ = Q) ↔
      stdNormalCDF c * K < Q ∧ Q < min (g * stdNormalCDF c) K := by
  obtain ⟨b, hb⟩ := exists_stdNormalCDF_eq (div_pos hK hg) ((div_lt_one hg).mpr hKg)
  have hKb : K = g * stdNormalCDF b := by rw [hb]; field_simp
  have hderiv := fun ρ (hρ : ρ ∈ Ioo (0 : ℝ) 1) => hasDerivAt_firstLossEL' g c b K ρ hg hKb hρ
  have hcont : ContinuousOn (firstLossEL g c K) (Ioo 0 1) :=
    fun ρ hρ => (hderiv ρ hρ).continuousAt.continuousWithinAt
  have hanti : StrictAntiOn (firstLossEL g c K) (Ioo 0 1) := by
    refine strictAntiOn_of_deriv_neg (convex_Ioo 0 1) hcont fun ρ hρ => ?_
    rw [interior_Ioo] at hρ
    rw [(hderiv ρ hρ).deriv, neg_mul]
    exact neg_neg_of_pos (mul_pos (deriv_coef_pos g ρ hg hρ)
      (mul_pos (stdNormalPDF_pos _) (stdNormalPDF_pos _)))
  exact ⟨hanti, fun Q => unique_iff_of_strictAntiOn hanti hcont
    (tendsto_firstLossEL_zero g c K hg.le hK.le) (tendsto_firstLossEL_one g c K hK.le hKg.le) Q⟩

/-- **The mezzanine has exactly one peak, so its quote can have two answers or none.** Take a
tranche from `A` to `B` with `A = g N(b_A)` and `B = g N(b_B)`, `b_A < b_B` (so `0 < A < B < g`),
and suppose `2c < b_A + b_B < 0`. Then the tranche's expected loss rises strictly on `(0, ρ*]`
and falls strictly on `[ρ*, 1)`, where `ρ* = 1 - ((b_A + b_B)/(2c))²` lies in `(0, 1)`. So no
correlation reproduces a quote above the peak, and a quote below the peak but above both end
values (the full-correlation value `p = N(c)` and the zero-correlation value
`(min(g p, B) - min(g p, A))/(B - A)`) is reproduced by exactly two correlations, one on each
side of `ρ*`. -/
theorem mezzanine_single_peak_two_or_no_implied_correlations
    (g c bA bB A B : ℝ) (hg : 0 < g) (hb : bA < bB)
    (hA : A = g * stdNormalCDF bA) (hB : B = g * stdNormalCDF bB)
    (hlow : 2 * c < bA + bB) (hhigh : bA + bB < 0) :
    peakCorrelation c bA bB ∈ Ioo (0 : ℝ) 1 ∧
    StrictMonoOn (trancheEL g c A B) (Ioc 0 (peakCorrelation c bA bB)) ∧
    StrictAntiOn (trancheEL g c A B) (Ico (peakCorrelation c bA bB) 1) ∧
    (∀ Q : ℝ, trancheEL g c A B (peakCorrelation c bA bB) < Q →
      ∀ ρ ∈ Ioo (0 : ℝ) 1, trancheEL g c A B ρ ≠ Q) ∧
    (∀ Q : ℝ, Q < trancheEL g c A B (peakCorrelation c bA bB) →
      stdNormalCDF c < Q →
      (min (g * stdNormalCDF c) B - min (g * stdNormalCDF c) A) / (B - A) < Q →
      ∃ ρ₁ ρ₂, 0 < ρ₁ ∧ ρ₁ < peakCorrelation c bA bB ∧ peakCorrelation c bA bB < ρ₂ ∧ ρ₂ < 1 ∧
        trancheEL g c A B ρ₁ = Q ∧ trancheEL g c A B ρ₂ = Q ∧
        ∀ ρ ∈ Ioo (0 : ℝ) 1, trancheEL g c A B ρ = Q → ρ = ρ₁ ∨ ρ = ρ₂) := by
  have hNab : stdNormalCDF bA < stdNormalCDF bB := strictMono_stdNormalCDF hb
  have hAB : A < B := by rw [hA, hB]; exact mul_lt_mul_of_pos_left hNab hg
  have hBA : 0 < B - A := by linarith
  have hA0 : 0 ≤ A := by rw [hA]; exact mul_nonneg hg.le (stdNormalCDF_nonneg _)
  have hB0 : 0 ≤ B := by rw [hB]; exact mul_nonneg hg.le (stdNormalCDF_nonneg _)
  have hAg : A ≤ g := by rw [hA]; nlinarith [stdNormalCDF_le_one bA]
  have hBg : B ≤ g := by rw [hB]; nlinarith [stdNormalCDF_le_one bB]
  have hc : c < 0 := by linarith
  set q := (bA + bB) / (2 * c) with hq
  have hq0 : 0 < q := div_pos_of_neg_of_neg hhigh (by linarith)
  have hq1 : q < 1 := (div_lt_one_of_neg (by linarith)).mpr hlow
  have h2cq : 2 * c * q = bA + bB := by rw [hq]; field_simp [show c ≠ 0 from hc.ne]
  have hpk : peakCorrelation c bA bB = 1 - q ^ 2 := rfl
  set ρs := peakCorrelation c bA bB with hρs
  have hρs0 : 0 < ρs := by rw [hpk]; nlinarith
  have hρs1 : ρs < 1 := by rw [hpk]; nlinarith
  set T := trancheEL g c A B with hT
  have hderiv : ∀ ρ ∈ Ioo (0 : ℝ) 1, HasDerivAt T
      ((-(g / (2 * √ρ * √(1 - ρ))) * (stdNormalPDF bB * stdNormalPDF (marketCut c bB ρ)) -
        -(g / (2 * √ρ * √(1 - ρ))) * (stdNormalPDF bA * stdNormalPDF (marketCut c bA ρ))) /
          (B - A)) ρ := by
    intro ρ hρ
    exact ((hasDerivAt_firstLossEL' g c bB B ρ hg hB hρ).sub
      (hasDerivAt_firstLossEL' g c bA A ρ hg hA hρ)).div_const (B - A)
  have hcontT : ContinuousOn T (Ioo 0 1) :=
    fun ρ hρ => (hderiv ρ hρ).continuousAt.continuousWithinAt
  have hdpos : ∀ ρ ∈ Ioo (0 : ℝ) 1,
      stdNormalPDF bB * stdNormalPDF (marketCut c bB ρ) <
        stdNormalPDF bA * stdNormalPDF (marketCut c bA ρ) → 0 < deriv T ρ := by
    intro ρ hρ h
    rw [(hderiv ρ hρ).deriv]
    have := deriv_coef_pos g ρ hg hρ
    exact div_pos (by nlinarith) hBA
  have hdneg : ∀ ρ ∈ Ioo (0 : ℝ) 1,
      stdNormalPDF bA * stdNormalPDF (marketCut c bA ρ) <
        stdNormalPDF bB * stdNormalPDF (marketCut c bB ρ) → deriv T ρ < 0 := by
    intro ρ hρ h
    rw [(hderiv ρ hρ).deriv]
    have := deriv_coef_pos g ρ hg hρ
    exact div_neg_of_neg_of_pos (by nlinarith) hBA
  have hmono : StrictMonoOn T (Ioc 0 ρs) := by
    refine strictMonoOn_of_deriv_pos (convex_Ioc 0 ρs)
      (hcontT.mono fun t ht => ⟨ht.1, ht.2.trans_lt hρs1⟩) fun ρ hρ => ?_
    rw [interior_Ioc] at hρ
    have hρ' : ρ ∈ Ioo (0 : ℝ) 1 := ⟨hρ.1, hρ.2.trans hρs1⟩
    apply hdpos ρ hρ'
    rw [pdf_prod_lt_iff c bB bA ρ hρ'.1 hρ'.2]
    have hs : q < √(1 - ρ) := (Real.lt_sqrt hq0.le).mpr (by linarith [hρ.2, hpk])
    have := mul_lt_mul_of_neg_left hs (show 2 * c < 0 by linarith)
    nlinarith [mul_pos (sub_pos.mpr hb)
      (by linarith : 0 < bA + bB - 2 * c * √(1 - ρ))]
  have hanti : StrictAntiOn T (Ico ρs 1) := by
    refine strictAntiOn_of_deriv_neg (convex_Ico ρs 1)
      (hcontT.mono fun t ht => ⟨hρs0.trans_le ht.1, ht.2⟩) fun ρ hρ => ?_
    rw [interior_Ico] at hρ
    have hρ' : ρ ∈ Ioo (0 : ℝ) 1 := ⟨hρs0.trans hρ.1, hρ.2⟩
    apply hdneg ρ hρ'
    rw [pdf_prod_lt_iff c bA bB ρ hρ'.1 hρ'.2]
    have hs : √(1 - ρ) < q := (Real.sqrt_lt' hq0).mpr (by linarith [hρ.1, hpk])
    have := mul_lt_mul_of_neg_left hs (show 2 * c < 0 by linarith)
    nlinarith [mul_pos_of_neg_of_neg (sub_neg.mpr hb)
      (by linarith : bA + bB - 2 * c * √(1 - ρ) < 0)]
  have hT0 := tendsto_trancheEL_zero g c A B hg.le hA0 hB0
  have hT1 := tendsto_trancheEL_one g c A B hA0 hAg hB0 hBg hAB
  have hmax : ∀ ρ ∈ Ioo (0 : ℝ) 1, T ρ ≤ T ρs := by
    intro ρ hρ
    rcases le_or_gt ρ ρs with h | h
    · exact hmono.monotoneOn ⟨hρ.1, h⟩ ⟨hρs0, le_rfl⟩ h
    · exact hanti.antitoneOn ⟨le_rfl, hρs1⟩ ⟨h.le, hρ.2⟩ h.le
  refine ⟨⟨hρs0, hρs1⟩, hmono, hanti, fun Q hQ ρ hρ => ((hmax ρ hρ).trans_lt hQ).ne, ?_⟩
  intro Q hQpk hQ1 hQ0
  obtain ⟨a, haQ, ha⟩ := ((hT0.eventually (gt_mem_nhds hQ0)).and (Ioo_mem_nhdsGT hρs0)).exists
  obtain ⟨b, hbQ, hb'⟩ := ((hT1.eventually (gt_mem_nhds hQ1)).and (Ioo_mem_nhdsLT hρs1)).exists
  have hsubA : Icc a ρs ⊆ Ioo 0 1 := fun t ht => ⟨ha.1.trans_le ht.1, ht.2.trans_lt hρs1⟩
  have hsubB : Icc ρs b ⊆ Ioo 0 1 := fun t ht => ⟨hρs0.trans_le ht.1, ht.2.trans_lt hb'.2⟩
  obtain ⟨ρ₁, hρ₁, hρ₁Q⟩ := intermediate_value_Icc ha.2.le (hcontT.mono hsubA) ⟨haQ.le, hQpk.le⟩
  obtain ⟨ρ₂, hρ₂, hρ₂Q⟩ := intermediate_value_Icc' hb'.1.le (hcontT.mono hsubB) ⟨hbQ.le, hQpk.le⟩
  have hρ₁lt : ρ₁ < ρs := lt_of_le_of_ne hρ₁.2 (fun h => by rw [h] at hρ₁Q; linarith)
  have hρ₂gt : ρs < ρ₂ := lt_of_le_of_ne hρ₂.1 (fun h => by rw [← h] at hρ₂Q; linarith)
  refine ⟨ρ₁, ρ₂, ha.1.trans_le hρ₁.1, hρ₁lt, hρ₂gt, hρ₂.2.trans_lt hb'.2, hρ₁Q, hρ₂Q, ?_⟩
  intro ρ hρ hρQ
  rcases le_or_gt ρ ρs with h | h
  · left
    exact hmono.injOn ⟨hρ.1, h⟩ ⟨ha.1.trans_le hρ₁.1, hρ₁.2⟩ (hρQ.trans hρ₁Q.symm)
  · right
    exact hanti.injOn ⟨h.le, hρ.2⟩ ⟨hρ₂.1, hρ₂.2.trans_lt hb'.2⟩ (hρQ.trans hρ₂Q.symm)

/-- **The sign test behind the single peak.** For a correlation `0 < ρ < 1` and `b_A < b_B`, the
mezzanine rises (its slope is a positive multiple of `φ(b_A)φ(z_A) - φ(b_B)φ(z_B)`) exactly when
`φ(b_A)φ(z_A) > φ(b_B)φ(z_B)`, and that holds exactly when `b_A + b_B > 2c√(1 - ρ)`. -/
theorem mezzanine_rises_iff_sign_test (c bA bB ρ : ℝ) (hb : bA < bB) (hρ0 : 0 < ρ) (hρ1 : ρ < 1) :
    stdNormalPDF bB * stdNormalPDF (marketCut c bB ρ) <
        stdNormalPDF bA * stdNormalPDF (marketCut c bA ρ) ↔
      2 * c * √(1 - ρ) < bA + bB := by
  rw [pdf_prod_lt_iff c bB bA ρ hρ0 hρ1]
  constructor
  · intro h; nlinarith
  · intro h; nlinarith

-- Step 1: the 3-7% tranche loses min(L, 7) - min(L, 3) points of the pool.
-- Pool losses of 2, 5 and 9 percent give 0, 2 and 4 points.
example : min (2 : ℤ) 7 - min 2 3 = 0 := by decide
example : min (5 : ℤ) 7 - min 5 3 = 2 := by decide
example : min (9 : ℤ) 7 - min 9 3 = 4 := by decide

-- The ends of the 0-3% equity, as a share of its width, with p = 1/20 and g = 3/5:
-- zero correlation min(g p, K)/K = 100 percent, full correlation p min(g, K)/K = 5 percent.
example : min ((3 : ℚ) / 5 * (1 / 20)) (3 / 100) / (3 / 100) = 1 := by norm_num
example : (1 / 20 : ℚ) * min (3 / 5) (3 / 100) / (3 / 100) = 1 / 20 := by norm_num

-- The ends of the 3-7% mezzanine: 0 at zero correlation, 5 percent at full correlation.
example : (min ((3 : ℚ) / 5 * (1 / 20)) (7 / 100) - min ((3 : ℚ) / 5 * (1 / 20)) (3 / 100))
    / (7 / 100 - 3 / 100) = 0 := by norm_num
example : ((1 / 20 : ℚ) * min (3 / 5) (7 / 100) - (1 / 20) * min (3 / 5) (3 / 100))
    / (7 / 100 - 3 / 100) = 1 / 20 := by norm_num

-- Step 6: base correlation at 5% by a straight line between 20% at 3% and 25% at 7% is 22.5%.
example : (20 : ℚ) + (5 - 3) / (7 - 3) * (25 - 20) = 45 / 2 := by norm_num

#print axioms first_loss_implied_correlation_unique
#print axioms mezzanine_single_peak_two_or_no_implied_correlations
#print axioms mezzanine_rises_iff_sign_test

end ImpliedAndBaseCorrelation
