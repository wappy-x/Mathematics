-- The canonical bundle and adjunction: the top form of projective n-space picks up the Jacobian -1/b0^(n+1) at the hyperplane at infinity, adjunction's degree d(d - 3) = 2g - 2 gives g = (d - 1)(d - 2)/2, and the card's whole-number checks hold exactly.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Topology.Algebra.Module.Determinant
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Tactic
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.LinearAlgebra.Matrix.Block

open Matrix

/-- Helper for Step 4: twice the sum of j - 1 over j < d is (d - 1)(d - 2). -/
theorem two_mul_sum_range_pred (d : ℕ) :
    2 * ∑ j ∈ Finset.range d, (j - 1) = (d - 1) * (d - 2) := by
  induction d with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, mul_add, ih]
    rcases k with _ | _ | k
    · simp
    · simp
    · simp only [Nat.add_sub_cancel, show k + 1 + 1 - 1 = k + 1 by omega,
        show k + 1 + 1 - 2 = k by omega, show k + 1 + 1 + 1 - 2 = k + 1 by omega]
      ring

#print axioms two_mul_sum_range_pred

/-- The top form of projective n-space has a pole of order n + 1 at infinity (Step 1 of the card):
move from the chart x1 = 1, with coordinates (b0, b2, ..., bn), to the chart x0 = 1, with
a1 = 1/b0 and aj = bj/b0. Wherever b0 is not 0, the Jacobian determinant of this chart change is
-1/b0^(n+1), so da1 ∧ ... ∧ dan = -b0^(-(n+1)) db0 ∧ db2 ∧ ... ∧ dbn and K of P^n is O(-n-1).
Index 0 here is b0 (and a1); index k ≥ 1 is b(k+1) (and a(k+1)). -/
theorem top_form_of_projective_space_has_pole_of_order_n_add_one
    {𝕜 : Type*} [NontriviallyNormedField 𝕜] (n : ℕ) [NeZero n] (b : Fin n → 𝕜) (hb : b 0 ≠ 0) :
    (fderiv 𝕜 (fun c : Fin n → 𝕜 => fun k : Fin n => if k = 0 then (c 0)⁻¹ else c k / c 0) b).det
      = -((b 0) ^ (n + 1))⁻¹ := by
  set D : Fin n → (Fin n → 𝕜) →L[𝕜] 𝕜 := fun k =>
    if k = 0 then (ContinuousLinearMap.toSpanSingleton 𝕜 (-(b 0 ^ 2)⁻¹)).comp
        (ContinuousLinearMap.proj 0)
    else b k • (ContinuousLinearMap.toSpanSingleton 𝕜 (-(b 0 ^ 2)⁻¹)).comp
        (ContinuousLinearMap.proj 0) + (b 0)⁻¹ • ContinuousLinearMap.proj k with hD
  have hinv : HasFDerivAt (fun c : Fin n → 𝕜 => (c 0)⁻¹)
      ((ContinuousLinearMap.toSpanSingleton 𝕜 (-(b 0 ^ 2)⁻¹)).comp
        (ContinuousLinearMap.proj 0)) b :=
    (hasFDerivAt_inv hb).comp b (hasFDerivAt_apply 0 b)
  have hder : HasFDerivAt (fun c : Fin n → 𝕜 => fun k : Fin n =>
      if k = 0 then (c 0)⁻¹ else c k / c 0) (ContinuousLinearMap.pi D) b := by
    rw [hasFDerivAt_pi]
    intro k
    by_cases hk : k = 0
    · simp only [hD, hk, ite_true]
      exact hinv
    · simp only [hD, hk, ite_false, div_eq_mul_inv]
      exact (hasFDerivAt_apply k b).mul hinv
  rw [hder.fderiv, ContinuousLinearMap.det, ← LinearMap.det_toMatrix']
  have hentry : ∀ i j : Fin n,
      LinearMap.toMatrix' (ContinuousLinearMap.pi D : (Fin n → 𝕜) →ₗ[𝕜] (Fin n → 𝕜)) i j
      = if i = 0 then (if j = 0 then -(b 0 ^ 2)⁻¹ else 0)
        else (if j = 0 then b i * -(b 0 ^ 2)⁻¹ else 0) + (if j = i then (b 0)⁻¹ else 0) := by
    intro i j
    rw [LinearMap.toMatrix'_apply]
    by_cases hi : i = 0
    · subst hi
      by_cases hj : j = 0
      · subst hj; simp [hD]
      · simp [hD, hj, Ne.symm hj]
    · by_cases hj : j = 0
      · subst hj; simp [hD, hi, Ne.symm hi]
      · by_cases hji : j = i
        · subst hji; simp [hD, hi]
        · simp [hD, hi, hj, hji, Ne.symm hj, Ne.symm hji]
  rw [Matrix.det_of_isLowerTriangular]
  · simp only [hentry]
    obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by have := NeZero.ne n; omega⟩
    rw [Fin.prod_univ_succ]
    simp [Fin.succ_ne_zero]
    field_simp
    ring
  · intro i j hij
    simp only [OrderDual.toDual_lt_toDual] at hij
    rw [hentry]
    have hj : j ≠ 0 := by
      rintro rfl
      exact absurd hij (by simp)
    simp [hj, hij.ne']

/-- Adjunction turns degree into genus (Step 3): on a smooth plane curve of degree d the canonical
bundle is O(d - 3) on C, of degree d(d - 3), and a canonical divisor has degree 2g - 2; so
g = (d - 1)(d - 2)/2. -/
theorem genus_of_plane_curve_from_adjunction (d g : ℤ) (h : 2 * g - 2 = d * (d - 3)) :
    g = (d - 1) * (d - 2) / 2 := by
  have h2 : (d - 1) * (d - 2) = 2 * g := by linear_combination -h
  rw [h2]
  omega

/-- The holomorphic differentials h dx/F_y on a smooth plane curve of degree d (Step 4): the
monomials x^i y^j with i + j ≤ d - 3 number exactly (d - 1)(d - 2)/2, the genus. -/
theorem holomorphic_differentials_count (d : ℕ) :
    ((Finset.range d ×ˢ Finset.range d).filter (fun p : ℕ × ℕ => p.1 + p.2 + 3 ≤ d)).card
      = (d - 1) * (d - 2) / 2 := by
  have hsum : ((Finset.range d ×ˢ Finset.range d).filter
      (fun p : ℕ × ℕ => p.1 + p.2 + 3 ≤ d)).card = ∑ j ∈ Finset.range d, (j - 1) := by
    rw [Finset.card_filter, Finset.sum_product]
    have hin : ∀ x ∈ Finset.range d,
        (∑ y ∈ Finset.range d, if x + y + 3 ≤ d then 1 else 0) = d - 1 - x - 1 := by
      intro x _
      rw [← Finset.card_filter]
      have : (Finset.range d).filter (fun y => x + y + 3 ≤ d)
          = Finset.range (d - 1 - x - 1) := by
        ext y
        simp only [Finset.mem_filter, Finset.mem_range]
        omega
      rw [this, Finset.card_range]
    rw [Finset.sum_congr rfl hin]
    exact Finset.sum_range_reflect (fun j => j - 1) d
  have h2 := two_mul_sum_range_pred d
  rw [hsum]
  generalize (d - 1) * (d - 2) = X at h2 ⊢
  omega

-- Step 1 on the plane: x = 1/t, y = s/t has Jacobian matrix [[-1/t^2, 0], [-s/t^2, 1/t]],
-- which at (t, s) = (2, 3) has determinant -1/8; and -1/8 times 2^3 is -1.
example : !![(-1 : ℚ) / 4, 0; -3 / 4, 1 / 2].det = -1 / 8 := by
  norm_num [Matrix.det_fin_two]
example : (-1 : ℚ) / 8 * 2 ^ 3 = -1 ∧ (-1 : ℚ) / 27 * 3 ^ 3 = -1 := by norm_num

-- Adjunction on plane curves: deg K_C = d(d - 3) = 2g - 2 gives g = 0, 0, 1, 3, 6 for d = 1 to 5.
example : [(1 : ℤ), 2, 3, 4, 5].map (fun d => d * (d - 3)) = [-2, -2, 0, 4, 10] := by decide
example : [(1 : ℤ), 2, 3, 4, 5].map (fun d => (d - 1) * (d - 2) / 2) = [0, 0, 1, 3, 6] := by decide
example : [0, 0, 1, 3, 6].map (fun g : ℤ => 2 * g - 2) = [-2, -2, 0, 4, 10] := by decide

-- The quartic: twist -3 + 4 = 1, degree 4 = 2 * 3 - 2; Riemann-Hurwitz 2 - 2 * 3 = 2 * 4 - 12.
example : (-3 : ℤ) + 4 = 1 ∧ (4 : ℤ) * (4 - 3) = 2 * 3 - 2 ∧ (2 : ℤ) - 2 * 3 = 2 * 4 - 12 := by
  norm_num

-- Branch points d(d - 1) and Riemann-Hurwitz 2 - 2g = 2d - d(d - 1) for d = 2 to 5.
example : [(2 : ℤ), 3, 4, 5].map (fun d => 1 - d + d * (d - 1) / 2) = [0, 1, 3, 6] := by decide

-- Hermitian quintic over GF(16): 64 affine points + 1 at infinity = 65, and (65 - 17)/8 = 6.
example : (64 : ℕ) + 1 = 65 ∧ (65 - 17) / 8 = 6 ∧ (65 : ℕ) ≤ 17 + 8 * 6 := by norm_num

-- Surfaces of degree e in P^3: K = O(e - 4), a line has L.L = -2 - (e - 4) = 1, 0, -1, -2, -3,
-- and a plane section has H.H + K.H = e + (e - 4)e = 2g - 2 with g = (e - 1)(e - 2)/2.
example : [(1 : ℤ), 2, 3, 4, 5].map (fun e => -2 - (e - 4)) = [1, 0, -1, -2, -3] := by decide
example : [(1 : ℤ), 2, 3, 4, 5].map (fun e => e + (e - 4) * e - (2 * ((e - 1) * (e - 2) / 2) - 2))
    = [0, 0, 0, 0, 0] := by decide

-- Two twists: a quadric and a cubic in P^3 give K_C = O(2 + 3 - 4) = O(1); the quintic
-- threefold in P^4 has K = O(5 - 4 - 1) = O(0).
example : (2 : ℤ) + 3 - 4 = 1 ∧ (5 : ℤ) - 4 - 1 = 0 := by norm_num

-- What breaks, for the quartic d = 4: K of P^2 taken as O(-2) gives g = 1 + 4 * 2 / 2 = 5;
-- twist dropped gives degree -12 and g = -5; wrong sign gives degree -28 and g = -13.
example : (1 : ℤ) + 4 * (4 - 2) / 2 = 5 := by norm_num
example : (-3 : ℤ) * 4 = -12 ∧ (-12 : ℤ) / 2 + 1 = -5 := by norm_num
example : (4 : ℤ) * (-3 - 4) = -28 ∧ (-28 : ℤ) / 2 + 1 = -13 := by norm_num

-- The nodal cubic x^3 + y^3 + x^2 - 4y^2: t = 1 on y = tx gives the point (3/2, 3/2), on the curve.
example : ((3 : ℚ) / 2) ^ 3 + (3 / 2) ^ 3 + (3 / 2) ^ 2 - 4 * (3 / 2) ^ 2 = 0 := by norm_num
example : (4 * (1 : ℚ) ^ 2 - 1) / (1 + 1 ^ 3) = 3 / 2 := by norm_num

#print axioms top_form_of_projective_space_has_pole_of_order_n_add_one
#print axioms genus_of_plane_curve_from_adjunction
#print axioms holomorphic_differentials_count
