-- Stochastic-local volatility: on any date, the leverage L(S) = σ_loc(S) / √E[v | S] makes the average of L(S)² v over the paths at each price equal the local variance σ_loc(S)², because a known factor comes out of a conditional average and the matching condition has only this nonnegative root.
import Mathlib.MeasureTheory.Function.ConditionalExpectation.PullOut
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open MeasureTheory

/-- Helper: pull a known factor `L(S)²` out of the conditional average given `S`. -/
theorem slv_helper_pull_out
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (S v : Ω → ℝ) (hv : Integrable v μ)
    (L : ℝ → ℝ) (hL : Measurable L)
    (hLv : Integrable (fun ω => L (S ω) ^ 2 * v ω) μ) :
    μ[(fun ω => L (S ω) ^ 2 * v ω) | MeasurableSpace.comap S inferInstance]
      =ᵐ[μ] fun ω => L (S ω) ^ 2 * μ[v | MeasurableSpace.comap S inferInstance] ω := by
  have hf : StronglyMeasurable[MeasurableSpace.comap S inferInstance]
      (fun ω => L (S ω) ^ 2) :=
    ((hL.pow_const 2).comp (comap_measurable S)).stronglyMeasurable
  exact condExp_mul_of_stronglyMeasurable_left (f := fun ω => L (S ω) ^ 2) (g := v) hf hLv hv

#print axioms slv_helper_pull_out

/-- **The leverage formula reprices the surface's local variance** (Steps 2 and 3, the
averaged condition). Fix one date. Let `S` be Acme's price and `v` the Heston variance on
that date, with `v` of finite average, and let `g` be the average Heston variance at each
price: `E[v | S] = g(S)`. Let `σ_loc` be the surface's local volatility at that date.
**A finite leverage:** the average variance `g` stays positive and the leverage
`L(x) = σ_loc(x) / √(g(x))` stays below some bound `C`. Then the mix's squared volatility,
averaged over the paths standing at each price, equals the surface's local variance:
`E[L(S)² v | S] = σ_loc(S)²` almost surely. -/
theorem slv_leverage_matches_local_variance
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (S v : Ω → ℝ) (hS : Measurable S) (hv : Integrable v μ)
    (g σloc : ℝ → ℝ) (hg : Measurable g) (hσ : Measurable σloc)
    (hcond : μ[v | MeasurableSpace.comap S inferInstance] =ᵐ[μ] fun ω => g (S ω))
    (hpos : ∀ x, 0 < g x)
    (hbound : ∃ C : ℝ, ∀ x, |σloc x / Real.sqrt (g x)| ≤ C) :
    μ[(fun ω => (σloc (S ω) / Real.sqrt (g (S ω))) ^ 2 * v ω) |
        MeasurableSpace.comap S inferInstance]
      =ᵐ[μ] fun ω => σloc (S ω) ^ 2 := by
  obtain ⟨C, hC⟩ := hbound
  set L : ℝ → ℝ := fun x => σloc x / Real.sqrt (g x) with hLdef
  have hLm : Measurable L := hσ.div (Real.continuous_sqrt.measurable.comp hg)
  have hLv : Integrable (fun ω => L (S ω) ^ 2 * v ω) μ := by
    refine hv.bdd_mul (c := C ^ 2) ?_ ?_
    · exact ((hLm.pow_const 2).comp hS).aestronglyMeasurable
    · refine Filter.Eventually.of_forall (fun ω => ?_)
      have h1 := hC (S ω)
      have h0 : 0 ≤ |L (S ω)| := abs_nonneg _
      rw [Real.norm_eq_abs, abs_pow]
      exact pow_le_pow_left₀ h0 h1 2
  have key := slv_helper_pull_out μ S v hv L hLm hLv
  filter_upwards [key, hcond] with ω h1 h2
  rw [h1, h2]
  have hg0 := hpos (S ω)
  simp only [hLdef]
  rw [div_pow, Real.sq_sqrt hg0.le]
  field_simp

/-- **A known factor comes out of the average** (Step 2). On the paths standing at a given
price the leverage is one known number, so for any leverage function `L` of price,
`E[L(S)² v | S] = L(S)² E[v | S]` almost surely (with `v` and `L(S)² v` of finite average). -/
theorem slv_leverage_comes_out_of_average
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (S v : Ω → ℝ) (hS : Measurable S) (hv : Integrable v μ)
    (L : ℝ → ℝ) (hL : Measurable L)
    (hLv : Integrable (fun ω => L (S ω) ^ 2 * v ω) μ) :
    μ[(fun ω => L (S ω) ^ 2 * v ω) | MeasurableSpace.comap S inferInstance]
      =ᵐ[μ] fun ω => L (S ω) ^ 2 * μ[v | MeasurableSpace.comap S inferInstance] ω := by
  exact slv_helper_pull_out μ S v hv L hL hLv

/-- **Divide by the average and take the root** (end of Step 3). At one price and date, with
average Heston variance `m > 0` and local volatility `σ ≥ 0`, a nonnegative leverage `L`
satisfies the matching condition `L² m = σ²` exactly when `L = σ / √m`. -/
theorem slv_leverage_unique_root (L m σ : ℝ) (hm : 0 < m) (hL : 0 ≤ L) (hσ : 0 ≤ σ) :
    L ^ 2 * m = σ ^ 2 ↔ L = σ / Real.sqrt m := by
  have hs : 0 < Real.sqrt m := Real.sqrt_pos.mpr hm
  have hss : Real.sqrt m ^ 2 = m := Real.sq_sqrt hm.le
  constructor
  · intro h
    rw [eq_div_iff hs.ne']
    have h2 : (L * Real.sqrt m) ^ 2 = σ ^ 2 := by rw [mul_pow, hss, h]
    exact (pow_left_inj₀ (mul_nonneg hL hs.le) hσ two_ne_zero).mp h2
  · intro h
    rw [h, div_pow, hss]
    field_simp

-- At the start every particle sits at $100 with variance 0.04, so the leverage is
-- 0.20 / √0.04 = 0.20 / 0.20 = 1.
example : Real.sqrt (1 / 25) = 1 / 5 := by
  rw [Real.sqrt_eq_iff_mul_self_eq] <;> norm_num
example : ((1 : ℚ) / 5) / (1 / 5) = 1 := by norm_num
-- With leverage 1 and variance 0.04 the matching condition L² v = 0.20² holds.
example : (1 : ℚ) ^ 2 * (1 / 25) = (1 / 5) ^ 2 := by norm_num
-- The $90 node at half a year: leverage 0.8676 scales Heston volatilities 30% and 10%
-- to 0.26028 and 0.08676 (the card rounds to 0.2603 and 0.0868).
example : (8676 / 10000 : ℚ) * (3 / 10) = 26028 / 100000 := by norm_num
example : (8676 / 10000 : ℚ) * (1 / 10) = 8676 / 100000 := by norm_num

#print axioms slv_leverage_matches_local_variance
#print axioms slv_leverage_comes_out_of_average
#print axioms slv_leverage_unique_root
