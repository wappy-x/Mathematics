-- Rational functions: a ratio of complex polynomials with the top of lower degree is the sum of its principal parts, one per pole, with the cover-up rule at simple poles and zeros of order n turning into poles of order n under the reciprocal.
import Mathlib.Analysis.Meromorphic.Order
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.Calculus.ContDiff.Polynomial
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.FieldTheory.IsAlgClosed.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.Basic

open Polynomial Filter Topology Complex

lemma rf_poly_contDiff (A : ℂ[X]) (k : ℕ) : ContDiff ℂ k (fun z => A.eval z) := by
  simpa using contDiff_aeval (𝕜 := ℂ) A k

lemma rf_poly_iteratedDeriv (A : ℂ[X]) (n : ℕ) :
    iteratedDeriv n (fun z => A.eval z) = fun z => (derivative^[n] A).eval z := by
  induction n generalizing A with
  | zero => simp
  | succ n ih =>
    rw [iteratedDeriv_succ', show deriv (fun z => A.eval z) = fun z => (derivative A).eval z
      from funext fun z => Polynomial.deriv A, ih]
    simp [Function.iterate_succ_apply]

lemma rf_taylor_dvd (A B : ℂ[X]) (p : ℂ) (hB : B.eval p ≠ 0) (m : ℕ) :
    (X - C p) ^ m ∣ A - B * ∑ j ∈ Finset.range m,
      C (iteratedDeriv j (fun z => A.eval z / B.eval z) p / (j.factorial : ℂ)) * (X - C p) ^ j := by
  set g := fun z => A.eval z / B.eval z with hg
  set T := ∑ j ∈ Finset.range m,
    C (iteratedDeriv j g p / (j.factorial : ℂ)) * (X - C p) ^ j with hT
  by_cases hD : A - B * T = 0
  · rw [hD]; exact dvd_zero _
  rw [← le_rootMultiplicity_iff hD]
  cases m with
  | zero => exact Nat.zero_le _
  | succ n =>
  rw [Nat.succ_le_iff, lt_rootMultiplicity_iff_isRoot_iterate_derivative hD]
  intro l hl
  have hTd : ∀ j < n + 1, (derivative^[j] T).eval p = iteratedDeriv j g p := by
    intro j hj
    rw [hT, iterate_derivative_sum, eval_finsetSum, Finset.sum_eq_single j]
    · rw [iterate_derivative_C_mul, eval_mul, eval_C, iterate_derivative_X_sub_pow_self,
        eval_natCast]
      have : (j.factorial : ℂ) ≠ 0 := by exact_mod_cast Nat.factorial_ne_zero j
      field_simp
    · intro i hi hij
      simp only [iterate_derivative_C_mul, iterate_derivative_X_sub_pow, eval_mul, eval_smul,
        eval_pow, eval_sub, eval_X, eval_C, sub_self]
      rcases lt_or_gt_of_ne hij with h | h
      · simp [Nat.descFactorial_eq_zero_iff_lt.mpr h]
      · simp [zero_pow (Nat.sub_ne_zero_of_lt h)]
    · intro hj'; simp at hj'; omega
  have hcd : ∀ k : ℕ, ContDiffAt ℂ k g p := fun k =>
    ((rf_poly_contDiff A k).contDiffAt).div ((rf_poly_contDiff B k).contDiffAt) hB
  have hTc : ∀ k : ℕ, ContDiffAt ℂ k (fun z => T.eval z) p := fun k =>
    (rf_poly_contDiff T k).contDiffAt
  have hBc : ∀ k : ℕ, ContDiffAt ℂ k (fun z => B.eval z) p := fun k =>
    (rf_poly_contDiff B k).contDiffAt
  have heq : (fun z => (A - B * T).eval z) =ᶠ[𝓝 p]
      (fun z => B.eval z) * (g - fun z => T.eval z) := by
    have : ∀ᶠ z in 𝓝 p, B.eval z ≠ 0 := (B.continuous.continuousAt).eventually_ne hB
    filter_upwards [this] with z hz
    simp only [hg, eval_sub, eval_mul, Pi.mul_apply, Pi.sub_apply]
    field_simp
  show (derivative^[l] (A - B * T)).eval p = 0
  have h1 := congrFun (rf_poly_iteratedDeriv (A - B * T) l) p
  have hgT : ContDiffAt ℂ l (g - fun z => T.eval z) p := (hcd l).sub (hTc l)
  rw [← h1, (heq.iteratedDeriv l).eq_of_nhds, iteratedDeriv_mul (hBc l) hgT]
  apply Finset.sum_eq_zero
  intro i hi
  rw [iteratedDeriv_sub (hcd _) (hTc _), rf_poly_iteratedDeriv T]
  beta_reduce
  rw [hTd _ (by simp at hi; omega), sub_self,
    mul_zero]

lemma rf_degree_T (p : ℂ) (m : ℕ) (a : ℕ → ℂ) :
    (∑ j ∈ Finset.range m, C (a j) * (X - C p) ^ j).degree < (m : WithBot ℕ) := by
  rw [← mem_degreeLT]
  refine Submodule.sum_mem _ fun j hj => ?_
  rw [← smul_eq_C_mul]
  refine Submodule.smul_mem _ _ ?_
  rw [mem_degreeLT, degree_pow, degree_X_sub_C]
  simp only [Finset.mem_range] at hj
  simp only [nsmul_eq_mul, mul_one]
  exact_mod_cast hj

#print axioms rf_poly_contDiff
#print axioms rf_poly_iteratedDeriv
#print axioms rf_taylor_dvd
#print axioms rf_degree_T

/-- A ratio of polynomials P/Q over the complex numbers, with deg P < deg Q and no common
factor, is exactly the sum of its principal parts, one for each pole. The poles are the roots
p of Q; the order of p is m = (how many times (s - p) divides Q), and the coefficient of
1/(s - p)^k is the Taylor coefficient g^(m-k)(p)/(m-k)! of g(s) = (s - p)^m P(s)/Q(s),
that is, g = P / (Q divided by (s - p)^m). The identity holds at every s that is not a root
of Q. -/
theorem rational_function_eq_sum_of_principal_parts (P Q : ℂ[X])
    (hdeg : P.degree < Q.degree) (hcop : IsCoprime P Q) (s : ℂ) (hs : Q.eval s ≠ 0) :
    P.eval s / Q.eval s =
      ∑ p ∈ Q.roots.toFinset, ∑ k ∈ Finset.Icc 1 (Q.rootMultiplicity p),
        iteratedDeriv (Q.rootMultiplicity p - k)
            (fun z => P.eval z / (Q /ₘ (X - C p) ^ Q.rootMultiplicity p).eval z) p
          / ((Q.rootMultiplicity p - k).factorial : ℂ) / (s - p) ^ k := by
  classical
  have hQ : Q ≠ 0 := by rintro rfl; simp at hdeg
  let Qp : ℂ → ℂ[X] := fun p => Q /ₘ (X - C p) ^ Q.rootMultiplicity p
  let a : ℂ → ℕ → ℂ := fun p j =>
    iteratedDeriv j (fun z => P.eval z / (Qp p).eval z) p / (j.factorial : ℂ)
  let T : ℂ → ℂ[X] := fun p =>
    ∑ j ∈ Finset.range (Q.rootMultiplicity p), C (a p j) * (X - C p) ^ j
  have hfac : ∀ p, (X - C p) ^ Q.rootMultiplicity p * Qp p = Q := fun p =>
    pow_mul_divByMonic_rootMultiplicity_eq Q p
  have hQp0 : ∀ p, Qp p ≠ 0 := fun p h => hQ (by rw [← hfac p, h, mul_zero])
  have hQpp : ∀ p, (Qp p).eval p ≠ 0 := fun p =>
    eval_divByMonic_pow_rootMultiplicity_ne_zero p hQ
  have hroot : ∀ p ∈ Q.roots.toFinset, Q.IsRoot p := fun p hp =>
    (mem_roots hQ).mp (Multiset.mem_toFinset.mp hp)
  -- Step A: the polynomial identity P = ∑ Qp * T.
  have hA : P = ∑ p ∈ Q.roots.toFinset, Qp p * T p := by
    rw [← sub_eq_zero]
    set N := P - ∑ p ∈ Q.roots.toFinset, Qp p * T p with hN
    by_contra hN0
    have hdiv : ∀ p ∈ Q.roots.toFinset, Q.rootMultiplicity p ≤ N.rootMultiplicity p := by
      intro p hp
      rw [le_rootMultiplicity_iff hN0, hN,
        ← Finset.add_sum_erase _ (fun p => Qp p * T p) hp, ← sub_sub]
      refine dvd_sub (rf_taylor_dvd P (Qp p) p (hQpp p) _) (Finset.dvd_sum fun q hq => ?_)
      apply Dvd.dvd.mul_right
      have hqp : q ≠ p := Finset.ne_of_mem_erase hq
      have hcp : IsCoprime ((X - C p) ^ Q.rootMultiplicity p)
          ((X - C q) ^ Q.rootMultiplicity q) :=
        (isCoprime_X_sub_C_of_isUnit_sub (sub_ne_zero.mpr hqp.symm).isUnit).pow
      exact hcp.dvd_of_dvd_mul_left (by rw [hfac q]; exact pow_rootMultiplicity_dvd Q p)
    have hle : Q.roots ≤ N.roots := by
      rw [Multiset.le_iff_count]
      intro p
      rw [count_roots, count_roots]
      by_cases hp : p ∈ Q.roots.toFinset
      · exact hdiv p hp
      · have : Q.rootMultiplicity p = 0 := by
          rw [← count_roots]; exact Multiset.count_eq_zero.mpr (by simpa using hp)
        omega
    have hdegN : N.degree < Q.degree := by
      rw [hN]
      have hbot : ⊥ < Q.degree := bot_lt_iff_ne_bot.mpr (by simpa using hQ)
      refine (degree_sub_le _ _).trans_lt (max_lt hdeg ?_)
      refine (degree_sum_le _ _).trans_lt ((Finset.sup_lt_iff hbot).mpr fun p hp => ?_)
      have hm : 0 < Q.rootMultiplicity p := (rootMultiplicity_pos hQ).mpr (hroot p hp)
      apply degree_lt_degree
      have hTn : (T p).natDegree < Q.rootMultiplicity p := by
        by_cases hT0 : T p = 0
        · rw [hT0, natDegree_zero]; exact hm
        · exact (natDegree_lt_iff_degree_lt hT0).mpr (rf_degree_T _ _ _)
      have hQn : Q.natDegree = Q.rootMultiplicity p + (Qp p).natDegree := by
        conv_lhs => rw [← hfac p]
        rw [natDegree_mul (pow_ne_zero _ (X_sub_C_ne_zero p)) (hQp0 p), natDegree_pow,
          natDegree_X_sub_C, mul_one]
      calc (Qp p * T p).natDegree ≤ (Qp p).natDegree + (T p).natDegree := natDegree_mul_le
        _ < Q.natDegree := by omega
    have h1 := Multiset.card_le_card hle
    rw [IsAlgClosed.card_roots_eq_natDegree] at h1
    have h2 := card_roots' N
    have h3 : N.natDegree < Q.natDegree := natDegree_lt_natDegree hN0 hdegN
    omega
  -- Step B: each pole's principal part, put over the common denominator Q.
  have hB : ∀ p ∈ Q.roots.toFinset,
      ∑ k ∈ Finset.Icc 1 (Q.rootMultiplicity p), a p (Q.rootMultiplicity p - k) / (s - p) ^ k
        = (Qp p).eval s * (T p).eval s / Q.eval s := by
    intro p hp
    have hsp : s - p ≠ 0 := by
      intro h; apply hs; rw [sub_eq_zero.mp h]; exact hroot p hp
    have hQs : Q.eval s = (s - p) ^ Q.rootMultiplicity p * (Qp p).eval s := by
      conv_lhs => rw [← hfac p]
      simp
    have hQps : (Qp p).eval s ≠ 0 := fun h => hs (by rw [hQs, h, mul_zero])
    rw [hQs, mul_comm ((s - p) ^ _), mul_div_mul_left _ _ hQps]
    simp only [T, eval_finsetSum, eval_mul, eval_C, eval_pow, eval_sub, eval_X]
    rw [Finset.sum_div]
    refine Finset.sum_nbij' (fun k => Q.rootMultiplicity p - k)
      (fun j => Q.rootMultiplicity p - j) ?_ ?_ ?_ ?_ ?_
    · intro k hk; simp only [Finset.mem_Icc, Finset.mem_range] at hk ⊢; omega
    · intro j hj; simp only [Finset.mem_Icc, Finset.mem_range] at hj ⊢; omega
    · intro k hk; simp only [Finset.mem_Icc] at hk; omega
    · intro j hj; simp only [Finset.mem_range] at hj; omega
    · intro k hk
      simp only [Finset.mem_Icc] at hk
      rw [← pow_sub_mul_pow (s - p) hk.2]
      field_simp
  conv_lhs => rw [hA]
  rw [eval_finsetSum, Finset.sum_div]
  refine Finset.sum_congr rfl fun p hp => ?_
  rw [eval_mul, ← hB p hp]

/-- The cover-up rule: at a simple pole p of P/Q (a root of Q of order 1), the coefficient
c₋₁(p) = lim_{s → p} (s - p) P(s)/Q(s) equals P(p)/Q'(p), the top over the slope of the
bottom. -/
theorem cover_up_rule (P Q : ℂ[X]) (p : ℂ) (hp : Q.rootMultiplicity p = 1) :
    Tendsto (fun s => (s - p) * (P.eval s / Q.eval s)) (𝓝[≠] p)
      (𝓝 (P.eval p / (derivative Q).eval p)) := by
  have hQ : Q ≠ 0 := by rintro rfl; simp at hp
  set R := Q /ₘ (X - C p) ^ Q.rootMultiplicity p with hR
  have hRp : R.eval p ≠ 0 := eval_divByMonic_pow_rootMultiplicity_ne_zero p hQ
  have hQR : Q = (X - C p) * R := by
    have h := pow_mul_divByMonic_rootMultiplicity_eq Q p
    rw [← hR, hp, pow_one] at h
    exact h.symm
  have hd : (derivative Q).eval p = R.eval p := by
    rw [hQR]; simp
  rw [hd]
  have hc : ContinuousAt (fun s => P.eval s / R.eval s) p :=
    (P.continuous.continuousAt).div (R.continuous.continuousAt) hRp
  refine (hc.tendsto.mono_left nhdsWithin_le_nhds).congr' ?_
  filter_upwards [self_mem_nhdsWithin] with s hs
  have hs' : s - p ≠ 0 := sub_ne_zero.mpr hs
  rw [hQR, eval_mul, eval_sub, eval_X, eval_C, mul_div_assoc', mul_div_mul_left _ _ hs']

/-- A zero of order n of a function holomorphic at p is a pole of order n of its reciprocal:
the order of 1/f at p is -n. -/
theorem zero_of_order_n_is_pole_of_order_n_of_reciprocal {f : ℂ → ℂ} {p : ℂ} {n : ℕ}
    (hf : AnalyticAt ℂ f p) (hn : analyticOrderAt f p = n) :
    meromorphicOrderAt f⁻¹ p = -(n : ℤ) := by
  rw [meromorphicOrderAt_inv, hf.meromorphicOrderAt_eq, hn]
  rfl

-- The card's worked numbers for G(s) = 1/((s^2 + 1)(s^2 + 4)), Q(s) = s^4 + 5s^2 + 4.
-- Slope of the bottom: Q'(s) = 4s^3 + 10s, so Q'(i) = 6i and Q'(2i) = -12i.
example : (4 * I ^ 3 + 10 * I : ℂ) = 6 * I := by linear_combination (4 * I) * I_sq
example : (4 * (2 * I) ^ 3 + 10 * (2 * I) : ℂ) = -12 * I := by
  linear_combination (32 * I) * I_sq
-- Coefficients by the cover-up rule: 1/(6i) = -i/6 at i, 1/(-12i) = i/12 at 2i.
example : (1 / (6 * I) : ℂ) = -I / 6 := by
  rw [div_eq_div_iff (by simp) (by norm_num)]; linear_combination 6 * I_sq
example : (1 / (-12 * I) : ℂ) = I / 12 := by
  rw [div_eq_div_iff (by simp) (by norm_num)]; linear_combination 12 * I_sq
-- Conjugate pairs: (-i/6)(2i) = 1/3 over s^2 + 1, and (i/12)(4i) = -1/3 over s^2 + 4.
example : (-I / 6) * (2 * I) = (1 / 3 : ℂ) := by linear_combination (-1/3 : ℂ) * I_sq
example : (I / 12) * (4 * I) = (-1 / 3 : ℂ) := by linear_combination (1/3 : ℂ) * I_sq
-- Check at s = 3: the four principal parts add to G(3) = 1/130 = (1/3)(1/10 - 1/13).
example : (-I / 6) / (3 - I) + (I / 6) / (3 + I) + (I / 12) / (3 - 2 * I)
    + (-I / 12) / (3 + 2 * I) = (1 / 130 : ℂ) := by
  apply Complex.ext <;> simp [Complex.div_re, Complex.div_im, Complex.normSq] <;> norm_num
example : (1 : ℚ) / ((3 ^ 2 + 1) * (3 ^ 2 + 4)) = 1 / 3 * (1 / (3 ^ 2 + 1) - 1 / (3 ^ 2 + 4)) := by
  norm_num
-- Splitting s^4/Q without dividing misses the quotient 1: s^4 = 1 * Q + (-5s^2 - 4), at s = 3.
example : (3 : ℚ) ^ 4 / ((3 ^ 2 + 1) * (3 ^ 2 + 4)) - 1
    = (-5 * 3 ^ 2 - 4) / ((3 ^ 2 + 1) * (3 ^ 2 + 4)) := by norm_num
-- F = 1/(s^2 + 1)^2 at s = 3 is 1/100.
example : (1 : ℚ) / (3 ^ 2 + 1) ^ 2 = 1 / 100 := by norm_num

#print axioms rational_function_eq_sum_of_principal_parts
#print axioms cover_up_rule
#print axioms zero_of_order_n_is_pole_of_order_n_of_reciprocal
