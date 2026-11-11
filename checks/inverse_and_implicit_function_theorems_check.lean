-- Inverse and implicit function theorems: where the rate block in the unknowns is invertible, an equation fixes the unknowns as a smooth function of the rest near a known state, and a map with an invertible Jacobian can be undone nearby.
import Mathlib.Analysis.Calculus.ImplicitContDiff
import Mathlib.Tactic.NormNum

open Filter Topology

theorem ift_general {E₁ E₂ F : Type*} [NormedAddCommGroup E₁] [NormedSpace ℝ E₁] [CompleteSpace E₁]
    [NormedAddCommGroup E₂] [NormedSpace ℝ E₂] [CompleteSpace E₂]
    [NormedAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F]
    (f : E₁ × E₂ → F) (x₀ : E₁) (y₀ : E₂)
    (hF : ContDiffAt ℝ 1 f (x₀, y₀)) (h0 : f (x₀, y₀) = 0)
    (hy : (fderiv ℝ f (x₀, y₀) ∘L ContinuousLinearMap.inr ℝ E₁ E₂).IsInvertible) :
    ∃ g : E₁ → E₂, g x₀ = y₀ ∧ (∀ᶠ p in 𝓝 (x₀, y₀), f p = 0 ↔ p.2 = g p.1) ∧
      (∀ᶠ x in 𝓝 x₀, f (x, g x) = 0) ∧ (∀ᶠ x in 𝓝 x₀, ContDiffAt ℝ 1 g x) ∧
      (∀ᶠ x in 𝓝 x₀, HasFDerivAt g
        (-(fderiv ℝ f (x, g x) ∘L ContinuousLinearMap.inr ℝ E₁ E₂).inverse ∘L
          (fderiv ℝ f (x, g x) ∘L ContinuousLinearMap.inl ℝ E₁ E₂)) x) := by
  set g := hF.implicitFunction one_ne_zero hy
  have hg0 : g x₀ = y₀ := hF.implicitFunction_apply_self (u := (x₀, y₀)) one_ne_zero hy
  have hsol : ∀ᶠ x in 𝓝 x₀, f (x, g x) = 0 := by
    have := hF.eventually_apply_implicitFunction one_ne_zero hy
    simpa [h0] using this
  have hiff : ∀ᶠ p in 𝓝 (x₀, y₀), f p = 0 ↔ p.2 = g p.1 := by
    filter_upwards [hF.eventually_apply_eq_iff_implicitFunction one_ne_zero hy] with p hp
    rw [h0] at hp; rw [hp]; exact eq_comm
  have hgc : ContDiffAt ℝ 1 g x₀ := hF.contDiffAt_implicitFunction one_ne_zero hy
  have hT : Tendsto (fun x => (x, g x)) (𝓝 x₀) (𝓝 (x₀, y₀)) := by
    have := (continuousAt_id.prodMk hgc.continuousAt).tendsto
    simpa [hg0] using this
  have hFev : ∀ᶠ x in 𝓝 x₀, ContDiffAt ℝ 1 f (x, g x) :=
    hT.eventually (hF.eventually (by simp))
  have hinv : ∀ᶠ x in 𝓝 x₀,
      (fderiv ℝ f (x, g x) ∘L ContinuousLinearMap.inr ℝ E₁ E₂).IsInvertible := by
    have hc : ContinuousAt (fun p => fderiv ℝ f p ∘L ContinuousLinearMap.inr ℝ E₁ E₂) (x₀, y₀) :=
      ((ContinuousLinearMap.compL ℝ E₂ (E₁ × E₂) F).flip
        (ContinuousLinearMap.inr ℝ E₁ E₂)).continuous.continuousAt.comp
          (hF.continuousAt_fderiv one_ne_zero)
    exact hT.eventually (hc.eventually hy.eventually_nhds)
  have hsol' : ∀ᶠ x in 𝓝 x₀, ∀ᶠ x' in 𝓝 x, f (x', g x') = 0 := hsol.eventually_nhds
  refine ⟨g, hg0, hiff, hsol, hgc.eventually (by simp), ?_⟩
  filter_upwards [hFev, hgc.eventually (by simp), hinv, hsol'] with x hFx hgx hix hsx
  set D := fderiv ℝ f (x, g x)
  have hgd := (hgx.differentiableAt one_ne_zero).hasFDerivAt
  have hcomp : HasFDerivAt (fun x' => f (x', g x'))
      (D ∘L ((ContinuousLinearMap.id ℝ E₁).prod (fderiv ℝ g x))) x :=
    (hFx.differentiableAt one_ne_zero).hasFDerivAt.comp x ((hasFDerivAt_id x).prodMk hgd)
  have hzero : HasFDerivAt (fun x' => f (x', g x')) (0 : E₁ →L[ℝ] F) x :=
    (hasFDerivAt_const 0 x).congr_of_eventuallyEq (hsx.mono fun _ h => h)
  have heq := hcomp.unique hzero
  have key : (D ∘L ContinuousLinearMap.inr ℝ E₁ E₂) ∘L fderiv ℝ g x =
      -(D ∘L ContinuousLinearMap.inl ℝ E₁ E₂) := by
    ext v
    have h1 := congrArg (fun L => L v) heq
    have h2 : D (v, fderiv ℝ g x v) = D (v, 0) + D (0, fderiv ℝ g x v) := by
      rw [← map_add]; simp
    simp only [ContinuousLinearMap.coe_comp, Function.comp_apply,
      ContinuousLinearMap.prod_apply, ContinuousLinearMap.coe_id', id_eq,
      zero_apply] at h1
    simp only [ContinuousLinearMap.coe_comp, Function.comp_apply, ContinuousLinearMap.inr_apply,
      neg_apply, ContinuousLinearMap.inl_apply]
    rw [h2] at h1
    exact eq_neg_of_add_eq_zero_right h1
  have : fderiv ℝ g x = -(D ∘L ContinuousLinearMap.inr ℝ E₁ E₂).inverse ∘L
      (D ∘L ContinuousLinearMap.inl ℝ E₁ E₂) := by
    rw [← ContinuousLinearMap.comp_neg, ← key,
      ← ContinuousLinearMap.comp_assoc, hix.inverse_comp_self, ContinuousLinearMap.id_comp]
  rw [← this]; exact hgd

#print axioms ift_general

theorem real_clm_inverse_apply (L : ℝ →L[ℝ] ℝ) (w : ℝ) : L.inverse w = w / L 1 := by
  by_cases hc : L 1 = 0
  · have hL : L = 0 := by
      ext; simpa using hc
    subst hL; simp
  · have hL : L = ((ContinuousLinearEquiv.unitsEquivAut ℝ (Units.mk0 (L 1) hc) : ℝ ≃L[ℝ] ℝ) :
        ℝ →L[ℝ] ℝ) := by
      ext; simp [ContinuousLinearEquiv.unitsEquivAut_apply]
    rw [hL, ContinuousLinearMap.inverse_equiv]
    simp [ContinuousLinearEquiv.unitsEquivAut_apply, div_eq_mul_inv]

#print axioms real_clm_inverse_apply

/-- Implicit function theorem. Take `m` equations `F (x, y) = 0` in free variables `x` (n numbers)
and unknowns `y` (m numbers), holding at a known state `(x₀, y₀)`. If `F` has continuous partial
derivatives near the state and the square block `∂F/∂y` (the equations' rates in the unknowns) is
invertible there, then near `x₀` exactly one nearby `y = g x` solves the equations, `g` has
continuous partials near `x₀`, and its rates are `∂y/∂x = -(∂F/∂y)⁻¹ (∂F/∂x)`. -/
theorem implicit_function_theorem {n m : ℕ}
    (F : (Fin n → ℝ) × (Fin m → ℝ) → (Fin m → ℝ)) (x₀ : Fin n → ℝ) (y₀ : Fin m → ℝ)
    (hF : ContDiffAt ℝ 1 F (x₀, y₀)) (h0 : F (x₀, y₀) = 0)
    (hy : (fderiv ℝ F (x₀, y₀) ∘L ContinuousLinearMap.inr ℝ (Fin n → ℝ) (Fin m → ℝ)).IsInvertible) :
    ∃ g : (Fin n → ℝ) → (Fin m → ℝ),
      g x₀ = y₀ ∧
      (∀ᶠ p in 𝓝 (x₀, y₀), F p = 0 ↔ p.2 = g p.1) ∧
      (∀ᶠ x in 𝓝 x₀, F (x, g x) = 0) ∧
      (∀ᶠ x in 𝓝 x₀, ContDiffAt ℝ 1 g x) ∧
      (∀ᶠ x in 𝓝 x₀, HasFDerivAt g
        (-(fderiv ℝ F (x, g x) ∘L ContinuousLinearMap.inr ℝ (Fin n → ℝ) (Fin m → ℝ)).inverse ∘L
          (fderiv ℝ F (x, g x) ∘L ContinuousLinearMap.inl ℝ (Fin n → ℝ) (Fin m → ℝ))) x) := by
  exact ift_general F x₀ y₀ hF h0 hy

/-- One equation, one unknown: near a state that satisfies `F (x, y) = 0`, if `F` has continuous
partials near it and the equation's rate in the unknown, `∂F/∂y`, is not zero, then the unknown is a
function `y = g x` of the rest with continuous partials, the only nearby solution, and each of its
rates is minus the equation's other rate divided by that one: `∂g/∂xᵢ = -(∂F/∂xᵢ) / (∂F/∂y)`. -/
theorem implicit_function_one_unknown {n : ℕ}
    (F : (Fin n → ℝ) × ℝ → ℝ) (x₀ : Fin n → ℝ) (y₀ : ℝ)
    (hF : ContDiffAt ℝ 1 F (x₀, y₀)) (h0 : F (x₀, y₀) = 0)
    (hy : fderiv ℝ F (x₀, y₀) (0, 1) ≠ 0) :
    ∃ g : (Fin n → ℝ) → ℝ,
      g x₀ = y₀ ∧
      (∀ᶠ p in 𝓝 (x₀, y₀), F p = 0 ↔ p.2 = g p.1) ∧
      (∀ᶠ x in 𝓝 x₀, ContDiffAt ℝ 1 g x) ∧
      (∀ᶠ x in 𝓝 x₀, ∀ i : Fin n,
        fderiv ℝ g x (Pi.single i 1) =
          -(fderiv ℝ F (x, g x) (Pi.single i 1, 0)) / fderiv ℝ F (x, g x) (0, 1)) := by
  have hy' : (fderiv ℝ F (x₀, y₀) ∘L ContinuousLinearMap.inr ℝ (Fin n → ℝ) ℝ).IsInvertible := by
    refine ⟨ContinuousLinearEquiv.unitsEquivAut ℝ (Units.mk0 _ hy), ?_⟩
    ext; simp [ContinuousLinearEquiv.unitsEquivAut_apply]
  obtain ⟨g, hg0, hiff, -, hcd, hd⟩ := ift_general F x₀ y₀ hF h0 hy'
  refine ⟨g, hg0, hiff, hcd, ?_⟩
  filter_upwards [hd] with x hx i
  rw [hx.fderiv]
  simp [real_clm_inverse_apply, neg_div]

/-- Inverse function theorem. Let `G` take n numbers to n numbers with continuous partial
derivatives near `x₀`. If its Jacobian at `x₀` is invertible, then `G` maps an open set around `x₀`
onto an open set around `G x₀`, it has an undo `H` there with continuous partials, and the undo's
Jacobian at `G x₀` is the inverse of `G`'s Jacobian at `x₀`. -/
theorem inverse_function_theorem {n : ℕ}
    (G : (Fin n → ℝ) → (Fin n → ℝ)) (x₀ : Fin n → ℝ)
    (hG : ContDiffAt ℝ 1 G x₀) (hJ : (fderiv ℝ G x₀).IsInvertible) :
    ∃ (U W : Set (Fin n → ℝ)) (H : (Fin n → ℝ) → (Fin n → ℝ)),
      IsOpen U ∧ IsOpen W ∧ x₀ ∈ U ∧ G '' U = W ∧
      (∀ x ∈ U, H (G x) = x) ∧ (∀ y ∈ W, G (H y) = y) ∧
      ContDiffOn ℝ 1 H W ∧
      HasFDerivAt H (fderiv ℝ G x₀).inverse (G x₀) := by
  obtain ⟨e, he⟩ := hJ
  have hG' : HasFDerivAt G (e : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ)) x₀ := by
    rw [he]; exact (hG.differentiableAt one_ne_zero).hasFDerivAt
  set S := {x | ContDiffAt ℝ 1 G x ∧ (fderiv ℝ G x).IsInvertible}
  have hS : S ∈ 𝓝 x₀ := by
    have h1 : ∀ᶠ x in 𝓝 x₀, ContDiffAt ℝ 1 G x := hG.eventually (by simp)
    have h2 : ∀ᶠ x in 𝓝 x₀, (fderiv ℝ G x).IsInvertible :=
      (hG.continuousAt_fderiv one_ne_zero).eventually
        (show (fderiv ℝ G x₀).IsInvertible from ⟨e, he⟩).eventually_nhds
    exact h1.and h2
  let Φ := hG.toOpenPartialHomeomorph G hG' one_ne_zero
  let Ψ := Φ.restrOpen (interior S) isOpen_interior
  have hcoe : (Ψ : (Fin n → ℝ) → (Fin n → ℝ)) = G := rfl
  refine ⟨Ψ.source, Ψ.target, Ψ.symm, Ψ.open_source, Ψ.open_target, ?_, ?_,
    fun x hx => Ψ.left_inv hx, fun y hy => Ψ.right_inv hy, ?_, ?_⟩
  · rw [OpenPartialHomeomorph.restrOpen_source]
    exact ⟨hG.mem_toOpenPartialHomeomorph_source hG' one_ne_zero,
      mem_interior_iff_mem_nhds.mpr hS⟩
  · rw [← hcoe]; exact Ψ.image_source_eq_target
  · intro y hy
    have hs : Ψ.symm y ∈ Ψ.source := Ψ.map_target hy
    rw [OpenPartialHomeomorph.restrOpen_source] at hs
    obtain ⟨hcd, ⟨e', he'⟩⟩ := interior_subset hs.2
    have hd : HasFDerivAt Ψ (e' : (Fin n → ℝ) →L[ℝ] (Fin n → ℝ)) (Ψ.symm y) := by
      rw [hcoe, he']; exact (hcd.differentiableAt one_ne_zero).hasFDerivAt
    exact (Ψ.contDiffAt_symm hy hd hcd).contDiffWithinAt
  · rw [← he, ContinuousLinearMap.inverse_equiv]
    exact ((hG.hasStrictFDerivAt' hG' one_ne_zero).to_localInverse).hasFDerivAt

/-! The card's worked numbers for one mole of ideal gas, `F(p, V, T) = pV - nRT`, with `n = 1`,
`R = 8.314`, `p = 100` and `T = 300`, checked exactly as fractions. -/

-- the volume at the state: 8.314 × 300 / 100 = 24.942 L
example : (8314 / 1000 : ℚ) * 300 / 100 = 24942 / 1000 := by norm_num

-- warming rate: ∂V/∂T = -(∂F/∂T)/(∂F/∂V) = -(-8.314)/100 = 0.08314 L per K
example : -(-(8314 / 1000 : ℚ)) / 100 = 8314 / 100000 := by norm_num

-- squeezing rate: ∂V/∂p = -(∂F/∂p)/(∂F/∂V) = -24.942/100 = -0.24942 L per kPa
example : -(24942 / 1000 : ℚ) / 100 = -24942 / 100000 := by norm_num

-- inverse theorem, Step 1: with s = -nRT/V² and c = nR/V, the top row of the inverse
-- of [[s, c], [0, 1]] is (1/s, -c/s) = (-0.24942, 0.08314)
example :
    let V : ℚ := 24942 / 1000
    let s : ℚ := -(8314 / 1000 * 300) / V ^ 2
    let c : ℚ := 8314 / 1000 / V
    1 / s = -24942 / 100000 ∧ -c / s = 8314 / 100000 := by norm_num

-- 3 K warmer and 2 kPa more: 3 × 0.08314 - 2 × 0.24942 = -0.24942 L
example : 3 * (8314 / 100000 : ℚ) + 2 * (-24942 / 100000) = -24942 / 100000 := by norm_num

-- the failed hypothesis at p = 0: with T = 0 every volume solves pV = nRT; with T = 1 K none does
example : ∀ V : ℚ, 0 * V - 1 * (8314 / 1000) * 0 = 0 := by intro V; norm_num
example : ∀ V : ℚ, 0 * V - 1 * (8314 / 1000) * 1 ≠ 0 := by intro V; norm_num

#print axioms implicit_function_theorem
#print axioms implicit_function_one_unknown
#print axioms inverse_function_theorem
