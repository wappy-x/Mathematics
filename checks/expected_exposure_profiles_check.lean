-- Expected exposure over time: a bought option's expected exposure, shrunk to today, equals its price at every date; flooring before averaging never lowers the average; and the PFE of a rising revaluation is the revaluation at the driver's percentile.
import Mathlib.MeasureTheory.Function.ConditionalExpectation.Basic
import Mathlib.Probability.Process.Filtration
import Mathlib.Analysis.SpecialFunctions.Exp

open MeasureTheory

/-- The card's main theorem (Step 3). In the pricing world, a bought option that pays only its
nonnegative payoff `H` at expiry `T` is worth `c(u) = e^{-r(T-u)} E[H | 𝓕_u]` on date `u`.
Its expected exposure `EE(u) = E[max(c(u), 0)]`, shrunk back to today by `e^{-ru}`, equals
today's price `C₀ = e^{-rT} E[H]` at every date `u` up to expiry. -/
theorem discounted_expected_exposure_eq_price {Ω : Type*} {m0 : MeasurableSpace Ω}
    (μ : Measure Ω) [IsProbabilityMeasure μ] (𝓕 : Filtration ℝ m0)
    (H : Ω → ℝ) (hH : ∀ ω, 0 ≤ H ω) (r T u : ℝ) (hu0 : 0 ≤ u) (huT : u ≤ T) :
    Real.exp (-r * u) * ∫ ω, max (Real.exp (-r * (T - u)) * μ[H | 𝓕 u] ω) 0 ∂μ
      = Real.exp (-r * T) * ∫ ω, H ω ∂μ := by
  have hnn : 0 ≤ᵐ[μ] μ[H | 𝓕 u] := condExp_nonneg (Filter.Eventually.of_forall hH)
  have hae : (fun ω => max (Real.exp (-r * (T - u)) * μ[H | 𝓕 u] ω) 0)
      =ᵐ[μ] fun ω => Real.exp (-r * (T - u)) * μ[H | 𝓕 u] ω := by
    filter_upwards [hnn] with ω hω
    exact max_eq_left (mul_nonneg (Real.exp_pos _).le hω)
  rw [integral_congr_ae hae, integral_const_mul, integral_condExp (𝓕.le u), ← mul_assoc,
    ← Real.exp_add]
  congr 2
  ring

/-- Step 2: floor first, then average. For any trade value `V` with a finite average, the
expected exposure `E[max(V, 0)]` is at least `max(E[V], 0)`. -/
theorem expected_exposure_ge_floor_of_mean {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (V : Ω → ℝ) (hV : Integrable V μ) :
    max (∫ ω, V ω ∂μ) 0 ≤ ∫ ω, max (V ω) 0 ∂μ := by
  refine max_le ?_ (integral_nonneg fun ω => le_max_right _ _)
  exact integral_mono hV (hV.sup (integrable_zero _ _ _)) fun ω => le_max_left _ _

/-- Step 4: the percentile passes through the revaluation. If the revaluation map `g` is
continuous and never decreasing, and `s` is the `α` percentile of the driver `S` (the smallest
level with `Pr(S ≤ s) ≥ α`), then `g(s)` is the `α` percentile of `g(S)`: the smallest `x`
with `Pr(g(S) ≤ x) ≥ α`. -/
theorem pfe_eq_revaluation_at_percentile {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) [IsProbabilityMeasure μ] (S : Ω → ℝ) (g : ℝ → ℝ)
    (hg : Continuous g) (hmono : Monotone g) (α s : ℝ)
    (hs : IsLeast {x : ℝ | α ≤ μ.real {ω | S ω ≤ x}} s) :
    IsLeast {x : ℝ | α ≤ μ.real {ω | g (S ω) ≤ x}} (g s) := by
  refine ⟨?_, ?_⟩
  · show α ≤ μ.real {ω | g (S ω) ≤ g s}
    exact hs.1.trans (measureReal_mono (s₁ := {ω | S ω ≤ s}) fun ω (hω : S ω ≤ s) => hmono hω)
  · intro x hx
    by_contra hlt
    push Not at hlt
    have hmem : g ⁻¹' Set.Ioi x ∈ nhds s := hg.continuousAt.preimage_mem_nhds (Ioi_mem_nhds hlt)
    obtain ⟨l, hl, hsub⟩ := exists_Ioc_subset_of_mem_nhds hmem ⟨s - 1, by linarith⟩
    have hset : {ω | g (S ω) ≤ x} ⊆ {ω | S ω ≤ l} := by
      intro ω (hω : g (S ω) ≤ x)
      show S ω ≤ l
      by_contra h
      push Not at h
      rcases le_or_gt (S ω) s with h2 | h2
      · have := hsub ⟨h, h2⟩
        simp only [Set.mem_preimage, Set.mem_Ioi] at this
        linarith
      · have := hmono h2.le
        linarith
    have hl' : l ∉ {x : ℝ | α ≤ μ.real {ω | S ω ≤ x}} := fun h => absurd (hs.2 h) (not_le.2 hl)
    simp only [Set.mem_ofPred_eq, not_le] at hl'
    have : α ≤ μ.real {ω | S ω ≤ l} := (show α ≤ μ.real {ω | g (S ω) ≤ x} from hx).trans
      (measureReal_mono hset)
    linarith

-- With 40,000 paths, the 95th percentile is the ceil(0.95 × 40,000)-th sorted value: the 38,000th.
example : (95 * 40000 + 99) / 100 = 38000 := by norm_num

-- At 95% confidence, one scenario in twenty is worse.
example : (1 : ℚ) - 95 / 100 = 1 / 20 := by norm_num

#print axioms discounted_expected_exposure_eq_price
#print axioms expected_exposure_ge_floor_of_mean
#print axioms pfe_eq_revaluation_at_percentile
