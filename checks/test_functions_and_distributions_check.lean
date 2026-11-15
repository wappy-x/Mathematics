-- Distributions: a locally integrable function on the line gives a distribution by integrating against test functions, its distributional derivative agrees with the ordinary one, and the delta at 0 comes from no locally integrable function.
import Mathlib.Analysis.Distribution.Distribution
import Mathlib.MeasureTheory.Integral.IntegralEqImproper

open MeasureTheory TopologicalSpace Set LineDeriv
open scoped Distributions

/-- A function you can integrate on bounded intervals gives a distribution on the whole line:
the rule that reads a smooth probe `φ`, zero outside a bounded interval, as `∫ f(t) φ(t) dt`
is a continuous linear map on test functions. Its continuity is the card's bound with `m = 0`:
for a probe that is zero outside `[a, b]` and at most `M` in size, the reading is at most
`(∫ over [a, b] of |f|) · M`. -/
theorem locally_integrable_function_gives_distribution (f : ℝ → ℝ) (hf : LocallyIntegrable f) :
    ∃ T : 𝓓'((⊤ : Opens ℝ), ℝ),
      (∀ φ : 𝓓((⊤ : Opens ℝ), ℝ), T φ = ∫ t, f t * φ t) ∧
      ∀ (a b M : ℝ) (φ : 𝓓((⊤ : Opens ℝ), ℝ)),
        (∀ t ∉ Icc a b, φ t = 0) → (∀ t, |φ t| ≤ M) →
          |T φ| ≤ (∫ t in Icc a b, |f t|) * M := by
  have hf' : LocallyIntegrableOn f ((⊤ : Opens ℝ) : Set ℝ) volume := hf.locallyIntegrableOn _
  refine ⟨Distribution.ofFun (⊤ : Opens ℝ) f volume ⊤, ?_, ?_⟩
  · intro φ
    rw [Distribution.ofFun_apply hf']
    congr 1
    ext t
    rw [smul_eq_mul, mul_comm]
  · intro a b M φ hφ hM
    rw [Distribution.ofFun_apply hf']
    have hint : Integrable (fun t => φ t • f t) := φ.integrable_smul hf'
    have hfI : IntegrableOn f (Icc a b) := hf.integrableOn_isCompact isCompact_Icc
    calc |∫ t, φ t • f t| ≤ ∫ t, |φ t • f t| := abs_integral_le_integral_abs
      _ = ∫ t in Icc a b, |φ t • f t| := by
          rw [setIntegral_eq_integral_of_forall_compl_eq_zero]
          intro t ht
          simp [hφ t ht]
      _ ≤ ∫ t in Icc a b, |f t| * M := by
          apply setIntegral_mono_on hint.abs.integrableOn
            ((Integrable.abs hfI).mul_const M) measurableSet_Icc
          intro t _
          rw [smul_eq_mul, abs_mul, mul_comm]
          exact mul_le_mul_of_nonneg_left (hM t) (abs_nonneg _)
      _ = (∫ t in Icc a b, |f t|) * M := integral_mul_const _ _

/-- The new derivative agrees with the old one: if `f` has a continuous derivative `f'`, then the
derivative of the distribution made from `f` (which reads a probe `φ` as `-T_f(φ')`) is the
distribution made from `f'`. -/
theorem distributional_derivative_agrees_with_classical (f : ℝ → ℝ) (hf : ContDiff ℝ 1 f) :
    ∂_{(1 : ℝ)} (Distribution.ofFun (⊤ : Opens ℝ) f volume ⊤) =
      Distribution.ofFun (⊤ : Opens ℝ) (deriv f) volume ⊤ := by
  have hc : Continuous (deriv f) := hf.continuous_deriv le_rfl
  have hfl : LocallyIntegrableOn f ((⊤ : Opens ℝ) : Set ℝ) volume :=
    hf.continuous.locallyIntegrable.locallyIntegrableOn _
  have hfl' : LocallyIntegrableOn (deriv f) ((⊤ : Opens ℝ) : Set ℝ) volume :=
    hc.locallyIntegrable.locallyIntegrableOn _
  ext φ
  rw [Distribution.lineDerivOp_apply_apply, Distribution.ofFun_apply hfl,
    Distribution.ofFun_apply hfl']
  set ψ : 𝓓((⊤ : Opens ℝ), ℝ) := ∂_{(1 : ℝ)} φ with hψdef
  have hψ : ∀ x, HasDerivAt φ (ψ x) x := by
    intro x
    have hdiff : DifferentiableAt ℝ φ x :=
      (φ.contDiff.differentiable (by simp)).differentiableAt
    have : ψ x = lineDeriv ℝ φ x 1 := TestFunction.lineDerivCLM_apply_of_le (by simp)
    rw [this, hdiff.lineDeriv_eq_fderiv, fderiv_apply_one_eq_deriv]
    exact hdiff.hasDerivAt
  have hfd : ∀ x, HasDerivAt f (deriv f x) x := fun x =>
    ((hf.differentiable one_ne_zero) x).hasDerivAt
  have I1 : Integrable (f * ⇑ψ) := by
    convert ψ.integrable_smul hfl using 1
    ext x
    simp [mul_comm]
  have I2 : Integrable (deriv f * ⇑φ) := by
    convert φ.integrable_smul hfl' using 1
    ext x
    simp [mul_comm]
  have I3 : Integrable (f * ⇑φ) := by
    convert φ.integrable_smul hfl using 1
    ext x
    simp [mul_comm]
  have key := integral_mul_deriv_eq_deriv_mul_of_integrable (fun x _ => hfd x)
    (fun x _ => hψ x) I1 I2 I3
  have e1 : ∫ x, (-ψ) x • f x = -∫ x, f x * ψ x := by
    rw [← integral_neg]
    congr 1
    ext x
    simp [mul_comm]
  have e2 : ∫ x, φ x • deriv f x = ∫ x, deriv f x * φ x := by
    congr 1
    ext x
    simp [mul_comm]
  rw [e1, e2, key, neg_neg]

/-- The ideal tap is a distribution that no function gives: no locally integrable `g` reads
every probe `φ` as its value `φ(0)`, so the delta at 0 is not the distribution of any
locally integrable function. -/
theorem delta_not_given_by_any_function (g : ℝ → ℝ) (hg : LocallyIntegrable g) :
    Distribution.ofFun (⊤ : Opens ℝ) g volume ⊤ ≠ (Distribution.delta 0 : 𝓓'((⊤ : Opens ℝ), ℝ)) := by
  intro h
  have hgl : LocallyIntegrableOn g ((⊤ : Opens ℝ) : Set ℝ) volume := hg.locallyIntegrableOn _
  have key : ∀ φ : 𝓓((⊤ : Opens ℝ), ℝ), ∫ x, φ x • g x = φ 0 := by
    intro φ
    rw [← Distribution.ofFun_apply hgl, h, Distribution.delta_apply]
  have hae : ∀ᵐ x ∂(volume : Measure ℝ), x ∈ ({0}ᶜ : Set ℝ) → g x = 0 := by
    apply isOpen_compl_singleton.ae_eq_zero_of_integral_contDiff_smul_eq_zero
      (hg.locallyIntegrableOn _)
    intro ψ hψ hψc hψs
    let Φ : 𝓓((⊤ : Opens ℝ), ℝ) := ⟨ψ, hψ, hψc, by simp⟩
    have hΦ := key Φ
    change ∫ x, ψ x • g x = ψ 0 at hΦ
    rw [hΦ]
    exact image_eq_zero_of_notMem_tsupport (fun h0 => hψs h0 rfl)
  have h0 : ∀ᵐ x ∂(volume : Measure ℝ), x ≠ 0 := by
    rw [ae_iff]
    simp
  have hae' : g =ᵐ[(volume : Measure ℝ).restrict ((⊤ : Opens ℝ) : Set ℝ)] 0 := by
    rw [Opens.coe_top, Measure.restrict_univ]
    filter_upwards [hae, h0] with x hx hx0
    exact hx hx0
  have hz : Distribution.ofFun (⊤ : Opens ℝ) g volume ⊤ = 0 := by
    rw [Distribution.ofFun_congr_ae hae', Distribution.ofFun_zero]
  let b : ContDiffBump (0 : ℝ) := ⟨1, 2, one_pos, one_lt_two⟩
  let Φ : 𝓓((⊤ : Opens ℝ), ℝ) := ⟨b, b.contDiff, b.hasCompactSupport, by simp⟩
  have hb : b 0 = 1 := b.one_of_mem_closedBall (by simp [b])
  have hval := congrArg (fun T : 𝓓'((⊤ : Opens ℝ), ℝ) => T Φ) (hz.symm.trans h)
  simp only [zero_apply, Distribution.delta_apply] at hval
  change (0 : ℝ) = b 0 at hval
  rw [hb] at hval
  exact zero_ne_one hval

/-- The card's twelve samples and twelve weights (the finite rehearsal of Step 1). -/
def samples : List ℤ := [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8]
def weights : List ℤ := [0, 1, 3, 6, 8, 9, 8, 6, 3, 1, 0, 0]

/-- Summation by parts on the card's samples: read the differences of the samples against the
weights, and get exactly 9. -/
example : (∑ k ∈ Finset.range 11,
    (samples.getD (k + 1) 0 - samples.getD k 0) * weights.getD k 0) = 9 := by
  decide

/-- The other side: minus the samples read against the differences of the weights, also 9. -/
example : -(∑ k ∈ Finset.Icc 1 11,
    samples.getD k 0 * (weights.getD k 0 - weights.getD (k - 1) 0)) = 9 := by
  decide

#print axioms locally_integrable_function_gives_distribution
#print axioms distributional_derivative_agrees_with_classical
#print axioms delta_not_given_by_any_function
