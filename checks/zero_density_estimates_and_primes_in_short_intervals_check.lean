-- Zero-density estimates: count times size, (T^A/x)^(1 − σ) with T = x^(1 − θ), is below 1 exactly when θ > 1 − 1/A, and the envelopes of Huxley and of Guth and Maynard peak at 12/5 and 30/13.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.IntervalCases

open Real

/-- Count against size (Steps 0 and 4). Take the cut height `T = x^(1 − θ)`, so that a density
exponent `A > 0` allows about `T^(A(1 − σ))` zeros with real part at least `σ`, each of relative size
`x^(σ − 1)`. Their product `(T^A / x)^(1 − σ)` equals `x^(−κ(1 − σ))` with margin
`κ = 1 − A(1 − θ)`, and for `x > 1` and `σ < 1` it is below 1 exactly when `θ > 1 − 1/A`. -/
theorem count_times_size_lt_one_iff {A θ σ x : ℝ} (hA : 0 < A) (hx : 1 < x) (hσ : σ < 1) :
    ((x ^ (1 - θ)) ^ A / x) ^ (1 - σ) = x ^ (-(1 - A * (1 - θ)) * (1 - σ)) ∧
      (((x ^ (1 - θ)) ^ A / x) ^ (1 - σ) < 1 ↔ 1 - 1 / A < θ) := by
  have hx0 : 0 < x := by linarith
  have key : ((x ^ (1 - θ)) ^ A / x) ^ (1 - σ) = x ^ (-(1 - A * (1 - θ)) * (1 - σ)) := by
    rw [← Real.rpow_mul hx0.le]
    conv_lhs => rw [show x ^ ((1 - θ) * A) / x = x ^ ((1 - θ) * A) / x ^ (1:ℝ) by rw [Real.rpow_one]]
    rw [← Real.rpow_sub hx0, ← Real.rpow_mul hx0.le]
    congr 1; ring
  refine ⟨key, ?_⟩
  rw [key]
  have e1 : ∀ e : ℝ, x ^ e < 1 ↔ e < 0 := fun e => by
    simpa using Real.rpow_lt_rpow_left_iff hx (y := e) (z := 0)
  rw [e1]
  have h1σ : 0 < 1 - σ := by linarith
  constructor
  · intro h
    have h2 : 0 < 1 - A * (1 - θ) := by
      by_contra hc
      push Not at hc
      nlinarith
    have : A * (1 - θ) < 1 := by linarith
    have h3 : 1 - θ < 1 / A := by rw [lt_div_iff₀ hA]; linarith
    linarith
  · intro h
    have h3 : 1 - θ < 1 / A := by linarith
    rw [lt_div_iff₀ hA] at h3
    nlinarith

/-- Huxley's density exponent (Step 6): the envelope `A(σ) = min(3/(2 − σ), 3/(3σ − 1))`, Ingham's
1940 bound joined to Huxley's large-values bound, has largest value `12/5` over `1/2 ≤ σ ≤ 1`,
reached at `σ = 3/4`. -/
theorem huxley_envelope_max :
    IsGreatest ((fun σ : ℝ => min (3 / (2 - σ)) (3 / (3 * σ - 1))) '' Set.Icc (1 / 2) 1) (12 / 5) ∧
      min (3 / (2 - (3 / 4 : ℝ))) (3 / (3 * (3 / 4) - 1)) = 12 / 5 := by
  have hv : min (3 / (2 - (3 / 4 : ℝ))) (3 / (3 * (3 / 4) - 1)) = 12 / 5 := by norm_num
  refine ⟨⟨⟨3 / 4, ⟨by norm_num, by norm_num⟩, hv⟩, ?_⟩, hv⟩
  rintro y ⟨σ, ⟨h1, h2⟩, rfl⟩
  rcases le_total σ (3 / 4) with h | h
  · refine (min_le_left _ _).trans ?_
    rw [div_le_iff₀ (by linarith)]; linarith
  · refine (min_le_right _ _).trans ?_
    rw [div_le_iff₀ (by linarith)]; linarith

/-- Guth and Maynard's density exponent (Step 6): the envelope
`A(σ) = min(3/(2 − σ), 15/(3 + 5σ))` has largest value `30/13` over `1/2 ≤ σ ≤ 1`, reached at
`σ = 7/10`. -/
theorem guth_maynard_envelope_max :
    IsGreatest ((fun σ : ℝ => min (3 / (2 - σ)) (15 / (3 + 5 * σ))) '' Set.Icc (1 / 2) 1) (30 / 13) ∧
      min (3 / (2 - (7 / 10 : ℝ))) (15 / (3 + 5 * (7 / 10))) = 30 / 13 := by
  have hv : min (3 / (2 - (7 / 10 : ℝ))) (15 / (3 + 5 * (7 / 10))) = 30 / 13 := by norm_num
  refine ⟨⟨⟨7 / 10, ⟨by norm_num, by norm_num⟩, hv⟩, ?_⟩, hv⟩
  rintro y ⟨σ, ⟨h1, h2⟩, rfl⟩
  rcases le_total σ (7 / 10) with h | h
  · refine (min_le_left _ _).trans ?_
    rw [div_le_iff₀ (by linarith)]; linarith
  · refine (min_le_right _ _).trans ?_
    rw [div_le_iff₀ (by linarith)]; linarith

-- Every window, θ = 1 − 1/A: Carlson 4 → 3/4, Ingham 8/3 → 5/8, Huxley 12/5 → 7/12,
-- Guth–Maynard 30/13 → 17/30, the density hypothesis 2 → 1/2.
example : (1 - 1 / 4 : ℚ) = 3 / 4 ∧ (1 - 1 / (8 / 3) : ℚ) = 5 / 8 ∧
    (1 - 1 / (12 / 5) : ℚ) = 7 / 12 ∧ (1 - 1 / (30 / 13) : ℚ) = 17 / 30 ∧
    (1 - 1 / 2 : ℚ) = 1 / 2 := by
  norm_num

-- Almost every window, θ = 1 − 2/A: 1/2, 1/4, 1/6, 2/15 and 0.
example : (1 - 2 / 4 : ℚ) = 1 / 2 ∧ (1 - 2 / (8 / 3) : ℚ) = 1 / 4 ∧
    (1 - 2 / (12 / 5) : ℚ) = 1 / 6 ∧ (1 - 2 / (30 / 13) : ℚ) = 2 / 15 ∧
    (1 - 2 / 2 : ℚ) = 0 := by
  norm_num

-- The margin at A = 12/5, θ = 5/8 is κ = 1/10; at the edge θ = 7/12 it is 0.
example : (1 - 12 / 5 * (1 - 5 / 8) : ℚ) = 1 / 10 ∧ (1 - 12 / 5 * (1 - 7 / 12) : ℚ) = 0 := by
  norm_num

-- Ingham's 1940 envelope 3/(2 − σ) is at most 8/3 up to σ = 7/8, where it equals 8/3, and is 3 at σ = 1.
example : (3 / (2 - 7 / 8) : ℚ) = 8 / 3 ∧ (3 / (2 - 1) : ℚ) = 3 := by
  norm_num

-- Window widths at x = 10^6: ⌊10^(7/12 · 6)⌋ = ⌊√(10^7)⌋ = 3,162, ⌊10^(15/4)⌋ = 5,623 and
-- ⌊10^(17/5)⌋ = 2,511.
example : 3162 ^ 2 ≤ 10 ^ 7 ∧ 10 ^ 7 < 3163 ^ 2 := by
  norm_num

example : 5623 ^ 4 ≤ 10 ^ 15 ∧ 10 ^ 15 < 5624 ^ 4 := by
  norm_num

example : 2511 ^ 5 ≤ 10 ^ 17 ∧ 10 ^ 17 < 2512 ^ 5 := by
  norm_num

-- What breaks: the gap of 114 after the prime 492,113; the next prime is 492,227, so the window
-- (p, p + 78] of width ⌊p^(1/3)⌋ = 78 holds no prime.
example : Nat.Prime 492113 ∧ Nat.Prime 492227 ∧
    (∀ m, 492113 < m → m < 492227 → ¬ Nat.Prime m) ∧
    78 ^ 3 ≤ 492113 ∧ 492113 < 79 ^ 3 := by
  refine ⟨by norm_num, by norm_num, ?_, by norm_num, by norm_num⟩
  intro m h1 h2
  interval_cases m <;> norm_num

#print axioms count_times_size_lt_one_iff
#print axioms huxley_envelope_max
#print axioms guth_maynard_envelope_max
