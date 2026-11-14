-- Damping ratio and natural frequency: for m x'' + c x' + k x = F started at rest with damping ratio ζ = c/(2√(km)) below 1, the body's first peak comes at π/ω_d and overshoots the final value F/k by exactly e^(−πζ/√(1 − ζ²)), the most it ever reaches; the poles sit at radius ω_n = √(k/m) with −Re p/|p| = ζ; and the frequency response at ω_n is 1/(2ζ j).
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open Real

namespace SecondOrder

/-- The natural frequency ω_n = √(k/m), in radians per second. -/
noncomputable def naturalFreq (m k : ℝ) : ℝ := Real.sqrt (k / m)

/-- The damping ratio ζ = c/(2√(km)): the damper coefficient over critical damping. -/
noncomputable def dampingRatio (m c k : ℝ) : ℝ := c / (2 * Real.sqrt (k * m))

/-- The damped (ringing) frequency ω_d = ω_n √(1 − ζ²). -/
noncomputable def dampedFreq (m c k : ℝ) : ℝ :=
  naturalFreq m k * Real.sqrt (1 - dampingRatio m c k ^ 2)

theorem naturalFreq_pos (m k : ℝ) (hm : 0 < m) (hk : 0 < k) : 0 < naturalFreq m k :=
  Real.sqrt_pos.2 (div_pos hk hm)

theorem naturalFreq_sq (m k : ℝ) (hm : 0 < m) (hk : 0 < k) : naturalFreq m k ^ 2 = k / m :=
  Real.sq_sqrt (div_pos hk hm).le

theorem damping_mul_naturalFreq (m c k : ℝ) (hm : 0 < m) (hk : 0 < k) :
    dampingRatio m c k * naturalFreq m k = c / (2 * m) := by
  unfold dampingRatio naturalFreq
  rw [Real.sqrt_mul hk.le, Real.sqrt_div hk.le]
  have h1 : 0 < Real.sqrt k := Real.sqrt_pos.2 hk
  have h2 : 0 < Real.sqrt m := Real.sqrt_pos.2 hm
  have h3 : Real.sqrt m ^ 2 = m := Real.sq_sqrt hm.le
  field_simp
  rw [h3]

theorem dampingRatio_nonneg (m c k : ℝ) (hc : 0 ≤ c) : 0 ≤ dampingRatio m c k := by
  unfold dampingRatio
  positivity

theorem one_sub_damping_sq_pos (m c k : ℝ) (hc : 0 ≤ c) (hζ : dampingRatio m c k < 1) :
    0 < 1 - dampingRatio m c k ^ 2 := by
  have := dampingRatio_nonneg m c k hc
  nlinarith

theorem dampedFreq_pos (m c k : ℝ) (hm : 0 < m) (hk : 0 < k) (hc : 0 ≤ c)
    (hζ : dampingRatio m c k < 1) : 0 < dampedFreq m c k :=
  mul_pos (naturalFreq_pos m k hm hk) (Real.sqrt_pos.2 (one_sub_damping_sq_pos m c k hc hζ))

theorem dampedFreq_sq (m c k : ℝ) (hc : 0 ≤ c)
    (hζ : dampingRatio m c k < 1) :
    dampedFreq m c k ^ 2 = naturalFreq m k ^ 2 * (1 - dampingRatio m c k ^ 2) := by
  unfold dampedFreq
  rw [mul_pow, Real.sq_sqrt (one_sub_damping_sq_pos m c k hc hζ).le]

theorem le_of_sq_le_sq_of_nonneg (a b : ℝ) (h : a ^ 2 ≤ b ^ 2) (hb : 0 ≤ b) : a ≤ b := by
  nlinarith [sq_nonneg (a - b), sq_nonneg (a + b)]

theorem energy_antitone (m c k : ℝ) (hc : 0 ≤ c) (y y' y'' : ℝ → ℝ)
    (hy : ∀ t, HasDerivAt y (y' t) t) (hy' : ∀ t, HasDerivAt y' (y'' t) t)
    (h : ∀ t, m * y'' t + c * y' t + k * y t = 0) :
    Antitone (fun t => m * y' t ^ 2 + k * y t ^ 2) := by
  have hE : ∀ t, HasDerivAt (fun t => m * y' t ^ 2 + k * y t ^ 2)
      (m * (2 * y' t * y'' t) + k * (2 * y t * y' t)) t := by
    intro t
    have h1 := ((hy' t).pow 2).const_mul m
    have h2 := ((hy t).pow 2).const_mul k
    convert h1.add h2 using 1
    simp
  apply antitone_of_deriv_nonpos (fun t => (hE t).differentiableAt)
  intro t
  rw [(hE t).deriv]
  have e : m * (2 * y' t * y'' t) + k * (2 * y t * y' t) = -(2 * c * y' t ^ 2) := by
    linear_combination (2 * y' t) * h t
  rw [e]
  have := mul_nonneg hc (sq_nonneg (y' t))
  linarith

theorem explicit_solution (m c k F σ ω : ℝ) (hm : 0 < m) (hω : 0 < ω)
    (hc : c = 2 * m * σ) (hk : k = m * (σ ^ 2 + ω ^ 2)) :
    (∀ t, HasDerivAt
        (fun t => F / k * (1 - Real.exp (-σ * t) * (Real.cos (ω * t) + σ / ω * Real.sin (ω * t))))
        (F / k * ((σ ^ 2 + ω ^ 2) / ω) * Real.exp (-σ * t) * Real.sin (ω * t)) t) ∧
    (∀ t, HasDerivAt
        (fun t => F / k * ((σ ^ 2 + ω ^ 2) / ω) * Real.exp (-σ * t) * Real.sin (ω * t))
        (F / k * ((σ ^ 2 + ω ^ 2) / ω) * Real.exp (-σ * t) *
          (ω * Real.cos (ω * t) - σ * Real.sin (ω * t))) t) ∧
    (∀ t, m * (F / k * ((σ ^ 2 + ω ^ 2) / ω) * Real.exp (-σ * t) *
          (ω * Real.cos (ω * t) - σ * Real.sin (ω * t)))
        + c * (F / k * ((σ ^ 2 + ω ^ 2) / ω) * Real.exp (-σ * t) * Real.sin (ω * t))
        + k * (F / k * (1 - Real.exp (-σ * t) * (Real.cos (ω * t) + σ / ω * Real.sin (ω * t))))
        = F) := by
  have hk0 : k ≠ 0 := by rw [hk]; positivity
  have hω0 : ω ≠ 0 := hω.ne'
  have he : ∀ t, HasDerivAt (fun t => Real.exp (-σ * t)) (Real.exp (-σ * t) * (-σ * 1)) t :=
    fun t => ((hasDerivAt_id' t).const_mul (-σ)).exp
  have hcs : ∀ t, HasDerivAt (fun t => Real.cos (ω * t)) (-Real.sin (ω * t) * (ω * 1)) t :=
    fun t => ((hasDerivAt_id' t).const_mul ω).cos
  have hsn : ∀ t, HasDerivAt (fun t => Real.sin (ω * t)) (Real.cos (ω * t) * (ω * 1)) t :=
    fun t => ((hasDerivAt_id' t).const_mul ω).sin
  refine ⟨fun t => ?_, fun t => ?_, fun t => ?_⟩
  · convert (((hasDerivAt_const t (1 : ℝ)).sub
      ((he t).mul ((hcs t).add ((hsn t).const_mul (σ / ω))))).const_mul (F / k)) using 1
    simp only [Pi.add_apply]
    field_simp
    ring
  · convert (((he t).const_mul (F / k * ((σ ^ 2 + ω ^ 2) / ω))).mul (hsn t)) using 1
    ring
  · subst hc hk
    have : σ ^ 2 + ω ^ 2 ≠ 0 := by positivity
    field_simp
    ring

#print axioms naturalFreq_pos
#print axioms naturalFreq_sq
#print axioms damping_mul_naturalFreq
#print axioms dampingRatio_nonneg
#print axioms one_sub_damping_sq_pos
#print axioms dampedFreq_pos
#print axioms dampedFreq_sq
#print axioms le_of_sq_le_sq_of_nonneg
#print axioms energy_antitone
#print axioms explicit_solution

/-- The overshoot depends on ζ alone. A mass m > 0 on a linear spring k > 0 and a linear damper
c ≥ 0, with damping ratio ζ = c/(2√(km)) below 1, is pushed by a constant force F ≠ 0 entering
only as a force (no zero), starting at rest: m x'' + c x' + k x = F, x(0) = 0, x'(0) = 0.
Then the body keeps moving the way F pushes until its first peak at t_p = π/ω_d, where it stops;
that peak is the furthest it ever goes in that direction; and the peak overshoots the final value
F/k by the fraction M_p = e^(−πζ/√(1 − ζ²)), in which ω_n does not appear. -/
theorem step_overshoot_eq_exp_of_damping_ratio (m c k F : ℝ) (x : ℝ → ℝ)
    (hm : 0 < m) (hk : 0 < k) (hc : 0 ≤ c) (hζ : dampingRatio m c k < 1) (hF : F ≠ 0)
    (hx : ContDiff ℝ 2 x)
    (hode : ∀ t, m * deriv (deriv x) t + c * deriv x t + k * x t = F)
    (h0 : x 0 = 0) (h0' : deriv x 0 = 0) :
    let ζ := dampingRatio m c k
    let tp := π / dampedFreq m c k
    (∀ t ∈ Set.Ioo 0 tp, 0 < F * deriv x t) ∧ deriv x tp = 0 ∧
    (∀ t, 0 ≤ t → F * x t ≤ F * x tp) ∧
    (x tp - F / k) / (F / k) = Real.exp (-π * ζ / Real.sqrt (1 - ζ ^ 2)) := by
  intro ζ tp
  have hσ : ζ * naturalFreq m k = c / (2 * m) := damping_mul_naturalFreq m c k hm hk
  have hωn : naturalFreq m k ^ 2 = k / m := naturalFreq_sq m k hm hk
  have hωnpos : 0 < naturalFreq m k := naturalFreq_pos m k hm hk
  have hωsq : dampedFreq m c k ^ 2 = naturalFreq m k ^ 2 * (1 - ζ ^ 2) :=
    dampedFreq_sq m c k hc hζ
  have hωpos : 0 < dampedFreq m c k := dampedFreq_pos m c k hm hk hc hζ
  have hspos : 0 < Real.sqrt (1 - ζ ^ 2) := Real.sqrt_pos.2 (one_sub_damping_sq_pos m c k hc hζ)
  have hωdef : dampedFreq m c k = naturalFreq m k * Real.sqrt (1 - ζ ^ 2) := rfl
  have hζ0 : 0 ≤ ζ := dampingRatio_nonneg m c k hc
  -- Plain names for the decay rate σ = ζ ω_n and the ringing frequency ω = ω_d.
  obtain ⟨σ, hσdef⟩ : ∃ σ, σ = ζ * naturalFreq m k := ⟨_, rfl⟩
  obtain ⟨ω, hωd⟩ : ∃ ω, ω = dampedFreq m c k := ⟨_, rfl⟩
  have hω : 0 < ω := hωd ▸ hωpos
  have hσ0 : 0 ≤ σ := by rw [hσdef]; positivity
  have hm0 : m ≠ 0 := hm.ne'
  have hk0 : k ≠ 0 := hk.ne'
  have hc' : c = 2 * m * σ := by rw [hσdef, hσ]; field_simp
  have hk' : k = m * (σ ^ 2 + ω ^ 2) := by
    rw [hσdef, hωd, hωsq]
    have : m * ((ζ * naturalFreq m k) ^ 2 + naturalFreq m k ^ 2 * (1 - ζ ^ 2))
        = m * naturalFreq m k ^ 2 := by ring
    rw [this, hωn]; field_simp
  have htp : tp = π / ω := by rw [hωd]
  have hωtp : ω * tp = π := by rw [htp]; field_simp
  obtain ⟨hX, hV, hODE⟩ := explicit_solution m c k F σ ω hm hω hc' hk'
  set X := fun t => F / k * (1 - Real.exp (-σ * t) * (Real.cos (ω * t) + σ / ω * Real.sin (ω * t)))
    with hXdef
  set V := fun t => F / k * ((σ ^ 2 + ω ^ 2) / ω) * Real.exp (-σ * t) * Real.sin (ω * t)
    with hVdef
  have hxd : Differentiable ℝ x := hx.differentiable (by norm_num)
  have hx'd : Differentiable ℝ (deriv x) := hx.differentiable_deriv_two
  -- Uniqueness on t ≥ 0: the energy of x − X starts at 0 and cannot grow.
  have hE := energy_antitone m c k hc (fun t => x t - X t) (fun t => deriv x t - V t)
    (fun t => deriv (deriv x) t - (F / k * ((σ ^ 2 + ω ^ 2) / ω) * Real.exp (-σ * t) *
          (ω * Real.cos (ω * t) - σ * Real.sin (ω * t))))
    (fun t => (hxd t).hasDerivAt.sub (hX t)) (fun t => (hx'd t).hasDerivAt.sub (hV t))
    (fun t => by have h1 := hode t; have h2 := hODE t; simp only [X, V]; linarith)
  have hagree : ∀ t, 0 ≤ t → x t = X t ∧ deriv x t = V t := by
    intro t ht
    have h1 := hE ht
    have hX0 : X 0 = 0 := by simp [X]
    have hV0 : V 0 = 0 := by simp [V]
    simp only [h0, h0', hX0, hV0] at h1
    have a1 := mul_nonneg hm.le (sq_nonneg (deriv x t - V t))
    have a2 := mul_nonneg hk.le (sq_nonneg (x t - X t))
    have b1 : m * (deriv x t - V t) ^ 2 = 0 := by linarith
    have b2 : k * (x t - X t) ^ 2 = 0 := by linarith
    rcases mul_eq_zero.1 b1 with h | h
    · exact absurd h hm0
    rcases mul_eq_zero.1 b2 with h' | h'
    · exact absurd h' hk0
    exact ⟨by linarith [pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h'],
      by linarith [pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h]⟩
  have htp0 : 0 ≤ tp := by rw [htp]; positivity
  have hFF : 0 < F * F := mul_self_pos.2 hF
  have hA : 0 < F * (F / k * ((σ ^ 2 + ω ^ 2) / ω)) := by
    have e : F * (F / k * ((σ ^ 2 + ω ^ 2) / ω)) = F * F / k * ((σ ^ 2 + ω ^ 2) / ω) := by ring
    have h1 : 0 < (σ ^ 2 + ω ^ 2) / ω := by positivity
    rw [e]
    exact mul_pos (div_pos hFF hk) h1
  have hVpos : ∀ t ∈ Set.Ioo 0 tp, 0 < F * V t := by
    rintro t ⟨ht0, ht1⟩
    have hs : 0 < Real.sin (ω * t) := by
      apply Real.sin_pos_of_pos_of_lt_pi (by positivity)
      rw [← hωtp]; exact mul_lt_mul_of_pos_left ht1 hω
    have : F * V t = F * (F / k * ((σ ^ 2 + ω ^ 2) / ω)) * (Real.exp (-σ * t) * Real.sin (ω * t)) := by
      simp only [V]; ring
    rw [this]
    exact mul_pos hA (mul_pos (Real.exp_pos _) hs)
  have hXtp : X tp - F / k = F / k * Real.exp (-σ * tp) := by
    simp only [X]; rw [hωtp, Real.cos_pi, Real.sin_pi]; ring
  have hxtp := hagree tp htp0
  have hpeak : 0 ≤ F * (x tp - F / k) := by
    rw [hxtp.1, hXtp]
    have e : F * (F / k * Real.exp (-σ * tp)) = F * F / k * Real.exp (-σ * tp) := by ring
    rw [e]
    exact (mul_pos (div_pos hFF hk) (Real.exp_pos _)).le
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro t ht
    rw [(hagree t ht.1.le).2]
    exact hVpos t ht
  · rw [hxtp.2]
    simp only [V]
    rw [hωtp, Real.sin_pi, mul_zero]
  · intro t ht
    rcases le_total t tp with h | h
    · -- Before the peak, F x rises.
      have hmono : MonotoneOn (fun t => F * X t) (Set.Icc 0 tp) := by
        have hd : ∀ t, HasDerivAt (fun t => F * X t) (F * V t) t := fun t => (hX t).const_mul F
        apply monotoneOn_of_deriv_nonneg (convex_Icc 0 tp)
        · exact (fun t _ => (hd t).continuousAt.continuousWithinAt)
        · exact (fun t _ => (hd t).differentiableAt.differentiableWithinAt)
        · intro t ht
          rw [interior_Icc] at ht
          rw [(hd t).deriv]
          exact (hVpos t ht).le
      have := hmono ⟨ht, h⟩ ⟨htp0, le_refl tp⟩ h
      simp only at this
      rw [(hagree t ht).1, hxtp.1]
      exact this
    · -- After the peak, the energy about F/k only falls, so |x − F/k| cannot pass its peak value.
      have hE2 := energy_antitone m c k hc (fun t => x t - F / k) (deriv x) (deriv (deriv x))
        (fun t => (hxd t).hasDerivAt.sub_const (F / k)) (fun t => (hx'd t).hasDerivAt)
        (fun t => by
          have := hode t
          have e : k * (F / k) = F := by field_simp
          linear_combination this - e)
      have h2 := hE2 h
      simp only at h2
      have hv0 : deriv x tp = 0 := by
        rw [hxtp.2]; simp only [V]; rw [hωtp, Real.sin_pi, mul_zero]
      rw [hv0] at h2
      have a1 := mul_nonneg hm.le (sq_nonneg (deriv x t))
      have h3 : (x t - F / k) ^ 2 ≤ (x tp - F / k) ^ 2 := by
        have : k * (x t - F / k) ^ 2 ≤ k * (x tp - F / k) ^ 2 := by
          linarith [h2, a1, show m * (0 : ℝ) ^ 2 = 0 by ring]
        exact le_of_mul_le_mul_left this hk
      have h4 : (F * (x t - F / k)) ^ 2 ≤ (F * (x tp - F / k)) ^ 2 := by
        rw [mul_pow, mul_pow]
        exact mul_le_mul_of_nonneg_left h3 (sq_nonneg F)
      have h5 : F * (x t - F / k) ≤ F * (x tp - F / k) := by
        exact le_of_sq_le_sq_of_nonneg _ _ h4 hpeak
      linarith
  · rw [hxtp.1, hXtp]
    have hFk : F / k ≠ 0 := div_ne_zero hF hk0
    rw [mul_div_cancel_left₀ _ hFk]
    congr 1
    rw [htp, hσdef, hωd, hωdef]
    field_simp

/-- Two numbers fix the equation and its poles. For m > 0, k > 0 and a damper c ≥ 0 with ζ below 1:
dividing by m leaves c/m = 2ζω_n and k/m = ω_n², so the equation reads
x'' + 2ζω_n x' + ω_n² x = ω_n² F/k; the roots of m s² + c s + k = 0 are exactly the pair
p = −ζω_n ± jω_d; and in polar form |p| = ω_n and −Re p/|p| = ζ. -/
theorem poles_have_radius_natural_freq_and_cosine_damping_ratio (m c k : ℝ)
    (hm : 0 < m) (hk : 0 < k) (hc : 0 ≤ c) (hζ : dampingRatio m c k < 1) :
    let ζ := dampingRatio m c k
    let ωn := naturalFreq m k
    let p : ℂ := ⟨-(ζ * ωn), dampedFreq m c k⟩
    c / m = 2 * ζ * ωn ∧ k / m = ωn ^ 2 ∧
    (∀ s : ℂ, (m : ℂ) * s ^ 2 + c * s + k = 0 ↔ s = p ∨ s = (starRingEnd ℂ) p) ∧
    ‖p‖ = ωn ∧ -p.re / ‖p‖ = ζ := by
  intro ζ ωn p
  have hσ : ζ * ωn = c / (2 * m) := damping_mul_naturalFreq m c k hm hk
  have hωn : ωn ^ 2 = k / m := naturalFreq_sq m k hm hk
  have hωnpos : 0 < ωn := naturalFreq_pos m k hm hk
  have hω : dampedFreq m c k ^ 2 = ωn ^ 2 * (1 - ζ ^ 2) := dampedFreq_sq m c k hc hζ
  have hm0 : m ≠ 0 := hm.ne'
  have hc' : c = 2 * m * (ζ * ωn) := by rw [hσ]; field_simp
  have hk' : k = m * ((ζ * ωn) ^ 2 + dampedFreq m c k ^ 2) := by
    rw [hω]; have : k = m * ωn ^ 2 := by rw [hωn]; field_simp
    rw [this]; ring
  have hnorm : ‖p‖ = ωn := by
    rw [Complex.norm_def, Complex.normSq_mk]
    rw [show -(ζ * ωn) * -(ζ * ωn) + dampedFreq m c k * dampedFreq m c k = ωn ^ 2 by
      linear_combination hω]
    exact Real.sqrt_sq hωnpos.le
  refine ⟨?_, hωn.symm, ?_, hnorm, ?_⟩
  · rw [hc']; field_simp
  · intro s
    have hp : p = ((-(ζ * ωn) : ℝ) : ℂ) + (dampedFreq m c k : ℂ) * Complex.I := by
      apply Complex.ext <;> simp [p]
    have hp' : (starRingEnd ℂ) p = ((-(ζ * ωn) : ℝ) : ℂ) - (dampedFreq m c k : ℂ) * Complex.I := by
      apply Complex.ext <;> simp [p]
    have hfac : (m : ℂ) * s ^ 2 + c * s + k = m * ((s - p) * (s - (starRingEnd ℂ) p)) := by
      have hcC : (c : ℂ) = 2 * m * (ζ * ωn) := by exact_mod_cast hc'
      have hkC : (k : ℂ) = m * ((ζ * ωn) ^ 2 + dampedFreq m c k ^ 2) := by exact_mod_cast hk'
      rw [hp', hp, hcC, hkC]
      push_cast
      linear_combination ((m : ℂ) * (dampedFreq m c k : ℂ) ^ 2) * Complex.I_sq
    rw [hfac, mul_eq_zero, mul_eq_zero, sub_eq_zero, sub_eq_zero]
    simp [hm0]
  · rw [hnorm]
    show -(-(ζ * ωn)) / ωn = ζ
    field_simp

/-- At the natural frequency the response is 1/(2ζ j). For m > 0 and k > 0, the transfer function
G(jω) = k/(k − mω² + jcω) at ω = ω_n equals 1/(2ζ j): a lag of a quarter cycle and a gain of
1/(2ζ). -/
theorem freq_response_at_natural_freq (m c k : ℝ) (hm : 0 < m) (hk : 0 < k) :
    let ωn := naturalFreq m k
    (k : ℂ) / (k - m * ωn ^ 2 + Complex.I * (c * ωn)) = 1 / (2 * dampingRatio m c k * Complex.I) := by
  intro ωn
  have hσ : dampingRatio m c k * ωn = c / (2 * m) := damping_mul_naturalFreq m c k hm hk
  have hωn : ωn ^ 2 = k / m := naturalFreq_sq m k hm hk
  have hωnpos : 0 < ωn := naturalFreq_pos m k hm hk
  have hm0 : m ≠ 0 := hm.ne'
  have hc' : c = 2 * m * (dampingRatio m c k * ωn) := by rw [hσ]; field_simp
  have hk' : k = m * ωn ^ 2 := by rw [hωn]; field_simp
  set ζ := dampingRatio m c k
  have hm0' : (m : ℂ) ≠ 0 := by exact_mod_cast hm0
  have hω0' : (ωn : ℂ) ≠ 0 := by exact_mod_cast hωnpos.ne'
  have hcC : (c : ℂ) = 2 * m * (ζ * ωn) := by exact_mod_cast hc'
  rw [hk']
  push_cast
  rw [hcC]
  rw [show (m : ℂ) * ωn ^ 2 - m * ωn ^ 2 + Complex.I * (2 * m * (ζ * ωn) * ωn)
      = (m * ωn ^ 2) * (2 * ζ * Complex.I) by ring]
  rw [div_mul_eq_div_div, div_self (mul_ne_zero hm0' (pow_ne_zero 2 hω0'))]

/-! The card's corner: m = 400 kg, f_n = 1 Hz so ω_n = 2π rad/s, ζ = 0.7 = 7/10. -/

-- Stiffness k = m ω_n² = 400 × (2π)² = 1600 π².
example : (400 : ℝ) * (2 * π) ^ 2 = 1600 * π ^ 2 := by ring
-- Damper c = 2ζ√(km) = 2ζ m ω_n, since √(km) = √(m² ω_n²) = m ω_n: c = 1120 π.
example : 2 * (7 / 10 : ℝ) * 400 * (2 * π) = 1120 * π := by ring
-- 1 − ζ² = 1 − 49/100 = 51/100, the square of ω_d/ω_n.
example : (1 : ℚ) - (7 / 10) ^ 2 = 51 / 100 := by norm_num
-- Gain at ω_n: 1/(2ζ) = 1/(2 × 7/10) = 5/7 ≈ 0.7143.
example : (1 : ℚ) / (2 * (7 / 10)) = 5 / 7 := by norm_num
-- At ω_n, G = 1/(2ζ j) = −(5/7) j: a quarter-cycle lag.
example : (1 : ℂ) / (2 * (7 / 10) * Complex.I) = -(5 / 7) * Complex.I := by
  field_simp
  ring_nf
  rw [Complex.I_sq]
  ring
-- A resonant peak needs ζ below 1/√2, that is ζ² < 1/2; at ζ = 7/10, ζ² = 49/100 < 1/2, just under.
example : (7 / 10 : ℚ) ^ 2 < 1 / 2 := by norm_num
-- The kerb's zero at −k/c = −ω_n/(2ζ) = −2π/(7/5) = −10π/7 ≈ −4.4880 rad/s.
example : (1600 * π ^ 2) / (1120 * π) = 10 * π / 7 := by
  have hπ : π ≠ 0 := Real.pi_ne_zero
  field_simp
  ring
-- 1 Hz read as 1 rad/s: k = 400 × 1² = 400 N/m.
example : (400 : ℚ) * 1 ^ 2 = 400 := by norm_num
-- The 2 dropped from c = 2ζ√(km): the real damping ratio is ζ/2 = 7/20 = 0.35.
example : (7 / 10 : ℚ) / 2 = 7 / 20 := by norm_num

#print axioms step_overshoot_eq_exp_of_damping_ratio
#print axioms poles_have_radius_natural_freq_and_cosine_damping_ratio
#print axioms freq_response_at_natural_freq

end SecondOrder
