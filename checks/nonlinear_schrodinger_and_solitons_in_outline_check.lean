-- Solitons: the sech pulse at peak power |β₂|/(γ T₀²) solves the fibre's nonlinear Schrödinger equation exactly when β₂ < 0, every scaled pulse a sech(aτ) e^(i a² Z/2) solves the scaled equation, and the hump 2κ² sech²(κ(x − 4κ²t)) solves KdV.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Complex.RealDeriv

open Complex

/-! Notation as on the card. `A z t` is the complex envelope at distance `z` and time `t`;
its power is `‖A z t‖²`. Rates are ordinary derivatives of one variable with the other held
fixed: `A_z` is `deriv (fun z' => A z' t) z`, and `A_tt` is the second derivative in `t`.
`sech = 1 / cosh`, written out since Mathlib has no `sech`. -/

lemma nls_sech_hasDerivAt (C : ℝ) {h : ℝ → ℝ} {h' t : ℝ} (hh : HasDerivAt h h' t) :
    HasDerivAt (fun t => C / Real.cosh (h t))
      (C * (-Real.sinh (h t) / Real.cosh (h t) ^ 2 * h')) t := by
  have hc : Real.cosh (h t) ≠ 0 := (Real.cosh_pos _).ne'
  convert (hasDerivAt_const t C).div hh.cosh hc using 1
  field_simp
  ring

#print axioms nls_sech_hasDerivAt

lemma nls_sech1_hasDerivAt (C : ℝ) {h : ℝ → ℝ} {h' t : ℝ} (hh : HasDerivAt h h' t) :
    HasDerivAt (fun t => C * (-Real.sinh (h t) / Real.cosh (h t) ^ 2 * h'))
      (C * ((1 / Real.cosh (h t) - 2 / Real.cosh (h t) ^ 3) * h' * h')) t := by
  have hc : Real.cosh (h t) ≠ 0 := (Real.cosh_pos _).ne'
  have := ((hh.sinh.neg.div (hh.cosh.pow 2) (pow_ne_zero 2 hc)).mul_const h').const_mul C
  convert this using 1
  simp only [Pi.pow_apply, Pi.neg_apply]
  have e := Real.cosh_sq (h t)
  field_simp
  linear_combination (2 * C * Real.cosh (h t) * h' ^ 2) * e

#print axioms nls_sech1_hasDerivAt

lemma kdv_g0_hasDerivAt (C : ℝ) {h : ℝ → ℝ} {h' t : ℝ} (hh : HasDerivAt h h' t) :
    HasDerivAt (fun t => C / Real.cosh (h t) ^ 2)
      (C * (-2 * Real.sinh (h t) / Real.cosh (h t) ^ 3) * h') t := by
  have hc : Real.cosh (h t) ≠ 0 := (Real.cosh_pos _).ne'
  convert (hasDerivAt_const t C).div (hh.cosh.pow 2) (pow_ne_zero 2 hc) using 1
  simp only [Pi.pow_apply]
  field_simp
  ring

#print axioms kdv_g0_hasDerivAt

lemma kdv_g1_hasDerivAt (C k : ℝ) {h : ℝ → ℝ} {h' t : ℝ} (hh : HasDerivAt h h' t) :
    HasDerivAt (fun t => C * (-2 * Real.sinh (h t) / Real.cosh (h t) ^ 3) * k)
      (C * (4 / Real.cosh (h t) ^ 2 - 6 / Real.cosh (h t) ^ 4) * h' * k) t := by
  have hc : Real.cosh (h t) ≠ 0 := (Real.cosh_pos _).ne'
  have := (((hh.sinh.const_mul (-2)).div (hh.cosh.pow 3) (pow_ne_zero 3 hc)).const_mul C).mul_const k
  convert this using 1
  simp only [Pi.pow_apply]
  have e := Real.cosh_sq (h t)
  field_simp
  linear_combination (6 * C * Real.cosh (h t) ^ 2 * h' * k) * e

#print axioms kdv_g1_hasDerivAt

lemma kdv_g2_hasDerivAt (C k k' : ℝ) {h : ℝ → ℝ} {h' t : ℝ} (hh : HasDerivAt h h' t) :
    HasDerivAt (fun t => C * (4 / Real.cosh (h t) ^ 2 - 6 / Real.cosh (h t) ^ 4) * k * k')
      (C * (-8 * Real.sinh (h t) / Real.cosh (h t) ^ 3
        + 24 * Real.sinh (h t) / Real.cosh (h t) ^ 5) * h' * k * k') t := by
  have hc : Real.cosh (h t) ≠ 0 := (Real.cosh_pos _).ne'
  have := ((((hasDerivAt_const t (4:ℝ)).div (hh.cosh.pow 2) (pow_ne_zero 2 hc)).sub
    ((hasDerivAt_const t (6:ℝ)).div (hh.cosh.pow 4) (pow_ne_zero 4 hc))).const_mul C).mul_const k |>.mul_const k'
  convert this using 1
  simp only [Pi.pow_apply]
  field_simp
  ring

#print axioms kdv_g2_hasDerivAt

/-- The fibre soliton. In fibre with anomalous dispersion, `β₂ < 0`, the pulse
`A = √P₀ · sech(t/T₀) · e^(i z/(2 L_D))`, with peak power `P₀ = |β₂|/(γ T₀²)` and dispersion
length `L_D = T₀²/|β₂|`, solves the nonlinear Schrödinger equation
`i A_z − (β₂/2) A_tt + γ |A|² A = 0` at every distance and time: it keeps its shape and only
turns its phase. -/
theorem sech_pulse_solves_fibre_nls (β₂ γ T₀ : ℝ) (hβ : β₂ < 0) :
    let P₀ : ℝ := |β₂| / (γ * T₀ ^ 2)
    let L_D : ℝ := T₀ ^ 2 / |β₂|
    let A : ℝ → ℝ → ℂ := fun z t =>
      (Real.sqrt P₀ : ℂ) * ((1 / Real.cosh (t / T₀) : ℝ) : ℂ) * cexp (I * ((z / (2 * L_D) : ℝ) : ℂ))
    ∀ z t : ℝ,
      I * deriv (fun z' => A z' t) z
        - ((β₂ / 2 : ℝ) : ℂ) * deriv (fun t' => deriv (fun t'' => A z t'') t') t
        + (γ : ℂ) * (‖A z t‖ : ℂ) ^ 2 * A z t = 0 := by
  intro P₀ L_D A z t
  simp only [A]
  set K : ℂ := (Real.sqrt P₀ : ℂ) with hK
  set E := cexp (I * ((z / (2 * L_D) : ℝ) : ℂ)) with hE
  have hT : ∀ y : ℝ, HasDerivAt (fun y => y / T₀) (1 / T₀) y := fun y =>
    (hasDerivAt_id' y).div_const T₀
  have hZ : HasDerivAt (fun z' => K * ((1 / Real.cosh (t / T₀) : ℝ) : ℂ)
      * cexp (I * ((z' / (2 * L_D) : ℝ) : ℂ)))
      (K * ((1 / Real.cosh (t / T₀) : ℝ) : ℂ) * (E * (I * ((1 / (2 * L_D) : ℝ) : ℂ)))) z := by
    exact (((hasDerivAt_id' z).div_const (2 * L_D)).ofReal_comp.const_mul I).cexp.const_mul _
  have D1 : (fun t' => deriv (fun t'' => K * ((1 / Real.cosh (t'' / T₀) : ℝ) : ℂ) * E) t')
      = fun t' => K * ((1 * (-Real.sinh (t' / T₀) / Real.cosh (t' / T₀) ^ 2 * (1 / T₀)) : ℝ) : ℂ)
          * E :=
    funext fun y => (((nls_sech_hasDerivAt 1 (hT y)).ofReal_comp.const_mul K).mul_const E).deriv
  have D2 := (((nls_sech1_hasDerivAt 1 (hT t)).ofReal_comp.const_mul K).mul_const E).deriv
  rw [hZ.deriv, D1, D2]
  by_cases hP : 0 < P₀
  swap
  · have hs : Real.sqrt P₀ = 0 := Real.sqrt_eq_zero'.mpr (not_lt.mp hP)
    simp [hK, hs]
  have hγT : γ * T₀ ^ 2 ≠ 0 := by
    intro h0
    simp [P₀, h0] at hP
  have hT0 : T₀ ≠ 0 := by
    intro h0; apply hγT; simp [h0]
  have hn : (‖K * ((1 / Real.cosh (t / T₀) : ℝ) : ℂ) * E‖ : ℂ) ^ 2
      = ((P₀ * (1 / Real.cosh (t / T₀)) ^ 2 : ℝ) : ℂ) := by
    rw [norm_mul, norm_mul, hE, mul_comm I, Complex.norm_exp_ofReal_mul_I, mul_one, hK,
      Complex.norm_real, Complex.norm_real, Real.norm_eq_abs, Real.norm_eq_abs,
      abs_of_nonneg (Real.sqrt_nonneg _), ← Complex.ofReal_pow, mul_pow, Real.sq_sqrt hP.le,
      sq_abs]
  rw [hn]
  have hL : (1 / (2 * L_D) : ℝ) = -β₂ / (2 * T₀ ^ 2) := by
    simp only [L_D]
    rw [abs_of_neg hβ]
    have : β₂ ≠ 0 := hβ.ne
    field_simp
  have hγP : γ * P₀ = -β₂ / T₀ ^ 2 := by
    have hγ : γ ≠ 0 := left_ne_zero_of_mul hγT
    simp only [P₀]
    rw [abs_of_neg hβ]
    field_simp
  have hγP' : (γ : ℂ) * (P₀ : ℂ) = -(β₂ : ℂ) / (T₀ : ℂ) ^ 2 := by
    exact_mod_cast hγP
  rw [hL]
  set c := Real.cosh (t / T₀) with hc
  have hc0 : (c : ℂ) ≠ 0 := by exact_mod_cast (Real.cosh_pos _).ne'
  push_cast
  linear_combination (K * (1 / (c : ℂ)) * E * (-(β₂ : ℂ) / (2 * (T₀ : ℂ) ^ 2))) * I_mul_I
    + ((1 / (c : ℂ)) ^ 2 * (K * (1 / (c : ℂ)) * E)) * hγP'

/-- The scaled family (Step 2's fold). In scaled units, for every real amplitude `a`, the pulse
`u = a · sech(aτ) · e^(i a² Z/2)` solves `i u_Z + ½ u_ττ + |u|² u = 0`: a taller soliton is
narrower in proportion. With `a = 1` this is `sech τ · e^(iZ/2)`. -/
theorem scaled_sech_family_solves_nls (a : ℝ) :
    let u : ℝ → ℝ → ℂ := fun Z τ =>
      ((a / Real.cosh (a * τ) : ℝ) : ℂ) * cexp (I * ((a ^ 2 * Z / 2 : ℝ) : ℂ))
    ∀ Z τ : ℝ,
      I * deriv (fun Z' => u Z' τ) Z
        + (1 / 2 : ℂ) * deriv (fun τ' => deriv (fun τ'' => u Z τ'') τ') τ
        + (‖u Z τ‖ : ℂ) ^ 2 * u Z τ = 0 := by
  intro u Z τ
  simp only [u]
  set E := cexp (I * ((a ^ 2 * Z / 2 : ℝ) : ℂ)) with hE
  have hτ : ∀ y : ℝ, HasDerivAt (fun y => a * y) a y := fun y => by
    simpa using (hasDerivAt_id' y).const_mul a
  have hZ : HasDerivAt (fun Z' => ((a / Real.cosh (a * τ) : ℝ) : ℂ)
      * cexp (I * ((a ^ 2 * Z' / 2 : ℝ) : ℂ)))
      (((a / Real.cosh (a * τ) : ℝ) : ℂ) * (E * (I * ((a ^ 2 * 1 / 2 : ℝ) : ℂ)))) Z := by
    exact ((((hasDerivAt_id' Z).const_mul (a ^ 2)).div_const 2).ofReal_comp.const_mul I).cexp.const_mul _
  have D1 : (fun τ' => deriv (fun τ'' => ((a / Real.cosh (a * τ'') : ℝ) : ℂ) * E) τ')
      = fun τ' => ((a * (-Real.sinh (a * τ') / Real.cosh (a * τ') ^ 2 * a) : ℝ) : ℂ) * E :=
    funext fun y => ((nls_sech_hasDerivAt a (hτ y)).ofReal_comp.mul_const E).deriv
  have D2 := ((nls_sech1_hasDerivAt a (hτ τ)).ofReal_comp.mul_const E).deriv
  have hn : (‖((a / Real.cosh (a * τ) : ℝ) : ℂ) * E‖ : ℂ) ^ 2
      = (((a / Real.cosh (a * τ)) ^ 2 : ℝ) : ℂ) := by
    rw [norm_mul, hE, mul_comm I, Complex.norm_exp_ofReal_mul_I, mul_one, Complex.norm_real,
      Real.norm_eq_abs, ← Complex.ofReal_pow, sq_abs]
  rw [hZ.deriv, D1, D2, hn]
  set c := Real.cosh (a * τ) with hc
  have hc0 : (c : ℂ) ≠ 0 := by exact_mod_cast (Real.cosh_pos _).ne'
  push_cast
  linear_combination ((a : ℂ) / c * E * ((a : ℂ) ^ 2 / 2)) * I_mul_I

/-- The KdV soliton (Step 5). For every real `κ`, the hump
`w = 2κ² sech²(κ(x − 4κ²t))`, of height `2κ²` moving at speed `4κ²`, solves the scaled
Korteweg–de Vries equation `w_t + 6 w w_x + w_xxx = 0`. -/
theorem kdv_sech_sq_hump_solves_kdv (κ : ℝ) :
    let w : ℝ → ℝ → ℝ := fun x t => 2 * κ ^ 2 / Real.cosh (κ * (x - 4 * κ ^ 2 * t)) ^ 2
    ∀ x t : ℝ,
      deriv (fun t' => w x t') t + 6 * w x t * deriv (fun x' => w x' t) x
        + deriv (fun x₁ => deriv (fun x₂ => deriv (fun x₃ => w x₃ t) x₂) x₁) x = 0 := by
  intro w x t
  simp only [w]
  have hx : ∀ y : ℝ, HasDerivAt (fun y => κ * (y - 4 * κ ^ 2 * t)) κ y := fun y => by
    simpa using ((hasDerivAt_id' y).sub_const (4 * κ ^ 2 * t)).const_mul κ
  have ht : HasDerivAt (fun s => κ * (x - 4 * κ ^ 2 * s)) (-(4 * κ ^ 3)) t := by
    convert (((hasDerivAt_id' t).const_mul (4 * κ ^ 2)).const_sub x).const_mul κ using 1
    ring
  have d1 : (fun x₂ => deriv (fun x₃ => 2 * κ ^ 2 / Real.cosh (κ * (x₃ - 4 * κ ^ 2 * t)) ^ 2) x₂)
      = fun x₂ => 2 * κ ^ 2 * (-2 * Real.sinh (κ * (x₂ - 4 * κ ^ 2 * t))
          / Real.cosh (κ * (x₂ - 4 * κ ^ 2 * t)) ^ 3) * κ :=
    funext fun y => (kdv_g0_hasDerivAt _ (hx y)).deriv
  have d2 : (fun x₁ => deriv (fun x₂ => 2 * κ ^ 2 * (-2 * Real.sinh (κ * (x₂ - 4 * κ ^ 2 * t))
          / Real.cosh (κ * (x₂ - 4 * κ ^ 2 * t)) ^ 3) * κ) x₁)
      = fun x₁ => 2 * κ ^ 2 * (4 / Real.cosh (κ * (x₁ - 4 * κ ^ 2 * t)) ^ 2
          - 6 / Real.cosh (κ * (x₁ - 4 * κ ^ 2 * t)) ^ 4) * κ * κ :=
    funext fun y => (kdv_g1_hasDerivAt _ _ (hx y)).deriv
  have d0 := (kdv_g0_hasDerivAt (2 * κ ^ 2) (hx x)).deriv
  have d3 := (kdv_g2_hasDerivAt (2 * κ ^ 2) κ κ (hx x)).deriv
  have dt := (kdv_g0_hasDerivAt (2 * κ ^ 2) ht).deriv
  rw [d1, d2, d3, dt, d0]
  have hc : Real.cosh (κ * (x - 4 * κ ^ 2 * t)) ≠ 0 := (Real.cosh_pos _).ne'
  field_simp
  ring

-- Worked numbers, with β₂ = −20 ps²/km, γ = 13/10 per W per km, T₀ = 10 ps (illustrative).
-- Dispersion length L_D = T₀²/|β₂| = 5 km, and 50 km is Z = 10 dispersion lengths.
example : (10 : ℚ) ^ 2 / |(-20 : ℚ)| = 5 := by norm_num
example : (50 : ℚ) / 5 = 10 := by norm_num
-- Phase turn 1/(2 L_D) = 1/10 rad per km.
example : (1 : ℚ) / (2 * 5) = 1 / 10 := by norm_num
-- Kerr phase at the peak over 50 km: γ P₀ · 50 = 10 rad exactly.
example : (13 / 10 : ℚ) * (20 / (13 / 10 * 10 ^ 2)) * 50 = 10 := by norm_num
-- Halving T₀ to 5 ps needs four times the power.
example : (20 : ℚ) / (13 / 10 * 5 ^ 2) = 4 * (20 / (13 / 10 * 10 ^ 2)) := by norm_num
-- Launch N = 4/5: bound state η = N − 1/2 = 3/10, keeping 4η/(2N²) = 15/16 of the energy (93.75%).
example : (4 / 5 : ℚ) - 1 / 2 = 3 / 10 := by norm_num
example : 4 * (3 / 10 : ℚ) / (2 * (4 / 5) ^ 2) = 15 / 16 := by norm_num
-- Launch N = 6/5: η = 7/10, keeping 35/36 of the energy (97.22%).
example : 4 * ((6 / 5 : ℚ) - 1 / 2) / (2 * (6 / 5) ^ 2) = 35 / 36 := by norm_num
-- Launch N = 2: bound states η = 3/2 and 1/2.
example : (2 : ℚ) - 1 / 2 = 3 / 2 ∧ (2 : ℚ) - 3 / 2 = 1 / 2 := by norm_num
-- KdV: bound states κ = 1 and 2 give heights 2κ² = 2 and 8 and speeds 4κ² = 4 and 16.
example : 2 * (1 : ℕ) ^ 2 = 2 ∧ 2 * (2 : ℕ) ^ 2 = 8 ∧ 4 * (1 : ℕ) ^ 2 = 4 ∧ 4 * (2 : ℕ) ^ 2 = 16 := by
  decide
-- The two-soliton solution at t = 0 is one hump of height 6 at x = 0.
example : 12 * (3 + 4 * Real.cosh (2 * 0 - 8 * 0) + Real.cosh (4 * 0 - 64 * 0))
    / (3 * Real.cosh (0 - 28 * 0) + Real.cosh (3 * 0 - 36 * 0)) ^ 2 = 6 := by
  norm_num [Real.cosh_zero]

#print axioms sech_pulse_solves_fibre_nls
#print axioms scaled_sech_family_solves_nls
#print axioms kdv_sech_sq_hump_solves_kdv
