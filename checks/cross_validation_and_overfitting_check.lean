-- Overfitting: a least-squares fit's training error falls short of its error on repeat readings at the same points by 2σ²p/n on average, and best-fit training error never rises as the polynomial degree goes up, reaching zero once there are as many coefficients as readings.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Probability.Notation
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.RingTheory.Polynomial.Basic
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Tactic

open MeasureTheory Matrix Polynomial

lemma cvo_sq_expand {κ : Type*} [Fintype κ] (u : ℝ) (c z : κ → ℝ) :
    (u + ∑ k, c k * z k) ^ 2
      = u ^ 2 + ∑ k, 2 * u * c k * z k + ∑ k, ∑ l, c k * c l * (z k * z l) := by
  have h1 : 2 * u * ∑ k, c k * z k = ∑ k, 2 * u * c k * z k := by
    rw [Finset.mul_sum]; exact Finset.sum_congr rfl fun k _ => by ring
  have h2 : (∑ k, c k * z k) ^ 2 = ∑ k, ∑ l, c k * c l * (z k * z l) := by
    rw [sq, Finset.sum_mul_sum]
    exact Finset.sum_congr rfl fun k _ => Finset.sum_congr rfl fun l _ => by ring
  rw [add_sq, h1, h2]

lemma cvo_expect {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (volume : Measure Ω)]
    {ι κ : Type*} [Fintype ι] [Fintype κ] [DecidableEq κ] (σ : ℝ) (Z : κ → Ω → ℝ)
    (hZ : ∀ k, MemLp (Z k) 2) (hm : ∀ k, ∫ ω, Z k ω = 0)
    (hc : ∀ k l, ∫ ω, Z k ω * Z l ω = if k = l then σ ^ 2 else 0)
    (u : ι → ℝ) (C : ι → κ → ℝ) :
    ∫ ω, ∑ i, (u i + ∑ k, C i k * Z k ω) ^ 2
      = ∑ i, u i ^ 2 + σ ^ 2 * ∑ i, ∑ k, C i k ^ 2 := by
  have hint : ∀ k, Integrable (Z k) := fun k => (hZ k).integrable one_le_two
  have hint2 : ∀ k l, Integrable (fun ω => Z k ω * Z l ω) := fun k l =>
    (hZ k).integrable_mul (hZ l)
  have hA : ∀ i, Integrable (fun ω => ∑ k, 2 * u i * C i k * Z k ω) := fun i =>
    integrable_finsetSum _ fun k _ => (hint k).const_mul _
  have hB : ∀ i, Integrable (fun ω => ∑ k, ∑ l, C i k * C i l * (Z k ω * Z l ω)) := fun i =>
    integrable_finsetSum _ fun k _ => integrable_finsetSum _ fun l _ => (hint2 k l).const_mul _
  have hI : ∀ i, Integrable (fun ω => u i ^ 2 + ∑ k, 2 * u i * C i k * Z k ω
      + ∑ k, ∑ l, C i k * C i l * (Z k ω * Z l ω)) := fun i =>
    ((integrable_const _).add (hA i)).add (hB i)
  simp_rw [cvo_sq_expand]
  rw [integral_finsetSum _ (fun i _ => hI i)]
  rw [Finset.mul_sum, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  have hC : Integrable (fun ω => u i ^ 2 + ∑ k, 2 * u i * C i k * Z k ω) :=
    (integrable_const _).add (hA i)
  rw [integral_add hC (hB i), integral_add (integrable_const _) (hA i), integral_const,
    integral_finsetSum _ fun k _ => (hint k).const_mul _,
    integral_finsetSum _ fun k _ => integrable_finsetSum _ fun l _ => (hint2 k l).const_mul _]
  simp_rw [integral_finsetSum _ fun l _ => (hint2 _ l).const_mul _, integral_const_mul, hm, hc]
  simp [mul_ite, Finset.mul_sum, sq]
  exact Finset.sum_congr rfl fun k _ => by ring

lemma cvo_trace_hat {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (hX : X.rank = p) :
    ∑ i, (X * (Xᵀ * X)⁻¹ * Xᵀ) i i = p := by
  have hr : (Xᵀ * X).rank = Fintype.card (Fin p) := by
    rw [rank_transpose_mul_self, hX, Fintype.card_fin]
  have hu : IsUnit (Xᵀ * X) := mulVec_surjective_iff_isUnit.mp (mulVec_surjective_iff_rank_eq_card.mpr hr)
  have hd : IsUnit (Xᵀ * X).det := (isUnit_iff_isUnit_det _).mp hu
  have : ∑ i, (X * (Xᵀ * X)⁻¹ * Xᵀ) i i = trace (X * (Xᵀ * X)⁻¹ * Xᵀ) := rfl
  rw [this, trace_mul_comm, ← Matrix.mul_assoc, mul_nonsing_inv _ hd, trace_one, Fintype.card_fin]

lemma cvo_err_nonneg {n : ℕ} (t y : Fin n → ℝ) (q : ℝ[X]) :
    0 ≤ (1 / (n : ℝ)) * ∑ i, (y i - q.eval (t i)) ^ 2 := by
  positivity

#print axioms cvo_sq_expand
#print axioms cvo_expect
#print axioms cvo_trace_hat
#print axioms cvo_err_nonneg

/-- The optimism of training error. Readings are `y i = f i + ε i` at `n` points, where the noises
have mean zero, variance `σ²` and no two are correlated. Repeat readings `y' i = f i + ε' i` at the
same points carry fresh noise with the same properties, uncorrelated with every `ε j`. The fit is
least squares on an `n × p` design matrix `X` of full column rank, so the fitted values are
`ŷ = H y` with hat matrix `H = X (XᵀX)⁻¹ Xᵀ`. Then the expected average squared error on the
repeat readings exceeds the expected training error (the average squared residual) by exactly
`2σ²p/n`. -/
theorem training_error_optimism_eq_two_sigma_sq_p_div_n
    {Ω : Type*} [MeasureSpace Ω] [IsProbabilityMeasure (volume : Measure Ω)]
    {n p : ℕ} (X : Matrix (Fin n) (Fin p) ℝ) (hX : X.rank = p)
    (f : Fin n → ℝ) (σ : ℝ) (ε ε' : Fin n → Ω → ℝ)
    (hε : ∀ i, MemLp (ε i) 2) (hε' : ∀ i, MemLp (ε' i) 2)
    (hmean : ∀ i, ∫ ω, ε i ω = 0) (hmean' : ∀ i, ∫ ω, ε' i ω = 0)
    (hcov : ∀ i j, ∫ ω, ε i ω * ε j ω = if i = j then σ ^ 2 else 0)
    (hcov' : ∀ i j, ∫ ω, ε' i ω * ε' j ω = if i = j then σ ^ 2 else 0)
    (hcross : ∀ i j, ∫ ω, ε' i ω * ε j ω = 0) :
    let H : Matrix (Fin n) (Fin n) ℝ := X * (Xᵀ * X)⁻¹ * Xᵀ
    let y : Fin n → Ω → ℝ := fun i ω => f i + ε i ω
    let y' : Fin n → Ω → ℝ := fun i ω => f i + ε' i ω
    let yhat : Fin n → Ω → ℝ := fun i ω => ∑ j, H i j * y j ω
    (∫ ω, (1 / (n : ℝ)) * ∑ i, (y' i ω - yhat i ω) ^ 2)
      - (∫ ω, (1 / (n : ℝ)) * ∑ i, (y i ω - yhat i ω) ^ 2)
      = 2 * σ ^ 2 * p / n := by
  intro H y y' yhat
  have htr : ∑ i, H i i = p := cvo_trace_hat X hX
  let Z : Fin n ⊕ Fin n → Ω → ℝ := Sum.elim ε ε'
  have hZ : ∀ k, MemLp (Z k) 2 := by
    rintro (k | k)
    · exact hε k
    · exact hε' k
  have hm : ∀ k, ∫ ω, Z k ω = 0 := by
    rintro (k | k)
    · exact hmean k
    · exact hmean' k
  have hc : ∀ k l, ∫ ω, Z k ω * Z l ω = if k = l then σ ^ 2 else 0 := by
    rintro (k | k) (l | l)
    · simpa [Z] using hcov k l
    · simp only [Z, Sum.elim_inl, Sum.elim_inr, reduceCtorEq, ite_false]
      simp_rw [mul_comm (ε k _)]
      exact hcross l k
    · simpa [Z] using hcross k l
    · simpa [Z] using hcov' k l
  let u : Fin n → ℝ := fun i => f i - ∑ j, H i j * f j
  let Ct : Fin n → Fin n ⊕ Fin n → ℝ := fun i =>
    Sum.elim (fun j => -H i j) (fun j => if i = j then 1 else 0)
  let Cr : Fin n → Fin n ⊕ Fin n → ℝ := fun i =>
    Sum.elim (fun j => (if i = j then 1 else 0) - H i j) (fun _ => 0)
  have ht : ∀ ω, ∑ i, (y' i ω - yhat i ω) ^ 2 = ∑ i, (u i + ∑ k, Ct i k * Z k ω) ^ 2 := by
    intro ω
    refine Finset.sum_congr rfl fun i _ => ?_
    congr 1
    simp only [y', yhat, y, u, Ct, Z, Fintype.sum_sum_type, Sum.elim_inl, Sum.elim_inr, mul_add,
      Finset.sum_add_distrib, ite_mul, one_mul, zero_mul, Finset.sum_ite_eq, Finset.mem_univ,
      ite_true, neg_mul, Finset.sum_neg_distrib]
    ring
  have hr : ∀ ω, ∑ i, (y i ω - yhat i ω) ^ 2 = ∑ i, (u i + ∑ k, Cr i k * Z k ω) ^ 2 := by
    intro ω
    refine Finset.sum_congr rfl fun i _ => ?_
    congr 1
    simp only [yhat, y, u, Cr, Z, Fintype.sum_sum_type, Sum.elim_inl, Sum.elim_inr, mul_add,
      Finset.sum_add_distrib, sub_mul, ite_mul, one_mul, zero_mul, Finset.sum_ite_eq,
      Finset.mem_univ, ite_true, Finset.sum_sub_distrib, Finset.sum_const_zero]
    ring
  simp_rw [integral_const_mul, ht, hr, cvo_expect σ Z hZ hm hc]
  have hsum : σ ^ 2 * ∑ i, ∑ k, Ct i k ^ 2 - σ ^ 2 * ∑ i, ∑ k, Cr i k ^ 2 = 2 * σ ^ 2 * p := by
    rw [← htr]
    simp only [Ct, Cr, Fintype.sum_sum_type, Sum.elim_inl, Sum.elim_inr, sub_sq, neg_sq,
      ite_pow, one_pow, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_ite, mul_one,
      mul_zero, ite_mul, zero_mul, Finset.sum_add_distrib, Finset.sum_sub_distrib,
      Finset.sum_ite_eq, Finset.mem_univ, ite_true, Finset.sum_const_zero, add_zero, Finset.mul_sum]
    ring_nf
    rw [Finset.mul_sum]
    exact Finset.sum_congr rfl fun _ _ => by ring
  linear_combination (1 / (n : ℝ)) * hsum

/-- Training error never rises with the degree. Fit polynomials by least squares to readings `y i`
at hours `t i`. The best training error over polynomials of degree at most `d'` is at most the best
over degree at most `d` whenever `d ≤ d'`: every polynomial of degree `d` is also one of degree `d'`
with zero top coefficients. -/
theorem best_training_error_antitone_in_degree
    {n : ℕ} (t y : Fin n → ℝ) {d d' : ℕ} (hdd' : d ≤ d') :
    (⨅ q : Polynomial.degreeLT ℝ (d' + 1), (1 / (n : ℝ)) * ∑ i, (y i - (q : ℝ[X]).eval (t i)) ^ 2)
      ≤ ⨅ q : Polynomial.degreeLT ℝ (d + 1), (1 / (n : ℝ)) * ∑ i, (y i - (q : ℝ[X]).eval (t i)) ^ 2 := by
  refine le_ciInf fun q => ?_
  have hq : (q : ℝ[X]) ∈ Polynomial.degreeLT ℝ (d' + 1) :=
    Polynomial.degreeLT_mono (by omega) q.2
  exact ciInf_le ⟨0, by rintro _ ⟨r, rfl⟩; exact cvo_err_nonneg t y r⟩ (⟨q, hq⟩ : Polynomial.degreeLT ℝ (d' + 1))

/-- As many coefficients as readings drive training error to zero. For `n` readings `y i` taken at
`n` different hours `t i`, the best training error over polynomials with `n` coefficients (degree at
most `n - 1`) is `0`: some such polynomial passes exactly through every reading. -/
theorem best_training_error_eq_zero_of_n_coefficients
    {n : ℕ} (t y : Fin n → ℝ) (ht : Function.Injective t) :
    (⨅ q : Polynomial.degreeLT ℝ n, (1 / (n : ℝ)) * ∑ i, (y i - (q : ℝ[X]).eval (t i)) ^ 2) = 0 := by
  have hinj : Set.InjOn t (Finset.univ : Finset (Fin n)) := ht.injOn
  have hdeg : Lagrange.interpolate Finset.univ t y ∈ Polynomial.degreeLT ℝ n := by
    rw [Polynomial.mem_degreeLT]
    simpa using Lagrange.degree_interpolate_lt y hinj
  refine le_antisymm ?_ (le_ciInf fun q => cvo_err_nonneg t y q)
  refine (ciInf_le ⟨0, by rintro _ ⟨r, rfl⟩; exact cvo_err_nonneg t y r⟩
    (⟨_, hdeg⟩ : Polynomial.degreeLT ℝ n)).trans (le_of_eq ?_)
  have hz : ∀ i, y i - (Lagrange.interpolate Finset.univ t y).eval (t i) = 0 := fun i => by
    rw [Lagrange.eval_interpolate_at_node y hinj (Finset.mem_univ i), sub_self]
  simp only [hz]
  simp

-- The card's optimism for the cubic: gauge noise σ = 3/10 m, p = 4 coefficients, n = 10 readings,
-- 2 × (3/10)² × 4 / 10 = 9/125 square metres (the card's 0.0720).
example : (2 * (3 / 10 : ℚ) ^ 2 * 4 / 10) = 9 / 125 := by norm_num

-- At degree 9, p = n = 10: the optimism is twice the noise variance, 9/50 (the card's 0.1800).
example : (2 * (3 / 10 : ℚ) ^ 2 * 10 / 10) = 2 * (3 / 10 : ℚ) ^ 2 := by norm_num
example : (2 * (3 / 10 : ℚ) ^ 2 * 10 / 10) = 9 / 50 := by norm_num

-- The five folds: fold k holds hours k and k + 5, and together they cover hours 0 to 9 once each.
example : (Finset.range 10).filter (fun h => h % 5 = 0) = {0, 5} := by decide
example : ((Finset.range 5).biUnion fun k => ({k, k + 5} : Finset ℕ)) = Finset.range 10 := by decide

#print axioms training_error_optimism_eq_two_sigma_sq_p_div_n
#print axioms best_training_error_antitone_in_degree
#print axioms best_training_error_eq_zero_of_n_coefficients
