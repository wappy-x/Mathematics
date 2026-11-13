-- The reference distributions: a sum of k independent squared standard normals has the chi-square law (gamma with shape k/2 and rate 1/2, mean k, variance 2k), and for normal samples the scaled sample variance is chi-square on n − 1 degrees and independent of the average, the t ratio has Student's t density on n − 1 degrees, and the ratio of two samples' scaled variances has the F density on (n₁ − 1, n₂ − 1).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Distributions.Gamma
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib

open MeasureTheory ProbabilityTheory Set Real
open scoped ENNReal NNReal

/-- The average of n measurements: their sum divided by n. -/
noncomputable def sampleMean {n : ℕ} (x : Fin n → ℝ) : ℝ := (∑ i, x i) / n

/-- The sample variance S²: the squared residuals (gaps from the average) added and divided
by n − 1. -/
noncomputable def sampleVar {n : ℕ} (x : Fin n → ℝ) : ℝ :=
  (∑ i, (x i - sampleMean x) ^ 2) / ((n : ℝ) - 1)

/-- Student's t density with ν degrees of freedom, as on the card:
f_T(t) = Γ((ν+1)/2) / (√(νπ) Γ(ν/2)) · (1 + t²/ν)^(−(ν+1)/2). -/
noncomputable def studentTPDF (ν t : ℝ) : ℝ :=
  Gamma ((ν + 1) / 2) / (√(ν * π) * Gamma (ν / 2)) * (1 + t ^ 2 / ν) ^ (-(ν + 1) / 2)

/-- The F density with ν₁ and ν₂ degrees of freedom, as on the card, with c = ν₁/ν₂:
f_F(x) = Γ((ν₁+ν₂)/2) c^(ν₁/2) x^(ν₁/2−1) / (Γ(ν₁/2) Γ(ν₂/2) (1 + c x)^((ν₁+ν₂)/2)) for x > 0,
and 0 for x ≤ 0. -/
noncomputable def fisherFPDF (ν₁ ν₂ x : ℝ) : ℝ :=
  if 0 < x then
    Gamma ((ν₁ + ν₂) / 2) * (ν₁ / ν₂) ^ (ν₁ / 2) * x ^ (ν₁ / 2 - 1) /
      (Gamma (ν₁ / 2) * Gamma (ν₂ / 2) * (1 + ν₁ / ν₂ * x) ^ ((ν₁ + ν₂) / 2))
  else 0

lemma lintegral_rpow_exp_Ioi {a b : ℝ} (ha : 0 < a) (hb : 0 < b) :
    ∫⁻ x in Ioi (0:ℝ), ENNReal.ofReal (x ^ (a - 1) * exp (-(b * x))) =
      ENNReal.ofReal ((1 / b) ^ a * Gamma a) := by
  rw [← integral_rpow_mul_exp_neg_mul_Ioi ha hb, ofReal_integral_eq_lintegral_ofReal]
  · apply Integrable.of_integral_ne_zero
    rw [integral_rpow_mul_exp_neg_mul_Ioi ha hb]; positivity
  · filter_upwards [ae_restrict_mem measurableSet_Ioi] with x hx
    have : (0:ℝ) ≤ x := le_of_lt hx
    positivity

#print axioms lintegral_rpow_exp_Ioi

lemma lintegral_comp_mul_left' (f : ℝ → ℝ≥0∞) {c : ℝ} (hc : c ≠ 0) :
    ∫⁻ x, f (c * x) = ENNReal.ofReal |c⁻¹| * ∫⁻ y, f y := by
  have e : MeasurableEmbedding (fun x : ℝ => c * x) :=
    (Homeomorph.mulLeft₀ c hc).measurableEmbedding
  rw [← e.lintegral_map, Real.map_volume_mul_left hc, lintegral_smul_measure, smul_eq_mul]

#print axioms lintegral_comp_mul_left'

lemma lintegral_eq_ofReal_mul_comp {F : ℝ → ℝ≥0∞} {z : ℝ} (hz : 0 < z) :
    ∫⁻ w, F w = ENNReal.ofReal z * ∫⁻ t, F (z * t) := by
  rw [lintegral_comp_mul_left' F hz.ne', ← mul_assoc, ← ENNReal.ofReal_mul (le_of_lt hz),
    abs_of_pos (inv_pos.2 hz), mul_inv_cancel₀ hz.ne', ENNReal.ofReal_one, one_mul]

#print axioms lintegral_eq_ofReal_mul_comp

lemma gamma_beta_identity {a b r z t : ℝ} (ha : 0 < a) (hb : 0 < b) (hr : 0 < r) (hz : 0 < z)
    (ht0 : 0 < t) (ht1 : t < 1) :
    r ^ b / Gamma b * (z * t) ^ (b - 1) * exp (-(r * (z * t))) *
      (r ^ a / Gamma a * (z - z * t) ^ (a - 1) * exp (-(r * (z - z * t)))) =
    r ^ (a + b) / Gamma (a + b) * z ^ (a + b - 1) * exp (-(r * z)) / z *
      (1 / beta b a * t ^ (b - 1) * (1 - t) ^ (a - 1)) := by
  have h1t : 0 < 1 - t := by linarith
  rw [mul_rpow hz.le ht0.le, show z - z * t = z * (1 - t) by ring, mul_rpow hz.le h1t.le,
    show a + b - 1 = (b - 1) + (a - 1) + 1 by ring, rpow_add hz, rpow_add hz, rpow_one,
    rpow_add hr, beta, add_comm b a]
  have hexp : exp (-(r * (z * t))) * exp (-(r * (z * (1 - t)))) = exp (-(r * z)) := by
    rw [← exp_add]; ring_nf
  have hGa := (Gamma_pos_of_pos ha).ne'
  have hGb := (Gamma_pos_of_pos hb).ne'
  have hGab := (Gamma_pos_of_pos (add_pos ha hb)).ne'
  rw [← hexp]
  field_simp

#print axioms gamma_beta_identity

lemma gamma_conv_density {a b r z : ℝ} (ha : 0 < a) (hb : 0 < b) (hr : 0 < r) (hz : 0 < z) :
    ∫⁻ w, gammaPDF b r w * gammaPDF a r (z - w) = gammaPDF (a + b) r z := by
  set C : ℝ := r ^ (a + b) / Gamma (a + b) * z ^ (a + b - 1) * exp (-(r * z)) / z
  have hC : 0 ≤ C := by positivity
  rw [lintegral_eq_ofReal_mul_comp hz]
  have hae : (fun t => gammaPDF b r (z * t) * gammaPDF a r (z - z * t)) =ᵐ[volume]
      fun t => ENNReal.ofReal C * betaPDF b a t := by
    filter_upwards [Measure.ae_ne volume 0, Measure.ae_ne volume 1] with t h0 h1
    rcases lt_or_gt_of_ne h0 with ht | ht
    · rw [gammaPDF_of_neg (mul_neg_of_pos_of_neg hz ht), betaPDF_eq_zero_of_nonpos ht.le]
      simp
    rcases lt_or_gt_of_ne h1 with ht' | ht'
    · rw [gammaPDF_of_nonneg (by positivity), gammaPDF_of_nonneg (by nlinarith),
        betaPDF_of_pos_lt_one ht ht', ← ENNReal.ofReal_mul (by positivity),
        ← ENNReal.ofReal_mul hC]
      congr 1
      exact gamma_beta_identity ha hb hr hz ht ht'
    · rw [gammaPDF_of_neg (a := a) (by nlinarith), betaPDF_eq_zero_of_one_le ht'.le]
      simp
  have hmb : Measurable (betaPDF b a) := (measurable_betaPDFReal b a).ennreal_ofReal
  rw [lintegral_congr_ae hae, lintegral_const_mul _ hmb,
    lintegral_betaPDF_eq_one hb ha, mul_one, ← ENNReal.ofReal_mul hz.le,
    gammaPDF_of_nonneg hz.le]
  congr 1
  simp only [C]
  field_simp

#print axioms gamma_conv_density

lemma measurable_gammaPDF' (a r : ℝ) : Measurable (gammaPDF a r) :=
  (measurable_gammaPDFReal a r).ennreal_ofReal

#print axioms measurable_gammaPDF'

lemma map_prod_withDensity_apply {f g : ℝ → ℝ≥0∞} (hf : Measurable f) (hg : Measurable g)
    {F : ℝ × ℝ → ℝ} (hF : Measurable F) {s : Set ℝ} (hs : MeasurableSet s) :
    (((volume.withDensity f).prod (volume.withDensity g)).map F) s =
      ∫⁻ y, g y * ∫⁻ x, f x * s.indicator 1 (F (x, y)) := by
  have hm : Measurable ((F ⁻¹' s).indicator (1 : ℝ × ℝ → ℝ≥0∞)) :=
    measurable_one.indicator (hF hs)
  rw [Measure.map_apply hF hs, ← lintegral_indicator_one (hF hs),
    lintegral_prod_symm _ hm.aemeasurable,
    lintegral_withDensity_eq_lintegral_mul _ hg (hm.lintegral_prod_left')]
  congr 1; ext y
  simp only [Pi.mul_apply]
  congr 1
  exact lintegral_withDensity_eq_lintegral_mul _ hf (hm.comp measurable_prodMk_right)

#print axioms map_prod_withDensity_apply

lemma gamma_conv {a b r : ℝ} (ha : 0 < a) (hb : 0 < b) (hr : 0 < r) :
    ((gammaMeasure a r).prod (gammaMeasure b r)).map (fun p => p.1 + p.2) =
      gammaMeasure (a + b) r := by
  ext s hs
  have hma := measurable_gammaPDF' a r
  have hmb := measurable_gammaPDF' b r
  rw [gammaMeasure, gammaMeasure, map_prod_withDensity_apply hma hmb measurable_add hs,
    gammaMeasure, withDensity_apply _ hs]
  have hsi : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  have h1 : ∀ y, gammaPDF b r y * ∫⁻ x, gammaPDF a r x * s.indicator 1 ((x, y).1 + (x, y).2) =
      ∫⁻ z, gammaPDF b r y * gammaPDF a r (z - y) * s.indicator 1 z := by
    intro y
    rw [← lintegral_add_right_eq_self (fun z => gammaPDF b r y * gammaPDF a r (z - y) *
      s.indicator 1 z) y]
    simp only [add_sub_cancel_right, mul_assoc]
    rw [lintegral_const_mul' _ _ (by simp [gammaPDF])]
  simp_rw [h1]
  rw [lintegral_lintegral_swap (by fun_prop), ← lintegral_indicator hs]
  apply lintegral_congr_ae
  filter_upwards [Measure.ae_ne volume 0] with z hz
  by_cases hzs : z ∈ s
  · simp only [indicator_of_mem hzs, Pi.one_apply, mul_one]
    rcases lt_or_gt_of_ne hz with hz | hz
    · rw [gammaPDF_of_neg hz]
      apply lintegral_eq_zero_of_ae_eq_zero (Filter.Eventually.of_forall fun y => ?_)
      rcases lt_or_ge y 0 with hy | hy
      · simp [gammaPDF_of_neg hy]
      · simp [gammaPDF_of_neg (show z - y < 0 by linarith)]
    · exact gamma_conv_density ha hb hr hz
  · simp [hzs]

#print axioms gamma_conv

instance sFinite_gammaMeasure (a r : ℝ) : SFinite (gammaMeasure a r) := by
  unfold gammaMeasure; infer_instance

#print axioms sFinite_gammaMeasure

lemma sq_density_identity {x : ℝ} (hx : 0 < x) :
    |2 * x| * ((1 / 2 : ℝ) ^ (1 / 2 : ℝ) / Gamma (1 / 2) * (x ^ 2) ^ ((1 / 2 : ℝ) - 1) *
      exp (-(1 / 2 * x ^ 2))) =
    2 * ((√(2 * π * ((1 : ℝ≥0) : ℝ)))⁻¹ * exp (-(x - 0) ^ 2 / (2 * ((1 : ℝ≥0) : ℝ)))) := by
  rw [Gamma_one_half_eq, show (1 / 2 : ℝ) - 1 = -(1 / 2) by norm_num,
    rpow_neg (sq_nonneg x), ← sqrt_eq_rpow, ← sqrt_eq_rpow, sqrt_sq hx.le,
    abs_of_pos (by positivity), NNReal.coe_one, mul_one, sqrt_mul (by norm_num), sub_zero]
  have h2 : (0:ℝ) < √2 := by positivity
  have hp : (0:ℝ) < √π := by positivity
  have hs : √(1/2 : ℝ) = 1 / √2 := by rw [sqrt_div' _ (by norm_num), sqrt_one]
  rw [hs, show -(1 / 2 * x ^ 2) = -x ^ 2 / 2 by ring]
  field_simp

#print axioms sq_density_identity

lemma gaussianPDF_neg (x : ℝ) : gaussianPDF 0 1 (-x) = gaussianPDF 0 1 x := by
  simp [gaussianPDF, gaussianPDFReal]

#print axioms gaussianPDF_neg

lemma image_sq_Ioi : (fun x : ℝ => x ^ 2) '' Ioi 0 = Ioi 0 := by
  ext v; constructor
  · rintro ⟨x, hx, rfl⟩; exact pow_pos (mem_Ioi.mp hx) 2
  · intro hv; exact ⟨√v, sqrt_pos.2 hv, sq_sqrt (le_of_lt hv)⟩

#print axioms image_sq_Ioi

lemma gaussian_map_sq :
    (gaussianReal 0 1).map (fun x => x ^ 2) = gammaMeasure (1 / 2) (1 / 2) := by
  ext s hs
  have hsi : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  have hφ : Measurable (gaussianPDF 0 1) := by fun_prop
  set h : ℝ → ℝ≥0∞ := fun x => gaussianPDF 0 1 x * s.indicator 1 (x ^ 2) with hh
  have hmh : Measurable h := hφ.mul (hsi.comp (measurable_id.pow_const 2))
  have hpre : MeasurableSet ((fun x : ℝ => x ^ 2) ⁻¹' s) := (continuous_pow 2).measurable hs
  have hL : ((gaussianReal 0 1).map (fun x => x ^ 2)) s = ∫⁻ x, h x := by
    rw [Measure.map_apply (by fun_prop) hs, gaussianReal_of_var_ne_zero _ one_ne_zero,
      withDensity_apply _ hpre, ← lintegral_indicator hpre]
    congr 1; ext x
    by_cases hx : x ^ 2 ∈ s <;> simp [hh, indicator, hx]
  have hsym : ∫⁻ x in Iic 0, h x = ∫⁻ x in Ioi 0, h x := by
    rw [← lintegral_indicator measurableSet_Iic, ← lintegral_neg_eq_self,
      setLIntegral_congr Ioi_ae_eq_Ici, ← lintegral_indicator measurableSet_Ici]
    congr 1; ext x
    simp only [indicator, mem_Iic, mem_Ici, neg_nonpos, hh, gaussianPDF_neg]
    rw [neg_sq]
  have hL2 : ∫⁻ x, h x = 2 * ∫⁻ x in Ioi 0, h x := by
    rw [← lintegral_add_compl _ measurableSet_Iic, compl_Iic, hsym, two_mul]
  set G : ℝ → ℝ≥0∞ := fun v => gammaPDF (1 / 2) (1 / 2) v * s.indicator 1 v with hG
  have hR : (gammaMeasure (1 / 2) (1 / 2)) s = ∫⁻ v in Ioi 0, G v := by
    rw [gammaMeasure, withDensity_apply _ hs, ← lintegral_indicator hs,
      ← lintegral_add_compl _ measurableSet_Iic, compl_Iic,
      setLIntegral_eq_zero measurableSet_Iic, zero_add]
    · apply setLIntegral_congr_fun measurableSet_Ioi (fun x _ => ?_)
      simp only [hG, indicator, Pi.one_apply]
      split_ifs <;> simp
    · intro x hx
      simp only [indicator]
      split_ifs
      · rcases (mem_Iic.mp hx).lt_or_eq with hx | hx
        · exact gammaPDF_of_neg hx
        · rw [hx, gammaPDF_of_nonneg le_rfl, zero_rpow (by norm_num)]; simp
      · rfl
  have hI : ∫⁻ v in Ioi 0, G v = ∫⁻ x in Ioi 0, ENNReal.ofReal |2 * x| * G (x ^ 2) := by
    conv_lhs => rw [← image_sq_Ioi]
    exact lintegral_image_eq_lintegral_abs_deriv_mul measurableSet_Ioi
      (f' := fun x => 2 * x) (fun x _ => by simpa using (hasDerivAt_pow 2 x).hasDerivWithinAt)
      (fun x hx y hy hxy => (pow_left_inj₀ (mem_Ioi.mp hx).le (mem_Ioi.mp hy).le
        two_ne_zero).1 hxy) G
  rw [hL, hR, hL2, hI, ← lintegral_const_mul _ hmh]
  apply setLIntegral_congr_fun measurableSet_Ioi (fun x hx => ?_)
  have hx : 0 < x := hx
  simp only [hh, hG, ← mul_assoc]
  congr 1
  rw [gammaPDF_of_nonneg (sq_nonneg x), gaussianPDF, ← ENNReal.ofReal_mul (abs_nonneg _),
    sq_density_identity hx, ENNReal.ofReal_mul (by norm_num)]
  simp [gaussianPDFReal]

#print axioms gaussian_map_sq

lemma pi_sumsq_step (m : ℕ) :
    (Measure.pi (fun _ : Fin (m + 1) => gaussianReal 0 1)).map (fun x => ∑ i, x i ^ 2) =
      (((gaussianReal 0 1).map (fun x => x ^ 2)).prod
        ((Measure.pi (fun _ : Fin m => gaussianReal 0 1)).map (fun x => ∑ i, x i ^ 2))).map
          (fun p => p.1 + p.2) := by
  have hmp := measurePreserving_piFinSuccAbove (fun _ : Fin (m + 1) => gaussianReal 0 1) 0
  have hfun : (fun x : Fin (m + 1) → ℝ => ∑ i, x i ^ 2) =
      (fun p : ℝ × (Fin m → ℝ) => p.1 ^ 2 + ∑ i, p.2 i ^ 2) ∘
        (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (m + 1) => ℝ) 0) := by
    ext x
    simp [Fin.sum_univ_succ, MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv, Fin.tail]
  rw [hfun, ← Measure.map_map (by fun_prop) (MeasurableEquiv.measurable _), hmp.map_eq,
    Measure.map_prod_map _ _ (by fun_prop) (by fun_prop), Measure.map_map (by fun_prop)
      (by fun_prop)]
  rfl

#print axioms pi_sumsq_step

lemma pi_sumsq_chi' (m : ℕ) :
    (Measure.pi (fun _ : Fin (m + 1) => gaussianReal 0 1)).map (fun x => ∑ i, x i ^ 2) =
      gammaMeasure (((m + 1 : ℕ) : ℝ) / 2) (1 / 2) := by
  induction m with
  | zero =>
    rw [pi_sumsq_step, gaussian_map_sq]
    simp only [Finset.univ_eq_empty, Finset.sum_empty, Measure.map_const, measure_univ,
      one_smul]
    rw [Measure.prod_dirac, Measure.map_map (by fun_prop) (by fun_prop)]
    simp [Function.comp_def]
  | succ m ih =>
    rw [pi_sumsq_step, gaussian_map_sq, ih, gamma_conv (by norm_num) (by positivity)
      (by norm_num)]
    congr 1
    push_cast; ring

#print axioms pi_sumsq_chi'

lemma pi_sumsq_chi (k : ℕ) (hk : 0 < k) :
    (Measure.pi (fun _ : Fin k => gaussianReal 0 1)).map (fun x => ∑ i, x i ^ 2) =
      gammaMeasure ((k : ℝ) / 2) (1 / 2) := by
  obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
  exact pi_sumsq_chi' m

#print axioms pi_sumsq_chi

lemma pi_head_rest (m : ℕ) (hm : 0 < m) :
    (Measure.pi (fun _ : Fin (m + 1) => gaussianReal 0 1)).map
      (fun x => (x 0, ∑ i, x i ^ 2 - x 0 ^ 2)) =
      (gaussianReal 0 1).prod (gammaMeasure ((m : ℝ) / 2) (1 / 2)) := by
  have hmp := measurePreserving_piFinSuccAbove (fun _ : Fin (m + 1) => gaussianReal 0 1) 0
  have hfun : (fun x : Fin (m + 1) → ℝ => (x 0, ∑ i, x i ^ 2 - x 0 ^ 2)) =
      (Prod.map id (fun y : Fin m → ℝ => ∑ i, y i ^ 2)) ∘
        (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (m + 1) => ℝ) 0) := by
    ext x
    · simp [MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv]
    · simp [Fin.sum_univ_succ, MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv, Fin.tail]
  rw [hfun, ← Measure.map_map (by fun_prop) (MeasurableEquiv.measurable _), hmp.map_eq,
    ← Measure.map_prod_map _ _ (by fun_prop) (by fun_prop), Measure.map_id, pi_sumsq_chi m hm]

#print axioms pi_head_rest

@[fun_prop]
lemma measurable_sampleMean (n : ℕ) : Measurable (fun x : Fin n → ℝ => sampleMean x) := by
  unfold sampleMean; fun_prop

#print axioms measurable_sampleMean

lemma sum_sq_sub_mean {n : ℕ} (hn : 0 < n) (x : Fin n → ℝ) :
    ∑ i, (x i - sampleMean x) ^ 2 = ∑ i, x i ^ 2 - (∑ i, x i) ^ 2 / n := by
  have hN : (n : ℝ) ≠ 0 := by positivity
  simp only [sampleMean, sub_sq, Finset.sum_add_distrib, Finset.sum_sub_distrib,
    ← Finset.sum_mul, ← Finset.mul_sum, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
    nsmul_eq_mul]
  field_simp
  ring

#print axioms sum_sq_sub_mean

lemma pi_sample_stats (n : ℕ) (hn : 2 ≤ n) :
    (Measure.pi (fun _ : Fin n => gaussianReal 0 1)).map
      (fun x => (√(n : ℝ) * sampleMean x, ∑ i, (x i - sampleMean x) ^ 2)) =
    (gaussianReal 0 1).prod (gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2)) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  set N : ℝ := ((m + 1 : ℕ) : ℝ) with hNdef
  have hN : 0 < N := by positivity
  let E := EuclideanSpace ℝ (Fin (m + 1))
  let u : E := WithLp.toLp 2 (fun _ => 1 / √N)
  let e0 : E := EuclideanSpace.single 0 1
  have he0 : ‖e0‖ = 1 := by
    have : ‖e0‖ ^ 2 = 1 := by
      rw [EuclideanSpace.real_norm_sq_eq]
      simp [e0]
    nlinarith [norm_nonneg e0]
  have hu1 : ‖u‖ = 1 := by
    have : ‖u‖ ^ 2 = 1 := by
      rw [EuclideanSpace.real_norm_sq_eq]
      simp [u, Real.sq_sqrt hN.le, ← hNdef]
    nlinarith [norm_nonneg u]
  have hu : ‖u‖ = ‖e0‖ := by rw [he0, hu1]
  let R := (ℝ ∙ (u - e0))ᗮ.reflection
  have hRu : R u = e0 := Submodule.reflection_sub hu
  have hRe : R e0 = u := by rw [← hRu, Submodule.reflection_reflection]
  have h0 : ∀ z : E, (R z).ofLp 0 = ∑ i, z.ofLp i / √N := by
    intro z
    have h1 : (R z).ofLp 0 = inner ℝ e0 (R z) := by
      rw [EuclideanSpace.inner_single_left]; simp
    rw [h1, ← LinearIsometryEquiv.inner_map_map R, hRe, Submodule.reflection_reflection]
    rw [PiLp.inner_apply]; simp [u, div_eq_mul_inv, mul_comm]
  have hsq : ∀ z : E, ∑ i, (R z).ofLp i ^ 2 = ∑ i, z.ofLp i ^ 2 := by
    intro z
    rw [← EuclideanSpace.real_norm_sq_eq, ← EuclideanSpace.real_norm_sq_eq,
      LinearIsometryEquiv.norm_map]
  have hsN : √N ^ 2 = N := Real.sq_sqrt hN.le
  have hsN0 : √N ≠ 0 := by positivity
  have hstat : (fun x : Fin (m + 1) → ℝ => (√N * sampleMean x, ∑ i, (x i - sampleMean x) ^ 2)) =
      (fun y : Fin (m + 1) → ℝ => (y 0, ∑ i, y i ^ 2 - y 0 ^ 2)) ∘ WithLp.ofLp ∘ R ∘
        WithLp.toLp 2 := by
    ext x
    · simp only [Function.comp_apply, h0, ← Finset.sum_div, sampleMean, ← hNdef]
      field_simp
      rw [hsN]; ring
    · simp only [Function.comp_apply, h0, hsq, ← Finset.sum_div,
        sum_sq_sub_mean (Nat.succ_pos m), ← hNdef]
      rw [div_pow, hsN]
  rw [hstat, ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_map (by fun_prop) (by fun_prop), map_pi_eq_stdGaussian, stdGaussian_map R,
    ← map_pi_eq_stdGaussian, Measure.map_map (by fun_prop) (by fun_prop)]
  rw [Measure.map_map (by fun_prop) (by fun_prop)]
  convert pi_head_rest m (by omega) using 3
  all_goals first | rfl | (rw [hNdef]; push_cast; ring)

#print axioms pi_sample_stats

lemma t_pointwise {ν v t : ℝ} (hν : 0 < ν) (hv : 0 < v) :
    (1 / 2 : ℝ) ^ (ν / 2) / Gamma (ν / 2) * v ^ (ν / 2 - 1) * exp (-(1 / 2 * v)) *
      (√(v / ν) * ((√(2 * π * ((1 : ℝ≥0) : ℝ)))⁻¹ *
        exp (-(√(v / ν) * t - 0) ^ 2 / (2 * ((1 : ℝ≥0) : ℝ))))) =
    (1 / 2 : ℝ) ^ (ν / 2) / (Gamma (ν / 2) * √(2 * π * ν)) *
      (v ^ ((ν + 1) / 2 - 1) * exp (-((1 + t ^ 2 / ν) / 2 * v))) := by
  have hexp : exp (-(1 / 2 * v)) * exp (-(√(v / ν) * t - 0) ^ 2 / (2 * ((1 : ℝ≥0) : ℝ))) =
      exp (-((1 + t ^ 2 / ν) / 2 * v)) := by
    rw [← exp_add, sub_zero, mul_pow, sq_sqrt (by positivity)]
    congr 1; push_cast; field_simp; ring
  rw [show (ν + 1) / 2 - 1 = (ν / 2 - 1) + 1 / 2 by ring, rpow_add hv, ← sqrt_eq_rpow, ← hexp,
    sqrt_div' _ hν.le, NNReal.coe_one, mul_one, sqrt_mul (by positivity) ν]
  have h1 := (Gamma_pos_of_pos (half_pos hν)).ne'
  have h2 : 0 < √(2 * π) := by positivity
  have h3 : 0 < √ν := by positivity
  field_simp

#print axioms t_pointwise

lemma t_const {ν t : ℝ} (hν : 0 < ν) :
    (1 / 2 : ℝ) ^ (ν / 2) / (Gamma (ν / 2) * √(2 * π * ν)) *
      ((1 / ((1 + t ^ 2 / ν) / 2)) ^ ((ν + 1) / 2) * Gamma ((ν + 1) / 2)) = studentTPDF ν t := by
  have hb : 0 < 1 + t ^ 2 / ν := by positivity
  rw [studentTPDF, one_div_div, div_rpow (by norm_num) hb.le,
    show -(ν + 1) / 2 = -((ν + 1) / 2) by ring, rpow_neg hb.le,
    show (ν + 1) / 2 = ν / 2 + 1 / 2 by ring, rpow_add (by norm_num : (0:ℝ) < 2),
    ← sqrt_eq_rpow, div_rpow (by norm_num) (by norm_num), one_rpow,
    show 2 * π * ν = 2 * (ν * π) by ring, sqrt_mul (by norm_num)]
  have h1 := (Gamma_pos_of_pos (half_pos hν)).ne'
  have h2 : 0 < √2 := by positivity
  have h3 : 0 < √(ν * π) := by positivity
  have h4 : 0 < (2 : ℝ) ^ (ν / 2) := by positivity
  have h5 : 0 < (1 + t ^ 2 / ν) ^ (ν / 2 + 1 / 2) := by positivity
  field_simp

#print axioms t_const

lemma t_density_at {ν : ℝ} (hν : 0 < ν) (t : ℝ) :
    ∫⁻ v, gammaPDF (ν / 2) (1 / 2) v * (ENNReal.ofReal (√(v / ν)) *
      gaussianPDF 0 1 (√(v / ν) * t)) = ENNReal.ofReal (studentTPDF ν t) := by
  rw [← lintegral_add_compl _ measurableSet_Iic, compl_Iic,
    setLIntegral_eq_zero measurableSet_Iic, zero_add]
  · rw [setLIntegral_congr_fun measurableSet_Ioi (g := fun v => ENNReal.ofReal
      ((1 / 2 : ℝ) ^ (ν / 2) / (Gamma (ν / 2) * √(2 * π * ν)) *
      (v ^ ((ν + 1) / 2 - 1) * exp (-((1 + t ^ 2 / ν) / 2 * v)))))]
    · rw [← t_const hν (t := t), ENNReal.ofReal_mul (by positivity),
        ← lintegral_rpow_exp_Ioi (by positivity) (by positivity),
        ← lintegral_const_mul]
      · simp_rw [← ENNReal.ofReal_mul (by positivity : (0:ℝ) ≤ (1 / 2 : ℝ) ^ (ν / 2) /
          (Gamma (ν / 2) * √(2 * π * ν)))]
        rfl
      · exact (((measurable_id.pow_const _).mul
          (measurable_id.const_mul _).neg.exp)).ennreal_ofReal
    · intro v hv
      have hv : 0 < v := hv
      dsimp only
      rw [gammaPDF_of_nonneg hv.le, gaussianPDF, gaussianPDFReal, ← ENNReal.ofReal_mul
        (by positivity), ← ENNReal.ofReal_mul (by positivity), t_pointwise hν hv]
  · intro v hv
    rcases (mem_Iic.mp hv).lt_or_eq with hv | hv
    · dsimp only; rw [gammaPDF_of_neg hv, zero_mul]; rfl
    · rw [hv]; simp

#print axioms t_density_at

lemma t_law {ν : ℝ} (hν : 0 < ν) :
    ((gaussianReal 0 1).prod (gammaMeasure (ν / 2) (1 / 2))).map (fun p => p.1 / √(p.2 / ν)) =
      volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ν t)) := by
  ext s hs
  have hφ : Measurable (gaussianPDF 0 1) := by fun_prop
  have hg := measurable_gammaPDF' (ν / 2) (1 / 2)
  have hsi : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  rw [gaussianReal_of_var_ne_zero 0 one_ne_zero, gammaMeasure,
    map_prod_withDensity_apply hφ hg (by fun_prop) hs, withDensity_apply _ hs]
  have h1 : ∀ᵐ v ∂volume, gammaPDF (ν / 2) (1 / 2) v *
      ∫⁻ z, gaussianPDF 0 1 z * s.indicator 1 ((z, v).1 / √((z, v).2 / ν)) =
      ∫⁻ t, gammaPDF (ν / 2) (1 / 2) v * (ENNReal.ofReal (√(v / ν)) *
        gaussianPDF 0 1 (√(v / ν) * t)) * s.indicator 1 t := by
    filter_upwards [Measure.ae_ne volume 0] with v hv
    rcases lt_or_gt_of_ne hv with hv | hv
    · simp [gammaPDF_of_neg hv]
    · have hc : 0 < √(v / ν) := sqrt_pos.2 (div_pos hv hν)
      rw [lintegral_eq_ofReal_mul_comp hc, ← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top,
        ← lintegral_const_mul' _ _ (by simp [gammaPDF])]
      congr 1; ext t
      simp only [mul_div_cancel_left₀ t hc.ne']
      ring
  rw [lintegral_congr_ae h1, lintegral_lintegral_swap, ← lintegral_indicator hs]
  · congr 1; ext t
    rw [lintegral_mul_const _ (by fun_prop), t_density_at hν t]
    by_cases ht : t ∈ s <;> simp [ht]
  · apply Measurable.aemeasurable
    apply Measurable.mul _ (hsi.comp measurable_snd)
    apply Measurable.mul (hg.comp measurable_fst)
    exact ((measurable_fst.div_const ν).sqrt.ennreal_ofReal).mul
      (hφ.comp (((measurable_fst.div_const ν).sqrt).mul measurable_snd))

#print axioms t_law

lemma f_pointwise {a b q w x : ℝ} (ha : 0 < a) (hb : 0 < b) (hq : 0 < q) (hw : 0 < w) (hx : 0 < x) :
    (1 / 2 : ℝ) ^ b / Gamma b * w ^ (b - 1) * exp (-(1 / 2 * w)) *
      (q * w * ((1 / 2 : ℝ) ^ a / Gamma a * (q * w * x) ^ (a - 1) *
        exp (-(1 / 2 * (q * w * x))))) =
    (1 / 2 : ℝ) ^ a * (1 / 2 : ℝ) ^ b / (Gamma a * Gamma b) * q ^ a * x ^ (a - 1) *
      (w ^ ((a + b) - 1) * exp (-((1 + q * x) / 2 * w))) := by
  have hexp : exp (-(1 / 2 * w)) * exp (-(1 / 2 * (q * w * x))) =
      exp (-((1 + q * x) / 2 * w)) := by
    rw [← exp_add]; congr 1; ring
  rw [mul_rpow (by positivity) hx.le, mul_rpow hq.le hw.le,
    show a + b - 1 = (b - 1) + (a - 1) + 1 by ring, rpow_add hw, rpow_add hw, rpow_one,
    show q ^ a = q ^ (a - 1 + 1) by ring_nf, rpow_add hq, rpow_one, ← hexp]
  have h1 : Gamma a ≠ 0 := (Gamma_pos_of_pos ha).ne'
  have h2 : Gamma b ≠ 0 := (Gamma_pos_of_pos hb).ne'
  field_simp

#print axioms f_pointwise

lemma f_const {ν₁ ν₂ x : ℝ} (h1 : 0 < ν₁) (h2 : 0 < ν₂) (hx : 0 < x) :
    (1 / 2 : ℝ) ^ (ν₁ / 2) * (1 / 2 : ℝ) ^ (ν₂ / 2) / (Gamma (ν₁ / 2) * Gamma (ν₂ / 2)) *
      (ν₁ / ν₂) ^ (ν₁ / 2) * x ^ (ν₁ / 2 - 1) *
      ((1 / ((1 + ν₁ / ν₂ * x) / 2)) ^ (ν₁ / 2 + ν₂ / 2) * Gamma (ν₁ / 2 + ν₂ / 2)) =
    fisherFPDF ν₁ ν₂ x := by
  have hb : 0 < 1 + ν₁ / ν₂ * x := by positivity
  simp only [fisherFPDF, hx, ↓reduceIte]
  rw [one_div_div, div_rpow (by norm_num) hb.le,
    show (ν₁ + ν₂) / 2 = ν₁ / 2 + ν₂ / 2 by ring, rpow_add (by norm_num : (0:ℝ) < 2),
    div_rpow (by norm_num) (by norm_num), div_rpow (by norm_num) (by norm_num), one_rpow, one_rpow]
  have g1 := (Gamma_pos_of_pos (half_pos h1)).ne'
  have g2 := (Gamma_pos_of_pos (half_pos h2)).ne'
  have h4 : 0 < (2 : ℝ) ^ (ν₁ / 2) := by positivity
  have h4' : 0 < (2 : ℝ) ^ (ν₂ / 2) := by positivity
  have h5 : 0 < (1 + ν₁ / ν₂ * x) ^ (ν₁ / 2 + ν₂ / 2) := by positivity
  field_simp

#print axioms f_const

lemma f_density_at {ν₁ ν₂ : ℝ} (h1 : 0 < ν₁) (h2 : 0 < ν₂) {x : ℝ} (hx : x ≠ 0) :
    ∫⁻ w, gammaPDF (ν₂ / 2) (1 / 2) w * (ENNReal.ofReal (ν₁ / ν₂ * w) *
      gammaPDF (ν₁ / 2) (1 / 2) (ν₁ / ν₂ * w * x)) = ENNReal.ofReal (fisherFPDF ν₁ ν₂ x) := by
  have hq : 0 < ν₁ / ν₂ := div_pos h1 h2
  rcases lt_or_gt_of_ne hx with hx | hx
  · have : fisherFPDF ν₁ ν₂ x = 0 := by simp [fisherFPDF, hx.not_gt]
    rw [this, ENNReal.ofReal_zero]
    apply lintegral_eq_zero_of_ae_eq_zero (Filter.Eventually.of_forall fun w => ?_)
    rcases lt_trichotomy w 0 with hw | hw | hw
    · simp [gammaPDF_of_neg hw]
    · simp [hw]
    · simp [gammaPDF_of_neg (mul_neg_of_pos_of_neg (mul_pos hq hw) hx)]
  rw [← lintegral_add_compl _ measurableSet_Iic, compl_Iic,
    setLIntegral_eq_zero measurableSet_Iic, zero_add]
  · rw [setLIntegral_congr_fun measurableSet_Ioi (g := fun w => ENNReal.ofReal
      ((1 / 2 : ℝ) ^ (ν₁ / 2) * (1 / 2 : ℝ) ^ (ν₂ / 2) / (Gamma (ν₁ / 2) * Gamma (ν₂ / 2)) *
        (ν₁ / ν₂) ^ (ν₁ / 2) * x ^ (ν₁ / 2 - 1) *
      (w ^ ((ν₁ / 2 + ν₂ / 2) - 1) * exp (-((1 + ν₁ / ν₂ * x) / 2 * w)))))]
    · rw [← f_const h1 h2 hx, ENNReal.ofReal_mul (by positivity),
        ← lintegral_rpow_exp_Ioi (by positivity) (by positivity),
        ← lintegral_const_mul]
      · simp_rw [← ENNReal.ofReal_mul (by positivity : (0:ℝ) ≤ (1 / 2 : ℝ) ^ (ν₁ / 2) *
          (1 / 2 : ℝ) ^ (ν₂ / 2) / (Gamma (ν₁ / 2) * Gamma (ν₂ / 2)) *
          (ν₁ / ν₂) ^ (ν₁ / 2) * x ^ (ν₁ / 2 - 1))]
        rfl
      · exact (((measurable_id.pow_const _).mul
          (measurable_id.const_mul _).neg.exp)).ennreal_ofReal
    · intro w hw
      have hw : 0 < w := hw
      dsimp only
      rw [gammaPDF_of_nonneg hw.le, gammaPDF_of_nonneg (by positivity), ← ENNReal.ofReal_mul
        (by positivity), ← ENNReal.ofReal_mul (by positivity),
        f_pointwise (half_pos h1) (half_pos h2) hq hw hx]
  · intro w hw
    rcases (mem_Iic.mp hw).lt_or_eq with hw | hw
    · dsimp only; rw [gammaPDF_of_neg hw, zero_mul]; rfl
    · rw [hw]; simp

#print axioms f_density_at

lemma f_law {ν₁ ν₂ : ℝ} (h1 : 0 < ν₁) (h2 : 0 < ν₂) :
    ((gammaMeasure (ν₁ / 2) (1 / 2)).prod (gammaMeasure (ν₂ / 2) (1 / 2))).map
      (fun p => (p.1 / ν₁) / (p.2 / ν₂)) =
      volume.withDensity (fun x => ENNReal.ofReal (fisherFPDF ν₁ ν₂ x)) := by
  ext s hs
  have ha := measurable_gammaPDF' (ν₁ / 2) (1 / 2)
  have hb := measurable_gammaPDF' (ν₂ / 2) (1 / 2)
  have hq : 0 < ν₁ / ν₂ := div_pos h1 h2
  have hsi : Measurable (s.indicator (1 : ℝ → ℝ≥0∞)) := measurable_one.indicator hs
  rw [gammaMeasure, gammaMeasure, map_prod_withDensity_apply ha hb (by fun_prop) hs,
    withDensity_apply _ hs]
  have e1 : ∀ᵐ w ∂volume, gammaPDF (ν₂ / 2) (1 / 2) w *
      ∫⁻ u, gammaPDF (ν₁ / 2) (1 / 2) u * s.indicator 1 (((u, w).1 / ν₁) / ((u, w).2 / ν₂)) =
      ∫⁻ x, gammaPDF (ν₂ / 2) (1 / 2) w * (ENNReal.ofReal (ν₁ / ν₂ * w) *
        gammaPDF (ν₁ / 2) (1 / 2) (ν₁ / ν₂ * w * x)) * s.indicator 1 x := by
    filter_upwards [Measure.ae_ne volume 0] with w hw
    rcases lt_or_gt_of_ne hw with hw | hw
    · simp [gammaPDF_of_neg hw]
    · have hc : 0 < ν₁ / ν₂ * w := mul_pos hq hw
      rw [lintegral_eq_ofReal_mul_comp hc, ← lintegral_const_mul' _ _ ENNReal.ofReal_ne_top,
        ← lintegral_const_mul' _ _ (by simp [gammaPDF])]
      congr 1; ext x
      have : ν₁ / ν₂ * w * x / ν₁ / (w / ν₂) = x := by field_simp
      simp only [this]
      ring
  rw [lintegral_congr_ae e1, lintegral_lintegral_swap, ← lintegral_indicator hs]
  · apply lintegral_congr_ae
    filter_upwards [Measure.ae_ne volume 0] with x hx
    rw [lintegral_mul_const _ (by fun_prop), f_density_at h1 h2 hx]
    by_cases hxs : x ∈ s <;> simp [hxs]
  · apply Measurable.aemeasurable
    apply Measurable.mul _ (hsi.comp measurable_snd)
    apply Measurable.mul (hb.comp measurable_fst)
    exact ((measurable_fst.const_mul _).ennreal_ofReal).mul
      (ha.comp ((measurable_fst.const_mul _).mul measurable_snd))

#print axioms f_law

lemma gamma_moment_fun {a r : ℝ} (p : ℕ) (hp : 1 ≤ p) :
    (fun x => gammaPDFReal a r x * x ^ p) =
      (Ioi 0).indicator (fun x => r ^ a / Gamma a * (x ^ (a + p - 1) * exp (-(r * x)))) := by
  ext x
  by_cases hx : 0 < x
  · simp only [indicator, mem_Ioi, hx, ↓reduceIte, gammaPDFReal, hx.le]
    rw [show a + p - 1 = (a - 1) + (p : ℝ) by ring, rpow_add hx, rpow_natCast]
    ring
  · simp only [indicator, mem_Ioi, hx, ↓reduceIte]
    rcases (not_lt.mp hx).lt_or_eq with hx | hx
    · simp [gammaPDFReal, hx.not_ge]
    · rw [hx]; simp [zero_pow (by omega : p ≠ 0)]

#print axioms gamma_moment_fun

lemma gamma_moment {a r : ℝ} (ha : 0 < a) (hr : 0 < r) (p : ℕ) (hp : 1 ≤ p) :
    Integrable (fun x => x ^ p) (gammaMeasure a r) ∧
      ∫ x, x ^ p ∂(gammaMeasure a r) = r ^ a / Gamma a * ((1 / r) ^ (a + p) * Gamma (a + p)) := by
  have hm := measurable_gammaPDF' a r
  have hlt : ∀ᵐ x ∂(volume : Measure ℝ), gammaPDF a r x < ∞ :=
    Filter.Eventually.of_forall fun x => by simp [gammaPDF]
  have hto : ∀ x, (gammaPDF a r x).toReal = gammaPDFReal a r x := fun x =>
    ENNReal.toReal_ofReal (gammaPDFReal_nonneg ha hr x)
  have hap : 0 < a + p := by positivity
  have hI : ∫ x in Ioi (0:ℝ), r ^ a / Gamma a * (x ^ (a + p - 1) * exp (-(r * x))) =
      r ^ a / Gamma a * ((1 / r) ^ (a + p) * Gamma (a + p)) := by
    rw [integral_const_mul, integral_rpow_mul_exp_neg_mul_Ioi hap hr]
  have hint : IntegrableOn (fun x => r ^ a / Gamma a * (x ^ (a + p - 1) * exp (-(r * x))))
      (Ioi 0) := by
    apply Integrable.of_integral_ne_zero
    rw [hI]; positivity
  constructor
  · rw [gammaMeasure, integrable_withDensity_iff hm hlt]
    simp_rw [hto, mul_comm _ (gammaPDFReal a r _)]
    rw [gamma_moment_fun p hp, integrable_indicator_iff measurableSet_Ioi]
    exact hint
  · rw [gammaMeasure, integral_withDensity_eq_integral_toReal_smul hm hlt]
    simp_rw [hto, smul_eq_mul]
    rw [gamma_moment_fun p hp, integral_indicator measurableSet_Ioi, hI]

#print axioms gamma_moment

lemma gamma_mean {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    ∫ x, x ∂(gammaMeasure a r) = a / r := by
  have h := (gamma_moment ha hr 1 le_rfl).2
  simp only [pow_one, Nat.cast_one] at h
  rw [h, Gamma_add_one ha.ne', rpow_add_one (by positivity), div_rpow zero_le_one hr.le,
    one_rpow]
  have := (Gamma_pos_of_pos ha).ne'
  have : r ^ a ≠ 0 := (rpow_pos_of_pos hr a).ne'
  field_simp

#print axioms gamma_mean

lemma gamma_variance {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    variance id (gammaMeasure a r) = a / r ^ 2 := by
  have := isProbabilityMeasure_gammaMeasure ha hr
  have h2 := gamma_moment ha hr 2 (by norm_num)
  have hmem : MemLp id 2 (gammaMeasure a r) :=
    (memLp_two_iff_integrable_sq aestronglyMeasurable_id).2 h2.1
  rw [variance_eq_sub hmem]
  simp only [id_eq]
  rw [show (∫ x, x ∂(gammaMeasure a r)) = a / r from gamma_mean ha hr]
  rw [show (∫ x, (id ^ 2 : ℝ → ℝ) x ∂(gammaMeasure a r)) = ∫ x, x ^ 2 ∂(gammaMeasure a r) from rfl,
    h2.2]
  rw [show a + ((2 : ℕ) : ℝ) = (a + 1) + 1 by push_cast; ring, Gamma_add_one (by positivity),
    Gamma_add_one ha.ne', rpow_add_one (by positivity), rpow_add_one (by positivity),
    div_rpow zero_le_one hr.le, one_rpow]
  have := (Gamma_pos_of_pos ha).ne'
  have : r ^ a ≠ 0 := (rpow_pos_of_pos hr a).ne'
  field_simp
  ring

#print axioms gamma_variance

lemma gaussianReal_singleton (μ : ℝ) {v : ℝ≥0} (hv : v ≠ 0) (c : ℝ) :
    gaussianReal μ v {c} = 0 := by
  rw [gaussianReal_of_var_ne_zero μ hv, withDensity_apply _ (measurableSet_singleton c),
    Measure.restrict_eq_zero.2 Real.volume_singleton, lintegral_zero_measure]

#print axioms gaussianReal_singleton

lemma aemeasurable_of_map_eq {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {f : Ω → ℝ}
    {μ : Measure ℝ} (hμ : ∀ c, μ {c} = 0) (h : P.map f = μ) : AEMeasurable f P := by
  by_contra hf
  rw [Measure.map_of_not_aemeasurable_of_ne_zero hf (IsProbabilityMeasure.ne_zero P)] at h
  have := congrArg (fun m : Measure ℝ => m {Classical.ofNonempty}) h
  simp [hμ] at this

#print axioms aemeasurable_of_map_eq

lemma gaussian_standardize (μ : ℝ) {σ : ℝ≥0} (hσ : 0 < σ) :
    (gaussianReal μ (σ ^ 2)).map (fun x => (x - μ) / σ) = gaussianReal 0 1 := by
  have h : (fun x : ℝ => (x - μ) / σ) = (· / (σ : ℝ)) ∘ (· - μ) := rfl
  rw [h, ← Measure.map_map (by fun_prop) (by fun_prop), gaussianReal_map_sub_const,
    gaussianReal_map_div_const, sub_self, zero_div]
  congr 1
  ext
  have : (σ : ℝ) ≠ 0 := by positivity
  simp [this]

#print axioms gaussian_standardize

lemma pi_gaussian_standardize (n : ℕ) (μ : ℝ) {σ : ℝ≥0} (hσ : 0 < σ) :
    (Measure.pi (fun _ : Fin n => gaussianReal μ (σ ^ 2))).map
      (fun x i => (x i - μ) / σ) = Measure.pi (fun _ : Fin n => gaussianReal 0 1) := by
  refine (Measure.pi_map_pi (μ := fun _ : Fin n => gaussianReal μ (σ ^ 2))
    (f := fun _ y => (y - μ) / (σ : ℝ)) (fun _ => by fun_prop)).trans ?_
  simp_rw [gaussian_standardize μ hσ]

#print axioms pi_gaussian_standardize

lemma sampleMean_standardize {n : ℕ} (hn : 0 < n) (x : Fin n → ℝ) (μ σ : ℝ) :
    sampleMean (fun i => (x i - μ) / σ) = (sampleMean x - μ) / σ := by
  have hN : (n : ℝ) ≠ 0 := by positivity
  simp only [sampleMean, ← Finset.sum_div, Finset.sum_sub_distrib, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  by_cases hσ : σ = 0
  · simp [hσ]
  field_simp

#print axioms sampleMean_standardize

lemma pi_gaussian_sample_stats (n : ℕ) (hn : 2 ≤ n) (μ : ℝ) {σ : ℝ≥0} (hσ : 0 < σ) :
    (Measure.pi (fun _ : Fin n => gaussianReal μ (σ ^ 2))).map
      (fun x => (√(n : ℝ) * ((sampleMean x - μ) / σ),
        (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2)) =
    (gaussianReal 0 1).prod (gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2)) := by
  have hσ' : (σ : ℝ) ≠ 0 := by positivity
  have hfun : (fun x : Fin n → ℝ => (√(n : ℝ) * ((sampleMean x - μ) / σ),
        (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2)) =
      (fun z : Fin n → ℝ => (√(n : ℝ) * sampleMean z, ∑ i, (z i - sampleMean z) ^ 2)) ∘
        (fun x i => (x i - μ) / σ) := by
    ext x
    · simp [sampleMean_standardize (by omega : 0 < n)]
    · simp only [Function.comp_apply, sampleMean_standardize (by omega : 0 < n), Finset.sum_div]
      congr 1; ext i
      field_simp
      ring
  rw [hfun, ← Measure.map_map (by fun_prop) (by fun_prop), pi_gaussian_standardize n μ hσ,
    pi_sample_stats n hn]

#print axioms pi_gaussian_sample_stats

lemma pi_gaussian_sumsq_law (n : ℕ) (hn : 2 ≤ n) (μ : ℝ) {σ : ℝ≥0} (hσ : 0 < σ) :
    (Measure.pi (fun _ : Fin n => gaussianReal μ (σ ^ 2))).map
      (fun x => (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2) =
    gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2) := by
  have := pi_gaussian_sample_stats n hn μ hσ
  rw [show (fun x : Fin n → ℝ => (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2) =
      Prod.snd ∘ (fun x => (√(n : ℝ) * ((sampleMean x - μ) / σ),
        (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2)) from rfl,
    ← Measure.map_map measurable_snd (by fun_prop), this, Measure.map_snd_prod, measure_univ,
    one_smul]

#print axioms pi_gaussian_sumsq_law

/-- **What a normal sample gives.** Take n ≥ 2 independent measurements X₁, …, Xₙ, each normal
with true mean μ and true standard deviation σ > 0. Let X̄ be their average and S² their sample
variance (divided by n − 1). Then
* (n − 1) S² / σ² has the chi-square law with n − 1 degrees of freedom, that is, the gamma
  law with shape (n − 1)/2 and rate 1/2;
* the average X̄ and the sample variance S² are independent;
* the t ratio (X̄ − μ) / (S/√n) has Student's t density with n − 1 degrees of freedom.
The unknown σ has cancelled from both laws. -/
theorem normal_sample_statistics_follow_chi_square_and_t
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n : ℕ) (hn : 2 ≤ n) (μ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (X : Fin n → Ω → ℝ) (hind : iIndepFun X P)
    (hlaw : ∀ i, P.map (X i) = gaussianReal μ (σ ^ 2)) :
    P.map (fun ω => ((n : ℝ) - 1) * sampleVar (fun i => X i ω) / (σ : ℝ) ^ 2) =
        gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2) ∧
      IndepFun (fun ω => sampleMean (fun i => X i ω)) (fun ω => sampleVar (fun i => X i ω)) P ∧
      P.map (fun ω => (sampleMean (fun i => X i ω) - μ) /
          (√(sampleVar (fun i => X i ω)) / √(n : ℝ))) =
        volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ((n : ℝ) - 1) t)) := by
  have hσ' : (σ : ℝ) ≠ 0 := by positivity
  have hm : ∀ i, AEMeasurable (X i) P := fun i =>
    aemeasurable_of_map_eq (gaussianReal_singleton μ (pow_ne_zero 2 hσ.ne')) (hlaw i)
  have hvm : AEMeasurable (fun ω i => X i ω) P := AEMeasurable.of_eval hm
  have hvec : P.map (fun ω i => X i ω) =
      Measure.pi (fun _ : Fin n => gaussianReal μ (σ ^ 2)) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map hm).1 hind]
    simp_rw [hlaw]
  set Gf : (Fin n → ℝ) → ℝ × ℝ := fun x => (√(n : ℝ) * ((sampleMean x - μ) / σ),
    (∑ i, (x i - sampleMean x) ^ 2) / (σ : ℝ) ^ 2) with hGf
  have hGm : Measurable Gf := by fun_prop
  set W : Ω → ℝ × ℝ := fun ω => Gf (fun i => X i ω) with hWdef
  have hWm : AEMeasurable W P := hGm.comp_aemeasurable hvm
  have hW : P.map W = (gaussianReal 0 1).prod (gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2)) := by
    rw [show W = Gf ∘ (fun ω i => X i ω) from rfl,
      ← AEMeasurable.map_map_of_aemeasurable hGm.aemeasurable hvm, hvec,
      pi_gaussian_sample_stats n hn μ hσ]
  have hn2 : (2 : ℝ) ≤ n := by exact_mod_cast hn
  have hn1 : (n : ℝ) - 1 ≠ 0 := by linarith
  have hsn : √(n : ℝ) ≠ 0 := by positivity
  have hGp : IsProbabilityMeasure (gammaMeasure (((n : ℝ) - 1) / 2) (1 / 2)) :=
    isProbabilityMeasure_gammaMeasure (by linarith) (by norm_num)
  have e1 : (fun ω => ((n : ℝ) - 1) * sampleVar (fun i => X i ω) / (σ : ℝ) ^ 2) =
      Prod.snd ∘ W := by
    ext ω
    simp only [Function.comp_apply, hWdef, hGf, sampleVar]
    field_simp
  have e2 : (fun ω => sampleMean (fun i => X i ω)) =
      (fun a => μ + σ / √(n : ℝ) * a) ∘ (Prod.fst ∘ W) := by
    ext ω
    simp only [Function.comp_apply, hWdef, hGf]
    field_simp
    ring
  have e3 : (fun ω => sampleVar (fun i => X i ω)) =
      (fun b => (σ : ℝ) ^ 2 / ((n : ℝ) - 1) * b) ∘ (Prod.snd ∘ W) := by
    ext ω
    simp only [Function.comp_apply, hWdef, hGf, sampleVar]
    field_simp
  have e4 : (fun ω => (sampleMean (fun i => X i ω) - μ) /
      (√(sampleVar (fun i => X i ω)) / √(n : ℝ))) =
      (fun p : ℝ × ℝ => p.1 / √(p.2 / ((n : ℝ) - 1))) ∘ W := by
    ext ω
    simp only [Function.comp_apply, hWdef, hGf, sampleVar]
    rw [div_div_eq_mul_div, div_right_comm _ ((σ : ℝ) ^ 2), sqrt_div' _ (sq_nonneg _),
      sqrt_sq (by positivity), div_div_eq_mul_div]
    field_simp
  refine ⟨?_, ?_, ?_⟩
  · rw [e1, ← AEMeasurable.map_map_of_aemeasurable measurable_snd.aemeasurable hWm, hW,
      Measure.map_snd_prod, measure_univ, one_smul]
  · rw [e2, e3]
    apply IndepFun.comp _ (by fun_prop) (by fun_prop)
    rw [indepFun_iff_map_prod_eq_prod_map_map (measurable_fst.comp_aemeasurable hWm)
      (measurable_snd.comp_aemeasurable hWm)]
    rw [show (fun ω => ((Prod.fst ∘ W) ω, (Prod.snd ∘ W) ω)) = W from rfl,
      ← AEMeasurable.map_map_of_aemeasurable measurable_fst.aemeasurable hWm,
      ← AEMeasurable.map_map_of_aemeasurable measurable_snd.aemeasurable hWm, hW,
      Measure.map_fst_prod, Measure.map_snd_prod, measure_univ, measure_univ, one_smul, one_smul]
  · rw [e4, ← AEMeasurable.map_map_of_aemeasurable (by fun_prop) hWm, hW,
      t_law (by linarith)]

/-- **Chi-square: a sum of squares.** If Z₁, …, Z_k (k ≥ 1) are independent standard normals,
then V = Z₁² + ⋯ + Z_k² has the chi-square law with k degrees of freedom: the gamma law with
shape k/2 and rate 1/2, whose density is v^(k/2−1) e^(−v/2) / (2^(k/2) Γ(k/2)) for v > 0.
Its mean is k and its variance is 2k. -/
theorem sum_of_squared_standard_normals_is_chi_square
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (k : ℕ) (hk : 0 < k) (Z : Fin k → Ω → ℝ) (hind : iIndepFun Z P)
    (hlaw : ∀ i, P.map (Z i) = gaussianReal 0 1) :
    P.map (fun ω => ∑ i, Z i ω ^ 2) = gammaMeasure ((k : ℝ) / 2) (1 / 2) ∧
      ∫ ω, (∑ i, Z i ω ^ 2) ∂P = k ∧
      variance (fun ω => ∑ i, Z i ω ^ 2) P = 2 * k := by
  have hm : ∀ i, AEMeasurable (Z i) P := fun i =>
    aemeasurable_of_map_eq (gaussianReal_singleton 0 one_ne_zero) (hlaw i)
  have hvm : AEMeasurable (fun ω i => Z i ω) P := AEMeasurable.of_eval hm
  have hvec : P.map (fun ω i => Z i ω) = Measure.pi (fun _ : Fin k => gaussianReal 0 1) := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map hm).1 hind]
    simp_rw [hlaw]
  have hsm : Measurable (fun x : Fin k → ℝ => ∑ i, x i ^ 2) := by fun_prop
  have hVm : AEMeasurable (fun ω => ∑ i, Z i ω ^ 2) P := hsm.comp_aemeasurable hvm
  have hV : P.map (fun ω => ∑ i, Z i ω ^ 2) = gammaMeasure ((k : ℝ) / 2) (1 / 2) := by
    rw [show (fun ω => ∑ i, Z i ω ^ 2) =
        (fun x : Fin k → ℝ => ∑ i, x i ^ 2) ∘ (fun ω i => Z i ω) from rfl,
      ← AEMeasurable.map_map_of_aemeasurable hsm.aemeasurable hvm, hvec, pi_sumsq_chi k hk]
  refine ⟨hV, ?_, ?_⟩
  · rw [show ∫ ω, (∑ i, Z i ω ^ 2) ∂P = ∫ y, y ∂(P.map (fun ω => ∑ i, Z i ω ^ 2)) from
      (integral_map hVm aestronglyMeasurable_id).symm, hV,
      gamma_mean (by positivity) (by norm_num)]
    field_simp
  · rw [show (fun ω => ∑ i, Z i ω ^ 2) = id ∘ (fun ω => ∑ i, Z i ω ^ 2) from rfl,
      ← variance_map aemeasurable_id hVm, hV, gamma_variance (by positivity) (by norm_num)]
    ring

/-- **F: a ratio of two spreads.** Take two independent normal samples: n₁ ≥ 2 measurements
X₁, …, X_{n₁} from N(μ₁, σ₁²) and n₂ ≥ 2 measurements Y₁, …, Y_{n₂} from N(μ₂, σ₂²), with
σ₁, σ₂ > 0 and all n₁ + n₂ measurements independent. Then the ratio
(S₁²/σ₁²) / (S₂²/σ₂²) of the sample variances, each divided by its true variance, has the
F density with n₁ − 1 and n₂ − 1 degrees of freedom (numerator first). -/
theorem two_normal_samples_variance_ratio_is_F
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (n₁ n₂ : ℕ) (hn₁ : 2 ≤ n₁) (hn₂ : 2 ≤ n₂) (μ₁ μ₂ : ℝ) (σ₁ σ₂ : ℝ≥0)
    (hσ₁ : 0 < σ₁) (hσ₂ : 0 < σ₂)
    (X : Fin n₁ → Ω → ℝ) (Y : Fin n₂ → Ω → ℝ) (hind : iIndepFun (Sum.elim X Y) P)
    (hX : ∀ i, P.map (X i) = gaussianReal μ₁ (σ₁ ^ 2))
    (hY : ∀ j, P.map (Y j) = gaussianReal μ₂ (σ₂ ^ 2)) :
    P.map (fun ω => (sampleVar (fun i => X i ω) / (σ₁ : ℝ) ^ 2) /
        (sampleVar (fun j => Y j ω) / (σ₂ : ℝ) ^ 2)) =
      volume.withDensity (fun x => ENNReal.ofReal (fisherFPDF ((n₁ : ℝ) - 1) ((n₂ : ℝ) - 1) x)) := by
  have hmX : ∀ i, AEMeasurable (X i) P := fun i =>
    aemeasurable_of_map_eq (gaussianReal_singleton μ₁ (pow_ne_zero 2 hσ₁.ne')) (hX i)
  have hmY : ∀ j, AEMeasurable (Y j) P := fun j =>
    aemeasurable_of_map_eq (gaussianReal_singleton μ₂ (pow_ne_zero 2 hσ₂.ne')) (hY j)
  have hm : ∀ k, AEMeasurable (Sum.elim X Y k) P := by
    rintro (i | j)
    · exact hmX i
    · exact hmY j
  set L : Fin n₁ ⊕ Fin n₂ → Measure ℝ :=
    Sum.elim (fun _ => gaussianReal μ₁ (σ₁ ^ 2)) (fun _ => gaussianReal μ₂ (σ₂ ^ 2)) with hL
  have hLs : ∀ i, SigmaFinite (L i) := by
    rintro (i | j) <;> simp only [hL, Sum.elim_inl, Sum.elim_inr] <;> infer_instance
  have hU : P.map (fun ω k => Sum.elim X Y k ω) = Measure.pi L := by
    rw [(iIndepFun_iff_map_fun_eq_pi_map hm).1 hind]
    congr 1; ext1 k
    rcases k with i | j
    · simp [hL, hX]
    · simp [hL, hY]
  have hUm : AEMeasurable (fun ω k => Sum.elim X Y k ω) P := AEMeasurable.of_eval hm
  have hXY : P.map (fun ω => ((fun i => X i ω), (fun j => Y j ω))) =
      (Measure.pi (fun _ : Fin n₁ => gaussianReal μ₁ (σ₁ ^ 2))).prod
        (Measure.pi (fun _ : Fin n₂ => gaussianReal μ₂ (σ₂ ^ 2))) := by
    have := (measurePreserving_sumPiEquivProdPi L).map_eq
    rw [show (fun ω => ((fun i => X i ω), (fun j => Y j ω))) =
        (MeasurableEquiv.sumPiEquivProdPi (fun _ => ℝ)) ∘ (fun ω k => Sum.elim X Y k ω) from rfl,
      ← AEMeasurable.map_map_of_aemeasurable (MeasurableEquiv.measurable _).aemeasurable hUm, hU,
      this]
    rfl
  have hXYm : AEMeasurable (fun ω => ((fun i => X i ω), (fun j => Y j ω))) P :=
    (AEMeasurable.of_eval hmX).prodMk (AEMeasurable.of_eval hmY)
  set h₁ : (Fin n₁ → ℝ) → ℝ := fun x => (∑ i, (x i - sampleMean x) ^ 2) / (σ₁ : ℝ) ^ 2
  set h₂ : (Fin n₂ → ℝ) → ℝ := fun x => (∑ i, (x i - sampleMean x) ^ 2) / (σ₂ : ℝ) ^ 2
  have hh₁ : Measurable h₁ := by fun_prop
  have hh₂ : Measurable h₂ := by fun_prop
  have hF : (fun ω => (sampleVar (fun i => X i ω) / (σ₁ : ℝ) ^ 2) /
        (sampleVar (fun j => Y j ω) / (σ₂ : ℝ) ^ 2)) =
      (fun p : ℝ × ℝ => (p.1 / ((n₁ : ℝ) - 1)) / (p.2 / ((n₂ : ℝ) - 1))) ∘ Prod.map h₁ h₂ ∘
        (fun ω => ((fun i => X i ω), (fun j => Y j ω))) := by
    ext ω
    simp only [Function.comp_apply, Prod.map, h₁, h₂, sampleVar]
    ring
  have h1 : (0 : ℝ) < (n₁ : ℝ) - 1 := by
    have : (2 : ℝ) ≤ n₁ := by exact_mod_cast hn₁
    linarith
  have h2 : (0 : ℝ) < (n₂ : ℝ) - 1 := by
    have : (2 : ℝ) ≤ n₂ := by exact_mod_cast hn₂
    linarith
  rw [hF, ← AEMeasurable.map_map_of_aemeasurable (by fun_prop)
      ((hh₁.prodMap hh₂).comp_aemeasurable hXYm),
    ← AEMeasurable.map_map_of_aemeasurable (hh₁.prodMap hh₂).aemeasurable hXYm, hXY,
    ← Measure.map_prod_map _ _ hh₁ hh₂, pi_gaussian_sumsq_law n₁ hn₁ μ₁ hσ₁,
    pi_gaussian_sumsq_law n₂ hn₂ μ₂ hσ₂, f_law h1 h2]

-- The ten bags from machine one: average 502 grams.
example : sampleMean (![507, 498, 505, 500, 503, 502, 501, 497, 505, 502] : Fin 10 → ℝ) = 502 := by
  norm_num [sampleMean, Fin.sum_univ_succ]

-- Their residuals from 502 add to 0, and the squared residuals add to 90.
example : (507 - 502 : ℤ) + (498 - 502) + (505 - 502) + (500 - 502) + (503 - 502) + (502 - 502) +
    (501 - 502) + (497 - 502) + (505 - 502) + (502 - 502) = 0 := by
  decide

example : (507 - 502 : ℤ) ^ 2 + (498 - 502) ^ 2 + (505 - 502) ^ 2 + (500 - 502) ^ 2 +
    (503 - 502) ^ 2 + (502 - 502) ^ 2 + (501 - 502) ^ 2 + (497 - 502) ^ 2 + (505 - 502) ^ 2 +
    (502 - 502) ^ 2 = 90 := by
  decide

-- Sample variance S² = 90 / 9 = 10.
example : sampleVar (![507, 498, 505, 500, 503, 502, 501, 497, 505, 502] : Fin 10 → ℝ) = 10 := by
  norm_num [sampleVar, sampleMean, Fin.sum_univ_succ]

-- The seven bags from machine two: average 500, squared residuals 24, S² = 24 / 6 = 4.
example : sampleMean (![503, 498, 501, 498, 502, 499, 499] : Fin 7 → ℝ) = 500 := by
  norm_num [sampleMean, Fin.sum_univ_succ]

example : sampleVar (![503, 498, 501, 498, 502, 499, 499] : Fin 7 → ℝ) = 4 := by
  norm_num [sampleVar, sampleMean, Fin.sum_univ_succ]

-- The t ratio: (502 − 500) / (√10 / √10) = 2 on 9 degrees.
example : ((502 : ℝ) - 500) / (√10 / √10) = 2 := by
  have h : (√(10 : ℝ)) ≠ 0 := by positivity
  rw [div_self h]; norm_num

-- Testing σ = 3: V = 9 × 10 / 3² = 10 on 9 degrees.
example : (9 : ℚ) * 10 / 3 ^ 2 = 10 := by norm_num

-- The F ratio 10 / 4 = 2.5 on (9, 6), with c = 9/6 = 1.5.
example : (10 : ℚ) / 4 = 5 / 2 ∧ (9 : ℚ) / 6 = 3 / 2 := by norm_num

-- Nine squares: mean 9, variance 2 × 9 = 18; Var(T) = 9/7 on 9 degrees; E[F] = 6/(6 − 2) = 3/2.
example : 2 * 9 = 18 ∧ (9 : ℚ) / (9 - 2) = 9 / 7 ∧ (6 : ℚ) / (6 - 2) = 3 / 2 := by norm_num

#print axioms normal_sample_statistics_follow_chi_square_and_t
#print axioms sum_of_squared_standard_normals_is_chi_square
#print axioms two_normal_samples_variance_ratio_is_F
