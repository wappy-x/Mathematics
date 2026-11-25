-- Morse theory: in the cell recipe a Morse function gives (c_k cells of dimension k, boundary maps over the rationals) every Betti number is at most the count c_k, the alternating partial sums obey the strong Morse inequalities, the full alternating count equals the alternating Betti sum (the Euler characteristic), and the index of a Hessian does not change with the chart.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.FiniteDimensional.Defs
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

/-! Mathlib has no Morse functions, no Morse lemma and no handle attachment, so the card's
geometric steps (Steps 0, 2, 3, 4, 6 and 7) are not stated here. This file states the parts the
card proves that can be stated exactly:

* Step 5, the Morse inequalities, from the cell recipe of Steps 3 and 4. Passing the critical
  levels builds `M`, up to deformation, from `c_k` cells of dimension `k`. Cellular homology over
  the rationals turns that recipe into a chain complex: a space `C k` of dimension `c_k` in each
  dimension `k`, and boundary maps `∂ k : C (k + 1) → C k` with `∂ ∘ ∂ = 0`. The Betti number `b_k`
  is the dimension of cycles modulo boundaries.
* Step 1, the index belongs to the point: at a critical point a change of chart with invertible
  Jacobian `J` sends the Hessian `H` to `Jᵀ H J`, and that has as many negative eigenvalues as `H`.

The examples check the card's whole-number worked numbers. -/

namespace MorseTheory

open Module

theorem alt_sum_rev_telescope (x r : ℕ → ℤ) (h0 : x 0 = r 0)
    (hs : ∀ k, x (k + 1) = r (k + 1) + r k) (k : ℕ) :
    ∑ i ∈ Finset.range (k + 1), (-1 : ℤ) ^ (k - i) * x i = r k := by
  induction k with
  | zero => simp [h0]
  | succ k ih =>
    rw [Finset.sum_range_succ, Nat.sub_self, pow_zero, one_mul, hs]
    have : ∑ i ∈ Finset.range (k + 1), (-1 : ℤ) ^ (k + 1 - i) * x i =
        -∑ i ∈ Finset.range (k + 1), (-1 : ℤ) ^ (k - i) * x i := by
      rw [← Finset.sum_neg_distrib]
      refine Finset.sum_congr rfl fun i hi => ?_
      have hik : i ≤ k := Nat.lt_succ_iff.mp (Finset.mem_range.mp hi)
      rw [show k + 1 - i = (k - i) + 1 by omega, pow_succ]
      ring
    rw [this, ih]
    ring

theorem alt_sum_telescope (x r : ℕ → ℤ) (h0 : x 0 = r 0)
    (hs : ∀ k, x (k + 1) = r (k + 1) + r k) (k : ℕ) :
    ∑ i ∈ Finset.range (k + 1), (-1 : ℤ) ^ i * x i = (-1 : ℤ) ^ k * r k := by
  induction k with
  | zero => simp [h0]
  | succ k ih =>
    rw [Finset.sum_range_succ, ih, hs]
    ring

open Matrix in
/-- Sylvester for diagonal real matrices: if `diagonal d = Mᴴ * diagonal d' * M` then `d` has at
most as many negative entries as `d'`. -/
theorem card_neg_le_of_diagonal_eq {ι : Type*} [Fintype ι] [DecidableEq ι] (d d' : ι → ℝ)
    (M : Matrix ι ι ℝ) (hM : Matrix.diagonal d = Mᴴ * Matrix.diagonal d' * M) :
    (Finset.univ.filter fun i => d i < 0).card ≤ (Finset.univ.filter fun i => d' i < 0).card := by
  classical
  let ext : ({i // d i < 0} → ℝ) →ₗ[ℝ] (ι → ℝ) :=
    { toFun := fun c i => if h : d i < 0 then c ⟨i, h⟩ else 0
      map_add' := fun c c' => by
        funext i; by_cases h : d i < 0 <;> simp [h]
      map_smul' := fun a c => by
        funext i; by_cases h : d i < 0 <;> simp [h] }
  let φ : ({i // d i < 0} → ℝ) →ₗ[ℝ] ({j // d' j < 0} → ℝ) :=
    LinearMap.funLeft ℝ ℝ Subtype.val ∘ₗ Matrix.toLin' M ∘ₗ ext
  have hinj : Function.Injective φ := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro c hc
    set x := ext c with hx
    set y := M *ᵥ x with hy
    have hy0 : ∀ j, d' j < 0 → y j = 0 := fun j hj => congr_fun hc ⟨j, hj⟩
    have hQ : x ⬝ᵥ (Matrix.diagonal d *ᵥ x) = y ⬝ᵥ (Matrix.diagonal d' *ᵥ y) := by
      rw [hM, hy, ← Matrix.mulVec_mulVec, ← Matrix.mulVec_mulVec, Matrix.dotProduct_mulVec,
        Matrix.dotProduct_mulVec, Matrix.vecMul_conjTranspose, star_trivial, star_trivial,
        Matrix.dotProduct_mulVec (M *ᵥ x) (diagonal d')]
    have hxi : ∀ i, x i = if h : d i < 0 then c ⟨i, h⟩ else 0 := fun i => rfl
    have hle : ∀ i ∈ Finset.univ, x i * (d i * x i) ≤ 0 := by
      intro i _
      rw [hxi i]
      split_ifs with h
      · nlinarith [mul_self_nonneg (c ⟨i, h⟩)]
      · simp
    have hge : ∀ j ∈ Finset.univ, 0 ≤ y j * (d' j * y j) := by
      intro j _
      by_cases h : d' j < 0
      · simp [hy0 j h]
      · nlinarith [mul_self_nonneg (y j), not_lt.mp h]
    simp only [dotProduct, mulVec_diagonal] at hQ
    have hsum : ∑ i, x i * (d i * x i) = 0 :=
      le_antisymm (Finset.sum_nonpos hle) (hQ ▸ Finset.sum_nonneg hge)
    have hzero := (Finset.sum_eq_zero_iff_of_nonpos hle).mp hsum
    funext ⟨i, hi⟩
    have h1 := hzero i (Finset.mem_univ i)
    simp only [hxi i, hi, ↓reduceDIte] at h1
    have h2 : c ⟨i, hi⟩ * c ⟨i, hi⟩ = 0 := by
      have : d i * (c ⟨i, hi⟩ * c ⟨i, hi⟩) = 0 := by linarith
      exact (mul_eq_zero.mp this).resolve_left hi.ne
    simpa using mul_self_eq_zero.mp h2
  have := LinearMap.finrank_le_finrank_of_injective hinj
  simpa [Module.finrank_fintype_fun_eq_card, Fintype.card_subtype] using this

open Matrix in
/-- Sylvester for Hermitian real matrices: if `A = Mᴴ * A' * M` then `A` has at most as many
negative eigenvalues as `A'`. -/
theorem card_neg_eigenvalues_le {ι : Type*} [Fintype ι] [DecidableEq ι] {A A' : Matrix ι ι ℝ}
    (hA : A.IsHermitian) (hA' : A'.IsHermitian) (M : Matrix ι ι ℝ) (h : A = Mᴴ * A' * M) :
    (Finset.univ.filter fun i => hA.eigenvalues i < 0).card ≤
      (Finset.univ.filter fun i => hA'.eigenvalues i < 0).card := by
  have hD := hA.conjStarAlgAut_star_eigenvectorUnitary
  have hD' := hA'.spectral_theorem
  rw [Unitary.conjStarAlgAut_star_apply] at hD
  rw [Unitary.conjStarAlgAut_apply] at hD'
  simp only [RCLike.ofReal_real_eq_id, Function.id_comp] at hD hD'
  set U : Matrix ι ι ℝ := (hA.eigenvectorUnitary : Matrix ι ι ℝ) with hUdef
  set V : Matrix ι ι ℝ := (hA'.eigenvectorUnitary : Matrix ι ι ℝ) with hVdef
  have hUA : star U * A * U = star U * (Mᴴ * A' * M) * U := congrArg (fun X => star U * X * U) h
  apply card_neg_le_of_diagonal_eq _ _ (star V * M * U)
  rw [← hD, hUA, congrArg (fun X => star U * (Mᴴ * X * M) * U) hD']
  simp only [Matrix.star_eq_conjTranspose, Matrix.conjTranspose_mul,
    Matrix.conjTranspose_conjTranspose, Matrix.mul_assoc]

variable {C : ℕ → Type*} [∀ k, AddCommGroup (C k)] [∀ k, Module ℚ (C k)]
  [∀ k, FiniteDimensional ℚ (C k)]

/-- The `k`-cycles of the chain complex: `k`-chains whose boundary is zero. Every 0-chain is a
cycle, since nothing lies below dimension 0. -/
def cycles (d : ∀ k, C (k + 1) →ₗ[ℚ] C k) : (k : ℕ) → Submodule ℚ (C k)
  | 0 => ⊤
  | k + 1 => LinearMap.ker (d k)

/-- The `k`-th Betti number of the chain complex over the rationals: the dimension of the
homology, `k`-cycles modulo `k`-boundaries (the image of `∂ k` from the `(k + 1)`-chains). -/
noncomputable def betti (d : ∀ k, C (k + 1) →ₗ[ℚ] C k) (k : ℕ) : ℕ :=
  finrank ℚ ((cycles d k) ⧸ (LinearMap.range (d k)).comap (cycles d k).subtype)

omit [∀ k, FiniteDimensional ℚ (C k)] in
theorem range_le_cycles (d : ∀ k, C (k + 1) →ₗ[ℚ] C k)
    (hdd : ∀ k, (d k).comp (d (k + 1)) = 0) (k : ℕ) :
    LinearMap.range (d k) ≤ cycles d k := by
  cases k with
  | zero => exact le_top
  | succ k => exact LinearMap.range_le_ker_iff.mpr (hdd k)

theorem betti_add_finrank_range (d : ∀ k, C (k + 1) →ₗ[ℚ] C k)
    (hdd : ∀ k, (d k).comp (d (k + 1)) = 0) (k : ℕ) :
    betti d k + finrank ℚ (LinearMap.range (d k)) = finrank ℚ (cycles d k) := by
  rw [betti, ← (Submodule.comapSubtypeEquivOfLe (range_le_cycles d hdd k)).finrank_eq]
  exact Submodule.finrank_quotient_add_finrank _

omit [∀ k, FiniteDimensional ℚ (C k)] in
theorem finrank_zero_eq_cycles (d : ∀ k, C (k + 1) →ₗ[ℚ] C k) :
    finrank ℚ (C 0) = finrank ℚ (cycles d 0) := by
  show finrank ℚ (C 0) = finrank ℚ (⊤ : Submodule ℚ (C 0))
  rw [finrank_top]

theorem finrank_succ_eq (d : ∀ k, C (k + 1) →ₗ[ℚ] C k) (k : ℕ) :
    finrank ℚ (C (k + 1)) = finrank ℚ (LinearMap.range (d k)) + finrank ℚ (cycles d (k + 1)) :=
  (LinearMap.finrank_range_add_finrank_ker (d k)).symm

/-- **The Morse inequalities, weak form and Euler sum.** Take the cell recipe of a Morse function
on a closed `n`-dimensional manifold: over the rationals, a chain space `C k` whose dimension
`c_k` is the number of critical points of index `k`, with no cells above dimension `n`, and
boundary maps with `∂ ∘ ∂ = 0`. Then every Betti number is at most the count of critical points
of that index, `b_k ≤ c_k`, and the alternating count of critical points equals the alternating
sum of Betti numbers, the Euler characteristic: `c_0 − c_1 + ⋯ ± c_n = b_0 − b_1 + ⋯ ± b_n`. -/
theorem morse_inequalities_weak_and_euler (n : ℕ) (d : ∀ k, C (k + 1) →ₗ[ℚ] C k)
    (hdd : ∀ k, (d k).comp (d (k + 1)) = 0) (htop : ∀ k, n < k → finrank ℚ (C k) = 0) :
    (∀ k, betti d k ≤ finrank ℚ (C k)) ∧
      ∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ k * (finrank ℚ (C k) : ℤ) =
        ∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ k * (betti d k : ℤ) := by
  refine ⟨fun k => ?_, ?_⟩
  · exact (Submodule.finrank_quotient_le _).trans (Submodule.finrank_le _)
  · have key := alt_sum_telescope (fun k => (finrank ℚ (C k) : ℤ) - betti d k)
      (fun k => (finrank ℚ (LinearMap.range (d k)) : ℤ)) ?_ ?_ n
    · have hr : finrank ℚ (LinearMap.range (d n)) = 0 :=
        Nat.eq_zero_of_le_zero ((LinearMap.finrank_range_le (d n)).trans
          (htop (n + 1) (Nat.lt_succ_self n)).le)
      simp only [hr, Nat.cast_zero, mul_zero, mul_sub, Finset.sum_sub_distrib] at key
      linarith
    · have h1 := betti_add_finrank_range d hdd 0
      have h2 := finrank_zero_eq_cycles d
      omega
    · intro k
      have h1 := betti_add_finrank_range d hdd (k + 1)
      have h2 := finrank_succ_eq d k
      omega

/-- **The strong Morse inequalities.** For the same cell recipe (chain spaces of dimension `c_k`
over the rationals, boundary maps with `∂ ∘ ∂ = 0`), every alternating partial sum of the counts
is at least the matching alternating partial sum of the Betti numbers:
`c_k − c_{k−1} + ⋯ ± c_0 ≥ b_k − b_{k−1} + ⋯ ± b_0` for every `k`. -/
theorem strong_morse_inequalities (d : ∀ k, C (k + 1) →ₗ[ℚ] C k)
    (hdd : ∀ k, (d k).comp (d (k + 1)) = 0) (k : ℕ) :
    ∑ i ∈ Finset.range (k + 1), (-1 : ℤ) ^ (k - i) * (betti d i : ℤ) ≤
      ∑ i ∈ Finset.range (k + 1), (-1 : ℤ) ^ (k - i) * (finrank ℚ (C i) : ℤ) := by
  have key := alt_sum_rev_telescope (fun k => (finrank ℚ (C k) : ℤ) - betti d k)
    (fun k => (finrank ℚ (LinearMap.range (d k)) : ℤ)) ?_ ?_ k
  · simp only [mul_sub, Finset.sum_sub_distrib] at key
    have : (0 : ℤ) ≤ (finrank ℚ (LinearMap.range (d k)) : ℤ) := Nat.cast_nonneg _
    linarith
  · have h1 := betti_add_finrank_range d hdd 0
    have h2 := finrank_zero_eq_cycles d
    omega
  · intro k
    have h1 := betti_add_finrank_range d hdd (k + 1)
    have h2 := finrank_succ_eq d k
    omega

/-- **The index belongs to the point, not the chart (Sylvester's law of inertia).** At a critical
point, a change of chart with invertible Jacobian matrix `J` sends the Hessian `H` (a real
symmetric matrix) to `Jᵀ H J`. Here `Jᴴ`, the conjugate transpose, is the transpose `Jᵀ` because
the entries are real. The new matrix has exactly as many negative eigenvalues as `H`, so the
index is the same in both charts. -/
theorem morse_index_independent_of_chart {ι : Type*} [Fintype ι] [DecidableEq ι]
    (H : Matrix ι ι ℝ) (hH : H.IsHermitian) (J : Matrix ι ι ℝ) (hJ : IsUnit J.det) :
    (Finset.univ.filter fun i => (Matrix.isHermitian_conjTranspose_mul_mul J hH).eigenvalues i < 0).card =
      (Finset.univ.filter fun i => hH.eigenvalues i < 0).card := by
  apply le_antisymm
  · exact card_neg_eigenvalues_le _ hH J rfl
  · refine card_neg_eigenvalues_le hH _ J⁻¹ ?_
    rw [Matrix.conjTranspose_nonsing_inv, ← Matrix.mul_assoc, ← Matrix.mul_assoc,
      Matrix.nonsing_inv_mul _ (by rw [Matrix.det_conjTranspose, star_trivial]; exact hJ), Matrix.one_mul,
      Matrix.mul_assoc, Matrix.mul_nonsing_inv _ hJ, Matrix.mul_one]

/-! ### The card's worked numbers -/

-- The toy planet: 3 pits, 4 passes, 3 peaks, and 3 - 4 + 3 = 2, the sphere's Euler characteristic.
example : (3 : ℤ) - 4 + 3 = 2 := by norm_num
-- The swim ring: counts by index (1, 2, 1), 1 - 2 + 1 = 0, the torus's Euler characteristic.
example : (1 : ℤ) - 2 + 1 = 0 := by norm_num
-- Ring heights h = 30 + (a + b cos v) cos u with a = 20, b = 10 and cos u, cos v = ±1:
-- 0, 20, 40 and 60 cm at the pit, the two passes and the peak.
example : (30 : ℤ) + (20 + 10 * 1) * (-1) = 0 ∧ (30 : ℤ) + (20 + 10 * (-1)) * (-1) = 20 ∧
    (30 : ℤ) + (20 + 10 * (-1)) * 1 = 40 ∧ (30 : ℤ) + (20 + 10 * 1) * 1 = 60 := by norm_num
-- Hessian diagonals H_uu = -(a + b cos v) cos u and H_vv = -b cos v cos u at the four points:
-- (30, 10), (10, -10), (-10, 10), (-30, -10).
example : -((20 : ℤ) + 10 * 1) * (-1) = 30 ∧ -(10 : ℤ) * 1 * (-1) = 10 ∧
    -((20 : ℤ) + 10 * (-1)) * (-1) = 10 ∧ -(10 : ℤ) * (-1) * (-1) = -10 ∧
    -((20 : ℤ) + 10 * (-1)) * 1 = -10 ∧ -(10 : ℤ) * (-1) * 1 = 10 ∧
    -((20 : ℤ) + 10 * 1) * 1 = -30 ∧ -(10 : ℤ) * 1 * 1 = -10 := by norm_num
-- Step 1 at the bottom of the ring: J = [[1, 2/5], [0, 1]] sends diag(30, 10) to
-- [[30, 12], [12, 74/5]]; its determinant is 300 > 0 and its corner 30 > 0, so both
-- eigenvalues stay positive and the index stays 0.
example : (!![1, 0; 2 / 5, 1] : Matrix (Fin 2) (Fin 2) ℚ) * !![30, 0; 0, 10] * !![1, 2 / 5; 0, 1] =
    !![30, 12; 12, 74 / 5] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : (30 : ℚ) * (74 / 5) - 12 * 12 = 300 := by norm_num
-- The ring's 9-vertex, 27-edge, 18-triangle mesh: Euler count 9 - 27 + 18 = 0, and with boundary
-- ranks 8 and 17, b_k = c_k - r_k - r_(k+1) gives Betti numbers 9 - 8 = 1, 27 - 8 - 17 = 2, 18 - 17 = 1.
example : (9 : ℤ) - 27 + 18 = 0 ∧ (9 : ℤ) - 8 = 1 ∧ (27 : ℤ) - 8 - 17 = 2 ∧ (18 : ℤ) - 17 = 1 := by
  norm_num
-- Ring: weak c = (1, 2, 1) ≥ b = (1, 2, 1); strong c1 - c0 = 1 ≥ b1 - b0 = 1.
example : (1 : ℤ) ≥ 1 ∧ (2 : ℤ) ≥ 2 ∧ (1 : ℤ) ≥ 1 ∧ (2 : ℤ) - 1 ≥ 2 - 1 := by norm_num
-- Sublevel Euler counts at 10, 30, 50, 70 cm: each k-cell adds (-1)^k, giving 1, 0, -1, 0.
example : (1 : ℤ) = 1 ∧ (1 : ℤ) - 1 = 0 ∧ (1 : ℤ) - 1 - 1 = -1 ∧ (1 : ℤ) - 1 - 1 + 1 = 0 := by norm_num
-- Toy planet against the sphere's Betti numbers (1, 0, 1): weak 3 ≥ 1, 4 ≥ 0, 3 ≥ 1;
-- strong 4 - 3 = 1 ≥ 0 - 1 = -1; full sum 3 - 4 + 3 = 1 - 0 + 1.
example : (3 : ℤ) ≥ 1 ∧ (4 : ℤ) ≥ 0 ∧ (3 : ℤ) ≥ 1 ∧ (4 : ℤ) - 3 ≥ 0 - 1 ∧
    (3 : ℤ) - 4 + 3 = 1 - 0 + 1 := by norm_num
-- What breaks: the planet with no nudge gives 3 pits, 0 passes, 3 peaks, sum 6, not 2;
-- counting without signs gives 4 on the ring (χ = 0) and 10 on the planet (χ = 2).
example : (3 : ℤ) - 0 + 3 = 6 ∧ 1 + 2 + 1 = 4 ∧ 3 + 4 + 3 = 10 := by norm_num

#print axioms alt_sum_rev_telescope
#print axioms alt_sum_telescope
#print axioms card_neg_le_of_diagonal_eq
#print axioms card_neg_eigenvalues_le
#print axioms range_le_cycles
#print axioms betti_add_finrank_range
#print axioms finrank_zero_eq_cycles
#print axioms finrank_succ_eq
#print axioms morse_inequalities_weak_and_euler
#print axioms strong_morse_inequalities
#print axioms morse_index_independent_of_chart

end MorseTheory
