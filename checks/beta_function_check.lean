-- The beta function: for a, b > 0 the area under x^(a-1)(1-x)^(b-1) from 0 to 1 equals Γ(a)Γ(b)/Γ(a+b), also for complex a, b with positive real parts, and B(1/2, 1/2) = π.
import Mathlib.Analysis.SpecialFunctions.Gamma.Beta

open Real

/-- Helper: the real beta integral, cast to ℂ, is the complex beta integral at real arguments. -/
lemma beta_real_integral_ofReal (a b : ℝ) :
    ((∫ x in (0 : ℝ)..1, x ^ (a - 1) * (1 - x) ^ (b - 1) : ℝ) : ℂ) =
      ∫ x in (0 : ℝ)..1, (x : ℂ) ^ ((a : ℂ) - 1) * (1 - (x : ℂ)) ^ ((b : ℂ) - 1) := by
  rw [← intervalIntegral.integral_ofReal]
  refine intervalIntegral.integral_congr fun x hx => ?_
  rw [Set.uIcc_of_le zero_le_one] at hx
  have h0 : 0 ≤ x := hx.1
  have h1 : 0 ≤ 1 - x := by linarith [hx.2]
  simp only [Complex.ofReal_mul]
  rw [Complex.ofReal_cpow h0, Complex.ofReal_cpow h1]
  push_cast
  ring_nf

#print axioms beta_real_integral_ofReal

/-- The beta function as a gamma ratio: for real a > 0 and b > 0, the area under
x^(a-1)(1-x)^(b-1) from 0 to 1 is Γ(a)Γ(b)/Γ(a+b). -/
theorem beta_integral_eq_gamma_ratio (a b : ℝ) (ha : 0 < a) (hb : 0 < b) :
    ∫ x in (0 : ℝ)..1, x ^ (a - 1) * (1 - x) ^ (b - 1) =
      Real.Gamma a * Real.Gamma b / Real.Gamma (a + b) := by
  have h := Complex.betaIntegral_eq_Gamma_mul_div (a : ℂ) (b : ℂ) (by simpa using ha)
    (by simpa using hb)
  rw [Complex.betaIntegral, ← beta_real_integral_ofReal, ← Complex.ofReal_add,
    Complex.Gamma_ofReal, Complex.Gamma_ofReal, Complex.Gamma_ofReal] at h
  exact_mod_cast h

/-- The same formula for complex a and b: when the real parts of a and b are positive,
the integral of x^(a-1)(1-x)^(b-1) over 0 to 1 is Γ(a)Γ(b)/Γ(a+b). -/
theorem beta_integral_eq_gamma_ratio_complex (a b : ℂ) (ha : 0 < a.re) (hb : 0 < b.re) :
    ∫ x in (0 : ℝ)..1, (x : ℂ) ^ (a - 1) * (1 - (x : ℂ)) ^ (b - 1) =
      Complex.Gamma a * Complex.Gamma b / Complex.Gamma (a + b) := by
  rw [← Complex.betaIntegral_eq_Gamma_mul_div a b ha hb]
  rfl

/-- The half values: B(1/2, 1/2), the area under x^(-1/2)(1-x)^(-1/2) from 0 to 1, is π. -/
theorem beta_half_half_eq_pi :
    ∫ x in (0 : ℝ)..1, x ^ ((1 : ℝ) / 2 - 1) * (1 - x) ^ ((1 : ℝ) / 2 - 1) = π := by
  rw [beta_integral_eq_gamma_ratio _ _ (by norm_num) (by norm_num)]
  norm_num [Real.Gamma_one_half_eq, Real.mul_self_sqrt Real.pi_pos.le]

-- The ramp as gammas: Γ(2)Γ(3)/Γ(5) = 1!·2!/4! = 2/24 = 1/12.
example : ((Nat.factorial 1 * Nat.factorial 2 : ℕ) : ℚ) / (Nat.factorial 4 : ℕ) = 1 / 12 := by
  norm_num [Nat.factorial]

-- The ramp term by term: x(1-x)^2 = x - 2x^2 + x^3 has area 1/2 - 2/3 + 1/4 = 1/12.
example : (1 / 2 : ℚ) - 2 / 3 + 1 / 4 = 1 / 12 := by norm_num

-- Mistake 1: B(3, 4) = 2!·3!/6! = 1/60, a fifth of 1/12.
example : ((Nat.factorial 2 * Nat.factorial 3 : ℕ) : ℚ) / (Nat.factorial 6 : ℕ) = 1 / 60 := by
  norm_num [Nat.factorial]

-- Mistake 2: factorials with no shift, 2!·3!/5! = 1/10.
example : ((Nat.factorial 2 * Nat.factorial 3 : ℕ) : ℚ) / (Nat.factorial 5 : ℕ) = 1 / 10 := by
  norm_num [Nat.factorial]

-- Mistake 3: stretch factor dropped, Γ(2)Γ(3)/Γ(4) = 1!·2!/3! = 1/3.
example : ((Nat.factorial 1 * Nat.factorial 2 : ℕ) : ℚ) / (Nat.factorial 3 : ℕ) = 1 / 3 := by
  norm_num [Nat.factorial]

-- B(3, 3/2): Γ(9/2) = (7/2)(5/2)(3/2)(1/2)Γ(1/2) = (105/16)Γ(1/2), and Γ(3)Γ(3/2) = 2·(1/2)Γ(1/2),
-- so B(3, 3/2) = 1 / (105/16) = 16/105.
example : (7 / 2 : ℚ) * (5 / 2) * (3 / 2) * (1 / 2) = 105 / 16 := by norm_num
example : (2 * (1 / 2) : ℚ) / (105 / 16) = 16 / 105 := by norm_num

-- Binomial coefficients: 1/B(2, 3) = (3 + 1) · (3 choose 1) = 12 for the ramp.
example : (3 + 1) * Nat.choose 3 1 = 12 := by decide

#print axioms beta_integral_eq_gamma_ratio
#print axioms beta_integral_eq_gamma_ratio_complex
#print axioms beta_half_half_eq_pi
