-- Pricing a CDS: the premium leg is the spread times the risky annuity, there is exactly one par spread (protection divided by annuity) when the annuity has a positive term, and for a flat rate and hazard the annuity is a geometric sum and the protection leg is the area under one exponential.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum

open Finset

/-- The premium leg is the spread times the risky annuity, and exactly one spread makes it equal
to the protection leg. Premiums fall on dates `t 1, …, t n` (`n ≥ 1`), each covering a slice `δ > 0`
of a year; `D u > 0` is today's value of 1 due at `u` and `Q u ≥ 0` the chance the company survives
to `u`, with some chance `Q (t 1) > 0` of surviving to the first premium date. Then for every spread
`s` the premium leg `∑ s δ D(t_j) Q(t_j)` equals `s × A`, where `A = ∑ δ D(t_j) Q(t_j)` is the risky
annuity; and for any protection-leg value `P`, the premium leg equals `P` exactly when `s = P / A`,
so the par spread exists and is unique. -/
theorem premium_leg_eq_spread_mul_annuity_and_par_spread_unique
    (n : ℕ) (hn : 1 ≤ n) (δ : ℝ) (hδ : 0 < δ) (D Q : ℝ → ℝ) (t : ℕ → ℝ)
    (hD : ∀ u, 0 < D u) (hQ : ∀ u, 0 ≤ Q u) (hQ1 : 0 < Q (t 1)) (P : ℝ) :
    (∀ s : ℝ, ∑ j ∈ Icc 1 n, s * δ * D (t j) * Q (t j)
        = s * ∑ j ∈ Icc 1 n, δ * D (t j) * Q (t j)) ∧
    ∀ s : ℝ, (∑ j ∈ Icc 1 n, s * δ * D (t j) * Q (t j) = P ↔
        s = P / ∑ j ∈ Icc 1 n, δ * D (t j) * Q (t j)) := by
  have hsum : ∀ s : ℝ, ∑ j ∈ Icc 1 n, s * δ * D (t j) * Q (t j)
      = s * ∑ j ∈ Icc 1 n, δ * D (t j) * Q (t j) := by
    intro s
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl ?_
    intro j _
    ring
  have hA : 0 < ∑ j ∈ Icc 1 n, δ * D (t j) * Q (t j) := by
    have h1 : (1 : ℕ) ∈ Icc 1 n := Finset.mem_Icc.mpr ⟨le_refl 1, hn⟩
    have hle : δ * D (t 1) * Q (t 1) ≤ ∑ j ∈ Icc 1 n, δ * D (t j) * Q (t j) :=
      Finset.single_le_sum (f := fun j => δ * D (t j) * Q (t j))
        (fun j _ => mul_nonneg (mul_nonneg hδ.le (hD _).le) (hQ _)) h1
    have hpos : 0 < δ * D (t 1) * Q (t 1) := mul_pos (mul_pos hδ (hD _)) hQ1
    linarith
  refine ⟨hsum, ?_⟩
  intro s
  rw [hsum s, eq_div_iff hA.ne']

/-- Flat curves, the risky annuity: with discount factor `e^{-r t}`, survival `e^{-λ t}`
(`c = r + λ > 0`) and premiums every `δ > 0` years at `t_j = j δ`, the annuity
`∑_{j=1}^n δ e^{-r t_j} e^{-λ t_j}` equals `δ x (1 - x^n) / (1 - x)` with `x = e^{-c δ}`. -/
theorem risky_annuity_flat_closed_form (r lam δ : ℝ) (n : ℕ) (hc : 0 < r + lam) (hδ : 0 < δ) :
    ∑ j ∈ Icc 1 n, δ * Real.exp (-r * (j * δ)) * Real.exp (-lam * (j * δ))
      = δ * (Real.exp (-(r + lam) * δ) * (1 - Real.exp (-(r + lam) * δ) ^ n)
          / (1 - Real.exp (-(r + lam) * δ))) := by
  set x := Real.exp (-(r + lam) * δ) with hx
  have hx1 : x < 1 := by
    rw [hx, Real.exp_lt_one_iff]
    nlinarith
  have hx1' : (1 - x) ≠ 0 := by linarith
  have hterm : ∀ j : ℕ, δ * Real.exp (-r * (j * δ)) * Real.exp (-lam * (j * δ)) = δ * x ^ j := by
    intro j
    rw [mul_assoc, ← Real.exp_add, hx, ← Real.exp_nat_mul]
    congr 2
    ring
  simp_rw [hterm]
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    field_simp
    ring

/-- Flat curves, the protection leg: with discount factor `e^{-r t}`, constant hazard `λ`,
survival `e^{-λ t}` and `c = r + λ > 0`, the protection leg
`(1 - R) ∫_0^T e^{-r t} λ e^{-λ t} dt` equals `(1 - R) λ (1 - e^{-c T}) / c`. -/
theorem protection_leg_flat_closed_form (r lam R T : ℝ) (hc : 0 < r + lam) :
    (1 - R) * ∫ u in (0 : ℝ)..T, Real.exp (-r * u) * lam * Real.exp (-lam * u)
      = (1 - R) * lam * (1 - Real.exp (-(r + lam) * T)) / (r + lam) := by
  have hc' : (r + lam) ≠ 0 := hc.ne'
  have hderiv : ∀ u ∈ Set.uIcc (0 : ℝ) T,
      HasDerivAt (fun u => -(lam / (r + lam)) * Real.exp (-(r + lam) * u))
        (Real.exp (-r * u) * lam * Real.exp (-lam * u)) u := by
    intro u _
    have h1 : HasDerivAt (fun u => -(r + lam) * u) (-(r + lam)) u := by
      simpa using (hasDerivAt_id u).const_mul (-(r + lam))
    have h2 := (h1.exp).const_mul (-(lam / (r + lam)))
    convert h2 using 1
    have he : Real.exp (-r * u) * Real.exp (-lam * u) = Real.exp (-(r + lam) * u) := by
      rw [← Real.exp_add]; ring_nf
    rw [← he]
    field_simp
  have hint : IntervalIntegrable (fun u => Real.exp (-r * u) * lam * Real.exp (-lam * u))
      MeasureTheory.volume 0 T := by
    apply Continuous.intervalIntegrable
    fun_prop
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint]
  simp only [mul_zero, Real.exp_zero]
  field_simp
  ring

-- Northwind: rate 5%, hazard 2%, recovery 40%, five years of quarterly premiums.
-- Combined shrink rate c = 0.05 + 0.02 = 0.07.
example : (5 : ℚ) / 100 + 2 / 100 = 7 / 100 := by norm_num
-- Five years of quarters is n = 20 premium dates.
example : (5 : ℚ) / (1 / 4) = 20 := by norm_num
-- Twenty quarters of shrink: c δ n = 0.07 × 0.25 × 20 = 0.35, the exponent in x^20 = e^{-0.35}.
example : (7 / 100 : ℚ) * (1 / 4) * 20 = 35 / 100 := by norm_num
-- Continuous premiums: the par spread is (1 - R) λ = 0.6 × 0.02, which is 120 bp exactly.
example : (1 - (40 : ℚ) / 100) * (2 / 100) * 10000 = 120 := by norm_num
-- "R in place of 1 - R" scales the spread by R / (1 - R) = 2/3 (121.06 bp to 80.70 bp).
example : ((40 : ℚ) / 100) / (1 - 40 / 100) = 2 / 3 := by norm_num

#print axioms premium_leg_eq_spread_mul_annuity_and_par_spread_unique
#print axioms risky_annuity_flat_closed_form
#print axioms protection_leg_flat_closed_form
