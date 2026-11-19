-- Finitely many solutions: when a polynomial system has finitely many solutions, the eigenvalues of its "multiply by f" matrix are exactly the values of f at the solutions, and the solutions number at most the standard monomials.
import Mathlib.RingTheory.Nullstellensatz
import Mathlib.RingTheory.MvPolynomial.MonomialOrder
import Mathlib.LinearAlgebra.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Algebra.Algebra.Bilinear
import Mathlib.Data.Set.Card
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.List.TFAE
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FinCases
import Mathlib.RingTheory.MvPolynomial.Groebner
import Mathlib.RingTheory.Jacobson.Artinian
import Mathlib.RingTheory.Polynomial.Tower
import Mathlib.FieldTheory.Extension
import Mathlib.FieldTheory.IsAlgClosed.Spectrum
import Mathlib.FieldTheory.Fixed
import Mathlib.LinearAlgebra.FreeModule.Finite.Matrix
import Mathlib.LinearAlgebra.Matrix.Charpoly.Eigs
import Mathlib.Data.Finsupp.Interval

open MvPolynomial

/-! Notation. `k` is the field of coefficients (the card's `ℚ`) and `K` is an algebraically closed
field containing it (the card's `ℂ`), where the solutions are counted. `I` is an ideal of
`k[x_1, ..., x_n]` (here `MvPolynomial σ k`, with finitely many variables `σ`), `A = k[x]/I` is the
quotient ring of remainders, and `zeroLocus K I = V(I)` is the set of common solutions in `K^n`.
A basis `b_1, ..., b_n` of `A` plays the part of the standard monomials. The multiplication matrix
`M_f` is `LinearMap.toMatrix b b` of "multiply by `f`" on `A`: its entry `[r, s]` is the coefficient
of `b_r` in the remainder of `f * b_s`. -/

/-- The point of `K^σ` read off a `k`-algebra map out of `k[x]/I`. -/
theorem zd_aeval_point {k K : Type*} [Field k] [Field K] [Algebra k K] {σ : Type*}
    (I : Ideal (MvPolynomial σ k)) (ψ : (MvPolynomial σ k ⧸ I) →ₐ[k] K) (g : MvPolynomial σ k) :
    aeval (fun i => ψ (Ideal.Quotient.mk I (X i))) g = ψ (Ideal.Quotient.mk I g) := by
  have : aeval (fun i => ψ (Ideal.Quotient.mk I (X i))) = ψ.comp (Ideal.Quotient.mkₐ k I) :=
    MvPolynomial.algHom_ext (fun i => by simp)
  rw [this]; rfl

theorem zd_point_mem {k K : Type*} [Field k] [Field K] [Algebra k K] {σ : Type*}
    (I : Ideal (MvPolynomial σ k)) (ψ : (MvPolynomial σ k ⧸ I) →ₐ[k] K) :
    (fun i => ψ (Ideal.Quotient.mk I (X i))) ∈ zeroLocus K I := by
  intro g hg
  rw [zd_aeval_point, Ideal.Quotient.eq_zero_iff_mem.mpr hg, map_zero]

/-- Evaluation at a solution, as a `k`-algebra map out of `k[x]/I`. -/
noncomputable def zdEval {k K : Type*} [Field k] [Field K] [Algebra k K] {σ : Type*}
    (I : Ideal (MvPolynomial σ k)) (p : zeroLocus K I) : (MvPolynomial σ k ⧸ I) →ₐ[k] K :=
  Ideal.Quotient.liftₐ I (aeval p.1) (fun a ha => p.2 a ha)

theorem zdEval_mk {k K : Type*} [Field k] [Field K] [Algebra k K] {σ : Type*}
    (I : Ideal (MvPolynomial σ k)) (p : zeroLocus K I) (g : MvPolynomial σ k) :
    zdEval I p (Ideal.Quotient.mk I g) = aeval p.1 g := rfl

theorem zdEval_injective {k K : Type*} [Field k] [Field K] [Algebra k K] {σ : Type*}
    (I : Ideal (MvPolynomial σ k)) : Function.Injective (zdEval (K := K) I) := by
  intro p q h
  apply Subtype.ext; funext i
  have := congrArg (fun χ => χ (Ideal.Quotient.mk I (X i))) h
  simpa [zdEval_mk] using this

theorem zd_card_le {k K : Type*} [Field k] [Field K] [Algebra k K] {σ : Type*}
    (I : Ideal (MvPolynomial σ k)) {n : ℕ} (b : Module.Basis (Fin n) k (MvPolynomial σ k ⧸ I)) :
    (zeroLocus K I).encard ≤ n := by
  have : Module.Finite k (MvPolynomial σ k ⧸ I) := Module.Finite.of_basis b
  have hfin : Finite (zeroLocus K I) := Finite.of_injective _ (zdEval_injective (K := K) I)
  have h1 := Nat.card_le_card_of_injective _ (zdEval_injective (K := K) I)
  have h2 := card_algHom_le_finrank k (MvPolynomial σ k ⧸ I) K
  rw [Module.finrank_eq_card_basis b, Fintype.card_fin] at h2
  rw [← (Set.toFinite (zeroLocus K I)).cast_ncard_eq, ← Nat.card_coe_set_eq]
  exact_mod_cast h1.trans h2

/-- Values of an algebra map on a basis form a left eigenvector of the multiplication matrix. -/
theorem zd_vecMul {k K : Type*} [Field k] [Field K] [Algebra k K] {A : Type*} [CommRing A]
    [Algebra k A] {n : ℕ} (b : Module.Basis (Fin n) k A) (χ : A →ₐ[k] K) (a : A) :
    Matrix.vecMul (fun r => χ (b r))
      ((LinearMap.toMatrix b b (LinearMap.mulLeft k a)).map (algebraMap k K)) =
      χ a • fun r => χ (b r) := by
  funext s
  simp only [Matrix.vecMul, dotProduct, Matrix.map_apply, LinearMap.toMatrix_apply,
    LinearMap.mulLeft_apply, Pi.smul_apply, smul_eq_mul]
  have key : χ (a * b s) = ∑ r, algebraMap k K (b.repr (a * b s) r) * χ (b r) := by
    conv_lhs => rw [← b.sum_repr (a * b s)]
    rw [map_sum]
    refine Finset.sum_congr rfl fun r _ => ?_
    rw [map_smul, Algebra.smul_def]
  rw [← map_mul, key]
  exact Finset.sum_congr rfl fun r _ => mul_comm _ _

theorem zd_ne_zero {k K : Type*} [Field k] [Field K] [Algebra k K] {A : Type*} [CommRing A]
    [Algebra k A] {n : ℕ} (b : Module.Basis (Fin n) k A) (χ : A →ₐ[k] K) :
    (fun r => χ (b r)) ≠ 0 := by
  intro h
  have h1 : χ 1 = 0 := by
    rw [← b.sum_repr 1, map_sum]
    refine Finset.sum_eq_zero fun r _ => ?_
    rw [map_smul, congrFun h r, Pi.zero_apply, smul_zero]
  simp at h1

theorem zd_univariate {k σ : Type*} [Field k] (m : MonomialOrder σ) (i : σ) (q : Polynomial k)
    (hq : q ≠ 0) :
    Polynomial.aeval (X i : MvPolynomial σ k) q ≠ 0 ∧
      m.degree (Polynomial.aeval (X i : MvPolynomial σ k) q) = Finsupp.single i q.natDegree := by
  classical
  set g := Polynomial.aeval (X i : MvPolynomial σ k) q with hg
  have hcoeff : ∀ c, g.coeff c = ∑ j ∈ Finset.range (q.natDegree + 1),
      q.coeff j * (if Finsupp.single i j = c then 1 else 0) := by
    intro c
    rw [hg, Polynomial.aeval_eq_sum_range, MvPolynomial.coeff_sum]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [MvPolynomial.coeff_smul, MvPolynomial.coeff_X_pow, smul_eq_mul]
  have hlead : g.coeff (Finsupp.single i q.natDegree) = q.leadingCoeff := by
    rw [hcoeff]
    simp only [(Finsupp.single_injective i).eq_iff, mul_ite, mul_one, mul_zero]
    rw [Finset.sum_ite_eq']
    rw [ite_eq_left (Finset.mem_range.mpr (Nat.lt_succ_self _))]
    rfl
  have hmem : Finsupp.single i q.natDegree ∈ g.support := by
    rw [MvPolynomial.mem_support_iff, hlead]
    exact Polynomial.leadingCoeff_ne_zero.mpr hq
  have hsupp : ∀ c ∈ g.support, ∃ j ≤ q.natDegree, Finsupp.single i j = c := by
    intro c hc
    by_contra hne
    push Not at hne
    apply (MvPolynomial.mem_support_iff.mp hc)
    rw [hcoeff]
    refine Finset.sum_eq_zero fun j hj => ?_
    rw [ite_eq_right_iff.mpr (fun h => absurd h (hne j (Nat.lt_succ_iff.mp (Finset.mem_range.mp hj)))), mul_zero]
  refine ⟨fun h0 => by simp [h0] at hmem, ?_⟩
  apply m.toSyn.injective
  apply le_antisymm
  · rw [MonomialOrder.degree_le_iff]
    intro c hc
    obtain ⟨j, hj, rfl⟩ := hsupp c hc
    exact m.toSyn_monotone (Finsupp.single_mono hj)
  · exact m.le_degree hmem

#print axioms zd_aeval_point
#print axioms zd_point_mem
#print axioms zdEval_mk
#print axioms zdEval_injective
#print axioms zd_card_le
#print axioms zd_vecMul
#print axioms zd_ne_zero
#print axioms zd_univariate

/-- Stickelberger's theorem, the card's main claim. Take a system over a field `k` whose remainders
have a finite basis `b_1, ..., b_n` (finitely many standard monomials), and let `M_f` be the matrix
of "multiply by `f`" in that basis. Then, over an algebraically closed field `K` containing `k`:
(1) a number `t` is an eigenvalue of `M_f` (a root of its characteristic polynomial) exactly when
`t = f(p)` for some solution `p`; and (2) at each solution `p`, the row of values
`v_p = (b_1(p), ..., b_n(p))` is a nonzero left eigenvector: `v_p M_f = f(p) v_p`. With `f = x` the
eigenvalues are the solutions' `x`-coordinates, and each point can be read off its eigenvector. -/
theorem multiplication_matrix_eigenvalues_are_values_at_solutions
    {k K : Type*} [Field k] [Field K] [Algebra k K] [IsAlgClosed K] {σ : Type*} [Finite σ]
    (I : Ideal (MvPolynomial σ k)) {n : ℕ} (b : Module.Basis (Fin n) k (MvPolynomial σ k ⧸ I))
    (f : MvPolynomial σ k) :
    let M : Matrix (Fin n) (Fin n) K :=
      (LinearMap.toMatrix b b (LinearMap.mulLeft k (Ideal.Quotient.mk I f))).map (algebraMap k K)
    (∀ t : K, M.charpoly.IsRoot t ↔ ∃ p ∈ zeroLocus K I, aeval p f = t) ∧
      (∀ p ∈ zeroLocus K I, ∀ c : Fin n → MvPolynomial σ k,
        (∀ r, Ideal.Quotient.mk I (c r) = b r) →
          (fun r => aeval p (c r)) ≠ 0 ∧
            Matrix.vecMul (fun r => aeval p (c r)) M = aeval p f • fun r => aeval p (c r)) := by
  intro M
  have hpart2 : ∀ p ∈ zeroLocus K I, ∀ c : Fin n → MvPolynomial σ k,
      (∀ r, Ideal.Quotient.mk I (c r) = b r) →
        (fun r => aeval p (c r)) ≠ 0 ∧
          Matrix.vecMul (fun r => aeval p (c r)) M = aeval p f • fun r => aeval p (c r) := by
    intro p hp c hc
    have hv : (fun r => aeval p (c r)) = fun r => zdEval I ⟨p, hp⟩ (b r) :=
      funext fun r => by rw [← hc r, zdEval_mk]
    have hf : aeval p f = zdEval I ⟨p, hp⟩ (Ideal.Quotient.mk I f) := (zdEval_mk I ⟨p, hp⟩ f).symm
    rw [hv, hf]
    exact ⟨zd_ne_zero b _, zd_vecMul b _ _⟩
  refine ⟨fun t => ⟨fun ht => ?_, ?_⟩, hpart2⟩
  · have hspec : t ∈ spectrum K M := Matrix.mem_spectrum_iff_isRoot_charpoly.mpr ht
    set Mk := LinearMap.toMatrix b b (LinearMap.mulLeft k (Ideal.Quotient.mk I f)) with hMk
    have hcp : M.charpoly = Mk.charpoly.map (algebraMap k K) := Matrix.charpoly_map Mk _
    have hint : IsIntegral k t := by
      refine ⟨Mk.charpoly, Matrix.charpoly_monic Mk, ?_⟩
      rw [← Polynomial.eval_map, ← hcp]; exact ht
    set q := minpoly k t with hq
    let Φ : (MvPolynomial σ k ⧸ I) →ₐ[k] Matrix (Fin n) (Fin n) K :=
      (AlgHom.mapMatrix (Algebra.ofId k K)).comp
        ((LinearMap.toMatrixAlgEquiv b).toAlgHom.comp (Algebra.lmul k _))
    have hΦ : Φ (Ideal.Quotient.mk I f) = M := by
      ext i j
      simp [Φ, M, LinearMap.toMatrixAlgEquiv_apply, Algebra.leftMulMatrix_eq_repr_mul]
    have hnu : ¬ IsUnit (Polynomial.aeval (Ideal.Quotient.mk I f) q) := by
      intro hu
      have h1 : IsUnit (Φ (Polynomial.aeval (Ideal.Quotient.mk I f) q)) := hu.map Φ
      rw [← Polynomial.aeval_algHom_apply, hΦ, ← Polynomial.aeval_map_algebraMap K] at h1
      have h2 := spectrum.subset_polynomial_aeval M (q.map (algebraMap k K)) ⟨t, hspec, rfl⟩
      simp only [Polynomial.eval_map_algebraMap, hq, minpoly.aeval] at h2
      exact (spectrum.zero_mem_iff K).mp h2 h1
    obtain ⟨m, hm, hqm⟩ := exists_max_ideal_of_mem_nonunits hnu
    let := Ideal.Quotient.field m
    have : Module.Finite k (MvPolynomial σ k ⧸ I) := Module.Finite.of_basis b
    have : Module.Finite k ((MvPolynomial σ k ⧸ I) ⧸ m) :=
      Module.Finite.of_surjective (Ideal.Quotient.mkₐ k m).toLinearMap Ideal.Quotient.mk_surjective
    let x : (MvPolynomial σ k ⧸ I) ⧸ m := Ideal.Quotient.mk m (Ideal.Quotient.mk I f)
    have hxq : Polynomial.aeval x q = 0 := by
      have : x = Ideal.Quotient.mkₐ k m (Ideal.Quotient.mk I f) := rfl
      rw [this, Polynomial.aeval_algHom_apply, Ideal.Quotient.mkₐ_eq_mk,
        Ideal.Quotient.eq_zero_iff_mem.mpr hqm]
    have hmin : q = minpoly k x :=
      minpoly.eq_of_irreducible_of_monic (minpoly.irreducible hint) hxq (minpoly.monic hint)
    obtain ⟨φ, hφ⟩ := IntermediateField.exists_algHom_of_splits_of_aeval (F := k)
      (E := (MvPolynomial σ k ⧸ I) ⧸ m) (K := K)
      (fun s => ⟨Algebra.IsIntegral.isIntegral s, IsAlgClosed.splits _⟩) (x := x) (y := t)
      (by rw [← hmin]; exact minpoly.aeval k t)
    let ψ := φ.comp (Ideal.Quotient.mkₐ k m)
    refine ⟨_, zd_point_mem I ψ, ?_⟩
    rw [zd_aeval_point]; exact hφ
  · rintro ⟨p, hp, rfl⟩
    choose c hc using fun r => Ideal.Quotient.mk_surjective (I := I) (b r)
    obtain ⟨hv0, hv⟩ := hpart2 p hp c hc
    rw [← Matrix.mem_spectrum_iff_isRoot_charpoly, spectrum.mem_iff]
    intro hu
    obtain ⟨N, hN⟩ := hu.exists_right_inv
    apply hv0
    have h0 : Matrix.vecMul (fun r => aeval p (c r)) (algebraMap K _ (aeval p f) - M) = 0 := by
      rw [Matrix.vecMul_sub, hv, Algebra.algebraMap_eq_smul_one, Matrix.vecMul_smul,
        Matrix.vecMul_one, sub_self]
    calc (fun r => aeval p (c r))
        = Matrix.vecMul (fun r => aeval p (c r)) ((algebraMap K _ (aeval p f) - M) * N) := by
          rw [hN, Matrix.vecMul_one]
      _ = 0 := by rw [← Matrix.vecMul_vecMul, h0, Matrix.zero_vecMul]

/-- The zero-dimensional test. For a system over `k` in finitely many variables, and any monomial
order, these are the same: (a) the system has only finitely many solutions, even counting those
in an algebraically closed field `K ⊇ k`; (b) the quotient `k[x]/I` is finite-dimensional, that
is, there are finitely many standard monomials; (c) for every variable `x_i`, some nonzero member
of `I` has a pure power of `x_i` as its leading monomial (equivalently, some leading term of a
Gröbner basis of `I` is a pure power of `x_i`). -/
theorem zero_dimensional_iff_pure_power_leading_terms
    {k K : Type*} [Field k] [Field K] [Algebra k K] [IsAlgClosed K] {σ : Type*} [Finite σ]
    (m : MonomialOrder σ) (I : Ideal (MvPolynomial σ k)) :
    List.TFAE
      [(zeroLocus K I).Finite,
        Module.Finite k (MvPolynomial σ k ⧸ I),
        ∀ i : σ, ∃ g ∈ I, g ≠ 0 ∧ ∃ d : ℕ, m.degree g = Finsupp.single i d] := by
  tfae_have 2 → 1 := by
    intro h
    have : Finite (zeroLocus K I) := Finite.of_injective _ (zdEval_injective (K := K) I)
    exact Set.toFinite _
  tfae_have 2 → 3 := by
    intro h i
    have hint : IsIntegral k (Ideal.Quotient.mk I (X i)) := Algebra.IsIntegral.isIntegral _
    obtain ⟨h0, hdeg⟩ := zd_univariate (k := k) m i _ (minpoly.ne_zero hint)
    refine ⟨_, ?_, h0, _, hdeg⟩
    rw [← Ideal.Quotient.eq_zero_iff_mem]
    have := Polynomial.aeval_algHom_apply (Ideal.Quotient.mkₐ k I) (X i : MvPolynomial σ k)
      (minpoly k (Ideal.Quotient.mk I (X i)))
    rw [Ideal.Quotient.mkₐ_eq_mk, minpoly.aeval] at this
    exact this.symm
  tfae_have 3 → 2 := by
    intro h
    classical
    choose g hgI hg0 d hd using h
    have hb : ∀ i, IsUnit (m.leadingCoeff (g i)) :=
      fun i => isUnit_iff_ne_zero.mpr (m.leadingCoeff_ne_zero_iff.mpr (hg0 i))
    let D : σ →₀ ℕ := Finsupp.equivFunOnFinite.symm d
    let T : Set (σ →₀ ℕ) := Set.Icc 0 D
    have hT : T.Finite := Set.finite_Icc 0 D
    refine ⟨Submodule.fg_def.mpr ⟨(fun c => Ideal.Quotient.mk I (monomial c (1 : k))) '' T,
      hT.image _, ?_⟩⟩
    rw [eq_top_iff]
    rintro a -
    obtain ⟨f, rfl⟩ := Ideal.Quotient.mk_surjective a
    obtain ⟨c, r, hfr, -, hr⟩ := m.div hb f
    have hmem : f - r ∈ I := by
      rw [hfr, add_sub_cancel_right, Finsupp.linearCombination_apply, Finsupp.sum]
      exact Ideal.sum_mem _ fun i _ => by rw [smul_eq_mul]; exact Ideal.mul_mem_left _ _ (hgI i)
    rw [Ideal.Quotient.eq.mpr hmem, r.as_sum, map_sum]
    refine Submodule.sum_mem _ fun e he => ?_
    have heT : e ∈ T := by
      refine ⟨fun j => Nat.zero_le _, fun j => ?_⟩
      have := hr e he j
      rw [hd j, Finsupp.single_le_iff] at this
      rw [Finsupp.coe_equivFunOnFinite_symm]
      omega
    have hmono : monomial e (r.coeff e) = (r.coeff e) • monomial e (1 : k) := by
      rw [smul_monomial, smul_eq_mul, mul_one]
    rw [hmono, show Ideal.Quotient.mk I ((r.coeff e) • monomial e (1 : k)) =
      Ideal.Quotient.mkₐ k I ((r.coeff e) • monomial e (1 : k)) from rfl, map_smul]
    exact Submodule.smul_mem _ _ (Submodule.subset_span ⟨e, heT, rfl⟩)
  tfae_have 1 → 2 := by
    intro hV
    rw [Module.finite_iff_krullDimLE_zero, Ring.krullDimLE_zero_iff]
    intro P hP
    have hmaxfin : {J : Ideal (MvPolynomial σ k ⧸ I) | J.IsMaximal}.Finite := by
      have key : ∀ J : {J : Ideal (MvPolynomial σ k ⧸ I) // J.IsMaximal},
          ∃ x ∈ zeroLocus K I, J.1.comap (Ideal.Quotient.mk I) = vanishingIdeal k {x} := by
        intro J
        have := J.2
        have hJ' : (J.1.comap (Ideal.Quotient.mk I)).IsMaximal :=
          Ideal.comap_isMaximal_of_surjective _ Ideal.Quotient.mk_surjective
        obtain ⟨x, hx⟩ := eq_vanishingIdeal_singleton_of_isMaximal K hJ'
        refine ⟨x, fun g hg => ?_, hx⟩
        have hg' : g ∈ J.1.comap (Ideal.Quotient.mk I) := by
          rw [Ideal.mem_comap, Ideal.Quotient.eq_zero_iff_mem.mpr hg]; exact J.1.zero_mem
        rw [hx] at hg'
        exact (mem_vanishingIdeal_singleton_iff x g).mp hg'
      choose x hxV hx using key
      have hinj : Function.Injective (fun J => (⟨x J, hxV J⟩ : zeroLocus K I)) := by
        intro J J' h
        have h' : x J = x J' := congrArg Subtype.val h
        apply Subtype.ext
        apply Ideal.comap_injective_of_surjective (Ideal.Quotient.mk I) Ideal.Quotient.mk_surjective
        rw [hx, hx, h']
      have := hV.to_subtype
      have : Finite {J : Ideal (MvPolynomial σ k ⧸ I) // J.IsMaximal} := Finite.of_injective _ hinj
      exact Set.toFinite _
    have hjac : P.jacobson = P := IsJacobsonRing.out' P hP.isRadical
    let S := {J : Ideal (MvPolynomial σ k ⧸ I) | P ≤ J ∧ J.IsMaximal}
    have hSfin : S.Finite := hmaxfin.subset fun J hJ => hJ.2
    have hle : hSfin.toFinset.inf id ≤ P := by
      rw [Finset.inf_id_eq_sInf, Set.Finite.coe_toFinset]
      exact hjac.le
    obtain ⟨J, hJS, hJP⟩ := hP.inf_le'.mp hle
    rw [Set.Finite.mem_toFinset] at hJS
    have : P = J := le_antisymm hJS.1 hJP
    rw [this]; exact hJS.2
  tfae_finish

/-- Counting before finding. If the remainders `k[x]/I` have a basis of `n` elements (`n` standard
monomials), then the system has at most `n` distinct solutions over an algebraically closed field
`K ⊇ k`. (The card states, with a named source, that the count is exactly `n` when each solution is
counted with its multiplicity.) -/
theorem number_of_solutions_le_number_of_standard_monomials
    {k K : Type*} [Field k] [Field K] [Algebra k K] [IsAlgClosed K] {σ : Type*} [Finite σ]
    (I : Ideal (MvPolynomial σ k)) {n : ℕ} (b : Module.Basis (Fin n) k (MvPolynomial σ k ⧸ I)) :
    (zeroLocus K I).encard ≤ n := by
  exact zd_card_le I b

/-! The card's worked example over `ℚ`, with `x = X 0` and `y = X 1`: the reach circle
`f₁ = x² + y² − 25` and the track `f₂ = x² + xy + y² − x − y − 30`. The standard monomials in
grevlex with `x > y` are `1, y, x, y²`, in that order. -/

-- The four crossings (4, 3), (3, 4), (0, −5), (−5, 0) lie on the circle and on the track.
example : (4 : ℤ) ^ 2 + 3 ^ 2 - 25 = 0 ∧ (3 : ℤ) ^ 2 + 4 ^ 2 - 25 = 0 ∧
    (0 : ℤ) ^ 2 + (-5) ^ 2 - 25 = 0 ∧ (-5 : ℤ) ^ 2 + 0 ^ 2 - 25 = 0 := by
  decide

example : (4 : ℤ) ^ 2 + 4 * 3 + 3 ^ 2 - 4 - 3 - 30 = 0 ∧ (3 : ℤ) ^ 2 + 3 * 4 + 4 ^ 2 - 3 - 4 - 30 = 0 ∧
    (0 : ℤ) ^ 2 + 0 * (-5) + (-5) ^ 2 - 0 - (-5) - 30 = 0 ∧
    (-5 : ℤ) ^ 2 + (-5) * 0 + 0 ^ 2 - (-5) - 0 - 30 = 0 := by
  decide

-- Track minus circle: f₂ − f₁ = xy − x − y − 5.
example : ((X 0 ^ 2 + X 0 * X 1 + X 1 ^ 2 - X 0 - X 1 - 30) - (X 0 ^ 2 + X 1 ^ 2 - 25) :
    MvPolynomial (Fin 2) ℚ) = X 0 * X 1 - X 0 - X 1 - 5 := by
  ring

-- The third Gröbner basis element lies in I: y³ − y² + 6x − 24y + 30 = (x + y) f₁ − (x + 1) f₂.
example : (X 1 ^ 3 - X 1 ^ 2 + 6 * X 0 - 24 * X 1 + 30 : MvPolynomial (Fin 2) ℚ) =
    (X 0 + X 1) * (X 0 ^ 2 + X 1 ^ 2 - 25) -
      (X 0 + 1) * (X 0 ^ 2 + X 0 * X 1 + X 1 ^ 2 - X 0 - X 1 - 30) := by
  ring

-- The column for x · y²: xy² = (y + 1)(xy − x − y − 5) + (y² + x + 6y + 5).
example : (X 0 * X 1 ^ 2 : MvPolynomial (Fin 2) ℚ) =
    (X 1 + 1) * (X 0 * X 1 - X 0 - X 1 - 5) + (X 1 ^ 2 + X 0 + 6 * X 1 + 5) := by
  ring

-- The left eigenvectors of M_x: v_p M_x = x_p v_p at (4, 3), (3, 4), (0, −5) and (−5, 0),
-- with v_p = (1, y_p, x_p, y_p²).
example : Matrix.vecMul ![(1 : ℤ), 3, 4, 9] !![0, 5, 25, 5; 0, 1, 0, 6; 1, 1, 0, 1; 0, 0, -1, 1] =
    (4 : ℤ) • ![1, 3, 4, 9] := by
  decide

example : Matrix.vecMul ![(1 : ℤ), 4, 3, 16] !![0, 5, 25, 5; 0, 1, 0, 6; 1, 1, 0, 1; 0, 0, -1, 1] =
    ![3, 12, 9, 48] ∧ (![3, 12, 9, 48] : Fin 4 → ℤ) = (3 : ℤ) • ![1, 4, 3, 16] := by
  decide

example : Matrix.vecMul ![(1 : ℤ), -5, 0, 25] !![0, 5, 25, 5; 0, 1, 0, 6; 1, 1, 0, 1; 0, 0, -1, 1] =
    (0 : ℤ) • ![1, -5, 0, 25] := by
  decide

example : Matrix.vecMul ![(1 : ℤ), 0, -5, 0] !![0, 5, 25, 5; 0, 1, 0, 6; 1, 1, 0, 1; 0, 0, -1, 1] =
    (-5 : ℤ) • ![1, 0, -5, 0] := by
  decide

-- M_x and M_y commute.
example : !![(0 : ℤ), 5, 25, 5; 0, 1, 0, 6; 1, 1, 0, 1; 0, 0, -1, 1] *
      !![0, 0, 5, -30; 1, 0, 1, 24; 0, 0, 1, -6; 0, 1, 0, 1] =
    !![0, 0, 5, -30; 1, 0, 1, 24; 0, 0, 1, -6; 0, 1, 0, 1] *
      !![(0 : ℤ), 5, 25, 5; 0, 1, 0, 6; 1, 1, 0, 1; 0, 0, -1, 1] := by
  decide

-- The characteristic polynomial t⁴ − 2t³ − 23t² + 60t has roots 4, 3, 0, −5;
-- trace of M_x = 0 + 1 + 0 + 1 = 2 = 4 + 3 + 0 + (−5).
example (t : ℤ) : t ^ 4 - 2 * t ^ 3 - 23 * t ^ 2 + 60 * t = (t - 4) * (t - 3) * t * (t + 5) := by
  ring

example : (0 : ℤ) + 1 + 0 + 1 = 2 ∧ (4 : ℤ) + 3 + 0 + (-5) = 2 := by decide

-- The shape lemma's second piece y = −(1/6)x³ + (1/6)x² + 4x − 5 gives y = 3, 4, −5, 0
-- at x = 4, 3, 0, −5.
example : -(1 / 6 : ℚ) * 4 ^ 3 + (1 / 6) * 4 ^ 2 + 4 * 4 - 5 = 3 ∧
    -(1 / 6 : ℚ) * 3 ^ 3 + (1 / 6) * 3 ^ 2 + 4 * 3 - 5 = 4 ∧
    -(1 / 6 : ℚ) * 0 ^ 3 + (1 / 6) * 0 ^ 2 + 4 * 0 - 5 = -5 ∧
    -(1 / 6 : ℚ) * (-5) ^ 3 + (1 / 6) * (-5) ^ 2 + 4 * (-5) - 5 = 0 := by
  norm_num

-- What breaks: the right eigenvector of M_x at 3 is (1, −3/10, 1/5, −1/10), not a point's values.
example : Matrix.mulVec !![(0 : ℚ), 5, 25, 5; 0, 1, 0, 6; 1, 1, 0, 1; 0, 0, -1, 1]
      ![1, -3 / 10, 1 / 5, -1 / 10] = (3 : ℚ) • ![1, -3 / 10, 1 / 5, -1 / 10] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_four]

-- What breaks: the track 16x² + 9y² = 288 meets the circle at (3, ±4) and (−3, ±4), two points per x.
example : (16 : ℤ) * 3 ^ 2 + 9 * 4 ^ 2 = 288 ∧ (16 : ℤ) * 3 ^ 2 + 9 * (-4) ^ 2 = 288 ∧
    (3 : ℤ) ^ 2 + 4 ^ 2 = 25 ∧ (3 : ℤ) ^ 2 + (-4) ^ 2 = 25 := by
  decide

-- What breaks: the tangent track x² + xy + y² − 4x − 5y = 5 passes through (5, 0) on the circle.
example : (5 : ℤ) ^ 2 + 5 * 0 + 0 ^ 2 - 4 * 5 - 5 * 0 = 5 ∧ (5 : ℤ) ^ 2 + 0 ^ 2 = 25 := by decide

#print axioms multiplication_matrix_eigenvalues_are_values_at_solutions
#print axioms zero_dimensional_iff_pure_power_leading_terms
#print axioms number_of_solutions_le_number_of_standard_monomials
