-- The Radon-Nikodym theorem: for sigma-finite measures, ν is absolutely continuous with respect to μ exactly when ν has a finite non-negative measurable density against μ, and that density is unique except on a μ-null set.
import Mathlib.MeasureTheory.Measure.Decomposition.RadonNikodym
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Real.Cardinality

open MeasureTheory
open scoped ENNReal NNReal

/-- The Radon-Nikodym theorem. Let μ and ν be sigma-finite measures on the same
sigma-algebra. Then ν ≪ μ (every μ-null set is ν-null) exactly when there is a
measurable function f ≥ 0, with finite values, such that ν(A) = ∫_A f dμ for every
measurable set A. -/
theorem absolutely_continuous_iff_exists_density
    {Ω : Type*} [MeasurableSpace Ω] (μ ν : Measure Ω) [SigmaFinite μ] [SigmaFinite ν] :
    ν ≪ μ ↔ ∃ f : Ω → ℝ≥0, Measurable f ∧
      ∀ A : Set Ω, MeasurableSet A → ν A = ∫⁻ x in A, (f x : ℝ≥0∞) ∂μ := by
  constructor
  · intro hac
    refine ⟨fun x => (ν.rnDeriv μ x).toNNReal, (Measure.measurable_rnDeriv ν μ).ennreal_toNNReal, ?_⟩
    intro A hA
    have hlt := Measure.rnDeriv_lt_top ν μ
    calc ν A = μ.withDensity (ν.rnDeriv μ) A := by rw [Measure.withDensity_rnDeriv_eq ν μ hac]
      _ = ∫⁻ x in A, ν.rnDeriv μ x ∂μ := withDensity_apply _ hA
      _ = ∫⁻ x in A, ((ν.rnDeriv μ x).toNNReal : ℝ≥0∞) ∂μ := by
        refine setLIntegral_congr_fun_ae hA ?_
        filter_upwards [hlt] with x hx _
        exact (ENNReal.coe_toNNReal hx.ne).symm
  · rintro ⟨f, hf, hν⟩
    have : ν = μ.withDensity (fun x => (f x : ℝ≥0∞)) := by
      ext A hA
      rw [hν A hA, withDensity_apply _ hA]
    rw [this]
    exact withDensity_absolutelyContinuous _ _

/-- Uniqueness: when μ and ν are sigma-finite, two densities of ν against μ agree
except on a set of μ-size zero. -/
theorem density_unique_ae
    {Ω : Type*} [MeasurableSpace Ω] (μ ν : Measure Ω) [SigmaFinite μ] [SigmaFinite ν]
    (f g : Ω → ℝ≥0) (hf : Measurable f) (hg : Measurable g)
    (hfν : ∀ A : Set Ω, MeasurableSet A → ν A = ∫⁻ x in A, (f x : ℝ≥0∞) ∂μ)
    (hgν : ∀ A : Set Ω, MeasurableSet A → ν A = ∫⁻ x in A, (g x : ℝ≥0∞) ∂μ) :
    f =ᵐ[μ] g := by
  have h : (fun x => (f x : ℝ≥0∞)) =ᵐ[μ] (fun x => (g x : ℝ≥0∞)) :=
    ae_eq_of_forall_setLIntegral_eq_of_sigmaFinite hf.coe_nnreal_ennreal hg.coe_nnreal_ennreal
      (fun s hs _ => (hfν s hs).symm.trans (hgν s hs))
  filter_upwards [h] with x hx
  exact ENNReal.coe_injective hx

/-- The card's failure case: counting measure on [0, 1] is not sigma-finite; length on
[0, 1] is absolutely continuous with respect to it, yet length has no density against it. -/
theorem volume_Icc_no_density_against_count :
    ¬ SigmaFinite (Measure.count.restrict (Set.Icc (0 : ℝ) 1)) ∧
    (volume.restrict (Set.Icc (0 : ℝ) 1)) ≪ (Measure.count.restrict (Set.Icc (0 : ℝ) 1)) ∧
    ¬ ∃ f : ℝ → ℝ≥0∞, Measurable f ∧ ∀ A : Set ℝ, MeasurableSet A →
      volume.restrict (Set.Icc (0 : ℝ) 1) A
        = ∫⁻ x in A, f x ∂(Measure.count.restrict (Set.Icc (0 : ℝ) 1)) := by
  refine ⟨?_, ?_, ?_⟩
  · intro hσ
    have hfin : ∀ n, (spanningSets (Measure.count.restrict (Set.Icc (0 : ℝ) 1)) n
        ∩ Set.Icc (0 : ℝ) 1).Finite := by
      intro n
      have h1 := measure_spanningSets_lt_top (Measure.count.restrict (Set.Icc (0 : ℝ) 1)) n
      rw [Measure.restrict_apply (measurableSet_spanningSets _ n)] at h1
      exact Measure.count_apply_lt_top.mp h1
    have hcount : (Set.Icc (0 : ℝ) 1).Countable := by
      have : Set.Icc (0 : ℝ) 1 = ⋃ n, (spanningSets
          (Measure.count.restrict (Set.Icc (0 : ℝ) 1)) n ∩ Set.Icc (0 : ℝ) 1) := by
        rw [← Set.iUnion_inter, iUnion_spanningSets, Set.univ_inter]
      rw [this]
      exact Set.countable_iUnion fun n => (hfin n).countable
    rw [Cardinal.Real.Icc_countable_iff] at hcount
    norm_num at hcount
  · intro A hA
    rw [Measure.restrict_apply' measurableSet_Icc] at hA ⊢
    rw [Measure.count_eq_zero_iff] at hA
    rw [hA, measure_empty]
  · rintro ⟨f, hf, hfA⟩
    have hzero : ∀ x ∈ Set.Icc (0 : ℝ) 1, f x = 0 := by
      intro x hx
      have h := hfA {x} (measurableSet_singleton x)
      simp only [lintegral_singleton, Measure.restrict_apply' measurableSet_Icc,
        Set.singleton_inter_of_mem hx, Measure.count_singleton, mul_one,
        Real.volume_singleton] at h
      exact h.symm
    have h := hfA (Set.Icc (0 : ℝ) 1) measurableSet_Icc
    rw [setLIntegral_congr_fun measurableSet_Icc (g := fun _ => 0) (fun x hx => hzero x hx),
      lintegral_zero, Measure.restrict_apply' measurableSet_Icc, Set.inter_self,
      Real.volume_Icc] at h
    norm_num at h

/-! Worked numbers: the loaded die Q against the fair die P (1/6 per face). -/

/-- The loaded die's probabilities, faces 1 to 6. -/
def loadedDie : Fin 6 → ℚ := ![1/10, 1/10, 1/10, 1/10, 2/10, 4/10]

/-- The card's density f = (0.6, 0.6, 0.6, 0.6, 1.2, 2.4), as fractions. -/
def dieDensity : Fin 6 → ℚ := ![3/5, 3/5, 3/5, 3/5, 6/5, 12/5]

-- factors: Q(face) ÷ (1/6) on faces 1 to 4, 5 and 6
example : (1/10 : ℚ) / (1/6) = 3/5 := by norm_num
example : (2/10 : ℚ) / (1/6) = 6/5 := by norm_num
example : (4/10 : ℚ) / (1/6) = 12/5 := by norm_num
-- the event "even" (faces 2, 4, 6)
example : (3/5 + 3/5 + 12/5 : ℚ) * (1/6) = 1/10 + 1/10 + 4/10 := by norm_num
-- the recipe after 8 rounds collects the whole loaded die
example : (4 * (3/5) + 6/5 + 12/5 : ℚ) * (1/6) = 1 := by norm_num
-- the L2 route on face 6: h = 0.4 / (1/6 + 0.4), and h / (1 - h) = 2.4
example : let h : ℚ := (4/10) / (1/6 + 4/10); h / (1 - h) = 12/5 := by norm_num
-- the density reproduces the loaded die on all 64 events
example : ∀ A : Finset (Fin 6), ∑ i ∈ A, dieDensity i * (1/6) = ∑ i ∈ A, loadedDie i := by
  intro A
  refine Finset.sum_congr rfl fun i _ => ?_
  fin_cases i <;> simp [dieDensity, loadedDie] <;> norm_num

#print axioms absolutely_continuous_iff_exists_density
#print axioms density_unique_ae
#print axioms volume_Icc_no_density_against_count
