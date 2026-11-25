-- Systems of conservation laws: the shallow-water system with dye has three wave families at speeds u - c, u and u + c (two that bend, one that does not), its bores into still water lie on the Hugoniot locus, and every such bore with deeper water behind passes the Lax entropy test.
import Mathlib.Analysis.Calculus.FDeriv.Pi
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- The conserved amounts per metre of channel, `U = (h, h u, h φ)`: water volume, momentum and
dye, for depth `h`, water speed `u` and dye fraction `φ`. -/
def swState (h u φ : ℝ) : Fin 3 → ℝ := ![h, h * u, h * φ]

/-- The flux of the shallow-water system with dye, written in the conserved amounts
`U = (U₀, U₁, U₂) = (h, h u, h φ)`: `F(U) = (h u, h u² + g h² / 2, h u φ)`. -/
noncomputable def swFlux (g : ℝ) (U : Fin 3 → ℝ) : Fin 3 → ℝ :=
  ![U 1, U 1 ^ 2 / U 0 + g * U 0 ^ 2 / 2, U 1 * U 2 / U 0]

/-- Family 1's speed `λ₁ = u - c`, with `c = √(g h)`, as a function of the conserved amounts. -/
noncomputable def swLam1 (g : ℝ) (U : Fin 3 → ℝ) : ℝ := U 1 / U 0 - √(g * U 0)

/-- Family 2's speed `λ₂ = u`, as a function of the conserved amounts. -/
noncomputable def swLam2 (U : Fin 3 → ℝ) : ℝ := U 1 / U 0

/-- Family 3's speed `λ₃ = u + c`, with `c = √(g h)`, as a function of the conserved amounts. -/
noncomputable def swLam3 (g : ℝ) (U : Fin 3 → ℝ) : ℝ := U 1 / U 0 + √(g * U 0)

theorem fderiv_apply_of_line {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F]
    {f : (Fin 3 → ℝ) → F} {x v : Fin 3 → ℝ} {w : F} (hf : DifferentiableAt ℝ f x)
    (hw : HasDerivAt (fun t : ℝ => f (x + t • v)) w 0) : fderiv ℝ f x v = w := by
  have hl : HasDerivAt (fun t : ℝ => x + t • v) v 0 :=
    HasDerivAt.congr_deriv ((hasDerivAt_const_add_iff x).mpr ((hasDerivAt_id (0:ℝ)).smul_const v)) (by simp)
  have h2 : HasFDerivAt f (fderiv ℝ f x) ((fun t : ℝ => x + t • v) 0) := by
    simpa using hf.hasFDerivAt
  exact (h2.comp_hasDerivAt (0:ℝ) hl).unique hw

theorem line_coord (x v : Fin 3 → ℝ) (i : Fin 3) :
    HasDerivAt (fun t : ℝ => x i + t * v i) (v i) 0 :=
  HasDerivAt.congr_deriv ((hasDerivAt_const_add_iff (x i)).mpr ((hasDerivAt_id (0:ℝ)).mul_const (v i))) (by simp)

theorem swFlux_differentiableAt (g : ℝ) (x : Fin 3 → ℝ) (hx : x 0 ≠ 0) :
    DifferentiableAt ℝ (swFlux g) x := by
  rw [differentiableAt_pi]
  intro i
  fin_cases i <;> simp [swFlux] <;> fun_prop (disch := exact hx)

theorem swFlux_line (g : ℝ) (x v : Fin 3 → ℝ) (hx : x 0 ≠ 0) :
    HasDerivAt (fun t : ℝ => swFlux g (x + t • v))
      ![v 1, 2 * x 1 * v 1 / x 0 - x 1 ^ 2 * v 0 / x 0 ^ 2 + g * x 0 * v 0,
        (v 1 * x 2 + x 1 * v 2) / x 0 - x 1 * x 2 * v 0 / x 0 ^ 2] 0 := by
  rw [hasDerivAt_pi]
  intro i
  have e0 := line_coord x v 0
  have e1 := line_coord x v 1
  have e2 := line_coord x v 2
  have hx0 : x 0 + 0 * v 0 ≠ 0 := by simpa using hx
  fin_cases i
  · exact e1
  · exact HasDerivAt.congr_deriv (HasDerivAt.add ((e1.fun_pow 2).fun_div e0 hx0) ((e0.fun_pow 2).const_mul g |>.div_const 2))
      (by simp; field_simp)
  · exact ((e1.fun_mul e2).fun_div e0 hx0).congr_deriv (by simp; field_simp)

theorem swLam1_line (g : ℝ) (x v : Fin 3 → ℝ) (hx : x 0 ≠ 0) (hgx : g * x 0 ≠ 0) :
    DifferentiableAt ℝ (swLam1 g) x ∧ HasDerivAt (fun t : ℝ => swLam1 g (x + t • v))
      ((v 1 * x 0 - x 1 * v 0) / x 0 ^ 2 - g * v 0 / (2 * √(g * x 0))) 0 := by
  have e0 := line_coord x v 0
  have e1 := line_coord x v 1
  have hx0 : x 0 + 0 * v 0 ≠ 0 := by simpa using hx
  have hgx0 : g * (x 0 + 0 * v 0) ≠ 0 := by simpa using hgx
  refine ⟨?_, ?_⟩
  · unfold swLam1
    have h1 : DifferentiableAt ℝ (fun U : Fin 3 → ℝ => U 1 / U 0) x := by fun_prop (disch := exact hx)
    have h2 : DifferentiableAt ℝ (fun U : Fin 3 → ℝ => g * U 0) x := by fun_prop
    exact h1.sub (h2.sqrt hgx)
  · exact HasDerivAt.congr_deriv (HasDerivAt.sub (e1.fun_div e0 hx0) ((e0.const_mul g).sqrt hgx0))
      (by simp)

theorem swLam3_line (g : ℝ) (x v : Fin 3 → ℝ) (hx : x 0 ≠ 0) (hgx : g * x 0 ≠ 0) :
    DifferentiableAt ℝ (swLam3 g) x ∧ HasDerivAt (fun t : ℝ => swLam3 g (x + t • v))
      ((v 1 * x 0 - x 1 * v 0) / x 0 ^ 2 + g * v 0 / (2 * √(g * x 0))) 0 := by
  have e0 := line_coord x v 0
  have e1 := line_coord x v 1
  have hx0 : x 0 + 0 * v 0 ≠ 0 := by simpa using hx
  have hgx0 : g * (x 0 + 0 * v 0) ≠ 0 := by simpa using hgx
  refine ⟨?_, ?_⟩
  · unfold swLam3
    have h1 : DifferentiableAt ℝ (fun U : Fin 3 → ℝ => U 1 / U 0) x := by fun_prop (disch := exact hx)
    have h2 : DifferentiableAt ℝ (fun U : Fin 3 → ℝ => g * U 0) x := by fun_prop
    exact h1.add (h2.sqrt hgx)
  · exact HasDerivAt.congr_deriv (HasDerivAt.add (e1.fun_div e0 hx0) ((e0.const_mul g).sqrt hgx0))
      (by simp)

theorem swLam2_line (x v : Fin 3 → ℝ) (hx : x 0 ≠ 0) :
    DifferentiableAt ℝ swLam2 x ∧ HasDerivAt (fun t : ℝ => swLam2 (x + t • v))
      ((v 1 * x 0 - x 1 * v 0) / x 0 ^ 2) 0 := by
  have e0 := line_coord x v 0
  have e1 := line_coord x v 1
  have hx0 : x 0 + 0 * v 0 ≠ 0 := by simpa using hx
  refine ⟨?_, ?_⟩
  · unfold swLam2
    fun_prop (disch := exact hx)
  · exact HasDerivAt.congr_deriv (e1.fun_div e0 hx0) (by simp)

/-- The shallow-water system with dye, `U_t + F(U)_x = 0`, is strictly hyperbolic while the
water has depth `h > 0`: its Jacobian `A(U)` (the derivative of the flux with respect to the
conserved amounts) has the eigenvectors `r₁ = (1, u - c, φ)`, `r₂ = (0, 0, 1)`,
`r₃ = (1, u + c, φ)` with the three different real eigenvalues `u - c < u < u + c`, where
`c = √(g h)`. Families 1 and 3 are genuinely nonlinear, their speed changing along their own
eigenvector at the rates `∇λ₁ · r₁ = -3c/(2h)` and `∇λ₃ · r₃ = 3c/(2h)`, never zero; family 2
is linearly degenerate, `∇λ₂ · r₂ = 0`, so its jumps are contacts. -/
theorem shallow_water_three_wave_families (g h u φ : ℝ) (hg : 0 < g) (hh : 0 < h) :
    fderiv ℝ (swFlux g) (swState h u φ) ![1, u - √(g * h), φ] =
        (u - √(g * h)) • ![1, u - √(g * h), φ] ∧
    fderiv ℝ (swFlux g) (swState h u φ) ![0, 0, 1] = u • ![0, 0, 1] ∧
    fderiv ℝ (swFlux g) (swState h u φ) ![1, u + √(g * h), φ] =
        (u + √(g * h)) • ![1, u + √(g * h), φ] ∧
    (u - √(g * h) < u ∧ u < u + √(g * h)) ∧
    fderiv ℝ (swLam1 g) (swState h u φ) ![1, u - √(g * h), φ] = -(3 * √(g * h) / (2 * h)) ∧
    fderiv ℝ swLam2 (swState h u φ) ![0, 0, 1] = 0 ∧
    fderiv ℝ (swLam3 g) (swState h u φ) ![1, u + √(g * h), φ] = 3 * √(g * h) / (2 * h) := by
  have hgh : 0 < g * h := mul_pos hg hh
  have hc : √(g * h) ^ 2 = g * h := Real.sq_sqrt hgh.le
  have hcpos : 0 < √(g * h) := Real.sqrt_pos.mpr hgh
  have hc' : √(h * g) ^ 2 = h * g := by rw [mul_comm h g]; exact hc
  have hx : swState h u φ 0 ≠ 0 := by simp [swState]; exact hh.ne'
  have hgx : g * swState h u φ 0 ≠ 0 := by simp [swState]; exact ⟨hg.ne', hh.ne'⟩
  have hF := swFlux_differentiableAt g _ hx
  refine ⟨?_, ?_, ?_, ⟨by linarith, by linarith⟩, ?_, ?_, ?_⟩
  · rw [fderiv_apply_of_line hF (swFlux_line g _ _ hx)]
    ext i; fin_cases i <;> simp [swState] <;> field_simp
    all_goals first | ring1 | linear_combination (-1 : ℝ) * hc'
  · rw [fderiv_apply_of_line hF (swFlux_line g _ _ hx)]
    ext i; fin_cases i <;> simp [swState, hh.ne']
  · rw [fderiv_apply_of_line hF (swFlux_line g _ _ hx)]
    ext i; fin_cases i <;> simp [swState] <;> field_simp
    all_goals first | ring1 | linear_combination (-1 : ℝ) * hc'
  · obtain ⟨d, l⟩ := swLam1_line g (swState h u φ) ![1, u - √(g * h), φ] hx hgx
    rw [fderiv_apply_of_line d l]
    simp [swState]
    field_simp
    linear_combination hc
  · obtain ⟨d, l⟩ := swLam2_line (swState h u φ) ![0, 0, 1] hx
    rw [fderiv_apply_of_line d l]
    simp [swState]
  · obtain ⟨d, l⟩ := swLam3_line g (swState h u φ) ![1, u + √(g * h), φ] hx hgx
    rw [fderiv_apply_of_line d l]
    simp [swState]
    field_simp
    linear_combination (-1 : ℝ) * hc

/-- The Hugoniot locus through still water: a state of depth `h` and speed `u` can sit behind a
jump into still water of depth `h_R` (the same dye fraction on both sides, `h ≠ h_R`) exactly
when some speed `s` satisfies the Rankine-Hugoniot rule `s [U] = [F(U)]`, and that happens
exactly when `u² = g (h - h_R)² (h + h_R) / (2 h h_R)`. -/
theorem hugoniot_locus_through_still_water (g h hR u φ : ℝ) (hg : 0 < g) (hh : 0 < h)
    (hR0 : 0 < hR) (hne : h ≠ hR) :
    (∃ s : ℝ, s • (swState h u φ - swState hR 0 φ) =
        swFlux g (swState h u φ) - swFlux g (swState hR 0 φ)) ↔
      u ^ 2 = g * (h - hR) ^ 2 * (h + hR) / (2 * h * hR) := by
  have hd : h - hR ≠ 0 := sub_ne_zero.mpr hne
  constructor
  · rintro ⟨s, hs⟩
    have e1 := congrFun hs 0
    have e2 := congrFun hs 1
    simp [swState, swFlux] at e1 e2
    field_simp at e2
    rw [eq_div_iff (by positivity)]
    linear_combination (h - hR) * e2 - 2 * h * u * e1
  · intro hu
    rw [eq_div_iff (by positivity)] at hu
    refine ⟨h * u / (h - hR), ?_⟩
    ext i; fin_cases i <;> simp [swState, swFlux] <;> field_simp
    linear_combination hu

/-- The Lax entropy test on a bore: a family-3 jump from depth `h` into still water of depth
`h_R`, with deeper water behind (`h > h_R > 0`), the forward branch of the Hugoniot locus
`u = (h - h_R) √(g (h + h_R) / (2 h h_R))` and speed `s = h u / (h - h_R)`, passes the Lax test:
`λ₃` behind `> s >` `λ₃` ahead, `u + √(g h) > s > √(g h_R)`, and family 2 behind falls back,
`s > u`. -/
theorem bore_into_still_water_passes_lax_test (g h hR : ℝ) (hg : 0 < g) (hR0 : 0 < hR)
    (hdeep : hR < h) :
    let u := (h - hR) * √(g * (h + hR) / (2 * h * hR))
    let s := h * u / (h - hR)
    (u + √(g * h) > s ∧ s > √(g * hR)) ∧ s > u := by
  intro u s
  have hh : 0 < h := hR0.trans hdeep
  have hd : 0 < h - hR := sub_pos.mpr hdeep
  set q := √(g * (h + hR) / (2 * h * hR)) with hqdef
  have hqa : 0 < g * (h + hR) / (2 * h * hR) := by positivity
  have hq : 0 < q := Real.sqrt_pos.mpr hqa
  have hq2 : q ^ 2 = g * (h + hR) / (2 * h * hR) := Real.sq_sqrt hqa.le
  have hs : s = h * q := by
    show h * ((h - hR) * q) / (h - hR) = h * q
    field_simp
  have hu : u = (h - hR) * q := rfl
  refine ⟨⟨?_, ?_⟩, ?_⟩
  · rw [hs, hu, gt_iff_lt, ← sub_lt_iff_lt_add']
    have : h * q - (h - hR) * q = hR * q := by ring
    rw [this, Real.lt_sqrt (by positivity), mul_pow, hq2]
    have e : hR ^ 2 * (g * (h + hR) / (2 * h * hR)) = g * hR * (h + hR) / (2 * h) := by
      field_simp
    rw [e, div_lt_iff₀ (by positivity)]
    nlinarith [mul_pos hg (mul_pos hd (by linarith : (0:ℝ) < 2 * h + hR))]
  · rw [hs, gt_iff_lt, Real.sqrt_lt' (by positivity), mul_pow, hq2]
    have e : h ^ 2 * (g * (h + hR) / (2 * h * hR)) = g * h * (h + hR) / (2 * hR) := by
      field_simp
    rw [e, lt_div_iff₀ (by positivity)]
    nlinarith [mul_pos hg (mul_pos hd (by linarith : (0:ℝ) < h + 2 * hR))]
  · rw [hs, hu]; nlinarith

-- The reservoir, 2 m deep, at rest and fully dyed, holds U = (2, 0, 2).
example : swState 2 0 1 = ![2, 0, 2] := by
  ext i; fin_cases i <;> norm_num [swState]

#print axioms fderiv_apply_of_line
#print axioms line_coord
#print axioms swFlux_differentiableAt
#print axioms swFlux_line
#print axioms swLam1_line
#print axioms swLam3_line
#print axioms swLam2_line
#print axioms shallow_water_three_wave_families
#print axioms hugoniot_locus_through_still_water
#print axioms bore_into_still_water_passes_lax_test
