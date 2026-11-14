-- Buckingham Pi: a relation among n positive quantities that holds in every unit system is a relation among n - k unit-free power products of them, where k is the rank of the dimension matrix.
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.Dual.Lemmas

open Matrix

theorem bp_prod_rpow_eq_exp {n : ℕ} (q e : Fin n → ℝ) (hq : ∀ i, 0 < q i) :
    ∏ i, q i ^ e i = Real.exp (∑ i, Real.log (q i) * e i) := by
  rw [Real.exp_sum]
  exact Finset.prod_congr rfl fun i _ => Real.rpow_def_of_pos (hq i) _

#print axioms bp_prod_rpow_eq_exp

theorem bp_finrank_ker {m n : ℕ} (D : Matrix (Fin m) (Fin n) ℝ) :
    Module.finrank ℝ (LinearMap.ker D.mulVecLin) = n - D.rank := by
  have h := LinearMap.finrank_range_add_finrank_ker D.mulVecLin
  rw [Module.finrank_fin_fun] at h
  rw [Matrix.rank]
  omega

#print axioms bp_finrank_ker

/-- Buckingham Pi. Take n positive quantities whose units are given by a dimension matrix `D`
(one row per base unit such as mass, length, time; column `i` holds the unit exponents of
quantity `i`), and let `k` be the rank of `D`. Changing the base units by positive factors `x`
turns quantity `i` into `q i * ∏ j, x j ^ D j i`. If a law `Φ` among the quantities holds in
every unit system, then there are n - k independent dimensionless products
`∏ i, q i ^ E r i` (exponent vectors in the null space of `D`) and a relation `Ψ` among them
alone, such that for all positive quantities the law holds exactly when `Ψ` holds of the groups. -/
theorem buckingham_pi {m n : ℕ} (D : Matrix (Fin m) (Fin n) ℝ) (Φ : (Fin n → ℝ) → Prop)
    (hinv : ∀ (q : Fin n → ℝ) (x : Fin m → ℝ), (∀ i, 0 < q i) → (∀ j, 0 < x j) →
      (Φ (fun i => q i * ∏ j, x j ^ D j i) ↔ Φ q)) :
    ∃ E : Fin (n - D.rank) → Fin n → ℝ,
      LinearIndependent ℝ E ∧ (∀ r, D *ᵥ E r = 0) ∧
      ∃ Ψ : (Fin (n - D.rank) → ℝ) → Prop,
        ∀ q : Fin n → ℝ, (∀ i, 0 < q i) → (Φ q ↔ Ψ (fun r => ∏ i, q i ^ E r i)) := by
  set K := LinearMap.ker D.mulVecLin
  let b : Module.Basis (Fin (n - D.rank)) ℝ K :=
    Module.finBasisOfFinrankEq ℝ K (bp_finrank_ker D)
  refine ⟨fun r => (b r : Fin n → ℝ), ?_, ?_, ?_⟩
  · exact b.linearIndependent.map' K.subtype (Submodule.ker_subtype K)
  · intro r
    exact LinearMap.mem_ker.mp (b r).2
  refine ⟨fun p => ∃ q', (∀ i, 0 < q' i) ∧ Φ q' ∧ (fun r => ∏ i, q' i ^ (b r : Fin n → ℝ) i) = p, ?_⟩
  intro q hq
  refine ⟨fun h => ⟨q, hq, h, rfl⟩, ?_⟩
  rintro ⟨q', hq', hΦ, hgr⟩
  -- v = log q - log q'
  set v : Fin n → ℝ := fun i => Real.log (q i) - Real.log (q' i) with hv
  -- v is orthogonal to the kernel
  have horth_b : ∀ r, ∑ i, v i * (b r : Fin n → ℝ) i = 0 := by
    intro r
    have h1 := congrFun hgr r
    simp only at h1
    rw [bp_prod_rpow_eq_exp _ _ hq', bp_prod_rpow_eq_exp _ _ hq] at h1
    have h2 := Real.exp_injective h1
    simp only [hv, sub_mul, Finset.sum_sub_distrib]
    linarith
  let φ : Module.Dual ℝ (Fin n → ℝ) :=
    { toFun := fun w => ∑ i, v i * w i
      map_add' := by intro a c; simp [mul_add, Finset.sum_add_distrib]
      map_smul' := by intro a c; simp [Finset.mul_sum, mul_left_comm] }
  have hφ : φ ∈ (LinearMap.ker D.mulVecLin).dualAnnihilator := by
    rw [Submodule.mem_dualAnnihilator]
    intro w hw
    suffices key : ∀ z ∈ Submodule.span ℝ (Set.range b), φ (z : Fin n → ℝ) = 0 from
      key ⟨w, hw⟩ (by rw [b.span_eq]; trivial)
    intro z hz
    induction hz using Submodule.span_induction with
    | mem y hy =>
      obtain ⟨r, rfl⟩ := hy
      exact horth_b r
    | zero => simp [φ]
    | add y z _ _ hy hz =>
      simp only [φ, LinearMap.coe_mk, AddHom.coe_mk] at hy hz ⊢
      simp [mul_add, Finset.sum_add_distrib, hy, hz]
    | smul a y _ hy =>
      simp only [φ, LinearMap.coe_mk, AddHom.coe_mk] at hy ⊢
      simp only [Submodule.coe_smul, Pi.smul_apply, smul_eq_mul]
      rw [show ∑ i, v i * (a * (y : Fin n → ℝ) i) = a * ∑ i, v i * (y : Fin n → ℝ) i by
        rw [Finset.mul_sum]; congr 1; ext i; ring, hy, mul_zero]
  rw [← LinearMap.range_dualMap_eq_dualAnnihilator_ker] at hφ
  obtain ⟨ψ, hψ⟩ := hφ
  let y : Fin m → ℝ := fun j => ψ (Pi.single j 1)
  have hvi : ∀ i, v i = ∑ j, Real.log (Real.exp (y j)) * D j i := by
    intro i
    have h1 := LinearMap.congr_fun hψ (Pi.single i 1)
    simp only [LinearMap.dualMap_apply, φ, LinearMap.coe_mk, AddHom.coe_mk] at h1
    rw [Finset.sum_eq_single i (by intro b _ hb; simp [hb]) (by simp)] at h1
    simp only [Pi.single_eq_same, mul_one] at h1
    rw [← h1]
    simp only [Real.log_exp]
    have : D.mulVecLin (Pi.single i 1) = ∑ j, D j i • Pi.single j 1 := by
      ext k
      simp [Matrix.mulVec_single, Finset.sum_apply, Pi.single_apply]
    rw [this, map_sum]
    simp [y, mul_comm]
  have hq_eq : (fun i => q' i * ∏ j, Real.exp (y j) ^ D j i) = q := by
    ext i
    rw [bp_prod_rpow_eq_exp (fun j => Real.exp (y j)) (fun j => D j i) (fun j => Real.exp_pos _),
      ← hvi i, hv]
    simp only
    rw [Real.exp_sub, Real.exp_log (hq i), Real.exp_log (hq' i)]
    field_simp [(hq' i).ne']
  have := hinv q' (fun j => Real.exp (y j)) hq' (fun j => Real.exp_pos _)
  rw [hq_eq] at this
  exact this.mpr hΦ

/-- Step 2, rank-nullity: the exponent vectors of dimensionless products form the null space of
the dimension matrix, and that space has dimension (number of quantities) - (rank). -/
theorem dimensionless_exponents_count {m n : ℕ} (D : Matrix (Fin m) (Fin n) ℝ) :
    Module.finrank ℝ (LinearMap.ker D.mulVecLin) = n - D.rank := by
  exact bp_finrank_ker D

/-- A product whose exponent vector is in the null space of the dimension matrix is
dimensionless: it reads the same number after any change of positive base units. -/
theorem dimensionless_product_unchanged_by_units {m n : ℕ} (D : Matrix (Fin m) (Fin n) ℝ)
    (e : Fin n → ℝ) (he : D *ᵥ e = 0) (q : Fin n → ℝ) (x : Fin m → ℝ)
    (hq : ∀ i, 0 < q i) (hx : ∀ j, 0 < x j) :
    ∏ i, (q i * ∏ j, x j ^ D j i) ^ e i = ∏ i, q i ^ e i := by
  have hP : ∀ i, ∏ j, x j ^ D j i = Real.exp (∑ j, Real.log (x j) * D j i) :=
    fun i => bp_prod_rpow_eq_exp (fun j => x j) (fun j => D j i) hx
  have hpos : ∀ i, 0 < q i * ∏ j, x j ^ D j i := fun i => by
    rw [hP]; exact mul_pos (hq i) (Real.exp_pos _)
  rw [bp_prod_rpow_eq_exp _ _ hpos, bp_prod_rpow_eq_exp _ _ hq]
  congr 1
  simp_rw [hP, Real.log_mul (hq _).ne' (Real.exp_pos _).ne', Real.log_exp, add_mul,
    Finset.sum_add_distrib, Finset.sum_mul]
  rw [Finset.sum_comm]
  have : ∀ j, ∑ i, Real.log (x j) * D j i * e i = 0 := by
    intro j
    have := congrFun he j
    simp only [Matrix.mulVec, dotProduct, Pi.zero_apply] at this
    simp_rw [mul_assoc, ← Finset.mul_sum, this, mul_zero]
  simp [this]

/-! The cyclist's dimension matrix: rows M, L, T; columns ρ, V, A, F, μ. -/

-- Π_F = F / (ρ V² A): exponents −1, −2, −1, 1, 0 make every row sum zero.
example : !![(1 : ℤ), 0, 0, 1, 1; -3, 1, 2, 1, -1; 0, -1, 0, -2, -1] *ᵥ ![-1, -2, -1, 1, 0] = 0 := by
  decide

-- Π_μ = μ / (ρ V √A): exponents −1, −1, −1/2, 0, 1 make every row sum zero.
example : !![(1 : ℚ), 0, 0, 1, 1; -3, 1, 2, 1, -1; 0, -1, 0, -2, -1] *ᵥ ![-1, -1, -1/2, 0, 1] = 0 := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_succ]

-- The wrong product F / (ρ V A) is not dimensionless: one power of V short.
example : !![(1 : ℤ), 0, 0, 1, 1; -3, 1, 2, 1, -1; 0, -1, 0, -2, -1] *ᵥ ![-1, -1, -1, 1, 0] ≠ 0 := by
  decide

-- Adding the speed of sound c (units m/s) at 150 m/s: the Mach number V / c is dimensionless.
example : !![(1 : ℤ), 0, 0, 1, 1, 0; -3, 1, 2, 1, -1, 1; 0, -1, 0, -2, -1, -1] *ᵥ
    ![0, 1, 0, 0, 0, -1] = 0 := by
  decide

-- The count: 5 quantities, rank 3, so 2 groups; with the speed of sound, 6 - 3 = 3 groups.
example : 5 - 3 = 2 ∧ 6 - 3 = 3 := by decide

#print axioms buckingham_pi
#print axioms dimensionless_exponents_count
#print axioms dimensionless_product_unchanged_by_units
