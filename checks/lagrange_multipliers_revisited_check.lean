-- Lagrange multipliers, proved: at a constrained local minimum where the rules' gradients are linearly independent, the cost's gradient is exactly one combination of the rules' gradients, each weight is the rate at which the least cost moves with that rule's amount, and at a cusp no multiplier exists.
import Mathlib.Analysis.Calculus.LagrangeMultipliers
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Topology.Order.LocalExtr
import Mathlib.Tactic
import Mathlib

open Filter Topology

/-- Lagrange multipliers with `m` rules on `n` choices. Let the cost `f` and every rule
`g j` have continuous partial rates near `x₀` (continuously differentiable there). If `x₀`
obeys every rule `g j x₀ = b j`, is a local minimum of `f` among plans obeying every rule,
and the rules' gradients at `x₀` are linearly independent (LICQ), then there is exactly one
list of multipliers `lam` with `∇f(x₀) = lam 1 ∇g₁(x₀) + ... + lam m ∇gₘ(x₀)`. -/
theorem exists_unique_lagrange_multipliers_of_licq {n m : ℕ}
    (f : EuclideanSpace ℝ (Fin n) → ℝ) (g : Fin m → EuclideanSpace ℝ (Fin n) → ℝ)
    (b : Fin m → ℝ) (x₀ : EuclideanSpace ℝ (Fin n))
    (hf : ContDiffAt ℝ 1 f x₀) (hg : ∀ j, ContDiffAt ℝ 1 (g j) x₀)
    (hfeas : ∀ j, g j x₀ = b j)
    (hmin : IsLocalMinOn f {x | ∀ j, g j x = b j} x₀)
    (hlicq : LinearIndependent ℝ (fun j => gradient (g j) x₀)) :
    ∃! lam : Fin m → ℝ, gradient f x₀ = ∑ j, lam j • gradient (g j) x₀ := by
  have hset : {x | ∀ j, g j x = g j x₀} = {x | ∀ j, g j x = b j} := by
    ext x; simp [hfeas]
  have hext : IsLocalExtrOn f {x | ∀ j, g j x = g j x₀} x₀ := by
    rw [hset]; exact Or.inl hmin
  obtain ⟨Λ, Λ₀, hne, hsum⟩ := hext.exists_multipliers_of_hasStrictFDerivAt
    (fun j => (hg j).hasStrictFDerivAt one_ne_zero) (hf.hasStrictFDerivAt one_ne_zero)
  have hsum' : ∑ j, Λ j • gradient (g j) x₀ + Λ₀ • gradient f x₀ = 0 := by
    have := congrArg (InnerProductSpace.toDual ℝ (EuclideanSpace ℝ (Fin n))).symm hsum
    simpa [map_sum, gradient] using this
  have hli := Fintype.linearIndependent_iff.mp hlicq
  have hΛ₀ : Λ₀ ≠ 0 := by
    intro h0
    apply hne
    have : ∀ i, Λ i = 0 := hli Λ (by simpa [h0] using hsum')
    ext <;> simp [h0, this]
  refine ⟨fun j => -(Λ₀⁻¹ * Λ j), ?_, ?_⟩
  · have h1 : gradient f x₀ = -Λ₀⁻¹ • ∑ j, Λ j • gradient (g j) x₀ := by
      have h2 : Λ₀ • gradient f x₀ = -∑ j, Λ j • gradient (g j) x₀ := by
        rw [eq_neg_iff_add_eq_zero, add_comm]; exact hsum'
      rw [neg_smul, ← smul_neg, ← h2, smul_smul, inv_mul_cancel₀ hΛ₀, one_smul]
    simp only at *
    rw [h1, Finset.smul_sum]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [smul_smul]; congr 1; ring
  · intro lam' hlam'
    have := (Fintype.linearIndependent_iffₛ.mp hlicq) lam' (fun j => -(Λ₀⁻¹ * Λ j))
    funext j
    apply this _ j
    rw [← hlam']
    have h2 : Λ₀ • gradient f x₀ = -∑ j, Λ j • gradient (g j) x₀ := by
      rw [eq_neg_iff_add_eq_zero, add_comm]; exact hsum'
    have h1 : gradient f x₀ = -Λ₀⁻¹ • ∑ j, Λ j • gradient (g j) x₀ := by
      rw [neg_smul, ← smul_neg, ← h2, smul_smul, inv_mul_cancel₀ hΛ₀, one_smul]
    rw [h1, Finset.smul_sum]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [smul_smul]; congr 1; ring

/-- The price reading (envelope theorem). Suppose the best plan `xstar b` moves smoothly
(is differentiable) as the amounts `b` change near `b₀`, obeys the rules `g j (xstar b) = b j`,
and is a local minimum of the cost among plans obeying them, so the least cost is
`p*(b) = f (xstar b)`. If `f` and the rules are continuously differentiable at `xstar b₀`,
the rules' gradients there are independent, and `lam` are the multipliers there, then each
multiplier is the rate of the least cost in its rule's amount: `∂p*/∂b_j = lam j`. -/
theorem multiplier_eq_rate_of_least_cost {n m : ℕ}
    (f : EuclideanSpace ℝ (Fin n) → ℝ) (g : Fin m → EuclideanSpace ℝ (Fin n) → ℝ)
    (xstar : (Fin m → ℝ) → EuclideanSpace ℝ (Fin n)) (b₀ : Fin m → ℝ) (lam : Fin m → ℝ)
    (hf : ContDiffAt ℝ 1 f (xstar b₀)) (hg : ∀ j, ContDiffAt ℝ 1 (g j) (xstar b₀))
    (hfeas : ∀ᶠ b in 𝓝 b₀, ∀ j, g j (xstar b) = b j)
    (hmin : ∀ᶠ b in 𝓝 b₀, IsLocalMinOn f {x | ∀ j, g j x = b j} (xstar b))
    (hlicq : LinearIndependent ℝ (fun j => gradient (g j) (xstar b₀)))
    (hsmooth : DifferentiableAt ℝ xstar b₀)
    (hlam : gradient f (xstar b₀) = ∑ j, lam j • gradient (g j) (xstar b₀)) :
    ∀ j, fderiv ℝ (fun b => f (xstar b)) b₀ (Pi.single j 1) = lam j := by
  intro k
  have hgj : ∀ j, fderiv ℝ (g j) (xstar b₀) (fderiv ℝ xstar b₀ (Pi.single k 1)) = (Pi.single k (1:ℝ) : Fin m → ℝ) j := by
    intro j
    have e1 : fderiv ℝ (fun b => g j (xstar b)) b₀ = fderiv ℝ (fun b : Fin m → ℝ => b j) b₀ :=
      Filter.EventuallyEq.fderiv_eq (hfeas.mono fun b hb => hb j)
    have e2 := fderiv_fun_comp (x := b₀) ((hg j).differentiableAt one_ne_zero) hsmooth
    rw [e2, (hasFDerivAt_apply j b₀).fderiv] at e1
    have := congrArg (fun L => L (Pi.single k 1)) e1
    simpa using this
  rw [fderiv_fun_comp (x := b₀) (hf.differentiableAt one_ne_zero) hsmooth,
    ContinuousLinearMap.comp_apply, ← inner_gradient_left, hlam, sum_inner]
  simp_rw [real_inner_smul_left, inner_gradient_left, hgj]
  simp [Pi.single_apply]

/-- The cusp: minimise `x₁` on the curve `x₂² = x₁³`. The origin is the minimum, yet no
multiplier makes the cost's gradient a multiple of the rule's gradient there (LICQ fails:
the rule's gradient at the origin is zero). -/
theorem cusp_minimum_has_no_multiplier :
    IsMinOn (fun x : EuclideanSpace ℝ (Fin 2) => x 0)
        {x | x 1 ^ 2 - x 0 ^ 3 = 0} 0 ∧
      ¬ ∃ lam : ℝ, gradient (fun x : EuclideanSpace ℝ (Fin 2) => x 0) 0 =
          lam • gradient (fun x : EuclideanSpace ℝ (Fin 2) => x 1 ^ 2 - x 0 ^ 3) 0 := by
  refine ⟨?_, ?_⟩
  · intro x hx
    simp only [Set.mem_setOf_eq] at hx ⊢
    simp only [PiLp.zero_apply]
    by_contra h
    push_neg at h
    nlinarith [pow_pos (neg_pos.mpr h) 3, sq_nonneg (x 1)]
  · rintro ⟨lam, h⟩
    have h1 := congrArg (fun v => inner ℝ v (EuclideanSpace.single (0 : Fin 2) (1:ℝ))) h
    simp only [real_inner_smul_left, inner_gradient_left] at h1
    have hf : HasFDerivAt (𝕜 := ℝ) (fun x : EuclideanSpace ℝ (Fin 2) => (x 0 : ℝ))
        (EuclideanSpace.proj (0 : Fin 2)) 0 := PiLp.hasFDerivAt_apply _ _ _
    have hp : ∀ i : Fin 2, HasFDerivAt (𝕜 := ℝ) (fun x : EuclideanSpace ℝ (Fin 2) => (x i : ℝ))
        (EuclideanSpace.proj i) 0 := fun i => PiLp.hasFDerivAt_apply _ _ _
    have hh : HasFDerivAt (fun x : EuclideanSpace ℝ (Fin 2) => x 1 ^ 2 - x 0 ^ 3) _ 0 :=
      ((hp 1).pow 2).sub ((hp 0).pow 3)
    rw [hf.fderiv, hh.fderiv] at h1
    simp at h1

-- Two pumps, 100 L/s: the 60/40 split draws 120 kW, the even split 125 kW.
example : (2 / 100 : ℚ) * 60 ^ 2 + (3 / 100) * 40 ^ 2 = 120 := by norm_num
example : (2 / 100 : ℚ) * 50 ^ 2 + (3 / 100) * 50 ^ 2 = 125 := by norm_num
-- At 60/40 both marginal costs are 2.4 = 12/5 kW per L/s; at 50/50 they are 2 and 3.
example : 2 * (2 / 100 : ℚ) * 60 = 12 / 5 ∧ 2 * (3 / 100 : ℚ) * 40 = 12 / 5 := by norm_num
example : 2 * (2 / 100 : ℚ) * 50 = 2 ∧ 2 * (3 / 100 : ℚ) * 50 = 3 := by norm_num
-- Chart values: power at pump A = 0, 10, 20 L/s is 300, 245, 200 kW.
example : (2 / 100 : ℚ) * 0 ^ 2 + (3 / 100) * 100 ^ 2 = 300 := by norm_num
example : (2 / 100 : ℚ) * 10 ^ 2 + (3 / 100) * 90 ^ 2 = 245 := by norm_num
example : (2 / 100 : ℚ) * 20 ^ 2 + (3 / 100) * 80 ^ 2 = 200 := by norm_num

-- Three pumps at 50, 50, 50 L/s meet both rules (150 L/s, 35 m) and draw 250 kW.
example : (50 + 50 + 50 : ℚ) = 150 := by norm_num
example : (1 / 10 : ℚ) * 50 + (2 / 10) * 50 + (4 / 10) * 50 = 35 := by norm_num
example : (2 / 100 : ℚ) * 50 ^ 2 + (3 / 100) * 50 ^ 2 + (5 / 100) * 50 ^ 2 = 250 := by norm_num
-- The gradient (2, 3, 5) equals 1 * (1, 1, 1) + 10 * (0.1, 0.2, 0.4): lambda1 = 1, lambda2 = 10.
example : 2 * (2 / 100 : ℚ) * 50 = 1 + 10 * (1 / 10) ∧
    2 * (3 / 100 : ℚ) * 50 = 1 + 10 * (2 / 10) ∧
    2 * (5 / 100 : ℚ) * 50 = 1 + 10 * (4 / 10) := by norm_num
-- The allowed step t = (2, -3, 1) keeps both rules, and grad f . t = 4 - 9 + 5 = 0.
example : (2 : ℤ) + (-3) + 1 = 0 := by decide
example : (1 / 10 : ℚ) * 2 + (2 / 10) * (-3) + (4 / 10) * 1 = 0 := by norm_num
example : (2 : ℤ) * 2 + 3 * (-3) + 5 * 1 = 0 := by decide
-- Along the allowed line the power is 250 + 0.4 s^2.
example (s : ℚ) : (2 / 100) * (50 + 2 * s) ^ 2 + (3 / 100) * (50 - 3 * s) ^ 2
    + (5 / 100) * (50 + s) ^ 2 = 250 + (2 / 5) * s ^ 2 := by ring
-- Hand elimination: 310 lam1 + 59 lam2 = 900 and 59 lam1 + 15.1 lam2 = 210; det 1200.
example : (310 : ℚ) * (151 / 10) - 59 * 59 = 1200 := by norm_num
example : ((900 : ℚ) * (151 / 10) - 59 * 210) / 1200 = 1 := by norm_num
example : ((310 : ℚ) * 210 - 59 * 900) / 1200 = 10 := by norm_num
example : (310 : ℚ) * 1 + 59 * 10 = 900 ∧ (59 : ℚ) * 1 + (151 / 10) * 10 = 210 := by norm_num
-- Pumps B and C alone: lam1 + 0.2 lam2 = 3 and lam1 + 0.4 lam2 = 5 give lam1 = 1, lam2 = 10.
example : (1 : ℚ) + (2 / 10) * 10 = 3 ∧ (1 : ℚ) + (4 / 10) * 10 = 5 := by norm_num
-- Pump B's 2-by-2 block [[1, 1], [0.2, 0.4]] has determinant 0.2.
example : (1 : ℚ) * (4 / 10) - 1 * (2 / 10) = 2 / 10 := by norm_num
-- Demand written twice: (1, 0, 10) and (0, 0.5, 10) both reproduce the gradient (2, 3, 5).
example : ∀ i : Fin 3,
    (1 : ℚ) * 1 + 0 * 2 + 10 * ![1 / 10, 2 / 10, 4 / 10] i = ![2, 3, 5] i ∧
    (0 : ℚ) * 1 + (1 / 2) * 2 + 10 * ![1 / 10, 2 / 10, 4 / 10] i = ![2, 3, 5] i := by
  intro i; fin_cases i <;> norm_num

#print axioms exists_unique_lagrange_multipliers_of_licq
#print axioms multiplier_eq_rate_of_least_cost
#print axioms cusp_minimum_has_no_multiplier
