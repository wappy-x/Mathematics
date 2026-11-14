-- Rotation: the parallel-axis rule I_P = I + m d^2 for any mass distribution centred on the spin axis, the solid-disc value I = (1/2) m R^2, and the clutch result that two equal discs lock at half speed and lose half the energy.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.PolarCoord
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory

theorem disc_polar_aux (R : ℝ) (g : ℝ → ℝ) :
    ∫ u : ℝ × ℝ, {u : ℝ × ℝ | u.1 ^ 2 + u.2 ^ 2 ≤ R ^ 2}.indicator
        (fun u => g (u.1 ^ 2 + u.2 ^ 2)) u
      = (∫ r in Set.Ioc 0 |R|, r * g (r ^ 2)) * ∫ _θ in Set.Ioo (-Real.pi) Real.pi, (1 : ℝ) := by
  rw [← integral_comp_polarCoord_symm]
  have h1 : Set.EqOn (fun p : ℝ × ℝ => p.1 • {u : ℝ × ℝ | u.1 ^ 2 + u.2 ^ 2 ≤ R ^ 2}.indicator
        (fun u => g (u.1 ^ 2 + u.2 ^ 2)) (polarCoord.symm p))
      (fun p => (Set.Iic |R|).indicator (fun r => r * g (r ^ 2)) p.1 * (1 : ℝ))
      polarCoord.target := by
    intro p hp
    have hp1 : 0 < p.1 := hp.1
    have hc : (p.1 * Real.cos p.2) ^ 2 + (p.1 * Real.sin p.2) ^ 2 = p.1 ^ 2 := by
      have := Real.sin_sq_add_cos_sq p.2
      linear_combination p.1 ^ 2 * this
    have hiff : p.1 ^ 2 ≤ R ^ 2 ↔ p.1 ≤ |R| := by
      rw [← sq_abs R]
      exact pow_le_pow_iff_left₀ hp1.le (abs_nonneg R) two_ne_zero
    simp only [polarCoord_symm_apply, Set.indicator, Set.mem_ofPred_eq, Set.mem_Iic, hc,
      smul_eq_mul, mul_one, hiff]
    split_ifs <;> simp
  rw [setIntegral_congr_fun (polarCoord.open_target.measurableSet) h1]
  rw [polarCoord_target, Measure.volume_eq_prod, ← Measure.prod_restrict,
    integral_prod_mul ((Set.Iic |R|).indicator (fun r => r * g (r ^ 2))) (fun _ => (1 : ℝ)),
    setIntegral_indicator measurableSet_Iic, Set.Ioi_inter_Iic]

theorem cylinder_aux (R h : ℝ) (φ : ℝ → ℝ) :
    ∫ p in {p : ℝ × ℝ × ℝ | p.1 ^ 2 + p.2.1 ^ 2 ≤ R ^ 2 ∧ 0 ≤ p.2.2 ∧ p.2.2 ≤ h},
        φ (p.1 ^ 2 + p.2.1 ^ 2)
      = (∫ u : ℝ × ℝ, {u : ℝ × ℝ | u.1 ^ 2 + u.2 ^ 2 ≤ R ^ 2}.indicator
          (fun u => φ (u.1 ^ 2 + u.2 ^ 2)) u)
        * ∫ z : ℝ, (Set.Icc 0 h).indicator (fun _ => (1 : ℝ)) z := by
  have hS : MeasurableSet
      {p : ℝ × ℝ × ℝ | p.1 ^ 2 + p.2.1 ^ 2 ≤ R ^ 2 ∧ 0 ≤ p.2.2 ∧ p.2.2 ≤ h} := by
    simp only [Set.ofPred_and]
    refine (measurableSet_le ?_ ?_).inter ((measurableSet_le ?_ ?_).inter
      (measurableSet_le ?_ ?_)) <;> fun_prop
  rw [← integral_indicator hS, ← volume_preserving_prodAssoc.integral_comp',
    Measure.volume_eq_prod, ← integral_prod_mul]
  congr 1
  funext q
  simp only [Set.indicator, Set.mem_ofPred_eq, Set.mem_Icc, MeasurableEquiv.prodAssoc,
    MeasurableEquiv.coe_mk, Equiv.prodAssoc_apply]
  split_ifs <;> simp_all

#print axioms disc_polar_aux
#print axioms cylinder_aux

/-- The shift-of-axis rule. A body is any finite mass distribution `μ` in space,
points written `(x, y, z)`, spinning about the `z`-axis. Its moment of inertia about
that axis is `∫ (x² + y²) dμ`. If the axis passes through the centre of mass
(the first moments `∫ x dμ` and `∫ y dμ` are zero), then about the parallel axis
through `(a, b)` the moment of inertia is the old one plus the whole mass times the
squared distance `a² + b²` between the axes: `I_P = I + m d²`. -/
theorem parallel_axis_theorem (μ : Measure (ℝ × ℝ × ℝ)) [IsFiniteMeasure μ]
    (hx : Integrable (fun p : ℝ × ℝ × ℝ => p.1) μ)
    (hy : Integrable (fun p : ℝ × ℝ × ℝ => p.2.1) μ)
    (hx2 : Integrable (fun p : ℝ × ℝ × ℝ => p.1 ^ 2) μ)
    (hy2 : Integrable (fun p : ℝ × ℝ × ℝ => p.2.1 ^ 2) μ)
    (hcx : ∫ p, p.1 ∂μ = 0) (hcy : ∫ p, p.2.1 ∂μ = 0) (a b : ℝ) :
    ∫ p, ((p.1 - a) ^ 2 + (p.2.1 - b) ^ 2) ∂μ
      = ∫ p, (p.1 ^ 2 + p.2.1 ^ 2) ∂μ + μ.real Set.univ * (a ^ 2 + b ^ 2) := by
  have e : (fun p : ℝ × ℝ × ℝ => (p.1 - a) ^ 2 + (p.2.1 - b) ^ 2)
      = fun p => (p.1 ^ 2 + p.2.1 ^ 2) + ((-2 * a) * p.1 + ((-2 * b) * p.2.1 + (a ^ 2 + b ^ 2))) := by
    funext p; ring
  have i0 : Integrable (fun p : ℝ × ℝ × ℝ => p.1 ^ 2 + p.2.1 ^ 2) μ := hx2.add hy2
  have i1 : Integrable (fun p : ℝ × ℝ × ℝ => (-2 * a) * p.1) μ := hx.const_mul _
  have i2 : Integrable (fun p : ℝ × ℝ × ℝ => (-2 * b) * p.2.1) μ := hy.const_mul _
  have i3 : Integrable (fun _ : ℝ × ℝ × ℝ => a ^ 2 + b ^ 2) μ := integrable_const _
  have i4 : Integrable (fun p : ℝ × ℝ × ℝ => (-2 * b) * p.2.1 + (a ^ 2 + b ^ 2)) μ := i2.add i3
  have i5 : Integrable (fun p : ℝ × ℝ × ℝ =>
      (-2 * a) * p.1 + ((-2 * b) * p.2.1 + (a ^ 2 + b ^ 2))) μ := i1.add i4
  rw [e, integral_add i0 i5, integral_add i1 i4, integral_add i2 i3,
    integral_const_mul, integral_const_mul, hcx, hcy, integral_const, smul_eq_mul]
  ring

/-- A uniform solid disc of density `ρ`, radius `R` and thickness `h`, spinning about
its own axis, has moment of inertia `(1/2) m R²`, where `m` is its mass
(the integral of the density over the disc). -/
theorem solid_disc_moment_of_inertia (ρ R h : ℝ) :
    let S : Set (ℝ × ℝ × ℝ) := {p | p.1 ^ 2 + p.2.1 ^ 2 ≤ R ^ 2 ∧ 0 ≤ p.2.2 ∧ p.2.2 ≤ h}
    ∫ p in S, ρ * (p.1 ^ 2 + p.2.1 ^ 2) = (1 / 2) * (∫ _p in S, ρ) * R ^ 2 := by
  intro S
  have e1 := cylinder_aux R h (fun r => ρ * r)
  have e2 := cylinder_aux R h (fun _ => ρ)
  beta_reduce at e1 e2
  rw [e1, e2, disc_polar_aux R (fun r => ρ * r), disc_polar_aux R (fun _ => ρ),
    ← intervalIntegral.integral_of_le (abs_nonneg R),
    ← intervalIntegral.integral_of_le (abs_nonneg R)]
  have f1 : (fun r : ℝ => r * (ρ * r ^ 2)) = fun r => ρ * r ^ 3 := by funext r; ring
  have f2 : (fun r : ℝ => r * ρ) = fun r => ρ * r := by funext r; ring
  rw [f1, f2, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    integral_pow, integral_id]
  have hA : |R| ^ 2 = R ^ 2 := sq_abs R
  linear_combination ((ρ * (∫ _θ in Set.Ioo (-Real.pi) Real.pi, (1 : ℝ))
    * ∫ z : ℝ, (Set.Icc 0 h).indicator (fun _ => (1 : ℝ)) z) / 4 * |R| ^ 2) * hA

/-- Clutch: a flywheel with moment of inertia `I` spinning at `ω` grabs an identical
still disc. Angular momentum is kept, so the pair locks at half the speed, and the
slipping clutch turns exactly half of the starting energy into heat. -/
theorem clutch_half_speed_half_energy (I ω ωf : ℝ) (hI : I ≠ 0)
    (hL : I * ω + I * 0 = (I + I) * ωf) :
    ωf = ω / 2 ∧
      (1 / 2) * I * ω ^ 2 - (1 / 2) * (I + I) * ωf ^ 2 = (1 / 2) * ((1 / 2) * I * ω ^ 2) := by
  have h1 : ωf = ω / 2 := by
    have h2 : I * (ω - 2 * ωf) = 0 := by linear_combination hL
    rcases mul_eq_zero.mp h2 with h | h
    · exact absurd h hI
    · linarith
  refine ⟨h1, ?_⟩
  subst h1
  ring

-- The card's flywheel in exact fractions: m = 12 kg, R = 0.15 m = 3/20 m, pin d = 0.12 m = 3/25 m.
-- I = (1/2) m R^2 = 0.135 kg m^2
example : (1 / 2 : ℚ) * 12 * (3 / 20) ^ 2 = 27 / 200 := by norm_num
-- I_P = I + m d^2 = 0.3078 kg m^2
example : (27 / 200 : ℚ) + 12 * (3 / 25) ^ 2 = 1539 / 5000 := by norm_num
-- all the mass at the rim: m R^2 = 0.270 kg m^2, twice the solid disc
example : (12 : ℚ) * (3 / 20) ^ 2 = 2 * (27 / 200) := by norm_num
-- clutch: 3000 rpm locks at 1500 rpm
example : (3000 : ℚ) / 2 = 1500 := by norm_num

#print axioms parallel_axis_theorem
#print axioms solid_disc_moment_of_inertia
#print axioms clutch_half_speed_half_energy
