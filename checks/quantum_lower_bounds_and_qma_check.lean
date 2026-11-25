-- Quantum limits: a yes-probability polynomial of degree at most 2T that stays in [0, 1] on the whole numbers 0 to N and climbs from at most 1/3 at k = 0 to at least 2/3 at k = 1 forces T ≥ √N/4, and the toy Hamiltonian Z ⊗ Z has lowest energy −1, at |01⟩ and |10⟩.
import Mathlib.Algebra.Polynomial.Degree.Defs
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.Algebra.Spectrum.Basic
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Chebyshev.Extremal
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Chebyshev.RootsExtrema
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Calculus.ContDiff.Polynomial
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.LinearAlgebra.Eigenspace.Matrix

open Polynomial
open scoped Kronecker Matrix

lemma iterate_derivative_comp_affine (p : ℝ[X]) (α β : ℝ) (k : ℕ) :
    derivative^[k] (p.comp (C α * X + C β)) =
      C (α ^ k) * (derivative^[k] p).comp (C α * X + C β) := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [Function.iterate_succ_apply', ih, derivative_C_mul, derivative_comp,
      Function.iterate_succ_apply']
    simp [pow_succ]
    ring

lemma poly_taylor2 (p : ℝ[X]) (a b : ℝ) : ∃ η ∈ Set.uIcc a b,
    p.eval b = p.eval a + (derivative p).eval a * (b - a) +
      (derivative^[2] p).eval η * (b - a) ^ 2 / 2 := by
  rcases eq_or_ne a b with rfl | hab
  · exact ⟨a, Set.left_mem_uIcc, by ring⟩
  have hcd : ContDiff ℝ (1 + 1) (fun x => p.eval x) := by
    simpa [Polynomial.aeval_def] using p.contDiff_aeval (𝕜 := ℝ) (1 + 1)
  obtain ⟨η, hη, h⟩ :=
    taylor_mean_remainder_lagrange_iteratedDeriv (f := fun x => p.eval x) (n := 1) hab
      hcd.contDiffOn
  refine ⟨η, Set.uIoo_subset_uIcc_self hη, ?_⟩
  have hder : derivWithin (fun x => p.eval x) (Set.uIcc a b) a = (derivative p).eval a := by
    rw [p.differentiableAt.derivWithin (uniqueDiffOn_uIcc hab a Set.left_mem_uIcc),
      Polynomial.deriv]
  have h2 : iteratedDeriv 2 (fun x => p.eval x) η = (derivative^[2] p).eval η := by
    have e1 : deriv (fun x => p.eval x) = fun x => (derivative p).eval x := by
      funext x; exact Polynomial.deriv _
    rw [iteratedDeriv_succ, iteratedDeriv_one, e1, Polynomial.deriv]
    simp
  rw [taylorWithinEval_succ, taylor_within_zero_eval, iteratedDerivWithin_one, hder, h2] at h
  simp at h
  have e : (⇑derivative)^[2] p = derivative (derivative p) := rfl
  rw [e]
  linarith

lemma markov_affine (q : ℝ[X]) (d k : ℕ) (hd : q.natDegree ≤ d) (α β m H : ℝ) (hα : α ≠ 0)
    (hk : 1 ≤ k) (hb : ∀ y ∈ Set.Icc (-1 : ℝ) 1, |q.eval (α * y + β) - m| ≤ H) :
    |α| ^ k * |(derivative^[k] q).eval (α + β)| ≤
      (derivative^[k] (Chebyshev.T ℝ d)).eval 1 * H := by
  set L : ℝ[X] := C α * X + C β with hL
  set P0 : ℝ[X] := (q - C m).comp L with hP0
  have hkey : (derivative^[k] P0).eval 1 = α ^ k * (derivative^[k] q).eval (α + β) := by
    rw [hP0, iterate_derivative_comp_affine, iterate_derivative_sub,
      iterate_derivative_C (by omega)]
    simp
  have hP0deg : P0.natDegree ≤ d := by
    calc P0.natDegree ≤ (q - C m).natDegree * L.natDegree := natDegree_comp_le
      _ ≤ d * 1 := by
          gcongr
          · rw [natDegree_sub_C]; exact hd
          · exact natDegree_linear_le
      _ = d := mul_one d
  have hP0b : ∀ y ∈ Set.Icc (-1 : ℝ) 1, |P0.eval y| ≤ H := by
    intro y hy
    simpa [P0, L, eval_comp] using hb y hy
  have hH0 : 0 ≤ H := le_trans (abs_nonneg _) (hP0b 1 (by norm_num))
  have hT0 : 0 ≤ (derivative^[k] (Chebyshev.T ℝ d)).eval 1 := by
    have := Chebyshev.abs_iterate_derivative_T_real_le (d : ℤ) k (x := 1) (by norm_num)
    exact le_trans (abs_nonneg _) this
  rcases hH0.lt_or_eq with hH | hH
  · set P : ℝ[X] := C H⁻¹ * P0 with hP
    have hPdeg : P.degree ≤ d := by
      apply degree_le_of_natDegree_le
      exact (natDegree_C_mul_le _ _).trans hP0deg
    have hPb : ∀ y ∈ Set.Icc (-1 : ℝ) 1, |P.eval y| ≤ 1 := by
      intro y hy
      rw [hP, eval_mul, eval_C, abs_mul, abs_inv, abs_of_pos hH, inv_mul_le_iff₀ hH, mul_one]
      exact hP0b y hy
    have hPneg : ∀ y ∈ Set.Icc (-1 : ℝ) 1, |(-P).eval y| ≤ 1 := by
      intro y hy; rw [eval_neg, abs_neg]; exact hPb y hy
    have h1 := Chebyshev.eval_iterate_derivative_le_of_forall_abs_le_one (k := k)
      (le_refl (1 : ℝ)) hPdeg hPb
    have h2 := Chebyshev.eval_iterate_derivative_le_of_forall_abs_le_one (k := k)
      (le_refl (1 : ℝ)) (by rwa [degree_neg]) hPneg
    rw [iterate_derivative_neg, eval_neg] at h2
    have hPv : (derivative^[k] P).eval 1 = H⁻¹ * (α ^ k * (derivative^[k] q).eval (α + β)) := by
      rw [hP, iterate_derivative_C_mul, eval_mul, eval_C, hkey]
    have habs : |(derivative^[k] P).eval 1| ≤ (derivative^[k] (Chebyshev.T ℝ d)).eval 1 :=
      abs_le.2 ⟨by linarith, h1⟩
    rw [hPv, abs_mul, abs_mul, abs_inv, abs_of_pos hH, abs_pow, inv_mul_le_iff₀ hH] at habs
    linarith [mul_comm H ((derivative^[k] (Chebyshev.T ℝ d)).eval 1)]
  · have hz : P0 = 0 := by
      apply Polynomial.eq_of_infinite_eval_eq P0 0
      apply (Set.Icc_infinite (by norm_num : (-1 : ℝ) < 1)).mono
      intro y hy
      have := hP0b y hy
      rw [← hH] at this
      simpa using this
    rw [hz] at hkey
    simp only [iterate_derivative_zero, eval_zero] at hkey
    have : (derivative^[k] q).eval (α + β) = 0 := by
      rcases mul_eq_zero.1 hkey.symm with h | h
      · exact absurd (pow_eq_zero_iff (by omega) |>.1 h) hα
      · exact h
    rw [this, abs_zero, mul_zero]
    exact mul_nonneg hT0 hH0

lemma markov_left (q : ℝ[X]) (d k : ℕ) (hd : q.natDegree ≤ d) (a b m H : ℝ) (hab : a < b)
    (hk : 1 ≤ k) (hb : ∀ x ∈ Set.Icc a b, |q.eval x - m| ≤ H) :
    ((b - a) / 2) ^ k * |(derivative^[k] q).eval a| ≤
      (derivative^[k] (Chebyshev.T ℝ d)).eval 1 * H := by
  have h := markov_affine q d k hd ((a - b) / 2) ((a + b) / 2) m H (by intro h; linarith) hk
    (fun y hy => hb _ ⟨by nlinarith [hy.1, hy.2], by nlinarith [hy.1, hy.2]⟩)
  have e1 : |(a - b) / 2| = (b - a) / 2 := by
    rw [abs_of_neg (by linarith)]; ring
  have e2 : (a - b) / 2 + (a + b) / 2 = a := by ring
  rwa [e1, e2] at h

lemma markov_right (q : ℝ[X]) (d k : ℕ) (hd : q.natDegree ≤ d) (a b m H : ℝ) (hab : a < b)
    (hk : 1 ≤ k) (hb : ∀ x ∈ Set.Icc a b, |q.eval x - m| ≤ H) :
    ((b - a) / 2) ^ k * |(derivative^[k] q).eval b| ≤
      (derivative^[k] (Chebyshev.T ℝ d)).eval 1 * H := by
  have h := markov_affine q d k hd ((b - a) / 2) ((a + b) / 2) m H (by intro h; linarith) hk
    (fun y hy => hb _ ⟨by nlinarith [hy.1, hy.2], by nlinarith [hy.1, hy.2]⟩)
  have e1 : |(b - a) / 2| = (b - a) / 2 := abs_of_pos (by linarith)
  have e2 : (b - a) / 2 + (a + b) / 2 = b := by ring
  rwa [e1, e2] at h


lemma T_deriv_one_eval (d : ℕ) :
    (derivative^[1] (Chebyshev.T ℝ d)).eval 1 = (d : ℝ) ^ 2 := by
  simpa using Chebyshev.derivative_T_eval_one (R := ℝ) (d : ℤ)

lemma T_deriv_two_eval (d : ℕ) :
    3 * (derivative^[2] (Chebyshev.T ℝ d)).eval 1 = ((d : ℝ) ^ 2 - 1) * (d : ℝ) ^ 2 := by
  have h := Chebyshev.iterate_derivative_T_eval_one_recurrence (R := ℝ) (d : ℤ) 1
  have h1 := T_deriv_one_eval d
  norm_num at h h1 ⊢
  rw [h, h1]

lemma second_deriv_interior (q : ℝ[X]) (N H η : ℝ) (hN : 0 < N) (hη : η ∈ Set.Icc 0 N)
    (hH : ∀ x ∈ Set.Icc 0 N, |q.eval x - 1 / 2| ≤ H) :
    N ^ 2 * |(derivative^[2] q).eval η| ≤
      16 * (derivative^[2] (Chebyshev.T ℝ q.natDegree)).eval 1 * H := by
  have hB := abs_nonneg ((derivative^[2] q).eval η)
  by_cases h : η ≤ N / 2
  · have hm := markov_left q q.natDegree 2 le_rfl η N (1 / 2) H (by linarith) (by norm_num)
      (fun x hx => hH x ⟨by linarith [hx.1, hη.1], hx.2⟩)
    have hsq : (N / 4) ^ 2 ≤ ((N - η) / 2) ^ 2 := by
      apply pow_le_pow_left₀ (by linarith) (by linarith)
    nlinarith [mul_le_mul_of_nonneg_right hsq hB]
  · push Not at h
    have hm := markov_right q q.natDegree 2 le_rfl 0 η (1 / 2) H (by linarith) (by norm_num)
      (fun x hx => hH x ⟨hx.1, by linarith [hx.2, hη.2]⟩)
    have hsq : (N / 4) ^ 2 ≤ ((η - 0) / 2) ^ 2 := by
      apply pow_le_pow_left₀ (by linarith) (by linarith)
    nlinarith [mul_le_mul_of_nonneg_right hsq hB]

lemma climb_algebra (c N D T2 H A B : ℝ) (hN : 2 ≤ N) (hD1 : 1 ≤ D)
    (hDN : D < N) (hT2 : 3 * T2 = (D - 1) * D) (hcl : c ≤ A + B / 2)
    (hA : N * A ≤ 2 * D * H) (hB : (N - 1) ^ 2 * B ≤ 4 * T2 * H)
    (hstep : N ^ 2 * H ≤ N ^ 2 / 2 + 2 * T2 * H) : c * N ≤ D * (c + 1) := by
  set p := N - 1 with hp
  have hp1 : 1 ≤ p := by linarith
  have hT2n : 0 ≤ T2 := by nlinarith
  have hS3 : 0 < N ^ 2 - 2 * T2 := by nlinarith
  have hS1 : c * (N * p ^ 2) ≤ 2 * H * (D * p ^ 2 + T2 * N) := by
    have h1 : c * (N * p ^ 2) ≤ (A + B / 2) * (N * p ^ 2) :=
      mul_le_mul_of_nonneg_right hcl (by positivity)
    nlinarith
  have hS2 : H * (N ^ 2 - 2 * T2) ≤ N ^ 2 / 2 := by linarith
  have hQ0 : 0 ≤ D * p ^ 2 + T2 * N := by positivity
  have hND : 0 < N - D := by linarith
  -- key polynomial inequality
  have hg : N ^ 2 * (N - D) ≤ p ^ 2 * (3 * N - 2 * D + 2) := by
    have e : p * (p ^ 2 * (3 * N - 2 * D + 2) - N ^ 2 * (N - D)) =
        (N - D) * ((N - 1) * N * (2 * N - 3)) + (D - 1) * ((N - 1) ^ 2 * (N + 2)) := by
      rw [hp]; ring
    have hr : 0 ≤ (N - D) * ((N - 1) * N * (2 * N - 3)) + (D - 1) * ((N - 1) ^ 2 * (N + 2)) := by
      have : 0 ≤ (N - 1) * N * (2 * N - 3) := by
        apply mul_nonneg (mul_nonneg (by linarith) (by linarith)) (by linarith)
      have : 0 ≤ (N - 1) ^ 2 * (N + 2) := by positivity
      positivity
    rw [← e] at hr
    have := nonneg_of_mul_nonneg_right (by linarith : 0 ≤ p * (p ^ 2 * (3 * N - 2 * D + 2) - N ^ 2 * (N - D))) (by linarith : (0:ℝ) < p)
    nlinarith [mul_pos (by linarith : (0:ℝ) < p) (by linarith : (0:ℝ) < p)]
  have hkey : N * (D * p ^ 2 + T2 * N) * (N - D) ≤ D * p ^ 2 * (N ^ 2 - 2 * T2) := by
    -- reduces to T2 N^2 (N - D) ≤ D p^2 (D N - 2 T2)
    have h3 : 3 * (T2 * N ^ 2 * (N - D)) ≤ 3 * (D * p ^ 2 * (D * N - 2 * T2)) := by
      have hl : 3 * (T2 * N ^ 2 * (N - D)) = D * ((D - 1) * (N ^ 2 * (N - D))) := by
        rw [show 3 * (T2 * N ^ 2 * (N - D)) = (3 * T2) * (N ^ 2 * (N - D)) by ring, hT2]; ring
      have hr : 3 * (D * p ^ 2 * (D * N - 2 * T2)) = D * (p ^ 2 * D * (3 * N - 2 * D + 2)) := by
        rw [show 3 * (D * p ^ 2 * (D * N - 2 * T2)) = D * p ^ 2 * (3 * D * N - 2 * (3 * T2)) by ring,
          hT2]; ring
      rw [hl, hr]
      apply mul_le_mul_of_nonneg_left _ (by linarith)
      have hN0 : 0 ≤ N ^ 2 * (N - D) := by positivity
      calc (D - 1) * (N ^ 2 * (N - D)) ≤ D * (N ^ 2 * (N - D)) := by nlinarith
        _ ≤ D * (p ^ 2 * (3 * N - 2 * D + 2)) := mul_le_mul_of_nonneg_left hg (by linarith)
        _ = p ^ 2 * D * (3 * N - 2 * D + 2) := by ring
    nlinarith
  -- combine
  have hpos : 0 < N * p ^ 2 * (N ^ 2 - 2 * T2) := by positivity
  have hc1 : c * (N - D) * (N * p ^ 2 * (N ^ 2 - 2 * T2)) ≤ D * (N * p ^ 2 * (N ^ 2 - 2 * T2)) := by
    calc c * (N - D) * (N * p ^ 2 * (N ^ 2 - 2 * T2))
        = (c * (N * p ^ 2)) * ((N - D) * (N ^ 2 - 2 * T2)) := by ring
      _ ≤ (2 * H * (D * p ^ 2 + T2 * N)) * ((N - D) * (N ^ 2 - 2 * T2)) :=
          mul_le_mul_of_nonneg_right hS1 (by positivity)
      _ = 2 * (H * (N ^ 2 - 2 * T2)) * ((D * p ^ 2 + T2 * N) * (N - D)) := by ring
      _ ≤ 2 * (N ^ 2 / 2) * ((D * p ^ 2 + T2 * N) * (N - D)) := by
          apply mul_le_mul_of_nonneg_right _ (by positivity)
          linarith
      _ = N * (N * (D * p ^ 2 + T2 * N) * (N - D)) := by ring
      _ ≤ N * (D * p ^ 2 * (N ^ 2 - 2 * T2)) := mul_le_mul_of_nonneg_left hkey (by linarith)
      _ = D * (N * p ^ 2 * (N ^ 2 - 2 * T2)) := by ring
  have := le_of_mul_le_mul_right hc1 hpos
  linarith


lemma climb_degree_bound (N : ℕ) (c : ℝ) (q : ℝ[X]) (hc : 0 ≤ c)
    (hprob : ∀ k : ℕ, k ≤ N → 0 ≤ q.eval (k : ℝ) ∧ q.eval (k : ℝ) ≤ 1)
    (hclimb : c ≤ q.eval 1 - q.eval 0) :
    c * N / (c + 1) ≤ (q.natDegree : ℝ) ^ 2 := by
  set d := q.natDegree with hd
  rw [div_le_iff₀ (by linarith)]
  by_cases hDN : (N : ℝ) ≤ (d : ℝ) ^ 2
  · nlinarith
  push Not at hDN
  rcases Nat.eq_zero_or_pos d with hd0 | hd0
  · have hq : q = C (q.coeff 0) := eq_C_of_natDegree_eq_zero (by rw [← hd, hd0])
    rw [hq] at hclimb
    simp only [eval_C, sub_self] at hclimb
    have : c = 0 := le_antisymm hclimb hc
    rw [this]; simp
  have hD1 : (1 : ℝ) ≤ (d : ℝ) ^ 2 := by
    have : (1 : ℝ) ≤ d := by exact_mod_cast hd0
    nlinarith
  have hN2 : (2 : ℝ) ≤ N := by
    have h1 : (1 : ℝ) < N := lt_of_le_of_lt hD1 hDN
    have : 1 < N := by exact_mod_cast h1
    exact_mod_cast this
  have hNpos : (0 : ℝ) < N := by linarith
  obtain ⟨x0, hx0, hmax⟩ := (isCompact_Icc (a := (0 : ℝ)) (b := N)).exists_isMaxOn
    (Set.nonempty_Icc.2 hNpos.le)
    ((q.differentiable.continuous.sub continuous_const).abs.continuousOn :
      ContinuousOn (fun x => |q.eval x - 1 / 2|) (Set.Icc 0 N))
  set H := |q.eval x0 - 1 / 2| with hHdef
  have hH : ∀ x ∈ Set.Icc (0 : ℝ) N, |q.eval x - 1 / 2| ≤ H := fun x hx => hmax hx
  have hH0 : 0 ≤ H := abs_nonneg _
  set T2 := (derivative^[2] (Chebyshev.T ℝ d)).eval 1 with hT2def
  have hT2 : 3 * T2 = ((d : ℝ) ^ 2 - 1) * (d : ℝ) ^ 2 := T_deriv_two_eval d
  -- Step A: control between whole numbers
  have hA : (N : ℝ) ^ 2 * H ≤ (N : ℝ) ^ 2 / 2 + 2 * T2 * H := by
    set r := round x0 with hr
    have hr0 : 0 ≤ r := by
      rw [hr, round_eq]; exact Int.floor_nonneg.2 (by linarith [hx0.1])
    have hrN : r ≤ N := by
      have h1 := round_le_add_half x0
      have h' : ((r : ℤ) : ℝ) < ((N : ℤ) : ℝ) + 1 := by push_cast; linarith [hx0.2]
      have : r < (N : ℤ) + 1 := by exact_mod_cast h'
      omega
    have hrd : |x0 - r| ≤ 1 / 2 := abs_sub_round x0
    set i := r.toNat with hi_def
    have hi : ((i : ℕ) : ℝ) = (r : ℝ) := by
      rw [hi_def]
      exact_mod_cast Int.toNat_of_nonneg hr0
    have hiN : i ≤ N := by omega
    obtain ⟨η, hη, htay⟩ := poly_taylor2 q x0 i
    have hzero : (derivative q).eval x0 * ((i : ℝ) - x0) = 0 := by
      by_cases hin : x0 ∈ Set.Ioo (0 : ℝ) N
      · have hnhds : Set.Icc (0 : ℝ) N ∈ nhds x0 := Icc_mem_nhds hin.1 hin.2
        have hd0' : deriv (fun x => q.eval x) x0 = 0 := by
          by_cases hs : 1 / 2 ≤ q.eval x0
          · have hlm : IsLocalMax (fun x => q.eval x) x0 :=
              Filter.mem_of_superset hnhds (fun x hx => by
                have h1 := hH x hx
                have h2 : H = q.eval x0 - 1 / 2 := abs_of_nonneg (by linarith)
                show q.eval x ≤ q.eval x0
                linarith [(abs_le.1 h1).2])
            exact hlm.deriv_eq_zero
          · push Not at hs
            have hlm : IsLocalMin (fun x => q.eval x) x0 :=
              Filter.mem_of_superset hnhds (fun x hx => by
                have h1 := hH x hx
                have h2 : H = -(q.eval x0 - 1 / 2) := abs_of_neg (by linarith)
                show q.eval x0 ≤ q.eval x
                linarith [(abs_le.1 h1).1])
            exact hlm.deriv_eq_zero
        rw [Polynomial.deriv] at hd0'
        rw [hd0', zero_mul]
      · have hx : x0 = 0 ∨ x0 = N := by
          by_contra hne
          push Not at hne
          exact hin ⟨lt_of_le_of_ne hx0.1 (Ne.symm hne.1), lt_of_le_of_ne hx0.2 hne.2⟩
        have : (i : ℝ) = x0 := by
          rw [hi, hr]
          rcases hx with h | h
          · rw [h]; simp
          · rw [h, round_natCast]; simp
        rw [this, sub_self, mul_zero]
    have hηI : η ∈ Set.Icc (0 : ℝ) N := by
      have hiI : (i : ℝ) ∈ Set.Icc (0 : ℝ) N :=
        ⟨by positivity, by exact_mod_cast hiN⟩
      exact Set.uIcc_subset_Icc hx0 hiI hη
    have hint := second_deriv_interior q N H η hNpos hηI hH
    rw [← hd, ← hT2def] at hint
    have hqi := hprob i hiN
    have hqi' : |q.eval (i : ℝ) - 1 / 2| ≤ 1 / 2 := abs_le.2 ⟨by linarith [hqi.1], by linarith [hqi.2]⟩
    have hsq : ((i : ℝ) - x0) ^ 2 ≤ 1 / 4 := by
      rw [hi]
      have := abs_le.1 hrd
      nlinarith [this.1, this.2]
    set B := (derivative^[2] q).eval η
    have hdiff : q.eval x0 - 1 / 2 = (q.eval (i : ℝ) - 1 / 2) - B * ((i : ℝ) - x0) ^ 2 / 2 := by
      linarith
    have hH' : H ≤ 1 / 2 + |B| / 8 := by
      rw [hHdef, hdiff]
      calc |(q.eval (i : ℝ) - 1 / 2) - B * ((i : ℝ) - x0) ^ 2 / 2|
          ≤ |q.eval (i : ℝ) - 1 / 2| + |B * ((i : ℝ) - x0) ^ 2 / 2| := abs_sub _ _
        _ ≤ 1 / 2 + |B| / 8 := by
          gcongr
          rw [abs_div, abs_mul, abs_of_nonneg (sq_nonneg ((i : ℝ) - x0))]
          have hB0 := abs_nonneg B
          norm_num
          nlinarith [mul_le_mul_of_nonneg_left hsq hB0]
    nlinarith [hint, hH', sq_nonneg (N : ℝ)]
  -- Step B: the climb from 0 to 1
  obtain ⟨η1, hη1, htay1⟩ := poly_taylor2 q 0 1
  rw [Set.uIcc_of_le zero_le_one] at hη1
  have hM1 := markov_left q d 1 le_rfl 0 N (1 / 2) H hNpos le_rfl hH
  rw [T_deriv_one_eval] at hM1
  have hM2 := markov_left q d 2 le_rfl η1 N (1 / 2) H (by linarith [hη1.2]) (by norm_num)
    (fun x hx => hH x ⟨by linarith [hx.1, hη1.1], hx.2⟩)
  rw [← hT2def] at hM2
  set A := (derivative q).eval 0
  set B := (derivative^[2] q).eval η1
  have hA' : (N : ℝ) * A ≤ 2 * (d : ℝ) ^ 2 * H := by
    simp only [Function.iterate_one, sub_zero, pow_one] at hM1
    nlinarith [le_abs_self A]
  have hB' : ((N : ℝ) - 1) ^ 2 * B ≤ 4 * T2 * H := by
    have hsq : ((N : ℝ) - 1) ^ 2 ≤ ((N : ℝ) - η1) ^ 2 :=
      pow_le_pow_left₀ (by linarith) (by linarith [hη1.2]) 2
    nlinarith [le_abs_self B, abs_nonneg B, mul_le_mul_of_nonneg_right hsq (abs_nonneg B)]
  have hcl : c ≤ A + B / 2 := by
    have : q.eval 1 - q.eval 0 = A + B / 2 := by rw [htay1]; ring
    linarith
  exact climb_algebra c N ((d : ℝ) ^ 2) T2 H A B hN2 hD1 hDN hT2 hcl hA' hB' hA

#print axioms iterate_derivative_comp_affine
#print axioms poly_taylor2
#print axioms markov_affine
#print axioms markov_left
#print axioms markov_right
#print axioms T_deriv_one_eval
#print axioms T_deriv_two_eval
#print axioms second_deriv_interior
#print axioms climb_algebra
#print axioms climb_degree_bound

/-! The quantum query model itself is not in Mathlib. The statements below start from the
symmetrised yes-probability q(k), which the card's Steps 1 and 2 show is a real polynomial of
degree at most 2T in the number k of marked entries; the card's bound is then a fact about
such polynomials. -/

/-- The polynomial-method search bound (card, Steps 3 and 4). Let q be the yes-probability of a
T-query algorithm, averaged over all lists of N entries with k marked, so q is a real
polynomial of degree at most 2T. If q(k) is a probability (between 0 and 1) at every whole
number k from 0 to N, says "yes" at most 1 time in 3 on the empty list (q(0) ≤ 1/3) and at
least 2 times in 3 with one mark (q(1) ≥ 2/3), then the queries number at least a quarter of
the square root of N: T ≥ √N/4. -/
theorem search_needs_quarter_sqrt_queries (N T : ℕ) (q : ℝ[X])
    (hdeg : q.natDegree ≤ 2 * T)
    (hprob : ∀ k : ℕ, k ≤ N → 0 ≤ q.eval (k : ℝ) ∧ q.eval (k : ℝ) ≤ 1)
    (hzero : q.eval 0 ≤ 1 / 3) (hone : 2 / 3 ≤ q.eval 1) :
    Real.sqrt N / 4 ≤ T := by
  have h := climb_degree_bound N (1 / 3) q (by norm_num) hprob (by linarith)
  have hd : (q.natDegree : ℝ) ≤ 2 * T := by exact_mod_cast hdeg
  have hd0 : (0 : ℝ) ≤ q.natDegree := Nat.cast_nonneg _
  have hN : (N : ℝ) ≤ (4 * T) ^ 2 := by
    have : (N : ℝ) / 4 ≤ (q.natDegree : ℝ) ^ 2 := by
      have e : (1 / 3 : ℝ) * N / (1 / 3 + 1) = N / 4 := by ring
      rwa [e] at h
    nlinarith
  have hT : (0 : ℝ) ≤ 4 * T := by positivity
  have := Real.sqrt_le_sqrt hN
  rw [Real.sqrt_sq hT] at this
  linarith

/-- The degree bound behind it (card, Step 3 and its detailed proof). A real polynomial q of
degree d whose values at the whole numbers 0, 1, …, N all lie in [0, 1], and which climbs by
at least c ≥ 0 from k = 0 to k = 1, has d² ≥ cN/(c + 1). With c = 1/3 this is d ≥ √N/2. -/
theorem bounded_polynomial_climb_forces_degree (N : ℕ) (c : ℝ) (q : ℝ[X]) (hc : 0 ≤ c)
    (hprob : ∀ k : ℕ, k ≤ N → 0 ≤ q.eval (k : ℝ) ∧ q.eval (k : ℝ) ≤ 1)
    (hclimb : c ≤ q.eval 1 - q.eval 0) :
    c * N / (c + 1) ≤ (q.natDegree : ℝ) ^ 2 := by
  exact climb_degree_bound N c q hc hprob hclimb

/-- The Pauli matrix Z = diag(1, −1), in the basis |0⟩, |1⟩. -/
def pauliZ : Matrix (Fin 2) (Fin 2) ℝ := !![1, 0; 0, -1]

/-- The basis state |ab⟩ on two qubits, indexed by the pair (a, b). -/
def ket (a b : Fin 2) : Fin 2 × Fin 2 → ℝ := Pi.single (a, b) 1

/-- The toy local Hamiltonian H = Z ⊗ Z on two qubits (card, Step 6 and worked numbers): its
lowest energy, the least eigenvalue, is −1, and it is reached at |01⟩ and at |10⟩. -/
theorem pauliZ_kron_pauliZ_ground_energy :
    IsLeast (spectrum ℝ (pauliZ ⊗ₖ pauliZ)) (-1) ∧
      (pauliZ ⊗ₖ pauliZ) *ᵥ ket 0 1 = (-1 : ℝ) • ket 0 1 ∧
      (pauliZ ⊗ₖ pauliZ) *ᵥ ket 1 0 = (-1 : ℝ) • ket 1 0 := by
  have hZ : pauliZ = Matrix.diagonal ![1, -1] := by
    ext i j; fin_cases i <;> fin_cases j <;> simp [pauliZ]
  rw [hZ, Matrix.diagonal_kronecker_diagonal, spectrum_diagonal]
  refine ⟨⟨⟨(0, 1), by simp⟩, ?_⟩, ?_, ?_⟩
  · rintro r ⟨⟨a, b⟩, rfl⟩
    fin_cases a <;> fin_cases b <;> norm_num
  · ext ⟨a, b⟩
    simp only [Matrix.mulVec_diagonal, ket, Pi.smul_apply, smul_eq_mul]
    fin_cases a <;> fin_cases b <;> simp
  · ext ⟨a, b⟩
    simp only [Matrix.mulVec_diagonal, ket, Pi.smul_apply, smul_eq_mul]
    fin_cases a <;> fin_cases b <;> simp

-- Z ⊗ Z is diagonal 1, −1, −1, 1 on |00⟩, |01⟩, |10⟩, |11⟩.
example : (pauliZ ⊗ₖ pauliZ) (0, 0) (0, 0) = 1 ∧ (pauliZ ⊗ₖ pauliZ) (0, 1) (0, 1) = -1 ∧
    (pauliZ ⊗ₖ pauliZ) (1, 0) (1, 0) = -1 ∧ (pauliZ ⊗ₖ pauliZ) (1, 1) (1, 1) = 1 := by
  norm_num [pauliZ, Matrix.kroneckerMap_apply]

-- The query floor for N = 1,000,000: √N = 1,000, so √N/4 = 250 queries and √N/2 = 500 degree.
example : 1000 * 1000 = 1000000 ∧ 4 * 250 = 1000 ∧ 2 * 250 = 500 := by norm_num

-- Grover's 478 rounds plus 1 checking query make 479 queries, so degree at most 2 × 479 = 958,
-- at least the 500 the bound needs; counting degree T instead would give a "floor" of 500,
-- above the 479 queries Grover uses.
example : 478 + 1 = 479 ∧ 2 * 479 = 958 ∧ 500 ≤ 958 ∧ 479 < 500 := by norm_num

-- Ordinary looks that see the mark with probability 2/3: 2N/3 rounded up is 666,667.
example : (2 * 1000000 + 2) / 3 = 666667 := by norm_num

-- Binary search on a sorted list of 1,000,000 entries: 20 looks, since 2^19 < 1,000,000 ≤ 2^20.
example : 2 ^ 19 < 1000000 ∧ 1000000 ≤ 2 ^ 20 := by norm_num

-- The degree-1 line q(k) = (1 + k)/3 passes 1/3 and 2/3 but is far above 1 at k = 1,000,000.
example : ((1 : ℚ) + 0) / 3 = 1 / 3 ∧ ((1 : ℚ) + 1) / 3 = 2 / 3 ∧
    ((1 : ℚ) + 1000000) / 3 = 1000001 / 3 ∧ (1 : ℚ) < 1000001 / 3 := by norm_num

-- Hybrid sum on Grover with 16 entries and 3 rounds is bounded by 2 × T × √16 = 2 × 3 × 4 = 24.
example : 4 * 4 = 16 ∧ 2 * 3 * 4 = 24 := by norm_num

#print axioms search_needs_quarter_sqrt_queries
#print axioms bounded_polynomial_climb_forces_degree
#print axioms pauliZ_kron_pauliZ_ground_energy
