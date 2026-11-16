-- The Laplacian in round coordinates, and the modes it splits into: in polar and spherical coordinates the Laplacian is a radial part plus an angular part over the radius squared, and the radial powers of the round modes are m and −m in the plane, n and −(n+1) in space.
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Tactic.NormNum

/-! The plane is `ℂ`: the point at distance `r` from the centre and angle `φ` round from the fixed
direction is `r * exp (φ i)`, that is `(r cos φ, r sin φ)`. Space is `EuclideanSpace ℝ (Fin 3)`:
the point at distance `r`, angle `θ` down from the north pole and angle `φ` round the axis is
`(r sin θ cos φ, r sin θ sin φ, r cos θ)`. `Δ` is Mathlib's Laplacian, the sum of the second
derivatives along an orthonormal basis (`u_xx + u_yy`, or `u_xx + u_yy + u_zz`). A rate in one round
coordinate is the ordinary derivative `deriv` along that coordinate with the others held fixed.
"Away from the coordinate gaps" is `0 < r`, and `0 < θ < π` off the poles. The settled temperature
is twice continuously differentiable round the point (`ContDiffAt ℝ 2`), so its Laplacian is the
classical one. -/

open InnerProductSpace Laplacian Real

/-- Second derivative of `u` along a curve, by the chain rule. -/
theorem curve_second_deriv {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {u : E → ℝ} {γ γ' : ℝ → E} {γ'' : E} {t₀ : ℝ}
    (hγ : ∀ t, HasDerivAt γ (γ' t) t) (hγ' : HasDerivAt γ' γ'' t₀)
    (hu : ContDiffAt ℝ 2 u (γ t₀)) :
    deriv (fun s => u (γ s)) t₀ = fderiv ℝ u (γ t₀) (γ' t₀) ∧
    HasDerivAt (fun t => deriv (fun s => u (γ s)) t)
      (fderiv ℝ (fderiv ℝ u) (γ t₀) (γ' t₀) (γ' t₀) + fderiv ℝ u (γ t₀) γ'') t₀ := by
  have hev : ∀ᶠ t in nhds t₀, DifferentiableAt ℝ u (γ t) := by
    have h1 := hu.eventually (by decide)
    have h2 : Filter.Tendsto γ (nhds t₀) (nhds (γ t₀)) := (hγ t₀).continuousAt.tendsto
    exact (h2.eventually h1).mono fun t ht => ht.differentiableAt (by norm_num)
  have heq : ∀ᶠ t in nhds t₀, deriv (fun s => u (γ s)) t = fderiv ℝ u (γ t) (γ' t) := by
    filter_upwards [hev] with t ht
    exact (ht.hasFDerivAt.comp_hasDerivAt t (hγ t)).deriv
  refine ⟨heq.self_of_nhds, ?_⟩
  have hd : DifferentiableAt ℝ (fderiv ℝ u) (γ t₀) :=
    (hu.fderiv_right (m := 1) (by norm_num)).differentiableAt (by norm_num)
  have hc : HasDerivAt (fun t => fderiv ℝ u (γ t))
      (fderiv ℝ (fderiv ℝ u) (γ t₀) (γ' t₀)) t₀ :=
    hd.hasFDerivAt.comp_hasDerivAt t₀ (hγ t₀)
  exact (hc.clm_apply hγ').congr_of_eventuallyEq heq

/-- A point of space as a combination of the standard unit vectors. -/
theorem euc3_eq (x y z : ℝ) :
    !₂[x, y, z] = x • EuclideanSpace.single (0 : Fin 3) (1 : ℝ) +
      y • EuclideanSpace.single (1 : Fin 3) (1 : ℝ) + z • EuclideanSpace.single (2 : Fin 3) (1 : ℝ) := by
  ext i; fin_cases i <;> simp

/-- A curve in space is differentiable when its three coordinates are. -/
theorem hasDerivAt_euc3 {a b c : ℝ → ℝ} {a' b' c' t : ℝ} (ha : HasDerivAt a a' t)
    (hb : HasDerivAt b b' t) (hc : HasDerivAt c c' t) :
    HasDerivAt (fun t => !₂[a t, b t, c t]) !₂[a', b', c'] t := by
  simp only [euc3_eq]
  exact ((ha.smul_const _).add (hb.smul_const _)).add (hc.smul_const _)

#print axioms curve_second_deriv
#print axioms euc3_eq
#print axioms hasDerivAt_euc3

/-- The Laplacian in polar coordinates. At a point at distance `r > 0` from the centre and angle `φ`,
the Laplacian of a twice continuously differentiable `u` is one over `r` times the rate in `r` of
`r` times the radial slope, plus the second rate round the circle divided by `r²`:
`Δu = (1/r) ∂_r (r ∂_r u) + (1/r²) ∂²_φ u`. -/
theorem laplacian_in_polar_coordinates {u : ℂ → ℝ} {r φ : ℝ} (hr : 0 < r)
    (hu : ContDiffAt ℝ 2 u ((r : ℂ) * Complex.exp ((φ : ℂ) * Complex.I))) :
    Δ u ((r : ℂ) * Complex.exp ((φ : ℂ) * Complex.I)) =
      (1 / r) * deriv (fun ρ : ℝ => ρ *
          deriv (fun s : ℝ => u ((s : ℂ) * Complex.exp ((φ : ℂ) * Complex.I))) ρ) r +
        (1 / r ^ 2) * deriv (fun ψ : ℝ =>
          deriv (fun t : ℝ => u ((r : ℂ) * Complex.exp ((t : ℂ) * Complex.I))) ψ) φ := by
  have hE : ∀ t : ℝ, HasDerivAt (fun t : ℝ => Complex.exp ((t : ℂ) * Complex.I))
      (Complex.exp ((t : ℂ) * Complex.I) * Complex.I) t := by
    intro t
    simpa using ((hasDerivAt_id t).ofReal_comp.mul_const Complex.I).cexp
  -- radial curve
  have hγ1 : ∀ s : ℝ, HasDerivAt (fun s : ℝ => (s : ℂ) * Complex.exp ((φ : ℂ) * Complex.I))
      ((fun _ : ℝ => Complex.exp ((φ : ℂ) * Complex.I)) s) s := by
    intro s
    simpa using (hasDerivAt_id s).ofReal_comp.mul_const (Complex.exp ((φ : ℂ) * Complex.I))
  obtain ⟨R1, R2⟩ := curve_second_deriv (u := u) hγ1 (hasDerivAt_const r _) hu
  -- angular curve
  have hγ2 : ∀ t : ℝ, HasDerivAt (fun t : ℝ => (r : ℂ) * Complex.exp ((t : ℂ) * Complex.I))
      ((fun t : ℝ => (r : ℂ) * (Complex.exp ((t : ℂ) * Complex.I) * Complex.I)) t) t :=
    fun t => (hE t).const_mul _
  have hγ2' : HasDerivAt (fun t : ℝ => (r : ℂ) * (Complex.exp ((t : ℂ) * Complex.I) * Complex.I))
      ((r : ℂ) * (Complex.exp ((φ : ℂ) * Complex.I) * Complex.I * Complex.I)) φ :=
    ((hE φ).mul_const Complex.I).const_mul _
  obtain ⟨A1, A2⟩ := curve_second_deriv (u := u) hγ2 hγ2' hu
  have hrad : HasDerivAt (fun ρ : ℝ => ρ *
      deriv (fun s : ℝ => u ((s : ℂ) * Complex.exp ((φ : ℂ) * Complex.I))) ρ) _ r :=
    (hasDerivAt_id' r).mul R2
  rw [hrad.deriv, A2.deriv, R1]
  simp only [laplacian_eq_iteratedFDeriv_complexPlane, iteratedFDeriv_two_apply]
  have e1 : Complex.exp ((φ : ℂ) * Complex.I) = cos φ • (1 : ℂ) + sin φ • Complex.I := by
    apply Complex.ext <;> simp [Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im, Complex.cos_ofReal_re, Complex.sin_ofReal_re]
  have e2 : (r : ℂ) * (Complex.exp ((φ : ℂ) * Complex.I) * Complex.I) =
      (r * -sin φ) • (1 : ℂ) + (r * cos φ) • Complex.I := by
    apply Complex.ext <;> simp [Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im, Complex.cos_ofReal_re, Complex.sin_ofReal_re]
  have e3 : (r : ℂ) * (Complex.exp ((φ : ℂ) * Complex.I) * Complex.I * Complex.I) =
      (-r * cos φ) • (1 : ℂ) + (-r * sin φ) • Complex.I := by
    apply Complex.ext <;> simp [Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im, Complex.cos_ofReal_re, Complex.sin_ofReal_re]
  generalize (r : ℂ) * Complex.exp ((φ : ℂ) * Complex.I) = P
  rw [e2, e3, e1]
  generalize fderiv ℝ (fderiv ℝ u) P = D2
  generalize fderiv ℝ u P = D1
  simp only [map_add, map_smul, _root_.add_apply, FunLike.coe_smul, Pi.smul_apply,
    smul_eq_mul, map_zero, Fin.isValue, Matrix.cons_val_zero, Matrix.cons_val_one]
  field_simp
  linear_combination (-r * (D2 1 1 + D2 Complex.I Complex.I)) * sin_sq_add_cos_sq φ

/-- The Laplacian in spherical coordinates. At a point at distance `r > 0` from the centre, angle
`θ` down from the north pole with `0 < θ < π` (off the poles) and angle `φ` round the axis, the
Laplacian of a twice continuously differentiable `u` is the radial part
`(1/r²) ∂_r (r² ∂_r u)` plus the sphere's Laplacian `Δ_S u` over `r²`, where
`Δ_S u = (1/sin θ) ∂_θ (sin θ ∂_θ u) + (1/sin² θ) ∂²_φ u`. -/
theorem laplacian_in_spherical_coordinates {u : EuclideanSpace ℝ (Fin 3) → ℝ} {r θ φ : ℝ}
    (hr : 0 < r) (hθ₀ : 0 < θ) (hθπ : θ < π)
    (hu : ContDiffAt ℝ 2 u !₂[r * sin θ * cos φ, r * sin θ * sin φ, r * cos θ]) :
    Δ u !₂[r * sin θ * cos φ, r * sin θ * sin φ, r * cos θ] =
      (1 / r ^ 2) * deriv (fun ρ : ℝ => ρ ^ 2 *
          deriv (fun s : ℝ => u !₂[s * sin θ * cos φ, s * sin θ * sin φ, s * cos θ]) ρ) r +
        (1 / r ^ 2) *
          ((1 / sin θ) * deriv (fun α : ℝ => sin α *
              deriv (fun t : ℝ => u !₂[r * sin t * cos φ, r * sin t * sin φ, r * cos t]) α) θ +
            (1 / sin θ ^ 2) * deriv (fun ψ : ℝ =>
              deriv (fun t : ℝ => u !₂[r * sin θ * cos t, r * sin θ * sin t, r * cos θ]) ψ) φ) := by
  have hs : 0 < sin θ := sin_pos_of_pos_of_lt_pi hθ₀ hθπ
  -- radial curve
  have hγ1 : ∀ s : ℝ, HasDerivAt (fun s : ℝ => !₂[s * sin θ * cos φ, s * sin θ * sin φ, s * cos θ])
      ((fun _ : ℝ => !₂[sin θ * cos φ, sin θ * sin φ, cos θ]) s) s := by
    intro s
    refine hasDerivAt_euc3 ?_ ?_ ?_
    · simpa using ((hasDerivAt_id' s).mul_const (sin θ)).mul_const (cos φ)
    · simpa using ((hasDerivAt_id' s).mul_const (sin θ)).mul_const (sin φ)
    · simpa using (hasDerivAt_id' s).mul_const (cos θ)
  obtain ⟨R1, R2⟩ := curve_second_deriv (u := u) hγ1 (hasDerivAt_const r _) hu
  -- polar-angle curve
  have hγ2 : ∀ t : ℝ, HasDerivAt (fun t : ℝ => !₂[r * sin t * cos φ, r * sin t * sin φ, r * cos t])
      ((fun t : ℝ => !₂[r * cos t * cos φ, r * cos t * sin φ, -(r * sin t)]) t) t := by
    intro t
    refine hasDerivAt_euc3 ?_ ?_ ?_
    · exact ((hasDerivAt_sin t).const_mul r).mul_const (cos φ)
    · exact ((hasDerivAt_sin t).const_mul r).mul_const (sin φ)
    · simpa using (hasDerivAt_cos t).const_mul r
  have hγ2' : HasDerivAt (fun t : ℝ => !₂[r * cos t * cos φ, r * cos t * sin φ, -(r * sin t)])
      !₂[-(r * sin θ * cos φ), -(r * sin θ * sin φ), -(r * cos θ)] θ := by
    refine hasDerivAt_euc3 ?_ ?_ ?_
    · simpa using ((hasDerivAt_cos θ).const_mul r).mul_const (cos φ)
    · simpa using ((hasDerivAt_cos θ).const_mul r).mul_const (sin φ)
    · exact ((hasDerivAt_sin θ).const_mul r).neg
  obtain ⟨A1, A2⟩ := curve_second_deriv (u := u) hγ2 hγ2' hu
  -- azimuth curve
  have hγ3 : ∀ t : ℝ, HasDerivAt (fun t : ℝ => !₂[r * sin θ * cos t, r * sin θ * sin t, r * cos θ])
      ((fun t : ℝ => !₂[-(r * sin θ * sin t), r * sin θ * cos t, 0]) t) t := by
    intro t
    refine hasDerivAt_euc3 ?_ ?_ ?_
    · simpa using (hasDerivAt_cos t).const_mul (r * sin θ)
    · exact (hasDerivAt_sin t).const_mul (r * sin θ)
    · exact hasDerivAt_const t _
  have hγ3' : HasDerivAt (fun t : ℝ => !₂[-(r * sin θ * sin t), r * sin θ * cos t, 0])
      !₂[-(r * sin θ * cos φ), -(r * sin θ * sin φ), 0] φ := by
    refine hasDerivAt_euc3 ?_ ?_ ?_
    · exact ((hasDerivAt_sin φ).const_mul (r * sin θ)).neg
    · simpa using (hasDerivAt_cos φ).const_mul (r * sin θ)
    · exact hasDerivAt_const φ _
  obtain ⟨B1, B2⟩ := curve_second_deriv (u := u) hγ3 hγ3' hu
  have hrad : HasDerivAt (fun ρ : ℝ => ρ ^ 2 *
      deriv (fun s : ℝ => u !₂[s * sin θ * cos φ, s * sin θ * sin φ, s * cos θ]) ρ) _ r :=
    (hasDerivAt_pow 2 r).mul R2
  have hpol : HasDerivAt (fun α : ℝ => sin α *
      deriv (fun t : ℝ => u !₂[r * sin t * cos φ, r * sin t * sin φ, r * cos t]) α) _ θ :=
    (hasDerivAt_sin θ).mul A2
  rw [hrad.deriv, hpol.deriv, B2.deriv, R1, A1]
  rw [laplacian_eq_iteratedFDeriv_orthonormalBasis u (EuclideanSpace.basisFun (Fin 3) ℝ)]
  simp only [Fin.sum_univ_three, EuclideanSpace.basisFun_apply, iteratedFDeriv_two_apply,
    Fin.isValue, Matrix.cons_val_zero, Matrix.cons_val_one]
  have v1 : !₂[r * cos θ * cos φ, r * cos θ * sin φ, -(r * sin θ)] =
      r • !₂[cos θ * cos φ, cos θ * sin φ, -sin θ] := by
    ext i; fin_cases i <;> simp <;> ring
  have v2 : !₂[-(r * sin θ * cos φ), -(r * sin θ * sin φ), -(r * cos θ)] =
      (-r) • !₂[sin θ * cos φ, sin θ * sin φ, cos θ] := by
    ext i; fin_cases i <;> simp <;> ring
  have v3 : !₂[-(r * sin θ * sin φ), r * sin θ * cos φ, 0] =
      (r * sin θ) • !₂[-sin φ, cos φ, 0] := by
    ext i; fin_cases i <;> simp
  have v4 : !₂[-(r * sin θ * cos φ), -(r * sin θ * sin φ), 0] =
      (-(r * sin θ * sin θ)) • !₂[sin θ * cos φ, sin θ * sin φ, cos θ] +
        (-(r * sin θ * cos θ)) • !₂[cos θ * cos φ, cos θ * sin φ, -sin θ] := by
    ext i; fin_cases i <;> simp
    · linear_combination (r * sin θ * cos φ) * sin_sq_add_cos_sq θ
    · linear_combination (r * sin θ * sin φ) * sin_sq_add_cos_sq θ
    · ring
  generalize !₂[r * sin θ * cos φ, r * sin θ * sin φ, r * cos θ] = P
  rw [v1, v2, v3, v4]
  generalize fderiv ℝ (fderiv ℝ u) P = D2
  generalize fderiv ℝ u P = D1
  have htr : D2 (EuclideanSpace.single 0 1) (EuclideanSpace.single 0 1) +
      D2 (EuclideanSpace.single 1 1) (EuclideanSpace.single 1 1) +
      D2 (EuclideanSpace.single 2 1) (EuclideanSpace.single 2 1) =
      D2 !₂[sin θ * cos φ, sin θ * sin φ, cos θ] !₂[sin θ * cos φ, sin θ * sin φ, cos θ] +
      D2 !₂[cos θ * cos φ, cos θ * sin φ, -sin θ] !₂[cos θ * cos φ, cos θ * sin φ, -sin θ] +
      D2 !₂[-sin φ, cos φ, 0] !₂[-sin φ, cos φ, 0] := by
    simp only [euc3_eq, map_add, map_smul, _root_.add_apply, FunLike.coe_smul, Pi.smul_apply,
      smul_eq_mul, zero_smul, add_zero]
    set e0 := (EuclideanSpace.single (0 : Fin 3) (1 : ℝ))
    set e1 := (EuclideanSpace.single (1 : Fin 3) (1 : ℝ))
    set e2 := (EuclideanSpace.single (2 : Fin 3) (1 : ℝ))
    linear_combination (-(D2 e0 e0 * cos φ ^ 2 + D2 e1 e1 * sin φ ^ 2 + D2 e2 e2 +
      (D2 e0 e1 + D2 e1 e0) * cos φ * sin φ)) * sin_sq_add_cos_sq θ +
      (-(D2 e0 e0 + D2 e1 e1)) * sin_sq_add_cos_sq φ
  rw [htr]
  simp only [map_add, map_smul, FunLike.coe_smul, Pi.smul_apply,
    smul_eq_mul, map_zero]
  field_simp
  ring

/-- The radial powers of the round modes. A mode with `m` waves round a circle needs a radial
factor `F` with `r (r F')' = m² F`; with `n(n+1)` from a degree-`n` pattern on a sphere it needs
`(r² F')' = n(n+1) F`. Trying a power `F = r^k` at any radius `r > 0`, the plane's equation holds
exactly when `k = m` or `k = −m`, and the sphere's exactly when `k = n` or `k = −(n+1)`. -/
theorem radial_powers_of_round_modes (m n : ℕ) {k r : ℝ} (hr : 0 < r) :
    (r * deriv (fun s : ℝ => s * deriv (fun t : ℝ => t ^ k) s) r = (m : ℝ) ^ 2 * r ^ k ↔
        k = m ∨ k = -(m : ℝ)) ∧
      (deriv (fun s : ℝ => s ^ 2 * deriv (fun t : ℝ => t ^ k) s) r =
          (n : ℝ) * (n + 1) * r ^ k ↔ k = n ∨ k = -((n : ℝ) + 1)) := by
  simp only [Real.deriv_rpow_const]
  have hpos : 0 < r ^ k := Real.rpow_pos_of_pos hr k
  have hev : ∀ᶠ s in nhds r, 0 < s := lt_mem_nhds hr
  have e1 : (fun s : ℝ => s * (k * s ^ (k - 1))) =ᶠ[nhds r] fun s => k * s ^ k := by
    filter_upwards [hev] with s hs
    rw [Real.rpow_sub_one hs.ne']; field_simp
  have e2 : (fun s : ℝ => s ^ 2 * (k * s ^ (k - 1))) =ᶠ[nhds r] fun s => k * s ^ (k + 1) := by
    filter_upwards [hev] with s hs
    rw [Real.rpow_sub_one hs.ne', Real.rpow_add_one hs.ne']; field_simp
  have d1 : deriv (fun s : ℝ => s * (k * s ^ (k - 1))) r = k * (k * r ^ (k - 1)) := by
    rw [e1.deriv_eq]
    exact ((Real.hasDerivAt_rpow_const (Or.inl hr.ne')).const_mul k).deriv
  have d2 : deriv (fun s : ℝ => s ^ 2 * (k * s ^ (k - 1))) r = k * ((k + 1) * r ^ (k + 1 - 1)) := by
    rw [e2.deriv_eq]
    exact ((Real.hasDerivAt_rpow_const (Or.inl hr.ne')).const_mul k).deriv
  rw [d1, d2, add_sub_cancel_right, Real.rpow_sub_one hr.ne']
  constructor
  · constructor
    · intro h
      have h' : (k - m) * (k + m) * r ^ k = 0 := by
        have := mul_div_cancel₀ (r ^ k) hr.ne'
        linear_combination h - k ^ 2 * this
      rcases mul_eq_zero.1 h' with h'' | h''
      · rcases mul_eq_zero.1 h'' with h3 | h3
        · left; linarith
        · right; linarith
      · exact absurd h'' hpos.ne'
    · rintro (rfl | rfl) <;> field_simp
  · constructor
    · intro h
      have h' : (k - n) * (k + n + 1) * r ^ k = 0 := by linear_combination h
      rcases mul_eq_zero.1 h' with h'' | h''
      · rcases mul_eq_zero.1 h'' with h3 | h3
        · left; linarith
        · right; linarith
      · exact absurd h'' hpos.ne'
    · rintro (rfl | rfl) <;> ring

-- The drum lid, rim 30 + 12 cos φ + 4 cos 2φ °C, radius R = 0.30 m, read at r/R = 1/2.
-- The rim on the hot side, φ = 0: 46 °C.
example : (30 : ℝ) + 12 * cos 0 + 4 * cos (2 * 0) = 46 := by norm_num
-- The rim's coolest point, at cos φ = −3/4 (cos 2φ = 2 cos² φ − 1): 21.5 °C = 43/2 °C.
example : (30 : ℚ) + 12 * (-3 / 4) + 4 * (2 * (-3 / 4) ^ 2 - 1) = 43 / 2 := by norm_num
-- The centre sees only the rim's mean: 30 °C.
example : (30 : ℝ) + 12 * 0 * cos 0 + 4 * 0 ^ 2 * cos (2 * 0) = 30 := by norm_num
-- Halfway to the hot side: 30 + 12 × 1/2 × cos 0 + 4 × (1/2)² × cos 0 = 37 °C.
example : (30 : ℝ) + 12 * (1 / 2) * cos 0 + 4 * (1 / 2) ^ 2 * cos (2 * 0) = 37 := by norm_num
-- Halfway, a quarter turn round: 30 + 12 × 1/2 × cos 90° + 4 × 1/4 × cos 180° = 29 °C.
example : (30 : ℝ) + 12 * (1 / 2) * cos (π / 2) + 4 * (1 / 2) ^ 2 * cos (2 * (π / 2)) = 29 := by
  norm_num [mul_div_cancel₀ π (two_ne_zero' ℝ)]
-- The midrange guess, (46 + 21.5)/2 = 33.75 °C = 135/4 °C, not the centre's 30 °C.
example : ((46 : ℚ) + 43 / 2) / 2 = 135 / 4 := by norm_num
-- The ball, halfway on the axis (P₁(1) = 1, P₂(1) = 1): 37 °C; halfway on the equator
-- (P₁(0) = 0, P₂(0) = −1/2): 29.5 °C = 59/2 °C.
example : (30 : ℚ) + 12 * (1 / 2) * 1 + 4 * (1 / 2) ^ 2 * 1 = 37 := by norm_num
example : (30 : ℚ) + 12 * (1 / 2) * 0 + 4 * (1 / 2) ^ 2 * (-1 / 2) = 59 / 2 := by norm_num
-- P₂¹(0.6) = 3 × 0.6 × 0.8 = 1.44 = 36/25.
example : (3 : ℚ) * (3 / 5) * (4 / 5) = 36 / 25 := by norm_num
-- Degree 2 on a sphere: k(k+1) = 6 for k = 2 and for k = −3; the plane's two-wave mode: k² = 4 for k = ±2.
example : (2 : ℤ) * (2 + 1) = 6 ∧ (-3 : ℤ) * (-3 + 1) = 6 := by norm_num
example : (2 : ℤ) ^ 2 = 4 ∧ (-2 : ℤ) ^ 2 = 4 := by norm_num
-- Outside, at twice the radius: degree 1 keeps 1/2 round a disc, 1/4 round a ball;
-- degree 2 keeps 1/4 and 1/8.
example : ((1 : ℚ) / 2) ^ 1 = 1 / 2 ∧ ((1 : ℚ) / 2) ^ (1 + 1) = 1 / 4 ∧
    ((1 : ℚ) / 2) ^ 2 = 1 / 4 ∧ ((1 : ℚ) / 2) ^ (2 + 1) = 1 / 8 := by norm_num

#print axioms laplacian_in_polar_coordinates
#print axioms laplacian_in_spherical_coordinates
#print axioms radial_powers_of_round_modes
