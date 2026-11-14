-- Step response specs: for the two-pole step trace with damping ratio ζ between 0 and 1, the first peak comes at t_p = π/ω_d with overshoot e^(-πζ/√(1-ζ²)), the overshoot spec is the ray ζ > ζ_min, and the trace stays within 2% once t ≥ (ln 50 - ½ ln(1-ζ²))/σ.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.MeanValue

open Real Set

lemma step_trace_hasDerivAt (σ ωd t : ℝ) (hωd : ωd ≠ 0) :
    HasDerivAt (fun t => 1 - Real.exp (-σ * t) *
      (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t)))
      (Real.exp (-σ * t) * ((σ ^ 2 + ωd ^ 2) / ωd) * Real.sin (ωd * t)) t := by
  have h1 : HasDerivAt (fun t => -σ * t) (-σ) t := by
    simpa using (hasDerivAt_id t).const_mul (-σ)
  have h2 : HasDerivAt (fun t => ωd * t) ωd t := by
    simpa using (hasDerivAt_id t).const_mul ωd
  have he := h1.exp
  have hc := h2.cos
  have hs := (h2.sin).const_mul (σ / ωd)
  have := (hasDerivAt_const t (1:ℝ)).sub (he.mul (hc.add hs))
  convert this using 1
  simp only [Pi.add_apply]
  field_simp
  ring

#print axioms step_trace_hasDerivAt

lemma overshoot_exponent_strictMonoOn :
    StrictMonoOn (fun ζ : ℝ => π * ζ / Real.sqrt (1 - ζ ^ 2)) (Ioo 0 1) := by
  intro a ha b hb hab
  simp only
  have hsa : 0 < Real.sqrt (1 - a ^ 2) := Real.sqrt_pos.mpr (by nlinarith [ha.1, ha.2])
  have hsb : 0 < Real.sqrt (1 - b ^ 2) := Real.sqrt_pos.mpr (by nlinarith [hb.1, hb.2])
  have hle : Real.sqrt (1 - b ^ 2) < Real.sqrt (1 - a ^ 2) :=
    Real.sqrt_lt_sqrt (by nlinarith [hb.1, hb.2]) (by nlinarith [ha.1, ha.2])
  rw [div_lt_div_iff₀ hsa hsb]
  have := Real.pi_pos
  have h1 : π * a * Real.sqrt (1 - b ^ 2) < π * b * Real.sqrt (1 - b ^ 2) := by
    have : π * a < π * b := by nlinarith
    exact mul_lt_mul_of_pos_right this hsb
  have h2 : π * b * Real.sqrt (1 - b ^ 2) < π * b * Real.sqrt (1 - a ^ 2) := by
    have : 0 < π * b := by nlinarith [hb.1]
    exact mul_lt_mul_of_pos_left hle this
  linarith

#print axioms overshoot_exponent_strictMonoOn

/-- Overshoot is set by the angle of the poles. Take the two-pole, no-zero step trace, divided by
its final position: x(t) = 1 - e^(-σt)(cos ω_d t + (σ/ω_d) sin ω_d t), with damping ratio
0 < ζ < 1, natural frequency ω_n > 0, decay rate σ = ζ ω_n and ring frequency
ω_d = ω_n √(1 - ζ²). Then the trace rises steadily from t = 0 to the peak time t_p = π/ω_d,
never goes higher than its value there at any time t ≥ 0, and overshoots its final position by
the fraction M_p = e^(-πζ/√(1 - ζ²)), which depends on ζ alone. -/
theorem step_response_peak_overshoot (ζ ωn σ ωd : ℝ) (x : ℝ → ℝ)
    (hζ0 : 0 < ζ) (hζ1 : ζ < 1) (hωn : 0 < ωn)
    (hσ : σ = ζ * ωn) (hωd : ωd = ωn * Real.sqrt (1 - ζ ^ 2))
    (hx : ∀ t, x t = 1 - Real.exp (-σ * t) *
      (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) :
    StrictMonoOn x (Icc 0 (π / ωd)) ∧
    (∀ t, 0 ≤ t → x t ≤ x (π / ωd)) ∧
    x (π / ωd) - 1 = Real.exp (-(π * ζ) / Real.sqrt (1 - ζ ^ 2)) := by
  have hs : 0 < Real.sqrt (1 - ζ ^ 2) := Real.sqrt_pos.mpr (by nlinarith)
  have hωdpos : 0 < ωd := by rw [hωd]; positivity
  have hσpos : 0 < σ := by rw [hσ]; positivity
  obtain rfl : x = _ := funext hx
  set T := π / ωd with hT
  have hTpos : 0 < T := by positivity
  have hωdT : ωd * T = π := by rw [hT]; field_simp
  set M := Real.exp (-σ * T) with hM
  have hMpos : 0 < M := Real.exp_pos _
  have hM1 : M < 1 := by
    rw [hM, Real.exp_lt_one_iff]; nlinarith
  -- shift identity
  have shift : ∀ v, (fun t => 1 - Real.exp (-σ * t) *
      (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) (v + T) =
      1 + M * (1 - (fun t => 1 - Real.exp (-σ * t) *
      (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) v) := by
    intro v
    simp only
    rw [mul_add ωd v T, hωdT, Real.cos_add_pi, Real.sin_add_pi,
      show -σ * (v + T) = -σ * v + -σ * T by ring, Real.exp_add, hM]
    ring
  have hmono : StrictMonoOn (fun t => 1 - Real.exp (-σ * t) *
      (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) (Icc 0 T) := by
    apply strictMonoOn_of_deriv_pos (convex_Icc 0 T)
    · intro t _
      exact (step_trace_hasDerivAt σ ωd t hωdpos.ne').continuousAt.continuousWithinAt
    · intro t ht
      rw [interior_Icc] at ht
      rw [(step_trace_hasDerivAt σ ωd t hωdpos.ne').deriv]
      have : 0 < Real.sin (ωd * t) := by
        apply Real.sin_pos_of_pos_of_lt_pi
        · exact mul_pos hωdpos ht.1
        · rw [← hωdT]; exact mul_lt_mul_of_pos_left ht.2 hωdpos
      positivity
  have hx0 : (fun t => 1 - Real.exp (-σ * t) *
      (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) 0 = 0 := by simp
  have hxT : (fun t => 1 - Real.exp (-σ * t) *
      (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) T = 1 + M := by
    have := shift 0
    rw [zero_add, hx0] at this
    rw [this]; ring
  refine ⟨hmono, ?_, ?_⟩
  · have key : ∀ n : ℕ, ∀ u, 0 ≤ u → u ≤ (n + 1) * T →
        0 ≤ (fun t => 1 - Real.exp (-σ * t) *
          (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) u ∧
        (fun t => 1 - Real.exp (-σ * t) *
          (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) u ≤ 1 + M := by
      have base : ∀ u, 0 ≤ u → u ≤ T →
          0 ≤ (fun t => 1 - Real.exp (-σ * t) *
            (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) u ∧
          (fun t => 1 - Real.exp (-σ * t) *
            (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) u ≤ 1 + M := by
        intro u hu0 huT
        have hu : u ∈ Icc 0 T := ⟨hu0, huT⟩
        have h0 : (0:ℝ) ∈ Icc 0 T := ⟨le_rfl, hTpos.le⟩
        have hT' : T ∈ Icc 0 T := ⟨hTpos.le, le_rfl⟩
        constructor
        · rw [← hx0]; exact hmono.monotoneOn h0 hu hu0
        · rw [← hxT]; exact hmono.monotoneOn hu hT' huT
      intro n
      induction n with
      | zero => intro u hu0 hu; exact base u hu0 (by simpa using hu)
      | succ n ih =>
        intro u hu0 hu
        rcases le_or_gt u T with h | h
        · exact base u hu0 h
        · have hv := ih (u - T) (by linarith) (by push_cast at hu ⊢; linarith)
          have e := shift (u - T)
          rw [sub_add_cancel] at e
          rw [e]
          obtain ⟨a, b⟩ := hv
          constructor <;> nlinarith
    intro t ht
    obtain ⟨n, hn⟩ := exists_nat_ge (t / T)
    have : t ≤ (n + 1) * T := by
      rw [div_le_iff₀ hTpos] at hn; nlinarith
    rw [hxT]
    exact (key n t ht this).2
  · rw [hxT, hM, hT, add_sub_cancel_left]
    congr 1
    rw [hσ, hωd]
    field_simp

/-- The overshoot spec is a ray from the origin. For a damping ratio 0 < ζ < 1 and an allowed
overshoot 0 < M < 1, the overshoot e^(-πζ/√(1 - ζ²)) equals M exactly when
ζ = -ln M / √(π² + (ln M)²), and is below M exactly when ζ is above that value ζ_min. -/
theorem overshoot_spec_damping_ratio (ζ M : ℝ)
    (hζ0 : 0 < ζ) (hζ1 : ζ < 1) (hM0 : 0 < M) (hM1 : M < 1) :
    (Real.exp (-(π * ζ) / Real.sqrt (1 - ζ ^ 2)) = M ↔
      ζ = -Real.log M / Real.sqrt (π ^ 2 + Real.log M ^ 2)) ∧
    (Real.exp (-(π * ζ) / Real.sqrt (1 - ζ ^ 2)) < M ↔
      -Real.log M / Real.sqrt (π ^ 2 + Real.log M ^ 2) < ζ) := by
  set L := Real.log M with hL
  have hLneg : L < 0 := Real.log_neg hM0 hM1
  set r := Real.sqrt (π ^ 2 + L ^ 2) with hr
  have hpi := Real.pi_pos
  have hrpos : 0 < r := Real.sqrt_pos.mpr (by positivity)
  have hr2 : r ^ 2 = π ^ 2 + L ^ 2 := Real.sq_sqrt (by positivity)
  set z := -L / r with hz
  have hz0 : 0 < z := div_pos (by linarith) hrpos
  have hz1 : z < 1 := by
    rw [hz, div_lt_one hrpos]
    nlinarith
  have hzmem : z ∈ Ioo (0:ℝ) 1 := ⟨hz0, hz1⟩
  have hζmem : ζ ∈ Ioo (0:ℝ) 1 := ⟨hζ0, hζ1⟩
  have hsz : Real.sqrt (1 - z ^ 2) = π / r := by
    have : 1 - z ^ 2 = (π / r) ^ 2 := by
      rw [hz]; field_simp; nlinarith
    rw [this, Real.sqrt_sq (by positivity)]
  have hφz : π * z / Real.sqrt (1 - z ^ 2) = -L := by
    rw [hsz, hz]; field_simp
  have hM : M = Real.exp (-(π * z) / Real.sqrt (1 - z ^ 2)) := by
    rw [neg_div, hφz, neg_neg, hL, Real.exp_log hM0]
  have hmono := overshoot_exponent_strictMonoOn
  constructor
  · constructor
    · intro h
      rw [hM, Real.exp_eq_exp, neg_div, neg_div, neg_inj] at h
      exact hmono.injOn hζmem hzmem h
    · intro h
      rw [hM, h]
  · rw [hM, Real.exp_lt_exp, neg_div, neg_div, neg_lt_neg_iff]
    exact hmono.lt_iff_lt hzmem hζmem


/-- The settling bound. For the same trace, the distance from the final position is at most
e^(-σt)/√(1 - ζ²) at every time t, so the trace is within 2% of its final position at every
time t ≥ (ln 50 - ½ ln(1 - ζ²))/σ. -/
theorem step_response_settling_bound (ζ ωn σ ωd : ℝ) (x : ℝ → ℝ)
    (hζ0 : 0 < ζ) (hζ1 : ζ < 1) (hωn : 0 < ωn)
    (hσ : σ = ζ * ωn) (hωd : ωd = ωn * Real.sqrt (1 - ζ ^ 2))
    (hx : ∀ t, x t = 1 - Real.exp (-σ * t) *
      (Real.cos (ωd * t) + σ / ωd * Real.sin (ωd * t))) :
    (∀ t, |x t - 1| ≤ Real.exp (-σ * t) / Real.sqrt (1 - ζ ^ 2)) ∧
    (∀ t, (Real.log 50 - Real.log (1 - ζ ^ 2) / 2) / σ ≤ t → |x t - 1| ≤ 1 / 50) := by
  have h1z : 0 < 1 - ζ ^ 2 := by nlinarith
  set s := Real.sqrt (1 - ζ ^ 2) with hsdef
  have hs : 0 < s := Real.sqrt_pos.mpr h1z
  have hs2 : s ^ 2 = 1 - ζ ^ 2 := Real.sq_sqrt h1z.le
  have hωdpos : 0 < ωd := by rw [hωd]; positivity
  have hσpos : 0 < σ := by rw [hσ]; positivity
  have hratio : σ / ωd = ζ / s := by
    rw [hσ, hωd]; field_simp
  have bound : ∀ t, |x t - 1| ≤ Real.exp (-σ * t) / s := by
    intro t
    rw [hx, hratio]
    set c := Real.cos (ωd * t)
    set sn := Real.sin (ωd * t)
    have hcs : sn ^ 2 + c ^ 2 = 1 := Real.sin_sq_add_cos_sq _
    have hkey : |c * s + ζ * sn| ≤ 1 := by
      rw [← Real.sqrt_one]
      apply Real.abs_le_sqrt
      nlinarith [sq_nonneg (c * ζ - s * sn)]
    have heq : 1 - Real.exp (-σ * t) * (c + ζ / s * sn) - 1 =
        -(Real.exp (-σ * t) / s) * (c * s + ζ * sn) := by
      field_simp; ring
    rw [heq, abs_mul, abs_neg, abs_of_pos (by positivity)]
    calc Real.exp (-σ * t) / s * |c * s + ζ * sn| ≤ Real.exp (-σ * t) / s * 1 :=
          mul_le_mul_of_nonneg_left hkey (by positivity)
      _ = _ := mul_one _
  refine ⟨bound, ?_⟩
  intro t ht
  rw [div_le_iff₀ hσpos] at ht
  refine (bound t).trans ?_
  rw [div_le_iff₀ hs]
  have hexp : Real.exp (-σ * t) ≤ Real.exp (-Real.log 50 + Real.log (1 - ζ ^ 2) / 2) :=
    Real.exp_le_exp.mpr (by nlinarith)
  rw [Real.exp_add, Real.exp_neg, Real.exp_log (by norm_num), Real.exp_half,
    Real.exp_log h1z, ← hsdef] at hexp
  linarith [hexp, show (50:ℝ)⁻¹ * s = 1 / 50 * s by norm_num]

-- Door A: m = 40 kg, b = 300 N s/m, k_s = 40 N/m, K_p = 960 N/m, command r = 450 mm.
-- Natural frequency: ω_n = √((960 + 40)/40) = √25 = 5 rad/s.
example : ((960 : ℚ) + 40) / 40 = 25 := by norm_num
example : Real.sqrt 25 = 5 := by
  rw [show (25 : ℝ) = 5 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Damping ratio: ζ = 300/(2 × 40 × 5) = 3/4; decay rate σ = 3/4 × 5 = 15/4 1/s.
example : (300 : ℚ) / (2 * 40 * 5) = 3 / 4 := by norm_num
example : (3 / 4 : ℚ) * 5 = 15 / 4 := by norm_num
-- 4mk - b² = 4 × 40 × 1000 - 300² = 70000.
example : (4 : ℤ) * 40 * 1000 - 300 ^ 2 = 70000 := by norm_num
-- Settling rule 4/σ = 4/(15/4) = 16/15 s; the spec 4/1.5 = 8/3 1/s.
example : (4 : ℚ) / (15 / 4) = 16 / 15 := by norm_num
example : (4 : ℚ) / (3 / 2) = 8 / 3 := by norm_num
-- Final position 960/1000 × 450 = 432 mm; steady error 450 - 432 = 18 mm, which is 4% of travel.
example : (960 : ℚ) / 1000 * 450 = 432 := by norm_num
example : (450 : ℚ) - 432 = 18 := by norm_num
example : (18 : ℚ) / 450 = 4 / 100 := by norm_num
-- The same error from r k_s/(m ω_n²) = 450 × 40/(40 × 25) = 18 mm.
example : (450 : ℚ) * 40 / (40 * 25) = 18 := by norm_num
-- Error spec 4.5 mm: K_p ≥ 40 × (450 - 9/2)/(9/2) = 3960 N/m, so ω_n ≥ √(4000/40) = 10 rad/s.
example : (40 : ℚ) * (450 - 9 / 2) / (9 / 2) = 3960 := by norm_num
example : ((3960 : ℚ) + 40) / 40 = 100 := by norm_num
example : Real.sqrt 100 = 10 := by
  rw [show (100 : ℝ) = 10 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- With K_p = 3960 the damping ratio is 300/(2√(40 × 4000)) = 300/800 = 3/8; with b = 600 it is 3/4.
example : Real.sqrt (40 * 4000) = 400 := by
  rw [show (40 * 4000 : ℝ) = 400 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : (300 : ℚ) / (2 * 400) = 3 / 8 := by norm_num
example : (600 : ℚ) / (2 * 400) = 3 / 4 := by norm_num
-- Drive force at the command: 960 × 450/1000 = 432 N for door A, 3960 × 450/1000 = 1782 N.
example : (960 : ℚ) * 450 / 1000 = 432 := by norm_num
example : (3960 : ℚ) * 450 / 1000 = 1782 := by norm_num
-- b = 400 gives ζ = 400/(2 × 40 × 5) = 1; b = 200 gives ζ = 1/2.
example : (400 : ℚ) / (2 * 40 * 5) = 1 := by norm_num
example : (200 : ℚ) / (2 * 40 * 5) = 1 / 2 := by norm_num

#print axioms step_response_peak_overshoot
#print axioms overshoot_spec_damping_ratio
#print axioms step_response_settling_bound
