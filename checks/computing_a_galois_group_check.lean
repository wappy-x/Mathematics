-- Computing a Galois group: the discriminant of a rational polynomial with distinct roots is a rational square exactly when its Galois group shuffles the roots only evenly, x^4 + x + 1 has discriminant 229 and the full group of 24 shuffles, and a group of shuffles of four roots holding a 4-cycle and a 3-cycle is all of S4.
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.Resultant.Basic
import Mathlib.GroupTheory.Perm.Cycle.Type
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.GroupTheory.SpecificGroups.Alternating
import Mathlib.LinearAlgebra.Vandermonde
import Mathlib.RingTheory.Polynomial.GaussLemma
import Mathlib.Algebra.Polynomial.SpecificDegree
import Mathlib.Algebra.Polynomial.Eval.Irreducible
import Mathlib.FieldTheory.Finite.Basic

open Polynomial

-- Every rational polynomial splits over ℂ, so its Galois group acts on its complex roots.
attribute [local instance] Polynomial.Gal.splits_ℚ_ℂ

theorem discr_x4_add_x_add_one : (X ^ 4 + X + 1 : ℚ[X]).discr = 229 := by
  have hnd : (X ^ 4 + X + 1 : ℚ[X]).natDegree = 4 := by compute_degree!
  have hdeg : 0 < (X ^ 4 + X + 1 : ℚ[X]).degree := by
    rw [← natDegree_pos_iff_degree_pos, hnd]; norm_num
  have hlc : (X ^ 4 + X + 1 : ℚ[X]).leadingCoeff = 1 := by
    rw [leadingCoeff, hnd]; simp [coeff_X, coeff_one]
  have h := resultant_deriv hdeg
  rw [hnd, hlc] at h
  norm_num at h
  rw [← h]
  have hder : derivative (X ^ 4 + X + 1 : ℚ[X]) = C 4 * X ^ 3 + 1 := by
    simp; ring_nf; simp [C_ofNat]; ring
  rw [hder]
  have hsplit : (X ^ 4 + X + 1 : ℚ[X]) =
      (C (3/4) * X + 1) + (C 4 * X ^ 3 + 1) * (C (1/4) * X) := by
    have e1 : (C 4 * C (1/4) : ℚ[X]) = 1 := by rw [← C_mul]; norm_num
    have e2 : (C (3/4) + C (1/4) : ℚ[X]) = 1 := by rw [← C_add]; norm_num
    linear_combination (-X ^ 4) * e1 + (-X) * e2
  have hg : (C 4 * X ^ 3 + 1 : ℚ[X]).natDegree ≤ 3 := by compute_degree
  have hq : (C (1/4) * X : ℚ[X]).natDegree ≤ 1 := by compute_degree
  rw [hsplit, resultant_add_mul_left _ _ _ _ _ (by omega) hg]
  have hl : (C (3/4) * X + 1 : ℚ[X]).natDegree ≤ 1 := by compute_degree
  rw [resultant_succ_left_deg _ _ _ _ (hl.trans (by norm_num)),
    resultant_succ_left_deg _ _ _ _ (hl.trans (by norm_num)),
    resultant_succ_left_deg _ _ _ _ hl]
  have hlin : (C (3/4) * X + 1 : ℚ[X]) = C (3/4) * (X + C (4/3)) := by
    rw [mul_add, ← C_mul]; norm_num
  rw [hlin, resultant_C_mul_left, resultant_X_add_C_left _ _ _ hg]
  have hc : (C 4 * X ^ 3 + 1 : ℚ[X]).coeff 3 = 4 := by simp [coeff_one]
  rw [hc]
  simp
  norm_num

#print axioms discr_x4_add_x_add_one

open Finset in
theorem sum_card_Ioi_fin (n : ℕ) : ∑ i : Fin (n + 1), #(Ioi i) = (n + 1) * n / 2 := by
  simp_rw [Fin.card_Ioi]
  rw [Fin.sum_univ_eq_sum_range (fun i => n + 1 - 1 - i) (n + 1),
    Finset.sum_range_reflect (fun i => i) (n + 1), Finset.sum_range_id]
  simp

#print axioms sum_card_Ioi_fin

open Finset in
theorem discr_algebraMap_eq_sq {K : Type*} [Field K] [Algebra ℚ K] (f : ℚ[X])
    (hf : f.Separable) (hs : (f.map (algebraMap ℚ K)).Splits) (n : ℕ)
    (hn : f.natDegree = n + 1) (e : Fin (n + 1) ≃ f.rootSet K) :
    algebraMap ℚ K f.discr =
      (algebraMap ℚ K f.leadingCoeff ^ n *
        (Matrix.vandermonde (fun i => (e i : K))).det) ^ 2 := by
  classical
  set φ := algebraMap ℚ K with hφ
  set F := f.map φ with hF
  set v : Fin (n + 1) → K := fun i => (e i : K) with hv
  have hf0 : f ≠ 0 := by rintro rfl; simp at hn
  have hlc : f.leadingCoeff ≠ 0 := leadingCoeff_ne_zero.mpr hf0
  have hvinj : Function.Injective v := fun i j h => e.injective (Subtype.ext h)
  have hroots : F.roots = (Finset.univ.val.map v) := by
    apply (Multiset.Nodup.ext (nodup_roots (hf.map)) (Finset.univ.nodup.map hvinj)).mpr
    intro a
    constructor
    · intro ha
      have : a ∈ f.rootSet K := by rw [rootSet_def]; exact Multiset.mem_toFinset.mpr ha
      obtain ⟨i, hi⟩ := e.surjective ⟨a, this⟩
      exact Multiset.mem_map.mpr ⟨i, Finset.mem_univ_val _, by simp [v, hi]⟩
    · intro ha
      obtain ⟨i, -, rfl⟩ := Multiset.mem_map.mp ha
      have : v i ∈ f.rootSet K := (e i).2
      rw [rootSet_def, Finset.mem_coe] at this
      exact Multiset.mem_toFinset.mp this
  have hFnd : F.natDegree = n + 1 := by rw [hF, natDegree_map, hn]
  have hFlc : F.leadingCoeff = φ f.leadingCoeff := by rw [hF, leadingCoeff_map]
  have hderiv : ∀ i, F.derivative.eval (v i) =
      φ f.leadingCoeff * ∏ j ∈ ({i}ᶜ : Finset _), (v i - v j) := by
    intro i
    have hmem : v i ∈ F.roots := by
      rw [hroots]; exact Multiset.mem_map.mpr ⟨i, Finset.mem_univ_val _, rfl⟩
    conv_lhs => rw [hs.eq_prod_roots]
    rw [derivative_C_mul, eval_C_mul, eval_multiset_prod_X_sub_C_derivative hmem, hFlc]
    congr 1
    rw [hroots, ← Multiset.map_erase v hvinj, Multiset.map_map, Finset.compl_singleton,
      Finset.prod_eq_multiset_prod, Finset.erase_val]
    rfl
  have key : ∏ i, ∏ j ∈ ({i}ᶜ : Finset (Fin (n + 1))), (v i - v j) =
      (-1) ^ ((n + 1) * n / 2) * (Matrix.vandermonde v).det ^ 2 := by
    rw [← prod_prod_Ioi_mul_eq_prod_prod_off_diag (fun j i => v i - v j),
      Matrix.det_vandermonde, ← sum_card_Ioi_fin n, ← Finset.prod_pow_eq_pow_sum,
      ← Finset.prod_pow, ← Finset.prod_mul_distrib]
    refine Finset.prod_congr rfl fun i _ => ?_
    rw [← Finset.prod_pow, ← Finset.prod_neg]
    refine Finset.prod_congr rfl fun j _ => ?_
    ring
  have h1 := resultant_deriv (f := f) (by rw [← natDegree_pos_iff_degree_pos, hn]; omega)
  rw [hn, Nat.add_sub_cancel] at h1
  have h2 := congrArg φ h1
  rw [← resultant_map_map, ← derivative_map] at h2
  have h3 := resultant_eq_prod_eval F F.derivative n
    (by have := natDegree_derivative_le F; rw [hFnd] at this; simpa using this) hs
  rw [hFnd, hFlc, hroots, Multiset.map_map, ← Finset.prod_eq_multiset_prod] at h3
  simp only [Function.comp_apply, hderiv, Finset.prod_mul_distrib, Finset.prod_const,
    Finset.card_univ, Fintype.card_fin, key] at h3
  have h4 := h2.symm.trans h3
  simp only [map_mul, map_pow, map_neg, map_one] at h4
  have hne : ((-1 : K) ^ ((n + 1) * n / 2) * φ f.leadingCoeff) ≠ 0 := by
    have : φ f.leadingCoeff ≠ 0 := (map_ne_zero φ).mpr hlc
    exact mul_ne_zero (pow_ne_zero _ (by norm_num)) this
  apply mul_left_cancel₀ hne
  linear_combination h4

#print axioms discr_algebraMap_eq_sq

theorem zmod2_x4_no_root : ∀ x : ZMod 2, ¬ x ^ 4 + x + 1 = 0 := by decide

#print axioms zmod2_x4_no_root

theorem zmod2_quadratic_coeffs : ∀ b c : ZMod 2, ¬ (0 ^ 2 + b * 0 + c = 0) →
    ¬ (1 ^ 2 + b * 1 + c = 0) → c = 1 ∧ b = 1 := by decide

#print axioms zmod2_quadratic_coeffs

theorem zmod3_cubic_no_root : ∀ x : ZMod 3, ¬ x ^ 3 - 4 * x - 1 = 0 := by decide

#print axioms zmod3_cubic_no_root

theorem irreducible_x4_zmod2 : Irreducible (X ^ 4 + X + 1 : (ZMod 2)[X]) := by
  have : Fact (Nat.Prime 2) := ⟨Nat.prime_two⟩
  have hm : (X ^ 4 + X + 1 : (ZMod 2)[X]).Monic := by monicity!
  have hnd : (X ^ 4 + X + 1 : (ZMod 2)[X]).natDegree = 4 := by compute_degree!
  have hroot : ∀ x : ZMod 2, ¬ (X ^ 4 + X + 1 : (ZMod 2)[X]).IsRoot x := by
    intro x; simp only [IsRoot, eval_add, eval_pow, eval_X, eval_one]; exact zmod2_x4_no_root x
  have hne1 : (X ^ 4 + X + 1 : (ZMod 2)[X]) ≠ 1 := by
    intro h; have := congrArg natDegree h; rw [hnd] at this; simp at this
  rw [hm.irreducible_iff_lt_natDegree_lt hne1]
  intro q hq hdeg hdvd
  rw [hnd] at hdeg
  simp only [Finset.mem_Ioc] at hdeg
  rcases (by omega : q.natDegree = 1 ∨ q.natDegree = 2) with h1 | h2
  · rw [hq.eq_X_add_C h1] at hdvd
    exact hroot (-(q.coeff 0)) (IsRoot.dvd (by rw [IsRoot, eval_add, eval_X, eval_C, neg_add_cancel]) hdvd)
  · have hq2 : q = X ^ 2 + C (q.coeff 1) * X + C (q.coeff 0) := by
      conv_lhs => rw [hq.as_sum, h2]
      simp [Finset.sum_range_succ]; ring
    have hqr : ∀ x, ¬ q.IsRoot x := fun x hx => hroot x (hx.dvd hdvd)
    have hb : q.coeff 0 = 1 ∧ q.coeff 1 = 1 := by
      generalize q.coeff 1 = b at hq2 ⊢
      generalize q.coeff 0 = c at hq2 ⊢
      rw [hq2] at hqr
      have h0 := hqr 0
      have h1 := hqr 1
      simp only [IsRoot, eval_add, eval_pow, eval_X, eval_mul, eval_C] at h0 h1
      exact zmod2_quadratic_coeffs b c h0 h1
    rw [hb.1, hb.2, C_1] at hq2
    obtain ⟨r, hr⟩ := hdvd
    have h2z : (2 : (ZMod 2)[X]) = 0 := CharTwo.two_eq_zero
    have hone : q * (r - (X ^ 2 + X)) = 1 := by
      rw [hq2] at hr ⊢
      linear_combination (-1) * hr + (-(X ^ 3) - X ^ 2) * h2z
    have hu := IsUnit.of_mul_eq_one _ hone
    have := natDegree_eq_zero_of_isUnit hu
    omega

#print axioms irreducible_x4_zmod2

theorem irreducible_x4_rat : Irreducible (X ^ 4 + X + 1 : ℚ[X]) := by
  have hm : (X ^ 4 + X + 1 : ℤ[X]).Monic := by monicity!
  have hZ : Irreducible (X ^ 4 + X + 1 : ℤ[X]) := by
    refine Monic.irreducible_of_irreducible_map (φ := Int.castRingHom (ZMod 2)) _ hm ?_
    simpa [Polynomial.map_add, Polynomial.map_pow] using irreducible_x4_zmod2
  have := (IsPrimitive.Int.irreducible_iff_irreducible_map_cast hm.isPrimitive).mp hZ
  simpa [Polynomial.map_add, Polynomial.map_pow] using this

#print axioms irreducible_x4_rat

theorem irreducible_resolvent_rat : Irreducible (X ^ 3 - 4 * X - 1 : ℚ[X]) := by
  have hm : (X ^ 3 - 4 * X - 1 : ℤ[X]).Monic := by monicity!
  have hZ : Irreducible (X ^ 3 - 4 * X - 1 : ℤ[X]) := by
    have : Fact (Nat.Prime 3) := ⟨Nat.prime_three⟩
    refine Monic.irreducible_of_irreducible_map (φ := Int.castRingHom (ZMod 3)) _ hm ?_
    apply irreducible_of_degree_le_three_of_not_isRoot
    · have : (Polynomial.map (Int.castRingHom (ZMod 3)) (X ^ 3 - 4 * X - 1)).natDegree = 3 := by
        simp only [Polynomial.map_sub, Polynomial.map_pow, map_X, Polynomial.map_mul,
          Polynomial.map_one]
        compute_degree!
      rw [this]; decide
    · intro x
      simp only [IsRoot, Polynomial.map_sub, Polynomial.map_pow, map_X, Polynomial.map_mul,
        Polynomial.map_one, eval_sub, eval_pow, eval_X, eval_mul, eval_one]
      simpa using zmod3_cubic_no_root x
  have := (IsPrimitive.Int.irreducible_iff_irreducible_map_cast hm.isPrimitive).mp hZ
  simpa [Polynomial.map_sub, Polynomial.map_pow] using this

#print axioms irreducible_resolvent_rat

theorem not_isSquare_229 : ¬ IsSquare (229 : ℚ) := by
  have : ((229 : ℕ) : ℚ) = 229 := by norm_num
  rw [← this, Rat.isSquare_natCast_iff]
  rintro ⟨r, hr⟩
  have : r ≤ 15 := by nlinarith
  interval_cases r <;> omega

#print axioms not_isSquare_229

theorem exists_resolvent_root {K : Type*} [Field K] [Algebra ℚ K]
    (hs : ((X ^ 4 + X + 1 : ℚ[X]).map (algebraMap ℚ K)).Splits) :
    ∃ θ : K, aeval θ (X ^ 3 - 4 * X - 1 : ℚ[X]) = 0 := by
  have hmon : ((X ^ 4 + X + 1 : ℚ[X]).map (algebraMap ℚ K)).Monic := by
    apply Monic.map; monicity!
  have hnd : ((X ^ 4 + X + 1 : ℚ[X]).map (algebraMap ℚ K)).natDegree = 4 := by
    rw [natDegree_map]; compute_degree!
  have hcard : Multiset.card ((X ^ 4 + X + 1 : ℚ[X]).map (algebraMap ℚ K)).roots = 4 := by
    rw [← hs.natDegree_eq_card_roots, hnd]
  obtain ⟨a, b, c, d, habcd⟩ := Multiset.card_eq_four.mp hcard
  have hprod := hs.eq_prod_roots_of_monic hmon
  rw [habcd] at hprod
  simp only [Multiset.insert_eq_cons, Multiset.map_cons, Multiset.prod_cons,
    Multiset.map_singleton, Multiset.prod_singleton] at hprod
  have hexp : (X - C a) * ((X - C b) * ((X - C c) * (X - C d))) =
      X ^ 4 - C (a + b + c + d) * X ^ 3 + C (a*b + a*c + a*d + b*c + b*d + c*d) * X ^ 2
        - C (a*b*c + a*b*d + a*c*d + b*c*d) * X + C (a*b*c*d) := by
    simp only [C_add, C_mul]; ring
  rw [hexp] at hprod
  simp only [Polynomial.map_add, Polynomial.map_pow, map_X, Polynomial.map_one] at hprod
  have k0 := congrArg (coeff · 0) hprod
  have k1 := congrArg (coeff · 1) hprod
  have k2 := congrArg (coeff · 2) hprod
  have k3 := congrArg (coeff · 3) hprod
  simp only [coeff_add, coeff_sub, coeff_C_mul, coeff_X_pow, coeff_X, coeff_C, coeff_one] at k0 k1 k2 k3
  norm_num at k0 k1 k2 k3
  have h1 : a + b + c + d = 0 := by linear_combination k3
  have h2 : a*b + a*c + a*d + b*c + b*d + c*d = 0 := by linear_combination -k2
  have h3 : a*b*c + a*b*d + a*c*d + b*c*d = -1 := by linear_combination k1
  have h4 : a*b*c*d = 1 := by linear_combination -k0
  refine ⟨a * b + c * d, ?_⟩
  simp only [map_sub, map_mul, map_pow, aeval_X, map_one, map_ofNat]
  linear_combination ((a * b + c * d) ^ 2 - 4 * (a*b*c*d)) * h2
    + ((a + b + c + d) * (a*b*c*d) - (a*b*c + a*b*d + a*c*d + b*c*d) * (a * b + c * d)) * h1
    + 4 * (a * b + c * d) * h4 + ((a*b*c + a*b*d + a*c*d + b*c*d) - 1) * h3

#print axioms exists_resolvent_root

theorem perm_four_subgroup_eq_top {α : Type*} [Fintype α] [DecidableEq α]
    (hα : Fintype.card α = 4) (H : Subgroup (Equiv.Perm α)) (h12 : 12 ∣ Nat.card H)
    (hodd : ∃ σ ∈ H, Equiv.Perm.sign σ ≠ 1) : H = ⊤ := by
  have hP : Nat.card (Equiv.Perm α) = 24 := by
    rw [Nat.card_perm, Nat.card_eq_fintype_card, hα]; rfl
  have hdvd : Nat.card H ∣ 24 := hP ▸ Subgroup.card_subgroup_dvd_card H
  obtain ⟨k, hk⟩ := h12
  have hk' : k = 1 ∨ k = 2 := by
    have hpos : 0 < Nat.card H := Nat.card_pos
    have : Nat.card H ≤ 24 := Nat.le_of_dvd (by norm_num) hdvd
    rcases hdvd with ⟨m, hm⟩
    have : k ≤ 2 := by omega
    interval_cases k <;> omega
  rcases hk' with rfl | rfl
  · exfalso
    have hidx : H.index = 2 := by
      have := Subgroup.card_mul_index H
      rw [hk, hP] at this; omega
    have hle := Equiv.Perm.alternatingGroup_le_of_index_le_two (G := H) hidx.le
    have : Nontrivial α := Fintype.one_lt_card_iff_nontrivial.mp (by omega)
    have hA : Nat.card (alternatingGroup α) = 12 := by
      have := two_mul_nat_card_alternatingGroup (α := α); rw [hP] at this; omega
    have hEq : alternatingGroup α = H :=
      Subgroup.eq_of_le_of_card_ge hle (by rw [hA, hk])
    obtain ⟨σ, hσ, hs⟩ := hodd
    rw [← hEq] at hσ
    exact hs (Equiv.Perm.mem_alternatingGroup.mp hσ)
  · exact Subgroup.eq_top_of_card_eq H (by rw [hk, hP])

#print axioms perm_four_subgroup_eq_top

/-- The discriminant test (Step 1 of the card). Let `f` have rational coefficients and distinct
roots (`f.Separable`). Then the discriminant of `f` is the square of a rational number exactly when
every shuffle in the Galois group of `f`, acting on the roots of `f` in the complex numbers, is an
even shuffle (sign `1`). A rational square root traps the group inside the even shuffles; an
irrational one means the group holds an odd shuffle. -/
theorem discriminant_square_iff_galois_group_even (f : ℚ[X]) (hf : f.Separable) :
    IsSquare f.discr ↔ ∀ σ : f.Gal, Equiv.Perm.sign (Gal.galActionHom f ℂ σ) = 1 := by
  classical
  set K := f.SplittingField
  let π : f.Gal → Equiv.Perm (f.rootSet K) := fun σ => MulAction.toPerm σ
  have hsign : ∀ σ : f.Gal,
      Equiv.Perm.sign (Gal.galActionHom f ℂ σ) = Equiv.Perm.sign (π σ) := by
    intro σ
    have : Gal.galActionHom f ℂ σ = (Gal.rootsEquivRootsAux f ℂ).permCongr (π σ) := by
      ext x : 1
      rfl
    rw [this, Equiv.Perm.sign_permCongr]
  simp_rw [hsign]
  rcases Nat.eq_zero_or_eq_succ_pred f.natDegree with h0 | hn
  · have hcard0 : Fintype.card (f.rootSet K) = 0 := by
      rw [card_rootSet_eq_natDegree hf (SplittingField.splits f), h0]
    have hempty : IsEmpty (f.rootSet K) := Fintype.card_eq_zero_iff.mp hcard0
    have hd : f.discr = 1 := by rw [eq_C_of_natDegree_eq_zero h0]; exact discr_C _
    rw [hd]
    refine ⟨fun _ σ => ?_, fun _ => ⟨1, by simp⟩⟩
    have : π σ = 1 := Equiv.ext fun x => (hempty.false x).elim
    rw [this, map_one]
  · set n := f.natDegree.pred
    have hs : (f.map (algebraMap ℚ K)).Splits := SplittingField.splits f
    have hcard : Fintype.card (f.rootSet K) = n + 1 := by
      rw [card_rootSet_eq_natDegree hf hs]; exact hn
    let e : Fin (n + 1) ≃ f.rootSet K := (Fintype.equivFinOfCardEq hcard).symm
    set φ := algebraMap ℚ K with hφ
    set v : Fin (n + 1) → K := fun i => (e i : K) with hv
    set E := φ f.leadingCoeff ^ n * (Matrix.vandermonde v).det with hE
    have hdisc : φ f.discr = E ^ 2 := discr_algebraMap_eq_sq f hf hs n hn e
    have hf0 : f ≠ 0 := by rintro rfl; simp at hn
    have hvinj : Function.Injective v := fun i j h => e.injective (Subtype.ext h)
    have hE0 : E ≠ 0 := mul_ne_zero (pow_ne_zero _ ((map_ne_zero φ).mpr
      (leadingCoeff_ne_zero.mpr hf0))) (Matrix.det_vandermonde_ne_zero_iff.mpr hvinj)
    have hact : ∀ σ : f.Gal, σ E = ((Equiv.Perm.sign (π σ) : ℤ) : K) * E := by
      intro σ
      let τ : Equiv.Perm (Fin (n + 1)) := (e.symm.symm.trans (π σ)).trans e.symm
      have hτ : Equiv.Perm.sign τ = Equiv.Perm.sign (π σ) :=
        Equiv.Perm.sign_symm_trans_trans _ _
      have hvτ : ∀ i, σ (v i) = v (τ i) := by
        intro i
        simp only [v, τ, Equiv.trans_apply, Equiv.symm_symm, Equiv.apply_symm_apply]
        rfl
      have hmat : σ.toRingHom.mapMatrix (Matrix.vandermonde v) =
          (Matrix.vandermonde v).submatrix τ id := by
        ext i j
        simp only [RingHom.mapMatrix_apply, Matrix.map_apply, Matrix.vandermonde,
          Matrix.of_apply, Matrix.submatrix_apply, id]
        change σ (v i ^ (j : ℕ)) = v (τ i) ^ (j : ℕ)
        rw [map_pow, hvτ]
      have hD : σ (Matrix.vandermonde v).det =
          ((Equiv.Perm.sign (π σ) : ℤ) : K) * (Matrix.vandermonde v).det := by
        have := RingHom.map_det σ.toRingHom (Matrix.vandermonde v)
        rw [hmat, Matrix.det_permute, hτ] at this
        exact this
      have hc : σ (φ f.leadingCoeff) = φ f.leadingCoeff := σ.commutes _
      rw [hE, map_mul, map_pow, hc, hD]
      ring
    constructor
    · rintro ⟨r, hr⟩ σ
      have hsq : E ^ 2 = (φ r) ^ 2 := by rw [← hdisc, hr, map_mul, sq]
      have hfix : σ E = E := by
        rcases sq_eq_sq_iff_eq_or_eq_neg.mp hsq with h | h
        · rw [h]; exact σ.commutes r
        · rw [h, map_neg]; exact congrArg Neg.neg (σ.commutes r)
      rw [hact σ] at hfix
      have h1 : ((Equiv.Perm.sign (π σ) : ℤ) : K) = 1 := by
        have := mul_right_cancel₀ hE0 (hfix.trans (one_mul E).symm)
        exact this
      rcases Int.units_eq_one_or (Equiv.Perm.sign (π σ)) with h | h
      · exact h
      · rw [h] at h1; norm_num at h1
    · intro h
      have : IsGalois ℚ K := IsGalois.of_separable_splitting_field hf
      have hfix : ∀ σ : Gal(K/ℚ), σ E = E := by
        intro σ; have := hact σ; rw [h σ] at this; simp only [Units.val_one, Int.cast_one, one_mul] at this; exact this
      obtain ⟨r, hr⟩ := (IsGalois.mem_range_algebraMap_iff_fixed E).mpr hfix
      refine ⟨r, φ.injective ?_⟩
      rw [hdisc, map_mul, ← sq]; exact congrArg (· ^ 2) hr.symm

/-- The card's main example. The discriminant of `x^4 + x + 1` is `229`, and its Galois group is
the full group of shuffles of its four complex roots: every one of the `24` shuffles of the roots
comes from exactly one element of the Galois group. -/
theorem x4_add_x_add_one_galois_group_is_S4 :
    (X ^ 4 + X + 1 : ℚ[X]).discr = 229 ∧
    Function.Bijective (Gal.galActionHom (X ^ 4 + X + 1 : ℚ[X]) ℂ) ∧
    Nat.card (X ^ 4 + X + 1 : ℚ[X]).Gal = 24 := by
  classical
  have hirr : Irreducible (X ^ 4 + X + 1 : ℚ[X]) := irreducible_x4_rat
  have hsep : (X ^ 4 + X + 1 : ℚ[X]).Separable := hirr.separable
  have hdisc : (X ^ 4 + X + 1 : ℚ[X]).discr = 229 := discr_x4_add_x_add_one
  have hnd : (X ^ 4 + X + 1 : ℚ[X]).natDegree = 4 := by compute_degree!
  have hs : ((X ^ 4 + X + 1 : ℚ[X]).map
      (algebraMap ℚ (X ^ 4 + X + 1 : ℚ[X]).SplittingField)).Splits := SplittingField.splits _
  have h4 : 4 ∣ Module.finrank ℚ (X ^ 4 + X + 1 : ℚ[X]).SplittingField :=
    by have := hirr.natDegree_dvd_finrank hs; rwa [hnd] at this
  obtain ⟨θ, hθ⟩ := exists_resolvent_root hs
  have hmin : (X ^ 3 - 4 * X - 1 : ℚ[X]) = minpoly ℚ θ :=
    minpoly.eq_of_irreducible_of_monic irreducible_resolvent_rat hθ (by monicity!)
  have h3 : 3 ∣ Module.finrank ℚ (X ^ 4 + X + 1 : ℚ[X]).SplittingField := by
    have := minpoly.degree_dvd (Algebra.IsIntegral.isIntegral (R := ℚ) θ)
    rw [← hmin] at this
    have hd : (X ^ 3 - 4 * X - 1 : ℚ[X]).natDegree = 3 := by compute_degree!
    rwa [hd] at this
  have h12 : 12 ∣ Nat.card (X ^ 4 + X + 1 : ℚ[X]).Gal := by
    rw [Gal.card_of_separable hsep]
    exact Nat.Coprime.mul_dvd_of_dvd_of_dvd (by norm_num) h4 h3
  have hodd : ∃ σ : (X ^ 4 + X + 1 : ℚ[X]).Gal,
      Equiv.Perm.sign (Gal.galActionHom (X ^ 4 + X + 1 : ℚ[X]) ℂ σ) ≠ 1 := by
    by_contra hcon
    push Not at hcon
    have := (discriminant_square_iff_galois_group_even _ hsep).mpr hcon
    rw [hdisc] at this
    exact not_isSquare_229 this
  have hrc : Fintype.card ((X ^ 4 + X + 1 : ℚ[X]).rootSet ℂ) = 4 := by
    rw [card_rootSet_eq_natDegree hsep Fact.out, hnd]
  have hinj := Gal.galActionHom_injective (X ^ 4 + X + 1 : ℚ[X]) ℂ
  have hHcard : Nat.card (Gal.galActionHom (X ^ 4 + X + 1 : ℚ[X]) ℂ).range =
      Nat.card (X ^ 4 + X + 1 : ℚ[X]).Gal :=
    (Nat.card_congr (MonoidHom.ofInjective hinj).toEquiv).symm
  have hHtop : (Gal.galActionHom (X ^ 4 + X + 1 : ℚ[X]) ℂ).range = ⊤ := by
    refine perm_four_subgroup_eq_top hrc _ (hHcard ▸ h12) ?_
    obtain ⟨σ, hσ⟩ := hodd
    exact ⟨_, ⟨σ, rfl⟩, hσ⟩
  have hsurj : Function.Surjective (Gal.galActionHom (X ^ 4 + X + 1 : ℚ[X]) ℂ) :=
    MonoidHom.range_eq_top.mp hHtop
  refine ⟨hdisc, ⟨hinj, hsurj⟩, ?_⟩
  rw [← hHcard, hHtop, Subgroup.card_top, Nat.card_perm, Nat.card_eq_fintype_card, hrc]
  rfl

/-- Two cycle types force all 24 (Step 4 of the card). A group of shuffles of four roots that
contains a 4-cycle (cycle type `4`) and a 3-cycle (cycle type `3 + 1`) is the whole of `S4`. -/
theorem four_cycle_and_three_cycle_generate_S4 (G : Subgroup (Equiv.Perm (Fin 4)))
    (h4 : ∃ σ ∈ G, σ.cycleType = {4}) (h3 : ∃ τ ∈ G, τ.cycleType = {3}) : G = ⊤ := by
  obtain ⟨σ, hσ, hσc⟩ := h4
  obtain ⟨τ, hτ, hτc⟩ := h3
  have o4 : orderOf σ = 4 := by rw [← Equiv.Perm.lcm_cycleType, hσc]; simp
  have o3 : orderOf τ = 3 := by rw [← Equiv.Perm.lcm_cycleType, hτc]; simp
  have d4 : 4 ∣ Nat.card G := by
    have := orderOf_dvd_natCard (⟨σ, hσ⟩ : G); rwa [Subgroup.orderOf_mk, o4] at this
  have d3 : 3 ∣ Nat.card G := by
    have := orderOf_dvd_natCard (⟨τ, hτ⟩ : G); rwa [Subgroup.orderOf_mk, o3] at this
  refine perm_four_subgroup_eq_top (by simp) G ?_ ⟨σ, hσ, ?_⟩
  · exact Nat.Coprime.mul_dvd_of_dvd_of_dvd (by norm_num) d4 d3
  · rw [Equiv.Perm.sign_of_cycleType, hσc]; decide

-- The card's whole-number worked examples.
-- Discriminant of x^4 + c x + d is -27 c^4 + 256 d^3: for x^4 + x + 1 it is 229.
example : (-27 : ℤ) * 1 ^ 4 + 256 * 1 ^ 3 = 229 := by norm_num
-- 229 is not a perfect square: 15^2 = 225 < 229 < 256 = 16^2.
example : 15 ^ 2 < 229 ∧ 229 < 16 ^ 2 ∧ ¬ ∃ n ∈ Finset.range 230, n * n = 229 := by
  decide +kernel
-- Resolvent cubic y^3 - 4y - 1: R(1) = -4, R(-1) = 2, so no rational root (one must divide 1).
example : (1 : ℤ) ^ 3 - 4 * 1 - 1 = -4 ∧ (-1 : ℤ) ^ 3 - 4 * (-1) - 1 = 2 := by norm_num
-- The resolvent's discriminant -4(-4)^3 - 27(-1)^2 is 229, the same as the quartic's.
example : -4 * (-4 : ℤ) ^ 3 - 27 * (-1) ^ 2 = 229 := by norm_num
-- Mod 2: no root, since f(0) = f(1) = 1.
example : ∀ x : ZMod 2, x ^ 4 + x + 1 ≠ 0 := by decide
-- Mod 2: no split into two quadratics (x^2 + a x + b)(x^2 + c x + d), so a 4-cycle.
example : ∀ a b c d : ZMod 2,
    ¬ (a + c = 0 ∧ b + d + a * c = 0 ∧ a * d + b * c = 1 ∧ b * d = 1) := by decide
-- The only irreducible quadratic mod 2 is x^2 + x + 1, and its square is x^4 + x^2 + 1, not f.
example : ∀ x : ZMod 2, (x ^ 2 + x + 1) ^ 2 = x ^ 4 + x ^ 2 + 1 := by decide
-- Mod 3: f(0), f(1), f(2) = 1, 3, 19, so 1 is the only root, and the derivative 4x^3 + 1 is 5 there.
example : (0 : ℕ) ^ 4 + 0 + 1 = 1 ∧ (1 : ℕ) ^ 4 + 1 + 1 = 3 ∧ (2 : ℕ) ^ 4 + 2 + 1 = 19 := by decide
example : ∀ x : ZMod 3, x ^ 4 + x + 1 = 0 ↔ x = 1 := by decide
example : 4 * (1 : ZMod 3) ^ 3 + 1 ≠ 0 := by decide
-- S4 splits as 1 identity, 6 swaps, 3 double swaps, 8 three-cycles and 6 four-cycles.
example : (Finset.univ.filter (fun σ : Equiv.Perm (Fin 4) => σ.cycleType = {2})).card = 6 ∧
    (Finset.univ.filter (fun σ : Equiv.Perm (Fin 4) => σ.cycleType = {2, 2})).card = 3 ∧
    (Finset.univ.filter (fun σ : Equiv.Perm (Fin 4) => σ.cycleType = {3})).card = 8 ∧
    (Finset.univ.filter (fun σ : Equiv.Perm (Fin 4) => σ.cycleType = {4})).card = 6 := by
  decide +kernel
example : 1 + 6 + 3 + 8 + 6 = 24 := by norm_num
-- What breaks at p = 229: the root 75 is a double root, (x - 75)^2 (x^2 + 150x + 158).
example : (75 ^ 4 + 75 + 1) % 229 = 0 ∧ (4 * 75 ^ 3 + 1) % 229 = 0 := by norm_num
example : ∀ x : ZMod 229, (x - 75) ^ 2 * (x ^ 2 + 150 * x + 158) = x ^ 4 + x + 1 := by
  decide +kernel
-- x^4 - 2: discriminant 256(-2)^3 = -2048, resolvent y^3 + 8y has the root 0;
-- mod 7 its roots are 2 and 5, pattern 2 + 1 + 1.
example : (-27 : ℤ) * 0 ^ 4 + 256 * (-2) ^ 3 = -2048 ∧ (0 : ℤ) ^ 3 + 8 * 0 = 0 := by norm_num
example : ∀ x : ZMod 7, x ^ 4 = 2 ↔ x = 2 ∨ x = 5 := by decide
-- x^4 + 4 = (x^2 + 2x + 2)(x^2 - 2x + 2): reducible, though its discriminant is 128^2
-- and its resolvent y^3 - 16y has the three roots -4, 0, 4.
example : (X ^ 2 + 2 * X + 2) * (X ^ 2 - 2 * X + 2) = (X ^ 4 + 4 : ℤ[X]) := by ring
example : (256 : ℤ) * 4 ^ 3 = 16384 ∧ (16384 : ℤ) = 128 ^ 2 := by norm_num
example : ∀ y ∈ ({-4, 0, 4} : Finset ℤ), y ^ 3 - 16 * y = 0 := by decide
-- x^3 - 3x + 1: discriminant -4(-3)^3 - 27(1)^2 = 81 = 9^2, so its group is A3.
example : -4 * (-3 : ℤ) ^ 3 - 27 * 1 ^ 2 = 81 ∧ (81 : ℤ) = 9 ^ 2 := by norm_num

#print axioms discriminant_square_iff_galois_group_even
#print axioms x4_add_x_add_one_galois_group_is_S4
#print axioms four_cycle_and_three_cycle_generate_S4
