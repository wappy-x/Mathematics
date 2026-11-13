-- Greeks inside the simulation: in the lognormal model, the delta of a discounted average payment is the average of the payment times the score weight Z / (S σ √T), it is also the average of the payment's own slope times S_T / S when the payment never jumps, and on the one-dollar digital that pathwise average is zero while the true delta is not.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Topology.EMetricSpace.Lipschitz
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Analysis.Calculus.Rademacher
import Mathlib.MeasureTheory.Function.Jacobian
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral

open MeasureTheory ProbabilityTheory

/-! The model: `Z` is a standard bell-curve draw, the measure `gaussianReal 0 1`.
Acme's price on expiry day is `S_T = S * exp ((r - q - σ^2/2) * T + σ * √T * Z)`.
A payment rule is any function `g : ℝ → ℝ`; the price is `exp (-(r * T)) * E[g S_T]`.
Delta is the slope of that price in today's price `S`, written as `HasDerivAt`.
The pathwise estimator uses the payment's own slope `deriv g` at the drawn ending;
the score estimator multiplies the payment by the weight `w_S = Z / (S * σ * √T)`.
`φ(x)` is Mathlib's `gaussianPDFReal 0 1 x`, the bell curve's height at `x`. -/

lemma gl_affine_integral (f : ℝ → ℝ) (hf : Measurable f) (m b : ℝ) (v : NNReal)
    (hv : (v : ℝ) = b ^ 2) :
    ∫ z, f (m + b * z) ∂(gaussianReal 0 1) = ∫ y, f y ∂(gaussianReal m v) := by
  have h1 : (gaussianReal 0 1).map (fun z => b * z) = gaussianReal 0 v := by
    rw [gaussianReal_map_const_mul]; congr 1
    · simp
    · ext; simp [hv]
  have h2 : (gaussianReal 0 v).map (fun u => u + m) = gaussianReal m v := by
    rw [gaussianReal_map_add_const]; simp
  calc ∫ z, f (m + b * z) ∂(gaussianReal 0 1)
      = ∫ u, f (u + m) ∂((gaussianReal 0 1).map (fun z => b * z)) := by
        rw [integral_map (f := fun u => f (u + m)) (by fun_prop)
          ((hf.comp (measurable_add_const m)).aestronglyMeasurable)]
        simp [add_comm]
    _ = ∫ u, f (u + m) ∂(gaussianReal 0 v) := by rw [h1]
    _ = ∫ y, f y ∂((gaussianReal 0 v).map (fun u => u + m)) := by
        rw [integral_map (by fun_prop) hf.aestronglyMeasurable]
    _ = _ := by rw [h2]

lemma gl_key_ineq (w : ℝ) (hw : 0 < w) (m0 t δ : ℝ) (hδ : |δ| ≤ 1) :
    Real.exp (-(t - δ) ^ 2 / (2 * w)) * (1 + Real.exp (m0 + t)) ≤
      (Real.exp (1 / (2 * w)) * (1 + Real.exp (m0 + 2 * w))) *
        Real.exp (-(1 / (8 * w)) * t ^ 2) := by
  have hδ2 : δ ^ 2 ≤ 1 := by nlinarith [abs_nonneg δ, sq_abs δ]
  set X := -(1 / (8 * w)) * t ^ 2 with hX
  have hX0 : X ≤ 0 := by
    have : 0 ≤ 1 / (8 * w) := by positivity
    rw [hX]; nlinarith [sq_nonneg t]
  have e1 : -(t - δ) ^ 2 / (2 * w) ≤ 1 / (2 * w) + (X + X) := by
    have h : (1 / (2 * w) + (X + X)) - (-(t - δ) ^ 2 / (2 * w)) =
        ((t - 2 * δ) ^ 2 + 2 - 2 * δ ^ 2) / (4 * w) := by
      rw [hX]; field_simp; ring
    have : 0 ≤ ((t - 2 * δ) ^ 2 + 2 - 2 * δ ^ 2) / (4 * w) :=
      div_nonneg (by nlinarith [sq_nonneg (t - 2 * δ)]) (by linarith)
    linarith
  have e2 : t + X ≤ 2 * w := by
    have h : 2 * w - (t + X) = (t - 4 * w) ^ 2 / (8 * w) := by
      rw [hX]; field_simp; ring
    have : 0 ≤ (t - 4 * w) ^ 2 / (8 * w) := by positivity
    linarith
  calc Real.exp (-(t - δ) ^ 2 / (2 * w)) * (1 + Real.exp (m0 + t))
      ≤ Real.exp (1 / (2 * w) + (X + X)) * (1 + Real.exp (m0 + t)) := by gcongr
    _ = Real.exp (1 / (2 * w)) * (Real.exp (X + X) + Real.exp (m0 + (t + X) + X)) := by
        simp only [Real.exp_add]; ring
    _ ≤ Real.exp (1 / (2 * w)) * (Real.exp X + Real.exp (m0 + 2 * w + X)) := by
        gcongr <;> linarith
    _ = _ := by simp only [Real.exp_add]; ring

lemma gl_core_deriv (h : ℝ → ℝ) (hh : Measurable h) (C : ℝ)
    (hbd : ∀ y, |h y| ≤ C * (1 + Real.exp y)) (v : NNReal) (hv : 0 < (v : ℝ)) (m0 : ℝ) :
    HasDerivAt (fun m => ∫ y, gaussianPDFReal m v y * h y)
      (∫ y, gaussianPDFReal m0 v y * ((y - m0) / v) * h y) m0 := by
  set w : ℝ := (v : ℝ) with hw
  have hC : 0 ≤ C := by
    have h0 := hbd 0; have := abs_nonneg (h 0); nlinarith [Real.exp_pos 0]
  set A : ℝ := (Real.sqrt (2 * Real.pi * w))⁻¹ with hA
  have hA0 : 0 ≤ A := inv_nonneg.mpr (Real.sqrt_nonneg _)
  set K1 := Real.exp (1 / (2 * w)) * (1 + Real.exp (m0 + 2 * w)) with hK1
  have hK10 : 0 ≤ K1 := by positivity
  set β := 1 / (8 * w) with hβdef
  have hβ : 0 < β := by positivity
  have hpdf : ∀ m y, |m - m0| ≤ 1 →
      gaussianPDFReal m v y * (1 + Real.exp y) ≤ A * K1 * Real.exp (-β * (y - m0) ^ 2) := by
    intro m y hm
    have key := gl_key_ineq w hv m0 (y - m0) (m - m0) hm
    rw [show y - m0 - (m - m0) = y - m by ring, show m0 + (y - m0) = y by ring] at key
    rw [gaussianPDFReal]
    calc A * Real.exp (-(y - m) ^ 2 / (2 * w)) * (1 + Real.exp y)
        = A * (Real.exp (-(y - m) ^ 2 / (2 * w)) * (1 + Real.exp y)) := by ring
      _ ≤ A * (K1 * Real.exp (-β * (y - m0) ^ 2)) := by gcongr
      _ = _ := by ring
  have hint0 : Integrable (fun x : ℝ => (|x| + 1) * Real.exp (-β * x ^ 2)) := by
    have h1 := (integrable_mul_exp_neg_mul_sq hβ).norm
    have h2 := integrable_exp_neg_mul_sq hβ
    refine (h1.add h2).congr (ae_of_all _ fun x => ?_)
    simp only [Pi.add_apply, Real.norm_eq_abs, abs_mul, abs_of_pos (Real.exp_pos _)]
    ring
  have hint : Integrable (fun y => (|y - m0| + 1) * Real.exp (-β * (y - m0) ^ 2)) :=
    hint0.comp_sub_right m0
  have hbound_int := hint.const_mul (C / w * (A * K1))
  have hint1 : Integrable (fun y => C * (A * K1) * Real.exp (-β * (y - m0) ^ 2)) :=
    ((integrable_exp_neg_mul_sq hβ).comp_sub_right m0).const_mul _
  have key := hasDerivAt_integral_of_dominated_loc_of_deriv_le (μ := volume)
    (F := fun m y => gaussianPDFReal m v y * h y)
    (F' := fun m y => gaussianPDFReal m v y * ((y - m) / v) * h y) (x₀ := m0)
    (bound := fun y => C / w * (A * K1) * ((|y - m0| + 1) * Real.exp (-β * (y - m0) ^ 2)))
    (Metric.ball_mem_nhds m0 one_pos)
    (Filter.Eventually.of_forall fun m =>
      ((measurable_gaussianPDFReal m v).mul hh).aestronglyMeasurable)
    (by
      refine hint1.mono' ((measurable_gaussianPDFReal m0 v).mul hh).aestronglyMeasurable
        (ae_of_all _ fun y => ?_)
      have hp := hpdf m0 y (by simp)
      have hp0 := gaussianPDFReal_nonneg m0 v y
      rw [Real.norm_eq_abs, abs_mul, abs_of_nonneg hp0]
      calc gaussianPDFReal m0 v y * |h y| ≤ gaussianPDFReal m0 v y * (C * (1 + Real.exp y)) :=
            mul_le_mul_of_nonneg_left (hbd y) hp0
        _ = C * (gaussianPDFReal m0 v y * (1 + Real.exp y)) := by ring
        _ ≤ C * (A * K1 * Real.exp (-β * (y - m0) ^ 2)) := mul_le_mul_of_nonneg_left hp hC
        _ = _ := by ring)
    (by
      exact (((measurable_gaussianPDFReal m0 v).mul (by fun_prop)).mul hh).aestronglyMeasurable)
    (by
      refine ae_of_all _ fun y m hm => ?_
      rw [Metric.mem_ball, Real.dist_eq] at hm
      have hp := hpdf m y hm.le
      have hp0 := gaussianPDFReal_nonneg m v y
      have hym : |y - m| ≤ |y - m0| + 1 := by
        have := abs_sub_le y m0 m
        rw [abs_sub_comm m0 m] at this; linarith
      rw [Real.norm_eq_abs, abs_mul, abs_mul, abs_div, abs_of_nonneg hp0, abs_of_pos hv]
      calc gaussianPDFReal m v y * (|y - m| / w) * |h y|
          ≤ gaussianPDFReal m v y * ((|y - m0| + 1) / w) * (C * (1 + Real.exp y)) := by
            apply mul_le_mul _ (hbd y) (abs_nonneg _) (by positivity)
            apply mul_le_mul_of_nonneg_left _ hp0
            exact div_le_div_of_nonneg_right hym hv.le
        _ = C / w * (|y - m0| + 1) * (gaussianPDFReal m v y * (1 + Real.exp y)) := by ring
        _ ≤ C / w * (|y - m0| + 1) * (A * K1 * Real.exp (-β * (y - m0) ^ 2)) := by
            apply mul_le_mul_of_nonneg_left hp; positivity
        _ = _ := by ring)
    hbound_int
    (by
      refine ae_of_all _ fun y m _ => ?_
      have h1 : HasDerivAt (fun m => -(y - m) ^ 2 / (2 * w)) ((y - m) / w) m := by
        have h0 : HasDerivAt (fun m => y - m) (-1) m := by
          simpa using (hasDerivAt_id m).const_sub y
        have := (h0.pow 2).neg.div_const (2 * w)
        convert this using 1
        field_simp; ring
      have h2 := (h1.exp.const_mul A).mul_const (h y)
      convert h2 using 1
      · simp only [gaussianPDFReal, hA, hw]
      · simp only [gaussianPDFReal, hA, hw]; ring)
  exact key.2

lemma gl_integral_Ioi_mul_pdf (c : ℝ) :
    ∫ z in Set.Ioi c, z * gaussianPDFReal 0 1 z = gaussianPDFReal 0 1 c := by
  have hd : ∀ x, HasDerivAt (fun x => -gaussianPDFReal 0 1 x) (x * gaussianPDFReal 0 1 x) x := by
    intro x
    have := ((((hasDerivAt_id x).pow 2).neg.div_const 2).exp.const_mul
      ((Real.sqrt (2 * Real.pi))⁻¹)).neg
    convert this using 1
    · ext y; simp [gaussianPDFReal]
    · simp [gaussianPDFReal]; ring
  have hint : Integrable (fun x => x * gaussianPDFReal 0 1 x) := by
    have := (integrable_mul_exp_neg_mul_sq (b := 1 / 2) (by norm_num)).const_mul
      ((Real.sqrt (2 * Real.pi))⁻¹)
    refine this.congr (ae_of_all _ fun x => ?_)
    simp [gaussianPDFReal]; ring_nf
  have htend : Filter.Tendsto (fun x => -gaussianPDFReal 0 1 x) Filter.atTop (nhds 0) := by
    have h1 : Filter.Tendsto (fun x : ℝ => x ^ 2 / 2) Filter.atTop Filter.atTop :=
      (Filter.tendsto_pow_atTop two_ne_zero).atTop_div_const two_pos
    have h2 := ((Real.tendsto_exp_neg_atTop_nhds_zero.comp h1).const_mul
      ((Real.sqrt (2 * Real.pi))⁻¹)).neg
    simp only [mul_zero, neg_zero] at h2
    refine h2.congr (fun x => ?_)
    simp only [gaussianPDFReal, Function.comp, NNReal.coe_one, sub_zero, mul_one]
    ring_nf
  have := integral_Ioi_of_hasDerivAt_of_tendsto' (a := c) (fun x _ => hd x) hint.integrableOn htend
  rw [this]; ring

#print axioms gl_affine_integral
#print axioms gl_key_ineq
#print axioms gl_core_deriv
#print axioms gl_integral_Ioi_mul_pdf

/-- The score (likelihood ratio) method: for a payment rule `g` that is measurable and grows at
most linearly (so the price exists, as it does for the call and the digital), with positive
spot, positive volatility and positive time to expiry, the slope of the price
`e^{-rT} E[g(S_T)]` in today's price `S` is the average of the discounted payment times the
score weight `Z / (S σ √T)`. The payment itself is never differentiated, so jumps do not matter. -/
theorem score_estimator_gives_delta (g : ℝ → ℝ) (hg : Measurable g) (C : ℝ)
    (hgrowth : ∀ x, |g x| ≤ C * (1 + |x|)) (S r q σ T : ℝ)
    (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
      (fun s => Real.exp (-(r * T)) *
        ∫ z, g (s * Real.exp ((r - q - σ ^ 2 / 2) * T + σ * Real.sqrt T * z)) ∂(gaussianReal 0 1))
      (Real.exp (-(r * T)) *
        ∫ z, g (S * Real.exp ((r - q - σ ^ 2 / 2) * T + σ * Real.sqrt T * z)) *
          (z / (S * σ * Real.sqrt T)) ∂(gaussianReal 0 1))
      S := by
  set a := (r - q - σ ^ 2 / 2) * T with ha
  set b := σ * Real.sqrt T with hb
  have hb0 : 0 < b := mul_pos hσ (Real.sqrt_pos.mpr hT)
  set v : NNReal := (b ^ 2).toNNReal with hv
  have hvb : (v : ℝ) = b ^ 2 := Real.coe_toNNReal _ (sq_nonneg b)
  have hvpos : 0 < (v : ℝ) := by rw [hvb]; positivity
  have hv0 : v ≠ 0 := by intro h; rw [h] at hvpos; simp at hvpos
  have hh : Measurable (fun y => g (Real.exp y)) := hg.comp Real.measurable_exp
  have hbd : ∀ y, |(fun y => g (Real.exp y)) y| ≤ C * (1 + Real.exp y) := fun y => by
    have := hgrowth (Real.exp y); rwa [abs_of_pos (Real.exp_pos y)] at this
  set G : ℝ → ℝ := fun m => ∫ y, gaussianPDFReal m v y * g (Real.exp y) with hG
  set m0 := Real.log S + a with hm0
  have hGd := gl_core_deriv (fun y => g (Real.exp y)) hh C hbd v hvpos m0
  have hm : HasDerivAt (fun s => Real.log s + a) S⁻¹ S := (Real.hasDerivAt_log hS.ne').add_const a
  have hcomp : HasDerivAt (G ∘ fun s => Real.log s + a)
      ((∫ y, gaussianPDFReal m0 v y * ((y - m0) / v) * g (Real.exp y)) * S⁻¹) S := hGd.comp S hm
  have hrep : ∀ s, 0 < s →
      ∫ z, g (s * Real.exp (a + b * z)) ∂(gaussianReal 0 1) = G (Real.log s + a) := by
    intro s hs
    have e : ∀ z, s * Real.exp (a + b * z) = Real.exp ((Real.log s + a) + b * z) := by
      intro z; simp only [Real.exp_add, Real.exp_log hs]; ring
    simp_rw [e]
    have := gl_affine_integral (fun y => g (Real.exp y)) hh (Real.log s + a) b v hvb
    rw [this, integral_gaussianReal_eq_integral_smul hv0]
    simp [hG, smul_eq_mul]
  have hev : (fun s => ∫ z, g (s * Real.exp (a + b * z)) ∂(gaussianReal 0 1)) =ᶠ[nhds S]
      (G ∘ fun s => Real.log s + a) := by
    filter_upwards [Ioi_mem_nhds hS] with s hs using hrep s hs
  have hD := hcomp.congr_of_eventuallyEq hev
  have hval : (∫ y, gaussianPDFReal m0 v y * ((y - m0) / v) * g (Real.exp y)) * S⁻¹ =
      ∫ z, g (S * Real.exp (a + b * z)) * (z / (S * σ * Real.sqrt T)) ∂(gaussianReal 0 1) := by
    have e1 : ∫ y, gaussianPDFReal m0 v y * ((y - m0) / v) * g (Real.exp y) =
        ∫ y, ((y - m0) / v * g (Real.exp y)) ∂(gaussianReal m0 v) := by
      rw [integral_gaussianReal_eq_integral_smul hv0]
      congr 1; ext y; simp only [smul_eq_mul]; ring
    have e2 := gl_affine_integral (fun y => (y - m0) / v * g (Real.exp y))
      (by fun_prop) m0 b v hvb
    rw [e1, ← e2, ← integral_mul_const]
    congr 1; ext z
    have : Real.exp (m0 + b * z) = S * Real.exp (a + b * z) := by
      rw [hm0, Real.exp_add, Real.exp_add, Real.exp_log hS, Real.exp_add]; ring
    rw [this, hvb, hb]
    have hsT : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
    field_simp
    ring
  rw [hval] at hD
  exact hD.const_mul (Real.exp (-(r * T)))

/-- Pathwise differentiation: for a payment rule that never jumps, in the sense that two endings
never produce payments further apart than `L` times the distance between the endings (the call
has `L = 1`; a corner is allowed), with positive spot, volatility and time, the slope of the price
in today's price `S` is the average of the discounted payment slope at the drawn ending times
`S_T / S`. The corner itself is hit with probability zero. -/
theorem pathwise_estimator_gives_delta (g : ℝ → ℝ) (L : NNReal) (hg : LipschitzWith L g)
    (S r q σ T : ℝ) (hS : 0 < S) (hσ : 0 < σ) (hT : 0 < T) :
    HasDerivAt
      (fun s => Real.exp (-(r * T)) *
        ∫ z, g (s * Real.exp ((r - q - σ ^ 2 / 2) * T + σ * Real.sqrt T * z)) ∂(gaussianReal 0 1))
      (Real.exp (-(r * T)) *
        ∫ z, deriv g (S * Real.exp ((r - q - σ ^ 2 / 2) * T + σ * Real.sqrt T * z)) *
          (S * Real.exp ((r - q - σ ^ 2 / 2) * T + σ * Real.sqrt T * z) / S) ∂(gaussianReal 0 1))
      S := by
  set a := (r - q - σ ^ 2 / 2) * T with ha
  set b := σ * Real.sqrt T with hb
  have hb0 : 0 < b := mul_pos hσ (Real.sqrt_pos.mpr hT)
  have hgc : Continuous g := hg.continuous
  have hEint : Integrable (fun z => Real.exp (a + b * z)) (gaussianReal 0 1) := by
    have := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) b).const_mul (Real.exp a)
    refine this.congr (ae_of_all _ fun z => ?_)
    simp [Real.exp_add]
  have hdiff : ∀ᵐ z ∂(gaussianReal 0 1), DifferentiableAt ℝ g (S * Real.exp (a + b * z)) := by
    have hN : volume {x | ¬ DifferentiableAt ℝ g x} = 0 := by
      have := hg.ae_differentiableAt (μ := volume)
      rwa [ae_iff] at this
    let ψ : ℝ → ℝ := fun x => (Real.log x - Real.log S - a) / b
    have hψ : volume (ψ '' ({x | ¬ DifferentiableAt ℝ g x} ∩ {x | x ≠ 0})) = 0 := by
      apply addHaar_image_eq_zero_of_differentiableOn_of_addHaar_eq_zero
      · intro x hx
        exact ((((Real.differentiableAt_log hx.2).sub_const _).sub_const _).div_const
          _).differentiableWithinAt
      · exact measure_mono_null Set.inter_subset_left hN
    have hsub : {z | ¬ DifferentiableAt ℝ g (S * Real.exp (a + b * z))} ⊆
        ψ '' ({x | ¬ DifferentiableAt ℝ g x} ∩ {x | x ≠ 0}) := by
      intro z hz
      refine ⟨S * Real.exp (a + b * z), ⟨hz, (mul_pos hS (Real.exp_pos _)).ne'⟩, ?_⟩
      simp only [ψ]
      rw [Real.log_mul hS.ne' (Real.exp_pos _).ne', Real.log_exp]
      field_simp
      ring
    have hvol : ∀ᵐ z ∂volume, DifferentiableAt ℝ g (S * Real.exp (a + b * z)) := by
      rw [ae_iff]; exact measure_mono_null hsub hψ
    exact (gaussianReal_absolutelyContinuous 0 one_ne_zero).ae_le hvol
  have key := hasDerivAt_integral_of_dominated_loc_of_lip (μ := gaussianReal 0 1)
    (F := fun s z => g (s * Real.exp (a + b * z)))
    (F' := fun z => deriv g (S * Real.exp (a + b * z)) * (S * Real.exp (a + b * z) / S))
    (x₀ := S) (s := Set.univ) (bound := fun z => (L : ℝ) * Real.exp (a + b * z))
    Filter.univ_mem
    (Filter.Eventually.of_forall fun s =>
      (hgc.comp (by fun_prop : Continuous fun z => s * Real.exp (a + b * z))).aestronglyMeasurable)
    (by
      refine ((integrable_const |g 0|).add (hEint.const_mul ((L : ℝ) * S))).mono'
        (hgc.comp (by fun_prop :
          Continuous fun z => S * Real.exp (a + b * z))).aestronglyMeasurable
        (ae_of_all _ fun z => ?_)
      have h1 := hg.dist_le_mul (S * Real.exp (a + b * z)) 0
      rw [Real.dist_eq, Real.dist_eq, sub_zero,
        abs_of_pos (mul_pos hS (Real.exp_pos _))] at h1
      have h2 := abs_sub_abs_le_abs_sub (g (S * Real.exp (a + b * z))) (g 0)
      simp only [Pi.add_apply, Real.norm_eq_abs]
      nlinarith)
    (by
      exact (((measurable_deriv g).comp (by fun_prop)).mul (by fun_prop)).aestronglyMeasurable)
    (by
      refine ae_of_all _ fun z => ?_
      apply LipschitzWith.lipschitzOnWith
      apply LipschitzWith.of_dist_le_mul
      intro x y
      rw [Real.coe_nnabs, abs_of_nonneg (by positivity)]
      calc dist (g (x * Real.exp (a + b * z))) (g (y * Real.exp (a + b * z)))
          ≤ L * dist (x * Real.exp (a + b * z)) (y * Real.exp (a + b * z)) := hg.dist_le_mul _ _
        _ = L * Real.exp (a + b * z) * dist x y := by
          rw [Real.dist_eq, Real.dist_eq, ← sub_mul, abs_mul, abs_of_pos (Real.exp_pos _)]
          ring)
    (hEint.const_mul _)
    (by
      filter_upwards [hdiff] with z hz
      have h1 : HasDerivAt (fun s => s * Real.exp (a + b * z)) (Real.exp (a + b * z)) S := by
        simpa using (hasDerivAt_id S).mul_const (Real.exp (a + b * z))
      have h2 := hz.hasDerivAt.comp S h1
      convert h2 using 1
      · rfl
      · rw [mul_div_cancel_left₀ _ hS.ne'])
  exact key.2.const_mul (Real.exp (-(r * T)))

/-- The one-dollar digital, which pays 1 if Acme ends above the strike `K` and 0 otherwise:
its pathwise average (payment slope times `S_T / S`, discounted) is exactly zero, its score
average is `e^{-rT} φ(d₂) / (S σ √T)`, the price's true slope is that same number, and that
number is positive. So pathwise reports no delta at all, and only the score finds it. -/
theorem digital_pathwise_zero_score_exact (S K r q σ T : ℝ)
    (hS : 0 < S) (hK : 0 < K) (hσ : 0 < σ) (hT : 0 < T) :
    let d₂ := (Real.log (S / K) + (r - q - σ ^ 2 / 2) * T) / (σ * Real.sqrt T)
    let dig : ℝ → ℝ := fun x => if K < x then 1 else 0
    let ST : ℝ → ℝ → ℝ := fun s z => s * Real.exp ((r - q - σ ^ 2 / 2) * T + σ * Real.sqrt T * z)
    Real.exp (-(r * T)) * ∫ z, deriv dig (ST S z) * (ST S z / S) ∂(gaussianReal 0 1) = 0 ∧
    Real.exp (-(r * T)) * ∫ z, dig (ST S z) * (z / (S * σ * Real.sqrt T)) ∂(gaussianReal 0 1) =
      Real.exp (-(r * T)) * gaussianPDFReal 0 1 d₂ / (S * σ * Real.sqrt T) ∧
    HasDerivAt (fun s => Real.exp (-(r * T)) * ∫ z, dig (ST s z) ∂(gaussianReal 0 1))
      (Real.exp (-(r * T)) * gaussianPDFReal 0 1 d₂ / (S * σ * Real.sqrt T)) S ∧
    0 < Real.exp (-(r * T)) * gaussianPDFReal 0 1 d₂ / (S * σ * Real.sqrt T) := by
  intro d₂ dig ST
  have hsT : 0 < Real.sqrt T := Real.sqrt_pos.mpr hT
  have hb0 : 0 < σ * Real.sqrt T := mul_pos hσ hsT
  have hden : 0 < S * σ * Real.sqrt T := mul_pos (mul_pos hS hσ) hsT
  -- the digital's slope is zero everywhere (at the strike it is not differentiable)
  have hderiv0 : ∀ x, deriv dig x = 0 := by
    intro x
    rcases lt_trichotomy x K with hx | hx | hx
    · have : dig =ᶠ[nhds x] fun _ => (0 : ℝ) := by
        filter_upwards [Iio_mem_nhds hx] with y hy
        have hy' : y < K := hy
        simp [dig, not_lt.mpr hy'.le]
      rw [this.deriv_eq]; simp
    · apply deriv_zero_of_not_differentiableAt
      intro hd
      have h1 : Filter.Tendsto dig (nhdsWithin x (Set.Ioi x)) (nhds (dig x)) :=
        hd.continuousAt.tendsto.mono_left nhdsWithin_le_nhds
      have h2 : Filter.Tendsto dig (nhdsWithin x (Set.Ioi x)) (nhds 1) := by
        apply tendsto_const_nhds.congr'
        filter_upwards [self_mem_nhdsWithin] with y hy
        have : K < y := by rw [← hx]; exact hy
        simp [dig, this]
      have := tendsto_nhds_unique h1 h2
      simp [dig, hx] at this
    · have : dig =ᶠ[nhds x] fun _ => (1 : ℝ) := by
        filter_upwards [Ioi_mem_nhds hx] with y hy
        have hy' : K < y := hy
        simp [dig, hy']
      rw [this.deriv_eq]; simp
  -- the exercise region: K < S_T exactly when the draw is above c = -d₂
  set c := (Real.log K - Real.log S - (r - q - σ ^ 2 / 2) * T) / (σ * Real.sqrt T) with hc
  have hcd : c = -d₂ := by
    simp only [hc, d₂, Real.log_div hS.ne' hK.ne']
    field_simp
    ring
  have hdig : ∀ z, dig (ST S z) = if c < z then 1 else 0 := by
    intro z
    have hpos : 0 < ST S z := mul_pos hS (Real.exp_pos _)
    have iff1 : K < ST S z ↔ c < z := by
      rw [← Real.log_lt_log_iff hK hpos]
      simp only [ST]
      rw [Real.log_mul hS.ne' (Real.exp_pos _).ne', Real.log_exp, hc, div_lt_iff₀ hb0]
      constructor <;> intro h <;> linarith
    by_cases h : c < z
    · simp [dig, iff1.mpr h, h]
    · have : ¬ K < ST S z := fun h' => h (iff1.mp h')
      simp only [dig, this, h, ite_false]
  have hscore : ∫ z, dig (ST S z) * (z / (S * σ * Real.sqrt T)) ∂(gaussianReal 0 1) =
      gaussianPDFReal 0 1 d₂ / (S * σ * Real.sqrt T) := by
    rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
    have : (fun z => gaussianPDFReal 0 1 z • (dig (ST S z) * (z / (S * σ * Real.sqrt T)))) =
        Set.indicator (Set.Ioi c) (fun z => z * gaussianPDFReal 0 1 z / (S * σ * Real.sqrt T)) := by
      ext z
      rw [hdig]
      by_cases hz : c < z
      · simp only [Set.indicator, Set.mem_Ioi, hz, ite_true, smul_eq_mul]; ring
      · simp only [Set.indicator, Set.mem_Ioi, hz, ite_false, smul_eq_mul]; ring
    rw [this, integral_indicator measurableSet_Ioi, integral_div, gl_integral_Ioi_mul_pdf, hcd]
    congr 1
    simp only [gaussianPDFReal]
    ring_nf
  have hpart2 : Real.exp (-(r * T)) *
      ∫ z, dig (ST S z) * (z / (S * σ * Real.sqrt T)) ∂(gaussianReal 0 1) =
      Real.exp (-(r * T)) * gaussianPDFReal 0 1 d₂ / (S * σ * Real.sqrt T) := by
    rw [hscore, mul_div_assoc]
  refine ⟨?_, hpart2, ?_, ?_⟩
  · simp [hderiv0]
  · have hmeas : Measurable dig :=
      Measurable.ite measurableSet_Ioi measurable_const measurable_const
    have hgr : ∀ x, |dig x| ≤ 1 * (1 + |x|) := by
      intro x
      by_cases h : K < x
      · simp only [dig, h, ite_true, abs_one, one_mul]; linarith [abs_nonneg x]
      · simp only [dig, h, ite_false, abs_zero, one_mul]; positivity
    have := score_estimator_gives_delta dig hmeas 1 hgr S r q σ T hS hσ hT
    exact this.congr_deriv hpart2
  · exact div_pos (mul_pos (Real.exp_pos _) (gaussianPDFReal_pos _ _ _ one_ne_zero)) hden

/-! The card's exact worked steps: S = 100, K = 100, r = 5/100, q = 2/100, σ = 1/5, T = 1. -/

-- d₂, the wiggle units of room: (ln 1 + 5/100 - 2/100 - (1/5)^2/2) / (1/5) = 1/20 (the card's 0.05).
example : (Real.log (100 / 100) + ((5 : ℝ) / 100 - 2 / 100 - (1 / 5) ^ 2 / 2) * 1) /
    ((1 / 5) * Real.sqrt 1) = 1 / 20 := by
  norm_num
-- d₁ = d₂ + σ √T = 1/20 + 1/5 = 1/4 (the card's 0.25).
example : (1 : ℚ) / 20 + 1 / 5 * 1 = 1 / 4 := by norm_num
-- One wiggle in dollars, S σ √T = 100 * 1/5 * 1 = 20, so the spot weight is the draw over twenty.
example : (100 : ℝ) * (1 / 5) * Real.sqrt 1 = 20 := by norm_num

#print axioms score_estimator_gives_delta
#print axioms pathwise_estimator_gives_delta
#print axioms digital_pathwise_zero_score_exact
