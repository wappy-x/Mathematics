-- Sums, products, sups and limits: sums, products, maxima, minima, sups, infs, upper and lower limits and pointwise limits of measurable functions on one measurable space are measurable, and so is the set where a sequence converges.
import Mathlib.MeasureTheory.Constructions.BorelSpace.Real
import Mathlib.MeasureTheory.Constructions.BorelSpace.Metrizable
import Mathlib.MeasureTheory.Constructions.Polish.StronglyMeasurable
import Mathlib.Tactic.NormNum

open Filter Topology MeasureTheory

/-- Everything you do to measurable functions gives back a measurable function. On one measurable
space, take finite (real-valued) measurable functions `f` and `g`, and a list `u 0, u 1, u 2, ...`
of measurable functions with values in the extended line (the reals with `+∞` and `-∞`). Then
`f + g`, `f * g`, `max f g` and `min f g` are measurable; so are the sup, the inf, the upper limit
and the lower limit of the list; and the set `L` where the lower and upper limits agree at a
finite value, the set where the list settles, is an allowed set. -/
theorem measurable_closed_under_sums_products_sups_and_limits
    {Ω : Type*} [MeasurableSpace Ω]
    (f g : Ω → ℝ) (hf : Measurable f) (hg : Measurable g)
    (u : ℕ → Ω → EReal) (hu : ∀ n, Measurable (u n)) :
    Measurable (fun ω => f ω + g ω) ∧
    Measurable (fun ω => f ω * g ω) ∧
    Measurable (fun ω => max (f ω) (g ω)) ∧
    Measurable (fun ω => min (f ω) (g ω)) ∧
    Measurable (fun ω => ⨆ n, u n ω) ∧
    Measurable (fun ω => ⨅ n, u n ω) ∧
    Measurable (fun ω => limsup (fun n => u n ω) atTop) ∧
    Measurable (fun ω => liminf (fun n => u n ω) atTop) ∧
    MeasurableSet {ω | liminf (fun n => u n ω) atTop = limsup (fun n => u n ω) atTop ∧
      limsup (fun n => u n ω) atTop < ⊤ ∧ ⊥ < liminf (fun n => u n ω) atTop} := by
  have hsup : Measurable (fun ω => limsup (fun n => u n ω) atTop) := Measurable.limsup hu
  have hinf : Measurable (fun ω => liminf (fun n => u n ω) atTop) := Measurable.liminf hu
  refine ⟨hf.add hg, hf.mul hg, hf.max hg, hf.min hg, Measurable.iSup hu, Measurable.iInf hu,
    hsup, hinf, ?_⟩
  exact (measurableSet_eq_fun hinf hsup).inter
    ((measurableSet_lt hsup measurable_const).inter (measurableSet_lt measurable_const hinf))

/-- The limit set and the limit function (Claims 4 and 5). For a list of real measurable
functions, the set `L` of outcomes where the list has a finite limit is allowed, and the limit,
set to 0 off `L`, is a measurable function. -/
theorem limit_set_and_limit_function_measurable
    {Ω : Type*} [MeasurableSpace Ω]
    (f : ℕ → Ω → ℝ) (hf : ∀ n, Measurable (f n)) :
    MeasurableSet {ω | ∃ c : ℝ, Tendsto (fun n => f n ω) atTop (𝓝 c)} ∧
    Measurable ({ω | ∃ c : ℝ, Tendsto (fun n => f n ω) atTop (𝓝 c)}.indicator
      (fun ω => limUnder atTop (fun n => f n ω))) := by
  have hs : ∀ n, StronglyMeasurable (f n) := fun n => (hf n).stronglyMeasurable
  have hS : MeasurableSet {ω | ∃ c : ℝ, Tendsto (fun n => f n ω) atTop (𝓝 c)} :=
    StronglyMeasurable.measurableSet_exists_tendsto hs
  exact ⟨hS, (StronglyMeasurable.limUnder hs).measurable.indicator hS⟩

/-- Pointwise limits. If a list of measurable functions on one measurable space converges at
every outcome, its limit is measurable. -/
theorem measurable_of_pointwise_limit
    {Ω : Type*} [MeasurableSpace Ω]
    (f : ℕ → Ω → ℝ) (hf : ∀ n, Measurable (f n)) (g : Ω → ℝ)
    (hlim : ∀ ω, Tendsto (fun n => f n ω) atTop (𝓝 (g ω))) :
    Measurable g := by
  exact measurable_of_tendsto_metrizable hf (tendsto_pi_nhds.2 hlim)

-- The card's toy river gauge, in exact fractions: the level at hour n in a year of wetness w,
-- with the sluice swing max(0, w - 3/4) added on even hours and removed on odd ones.
def level (w : ℚ) (n : ℕ) : ℚ := 2 + 2 * w * (1 - (1 / 2) ^ n) + (-1) ^ n * max 0 (w - 3 / 4)

-- Wetness 0.95 = 19/20: hour 1 reads 2.75 m, hour 4 reads 3.98125 m (below the 4 m flood mark),
-- hour 6 reads 4.0703125 m (above it).
example : level (19 / 20) 1 = 11 / 4 := by norm_num [level]
example : level (19 / 20) 4 = 637 / 160 ∧ level (19 / 20) 4 < 4 := by norm_num [level]
example : level (19 / 20) 6 = 521 / 128 ∧ 4 < level (19 / 20) 6 := by norm_num [level]
-- The swing at wetness 0.95 is 0.2 m; floor and ceiling are 3.70 m and 4.10 m.
example : max 0 ((19 / 20 : ℚ) - 3 / 4) = 1 / 5 := by norm_num
example : 2 + 2 * (19 / 20 : ℚ) - 1 / 5 = 37 / 10 ∧ 2 + 2 * (19 / 20 : ℚ) + 1 / 5 = 41 / 10 := by
  norm_num
-- The flood bands: hour n passes 4 m when the wetness exceeds 2.75 / (3 - 2^(1-n)).
example : (11 / 4 : ℚ) / (3 - 1 / 8) = 22 / 23 ∧ 1 - (22 / 23 : ℚ) = 1 / 23 := by norm_num
example : (11 / 4 : ℚ) / (3 - 1 / 32) = 88 / 95 ∧ 1 - (88 / 95 : ℚ) = 7 / 95 := by norm_num
example : (11 / 4 : ℚ) / (3 - 1 / 128) = 352 / 383 := by norm_num
example : (11 / 4 : ℚ) / 3 = 11 / 12 ∧ 1 - (11 / 12 : ℚ) = 1 / 12 := by norm_num
-- At each band's left edge the level sits exactly on the 4 m mark.
example : level (22 / 23) 4 = 4 ∧ level (88 / 95) 6 = 4 ∧ level (352 / 383) 8 = 4 := by
  norm_num [level]
-- At wetness 11/12 the record approaches 4 m but hours 10 and 20 stay below it.
example : level (11 / 12) 10 < 4 ∧ level (11 / 12) 20 < 4 := by norm_num [level]
-- The long-run level at wetness 0.45 is 2 + 2 × 0.45 = 2.90 m.
example : 2 + 2 * (9 / 20 : ℚ) = 29 / 10 := by norm_num
-- Hours 2 and 3 sum to exactly 6 m at wetness 8/13, the edge of {hour 2 + hour 3 < 6}.
example : level (8 / 13) 2 + level (8 / 13) 3 = 6 := by norm_num [level]
-- Whole-number q = 3 catches wetness below min((3 - 2)/(3/2), (4 - 3)/(7/4)) = 4/7.
example : min (((3 : ℚ) - 2) / (3 / 2)) ((4 - 3) / (7 / 4)) = 4 / 7 := by norm_num
-- The four-point space: 3^4 = 81 functions with values 0, 1, 2; 3^2 = 9 fit the blocks {0,1} {2,3}.
example : 3 ^ 4 = 81 ∧ 3 ^ 2 = 9 := by decide
-- Mixing: f = (1, 1, 0, 0) plus g = (1, 0, 1, 0) is (2, 1, 1, 0).
example : (![1, 1, 0, 0] + ![1, 0, 1, 0] : Fin 4 → ℕ) = ![2, 1, 1, 0] := by decide

#print axioms measurable_closed_under_sums_products_sups_and_limits
#print axioms limit_set_and_limit_function_measurable
#print axioms measurable_of_pointwise_limit
