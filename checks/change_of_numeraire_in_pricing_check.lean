-- Changing the unit of account: a price counted in any strictly positive unit whose ratio to the bank account is a fair bet equals the average of the payoff in that unit under the bank's odds multiplied by the tilt, and those tilted odds are a probability equivalent to the bank's.
import Mathlib.MeasureTheory.Integral.Bochner.ContinuousLinearMap
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- Change of unit of account. Let `P` be the bank's odds on the endings `Ω`, with the bank
account worth `B₀ > 0` today and `B ω > 0` at the end, and let the chosen unit be worth
`U₀ > 0` today and `U ω > 0` on every ending. Suppose the unit measured against the bank is a
genuine fair bet under the bank's odds: `U / B` has a finite average equal to `U₀ / B₀`.
If the contract's dollar price is given by the bank rule `V₀ = B₀ · E[V / B]`, then its price
counted in units, `V₀ / U₀`, equals the average of its payoff counted in units, `V / U`, taken
with the bank's weights multiplied by the tilt `L = (U / U₀) / (B / B₀)`. -/
theorem price_in_units_eq_tilted_average
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (B U V : Ω → ℝ) (B₀ U₀ V₀ : ℝ)
    (hB₀ : 0 < B₀) (hB : ∀ ω, 0 < B ω)
    (hU₀ : 0 < U₀) (hU : ∀ ω, 0 < U ω)
    (hfair_int : Integrable (fun ω => U ω / B ω) P)
    (hfair : ∫ ω, U ω / B ω ∂P = U₀ / B₀)
    (hV₀ : V₀ = B₀ * ∫ ω, V ω / B ω ∂P) :
    V₀ / U₀ =
      ∫ ω, V ω / U ω ∂(P.withDensity (fun ω => ENNReal.ofReal ((U ω / U₀) / (B ω / B₀)))) := by
  have hρ : ∀ ω, (U ω / U₀) / (B ω / B₀) = (B₀ / U₀) * (U ω / B ω) := by
    intro ω
    have := hB ω
    field_simp
  have hmeas : AEMeasurable (fun ω => ENNReal.ofReal ((U ω / U₀) / (B ω / B₀))) P := by
    simp_rw [hρ]
    exact ENNReal.measurable_ofReal.comp_aemeasurable
      (hfair_int.aemeasurable.const_mul (B₀ / U₀))
  rw [integral_withDensity_eq_integral_toReal_smul₀ hmeas
    (Filter.Eventually.of_forall (fun ω => ENNReal.ofReal_lt_top))]
  have hpt : ∀ ω, (ENNReal.ofReal ((U ω / U₀) / (B ω / B₀))).toReal • (V ω / U ω)
      = (B₀ / U₀) * (V ω / B ω) := by
    intro ω
    have h1 := hB ω
    have h2 := hU ω
    rw [ENNReal.toReal_ofReal (by positivity), smul_eq_mul]
    field_simp
  simp_rw [hpt]
  rw [integral_const_mul, hV₀]
  field_simp

/-- The tilted weights are odds. Under the same conditions on the bank account and the unit,
multiplying the bank's weight on every ending by the tilt `L = (U / U₀) / (B / B₀)` gives a
probability (the weights add to one), and it is equivalent to the bank's odds: an ending set
is impossible under one exactly when it is impossible under the other. -/
theorem tilted_odds_are_equivalent_probability
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (B U : Ω → ℝ) (B₀ U₀ : ℝ)
    (hB₀ : 0 < B₀) (hB : ∀ ω, 0 < B ω)
    (hU₀ : 0 < U₀) (hU : ∀ ω, 0 < U ω)
    (hfair_int : Integrable (fun ω => U ω / B ω) P)
    (hfair : ∫ ω, U ω / B ω ∂P = U₀ / B₀) :
    IsProbabilityMeasure (P.withDensity (fun ω => ENNReal.ofReal ((U ω / U₀) / (B ω / B₀)))) ∧
      P.withDensity (fun ω => ENNReal.ofReal ((U ω / U₀) / (B ω / B₀))) ≪ P ∧
      P ≪ P.withDensity (fun ω => ENNReal.ofReal ((U ω / U₀) / (B ω / B₀))) := by
  have hρ : ∀ ω, (U ω / U₀) / (B ω / B₀) = (B₀ / U₀) * (U ω / B ω) := by
    intro ω
    have := hB ω
    field_simp
  have hmeas : AEMeasurable (fun ω => ENNReal.ofReal ((U ω / U₀) / (B ω / B₀))) P := by
    simp_rw [hρ]
    exact ENNReal.measurable_ofReal.comp_aemeasurable
      (hfair_int.aemeasurable.const_mul (B₀ / U₀))
  refine ⟨⟨?_⟩, withDensity_absolutelyContinuous _ _, ?_⟩
  · rw [withDensity_apply _ MeasurableSet.univ, Measure.restrict_univ]
    simp_rw [hρ]
    rw [← ofReal_integral_eq_lintegral_ofReal (hfair_int.const_mul (B₀ / U₀))
      (Filter.Eventually.of_forall (fun ω => by
        have := hB ω
        have := hU ω
        simp only [Pi.zero_apply]
        positivity)),
      integral_const_mul, hfair]
    rw [show B₀ / U₀ * (U₀ / B₀) = 1 by field_simp]
    simp
  · refine withDensity_absolutelyContinuous' hmeas (Filter.Eventually.of_forall (fun ω => ?_))
    have := hB ω
    have := hU ω
    simp only [ne_eq, ENNReal.ofReal_eq_zero, not_le]
    positivity

/-- The bond unit. Take as unit the bond that pays one dollar on the payment date, worth
`P₀ > 0` today and exactly `1` on every ending, with the bond against the bank a fair bet.
Then the contract's dollar price is the bond's price today times the plain, undiscounted
average of the payoff under the bond's own (forward) odds: `V₀ = P₀ · E^T[V]`. -/
theorem price_eq_bond_times_forward_average
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (B V : Ω → ℝ) (B₀ P₀ V₀ : ℝ)
    (hB₀ : 0 < B₀) (hB : ∀ ω, 0 < B ω) (hP₀ : 0 < P₀)
    (hfair_int : Integrable (fun ω => 1 / B ω) P)
    (hfair : ∫ ω, 1 / B ω ∂P = P₀ / B₀)
    (hV₀ : V₀ = B₀ * ∫ ω, V ω / B ω ∂P) :
    V₀ = P₀ * ∫ ω, V ω ∂(P.withDensity (fun ω => ENNReal.ofReal ((1 / P₀) / (B ω / B₀)))) := by
  have h := price_in_units_eq_tilted_average P B (fun _ => 1) V B₀ P₀ V₀ hB₀ hB hP₀
    (fun _ => one_pos) hfair_int hfair hV₀
  simp only [div_one] at h
  rw [← h]
  field_simp

-- The card's two-outcome toy: bank unit 2 → 2, asset 3 → 2 or 4, contract pays 0 or 12,
-- bank weights 1/2 and 1/2.
-- In dollars, with the bank's weights, the bill is 6.
example : (2 : ℚ) * ((1 / 2) * (0 / 2) + (1 / 2) * (12 / 2)) = 6 := by norm_num
-- The hedge: 6 asset units less 6 borrowed bank units costs 6 and pays 0 or 12.
example : (6 : ℚ) * 3 - 6 * 2 = 6 ∧ (6 : ℚ) * 2 - 6 * 2 = 0 ∧ (6 : ℚ) * 4 - 6 * 2 = 12 := by
  norm_num
-- The asset under the bank's weights is a fair bet against the bank: average of 2/2 and 4/2 is 3/2.
example : (1 / 2 : ℚ) * (2 / 2) + (1 / 2) * (4 / 2) = 3 / 2 := by norm_num
-- The two tilts are 2/3 and 4/3.
example : ((2 : ℚ) / 3) / (2 / 2) = 2 / 3 ∧ ((4 : ℚ) / 3) / (2 / 2) = 4 / 3 := by norm_num
-- The asset's own weights are 1/3 and 2/3, and they add to one.
example : (1 / 2 : ℚ) * (2 / 3) = 1 / 3 ∧ (1 / 2 : ℚ) * (4 / 3) = 2 / 3 ∧
    (1 / 3 : ℚ) + 2 / 3 = 1 := by norm_num
-- In asset units with the asset's weights: 2 units at 3 dollars, the same bill of 6.
example : (1 / 3 : ℚ) * (0 / 2) + (2 / 3) * (12 / 4) = 2 ∧
    (3 : ℚ) * ((1 / 3) * (0 / 2) + (2 / 3) * (12 / 4)) = 6 := by norm_num
-- Asset units with the old bank weights kept: the wrong bill, 9/2.
example : (3 : ℚ) * ((1 / 2) * (0 / 2) + (1 / 2) * (12 / 4)) = 9 / 2 := by norm_num

#print axioms price_in_units_eq_tilted_average
#print axioms tilted_odds_are_equivalent_probability
#print axioms price_eq_bond_times_forward_average
