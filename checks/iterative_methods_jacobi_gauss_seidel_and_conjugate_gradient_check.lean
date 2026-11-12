-- Iterating instead of factoring: on a strictly diagonally dominant matrix, Jacobi and Gauss-Seidel converge from every start with max-norm error at most q^k times the first error, and for a symmetric positive definite matrix a polynomial with p(0) = 1 shrinks every error in the energy norm by 2((√κ − 1)/(√κ + 1))^k, the conjugate gradient bound.
import Mathlib.Analysis.Matrix.Spectrum
import Mathlib.Analysis.Normed.Group.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Algebra.Polynomial.AlgebraMap
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Order.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Chebyshev.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse

open Matrix Filter Topology Polynomial

variable {n : ℕ}

/-- Strict diagonal dominance by rows: in every row, the diagonal entry is bigger in size than
the other entries of that row added up in size. -/
def StrictlyDiagDominant (A : Matrix (Fin n) (Fin n) ℝ) : Prop :=
  ∀ i, ∑ j ∈ Finset.univ.erase i, |A i j| < |A i i|

/-- The dominance ratio `q`: the largest, over the rows, of the off-diagonal sizes added up and
divided by the size of the diagonal entry. -/
noncomputable def dominanceRatio (A : Matrix (Fin n) (Fin n) ℝ) : ℝ :=
  ⨆ i, (∑ j ∈ Finset.univ.erase i, |A i j|) / |A i i|

/-- One Jacobi sweep for `A x = b`: each entry `i` is set to the value that balances row `i`,
using the old values of all the other entries,
`x_i ← (b_i − Σ_{j ≠ i} a_ij x_j) / a_ii`. -/
noncomputable def jacobiSweep (A : Matrix (Fin n) (Fin n) ℝ) (b x : Fin n → ℝ) : Fin n → ℝ :=
  fun i => (b i - ∑ j ∈ Finset.univ.erase i, A i j * x j) / A i i

/-- One Gauss-Seidel sweep for `A x = b`, in the order `0, 1, …, n − 1`: entry `i` is set to
the value that balances row `i`, using the new values of the entries before it and the old
values of the entries after it,
`x_i ← (b_i − Σ_{j < i} a_ij x_j^new − Σ_{j > i} a_ij x_j^old) / a_ii`. -/
noncomputable def gaussSeidelSweep (A : Matrix (Fin n) (Fin n) ℝ) (b x : Fin n → ℝ) :
    Fin n → ℝ :=
  go
where
  /-- The new value of entry `i`, computed from the new values before it. -/
  go (i : Fin n) : ℝ :=
    (b i - ∑ j : {j : Fin n // j < i}, A i j * go j.1
      - ∑ j ∈ Finset.univ.filter (fun j => i < j), A i j * x j) / A i i
  termination_by i.val
  decreasing_by exact j.2

/-- The energy norm `‖v‖_A = √(vᵀ A v)` of a list `v`, measured by the matrix `A`. -/
noncomputable def energyNorm (A : Matrix (Fin n) (Fin n) ℝ) (v : Fin n → ℝ) : ℝ :=
  Real.sqrt (v ⬝ᵥ (A *ᵥ v))

lemma sdd_diag_pos (A : Matrix (Fin n) (Fin n) ℝ) (hA : StrictlyDiagDominant A) (i : Fin n) :
    0 < |A i i| :=
  lt_of_le_of_lt (Finset.sum_nonneg fun j _ => abs_nonneg (A i j)) (hA i)

lemma dominanceRatio_nonneg (A : Matrix (Fin n) (Fin n) ℝ) : 0 ≤ dominanceRatio A :=
  Real.iSup_nonneg fun i => div_nonneg (Finset.sum_nonneg fun j _ => abs_nonneg _) (abs_nonneg _)

lemma dominanceRatio_lt_one (A : Matrix (Fin n) (Fin n) ℝ) (hA : StrictlyDiagDominant A) :
    dominanceRatio A < 1 := by
  rcases isEmpty_or_nonempty (Fin n) with h | h
  · rw [dominanceRatio, Real.iSup_of_isEmpty]; norm_num
  · obtain ⟨i, hi⟩ := exists_eq_ciSup_of_finite
      (f := fun i => (∑ j ∈ Finset.univ.erase i, |A i j|) / |A i i|)
    rw [dominanceRatio, ← hi]
    exact (div_lt_one (sdd_diag_pos A hA i)).2 (hA i)

lemma sum_off_le (A : Matrix (Fin n) (Fin n) ℝ) (hA : StrictlyDiagDominant A) (i : Fin n) :
    ∑ j ∈ Finset.univ.erase i, |A i j| ≤ dominanceRatio A * |A i i| := by
  have h : (∑ j ∈ Finset.univ.erase i, |A i j|) / |A i i| ≤ dominanceRatio A :=
    le_ciSup (f := fun i => (∑ j ∈ Finset.univ.erase i, |A i j|) / |A i i|)
      (Set.finite_range _).bddAbove i
  exact (div_le_iff₀ (sdd_diag_pos A hA i)).1 h

lemma coord_le_norm (v : Fin n → ℝ) (j : Fin n) : |v j| ≤ ‖v‖ := by
  have := norm_le_pi_norm v j
  rwa [Real.norm_eq_abs] at this

lemma jacobi_step (A : Matrix (Fin n) (Fin n) ℝ) (b xstar : Fin n → ℝ)
    (hA : StrictlyDiagDominant A) (hx : A *ᵥ xstar = b) (x : Fin n → ℝ) :
    ‖jacobiSweep A b x - xstar‖ ≤ dominanceRatio A * ‖x - xstar‖ := by
  refine (pi_norm_le_iff_of_nonneg
    (mul_nonneg (dominanceRatio_nonneg A) (norm_nonneg _))).2 fun i => ?_
  rw [Real.norm_eq_abs]
  have hAi := sdd_diag_pos A hA i
  have hAi' : A i i ≠ 0 := abs_pos.1 hAi
  have hb : b i = A i i * xstar i + ∑ j ∈ Finset.univ.erase i, A i j * xstar j := by
    rw [← hx]; simp only [mulVec, dotProduct]
    exact (Finset.add_sum_erase _ (fun j => A i j * xstar j) (Finset.mem_univ i)).symm
  have key : (jacobiSweep A b x - xstar) i =
      (∑ j ∈ Finset.univ.erase i, A i j * (xstar j - x j)) / A i i := by
    simp only [Pi.sub_apply, jacobiSweep, hb, mul_sub, Finset.sum_sub_distrib]
    field_simp
    ring
  rw [key, abs_div, div_le_iff₀ hAi]
  calc |∑ j ∈ Finset.univ.erase i, A i j * (xstar j - x j)|
      ≤ ∑ j ∈ Finset.univ.erase i, |A i j| * ‖x - xstar‖ := by
        refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun j _ => ?_)
        rw [abs_mul]
        refine mul_le_mul_of_nonneg_left ?_ (abs_nonneg _)
        rw [abs_sub_comm]
        exact coord_le_norm (x - xstar) j
    _ = (∑ j ∈ Finset.univ.erase i, |A i j|) * ‖x - xstar‖ := by rw [Finset.sum_mul]
    _ ≤ (dominanceRatio A * |A i i|) * ‖x - xstar‖ :=
        mul_le_mul_of_nonneg_right (sum_off_le A hA i) (norm_nonneg _)
    _ = dominanceRatio A * ‖x - xstar‖ * |A i i| := by ring

lemma iterate_bound (f : (Fin n → ℝ) → (Fin n → ℝ)) (xstar : Fin n → ℝ) (q : ℝ) (hq : 0 ≤ q)
    (hf : ∀ x, ‖f x - xstar‖ ≤ q * ‖x - xstar‖) (x0 : Fin n → ℝ) (k : ℕ) :
    ‖f^[k] x0 - xstar‖ ≤ q ^ k * ‖x0 - xstar‖ := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [Function.iterate_succ_apply', pow_succ]
    calc ‖f (f^[k] x0) - xstar‖ ≤ q * ‖f^[k] x0 - xstar‖ := hf _
      _ ≤ q * (q ^ k * ‖x0 - xstar‖) := mul_le_mul_of_nonneg_left ih hq
      _ = q ^ k * q * ‖x0 - xstar‖ := by ring

lemma iterate_tendsto (f : (Fin n → ℝ) → (Fin n → ℝ)) (xstar : Fin n → ℝ) (q : ℝ) (hq : 0 ≤ q)
    (hq1 : q < 1) (x0 : Fin n → ℝ) (h : ∀ k : ℕ, ‖f^[k] x0 - xstar‖ ≤ q ^ k * ‖x0 - xstar‖) :
    Tendsto (fun k : ℕ => f^[k] x0) atTop (𝓝 xstar) := by
  rw [tendsto_iff_norm_sub_tendsto_zero]
  refine squeeze_zero (fun k => norm_nonneg _) h ?_
  simpa using (tendsto_pow_atTop_nhds_zero_of_lt_one hq hq1).mul_const ‖x0 - xstar‖

lemma sum_erase_split (f : Fin n → ℝ) (i : Fin n) :
    ∑ j ∈ Finset.univ.erase i, f j =
      ∑ j ∈ Finset.univ.filter (fun j => j < i), f j +
        ∑ j ∈ Finset.univ.filter (fun j => i < j), f j := by
  rw [← Finset.sum_filter_add_sum_filter_not (Finset.univ.erase i) (fun j => j < i)]
  congr 1
  · congr 1; ext j; simp only [Finset.mem_filter, Finset.mem_erase, Finset.mem_univ, and_true,
      true_and]
    exact ⟨fun h => h.2, fun h => ⟨ne_of_lt h, h⟩⟩
  · congr 1; ext j; simp only [Finset.mem_filter, Finset.mem_erase, Finset.mem_univ, and_true,
      true_and, not_lt]
    exact ⟨fun h => lt_of_le_of_ne h.2 (Ne.symm h.1), fun h => ⟨ne_of_gt h, le_of_lt h⟩⟩

lemma gs_coord (A : Matrix (Fin n) (Fin n) ℝ) (b xstar : Fin n → ℝ)
    (hA : StrictlyDiagDominant A) (hx : A *ᵥ xstar = b) (x : Fin n → ℝ) :
    ∀ m : ℕ, ∀ i : Fin n, i.val = m →
      |gaussSeidelSweep.go A b x i - xstar i| ≤ dominanceRatio A * ‖x - xstar‖ := by
  intro m
  induction m using Nat.strong_induction_on with
  | _ m ih =>
  intro i hi
  set E := ‖x - xstar‖
  set q := dominanceRatio A
  have hq0 := dominanceRatio_nonneg A
  have hq1 := dominanceRatio_lt_one A hA
  have hE : 0 ≤ E := norm_nonneg _
  have hAi := sdd_diag_pos A hA i
  have hAi' : A i i ≠ 0 := abs_pos.1 hAi
  have hsub : ∑ j : {j : Fin n // j < i}, A i j * gaussSeidelSweep.go A b x j.1 =
      ∑ j ∈ Finset.univ.filter (fun j => j < i), A i j * gaussSeidelSweep.go A b x j :=
    (Finset.sum_subtype _ (by simp) (fun j => A i j * gaussSeidelSweep.go A b x j)).symm
  have hb : b i = A i i * xstar i + (∑ j ∈ Finset.univ.filter (fun j => j < i), A i j * xstar j +
        ∑ j ∈ Finset.univ.filter (fun j => i < j), A i j * xstar j) := by
    rw [← sum_erase_split, ← hx]; simp only [mulVec, dotProduct]
    exact (Finset.add_sum_erase _ (fun j => A i j * xstar j) (Finset.mem_univ i)).symm
  have key : gaussSeidelSweep.go A b x i - xstar i =
      (∑ j ∈ Finset.univ.filter (fun j => j < i),
          A i j * (xstar j - gaussSeidelSweep.go A b x j) +
        ∑ j ∈ Finset.univ.filter (fun j => i < j), A i j * (xstar j - x j)) / A i i := by
    rw [gaussSeidelSweep.go, hsub, hb]
    simp only [mul_sub, Finset.sum_sub_distrib]
    field_simp
    ring
  rw [key, abs_div, div_le_iff₀ hAi]
  calc _ ≤ ∑ j ∈ Finset.univ.filter (fun j => j < i), |A i j| * E +
        ∑ j ∈ Finset.univ.filter (fun j => i < j), |A i j| * E := by
        refine (abs_add_le _ _).trans (add_le_add ?_ ?_)
        · refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun j hj => ?_)
          rw [abs_mul]
          refine mul_le_mul_of_nonneg_left ?_ (abs_nonneg _)
          have hj' : j < i := (Finset.mem_filter.1 hj).2
          rw [abs_sub_comm]
          refine (ih j.val (hi ▸ hj') j rfl).trans ?_
          calc q * E ≤ 1 * E := mul_le_mul_of_nonneg_right hq1.le hE
            _ = E := one_mul E
        · refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun j _ => ?_)
          rw [abs_mul]
          refine mul_le_mul_of_nonneg_left ?_ (abs_nonneg _)
          rw [abs_sub_comm]
          exact coord_le_norm (x - xstar) j
    _ = (∑ j ∈ Finset.univ.erase i, |A i j|) * E := by
        rw [sum_erase_split, add_mul, Finset.sum_mul, Finset.sum_mul]
    _ ≤ (q * |A i i|) * E := mul_le_mul_of_nonneg_right (sum_off_le A hA i) hE
    _ = q * E * |A i i| := by ring

lemma gs_step (A : Matrix (Fin n) (Fin n) ℝ) (b xstar : Fin n → ℝ)
    (hA : StrictlyDiagDominant A) (hx : A *ᵥ xstar = b) (x : Fin n → ℝ) :
    ‖gaussSeidelSweep A b x - xstar‖ ≤ dominanceRatio A * ‖x - xstar‖ := by
  refine (pi_norm_le_iff_of_nonneg
    (mul_nonneg (dominanceRatio_nonneg A) (norm_nonneg _))).2 fun i => ?_
  rw [Real.norm_eq_abs]
  exact gs_coord A b xstar hA hx x i.val i rfl

lemma quad_conj (U : Matrix (Fin n) (Fin n) ℝ) (d v : Fin n → ℝ) :
    v ⬝ᵥ ((U * diagonal d * star U) *ᵥ v) = ∑ i, d i * (star U *ᵥ v) i ^ 2 := by
  rw [← mulVec_mulVec, ← mulVec_mulVec, dotProduct_mulVec, ← mulVec_transpose,
    star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial]
  simp only [dotProduct, mulVec_diagonal]
  exact Finset.sum_congr rfl fun i _ => by ring

lemma conj_mulVec (U : Matrix (Fin n) (Fin n) ℝ) (hU : star U * U = 1) (f e : Fin n → ℝ) :
    star U *ᵥ ((U * diagonal f * star U) *ᵥ e) = fun i => f i * (star U *ᵥ e) i := by
  rw [mulVec_mulVec]
  simp only [← Matrix.mul_assoc, hU, Matrix.one_mul]
  rw [← mulVec_mulVec]
  ext i
  simp [mulVec_diagonal]

lemma aeval_spectral (A : Matrix (Fin n) (Fin n) ℝ) (hH : A.IsHermitian) (p : ℝ[X]) :
    aeval A p = (hH.eigenvectorUnitary : Matrix (Fin n) (Fin n) ℝ) *
      diagonal (fun i => p.eval (hH.eigenvalues i)) *
      star (hH.eigenvectorUnitary : Matrix (Fin n) (Fin n) ℝ) := by
  have h := congrArg (fun M => aeval M p) hH.spectral_theorem
  rw [h, aeval_algHom_apply, Unitary.conjStarAlgAut_apply]
  congr 2
  have hd : diagonal (RCLike.ofReal ∘ hH.eigenvalues) =
      diagonalAlgHom ℝ (fun i => hH.eigenvalues i) := by
    show diagonal _ = diagonal _
    congr 1
  rw [hd, aeval_algHom_apply, aeval_pi_apply]
  rfl

lemma A_spectral (A : Matrix (Fin n) (Fin n) ℝ) (hH : A.IsHermitian) :
    A = (hH.eigenvectorUnitary : Matrix (Fin n) (Fin n) ℝ) *
      diagonal (fun i => hH.eigenvalues i) *
      star (hH.eigenvectorUnitary : Matrix (Fin n) (Fin n) ℝ) := by
  conv_lhs => rw [hH.spectral_theorem]
  rw [Unitary.conjStarAlgAut_apply]
  congr 2

lemma energy_bound (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.PosDef) (p : ℝ[X]) (c : ℝ)
    (hc : 0 ≤ c) (hpos : ∀ i, 0 ≤ hA.isHermitian.eigenvalues i)
    (hp : ∀ i, |p.eval (hA.isHermitian.eigenvalues i)| ≤ c) (e : Fin n → ℝ) :
    energyNorm A (aeval A p *ᵥ e) ≤ c * energyNorm A e := by
  set hH := hA.isHermitian
  set U : Matrix (Fin n) (Fin n) ℝ := (hH.eigenvectorUnitary : Matrix (Fin n) (Fin n) ℝ)
  have hU : star U * U = 1 := Unitary.star_mul_self_of_mem hH.eigenvectorUnitary.2
  set d := hH.eigenvalues
  have hA' := A_spectral A hH
  have hq : ∀ v, v ⬝ᵥ (A *ᵥ v) = ∑ i, d i * (star U *ᵥ v) i ^ 2 := by
    intro v
    have : A *ᵥ v = (U * diagonal d * star U) *ᵥ v := congrArg (· *ᵥ v) hA'
    rw [this, quad_conj]
  rw [energyNorm, energyNorm, hq, hq, aeval_spectral A hH p, conj_mulVec U hU]
  rw [← Real.sqrt_sq hc, ← Real.sqrt_mul (sq_nonneg c)]
  apply Real.sqrt_le_sqrt
  rw [Finset.mul_sum]
  refine Finset.sum_le_sum fun i _ => ?_
  have h1 : (p.eval (d i)) ^ 2 ≤ c ^ 2 := by
    rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) (hp i) 2
  have h2 : 0 ≤ d i * (star U *ᵥ e) i ^ 2 := mul_nonneg (hpos i) (sq_nonneg _)
  calc d i * (p.eval (d i) * (star U *ᵥ e) i) ^ 2
      = (p.eval (d i)) ^ 2 * (d i * (star U *ᵥ e) i ^ 2) := by ring
    _ ≤ c ^ 2 * (d i * (star U *ᵥ e) i ^ 2) := mul_le_mul_of_nonneg_right h1 h2

open Polynomial.Chebyshev in
lemma cheb_abs_le_one (k : ℕ) (x : ℝ) (hx : |x| ≤ 1) : |(T ℝ (k : ℤ)).eval x| ≤ 1 := by
  obtain ⟨h1, h2⟩ := abs_le.1 hx
  rw [← Real.cos_arccos h1 h2, T_real_cos]
  exact Real.abs_cos_le_one _

open Polynomial.Chebyshev in
lemma cheb_poly (a b : ℝ) (ha : 0 < a) (hab : a ≤ b) (k : ℕ) :
    ∃ p : ℝ[X], p.natDegree ≤ k ∧ p.eval 0 = 1 ∧ ∀ x, a ≤ x → x ≤ b →
      |p.eval x| ≤ 2 * ((Real.sqrt (b / a) - 1) / (Real.sqrt (b / a) + 1)) ^ k := by
  rcases hab.eq_or_lt with rfl | hab
  · refine ⟨(1 - C (1 / a) * X) ^ k, ?_, ?_, ?_⟩
    · refine (natDegree_pow_le_of_le k
        (show (1 - C (1 / a) * X : ℝ[X]).natDegree ≤ 1 by compute_degree!)).trans (by simp)
    · simp
    · intro x h1 h2
      have hx : x = a := le_antisymm h2 h1
      subst hx
      rw [div_self ha.ne', Real.sqrt_one]
      have : eval x (1 - C (1 / x) * X) = 0 := by
        simp [ha.ne']
      rw [eval_pow, this]
      rcases k with _ | k <;> simp
  · set s := Real.sqrt (b / a) with hs
    have hba : 1 < b / a := (one_lt_div ha).2 hab
    have hs1 : 1 < s := by
      rw [hs, show (1:ℝ) = Real.sqrt 1 by simp]
      exact Real.sqrt_lt_sqrt zero_le_one hba
    have hss : s ^ 2 = b / a := Real.sq_sqrt (by positivity)
    set y := (s + 1) / (s - 1) with hy
    have hy0 : 0 < y := div_pos (by linarith) (by linarith)
    set u := Real.log y
    set x0 := (b + a) / (b - a) with hx0
    have hcosh : Real.cosh u = x0 := by
      rw [Real.cosh_eq, Real.exp_neg, Real.exp_log hy0, hx0, hy]
      have hbab : b = s ^ 2 * a := by rw [hss]; field_simp
      rw [hbab]
      have h1 : s - 1 ≠ 0 := by linarith
      have h2 : s + 1 ≠ 0 := by linarith
      have h3 : s ^ 2 * a - a ≠ 0 := by
        have : s ^ 2 * a - a = (s - 1) * (s + 1) * a := by ring
        rw [this]; exact mul_ne_zero (mul_ne_zero h1 h2) ha.ne'
      have h4 : s ^ 2 - 1 ≠ 0 := by
        have : s ^ 2 - 1 = (s - 1) * (s + 1) := by ring
        rw [this]; exact mul_ne_zero h1 h2
      rw [show s ^ 2 * a + a = (s ^ 2 + 1) * a by ring, show s ^ 2 * a - a = (s ^ 2 - 1) * a by ring,
        mul_div_mul_right _ _ ha.ne', inv_div, div_add_div _ _ h1 h2, div_div,
        div_eq_div_iff (mul_ne_zero (mul_ne_zero h1 h2) two_ne_zero) h4]
      ring
    set τ := (T ℝ (k : ℤ)).eval x0 with hτ
    have hτ_ge : y ^ k / 2 ≤ τ := by
      rw [hτ, ← hcosh, T_real_cosh, Real.cosh_eq]
      have : Real.exp (((k : ℤ) : ℝ) * u) = y ^ k := by
        rw [show (((k : ℤ) : ℝ)) = (k : ℝ) by push_cast; rfl, Real.exp_nat_mul,
          Real.exp_log hy0]
      rw [this]
      have : 0 < Real.exp (-(((k : ℤ) : ℝ) * u)) := Real.exp_pos _
      linarith
    have hτ0 : 0 < τ := lt_of_lt_of_le (by positivity) hτ_ge
    refine ⟨C (1 / τ) * (T ℝ (k : ℤ)).comp (C x0 - C (2 / (b - a)) * X), ?_, ?_, ?_⟩
    · refine (natDegree_C_mul_le _ _).trans ?_
      refine natDegree_comp_le.trans ?_
      rw [natDegree_T]
      have : (C x0 - C (2 / (b - a)) * X).natDegree ≤ 1 := by compute_degree!
      simpa using Nat.mul_le_mul_left k this
    · simp only [eval_mul, eval_C, eval_comp, eval_sub, eval_X, mul_zero, sub_zero]
      rw [← hτ]; field_simp
    · intro x h1 h2
      simp only [eval_mul, eval_C, eval_comp, eval_sub, eval_X]
      have hba' : 0 < b - a := by linarith
      have ht : |x0 - 2 / (b - a) * x| ≤ 1 := by
        have : x0 - 2 / (b - a) * x = (b + a - 2 * x) / (b - a) := by
          rw [hx0]; field_simp
        rw [this, abs_le, le_div_iff₀ hba', div_le_iff₀ hba']
        constructor <;> linarith
      rw [abs_mul, abs_of_pos (by positivity : (0:ℝ) < 1 / τ)]
      have hT := cheb_abs_le_one k _ ht
      have hr : (s - 1) / (s + 1) = 1 / y := by rw [hy, one_div_div]
      rw [hr, div_pow, one_pow]
      calc 1 / τ * |(T ℝ (k : ℤ)).eval (x0 - 2 / (b - a) * x)| ≤ 1 / τ * 1 :=
            mul_le_mul_of_nonneg_left hT (by positivity)
        _ = 1 / τ := mul_one _
        _ ≤ 1 / (y ^ k / 2) := one_div_le_one_div_of_le (by positivity) hτ_ge
        _ = 2 * (1 / y ^ k) := by field_simp

/-- **Jacobi converges for a strictly diagonally dominant matrix.**
Let `A` be strictly diagonally dominant by rows, and let `x*` solve `A x* = b`. Then the
dominance ratio `q` is below 1, and from every start `x⁽⁰⁾` the Jacobi sweeps satisfy
`‖x⁽ᵏ⁾ − x*‖∞ ≤ q^k ‖x⁽⁰⁾ − x*‖∞` for every `k` (the norm on `Fin n → ℝ` is the max norm),
so they converge to `x*`. -/
theorem jacobi_converges_of_strictly_diag_dominant (A : Matrix (Fin n) (Fin n) ℝ)
    (b xstar : Fin n → ℝ) (hA : StrictlyDiagDominant A) (hx : A *ᵥ xstar = b)
    (x0 : Fin n → ℝ) :
    dominanceRatio A < 1 ∧
    (∀ k : ℕ, ‖(jacobiSweep A b)^[k] x0 - xstar‖ ≤ dominanceRatio A ^ k * ‖x0 - xstar‖) ∧
    Tendsto (fun k : ℕ => (jacobiSweep A b)^[k] x0) atTop (𝓝 xstar) := by
  have hk := iterate_bound (jacobiSweep A b) xstar _ (dominanceRatio_nonneg A)
    (jacobi_step A b xstar hA hx) x0
  exact ⟨dominanceRatio_lt_one A hA, hk, iterate_tendsto _ xstar _ (dominanceRatio_nonneg A)
    (dominanceRatio_lt_one A hA) x0 hk⟩

/-- **Gauss-Seidel obeys the same dominance bound.**
Let `A` be strictly diagonally dominant by rows, and let `x*` solve `A x* = b`. Then from every
start `x⁽⁰⁾` the Gauss-Seidel sweeps satisfy `‖x⁽ᵏ⁾ − x*‖∞ ≤ q^k ‖x⁽⁰⁾ − x*‖∞` for every `k`,
with `q` the dominance ratio, so they converge to `x*`. -/
theorem gauss_seidel_converges_of_strictly_diag_dominant (A : Matrix (Fin n) (Fin n) ℝ)
    (b xstar : Fin n → ℝ) (hA : StrictlyDiagDominant A) (hx : A *ᵥ xstar = b)
    (x0 : Fin n → ℝ) :
    (∀ k : ℕ, ‖(gaussSeidelSweep A b)^[k] x0 - xstar‖ ≤ dominanceRatio A ^ k * ‖x0 - xstar‖) ∧
    Tendsto (fun k : ℕ => (gaussSeidelSweep A b)^[k] x0) atTop (𝓝 xstar) := by
  have hk := iterate_bound (gaussSeidelSweep A b) xstar _ (dominanceRatio_nonneg A)
    (gs_step A b xstar hA hx) x0
  exact ⟨hk, iterate_tendsto _ xstar _ (dominanceRatio_nonneg A)
    (dominanceRatio_lt_one A hA) x0 hk⟩

/-- **The conjugate gradient bound, from a stretched Chebyshev polynomial.**
Let `A` be symmetric positive definite, with every eigenvalue between `λmin > 0` and `λmax`, and
let `κ = λmax / λmin`. Then for every number of steps `k` there is a polynomial `p` of degree at
most `k` with `p(0) = 1` that shrinks every error in the energy norm by the factor
`2((√κ − 1)/(√κ + 1))^k`: `‖p(A) e‖_A ≤ 2((√κ − 1)/(√κ + 1))^k ‖e‖_A`. Conjugate gradient's
error after `k` steps is `p_k(A) e₀` for the allowed polynomial with the smallest `‖p_k(A) e₀‖_A`,
so `‖e_k‖_A ≤ 2((√κ − 1)/(√κ + 1))^k ‖e₀‖_A`. -/
theorem conjugate_gradient_chebyshev_bound (A : Matrix (Fin n) (Fin n) ℝ) (hA : A.PosDef)
    (lmin lmax : ℝ) (hlmin : 0 < lmin)
    (heig : ∀ i, lmin ≤ hA.isHermitian.eigenvalues i ∧ hA.isHermitian.eigenvalues i ≤ lmax)
    (k : ℕ) :
    ∃ p : ℝ[X], p.natDegree ≤ k ∧ p.eval 0 = 1 ∧
      ∀ e : Fin n → ℝ, energyNorm A (aeval A p *ᵥ e) ≤
        2 * ((Real.sqrt (lmax / lmin) - 1) / (Real.sqrt (lmax / lmin) + 1)) ^ k *
          energyNorm A e := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · refine ⟨1, by simp, by simp, fun e => ?_⟩
    simp [energyNorm, dotProduct]
  · have hab : lmin ≤ lmax := (heig ⟨0, hn⟩).1.trans (heig ⟨0, hn⟩).2
    obtain ⟨p, hpdeg, hp0, hpb⟩ := cheb_poly lmin lmax hlmin hab k
    refine ⟨p, hpdeg, hp0, fun e => ?_⟩
    have hs1 : 1 ≤ Real.sqrt (lmax / lmin) := by
      rw [show (1:ℝ) = Real.sqrt 1 by simp]
      exact Real.sqrt_le_sqrt ((one_le_div hlmin).2 hab)
    have hc : 0 ≤ 2 * ((Real.sqrt (lmax / lmin) - 1) / (Real.sqrt (lmax / lmin) + 1)) ^ k := by
      have : 0 ≤ (Real.sqrt (lmax / lmin) - 1) / (Real.sqrt (lmax / lmin) + 1) :=
        div_nonneg (by linarith) (by linarith)
      positivity
    exact energy_bound A hA p _ hc (fun i => hlmin.le.trans (heig i).1)
      (fun i => hpb _ (heig i).1 (heig i).2) e

/-! ## The card's whole-number and exact worked examples -/

-- The network: 10 rows of 24 pipes and 9 rows of 25 between junctions, plus 25 + 10 from the main.
example : 10 * 24 + 9 * 25 = 465 ∧ 465 + 25 + 10 = 500 := by norm_num
-- Nonzeros of A: one diagonal entry per junction and two entries per pipe between junctions.
example : 250 + 2 * 465 = 1180 ∧ 250 * 250 = 62500 := by norm_num
-- Flops per step: a sweep, and a conjugate gradient step, from the 1,180 nonzeros at n = 250.
example : 2 * (1180 - 250) + 250 = 2110 ∧
    (2 * 1180 - 250) + 2 * (2 * 250 - 1) + 3 * 2 * 250 + 2 = 4610 := by norm_num
-- Cost to settle: Jacobi 471 sweeps, Gauss-Seidel 233 sweeps, CG 57 steps, SOR 44 sweeps.
example : 471 * 2110 = 993810 ∧ 233 * 2110 = 491630 ∧ 57 * 4610 = 262770 ∧
    44 * (2110 + 3 * 250) = 125840 := by norm_num
-- A dense Cholesky factorisation and its two solves at n = 250.
example : (2 * 250 ^ 3 + 3 * 250 ^ 2 + 250) / 6 = 5239625 := by norm_num
-- The dominance ratio at a junction with four pipes: 4 ÷ 4.1 = 40/41.
example : (4 : ℚ) / (4 + 1 / 10) = 40 / 41 := by norm_num
-- First Jacobi sweep at the corner: 100 ÷ 4.1; first Gauss-Seidel values at (0, 1) and (1, 1).
example : (100 : ℚ) / (41 / 10) = 1000 / 41 ∧
    ((50 : ℚ) + 1000 / 41) / (41 / 10) = 30500 / 1681 ∧
    ((30500 : ℚ) / 1681 + 30500 / 1681) / (41 / 10) = 610000 / 68921 := by norm_num

/-- The card's 3-by-3 matrix with 1 on the diagonal and 0.8 elsewhere. -/
noncomputable def badMatrix : Matrix (Fin 3) (Fin 3) ℝ :=
  !![1, 4/5, 4/5; 4/5, 1, 4/5; 4/5, 4/5, 1]

-- Its eigenvalues 2.6, 0.2 and 0.2, at (1, 1, 1), (1, −1, 0) and (1, 1, −2).
example : badMatrix *ᵥ ![1, 1, 1] = (13 / 5 : ℝ) • ![1, 1, 1] := by
  ext i; fin_cases i <;> simp [badMatrix, mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num
example : badMatrix *ᵥ ![1, -1, 0] = (1 / 5 : ℝ) • ![1, -1, 0] := by
  ext i; fin_cases i <;> simp [badMatrix, mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num
example : badMatrix *ᵥ ![1, 1, -2] = (1 / 5 : ℝ) • ![1, 1, -2] := by
  ext i; fin_cases i <;> simp [badMatrix, mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num
-- It is not diagonally dominant: 0.8 + 0.8 outweighs 1.
example : ¬ StrictlyDiagDominant badMatrix := by
  intro h
  have h0 := h 0
  rw [Finset.sum_erase_eq_sub (Finset.mem_univ _), Fin.sum_univ_three] at h0
  simp [badMatrix] at h0
  norm_num [abs_of_pos] at h0
-- One Jacobi sweep on the error (b = 0) multiplies the error (1, 1, 1) by −1.6.
example : jacobiSweep badMatrix 0 ![1, 1, 1] = (-8 / 5 : ℝ) • ![1, 1, 1] := by
  ext i
  fin_cases i <;>
  simp [jacobiSweep, badMatrix, Finset.sum_erase_eq_sub, Fin.sum_univ_three] <;> norm_num

#print axioms jacobi_converges_of_strictly_diag_dominant
#print axioms gauss_seidel_converges_of_strictly_diag_dominant
#print axioms conjugate_gradient_chebyshev_bound
#print axioms sdd_diag_pos
#print axioms dominanceRatio_nonneg
#print axioms dominanceRatio_lt_one
#print axioms sum_off_le
#print axioms coord_le_norm
#print axioms jacobi_step
#print axioms iterate_bound
#print axioms iterate_tendsto
#print axioms sum_erase_split
#print axioms gs_coord
#print axioms gs_step
#print axioms quad_conj
#print axioms conj_mulVec
#print axioms aeval_spectral
#print axioms A_spectral
#print axioms energy_bound
#print axioms cheb_abs_le_one
#print axioms cheb_poly
