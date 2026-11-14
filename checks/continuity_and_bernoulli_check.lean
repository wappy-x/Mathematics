-- Continuity and Bernoulli: integrating Euler's equation along a streamline gives Bernoulli's equation, equal flow through a narrower section means faster water at lower pressure, and a sudden widening loses exactly half rho times the speed change squared.
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Order.Interval.Set.UnorderedInterval

open Set

/-- Helper: the Bernoulli sum is the same at both ends of an ordered stretch `a < b`. -/
theorem bernoulli_helper (ρ g a b : ℝ) (v p z : ℝ → ℝ) (hab : a < b)
    (hv : ContinuousOn v (Icc a b)) (hp : ContinuousOn p (Icc a b))
    (hz : ContinuousOn z (Icc a b))
    (hv' : ∀ s ∈ Ioo a b, DifferentiableAt ℝ v s)
    (hp' : ∀ s ∈ Ioo a b, DifferentiableAt ℝ p s)
    (hz' : ∀ s ∈ Ioo a b, DifferentiableAt ℝ z s)
    (euler : ∀ s ∈ Ioo a b, ρ * v s * deriv v s = -deriv p s - ρ * g * deriv z s) :
    p a + 1 / 2 * ρ * v a ^ 2 + ρ * g * z a = p b + 1 / 2 * ρ * v b ^ 2 + ρ * g * z b := by
  set F : ℝ → ℝ := fun s => p s + 1 / 2 * ρ * v s ^ 2 + ρ * g * z s with hF
  have hFc : ContinuousOn F (Icc a b) := by
    have h2 : ContinuousOn (fun s => 1 / 2 * ρ * v s ^ 2) (Icc a b) :=
      continuousOn_const.mul (hv.pow 2)
    have h3 : ContinuousOn (fun s => ρ * g * z s) (Icc a b) := continuousOn_const.mul hz
    exact (hp.add h2).add h3
  have hFd : ∀ s ∈ Ioo a b, HasDerivAt F
      (deriv p s + 1 / 2 * ρ * (2 * v s * deriv v s) + ρ * g * deriv z s) s := by
    intro s hs
    have h1 := (hp' s hs).hasDerivAt
    have h2 := ((hv' s hs).hasDerivAt.pow 2).const_mul (1 / 2 * ρ)
    have h3 := (hz' s hs).hasDerivAt.const_mul (ρ * g)
    have := (h1.add h2).add h3
    convert this using 1
    · push_cast; ring
  obtain ⟨c, hc, hc'⟩ := exists_hasDerivAt_eq_slope F _ hab hFc hFd
  have h0 : deriv p c + 1 / 2 * ρ * (2 * v c * deriv v c) + ρ * g * deriv z c = 0 := by
    have := euler c hc
    linarith
  rw [h0, eq_comm, div_eq_zero_iff] at hc'
  rcases hc' with h | h
  · simp only [hF] at h; linarith
  · exact absurd h (sub_ne_zero.mpr hab.ne')

#print axioms bernoulli_helper

/-- Bernoulli's equation along a streamline.  Let `s` be distance along the streamline, and
let the speed `v s`, pressure `p s` and height `z s` be continuous on the stretch between
`s₁` and `s₂` and differentiable inside it.  If the fluid has fixed density `ρ` (it does not
compress) and Euler's equation for flow without friction holds along the streamline,
`ρ v dv/ds = -dp/ds - ρ g dz/ds`, then pressure plus kinetic energy per cubic metre plus
height energy per cubic metre is the same at both ends. -/
theorem bernoulli_along_streamline (ρ g s₁ s₂ : ℝ) (v p z : ℝ → ℝ)
    (hv : ContinuousOn v (uIcc s₁ s₂)) (hp : ContinuousOn p (uIcc s₁ s₂))
    (hz : ContinuousOn z (uIcc s₁ s₂))
    (hv' : ∀ s ∈ uIoo s₁ s₂, DifferentiableAt ℝ v s)
    (hp' : ∀ s ∈ uIoo s₁ s₂, DifferentiableAt ℝ p s)
    (hz' : ∀ s ∈ uIoo s₁ s₂, DifferentiableAt ℝ z s)
    (euler : ∀ s ∈ uIoo s₁ s₂, ρ * v s * deriv v s = -deriv p s - ρ * g * deriv z s) :
    p s₁ + 1 / 2 * ρ * v s₁ ^ 2 + ρ * g * z s₁ = p s₂ + 1 / 2 * ρ * v s₂ ^ 2 + ρ * g * z s₂ := by
  rcases lt_trichotomy s₁ s₂ with h | h | h
  · rw [uIcc_of_le h.le] at hv hp hz
    rw [uIoo_of_lt h] at hv' hp' hz' euler
    exact bernoulli_helper ρ g s₁ s₂ v p z h hv hp hz hv' hp' hz' euler
  · subst h; rfl
  · rw [uIcc_of_ge h.le] at hv hp hz
    rw [uIoo_of_gt h] at hv' hp' hz' euler
    exact (bernoulli_helper ρ g s₂ s₁ v p z h hv hp hz hv' hp' hz' euler).symm

/-- A narrower pipe carries faster water, and faster water sits at lower pressure.  In a level
pipe (`z₁ = z₂`), if the same volume crosses both sections each second (`A₁ v₁ = A₂ v₂`), the
second section is narrower (`0 < A₂ < A₁`), the water moves forward (`0 < v₁`), the density is
positive and Bernoulli's equation holds between the sections, then the water in the narrow
section is faster and its pressure is lower. -/
theorem narrower_pipe_faster_lower_pressure (ρ g A₁ A₂ v₁ v₂ p₁ p₂ z₁ z₂ : ℝ)
    (hρ : 0 < ρ) (hA₂ : 0 < A₂) (hA : A₂ < A₁) (hv₁ : 0 < v₁) (hlevel : z₁ = z₂)
    (continuity : A₁ * v₁ = A₂ * v₂)
    (bernoulli : p₁ + 1 / 2 * ρ * v₁ ^ 2 + ρ * g * z₁ = p₂ + 1 / 2 * ρ * v₂ ^ 2 + ρ * g * z₂) :
    v₁ < v₂ ∧ p₂ < p₁ := by
  subst hlevel
  have hv₂ : v₁ < v₂ := by nlinarith
  refine ⟨hv₂, ?_⟩
  have : v₁ ^ 2 < v₂ ^ 2 := by nlinarith
  nlinarith

/-- The Borda–Carnot loss at a sudden widening.  The pressure Bernoulli promises back,
`½ρ(v₂² - v₁²)`, minus the pressure the momentum balance actually gives, `ρ v₁ (v₂ - v₁)`, is
exactly `½ρ(v₂ - v₁)²`, which is never negative. -/
theorem borda_carnot_loss (ρ v₁ v₂ : ℝ) :
    1 / 2 * ρ * (v₂ ^ 2 - v₁ ^ 2) - ρ * v₁ * (v₂ - v₁) = 1 / 2 * ρ * (v₂ - v₁) ^ 2 ∧
    (0 ≤ ρ → ρ * v₁ * (v₂ - v₁) ≤ 1 / 2 * ρ * (v₂ ^ 2 - v₁ ^ 2)) := by
  refine ⟨by ring, fun h => ?_⟩
  nlinarith [sq_nonneg (v₂ - v₁), mul_nonneg h (sq_nonneg (v₂ - v₁))]

#print axioms bernoulli_along_streamline
#print axioms narrower_pipe_faster_lower_pressure
#print axioms borda_carnot_loss
