-- Action-angle variables and KAM: the spring's loop H = p^2/2 + omega^2 q^2/2 = E encloses area 2 pi E / omega, so its action is J = E / omega; the angle coordinates turn at the constant rate omega with energy omega J; and the kicked wheel (standard map) keeps area.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Measure.Lebesgue.Integral
import Mathlib.MeasureTheory.Group.Prod
import Mathlib.Dynamics.Ergodic.MeasurePreserving
import Mathlib.Data.Nat.Fib.Basic
import Mathlib.Tactic.NormNum

open MeasureTheory Real

/-- Helper: the unit disc in the plane has area pi. -/
theorem unit_disc_area :
    volume {y : ℝ × ℝ | y.1 ^ 2 + y.2 ^ 2 ≤ 1} = ENNReal.ofReal π := by
  have hset : {y : ℝ × ℝ | y.1 ^ 2 + y.2 ^ 2 ≤ 1} =
      Complex.measurableEquivRealProd.symm ⁻¹' Metric.closedBall (0 : ℂ) 1 := by
    ext y
    simp only [Set.mem_ofPred_eq, Set.mem_preimage, Metric.mem_closedBall, dist_zero_right,
      Complex.measurableEquivRealProd_symm_apply, Complex.norm_def, Complex.normSq_mk]
    rw [Real.sqrt_le_one]
    constructor <;> intro h <;> nlinarith
  rw [hset, (Complex.volume_preserving_equiv_real_prod.symm).measure_preimage
    measurableSet_closedBall.nullMeasurableSet, Complex.volume_closedBall]
  simp [← NNReal.coe_real_pi, ENNReal.ofReal_coe_nnreal]

#print axioms unit_disc_area

/-- The action of the spring is its loop's area over 2 pi. For the oscillator
H = p^2/2 + omega^2 q^2/2 with rate omega > 0, at energy E > 0 (so the motion repeats on a
closed loop), the region the loop encloses in the (position, momentum) plane has area
2 pi E / omega. So the action J = area / (2 pi) equals E / omega, and the energy is H = omega J. -/
theorem oscillator_action_eq_energy_div_rate (ω E : ℝ) (hω : 0 < ω) (hE : 0 < E) :
    volume {x : ℝ × ℝ | x.2 ^ 2 / 2 + ω ^ 2 * x.1 ^ 2 / 2 ≤ E} =
      ENNReal.ofReal (2 * π * (E / ω)) := by
  set s := √(2 * E) with hs
  have hs0 : 0 < s := Real.sqrt_pos.2 (by linarith)
  have hs2 : s ^ 2 = 2 * E := Real.sq_sqrt (by linarith)
  let f : ℝ × ℝ →ₗ[ℝ] ℝ × ℝ :=
    LinearMap.prodMap ((ω / s) • LinearMap.id) ((1 / s) • LinearMap.id)
  have hdet : LinearMap.det f = ω / (2 * E) := by
    simp only [f, LinearMap.det_prodMap, LinearMap.det_smul, LinearMap.det_id, Module.finrank_self]
    rw [← hs2]; field_simp
  have hset : {x : ℝ × ℝ | x.2 ^ 2 / 2 + ω ^ 2 * x.1 ^ 2 / 2 ≤ E} =
      f ⁻¹' {y : ℝ × ℝ | y.1 ^ 2 + y.2 ^ 2 ≤ 1} := by
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_preimage, f, LinearMap.prodMap_apply,
      LinearMap.smul_apply, LinearMap.id_apply, smul_eq_mul]
    rw [div_mul_eq_mul_div, one_div_mul_eq_div, div_pow, div_pow, ← add_div, hs2]
    rw [← add_div, div_le_one (by linarith)]
    constructor <;> intro h <;> nlinarith
  rw [hset, Measure.addHaar_preimage_linearMap _ (by rw [hdet]; positivity), unit_disc_area, hdet,
    ← ENNReal.ofReal_mul (abs_nonneg _)]
  congr 1
  rw [inv_div, abs_of_pos (by positivity)]
  field_simp

/-- Action-angle coordinates for the spring. With action J ≥ 0 and angle theta = omega t + theta0,
the point q = sqrt(2J/omega) sin theta, p = sqrt(2J omega) cos theta solves Hamilton's equations
q' = p, p' = -omega^2 q at every time, and its energy p^2/2 + omega^2 q^2/2 is omega J at every
time: the action stays fixed and the angle advances at the constant rate omega. -/
theorem oscillator_angle_turns_at_constant_rate (ω J θ₀ : ℝ) (hω : 0 < ω) (hJ : 0 ≤ J) (t : ℝ) :
    let q : ℝ → ℝ := fun s => √(2 * J / ω) * Real.sin (ω * s + θ₀)
    let p : ℝ → ℝ := fun s => √(2 * J * ω) * Real.cos (ω * s + θ₀)
    HasDerivAt q (p t) t ∧ HasDerivAt p (-(ω ^ 2 * q t)) t ∧
      p t ^ 2 / 2 + ω ^ 2 * q t ^ 2 / 2 = ω * J := by
  intro q p
  have key : √(2 * J / ω) * ω = √(2 * J * ω) := by
    rw [show 2 * J * ω = 2 * J / ω * ω ^ 2 by field_simp, Real.sqrt_mul (by positivity),
      Real.sqrt_sq hω.le]
  have hlin : HasDerivAt (fun s : ℝ => ω * s + θ₀) ω t := by
    simpa using ((hasDerivAt_id t).const_mul ω).add_const θ₀
  refine ⟨?_, ?_, ?_⟩
  · have := ((hlin.sin).const_mul (√(2 * J / ω)))
    convert this using 1
    simp only [p]; rw [← key]; ring
  · have := ((hlin.cos).const_mul (√(2 * J * ω)))
    convert this using 1
    simp only [q]; rw [← key]; ring
  · simp only [p, q]
    rw [mul_pow, mul_pow, Real.sq_sqrt (by positivity), Real.sq_sqrt (by positivity)]
    have := Real.sin_sq_add_cos_sq (ω * t + θ₀)
    have h2 : ω ^ 2 * (2 * J / ω) = 2 * J * ω := by field_simp
    calc 2 * J * ω * cos (ω * t + θ₀) ^ 2 / 2 + ω ^ 2 * (2 * J / ω * sin (ω * t + θ₀) ^ 2) / 2
        = ω * J * (sin (ω * t + θ₀) ^ 2 + cos (ω * t + θ₀) ^ 2) := by
          rw [← mul_assoc, h2]; ring
      _ = ω * J := by rw [this, mul_one]

/-- The kicked wheel keeps area. The standard map
(theta, p) ↦ (theta + p + K sin theta, p + K sin theta), for any kick strength K,
preserves area in the (angle, momentum) plane. -/
theorem standard_map_keeps_area (K : ℝ) :
    MeasurePreserving
      (fun x : ℝ × ℝ => (x.1 + (x.2 + K * Real.sin x.1), x.2 + K * Real.sin x.1))
      volume volume := by
  have h1 : MeasurePreserving (fun x : ℝ × ℝ => (x.1, x.2 + K * Real.sin x.1))
      (volume : Measure (ℝ × ℝ)) volume := by
    have := (MeasurePreserving.id (volume : Measure ℝ)).skew_product
      (g := fun a b => b + K * Real.sin a) (by fun_prop)
      (Filter.Eventually.of_forall fun a => (measurePreserving_add_right volume _).map_eq)
    exact this
  have h2 : MeasurePreserving (fun x : ℝ × ℝ => (x.1 + x.2, x.2))
      (volume : Measure (ℝ × ℝ)) volume := by
    have := (MeasurePreserving.id (volume : Measure ℝ)).skew_product
      (g := fun (a b : ℝ) => b + a) (by fun_prop)
      (Filter.Eventually.of_forall fun a => (measurePreserving_add_right volume _).map_eq)
    have hs := (Measure.measurePreserving_swap (μ := (volume : Measure ℝ)) (ν := (volume : Measure ℝ)))
    have := (hs.comp this).comp hs
    convert this using 1
    funext x; simp [add_comm]
  exact h2.comp h1

-- Worked numbers, by hand: omega^2 / 2 = 2 gives omega = 2.
example : (2 : ℚ) ^ 2 / 2 = 2 := by norm_num
-- Widest swing: 2 q^2 = 1 at q^2 = 1/2; peak momentum: p^2 / 2 = 1 at p^2 = 2.
example : 2 * (1 / 2 : ℚ) = 1 ∧ (2 : ℚ) / 2 = 1 := by norm_num
-- Action J = E / omega = 1/2, and the energy back is omega J = 2 * 1/2 = 1.
example : (1 : ℚ) / 2 = 1 / 2 ∧ (2 : ℚ) * (1 / 2) = 1 := by norm_num
-- Mistake: only the upper half of the loop gives J = 1/4.
example : (1 / 2 : ℚ) / 2 = 1 / 4 := by norm_num
-- Four times the energy (Try changing): J = 4 / 2 = 2.
example : (4 : ℚ) / 2 = 2 := by norm_num
-- The golden mean's best fractions are Fibonacci ratios: 21/34, 34/55, 55/89, and 5/8, 8/13, 13/21.
example : Nat.fib 5 = 5 ∧ Nat.fib 6 = 8 ∧ Nat.fib 7 = 13 ∧ Nat.fib 8 = 21 ∧ Nat.fib 9 = 34 ∧
    Nat.fib 10 = 55 ∧ Nat.fib 11 = 89 := by decide

#print axioms oscillator_action_eq_energy_div_rate
#print axioms oscillator_angle_turns_at_constant_rate
#print axioms standard_map_keeps_area
