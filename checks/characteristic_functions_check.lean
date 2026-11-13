-- Characteristic functions: two random variables on the line with the same characteristic function have the same law, characteristic functions converge exactly as Lévy's continuity theorem says, and independent sums multiply them.
import Mathlib.MeasureTheory.Measure.CharacteristicFunction.Basic
import Mathlib.MeasureTheory.Function.ConvergenceInDistribution
import Mathlib.Probability.Independence.Basic
import Mathlib.MeasureTheory.Measure.LevyConvergence
import Mathlib.MeasureTheory.Measure.Prokhorov
import Mathlib.Probability.Independence.CharacteristicFunction

open MeasureTheory ProbabilityTheory Filter Topology

/-- **Uniqueness.** The characteristic function pins down the law: if real random variables
`X` and `Y` on a probability space have `φ_X(t) = φ_Y(t)` for every real rate `t`, where
`φ_X(t) = ∫ e^(itx) dμ_X(x)` is Mathlib's `charFun` of the law `μ_X = P ∘ X⁻¹`, then the
two laws are equal. -/
theorem charFun_eq_everywhere_implies_law_eq
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X Y : Ω → ℝ) (hX : Measurable X) (hY : Measurable Y)
    (h : ∀ t : ℝ, charFun (P.map X) t = charFun (P.map Y) t) :
    P.map X = P.map Y := by
  exact Measure.ext_of_charFun (funext h)

/-- **Lévy's continuity theorem.** (a) If `X n` converges in distribution to `Y`, then
`φ_{X n}(t) → φ_Y(t)` for every real `t`. (b) If `φ_{X n}(t) → g(t)` for every real `t` and the
limit `g` is continuous at `0`, then `g` is the characteristic function of some law `ν` on the
line (the law of the random variable `x ↦ x` on `(ℝ, ν)`), and `X n` converges in distribution
to it. -/
theorem levy_continuity_theorem
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P] :
    (∀ (X : ℕ → Ω → ℝ) (Y : Ω → ℝ),
        TendstoInDistribution X atTop Y (fun _ => P) P →
          ∀ t : ℝ, Tendsto (fun n => charFun (P.map (X n)) t) atTop
            (𝓝 (charFun (P.map Y) t))) ∧
    (∀ (X : ℕ → Ω → ℝ) (g : ℝ → ℂ), (∀ n, Measurable (X n)) →
        (∀ t : ℝ, Tendsto (fun n => charFun (P.map (X n)) t) atTop (𝓝 (g t))) →
        ContinuousAt g 0 →
          ∃ ν : ProbabilityMeasure ℝ, (∀ t : ℝ, charFun (ν : Measure ℝ) t = g t) ∧
            TendstoInDistribution X atTop id (fun _ => P) (ν : Measure ℝ)) := by
  refine ⟨fun X Y hXY t => hXY.tendsto_charFun t, ?_⟩
  intro X g hX hconv hg
  let μ : ℕ → ProbabilityMeasure ℝ :=
    fun n => ⟨P.map (X n), inferInstance⟩
  have htight : IsTightMeasureSet (Set.range fun n => (μ n : Measure ℝ)) :=
    isTightMeasureSet_of_tendsto_charFun hg hconv
  have htight' : IsTightMeasureSet
      {((ρ : ProbabilityMeasure ℝ) : Measure ℝ) | ρ ∈ Set.range μ} := by
    convert htight using 1
    ext m
    simp
  have hcomp : IsCompact (closure (Set.range μ)) :=
    isCompact_closure_of_isTightMeasureSet htight'
  let U : Ultrafilter ℕ := Ultrafilter.of atTop
  have hU : (U : Filter ℕ) ≤ atTop := Ultrafilter.of_le atTop
  obtain ⟨ν, -, hν⟩ := hcomp.ultrafilter_le_nhds (U.map μ)
    (by
      refine le_trans ?_ (monotone_principal subset_closure)
      simp)
  have hν' : Tendsto μ U (𝓝 ν) := hν
  have hchar : ∀ t : ℝ, charFun (ν : Measure ℝ) t = g t := by
    intro t
    have h1 : Tendsto (fun n => charFun (μ n : Measure ℝ) t) U (𝓝 (charFun (ν : Measure ℝ) t)) := by
      rw [ProbabilityMeasure.tendsto_iff_forall_integral_rclike_tendsto ℂ] at hν'
      simp_rw [charFun_eq_integral_innerProbChar]
      exact hν' (BoundedContinuousFunction.innerProbChar t)
    exact tendsto_nhds_unique h1 ((hconv t).mono_left hU)
  refine ⟨ν, hchar, ?_⟩
  refine TendstoInDistribution.of_tendsto_charFun (fun n => (hX n).aemeasurable)
    aemeasurable_id fun t => ?_
  rw [Measure.map_id, hchar t]
  exact hconv t

/-- **Independent sums multiply.** If real random variables `X` and `Y` are independent, then
`φ_{X+Y}(t) = φ_X(t) · φ_Y(t)` for every real `t`. -/
theorem charFun_add_of_indep
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (X Y : Ω → ℝ) (hX : Measurable X) (hY : Measurable Y) (hXY : IndepFun X Y P) (t : ℝ) :
    charFun (P.map (fun ω => X ω + Y ω)) t = charFun (P.map X) t * charFun (P.map Y) t := by
  rw [hXY.charFun_map_fun_add_eq_mul hX.aemeasurable hY.aemeasurable, Pi.mul_apply]

-- The die's mean from φ'(0) = 3.5i: (1 + 2 + ... + 6) / 6 = 21/6 = 7/2.
example : ∑ k ∈ Finset.Icc 1 6, k = 21 := by decide
example : ((∑ k ∈ Finset.Icc 1 6, k : ℕ) : ℚ) / 6 = 7 / 2 := by norm_num [Finset.sum_Icc_succ_top]
-- E[X^2] from -φ''(0): (1 + 4 + ... + 36) / 6 = 91/6, and the variance 91/6 - (7/2)^2 = 35/12.
example : ∑ k ∈ Finset.Icc 1 6, k ^ 2 = 91 := by decide
example : (91 : ℚ) / 6 - (7 / 2) ^ 2 = 35 / 12 := by norm_num
-- Two dice: total 7 arises in 6 of the 36 ordered pairs, the coefficient 6/36 of e^(7it) in φ^2.
example : ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun p : ℕ × ℕ => p.1 + p.2 = 7)).card = 6 := by
  decide
example : (Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).card = 36 := by decide
-- 100 rolls, from φ^100: mean 100 · 7/2 = 350 and variance 100 · 35/12 = 875/3.
example : (100 : ℚ) * (7 / 2) = 350 := by norm_num
example : (100 : ℚ) * (35 / 12) = 875 / 3 := by norm_num

#print axioms charFun_eq_everywhere_implies_law_eq
#print axioms levy_continuity_theorem
#print axioms charFun_add_of_indep
