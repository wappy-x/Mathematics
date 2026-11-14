-- Electric fields: a point charge's Coulomb field sends flux q/ε₀ out through every sphere centred on it, is minus the gradient of the potential q/(4πε₀r), and parallel plates give capacitance ε₀A/d.
import Mathlib.MeasureTheory.Constructions.HaarToSphere
import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.InnerProductSpace.Calculus

open MeasureTheory Metric Real InnerProductSpace

/-- Coulomb's law: the field at `x` of a charge `q` sitting at `p`, in space with permittivity `ε₀`,
is `k q (x - p) / ‖x - p‖³` with `k = 1/(4π ε₀)`: size `k q / r²`, pointing straight away from `p`. -/
noncomputable def coulombField (ε₀ q : ℝ) (p x : EuclideanSpace ℝ (Fin 3)) :
    EuclideanSpace ℝ (Fin 3) :=
  (q / (4 * π * ε₀) / ‖x - p‖ ^ 3) • (x - p)

/-- Helper: the unit sphere in 3-space has total surface measure `4π`. -/
lemma toSphere_real_univ_fin_three :
    (volume : Measure (EuclideanSpace ℝ (Fin 3))).toSphere.real Set.univ = 4 * π := by
  rw [Measure.real, Measure.toSphere_apply_univ, EuclideanSpace.volume_ball_fin_three]
  simp
  rw [ENNReal.toReal_ofReal (by positivity)]
  ring

/-- Gauss's law for a sphere round the charge: the outward flux of a point charge's field through a
sphere of any radius `r` centred on it equals the charge divided by `ε₀`. The point on the sphere is
`p + r u` for `u` on the unit sphere, the outward unit normal there is `u`, and the area element is
`r² dσ(u)`, where `σ` is the surface measure of the unit sphere (total area 4π). -/
theorem gauss_flux_through_sphere_eq_charge_div_eps0 (ε₀ q : ℝ) (p : EuclideanSpace ℝ (Fin 3))
    {r : ℝ} (hr : 0 < r) :
    ∫ u : sphere (0 : EuclideanSpace ℝ (Fin 3)) 1,
        ⟪coulombField ε₀ q p (p + r • (u : EuclideanSpace ℝ (Fin 3))),
          (u : EuclideanSpace ℝ (Fin 3))⟫_ℝ * r ^ 2 ∂(volume.toSphere) = q / ε₀ := by
  have key : ∀ u : sphere (0 : EuclideanSpace ℝ (Fin 3)) 1,
      ⟪coulombField ε₀ q p (p + r • (u : EuclideanSpace ℝ (Fin 3))),
          (u : EuclideanSpace ℝ (Fin 3))⟫_ℝ * r ^ 2 = q / (4 * π * ε₀) := by
    intro u
    have hu : ‖(u : EuclideanSpace ℝ (Fin 3))‖ = 1 := by simp
    simp only [coulombField, add_sub_cancel_left, norm_smul, hu, Real.norm_eq_abs, abs_of_pos hr,
      inner_smul_left, real_inner_self_eq_norm_sq]
    simp
    field_simp
  simp_rw [key]
  rw [integral_const, smul_eq_mul, toSphere_real_univ_fin_three]
  rcases eq_or_ne ε₀ 0 with rfl | he
  · simp
  field_simp

/-- Voltage as potential: away from the charge, the Coulomb field is minus the gradient of the
potential `V(x) = k q / ‖x - p‖`, so adding the field along any path gives the same voltage. -/
theorem coulomb_field_eq_neg_gradient_of_potential (ε₀ q : ℝ) {p x : EuclideanSpace ℝ (Fin 3)}
    (hx : x ≠ p) :
    HasGradientAt (fun y => q / (4 * π * ε₀) / ‖y - p‖) (-coulombField ε₀ q p x) x := by
  set c := q / (4 * π * ε₀)
  have hv : x - p ≠ 0 := sub_ne_zero.mpr hx
  have hr : ‖x - p‖ ≠ 0 := norm_ne_zero_iff.mpr hv
  have h1 := ((hasFDerivAt_id x).sub_const p).norm_sq
  have h2 := h1.sqrt (by simpa using hr)
  have h3 := ((hasDerivAt_inv (by simpa using hr : √(‖x - p‖ ^ 2) ≠ 0)).const_mul c).comp_hasFDerivAt
    x h2
  rw [hasGradientAt_iff_hasFDerivAt]
  convert h3 using 1
  · funext y
    simp [Real.sqrt_sq (norm_nonneg _), div_eq_mul_inv]
  · ext w
    simp [coulombField, Real.sqrt_sq (norm_nonneg _)]
    simp only [c]
    field_simp

/-- Parallel plates: with charge `Q` on plates of area `A` a gap `d` apart, the field is
`E = σ/ε₀` with `σ = Q/A`, the voltage is `V = E d`, and the capacitance `C = Q/V` equals `ε₀ A / d`. -/
theorem parallel_plate_capacitance (Q A d ε₀ : ℝ) (hQ : Q ≠ 0) :
    Q / ((Q / A / ε₀) * d) = ε₀ * A / d := by
  rcases eq_or_ne A 0 with rfl | hA
  · simp
  rcases eq_or_ne ε₀ 0 with rfl | he
  · simp
  rcases eq_or_ne d 0 with rfl | hd
  · simp
  field_simp

#print axioms toSphere_real_univ_fin_three
#print axioms gauss_flux_through_sphere_eq_charge_div_eps0
#print axioms coulomb_field_eq_neg_gradient_of_potential
#print axioms parallel_plate_capacitance
