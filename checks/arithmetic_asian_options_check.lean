-- Arithmetic Asian options: the geometric-twin control variate is unbiased for every slope and at the best slope leaves (1 - ρ²) of the plain variance, the arithmetic payoff is squeezed path by path between the geometric payoff and that payoff plus A - G, and a seasoned Asian call is m/n of a fresh one struck at K*.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Analysis.MeanInequalities
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory ProbabilityTheory

lemma cv_var_formula
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X Y : Ω → ℝ) (hX : MemLp X 2 μ) (hY : MemLp Y 2 μ) (b : ℝ) :
    Var[fun ω => X ω - b * (Y ω - ∫ ω', Y ω' ∂μ); μ]
      = Var[X; μ] - 2 * b * cov[X, Y; μ] + b ^ 2 * Var[Y; μ] := by
  have h1 : (fun ω => X ω - b * (Y ω - ∫ ω', Y ω' ∂μ))
      = fun ω => (X ω - b * Y ω) + b * ∫ ω', Y ω' ∂μ := by
    funext ω; ring
  have hbY : MemLp (fun ω => b * Y ω) 2 μ := hY.const_mul b
  have hm : AEStronglyMeasurable (fun ω => X ω - b * Y ω) μ := (hX.sub hbY).aestronglyMeasurable
  rw [h1, variance_add_const (X := fun ω => X ω - b * Y ω) hm,
    variance_fun_sub hX hbY, variance_const_mul, covariance_const_mul_right]
  ring

#print axioms cv_var_formula

/-- The geometric twin as a control variate. Let `X` be one path's discounted arithmetic
payoff and `Y` the geometric twin's on the same path, whose exact price `C_G = E[Y]` is known.
The corrected payoff `X - β (Y - C_G)` has the same average as `X` for every slope `β`, so the
correction cannot bias the price. With the slope `β = cov(X, Y) / var(Y)` its variance is
`(1 - ρ²) var(X)`, where `ρ` is the correlation of `X` and `Y`, and no other slope does better. -/
theorem control_variate_unbiased_and_cuts_variance
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X Y : Ω → ℝ) (hX : MemLp X 2 μ) (hY : MemLp Y 2 μ) :
    (∀ β : ℝ, ∫ ω, (X ω - β * (Y ω - ∫ ω', Y ω' ∂μ)) ∂μ = ∫ ω, X ω ∂μ) ∧
    (Var[fun ω => X ω - (cov[X, Y; μ] / Var[Y; μ]) * (Y ω - ∫ ω', Y ω' ∂μ); μ]
        = (1 - (cov[X, Y; μ] / Real.sqrt (Var[X; μ] * Var[Y; μ])) ^ 2) * Var[X; μ]) ∧
    (∀ b : ℝ, Var[fun ω => X ω - (cov[X, Y; μ] / Var[Y; μ]) * (Y ω - ∫ ω', Y ω' ∂μ); μ]
        ≤ Var[fun ω => X ω - b * (Y ω - ∫ ω', Y ω' ∂μ); μ]) := by
  have hXi : Integrable X μ := hX.integrable (by norm_num)
  have hYi : Integrable Y μ := hY.integrable (by norm_num)
  have hF := cv_var_formula μ X Y hX hY
  have hnn : ∀ b : ℝ, 0 ≤ Var[X; μ] - 2 * b * cov[X, Y; μ] + b ^ 2 * Var[Y; μ] := by
    intro b; rw [← hF b]; exact variance_nonneg _ _
  set V := Var[X; μ] with hV
  set W := Var[Y; μ] with hW
  set c := cov[X, Y; μ] with hc
  have hV0 : 0 ≤ V := variance_nonneg _ _
  have hW0 : 0 ≤ W := variance_nonneg _ _
  -- If W = 0 then c = 0.
  have hcW : W = 0 → c = 0 := by
    intro h
    by_contra hne
    have := hnn ((V + 1) / (2 * c))
    rw [h] at this
    have e : 2 * ((V + 1) / (2 * c)) * c = V + 1 := by field_simp
    rw [e] at this
    linarith
  -- Cauchy–Schwarz from nonnegativity.
  have hCS : c ^ 2 ≤ V * W := by
    rcases hW0.lt_or_eq with hpos | h0
    · have := hnn (c / W)
      have e : V - 2 * (c / W) * c + (c / W) ^ 2 * W = (V * W - c ^ 2) / W := by
        field_simp; ring
      rw [e] at this
      have := (div_nonneg_iff.mp this)
      rcases this with ⟨h1, _⟩ | ⟨_, h2⟩
      · linarith
      · linarith
    · rw [hcW h0.symm, ← h0]; simp
  refine ⟨?_, ?_, ?_⟩
  · intro β
    have h1 : Integrable (fun ω => β * (Y ω - ∫ ω', Y ω' ∂μ)) μ :=
      (hYi.sub (integrable_const _)).const_mul β
    rw [integral_sub hXi h1, integral_const_mul, integral_sub hYi (integrable_const _)]
    simp
  · rw [hF]
    rcases hW0.lt_or_eq with hpos | h0
    · rcases hV0.lt_or_eq with hVpos | hV00
      · rw [show (c / Real.sqrt (V * W)) ^ 2 = c ^ 2 / (V * W) by
          rw [div_pow, Real.sq_sqrt (mul_nonneg hV0 hW0)]]
        field_simp
        ring
      · have : c = 0 := by
          rw [← hV00] at hCS; simp at hCS; nlinarith [sq_nonneg c]
        rw [this, ← hV00]; simp
    · rw [hcW h0.symm, ← h0]; simp
  · intro b
    rw [hF, hF]
    rcases hW0.lt_or_eq with hpos | h0
    · have e : V - 2 * (c / W) * c + (c / W) ^ 2 * W = V - c ^ 2 / W := by
        field_simp; ring
      rw [e]
      have : 2 * b * c - b ^ 2 * W ≤ c ^ 2 / W := by
        rw [le_div_iff₀ hpos]; nlinarith [sq_nonneg (b * W - c)]
      linarith
    · rw [hcW h0.symm, ← h0]; simp

/-- Floor and ceiling, path by path. For any `n ≥ 1` positive fixings and any strike `K`, with
`A` the arithmetic average and `G` the geometric average, the arithmetic call payoff is never
below the geometric one, and exceeds it by at most `A - G`. Discounting and averaging over
futures gives `C_G ≤ C_A ≤ C_G + e^{-rT} (M₁ - F_G)`. -/
theorem asian_payoff_between_geometric_floor_and_ceiling
    (n : ℕ) (hn : 0 < n) (S : Fin n → ℝ) (hS : ∀ i, 0 < S i) (K : ℝ) :
    max ((∏ i, S i ^ ((1 : ℝ) / n)) - K) 0 ≤ max ((∑ i, S i) / n - K) 0 ∧
    max ((∑ i, S i) / n - K) 0 ≤
      max ((∏ i, S i ^ ((1 : ℝ) / n)) - K) 0 + ((∑ i, S i) / n - ∏ i, S i ^ ((1 : ℝ) / n)) := by
  have hn' : (0 : ℝ) < n := by exact_mod_cast hn
  have hGA : (∏ i, S i ^ ((1 : ℝ) / n)) ≤ (∑ i, S i) / n := by
    have := Real.geom_mean_le_arith_mean_weighted (Finset.univ : Finset (Fin n))
      (fun _ => (1 : ℝ) / n) S (fun _ _ => by positivity)
      (by simp [Finset.card_univ]; field_simp) (fun i _ => (hS i).le)
    simpa [Finset.mul_sum, div_eq_inv_mul, Finset.sum_div] using this
  constructor
  · exact max_le_max (by linarith) le_rfl
  · apply max_le
    · have := le_max_left ((∏ i, S i ^ ((1 : ℝ) / n)) - K) 0
      linarith
    · have := le_max_right ((∏ i, S i ^ ((1 : ℝ) / n)) - K) 0
      linarith

/-- A seasoned Asian call. With `k` fixings already in (values `a`) and `m ≥ 1` still to come
(values `b`), so `n = k + m`, the payoff on the whole average is `m/n` times a fresh Asian
payoff on the remaining fixings struck at `K* = (n K - sum of the fixings in) / m`.
If `K* ≤ 0` and prices are positive, the call is sure to pay: its payoff is `A - K`. -/
theorem seasoned_asian_is_scaled_fresh_asian
    (k m : ℕ) (hm : 0 < m) (a : Fin k → ℝ) (b : Fin m → ℝ) (hb : ∀ j, 0 < b j) (K : ℝ) :
    max ((∑ i, a i + ∑ j, b j) / ((k + m : ℕ) : ℝ) - K) 0 =
      ((m : ℝ) / ((k + m : ℕ) : ℝ)) *
        max ((∑ j, b j) / m - (((k + m : ℕ) : ℝ) * K - ∑ i, a i) / m) 0 ∧
    ((((k + m : ℕ) : ℝ) * K - ∑ i, a i) / m ≤ 0 →
      max ((∑ i, a i + ∑ j, b j) / ((k + m : ℕ) : ℝ) - K) 0
        = (∑ i, a i + ∑ j, b j) / ((k + m : ℕ) : ℝ) - K) := by
  have hm' : (0 : ℝ) < m := by exact_mod_cast hm
  have hn' : (0 : ℝ) < ((k + m : ℕ) : ℝ) := by
    have : 0 < k + m := by omega
    exact_mod_cast this
  have key : (∑ i, a i + ∑ j, b j) / ((k + m : ℕ) : ℝ) - K
      = ((m : ℝ) / ((k + m : ℕ) : ℝ)) *
        ((∑ j, b j) / m - (((k + m : ℕ) : ℝ) * K - ∑ i, a i) / m) := by
    field_simp
    ring
  have hB : 0 < ∑ j, b j := by
    have : Nonempty (Fin m) := ⟨⟨0, hm⟩⟩
    exact Finset.sum_pos (fun j _ => hb j) Finset.univ_nonempty
  constructor
  · rw [key, mul_max_of_nonneg _ _ (by positivity), mul_zero]
  · intro hK
    have hpos : 0 < (∑ j, b j) / m - (((k + m : ℕ) : ℝ) * K - ∑ i, a i) / m := by
      have : 0 < (∑ j, b j) / m := by positivity
      linarith
    have : 0 < (∑ i, a i + ∑ j, b j) / ((k + m : ℕ) : ℝ) - K := by
      rw [key]; positivity
    exact max_eq_left this.le

-- Halfway through the 52 fixings, dropping the m/n weight overprices by n/m = 2.
example : (52 : ℚ) / (52 - 26) = 2 := by norm_num

#print axioms control_variate_unbiased_and_cuts_variance
#print axioms asian_payoff_between_geometric_floor_and_ceiling
#print axioms seasoned_asian_is_scaled_fresh_asian
