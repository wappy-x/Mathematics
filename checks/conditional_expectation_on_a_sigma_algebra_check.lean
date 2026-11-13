-- Conditional expectation on a sigma-algebra: for an integrable X and a sub-sigma-algebra G of a finite measure space, a G-measurable integrable forecast with the same integral as X on every event of G exists, and any two agree almost everywhere.
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- The conditional expectation of `X` given the information `G` (here the sub-sigma-algebra
`m ≤ m0`) is a forecast `M` that uses only that information (`M` is `G`-measurable), has a
finite average, and matches `X`'s total on every event `A` in `G`. Such a forecast always
exists when `X` has a finite average and `P` is a finite measure, and it is unique up to a
set of probability zero: any other forecast `L` passing both tests equals `M` almost
everywhere. -/
theorem conditional_expectation_exists_unique
    {Ω : Type*} {m m0 : MeasurableSpace Ω} (hm : m ≤ m0)
    (P : Measure[m0] Ω) [IsFiniteMeasure P]
    (X : Ω → ℝ) (hX : Integrable X P) :
    ∃ M : Ω → ℝ, Measurable[m] M ∧ Integrable M P ∧
      (∀ A, MeasurableSet[m] A → ∫ ω in A, M ω ∂P = ∫ ω in A, X ω ∂P) ∧
      ∀ L : Ω → ℝ, Measurable[m] L → Integrable L P →
        (∀ A, MeasurableSet[m] A → ∫ ω in A, L ω ∂P = ∫ ω in A, X ω ∂P) →
        L =ᵐ[P] M := by
  refine ⟨P[X | m], stronglyMeasurable_condExp.measurable, integrable_condExp,
    fun A hA => setIntegral_condExp hm hX hA, ?_⟩
  intro L hLm hLi hLX
  exact ae_eq_condExp_of_forall_setIntegral_eq hm hX
    (fun s _ _ => hLi.integrableOn) (fun s hs _ => hLX s hs)
    hLm.stronglyMeasurable.aestronglyMeasurable

/-- The partition rule comes back: if `C` is an atom of `G` (an event of `G` whose only
`G`-subevents are the empty set and `C` itself) with positive probability, then every
forecast `M` passing both tests is constant on `C`, equal to the total of `X` over `C`
divided by the probability of `C`. -/
theorem conditional_expectation_on_atom_eq_average
    {Ω : Type*} {m m0 : MeasurableSpace Ω} (hm : m ≤ m0)
    (P : Measure[m0] Ω) [IsFiniteMeasure P]
    (X : Ω → ℝ) (hX : Integrable X P)
    (M : Ω → ℝ) (hMm : Measurable[m] M) (hMi : Integrable M P)
    (hMX : ∀ A, MeasurableSet[m] A → ∫ ω in A, M ω ∂P = ∫ ω in A, X ω ∂P)
    (C : Set Ω) (hC : MeasurableSet[m] C)
    (hatom : ∀ B, MeasurableSet[m] B → B ⊆ C → B = ∅ ∨ B = C)
    (hpos : P C ≠ 0) :
    ∀ ω ∈ C, M ω = (∫ x in C, X x ∂P) / P.real C := by
  intro ω hω
  have hB : MeasurableSet[m] (C ∩ M ⁻¹' {M ω}) :=
    hC.inter (hMm (MeasurableSet.singleton (M ω)))
  have hconst : ∀ x ∈ C, M x = M ω := by
    rcases hatom _ hB Set.inter_subset_left with h | h
    · exact absurd (h ▸ (⟨hω, rfl⟩ : ω ∈ C ∩ M ⁻¹' {M ω})) (Set.notMem_empty ω)
    · intro x hx
      rw [← h] at hx
      exact hx.2
  have hint : ∫ x in C, M x ∂P = P.real C * M ω := by
    rw [setIntegral_congr_fun (hm C hC) hconst, setIntegral_const, smul_eq_mul]
  have hreal : P.real C ≠ 0 := by
    rw [measureReal_def, ENNReal.toReal_ne_zero]
    exact ⟨hpos, measure_ne_top P C⟩
  rw [← hMX C hC, hint]
  field_simp

-- Worked numbers from the card: twelve months, each with probability 1/12.
-- Winter total as an integral: (36 + 30 + 24)/12 = 7.50.
example : ((36 + 30 + 24 : ℚ) / 12) = 15 / 2 := by norm_num
-- Winter probability 3/12 and winter forecast 7.50 ÷ 0.25 = 30.
example : ((3 : ℚ) / 12) = 1 / 4 := by norm_num
example : ((15 / 2 : ℚ) / (1 / 4)) = 30 := by norm_num
-- Spring, summer, autumn forecasts: 180/3, 270/3, 120/3 = 60, 90, 40.
example : ((180 : ℚ) / 3, (270 : ℚ) / 3, (120 : ℚ) / 3) = (60, 90, 40) := by norm_num
-- Season totals from the monthly rainfall.
example : (45 + 60 + 75 : ℕ) = 180 ∧ (100 + 95 + 75 : ℕ) = 270 ∧ (55 + 40 + 25 : ℕ) = 120 := by
  decide
-- The wet half: 3 × 60/12 + 3 × 90/12 = (180 + 270)/12 = 37.50.
example : (3 * 60 / 12 + 3 * 90 / 12 : ℚ) = (180 + 270) / 12 := by norm_num
example : ((180 + 270 : ℚ) / 12) = 75 / 2 := by norm_num
-- Yearly mean 660/12 = 55.
example : ((30 + 24 + 45 + 60 + 75 + 100 + 95 + 75 + 55 + 40 + 25 + 36 : ℚ) / 12) = 55 := by
  norm_num
-- Wet and dry season forecasts, directly and from the season forecast.
example : ((180 + 270 : ℚ) / 6) = 75 := by norm_num
example : ((120 + 90 : ℚ) / 6) = 35 := by norm_num
example : ((60 + 90 : ℚ) / 2) = 75 := by norm_num
example : ((30 + 40 : ℚ) / 2) = 35 := by norm_num
-- The constant 55 totals 13.75 on winter, against the true 7.50.
example : ((3 * 55 : ℚ) / 12) = 55 / 4 ∧ (55 / 4 : ℚ) ≠ 15 / 2 := by norm_num
-- Spring anomaly densities: (25/12) ÷ (3/12) and (10/12) ÷ (3/12); difference 5, plus 55 is 60.
example : ((25 / 12 : ℚ) / (3 / 12) - (10 / 12) / (3 / 12) + 55) = 60 := by norm_num
-- Anomaly surplus over the year: 130/12 for both nu+ and nu-.
example : (5 + 20 + 45 + 40 + 20 : ℕ) = 130 ∧ (25 + 31 + 10 + 15 + 30 + 19 : ℕ) = 130 := by
  decide
-- Counts: 16 season events, 4096 sets of months, 194,481 season-constant forecasts.
example : 2 ^ 4 = 16 ∧ 2 ^ 12 = 4096 ∧ 21 ^ 4 = 194481 := by norm_num
-- Without integrability: X(n) = (-2)^n with probability 2^-n. Partial averages after
-- six terms are back to 0, while the partial E|X| has reached 6.
example : (∑ n ∈ Finset.Icc 1 5, ((-2 : ℚ) ^ n / 2 ^ n)) = -1 := by
  simp [Finset.sum_Icc_succ_top]; norm_num
example : (∑ n ∈ Finset.Icc 1 6, ((-2 : ℚ) ^ n / 2 ^ n)) = 0 := by
  simp [Finset.sum_Icc_succ_top]; norm_num
example : (∑ n ∈ Finset.Icc 1 6, ((2 : ℚ) ^ n / 2 ^ n)) = 6 := by simp

#print axioms conditional_expectation_exists_unique
#print axioms conditional_expectation_on_atom_eq_average
