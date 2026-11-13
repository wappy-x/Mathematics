-- t-tests: for independent normal readings the one-sample and pooled t ratios follow Student's t law whatever the unknown spread, and pairing removes the between-patient spread by the identity s_d² = s_b² + s_a² − 2 r s_b s_a.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Distributions.Gamma
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Probability.Distributions.Gaussian.Multivariate
import Mathlib.Probability.Moments.ComplexMGF
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Integral.Pi
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.Complex.Convex

/-! Mathlib has no Student's t law, so it is defined here as the card defines it: a standard
normal divided by the root of an independent chi-square over its degrees of freedom, with the
chi-square law taken as Mathlib's gamma law with shape `k/2` and rate `1/2`.

A sample of size `n` is a function `x : Fin n → ℝ`. The sample statistics follow the card:
average `x̄ = (∑ xᵢ)/n`, spread `s` with `n − 1` in the divisor, correlation `r`. -/

open MeasureTheory ProbabilityTheory
open scoped NNReal

noncomputable section

namespace TTest

/-- The average of a sample. -/
def sampleMean {n : ℕ} (x : Fin n → ℝ) : ℝ := (∑ i, x i) / n

/-- The sample variance `s²`, with `n − 1` in the divisor. -/
def sampleVar {n : ℕ} (x : Fin n → ℝ) : ℝ :=
  (∑ i, (x i - sampleMean x) ^ 2) / ((n : ℝ) - 1)

/-- The sample spread `s`, the root of the sample variance. -/
def sampleSD {n : ℕ} (x : Fin n → ℝ) : ℝ := Real.sqrt (sampleVar x)

/-- The sample covariance of two columns measured on the same `n` patients. -/
def sampleCov {n : ℕ} (x y : Fin n → ℝ) : ℝ :=
  (∑ i, (x i - sampleMean x) * (y i - sampleMean y)) / ((n : ℝ) - 1)

/-- The sample correlation `r` of two columns. -/
def sampleCorr {n : ℕ} (x y : Fin n → ℝ) : ℝ := sampleCov x y / (sampleSD x * sampleSD y)

/-- The one-sample t ratio against the claim `μ₀`: `(x̄ − μ₀) / (s / √n)`. -/
def tStat {n : ℕ} (μ₀ : ℝ) (x : Fin n → ℝ) : ℝ :=
  (sampleMean x - μ₀) / (sampleSD x / Real.sqrt n)

/-- The pooled variance `s_p² = ((n₁ − 1)s₁² + (n₂ − 1)s₂²) / (n₁ + n₂ − 2)`. -/
def pooledVar {n₁ n₂ : ℕ} (x : Fin n₁ → ℝ) (y : Fin n₂ → ℝ) : ℝ :=
  (((n₁ : ℝ) - 1) * sampleVar x + ((n₂ : ℝ) - 1) * sampleVar y) / ((n₁ : ℝ) + n₂ - 2)

/-- The pooled two-sample ratio: `(x̄₁ − x̄₂) / (s_p √(1/n₁ + 1/n₂))`. -/
def pooledT {n₁ n₂ : ℕ} (x : Fin n₁ → ℝ) (y : Fin n₂ → ℝ) : ℝ :=
  (sampleMean x - sampleMean y) /
    (Real.sqrt (pooledVar x y) * Real.sqrt (1 / (n₁ : ℝ) + 1 / n₂))

/-- The chi-square law with `k` degrees of freedom: the gamma law with shape `k/2` and rate `1/2`. -/
def chiSquared (k : ℕ) : Measure ℝ := gammaMeasure ((k : ℝ) / 2) (1 / 2)

/-- Student's t law with `k` degrees of freedom, as the card defines it: the law of a standard
normal `Z` divided by `√(V / k)`, where `V` is chi-square with `k` degrees of freedom and
independent of `Z` (independence is the product measure). -/
def studentT (k : ℕ) : Measure ℝ :=
  ((gaussianReal 0 1).prod (chiSquared k)).map fun p => p.1 / Real.sqrt (p.2 / k)

section Helpers
open Real
open scoped ENNReal


lemma gauss_sq_eq (t : ℝ) :
    (fun x : ℝ => gaussianPDFReal 0 1 x * rexp (t * x ^ 2)) =
      fun x => (√(2 * π))⁻¹ * rexp (-(1/2 - t) * x ^ 2) := by
  ext x
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  rw [mul_assoc, ← Real.exp_add]
  congr 2
  ring
#print axioms gauss_sq_eq

lemma integrable_gauss_sq {t : ℝ} (ht : t < 1/2) :
    Integrable (fun x : ℝ => rexp (t * x ^ 2)) (gaussianReal 0 1) := by
  rw [gaussianReal_of_var_ne_zero _ one_ne_zero,
    integrable_withDensity_iff_integrable_smul' (measurable_gaussianPDF _ _)
      (ae_of_all _ fun _ => gaussianPDF_lt_top)]
  have : (fun x : ℝ => (gaussianPDF 0 1 x).toReal • rexp (t * x ^ 2)) =
      fun x => gaussianPDFReal 0 1 x * rexp (t * x ^ 2) := by
    ext x
    rw [gaussianPDF, ENNReal.toReal_ofReal (gaussianPDFReal_nonneg _ _ _), smul_eq_mul]
  rw [this, gauss_sq_eq]
  exact (integrable_exp_neg_mul_sq (by linarith)).const_mul _
#print axioms integrable_gauss_sq

lemma integral_gauss_sq {t : ℝ} (ht : t < 1/2) :
    ∫ x, rexp (t * x ^ 2) ∂(gaussianReal 0 1) = (√(1 - 2 * t))⁻¹ := by
  rw [integral_gaussianReal_eq_integral_smul one_ne_zero]
  simp_rw [smul_eq_mul]
  rw [gauss_sq_eq, integral_const_mul, integral_gaussian]
  have h1 : 0 < 1/2 - t := by linarith
  rw [← Real.sqrt_inv, ← Real.sqrt_inv, ← Real.sqrt_mul (by positivity)]
  congr 1
  field_simp
#print axioms integral_gauss_sq


lemma gammaPDF_toReal {a r x : ℝ} (ha : 0 < a) (hr : 0 < r) :
    (gammaPDF a r x).toReal = gammaPDFReal a r x :=
  ENNReal.toReal_ofReal (gammaPDFReal_nonneg ha hr x)
#print axioms gammaPDF_toReal

lemma integrable_gammaPDFReal {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    Integrable (gammaPDFReal a r) := by
  refine ⟨(measurable_gammaPDFReal a r).aestronglyMeasurable, ?_⟩
  rw [hasFiniteIntegral_iff_ofReal (ae_of_all _ (gammaPDFReal_nonneg ha hr))]
  have := lintegral_gammaPDF_eq_one ha hr
  simp only [gammaPDF] at this
  rw [this]; exact ENNReal.one_lt_top
#print axioms integrable_gammaPDFReal

lemma integral_gammaPDFReal {a r : ℝ} (ha : 0 < a) (hr : 0 < r) :
    ∫ x, gammaPDFReal a r x = 1 := by
  rw [integral_eq_lintegral_of_nonneg_ae (ae_of_all _ (gammaPDFReal_nonneg ha hr))
    (measurable_gammaPDFReal a r).aestronglyMeasurable]
  have := lintegral_gammaPDF_eq_one ha hr
  simp only [gammaPDF] at this
  rw [this]; simp
#print axioms integral_gammaPDFReal

lemma meas_gammaPDF (a r : ℝ) : Measurable (gammaPDF a r) :=
  (measurable_gammaPDFReal a r).ennreal_ofReal
#print axioms meas_gammaPDF

lemma gamma_tilt {a r t : ℝ} (ha : 0 < a) (hr : 0 < r) (ht : t < r) :
    (fun x => (gammaPDF a r x).toReal • rexp (t * x)) =
      fun x => (r / (r - t)) ^ a * gammaPDFReal a (r - t) x := by
  ext x
  rw [gammaPDF_toReal ha hr, smul_eq_mul]
  have hrt : 0 < r - t := by linarith
  by_cases hx : 0 ≤ x
  · simp only [gammaPDFReal, hx, ↓reduceIte]
    rw [Real.div_rpow hr.le hrt.le]
    have h1 : (r - t) ^ a ≠ 0 := (Real.rpow_pos_of_pos hrt a).ne'
    field_simp
    rw [mul_assoc, ← Real.exp_add]; congr 2; ring
  · simp [gammaPDFReal, hx]
#print axioms gamma_tilt

lemma integrable_gamma_exp {a r t : ℝ} (ha : 0 < a) (hr : 0 < r) (ht : t < r) :
    Integrable (fun x => rexp (t * x)) (gammaMeasure a r) := by
  rw [gammaMeasure, integrable_withDensity_iff_integrable_smul' (meas_gammaPDF a r)
    (ae_of_all _ fun _ => ENNReal.ofReal_lt_top), gamma_tilt ha hr ht]
  exact (integrable_gammaPDFReal ha (by linarith)).const_mul _
#print axioms integrable_gamma_exp

lemma integral_gamma_exp {a r t : ℝ} (ha : 0 < a) (hr : 0 < r) (ht : t < r) :
    ∫ x, rexp (t * x) ∂(gammaMeasure a r) = (r / (r - t)) ^ a := by
  rw [gammaMeasure, integral_withDensity_eq_integral_toReal_smul (meas_gammaPDF a r)
    (ae_of_all _ fun _ => ENNReal.ofReal_lt_top), gamma_tilt ha hr ht, integral_const_mul,
    integral_gammaPDFReal ha (by linarith), mul_one]
#print axioms integral_gamma_exp


lemma exp_sumsq_eq_prod {ι : Type*} [Fintype ι] [DecidableEq ι] (S : Finset ι) (t : ℝ) (w : ι → ℝ) :
    rexp (t * ∑ i ∈ S, w i ^ 2) = ∏ i, (if i ∈ S then rexp (t * w i ^ 2) else 1) := by
  rw [Finset.mul_sum, Real.exp_sum, Finset.prod_ite_mem, Finset.univ_inter]
#print axioms exp_sumsq_eq_prod

lemma pi_sumsq_mgf {ι : Type*} [Fintype ι] [DecidableEq ι] (S : Finset ι) {t : ℝ} (ht : t < 1/2) :
    Integrable (fun w : ι → ℝ => rexp (t * ∑ i ∈ S, w i ^ 2))
        (Measure.pi fun _ => gaussianReal 0 1) ∧
      ∫ w, rexp (t * ∑ i ∈ S, w i ^ 2) ∂(Measure.pi fun _ : ι => gaussianReal 0 1) =
        ((√(1 - 2 * t))⁻¹) ^ S.card := by
  simp_rw [exp_sumsq_eq_prod S t]
  constructor
  · refine Integrable.fintype_prod (f := fun i x => if i ∈ S then rexp (t * x ^ 2) else 1)
      (fun i => ?_)
    by_cases hi : i ∈ S
    · simpa [hi] using integrable_gauss_sq ht
    · simp [hi]
  · rw [integral_fintype_prod_eq_prod (f := fun i x => if i ∈ S then rexp (t * x ^ 2) else 1)]
    have : ∀ i, ∫ x, (if i ∈ S then rexp (t * x ^ 2) else 1) ∂(gaussianReal 0 1) =
        if i ∈ S then (√(1 - 2 * t))⁻¹ else 1 := by
      intro i
      by_cases hi : i ∈ S
      · simp [hi, integral_gauss_sq ht]
      · simp [hi]
    simp_rw [this]
    rw [Finset.prod_ite_mem, Finset.univ_inter, Finset.prod_const]
#print axioms pi_sumsq_mgf

lemma chi_mgf_eq {k : ℕ} {t : ℝ} (ht : t < 1/2) :
    ((√(1 - 2 * t))⁻¹) ^ k = ((1/2) / (1/2 - t)) ^ ((k : ℝ) / 2) := by
  have hu : 0 < 1 - 2 * t := by linarith
  have h1 : (1/2 : ℝ) / (1/2 - t) = (1 - 2 * t)⁻¹ := by
    field_simp
  rw [h1, ← Real.sqrt_inv, Real.sqrt_eq_rpow, ← Real.rpow_mul_natCast (by positivity)]
  congr 1; ring
#print axioms chi_mgf_eq


open Filter Topology in
lemma map_eq_of_mgf_eq {Ω : Type*} [MeasurableSpace Ω] {μ : Measure Ω} [IsProbabilityMeasure μ]
    {X : Ω → ℝ} (hX : Measurable X) {ν : Measure ℝ} [IsProbabilityMeasure ν] {c : ℝ} (hc : 0 < c)
    (hiX : ∀ t < c, Integrable (fun ω => rexp (t * X ω)) μ)
    (hiν : ∀ t < c, Integrable (fun x => rexp (t * x)) ν)
    (heq : ∀ t < c, mgf X μ t = mgf id ν t) : μ.map X = ν := by
  set U : Set ℂ := {z | z.re < c}
  have hUX : U ⊆ {z | z.re ∈ interior (integrableExpSet X μ)} := by
    intro z hz
    have : Set.Iio c ⊆ integrableExpSet X μ := fun t ht => hiX t ht
    have := interior_mono this
    rw [isOpen_Iio.interior_eq] at this
    exact this hz
  have hUν : U ⊆ {z | z.re ∈ interior (integrableExpSet id ν)} := by
    intro z hz
    have : Set.Iio c ⊆ integrableExpSet id ν := fun t ht => hiν t ht
    have := interior_mono this
    rw [isOpen_Iio.interior_eq] at this
    exact this hz
  have hA := (analyticOnNhd_complexMGF (X := X) (μ := μ)).mono hUX
  have hB := (analyticOnNhd_complexMGF (X := id) (μ := ν)).mono hUν
  have hpre : IsPreconnected U := (convex_halfSpace_re_lt c).isPreconnected
  have h0 : (0 : ℂ) ∈ U := by simp [U, hc]
  have h_real : ∃ᶠ (x : ℝ) in 𝓝[≠] 0, complexMGF X μ x = complexMGF id ν x := by
    have : ∀ᶠ (x : ℝ) in 𝓝[≠] 0, x < c :=
      eventually_nhdsWithin_of_eventually_nhds (eventually_lt_nhds hc)
    refine this.frequently.mono fun x hx => ?_
    rw [complexMGF_ofReal, complexMGF_ofReal, heq x hx]
  have hfreq : ∃ᶠ z in 𝓝[≠] (0 : ℂ), complexMGF X μ z = complexMGF id ν z := by
    rw [frequently_iff_seq_forall] at h_real ⊢
    obtain ⟨xs, hx_tendsto, hx_eq⟩ := h_real
    refine ⟨fun n ↦ xs n, ?_, fun n ↦ ?_⟩
    · rw [tendsto_nhdsWithin_iff] at hx_tendsto ⊢
      constructor
      · have := (Complex.continuous_ofReal.tendsto 0).comp hx_tendsto.1
        simpa [Function.comp_def] using this
      · simpa using hx_tendsto.2
    · simp [hx_eq]
  have hEq := hA.eqOn_of_preconnected_of_frequently_eq hB hpre h0 hfreq
  apply Measure.ext_of_charFun
  funext t
  have h1 := complexMGF_mul_I hX.aemeasurable (μ := μ) t
  have h2 := complexMGF_mul_I (aemeasurable_id (μ := ν)) t
  rw [Measure.map_id] at h2
  rw [← h1, ← h2]
  exact hEq (by simp [U, hc])
#print axioms map_eq_of_mgf_eq

lemma map_sumsq_pi {ι : Type*} [Fintype ι] [DecidableEq ι] (S : Finset ι) (hS : S.Nonempty) :
    (Measure.pi fun _ : ι => gaussianReal 0 1).map (fun w => ∑ i ∈ S, w i ^ 2) =
      gammaMeasure ((S.card : ℝ) / 2) (1 / 2) := by
  have ha : 0 < (S.card : ℝ) / 2 := by
    have := hS.card_pos; positivity
  have := isProbabilityMeasure_gammaMeasure ha (by norm_num : (0:ℝ) < 1/2)
  refine map_eq_of_mgf_eq (by fun_prop) (by norm_num : (0:ℝ) < 1/2)
    (fun t ht => (pi_sumsq_mgf S ht).1)
    (fun t ht => integrable_gamma_exp ha (by norm_num) ht) (fun t ht => ?_)
  simp only [mgf, id]
  rw [(pi_sumsq_mgf S ht).2, integral_gamma_exp ha (by norm_num) ht, chi_mgf_eq ht]
#print axioms map_sumsq_pi


lemma map_pair_pi {ι : Type*} [Fintype ι] [DecidableEq ι] (i₀ : ι) (S : Finset ι)
    (h : i₀ ∉ S) (hS : S.Nonempty) :
    (Measure.pi fun _ : ι => gaussianReal 0 1).map (fun w => (w i₀, ∑ i ∈ S, w i ^ 2)) =
      (gaussianReal 0 1).prod (chiSquared S.card) := by
  have hind := iIndepFun_pi (μ := fun _ : ι => gaussianReal 0 1) (X := fun _ => id)
    (fun _ => aemeasurable_id)
  have h2 := hind.indepFun_finset {i₀} S (Finset.disjoint_singleton_left.mpr h)
    (fun _ => measurable_pi_apply _)
  have h3 : IndepFun
      ((fun v : ({i₀} : Finset ι) → ℝ => v ⟨i₀, Finset.mem_singleton_self i₀⟩) ∘
        fun a (i : ({i₀} : Finset ι)) => id (a i))
      ((fun v : S → ℝ => ∑ i : S, v i ^ 2) ∘ fun a (i : S) => id (a i))
      (Measure.pi fun _ : ι => gaussianReal 0 1) :=
    h2.comp (measurable_pi_apply _) (by fun_prop)
  have e1 : ((fun v : ({i₀} : Finset ι) → ℝ => v ⟨i₀, Finset.mem_singleton_self i₀⟩) ∘
      fun a (i : ({i₀} : Finset ι)) => id (a i)) = fun w : ι → ℝ => w i₀ := rfl
  have e2 : ((fun v : S → ℝ => ∑ i : S, v i ^ 2) ∘ fun a (i : S) => id (a i)) =
      fun w : ι → ℝ => ∑ i ∈ S, w i ^ 2 := by
    funext w
    simp only [Function.comp_apply, id]
    exact Finset.sum_coe_sort S (fun i => w i ^ 2)
  rw [e1, e2] at h3
  rw [(indepFun_iff_map_prod_eq_prod_map_map (measurable_pi_apply i₀).aemeasurable
    (Finset.measurable_sum S fun i _ => (measurable_pi_apply i).pow_const 2).aemeasurable).mp h3,
    (measurePreserving_eval _ i₀).map_eq, map_sumsq_pi S hS, chiSquared]
#print axioms map_pair_pi

lemma core_law {ι : Type*} [Fintype ι] [DecidableEq ι] (i₀ : ι) (S : Finset ι)
    (h : i₀ ∉ S) (hS : S.Nonempty) :
    (Measure.pi fun _ : ι => gaussianReal 0 1).map
        (fun w => w i₀ / Real.sqrt ((∑ i ∈ S, w i ^ 2) / S.card)) = studentT S.card := by
  rw [studentT, ← map_pair_pi i₀ S h hS, Measure.map_map (by fun_prop) (by fun_prop)]
  rfl
#print axioms core_law

lemma pi_rot {ι : Type*} [Fintype ι] (b : OrthonormalBasis ι ℝ (EuclideanSpace ℝ ι)) :
    (Measure.pi fun _ : ι => gaussianReal 0 1).map
        (fun z i => inner ℝ (b i) (WithLp.toLp 2 z)) =
      Measure.pi fun _ : ι => gaussianReal 0 1 := by
  have e : (fun (z : ι → ℝ) i => inner ℝ (b i) (WithLp.toLp 2 z)) =
      (WithLp.ofLp ∘ b.repr) ∘ WithLp.toLp 2 := by
    funext z i
    simp [OrthonormalBasis.repr_apply_apply]
  rw [e, ← Measure.map_map (by fun_prop) (by fun_prop), map_pi_eq_stdGaussian,
    ← Measure.map_map (by fun_prop) (by fun_prop)]
  rw [stdGaussian_map b.repr, ← map_pi_eq_stdGaussian, Measure.map_map (by fun_prop) (by fun_prop)]
  rw [show (WithLp.ofLp ∘ WithLp.toLp 2 : (ι → ℝ) → ι → ℝ) = id from rfl, Measure.map_id]
#print axioms pi_rot

lemma core_law_basis {ι : Type*} [Fintype ι] [DecidableEq ι]
    (b : OrthonormalBasis ι ℝ (EuclideanSpace ℝ ι)) (i₀ : ι) (S : Finset ι)
    (h : i₀ ∉ S) (hS : S.Nonempty) :
    (Measure.pi fun _ : ι => gaussianReal 0 1).map
        (fun z => inner ℝ (b i₀) (WithLp.toLp 2 z) /
          Real.sqrt ((∑ i ∈ S, inner ℝ (b i) (WithLp.toLp 2 z) ^ 2) / S.card)) =
      studentT S.card := by
  rw [← core_law i₀ S h hS]
  conv_rhs => rw [← pi_rot b]
  rw [Measure.map_map (by fun_prop) (by fun_prop)]
  rfl
#print axioms core_law_basis

lemma gauss_affine (μ : ℝ) (σ : ℝ≥0) :
    (gaussianReal 0 1).map (fun x => μ + σ * x) = gaussianReal μ (σ ^ 2) := by
  have : (fun x : ℝ => μ + σ * x) = (μ + ·) ∘ ((σ : ℝ) * ·) := rfl
  rw [this, ← Measure.map_map (by fun_prop) (by fun_prop), gaussianReal_map_const_mul,
    gaussianReal_map_const_add]
  congr 1
  · simp
  · ext; simp
#print axioms gauss_affine

lemma pi_affine {ι : Type*} [Fintype ι] (μ : ℝ) (σ : ℝ≥0) :
    (Measure.pi fun _ : ι => gaussianReal 0 1).map (fun z i => μ + σ * z i) =
      Measure.pi fun _ : ι => gaussianReal μ (σ ^ 2) := by
  have := Measure.pi_map_pi (μ := fun _ : ι => gaussianReal 0 1)
    (f := fun _ x => μ + σ * x) (hμ := fun _ => by rw [gauss_affine]; infer_instance)
    (fun _ => by fun_prop)
  rw [this]
  simp_rw [gauss_affine]
#print axioms pi_affine

lemma sampleMean_sub {n : ℕ} (b a : Fin n → ℝ) :
    sampleMean (fun i => b i - a i) = sampleMean b - sampleMean a := by
  simp [sampleMean, Finset.sum_sub_distrib, sub_div]
#print axioms sampleMean_sub

lemma sampleVar_sub {n : ℕ} (b a : Fin n → ℝ) :
    sampleVar (fun i => b i - a i) = sampleVar b + sampleVar a - 2 * sampleCov b a := by
  simp only [sampleVar, sampleCov, sampleMean_sub]
  rw [← add_div, ← mul_div_assoc, ← sub_div]
  congr 1
  rw [Finset.mul_sum, ← Finset.sum_add_distrib, ← Finset.sum_sub_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  ring
#print axioms sampleVar_sub

lemma sampleCov_comm {n : ℕ} (x y : Fin n → ℝ) : sampleCov x y = sampleCov y x := by
  simp only [sampleCov, mul_comm]
#print axioms sampleCov_comm

lemma sampleCov_of_sd_zero {n : ℕ} (x y : Fin n → ℝ) (h : sampleSD x = 0) :
    sampleCov x y = 0 := by
  rcases Nat.lt_or_ge n 2 with hn | hn
  · interval_cases n
    · simp [sampleCov]
    · simp [sampleCov]
  have hn' : (0 : ℝ) < (n : ℝ) - 1 := by
    have : (2 : ℝ) ≤ n := by exact_mod_cast hn
    linarith
  rw [sampleSD, Real.sqrt_eq_zero', sampleVar, div_nonpos_iff] at h
  have hSS : ∑ i, (x i - sampleMean x) ^ 2 = 0 := by
    rcases h with h | h
    · linarith [h.2]
    · exact le_antisymm h.1 (Finset.sum_nonneg fun i _ => sq_nonneg _)
  rw [Finset.sum_eq_zero_iff_of_nonneg (fun i _ => sq_nonneg _)] at hSS
  simp only [sampleCov]
  rw [Finset.sum_eq_zero (fun i hi => by rw [pow_eq_zero_iff two_ne_zero |>.mp (hSS i hi)]; ring),
    zero_div]
#print axioms sampleCov_of_sd_zero

lemma corr_sd_sd {n : ℕ} (b a : Fin n → ℝ) :
    sampleCorr b a * sampleSD b * sampleSD a = sampleCov b a := by
  by_cases h : sampleSD b * sampleSD a = 0
  · rcases mul_eq_zero.mp h with h | h
    · rw [sampleCov_of_sd_zero b a h, h]; ring
    · rw [sampleCov_comm, sampleCov_of_sd_zero a b h, h]; ring
  · rw [sampleCorr, mul_assoc, div_mul_cancel₀ _ h]
#print axioms corr_sd_sd

lemma real_inner_toLp {ι : Type*} [Fintype ι] (f g : ι → ℝ) :
    inner ℝ (WithLp.toLp 2 f) (WithLp.toLp 2 g) = ∑ i, f i * g i := by
  rw [EuclideanSpace.inner_toLp_toLp]
  simp [dotProduct, mul_comm]
#print axioms real_inner_toLp

lemma norm_sq_toLp {ι : Type*} [Fintype ι] (f : ι → ℝ) :
    ‖(WithLp.toLp 2 f : EuclideanSpace ℝ ι)‖ ^ 2 = ∑ i, f i ^ 2 := by
  rw [← real_inner_self_eq_norm_sq, real_inner_toLp]
  simp [sq]
#print axioms norm_sq_toLp

lemma exists_basis_two {ι : Type*} [Fintype ι] [DecidableEq ι] (i₀ i₁ : ι) (h : i₀ ≠ i₁)
    (u v : EuclideanSpace ℝ ι) (hu : ‖u‖ = 1) (hv : ‖v‖ = 1) (huv : inner ℝ u v = 0) :
    ∃ b : OrthonormalBasis ι ℝ (EuclideanSpace ℝ ι), b i₀ = u ∧ b i₁ = v := by
  let f : ι → EuclideanSpace ℝ ι := fun i => if i = i₀ then u else v
  have hf : Orthonormal ℝ (({i₀, i₁} : Set ι).domRestrict f) := by
    rw [orthonormal_iff_ite]
    rintro ⟨i, hi⟩ ⟨j, hj⟩
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hi hj
    change inner ℝ (f i) (f j) = _
    rcases hi with rfl | rfl <;> rcases hj with rfl | rfl <;>
      simp [f, h, h.symm, hu, hv, huv, real_inner_comm]
  obtain ⟨b, hb⟩ := hf.exists_orthonormalBasis_extension_of_card_eq (by simp)
  exact ⟨b, by simpa [f] using hb i₀ (by simp), by simpa [f, h.symm] using hb i₁ (by simp)⟩
#print axioms exists_basis_two

lemma exists_basis_one {ι : Type*} [Fintype ι] [DecidableEq ι] (i₀ : ι)
    (u : EuclideanSpace ℝ ι) (hu : ‖u‖ = 1) :
    ∃ b : OrthonormalBasis ι ℝ (EuclideanSpace ℝ ι), b i₀ = u := by
  let f : ι → EuclideanSpace ℝ ι := fun _ => u
  have hf : Orthonormal ℝ (({i₀} : Set ι).domRestrict f) := by
    rw [orthonormal_iff_ite]
    rintro ⟨i, hi⟩ ⟨j, hj⟩
    simp only [Set.mem_singleton_iff] at hi hj
    change inner ℝ (f i) (f j) = _
    subst hi hj
    simp [f, hu]
  obtain ⟨b, hb⟩ := hf.exists_orthonormalBasis_extension_of_card_eq (by simp)
  exact ⟨b, by simpa [f] using hb i₀ (by simp)⟩
#print axioms exists_basis_one

lemma sampleMean_affine {n : ℕ} (hn : 0 < n) (μ σ : ℝ) (z : Fin n → ℝ) :
    sampleMean (fun i => μ + σ * z i) = μ + σ * sampleMean z := by
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  simp only [sampleMean, Finset.sum_add_distrib, Finset.sum_const, ← Finset.mul_sum,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  field_simp
#print axioms sampleMean_affine

lemma sampleVar_affine {n : ℕ} (hn : 0 < n) (μ σ : ℝ) (z : Fin n → ℝ) :
    sampleVar (fun i => μ + σ * z i) = σ ^ 2 * sampleVar z := by
  simp only [sampleVar, sampleMean_affine hn]
  rw [← mul_div_assoc, Finset.mul_sum]
  congr 1
  refine Finset.sum_congr rfl fun i _ => ?_
  ring
#print axioms sampleVar_affine

lemma sampleSD_affine {n : ℕ} (hn : 0 < n) (μ : ℝ) {σ : ℝ} (hσ : 0 ≤ σ) (z : Fin n → ℝ) :
    sampleSD (fun i => μ + σ * z i) = σ * sampleSD z := by
  rw [sampleSD, sampleVar_affine hn, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hσ, sampleSD]
#print axioms sampleSD_affine

lemma tStat_affine {n : ℕ} (hn : 0 < n) (μ : ℝ) {σ : ℝ} (hσ : 0 < σ) (z : Fin n → ℝ) :
    tStat μ (fun i => μ + σ * z i) = tStat 0 z := by
  simp only [tStat, sampleMean_affine hn, sampleSD_affine hn μ hσ.le]
  rw [add_sub_cancel_left, sub_zero, mul_div_assoc σ (sampleSD z), mul_div_mul_left _ _ hσ.ne']
#print axioms tStat_affine

lemma sumsq_dev {n : ℕ} (hn : 0 < n) (z : Fin n → ℝ) :
    ∑ i, (z i - sampleMean z) ^ 2 = ∑ i, z i ^ 2 - (∑ i, z i) ^ 2 / n := by
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  simp only [sampleMean, sub_sq, Finset.sum_add_distrib, Finset.sum_sub_distrib,
    ← Finset.sum_mul, ← Finset.mul_sum, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
    nsmul_eq_mul]
  field_simp
  ring
#print axioms sumsq_dev

lemma tStat_core {n : ℕ} (hn : 2 ≤ n) (b : OrthonormalBasis (Fin n) ℝ (EuclideanSpace ℝ (Fin n)))
    (i₀ : Fin n) (hb : b i₀ = WithLp.toLp 2 (fun _ => 1 / √(n : ℝ))) (z : Fin n → ℝ) :
    tStat 0 z = inner ℝ (b i₀) (WithLp.toLp 2 z) /
      √((∑ i ∈ Finset.univ.erase i₀, inner ℝ (b i) (WithLp.toLp 2 z) ^ 2) /
        ((Finset.univ.erase i₀).card : ℝ)) := by
  have hn0 : (0 : ℝ) < n := by
    have : (2 : ℝ) ≤ n := by exact_mod_cast hn
    linarith
  have hA : inner ℝ (b i₀) (WithLp.toLp 2 z) = (∑ i, z i) / √(n : ℝ) := by
    rw [hb, real_inner_toLp, ← Finset.mul_sum]
    ring
  have hP : ∑ i, inner ℝ (b i) (WithLp.toLp 2 z) ^ 2 = ∑ i, z i ^ 2 := by
    rw [b.sum_sq_inner_right, norm_sq_toLp]
  have hS : ∑ i ∈ Finset.univ.erase i₀, inner ℝ (b i) (WithLp.toLp 2 z) ^ 2 =
      ∑ i, z i ^ 2 - (∑ i, z i) ^ 2 / n := by
    rw [Finset.sum_erase_eq_sub (Finset.mem_univ _), hP, hA, div_pow,
      Real.sq_sqrt hn0.le]
  have hcard : ((Finset.univ.erase i₀).card : ℝ) = n - 1 := by
    rw [Finset.card_erase_of_mem (Finset.mem_univ _), Finset.card_univ, Fintype.card_fin,
      Nat.cast_sub (by omega)]
    simp
  rw [hA, hS, hcard, ← sumsq_dev (by omega)]
  simp only [tStat, sampleSD, sampleVar, sub_zero, sampleMean]
  set s := √((∑ i, (z i - (∑ i, z i) / n) ^ 2) / ((n : ℝ) - 1))
  by_cases hs : s = 0
  · simp [hs]
  have hsq : √(n : ℝ) ≠ 0 := (Real.sqrt_pos.mpr hn0).ne'
  field_simp
  rw [Real.sq_sqrt hn0.le]
#print axioms tStat_core

lemma measurable_sampleMean {n : ℕ} : Measurable (sampleMean (n := n)) := by
  unfold sampleMean
  fun_prop
#print axioms measurable_sampleMean

lemma measurable_sampleVar {n : ℕ} : Measurable (sampleVar (n := n)) := by
  unfold sampleVar
  have := measurable_sampleMean (n := n)
  fun_prop
#print axioms measurable_sampleVar

lemma measurable_sampleSD {n : ℕ} : Measurable (sampleSD (n := n)) :=
  measurable_sampleVar.sqrt
#print axioms measurable_sampleSD

lemma measurable_tStat {n : ℕ} (μ₀ : ℝ) : Measurable (tStat (n := n) μ₀) :=
  (measurable_sampleMean.sub_const μ₀).div (measurable_sampleSD.div_const _)
#print axioms measurable_tStat

lemma norm_const_unit {n : ℕ} (hn : 0 < n) :
    ‖(WithLp.toLp 2 (fun _ : Fin n => 1 / √(n : ℝ)) : EuclideanSpace ℝ (Fin n))‖ = 1 := by
  have hn0 : (0 : ℝ) < n := by exact_mod_cast hn
  have h2 := norm_sq_toLp (fun _ : Fin n => 1 / √(n : ℝ))
  rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, div_pow,
    Real.sq_sqrt hn0.le, one_pow, mul_one_div_cancel hn0.ne'] at h2
  have h3 := norm_nonneg (WithLp.toLp 2 (fun _ : Fin n => 1 / √(n : ℝ)) : EuclideanSpace ℝ (Fin n))
  nlinarith
#print axioms norm_const_unit

lemma sub_one_mul_sampleVar {n : ℕ} (hn : 1 ≤ n) (x : Fin n → ℝ) :
    ((n : ℝ) - 1) * sampleVar x = ∑ i, (x i - sampleMean x) ^ 2 := by
  rcases Nat.lt_or_ge n 2 with h | h
  · obtain rfl : n = 1 := by omega
    simp [sampleVar, sampleMean]
  · have : (0 : ℝ) < (n : ℝ) - 1 := by
      have : (2 : ℝ) ≤ n := by exact_mod_cast h
      linarith
    rw [sampleVar, mul_div_cancel₀ _ this.ne']
#print axioms sub_one_mul_sampleVar

lemma pooledT_affine {n₁ n₂ : ℕ} (h₁ : 0 < n₁) (h₂ : 0 < n₂) (μ : ℝ) {σ : ℝ} (hσ : 0 < σ)
    (x : Fin n₁ → ℝ) (y : Fin n₂ → ℝ) :
    pooledT (fun i => μ + σ * x i) (fun i => μ + σ * y i) = pooledT x y := by
  have hv : pooledVar (fun i => μ + σ * x i) (fun i => μ + σ * y i) = σ ^ 2 * pooledVar x y := by
    simp only [pooledVar, sampleVar_affine h₁, sampleVar_affine h₂]
    ring
  simp only [pooledT, hv, sampleMean_affine h₁, sampleMean_affine h₂]
  rw [Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hσ.le,
    show μ + σ * sampleMean x - (μ + σ * sampleMean y) = σ * (sampleMean x - sampleMean y) by ring,
    mul_assoc, mul_div_mul_left _ _ hσ.ne']
#print axioms pooledT_affine

lemma norm_const_unit' {ι : Type*} [Fintype ι] (hn : 0 < Fintype.card ι) :
    ‖(WithLp.toLp 2 (fun _ : ι => 1 / √(Fintype.card ι : ℝ)) : EuclideanSpace ℝ ι)‖ = 1 := by
  have hn0 : (0 : ℝ) < Fintype.card ι := by exact_mod_cast hn
  have h2 := norm_sq_toLp (fun _ : ι => 1 / √(Fintype.card ι : ℝ))
  rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul, div_pow,
    Real.sq_sqrt hn0.le, one_pow, mul_one_div_cancel hn0.ne'] at h2
  have h3 := norm_nonneg
    (WithLp.toLp 2 (fun _ : ι => 1 / √(Fintype.card ι : ℝ)) : EuclideanSpace ℝ ι)
  nlinarith
#print axioms norm_const_unit'

/-- The unit contrast vector `c · (1/n₁, …, 1/n₁, −1/n₂, …, −1/n₂)`. -/
def contrastVec (n₁ n₂ : ℕ) : EuclideanSpace ℝ (Fin n₁ ⊕ Fin n₂) :=
  WithLp.toLp 2 (Sum.elim (fun _ => (1 / √(1 / (n₁ : ℝ) + 1 / n₂)) / n₁)
    (fun _ => -((1 / √(1 / (n₁ : ℝ) + 1 / n₂)) / n₂)))

lemma inner_contrastVec {n₁ n₂ : ℕ} (w : Fin n₁ ⊕ Fin n₂ → ℝ) :
    inner ℝ (contrastVec n₁ n₂) (WithLp.toLp 2 w) =
      (1 / √(1 / (n₁ : ℝ) + 1 / n₂)) *
        (sampleMean (fun i => w (Sum.inl i)) - sampleMean (fun i => w (Sum.inr i))) := by
  rw [contrastVec, real_inner_toLp, Fintype.sum_sum_type]
  simp only [Sum.elim_inl, Sum.elim_inr, sampleMean, ← Finset.mul_sum]
  ring
#print axioms inner_contrastVec

lemma norm_contrastVec {n₁ n₂ : ℕ} (h₁ : 0 < n₁) (h₂ : 0 < n₂) :
    ‖contrastVec n₁ n₂‖ = 1 := by
  have a1 : (0 : ℝ) < n₁ := by exact_mod_cast h₁
  have a2 : (0 : ℝ) < n₂ := by exact_mod_cast h₂
  have hh : 0 < 1 / (n₁ : ℝ) + 1 / n₂ := by positivity
  have h2 := norm_sq_toLp (Sum.elim (fun _ : Fin n₁ => (1 / √(1 / (n₁ : ℝ) + 1 / n₂)) / n₁)
    (fun _ : Fin n₂ => -((1 / √(1 / (n₁ : ℝ) + 1 / n₂)) / n₂)))
  rw [Fintype.sum_sum_type] at h2
  simp only [Sum.elim_inl, Sum.elim_inr, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
    nsmul_eq_mul, neg_sq, div_pow, one_pow, Real.sq_sqrt hh.le] at h2
  have h4 : (n₁ : ℝ) * (1 / (1 / (n₁ : ℝ) + 1 / n₂) / n₁ ^ 2) +
      n₂ * (1 / (1 / (n₁ : ℝ) + 1 / n₂) / n₂ ^ 2) = 1 := by
    field_simp
  rw [h4] at h2
  have h3 := norm_nonneg (contrastVec n₁ n₂)
  rw [contrastVec] at h3 ⊢
  nlinarith
#print axioms norm_contrastVec

lemma inner_contrast_const {n₁ n₂ : ℕ} (h₁ : 0 < n₁) (h₂ : 0 < n₂) :
    inner ℝ (contrastVec n₁ n₂)
      (WithLp.toLp 2 (fun _ : Fin n₁ ⊕ Fin n₂ => 1 / √(Fintype.card (Fin n₁ ⊕ Fin n₂) : ℝ))) =
      0 := by
  have a1 : (n₁ : ℝ) ≠ 0 := by exact_mod_cast h₁.ne'
  have a2 : (n₂ : ℝ) ≠ 0 := by exact_mod_cast h₂.ne'
  rw [inner_contrastVec]
  simp only [sampleMean, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  field_simp
  ring
#print axioms inner_contrast_const

lemma pooledT_core {n₁ n₂ : ℕ} (h₁ : 0 < n₁) (h₂ : 0 < n₂) (h : 3 ≤ n₁ + n₂)
    (b : OrthonormalBasis (Fin n₁ ⊕ Fin n₂) ℝ (EuclideanSpace ℝ (Fin n₁ ⊕ Fin n₂)))
    (i₀ i₁ : Fin n₁ ⊕ Fin n₂) (hne : i₀ ≠ i₁) (hb₀ : b i₀ = contrastVec n₁ n₂)
    (hb₁ : b i₁ = WithLp.toLp 2
      (fun _ : Fin n₁ ⊕ Fin n₂ => 1 / √(Fintype.card (Fin n₁ ⊕ Fin n₂) : ℝ)))
    (w : Fin n₁ ⊕ Fin n₂ → ℝ) :
    pooledT (fun i => w (Sum.inl i)) (fun j => w (Sum.inr j)) =
      inner ℝ (b i₀) (WithLp.toLp 2 w) /
        √((∑ i ∈ (Finset.univ.erase i₀).erase i₁, inner ℝ (b i) (WithLp.toLp 2 w) ^ 2) /
          (((Finset.univ.erase i₀).erase i₁).card : ℝ)) := by
  classical
  set x : Fin n₁ → ℝ := fun i => w (Sum.inl i)
  set y : Fin n₂ → ℝ := fun j => w (Sum.inr j)
  have a1 : (0 : ℝ) < n₁ := by exact_mod_cast h₁
  have a2 : (0 : ℝ) < n₂ := by exact_mod_cast h₂
  have hN : (Fintype.card (Fin n₁ ⊕ Fin n₂) : ℝ) = n₁ + n₂ := by simp
  have hhpos : 0 < 1 / (n₁ : ℝ) + 1 / n₂ := by positivity
  have hA : inner ℝ (b i₀) (WithLp.toLp 2 w) =
      (1 / √(1 / (n₁ : ℝ) + 1 / n₂)) * (sampleMean x - sampleMean y) := by
    rw [hb₀, inner_contrastVec]
  have hB : inner ℝ (b i₁) (WithLp.toLp 2 w) =
      ((∑ i, x i) + ∑ j, y j) / √((n₁ : ℝ) + n₂) := by
    rw [hb₁, real_inner_toLp, Fintype.sum_sum_type, hN, ← Finset.mul_sum, ← Finset.mul_sum]
    ring
  have hP : ∑ i, inner ℝ (b i) (WithLp.toLp 2 w) ^ 2 = ∑ i, x i ^ 2 + ∑ j, y j ^ 2 := by
    rw [b.sum_sq_inner_right, norm_sq_toLp, Fintype.sum_sum_type]
  have hS : ∑ i ∈ (Finset.univ.erase i₀).erase i₁, inner ℝ (b i) (WithLp.toLp 2 w) ^ 2 =
      ∑ i, x i ^ 2 + ∑ j, y j ^ 2 - inner ℝ (b i₀) (WithLp.toLp 2 w) ^ 2 -
        inner ℝ (b i₁) (WithLp.toLp 2 w) ^ 2 := by
    rw [Finset.sum_erase_eq_sub (Finset.mem_erase.mpr ⟨hne.symm, Finset.mem_univ _⟩),
      Finset.sum_erase_eq_sub (Finset.mem_univ _), hP]
  have hcard : (((Finset.univ.erase i₀).erase i₁).card : ℝ) = (n₁ : ℝ) + n₂ - 2 := by
    rw [Finset.card_erase_of_mem (Finset.mem_erase.mpr ⟨hne.symm, Finset.mem_univ _⟩),
      Finset.card_erase_of_mem (Finset.mem_univ _), Finset.card_univ]
    simp only [Fintype.card_sum, Fintype.card_fin]
    rw [Nat.cast_sub (by omega), Nat.cast_sub (by omega)]
    push_cast
    ring
  have hpv : pooledVar x y =
      ((∑ i, x i ^ 2 - (∑ i, x i) ^ 2 / n₁) + (∑ j, y j ^ 2 - (∑ j, y j) ^ 2 / n₂)) /
        ((n₁ : ℝ) + n₂ - 2) := by
    rw [pooledVar, sub_one_mul_sampleVar h₁, sub_one_mul_sampleVar h₂, sumsq_dev h₁,
      sumsq_dev h₂]
  have key : ∑ i, x i ^ 2 + ∑ j, y j ^ 2 - inner ℝ (b i₀) (WithLp.toLp 2 w) ^ 2 -
        inner ℝ (b i₁) (WithLp.toLp 2 w) ^ 2 =
      (∑ i, x i ^ 2 - (∑ i, x i) ^ 2 / n₁) + (∑ j, y j ^ 2 - (∑ j, y j) ^ 2 / n₂) := by
    rw [hA, hB, mul_pow, div_pow, div_pow, one_pow, Real.sq_sqrt hhpos.le,
      Real.sq_sqrt (by positivity)]
    simp only [sampleMean]
    field_simp
    ring
  rw [hS, key, hcard, ← hpv, hA]
  simp only [pooledT]
  set s := √(pooledVar x y)
  have ht : √(1 / (n₁ : ℝ) + 1 / n₂) ≠ 0 := (Real.sqrt_pos.mpr hhpos).ne'
  by_cases hs : s = 0
  · simp [hs]
  field_simp
#print axioms pooledT_core

lemma measurable_pooledT {n₁ n₂ : ℕ} :
    Measurable (fun p : (Fin n₁ → ℝ) × (Fin n₂ → ℝ) => pooledT p.1 p.2) := by
  have h1 := measurable_sampleMean (n := n₁)
  have h2 := measurable_sampleMean (n := n₂)
  have v1 := measurable_sampleVar (n := n₁)
  have v2 := measurable_sampleVar (n := n₂)
  unfold pooledT pooledVar
  fun_prop
#print axioms measurable_pooledT
end Helpers

/-- One-sample (and paired) t-test: when `n ≥ 2` readings are independent draws from one
normal law whose mean is the claimed value `μ₀` and whose spread is any `σ > 0`, the ratio
`(x̄ − μ₀) / (s / √n)` follows Student's t law with `n − 1` degrees of freedom, whatever `σ` is.
So the test that rejects when `|T|` passes the t law's cutoff has false-alarm rate exactly `α`. -/
theorem one_sample_t_ratio_follows_t_law (n : ℕ) (hn : 2 ≤ n) (μ₀ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ) :
    (Measure.pi fun _ : Fin n => gaussianReal μ₀ (σ ^ 2)).map (tStat μ₀) = studentT (n - 1) := by
  classical
  have hn0 : 0 < n := by omega
  let i₀ : Fin n := ⟨0, hn0⟩
  obtain ⟨b, hb⟩ := exists_basis_one i₀ _ (norm_const_unit hn0)
  have hcardN : (Finset.univ.erase i₀).card = n - 1 := by
    rw [Finset.card_erase_of_mem (Finset.mem_univ _), Finset.card_univ, Fintype.card_fin]
  have hS : (Finset.univ.erase i₀).Nonempty := by
    rw [← Finset.card_pos, hcardN]; omega
  have key := core_law_basis b i₀ (Finset.univ.erase i₀) (Finset.notMem_erase i₀ _) hS
  rw [← hcardN, ← key, ← pi_affine μ₀ σ, Measure.map_map (measurable_tStat μ₀) (by fun_prop)]
  congr 1
  funext z
  simp only [Function.comp_apply]
  rw [tStat_affine hn0 μ₀ (by exact_mod_cast hσ) z, tStat_core hn b i₀ hb z]

/-- Pooled two-sample t-test: when group 1 is `n₁` independent normal readings and group 2 is
`n₂` more, independent of group 1, all with one common mean `μ` and one common spread `σ > 0`,
the pooled ratio `(x̄₁ − x̄₂) / (s_p √(1/n₁ + 1/n₂))` follows Student's t law with
`n₁ + n₂ − 2` degrees of freedom. -/
theorem pooled_t_ratio_follows_t_law (n₁ n₂ : ℕ) (h₁ : 1 ≤ n₁) (h₂ : 1 ≤ n₂) (h : 3 ≤ n₁ + n₂)
    (μ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ) :
    ((Measure.pi fun _ : Fin n₁ => gaussianReal μ (σ ^ 2)).prod
        (Measure.pi fun _ : Fin n₂ => gaussianReal μ (σ ^ 2))).map
        (fun p => pooledT p.1 p.2) = studentT (n₁ + n₂ - 2) := by
  classical
  have h₁' : 0 < n₁ := by omega
  have h₂' : 0 < n₂ := by omega
  let i₀ : Fin n₁ ⊕ Fin n₂ := Sum.inl ⟨0, h₁'⟩
  let i₁ : Fin n₁ ⊕ Fin n₂ := Sum.inr ⟨0, h₂'⟩
  have hne : i₀ ≠ i₁ := Sum.inl_ne_inr
  obtain ⟨b, hb₀, hb₁⟩ := exists_basis_two i₀ i₁ hne _ _ (norm_contrastVec h₁' h₂')
    (norm_const_unit' (by simp; omega)) (inner_contrast_const h₁' h₂')
  have hcardN : ((Finset.univ.erase i₀).erase i₁).card = n₁ + n₂ - 2 := by
    rw [Finset.card_erase_of_mem (Finset.mem_erase.mpr ⟨hne.symm, Finset.mem_univ _⟩),
      Finset.card_erase_of_mem (Finset.mem_univ _), Finset.card_univ]
    simp only [Fintype.card_sum, Fintype.card_fin]
    omega
  have hS : ((Finset.univ.erase i₀).erase i₁).Nonempty := by
    rw [← Finset.card_pos, hcardN]; omega
  have hi₀ : i₀ ∉ (Finset.univ.erase i₀).erase i₁ := by simp
  have key := core_law_basis b i₀ _ hi₀ hS
  have hmp : (Measure.pi fun _ : Fin n₁ ⊕ Fin n₂ => gaussianReal μ (σ ^ 2)).map
      (MeasurableEquiv.sumPiEquivProdPi (fun _ : Fin n₁ ⊕ Fin n₂ => ℝ)) =
      (Measure.pi fun _ : Fin n₁ => gaussianReal μ (σ ^ 2)).prod
        (Measure.pi fun _ : Fin n₂ => gaussianReal μ (σ ^ 2)) :=
    (measurePreserving_sumPiEquivProdPi _).map_eq
  rw [← hcardN, ← key, ← hmp, ← pi_affine μ σ,
    Measure.map_map measurable_pooledT (MeasurableEquiv.measurable _),
    Measure.map_map (measurable_pooledT.comp (MeasurableEquiv.measurable _)) (by fun_prop)]
  congr 1
  funext z
  change pooledT (fun i => μ + σ * z (Sum.inl i)) (fun j => μ + σ * z (Sum.inr j)) = _
  rw [pooledT_affine h₁' h₂' μ (by exact_mod_cast hσ), pooledT_core h₁' h₂' h b i₀ i₁ hne hb₀ hb₁]

/-- Pairing: for any two columns `b` (before) and `a` (after) on the same patients,
the variance of the drops `b − a` is `s_b² + s_a² − 2 r s_b s_a`. -/
theorem paired_variance_identity (n : ℕ) (b a : Fin n → ℝ) :
    sampleVar (fun i => b i - a i) =
      sampleVar b + sampleVar a - 2 * sampleCorr b a * sampleSD b * sampleSD a := by
  rw [sampleVar_sub, ← corr_sd_sd]
  ring

end TTest

/-! The card's whole-number worked examples: thirty patients, systolic pressure in mmHg.
Patients 1 to 15 are women, 16 to 30 men. -/

def before : List ℤ := [152, 151, 165, 156, 163, 150, 150, 151, 128, 166, 131, 139, 161, 153, 163,
  174, 176, 170, 149, 179, 141, 151, 165, 149, 150, 147, 170, 120, 169, 166]
def after : List ℤ := [145, 149, 151, 159, 181, 137, 155, 145, 119, 156, 123, 123, 144, 160, 157,
  172, 172, 168, 131, 164, 140, 153, 150, 138, 135, 146, 167, 114, 158, 163]
def drops : List ℤ := List.zipWith (· - ·) before after

-- Patient 1 drops 7; patient 5 rises 18.
example : drops[0]! = 7 ∧ drops[4]! = -18 := by decide
-- Thirty patients; the drops add to 180, an average drop of 6.
example : drops.length = 30 ∧ drops.sum = 180 ∧ (180 : ℚ) / 30 = 6 := by
  refine ⟨by decide, by decide, by norm_num⟩
-- Squared distances from 6 add to 1932, so s_d² = 1932 / 29.
example : (drops.map fun d => (d - 6) ^ 2).sum = 1932 := by decide
-- 25 of the 30 points lie below the no-change line; none of the drops is 0.
example : (drops.filter fun d => 0 < d).length = 25 ∧ (drops.filter fun d => d = 0).length = 0 := by
  decide
-- Women's drops add to 75 (average 5), men's to 105 (average 7): a gap of 2.
example : (drops.take 15).sum = 75 ∧ (drops.drop 15).sum = 105 := by decide
-- The pairing identity on these data, scaled by n(n − 1) to stay in whole numbers:
-- S_bb + S_aa − 2 S_ab = 30 · 1932, where S_xy = n ∑ xy − (∑ x)(∑ y).
example :
    (30 * (before.map fun b => b ^ 2).sum - before.sum ^ 2) +
      (30 * (after.map fun a => a ^ 2).sum - after.sum ^ 2) -
      2 * (30 * (List.zipWith (· * ·) before after).sum - before.sum * after.sum) = 30 * 1932 := by
  decide
-- Histogram of the drops in bins of 5 from −20 to 25: 1, 0, 1, 3, 8, 6, 5, 6, 0.
example : ((List.range 9).map fun k =>
      (drops.filter fun d => -20 + 5 * (k : ℤ) ≤ d ∧ d < -15 + 5 * (k : ℤ)).length) =
    [1, 0, 1, 3, 8, 6, 5, 6, 0] := by decide
-- Degrees of freedom: 30 − 1 = 29 paired; 15 + 15 − 2 = 28 pooled.
example : 30 - 1 = 29 ∧ 15 + 15 - 2 = 28 := by decide
-- Sign patterns on thirty drops, and splits into two groups of 15.
example : 2 ^ 30 = 1073741824 ∧ Nat.choose 30 15 = 155117520 := by decide
-- Sign test: patterns with 25 or more drops of one sign out of 30 number 2 · 174437.
example : (Finset.range 6).sum (fun k => Nat.choose 30 k) = 174437 := by decide

open TTest

#print axioms one_sample_t_ratio_follows_t_law
#print axioms pooled_t_ratio_follows_t_law
#print axioms paired_variance_identity
