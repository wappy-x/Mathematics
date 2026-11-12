-- The characteristic equation: e^(rt) solves a y'' + b y' + c y = 0 exactly when a r^2 + b r + c = 0, and with two real roots or one repeated root the exponential families hold every solution.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.MeanValue

/-- The derivative of `e^(r s)` at `t` is `r e^(r t)`. -/
lemma ce_hasDerivAt_exp (r t : ℝ) :
    HasDerivAt (fun s => Real.exp (r * s)) (r * Real.exp (r * t)) t := by
  have := ((hasDerivAt_id t).const_mul r).exp
  convert this using 1 <;> simp [mul_comm]

/-- If `y'' = (p + q) y' - p q y`, then `y' - q y = (y'(0) - q y(0)) e^(p t)`. -/
lemma ce_first_factor (p q : ℝ) (y : ℝ → ℝ) (hy : Differentiable ℝ y)
    (hy' : Differentiable ℝ (deriv y))
    (h : ∀ t, deriv (deriv y) t = (p + q) * deriv y t - p * q * y t) (t : ℝ) :
    deriv y t - q * y t = (deriv y 0 - q * y 0) * Real.exp (p * t) := by
  have hgd : ∀ t, HasDerivAt (fun t => (deriv y t - q * y t) * Real.exp (-p * t))
      ((deriv (deriv y) t - q * deriv y t) * Real.exp (-p * t)
        + (deriv y t - q * y t) * (-p * Real.exp (-p * t))) t := fun t =>
    ((hy' t).hasDerivAt.sub ((hy t).hasDerivAt.const_mul q)).mul (ce_hasDerivAt_exp (-p) t)
  have hc := is_const_of_deriv_eq_zero (fun t => (hgd t).differentiableAt)
    (fun t => by rw [(hgd t).deriv, h t]; ring) t 0
  simp only [mul_zero, Real.exp_zero, mul_one] at hc
  have e : Real.exp (-p * t) * Real.exp (p * t) = 1 := by
    rw [← Real.exp_add]; simp
  linear_combination (Real.exp (p * t)) * hc - (deriv y t - q * y t) * e

/-- If `y' - q y = K e^(p t)` with `p ≠ q`, then `y` is a mix of `e^(q t)` and `e^(p t)`. -/
lemma ce_second_distinct (p q K : ℝ) (hpq : p ≠ q) (y : ℝ → ℝ) (hy : Differentiable ℝ y)
    (h : ∀ t, deriv y t - q * y t = K * Real.exp (p * t)) (t : ℝ) :
    y t = (y 0 - K / (p - q)) * Real.exp (q * t) + K / (p - q) * Real.exp (p * t) := by
  have hpq' : p - q ≠ 0 := sub_ne_zero.mpr hpq
  have hgd : ∀ t, HasDerivAt
      (fun t => y t * Real.exp (-q * t) - K / (p - q) * Real.exp ((p - q) * t))
      (deriv y t * Real.exp (-q * t) + y t * (-q * Real.exp (-q * t))
        - K / (p - q) * ((p - q) * Real.exp ((p - q) * t))) t := fun t =>
    ((hy t).hasDerivAt.mul (ce_hasDerivAt_exp (-q) t)).sub
      ((ce_hasDerivAt_exp (p - q) t).const_mul (K / (p - q)))
  have hK : K / (p - q) * (p - q) = K := div_mul_cancel₀ K hpq'
  have hc := is_const_of_deriv_eq_zero (fun t => (hgd t).differentiableAt)
    (fun t => by
      rw [(hgd t).deriv]
      have e : Real.exp ((p - q) * t) = Real.exp (p * t) * Real.exp (-q * t) := by
        rw [← Real.exp_add]; ring_nf
      rw [e]
      linear_combination (Real.exp (-q * t)) * h t
        - (Real.exp (p * t) * Real.exp (-q * t)) * hK) t 0
  simp only [mul_zero, Real.exp_zero, mul_one] at hc
  have e1 : Real.exp (-q * t) * Real.exp (q * t) = 1 := by
    rw [← Real.exp_add]; simp
  have e2 : Real.exp ((p - q) * t) * Real.exp (q * t) = Real.exp (p * t) := by
    rw [← Real.exp_add]; ring_nf
  linear_combination (Real.exp (q * t)) * hc - y t * e1 + K / (p - q) * e2

/-- If `y' - r y = K e^(r t)`, then `y = (y(0) + K t) e^(r t)`. -/
lemma ce_second_repeated (r K : ℝ) (y : ℝ → ℝ) (hy : Differentiable ℝ y)
    (h : ∀ t, deriv y t - r * y t = K * Real.exp (r * t)) (t : ℝ) :
    y t = (y 0 + K * t) * Real.exp (r * t) := by
  have hgd : ∀ t, HasDerivAt (fun t => y t * Real.exp (-r * t) - K * t)
      (deriv y t * Real.exp (-r * t) + y t * (-r * Real.exp (-r * t)) - K * 1) t := fun t =>
    ((hy t).hasDerivAt.mul (ce_hasDerivAt_exp (-r) t)).sub ((hasDerivAt_id t).const_mul K)
  have hc := is_const_of_deriv_eq_zero (fun t => (hgd t).differentiableAt)
    (fun t => by
      rw [(hgd t).deriv]
      have e : Real.exp (r * t) * Real.exp (-r * t) = 1 := by
        rw [← Real.exp_add]; simp
      linear_combination (Real.exp (-r * t)) * h t + K * e) t 0
  simp only [mul_zero, Real.exp_zero, mul_one, sub_zero] at hc
  have e1 : Real.exp (-r * t) * Real.exp (r * t) = 1 := by
    rw [← Real.exp_add]; simp
  linear_combination (Real.exp (r * t)) * hc - y t * e1

#print axioms ce_hasDerivAt_exp
#print axioms ce_first_factor
#print axioms ce_second_distinct
#print axioms ce_second_repeated

/-- The guess: for a linear equation `a y'' + b y' + c y = 0` with constant real coefficients
and `a ≠ 0`, the exponential `y = e^(r t)` solves it at every time `t` exactly when its rate `r`
solves the characteristic equation `a r^2 + b r + c = 0`. -/
theorem exp_solves_iff_characteristic_root (a b c r : ℝ) (ha : a ≠ 0) :
    (∀ t : ℝ, a * deriv (deriv fun s => Real.exp (r * s)) t
        + b * deriv (fun s => Real.exp (r * s)) t + c * Real.exp (r * t) = 0) ↔
      a * r ^ 2 + b * r + c = 0 := by
  have d1 : deriv (fun s => Real.exp (r * s)) = fun s => r * Real.exp (r * s) :=
    funext fun t => (ce_hasDerivAt_exp r t).deriv
  have d2 : deriv (fun s => r * Real.exp (r * s)) = fun s => r * (r * Real.exp (r * s)) :=
    funext fun t => ((ce_hasDerivAt_exp r t).const_mul r).deriv
  rw [d1, d2]
  constructor
  · intro h
    have h0 := h 0
    simp only [mul_zero, Real.exp_zero, mul_one] at h0
    linear_combination h0
  · intro h t
    linear_combination (Real.exp (r * t)) * h

/-- Two real roots: if `a ≠ 0` and the discriminant `Δ = b^2 - 4ac` is positive, with
`r₁, r₂ = (-b ± √Δ)/(2a)`, then a twice differentiable `y` solves `a y'' + b y' + c y = 0`
at every time exactly when `y = C₁ e^(r₁ t) + C₂ e^(r₂ t)` for some constants `C₁, C₂`.
So the two-exponential mixes are every solution. -/
theorem solutions_of_distinct_real_roots (a b c : ℝ) (ha : a ≠ 0)
    (hΔ : 0 < b ^ 2 - 4 * a * c) (y : ℝ → ℝ)
    (hy : Differentiable ℝ y) (hy' : Differentiable ℝ (deriv y)) :
    (∀ t : ℝ, a * deriv (deriv y) t + b * deriv y t + c * y t = 0) ↔
      ∃ C₁ C₂ : ℝ, ∀ t : ℝ,
        y t = C₁ * Real.exp ((-b + Real.sqrt (b ^ 2 - 4 * a * c)) / (2 * a) * t)
          + C₂ * Real.exp ((-b - Real.sqrt (b ^ 2 - 4 * a * c)) / (2 * a) * t) := by
  set s := Real.sqrt (b ^ 2 - 4 * a * c) with hs_def
  have hs2 : s ^ 2 = b ^ 2 - 4 * a * c := Real.sq_sqrt hΔ.le
  have hs0 : 0 < s := Real.sqrt_pos.mpr hΔ
  set r₁ := (-b + s) / (2 * a) with hr₁
  set r₂ := (-b - s) / (2 * a) with hr₂
  have hsum : a * (r₁ + r₂) = -b := by
    rw [hr₁, hr₂]; field_simp; ring
  have hprod : a * (r₁ * r₂) = c := by
    rw [hr₁, hr₂]; field_simp; linear_combination (-1 : ℝ) * hs2
  have hne : r₁ ≠ r₂ := by
    intro heq
    have : a * (r₁ - r₂) = s := by rw [hr₁, hr₂]; field_simp; ring
    rw [heq, sub_self, mul_zero] at this
    linarith
  have hroot₁ : a * r₁ ^ 2 + b * r₁ + c = 0 := by
    linear_combination r₁ * hsum - hprod
  have hroot₂ : a * r₂ ^ 2 + b * r₂ + c = 0 := by
    linear_combination r₂ * hsum - hprod
  constructor
  · intro h
    have h' : ∀ t, deriv (deriv y) t = (r₁ + r₂) * deriv y t - r₁ * r₂ * y t := by
      intro t
      apply mul_left_cancel₀ ha
      linear_combination h t - deriv y t * hsum + y t * hprod
    have hf := ce_first_factor r₁ r₂ y hy hy' h'
    refine ⟨(deriv y 0 - r₂ * y 0) / (r₁ - r₂),
      y 0 - (deriv y 0 - r₂ * y 0) / (r₁ - r₂), fun t => ?_⟩
    rw [ce_second_distinct r₁ r₂ _ hne y hy hf t]
    ring
  · rintro ⟨C₁, C₂, hC⟩
    have hyeq : y = fun t => C₁ * Real.exp (r₁ * t) + C₂ * Real.exp (r₂ * t) := funext hC
    subst hyeq
    have d1 : deriv (fun t => C₁ * Real.exp (r₁ * t) + C₂ * Real.exp (r₂ * t))
        = fun t => C₁ * (r₁ * Real.exp (r₁ * t)) + C₂ * (r₂ * Real.exp (r₂ * t)) :=
      funext fun t => (((ce_hasDerivAt_exp r₁ t).const_mul C₁).add
        ((ce_hasDerivAt_exp r₂ t).const_mul C₂)).deriv
    have d2 : deriv (fun t => C₁ * (r₁ * Real.exp (r₁ * t)) + C₂ * (r₂ * Real.exp (r₂ * t)))
        = fun t => C₁ * (r₁ * (r₁ * Real.exp (r₁ * t)))
            + C₂ * (r₂ * (r₂ * Real.exp (r₂ * t))) :=
      funext fun t => ((((ce_hasDerivAt_exp r₁ t).const_mul r₁).const_mul C₁).add
        (((ce_hasDerivAt_exp r₂ t).const_mul r₂).const_mul C₂)).deriv
    intro t
    rw [d1, d2]
    linear_combination (C₁ * Real.exp (r₁ * t)) * hroot₁ + (C₂ * Real.exp (r₂ * t)) * hroot₂

/-- One repeated root: if `a ≠ 0` and the discriminant `b^2 - 4ac` is zero, with
`r = -b/(2a)`, then a twice differentiable `y` solves `a y'' + b y' + c y = 0` at every time
exactly when `y = (C₁ + C₂ t) e^(r t)` for some constants `C₁, C₂`.
So `e^(r t)` and `t e^(r t)` together give every solution. -/
theorem solutions_of_repeated_root (a b c : ℝ) (ha : a ≠ 0)
    (hΔ : b ^ 2 - 4 * a * c = 0) (y : ℝ → ℝ)
    (hy : Differentiable ℝ y) (hy' : Differentiable ℝ (deriv y)) :
    (∀ t : ℝ, a * deriv (deriv y) t + b * deriv y t + c * y t = 0) ↔
      ∃ C₁ C₂ : ℝ, ∀ t : ℝ, y t = (C₁ + C₂ * t) * Real.exp (-b / (2 * a) * t) := by
  set r := -b / (2 * a) with hr
  have hsum : a * (r + r) = -b := by
    rw [hr]; field_simp; ring
  have hprod : a * (r * r) = c := by
    rw [hr]; field_simp; linear_combination hΔ
  have hroot : a * r ^ 2 + b * r + c = 0 := by
    linear_combination r * hsum - hprod
  have hd : 2 * a * r + b = 0 := by linear_combination hsum
  constructor
  · intro h
    have h' : ∀ t, deriv (deriv y) t = (r + r) * deriv y t - r * r * y t := by
      intro t
      apply mul_left_cancel₀ ha
      linear_combination h t - deriv y t * hsum + y t * hprod
    have hf := ce_first_factor r r y hy hy' h'
    refine ⟨y 0, deriv y 0 - r * y 0, fun t => ?_⟩
    exact ce_second_repeated r _ y hy hf t
  · rintro ⟨C₁, C₂, hC⟩
    have hyeq : y = fun t => (C₁ + C₂ * t) * Real.exp (r * t) := funext hC
    subst hyeq
    have hlin : ∀ t : ℝ, HasDerivAt (fun t => C₁ + C₂ * t) C₂ t := fun t => by
      simpa using ((hasDerivAt_id t).const_mul C₂).const_add C₁
    have d1 : deriv (fun t => (C₁ + C₂ * t) * Real.exp (r * t))
        = fun t => C₂ * Real.exp (r * t) + (C₁ + C₂ * t) * (r * Real.exp (r * t)) :=
      funext fun t => ((hlin t).mul (ce_hasDerivAt_exp r t)).deriv
    have d2 : deriv (fun t => C₂ * Real.exp (r * t) + (C₁ + C₂ * t) * (r * Real.exp (r * t)))
        = fun t => C₂ * (r * Real.exp (r * t)) + (C₂ * (r * Real.exp (r * t))
            + (C₁ + C₂ * t) * (r * (r * Real.exp (r * t)))) :=
      funext fun t => (((ce_hasDerivAt_exp r t).const_mul C₂).add
        ((hlin t).mul ((ce_hasDerivAt_exp r t).const_mul r))).deriv
    intro t
    rw [d1, d2]
    linear_combination ((C₁ + C₂ * t) * Real.exp (r * t)) * hroot
      + (C₂ * Real.exp (r * t)) * hd

-- The car with damper 6: discriminant 36 - 20 = 16.
example : (6 : ℤ) ^ 2 - 4 * 1 * 5 = 16 := by norm_num

-- Its roots (-6 ± 4)/2 are -1 and -5, and r^2 + 6r + 5 = (r + 1)(r + 5).
example : ((-6 : ℚ) + 4) / 2 = -1 ∧ ((-6 : ℚ) - 4) / 2 = -5 := by norm_num
example (r : ℚ) : r ^ 2 + 6 * r + 5 = (r + 1) * (r + 5) := by ring

-- Fitting the start: C1 = 5/4 and C2 = -1/4 give C1 + C2 = 1 and -C1 - 5 C2 = 0.
example : (5 / 4 : ℚ) + (-1 / 4) = 1 ∧ -(5 / 4 : ℚ) - 5 * (-1 / 4) = 0 := by norm_num

-- The critical damper b = 2√5 makes the discriminant zero.
example : (2 * Real.sqrt 5) ^ 2 - 4 * 1 * 5 = 0 := by
  rw [mul_pow, Real.sq_sqrt (by norm_num)]; norm_num

-- The bouncing car b = 2: discriminant 4 - 20 = -16, so the roots are complex.
example : (2 : ℤ) ^ 2 - 4 * 1 * 5 = -16 := by norm_num

-- Cauchy-Euler t^2 y'' + t y' - y with y = e^t leaves (t^2 + t - 1) e^t: 1 at t = 1, 5 at t = 2.
example : (1 : ℤ) ^ 2 + 1 - 1 = 1 ∧ (2 : ℤ) ^ 2 + 2 - 1 = 5 := by norm_num

-- With y = t it leaves t^2 * 0 + t * 1 - t = 0 at t = 2.
example : (2 : ℤ) ^ 2 * 0 + 2 * 1 - 2 = 0 := by norm_num

#print axioms exp_solves_iff_characteristic_root
#print axioms solutions_of_distinct_real_roots
#print axioms solutions_of_repeated_root
