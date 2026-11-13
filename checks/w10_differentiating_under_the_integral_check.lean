-- Differentiating under the integral sign: if each integrand is differentiable in the parameter off one null set and one function with finite integral caps every rate on an open interval, then the integral is differentiable there with derivative the integral of the rates, as on the bakery (marginal profit £16 at £3) and the Gaussian moments.
import Mathlib.Analysis.Calculus.ParametricIntegral
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.MeasureTheory.Integral.Bochner.Set
import Mathlib.MeasureTheory.Integral.Gamma

open MeasureTheory Set Real

open Filter Topology in
/-- A real function continuous at `s` that is at most `C` at every rational point of a
neighborhood of `s` is at most `C` at `s`. -/
theorem le_of_rat_le_of_continuousAt (h : ℝ → ℝ) (s C : ℝ) (U : Set ℝ) (hU : U ∈ 𝓝 s)
    (hc : ContinuousAt h s) (hq : ∀ q : ℚ, (q : ℝ) ∈ U → h q ≤ C) : h s ≤ C := by
  by_contra hlt
  replace hlt := not_le.1 hlt
  have hV : U ∩ {y | C < h y} ∈ 𝓝 s := Filter.inter_mem hU (hc.eventually (lt_mem_nhds hlt))
  obtain ⟨V, hVsub, hVo, hsV⟩ := mem_nhds_iff.1 hV
  obtain ⟨q, hq'⟩ := Rat.denseRange_cast.exists_mem_open hVo ⟨s, hsV⟩
  have := hVsub hq'
  exact absurd (hq q this.1) (not_le.2 this.2)

#print axioms le_of_rat_le_of_continuousAt

theorem integral_Ioi_mul_exp_neg_mul (b : ℝ) (hb : 0 < b) :
    ∫ z in Ioi (0 : ℝ), z * exp (-(b * z)) = 1 / b ^ 2 := by
  have h := integral_rpow_mul_exp_neg_mul_Ioi (a := 2) two_pos hb
  norm_num at h
  rw [h]
  field_simp

#print axioms integral_Ioi_mul_exp_neg_mul

theorem integral_Ioi_sq_mul_exp_neg_mul (b : ℝ) (hb : 0 < b) :
    ∫ z in Ioi (0 : ℝ), z ^ 2 * exp (-(b * z)) = 2 / b ^ 3 := by
  have h := integral_rpow_mul_exp_neg_mul_Ioi (a := 3) (by norm_num) hb
  have hG : Gamma 3 = 2 := by
    rw [show (3 : ℝ) = (2 : ℕ) + 1 by norm_num, Real.Gamma_nat_eq_factorial]
    norm_num [Nat.factorial]
  norm_num [hG] at h
  rw [h]
  field_simp

#print axioms integral_Ioi_sq_mul_exp_neg_mul

theorem gauss_Ioi_moment (q : ℕ) :
    ∫ x in Ioi (0 : ℝ), x ^ q * exp (-x ^ 2) =
      (1 / 2) * Gamma (((q : ℝ) + 1) / 2) := by
  have h := integral_rpow_mul_exp_neg_mul_rpow (p := 2) (q := q) (b := 1) two_pos
    (by have := (Nat.cast_nonneg q : (0 : ℝ) ≤ q); linarith) one_pos
  have e : ∫ x in Ioi (0 : ℝ), x ^ (q : ℝ) * exp (-1 * x ^ (2 : ℝ)) =
      ∫ x in Ioi (0 : ℝ), x ^ q * exp (-x ^ 2) := by
    refine setIntegral_congr_fun measurableSet_Ioi fun x _ => ?_
    simp only [Real.rpow_natCast, Real.rpow_two, neg_mul, one_mul]
  rw [← e, h]
  simp

#print axioms gauss_Ioi_moment

/-- Leibniz's rule, dominated-convergence version. Let `(Ω, μ)` be any measure space, `I` an
open interval of parameters (any open, interval-shaped set of reals), and `f t x` a real
function of a parameter `t` and a point `x`. Suppose
1. for each `t` in `I`, `x ↦ f t x` is measurable and has a finite integral;
2. off one null set of points `x`, `t ↦ f t x` is differentiable at every `t` in `I`;
3. one function `g` with `∫ g dμ < ∞` caps every rate: off one null set of `x`,
   `|∂f/∂t (t, x)| ≤ g x` at every `t` in `I`.
Then at every `t` in `I` the rate `x ↦ ∂f/∂t (t, x)` has a finite integral, and
`F(t) = ∫ f t x dμ` is differentiable at `t` with `F'(t) = ∫ ∂f/∂t (t, x) dμ`. -/
theorem deriv_integral_eq_integral_deriv_of_dominated
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (I : Set ℝ) (hI_open : IsOpen I) (hI_interval : I.OrdConnected)
    (f : ℝ → Ω → ℝ) (g : Ω → ENNReal)
    (hf_meas : ∀ t ∈ I, Measurable (f t))
    (hf_fin : ∀ t ∈ I, HasFiniteIntegral (f t) μ)
    (hf_diff : ∀ᵐ x ∂μ, ∀ t ∈ I, DifferentiableAt ℝ (fun s => f s x) t)
    (hg_fin : ∫⁻ x, g x ∂μ < ⊤)
    (hbound : ∀ᵐ x ∂μ, ∀ t ∈ I, ENNReal.ofReal |deriv (fun s => f s x) t| ≤ g x) :
    ∀ t ∈ I,
      Integrable (fun x => deriv (fun s => f s x) t) μ ∧
      HasDerivAt (fun s => ∫ x, f s x ∂μ) (∫ x, deriv (fun s => f s x) t ∂μ) t := by
  classical
  intro t ht
  -- measurable majorant built from rational difference quotients
  set G : Ω → ENNReal := fun x => ⨆ p : ℚ × ℚ,
    if ((p.1 : ℝ) ∈ I ∧ (p.2 : ℝ) ∈ I) then
      ENNReal.ofReal (|f p.1 x - f p.2 x| / |(p.1 : ℝ) - p.2|) else 0 with hG
  have hGm : Measurable G := by
    refine Measurable.iSup fun p => ?_
    split_ifs with h
    · exact ENNReal.measurable_ofReal.comp
        ((continuous_abs.measurable.comp ((hf_meas _ h.1).sub (hf_meas _ h.2))).div_const _)
    · exact measurable_const
  have hconv : Convex ℝ I := hI_interval.convex
  have hGg : ∀ᵐ x ∂μ, G x ≤ g x := by
    filter_upwards [hf_diff, hbound] with x hd hb
    by_cases hgt : g x = ⊤
    · simp [hgt]
    refine iSup_le fun p => ?_
    split_ifs with h
    · apply ENNReal.ofReal_le_of_le_toReal
      have key := hconv.norm_image_sub_le_of_norm_deriv_le (f := fun s => f s x)
        (C := (g x).toReal) hd
        (fun s hs => (ENNReal.ofReal_le_iff_le_toReal hgt).1 (hb s hs)) h.2 h.1
      simp only [Real.norm_eq_abs] at key
      rcases eq_or_ne (p.1 : ℝ) p.2 with he | he
      · simp [he]
      · rw [div_le_iff₀ (abs_pos.2 (sub_ne_zero.2 he))]
        exact key
    · exact bot_le
  have hGfin : ∫⁻ x, G x ∂μ < ⊤ := lt_of_le_of_lt (lintegral_mono_ae hGg) hg_fin
  have hGlt : ∀ᵐ x ∂μ, G x < ⊤ := ae_lt_top hGm hGfin.ne
  have hlip : ∀ᵐ x ∂μ, LipschitzOnWith (Real.nnabs (G x).toReal) (fun s => f s x) I := by
    filter_upwards [hf_diff, hGlt] with x hd hlt
    set C := (G x).toReal
    have hrat : ∀ a b : ℚ, (a : ℝ) ∈ I → (b : ℝ) ∈ I → |f a x - f b x| ≤ C * |(a : ℝ) - b| := by
      intro a b ha hb
      have h1 : ENNReal.ofReal (|f a x - f b x| / |(a : ℝ) - b|) ≤ G x := by
        refine le_trans ?_ (le_iSup _ (a, b))
        simp [ha, hb]
      have h2 := (ENNReal.ofReal_le_iff_le_toReal hlt.ne).1 h1
      rcases eq_or_ne (a : ℝ) b with he | he
      · simp [he]
      · rwa [div_le_iff₀ (abs_pos.2 (sub_ne_zero.2 he))] at h2
    have hcont : ∀ s ∈ I, ContinuousAt (fun s => f s x) s := fun s hs => (hd s hs).continuousAt
    have hrat2 : ∀ a : ℚ, ∀ b : ℝ, (a : ℝ) ∈ I → b ∈ I → |f a x - f b x| ≤ C * |(a : ℝ) - b| := by
      intro a b ha hb
      have := le_of_rat_le_of_continuousAt
        (fun y => |f a x - f y x| - C * |(a : ℝ) - y|) b 0 I (hI_open.mem_nhds hb)
        (by
          apply ContinuousAt.sub
          · exact (continuousAt_const.sub (hcont b hb)).abs
          · exact continuousAt_const.mul (continuousAt_const.sub continuousAt_id).abs)
        (fun q hq => by simpa using hrat a q ha hq)
      simpa using this
    have hreal : ∀ a b : ℝ, a ∈ I → b ∈ I → |f a x - f b x| ≤ C * |a - b| := by
      intro a b ha hb
      have := le_of_rat_le_of_continuousAt
        (fun y => |f y x - f b x| - C * |y - b|) a 0 I (hI_open.mem_nhds ha)
        (by
          apply ContinuousAt.sub
          · exact ((hcont a ha).sub continuousAt_const).abs
          · exact continuousAt_const.mul (continuousAt_id.sub continuousAt_const).abs)
        (fun q hq => by simpa using hrat2 q b hq hb)
      simpa using this
    apply LipschitzOnWith.of_dist_le_mul
    intro a ha b hb
    simp only [Real.dist_eq]
    have hC : (0 : ℝ) ≤ C := ENNReal.toReal_nonneg
    rw [Real.coe_nnabs, abs_of_nonneg hC]
    exact hreal a b ha hb
  have hderiv_meas : AEStronglyMeasurable (fun x => deriv (fun s => f s x) t) μ := by
    refine aestronglyMeasurable_of_tendsto_ae (nhdsWithin t {t}ᶜ)
      (f := fun r x => if r ∈ I then slope (fun s => f s x) t r else 0) (fun r => ?_) ?_
    · split_ifs with hr
      · simp only [slope_def_field]
        exact (((hf_meas r hr).sub (hf_meas t ht)).div_const _).aestronglyMeasurable
      · exact aestronglyMeasurable_const
    · filter_upwards [hf_diff] with x hd
      have := (hd t ht).hasDerivAt.tendsto_slope
      refine this.congr' ?_
      filter_upwards [nhdsWithin_le_nhds (hI_open.mem_nhds ht)] with r hr
      simp [hr]
  have hint : Integrable (f t) μ := ⟨(hf_meas t ht).aestronglyMeasurable, hf_fin t ht⟩
  have hmeas_ev : ∀ᶠ s in nhds t, AEStronglyMeasurable (f s) μ := by
    filter_upwards [hI_open.mem_nhds ht] with s hs
    exact (hf_meas s hs).aestronglyMeasurable
  have hbint : Integrable (fun x => (G x).toReal) μ :=
    integrable_toReal_of_lintegral_ne_top hGm.aemeasurable hGfin.ne
  have hdiff' : ∀ᵐ x ∂μ, HasDerivAt (fun s => f s x) (deriv (fun s => f s x) t) t := by
    filter_upwards [hf_diff] with x hd
    exact (hd t ht).hasDerivAt
  exact hasDerivAt_integral_of_dominated_loc_of_lip (hI_open.mem_nhds ht) hmeas_ev hint
    hderiv_meas hlip hbint hdiff'

/-- The bakery. A day with price sensitivity `z` sells `500 e^(-z p)` loaves at price `p`, each
costing £1, and `z` has density `4 z e^(-2z)` on `z > 0`. The average daily profit
`Π(p) = ∫ (p - 1) 500 e^(-z p) 4 z e^(-2z) dz` is £160 at `p = 3`; the average of each day's
rate `500 e^(-z p) (1 - (p - 1) z)` at `p = 3` is 16; and `Π` has derivative 16 at `p = 3`:
both roads give £16 a day per £1 of price. -/
theorem bakery_marginal_profit_at_three :
    (∫ z in Ioi (0 : ℝ), (3 - 1) * 500 * exp (-z * 3) * (4 * z * exp (-2 * z))) = 160 ∧
    (∫ z in Ioi (0 : ℝ), 500 * exp (-z * 3) * (1 - (3 - 1) * z) * (4 * z * exp (-2 * z))) = 16 ∧
    HasDerivAt
      (fun p : ℝ => ∫ z in Ioi (0 : ℝ), (p - 1) * 500 * exp (-z * p) * (4 * z * exp (-2 * z)))
      16 3 := by
  have hexp : ∀ z p : ℝ, exp (-z * p) * exp (-2 * z) = exp (-((p + 2) * z)) := by
    intro z p; rw [← exp_add]; ring_nf
  refine ⟨?_, ?_, ?_⟩
  · have e : (fun z : ℝ => (3 - 1) * 500 * exp (-z * 3) * (4 * z * exp (-2 * z))) =
        fun z => 4000 * (z * exp (-((3 + 2) * z))) := by
      funext z; linear_combination (4000 * z) * hexp z 3
    rw [e, integral_const_mul, integral_Ioi_mul_exp_neg_mul _ (by norm_num)]
    norm_num
  · have e : (fun z : ℝ => 500 * exp (-z * 3) * (1 - (3 - 1) * z) * (4 * z * exp (-2 * z))) =
        fun z => 2000 * (z * exp (-((3 + 2) * z))) - 4000 * (z ^ 2 * exp (-((3 + 2) * z))) := by
      funext z; linear_combination (2000 * z * (1 - 2 * z)) * hexp z 3
    have i1 : Integrable (fun z : ℝ => z * exp (-((3 + 2) * z))) (volume.restrict (Ioi 0)) :=
      Integrable.of_integral_ne_zero (by rw [integral_Ioi_mul_exp_neg_mul _ (by norm_num)]; norm_num)
    have i2 : Integrable (fun z : ℝ => z ^ 2 * exp (-((3 + 2) * z))) (volume.restrict (Ioi 0)) :=
      Integrable.of_integral_ne_zero
        (by rw [integral_Ioi_sq_mul_exp_neg_mul _ (by norm_num)]; norm_num)
    rw [e, integral_sub (i1.const_mul _) (i2.const_mul _), integral_const_mul, integral_const_mul,
      integral_Ioi_mul_exp_neg_mul _ (by norm_num), integral_Ioi_sq_mul_exp_neg_mul _ (by norm_num)]
    norm_num
  · have hform : (fun p : ℝ => ∫ z in Ioi (0 : ℝ), (p - 1) * 500 * exp (-z * p) * (4 * z * exp (-2 * z)))
        =ᶠ[nhds 3] fun p => 2000 * (p - 1) / (p + 2) ^ 2 := by
      filter_upwards [Ioi_mem_nhds (by norm_num : (-2 : ℝ) < 3)] with p hp
      have hp' : 0 < p + 2 := by simp at hp; linarith
      have e : (fun z : ℝ => (p - 1) * 500 * exp (-z * p) * (4 * z * exp (-2 * z))) =
          fun z => (2000 * (p - 1)) * (z * exp (-((p + 2) * z))) := by
        funext z; linear_combination (2000 * (p - 1) * z) * hexp z p
      rw [e, integral_const_mul, integral_Ioi_mul_exp_neg_mul _ hp']
      field_simp
    have hd : HasDerivAt (fun p : ℝ => 2000 * (p - 1) / (p + 2) ^ 2) 16 3 := by
      have h1 : HasDerivAt (fun p : ℝ => 2000 * (p - 1)) 2000 3 := by
        simpa using ((hasDerivAt_id (3 : ℝ)).sub_const 1).const_mul 2000
      have h2 : HasDerivAt (fun p : ℝ => (p + 2) ^ 2) 10 3 := by
        have := ((hasDerivAt_id (3 : ℝ)).add_const 2).pow 2
        convert this using 1
        · funext p; simp
        · norm_num
      convert h1.div h2 (by norm_num) using 1
      norm_num
    exact hd.congr_of_eventuallyEq hform

/-- The Gaussian moment trick: differentiating `G(t) = ∫ e^(-t x²) dx = √(π/t)` under the
integral sign at `t = 1` gives `∫ x² e^(-x²) dx = √π / 2` and `∫ x⁴ e^(-x²) dx = 3√π / 4`. -/
theorem gaussian_second_and_fourth_moments :
    (∫ x : ℝ, x ^ 2 * exp (-x ^ 2)) = √π / 2 ∧
    (∫ x : ℝ, x ^ 4 * exp (-x ^ 2)) = 3 * √π / 4 := by
  have hG32 : Gamma (3 / 2) = √π / 2 := by
    have := Real.Gamma_add_one (s := 1 / 2) (by norm_num)
    rw [Real.Gamma_one_half_eq] at this
    norm_num at this
    rw [this]; ring
  have hG52 : Gamma (5 / 2) = 3 * √π / 4 := by
    have := Real.Gamma_add_one (s := 3 / 2) (by norm_num)
    norm_num [hG32] at this
    rw [this]; ring
  constructor
  · have := integral_comp_abs (f := fun y : ℝ => y ^ 2 * exp (-y ^ 2))
    simp only [sq_abs] at this
    rw [this, gauss_Ioi_moment 2]
    norm_num [hG32]
    ring
  · have := integral_comp_abs (f := fun y : ℝ => y ^ 4 * exp (-y ^ 2))
    have h4 : ∀ y : ℝ, |y| ^ 4 = y ^ 4 := fun y => by
      rw [pow_abs, abs_of_nonneg (by positivity)]
    simp only [sq_abs, h4] at this
    rw [this, gauss_Ioi_moment 4]
    norm_num [hG52]
    ring

/-! The card's worked numbers, by hand, in exact fractions (0.16 = 4/25, 0.064 = 8/125). -/

-- E[e^(-3Z)] = 4 × 1!/5^2 = 4/25, and Π(3) = (3 - 1) × 500 × 4/25 = 160
example : (4 * Nat.factorial 1 / 5 ^ 2 : ℚ) = 4 / 25 ∧ ((3 - 1) * 500 * (4 / 25) : ℚ) = 160 := by
  norm_num [Nat.factorial]

-- E[Z e^(-3Z)] = 4 × 2!/5^3 = 8/125, and the average of the rates 500 × (4/25 - 2 × 8/125) = 16
example : (4 * Nat.factorial 2 / 5 ^ 3 : ℚ) = 8 / 125 ∧
    (500 * (4 / 25 - 2 * (8 / 125)) : ℚ) = 500 * (4 / 125) ∧
    (500 * (4 / 125) : ℚ) = 16 := by
  norm_num [Nat.factorial]

-- Π as a formula: 500 (p - 1) × 4/(2 + p)^2 = 2000 (p - 1)/(2 + p)^2; at p = 3 it is 160
example : (500 * (3 - 1) * (4 / (2 + 3) ^ 2) : ℚ) = 2000 * (3 - 1) / (2 + 3) ^ 2 ∧
    (2000 * (3 - 1) / (2 + 3) ^ 2 : ℚ) = 160 := by
  norm_num

-- the derivative of the formula at p = 3: 2000 (4 - 3)/(2 + 3)^3 = 2000 × 1/125 = 16
example : (2000 * ((2 + 3) - 2 * (3 - 1)) / (2 + 3) ^ 3 : ℚ) = 2000 * (4 - 3) / (2 + 3) ^ 3 ∧
    (2000 * (4 - 3) / (2 + 3) ^ 3 : ℚ) = 16 := by
  norm_num

-- best price: 4 - p = 0 at p = 4, profit 2000 × 3/36 = 500/3 (£166.67)
example : (4 - 4 : ℚ) = 0 ∧ (2000 * (4 - 1) / (2 + 4) ^ 2 : ℚ) = 2000 * 3 / 36 ∧
    (2000 * 3 / 36 : ℚ) = 500 / 3 := by
  norm_num

-- the cap on (2, 4) at z = 0 is 500, and its average 500 × (1 × 4 × 1!/4^2 + 3 × 4 × 2!/4^3) = 312.5
example : (500 * (1 + 3 * 0) : ℚ) = 500 ∧
    (500 * (4 * Nat.factorial 1 / 4 ^ 2 + 3 * (4 * Nat.factorial 2 / 4 ^ 3)) : ℚ) = 625 / 2 := by
  norm_num [Nat.factorial]

#print axioms deriv_integral_eq_integral_deriv_of_dominated
#print axioms bakery_marginal_profit_at_three
#print axioms gaussian_second_and_fourth_moments
