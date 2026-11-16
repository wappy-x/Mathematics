-- The Hilbert transform: the kernel 1/(πt), cut with equal gaps, has the quarter-turn multiplier -i sgn(ξ), that multiplier turns cosines into sines, and the analytic signal of an AM wave whose carrier lies above every message frequency is A(t) e^(2πi ξ_c t), with the positive height A(t) as its size.
import Mathlib.Basic.Real.Sign
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Sinc
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.ExpDecay
import Mathlib.MeasureTheory.Integral.DominatedConvergence

open Complex MeasureTheory Filter Topology

noncomputable section

namespace HilbertCard

variable {ι : Type*} [Fintype ι]

/-- A steady signal made of finitely many arrows: coefficient `c k` at frequency `ν k` hertz,
`t` in seconds. -/
def trigSignal (c : ι → ℂ) (ν : ι → ℝ) (t : ℝ) : ℂ :=
  ∑ k, c k * exp (2 * Real.pi * I * ν k * t)

/-- The Hilbert transform by its multiplier `-i sgn(ξ)`, acting spike by spike. -/
def hilbert (c : ι → ℂ) (ν : ι → ℝ) (t : ℝ) : ℂ :=
  ∑ k, (-I * (Real.sign (ν k) : ℂ)) * c k * exp (2 * Real.pi * I * ν k * t)

/-- The analytic signal `z = s + i Hs`. -/
def analyticSignal (c : ι → ℂ) (ν : ι → ℝ) (t : ℝ) : ℂ :=
  trigSignal c ν t + I * hilbert c ν t

/-- The spectrum of the AM wave `A(t) cos(2π ξ_c t)`: each arrow `a k` of the message at `ν k`
splits into two arrows `a k / 2`, at `ν k + ξ_c` and at `ν k - ξ_c`. -/
def amCoeff (a : ι → ℂ) : ι ⊕ ι → ℂ :=
  Sum.elim (fun k => a k / 2) (fun k => a k / 2)

/-- The frequencies of the AM wave: the message's frequencies shifted up and down by `ξ_c`. -/
def amFreq (ν : ι → ℝ) (ξc : ℝ) : ι ⊕ ι → ℝ :=
  Sum.elim (fun k => ν k + ξc) (fun k => ν k - ξc)

end HilbertCard

open HilbertCard

variable {ι : Type*} [Fintype ι]


lemma hc_exp_neg_freq (ν t : ℝ) :
    exp (2 * Real.pi * I * ((-ν : ℝ) : ℂ) * t) = (exp (2 * Real.pi * I * ν * t))⁻¹ := by
  rw [← Complex.exp_neg]; congr 1; push_cast; ring

#print axioms hc_exp_neg_freq

lemma hc_exp_add_freq (ν ξ t : ℝ) :
    exp (2 * Real.pi * I * ((ν + ξ : ℝ) : ℂ) * t) =
      exp (2 * Real.pi * I * ν * t) * exp (2 * Real.pi * I * ξ * t) := by
  rw [← Complex.exp_add]; congr 1; push_cast; ring

#print axioms hc_exp_add_freq

lemma hc_exp_sub_freq (ν ξ t : ℝ) :
    exp (2 * Real.pi * I * ((ν - ξ : ℝ) : ℂ) * t) =
      exp (2 * Real.pi * I * ν * t) * (exp (2 * Real.pi * I * ξ * t))⁻¹ := by
  rw [← Complex.exp_neg, ← Complex.exp_add]; congr 1; push_cast; ring

#print axioms hc_exp_sub_freq

lemma hc_cos (ν t : ℝ) : ((Real.cos (2 * Real.pi * ν * t) : ℝ) : ℂ) =
    (exp (2 * Real.pi * I * ν * t) + (exp (2 * Real.pi * I * ν * t))⁻¹) / 2 := by
  rw [Complex.ofReal_cos, Complex.cos, ← Complex.exp_neg]
  congr 3 <;> push_cast <;> ring

#print axioms hc_cos

lemma hc_sin (ν t : ℝ) : ((Real.sin (2 * Real.pi * ν * t) : ℝ) : ℂ) =
    ((exp (2 * Real.pi * I * ν * t))⁻¹ - exp (2 * Real.pi * I * ν * t)) * I / 2 := by
  rw [Complex.ofReal_sin, Complex.sin, ← Complex.exp_neg]
  congr 4 <;> push_cast <;> ring

#print axioms hc_sin

open MeasureTheory in
lemma hc_dir_inner_exp (x : ℝ) (hx : 0 < x) :
    (∫ t in Set.Ioi (0 : ℝ), Real.exp (-x * t)) = 1 / x := by
  rw [integral_exp_mul_Ioi (by linarith) 0]
  simp

#print axioms hc_dir_inner_exp

open MeasureTheory in
lemma hc_dir_inner_sin (R t : ℝ) :
    (∫ x in (0 : ℝ)..R, Real.sin x * Real.exp (-x * t)) =
      (1 - Real.exp (-R * t) * (t * Real.sin R + Real.cos R)) / (1 + t ^ 2) := by
  have ht : (1 + t ^ 2) ≠ 0 := by positivity
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun x : ℝ => -(Real.exp (-x * t) * (t * Real.sin x + Real.cos x)) / (1 + t ^ 2))]
  · simp only [neg_zero, zero_mul, Real.exp_zero, Real.sin_zero, Real.cos_zero, mul_zero,
      zero_add, one_mul]
    field_simp
    ring
  · intro x _
    have h1 := (((hasDerivAt_id' x).neg.mul_const t).exp)
    have h2 := ((Real.hasDerivAt_sin x).const_mul t).add (Real.hasDerivAt_cos x)
    have hd := ((h1.mul h2).neg).div_const (1 + t ^ 2)
    convert hd using 1
    simp only [Pi.neg_apply, Pi.add_apply]
    field_simp
    ring
  · exact (by fun_prop : Continuous fun x : ℝ => Real.sin x * Real.exp (-x * t)).intervalIntegrable _ _

#print axioms hc_dir_inner_sin

open MeasureTheory in
lemma hc_dir_integrable (R : ℝ) :
    Integrable (Function.uncurry fun x t : ℝ => Real.sin x * Real.exp (-x * t))
      ((volume.restrict (Set.Ioc (0 : ℝ) R)).prod (volume.restrict (Set.Ioi (0 : ℝ)))) := by
  have hc : Continuous (Function.uncurry fun x t : ℝ => Real.sin x * Real.exp (-x * t)) := by
    show Continuous (fun p : ℝ × ℝ => Real.sin p.1 * Real.exp (-p.1 * p.2))
    fun_prop
  refine (integrable_prod_iff hc.aestronglyMeasurable).mpr ⟨?_, ?_⟩
  · filter_upwards [ae_restrict_mem measurableSet_Ioc] with x hx
    exact (exp_neg_integrableOn_Ioi 0 hx.1).const_mul (Real.sin x)
  · have hint : Integrable (fun x : ℝ => |Real.sinc x|) (volume.restrict (Set.Ioc (0 : ℝ) R)) :=
      Continuous.integrableOn_Ioc (by fun_prop)
    refine hint.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioc] with x hx
    have hx0 : 0 < x := hx.1
    show |Real.sinc x| = ∫ t in Set.Ioi (0 : ℝ), ‖Real.sin x * Real.exp (-x * t)‖
    simp_rw [norm_mul, Real.norm_eq_abs, Real.abs_exp]
    rw [integral_const_mul, hc_dir_inner_exp x hx0, Real.sinc_of_ne_zero hx0.ne', abs_div,
      abs_of_pos hx0]
    ring

#print axioms hc_dir_integrable

open MeasureTheory in
lemma hc_dir_bound (R t : ℝ) :
    ‖Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)‖ ≤ 2 * Real.exp (-R * t) := by
  have ht : 0 < 1 + t ^ 2 := by positivity
  have he := Real.exp_pos (-R * t)
  rw [Real.norm_eq_abs, abs_div, abs_mul, Real.abs_exp, abs_of_pos ht, div_le_iff₀ ht]
  have h1 : |t * Real.sin R + Real.cos R| ≤ |t| + 1 := by
    calc |t * Real.sin R + Real.cos R| ≤ |t * Real.sin R| + |Real.cos R| := abs_add_le _ _
      _ ≤ |t| * 1 + 1 := by
        rw [abs_mul]
        gcongr
        · exact Real.abs_sin_le_one R
        · exact Real.abs_cos_le_one R
      _ = |t| + 1 := by ring
  have h2 : |t| ≤ 1 + t ^ 2 := by nlinarith [abs_nonneg t, sq_abs t]
  calc Real.exp (-R * t) * |t * Real.sin R + Real.cos R|
      ≤ Real.exp (-R * t) * (2 * (1 + t ^ 2)) := by
        apply mul_le_mul_of_nonneg_left _ he.le
        nlinarith [sq_nonneg t]
    _ = 2 * Real.exp (-R * t) * (1 + t ^ 2) := by ring

#print axioms hc_dir_bound

open MeasureTheory in
lemma hc_dir_partial (R : ℝ) (hR : 0 < R) :
    (∫ x in (0 : ℝ)..R, Real.sinc x) = Real.pi / 2 -
      ∫ t in Set.Ioi (0 : ℝ), Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2) := by
  have hk : IntegrableOn (fun t : ℝ =>
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) (Set.Ioi 0) := by
    refine Integrable.mono' ((exp_neg_integrableOn_Ioi 0 hR).const_mul 2) ?_
      (Eventually.of_forall fun t => hc_dir_bound R t)
    exact (Continuous.div (by fun_prop) (by fun_prop) (fun t => by positivity) : Continuous fun t : ℝ =>
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)).aestronglyMeasurable
  rw [intervalIntegral.integral_of_le hR.le]
  calc (∫ x in Set.Ioc 0 R, Real.sinc x)
      = ∫ x in Set.Ioc 0 R, ∫ t in Set.Ioi (0 : ℝ), Real.sin x * Real.exp (-x * t) := by
        refine setIntegral_congr_fun measurableSet_Ioc (fun x hx => ?_)
        have hx0 : 0 < x := hx.1
        rw [integral_const_mul, hc_dir_inner_exp x hx0, Real.sinc_of_ne_zero hx0.ne']
        ring
    _ = ∫ t in Set.Ioi (0 : ℝ), ∫ x in Set.Ioc 0 R, Real.sin x * Real.exp (-x * t) :=
        integral_integral_swap (hc_dir_integrable R)
    _ = ∫ t in Set.Ioi (0 : ℝ), ((1 + t ^ 2)⁻¹ -
          Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) := by
        refine integral_congr_ae (Eventually.of_forall fun t => ?_)
        simp only
        rw [← intervalIntegral.integral_of_le hR.le, hc_dir_inner_sin]
        ring
    _ = Real.pi / 2 - ∫ t in Set.Ioi (0 : ℝ),
          Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2) := by
        rw [integral_sub integrable_inv_one_add_sq.integrableOn hk, integral_Ioi_inv_one_add_sq,
          Real.arctan_zero, sub_zero]

#print axioms hc_dir_partial

open MeasureTheory in
lemma hc_dir_half : Tendsto (fun R : ℝ => ∫ x in (0 : ℝ)..R, Real.sinc x) atTop
    (𝓝 (Real.pi / 2)) := by
  have hE : Tendsto (fun R : ℝ => ∫ t in Set.Ioi (0 : ℝ),
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) atTop (𝓝 0) := by
    have h2 : Tendsto (fun R : ℝ => 2 * R⁻¹) atTop (𝓝 0) := by
      simpa using tendsto_inv_atTop_zero.const_mul (2 : ℝ)
    refine squeeze_zero_norm' ?_ h2
    filter_upwards [eventually_gt_atTop 0] with R hR
    calc _ ≤ ∫ t in Set.Ioi (0 : ℝ), 2 * Real.exp (-R * t) :=
          norm_integral_le_of_norm_le ((exp_neg_integrableOn_Ioi 0 hR).const_mul 2)
            (Eventually.of_forall fun t => hc_dir_bound R t)
      _ = 2 * R⁻¹ := by rw [integral_const_mul, hc_dir_inner_exp R hR, one_div]
  have := hE.const_sub (Real.pi / 2)
  rw [sub_zero] at this
  refine this.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with R hR
  rw [hc_dir_partial R hR]

#print axioms hc_dir_half


/-- The area under `sinc` from 0 to `y`. -/
def hcG (y : ℝ) : ℝ := ∫ x in (0 : ℝ)..y, Real.sinc x

lemma hc_G_cont : Continuous hcG :=
  intervalIntegral.continuous_primitive (fun a b => Real.continuous_sinc.intervalIntegrable a b) 0

#print axioms hc_G_cont

lemma hc_G_neg (y : ℝ) : hcG (-y) = -hcG y := by
  have h := intervalIntegral.integral_comp_neg (a := (0 : ℝ)) (b := y) (f := Real.sinc)
  simp only [Real.sinc_neg, neg_zero] at h
  unfold hcG
  rw [intervalIntegral.integral_symm (-y) 0, h]

#print axioms hc_G_neg

lemma hc_G_lim (ξ : ℝ) :
    Tendsto (fun R : ℝ => hcG (2 * Real.pi * ξ * R)) atTop (𝓝 (Real.sign ξ * (Real.pi / 2))) := by
  rcases lt_trichotomy ξ 0 with h | h | h
  · have hc : 0 < 2 * Real.pi * (-ξ) := by have := Real.pi_pos; nlinarith
    have := (hc_dir_half.comp (tendsto_id.const_mul_atTop hc)).neg
    rw [Real.sign_of_neg h]
    convert this using 2
    · simp only [Function.comp, id]
      rename_i x
      have hx : 2 * Real.pi * ξ * x = -(2 * Real.pi * (-ξ) * x) := by ring
      rw [hx, hc_G_neg]; rfl
    · ring
  · subst h
    simp only [Real.sign_zero, zero_mul, mul_zero]
    have : hcG 0 = 0 := by simp [hcG]
    rw [this]
    exact tendsto_const_nhds
  · have hc : 0 < 2 * Real.pi * ξ := by have := Real.pi_pos; positivity
    rw [Real.sign_of_pos h, one_mul]
    exact hc_dir_half.comp (tendsto_id.const_mul_atTop hc)

#print axioms hc_G_lim

lemma hc_real_part (ξ ε R : ℝ) (hε : 0 < ε) (hεR : ε < R) :
    (∫ x in ε..R, Real.sin (2 * Real.pi * ξ * x) / x) =
      hcG (2 * Real.pi * ξ * R) - hcG (2 * Real.pi * ξ * ε) := by
  set c := 2 * Real.pi * ξ with hcdef
  have h1 : (∫ x in ε..R, Real.sin (c * x) / x) = ∫ x in ε..R, c * Real.sinc (c * x) := by
    refine intervalIntegral.integral_congr fun x hx => ?_
    have hx0 : 0 < x := by
      rw [Set.uIcc_of_le hεR.le] at hx; linarith [hx.1]
    by_cases hc : c = 0
    · simp [hc]
    · rw [Real.sinc_of_ne_zero (mul_ne_zero hc hx0.ne')]
      field_simp
  rw [h1, intervalIntegral.integral_const_mul, intervalIntegral.mul_integral_comp_mul_left]
  unfold hcG
  rw [intervalIntegral.integral_interval_sub_left (Real.continuous_sinc.intervalIntegrable _ _)
    (Real.continuous_sinc.intervalIntegrable _ _)]

#print axioms hc_real_part

lemma hc_pointwise (ξ x : ℝ) (hx : x ≠ 0) :
    exp (-(2 * Real.pi * I * ξ * ((-x : ℝ) : ℂ))) / (Real.pi * ((-x : ℝ) : ℂ)) +
      exp (-(2 * Real.pi * I * ξ * x)) / (Real.pi * x) =
      (-2 * I / Real.pi) * ((Real.sin (2 * Real.pi * ξ * x) / x : ℝ) : ℂ) := by
  have e1 : exp (-(2 * Real.pi * I * ξ * ((-x : ℝ) : ℂ))) = exp (2 * Real.pi * I * ξ * x) := by
    congr 1; push_cast; ring
  have e2 : exp (-(2 * Real.pi * I * ξ * x)) = (exp (2 * Real.pi * I * ξ * x))⁻¹ := by
    rw [Complex.exp_neg]
  rw [e1, e2, Complex.ofReal_div, hc_sin]
  have hE : exp (2 * Real.pi * I * ξ * x) ≠ 0 := Complex.exp_ne_zero _
  have hx' : (x : ℂ) ≠ 0 := by exact_mod_cast hx
  have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  push_cast
  field_simp
  ring_nf
  rw [I_sq]
  ring

#print axioms hc_pointwise

lemma hc_contOn (ξ a b : ℝ) (h : ∀ t ∈ Set.Icc a b, t ≠ 0) :
    ContinuousOn (fun t : ℝ => exp (-(2 * Real.pi * I * ξ * t)) / (Real.pi * t)) (Set.Icc a b) := by
  refine ContinuousOn.div (by fun_prop) (by fun_prop) fun t ht => ?_
  have : (t : ℂ) ≠ 0 := by exact_mod_cast h t ht
  have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  exact mul_ne_zero hpi this

#print axioms hc_contOn

lemma hc_pieces (ξ ε R : ℝ) (hε : 0 < ε) (hεR : ε < R) :
    (∫ t in {t : ℝ | ε < |t| ∧ |t| < R}, exp (-(2 * Real.pi * I * ξ * t)) / (Real.pi * t)) =
      (-2 * I / Real.pi) * ((hcG (2 * Real.pi * ξ * R) - hcG (2 * Real.pi * ξ * ε) : ℝ) : ℂ) := by
  set f : ℝ → ℂ := fun t => exp (-(2 * Real.pi * I * ξ * t)) / (Real.pi * t) with hf
  have hset : {t : ℝ | ε < |t| ∧ |t| < R} = Set.Ioo (-R) (-ε) ∪ Set.Ioo ε R := by
    ext t
    simp only [Set.mem_ofPred_eq, Set.mem_union, Set.mem_Ioo, lt_abs, abs_lt]
    constructor
    · rintro ⟨h1 | h1, h2, h3⟩
      · right; exact ⟨h1, h3⟩
      · left; exact ⟨h2, by linarith⟩
    · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩)
      · exact ⟨Or.inr (by linarith), h1, by linarith⟩
      · exact ⟨Or.inl h1, by linarith, h2⟩
  have hc1 : ContinuousOn f (Set.Icc (-R) (-ε)) :=
    hc_contOn ξ _ _ fun t ht => by linarith [ht.2]
  have hc2 : ContinuousOn f (Set.Icc ε R) :=
    hc_contOn ξ _ _ fun t ht => by linarith [ht.1]
  have hc2' : ContinuousOn (fun x => f (-x)) (Set.Icc ε R) := by
    have : ContinuousOn f (Set.Icc (-R) (-ε)) := hc1
    refine this.comp continuousOn_neg fun x hx => ?_
    exact ⟨by linarith [hx.2], by linarith [hx.1]⟩
  have hdisj : Disjoint (Set.Ioo (-R) (-ε)) (Set.Ioo ε R) :=
    Set.disjoint_left.mpr fun x h1 h2 => by linarith [h1.2, h2.1]
  rw [hset, setIntegral_union hdisj measurableSet_Ioo
    ((hc1.integrableOn_Icc).mono_set Set.Ioo_subset_Icc_self)
    ((hc2.integrableOn_Icc).mono_set Set.Ioo_subset_Icc_self),
    ← integral_Ioc_eq_integral_Ioo, ← integral_Ioc_eq_integral_Ioo,
    ← intervalIntegral.integral_of_le (by linarith), ← intervalIntegral.integral_of_le hεR.le,
    ← intervalIntegral.integral_comp_neg,
    ← intervalIntegral.integral_add
      (hc2'.intervalIntegrable_of_Icc hεR.le) (hc2.intervalIntegrable_of_Icc hεR.le),
    ← hc_real_part ξ ε R hε hεR, ← intervalIntegral.integral_ofReal,
    ← intervalIntegral.integral_const_mul]
  refine intervalIntegral.integral_congr fun x hx => ?_
  have hx0 : 0 < x := by
    rw [Set.uIcc_of_le hεR.le] at hx; linarith [hx.1]
  exact hc_pointwise ξ x hx0.ne'

#print axioms hc_pieces


/-- **Envelope of an AM wave (Bedrosian).** Let the height `A(t)` be a real message made of
finitely many frequencies, every one of them below the carrier frequency `ξ_c` in size, and let
the height stay positive. Then the signal is `A(t) cos(2π ξ_c t)`, its analytic signal is
`A(t) e^(2πi ξ_c t)`, so its size, the envelope, is `A(t)` and its phase is `2π ξ_c t`. -/
theorem am_analytic_signal_envelope (a : ι → ℂ) (ν : ι → ℝ) (ξc : ℝ) (A : ℝ → ℝ)
    (hA : ∀ t, (A t : ℂ) = trigSignal a ν t)
    (hfreq : ∀ k, |ν k| < ξc)
    (hpos : ∀ t, 0 < A t) (t : ℝ) :
    trigSignal (amCoeff a) (amFreq ν ξc) t = A t * Real.cos (2 * Real.pi * ξc * t) ∧
    analyticSignal (amCoeff a) (amFreq ν ξc) t = A t * exp (2 * Real.pi * I * ξc * t) ∧
    ‖analyticSignal (amCoeff a) (amFreq ν ξc) t‖ = A t := by
  have hAn : analyticSignal (amCoeff a) (amFreq ν ξc) t = A t * exp (2 * Real.pi * I * ξc * t) := by
    rw [hA]
    simp only [analyticSignal, trigSignal, hilbert, Fintype.sum_sum_type, amCoeff, amFreq,
      Sum.elim_inl, Sum.elim_inr, hc_exp_add_freq, hc_exp_sub_freq, Finset.sum_mul, mul_add,
      Finset.mul_sum, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun k _ => ?_
    have h1 : 0 < ν k + ξc := by linarith [neg_abs_le (ν k), hfreq k]
    have h2 : ν k - ξc < 0 := by linarith [le_abs_self (ν k), hfreq k]
    rw [Real.sign_of_pos h1, Real.sign_of_neg h2]
    have hE : exp (2 * Real.pi * I * ξc * t) ≠ 0 := Complex.exp_ne_zero _
    field_simp
    push_cast
    ring_nf
    rw [I_sq]
    ring
  refine ⟨?_, hAn, ?_⟩
  · rw [hA, hc_cos]
    simp only [trigSignal, Fintype.sum_sum_type, amCoeff, amFreq, Sum.elim_inl, Sum.elim_inr,
      hc_exp_add_freq, hc_exp_sub_freq, Finset.sum_mul, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun k _ => ?_
    ring
  · rw [hAn, norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_pos (hpos t)]
    have : 2 * Real.pi * I * ξc * t = ((2 * Real.pi * ξc * t : ℝ) : ℂ) * I := by push_cast; ring
    rw [this, Complex.norm_exp_ofReal_mul_I, mul_one]

/-- **The kernel has the quarter-turn multiplier.** Cut the kernel `1/(π t)` to `ε < |t| < R`,
equal gaps on both sides of 0. Its Fourier transform at `ξ` hertz tends to `-i sgn(ξ)` as `ε`
shrinks to 0 and `R` grows without bound. -/
theorem pv_kernel_transform_eq_neg_I_sign (ξ : ℝ) :
    Tendsto (fun p : ℝ × ℝ =>
        ∫ t in {t : ℝ | p.1 < |t| ∧ |t| < p.2},
          exp (-(2 * Real.pi * I * ξ * t)) / (Real.pi * t))
      (𝓝[>] (0 : ℝ) ×ˢ atTop) (𝓝 (-I * (Real.sign ξ : ℂ))) := by
  have h1 : Tendsto (fun p : ℝ × ℝ => hcG (2 * Real.pi * ξ * p.2)) (𝓝[>] (0 : ℝ) ×ˢ atTop)
      (𝓝 (Real.sign ξ * (Real.pi / 2))) := (hc_G_lim ξ).comp tendsto_snd
  have h2 : Tendsto (fun p : ℝ × ℝ => hcG (2 * Real.pi * ξ * p.1)) (𝓝[>] (0 : ℝ) ×ˢ atTop)
      (𝓝 0) := by
    have hc : Continuous fun e : ℝ => hcG (2 * Real.pi * ξ * e) :=
      hc_G_cont.comp (continuous_const_mul _)
    have h0 : hcG (2 * Real.pi * ξ * 0) = 0 := by simp [hcG]
    have := (hc.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    rw [h0] at this
    exact this.comp tendsto_fst
  have key := ((Complex.continuous_ofReal.tendsto _).comp (h1.sub h2)).const_mul
    (-2 * I / (Real.pi : ℂ))
  have hlim : (-2 * I / (Real.pi : ℂ)) * ((Real.sign ξ * (Real.pi / 2) - 0 : ℝ) : ℂ) =
      -I * (Real.sign ξ : ℂ) := by
    have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    push_cast
    field_simp
    ring
  rw [hlim] at key
  refine key.congr' ?_
  have e1 : ∀ᶠ p : ℝ × ℝ in 𝓝[>] (0 : ℝ) ×ˢ atTop, p.1 ∈ Set.Ioo 0 1 :=
    Eventually.prod_inl (Ioo_mem_nhdsGT one_pos) _
  have e2 : ∀ᶠ p : ℝ × ℝ in 𝓝[>] (0 : ℝ) ×ˢ atTop, 1 < p.2 :=
    Eventually.prod_inr (eventually_gt_atTop 1) _
  filter_upwards [e1, e2] with p hp1 hp2
  exact (hc_pieces ξ p.1 p.2 hp1.1 (by linarith [hp1.2])).symm

/-- **The multiplier turns cosines into sines.** For a frequency `ξ₀ > 0`, the cosine
`cos(2π ξ₀ t)` is the two arrows `1/2` at `±ξ₀`, and its Hilbert transform is `sin(2π ξ₀ t)`;
the sine is the two arrows `∓i/2` at `±ξ₀`, and its Hilbert transform is `-cos(2π ξ₀ t)`. -/
theorem hilbert_cos_eq_sin_and_hilbert_sin_eq_neg_cos (ξ₀ : ℝ) (hξ : 0 < ξ₀) (t : ℝ) :
    trigSignal ![1 / 2, 1 / 2] ![ξ₀, -ξ₀] t = Real.cos (2 * Real.pi * ξ₀ * t) ∧
    hilbert ![1 / 2, 1 / 2] ![ξ₀, -ξ₀] t = Real.sin (2 * Real.pi * ξ₀ * t) ∧
    trigSignal ![-I / 2, I / 2] ![ξ₀, -ξ₀] t = Real.sin (2 * Real.pi * ξ₀ * t) ∧
    hilbert ![-I / 2, I / 2] ![ξ₀, -ξ₀] t = -Real.cos (2 * Real.pi * ξ₀ * t) := by
  have hE : exp (2 * Real.pi * I * ξ₀ * t) ≠ 0 := Complex.exp_ne_zero _
  simp only [trigSignal, hilbert, Fin.sum_univ_two, Matrix.cons_val_zero, Matrix.cons_val_one,
    hc_exp_neg_freq, hc_cos, hc_sin, Real.sign_of_pos hξ,
    Real.sign_of_neg (neg_neg_of_pos hξ)]
  refine ⟨?_, ?_, ?_, ?_⟩ <;>
  · field_simp
    try push_cast
    try ring_nf
    try rw [I_sq]
    try ring



-- The radio signal's mean square by hand: (1 + 2 × 0.25²)/2 = 0.5625 V².
example : ((1 : ℚ) + 2 * (1 / 4) ^ 2) / 2 = 9 / 16 := by norm_num
-- The worked instant t = 200.125 µs is sample 1601 at 8 MHz.
example : (200125 / 10 ^ 9 : ℚ) * 8000000 = 1601 := by norm_num
-- The tone's angle there: 360° × 1000 Hz × 0.000200125 s = 72.045°.
example : (360 : ℚ) * 1000 * (200125 / 10 ^ 9) = 14409 / 200 := by norm_num
-- The carrier's angle: 360° × 1,000,000 Hz × 0.000200125 s = 72045°, which is 45° past whole turns.
example : (360 : ℚ) * 1000000 * (200125 / 10 ^ 9) = 72045 := by norm_num
example : 72045 % 360 = 45 := by norm_num
-- Overmodulation at 500 µs, where the tone's cosine is -1: the height is 1 + 1.5 × (-1) = -0.5 V.
example : (1 : ℚ) + 3 / 2 * (-1) = -1 / 2 := by norm_num
-- The tone's frequencies -1, 0, 1 kHz land at 999, 1000, 1001 kHz on the 1000 kHz carrier.
example : ((-1 : ℤ) + 1000, (0 : ℤ) + 1000, (1 : ℤ) + 1000) = (999, 1000, 1001) := by norm_num
-- The record of 8000 samples splits into factors of 2 and 5 for the fast transform.
example : (8000 : ℕ) = 2 ^ 6 * 5 ^ 3 := by norm_num

#print axioms am_analytic_signal_envelope
#print axioms pv_kernel_transform_eq_neg_I_sign
#print axioms hilbert_cos_eq_sin_and_hilbert_sin_eq_neg_cos
