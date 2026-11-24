-- Measure-preserving maps and Poincare recurrence: a map that keeps the size of every preimage on a space of finite size brings almost every point of any measurable set A back to A infinitely often, and the doubling map x ↦ 2x mod 1 keeps length on [0, 1).
import Mathlib.Dynamics.Ergodic.MeasurePreserving
import Mathlib.Dynamics.Ergodic.Conservative
import Mathlib.MeasureTheory.Function.Floor
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Data.Nat.Fib.Basic

open MeasureTheory Set

/-- Helper: preimage of [a, b) under the doubling map, inside [0, 1). -/
theorem doubling_preimage_Ico (a b : ℝ) (ha : 0 ≤ a) (hb : b ≤ 1) :
      Ico (0 : ℝ) 1 ∩ (fun x : ℝ => Int.fract (2 * x)) ⁻¹' Ico a b =
        Ico (a / 2) (b / 2) ∪ Ico ((a + 1) / 2) ((b + 1) / 2) := by
  ext x
  simp only [mem_inter_iff, mem_Ico, mem_preimage, mem_union]
  by_cases hx : x < 1 / 2
  · by_cases h0 : 0 ≤ x
    · have hf : Int.fract (2 * x) = 2 * x := Int.fract_eq_self.2 ⟨by linarith, by linarith⟩
      rw [hf]
      constructor
      · rintro ⟨-, h1, h2⟩; left; constructor <;> linarith
      · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩)
        · refine ⟨⟨h0, by linarith⟩, by linarith, by linarith⟩
        · exfalso; linarith
    · constructor
      · rintro ⟨⟨h, _⟩, _⟩; exact absurd h h0
      · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩) <;> exfalso <;> linarith
  · push Not at hx
    by_cases h1 : x < 1
    · have hf : Int.fract (2 * x) = 2 * x - 1 :=
        Int.fract_eq_iff.2 ⟨by linarith, by linarith, 1, by push_cast; ring⟩
      rw [hf]
      constructor
      · rintro ⟨-, h3, h4⟩; right; constructor <;> linarith
      · rintro (⟨h3, h4⟩ | ⟨h3, h4⟩)
        · exfalso; linarith
        · refine ⟨⟨by linarith, by linarith⟩, by linarith, by linarith⟩
    · push Not at h1
      constructor
      · rintro ⟨⟨_, h⟩, _⟩; exact absurd h (not_lt.2 h1)
      · rintro (⟨h3, h4⟩ | ⟨h3, h4⟩) <;> exfalso <;> linarith

#print axioms doubling_preimage_Ico

/-- Poincaré's recurrence theorem. Let T map a measure space X to itself, keep sizes
(T is measurable and every measurable set B has a preimage T⁻¹(B) of the same size as B),
and let the whole space have finite size. Then for every measurable set A, the points of A
that come back to A only finitely often make up a set of size zero:
μ({x ∈ A : Tⁿ(x) ∈ A for only finitely many n}) = 0. -/
theorem poincare_recurrence {X : Type*} [MeasurableSpace X] {μ : Measure X} [IsFiniteMeasure μ]
    {T : X → X} (hT : MeasurePreserving T μ μ) {A : Set X} (hA : MeasurableSet A) :
    μ {x | x ∈ A ∧ {n : ℕ | T^[n] x ∈ A}.Finite} = 0 := by
  rw [measure_eq_zero_iff_ae_notMem]
  filter_upwards [hT.conservative.ae_mem_imp_frequently_image_mem hA.nullMeasurableSet] with x hx
  rintro ⟨hxA, hfin⟩
  exact (Nat.frequently_atTop_iff_infinite.1 (hx hxA)) hfin

/-- The definition of a measure-preserving map, in the card's words: T keeps the measure μ
exactly when T is measurable and, for every measurable set B, the starts that land in B take
up as much room as B itself: μ(T⁻¹(B)) = μ(B). -/
theorem measurePreserving_iff_preimage {X : Type*} [MeasurableSpace X] {μ : Measure X}
    {T : X → X} :
    MeasurePreserving T μ μ ↔
      Measurable T ∧ ∀ B : Set X, MeasurableSet B → μ (T ⁻¹' B) = μ B := by
  constructor
  · intro h
    exact ⟨h.measurable, fun B hB => h.measure_preimage hB.nullMeasurableSet⟩
  · rintro ⟨hm, h⟩
    refine ⟨hm, ?_⟩
    ext B hB
    rw [Measure.map_apply hm hB, h B hB]

/-- The doubling map T(x) = 2x mod 1 on the strip [0, 1). For 0 ≤ a and b ≤ 1, the starts in
[0, 1) that land in [a, b) are the two half-length pieces [a/2, b/2) and [(a+1)/2, (b+1)/2);
and T keeps length on [0, 1). -/
theorem doubling_map_preimage_and_measurePreserving :
    (∀ a b : ℝ, 0 ≤ a → b ≤ 1 →
      Ico (0 : ℝ) 1 ∩ (fun x : ℝ => Int.fract (2 * x)) ⁻¹' Ico a b =
        Ico (a / 2) (b / 2) ∪ Ico ((a + 1) / 2) ((b + 1) / 2)) ∧
    MeasurePreserving (fun x : ℝ => Int.fract (2 * x))
      (volume.restrict (Ico (0 : ℝ) 1)) (volume.restrict (Ico (0 : ℝ) 1)) := by
  refine ⟨doubling_preimage_Ico, ?_⟩
  have hm : Measurable (fun x : ℝ => Int.fract (2 * x)) :=
    measurable_fract.comp (measurable_const_mul 2)
  refine ⟨hm, ?_⟩
  have : IsFiniteMeasure (volume.restrict (Ico (0 : ℝ) 1)) := by
    rw [isFiniteMeasure_restrict]; simp
  have key : ∀ a b : ℝ, (volume.restrict (Ico (0 : ℝ) 1)).map (fun x : ℝ => Int.fract (2 * x))
      (Ico a b) = volume.restrict (Ico (0 : ℝ) 1) (Ico a b) := by
    intro a b
    have hrange : (fun x : ℝ => Int.fract (2 * x)) ⁻¹' Ico a b =
        (fun x : ℝ => Int.fract (2 * x)) ⁻¹' Ico (max a 0) (min b 1) := by
      ext x
      simp only [mem_preimage, mem_Ico, max_le_iff, lt_min_iff]
      have h0 := Int.fract_nonneg (2 * x)
      have h1 := Int.fract_lt_one (2 * x)
      tauto
    rw [Measure.map_apply hm measurableSet_Ico, Measure.restrict_apply measurableSet_Ico,
      Measure.restrict_apply (hm measurableSet_Ico), hrange, inter_comm,
      doubling_preimage_Ico _ _ (le_max_right _ _) (min_le_right _ _), Ico_inter_Ico]
    set a' := max a 0
    set b' := min b 1
    have ha' : 0 ≤ a' := le_max_right _ _
    have hb' : b' ≤ 1 := min_le_right _ _
    rcases le_total a' b' with h | h
    · rw [measure_union (Ico_disjoint_Ico.2 (by
          rw [min_eq_left (by linarith), max_eq_right (by linarith)]; linarith)) measurableSet_Ico]
      simp only [Real.volume_Ico]
      rw [← ENNReal.ofReal_add (by linarith) (by linarith)]
      congr 1
      ring
    · rw [Ico_eq_empty_of_le (by linarith : b' / 2 ≤ a' / 2),
        Ico_eq_empty_of_le (by linarith : (b' + 1) / 2 ≤ (a' + 1) / 2), Ico_eq_empty_of_le h]
      simp
  refine Measure.ext_of_Ico_finite _ _ ?_ (fun a b _ => key a b)
  rw [Measure.map_apply hm MeasurableSet.univ, preimage_univ]

-- Preimage of [0.2, 0.5) under the doubling map: [0.1, 0.25) and [0.6, 0.75), lengths 0.15 + 0.15 = 0.3.
example : ((1 : ℚ) / 5) / 2 = 1 / 10 ∧ ((1 : ℚ) / 2) / 2 = 1 / 4 ∧
    ((1 : ℚ) / 5 + 1) / 2 = 3 / 5 ∧ ((1 : ℚ) / 2 + 1) / 2 = 3 / 4 := by norm_num
example : ((1 : ℚ) / 4 - 1 / 10) + (3 / 4 - 3 / 5) = 1 / 2 - 1 / 5 := by norm_num

-- The orbit of 1/3: 2 × 1/3 = 2/3, then 2 × 2/3 − 1 = 1/3.
example : 2 * ((1 : ℚ) / 3) = 2 / 3 ∧ 2 * ((2 : ℚ) / 3) - 1 = 1 / 3 := by norm_num

-- Shift with p = 0.3: block 10 has chance 0.3 × 0.7 = 0.21; blocks 010 and 110 give 0.147 + 0.063 = 0.21.
example : (3 : ℚ) / 10 * (7 / 10) = 21 / 100 := by norm_num
example : (7 : ℚ) / 10 * (21 / 100) + 3 / 10 * (21 / 100) = 21 / 100 := by norm_num
example : (7 : ℚ) / 10 * (21 / 100) = 147 / 1000 ∧ (3 : ℚ) / 10 * (21 / 100) = 63 / 1000 := by
  norm_num

-- First returns to [0, 0.5): shares 2^-n for n = 1..6, and 1 − 2^-11 back by round 11.
example : ∑ n ∈ Finset.Icc 1 6, ((1 : ℚ) / 2) ^ n = 63 / 64 := by
  simp [Finset.sum_Icc_succ_top]; norm_num
example : ∑ n ∈ Finset.Icc 1 11, ((1 : ℚ) / 2) ^ n = 1 - (1 / 2) ^ 11 := by
  simp [Finset.sum_Icc_succ_top]; norm_num

-- Share of [0, 0.25) not back by round n is Fib(n+1)/2^n: 2/4, 5/16, 34/256, 1597/65536.
example : Nat.fib 3 = 2 ∧ Nat.fib 5 = 5 ∧ Nat.fib 9 = 34 ∧ Nat.fib 17 = 1597 := by decide

-- The rotation by √2 − 1 at round 70: 99² − 2 × 70² = 1.
example : (99 : ℤ) ^ 2 - 2 * 70 ^ 2 = 1 := by norm_num

-- Pigeonhole: 101 arcs of width 0.01 have total width 1.01 > 1.
example : (101 : ℚ) * (1 / 100) = 101 / 100 ∧ (1 : ℚ) < 101 / 100 := by norm_num

#print axioms poincare_recurrence
#print axioms measurePreserving_iff_preimage
#print axioms doubling_map_preimage_and_measurePreserving
