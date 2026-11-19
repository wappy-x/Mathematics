-- Exterior derivative: in three dimensions d is the gradient on functions, the curl on one-forms and the divergence on two-forms, d applied twice is zero, and d commutes with pullback.
import Mathlib.Analysis.Calculus.DifferentialForm.Basic
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum

open Matrix

theorem clm_apply_eq_sum (L : (Fin 3 → ℝ) →L[ℝ] ℝ) (a : Fin 3 → ℝ) :
    L a = ∑ i, a i * L (Pi.single i 1) := by
  conv_lhs => rw [← Finset.univ_sum_single a]
  rw [map_sum]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [show Pi.single i (a i) = a i • (Pi.single i 1 : Fin 3 → ℝ) by
    rw [← Pi.single_smul, smul_eq_mul, mul_one], map_smul, smul_eq_mul]

#print axioms clm_apply_eq_sum

/-- The one-form `a ↦ a j`. -/
noncomputable def oneFormProj (j : Fin 3) : (Fin 3 → ℝ) [⋀^Fin 1]→L[ℝ] ℝ :=
  ContinuousAlternatingMap.ofSubsingleton ℝ (Fin 3 → ℝ) ℝ (0 : Fin 1)
    (ContinuousLinearMap.proj j)

theorem oneFormProj_apply (j : Fin 3) (m : Fin 1 → Fin 3 → ℝ) : oneFormProj j m = m 0 j := by
  simp [oneFormProj]

#print axioms oneFormProj_apply

/-- The two-form `(a, b) ↦ a k * b l - b k * a l`. -/
noncomputable def twoFormProj (k l : Fin 3) : (Fin 3 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ :=
  ContinuousAlternatingMap.alternatizeUncurryFin
    ((ContinuousLinearMap.proj k : (Fin 3 → ℝ) →L[ℝ] ℝ).smulRight (oneFormProj l))

theorem twoFormProj_apply (k l : Fin 3) (a b : Fin 3 → ℝ) :
    twoFormProj k l ![a, b] = a k * b l - b k * a l := by
  simp [twoFormProj, ContinuousAlternatingMap.alternatizeUncurryFin_apply, Fin.sum_univ_two,
    oneFormProj_apply, Fin.removeNth]
  ring

#print axioms twoFormProj_apply

/-- In three dimensions, with straight right-handed axes, the exterior derivative is the
gradient, the curl and the divergence. Let `T` be a temperature and `v = (P, Q, R)` a wind on
`ℝ³`, both with continuous first rates at the point `x`. Then:
* `d` of the 0-form `T`, fed an arrow `a`, is `grad T · a`;
* `d` of the work form `ω = P dx + Q dy + R dz` (so `ω(a) = v · a`), fed two arrows `a, b`,
  is `curl v · (a × b)`: its parts on `dy ∧ dz`, `dz ∧ dx`, `dx ∧ dy` are the curl's parts;
* `d` of the flux form `Φ = P dy ∧ dz + Q dz ∧ dx + R dx ∧ dy` (so `Φ(a, b) = v · (a × b)`),
  fed three arrows `a, b, c`, is `div v` times the volume `det (a, b, c)`. -/
theorem exterior_derivative_is_grad_curl_div
    (T : (Fin 3 → ℝ) → ℝ) (v : (Fin 3 → ℝ) → (Fin 3 → ℝ))
    (ω : (Fin 3 → ℝ) → (Fin 3 → ℝ) [⋀^Fin 1]→L[ℝ] ℝ)
    (Φ : (Fin 3 → ℝ) → (Fin 3 → ℝ) [⋀^Fin 2]→L[ℝ] ℝ)
    (hω : ∀ y a, ω y ![a] = v y ⬝ᵥ a)
    (hΦ : ∀ y a b, Φ y ![a, b] = v y ⬝ᵥ (a ⨯₃ b))
    (x : Fin 3 → ℝ) (hT : ContDiffAt ℝ 1 T x) (hv : ContDiffAt ℝ 1 v x) :
    (∀ a : Fin 3 → ℝ,
      extDeriv (fun y => ContinuousAlternatingMap.constOfIsEmpty ℝ (Fin 3 → ℝ) (Fin 0) (T y))
          x ![a] =
        (fun i => fderiv ℝ T x (Pi.single i 1)) ⬝ᵥ a) ∧
    (∀ a b : Fin 3 → ℝ,
      extDeriv ω x ![a, b] =
        ![fderiv ℝ (fun y => v y 2) x (Pi.single 1 1) - fderiv ℝ (fun y => v y 1) x (Pi.single 2 1),
          fderiv ℝ (fun y => v y 0) x (Pi.single 2 1) - fderiv ℝ (fun y => v y 2) x (Pi.single 0 1),
          fderiv ℝ (fun y => v y 1) x (Pi.single 0 1) - fderiv ℝ (fun y => v y 0) x (Pi.single 1 1)]
          ⬝ᵥ (a ⨯₃ b)) ∧
    (∀ a b c : Fin 3 → ℝ,
      extDeriv Φ x ![a, b, c] =
        (fderiv ℝ (fun y => v y 0) x (Pi.single 0 1) + fderiv ℝ (fun y => v y 1) x (Pi.single 1 1)
          + fderiv ℝ (fun y => v y 2) x (Pi.single 2 1)) * (Matrix.of ![a, b, c]).det) := by
  have hvj : ∀ j, DifferentiableAt ℝ (fun y => v y j) x :=
    differentiableAt_pi.1 (hv.differentiableAt one_ne_zero)
  refine ⟨?_, ?_, ?_⟩
  · -- the gradient
    intro a
    rw [extDeriv_constOfIsEmpty]
    simp only [ContinuousAlternatingMap.ofSubsingleton_apply_apply, Matrix.cons_val_zero]
    rw [clm_apply_eq_sum, dotProduct]
    simp [mul_comm]
  · -- the curl
    have hωeq : ω = fun y => ∑ j, v y j • oneFormProj j := by
      funext y
      ext m
      have hm : m = ![m 0] := by ext i; fin_cases i; rfl
      rw [hm, hω]
      simp [dotProduct, oneFormProj_apply]
    have hdiff : DifferentiableAt ℝ ω x := by
      rw [hωeq]
      exact DifferentiableAt.fun_sum fun j _ => (hvj j).smul_const _
    have hfd : ∀ b : Fin 3 → ℝ, ∀ a, fderiv ℝ (fun y => ω y ![b]) x a =
        ∑ j, (∑ i, a i * fderiv ℝ (fun y => v y j) x (Pi.single i 1)) * b j := by
      intro b a
      simp only [hω, dotProduct]
      rw [fderiv_fun_sum (fun j _ => (hvj j).mul_const _)]
      simp only [FunLike.coe_sum, Finset.sum_apply]
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [fderiv_mul_const (hvj j)]
      simp only [clm_apply_eq_sum _ a]
      rw [Finset.sum_mul]
      exact Finset.sum_congr rfl fun i _ => by
        rw [smul_apply, smul_eq_mul]; ring
    intro a b
    rw [extDeriv_apply hdiff]
    have h0 : Fin.removeNth 0 ![a, b] = ![b] := by ext i; fin_cases i; rfl
    have h1 : Fin.removeNth 1 ![a, b] = ![a] := by ext i; fin_cases i; rfl
    rw [Fin.sum_univ_two, h0, h1]
    simp only [Matrix.cons_val_zero, Matrix.cons_val_one, hfd]
    simp [Fin.sum_univ_three, cross_apply, dotProduct]
    ring
  · -- the divergence
    have hΦeq : Φ = fun y => ∑ j, v y j •
        ![twoFormProj 1 2, twoFormProj 2 0, twoFormProj 0 1] j := by
      funext y
      ext m
      have hm : m = ![m 0, m 1] := by ext i; fin_cases i <;> rfl
      rw [hm, hΦ]
      simp [dotProduct, Fin.sum_univ_three, twoFormProj_apply, cross_apply]
      ring
    have hdiff : DifferentiableAt ℝ Φ x := by
      rw [hΦeq]
      exact DifferentiableAt.fun_sum fun j _ => (hvj j).smul_const _
    have hfd : ∀ p q : Fin 3 → ℝ, ∀ a, fderiv ℝ (fun y => Φ y ![p, q]) x a =
        ∑ j, (∑ i, a i * fderiv ℝ (fun y => v y j) x (Pi.single i 1)) * (p ⨯₃ q) j := by
      intro p q a
      simp only [hΦ, dotProduct]
      rw [fderiv_fun_sum (fun j _ => (hvj j).mul_const _)]
      simp only [FunLike.coe_sum, Finset.sum_apply]
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [fderiv_mul_const (hvj j)]
      simp only [clm_apply_eq_sum _ a]
      rw [Finset.sum_mul]
      exact Finset.sum_congr rfl fun i _ => by
        rw [smul_apply, smul_eq_mul]; ring
    intro a b c
    rw [extDeriv_apply hdiff]
    have h0 : Fin.removeNth 0 ![a, b, c] = ![b, c] := by ext i; fin_cases i <;> rfl
    have h1 : Fin.removeNth 1 ![a, b, c] = ![a, c] := by ext i; fin_cases i <;> rfl
    have h2 : Fin.removeNth 2 ![a, b, c] = ![a, b] := by ext i; fin_cases i <;> rfl
    rw [Fin.sum_univ_three, h0, h1, h2]
    simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_two, hfd]
    simp [Fin.sum_univ_three, cross_apply, Matrix.det_fin_three]
    ring

/-- Applying `d` twice gives zero: for a k-form on `ℝⁿ` whose coefficients have continuous
second rates near `x`, `d(dα) = 0` at `x` (a gradient has no curl, a curl has no divergence). -/
theorem exterior_derivative_twice_eq_zero {n k : ℕ}
    (α : (Fin n → ℝ) → (Fin n → ℝ) [⋀^Fin k]→L[ℝ] ℝ) (x : Fin n → ℝ)
    (hα : ContDiffAt ℝ 2 α x) :
    extDeriv (extDeriv α) x = 0 := by
  exact extDeriv_extDeriv_apply hα (by simp)

/-- `d` reads the same in every chart: for a chart map `F` with continuous second rates and a
k-form `α` with continuous first rates, differentiating then pulling back equals pulling back
then differentiating, `F*(dα) = d(F*α)`. -/
theorem exterior_derivative_commutes_with_pullback {n m k : ℕ}
    (α : (Fin m → ℝ) → (Fin m → ℝ) [⋀^Fin k]→L[ℝ] ℝ) (F : (Fin n → ℝ) → (Fin m → ℝ))
    (x : Fin n → ℝ) (hα : ContDiffAt ℝ 1 α (F x)) (hF : ContDiffAt ℝ 2 F x) :
    extDeriv (fun y => (α (F y)).compContinuousLinearMap (fderiv ℝ F y)) x =
      (extDeriv α (F x)).compContinuousLinearMap (fderiv ℝ F x) := by
  exact extDeriv_pullback (hα.differentiableAt one_ne_zero) hF (by simp)

-- The card's worked numbers at the mast, as exact fractions.
-- dT(wind) = 0.003 * 0.22 - 0.0065 * 0.035 = 0.0004325 degC/s, which is 1.557 degC per hour.
example : (3 / 1000 : ℚ) * (22 / 100) - (65 / 10000) * (35 / 1000) = 4325 / 10000000 := by
  norm_num
example : (4325 / 10000000 : ℚ) * 3600 = 1557 / 1000 := by norm_num
-- The three curl parts: 0 - 0.01, 0.004 - 0.0005, -0.0016 - (-0.0006).
example : (0 : ℚ) - 1 / 100 = -1 / 100 ∧ (4 / 1000 : ℚ) - 5 / 10000 = 35 / 10000 ∧
    (-16 / 10000 : ℚ) - (-6 / 10000) = -1 / 1000 := by norm_num
-- The divergence: 0.001 + 0.0003 - 0.0013 = 0.
example : (1 / 1000 : ℚ) + 3 / 10000 - 13 / 10000 = 0 := by norm_num
-- 10 m squares: circulation = curl part * 100 m^2.
example : (-1 / 100 : ℚ) * 100 = -1 ∧ (35 / 10000 : ℚ) * 100 = 35 / 100 ∧
    (-1 / 1000 : ℚ) * 100 = -1 / 10 := by norm_num
-- Terrain chart: the dx ^ dy part becomes -0.001 - 0.2 * (-0.01) = 0.001, and
-- the pulled-back east rate of T is 0.003 - 0.0065 * 0.2 = 0.0017.
example : (-1 / 1000 : ℚ) - (2 / 10) * (-1 / 100) = 1 / 1000 := by norm_num
example : (3 / 1000 : ℚ) - (65 / 10000) * (2 / 10) = 17 / 10000 := by norm_num
-- What breaks: treating dy ^ dx as dx ^ dy gives -0.0016 + (-0.0006) = -0.0022;
-- writing Q dx ^ dz for Q dz ^ dx gives 0.001 - 0.0003 - 0.0013 = -0.0006.
example : (-16 / 10000 : ℚ) + (-6 / 10000) = -22 / 10000 := by norm_num
example : (1 / 1000 : ℚ) - 3 / 10000 - 13 / 10000 = -6 / 10000 := by norm_num

#print axioms exterior_derivative_is_grad_curl_div
#print axioms exterior_derivative_twice_eq_zero
#print axioms exterior_derivative_commutes_with_pullback
