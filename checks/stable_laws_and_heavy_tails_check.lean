-- Stable laws: the sum of n independent copies of a law with fingerprint exp(-γ^α |t|^α) is one copy stretched by n^(1/α), the average of n Cauchy hits has the law of one hit, and no law has such a fingerprint when α > 2.
import Mathlib.Probability.Distributions.Cauchy
import Mathlib.Probability.Independence.CharacteristicFunction
import Mathlib.Probability.IdentDistrib
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan
import Mathlib.Analysis.Fourier.Inversion

open MeasureTheory ProbabilityTheory
open scoped NNReal Real

open scoped FourierTransform

lemma re_charFun_eq_integral_cos (μ : Measure ℝ) [IsProbabilityMeasure μ] (t : ℝ) :
    (charFun μ t).re = ∫ x, Real.cos (t * x) ∂μ := by
  rw [charFun_apply_real]
  have hi : Integrable (fun x : ℝ => Complex.exp (t * x * Complex.I)) μ := by
    refine Integrable.of_bound (by fun_prop) 1 (ae_of_all _ fun x => ?_)
    rw [← Complex.ofReal_mul, Complex.norm_exp_ofReal_mul_I]
  rw [← RCLike.re_eq_complex_re, ← integral_re hi]
  congr with x
  rw [RCLike.re_eq_complex_re, ← Complex.ofReal_mul, Complex.exp_ofReal_mul_I_re]

#print axioms re_charFun_eq_integral_cos

lemma four_re_charFun_sub_three_le (μ : Measure ℝ) [IsProbabilityMeasure μ] (t : ℝ) :
    4 * (charFun μ t).re - 3 ≤ (charFun μ (2 * t)).re := by
  rw [re_charFun_eq_integral_cos, re_charFun_eq_integral_cos]
  have hint : ∀ a : ℝ, Integrable (fun x : ℝ => Real.cos (a * x)) μ := fun a =>
    Integrable.of_bound (by fun_prop) 1 (ae_of_all _ fun x => by
      rw [Real.norm_eq_abs]; exact Real.abs_cos_le_one _)
  have h1 : ∫ x, (4 * Real.cos (t * x) - 3) ∂μ = 4 * ∫ x, Real.cos (t * x) ∂μ - 3 := by
    rw [integral_sub ((hint t).const_mul 4) (integrable_const _), integral_const_mul]
    simp
  rw [← h1]
  refine integral_mono ((hint t).const_mul 4 |>.sub (integrable_const _)) (hint (2 * t)) ?_
  intro x
  simp only
  rw [mul_assoc, Real.cos_two_mul]
  nlinarith [sq_nonneg (Real.cos (t * x) - 1)]

#print axioms four_re_charFun_sub_three_le

lemma fourier_exp_neg_abs (w : ℝ) :
    𝓕 (fun x : ℝ => (Real.exp (-|x|) : ℂ)) w = ((2 / (1 + (2 * π * w) ^ 2) : ℝ) : ℂ) := by
  rw [Real.fourier_real_eq_integral_exp_smul]
  set a : ℂ := -1 - 2 * π * w * Complex.I with ha
  set b : ℂ := 1 - 2 * π * w * Complex.I with hb
  have ha_re : a.re < 0 := by simp [ha]
  have hb_re : 0 < b.re := by simp [hb]
  have hR : Set.EqOn (fun v : ℝ => Complex.exp (↑(-2 * π * v * w) * Complex.I) • (Real.exp (-|v|) : ℂ))
      (fun v : ℝ => Complex.exp (a * v)) (Set.Ioi 0) := by
    intro v hv
    simp only [smul_eq_mul]
    rw [abs_of_pos hv, Complex.ofReal_exp, ← Complex.exp_add]
    congr 1
    rw [ha]; push_cast; ring
  have hL : Set.EqOn (fun v : ℝ => Complex.exp (↑(-2 * π * v * w) * Complex.I) • (Real.exp (-|v|) : ℂ))
      (fun v : ℝ => Complex.exp (b * v)) (Set.Iic 0) := by
    intro v hv
    simp only [smul_eq_mul]
    rw [abs_of_nonpos hv, Complex.ofReal_exp, ← Complex.exp_add]
    congr 1
    rw [hb]; push_cast; ring
  rw [← intervalIntegral.integral_Iic_add_Ioi (b := 0)
      ((integrableOn_exp_mul_complex_Iic hb_re 0).congr_fun hL.symm measurableSet_Iic)
      ((integrableOn_exp_mul_complex_Ioi ha_re 0).congr_fun hR.symm measurableSet_Ioi),
    setIntegral_congr_fun measurableSet_Iic hL, setIntegral_congr_fun measurableSet_Ioi hR,
    integral_exp_mul_complex_Iic hb_re, integral_exp_mul_complex_Ioi ha_re]
  have ha0 : a ≠ 0 := fun h => by simp [h] at ha_re
  have hb0 : b ≠ 0 := fun h => by simp [h] at hb_re
  have hab : a * b = -((1 + (2 * π * w) ^ 2 : ℝ) : ℂ) := by
    rw [ha, hb]; push_cast; ring_nf; rw [Complex.I_sq]; ring
  have h1 : ((1 + (2 * π * w) ^ 2 : ℝ) : ℂ) ≠ 0 := by
    norm_cast; positivity
  have hdiff : a - b = -2 := by rw [ha, hb]; ring
  push_cast at h1 hab ⊢
  simp only [mul_zero, Complex.exp_zero]
  rw [div_add_div _ _ hb0 ha0, div_eq_div_iff (mul_ne_zero hb0 ha0) h1]
  linear_combination (-2) * hab + (1 + (2 * (π : ℂ) * w) ^ 2) * hdiff

#print axioms fourier_exp_neg_abs

lemma integrable_exp_neg_abs : Integrable (fun x : ℝ => Real.exp (-|x|)) := by
  have hR : IntegrableOn (fun x : ℝ => Real.exp (-|x|)) (Set.Ioi 0) :=
    (integrableOn_exp_mul_Ioi (by norm_num : (-1 : ℝ) < 0) 0).congr_fun
      (fun x hx => by simp [abs_of_pos (Set.mem_Ioi.mp hx)]) measurableSet_Ioi
  have hL : IntegrableOn (fun x : ℝ => Real.exp (-|x|)) (Set.Iic 0) :=
    (integrableOn_exp_mul_Iic (by norm_num : (0 : ℝ) < 1) 0).congr_fun
      (fun x hx => by simp [abs_of_nonpos (Set.mem_Iic.mp hx)]) measurableSet_Iic
  have := hL.union hR
  rwa [Set.Iic_union_Ioi, integrableOn_univ] at this

#print axioms integrable_exp_neg_abs

lemma integral_exp_mul_I_mul_cauchy_kernel (t : ℝ) :
    ∫ x : ℝ, Complex.exp (↑(t * x) * Complex.I) * ((π⁻¹ * (1 + x ^ 2)⁻¹ : ℝ) : ℂ) =
      (Real.exp (-|t|) : ℂ) := by
  have hcont : Continuous (fun x : ℝ => (Real.exp (-|x|) : ℂ)) := by fun_prop
  have hint : Integrable (fun x : ℝ => (Real.exp (-|x|) : ℂ)) := integrable_exp_neg_abs.ofReal
  have hF : 𝓕 (fun x : ℝ => (Real.exp (-|x|) : ℂ)) =
      fun w : ℝ => ((2 / (1 + (2 * π * w) ^ 2) : ℝ) : ℂ) := funext fourier_exp_neg_abs
  have hg2 : Integrable (fun w : ℝ => (2 / (1 + (2 * π * w) ^ 2) : ℝ)) := by
    have := (integrable_inv_one_add_sq.comp_mul_left' (by positivity : (2 * π : ℝ) ≠ 0)).const_mul 2
    refine this.congr (ae_of_all _ fun x => ?_)
    simp [div_eq_mul_inv]
  have hFint : Integrable (𝓕 (fun x : ℝ => (Real.exp (-|x|) : ℂ))) := by
    rw [hF]
    exact hg2.ofReal
  have hinv := congrFun (hcont.fourierInv_fourier_eq hint hFint) t
  rw [Real.fourierInv_eq_fourier_neg, Real.fourier_real_eq_integral_exp_smul, hF] at hinv
  rw [← hinv]
  have hsub := Measure.integral_comp_mul_left
    (fun x : ℝ => Complex.exp (↑(t * x) * Complex.I) * ((π⁻¹ * (1 + x ^ 2)⁻¹ : ℝ) : ℂ)) (2 * π)
  have h2pi : |(2 * π)⁻¹| = (2 * π)⁻¹ := abs_of_pos (by positivity)
  rw [h2pi] at hsub
  have : ∫ x : ℝ, Complex.exp (↑(t * x) * Complex.I) * ((π⁻¹ * (1 + x ^ 2)⁻¹ : ℝ) : ℂ) =
      (2 * π : ℝ) • ∫ v : ℝ, Complex.exp (↑(t * (2 * π * v)) * Complex.I) *
        ((π⁻¹ * (1 + (2 * π * v) ^ 2)⁻¹ : ℝ) : ℂ) := by
    rw [hsub, smul_smul, mul_inv_cancel₀ (by positivity), one_smul]
  rw [this, ← integral_smul]
  congr 1
  funext v
  rw [Complex.real_smul, smul_eq_mul]
  have hπ : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
  rw [mul_left_comm]
  have hA : (↑(t * (2 * π * v)) : ℂ) = ↑(-2 * π * v * -t) := by push_cast; ring
  rw [hA]
  congr 1
  push_cast
  field_simp

#print axioms integral_exp_mul_I_mul_cauchy_kernel

lemma charFun_cauchyMeasure (x₀ : ℝ) (d : ℝ≥0) (t : ℝ) :
    charFun (cauchyMeasure x₀ d) t =
      Complex.exp (↑(t * x₀) * Complex.I - ↑((d : ℝ) * |t|)) := by
  by_cases hd : d = 0
  · subst hd
    rw [cauchyMeasure_zero_scale, charFun_dirac]
    simp [mul_comm]
  have hd0 : (0 : ℝ) < d := by positivity
  have hdne : (d : ℝ) ≠ 0 := hd0.ne'
  rw [cauchyMeasure_of_scale_ne_zero x₀ hd, charFun_apply_real,
    integral_withDensity_eq_integral_toReal_smul (measurable_cauchyPDF x₀ d)
      (ae_of_all _ fun x => ENNReal.ofReal_lt_top)]
  set H : ℝ → ℂ := fun u => Complex.exp (↑((t * d) * u) * Complex.I) *
    ((π⁻¹ * (1 + u ^ 2)⁻¹ : ℝ) : ℂ) with hH
  calc ∫ x, (cauchyPDF x₀ d x).toReal • Complex.exp (↑t * ↑x * Complex.I)
      = ∫ x, (fun y : ℝ => ((d : ℝ)⁻¹ : ℂ) *
          (Complex.exp (↑(t * x₀) * Complex.I) * H (y / d))) (x - x₀) := by
        congr 1
        funext x
        rw [cauchyPDF_def, ENNReal.toReal_ofReal (cauchyPDF_pos x₀ hd x).le,
          cauchyPDFReal_def', Complex.real_smul, hH]
        simp only
        have he : Complex.exp (↑t * ↑x * Complex.I) =
            Complex.exp (↑(t * x₀) * Complex.I) *
              Complex.exp (↑(t * d * ((x - x₀) / d)) * Complex.I) := by
          rw [← Complex.exp_add]
          congr 1
          have : t * d * ((x - x₀) / d) = t * x - t * x₀ := by field_simp
          rw [this]
          push_cast
          ring
        rw [he]
        push_cast
        ring
    _ = ∫ y : ℝ, ((d : ℝ)⁻¹ : ℂ) * (Complex.exp (↑(t * x₀) * Complex.I) * H (y / d)) :=
        integral_sub_right_eq_self (μ := volume) (fun y : ℝ => ((d : ℝ)⁻¹ : ℂ) *
          (Complex.exp (↑(t * x₀) * Complex.I) * H (y / d))) x₀
    _ = ((d : ℝ)⁻¹ : ℂ) * (Complex.exp (↑(t * x₀) * Complex.I) * ((d : ℝ) • ∫ u, H u)) := by
        rw [integral_const_mul, integral_const_mul, Measure.integral_comp_div,
          abs_of_pos hd0]
    _ = Complex.exp (↑(t * x₀) * Complex.I - ↑((d : ℝ) * |t|)) := by
        rw [hH, integral_exp_mul_I_mul_cauchy_kernel, Complex.real_smul, sub_eq_add_neg,
          Complex.exp_add, abs_mul, abs_of_pos hd0]
        have hdc : ((d : ℝ) : ℂ) ≠ 0 := by exact_mod_cast hdne
        push_cast
        field_simp

#print axioms charFun_cauchyMeasure

/-- Stability of the symmetric family: let X₁, X₂, ... be independent copies of a law whose
fingerprint is φ(t) = exp(-γ^α |t|^α), with index 0 < α ≤ 2. Then for every n the sum of n
copies has the same law as one copy stretched by n^(1/α). On fingerprints this is
φ(t)^n = φ(n^(1/α) t). -/
theorem sum_of_copies_has_law_of_stretched_copy
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : ℕ → Ω → ℝ} (hX : ∀ i, Measurable (X i)) (hindep : iIndepFun X P)
    (hident : ∀ i, IdentDistrib (X i) (X 0) P P)
    {α γ : ℝ} (hα0 : 0 < α) (hα2 : α ≤ 2)
    (hφ : ∀ t : ℝ, charFun (P.map (X 0)) t = Complex.exp (-(γ ^ α * |t| ^ α : ℝ)))
    (n : ℕ) :
    P.map (fun ω => ∑ i ∈ Finset.range n, X i ω) =
      P.map (fun ω => (n : ℝ) ^ (1 / α) * X 0 ω) := by
  apply Measure.ext_of_charFun
  funext t
  rw [iIndepFun.charFun_map_fun_finsetSum_eq_prod (fun i _ => (hX i).aemeasurable)
    (iIndepFun_iff_finset.mp hindep _), charFun_map_mul_comp (hX 0).aemeasurable]
  have h1 : ∀ i ∈ Finset.range n, charFun (P.map (X i)) t = charFun (P.map (X 0)) t := by
    intro i _
    rw [(hident i).map_eq]
  rw [Finset.prod_apply, Finset.prod_congr rfl h1, Finset.prod_const, Finset.card_range, hφ, hφ,
    ← Complex.exp_nat_mul]
  congr 1
  have hn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
  rw [abs_mul, abs_of_nonneg (Real.rpow_nonneg hn _),
    Real.mul_rpow (Real.rpow_nonneg hn _) (abs_nonneg _), one_div,
    Real.rpow_inv_rpow hn hα0.ne']
  push_cast
  ring

/-- The lighthouse: if X₁, X₂, ... are independent hits, each with the Cauchy law of centre x₀
and scale d, then the average of n hits (n ≥ 1) has exactly the same Cauchy law as one hit. -/
theorem average_of_cauchy_hits_has_law_of_one_hit
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {X : ℕ → Ω → ℝ} (hX : ∀ i, Measurable (X i)) (hindep : iIndepFun X P)
    {x₀ : ℝ} {d : ℝ≥0} (hlaw : ∀ i, P.map (X i) = cauchyMeasure x₀ d)
    {n : ℕ} (hn : 0 < n) :
    P.map (fun ω => (∑ i ∈ Finset.range n, X i ω) / n) = cauchyMeasure x₀ d := by
  apply Measure.ext_of_charFun
  funext t
  have hfun : (fun ω => (∑ i ∈ Finset.range n, X i ω) / n) =
      fun ω => (n : ℝ)⁻¹ * ∑ i ∈ Finset.range n, X i ω := by
    funext ω
    rw [div_eq_inv_mul]
  rw [hfun, charFun_map_mul_comp (by fun_prop),
    iIndepFun.charFun_map_fun_finsetSum_eq_prod (fun i _ => (hX i).aemeasurable)
      (iIndepFun_iff_finset.mp hindep _), Finset.prod_apply]
  simp_rw [hlaw]
  rw [Finset.prod_const, Finset.card_range, charFun_cauchyMeasure, charFun_cauchyMeasure,
    ← Complex.exp_nat_mul]
  congr 1
  have hn' : (n : ℝ) ≠ 0 := Nat.cast_ne_zero.mpr hn.ne'
  have hn'' : (n : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr hn.ne'
  rw [abs_mul, abs_inv, Nat.abs_cast]
  push_cast
  field_simp

/-- The index stops at 2: for α > 2 and any scale γ > 0, the function exp(-γ^α |t|^α) is the
fingerprint of no probability law on the real line. -/
theorem no_law_has_stable_fingerprint_of_index_above_two
    {α γ : ℝ} (hα : 2 < α) (hγ : 0 < γ) (μ : Measure ℝ) [IsProbabilityMeasure μ] :
    charFun μ ≠ fun t => Complex.exp (-(γ ^ α * |t| ^ α : ℝ)) := by
  intro h
  have hα0 : 0 < α := by linarith
  set c := γ ^ α with hc
  have hc0 : 0 < c := Real.rpow_pos_of_pos hγ α
  have hre : ∀ t, (charFun μ t).re = Real.exp (-(c * |t| ^ α)) := by
    intro t
    rw [h]
    simp only
    rw [← Complex.ofReal_neg, ← Complex.ofReal_exp, Complex.ofReal_re]
  set k : ℝ := (2 : ℝ) ^ α with hk_def
  have hk : 4 < k := by
    have : (2 : ℝ) ^ (2 : ℝ) < 2 ^ α := Real.rpow_lt_rpow_of_exponent_lt (by norm_num) hα
    rw [Real.rpow_two] at this
    norm_num at this
    exact this
  set s : ℝ := (k - 4) / (8 * k) with hs_def
  have hs : 0 < s := div_pos (by linarith) (by linarith)
  have hsc : 0 ≤ s / c := div_nonneg hs.le hc0.le
  set t : ℝ := (s / c) ^ (1 / α) with ht_def
  have ht0 : 0 ≤ t := Real.rpow_nonneg hsc _
  have hta : t ^ α = s / c := by
    rw [ht_def, one_div, Real.rpow_inv_rpow hsc hα0.ne']
  have h1 : c * |t| ^ α = s := by
    rw [abs_of_nonneg ht0, hta]
    field_simp
  have h2 : c * |2 * t| ^ α = k * s := by
    rw [abs_of_nonneg (by positivity), Real.mul_rpow (by norm_num) ht0, hta, ← hk_def]
    field_simp
  have key := four_re_charFun_sub_three_le μ t
  rw [hre, hre, h1, h2] at key
  have e1 : 1 - s ≤ Real.exp (-s) := by linarith [Real.add_one_le_exp (-s)]
  have e2 : Real.exp (-(k * s)) * (1 + k * s) ≤ 1 := by
    have h3 : 1 + k * s ≤ Real.exp (k * s) := by linarith [Real.add_one_le_exp (k * s)]
    calc Real.exp (-(k * s)) * (1 + k * s) ≤ Real.exp (-(k * s)) * Real.exp (k * s) :=
          mul_le_mul_of_nonneg_left h3 (Real.exp_pos _).le
      _ = 1 := by rw [← Real.exp_add, neg_add_cancel, Real.exp_zero]
  have hks : 0 ≤ k * s := by positivity
  have e3 : (1 - 4 * s) * (1 + k * s) ≤ 1 := by nlinarith
  have hk8 : k * s = (k - 4) / 8 := by rw [hs_def]; field_simp
  have : (1 - 4 * s) * (1 + k * s) - 1 = (k - 4) ^ 2 / (16 * k) := by
    rw [hs_def]; field_simp; ring
  have : 0 < (k - 4) ^ 2 / (16 * k) := by
    have : 0 < k - 4 := by linarith
    positivity
  linarith

-- A fair die has variance 35/12, which is finite, so dice totals reach the bell.
example : (∑ k ∈ Finset.Icc (1 : ℕ) 6, ((k : ℚ) ^ 2)) / 6
    - ((∑ k ∈ Finset.Icc (1 : ℕ) 6, (k : ℚ)) / 6) ^ 2 = 35 / 12 := by
  norm_num [Finset.sum_Icc_succ_top]

-- Pareto fortunes with shape 3/2 and cutoff 1 have mean α/(α - 1) = 3.
example : ((3 : ℚ) / 2) / ((3 : ℚ) / 2 - 1) = 3 := by norm_num

-- The leftover term in the Pareto proof shrinks: 1 - 2/α < 0 at α = 3/2.
example : (1 : ℚ) - 2 / (3 / 2) < 0 := by norm_num

-- The average of Cauchy hits misses by more than d half the time: 1 - (2/π) arctan 1 = 1/2.
example : 1 - (2 / π) * Real.arctan 1 = 1 / 2 := by
  rw [Real.arctan_one]
  field_simp
  norm_num

#print axioms sum_of_copies_has_law_of_stretched_copy
#print axioms average_of_cauchy_hits_has_law_of_one_hit
#print axioms no_law_has_stable_fingerprint_of_index_above_two
