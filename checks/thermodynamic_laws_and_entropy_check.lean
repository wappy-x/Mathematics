-- The thermodynamic laws: from the first law and the second law, the work on a closed system is its change in stored energy, minus room temperature times its entropy change, plus room temperature times the entropy generated, so it can never be less than the first two terms; heat flowing from hot to cold is exactly what raises the total entropy; and heat has no state function while heat over temperature (the entropy) does.
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Tactic

/-- The lost-work rule. A closed system takes heat `Q` and work `W`; by the first law its stored
energy changes by `ΔU = Q + W`. The room at absolute temperature `T₀ > 0` receives the heat `-Q`,
so its entropy changes by `-Q / T₀`. By the second law the total entropy change of system and room
is the entropy generated, `S_gen ≥ 0`. Then the work is
`W = ΔU - T₀ ΔS_air + T₀ S_gen`, and so it is never less than `ΔU - T₀ ΔS_air`, which depends only
on the start and end states: every joule per kelvin generated costs `T₀` times that in extra work. -/
theorem lost_work_rule (ΔU Q W ΔS_air ΔS_room S_gen T₀ : ℝ) (hT₀ : 0 < T₀)
    (first_law : ΔU = Q + W)
    (room : ΔS_room = -Q / T₀)
    (second_law : ΔS_air + ΔS_room = S_gen)
    (h_gen : 0 ≤ S_gen) :
    W = ΔU - T₀ * ΔS_air + T₀ * S_gen ∧ ΔU - T₀ * ΔS_air ≤ W := by
  have hT : T₀ ≠ 0 := hT₀.ne'
  have h1 : T₀ * S_gen = T₀ * ΔS_air - Q := by
    rw [← second_law, room]; field_simp; ring
  refine ⟨?_, ?_⟩
  · rw [h1, first_law]; ring
  · nlinarith [mul_nonneg hT₀.le h_gen]

/-- The entropy form of the second law contains the older one. A positive piece of heat `δQ`
leaving a body at absolute temperature `T_h` for one at `T_c` changes the total entropy by
`δQ (1/T_c - 1/T_h)`, and this is positive exactly when `T_h > T_c`: heat flows by itself only
from hot to cold. -/
theorem heat_flow_raises_entropy_iff_hot_to_cold (δQ T_h T_c : ℝ) (hQ : 0 < δQ)
    (hh : 0 < T_h) (hc : 0 < T_c) :
    0 < δQ * (1 / T_c - 1 / T_h) ↔ T_c < T_h := by
  have key : 1 / T_c - 1 / T_h = (T_h - T_c) / (T_c * T_h) := by
    field_simp
  rw [key]
  constructor
  · intro h
    by_contra hlt
    have hle : T_h ≤ T_c := not_lt.mp hlt
    have : (T_h - T_c) / (T_c * T_h) ≤ 0 :=
      div_nonpos_of_nonpos_of_nonneg (by linarith) (by positivity)
    nlinarith [mul_nonpos_of_nonneg_of_nonpos hQ.le this]
  · intro h
    apply mul_pos hQ
    apply div_pos (by linarith) (by positivity)

/-- Heat is not a state quantity, but heat over temperature is. For an ideal gas (`n > 0` moles,
fixed `c_v > 0`, gas constant `R > 0`) the heat taken in on a gentle step is
`δQ = n c_v dT + (n R T / V) dV`. No function `f(T, V)` on positive temperatures and volumes has
these two partial derivatives. Divided by `T`, the two pieces `n c_v / T` and `n R / V` are exactly
the partial derivatives of `S(T, V) = n c_v ln T + n R ln V`, the entropy. -/
theorem heat_has_no_state_function_but_entropy_does (n c_v R : ℝ) (hn : 0 < n) (hcv : 0 < c_v)
    (hR : 0 < R) :
    (¬ ∃ f : ℝ → ℝ → ℝ, ∀ T V : ℝ, 0 < T → 0 < V →
        HasDerivAt (fun t => f t V) (n * c_v) T ∧
        HasDerivAt (fun v => f T v) (n * R * T / V) V) ∧
    (∀ T V : ℝ, 0 < T → 0 < V →
        HasDerivAt (fun t => n * c_v * Real.log t + n * R * Real.log V) (n * c_v / T) T ∧
        HasDerivAt (fun v => n * c_v * Real.log T + n * R * Real.log v) (n * R / V) V) := by
  refine ⟨?_, ?_⟩
  · rintro ⟨f, hf⟩
    -- For each volume, the change from temperature 1 to 2 is `n c_v`.
    have hdiff : ∀ v : ℝ, 0 < v → f 2 v - f 1 v = n * c_v := by
      intro v hv
      obtain ⟨c, _, hc⟩ := exists_hasDerivAt_eq_slope (fun t => f t v) (fun _ => n * c_v)
        (by norm_num : (1:ℝ) < 2)
        (fun x hx => (hf x v (by linarith [hx.1]) hv).1.continuousAt.continuousWithinAt)
        (fun x hx => (hf x v (by linarith [hx.1]) hv).1)
      norm_num at hc
      linarith
    have hderiv : HasDerivAt (fun v => f 2 v - f 1 v) (n * R * 2 / 1 - n * R * 1 / 1) 1 :=
      (hf 2 1 (by norm_num) (by norm_num)).2.sub (hf 1 1 (by norm_num) (by norm_num)).2
    have hconst : HasDerivAt (fun v => f 2 v - f 1 v) 0 1 := by
      apply (hasDerivAt_const (1:ℝ) (n * c_v)).congr_of_eventuallyEq
      filter_upwards [Ioi_mem_nhds (by norm_num : (0:ℝ) < 1)] with v hv
      exact hdiff v hv
    have := hderiv.unique hconst
    have hnR : 0 < n * R := mul_pos hn hR
    linarith
  · intro T V hT hV
    refine ⟨?_, ?_⟩
    · have := ((Real.hasDerivAt_log hT.ne').const_mul (n * c_v)).add_const (n * R * Real.log V)
      convert this using 1
      field_simp
    · have := ((Real.hasDerivAt_log hV.ne').const_mul (n * R)).const_add (n * c_v * Real.log T)
      convert this using 1
      field_simp

-- The card's whole-number checks.
-- The squeeze from 300 cm^3 to 75 cm^3 is a volume ratio of 4.
example : (300 : ℕ) / 75 = 4 ∧ (300 : ℕ) % 75 = 0 := by decide
-- The tyre valve opens above 101,325 Pa plus 7 bar gauge (1 bar = 100,000 Pa): 801,325 Pa.
example : (101325 : ℕ) + 7 * 100000 = 801325 := by decide
-- The last step on the chart's volume axis, from 100 cm^3 to 75 cm^3, is 25 cm^3.
example : (100 : ℕ) - 75 = 25 := by decide

#print axioms lost_work_rule
#print axioms heat_flow_raises_entropy_iff_hot_to_cold
#print axioms heat_has_no_state_function_but_entropy_does
