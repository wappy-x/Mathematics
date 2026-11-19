-- Sphere, torus and projective plane: the projective plane's three gnomonic sheets change smoothly but cannot keep clockwise, the globe's stereographic change reverses it and the doughnut's angle windows differ by shifts, and no closed surface fits on one chart.
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Topology.OpenPartialHomeomorph.Defs
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.NormNum

open scoped ContDiff

/-- The Jacobian determinant of a map of the plane at `p`, from its table of partial rates:
`∂f₁/∂u₁ · ∂f₂/∂u₂ - ∂f₁/∂u₂ · ∂f₂/∂u₁`. Negative means the map reverses clockwise. -/
noncomputable def jacDet (f : ℝ × ℝ → ℝ × ℝ) (p : ℝ × ℝ) : ℝ :=
  deriv (fun a => (f (a, p.2)).1) p.1 * deriv (fun b => (f (p.1, b)).2) p.2 -
    deriv (fun b => (f (p.1, b)).1) p.2 * deriv (fun a => (f (a, p.2)).2) p.1

/-- A mirror on a chart: `s = 1` leaves it alone, `s = -1` swaps the sign of its second
coordinate. -/
def mirror (s : ℝ) (u : ℝ × ℝ) : ℝ × ℝ := (u.1, s * u.2)

/-- The gnomonic sheet `μ_z` touching the North Pole of the globe of radius `R`: the line
through the centre and `(x, y, z)` meets the plane `z = R` at `R (x/z, y/z)`. -/
noncomputable def gnomZ (R : ℝ) (p : ℝ × ℝ × ℝ) : ℝ × ℝ := (R * p.1 / p.2.2, R * p.2.1 / p.2.2)

/-- The gnomonic sheet `μ_x` touching the equator at longitude 0°: `R (y/x, z/x)`. -/
noncomputable def gnomX (R : ℝ) (p : ℝ × ℝ × ℝ) : ℝ × ℝ := (R * p.2.1 / p.1, R * p.2.2 / p.1)

/-- The inverse of `μ_z`: the reading `(U, V)` is the line through the point `(U, V, R)`. -/
def gnomZInv (R : ℝ) (u : ℝ × ℝ) : ℝ × ℝ × ℝ := (u.1, u.2, R)

/-- Stereographic projection `σ_N` of the globe of radius `R` from the North Pole. -/
noncomputable def stereoN (R : ℝ) (p : ℝ × ℝ × ℝ) : ℝ × ℝ :=
  (R * p.1 / (R - p.2.2), R * p.2.1 / (R - p.2.2))

/-- Stereographic projection `σ_S` of the globe of radius `R` from the South Pole. -/
noncomputable def stereoS (R : ℝ) (p : ℝ × ℝ × ℝ) : ℝ × ℝ :=
  (R * p.1 / (R + p.2.2), R * p.2.1 / (R + p.2.2))

/-- The globe's change of chart `u ↦ R² u / |u|²`. -/
noncomputable def invertSheet (R : ℝ) (u : ℝ × ℝ) : ℝ × ℝ :=
  (R ^ 2 * u.1 / (u.1 ^ 2 + u.2 ^ 2), R ^ 2 * u.2 / (u.1 ^ 2 + u.2 ^ 2))

/-- The doughnut with centre-circle radius `a` and tube radius `b`, at angle `θ = u.1` round the
hole and `ψ = u.2` round the tube. -/
noncomputable def torusPoint (a b : ℝ) (u : ℝ × ℝ) : ℝ × ℝ × ℝ :=
  ((a + b * Real.cos u.2) * Real.cos u.1, (a + b * Real.cos u.2) * Real.sin u.1, b * Real.sin u.2)

/-- The projective change of chart with mirrors, written out. -/
theorem mirrored_change_eq (R sZ sX : ℝ) (v : ℝ × ℝ) :
    mirror sX (gnomX R (gnomZInv R (mirror sZ v))) = (R * (sZ * v.2) / v.1, sX * (R * R / v.1)) := by
  simp [mirror, gnomX, gnomZInv]

/-- Jacobian determinant of the mirrored projective change of chart. -/
theorem jacDet_mirrored (R sZ sX : ℝ) (u : ℝ × ℝ) (hu : u.1 ≠ 0) :
    jacDet (fun v => mirror sX (gnomX R (gnomZInv R (mirror sZ v)))) u =
      sZ * sX * R ^ 3 / u.1 ^ 3 := by
  simp only [jacDet, mirrored_change_eq]
  have h1 : HasDerivAt (fun a : ℝ => R * (sZ * u.2) / a) (-(R * (sZ * u.2)) / u.1 ^ 2) u.1 := by
    have := (hasDerivAt_inv hu).const_mul (R * (sZ * u.2))
    convert this using 1
    · ext a; simp [div_eq_mul_inv]
    · field_simp
  have h2 : HasDerivAt (fun b : ℝ => sX * (R * R / u.1)) 0 u.2 := hasDerivAt_const _ _
  have h3 : HasDerivAt (fun b : ℝ => R * (sZ * b) / u.1) (R * sZ / u.1) u.2 := by
    have := ((hasDerivAt_id u.2).const_mul (R * sZ)).div_const u.1
    convert this using 1
    · ext b; simp; ring
    · simp
  have h4 : HasDerivAt (fun a : ℝ => sX * (R * R / a)) (-(sX * (R * R)) / u.1 ^ 2) u.1 := by
    have := (hasDerivAt_inv hu).const_mul (sX * (R * R))
    convert this using 1
    · ext a; simp [div_eq_mul_inv]; ring
    · field_simp
  rw [h1.deriv, h2.deriv, h3.deriv, h4.deriv]
  field_simp
  ring

/-- Jacobian determinant of the globe's change of chart. -/
theorem jacDet_invertSheet (R : ℝ) (u : ℝ × ℝ) (hu : u.1 ^ 2 + u.2 ^ 2 ≠ 0) :
    jacDet (invertSheet R) u = -R ^ 4 / (u.1 ^ 2 + u.2 ^ 2) ^ 2 := by
  obtain ⟨x, y⟩ := u
  simp only at hu ⊢
  simp only [jacDet, invertSheet]
  have d1 : HasDerivAt (fun a : ℝ => R ^ 2 * a / (a ^ 2 + y ^ 2))
      ((R ^ 2 * 1 * (x ^ 2 + y ^ 2) - R ^ 2 * x * (2 * x)) / (x ^ 2 + y ^ 2) ^ 2) x := by
    have hn : HasDerivAt (fun t : ℝ => R ^ 2 * t) (R ^ 2 * 1) x := (hasDerivAt_id' x).const_mul _
    have hd : HasDerivAt (fun a : ℝ => a ^ 2 + y ^ 2) (2 * x) x := by
      simpa using (hasDerivAt_pow 2 x).add_const (y ^ 2)
    exact hn.div hd hu
  have d2 : HasDerivAt (fun b : ℝ => R ^ 2 * b / (x ^ 2 + b ^ 2))
      ((R ^ 2 * 1 * (x ^ 2 + y ^ 2) - R ^ 2 * y * (2 * y)) / (x ^ 2 + y ^ 2) ^ 2) y := by
    have hn : HasDerivAt (fun t : ℝ => R ^ 2 * t) (R ^ 2 * 1) y := (hasDerivAt_id' y).const_mul _
    have hd : HasDerivAt (fun b : ℝ => x ^ 2 + b ^ 2) (2 * y) y := by
      simpa using (hasDerivAt_pow 2 y).const_add (x ^ 2)
    exact hn.div hd hu
  have d3 : HasDerivAt (fun b : ℝ => R ^ 2 * x / (x ^ 2 + b ^ 2))
      ((0 * (x ^ 2 + y ^ 2) - R ^ 2 * x * (2 * y)) / (x ^ 2 + y ^ 2) ^ 2) y := by
    have hn := hasDerivAt_const y (R ^ 2 * x)
    have hd : HasDerivAt (fun b : ℝ => x ^ 2 + b ^ 2) (2 * y) y := by
      simpa using (hasDerivAt_pow 2 y).const_add (x ^ 2)
    exact hn.div hd hu
  have d4 : HasDerivAt (fun a : ℝ => R ^ 2 * y / (a ^ 2 + y ^ 2))
      ((0 * (x ^ 2 + y ^ 2) - R ^ 2 * y * (2 * x)) / (x ^ 2 + y ^ 2) ^ 2) x := by
    have hn := hasDerivAt_const x (R ^ 2 * y)
    have hd : HasDerivAt (fun a : ℝ => a ^ 2 + y ^ 2) (2 * x) x := by
      simpa using (hasDerivAt_pow 2 x).add_const (y ^ 2)
    exact hn.div hd hu
  rw [d1.deriv, d2.deriv, d3.deriv, d4.deriv]
  field_simp
  ring

/-- On the open window `(-π, π)`, cosine and sine together name each angle once. -/
theorem angle_eq_of_cos_sin_eq {θ θ' : ℝ} (h : θ ∈ Set.Ioo (-Real.pi) Real.pi)
    (h' : θ' ∈ Set.Ioo (-Real.pi) Real.pi) (hc : Real.cos θ = Real.cos θ')
    (hs : Real.sin θ = Real.sin θ') : θ = θ' := by
  have hcos : Real.cos (θ - θ') = 1 := by
    rw [Real.cos_sub, ← hc, ← hs]
    nlinarith [Real.sin_sq_add_cos_sq θ]
  have := (Real.cos_eq_one_iff_of_lt_of_lt (x := θ - θ') (by linarith [h.1, h'.2])
    (by linarith [h.2, h'.1])).1 hcos
  linarith

#print axioms mirrored_change_eq
#print axioms jacDet_mirrored
#print axioms jacDet_invertSheet
#print axioms angle_eq_of_cos_sin_eq

/-- The one-sided sheet's atlas cannot keep clockwise. On the globe of radius `R > 0`, the
gnomonic sheets `μ_z` and `μ_x` read lines through the centre: rescaling a point does not
change its reading, and `μ_z⁻¹(U, V) = (U, V, R)` lies on the line `μ_z` read. Their change of
chart `μ_x ∘ μ_z⁻¹` is `(U, V) ↦ (RV/U, R²/U)`, smooth on the whole overlap `U ≠ 0`, with
Jacobian determinant `R³/U³`. That determinant is positive where `U > 0` and negative where
`U < 0`, so no choice of mirrors on the two sheets makes the change keep clockwise on the
whole overlap. -/
theorem projective_plane_atlas_cannot_keep_clockwise (R : ℝ) (hR : 0 < R) :
    (∀ (c : ℝ) (p : ℝ × ℝ × ℝ), c ≠ 0 → gnomZ R (c • p) = gnomZ R p ∧ gnomX R (c • p) = gnomX R p) ∧
    (∀ p : ℝ × ℝ × ℝ, p.2.2 ≠ 0 → gnomZInv R (gnomZ R p) = (R / p.2.2) • p) ∧
    (∀ u : ℝ × ℝ, gnomX R (gnomZInv R u) = (R * u.2 / u.1, R ^ 2 / u.1)) ∧
    ContDiffOn ℝ ∞ (fun u => gnomX R (gnomZInv R u)) {u | u.1 ≠ 0} ∧
    (∀ u : ℝ × ℝ, u.1 ≠ 0 → jacDet (fun v => gnomX R (gnomZInv R v)) u = R ^ 3 / u.1 ^ 3) ∧
    ¬ ∃ sZ sX : ℝ, (sZ = 1 ∨ sZ = -1) ∧ (sX = 1 ∨ sX = -1) ∧
      ∀ u : ℝ × ℝ, u.1 ≠ 0 →
        0 < jacDet (fun v => mirror sX (gnomX R (gnomZInv R (mirror sZ v)))) u := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro c p hc
    obtain ⟨x, y, z⟩ := p
    simp only [gnomZ, gnomX, Prod.smul_mk, smul_eq_mul]
    refine ⟨Prod.ext ?_ ?_, Prod.ext ?_ ?_⟩ <;> simp only <;>
      rw [mul_left_comm, mul_div_mul_left _ _ hc]
  · intro p hp
    obtain ⟨x, y, z⟩ := p
    simp only at hp
    simp only [gnomZ, gnomZInv, Prod.smul_mk, smul_eq_mul]
    refine Prod.ext ?_ (Prod.ext ?_ ?_) <;> simp only <;> field_simp
  · intro u
    simp [gnomX, gnomZInv, pow_two]
  · have hf : (fun u : ℝ × ℝ => gnomX R (gnomZInv R u)) =
        fun u => (R * u.2 / u.1, R * R / u.1) := by
      funext u; simp [gnomX, gnomZInv]
    rw [hf]
    apply ContDiffOn.prodMk
    · exact (contDiffOn_const.mul contDiff_snd.contDiffOn).div contDiff_fst.contDiffOn
        (fun u hu => hu)
    · exact contDiffOn_const.div contDiff_fst.contDiffOn (fun u hu => hu)
  · intro u hu
    have hf : (fun v : ℝ × ℝ => gnomX R (gnomZInv R v)) =
        fun v => mirror 1 (gnomX R (gnomZInv R (mirror 1 v))) := by
      funext v; simp [mirror]
    rw [hf, jacDet_mirrored R 1 1 u hu]
    ring
  · rintro ⟨sZ, sX, hZ, hX, h⟩
    have hp := h (1, 0) one_ne_zero
    have hn := h (-1, 0) (by norm_num)
    rw [jacDet_mirrored R sZ sX _ one_ne_zero] at hp
    rw [jacDet_mirrored R sZ sX _ (by norm_num)] at hn
    simp only at hp hn
    have hR3 : 0 < R ^ 3 := by positivity
    rcases hZ with rfl | rfl <;> rcases hX with rfl | rfl <;> norm_num at hp hn <;> linarith

/-- The globe and the doughnut. On the globe of radius `R > 0`, a point that is neither pole
reads `σ_S = R² u / |u|²` where `σ_N` reads `u`; that change of chart is smooth on the whole
overlap `u ≠ 0`, and its Jacobian determinant is `-R⁴/|u|⁴`, negative everywhere, so it
reverses clockwise and mirroring one sheet fixes it. On the doughnut with `0 < b < a`, the
angles name each point once in the open window `(-π, π)²`, two windows differ by whole turns
`(2πm, 2πn)`, and that shift has Jacobian determinant 1. -/
theorem globe_and_doughnut_changes_of_chart (R : ℝ) (hR : 0 < R) (a b : ℝ) (hb : 0 < b)
    (hab : b < a) :
    (∀ p : ℝ × ℝ × ℝ, p.1 ^ 2 + p.2.1 ^ 2 + p.2.2 ^ 2 = R ^ 2 → p.2.2 ≠ R → p.2.2 ≠ -R →
      stereoS R p = invertSheet R (stereoN R p)) ∧
    ContDiffOn ℝ ∞ (invertSheet R) {u | u ≠ 0} ∧
    (∀ u : ℝ × ℝ, u ≠ 0 → jacDet (invertSheet R) u = -R ^ 4 / (u.1 ^ 2 + u.2 ^ 2) ^ 2) ∧
    Set.InjOn (torusPoint a b) (Set.Ioo (-Real.pi) Real.pi ×ˢ Set.Ioo (-Real.pi) Real.pi) ∧
    (∀ (m n : ℤ) (u : ℝ × ℝ),
      torusPoint a b (u.1 + 2 * Real.pi * m, u.2 + 2 * Real.pi * n) = torusPoint a b u ∧
      jacDet (fun v => (v.1 + 2 * Real.pi * m, v.2 + 2 * Real.pi * n)) u = 1) := by
  have hR0 : R ≠ 0 := hR.ne'
  have hsq : ∀ u : ℝ × ℝ, u ≠ 0 → u.1 ^ 2 + u.2 ^ 2 ≠ 0 := by
    rintro ⟨x, y⟩ hu h
    apply hu
    have hx : x = 0 := by nlinarith [sq_nonneg x, sq_nonneg y]
    have hy : y = 0 := by nlinarith [sq_nonneg x, sq_nonneg y]
    simp [hx, hy]
  have hpos : ∀ ψ : ℝ, 0 < a + b * Real.cos ψ := by
    intro ψ; nlinarith [Real.neg_one_le_cos ψ]
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · rintro ⟨x, y, z⟩ hs h1 h2
    simp only at hs h1 h2
    have hm : R - z ≠ 0 := sub_ne_zero.mpr (Ne.symm h1)
    have hp : R + z ≠ 0 := by
      intro h; apply h2; linarith
    have hxy : x ^ 2 + y ^ 2 = (R - z) * (R + z) := by linear_combination hs
    have hden : (R * x / (R - z)) ^ 2 + (R * y / (R - z)) ^ 2 = R ^ 2 * (R + z) / (R - z) := by
      rw [div_pow, div_pow, ← add_div, mul_pow, mul_pow, ← mul_add, hxy]
      field_simp
    simp only [stereoS, stereoN, invertSheet]
    rw [hden]
    refine Prod.ext ?_ ?_ <;> simp only <;> field_simp
  · apply ContDiffOn.prodMk
    · exact (contDiffOn_const.mul contDiff_fst.contDiffOn).div
        ((contDiff_fst.pow 2).add (contDiff_snd.pow 2)).contDiffOn (fun u hu => hsq u hu)
    · exact (contDiffOn_const.mul contDiff_snd.contDiffOn).div
        ((contDiff_fst.pow 2).add (contDiff_snd.pow 2)).contDiffOn (fun u hu => hsq u hu)
  · intro u hu
    exact jacDet_invertSheet R u (hsq u hu)
  · rintro ⟨θ, ψ⟩ ⟨hθ, hψ⟩ ⟨θ', ψ'⟩ ⟨hθ', hψ'⟩ heq
    simp only [torusPoint, Prod.mk.injEq] at heq hθ hψ hθ' hψ'
    obtain ⟨e1, e2, e3⟩ := heq
    have r1 := hpos ψ
    have r2 := hpos ψ'
    have hr : a + b * Real.cos ψ = a + b * Real.cos ψ' := by
      have hsq2 : (a + b * Real.cos ψ) ^ 2 = (a + b * Real.cos ψ') ^ 2 := by
        have t1 := Real.sin_sq_add_cos_sq θ
        have t2 := Real.sin_sq_add_cos_sq θ'
        linear_combination ((a + b * Real.cos ψ) * Real.cos θ + (a + b * Real.cos ψ') * Real.cos θ') * e1 +
          ((a + b * Real.cos ψ) * Real.sin θ + (a + b * Real.cos ψ') * Real.sin θ') * e2 -
          (a + b * Real.cos ψ) ^ 2 * t1 + (a + b * Real.cos ψ') ^ 2 * t2
      nlinarith [sq_nonneg (a + b * Real.cos ψ - (a + b * Real.cos ψ'))]
    have hcθ : Real.cos θ = Real.cos θ' := by
      rw [hr] at e1; exact mul_left_cancel₀ r2.ne' e1
    have hsθ : Real.sin θ = Real.sin θ' := by
      rw [hr] at e2; exact mul_left_cancel₀ r2.ne' e2
    have hcψ : Real.cos ψ = Real.cos ψ' := by
      have := hr; have hb0 : b ≠ 0 := hb.ne'
      have : b * Real.cos ψ = b * Real.cos ψ' := by linarith
      exact mul_left_cancel₀ hb0 this
    have hsψ : Real.sin ψ = Real.sin ψ' := mul_left_cancel₀ hb.ne' e3
    rw [angle_eq_of_cos_sin_eq hθ hθ' hcθ hsθ, angle_eq_of_cos_sin_eq hψ hψ' hcψ hsψ]
  · intro m n u
    constructor
    · have h1 : u.1 + 2 * Real.pi * m = u.1 + (m : ℤ) * (2 * Real.pi) := by ring
      have h2 : u.2 + 2 * Real.pi * n = u.2 + (n : ℤ) * (2 * Real.pi) := by ring
      simp only [torusPoint, h1, h2, Real.cos_add_int_mul_two_pi, Real.sin_add_int_mul_two_pi]
    · simp [jacDet]

/-- A closed surface does not fit on one chart. If a space is compact and not empty, no chart
onto an open set of the plane has the whole space as its patch. -/
theorem closed_surface_not_on_one_chart {X : Type*} [TopologicalSpace X] [CompactSpace X]
    [Nonempty X] (φ : OpenPartialHomeomorph X (EuclideanSpace ℝ (Fin 2))) :
    φ.source ≠ Set.univ := by
  intro h
  have hc : IsCompact φ.target := by
    rw [← φ.image_source_eq_target, h]
    exact isCompact_univ.image_of_continuousOn (h ▸ φ.continuousOn)
  have hne : φ.target.Nonempty := by
    obtain ⟨x⟩ := ‹Nonempty X›
    exact ⟨φ x, φ.map_source (h ▸ Set.mem_univ x)⟩
  have huniv : φ.target = Set.univ := IsClopen.eq_univ ⟨hc.isClosed, φ.open_target⟩ hne
  have : CompactSpace (EuclideanSpace ℝ (Fin 2)) := ⟨huniv ▸ hc⟩
  exact not_compactSpace_iff.mpr inferInstance this

-- London on the two stereographic sheets: the distances multiply to R² = 6371 × 6371 km².
example : (6371 : ℕ) * 6371 = 40589641 := by norm_num
-- The sprinkle at θ = 200°, ψ = 300° reads (-160°, -60°) in the first window: one whole turn off.
example : (200 : ℤ) - 360 = -160 ∧ (300 : ℤ) - 360 = -60 := by norm_num
-- Euler counts: octahedron 6 - 12 + 8 = 2; opposite points glued 3 - 6 + 4 = 1;
-- 4 × 4 grid glued 16 - 32 + 16 = 0; the same grid unglued 25 - 40 + 16 = 1.
example : (6 : ℤ) - 12 + 8 = 2 ∧ (3 : ℤ) - 6 + 4 = 1 ∧ (16 : ℤ) - 32 + 16 = 0 ∧
    (25 : ℤ) - 40 + 16 = 1 := by norm_num
-- Mirror choices keeping clockwise: the globe's one change reverses it, so the two sheets must be
-- mirrored differently, 2 of 4; the doughnut's changes all keep it, so all four windows must be
-- mirrored alike, 2 of 16.
example : (Finset.univ.filter fun s : Fin 2 → Bool => s 0 ≠ s 1).card = 2 := by decide
example : (Finset.univ.filter fun s : Fin 4 → Bool => ∀ i j, s i = s j).card = 2 := by decide
-- The octant triangle: angles 90° + 90° + 90° exceed 180° by 90°, one eighth of the globe's 720°.
example : (3 * 90 : ℤ) - 180 = 90 ∧ (720 : ℤ) / 8 = 90 := by norm_num

#print axioms projective_plane_atlas_cannot_keep_clockwise
#print axioms globe_and_doughnut_changes_of_chart
#print axioms closed_surface_not_on_one_chart
