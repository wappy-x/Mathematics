-- Daubechies wavelets: a detail filter with p vanishing moments gives zero detail on every polynomial of degree below p, and the four D4 taps are the only solutions, up to mirror image, of the sum, two-moment and orthogonality equations, which cannot hold a third moment.
import Mathlib.Algebra.Polynomial.Degree.Defs
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.Polynomial.Eval.Degree
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset Polynomial

/-- The level-1 detail at position k of a detail filter g with L taps:
d[k] = g_0 x[2k] + g_1 x[2k+1] + ... + g_(L-1) x[2k+L-1]. -/
def detail (g x : ℕ → ℝ) (L k : ℕ) : ℝ := ∑ m ∈ range L, g m * x (2 * k + m)

/-- The detail filter g with L taps has p vanishing moments: its weights, multiplied by each
power m^0, m^1, ..., m^(p-1) of their position m and added, give zero. -/
def HasVanishingMoments (g : ℕ → ℝ) (L p : ℕ) : Prop :=
  ∀ r < p, ∑ m ∈ range L, (m : ℝ) ^ r * g m = 0

/-- Helper: the moment conditions kill every shifted power (2k + m)^i with i < p. -/
theorem shifted_power_moment_zero (g : ℕ → ℝ) (L p : ℕ)
    (hg : HasVanishingMoments g L p) (k i : ℕ) (hi : i < p) :
    ∑ m ∈ range L, g m * ((2 * k + m : ℕ) : ℝ) ^ i = 0 := by
  have h1 : ∀ m ∈ range L, g m * ((2 * k + m : ℕ) : ℝ) ^ i =
      ∑ j ∈ range (i + 1), ((2 * k : ℝ) ^ (i - j) * (i.choose j : ℝ)) * ((m : ℝ) ^ j * g m) := by
    intro m _
    rw [show ((2 * k + m : ℕ) : ℝ) = (m : ℝ) + 2 * k by push_cast; ring, add_pow, mul_sum]
    refine sum_congr rfl fun j _ => ?_
    ring
  rw [sum_congr rfl h1, sum_comm]
  refine sum_eq_zero fun j hj => ?_
  rw [← mul_sum, hg j (by simp at hj; omega), mul_zero]

#print axioms shifted_power_moment_zero

/-- A detail filter with p vanishing moments gives zero detail, at every position, on every
signal that is a polynomial of degree below p in the reading number. -/
theorem vanishing_moments_give_zero_detail_on_polynomials (g : ℕ → ℝ) (L p : ℕ)
    (hg : HasVanishingMoments g L p) (P : ℝ[X]) (hP : P.degree < p) (k : ℕ) :
    detail g (fun n => P.eval (n : ℝ)) L k = 0 := by
  unfold detail
  simp_rw [eval_eq_sum_range, mul_sum]
  rw [sum_comm]
  refine sum_eq_zero fun i _ => ?_
  by_cases hi : i < p
  · have := shifted_power_moment_zero g L p hg k i hi
    calc ∑ m ∈ range L, g m * (P.coeff i * ((2 * k + m : ℕ) : ℝ) ^ i)
        = P.coeff i * ∑ m ∈ range L, g m * ((2 * k + m : ℕ) : ℝ) ^ i := by
          rw [mul_sum]; refine sum_congr rfl fun m _ => ?_; ring
      _ = 0 := by rw [this, mul_zero]
  · have hc : P.coeff i = 0 :=
      coeff_eq_zero_of_degree_lt (lt_of_lt_of_le hP (by exact_mod_cast not_lt.mp hi))
    simp [hc]

/-- The four-tap filter h = (h₀, h₁, h₂, h₃), with detail filter g = (h₃, -h₂, h₁, -h₀), meets
the sum condition h₀ + h₁ + h₂ + h₃ = √2, moment 0 (g₀ + g₁ + g₂ + g₃ = 0), moment 1
(0 g₀ + 1 g₁ + 2 g₂ + 3 g₃ = 0) and orthogonality to its double shift (h₀ h₂ + h₁ h₃ = 0)
exactly when it is D4, h = (1 + √3, 3 + √3, 3 - √3, 1 - √3) / (4√2), or D4's mirror image,
the same four numbers in reverse order. -/
theorem d4_is_fixed_by_four_equations (h₀ h₁ h₂ h₃ : ℝ) :
    (h₀ + h₁ + h₂ + h₃ = √2 ∧ h₃ - h₂ + h₁ - h₀ = 0 ∧ -h₂ + 2 * h₁ - 3 * h₀ = 0 ∧
        h₀ * h₂ + h₁ * h₃ = 0) ↔
      ((h₀, h₁, h₂, h₃) = ((1 + √3) / (4 * √2), (3 + √3) / (4 * √2), (3 - √3) / (4 * √2),
          (1 - √3) / (4 * √2)) ∨
        (h₀, h₁, h₂, h₃) = ((1 - √3) / (4 * √2), (3 - √3) / (4 * √2), (3 + √3) / (4 * √2),
          (1 + √3) / (4 * √2))) := by
  have hs : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have ht : √3 * √3 = 3 := Real.mul_self_sqrt (by norm_num)
  have hs0 : √2 ≠ 0 := by positivity
  have hs2 : √2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have ht2 : √3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  simp only [Prod.mk.injEq]
  constructor
  · rintro ⟨e1, e2, e3, e4⟩
    have q1 : h₁ = h₀ + √2 / 4 := by linarith
    have q2 : h₂ = √2 / 2 - h₀ := by linarith
    have q3 : h₃ = √2 / 4 - h₀ := by linarith
    subst q1 q2 q3
    have hq : (h₀ - (1 + √3) / (4 * √2)) * (h₀ - (1 - √3) / (4 * √2)) = 0 := by
      field_simp
      linear_combination (-16) * e4 + (16 * h₀ ^ 2 + 1) * hs - ht
    rcases mul_eq_zero.mp hq with h | h
    · have h0 : h₀ = (1 + √3) / (4 * √2) := by linarith
      left
      refine ⟨h0, ?_, ?_, ?_⟩ <;> rw [h0] <;> field_simp <;> ring_nf <;> linarith [hs2, ht2]
    · have h0 : h₀ = (1 - √3) / (4 * √2) := by linarith
      right
      refine ⟨h0, ?_, ?_, ?_⟩ <;> rw [h0] <;> field_simp <;> ring_nf <;> linarith [hs2, ht2]
  · rintro (⟨rfl, rfl, rfl, rfl⟩ | ⟨rfl, rfl, rfl, rfl⟩) <;>
      refine ⟨?_, ?_, ?_, ?_⟩ <;> field_simp <;> ring_nf <;> linarith [hs2, ht2]

/-- Four taps cannot hold three vanishing moments: if the sum is √2 and the detail filter
g = (h₃, -h₂, h₁, -h₀) has moments 0, 1 and 2 equal to zero, then the double-shift
orthogonality sum h₀ h₂ + h₁ h₃ is 3/16 = 0.1875, not zero, so orthogonality is lost. -/
theorem four_taps_cannot_hold_three_moments (h₀ h₁ h₂ h₃ : ℝ)
    (hsum : h₀ + h₁ + h₂ + h₃ = √2) (hm0 : h₃ - h₂ + h₁ - h₀ = 0)
    (hm1 : -h₂ + 2 * h₁ - 3 * h₀ = 0) (hm2 : -h₂ + 4 * h₁ - 9 * h₀ = 0) :
    h₀ * h₂ + h₁ * h₃ = 3 / 16 := by
  have q1 : h₁ = 3 * h₀ := by linarith
  have q2 : h₂ = 3 * h₀ := by linarith
  have q3 : h₃ = h₀ := by linarith
  have q0 : h₀ = √2 / 8 := by linarith
  have hs : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  rw [q1, q2, q3, q0]
  linear_combination (3 / 32) * hs

-- The straight line 12.0, 12.5, 13.0, 13.5 °C gives a D4 detail of exactly zero.
example :
    (1 - √3) / (4 * √2) * 12 - (3 - √3) / (4 * √2) * (25 / 2) + (3 + √3) / (4 * √2) * 13
      - (1 + √3) / (4 * √2) * (27 / 2) = 0 := by
  ring

-- The D4 taps have energy 1: (1 + √3)² + (3 + √3)² + (3 - √3)² + (1 - √3)² = 32 = (4√2)².
example : (1 + √3) ^ 2 + (3 + √3) ^ 2 + (3 - √3) ^ 2 + (1 - √3) ^ 2 = (4 * √2) ^ 2 := by
  ring_nf
  norm_num

-- Four taps forced to three moments are proportional to 1, 3, 3, 1, with orthogonality sum
-- (1·3 + 3·1) / 32 = 3/16.
example : ((1 : ℚ) * 3 + 3 * 1) / 32 = 3 / 16 := by norm_num

#print axioms vanishing_moments_give_zero_detail_on_polynomials
#print axioms d4_is_fixed_by_four_equations
#print axioms four_taps_cannot_hold_three_moments
