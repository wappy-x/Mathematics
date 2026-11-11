-- Trig graphs: the wave y = a sin(b(t - c)) + d swings between d - |a| and d + |a|, repeats first after 2π/|b|, rises through its midline at t = c and peaks a quarter period later.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse

open Real

/-- Amplitude, midline and period read off a wave: when neither a nor b is zero, the wave
y = a sin(b(t - c)) + d takes exactly the heights from d - |a| (low water) to d + |a| (high water),
so the amplitude |a| is half the swing and the midline d is its middle; and the shortest
positive shift that lays the wave back on itself is 2π/|b|, so the period is P = 2π/|b|. -/
theorem sine_wave_amplitude_midline_period (a b c d : ℝ) (ha : a ≠ 0) (hb : b ≠ 0) :
    Set.range (fun t : ℝ => a * sin (b * (t - c)) + d) = Set.Icc (d - |a|) (d + |a|) ∧
    IsLeast {P : ℝ | 0 < P ∧ Function.Periodic (fun t : ℝ => a * sin (b * (t - c)) + d) P}
      (2 * π / |b|) := by
  have hab : 0 < |a| := abs_pos.mpr ha
  have hbb : 0 < |b| := abs_pos.mpr hb
  refine ⟨?_, ?_, ?_⟩
  · ext y
    simp only [Set.mem_range, Set.mem_Icc]
    constructor
    · rintro ⟨t, rfl⟩
      have h1 : |a * sin (b * (t - c))| ≤ |a| := by
        rw [abs_mul]
        exact mul_le_of_le_one_right (abs_nonneg a) (abs_sin_le_one _)
      have := abs_le.mp h1
      constructor <;> linarith [this.1, this.2]
    · rintro ⟨h1, h2⟩
      have hle : |(y - d) / a| ≤ 1 := by
        rw [abs_div, div_le_one hab, abs_le]
        constructor <;> linarith
      obtain ⟨hl, hr⟩ := abs_le.mp hle
      refine ⟨arcsin ((y - d) / a) / b + c, ?_⟩
      have : b * (arcsin ((y - d) / a) / b + c - c) = arcsin ((y - d) / a) := by
        field_simp; ring
      rw [this, sin_arcsin hl hr]
      field_simp; ring
  · refine ⟨by positivity, ?_⟩
    intro t
    simp only
    have key : b * (t + 2 * π / |b| - c) = b * (t - c) + (b / |b|) * (2 * π) := by
      field_simp; ring
    rcases lt_or_gt_of_ne hb with h | h
    · rw [key, abs_of_neg h]
      have : b / -b = -1 := by field_simp
      rw [this, neg_one_mul, ← sub_eq_add_neg, sin_sub_two_pi]
    · rw [key, abs_of_pos h, div_self hb, one_mul, sin_add_two_pi]
  · rintro P ⟨hP, hper⟩
    have h := hper (c + π / 2 / b)
    simp only at h
    have e1 : b * (c + π / 2 / b + P - c) = π / 2 + b * P := by field_simp; ring
    have e2 : b * (c + π / 2 / b - c) = π / 2 := by field_simp; ring
    rw [e1, e2, sin_pi_div_two, sin_add, sin_pi_div_two, cos_pi_div_two] at h
    have hc : cos (b * P) = 1 := by
      have : a * (cos (b * P) - 1) = 0 := by linarith
      rcases mul_eq_zero.mp this with h' | h'
      · exact absurd h' ha
      · linarith
    obtain ⟨n, hn⟩ := (cos_eq_one_iff _).mp hc
    have hn0 : n ≠ 0 := by
      rintro rfl
      simp at hn
      rcases hn with h' | h'
      · exact hb h'
      · linarith
    have hn1 : (1 : ℝ) ≤ |(n : ℝ)| := by
      rw [← Int.cast_abs]
      exact_mod_cast Int.one_le_abs hn0
    have habs : |b| * P = |(n : ℝ)| * (2 * π) := by
      have := congrArg abs hn
      rw [abs_mul, abs_mul, abs_mul, abs_of_pos hP, abs_two, abs_of_pos pi_pos] at this
      linarith
    rw [div_le_iff₀ hbb]
    nlinarith [pi_pos]

/-- The phase shift c: at t = c the wave is on its midline d, climbing at rate a·b
(rising when a and b are positive), and a quarter period P/4 = (2π/b)/4 later it reaches
d + a, high water. -/
theorem sine_wave_phase_shift (a b c d : ℝ) (hb : b ≠ 0) :
    (fun t : ℝ => a * sin (b * (t - c)) + d) c = d ∧
    HasDerivAt (fun t : ℝ => a * sin (b * (t - c)) + d) (a * b) c ∧
    (fun t : ℝ => a * sin (b * (t - c)) + d) (c + 2 * π / b / 4) = d + a := by
  refine ⟨by simp, ?_, ?_⟩
  · have h1 : HasDerivAt (fun t : ℝ => b * (t - c)) (b * 1) c :=
      ((hasDerivAt_id c).sub_const c).const_mul b
    have h2 := ((h1.sin).const_mul a).add_const d
    convert h2 using 1
    simp
  · simp only
    have : b * (c + 2 * π / b / 4 - c) = π / 2 := by field_simp; ring
    rw [this, sin_pi_div_two]; ring

/-- One tide, several formulas: the sine wave started at c equals the cosine wave started a
quarter period later at its high water, the sine wave started one full period later, and the
upside-down sine wave (amplitude -a) started half a period later. So the reading is unique only
once a and b are positive and c is the first rising crossing. -/
theorem sine_wave_equivalent_forms (a b c d : ℝ) (hb : b ≠ 0) (t : ℝ) :
    a * sin (b * (t - c)) + d = a * cos (b * (t - (c + 2 * π / b / 4))) + d ∧
    a * sin (b * (t - c)) + d = a * sin (b * (t - (c + 2 * π / b))) + d ∧
    a * sin (b * (t - c)) + d = -a * sin (b * (t - (c + 2 * π / b / 2))) + d := by
  have e1 : b * (t - (c + 2 * π / b / 4)) = b * (t - c) - π / 2 := by field_simp; ring
  have e2 : b * (t - (c + 2 * π / b)) = b * (t - c) - 2 * π := by field_simp; ring
  have e3 : b * (t - (c + 2 * π / b / 2)) = b * (t - c) - π := by field_simp; ring
  rw [e1, e2, e3, cos_sub_pi_div_two, sin_sub_two_pi, sin_sub_pi]
  refine ⟨rfl, rfl, by ring⟩

-- The card's worked numbers, heights in tenths of a metre (35 = 3.5 m, 5 = 0.5 m)
-- and times in minutes after midnight (04:06 = 246, 16:30 = 990).
example : (35 + 5) / 2 = 20 := by decide                -- midline 2.0 m
example : (35 - 5) / 2 = 15 := by decide                -- amplitude 1.5 m
example : (16 * 60 + 30) - (4 * 60 + 6) = 744 := by decide   -- period 12 h 24 min = 12.4 h
example : 744 / 4 = 186 := by decide                    -- a quarter period, 3 h 06 min = 3.1 h
example : (4 * 60 + 6) - 744 / 4 = 60 := by decide      -- phase shift c = 01:00
example : (4 * 60 + 6) + 744 / 2 = 10 * 60 + 18 := by decide  -- low water half a period on, 10:18
example : (4 * 60 + 6) + 2 * 744 - 24 * 60 = 4 * 60 + 54 := by decide  -- tomorrow's first high, 04:54
example : 2 * 744 - 24 * 60 = 48 := by decide           -- 48 minutes later each day
example : (20 + 30 : ℤ) = 50 ∧ (20 - 30 : ℤ) = -10 := by decide  -- swing as amplitude: 5.0 m and -1.0 m

#print axioms sine_wave_amplitude_midline_period
#print axioms sine_wave_phase_shift
#print axioms sine_wave_equivalent_forms
