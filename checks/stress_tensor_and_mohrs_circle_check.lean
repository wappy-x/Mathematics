-- Stress in 3D: for a symmetric stress matrix the normal stress on every cut lies between the smallest and largest eigenvalues, the largest shear is half their gap, plane-stress turning puts every face on Mohr's circle, and the in-plane principal stresses are C ± R.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Matrix

lemma orth_dot (U : Matrix (Fin 3) (Fin 3) ℝ) (hU : Uᵀ * U = 1) (a b : Fin 3 → ℝ) :
    (U *ᵥ a) ⬝ᵥ (U *ᵥ b) = a ⬝ᵥ b := by
  rw [dotProduct_mulVec, ← vecMul_transpose, vecMul_vecMul, hU, vecMul_one]

#print axioms orth_dot

lemma orth_conj_mulVec (U : Matrix (Fin 3) (Fin 3) ℝ) (hU : Uᵀ * U = 1) (d y : Fin 3 → ℝ) :
    (U * diagonal d * Uᵀ) *ᵥ (U *ᵥ y) = U *ᵥ (diagonal d *ᵥ y) := by
  rw [mulVec_mulVec, Matrix.mul_assoc, Matrix.mul_assoc, hU, Matrix.mul_one, ← mulVec_mulVec]

#print axioms orth_conj_mulVec

lemma pair_vec (d : Fin 3 → ℝ) (i j : Fin 3) (h : i ≠ j) (a : ℝ) :
    (Pi.single i a + Pi.single j a : Fin 3 → ℝ) ⬝ᵥ (Pi.single i a + Pi.single j a) = 2 * a ^ 2 ∧
    (Pi.single i a + Pi.single j a : Fin 3 → ℝ) ⬝ᵥ
        (diagonal d *ᵥ (Pi.single i a + Pi.single j a)) = a ^ 2 * (d i + d j) ∧
    (diagonal d *ᵥ (Pi.single i a + Pi.single j a : Fin 3 → ℝ)) ⬝ᵥ
        (diagonal d *ᵥ (Pi.single i a + Pi.single j a)) = a ^ 2 * (d i ^ 2 + d j ^ 2) := by
  fin_cases i <;> fin_cases j <;>
    simp_all [dotProduct, Fin.sum_univ_three, Pi.single_apply, mulVec_diagonal] <;> ring_nf <;>
    simp

#print axioms pair_vec

lemma diag_core (U : Matrix (Fin 3) (Fin 3) ℝ) (d : Fin 3 → ℝ)
    (hU1 : Uᵀ * U = 1) (hU2 : U * Uᵀ = 1) :
    let S := U * diagonal d * Uᵀ
    let σ₁ := Finset.univ.sup' Finset.univ_nonempty d
    let σ₃ := Finset.univ.inf' Finset.univ_nonempty d
    (∀ n : Fin 3 → ℝ, n ⬝ᵥ n = 1 →
        σ₃ ≤ n ⬝ᵥ (S *ᵥ n) ∧ n ⬝ᵥ (S *ᵥ n) ≤ σ₁ ∧
        (S *ᵥ n) ⬝ᵥ (S *ᵥ n) - (n ⬝ᵥ (S *ᵥ n)) ^ 2 ≤ ((σ₁ - σ₃) / 2) ^ 2) ∧
    (∃ n : Fin 3 → ℝ, n ⬝ᵥ n = 1 ∧ S *ᵥ n = σ₁ • n) ∧
    (∃ n : Fin 3 → ℝ, n ⬝ᵥ n = 1 ∧ S *ᵥ n = σ₃ • n) ∧
    (∃ n : Fin 3 → ℝ, n ⬝ᵥ n = 1 ∧
        (S *ᵥ n) ⬝ᵥ (S *ᵥ n) - (n ⬝ᵥ (S *ᵥ n)) ^ 2 = ((σ₁ - σ₃) / 2) ^ 2) := by
  intro S σ₁ σ₃
  have hb : ∀ i, σ₃ ≤ d i ∧ d i ≤ σ₁ := fun i =>
    ⟨Finset.inf'_le _ (Finset.mem_univ i), Finset.le_sup' _ (Finset.mem_univ i)⟩
  obtain ⟨i1, -, h1⟩ := Finset.exists_mem_eq_sup' Finset.univ_nonempty d
  obtain ⟨i3, -, h3⟩ := Finset.exists_mem_eq_inf' Finset.univ_nonempty d
  change σ₁ = d i1 at h1
  change σ₃ = d i3 at h3
  have hn : ∀ n : Fin 3 → ℝ, n = U *ᵥ (Uᵀ *ᵥ n) := fun n => by
    rw [mulVec_mulVec, hU2, one_mulVec]
  have key : ∀ y : Fin 3 → ℝ, (U *ᵥ y) ⬝ᵥ (U *ᵥ y) = y ⬝ᵥ y ∧
      (U *ᵥ y) ⬝ᵥ (S *ᵥ (U *ᵥ y)) = y ⬝ᵥ (diagonal d *ᵥ y) ∧
      (S *ᵥ (U *ᵥ y)) ⬝ᵥ (S *ᵥ (U *ᵥ y)) = (diagonal d *ᵥ y) ⬝ᵥ (diagonal d *ᵥ y) := fun y => by
    refine ⟨orth_dot U hU1 y y, ?_, ?_⟩
    · rw [orth_conj_mulVec U hU1, orth_dot U hU1]
    · rw [orth_conj_mulVec U hU1, orth_dot U hU1]
  have eig : ∀ i, S *ᵥ (U *ᵥ Pi.single i 1) = d i • (U *ᵥ Pi.single i 1) := fun i => by
    rw [orth_conj_mulVec U hU1, ← mulVec_smul]
    congr 1
    ext j
    simp only [mulVec_diagonal, Pi.single_apply, Pi.smul_apply, smul_eq_mul]
    split_ifs with h <;> simp [h]
  have unit : ∀ i, (U *ᵥ Pi.single i 1) ⬝ᵥ (U *ᵥ Pi.single i 1) = 1 := fun i => by
    rw [orth_dot U hU1]; simp
  refine ⟨?_, ⟨_, unit i1, h1 ▸ eig i1⟩, ⟨_, unit i3, h3 ▸ eig i3⟩, ?_⟩
  · intro n hnn
    rw [hn n] at hnn ⊢
    obtain ⟨k1, k2, k3⟩ := key (Uᵀ *ᵥ n)
    rw [k1] at hnn
    rw [k2, k3]
    generalize Uᵀ *ᵥ n = y at hnn ⊢
    simp only [dotProduct, Fin.sum_univ_three, mulVec_diagonal] at hnn ⊢
    obtain ⟨a0, b0⟩ := hb 0
    obtain ⟨a1, b1⟩ := hb 1
    obtain ⟨a2, b2⟩ := hb 2
    have p0 := mul_nonneg (mul_nonneg (sub_nonneg.2 a0) (sub_nonneg.2 b0)) (mul_self_nonneg (y 0))
    have p1 := mul_nonneg (mul_nonneg (sub_nonneg.2 a1) (sub_nonneg.2 b1)) (mul_self_nonneg (y 1))
    have p2 := mul_nonneg (mul_nonneg (sub_nonneg.2 a2) (sub_nonneg.2 b2)) (mul_self_nonneg (y 2))
    have f1 : σ₁ = σ₁ * (y 0 * y 0 + y 1 * y 1 + y 2 * y 2) := by rw [hnn, mul_one]
    have f3 : σ₃ = σ₃ * (y 0 * y 0 + y 1 * y 1 + y 2 * y 2) := by rw [hnn, mul_one]
    refine ⟨?_, ?_, ?_⟩
    · nlinarith [mul_nonneg (sub_nonneg.2 a0) (mul_self_nonneg (y 0)),
        mul_nonneg (sub_nonneg.2 a1) (mul_self_nonneg (y 1)),
        mul_nonneg (sub_nonneg.2 a2) (mul_self_nonneg (y 2))]
    · nlinarith [mul_nonneg (sub_nonneg.2 b0) (mul_self_nonneg (y 0)),
        mul_nonneg (sub_nonneg.2 b1) (mul_self_nonneg (y 1)),
        mul_nonneg (sub_nonneg.2 b2) (mul_self_nonneg (y 2))]
    · have hsq := sq_nonneg (y 0 * (d 0 * y 0) + y 1 * (d 1 * y 1) + y 2 * (d 2 * y 2)
          - (σ₁ + σ₃) / 2)
      have e : ((σ₁ - σ₃) / 2) ^ 2 = ((σ₁ - σ₃) / 2) ^ 2 * (y 0 * y 0 + y 1 * y 1 + y 2 * y 2) := by
        rw [hnn, mul_one]
      have e2 : ((σ₁ + σ₃) / 2) ^ 2 = ((σ₁ + σ₃) / 2) ^ 2 * (y 0 * y 0 + y 1 * y 1 + y 2 * y 2) := by
        rw [hnn, mul_one]
      have e3 : σ₁ * σ₃ = σ₁ * σ₃ * (y 0 * y 0 + y 1 * y 1 + y 2 * y 2) := by
        rw [hnn, mul_one]
      nlinarith
  · by_cases hd : σ₁ = σ₃
    · refine ⟨_, unit i1, ?_⟩
      rw [eig i1, smul_dotProduct, dotProduct_smul, unit, ← h1, hd]
      simp only [smul_eq_mul]
      ring
    · have hne : i1 ≠ i3 := fun h => hd (by rw [h1, h3, h])
      set a : ℝ := Real.sqrt (1 / 2) with ha_def
      have ha : a ^ 2 = 1 / 2 := Real.sq_sqrt (by norm_num)
      obtain ⟨c1, c2, c3⟩ := pair_vec d i1 i3 hne a
      set y : Fin 3 → ℝ := Pi.single i1 a + Pi.single i3 a with hy
      obtain ⟨k1, k2, k3⟩ := key y
      refine ⟨U *ᵥ y, by rw [k1, c1, ha]; norm_num, ?_⟩
      rw [k2, k3, c2, c3, h1, h3]
      linear_combination ((d i1 ^ 2 + d i3 ^ 2) - (d i1 + d i3) ^ 2 * (a ^ 2 + 1 / 2)) * ha

#print axioms diag_core

lemma spectral_real (S : Matrix (Fin 3) (Fin 3) ℝ) (hS : S.IsHermitian) :
    let U : Matrix (Fin 3) (Fin 3) ℝ := hS.eigenvectorUnitary
    Uᵀ * U = 1 ∧ U * Uᵀ = 1 ∧ S = U * diagonal hS.eigenvalues * Uᵀ := by
  intro U
  have h1 : star U * U = 1 := Unitary.coe_star_mul_self _
  have h2 : U * star U = 1 := Unitary.coe_mul_star_self _
  have hst : star U = Uᵀ := by
    rw [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial]
  refine ⟨hst ▸ h1, hst ▸ h2, ?_⟩
  conv_lhs => rw [hS.spectral_theorem]
  rw [Unitary.conjStarAlgAut_apply]
  simp only [RCLike.ofReal_real_eq_id, Function.id_comp]
  rw [← hst]

#print axioms spectral_real

/-- Principal stresses and the largest shear. Let the stress at a point be a symmetric 3 × 3
real matrix S (symmetry comes from moment balance; for real matrices Mathlib's `IsHermitian`
means Sᵀ = S). Let σ₁ be its largest eigenvalue and σ₃ its smallest. For a cut with unit
normal n, the traction is t = S n, the normal stress is σ_n = n · S n, and the shear squared
is |t|² − σ_n². Then on every cut σ₃ ≤ σ_n ≤ σ₁ and the shear is at most (σ₁ − σ₃)/2; the
extreme pulls σ₁ and σ₃ are reached on cuts whose normal is an eigenvector (so the traction
points straight along n and the shear is zero); and some cut carries shear exactly
(σ₁ − σ₃)/2. -/
theorem largest_shear_is_half_principal_gap (S : Matrix (Fin 3) (Fin 3) ℝ)
    (hS : S.IsHermitian) :
    let σ₁ := Finset.univ.sup' Finset.univ_nonempty hS.eigenvalues
    let σ₃ := Finset.univ.inf' Finset.univ_nonempty hS.eigenvalues
    (∀ n : Fin 3 → ℝ, n ⬝ᵥ n = 1 →
        σ₃ ≤ n ⬝ᵥ (S *ᵥ n) ∧ n ⬝ᵥ (S *ᵥ n) ≤ σ₁ ∧
        (S *ᵥ n) ⬝ᵥ (S *ᵥ n) - (n ⬝ᵥ (S *ᵥ n)) ^ 2 ≤ ((σ₁ - σ₃) / 2) ^ 2) ∧
    (∃ n : Fin 3 → ℝ, n ⬝ᵥ n = 1 ∧ S *ᵥ n = σ₁ • n) ∧
    (∃ n : Fin 3 → ℝ, n ⬝ᵥ n = 1 ∧ S *ᵥ n = σ₃ • n) ∧
    (∃ n : Fin 3 → ℝ, n ⬝ᵥ n = 1 ∧
        (S *ᵥ n) ⬝ᵥ (S *ᵥ n) - (n ⬝ᵥ (S *ᵥ n)) ^ 2 = ((σ₁ - σ₃) / 2) ^ 2) := by
  obtain ⟨hU1, hU2, hSd⟩ := spectral_real S hS
  have h := diag_core _ hS.eigenvalues hU1 hU2
  simp only [← hSd] at h
  exact h

/-- Mohr's circle. In plane stress, with stress matrix [[σ_x, τ_xy], [τ_xy, σ_y]], turn the axes
by θ with Q = [[cos θ, sin θ], [−sin θ, cos θ]] and σ' = Q σ Qᵀ. Then the turned normal and
shear stresses are σ_x' = C + (σ_x − σ_y)/2 · cos 2θ + τ_xy sin 2θ and
τ_x'y' = −(σ_x − σ_y)/2 · sin 2θ + τ_xy cos 2θ, with C = (σ_x + σ_y)/2, and the pair lies on
the circle (σ_x' − C)² + τ_x'y'² = R², R² = ((σ_x − σ_y)/2)² + τ_xy². -/
theorem mohrs_circle (σx σy τxy θ : ℝ) :
    let Q : Matrix (Fin 2) (Fin 2) ℝ := !![Real.cos θ, Real.sin θ; -Real.sin θ, Real.cos θ]
    let σ' := Q * !![σx, τxy; τxy, σy] * Qᵀ
    let C := (σx + σy) / 2
    σ' 0 0 = C + (σx - σy) / 2 * Real.cos (2 * θ) + τxy * Real.sin (2 * θ) ∧
    σ' 0 1 = -((σx - σy) / 2) * Real.sin (2 * θ) + τxy * Real.cos (2 * θ) ∧
    (σ' 0 0 - C) ^ 2 + (σ' 0 1) ^ 2 = ((σx - σy) / 2) ^ 2 + τxy ^ 2 := by
  intro Q σ' C
  have hs := Real.sin_sq_add_cos_sq θ
  have e00 : σ' 0 0 = C + (σx - σy) / 2 * Real.cos (2 * θ) + τxy * Real.sin (2 * θ) := by
    simp only [σ', Q, C, Matrix.mul_apply, Fin.sum_univ_two, Matrix.transpose_apply,
      Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.empty_val', Matrix.cons_val_fin_one, Real.cos_two_mul, Real.sin_two_mul]
    linear_combination σy * hs
  have e01 : σ' 0 1 = -((σx - σy) / 2) * Real.sin (2 * θ) + τxy * Real.cos (2 * θ) := by
    simp only [σ', Q, Matrix.mul_apply, Fin.sum_univ_two, Matrix.transpose_apply,
      Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.empty_val', Matrix.cons_val_fin_one, Real.cos_two_mul, Real.sin_two_mul]
    linear_combination (-τxy) * hs
  refine ⟨e00, e01, ?_⟩
  rw [e00, e01]
  have h2 := Real.sin_sq_add_cos_sq (2 * θ)
  linear_combination (((σx - σy) / 2) ^ 2 + τxy ^ 2) * h2

/-- In-plane principal stresses. The eigenvalues of the plane-stress matrix
[[σ_x, τ_xy], [τ_xy, σ_y]], the roots l of det(σ − l I) = 0, are exactly C + R and C − R, where
C = (σ_x + σ_y)/2 and R = √(((σ_x − σ_y)/2)² + τ_xy²): where Mohr's circle meets the axis. -/
theorem plane_principal_stresses_eq_centre_pm_radius (σx σy τxy l : ℝ) :
    let C := (σx + σy) / 2
    let R := Real.sqrt (((σx - σy) / 2) ^ 2 + τxy ^ 2)
    (!![σx, τxy; τxy, σy] - l • (1 : Matrix (Fin 2) (Fin 2) ℝ)).det = 0 ↔
      l = C + R ∨ l = C - R := by
  intro C R
  have hR : R ^ 2 = ((σx - σy) / 2) ^ 2 + τxy ^ 2 := Real.sq_sqrt (by positivity)
  have hdet : (!![σx, τxy; τxy, σy] - l • (1 : Matrix (Fin 2) (Fin 2) ℝ)).det
      = (l - C) ^ 2 - R ^ 2 := by
    rw [Matrix.det_fin_two, hR]
    simp [C]
    ring
  rw [hdet, sub_eq_zero, sq_eq_sq_iff_eq_or_eq_neg]
  constructor
  · rintro (h | h)
    · left; linarith
    · right; linarith
  · rintro (h | h)
    · left; linarith
    · right; linarith

-- The web point: σ_x = 80 MPa, σ_y = −40 MPa, τ_xy = 30 MPa.
-- Centre C = 20 MPa, half-difference 60 MPa, R² = 60² + 30² = 4500 (R = 67.08 MPa).
example : ((80 : ℚ) + (-40)) / 2 = 20 ∧ ((80 : ℚ) - (-40)) / 2 = 60 ∧
    (60 : ℚ) ^ 2 + 30 ^ 2 = 4500 := by norm_num
-- tan 2θ_p = 2 × 30 / 120 = 1/2.
example : (2 * 30 : ℚ) / (80 - (-40)) = 1 / 2 := by norm_num
-- Invariants of the in-plane block: I₁ = 40, I₂ = 80 × (−40) − 30² = −4100,
-- so λ² − 40 λ − 4100 = 0.
example : Matrix.trace !![(80 : ℤ), 30; 30, -40] = 40 := by
  norm_num [Matrix.trace, Fin.sum_univ_two]
example : Matrix.det !![(80 : ℤ), 30; 30, -40] = -4100 := by
  norm_num [Matrix.det_fin_two]
-- Hooke, E = 200 000 MPa, ν = 3/10, in microstrain: ε_x = 460, ε_y = −320, ε_z = −60.
example : ((80 : ℚ) - 3 / 10 * (-40 + 0)) / 200000 * 10 ^ 6 = 460 ∧
    ((-40 : ℚ) - 3 / 10 * (0 + 80)) / 200000 * 10 ^ 6 = -320 ∧
    ((0 : ℚ) - 3 / 10 * (80 + -40)) / 200000 * 10 ^ 6 = -60 := by norm_num
-- G = E / 2(1 + ν), and γ_xy = τ_xy / G = 390 microstrain.
example : (30 : ℚ) / (200000 / (2 * (1 + 3 / 10))) * 10 ^ 6 = 390 := by norm_num
-- Strain circle: centre (460 − 320)/2 = 70, half-difference (460 + 320)/2 = 390,
-- tan 2θ = 390 / 780 = 1/2, the same axis as the stresses.
example : ((460 : ℚ) + -320) / 2 = 70 ∧ ((460 : ℚ) - -320) / 2 = 390 ∧
    (390 : ℚ) / (460 + 320) = 1 / 2 := by norm_num

#print axioms largest_shear_is_half_principal_gap
#print axioms mohrs_circle
#print axioms plane_principal_stresses_eq_centre_pm_radius
