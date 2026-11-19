-- Dirichlet L-functions: the L-function of every non-principal Dirichlet character is nonzero at 1, for σ > 1 it is the series of χ(n)/n^s and the product over primes of 1/(1 − χ(p)p^(−s)), and for the character mod 4 the series 1 − 1/3 + 1/5 − … sums to π/4.
import Mathlib.NumberTheory.LSeries.Nonvanishing
import Mathlib.NumberTheory.EulerProduct.DirichletLSeries
import Mathlib.NumberTheory.LegendreSymbol.ZModChar
import Mathlib.Analysis.Real.Pi.Leibniz

open Filter Topology Finset

/-- The value at 1 is never zero: for every Dirichlet character χ mod q other than the
principal character (the modulus q a positive whole number), the L-function L(s, χ) is not
zero at s = 1. -/
theorem dirichlet_L_one_ne_zero {q : ℕ} [NeZero q] (χ : DirichletCharacter ℂ q) (hχ : χ ≠ 1) :
    DirichletCharacter.LFunction χ 1 ≠ 0 := by
  exact DirichletCharacter.LFunction_apply_one_ne_zero hχ

/-- The series and the Euler product: when the real part of s is above 1, the L-function of a
Dirichlet character χ is the sum of χ(n)/n^s over the whole numbers n, and it is also the
product over all primes p of 1/(1 − χ(p) p^(−s)). -/
theorem dirichlet_L_series_and_euler_product {q : ℕ} [NeZero q] (χ : DirichletCharacter ℂ q) {s : ℂ}
    (hs : 1 < s.re) :
    HasSum (fun n : ℕ ↦ χ n / (n : ℂ) ^ s) (DirichletCharacter.LFunction χ s) ∧
      HasProd (fun p : Nat.Primes ↦ (1 - χ p * (p : ℂ) ^ (-s))⁻¹)
        (DirichletCharacter.LFunction χ s) := by
  have hsum : HasSum (fun n : ℕ ↦ χ n / (n : ℂ) ^ s) (DirichletCharacter.LFunction χ s) := by
    rw [DirichletCharacter.LFunction_eq_LSeries χ hs]
    have h := (DirichletCharacter.LSeriesSummable_of_one_lt_re χ hs).LSeriesHasSum
    have hs0 : s ≠ 0 := by
      intro h0
      rw [h0] at hs
      simp at hs
      linarith
    unfold LSeriesHasSum at h
    convert h using 1
    funext n
    rcases eq_or_ne n 0 with rfl | hn
    · simp [Complex.zero_cpow hs0]
    · rw [LSeries.term_of_ne_zero hn]
  refine ⟨hsum, ?_⟩
  rw [DirichletCharacter.LFunction_eq_LSeries χ hs]
  exact DirichletCharacter.LSeries_eulerProduct_hasProd χ hs

/-- The odd character mod 4 at s = 1: the partial sums of χ₄(n)/n, that is
1 − 1/3 + 1/5 − 1/7 + …, tend to π/4. -/
theorem chi4_L_one_eq_pi_div_four :
    Tendsto (fun N : ℕ ↦ ∑ n ∈ range N, ((ZMod.χ₄ (n : ZMod 4) : ℤ) : ℝ) / n) atTop
      (𝓝 (Real.pi / 4)) := by
  have key : ∀ k : ℕ,
      (∑ n ∈ range (2 * k), ((ZMod.χ₄ (n : ZMod 4) : ℤ) : ℝ) / n) =
        ∑ i ∈ range k, (-1 : ℝ) ^ i / (2 * i + 1) := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      rw [show 2 * (k + 1) = 2 * k + 1 + 1 by ring, sum_range_succ, sum_range_succ, ih,
        sum_range_succ]
      have h0 : ZMod.χ₄ ((2 * k : ℕ) : ZMod 4) = 0 := by
        rw [ZMod.χ₄_nat_eq_if_mod_four]
        simp [Nat.mul_mod_right]
      have h1 : ZMod.χ₄ ((2 * k + 1 : ℕ) : ZMod 4) = (-1) ^ k := by
        rw [ZMod.χ₄_eq_neg_one_pow (by omega)]
        congr 1
        omega
      rw [h0, h1]
      push_cast
      ring
  have key' : ∀ N : ℕ,
      (∑ n ∈ range N, ((ZMod.χ₄ (n : ZMod 4) : ℤ) : ℝ) / n) =
        ∑ i ∈ range (N / 2), (-1 : ℝ) ^ i / (2 * i + 1) := by
    intro N
    rcases Nat.even_or_odd' N with ⟨k, rfl | rfl⟩
    · rw [key, show 2 * k / 2 = k by omega]
    · rw [sum_range_succ, key, show (2 * k + 1) / 2 = k by omega]
      have h0 : ZMod.χ₄ ((2 * k : ℕ) : ZMod 4) = 0 := by
        rw [ZMod.χ₄_nat_eq_if_mod_four]
        simp [Nat.mul_mod_right]
      rw [h0]
      simp
  have hdiv : Tendsto (fun N : ℕ ↦ N / 2) atTop atTop := by
    rw [tendsto_atTop_atTop]
    intro b
    exact ⟨2 * b, fun n hn ↦ by omega⟩
  simp_rw [key']
  exact Real.tendsto_sum_pi_div_four.comp hdiv

-- The weights χ₄(1) to χ₄(10): 1, 0, −1, 0, 1, 0, −1, 0, 1, 0.
example : (List.range' 1 10).map (fun n : ℕ ↦ ZMod.χ₄ (n : ZMod 4)) =
    [1, 0, -1, 0, 1, 0, -1, 0, 1, 0] := by decide

-- The divisor sum to 10: the sum of χ₄(d)⌊10/d⌋ for d from 1 to 10 is 10 − 3 + 2 − 1 + 1 = 9.
example : ∑ d ∈ Icc (1 : ℕ) 10, ZMod.χ₄ (d : ZMod 4) * ((10 / d : ℕ) : ℤ) = 9 := by decide

-- The integer points (a, b) with 0 < a² + b² ≤ 10 number 36 = 4 × 9.
example : ((Icc (-3 : ℤ) 3 ×ˢ Icc (-3 : ℤ) 3).filter
    (fun x ↦ 0 < x.1 ^ 2 + x.2 ^ 2 ∧ x.1 ^ 2 + x.2 ^ 2 ≤ 10)).card = 36 := by decide

-- r(5) = χ₄(1) + χ₄(5) = 2 and r(3) = χ₄(1) + χ₄(3) = 0.
example : ∑ d ∈ Nat.divisors 5, ZMod.χ₄ (d : ZMod 4) = 2 := by decide
example : ∑ d ∈ Nat.divisors 3, ZMod.χ₄ (d : ZMod 4) = 0 := by decide

-- The running Euler product at s = 2 over 3, 5, 7: 9/10, then 15/16, then 147/160.
example : (1 - (ZMod.χ₄ (3 : ZMod 4) : ℚ) / 3 ^ 2)⁻¹ = 9 / 10 := by norm_num [ZMod.χ₄_int_three_mod_four]
example : (1 - (-1 : ℚ) / 3 ^ 2)⁻¹ * (1 - (1 : ℚ) / 5 ^ 2)⁻¹ = 15 / 16 := by norm_num
example : (1 - (-1 : ℚ) / 3 ^ 2)⁻¹ * (1 - (1 : ℚ) / 5 ^ 2)⁻¹ * (1 - (-1 : ℚ) / 7 ^ 2)⁻¹ =
    147 / 160 := by norm_num

-- The weight (−1)^(n+1) is not multiplicative: its value at 2 times itself is +1, at 4 it is −1.
example : ((-1 : ℤ) ^ (2 + 1)) * ((-1 : ℤ) ^ (2 + 1)) = 1 ∧ (-1 : ℤ) ^ (4 + 1) = -1 := by decide

#print axioms dirichlet_L_one_ne_zero
#print axioms dirichlet_L_series_and_euler_product
#print axioms chi4_L_one_eq_pi_div_four
