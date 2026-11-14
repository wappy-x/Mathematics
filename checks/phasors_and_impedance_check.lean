-- Phasors: a sine current solves the series resistor-coil circuit exactly when its phasor times the impedance R + jωL equals the supply's phasor, differentiating a wave multiplies its phasor by jω, and Kirchhoff sums of waves vanish only when the phasors sum to zero.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

open Complex

/-- Helper: a wave `t ↦ Re(W e^{jωt})` with `ω ≠ 0` vanishes at every instant exactly when
its phasor `W` is zero. -/
theorem phasor_wave_zero_iff (ω : ℝ) (hω : ω ≠ 0) (W : ℂ) :
    (∀ t : ℝ, (W * exp (ω * t * I)).re = 0) ↔ W = 0 := by
  constructor
  · intro h
    have h0 := h 0
    have h1 := h (Real.pi / 2 / ω)
    simp at h0
    have e : ((ω : ℂ) * ((Real.pi / 2 / ω : ℝ) : ℂ) * I) = ((Real.pi / 2 : ℝ) : ℂ) * I := by
      have hω' : (ω : ℂ) ≠ 0 := ofReal_ne_zero.mpr hω
      push_cast
      field_simp
    rw [e, exp_mul_I] at h1
    rw [← ofReal_cos, ← ofReal_sin, Real.cos_pi_div_two, Real.sin_pi_div_two] at h1
    simp at h1
    exact Complex.ext h0 h1
  · rintro rfl t
    simp

/-- Helper: the derivative of the wave `t ↦ Re(X e^{jωt})` is `Re((jω X) e^{jωt})`. -/
theorem phasor_hasDerivAt_aux (ω : ℝ) (X : ℂ) (t : ℝ) :
    HasDerivAt (fun s : ℝ => (X * exp (ω * s * I)).re)
      ((I * ω * X) * exp (ω * t * I)).re t := by
  have h1 : HasDerivAt (fun s : ℝ => (s : ℂ)) 1 t := by
    simpa using (hasDerivAt_id t).ofReal_comp
  have h2 : HasDerivAt (fun s : ℝ => X * exp (ω * s * I))
      (X * (exp (ω * t * I) * (ω * 1 * I))) t :=
    (((h1.const_mul (ω : ℂ)).mul_const I).cexp).const_mul X
  have h3 := Complex.reCLM.hasFDerivAt.comp_hasDerivAt t h2
  convert h3 using 1
  · funext s
    rfl
  · rw [Complex.reCLM_apply]
    congr 1
    ring

/-- Impedance replaces resistance. In a series circuit of a resistor `R` and a coil `L`, driven
by the steady sine wave `√2·Re(V e^{jωt})` of angular frequency `ω ≠ 0`, a sine current
`i(t) = √2·Re(Ip e^{jωt})` at the same frequency obeys Kirchhoff's voltage law
`L di/dt + R i = v(t)` at every instant exactly when `V = (R + jωL) · Ip`, that is `I = V / Z`
with `Z = R + jωL`. -/
theorem series_rl_steady_state_iff_impedance (R L ω : ℝ) (hω : ω ≠ 0) (V Ip : ℂ) :
    (∀ t : ℝ,
      L * deriv (fun s : ℝ => ((Real.sqrt 2 : ℂ) * Ip * exp (ω * s * I)).re) t
        + R * ((Real.sqrt 2 : ℂ) * Ip * exp (ω * t * I)).re
        = ((Real.sqrt 2 : ℂ) * V * exp (ω * t * I)).re)
    ↔ V = ((R : ℂ) + I * ω * L) * Ip := by
  have key : ∀ t : ℝ,
      (L * deriv (fun s : ℝ => ((Real.sqrt 2 : ℂ) * Ip * exp (ω * s * I)).re) t
        + R * ((Real.sqrt 2 : ℂ) * Ip * exp (ω * t * I)).re
        = ((Real.sqrt 2 : ℂ) * V * exp (ω * t * I)).re)
      ↔ (((Real.sqrt 2 : ℂ) * (((R : ℂ) + I * ω * L) * Ip - V)) * exp (ω * t * I)).re = 0 := by
    intro t
    rw [(phasor_hasDerivAt_aux ω ((Real.sqrt 2 : ℂ) * Ip) t).deriv]
    have e : ((Real.sqrt 2 : ℂ) * (((R : ℂ) + I * ω * L) * Ip - V)) * exp (ω * t * I)
        = (L : ℂ) * ((I * ω * ((Real.sqrt 2 : ℂ) * Ip)) * exp (ω * t * I))
          + (R : ℂ) * ((Real.sqrt 2 : ℂ) * Ip * exp (ω * t * I))
          - (Real.sqrt 2 : ℂ) * V * exp (ω * t * I) := by ring
    rw [e, sub_re, add_re, re_ofReal_mul, re_ofReal_mul, sub_eq_zero]
  simp_rw [key, phasor_wave_zero_iff ω hω]
  have h2 : (Real.sqrt 2 : ℂ) ≠ 0 := by
    rw [ofReal_ne_zero]
    positivity
  rw [mul_eq_zero, or_iff_right h2, sub_eq_zero, eq_comm]

/-- Differentiating becomes multiplying by jω: the wave `t ↦ Re(X e^{jωt})` has, at every
instant, derivative `Re((jω X) e^{jωt})`, so the phasor of the derivative is `jω X`. -/
theorem phasor_deriv_eq_mul_I_omega (ω : ℝ) (X : ℂ) (t : ℝ) :
    HasDerivAt (fun s : ℝ => (X * exp (ω * s * I)).re)
      ((I * ω * X) * exp (ω * t * I)).re t := by
  exact phasor_hasDerivAt_aux ω X t

/-- Kirchhoff's laws carry over: if waves of one angular frequency `ω ≠ 0` with phasors `V k`
add to zero at every instant, then the phasors themselves add to zero. -/
theorem kirchhoff_for_phasors {ι : Type*} (s : Finset ι) (V : ι → ℂ) (ω : ℝ) (hω : ω ≠ 0)
    (h : ∀ t : ℝ, (∑ k ∈ s, V k * exp (ω * t * I)).re = 0) :
    ∑ k ∈ s, V k = 0 := by
  rw [← phasor_wave_zero_iff ω hω]
  intro t
  rw [Finset.sum_mul]
  exact h t

-- The bench: Z = 40 + j30 ohms has length 50 ohms.
example : ‖(40 : ℂ) + 30 * I‖ = 50 := by
  rw [Complex.norm_def, Complex.normSq_apply]
  simp
  rw [show (40 * 40 + 30 * 30 : ℝ) = 50 ^ 2 by norm_num]
  rw [Real.sqrt_sq (by norm_num)]

-- The current: 230 / (40 + j30) = 3.68 - j2.76 A, written as fractions.
example : (230 : ℂ) / (40 + 30 * I) = 92 / 25 - 69 / 25 * I := by
  have : (40 + 30 * I : ℂ) ≠ 0 := by
    intro h
    have := congrArg Complex.re h
    simp at this
  rw [div_eq_iff this]
  ring_nf
  rw [I_sq]
  ring

-- Its size: 230 / 50 = 4.6 A rms.
example : (230 : ℚ) / 50 = 23 / 5 := by norm_num

-- The resistor's and coil's voltages, 184 V and 138 V, add as arrows to the 230 V supply.
example : (40 : ℂ) * (92 / 25 - 69 / 25 * I) + 30 * I * (92 / 25 - 69 / 25 * I) = 230 := by
  ring_nf
  rw [I_sq]
  ring

-- The meters' right triangle: 184² + 138² = 230², and 40² + 30² = 50².
example : (184 : ℕ) ^ 2 + 138 ^ 2 = 230 ^ 2 := by norm_num
example : (40 : ℕ) ^ 2 + 30 ^ 2 = 50 ^ 2 := by norm_num

-- Ignoring the coil: 230 / 40 = 5.75 A, over the fuse's 5 A rating.
example : (230 : ℚ) / 40 = 23 / 4 ∧ (5 : ℚ) < 230 / 40 := by norm_num

-- The meters added: 184 + 138 = 322 V, not 230 V.
example : (184 : ℕ) + 138 = 322 := by norm_num

#print axioms phasor_wave_zero_iff
#print axioms phasor_hasDerivAt_aux
#print axioms series_rl_steady_state_iff_impedance
#print axioms phasor_deriv_eq_mul_I_omega
#print axioms kirchhoff_for_phasors
