-- Newton and BFGS: the lifted Newton step always points downhill, every BFGS matrix started from the identity sends each step to its change in slope and stays positive definite while the curvature condition holds, the banana valley's lowest point is (1, 1), and the card's whole-number worked values come out exactly.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Order.ConditionallyCompleteLattice.Indexed
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Algebra.Order.Star.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Matrix

/-- The gradient of `f` at `x`: entry `i` is the slope of `f` along coordinate `i`. -/
noncomputable def gradVec {n : ℕ} (f : (Fin n → ℝ) → ℝ) (x : Fin n → ℝ) : Fin n → ℝ :=
  fun i => fderiv ℝ f x (Pi.single i 1)

/-- The Hessian of `f` at `x`: entry `(i, j)` is the slope along coordinate `i` of the slope of `f`
along coordinate `j`. -/
noncomputable def hessMat {n : ℕ} (f : (Fin n → ℝ) → ℝ) (x : Fin n → ℝ) :
    Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j => fderiv ℝ (fun z => fderiv ℝ f z (Pi.single j 1)) x (Pi.single i 1)

/-- The lowest curvature of a matrix `H` in any direction: the smallest value of `wᵀ H w` over
directions `w` of length 1. For a symmetric matrix such as a Hessian this is its smallest
eigenvalue, the card's `λ_min`. -/
noncomputable def lowestCurvature {n : ℕ} (H : Matrix (Fin n) (Fin n) ℝ) : ℝ :=
  ⨅ w : {w : Fin n → ℝ // w ⬝ᵥ w = 1}, w.1 ⬝ᵥ (H *ᵥ w.1)

theorem lowestCurvature_bddBelow {n : ℕ} (H : Matrix (Fin n) (Fin n) ℝ) :
    BddBelow (Set.range fun w : {w : Fin n → ℝ // w ⬝ᵥ w = 1} => w.1 ⬝ᵥ (H *ᵥ w.1)) := by
  refine ⟨-∑ i, ∑ j, |H i j|, ?_⟩
  rintro _ ⟨⟨w, hw⟩, rfl⟩
  have hwi : ∀ i, |w i| ≤ 1 := by
    intro i
    have h1 : w i * w i ≤ ∑ j, w j * w j :=
      Finset.single_le_sum (f := fun j => w j * w j) (fun j _ => mul_self_nonneg (w j))
        (Finset.mem_univ i)
    have h2 : w i ^ 2 ≤ 1 := by
      have : ∑ j, w j * w j = 1 := by simpa [dotProduct] using hw
      nlinarith
    exact (sq_le_one_iff_abs_le_one _).mp h2
  simp only [dotProduct, mulVec, Finset.mul_sum]
  rw [← Finset.sum_neg_distrib]
  refine Finset.sum_le_sum fun i _ => ?_
  rw [← Finset.sum_neg_distrib]
  refine Finset.sum_le_sum fun j _ => ?_
  have hab : |w i * (H i j * w j)| ≤ |H i j| := by
    rw [abs_mul, abs_mul]
    have := hwi i; have := hwi j
    have := abs_nonneg (H i j); have := abs_nonneg (w i); have := abs_nonneg (w j)
    calc |w i| * (|H i j| * |w j|) ≤ 1 * (|H i j| * 1) := by gcongr
      _ = |H i j| := by ring
  exact (abs_le.mp hab).1

theorem quad_ge_lowestCurvature {n : ℕ} (H : Matrix (Fin n) (Fin n) ℝ) (d : Fin n → ℝ)
    (hd : d ≠ 0) : lowestCurvature H * (d ⬝ᵥ d) ≤ d ⬝ᵥ (H *ᵥ d) := by
  have hpos : 0 < d ⬝ᵥ d := by
    have h0 : 0 ≤ d ⬝ᵥ d := Finset.sum_nonneg fun i _ => mul_self_nonneg (d i)
    exact lt_of_le_of_ne h0 (fun h => hd (dotProduct_self_eq_zero.mp h.symm))
  set c := Real.sqrt (d ⬝ᵥ d) with hc
  have hcpos : 0 < c := Real.sqrt_pos.mpr hpos
  have hc2 : c ^ 2 = d ⬝ᵥ d := Real.sq_sqrt hpos.le
  have hw : (c⁻¹ • d) ⬝ᵥ (c⁻¹ • d) = 1 := by
    rw [smul_dotProduct, dotProduct_smul, smul_eq_mul, smul_eq_mul, ← hc2]
    field_simp
  have hle := ciInf_le (lowestCurvature_bddBelow H) ⟨c⁻¹ • d, hw⟩
  simp only [mulVec_smul, smul_dotProduct, dotProduct_smul, smul_eq_mul] at hle
  change lowestCurvature H ≤ _ at hle
  rw [← hc2]
  have : c⁻¹ * (c⁻¹ * (d ⬝ᵥ (H *ᵥ d))) = (d ⬝ᵥ (H *ᵥ d)) / c ^ 2 := by field_simp
  rw [this, le_div_iff₀ (by positivity)] at hle
  exact hle

theorem fderiv_eq_dot {n : ℕ} (L : (Fin n → ℝ) →L[ℝ] ℝ) (d : Fin n → ℝ) :
    L d = (fun i => L (Pi.single i 1)) ⬝ᵥ d := by
  have : d = ∑ i, d i • Pi.single i (1 : ℝ) := by
    ext j; simp [Pi.single_apply]
  conv_lhs => rw [this]
  simp [map_sum, map_smul, dotProduct, mul_comm]

theorem bfgs_rank_one_mulVec {n : ℕ} (B : Matrix (Fin n) (Fin n) ℝ) (s z : Fin n → ℝ) :
    (B * vecMulVec s s * B) *ᵥ z = (s ⬝ᵥ (B *ᵥ z)) • (B *ᵥ s) := by
  rw [mul_vecMulVec, vecMulVec_mul, vecMulVec_mulVec, ← dotProduct_mulVec]
  simp [op_smul_eq_smul]

theorem symm_dot {n : ℕ} (B : Matrix (Fin n) (Fin n) ℝ) (hB : Bᵀ = B) (u v : Fin n → ℝ) :
    u ⬝ᵥ (B *ᵥ v) = v ⬝ᵥ (B *ᵥ u) := by
  rw [dotProduct_mulVec, dotProduct_comm, ← mulVec_transpose, hB]

theorem bfgs_step {n : ℕ} (B : Matrix (Fin n) (Fin n) ℝ) (s y : Fin n → ℝ) (hB : B.PosDef)
    (hc : 0 < y ⬝ᵥ s) :
    (B - (s ⬝ᵥ (B *ᵥ s))⁻¹ • (B * vecMulVec s s * B)
        + (y ⬝ᵥ s)⁻¹ • vecMulVec y y).PosDef ∧
    (B - (s ⬝ᵥ (B *ᵥ s))⁻¹ • (B * vecMulVec s s * B)
        + (y ⬝ᵥ s)⁻¹ • vecMulVec y y) *ᵥ s = y := by
  have hBT : Bᵀ = B := by
    have := hB.isHermitian
    rwa [IsHermitian, conjTranspose_eq_transpose_of_trivial] at this
  have hs0 : s ≠ 0 := by
    rintro rfl; simp at hc
  have hBpos : ∀ v : Fin n → ℝ, v ≠ 0 → 0 < v ⬝ᵥ (B *ᵥ v) := by
    intro v hv; simpa using hB.dotProduct_mulVec_pos hv
  have ha : 0 < s ⬝ᵥ (B *ᵥ s) := hBpos s hs0
  have hmul : ∀ z, (B - (s ⬝ᵥ (B *ᵥ s))⁻¹ • (B * vecMulVec s s * B)
        + (y ⬝ᵥ s)⁻¹ • vecMulVec y y) *ᵥ z
      = B *ᵥ z - ((s ⬝ᵥ (B *ᵥ s))⁻¹ * (s ⬝ᵥ (B *ᵥ z))) • (B *ᵥ s)
        + ((y ⬝ᵥ s)⁻¹ * (y ⬝ᵥ z)) • y := by
    intro z
    rw [add_mulVec, sub_mulVec, smul_mulVec, smul_mulVec, bfgs_rank_one_mulVec,
      vecMulVec_mulVec, op_smul_eq_smul, smul_smul, smul_smul]
  refine ⟨?_, ?_⟩
  · refine PosDef.of_dotProduct_mulVec_pos ?_ ?_
    · rw [IsHermitian, conjTranspose_eq_transpose_of_trivial]
      simp only [transpose_add, transpose_sub, transpose_smul, transpose_mul, transpose_vecMulVec,
        hBT, Matrix.mul_assoc]
    · intro z hz
      simp only [star_trivial]
      rw [hmul, dotProduct_add, dotProduct_sub, dotProduct_smul, dotProduct_smul, smul_eq_mul,
        smul_eq_mul, symm_dot B hBT z s]
      set a := s ⬝ᵥ (B *ᵥ s)
      set b := s ⬝ᵥ (B *ᵥ z)
      set Z := z ⬝ᵥ (B *ᵥ z)
      set c := y ⬝ᵥ s
      set e := y ⬝ᵥ z
      rw [dotProduct_comm z y]
      -- v = a z - b s
      have hv : (a • z - b • s) ⬝ᵥ (B *ᵥ (a • z - b • s)) = a * (a * Z - b ^ 2) := by
        simp only [mulVec_sub, mulVec_smul, dotProduct_sub, sub_dotProduct, dotProduct_smul,
          smul_dotProduct, smul_eq_mul]
        rw [symm_dot B hBT z s]
        ring
      by_cases hv0 : a • z - b • s = 0
      · have hb : b ≠ 0 := by
          rintro hb0
          rw [hb0, zero_smul, sub_zero] at hv0
          exact hz ((smul_eq_zero.mp hv0).resolve_left ha.ne')
        have hze : a * e = b * c := by
          have := congrArg (fun v => y ⬝ᵥ v) hv0
          simpa [dotProduct_sub, dotProduct_smul, sub_eq_zero] using this
        have hZ : a * Z - b ^ 2 = 0 := by
          have := hv; rw [hv0] at this; simp at this
          rcases this.symm with h | h
          · exact h
          · exact absurd h ha.ne'
        have he : e ≠ 0 := by
          rintro he0; rw [he0, mul_zero] at hze
          exact (mul_ne_zero hb hc.ne') hze.symm
        have h1 : Z - a⁻¹ * b * b = 0 := by
          field_simp; nlinarith
        have h2 : 0 < c⁻¹ * e * e := by
          have : 0 < e * e := mul_self_pos.mpr he
          rw [mul_assoc]; exact mul_pos (inv_pos.mpr hc) this
        linarith
      · have hpos := hBpos _ hv0
        rw [hv] at hpos
        have h1 : 0 < a * Z - b ^ 2 := pos_of_mul_pos_right hpos ha.le
        have h1' : 0 < Z - a⁻¹ * b * b := by
          have : Z - a⁻¹ * b * b = (a * Z - b ^ 2) / a := by field_simp
          rw [this]; positivity
        have h2 : 0 ≤ c⁻¹ * e * e := by
          have : 0 ≤ e * e := mul_self_nonneg e
          have : 0 ≤ c⁻¹ := inv_nonneg.mpr hc.le
          nlinarith
        linarith
  · rw [hmul, symm_dot B hBT s s, inv_mul_cancel₀ ha.ne', inv_mul_cancel₀ hc.ne', one_smul,
      one_smul]
    abel

/-- The lifted Newton step points downhill. Let `f` have two continuous derivatives, take a point
`x` where the gradient `∇f(x)` is not zero, and a floor `δ > 0`. Lift the Hessian by
`τ = max(0, δ - λ_min(∇²f(x)))` in every direction and solve `(∇²f(x) + τ I) d = -∇f(x)`
for the direction `d`. Then the slope of `f` along `d` is negative: `d` goes downhill. -/
theorem lifted_newton_step_points_downhill {n : ℕ} (f : (Fin n → ℝ) → ℝ) (hf : ContDiff ℝ 2 f)
    (x : Fin n → ℝ) (δ : ℝ) (hδ : 0 < δ) (τ : ℝ)
    (hτ : τ = max 0 (δ - lowestCurvature (hessMat f x)))
    (d : Fin n → ℝ) (hd : (hessMat f x + τ • (1 : Matrix (Fin n) (Fin n) ℝ)) *ᵥ d = -gradVec f x)
    (hg : gradVec f x ≠ 0) :
    fderiv ℝ f x d < 0 := by
  have hfd : fderiv ℝ f x d = gradVec f x ⬝ᵥ d := fderiv_eq_dot _ d
  have hd0 : d ≠ 0 := by
    rintro rfl
    apply hg
    have := hd
    rw [mulVec_zero] at this
    exact neg_eq_zero.mp this.symm
  have hpos : 0 < d ⬝ᵥ d := by
    have h0 : 0 ≤ d ⬝ᵥ d := Finset.sum_nonneg fun i _ => mul_self_nonneg (d i)
    exact lt_of_le_of_ne h0 (fun h => hd0 (dotProduct_self_eq_zero.mp h.symm))
  have hq := quad_ge_lowestCurvature (hessMat f x) d hd0
  have hτ' : δ - lowestCurvature (hessMat f x) ≤ τ := hτ ▸ le_max_right _ _
  have key : d ⬝ᵥ ((hessMat f x + τ • (1 : Matrix (Fin n) (Fin n) ℝ)) *ᵥ d)
      = d ⬝ᵥ (hessMat f x *ᵥ d) + τ * (d ⬝ᵥ d) := by
    rw [add_mulVec, smul_mulVec, one_mulVec, dotProduct_add, dotProduct_smul, smul_eq_mul]
  rw [hd, dotProduct_neg, dotProduct_comm] at key
  rw [hfd]
  nlinarith

/-- BFGS remembers curvature and stays a bowl. Start from `B₀ = I`. After each step `s_k`, with
change in slope `y_k`, update
`B_{k+1} = B_k - (B_k s_k s_kᵀ B_k) / (s_kᵀ B_k s_k) + (y_k y_kᵀ) / (y_kᵀ s_k)`.
If the curvature condition `y_kᵀ s_k > 0` holds at every step, then every `B_k` is positive
definite (a true bowl), and every updated matrix meets the secant equation `B_{k+1} s_k = y_k`. -/
theorem bfgs_meets_secant_and_stays_positive_definite {n : ℕ}
    (B : ℕ → Matrix (Fin n) (Fin n) ℝ) (s y : ℕ → Fin n → ℝ)
    (h0 : B 0 = 1)
    (hupdate : ∀ k, B (k + 1) =
      B k - (s k ⬝ᵥ (B k *ᵥ s k))⁻¹ • (B k * vecMulVec (s k) (s k) * B k)
        + (y k ⬝ᵥ s k)⁻¹ • vecMulVec (y k) (y k))
    (hcurv : ∀ k, 0 < y k ⬝ᵥ s k) :
    ∀ k, (B k).PosDef ∧ B (k + 1) *ᵥ s k = y k := by
  have hpd : ∀ k, (B k).PosDef := by
    intro k
    induction k with
    | zero => rw [h0]; exact PosDef.one
    | succ k ih => rw [hupdate k]; exact (bfgs_step (B k) (s k) (y k) ih (hcurv k)).1
  intro k
  refine ⟨hpd k, ?_⟩
  rw [hupdate k]
  exact (bfgs_step (B k) (s k) (y k) (hpd k) (hcurv k)).2


/-- The banana valley, the card's test landscape: `f(u, v) = (1 - u)² + 100 (v - u²)²`. -/
def banana (u v : ℝ) : ℝ := (1 - u) ^ 2 + 100 * (v - u ^ 2) ^ 2

/-- The answer is the global minimum. The banana valley has height 0 at `(1, 1)`, and no point
of the plane is lower. -/
theorem banana_global_minimum_at_one_one :
    banana 1 1 = 0 ∧ ∀ u v : ℝ, banana 1 1 ≤ banana u v := by
  refine ⟨by norm_num [banana], fun u v => ?_⟩
  have : banana 1 1 = 0 := by norm_num [banana]
  rw [this, banana]
  positivity

/-! The card's whole-number worked values, checked exactly. -/

-- height at the start (0, 1): (1 - 0)² + 100 (1 - 0)² = 101
example : banana 0 1 = 101 := by norm_num [banana]
-- slopes at (0, 1): -2(1 - 0) - 400 × 0 × (1 - 0) = -2 and 200 (1 - 0) = 200
example : -2 * (1 - (0 : ℤ)) - 400 * 0 * (1 - 0 ^ 2) = -2 ∧ 200 * (1 - (0 : ℤ) ^ 2) = 200 := by
  norm_num
-- Hessian at (0, 1): 2 - 400 × 1 + 1200 × 0 = -398, -400 × 0 = 0, and 200
example : (2 : ℤ) - 400 * 1 + 1200 * 0 ^ 2 = -398 ∧ (-400 : ℤ) * 0 = 0 := by norm_num
-- Hessian at (1, 1): 2 - 400 + 1200 = 802, -400 × 1 = -400, 200; determinant 802 × 200 - 400² = 400
example : (2 : ℤ) - 400 * 1 + 1200 * 1 ^ 2 = 802 ∧ (-400 : ℤ) * 1 = -400 := by norm_num
example : !![(802 : ℤ), -400; -400, 200].det = 400 := by
  simp [Matrix.det_fin_two_of]
-- the test bowl [[3, 1], [1, 2]]: its bottom solves A x = (1, 1), and by Cramer's rule
-- x = ((2 - 1)/5, (3 - 1)/5) = (1/5, 2/5), the card's (0.2, 0.4)
example : !![(3 : ℚ), 1; 1, 2] *ᵥ ![1 / 5, 2 / 5] = ![1, 1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]

#print axioms lowestCurvature_bddBelow
#print axioms quad_ge_lowestCurvature
#print axioms fderiv_eq_dot
#print axioms bfgs_rank_one_mulVec
#print axioms symm_dot
#print axioms bfgs_step
#print axioms lifted_newton_step_points_downhill
#print axioms bfgs_meets_secant_and_stays_positive_definite
#print axioms banana_global_minimum_at_one_one
