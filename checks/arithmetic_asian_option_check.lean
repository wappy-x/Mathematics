-- The Asian option desks trade: the arithmetic Asian call is priced between its geometric twin and that twin plus the discounted gap between the two averages' forwards, and the geometric twin used as a control variate leaves the price unbiased and the variance at (1 - ρ²) of the plain variance.
import Mathlib.Analysis.MeanInequalities
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Moments.Covariance

open MeasureTheory ProbabilityTheory

/-- AM-GM for positive fixings: the geometric average is at most the arithmetic one. -/
theorem asian_helper_geom_le_arith (n : ℕ) (hn : n ≠ 0) (P : Fin n → ℝ) (hpos : ∀ i, 0 < P i) :
    (∏ i, P i) ^ ((1 : ℝ) / n) ≤ (∑ i, P i) / n := by
  have h := Real.geom_mean_le_arith_mean (Finset.univ : Finset (Fin n)) (fun _ => (1 : ℝ)) P
    (fun _ _ => zero_le_one) (by simp [Nat.pos_of_ne_zero hn]) (fun i _ => (hpos i).le)
  simpa [one_div] using h

/-- The geometric average of positive fixings is nonnegative. -/
theorem asian_helper_geom_nonneg (n : ℕ) (P : Fin n → ℝ) (hpos : ∀ i, 0 < P i) :
    0 ≤ (∏ i, P i) ^ ((1 : ℝ) / n) :=
  Real.rpow_nonneg (Finset.prod_nonneg fun i _ => (hpos i).le) _

/-- Variance of the control-variate payoff, expanded. -/
theorem asian_helper_cv_variance
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X Y : Ω → ℝ) (hX : MemLp X 2 μ) (hY : MemLp Y 2 μ) (C β : ℝ) :
    Var[fun ω => X ω - β * (Y ω - C); μ]
      = Var[X; μ] - 2 * β * cov[X, Y; μ] + β ^ 2 * Var[Y; μ] := by
  have hZ : MemLp (fun ω => β * (Y ω - C)) 2 μ := (hY.sub (memLp_const C)).const_mul β
  rw [variance_fun_sub hX hZ, covariance_const_mul_right,
    covariance_sub_const_right (hY.integrable one_le_two), variance_const_mul,
    variance_sub_const hY.aestronglyMeasurable]
  ring


/-- The card's floor and ceiling (Step 6). Take `n` fixings, each a positive price
(lognormal fixings are positive) with a finite mean in the pricing world `μ`.
Let `A` be their arithmetic average and `G` their geometric average (the `n`-th root of
the product). Then the arithmetic Asian call `C_A = e^{-rT} E[max(A - K, 0)]` is never
below the geometric twin `C_G = e^{-rT} E[max(G - K, 0)]`, and never above
`C_G + e^{-rT} (M₁ - F_G)`, where `M₁ = E[A]` and `F_G = E[G]` are the two averages'
forwards. -/
theorem arithmetic_asian_between_geometric_floor_and_ceiling
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (n : ℕ) (hn : n ≠ 0) (P : Fin n → Ω → ℝ)
    (hpos : ∀ i ω, 0 < P i ω) (hint : ∀ i, Integrable (P i) μ)
    (K r T : ℝ) :
    let A : Ω → ℝ := fun ω => (∑ i, P i ω) / n
    let G : Ω → ℝ := fun ω => (∏ i, P i ω) ^ ((1 : ℝ) / n)
    let C_A := Real.exp (-r * T) * ∫ ω, max (A ω - K) 0 ∂μ
    let C_G := Real.exp (-r * T) * ∫ ω, max (G ω - K) 0 ∂μ
    let M₁ := ∫ ω, A ω ∂μ
    let F_G := ∫ ω, G ω ∂μ
    C_G ≤ C_A ∧ C_A ≤ C_G + Real.exp (-r * T) * (M₁ - F_G) := by
  intro A G C_A C_G M₁ F_G
  have hGA : ∀ ω, G ω ≤ A ω := fun ω => asian_helper_geom_le_arith n hn (fun i => P i ω) (hpos · ω)
  have hG0 : ∀ ω, 0 ≤ G ω := fun ω => asian_helper_geom_nonneg n (fun i => P i ω) (hpos · ω)
  have hAint : Integrable A μ := by
    have : Integrable (fun ω => ∑ i, P i ω) μ := integrable_finsetSum _ fun i _ => hint i
    exact this.div_const _
  have hGmeas : AEStronglyMeasurable G μ := by
    have : AEMeasurable G μ :=
      (Finset.univ.aemeasurable_fun_prod fun i _ => (hint i).aemeasurable).pow_const _
    exact this.aestronglyMeasurable
  have hGint : Integrable G μ := by
    refine hAint.mono' hGmeas (Filter.Eventually.of_forall fun ω => ?_)
    rw [Real.norm_eq_abs, abs_of_nonneg (hG0 ω)]
    exact hGA ω
  have hGK : Integrable (fun ω => max (G ω - K) 0) μ := (hGint.sub (integrable_const K)).pos_part
  have hAK : Integrable (fun ω => max (A ω - K) 0) μ := (hAint.sub (integrable_const K)).pos_part
  have he := (Real.exp_pos (-r * T)).le
  constructor
  · refine mul_le_mul_of_nonneg_left (integral_mono hGK hAK fun ω => ?_) he
    exact max_le_max (by linarith [hGA ω]) le_rfl
  · have hle : ∫ ω, max (A ω - K) 0 ∂μ ≤ ∫ ω, (max (G ω - K) 0 + (A ω - G ω)) ∂μ := by
      refine integral_mono hAK (hGK.add (hAint.sub hGint)) fun ω => ?_
      have := hGA ω
      exact max_le (by linarith [le_max_left (G ω - K) 0]) (by linarith [le_max_right (G ω - K) 0])
    have hsub : Integrable (fun ω => A ω - G ω) μ := hAint.sub hGint
    rw [integral_add hGK hsub, integral_sub hAint hGint] at hle
    have := mul_le_mul_of_nonneg_left hle he
    show Real.exp (-r * T) * ∫ ω, max (A ω - K) 0 ∂μ ≤
      Real.exp (-r * T) * ∫ ω, max (G ω - K) 0 ∂μ + Real.exp (-r * T) * ((∫ ω, A ω ∂μ) - ∫ ω, G ω ∂μ)
    linarith

/-- The same floor and ceiling on one simulated path: for positive fixings, the
arithmetic payoff is never below the geometric payoff, and the gap between the two
payoffs is never more than the gap between the two averages, `A - G`. -/
theorem arithmetic_payoff_between_geometric_payoff_and_gap
    (n : ℕ) (hn : n ≠ 0) (P : Fin n → ℝ) (hpos : ∀ i, 0 < P i) (K : ℝ) :
    let A := (∑ i, P i) / n
    let G := (∏ i, P i) ^ ((1 : ℝ) / n)
    max (G - K) 0 ≤ max (A - K) 0 ∧ max (A - K) 0 ≤ max (G - K) 0 + (A - G) := by
  intro A G
  have hGA : G ≤ A := asian_helper_geom_le_arith n hn P hpos
  constructor
  · exact max_le_max (by linarith) le_rfl
  · exact max_le (by linarith [le_max_left (G - K) 0]) (by linarith [le_max_right (G - K) 0])

/-- The control variate (Step 5). Let `X` and `Y` be the discounted arithmetic and
geometric payoffs on one path, with finite variances, `Y` not constant, and let
`C_G = E[Y]` be the twin's exact price. Then the corrected payoff
`X - β (Y - C_G)` has the same mean as `X` for every slope `β`; its variance is never
below `(1 - ρ²) var X`, where `ρ` is the correlation of `X` and `Y`; and the slope
`β = cov(X, Y) / var Y` reaches exactly `(1 - ρ²) var X`. -/
theorem control_variate_unbiased_and_leaves_one_minus_rho_sq
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X Y : Ω → ℝ) (hX : MemLp X 2 μ) (hY : MemLp Y 2 μ) (hvY : 0 < Var[Y; μ])
    (C_G : ℝ) (hCG : C_G = ∫ ω, Y ω ∂μ) :
    let ρ := cov[X, Y; μ] / Real.sqrt (Var[X; μ] * Var[Y; μ])
    let βstar := cov[X, Y; μ] / Var[Y; μ]
    (∀ β : ℝ, ∫ ω, (X ω - β * (Y ω - C_G)) ∂μ = ∫ ω, X ω ∂μ) ∧
    (∀ β : ℝ, (1 - ρ ^ 2) * Var[X; μ] ≤ Var[fun ω => X ω - β * (Y ω - C_G); μ]) ∧
    Var[fun ω => X ω - βstar * (Y ω - C_G); μ] = (1 - ρ ^ 2) * Var[X; μ] := by
  intro ρ βstar
  simp only [ρ, βstar]
  have hvar := asian_helper_cv_variance μ X Y hX hY C_G
  have hVX0 : 0 ≤ Var[X; μ] := variance_nonneg _ _
  have hint1 : ∀ β : ℝ, ∫ ω, (X ω - β * (Y ω - C_G)) ∂μ = ∫ ω, X ω ∂μ := by
    intro β
    have hYi := hY.integrable one_le_two
    have hXi := hX.integrable one_le_two
    have h1 : Integrable (fun ω => β * (Y ω - C_G)) μ := (hYi.sub (integrable_const C_G)).const_mul β
    have h2 : Integrable (fun _ : Ω => C_G) μ := integrable_const C_G
    rw [integral_sub hXi h1, integral_const_mul, integral_sub hYi h2, integral_const, ← hCG]
    simp
  clear ρ βstar
  generalize Var[X; μ] = VX at *
  generalize Var[Y; μ] = VY at *
  generalize cov[X, Y; μ] = c at *
  -- value at the best slope
  have hstar : Var[fun ω => X ω - c / VY * (Y ω - C_G); μ] = VX - c ^ 2 / VY := by
    rw [hvar]; field_simp; ring
  -- Cauchy–Schwarz from nonnegativity of that variance
  have hCS : c ^ 2 ≤ VX * VY := by
    have h0 : 0 ≤ VX - c ^ 2 / VY := hstar ▸ variance_nonneg _ _
    rw [sub_nonneg, div_le_iff₀ hvY] at h0
    exact h0
  have hrho : (1 - (c / Real.sqrt (VX * VY)) ^ 2) * VX = VX - c ^ 2 / VY := by
    rw [div_pow, Real.sq_sqrt (mul_nonneg hVX0 hvY.le)]
    rcases hVX0.eq_or_lt with h | h
    · rw [← h] at hCS ⊢
      have : c ^ 2 = 0 := le_antisymm (by simpa using hCS) (sq_nonneg _)
      rw [this]; simp
    · field_simp
  refine ⟨fun β => ?_, fun β => ?_, ?_⟩
  · exact hint1 β
  · rw [hrho, hvar]
    have key : VX - 2 * β * c + β ^ 2 * VY - (VX - c ^ 2 / VY) = (β * VY - c) ^ 2 / VY := by
      field_simp; ring
    have : 0 ≤ (β * VY - c) ^ 2 / VY := div_nonneg (sq_nonneg _) hvY.le
    linarith
  · rw [hstar, hrho]

-- Step 7: half the year gone, 26 fixings banked at an average of $80 against a
-- $100 strike on 52 fixings. The strike left for the rest is K* = 2 × 100 − 80 = 120.
example : (2 * 100 - 80 : ℕ) = 120 := by decide

-- The payoff is half of the remaining average's excess over K* = 120,
-- whatever the remaining 26 fixings average to.
example (R : ℝ) :
    max ((26 * 80 + 26 * R) / 52 - 100) 0 = (1 / 2) * max (R - 120) 0 := by
  rcases le_total R 120 with h | h
  · rw [max_eq_right (by linarith), max_eq_right (by linarith)]; ring
  · rw [max_eq_left (by linarith), max_eq_left (by linarith)]; ring

-- The mean square M₂ sums over all 52 × 52 ordered pairs of fixings.
example : 52 * 52 = 2704 := by norm_num

-- The payoff chart: an average of $120 against the $100 strike pays $20 a barrel,
-- and an average of $80 pays nothing.
example : max ((120 : ℤ) - 100) 0 = 20 ∧ max ((80 : ℤ) - 100) 0 = 0 := by decide

#print axioms asian_helper_geom_le_arith
#print axioms asian_helper_geom_nonneg
#print axioms asian_helper_cv_variance
#print axioms arithmetic_asian_between_geometric_floor_and_ceiling
#print axioms arithmetic_payoff_between_geometric_payoff_and_gap
#print axioms control_variate_unbiased_and_leaves_one_minus_rho_sq
