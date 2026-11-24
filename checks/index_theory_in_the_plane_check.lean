-- Index theory: a linear field round a rest turns its arrow sign(det A) times, its key integrand is det A, and the field z^n turns n times.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Basic.Real.Sign
import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Complex.RealDeriv

open Real

/-- The index of a planar field `F = (f, g)` on the circle of centre `c` and radius `r`, walked
once anticlockwise: `I = (1 / 2π) ∫₀^{2π} (f g' - g f') / (f² + g²) dt`, where `f` and `g` are the
field's two parts read along the walk `t ↦ c + r (cos t, sin t)` and `'` is the rate in `t`. -/
noncomputable def circleIndex (F : ℝ × ℝ → ℝ × ℝ) (c : ℝ × ℝ) (r : ℝ) : ℝ :=
  let f : ℝ → ℝ := fun t => (F (c.1 + r * cos t, c.2 + r * sin t)).1
  let g : ℝ → ℝ := fun t => (F (c.1 + r * cos t, c.2 + r * sin t)).2
  (1 / (2 * π)) * ∫ t in (0 : ℝ)..(2 * π),
    (f t * deriv g t - g t * deriv f t) / (f t ^ 2 + g t ^ 2)

/-- The linear field `u ↦ A u` of a 2 × 2 matrix `A`. -/
def linearField (A : Matrix (Fin 2) (Fin 2) ℝ) (p : ℝ × ℝ) : ℝ × ℝ :=
  (A 0 0 * p.1 + A 0 1 * p.2, A 1 0 * p.1 + A 1 1 * p.2)

theorem hasDerivAt_re_of_complex {Ψ : ℝ → ℂ} {Ψ' : ℂ} {t : ℝ} (h : HasDerivAt Ψ Ψ' t) :
    HasDerivAt (fun s => (Ψ s).re) Ψ'.re t := by
  exact Complex.reCLM.hasFDerivAt.comp_hasDerivAt t h

theorem hasDerivAt_im_of_complex {Ψ : ℝ → ℂ} {Ψ' : ℂ} {t : ℝ} (h : HasDerivAt Ψ Ψ' t) :
    HasDerivAt (fun s => (Ψ s).im) Ψ'.im t := by
  exact Complex.imCLM.hasFDerivAt.comp_hasDerivAt t h

theorem hasDerivAt_expI (m : ℤ) (t : ℝ) :
    HasDerivAt (fun s : ℝ => Complex.exp (((m * s : ℝ) : ℂ) * Complex.I))
      (Complex.exp (((m * t : ℝ) : ℂ) * Complex.I) * ((m : ℂ) * Complex.I)) t := by
  have h1 : HasDerivAt (fun s : ℝ => ((m * s : ℝ) : ℂ)) ((m : ℝ) : ℂ) t := by
    simpa using ((hasDerivAt_id t).const_mul (m : ℝ)).ofReal_comp
  have h2 := (h1.mul_const Complex.I).cexp
  simpa using h2

theorem expI_mul (m n : ℤ) (t : ℝ) :
    Complex.exp (((m * t : ℝ) : ℂ) * Complex.I) * Complex.exp ((((n - m : ℤ) * t : ℝ) : ℂ) * Complex.I)
      = Complex.exp (((n * t : ℝ) : ℂ) * Complex.I) := by
  rw [← Complex.exp_add]; congr 1; push_cast; ring

theorem expI_period (k : ℤ) :
    Complex.exp (((k * (2 * π) : ℝ) : ℂ) * Complex.I) = 1 := by
  have : (((k * (2 * π) : ℝ) : ℂ) * Complex.I) = (k : ℂ) * (2 * π * Complex.I) := by
    push_cast; ring
  rw [this, Complex.exp_int_mul_two_pi_mul_I]

theorem winding_core (f g : ℝ → ℝ) (κ β : ℂ) (m n : ℤ) (hβ : ‖β‖ < ‖κ‖)
    (hw : ∀ t, ((f t : ℂ) + (g t : ℂ) * Complex.I)
      = κ * Complex.exp (((m * t : ℝ) : ℂ) * Complex.I) + β * Complex.exp (((n * t : ℝ) : ℂ) * Complex.I)) :
    ∫ t in (0 : ℝ)..(2 * π), (f t * deriv g t - g t * deriv f t) / (f t ^ 2 + g t ^ 2)
      = 2 * π * m := by
  have hκ : κ ≠ 0 := by
    intro h; rw [h, norm_zero] at hβ; exact absurd hβ (not_lt.2 (norm_nonneg _))
  set γ : ℂ := β / κ with hγdef
  have hγ : ‖γ‖ < 1 := by
    rw [hγdef, norm_div, div_lt_one (norm_pos_iff.2 hκ)]; exact hβ
  let k : ℤ := n - m
  let E : ℝ → ℂ := fun s => Complex.exp (((m * s : ℝ) : ℂ) * Complex.I)
  let Ek : ℝ → ℂ := fun s => Complex.exp (((k * s : ℝ) : ℂ) * Complex.I)
  let h : ℝ → ℂ := fun s => 1 + γ * Ek s
  let Ψ : ℝ → ℂ := fun s => κ * E s * h s
  have hΨ : ∀ t, Ψ t = (f t : ℂ) + (g t : ℂ) * Complex.I := by
    intro t
    rw [hw t]
    simp only [Ψ, h, E, Ek, k]
    rw [← expI_mul m n t, hγdef]
    field_simp
  have hf : ∀ t, f t = (Ψ t).re := by intro t; rw [hΨ t]; simp
  have hg : ∀ t, g t = (Ψ t).im := by intro t; rw [hΨ t]; simp
  have hEk : ∀ t, ‖Ek t‖ = 1 := fun t => Complex.norm_exp_ofReal_mul_I _
  have hE0 : ∀ t, E t ≠ 0 := fun t => Complex.exp_ne_zero _
  have hslit : ∀ t, h t ∈ Complex.slitPlane := by
    intro t
    rw [Complex.mem_slitPlane_iff]; left
    have h1 : -(γ * Ek t).re ≤ ‖γ * Ek t‖ := by
      exact (neg_le_abs _).trans (Complex.abs_re_le_norm _)
    rw [norm_mul, hEk, mul_one] at h1
    simp only [h, Complex.add_re, Complex.one_re]
    linarith
  have hh0 : ∀ t, h t ≠ 0 := fun t => Complex.slitPlane_ne_zero (hslit t)
  let h' : ℝ → ℂ := fun s => γ * (Ek s * ((k : ℂ) * Complex.I))
  have hhd : ∀ t, HasDerivAt h (h' t) t := by
    intro t
    have := ((hasDerivAt_expI k t).const_mul γ).const_add 1
    exact this
  let Ψ' : ℝ → ℂ := fun s => κ * (E s * ((m : ℂ) * Complex.I)) * h s + κ * E s * h' s
  have hΨd : ∀ t, HasDerivAt Ψ (Ψ' t) t := by
    intro t
    have := ((hasDerivAt_expI m t).const_mul κ).mul (hhd t)
    exact this
  have hfd : ∀ t, deriv f t = (Ψ' t).re := by
    intro t
    have : f = fun s => (Ψ s).re := funext hf
    rw [this]; exact (hasDerivAt_re_of_complex (hΨd t)).deriv
  have hgd : ∀ t, deriv g t = (Ψ' t).im := by
    intro t
    have : g = fun s => (Ψ s).im := funext hg
    rw [this]; exact (hasDerivAt_im_of_complex (hΨd t)).deriv
  let θ' : ℝ → ℝ := fun s => (m : ℝ) + (h' s / h s).im
  have hint : ∀ t, (f t * deriv g t - g t * deriv f t) / (f t ^ 2 + g t ^ 2) = θ' t := by
    intro t
    have hΨ0 : Ψ t ≠ 0 := mul_ne_zero (mul_ne_zero hκ (hE0 t)) (hh0 t)
    have hq : Ψ' t / Ψ t = (m : ℂ) * Complex.I + h' t / h t := by
      simp only [Ψ', Ψ]
      field_simp [hE0 t, hh0 t, hκ]
    have hq2 : (f t * deriv g t - g t * deriv f t) / (f t ^ 2 + g t ^ 2) = (Ψ' t / Ψ t).im := by
      rw [hfd, hgd, hf, hg, Complex.div_im, Complex.normSq_apply]
      have : (Ψ t).re * (Ψ t).re + (Ψ t).im * (Ψ t).im ≠ 0 := by
        rw [← Complex.normSq_apply]; exact (Complex.normSq_pos.2 hΨ0).ne'
      field_simp
    rw [hq2, hq]
    simp [θ']
  let θ : ℝ → ℝ := fun s => (m : ℝ) * s + (Complex.log (h s)).im
  have hθ : ∀ t, HasDerivAt θ (θ' t) t := by
    intro t
    have h1 := hasDerivAt_im_of_complex ((hhd t).clog_real (hslit t))
    have h2 := ((hasDerivAt_id t).const_mul (m : ℝ)).add h1
    rw [mul_one] at h2
    exact h2
  have hcont : Continuous θ' := by
    have hc1 : Continuous h' := by simp only [h', Ek]; fun_prop
    have hc2 : Continuous h := by simp only [h, Ek]; fun_prop
    exact continuous_const.add (Complex.continuous_im.comp (hc1.div hc2 hh0))
  rw [intervalIntegral.integral_congr (g := θ') (fun t _ => hint t)]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun t _ => hθ t)
    (hcont.intervalIntegrable _ _)]
  have hper : h (2 * π) = h 0 := by
    simp only [h, Ek]
    rw [expI_period]; simp
  simp only [θ]
  rw [hper]
  ring

theorem circleIndex_of_winding (F : ℝ × ℝ → ℝ × ℝ) (c : ℝ × ℝ) (r : ℝ) (κ β : ℂ) (m n : ℤ)
    (hβ : ‖β‖ < ‖κ‖)
    (hw : ∀ t, (((F (c.1 + r * cos t, c.2 + r * sin t)).1 : ℝ) : ℂ)
        + (((F (c.1 + r * cos t, c.2 + r * sin t)).2 : ℝ) : ℂ) * Complex.I
      = κ * Complex.exp (((m * t : ℝ) : ℂ) * Complex.I)
        + β * Complex.exp (((n * t : ℝ) : ℂ) * Complex.I)) :
    circleIndex F c r = m := by
  have key := winding_core (fun t => (F (c.1 + r * cos t, c.2 + r * sin t)).1)
    (fun t => (F (c.1 + r * cos t, c.2 + r * sin t)).2) κ β m n hβ hw
  unfold circleIndex
  simp only [] at key ⊢
  rw [key]
  field_simp

#print axioms hasDerivAt_re_of_complex
#print axioms hasDerivAt_im_of_complex
#print axioms hasDerivAt_expI
#print axioms expI_mul
#print axioms expI_period
#print axioms winding_core
#print axioms circleIndex_of_winding

/-- A rest counts the sign of its determinant: when `det A ≠ 0`, the linear field `A u` turns its
arrow `sign (det A)` times on any circle round the rest at the origin, walked once anticlockwise.
So a saddle (`det A < 0`) counts −1 and a node, spiral or centre (`det A > 0`) counts +1. -/
theorem circleIndex_linear_eq_sign_det (A : Matrix (Fin 2) (Fin 2) ℝ) (hA : A.det ≠ 0)
    (r : ℝ) (hr : 0 < r) :
    circleIndex (linearField A) (0, 0) r = Real.sign A.det := by
  set α : ℂ := ⟨(A 0 0 + A 1 1) / 2, (A 1 0 - A 0 1) / 2⟩ with hα
  set β : ℂ := ⟨(A 0 0 - A 1 1) / 2, (A 1 0 + A 0 1) / 2⟩ with hβ
  have hexp : ∀ t : ℝ, (((linearField A (((0, 0) : ℝ × ℝ).1 + r * cos t,
        ((0, 0) : ℝ × ℝ).2 + r * sin t)).1 : ℝ) : ℂ)
      + (((linearField A (((0, 0) : ℝ × ℝ).1 + r * cos t,
        ((0, 0) : ℝ × ℝ).2 + r * sin t)).2 : ℝ) : ℂ) * Complex.I
      = (r * α) * Complex.exp ((((1 : ℤ) * t : ℝ) : ℂ) * Complex.I)
        + (r * β) * Complex.exp ((((-1 : ℤ) * t : ℝ) : ℂ) * Complex.I) := by
    intro t
    have e1 : Complex.exp ((((1 : ℤ) * t : ℝ) : ℂ) * Complex.I)
        = ((cos t : ℝ) : ℂ) + ((sin t : ℝ) : ℂ) * Complex.I := by
      apply Complex.ext
      · rw [Complex.exp_ofReal_mul_I_re]; simp [Complex.cos_ofReal_re, Complex.sin_ofReal_re]
      · rw [Complex.exp_ofReal_mul_I_im]; simp [Complex.cos_ofReal_re, Complex.sin_ofReal_re]
    have e2 : Complex.exp ((((-1 : ℤ) * t : ℝ) : ℂ) * Complex.I)
        = ((cos t : ℝ) : ℂ) - ((sin t : ℝ) : ℂ) * Complex.I := by
      apply Complex.ext
      · rw [Complex.exp_ofReal_mul_I_re]; simp [Complex.cos_ofReal_re, Complex.sin_ofReal_re]
      · rw [Complex.exp_ofReal_mul_I_im]; simp [Complex.cos_ofReal_re, Complex.sin_ofReal_re]
    rw [e1, e2]
    apply Complex.ext <;> simp [linearField, hα, hβ] <;> ring
  have hdiff : ‖(r : ℂ) * α‖ ^ 2 - ‖(r : ℂ) * β‖ ^ 2 = r ^ 2 * A.det := by
    rw [Complex.sq_norm, Complex.sq_norm, Matrix.det_fin_two A]
    simp [Complex.normSq_apply, hα, hβ]
    ring
  rcases lt_or_gt_of_ne hA with hneg | hpos
  · have hlt : ‖(r : ℂ) * α‖ < ‖(r : ℂ) * β‖ := by
      apply lt_of_pow_lt_pow_left₀ 2 (norm_nonneg _)
      nlinarith [mul_pos (pow_pos hr 2) (neg_pos.2 hneg)]
    have := circleIndex_of_winding (linearField A) (0, 0) r (r * β) (r * α) (-1) 1 hlt
      (fun t => by rw [hexp t, add_comm])
    rw [this, Real.sign_of_neg hneg]; simp
  · have hlt : ‖(r : ℂ) * β‖ < ‖(r : ℂ) * α‖ := by
      apply lt_of_pow_lt_pow_left₀ 2 (norm_nonneg _)
      nlinarith [mul_pos (pow_pos hr 2) hpos]
    have := circleIndex_of_winding (linearField A) (0, 0) r (r * α) (r * β) 1 (-1) hlt hexp
    rw [this, Real.sign_of_pos hpos]; simp

/-- Step 2's key line: for the linear field on the unit circle `u = (cos t, sin t)`, the top of the
index formula, `f g' - g f'`, equals `det A` at every point of the walk. -/
theorem linear_numerator_eq_det (A : Matrix (Fin 2) (Fin 2) ℝ) (t : ℝ) :
    let f : ℝ → ℝ := fun s => (linearField A (cos s, sin s)).1
    let g : ℝ → ℝ := fun s => (linearField A (cos s, sin s)).2
    f t * deriv g t - g t * deriv f t = A.det := by
  intro f g
  have hf : HasDerivAt f (A 0 0 * -sin t + A 0 1 * cos t) t :=
    ((hasDerivAt_cos t).const_mul (A 0 0)).add ((hasDerivAt_sin t).const_mul (A 0 1))
  have hg : HasDerivAt g (A 1 0 * -sin t + A 1 1 * cos t) t :=
    ((hasDerivAt_cos t).const_mul (A 1 0)).add ((hasDerivAt_sin t).const_mul (A 1 1))
  rw [hf.deriv, hg.deriv, Matrix.det_fin_two A]
  simp only [f, g, linearField]
  linear_combination (A 0 0 * A 1 1 - A 0 1 * A 1 0) * sin_sq_add_cos_sq t

/-- The field `z ↦ zⁿ` (the point as `z = x + iy`) turns its arrow `n` times on any circle round
the origin; for `z²`, the field `(x² − y², 2xy)`, the index is 2. -/
theorem circleIndex_pow_eq (n : ℕ) (r : ℝ) (hr : 0 < r) :
    circleIndex (fun p => ((((p.1 : ℂ) + p.2 * Complex.I) ^ n).re,
                           (((p.1 : ℂ) + p.2 * Complex.I) ^ n).im)) (0, 0) r = n := by
  have hlt : ‖(0 : ℂ)‖ < ‖((r : ℂ) ^ n)‖ := by
    rw [norm_zero, norm_pow, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hr]
    positivity
  have := circleIndex_of_winding (fun p => ((((p.1 : ℂ) + p.2 * Complex.I) ^ n).re,
      (((p.1 : ℂ) + p.2 * Complex.I) ^ n).im)) (0, 0) r ((r : ℂ) ^ n) 0 (n : ℤ) 0 hlt (by
    intro t
    simp only [Complex.re_add_im, zero_mul, add_zero]
    have hz : (((0 : ℝ) + r * cos t : ℝ) : ℂ) + (((0 : ℝ) + r * sin t : ℝ) : ℂ) * Complex.I
        = r * Complex.exp ((t : ℂ) * Complex.I) := by
      rw [Complex.exp_mul_I]; push_cast; ring
    rw [hz, mul_pow, ← Complex.exp_nat_mul]
    congr 2
    push_cast; ring)
  rw [this]; simp

/-- Predator-prey with every rate 1: the arrow `(x - x y, -y + x y)`. -/
def predPrey (p : ℝ × ℝ) : ℝ × ℝ := (p.1 - p.1 * p.2, -p.2 + p.1 * p.2)

/-- Its Jacobian, the four slopes `[[1 - y, -x], [y, x - 1]]`. -/
def predPreyJac (p : ℝ × ℝ) : Matrix (Fin 2) (Fin 2) ℝ := !![1 - p.2, -p.1; p.2, p.1 - 1]

-- The arrow at E, N, W, S of the circle of radius 1/2 round (1, 1): up, west, down, east.
example : predPrey (3/2, 1) = (0, 1/2) := by norm_num [predPrey]
example : predPrey (1, 3/2) = (-1/2, 0) := by norm_num [predPrey]
example : predPrey (1/2, 1) = (0, -1/2) := by norm_num [predPrey]
example : predPrey (1, 1/2) = (1/2, 0) := by norm_num [predPrey]

-- The arrow at E, N, W, S of the circle of radius 1/2 round (0, 0): east, south, west, north.
example : predPrey (1/2, 0) = (1/2, 0) := by norm_num [predPrey]
example : predPrey (0, 1/2) = (0, -1/2) := by norm_num [predPrey]
example : predPrey (-1/2, 0) = (-1/2, 0) := by norm_num [predPrey]
example : predPrey (0, -1/2) = (0, 1/2) := by norm_num [predPrey]

-- det J is −1 at the saddle (0, 0) and +1 at the centre (1, 1); a loop round both counts −1 + 1 = 0.
example : (predPreyJac (0, 0)).det = -1 := by norm_num [predPreyJac, Matrix.det_fin_two_of]
example : (predPreyJac (1, 1)).det = 1 := by norm_num [predPreyJac, Matrix.det_fin_two_of]
example : (predPreyJac (0, 0)).det + (predPreyJac (1, 1)).det = 0 := by
  norm_num [predPreyJac, Matrix.det_fin_two_of]

-- The field z², `(x² − y², 2xy)`, at E, N, W, S of the unit circle: (1, 0), (−1, 0), (1, 0), (−1, 0).
example : ((1 : ℝ) ^ 2 - 0 ^ 2, 2 * 1 * 0) = ((1 : ℝ), (0 : ℝ)) := by norm_num
example : ((0 : ℝ) ^ 2 - 1 ^ 2, 2 * 0 * 1) = ((-1 : ℝ), (0 : ℝ)) := by norm_num
example : ((-1 : ℝ) ^ 2 - 0 ^ 2, 2 * (-1) * 0) = ((1 : ℝ), (0 : ℝ)) := by norm_num
example : ((0 : ℝ) ^ 2 - (-1) ^ 2, 2 * 0 * (-1)) = ((-1 : ℝ), (0 : ℝ)) := by norm_num

-- The swing `θ'' + θ'/2 + sin θ = 0`, Jacobian `[[0, 1], [-cos θ, -1/2]]`: hanging det +1,
-- upside down (θ = π) det −1.
example : Matrix.det !![(0 : ℝ), 1; -cos 0, -1/2] = 1 := by
  norm_num [Matrix.det_fin_two_of]
example : Matrix.det !![(0 : ℝ), 1; -cos π, -1/2] = -1 := by
  norm_num [Matrix.det_fin_two_of]

#print axioms circleIndex_linear_eq_sign_det
#print axioms linear_numerator_eq_det
#print axioms circleIndex_pow_eq
