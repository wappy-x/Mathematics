-- Pricing by transform: a European call's price, the payoff paired with the law of the log return, equals the damped payoff's Fourier transform paired with the fingerprint on the shifted line a + 2πiξ, and the damped payoff's transform has a closed form.
import Mathlib.Analysis.Fourier.FourierTransform
import Mathlib.Analysis.Fourier.Inversion
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Data.Finset.Interval

open MeasureTheory Complex Real
open scoped FourierTransform

theorem cm_damped_payoff_eq_indicator (S K a : ℝ) (hS : 0 < S) (hK : 0 < K) :
    (fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)) =
      Set.indicator (Set.Ioi (Real.log (K / S)))
        (fun x : ℝ => (S : ℂ) * Complex.exp (((1 - a : ℝ) : ℂ) * x) -
          (K : ℂ) * Complex.exp (((-a : ℝ) : ℂ) * x)) := by
  funext x
  have hkey : S * Real.exp x - K > 0 ↔ Real.log (K / S) < x := by
    rw [Real.log_lt_iff_lt_exp (div_pos hK hS), div_lt_iff₀ hS]
    constructor <;> intro h <;> linarith
  by_cases hx : Real.log (K / S) < x
  · rw [Set.indicator_of_mem (Set.mem_Ioi.mpr hx), max_eq_left (hkey.mpr hx).le]
    push_cast
    simp only [sub_mul, one_mul, neg_mul, Complex.exp_sub, Complex.exp_neg]
    ring
  · rw [Set.indicator_of_notMem (by simpa using hx), max_eq_right (by
      by_contra h; exact hx (hkey.mp (lt_of_not_ge h)))]
    simp

theorem cm_damped_payoff_integrable (S K a : ℝ) (hS : 0 < S) (hK : 0 < K) (ha : 1 < a) :
    Integrable (fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)) := by
  rw [cm_damped_payoff_eq_indicator S K a hS hK, integrable_indicator_iff measurableSet_Ioi]
  refine Integrable.sub (Integrable.const_mul ?_ _) (Integrable.const_mul ?_ _)
  · exact integrableOn_exp_mul_complex_Ioi (by simp; linarith) _
  · exact integrableOn_exp_mul_complex_Ioi (by simp; linarith) _

theorem cm_damped_payoff_continuous (S K a : ℝ) :
    Continuous (fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)) := by
  fun_prop

theorem cm_fourier_closed_form (S K a : ℝ)
    (hS : 0 < S) (hK : 0 < K) (ha : 1 < a) (ξ : ℝ) :
    𝓕 (fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)) ξ =
      (S * Real.exp ((1 - a) * Real.log (K / S)) : ℂ) *
          Complex.exp (-(2 * π * I * ξ * Real.log (K / S))) /
        (((a - 1 : ℂ) + 2 * π * I * ξ) * ((a : ℂ) + 2 * π * I * ξ)) := by
  set k := Real.log (K / S) with hk
  have hKk : (K : ℂ) = (S : ℂ) * Complex.exp (k : ℂ) := by
    rw [← Complex.ofReal_exp, hk, Real.exp_log (div_pos hK hS)]
    have hS' : (S : ℂ) ≠ 0 := by exact_mod_cast hS.ne'
    push_cast; field_simp
  rw [cm_damped_payoff_eq_indicator S K a hS hK, fourier_real_eq_integral_exp_smul]
  have h1 : ∀ v : ℝ, Complex.exp (↑(-2 * π * v * ξ) * I) •
      Set.indicator (Set.Ioi k) (fun x : ℝ => (S : ℂ) * Complex.exp (((1 - a : ℝ) : ℂ) * x) -
          (K : ℂ) * Complex.exp (((-a : ℝ) : ℂ) * x)) v =
      Set.indicator (Set.Ioi k) (fun x : ℝ =>
        (S : ℂ) * Complex.exp (((1 - a : ℂ) - 2 * π * I * ξ) * x) -
          (K : ℂ) * Complex.exp ((-(a : ℂ) - 2 * π * I * ξ) * x)) v := by
    intro v
    by_cases hv : v ∈ Set.Ioi k
    · rw [Set.indicator_of_mem hv, Set.indicator_of_mem hv, smul_eq_mul, mul_sub, mul_left_comm,
        mul_left_comm (Complex.exp _) (K : ℂ), ← Complex.exp_add, ← Complex.exp_add]
      congr 3 <;> push_cast <;> ring
    · rw [Set.indicator_of_notMem hv, Set.indicator_of_notMem hv, smul_zero]
  rw [integral_congr_ae (Filter.Eventually.of_forall h1)]
  rw [integral_indicator measurableSet_Ioi, integral_sub, integral_const_mul, integral_const_mul,
    integral_exp_mul_complex_Ioi, integral_exp_mul_complex_Ioi]
  rotate_left
  · simp; linarith
  · simp; linarith
  · exact (integrableOn_exp_mul_complex_Ioi (by simp; linarith) _).const_mul _
  · exact (integrableOn_exp_mul_complex_Ioi (by simp; linarith) _).const_mul _
  have hd1 : ((a - 1 : ℂ) + 2 * π * I * ξ) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this; linarith
  have hd2 : ((a : ℂ) + 2 * π * I * ξ) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this; linarith
  have e1 : Complex.exp (((1 - a : ℂ) - 2 * π * I * ξ) * k) =
      (Real.exp ((1 - a) * k) : ℂ) * Complex.exp (-(2 * π * I * ξ * k)) := by
    rw [Complex.ofReal_exp, ← Complex.exp_add]; congr 1; push_cast; ring
  have e2 : (K : ℂ) * Complex.exp ((-(a : ℂ) - 2 * π * I * ξ) * k) =
      (S : ℂ) * ((Real.exp ((1 - a) * k) : ℂ) * Complex.exp (-(2 * π * I * ξ * k))) := by
    rw [hKk, Complex.ofReal_exp, mul_assoc, ← Complex.exp_add, ← Complex.exp_add]
    congr 2; push_cast; ring
  rw [neg_div, neg_div, mul_neg, mul_neg, mul_div_assoc', mul_div_assoc', e2, e1]
  have hd1' : ((1 - a : ℂ) - 2 * π * I * ξ) = -((a - 1 : ℂ) + 2 * π * I * ξ) := by ring
  have hd2' : (-(a : ℂ) - 2 * π * I * ξ) = -((a : ℂ) + 2 * π * I * ξ) := by ring
  rw [hd1', hd2']
  push_cast
  field_simp
  ring

theorem cm_closed_form_integrable (S K a : ℝ) (hS : 0 < S) (hK : 0 < K) (ha : 1 < a) :
    Integrable (fun ξ : ℝ => (S * Real.exp ((1 - a) * Real.log (K / S)) : ℂ) *
          Complex.exp (-(2 * π * I * ξ * Real.log (K / S))) /
        (((a - 1 : ℂ) + 2 * π * I * ξ) * ((a : ℂ) + 2 * π * I * ξ))) := by
  set k := Real.log (K / S)
  set C0 : ℝ := S * Real.exp ((1 - a) * k)
  have hC0 : 0 ≤ C0 := by positivity
  set m : ℝ := min ((a - 1) ^ 2) 1
  have hm : 0 < m := lt_min (by nlinarith) one_pos
  refine Integrable.mono' (integrable_inv_one_add_sq.const_mul (C0 / m)) ?_ ?_
  · apply Measurable.aestronglyMeasurable
    fun_prop
  · refine Filter.Eventually.of_forall (fun ξ => ?_)
    have hE : ‖Complex.exp (-(2 * π * I * ξ * k))‖ = 1 := by
      rw [Complex.norm_exp]; simp
    have hz1 : ‖((a - 1 : ℂ) + 2 * π * I * ξ)‖ ^ 2 = (a - 1) ^ 2 + (2 * π * ξ) ^ 2 := by
      rw [Complex.sq_norm, Complex.normSq_apply]; simp; ring
    have hz2 : ‖((a : ℂ) + 2 * π * I * ξ)‖ ^ 2 = a ^ 2 + (2 * π * ξ) ^ 2 := by
      rw [Complex.sq_norm, Complex.normSq_apply]; simp; ring
    have hD : (a - 1) ^ 2 + (2 * π * ξ) ^ 2 ≤
        ‖((a - 1 : ℂ) + 2 * π * I * ξ)‖ * ‖((a : ℂ) + 2 * π * I * ξ)‖ := by
      have hsq : ((a - 1) ^ 2 + (2 * π * ξ) ^ 2) ^ 2 ≤
          (‖((a - 1 : ℂ) + 2 * π * I * ξ)‖ * ‖((a : ℂ) + 2 * π * I * ξ)‖) ^ 2 := by
        rw [mul_pow (‖((a - 1 : ℂ) + 2 * π * I * ξ)‖) _ 2, hz1, hz2]
        have : (a - 1) ^ 2 ≤ a ^ 2 := by nlinarith
        have h0 : 0 ≤ (2 * π * ξ) ^ 2 := sq_nonneg _
        nlinarith
      exact (pow_le_pow_iff_left₀ (by positivity) (by positivity) two_ne_zero).mp hsq
    have hpi : 2 ≤ π := Real.two_le_pi
    have hm1 : m ≤ (a - 1) ^ 2 := min_le_left _ _
    have hm2 : m ≤ 1 := min_le_right _ _
    have hlow : m * (1 + ξ ^ 2) ≤ (a - 1) ^ 2 + (2 * π * ξ) ^ 2 := by
      have h0 : 0 ≤ ξ ^ 2 := sq_nonneg _
      have : 1 ≤ (2 * π) ^ 2 := by nlinarith
      nlinarith
    have hpos : 0 < m * (1 + ξ ^ 2) := by positivity
    rw [norm_div, norm_mul, norm_mul, hE, mul_one, norm_mul, Complex.norm_real,
      Complex.norm_real, Real.norm_of_nonneg hS.le, Real.norm_of_nonneg (Real.exp_pos _).le]
    calc C0 / (‖((a - 1 : ℂ) + 2 * π * I * ξ)‖ * ‖((a : ℂ) + 2 * π * I * ξ)‖)
        ≤ C0 / (m * (1 + ξ ^ 2)) := div_le_div_of_nonneg_left hC0 hpos (hlow.trans hD)
      _ = C0 / m * (1 + ξ ^ 2)⁻¹ := by rw [div_mul_eq_div_div, div_eq_mul_inv (C0 / m)]

theorem cm_pair_integrable (μ : Measure ℝ) [IsProbabilityMeasure μ] (a : ℝ) (G : ℝ → ℂ)
    (hG : Integrable G) (hM : Integrable (fun x : ℝ => Real.exp (a * x)) μ) :
    Integrable (Function.uncurry fun (x ξ : ℝ) => G ξ * Complex.exp ((a + 2 * π * I * ξ) * x))
      (μ.prod volume) := by
  have hM' : Integrable (fun x : ℝ => ((Real.exp (a * x) : ℝ) : ℂ)) μ := hM.ofReal
  refine (hM'.mul_prod hG).mono ?_ (Filter.Eventually.of_forall (fun z => le_of_eq ?_))
  · refine AEStronglyMeasurable.mul hG.aestronglyMeasurable.comp_snd ?_
    exact (by fun_prop : Continuous fun z : ℝ × ℝ =>
      Complex.exp ((a + 2 * π * I * z.2) * z.1)).aestronglyMeasurable
  · rcases z with ⟨x, ξ⟩
    simp only [Function.uncurry_apply_pair, norm_mul, Complex.norm_exp, Complex.norm_real,
      Real.norm_of_nonneg (Real.exp_pos _).le]
    rw [mul_comm]
    congr 2
    simp

theorem cm_transform_integrable (S K a : ℝ) (hS : 0 < S) (hK : 0 < K) (ha : 1 < a) :
    Integrable (𝓕 (fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ))) := by
  rw [show 𝓕 (fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)) = _ from
    funext (cm_fourier_closed_form S K a hS hK ha)]
  exact cm_closed_form_integrable S K a hS hK ha

#print axioms cm_damped_payoff_eq_indicator
#print axioms cm_damped_payoff_integrable
#print axioms cm_damped_payoff_continuous
#print axioms cm_fourier_closed_form
#print axioms cm_closed_form_integrable
#print axioms cm_pair_integrable
#print axioms cm_transform_integrable

/-- **The pricing identity (Carr-Madan, Lewis).** Let `μ` be the pricing-world law of the log
return `X = ln(S_T/S)`, with today's price `S > 0`, strike `K > 0`, rate `r`, dividend yield `q`
and time to expiry `T`, so that `E[e^X] = e^((r-q)T)`. If the damping exponent satisfies `a > 1`
and the tilted law has finite size, `M(a) = E[e^(aX)] < ∞`, then the call price
`C(K) = e^(-rT) E[(S e^X - K)^+]` equals `e^(-rT)` times the integral over all frequencies `ξ`
of the Fourier transform of the damped payoff `g_K(x) = e^(-ax) (S e^x - K)^+` times the
fingerprint read on the shifted line, `M(a + 2πiξ) = E[e^((a + 2πiξ)X)]`. -/
theorem call_price_eq_damped_payoff_transform_paired_with_fingerprint
    (μ : Measure ℝ) [IsProbabilityMeasure μ] (S K r q T a : ℝ)
    (hS : 0 < S) (hK : 0 < K) (ha : 1 < a)
    (hM : Integrable (fun x : ℝ => Real.exp (a * x)) μ)
    (hpricing : ∫ x, Real.exp x ∂μ = Real.exp ((r - q) * T)) :
    (((Real.exp (-r * T) * ∫ x, max (S * Real.exp x - K) 0 ∂μ : ℝ)) : ℂ) =
      (Real.exp (-r * T) : ℂ) *
        ∫ ξ : ℝ, 𝓕 (fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)) ξ *
          ∫ x, Complex.exp ((a + 2 * π * I * ξ) * x) ∂μ := by
  set g : ℝ → ℂ := fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)
    with hg
  have hgi : Integrable g := cm_damped_payoff_integrable S K a hS hK ha
  have hgc : Continuous g := cm_damped_payoff_continuous S K a
  have hFi : Integrable (𝓕 g) := cm_transform_integrable S K a hS hK ha
  have hprod := cm_pair_integrable μ a (𝓕 g) hFi hM
  have hpt : ∀ x : ℝ, ((max (S * Real.exp x - K) 0 : ℝ) : ℂ) =
      ∫ ξ : ℝ, 𝓕 g ξ * Complex.exp ((a + 2 * π * I * ξ) * x) := by
    intro x
    have hinv := congrFun (hgc.fourierInv_fourier_eq hgi hFi) x
    rw [fourierInv_eq'] at hinv
    have hmx : ((max (S * Real.exp x - K) 0 : ℝ) : ℂ) = Complex.exp (a * x) * g x := by
      simp only [hg]
      push_cast
      rw [← mul_assoc, ← Complex.exp_add]
      simp
    rw [hmx, ← hinv, ← integral_const_mul]
    congr 1
    funext ξ
    rw [smul_eq_mul, ← mul_assoc, ← Complex.exp_add, mul_comm (𝓕 g ξ)]
    congr 2
    rw [Real.inner_apply]
    push_cast
    ring
  rw [Complex.ofReal_mul, ← integral_complex_ofReal]
  congr 1
  simp_rw [hpt]
  rw [integral_integral_swap hprod]
  congr 1
  funext ξ
  rw [integral_const_mul]

/-- **The damped payoff's transform, by hand.** For `S > 0`, `K > 0`, `a > 1` and log strike
`k = ln(K/S)`, the Fourier transform of `g_K(x) = e^(-ax) (S e^x - K)^+` at frequency `ξ` is
`S e^((1-a)k) e^(-2πiξk) / ((a - 1 + 2πiξ)(a + 2πiξ))`. -/
theorem damped_call_payoff_fourier_transform (S K a : ℝ)
    (hS : 0 < S) (hK : 0 < K) (ha : 1 < a) (ξ : ℝ) :
    𝓕 (fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)) ξ =
      (S * Real.exp ((1 - a) * Real.log (K / S)) : ℂ) *
          Complex.exp (-(2 * π * I * ξ * Real.log (K / S))) /
        (((a - 1 : ℂ) + 2 * π * I * ξ) * ((a : ℂ) + 2 * π * I * ξ)) := by
  exact cm_fourier_closed_form S K a hS hK ha ξ

/-- **Every strike from one strike-free array.** Under the same hypotheses, put
`Ψ(ξ) = S e^(-rT) M(a + 2πiξ) / ((a - 1 + 2πiξ)(a + 2πiξ))`, which does not depend on the strike.
Then with log strike `k = ln(K/S)` the call price is
`C(K) = 2 e^((1-a)k) Re ∫_0^∞ Ψ(ξ) e^(-2πiξk) dξ`: the strike only turns a phase and undoes the
damping, and half the frequency line suffices. -/
theorem call_price_eq_strike_free_half_line_formula
    (μ : Measure ℝ) [IsProbabilityMeasure μ] (S K r q T a : ℝ)
    (hS : 0 < S) (hK : 0 < K) (ha : 1 < a)
    (hM : Integrable (fun x : ℝ => Real.exp (a * x)) μ)
    (hpricing : ∫ x, Real.exp x ∂μ = Real.exp ((r - q) * T)) :
    Real.exp (-r * T) * ∫ x, max (S * Real.exp x - K) 0 ∂μ =
      2 * Real.exp ((1 - a) * Real.log (K / S)) *
        (∫ ξ in Set.Ioi (0 : ℝ),
          ((S * Real.exp (-r * T) : ℝ) : ℂ) *
              (∫ x, Complex.exp ((a + 2 * π * I * ξ) * x) ∂μ) /
              (((a - 1 : ℂ) + 2 * π * I * ξ) * ((a : ℂ) + 2 * π * I * ξ)) *
            Complex.exp (-(2 * π * I * ξ * Real.log (K / S)))).re := by
  have h1 := call_price_eq_damped_payoff_transform_paired_with_fingerprint μ S K r q T a hS hK ha
    hM hpricing
  set k := Real.log (K / S) with hk
  set g : ℝ → ℂ := fun x : ℝ => ((Real.exp (-a * x) * max (S * Real.exp x - K) 0 : ℝ) : ℂ)
    with hg
  have hFi : Integrable (𝓕 g) := cm_transform_integrable S K a hS hK ha
  have hprod := cm_pair_integrable μ a (𝓕 g) hFi hM
  set M : ℝ → ℂ := fun ξ : ℝ => ∫ x, Complex.exp ((a + 2 * π * I * ξ) * x) ∂μ with hMdef
  have hGM : Integrable (fun ξ : ℝ => 𝓕 g ξ * M ξ) := by
    refine hprod.integral_prod_right.congr (Filter.Eventually.of_forall fun ξ => ?_)
    simp only [Function.uncurry_apply_pair, hMdef]
    exact integral_const_mul _ _
  set F : ℝ → ℂ := fun ξ : ℝ => ((S * Real.exp (-r * T) : ℝ) : ℂ) * M ξ /
      (((a - 1 : ℂ) + 2 * π * I * ξ) * ((a : ℂ) + 2 * π * I * ξ)) *
      Complex.exp (-(2 * π * I * ξ * k)) with hFdef
  set P : ℂ := ((Real.exp ((1 - a) * k) : ℝ) : ℂ) with hPdef
  have hP : P ≠ 0 := by rw [hPdef]; exact Complex.ofReal_ne_zero.mpr (Real.exp_pos _).ne'
  have hpt : ∀ ξ : ℝ, (Real.exp (-r * T) : ℂ) * (𝓕 g ξ * M ξ) = P * F ξ := by
    intro ξ
    rw [cm_fourier_closed_form S K a hS hK ha ξ]
    simp only [hFdef, hPdef]
    push_cast
    ring
  have hFint : Integrable F := by
    refine (hGM.const_mul ((Real.exp (-r * T) : ℂ) / P)).congr
      (Filter.Eventually.of_forall fun ξ => ?_)
    simp only
    rw [div_mul_eq_mul_div, hpt ξ]
    field_simp
  have hMc : ∀ ξ : ℝ, M (-ξ) = (starRingEnd ℂ) (M ξ) := by
    intro ξ
    simp only [hMdef]
    rw [← integral_conj]
    congr 1
    funext x
    rw [← Complex.exp_conj]
    congr 1
    simp only [map_mul, map_add, Complex.conj_ofReal, Complex.conj_I, map_ofNat]
    push_cast
    ring
  have hsym : ∀ ξ : ℝ, F (-ξ) = (starRingEnd ℂ) (F ξ) := by
    intro ξ
    simp only [hFdef]
    rw [hMc ξ]
    simp only [map_mul, map_div₀, map_add, map_sub, map_neg, Complex.conj_ofReal, Complex.conj_I,
      ← Complex.exp_conj, map_ofNat, map_one]
    push_cast
    ring_nf
  have hsplit : ∫ ξ, F ξ =
      (∫ ξ in Set.Ioi (0 : ℝ), F ξ) + (starRingEnd ℂ) (∫ ξ in Set.Ioi (0 : ℝ), F ξ) := by
    rw [← integral_add_compl measurableSet_Ioi hFint, Set.compl_Ioi, ← integral_conj]
    congr 1
    have := integral_comp_neg_Ioi 0 F
    rw [neg_zero] at this
    rw [← this]
    congr 1
    funext ξ
    exact hsym ξ
  have hmain : ((Real.exp (-r * T) * ∫ x, max (S * Real.exp x - K) 0 ∂μ : ℝ) : ℂ) =
      P * ∫ ξ, F ξ := by
    rw [h1, ← integral_const_mul, ← integral_const_mul]
    congr 1
    funext ξ
    exact hpt ξ
  rw [hsplit, Complex.add_conj] at hmain
  apply Complex.ofReal_injective
  rw [hmain, hPdef]
  push_cast
  ring

-- The card's whole-number facts: strikes every dollar from $70 to $133 are 64 strikes.
example : (Finset.Icc (70 : ℕ) 133).card = 64 := by decide

-- One pass needs 512 fingerprint values; strike by strike would need 64 × 512 = 32,768.
example : (64 : ℕ) * 512 = 32768 := by norm_num

-- 512 samples at step 1/64 put the cut-off at Ξ = N h = 8.
example : (512 : ℚ) * (1 / 64) = 8 := by norm_num

#print axioms call_price_eq_damped_payoff_transform_paired_with_fingerprint
#print axioms damped_call_payoff_fourier_transform
#print axioms call_price_eq_strike_free_half_line_formula
