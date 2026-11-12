-- Gaussian quadrature: an n-point rule with its nodes at the n zeros of the Legendre polynomial of degree n, which are distinct and lie strictly inside -1 to 1, integrates every polynomial of degree up to 2n - 1 exactly on -1 to 1, and no n-point rule is exact for every polynomial of degree 2n.
import Mathlib.RingTheory.Polynomial.ShiftedLegendre
import Mathlib.LinearAlgebra.Lagrange
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.LocalExtr.Polynomial

open Polynomial intervalIntegral

/-- The Legendre polynomial `P_n` on `-1` to `1`, built from Mathlib's shifted Legendre
polynomial on `0` to `1`: `P_n(t) = (-1)^n * shiftedLegendre n ((1 + t) / 2)`. The sign makes
`P_n(1) = 1`, as on the Legendre card; for example `P_2 = (3t^2 - 1)/2`. -/
noncomputable def legendreP (n : ℕ) : ℝ[X] :=
  (-1) ^ n * ((shiftedLegendre n).map (Int.castRingHom ℝ)).comp (C (1 / 2) * (X + 1))

lemma gq_rodrigues (n : ℕ) :
    (n.factorial : ℝ[X]) * (shiftedLegendre n).map (Int.castRingHom ℝ) =
      derivative^[n] (X ^ n * (1 - X : ℝ[X]) ^ n) := by
  have := congrArg (Polynomial.map (Int.castRingHom ℝ)) (factorial_mul_shiftedLegendre_eq n)
  rw [Polynomial.map_mul, Polynomial.map_natCast, ← iterate_derivative_map] at this
  simpa using this

#print axioms gq_rodrigues

lemma gq_legendreP_eval (n : ℕ) (x : ℝ) :
    (legendreP n).eval x =
      (-1) ^ n * ((shiftedLegendre n).map (Int.castRingHom ℝ)).eval ((x + 1) / 2) := by
  simp only [legendreP, eval_mul, eval_pow, eval_neg, eval_one, eval_comp, eval_C, eval_add, eval_X]
  congr 2; ring

#print axioms gq_legendreP_eval

lemma gq_shifted_degree (n : ℕ) :
    ((shiftedLegendre n).map (Int.castRingHom ℝ)).natDegree = n := by
  rw [natDegree_map_eq_of_injective (RingHom.injective_int _), natDegree_shiftedLegendre]

#print axioms gq_shifted_degree

lemma gq_shifted_ne_zero (n : ℕ) : (shiftedLegendre n).map (Int.castRingHom ℝ) ≠ 0 := by
  intro h
  have := degree_map_eq_of_injective (RingHom.injective_int (Int.castRingHom ℝ)) (shiftedLegendre n)
  rw [h, degree_shiftedLegendre] at this
  simp at this

#print axioms gq_shifted_ne_zero

lemma gq_legendreP_degree (n : ℕ) : (legendreP n).degree = n := by
  have h1 : (C (1 / 2 : ℝ) * (X + 1)).degree = 1 := by
    rw [degree_C_mul (by norm_num)]; compute_degree!
  have h2 : (((shiftedLegendre n).map (Int.castRingHom ℝ)).comp (C (1 / 2) * (X + 1))).degree = n := by
    rw [degree_comp (by rw [h1]; norm_num), h1, mul_one,
      degree_eq_natDegree (gq_shifted_ne_zero n), gq_shifted_degree]
  rw [legendreP, degree_mul, h2, degree_pow, degree_neg, degree_one]
  simp

#print axioms gq_legendreP_degree

lemma gq_parts (m : ℕ) : ∀ r h : ℝ[X], ∃ F : ℝ[X],
    derivative F = r * derivative^[m] h - (-1) ^ m * derivative^[m] r * h ∧
    ∀ a : ℝ, (∀ j < m, (derivative^[j] h).eval a = 0) → F.eval a = 0 := by
  induction m with
  | zero => intro r h; exact ⟨0, by simp, fun _ _ => by simp⟩
  | succ m ih =>
    intro r h
    obtain ⟨F, hF, hFa⟩ := ih (derivative r) h
    refine ⟨r * derivative^[m] h - F, ?_, fun a hj => ?_⟩
    · rw [derivative_sub, derivative_mul, hF, Function.iterate_succ_apply derivative m r,
        Function.iterate_succ_apply' derivative m h]
      ring
    · rw [eval_sub, eval_mul, hj m (Nat.lt_succ_self m), hFa a (fun j hj' => hj j (by omega))]
      ring

#print axioms gq_parts

lemma gq_rodrigues_ne_zero (n : ℕ) : (X ^ n * (1 - X : ℝ[X]) ^ n) ≠ 0 := by
  intro h
  have := congrArg (eval 2) h
  norm_num at this

#print axioms gq_rodrigues_ne_zero

lemma gq_vanish (n j : ℕ) (hj : j < n) :
    (derivative^[j] (X ^ n * (1 - X : ℝ[X]) ^ n)).eval 0 = 0 ∧
      (derivative^[j] (X ^ n * (1 - X : ℝ[X]) ^ n)).eval 1 = 0 := by
  have h0 := gq_rodrigues_ne_zero n
  constructor
  · have : n ≤ (X ^ n * (1 - X : ℝ[X]) ^ n).rootMultiplicity 0 := by
      rw [le_rootMultiplicity_iff h0]
      simp
    exact isRoot_iterate_derivative_of_lt_rootMultiplicity (by omega)
  · have : n ≤ (X ^ n * (1 - X : ℝ[X]) ^ n).rootMultiplicity 1 := by
      rw [le_rootMultiplicity_iff h0]
      exact Dvd.dvd.mul_left (pow_dvd_pow_of_dvd ⟨-1, by simp⟩ n) _
    exact isRoot_iterate_derivative_of_lt_rootMultiplicity (by omega)

#print axioms gq_vanish

lemma gq_shifted_orth (n : ℕ) (r : ℝ[X]) (hr : r.degree < n) :
    ∫ y in (0 : ℝ)..1, (r * (shiftedLegendre n).map (Int.castRingHom ℝ)).eval y = 0 := by
  obtain ⟨F, hF, hFa⟩ := gq_parts n r (X ^ n * (1 - X : ℝ[X]) ^ n)
  rw [iterate_derivative_eq_zero_of_degree_lt hr, mul_zero, zero_mul, sub_zero,
    ← gq_rodrigues] at hF
  have hint : ∫ y in (0 : ℝ)..1, (derivative F).eval y = F.eval 1 - F.eval 0 :=
    integral_eq_sub_of_hasDerivAt (fun x _ => F.hasDerivAt x)
      ((Polynomial.continuous _).intervalIntegrable _ _)
  have hfac : (n.factorial : ℝ) ≠ 0 := by positivity
  rw [hF, hFa 0 (fun j hj => (gq_vanish n j hj).1), hFa 1 (fun j hj => (gq_vanish n j hj).2)] at hint
  have : ∫ y in (0 : ℝ)..1, (r * (shiftedLegendre n).map (Int.castRingHom ℝ)).eval y =
      (n.factorial : ℝ)⁻¹ * ∫ y in (0 : ℝ)..1,
        (r * ((n.factorial : ℝ[X]) * (shiftedLegendre n).map (Int.castRingHom ℝ))).eval y := by
    rw [← integral_const_mul]
    congr 1; ext y
    simp only [eval_mul, eval_natCast]
    field_simp
  rw [this, hint]; simp

#print axioms gq_shifted_orth

lemma gq_legendreP_orth (n : ℕ) (q : ℝ[X]) (hq : q.degree < n) :
    ∫ x in (-1 : ℝ)..1, (q * legendreP n).eval x = 0 := by
  set S := (shiftedLegendre n).map (Int.castRingHom ℝ)
  set r := q.comp (C 2 * X - 1)
  have hr : r.degree < n := by
    refine lt_of_le_of_lt ?_ hq
    rcases eq_or_ne q 0 with h | h
    · simp [r, h]
    · have : (C (2 : ℝ) * X - 1).degree = 1 := by compute_degree!
      rw [degree_comp (by rw [this]; norm_num), this, mul_one]
  have key : ∀ x : ℝ, (q * legendreP n).eval x =
      (fun y => (-1) ^ n * (r * S).eval y) ((1 / 2) * x + 1 / 2) := by
    intro x
    simp only [eval_mul, gq_legendreP_eval, r, eval_comp, eval_sub, eval_C, eval_X, eval_one, S]
    have : 2 * (1 / 2 * x + 1 / 2) - 1 = x := by ring
    rw [this, show (x + 1) / 2 = 1 / 2 * x + 1 / 2 by ring]
    ring
  have hc := intervalIntegral.integral_comp_mul_add (a := -1) (b := 1)
    (fun y => (-1) ^ n * (r * S).eval y) (by norm_num : (1 / 2 : ℝ) ≠ 0) (1 / 2)
  rw [show (fun x => eval x (q * legendreP n)) = _ from funext key, hc]
  have h0 := gq_shifted_orth n r hr
  simp only [eval_mul] at h0
  norm_num
  exact h0

#print axioms gq_legendreP_orth

lemma gq_iter_ne_zero (n k : ℕ) (hk : k ≤ n) :
    derivative^[k] (X ^ n * (1 - X : ℝ[X]) ^ n) ≠ 0 := by
  intro h
  have h2 : derivative^[n] (X ^ n * (1 - X : ℝ[X]) ^ n) = 0 := by
    rw [← Nat.sub_add_cancel hk, Function.iterate_add_apply, Nat.sub_add_cancel hk, h,
      iterate_derivative_zero]
  rw [← gq_rodrigues] at h2
  rcases mul_eq_zero.1 h2 with h3 | h3
  · exact (Nat.factorial_ne_zero n) (by exact_mod_cast h3)
  · exact gq_shifted_ne_zero n h3

#print axioms gq_iter_ne_zero

lemma gq_rolle (n : ℕ) : ∀ k ≤ n, k ≤ ((derivative^[k] (X ^ n * (1 - X : ℝ[X]) ^ n)).roots.toFinset.filter
    (fun z => z ∈ Set.Ioo (0 : ℝ) 1)).card := by
  intro k
  induction k with
  | zero => intro _; exact Nat.zero_le _
  | succ k ih =>
    intro hk
    set f := derivative^[k] (X ^ n * (1 - X : ℝ[X]) ^ n) with hf
    set T := (f.roots.toFinset.filter (fun z => z ∈ Set.Ioo (0 : ℝ) 1)) with hT
    have hIH := ih (by omega)
    have hf0 := gq_iter_ne_zero n k (by omega)
    have hf1 := gq_iter_ne_zero n (k + 1) hk
    have hv := gq_vanish n k (by omega)
    have h0T : (0 : ℝ) ∉ T := by simp [T]
    have h1T : (1 : ℝ) ∉ T := by simp [T]
    have hcard : (insert 0 (insert 1 T)).card = T.card + 2 := by
      rw [Finset.card_insert_of_notMem, Finset.card_insert_of_notMem h1T]
      simp [h0T]
    have hmem : ∀ x ∈ insert 0 (insert 1 T), f.eval x = 0 ∧ x ∈ Set.Icc (0 : ℝ) 1 := by
      intro x hx
      simp only [Finset.mem_insert] at hx
      rcases hx with rfl | rfl | hx
      · exact ⟨hv.1, by norm_num⟩
      · exact ⟨hv.2, by norm_num⟩
      · simp only [T, Finset.mem_filter, Multiset.mem_toFinset] at hx
        exact ⟨(mem_roots hf0).1 hx.1, Set.Ioo_subset_Icc_self hx.2⟩
    have := Finset.card_le_of_interleaved (s := insert 0 (insert 1 T))
      (t := ((derivative^[k + 1] (X ^ n * (1 - X : ℝ[X]) ^ n)).roots.toFinset.filter
        (fun z => z ∈ Set.Ioo (0 : ℝ) 1))) (by
      intro x hx y hy hxy _
      obtain ⟨hxr, hxI⟩ := hmem x hx
      obtain ⟨hyr, hyI⟩ := hmem y hy
      obtain ⟨z, hz, hz'⟩ := exists_deriv_eq_zero hxy f.continuousOn (hxr.trans hyr.symm)
      refine ⟨z, ?_, hz.1, hz.2⟩
      rw [Polynomial.deriv] at hz'
      rw [Function.iterate_succ_apply'] at hf1
      simp only [Finset.mem_filter, Multiset.mem_toFinset, Function.iterate_succ_apply']
      exact ⟨(mem_roots hf1).2 hz', lt_of_le_of_lt hxI.1 hz.1, lt_of_lt_of_le hz.2 hyI.2⟩)
    omega

#print axioms gq_rolle

lemma gq_legendreP_two : legendreP 2 = C (3 / 2) * X ^ 2 - C (1 / 2) := by
  refine Polynomial.funext fun x => ?_
  simp [legendreP, shiftedLegendre, Finset.sum_range_succ, Nat.choose]
  ring

#print axioms gq_legendreP_two

/-- The Gauss rule is exact to degree `2n - 1`: put the `n` nodes `t_1, ..., t_n` at the `n`
different zeros of the Legendre polynomial `P_n`, and give node `j` the weight `w_j`, the integral
from `-1` to `1` of its Lagrange basis polynomial `ℓ_j`. Then for every polynomial `p` of degree
at most `2n - 1`, the weighted sum `∑ w_j p(t_j)` equals the integral of `p` from `-1` to `1`. -/
theorem gauss_rule_exact_up_to_degree_two_n_sub_one (n : ℕ) (t : Fin n → ℝ)
    (ht : Function.Injective t) (hroot : ∀ j, (legendreP n).eval (t j) = 0)
    (p : ℝ[X]) (hp : p.degree < ↑(2 * n)) :
    ∫ x in (-1 : ℝ)..1, p.eval x =
      ∑ j, (∫ x in (-1 : ℝ)..1, (Lagrange.basis Finset.univ t j).eval x) * p.eval (t j) := by
  set L := legendreP n with hLdef
  have hLdeg : L.degree = n := gq_legendreP_degree n
  have hL0 : L ≠ 0 := by
    intro h; rw [h, degree_zero] at hLdeg; exact WithBot.bot_ne_coe hLdeg
  have hdm := EuclideanDomain.div_add_mod p L
  set q := p / L
  set r := p % L
  have hr : r.degree < n := hLdeg ▸ degree_mod_lt p hL0
  have hq : q.degree < n := by
    rcases eq_or_ne q 0 with h | h
    · rw [h, degree_zero]; exact WithBot.bot_lt_coe _
    have h1 : (L * q).degree = n + q.degree := by rw [degree_mul, hLdeg]
    have h2 : (L * q).degree < ↑(2 * n) := by
      rw [show L * q = p - r by rw [← hdm]; ring]
      exact lt_of_le_of_lt (degree_sub_le _ _) (max_lt hp (lt_of_lt_of_le hr (by
        norm_cast; omega)))
    rw [degree_eq_natDegree h] at h1 ⊢
    rw [h1] at h2
    norm_cast at h2 ⊢
    omega
  have hint : ∫ x in (-1 : ℝ)..1, p.eval x = ∫ x in (-1 : ℝ)..1, r.eval x := by
    rw [← hdm]
    simp only [eval_add]
    rw [integral_add ((Polynomial.continuous _).intervalIntegrable _ _)
      ((Polynomial.continuous _).intervalIntegrable _ _)]
    rw [show (fun x => eval x (L * q)) = fun x => eval x (q * L) by ext; rw [mul_comm],
      gq_legendreP_orth n q hq, zero_add]
  have hsum : ∀ j, p.eval (t j) = r.eval (t j) := by
    intro j
    rw [← hdm, eval_add, eval_mul, hroot j, zero_mul, zero_add]
  have hinterp := Lagrange.eq_interpolate (s := Finset.univ) (v := t) (f := r)
    (ht.injOn) (by simpa using hr)
  rw [hint, hinterp, Lagrange.interpolate_apply]
  simp only [eval_finsetSum, eval_mul, eval_C]
  rw [intervalIntegral.integral_finsetSum (fun j _ => by
    exact ((Polynomial.continuous _).intervalIntegrable _ _).const_mul _)]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [integral_const_mul, hsum j, mul_comm]

/-- Degree `2n` is out of reach: for any `n` sample points and any `n` weights, wherever the
points are, some polynomial of degree `2n` is integrated wrongly on `-1` to `1`. -/
theorem no_n_point_rule_exact_for_degree_two_n (n : ℕ) (t w : Fin n → ℝ) :
    ∃ p : ℝ[X], p.degree = ↑(2 * n) ∧
      ∫ x in (-1 : ℝ)..1, p.eval x ≠ ∑ j, w j * p.eval (t j) := by
  refine ⟨(∏ j, (X - C (t j))) ^ 2, ?_, ?_⟩
  · rw [degree_pow, degree_prod]
    simp [mul_comm]
  · have hsum : ∑ j, w j * ((∏ j, (X - C (t j))) ^ 2).eval (t j) = 0 := by
      refine Finset.sum_eq_zero fun j _ => ?_
      rw [eval_pow, eval_prod, Finset.prod_eq_zero (Finset.mem_univ j) (by simp)]
      simp
    rw [hsum]
    obtain ⟨c, hc, hct⟩ := (Set.Icc_infinite (by norm_num : (-1 : ℝ) < 1)).exists_notMem_finset
      (Finset.univ.image t)
    have hpos : 0 < ((∏ j, (X - C (t j))) ^ 2).eval c := by
      rw [eval_pow, eval_prod]
      refine pow_two_pos_of_ne_zero ?_
      rw [Finset.prod_ne_zero_iff]
      intro j _ h
      apply hct
      simp only [eval_sub, eval_X, eval_C, sub_eq_zero] at h
      exact Finset.mem_image.2 ⟨j, Finset.mem_univ _, h.symm⟩
    have := intervalIntegral.integral_lt_integral_of_continuousOn_of_le_of_exists_lt
      (f := fun _ => (0 : ℝ)) (g := fun x => ((∏ j, (X - C (t j))) ^ 2).eval x)
      (by norm_num : (-1 : ℝ) < 1) continuousOn_const (Polynomial.continuousOn _)
      (fun x _ => by simp only [eval_pow]; positivity) ⟨c, hc, hpos⟩
    simp only [integral_zero, eval_pow] at this
    simp only [eval_pow]
    exact this.ne'

/-- The Legendre polynomial `P_n` has `n` different zeros, all strictly between `-1` and `1`,
and these are all of its zeros: so the Gauss nodes exist and never sit at an endpoint. -/
theorem legendreP_has_n_distinct_zeros_inside (n : ℕ) :
    ∃ t : Fin n → ℝ, StrictMono t ∧ (∀ j, t j ∈ Set.Ioo (-1 : ℝ) 1 ∧ (legendreP n).eval (t j) = 0) ∧
      ∀ x : ℝ, (legendreP n).eval x = 0 → x ∈ Set.range t := by
  set S := (shiftedLegendre n).map (Int.castRingHom ℝ) with hSdef
  have hS0 : S ≠ 0 := gq_shifted_ne_zero n
  have hR := gq_rolle n n le_rfl
  rw [← gq_rodrigues, ← C_eq_natCast, roots_C_mul _ (by positivity)] at hR
  set U := S.roots.toFinset with hUdef
  have hUcard : U.card ≤ n :=
    (Multiset.toFinset_card_le _).trans ((card_roots' S).trans (gq_shifted_degree n).le)
  have heq : U.filter (fun z => z ∈ Set.Ioo (0 : ℝ) 1) = U :=
    Finset.eq_of_subset_of_card_le (Finset.filter_subset _ _) (by omega)
  have hU : U.card = n := le_antisymm hUcard (heq ▸ hR)
  have hUmem : ∀ z ∈ U, S.eval z = 0 ∧ z ∈ Set.Ioo (0 : ℝ) 1 := by
    intro z hz
    have hz' := hz
    rw [← heq, Finset.mem_filter] at hz'
    exact ⟨(mem_roots hS0).1 (Multiset.mem_toFinset.1 hz), hz'.2⟩
  refine ⟨fun j => 2 * U.orderEmbOfFin hU j - 1, ?_, ?_, ?_⟩
  · intro i j hij
    have := (U.orderEmbOfFin hU).strictMono hij
    simp only
    linarith
  · intro j
    obtain ⟨h1, h2⟩ := hUmem _ (U.orderEmbOfFin_mem hU j)
    refine ⟨⟨by linarith [h2.1], by linarith [h2.2]⟩, ?_⟩
    rw [gq_legendreP_eval, ← hSdef]
    rw [show (2 * U.orderEmbOfFin hU j - 1 + 1) / 2 = U.orderEmbOfFin hU j by ring, h1, mul_zero]
  · intro x hx
    rw [gq_legendreP_eval, ← hSdef] at hx
    have h1 : S.eval ((x + 1) / 2) = 0 :=
      (mul_eq_zero.1 hx).resolve_left (pow_ne_zero _ (by norm_num))
    have hmem : (x + 1) / 2 ∈ (U : Set ℝ) :=
      Finset.mem_coe.2 (Multiset.mem_toFinset.2 ((mem_roots hS0).2 h1))
    rw [← Finset.range_orderEmbOfFin U hU] at hmem
    obtain ⟨j, hj⟩ := hmem
    exact ⟨j, by simp only; rw [hj]; ring⟩

-- The card's P_2 = (3t^2 - 1)/2, and its zeros ±1/√3 are the two-point nodes.
example : legendreP 2 = C (3 / 2) * X ^ 2 - C (1 / 2) := by
  exact gq_legendreP_two

example : (legendreP 2).eval (1 / Real.sqrt 3) = 0 ∧ (legendreP 2).eval (-(1 / Real.sqrt 3)) = 0 := by
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  have h3' : Real.sqrt 3 ≠ 0 := by positivity
  rw [gq_legendreP_two]
  simp only [eval_sub, eval_mul, eval_C, eval_pow, eval_X, neg_sq, div_pow, h3]
  norm_num

-- The two-point rule (nodes ±1/√3, weights 1) on t^0 .. t^4: exact integrals 2, 0, 2/3, 0, 2/5.
example : ∀ k ∈ Finset.range 4,
    (-(1 / Real.sqrt 3)) ^ k + (1 / Real.sqrt 3) ^ k = ∫ x in (-1 : ℝ)..1, x ^ k := by
  have h3 : Real.sqrt 3 ^ 2 = 3 := Real.sq_sqrt (by norm_num)
  intro k hk
  rw [integral_pow]
  simp only [Finset.mem_range] at hk
  interval_cases k
  all_goals norm_num [div_pow, h3]
  ring

example : (-(1 / Real.sqrt 3)) ^ 4 + (1 / Real.sqrt 3) ^ 4 = (2 / 9 : ℝ) ∧
    ∫ x in (-1 : ℝ)..1, x ^ 4 = (2 / 5 : ℝ) := by
  have h3 : Real.sqrt 3 ^ 4 = 9 := by
    rw [show (4 : ℕ) = 2 * 2 by rfl, pow_mul, Real.sq_sqrt (by norm_num)]; norm_num
  refine ⟨?_, ?_⟩
  · rw [neg_pow, div_pow, h3]; norm_num
  · rw [integral_pow]; norm_num

-- Degree of exactness 2n - 1 for n = 1 .. 6, as the code prints.
example : (List.range 6).map (fun k => 2 * (k + 1) - 1) = [1, 3, 5, 7, 9, 11] := by
  decide

-- The error constant 2^(2n+1) (n!)^4 / ((2n+1) ((2n)!)^3) is 1/135 for n = 2 and 1/15750 for n = 3.
example : ((2 : ℚ) ^ 5 * (Nat.factorial 2 : ℚ) ^ 4 / (5 * (Nat.factorial 4 : ℚ) ^ 3) = 1 / 135) ∧
    ((2 : ℚ) ^ 7 * (Nat.factorial 3 : ℚ) ^ 4 / (7 * (Nat.factorial 6 : ℚ) ^ 3) = 1 / 15750) := by
  norm_num [Nat.factorial]

-- The beam: exact U = 1000 w0^2 L^5 / (945 EI) = 10368/175 J (59.245714...) with w0 = 12, L = 6,
-- EI = 20000, and the 3-point value 58.968 J misses it by 243/875 J (2.777e-1).
example : (1000 * 12 ^ 2 * 6 ^ 5 / (945 * 20000) : ℚ) = 10368 / 175 ∧
    (10368 / 175 - 58968 / 1000 : ℚ) = 243 / 875 := by
  norm_num

#print axioms gauss_rule_exact_up_to_degree_two_n_sub_one
#print axioms no_n_point_rule_exact_for_degree_two_n
#print axioms legendreP_has_n_distinct_zeros_inside
