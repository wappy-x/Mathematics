-- Filtrations and martingales: forecasts of a fixed integrable result are martingales, the density process of one probability against another is a martingale with mean 1, and a martingale keeps its forecast and its mean at every later step.
import Mathlib.Probability.Martingale.Basic
import Mathlib.MeasureTheory.Measure.Decomposition.RadonNikodym
import Mathlib.MeasureTheory.Measure.Decomposition.IntegralRNDeriv

open MeasureTheory

/-- Forecasts are martingales: on a probability space with a filtration (information that only
grows), for every integrable final result `Y` the forecasts `M n = E[Y | ℱ n]` are integrable and
form a martingale. -/
theorem condExp_forecast_is_martingale {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0)
    (Y : Ω → ℝ) (hY : Integrable Y P) :
    Martingale (fun n => P[Y | ℱ n]) ℱ P ∧ ∀ n, Integrable (P[Y | ℱ n]) P := by
  exact ⟨martingale_condExp Y ℱ P, fun _ => integrable_condExp⟩

/-- The density process is a martingale: if `Q` and `P` are probabilities and `Q ≪ P` on each
`ℱ n`, then `Z n = dQ|ℱ n / dP|ℱ n` is integrable, is a martingale under `P`, and has
`E_P[Z n] = 1` for every `n`. -/
theorem density_process_is_martingale {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P Q : Measure Ω) [IsProbabilityMeasure P] [IsProbabilityMeasure Q] (ℱ : Filtration ℕ m0)
    (hQP : ∀ n, Q.trim (ℱ.le n) ≪ P.trim (ℱ.le n)) :
    Martingale (fun n ω => ((Q.trim (ℱ.le n)).rnDeriv (P.trim (ℱ.le n)) ω).toReal) ℱ P ∧
      (∀ n, Integrable (fun ω => ((Q.trim (ℱ.le n)).rnDeriv (P.trim (ℱ.le n)) ω).toReal) P) ∧
      ∀ n, ∫ ω, ((Q.trim (ℱ.le n)).rnDeriv (P.trim (ℱ.le n)) ω).toReal ∂P = 1 := by
  have hmeas : ∀ n, StronglyMeasurable[ℱ n]
      (fun ω => ((Q.trim (ℱ.le n)).rnDeriv (P.trim (ℱ.le n)) ω).toReal) := fun n =>
    (@Measure.measurable_rnDeriv Ω (ℱ n) _ _).ennreal_toReal.stronglyMeasurable
  have hint : ∀ n, Integrable (fun ω => ((Q.trim (ℱ.le n)).rnDeriv (P.trim (ℱ.le n)) ω).toReal) P :=
    fun n => integrable_of_integrable_trim (ℱ.le n) Measure.integrable_toReal_rnDeriv
  have hset : ∀ n (s : Set Ω), MeasurableSet[ℱ n] s →
      ∫ ω in s, ((Q.trim (ℱ.le n)).rnDeriv (P.trim (ℱ.le n)) ω).toReal ∂P = Q.real s := by
    intro n s hs
    rw [setIntegral_trim (ℱ.le n) (hmeas n) hs, Measure.setIntegral_toReal_rnDeriv (hQP n) s,
      measureReal_def, measureReal_def, trim_measurableSet_eq (ℱ.le n) hs]
  refine ⟨martingale_of_setIntegral_eq_succ hmeas hint fun n s hs => ?_, hint, fun n => ?_⟩
  · rw [hset n s hs, hset (n + 1) s (ℱ.mono n.le_succ s hs)]
  · rw [← setIntegral_univ, hset n Set.univ MeasurableSet.univ, probReal_univ]

/-- A martingale keeps its mean: if `X` is adapted, each `X n` is integrable, and
`E[X (n+1) | ℱ n] = X n` almost surely for every `n`, then `E[X m | ℱ n] = X n` almost surely for
every `m ≥ n`, and `E[X n] = E[X 0]` for every `n`. -/
theorem martingale_keeps_its_mean {Ω : Type*} {m0 : MeasurableSpace Ω}
    (P : Measure Ω) [IsProbabilityMeasure P] (ℱ : Filtration ℕ m0) (X : ℕ → Ω → ℝ)
    (hadapt : Adapted ℱ X) (hint : ∀ n, Integrable (X n) P)
    (hstep : ∀ n, P[X (n + 1) | ℱ n] =ᵐ[P] X n) :
    (∀ n m, n ≤ m → P[X m | ℱ n] =ᵐ[P] X n) ∧ ∀ n, ∫ ω, X n ω ∂P = ∫ ω, X 0 ω ∂P := by
  have hM : Martingale X ℱ P :=
    martingale_nat hadapt.stronglyAdapted hint fun n => (hstep n).symm
  refine ⟨fun n m hnm => hM.condExp_ae_eq hnm, fun n => ?_⟩
  have := hM.setIntegral_eq (Nat.zero_le n) MeasurableSet.univ
  simpa only [setIntegral_univ] using this.symm

-- The poker night: the eight endings average to the start, $100.
example : ((150 + 130 + 110 + 90 + 130 + 110 + 50 + 30) / 8 : ℚ) = 100 := by norm_num
-- After a first win the forecast is $120; after a first loss, $80.
example : ((150 + 130 + 110 + 90) / 4 : ℚ) = 120 := by norm_num
example : ((130 + 110 + 50 + 30) / 4 : ℚ) = 80 := by norm_num
-- After W then L, the forecast is $100; the two step-2 forecasts after a win average back to $120.
example : ((110 + 90) / 2 : ℚ) = 100 := by norm_num
example : ((140 + 100) / 2 : ℚ) = 120 := by norm_num
-- Finishing above $100: 5 of the 8 endings.
example : (([150, 130, 110, 90, 130, 110, 50, 30] : List ℕ).filter (fun y => 100 < y)).length = 5 := by
  decide
-- The chance of finishing ahead is a martingale too: 3/4 and 1/2 average to 5/8.
example : ((3 / 4 + 1 / 2) / 2 : ℚ) = 5 / 8 := by norm_num
-- The loaded die: two sixes give Z_2 = (12/5)(12/5) = 144/25, and 144/25 times 1/36 is Q(two sixes) = (2/5)^2.
example : ((12 / 5) * (12 / 5) : ℚ) = 144 / 25 := by norm_num
example : ((144 / 25) * (1 / 36) : ℚ) = (2 / 5) * (2 / 5) := by norm_num
-- Averaged under Q instead of P, Z_1 has mean 36/25, not 1.
example : (4 * ((1 / 10) * (3 / 5)) + (1 / 5) * (6 / 5) + (2 / 5) * (12 / 5) : ℚ) = 36 / 25 := by
  norm_num
-- Of the 216 three-roll sequences, 172 end with Z_3 below 1. The rates are 3/5, 6/5, 12/5, so
-- Z_3 < 1 exactly when the product of the numerators (3, 3, 3, 3, 6, 12 by face) is below 125.
example :
    ((Finset.univ : Finset (Fin 6 × Fin 6 × Fin 6)).filter (fun r =>
      (![3, 3, 3, 3, 6, 12] : Fin 6 → ℕ) r.1 * (![3, 3, 3, 3, 6, 12] : Fin 6 → ℕ) r.2.1 *
        (![3, 3, 3, 3, 6, 12] : Fin 6 → ℕ) r.2.2 < 125)).card = 172 := by
  decide +kernel

#print axioms condExp_forecast_is_martingale
#print axioms density_process_is_martingale
#print axioms martingale_keeps_its_mean
