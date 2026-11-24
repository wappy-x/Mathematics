-- Radial basis functions: the Gaussian kernel matrix on distinct nodes in any dimension is positive definite, so the interpolation system has exactly one solution, and Rippa's leave-one-out formula holds.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Exponential

open Matrix

lemma rbf_hasSum_exp (a : ℝ) :
    HasSum (fun k : ℕ => a ^ k / (k.factorial : ℝ)) (Real.exp a) := by
  rw [Real.exp_eq_exp_ℝ]; exact NormedSpace.expSeries_div_hasSum_exp a

#print axioms rbf_hasSum_exp

lemma rbf_inner_pow {d : ℕ} (x y : EuclideanSpace ℝ (Fin d)) (k : ℕ) :
    (inner ℝ x y) ^ k = ∑ α : Fin k → Fin d, (∏ m, x (α m)) * (∏ m, y (α m)) := by
  have h : inner ℝ x y = ∑ l, x l * y l := by simp [PiLp.inner_apply, mul_comm]
  rw [h, ← Fin.prod_const, Finset.prod_univ_sum]
  simp [Finset.prod_mul_distrib]

#print axioms rbf_inner_pow

lemma rbf_quad_pow {n d : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d)) (c : Fin n → ℝ) (k : ℕ) :
    ∑ i, ∑ j, c i * c j * (inner ℝ (x i) (x j)) ^ k
      = ∑ α : Fin k → Fin d, (∑ i, c i * ∏ m, x i (α m)) ^ 2 := by
  simp_rw [rbf_inner_pow, sq, Finset.sum_mul_sum, Finset.mul_sum]
  rw [Finset.sum_comm (s := (Finset.univ : Finset (Fin k → Fin d)))]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun j _ => ?_
  refine Finset.sum_congr rfl fun α _ => ?_
  ring

#print axioms rbf_quad_pow

lemma rbf_char {n d : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d)) (hx : Function.Injective x)
    (c : Fin n → ℝ) (h : ∀ v, ∑ i, c i * Real.exp (inner ℝ (x i) v) = 0) : c = 0 := by
  let χ : Fin n → (Multiplicative (EuclideanSpace ℝ (Fin d)) →* ℝ) := fun i =>
    { toFun := fun v => Real.exp (inner ℝ (x i) (Multiplicative.toAdd v))
      map_one' := by simp
      map_mul' := by intro a b; simp [inner_add_right, Real.exp_add] }
  have hinj : Function.Injective χ := by
    intro i j hij
    have := DFunLike.congr_fun hij (Multiplicative.ofAdd (x i - x j))
    simp only [χ, MonoidHom.coe_mk, OneHom.coe_mk, toAdd_ofAdd, Real.exp_eq_exp] at this
    apply hx
    have h2 : inner ℝ (x i - x j) (x i - x j) = 0 := by
      rw [inner_sub_left, this, sub_self]
    exact sub_eq_zero.mp (inner_self_eq_zero.mp h2)
  have hli := (linearIndependent_monoidHom (Multiplicative (EuclideanSpace ℝ (Fin d))) ℝ).comp χ hinj
  funext i
  refine Fintype.linearIndependent_iff.mp hli c ?_ i
  funext v
  simpa [Finset.sum_apply, χ] using h (Multiplicative.toAdd v)

#print axioms rbf_char

lemma rbf_exp_gram_pos {n d : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d))
    (hx : Function.Injective x) {s : ℝ} (hs : 0 < s) (c : Fin n → ℝ) (hc : c ≠ 0) :
    0 < ∑ i, ∑ j, c i * c j * Real.exp (s * inner ℝ (x i) (x j)) := by
  set T : ℕ → ℝ := fun k =>
    s ^ k / (k.factorial : ℝ) * ∑ α : Fin k → Fin d, (∑ i, c i * ∏ m, x i (α m)) ^ 2 with hT
  have hS : HasSum T (∑ i, ∑ j, c i * c j * Real.exp (s * inner ℝ (x i) (x j))) := by
    have := hasSum_sum (fun i (_ : i ∈ Finset.univ) => hasSum_sum (fun j (_ : j ∈ Finset.univ) =>
      (rbf_hasSum_exp (s * inner ℝ (x i) (x j))).mul_left (c i * c j)))
    convert this using 1
    funext k
    rw [hT]
    dsimp only
    rw [← rbf_quad_pow, Finset.mul_sum]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [mul_pow]; ring
  have hnn : ∀ k, 0 ≤ T k := fun k => by rw [hT]; positivity
  have hex : ∃ k, 0 < T k := by
    by_contra hne
    push Not at hne
    have hzero : ∀ k (α : Fin k → Fin d), ∑ i, c i * ∏ m, x i (α m) = 0 := by
      intro k α
      have hk : T k = 0 := le_antisymm (hne k) (hnn k)
      rw [hT] at hk
      dsimp only at hk
      have hpos : 0 < s ^ k / (k.factorial : ℝ) := by positivity
      have hsum := (mul_eq_zero.mp hk).resolve_left hpos.ne'
      have := (Finset.sum_eq_zero_iff_of_nonneg (fun α _ => sq_nonneg
        (∑ i, c i * ∏ m, x i (α m)))).mp hsum α (Finset.mem_univ _)
      exact pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
    have hpow : ∀ v k, ∑ i, c i * (inner ℝ (x i) v) ^ k = 0 := by
      intro v k
      simp_rw [rbf_inner_pow, Finset.mul_sum]
      rw [Finset.sum_comm]
      refine Finset.sum_eq_zero fun α _ => ?_
      have := hzero k α
      calc ∑ i, c i * ((∏ m, x i (α m)) * ∏ m, v (α m))
          = (∑ i, c i * ∏ m, x i (α m)) * ∏ m, v (α m) := by
            rw [Finset.sum_mul]; refine Finset.sum_congr rfl fun i _ => by ring
        _ = 0 := by rw [this, zero_mul]
    have hexp : ∀ v, ∑ i, c i * Real.exp (inner ℝ (x i) v) = 0 := by
      intro v
      have h1 := hasSum_sum (fun i (_ : i ∈ Finset.univ) =>
        (rbf_hasSum_exp (inner ℝ (x i) v)).mul_left (c i))
      have h2 : (fun k : ℕ => ∑ i, c i * ((inner ℝ (x i) v) ^ k / (k.factorial : ℝ)))
          = fun _ => 0 := by
        funext k
        have := hpow v k
        calc ∑ i, c i * ((inner ℝ (x i) v) ^ k / (k.factorial : ℝ))
            = (∑ i, c i * (inner ℝ (x i) v) ^ k) / (k.factorial : ℝ) := by
              rw [Finset.sum_div]; refine Finset.sum_congr rfl fun i _ => by ring
          _ = 0 := by rw [this, zero_div]
      rw [h2] at h1
      exact h1.unique hasSum_zero
    exact hc (rbf_char x hx c hexp)
  obtain ⟨k, hk⟩ := hex
  rw [← hS.tsum_eq]
  exact hS.summable.tsum_pos hnn k hk

#print axioms rbf_exp_gram_pos

/-- The Gaussian kernel matrix is positive definite: for any distinct nodes `x 1, ..., x n`
in any dimension `d` and any shape parameter `ε > 0`, the matrix with entries
`A i j = exp (-(ε ‖x i - x j‖)^2)` satisfies `cᵀ A c > 0` for every nonzero weight vector `c`. -/
theorem gaussian_kernel_matrix_posDef {n d : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d))
    (hx : Function.Injective x) {ε : ℝ} (hε : 0 < ε) :
    (Matrix.of fun i j => Real.exp (-((ε * ‖x i - x j‖) ^ 2))).PosDef := by
  rw [posDef_iff_dotProduct_mulVec]
  refine ⟨?_, ?_⟩
  · ext i j
    simp [norm_sub_rev]
  · intro c hc
    have hentry : ∀ i j, Real.exp (-((ε * ‖x i - x j‖) ^ 2))
        = Real.exp (-(ε ^ 2 * ‖x i‖ ^ 2)) * Real.exp (-(ε ^ 2 * ‖x j‖ ^ 2))
          * Real.exp ((2 * ε ^ 2) * inner ℝ (x i) (x j)) := by
      intro i j
      rw [← Real.exp_add, ← Real.exp_add]
      congr 1
      rw [mul_pow, norm_sub_sq_real]; ring
    set c' : Fin n → ℝ := fun i => c i * Real.exp (-(ε ^ 2 * ‖x i‖ ^ 2)) with hc'
    have hc'0 : c' ≠ 0 := by
      intro h0
      apply hc
      funext i
      have := congr_fun h0 i
      simp only [hc', Pi.zero_apply] at this
      simpa [(Real.exp_pos _).ne'] using this
    have key := rbf_exp_gram_pos x hx (s := 2 * ε ^ 2) (by positivity) c' hc'0
    convert key using 1
    simp only [star_trivial, dotProduct, mulVec, Matrix.of_apply, Finset.mul_sum, hentry, hc']
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => by ring

/-- The Gaussian interpolation system is solvable: for distinct nodes in any dimension, any
shape parameter `ε > 0` and any data values `y`, there is exactly one weight vector `c` with
`∑ j, c j * exp (-(ε ‖x i - x j‖)^2) = y i` at every node `x i`. -/
theorem gaussian_interpolant_exists_unique {n d : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d))
    (hx : Function.Injective x) {ε : ℝ} (hε : 0 < ε) (y : Fin n → ℝ) :
    ∃! c : Fin n → ℝ, ∀ i, ∑ j, c j * Real.exp (-((ε * ‖x i - x j‖) ^ 2)) = y i := by
  set A : Matrix (Fin n) (Fin n) ℝ := Matrix.of fun i j => Real.exp (-((ε * ‖x i - x j‖) ^ 2))
    with hA
  have hpd : A.PosDef := gaussian_kernel_matrix_posDef x hx hε
  have hdet : IsUnit A.det := (Matrix.isUnit_iff_isUnit_det A).mp hpd.isUnit
  have hiff : ∀ c : Fin n → ℝ,
      (∀ i, ∑ j, c j * Real.exp (-((ε * ‖x i - x j‖) ^ 2)) = y i) ↔ A *ᵥ c = y := by
    intro c
    rw [funext_iff]
    refine forall_congr' fun i => ?_
    simp only [hA, mulVec, dotProduct, Matrix.of_apply, mul_comm]
  refine ⟨A⁻¹ *ᵥ y, (hiff _).2 ?_, fun c hc => ?_⟩
  · rw [mulVec_mulVec, mul_nonsing_inv A hdet, one_mulVec]
  · have h := (hiff c).1 hc
    rw [← h, mulVec_mulVec, nonsing_inv_mul A hdet, one_mulVec]

/-- Rippa's leave-one-out formula: let `A` be positive definite and `c` the weights with
`A c = y`. Let `c'` be the weights of the fit that leaves out node `k`: weight `0` on node `k`
and matching the data at every other node. Then that fit's miss at node `k`,
`e_k = y k - (A c') k`, equals `c k / (A⁻¹) k k`. -/
theorem rippa_leave_one_out {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.PosDef)
    (y c c' : Fin n → ℝ) (k : Fin n) (hc : A *ᵥ c = y)
    (hc'k : c' k = 0) (hc' : ∀ i, i ≠ k → (A *ᵥ c') i = y i) :
    y k - (A *ᵥ c') k = c k / A⁻¹ k k := by
  set e := y k - (A *ᵥ c') k with he
  have hdet : IsUnit A.det := (Matrix.isUnit_iff_isUnit_det A).mp hA.isUnit
  have hAc' : A *ᵥ c' = y - Pi.single k e := by
    funext i
    by_cases hik : i = k
    · subst hik; simp [he]
    · simp [hik, hc' i hik]
  have hc'eq : c' = A⁻¹ *ᵥ y - A⁻¹ *ᵥ Pi.single k e := by
    rw [← mulVec_sub, ← hAc', mulVec_mulVec, nonsing_inv_mul A hdet, one_mulVec]
  have hcy : A⁻¹ *ᵥ y = c := by
    rw [← hc, mulVec_mulVec, nonsing_inv_mul A hdet, one_mulVec]
  have hk := congr_fun hc'eq k
  rw [hcy, hc'k, Pi.sub_apply, mulVec_single] at hk
  have hpos : 0 < A⁻¹ k k := hA.inv.diag_pos
  simp at hk
  rw [eq_div_iff hpos.ne']
  linarith

#print axioms gaussian_kernel_matrix_posDef
#print axioms gaussian_interpolant_exists_unique
#print axioms rippa_leave_one_out
