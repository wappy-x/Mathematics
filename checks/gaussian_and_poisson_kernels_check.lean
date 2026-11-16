-- The Gaussian and Poisson kernels: the bell curve and the Poisson kernel are positive scaled families of area 1 whose smear of a bounded start returns it at every point of continuity, the bell solves the heat equation and the Poisson kernel is harmonic, and the bell's tail beyond a distance falls like e^(-δ²/2s²) while the Poisson kernel's equals (2/π) arctan(y/δ).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Distributions.Cauchy
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.Harmonic.Constructions
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Sqrt

open MeasureTheory Filter Topology Real ProbabilityTheory InnerProductSpace

/-- The Gaussian kernel (the bell) of standard deviation `s`:
`G_s(x) = e^(-x²/(2s²)) / (s √(2π))`, Mathlib's normal density with mean 0 and variance `s²`. -/
noncomputable def gaussKernel (s x : ℝ) : ℝ :=
  gaussianPDFReal 0 ⟨s ^ 2, sq_nonneg s⟩ x

/-- The Poisson kernel of the half-plane at height `y > 0`: `P_y(x) = y / (π (x² + y²))`,
Mathlib's Cauchy density with centre 0 and scale `y`. -/
noncomputable def poissonKernel (y x : ℝ) : ℝ :=
  cauchyPDFReal 0 (Real.toNNReal y) x

lemma gaussVar_ne_zero {ε : ℝ} (hε : 0 < ε) : (⟨ε ^ 2, sq_nonneg ε⟩ : NNReal) ≠ 0 := by
  intro h
  have : (ε ^ 2 : ℝ) = 0 := congrArg Subtype.val h
  exact (pow_pos hε 2).ne' this

#print axioms gaussVar_ne_zero

lemma gaussKernel_eq (s x : ℝ) :
    gaussKernel s x = (√(2 * π * s ^ 2))⁻¹ * exp (-x ^ 2 / (2 * s ^ 2)) := by
  have : gaussKernel s x = (√(2 * π * s ^ 2))⁻¹ * exp (-(x - 0) ^ 2 / (2 * s ^ 2)) := rfl
  rw [this, sub_zero]

#print axioms gaussKernel_eq

lemma gaussKernel_facts {ε : ℝ} (hε : 0 < ε) :
    (∀ q, 0 < gaussKernel ε q) ∧ ∫ q, gaussKernel ε q = 1 ∧
        ∀ q, gaussKernel ε q = gaussKernel 1 (q / ε) / ε := by
  refine ⟨fun q => gaussianPDFReal_pos _ _ _ (gaussVar_ne_zero hε),
    integral_gaussianPDFReal_eq_one _ (gaussVar_ne_zero hε), fun q => ?_⟩
  rw [gaussKernel_eq, gaussKernel_eq, one_pow, mul_one, mul_one]
  rw [show 2 * π * ε ^ 2 = (2 * π) * ε ^ 2 by ring, Real.sqrt_mul (by positivity),
    Real.sqrt_sq hε.le]
  have : 0 < √(2 * π) := Real.sqrt_pos.mpr (by positivity)
  field_simp

#print axioms gaussKernel_facts

lemma poissonKernel_facts {ε : ℝ} (hε : 0 < ε) :
    (∀ q, 0 < poissonKernel ε q) ∧ ∫ q, poissonKernel ε q = 1 ∧
        ∀ q, poissonKernel ε q = poissonKernel 1 (q / ε) / ε := by
  have hne : Real.toNNReal ε ≠ 0 := (Real.toNNReal_pos.mpr hε).ne'
  refine ⟨fun q => cauchyPDF_pos _ hne _, integral_cauchyPDFReal_eq_one _ hne, fun q => ?_⟩
  simp only [poissonKernel, cauchyPDFReal, Real.coe_toNNReal _ hε.le, Real.toNNReal_one,
    NNReal.coe_one, sub_zero]
  field_simp

#print axioms poissonKernel_facts

lemma approx_id_tendsto (K : ℝ → ℝ → ℝ) (hK1 : Integrable (K 1)) (hint : ∫ q, K 1 q = 1)
    (hscale : ∀ ε > 0, ∀ q, K ε q = K 1 (q / ε) / ε)
    (f : ℝ → ℝ) (hf_meas : AEStronglyMeasurable f volume)
    (hf_bdd : ∃ B : ℝ, ∀ t, |f t| ≤ B) (x : ℝ) (hx : ContinuousAt f x) :
    Tendsto (fun s => ∫ q, K s q * f (x - q)) (𝓝[>] 0) (𝓝 (f x)) := by
  obtain ⟨B, hB⟩ := hf_bdd
  have h1 : ∀ s > 0, ∫ q, K s q * f (x - q) = ∫ u, K 1 u * f (x - s * u) := by
    intro s hs
    have hc := Measure.integral_comp_div (fun u => K 1 u * f (x - s * u)) s
    calc ∫ q, K s q * f (x - q) = ∫ q, s⁻¹ * (K 1 (q / s) * f (x - s * (q / s))) := by
          congr 1; ext q
          rw [hscale s hs q, mul_div_cancel₀ q hs.ne']
          ring
      _ = s⁻¹ * (|s| * ∫ u, K 1 u * f (x - s * u)) := by
          rw [integral_const_mul, hc, smul_eq_mul]
      _ = ∫ u, K 1 u * f (x - s * u) := by
          rw [abs_of_pos hs]; field_simp
  have hfx : f x = ∫ u, K 1 u * f x := by rw [integral_mul_const, hint, one_mul]
  rw [hfx]
  refine Tendsto.congr' (eventually_nhdsWithin_of_forall fun s hs => (h1 s hs).symm) ?_
  refine tendsto_integral_filter_of_dominated_convergence (fun u => ‖K 1 u‖ * B) ?_ ?_
    (hK1.norm.mul_const B) ?_
  · filter_upwards [self_mem_nhdsWithin] with s hs
    refine hK1.aestronglyMeasurable.mul ?_
    have h2 := (hf_meas.comp_quasiMeasurePreserving
      (volume.measurePreserving_sub_left x).quasiMeasurePreserving).comp_quasiMeasurePreserving
      (Measure.quasiMeasurePreserving_smul volume (ne_of_gt hs))
    simpa [Function.comp_def, smul_eq_mul] using h2
  · filter_upwards with s
    filter_upwards with u
    rw [norm_mul, Real.norm_eq_abs (f _)]
    exact mul_le_mul_of_nonneg_left (hB _) (norm_nonneg _)
  · filter_upwards with u
    refine tendsto_const_nhds.mul (hx.tendsto.comp ?_)
    have hc : Continuous fun s : ℝ => x - s * u := by fun_prop
    exact (hc.tendsto' 0 x (by simp)).mono_left nhdsWithin_le_nhds

#print axioms approx_id_tendsto

lemma bell_hasDerivAt (A v : ℝ) (hv : 0 < v) (y : ℝ) :
    HasDerivAt (fun x => A * exp (-x ^ 2 / (2 * v))) (A * exp (-y ^ 2 / (2 * v)) * (-y / v)) y := by
  have h0 : HasDerivAt (fun x => -x ^ 2 / (2 * v)) (-y / v) y := by
    have := ((hasDerivAt_pow 2 y).neg).div_const (2 * v)
    refine this.congr_deriv ?_
    field_simp
    ring
  refine (h0.exp.const_mul A).congr_deriv ?_
  ring

#print axioms bell_hasDerivAt

lemma poissonKernel_eq {y : ℝ} (hy : 0 < y) (x : ℝ) :
    poissonKernel y x = π⁻¹ * y * (x ^ 2 + y ^ 2)⁻¹ := by
  simp only [poissonKernel, cauchyPDFReal, Real.coe_toNNReal _ hy.le, sub_zero]

#print axioms poissonKernel_eq

lemma poisson_tail (y δ : ℝ) (hy : 0 < y) (hδ : 0 < δ) :
    ∫ x in {x : ℝ | δ < |x|}, poissonKernel y x = 2 / π * arctan (y / δ) := by
  have hS : MeasurableSet {x : ℝ | δ < |x|} := measurableSet_lt measurable_const continuous_abs.measurable
  have hint : Integrable (poissonKernel y) := integrable_cauchyPDFReal _
  have htot := integral_add_compl hS hint
  have hc : {x : ℝ | δ < |x|}ᶜ = Set.Icc (-δ) δ := by
    ext x; simp [abs_le]
  have hd : ∀ x, HasDerivAt (fun x => π⁻¹ * arctan (x / y)) (poissonKernel y x) x := by
    intro x
    refine (((hasDerivAt_id x).div_const y).arctan.const_mul π⁻¹).congr_deriv ?_
    rw [poissonKernel_eq hy]
    simp only [id]
    field_simp
    ring
  have hIcc : ∫ x in Set.Icc (-δ) δ, poissonKernel y x = 2 / π * arctan (δ / y) := by
    rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le (by linarith),
      intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hd x) hint.intervalIntegrable,
      neg_div, arctan_neg]
    ring
  have hone : ∫ x, poissonKernel y x = 1 := integral_cauchyPDFReal_eq_one _
    (Real.toNNReal_pos.mpr hy).ne'
  rw [hc, hIcc, hone] at htot
  rw [show y / δ = (δ / y)⁻¹ by rw [inv_div], arctan_inv_of_pos (by positivity)]
  have : 2 / π * (π / 2 - arctan (δ / y)) = 1 - 2 / π * arctan (δ / y) := by
    field_simp
  linarith

#print axioms poisson_tail

lemma gauss_tail (s δ : ℝ) (hs : 0 < s) (hδ : 0 < δ) :
    ∫ x in {x : ℝ | δ < |x|}, gaussKernel s x
        < √(2 / π) * (s / δ) * exp (-δ ^ 2 / (2 * s ^ 2)) := by
  set c := (√(2 * π * s ^ 2))⁻¹ with hc
  have hv : 0 < s ^ 2 := by positivity
  have hint : Integrable (gaussKernel s) := integrable_gaussianPDFReal _ _
  have hS : {x : ℝ | δ < |x|} = Set.Ioi δ ∪ Set.Iio (-δ) := by
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_union, Set.mem_Ioi, Set.mem_Iio, lt_abs]
    constructor <;> rintro (h | h) <;> first | (left; linarith) | (right; linarith)
  have hdisj : Disjoint (Set.Ioi δ) (Set.Iio (-δ)) :=
    Set.disjoint_left.mpr fun x h1 h2 => by
      simp only [Set.mem_Ioi, Set.mem_Iio] at h1 h2; linarith
  have hsym : ∫ x in Set.Iio (-δ), gaussKernel s x = ∫ x in Set.Ioi δ, gaussKernel s x := by
    rw [← integral_Iic_eq_integral_Iio, ← integral_comp_neg_Ioi]
    congr 1; ext x
    rw [gaussKernel_eq, gaussKernel_eq, neg_sq]
  rw [hS, setIntegral_union hdisj measurableSet_Iio hint.integrableOn hint.integrableOn, hsym]
  -- the comparison integral
  set F : ℝ → ℝ := fun x => -(s ^ 2 / δ) * (c * exp (-x ^ 2 / (2 * s ^ 2))) with hF
  have hFd : ∀ x, HasDerivAt F (x / δ * gaussKernel s x) x := by
    intro x
    refine ((bell_hasDerivAt c (s ^ 2) hv x).const_mul _).congr_deriv ?_
    rw [gaussKernel_eq, ← hc]
    field_simp
  have hJint : IntegrableOn (fun x => x / δ * gaussKernel s x) (Set.Ioi δ) := by
    have := (integrable_mul_exp_neg_mul_sq (b := 1 / (2 * s ^ 2)) (by positivity)).const_mul (c / δ)
    refine (this.congr (ae_of_all _ fun x => ?_)).integrableOn
    simp only
    rw [gaussKernel_eq, ← hc]
    field_simp
  have hFlim : Tendsto F atTop (𝓝 0) := by
    have h1 : Tendsto (fun x : ℝ => -x ^ 2 / (2 * s ^ 2)) atTop atBot := by
      have := tendsto_neg_atTop_atBot.comp
        ((tendsto_pow_atTop (two_ne_zero)).atTop_div_const (show (0:ℝ) < 2 * s ^ 2 by positivity))
      refine this.congr fun x => ?_
      simp [neg_div]
    have := ((Real.tendsto_exp_atBot.comp h1).const_mul c).const_mul (-(s ^ 2 / δ))
    simpa [F, Function.comp_def] using this
  have hJ : ∫ x in Set.Ioi δ, x / δ * gaussKernel s x = -F δ := by
    rw [integral_Ioi_of_hasDerivAt_of_tendsto' (fun x _ => hFd x) hJint hFlim, zero_sub]
  have hlt : ∫ x in Set.Ioi δ, gaussKernel s x < ∫ x in Set.Ioi δ, x / δ * gaussKernel s x := by
    rw [← sub_pos, ← integral_sub hJint hint.integrableOn]
    have hpos : ∀ x ∈ Set.Ioi δ, 0 < x / δ * gaussKernel s x - gaussKernel s x := by
      intro x hx
      have h1 : 1 < x / δ := (one_lt_div hδ).mpr hx
      have h2 : 0 < gaussKernel s x := by rw [gaussKernel_eq]; positivity
      nlinarith
    rw [setIntegral_pos_iff_support_of_nonneg_ae
      ((ae_restrict_iff' measurableSet_Ioi).mpr (ae_of_all _ fun x hx => (hpos x hx).le))
      (hJint.sub hint.integrableOn)]
    have hsub : Set.Ioi δ ⊆ Function.support
        (fun x => x / δ * gaussKernel s x - gaussKernel s x) ∩ Set.Ioi δ :=
      fun x hx => ⟨(hpos x hx).ne', hx⟩
    exact lt_of_lt_of_le (by simp [Real.volume_Ioi]) (measure_mono hsub)
  rw [hJ] at hlt
  have hkey : √(2 / π) * √(2 * π * s ^ 2) = 2 * s := by
    rw [← Real.sqrt_mul (by positivity),
      show 2 / π * (2 * π * s ^ 2) = (2 * s) ^ 2 by field_simp]
    exact Real.sqrt_sq (by positivity)
  have hsq : 0 < √(2 * π * s ^ 2) := Real.sqrt_pos.mpr (by positivity)
  have heq : √(2 / π) = 2 * s / √(2 * π * s ^ 2) := by
    rw [eq_div_iff hsq.ne', hkey]
  have hval : 2 * -F δ = √(2 / π) * (s / δ) * exp (-δ ^ 2 / (2 * s ^ 2)) := by
    rw [heq, hF, hc]
    field_simp
  linarith

#print axioms gauss_tail

lemma poisson_harmonic :
    HarmonicOnNhd (fun z : ℂ => poissonKernel z.im z.re) {z : ℂ | 0 < z.im} := by
  intro z hz
  have hz0 : z ≠ 0 := by
    intro h; simp [h] at hz
  have hA : HarmonicAt ((-π⁻¹ : ℝ) • fun w : ℂ => (w⁻¹).im) z :=
    ((analyticAt_inv (𝕜 := ℂ) hz0).harmonicAt_im).const_smul
  refine (harmonicAt_congr_nhds ?_).mpr hA
  have hopen : IsOpen {w : ℂ | 0 < w.im} := isOpen_lt continuous_const Complex.continuous_im
  filter_upwards [hopen.mem_nhds hz] with w hw
  simp only [poissonKernel, cauchyPDFReal, Real.coe_toNNReal _ hw.le, Pi.smul_apply,
    Complex.inv_im, smul_eq_mul, Complex.normSq_apply, sub_zero]
  field_simp

#print axioms poisson_harmonic

lemma gaussKernel_sqrt_eq (v : ℝ) (hv : 0 < v) :
    gaussKernel (√v) = fun x => (√(2 * π * v))⁻¹ * exp (-x ^ 2 / (2 * v)) := by
  funext x
  simp [gaussKernel, gaussianPDFReal, Real.sq_sqrt hv.le]
  rfl

#print axioms gaussKernel_sqrt_eq

lemma iteratedDeriv_two_bell (A v : ℝ) (hv : 0 < v) (x : ℝ) :
    iteratedDeriv 2 (fun x => A * exp (-x ^ 2 / (2 * v))) x
      = A * exp (-x ^ 2 / (2 * v)) * (x ^ 2 / v ^ 2 - 1 / v) := by
  have h1 : ∀ y, HasDerivAt (fun x => A * exp (-x ^ 2 / (2 * v)))
      (A * exp (-y ^ 2 / (2 * v)) * (-y / v)) y := by
    intro y
    have h0 : HasDerivAt (fun x => -x ^ 2 / (2 * v)) (-y / v) y := by
      have := ((hasDerivAt_pow 2 y).neg).div_const (2 * v)
      refine this.congr_deriv ?_
      field_simp
      ring
    refine (h0.exp.const_mul A).congr_deriv ?_
    ring
  have hd : deriv (fun x => A * exp (-x ^ 2 / (2 * v)))
      = fun y => A * exp (-y ^ 2 / (2 * v)) * (-y / v) := funext fun y => (h1 y).deriv
  rw [iteratedDeriv_succ, iteratedDeriv_one, hd]
  have h2 : HasDerivAt (fun y => A * exp (-y ^ 2 / (2 * v)) * (-y / v))
      (A * exp (-x ^ 2 / (2 * v)) * (x ^ 2 / v ^ 2 - 1 / v)) x := by
    have := (h1 x).mul ((hasDerivAt_id x).neg.div_const v)
    refine this.congr_deriv ?_
    simp only [Pi.neg_apply, id]
    field_simp
    ring
  exact h2.deriv

#print axioms iteratedDeriv_two_bell

lemma bell_heat (κ : ℝ) (hκ : 0 < κ) : ∀ t > 0, ∀ x : ℝ,
      HasDerivAt (fun τ => gaussKernel (√(2 * κ * τ)) x)
        (κ * iteratedDeriv 2 (gaussKernel (√(2 * κ * t))) x) t := by
  intro t ht x
  have hv : 0 < 2 * κ * t := by positivity
  rw [gaussKernel_sqrt_eq _ hv, iteratedDeriv_two_bell _ _ hv]
  -- the time function near t
  have hev : (fun τ => gaussKernel (√(2 * κ * τ)) x) =ᶠ[𝓝 t]
      fun τ => (√(2 * π * (2 * κ * τ)))⁻¹ * exp (-x ^ 2 / (2 * (2 * κ * τ))) := by
    filter_upwards [lt_mem_nhds ht] with τ hτ
    rw [gaussKernel_sqrt_eq _ (by positivity)]
  refine HasDerivAt.congr_of_eventuallyEq ?_ hev
  set h := √(2 * π * (2 * κ * t)) with hh
  have hpos : 0 < 2 * π * (2 * κ * t) := by positivity
  have hhpos : 0 < h := Real.sqrt_pos.mpr hpos
  have hh2 : h ^ 2 = 2 * π * (2 * κ * t) := Real.sq_sqrt hpos.le
  have hs : HasDerivAt (fun τ => √(2 * π * (2 * κ * τ))) (4 * π * κ / (2 * h)) t := by
    have := (Real.hasDerivAt_sqrt hpos.ne').comp t
      (((hasDerivAt_id t).const_mul (2 * κ)).const_mul (2 * π))
    refine this.congr_deriv ?_
    rw [← hh]; field_simp; ring
  have hsi := hs.inv hhpos.ne'
  have he : HasDerivAt (fun τ => exp (-x ^ 2 / (2 * (2 * κ * τ))))
      (exp (-x ^ 2 / (2 * (2 * κ * t))) * (x ^ 2 / (4 * κ * t ^ 2))) t := by
    have h0 : HasDerivAt (fun τ => -x ^ 2 / (2 * (2 * κ * τ))) (x ^ 2 / (4 * κ * t ^ 2)) t := by
      have e : (fun τ => -x ^ 2 / (2 * (2 * κ * τ))) = fun τ => (-x ^ 2 / (4 * κ)) * τ⁻¹ := by
        funext τ; ring
      rw [e]
      refine ((hasDerivAt_inv ht.ne').const_mul (-x ^ 2 / (4 * κ))).congr_deriv ?_
      field_simp
    exact h0.exp
  have := hsi.mul he
  convert this using 1
  simp only [Pi.inv_apply]
  rw [← hh]
  field_simp
  rw [hh2]
  ring

#print axioms bell_heat

/-- Both kernels are approximate identities. For every width `ε > 0` the bell `G_ε` and the
Poisson kernel `P_ε` are positive, have area exactly 1, and are the width-1 shape stretched to
width `ε`, `K_ε(x) = K_1(x/ε)/ε`. So if the start `f` is bounded and continuous at the point
`x`, the smear `(f * K_ε)(x) = ∫ K_ε(q) f(x − q) dq` tends to `f(x)` as the width shrinks to 0,
for the bell and for the Poisson kernel alike. -/
theorem gaussian_and_poisson_smears_return_the_start
    (f : ℝ → ℝ) (hf_meas : AEStronglyMeasurable f volume)
    (hf_bdd : ∃ B : ℝ, ∀ t, |f t| ≤ B) (x : ℝ) (hx : ContinuousAt f x) :
    (∀ ε > 0, (∀ q, 0 < gaussKernel ε q) ∧ ∫ q, gaussKernel ε q = 1 ∧
        ∀ q, gaussKernel ε q = gaussKernel 1 (q / ε) / ε) ∧
    (∀ ε > 0, (∀ q, 0 < poissonKernel ε q) ∧ ∫ q, poissonKernel ε q = 1 ∧
        ∀ q, poissonKernel ε q = poissonKernel 1 (q / ε) / ε) ∧
    Tendsto (fun s => ∫ q, gaussKernel s q * f (x - q)) (𝓝[>] 0) (𝓝 (f x)) ∧
    Tendsto (fun y => ∫ q, poissonKernel y q * f (x - q)) (𝓝[>] 0) (𝓝 (f x)) := by
  refine ⟨fun ε hε => gaussKernel_facts hε, fun ε hε => poissonKernel_facts hε, ?_, ?_⟩
  · exact approx_id_tendsto gaussKernel (integrable_gaussianPDFReal _ _)
      (gaussKernel_facts one_pos).2.1 (fun ε hε => (gaussKernel_facts hε).2.2) f hf_meas hf_bdd x hx
  · exact approx_id_tendsto poissonKernel (integrable_cauchyPDFReal _)
      (poissonKernel_facts one_pos).2.1 (fun ε hε => (poissonKernel_facts hε).2.2) f hf_meas
      hf_bdd x hx

/-- The tails. The bell's weight farther than `δ` from the centre is less than
`√(2/π) (s/δ) e^(-δ²/(2s²))`, while the Poisson kernel's weight farther than `δ` is exactly
`(2/π) arctan(y/δ)`. -/
theorem gaussian_and_poisson_tails (s y δ : ℝ) (hs : 0 < s) (hy : 0 < y) (hδ : 0 < δ) :
    ∫ x in {x : ℝ | δ < |x|}, gaussKernel s x
        < √(2 / π) * (s / δ) * exp (-δ ^ 2 / (2 * s ^ 2)) ∧
    ∫ x in {x : ℝ | δ < |x|}, poissonKernel y x = 2 / π * arctan (y / δ) := by
  exact ⟨gauss_tail s δ hs hδ, poisson_tail y δ hy hδ⟩

/-- The bell is the heat kernel and the Poisson kernel is harmonic. For diffusivity `κ > 0`,
the bell of standard deviation `√(2κt)` has time-rate equal to `κ` times its curvature in `x`,
`∂_t G = κ ∂²_x G`, at every time `t > 0`; and `P_y(x)`, read as a function of the point
`x + iy`, is harmonic (its two second slopes cancel) on the upper half-plane `y > 0`. -/
theorem bell_solves_heat_equation_and_poisson_is_harmonic (κ : ℝ) (hκ : 0 < κ) :
    (∀ t > 0, ∀ x : ℝ,
      HasDerivAt (fun τ => gaussKernel (√(2 * κ * τ)) x)
        (κ * iteratedDeriv 2 (gaussKernel (√(2 * κ * t))) x) t) ∧
    HarmonicOnNhd (fun z : ℂ => poissonKernel z.im z.re) {z : ℂ | 0 < z.im} := by
  exact ⟨bell_heat κ hκ, poisson_harmonic⟩

-- Bells add by variance: G_3 * G_4 = G_5 because 3² + 4² = 5².
example : (3 : ℝ) ^ 2 + 4 ^ 2 = 5 ^ 2 := by norm_num

-- The Poisson kernel at height 1, 2 cm out: P_1(2) = 1/(5π).
example : poissonKernel 1 2 = 1 / (5 * π) := by
  norm_num [poissonKernel, cauchyPDFReal]

-- Poisson kernels add by height, P_3 * P_4 = P_7, whose centre value is P_7(0) = 1/(7π).
example : poissonKernel 7 0 = 1 / (7 * π) := by
  norm_num [poissonKernel, cauchyPDFReal]
  ring

-- The Poisson kernel's half-width at half-maximum is exactly its height: P_1(1) = P_1(0)/2.
example : poissonKernel 1 1 = poissonKernel 1 0 / 2 := by
  norm_num [poissonKernel, cauchyPDFReal]
  ring

#print axioms gaussian_and_poisson_smears_return_the_start
#print axioms gaussian_and_poisson_tails
#print axioms bell_solves_heat_equation_and_poisson_is_harmonic
