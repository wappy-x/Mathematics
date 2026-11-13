-- Measures: every weighted count with weights of zero or more is a measure, dividing a measure by a finite non-zero total gives a probability measure, and the finite-or-not rule on the whole numbers adds over two disjoint sets but not over a countable list.
import Mathlib.MeasureTheory.Measure.Dirac.Basic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory Set
open scoped ENNReal

/-- Every weighted count is a measure. On any space where every subset is allowed, give each
point `ω` a weight `w ω` of zero or more (possibly infinite). Then the rule "the size of a set is
the total weight of the points inside it" is a measure: there is a measure `μ` with
`μ A = ∑_{ω ∈ A} w ω` for every set `A`. For an infinite set the sum is the least upper bound of
the sums over its finite subsets, which is how Mathlib's `tsum` on `[0, ∞]` is defined. -/
theorem weighted_count_is_measure {Ω : Type*} [MeasurableSpace Ω]
    (hall : ∀ s : Set Ω, MeasurableSet s) (w : Ω → ℝ≥0∞) :
    ∃ μ : Measure Ω, ∀ A : Set Ω, μ A = ∑' ω : A, w ω := by
  classical
  refine ⟨Measure.sum (fun ω => w ω • Measure.dirac ω), fun A => ?_⟩
  rw [Measure.sum_apply _ (hall A), tsum_subtype A w]
  congr 1
  funext ω
  rw [Measure.smul_apply, Measure.dirac_apply' _ (hall A), smul_eq_mul]
  by_cases h : ω ∈ A <;> simp [h]

/-- Dividing by a finite total gives a probability. If `μ` is a measure whose total `μ(Ω)` is
finite and not zero, then the rule `P(A) = μ(A) / μ(Ω)` is a probability measure. -/
theorem divide_by_total_is_probability {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (h0 : μ univ ≠ 0) (htop : μ univ ≠ ∞) :
    ∃ P : Measure Ω, IsProbabilityMeasure P ∧ ∀ A : Set Ω, P A = μ A / μ univ := by
  refine ⟨(μ univ)⁻¹ • μ, ⟨?_⟩, fun A => ?_⟩
  · rw [Measure.smul_apply, smul_eq_mul, ENNReal.inv_mul_cancel h0 htop]
  · rw [Measure.smul_apply, smul_eq_mul, div_eq_mul_inv, mul_comm]

open scoped Classical in
/-- Countable adding is strictly stronger than finite adding. On the whole numbers, the
finite-or-not rule (size 0 for a finite set, `∞` for an infinite one) adds over any two disjoint
sets, but it does not add over every countable list of disjoint sets: the singletons
`{0}, {1}, {2}, …` each have size 0, while their union, all the whole numbers, has size `∞`. -/
theorem finite_or_not_rule_finitely_but_not_countably_additive :
    let ν : Set ℕ → ℝ≥0∞ := fun A => if A.Finite then 0 else ∞
    (∀ A B : Set ℕ, Disjoint A B → ν (A ∪ B) = ν A + ν B) ∧
      ¬ (∀ A : ℕ → Set ℕ, Pairwise (Function.onFun Disjoint A) → ν (⋃ i, A i) = ∑' i, ν (A i)) := by
  intro ν
  refine ⟨fun A B _ => ?_, fun h => ?_⟩
  · simp only [ν, Set.finite_union]
    by_cases hA : A.Finite <;> by_cases hB : B.Finite <;> simp [hA, hB]
  · have hd : Pairwise (Function.onFun Disjoint (fun i : ℕ => ({i} : Set ℕ))) := by
      intro i j hij
      simp [Function.onFun, hij]
    have := h (fun i => {i}) hd
    have hu : (⋃ i : ℕ, ({i} : Set ℕ)) = univ := by
      ext n; simp
    simp only [ν, hu, Set.finite_singleton, ite_true, tsum_zero] at this
    have hinf : ¬ (univ : Set ℕ).Finite := Set.infinite_univ
    simp [hinf] at this

/-! The card's worked numbers. Districts are `0 = N`, `1 = C`, `2 = S`. -/

-- Head count of N,S: 40,000 + 10,000 = 50,000; districts: 1 + 1 = 2; area: 12 + 8 = 20 sq km;
-- town hall (point mass at C): 0 + 0 = 0.
example : ∑ i ∈ ({0, 2} : Finset (Fin 3)), ![40000, 25000, 10000] i = 50000 := by decide
example : ∑ i ∈ ({0, 2} : Finset (Fin 3)), ![1, 1, 1] i = 2 := by decide
example : ∑ i ∈ ({0, 2} : Finset (Fin 3)), ![12, 5, 8] i = 20 := by decide
example : ∑ i ∈ ({0, 2} : Finset (Fin 3)), ![0, 1, 0] i = 0 := by decide

-- N,S and its complement C add to the city: 50,000 + 25,000 = 75,000 residents, 20 + 5 = 25 sq km.
example : ∑ i : Fin 3, ![40000, 25000, 10000] i = 50000 + 25000 ∧
    ∑ i : Fin 3, ![12, 5, 8] i = 20 + 5 := by decide

-- Share of residents of N,S: 50,000 / 75,000 = 2/3; the city's share is 1.
example : (50000 : ℚ) / 75000 = 2 / 3 ∧ (75000 : ℚ) / 75000 = 1 := by norm_num

-- Overlapping pieces do not add: residents of N,C plus residents of C,S is 100,000, not 75,000.
example : (40000 + 25000) + (25000 + 10000) = 100000 ∧ 100000 ≠ 75000 := by decide

-- Length of [-3, 3) is 6, the sum of 6 unit intervals.
example : volume (Ico (-3 : ℝ) 3) = 6 := by
  rw [Real.volume_Ico]; norm_num

#print axioms weighted_count_is_measure
#print axioms divide_by_total_is_probability
#print axioms finite_or_not_rule_finitely_but_not_countably_additive
