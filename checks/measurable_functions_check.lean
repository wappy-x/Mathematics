-- Measurable functions: a real-valued function is measurable exactly when every set "value below a" is an allowed set, and continuous functions, indicators of allowed sets and Borel functions of measurable functions are measurable.
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.MeasureTheory.MeasurableSpace.Basic
import Mathlib.Combinatorics.Enumerative.Stirling
import Mathlib.Tactic.NormNum

open MeasureTheory Set

/-- The threshold test. Fix a sigma-algebra on the inputs `Ω`. A real-valued function `f` is
measurable (every Borel set of values pulls back to an allowed set) exactly when, for every real
threshold `a`, the set of inputs whose value is below `a` is an allowed set. -/
theorem measurable_iff_below_every_threshold_measurable {Ω : Type*} [MeasurableSpace Ω]
    (f : Ω → ℝ) : Measurable f ↔ ∀ a : ℝ, MeasurableSet {ω | f ω < a} := by
  constructor
  · intro hf a
    exact measurableSet_lt hf measurable_const
  · intro h
    exact measurable_of_Iio h

/-- Indicators. The function that is 1 on a set `A` of inputs and 0 off it is measurable exactly
when `A` is an allowed set. -/
theorem indicator_measurable_iff_set_allowed {Ω : Type*} [MeasurableSpace Ω] (A : Set Ω) :
    Measurable (A.indicator (fun _ => (1 : ℝ))) ↔ MeasurableSet A := by
  exact measurable_indicator_const_iff (1 : ℝ)

/-- Continuous functions and compositions. A continuous function from the line to the line is
Borel (measurable, with the Borel sets on both sides), and a Borel function applied after a
measurable function gives a measurable function. -/
theorem continuous_is_borel_and_borel_after_measurable_is_measurable :
    (∀ g : ℝ → ℝ, Continuous g → Measurable g) ∧
    (∀ {Ω : Type*} [MeasurableSpace Ω] (f : Ω → ℝ) (g : ℝ → ℝ),
      Measurable f → Measurable g → Measurable (g ∘ f)) := by
  refine ⟨fun g hg => hg.measurable, ?_⟩
  intro Ω _ f g hf hg
  exact hg.comp hf

-- Weights in tenths of a kilogram: p1 13, p2 18, p3 22, p4 36. "Under 2 kg?" picks p1 and p2.
example : (Finset.univ.filter (fun i : Fin 4 => (![13, 18, 22, 36] : Fin 4 → ℕ) i < 20))
    = {0, 1} := by decide
-- "Under 1.5 kg?" picks p1 alone; "under 2.5 kg?" picks p1, p2, p3.
example : (Finset.univ.filter (fun i : Fin 4 => (![13, 18, 22, 36] : Fin 4 → ℕ) i < 15))
    = {0} := by decide
example : (Finset.univ.filter (fun i : Fin 4 => (![13, 18, 22, 36] : Fin 4 → ℕ) i < 25))
    = {0, 1, 2} := by decide
-- Rounding halves up: the largest whole number at most x + 1/2, here in tenths: 1, 2, 2, 4.
example : (13 + 5) / 10 = 1 ∧ (18 + 5) / 10 = 2 ∧ (22 + 5) / 10 = 2 ∧ (36 + 5) / 10 = 4 := by
  decide
-- The rounded log: every union of the atoms {p1}, {p2, p3}, {p4}, 2 x 2 x 2 = 8 sets.
-- It does not hold {p1, p2}, so it cannot settle "under 2 kg?"; it does hold {p1}.
example :
    let log : Finset (Finset (Fin 4)) :=
      {∅, {0}, {1, 2}, {3}, {0, 1, 2}, {0, 3}, {1, 2, 3}, {0, 1, 2, 3}}
    log.card = 8 ∧ ({0, 1} : Finset (Fin 4)) ∉ log ∧ ({0} : Finset (Fin 4)) ∈ log := by
  decide
example : 2 * 2 * 2 = 8 := by norm_num
-- The full record holds all 2^4 = 16 sets; 2^16 = 65536 families searched; 3^4 = 81 maps.
example : 2 ^ 4 = 16 ∧ 2 ^ 16 = 65536 ∧ 3 ^ 4 = 81 := by norm_num
-- Sigma-algebras on four parcels by number of atoms: Stirling numbers S(4, k) = 1, 7, 6, 1; 15 in all.
example : Nat.stirlingSecond 4 1 = 1 ∧ Nat.stirlingSecond 4 2 = 7 ∧
    Nat.stirlingSecond 4 3 = 6 ∧ Nat.stirlingSecond 4 4 = 1 := by decide
example : ∑ k ∈ Finset.range 5, Nat.stirlingSecond 4 k = 15 := by decide
-- Measurable (family, map) pairs into {1, 2, 3}: 1 x 3 + 7 x 9 + 6 x 27 + 1 x 81 = 309.
example : 1 * 3 + 7 * 9 + 6 * 27 + 1 * 81 = 309 := by norm_num
example : ∑ k ∈ Finset.range 5, Nat.stirlingSecond 4 k * 3 ^ k = 309 := by decide

#print axioms measurable_iff_below_every_threshold_measurable
#print axioms indicator_measurable_iff_set_allowed
#print axioms continuous_is_borel_and_borel_after_measurable_is_measurable
