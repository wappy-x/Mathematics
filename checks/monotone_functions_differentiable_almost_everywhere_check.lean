-- Lebesgue's theorem on monotone functions: an increasing real function has a derivative almost everywhere, the integral of that derivative over an interval is at most the function's rise, and for a right-continuous function the gap is the singular part of its measure.
import Mathlib.Analysis.Calculus.Monotone
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Measure.Stieltjes
import Mathlib.MeasureTheory.Measure.Decomposition.Lebesgue
import Mathlib.MeasureTheory.Measure.Decomposition.RadonNikodym
import Mathlib.Tactic.NormNum

open MeasureTheory Set

-- Helper lemmas.
theorem stieltjes_setIntegral_rnDeriv (G : StieltjesFunction ℝ) {s : Set ℝ}
    (hfin : G.measure s ≠ ⊤) :
    IntegrableOn (fun x => (G.measure.rnDeriv volume x).toReal) s ∧
      ∫ x in s, (G.measure.rnDeriv volume x).toReal
        = (∫⁻ x in s, G.measure.rnDeriv volume x).toReal := by
  have hm : AEMeasurable (G.measure.rnDeriv volume) (volume.restrict s) :=
    (Measure.measurable_rnDeriv _ _).aemeasurable
  have hlt : ∀ᵐ x ∂(volume.restrict s), G.measure.rnDeriv volume x < ⊤ :=
    ae_restrict_of_ae (Measure.rnDeriv_lt_top _ _)
  have hne : (∫⁻ x in s, G.measure.rnDeriv volume x) ≠ ⊤ :=
    ne_top_of_le_ne_top hfin (Measure.setLIntegral_rnDeriv_le s)
  exact ⟨integrable_toReal_of_lintegral_ne_top hm hne, integral_toReal hm hlt⟩

#print axioms stieltjes_setIntegral_rnDeriv

open Filter in
theorem monotone_line_integral_deriv_aux
    {F : ℝ → ℝ} (hF : Monotone F) :
    (∀ᵐ x, DifferentiableAt ℝ F x) ∧
      ∀ a b : ℝ, a ≤ b →
        IntervalIntegrable (deriv F) volume a b ∧ ∫ x in a..b, deriv F x ≤ F b - F a := by
  refine ⟨hF.ae_differentiableAt, fun a b hab => ?_⟩
  set G := hF.stieltjesFunction with hG
  have hae : ∀ᵐ x, deriv F x = (G.measure.rnDeriv volume x).toReal := by
    filter_upwards [hF.ae_hasDerivAt] with x hx using hx.deriv
  have hIoc := stieltjes_setIntegral_rnDeriv G (s := Ioc a b) (by simp [G.measure_Ioc])
  have hIoo := stieltjes_setIntegral_rnDeriv G (s := Ioo a b) (by simp [G.measure_Ioo])
  have hint : IntervalIntegrable (deriv F) volume a b := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le hab]
    exact hIoc.1.congr_fun_ae (ae_restrict_of_ae (hae.mono fun x hx => hx.symm))
  refine ⟨hint, ?_⟩
  have h1 : ∫ x in a..b, deriv F x = ∫ x in Ioo a b, (G.measure.rnDeriv volume x).toReal := by
    rw [intervalIntegral.integral_of_le hab, setIntegral_congr_set Ioo_ae_eq_Ioc.symm]
    exact integral_congr_ae (ae_restrict_of_ae hae)
  rw [h1, hIoo.2]
  have h2 : (∫⁻ x in Ioo a b, G.measure.rnDeriv volume x).toReal ≤ (G.measure (Ioo a b)).toReal :=
    ENNReal.toReal_mono (by simp [G.measure_Ioo]) (Measure.setLIntegral_rnDeriv_le _)
  refine h2.trans ?_
  rw [G.measure_Ioo, ENNReal.toReal_ofReal']
  have hlb : Function.leftLim G b ≤ F b := by
    apply le_of_tendsto (G.mono.tendsto_leftLim b)
    filter_upwards [self_mem_nhdsWithin] with y hy
    rw [hG, Monotone.stieltjesFunction_eq]
    exact hF.rightLim_le hy
  have hga : F a ≤ G a := by
    rw [hG, Monotone.stieltjesFunction_eq]
    exact hF.le_rightLim le_rfl
  have : F a ≤ F b := hF hab
  exact max_le (by linarith) (by linarith)

#print axioms monotone_line_integral_deriv_aux

/-- Lebesgue's theorem: if `F` is increasing and real-valued on the interval `[a, b]`, then
`F` has a finite derivative at almost every point of `[a, b]`, the derivative is integrable
on `[a, b]`, and its integral from `a` to `b` is at most the rise `F b - F a`. -/
theorem monotone_differentiable_ae_and_integral_deriv_le_rise
    {F : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b) (hF : MonotoneOn F (Icc a b)) :
    (∀ᵐ x ∂(volume.restrict (Icc a b)), DifferentiableAt ℝ F x) ∧
      IntervalIntegrable (deriv F) volume a b ∧
      ∫ x in a..b, deriv F x ≤ F b - F a := by
  set g : ℝ → ℝ := fun x => F (projIcc a b hab x) with hg
  have hgm : Monotone g := fun x y hxy =>
    hF (projIcc a b hab x).2 (projIcc a b hab y).2 (monotone_projIcc hab hxy)
  have hgF : ∀ x ∈ Icc a b, g x = F x := fun x hx => by
    simp only [hg, projIcc_of_mem hab hx]
  have hev : ∀ x ∈ Ioo a b, g =ᶠ[nhds x] F := fun x hx => by
    filter_upwards [Ioo_mem_nhds hx.1 hx.2] with y hy using hgF y (Ioo_subset_Icc_self hy)
  obtain ⟨hd, hi⟩ := monotone_line_integral_deriv_aux hgm
  obtain ⟨hint, hle⟩ := hi a b hab
  have hderiv : EqOn (deriv g) (deriv F) (Ioo a b) := fun x hx => (hev x hx).deriv_eq
  refine ⟨?_, ?_, ?_⟩
  · rw [Measure.restrict_congr_set Ioo_ae_eq_Icc.symm, ae_restrict_iff' measurableSet_Ioo]
    filter_upwards [hd] with x hx hxI
    exact hx.congr_of_eventuallyEq (hev x hxI).symm
  · exact hint.congr_uIoo (by rw [uIoo_of_le hab]; exact hderiv)
  · rw [← intervalIntegral.integral_congr_Ioo_of_le hab hderiv]
    have := hgF a (left_mem_Icc.2 hab)
    have := hgF b (right_mem_Icc.2 hab)
    linarith

/-- The same theorem for an increasing function on the whole line: it is differentiable
almost everywhere, and on every stretch `[a, b]` its derivative is integrable with integral
at most `F b - F a`. -/
theorem monotone_on_line_differentiable_ae_and_integral_deriv_le_rise
    {F : ℝ → ℝ} (hF : Monotone F) :
    (∀ᵐ x, DifferentiableAt ℝ F x) ∧
      ∀ a b : ℝ, a ≤ b →
        IntervalIntegrable (deriv F) volume a b ∧ ∫ x in a..b, deriv F x ≤ F b - F a := by
  exact monotone_line_integral_deriv_aux hF

/-- The exact shortfall: for an increasing right-continuous `F` (a Stieltjes function) with
Lebesgue-Stieltjes measure `μ_F`, the rise minus the integral of the derivative over `(a, b]`
is the mass that the singular part of `μ_F` (with respect to length) gives to `(a, b]`. -/
theorem rise_sub_integral_deriv_eq_singularPart (F : StieltjesFunction ℝ) {a b : ℝ}
    (hab : a ≤ b) :
    F b - F a - ∫ x in a..b, deriv F x =
      ((F.measure.singularPart volume) (Ioc a b)).toReal := by
  have hae : ∀ᵐ x, deriv F x = (F.measure.rnDeriv volume x).toReal := by
    filter_upwards [F.ae_hasDerivAt] with x hx using hx.deriv
  have hIoc := stieltjes_setIntegral_rnDeriv F (s := Ioc a b) (by simp [F.measure_Ioc])
  have h1 : ∫ x in a..b, deriv F x = (∫⁻ x in Ioc a b, F.measure.rnDeriv volume x).toReal := by
    rw [intervalIntegral.integral_of_le hab, ← hIoc.2]
    exact integral_congr_ae (ae_restrict_of_ae hae)
  have hdec := congrArg (fun μ : Measure ℝ => μ (Ioc a b))
    (Measure.haveLebesgueDecomposition_add F.measure volume)
  rw [Measure.add_apply, withDensity_apply _ measurableSet_Ioc, F.measure_Ioc] at hdec
  have hS : (F.measure.singularPart volume) (Ioc a b) ≠ ⊤ := by
    intro h; rw [h, top_add] at hdec; exact ENNReal.ofReal_ne_top hdec
  have hL : (∫⁻ x in Ioc a b, F.measure.rnDeriv volume x) ≠ ⊤ := by
    intro h; rw [h, add_top] at hdec; exact ENNReal.ofReal_ne_top hdec
  have h2 := congrArg ENNReal.toReal hdec
  rw [ENNReal.toReal_ofReal (sub_nonneg.2 (F.mono hab)), ENNReal.toReal_add hS hL] at h2
  rw [h1, h2]
  ring

-- The Cantor staircase stages: at stage n there are 2^n rising cells of width 3^(-n),
-- each with slope (3/2)^n, so the stage slopes integrate to exactly 1.
example : (2 : ℕ) ^ 10 = 1024 ∧ (3 : ℕ) ^ 10 = 59049 := by norm_num
example : ((3 : ℚ) / 2) ^ 4 = 81 / 16 := by norm_num
example (n : ℕ) : (2 : ℚ) ^ n * ((3 : ℚ) / 2) ^ n * (1 / 3 ^ n) = 1 := by
  rw [div_pow, one_div]; field_simp
-- The three-piece law on [-1, 1]: shortfall 0.5 is the jump 0.3 plus the staircase 0.2.
example : (3 : ℚ) / 10 + 2 / 10 = 1 / 2 := by norm_num

#print axioms monotone_differentiable_ae_and_integral_deriv_le_rise
#print axioms monotone_on_line_differentiable_ae_and_integral_deriv_le_rise
#print axioms rise_sub_integral_deriv_eq_singularPart
