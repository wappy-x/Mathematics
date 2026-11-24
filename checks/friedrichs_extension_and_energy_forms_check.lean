-- Friedrichs extension: on the bar from 0 to pi with both ends held at 0, the middle spike's energy u(pi/2)^2 has form bound 0, the bar's energy is never below the size squared, and the trial profile sin x gives the bracket value 1 + 2 alpha / pi.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real intervalIntegral


theorem spike_energy_bound_each_a (u u' : ℝ → ℝ) (hd : ∀ x, HasDerivAt u (u' x) x)
    (hc : Continuous u') (h0 : u 0 = 0) (hπ : u π = 0) (a : ℝ) (ha : 0 < a) :
    u (π / 2) ^ 2 ≤ a * (∫ x in (0)..π, u' x ^ 2) + 1 / (4 * a) * (∫ x in (0)..π, u x ^ 2) := by
  have hu : Continuous u := continuous_iff_continuousAt.2 fun x => (hd x).continuousAt
  set g : ℝ → ℝ := fun x => 2 * a * u' x ^ 2 + 1 / (2 * a) * u x ^ 2 with hg
  have hgc : Continuous g := by fun_prop
  have hsq : ∀ x, HasDerivAt (fun y => u y ^ 2) (2 * u x * u' x) x := by
    intro x
    convert (hd x).pow 2 using 1
    push_cast; ring
  have hpt1 : ∀ x, 2 * u x * u' x ≤ g x := by
    intro x
    have h1 : 0 ≤ (2 * a * u' x - u x) ^ 2 / (2 * a) := by positivity
    have h2 : (2 * a * u' x - u x) ^ 2 / (2 * a) = g x - 2 * u x * u' x := by
      simp only [hg]; field_simp; ring
    linarith
  have hpt2 : ∀ x, -(2 * u x * u' x) ≤ g x := by
    intro x
    have h1 : 0 ≤ (2 * a * u' x + u x) ^ 2 / (2 * a) := by positivity
    have h2 : (2 * a * u' x + u x) ^ 2 / (2 * a) = g x + 2 * u x * u' x := by
      simp only [hg]; field_simp; ring
    linarith
  have hint : ∀ c d, IntervalIntegrable (fun x => 2 * u x * u' x) MeasureTheory.volume c d :=
    fun c d => (by fun_prop : Continuous fun x => 2 * u x * u' x).intervalIntegrable c d
  have I1 : ∫ x in (0)..(π / 2), 2 * u x * u' x = u (π / 2) ^ 2 := by
    rw [integral_eq_sub_of_hasDerivAt (fun x _ => hsq x) (hint _ _), h0]; ring
  have I2 : ∫ x in (π / 2)..π, 2 * u x * u' x = - u (π / 2) ^ 2 := by
    rw [integral_eq_sub_of_hasDerivAt (fun x _ => hsq x) (hint _ _), hπ]; ring
  have J1 : u (π / 2) ^ 2 ≤ ∫ x in (0)..(π / 2), g x := by
    rw [← I1]
    exact integral_mono_on (by positivity) (hint _ _) (hgc.intervalIntegrable _ _)
      (fun x _ => hpt1 x)
  have J2 : u (π / 2) ^ 2 ≤ ∫ x in (π / 2)..π, g x := by
    have e : u (π / 2) ^ 2 = ∫ x in (π / 2)..π, -(2 * u x * u' x) := by
      rw [intervalIntegral.integral_neg, I2]; ring
    rw [e]
    exact integral_mono_on (by linarith [pi_pos]) (hint _ _).neg (hgc.intervalIntegrable _ _)
      (fun x _ => hpt2 x)
  have hsplit : (∫ x in (0)..(π / 2), g x) + (∫ x in (π / 2)..π, g x) = ∫ x in (0)..π, g x :=
    integral_add_adjacent_intervals (hgc.intervalIntegrable _ _) (hgc.intervalIntegrable _ _)
  have hgint : ∫ x in (0)..π, g x
      = 2 * a * (∫ x in (0)..π, u' x ^ 2) + 1 / (2 * a) * ∫ x in (0)..π, u x ^ 2 := by
    simp only [hg]
    rw [intervalIntegral.integral_add, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_const_mul]
    · exact (by fun_prop : Continuous fun x => 2 * a * u' x ^ 2).intervalIntegrable _ _
    · exact (by fun_prop : Continuous fun x => 1 / (2 * a) * u x ^ 2).intervalIntegrable _ _
  have e2 : 1 / (2 * a) = 2 * (1 / (4 * a)) := by field_simp; ring
  rw [e2] at hgint
  nlinarith

lemma le_sqrt_mul_sqrt_of_forall {A B c : ℝ} (hA : 0 ≤ A) (hB : 0 ≤ B)
    (h : ∀ a : ℝ, 0 < a → c ≤ a * B + 1 / (4 * a) * A) : c ≤ √A * √B := by
  rcases (Real.sqrt_nonneg A).eq_or_lt with hs | hs
  · have hA0 : A = 0 := (Real.sqrt_eq_zero hA).1 hs.symm
    rw [← hs, zero_mul]
    refine le_of_not_gt fun hc => ?_
    have h1 := h (c / (2 * (B + 1))) (by positivity)
    rw [hA0, mul_zero, add_zero] at h1
    have h2 : c / (2 * (B + 1)) * B < c := by
      rw [div_mul_eq_mul_div, div_lt_iff₀ (by positivity)]; nlinarith
    linarith
  rcases (Real.sqrt_nonneg B).eq_or_lt with hr | hr
  · have hB0 : B = 0 := (Real.sqrt_eq_zero hB).1 hr.symm
    rw [← hr, mul_zero]
    refine le_of_not_gt fun hc => ?_
    have h1 := h ((A + 1) / c) (by positivity)
    rw [hB0, mul_zero, zero_add] at h1
    have h2 : 1 / (4 * ((A + 1) / c)) * A < c := by
      rw [show 1 / (4 * ((A + 1) / c)) * A = c * A / (4 * (A + 1)) by field_simp]
      rw [div_lt_iff₀ (by positivity)]; nlinarith
    linarith
  · have h1 := h (√A / (2 * √B)) (by positivity)
    have hA2 : √A ^ 2 = A := sq_sqrt hA
    have hB2 : √B ^ 2 = B := sq_sqrt hB
    generalize √A = s at *
    generalize √B = r at *
    subst hA2 hB2
    have e : s / (2 * r) * r ^ 2 + 1 / (4 * (s / (2 * r))) * s ^ 2 = s * r := by
      field_simp; ring
    linarith

#print axioms spike_energy_bound_each_a
#print axioms le_sqrt_mul_sqrt_of_forall

theorem bar_energy_scaled_floor (u u' : ℝ → ℝ) (hd : ∀ x, HasDerivAt u (u' x) x)
    (hc : Continuous u') (h0 : u 0 = 0) (hπ : u π = 0) (l : ℝ) (hl0 : 0 < l) (hl1 : l < 1) :
    l ^ 2 * (∫ x in (0)..π, u x ^ 2) ≤ ∫ x in (0)..π, u' x ^ 2 := by
  have hu : Continuous u := continuous_iff_continuousAt.2 fun x => (hd x).continuousAt
  set θ : ℝ → ℝ := fun x => l * x + (1 - l) * π / 2 with hθ
  have hsin : ∀ x ∈ Set.uIcc 0 π, 0 < sin (θ x) := by
    intro x hx
    rw [Set.uIcc_of_le pi_pos.le] at hx
    obtain ⟨hx0, hx1⟩ := hx
    apply sin_pos_of_pos_of_lt_pi
    · simp only [hθ]; nlinarith [pi_pos]
    · simp only [hθ]; nlinarith [pi_pos]
  set w : ℝ → ℝ := fun x => l * cos (θ x) / sin (θ x) with hw
  set F' : ℝ → ℝ := fun x =>
    -(l ^ 2) / sin (θ x) ^ 2 * u x ^ 2 + w x * (2 * u x * u' x) with hF'
  have hθd : ∀ x, HasDerivAt θ l x := by
    intro x
    have := ((hasDerivAt_id x).const_mul l).add_const ((1 - l) * π / 2)
    simpa [hθ] using this
  have hF : ∀ x ∈ Set.uIcc 0 π, HasDerivAt (fun y => w y * u y ^ 2) (F' x) x := by
    intro x hx
    have hs := (hsin x hx).ne'
    have hcos : HasDerivAt (fun y => cos (θ y)) (-sin (θ x) * l) x := (hθd x).cos
    have hsn : HasDerivAt (fun y => sin (θ y)) (cos (θ x) * l) x := (hθd x).sin
    have hwd : HasDerivAt w (-(l ^ 2) / sin (θ x) ^ 2) x := by
      have := (hcos.const_mul l).div hsn hs
      convert this using 1
      field_simp
      nlinarith [sin_sq_add_cos_sq (θ x)]
    have hsq : HasDerivAt (fun y => u y ^ 2) (2 * u x * u' x) x := by
      convert (hd x).pow 2 using 1
      push_cast; ring
    exact hwd.mul hsq
  have hF'c : ContinuousOn F' (Set.uIcc 0 π) := by
    have hsc : ContinuousOn (fun x => sin (θ x)) (Set.uIcc 0 π) := by fun_prop
    have hcc : ContinuousOn (fun x => cos (θ x)) (Set.uIcc 0 π) := by fun_prop
    apply ContinuousOn.add
    · apply ContinuousOn.mul
      · exact continuousOn_const.div (hsc.pow 2) (fun x hx => by positivity [hsin x hx])
      · exact (hu.pow 2).continuousOn
    · apply ContinuousOn.mul
      · exact (hcc.const_smul l).div hsc (fun x hx => (hsin x hx).ne')
      · exact (by fun_prop : Continuous fun x => 2 * u x * u' x).continuousOn
  have hFint : ∫ x in (0)..π, F' x = 0 := by
    rw [integral_eq_sub_of_hasDerivAt hF (hF'c.intervalIntegrable)]
    simp [h0, hπ]
  have hpt : ∀ x ∈ Set.Icc 0 π, F' x ≤ u' x ^ 2 - l ^ 2 * u x ^ 2 := by
    intro x hx
    have hx' : x ∈ Set.uIcc 0 π := by rw [Set.uIcc_of_le pi_pos.le]; exact hx
    have hs := hsin x hx'
    have key : u' x ^ 2 - l ^ 2 * u x ^ 2 - F' x = (u' x - w x * u x) ^ 2 := by
      simp only [hF', hw]
      field_simp
      linear_combination (-(l ^ 2 * u x ^ 2)) * sin_sq_add_cos_sq (θ x)
    nlinarith [sq_nonneg (u' x - w x * u x)]
  have hmono := integral_mono_on (μ := MeasureTheory.volume) pi_pos.le hF'c.intervalIntegrable
    ((by fun_prop : Continuous fun x => u' x ^ 2 - l ^ 2 * u x ^ 2).intervalIntegrable 0 π) hpt
  rw [hFint, intervalIntegral.integral_sub, intervalIntegral.integral_const_mul] at hmono
  · linarith
  · exact (by fun_prop : Continuous fun x => u' x ^ 2).intervalIntegrable _ _
  · exact (by fun_prop : Continuous fun x => l ^ 2 * u x ^ 2).intervalIntegrable _ _

#print axioms bar_energy_scaled_floor

/-- Step 5, the spike is form-bounded with bound 0. Take a profile u on the bar from 0 to pi
with a continuous slope u' and both ends held at 0 (the smooth core of the form domain H^1_0).
Its squared value at the middle is at most its size times its slope's size,
u(pi/2)^2 <= ||u|| ||u'||, and so, for every a > 0, at most
a * (integral of u'^2) + (1 / (4a)) * (integral of u^2). -/
theorem spike_energy_form_bound_zero (u u' : ℝ → ℝ) (hd : ∀ x, HasDerivAt u (u' x) x)
    (hc : Continuous u') (h0 : u 0 = 0) (hπ : u π = 0) :
    u (π / 2) ^ 2 ≤ √(∫ x in (0)..π, u x ^ 2) * √(∫ x in (0)..π, u' x ^ 2) ∧
    ∀ a : ℝ, 0 < a →
      u (π / 2) ^ 2 ≤ a * (∫ x in (0)..π, u' x ^ 2) + 1 / (4 * a) * (∫ x in (0)..π, u x ^ 2) := by
  have hb := spike_energy_bound_each_a u u' hd hc h0 hπ
  refine ⟨le_sqrt_mul_sqrt_of_forall ?_ ?_ hb, hb⟩
  · exact intervalIntegral.integral_nonneg pi_pos.le fun x _ => sq_nonneg _
  · exact intervalIntegral.integral_nonneg pi_pos.le fun x _ => sq_nonneg _

/-- The floor of the bar's energy (Poincare on length pi, C_P = 1, so m = 1): for a profile with
a continuous slope and both ends held at 0, the energy q(u) = integral of u'^2 is never less than
the integral of u^2. -/
theorem bar_energy_at_least_size_squared (u u' : ℝ → ℝ) (hd : ∀ x, HasDerivAt u (u' x) x)
    (hc : Continuous u') (h0 : u 0 = 0) (hπ : u π = 0) :
    ∫ x in (0)..π, u x ^ 2 ≤ ∫ x in (0)..π, u' x ^ 2 := by
  set A := ∫ x in (0)..π, u x ^ 2
  set B := ∫ x in (0)..π, u' x ^ 2
  have hB : 0 ≤ B := intervalIntegral.integral_nonneg pi_pos.le fun x _ => sq_nonneg _
  refine le_of_not_gt fun hlt => ?_
  have hA : 0 < A := lt_of_le_of_lt hB hlt
  have hl0 : 0 < (A + B) / (2 * A) := by positivity
  have hl1 : (A + B) / (2 * A) < 1 := by rw [div_lt_one (by positivity)]; linarith
  have h := bar_energy_scaled_floor u u' hd hc h0 hπ _ hl0 hl1
  have e : ((A + B) / (2 * A)) ^ 2 * A = (A + B) ^ 2 / (4 * A) := by field_simp; ring
  rw [e, div_le_iff₀ (by positivity)] at h
  nlinarith [sq_pos_of_pos (sub_pos.2 hlt)]

/-- Road 3, the Rayleigh bracket with the trial profile sin x: its energy (the integral of
cos^2, the slope of sin squared) plus the spike's energy alpha * sin(pi/2)^2, divided by its
squared size (the integral of sin^2), equals 1 + 2 alpha / pi; at strength alpha = 1 this is
1 + 2/pi. -/
theorem sin_trial_rayleigh_quotient (α : ℝ) :
    ((∫ x in (0)..π, cos x ^ 2) + α * sin (π / 2) ^ 2) / (∫ x in (0)..π, sin x ^ 2)
      = 1 + 2 * α / π := by
  rw [integral_cos_sq, integral_sin_sq]
  simp only [sin_pi, cos_pi, sin_zero, cos_zero, sin_pi_div_two]
  field_simp
  ring

-- The held-ends bar's levels n^2 for n = 1, 2, 3 are 1, 4, 9.
example : (List.range 3).map (fun n => (n + 1) ^ 2) = [1, 4, 9] := by decide

-- Step 4's ramp energies 2/eps at eps = 0.1, 0.01, 0.001 are 20, 200, 2000.
example : (2 : ℚ) / (1 / 10) = 20 ∧ (2 : ℚ) / (1 / 100) = 200 ∧ (2 : ℚ) / (1 / 1000) = 2000 := by
  norm_num

#print axioms spike_energy_form_bound_zero
#print axioms bar_energy_at_least_size_squared
#print axioms sin_trial_rayleigh_quotient
