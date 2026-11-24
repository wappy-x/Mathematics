-- Poincare maps: for a linear periodic law the once-per-period map z ↦ M z + c has exactly one fixed point and every start converges to it when all eigenvalues of M (the Floquet multipliers) are smaller than 1 in size, each multiplier of M = e^(T A) is e^(T λ), and the pushed spring x'' + 0.2 x' + x = cos t has the steady 2π-periodic swing 5 sin t.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Algebra.Algebra.Spectrum.Basic
import Mathlib.Topology.Instances.Matrix
import Mathlib.Analysis.Normed.Algebra.GelfandFormula
import Mathlib.Analysis.SpecialFunctions.Pow.NNReal
import Mathlib.Analysis.Complex.Basic

open Filter Topology Matrix

open scoped NNReal ENNReal in
theorem pow_norm_tendsto_zero_of_spectralRadius_lt_one {A : Type*} [NormedRing A]
    [NormedAlgebra ℂ A] [CompleteSpace A] (a : A) (h : spectralRadius ℂ a < 1) :
    Tendsto (fun k : ℕ => ‖a ^ k‖) atTop (𝓝 0) := by
  obtain ⟨r, hr1, hr2⟩ := ENNReal.lt_iff_exists_nnreal_btwn.mp h
  have hr : (r : ℝ) < 1 := by exact_mod_cast ENNReal.coe_lt_one_iff.mp hr2
  have hev := (spectrum.pow_nnnorm_pow_one_div_tendsto_nhds_spectralRadius a).eventually
    (gt_mem_nhds hr1)
  have hb : ∀ᶠ k : ℕ in atTop, ‖a ^ k‖ ≤ (r : ℝ) ^ k := by
    filter_upwards [hev, eventually_ge_atTop 1] with k hk hk1
    have hkpos : (0 : ℝ) < k := by exact_mod_cast hk1
    rw [one_div, ENNReal.rpow_inv_lt_iff hkpos, ENNReal.rpow_natCast] at hk
    have h2 : ‖a ^ k‖₊ < r ^ k := by exact_mod_cast hk
    have h3 := NNReal.coe_lt_coe.mpr h2
    push_cast at h3
    exact h3.le
  exact squeeze_zero' (Eventually.of_forall fun k => norm_nonneg _) hb
    (tendsto_pow_atTop_nhds_zero_of_lt_one r.coe_nonneg hr)

#print axioms pow_norm_tendsto_zero_of_spectralRadius_lt_one

section
attribute [local instance] Matrix.linftyOpNormedRing Matrix.linftyOpNormedAlgebra

theorem real_matrix_pow_mulVec_tendsto_zero {n : ℕ} [Nonempty (Fin n)]
    (M : Matrix (Fin n) (Fin n) ℝ)
    (hμ : ∀ μ ∈ spectrum ℂ (M.map (algebraMap ℝ ℂ)), ‖μ‖ < 1) (v : Fin n → ℝ) :
    Tendsto (fun k : ℕ => (M ^ k) *ᵥ v) atTop (𝓝 0) := by
  have : CompleteSpace (Matrix (Fin n) (Fin n) ℂ) := FiniteDimensional.complete ℂ _
  set Mc := M.map (algebraMap ℝ ℂ) with hMc
  have hρ : spectralRadius ℂ Mc < 1 := by
    have := spectrum.spectralRadius_lt_of_forall_lt_of_nonempty (r := 1) (spectrum.nonempty Mc)
      (fun μ hμ' => by
        rw [← NNReal.coe_lt_coe]
        simpa using hμ μ hμ')
    simpa using this
  have h0 := pow_norm_tendsto_zero_of_spectralRadius_lt_one Mc hρ
  have hnorm : ∀ k : ℕ, ‖M ^ k‖ = ‖Mc ^ k‖ := by
    intro k
    have : Mc ^ k = (M ^ k).map (algebraMap ℝ ℂ) := by
      rw [hMc, ← RingHom.mapMatrix_apply, ← RingHom.mapMatrix_apply, map_pow]
    rw [this, Matrix.linfty_opNorm_def, Matrix.linfty_opNorm_def]
    simp
  have h1 : Tendsto (fun k : ℕ => ‖M ^ k‖ * ‖v‖) atTop (𝓝 0) := by
    simpa [hnorm] using h0.mul_const ‖v‖
  exact squeeze_zero_norm (fun k => Matrix.linfty_opNorm_mulVec _ _) h1

end

#print axioms real_matrix_pow_mulVec_tendsto_zero

/-- The stability test for a linear law's stroboscopic (Poincare) map. The map is affine,
`P z = M z + c`. If every eigenvalue of `M` (every Floquet multiplier, taken over the complex
numbers) is smaller than 1 in size, then `P` has exactly one fixed point `z*` (the periodic
orbit), and from every start the snapshots `P^[k] z` converge to `z*`. -/
theorem affine_return_map_fixed_point_attracts {n : ℕ} (M : Matrix (Fin n) (Fin n) ℝ)
    (c : Fin n → ℝ)
    (hμ : ∀ μ ∈ spectrum ℂ (M.map (algebraMap ℝ ℂ)), ‖μ‖ < 1) :
    ∃! zs : Fin n → ℝ, M *ᵥ zs + c = zs ∧
      ∀ z : Fin n → ℝ, Tendsto (fun k : ℕ => (fun w => M *ᵥ w + c)^[k] z) atTop (𝓝 zs) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · refine ⟨0, ⟨Subsingleton.elim _ _, fun z => ?_⟩, fun y _ => Subsingleton.elim _ _⟩
    exact tendsto_const_nhds.congr (fun k => Subsingleton.elim _ _)
  have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
  have hdecay : ∀ v, Tendsto (fun k : ℕ => (M ^ k) *ᵥ v) atTop (𝓝 0) :=
    real_matrix_pow_mulVec_tendsto_zero M hμ
  have hfix : ∀ w, M *ᵥ w = w → w = 0 := by
    intro w hw
    have hpow : ∀ k : ℕ, (M ^ k) *ᵥ w = w := by
      intro k
      induction k with
      | zero => simp
      | succ k ih => rw [pow_succ, ← Matrix.mulVec_mulVec, hw, ih]
    have := hdecay w
    simp only [hpow] at this
    exact tendsto_nhds_unique tendsto_const_nhds this
  have hinj : Function.Injective (1 - M).mulVec := by
    intro a b hab
    have h1 : (1 - M) *ᵥ (a - b) = 0 := by rw [Matrix.mulVec_sub, hab, sub_self]
    rw [Matrix.sub_mulVec, Matrix.one_mulVec, sub_eq_zero] at h1
    exact sub_eq_zero.mp (hfix _ h1.symm)
  have hsurj := Matrix.mulVec_surjective_iff_isUnit.mpr (Matrix.mulVec_injective_iff_isUnit.mp hinj)
  obtain ⟨zs, hzs⟩ := hsurj c
  have hfp : M *ᵥ zs + c = zs := by
    rw [← hzs, Matrix.sub_mulVec, Matrix.one_mulVec]; abel
  have hMzs : M *ᵥ zs = zs - c := eq_sub_of_add_eq hfp
  refine ⟨zs, ⟨hfp, fun z => ?_⟩, fun y hy => ?_⟩
  · have hit : ∀ k : ℕ, (fun w => M *ᵥ w + c)^[k] z = zs + (M ^ k) *ᵥ (z - zs) := by
      intro k
      induction k with
      | zero => simp
      | succ k ih =>
        rw [Function.iterate_succ_apply', ih]
        rw [Matrix.mulVec_add, pow_succ', ← Matrix.mulVec_mulVec, hMzs]
        abel
    simp_rw [hit]
    simpa using tendsto_const_nhds.add (hdecay (z - zs))
  · have := hfix (y - zs) (by rw [Matrix.mulVec_sub, eq_sub_of_add_eq hy.1, hMzs]; abel)
    exact sub_eq_zero.mp this

/-- Step 4: the multipliers of `M = e^(T A)` are `e^(T λ)`. If `u` is an eigenvector of `A`
with eigenvalue `λ`, then `e^(T A)` multiplies `u` by `e^(T λ)`. -/
theorem exp_mulVec_of_eigenvector {n : ℕ} (A : Matrix (Fin n) (Fin n) ℂ) (u : Fin n → ℂ)
    (lam : ℂ) (T : ℝ) (hu : A *ᵥ u = lam • u) :
    NormedSpace.exp ((T : ℂ) • A) *ᵥ u = Complex.exp (T * lam) • u := by
  set X : Matrix (Fin n) (Fin n) ℂ := (T : ℂ) • A with hX
  have hXu : X *ᵥ u = ((T : ℂ) * lam) • u := by
    rw [hX, Matrix.smul_mulVec, hu, smul_smul]
  have hpow : ∀ k : ℕ, (X ^ k) *ᵥ u = ((T : ℂ) * lam) ^ k • u := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      rw [pow_succ', ← Matrix.mulVec_mulVec, ih, Matrix.mulVec_smul, hXu, smul_smul, pow_succ]
  have hS : HasSum (fun k : ℕ => ((k.factorial⁻¹ : ℂ) • X ^ k)) (NormedSpace.exp X) := by
    open scoped Norms.Operator in exact NormedSpace.exp_series_hasSum_exp' (𝕂 := ℂ) X
  have hS2 := hS.map (Matrix.mulVec.addMonoidHomLeft u)
    (continuous_id.matrix_mulVec continuous_const)
  have hC : HasSum (fun k : ℕ => ((k.factorial⁻¹ : ℂ) • ((T : ℂ) * lam) ^ k))
      (Complex.exp (T * lam)) := by
    rw [Complex.exp_eq_exp_ℂ]
    exact NormedSpace.exp_series_hasSum_exp' (𝕂 := ℂ) _
  have hC2 := hC.smul_const u
  refine hS2.unique ?_
  convert hC2 using 1
  funext k
  simp [Matrix.mulVec.addMonoidHomLeft, Matrix.smul_mulVec, hpow, smul_smul]

/-- Step 2, second road: the swing `x = 5 sin t` solves `x'' + 0.2 x' + x = cos t`, repeats
every `2π`, and so shows the same snapshot `(x, v) = (0, 5)` at every flash: the fixed point. -/
theorem steady_swing_is_periodic_solution :
    (∀ t : ℝ, deriv (deriv fun s => 5 * Real.sin s) t + (1 / 5 : ℝ) * deriv (fun s => 5 * Real.sin s) t
        + 5 * Real.sin t = Real.cos t) ∧
    (∀ t : ℝ, 5 * Real.sin (t + 2 * Real.pi) = 5 * Real.sin t) ∧
    ((5 * Real.sin 0, deriv (fun s => 5 * Real.sin s) 0) = ((0 : ℝ), (5 : ℝ))) := by
  have h1 : deriv (fun s => 5 * Real.sin s) = fun s => 5 * Real.cos s := by
    funext s; simp
  have h2 : deriv (fun s => 5 * Real.cos s) = fun s => -(5 * Real.sin s) := by
    funext s; simp
  refine ⟨fun t => ?_, fun t => ?_, ?_⟩
  · rw [h1, h2]; ring
  · rw [Real.sin_add_two_pi]
  · rw [h1]; simp

/-- The amplitude: damping 0.2 = 1/5 times amplitude 5 matches the push of size 1. -/
example : (1 / 5 : ℚ) * 5 = 1 := by norm_num

/-- The hand formula for `M`: with `N = A + 0.1 I = [[1/10, 1], [-1, -1/10]]`,
`N^2 = -(99/100) I`, so `ω^2 = 1 - 0.01 = 0.99`. -/
example : (!![1 / 10, 1; -1, -1 / 10] : Matrix (Fin 2) (Fin 2) ℚ) ^ 2
    = -(99 / 100 : ℚ) • (1 : Matrix (Fin 2) (Fin 2) ℚ) := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [sq, Matrix.mul_apply, Fin.sum_univ_two]

/-- `N = A + 0.1 I` with `A = [[0, 1], [-1, -1/5]]`. -/
example : (!![0, 1; -1, -1 / 5] : Matrix (Fin 2) (Fin 2) ℚ) + (1 / 10 : ℚ) • 1
    = !![1 / 10, 1; -1, -1 / 10] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num

#print axioms affine_return_map_fixed_point_attracts
#print axioms exp_mulVec_of_eigenvector
#print axioms steady_swing_is_periodic_solution
