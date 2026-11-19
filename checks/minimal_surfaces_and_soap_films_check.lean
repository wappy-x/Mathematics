-- Minimal surface: the catenoid, a hanging-chain curve a cosh(z/a) spun round an axis, has zero mean curvature and negative Gaussian curvature -a^2/rho^4 at every point, and pushing a film a distance eps*phi along its normal changes its area element at the rate -2 H phi.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Analysis.Calculus.Deriv.Pi
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.FinCases

/-! A patch `r u v` names a surface point in space, `Fin 3 → ℝ`, by two grid numbers `u`, `v`.
`u ⨯₃ v` is Mathlib's cross product and `u ⬝ᵥ v` its dot product. Every quantity below is
computed from the patch alone, by Mathlib's derivative `deriv`, as the card's formulas say:
`r_u`, `r_v` and the second derivatives, the unit normal `n = (r_u × r_v)/|r_u × r_v|`, the
first fundamental form `E, F, G`, the second fundamental form `L, M, N`, and from them the
mean curvature `H` and the Gaussian curvature `K`. -/

open Real Matrix

/-- `r_u`: how the point moves per unit step of the first grid number. -/
noncomputable def partialU (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : Fin 3 → ℝ :=
  deriv (fun s => r s v) u

/-- `r_v`: how the point moves per unit step of the second grid number. -/
noncomputable def partialV (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : Fin 3 → ℝ :=
  deriv (fun t => r u t) v

/-- The unit normal `n = (r_u × r_v) / |r_u × r_v|`. -/
noncomputable def unitNormal (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : Fin 3 → ℝ :=
  (√((partialU r u v ⨯₃ partialV r u v) ⬝ᵥ (partialU r u v ⨯₃ partialV r u v)))⁻¹ •
    (partialU r u v ⨯₃ partialV r u v)

/-- First fundamental form: `E = r_u · r_u`. -/
noncomputable def formE (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : ℝ := partialU r u v ⬝ᵥ partialU r u v
/-- First fundamental form: `F = r_u · r_v`. -/
noncomputable def formF (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : ℝ := partialU r u v ⬝ᵥ partialV r u v
/-- First fundamental form: `G = r_v · r_v`. -/
noncomputable def formG (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : ℝ := partialV r u v ⬝ᵥ partialV r u v
/-- Second fundamental form: `L = r_uu · n`. -/
noncomputable def formL (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : ℝ :=
  partialU (partialU r) u v ⬝ᵥ unitNormal r u v
/-- Second fundamental form: `M = r_uv · n`. -/
noncomputable def formM (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : ℝ :=
  partialV (partialU r) u v ⬝ᵥ unitNormal r u v
/-- Second fundamental form: `N = r_vv · n`. -/
noncomputable def formN (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : ℝ :=
  partialV (partialV r) u v ⬝ᵥ unitNormal r u v

/-- The card's mean curvature `H = (EN − 2FM + GL) / (2(EG − F²))`, the average of the two
principal curvatures. -/
noncomputable def meanCurvature (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : ℝ :=
  (formE r u v * formN r u v - 2 * formF r u v * formM r u v + formG r u v * formL r u v) /
    (2 * (formE r u v * formG r u v - formF r u v ^ 2))

/-- The card's Gaussian curvature `K = (LN − M²) / (EG − F²)`, the product of the two
principal curvatures. -/
noncomputable def gaussCurvature (r : ℝ → ℝ → Fin 3 → ℝ) (u v : ℝ) : ℝ :=
  (formL r u v * formN r u v - formM r u v ^ 2) / (formE r u v * formG r u v - formF r u v ^ 2)

/-- The catenoid with waist radius `a`, in the card's chart 1:
`r(z, θ) = (ρ cos θ, ρ sin θ, z)` with `ρ = a cosh(z/a)`, the hanging-chain curve spun round
the axis. -/
noncomputable def catenoid (a : ℝ) (z θ : ℝ) : Fin 3 → ℝ :=
  ![a * cosh (z / a) * cos θ, a * cosh (z / a) * sin θ, z]


/-- Derivative of a three-component vector function, component by component. -/
theorem vec3_hasDerivAt {f g h : ℝ → ℝ} {f' g' h' x : ℝ} (hf : HasDerivAt f f' x)
    (hg : HasDerivAt g g' x) (hh : HasDerivAt h h' x) :
    HasDerivAt (fun s => ![f s, g s, h s]) ![f', g', h'] x := by
  rw [hasDerivAt_pi]
  intro i
  fin_cases i <;> simpa

/-- The catenoid's `r_z`. -/
theorem catenoid_partialU (a : ℝ) (ha : a ≠ 0) (z θ : ℝ) :
    partialU (catenoid a) z θ = ![sinh (z / a) * cos θ, sinh (z / a) * sin θ, 1] := by
  unfold partialU catenoid
  have hz : HasDerivAt (fun s : ℝ => s / a) (1 / a) z := (hasDerivAt_id z).div_const a
  have hc : HasDerivAt (fun s : ℝ => a * cosh (s / a)) (sinh (z / a)) z := by
    have := (hz.cosh).const_mul a
    convert this using 1
    field_simp
  refine (vec3_hasDerivAt (hc.mul_const (cos θ)) (hc.mul_const (sin θ)) (hasDerivAt_id z)).deriv

/-- The catenoid's `r_θ`. -/
theorem catenoid_partialV (a : ℝ) (z θ : ℝ) :
    partialV (catenoid a) z θ = ![-(a * cosh (z / a) * sin θ), a * cosh (z / a) * cos θ, 0] := by
  unfold partialV catenoid
  refine (vec3_hasDerivAt ((hasDerivAt_cos θ).const_mul (a * cosh (z / a)))
    ((hasDerivAt_sin θ).const_mul (a * cosh (z / a))) (hasDerivAt_const θ z)).deriv.trans ?_
  ext i; fin_cases i <;> simp

/-- The catenoid's `r_zz`. -/
theorem catenoid_partialUU (a : ℝ) (ha : a ≠ 0) (z θ : ℝ) :
    partialU (partialU (catenoid a)) z θ =
      ![cosh (z / a) / a * cos θ, cosh (z / a) / a * sin θ, 0] := by
  unfold partialU
  have e : (fun s => deriv (fun s' => catenoid a s' θ) s) =
      fun s => ![sinh (s / a) * cos θ, sinh (s / a) * sin θ, 1] := by
    funext s; exact catenoid_partialU a ha s θ
  rw [e]
  have hz : HasDerivAt (fun s : ℝ => s / a) (1 / a) z := (hasDerivAt_id z).div_const a
  have hs : HasDerivAt (fun s : ℝ => sinh (s / a)) (cosh (z / a) / a) z := by
    convert hz.sinh using 1; ring
  exact (vec3_hasDerivAt (hs.mul_const (cos θ)) (hs.mul_const (sin θ))
    (hasDerivAt_const z 1)).deriv

/-- The catenoid's `r_zθ`. -/
theorem catenoid_partialUV (a : ℝ) (ha : a ≠ 0) (z θ : ℝ) :
    partialV (partialU (catenoid a)) z θ =
      ![-(sinh (z / a) * sin θ), sinh (z / a) * cos θ, 0] := by
  unfold partialV
  have e : (fun t => partialU (catenoid a) z t) =
      fun t => ![sinh (z / a) * cos t, sinh (z / a) * sin t, 1] := by
    funext t; exact catenoid_partialU a ha z t
  rw [e]
  refine (vec3_hasDerivAt ((hasDerivAt_cos θ).const_mul (sinh (z / a)))
    ((hasDerivAt_sin θ).const_mul (sinh (z / a))) (hasDerivAt_const θ 1)).deriv.trans ?_
  ext i; fin_cases i <;> simp

/-- The catenoid's `r_θθ`. -/
theorem catenoid_partialVV (a : ℝ) (z θ : ℝ) :
    partialV (partialV (catenoid a)) z θ =
      ![-(a * cosh (z / a) * cos θ), -(a * cosh (z / a) * sin θ), 0] := by
  unfold partialV
  have e : (fun t => deriv (fun t' => catenoid a z t') t) =
      fun t => ![-(a * cosh (z / a) * sin t), a * cosh (z / a) * cos t, 0] := by
    funext t; exact catenoid_partialV a z t
  rw [e]
  refine (vec3_hasDerivAt ((hasDerivAt_sin θ).const_mul (a * cosh (z / a))).neg
    ((hasDerivAt_cos θ).const_mul (a * cosh (z / a))) (hasDerivAt_const θ 0)).deriv.trans ?_
  ext i; fin_cases i <;> simp

/-- The catenoid's unit normal. -/
theorem catenoid_unitNormal (a : ℝ) (ha : 0 < a) (z θ : ℝ) :
    unitNormal (catenoid a) z θ =
      ![-(cos θ / cosh (z / a)), -(sin θ / cosh (z / a)), sinh (z / a) / cosh (z / a)] := by
  have hc : 0 < cosh (z / a) := cosh_pos _
  have hcross : partialU (catenoid a) z θ ⨯₃ partialV (catenoid a) z θ =
      ![-(a * cosh (z / a) * cos θ), -(a * cosh (z / a) * sin θ),
        a * cosh (z / a) * sinh (z / a)] := by
    rw [catenoid_partialU a ha.ne', catenoid_partialV, cross_apply]
    ext i; fin_cases i
    · simp
    · simp
    · simp
      linear_combination (a * cosh (z / a) * sinh (z / a)) * sin_sq_add_cos_sq θ
  have hdot : (partialU (catenoid a) z θ ⨯₃ partialV (catenoid a) z θ) ⬝ᵥ
      (partialU (catenoid a) z θ ⨯₃ partialV (catenoid a) z θ) = (a * cosh (z / a) ^ 2) ^ 2 := by
    rw [hcross]
    simp [dotProduct, Fin.sum_univ_three]
    have h1 := sin_sq_add_cos_sq θ
    have h2 := cosh_sq (z / a)
    linear_combination (a * cosh (z / a)) ^ 2 * h1 - (a ^ 2 * cosh (z / a) ^ 2) * h2
  unfold unitNormal
  rw [hdot, sqrt_sq (by positivity), hcross]
  ext i; fin_cases i <;> simp <;> field_simp


/-- The catenoid's six form coefficients: `E = cosh²`, `F = 0`, `G = a² cosh²`,
`L = −1/a`, `M = 0`, `N = a`. -/
theorem catenoid_forms (a : ℝ) (ha : 0 < a) (z θ : ℝ) :
    formE (catenoid a) z θ = cosh (z / a) ^ 2 ∧ formF (catenoid a) z θ = 0 ∧
    formG (catenoid a) z θ = a ^ 2 * cosh (z / a) ^ 2 ∧ formL (catenoid a) z θ = -1 / a ∧
    formM (catenoid a) z θ = 0 ∧ formN (catenoid a) z θ = a := by
  have hc : cosh (z / a) ≠ 0 := (cosh_pos _).ne'
  have h1 := sin_sq_add_cos_sq θ
  have h2 := cosh_sq (z / a)
  unfold formE formF formG formL formM formN
  rw [catenoid_partialU a ha.ne', catenoid_partialV, catenoid_partialUU a ha.ne',
    catenoid_partialUV a ha.ne', catenoid_partialVV, catenoid_unitNormal a ha]
  simp only [dotProduct, Fin.sum_univ_three, Matrix.cons_val_zero, Matrix.cons_val_one,
    Matrix.cons_val_two, Matrix.head_cons, Matrix.tail_cons]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · linear_combination sinh (z / a) ^ 2 * h1 - h2
  · ring
  · linear_combination (a * cosh (z / a)) ^ 2 * h1
  · field_simp
    linear_combination (-cosh (z / a)) * h1
  · field_simp
    ring
  · field_simp
    linear_combination a * cosh (z / a) * h1

/-- **The catenoid is a minimal surface.** For every waist radius `a > 0`, at every point
`(z, θ)` of the catenoid `ρ = a cosh(z/a)`, the mean curvature computed from the patch's own
first and second fundamental forms is zero: the bend round the circle and the bend along the
profile cancel. -/
theorem catenoid_mean_curvature_eq_zero (a : ℝ) (ha : 0 < a) (z θ : ℝ) :
    meanCurvature (catenoid a) z θ = 0 := by
  obtain ⟨hE, hF, hG, hL, hM, hN⟩ := catenoid_forms a ha z θ
  unfold meanCurvature
  rw [hE, hF, hG, hL, hM, hN]
  have hc : cosh (z / a) ≠ 0 := (cosh_pos _).ne'
  field_simp
  ring

/-- **Every point of the catenoid is a saddle.** For every waist radius `a > 0`, the Gaussian
curvature of the catenoid at `(z, θ)` is `K = −a²/ρ⁴` with `ρ = a cosh(z/a)`, negative
everywhere. -/
theorem catenoid_gaussian_curvature (a : ℝ) (ha : 0 < a) (z θ : ℝ) :
    gaussCurvature (catenoid a) z θ = -a ^ 2 / (a * cosh (z / a)) ^ 4 := by
  obtain ⟨hE, hF, hG, hL, hM, hN⟩ := catenoid_forms a ha z θ
  unfold gaussCurvature
  rw [hE, hF, hG, hL, hM, hN]
  have hc : cosh (z / a) ≠ 0 := (cosh_pos _).ne'
  have ha' : a ≠ 0 := ha.ne'
  field_simp
  ring

/-- **The first variation of area, at one point.** Push the surface a distance `ε φ` along its
normal. To first order its forms become `E − 2εφL`, `F − 2εφM`, `G − 2εφN` (the card's
detailed proof). Where `EG − F² > 0`, the area element `√(E_ε G_ε − F_ε²)` then changes at
`ε = 0` at the rate `−2 φ H √(EG − F²)`, with `H = (EN − 2FM + GL)/(2(EG − F²))`. Added over
the surface, this is `dA/dε = −2 ∬ H φ dA`. -/
theorem area_element_first_variation (E F G L M N φ : ℝ) (hW : 0 < E * G - F ^ 2) :
    HasDerivAt
      (fun ε : ℝ => √((E - 2 * ε * φ * L) * (G - 2 * ε * φ * N) - (F - 2 * ε * φ * M) ^ 2))
      (-2 * φ * ((E * N - 2 * F * M + G * L) / (2 * (E * G - F ^ 2))) * √(E * G - F ^ 2)) 0 := by
  have hQ : HasDerivAt
      (fun ε : ℝ => (E - 2 * ε * φ * L) * (G - 2 * ε * φ * N) - (F - 2 * ε * φ * M) ^ 2)
      (-2 * φ * (E * N - 2 * F * M + G * L)) 0 := by
    have hl : ∀ c d : ℝ, HasDerivAt (fun ε : ℝ => c - 2 * ε * φ * d) (-2 * φ * d) 0 := by
      intro c d
      have := ((((hasDerivAt_id (0 : ℝ)).const_mul 2).mul_const φ).mul_const d).const_sub c
      convert this using 1 <;> simp
    have := ((hl E L).mul (hl G N)).sub ((hl F M).pow 2)
    convert this using 1
    simp
    ring
  have hW0 : ((E - 2 * 0 * φ * L) * (G - 2 * 0 * φ * N) - (F - 2 * 0 * φ * M) ^ 2) =
      E * G - F ^ 2 := by ring
  have := hQ.sqrt (by rw [hW0]; exact hW.ne')
  convert this using 1
  rw [hW0]
  have hs : 0 < √(E * G - F ^ 2) := sqrt_pos.mpr hW
  have hss : √(E * G - F ^ 2) * √(E * G - F ^ 2) = E * G - F ^ 2 := mul_self_sqrt hW.le
  field_simp
  rw [sq_sqrt hW.le]

/-! The card's exact worked numbers. -/

-- A 5 cm cylinder bends 1/5 per cm round its circles and 0 along its length: H = 0.1 1/cm.
example : ((1 / 5 + 0) / 2 : ℚ) = 1 / 10 := by norm_num
-- The cylinder on the rings, 2π · 5 · 4 = 125.66 cm², has less area than the two discs, 2π · 5² = 157.08 cm².
example : 2 * π * 5 * 4 < 2 * π * 5 ^ 2 := by
  have := Real.pi_pos; norm_num; linarith
-- Wing 19's saddle f = (x² − y²)/25 has f_xx + f_yy = 2/25 − 2/25 = 0: it satisfies Laplace's equation.
example : (2 / 25 : ℚ) + (-2 / 25) = 0 := by norm_num
-- At the rim point (5, 0), slope f_x = 2/5 and f_y = 0, the minimal surface equation's left side
-- (1 + f_y²) f_xx − 2 f_x f_y f_xy + (1 + f_x²) f_yy is −8/625, not 0, so H ≠ 0 there.
example : (1 + 0 ^ 2) * (2 / 25 : ℚ) - 2 * (2 / 5) * 0 * 0 + (1 + (2 / 5) ^ 2) * (-2 / 25) = -8 / 625 := by
  norm_num
-- A cylinder film with H = 10 1/m at 1/40 N/m per face needs Δp = 4γH = 1 Pa.
example : (4 * (1 / 40) * 10 : ℚ) = 1 := by norm_num
-- The helicoid rising 1 cm per radian has K = −1/(1 + 2²)² = −1/25 1/cm² at 2 cm out.
example : (-1 / (1 + 2 ^ 2) ^ 2 : ℚ) = -1 / 25 := by norm_num

#print axioms vec3_hasDerivAt
#print axioms catenoid_partialU
#print axioms catenoid_partialV
#print axioms catenoid_partialUU
#print axioms catenoid_partialUV
#print axioms catenoid_partialVV
#print axioms catenoid_unitNormal
#print axioms catenoid_forms
#print axioms catenoid_mean_curvature_eq_zero
#print axioms catenoid_gaussian_curvature
#print axioms area_element_first_variation
