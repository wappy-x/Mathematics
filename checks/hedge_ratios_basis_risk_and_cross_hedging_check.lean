-- Imperfect hedges: the hedge ratio rho * sigma_S / sigma_F (covariance over the futures' variance) is the one and only ratio that leaves the least variance, the variance it leaves is sigma_S^2 (1 - rho^2), and on data the least-squares slope is that same ratio.
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance

open ProbabilityTheory MeasureTheory

/-- The hedged variance is a quadratic in the hedge ratio. -/
lemma hedge_var_quad {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (dS dF : Ω → ℝ) (hS : MemLp dS 2 P) (hF : MemLp dF 2 P) (h : ℝ) :
    Var[fun ω => dS ω - h * dF ω; P]
      = Var[dS; P] - 2 * h * cov[dS, dF; P] + h ^ 2 * Var[dF; P] := by
  rw [variance_fun_sub hS (hF.const_mul h), covariance_const_mul_right, variance_const_mul]
  ring

/-- Cauchy-Schwarz for covariance, from the nonnegativity of the hedged variance. -/
lemma hedge_cov_sq_le {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (dS dF : Ω → ℝ) (hS : MemLp dS 2 P) (hF : MemLp dF 2 P)
    (hvF : 0 < Var[dF; P]) :
    cov[dS, dF; P] ^ 2 ≤ Var[dS; P] * Var[dF; P] := by
  have h0 := variance_nonneg (fun ω => dS ω - (cov[dS, dF; P] / Var[dF; P]) * dF ω) P
  rw [hedge_var_quad dS dF hS hF] at h0
  have e : Var[dS; P] - 2 * (cov[dS, dF; P] / Var[dF; P]) * cov[dS, dF; P]
      + (cov[dS, dF; P] / Var[dF; P]) ^ 2 * Var[dF; P]
      = (Var[dS; P] * Var[dF; P] - cov[dS, dF; P] ^ 2) / Var[dF; P] := by
    field_simp
    ring
  rw [e] at h0
  have := (div_nonneg_iff.mp h0)
  rcases this with ⟨h1, _⟩ | ⟨_, h2⟩
  · linarith
  · linarith

/-- The facts about `σS`, `σF`, `ρ`, `h*` used by both probabilistic theorems. -/
lemma hedge_facts {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (dS dF : Ω → ℝ) (hS : MemLp dS 2 P) (hF : MemLp dF 2 P)
    (hσF : 0 < Real.sqrt Var[dF; P]) :
    Real.sqrt Var[dS; P] ^ 2 = Var[dS; P] ∧
    Real.sqrt Var[dF; P] ^ 2 = Var[dF; P] ∧
    cov[dS, dF; P] / (Real.sqrt Var[dS; P] * Real.sqrt Var[dF; P]) * Real.sqrt Var[dS; P]
      * Real.sqrt Var[dF; P] = cov[dS, dF; P] := by
  have hvF : 0 < Var[dF; P] := Real.sqrt_pos.mp hσF
  have e1 : Real.sqrt Var[dS; P] ^ 2 = Var[dS; P] := Real.sq_sqrt (variance_nonneg _ _)
  have e2 : Real.sqrt Var[dF; P] ^ 2 = Var[dF; P] := Real.sq_sqrt (variance_nonneg _ _)
  refine ⟨e1, e2, ?_⟩
  by_cases hs : Real.sqrt Var[dS; P] = 0
  · have hv : Var[dS; P] = 0 := by rw [← e1, hs]; ring
    have hc := hedge_cov_sq_le dS dF hS hF hvF
    rw [hv, zero_mul] at hc
    have : cov[dS, dF; P] = 0 := by nlinarith [sq_nonneg cov[dS, dF; P]]
    rw [hs, this]; simp
  · field_simp


/-- The minimum-variance hedge ratio and the basis risk that remains. Let `dS` be the change
in the price of the thing hedged (jet fuel) and `dF` the change in the futures price (heating
oil) over the hedge's horizon, both with finite variance, and let the futures actually move
(`σ_F > 0`). Write `σ_S`, `σ_F` for the two spreads (standard deviations) and
`ρ = Cov(dS, dF) / (σ_S σ_F)` for their correlation. Then the hedge ratio
`h* = ρ σ_S / σ_F` equals `Cov(dS, dF) / σ_F²`; holding `h*` gallons of futures per gallon
leaves strictly less variance in `dS - h dF` than any other ratio `h`; and the spread it
leaves is `σ_S √(1 - ρ²)`. -/
theorem min_variance_hedge_ratio {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (dS dF : Ω → ℝ) (hS : MemLp dS 2 P) (hF : MemLp dF 2 P)
    (hσF : 0 < Real.sqrt Var[dF; P]) :
    let σS := Real.sqrt Var[dS; P]
    let σF := Real.sqrt Var[dF; P]
    let ρ := cov[dS, dF; P] / (σS * σF)
    let hstar := ρ * σS / σF
    hstar = cov[dS, dF; P] / σF ^ 2 ∧
    (∀ h : ℝ, h ≠ hstar →
      Var[fun ω => dS ω - hstar * dF ω; P] < Var[fun ω => dS ω - h * dF ω; P]) ∧
    Real.sqrt Var[fun ω => dS ω - hstar * dF ω; P] = σS * Real.sqrt (1 - ρ ^ 2) := by
  intro σS σF ρ hstar
  obtain ⟨e1, e2, e3⟩ := hedge_facts dS dF hS hF hσF
  have hq := hedge_var_quad dS dF hS hF
  have hσS : 0 ≤ σS := Real.sqrt_nonneg _
  have hρ : ρ * σS * σF = cov[dS, dF; P] := e3
  have hh : hstar = ρ * σS / σF := rfl
  have e1' : σS ^ 2 = Var[dS; P] := e1
  have e2' : σF ^ 2 = Var[dF; P] := e2
  have hσF' : 0 < σF := hσF
  clear e1 e2 e3 hσF
  clear_value σS σF ρ hstar
  have hvF : 0 < Var[dF; P] := by rw [← e2']; positivity
  have hc : cov[dS, dF; P] = hstar * Var[dF; P] := by
    rw [hh, ← e2', ← hρ]; field_simp
  refine ⟨?_, ?_, ?_⟩
  · rw [hc, ← e2']; field_simp
  · intro h hne
    rw [hq, hq, hc]
    have : 0 < Var[dF; P] * (h - hstar) ^ 2 :=
      mul_pos hvF (sq_pos_of_ne_zero (sub_ne_zero.mpr hne))
    nlinarith
  · rw [hq, hc]
    have : Var[dS; P] - 2 * hstar * (hstar * Var[dF; P]) + hstar ^ 2 * Var[dF; P]
        = σS ^ 2 * (1 - ρ ^ 2) := by
      rw [← e1', ← e2', hh]; field_simp; ring
    rw [this, Real.sqrt_mul (sq_nonneg σS), Real.sqrt_sq hσS]

/-- Steps 1 and 2: the leftover variance is a quadratic in the hedge ratio, and completing the
square shows the cost of a wrong ratio. Under the same assumptions, for every hedge ratio `h`,
`Var(dS - h dF) = σ_S² - 2 h ρ σ_S σ_F + h² σ_F²`, and this equals
`σ_F² (h - h*)² + σ_S² (1 - ρ²)`: the basis-risk floor plus a penalty growing with the square
of the miss. -/
theorem hedged_variance_complete_square {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω}
    [IsProbabilityMeasure P] (dS dF : Ω → ℝ) (hS : MemLp dS 2 P) (hF : MemLp dF 2 P)
    (hσF : 0 < Real.sqrt Var[dF; P]) :
    let σS := Real.sqrt Var[dS; P]
    let σF := Real.sqrt Var[dF; P]
    let ρ := cov[dS, dF; P] / (σS * σF)
    let hstar := ρ * σS / σF
    ∀ h : ℝ,
      Var[fun ω => dS ω - h * dF ω; P] = σS ^ 2 - 2 * h * ρ * σS * σF + h ^ 2 * σF ^ 2 ∧
      Var[fun ω => dS ω - h * dF ω; P] = σF ^ 2 * (h - hstar) ^ 2 + σS ^ 2 * (1 - ρ ^ 2) := by
  intro σS σF ρ hstar h
  obtain ⟨e1, e2, e3⟩ := hedge_facts dS dF hS hF hσF
  have hq := hedge_var_quad dS dF hS hF h
  have hρ : ρ * σS * σF = cov[dS, dF; P] := e3
  have hh : hstar = ρ * σS / σF := rfl
  have e1' : σS ^ 2 = Var[dS; P] := e1
  have e2' : σF ^ 2 = Var[dF; P] := e2
  have hσF' : σF ≠ 0 := hσF.ne'
  clear e1 e2 e3 hσF
  clear_value σS σF ρ hstar
  refine ⟨?_, ?_⟩
  · rw [hq, ← e1', ← e2', ← hρ]; ring
  · rw [hq, ← e1', ← e2', ← hρ, hh]; field_simp; ring

/-- Step 3: the best ratio is a regression slope. Take `n` past quarters of fuel changes `s`
and futures changes `f`, with the futures changes not all equal. For a slope `b`, the best
intercept `a` leaves a sum of squared misses `Σ (s - a - b f)²` equal to the summed squared
deviations of the hedged change `s - b f` from its average, so fitting a line by least squares
is minimising the hedged variance on the data. And the slope
`b̂ = Σ (f - f̄)(s - s̄) / Σ (f - f̄)²` (sample covariance over sample variance) leaves
strictly less hedged variance on the data than any other slope. -/
theorem least_squares_slope_is_min_variance_hedge (n : ℕ) (s f : Fin n → ℝ)
    (hf : ∃ i j, f i ≠ f j) :
    let sbar := (∑ i, s i) / n
    let fbar := (∑ i, f i) / n
    let hedgedSS := fun b : ℝ => ∑ i, (s i - b * f i - (∑ j, (s j - b * f j)) / n) ^ 2
    let bhat := (∑ i, (f i - fbar) * (s i - sbar)) / ∑ i, (f i - fbar) ^ 2
    (∀ a b : ℝ, hedgedSS b ≤ ∑ i, (s i - a - b * f i) ^ 2) ∧
    (∀ b : ℝ, b ≠ bhat → hedgedSS bhat < hedgedSS b) := by
  intro sbar fbar hedgedSS bhat
  obtain ⟨i0, j0, hij⟩ := hf
  have hn : (n : ℝ) ≠ 0 := by
    have : 0 < n := Fin.pos i0
    exact_mod_cast this.ne'
  have hsb : sbar = (∑ i, s i) / n := rfl
  have hfb : fbar = (∑ i, f i) / n := rfl
  have key : ∀ b : ℝ, (∑ j, (s j - b * f j)) / n = sbar - b * fbar := by
    intro b
    rw [Finset.sum_sub_distrib, ← Finset.mul_sum, hsb, hfb]
    field_simp
  have hH : ∀ b : ℝ, hedgedSS b = ∑ i, (s i - b * f i - (sbar - b * fbar)) ^ 2 := by
    intro b
    show ∑ i, (s i - b * f i - (∑ j, (s j - b * f j)) / n) ^ 2 = _
    rw [key]
  have hbh : bhat = (∑ i, (f i - fbar) * (s i - sbar)) / ∑ i, (f i - fbar) ^ 2 := rfl
  clear_value sbar fbar hedgedSS bhat
  have hcs : ∑ i, (s i - sbar) = 0 := by
    rw [Finset.sum_sub_distrib, hsb]; simp; field_simp; ring
  have hcf : ∑ i, (f i - fbar) = 0 := by
    rw [Finset.sum_sub_distrib, hfb]; simp; field_simp; ring
  refine ⟨?_, ?_⟩
  · intro a b
    rw [hH]
    have e : ∀ i, (s i - a - b * f i) ^ 2 = (s i - b * f i - (sbar - b * fbar)) ^ 2
        + (2 * (sbar - b * fbar - a) * (s i - sbar) - 2 * (sbar - b * fbar - a) * b * (f i - fbar))
        + (sbar - b * fbar - a) ^ 2 := by
      intro i; ring
    simp_rw [e]
    rw [Finset.sum_add_distrib, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
      ← Finset.mul_sum, hcs, hcf]
    have : 0 ≤ ∑ _i : Fin n, (sbar - b * fbar - a) ^ 2 :=
      Finset.sum_nonneg (fun _ _ => sq_nonneg _)
    linarith
  · have hpos : 0 < ∑ i, (f i - fbar) ^ 2 := by
      have hnn : 0 ≤ ∑ i, (f i - fbar) ^ 2 := Finset.sum_nonneg (fun _ _ => sq_nonneg _)
      rcases hnn.lt_or_eq with h | h
      · exact h
      · exfalso
        have hz := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => sq_nonneg (f i - fbar))).mp h.symm
        have a1 : f i0 = fbar := by
          have := hz i0 (Finset.mem_univ _); nlinarith [sq_nonneg (f i0 - fbar)]
        have a2 : f j0 = fbar := by
          have := hz j0 (Finset.mem_univ _); nlinarith [sq_nonneg (f j0 - fbar)]
        exact hij (a1.trans a2.symm)
    have expand : ∀ b : ℝ, hedgedSS b = ∑ i, (s i - sbar) ^ 2
        - 2 * b * ∑ i, (f i - fbar) * (s i - sbar) + b ^ 2 * ∑ i, (f i - fbar) ^ 2 := by
      intro b
      rw [hH]
      have e : ∀ i, (s i - b * f i - (sbar - b * fbar)) ^ 2 = (s i - sbar) ^ 2
          - 2 * b * ((f i - fbar) * (s i - sbar)) + b ^ 2 * (f i - fbar) ^ 2 := by
        intro i; ring
      simp_rw [e]
      rw [Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum, ← Finset.mul_sum]
    intro b hb
    rw [expand, expand]
    have hbs : bhat * ∑ i, (f i - fbar) ^ 2 = ∑ i, (f i - fbar) * (s i - sbar) := by
      rw [hbh]; field_simp
    have : 0 < (∑ i, (f i - fbar) ^ 2) * (b - bhat) ^ 2 :=
      mul_pos hpos (sq_pos_of_ne_zero (sub_ne_zero.mpr hb))
    rw [← hbs]
    nlinarith

/-! Worked numbers from the card, as exact fractions: σ_S = 0.18, σ_F = 0.20, ρ = 0.943,
Q = 2,000,000 gallons, one contract L = 42,000 gallons. -/

-- Covariance ρ σ_S σ_F = 0.033948.
example : (943 / 1000 : ℚ) * (18 / 100) * (20 / 100) = 33948 / 1000000 := by norm_num

-- Hedge ratio: 0.033948 / 0.04 = 0.8487, the same as ρ σ_S / σ_F.
example : (33948 / 1000000 : ℚ) / (20 / 100) ^ 2 = 8487 / 10000 ∧
    (943 / 1000 : ℚ) * (18 / 100) / (20 / 100) = 8487 / 10000 := by norm_num

-- 1 - ρ² = 1 - 0.889249 = 0.110751.
example : (943 / 1000 : ℚ) ^ 2 = 889249 / 1000000 ∧
    1 - (943 / 1000 : ℚ) ^ 2 = 110751 / 1000000 := by norm_num

-- Contracts: 0.8487 × 2,000,000 / 42,000 = 40.41..., so 40 whole contracts.
example : (40 : ℚ) < 8487 / 10000 * 2000000 / 42000 ∧
    (8487 / 10000 : ℚ) * 2000000 / 42000 < 81 / 2 := by norm_num

-- Ratio actually held: 40 × 42,000 / 2,000,000 = 0.84.
example : (40 : ℚ) * 42000 / 2000000 = 21 / 25 := by norm_num

-- Unhedged uncertainty in dollars: 0.18 × 2,000,000 = 360,000.
example : (18 / 100 : ℚ) * 2000000 = 360000 := by norm_num

-- Variance at h = 1 (the one-for-one hedge, pure basis risk):
-- 0.0324 - 2 × 0.033948 + 0.04 = 0.004504, which is also σ_S²(1-ρ²) + σ_F²(1-h*)².
example : (18 / 100 : ℚ) ^ 2 - 2 * 1 * (33948 / 1000000) + 1 ^ 2 * (20 / 100) ^ 2 = 4504 / 1000000 ∧
    (18 / 100 : ℚ) ^ 2 * (110751 / 1000000) + (20 / 100) ^ 2 * (1 - 8487 / 10000) ^ 2
      = 4504 / 1000000 := by norm_num

-- One quarter traced: futures 2.50 → 2.90 pay 0.84 × 0.40 = 0.336; net cost 2.75 - 0.336 = 2.414,
-- 1.4 cents above today's 2.40.
example : (21 / 25 : ℚ) * (290 / 100 - 250 / 100) = 336 / 1000 ∧
    (275 / 100 : ℚ) - 336 / 1000 = 2414 / 1000 ∧ (2414 / 1000 : ℚ) - 240 / 100 = 14 / 1000 := by
  norm_num

-- Beta hedge: 1.2 × 10,000,000 / 250,000 = 48 contracts.
example : (6 / 5 : ℚ) * 10000000 / 250000 = 48 := by norm_num

-- Try changing: ρ = 0.8 gives ratio 0.72; σ_F = 0.40 gives ratio 0.42435; 48 contracts hold 1.008.
example : (8 / 10 : ℚ) * (18 / 100) / (20 / 100) = 72 / 100 ∧
    (943 / 1000 : ℚ) * (18 / 100) / (40 / 100) = 42435 / 100000 ∧
    (48 : ℚ) * 42000 / 2000000 = 1008 / 1000 := by norm_num

#print axioms hedge_var_quad
#print axioms hedge_cov_sq_le
#print axioms hedge_facts
#print axioms min_variance_hedge_ratio
#print axioms hedged_variance_complete_square
#print axioms least_squares_slope_is_min_variance_hedge
