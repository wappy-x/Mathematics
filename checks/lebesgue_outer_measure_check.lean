-- Outer measure: the cheapest total length of a list of open intervals covering a set never shrinks when the set grows, is at most the sum over a list of pieces, gives every bounded interval its length, gives every countable set 0, and gives the 3 m fence without its 100 rust spots exactly 3.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

open Set ENNReal

/-- The card's outer measure: over every list `(c k, d k)` of open intervals whose union contains
`A`, take the total length `∑ (d k - c k)`, and take the infimum of those totals. Totals may be
infinite; an interval with `d k ≤ c k` is empty and has length 0, which pads finite lists. -/
noncomputable def lambdaStar (A : Set ℝ) : ℝ≥0∞ :=
  ⨅ (c : ℕ → ℝ) (d : ℕ → ℝ) (_ : A ⊆ ⋃ k, Ioo (c k) (d k)), ∑' k, ENNReal.ofReal (d k - c k)

theorem lambdaStar_eq_volume (A : Set ℝ) : lambdaStar A = MeasureTheory.volume A := by
  apply le_antisymm
  · have hv : MeasureTheory.volume A = StieltjesFunction.id.outer A := by
      rw [Real.volume_eq_stieltjes_id, StieltjesFunction.measure]
      rfl
    rw [hv, StieltjesFunction.outer, MeasureTheory.OuterMeasure.ofFunction_apply]
    refine le_iInf₂ fun t ht => ?_
    refine ENNReal.le_of_forall_pos_le_add fun ε hε hlt => ?_
    have hε2 : ((ε : ℝ≥0∞) / 2) ≠ 0 := by
      simp [hε.ne']
    obtain ⟨ε', hε'pos, hε'sum⟩ := ENNReal.exists_pos_sum_of_countable hε2 ℕ
    have key : ∀ n, ∃ a b : ℝ, t n ⊆ Ioc a b ∧
        ENNReal.ofReal (b - a) < StieltjesFunction.id.length (t n) + ε' n := by
      intro n
      have hfin : StieltjesFunction.id.length (t n) ≠ ∞ :=
        ne_top_of_tsum_ne_top hlt.ne n
      have hlt' := ENNReal.lt_add_right hfin (ENNReal.coe_ne_zero.2 (hε'pos n).ne')
      rw [StieltjesFunction.length_eq] at hlt'
      obtain ⟨a, ha⟩ := iInf_lt_iff.1 hlt'
      obtain ⟨b, hb⟩ := iInf_lt_iff.1 ha
      obtain ⟨hs, hab⟩ := iInf_lt_iff.1 hb
      refine ⟨a, b, ?_, ?_⟩
      · intro x hx
        exact hs ⟨hx, fun h => not_isBot x h⟩
      · rw [StieltjesFunction.length_eq]
        simpa using hab
    choose a b hsub hlen using key
    have hcover : A ⊆ ⋃ k, Ioo (a k) (b k + ε' k) := by
      intro x hx
      obtain ⟨n, hn⟩ := mem_iUnion.1 (ht hx)
      have := hsub n hn
      exact mem_iUnion.2 ⟨n, this.1, by linarith [this.2, (NNReal.coe_pos.2 (hε'pos n))]⟩
    calc lambdaStar A ≤ ∑' k, ENNReal.ofReal ((b k + ε' k) - a k) :=
          iInf_le_of_le a (iInf_le_of_le (fun k => b k + ε' k) (iInf_le_of_le hcover le_rfl))
      _ ≤ ∑' k, (StieltjesFunction.id.length (t k) + ε' k + ε' k) := by
          refine tsum_le_tsum fun k => ?_
          calc ENNReal.ofReal ((b k + ε' k) - a k) = ENNReal.ofReal ((b k - a k) + ε' k) := by
                congr 1; ring
            _ ≤ ENNReal.ofReal (b k - a k) + ENNReal.ofReal (ε' k) := ENNReal.ofReal_add_le
            _ ≤ StieltjesFunction.id.length (t k) + ε' k + ε' k := by
                rw [ENNReal.ofReal_coe_nnreal]
                gcongr
                exact (hlen k).le
      _ = ∑' k, StieltjesFunction.id.length (t k) + (∑' k, (ε' k : ℝ≥0∞) + ∑' k, (ε' k : ℝ≥0∞)) := by
          rw [tsum_add, tsum_add, add_assoc]
      _ ≤ ∑' k, StieltjesFunction.id.length (t k) + ε := by
          gcongr
          calc ∑' k, (ε' k : ℝ≥0∞) + ∑' k, (ε' k : ℝ≥0∞) ≤ (ε : ℝ≥0∞) / 2 + (ε : ℝ≥0∞) / 2 := by
                exact add_le_add hε'sum.le hε'sum.le
            _ = ε := ENNReal.add_halves _
  · refine le_iInf fun c => le_iInf fun d => le_iInf fun h => ?_
    calc MeasureTheory.volume A ≤ MeasureTheory.volume (⋃ k, Ioo (c k) (d k)) := MeasureTheory.measure_mono h
      _ ≤ ∑' k, MeasureTheory.volume (Ioo (c k) (d k)) := MeasureTheory.measure_iUnion_le _
      _ = ∑' k, ENNReal.ofReal (d k - c k) := by simp [Real.volume_Ioo]

#print axioms lambdaStar_eq_volume

/-- Every set of real numbers gets a size, the cheapest total length of a list of open intervals
covering it. This size never shrinks when the set grows, never exceeds the sum of the sizes of a
list of pieces, and gives an interval from `a` to `b` its length `b - a`, closed, open or
half-open. -/
theorem outer_measure_monotone_subadditive_interval_length :
    (∀ A B : Set ℝ, A ⊆ B → lambdaStar A ≤ lambdaStar B) ∧
    (∀ A : ℕ → Set ℝ, lambdaStar (⋃ n, A n) ≤ ∑' n, lambdaStar (A n)) ∧
    (∀ a b : ℝ,
      lambdaStar (Icc a b) = ENNReal.ofReal (b - a) ∧
      lambdaStar (Ioo a b) = ENNReal.ofReal (b - a) ∧
      lambdaStar (Ico a b) = ENNReal.ofReal (b - a) ∧
      lambdaStar (Ioc a b) = ENNReal.ofReal (b - a)) := by
  simp only [lambdaStar_eq_volume]
  refine ⟨fun A B h => MeasureTheory.measure_mono h, fun A => MeasureTheory.measure_iUnion_le A, fun a b => ?_⟩
  simp [Real.volume_Icc, Real.volume_Ioo, Real.volume_Ico, Real.volume_Ioc]

/-- A point, a finite set and a countable set (such as the rationals in [0, 1]) each have outer
measure 0. -/
theorem countable_set_outer_measure_zero (A : Set ℝ) (hA : A.Countable) :
    lambdaStar A = 0 := by
  rw [lambdaStar_eq_volume]
  exact hA.measure_zero _

/-- The fence [0, 3] with its 100 rust spots at 0.03, 0.06, ..., 3 taken out still has outer
measure 3: removing the spots costs nothing. -/
theorem fence_minus_spots_outer_measure :
    lambdaStar (Icc (0 : ℝ) 3 \ ((fun k : ℕ => (3 * k : ℝ) / 100) '' Icc 1 100)) = 3 := by
  rw [lambdaStar_eq_volume, MeasureTheory.measure_sdiff_null (((Set.finite_Icc 1 100).image _).measure_zero _),
    Real.volume_Icc]
  norm_num

/- The card's worked numbers, in whole micrometres (1 m = 1000000 um), as its code counts them. -/

-- The cover (-0.001, 3.001) of the fence totals 3.002 m.
example : (3001000 : ℤ) - (-1000) = 3002000 := by norm_num

-- 100 spot intervals of 0.0001 m each total 0.01 m.
example : 100 * ((50 : ℤ) - (-50)) = 10000 := by norm_num

-- The gap cover: (-0.001, 0.03) plus the 99 gaps between spots totals 3.001 m.
example : ((30000 : ℤ) - (-1000)) + ∑ k ∈ Finset.Icc (2 : ℕ) 100, ((30000 * k : ℤ) - 30000 * (k - 1))
    = 3001000 := by norm_num [Finset.sum_Icc_succ_top]

-- Subadditivity's lower bound for the fence minus the spots: 3 - 0.01 = 2.99 m.
example : (3000000 : ℤ) - 10000 = 2990000 := by norm_num

-- Shrunk allowances: gap cover 3.000001 m above, 3 - 0.0002 = 2.9998 m below.
example : ((30000 : ℤ) - (-1)) + 99 * 30000 = 3000001 ∧ (3000000 : ℤ) - 100 * 2 = 2999800 := by
  norm_num

-- The rational cover: 0.01/2 + 0.01/4 + ... + 0.01/2^n = 0.01 - 0.01/2^n, for n = 10, 20, 40.
example : ∑ k ∈ Finset.Icc 1 10, (1 : ℚ) / (100 * 2 ^ k) = 1 / 100 - 1 / (100 * 2 ^ 10) := by
  norm_num [Finset.sum_Icc_succ_top]
example : ∑ k ∈ Finset.Icc 1 20, (1 : ℚ) / (100 * 2 ^ k) = 1 / 100 - 1 / (100 * 2 ^ 20) := by
  norm_num [Finset.sum_Icc_succ_top]
example : ∑ k ∈ Finset.Icc 1 40, (1 : ℚ) / (100 * 2 ^ k) = 1 / 100 - 1 / (100 * 2 ^ 40) := by
  norm_num [Finset.sum_Icc_succ_top]

-- The picture: the chain (-0.2, 1.1), (0.8, 1.9), (1.5, 2.6), (2.4, 3.3) totals 4.4 m,
-- and all five tapes, with (1, 1.4), total 4.8 m.
example : ((1100000 : ℤ) - (-200000)) + (1900000 - 800000) + (2600000 - 1500000)
    + (3300000 - 2400000) = 4400000 := by norm_num
example : ((1100000 : ℤ) - (-200000)) + (1900000 - 800000) + (1400000 - 1000000)
    + (2600000 - 1500000) + (3300000 - 2400000) = 4800000 := by norm_num

-- Mistake 2: (0, 2) and (1, 3) added as if separate give 2 + 2 = 4 m for the 3 m union (0, 3).
example : ((2 : ℤ) - 0) + (3 - 1) = 4 ∧ (3 : ℤ) - 0 = 3 := by norm_num

#print axioms outer_measure_monotone_subadditive_interval_length
#print axioms countable_set_outer_measure_zero
#print axioms fence_minus_spots_outer_measure
