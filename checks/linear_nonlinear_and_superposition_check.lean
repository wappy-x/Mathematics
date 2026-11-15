-- Linear or not: for a linear second-order operator with coefficients depending only on position and time, any weighted sum of two classical solutions that vanish on the edge is again such a solution, while for Burgers' equation the sum misses by the cross term (v₁v₂)ₓ, 2/3 at (1 m, 1 s).
import Mathlib.Analysis.Calculus.FDeriv.Add
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Topology.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp

namespace LinearNonlinearSuperposition

open Finset

variable {n : ℕ}

/-! A point `x : Fin n → ℝ` lists all `n` variables, time included (for the plate,
`(x, y, t)` and `n = 3`). `pd i u x` is the partial derivative of `u` along the `i`-th
variable at `x`. -/

/-- The partial derivative `u_{x_i}` of `u` at `x`: the derivative of `u` along the `i`-th
coordinate direction. -/
noncomputable def pd (i : Fin n) (u : (Fin n → ℝ) → ℝ) (x : Fin n → ℝ) : ℝ :=
  fderiv ℝ u x (Pi.single i 1)

/-- The card's general linear second-order operator
`L[u] = ∑ᵢⱼ a_ij u_{x_i x_j} + ∑ᵢ b_i u_{x_i} + r u`,
whose coefficients `a_ij`, `b_i`, `r` depend on the point `x` (position and time) only. -/
noncomputable def L (a : Fin n → Fin n → (Fin n → ℝ) → ℝ) (b : Fin n → (Fin n → ℝ) → ℝ)
    (r : (Fin n → ℝ) → ℝ) (u : (Fin n → ℝ) → ℝ) (x : Fin n → ℝ) : ℝ :=
  ∑ i, ∑ j, a i j x * pd i (pd j u) x + ∑ i, b i x * pd i u x + r x * u x

/-- Helper: the partial derivative is linear on functions differentiable at the point. -/
theorem pd_lin (i : Fin n) (u₁ u₂ : (Fin n → ℝ) → ℝ) (c₁ c₂ : ℝ) (x : Fin n → ℝ)
    (h₁ : DifferentiableAt ℝ u₁ x) (h₂ : DifferentiableAt ℝ u₂ x) :
    pd i (fun y => c₁ * u₁ y + c₂ * u₂ y) x = c₁ * pd i u₁ x + c₂ * pd i u₂ x := by
  unfold pd
  have hd : HasFDerivAt (fun y => c₁ * u₁ y + c₂ * u₂ y)
      (c₁ • fderiv ℝ u₁ x + c₂ • fderiv ℝ u₂ x) x :=
    (h₁.hasFDerivAt.const_mul c₁).add (h₂.hasFDerivAt.const_mul c₂)
  rw [hd.fderiv]
  simp

/-- Helper: a first partial derivative of a `C²` function on an open set is differentiable
at every point of the set. -/
theorem pd_differentiableAt (j : Fin n) (Ω : Set (Fin n → ℝ)) (hΩ : IsOpen Ω)
    (u : (Fin n → ℝ) → ℝ) (h : ContDiffOn ℝ 2 u Ω) (x : Fin n → ℝ) (hx : x ∈ Ω) :
    DifferentiableAt ℝ (pd j u) x := by
  have h1 : ContDiffOn ℝ 1 (fun y => fderiv ℝ u y) Ω :=
    h.fderiv_of_isOpen hΩ (by norm_num)
  have h2 : ContDiffOn ℝ 1 (fun y => fderiv ℝ u y (Pi.single j 1)) Ω :=
    h1.clm_apply contDiffOn_const
  exact (h2.differentiableOn (by norm_num)).differentiableAt (hΩ.mem_nhds hx)

/-- Helper: a `C²` function on an open set is differentiable at every point of the set. -/
theorem differentiableAt_of_C2 (Ω : Set (Fin n → ℝ)) (hΩ : IsOpen Ω)
    (u : (Fin n → ℝ) → ℝ) (h : ContDiffOn ℝ 2 u Ω) (x : Fin n → ℝ) (hx : x ∈ Ω) :
    DifferentiableAt ℝ u x :=
  (h.differentiableOn (by norm_num)).differentiableAt (hΩ.mem_nhds hx)

/-- Superposition. Let `L` be the linear second-order operator above, with coefficients that
depend on position and time only, no source (the equation is `L[u] = 0`), and zero edge data.
If `u₁` and `u₂` are classical solutions on an open region `Ω` (twice continuously
differentiable there, with `L[u] = 0` at every point of `Ω`) and both are 0 on the edge
`∂Ω`, then for any numbers `c₁`, `c₂` the weighted sum `c₁ u₁ + c₂ u₂` is again a classical
solution on `Ω` and is again 0 on the edge. -/
theorem superposition_of_linear_homogeneous
    (a : Fin n → Fin n → (Fin n → ℝ) → ℝ) (b : Fin n → (Fin n → ℝ) → ℝ)
    (r : (Fin n → ℝ) → ℝ) (Ω : Set (Fin n → ℝ)) (hΩ : IsOpen Ω)
    (u₁ u₂ : (Fin n → ℝ) → ℝ) (c₁ c₂ : ℝ)
    (h₁ : ContDiffOn ℝ 2 u₁ Ω) (h₂ : ContDiffOn ℝ 2 u₂ Ω)
    (hL₁ : ∀ x ∈ Ω, L a b r u₁ x = 0) (hL₂ : ∀ x ∈ Ω, L a b r u₂ x = 0)
    (hb₁ : ∀ x ∈ frontier Ω, u₁ x = 0) (hb₂ : ∀ x ∈ frontier Ω, u₂ x = 0) :
    ContDiffOn ℝ 2 (fun x => c₁ * u₁ x + c₂ * u₂ x) Ω ∧
      (∀ x ∈ Ω, L a b r (fun x => c₁ * u₁ x + c₂ * u₂ x) x = 0) ∧
      ∀ x ∈ frontier Ω, c₁ * u₁ x + c₂ * u₂ x = 0 := by
  refine ⟨?_, ?_, ?_⟩
  · exact (contDiffOn_const.mul h₁).add (contDiffOn_const.mul h₂)
  · intro x hx
    have hpd : ∀ i j, pd i (pd j (fun x => c₁ * u₁ x + c₂ * u₂ x)) x =
        c₁ * pd i (pd j u₁) x + c₂ * pd i (pd j u₂) x := by
      intro i j
      have hev : pd j (fun x => c₁ * u₁ x + c₂ * u₂ x) =ᶠ[nhds x]
          fun y => c₁ * pd j u₁ y + c₂ * pd j u₂ y := by
        filter_upwards [hΩ.mem_nhds hx] with y hy
        exact pd_lin j u₁ u₂ c₁ c₂ y (differentiableAt_of_C2 Ω hΩ u₁ h₁ y hy)
          (differentiableAt_of_C2 Ω hΩ u₂ h₂ y hy)
      have : pd i (pd j (fun x => c₁ * u₁ x + c₂ * u₂ x)) x =
          pd i (fun y => c₁ * pd j u₁ y + c₂ * pd j u₂ y) x := by
        unfold pd at hev ⊢
        rw [hev.fderiv_eq]
      rw [this]
      exact pd_lin i _ _ c₁ c₂ x (pd_differentiableAt j Ω hΩ u₁ h₁ x hx)
        (pd_differentiableAt j Ω hΩ u₂ h₂ x hx)
    have hp1 : ∀ i, pd i (fun x => c₁ * u₁ x + c₂ * u₂ x) x =
        c₁ * pd i u₁ x + c₂ * pd i u₂ x := fun i =>
      pd_lin i u₁ u₂ c₁ c₂ x (differentiableAt_of_C2 Ω hΩ u₁ h₁ x hx)
        (differentiableAt_of_C2 Ω hΩ u₂ h₂ x hx)
    have e1 := hL₁ x hx
    have e2 := hL₂ x hx
    unfold L at e1 e2 ⊢
    simp only [hpd, hp1]
    have k1 : ∀ i j, a i j x * (c₁ * pd i (pd j u₁) x + c₂ * pd i (pd j u₂) x) =
        c₁ * (a i j x * pd i (pd j u₁) x) + c₂ * (a i j x * pd i (pd j u₂) x) := by
      intros; ring
    have k2 : ∀ i, b i x * (c₁ * pd i u₁ x + c₂ * pd i u₂ x) =
        c₁ * (b i x * pd i u₁ x) + c₂ * (b i x * pd i u₂ x) := by
      intros; ring
    simp only [k1, k2, Finset.sum_add_distrib, ← Finset.mul_sum]
    linear_combination c₁ * e1 + c₂ * e2
  · intro x hx
    rw [hb₁ x hx, hb₂ x hx]
    ring

/-! Burgers' equation: `v x t` is a speed in m/s at position `x` and time `t`, and
`N[v] = v_t + v v_x`. -/

/-- Burgers' operator `N[v] = v_t + v v_x` at the point `(x, t)`. -/
noncomputable def burgers (v : ℝ → ℝ → ℝ) (x t : ℝ) : ℝ :=
  deriv (fun s => v x s) t + v x t * deriv (fun y => v y t) x

/-- The cross term. For any two flows `v₁`, `v₂` with first derivatives in `x` and `t` at
`(x, t)`, Burgers applied to the sum is the sum of the two results plus the cross term
`(v₁ v₂)_x`: `N[v₁ + v₂] = N[v₁] + N[v₂] + (v₁ v₂)_x`. -/
theorem burgers_add_eq_add_add_cross_term (v₁ v₂ : ℝ → ℝ → ℝ) (x t : ℝ)
    (h₁t : DifferentiableAt ℝ (fun s => v₁ x s) t) (h₂t : DifferentiableAt ℝ (fun s => v₂ x s) t)
    (h₁x : DifferentiableAt ℝ (fun y => v₁ y t) x) (h₂x : DifferentiableAt ℝ (fun y => v₂ y t) x) :
    burgers (fun y s => v₁ y s + v₂ y s) x t =
      burgers v₁ x t + burgers v₂ x t + deriv (fun y => v₁ y t * v₂ y t) x := by
  simp only [burgers]
  have d1 : HasDerivAt (fun s => v₁ x s + v₂ x s)
      (deriv (fun s => v₁ x s) t + deriv (fun s => v₂ x s) t) t :=
    h₁t.hasDerivAt.add h₂t.hasDerivAt
  have d2 : HasDerivAt (fun y => v₁ y t + v₂ y t)
      (deriv (fun y => v₁ y t) x + deriv (fun y => v₂ y t) x) x :=
    h₁x.hasDerivAt.add h₂x.hasDerivAt
  have d3 : HasDerivAt (fun y => v₁ y t * v₂ y t)
      (deriv (fun y => v₁ y t) x * v₂ x t + v₁ x t * deriv (fun y => v₂ y t) x) x :=
    h₁x.hasDerivAt.mul h₂x.hasDerivAt
  rw [d1.deriv, d2.deriv, d3.deriv]
  ring

/-- Burgers refuses to add. The clouds `v₁ = x/(1 + t)` and `v₂ = x/(1/2 + t)` both solve
Burgers' equation at every position for every time `t > -1/2`, yet their sum misses it by
`2/3` m/s² at `(1 m, 1 s)`. The flow `w = 3x/(1 + 3t)` from the summed start (`w = v₁ + v₂`
at `t = 0`) does solve it, and at `(1 m, 1 s)` it moves at `3/4` m/s, not the `7/6` m/s that
`v₁ + v₂` predicts. -/
theorem burgers_refuses_to_add :
    (∀ x t : ℝ, -1/2 < t → burgers (fun y s => y / (1 + s)) x t = 0) ∧
    (∀ x t : ℝ, -1/2 < t → burgers (fun y s => y / (1/2 + s)) x t = 0) ∧
    burgers (fun y s => y / (1 + s) + y / (1/2 + s)) 1 1 = 2/3 ∧
    (∀ x t : ℝ, -1/3 < t → burgers (fun y s => 3 * y / (1 + 3 * s)) x t = 0) ∧
    (∀ x : ℝ, 3 * x / (1 + 3 * 0) = x / (1 + 0) + x / (1/2 + 0)) ∧
    (3 * 1 / (1 + 3 * 1) : ℝ) = 3/4 ∧ (1 / (1 + 1) + 1 / (1/2 + 1) : ℝ) = 7/6 := by
  have ds : ∀ (a c t : ℝ), c + t ≠ 0 → deriv (fun s => a / (c + s)) t = -a / (c + t) ^ 2 := by
    intro a c t h
    have hd : HasDerivAt (fun s => a / (c + s)) ((0 * (c + t) - a * 1) / (c + t) ^ 2) t :=
      (hasDerivAt_const t a).div ((hasDerivAt_id t).const_add c) h
    rw [hd.deriv]
    ring
  have dy : ∀ (c x : ℝ), deriv (fun y => y / c) x = 1 / c := by
    intro c x
    simp
  have one : ∀ c x t : ℝ, c + t ≠ 0 → burgers (fun y s => y / (c + s)) x t = 0 := by
    intro c x t h
    simp only [burgers]
    rw [ds x c t h, dy]
    field_simp
    ring
  refine ⟨fun x t ht => one 1 x t (by linarith), fun x t ht => one (1/2) x t (by linarith),
    ?_, ?_, ?_, by norm_num, by norm_num⟩
  · have dt : ∀ c : ℝ, c + 1 ≠ 0 → DifferentiableAt ℝ (fun s : ℝ => 1 / (c + s)) 1 :=
      fun c hc => (differentiableAt_const _).div (differentiableAt_id.const_add c) hc
    have dx : ∀ c : ℝ, DifferentiableAt ℝ (fun y : ℝ => y / (c + 1)) 1 :=
      fun c => differentiableAt_id.div_const _
    have key := burgers_add_eq_add_add_cross_term (fun y s => y / (1 + s))
      (fun y s => y / (1/2 + s)) 1 1 (dt 1 (by norm_num)) (dt (1/2) (by norm_num))
      (dx 1) (dx (1/2))
    rw [key, one 1 1 1 (by norm_num), one (1/2) 1 1 (by norm_num)]
    have hd : HasDerivAt (fun y : ℝ => y / (1 + 1) * (y / (1/2 + 1)))
        (1 / (1 + 1) * (1 / (1/2 + 1)) + 1 / (1 + 1) * (1 / (1/2 + 1))) 1 :=
      ((hasDerivAt_id 1).div_const _).mul ((hasDerivAt_id 1).div_const _)
    rw [hd.deriv]
    norm_num
  · intro x t ht
    have h : (1 : ℝ) + 3 * t ≠ 0 := by linarith
    have hs : HasDerivAt (fun s => 3 * x / (1 + 3 * s))
        ((0 * (1 + 3 * t) - 3 * x * (3 * 1)) / (1 + 3 * t) ^ 2) t :=
      (hasDerivAt_const t (3 * x)).div (((hasDerivAt_id t).const_mul 3).const_add 1) h
    have hy : HasDerivAt (fun y => 3 * y / (1 + 3 * t)) (3 * 1 / (1 + 3 * t)) x :=
      ((hasDerivAt_id x).const_mul 3).div_const _
    simp only [burgers]
    rw [hs.deriv, hy.deriv]
    field_simp
    ring
  · intro x
    norm_num
    ring

/-! The card's worked Burgers numbers at x = 1 m, t = 1 s, in exact fractions. -/

-- v₁ = 1/(1 + 1) = 1/2 m/s and v₂ = 1/(1/2 + 1) = 2/3 m/s
example : (1 : ℚ) / (1 + 1) = 1/2 := by norm_num
example : (1 : ℚ) / (1/2 + 1) = 2/3 := by norm_num
-- the sum of the answers, 1/2 + 2/3 = 7/6 m/s
example : (1 : ℚ)/2 + 2/3 = 7/6 := by norm_num
-- the cross term 2x/((1 + t)(1/2 + t)) at (1, 1) is 2/(2 × 3/2) = 2/3 m/s²
example : (2 * 1 : ℚ) / ((1 + 1) * (1/2 + 1)) = 2/3 := by norm_num
-- the flow from the summed start, 3x/(1 + 3t) at (1, 1), is 3/4 m/s
example : (3 * 1 : ℚ) / (1 + 3 * 1) = 3/4 := by norm_num
-- doubling the start gives x/(1/2 + t), 2/3 m/s; doubling the answer gives 2 × 1/2 = 1 m/s
example : (2 * 1 : ℚ) / (1 + 2 * 1) = 2/3 ∧ (2 : ℚ) * (1/2) = 1 := by norm_num

#print axioms pd_lin
#print axioms pd_differentiableAt
#print axioms differentiableAt_of_C2
#print axioms superposition_of_linear_homogeneous
#print axioms burgers_add_eq_add_add_cross_term
#print axioms burgers_refuses_to_add

end LinearNonlinearSuperposition
