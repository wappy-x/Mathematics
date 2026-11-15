-- Reproducing kernels: in a reproducing kernel Hilbert space each value is an inner product with a bump, so any fit judged by its values at n data points plus an increasing charge on its length is a sum of n bumps at those points, and for kernel ridge the weights solve (K + λI)α = y.
import Mathlib.Analysis.InnerProductSpace.Reproducing
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open scoped RealInnerProductSpace

/-- The value of a finite sum of bumps at a point. -/
lemma rkhs_sum_bumps_apply {X H : Type*} [NormedAddCommGroup H]
    [InnerProductSpace ℝ H] [CompleteSpace H] [RKHS ℝ H X ℝ]
    {n : ℕ} (x : Fin n → X) (c : Fin n → ℝ) (z : X) :
    (∑ i, c i • RKHS.kerFun H (x i) 1) z = ∑ i, c i * RKHS.kernel H z (x i) 1 := by
  show RKHS.eval H z (∑ i, c i • RKHS.kerFun H (x i) 1) = _
  rw [map_sum]
  simp

/-- The inner product of a finite sum of bumps with any profile. -/
lemma rkhs_inner_sum_bumps {X H : Type*} [NormedAddCommGroup H]
    [InnerProductSpace ℝ H] [CompleteSpace H] [RKHS ℝ H X ℝ]
    {n : ℕ} (x : Fin n → X) (c : Fin n → ℝ) (h : H) :
    ⟪∑ i, c i • RKHS.kerFun H (x i) 1, h⟫ = ∑ i, c i * h (x i) := by
  rw [sum_inner]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [real_inner_smul_left, RKHS.kerFun_inner]
  simp

/-- The representer theorem. Let `H` be a reproducing kernel Hilbert space of real functions on
`X` (a Hilbert space of functions in which reading off a value is bounded), with bump
`k_x = RKHS.kerFun H x 1`. Take `n` data points `x₁, …, xₙ`, any cost `L` that sees a profile
only through its values at the data points, and a strictly increasing charge `Ω` on its
length. If `f` makes the total cost `L(f(x₁), …, f(xₙ)) + Ω(‖f‖)` smallest, then `f` is a sum
of bumps at the data points: `f = ∑ αᵢ k_{xᵢ}` for some weights `α`. -/
theorem best_fit_is_sum_of_bumps_at_data {X H : Type*} [NormedAddCommGroup H]
    [InnerProductSpace ℝ H] [CompleteSpace H] [RKHS ℝ H X ℝ]
    {n : ℕ} (x : Fin n → X) (L : (Fin n → ℝ) → ℝ) (Ω : ℝ → ℝ) (hΩ : StrictMono Ω)
    (f : H) (hf : ∀ g : H, L (fun i => f (x i)) + Ω ‖f‖ ≤ L (fun i => g (x i)) + Ω ‖g‖) :
    ∃ α : Fin n → ℝ, f = ∑ i, α i • RKHS.kerFun H (x i) 1 := by
  set M : Submodule ℝ H := Submodule.span ℝ (Set.range fun i => RKHS.kerFun H (x i) 1) with hM
  have : FiniteDimensional ℝ M := FiniteDimensional.span_of_finite ℝ (Set.finite_range _)
  have : CompleteSpace M := FiniteDimensional.complete ℝ M
  set g : H := M.starProjection f with hg
  have hperp : f - g ∈ Mᗮ := M.sub_starProjection_mem_orthogonal f
  have hgM : g ∈ M := M.starProjection_apply_mem f
  have hvals : (fun i => g (x i)) = fun i => f (x i) := by
    funext i
    have hk : RKHS.kerFun H (x i) 1 ∈ M := Submodule.subset_span ⟨i, rfl⟩
    have h0 : ⟪RKHS.kerFun H (x i) 1, f - g⟫ = 0 := Submodule.inner_right_of_mem_orthogonal hk hperp
    rw [RKHS.kerFun_inner] at h0
    simp at h0
    linarith
  have hfg : f = g := by
    by_contra hne
    have hinner : ⟪g, f - g⟫ = 0 := Submodule.inner_right_of_mem_orthogonal hgM hperp
    have hpy := norm_add_sq_eq_norm_sq_add_norm_sq_real hinner
    rw [add_sub_cancel] at hpy
    have hpos : 0 < ‖f - g‖ := norm_pos_iff.mpr (sub_ne_zero.mpr hne)
    have hlt : ‖g‖ < ‖f‖ := by
      have : ‖g‖ ^ 2 < ‖f‖ ^ 2 := by nlinarith
      exact lt_of_pow_lt_pow_left₀ 2 (norm_nonneg _) this
    have := hf g
    rw [hvals] at this
    linarith [hΩ hlt]
  have hfM : f ∈ M := hfg ▸ hgM
  obtain ⟨α, hα⟩ := (Submodule.mem_span_range_iff_exists_fun ℝ).mp hfM
  exact ⟨α, hα.symm⟩

/-- The reproducing property. In a reproducing kernel Hilbert space of real functions on `X`,
reading a profile's value at a point is its inner product with the bump there,
`f(x) = ⟨f, k_x⟩_k`, and two bumps have the kernel as their inner product,
`⟨k_x, k_{x'}⟩_k = k(x, x')`. -/
theorem value_is_inner_product_with_bump {X H : Type*} [NormedAddCommGroup H]
    [InnerProductSpace ℝ H] [CompleteSpace H] [RKHS ℝ H X ℝ] (f : H) (x x' : X) :
    f x = ⟪f, RKHS.kerFun H x 1⟫ ∧
      ⟪RKHS.kerFun H x 1, RKHS.kerFun H x' 1⟫ = RKHS.kernel H x x' 1 := by
  constructor
  · rw [RKHS.inner_kerFun]; simp
  · rw [RKHS.kerFun_inner, RKHS.kerFun_apply]; simp

/-- Kernel ridge regression. With data points `x₁, …, xₙ`, readings `y`, a positive charge `lam`
(the card's `λ > 0`) and Gram matrix `K_{ij} = k(xᵢ, xⱼ)`, set `α = (K + λI)⁻¹ y` and
`f̂ = ∑ αᵢ k_{xᵢ}`. Then `f̂` is the profile with the smallest cost
`J(f) = ∑ (yᵢ - f(xᵢ))² + λ ‖f‖²`: every profile costs at least as much, and any profile with
the same cost is `f̂` itself. -/
theorem kernel_ridge_fit_solves_linear_system {X H : Type*} [NormedAddCommGroup H]
    [InnerProductSpace ℝ H] [CompleteSpace H] [RKHS ℝ H X ℝ]
    {n : ℕ} (x : Fin n → X) (y : Fin n → ℝ) {lam : ℝ} (hlam : 0 < lam) :
    let K : Matrix (Fin n) (Fin n) ℝ := Matrix.of fun i j => RKHS.kernel H (x i) (x j) 1
    let α : Fin n → ℝ := (K + lam • (1 : Matrix (Fin n) (Fin n) ℝ))⁻¹.mulVec y
    let fhat : H := ∑ i, α i • RKHS.kerFun H (x i) 1
    let J : H → ℝ := fun f => ∑ i, (y i - f (x i)) ^ 2 + lam * ‖f‖ ^ 2
    (∀ f : H, J fhat ≤ J f) ∧ ∀ f : H, J f = J fhat → f = fhat := by
  intro K α fhat J
  set A : Matrix (Fin n) (Fin n) ℝ := K + lam • (1 : Matrix (Fin n) (Fin n) ℝ) with hA
  have hKv : ∀ (c : Fin n → ℝ) (j : Fin n),
      K.mulVec c j = (∑ i, c i • RKHS.kerFun H (x i) 1) (x j) := by
    intro c j
    rw [rkhs_sum_bumps_apply]
    simp only [K, Matrix.mulVec, dotProduct, Matrix.of_apply]
    exact Finset.sum_congr rfl fun i _ => mul_comm _ _
  have hAv : ∀ (c : Fin n → ℝ) (j : Fin n), A.mulVec c j = K.mulVec c j + lam * c j := by
    intro c j
    simp [hA, Matrix.add_mulVec, Matrix.smul_mulVec, Matrix.one_mulVec]
  have hdet : A.det ≠ 0 := by
    intro h0
    obtain ⟨v, hv0, hv⟩ := Matrix.exists_mulVec_eq_zero_iff.mpr h0
    apply hv0
    set gv : H := ∑ i, v i • RKHS.kerFun H (x i) 1
    have hsum : ∑ j, v j * A.mulVec v j = 0 := by simp [hv]
    have hexp : ∑ j, v j * A.mulVec v j = ⟪gv, gv⟫ + lam * ∑ j, v j ^ 2 := by
      rw [rkhs_inner_sum_bumps, Finset.mul_sum, ← Finset.sum_add_distrib]
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [hAv, hKv]; ring
    have hgg : 0 ≤ ⟪gv, gv⟫ := real_inner_self_nonneg
    have hsq : ∑ j, v j ^ 2 = 0 := by
      have h1 : 0 ≤ ∑ j, v j ^ 2 := Finset.sum_nonneg fun j _ => sq_nonneg _
      nlinarith
    funext j
    have := (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => sq_nonneg (v j))).mp hsq j
      (Finset.mem_univ _)
    simpa using this
  have hsys : A.mulVec α = y := by
    simp only [α, Matrix.mulVec_mulVec]
    rw [Matrix.mul_nonsing_inv A (isUnit_iff_ne_zero.mpr hdet), Matrix.one_mulVec]
  have hres : ∀ j, y j - fhat (x j) = lam * α j := by
    intro j
    have := congrFun hsys j
    rw [hAv, hKv] at this
    linarith
  have key : ∀ h : H, J (fhat + h) = J fhat + (∑ i, h (x i) ^ 2 + lam * ‖h‖ ^ 2) := by
    intro h
    have hin : ⟪fhat, h⟫ = ∑ i, α i * h (x i) := rkhs_inner_sum_bumps x α h
    simp only [J]
    rw [norm_add_sq_real, hin]
    have e1 : ∑ i, (y i - (fhat + h) (x i)) ^ 2
        = ∑ i, ((y i - fhat (x i)) ^ 2 + h (x i) ^ 2 - 2 * lam * (α i * h (x i))) := by
      refine Finset.sum_congr rfl fun i _ => ?_
      have := hres i
      simp only [RKHS.coe_add, Pi.add_apply]
      rw [show y i - (fhat (x i) + h (x i)) = (y i - fhat (x i)) - h (x i) by ring, this]
      ring
    rw [e1, Finset.sum_sub_distrib, Finset.sum_add_distrib, ← Finset.mul_sum]
    ring
  refine ⟨fun f => ?_, fun f hf => ?_⟩
  · have := key (f - fhat)
    rw [add_sub_cancel] at this
    rw [this]
    have h1 : 0 ≤ ∑ i, (f - fhat) (x i) ^ 2 := Finset.sum_nonneg fun i _ => sq_nonneg _
    have h2 : 0 ≤ lam * ‖f - fhat‖ ^ 2 := mul_nonneg hlam.le (sq_nonneg _)
    linarith
  · have := key (f - fhat)
    rw [add_sub_cancel, hf] at this
    have h1 : 0 ≤ ∑ i, (f - fhat) (x i) ^ 2 := Finset.sum_nonneg fun i _ => sq_nonneg _
    have h2 : 0 ≤ lam * ‖f - fhat‖ ^ 2 := mul_nonneg hlam.le (sq_nonneg _)
    have h3 : lam * ‖f - fhat‖ ^ 2 = 0 := by linarith
    have h4 : ‖f - fhat‖ = 0 := by
      rcases mul_eq_zero.mp h3 with h | h
      · exact absurd h hlam.ne'
      · exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h
    exact sub_eq_zero.mp (norm_eq_zero.mp h4)

-- The borehole: thermometers at 1, 2, 3 m, readings above the deep 10 °C are y = (6, 3, 2),
-- kernel 2^(-(x - x')²), so the Gram matrix has rows (1, 1/2, 1/16), (1/2, 1, 1/2), (1/16, 1/2, 1).
-- Times 16, the system (K + I/16) α = y has rows (17, 8, 1), (8, 17, 8), (1, 8, 17) and right
-- side (96, 48, 32); its solution is α = (530/89, -80/89, 174/89) = (5.9551, -0.8989, 1.9551).
example : (17 * (530 / 89) + 8 * (-80 / 89) + 1 * (174 / 89) : ℚ) = 96 ∧
    (8 * (530 / 89) + 17 * (-80 / 89) + 8 * (174 / 89) : ℚ) = 48 ∧
    (1 * (530 / 89) + 8 * (-80 / 89) + 17 * (174 / 89) : ℚ) = 32 := by norm_num

-- The by-hand steps: α₁ - α₃ = 4, α₁ + α₃ = 704/89, 89 α₂ = -80.
example : (530 / 89 - 174 / 89 : ℚ) = 4 ∧ (530 / 89 + 174 / 89 : ℚ) = 704 / 89 ∧
    (89 * (-80 / 89) : ℚ) = -80 := by norm_num

-- K⁻¹ = (1/225) [[320, -200, 80], [-200, 425, -200], [80, -200, 320]].
example : !![(1 : ℚ), 1/2, 1/16; 1/2, 1, 1/2; 1/16, 1/2, 1] *
    ((1 / 225 : ℚ) • !![(320 : ℚ), -200, 80; -200, 425, -200; 80, -200, 320]) = 1 := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Fin.sum_univ_three, Matrix.one_apply]

-- Each weight is its leftover over λ = 1/16: leftovers y - Kα are (265/712, -5/89, 87/712),
-- and 16 times them is α; the best cost is J* = 411/178 = 2.3090 °C².
example : (6 - (530 / 89 + (1 / 2) * (-80 / 89) + (1 / 16) * (174 / 89)) : ℚ) = 265 / 712 ∧
    (16 * (265 / 712) : ℚ) = 530 / 89 ∧
    ((265 / 712) ^ 2 + (-5 / 89) ^ 2 + (87 / 712) ^ 2 +
      (1 / 16) * ((530 / 89) * (6 - 265 / 712) + (-80 / 89) * (3 + 5 / 89) +
        (174 / 89) * (2 - 87 / 712)) : ℚ) = 411 / 178 := by norm_num

-- The surface bump k₀ reads (1/2, 1/16, 1/512) at 1, 2, 3 m; what is left after its shadow on
-- the data bumps has squared length 1 - k₀ᵀ K⁻¹ k₀ = 2835/4096 = 0.6921.
example : (1 - (1 / 225) * ((1 / 2) * (320 * (1 / 2) - 200 * (1 / 16) + 80 * (1 / 512)) +
    (1 / 16) * (-200 * (1 / 2) + 425 * (1 / 16) - 200 * (1 / 512)) +
    (1 / 512) * (80 * (1 / 2) - 200 * (1 / 16) + 320 * (1 / 512))) : ℚ) = 2835 / 4096 := by
  norm_num

-- What breaks: the box similarity at 1, 1.9, 2.8 m has rows (1, 1, 0), (1, 1, 1), (0, 1, 1),
-- and the weights c = (1, -1, 1) give a "squared length" cᵀ B c = -1.
example : dotProduct ![(1 : ℤ), -1, 1]
    (!![(1 : ℤ), 1, 0; 1, 1, 1; 0, 1, 1].mulVec ![1, -1, 1]) = -1 := by decide

#print axioms rkhs_sum_bumps_apply
#print axioms rkhs_inner_sum_bumps
#print axioms best_fit_is_sum_of_bumps_at_data
#print axioms value_is_inner_product_with_bump
#print axioms kernel_ridge_fit_solves_linear_system
