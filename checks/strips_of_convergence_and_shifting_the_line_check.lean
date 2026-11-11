-- Where a transform lives: a signal that grows at most exponentially at each end has a two-sided Laplace transform that converges and is holomorphic on the open strip between the two growth rates, the inverse integral up any vertical line in that strip returns the signal wherever it is continuous, and damping by e^(−at) turns the Fourier transform into the transform read along Re s = a.
import Mathlib.Analysis.MellinInversion
import Mathlib.MeasureTheory.Function.LocallyIntegrable
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Tactic.NormNum

open MeasureTheory Complex Asymptotics Filter Set

/-- The card's two-sided Laplace transform, run over all time, past and future:
`F(s) = ∫ f(t) e^(−st) dt` over the whole real line. -/
noncomputable def twoSidedLaplace (f : ℝ → ℂ) (s : ℂ) : ℂ :=
  ∫ t : ℝ, f t * cexp (-(s * t))

/-- The card's inverse up the vertical line `Re s = σ`:
`(1 / 2πi) ∫ F(s) e^(st) ds` with `s = σ + iy`, so `ds = i dy`. -/
noncomputable def inverseOnLine (F : ℂ → ℂ) (σ t : ℝ) : ℂ :=
  (1 / (2 * Real.pi * I)) * ∫ y : ℝ, F (σ + y * I) * cexp ((σ + y * I) * t) * I

theorem slx_deriv :
    ∀ x ∈ (univ : Set ℝ), HasDerivWithinAt (Real.exp ∘ Neg.neg) (-Real.exp (-x)) univ x :=
  fun x _ ↦ mul_neg_one (Real.exp (-x)) ▸
    ((Real.hasDerivAt_exp (-x)).comp x (hasDerivAt_neg x)).hasDerivWithinAt

theorem slx_image : Real.exp ∘ Neg.neg '' (univ : Set ℝ) = Ioi 0 := by
  rw [Set.image_comp, Set.image_univ_of_surjective neg_surjective, Set.image_univ, Real.range_exp]

theorem slx_inj : (univ : Set ℝ).InjOn (Real.exp ∘ Neg.neg) :=
  Real.exp_injective.injOn.comp neg_injective.injOn (univ.mapsTo_univ _)

theorem slx_cpow (t : ℝ) (z : ℂ) : ((Real.exp (-t) : ℝ) : ℂ) ^ z = cexp (-(z * t)) := by
  rw [Complex.ofReal_exp, Complex.cpow_def_of_ne_zero (Complex.exp_ne_zero _),
    Complex.log_exp (by simp [Real.pi_pos]) (by simpa using Real.pi_nonneg)]
  push_cast; ring_nf

theorem slx_integrand (f : ℝ → ℂ) (s : ℂ) (u : ℝ) :
    |-Real.exp (-u)| • (((Real.exp (-u) : ℝ) : ℂ) ^ (s - 1) • f (-Real.log ((Real.exp ∘ Neg.neg) u))) =
      f u * cexp (-(s * u)) := by
  simp only [Function.comp, Real.log_exp, neg_neg, abs_neg, abs_of_pos (Real.exp_pos _)]
  rw [slx_cpow, smul_eq_mul, Complex.real_smul, Complex.ofReal_exp, ← mul_assoc,
    ← Complex.exp_add, mul_comm]
  congr 2; push_cast; ring

theorem slx_laplace_eq_mellin (f : ℝ → ℂ) (s : ℂ) :
    twoSidedLaplace f s = mellin (fun x => f (-Real.log x)) s := by
  rw [mellin, ← slx_image, integral_image_eq_integral_abs_deriv_smul MeasurableSet.univ slx_deriv
    slx_inj, Measure.restrict_univ, twoSidedLaplace]
  congr 1; ext u; exact (slx_integrand f s u).symm

theorem slx_conv_iff (f : ℝ → ℂ) (s : ℂ) :
    MellinConvergent (fun x => f (-Real.log x)) s ↔ Integrable (fun t : ℝ => f t * cexp (-(s * t))) := by
  rw [MellinConvergent, ← slx_image, integrableOn_image_iff_integrableOn_abs_deriv_smul
    MeasurableSet.univ slx_deriv slx_inj, integrableOn_univ]
  exact Iff.of_eq (congrArg (fun F : ℝ → ℂ => Integrable F volume) (funext (slx_integrand f s)))

theorem slx_top (f : ℝ → ℂ) (β : ℝ) (hpast : f =O[atBot] fun t => Real.exp (β * t)) :
    (fun x => f (-Real.log x)) =O[atTop] (· ^ (-β)) := by
  have ht : Tendsto (fun x : ℝ => -Real.log x) atTop atBot :=
    tendsto_neg_atTop_atBot.comp Real.tendsto_log_atTop
  refine (hpast.comp_tendsto ht).congr' (Eventually.of_forall fun _ => rfl) ?_
  filter_upwards [eventually_gt_atTop 0] with x hx
  simp only [Function.comp, Real.rpow_def_of_pos hx]
  congr 1; ring

theorem slx_bot (f : ℝ → ℂ) (α : ℝ) (hfuture : f =O[atTop] fun t => Real.exp (α * t)) :
    (fun x => f (-Real.log x)) =O[nhdsWithin 0 (Ioi 0)] (· ^ (-α)) := by
  have ht : Tendsto (fun x : ℝ => -Real.log x) (nhdsWithin 0 (Ioi 0)) atTop :=
    tendsto_neg_atBot_atTop.comp Real.tendsto_log_nhdsGT_zero
  refine (hfuture.comp_tendsto ht).congr' (Eventually.of_forall fun _ => rfl) ?_
  filter_upwards [self_mem_nhdsWithin] with x hx
  simp only [Function.comp, Real.rpow_def_of_pos (show (0:ℝ) < x from hx)]
  congr 1; ring

theorem slx_locint (f : ℝ → ℂ) (hloc : LocallyIntegrable f) :
    LocallyIntegrableOn (fun x => f (-Real.log x)) (Ioi 0) := by
  rw [locallyIntegrableOn_iff isOpen_Ioi.isLocallyClosed]
  intro K hK hKc
  have hcont : ContinuousOn (fun x : ℝ => -Real.log x) K :=
    (Real.continuousOn_log.mono (fun x hx => (show (0:ℝ) < x from hK hx).ne')).neg
  have hS : IsCompact ((fun x : ℝ => -Real.log x) '' K) := hKc.image_of_continuousOn hcont
  have himg : (Real.exp ∘ Neg.neg) '' ((fun x : ℝ => -Real.log x) '' K) = K := by
    rw [Set.image_image]
    refine (Set.image_congr fun x hx => ?_).trans (Set.image_id K)
    simp [Real.exp_log (show (0:ℝ) < x from hK hx)]
  rw [← himg, integrableOn_image_iff_integrableOn_abs_deriv_smul hS.measurableSet
    (fun x _ => (slx_deriv x trivial).mono (subset_univ _)) (slx_inj.mono (subset_univ _))]
  have := (hloc.integrableOn_isCompact hS).continuousOn_smul
    (f := fun x => |-Real.exp (-x)|) (by fun_prop) hS
  refine this.congr_fun (fun x _ => ?_) hS.measurableSet
  simp [Real.log_exp]

theorem slx_mul_unit_iff (g : ℝ → ℂ) (ω : ℝ) :
    Integrable (fun t : ℝ => g t * cexp (-(I * ω * t))) ↔ Integrable g := by
  have hu : Continuous fun t : ℝ => cexp (-(I * ω * t)) := by fun_prop
  have hu' : Continuous fun t : ℝ => cexp (I * ω * t) := by fun_prop
  have hn : ∀ t : ℝ, ‖cexp (-(I * ω * t))‖ = 1 := fun t => by
    rw [Complex.norm_exp]; simp
  constructor
  · intro h
    have hm : AEStronglyMeasurable g := by
      have := h.1.mul hu'.aestronglyMeasurable
      refine this.congr (Eventually.of_forall fun t => ?_)
      show g t * cexp (-(I * ω * t)) * cexp (I * ω * t) = g t
      rw [mul_assoc, ← Complex.exp_add, neg_add_cancel, Complex.exp_zero, mul_one]
    exact h.congr' hm (Eventually.of_forall fun t => by simp [hn])
  · intro h
    exact h.congr' (h.1.mul hu.aestronglyMeasurable) (Eventually.of_forall fun t => by
      simp [hn])

/-- **The line slides without changing the answer.** Let the signal `f` grow at most
exponentially at each end: no faster than `e^(αt)` as `t → +∞` and no faster than `e^(βt)` as
`t → −∞` (and `f` has finite area over every bounded stretch of time, so its integrals make
sense). Take any line `Re s = σ` inside the open strip `α < σ < β`, on which the transform `F`
fades enough that the inverse integral up the line exists (`|F|` has finite area along it).
Then at every time `t` where `f` is continuous, the inverse up that line returns `f(t)`. So
every such line in the strip gives the same answer. -/
theorem inverse_up_any_line_in_strip_returns_signal (f : ℝ → ℂ) (α β : ℝ)
    (hloc : LocallyIntegrable f)
    (hfuture : f =O[atTop] fun t => Real.exp (α * t))
    (hpast : f =O[atBot] fun t => Real.exp (β * t))
    (σ : ℝ) (hσ : σ ∈ Ioo α β)
    (hfade : Integrable fun y : ℝ => twoSidedLaplace f (σ + y * I))
    (t : ℝ) (hcont : ContinuousAt f t) :
    inverseOnLine (twoSidedLaplace f) σ t = f t := by
  set h : ℝ → ℂ := fun x => f (-Real.log x) with hh
  have hσt : ((σ : ℂ)).re < β := by simpa using hσ.2
  have hσb : α < ((σ : ℂ)).re := by simpa using hσ.1
  have hconv : MellinConvergent h σ :=
    mellinConvergent_of_isBigO_rpow (slx_locint f hloc) (slx_top f β hpast) hσt
      (slx_bot f α hfuture) hσb
  have e1 : mellin h = twoSidedLaplace f := funext fun s => (slx_laplace_eq_mellin f s).symm
  have hvi : VerticalIntegrable (mellin h) σ := by
    rw [e1]; exact hfade
  have hcx : ContinuousAt h (Real.exp (-t)) := by
    refine ContinuousAt.comp_of_eq hcont ((Real.continuousAt_log (Real.exp_pos _).ne').neg) ?_
    simp [Real.log_exp]
  have key := mellinInv_mellin_eq σ h (Real.exp_pos (-t)) hconv hvi hcx
  rw [e1] at key
  simp only [hh, Real.log_exp, neg_neg] at key
  rw [← key, inverseOnLine, mellinInv, integral_mul_const]
  simp_rw [slx_cpow, smul_eq_mul, Complex.real_smul]
  have hI : I ≠ 0 := Complex.I_ne_zero
  have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_pos.ne'
  have : (fun y : ℝ => cexp (-(-((σ : ℂ) + y * I) * t)) * twoSidedLaplace f (σ + y * I)) =
      fun y : ℝ => twoSidedLaplace f (σ + y * I) * cexp ((σ + y * I) * t) := by
    ext y; rw [mul_comm]; congr 2; ring
  rw [this]
  push_cast
  field_simp
  congr 1; ext a; ring_nf

/-- **A strip of convergence, holomorphic inside.** If `f` grows no faster than `e^(αt)` as
`t → +∞` and no faster than `e^(βt)` as `t → −∞` (and has finite area over every bounded
stretch), then at every `s` with `α < Re s < β` the defining integral of `F(s)` converges
absolutely, and `F` has a complex derivative there equal to the transform of `−t f(t)`. -/
theorem transform_converges_and_is_holomorphic_on_strip (f : ℝ → ℂ) (α β : ℝ)
    (hloc : LocallyIntegrable f)
    (hfuture : f =O[atTop] fun t => Real.exp (α * t))
    (hpast : f =O[atBot] fun t => Real.exp (β * t))
    (s : ℂ) (hs : s.re ∈ Ioo α β) :
    Integrable (fun t : ℝ => f t * cexp (-(s * t))) ∧
      HasDerivAt (twoSidedLaplace f) (twoSidedLaplace (fun t => -(t : ℂ) * f t) s) s := by
  obtain ⟨-, hd⟩ := mellin_hasDerivAt_of_isBigO_rpow (slx_locint f hloc) (slx_top f β hpast) hs.2
    (slx_bot f α hfuture) hs.1
  refine ⟨(slx_conv_iff f s).1 (mellinConvergent_of_isBigO_rpow (slx_locint f hloc)
    (slx_top f β hpast) hs.2 (slx_bot f α hfuture) hs.1), ?_⟩
  have e1 : twoSidedLaplace f = mellin (fun x => f (-Real.log x)) :=
    funext (slx_laplace_eq_mellin f)
  have e2 : twoSidedLaplace (fun t => -(t : ℂ) * f t) s =
      mellin (fun t => Real.log t • f (-Real.log t)) s := by
    rw [slx_laplace_eq_mellin]; congr 1; ext x; simp [Complex.real_smul]
  rw [e2, e1]; exact hd

/-- **Damping is moving the line.** For any signal `f`, damping rate `a` and frequency `ω`:
the Fourier integral of the damped signal `e^(−at) f(t)` at `ω` converges absolutely exactly
when the transform's integral converges absolutely at the real point `s = a` (only the damping,
not the frequency, decides), and its value is `F(a + iω)`, the transform read along `Re s = a`. -/
theorem damped_fourier_is_transform_on_line (f : ℝ → ℂ) (a ω : ℝ) :
    (Integrable (fun t : ℝ => (Real.exp (-a * t) : ℂ) * f t * cexp (-(I * ω * t))) ↔
        Integrable (fun t : ℝ => f t * cexp (-((a : ℂ) * t)))) ∧
      ∫ t : ℝ, (Real.exp (-a * t) : ℂ) * f t * cexp (-(I * ω * t)) =
        twoSidedLaplace f (a + ω * I) := by
  have hpt : ∀ t : ℝ, (Real.exp (-a * t) : ℂ) * f t * cexp (-(I * ω * t)) =
      (f t * cexp (-((a : ℂ) * t))) * cexp (-(I * ω * t)) := fun t => by
    rw [Complex.ofReal_exp]; push_cast; ring_nf
  have hpt2 : ∀ t : ℝ, (Real.exp (-a * t) : ℂ) * f t * cexp (-(I * ω * t)) =
      f t * cexp (-((a + ω * I) * t)) := fun t => by
    rw [hpt, mul_assoc, ← Complex.exp_add]; congr 2; ring
  refine ⟨?_, ?_⟩
  · simp_rw [hpt]; exact slx_mul_unit_iff _ ω
  · rw [twoSidedLaplace]; simp_rw [hpt2]

-- Worked numbers, exact. The rates 0.05, 0.10 and 0.20 are written 1/20, 1/10 and 1/5.
-- The balance's transform at s = 0.10: 1/(0.10 − 0.05) = 20.
example : (1 : ℂ) / (1 / 10 - 1 / 20) = 20 := by norm_num
-- Damped by a = 0.10, read at frequency 0.05: F(0.10 + 0.05i) = 1/(0.05 + 0.05i) = 10 − 10i.
example : (1 : ℂ) / ((1 / 10 + 1 / 20 * I) - 1 / 20) = 10 - 10 * I := by
  rw [div_eq_iff (by simp [Complex.ext_iff])]; ring_nf; simp [I_sq]; ring_nf
-- h's Fourier transform at ω = 0.1: H(0.1i) = 1/(0.05 − 0.1i) + 1/(0.1i + 0.20) = 8 + 6i.
example : (1 : ℂ) / (1 / 20 - 1 / 10 * I) + 1 / (1 / 10 * I + 1 / 5) = 8 + 6 * I := by
  have h1 : (1 / 20 - 1 / 10 * I : ℂ) ≠ 0 := by simp [Complex.ext_iff]
  have h2 : (1 / 10 * I + 1 / 5 : ℂ) ≠ 0 := by simp [Complex.ext_iff]
  rw [div_add_div _ _ h1 h2, div_eq_iff (mul_ne_zero h1 h2)]
  ring_nf
  rw [I_sq, I_pow_three]; ring_nf
-- H(0) = 1/0.05 + 1/0.20 = 25, the area under h.
example : (1 : ℂ) / (1 / 20 - 0) + 1 / (0 + 1 / 5) = 25 := by norm_num
-- The pole at 0.05: 1/(0.05 − s) = −1/(s − 0.05), so the residue of H(s) e^(st) there is −e^(0.05t).
example (s : ℂ) (hs : s ≠ 1 / 20) : 1 / (1 / 20 - s) = -(1 / (s - 1 / 20)) := by
  rw [← one_div_neg_eq_neg_one_div, neg_sub]
-- The figure, 800 units per unit, origin x = 240: poles at −0.20 and 0.05 sit at x = 80 and 280.
example : (240 : ℚ) + 800 * (-1 / 5) = 80 ∧ (240 : ℚ) + 800 * (1 / 20) = 280 := by norm_num

#print axioms inverse_up_any_line_in_strip_returns_signal
#print axioms transform_converges_and_is_holomorphic_on_strip
#print axioms damped_fourier_is_transform_on_line
#print axioms slx_deriv
#print axioms slx_image
#print axioms slx_inj
#print axioms slx_cpow
#print axioms slx_integrand
#print axioms slx_laplace_eq_mellin
#print axioms slx_conv_iff
#print axioms slx_top
#print axioms slx_bot
#print axioms slx_locint
#print axioms slx_mul_unit_iff
