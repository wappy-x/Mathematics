-- Wavelet denoising: the largest of N bell-curve noise coefficients passes the universal threshold σ√(2 ln N) with chance at most 1/√(π ln N), and soft thresholding at that line comes within a factor 2 ln N + 1 of the oracle.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.HasLaw
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Basic.Real.Sign
import Mathlib.Analysis.Complex.ExponentialBounds

open MeasureTheory ProbabilityTheory Real

lemma soft_pt_A (lam : ℝ) (hlam : 0 ≤ lam) (θ x : ℝ) :
    (Real.sign (θ + x) * max (|θ + x| - lam) 0 - θ) ^ 2 ≤ θ ^ 2 + (max (|x| - lam) 0) ^ 2 := by
  rcases lt_trichotomy (θ + x) 0 with h | h | h
  · rw [Real.sign_of_neg h, abs_of_neg h]
    rcases le_total (-(θ + x) - lam) 0 with h1 | h1
    · rw [max_eq_right h1]; nlinarith [sq_nonneg (max (|x| - lam) 0)]
    · rw [max_eq_left h1]
      rcases le_total x 0 with hx | hx
      · rw [abs_of_nonpos hx]
        rcases le_total (-x - lam) 0 with h2 | h2
        · rw [max_eq_right h2]; nlinarith
        · rw [max_eq_left h2]; nlinarith
      · rw [abs_of_nonneg hx]
        rcases le_total (x - lam) 0 with h2 | h2
        · rw [max_eq_right h2]; nlinarith
        · rw [max_eq_left h2]; nlinarith
  · rw [h, Real.sign_zero]; nlinarith [sq_nonneg (max (|x| - lam) 0)]
  · rw [Real.sign_of_pos h, abs_of_pos h]
    rcases le_total ((θ + x) - lam) 0 with h1 | h1
    · rw [max_eq_right h1]; nlinarith [sq_nonneg (max (|x| - lam) 0)]
    · rw [max_eq_left h1]
      rcases le_total x 0 with hx | hx
      · rw [abs_of_nonpos hx]
        rcases le_total (-x - lam) 0 with h2 | h2
        · rw [max_eq_right h2]; nlinarith
        · rw [max_eq_left h2]; nlinarith
      · rw [abs_of_nonneg hx]
        rcases le_total (x - lam) 0 with h2 | h2
        · rw [max_eq_right h2]; nlinarith
        · rw [max_eq_left h2]; nlinarith

#print axioms soft_pt_A

lemma soft_pt_B (lam : ℝ) (hlam : 0 ≤ lam) (θ x : ℝ) :
    (Real.sign (θ + x) * max (|θ + x| - lam) 0 - θ) ^ 2
      ≤ x ^ 2 - 2 * max (-lam) (min θ lam) * x + lam ^ 2 := by
  -- η(θ+x) - θ = x - c with c = clamp(θ+x), and x (c - c0) ≥ 0
  have key : Real.sign (θ + x) * max (|θ + x| - lam) 0 - θ = x - max (-lam) (min (θ + x) lam) := by
    rcases lt_trichotomy (θ + x) 0 with h | h | h
    · rw [Real.sign_of_neg h, abs_of_neg h]
      rcases le_total (-(θ + x) - lam) 0 with h1 | h1
      · rw [max_eq_right h1, min_eq_left (by linarith), max_eq_right (by linarith)]; ring
      · rw [max_eq_left h1, min_eq_left (by linarith), max_eq_left (by linarith)]; ring
    · rw [h, Real.sign_zero, zero_mul, min_eq_left hlam, max_eq_right (neg_nonpos.mpr hlam)]; linarith
    · rw [Real.sign_of_pos h, abs_of_pos h]
      rcases le_total ((θ + x) - lam) 0 with h1 | h1
      · rw [max_eq_right h1, min_eq_left (by linarith), max_eq_right (by linarith)]; ring
      · rw [max_eq_left h1, min_eq_right (by linarith), max_eq_right (by linarith)]; ring
  rw [key]
  set c := max (-lam) (min (θ + x) lam)
  set c0 := max (-lam) (min θ lam)
  have hc1 : -lam ≤ c := le_max_left _ _
  have hc2 : c ≤ lam := max_le (by linarith) (min_le_right _ _)
  have hmono : 0 ≤ x * (c - c0) := by
    rcases le_total x 0 with hx | hx
    · have : c ≤ c0 := max_le_max le_rfl (min_le_min (by linarith) le_rfl)
      nlinarith
    · have : c0 ≤ c := max_le_max le_rfl (min_le_min (by linarith) le_rfl)
      nlinarith
  nlinarith

#print axioms soft_pt_B

lemma gauss_int_id : ∫ x, x ∂(gaussianReal 0 1) = 0 := by simp

#print axioms gauss_int_id

lemma gauss_integrable_id : Integrable (fun x : ℝ => x) (gaussianReal 0 1) :=
  (memLp_id_gaussianReal (μ := 0) (v := 1) 1).integrable le_rfl

#print axioms gauss_integrable_id

lemma gauss_integrable_sq : Integrable (fun x : ℝ => x ^ 2) (gaussianReal 0 1) :=
  (memLp_id_gaussianReal (μ := 0) (v := 1) 2).integrable_sq

#print axioms gauss_integrable_sq

lemma gauss_int_sq : ∫ x, x ^ 2 ∂(gaussianReal 0 1) = 1 := by
  have h := variance_fun_id_gaussianReal (μ := 0) (v := 1)
  rw [variance_eq_integral measurable_id'.aemeasurable] at h
  simpa using h

#print axioms gauss_int_sq

lemma soft_zero_sq (lam : ℝ) (hlam : 0 ≤ lam) (x : ℝ) :
    (Real.sign x * max (|x| - lam) 0) ^ 2 = (max (|x| - lam) 0) ^ 2 := by
  rcases lt_trichotomy x 0 with h | h | h
  · rw [Real.sign_of_neg h]; ring
  · subst h; simp [hlam]
  · rw [Real.sign_of_pos h]; ring

#print axioms soft_zero_sq

lemma integrable_soft_sq (lam : ℝ) (hlam : 0 ≤ lam) :
    Integrable (fun x : ℝ => (max (|x| - lam) 0) ^ 2) (gaussianReal 0 1) := by
  refine ((memLp_id_gaussianReal (μ := 0) (v := 1) 2).integrable_sq).mono' ?_ ?_
  · exact (by fun_prop : Continuous fun x : ℝ => (max (|x| - lam) 0) ^ 2).aestronglyMeasurable
  · refine Filter.Eventually.of_forall fun x => ?_
    simp only [id, Real.norm_eq_abs]
    rw [abs_of_nonneg (sq_nonneg _)]
    have h0 : 0 ≤ max (|x| - lam) 0 := le_max_right _ _
    have h1 : max (|x| - lam) 0 ≤ |x| := max_le (by linarith) (abs_nonneg _)
    calc (max (|x| - lam) 0) ^ 2 ≤ |x| ^ 2 := pow_le_pow_left₀ h0 h1 2
      _ = x ^ 2 := sq_abs x

#print axioms integrable_soft_sq

lemma gaussPDF01_eq (x : ℝ) :
    gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * rexp (-(1 / 2) * x ^ 2) := by
  rw [gaussianPDFReal_def]; simp only [NNReal.coe_one, mul_one, sub_zero]
  congr 2; ring

#print axioms gaussPDF01_eq

lemma integral_Ioi_mul_gaussPDF01 (a : ℝ) :
    ∫ x in Set.Ioi a, x * gaussianPDFReal 0 1 x = gaussianPDFReal 0 1 a := by
  have hderiv : ∀ x ∈ Set.Ioi a, HasDerivAt (fun x => -gaussianPDFReal 0 1 x)
      (x * gaussianPDFReal 0 1 x) x := by
    intro x _
    simp only [gaussPDF01_eq]
    have h1 : HasDerivAt (fun x : ℝ => -(1 / 2) * x ^ 2) (-(1 / 2) * (2 * x)) x := by
      simpa using (hasDerivAt_pow 2 x).const_mul (-(1 / 2) : ℝ)
    have h2 := (h1.exp.const_mul (√(2 * π))⁻¹).neg
    convert h2 using 1; ring
  have hint : MeasureTheory.IntegrableOn (fun x => x * gaussianPDFReal 0 1 x) (Set.Ioi a) := by
    have := (integrable_mul_exp_neg_mul_sq (b := 1 / 2) (by norm_num)).const_mul (√(2 * π))⁻¹
    refine (this.congr (Filter.Eventually.of_forall fun x => ?_)).integrableOn
    simp only [gaussPDF01_eq]; ring
  have hlim : Filter.Tendsto (fun x => -gaussianPDFReal 0 1 x) Filter.atTop (nhds 0) := by
    simp only [gaussPDF01_eq]
    have : Filter.Tendsto (fun x : ℝ => -(1 / 2) * x ^ 2) Filter.atTop Filter.atBot :=
      Filter.Tendsto.const_mul_atTop_of_neg (by norm_num) (Filter.tendsto_pow_atTop two_ne_zero)
    have h := (Real.tendsto_exp_atBot.comp this).const_mul (√(2 * π))⁻¹
    simpa using h.neg
  have hc : Continuous fun x => -gaussianPDFReal 0 1 x := by
    simp only [gaussPDF01_eq]; fun_prop
  have := integral_Ioi_of_hasDerivAt_of_tendsto
    (hc.continuousWithinAt) hderiv hint hlim
  simpa using this

#print axioms integral_Ioi_mul_gaussPDF01

lemma gaussianReal01_real_eq (s : Set ℝ) :
    (gaussianReal 0 1).real s = ∫ x in s, gaussianPDFReal 0 1 x := by
  rw [measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal (setIntegral_nonneg_of_ae_restrict
      (Filter.Eventually.of_forall fun x => gaussianPDFReal_nonneg _ _ x))]

#print axioms gaussianReal01_real_eq

lemma gaussian_tail_aux (lam : ℝ) (hlam : 0 < lam) :
    (gaussianReal 0 1).real (Set.Ioi lam) ≤ gaussianPDFReal 0 1 lam / lam := by
  rw [gaussianReal01_real_eq]
  have hint : MeasureTheory.IntegrableOn (fun x => x * gaussianPDFReal 0 1 x) (Set.Ioi lam) := by
    have := (integrable_mul_exp_neg_mul_sq (b := 1 / 2) (by norm_num)).const_mul (√(2 * π))⁻¹
    refine (this.congr (Filter.Eventually.of_forall fun x => ?_)).integrableOn
    simp only [gaussPDF01_eq]; ring
  calc ∫ x in Set.Ioi lam, gaussianPDFReal 0 1 x
      ≤ ∫ x in Set.Ioi lam, lam⁻¹ * (x * gaussianPDFReal 0 1 x) := by
        refine setIntegral_mono_on (integrable_gaussianPDFReal 0 1).integrableOn
          (hint.const_mul _) measurableSet_Ioi fun x hx => ?_
        have hx' : lam < x := hx
        have hp := gaussianPDFReal_nonneg 0 1 x
        rw [← mul_assoc]
        have : 1 ≤ lam⁻¹ * x := by
          rw [le_inv_mul_iff₀ hlam]; linarith
        nlinarith
    _ = gaussianPDFReal 0 1 lam / lam := by
        rw [integral_const_mul, integral_Ioi_mul_gaussPDF01]; ring

#print axioms gaussian_tail_aux

lemma gaussian_abs_tail_le (lam : ℝ) (hlam : 0 < lam) :
    (gaussianReal 0 1).real {x | lam < |x|} ≤ 2 * (gaussianPDFReal 0 1 lam / lam) := by
  have hset : {x : ℝ | lam < |x|} = Set.Iio (-lam) ∪ Set.Ioi lam := by
    ext x; simp only [Set.mem_ofPred_eq, Set.mem_union, Set.mem_Iio, Set.mem_Ioi, lt_abs]
    constructor <;> rintro (h | h) <;> [right; left; right; left] <;> linarith
  have hdisj : Disjoint (Set.Iio (-lam)) (Set.Ioi lam) := by
    rw [Set.disjoint_left]; intro x h1 h2
    simp only [Set.mem_Iio, Set.mem_Ioi] at h1 h2; linarith
  have hneg : (gaussianReal 0 1).real (Set.Iio (-lam)) = (gaussianReal 0 1).real (Set.Ioi lam) := by
    have hm : (gaussianReal 0 1).map (fun x => -x) = gaussianReal 0 1 := by
      rw [gaussianReal_map_neg, neg_zero]
    conv_rhs => rw [← hm]
    rw [map_measureReal_apply measurable_neg measurableSet_Ioi]
    congr 1; ext x; simp
  rw [hset, measureReal_union hdisj measurableSet_Ioi, hneg]
  have := gaussian_tail_aux lam hlam
  linarith

#print axioms gaussian_abs_tail_le

lemma soft_sq_le_exp (lam : ℝ) (hlam : 0 < lam) (x : ℝ) :
    (max (|x| - lam) 0) ^ 2
      ≤ 4 / (rexp 2 * lam ^ 2) * (rexp (lam * x - lam ^ 2) + rexp (-lam * x - lam ^ 2)) := by
  have hpos : 0 < 4 / (rexp 2 * lam ^ 2) * (rexp (lam * x - lam ^ 2) + rexp (-lam * x - lam ^ 2)) := by
    positivity
  rcases le_total (|x| - lam) 0 with h | h
  · rw [max_eq_right h]; nlinarith
  · rw [max_eq_left h]
    set t := |x| - lam with ht
    have hexp : rexp (lam * t) ≤ rexp (lam * x - lam ^ 2) + rexp (-lam * x - lam ^ 2) := by
      rcases le_total 0 x with hx | hx
      · rw [ht, abs_of_nonneg hx]
        have := Real.exp_pos (-lam * x - lam ^ 2)
        have e : lam * (x - lam) = lam * x - lam ^ 2 := by ring
        rw [e]; linarith
      · rw [ht, abs_of_nonpos hx]
        have := Real.exp_pos (lam * x - lam ^ 2)
        have e : lam * (-x - lam) = -lam * x - lam ^ 2 := by ring
        rw [e]; linarith
    -- u ≤ exp (u - 1) with u = lam * t / 2
    have hu : lam * t / 2 ≤ rexp (lam * t / 2 - 1) := by
      have := Real.add_one_le_exp (lam * t / 2 - 1); linarith
    have hu0 : 0 ≤ lam * t / 2 := by positivity
    have hsq : (lam * t / 2) ^ 2 ≤ rexp (lam * t / 2 - 1) ^ 2 := pow_le_pow_left₀ hu0 hu 2
    have he : rexp (lam * t / 2 - 1) ^ 2 * rexp 2 = rexp (lam * t) := by
      rw [← Real.exp_nat_mul, ← Real.exp_add]; congr 1; push_cast; ring
    have h2 : t ^ 2 * (rexp 2 * lam ^ 2) ≤ 4 * rexp (lam * t) := by
      have := Real.exp_pos 2
      nlinarith
    have hd : 0 < rexp 2 * lam ^ 2 := by positivity
    calc t ^ 2 ≤ 4 / (rexp 2 * lam ^ 2) * rexp (lam * t) := by
          rw [div_mul_eq_mul_div, le_div_iff₀ hd]; linarith
      _ ≤ _ := mul_le_mul_of_nonneg_left hexp (by positivity)

#print axioms soft_sq_le_exp

lemma integral_exp_lin_gauss (a b : ℝ) :
    ∫ x, rexp (a * x + b) ∂(gaussianReal 0 1) = rexp (b + a ^ 2 / 2) := by
  have h1 : (fun x => rexp (a * x + b)) = fun x => rexp b * rexp (a * x) := by
    funext x; rw [← Real.exp_add]; ring_nf
  rw [h1, integral_const_mul]
  have h2 := congrFun (mgf_fun_id_gaussianReal (μ := 0) (v := 1)) a
  simp only [mgf] at h2
  rw [h2, ← Real.exp_add]; congr 1; push_cast; ring

#print axioms integral_exp_lin_gauss

lemma soft_risk_zero_le_one (lam : ℝ) (hlam : 0 ≤ lam) :
    ∫ x, (max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1) ≤ 1 := by
  rw [← gauss_int_sq]
  refine integral_mono (integrable_soft_sq lam hlam) gauss_integrable_sq fun x => ?_
  have h0 : 0 ≤ max (|x| - lam) 0 := le_max_right _ _
  have h1 : max (|x| - lam) 0 ≤ |x| := max_le (by linarith) (abs_nonneg _)
  calc (max (|x| - lam) 0) ^ 2 ≤ |x| ^ 2 := pow_le_pow_left₀ h0 h1 2
    _ = x ^ 2 := sq_abs x

#print axioms soft_risk_zero_le_one

lemma N_soft_risk_zero_le (N : ℕ) :
    (N : ℝ) * ∫ x, (max (|x| - Real.sqrt (2 * Real.log N)) 0) ^ 2 ∂(gaussianReal 0 1)
      ≤ 1 + 2 * Real.log N := by
  have hL0 : 0 ≤ Real.log N := Real.log_natCast_nonneg N
  have hr0 := soft_risk_zero_le_one (Real.sqrt (2 * Real.log N)) (Real.sqrt_nonneg _)
  rcases Nat.lt_or_ge N 2 with hN | hN
  · interval_cases N
    · simp
    · simpa using hr0
  · have hN' : (1 : ℝ) < N := by exact_mod_cast (by omega : 1 < N)
    have hNpos : (0 : ℝ) < N := by linarith
    set L := Real.log N with hL
    have hLpos : 0 < L := Real.log_pos hN'
    set lam := Real.sqrt (2 * L) with hlam
    have hlampos : 0 < lam := Real.sqrt_pos.mpr (by positivity)
    have hlam2 : lam ^ 2 = 2 * L := Real.sq_sqrt (by positivity)
    have hi1 : Integrable (fun x : ℝ => rexp (lam * x - lam ^ 2)) (gaussianReal 0 1) := by
      have := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) lam).const_mul (rexp (-lam ^ 2))
      refine this.congr (Filter.Eventually.of_forall fun x => ?_)
      simp only; rw [← Real.exp_add]; ring_nf
    have hi2 : Integrable (fun x : ℝ => rexp (-lam * x - lam ^ 2)) (gaussianReal 0 1) := by
      have := (integrable_exp_mul_gaussianReal (μ := 0) (v := 1) (-lam)).const_mul (rexp (-lam ^ 2))
      refine this.congr (Filter.Eventually.of_forall fun x => ?_)
      simp only; rw [← Real.exp_add]; ring_nf
    have hb : ∫ x, (max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1) ≤ ∫ x, 4 / (rexp 2 * lam ^ 2) *
        (rexp (lam * x - lam ^ 2) + rexp (-lam * x - lam ^ 2)) ∂(gaussianReal 0 1) :=
      integral_mono (integrable_soft_sq lam hlampos.le)
        ((hi1.add hi2).const_mul (4 / (rexp 2 * lam ^ 2))) (soft_sq_le_exp lam hlampos)
    rw [integral_const_mul, integral_add hi1 hi2] at hb
    have e1 : ∫ x, rexp (lam * x - lam ^ 2) ∂(gaussianReal 0 1) = rexp (-L) := by
      have := integral_exp_lin_gauss lam (-lam ^ 2)
      simp only [← sub_eq_add_neg] at this
      rw [this, hlam2]; congr 1; ring
    have e2 : ∫ x, rexp (-lam * x - lam ^ 2) ∂(gaussianReal 0 1) = rexp (-L) := by
      have := integral_exp_lin_gauss (-lam) (-lam ^ 2)
      simp only [← sub_eq_add_neg] at this
      rw [this, neg_sq, hlam2]; congr 1; ring
    rw [e1, e2, Real.exp_neg, Real.exp_log hNpos, hlam2] at hb
    -- hb : r0 ≤ 4 / (e² · 2L) · (N⁻¹ + N⁻¹)
    have he2 : 7 < rexp 2 := by
      have h := Real.exp_one_gt_d9
      have : rexp 2 = rexp 1 * rexp 1 := by rw [← Real.exp_add]; norm_num
      rw [this]; nlinarith
    have hlog2 : (0.6931471803 : ℝ) < L := by
      have := Real.log_two_gt_d9
      have : Real.log 2 ≤ L := Real.log_le_log (by norm_num) (by exact_mod_cast hN)
      linarith
    have hkey : (N : ℝ) * (4 / (rexp 2 * (2 * L)) * ((N : ℝ)⁻¹ + (N : ℝ)⁻¹)) ≤ 1 := by
      have : (N : ℝ) * (4 / (rexp 2 * (2 * L)) * ((N : ℝ)⁻¹ + (N : ℝ)⁻¹)) = 4 / (rexp 2 * L) := by
        field_simp; ring
      rw [this, div_le_one (by positivity)]
      nlinarith
    calc (N : ℝ) * ∫ x, (max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1)
        ≤ (N : ℝ) * (4 / (rexp 2 * (2 * L)) * ((N : ℝ)⁻¹ + (N : ℝ)⁻¹)) :=
          mul_le_mul_of_nonneg_left hb hNpos.le
      _ ≤ 1 := hkey
      _ ≤ 1 + 2 * L := by linarith

#print axioms N_soft_risk_zero_le

lemma soft_bound_exists (lam : ℝ) (hlam : 0 ≤ lam) (t : ℝ) :
    ∃ b : ℝ → ℝ, Integrable b (gaussianReal 0 1) ∧
      (∀ x, (Real.sign (t + x) * max (|t + x| - lam) 0 - t) ^ 2 ≤ b x) ∧
      ∫ x, b x ∂(gaussianReal 0 1)
        ≤ ∫ x, (max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1) + (1 + lam ^ 2) * min (t ^ 2) 1 := by
  have hR0 : 0 ≤ ∫ x, (max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1) :=
    integral_nonneg fun x => sq_nonneg _
  rcases le_total (t ^ 2) 1 with ht | ht
  · refine ⟨fun x => t ^ 2 + (max (|x| - lam) 0) ^ 2,
      (integrable_const _).add (integrable_soft_sq lam hlam), soft_pt_A lam hlam t, ?_⟩
    rw [integral_add (integrable_const _) (integrable_soft_sq lam hlam), min_eq_left ht]
    simp only [integral_const, probReal_univ, smul_eq_mul, one_mul]
    nlinarith [sq_nonneg t, sq_nonneg lam]
  · set c0 := max (-lam) (min t lam)
    have hA : Integrable (fun x : ℝ => x ^ 2 - 2 * c0 * x) (gaussianReal 0 1) :=
      gauss_integrable_sq.sub (gauss_integrable_id.const_mul (2 * c0))
    refine ⟨fun x => x ^ 2 - 2 * c0 * x + lam ^ 2, hA.add (integrable_const _),
      soft_pt_B lam hlam t, ?_⟩
    have he : ∫ x, (x ^ 2 - 2 * c0 * x + lam ^ 2) ∂(gaussianReal 0 1) = 1 + lam ^ 2 := by
      rw [integral_add hA (integrable_const _),
        integral_sub gauss_integrable_sq (gauss_integrable_id.const_mul (2 * c0)),
        integral_const_mul, gauss_int_sq, gauss_int_id]
      simp
    rw [he, min_eq_right ht]
    linarith

#print axioms soft_bound_exists

lemma soft_scale (σ : ℝ) (hσ : 0 < σ) (lam θ x : ℝ) :
    (Real.sign (θ + σ * x) * max (|θ + σ * x| - σ * lam) 0 - θ) ^ 2
      = σ ^ 2 * (Real.sign (θ / σ + x) * max (|θ / σ + x| - lam) 0 - θ / σ) ^ 2 := by
  set y := θ / σ + x
  have hθ : θ = σ * (θ / σ) := by field_simp
  have hy : θ + σ * x = σ * y := by simp only [y]; field_simp
  have hsign : Real.sign (σ * y) = Real.sign y := by
    rcases lt_trichotomy y 0 with h | h | h
    · rw [Real.sign_of_neg h, Real.sign_of_neg (mul_neg_of_pos_of_neg hσ h)]
    · rw [h, mul_zero]
    · rw [Real.sign_of_pos h, Real.sign_of_pos (mul_pos hσ h)]
  have hmax : max (|σ * y| - σ * lam) 0 = σ * max (|y| - lam) 0 := by
    rw [abs_mul, abs_of_pos hσ, mul_max_of_nonneg _ _ hσ.le, mul_zero, mul_sub]
  rw [hy, hsign, hmax]
  conv_lhs => rw [hθ]
  ring

#print axioms soft_scale

/-- The largest of N noise coefficients rarely passes the universal threshold: if
`z 1, …, z N` are independent standard bell-curve draws (white Gaussian noise) and the noise on
each coefficient is `σ z i` with `σ > 0`, then the chance that some `|σ z i|` passes
`λ = σ √(2 ln N)` is at most `1 / √(π ln N)`. -/
theorem largest_noise_coefficient_rarely_passes_universal_threshold
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (N : ℕ) (hN : 2 ≤ N) (σ : ℝ) (hσ : 0 < σ)
    (z : Fin N → Ω → ℝ) (hind : iIndepFun z P)
    (hlaw : ∀ i, HasLaw (z i) (gaussianReal 0 1) P) :
    P.real {ω | ∃ i, σ * Real.sqrt (2 * Real.log N) < |σ * z i ω|}
      ≤ 1 / Real.sqrt (π * Real.log N) := by
  set L := Real.log N with hL
  have hN' : (1 : ℝ) < N := by exact_mod_cast (by omega : 1 < N)
  have hNpos : (0 : ℝ) < N := by linarith
  have hLpos : 0 < L := Real.log_pos hN'
  set lam := Real.sqrt (2 * L) with hlam
  have hlampos : 0 < lam := Real.sqrt_pos.mpr (by positivity)
  have hevent : ∀ i, {ω | σ * lam < |σ * z i ω|} = {ω | (fun x => lam < |x|) (z i ω)} := by
    intro i; ext ω
    simp only [Set.mem_ofPred_eq, abs_mul, abs_of_pos hσ]
    exact mul_lt_mul_iff_right₀ hσ
  have hmeas : MeasurableSet {x : ℝ | lam < |x|} := (isOpen_lt continuous_const continuous_abs).measurableSet
  have hunion : {ω | ∃ i, σ * lam < |σ * z i ω|} = ⋃ i, {ω | σ * lam < |σ * z i ω|} := by
    ext ω; simp
  rw [hunion]
  refine (measureReal_iUnion_fintype_le _).trans ?_
  simp_rw [hevent, fun i => (hlaw i).measureReal_eq hmeas]
  rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  refine (mul_le_mul_of_nonneg_left (gaussian_abs_tail_le lam hlampos) hNpos.le).trans (le_of_eq ?_)
  have hφ : gaussianPDFReal 0 1 lam = (√(2 * π))⁻¹ * (N : ℝ)⁻¹ := by
    rw [gaussPDF01_eq, hlam, Real.sq_sqrt (by positivity)]
    congr 1
    rw [show -(1 / 2) * (2 * L) = -L by ring, Real.exp_neg, hL, Real.exp_log hNpos]
  have hsq : √(2 * π) * lam = 2 * √(π * L) := by
    rw [hlam, ← Real.sqrt_mul (by positivity), show 2 * π * (2 * L) = 2 ^ 2 * (π * L) by ring,
      Real.sqrt_mul (by positivity), Real.sqrt_sq (by norm_num)]
  have hpi : 0 < √(2 * π) := Real.sqrt_pos.mpr (by positivity)
  have hpl : 0 < √(π * L) := Real.sqrt_pos.mpr (by positivity)
  rw [hφ]
  field_simp
  linear_combination (-1) * hsq

/-- Soft thresholding comes within `2 ln N + 1` of the oracle: with clean coefficients
`θ i`, noisy coefficients `y i = θ i + σ z i` (independent standard bell-curve `z i`, `σ > 0`)
and the soft rule `η_S(y) = sign(y) · max(|y| - λ, 0)` at `λ = σ √(2 ln N)`, the expected total
squared error is at most `(2 ln N + 1) (σ² + ∑ min(θ i², σ²))`. -/
theorem soft_threshold_within_two_log_n_plus_one_of_oracle
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (N : ℕ) (σ : ℝ) (hσ : 0 < σ) (θ : Fin N → ℝ)
    (z : Fin N → Ω → ℝ) (hind : iIndepFun z P)
    (hlaw : ∀ i, HasLaw (z i) (gaussianReal 0 1) P) :
    ∫ ω, ∑ i, (Real.sign (θ i + σ * z i ω)
        * max (|θ i + σ * z i ω| - σ * Real.sqrt (2 * Real.log N)) 0 - θ i) ^ 2 ∂P
      ≤ (2 * Real.log N + 1) * (σ ^ 2 + ∑ i, min (θ i ^ 2) (σ ^ 2)) := by
  set L := Real.log N with hL
  have hL0 : 0 ≤ L := Real.log_natCast_nonneg N
  set lam := Real.sqrt (2 * L) with hlam
  have hlam0 : 0 ≤ lam := Real.sqrt_nonneg _
  have hlam2 : lam ^ 2 = 2 * L := Real.sq_sqrt (by positivity)
  set r0 := ∫ x, (max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1) with hr0
  have hNr0 : (N : ℝ) * r0 ≤ 1 + 2 * L := N_soft_risk_zero_le N
  choose b hbi hbpt hbint using fun i : Fin N => soft_bound_exists lam hlam0 (θ i / σ)
  have hint : Integrable (fun ω => ∑ i, σ ^ 2 * b i (z i ω)) P :=
    integrable_finsetSum _ fun i _ => ((hlaw i).integrable_comp (hbi i)).const_mul (σ ^ 2)
  have hmono := integral_mono_of_nonneg
    (Filter.Eventually.of_forall fun ω => Finset.sum_nonneg fun i _ => sq_nonneg
      (Real.sign (θ i + σ * z i ω) * max (|θ i + σ * z i ω| - σ * lam) 0 - θ i))
    hint (Filter.Eventually.of_forall fun ω => Finset.sum_le_sum fun i _ => by
      rw [soft_scale σ hσ lam (θ i) (z i ω)]
      exact mul_le_mul_of_nonneg_left (hbpt i (z i ω)) (sq_nonneg σ))
  refine hmono.trans ?_
  have hint_i : ∀ i ∈ Finset.univ, Integrable (fun ω => σ ^ 2 * b i (z i ω)) P :=
    fun i _ => ((hlaw i).integrable_comp (hbi i)).const_mul (σ ^ 2)
  rw [integral_finsetSum _ hint_i]
  have hcomp : ∀ i, ∫ ω, σ ^ 2 * b i (z i ω) ∂P = σ ^ 2 * ∫ x, b i x ∂(gaussianReal 0 1) := by
    intro i
    rw [integral_const_mul]
    have := (hlaw i).integral_comp (hbi i).aestronglyMeasurable
    simp only [Function.comp_def] at this
    rw [this]
  simp_rw [hcomp]
  have hmin : ∀ i, σ ^ 2 * min ((θ i / σ) ^ 2) 1 = min (θ i ^ 2) (σ ^ 2) := by
    intro i
    rw [mul_min_of_nonneg _ _ (sq_nonneg σ), mul_one]
    congr 1; field_simp
  calc ∑ i, σ ^ 2 * ∫ x, b i x ∂(gaussianReal 0 1)
      ≤ ∑ i, σ ^ 2 * (r0 + (1 + lam ^ 2) * min ((θ i / σ) ^ 2) 1) :=
        Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_left (hbint i) (sq_nonneg σ)
    _ = σ ^ 2 * ((N : ℝ) * r0) + (1 + lam ^ 2) * ∑ i, min (θ i ^ 2) (σ ^ 2) := by
        simp_rw [← hmin, mul_add, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ,
          Fintype.card_fin, nsmul_eq_mul, Finset.mul_sum]
        congr 1
        · ring
        · exact Finset.sum_congr rfl fun i _ => by ring
    _ ≤ σ ^ 2 * (1 + 2 * L) + (1 + 2 * L) * ∑ i, min (θ i ^ 2) (σ ^ 2) := by
        rw [hlam2]
        exact add_le_add_left (mul_le_mul_of_nonneg_left hNr0 (sq_nonneg σ)) _
    _ = (2 * L + 1) * (σ ^ 2 + ∑ i, min (θ i ^ 2) (σ ^ 2)) := by ring

/-- Step 2's tail bound: for a standard bell-curve draw and a line `λ > 0`, the chance of
landing above `λ` is at most the bell curve's height at `λ` divided by `λ`. -/
theorem gaussian_tail_le_height_div_line (lam : ℝ) (hlam : 0 < lam) :
    (gaussianReal 0 1).real (Set.Ioi lam) ≤ gaussianPDFReal 0 1 lam / lam := by
  exact gaussian_tail_aux lam hlam

/-- Step 4's risk bound for one coefficient, in units of `σ²`: the soft rule's risk
`r(λ, θ) = E (η_S(θ + z) - θ)²` obeys `r(λ, θ) ≤ r(λ, 0) + (1 + λ²) min(θ², 1)`. -/
theorem soft_threshold_risk_le (lam : ℝ) (hlam : 0 ≤ lam) (θ : ℝ) :
    ∫ x, (Real.sign (θ + x) * max (|θ + x| - lam) 0 - θ) ^ 2 ∂(gaussianReal 0 1)
      ≤ ∫ x, (Real.sign x * max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1)
        + (1 + lam ^ 2) * min (θ ^ 2) 1 := by
  have hR : ∫ x, (Real.sign x * max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1)
      = ∫ x, (max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1) := by
    congr 1; funext x; exact soft_zero_sq lam hlam x
  rw [hR]
  have hR0 : 0 ≤ ∫ x, (max (|x| - lam) 0) ^ 2 ∂(gaussianReal 0 1) :=
    integral_nonneg fun x => sq_nonneg _
  have hnn : 0 ≤ᵐ[gaussianReal 0 1]
      fun x => (Real.sign (θ + x) * max (|θ + x| - lam) 0 - θ) ^ 2 :=
    Filter.Eventually.of_forall fun x => sq_nonneg _
  rcases le_total (θ ^ 2) 1 with hθ | hθ
  · rw [min_eq_left hθ]
    have hi : Integrable (fun x : ℝ => θ ^ 2 + (max (|x| - lam) 0) ^ 2) (gaussianReal 0 1) :=
      (integrable_const _).add (integrable_soft_sq lam hlam)
    have h1 := integral_mono_of_nonneg hnn hi
      (Filter.Eventually.of_forall fun x => soft_pt_A lam hlam θ x)
    rw [integral_add (integrable_const _) (integrable_soft_sq lam hlam)] at h1
    simp only [integral_const, probReal_univ, smul_eq_mul, one_mul] at h1
    nlinarith [sq_nonneg θ, sq_nonneg lam]
  · rw [min_eq_right hθ]
    set c0 := max (-lam) (min θ lam)
    have hi : Integrable (fun x : ℝ => x ^ 2 - 2 * c0 * x + lam ^ 2) (gaussianReal 0 1) :=
      (gauss_integrable_sq.sub (gauss_integrable_id.const_mul (2 * c0))).add (integrable_const _)
    have h1 := integral_mono_of_nonneg hnn hi
      (Filter.Eventually.of_forall fun x => soft_pt_B lam hlam θ x)
    have hA : Integrable (fun x : ℝ => x ^ 2 - 2 * c0 * x) (gaussianReal 0 1) :=
      gauss_integrable_sq.sub (gauss_integrable_id.const_mul (2 * c0))
    have he : ∫ x, (x ^ 2 - 2 * c0 * x + lam ^ 2) ∂(gaussianReal 0 1) = 1 + lam ^ 2 := by
      rw [integral_add hA (integrable_const _),
        integral_sub gauss_integrable_sq (gauss_integrable_id.const_mul (2 * c0)),
        integral_const_mul, gauss_int_sq, gauss_int_id]
      simp
    rw [he] at h1
    linarith

-- The card's counts: 1920 details (1024, 512, 256, 128 at levels 1 to 4) and 128 coarse values.
example : 1024 + 512 + 256 + 128 = 1920 := by norm_num
example : 1920 + 128 = 2048 := by norm_num
example : 2048 / 2 ^ 4 = 128 := by norm_num
example : (2048 : ℕ) = 2 ^ 11 := by norm_num
-- Beats 0.8 s apart are 75 a minute.
example : (60 : ℚ) / (4 / 5) = 75 := by norm_num

#print axioms largest_noise_coefficient_rarely_passes_universal_threshold
#print axioms soft_threshold_within_two_log_n_plus_one_of_oracle
#print axioms gaussian_tail_le_height_div_line
#print axioms soft_threshold_risk_le
