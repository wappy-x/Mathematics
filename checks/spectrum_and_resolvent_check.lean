-- Spectrum: every bounded operator on a nonzero complex Banach space has a nonempty, closed and bounded spectrum, and the delay line on ℓ² has no eigenvalues, its spectrum is the closed unit disc, residual inside and continuous on the circle.
import Mathlib.Analysis.Normed.Algebra.Spectrum
import Mathlib.Analysis.Normed.Lp.lpSpace
import Mathlib.Analysis.Normed.Operator.NormedSpace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Normed.Algebra.GelfandFormula
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Analysis.Normed.Operator.Banach
import Mathlib.Analysis.SpecificLimits.Basic

open scoped ENNReal

theorem delay_single (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0) (hS : ∀ x n, S x (n + 1) = x n)
    (n : ℕ) (c : ℂ) : S (lp.single 2 n c) = lp.single 2 (n + 1) c := by
  ext m
  cases m with
  | zero => simp [hS0]
  | succ m => rw [hS]; simp [Pi.single_apply]

theorem delay_norm (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0) (hS : ∀ x n, S x (n + 1) = x n)
    (x : lp (fun _ : ℕ => ℂ) 2) : ‖S x‖ = ‖x‖ := by
  have hp : 0 < (2 : ℝ≥0∞).toReal := by norm_num
  have h1 := lp.norm_rpow_eq_tsum hp (S x)
  have h2 := lp.norm_rpow_eq_tsum hp x
  have hsum := (lp.memℓp (S x)).summable hp
  rw [hsum.tsum_eq_zero_add] at h1
  simp only [hS0, hS, norm_zero] at h1
  rw [Real.zero_rpow hp.ne', zero_add, ← h2] at h1
  simp only [ENNReal.toReal_ofNat, Real.rpow_two] at h1
  exact (pow_left_inj₀ (norm_nonneg _) (norm_nonneg _) two_ne_zero).1 h1

theorem delay_eigen (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0) (hS : ∀ x n, S x (n + 1) = x n)
    (μ : ℂ) (x : lp (fun _ : ℕ => ℂ) 2) (h : S x = μ • x) : x = 0 := by
  have key : ∀ n, x n = 0 := by
    by_cases hμ : μ = 0
    · intro n
      have := congrArg (fun y : lp (fun _ : ℕ => ℂ) 2 => y (n + 1)) h
      simpa [hS, hμ] using this
    · intro n
      induction n with
      | zero =>
        have := congrArg (fun y : lp (fun _ : ℕ => ℂ) 2 => y 0) h
        simp [hS0, hμ] at this
        exact this
      | succ n ih =>
        have := congrArg (fun y : lp (fun _ : ℕ => ℂ) 2 => y (n + 1)) h
        simp [hS, ih, hμ] at this
        exact this
  ext n
  simpa using key n

theorem delay_sub_single (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0)
    (hS : ∀ x n, S x (n + 1) = x n) (μ : ℂ) (n : ℕ) (c : ℂ) :
    (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S) (lp.single 2 n c) = μ • lp.single 2 n c - lp.single 2 (n + 1) c := by
  simp [delay_single S hS0 hS]

theorem delay_not_dense (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0)
    (hS : ∀ x n, S x (n + 1) = x n) (μ : ℂ) (hμ : ‖μ‖ < 1) :
    ¬ Dense (Set.range (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S)) := by
  set T := μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S with hT
  have hmem : Memℓp (fun n : ℕ => (starRingEnd ℂ μ) ^ n) 2 := by
    apply memℓp_gen
    have : (fun n : ℕ => ‖(starRingEnd ℂ μ) ^ n‖ ^ (2 : ℝ≥0∞).toReal) = fun n => (‖μ‖ ^ 2) ^ n := by
      funext n
      simp only [ENNReal.toReal_ofNat, Real.rpow_two, norm_pow, Complex.norm_conj]
      ring
    rw [this]
    exact summable_geometric_of_lt_one (sq_nonneg _) (by nlinarith [norm_nonneg μ])
  set v : lp (fun _ : ℕ => ℂ) 2 := ⟨_, hmem⟩ with hv
  have hv0 : v 0 = 1 := by simp [hv]
  have horth : v ∈ (LinearMap.range (T : lp (fun _ : ℕ => ℂ) 2 →ₗ[ℂ] lp (fun _ : ℕ => ℂ) 2))ᗮ := by
    rw [Submodule.mem_orthogonal]
    rintro u ⟨x, rfl⟩
    have hsum := (lp.hasSum_single (p := 2) (by norm_num) x).mapL ((innerSL ℂ v).comp T)
    have hzero : ∀ n, ((innerSL ℂ v).comp T) (lp.single 2 n (x n)) = 0 := by
      intro n
      simp only [ContinuousLinearMap.comp_apply, innerSL_apply_apply, hT,
        delay_sub_single S hS0 hS, inner_sub_right, inner_smul_right, lp.inner_single_right]
      simp [hv, pow_succ]
      ring
    simp only [hzero] at hsum
    have h0 := hsum.unique hasSum_zero
    simp only [ContinuousLinearMap.comp_apply, innerSL_apply_apply] at h0
    have h1 : inner ℂ (T x) v = 0 := by rw [← inner_conj_symm, h0, map_zero]
    exact h1
  intro hd
  have htop : (LinearMap.range (T : lp (fun _ : ℕ => ℂ) 2 →ₗ[ℂ] lp (fun _ : ℕ => ℂ) 2)).topologicalClosure = ⊤ :=
    (Submodule.dense_iff_topologicalClosure_eq_top).1 hd
  rw [Submodule.topologicalClosure_eq_top_iff] at htop
  rw [htop, Submodule.mem_bot] at horth
  have := congrArg (fun y : lp (fun _ : ℕ => ℂ) 2 => y 0) horth
  simp [hv0] at this

theorem delay_injective (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0)
    (hS : ∀ x n, S x (n + 1) = x n) (μ : ℂ) :
    Function.Injective (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S) := by
  intro x y hxy
  have h : (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S) (x - y) = 0 := by rw [map_sub, hxy, sub_self]
  have h2 : μ • (x - y) - S (x - y) = 0 := by simpa using h
  exact sub_eq_zero.1 (delay_eigen S hS0 hS μ (x - y) (sub_eq_zero.1 h2).symm)

theorem delay_spectrum (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0)
    (hS : ∀ x n, S x (n + 1) = x n) :
    spectrum ℂ S = Metric.closedBall (0 : ℂ) 1 := by
  apply le_antisymm
  · have : Nontrivial (lp (fun _ : ℕ => ℂ) 2) := nontrivial_of_ne (lp.single 2 0 1) 0 (by
      intro h
      have := congrArg (fun y : lp (fun _ : ℕ => ℂ) 2 => y 0) h
      simp at this)
    have hn : ‖S‖ ≤ 1 :=
      ContinuousLinearMap.opNorm_le_bound S zero_le_one
        (fun x => by rw [delay_norm S hS0 hS x, one_mul])
    exact (spectrum.subset_closedBall_norm S).trans (Metric.closedBall_subset_closedBall hn)
  · have hball : Metric.ball (0 : ℂ) 1 ⊆ spectrum ℂ S := by
      intro μ hμ
      rw [Metric.mem_ball, dist_zero_right] at hμ
      rw [spectrum.mem_iff, Algebra.algebraMap_eq_smul_one]
      intro hu
      rw [ContinuousLinearMap.isUnit_iff_bijective] at hu
      apply delay_not_dense S hS0 hS μ hμ
      rw [hu.2.range_eq]
      exact dense_univ
    rw [← closure_ball (0 : ℂ) one_ne_zero]
    exact (spectrum.isClosed S).closure_subset_iff.2 hball

theorem delay_dense (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0)
    (hS : ∀ x n, S x (n + 1) = x n) (μ : ℂ) (hμ : ‖μ‖ = 1) :
    Dense (Set.range (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S)) := by
  set T := μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S with hT
  have hd : Dense ((LinearMap.range (T : lp (fun _ : ℕ => ℂ) 2 →ₗ[ℂ] lp (fun _ : ℕ => ℂ) 2) : Submodule ℂ (lp (fun _ : ℕ => ℂ) 2)) : Set (lp (fun _ : ℕ => ℂ) 2)) := by
    rw [Submodule.dense_iff_topologicalClosure_eq_top, Submodule.topologicalClosure_eq_top_iff,
      Submodule.eq_bot_iff]
    intro w hw
    rw [Submodule.mem_orthogonal] at hw
    have hrec : ∀ n, w (n + 1) = (starRingEnd ℂ μ) * w n := by
      intro n
      have h := hw (T (lp.single 2 n 1)) ⟨_, rfl⟩
      simp only [hT, delay_sub_single S hS0 hS, inner_sub_left, inner_smul_left,
        lp.inner_single_left] at h
      simp at h
      linear_combination -h
    have hconst : ∀ n, ‖w n‖ = ‖w 0‖ := by
      intro n
      induction n with
      | zero => rfl
      | succ n ih => rw [hrec, norm_mul, Complex.norm_conj, hμ, one_mul, ih]
    have hp : 0 < (2 : ℝ≥0∞).toReal := by norm_num
    have hsum := (lp.memℓp w).summable hp
    simp only [hconst] at hsum
    rw [summable_const_iff] at hsum
    have h0 : ‖w 0‖ = 0 := by
      simp only [ENNReal.toReal_ofNat, Real.rpow_two] at hsum
      exact pow_eq_zero_iff two_ne_zero |>.1 hsum
    ext n
    have h1 : ‖w n‖ = 0 := by rw [hconst n, h0]
    simpa using h1
  exact hd

theorem delay_not_bounded_below (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) (hS0 : ∀ x, S x 0 = 0)
    (hS : ∀ x n, S x (n + 1) = x n) (μ : ℂ) (hμ : ‖μ‖ = 1) :
    ¬ ∃ C : ℝ, ∀ x : lp (fun _ : ℕ => ℂ) 2, ‖x‖ ≤ C * ‖(μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S) x‖ := by
  rintro ⟨C, hC⟩
  set T := μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S with hT
  have hspec : μ ∈ spectrum ℂ S := by
    rw [delay_spectrum S hS0 hS, Metric.mem_closedBall, dist_zero_right, hμ]
  have hK : ∀ x : lp (fun _ : ℕ => ℂ) 2, ‖x‖ ≤ (Real.toNNReal C : ℝ) * ‖T x‖ := by
    intro x
    refine (hC x).trans ?_
    exact mul_le_mul_of_nonneg_right (Real.le_coe_toNNReal C) (norm_nonneg _)
  have hanti := ContinuousLinearMap.antilipschitz_of_bound T hK
  have hclosed := hanti.isClosed_range T.uniformContinuous
  have hrange : Set.range T = Set.univ := by
    rw [← hclosed.closure_eq]
    exact (delay_dense S hS0 hS μ hμ).closure_eq
  have hbij : Function.Bijective T :=
    ⟨delay_injective S hS0 hS μ, Set.range_eq_univ.1 hrange⟩
  rw [spectrum.mem_iff, Algebra.algebraMap_eq_smul_one] at hspec
  exact hspec (ContinuousLinearMap.isUnit_iff_bijective.2 hbij)

#print axioms delay_single
#print axioms delay_norm
#print axioms delay_eigen
#print axioms delay_sub_single
#print axioms delay_not_dense
#print axioms delay_injective
#print axioms delay_spectrum
#print axioms delay_dense
#print axioms delay_not_bounded_below

/-- Every bounded operator has a nonempty, closed and bounded spectrum. Let `E` be a nonzero
complex Banach space (complete normed space) and `T` a bounded operator on it. The spectrum
`σ(T)`, the complex numbers `λ` at which `λI − T` has no bounded inverse, is nonempty and
compact (closed and bounded in the plane). -/
theorem spectrum_nonempty_and_compact
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℂ E] [CompleteSpace E] [Nontrivial E]
    (T : E →L[ℂ] E) :
    (spectrum ℂ T).Nonempty ∧ IsCompact (spectrum ℂ T) := by
  exact ⟨spectrum.nonempty T, spectrum.isCompact T⟩

/-- The delay line has no eigenvalues, yet its spectrum is the closed unit disc. Let `S` be the
bounded operator on one-sided complex signals of finite energy, `ℓ²`, that delays every sample by
one step: `(Sx)₀ = 0` and `(Sx)ₙ₊₁ = xₙ`. Then `Sx = λx` forces `x = 0` for every complex `λ`, and
the spectrum `σ(S)` is exactly the set of complex `λ` with `|λ| ≤ 1`. -/
theorem delay_line_spectrum_eq_closed_unit_disc
    (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2)
    (hS0 : ∀ x, S x 0 = 0) (hS : ∀ x n, S x (n + 1) = x n) :
    (∀ (μ : ℂ) (x : lp (fun _ : ℕ => ℂ) 2), S x = μ • x → x = 0) ∧
      spectrum ℂ S = Metric.closedBall (0 : ℂ) 1 := by
  exact ⟨delay_eigen S hS0 hS, delay_spectrum S hS0 hS⟩

/-- The delay line's spectrum splits into a residual inside and a continuous circle. For the
delay line `S` on `ℓ²`: when `|λ| < 1`, the map `λI − S` is one-to-one but its range is not dense
(residual spectrum); when `|λ| = 1`, the map `λI − S` is one-to-one with dense range, yet no
constant `C` gives `‖x‖ ≤ C ‖(λI − S)x‖` for all `x`, so it has no bounded inverse (continuous
spectrum). -/
theorem delay_line_residual_inside_continuous_on_circle
    (S : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2)
    (hS0 : ∀ x, S x 0 = 0) (hS : ∀ x n, S x (n + 1) = x n) :
    (∀ μ : ℂ, ‖μ‖ < 1 →
        Function.Injective (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S) ∧
          ¬ Dense (Set.range (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S))) ∧
    (∀ μ : ℂ, ‖μ‖ = 1 →
        Function.Injective (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S) ∧
          Dense (Set.range (μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S)) ∧
          ¬ ∃ C : ℝ, ∀ x : lp (fun _ : ℕ => ℂ) 2,
              ‖x‖ ≤ C * ‖(μ • (1 : lp (fun _ : ℕ => ℂ) 2 →L[ℂ] lp (fun _ : ℕ => ℂ) 2) - S) x‖) := by
  exact ⟨fun μ hμ => ⟨delay_injective S hS0 hS μ, delay_not_dense S hS0 hS μ hμ⟩,
    fun μ hμ => ⟨delay_injective S hS0 hS μ, delay_dense S hS0 hS μ hμ,
      delay_not_bounded_below S hS0 hS μ hμ⟩⟩

/-- Inside the disc, at λ = 1/2, solving (λI − S)x = e₀ sample by sample gives
xₙ = 2 (yₙ + xₙ₋₁): the echo 2, 4, 8, 16, 32, doubling. -/
example : List.scanl (fun x y => 2 * (y + x)) 0 [1, 0, 0, 0, 0] = [0, 2, 4, 8, 16, 32] := by
  decide

/-- On the circle, at λ = 1, the same recursion xₙ = yₙ + xₙ₋₁ gives the echo 1, 1, 1, 1, 1:
it never decays. -/
example : List.scanl (fun x y => y + x) 0 [1, 0, 0, 0, 0] = [0, 1, 1, 1, 1, 1] := by
  decide

/-- The obstruction at λ = 1/2: for x = (3, −1, 4, 1, −5), the output (λI − S)x is
(3/2, −7/2, 3, −7/2, −7/2, 5), and its inner product with v = (1, 1/2, 1/4, …) is 0. -/
example :
    ((1 : ℚ) / 2 * 3 - 0 = 3 / 2) ∧ ((1 : ℚ) / 2 * (-1) - 3 = -7 / 2) ∧
    ((1 : ℚ) / 2 * 4 - (-1) = 3) ∧ ((1 : ℚ) / 2 * 1 - 4 = -7 / 2) ∧
    ((1 : ℚ) / 2 * (-5) - 1 = -7 / 2) ∧ ((1 : ℚ) / 2 * 0 - (-5) = 5) ∧
    (1 * (3 / 2 : ℚ) + 1 / 2 * (-7 / 2) + 1 / 4 * 3 + 1 / 8 * (-7 / 2) + 1 / 16 * (-7 / 2)
      + 1 / 32 * 5 = 0) := by
  norm_num

/-- On the circle, at λ = 1, the block of M = 5 ones (energy 5) is sent by I − S to
e₀ − e₅ = (1, 0, 0, 0, 0, −1), of energy 2. -/
example :
    List.zipWith (· - ·) [1, 1, 1, 1, 1, 0] [0, 1, 1, 1, 1, 1] = ([1, 0, 0, 0, 0, -1] : List ℤ) ∧
    ([1, 1, 1, 1, 1].map (· ^ 2)).sum = (5 : ℤ) ∧
    ([1, 0, 0, 0, 0, -1].map (· ^ 2)).sum = (2 : ℤ) := by
  decide

/-- The truncation lies: the delay cut to 8 samples sends e₇ to 0, so 0 is its eigenvalue, and
eight cut delays push every sample of (1, …, 1) off the end. -/
example : (0 :: [0, 0, 0, 0, 0, 0, 0, 1]).dropLast = [0, 0, 0, 0, 0, 0, 0, 0] ∧
    (fun l : List ℕ => (0 :: l).dropLast)^[8] [1, 1, 1, 1, 1, 1, 1, 1] =
      [0, 0, 0, 0, 0, 0, 0, 0] := by
  decide

/-- What breaks over real scalars: the quarter turn A = [[0, −1], [1, 0]] has
det(λI − A) = λ² + 1, which is at least 1 for every real λ. -/
example (l : ℝ) : Matrix.det (!![l, 1; -1, l]) = l ^ 2 + 1 ∧ 1 ≤ l ^ 2 + 1 := by
  constructor
  · rw [Matrix.det_fin_two_of]; ring
  · nlinarith [sq_nonneg l]

/-- Over complex scalars the quarter turn's spectrum is i and −i: det(λI − A) = 0 there. -/
example : Matrix.det (!![Complex.I, 1; -1, Complex.I]) = 0 ∧
    Matrix.det (!![-Complex.I, 1; -1, -Complex.I]) = 0 := by
  rw [Matrix.det_fin_two_of, Matrix.det_fin_two_of]
  constructor <;> ring_nf <;> simp [Complex.I_sq]

#print axioms spectrum_nonempty_and_compact
#print axioms delay_line_spectrum_eq_closed_unit_disc
#print axioms delay_line_residual_inside_continuous_on_circle
