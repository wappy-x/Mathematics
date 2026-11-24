-- Measured Bode plots: the measured coherence |S_yu|^2 / (S_uu S_yy) always lies between 0 and 1, equals 1 exactly when one complex number maps every segment's input to its output, and so is always 1 for a single segment.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Finset.Sort
import Mathlib.Analysis.InnerProductSpace.PiL2

open ComplexConjugate

/-- The averaged cross-spectrum at one frequency: `S_yu = (1/n_d) * sum_m Y_m * conj(U_m)`,
from the `n_d` segment transforms `Y_m` (output) and `U_m` (input). -/
noncomputable def crossSpectrum {nd : ℕ} (Y U : Fin nd → ℂ) : ℂ :=
  (∑ m, Y m * conj (U m)) / nd

/-- The averaged power spectrum at one frequency: `S_uu = (1/n_d) * sum_m |U_m|^2`. -/
noncomputable def powerSpectrum {nd : ℕ} (U : Fin nd → ℂ) : ℝ :=
  (∑ m, ‖U m‖ ^ 2) / nd

/-- The measured coherence at one frequency: `|S_yu|^2 / (S_uu * S_yy)`. -/
noncomputable def coherence {nd : ℕ} (Y U : Fin nd → ℂ) : ℝ :=
  ‖crossSpectrum Y U‖ ^ 2 / (powerSpectrum U * powerSpectrum Y)

lemma frc_sum_eq_inner {nd : ℕ} (Y U : Fin nd → ℂ) :
    ∑ m, Y m * conj (U m) = inner ℂ (WithLp.toLp 2 U : EuclideanSpace ℂ (Fin nd)) (WithLp.toLp 2 Y) := by
  rw [EuclideanSpace.inner_toLp_toLp]; rfl

#print axioms frc_sum_eq_inner

lemma frc_sum_eq_norm_sq {nd : ℕ} (U : Fin nd → ℂ) :
    ∑ m, ‖U m‖ ^ 2 = ‖(WithLp.toLp 2 U : EuclideanSpace ℂ (Fin nd))‖ ^ 2 := by
  rw [EuclideanSpace.norm_sq_eq]

#print axioms frc_sum_eq_norm_sq

lemma frc_coherence_eq {nd : ℕ} (Y U : Fin nd → ℂ) :
    coherence Y U = ‖∑ m, Y m * conj (U m)‖ ^ 2 / ((∑ m, ‖U m‖ ^ 2) * (∑ m, ‖Y m‖ ^ 2)) := by
  rcases Nat.eq_zero_or_pos nd with h | h
  · subst h; simp [coherence, crossSpectrum, powerSpectrum]
  · have hn : (nd : ℝ) ≠ 0 := by positivity
    unfold coherence crossSpectrum powerSpectrum
    rw [norm_div, Complex.norm_natCast, div_pow, div_mul_div_comm, ← sq,
      div_div_div_cancel_right₀ (pow_ne_zero 2 hn)]

#print axioms frc_coherence_eq

lemma frc_cauchy_schwarz {nd : ℕ} (Y U : Fin nd → ℂ) :
    ‖∑ m, Y m * conj (U m)‖ ^ 2 ≤ (∑ m, ‖U m‖ ^ 2) * (∑ m, ‖Y m‖ ^ 2) := by
  rw [frc_sum_eq_inner, frc_sum_eq_norm_sq, frc_sum_eq_norm_sq, ← mul_pow]
  exact pow_le_pow_left₀ (norm_nonneg _) (norm_inner_le_norm _ _) 2

#print axioms frc_cauchy_schwarz

/-- The card's main claim (Step 2's fold): for any number of segments and any segment
transforms `Y_m`, `U_m` at one frequency, the measured coherence
`|S_yu|^2 / (S_uu S_yy)` lies between 0 and 1 (Cauchy–Schwarz). -/
theorem coherence_between_zero_and_one {nd : ℕ} (Y U : Fin nd → ℂ) :
    0 ≤ coherence Y U ∧ coherence Y U ≤ 1 := by
  rw [frc_coherence_eq]
  have hA : 0 ≤ ∑ m, ‖U m‖ ^ 2 := Finset.sum_nonneg (fun _ _ => by positivity)
  have hB : 0 ≤ ∑ m, ‖Y m‖ ^ 2 := Finset.sum_nonneg (fun _ _ => by positivity)
  exact ⟨by positivity, div_le_one_of_le₀ (frc_cauchy_schwarz Y U) (mul_nonneg hA hB)⟩

/-- Equality case: when the input and output both have power at this frequency, the measured
coherence is exactly 1 if and only if one complex number `c` maps every segment's input to its
output, `Y_m = c * U_m` for every segment `m`. -/
theorem coherence_eq_one_iff_one_gain_fits_all {nd : ℕ} (Y U : Fin nd → ℂ)
    (hU : 0 < powerSpectrum U) (hY : 0 < powerSpectrum Y) :
    coherence Y U = 1 ↔ ∃ c : ℂ, ∀ m, Y m = c * U m := by
  have hA : 0 < ∑ m, ‖U m‖ ^ 2 := by
    by_contra h; rw [not_lt] at h
    exact absurd hU (not_lt.mpr (div_nonpos_of_nonpos_of_nonneg h (Nat.cast_nonneg _)))
  have hB : 0 < ∑ m, ‖Y m‖ ^ 2 := by
    by_contra h; rw [not_lt] at h
    exact absurd hY (not_lt.mpr (div_nonpos_of_nonpos_of_nonneg h (Nat.cast_nonneg _)))
  set u : EuclideanSpace ℂ (Fin nd) := WithLp.toLp 2 U with hu
  set y : EuclideanSpace ℂ (Fin nd) := WithLp.toLp 2 Y with hy
  have hu0 : u ≠ 0 := by
    intro h; rw [frc_sum_eq_norm_sq, ← hu, h] at hA; simp at hA
  have hy0 : y ≠ 0 := by
    intro h; rw [frc_sum_eq_norm_sq, ← hy, h] at hB; simp at hB
  rw [frc_coherence_eq, div_eq_one_iff_eq (mul_pos hA hB).ne', frc_sum_eq_inner,
    frc_sum_eq_norm_sq, frc_sum_eq_norm_sq, ← hu, ← hy, ← mul_pow,
    sq_eq_sq₀ (norm_nonneg _) (by positivity), norm_inner_eq_norm_iff hu0 hy0]
  constructor
  · rintro ⟨r, -, hr⟩
    refine ⟨r, fun m => ?_⟩
    have := congrArg (fun v : EuclideanSpace ℂ (Fin nd) => v m) hr
    simpa [hu, hy] using this
  · rintro ⟨c, hc⟩
    have hYc : Y = c • U := funext fun m => by simp [hc m]
    refine ⟨c, ?_, ?_⟩
    · rintro rfl
      apply hy0
      rw [hy, hYc, zero_smul, WithLp.toLp_zero]
    · rw [hy, hYc, WithLp.toLp_smul]

/-- One segment gives coherence exactly 1, whatever the (nonzero) data: with `n_d = 1` the
number `c = Y_1 / U_1` always fits, so the coherence says nothing without averaging. -/
theorem coherence_one_segment_eq_one (Y U : Fin 1 → ℂ) (hU : U 0 ≠ 0) (hY : Y 0 ≠ 0) :
    coherence Y U = 1 := by
  have hpU : 0 < powerSpectrum U := by simp [powerSpectrum]; positivity
  have hpY : 0 < powerSpectrum Y := by simp [powerSpectrum]; positivity
  rw [coherence_eq_one_iff_one_gain_fits_all Y U hpU hpY]
  refine ⟨Y 0 / U 0, fun m => ?_⟩
  rw [Subsingleton.elim m 0, div_mul_cancel₀ _ hU]

-- The card's whole-number facts: 8 segments of 180 minutes make the 1,440-minute day.
example : 8 * 180 = 1440 := by norm_num

-- With each setting held h = 5 minutes and segments of L = 180 samples, the input has no power at
-- bin k exactly when h k / L is a whole number; among bins 1 to 89 that is bins 36 and 72
-- (0.2 and 0.4 cycles a minute).
example : (Finset.Icc 1 89).filter (fun k => (5 * k) % 180 = 0) = {36, 72} := by decide

-- 39 trusted bins and 50 untrusted bins make the 89 bins used.
example : 39 + 50 = 89 := by norm_num

#print axioms coherence_between_zero_and_one
#print axioms coherence_eq_one_iff_one_gain_fits_all
#print axioms coherence_one_segment_eq_one
