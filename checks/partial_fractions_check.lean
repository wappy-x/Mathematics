-- Partial fractions: every ratio of real polynomials whose bottom is factored into distinct linear factors and rootless quadratics equals a polynomial plus one simple fraction per power of each factor, each piece integrates to a log, a fraction or a log plus an arctangent, and 1/(x^2 - 1) splits into halves whose area from 2 to 3 is half of ln(3/2).
import Mathlib.Algebra.Polynomial.PartialFractions
import Mathlib.Algebra.Polynomial.SpecificDegree
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.ArctanDeriv
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open Polynomial Real Set intervalIntegral

/-- **Every rational function is a polynomial plus simple fractions.** Let P be any real
polynomial (the top). Let the bottom Q be fully factored over the real numbers: a nonzero
constant c times a product of powers g_i ^ m_i of distinct monic factors, each either linear
(x − r) or a quadratic with no real root. Then there is a polynomial H and, for each factor g_i
and each power k = 1, …, m_i, a top r_{i,k} of lower degree than g_i (a constant over a linear
factor, a straight line Mx + N over a quadratic), such that at every x where Q(x) ≠ 0,
P(x)/Q(x) = H(x) + Σ_i Σ_{k=1}^{m_i} r_{i,k}(x) / g_i(x)^k.
When the top already has lower degree than the bottom, no polynomial part is needed: H = 0. -/
theorem rational_function_eq_polynomial_add_partial_fractions {ι : Type*}
    (P Q : ℝ[X]) (c : ℝ) (hc : c ≠ 0) (s : Finset ι) (g : ι → ℝ[X]) (m : ι → ℕ)
    (hg : ∀ i ∈ s, (g i).Monic ∧
      ((g i).natDegree = 1 ∨ ((g i).natDegree = 2 ∧ ∀ x : ℝ, (g i).eval x ≠ 0)))
    (hdistinct : Set.InjOn g s)
    (hQ : Q = C c * ∏ i ∈ s, g i ^ m i) :
    ∃ (H : ℝ[X]) (r : ι → ℕ → ℝ[X]),
      (∀ i ∈ s, ∀ k, (r i k).degree < (g i).degree) ∧
      (P.degree < Q.degree → H = 0) ∧
      ∀ x : ℝ, Q.eval x ≠ 0 →
        P.eval x / Q.eval x =
          H.eval x + ∑ i ∈ s, ∑ k ∈ Finset.Icc 1 (m i), (r i k).eval x / (g i).eval x ^ k := by
  classical
  have hirr : ∀ i ∈ s, Irreducible (g i) := by
    intro i hi
    rcases (hg i hi).2 with h1 | ⟨h2, hroot⟩
    · exact Polynomial.irreducible_of_degree_eq_one
        (by rw [degree_eq_natDegree (hg i hi).1.ne_zero, h1]; rfl)
    · exact irreducible_of_degree_le_three_of_not_isRoot (by rw [h2]; decide)
        (fun x hx => hroot x hx)
  have hcop : Set.Pairwise (s : Set ι) fun i j => IsCoprime (g i) (g j) := by
    intro i hi j hj hij
    rw [(hirr i hi).coprime_iff_not_dvd]
    intro hdvd
    exact hij (hdistinct hi hj (eq_of_monic_of_associated (hg i hi).1 (hg j hj).1
      (((hirr i hi).dvd_irreducible_iff_associated (hirr j hj)).mp hdvd)))
  obtain ⟨Q', hQ'⟩ : ∃ Q', Q' = ∏ i ∈ s, g i ^ m i := ⟨_, rfl⟩
  have hmon : Q'.Monic := hQ' ▸ monic_prod_of_monic _ _ fun i hi => (hg i hi).1.pow _
  obtain ⟨H, r, hr, hf⟩ := eq_quo_mul_prod_pow_add_sum_rem_mul_prod_pow (C c⁻¹ * P)
    (fun i hi => (hg i hi).1) hcop m
  rw [← hQ'] at hf hQ
  let R : ι → ℕ → ℝ[X] := fun i k =>
    if h : 1 ≤ k ∧ k ≤ m i then r i ⟨m i - k, by omega⟩ else 0
  refine ⟨H, R, ?_, ?_, ?_⟩
  · intro i hi k
    simp only [R]
    split_ifs with h
    · exact hr i hi _
    · rw [degree_zero]
      exact bot_lt_iff_ne_bot.mpr (fun h' => (hg i hi).1.ne_zero (degree_eq_bot.mp h'))
  · intro hdeg
    have hbot : (⊥ : WithBot ℕ) < Q'.degree :=
      bot_lt_iff_ne_bot.mpr (fun h' => hmon.ne_zero (degree_eq_bot.mp h'))
    have hterm : ∀ i ∈ s, ∀ j : Fin (m i),
        (r i j * g i ^ j.1 * ∏ k ∈ s.erase i, g k ^ m k).degree < Q'.degree := by
      intro i hi j
      have hE : (∏ k ∈ s.erase i, g k ^ m k) ≠ 0 :=
        (monic_prod_of_monic _ _ fun k hk => (hg k (Finset.mem_of_mem_erase hk)).1.pow _).ne_zero
      have hgi := (hg i hi).1.ne_zero
      by_cases hr0 : r i j = 0
      · rw [hr0, zero_mul, zero_mul, degree_zero]; exact hbot
      · apply degree_lt_degree
        rw [hQ', ← Finset.mul_prod_erase s (fun k => g k ^ m k) hi]
        rw [natDegree_mul (mul_ne_zero hr0 (pow_ne_zero _ hgi)) hE,
          natDegree_mul hr0 (pow_ne_zero _ hgi), natDegree_mul (pow_ne_zero _ hgi) hE,
          natDegree_pow, natDegree_pow]
        have h1 : (r i j).natDegree < (g i).natDegree := natDegree_lt_natDegree hr0 (hr i hi j)
        have h2 : j.1 + 1 ≤ m i := j.2
        have h3 : (j.1 + 1) * (g i).natDegree ≤ m i * (g i).natDegree :=
          Nat.mul_le_mul_right _ h2
        nlinarith
    have hRem : (∑ i ∈ s, ∑ j, r i j * g i ^ j.1 * ∏ k ∈ s.erase i, g k ^ m k).degree
        < Q'.degree := by
      refine lt_of_le_of_lt (degree_sum_le _ _) ((Finset.sup_lt_iff hbot).mpr fun i hi => ?_)
      exact lt_of_le_of_lt (degree_sum_le _ _)
        ((Finset.sup_lt_iff hbot).mpr fun j _ => hterm i hi j)
    have hdiv := (div_modByMonic_unique (f := C c⁻¹ * P) H _ hmon ⟨by rw [hf]; ring, hRem⟩).1
    rw [← hdiv, divByMonic_eq_zero_iff hmon, degree_C_mul (inv_ne_zero hc)]
    rw [hQ, degree_C_mul hc] at hdeg
    exact hdeg
  · intro x hx
    have hQx : Q.eval x = c * Q'.eval x := by rw [hQ, eval_mul, eval_C]
    have hQ'x : Q'.eval x ≠ 0 := by rw [hQx] at hx; exact right_ne_zero_of_mul hx
    have hE : ∀ i ∈ s, Q'.eval x = (g i).eval x ^ m i * ∏ k ∈ s.erase i, (g k).eval x ^ m k := by
      intro i hi
      rw [hQ', eval_prod]
      simp only [eval_pow]
      rw [Finset.mul_prod_erase s (fun k => (g k).eval x ^ m k) hi]
    have hgx : ∀ i ∈ s, (g i).eval x ^ m i ≠ 0 := fun i hi h =>
      hQ'x (by rw [hE i hi, h, zero_mul])
    have key : ∀ i ∈ s, ∑ k ∈ Finset.Icc 1 (m i), (R i k).eval x / (g i).eval x ^ k
        = (∑ j : Fin (m i), (r i j).eval x * (g i).eval x ^ j.1) / (g i).eval x ^ m i := by
      intro i hi
      rcases Nat.eq_zero_or_pos (m i) with h0 | hpos
      · have : Finset.Icc 1 (m i) = ∅ := by rw [h0]; rfl
        rw [this, Finset.sum_empty]
        have : IsEmpty (Fin (m i)) := by rw [h0]; infer_instance
        simp [Finset.univ_eq_empty]
      · have hg0 : (g i).eval x ≠ 0 := fun h => hgx i hi (by rw [h, zero_pow hpos.ne'])
        rw [Finset.sum_div]
        symm
        refine Finset.sum_bij' (fun j _ => m i - j.1)
          (fun k hk => (⟨m i - k, by rw [Finset.mem_Icc] at hk; omega⟩ : Fin (m i)))
          ?_ ?_ ?_ ?_ ?_
        · intro j _
          rw [Finset.mem_Icc]; have := j.2; omega
        · intro k _; exact Finset.mem_univ _
        · intro j _
          ext; simp only; have := j.2; omega
        · intro k hk
          rw [Finset.mem_Icc] at hk; simp only; omega
        · intro j _
          have hj := j.2
          have hR : R i (m i - j.1) = r i j := by
            simp only [R]
            split_ifs with h
            · congr 1; ext; simp only; omega
            · omega
          rw [hR]
          have hp : (g i).eval x ^ m i = (g i).eval x ^ j.1 * (g i).eval x ^ (m i - j.1) := by
            rw [← pow_add]; congr 1; omega
          rw [hp]
          have : (g i).eval x ^ (m i - j.1) ≠ 0 := pow_ne_zero _ hg0
          have : (g i).eval x ^ j.1 ≠ 0 := pow_ne_zero _ hg0
          field_simp
    have hfx := congrArg (eval x) hf
    simp only [eval_mul, eval_C, eval_add, eval_finsetSum, eval_pow, eval_prod] at hfx
    rw [Finset.sum_congr rfl key, hQx]
    have step : P.eval x / (c * Q'.eval x) = (c⁻¹ * P.eval x) / Q'.eval x := by
      field_simp
    rw [step, hfx, add_div, Finset.sum_div]
    congr 1
    · field_simp
    · apply Finset.sum_congr rfl
      intro i hi
      rw [← Finset.sum_mul, hE i hi]
      have hEne : ∏ k ∈ s.erase i, (g k).eval x ^ m k ≠ 0 :=
        right_ne_zero_of_mul (hE i hi ▸ hQ'x)
      rw [mul_div_mul_right _ _ hEne]

/-- **Each piece integrates to a log, a fraction or an arctangent.** On an interval from a to b
that contains no root of the piece's bottom, ends included:
1. A/(x − r) integrates to A ln|x − r|;
2. A/(x − r)^k with k ≥ 2 integrates to the fraction A/(1 − k) · 1/(x − r)^(k − 1);
3. (Mx + N)/(x^2 + px + q), a quadratic with no real root (p^2 < 4q), integrates to
   M/2 · ln(x^2 + px + q) plus (N − Mp/2)/w · arctan((x + p/2)/w), where w = √(q − p^2/4).
(Higher powers of a rootless quadratic, which the card does not work, are left out.) -/
theorem partial_fraction_pieces_integrate (a b : ℝ) :
    (∀ r A : ℝ, r ∉ uIcc a b →
      ∫ x in a..b, A / (x - r) = A * (log |b - r| - log |a - r|)) ∧
    (∀ (r A : ℝ) (k : ℕ), 2 ≤ k → r ∉ uIcc a b →
      ∫ x in a..b, A / (x - r) ^ k =
        A / (1 - (k : ℝ)) * (1 / (b - r) ^ (k - 1) - 1 / (a - r) ^ (k - 1))) ∧
    (∀ p q M N : ℝ, p ^ 2 < 4 * q →
      ∫ x in a..b, (M * x + N) / (x ^ 2 + p * x + q) =
        M / 2 * (log (b ^ 2 + p * b + q) - log (a ^ 2 + p * a + q)) +
          (N - M * p / 2) / √(q - p ^ 2 / 4) *
            (arctan ((b + p / 2) / √(q - p ^ 2 / 4)) - arctan ((a + p / 2) / √(q - p ^ 2 / 4)))) := by
  refine ⟨?_, ?_, ?_⟩
  · intro r A hr
    have hne : ∀ x ∈ uIcc a b, x - r ≠ 0 := fun x hx h => hr (by
      have : x = r := by linarith
      exact this ▸ hx)
    rw [Real.log_abs, Real.log_abs]
    rw [integral_eq_sub_of_hasDerivAt (f := fun x => A * log (x - r))]
    · ring
    · intro x hx
      have := (((hasDerivAt_id x).sub_const r).log (hne x hx)).const_mul A
      exact this.congr_deriv (by simp only [id_eq, div_eq_mul_inv, one_mul])
    · apply ContinuousOn.intervalIntegrable
      exact continuousOn_const.div (continuousOn_id.sub continuousOn_const) hne
  · intro r A k hk hr
    obtain ⟨n, rfl⟩ : ∃ n, k = n + 2 := ⟨k - 2, by omega⟩
    have hne : ∀ x ∈ uIcc a b, x - r ≠ 0 := fun x hx h => hr (by
      have : x = r := by linarith
      exact this ▸ hx)
    have hfun : (fun x : ℝ => A / (x - r) ^ (n + 2)) =
        fun x => A * (x - r) ^ (-((n + 2 : ℕ) : ℤ)) := by
      funext x; rw [zpow_neg, zpow_natCast, div_eq_mul_inv]
    have hsub : (∫ x in a..b, (x - r) ^ (-((n + 2 : ℕ) : ℤ))) =
        ∫ x in a - r..b - r, x ^ (-((n + 2 : ℕ) : ℤ)) :=
      integral_comp_sub_right (fun y : ℝ => y ^ (-((n + 2 : ℕ) : ℤ))) r
    rw [hfun, intervalIntegral.integral_const_mul, hsub, integral_zpow]
    · have h1 : (-((n + 2 : ℕ) : ℤ)) + 1 = -((n + 1 : ℕ) : ℤ) := by push_cast; ring
      rw [h1]
      have hb : b - r ≠ 0 := hne b right_mem_uIcc
      have ha : a - r ≠ 0 := hne a left_mem_uIcc
      simp only [zpow_neg, zpow_natCast]
      push_cast
      field_simp
      ring
    · right
      refine ⟨by omega, ?_⟩
      intro h0
      apply hr
      rw [Set.mem_uIcc] at h0 ⊢
      rcases h0 with h | h
      · left; constructor <;> linarith
      · right; constructor <;> linarith
  · intro p q M N hpq
    set w := √(q - p ^ 2 / 4) with hw_def
    have hd : 0 < q - p ^ 2 / 4 := by linarith
    have hw : 0 < w := Real.sqrt_pos.mpr hd
    have hw2 : w ^ 2 = q - p ^ 2 / 4 := Real.sq_sqrt hd.le
    have hpos : ∀ x : ℝ, 0 < x ^ 2 + p * x + q := fun x => by nlinarith [sq_nonneg (x + p / 2)]
    rw [integral_eq_sub_of_hasDerivAt (f := fun x => M / 2 * log (x ^ 2 + p * x + q) +
        (N - M * p / 2) / w * arctan ((x + p / 2) / w))]
    · ring
    · intro x _
      have h1 : HasDerivAt (fun x : ℝ => x ^ 2 + p * x + q) (2 * x + p) x := by
        have := ((hasDerivAt_pow 2 x).add ((hasDerivAt_id x).const_mul p)).add_const q
        convert this using 1 <;> norm_num
      have h2 : HasDerivAt (fun x : ℝ => (x + p / 2) / w) (1 / w) x :=
        ((hasDerivAt_id x).add_const (p / 2)).div_const w
      have h3 := ((h1.log (hpos x).ne').const_mul (M / 2)).add (h2.arctan.const_mul ((N - M * p / 2) / w))
      refine h3.congr_deriv ?_
      have key : 1 + ((x + p / 2) / w) ^ 2 = (x ^ 2 + p * x + q) / w ^ 2 := by
        field_simp
        rw [hw2]; ring
      rw [key]
      have := (hpos x).ne'
      field_simp
      ring
    · apply Continuous.intervalIntegrable
      exact (by fun_prop : Continuous fun x : ℝ => M * x + N).div (by fun_prop)
        (fun x => (hpos x).ne')

/-- **The card's curve.** For every x other than 1 and −1,
1/(x^2 − 1) = (1/2)/(x − 1) − (1/2)/(x + 1),
and the area under 1/(x^2 − 1) from 2 to 3 is exactly half of ln(3/2). -/
theorem one_div_sq_sub_one_split_and_area :
    (∀ x : ℝ, x ≠ 1 → x ≠ -1 → 1 / (x ^ 2 - 1) = (1 / 2) / (x - 1) - (1 / 2) / (x + 1)) ∧
    ∫ x in (2 : ℝ)..3, 1 / (x ^ 2 - 1) = 1 / 2 * log (3 / 2) := by
  have split : ∀ x : ℝ, x ≠ 1 → x ≠ -1 →
      1 / (x ^ 2 - 1) = (1 / 2) / (x - 1) - (1 / 2) / (x + 1) := by
    intro x h1 h2
    have h1' : x - 1 ≠ 0 := sub_ne_zero.mpr h1
    have h2' : x + 1 ≠ 0 := fun h => h2 (by linarith)
    have h3 : x ^ 2 - 1 ≠ 0 := by
      have : x ^ 2 - 1 = (x - 1) * (x + 1) := by ring
      rw [this]; exact mul_ne_zero h1' h2'
    field_simp
    ring
  refine ⟨split, ?_⟩
  have hI : ∀ x ∈ uIcc (2 : ℝ) 3, x ≠ 1 ∧ x ≠ -1 := by
    intro x hx
    rw [Set.uIcc_of_le (by norm_num)] at hx
    exact ⟨by linarith [hx.1], by linarith [hx.1]⟩
  have h1 : (1 : ℝ) ∉ uIcc (2 : ℝ) 3 := fun h => (hI 1 h).1 rfl
  have h2 : (-1 : ℝ) ∉ uIcc (2 : ℝ) 3 := fun h => (hI (-1) h).2 rfl
  rw [intervalIntegral.integral_congr (g := fun x : ℝ => (1 / 2) / (x - 1) - (1 / 2) / (x + 1))
    (fun x hx => split x (hI x hx).1 (hI x hx).2)]
  rw [intervalIntegral.integral_sub]
  · have e1 := (partial_fraction_pieces_integrate 2 3).1 1 (1 / 2) h1
    have e2 := (partial_fraction_pieces_integrate 2 3).1 (-1) (1 / 2) h2
    simp only [sub_neg_eq_add] at e2
    rw [e1, e2]
    norm_num
    rw [Real.log_div (by norm_num) (by norm_num),
      show (4 : ℝ) = 2 * 2 by norm_num, Real.log_mul (by norm_num) (by norm_num)]
    ring
  · apply ContinuousOn.intervalIntegrable
    exact continuousOn_const.div (continuousOn_id.sub continuousOn_const)
      (fun x hx => sub_ne_zero.mpr (hI x hx).1)
  · apply ContinuousOn.intervalIntegrable
    exact continuousOn_const.div (continuousOn_id.add continuousOn_const)
      (fun x hx h => (hI x hx).2 (by linarith))

-- Cover-up: set x = 1 in 1 = A(x + 1) + B(x − 1) to get 1 = 2A, so A = 1/2;
-- set x = −1 to get 1 = −2B, so B = −1/2.
example : (1 : ℚ) / 2 * (1 + 1) + (-1 / 2) * (1 - 1) = 1 := by norm_num
example : (1 : ℚ) / 2 * (-1 + 1) + (-1 / 2) * (-1 - 1) = 1 := by norm_num
-- Matching coefficients: A + B = 0 and A − B = 1 give the same A = 1/2, B = −1/2.
example : (1 : ℚ) / 2 + (-1 / 2) = 0 ∧ (1 : ℚ) / 2 - (-1 / 2) = 1 := by norm_num
-- The chart at x = 2: the curve 1/3 is the top line 1/2 plus the bottom line −1/6.
example : (1 : ℚ) / (2 ^ 2 - 1) = (1 / 2) / (2 - 1) - (1 / 2) / (2 + 1) := by norm_num
-- At x = 3 the curve is 1/8.
example : (1 : ℚ) / (3 ^ 2 - 1) = 1 / 8 := by norm_num
-- Divide first: x^3 = x(x^2 − 1) + x, and x/(x^2 − 1) = (1/2)/(x − 1) + (1/2)/(x + 1).
example : ∀ x : ℚ, x ^ 3 = x * (x ^ 2 - 1) + x := by intro x; ring
example : ∀ x : ℚ, x ≠ 1 → x ≠ -1 → x / (x ^ 2 - 1) = (1 / 2) / (x - 1) + (1 / 2) / (x + 1) := by
  intro x h1 h2
  have h1' : x - 1 ≠ 0 := sub_ne_zero.mpr h1
  have h2' : x + 1 ≠ 0 := fun h => h2 (by linarith)
  have h3 : x ^ 2 - 1 ≠ 0 := by
    have : x ^ 2 - 1 = (x - 1) * (x + 1) := by ring
    rw [this]; exact mul_ne_zero h1' h2'
  field_simp
  ring
-- The polynomial part x contributes (3^2 − 2^2)/2 = 5/2 to the area from 2 to 3.
example : ((3 : ℚ) ^ 2 - 2 ^ 2) / 2 = 5 / 2 := by norm_num
-- A repeated factor needs every power: at x = 0, −(1/4)/(x − 1) + (1/4)/(x − 1)^2
-- + (1/4)/(x + 1) + (1/4)/(x + 1)^2 equals 1/(x^2 − 1)^2 = 1.
example : -(1 / 4 : ℚ) / (0 - 1) + (1 / 4) / (0 - 1) ^ 2 + (1 / 4) / (0 + 1) + (1 / 4) / (0 + 1) ^ 2
    = 1 / (0 ^ 2 - 1) ^ 2 := by norm_num
-- A quadratic keeps a straight-line top: at x = 0, (1/4)/(x − 1) − (1/4)/(x + 1) − (1/2)/(x^2 + 1)
-- equals 1/(x^4 − 1) = −1, which is what fixes N = −1/2.
example : (1 / 4 : ℚ) / (0 - 1) - (1 / 4) / (0 + 1) - (1 / 2) / (0 ^ 2 + 1) = 1 / (0 ^ 4 - 1) := by
  norm_num
-- And x^4 − 1 = (x − 1)(x + 1)(x^2 + 1).
example : ∀ x : ℚ, x ^ 4 - 1 = (x - 1) * (x + 1) * (x ^ 2 + 1) := by intro x; ring
-- Tangent subtraction: arctan 3 − arctan 2 = arctan((3 − 2)/(1 + 3·2)) = arctan(1/7).
example : ((3 : ℚ) - 2) / (1 + 3 * 2) = 1 / 7 := by norm_num

#print axioms rational_function_eq_polynomial_add_partial_fractions
#print axioms partial_fraction_pieces_integrate
#print axioms one_div_sq_sub_one_split_and_area
