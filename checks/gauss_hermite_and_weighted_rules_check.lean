-- Weighted Gauss rules: n nodes at the roots of the physicists' Hermite polynomial H_n, with positive weights, integrate e^(-x^2) times every polynomial of degree up to 2n - 1 exactly, fail on H_n^2, and fall short on x^(2n) by exactly sqrt(pi) n!/2^n.
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.Polynomial.Degree.Defs
import Mathlib.Data.Nat.Factorial.DoubleFactorial
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.MeasureTheory.Integral.IntegralEqImproper

open Polynomial MeasureTheory Real

/-- The physicists' Hermite polynomials, built by the card's recurrence:
`H_0 = 1`, `H_1 = 2x`, `H_(k+1) = 2x H_k - 2k H_(k-1)`.
(Mathlib's `Polynomial.hermite` is the probabilists' `He_n`, which the card does not use.) -/
noncomputable def physHermite : ℕ → ℝ[X]
  | 0 => 1
  | 1 => C 2 * X
  | (k + 2) => C 2 * X * physHermite (k + 1) - C (2 * ((k : ℝ) + 1)) * physHermite k

lemma gh_integrable (q : ℝ[X]) : Integrable (fun t : ℝ => exp (-t ^ 2) * q.eval t) := by
  have hmon : ∀ k : ℕ, Integrable (fun t : ℝ => exp (-t ^ 2) * t ^ k) := by
    intro k
    have hk : (-1 : ℝ) < (k : ℝ) := by have := k.cast_nonneg (α := ℝ); linarith
    have := integrable_rpow_mul_exp_neg_mul_sq (b := 1) one_pos hk
    simpa [Real.rpow_natCast, mul_comm] using this
  induction q using Polynomial.induction_on' with
  | add p q hp hq =>
    refine (hp.add hq).congr (Filter.Eventually.of_forall fun t => ?_)
    simp only [Pi.add_apply, eval_add, mul_add]
  | monomial n a =>
    have := (hmon n).const_mul a
    refine this.congr (Filter.Eventually.of_forall fun t => ?_)
    simp only [eval_monomial]; ring

lemma gh_int_add (p q : ℝ[X]) :
    ∫ t : ℝ, exp (-t ^ 2) * (p + q).eval t =
      (∫ t : ℝ, exp (-t ^ 2) * p.eval t) + ∫ t : ℝ, exp (-t ^ 2) * q.eval t := by
  simp only [eval_add, mul_add]
  exact integral_add (gh_integrable p) (gh_integrable q)

lemma gh_int_sub (p q : ℝ[X]) :
    ∫ t : ℝ, exp (-t ^ 2) * (p - q).eval t =
      (∫ t : ℝ, exp (-t ^ 2) * p.eval t) - ∫ t : ℝ, exp (-t ^ 2) * q.eval t := by
  simp only [eval_sub, mul_sub]
  exact integral_sub (gh_integrable p) (gh_integrable q)

lemma gh_int_C_mul (c : ℝ) (p : ℝ[X]) :
    ∫ t : ℝ, exp (-t ^ 2) * (C c * p).eval t = c * ∫ t : ℝ, exp (-t ^ 2) * p.eval t := by
  rw [← integral_const_mul]
  congr 1; funext t; simp only [eval_mul, eval_C]; ring

lemma gh_int_sum {ι : Type*} (s : Finset ι) (f : ι → ℝ[X]) :
    ∫ t : ℝ, exp (-t ^ 2) * (∑ i ∈ s, f i).eval t =
      ∑ i ∈ s, ∫ t : ℝ, exp (-t ^ 2) * (f i).eval t := by
  simp only [eval_finsetSum, Finset.mul_sum]
  exact integral_finsetSum s (fun i _ => gh_integrable (f i))

lemma gh_gauss : ∫ t : ℝ, exp (-t ^ 2) = √π := by
  simpa using integral_gaussian 1

lemma gh_deriv (n : ℕ) :
    derivative (physHermite (n + 1)) = C (2 * ((n : ℝ) + 1)) * physHermite n := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    rcases n with _ | _ | k
    · simp [physHermite]
    · simp [physHermite]; ring
    · have h1 := ih (k + 1) (by omega)
      have h0 := ih k (by omega)
      rw [show physHermite (k + 2 + 1) = C 2 * X * physHermite (k + 2)
          - C (2 * (((k + 1 : ℕ) : ℝ) + 1)) * physHermite (k + 1) from rfl]
      rw [derivative_sub, derivative_mul, derivative_mul, derivative_C_mul, h1]
      rw [show physHermite (k + 2) = C 2 * X * physHermite (k + 1)
          - C (2 * ((k : ℝ) + 1)) * physHermite k from rfl]
      simp only [derivative_C, derivative_X, h0]
      simp only [map_mul, map_add, map_natCast, map_ofNat, map_one, Nat.cast_add, Nat.cast_one]
      ring

lemma gh_succ (n : ℕ) :
    physHermite (n + 1) = C 2 * X * physHermite n - derivative (physHermite n) := by
  rcases n with _ | k
  · simp [physHermite]
  · rw [gh_deriv k]; rfl

lemma gh_hasDerivAt (n : ℕ) (t : ℝ) :
    HasDerivAt (fun t : ℝ => exp (-t ^ 2) * (physHermite n).eval t)
      (-(exp (-t ^ 2) * (physHermite (n + 1)).eval t)) t := by
  have h1 := ((hasDerivAt_pow 2 t).neg.exp).mul (Polynomial.hasDerivAt (physHermite n) t)
  convert h1 using 1
  rw [gh_succ]
  simp only [eval_sub, eval_mul, eval_C, eval_X, Pi.neg_apply]
  push_cast; ring

lemma gh_step (n : ℕ) (p : ℝ[X]) :
    ∫ t : ℝ, exp (-t ^ 2) * (physHermite (n + 1) * p).eval t =
      ∫ t : ℝ, exp (-t ^ 2) * (physHermite n * derivative p).eval t := by
  have key := integral_mul_deriv_eq_deriv_mul_of_integrable
    (u := fun t : ℝ => exp (-t ^ 2) * (physHermite n).eval t)
    (u' := fun t : ℝ => -(exp (-t ^ 2) * (physHermite (n + 1)).eval t))
    (v := fun t => p.eval t) (v' := fun t => (derivative p).eval t)
    (fun t _ => gh_hasDerivAt n t) (fun t _ => Polynomial.hasDerivAt p t)
    ((gh_integrable (physHermite n * derivative p)).congr
      (Filter.Eventually.of_forall fun t => by simp only [eval_mul, Pi.mul_apply]; ring))
    ((gh_integrable (physHermite (n + 1) * p)).neg.congr
      (Filter.Eventually.of_forall fun t => by simp only [eval_mul, Pi.mul_apply, Pi.neg_apply]; ring))
    ((gh_integrable (physHermite n * p)).congr
      (Filter.Eventually.of_forall fun t => by simp only [eval_mul, Pi.mul_apply]; ring))
  have e1 : (∫ t : ℝ, exp (-t ^ 2) * (physHermite n * derivative p).eval t) =
      ∫ t : ℝ, exp (-t ^ 2) * (physHermite n).eval t * (derivative p).eval t := by
    congr 1; funext t; simp only [eval_mul]; ring
  have e2 : (∫ t : ℝ, exp (-t ^ 2) * (physHermite (n + 1) * p).eval t) =
      - ∫ t : ℝ, -(exp (-t ^ 2) * (physHermite (n + 1)).eval t) * p.eval t := by
    rw [← integral_neg]; congr 1; funext t; simp only [eval_mul]; ring
  rw [e1, e2, key]

lemma gh_rodrigues (n : ℕ) (p : ℝ[X]) :
    ∫ t : ℝ, exp (-t ^ 2) * (physHermite n * p).eval t =
      ∫ t : ℝ, exp (-t ^ 2) * (derivative^[n] p).eval t := by
  induction n generalizing p with
  | zero => simp [physHermite]
  | succ n ih => rw [gh_step, ih, Function.iterate_succ_apply]

lemma gh_iter (n : ℕ) :
    derivative^[n] (physHermite n) = C ((2 : ℝ) ^ n * n.factorial) := by
  induction n with
  | zero => simp [physHermite]
  | succ n ih =>
    rw [Function.iterate_succ_apply, gh_deriv, iterate_derivative_C_mul, ih, ← C_mul]
    congr 1; push_cast [Nat.factorial_succ, pow_succ]; ring

lemma gh_orth (n : ℕ) (q : ℝ[X]) (hq : q.natDegree < n) :
    ∫ t : ℝ, exp (-t ^ 2) * (physHermite n * q).eval t = 0 := by
  rw [gh_rodrigues, iterate_derivative_eq_zero hq]; simp

lemma gh_norm (n : ℕ) :
    ∫ t : ℝ, exp (-t ^ 2) * (physHermite n * physHermite n).eval t =
      √π * 2 ^ n * n.factorial := by
  rw [gh_rodrigues, gh_iter]
  simp only [eval_C]
  rw [integral_mul_const, gh_gauss]; ring

lemma gh_natDegree_le (n : ℕ) : (physHermite n).natDegree ≤ n := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    rcases n with _ | _ | k
    · simp [physHermite]
    · simp only [physHermite]
      exact (natDegree_C_mul_le _ _).trans natDegree_X_le
    · show (C (2 : ℝ) * X * physHermite (k + 1) - C (2 * ((k : ℝ) + 1)) * physHermite k).natDegree ≤ k + 2
      refine (natDegree_sub_le _ _).trans (max_le ?_ ?_)
      · refine natDegree_mul_le.trans ?_
        have h1 : (C (2 : ℝ) * X).natDegree ≤ 1 := (natDegree_C_mul_le _ _).trans natDegree_X_le
        have h2 := ih (k + 1) (by omega)
        omega
      · exact (natDegree_C_mul_le _ _).trans ((ih k (by omega)).trans (by omega))

lemma gh_coeff (n : ℕ) : (physHermite n).coeff n = 2 ^ n := by
  have h := congrArg (fun p => coeff p 0) (gh_iter n)
  simp only [coeff_iterate_derivative, zero_add, Nat.descFactorial_self, coeff_C_zero,
    nsmul_eq_mul] at h
  have hf : (n.factorial : ℝ) ≠ 0 := by positivity
  have : (n.factorial : ℝ) * ((physHermite n).coeff n - (2 : ℝ) ^ n) = 0 := by rw [mul_sub, h]; ring
  rcases mul_eq_zero.mp this with h' | h'
  · exact absurd h' hf
  · linarith

lemma gh_natDegree (n : ℕ) : (physHermite n).natDegree = n :=
  le_antisymm (gh_natDegree_le n)
    (le_natDegree_of_ne_zero (by rw [gh_coeff]; positivity))

lemma gh_leadingCoeff (n : ℕ) : (physHermite n).leadingCoeff = 2 ^ n := by
  rw [leadingCoeff, gh_natDegree, gh_coeff]

lemma gh_pos (p : ℝ[X]) (hp : p ≠ 0) :
    0 < ∫ t : ℝ, exp (-t ^ 2) * (p * p).eval t := by
  have hnn : 0 ≤ fun t : ℝ => exp (-t ^ 2) * (p * p).eval t := fun t => by
    simp only [eval_mul]; exact mul_nonneg (exp_pos _).le (mul_self_nonneg _)
  rw [integral_pos_iff_support_of_nonneg hnn (gh_integrable _)]
  have hsub : (Function.support fun t : ℝ => exp (-t ^ 2) * (p * p).eval t)ᶜ ⊆
      (p.roots.toFinset : Set ℝ) := by
    intro t ht
    simp only [Set.mem_compl_iff, Function.mem_support, not_not, eval_mul, mul_eq_zero,
      (exp_pos _).ne', false_or, or_self] at ht
    simp [Polynomial.mem_roots hp, ht]
  have h0 := measure_mono_null hsub (Finset.measure_zero _ volume)
  rw [pos_iff_ne_zero]
  intro hS
  have := measure_union_null hS h0
  rw [Set.union_compl_self, Real.volume_univ] at this
  exact ENNReal.top_ne_zero this

#print axioms gh_integrable
#print axioms gh_int_add
#print axioms gh_int_sub
#print axioms gh_int_C_mul
#print axioms gh_int_sum
#print axioms gh_gauss
#print axioms gh_deriv
#print axioms gh_succ
#print axioms gh_hasDerivAt
#print axioms gh_step
#print axioms gh_rodrigues
#print axioms gh_iter
#print axioms gh_orth
#print axioms gh_norm
#print axioms gh_natDegree_le
#print axioms gh_coeff
#print axioms gh_natDegree
#print axioms gh_leadingCoeff
#print axioms gh_pos

/-- Gauss–Hermite exactness. Take n ≥ 1 distinct nodes `x i`, each a root of the physicists'
Hermite polynomial `H_n`. Then there are positive weights `w i` such that the rule
`∑ w i * g (x i)` gives `∫ e^(-t^2) g(t) dt` over the whole line with no error for every
polynomial `g` of degree at most `2n - 1`. -/
theorem gauss_hermite_exact_to_degree_two_n_sub_one (n : ℕ) (hn : 0 < n) (x : Fin n → ℝ)
    (hx : Function.Injective x) (hroot : ∀ i, (physHermite n).eval (x i) = 0) :
    ∃ w : Fin n → ℝ, (∀ i, 0 < w i) ∧
      ∀ g : ℝ[X], g.natDegree ≤ 2 * n - 1 →
        ∫ t : ℝ, exp (-t ^ 2) * g.eval t = ∑ i, w i * g.eval (x i) := by
  have hinj : Set.InjOn x (Finset.univ : Finset (Fin n)) := fun a _ b _ h => hx h
  have hcard : (Finset.univ : Finset (Fin n)).card = n := by rw [Finset.card_univ, Fintype.card_fin]
  have h2n : ((2 : ℝ) ^ n)⁻¹ ≠ 0 := by positivity
  have hM : (C ((2 : ℝ) ^ n)⁻¹ * physHermite n).Monic := by
    rw [Monic, leadingCoeff_mul, leadingCoeff_C, gh_leadingCoeff]
    exact inv_mul_cancel₀ (by positivity)
  have hMdeg : (C ((2 : ℝ) ^ n)⁻¹ * physHermite n).natDegree = n := by
    rw [natDegree_C_mul h2n, gh_natDegree]
  have hex : ∀ g : ℝ[X], g.natDegree ≤ 2 * n - 1 →
      ∫ t : ℝ, exp (-t ^ 2) * g.eval t =
        ∑ i, (∫ t : ℝ, exp (-t ^ 2) * (Lagrange.basis Finset.univ x i).eval t) * g.eval (x i) := by
    intro g hg
    set Mo := C ((2 : ℝ) ^ n)⁻¹ * physHermite n with hMo
    have hdecomp := modByMonic_add_div g Mo
    have hqdeg : (g /ₘ Mo).natDegree < n := by
      rw [natDegree_divByMonic g hM, hMdeg]; omega
    have hrdeg : (g %ₘ Mo).degree < (Finset.univ : Finset (Fin n)).card := by
      have := degree_modByMonic_lt g hM
      rwa [degree_eq_natDegree hM.ne_zero, hMdeg, ← hcard] at this
    have hinterp := Lagrange.eq_interpolate hinj hrdeg
    rw [Lagrange.interpolate_apply] at hinterp
    have horth : ∫ t : ℝ, exp (-t ^ 2) * (Mo * (g /ₘ Mo)).eval t = 0 := by
      rw [hMo, mul_assoc, gh_int_C_mul, gh_orth n _ hqdeg, mul_zero]
    have hval : ∀ i, g.eval (x i) = (g %ₘ Mo).eval (x i) := by
      intro i
      conv_lhs => rw [← hdecomp]
      simp [hMo, hroot i]
    conv_lhs => rw [← hdecomp]
    rw [gh_int_add, horth, add_zero, hinterp, gh_int_sum]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [gh_int_C_mul, hval i, mul_comm]
  refine ⟨fun i => ∫ t : ℝ, exp (-t ^ 2) * (Lagrange.basis Finset.univ x i).eval t, ?_, hex⟩
  intro i
  have hi : i ∈ (Finset.univ : Finset (Fin n)) := Finset.mem_univ i
  have hdeg : (Lagrange.basis Finset.univ x i * Lagrange.basis Finset.univ x i).natDegree
      ≤ 2 * n - 1 := by
    refine natDegree_mul_le.trans ?_
    rw [Lagrange.natDegree_basis hinj hi, hcard]; omega
  have h := hex _ hdeg
  rw [Finset.sum_eq_single i] at h
  · rw [eval_mul, Lagrange.eval_basis_self hinj hi, mul_one, mul_one] at h
    show 0 < ∫ t : ℝ, exp (-t ^ 2) * (Lagrange.basis Finset.univ x i).eval t
    rw [← h]
    exact gh_pos _ (Lagrange.basis_ne_zero hinj hi)
  · intro j _ hji
    rw [eval_mul, Lagrange.eval_basis_of_ne hji.symm (Finset.mem_univ j)]; ring
  · intro h'; exact absurd hi h'

/-- The rule cannot reach degree 2n: whatever the weights, at the roots of `H_n` the rule sees
zero for `H_n^2`, a polynomial of degree 2n, while `∫ e^(-t^2) H_n(t)^2 dt` is positive. -/
theorem gauss_hermite_not_exact_on_hermite_sq (n : ℕ) (x : Fin n → ℝ)
    (hroot : ∀ i, (physHermite n).eval (x i) = 0) (w : Fin n → ℝ) :
    ∑ i, w i * ((physHermite n) ^ 2).eval (x i) <
      ∫ t : ℝ, exp (-t ^ 2) * ((physHermite n) ^ 2).eval t := by
  have hsum : ∑ i, w i * ((physHermite n) ^ 2).eval (x i) = 0 :=
    Finset.sum_eq_zero fun i _ => by simp [eval_pow, hroot i]
  rw [hsum, sq, gh_norm]
  have := Real.sqrt_pos.2 pi_pos
  positivity

/-- The shortfall on `x^(2n)`: an n-node rule at roots of `H_n` that is exact to
degree `2n - 1` falls short on `t^(2n)` by exactly `sqrt(pi) n! / 2^n`
(in normal form, `E[Z^(2n)]` falls short by `n!`, so by 7! = 5040 at n = 7). -/
theorem gauss_hermite_shortfall_on_two_n (n : ℕ) (x : Fin n → ℝ)
    (hroot : ∀ i, (physHermite n).eval (x i) = 0) (w : Fin n → ℝ)
    (hexact : ∀ g : ℝ[X], g.natDegree ≤ 2 * n - 1 →
      ∫ t : ℝ, exp (-t ^ 2) * g.eval t = ∑ i, w i * g.eval (x i)) :
    (∫ t : ℝ, exp (-t ^ 2) * t ^ (2 * n)) - ∑ i, w i * x i ^ (2 * n) =
      √π * (n.factorial : ℝ) / 2 ^ n := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · exfalso
    have h := hexact 1 (by simp)
    simp only [eval_one, mul_one, Finset.univ_eq_empty, Finset.sum_empty] at h
    rw [gh_gauss] at h
    exact (Real.sqrt_pos.2 pi_pos).ne' h
  have hH0 : physHermite n ≠ 0 := fun h => by
    have := gh_leadingCoeff n
    rw [h, leadingCoeff_zero] at this
    exact (pow_ne_zero n two_ne_zero) this.symm
  have hc : ((4 : ℝ) ^ n)⁻¹ ≠ 0 := by positivity
  have h4 : (4 : ℝ) ^ n = 2 ^ n * 2 ^ n := by rw [← mul_pow]; norm_num
  have hq_nd : (C ((4 : ℝ) ^ n)⁻¹ * (physHermite n * physHermite n)).natDegree = 2 * n := by
    rw [natDegree_C_mul hc, natDegree_mul hH0 hH0, gh_natDegree]; ring
  have hq0 : C ((4 : ℝ) ^ n)⁻¹ * (physHermite n * physHermite n) ≠ 0 :=
    mul_ne_zero (C_ne_zero.2 hc) (mul_ne_zero hH0 hH0)
  have hq_lc : (C ((4 : ℝ) ^ n)⁻¹ * (physHermite n * physHermite n)).leadingCoeff = 1 := by
    rw [leadingCoeff_mul, leadingCoeff_mul, leadingCoeff_C, gh_leadingCoeff, ← h4]
    exact inv_mul_cancel₀ (by positivity)
  have hdeg : ((X : ℝ[X]) ^ (2 * n) - C ((4 : ℝ) ^ n)⁻¹ * (physHermite n * physHermite n)).degree
      < ((2 * n : ℕ) : WithBot ℕ) := by
    have := degree_sub_lt_left (p := (X : ℝ[X]) ^ (2 * n))
      (q := C ((4 : ℝ) ^ n)⁻¹ * (physHermite n * physHermite n))
      (by rw [degree_X_pow, degree_eq_natDegree hq0, hq_nd])
      (pow_ne_zero _ X_ne_zero) (by rw [leadingCoeff_X_pow, hq_lc])
    rwa [degree_X_pow] at this
  have hr : ((X : ℝ[X]) ^ (2 * n) -
      C ((4 : ℝ) ^ n)⁻¹ * (physHermite n * physHermite n)).natDegree ≤ 2 * n - 1 := by
    by_cases h : ((X : ℝ[X]) ^ (2 * n) -
        C ((4 : ℝ) ^ n)⁻¹ * (physHermite n * physHermite n)) = 0
    · rw [h, natDegree_zero]; exact Nat.zero_le _
    · have := (natDegree_lt_iff_degree_lt h).2 hdeg; omega
  have h := hexact _ hr
  rw [gh_int_sub, gh_int_C_mul, gh_norm] at h
  simp only [eval_pow, eval_X] at h
  have hs : ∑ i, w i * ((X : ℝ[X]) ^ (2 * n) -
      C ((4 : ℝ) ^ n)⁻¹ * (physHermite n * physHermite n)).eval (x i) =
        ∑ i, w i * x i ^ (2 * n) :=
    Finset.sum_congr rfl fun i _ => by simp [hroot i]
  rw [hs] at h
  rw [← h, h4]
  field_simp
  ring

-- The card's whole-number checks at n = 7, in normal form (E[Z^(2k)] = (2k - 1)!!).
-- The rule's E[Z^12] is the true value 11!! = 10395.
example : Nat.doubleFactorial 11 = 10395 := by decide
-- The true E[Z^14] is 13!! = 135135; the rule gives 130095, short by 7! = 5040.
example : Nat.doubleFactorial 13 = 135135 := by decide
example : Nat.factorial 7 = 5040 := by decide
example : Nat.doubleFactorial 13 - Nat.factorial 7 = 130095 := by decide
-- The centre probability p_4 = w_4 / sqrt(pi) = 2^6 7! / (7^2 H_6(0)^2), with H_6(0) = -120,
-- is 16/35 = 0.4571428571...
example : (physHermite 6).eval 0 = -120 := by
  simp [physHermite]; norm_num
example : ((2 : ℚ) ^ 6 * 5040) / (7 ^ 2 * (-120) ^ 2) = 16 / 35 := by norm_num

#print axioms gauss_hermite_exact_to_degree_two_n_sub_one
#print axioms gauss_hermite_not_exact_on_hermite_sq
#print axioms gauss_hermite_shortfall_on_two_n
