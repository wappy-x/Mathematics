-- Dispersion: two plane waves beat with an envelope that travels at the gap ratio Δω/Δk, which tends to the group velocity dω/dk; a plane wave in the linear long-wave equation obeys ω = c₀k − βk³; and the sech² solitary wave solves KdV.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.Calculus.Deriv.Slope

open Filter Topology

/-- Derivative of `y ↦ cos (k y - c)`. -/
lemma deriv_cos_affine (k c : ℝ) :
    deriv (fun y => Real.cos (k * y - c)) = fun y => -(k * Real.sin (k * y - c)) := by
  funext y
  have h : HasDerivAt (fun y => k * y - c) k y := by
    simpa using ((hasDerivAt_id y).const_mul k).sub_const c
  rw [(h.cos).deriv]
  ring

/-- Derivative of `y ↦ sin (k y - c)`. -/
lemma deriv_sin_affine (k c : ℝ) :
    deriv (fun y => Real.sin (k * y - c)) = fun y => k * Real.cos (k * y - c) := by
  funext y
  have h : HasDerivAt (fun y => k * y - c) k y := by
    simpa using ((hasDerivAt_id y).const_mul k).sub_const c
  rw [(h.sin).deriv]
  ring

/-- Third derivative of `y ↦ cos (k y - c)`. -/
lemma iteratedDeriv_three_cos_affine (k c y : ℝ) :
    iteratedDeriv 3 (fun y => Real.cos (k * y - c)) y = k ^ 3 * Real.sin (k * y - c) := by
  rw [iteratedDeriv_succ', iteratedDeriv_succ', iteratedDeriv_one, deriv_cos_affine]
  have e1 : deriv (fun y => -(k * Real.sin (k * y - c))) = fun y => -(k * (k * Real.cos (k * y - c))) := by
    funext y
    rw [deriv.fun_neg, deriv_const_mul_field', deriv_sin_affine]
  rw [e1]
  have e2 : deriv (fun y => -(k * (k * Real.cos (k * y - c)))) y = k ^ 3 * Real.sin (k * y - c) := by
    rw [deriv.fun_neg, deriv_const_mul_field', deriv_const_mul_field', deriv_cos_affine]
    ring
  exact e2

/-- First derivative of `sech² u`. -/
lemma hasDerivAt_sech_sq (u : ℝ) :
    HasDerivAt (fun u => (1 / Real.cosh u) ^ 2) (-2 * Real.sinh u / Real.cosh u ^ 3) u := by
  have hc := Real.cosh_pos u
  have := ((hasDerivAt_const u (1:ℝ)).div (Real.hasDerivAt_cosh u) hc.ne').pow 2
  convert this using 1
  simp only [Pi.div_apply, Nat.cast_ofNat, Nat.add_one_sub_one, pow_one]
  field_simp
  ring

/-- Second derivative of `sech² u`. -/
lemma hasDerivAt_sech_sq_d1 (u : ℝ) :
    HasDerivAt (fun u => -2 * Real.sinh u / Real.cosh u ^ 3)
      (-2 / Real.cosh u ^ 2 + 6 * Real.sinh u ^ 2 / Real.cosh u ^ 4) u := by
  have hc := Real.cosh_pos u
  have := ((Real.hasDerivAt_sinh u).const_mul (-2)).div ((Real.hasDerivAt_cosh u).pow 3)
    (pow_pos hc 3).ne'
  convert this using 1
  simp only [Pi.pow_apply]
  field_simp
  ring

/-- Third derivative of `sech² u`. -/
lemma hasDerivAt_sech_sq_d2 (u : ℝ) :
    HasDerivAt (fun u => -2 / Real.cosh u ^ 2 + 6 * Real.sinh u ^ 2 / Real.cosh u ^ 4)
      (16 * Real.sinh u / Real.cosh u ^ 3 - 24 * Real.sinh u ^ 3 / Real.cosh u ^ 5) u := by
  have hc := Real.cosh_pos u
  have h1 := (hasDerivAt_const u (-2:ℝ)).div ((Real.hasDerivAt_cosh u).pow 2)
    (pow_pos hc 2).ne'
  have h2 := (((Real.hasDerivAt_sinh u).pow 2).const_mul 6).div ((Real.hasDerivAt_cosh u).pow 4)
    (pow_pos hc 4).ne'
  convert h1.add h2 using 1
  simp only [Pi.pow_apply]
  field_simp
  ring

/-- Derivative of `y ↦ a G ((y - b)/m)`. -/
lemma deriv_affine_comp (G G' : ℝ → ℝ) (hG : ∀ u, HasDerivAt G (G' u) u) (a b m : ℝ) :
    deriv (fun y => a * G ((y - b) / m)) = fun y => a / m * G' ((y - b) / m) := by
  funext y
  have hin : HasDerivAt (fun y => (y - b) / m) (1 / m) y := by
    simpa using ((hasDerivAt_id y).sub_const b).div_const m
  have := ((hG ((y - b) / m)).comp y hin).const_mul a
  refine this.deriv.trans ?_
  ring


/-- Group velocity from beats. Take any dispersion relation `ω(k)` with slope `ω'` at `k`.
Add two plane waves of equal height at wavenumbers `k - d/2` and `k + d/2`. The sum is a carrier
`cos(k x - ω̄ t)` (crests at the phase velocity) times an envelope `2 cos(d (x - c t)/2)`,
which is a fixed shape moving at the beat speed `c = Δω/Δk`. As the two wavenumbers close in,
the beat speed tends to the group velocity `dω/dk = ω'`. -/
theorem beats_move_at_group_velocity (ω : ℝ → ℝ) (k ω' : ℝ) (hω : HasDerivAt ω ω' k) :
    (∀ d x t : ℝ, d ≠ 0 →
      Real.cos ((k - d / 2) * x - ω (k - d / 2) * t)
          + Real.cos ((k + d / 2) * x - ω (k + d / 2) * t)
        = 2 * Real.cos (d * (x - (ω (k + d / 2) - ω (k - d / 2)) / d * t) / 2)
            * Real.cos (k * x - (ω (k - d / 2) + ω (k + d / 2)) / 2 * t)) ∧
    Tendsto (fun d : ℝ => (ω (k + d / 2) - ω (k - d / 2)) / d) (𝓝[≠] 0) (𝓝 ω') := by
  constructor
  · intro d x t hd
    rw [add_comm, Real.cos_add_cos, mul_assoc, mul_assoc, mul_comm (Real.cos _) (Real.cos _)]
    congr 3
    · field_simp
      ring
    · ring
  · have h1 : HasDerivAt (fun d : ℝ => k + d / 2) (1 / 2) 0 := by
      simpa using ((hasDerivAt_id (0:ℝ)).div_const 2).const_add k
    have h2 : HasDerivAt (fun d : ℝ => k - d / 2) (-(1 / 2)) 0 := by
      simpa using ((hasDerivAt_id (0:ℝ)).div_const 2).const_sub k
    have e1 : (fun d : ℝ => k + d / 2) 0 = k := by simp
    have e2 : (fun d : ℝ => k - d / 2) 0 = k := by simp
    have g1 : HasDerivAt (fun d : ℝ => ω (k + d / 2)) (ω' * (1 / 2)) 0 := by
      have := (e1 ▸ hω).comp (0:ℝ) h1
      simpa [Function.comp_def] using this
    have g2 : HasDerivAt (fun d : ℝ => ω (k - d / 2)) (ω' * (-(1 / 2))) 0 := by
      have := (e2 ▸ hω).comp (0:ℝ) h2
      simpa [Function.comp_def] using this
    have g := g1.sub g2
    rw [hasDerivAt_iff_tendsto_slope_zero] at g
    convert g using 1
    · funext d
      simp only [zero_add, zero_div, add_zero, sub_zero, sub_self, smul_eq_mul, Pi.sub_apply]
      ring
    · congr 1; ring

/-- Reading the dispersion relation off a plane wave. The plane wave `η = cos(k x - ω t)`
solves the linear long-wave equation `η_t + c₀ η_x + β η_xxx = 0` everywhere exactly when
`ω = c₀ k - β k³`; the group velocity, the slope of that rule, is then `c₀ - 3 β k²`. -/
theorem long_wave_dispersion_relation (c₀ β k ω : ℝ) :
    ((∀ x t : ℝ, deriv (fun s => Real.cos (k * x - ω * s)) t
        + c₀ * deriv (fun y => Real.cos (k * y - ω * t)) x
        + β * iteratedDeriv 3 (fun y => Real.cos (k * y - ω * t)) x = 0)
      ↔ ω = c₀ * k - β * k ^ 3) ∧
    HasDerivAt (fun q : ℝ => c₀ * q - β * q ^ 3) (c₀ - 3 * β * k ^ 2) k := by
  have key : ∀ x t : ℝ, deriv (fun s => Real.cos (k * x - ω * s)) t
        + c₀ * deriv (fun y => Real.cos (k * y - ω * t)) x
        + β * iteratedDeriv 3 (fun y => Real.cos (k * y - ω * t)) x
        = (ω - c₀ * k + β * k ^ 3) * Real.sin (k * x - ω * t) := by
    intro x t
    have ht : deriv (fun s => Real.cos (k * x - ω * s)) t = ω * Real.sin (k * x - ω * t) := by
      have h : HasDerivAt (fun s => k * x - ω * s) (-ω) t := by
        simpa using ((hasDerivAt_id t).const_mul ω).const_sub (k * x)
      rw [h.cos.deriv]
      ring
    rw [ht, deriv_cos_affine, iteratedDeriv_three_cos_affine]
    ring
  refine ⟨⟨fun h => ?_, fun h x t => ?_⟩, ?_⟩
  · by_cases hk : k = 0
    · subst hk
      by_contra hne
      have hω : ω ≠ 0 := by simpa using hne
      have := h 0 (-(Real.pi / 2) / ω)
      rw [key] at this
      have e : (0:ℝ) * 0 - ω * (-(Real.pi / 2) / ω) = Real.pi / 2 := by field_simp; ring
      rw [e, Real.sin_pi_div_two] at this
      apply hne
      linear_combination this
    · have := h (Real.pi / 2 / k) 0
      rw [key] at this
      have e : k * (Real.pi / 2 / k) - ω * 0 = Real.pi / 2 := by field_simp; ring
      rw [e, Real.sin_pi_div_two] at this
      linear_combination this
  · rw [key, h]
    ring
  · have := ((hasDerivAt_id k).const_mul c₀).sub ((hasDerivAt_pow 3 k).const_mul β)
    convert this using 1
    · funext q; simp
    · norm_num; ring

/-- The KdV solitary wave. On water of depth `h > 0`, with long-wave speed `c₀ = √(g h)`,
the hump `η = a sech²((x - V t)/ℓ)` of height `a > 0`, with speed `V = c₀ (1 + a/(2h))` and
width scale `ℓ = √(4h³/(3a))`, solves the Korteweg-de Vries equation
`η_t + c₀ η_x + (3c₀/(2h)) η η_x + (c₀ h²/6) η_xxx = 0` at every place and time. -/
theorem kdv_solitary_wave (g h a : ℝ) (hh : 0 < h) (ha : 0 < a) (x t : ℝ) :
    let c₀ := Real.sqrt (g * h)
    let V := c₀ * (1 + a / (2 * h))
    let ℓ := Real.sqrt (4 * h ^ 3 / (3 * a))
    let η : ℝ → ℝ → ℝ := fun y s => a * (1 / Real.cosh ((y - V * s) / ℓ)) ^ 2
    deriv (fun s => η x s) t + c₀ * deriv (fun y => η y t) x
      + 3 * c₀ / (2 * h) * η x t * deriv (fun y => η y t) x
      + c₀ * h ^ 2 / 6 * iteratedDeriv 3 (fun y => η y t) x = 0 := by
  intro c₀ V ℓ η
  have hℓpos : 0 < ℓ := Real.sqrt_pos.mpr (by positivity)
  have hℓ2 : ℓ ^ 2 = 4 * h ^ 3 / (3 * a) := Real.sq_sqrt (by positivity)
  have hy : (fun y => η y t) = fun y => a * (fun u => (1 / Real.cosh u) ^ 2) ((y - V * t) / ℓ) :=
    rfl
  have d1 := deriv_affine_comp _ _ hasDerivAt_sech_sq a (V * t) ℓ
  have d2 := deriv_affine_comp _ _ hasDerivAt_sech_sq_d1 (a / ℓ) (V * t) ℓ
  have d3 := deriv_affine_comp _ _ hasDerivAt_sech_sq_d2 (a / ℓ / ℓ) (V * t) ℓ
  have hthird : iteratedDeriv 3 (fun y => η y t) x
      = a / ℓ / ℓ / ℓ * (16 * Real.sinh ((x - V * t) / ℓ) / Real.cosh ((x - V * t) / ℓ) ^ 3
          - 24 * Real.sinh ((x - V * t) / ℓ) ^ 3 / Real.cosh ((x - V * t) / ℓ) ^ 5) := by
    rw [iteratedDeriv_succ', iteratedDeriv_succ', iteratedDeriv_one, hy, d1, d2, d3]
  have hfirst : deriv (fun y => η y t) x
      = a / ℓ * (-2 * Real.sinh ((x - V * t) / ℓ) / Real.cosh ((x - V * t) / ℓ) ^ 3) := by
    rw [hy, d1]
  have htime : deriv (fun s => η x s) t
      = a * (-2 * Real.sinh ((x - V * t) / ℓ) / Real.cosh ((x - V * t) / ℓ) ^ 3) * (-V / ℓ) := by
    have hin : HasDerivAt (fun s => (x - V * s) / ℓ) (-V / ℓ) t := by
      simpa using (((hasDerivAt_id t).const_mul V).const_sub x).div_const ℓ
    have := ((hasDerivAt_sech_sq ((x - V * t) / ℓ)).comp t hin).const_mul a
    refine this.deriv.trans ?_
    ring
  have hval : η x t = a * (1 / Real.cosh ((x - V * t) / ℓ)) ^ 2 := rfl
  rw [hthird, hfirst, htime, hval]
  set u := (x - V * t) / ℓ
  have hc := Real.cosh_pos u
  have hcs := Real.cosh_sq u
  have hs3 : Real.sinh u ^ 3 = Real.sinh u * (Real.cosh u ^ 2 - 1) := by rw [hcs]; ring
  have hℓ3 : a / ℓ / ℓ / ℓ = a / ℓ * (3 * a / (4 * h ^ 3)) := by
    rw [show a / ℓ / ℓ / ℓ = a / ℓ / ℓ ^ 2 by ring, hℓ2]
    field_simp
  rw [hℓ3, hs3]
  simp only [V]
  field_simp
  ring

-- The card's hump: height a = 3/10 m on depth h = 3/2 m.
-- Width scale squared: 4 h³ / (3 a) = 15, so ℓ = √15 m.
example : (4 * (3 / 2 : ℚ) ^ 3 / (3 * (3 / 10))) = 15 := by norm_num
-- Speed factor: V / c₀ = 1 + a / (2 h) = 11/10.
example : (1 + (3 / 10 : ℚ) / (2 * (3 / 2))) = 11 / 10 := by norm_num

#print axioms deriv_cos_affine
#print axioms deriv_sin_affine
#print axioms iteratedDeriv_three_cos_affine
#print axioms hasDerivAt_sech_sq
#print axioms hasDerivAt_sech_sq_d1
#print axioms hasDerivAt_sech_sq_d2
#print axioms deriv_affine_comp
#print axioms beats_move_at_group_velocity
#print axioms long_wave_dispersion_relation
#print axioms kdv_solitary_wave
