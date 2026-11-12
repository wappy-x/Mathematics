-- Resonance: started from rest, y'' + ω₀² y = F cos(ω t) has exactly one solution, F t sin(ω₀ t)/(2ω₀) when ω = ω₀ and 2F/(ω₀² - ω²) sin((ω₀ - ω)t/2) sin((ω₀ + ω)t/2) when ω ≠ ω₀, and with damping b > 0 a steady swing of size F/√((ω₀² - ω²)² + b²ω²) answers the push.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Real

lemma rb_cos_hasDerivAt (ω t : ℝ) :
    HasDerivAt (fun s => Real.cos (ω * s)) (-(ω * Real.sin (ω * t))) t := by
  have := ((hasDerivAt_id' t).const_mul ω).cos
  convert this using 1; simp; ring

lemma rb_sin_hasDerivAt (ω t : ℝ) :
    HasDerivAt (fun s => Real.sin (ω * s)) (ω * Real.cos (ω * t)) t := by
  have := ((hasDerivAt_id' t).const_mul ω).sin
  convert this using 1; simp; ring

lemma rb_energy_zero (k : ℝ) (hk : k ≠ 0) (z z' : ℝ → ℝ) (hz : ∀ t, HasDerivAt z (z' t) t)
    (hz' : ∀ t, HasDerivAt z' (-(k ^ 2) * z t) t) (h0 : z 0 = 0) (h0' : z' 0 = 0) (t : ℝ) :
    z t = 0 := by
  let E : ℝ → ℝ := fun s => z' s ^ 2 + k ^ 2 * z s ^ 2
  have hEd : ∀ s, HasDerivAt E 0 s := by
    intro s
    have := ((hz' s).pow 2).add (((hz s).pow 2).const_mul (k ^ 2))
    convert this using 1
    simp; ring
  have hc : E t = E 0 :=
    is_const_of_deriv_eq_zero (fun s => (hEd s).differentiableAt) (fun s => (hEd s).deriv) t 0
  have hE0 : E 0 = 0 := by simp [E, h0, h0']
  have hk2 : 0 < k ^ 2 := by positivity
  have h1 : z' t ^ 2 + k ^ 2 * z t ^ 2 = 0 := by rw [← hE0]; exact hc
  have h2 : k ^ 2 * z t ^ 2 = 0 := by
    nlinarith [sq_nonneg (z' t), mul_nonneg hk2.le (sq_nonneg (z t))]
  have h3 : z t ^ 2 = 0 := by
    rcases mul_eq_zero.mp h2 with h | h
    · exact absurd h hk2.ne'
    · exact h
  exact pow_eq_zero_iff (by norm_num) |>.mp h3

lemma rb_res_d1 (F ω₀ s : ℝ) :
    HasDerivAt (fun t => F / (2 * ω₀) * t * Real.sin (ω₀ * t))
      (F / (2 * ω₀) * (Real.sin (ω₀ * s) + ω₀ * s * Real.cos (ω₀ * s))) s := by
  have := ((hasDerivAt_id' s).const_mul (F / (2 * ω₀))).mul (rb_sin_hasDerivAt ω₀ s)
  exact this.congr_deriv (by ring)

lemma rb_res_d2 (F ω₀ s : ℝ) (hω₀ : ω₀ ≠ 0) :
    HasDerivAt (fun t => F / (2 * ω₀) * (Real.sin (ω₀ * t) + ω₀ * t * Real.cos (ω₀ * t)))
      (F * Real.cos (ω₀ * s) - ω₀ ^ 2 * (F / (2 * ω₀) * s * Real.sin (ω₀ * s))) s := by
  have := ((rb_sin_hasDerivAt ω₀ s).add
    (((hasDerivAt_id' s).const_mul ω₀).mul (rb_cos_hasDerivAt ω₀ s))).const_mul (F / (2 * ω₀))
  refine this.congr_deriv ?_
  field_simp; ring

lemma rb_beat_d1 (F ω₀ ω s : ℝ) :
    HasDerivAt (fun t => F / (ω₀ ^ 2 - ω ^ 2) * (Real.cos (ω * t) - Real.cos (ω₀ * t)))
      (F / (ω₀ ^ 2 - ω ^ 2) * (-(ω * Real.sin (ω * s)) + ω₀ * Real.sin (ω₀ * s))) s := by
  have := ((rb_cos_hasDerivAt ω s).sub (rb_cos_hasDerivAt ω₀ s)).const_mul (F / (ω₀ ^ 2 - ω ^ 2))
  convert this using 1; ring

lemma rb_beat_d2 (F ω₀ ω s : ℝ) (hD : ω₀ ^ 2 - ω ^ 2 ≠ 0) :
    HasDerivAt (fun t => F / (ω₀ ^ 2 - ω ^ 2) * (-(ω * Real.sin (ω * t)) + ω₀ * Real.sin (ω₀ * t)))
      (F * Real.cos (ω * s) - ω₀ ^ 2 *
        (F / (ω₀ ^ 2 - ω ^ 2) * (Real.cos (ω * s) - Real.cos (ω₀ * s)))) s := by
  have := ((((rb_sin_hasDerivAt ω s).const_mul ω).neg).add
    ((rb_sin_hasDerivAt ω₀ s).const_mul ω₀)).const_mul (F / (ω₀ ^ 2 - ω ^ 2))
  convert this using 1
  field_simp; ring

#print axioms rb_cos_hasDerivAt
#print axioms rb_sin_hasDerivAt
#print axioms rb_energy_zero
#print axioms rb_res_d1
#print axioms rb_res_d2
#print axioms rb_beat_d1
#print axioms rb_beat_d2

/-- Resonance: an undamped spring with natural angular frequency ω₀ > 0, started at rest
(y(0) = 0, y'(0) = 0) and pushed at its own frequency, y'' + ω₀² y = F cos(ω₀ t), has exactly
one solution, y(t) = F/(2ω₀) · t · sin(ω₀ t): the swing grows in proportion to time. -/
theorem resonance_swing_grows_linearly (F ω₀ : ℝ) (hω₀ : 0 < ω₀) (y : ℝ → ℝ) :
    (Differentiable ℝ y ∧ Differentiable ℝ (deriv y) ∧
      (∀ t, deriv (deriv y) t + ω₀ ^ 2 * y t = F * Real.cos (ω₀ * t)) ∧
      y 0 = 0 ∧ deriv y 0 = 0) ↔
    y = fun t => F / (2 * ω₀) * t * Real.sin (ω₀ * t) := by
  have h1 := rb_res_d1 F ω₀
  have h2 := fun s => rb_res_d2 F ω₀ s hω₀.ne'
  constructor
  · rintro ⟨hd, hd2, hode, h0, h0'⟩
    funext t
    have key := rb_energy_zero ω₀ hω₀.ne'
      (fun s => y s - F / (2 * ω₀) * s * Real.sin (ω₀ * s))
      (fun s => deriv y s - F / (2 * ω₀) * (Real.sin (ω₀ * s) + ω₀ * s * Real.cos (ω₀ * s)))
      (fun s => (hd s).hasDerivAt.sub (h1 s))
      (fun s => ((hd2 s).hasDerivAt.sub (h2 s)).congr_deriv (by linarith [hode s]))
      (by simp [h0]) (by simp [h0']) t
    linarith
  · rintro rfl
    have e1 : deriv (fun t => F / (2 * ω₀) * t * Real.sin (ω₀ * t)) =
        fun s => F / (2 * ω₀) * (Real.sin (ω₀ * s) + ω₀ * s * Real.cos (ω₀ * s)) :=
      funext fun s => (h1 s).deriv
    have e2 : deriv (fun s => F / (2 * ω₀) * (Real.sin (ω₀ * s) + ω₀ * s * Real.cos (ω₀ * s))) =
        fun s => F * Real.cos (ω₀ * s) - ω₀ ^ 2 * (F / (2 * ω₀) * s * Real.sin (ω₀ * s)) :=
      funext fun s => (h2 s).deriv
    refine ⟨fun s => (h1 s).differentiableAt, ?_, ?_, by simp, ?_⟩
    · rw [e1]; exact fun s => (h2 s).differentiableAt
    · intro t; rw [e1, e2]; ring
    · rw [e1]; simp

/-- Beats: pushed at a nearby angular frequency ω ≠ ω₀ (both positive) from rest, the spring's
only motion is y(t) = F/(ω₀² - ω²)(cos ωt - cos ω₀t)
= 2F/(ω₀² - ω²) · sin((ω₀ - ω)t/2) · sin((ω₀ + ω)t/2):
a fast swing at the average frequency inside a slow envelope at half the difference. -/
theorem beats_solution (F ω₀ ω : ℝ) (hω₀ : 0 < ω₀) (hω : 0 < ω) (hne : ω ≠ ω₀)
    (y : ℝ → ℝ) :
    (Differentiable ℝ y ∧ Differentiable ℝ (deriv y) ∧
      (∀ t, deriv (deriv y) t + ω₀ ^ 2 * y t = F * Real.cos (ω * t)) ∧
      y 0 = 0 ∧ deriv y 0 = 0) ↔
    ((∀ t, y t = F / (ω₀ ^ 2 - ω ^ 2) * (Real.cos (ω * t) - Real.cos (ω₀ * t))) ∧
      ∀ t, y t = 2 * F / (ω₀ ^ 2 - ω ^ 2) *
        Real.sin ((ω₀ - ω) * t / 2) * Real.sin ((ω₀ + ω) * t / 2)) := by
  have hD : ω₀ ^ 2 - ω ^ 2 ≠ 0 := by
    intro h
    have : (ω₀ - ω) * (ω₀ + ω) = 0 := by linarith [h]
    rcases mul_eq_zero.mp this with h' | h'
    · exact hne (by linarith)
    · linarith
  have h1 := rb_beat_d1 F ω₀ ω
  have h2 := fun s => rb_beat_d2 F ω₀ ω s hD
  have prod : ∀ t, F / (ω₀ ^ 2 - ω ^ 2) * (Real.cos (ω * t) - Real.cos (ω₀ * t)) =
      2 * F / (ω₀ ^ 2 - ω ^ 2) *
        Real.sin ((ω₀ - ω) * t / 2) * Real.sin ((ω₀ + ω) * t / 2) := by
    intro t
    have ea : ω * t = (ω₀ + ω) * t / 2 - (ω₀ - ω) * t / 2 := by ring
    have eb : ω₀ * t = (ω₀ - ω) * t / 2 + (ω₀ + ω) * t / 2 := by ring
    rw [ea, eb, Real.cos_sub, Real.cos_add]
    ring
  constructor
  · rintro ⟨hd, hd2, hode, h0, h0'⟩
    have hy : ∀ t, y t = F / (ω₀ ^ 2 - ω ^ 2) * (Real.cos (ω * t) - Real.cos (ω₀ * t)) := by
      intro t
      have key := rb_energy_zero ω₀ hω₀.ne'
        (fun s => y s - F / (ω₀ ^ 2 - ω ^ 2) * (Real.cos (ω * s) - Real.cos (ω₀ * s)))
        (fun s => deriv y s -
          F / (ω₀ ^ 2 - ω ^ 2) * (-(ω * Real.sin (ω * s)) + ω₀ * Real.sin (ω₀ * s)))
        (fun s => (hd s).hasDerivAt.sub (h1 s))
        (fun s => ((hd2 s).hasDerivAt.sub (h2 s)).congr_deriv (by linarith [hode s]))
        (by simp [h0]) (by simp [h0']) t
      linarith
    exact ⟨hy, fun t => (hy t).trans (prod t)⟩
  · rintro ⟨hy, -⟩
    have hyf : y = fun t => F / (ω₀ ^ 2 - ω ^ 2) * (Real.cos (ω * t) - Real.cos (ω₀ * t)) :=
      funext hy
    subst hyf
    have e1 := funext fun s => (h1 s).deriv
    have e2 := funext fun s => (h2 s).deriv
    refine ⟨fun s => (h1 s).differentiableAt, ?_, ?_, by simp, ?_⟩
    · rw [e1]; exact fun s => (h2 s).differentiableAt
    · intro t; rw [e1, e2]; ring
    · rw [e1]; simp

/-- Damping caps the growth: with drag b > 0, the damped equation
y'' + b y' + ω₀² y = F cos(ωt) is answered by a steady swing P cos ωt + Q sin ωt whose size
√(P² + Q²) is A(ω) = F/√((ω₀² - ω²)² + b²ω²) (written with |F| so the sign of the push
does not matter). -/
theorem damped_steady_amplitude (F ω₀ ω b : ℝ) (hω₀ : 0 < ω₀) (hω : 0 < ω) (hb : 0 < b) :
    ∃ P Q : ℝ,
      (∀ t, deriv (deriv fun s => P * Real.cos (ω * s) + Q * Real.sin (ω * s)) t
          + b * deriv (fun s => P * Real.cos (ω * s) + Q * Real.sin (ω * s)) t
          + ω₀ ^ 2 * (P * Real.cos (ω * t) + Q * Real.sin (ω * t)) = F * Real.cos (ω * t)) ∧
      Real.sqrt (P ^ 2 + Q ^ 2) = |F| / Real.sqrt ((ω₀ ^ 2 - ω ^ 2) ^ 2 + b ^ 2 * ω ^ 2) := by
  set D := ω₀ ^ 2 - ω ^ 2 with hDdef
  set R := D ^ 2 + b ^ 2 * ω ^ 2 with hRdef
  have hR : 0 < R := by positivity
  refine ⟨F * D / R, F * (b * ω) / R, ?_, ?_⟩
  · have d1 : ∀ P Q : ℝ, ∀ s, HasDerivAt (fun s => P * Real.cos (ω * s) + Q * Real.sin (ω * s))
        (-(ω * (P * Real.sin (ω * s))) + ω * (Q * Real.cos (ω * s))) s := by
      intro P Q s
      have := ((rb_cos_hasDerivAt ω s).const_mul P).add ((rb_sin_hasDerivAt ω s).const_mul Q)
      exact this.congr_deriv (by ring)
    have d2 : ∀ P Q : ℝ, ∀ s, HasDerivAt
        (fun s => -(ω * (P * Real.sin (ω * s))) + ω * (Q * Real.cos (ω * s)))
        (-(ω ^ 2) * (P * Real.cos (ω * s) + Q * Real.sin (ω * s))) s := by
      intro P Q s
      have := (((rb_sin_hasDerivAt ω s).const_mul P).const_mul ω).neg.add
        (((rb_cos_hasDerivAt ω s).const_mul Q).const_mul ω)
      exact this.congr_deriv (by ring)
    intro t
    rw [funext (fun s => (d1 (F * D / R) (F * (b * ω) / R) s).deriv),
      (d2 (F * D / R) (F * (b * ω) / R) t).deriv]
    field_simp
    rw [hRdef]
    ring
  · have : (F * D / R) ^ 2 + (F * (b * ω) / R) ^ 2 = F ^ 2 / R := by
      field_simp; rw [hRdef]
    rw [this, Real.sqrt_div' _ hR.le, Real.sqrt_sq_eq_abs]

-- The gap in squares at 0.9 Hz: (2π)^2 - (2π · 9/10)^2 = (19/25) π^2 (about 7.5009 per s^2).
example : (2 * π) ^ 2 - (2 * π * (9 / 10)) ^ 2 = 19 / 25 * π ^ 2 := by ring
-- Beat period 1/(1 - 9/10) = 10 s; the mistaken reading 2/(1 - 9/10) gives 20 s.
example : (1 : ℚ) / (1 - 9 / 10) = 10 := by norm_num
example : (2 : ℚ) / (1 - 9 / 10) = 20 := by norm_num
-- The beat peak is twice the steady part: 2 · F/(ω₀² - ω²).
example (F D : ℝ) : 2 * F / D = 2 * (F / D) := by ring
-- At resonance with damping ratio ζ = 1/100, so b = 2ζω₀, the peak F/(bω₀) over the static sag
-- F/ω₀² is 1/(2ζ) = 50.
example : (1 : ℚ) / (2 * (1 / 100)) = 50 := by norm_num
example (F ω₀ : ℝ) (hF : F ≠ 0) (hω₀ : ω₀ ≠ 0) :
    (F / ((2 * (1 / 100) * ω₀) * ω₀)) / (F / ω₀ ^ 2) = 50 := by
  field_simp; ring

#print axioms resonance_swing_grows_linearly
#print axioms beats_solution
#print axioms damped_steady_amplitude
