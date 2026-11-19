-- Geodesic and exponential map: on a sphere of radius R the exponential map shoots along a great circle that stays on the sphere at unit speed with no sideways acceleration, the logarithm map undoes it for distances under π R, and the chart's θ equation conserves Clairaut's quantity.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse

open Real

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]

/-- The card's exponential map on the sphere of radius `R` centred at the origin:
`exp_p(v) = cos(|v|/R) p + R sin(|v|/R) v/|v|`. -/
noncomputable def sphereExp (R : ℝ) (p v : E) : E :=
  Real.cos (‖v‖ / R) • p + (R * Real.sin (‖v‖ / R) / ‖v‖) • v

/-- The card's logarithm map on the sphere of radius `R`:
`log_p(q) = d w/|w|`, with `w = q - (p·q/R²) p` and `d = R arccos(p·q/R²)`. -/
noncomputable def sphereLog (R : ℝ) (p q : E) : E :=
  (R * Real.arccos (inner ℝ p q / R ^ 2) / ‖q - (inner ℝ p q / R ^ 2) • p‖) •
    (q - (inner ℝ p q / R ^ 2) • p)

theorem sphereExp_smul_unit (R : ℝ) (p u : E) (hu : ‖u‖ = 1) (s : ℝ) :
    sphereExp R p (s • u) = Real.cos (s / R) • p + (R * Real.sin (s / R)) • u := by
  unfold sphereExp
  rw [norm_smul, hu, mul_one, Real.norm_eq_abs, smul_smul]
  rcases le_or_gt 0 s with hs | hs
  · rw [abs_of_nonneg hs]
    rcases hs.eq_or_lt with h0 | hpos
    · subst h0; simp
    · congr 2; field_simp
  · rw [abs_of_neg hs, neg_div, Real.cos_neg, Real.sin_neg]
    congr 2; field_simp
    rw [mul_comm R s, mul_assoc, mul_div_cancel_left₀ _ hs.ne]

#print axioms sphereExp_smul_unit

theorem sphere_inner_combo (R a b : ℝ) (p u : E) (hp : ‖p‖ = R)
    (hu : ‖u‖ = 1) (hpu : inner ℝ p u = 0) :
    ‖a • p + b • u‖ ^ 2 = a ^ 2 * R ^ 2 + b ^ 2 := by
  have hup : inner ℝ u p = 0 := by rw [real_inner_comm]; exact hpu
  rw [← real_inner_self_eq_norm_sq]
  simp only [inner_add_left, inner_add_right, real_inner_smul_left, real_inner_smul_right,
    real_inner_self_eq_norm_sq, hpu, hup, norm_smul, mul_pow, Real.norm_eq_abs, sq_abs]
  rw [hp, hu]
  ring

#print axioms sphere_inner_combo

omit [InnerProductSpace ℝ E] in
theorem norm_eq_of_sq_eq {x : E} {r : ℝ} (hr : 0 ≤ r) (h : ‖x‖ ^ 2 = r ^ 2) : ‖x‖ = r := by
  exact (pow_left_inj₀ (norm_nonneg _) hr two_ne_zero).1 h

#print axioms norm_eq_of_sq_eq

/-- Shooting from a point `p` on the sphere of radius `R` along a unit arrow `u` flat along the
ground at `p` traces a geodesic: the route `s ↦ exp_p(s u)` stays on the sphere, starts at `p`
moving along `u`, runs at speed 1, and its acceleration is `-γ(s)/R²`, pointing at the centre,
so it has no part along the ground. -/
theorem sphere_exp_ray_is_geodesic (R : ℝ) (hR : 0 < R) (p u : E) (hp : ‖p‖ = R)
    (hu : ‖u‖ = 1) (hpu : inner ℝ p u = 0) :
    let γ : ℝ → E := fun s => sphereExp R p (s • u)
    (∀ s, ‖γ s‖ = R) ∧ γ 0 = p ∧ deriv γ 0 = u ∧ (∀ s, ‖deriv γ s‖ = 1) ∧
      (∀ s, deriv (deriv γ) s = -(R ^ 2)⁻¹ • γ s) ∧
      (∀ s w, inner ℝ (γ s) w = 0 → inner ℝ (deriv (deriv γ) s) w = 0) := by
  intro γ
  have hR0 : R ≠ 0 := hR.ne'
  have hγ : γ = fun s => Real.cos (s / R) • p + (R * Real.sin (s / R)) • u := by
    funext s; exact sphereExp_smul_unit R p u hu s
  have hd1 : ∀ s, HasDerivAt γ ((-(Real.sin (s / R) / R)) • p + Real.cos (s / R) • u) s := by
    intro s
    rw [hγ]
    have h1 : HasDerivAt (fun s : ℝ => s / R) (1 / R) s := (hasDerivAt_id s).div_const R
    have hc := (h1.cos).smul_const p
    have hs := ((h1.sin).const_mul R).smul_const u
    convert hc.add hs using 2
    · simp [div_eq_mul_inv]
    · simp; field_simp
  have hD1 : deriv γ = fun s => (-(Real.sin (s / R) / R)) • p + Real.cos (s / R) • u := by
    funext s; exact (hd1 s).deriv
  have hd2 : ∀ s, HasDerivAt (deriv γ) (-(R ^ 2)⁻¹ • γ s) s := by
    intro s
    rw [hD1, hγ]
    have h1 : HasDerivAt (fun s : ℝ => s / R) (1 / R) s := (hasDerivAt_id s).div_const R
    have hc := (((h1.sin).div_const R).neg).smul_const p
    have hs := (h1.cos).smul_const u
    convert hc.add hs using 1
    simp only [smul_add, smul_smul]
    congr 1
    · congr 1; field_simp
    · congr 1; field_simp
  have hD2 : ∀ s, deriv (deriv γ) s = -(R ^ 2)⁻¹ • γ s := fun s => (hd2 s).deriv
  refine ⟨?_, ?_, ?_, ?_, hD2, ?_⟩
  · intro s
    rw [hγ]
    apply norm_eq_of_sq_eq hR.le
    rw [sphere_inner_combo R _ _ p u hp hu hpu]
    have := Real.sin_sq_add_cos_sq (s / R)
    linear_combination (R ^ 2) * this
  · rw [hγ]; simp
  · rw [hD1]; simp
  · intro s
    rw [hD1]
    apply norm_eq_of_sq_eq zero_le_one
    rw [sphere_inner_combo R _ _ p u hp hu hpu]
    have := Real.sin_sq_add_cos_sq (s / R)
    field_simp
    linear_combination this
  · intro s w hw
    rw [hD2, real_inner_smul_left, hw, mul_zero]

/-- The logarithm map undoes the exponential map for every arrow `v` flat along the ground at `p`
that is shorter than half way round, `|v| < π R`. -/
theorem sphere_log_exp_of_lt_pi_mul (R : ℝ) (hR : 0 < R) (p v : E) (hp : ‖p‖ = R)
    (hpv : inner ℝ p v = 0) (hv : ‖v‖ < π * R) :
    sphereLog R p (sphereExp R p v) = v := by
  have hR0 : R ≠ 0 := hR.ne'
  set t := ‖v‖ / R with ht
  have ht0 : 0 ≤ t := div_nonneg (norm_nonneg _) hR.le
  have htpi : t < π := by rw [ht, div_lt_iff₀ hR]; exact hv
  have hinner : inner ℝ p (sphereExp R p v) / R ^ 2 = Real.cos t := by
    unfold sphereExp
    rw [inner_add_right, real_inner_smul_right, real_inner_smul_right, hpv,
      real_inner_self_eq_norm_sq, hp]
    field_simp
    ring
  unfold sphereLog
  rw [hinner, Real.arccos_cos ht0 htpi.le]
  have hw : sphereExp R p v - Real.cos t • p = (R * Real.sin t / ‖v‖) • v := by
    unfold sphereExp; rw [← ht]; abel
  rw [hw]
  rcases (norm_nonneg v).eq_or_lt with h0 | hpos
  · have hv0 : v = 0 := norm_eq_zero.1 h0.symm
    subst hv0; simp
  · have htpos : 0 < t := div_pos hpos hR
    have hsin : 0 < Real.sin t := Real.sin_pos_of_pos_of_lt_pi htpos htpi
    rw [norm_smul, Real.norm_eq_abs, abs_of_pos (by positivity), smul_smul]
    have : R * t / (R * Real.sin t / ‖v‖ * ‖v‖) * (R * Real.sin t / ‖v‖) = 1 := by
      rw [ht] at hsin ⊢; field_simp [hsin.ne']
    rw [this, one_smul]

/-- Clairaut's relation: wherever the chart covers the route (`sin φ ≠ 0`), a solution of the
globe's θ equation `θ'' = -2 (cos φ / sin φ) φ' θ'` keeps `R² sin² φ θ'` constant. -/
theorem clairaut_quantity_conserved (R : ℝ) (φ θ : ℝ → ℝ) (hφ : Differentiable ℝ φ)
    (hθ' : Differentiable ℝ (deriv θ))
    (hchart : ∀ s, Real.sin (φ s) ≠ 0)
    (heq : ∀ s, deriv (deriv θ) s =
      -2 * (Real.cos (φ s) / Real.sin (φ s)) * deriv φ s * deriv θ s) :
    ∀ s t, R ^ 2 * Real.sin (φ s) ^ 2 * deriv θ s = R ^ 2 * Real.sin (φ t) ^ 2 * deriv θ t := by
  let f : ℝ → ℝ := fun s => R ^ 2 * Real.sin (φ s) ^ 2 * deriv θ s
  have hf : ∀ s, HasDerivAt f 0 s := by
    intro s
    have h1 := ((((hφ s).hasDerivAt.sin).pow 2).const_mul (R ^ 2)).mul (hθ' s).hasDerivAt
    convert h1 using 1
    rw [heq s]
    simp only [Pi.pow_apply]
    have := hchart s
    field_simp
    ring
  have hdiff : Differentiable ℝ f := fun s => (hf s).differentiableAt
  intro s t
  exact is_const_of_deriv_eq_zero hdiff (fun s => (hf s).deriv) s t

#print axioms sphere_exp_ray_is_geodesic
#print axioms sphere_log_exp_of_lt_pi_mul
#print axioms clairaut_quantity_conserved
