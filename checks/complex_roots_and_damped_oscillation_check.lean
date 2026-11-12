-- Complex roots: when p^2 < 4q, every solution of y'' + p y' + q y = 0 is e^(at)(C cos bt + D sin bt) with a = -p/2 and b = sqrt(q - p^2/4), every such curve is a solution, and the motion stays inside the envelope sqrt(C^2 + D^2) e^(at).
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Complex.Basic

open Real

lemma damped_hasDerivAt_expcs (a b c d t : ℝ) :
    HasDerivAt (fun t => Real.exp (a * t) * (c * Real.cos (b * t) + d * Real.sin (b * t)))
      (Real.exp (a * t) * ((a * c + b * d) * Real.cos (b * t) + (a * d - b * c) * Real.sin (b * t))) t := by
  have h1 : HasDerivAt (fun t => Real.exp (a * t)) (Real.exp (a * t) * a) t := by
    have := ((hasDerivAt_id t).const_mul a).exp
    simpa using this
  have hc : HasDerivAt (fun t => Real.cos (b * t)) (-Real.sin (b * t) * b) t := by
    have := ((hasDerivAt_id t).const_mul b).cos
    simpa using this
  have hs : HasDerivAt (fun t => Real.sin (b * t)) (Real.cos (b * t) * b) t := by
    have := ((hasDerivAt_id t).const_mul b).sin
    simpa using this
  have h := h1.mul ((hc.const_mul c).add (hs.const_mul d))
  convert h using 1
  simp only [Pi.add_apply]
  ring

lemma damped_deriv_expcs (a b c d : ℝ) :
    deriv (fun t => Real.exp (a * t) * (c * Real.cos (b * t) + d * Real.sin (b * t))) =
      fun t => Real.exp (a * t) * ((a * c + b * d) * Real.cos (b * t) + (a * d - b * c) * Real.sin (b * t)) := by
  funext t
  exact (damped_hasDerivAt_expcs a b c d t).deriv

lemma damped_energy_const (a b : ℝ) (z : ℝ → ℝ) (hz : Differentiable ℝ z)
    (hz' : Differentiable ℝ (deriv z))
    (hode : ∀ t, deriv (deriv z) t = 2 * a * deriv z t - (a ^ 2 + b ^ 2) * z t) (t : ℝ) :
    Real.exp (-2 * a * t) * ((deriv z t - a * z t) ^ 2 + b ^ 2 * z t ^ 2) =
      (deriv z 0 - a * z 0) ^ 2 + b ^ 2 * z 0 ^ 2 := by
  let E : ℝ → ℝ := fun t => Real.exp (-2 * a * t) * ((deriv z t - a * z t) ^ 2 + b ^ 2 * z t ^ 2)
  have hd : ∀ t, HasDerivAt E 0 t := by
    intro t
    have h1 : HasDerivAt (fun t => Real.exp (-2 * a * t)) (Real.exp (-2 * a * t) * (-2 * a)) t := by
      have := ((hasDerivAt_id t).const_mul (-2 * a)).exp
      simpa using this
    have h2 := (hz t).hasDerivAt
    have h3 := (hz' t).hasDerivAt
    have h4 := ((h3.sub (h2.const_mul a)).pow 2).add ((h2.pow 2).const_mul (b ^ 2))
    have h5 := h1.mul h4
    convert h5 using 1
    rw [hode t]
    simp only [Pi.add_apply, Pi.sub_apply, Pi.pow_apply]
    push_cast
    ring
  have := is_const_of_deriv_eq_zero (fun t => (hd t).differentiableAt) (fun t => (hd t).deriv) t 0
  simpa [E] using this

#print axioms damped_hasDerivAt_expcs
#print axioms damped_deriv_expcs
#print axioms damped_energy_const

/-- Complex roots give every solution: if the characteristic equation r^2 + p r + q = 0 has
complex roots a ± ib (that is, p^2 < 4q, with a = -p/2 and b = sqrt(q - p^2/4)), then every
real solution of y'' + p y' + q y = 0 with constant real p and q is
y(t) = e^(at)(C cos bt + D sin bt), where C = y(0) and D = (y'(0) - a C)/b. -/
theorem damped_solution_eq_exp_mul_cos_sin (p q a b : ℝ) (y : ℝ → ℝ)
    (hpq : p ^ 2 < 4 * q) (ha : a = -p / 2) (hb : b = Real.sqrt (q - p ^ 2 / 4))
    (hy : Differentiable ℝ y) (hy' : Differentiable ℝ (deriv y))
    (hode : ∀ t, deriv (deriv y) t + p * deriv y t + q * y t = 0) :
    ∀ t, y t = Real.exp (a * t) *
      (y 0 * Real.cos (b * t) + (deriv y 0 - a * y 0) / b * Real.sin (b * t)) := by
  intro t
  have hq : 0 < q - p ^ 2 / 4 := by linarith
  have hbpos : 0 < b := by rw [hb]; exact Real.sqrt_pos.mpr hq
  have hb2 : b ^ 2 = q - p ^ 2 / 4 := by rw [hb]; exact Real.sq_sqrt hq.le
  have hY : ∀ c d : ℝ, Differentiable ℝ
      (fun t => Real.exp (a * t) * (c * Real.cos (b * t) + d * Real.sin (b * t))) :=
    fun c d t => (damped_hasDerivAt_expcs a b c d t).differentiableAt
  set C := y 0 with hC
  set D := (deriv y 0 - a * y 0) / b with hD
  set z : ℝ → ℝ := fun t => y t - Real.exp (a * t) * (C * Real.cos (b * t) + D * Real.sin (b * t))
    with hzdef
  have hz : Differentiable ℝ z := hy.sub (hY C D)
  have hdz : deriv z = fun t => deriv y t - Real.exp (a * t) *
      ((a * C + b * D) * Real.cos (b * t) + (a * D - b * C) * Real.sin (b * t)) := by
    funext s
    rw [hzdef]
    exact ((hy s).hasDerivAt.sub (damped_hasDerivAt_expcs a b C D s)).deriv
  have hz' : Differentiable ℝ (deriv z) := by rw [hdz]; exact hy'.sub (hY _ _)
  have hddz : ∀ s, deriv (deriv z) s = deriv (deriv y) s - Real.exp (a * s) *
      ((a * (a * C + b * D) + b * (a * D - b * C)) * Real.cos (b * s) +
        (a * (a * D - b * C) - b * (a * C + b * D)) * Real.sin (b * s)) := by
    intro s
    rw [hdz]
    exact ((hy' s).hasDerivAt.sub (damped_hasDerivAt_expcs a b _ _ s)).deriv
  have hodez : ∀ s, deriv (deriv z) s = 2 * a * deriv z s - (a ^ 2 + b ^ 2) * z s := by
    intro s
    rw [hddz, hdz]
    simp only [hzdef]
    linear_combination hode s + (-2 * deriv y s + (a - p / 2) * y s) * ha + y s * hb2
  have hE := damped_energy_const a b z hz hz' hodez t
  have hz0 : z 0 = 0 := by simp [hzdef, hC]
  have hdz0 : deriv z 0 = 0 := by
    rw [hdz]
    simp only [mul_zero, Real.exp_zero, Real.cos_zero, Real.sin_zero, one_mul, mul_one]
    rw [hD]
    field_simp
    ring
  rw [hz0, hdz0] at hE
  have hpos := Real.exp_pos (-2 * a * t)
  have h0 : (deriv z t - a * z t) ^ 2 + b ^ 2 * z t ^ 2 = 0 := by
    have : Real.exp (-2 * a * t) * ((deriv z t - a * z t) ^ 2 + b ^ 2 * z t ^ 2) = 0 := by
      rw [hE]; ring
    rcases mul_eq_zero.mp this with h | h
    · linarith
    · exact h
  have hzt : z t = 0 := by
    have hb2pos : 0 < b ^ 2 := by positivity
    have : b ^ 2 * z t ^ 2 = 0 := by nlinarith [sq_nonneg (deriv z t - a * z t), sq_nonneg (z t)]
    have : z t ^ 2 = 0 := by
      rcases mul_eq_zero.mp this with h | h
      · linarith
      · exact h
    exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
  simp only [hzdef] at hzt
  linarith

/-- The method works: with a = -p/2 and b = sqrt(q - p^2/4), for any amounts C and D the
curve e^(at)(C cos bt + D sin bt) solves y'' + p y' + q y = 0. -/
theorem exp_mul_cos_sin_solves_damped (p q a b C D : ℝ)
    (hpq : p ^ 2 < 4 * q) (ha : a = -p / 2) (hb : b = Real.sqrt (q - p ^ 2 / 4)) :
    let y : ℝ → ℝ := fun t => Real.exp (a * t) * (C * Real.cos (b * t) + D * Real.sin (b * t))
    ∀ t, deriv (deriv y) t + p * deriv y t + q * y t = 0 := by
  intro y t
  have hq : 0 < q - p ^ 2 / 4 := by linarith
  have hb2 : b ^ 2 = q - p ^ 2 / 4 := by rw [hb]; exact Real.sq_sqrt hq.le
  simp only [y, damped_deriv_expcs]
  subst ha
  linear_combination (-(Real.exp (-p / 2 * t) * (C * Real.cos (b * t) + D * Real.sin (b * t)))) * hb2

/-- The envelope: a solution of y'' + p y' + q y = 0 with p^2 < 4q never leaves the band
± R e^(at), where R = sqrt(C^2 + D^2), C = y(0) and D = (y'(0) - a C)/b. -/
theorem damped_solution_within_envelope (p q a b : ℝ) (y : ℝ → ℝ)
    (hpq : p ^ 2 < 4 * q) (ha : a = -p / 2) (hb : b = Real.sqrt (q - p ^ 2 / 4))
    (hy : Differentiable ℝ y) (hy' : Differentiable ℝ (deriv y))
    (hode : ∀ t, deriv (deriv y) t + p * deriv y t + q * y t = 0) :
    ∀ t, |y t| ≤ Real.sqrt (y 0 ^ 2 + ((deriv y 0 - a * y 0) / b) ^ 2) * Real.exp (a * t) := by
  intro t
  have hq : 0 < q - p ^ 2 / 4 := by linarith
  have hbpos : 0 < b := by rw [hb]; exact Real.sqrt_pos.mpr hq
  have hb2 : b ^ 2 = q - p ^ 2 / 4 := by rw [hb]; exact Real.sq_sqrt hq.le
  have hodey : ∀ s, deriv (deriv y) s = 2 * a * deriv y s - (a ^ 2 + b ^ 2) * y s := by
    intro s
    linear_combination hode s + (-2 * deriv y s + (a - p / 2) * y s) * ha + y s * hb2
  have hE := damped_energy_const a b y hy hy' hodey t
  set S := y 0 ^ 2 + ((deriv y 0 - a * y 0) / b) ^ 2 with hSdef
  have hS0 : 0 ≤ S := by positivity
  have hS : (deriv y 0 - a * y 0) ^ 2 + b ^ 2 * y 0 ^ 2 = b ^ 2 * S := by
    rw [hSdef]; field_simp; ring
  have h1 : Real.exp (-2 * a * t) * Real.exp (a * t) ^ 2 = 1 := by
    rw [sq, ← Real.exp_add, ← Real.exp_add]
    ring_nf
    simp
  have hb2pos : 0 < b ^ 2 := by positivity
  have hx := Real.exp_pos (a * t)
  have hx2 := Real.exp_pos (-2 * a * t)
  have key : b ^ 2 * y t ^ 2 ≤ b ^ 2 * (S * Real.exp (a * t) ^ 2) := by
    have e1 : b ^ 2 * y t ^ 2 = Real.exp (a * t) ^ 2 *
        (Real.exp (-2 * a * t) * (b ^ 2 * y t ^ 2)) := by
      linear_combination (-(b ^ 2 * y t ^ 2)) * h1
    rw [e1]
    have e2 : Real.exp (-2 * a * t) * (b ^ 2 * y t ^ 2) ≤ b ^ 2 * S := by
      rw [← hS, ← hE]
      have := sq_nonneg (deriv y t - a * y t)
      nlinarith
    have := mul_le_mul_of_nonneg_left e2 (sq_nonneg (Real.exp (a * t)))
    linarith
  have key2 : y t ^ 2 ≤ S * Real.exp (a * t) ^ 2 := le_of_mul_le_mul_left key hb2pos
  calc |y t| ≤ Real.sqrt (S * Real.exp (a * t) ^ 2) := Real.abs_le_sqrt key2
    _ = Real.sqrt S * Real.exp (a * t) := by
      rw [Real.sqrt_mul hS0, Real.sqrt_sq hx.le]

-- The car, y'' + 2y' + 5y = 0: the discriminant p^2 - 4q is -16, so the roots are complex.
example : (2 : ℤ) ^ 2 - 4 * 5 = -16 := by norm_num
-- Real part a = -2/2 = -1; imaginary part b = sqrt(5 - 2^2/4) = sqrt 4 = 2.
example : -(2 : ℝ) / 2 = -1 := by norm_num
example : Real.sqrt (5 - 2 ^ 2 / 4) = 2 := by
  rw [show (5 : ℝ) - 2 ^ 2 / 4 = 2 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- -1 + 2i is a root of r^2 + 2r + 5: (-1 + 2i)^2 = -3 - 4i, and -3 - 4i + 2(-1 + 2i) + 5 = 0.
example : ((-1 + 2 * Complex.I) ^ 2 : ℂ) = -3 - 4 * Complex.I := by
  ring_nf; rw [Complex.I_sq]; ring
example : ((-1 + 2 * Complex.I) ^ 2 + 2 * (-1 + 2 * Complex.I) + 5 : ℂ) = 0 := by
  ring_nf; rw [Complex.I_sq]; ring
-- From rest at 1 cm: C = 1 and D = (0 - (-1)(1))/2 = 1/2.
example : ((0 : ℚ) - (-1) * 1) / 2 = 1 / 2 := by norm_num
-- Envelope squared: R^2 = 1^2 + (1/2)^2 = 5/4.
example : (1 : ℚ) ^ 2 + (1 / 2) ^ 2 = 5 / 4 := by norm_num

#print axioms damped_solution_eq_exp_mul_cos_sin
#print axioms exp_mul_cos_sin_solves_damped
#print axioms damped_solution_within_envelope
