-- Bernoulli and Riccati equations: the substitution v = y^(1-n) makes a Bernoulli equation linear, the substitution y = y1 + 1/w makes a Riccati equation linear, and the rumour P = 1000/(1 + 99e^(-0.8t)) solves the logistic law from 10 pupils.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

open Filter Topology

/-- Bernoulli's substitution: take a power `n` other than 0 and 1, and a time `t` near which
the unknown `y` stays positive. Then `y` obeys the Bernoulli law `y' + p y = q y^n` at `t`
exactly when the new unknown `v = y^(1-n)` obeys the linear law
`v' + (1-n) p v = (1-n) q` at `t`. -/
theorem bernoulli_substitution_linearizes
    (p q y : ℝ → ℝ) (n t : ℝ) (hn0 : n ≠ 0) (hn1 : n ≠ 1)
    (hy : ∀ᶠ s in 𝓝 t, 0 < y s) :
    HasDerivAt y (q t * y t ^ n - p t * y t) t ↔
      HasDerivAt (fun s => y s ^ (1 - n))
        ((1 - n) * q t - (1 - n) * p t * y t ^ (1 - n)) t := by
  have hyt : 0 < y t := hy.self_of_nhds
  have hA : y t ^ n * y t ^ (-n) = 1 := by
    rw [← Real.rpow_add hyt]; simp
  have hC : y t ^ (1 - n) = y t * y t ^ (-n) := by
    rw [sub_eq_add_neg, Real.rpow_add hyt, Real.rpow_one]
  have hD : y t ^ (1 - n) * y t ^ n = y t := by
    rw [← Real.rpow_add hyt]; simp
  constructor
  · intro h
    have h2 := h.rpow_const (p := 1 - n) (Or.inl hyt.ne')
    convert h2 using 1
    have : (1 - n - 1 : ℝ) = -n := by ring
    rw [this, hC]
    linear_combination (-(1 - n) * q t) * hA
  · intro h
    have hn' : (1 - n : ℝ) ≠ 0 := sub_ne_zero.mpr (Ne.symm hn1)
    have h2 := h.rpow_const (p := (1 - n)⁻¹) (Or.inl (Real.rpow_pos_of_pos hyt _).ne')
    have heq : y =ᶠ[𝓝 t] fun s => (y s ^ (1 - n)) ^ (1 - n)⁻¹ := by
      filter_upwards [hy] with s hs
      rw [Real.rpow_rpow_inv hs.le hn']
    have h3 := h2.congr_of_eventuallyEq heq
    convert h3 using 1
    rw [← Real.rpow_mul hyt.le]
    have : (1 - n) * ((1 - n)⁻¹ - 1) = n := by field_simp; ring
    rw [this]
    field_simp
    linear_combination (p t) * hD

/-- Riccati's substitution: let `y₁` be a known solution of `y' = a + b y + c y^2` at `t`, and
let the new unknown `w` stay away from 0 near `t`. Then `y = y₁ + 1/w` obeys the Riccati law at
`t` exactly when `w` obeys the linear law `w' = -(b + 2 c y₁) w - c` at `t`. -/
theorem riccati_substitution_linearizes
    (a b c y₁ w : ℝ → ℝ) (t : ℝ)
    (hy₁ : HasDerivAt y₁ (a t + b t * y₁ t + c t * y₁ t ^ 2) t)
    (hw : ∀ᶠ s in 𝓝 t, w s ≠ 0) :
    HasDerivAt (fun s => y₁ s + 1 / w s)
        (a t + b t * (y₁ t + 1 / w t) + c t * (y₁ t + 1 / w t) ^ 2) t ↔
      HasDerivAt w (-(b t + 2 * c t * y₁ t) * w t - c t) t := by
  have hwt : w t ≠ 0 := hw.self_of_nhds
  constructor
  · intro h
    have h2 := h.sub hy₁
    have hne : (y₁ t + 1 / w t) - y₁ t ≠ 0 := by simpa using hwt
    have h3 := h2.fun_inv hne
    have heq : w =ᶠ[𝓝 t] fun s => ((y₁ s + 1 / w s) - y₁ s)⁻¹ := by
      filter_upwards [hw] with s hs
      simp
    have h4 := h3.congr_of_eventuallyEq heq
    convert h4 using 1
    simp only [Pi.sub_apply, add_sub_cancel_left, one_div]
    field_simp
    ring
  · intro h
    have h2 := hy₁.add (h.fun_inv hwt)
    convert h2 using 1
    · funext s; simp [one_div]
    · field_simp
      ring

/-- The rumour: `P = 1000/(1 + 99 e^(-0.8 t))` obeys the logistic law
`P' = 0.8 P (1 - P/1000)` at every time `t`, and starts at `P(0) = 10` pupils. -/
theorem rumour_solves_logistic_law :
    (∀ t : ℝ, HasDerivAt (fun s : ℝ => 1000 / (1 + 99 * Real.exp (-(4 / 5) * s)))
        (4 / 5 * (1000 / (1 + 99 * Real.exp (-(4 / 5) * t)))
          * (1 - 1000 / (1 + 99 * Real.exp (-(4 / 5) * t)) / 1000)) t) ∧
      (fun s : ℝ => 1000 / (1 + 99 * Real.exp (-(4 / 5) * s))) 0 = 10 := by
  constructor
  · intro t
    have he := ((hasDerivAt_id t).const_mul (-(4 / 5 : ℝ))).exp
    have hd := (he.const_mul (99 : ℝ)).const_add (1 : ℝ)
    have hpos : (0 : ℝ) < 1 + 99 * Real.exp (-(4 / 5) * t) := by positivity
    have h := (hasDerivAt_const t (1000 : ℝ)).div hd hpos.ne'
    convert h using 1
    · funext s; simp [id]
    · simp only [id]
      field_simp
      ring
  · simp
    norm_num

-- The rumour's start: v(0) = 1/10, so C = 1/10 - 1/1000 = 99/1000.
example : (1 : ℚ) / 10 - 1 / 1000 = 99 / 1000 := by norm_num

-- Flipping back: 1/(1/1000 + 99/1000) = 1000/(1 + 99) = 10 pupils at day 0.
example : (1 : ℚ) / (1 / 1000 + 99 / 1000) = 10 ∧ (1000 : ℚ) / (1 + 99) = 10 := by norm_num

-- The skydiver from rest: y(0) = 0 needs (1 + C)/(1 - C) = 0, so C = -1.
example : ((1 : ℚ) + (-1)) / (1 - (-1)) = 0 := by norm_num

-- A start at y(0) = 3: C = (3 - 1)/(3 + 1) = 1/2.
example : ((3 : ℚ) - 1) / (3 + 1) = 1 / 2 := by norm_num

-- The skydiver's scaled law: 49 m/s terminal speed and 9.8 m/s^2 give 49/9.8 = 5 s per time unit.
example : (49 : ℚ) / (98 / 10) = 5 := by norm_num

#print axioms bernoulli_substitution_linearizes
#print axioms riccati_substitution_linearizes
#print axioms rumour_solves_logistic_law
