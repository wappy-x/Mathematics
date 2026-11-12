-- Trapezoid, midpoint and Simpson: a composite Newton-Cotes rule exact up to degree d errs by at most a constant times the panel width to the power d + 1, and the closed rule on m + 1 equally spaced points is exact up to degree m, or m + 1 when m is even.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.Topology.Algebra.Polynomial

open Polynomial

/-! A one-panel rule is given per unit width: nodes `x j` in `[0, 1]` and weights `w j`.
On a panel `[c, c + H]` it reads `H * ∑ j, w j * f (c + x j * H)`.
The composite rule `Q_n` cuts `[a, b]` into `n` slices of width `h = (b - a) / n`,
groups them into `n / m` panels of width `m h`, applies the rule on each panel and adds. -/

/-- The composite rule `Q_n`: `n / m` panels of width `m h`, `h = (b - a) / n`,
the one-panel rule (nodes `x j`, weights `w j`, per unit width) on each, added up. -/
noncomputable def compositeRule {k : ℕ} (x w : Fin k → ℝ) (m n : ℕ) (f : ℝ → ℝ) (a b : ℝ) : ℝ :=
  ∑ p ∈ Finset.range (n / m), ∑ j, ((m : ℝ) * ((b - a) / n)) * w j *
    f (a + ((p : ℝ) + x j) * ((m : ℝ) * ((b - a) / n)))

/-- The closed Newton-Cotes weight `w_j = (1/m) ∫₀^m ℓ_j(s) ds`, per unit width,
where `ℓ_j` is Mathlib's Lagrange basis polynomial on the nodes `0, 1, ..., m`. -/
noncomputable def newtonCotesWeight (m : ℕ) (j : Fin (m + 1)) : ℝ :=
  (1 / (m : ℝ)) * ∫ s in (0 : ℝ)..m,
    (Lagrange.basis Finset.univ (fun i : Fin (m + 1) => (i : ℝ)) j).eval s

/-- Taylor's theorem on a sub-panel `[c, t]` of `[a, b]`, with the Taylor polynomial taken
within `[a, b]` and the Lagrange remainder bounded by `B (t - c)^(d+1) / (d+1)!`. -/
lemma taylor_panel_bound {f : ℝ → ℝ} {a b B c t : ℝ} {d : ℕ}
    (hf : ContDiffOn ℝ (d + 1) f (Set.Icc a b))
    (hB : ∀ y ∈ Set.Icc a b, |iteratedDerivWithin (d + 1) f (Set.Icc a b) y| ≤ B)
    (hac : a ≤ c) (hct : c ≤ t) (htb : t ≤ b) :
    |f t - taylorWithinEval f d (Set.Icc a b) c t| ≤
      B * (t - c) ^ (d + 1) / (d + 1).factorial := by
  rcases hct.eq_or_lt with rfl | hlt
  · simp [taylorWithinEval_self]
  have hab : a < b := by linarith
  have hsub : Set.uIcc c t ⊆ Set.Icc a b := by
    rw [Set.uIcc_of_le hct]; exact Set.Icc_subset_Icc hac htb
  obtain ⟨x', hx', heq⟩ := taylor_mean_remainder_lagrange_iteratedDeriv hlt.ne (hf.mono hsub)
  rw [Set.uIoo_of_le hct] at hx'
  obtain ⟨hx1, hx2⟩ := hx'
  have htaylor : taylorWithinEval f d (Set.uIcc c t) c t =
      taylorWithinEval f d (Set.Icc a b) c t := by
    simp only [taylor_within_apply]
    refine Finset.sum_congr rfl (fun k hk => ?_)
    have hk' : k < d + 1 := Finset.mem_range.mp hk
    congr 1
    simp only [iteratedDerivWithin]
    rw [iteratedFDerivWithin_subset hsub (uniqueDiffOn_uIcc hlt.ne) (uniqueDiffOn_Icc hab)
      (hf.of_le (by exact_mod_cast hk'.le)) Set.left_mem_uIcc]
  have hx'Icc : x' ∈ Set.Icc a b := ⟨by linarith, by linarith⟩
  have hderiv : iteratedDeriv (d + 1) f x' = iteratedDerivWithin (d + 1) f (Set.Icc a b) x' :=
    (iteratedDerivWithin_eq_iteratedDeriv (uniqueDiffOn_Icc hab)
      ((hf.contDiffAt (Icc_mem_nhds (by linarith) (by linarith))).of_le
        (by exact_mod_cast le_refl _)) hx'Icc).symm
  rw [← htaylor, heq, hderiv, abs_div, abs_mul, abs_of_nonneg (pow_nonneg (sub_nonneg.mpr hct) (d + 1)),
    abs_of_pos (by positivity : (0 : ℝ) < ((d + 1).factorial : ℝ))]
  gcongr
  exact hB x' hx'Icc

#print axioms taylor_panel_bound

/-- A one-panel rule exact up to degree `d` on `[0, 1]` is exact up to degree `d` on any panel
`[c, c + H]`, after scaling. -/
lemma panel_rule_exact {k : ℕ} (x w : Fin k → ℝ) (d : ℕ)
    (hexact : ∀ q : ℝ[X], q.natDegree ≤ d →
      ∑ j, w j * q.eval (x j) = ∫ s in (0 : ℝ)..1, q.eval s)
    (P : ℝ[X]) (hP : P.natDegree ≤ d) (c H : ℝ) :
    H * ∑ j, w j * P.eval (c + x j * H) = ∫ t in c..c + H, P.eval t := by
  by_cases hH : H = 0
  · simp [hH]
  have hq : (P.comp (C H * X + C c)).natDegree ≤ d := by
    refine natDegree_comp_le.trans ?_
    calc P.natDegree * (C H * X + C c).natDegree ≤ P.natDegree * 1 := by
          gcongr; exact natDegree_linear_le
      _ ≤ d := by rw [mul_one]; exact hP
  have h := hexact _ hq
  simp only [eval_comp, eval_add, eval_mul, eval_C, eval_X] at h
  rw [intervalIntegral.integral_comp_mul_add (fun t => P.eval t) hH] at h
  simp only [mul_zero, zero_add, mul_one, smul_eq_mul] at h
  have h2 : ∑ j, w j * P.eval (c + x j * H) = ∑ j, w j * P.eval (H * x j + c) := by
    refine Finset.sum_congr rfl (fun j _ => ?_)
    rw [show c + x j * H = H * x j + c by ring]
  rw [h2, h, add_comm H c]
  field_simp

#print axioms panel_rule_exact

/-- The degree-`d` Taylor polynomial of `f` at `c`, within `[a, b]`, as a polynomial. -/
noncomputable def taylorPoly (f : ℝ → ℝ) (d : ℕ) (s : Set ℝ) (c : ℝ) : ℝ[X] :=
  ∑ i ∈ Finset.range (d + 1), C (iteratedDerivWithin i f s c / (i.factorial : ℝ)) * (X - C c) ^ i

/-- Evaluating `taylorPoly` gives Mathlib's `taylorWithinEval`. -/
lemma taylorPoly_eval (f : ℝ → ℝ) (d : ℕ) (s : Set ℝ) (c t : ℝ) :
    (taylorPoly f d s c).eval t = taylorWithinEval f d s c t := by
  simp only [taylorPoly, taylor_within_apply, eval_finsetSum, eval_mul, eval_C, eval_pow, eval_sub,
    eval_X, smul_eq_mul]
  refine Finset.sum_congr rfl (fun i _ => ?_)
  ring

#print axioms taylorPoly_eval

/-- `taylorPoly f d s c` has degree at most `d`. -/
lemma taylorPoly_natDegree (f : ℝ → ℝ) (d : ℕ) (s : Set ℝ) (c : ℝ) :
    (taylorPoly f d s c).natDegree ≤ d := by
  refine natDegree_sum_le_of_forall_le _ _ (fun i hi => ?_)
  refine (natDegree_C_mul_le _ _).trans ?_
  rw [natDegree_pow, natDegree_X_sub_C, mul_one]
  exact Nat.lt_succ_iff.mp (Finset.mem_range.mp hi)

#print axioms taylorPoly_natDegree

/-- The error of the rule on one panel `[c, c + H] ⊆ [a, b]` is at most
`(1 + W) H B H^(d+1) / (d+1)!`. -/
lemma panel_error_bound {k : ℕ} (x w : Fin k → ℝ) (d : ℕ) (f : ℝ → ℝ) (a b B c H : ℝ)
    (hx : ∀ j, x j ∈ Set.Icc (0 : ℝ) 1)
    (hexact : ∀ q : ℝ[X], q.natDegree ≤ d →
      ∑ j, w j * q.eval (x j) = ∫ s in (0 : ℝ)..1, q.eval s)
    (hf : ContDiffOn ℝ (d + 1) f (Set.Icc a b))
    (hB : ∀ y ∈ Set.Icc a b, |iteratedDerivWithin (d + 1) f (Set.Icc a b) y| ≤ B)
    (hB0 : 0 ≤ B) (hac : a ≤ c) (hH : 0 ≤ H) (hcb : c + H ≤ b) :
    |(∫ t in c..c + H, f t) - H * ∑ j, w j * f (c + x j * H)| ≤
      (1 + ∑ j, |w j|) * H * (B * H ^ (d + 1) / (d + 1).factorial) := by
  set M := B * H ^ (d + 1) / (d + 1).factorial
  set P := taylorPoly f d (Set.Icc a b) c
  set g : ℝ → ℝ := fun t => f t - P.eval t
  have hg : ∀ t ∈ Set.Icc c (c + H), |g t| ≤ M := by
    intro t ht
    simp only [g, P, taylorPoly_eval]
    refine (taylor_panel_bound hf hB hac ht.1 (by linarith [ht.2])).trans ?_
    simp only [M]
    gcongr
    · linarith [ht.1]
    · linarith [ht.2]
  have hex := panel_rule_exact x w d hexact P (taylorPoly_natDegree _ _ _ _) c H
  have hsub : Set.uIcc c (c + H) ⊆ Set.Icc a b := by
    rw [Set.uIcc_of_le (by linarith)]; exact Set.Icc_subset_Icc hac hcb
  have hfint : IntervalIntegrable f MeasureTheory.volume c (c + H) :=
    (hf.continuousOn.mono hsub).intervalIntegrable
  have hPint : IntervalIntegrable (fun t => P.eval t) MeasureTheory.volume c (c + H) :=
    (Polynomial.continuous P).intervalIntegrable _ _
  have hsplit : (∫ t in c..c + H, f t) - H * ∑ j, w j * f (c + x j * H) =
      (∫ t in c..c + H, g t) - H * ∑ j, w j * g (c + x j * H) := by
    simp only [g]
    rw [intervalIntegral.integral_sub hfint hPint, ← hex]
    simp only [mul_sub, Finset.sum_sub_distrib]
    ring
  rw [hsplit]
  have h1 : |∫ t in c..c + H, g t| ≤ M * H := by
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := c) (b := c + H) (C := M)
      (f := g) (fun t ht => by
        rw [Set.uIoc_of_le (by linarith)] at ht
        exact hg t ⟨ht.1.le, ht.2⟩)
    simpa [Real.norm_eq_abs, abs_of_nonneg hH] using this
  have h2 : |H * ∑ j, w j * g (c + x j * H)| ≤ H * ((∑ j, |w j|) * M) := by
    rw [abs_mul, abs_of_nonneg hH]
    gcongr
    refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
    rw [Finset.sum_mul]
    refine Finset.sum_le_sum (fun j _ => ?_)
    rw [abs_mul]
    gcongr
    apply hg
    obtain ⟨h0, h1⟩ := hx j
    constructor
    · nlinarith
    · nlinarith
  calc |(∫ t in c..c + H, g t) - H * ∑ j, w j * g (c + x j * H)|
      ≤ |∫ t in c..c + H, g t| + |H * ∑ j, w j * g (c + x j * H)| := abs_sub _ _
    _ ≤ M * H + H * ((∑ j, |w j|) * M) := add_le_add h1 h2
    _ = (1 + ∑ j, |w j|) * H * M := by ring

#print axioms panel_error_bound

/-- The node polynomial `∏ (t - i)` on the nodes `0, 1, ..., m` has zero integral over `[0, m]`
when `m` is even, since it is odd about `m / 2`. -/
lemma nodal_integral_eq_zero_of_even (m : ℕ) (hm : Even m) :
    ∫ t in (0 : ℝ)..m,
      (Lagrange.nodal Finset.univ (fun i : Fin (m + 1) => (i : ℝ))).eval t = 0 := by
  set N := Lagrange.nodal Finset.univ (fun i : Fin (m + 1) => (i : ℝ))
  have hsym : ∀ t : ℝ, N.eval ((m : ℝ) - t) = - N.eval t := by
    intro t
    simp only [N, Lagrange.eval_nodal]
    have h1 : ∀ i : Fin (m + 1), (m : ℝ) - t - (i : ℝ) = (-1) * (t - ((Fin.rev i : ℕ) : ℝ)) := by
      intro i
      have hi := i.isLt
      rw [Fin.val_rev]
      rw [Nat.cast_sub (by omega)]
      push_cast
      ring
    rw [Finset.prod_congr rfl (fun i _ => h1 i), Finset.prod_mul_distrib, Finset.prod_const,
      Finset.card_univ, Fintype.card_fin,
      Fintype.prod_equiv Fin.revPerm (fun i => t - ((Fin.rev i : ℕ) : ℝ)) (fun i => t - (i : ℝ))
        (fun i => rfl)]
    rw [pow_succ, hm.neg_one_pow]
    ring
  have h2 : ∫ t in (0 : ℝ)..m, N.eval t = ∫ t in (0 : ℝ)..m, N.eval ((m : ℝ) - t) := by
    rw [intervalIntegral.integral_comp_sub_left (fun t => N.eval t) (m : ℝ)]
    simp
  simp only [hsym, intervalIntegral.integral_neg] at h2
  linarith

#print axioms nodal_integral_eq_zero_of_even

/-- The composite error bound. Take a one-panel rule with nodes in the panel whose degree of
exactness is at least `d`: it gets the area of every polynomial of degree `d` or less exactly
right. Let `f` be `d + 1` times continuously differentiable on `[a, b]`, with its `(d+1)`th
derivative at most `B` in size there. Cut `[a, b]` into `n` slices of width `h = (b - a) / n`,
`n` a multiple of `m`, and apply the rule on each of the `n / m` panels of width `m h`.
Then the error is at most `(1 + W) (b - a) B (m h)^(d+1) / (d+1)!`, where `W = ∑ |w_j|`. -/
theorem composite_newton_cotes_error_bound {k : ℕ} (x w : Fin k → ℝ) (d m n : ℕ)
    (f : ℝ → ℝ) (a b B : ℝ)
    (hab : a ≤ b) (hm : 0 < m) (hn : 0 < n) (hmn : m ∣ n)
    (hx : ∀ j, x j ∈ Set.Icc (0 : ℝ) 1)
    (hexact : ∀ q : ℝ[X], q.natDegree ≤ d →
      ∑ j, w j * q.eval (x j) = ∫ s in (0 : ℝ)..1, q.eval s)
    (hf : ContDiffOn ℝ (d + 1) f (Set.Icc a b))
    (hB : ∀ y ∈ Set.Icc a b, |iteratedDerivWithin (d + 1) f (Set.Icc a b) y| ≤ B) :
    let h : ℝ := (b - a) / n
    |(∫ t in a..b, f t) - compositeRule x w m n f a b| ≤
      (1 + ∑ j, |w j|) * (b - a) * B * ((m : ℝ) * h) ^ (d + 1) / (d + 1).factorial := by
  intro h
  set H : ℝ := (m : ℝ) * h with hHdef
  set N : ℕ := n / m with hNdef
  have hB0 : 0 ≤ B := (abs_nonneg _).trans (hB a ⟨le_rfl, hab⟩)
  have hn0 : (n : ℝ) ≠ 0 := by positivity
  have hm0 : (m : ℝ) ≠ 0 := by positivity
  have hH0 : 0 ≤ H := by
    simp only [H, h]; have : (0 : ℝ) ≤ b - a := by linarith
    positivity
  have hNH : (N : ℝ) * H = b - a := by
    simp only [N, H, h]
    rw [Nat.cast_div hmn hm0]
    field_simp
  set M := B * H ^ (d + 1) / (d + 1).factorial
  set W := ∑ j, |w j|
  set cp : ℕ → ℝ := fun p => a + (p : ℝ) * H with hcp
  have hrule : compositeRule x w m n f a b =
      ∑ p ∈ Finset.range N, H * ∑ j, w j * f (cp p + x j * H) := by
    simp only [compositeRule]
    refine Finset.sum_congr rfl (fun p _ => ?_)
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl (fun j _ => ?_)
    simp only [cp]
    rw [show a + ((p : ℝ) + x j) * H = a + (p : ℝ) * H + x j * H by ring]
    ring
  have hint : (∫ t in a..b, f t) = ∑ p ∈ Finset.range N, ∫ t in cp p..cp p + H, f t := by
    have hcs : ∀ p : ℕ, cp (p + 1) = cp p + H := by
      intro p; simp only [cp]; push_cast; ring
    have := intervalIntegral.sum_integral_adjacent_intervals (f := f) (μ := MeasureTheory.volume)
      (a := cp) (n := N) (fun p hp => by
        rw [hcs]
        refine (hf.continuousOn.mono ?_).intervalIntegrable
        rw [Set.uIcc_of_le (by linarith)]
        refine Set.Icc_subset_Icc ?_ ?_
        · simp only [cp]; have : (0 : ℝ) ≤ p * H := by positivity
          linarith
        · simp only [cp]
          have : ((p : ℝ) + 1) * H ≤ N * H := by
            gcongr; exact_mod_cast hp
          nlinarith)
    simp only [hcs] at this
    rw [this]
    simp only [cp]
    congr 1
    · simp
    · rw [hNH]; ring
  rw [hrule, hint, ← Finset.sum_sub_distrib]
  refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
  calc ∑ p ∈ Finset.range N, |(∫ t in cp p..cp p + H, f t) - H * ∑ j, w j * f (cp p + x j * H)|
      ≤ ∑ p ∈ Finset.range N, (1 + W) * H * M := by
        refine Finset.sum_le_sum (fun p hp => ?_)
        refine panel_error_bound x w d f a b B (cp p) H hx hexact hf hB hB0 ?_ hH0 ?_
        · simp only [cp]; have : (0 : ℝ) ≤ p * H := by positivity
          linarith
        · simp only [cp]
          have : ((p : ℝ) + 1) * H ≤ N * H := by
            gcongr; exact_mod_cast (Finset.mem_range.mp hp)
          nlinarith
    _ = (1 + W) * (b - a) * B * H ^ (d + 1) / (d + 1).factorial := by
        rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul, ← hNH]
        simp only [M]
        ring

/-- The degree of exactness of the closed Newton-Cotes rule on `m + 1` equally spaced nodes
`0, 1/m, ..., 1` (per unit width), `m ≥ 1`: it integrates every polynomial of degree `m` or
less exactly, and when `m` is even, every polynomial of degree `m + 1` too. -/
theorem newton_cotes_degree_of_exactness (m : ℕ) (hm : 0 < m) (q : ℝ[X])
    (hq : q.natDegree ≤ m ∨ (Even m ∧ q.natDegree ≤ m + 1)) :
    ∑ j : Fin (m + 1), newtonCotesWeight m j * q.eval ((j : ℝ) / m) =
      ∫ s in (0 : ℝ)..1, q.eval s := by
  set v : Fin (m + 1) → ℝ := fun i => (i : ℝ) with hv
  have hvinj : Set.InjOn v (Finset.univ : Finset (Fin (m + 1))) := by
    intro i _ j _ hij
    simp only [v, Nat.cast_inj] at hij
    exact Fin.ext hij
  have hm0 : (m : ℝ) ≠ 0 := by positivity
  set N := Lagrange.nodal (Finset.univ : Finset (Fin (m + 1))) v with hN
  have hNmonic : N.Monic := Lagrange.nodal_monic
  have hNdeg : N.natDegree = m + 1 := by
    rw [hN, Lagrange.natDegree_nodal, Finset.card_univ, Fintype.card_fin]
  set r : ℝ[X] := q.comp (C (1 / (m : ℝ)) * X) with hr
  have hreval : ∀ t, r.eval t = q.eval (t / m) := by
    intro t; simp [r, eval_comp]; ring_nf
  have hrdeg : r.natDegree ≤ q.natDegree := by
    refine (natDegree_comp_le).trans ?_
    have : (C (1 / (m : ℝ)) * X).natDegree ≤ 1 := (natDegree_C_mul_le _ _).trans natDegree_X_le
    calc q.natDegree * (C (1 / (m : ℝ)) * X).natDegree ≤ q.natDegree * 1 := by gcongr
      _ = q.natDegree := mul_one _
  set R := r %ₘ N
  set Q := r /ₘ N
  have hsplit : r = R + N * Q := (modByMonic_add_div r N).symm
  have hRdeg : R.degree < (Finset.univ : Finset (Fin (m + 1))).card := by
    rw [Finset.card_univ, Fintype.card_fin]
    have := degree_modByMonic_lt r hNmonic
    rwa [degree_eq_natDegree hNmonic.ne_zero, hNdeg] at this
  have hRnode : ∀ i, R.eval (v i) = r.eval (v i) := by
    intro i
    have := congrArg (eval (v i)) hsplit
    rw [eval_add, eval_mul, Lagrange.eval_nodal_at_node (Finset.mem_univ i), zero_mul,
      add_zero] at this
    exact this.symm
  have hRinterp := Lagrange.eq_interpolate hvinj hRdeg
  have hReval : ∀ t, R.eval t = ∑ i, r.eval (v i) * (Lagrange.basis Finset.univ v i).eval t := by
    intro t
    conv_lhs => rw [hRinterp]
    simp [Lagrange.interpolate_apply, eval_finsetSum, hRnode]
  have hNQ : ∫ t in (0 : ℝ)..m, (N * Q).eval t = 0 := by
    rcases hq with hq | ⟨hev, hq⟩
    · have : Q = 0 := by
        rw [divByMonic_eq_zero_iff hNmonic, degree_eq_natDegree hNmonic.ne_zero, hNdeg]
        refine lt_of_le_of_lt (degree_le_natDegree) ?_
        exact_mod_cast (show r.natDegree < m + 1 by omega)
      simp [this]
    · have hQ0 : Q.natDegree = 0 := by
        rw [natDegree_divByMonic r hNmonic, hNdeg]; omega
      rw [eq_C_of_natDegree_eq_zero hQ0]
      simp only [eval_mul, eval_C]
      rw [intervalIntegral.integral_mul_const]
      have := nodal_integral_eq_zero_of_even m hev
      simp only [N, v] at this ⊢
      rw [this, zero_mul]
  have hint : ∀ p : ℝ[X], IntervalIntegrable (fun t => p.eval t) MeasureTheory.volume (0 : ℝ) m :=
    fun p => (Polynomial.continuous p).intervalIntegrable _ _
  -- integral of r over [0, m]
  have hrint : ∫ t in (0 : ℝ)..m, r.eval t = m * ∫ s in (0 : ℝ)..1, q.eval s := by
    simp only [hreval]
    rw [intervalIntegral.integral_comp_div (fun s => q.eval s) hm0]
    simp [hm0]
  have hRint : ∫ t in (0 : ℝ)..m, R.eval t =
      ∑ i, r.eval (v i) * ∫ t in (0 : ℝ)..m, (Lagrange.basis Finset.univ v i).eval t := by
    simp only [hReval]
    rw [intervalIntegral.integral_finsetSum (fun i _ => (hint _).const_mul _)]
    simp [intervalIntegral.integral_const_mul]
  have hrR : ∫ t in (0 : ℝ)..m, r.eval t = ∫ t in (0 : ℝ)..m, R.eval t := by
    conv_lhs => rw [hsplit]
    simp only [eval_add]
    rw [intervalIntegral.integral_add (hint R) (hint (N * Q)), hNQ, add_zero]
  have key : (m : ℝ) * ∑ j : Fin (m + 1), newtonCotesWeight m j * q.eval ((j : ℝ) / m) =
      m * ∫ s in (0 : ℝ)..1, q.eval s := by
    rw [← hrint, hrR, hRint, Finset.mul_sum]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    rw [newtonCotesWeight, hreval]
    simp only [v]
    field_simp
  exact mul_left_cancel₀ hm0 key

/-- The wind day's true energy: the power `P(t) = (3 + t (24 - t) / 24)^3 / 50` kW,
integrated over 24 hours, is exactly `170748/875` kWh (about 195.140571429). -/
theorem wind_day_energy_exact :
    ∫ t in (0 : ℝ)..24, (3 + t * (24 - t) / 24) ^ 3 / 50 = (170748 : ℝ) / 875 := by
  let P : ℝ[X] := C (27/50) * X + C (27/100) * X ^ 2 + C (21/400) * X ^ 3 + C (1/800) * X ^ 4
    - C (7/16000) * X ^ 5 + C (1/57600) * X ^ 6 - C (1/4838400) * X ^ 7
  have hd : ∀ t ∈ Set.uIcc (0:ℝ) 24, HasDerivAt (fun t => P.eval t)
      ((3 + t * (24 - t) / 24) ^ 3 / 50) t := by
    intro t _
    have := Polynomial.hasDerivAt P t
    convert this using 1
    simp only [P, derivative_add, derivative_sub, derivative_C_mul_X, derivative_C_mul_X_pow,
      eval_add, eval_sub, eval_mul, eval_C, eval_pow, eval_X]
    push_cast
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd
    (by apply Continuous.intervalIntegrable; fun_prop)]
  simp only [P, eval_add, eval_sub, eval_mul, eval_C, eval_pow, eval_X]
  norm_num

/-! The card's rules, checked in exact fractions: each rule's moments `∑ w_j x_j^i` equal
`1 / (i + 1)` up to its degree, and miss at the next power. -/

-- Simpson (m = 2): nodes 0, 1/2, 1, weights 1/6, 2/3, 1/6; exact for s^0 to s^3, not s^4.
example : ∀ i ∈ Finset.range 4,
    ∑ j : Fin 3, ![(1 : ℚ) / 6, 2 / 3, 1 / 6] j * (![(0 : ℚ), 1 / 2, 1] j) ^ i = 1 / (i + 1) := by
  intro i hi
  simp only [Finset.mem_range] at hi
  interval_cases i <;> simp [Fin.sum_univ_succ] <;> norm_num

example : ∑ j : Fin 3, ![(1 : ℚ) / 6, 2 / 3, 1 / 6] j * (![(0 : ℚ), 1 / 2, 1] j) ^ 4 ≠ 1 / 5 := by
  simp [Fin.sum_univ_succ]; norm_num

-- Three-eighths (m = 3): weights 1/8, 3/8, 3/8, 1/8; exact for s^0 to s^3, not s^4.
example : ∀ i ∈ Finset.range 4,
    ∑ j : Fin 4, ![(1 : ℚ) / 8, 3 / 8, 3 / 8, 1 / 8] j * (![(0 : ℚ), 1 / 3, 2 / 3, 1] j) ^ i
      = 1 / (i + 1) := by
  intro i hi
  simp only [Finset.mem_range] at hi
  interval_cases i <;> simp [Fin.sum_univ_succ] <;> norm_num

example : ∑ j : Fin 4, ![(1 : ℚ) / 8, 3 / 8, 3 / 8, 1 / 8] j * (![(0 : ℚ), 1 / 3, 2 / 3, 1] j) ^ 4
    ≠ 1 / 5 := by
  simp [Fin.sum_univ_succ]; norm_num

-- Boole (m = 4): weights 7/90, 16/45, 2/15, 16/45, 7/90; exact for s^0 to s^5, not s^6.
example : ∀ i ∈ Finset.range 6,
    ∑ j : Fin 5, ![(7 : ℚ) / 90, 16 / 45, 2 / 15, 16 / 45, 7 / 90] j *
      (![(0 : ℚ), 1 / 4, 1 / 2, 3 / 4, 1] j) ^ i = 1 / (i + 1) := by
  intro i hi
  simp only [Finset.mem_range] at hi
  interval_cases i <;> simp [Fin.sum_univ_succ] <;> norm_num

example : ∑ j : Fin 5, ![(7 : ℚ) / 90, 16 / 45, 2 / 15, 16 / 45, 7 / 90] j *
    (![(0 : ℚ), 1 / 4, 1 / 2, 3 / 4, 1] j) ^ 6 ≠ 1 / 7 := by
  simp [Fin.sum_univ_succ]; norm_num

-- Milne's open rule: nodes 1/4, 1/2, 3/4, weights 2/3, -1/3, 2/3; exact for s^0 to s^3.
example : ∀ i ∈ Finset.range 4,
    ∑ j : Fin 3, ![(2 : ℚ) / 3, -1 / 3, 2 / 3] j * (![(1 : ℚ) / 4, 1 / 2, 3 / 4] j) ^ i
      = 1 / (i + 1) := by
  intro i hi
  simp only [Finset.mem_range] at hi
  interval_cases i <;> simp [Fin.sum_univ_succ] <;> norm_num

-- Road 2: the 7-point rule (m = 6, weights 41/840, 9/35, 9/280, 34/105, 9/280, 9/35, 41/840)
-- on readings four hours apart gives exactly 170748/875 kWh.
example : ∑ j : Fin 7, ![(41 : ℚ) / 840, 9 / 35, 9 / 280, 34 / 105, 9 / 280, 9 / 35, 41 / 840] j *
    24 * ((3 + (4 * (j : ℚ)) * (24 - 4 * (j : ℚ)) / 24) ^ 3 / 50) = 170748 / 875 := by
  simp [Fin.sum_univ_succ]; norm_num

-- m = 8: weights (989, 5888, -928, 10496, -4540, 10496, -928, 5888, 989) / 28350.
-- They are exact for s^0 to s^9, one is negative, and W_8 = ∑ |w_j| = 41142/28350 (about 1.4512).
example : ∀ i ∈ Finset.range 10,
    ∑ j : Fin 9, ![(989 : ℚ), 5888, -928, 10496, -4540, 10496, -928, 5888, 989] j / 28350 *
      ((j : ℚ) / 8) ^ i = 1 / (i + 1) := by
  intro i hi
  simp only [Finset.mem_range] at hi
  interval_cases i <;> simp [Fin.sum_univ_succ] <;> norm_num

example : ∑ j : Fin 9,
    |![(989 : ℚ), 5888, -928, 10496, -4540, 10496, -928, 5888, 989] j / 28350| = 41142 / 28350 := by
  simp [Fin.sum_univ_succ]; norm_num [abs_of_neg]

#print axioms composite_newton_cotes_error_bound
#print axioms newton_cotes_degree_of_exactness
#print axioms wind_day_energy_exact
