-- The four fundamental subspaces: for every matrix of real numbers, the row space is perpendicular to the null space, the column space is perpendicular to the left null space, A x = b has a solution exactly when b passes every check y with A^T y = 0, and the four sizes are r, n - r, r and m - r, with the card's bakery checked exactly.
import Mathlib

open Matrix

/-! A matrix with `m` rows and `n` columns of real numbers is `A : Matrix (Fin m) (Fin n) ℝ`.
An input is `x : Fin n → ℝ` and `A *ᵥ x` is the output. `Aᵀ` is `A` with rows and columns
swapped, and `u ⬝ᵥ v` is the dot product. A mix of the rows is `Aᵀ *ᵥ c` for weights `c`,
so the row space is every such vector; the null space is every `x` with `A *ᵥ x = 0`. A mix of
the columns is `A *ᵥ x`; the left null space, the checks, is every `y` with `Aᵀ *ᵥ y = 0`. -/

/-- Helper for Steps 1 and 4: least squares always has a best choice. Some `x` solves the normal
equations `Aᵀ A x = Aᵀ b`, because `Aᵀ A` reaches as much as `Aᵀ` does: same rank. -/
theorem ffs_normal_equations_solvable {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (b : Fin m → ℝ) : ∃ x, (Aᵀ * A) *ᵥ x = Aᵀ *ᵥ b := by
  have hle : LinearMap.range (Aᵀ * A).mulVecLin ≤ LinearMap.range Aᵀ.mulVecLin := by
    rw [Matrix.mulVecLin_mul]
    exact LinearMap.range_comp_le_range _ _
  have hrank : Module.finrank ℝ (LinearMap.range (Aᵀ * A).mulVecLin) =
      Module.finrank ℝ (LinearMap.range Aᵀ.mulVecLin) := by
    have h1 := Matrix.rank_transpose_mul_self A
    have h2 := Matrix.rank_transpose A
    unfold Matrix.rank at h1 h2
    rw [h1, h2]
  have heq := Submodule.eq_of_le_of_finrank_eq hle hrank
  have hmem : Aᵀ *ᵥ b ∈ LinearMap.range (Aᵀ * A).mulVecLin := by
    rw [heq]
    exact ⟨b, rfl⟩
  obtain ⟨x, hx⟩ := hmem
  exact ⟨x, hx⟩

/-- Step 0: the matrix kills an input exactly when the input is perpendicular to every row. -/
theorem ffs_null_iff_perp_rows {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (x : Fin n → ℝ) :
    A *ᵥ x = 0 ↔ ∀ i, A i ⬝ᵥ x = 0 := by
  constructor
  · intro h i
    exact congrFun h i
  · intro h
    funext i
    exact h i

/-- Step 1: every mix of the rows is perpendicular to every input the matrix kills. -/
theorem ffs_row_space_perp_null_space {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (c : Fin m → ℝ) (x : Fin n → ℝ) (hx : A *ᵥ x = 0) :
    (Aᵀ *ᵥ c) ⬝ᵥ x = 0 := by
  rw [mulVec_transpose, ← dotProduct_mulVec, hx, dotProduct_zero]

/-- Step 1: every input splits into a row part, a mix of the rows, plus a part the matrix kills.
The row part comes from the normal equations of `Aᵀ`, as a projection onto the row space. -/
theorem ffs_split_row_plus_null {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (x : Fin n → ℝ) :
    ∃ c z, A *ᵥ z = 0 ∧ x = Aᵀ *ᵥ c + z := by
  obtain ⟨c, hc⟩ := ffs_normal_equations_solvable Aᵀ x
  rw [transpose_transpose] at hc
  refine ⟨c, x - Aᵀ *ᵥ c, ?_, by abel⟩
  rw [mulVec_sub, mulVec_mulVec, hc, sub_self]

/-- Step 1: two row parts with the same total are equal: the matrix is one for one on its row
space, because their difference lies in both spaces and is perpendicular to itself. -/
theorem ffs_row_space_one_for_one {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (c d : Fin m → ℝ)
    (h : A *ᵥ (Aᵀ *ᵥ c) = A *ᵥ (Aᵀ *ᵥ d)) : Aᵀ *ᵥ c = Aᵀ *ᵥ d := by
  have hz : A *ᵥ (Aᵀ *ᵥ (c - d)) = 0 := by
    rw [mulVec_sub, mulVec_sub, h, sub_self]
  have h0 := ffs_row_space_perp_null_space A (c - d) _ hz
  rw [← sub_eq_zero, ← mulVec_sub]
  exact dotProduct_self_eq_zero.mp h0

/-- Step 2: every output the matrix reaches is perpendicular to every check. -/
theorem ffs_column_space_perp_left_null_space {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (x : Fin n → ℝ) (y : Fin m → ℝ) (hy : Aᵀ *ᵥ y = 0) :
    (A *ᵥ x) ⬝ᵥ y = 0 := by
  rw [dotProduct_comm, dotProduct_mulVec, ← mulVec_transpose, hy, zero_dotProduct]

/-- Step 3: a reachable output passes every check. -/
theorem ffs_reachable_passes_every_check {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (x : Fin n → ℝ) (b y : Fin m → ℝ) (hb : A *ᵥ x = b) (hy : Aᵀ *ᵥ y = 0) :
    y ⬝ᵥ b = 0 := by
  rw [← hb, dotProduct_comm]
  exact ffs_column_space_perp_left_null_space A x y hy

/-- Step 4: an output that passes every check is reachable. The leftover `e = b - A x` of a
least-squares choice is itself a check; `b` passes it, `A x` passes it, so `e ⬝ᵥ e = 0`. -/
theorem ffs_passes_every_check_reachable {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (b : Fin m → ℝ) (h : ∀ y, Aᵀ *ᵥ y = 0 → y ⬝ᵥ b = 0) : ∃ x, A *ᵥ x = b := by
  obtain ⟨x, hx⟩ := ffs_normal_equations_solvable A b
  have he : Aᵀ *ᵥ (b - A *ᵥ x) = 0 := by
    rw [mulVec_sub, mulVec_mulVec, hx, sub_self]
  have h1 : (b - A *ᵥ x) ⬝ᵥ b = 0 := h _ he
  have h2 : (b - A *ᵥ x) ⬝ᵥ (A *ᵥ x) = 0 := by
    rw [dotProduct_comm]
    exact ffs_column_space_perp_left_null_space A x _ he
  have h3 : (b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x) = 0 := by
    rw [dotProduct_sub, h1, h2, sub_self]
  exact ⟨x, (sub_eq_zero.mp (dotProduct_self_eq_zero.mp h3)).symm⟩

/-- The solvability test, both halves: `A x = b` has a solution exactly when `b` passes every
check in the left null space. -/
theorem ffs_solvable_iff_passes_every_check {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (b : Fin m → ℝ) : (∃ x, A *ᵥ x = b) ↔ ∀ y, Aᵀ *ᵥ y = 0 → y ⬝ᵥ b = 0 := by
  constructor
  · rintro ⟨x, hx⟩ y hy
    exact ffs_reachable_passes_every_check A x b y hx hy
  · exact ffs_passes_every_check_reachable A b

/-- Step 4 run on `Aᵀ`: the row space is everything perpendicular to the null space. -/
theorem ffs_row_space_iff_perp_null_space {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (v : Fin n → ℝ) : (∃ c, Aᵀ *ᵥ c = v) ↔ ∀ z, A *ᵥ z = 0 → z ⬝ᵥ v = 0 := by
  have h := ffs_solvable_iff_passes_every_check Aᵀ v
  rwa [transpose_transpose] at h

/-- The row space and the column space have the same size: `A` and `Aᵀ` share one rank. -/
theorem ffs_rank_transpose {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) : Aᵀ.rank = A.rank :=
  Matrix.rank_transpose A

/-- Every linear functional on `Fin m → ℝ` is a dot product. -/
theorem dual_apply_eq_dotProduct {m : ℕ} (φ : Module.Dual ℝ (Fin m → ℝ)) (b : Fin m → ℝ) :
    φ b = (fun i => φ (Pi.single i 1)) ⬝ᵥ b := by
  rw [LinearMap.pi_apply_eq_sum_univ φ b, dotProduct]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [smul_eq_mul, mul_comm]
  congr 2
  ext j
  simp [Pi.single_apply, eq_comm]

/-- The main claim: for every matrix of real numbers, every vector in the row space is at right
angles to every vector in the null space, and every vector in the column space is at right angles
to every vector in the left null space. -/
theorem row_space_perp_null_space_and_column_space_perp_left_null_space {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) :
    (∀ v ∈ LinearMap.range Aᵀ.mulVecLin, ∀ x ∈ LinearMap.ker A.mulVecLin, v ⬝ᵥ x = 0) ∧
    (∀ w ∈ LinearMap.range A.mulVecLin, ∀ y ∈ LinearMap.ker Aᵀ.mulVecLin, w ⬝ᵥ y = 0) := by
  constructor
  · rintro v ⟨y, rfl⟩ x hx
    rw [LinearMap.mem_ker, mulVecLin_apply] at hx
    rw [mulVecLin_apply, mulVec_transpose, ← dotProduct_mulVec, hx, dotProduct_zero]
  · rintro w ⟨x, rfl⟩ y hy
    rw [LinearMap.mem_ker, mulVecLin_apply] at hy
    rw [mulVecLin_apply, dotProduct_comm, dotProduct_mulVec, ← mulVec_transpose, hy,
      zero_dotProduct]

/-- The solvability test: `A x = b` has a real solution exactly when `y ⬝ᵥ b = 0` for every
check `y` with `Aᵀ y = 0`. -/
theorem solvable_iff_passes_every_left_null_check {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (b : Fin m → ℝ) :
    (∃ x, A *ᵥ x = b) ↔ ∀ y, Aᵀ *ᵥ y = 0 → y ⬝ᵥ b = 0 := by
  constructor
  · rintro ⟨x, rfl⟩ y hy
    rw [dotProduct_mulVec, ← mulVec_transpose, hy, zero_dotProduct]
  · intro h
    have hb : b ∈ LinearMap.range A.mulVecLin := by
      rw [← Subspace.forall_mem_dualAnnihilator_apply_eq_zero_iff]
      intro φ hφ
      rw [Submodule.mem_dualAnnihilator] at hφ
      rw [dual_apply_eq_dotProduct]
      apply h
      ext j
      rw [mulVec_transpose, Pi.zero_apply, ← mul_one ((_ ᵥ* A) j), ← dotProduct_single,
        ← dotProduct_mulVec, ← dual_apply_eq_dotProduct]
      exact hφ _ ⟨Pi.single j 1, rfl⟩
    obtain ⟨x, hx⟩ := hb
    exact ⟨x, hx⟩

/-- The sizes: with rank `r`, the row space and column space both have size `r`, the null space
has size `n - r`, and the left null space has size `m - r`. -/
theorem four_subspace_sizes {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    Module.finrank ℝ (LinearMap.range Aᵀ.mulVecLin) = A.rank ∧
    Module.finrank ℝ (LinearMap.range A.mulVecLin) = A.rank ∧
    Module.finrank ℝ (LinearMap.ker A.mulVecLin) = n - A.rank ∧
    Module.finrank ℝ (LinearMap.ker Aᵀ.mulVecLin) = m - A.rank := by
  have h1 : Module.finrank ℝ (LinearMap.range Aᵀ.mulVecLin) = A.rank := rank_transpose A
  have h2 : Module.finrank ℝ (LinearMap.range A.mulVecLin) = A.rank := rfl
  have h3 := LinearMap.finrank_range_add_finrank_ker A.mulVecLin
  have h4 := LinearMap.finrank_range_add_finrank_ker Aᵀ.mulVecLin
  simp only [Module.finrank_fin_fun] at h3 h4
  refine ⟨h1, h2, ?_, ?_⟩ <;> omega

/-- The bakery: two checks are enough. Every check for `[[1, 2], [2, 4], [3, 6]]` is a mix
of (-2, 1, 0) and (-3, 0, 1). -/
theorem ffs_bakery_two_checks (y : Fin 3 → ℝ)
    (hy : (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℝ)ᵀ *ᵥ y = 0) :
    y = y 1 • ![-2, 1, 0] + y 2 • ![-3, 0, 1] := by
  have h0 := congrFun hy 0
  simp [mulVec, dotProduct, Fin.sum_univ_succ] at h0
  funext i
  fin_cases i
  · simp; linarith
  · simp
  · simp

/-- The bakery: no real-number order makes the report (1, 0, 0). -/
theorem ffs_bakery_report_impossible :
    ¬ ∃ x, (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℝ) *ᵥ x = ![1, 0, 0] := by
  rintro ⟨x, hx⟩
  have hy : (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℝ)ᵀ *ᵥ ![-2, 1, 0] = 0 := by
    funext i; fin_cases i <;> norm_num [mulVec, dotProduct, Fin.sum_univ_succ]
  have h := ffs_reachable_passes_every_check _ x _ _ hx hy
  norm_num [dotProduct, Fin.sum_univ_succ] at h

-- The bakery A = [[1, 2], [2, 4], [3, 6]] kills (-2, 1), and A^T kills the checks (-2, 1, 0) and (-3, 0, 1).
example : (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℤ) *ᵥ ![-2, 1] = 0 ∧
    (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℤ)ᵀ *ᵥ ![-2, 1, 0] = 0 ∧
    (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℤ)ᵀ *ᵥ ![-3, 0, 1] = 0 := by decide
-- Perpendicular pairs: (1, 2) . (-2, 1) = 0; (1, 2, 3) . each check = 0.
example : (![1, 2] : Fin 2 → ℤ) ⬝ᵥ ![-2, 1] = 0 ∧ (![1, 2, 3] : Fin 3 → ℤ) ⬝ᵥ ![-2, 1, 0] = 0 ∧
    (![1, 2, 3] : Fin 3 → ℤ) ⬝ᵥ ![-3, 0, 1] = 0 := by decide
-- The order (3, 1) is (1, 2) + (2, -1), and (3, 1) and (1, 2) both use (5, 10, 15) kg.
example : (![3, 1] : Fin 2 → ℤ) = ![1, 2] + ![2, -1] ∧
    (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℤ) *ᵥ ![3, 1] = ![5, 10, 15] ∧
    (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℤ) *ᵥ ![1, 2] = ![5, 10, 15] := by decide
-- The tests: (1, 0, 0) gives -2 and -3; (5, 10, 15) gives 0 and 0; (1, 2, 0) gives 0 and -3.
example : (![-2, 1, 0] : Fin 3 → ℤ) ⬝ᵥ ![1, 0, 0] = -2 ∧ (![-3, 0, 1] : Fin 3 → ℤ) ⬝ᵥ ![1, 0, 0] = -3 ∧
    (![-2, 1, 0] : Fin 3 → ℤ) ⬝ᵥ ![5, 10, 15] = 0 ∧ (![-3, 0, 1] : Fin 3 → ℤ) ⬝ᵥ ![5, 10, 15] = 0 ∧
    (![-2, 1, 0] : Fin 3 → ℤ) ⬝ᵥ ![1, 2, 0] = 0 ∧ (![-3, 0, 1] : Fin 3 → ℤ) ⬝ᵥ ![1, 2, 0] = -3 := by
  decide
-- Nearest total to (1, 0, 0): a fourteenth of (1, 2, 3); the leftover is a check, squared length 13/14.
example : (![1, 0, 0] : Fin 3 → ℚ) - (1 / 14 : ℚ) • ![1, 2, 3] = ![13 / 14, -2 / 14, -3 / 14] ∧
    (!![1, 2; 2, 4; 3, 6] : Matrix (Fin 3) (Fin 2) ℚ)ᵀ *ᵥ ![13 / 14, -2 / 14, -3 / 14] = 0 ∧
    (![13 / 14, -2 / 14, -3 / 14] : Fin 3 → ℚ) ⬝ᵥ ![13 / 14, -2 / 14, -3 / 14] = 13 / 14 := by
  refine ⟨?_, ?_, ?_⟩
  · funext i; fin_cases i <;> simp <;> norm_num
  · funext i; fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
  · simp [dotProduct, Fin.sum_univ_succ]; norm_num
-- That nearest total passes both checks, yet no whole-number order makes it: butter s + 2 d is never 1/14.
example (s d : ℤ) : ((s : ℚ) + 2 * d) ≠ 1 / 14 := by
  intro h
  have h14 : ((14 * (s + 2 * d) : ℤ) : ℚ) = 1 := by push_cast; linarith
  have : 14 * (s + 2 * d) = 1 := by exact_mod_cast h14
  omega
-- The mistakes: a column as the test gives (1, 2, 3) . (5, 10, 15) = 70; rows as the rank give 2 - 3 = -1.
example : (![1, 2, 3] : Fin 3 → ℤ) ⬝ᵥ ![5, 10, 15] = 70 ∧ (2 : ℤ) - 3 = -1 := by decide

#print axioms ffs_null_iff_perp_rows
#print axioms ffs_row_space_perp_null_space
#print axioms ffs_split_row_plus_null
#print axioms ffs_row_space_one_for_one
#print axioms ffs_column_space_perp_left_null_space
#print axioms ffs_reachable_passes_every_check
#print axioms ffs_normal_equations_solvable
#print axioms ffs_passes_every_check_reachable
#print axioms ffs_solvable_iff_passes_every_check
#print axioms ffs_row_space_iff_perp_null_space
#print axioms ffs_rank_transpose
#print axioms ffs_bakery_two_checks
#print axioms ffs_bakery_report_impossible
#print axioms dual_apply_eq_dotProduct
#print axioms row_space_perp_null_space_and_column_space_perp_left_null_space
#print axioms solvable_iff_passes_every_left_null_check
#print axioms four_subspace_sizes
