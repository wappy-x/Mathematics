-- Fatou's lemma: for measurable functions with values in [0, ∞] on any measure space, the integral of the lower limit is at most the lower limit of the integrals, the reverse inequality holds for upper limits under one roof of finite integral, and the card's spotlight shows the inequality can be strict.
import Mathlib.MeasureTheory.Integral.Lebesgue.Add
import Mathlib.MeasureTheory.Integral.Lebesgue.DominatedConvergence
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic

open MeasureTheory Filter Set
open scoped ENNReal

/-- Fatou's lemma. On any measure space, if every `f n` is measurable with values in
[0, ∞], then the integral of the eventual floor (the lower limit taken point by point)
is at most the eventual floor of the integrals: in a limit, total can leak away but
never appear from nowhere. Infinite values are allowed on both sides. -/
theorem integral_liminf_le_liminf_integral {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (f : ℕ → Ω → ℝ≥0∞) (hf : ∀ n, Measurable (f n)) :
    ∫⁻ x, liminf (fun n => f n x) atTop ∂μ ≤ liminf (fun n => ∫⁻ x, f n x ∂μ) atTop := by
  exact lintegral_liminf_le hf

/-- Reverse Fatou. If every `f n` is measurable and lies between 0 and one roof `G`
whose integral is finite, then the eventual ceiling of the integrals is at most the
integral of the eventual ceiling (the upper limit taken point by point). -/
theorem limsup_integral_le_integral_limsup_of_roof {Ω : Type*} [MeasurableSpace Ω]
    (μ : Measure Ω) (f : ℕ → Ω → ℝ≥0∞) (G : Ω → ℝ≥0∞) (hf : ∀ n, Measurable (f n))
    (hroof : ∀ n x, f n x ≤ G x) (hG : ∫⁻ x, G x ∂μ < ∞) :
    limsup (fun n => ∫⁻ x, f n x ∂μ) atTop ≤ ∫⁻ x, limsup (fun n => f n x) atTop ∂μ := by
  exact limsup_lintegral_le G hf (fun n => Filter.Eventually.of_forall (hroof n)) hG.ne

/-- The spotlight on a stage [0, 1] measured by length: frame n lights the strip
[1 - 1/n, 1) at brightness n. Every frame from frame 1 on carries total 1, yet the
lower limit at every seat is 0, so the integral of the lower limit is 0 while the
lower limit of the integrals is 1. The watt leaks away, and Fatou's inequality is strict.
(Frame 0 lights the empty strip [1, 1).) -/
theorem spotlight_loses_its_watt :
    let f : ℕ → ℝ → ℝ≥0∞ := fun n x => (Ico (1 - 1 / (n : ℝ)) 1).indicator (fun _ => (n : ℝ≥0∞)) x
    (∀ n : ℕ, 1 ≤ n → ∫⁻ x in Icc (0 : ℝ) 1, f n x = 1) ∧
      ∫⁻ x in Icc (0 : ℝ) 1, liminf (fun n => f n x) atTop = 0 ∧
      liminf (fun n => ∫⁻ x in Icc (0 : ℝ) 1, f n x) atTop = 1 := by
  intro f
  have h1 : ∀ n : ℕ, 1 ≤ n → ∫⁻ x in Icc (0 : ℝ) 1, f n x = 1 := by
    intro n hn
    have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
    simp only [f]
    rw [lintegral_indicator_const measurableSet_Ico, Measure.restrict_apply measurableSet_Ico]
    have hsub : Ico (1 - 1 / (n : ℝ)) 1 ∩ Icc 0 1 = Ico (1 - 1 / (n : ℝ)) 1 := by
      apply inter_eq_left.mpr
      intro x hx
      have : 1 / (n : ℝ) ≤ 1 := by
        rw [div_le_one hnpos]; exact_mod_cast hn
      exact ⟨by linarith [hx.1], hx.2.le⟩
    rw [hsub, Real.volume_Ico]
    have : (1 : ℝ) - (1 - 1 / (n : ℝ)) = (n : ℝ)⁻¹ := by ring
    rw [this, ENNReal.ofReal_inv_of_pos hnpos, ENNReal.ofReal_natCast]
    exact ENNReal.mul_inv_cancel (by exact_mod_cast (by omega : n ≠ 0)) (ENNReal.natCast_ne_top n)
  have h0 : ∀ x : ℝ, liminf (fun n => f n x) atTop = 0 := by
    intro x
    have hev : (fun n => f n x) =ᶠ[atTop] fun _ => 0 := by
      by_cases hx : x < 1
      · obtain ⟨N, hN⟩ := exists_nat_gt (1 / (1 - x))
        filter_upwards [eventually_ge_atTop (N + 1)] with n hn
        simp only [f]
        apply indicator_of_notMem
        intro hmem
        have hx1 : 0 < 1 - x := by linarith
        have hnpos : (0 : ℝ) < n := by
          have : (1 : ℝ) ≤ n := by exact_mod_cast (by omega : 1 ≤ n)
          linarith
        have hNn : (N : ℝ) < n := by exact_mod_cast (by omega : N < n)
        have : 1 / (1 - x) < n := lt_trans hN hNn
        rw [div_lt_iff₀ hx1] at this
        have h2 : 1 - 1 / (n : ℝ) ≤ x := hmem.1
        have h3 : 1 / (n : ℝ) * n = 1 := by field_simp
        nlinarith
      · filter_upwards with n
        simp only [f]
        apply indicator_of_notMem
        intro hmem
        exact hx hmem.2
    rw [liminf_congr hev, liminf_const]
  refine ⟨h1, ?_, ?_⟩
  · simp [h0]
  · have hev : (fun n => ∫⁻ x in Icc (0 : ℝ) 1, f n x) =ᶠ[atTop] fun _ => 1 := by
      filter_upwards [eventually_ge_atTop 1] with n hn
      exact h1 n hn
    rw [liminf_congr hev, liminf_const]

-- Frame n's strip starts at 1 - 1/n: frames 2, 4 and 1000.
example : (1 : ℚ) - 1 / 2 = 1 / 2 := by norm_num
example : (1 : ℚ) - 1 / 4 = 3 / 4 := by norm_num
example : (1 : ℚ) - 1 / 1000 = 999 / 1000 := by norm_num
-- Frame n's total: width 1/n times brightness n is 1, here for frame 1000.
example : (1 : ℚ) / 1000 * 1000 = 1 := by norm_num
-- Light on [0, 9/10] in frame 4: 4 × (9/10 − 3/4) = 3/5 (0.6000 W).
example : (4 : ℚ) * (9 / 10 - 3 / 4) = 3 / 5 := by norm_num
-- Frame 10's strip starts at 9/10, so it puts 0 W on [0, 9/10].
example : (1 : ℚ) - 1 / 10 = 9 / 10 := by norm_num
-- The seat at 9/10 m is lit in frame 10 and dark in frame 11: N = 10.
example : (1 : ℚ) - 1 / 10 ≤ 9 / 10 ∧ ¬ ((1 : ℚ) - 1 / 11 ≤ 9 / 10) := by norm_num
-- House lights at k = 3: h_3 = (1/2)(1 − 1/3) = 1/3 W/m, over [0, 2/3) m gives 2/9 W.
example : (1 / 2 : ℚ) * (1 - 1 / 3) = 1 / 3 := by norm_num
example : (1 / 3 : ℚ) * (1 - 1 / 3) = 2 / 9 := by norm_num
-- With house lights, frame 3 carries h_3 + 1 = 4/3 W (1.3333 W).
example : (1 / 2 : ℚ) * (1 - 1 / 3) + 1 = 4 / 3 := by norm_num
-- Flicker: 2 W/m on half the stage is 1 W; the roof of 2 W/m over 1 m is 2 W.
example : (2 : ℚ) * (1 / 2) = 1 := by norm_num
example : (0 : ℚ) ≤ 1 ∧ (1 : ℚ) ≤ 1 ∧ (1 : ℚ) ≤ 2 := by norm_num
-- Smallest roof over the spotlight, strips 1 to 10: 1/2 + 1/3 + ... + 1/11 = 55991/27720 (2.0199 W).
example : (∑ i ∈ Finset.range 10, (1 : ℚ) / (i + 2)) = 55991 / 27720 := by
  norm_num [Finset.sum_range_succ]
-- The shadow breaks the sign rule: Fatou would read 0 ≤ −1, which is false.
example : ¬ ((0 : ℤ) ≤ -1) := by decide

#print axioms integral_liminf_le_liminf_integral
#print axioms limsup_integral_le_integral_limsup_of_roof
#print axioms spotlight_loses_its_watt
