-- Regression error bars: when each day's value is a straight line in a fixed temperature plus independent normal noise of one spread, the fitted slope is unbiased with variance σ²/S_xx, s² = SSE/(n − 2) is unbiased for σ², and the slope's t ratio and both forecast t ratios follow Student's t law on n − 2 degrees of freedom.
import Mathlib.Probability.Distributions.Gaussian.Multivariate
import Mathlib.MeasureTheory.Constructions.HaarToSphere
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Integral.Gamma
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.MeasureTheory.Integral.Pi
import Mathlib.MeasureTheory.Group.Convolution
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt

/-! Notation as on the card. The data are `n` days; day `i` has temperature `x i` and sales
`y i`. A bar is an average; `S_xx` is the spread of the temperatures; the fitted slope is
`∑ (xᵢ − x̄) yᵢ / S_xx`, the fitted intercept is `ȳ − slope · x̄`; `SSE` is the sum of the
squared leftovers; `s² = SSE / (n − 2)`; `SE(slope) = s / √S_xx`; at a new temperature `x₀`,
`h₀ = 1/n + (x₀ − x̄)² / S_xx`. -/

open MeasureTheory ProbabilityTheory Real
open scoped ENNReal NNReal

noncomputable section

namespace RegressionInference

variable {n : ℕ}

/-- The average of `n` readings, `(∑ xᵢ) / n`. -/
def mean (x : Fin n → ℝ) : ℝ := (∑ i, x i) / n

/-- `S_xx = ∑ (xᵢ − x̄)²`: how spread out the temperatures are. -/
def Sxx (x : Fin n → ℝ) : ℝ := ∑ i, (x i - mean x) ^ 2

/-- The least-squares slope, written as weights: `∑ (xᵢ − x̄) yᵢ / S_xx`. -/
def slope (x y : Fin n → ℝ) : ℝ := (∑ i, (x i - mean x) * y i) / Sxx x

/-- The least-squares intercept `ȳ − slope · x̄`. -/
def intercept (x y : Fin n → ℝ) : ℝ := mean y - slope x y * mean x

/-- `SSE`: the sum of the squared leftovers, recorded minus fitted. -/
def SSE (x y : Fin n → ℝ) : ℝ := ∑ i, (y i - intercept x y - slope x y * x i) ^ 2

/-- `s² = SSE / (n − 2)`: the estimated noise variance. -/
def s2 (x y : Fin n → ℝ) : ℝ := SSE x y / ((n : ℝ) - 2)

/-- The slope's standard error `s / √S_xx`. -/
def seSlope (x y : Fin n → ℝ) : ℝ := √(s2 x y) / √(Sxx x)

/-- The distance factor at a new temperature `x₀`: `h₀ = 1/n + (x₀ − x̄)² / S_xx`. -/
def h0 (x : Fin n → ℝ) (x0 : ℝ) : ℝ := 1 / n + (x0 - mean x) ^ 2 / Sxx x

/-- Student's t density with ν degrees of freedom:
`Γ((ν+1)/2) / (√(νπ) Γ(ν/2)) · (1 + t²/ν)^(−(ν+1)/2)`. -/
def studentTPDF (ν t : ℝ) : ℝ :=
  Gamma ((ν + 1) / 2) / (√(ν * π) * Gamma (ν / 2)) * (1 + t ^ 2 / ν) ^ (-(ν + 1) / 2)

/-! ### Helper lemmas -/

lemma lintegral_pi_prod_aux : ∀ (m : ℕ) (μ : Fin m → Measure ℝ) [∀ i, SigmaFinite (μ i)]
    (f : Fin m → ℝ → ℝ≥0∞), (∀ i, Measurable (f i)) →
    ∫⁻ w, ∏ i, f i (w i) ∂(Measure.pi μ) = ∏ i, ∫⁻ x, f i x ∂(μ i)
  | 0, μ, _, f, _ => by simp
  | m + 1, μ, _, f, hf => by
    have h := ((measurePreserving_piFinSuccAbove μ 0).symm
      _).lintegral_comp_emb (MeasurableEquiv.measurableEmbedding _) (fun w => ∏ i, f i (w i))
    rw [← h]
    simp only [MeasurableEquiv.piFinSuccAbove_symm_apply, Fin.prod_univ_succ, Fin.insertNthEquiv_apply,
      Fin.insertNth_zero', Fin.cons_zero, Fin.cons_succ]
    rw [lintegral_prod_mul (g := fun w : Fin m → ℝ => ∏ x, f x.succ (w x)) (hf 0).aemeasurable]
    · simp only [Fin.succAbove_zero]
      rw [lintegral_pi_prod_aux m _ _ (fun i => hf i.succ)]
    exact (Finset.measurable_prod _ fun i _ => (hf i.succ).comp (measurable_pi_apply i)).aemeasurable

/-- `n` independent standard normals have the product of the normal densities as their joint density. -/
lemma gaussPi_eq_withDensity (m : ℕ) :
    Measure.pi (fun _ : Fin m => gaussianReal 0 1) =
      (volume : Measure (Fin m → ℝ)).withDensity (fun w => ∏ i, gaussianPDF 0 1 (w i)) := by
  refine (Measure.pi_eq (μ := fun _ : Fin m => gaussianReal 0 1) fun s hs => ?_)
  rw [withDensity_apply _ (MeasurableSet.univ_pi hs), volume_pi, Measure.restrict_pi_pi,
    lintegral_pi_prod_aux m _ _ (fun _ => measurable_gaussianPDF 0 1)]
  refine Finset.prod_congr rfl fun i _ => ?_
  rw [gaussianReal_apply 0 one_ne_zero]

/-- The Gaussian density of `z` at `t` when `z / √(S/m)` is standard normal. -/
def qd (m S t : ℝ) : ℝ := √S / √(2 * π * m) * exp (-(t ^ 2 * S) / (2 * m))

/-- The product of `m` standard normal densities is `(2π)^(−m/2) · exp(−∑ wᵢ² / 2)`. -/
lemma prod_gaussianPDF (m : ℕ) (w : Fin m → ℝ) :
    ∏ i, gaussianPDF 0 1 (w i) = ENNReal.ofReal ((√(2 * π))⁻¹ ^ m * exp (-(∑ i, w i ^ 2) / 2)) := by
  simp only [gaussianPDF]
  rw [← ENNReal.ofReal_prod_of_nonneg (fun i _ => gaussianPDFReal_nonneg _ _ _)]
  congr 1
  simp only [gaussianPDFReal, NNReal.coe_one, mul_one, sub_zero]
  rw [Finset.prod_mul_distrib, Finset.prod_const, Finset.card_univ, Fintype.card_fin, ← Real.exp_sum]
  congr 2
  rw [← Finset.sum_div, Finset.sum_neg_distrib]

/-- Averaging the scaled normal density over `m` independent standard normals gives the Student t density with `m` degrees of freedom. -/
lemma key_K (m : ℕ) (hm : 0 < m) (t : ℝ) :
    ∫⁻ w, ENNReal.ofReal (qd m (∑ k, w k ^ 2) t) ∂(Measure.pi fun _ : Fin m => gaussianReal 0 1) =
      ENNReal.ofReal (studentTPDF m t) := by
  set C : ℝ := (√(2 * π))⁻¹ ^ m / √(2 * π * m) with hC
  set b : ℝ := 1 / 2 + t ^ 2 / (2 * m) with hb
  have hb0 : 0 < b := by positivity
  set G : ℝ → ℝ := fun y => C * (|y| * exp (-b * y ^ 2)) with hG
  have hGnn : ∀ y, 0 ≤ G y := fun y => by positivity
  rw [gaussPi_eq_withDensity, lintegral_withDensity_eq_lintegral_mul _ (by fun_prop) (by unfold qd; fun_prop)]
  simp only [Pi.mul_apply]
  have h1 : ∀ w : Fin m → ℝ, (∏ i, gaussianPDF 0 1 (w i)) * ENNReal.ofReal (qd m (∑ k, w k ^ 2) t)
      = ENNReal.ofReal (G (√(∑ k, w k ^ 2))) := by
    intro w
    have hS : 0 ≤ ∑ k, w k ^ 2 := Finset.sum_nonneg fun k _ => sq_nonneg _
    rw [prod_gaussianPDF, ← ENNReal.ofReal_mul (by positivity)]
    congr 1
    simp only [hG, qd, hC, hb, abs_of_nonneg (Real.sqrt_nonneg _), Real.sq_sqrt hS]
    have hmpos : (0 : ℝ) < m := by exact_mod_cast hm
    rw [show -(1 / 2 + t ^ 2 / (2 * (m : ℝ))) * ∑ k, w k ^ 2
        = -(∑ k, w k ^ 2) / 2 + -(t ^ 2 * ∑ k, w k ^ 2) / (2 * m) by field_simp; ring, Real.exp_add]
    ring
  simp_rw [h1]
  rw [← (PiLp.volume_preserving_ofLp (Fin m)).lintegral_comp (by fun_prop)]
  simp_rw [← EuclideanSpace.real_norm_sq_eq, Real.sqrt_sq (norm_nonneg _)]
  have hm1 : (-1 : ℝ) < m := by linarith [(Nat.cast_nonneg m : (0:ℝ) ≤ m)]
  have : Nonempty (Fin m) := ⟨⟨0, hm⟩⟩
  have hdim : Module.finrank ℝ (EuclideanSpace ℝ (Fin m)) = m := finrank_euclideanSpace_fin
  have hcongr : Set.EqOn (fun y : ℝ => y ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin m)) - 1) • G y)
      (fun y => C * (y ^ (m : ℝ) * exp (-b * y ^ (2 : ℝ)))) (Set.Ioi 0) := by
    intro y hy
    have hy : 0 < y := hy
    simp only [hdim, hG, smul_eq_mul, abs_of_pos hy, Real.rpow_two, Real.rpow_natCast]
    rw [← pow_sub_one_mul hm.ne' y]
    ring
  have hint : IntegrableOn (fun y : ℝ => y ^ (Module.finrank ℝ (EuclideanSpace ℝ (Fin m)) - 1) • G y)
      (Set.Ioi 0) := by
    refine (IntegrableOn.congr_fun ?_ hcongr.symm measurableSet_Ioi)
    exact (integrableOn_rpow_mul_exp_neg_mul_rpow hm1 two_pos hb0).const_mul C
  rw [← ofReal_integral_eq_lintegral_ofReal ((integrable_fun_norm_addHaar volume).2 hint)
    (ae_of_all _ fun v => hGnn _), integral_fun_norm_addHaar volume G,
    setIntegral_congr_fun measurableSet_Ioi hcongr, integral_const_mul,
    integral_rpow_mul_exp_neg_mul_rpow two_pos hm1 hb0, hdim]
  congr 1
  rw [Measure.real, EuclideanSpace.volume_ball]
  have hmpos : (0 : ℝ) < m := by exact_mod_cast hm
  have hG1 : 0 < Gamma ((m : ℝ) / 2 + 1) := Real.Gamma_pos_of_pos (by positivity)
  simp only [Fintype.card_fin, ENNReal.ofReal_one, one_pow, one_mul, nsmul_eq_mul, smul_eq_mul]
  rw [ENNReal.toReal_ofReal (by positivity), Real.Gamma_add_one (by positivity), studentTPDF]
  have hb' : b = (1 + t ^ 2 / m) / 2 := by rw [hb]; ring
  have hX : 0 ≤ 1 + t ^ 2 / (m : ℝ) := by positivity
  have h2 : (2 : ℝ) ^ (-(-((m : ℝ) + 1) / 2)) = √2 ^ (m + 1) := by
    rw [Real.sqrt_eq_rpow, ← Real.rpow_natCast, ← Real.rpow_mul (by norm_num)]
    congr 1; push_cast; ring
  rw [hb', Real.div_rpow hX (by norm_num), div_eq_mul_inv _ ((2 : ℝ) ^ _), ← Real.rpow_neg (by norm_num), h2, hC]
  have hs2 : 0 < √2 := by positivity
  have hsp : 0 < √π := by positivity
  have hsm : 0 < √(m : ℝ) := by positivity
  rw [show √(2 * π * m) = √2 * √π * √m by rw [Real.sqrt_mul (by positivity), Real.sqrt_mul (by positivity)],
    show √(2 * π) = √2 * √π by rw [Real.sqrt_mul (by positivity)],
    show √(m * π) = √m * √π by rw [Real.sqrt_mul (by positivity)]]
  have hGm : 0 < Gamma ((m : ℝ) / 2) := Real.Gamma_pos_of_pos (by positivity)
  simp only [inv_pow, mul_pow]
  field_simp
  ring

/-- Given `S > 0`, the law of `z / √(S/m)` for a standard normal `z` has density `qd m S`. -/
lemma inner_law (m : ℕ) (hm : 0 < m) (S : ℝ) (hS : 0 < S) (A : Set ℝ) (hA : MeasurableSet A) :
    gaussianReal 0 1 ((fun z => z / √(S / m)) ⁻¹' A) = ∫⁻ t in A, ENNReal.ofReal (qd m S t) := by
  have hmpos : (0 : ℝ) < m := by exact_mod_cast hm
  have hc : 0 < √(S / m) := Real.sqrt_pos.2 (by positivity)
  rw [← Measure.map_apply (by fun_prop) hA, gaussianReal_map_div_const, gaussianReal_apply _ (by
    apply ne_of_gt; apply div_pos one_pos; rw [← NNReal.coe_pos, NNReal.coe_mk]; positivity)]
  refine setLIntegral_congr_fun hA fun t _ => ?_
  simp only [gaussianPDF, gaussianPDFReal, qd]
  congr 1
  simp only [NNReal.coe_div, NNReal.coe_one, NNReal.coe_mk, Real.sq_sqrt (by positivity : 0 ≤ S / m),
    zero_div, sub_zero]
  rw [show 2 * π * (1 / (S / m)) = 2 * π * m / S by field_simp, Real.sqrt_div' _ hS.le,
    show -t ^ 2 / (2 * (1 / (S / m))) = -(t ^ 2 * S) / (2 * m) by field_simp, inv_div]

/-- **Student t law.** If `z` is standard normal and independent of `w₁, …, w_m`, which are independent standard normals, then `z / √((∑ wₖ²)/m)` has the Student t density with `m` degrees of freedom. -/
lemma t_law (m : ℕ) (hm : 0 < m) :
    ((gaussianReal 0 1).prod (Measure.pi fun _ : Fin m => gaussianReal 0 1)).map
      (fun p => p.1 / √((∑ k, p.2 k ^ 2) / m)) =
      volume.withDensity (fun t => ENNReal.ofReal (studentTPDF m t)) := by
  ext A hA
  rw [Measure.map_apply (by fun_prop) hA, withDensity_apply _ hA,
    Measure.prod_apply_symm (measurableSet_preimage (by fun_prop) hA)]
  have hae : ∀ᵐ w ∂(Measure.pi fun _ : Fin m => gaussianReal 0 1), 0 < ∑ k, w k ^ 2 := by
    have h0 : (Measure.pi fun _ : Fin m => gaussianReal 0 1) {w | w ⟨0, hm⟩ = 0} = 0 := by
      have := (measurePreserving_eval (fun _ : Fin m => gaussianReal 0 1) ⟨0, hm⟩).measure_preimage
        (s := {0}) (measurableSet_singleton _).nullMeasurableSet
      rw [show {w : Fin m → ℝ | w ⟨0, hm⟩ = 0} = (Function.eval ⟨0, hm⟩) ⁻¹' {0} from rfl, this]
      have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
      exact measure_singleton 0
    filter_upwards [measure_eq_zero_iff_ae_notMem.1 h0] with w hw
    have hw : w ⟨0, hm⟩ ≠ 0 := hw
    exact lt_of_lt_of_le (by positivity) (Finset.single_le_sum (fun k _ => sq_nonneg (w k))
      (Finset.mem_univ _))
  calc _ = ∫⁻ w, (∫⁻ t in A, ENNReal.ofReal (qd m (∑ k, w k ^ 2) t))
        ∂(Measure.pi fun _ : Fin m => gaussianReal 0 1) := by
        refine lintegral_congr_ae ?_
        filter_upwards [hae] with w hw
        exact inner_law m hm _ hw A hA
    _ = ∫⁻ t in A, (∫⁻ w, ENNReal.ofReal (qd m (∑ k, w k ^ 2) t)
        ∂(Measure.pi fun _ : Fin m => gaussianReal 0 1)) := by
        refine lintegral_lintegral_swap ?_
        unfold qd
        exact Measurable.aemeasurable (by fun_prop)
    _ = _ := by simp_rw [key_K m hm]

/-- A function whose law is a normal law with positive variance is almost everywhere measurable. -/
lemma aemeasurable_of_map_gaussianReal {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] {f : Ω → ℝ} {μ : ℝ} {v : ℝ≥0} (hv : v ≠ 0)
    (h : P.map f = gaussianReal μ v) : AEMeasurable f P := by
  by_contra hf
  have h3 : ∀ x : ℝ, (P.map f) {x} = 0 := by
    rw [h]; intro x
    have := nullSingletonClass_gaussianReal (μ := μ) hv
    exact measure_singleton x
  rw [Measure.map_of_not_aemeasurable_of_ne_zero hf (IsProbabilityMeasure.ne_zero P)] at h3
  have := h3 (@Classical.ofNonempty ℝ _)
  simp at this

/-- Independent normal noises with variance `σ²`, divided by `σ`, are independent standard normals. -/
lemma noise_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (σ : ℝ≥0) (hσ : 0 < σ) (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2)) :
    P.map (fun ω i => ε i ω / σ) = Measure.pi (fun _ => gaussianReal 0 1) := by
  have hσ2 : σ ^ 2 ≠ 0 := by positivity
  have hm : ∀ i, AEMeasurable (ε i) P := fun i => aemeasurable_of_map_gaussianReal hσ2 (hlaw i)
  have h1 := (iIndepFun_iff_map_fun_eq_pi_map hm).1 hind
  have h2 : (fun ω i => ε i ω / σ) = (fun z : Fin n → ℝ => fun i => z i / σ) ∘ (fun ω i => ε i ω) := rfl
  rw [h2, ← AEMeasurable.map_map_of_aemeasurable (Measurable.aemeasurable (by fun_prop))
    (AEMeasurable.of_eval hm), h1, funext hlaw,
    Measure.pi_map_pi (f := fun _ (x : ℝ) => x / (σ : ℝ)) (fun i => by fun_prop)]
  congr 1
  funext i
  rw [gaussianReal_map_div_const]
  congr 1
  · simp
  · ext; simp [hσ.ne']

/-- Rotating `N` independent standard normals into another orthonormal basis gives `N` independent standard normals. -/
lemma rotation_law {N : ℕ} (b : OrthonormalBasis (Fin N) ℝ (EuclideanSpace ℝ (Fin N))) :
    (Measure.pi (fun _ : Fin N => gaussianReal 0 1)).map
      (fun z k => inner ℝ (b k) (WithLp.toLp 2 z)) = Measure.pi (fun _ => gaussianReal 0 1) := by
  have h1 : (fun z : Fin N → ℝ => fun k => inner ℝ (b k) (WithLp.toLp 2 z)) =
      WithLp.ofLp ∘ b.repr ∘ WithLp.toLp 2 := by
    funext z k; simp [OrthonormalBasis.repr_apply_apply]
  have h2 : (stdGaussian (EuclideanSpace ℝ (Fin N))).map WithLp.ofLp =
      Measure.pi (fun _ : Fin N => gaussianReal 0 1) := by
    rw [← map_pi_eq_stdGaussian, Measure.map_map (by fun_prop) (by fun_prop)]
    rw [show (WithLp.ofLp ∘ WithLp.toLp 2 : (Fin N → ℝ) → (Fin N → ℝ)) = id from rfl, Measure.map_id]
  rw [h1, ← Measure.map_map (by fun_prop) (by fun_prop), ← Measure.map_map (by fun_prop) (by fun_prop),
    map_pi_eq_stdGaussian]
  rw [stdGaussian_map b.repr, h2]

/-- Dropping the first of `m + 1` independent standard normals leaves `m` independent standard normals. -/
lemma tail_law (m : ℕ) :
    (Measure.pi (fun _ : Fin (m + 1) => gaussianReal 0 1)).map (fun u k => u (Fin.succ k)) =
      Measure.pi (fun _ : Fin m => gaussianReal 0 1) := by
  have h := (measurePreserving_piFinSuccAbove (fun _ : Fin (m + 1) => gaussianReal 0 1) 0).map_eq
  have h2 : (fun u : Fin (m + 1) → ℝ => fun k => u (Fin.succ k)) =
      Prod.snd ∘ (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (m + 1) => ℝ) 0) := by
    funext u k; simp [MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv, Fin.tail]
  rw [h2, ← Measure.map_map measurable_snd (MeasurableEquiv.measurable _), h, Measure.map_snd_prod]
  simp

/-- The first of `m + 2` independent standard normals is independent of the last `m`. -/
lemma proj_law (m : ℕ) :
    (Measure.pi (fun _ : Fin (m + 2) => gaussianReal 0 1)).map
      (fun u => (u 0, fun k : Fin m => u k.succ.succ)) =
      (gaussianReal 0 1).prod (Measure.pi (fun _ : Fin m => gaussianReal 0 1)) := by
  have h := (measurePreserving_piFinSuccAbove (fun _ : Fin (m + 2) => gaussianReal 0 1) 0).map_eq
  have h2 : (fun u : Fin (m + 2) → ℝ => (u 0, fun k : Fin m => u k.succ.succ)) =
      Prod.map id (fun v : Fin (m + 1) → ℝ => fun k => v k.succ) ∘
        (MeasurableEquiv.piFinSuccAbove (fun _ : Fin (m + 2) => ℝ) 0) := by
    funext u; simp [MeasurableEquiv.piFinSuccAbove_apply, Fin.insertNthEquiv, Fin.tail]
  rw [h2, ← Measure.map_map (by fun_prop) (MeasurableEquiv.measurable _), h,
    ← Measure.map_prod_map _ _ measurable_id (by fun_prop), Measure.map_id]
  rw [tail_law]

/-- If `v` and `a` are independent standard normals, then `(v − α a) / √(1 + α²)` is standard normal. -/
lemma combo_law (α : ℝ) :
    ((gaussianReal 0 1).prod (gaussianReal 0 1)).map (fun p : ℝ × ℝ => (p.1 - α * p.2) / √(1 + α ^ 2)) =
      gaussianReal 0 1 := by
  have h : (fun p : ℝ × ℝ => (p.1 - α * p.2) / √(1 + α ^ 2)) =
      (fun x => x / √(1 + α ^ 2)) ∘ (fun p : ℝ × ℝ => p.1 + p.2) ∘ Prod.map id (fun a => (-α) * a) := by
    funext p; simp [sub_eq_add_neg]
  rw [h, ← Measure.map_map (by fun_prop) (by fun_prop), ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_prod_map _ _ measurable_id (by fun_prop), Measure.map_id, gaussianReal_map_const_mul]
  change (Measure.conv _ _).map _ = _
  rw [gaussianReal_conv_gaussianReal, gaussianReal_map_div_const]
  congr 1
  · simp
  · ext
    simp only [NNReal.coe_div, NNReal.coe_add, NNReal.coe_one, NNReal.coe_mk, mul_one]
    rw [Real.sq_sqrt (by positivity), neg_sq, div_self (by positivity)]

/-- A new independent standard normal mixed with the first rotated coordinate stays independent of the last `m` coordinates. -/
lemma newday_law (m : ℕ) (α : ℝ) :
    ((gaussianReal 0 1).prod (Measure.pi fun _ : Fin (m + 2) => gaussianReal 0 1)).map
      (fun p => ((p.1 - α * p.2 0) / √(1 + α ^ 2), fun k : Fin m => p.2 k.succ.succ)) =
      (gaussianReal 0 1).prod (Measure.pi fun _ : Fin m => gaussianReal 0 1) := by
  have h : (fun p : ℝ × (Fin (m + 2) → ℝ) =>
      ((p.1 - α * p.2 0) / √(1 + α ^ 2), fun k : Fin m => p.2 k.succ.succ)) =
      Prod.map (fun p : ℝ × ℝ => (p.1 - α * p.2) / √(1 + α ^ 2)) id ∘
        (MeasurableEquiv.prodAssoc (α := ℝ) (β := ℝ) (γ := Fin m → ℝ)).symm ∘
        Prod.map id (fun u : Fin (m + 2) → ℝ => (u 0, fun k : Fin m => u k.succ.succ)) := by
    funext p; simp [MeasurableEquiv.prodAssoc]
  rw [h, ← Measure.map_map (by fun_prop) (by fun_prop), ← Measure.map_map (by fun_prop) (by fun_prop),
    ← Measure.map_prod_map _ _ measurable_id (by fun_prop), Measure.map_id, proj_law,
    (measurePreserving_prodAssoc (gaussianReal 0 1) (gaussianReal 0 1)
      (Measure.pi fun _ : Fin m => gaussianReal 0 1)).symm.map_eq,
    ← Measure.map_prod_map _ _ (by fun_prop) measurable_id, Measure.map_id, combo_law]

/-- `(∑ eᵢ) / √n`. -/
def a1 (e : Fin n → ℝ) : ℝ := (∑ i, e i) / √n
/-- `(∑ (xᵢ − x̄) eᵢ) / √S_xx`. -/
def ax (x e : Fin n → ℝ) : ℝ := (∑ i, (x i - mean x) * e i) / √(Sxx x)
/-- The vector `α · 1/√n + β · (x − x̄)/√S_xx`. -/
def comb (x : Fin n → ℝ) (α β : ℝ) : Fin n → ℝ := fun i => α / √n + β * ((x i - mean x) / √(Sxx x))

/-- The deviations from the mean add up to zero. -/
lemma sum_dev (x : Fin n → ℝ) (hn : n ≠ 0) : ∑ i, (x i - mean x) = 0 := by
  rw [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, mean]
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn
  field_simp
  ring

/-- `∑ (xᵢ − x̄) xᵢ = S_xx`. -/
lemma sum_dev_mul (x : Fin n → ℝ) (hn : n ≠ 0) : ∑ i, (x i - mean x) * x i = Sxx x := by
  have : ∀ i, (x i - mean x) * x i = (x i - mean x) ^ 2 + mean x * (x i - mean x) := fun i => by ring
  simp_rw [this, Finset.sum_add_distrib, ← Finset.mul_sum, sum_dev x hn, mul_zero, add_zero, Sxx]

/-- If the temperatures are not all equal, then `S_xx > 0`. -/
lemma Sxx_pos (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j) : 0 < Sxx x := by
  obtain ⟨i, j, hij⟩ := hx
  refine lt_of_le_of_ne (Finset.sum_nonneg fun k _ => sq_nonneg _) fun h => hij ?_
  have h' := (Finset.sum_eq_zero_iff_of_nonneg (fun k _ => sq_nonneg (x k - mean x))).1 h.symm
  have hi := h' i (Finset.mem_univ _)
  have hj := h' j (Finset.mem_univ _)
  have : x i - mean x = 0 := pow_eq_zero_iff (two_ne_zero) |>.1 hi
  have : x j - mean x = 0 := pow_eq_zero_iff (two_ne_zero) |>.1 hj
  linarith

/-- The mean of the model values `β₀ + β₁ xᵢ + eᵢ`. -/
lemma mean_model (x e : Fin n → ℝ) (β₀ β₁ : ℝ) (hn : n ≠ 0) :
    mean (fun i => β₀ + β₁ * x i + e i) = β₀ + β₁ * mean x + mean e := by
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn
  simp only [mean, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
    nsmul_eq_mul, ← Finset.mul_sum]
  field_simp

/-- The fitted slope under the model is the true slope plus a weighted sum of the noise. -/
lemma slope_model (x e : Fin n → ℝ) (β₀ β₁ : ℝ) (hn : n ≠ 0) (hS : Sxx x ≠ 0) :
    slope x (fun i => β₀ + β₁ * x i + e i) = β₁ + (∑ i, (x i - mean x) * e i) / Sxx x := by
  have : ∀ i, (x i - mean x) * (β₀ + β₁ * x i + e i) =
      β₀ * (x i - mean x) + β₁ * ((x i - mean x) * x i) + (x i - mean x) * e i := fun i => by ring
  simp only [slope]
  simp_rw [this, Finset.sum_add_distrib, ← Finset.mul_sum, sum_dev x hn, sum_dev_mul x hn]
  field_simp
  ring

/-- The forecast error at `x₀` under the model. -/
lemma forecast_model (x e : Fin n → ℝ) (β₀ β₁ x0 : ℝ) (hn : n ≠ 0) (hS : Sxx x ≠ 0) :
    intercept x (fun i => β₀ + β₁ * x i + e i) + slope x (fun i => β₀ + β₁ * x i + e i) * x0 -
      (β₀ + β₁ * x0) = mean e + (∑ i, (x i - mean x) * e i) / Sxx x * (x0 - mean x) := by
  rw [intercept, mean_model x e β₀ β₁ hn, slope_model x e β₀ β₁ hn hS]
  ring

/-- The leftover sum of squares under the model, written with the noise only. -/
lemma SSE_model (x e : Fin n → ℝ) (β₀ β₁ : ℝ) (hn : n ≠ 0) (hS : Sxx x ≠ 0) :
    SSE x (fun i => β₀ + β₁ * x i + e i) =
      ∑ i, e i ^ 2 - (∑ i, e i) ^ 2 / n - (∑ i, (x i - mean x) * e i) ^ 2 / Sxx x := by
  set B := (∑ i, (x i - mean x) * e i) / Sxx x with hB
  have hres : ∀ i, (β₀ + β₁ * x i + e i) - intercept x (fun i => β₀ + β₁ * x i + e i) -
      slope x (fun i => β₀ + β₁ * x i + e i) * x i = e i - mean e - B * (x i - mean x) := by
    intro i; rw [intercept, mean_model x e β₀ β₁ hn, slope_model x e β₀ β₁ hn hS]; ring
  have hexp : ∀ i, (e i - mean e - B * (x i - mean x)) ^ 2 = e i ^ 2 + (-2 * mean e) * e i +
      (-2 * B) * ((x i - mean x) * e i) + mean e ^ 2 + (2 * mean e * B) * (x i - mean x) +
      B ^ 2 * (x i - mean x) ^ 2 := fun i => by ring
  simp only [SSE, hres, hexp, Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_const,
    Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, sum_dev x hn]
  rw [show ∑ i, (x i - mean x) ^ 2 = Sxx x from rfl, hB, mean]
  have : (n : ℝ) ≠ 0 := by exact_mod_cast hn
  field_simp
  ring

/-- Inner product of a combination vector with any vector. -/
lemma inner_comb (x : Fin n → ℝ) (α β : ℝ) (e : Fin n → ℝ) :
    inner ℝ (WithLp.toLp 2 (comb x α β)) (WithLp.toLp 2 e) = α * a1 e + β * ax x e := by
  simp only [PiLp.inner_apply, comb, a1, ax, RCLike.inner_apply, conj_trivial]
  simp only [mul_div_assoc', Finset.mul_sum, Finset.sum_div, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => by ring

/-- The `1/√n` coordinate of a combination vector. -/
lemma a1_comb (x : Fin n → ℝ) (α β : ℝ) (hn : n ≠ 0) : a1 (comb x α β) = α := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero hn
  have h : ∀ i, comb x α β i = α / √n + (β / √(Sxx x)) * (x i - mean x) := fun i => by
    simp only [comb]; ring
  simp only [a1, h, Finset.sum_add_distrib, ← Finset.mul_sum, sum_dev x hn, mul_zero, add_zero,
    Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  have : √(n : ℝ) ≠ 0 := (Real.sqrt_pos.2 hn').ne'
  field_simp
  rw [Real.sq_sqrt hn'.le]
  ring

/-- The `(x − x̄)/√S_xx` coordinate of a combination vector. -/
lemma ax_comb (x : Fin n → ℝ) (α β : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) : ax x (comb x α β) = β := by
  have h : ∀ i, (x i - mean x) * comb x α β i =
      (α / √n) * (x i - mean x) + (β / √(Sxx x)) * (x i - mean x) ^ 2 := fun i => by
    simp only [comb]; ring
  simp only [ax, h, Finset.sum_add_distrib, ← Finset.mul_sum, sum_dev x hn, mul_zero, zero_add]
  rw [show ∑ i, (x i - mean x) ^ 2 = Sxx x from rfl]
  have : √(Sxx x) ≠ 0 := (Real.sqrt_pos.2 hS).ne'
  field_simp
  rw [Real.sq_sqrt hS.le]

/-- Inner product of two combination vectors. -/
lemma inner_comb_comb (x : Fin n → ℝ) (α β α' β' : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) :
    inner ℝ (WithLp.toLp 2 (comb x α β)) (WithLp.toLp 2 (comb x α' β')) = α * α' + β * β' := by
  rw [inner_comb, a1_comb x _ _ hn, ax_comb x _ _ hn hS]

/-- Two orthonormal combination vectors extend to an orthonormal basis. -/
lemma exists_basis (m : ℕ) (x : Fin (m + 2) → ℝ) (hS : 0 < Sxx x) (p q : ℝ) (hpq : p ^ 2 + q ^ 2 = 1) :
    ∃ b : OrthonormalBasis (Fin (m + 2)) ℝ (EuclideanSpace ℝ (Fin (m + 2))),
      b 0 = WithLp.toLp 2 (comb x p q) ∧ b 1 = WithLp.toLp 2 (comb x (-q) p) := by
  set v : Fin (m + 2) → EuclideanSpace ℝ (Fin (m + 2)) := fun i =>
    if i = 0 then WithLp.toLp 2 (comb x p q) else WithLp.toLp 2 (comb x (-q) p) with hv
  have hn : m + 2 ≠ 0 := by omega
  have h01 : (1 : Fin (m + 2)) ≠ 0 := by simp
  have hon : Orthonormal ℝ (({0, 1} : Set (Fin (m + 2))).domRestrict v) := by
    rw [orthonormal_iff_ite]
    rintro ⟨i, hi⟩ ⟨j, hj⟩
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hi hj
    simp only [Set.domRestrict_apply, Subtype.mk.injEq, hv]
    rcases hi with rfl | rfl <;> rcases hj with rfl | rfl <;>
      simp only [h01, h01.symm, ite_true, ite_false, inner_comb_comb x _ _ _ _ hn hS] <;>
      linarith
  obtain ⟨b, hb⟩ := Orthonormal.exists_orthonormalBasis_extension_of_card_eq
    (by simp) hon
  refine ⟨b, ?_, ?_⟩
  · rw [hb 0 (by simp)]; simp [hv]
  · rw [hb 1 (by simp)]; simp [hv, h01]

/-- The squared coordinates along the last `m` basis vectors add up to the leftover sum of squares. -/
lemma tail_sq (m : ℕ) (x : Fin (m + 2) → ℝ) (p q : ℝ) (hpq : p ^ 2 + q ^ 2 = 1)
    (b : OrthonormalBasis (Fin (m + 2)) ℝ (EuclideanSpace ℝ (Fin (m + 2))))
    (hb0 : b 0 = WithLp.toLp 2 (comb x p q)) (hb1 : b 1 = WithLp.toLp 2 (comb x (-q) p))
    (z : Fin (m + 2) → ℝ) :
    ∑ k : Fin m, inner ℝ (b k.succ.succ) (WithLp.toLp 2 z) ^ 2 = ∑ i, z i ^ 2 - a1 z ^ 2 - ax x z ^ 2 := by
  have h := b.sum_sq_inner_right (WithLp.toLp 2 z)
  rw [EuclideanSpace.real_norm_sq_eq, Fin.sum_univ_succ, Fin.sum_univ_succ] at h
  simp only [Fin.succ_zero_eq_one, hb0, hb1, inner_comb] at h
  linear_combination h - (a1 z ^ 2 + ax x z ^ 2) * hpq

/-- The slope under the model, with the noise written as `σ · z`. -/
lemma slope_model' (x z : Fin n → ℝ) (β₀ β₁ σ : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) :
    slope x (fun i => β₀ + β₁ * x i + σ * z i) = β₁ + σ * ax x z / √(Sxx x) := by
  rw [slope_model x _ β₀ β₁ hn hS.ne', ax]
  have : √(Sxx x) ≠ 0 := (Real.sqrt_pos.2 hS).ne'
  simp_rw [show ∀ i, (x i - mean x) * (σ * z i) = σ * ((x i - mean x) * z i) from fun i => by ring,
    ← Finset.mul_sum]
  field_simp
  rw [Real.sq_sqrt hS.le]
  ring

/-- The forecast error under the model, with the noise written as `σ · z`. -/
lemma forecast_model' (x z : Fin n → ℝ) (β₀ β₁ σ x0 : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) :
    intercept x (fun i => β₀ + β₁ * x i + σ * z i) + slope x (fun i => β₀ + β₁ * x i + σ * z i) * x0 -
      (β₀ + β₁ * x0) = σ * (a1 z / √n + (x0 - mean x) / √(Sxx x) * ax x z) := by
  have : √(Sxx x) ≠ 0 := (Real.sqrt_pos.2 hS).ne'
  have hn' : (0 : ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero hn
  have : √(n : ℝ) ≠ 0 := (Real.sqrt_pos.2 hn').ne'
  have hmean : mean (fun i => σ * z i) = σ * a1 z / √n := by
    simp only [mean, a1, ← Finset.mul_sum]
    field_simp
    rw [Real.sq_sqrt hn'.le]
  rw [forecast_model x _ β₀ β₁ x0 hn hS.ne', hmean, ax]
  simp_rw [show ∀ i, (x i - mean x) * (σ * z i) = σ * ((x i - mean x) * z i) from fun i => by ring,
    ← Finset.mul_sum]
  field_simp
  rw [Real.sq_sqrt hS.le]
  ring

/-- `SSE` under the model, with the noise written as `σ · z`. -/
lemma SSE_model' (x z : Fin n → ℝ) (β₀ β₁ σ : ℝ) (hn : n ≠ 0) (hS : 0 < Sxx x) :
    SSE x (fun i => β₀ + β₁ * x i + σ * z i) = σ ^ 2 * (∑ i, z i ^ 2 - a1 z ^ 2 - ax x z ^ 2) := by
  rw [SSE_model x _ β₀ β₁ hn hS.ne', ax, a1]
  have : √(Sxx x) ≠ 0 := (Real.sqrt_pos.2 hS).ne'
  have hn' : (0 : ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero hn
  have : √(n : ℝ) ≠ 0 := (Real.sqrt_pos.2 hn').ne'
  simp_rw [show ∀ i, (x i - mean x) * (σ * z i) = σ * ((x i - mean x) * z i) from fun i => by ring,
    ← Finset.mul_sum, mul_pow σ, ← Finset.mul_sum, div_pow, Real.sq_sqrt hS.le, Real.sq_sqrt hn'.le]
  field_simp

/-- Cancelling `σ` and `K` in the slope ratio. -/
lemma ratio_aux (σ A Q m K : ℝ) (hσ : 0 < σ) (hK : 0 < K) :
    (σ * A / K) / (√(σ ^ 2 * Q / m) / K) = A / √(Q / m) := by
  rw [show σ ^ 2 * Q / m = σ ^ 2 * (Q / m) by ring, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hσ.le,
    div_div_div_cancel_right₀ hK.ne', mul_div_mul_left _ _ hσ.ne']

/-- Cancelling `σ` and `K` in the mean-forecast ratio. -/
lemma ratio_aux' (σ A Q m K : ℝ) (hσ : 0 < σ) (hK : 0 < K) :
    (σ * (K * A)) / (√(σ ^ 2 * Q / m) * K) = A / √(Q / m) := by
  rw [show σ ^ 2 * Q / m = σ ^ 2 * (Q / m) by ring, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hσ.le,
    show σ * (K * A) = (σ * K) * A by ring, show σ * √(Q / m) * K = (σ * K) * √(Q / m) by ring,
    mul_div_mul_left _ _ (mul_pos hσ hK).ne']

/-- The noise, scaled to unit variance and rotated into an orthonormal basis, is again a vector
of independent standard normals. -/
lemma rotated_noise_law {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    {N : ℕ} (σ : ℝ≥0) (hσ : 0 < σ) (ε : Fin N → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2))
    (b : OrthonormalBasis (Fin N) ℝ (EuclideanSpace ℝ (Fin N))) :
    AEMeasurable (fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ)))) P ∧
    P.map (fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ)))) =
      Measure.pi (fun _ => gaussianReal 0 1) := by
  have hmeas : ∀ i, AEMeasurable (ε i) P := fun i =>
    aemeasurable_of_map_gaussianReal (by positivity) (hlaw i)
  have hZ : AEMeasurable (fun ω i => ε i ω / (σ : ℝ)) P :=
    AEMeasurable.of_eval fun i => (hmeas i).div_const _
  have hR : Measurable (fun (z : Fin N → ℝ) (k : Fin N) => inner ℝ (b k) (WithLp.toLp 2 z)) := by
    fun_prop
  refine ⟨hR.comp_aemeasurable hZ, ?_⟩
  rw [show (fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ)))) =
    (fun (z : Fin N → ℝ) (k : Fin N) => inner ℝ (b k) (WithLp.toLp 2 z)) ∘
      (fun ω i => ε i ω / (σ : ℝ)) from rfl,
    ← AEMeasurable.map_map_of_aemeasurable hR.aemeasurable hZ, noise_law σ hσ ε hind hlaw,
    rotation_law]

/-- Cancelling `σ` in the new-day ratio. -/
lemma ratio_aux'' (σ B Q m K : ℝ) (hσ : 0 < σ) :
    (σ * B) / (√(σ ^ 2 * Q / m) * K) = (B / K) / √(Q / m) := by
  rw [show σ ^ 2 * Q / m = σ ^ 2 * (Q / m) by ring, Real.sqrt_mul (sq_nonneg _), Real.sqrt_sq hσ.le,
    show σ * √(Q / m) * K = σ * (√(Q / m) * K) by ring, mul_div_mul_left _ _ hσ.ne', div_div,
    mul_comm K]

#print axioms lintegral_pi_prod_aux
#print axioms gaussPi_eq_withDensity
#print axioms prod_gaussianPDF
#print axioms key_K
#print axioms inner_law
#print axioms t_law
#print axioms aemeasurable_of_map_gaussianReal
#print axioms noise_law
#print axioms rotation_law
#print axioms tail_law
#print axioms proj_law
#print axioms combo_law
#print axioms newday_law
#print axioms sum_dev
#print axioms sum_dev_mul
#print axioms Sxx_pos
#print axioms mean_model
#print axioms slope_model
#print axioms forecast_model
#print axioms SSE_model
#print axioms inner_comb
#print axioms a1_comb
#print axioms ax_comb
#print axioms inner_comb_comb
#print axioms exists_basis
#print axioms tail_sq
#print axioms slope_model'
#print axioms forecast_model'
#print axioms SSE_model'
#print axioms ratio_aux
#print axioms ratio_aux'
#print axioms rotated_noise_law
#print axioms ratio_aux''

/-- **The slope's t ratio follows Student's t law on n − 2 degrees of freedom.** Take `n ≥ 3`
days at fixed temperatures `x₁, …, xₙ`, not all equal. Suppose each day's sales are the true line
plus noise, `Yᵢ = β₀ + β₁ xᵢ + εᵢ`, where the noises `ε₁, …, εₙ` are independent and each is
normal with mean 0 and the same variance `σ² > 0`. Then the fitted slope's distance from the
true slope, counted in standard errors, `(β̂₁ − β₁) / SE(β̂₁)` with `SE(β̂₁) = s / √S_xx` and
`s² = SSE / (n − 2)`, has Student's t density with `n − 2` degrees of freedom. This is the fact
behind the test of "slope zero" and the interval `β̂₁ ± t_* SE(β̂₁)`. -/
theorem slope_t_ratio_has_student_t_law
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (hn : 3 ≤ n) (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j)
    (β₀ β₁ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2)) :
    P.map (fun ω => (slope x (fun i => β₀ + β₁ * x i + ε i ω) - β₁) /
        seSlope x (fun i => β₀ + β₁ * x i + ε i ω)) =
      volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ((n : ℝ) - 2) t)) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  have hm : 0 < m := by omega
  have hn0 : m + 2 ≠ 0 := by omega
  have hS := Sxx_pos x hx
  have hσ' : (0 : ℝ) < σ := hσ
  obtain ⟨b, hb0, hb1⟩ := exists_basis m x hS 0 1 (by norm_num)
  obtain ⟨hUm, hU⟩ := rotated_noise_law σ hσ ε hind hlaw b
  have hcast : ((m + 2 : ℕ) : ℝ) - 2 = m := by push_cast; ring
  rw [hcast, ← t_law m hm, ← proj_law m, Measure.map_map (by fun_prop) (by fun_prop), ← hU,
    AEMeasurable.map_map_of_aemeasurable (by fun_prop) hUm]
  congr 1
  funext ω
  have hε : (fun i => β₀ + β₁ * x i + ε i ω) =
      fun i => β₀ + β₁ * x i + (σ : ℝ) * (ε i ω / σ) := by
    funext i; field_simp
  simp only [Function.comp_apply, hε, seSlope, s2, hcast, slope_model' x _ β₀ β₁ _ hn0 hS,
    SSE_model' x _ β₀ β₁ _ hn0 hS, tail_sq m x 0 1 (by norm_num) b hb0 hb1, hb0, inner_comb,
    zero_mul, zero_add, one_mul, add_sub_cancel_left]
  exact ratio_aux _ _ _ _ _ hσ' (Real.sqrt_pos.2 hS)

/-- **The slope's spread, and the noise estimate (Steps 1 to 3).** Under the same model, the
fitted slope is right on average, `E[β̂₁] = β₁`; its variance is `σ² / S_xx`; and the estimated
noise variance `s² = SSE / (n − 2)` is right on average, `E[s²] = σ²`. -/
theorem slope_unbiased_variance_and_s2_unbiased
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (hn : 3 ≤ n) (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j)
    (β₀ β₁ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2)) :
    ∫ ω, slope x (fun i => β₀ + β₁ * x i + ε i ω) ∂P = β₁ ∧
      variance (fun ω => slope x (fun i => β₀ + β₁ * x i + ε i ω)) P = (σ : ℝ) ^ 2 / Sxx x ∧
      ∫ ω, s2 x (fun i => β₀ + β₁ * x i + ε i ω) ∂P = (σ : ℝ) ^ 2 := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  have hm : 0 < m := by omega
  have hn0 : m + 2 ≠ 0 := by omega
  have hS := Sxx_pos x hx
  have hσ' : (0 : ℝ) < σ := hσ
  obtain ⟨b, hb0, hb1⟩ := exists_basis m x hS 0 1 (by norm_num)
  obtain ⟨hUm, hU⟩ := rotated_noise_law σ hσ ε hind hlaw b
  set U := fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ))) with hUdef
  have hcast : ((m + 2 : ℕ) : ℝ) - 2 = m := by push_cast; ring
  have hε : ∀ ω, (fun i => β₀ + β₁ * x i + ε i ω) =
      fun i => β₀ + β₁ * x i + (σ : ℝ) * (ε i ω / σ) := fun ω => by
    funext i; field_simp
  have hslope : (fun ω => slope x (fun i => β₀ + β₁ * x i + ε i ω)) =
      (fun u : Fin (m + 2) → ℝ => β₁ + σ / √(Sxx x) * u 0) ∘ U := by
    funext ω
    simp only [Function.comp_apply, hε, slope_model' x _ β₀ β₁ _ hn0 hS, hUdef, hb0, inner_comb,
      zero_mul, zero_add, one_mul]
    ring
  have hs2 : (fun ω => s2 x (fun i => β₀ + β₁ * x i + ε i ω)) =
      (fun u : Fin (m + 2) → ℝ => (σ : ℝ) ^ 2 / m * ∑ k : Fin m, u k.succ.succ ^ 2) ∘ U := by
    funext ω
    simp only [Function.comp_apply, hε, s2, SSE_model' x _ β₀ β₁ _ hn0 hS, hcast,
      ← tail_sq m x 0 1 (by norm_num) b hb0 hb1, hUdef]
    ring
  have hsq : ∀ j : Fin (m + 2), ∫ u, u j ^ 2 ∂(Measure.pi fun _ : Fin (m + 2) => gaussianReal 0 1) = 1 := by
    intro j
    rw [integral_comp_eval (X := fun _ : Fin (m + 2) => ℝ) (μ := fun _ => gaussianReal 0 1) (i := j)
        (f := fun x : ℝ => x ^ 2) (by fun_prop)]
    have h1 : Var[id; gaussianReal 0 1] = ∫ x, x ^ 2 ∂gaussianReal 0 1 :=
      variance_of_integral_eq_zero aemeasurable_id (by simp)
    rw [← h1, variance_id_gaussianReal]
    simp
  have hint : ∀ g : (Fin (m + 2) → ℝ) → ℝ, Measurable g →
      ∫ ω, (g ∘ U) ω ∂P = ∫ u, g u ∂(Measure.pi fun _ : Fin (m + 2) => gaussianReal 0 1) :=
    fun g hg => by rw [← hU, integral_map hUm hg.aestronglyMeasurable]; rfl
  have hv0 : Var[fun u : Fin (m + 2) → ℝ => u 0; Measure.pi fun _ => gaussianReal 0 1] = 1 := by
    rw [show (fun u : Fin (m + 2) → ℝ => u 0) = fun u => id (Function.eval 0 u) from rfl,
      (measurePreserving_eval (fun _ : Fin (m + 2) => gaussianReal 0 1) 0).variance_fun_comp
        aemeasurable_id, variance_id_gaussianReal]
    simp
  refine ⟨?_, ?_, ?_⟩
  · rw [hslope, hint _ (by fun_prop),
      integral_add (integrable_const _) ((integrable_eval IsGaussian.integrable_id).const_mul _),
      integral_const_mul, integral_eval, integral_id_gaussianReal]
    simp
  · rw [hslope, ← variance_map (Measurable.aemeasurable (by fun_prop)) hUm, hU,
      variance_const_add (Measurable.aestronglyMeasurable (by fun_prop)),
      variance_const_mul, hv0, div_pow, Real.sq_sqrt hS.le, mul_one]
  · rw [hs2, hint _ (by fun_prop), integral_const_mul,
      integral_finsetSum _ (fun k _ => ?_)]
    · simp only [hsq, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, mul_one]
      have : (m : ℝ) ≠ 0 := by exact_mod_cast hm.ne'
      field_simp
    · exact integrable_comp_eval (X := fun _ : Fin (m + 2) => ℝ) (μ := fun _ => gaussianReal 0 1)
        (i := k.succ.succ) (f := fun x : ℝ => x ^ 2)
        ((memLp_id_gaussianReal (μ := 0) (v := 1) 2).integrable_sq)

/-- **The two forecast intervals (Steps 2 and 4).** Under the same model, fix a new temperature
`x₀` and let `ŷ₀ = β̂₀ + β̂₁ x₀` be the line's forecast there. Let a new day's sales be
`Y₀ = β₀ + β₁ x₀ + ε₀`, with its own noise `ε₀` normal with mean 0 and variance `σ²`, independent
of the `n` recorded noises. Then both
* the mean-sales ratio `(ŷ₀ − (β₀ + β₁ x₀)) / (s √h₀)`, and
* the new-day ratio `(Y₀ − ŷ₀) / (s √(1 + h₀))`, with the extra 1 for the new day's own noise,
have Student's t density with `n − 2` degrees of freedom. -/
theorem forecast_t_ratios_have_student_t_law
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (hn : 3 ≤ n) (x : Fin n → ℝ) (hx : ∃ i j, x i ≠ x j)
    (β₀ β₁ : ℝ) (σ : ℝ≥0) (hσ : 0 < σ)
    (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P)
    (hlaw : ∀ i, P.map (ε i) = gaussianReal 0 (σ ^ 2))
    (x0 : ℝ) (ε0 : Ω → ℝ) (hind0 : IndepFun ε0 (fun ω i => ε i ω) P)
    (hlaw0 : P.map ε0 = gaussianReal 0 (σ ^ 2)) :
    P.map (fun ω =>
        (intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
            slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0 - (β₀ + β₁ * x0)) /
          (√(s2 x (fun i => β₀ + β₁ * x i + ε i ω)) * √(h0 x x0))) =
        volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ((n : ℝ) - 2) t)) ∧
      P.map (fun ω =>
        (β₀ + β₁ * x0 + ε0 ω -
            (intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
              slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0)) /
          (√(s2 x (fun i => β₀ + β₁ * x i + ε i ω)) * √(1 + h0 x x0))) =
        volume.withDensity (fun t => ENNReal.ofReal (studentTPDF ((n : ℝ) - 2) t)) := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 2 := ⟨n - 2, by omega⟩
  have hm : 0 < m := by omega
  have hn0 : m + 2 ≠ 0 := by omega
  have hS := Sxx_pos x hx
  have hσ' : (0 : ℝ) < σ := hσ
  have hn' : (0 : ℝ) < ((m + 2 : ℕ) : ℝ) := by positivity
  have hhpos : 0 < h0 x x0 := by rw [h0]; positivity
  set p := (1 / √((m + 2 : ℕ) : ℝ)) / √(h0 x x0) with hp
  set q := ((x0 - mean x) / √(Sxx x)) / √(h0 x x0) with hq
  have hpq : p ^ 2 + q ^ 2 = 1 := by
    rw [hp, hq, div_pow, div_pow, div_pow, div_pow, Real.sq_sqrt hhpos.le, Real.sq_sqrt hS.le,
      Real.sq_sqrt hn'.le, ← add_div, one_pow]
    exact div_self hhpos.ne'
  obtain ⟨b, hb0, hb1⟩ := exists_basis m x hS p q hpq
  obtain ⟨hUm, hU⟩ := rotated_noise_law σ hσ ε hind hlaw b
  set U := fun ω k => inner ℝ (b k) (WithLp.toLp 2 (fun i => ε i ω / (σ : ℝ))) with hUdef
  have hcast : ((m + 2 : ℕ) : ℝ) - 2 = m := by push_cast; ring
  have hε : ∀ ω, (fun i => β₀ + β₁ * x i + ε i ω) =
      fun i => β₀ + β₁ * x i + (σ : ℝ) * (ε i ω / σ) := fun ω => by
    funext i; field_simp
  have hkey : ∀ z : Fin (m + 2) → ℝ, a1 z / √((m + 2 : ℕ) : ℝ) + (x0 - mean x) / √(Sxx x) * ax x z =
      √(h0 x x0) * (p * a1 z + q * ax x z) := by
    intro z
    have : √(h0 x x0) ≠ 0 := (Real.sqrt_pos.2 hhpos).ne'
    rw [hp, hq]
    field_simp
  have hfc : ∀ ω, intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
      slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0 - (β₀ + β₁ * x0) =
      (σ : ℝ) * (√(h0 x x0) * U ω 0) := by
    intro ω
    rw [hε ω, forecast_model' x _ β₀ β₁ _ x0 hn0 hS, hkey]
    simp only [hUdef, hb0, inner_comb]
  have hs2 : ∀ ω, s2 x (fun i => β₀ + β₁ * x i + ε i ω) =
      (σ : ℝ) ^ 2 * (∑ k : Fin m, U ω k.succ.succ ^ 2) / m := by
    intro ω
    rw [hε ω, s2, SSE_model' x _ β₀ β₁ _ hn0 hS, hcast, ← tail_sq m x p q hpq b hb0 hb1]
  constructor
  · rw [hcast, ← t_law m hm, ← proj_law m, Measure.map_map (by fun_prop) (by fun_prop), ← hU,
      AEMeasurable.map_map_of_aemeasurable (by fun_prop) hUm]
    congr 1
    funext ω
    rw [hfc ω, hs2 ω]
    exact ratio_aux' _ _ _ _ _ hσ' (Real.sqrt_pos.2 hhpos)
  · have hε0m : AEMeasurable ε0 P := aemeasurable_of_map_gaussianReal (by positivity) hlaw0
    have hV : P.map (fun ω => ε0 ω / σ) = gaussianReal 0 1 := by
      rw [show (fun ω => ε0 ω / (σ : ℝ)) = (fun t => t / (σ : ℝ)) ∘ ε0 from rfl,
        ← AEMeasurable.map_map_of_aemeasurable (by fun_prop) hε0m, hlaw0, gaussianReal_map_div_const]
      congr 1
      · simp
      · ext; simp [hσ.ne']
    have hψ : Measurable (fun (e : Fin (m + 2) → ℝ) (k : Fin (m + 2)) =>
        inner ℝ (b k) (WithLp.toLp 2 (fun i => e i / (σ : ℝ)))) := by fun_prop
    have hφ : Measurable (fun t : ℝ => t / (σ : ℝ)) := by fun_prop
    have hindVU : IndepFun (fun ω => ε0 ω / σ) U P := hind0.comp hφ hψ
    have hVU : P.map (fun ω => (ε0 ω / σ, U ω)) =
        (gaussianReal 0 1).prod (Measure.pi fun _ => gaussianReal 0 1) := by
      rw [(indepFun_iff_map_prod_eq_prod_map_map (hε0m.div_const _) hUm).1 hindVU, hV, hU]
    rw [hcast, ← t_law m hm, ← newday_law m (√(h0 x x0)), ← hVU,
      Measure.map_map (by fun_prop) (by fun_prop),
      AEMeasurable.map_map_of_aemeasurable (by fun_prop) ((hε0m.div_const _).prodMk hUm)]
    congr 1
    funext ω
    rw [hs2 ω, Real.sq_sqrt hhpos.le,
      show β₀ + β₁ * x0 + ε0 ω - (intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
          slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0) =
        ε0 ω - (intercept x (fun i => β₀ + β₁ * x i + ε i ω) +
          slope x (fun i => β₀ + β₁ * x i + ε i ω) * x0 - (β₀ + β₁ * x0)) by ring, hfc ω,
      show ε0 ω - (σ : ℝ) * (√(h0 x x0) * U ω 0) = (σ : ℝ) * (ε0 ω / σ - √(h0 x x0) * U ω 0) by
        field_simp]
    exact ratio_aux'' _ _ _ _ _ hσ'

/-! The card's café: ten days at 16, 18, …, 34 °C. -/

/-- Midday temperatures, °C. -/
def temps : Fin 10 → ℝ := ![16, 18, 20, 22, 24, 26, 28, 30, 32, 34]

/-- Iced coffees sold. -/
def sales : Fin 10 → ℝ := ![37, 33, 34, 31, 35, 49, 40, 53, 50, 38]

-- Averages: 25 °C and 40 coffees.
example : mean temps = 25 ∧ mean sales = 40 := by
  norm_num [mean, temps, sales, Fin.sum_univ_succ]
-- S_xx = 330.
example : Sxx temps = 330 := by
  norm_num [Sxx, mean, temps, Fin.sum_univ_succ]
-- The slope is 264 / 330 = 0.8 coffees per degree, and the intercept is 20.
example : slope temps sales = 4 / 5 ∧ intercept temps sales = 20 := by
  norm_num [intercept, slope, Sxx, mean, temps, sales, Fin.sum_univ_succ]
-- SSE = 342.8, so s² = 342.8 / 8 = 42.85.
example : SSE temps sales = 1714 / 5 ∧ s2 temps sales = 857 / 20 := by
  norm_num [s2, SSE, intercept, slope, Sxx, mean, temps, sales, Fin.sum_univ_succ]
-- The F road: S_yy − SSE = 554 − 342.8 = 211.2 = slope² · S_xx.
example : (554 : ℚ) - 1714 / 5 = (4 / 5) ^ 2 * 330 := by norm_num
-- At 30 °C: the line predicts 44, and h₀ = 1/10 + 25/330 = 29/165 (about 0.1758).
example : intercept temps sales + slope temps sales * 30 = 44 ∧ h0 temps 30 = 29 / 165 := by
  norm_num [h0, intercept, slope, Sxx, mean, temps, sales, Fin.sum_univ_succ]

#print axioms slope_t_ratio_has_student_t_law
#print axioms slope_unbiased_variance_and_s2_unbiased
#print axioms forecast_t_ratios_have_student_t_law

end RegressionInference
