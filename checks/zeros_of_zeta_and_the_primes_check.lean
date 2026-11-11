-- Zeta's zeros and the primes: minus zeta's slope over zeta is the series with weight ln p on every prime power where Re s > 1, zeta has no zero where Re s ≥ 1, and every zero of zeta other than the trivial zeros -2, -4, -6, … lies in the critical strip 0 ≤ Re s ≤ 1.
import Mathlib.NumberTheory.LSeries.Nonvanishing
import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.NumberTheory.ArithmeticFunction.VonMangoldt
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.Tactic.NormNum

open ArithmeticFunction

/-- Zeta's logarithmic derivative counts prime powers. For every complex s with real part
greater than 1, the series ∑ Λ(n)/n^s, with weight Λ(n) = ln p when n is a power of a prime p
and 0 otherwise, converges, and its value is -ζ′(s)/ζ(s). -/
theorem neg_zeta_log_derivative_eq_von_mangoldt_series (s : ℂ) (hs : 1 < s.re) :
    Summable (fun n : ℕ => (Λ n : ℂ) / (n : ℂ) ^ s) ∧
      -deriv riemannZeta s / riemannZeta s = ∑' n : ℕ, (Λ n : ℂ) / (n : ℂ) ^ s := by
  have h0 : (fun n : ℕ => (Λ n : ℂ)) 0 = 0 := by simp
  have hterm : LSeries.term (fun n : ℕ => (Λ n : ℂ)) s = fun n : ℕ => (Λ n : ℂ) / (n : ℂ) ^ s := by
    funext n
    rw [LSeries.term_def]
    split_ifs with h
    · subst h; simp
    · rfl
  refine ⟨?_, ?_⟩
  · have := LSeriesSummable_vonMangoldt hs
    rw [LSeriesSummable, hterm] at this
    exact this
  · rw [← LSeries_vonMangoldt_eq_deriv_riemannZeta_div hs, LSeries_def₀ h0]

/-- No zero on or right of the line Re s = 1. The Euler product has no zero where Re s > 1,
and (Hadamard and de la Vallée Poussin, 1896) zeta has no zero on the line Re s = 1 either. -/
theorem zeta_ne_zero_where_re_ge_one (s : ℂ) (hs : 1 ≤ s.re) : riemannZeta s ≠ 0 := by
  exact riemannZeta_ne_zero_of_one_le_re hs

/-- Where the zeros are. Every zero of zeta other than the trivial zeros -2, -4, -6, … lies in
the critical strip 0 ≤ Re s ≤ 1. -/
theorem nontrivial_zero_in_critical_strip (s : ℂ) (hz : riemannZeta s = 0)
    (hnt : ∀ n : ℕ, s ≠ -2 * ((n : ℂ) + 1)) :
    0 ≤ s.re ∧ s.re ≤ 1 := by
  refine ⟨?_, ?_⟩
  · by_contra h
    rw [not_le] at h
    obtain ⟨n, hn⟩ := (riemannZeta_eq_zero_iff_of_re_nonpos h.le).mp hz
    exact hnt n hn
  · by_contra h
    rw [not_le] at h
    exact riemannZeta_ne_zero_of_one_le_re h.le hz

-- The staircase at 100: 25 primes, 2, 3, 5, …, 97.
example : Nat.primeCounting 100 = 25 := by
  rw [Nat.primeCounting, Nat.primeCounting', Nat.count_eq_card_filter_range]
  decide
-- Legendre's count at 100: 22 numbers from 1 to 100 have none of 2, 3, 5, 7 as a factor,
-- and 22 + 4 - 1 = 25.
example : (List.range' 1 100).countP (fun n => Nat.gcd n 210 == 1) = 22 := by decide
example : 22 + 4 - 1 = 25 := by norm_num
-- The weights: Λ(8) = ln 2 and Λ(6) = 0.
example : Λ 8 = Real.log 2 := by
  rw [show (8 : ℕ) = 2 ^ 3 by norm_num, vonMangoldt_apply_pow (by norm_num),
    vonMangoldt_apply_prime Nat.prime_two]
  norm_num
example : Λ 6 = 0 := by
  rw [vonMangoldt_eq_zero_iff]
  decide

#print axioms neg_zeta_log_derivative_eq_von_mangoldt_series
#print axioms zeta_ne_zero_where_re_ge_one
#print axioms nontrivial_zero_in_critical_strip
