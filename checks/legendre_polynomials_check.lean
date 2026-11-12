-- Legendre's equation: for a whole number n the power series of n's parity stops at x^n, exactly one polynomial solution equals 1 at x = 1 and it has degree n, and solutions for different whole numbers integrate to zero against each other on -1 to 1.
import Mathlib.RingTheory.PowerSeries.Derivative
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.Topology.Algebra.Polynomial

open Polynomial

/-- Coefficient recurrence for a power-series solution of Legendre's equation. -/
theorem legendre_series_rec (n : ℕ) (y : PowerSeries ℝ)
    (hy : (1 - PowerSeries.X ^ 2) * PowerSeries.derivative (PowerSeries.derivative y)
        - 2 * PowerSeries.X * PowerSeries.derivative y
        + PowerSeries.C ((n : ℝ) * (n + 1)) * y = 0) (j : ℕ) :
    PowerSeries.coeff (j + 2) y * (((j : ℝ) + 2) * ((j : ℝ) + 1))
      = (((j : ℝ) * (j + 1)) - (n : ℝ) * (n + 1)) * PowerSeries.coeff j y := by
  have e : (1 - PowerSeries.X ^ 2) * PowerSeries.derivative (PowerSeries.derivative y)
        - 2 * PowerSeries.X * PowerSeries.derivative y
        + PowerSeries.C ((n : ℝ) * (n + 1)) * y
      = PowerSeries.derivative (PowerSeries.derivative y)
        - PowerSeries.X ^ 2 * PowerSeries.derivative (PowerSeries.derivative y)
        - PowerSeries.X * (PowerSeries.C (2 : ℝ) * PowerSeries.derivative y)
        + PowerSeries.C ((n : ℝ) * (n + 1)) * y := by
    rw [show (PowerSeries.C (2 : ℝ)) = 2 from map_ofNat _ 2]; ring
  rw [e] at hy
  generalize (n : ℝ) * (n + 1) = c at hy ⊢
  have h := congrArg (PowerSeries.coeff j) hy
  rcases j with _ | _ | i <;>
  simp only [map_add, map_sub, PowerSeries.coeff_X_pow_mul', PowerSeries.coeff_succ_X_mul,
    PowerSeries.coeff_zero_X_mul, PowerSeries.coeff_C_mul, PowerSeries.coeff_derivative,
    map_zero] at h <;>
  norm_num at h ⊢ <;>
  linear_combination h

#print axioms legendre_series_rec

/-- The series stops. Let n be a whole number and y = a_0 + a_1 x + a_2 x^2 + ... a power series
that solves Legendre's equation (1 - x^2) y'' - 2x y' + n(n + 1) y = 0 term by term. If y is the
series of n's parity (only even powers for even n, only odd powers for odd n), then every
coefficient past x^n is zero: the series stops at x^n. -/
theorem legendre_series_stops_at_x_pow_n (n : ℕ) (y : PowerSeries ℝ)
    (hy : (1 - PowerSeries.X ^ 2) * PowerSeries.derivative (PowerSeries.derivative y)
        - 2 * PowerSeries.X * PowerSeries.derivative y
        + PowerSeries.C ((n : ℝ) * (n + 1)) * y = 0)
    (hparity : ∀ k : ℕ, k % 2 ≠ n % 2 → PowerSeries.coeff k y = 0) :
    ∀ k : ℕ, n < k → PowerSeries.coeff k y = 0 := by
  intro k
  induction k using Nat.strong_induction_on with
  | _ k ih =>
    intro hk
    by_cases hp : k % 2 = n % 2
    · obtain ⟨j, rfl⟩ : ∃ j, k = j + 2 := ⟨k - 2, by omega⟩
      have hr := legendre_series_rec n y hy j
      have hj : n ≤ j := by omega
      have hpos : ((j : ℝ) + 2) * ((j : ℝ) + 1) ≠ 0 := by positivity
      rcases hj.lt_or_eq with hlt | heq
      · rw [ih j (by omega) hlt, mul_zero] at hr
        exact (mul_eq_zero.mp hr).resolve_right hpos
      · subst heq
        rw [sub_self, zero_mul] at hr
        exact (mul_eq_zero.mp hr).resolve_right hpos
    · exact hparity k hp

theorem legendre_iterate_eq (c : ℝ) (Q : ℝ[X])
    (hQ : (1 - X ^ 2) * derivative (derivative Q) - 2 * X * derivative Q + C c * Q = 0) (j : ℕ) :
    (1 - X ^ 2) * derivative^[j + 2] Q - C (2 * ((j : ℝ) + 1)) * X * derivative^[j + 1] Q
      + C (c - (j : ℝ) * (j + 1)) * derivative^[j] Q = 0 := by
  induction j with
  | zero => simpa [map_ofNat] using hQ
  | succ j ih =>
    have h := congrArg derivative ih
    rw [show j + 1 + 2 = (j + 1) + 1 + 1 by ring] 
    rw [show j + 2 = j + 1 + 1 by ring] at h
    simp only [derivative_mul, derivative_sub, derivative_add, derivative_one, derivative_X_pow,
      derivative_X, derivative_C, derivative_zero, zero_mul, zero_add, map_add, map_mul, map_sub,
      map_one, map_natCast, map_ofNat, Function.iterate_succ_apply', derivative_ofNat, derivative_natCast] at h ⊢
    push_cast at h ⊢
    linear_combination h

#print axioms legendre_iterate_eq

/-- A polynomial solution of Legendre's equation that vanishes at x = 1 is zero. -/
theorem legendre_eval_one_eq_zero (n : ℕ) (Q : ℝ[X])
    (hQ : (1 - X ^ 2) * derivative (derivative Q) - 2 * X * derivative Q
        + C ((n : ℝ) * (n + 1)) * Q = 0) (h1 : Q.eval 1 = 0) : Q = 0 := by
  have hall : ∀ j : ℕ, (derivative^[j] Q).eval 1 = 0 := by
    intro j
    induction j with
    | zero => simpa using h1
    | succ j ih =>
      have h := congrArg (eval 1) (legendre_iterate_eq _ Q hQ j)
      simp only [eval_add, eval_sub, eval_mul, eval_one, eval_pow, eval_X, eval_C,
        eval_zero, ih] at h
      have hpos : (2 : ℝ) * ((j : ℝ) + 1) ≠ 0 := by positivity
      have : 2 * ((j : ℝ) + 1) * (derivative^[j + 1] Q).eval 1 = 0 := by
        linear_combination -h
      exact (mul_eq_zero.mp this).resolve_left hpos
  by_contra hne
  set d := Q.natDegree
  have hd : derivative^[d] Q = C ((derivative^[d] Q).coeff 0) :=
    eq_C_of_natDegree_le_zero (by have := natDegree_iterate_derivative Q d; omega)
  have h0 := hall d
  rw [hd, eval_C, coeff_iterate_derivative, zero_add, Nat.descFactorial_self, nsmul_eq_mul] at h0
  have hl : Q.coeff d ≠ 0 := by
    simpa [d] using (leadingCoeff_ne_zero.mpr hne)
  have : (d.factorial : ℝ) ≠ 0 := by positivity
  exact mul_ne_zero this hl h0

#print axioms legendre_eval_one_eq_zero

theorem rodrigues_iterate (n : ℕ) (j : ℕ) :
    (X ^ 2 - 1) * derivative^[j + 2] ((X ^ 2 - 1 : ℝ[X]) ^ n)
      + C (2 * (j : ℝ) + 2 - 2 * n) * X * derivative^[j + 1] ((X ^ 2 - 1 : ℝ[X]) ^ n)
      + C ((j : ℝ) * (j + 1) - 2 * n * (j + 1)) * derivative^[j] ((X ^ 2 - 1 : ℝ[X]) ^ n)
      = 0 := by
  set u : ℝ[X] := (X ^ 2 - 1) ^ n with hu
  have base : (X ^ 2 - 1) * derivative u = C (2 * (n : ℝ)) * X * u := by
    rcases n with _ | m
    · simp [hu]
    · rw [hu, derivative_pow]
      simp only [Nat.add_sub_cancel, derivative_sub, derivative_X_pow, derivative_one, map_natCast,
        map_mul, map_ofNat]
      push_cast
      ring
  induction j with
  | zero =>
    have h := congrArg derivative base
    rw [show (0 : ℕ) + 2 = 0 + 1 + 1 by ring]
    simp only [derivative_mul, derivative_sub, derivative_add, derivative_one, derivative_X_pow,
      derivative_X, derivative_C, derivative_zero, zero_mul, zero_add, map_add, map_mul, map_sub,
      map_one, map_natCast, map_ofNat, Function.iterate_succ_apply', derivative_ofNat, derivative_natCast,
      Function.iterate_zero_apply] at h ⊢
    push_cast at h ⊢
    linear_combination h
  | succ j ih =>
    have h := congrArg derivative ih
    rw [show j + 1 + 2 = (j + 1) + 1 + 1 by ring] 
    rw [show j + 2 = j + 1 + 1 by ring] at h
    simp only [derivative_mul, derivative_sub, derivative_add, derivative_one, derivative_X_pow,
      derivative_X, derivative_C, derivative_zero, zero_mul, zero_add, map_add, map_mul, map_sub,
      map_one, map_natCast, map_ofNat, Function.iterate_succ_apply', derivative_ofNat, derivative_natCast] at h ⊢
    push_cast at h ⊢
    linear_combination h

#print axioms rodrigues_iterate

theorem rodrigues_natDegree (n : ℕ) :
    (derivative^[n] ((X ^ 2 - 1 : ℝ[X]) ^ n)).natDegree = n := by
  have hm : ((X ^ 2 - 1 : ℝ[X]) ^ n).Monic := by
    apply Monic.pow
    simpa using (monic_X_pow_sub_C (1 : ℝ) (by norm_num : (2 : ℕ) ≠ 0))
  have hdeg : ((X ^ 2 - 1 : ℝ[X]) ^ n).natDegree = 2 * n := by
    rw [natDegree_pow, show (X ^ 2 - 1 : ℝ[X]) = X ^ 2 - C 1 by simp, natDegree_X_pow_sub_C]
    ring
  apply natDegree_eq_of_le_of_coeff_ne_zero
  · have := natDegree_iterate_derivative ((X ^ 2 - 1 : ℝ[X]) ^ n) n
    omega
  · rw [coeff_iterate_derivative, show n + n = 2 * n by ring, ← hdeg, hm.coeff_natDegree,
      nsmul_eq_mul, mul_one]
    have : 0 < (2 * n).descFactorial n := Nat.descFactorial_pos.mpr (by omega)
    rw [hdeg]
    exact_mod_cast this.ne'

#print axioms rodrigues_natDegree

/-- The Legendre polynomial. For every whole number n there is a polynomial solution of
(1 - x^2) y'' - 2x y' + n(n + 1) y = 0 of degree exactly n that equals 1 at x = 1, and it is the
only polynomial solution that equals 1 at x = 1. This is P_n. -/
theorem legendre_polynomial_exists_unique (n : ℕ) :
    ∃ P : ℝ[X], P.natDegree = n ∧
      (1 - X ^ 2) * derivative (derivative P) - 2 * X * derivative P
        + C ((n : ℝ) * (n + 1)) * P = 0 ∧
      P.eval 1 = 1 ∧
      ∀ Q : ℝ[X], (1 - X ^ 2) * derivative (derivative Q) - 2 * X * derivative Q
          + C ((n : ℝ) * (n + 1)) * Q = 0 → Q.eval 1 = 1 → Q = P := by
  set v : ℝ[X] := derivative^[n] ((X ^ 2 - 1 : ℝ[X]) ^ n) with hv
  have hveq : (1 - X ^ 2) * derivative (derivative v) - 2 * X * derivative v
      + C ((n : ℝ) * (n + 1)) * v = 0 := by
    have h := rodrigues_iterate n n
    simp only [Function.iterate_succ_apply', map_add, map_mul, map_sub, map_one, map_natCast,
      map_ofNat] at h ⊢
    rw [hv]
    linear_combination -h
  have hvdeg : v.natDegree = n := rodrigues_natDegree n
  have hv0 : v ≠ 0 := by
    intro h0
    rcases n with _ | m
    · simp [hv] at h0
    · rw [h0, natDegree_zero] at hvdeg
      omega
  have hv1 : v.eval 1 ≠ 0 := fun h => hv0 (legendre_eval_one_eq_zero n v hveq h)
  refine ⟨C (v.eval 1)⁻¹ * v, ?_, ?_, ?_, ?_⟩
  · rw [natDegree_C_mul (inv_ne_zero hv1), hvdeg]
  · simp only [derivative_mul, derivative_C, zero_mul, zero_add]
    linear_combination C (v.eval 1)⁻¹ * hveq
  · simp [hv1]
  · intro Q hQ hQ1
    have hd : (1 - X ^ 2) * derivative (derivative (Q - C (v.eval 1)⁻¹ * v))
        - 2 * X * derivative (Q - C (v.eval 1)⁻¹ * v)
        + C ((n : ℝ) * (n + 1)) * (Q - C (v.eval 1)⁻¹ * v) = 0 := by
      simp only [derivative_mul, derivative_sub, derivative_C, zero_mul, zero_add]
      linear_combination hQ - C (v.eval 1)⁻¹ * hveq
    have := legendre_eval_one_eq_zero n _ hd (by simp [hQ1, hv1])
    exact sub_eq_zero.mp this

/-- Orthogonality. For different whole numbers m and n, polynomial solutions of Legendre's
equation with parameters m and n, multiplied together and integrated from -1 to 1 with weight 1,
give zero. -/
theorem legendre_orthogonal (m n : ℕ) (hmn : m ≠ n) (P Q : ℝ[X])
    (hP : (1 - X ^ 2) * derivative (derivative P) - 2 * X * derivative P
        + C ((m : ℝ) * (m + 1)) * P = 0)
    (hQ : (1 - X ^ 2) * derivative (derivative Q) - 2 * X * derivative Q
        + C ((n : ℝ) * (n + 1)) * Q = 0) :
    ∫ x in (-1 : ℝ)..1, P.eval x * Q.eval x = 0 := by
  set c : ℝ := (n : ℝ) * (n + 1) - (m : ℝ) * (m + 1) with hc
  set W : ℝ[X] := (1 - X ^ 2) * (derivative P * Q - P * derivative Q) with hW
  have hWd : derivative W = C c * (P * Q) := by
    rw [hW, hc]
    simp only [derivative_mul, derivative_sub, derivative_one, derivative_X_pow, map_sub,
      derivative_X, map_natCast, map_ofNat, derivative_ofNat] at *
    linear_combination Q * hP - P * hQ
  have hc0 : c ≠ 0 := by
    rw [hc]
    intro h
    apply hmn
    have : ((m : ℝ) - n) * (m + n + 1) = 0 := by linear_combination -h
    rcases mul_eq_zero.mp this with h1 | h1
    · exact_mod_cast sub_eq_zero.mp h1
    · have : (0 : ℝ) < m + n + 1 := by positivity
      linarith
  have hint : ∫ x in (-1 : ℝ)..1, (derivative W).eval x = W.eval 1 - W.eval (-1) :=
    intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => W.hasDerivAt x)
      ((derivative W).continuous.intervalIntegrable _ _)
  have hWe : W.eval 1 - W.eval (-1) = 0 := by simp [hW]
  have key : c * ∫ x in (-1 : ℝ)..1, P.eval x * Q.eval x = 0 := by
    rw [← intervalIntegral.integral_const_mul, ← hWe, ← hint]
    congr 1
    ext x
    simp [hWd]
  exact (mul_eq_zero.mp key).resolve_left hc0

-- The two-step rule at n = 2, k = 0: a_2 = (0 - 2)(0 + 3)/((0 + 1)(0 + 2)) a_0 = -3 a_0.
example : ((0 : ℚ) - 2) * (0 + 2 + 1) / ((0 + 1) * (0 + 2)) = -3 := by norm_num
-- Before scaling, the series 1 - 3x^2, x - (5/3)x^3 and 1 - 10x^2 + (35/3)x^4 are -2, -2/3, 8/3 at x = 1.
example : (1 : ℚ) - 3 * 1 ^ 2 = -2 := by norm_num
example : (1 : ℚ) - 5 / 3 * 1 ^ 3 = -2 / 3 := by norm_num
example : ((2 : ℚ) - 4) * (2 + 4 + 1) / ((2 + 1) * (2 + 2)) * ((0 - 4) * (0 + 4 + 1) / ((0 + 1) * (0 + 2))) = 35 / 3 ∧
    (1 : ℚ) - 10 + 35 / 3 = 8 / 3 := by norm_num
-- P2 = (3x^2 - 1)/2 solves Legendre's equation with n = 2, equals 1 at x = 1 and -1/2 on the equator.
example : (1 - X ^ 2) * derivative (derivative (C (3 / 2 : ℝ) * X ^ 2 - C (1 / 2))) -
      2 * X * derivative (C (3 / 2 : ℝ) * X ^ 2 - C (1 / 2))
      + C ((2 : ℝ) * (2 + 1)) * (C (3 / 2 : ℝ) * X ^ 2 - C (1 / 2)) = 0 := by
  apply Polynomial.funext; intro x; simp; ring
example : (C (3 / 2 : ℝ) * X ^ 2 - C (1 / 2)).eval 1 = 1 ∧
    (C (3 / 2 : ℝ) * X ^ 2 - C (1 / 2)).eval 0 = -1 / 2 := by
  norm_num
-- Bonnet's rule at n = 2: 3 P3 = 5x P2 - 2 P1.
example (x : ℝ) : 3 * ((5 * x ^ 3 - 3 * x) / 2) = 5 * x * ((3 * x ^ 2 - 1) / 2) - 2 * x := by ring
-- P1 P2 integrates to 0; P2 squared integrates to 2/5 = 2/(2*2 + 1).
example : ∫ x in (-1 : ℝ)..1, x * ((3 * x ^ 2 - 1) / 2) = 0 := by
  have : (fun x : ℝ => x * ((3 * x ^ 2 - 1) / 2)) = fun x => (3 / 2) * x ^ 3 - (1 / 2) * x ^ 1 := by
    ext x; ring
  rw [this, intervalIntegral.integral_sub, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul, integral_pow, integral_pow] <;>
    first | exact (by fun_prop : Continuous _).intervalIntegrable _ _ | norm_num
example : ∫ x in (-1 : ℝ)..1, ((3 * x ^ 2 - 1) / 2) ^ 2 = 2 / 5 := by
  have : (fun x : ℝ => ((3 * x ^ 2 - 1) / 2) ^ 2) = fun x => ((9 / 4) * x ^ 4 - (3 / 2) * x ^ 2) + 1 / 4 := by
    ext x; ring
  rw [this, intervalIntegral.integral_add, intervalIntegral.integral_sub, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    integral_pow, integral_pow] <;>
    first | exact (by fun_prop : Continuous _).intervalIntegrable _ _ | norm_num
-- The sphere: c_0 = (1/2) * integral of 30x^2 = 10 V, c_2 = (5/2) * integral of 30x^2 P2 = 20 V,
-- and 30x^2 = 10 + 20 P2(x).
example : (1 / 2 : ℝ) * ∫ x in (-1 : ℝ)..1, 30 * x ^ 2 = 10 := by
  rw [intervalIntegral.integral_const_mul, integral_pow]; norm_num
example : (5 / 2 : ℝ) * ∫ x in (-1 : ℝ)..1, 30 * x ^ 2 * ((3 * x ^ 2 - 1) / 2) = 20 := by
  have : (fun x : ℝ => 30 * x ^ 2 * ((3 * x ^ 2 - 1) / 2)) = fun x => 45 * x ^ 4 - 15 * x ^ 2 := by
    ext x; ring
  rw [this, intervalIntegral.integral_sub, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul, integral_pow, integral_pow] <;>
    first | exact (by fun_prop : Continuous _).intervalIntegrable _ _ | norm_num
example (x : ℝ) : 30 * x ^ 2 = 10 + 20 * ((3 * x ^ 2 - 1) / 2) := by ring
-- Voltage V = c_0 + c_2 (r/R)^2 P2: 10 V at the centre, 15 V at 5 cm on the axis, 7.5 V towards the equator.
example : (10 : ℚ) + 20 * (5 / 10) ^ 2 * 1 = 15 ∧ (10 : ℚ) + 20 * (5 / 10) ^ 2 * (-1 / 2) = 15 / 2 := by
  norm_num
-- The mistakes: weight 1 - x^2 gives -4/15 for P0 with P2; dropping (2n + 1)/2 gives 20 V at the centre.
example : ∫ x in (-1 : ℝ)..1, (1 - x ^ 2) * ((3 * x ^ 2 - 1) / 2) = -4 / 15 := by
  have : (fun x : ℝ => (1 - x ^ 2) * ((3 * x ^ 2 - 1) / 2)) = fun x => (2 * x ^ 2 - (3 / 2) * x ^ 4) - 1 / 2 := by
    ext x; ring
  rw [this, intervalIntegral.integral_sub, intervalIntegral.integral_sub, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    integral_pow, integral_pow] <;>
    first | exact (by fun_prop : Continuous _).intervalIntegrable _ _ | norm_num
example : (∫ x in (-1 : ℝ)..1, 30 * x ^ 2) = 20 := by
  rw [intervalIntegral.integral_const_mul, integral_pow]; norm_num

#print axioms legendre_series_stops_at_x_pow_n
#print axioms legendre_polynomial_exists_unique
#print axioms legendre_orthogonal
