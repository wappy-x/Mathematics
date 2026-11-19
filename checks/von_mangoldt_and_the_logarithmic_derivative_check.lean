-- The von Mangoldt function: the divisor sum of Λ is log n, Λ is minus the sum of μ(d) log d, minus zeta's logarithmic derivative is the Dirichlet series of Λ, and ψ is the sum of θ at the roots of x.
import Mathlib.NumberTheory.Chebyshev
import Mathlib.NumberTheory.LSeries.Dirichlet
import Mathlib.NumberTheory.PrimeCounting

open ArithmeticFunction Chebyshev
open scoped ArithmeticFunction.Moebius

/-- The von Mangoldt function gives each prime power p^k the weight log p and every other
number the weight 0. With these weights, for every whole number n the weights of the divisors
of n add up to log n; and, turned around by Möbius inversion, Λ(n) is minus the sum of
μ(d) log d over the divisors d of n. -/
theorem vonMangoldt_divisor_sum_eq_log_and_moebius_form (n : ℕ) :
    (∑ d ∈ n.divisors, Λ d = Real.log n) ∧
      Λ n = -∑ d ∈ n.divisors, (μ d : ℝ) * Real.log d := by
  refine ⟨vonMangoldt_sum, ?_⟩
  have h := sum_moebius_mul_log_eq (n := n)
  simp only [ArithmeticFunction.log_apply] at h
  linarith

/-- Where the real part of s is above 1, the series of Λ(n)/n^s converges absolutely and
minus zeta's logarithmic derivative, −ζ′(s)/ζ(s), equals that series.
(The n = 0 term is 0, since Λ(0) = 0, so the sum is the card's sum from n = 1.) -/
theorem neg_logDeriv_riemannZeta_eq_sum_vonMangoldt (s : ℂ) (hs : 1 < s.re) :
    Summable (fun n : ℕ => ‖(Λ n : ℂ) / (n : ℂ) ^ s‖) ∧
      -deriv riemannZeta s / riemannZeta s = ∑' n : ℕ, (Λ n : ℂ) / (n : ℂ) ^ s := by
  have hsum := LSeriesSummable_vonMangoldt hs
  have hterm : ∀ n : ℕ, LSeries.term (fun n => (Λ n : ℂ)) s n = (Λ n : ℂ) / (n : ℂ) ^ s := by
    intro n
    rcases eq_or_ne n 0 with rfl | hn
    · simp
    · exact LSeries.term_of_ne_zero hn _ _
  have hfun : LSeries.term (fun n => (Λ n : ℂ)) s = fun n : ℕ => (Λ n : ℂ) / (n : ℂ) ^ s :=
    funext hterm
  refine ⟨?_, ?_⟩
  · have h : Summable (LSeries.term (fun n => (Λ n : ℂ)) s) := hsum
    rw [hfun] at h
    exact h.norm
  · rw [← LSeries_vonMangoldt_eq_deriv_riemannZeta_div hs]
    simp only [LSeries]
    rw [hfun]

/-- ψ from θ: the weighted count ψ(x) is θ(x) + θ(x^(1/2)) + θ(x^(1/3)) + ⋯. The sum is
finite: once 2^(N+1) is above x, every root x^(1/k) with k > N is below 2 and adds nothing,
so stopping at any such N gives ψ(x) exactly. -/
theorem psi_eq_sum_theta_at_roots (x : ℝ) (hx : 0 ≤ x) (N : ℕ) (hN : x < 2 ^ (N + 1)) :
    ψ x = ∑ k ∈ Finset.Icc 1 N, θ (x ^ ((1 : ℝ) / k)) := by
  apply psi_eq_sum_theta' hx
  rcases hx.eq_or_lt with h0 | hpos
  · subst h0; simp
  · have hl2 : 0 < Real.log 2 := Real.log_pos one_lt_two
    have hlt : Real.log x < ((N + 1 : ℕ) : ℝ) * Real.log 2 := by
      rw [← Real.log_rpow two_pos, Real.rpow_natCast]
      exact Real.log_lt_log hpos (by exact_mod_cast hN)
    have : Real.log x / Real.log 2 < ((N + 1 : ℕ) : ℝ) := by
      rw [div_lt_iff₀ hl2]; exact hlt
    have := (Nat.floor_lt' (Nat.succ_ne_zero N)).mpr this
    omega

-- There are 25 primes up to 100.
example : Nat.primeCounting 100 = 25 := by
  simp [Nat.primeCounting, Nat.primeCounting', Nat.count_eq_card_filter_range]
  decide

-- 720720 = 2^4 × 3^2 × 5 × 7 × 11 × 13, so its prime-power divisors are 2, 4, 8, 16, 3, 9,
-- 5, 7, 11 and 13: each divides it, and the next powers 32, 27, 25, 49, 121, 169 do not.
example : 720720 = 2 ^ 4 * 3 ^ 2 * 5 * 7 * 11 * 13 := by norm_num
example : (2 ∣ 720720 ∧ 4 ∣ 720720 ∧ 8 ∣ 720720 ∧ 16 ∣ 720720 ∧ 3 ∣ 720720 ∧ 9 ∣ 720720 ∧
    5 ∣ 720720 ∧ 7 ∣ 720720 ∧ 11 ∣ 720720 ∧ 13 ∣ 720720) ∧
    ¬ 32 ∣ 720720 ∧ ¬ 27 ∣ 720720 ∧ ¬ 25 ∣ 720720 ∧ ¬ 49 ∣ 720720 ∧
    ¬ 121 ∣ 720720 ∧ ¬ 169 ∣ 720720 := by decide

-- The least common multiple of 1, 2, …, 100, whose log is ψ(100), has 41 digits.
set_option maxRecDepth 100000 in
example : 10 ^ 40 ≤ (Finset.Icc 1 100).lcm id ∧ (Finset.Icc 1 100).lcm id < 10 ^ 41 := by
  decide

#print axioms vonMangoldt_divisor_sum_eq_log_and_moebius_form
#print axioms neg_logDeriv_riemannZeta_eq_sum_vonMangoldt
#print axioms psi_eq_sum_theta_at_roots
