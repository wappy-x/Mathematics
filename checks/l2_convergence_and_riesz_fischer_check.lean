-- Convergence in energy: every finite-energy signal on the circle is the limit in energy of its Fourier partial sums, its energy equals the sum of its squared coefficients, and every square-summable list is the coefficient list of exactly one finite-energy signal.
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.Order.Filter.AtTopBot.Interval

open MeasureTheory Filter Topology Real

namespace L2ConvergenceRieszFischer

/-! Notation, as on the card. The phase `x` runs over one cycle of length `2π`, with the two
ends joined: the circle `𝕋` is `AddCircle (2 * π)`. Mathlib's `haarAddCircle` is the length
measure divided by `2π`, so for a signal `f` in `L²(𝕋)` (Mathlib's `Lp ℂ 2 haarAddCircle`,
signals equal off a set of length zero counted as one) the energy
`(1/2π) ∫_{-π}^{π} |f(x)|² dx` is `‖f‖ ^ 2`. Mathlib's `fourierCoeff f n` is the card's
`f̂(n) = (1/2π) ∫ f(x) e^{-inx} dx`, and `fourierLp 2 n` is the harmonic `e^{inx}` as a
finite-energy signal. -/

local instance : Fact (0 < 2 * π) := ⟨Real.two_pi_pos⟩

/-- The finite-energy signals on the circle, `L²(𝕋)`. -/
abbrev L2Circle : Type := Lp ℂ 2 (@AddCircle.haarAddCircle (2 * π) _)

/-- The partial sum `S_N f = ∑_{|n| ≤ N} f̂(n) e^{inx}`: harmonics `-N` to `N` kept. -/
noncomputable def partialSum (f : L2Circle) (N : ℕ) : L2Circle :=
  ∑ n ∈ Finset.Icc (-(N : ℤ)) N, fourierCoeff (⇑f) n • fourierLp 2 n

/-- The partial sum built from a list, `P_N = ∑_{|n| ≤ N} c_n e^{inx}`. -/
noncomputable def listPartialSum (c : ℤ → ℂ) (N : ℕ) : L2Circle :=
  ∑ n ∈ Finset.Icc (-(N : ℤ)) N, c n • fourierLp 2 n

theorem parseval_helper (f : L2Circle) :
    HasSum (fun n : ℤ => ‖fourierCoeff (⇑f) n‖ ^ 2) (‖f‖ ^ 2) := by
  simp_rw [← fourierBasis_repr]
  have H₁ : HasSum (fun i => ‖fourierBasis.repr f i‖ ^ 2) (‖fourierBasis.repr f‖ ^ 2) := by
    apply_mod_cast lp.hasSum_norm ?_ (fourierBasis.repr f)
    simp
  have H₂ : ‖fourierBasis.repr f‖ ^ 2 = ‖f‖ ^ 2 := by simp
  rwa [H₂] at H₁

#print axioms parseval_helper

theorem coeff_sub_partialSum (f : L2Circle) (N : ℕ) (n : ℤ) :
    fourierCoeff (⇑(f - partialSum f N)) n =
      if n ∈ Finset.Icc (-(N : ℤ)) N then 0 else fourierCoeff (⇑f) n := by
  classical
  have key : ∀ m : ℤ, fourierBasis.repr (fourierLp 2 m : L2Circle) n =
      if n = m then 1 else 0 := by
    intro m
    rw [← coe_fourierBasis, HilbertBasis.repr_self, lp.single_apply, Pi.single_apply]
  rw [← fourierBasis_repr, ← fourierBasis_repr]
  rw [map_sub, partialSum, map_sum, lp.coeFn_sub, Pi.sub_apply, lp.coeFn_sum, Finset.sum_apply]
  simp only [map_smul, lp.coeFn_smul, Pi.smul_apply, key, smul_eq_mul, mul_ite, mul_one,
    mul_zero, Finset.sum_ite_eq, fourierBasis_repr]
  split_ifs <;> simp

#print axioms coeff_sub_partialSum

theorem tendsto_partialSum (f : L2Circle) :
    Tendsto (fun N : ℕ => partialSum f N) atTop (𝓝 f) :=
  (hasSum_fourier_series_L2 f).comp Finset.tendsto_Icc_neg

#print axioms tendsto_partialSum

/-- **Convergence in energy** (The formula, first statement; Why it works, Steps 1 and 2).
For every finite-energy signal `f` on the circle, the energy of the gap after harmonic `N` is
the energy of the coefficients left out, `‖f - S_N f‖² = ∑_{|n| > N} |f̂(n)|²`, and this gap
falls to zero: `‖f - S_N f‖ → 0` as `N → ∞`. -/
theorem fourier_partial_sums_converge_in_energy (f : L2Circle) :
    (∀ N : ℕ, HasSum (fun n : {n : ℤ // (N : ℤ) < |n|} => ‖fourierCoeff (⇑f) n‖ ^ 2)
        (‖f - partialSum f N‖ ^ 2)) ∧
      Tendsto (fun N : ℕ => ‖f - partialSum f N‖) atTop (𝓝 0) := by
  refine ⟨fun N => ?_, ?_⟩
  · have h := parseval_helper (f - partialSum f N)
    have hs : Function.support (fun n : ℤ => ‖fourierCoeff (⇑(f - partialSum f N)) n‖ ^ 2) ⊆
        {n : ℤ | (N : ℤ) < |n|} := by
      intro n hn
      by_contra hlt
      have hlt' : |n| ≤ (N : ℤ) := not_lt.mp hlt
      apply hn
      have hmem : n ∈ Finset.Icc (-(N : ℤ)) N := Finset.mem_Icc.mpr (abs_le.mp hlt')
      show ‖fourierCoeff (⇑(f - partialSum f N)) n‖ ^ 2 = 0
      rw [coeff_sub_partialSum]
      simp only [hmem, ↓reduceIte, norm_zero]
      norm_num
    have h2 := (hasSum_subtype_iff_of_support_subset hs).mpr h
    convert h2 using 1
    funext ⟨n, hn⟩
    have hmem : n ∉ Finset.Icc (-(N : ℤ)) N := by
      intro h'
      exact absurd (abs_le.mpr (Finset.mem_Icc.mp h')) (not_le.mpr hn)
    show ‖fourierCoeff (⇑f) n‖ ^ 2 = ‖fourierCoeff (⇑(f - partialSum f N)) n‖ ^ 2
    rw [coeff_sub_partialSum]
    simp only [hmem, ↓reduceIte]
  · have h := (tendsto_iff_norm_sub_tendsto_zero.mp (tendsto_partialSum f))
    simpa [norm_sub_rev] using h

/-- **Parseval for every finite-energy signal** (Why it works, Step 3). The energy of a
finite-energy signal `f` on the circle equals the sum of its squared coefficients over all
whole numbers `n`, negative ones included: `‖f‖² = ∑_n |f̂(n)|²`. -/
theorem parseval_energy_eq_sum_sq_coeff (f : L2Circle) :
    HasSum (fun n : ℤ => ‖fourierCoeff (⇑f) n‖ ^ 2) (‖f‖ ^ 2) := by
  exact parseval_helper f

/-- **Riesz-Fischer, from a list to a signal** (The formula, second statement; Why it works,
Step 4). Let `c` be a square-summable list, one complex number `c_n` for every whole number
`n` (`c ∈ ℓ²(ℤ)`). Then exactly one finite-energy signal `f` on the circle has `f̂(n) = c_n`
for every `n`, and the list's partial sums `P_N = ∑_{|n| ≤ N} c_n e^{inx}` converge to that
signal in energy. -/
theorem riesz_fischer_square_summable_list_builds_one_signal (c : ℤ → ℂ) (hc : Memℓp c 2) :
    (∃! f : L2Circle, ∀ n : ℤ, fourierCoeff (⇑f) n = c n) ∧
      ∀ f : L2Circle, (∀ n : ℤ, fourierCoeff (⇑f) n = c n) →
        Tendsto (fun N : ℕ => ‖f - listPartialSum c N‖) atTop (𝓝 0) := by
  refine ⟨⟨fourierBasis.repr.symm ⟨c, hc⟩, fun n => ?_, fun g hg => ?_⟩, fun f hf => ?_⟩
  · rw [← fourierBasis_repr, LinearIsometryEquiv.apply_symm_apply]
  · apply fourierBasis.repr.injective
    rw [LinearIsometryEquiv.apply_symm_apply]
    ext n
    rw [fourierBasis_repr, hg]
  · have he : ∀ N, listPartialSum c N = partialSum f N := by
      intro N
      simp only [listPartialSum, partialSum, hf]
    simp_rw [he]
    exact (fourier_partial_sums_converge_in_energy f).2

/-! The card's whole-number worked facts. -/

/-- The siren: 220 cycles a second switch 440 times a second. -/
example : 2 * 220 = 440 := by norm_num

/-- Odd harmonics of 220 Hz: harmonics 3 and 5 sit at 660 Hz and 1100 Hz. -/
example : 3 * 220 = 660 ∧ 5 * 220 = 1100 := by norm_num

/-- The CD copy keeps odd harmonics up to 99: `99 × 220 = 21780 ≤ 22050 < 22220 = 101 × 220`. -/
example : 99 * 220 = 21780 ∧ 99 * 220 ≤ 22050 ∧ 22050 < 101 * 220 ∧ 101 * 220 = 22220 := by
  norm_num

/-- Harmonic `n` of the rebuilt signal holds `1/(2n²)` V²: 1/2, 1/8, 1/18, 1/32, 1/50 for
`n = 1` to `5`. -/
example : (1 : ℚ) / (2 * 1 ^ 2) = 1 / 2 ∧ (1 : ℚ) / (2 * 2 ^ 2) = 1 / 8 ∧
    (1 : ℚ) / (2 * 3 ^ 2) = 1 / 18 ∧ (1 : ℚ) / (2 * 4 ^ 2) = 1 / 32 ∧
    (1 : ℚ) / (2 * 5 ^ 2) = 1 / 50 := by norm_num

/-- The Cauchy bounds `1/(2N)` at `N = 10, 100, 1000`: 1/20, 1/200, 1/2000. -/
example : (1 : ℚ) / (2 * 10) = 1 / 20 ∧ (1 : ℚ) / (2 * 100) = 1 / 200 ∧
    (1 : ℚ) / (2 * 1000) = 1 / 2000 := by norm_num

#print axioms fourier_partial_sums_converge_in_energy
#print axioms parseval_energy_eq_sum_sq_coeff
#print axioms riesz_fischer_square_summable_list_builds_one_signal

end L2ConvergenceRieszFischer
