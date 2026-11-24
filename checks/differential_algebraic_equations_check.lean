-- Differential-algebraic equations: an invertible ∂g/∂z makes the constraint fix z = φ(y), implicit Runge-Kutta stages on such a DAE are the same stages on the reduced ODE, and the card's RC circuit has the stated exact and backward-Euler solutions.
import Mathlib.Analysis.Calculus.ImplicitFunction.ProdDomain
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Algebra.BigOperators.Fin

open Filter Topology

/-- Index-1 test (Step 0 and Step A of the card). For a semi-explicit DAE
`y' = f(y, z), 0 = g(y, z)`, if `g` is differentiable at a consistent point `(y₀, z₀)`
(so `g(y₀, z₀) = 0`) and its partial derivative `∂g/∂z` there is invertible, then the
constraint hides a formula `z = φ(y)`: near the point, `g(y, z) = 0` holds exactly when
`z = φ(y)`, with `φ(y₀) = z₀`, `g(y, φ y) = 0` for `y` near `y₀`, and `φ` differentiable
with derivative `-(∂g/∂z)⁻¹ ∘ ∂g/∂y`. -/
theorem index_one_constraint_fixes_algebraic_unknown
    {E F : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
    [NormedAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F]
    (g : E × F → F) (g' : E × F →L[ℝ] F) (y₀ : E) (z₀ : F)
    (hg : HasStrictFDerivAt g g' (y₀, z₀))
    (hz : (g'.comp (ContinuousLinearMap.inr ℝ E F)).IsInvertible)
    (hcons : g (y₀, z₀) = 0) :
    ∃ φ : E → F, φ y₀ = z₀ ∧
      (∀ᶠ p in 𝓝 (y₀, z₀), g p = 0 ↔ p.2 = φ p.1) ∧
      (∀ᶠ y in 𝓝 y₀, g (y, φ y) = 0) ∧
      HasStrictFDerivAt φ
        (-(g'.comp (ContinuousLinearMap.inr ℝ E F)).inverse.comp
          (g'.comp (ContinuousLinearMap.inl ℝ E F))) y₀ := by
  refine ⟨hg.implicitFunctionOfProdDomain hz, ?_, ?_, ?_, ?_⟩
  · exact ((hg.eventually_apply_eq_iff_implicitFunctionOfProdDomain hz).self_of_nhds.mp rfl)
  · filter_upwards [hg.eventually_apply_eq_iff_implicitFunctionOfProdDomain hz] with p hp
    rw [hcons] at hp
    rw [hp]
    exact eq_comm
  · have := hg.eventually_apply_implicitFunctionOfProdDomain hz
    simpa [hcons] using this
  · exact hg.hasStrictFDerivAt_implicitFunctionOfProdDomain hz

/-- Step C and Step E of the card: on an index-1 DAE, where the constraint `g = 0` holds
on a region `U` exactly when `z = φ(y)`, the stage equations of an implicit Runge-Kutta
method with stage matrix `A` (backward Euler: one stage, `A = 1`; Radau IIA: two stages)
applied to the DAE, `Yᵢ = yₙ + h Σⱼ aᵢⱼ f(Yⱼ, Zⱼ)` and `0 = g(Yᵢ, Zᵢ)`, have exactly the
same solutions as that method on the reduced ODE `y' = f(y, φ(y))`, with `Zᵢ = φ(Yᵢ)`. -/
theorem implicit_rk_on_index_one_dae_is_rk_on_reduced_ode
    {E F : Type*} [AddCommGroup E] [Module ℝ E] [Zero F] {s : ℕ}
    (f : E × F → E) (g : E × F → F) (φ : E → F) (U : Set (E × F))
    (hφ : ∀ p ∈ U, g p = 0 ↔ p.2 = φ p.1)
    (A : Fin s → Fin s → ℝ) (h : ℝ) (yn : E) (Y : Fin s → E) (Z : Fin s → F)
    (hU : ∀ i, (Y i, Z i) ∈ U) :
    (∀ i, Y i = yn + h • ∑ j, A i j • f (Y j, Z j) ∧ g (Y i, Z i) = 0) ↔
      (∀ i, Y i = yn + h • ∑ j, A i j • f (Y j, φ (Y j)) ∧ Z i = φ (Y i)) := by
  have key : ∀ i, g (Y i, Z i) = 0 ↔ Z i = φ (Y i) := fun i => hφ _ (hU i)
  constructor
  · intro H
    have hZ : ∀ i, Z i = φ (Y i) := fun i => (key i).mp (H i).2
    intro i
    refine ⟨?_, hZ i⟩
    rw [(H i).1]
    congr 2
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [hZ j]
  · intro H
    have hZ : ∀ i, Z i = φ (Y i) := fun i => (H i).2
    intro i
    refine ⟨?_, (key i).mpr (hZ i)⟩
    rw [(H i).1]
    congr 2
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [hZ j]

/-- The card's RC circuit `y' = -y + z, 0 = y + z - 1, y(0) = 0`: the exact solution is
`y = (1 - e^(-2t))/2, z = 1 - y`, and backward Euler with `h = 0.1`, solving the pair at
each new point, gives `yₙ = 0.5 (1 - 1.2^(-n))` and `zₙ = 1 - yₙ` for every step `n ≥ 1`. -/
theorem rc_circuit_exact_and_backward_euler :
    (∀ t : ℝ,
      HasDerivAt (fun t => (1 - Real.exp (-2 * t)) / 2)
        (-((1 - Real.exp (-2 * t)) / 2) + (1 - (1 - Real.exp (-2 * t)) / 2)) t ∧
      (1 - Real.exp (-2 * t)) / 2 + (1 - (1 - Real.exp (-2 * t)) / 2) - 1 = 0) ∧
    (1 - Real.exp (-2 * 0)) / 2 = (0 : ℝ) ∧
    (∀ ys zs : ℕ → ℝ, ys 0 = 0 →
      (∀ n, ys (n + 1) = ys n + (1 / 10) * (-ys (n + 1) + zs (n + 1)) ∧
        0 = ys (n + 1) + zs (n + 1) - 1) →
      ∀ n, 1 ≤ n → ys n = 1 / 2 * (1 - ((6 / 5 : ℝ) ^ n)⁻¹) ∧ zs n = 1 - ys n) := by
  refine ⟨fun t => ⟨?_, by ring⟩, by simp, ?_⟩
  · have h1 : HasDerivAt (fun t : ℝ => Real.exp (-2 * t)) (Real.exp (-2 * t) * (-2)) t := by
      have := ((hasDerivAt_id t).const_mul (-2 : ℝ)).exp
      simpa using this
    have h2 := (h1.const_sub 1).div_const 2
    convert h2 using 1
    ring
  · intro ys zs h0 hstep n hn
    have hz : ∀ n, zs (n + 1) = 1 - ys (n + 1) := fun n => by
      have := (hstep n).2; linarith
    have hy : ∀ n, ys (n + 1) = (ys n + 1 / 10) / (6 / 5) := fun n => by
      have h := (hstep n).1
      rw [hz n] at h
      field_simp
      linarith
    have closed : ∀ n, ys n = 1 / 2 * (1 - ((6 / 5 : ℝ) ^ n)⁻¹) := by
      intro n
      induction n with
      | zero => simp [h0]
      | succ k ih =>
        rw [hy k, ih, pow_succ]
        field_simp
        ring
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
    exact ⟨closed _, hz m⟩

/-- Worked numbers: the first backward Euler step `(0 + 0.1)/1.2 = 1/12` V, current `11/12` mA. -/
example : ((0 : ℚ) + 1 / 10) / (6 / 5) = 1 / 12 ∧ (1 : ℚ) - 1 / 12 = 11 / 12 := by norm_num

/-- Ten backward Euler steps of `y ↦ (y + 0.1)/1.2` from 0 give `0.5 (1 - 1.2^(-10))`, exactly
`50700551/120932352` (0.41925 to five places). -/
example : (fun y : ℚ => (y + 1 / 10) / (6 / 5))^[10] 0 = 50700551 / 120932352 ∧
    (1 : ℚ) / 2 * (1 - ((6 / 5 : ℚ) ^ 10)⁻¹) = 50700551 / 120932352 := by
  norm_num [Function.iterate_succ_apply']

/-- Radau IIA's step factor `R(z) = (1 + z/3)/(1 - 2z/3 + z²/6)` at `z = -0.2` is `140/171`
(0.81871345). -/
example : (1 + (-1 / 5 : ℚ) / 3) / (1 - 2 * (-1 / 5 : ℚ) / 3 + (-1 / 5 : ℚ) ^ 2 / 6) = 140 / 171 := by
  norm_num

/-- The pendulum's level-3 constraint responds to the pull `μ` with slope `-(x₁² + x₂²)`,
which is `-1` at the point (0.6, -0.8) on the circle. -/
example : -(((3 : ℚ) / 5) ^ 2 + (-4 / 5 : ℚ) ^ 2) = -1 := by norm_num

#print axioms index_one_constraint_fixes_algebraic_unknown
#print axioms implicit_rk_on_index_one_dae_is_rk_on_reduced_ode
#print axioms rc_circuit_exact_and_backward_euler
