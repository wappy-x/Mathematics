-- Waves on strings and drums: a string of length L held still at both ends can ring at a frequency f exactly when f = n c / (2L) for a whole number n = 1, 2, 3, ..., each rectangular drum mode sin(m π x / a) sin(n π y / b) cos(2π f_mn t) with f_mn = (c/2) √(m²/a² + n²/b²) solves the drum's wave equation with its edges still, and on a square head the mix of modes (1,2) and (2,1) rings at one frequency with a still line along the diagonal.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.MeanValue

open Real Set

theorem wave_const_on_Icc (g : ℝ → ℝ) (L : ℝ)
    (h : ∀ x ∈ Icc (0 : ℝ) L, HasDerivWithinAt g 0 (Icc 0 L) x) (hL : 0 ≤ L) :
    ∀ x ∈ Icc (0 : ℝ) L, g x = g 0 := by
  intro x hx
  have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f' := fun _ => (0 : ℝ)) (C := 0)
    h (fun _ _ => by simp) (convex_Icc 0 L) (left_mem_Icc.2 hL) hx
  simp at this
  linarith [sub_eq_zero.1 this]

theorem wave_deriv2_of (g g' : ℝ → ℝ) (g'' x : ℝ) (h1 : ∀ p, HasDerivAt g (g' p) p)
    (h2 : HasDerivAt g' g'' x) : deriv (fun p => deriv g p) x = g'' := by
  have : (fun p => deriv g p) = g' := funext fun p => (h1 p).deriv
  rw [this]; exact h2.deriv

theorem wave_hasDerivAt_sin_lin (w a x : ℝ) :
    HasDerivAt (fun q => sin (w * q / a)) (cos (w * x / a) * (w / a)) x :=
  (((hasDerivAt_id x).const_mul w).div_const a).sin.congr_deriv (by simp [mul_div_assoc])

theorem wave_hasDerivAt_cos_lin (w a x : ℝ) :
    HasDerivAt (fun q => cos (w * q / a)) (-sin (w * x / a) * (w / a)) x :=
  (((hasDerivAt_id x).const_mul w).div_const a).cos.congr_deriv (by simp [mul_div_assoc])

theorem wave_hasDerivAt_cos_mul (w x : ℝ) :
    HasDerivAt (fun q => cos (w * q)) (-sin (w * x) * w) x :=
  ((hasDerivAt_id x).const_mul w).cos.congr_deriv (by simp)

theorem wave_hasDerivAt_sin_mul (w x : ℝ) :
    HasDerivAt (fun q => sin (w * q)) (cos (w * x) * w) x :=
  ((hasDerivAt_id x).const_mul w).sin.congr_deriv (by simp)

theorem wave_dd_time (A w t : ℝ) :
    deriv (fun s => deriv (fun r => A * cos (w * r)) s) t = -(w ^ 2) * (A * cos (w * t)) := by
  rw [wave_deriv2_of _ (fun r => A * (-sin (w * r) * w)) (A * (-(cos (w * t) * w) * w)) t
    (fun p => (wave_hasDerivAt_cos_mul w p).const_mul A)
    (((wave_hasDerivAt_sin_mul w t).neg.mul_const w).const_mul A)]
  ring

theorem wave_dd_x (w a B C x : ℝ) :
    deriv (fun p => deriv (fun q => sin (w * q / a) * B * C) p) x
      = -(w / a) ^ 2 * (sin (w * x / a) * B * C) := by
  rw [wave_deriv2_of _ (fun p => cos (w * p / a) * (w / a) * B * C)
    (-sin (w * x / a) * (w / a) * (w / a) * B * C) x
    (fun p => ((wave_hasDerivAt_sin_lin w a p).mul_const B).mul_const C)
    ((((wave_hasDerivAt_cos_lin w a x).mul_const (w / a)).mul_const B).mul_const C)]
  ring

theorem wave_dd_y (w b A C y : ℝ) :
    deriv (fun p => deriv (fun q => A * sin (w * q / b) * C) p) y
      = -(w / b) ^ 2 * (A * sin (w * y / b) * C) := by
  rw [wave_deriv2_of _ (fun p => A * (cos (w * p / b) * (w / b)) * C)
    (A * (-sin (w * y / b) * (w / b) * (w / b)) * C) y
    (fun p => ((wave_hasDerivAt_sin_lin w b p).const_mul A).mul_const C)
    ((((wave_hasDerivAt_cos_lin w b y).mul_const (w / b)).const_mul A).mul_const C)]
  ring

theorem wave_dd_x2 (w1 w2 a B1 B2 C x : ℝ) :
    deriv (fun p => deriv (fun q => (sin (w1 * q / a) * B1 + sin (w2 * q / a) * B2) * C) p) x
      = (-(w1 / a) ^ 2 * sin (w1 * x / a) * B1 - (w2 / a) ^ 2 * sin (w2 * x / a) * B2) * C := by
  rw [wave_deriv2_of (fun q => (sin (w1 * q / a) * B1 + sin (w2 * q / a) * B2) * C)
    (fun p => (cos (w1 * p / a) * (w1 / a) * B1 + cos (w2 * p / a) * (w2 / a) * B2) * C)
    ((-sin (w1 * x / a) * (w1 / a) * (w1 / a) * B1
      + -sin (w2 * x / a) * (w2 / a) * (w2 / a) * B2) * C) x
    (fun p => (((wave_hasDerivAt_sin_lin w1 a p).mul_const B1).add
      ((wave_hasDerivAt_sin_lin w2 a p).mul_const B2)).mul_const C)
    (((((wave_hasDerivAt_cos_lin w1 a x).mul_const (w1 / a)).mul_const B1).add
      (((wave_hasDerivAt_cos_lin w2 a x).mul_const (w2 / a)).mul_const B2)).mul_const C)]
  ring

theorem wave_dd_y2 (w1 w2 a A1 A2 C y : ℝ) :
    deriv (fun p => deriv (fun q => (A1 * sin (w1 * q / a) + A2 * sin (w2 * q / a)) * C) p) y
      = (-(w1 / a) ^ 2 * A1 * sin (w1 * y / a) - (w2 / a) ^ 2 * A2 * sin (w2 * y / a)) * C := by
  rw [wave_deriv2_of (fun q => (A1 * sin (w1 * q / a) + A2 * sin (w2 * q / a)) * C)
    (fun p => (A1 * (cos (w1 * p / a) * (w1 / a)) + A2 * (cos (w2 * p / a) * (w2 / a))) * C)
    ((A1 * (-sin (w1 * y / a) * (w1 / a) * (w1 / a))
      + A2 * (-sin (w2 * y / a) * (w2 / a) * (w2 / a))) * C) y
    (fun p => (((wave_hasDerivAt_sin_lin w1 a p).const_mul A1).add
      ((wave_hasDerivAt_sin_lin w2 a p).const_mul A2)).mul_const C)
    (((((wave_hasDerivAt_cos_lin w1 a y).mul_const (w1 / a)).const_mul A1).add
      (((wave_hasDerivAt_cos_lin w2 a y).mul_const (w2 / a)).const_mul A2)).mul_const C)]
  ring

#print axioms wave_const_on_Icc
#print axioms wave_deriv2_of
#print axioms wave_hasDerivAt_sin_lin
#print axioms wave_hasDerivAt_cos_lin
#print axioms wave_hasDerivAt_cos_mul
#print axioms wave_hasDerivAt_sin_mul
#print axioms wave_dd_time
#print axioms wave_dd_x
#print axioms wave_dd_y
#print axioms wave_dd_x2
#print axioms wave_dd_y2

/-- The string's list of notes (Steps 1 and 2). Take a string of length `L > 0` with wave
speed `c > 0`, held still at both ends, and a frequency `f > 0`. A motion that keeps its shape
and swings at `f` has a shape `X` along the string with `-X'' = k^2 X`, where `k = 2π f / c`
(the time factor `cos (2π f t)` splits off). Such a shape that is zero at the nut (`X 0 = 0`)
and at the bridge (`X L = 0`) and is not zero everywhere on the string exists exactly when
`f = n c / (2L)` for some whole number `n = 1, 2, 3, ...`: the string can ring only at those
frequencies. Slopes are taken on the string `0 ≤ x ≤ L`, one-sided at the ends. -/
theorem string_rings_only_at_whole_multiples (c L f : ℝ) (hc : 0 < c) (hL : 0 < L) (hf : 0 < f) :
    (∃ X X' : ℝ → ℝ,
      (∀ x ∈ Icc (0 : ℝ) L,
        HasDerivWithinAt X (X' x) (Icc 0 L) x ∧
        HasDerivWithinAt X' (-(2 * π * f / c) ^ 2 * X x) (Icc 0 L) x) ∧
      X 0 = 0 ∧ X L = 0 ∧ ∃ x ∈ Icc (0 : ℝ) L, X x ≠ 0) ↔
    ∃ n : ℕ, 0 < n ∧ f = n * c / (2 * L) := by
  set k := 2 * π * f / c with hk
  have kpos : 0 < k := by positivity
  constructor
  · rintro ⟨X, X', hd, h0, hLz, x0, hx0, hX0⟩
    -- Q(x) = X x * sin (k x) + X' x * cos (k x) / k is constant
    have hQ : ∀ x ∈ Icc (0 : ℝ) L,
        HasDerivWithinAt (fun x => X x * sin (k * x) + X' x * cos (k * x) / k) 0 (Icc 0 L) x := by
      intro x hx
      obtain ⟨h1, h2⟩ := hd x hx
      have hs : HasDerivWithinAt (fun x => sin (k * x)) (cos (k * x) * k) (Icc 0 L) x :=
        (((hasDerivAt_id x).const_mul k).sin.hasDerivWithinAt).congr_deriv (by simp)
      have hc' : HasDerivWithinAt (fun x => cos (k * x)) (-sin (k * x) * k) (Icc 0 L) x :=
        (((hasDerivAt_id x).const_mul k).cos.hasDerivWithinAt).congr_deriv (by simp)
      convert (h1.mul hs).add ((h2.mul hc').div_const k) using 1
      field_simp
      ring
    have hP : ∀ x ∈ Icc (0 : ℝ) L,
        HasDerivWithinAt (fun x => X x * cos (k * x) - X' x * sin (k * x) / k) 0 (Icc 0 L) x := by
      intro x hx
      obtain ⟨h1, h2⟩ := hd x hx
      have hs : HasDerivWithinAt (fun x => sin (k * x)) (cos (k * x) * k) (Icc 0 L) x :=
        (((hasDerivAt_id x).const_mul k).sin.hasDerivWithinAt).congr_deriv (by simp)
      have hc' : HasDerivWithinAt (fun x => cos (k * x)) (-sin (k * x) * k) (Icc 0 L) x :=
        (((hasDerivAt_id x).const_mul k).cos.hasDerivWithinAt).congr_deriv (by simp)
      convert (h1.mul hc').sub ((h2.mul hs).div_const k) using 1
      field_simp
      ring
    have cQ := wave_const_on_Icc _ L hQ hL.le
    have cP := wave_const_on_Icc _ L hP hL.le
    have hform : ∀ x ∈ Icc (0 : ℝ) L, X x = X' 0 / k * sin (k * x) := by
      intro x hx
      have e1 := cQ x hx
      have e2 := cP x hx
      simp only [mul_zero, sin_zero, cos_zero, h0] at e1 e2
      have := sin_sq_add_cos_sq (k * x)
      have : X x = (X x * sin (k * x) + X' x * cos (k * x) / k) * sin (k * x)
          + (X x * cos (k * x) - X' x * sin (k * x) / k) * cos (k * x) := by
        field_simp
        linear_combination (-(X x) * k) * this
      rw [this, e1, e2]
      ring
    have hA : X' 0 / k ≠ 0 := by
      intro h
      exact hX0 (by rw [hform x0 hx0, h, zero_mul])
    have hsin : sin (k * L) = 0 := by
      have := hform L (right_mem_Icc.2 hL.le)
      rw [hLz] at this
      rcases mul_eq_zero.1 this.symm with h | h
      · exact absurd h hA
      · exact h
    obtain ⟨n, hn⟩ := sin_eq_zero_iff.1 hsin
    have hnpos : (0 : ℝ) < n := by
      have : 0 < (n : ℝ) * π := by rw [hn]; positivity
      exact pos_of_mul_pos_left this pi_pos.le
    have hn0 : 0 < n := by exact_mod_cast hnpos
    refine ⟨n.toNat, by omega, ?_⟩
    have hcast : ((n.toNat : ℕ) : ℝ) = (n : ℝ) := by
      have : ((n.toNat : ℤ) : ℝ) = (n : ℝ) := by rw [Int.toNat_of_nonneg hn0.le]
      exact_mod_cast this
    rw [hcast, eq_div_iff (by positivity)]
    have h3 : (n : ℝ) * π * c = 2 * π * f * L := by rw [hn, hk]; field_simp
    exact mul_left_cancel₀ pi_pos.ne' (show π * (f * (2 * L)) = π * (n * c) by linear_combination -h3)
  · rintro ⟨n, hn, rfl⟩
    have hkn : k = n * π / L := by
      rw [hk]; field_simp
    refine ⟨fun x => sin (k * x), fun x => k * cos (k * x), ?_, by simp, ?_, ?_⟩
    · intro x _
      constructor
      · exact (((hasDerivAt_id x).const_mul k).sin.hasDerivWithinAt).congr_deriv (by simp; ring)
      · exact ((((hasDerivAt_id x).const_mul k).cos.const_mul k).hasDerivWithinAt).congr_deriv
          (by simp; ring)
    · simp only
      rw [hkn, div_mul_cancel₀ _ hL.ne']
      exact sin_nat_mul_pi n
    · refine ⟨L / (2 * n), ⟨by positivity, ?_⟩, ?_⟩
      · have : (1 : ℝ) ≤ n := by exact_mod_cast hn
        rw [div_le_iff₀ (by positivity)]
        nlinarith
      · simp only
        have hn' : (n : ℝ) ≠ 0 := by positivity
        rw [hkn, show n * π / L * (L / (2 * n)) = π / 2 by field_simp]
        simp

/-- The drum's modes (Step 3). On an `a` by `b` rectangular head with wave speed `c`, for whole
numbers `m` and `n`, the motion
`u = sin (m π x / a) sin (n π y / b) cos (2π f_mn t)` with
`f_mn = (c/2) √(m^2/a^2 + n^2/b^2)` obeys the drum's wave equation
`u_tt = c^2 (u_xx + u_yy)` at every point and time, and is zero on all four edges
(`x = 0`, `x = a`, `y = 0`, `y = b`) at every moment. -/
theorem rectangular_drum_mode_solves_wave_equation (a b c : ℝ) (ha : 0 < a) (hb : 0 < b)
    (m n : ℕ) :
    let f : ℝ := c / 2 * √((m : ℝ) ^ 2 / a ^ 2 + (n : ℝ) ^ 2 / b ^ 2)
    let u : ℝ → ℝ → ℝ → ℝ := fun x y t =>
      sin (m * π * x / a) * sin (n * π * y / b) * cos (2 * π * f * t)
    (∀ x y t : ℝ,
      deriv (fun s => deriv (fun r => u x y r) s) t
        = c ^ 2 * (deriv (fun p => deriv (fun q => u q y t) p) x
          + deriv (fun p => deriv (fun q => u x q t) p) y)) ∧
    (∀ x y t : ℝ, u 0 y t = 0 ∧ u a y t = 0 ∧ u x 0 t = 0 ∧ u x b t = 0) := by
  intro f u
  constructor
  · intro x y t
    simp only [u]
    rw [wave_dd_time, wave_dd_x, wave_dd_y]
    have hsq : √((m : ℝ) ^ 2 / a ^ 2 + (n : ℝ) ^ 2 / b ^ 2) ^ 2
        = (m : ℝ) ^ 2 / a ^ 2 + (n : ℝ) ^ 2 / b ^ 2 := Real.sq_sqrt (by positivity)
    simp only [f]
    linear_combination (-(sin (m * π * x / a) * sin (n * π * y / b)
      * cos (2 * π * (c / 2 * √((m : ℝ) ^ 2 / a ^ 2 + (n : ℝ) ^ 2 / b ^ 2)) * t)) * π ^ 2 * c ^ 2)
      * hsq
  · intro x y t
    simp only [u]
    have h1 : (m : ℝ) * π * a / a = m * π := by field_simp
    have h2 : (n : ℝ) * π * b / b = n * π := by field_simp
    refine ⟨by simp, ?_, by simp, ?_⟩
    · rw [h1, sin_nat_mul_pi]; ring
    · rw [h2, sin_nat_mul_pi]; ring

/-- One note, two shapes (Step 4). On a square head of side `a > 0` with wave speed `c`, modes
(1,2) and (2,1) share `m^2 + n^2 = 5`, so both ring at `f = (c / (2a)) √5`. Their sum,
`(sin (π x / a) sin (2π y / a) + sin (2π x / a) sin (π y / a)) cos (2π f t)`, also obeys
`u_tt = c^2 (u_xx + u_yy)` everywhere, is zero on all four edges, and is zero at every moment
along the diagonal `x + y = a`: a still line neither mode has alone. -/
theorem square_drum_mixed_mode_has_diagonal_still_line (a c : ℝ) (ha : 0 < a) :
    let f : ℝ := c / (2 * a) * √5
    let u : ℝ → ℝ → ℝ → ℝ := fun x y t =>
      (sin (π * x / a) * sin (2 * π * y / a) + sin (2 * π * x / a) * sin (π * y / a))
        * cos (2 * π * f * t)
    (∀ x y t : ℝ,
      deriv (fun s => deriv (fun r => u x y r) s) t
        = c ^ 2 * (deriv (fun p => deriv (fun q => u q y t) p) x
          + deriv (fun p => deriv (fun q => u x q t) p) y)) ∧
    (∀ x y t : ℝ, u 0 y t = 0 ∧ u a y t = 0 ∧ u x 0 t = 0 ∧ u x a t = 0) ∧
    (∀ x t : ℝ, u x (a - x) t = 0) := by
  intro f u
  have h1 : π * a / a = π := by field_simp
  have h2 : 2 * π * a / a = 2 * π := by field_simp
  refine ⟨?_, ?_, ?_⟩
  · intro x y t
    simp only [u]
    rw [wave_dd_time, wave_dd_x2, wave_dd_y2]
    have hsq : √(5 : ℝ) ^ 2 = 5 := Real.sq_sqrt (by norm_num)
    simp only [f]
    linear_combination (-(sin (π * x / a) * sin (2 * π * y / a)
      + sin (2 * π * x / a) * sin (π * y / a)) * cos (2 * π * (c / (2 * a) * √5) * t)
      * π ^ 2 * c ^ 2 / a ^ 2) * hsq
  · intro x y t
    simp only [u]
    refine ⟨by simp, ?_, by simp, ?_⟩
    · rw [h1, h2, sin_pi, sin_two_pi]; ring
    · rw [h1, h2, sin_pi, sin_two_pi]; ring
  · intro x t
    simp only [u]
    have e1 : π * (a - x) / a = π - π * x / a := by field_simp
    have e2 : 2 * π * (a - x) / a = 2 * π - 2 * π * x / a := by field_simp
    rw [e1, e2, sin_pi_sub, sin_two_pi_sub]
    ring

-- Harmonics 1 to 4 of the high E, in hundredths of a hertz: n × 329.63 Hz gives
-- 329.63, 659.26, 988.89 and 1318.52 Hz.
example : (List.range' 1 4).map (fun n => n * 32963) = [32963, 65926, 98889, 131852] := by decide
-- A light finger at L/3 (7th fret): mode n has a still point there when 3 divides n, so of
-- modes 1 to 9 it keeps 3, 6 and 9, and the lowest is harmonic 3.
example : (List.range' 1 9).filter (fun n => n % 3 = 0) = [3, 6, 9] := by decide
-- A finger at L/2 (12th fret) keeps the even modes; the lowest is harmonic 2.
example : (List.range' 1 9).filter (fun n => n % 2 = 0) = [2, 4, 6, 8] := by decide
-- Square drum: m^2 + n^2 for modes (1,1), (1,2), (2,1), (2,2) is 2, 5, 5, 8, so (1,2) and (2,1)
-- share a note and (2,2) has exactly twice the frequency of (1,1) (√8 = 2√2).
example : [(1, 1), (1, 2), (2, 1), (2, 2)].map (fun p : ℕ × ℕ => p.1 ^ 2 + p.2 ^ 2) = [2, 5, 5, 8] := by
  decide
example : (8 : ℕ) = 2 ^ 2 * 2 := by decide
-- The mistake "mode numbers added": (1 + 2)^2 = 9, not 1^2 + 2^2 = 5, so 500 Hz is wrong for (1,2).
example : (1 + 2) ^ 2 ≠ 1 ^ 2 + 2 ^ 2 := by decide
-- The 0.30 m by 0.20 m head at 100 m/s: mode (2,1) rings at 50 √((2/0.3)^2 + (1/0.2)^2) = 1250/3 Hz,
-- the card's 416.7 Hz.
example : (50 : ℝ) * √((2 / (3 / 10)) ^ 2 + (1 / (2 / 10)) ^ 2) = 1250 / 3 := by
  rw [show ((2 : ℝ) / (3 / 10)) ^ 2 + (1 / (2 / 10)) ^ 2 = (25 / 3) ^ 2 by norm_num,
    Real.sqrt_sq (by norm_num)]
  norm_num

#print axioms string_rings_only_at_whole_multiples
#print axioms rectangular_drum_mode_solves_wave_equation
#print axioms square_drum_mixed_mode_has_diagonal_still_line
