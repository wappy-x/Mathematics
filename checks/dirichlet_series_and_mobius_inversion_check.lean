-- Dirichlet series: the product of two absolutely convergent Dirichlet series is the series of the divisor convolution of their weights, one over zeta is the series with the Möbius weights where Re s > 1, and Möbius weights undo any divisor sum.
import Mathlib.NumberTheory.LSeries.Convolution
import Mathlib.NumberTheory.LSeries.Dirichlet
import Mathlib.NumberTheory.ArithmeticFunction.Moebius

open Finset ArithmeticFunction
open scoped ArithmeticFunction.Moebius ArithmeticFunction.Omega

open scoped LSeries.notation in
/-- Helper: the divisor-sum weights have the same L-series terms as the convolution `a ⍟ b`. -/
theorem divisor_sum_term_eq_term_convolution (a b : ℕ → ℂ) (s : ℂ) :
    LSeries.term (fun n => ∑ d ∈ n.divisors, a d * b (n / d)) s = LSeries.term (a ⍟ b) s := by
  funext n
  rcases eq_or_ne n 0 with rfl | hn
  · simp
  · rw [LSeries.term_of_ne_zero hn, LSeries.term_of_ne_zero hn, LSeries.convolution_def]
    simp only
    rw [Nat.sum_divisorsAntidiagonal (fun x y => a x * b y)]

#print axioms divisor_sum_term_eq_term_convolution

/-- Multiplying two Dirichlet series convolves their weights over divisors. Let a and b give one
complex number for each whole number n, and let s be a complex number at which both series
∑ a(n)/n^s and ∑ b(n)/n^s converge absolutely. Then the series whose weight at n is the divisor
sum (a ∗ b)(n) = ∑_{d ∣ n} a(d) b(n/d) also converges absolutely at s, and its value is the
product of the two series' values. -/
theorem dirichlet_series_mul_eq_series_of_divisor_convolution (a b : ℕ → ℂ) (s : ℂ)
    (ha : Summable (fun n => ‖LSeries.term a s n‖))
    (hb : Summable (fun n => ‖LSeries.term b s n‖)) :
    Summable (fun n => ‖LSeries.term (fun n => ∑ d ∈ n.divisors, a d * b (n / d)) s n‖) ∧
      LSeries (fun n => ∑ d ∈ n.divisors, a d * b (n / d)) s = LSeries a s * LSeries b s := by
  have ha' : LSeriesSummable a s := summable_norm_iff.mp ha
  have hb' : LSeriesSummable b s := summable_norm_iff.mp hb
  have hc := ha'.convolution hb'
  have hT := divisor_sum_term_eq_term_convolution a b s
  refine ⟨?_, ?_⟩
  · rw [hT]; exact summable_norm_iff.mpr hc
  · rw [← LSeries_convolution' ha' hb']
    unfold LSeries
    rw [hT]

/-- One over zeta has the Möbius weights. For every complex s with real part greater than 1, the
series ∑ μ(n)/n^s converges absolutely and equals 1/ζ(s). -/
theorem one_div_riemannZeta_eq_moebius_series (s : ℂ) (hs : 1 < s.re) :
    Summable (fun n => ‖LSeries.term (fun n => (μ n : ℂ)) s n‖) ∧
      1 / riemannZeta s = LSeries (fun n => (μ n : ℂ)) s := by
  have hm : LSeriesSummable (fun n => (μ n : ℂ)) s := LSeriesSummable_moebius_iff.mpr hs
  refine ⟨summable_norm_iff.mpr hm, ?_⟩
  have h := LSeries_zeta_mul_Lseries_moebius hs
  rw [LSeries_zeta_eq_riemannZeta hs] at h
  have hz : riemannZeta s ≠ 0 := by
    intro h0; rw [h0, zero_mul] at h; exact zero_ne_one h
  rw [eq_comm, eq_div_iff hz, mul_comm]
  exact h

/-- Möbius inversion, for every arithmetic function. If g at each n ≥ 1 is the sum of f over the
divisors of n (g = 1 ∗ f), then f at each n ≥ 1 is the Möbius-weighted divisor sum of g
(f = μ ∗ g), and the other way round. -/
theorem moebius_inversion {R : Type*} [CommRing R] (f g : ℕ → R) :
    (∀ n > 0, g n = ∑ d ∈ n.divisors, f d) ↔
      (∀ n > 0, f n = ∑ d ∈ n.divisors, (μ d : R) * g (n / d)) := by
  have h := (sum_eq_iff_sum_mul_moebius_eq (f := f) (g := g))
  simp only [Nat.sum_divisorsAntidiagonal (fun x y => (μ x : R) * g y)] at h
  constructor
  · intro H n hn; exact (h.mp (fun m hm => (H m hm).symm) n hn).symm
  · intro H n hn; exact (h.mpr (fun m hm => (H m hm).symm) n hn).symm

-- The six ways to cut the clock: 12 has six divisors, so τ(12) = 6, and (2 + 1)(1 + 1) = 6.
example : Nat.divisors 12 = {1, 2, 3, 4, 6, 12} := by decide
example : (Nat.divisors 12).card = 6 := by decide
example : (2 + 1) * (1 + 1) = 6 := by norm_num
-- τ is multiplicative across 4 × 3, but a shared prime breaks it: τ(2) × τ(2) = 4, τ(4) = 3.
example : (Nat.divisors 4).card * (Nat.divisors 3).card = 6 := by decide
example : (Nat.divisors 2).card * (Nat.divisors 2).card = 4 := by decide
example : (Nat.divisors 4).card = 3 := by decide
-- The weights of 1/ζ: μ(1) to μ(10) are 1, −1, −1, 0, −1, 1, −1, 0, 0, 1.
example : (List.range' 1 10).map (fun n => μ n) = [1, -1, -1, 0, -1, 1, -1, 0, 0, 1] := by
  decide +kernel
-- μ(6) = 1 and μ(12) = 0.
example : μ 6 = 1 := by decide +kernel
example : μ 12 = 0 := by decide +kernel
-- The Möbius signs over the divisors 1, 2, 3, 4, 6, 12 are 1, −1, −1, 0, 1, 0 and add to 0.
example : ([1, 2, 3, 4, 6, 12] : List ℕ).map (fun n => μ n) = [1, -1, -1, 0, 1, 0] := by
  decide +kernel
example : ∑ d ∈ Nat.divisors 12, μ d = 0 := by decide +kernel
-- Divisor sums: σ(6) = 1 + 2 + 3 + 6 = 12 and σ(12) = 28.
example : ∑ d ∈ Nat.divisors 6, d = 12 := by decide
example : ∑ d ∈ Nat.divisors 12, d = 28 := by decide
-- σ(6) back to 6: 12 − 4 − 3 + 1 = 6.
example : ∑ d ∈ Nat.divisors 6, μ d * ((∑ e ∈ Nat.divisors (6 / d), e : ℕ) : ℤ) = 6 := by
  decide +kernel
-- σ(12) back to 12: 28 − 12 − 7 + 0 + 3 + 0 = 12.
example : ∑ d ∈ Nat.divisors 12, μ d * ((∑ e ∈ Nat.divisors (12 / d), e : ℕ) : ℤ) = 12 := by
  decide +kernel
-- Signs that count repeated primes, (−1) to the number of prime factors with repeats, add to 1,
-- not 0, over the divisors of 4.
example : ∑ d ∈ Nat.divisors 4, (-1 : ℤ) ^ (Ω d) = 1 := by decide +kernel

#print axioms dirichlet_series_mul_eq_series_of_divisor_convolution
#print axioms one_div_riemannZeta_eq_moebius_series
#print axioms moebius_inversion
