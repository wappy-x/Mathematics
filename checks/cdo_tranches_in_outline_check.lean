-- Tranches: a tranche's loss is a call spread on the pool's loss, its expected loss is the area under the pool's "loses more than x" curve between its two floors, and the tranches' losses add back to the pool's loss.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Probability.Notation
import Mathlib.MeasureTheory.Integral.Prod

open MeasureTheory

lemma tranche_aux_inner (A D c : ℝ) (hAD : A < D) :
    ∫ x in Set.Ioc A D, (if x < c then (1:ℝ) else 0) = max (c - A) 0 - max (c - D) 0 := by
  have hf : (fun x : ℝ => if x < c then (1:ℝ) else 0) = (Set.Iio c).indicator 1 := by
    funext x; simp [Set.indicator_apply]
  rw [hf, integral_indicator_one measurableSet_Iio, measureReal_restrict_apply measurableSet_Iio]
  rcases le_or_gt c A with h | h
  · have : Set.Iio c ∩ Set.Ioc A D = ∅ := by
      ext x; simp only [Set.mem_inter_iff, Set.mem_Iio, Set.mem_Ioc, Set.mem_empty_iff_false,
        iff_false, not_and]
      intro h1 h2; linarith
    rw [this, measureReal_empty, max_eq_right (by linarith), max_eq_right (by linarith)]; ring
  rcases le_or_gt c D with h' | h'
  · have : Set.Iio c ∩ Set.Ioc A D = Set.Ioo A c := by
      ext x; simp only [Set.mem_inter_iff, Set.mem_Iio, Set.mem_Ioc, Set.mem_Ioo]
      constructor
      · rintro ⟨h1, h2, h3⟩; exact ⟨h2, h1⟩
      · rintro ⟨h1, h2⟩; exact ⟨h2, h1, by linarith⟩
    rw [this, Real.volume_real_Ioo_of_le h.le, max_eq_left (by linarith),
      max_eq_right (by linarith)]; ring
  · have : Set.Iio c ∩ Set.Ioc A D = Set.Ioc A D := by
      ext x; simp only [Set.mem_inter_iff, Set.mem_Iio, Set.mem_Ioc]
      constructor
      · rintro ⟨h1, h2⟩; exact h2
      · rintro ⟨h1, h2⟩; exact ⟨by linarith, h1, h2⟩
    rw [this, Real.volume_real_Ioc_of_le hAD.le, max_eq_left (by linarith),
      max_eq_left (by linarith)]; ring

#print axioms tranche_aux_inner

/-- The expected loss of the tranche from attachment point `A` to detachment point `D`, as a share
of its width, is the area under the pool's "chance of losing more than x" curve from `A` to `D`,
divided by the width: `E[((L - A)⁺ - (L - D)⁺) / (D - A)] = (1 / (D - A)) ∫_A^D P(L > x) dx`,
for any pool loss `L` on any probability space. -/
theorem tranche_expected_loss_eq_area_under_loss_curve
    {Ω : Type*} [MeasurableSpace Ω] (P : Measure Ω) [IsProbabilityMeasure P]
    (L : Ω → ℝ) (hL : Measurable L) (A D : ℝ) (hAD : A < D) :
    ∫ ω, (max (L ω - A) 0 - max (L ω - D) 0) / (D - A) ∂P
      = (1 / (D - A)) * ∫ x in A..D, P.real {ω | x < L ω} := by
  rw [integral_div, intervalIntegral.integral_of_le hAD.le, div_eq_inv_mul, one_div]
  congr 1
  let f : Ω → ℝ → ℝ := fun ω x => if x < L ω then (1:ℝ) else 0
  have hS : MeasurableSet {p : Ω × ℝ | p.2 < L p.1} :=
    measurableSet_lt measurable_snd (hL.comp measurable_fst)
  have hint : Integrable (Function.uncurry f) (P.prod (volume.restrict (Set.Ioc A D))) := by
    have : Function.uncurry f = {p : Ω × ℝ | p.2 < L p.1}.indicator 1 := by
      funext p; simp [f, Function.uncurry, Set.indicator_apply]
    rw [this]
    exact (integrable_const (1:ℝ)).indicator hS
  have h1 : ∀ ω, max (L ω - A) 0 - max (L ω - D) 0 = ∫ x in Set.Ioc A D, f ω x := by
    intro ω; exact (tranche_aux_inner A D (L ω) hAD).symm
  have h2 : ∀ x, P.real {ω | x < L ω} = ∫ ω, f ω x ∂P := by
    intro x
    have : (fun ω => f ω x) = {ω | x < L ω}.indicator 1 := by
      funext ω; simp [f, Set.indicator_apply]
    rw [this, integral_indicator_one (measurableSet_lt measurable_const hL)]
  simp_rw [h1, h2]
  exact integral_integral_swap hint

/-- A tranche is a call spread on the pool's loss: the losses above the attachment point minus the
losses above the detachment point equal the losses above the attachment point, capped at the
tranche's width: `(L - A)⁺ - (L - D)⁺ = min ((L - A)⁺) (D - A)`. -/
theorem tranche_loss_eq_call_spread (L A D : ℝ) (hAD : A < D) :
    max (L - A) 0 - max (L - D) 0 = min (max (L - A) 0) (D - A) := by
  simp only [max_def, min_def]
  split_ifs <;> linarith

/-- The tranches add back to the pool: for floors `0 = a 0 < a 1 < ... < a n = 1` and any pool
loss `L` between 0 and 1, the tranche widths times the tranches' losses (each as a share of its
width) sum to `L`. -/
theorem tranches_add_back_to_pool_loss (n : ℕ) (a : ℕ → ℝ) (h0 : a 0 = 0) (hn : a n = 1)
    (hmono : ∀ k < n, a k < a (k + 1)) (L : ℝ) (hL0 : 0 ≤ L) (hL1 : L ≤ 1) :
    ∑ k ∈ Finset.range n,
        (a (k + 1) - a k) * ((max (L - a k) 0 - max (L - a (k + 1)) 0) / (a (k + 1) - a k))
      = L := by
  have : ∀ k ∈ Finset.range n,
      (a (k + 1) - a k) * ((max (L - a k) 0 - max (L - a (k + 1)) 0) / (a (k + 1) - a k))
        = max (L - a k) 0 - max (L - a (k + 1)) 0 := by
    intro k hk
    have := hmono k (Finset.mem_range.mp hk)
    field_simp [sub_ne_zero.mpr this.ne']
  rw [Finset.sum_congr rfl this, Finset.sum_range_sub' (fun k => max (L - a k) 0), h0, hn,
    max_eq_left (by linarith), max_eq_right (by linarith)]
  ring

-- Step 1's checks, in percentage points of the pool: the 3-to-7 tranche at pool losses 5 and 9.
example : max ((5 : ℤ) - 3) 0 - max ((5 : ℤ) - 7) 0 = 2 := by decide
example : max ((9 : ℤ) - 3) 0 - max ((9 : ℤ) - 7) 0 = 4 := by decide
-- As a share of its 4-point width, the junior mezzanine loses 50% at a pool loss of 5%.
example : (max ((5 : ℚ) - 3) 0 - max ((5 : ℚ) - 7) 0) / (7 - 3) = 1 / 2 := by norm_num
-- The chart: equity (0 to 3) loses 1/3 of its size at a pool loss of 1%, all of it from 3% up.
example : (max ((1 : ℚ) - 0) 0 - max ((1 : ℚ) - 3) 0) / (3 - 0) = 1 / 3 := by norm_num
example : (max ((3 : ℚ) - 0) 0 - max ((3 : ℚ) - 3) 0) / (3 - 0) = 1 := by norm_num
-- The senior tranche (10 to 100) loses 1/90 of its size at 11% and 2/90 at 12%.
example : (max ((11 : ℚ) - 10) 0 - max ((11 : ℚ) - 100) 0) / (100 - 10) = 1 / 90 := by norm_num
example : (max ((12 : ℚ) - 10) 0 - max ((12 : ℚ) - 100) 0) / (100 - 10) = 2 / 90 := by norm_num
-- Adding back with the card's floors 0, 3, 7, 10, 100: a pool loss of 5 points splits 3 + 2 + 0 + 0.
example :
    (max ((5 : ℤ) - 0) 0 - max (5 - 3) 0) + (max ((5 : ℤ) - 3) 0 - max (5 - 7) 0)
      + (max ((5 : ℤ) - 7) 0 - max (5 - 10) 0) + (max ((5 : ℤ) - 10) 0 - max (5 - 100) 0) = 5 := by
  decide

#print axioms tranche_expected_loss_eq_area_under_loss_curve
#print axioms tranche_loss_eq_call_spread
#print axioms tranches_add_back_to_pool_loss
