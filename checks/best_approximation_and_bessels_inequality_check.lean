-- Partial sums are the best fit: the Fourier partial sum of degree N is the closest trigonometric polynomial of degree N to a finite-energy signal in mean square, and so the coefficients obey Bessel's inequality and tend to zero.
import Mathlib.Analysis.Fourier.AddCircle

open MeasureTheory Filter Topology AddCircle

noncomputable section

variable {T : ℝ} [hT : Fact (0 < T)]

/-- The inner product of the `n`-th Fourier monomial with `h` is the `n`-th Fourier coefficient. -/
theorem inner_fourierLp_eq_fourierCoeff (h : Lp ℂ 2 (haarAddCircle (T := T))) (n : ℤ) :
    inner ℂ (fourierLp (T := T) 2 n) h = fourierCoeff h n := by
  rw [← fourierBasis_repr, fourierBasis.repr_apply_apply, coe_fourierBasis]

/-- **Partial sums are the best fit.** Let `h` be a signal of finite energy on the circle
(an element of `L²`, with the normalised measure, so `‖h‖²` is the mean square), `N` a degree,
and `P = ∑_{|n| ≤ N} p n • e^{inx}` any trigonometric polynomial of degree `N`. Then the mean
square miss of `P` equals the miss of the partial sum `S_N h = ∑_{|n| ≤ N} ĥ(n) • e^{inx}` plus
`∑_{|n| ≤ N} |ĥ(n) - p n|²`; in particular the partial sum misses by no more than `P`. -/
theorem partial_sum_is_best_mean_square_fit (h : Lp ℂ 2 (haarAddCircle (T := T))) (N : ℕ)
    (p : ℤ → ℂ) :
    ‖h - ∑ n ∈ Finset.Icc (-(N : ℤ)) N, p n • fourierLp (T := T) 2 n‖ ^ 2 =
        ‖h - ∑ n ∈ Finset.Icc (-(N : ℤ)) N, fourierCoeff h n • fourierLp (T := T) 2 n‖ ^ 2 +
          ∑ n ∈ Finset.Icc (-(N : ℤ)) N, ‖fourierCoeff h n - p n‖ ^ 2 ∧
      ‖h - ∑ n ∈ Finset.Icc (-(N : ℤ)) N, fourierCoeff h n • fourierLp (T := T) 2 n‖ ≤
        ‖h - ∑ n ∈ Finset.Icc (-(N : ℤ)) N, p n • fourierLp (T := T) 2 n‖ := by
  set s := Finset.Icc (-(N : ℤ)) N
  set c := fun n : ℤ => fourierCoeff h n with hc
  have ho : Orthonormal ℂ (fourierLp (T := T) 2) := orthonormal_fourier
  set e := fourierLp (T := T) 2
  have key : h - ∑ n ∈ s, p n • e n =
      (h - ∑ n ∈ s, c n • e n) + ∑ n ∈ s, (c n - p n) • e n := by
    simp only [sub_smul, Finset.sum_sub_distrib]
    abel
  have orth : inner ℂ (h - ∑ n ∈ s, c n • e n) (∑ n ∈ s, (c n - p n) • e n) = 0 := by
    rw [inner_sum]
    refine Finset.sum_eq_zero fun i hi => ?_
    rw [inner_smul_right, inner_sub_left, ho.inner_left_sum c hi, ← inner_conj_symm,
      inner_fourierLp_eq_fourierCoeff]
    simp [c]
  have hQ : ‖∑ n ∈ s, (c n - p n) • e n‖ ^ 2 = ∑ n ∈ s, ‖c n - p n‖ ^ 2 := by
    rw [@norm_sq_eq_re_inner ℂ, ho.inner_sum, map_sum]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [RCLike.conj_mul]
    norm_cast
  have eq1 : ‖h - ∑ n ∈ s, p n • e n‖ ^ 2 =
      ‖h - ∑ n ∈ s, c n • e n‖ ^ 2 + ∑ n ∈ s, ‖c n - p n‖ ^ 2 := by
    rw [key, ← hQ]
    simp only [sq]
    exact norm_add_sq_eq_norm_sq_add_norm_sq_of_inner_eq_zero _ _ orth
  refine ⟨eq1, ?_⟩
  have hnn : 0 ≤ ∑ n ∈ s, ‖c n - p n‖ ^ 2 := Finset.sum_nonneg fun _ _ => by positivity
  have : ‖h - ∑ n ∈ s, c n • e n‖ ^ 2 ≤ ‖h - ∑ n ∈ s, p n • e n‖ ^ 2 := by
    rw [eq1]; linarith
  exact (sq_le_sq₀ (norm_nonneg _) (norm_nonneg _)).mp this

/-- **Bessel's inequality.** For a signal `h` of finite energy on the circle, the kept energies
`∑_{|n| ≤ N} |ĥ(n)|²` never exceed the mean square `‖h‖²`, for every degree `N`; so the full sum
of `|ĥ(n)|²` over all whole numbers `n` converges and is at most `‖h‖²`. -/
theorem bessels_inequality (h : Lp ℂ 2 (haarAddCircle (T := T))) :
    (∀ N : ℕ, ∑ n ∈ Finset.Icc (-(N : ℤ)) N, ‖fourierCoeff h n‖ ^ 2 ≤ ‖h‖ ^ 2) ∧
      Summable (fun n : ℤ => ‖fourierCoeff h n‖ ^ 2) ∧
      ∑' n : ℤ, ‖fourierCoeff h n‖ ^ 2 ≤ ‖h‖ ^ 2 := by
  have ho : Orthonormal ℂ (fourierLp (T := T) 2) := orthonormal_fourier
  have hc : ∀ n : ℤ, ‖fourierCoeff h n‖ ^ 2 = ‖inner ℂ (fourierLp (T := T) 2 n) h‖ ^ 2 := by
    intro n; rw [inner_fourierLp_eq_fourierCoeff]
  simp_rw [hc]
  exact ⟨fun N => ho.sum_inner_products_le h, ho.inner_products_summable h,
    ho.tsum_inner_products_le h⟩

/-- **The coefficients tend to zero.** For every signal `h` of finite energy on the circle,
`ĥ(n) → 0` as `|n| → ∞` (the square-integrable form of the Riemann–Lebesgue lemma). -/
theorem fourier_coefficients_tend_to_zero (h : Lp ℂ 2 (haarAddCircle (T := T))) :
    Tendsto (fun n : ℤ => fourierCoeff h n) cofinite (𝓝 0) := by
  have hs : Summable (fun n : ℤ => ‖fourierCoeff h n‖ ^ 2) := (bessels_inequality h).2.1
  have h1 : Tendsto (fun n : ℤ => ‖fourierCoeff h n‖ ^ 2) cofinite (𝓝 0) :=
    hs.tendsto_cofinite_zero
  have h2 : Tendsto (fun n : ℤ => ‖fourierCoeff h n‖) cofinite (𝓝 0) := by
    have := (Real.continuous_sqrt.tendsto 0).comp h1
    simp only [Function.comp_def, Real.sqrt_sq (norm_nonneg _), Real.sqrt_zero] at this
    exact this
  exact tendsto_zero_iff_norm_tendsto_zero.mpr h2

end

#print axioms inner_fourierLp_eq_fourierCoeff
#print axioms partial_sum_is_best_mean_square_fit
#print axioms bessels_inequality
#print axioms fourier_coefficients_tend_to_zero
