-- The Laplace transform: for a continuous signal that grows no faster than M e^(at) and has a differentiable stretch after time zero, the transform of its derivative is s times its transform minus its starting value at every s with Re s > a; such a signal's transform converges there, and 1, t, e^(at) and cos(bt) transform to 1/s, 1/s^2, 1/(s − a) and s/(s^2 + b^2).
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open MeasureTheory Set Complex

/-- The card's Laplace transform: `F(s) = ∫₀^∞ f(t) e^(−st) dt`, a signal `f` from time zero
on, weighted by `e^(−st)` for a complex number `s`, and added up. -/
noncomputable def laplace (f : ℝ → ℂ) (s : ℂ) : ℂ :=
  ∫ t in Ioi (0 : ℝ), f t * cexp (-(s * t))

theorem laplace_integrable_aux (f : ℝ → ℂ) (M a : ℝ) (s : ℂ)
    (hmeas : AEStronglyMeasurable f (volume.restrict (Ioi 0)))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → ‖f t‖ ≤ M * Real.exp (a * t))
    (hs : a < s.re) :
    IntegrableOn (fun t : ℝ => f t * cexp (-(s * t))) (Ioi 0) := by
  refine Integrable.mono' ((integrableOn_exp_mul_Ioi (a := a - s.re) (by linarith) 0).const_mul M)
    ?_ ?_
  · exact hmeas.mul (Continuous.aestronglyMeasurable (by fun_prop))
  · filter_upwards [ae_restrict_mem measurableSet_Ioi] with t ht
    rw [norm_mul, Complex.norm_exp]
    have h1 : (-(s * (t : ℂ))).re = -(s.re * t) := by simp
    rw [h1]
    calc ‖f t‖ * Real.exp (-(s.re * t)) ≤ M * Real.exp (a * t) * Real.exp (-(s.re * t)) :=
          mul_le_mul_of_nonneg_right (hgrowth t (le_of_lt ht)) (Real.exp_pos _).le
      _ = M * Real.exp ((a - s.re) * t) := by rw [mul_assoc, ← Real.exp_add]; ring_nf

#print axioms laplace_integrable_aux

theorem laplace_cexp_aux (c s : ℂ) (h : c.re < s.re) :
    laplace (fun t => cexp (c * t)) s = 1 / (s - c) := by
  have hne : s - c ≠ 0 := by
    intro h0; have := congrArg Complex.re h0; simp at this; linarith
  unfold laplace
  have : (fun t : ℝ => cexp (c * t) * cexp (-(s * t))) = fun t : ℝ => cexp ((c - s) * t) := by
    funext t; rw [← Complex.exp_add]; ring_nf
  rw [this, integral_exp_mul_complex_Ioi (by simp; linarith)]
  have hne2 : c - s ≠ 0 := by intro h0; apply hne; linear_combination -h0
  rw [ofReal_zero, mul_zero, Complex.exp_zero]
  field_simp
  ring

#print axioms laplace_cexp_aux

theorem laplace_cexp_integrable (c s : ℂ) (h : c.re < s.re) :
    IntegrableOn (fun t : ℝ => cexp (c * t) * cexp (-(s * t))) (Ioi 0) := by
  have : (fun t : ℝ => cexp (c * t) * cexp (-(s * t))) = fun t : ℝ => cexp ((c - s) * t) := by
    funext t; rw [← Complex.exp_add]; ring_nf
  rw [this]
  exact integrableOn_exp_mul_complex_Ioi (by simp; linarith) 0

#print axioms laplace_cexp_integrable

/-- The derivative rule: if the signal `f` has no jumps from time zero on, has derivative `f'`
after time zero, grows no faster than `M e^(at)`, and `f'` has a transform at `s`, then at every
`s` right of the line `Re s = a` the transform of `f'` is `s F(s) − f(0)`. -/
theorem laplace_deriv_eq_mul_sub (f f' : ℝ → ℂ) (M a : ℝ) (s : ℂ)
    (hcont : ContinuousOn f (Ici 0))
    (hderiv : ∀ t ∈ Ioi (0 : ℝ), HasDerivAt f (f' t) t)
    (hgrowth : ∀ t : ℝ, 0 ≤ t → ‖f t‖ ≤ M * Real.exp (a * t))
    (hs : a < s.re)
    (hf' : IntegrableOn (fun t : ℝ => f' t * cexp (-(s * t))) (Ioi 0)) :
    laplace f' s = s * laplace f s - f 0 := by
  have hint := laplace_integrable_aux f M a s
    ((hcont.mono Ioi_subset_Ici_self).aestronglyMeasurable measurableSet_Ioi) hgrowth hs
  have hv : ∀ t ∈ Ioi (0:ℝ), HasDerivAt (fun t : ℝ => cexp (-(s * t)))
      (-s * cexp (-(s * t))) t := by
    intro t _
    have := (((hasDerivAt_id t).ofReal_comp).const_mul s).neg.cexp
    simpa [mul_comm] using this
  have huv' : IntegrableOn (f * fun t : ℝ => -s * cexp (-(s * t))) (Ioi 0) := by
    refine IntegrableOn.congr_fun (hint.const_mul (-s)) (fun t _ => ?_) measurableSet_Ioi
    simp only [Pi.mul_apply]; ring
  have h_zero : Filter.Tendsto (f * fun t : ℝ => cexp (-(s * t))) (nhdsWithin 0 (Ioi 0)) (nhds (f 0)) := by
    have h1 : Filter.Tendsto f (nhdsWithin 0 (Ioi 0)) (nhds (f 0)) :=
      ((hcont 0 (Set.mem_Ici.2 le_rfl)).mono Ioi_subset_Ici_self).tendsto
    have h2 : Filter.Tendsto (fun t : ℝ => cexp (-(s * t))) (nhdsWithin 0 (Ioi 0)) (nhds (cexp (-(s * ((0:ℝ):ℂ))))) :=
      ((Continuous.tendsto (by fun_prop) 0)).mono_left nhdsWithin_le_nhds
    have h3 := h1.mul h2
    simp only [ofReal_zero, mul_zero, neg_zero, Complex.exp_zero, mul_one] at h3
    exact h3
  have h_infty : Filter.Tendsto (f * fun t : ℝ => cexp (-(s * t))) Filter.atTop (nhds 0) := by
    have hlim : Filter.Tendsto (fun t : ℝ => M * Real.exp ((a - s.re) * t)) Filter.atTop (nhds 0) := by
      have := Real.tendsto_exp_atBot.comp
        (Filter.tendsto_id.const_mul_atTop_of_neg (show a - s.re < 0 by linarith))
      simpa using this.const_mul M
    refine squeeze_zero_norm' ?_ hlim
    filter_upwards [Filter.eventually_ge_atTop (0:ℝ)] with t ht
    simp only [Pi.mul_apply]
    rw [norm_mul, Complex.norm_exp]
    have h1 : (-(s * (t : ℂ))).re = -(s.re * t) := by simp
    rw [h1]
    calc ‖f t‖ * Real.exp (-(s.re * t)) ≤ M * Real.exp (a * t) * Real.exp (-(s.re * t)) :=
          mul_le_mul_of_nonneg_right (hgrowth t ht) (Real.exp_pos _).le
      _ = M * Real.exp ((a - s.re) * t) := by rw [mul_assoc, ← Real.exp_add]; ring_nf
  have key := integral_Ioi_mul_deriv_eq_deriv_mul hderiv hv huv' hf' h_zero h_infty
  have e1 : ∫ x in Ioi (0:ℝ), f x * (-s * cexp (-(s * x))) = -s * laplace f s := by
    rw [laplace, ← integral_const_mul]; congr 1; funext x; ring
  rw [e1] at key
  unfold laplace at key ⊢
  linear_combination key

/-- The half plane of convergence: if a signal stays below `M e^(at)` from time zero on, its
transform integral converges absolutely at every `s` with `Re s > a`. -/
theorem laplace_integrable_of_exp_bound (f : ℝ → ℂ) (M a : ℝ) (s : ℂ)
    (hmeas : AEStronglyMeasurable f (volume.restrict (Ioi 0)))
    (hgrowth : ∀ t : ℝ, 0 ≤ t → ‖f t‖ ≤ M * Real.exp (a * t))
    (hs : a < s.re) :
    IntegrableOn (fun t : ℝ => f t * cexp (-(s * t))) (Ioi 0) := by
  exact laplace_integrable_aux f M a s hmeas hgrowth hs

/-- The card's four transform pairs: `1 ↦ 1/s` and `t ↦ 1/s²` for `Re s > 0`,
`e^(at) ↦ 1/(s − a)` for `Re s > a`, and `cos(bt) ↦ s/(s² + b²)` for `Re s > 0`. -/
theorem laplace_table :
    (∀ s : ℂ, 0 < s.re → laplace (fun _ => 1) s = 1 / s) ∧
    (∀ s : ℂ, 0 < s.re → laplace (fun t => (t : ℂ)) s = 1 / s ^ 2) ∧
    (∀ (a : ℝ) (s : ℂ), a < s.re → laplace (fun t => cexp (a * t)) s = 1 / (s - a)) ∧
    (∀ (b : ℝ) (s : ℂ), 0 < s.re →
      laplace (fun t => Complex.cos (b * t)) s = s / (s ^ 2 + (b : ℂ) ^ 2)) := by
  have hone : ∀ s : ℂ, 0 < s.re → laplace (fun _ => 1) s = 1 / s := by
    intro s hs
    have := laplace_cexp_aux 0 s (by simpa using hs)
    simpa using this
  refine ⟨hone, ?_, ?_, ?_⟩
  · intro s hs
    have hs0 : s ≠ 0 := by intro h0; rw [h0] at hs; simp at hs
    have hd := laplace_deriv_eq_mul_sub (fun t => (t : ℂ)) (fun _ => 1) (2 / s.re) (s.re / 2) s
      (by fun_prop)
      (fun t _ => by simpa using (hasDerivAt_id t).ofReal_comp)
      (by
        intro t ht
        rw [Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg ht]
        have h1 := Real.add_one_le_exp (s.re / 2 * t)
        calc t = 2 / s.re * (s.re / 2 * t) := by field_simp
          _ ≤ 2 / s.re * Real.exp (s.re / 2 * t) :=
            mul_le_mul_of_nonneg_left (by linarith) (by positivity))
      (by linarith)
      (by
        have := laplace_cexp_integrable 0 s (by simpa using hs)
        simpa using this)
    rw [hone s hs] at hd
    simp only [ofReal_zero, sub_zero] at hd
    rw [eq_div_iff (pow_ne_zero 2 hs0)]
    calc laplace (fun t => (t : ℂ)) s * s ^ 2 = s * (s * laplace (fun t => (t : ℂ)) s) := by ring
      _ = s * (1 / s) := by rw [← hd]
      _ = 1 := by field_simp
  · intro a s hs
    exact laplace_cexp_aux a s (by simpa using hs)
  · intro b s hs
    have h1 : (b * I - s) ≠ 0 := by
      intro h0; have := congrArg Complex.re h0; simp at this; linarith
    have h2 : (-(b * I) - s) ≠ 0 := by
      intro h0; have := congrArg Complex.re h0; simp at this; linarith
    have hfun : (fun t : ℝ => Complex.cos (b * t) * cexp (-(s * t))) =
        fun t : ℝ => (1/2 : ℂ) * (cexp ((b * I) * t) * cexp (-(s * t))) +
          (1/2 : ℂ) * (cexp (-(b * I) * t) * cexp (-(s * t))) := by
      funext t
      rw [Complex.cos]
      ring_nf
    unfold laplace
    rw [hfun, integral_add, integral_const_mul, integral_const_mul]
    · have e1 := laplace_cexp_aux (b * I) s (by simpa using hs)
      have e2 := laplace_cexp_aux (-(b * I)) s (by simpa using hs)
      unfold laplace at e1 e2
      rw [e1, e2]
      have h3 : s ^ 2 + (b : ℂ) ^ 2 ≠ 0 := by
        have : s ^ 2 + (b : ℂ) ^ 2 = (s - b * I) * (s - -(b * I)) := by
          ring_nf; rw [I_sq]; ring
        rw [this]
        refine mul_ne_zero ?_ ?_
        · intro h0; apply h1; linear_combination -h0
        · intro h0; apply h2; linear_combination -h0
      have h1' : s - b * I ≠ 0 := by intro h0; apply h1; linear_combination -h0
      have h2' : s - -(b * I) ≠ 0 := by intro h0; apply h2; linear_combination -h0
      field_simp
      ring_nf
      rw [I_sq]
      ring
    · exact (laplace_cexp_integrable (b * I) s (by simpa using hs)).const_mul _
    · exact (laplace_cexp_integrable (-(b * I)) s (by simpa using hs)).const_mul _

-- Worked numbers, exact.
-- The table at s = 3: 1/3, 1/9, 1/(3 + 2) = 1/5 for a = −2, 3/(9 + 1) = 3/10 for b = 1.
example : (1 : ℚ) / 3 = 1 / 3 ∧ (1 : ℚ) / 3 ^ 2 = 1 / 9 ∧ (1 : ℚ) / (3 - (-2)) = 1 / 5 ∧
    (3 : ℚ) / (3 ^ 2 + 1 ^ 2) = 3 / 10 := by norm_num
-- The table at s = 1 + i: 0.5 − 0.5i, −0.5i, 0.3 − 0.1i (a = −2), 0.6 − 0.2i (b = 1).
example : 1 / (1 + I) = 1 / 2 - I / 2 := by
  have : (1 + I) ≠ 0 := by intro h; have := congrArg Complex.re h; simp at this
  rw [div_eq_iff this]; linear_combination (1 / 2) * I_sq
example : 1 / (1 + I) ^ 2 = -(I / 2) := by
  have : (1 + I) ≠ 0 := by intro h; have := congrArg Complex.re h; simp at this
  rw [div_eq_iff (pow_ne_zero 2 this)]; linear_combination (1 + I / 2) * I_sq
example : 1 / (1 + I - (-2)) = 3 / 10 - I / 10 := by
  have : (1 + I - (-2)) ≠ 0 := by intro h; have := congrArg Complex.re h; norm_num at this
  rw [div_eq_iff this]; linear_combination (1 / 10) * I_sq
example : (1 + I) / ((1 + I) ^ 2 + 1 ^ 2) = 3 / 5 - I / 5 := by
  have e : ((1:ℂ) + I) ^ 2 + 1 ^ 2 = 1 + 2 * I := by linear_combination I_sq
  have : (1 + 2 * I) ≠ 0 := by intro h; have := congrArg Complex.im h; norm_num at this
  rw [e, div_eq_iff this]; linear_combination (2 / 5) * I_sq
-- The car: s V − 5 = −2V solves to V = 5/(s + 2) wherever s ≠ −2.
example (s V : ℂ) (hs : s ≠ -2) (h : s * V - 5 = -2 * V) : V = 5 / (s + 2) := by
  have : s + 2 ≠ 0 := by intro h0; apply hs; linear_combination h0
  field_simp; linear_combination h
-- V(3) = 5/5 = 1, and the distance V(0) = 5/2 = 2.5 metres.
example : (5 : ℚ) / (3 + 2) = 1 ∧ (5 : ℚ) / (0 + 2) = 5 / 2 := by norm_num
-- The derivative rule on the car at s = 3: 3 × 1 − 5 = −2; without f(0) it gives 3.
example : (3 : ℤ) * 1 - 5 = -2 ∧ (3 : ℤ) * 1 = 3 := by norm_num
-- The rule on the wave at s = 1 + i: (1 + i)(0.6 − 0.2i) − 1 = −0.2 + 0.4i.
example : (1 + I) * (3 / 5 - I / 5) - 1 = -(1 / 5) + 2 / 5 * I := by
  linear_combination (-1 / 5) * I_sq
-- The usual mistake: 1/(s − 1) at s = 1/2 gives −2 for a positive signal.
example : (1 : ℚ) / (1 / 2 - 1) = -2 := by norm_num

#print axioms laplace_deriv_eq_mul_sub
#print axioms laplace_integrable_of_exp_bound
#print axioms laplace_table
