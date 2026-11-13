-- Continuous-time chains: the M/M/1 balance equations have the single solution (1 - ρ) ρ^n with mean ρ / (1 - ρ) when ρ < 1, and the two-state desk with no hold line is busy with chance λ/(λ + μ) (1 - e^(-(λ + μ) t)).
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Calculus.MeanValue

/-- The M/M/1 law. One server, arrivals at rate `lam`, services at rate `mu`, load
`ρ = lam / mu` below 1. A row `π` of shares on the states 0, 1, 2, ... solves "rate out equals
rate in" at every state (at 0: `lam π₀ = mu π₁`; at `n + 1`:
`(lam + mu) π_{n+1} = lam π_n + mu π_{n+2}`) and adds up to 1 exactly when
`π_n = (1 - ρ) ρ^n` for every `n`: this is the stationary distribution, and the only one. -/
theorem mm1_stationary_law (lam mu : ℝ) (hlam : 0 < lam) (hload : lam < mu) (π : ℕ → ℝ) :
    ((lam * π 0 = mu * π 1 ∧
        ∀ n : ℕ, (lam + mu) * π (n + 1) = lam * π n + mu * π (n + 2)) ∧ HasSum π 1) ↔
      ∀ n : ℕ, π n = (1 - lam / mu) * (lam / mu) ^ n := by
  have hmu : 0 < mu := hlam.trans hload
  have hρ0 : 0 ≤ lam / mu := (div_pos hlam hmu).le
  have hρ1 : lam / mu < 1 := (div_lt_one hmu).2 hload
  have hgeo := hasSum_geometric_of_lt_one hρ0 hρ1
  have hne : (1 - lam / mu) ≠ 0 := by linarith
  have hmρ : mu * (lam / mu) = lam := by field_simp
  constructor
  · rintro ⟨⟨h0, hstep⟩, hsum⟩
    have hflux : ∀ n, mu * π (n + 1) = lam * π n := by
      intro n
      induction n with
      | zero => exact h0.symm
      | succ k ih =>
        have := hstep k
        linarith
    have hform : ∀ n, π n = π 0 * (lam / mu) ^ n := by
      intro n
      induction n with
      | zero => simp
      | succ k ih =>
        have h := hflux k
        rw [pow_succ, ← mul_assoc, ← ih]
        field_simp
        linarith
    have hs2 : HasSum π (π 0 * (1 - lam / mu)⁻¹) := by
      have := hgeo.mul_left (π 0)
      convert this using 1
      exact funext hform
    have h1 := hsum.unique hs2
    have hπ0 : π 0 = 1 - lam / mu := by
      field_simp at h1
      rw [eq_comm, ← sub_eq_zero]; field_simp; linarith
    intro n
    rw [hform n, hπ0]
  · intro h
    have hπ : π = fun n => (1 - lam / mu) * (lam / mu) ^ n := funext h
    subst hπ
    refine ⟨⟨?_, ?_⟩, ?_⟩
    · simp only [pow_zero, pow_one, mul_one]
      rw [mul_comm (1 - lam / mu), ← mul_assoc, hmρ, mul_comm]
    · intro n
      have e1 : mu * (lam / mu) ^ (n + 2) = lam * (lam / mu) ^ (n + 1) := by
        rw [pow_succ _ (n + 1), mul_comm _ (lam / mu), ← mul_assoc, hmρ]
      have e2 : mu * (lam / mu) ^ (n + 1) = lam * (lam / mu) ^ n := by
        rw [pow_succ, mul_comm _ (lam / mu), ← mul_assoc, hmρ]
      linear_combination (1 - lam / mu) * (e2 - e1)
    · have := hgeo.mul_left (1 - lam / mu)
      rwa [mul_inv_cancel₀ hne] at this

/-- The mean number in an M/M/1 system. With load `ρ = lam / mu` below 1, the average
`L = ∑ n π_n` of the law `π_n = (1 - ρ) ρ^n` is `ρ / (1 - ρ)`. -/
theorem mm1_mean_in_system (lam mu : ℝ) (hlam : 0 < lam) (hload : lam < mu) :
    HasSum (fun n : ℕ => (n : ℝ) * ((1 - lam / mu) * (lam / mu) ^ n))
      ((lam / mu) / (1 - lam / mu)) := by
  have hmu : 0 < mu := hlam.trans hload
  have hρ0 : 0 ≤ lam / mu := (div_pos hlam hmu).le
  have hρ1 : lam / mu < 1 := (div_lt_one hmu).2 hload
  have hne : (1 - lam / mu) ≠ 0 := by linarith
  have hn : ‖lam / mu‖ < 1 := by rw [Real.norm_of_nonneg hρ0]; exact hρ1
  have := (hasSum_coe_mul_geometric_of_norm_lt_one hn).mul_left (1 - lam / mu)
  convert this using 1
  · funext n; ring
  · field_simp

/-- The desk with no hold line. States idle (0) and busy (1), rate matrix
`G = [[-lam, lam], [mu, -mu]]`. If the chances `p₀ t`, `p₁ t` start idle (`p₀ 0 = 1`,
`p₁ 0 = 0`) and solve the forward equations `p' = p G` for all times `t ≥ 0` (an ordinary
derivative for `t > 0`, taken from the right at the start `t = 0`), then the chance of busy at
time `t` is `lam / (lam + mu) * (1 - e^(-(lam + mu) t))`. -/
theorem two_state_busy_chance (lam mu : ℝ) (hlam : 0 < lam) (hmu : 0 < mu) (p₀ p₁ : ℝ → ℝ)
    (h₀ : p₀ 0 = 1) (h₁ : p₁ 0 = 0)
    (hd₀ : ∀ t, 0 ≤ t → HasDerivWithinAt p₀ (p₀ t * (-lam) + p₁ t * mu) (Set.Ici 0) t)
    (hd₁ : ∀ t, 0 ≤ t → HasDerivWithinAt p₁ (p₀ t * lam + p₁ t * (-mu)) (Set.Ici 0) t) :
    ∀ t, 0 ≤ t → p₁ t = lam / (lam + mu) * (1 - Real.exp (-(lam + mu) * t)) := by
  intro t ht
  have hk : 0 < lam + mu := by linarith
  have hkne : lam + mu ≠ 0 := hk.ne'
  -- total mass stays 1
  have hsum : ∀ x, 0 ≤ x → p₀ x + p₁ x = 1 := by
    intro x hx
    have hd : ∀ y, 0 ≤ y → HasDerivWithinAt (fun y => p₀ y + p₁ y) 0 (Set.Ici 0) y := by
      intro y hy
      have := (hd₀ y hy).add (hd₁ y hy)
      convert this using 1
      ring
    have hc := constant_of_has_deriv_right_zero (f := fun y => p₀ y + p₁ y) (a := 0) (b := x)
      (fun y hy => ((hd y hy.1).continuousWithinAt).mono Set.Icc_subset_Ici_self)
      (fun y hy => (hd y hy.1).mono (Set.Ici_subset_Ici.2 hy.1)) x ⟨hx, le_rfl⟩
    rw [hc, h₀, h₁]; ring
  -- g t = exp((lam+mu) t) * (p₁ t - lam/(lam+mu)) is constant
  set g : ℝ → ℝ := fun y => Real.exp ((lam + mu) * y) * (p₁ y - lam / (lam + mu)) with hg
  have hdg : ∀ y, 0 ≤ y → HasDerivWithinAt g 0 (Set.Ici 0) y := by
    intro y hy
    have he : HasDerivWithinAt (fun y => Real.exp ((lam + mu) * y))
        (Real.exp ((lam + mu) * y) * (lam + mu)) (Set.Ici 0) y := by
      have := ((hasDerivAt_id y).const_mul (lam + mu)).exp
      simpa using this.hasDerivWithinAt
    have hp := (hd₁ y hy).sub_const (lam / (lam + mu))
    have := he.mul hp
    convert this using 1
    have hs := hsum y hy
    have hp0 : p₀ y = 1 - p₁ y := by linarith
    rw [hp0]
    field_simp
    ring
  have hc := constant_of_has_deriv_right_zero (f := g) (a := 0) (b := t)
    (fun y hy => ((hdg y hy.1).continuousWithinAt).mono Set.Icc_subset_Ici_self)
    (fun y hy => (hdg y hy.1).mono (Set.Ici_subset_Ici.2 hy.1)) t ⟨ht, le_rfl⟩
  simp only [hg, mul_zero, Real.exp_zero, one_mul, h₁] at hc
  have hE : Real.exp (-(lam + mu) * t) * Real.exp ((lam + mu) * t) = 1 := by
    rw [← Real.exp_add]; ring_nf; exact Real.exp_zero
  have hpos := Real.exp_pos ((lam + mu) * t)
  have : p₁ t - lam / (lam + mu) = Real.exp (-(lam + mu) * t) * (0 - lam / (lam + mu)) := by
    rw [← hc, ← mul_assoc, hE, one_mul]
  linear_combination this

-- Worked numbers, by hand: arrivals 4 and services 5 an hour.
-- The load ρ = 4/5, the desk empty π₀ = 1/5, one person 4/25, two people 16/125.
example : (1 - (4 : ℚ) / 5) = 1 / 5 := by norm_num
example : (1 - (4 : ℚ) / 5) * (4 / 5) ^ 1 = 4 / 25 := by norm_num
example : (1 - (4 : ℚ) / 5) * (4 / 5) ^ 2 = 16 / 125 := by norm_num
-- Five or more: ρ^5 = 1024/3125 (about 0.3277); ten or more: ρ^10 (about 0.1074).
example : ((4 : ℚ) / 5) ^ 5 = 1024 / 3125 := by norm_num
example : ((4 : ℚ) / 5) ^ 10 = 1048576 / 9765625 := by norm_num
-- Mean in system L = 4, mean on hold 4 - 4/5 = 16/5, mean time in system W = L / λ = 1 hour.
example : ((4 : ℚ) / 5) / (1 - 4 / 5) = 4 := by norm_num
example : (4 : ℚ) - (1 - 1 / 5) = 16 / 5 := by norm_num
example : (4 : ℚ) / 4 = 1 := by norm_num
-- The load is the lever: 4.5, 4.75 and 4.9 arrivals an hour give L = 9, 19 and 49.
example : ((9 / 2 : ℚ) / 5) / (1 - (9 / 2) / 5) = 9 := by norm_num
example : ((19 / 4 : ℚ) / 5) / (1 - (19 / 4) / 5) = 19 := by norm_num
example : ((49 / 10 : ℚ) / 5) / (1 - (49 / 10) / 5) = 49 := by norm_num
-- Dropping ρ < 1: 5.5 arrivals an hour put the formula at L = -11.
example : ((11 / 2 : ℚ) / 5) / (1 - (11 / 2) / 5) = -11 := by norm_num
-- No hold line: π = (5/9, 4/9) balances 4 π₀ = 5 π₁ and adds to 1.
example : (4 : ℚ) * (5 / 9) = 5 * (4 / 9) ∧ (5 : ℚ) / 9 + 4 / 9 = 1 := by norm_num
-- Uniformization at clock rate 9: K = I + G/9 = [[5/9, 4/9], [5/9, 4/9]], K² = K, and the
-- ticks give back the rates 9 × 4/9 = 4 and 9 × 5/9 = 5.
example : (1 : Matrix (Fin 2) (Fin 2) ℚ) + (1 / 9 : ℚ) • !![-4, 4; 5, -5] =
    !![5 / 9, 4 / 9; 5 / 9, 4 / 9] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num
example : !![(5 / 9 : ℚ), 4 / 9; 5 / 9, 4 / 9] * !![5 / 9, 4 / 9; 5 / 9, 4 / 9] =
    !![5 / 9, 4 / 9; 5 / 9, 4 / 9] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : (9 : ℚ) * (4 / 9) = 4 ∧ (9 : ℚ) * (5 / 9) = 5 := by norm_num

#print axioms mm1_stationary_law
#print axioms mm1_mean_in_system
#print axioms two_state_busy_chance
