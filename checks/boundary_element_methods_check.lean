-- Boundary elements: the trapezoid rule with N equal steps round a closed curve integrates every wave e^(imt) with |m| < N exactly, because the N-th roots of unity add to zero.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Algebra.Field.GeomSum
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum

open Real

/-- Helper: the root-of-unity sum, proved here so the first theorem can use it. -/
theorem root_of_unity_wave_sum_aux (N : ℕ) (hN : 0 < N) (m : ℤ) :
    (2 * π / N : ℂ) * ∑ j ∈ Finset.range N,
        Complex.exp (2 * π * Complex.I * m * j / N) =
      if (N : ℤ) ∣ m then (2 * π : ℂ) else 0 := by
  have hN' : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
  have hpow : ∀ j : ℕ, Complex.exp (2 * π * Complex.I * m * j / N)
      = Complex.exp (2 * π * Complex.I * m / N) ^ j := by
    intro j
    rw [← Complex.exp_nat_mul]
    congr 1
    ring
  simp_rw [hpow]
  split_ifs with h
  · obtain ⟨q, rfl⟩ := h
    have h1 : Complex.exp (2 * π * Complex.I * ((N * q : ℤ) : ℂ) / N) = 1 := by
      have : 2 * π * Complex.I * ((N * q : ℤ) : ℂ) / N = (q : ℂ) * (2 * π * Complex.I) := by
        push_cast
        field_simp
      rw [this, Complex.exp_int_mul_two_pi_mul_I]
    rw [h1]
    simp only [one_pow, Finset.sum_const, Finset.card_range, nsmul_eq_mul, mul_one]
    field_simp
  · have hz : Complex.exp (2 * π * Complex.I * m / N) ≠ 1 := by
      intro hz
      rw [Complex.exp_eq_one_iff] at hz
      obtain ⟨n, hn⟩ := hz
      apply h
      refine ⟨n, ?_⟩
      have hpi : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
      field_simp at hn
      exact_mod_cast hn
    have hzN : Complex.exp (2 * π * Complex.I * m / N) ^ N = 1 := by
      rw [← Complex.exp_nat_mul]
      have : (N : ℂ) * (2 * π * Complex.I * m / N) = (m : ℂ) * (2 * π * Complex.I) := by
        field_simp
      rw [this, Complex.exp_int_mul_two_pi_mul_I]
    rw [geom_sum_eq hz, hzN]
    simp

#print axioms root_of_unity_wave_sum_aux

/-- The card's Step 1: on a closed curve, the trapezoid rule with `N` equal steps
`t_j = 2πj/N` (every weight `2π/N`) gives exactly the true integral over a full period
of the wave `e^(imt)`, for every whole number `m` with `|m| < N`. -/
theorem trapezoid_rule_exact_on_low_waves (N : ℕ) (m : ℤ) (hm : |m| < (N : ℤ)) :
    (2 * π / N : ℂ) * ∑ j ∈ Finset.range N,
        Complex.exp (Complex.I * m * (2 * π * j / N)) =
      ∫ t in (0 : ℝ)..(2 * π), Complex.exp (Complex.I * m * t) := by
  have hN : 0 < N := by
    have : (0 : ℤ) < N := lt_of_le_of_lt (abs_nonneg m) hm
    exact_mod_cast this
  have key := root_of_unity_wave_sum_aux N hN m
  have harg : ∀ j : ℕ, Complex.I * m * (2 * π * j / N) = 2 * π * Complex.I * m * j / N := by
    intro j; ring
  simp_rw [harg]
  rw [key]
  by_cases hm0 : m = 0
  · subst hm0
    simp
  · have hnd : ¬ (N : ℤ) ∣ m := by
      intro hd
      have := Int.le_of_dvd (abs_pos.mpr hm0) ((dvd_abs _ _).mpr hd)
      omega
    simp only [hnd, ↓reduceIte]
    have hc : Complex.I * m ≠ 0 := by
      simp [Complex.I_ne_zero, hm0]
    rw [integral_exp_mul_complex hc]
    have : Complex.I * m * ((2 * π : ℝ) : ℂ) = (m : ℂ) * (2 * π * Complex.I) := by
      push_cast; ring
    rw [this, Complex.exp_int_mul_two_pi_mul_I]
    simp

/-- The card's displayed sum: `2π/N` times the sum of the powers `e^(2πimj/N)`,
`j = 0, …, N - 1`, of an `N`-th root of unity is `2π` when `N` divides `m` and `0`
otherwise. -/
theorem root_of_unity_wave_sum (N : ℕ) (hN : 0 < N) (m : ℤ) :
    (2 * π / N : ℂ) * ∑ j ∈ Finset.range N,
        Complex.exp (2 * π * Complex.I * m * j / N) =
      if (N : ℤ) ∣ m then (2 * π : ℂ) else 0 := by
  exact root_of_unity_wave_sum_aux N hN m

/-- The same fact for real waves: with `N` equal steps over a full period, the trapezoid
rule integrates `cos kt` and `sin kt` exactly for every whole number `k < N`. -/
theorem trapezoid_rule_exact_on_cos_sin (N k : ℕ) (hk : k < N) :
    (2 * π / N) * ∑ j ∈ Finset.range N, Real.cos (k * (2 * π * j / N)) =
        ∫ t in (0 : ℝ)..(2 * π), Real.cos (k * t) ∧
      (2 * π / N) * ∑ j ∈ Finset.range N, Real.sin (k * (2 * π * j / N)) =
        ∫ t in (0 : ℝ)..(2 * π), Real.sin (k * t) := by
  have hN : 0 < N := by omega
  have hN' : (N : ℝ) ≠ 0 := by exact_mod_cast hN.ne'
  by_cases hk0 : k = 0
  · subst hk0
    simp
    field_simp
  · have hkR : (k : ℝ) ≠ 0 := by exact_mod_cast hk0
    have key := root_of_unity_wave_sum_aux N hN k
    have hnd : ¬ (N : ℤ) ∣ (k : ℤ) := by
      intro hd
      have := Int.le_of_dvd (by omega) hd
      omega
    simp only [hnd, ↓reduceIte] at key
    have hsum : ∑ j ∈ Finset.range N, Complex.exp (((k * (2 * π * j / N) : ℝ) : ℂ) * Complex.I) = 0 := by
      have h2 : (2 * π / N : ℂ) ≠ 0 := by
        have hpi : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
        have : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
        simp [hpi, this]
      have := (mul_eq_zero.mp key).resolve_left h2
      rw [← this]
      apply Finset.sum_congr rfl
      intro j _
      congr 1
      push_cast
      ring
    have hre := congrArg Complex.re hsum
    have him := congrArg Complex.im hsum
    rw [Complex.re_sum] at hre
    rw [Complex.im_sum] at him
    simp only [Complex.exp_ofReal_mul_I_re, Complex.zero_re] at hre
    simp only [Complex.exp_ofReal_mul_I_im, Complex.zero_im] at him
    rw [hre, him, intervalIntegral.integral_comp_mul_left (fun t => Real.cos t) hkR,
      intervalIntegral.integral_comp_mul_left (fun t => Real.sin t) hkR,
      integral_cos, integral_sin]
    have h1 : (k : ℝ) * (2 * π) = ((2 * k : ℕ) : ℝ) * π := by push_cast; ring
    refine ⟨?_, ?_⟩
    · simp only [mul_zero, mul_comm (k : ℝ) 0, zero_mul]
      rw [h1, Real.sin_nat_mul_pi]
      simp
    · simp only [mul_zero]
      rw [Real.cos_nat_mul_two_pi]
      simp

-- The duct's exact temperature at (0.5 m, 0.3 m): 0.25 - 0.09 = 0.16 K, in exact fractions.
example : ((1 : ℚ) / 2) ^ 2 - (3 / 10) ^ 2 = 4 / 25 := by norm_num

-- The rim data g = x^2 - y^2 at node 0, (2, 0) m, and node 2, (0, 1) m: 4 K and -1 K.
example : (2 : ℤ) ^ 2 - 0 ^ 2 = 4 ∧ (0 : ℤ) ^ 2 - 1 ^ 2 = -1 := by norm_num

-- Worked step 4: node 2 seen from node 0, (2 - 0, 0 - 1) · (0, 1) = -1 over |(2, -1)|^2 = 5.
example : (2 - 0 : ℤ) * 0 + (0 - 1) * 1 = -1 ∧ (2 - 0 : ℤ) ^ 2 + (0 - 1) ^ 2 = 5 := by norm_num

-- The dense matrices: 16^2 = 256 entries for 16 unknowns, 1024 for 32.
example : (16 : ℕ) ^ 2 = 256 ∧ (32 : ℕ) ^ 2 = 1024 := by norm_num

-- The grid with h = 0.1 m: the point (ih, jh) is inside the ellipse 2 m by 1 m exactly when
-- i^2 + 4j^2 < 400, and there are 617 such grid points (the card's 617 unknowns).
set_option maxRecDepth 100000 in
example : ((Finset.Icc (-21 : ℤ) 21 ×ˢ Finset.Icc (-11 : ℤ) 11).filter
    (fun p => p.1 ^ 2 + 4 * p.2 ^ 2 < 400)).card = 617 := by decide

#print axioms trapezoid_rule_exact_on_low_waves
#print axioms root_of_unity_wave_sum
#print axioms trapezoid_rule_exact_on_cos_sin
