-- Moment maps: for yaw turning the plane's phase space, the angular momentum J = x p_y − y p_x is the moment map, it stays constant along the flow of every energy the turns leave unchanged, and on the level J = c the energy reduces to the one-freedom energy p_r²/(2m) + c²/(2 m r²) − k/r.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Prod

namespace MomentMaps

/-! A state of a body in the plane is `z = (x, y, p_x, p_y)`, stored as `z : Fin 4 → ℝ` with
`z 0 = x`, `z 1 = y`, `z 2 = p_x`, `z 3 = p_y`. The symplectic form is
`ω = dx ∧ dp_x + dy ∧ dp_y`, so the Hamiltonian flow of a function `H` is the field
`X_H = (∂H/∂p_x, ∂H/∂p_y, −∂H/∂x, −∂H/∂y)`, the one with `ι_{X_H} ω = dH`. -/

/-- The angular momentum `J = x p_y − y p_x`. -/
def angMom (z : Fin 4 → ℝ) : ℝ := z 0 * z 3 - z 1 * z 2

/-- Yaw by the angle `s`: position and momentum turn together. -/
noncomputable def yaw (s : ℝ) (z : Fin 4 → ℝ) : Fin 4 → ℝ :=
  ![Real.cos s * z 0 - Real.sin s * z 1, Real.sin s * z 0 + Real.cos s * z 1,
    Real.cos s * z 2 - Real.sin s * z 3, Real.sin s * z 2 + Real.cos s * z 3]

/-- The partial derivative of `H` along coordinate `i` at the state `z`. -/
noncomputable def pd (H : (Fin 4 → ℝ) → ℝ) (z : Fin 4 → ℝ) (i : Fin 4) : ℝ :=
  fderiv ℝ H z (Pi.single i 1)

/-- The Hamiltonian flow of `H` for `ω = dx ∧ dp_x + dy ∧ dp_y`:
`X_H = (∂H/∂p_x, ∂H/∂p_y, −∂H/∂x, −∂H/∂y)`. -/
noncomputable def hamField (H : (Fin 4 → ℝ) → ℝ) (z : Fin 4 → ℝ) : Fin 4 → ℝ :=
  ![pd H z 2, pd H z 3, -pd H z 0, -pd H z 1]

/-- The derivative of the yaw turn at angle zero. -/
theorem yaw_hasDerivAt_zero (z : Fin 4 → ℝ) :
    HasDerivAt (fun s => yaw s z) ![-z 1, z 0, -z 3, z 2] 0 := by
  rw [hasDerivAt_pi]
  intro i
  fin_cases i
  · have := (((Real.hasDerivAt_cos 0).mul_const (z 0)).sub ((Real.hasDerivAt_sin 0).mul_const (z 1)))
    convert this using 1 <;> simp [yaw]; rfl
  · have := (((Real.hasDerivAt_sin 0).mul_const (z 0)).add ((Real.hasDerivAt_cos 0).mul_const (z 1)))
    convert this using 1 <;> simp [yaw]; rfl
  · have := (((Real.hasDerivAt_cos 0).mul_const (z 2)).sub ((Real.hasDerivAt_sin 0).mul_const (z 3)))
    convert this using 1 <;> simp [yaw]; rfl
  · have := (((Real.hasDerivAt_sin 0).mul_const (z 2)).add ((Real.hasDerivAt_cos 0).mul_const (z 3)))
    convert this using 1 <;> simp [yaw]; rfl

/-- A vector of `Fin 4 → ℝ` as a sum of the coordinate vectors. -/
theorem vec_eq_sum_single (v : Fin 4 → ℝ) :
    v = v 0 • Pi.single 0 1 + v 1 • Pi.single 1 1 + v 2 • Pi.single 2 1 + v 3 • Pi.single 3 1 := by
  ext i; fin_cases i <;> simp

/-- The derivative of the angular momentum. -/
theorem angMom_hasFDerivAt (z : Fin 4 → ℝ) :
    HasFDerivAt angMom
      ((z 0 • ContinuousLinearMap.proj 3 + z 3 • ContinuousLinearMap.proj 0) -
        (z 1 • ContinuousLinearMap.proj 2 + z 2 • ContinuousLinearMap.proj 1) :
          (Fin 4 → ℝ) →L[ℝ] ℝ) z := by
  have h0 := hasFDerivAt_apply (𝕜 := ℝ) (0 : Fin 4) z
  have h1 := hasFDerivAt_apply (𝕜 := ℝ) (1 : Fin 4) z
  have h2 := hasFDerivAt_apply (𝕜 := ℝ) (2 : Fin 4) z
  have h3 := hasFDerivAt_apply (𝕜 := ℝ) (3 : Fin 4) z
  exact (h0.mul h3).sub (h1.mul h2)

theorem angMom_pd (z : Fin 4 → ℝ) :
    pd angMom z 0 = z 3 ∧ pd angMom z 1 = -z 2 ∧ pd angMom z 2 = -z 1 ∧ pd angMom z 3 = z 0 := by
  simp only [pd, (angMom_hasFDerivAt z).fderiv]
  simp

/-- **The moment map is conserved.** Let `H` be an energy that yaw leaves unchanged,
`H(g · z) = H(z)` for every turn `g`. Along any motion that follows Hamilton's equations for
`H` (with `H` differentiable at the states it passes through), the moment map of yaw, the
angular momentum `J = x p_y − y p_x`, keeps its starting value: `dJ/dt = {J, H} = 0`. -/
theorem moment_map_conserved_by_invariant_energy (H : (Fin 4 → ℝ) → ℝ)
    (hinv : ∀ s z, H (yaw s z) = H z)
    (γ : ℝ → Fin 4 → ℝ) (hdiff : ∀ t, DifferentiableAt ℝ H (γ t))
    (hflow : ∀ t, HasDerivAt γ (hamField H (γ t)) t) :
    ∀ t, angMom (γ t) = angMom (γ 0) := by
  have hderiv : ∀ t, HasDerivAt (fun t => angMom (γ t)) 0 t := by
    intro t
    set z := γ t with hz
    have hyaw0 : yaw 0 z = z := by
      ext i; fin_cases i <;> simp [yaw]
    have hH : HasFDerivAt H (fderiv ℝ H z) (yaw 0 z) := by
      rw [hyaw0]; exact (hdiff t).hasFDerivAt
    have hcomp := hH.comp_hasDerivAt (0 : ℝ) (yaw_hasDerivAt_zero z)
    have hconst : HasDerivAt (H ∘ fun s => yaw s z) 0 0 := by
      have : (H ∘ fun s => yaw s z) = fun _ => H z := by
        funext s; simp [hinv]
      rw [this]; exact hasDerivAt_const _ _
    have hzero := hcomp.unique hconst
    rw [vec_eq_sum_single ![-z 1, z 0, -z 3, z 2]] at hzero
    simp only [map_add, map_smul] at hzero
    have hJ := (angMom_hasFDerivAt z).comp_hasDerivAt t (hflow t)
    refine hJ.congr_deriv ?_
    simp [hamField, pd] at hzero ⊢
    linear_combination -hzero
  intro t
  have hd : Differentiable ℝ (fun t => angMom (γ t)) := fun t => (hderiv t).differentiableAt
  exact is_const_of_deriv_eq_zero hd (fun t => (hderiv t).deriv) t 0

/-- **Angular momentum is the moment map of yaw.** The Hamiltonian flow of
`J = x p_y − y p_x` is exactly the velocity of the turn at angle zero,
`X = (−y, x, −p_y, p_x)`; that is, `ι_X ω = dJ`. -/
theorem angular_momentum_is_moment_map_of_yaw (z : Fin 4 → ℝ) :
    hamField angMom z = deriv (fun s => yaw s z) 0 ∧
    hamField angMom z = ![-z 1, z 0, -z 3, z 2] := by
  have h2 : hamField angMom z = ![-z 1, z 0, -z 3, z 2] := by
    obtain ⟨a, b, c, d⟩ := angMom_pd z
    simp only [hamField, a, b, c, d, neg_neg]
  exact ⟨by rw [(yaw_hasDerivAt_zero z).deriv, h2], h2⟩

/-- **Reduction of the turning plane.** Away from the centre, write `r = √(x² + y²)` and the
radial momentum `p_r = (x p_x + y p_y)/r`. On the level set `J = c`, the energy of a body of
mass `m` pulled by `k/r²` equals the reduced energy of one radial freedom:
`(p_x² + p_y²)/(2m) − k/r = p_r²/(2m) + c²/(2 m r²) − k/r`. -/
theorem energy_reduces_on_level_set (m k c x y px py : ℝ) (hr : x ^ 2 + y ^ 2 ≠ 0)
    (hJ : x * py - y * px = c) :
    (px ^ 2 + py ^ 2) / (2 * m) - k / Real.sqrt (x ^ 2 + y ^ 2) =
      ((x * px + y * py) / Real.sqrt (x ^ 2 + y ^ 2)) ^ 2 / (2 * m)
        + c ^ 2 / (2 * m * Real.sqrt (x ^ 2 + y ^ 2) ^ 2) - k / Real.sqrt (x ^ 2 + y ^ 2) := by
  have hpos : 0 ≤ x ^ 2 + y ^ 2 := by positivity
  have hs2 : Real.sqrt (x ^ 2 + y ^ 2) ^ 2 = x ^ 2 + y ^ 2 := Real.sq_sqrt hpos
  have key : ((x * px + y * py) / Real.sqrt (x ^ 2 + y ^ 2)) ^ 2
      + c ^ 2 / Real.sqrt (x ^ 2 + y ^ 2) ^ 2 = px ^ 2 + py ^ 2 := by
    rw [div_pow, hs2, ← hJ, ← add_div, div_eq_iff hr]
    ring
  rw [← key, add_div, div_div, mul_comm (Real.sqrt (x ^ 2 + y ^ 2) ^ 2) (2 * m)]

/-! The card's exact worked numbers: mass 1 kg, pull 12 N m², start 2 m east with momentum
3 kg m/s north. -/

-- The moment map at the start: J = 2 × 3 − 0 × 0 = 6 kg m²/s.
example : angMom ![2, 0, 0, 3] = 6 := by norm_num [angMom]
-- Energy: kinetic (0² + 3²)/(2 × 1) = 9/2 J, pull 12/2 = 6 J, so E = −3/2 J.
example : ((0 : ℚ) ^ 2 + 3 ^ 2) / (2 * 1) = 9 / 2 ∧ (12 : ℚ) / 2 = 6 ∧
    (9 / 2 : ℚ) - 6 = -3 / 2 := by norm_num
-- Turning points: V_eff(r) = 36/(2r²) − 12/r equals −3/2 at r = 2 and r = 6, the roots of
-- r² − 8r + 12 = 0.
example : (36 : ℚ) / (2 * 2 ^ 2) - 12 / 2 = -3 / 2 ∧ (36 : ℚ) / (2 * 6 ^ 2) - 12 / 6 = -3 / 2 ∧
    (2 : ℚ) ^ 2 - 8 * 2 + 12 = 0 ∧ (6 : ℚ) ^ 2 - 8 * 6 + 12 = 0 := by norm_num
-- Well bottom: r = c²/(mk) = 36/12 = 3 m, where V_eff = 36/18 − 12/3 = −2 J.
example : (6 : ℚ) ^ 2 / (1 * 12) = 3 ∧ (36 : ℚ) / (2 * 3 ^ 2) - 12 / 3 = -2 := by norm_num
-- The chart's first point: V_eff(3/2) = 36/(2 × 9/4) − 12/(3/2) = 8 − 8 = 0 J.
example : (36 : ℚ) / (2 * (3 / 2) ^ 2) - 12 / (3 / 2) = 0 := by norm_num
-- Half the longest width a = (2 + 6)/2 = 4 m, and m a³/k = 64/12 = 16/3 under the period's root.
example : ((2 : ℚ) + 6) / 2 = 4 ∧ (1 * 4 ^ 3 : ℚ) / 12 = 16 / 3 := by norm_num
-- Wind 1/20 N at the test state y = −7/10 m: {J, H} = −y F = 7/200 = 0.035 kg m²/s².
example : -(-7 / 10 : ℚ) * (1 / 20) = 7 / 200 := by norm_num
-- All turns of space: r = (2, 0, 1/2), p = (0, 3, 2/5) give J = r × p = (−3/2, −4/5, 6).
example : crossProduct ![(2 : ℚ), 0, 1 / 2] ![0, 3, 2 / 5] = ![-3 / 2, -4 / 5, 6] := by
  ext i; fin_cases i <;> norm_num [cross_apply]
-- Dimension counts dim M − dim G − dim G_c: 4 − 1 − 1 = 2 (yaw on the plane) and
-- 6 − 3 − 1 = 2 (all turns of space).
example : (4 : ℤ) - 1 - 1 = 2 ∧ (6 : ℤ) - 3 - 1 = 2 := by norm_num

#print axioms yaw_hasDerivAt_zero
#print axioms vec_eq_sum_single
#print axioms angMom_hasFDerivAt
#print axioms angMom_pd
#print axioms moment_map_conserved_by_invariant_energy
#print axioms angular_momentum_is_moment_map_of_yaw
#print axioms energy_reduces_on_level_set

end MomentMaps
