-- The complex derivative: a complex derivative at a point forces the Cauchy-Riemann equations with f' = u_x + i v_x, those equations with continuous partials near the point give the derivative back, sqrt|xy| passes the equations at 0 yet has no derivative there, and |z|^2 has a derivative at 0 alone so is holomorphic on no open region.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Abs
import Mathlib.Analysis.Complex.RealDeriv

open Complex Filter Topology

lemma cr_mvt_aux (g g' : ℝ → ℝ) (t0 δ L ε : ℝ)
    (hg : ∀ t, |t - t0| < δ → HasDerivAt g (g' t) t ∧ |g' t - L| ≤ ε) (s : ℝ) (hs : |s| < δ) :
    |g (t0 + s) - g t0 - L * s| ≤ ε * |s| := by
  have hconv : Convex ℝ (Metric.ball t0 δ) := convex_ball t0 δ
  have key := hconv.norm_image_sub_le_of_norm_hasDerivWithin_le
    (f := fun t => g t - L * t) (f' := fun t => g' t - L) (C := ε)
    (fun t ht => by
      have ht' : |t - t0| < δ := by simpa [Real.dist_eq] using ht
      exact (((hg t ht').1).sub ((hasDerivAt_id t).const_mul L) |>.congr_deriv (by simp)).hasDerivWithinAt)
    (fun t ht => by
      have ht' : |t - t0| < δ := by simpa [Real.dist_eq] using ht
      simpa [Real.norm_eq_abs] using (hg t ht').2)
    (x := t0) (y := t0 + s) (Metric.mem_ball_self (by linarith [abs_nonneg s]))
    (by simpa [Real.dist_eq] using hs)
  simp only [Real.norm_eq_abs, add_sub_cancel_left] at key
  have : g (t0 + s) - L * (t0 + s) - (g t0 - L * t0) = g (t0 + s) - g t0 - L * s := by ring
  rw [this] at key
  exact key

#print axioms cr_mvt_aux

/-- The Cauchy-Riemann equations, both halves. Let `f` send complex numbers to complex numbers and
write `u` and `v` for the real and imaginary parts of its output, as functions of `x` and `y` in
`z = x + iy`. The partial derivatives are the rates along a line: `u_x` is the rate of `u` as `x`
alone moves, `u_y` as `y` alone moves, and the same for `v`.

Necessary half: if `f` has complex derivative `f'` at `z₀`, then all four partials exist at `z₀`,
they satisfy `u_x = v_y` and `u_y = -v_x`, and `f' = u_x + i v_x`.

Converse: if the four partials exist at every point near `z₀`, are continuous near `z₀`, and satisfy
`u_x = v_y` and `u_y = -v_x` at `z₀`, then `f` has a complex derivative at `z₀`, equal to
`u_x + i v_x`. -/
theorem complex_derivative_and_cauchy_riemann (f : ℂ → ℂ) (z₀ : ℂ) :
    (∀ f' : ℂ, HasDerivAt f f' z₀ →
      ∃ ux uy vx vy : ℝ,
        HasDerivAt (fun x : ℝ => (f ⟨x, z₀.im⟩).re) ux z₀.re ∧
        HasDerivAt (fun y : ℝ => (f ⟨z₀.re, y⟩).re) uy z₀.im ∧
        HasDerivAt (fun x : ℝ => (f ⟨x, z₀.im⟩).im) vx z₀.re ∧
        HasDerivAt (fun y : ℝ => (f ⟨z₀.re, y⟩).im) vy z₀.im ∧
        ux = vy ∧ uy = -vx ∧ f' = ux + vx * I) ∧
    (∀ ux uy vx vy : ℂ → ℝ,
      (∀ᶠ z in 𝓝 z₀,
        HasDerivAt (fun x : ℝ => (f ⟨x, z.im⟩).re) (ux z) z.re ∧
        HasDerivAt (fun y : ℝ => (f ⟨z.re, y⟩).re) (uy z) z.im ∧
        HasDerivAt (fun x : ℝ => (f ⟨x, z.im⟩).im) (vx z) z.re ∧
        HasDerivAt (fun y : ℝ => (f ⟨z.re, y⟩).im) (vy z) z.im) →
      (∀ᶠ z in 𝓝 z₀, ContinuousAt ux z ∧ ContinuousAt uy z ∧ ContinuousAt vx z ∧ ContinuousAt vy z) →
      ux z₀ = vy z₀ → uy z₀ = -vx z₀ →
      HasDerivAt f (ux z₀ + vx z₀ * I) z₀) := by
  obtain ⟨x0, y0⟩ := z₀
  constructor
  · intro f' hf
    -- horizontal line
    have hH : HasDerivAt (fun x : ℝ => f ⟨x, y0⟩) f' x0 := by
      have h1 : HasDerivAt (fun x : ℝ => (x : ℂ) + (y0 : ℂ) * I) 1 x0 := by
        simpa using (hasDerivAt_id x0).ofReal_comp.add_const ((y0 : ℂ) * I)
      have h2 : HasDerivAt f f' ((x0 : ℂ) + (y0 : ℂ) * I) := by
        have : ((x0 : ℂ) + (y0 : ℂ) * I) = ⟨x0, y0⟩ := Complex.ext (by simp) (by simp)
        rw [this]; exact hf
      have := h2.comp x0 h1
      simp only [mul_one] at this
      convert this using 1
      funext x
      simp only [Function.comp]
      congr 1
      exact Complex.ext (by simp) (by simp)
    have hV : HasDerivAt (fun y : ℝ => f ⟨x0, y⟩) (f' * I) y0 := by
      have h1 : HasDerivAt (fun y : ℝ => (x0 : ℂ) + (y : ℂ) * I) I y0 := by
        simpa using ((hasDerivAt_id y0).ofReal_comp.mul_const I).const_add (x0 : ℂ)
      have h2 : HasDerivAt f f' ((x0 : ℂ) + (y0 : ℂ) * I) := by
        have : ((x0 : ℂ) + (y0 : ℂ) * I) = ⟨x0, y0⟩ := Complex.ext (by simp) (by simp)
        rw [this]; exact hf
      have := h2.comp y0 h1
      convert this using 1
      funext y
      simp only [Function.comp]
      congr 1
      exact Complex.ext (by simp) (by simp)
    have re_d : ∀ {g : ℝ → ℂ} {d : ℂ} {t : ℝ}, HasDerivAt g d t →
        HasDerivAt (fun s => (g s).re) d.re t := fun h =>
      Complex.reCLM.hasFDerivAt.comp_hasDerivAt _ h
    have im_d : ∀ {g : ℝ → ℂ} {d : ℂ} {t : ℝ}, HasDerivAt g d t →
        HasDerivAt (fun s => (g s).im) d.im t := fun h =>
      Complex.imCLM.hasFDerivAt.comp_hasDerivAt _ h
    refine ⟨f'.re, (f' * I).re, f'.im, (f' * I).im, re_d hH, re_d hV, im_d hH, im_d hV,
      by simp, by simp, ?_⟩
    exact (Complex.re_add_im f').symm
  · intro ux uy vx vy hd hc hCR1 hCR2
    obtain ⟨cux, cuy, cvx, cvy⟩ := hc.self_of_nhds
    rw [hasDerivAt_iff_isLittleO_nhds_zero, Asymptotics.isLittleO_iff]
    intro c hcpos
    set ε := c / 4 with hε
    have hεpos : 0 < ε := by positivity
    have near : ∀ {φ : ℂ → ℝ}, ContinuousAt φ ⟨x0, y0⟩ → ∀ᶠ z in 𝓝 (⟨x0, y0⟩ : ℂ),
        |φ z - φ ⟨x0, y0⟩| ≤ ε := by
      intro φ hφ
      have := hφ.eventually (Metric.closedBall_mem_nhds (φ ⟨x0, y0⟩) hεpos)
      filter_upwards [this] with z hz
      simpa [Metric.mem_closedBall, Real.dist_eq] using hz
    obtain ⟨δ, hδ, hP⟩ := Metric.eventually_nhds_iff.1
      (hd.and ((near cux).and ((near cuy).and ((near cvx).and (near cvy)))))
    have hbox : ∀ t y : ℝ, |t - x0| < δ / 2 → |y - y0| < δ / 2 → _ := fun t y ht hy =>
      hP (y := (⟨t, y⟩ : ℂ)) (by
        rw [Complex.dist_eq]
        calc ‖(⟨t, y⟩ : ℂ) - ⟨x0, y0⟩‖ ≤ |((⟨t, y⟩ : ℂ) - ⟨x0, y0⟩).re|
              + |((⟨t, y⟩ : ℂ) - ⟨x0, y0⟩).im| := Complex.norm_le_abs_re_add_abs_im _
          _ = |t - x0| + |y - y0| := by simp
          _ < δ := by linarith)
    rw [Metric.eventually_nhds_iff]
    refine ⟨δ / 2, by positivity, ?_⟩
    rintro ⟨a, b⟩ hh
    have hh' : ‖(⟨a, b⟩ : ℂ)‖ < δ / 2 := by simpa using hh
    have ha : |a| ≤ ‖(⟨a, b⟩ : ℂ)‖ := by
      simpa using Complex.abs_re_le_norm (⟨a, b⟩ : ℂ)
    have hb : |b| ≤ ‖(⟨a, b⟩ : ℂ)‖ := by
      simpa using Complex.abs_im_le_norm (⟨a, b⟩ : ℂ)
    have ha' : |a| < δ / 2 := lt_of_le_of_lt ha hh'
    have hb' : |b| < δ / 2 := lt_of_le_of_lt hb hh'
    have h0 : |x0 - x0| < δ / 2 := by simp; positivity
    have h0' : |y0 - y0| < δ / 2 := by simp; positivity
    -- four mean value estimates
    have A1 := cr_mvt_aux (fun x => (f ⟨x, y0 + b⟩).re) (fun t => ux ⟨t, y0 + b⟩) x0 (δ / 2)
      (ux ⟨x0, y0⟩) ε (fun t ht => by
        have := hbox t (y0 + b) ht (by simpa using hb')
        exact ⟨this.1.1, this.2.1⟩) a ha'
    have A2 := cr_mvt_aux (fun y => (f ⟨x0, y⟩).re) (fun t => uy ⟨x0, t⟩) y0 (δ / 2)
      (uy ⟨x0, y0⟩) ε (fun t ht => by
        have := hbox x0 t h0 ht
        exact ⟨this.1.2.1, this.2.2.1⟩) b hb'
    have A3 := cr_mvt_aux (fun x => (f ⟨x, y0 + b⟩).im) (fun t => vx ⟨t, y0 + b⟩) x0 (δ / 2)
      (vx ⟨x0, y0⟩) ε (fun t ht => by
        have := hbox t (y0 + b) ht (by simpa using hb')
        exact ⟨this.1.2.2.1, this.2.2.2.1⟩) a ha'
    have A4 := cr_mvt_aux (fun y => (f ⟨x0, y⟩).im) (fun t => vy ⟨x0, t⟩) y0 (δ / 2)
      (vy ⟨x0, y0⟩) ε (fun t ht => by
        have := hbox x0 t h0 ht
        exact ⟨this.1.2.2.2, this.2.2.2.2⟩) b hb'
    have e : (⟨x0, y0⟩ + ⟨a, b⟩ : ℂ) = ⟨x0 + a, y0 + b⟩ := Complex.ext (by simp) (by simp)
    rw [e, smul_eq_mul]
    set w := f ⟨x0 + a, y0 + b⟩ - f ⟨x0, y0⟩ - (⟨a, b⟩ : ℂ) * (↑(ux ⟨x0, y0⟩) + ↑(vx ⟨x0, y0⟩) * I)
      with hw
    have hre : w.re = ((f ⟨x0 + a, y0 + b⟩).re - (f ⟨x0, y0 + b⟩).re - ux ⟨x0, y0⟩ * a)
        + ((f ⟨x0, y0 + b⟩).re - (f ⟨x0, y0⟩).re - uy ⟨x0, y0⟩ * b) := by
      rw [hw, hCR2]; simp; ring
    have him : w.im = ((f ⟨x0 + a, y0 + b⟩).im - (f ⟨x0, y0 + b⟩).im - vx ⟨x0, y0⟩ * a)
        + ((f ⟨x0, y0 + b⟩).im - (f ⟨x0, y0⟩).im - vy ⟨x0, y0⟩ * b) := by
      rw [hw, ← hCR1]; simp; ring
    have hre' : |w.re| ≤ ε * |a| + ε * |b| := by
      rw [hre]; exact (abs_add_le _ _).trans (add_le_add A1 A2)
    have him' : |w.im| ≤ ε * |a| + ε * |b| := by
      rw [him]; exact (abs_add_le _ _).trans (add_le_add A3 A4)
    have hn := Complex.norm_le_abs_re_add_abs_im w
    have : ε * |a| + ε * |b| ≤ 2 * ε * ‖(⟨a, b⟩ : ℂ)‖ := by nlinarith
    have h2 : 4 * ε * ‖(⟨a, b⟩ : ℂ)‖ ≤ c * ‖(⟨a, b⟩ : ℂ)‖ := by
      rw [hε]; nlinarith [norm_nonneg (⟨a, b⟩ : ℂ)]
    linarith

/-- Two directions are not every direction. The function `sqrt|xy|` (real output, imaginary part 0)
is 0 on both axes, so at 0 all four partials are 0 and the Cauchy-Riemann equations hold there. Yet
on the diagonal `h = s(1 + i)`, `s > 0`, its difference quotient is `1/(1 + i) = 0.5 - 0.5i`, and it
has no complex derivative at 0. -/
theorem sqrt_abs_xy_passes_equations_but_not_differentiable :
    let g : ℂ → ℂ := fun z => (Real.sqrt |z.re * z.im| : ℂ)
    HasDerivAt (fun x : ℝ => (g ⟨x, 0⟩).re) 0 0 ∧
    HasDerivAt (fun y : ℝ => (g ⟨0, y⟩).re) 0 0 ∧
    HasDerivAt (fun x : ℝ => (g ⟨x, 0⟩).im) 0 0 ∧
    HasDerivAt (fun y : ℝ => (g ⟨0, y⟩).im) 0 0 ∧
    (∀ s : ℝ, 0 < s → (g (s * (1 + I)) - g 0) / (s * (1 + I)) = 1 / 2 - I / 2) ∧
    ¬ DifferentiableAt ℂ g 0 := by
  intro g
  have h1 : (fun x : ℝ => (g ⟨x, 0⟩).re) = fun _ => 0 := by funext x; simp [g]
  have h2 : (fun y : ℝ => (g ⟨0, y⟩).re) = fun _ => 0 := by funext x; simp [g]
  have h3 : (fun x : ℝ => (g ⟨x, 0⟩).im) = fun _ => 0 := by funext x; simp [g]
  have h4 : (fun y : ℝ => (g ⟨0, y⟩).im) = fun _ => 0 := by funext x; simp [g]
  have hdiag : ∀ t : ℝ, g (t * (1 + I)) = ((|t| : ℝ) : ℂ) := by
    intro t
    simp only [g]
    congr 1
    have : ((t : ℂ) * (1 + I)).re * ((t : ℂ) * (1 + I)).im = t * t := by simp
    rw [this, abs_mul_self, Real.sqrt_mul_self_eq_abs]
  have hg0 : g 0 = 0 := by simp [g]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [h1]; exact hasDerivAt_const _ _
  · rw [h2]; exact hasDerivAt_const _ _
  · rw [h3]; exact hasDerivAt_const _ _
  · rw [h4]; exact hasDerivAt_const _ _
  · intro s hs
    rw [hdiag, hg0, abs_of_pos hs, sub_zero]
    have hs' : (s : ℂ) ≠ 0 := by exact_mod_cast hs.ne'
    rw [div_mul_eq_div_div, div_self hs']
    apply Complex.ext <;> norm_num [div_re, div_im, normSq_apply]
  · intro hd
    have hl : HasDerivAt (fun t : ℝ => (t : ℂ) * (1 + I)) (1 + I) 0 := by
      simpa using (hasDerivAt_id (0 : ℝ)).ofReal_comp.mul_const (1 + I)
    have hd' : HasDerivAt g (deriv g 0) (((0 : ℝ) : ℂ) * (1 + I)) := by
      simpa using hd.hasDerivAt
    have hc := hd'.comp (0 : ℝ) hl
    have hre := Complex.reCLM.hasFDerivAt.comp_hasDerivAt _ hc
    have : (⇑Complex.reCLM ∘ g ∘ fun t : ℝ => (t : ℂ) * (1 + I)) = abs := by
      funext t; simp [hdiag]
    rw [this] at hre
    exact not_differentiableAt_abs_zero hre.differentiableAt

/-- A derivative at one point is not holomorphic. The size squared `|z|^2` has a complex derivative
at 0 and at no other point, so it is holomorphic on no open region: on no nonempty open set does it
have a complex derivative at every point. -/
theorem norm_sq_differentiable_only_at_zero :
    (∀ z : ℂ, DifferentiableAt ℂ (fun w : ℂ => (normSq w : ℂ)) z ↔ z = 0) ∧
    (∀ U : Set ℂ, IsOpen U → U.Nonempty → ¬ DifferentiableOn ℂ (fun w : ℂ => (normSq w : ℂ)) U) := by
  have part1 : ∀ z : ℂ, DifferentiableAt ℂ (fun w : ℂ => (normSq w : ℂ)) z ↔ z = 0 := by
    intro z
    constructor
    · intro hd
      obtain ⟨ux, uy, vx, vy, H1, H2, H3, H4, e1, e2, -⟩ :=
        (complex_derivative_and_cauchy_riemann (fun w : ℂ => (normSq w : ℂ)) z).1 _ hd.hasDerivAt
      have k1 : (fun x : ℝ => ((normSq ⟨x, z.im⟩ : ℂ)).re) = fun x => x * x + z.im * z.im := by
        funext x; simp [normSq_apply]
      have k2 : (fun y : ℝ => ((normSq ⟨z.re, y⟩ : ℂ)).re) = fun y => z.re * z.re + y * y := by
        funext y; simp [normSq_apply]
      have k3 : (fun x : ℝ => ((normSq ⟨x, z.im⟩ : ℂ)).im) = fun _ => 0 := by
        funext x; simp
      have k4 : (fun y : ℝ => ((normSq ⟨z.re, y⟩ : ℂ)).im) = fun _ => 0 := by
        funext y; simp
      rw [k1] at H1; rw [k2] at H2; rw [k3] at H3; rw [k4] at H4
      have D1 : HasDerivAt (fun x : ℝ => x * x + z.im * z.im) (2 * z.re) z.re := by
        have := ((hasDerivAt_id z.re).mul (hasDerivAt_id z.re)).add_const (z.im * z.im)
        convert this using 1
        · rfl
        · show (2:ℝ) * z.re = 1 * z.re + z.re * 1; ring
      have D2 : HasDerivAt (fun y : ℝ => z.re * z.re + y * y) (2 * z.im) z.im := by
        have := ((hasDerivAt_id z.im).mul (hasDerivAt_id z.im)).const_add (z.re * z.re)
        convert this using 1
        · rfl
        · show (2:ℝ) * z.im = 1 * z.im + z.im * 1; ring
      have q1 := H1.unique D1
      have q2 := H2.unique D2
      have q3 := H3.unique (hasDerivAt_const _ _)
      have q4 := H4.unique (hasDerivAt_const _ _)
      apply Complex.ext
      · simp; linarith
      · simp; linarith
    · rintro rfl
      apply HasDerivAt.differentiableAt (f' := 0)
      rw [hasDerivAt_iff_isLittleO_nhds_zero, Asymptotics.isLittleO_iff]
      intro c hc
      rw [Metric.eventually_nhds_iff]
      refine ⟨c, hc, fun h hh => ?_⟩
      have hh' : ‖h‖ < c := by simpa using hh
      simp only [zero_add, map_zero, ofReal_zero, sub_zero, smul_zero]
      rw [Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg (normSq_nonneg h),
        Complex.normSq_eq_norm_sq]
      nlinarith [norm_nonneg h]
  refine ⟨part1, ?_⟩
  rintro U hU ⟨z, hz⟩ hdiff
  have all0 : ∀ w ∈ U, w = 0 := fun w hw =>
    (part1 w).1 (hdiff.differentiableAt (hU.mem_nhds hw))
  have hz0 := all0 z hz
  subst hz0
  obtain ⟨ε, hε, hball⟩ := Metric.isOpen_iff.1 hU 0 hz
  have hmem : ((ε / 2 : ℝ) : ℂ) ∈ U := hball (by
    rw [Metric.mem_ball, dist_zero_right, Complex.norm_real, Real.norm_eq_abs,
      abs_of_pos (by positivity)]
    linarith)
  have := all0 _ hmem
  have : (ε / 2 : ℝ) = 0 := by exact_mod_cast this
  linarith

/-! The card's worked numbers for the square filter at 1 + i, checked exactly. -/

-- where the pixel lands: (1 + i)^2 = 2i
example : ((1 : ℂ) + I) ^ 2 = 2 * I := by apply Complex.ext <;> norm_num [pow_two]
-- u = x^2 - y^2 = 0 and v = 2xy = 2 at x = 1, y = 1
example : (1 : ℤ) ^ 2 - 1 ^ 2 = 0 ∧ (2 : ℤ) * 1 * 1 = 2 := by decide
-- eastward rates u_x = 2x = 2, v_x = 2y = 2; northward rates u_y = -2y = -2, v_y = 2x = 2
example : (2 : ℤ) * 1 = 2 ∧ -(2 : ℤ) * 1 = -2 := by decide
-- Cauchy-Riemann: u_x = v_y is 2 = 2, u_y = -v_x is -2 = -2; the wrong sign u_y = v_x fails, -2 against 2
example : (2 : ℤ) = 2 ∧ (-2 : ℤ) = -2 ∧ (-2 : ℤ) ≠ 2 := by decide
-- the derivative u_x + i v_x = 2 + 2i equals 2 z₀
example : (2 : ℂ) + 2 * I = 2 * (1 + I) := by ring
-- the square's difference quotient misses 2 z₀ by the step: (z₀ + h)^2 - z₀^2 = 2 z₀ h + h^2
example (z₀ h : ℂ) : (z₀ + h) ^ 2 - z₀ ^ 2 = 2 * z₀ * h + h ^ 2 := by ring
-- the stretch squared: |2 + 2i|^2 = 2^2 + 2^2 = 8 (stretch 2.828427 is its square root)
example : normSq (2 + 2 * I) = 8 := by norm_num [normSq_apply]
-- the mirror's quotient conj(h)/h: 1 eastward, -i at 45 degrees, -1 northward
example : (starRingEnd ℂ) 1 / 1 = 1 := by norm_num
example : (starRingEnd ℂ) (1 + I) / (1 + I) = -I := by
  apply Complex.ext <;> norm_num [div_re, div_im, normSq_apply]
example : (starRingEnd ℂ) I / I = -1 := by
  apply Complex.ext <;> norm_num [div_re, div_im, normSq_apply]
-- sqrt|xy| on the diagonal: 1/(1 + i) = 0.5 - 0.5i
example : (1 : ℂ) / (1 + I) = 1 / 2 - I / 2 := by
  apply Complex.ext <;> norm_num [div_re, div_im, normSq_apply]

#print axioms complex_derivative_and_cauchy_riemann
#print axioms sqrt_abs_xy_passes_equations_but_not_differentiable
#print axioms norm_sq_differentiable_only_at_zero
