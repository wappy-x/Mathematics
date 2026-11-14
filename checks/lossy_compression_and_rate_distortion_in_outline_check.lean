-- Rate and distortion: for a bell-curve value with variance σ², the fewest bits a copy with mean squared error at most D can carry about it is ½ log₂(σ²/D) (and 0 once D ≥ σ²), reverse water-filling is the best split of error among independent bell curves, and an orthonormal transform keeps the error the same on the weights as on the pixels.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.InformationTheory.KullbackLeibler.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory InformationTheory Real Finset
open scoped ENNReal NNReal

/-- The mutual information `I(X; X̂)` in bits of a joint law `P` of an original `X` (first
coordinate) and its copy `X̂` (second coordinate): the Kullback-Leibler divergence of `P` from
the product of its two marginals, in nats, divided by `ln 2`. -/
noncomputable def mutualInfoBits (P : Measure (ℝ × ℝ)) : ℝ≥0∞ :=
  klDiv P ((P.map Prod.fst).prod (P.map Prod.snd)) / ENNReal.ofReal (Real.log 2)

/-- Second central moment of a bell curve. -/
lemma rd_gauss_sq (c : ℝ) (w : ℝ≥0) :
    Integrable (fun x : ℝ => (x - c) ^ 2) (gaussianReal c w) ∧
      ∫ x, (x - c) ^ 2 ∂gaussianReal c w = w := by
  refine ⟨?_, ?_⟩
  · have h := (memLp_id_gaussianReal (μ := c) (v := w) 2).sub (memLp_const c)
    exact h.integrable_sq
  · have h := variance_fun_id_gaussianReal (μ := c) (v := w)
    rw [variance_eq_integral measurable_id'.aemeasurable] at h
    simpa only [integral_id_gaussianReal] using h

lemma rd_fst_sq (P : Measure (ℝ × ℝ)) (m : ℝ) (v : ℝ≥0)
    (h1 : P.map Prod.fst = gaussianReal m v) :
    Integrable (fun p : ℝ × ℝ => (p.1 - m) ^ 2) P ∧
      ∫ p, (p.1 - m) ^ 2 ∂P = v := by
  obtain ⟨hi, he⟩ := rd_gauss_sq m v
  rw [← h1] at hi he
  refine ⟨?_, ?_⟩
  · exact (integrable_map_measure (by fun_prop) measurable_fst.aemeasurable).mp hi
  · rw [integral_map measurable_fst.aemeasurable (by fun_prop)] at he
    exact he

/-- The core pointwise identity behind the Gaussian test channel. -/
lemma rd_core (m y x : ℝ) (v D : ℝ≥0) (hv : 0 < (v : ℝ)) (hD : 0 < (D : ℝ)) :
    gaussianPDFReal m v x * Real.exp ((x - m) ^ 2 / (2 * v) - (x - y) ^ 2 / (2 * D)) =
      √((D : ℝ) / v) * gaussianPDFReal y D x := by
  simp only [gaussianPDFReal]
  rw [mul_assoc, ← Real.exp_add]
  have e : -(x - m) ^ 2 / (2 * (v : ℝ)) + ((x - m) ^ 2 / (2 * v) - (x - y) ^ 2 / (2 * D))
      = -(x - y) ^ 2 / (2 * D) := by ring
  rw [e, ← mul_assoc]
  congr 1
  rw [Real.sqrt_div' _ hv.le, Real.sqrt_mul' _ hD.le, Real.sqrt_mul' _ hv.le]
  have h1 : 0 < √(2 * π) := Real.sqrt_pos.mpr (by positivity)
  have h2 : 0 < √(D : ℝ) := Real.sqrt_pos.mpr hD
  have h3 : 0 < √(v : ℝ) := Real.sqrt_pos.mpr hv
  field_simp

/-- The partition function of the tilt. -/
lemma rd_Z (m : ℝ) (v D : ℝ≥0) (hv : 0 < (v : ℝ)) (hD : 0 < (D : ℝ))
    (P2 : Measure ℝ) [IsProbabilityMeasure P2] :
    Integrable (fun p : ℝ × ℝ => Real.exp ((p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * D)))
        ((gaussianReal m v).prod P2) ∧
      ∫ p, Real.exp ((p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * D))
        ∂((gaussianReal m v).prod P2) = √((D : ℝ) / v) := by
  set f : ℝ × ℝ → ℝ := fun p => Real.exp ((p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * D))
    with hf
  have hfm : Measurable f := by fun_prop
  have hL : ∫⁻ p, ENNReal.ofReal (f p) ∂((gaussianReal m v).prod P2) =
      ENNReal.ofReal √((D : ℝ) / v) := by
    rw [lintegral_prod_symm _ (by fun_prop)]
    have inner : ∀ y, ∫⁻ x, ENNReal.ofReal (f (x, y)) ∂(gaussianReal m v) =
        ENNReal.ofReal √((D : ℝ) / v) := by
      intro y
      have hvne : v ≠ 0 := by
        intro h; rw [h] at hv; simp at hv
      have hDne : D ≠ 0 := by
        intro h; rw [h] at hD; simp at hD
      rw [gaussianReal_of_var_ne_zero m hvne,
        lintegral_withDensity_eq_lintegral_mul _ (measurable_gaussianPDF m v) (by fun_prop)]
      have hpt : ∀ x, (gaussianPDF m v * fun x => ENNReal.ofReal (f (x, y))) x =
          ENNReal.ofReal √((D : ℝ) / v) * gaussianPDF y D x := by
        intro x
        simp only [Pi.mul_apply, gaussianPDF, hf]
        rw [← ENNReal.ofReal_mul (gaussianPDFReal_nonneg _ _ _), rd_core m y x v D hv hD,
          ENNReal.ofReal_mul (Real.sqrt_nonneg _)]
      simp_rw [hpt]
      rw [lintegral_const_mul _ (measurable_gaussianPDF y D), lintegral_gaussianPDF_eq_one y hDne,
        mul_one]
    simp_rw [inner]
    simp
  have hint : Integrable f ((gaussianReal m v).prod P2) := by
    rw [← lintegral_ofReal_ne_top_iff_integrable hfm.aestronglyMeasurable
      (ae_of_all _ (fun p => (Real.exp_pos _).le))]
    rw [hL]; exact ENNReal.ofReal_ne_top
  refine ⟨hint, ?_⟩
  rw [integral_eq_lintegral_of_nonneg_ae (ae_of_all _ (fun p => (Real.exp_pos _).le))
    hfm.aestronglyMeasurable, hL, ENNReal.toReal_ofReal (Real.sqrt_nonneg _)]

/-- Donsker-Varadhan lower bound, from the tilted measure. -/
lemma rd_dv {α : Type*} [MeasurableSpace α] (P Q : Measure α) [IsProbabilityMeasure P]
    [IsProbabilityMeasure Q] (f : α → ℝ) (hac : P ≪ Q) (hllr : Integrable (llr P Q) P)
    (hf : Integrable f P) (hexp : Integrable (fun x => Real.exp (f x)) Q) :
    ∫ x, f x ∂P - Real.log (∫ x, Real.exp (f x) ∂Q) ≤ ∫ x, llr P Q x ∂P := by
  have := isProbabilityMeasure_tilted hexp
  have hac' : P ≪ Q.tilted f := hac.trans (absolutelyContinuous_tilted hexp)
  have hint' := integrable_llr_tilted_right hac hf hllr hexp
  have h0 := integral_llr_add_sub_measure_univ_nonneg hac' hint'
  rw [integral_llr_tilted_right hac hf hexp hllr] at h0
  simp only [probReal_univ] at h0
  linarith

/-- Kullback-Leibler divergence of a tilt from its base. -/
lemma rd_kl_tilt {α : Type*} [MeasurableSpace α] (Q : Measure α) [IsProbabilityMeasure Q]
    (f : α → ℝ) (hfm : Measurable f) (hexp : Integrable (fun x => Real.exp (f x)) Q)
    (hf : Integrable f (Q.tilted f)) :
    klDiv (Q.tilted f) Q =
      ENNReal.ofReal (∫ x, f x ∂(Q.tilted f) - Real.log (∫ x, Real.exp (f x) ∂Q)) := by
  have := isProbabilityMeasure_tilted hexp
  have hac : Q.tilted f ≪ Q := tilted_absolutelyContinuous Q f
  have h1 := llr_tilted_left (μ := Q) (ν := Q) Measure.AbsolutelyContinuous.rfl hexp
    hfm.aemeasurable
  have h2 := llr_self Q
  have h3 : llr (Q.tilted f) Q =ᵐ[Q] fun x => f x - Real.log (∫ z, Real.exp (f z) ∂Q) := by
    filter_upwards [h1, h2] with x hx1 hx2
    rw [hx1, hx2]; simp
  have h4 := hac.ae_le h3
  have hint : Integrable (llr (Q.tilted f) Q) (Q.tilted f) := by
    rw [integrable_congr h4]
    exact hf.sub (integrable_const _)
  rw [klDiv_of_ac_of_integrable hac hint, integral_congr_ae h4,
    integral_sub hf (integrable_const _)]
  simp

/-- The lower bound: every admissible copy carries at least `½ ln(σ²/D)` nats. -/
lemma rd_lower (m : ℝ) (v D : ℝ≥0) (hv : 0 < (v : ℝ)) (hD : 0 < (D : ℝ))
    (P : Measure (ℝ × ℝ)) [IsProbabilityMeasure P] (h1 : P.map Prod.fst = gaussianReal m v)
    (hint : Integrable (fun z : ℝ × ℝ => (z.1 - z.2) ^ 2) P)
    (hle : ∫ z, (z.1 - z.2) ^ 2 ∂P ≤ D) :
    ENNReal.ofReal (1 / 2 * Real.log ((v : ℝ) / D)) ≤
      klDiv P ((P.map Prod.fst).prod (P.map Prod.snd)) := by
  obtain ⟨hsi, hse⟩ := rd_fst_sq P m v h1
  rw [h1]
  by_cases hk : klDiv P ((gaussianReal m v).prod (P.map Prod.snd)) = ∞
  · rw [hk]; exact le_top
  obtain ⟨hac, hllr⟩ := klDiv_ne_top_iff.mp hk
  rw [klDiv_of_ac_of_integrable hac hllr]
  simp only [probReal_univ, add_sub_cancel_right]
  apply ENNReal.ofReal_le_ofReal
  obtain ⟨hZi, hZ⟩ := rd_Z m v D hv hD (P.map Prod.snd)
  have hfi : Integrable (fun p : ℝ × ℝ => (p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * D))
      P := (hsi.div_const _).sub (hint.div_const _)
  have hdv := rd_dv P ((gaussianReal m v).prod (P.map Prod.snd))
    (fun p : ℝ × ℝ => (p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * D)) hac hllr hfi hZi
  beta_reduce at hdv
  rw [hZ] at hdv
  have hfint : ∫ p, ((p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * D)) ∂P =
      1 / 2 - (∫ p, (p.1 - p.2) ^ 2 ∂P) / (2 * D) := by
    rw [integral_sub (hsi.div_const _) (hint.div_const _), integral_div, integral_div, hse]
    field_simp
  have hlog : Real.log √((D : ℝ) / v) = -(1 / 2 * Real.log ((v : ℝ) / D)) := by
    rw [Real.log_sqrt (by positivity), Real.log_div hD.ne' hv.ne', Real.log_div hv.ne' hD.ne']
    ring
  have h2 : (∫ p, (p.1 - p.2) ^ 2 ∂P) / (2 * D) ≤ 1 / 2 := by
    rw [div_le_iff₀ (by positivity)]; linarith
  rw [hfint, hlog] at hdv
  linarith

/-- Shearing a density on the plane. -/
lemma rd_shear (g : ℝ × ℝ → ℝ≥0∞) (hg : Measurable g) :
    (((volume : Measure ℝ).prod volume).withDensity g).map (fun p => (p.1 + p.2, p.2)) =
      ((volume : Measure ℝ).prod volume).withDensity (fun q => g (q.1 - q.2, q.2)) := by
  have hT : Measurable (fun p : ℝ × ℝ => (p.1 + p.2, p.2)) := by fun_prop
  ext s hs
  rw [Measure.map_apply hT hs, withDensity_apply _ (hT hs), withDensity_apply _ hs]
  have hmp := measurePreserving_add_prod (volume : Measure ℝ) (volume : Measure ℝ)
  rw [← hmp.setLIntegral_comp_preimage hs (f := fun q => g (q.1 - q.2, q.2)) (by fun_prop)]
  simp

/-- The Gaussian test channel: `X = Z + X̂` with `Z ~ N(0, D)` and `X̂ ~ N(m, σ² - D)`
independent, written as a tilt of the product of the marginals. -/
lemma rd_tilt_eq (m : ℝ) (v D a : ℝ≥0) (hv : 0 < (v : ℝ)) (hD : 0 < (D : ℝ)) (ha : a ≠ 0) :
    ((gaussianReal m v).prod (gaussianReal m a)).tilted
        (fun p : ℝ × ℝ => (p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * D)) =
      ((gaussianReal 0 D).prod (gaussianReal m a)).map (fun p => (p.1 + p.2, p.2)) := by
  have hvne : v ≠ 0 := by
    intro h; rw [h] at hv; simp at hv
  have hDne : D ≠ 0 := by
    intro h; rw [h] at hD; simp at hD
  rw [Measure.tilted, (rd_Z m v D hv hD (gaussianReal m a)).2]
  rw [gaussianReal_of_var_ne_zero m hvne, gaussianReal_of_var_ne_zero m ha,
    gaussianReal_of_var_ne_zero 0 hDne,
    prod_withDensity (measurable_gaussianPDF m v) (measurable_gaussianPDF m a),
    prod_withDensity (measurable_gaussianPDF 0 D) (measurable_gaussianPDF m a),
    ← withDensity_mul _ (by fun_prop) (by fun_prop), rd_shear _ (by fun_prop)]
  congr 1
  funext p
  simp only [Pi.mul_apply, gaussianPDF]
  rw [mul_comm (ENNReal.ofReal (gaussianPDFReal m v p.1)), mul_assoc,
    ← ENNReal.ofReal_mul (gaussianPDFReal_nonneg _ _ _), mul_comm (ENNReal.ofReal _)]
  congr 2
  have hs : 0 < √((D : ℝ) / v) := Real.sqrt_pos.mpr (by positivity)
  rw [← mul_div_assoc, rd_core m p.2 p.1 v D hv hD, mul_div_cancel_left₀ _ hs.ne']
  simp [gaussianPDFReal]

lemma rd_log_le (d a θ : ℝ) (hd : 0 < d) (ha : 0 < a) (hθ : 0 < θ)
    (h : (a = θ) ∨ (a ≤ θ ∧ d ≤ a)) :
    Real.log d - Real.log a ≤ (d - a) / θ := by
  have key : Real.log d - Real.log a ≤ (d - a) / a := by
    rw [← Real.log_div hd.ne' ha.ne']
    have := Real.log_le_sub_one_of_pos (div_pos hd ha)
    have e : d / a - 1 = (d - a) / a := by field_simp
    linarith
  rcases h with h | ⟨h1, h2⟩
  · subst h; exact key
  · have : (d - a) / a ≤ (d - a) / θ := by
      rw [div_le_div_iff₀ ha hθ]
      nlinarith
    linarith

lemma rd_frob {n : ℕ} (C A : Matrix (Fin n) (Fin n) ℝ) (hC : C * C.transpose = 1) :
    ∑ i, ∑ j, (C * A * C.transpose) i j ^ 2 = ∑ i, ∑ j, A i j ^ 2 := by
  have hC' : C.transpose * C = 1 := mul_eq_one_comm.mp hC
  have key : ∀ M : Matrix (Fin n) (Fin n) ℝ, ∑ i, ∑ j, M i j ^ 2 = (M * M.transpose).trace := by
    intro M
    simp [Matrix.trace, Matrix.mul_apply, sq]
  rw [key, key]
  have : (C * A * C.transpose) * (C * A * C.transpose).transpose =
      C * (A * A.transpose) * C.transpose := by
    simp only [Matrix.transpose_mul, Matrix.transpose_transpose, Matrix.mul_assoc]
    rw [← Matrix.mul_assoc C.transpose C, hC', Matrix.one_mul]
  rw [this, Matrix.trace_mul_comm, ← Matrix.mul_assoc, hC', Matrix.one_mul]

#print axioms rd_gauss_sq
#print axioms rd_fst_sq
#print axioms rd_core
#print axioms rd_Z
#print axioms rd_dv
#print axioms rd_kl_tilt
#print axioms rd_lower
#print axioms rd_shear
#print axioms rd_tilt_eq
#print axioms rd_log_le
#print axioms rd_frob

/-- **The rate-distortion function of a bell curve.** Let `X` be a bell-curve value with mean
`m` and variance `σ² > 0`, and allow an average squared error `D > 0`. Among all ways of making
a copy `X̂` (all joint laws of `X` and `X̂` whose first marginal is that bell curve and whose mean
squared error `E[(X - X̂)²]` is finite and at most `D`), the smallest mutual information
`I(X; X̂)` is exactly `R(D) = ½ log₂(σ²/D)` bits when `D < σ²`, and `0` when `D ≥ σ²`
(`ENNReal.ofReal` turns the negative values of the formula into `0`). -/
theorem gaussian_rate_distortion (m : ℝ) (v : ℝ≥0) (hv : 0 < v) (D : ℝ) (hD : 0 < D) :
    IsLeast
      {I : ℝ≥0∞ | ∃ P : Measure (ℝ × ℝ), IsProbabilityMeasure P ∧
          P.map Prod.fst = gaussianReal m v ∧
          Integrable (fun z : ℝ × ℝ => (z.1 - z.2) ^ 2) P ∧
          ∫ z, (z.1 - z.2) ^ 2 ∂P ≤ D ∧
          I = mutualInfoBits P}
      (ENNReal.ofReal (1 / 2 * Real.logb 2 ((v : ℝ) / D))) := by
  have hvR : 0 < (v : ℝ) := NNReal.coe_pos.mpr hv
  set Dn : ℝ≥0 := ⟨D, hD.le⟩ with hDn
  have hDnR : (Dn : ℝ) = D := rfl
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hval : ENNReal.ofReal (1 / 2 * Real.logb 2 ((v : ℝ) / D)) =
      ENNReal.ofReal (1 / 2 * Real.log ((v : ℝ) / D)) / ENNReal.ofReal (Real.log 2) := by
    rw [← ENNReal.ofReal_div_of_pos hl2, Real.logb, mul_div_assoc]
  constructor
  · by_cases hDv : D < v
    · have hDle : Dn ≤ v := by
        rw [← NNReal.coe_le_coe, hDnR]; exact hDv.le
      set a : ℝ≥0 := v - Dn with ha
      have hapos : a ≠ 0 := (tsub_pos_of_lt (show Dn < v by
        rw [← NNReal.coe_lt_coe, hDnR]; exact hDv)).ne'
      have hT : Measurable (fun p : ℝ × ℝ => (p.1 + p.2, p.2)) := by fun_prop
      set P := ((gaussianReal 0 Dn).prod (gaussianReal m a)).map (fun p => (p.1 + p.2, p.2))
        with hP
      have hP1 : P.map Prod.fst = gaussianReal m v := by
        rw [hP, Measure.map_map measurable_fst hT]
        have : (Prod.fst ∘ fun p : ℝ × ℝ => (p.1 + p.2, p.2)) = fun p => p.1 + p.2 := rfl
        rw [this]
        change (gaussianReal 0 Dn) ∗ (gaussianReal m a) = _
        rw [gaussianReal_conv_gaussianReal, zero_add, ha, add_tsub_cancel_of_le hDle]
      have hP2 : P.map Prod.snd = gaussianReal m a := by
        rw [hP, Measure.map_map measurable_snd hT]
        have : (Prod.snd ∘ fun p : ℝ × ℝ => (p.1 + p.2, p.2)) = Prod.snd := rfl
        rw [this, Measure.map_snd_prod, measure_univ, one_smul]
      obtain ⟨hRi, hRe⟩ := rd_fst_sq ((gaussianReal 0 Dn).prod (gaussianReal m a)) 0 Dn
        (by rw [Measure.map_fst_prod, measure_univ, one_smul])
      have hcomp : ((fun z : ℝ × ℝ => (z.1 - z.2) ^ 2) ∘ fun p : ℝ × ℝ => (p.1 + p.2, p.2)) =
          fun p => (p.1 - 0) ^ 2 := by
        funext p; simp
      have hPi : Integrable (fun z : ℝ × ℝ => (z.1 - z.2) ^ 2) P := by
        rw [hP, integrable_map_measure (by fun_prop) hT.aemeasurable, hcomp]
        exact hRi
      have hPe : ∫ z, (z.1 - z.2) ^ 2 ∂P = D := by
        rw [hP, integral_map hT.aemeasurable (by fun_prop)]
        have : ∀ p : ℝ × ℝ, (p.1 + p.2 - p.2) ^ 2 = (p.1 - 0) ^ 2 := by intro p; simp
        simp_rw [this]
        rw [hRe, hDnR]
      obtain ⟨hsi, hse⟩ := rd_fst_sq P m v hP1
      refine ⟨P, inferInstance, hP1, hPi, hPe.le, ?_⟩
      have hkey := rd_tilt_eq m v Dn a hvR hD hapos
      rw [← hP] at hkey
      obtain ⟨hZi, hZ⟩ := rd_Z m v Dn hvR hD (gaussianReal m a)
      have hfi : Integrable
          (fun p : ℝ × ℝ => (p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * Dn)) P :=
        (hsi.div_const _).sub (hPi.div_const _)
      have hfint : ∫ p, ((p.1 - m) ^ 2 / (2 * v) - (p.1 - p.2) ^ 2 / (2 * Dn)) ∂P = 0 := by
        rw [integral_sub (hsi.div_const _) (hPi.div_const _), integral_div, integral_div, hse,
          hDnR, hPe]
        field_simp
        ring
      rw [mutualInfoBits, hP1, hP2]
      rw [← hkey] at hfi hfint ⊢
      rw [rd_kl_tilt _ _ (by fun_prop) hZi hfi, hfint, hZ, hval]
      congr 2
      rw [Real.log_sqrt (by positivity), hDnR, Real.log_div hD.ne' hvR.ne',
        Real.log_div hvR.ne' hD.ne']
      ring
    · rw [not_lt] at hDv
      refine ⟨(gaussianReal m v).prod (Measure.dirac m), inferInstance, ?_, ?_, ?_, ?_⟩
      · rw [Measure.map_fst_prod, measure_univ, one_smul]
      · rw [Measure.prod_dirac, integrable_map_measure (by fun_prop) (by fun_prop)]
        exact (rd_gauss_sq m v).1
      · rw [Measure.prod_dirac, integral_map (by fun_prop) (by fun_prop)]
        have := (rd_gauss_sq m v).2
        simp only at this ⊢
        rw [this]; exact hDv
      · rw [mutualInfoBits, Measure.map_fst_prod, Measure.map_snd_prod, measure_univ, one_smul,
          measure_univ, one_smul, klDiv_self, ENNReal.zero_div]
        apply ENNReal.ofReal_of_nonpos
        have : Real.logb 2 ((v : ℝ) / D) ≤ 0 :=
          Real.logb_nonpos (by norm_num) (div_nonneg hvR.le hD.le)
            (by rw [div_le_one hD]; exact hDv)
        linarith
  · rintro I ⟨P, hP, h1, hint, hle, rfl⟩
    rw [hval, mutualInfoBits]
    exact ENNReal.div_le_div_right (rd_lower m v Dn hvR hD P h1 hint hle) _

/-- **Reverse water-filling.** Take independent bell-curve slots with variances `σ_k² > 0` and a
water level `θ > 0`. Splitting the total error `D = Σ_k min(θ, σ_k²)` among the slots, with each
slot's error `D_k` in `(0, σ_k²]` and slot `k` costing `½ log₂(σ_k²/D_k)` bits, the fewest bits
in total are `Σ_k max(0, ½ log₂(σ_k²/θ))`, and they are reached by giving each slot the error
`min(θ, σ_k²)`. -/
theorem reverse_water_filling {ι : Type*} [Fintype ι] (s : ι → ℝ) (hs : ∀ k, 0 < s k)
    (θ : ℝ) (hθ : 0 < θ) :
    IsLeast
      {R : ℝ | ∃ d : ι → ℝ, (∀ k, 0 < d k ∧ d k ≤ s k) ∧
          ∑ k, d k = ∑ k, min θ (s k) ∧
          R = ∑ k, 1 / 2 * Real.logb 2 (s k / d k)}
      (∑ k, max 0 (1 / 2 * Real.logb 2 (s k / θ))) ∧
    ∑ k, 1 / 2 * Real.logb 2 (s k / min θ (s k)) =
      ∑ k, max 0 (1 / 2 * Real.logb 2 (s k / θ)) := by
  have heq : ∀ k, 1 / 2 * Real.logb 2 (s k / min θ (s k)) =
      max 0 (1 / 2 * Real.logb 2 (s k / θ)) := by
    intro k
    rcases le_total θ (s k) with h | h
    · rw [min_eq_left h, max_eq_right]
      have : 0 ≤ Real.logb 2 (s k / θ) :=
        Real.logb_nonneg (by norm_num) (by rw [le_div_iff₀ hθ]; linarith)
      linarith
    · rw [min_eq_right h, div_self (hs k).ne', Real.logb_one, mul_zero, max_eq_left]
      have : Real.logb 2 (s k / θ) ≤ 0 :=
        Real.logb_nonpos (by norm_num) (div_nonneg (hs k).le hθ.le)
          (by rw [div_le_one hθ]; exact h)
      linarith
  have hsum : ∑ k, 1 / 2 * Real.logb 2 (s k / min θ (s k)) =
      ∑ k, max 0 (1 / 2 * Real.logb 2 (s k / θ)) := Finset.sum_congr rfl (fun k _ => heq k)
  refine ⟨⟨⟨fun k => min θ (s k), fun k => ⟨lt_min hθ (hs k), min_le_right _ _⟩, rfl,
    hsum.symm⟩, ?_⟩, hsum⟩
  rintro R ⟨d, hd, hdsum, rfl⟩
  rw [← hsum]
  have hl2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hterm : ∀ k, 1 / 2 * Real.logb 2 (s k / d k) - 1 / 2 * Real.logb 2 (s k / min θ (s k))
      = (Real.log (min θ (s k)) - Real.log (d k)) / (2 * Real.log 2) := by
    intro k
    have hm : 0 < min θ (s k) := lt_min hθ (hs k)
    simp only [Real.logb]
    rw [Real.log_div (hs k).ne' (hd k).1.ne', Real.log_div (hs k).ne' hm.ne']
    field_simp
    ring
  have hle : ∀ k, Real.log (d k) - Real.log (min θ (s k)) ≤ (d k - min θ (s k)) / θ := by
    intro k
    apply rd_log_le _ _ _ (hd k).1 (lt_min hθ (hs k)) hθ
    rcases le_total θ (s k) with h | h
    · left; exact min_eq_left h
    · right; rw [min_eq_right h]; exact ⟨h, (hd k).2⟩
  have htot : ∑ k, (Real.log (d k) - Real.log (min θ (s k))) ≤ 0 := by
    calc ∑ k, (Real.log (d k) - Real.log (min θ (s k)))
        ≤ ∑ k, (d k - min θ (s k)) / θ := Finset.sum_le_sum (fun k _ => hle k)
      _ = 0 := by
        rw [← Finset.sum_div, Finset.sum_sub_distrib, hdsum, sub_self, zero_div]
  have : 0 ≤ ∑ k, (1 / 2 * Real.logb 2 (s k / d k) -
      1 / 2 * Real.logb 2 (s k / min θ (s k))) := by
    simp_rw [hterm]
    rw [← Finset.sum_div]
    apply div_nonneg _ (by positivity)
    have : ∑ k, (Real.log (min θ (s k)) - Real.log (d k)) =
        -∑ k, (Real.log (d k) - Real.log (min θ (s k))) := by
      rw [← Finset.sum_neg_distrib]; congr 1; ext k; ring
    linarith
  rw [Finset.sum_sub_distrib] at this
  linarith

/-- **An orthonormal transform keeps lengths, so it keeps the error.** Let `C` be an `n × n`
matrix with perpendicular rows of length 1 (`C Cᵀ = 1`), such as the 8 by 8 cosine transform.
A tile `X` has weights `Y = C X Cᵀ`. If the weights are replaced by any `Ŷ` and the tile is
rebuilt as `X̂ = Cᵀ Ŷ C`, the sum of squared errors on the weights equals the sum of squared
errors on the pixels. -/
theorem orthonormal_transform_keeps_error {n : ℕ} (C : Matrix (Fin n) (Fin n) ℝ)
    (hC : C * C.transpose = 1) (X Yhat : Matrix (Fin n) (Fin n) ℝ) :
    ∑ i, ∑ j, ((C * X * C.transpose) i j - Yhat i j) ^ 2 =
      ∑ i, ∑ j, (X i j - (C.transpose * Yhat * C) i j) ^ 2 := by
  have hC' : C.transpose * C = 1 := mul_eq_one_comm.mp hC
  have h1 : C * X * C.transpose - Yhat = C * (X - C.transpose * Yhat * C) * C.transpose := by
    rw [Matrix.mul_sub, Matrix.sub_mul]
    congr 1
    simp only [Matrix.mul_assoc]
    rw [← Matrix.mul_assoc C C.transpose, hC, Matrix.one_mul]
    simp
  have := rd_frob C (X - C.transpose * Yhat * C) hC
  rw [← h1] at this
  simpa [Matrix.sub_apply] using this

-- Bell curve with σ² = 1 and allowed error D = 1/4: ½ log₂(1 / (1/4)) = ½ log₂ 4 = 1 bit.
example : (1 / 2 : ℝ) * Real.logb 2 (1 / (1 / 4)) = 1 := by
  rw [show (1 : ℝ) / (1 / 4) = 2 ^ (2 : ℕ) by norm_num, Real.logb_pow, Real.logb_self_eq_one]
    <;> norm_num
-- The weather station: spread 4, error 1, ½ log₂(4² / 1²) = 2 bits a day.
example : (1 / 2 : ℝ) * Real.logb 2 (4 ^ 2 / 1 ^ 2) = 2 := by
  rw [show (4 : ℝ) ^ 2 / 1 ^ 2 = 2 ^ (4 : ℕ) by norm_num, Real.logb_pow, Real.logb_self_eq_one]
    <;> norm_num
-- The formula read at D = 2σ²: ½ log₂(1/2) = -½ bit, a negative rate.
example : (1 / 2 : ℝ) * Real.logb 2 (1 / 2) = -1 / 2 := by
  rw [one_div, Real.logb_inv, Real.logb_self_eq_one] <;> norm_num
-- The photo: 128 by 128 pixels in 8 by 8 tiles gives 256 tiles, each with 63 detail weights.
example : (128 / 8) * (128 / 8) = 256 ∧ 8 * 8 - 1 = 63 ∧ 63 * 256 = 16128 := by decide
-- 8 bits a pixel sent at 0.8 bits a pixel is a ratio of 10 to 1.
example : (8 : ℚ) / (8 / 10) = 10 := by norm_num

#print axioms gaussian_rate_distortion
#print axioms reverse_water_filling
#print axioms orthonormal_transform_keeps_error
