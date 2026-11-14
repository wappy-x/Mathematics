-- RLC resonance: a series coil, capacitor and resistor draws the most current at exactly f0 = 1/(2π√(LC)), its current curve is 1/√(1 + Q²(f/f0 − f0/f)²), and its half-power band is exactly f0/Q wide.
import Mathlib.Analysis.Complex.Norm
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real

/-- The impedance of a series loop of resistance `R`, inductance `L` and capacitance `C`
at angular frequency `ω` (radians per second): `Z(ω) = R + j(ωL − 1/(ωC))`.
The current for a drive of size `V` is `V / ‖Z(ω)‖`; a frequency `f` in hertz has `ω = 2πf`. -/
noncomputable def seriesImpedance (R L C ω : ℝ) : ℂ :=
  (R : ℂ) + ((ω * L - 1 / (ω * C) : ℝ) : ℂ) * Complex.I

lemma rlc_norm_seriesImpedance (R L C ω : ℝ) :
    ‖seriesImpedance R L C ω‖ = √(R ^ 2 + (ω * L - 1 / (ω * C)) ^ 2) :=
  Complex.norm_add_mul_I _ _

#print axioms rlc_norm_seriesImpedance

lemma rlc_omega0 (L C : ℝ) (hL : 0 < L) (hC : 0 < C) :
    2 * π * (1 / (2 * π * √(L * C))) = 1 / √(L * C) := by
  have hs : 0 < √(L * C) := Real.sqrt_pos.mpr (mul_pos hL hC)
  field_simp

#print axioms rlc_omega0

lemma rlc_reactance_zero (L C : ℝ) (hL : 0 < L) (hC : 0 < C) :
    1 / √(L * C) * L - 1 / (1 / √(L * C) * C) = 0 := by
  have hs : 0 < √(L * C) := Real.sqrt_pos.mpr (mul_pos hL hC)
  have hs2 : √(L * C) ^ 2 = L * C := Real.sq_sqrt (mul_pos hL hC).le
  field_simp
  nlinarith

#print axioms rlc_reactance_zero

lemma rlc_norm_at_res (R L C : ℝ) (hR : 0 < R) (hL : 0 < L) (hC : 0 < C) :
    ‖seriesImpedance R L C (2 * π * (1 / (2 * π * √(L * C))))‖ = R := by
  rw [rlc_omega0 L C hL hC, rlc_norm_seriesImpedance, rlc_reactance_zero L C hL hC]
  simp [Real.sqrt_sq hR.le]

#print axioms rlc_norm_at_res

/-- reactance vanishes only at resonance -/
lemma rlc_reactance_ne (L C f : ℝ) (hL : 0 < L) (hC : 0 < C) (hf : 0 < f)
    (hne : f ≠ 1 / (2 * π * √(L * C))) :
    2 * π * f * L - 1 / (2 * π * f * C) ≠ 0 := by
  intro h
  have hs : 0 < √(L * C) := Real.sqrt_pos.mpr (mul_pos hL hC)
  have hs2 : √(L * C) ^ 2 = L * C := Real.sq_sqrt (mul_pos hL hC).le
  have hw : 0 < 2 * π * f := by positivity
  apply hne
  have h1 : (2 * π * f) ^ 2 * (L * C) = 1 := by
    field_simp at h
    nlinarith
  have h2 : (2 * π * f * √(L * C)) ^ 2 = 1 := by rw [mul_pow, hs2]; exact h1
  have h3 : 2 * π * f * √(L * C) = 1 := by
    have hp : 0 < 2 * π * f * √(L * C) := by positivity
    nlinarith
  field_simp
  linarith

#print axioms rlc_reactance_ne

/-- The quadratic factorisation behind the half-power edges. -/
lemma rlc_factor (R L C S ω : ℝ) (hL : 0 < L) (hC : 0 < C)
    (hS2 : S ^ 2 = R ^ 2 + 4 * L / C) :
    L * ω ^ 2 - R * ω - 1 / C = L * (ω - (R + S) / (2 * L)) * (ω + (S - R) / (2 * L)) ∧
    L * ω ^ 2 + R * ω - 1 / C = L * (ω - (S - R) / (2 * L)) * (ω + (R + S) / (2 * L)) := by
  have hL' : L ≠ 0 := hL.ne'
  have hC' : C ≠ 0 := hC.ne'
  have hS2' : C * S ^ 2 = C * R ^ 2 + 4 * L := by rw [hS2]; field_simp
  constructor
  · field_simp
    linear_combination hS2'
  · field_simp
    linear_combination hS2'

#print axioms rlc_factor

/-- Half-power condition in angular frequency. -/
lemma rlc_band (R L C ω : ℝ) (hR : 0 < R) (hL : 0 < L) (hC : 0 < C) (hω : 0 < ω) :
    (ω * L - 1 / (ω * C)) ^ 2 ≤ R ^ 2 ↔
      (√(R ^ 2 + 4 * L / C) - R) / (2 * L) ≤ ω ∧ ω ≤ (R + √(R ^ 2 + 4 * L / C)) / (2 * L) := by
  have hS2 : √(R ^ 2 + 4 * L / C) ^ 2 = R ^ 2 + 4 * L / C := Real.sq_sqrt (by positivity)
  have hSR : R < √(R ^ 2 + 4 * L / C) := by
    rw [show R = √(R ^ 2) from (Real.sqrt_sq hR.le).symm]
    rw [Real.sqrt_sq hR.le]
    have : 0 < 4 * L / C := by positivity
    exact Real.lt_sqrt_of_sq_lt (by linarith)
  generalize √(R ^ 2 + 4 * L / C) = S at hS2 hSR
  obtain ⟨h1, h2⟩ := rlc_factor R L C S ω hL hC hS2
  have hXω : (ω * L - 1 / (ω * C)) * ω = L * ω ^ 2 - 1 / C := by
    field_simp
  have hw1 : 0 < ω + (S - R) / (2 * L) := by
    have : 0 < (S - R) / (2 * L) := div_pos (by linarith) (by linarith)
    linarith
  have hw2 : 0 < ω + (R + S) / (2 * L) := by
    have : 0 < (R + S) / (2 * L) := div_pos (by linarith) (by linarith)
    linarith
  rw [sq_le_sq, abs_of_pos hR, abs_le]
  constructor
  · rintro ⟨hlo, hhi⟩
    constructor
    · -- b ≥ 0
      have hb : 0 ≤ L * (ω - (S - R) / (2 * L)) * (ω + (R + S) / (2 * L)) := by
        rw [← h2]; nlinarith
      by_contra hcon
      push Not at hcon
      have : L * (ω - (S - R) / (2 * L)) * (ω + (R + S) / (2 * L)) < 0 := by
        have : L * (ω - (S - R) / (2 * L)) < 0 := mul_neg_of_pos_of_neg hL (by linarith)
        exact mul_neg_of_neg_of_pos this hw2
      linarith
    · have ha : L * (ω - (R + S) / (2 * L)) * (ω + (S - R) / (2 * L)) ≤ 0 := by
        rw [← h1]; nlinarith
      by_contra hcon
      push Not at hcon
      have : 0 < L * (ω - (R + S) / (2 * L)) * (ω + (S - R) / (2 * L)) := by
        have : 0 < L * (ω - (R + S) / (2 * L)) := mul_pos hL (by linarith)
        exact mul_pos this hw1
      linarith
  · rintro ⟨hlo, hhi⟩
    have hb : 0 ≤ L * (ω - (S - R) / (2 * L)) * (ω + (R + S) / (2 * L)) :=
      mul_nonneg (mul_nonneg hL.le (by linarith)) hw2.le
    have ha : L * (ω - (R + S) / (2 * L)) * (ω + (S - R) / (2 * L)) ≤ 0 :=
      mul_nonpos_of_nonpos_of_nonneg (mul_nonpos_of_nonneg_of_nonpos hL.le (by linarith)) hw1.le
    rw [← h2] at hb
    rw [← h1] at ha
    constructor
    · by_contra hcon
      push Not at hcon
      have : (ω * L - 1 / (ω * C)) * ω < -R * ω := mul_lt_mul_of_pos_right hcon hω
      nlinarith
    · by_contra hcon
      push Not at hcon
      have : R * ω < (ω * L - 1 / (ω * C)) * ω := mul_lt_mul_of_pos_right hcon hω
      nlinarith

#print axioms rlc_band

/-- The card's main claim, the peak: for any positive resistance, inductance and capacitance,
the size of the loop's impedance, and so the opposition to current, is smallest at exactly one
positive frequency, `f0 = 1/(2π√(LC))`, which does not involve `R`. There the coil's and the
capacitor's push-backs cancel and only the resistor is left: `‖Z‖ = R`. At every other positive
frequency `‖Z‖` is strictly larger, so the current `V/‖Z‖` is strictly smaller. -/
theorem current_peaks_at_resonant_frequency (R L C : ℝ) (hR : 0 < R) (hL : 0 < L) (hC : 0 < C) :
    let f₀ := 1 / (2 * π * √(L * C))
    ‖seriesImpedance R L C (2 * π * f₀)‖ = R ∧
      ∀ f : ℝ, 0 < f → f ≠ f₀ →
        ‖seriesImpedance R L C (2 * π * f₀)‖ < ‖seriesImpedance R L C (2 * π * f)‖ := by
  intro f₀
  refine ⟨rlc_norm_at_res R L C hR hL hC, fun f hf hne => ?_⟩
  rw [rlc_norm_at_res R L C hR hL hC, rlc_norm_seriesImpedance]
  have hX := rlc_reactance_ne L C f hL hC hf hne
  have hpos : 0 < (2 * π * f * L - 1 / (2 * π * f * C)) ^ 2 := by positivity
  rw [show R = √(R ^ 2) from (Real.sqrt_sq hR.le).symm]
  rw [Real.sqrt_sq hR.le]
  apply Real.lt_sqrt_of_sq_lt
  linarith

/-- The card's main claim, the sharpness: with `Q = 2π f0 L / R` (the coil's reactance at
resonance over the resistance), the frequencies that get at least half the peak power, that is
current at least `1/√2` of the peak current, form one closed band `[f1, f2]`. Its width is
exactly `f0 / Q`, at any `Q`, and `f0` is the geometric mean of its edges: `f1 · f2 = f0²`. -/
theorem half_power_bandwidth_eq_f0_div_Q (R L C : ℝ) (hR : 0 < R) (hL : 0 < L) (hC : 0 < C) :
    let f₀ := 1 / (2 * π * √(L * C))
    let Q := 2 * π * f₀ * L / R
    ∃ f₁ f₂ : ℝ, 0 < f₁ ∧ f₁ < f₂ ∧
      {f : ℝ | 0 < f ∧
          1 / 2 ≤ (‖seriesImpedance R L C (2 * π * f₀)‖ / ‖seriesImpedance R L C (2 * π * f)‖) ^ 2} =
        Set.Icc f₁ f₂ ∧
      f₂ - f₁ = f₀ / Q ∧ f₁ * f₂ = f₀ ^ 2 := by
  intro f₀ Q
  have hS2 : √(R ^ 2 + 4 * L / C) ^ 2 = R ^ 2 + 4 * L / C := Real.sq_sqrt (by positivity)
  have hSR : R < √(R ^ 2 + 4 * L / C) := by
    rw [show R = √(R ^ 2) from (Real.sqrt_sq hR.le).symm]
    rw [Real.sqrt_sq hR.le]
    have : 0 < 4 * L / C := by positivity
    exact Real.lt_sqrt_of_sq_lt (by linarith)
  have hπ : 0 < 2 * π := by positivity
  refine ⟨(√(R ^ 2 + 4 * L / C) - R) / (2 * L) / (2 * π),
    (R + √(R ^ 2 + 4 * L / C)) / (2 * L) / (2 * π), ?_, ?_, ?_, ?_, ?_⟩
  · exact div_pos (div_pos (by linarith) (by linarith)) hπ
  · apply div_lt_div_of_pos_right _ hπ
    apply div_lt_div_of_pos_right _ (by linarith)
    linarith
  · ext f
    simp only [Set.mem_ofPred_eq, Set.mem_Icc]
    rw [rlc_norm_at_res R L C hR hL hC, rlc_norm_seriesImpedance, div_pow,
      Real.sq_sqrt (by positivity)]
    rw [div_le_iff₀ hπ, le_div_iff₀ hπ]
    constructor
    · rintro ⟨hf, hhalf⟩
      have hw : 0 < 2 * π * f := by positivity
      have hpos : 0 < R ^ 2 + (2 * π * f * L - 1 / (2 * π * f * C)) ^ 2 := by positivity
      rw [le_div_iff₀ hpos] at hhalf
      have hX : (2 * π * f * L - 1 / (2 * π * f * C)) ^ 2 ≤ R ^ 2 := by linarith
      obtain ⟨h1, h2⟩ := (rlc_band R L C (2 * π * f) hR hL hC hw).mp hX
      constructor <;> linarith
    · rintro ⟨h1, h2⟩
      have hlo : 0 < (√(R ^ 2 + 4 * L / C) - R) / (2 * L) := div_pos (by linarith) (by linarith)
      have hw : 0 < 2 * π * f := by linarith
      have hf : 0 < f := by
        by_contra h; push Not at h; nlinarith [Real.pi_pos]
      refine ⟨hf, ?_⟩
      have hX := (rlc_band R L C (2 * π * f) hR hL hC hw).mpr ⟨by linarith, by linarith⟩
      have hpos : 0 < R ^ 2 + (2 * π * f * L - 1 / (2 * π * f * C)) ^ 2 := by positivity
      rw [le_div_iff₀ hpos]
      linarith
  · show _ = (1 / (2 * π * √(L * C))) / (2 * π * (1 / (2 * π * √(L * C))) * L / R)
    have hs : 0 < √(L * C) := Real.sqrt_pos.mpr (mul_pos hL hC)
    generalize √(L * C) = s at hs
    generalize √(R ^ 2 + 4 * L / C) = S
    field_simp
    ring
  · show _ = (1 / (2 * π * √(L * C))) ^ 2
    have hs : 0 < √(L * C) := Real.sqrt_pos.mpr (mul_pos hL hC)
    have hs2 : √(L * C) ^ 2 = L * C := Real.sq_sqrt (mul_pos hL hC).le
    generalize √(L * C) = s at hs hs2
    generalize √(R ^ 2 + 4 * L / C) = S at hS2
    have hS2' : C * S ^ 2 = C * R ^ 2 + 4 * L := by rw [hS2]; field_simp
    field_simp
    rw [hs2]
    linear_combination L * hS2'

/-- The resonance curve: at any positive frequency `f`, the current as a fraction of its peak,
`G(f) = |I(f)| / |I(f0)| = ‖Z(f0)‖ / ‖Z(f)‖`, equals `1 / √(1 + Q²(f/f0 − f0/f)²)`,
with `Q = 2π f0 L / R`, which also equals `(1/R)√(L/C)`. -/
theorem resonance_curve_gain (R L C : ℝ) (hR : 0 < R) (hL : 0 < L) (hC : 0 < C) :
    let f₀ := 1 / (2 * π * √(L * C))
    let Q := 2 * π * f₀ * L / R
    Q = 1 / R * √(L / C) ∧
      ∀ f : ℝ, 0 < f →
        ‖seriesImpedance R L C (2 * π * f₀)‖ / ‖seriesImpedance R L C (2 * π * f)‖ =
          1 / √(1 + Q ^ 2 * (f / f₀ - f₀ / f) ^ 2) := by
  intro f₀ Q
  have hs : 0 < √(L * C) := Real.sqrt_pos.mpr (mul_pos hL hC)
  have hs2 : √(L * C) ^ 2 = L * C := Real.sq_sqrt (mul_pos hL hC).le
  have hsLC : √(L * C) = √L * √C := Real.sqrt_mul hL.le C
  have hLC : √(L / C) = √L / √C := Real.sqrt_div' L hC.le
  have hsL : 0 < √L := Real.sqrt_pos.mpr hL
  have hsC : 0 < √C := Real.sqrt_pos.mpr hC
  have hL2 : √L ^ 2 = L := Real.sq_sqrt hL.le
  have hC2 : √C ^ 2 = C := Real.sq_sqrt hC.le
  constructor
  · show 2 * π * (1 / (2 * π * √(L * C))) * L / R = 1 / R * √(L / C)
    rw [hsLC, hLC]
    field_simp
    linear_combination (-1 : ℝ) * hL2
  · intro f hf
    rw [rlc_norm_at_res R L C hR hL hC, rlc_norm_seriesImpedance]
    have hf0 : 0 < f₀ := by positivity
    have key : R ^ 2 + (2 * π * f * L - 1 / (2 * π * f * C)) ^ 2 =
        R ^ 2 * (1 + Q ^ 2 * (f / f₀ - f₀ / f) ^ 2) := by
      show _ = R ^ 2 * (1 + (2 * π * (1 / (2 * π * √(L * C))) * L / R) ^ 2 *
        (f / (1 / (2 * π * √(L * C))) - (1 / (2 * π * √(L * C))) / f) ^ 2)
      generalize √(L * C) = s at hs hs2 ⊢
      field_simp
      rw [show s ^ 4 = (s ^ 2) ^ 2 by ring, hs2]
      ring
    rw [key, Real.sqrt_mul (sq_nonneg R), Real.sqrt_sq hR.le]
    have : 0 < √(1 + Q ^ 2 * (f / f₀ - f₀ / f) ^ 2) := Real.sqrt_pos.mpr (by positivity)
    field_simp

#print axioms current_peaks_at_resonant_frequency
#print axioms half_power_bandwidth_eq_f0_div_Q
#print axioms resonance_curve_gain
