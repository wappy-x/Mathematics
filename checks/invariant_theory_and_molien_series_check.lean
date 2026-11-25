-- Invariants of a finite group: for a finite group of matrices over a field where its size is not 0, the Reynolds average makes invariants, the invariant ring is finitely generated, and Molien's formula counts its members of each degree.
import Mathlib.RingTheory.MvPolynomial.Homogeneous
import Mathlib.RingTheory.PowerSeries.Inverse
import Mathlib.RingTheory.FiniteType
import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Defs
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.RingTheory.Adjoin.Tower
import Mathlib.RingTheory.Invariant.Basic
import Mathlib.LinearAlgebra.Trace
import Mathlib.LinearAlgebra.Eigenspace.Semisimple
import Mathlib.FieldTheory.IsAlgClosed.AlgebraicClosure
import Mathlib.FieldTheory.Separable
import Mathlib.LinearAlgebra.Matrix.Basis

open MvPolynomial

variable {k : Type*} [Field k] {n : ℕ}

/-- A matrix `g` acts on a polynomial by linear substitution: `(g · f)(x) = f(g x)`,
that is, each `x_i` becomes `∑ j, g i j * x_j`. -/
noncomputable def linSubst (g : Matrix (Fin n) (Fin n) k) :
    MvPolynomial (Fin n) k →ₐ[k] MvPolynomial (Fin n) k :=
  aeval fun i => ∑ j, C (g i j) * X j

/-- The ring of invariants `k[x_1, …, x_n]^G`: the polynomials `f` with `g · f = f`
for every matrix `g` in the group `G`. -/
noncomputable def invariantRing (G : Subgroup (GL (Fin n) k)) :
    Subalgebra k (MvPolynomial (Fin n) k) :=
  ⨅ g : G, AlgHom.equalizer (linSubst ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k))
    (AlgHom.id k _)

/-- The Reynolds operator: `R(f) = (1/|G|) ∑_{g ∈ G} g · f`, the average of `f` over `G`. -/
noncomputable def reynolds (G : Subgroup (GL (Fin n) k)) [Fintype G]
    (f : MvPolynomial (Fin n) k) : MvPolynomial (Fin n) k :=
  (Fintype.card G : k)⁻¹ • ∑ g : G, linSubst ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) f

section Helpers

variable {F : Type*} [Field F]

theorem linSubst_mul (A B : Matrix (Fin n) (Fin n) k) :
    linSubst (A * B) = (linSubst B).comp (linSubst A) := by
  apply MvPolynomial.algHom_ext
  intro i
  simp only [linSubst, AlgHom.comp_apply, aeval_X, map_sum, map_mul, aeval_C,
    Matrix.mul_apply, algebraMap_eq, Finset.mul_sum, map_sum]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun l _ => ?_
  rw [Finset.sum_mul]
  refine Finset.sum_congr rfl fun j _ => ?_
  simp [mul_assoc]

theorem linSubst_one : linSubst (1 : Matrix (Fin n) (Fin n) k) = AlgHom.id k _ := by
  apply MvPolynomial.algHom_ext
  intro i
  simp [linSubst, Matrix.one_apply]

theorem mem_invariantRing (G : Subgroup (GL (Fin n) k)) (f : MvPolynomial (Fin n) k) :
    f ∈ invariantRing G ↔ ∀ g : G, linSubst ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) f = f := by
  simp [invariantRing, Algebra.mem_iInf, AlgHom.mem_equalizer]

theorem linSubst_reynolds (G : Subgroup (GL (Fin n) k)) [Fintype G] (h : G)
    (f : MvPolynomial (Fin n) k) :
    linSubst ((h : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) (reynolds G f) = reynolds G f := by
  have key : ∀ g : G, linSubst ((h : GL (Fin n) k) : Matrix (Fin n) (Fin n) k)
      (linSubst ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) f) =
      linSubst (((g * h : G) : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) f := by
    intro g
    simp [linSubst_mul]
  have hs : ∑ g : G, linSubst ((h : GL (Fin n) k) : Matrix (Fin n) (Fin n) k)
      (linSubst ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) f) =
      ∑ g : G, linSubst ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) f := by
    simp_rw [key]
    exact Fintype.sum_equiv (Equiv.mulRight h) _ _ (fun _ => rfl)
  unfold reynolds
  rw [map_smul, map_sum, hs]

theorem reynolds_props (G : Subgroup (GL (Fin n) k)) [Fintype G]
    (hG : (Fintype.card G : k) ≠ 0) :
    (∀ f, reynolds G f ∈ invariantRing G) ∧
    (∀ f ∈ invariantRing G, reynolds G f = f) ∧
    (∀ p, ∀ f ∈ invariantRing G, reynolds G (p * f) = reynolds G p * f) := by
  refine ⟨fun f => (mem_invariantRing G _).mpr fun h => linSubst_reynolds G h f, ?_, ?_⟩
  · intro f hf
    rw [mem_invariantRing] at hf
    unfold reynolds
    simp_rw [hf]
    rw [Finset.sum_const, Finset.card_univ, ← Nat.cast_smul_eq_nsmul k, smul_smul,
      inv_mul_cancel₀ hG, one_smul]
  · intro p f hf
    rw [mem_invariantRing] at hf
    unfold reynolds
    simp_rw [map_mul, hf, ← Finset.sum_mul, smul_mul_assoc]

/-- the multidegrees of total degree `d` -/
noncomputable def degSet (n d : ℕ) : Finset (Fin n →₀ ℕ) := Finset.univ.finsuppAntidiag d

theorem mem_degSet {d : ℕ} (a : Fin n →₀ ℕ) : a ∈ degSet n d ↔ a.degree = d := by
  simp [degSet, Finset.mem_finsuppAntidiag, Finsupp.degree_eq_sum]

theorem homogeneousSubmodule_eq_supported (d : ℕ) :
    homogeneousSubmodule (Fin n) F d =
      AddMonoidAlgebra.supported F F ((degSet n d : Finset _) : Set (Fin n →₀ ℕ)) := by
  rw [homogeneousSubmodule_eq_finsupp_supported]
  congr 1
  ext a
  simp [mem_degSet]

noncomputable def homBasis (d : ℕ) :
    Module.Basis (degSet n d) F (homogeneousSubmodule (Fin n) F d) :=
  (Finsupp.basisSingleOne).map
    ((LinearEquiv.ofEq _ _ (homogeneousSubmodule_eq_supported (F := F) d)).trans
      (AddMonoidAlgebra.supportedEquivFinsupp _)).symm

theorem homBasis_repr (d : ℕ) (x : homogeneousSubmodule (Fin n) F d) (a : degSet n d) :
    (homBasis d).repr x a = (x : MvPolynomial (Fin n) F).coeff (a : Fin n →₀ ℕ) := by
  rfl

theorem homBasis_apply (d : ℕ) (a : degSet n d) :
    ((homBasis (F := F) d a : homogeneousSubmodule (Fin n) F d) : MvPolynomial (Fin n) F) =
      monomial (a : Fin n →₀ ℕ) 1 := by
  classical
  ext m
  have := homBasis_repr (F := F) d (homBasis d a)
  rw [MvPolynomial.coeff_monomial]
  by_cases h : (a : Fin n →₀ ℕ) = m
  · subst h
    have h2 := congrArg (fun f => f a) ((homBasis (F := F) d).repr_self a)
    simp only [Finsupp.single_eq_same] at h2
    rw [ite_eq_left rfl, ← homBasis_repr]; exact h2
  · rw [ite_eq_right h]
    by_cases hm : m ∈ degSet n d
    · have h2 := congrArg (fun f => f ⟨m, hm⟩) ((homBasis (F := F) d).repr_self a)
      rw [Finsupp.single_eq_of_ne (by intro e; apply h; exact congrArg Subtype.val e.symm)] at h2
      rw [← h2]; rfl
    · have := (homBasis (F := F) d a).2
      rw [mem_homogeneousSubmodule] at this
      exact this.coeff_eq_zero (by rwa [mem_degSet] at hm)

theorem linSubst_mem_hom (g : Matrix (Fin n) (Fin n) F) (d : ℕ) :
    ∀ x ∈ homogeneousSubmodule (Fin n) F d,
      linSubst g x ∈ homogeneousSubmodule (Fin n) F d := by
  intro x hx
  rw [mem_homogeneousSubmodule] at *
  have := hx.aeval (fun i => ∑ j, C (g i j) * X j) (n := 1)
    (fun i => IsHomogeneous.sum _ _ _ (fun j _ => isHomogeneous_C_mul_X _ _))
  simpa [linSubst] using this

noncomputable def homAct (g : Matrix (Fin n) (Fin n) F) (d : ℕ) :
    Module.End F (homogeneousSubmodule (Fin n) F d) :=
  (linSubst g).toLinearMap.restrict (linSubst_mem_hom g d)

theorem homAct_apply (g : Matrix (Fin n) (Fin n) F) (d : ℕ)
    (x : homogeneousSubmodule (Fin n) F d) :
    ((homAct g d x : homogeneousSubmodule (Fin n) F d) : MvPolynomial (Fin n) F) =
      linSubst g (x : MvPolynomial (Fin n) F) := rfl

theorem homAct_mul (A B : Matrix (Fin n) (Fin n) F) (d : ℕ) :
    homAct (A * B) d = homAct B d * homAct A d := by
  ext x
  simp [homAct_apply, linSubst_mul]

theorem homAct_one (d : ℕ) : homAct (1 : Matrix (Fin n) (Fin n) F) d = 1 := by
  ext x
  simp [homAct_apply, linSubst_one]

instance homFinite (d : ℕ) : FiniteDimensional F (homogeneousSubmodule (Fin n) F d) :=
  Module.Finite.of_basis (homBasis d)

theorem trace_homAct (g : Matrix (Fin n) (Fin n) F) (d : ℕ) :
    LinearMap.trace F _ (homAct g d) =
      ∑ a ∈ degSet n d, (linSubst g (monomial a 1)).coeff a := by
  classical
  rw [LinearMap.trace_eq_matrix_trace F (homBasis d), Matrix.trace]
  simp only [Matrix.diag, LinearMap.toMatrix_apply, homBasis_repr, homAct_apply, homBasis_apply]
  exact Finset.sum_coe_sort (degSet n d) (fun a => (linSubst g (monomial a 1)).coeff a)

theorem trace_homAct_conj (P D Q : Matrix (Fin n) (Fin n) F) (hQP : Q * P = 1) (d : ℕ) :
    LinearMap.trace F _ (homAct (P * D * Q) d) = LinearMap.trace F _ (homAct D d) := by
  rw [homAct_mul, homAct_mul, LinearMap.trace_mul_comm, mul_assoc, ← homAct_mul, hQP,
    homAct_one, mul_one]

theorem linSubst_diagonal_monomial (μ : Fin n → F) (a : Fin n →₀ ℕ) :
    linSubst (Matrix.diagonal μ) (monomial a 1) = monomial a (∏ i, μ i ^ a i) := by
  have hX : ∀ i, linSubst (Matrix.diagonal μ) (X i) = C (μ i) * X i := by
    intro i
    simp only [linSubst, aeval_X, Matrix.diagonal_apply]
    rw [Finset.sum_eq_single i]
    · simp
    · intro j _ hj; simp [Ne.symm hj]
    · simp
  rw [monomial_eq, monomial_eq, map_mul, map_one, map_one, one_mul, ← Finsupp.prod_pow]
  simp only [Finsupp.prod, map_prod, map_pow, hX, mul_pow, Finset.prod_mul_distrib]

theorem linSubst_map {K : Type*} [Field K] (φ : F →+* K) (g : Matrix (Fin n) (Fin n) F)
    (p : MvPolynomial (Fin n) F) :
    linSubst (g.map φ) (MvPolynomial.map φ p) = MvPolynomial.map φ (linSubst g p) := by
  have : (linSubst (g.map φ)).toRingHom.comp (MvPolynomial.map φ) =
      (MvPolynomial.map φ).comp (linSubst g).toRingHom := by
    apply MvPolynomial.ringHom_ext
    · intro r; simp [linSubst]
    · intro i; simp [linSubst]
  exact congrArg (fun h => h p) this

theorem trace_homAct_map {K : Type*} [Field K] (φ : F →+* K) (g : Matrix (Fin n) (Fin n) F)
    (d : ℕ) : φ (LinearMap.trace F _ (homAct g d)) = LinearMap.trace K _ (homAct (g.map φ) d) := by
  rw [trace_homAct, trace_homAct, map_sum]
  refine Finset.sum_congr rfl fun a _ => ?_
  rw [← MvPolynomial.coeff_map, ← linSubst_map, MvPolynomial.map_monomial, map_one]

noncomputable def molDet (g : Matrix (Fin n) (Fin n) F) : PowerSeries F :=
  Matrix.det ((1 : Matrix (Fin n) (Fin n) (PowerSeries F)) -
    (PowerSeries.X : PowerSeries F) • g.map (PowerSeries.C : F →+* PowerSeries F))

theorem constantCoeff_molDet (g : Matrix (Fin n) (Fin n) F) :
    PowerSeries.constantCoeff (molDet g) = 1 := by
  rw [molDet, RingHom.map_det]
  have : (PowerSeries.constantCoeff : PowerSeries F →+* F).mapMatrix
      ((1 : Matrix (Fin n) (Fin n) (PowerSeries F)) -
        (PowerSeries.X : PowerSeries F) • g.map (PowerSeries.C : F →+* PowerSeries F)) = 1 := by
    ext i j
    simp [Matrix.one_apply]
  rw [this, Matrix.det_one]

theorem molDet_map {K : Type*} [Field K] (φ : F →+* K) (g : Matrix (Fin n) (Fin n) F) :
    PowerSeries.map φ (molDet g) = molDet (g.map φ) := by
  rw [molDet, molDet, RingHom.map_det]
  congr 1
  ext i j
  simp [Matrix.one_apply]

theorem molDet_conj (P D Q : Matrix (Fin n) (Fin n) F) (hPQ : P * Q = 1) :
    molDet (P * D * Q) = molDet D := by
  have hPQ' : P.map (PowerSeries.C : F →+* PowerSeries F) * Q.map PowerSeries.C = 1 := by
    rw [← Matrix.map_mul, hPQ, Matrix.map_one _ (map_zero _) (map_one _)]
  have h : (1 : Matrix (Fin n) (Fin n) (PowerSeries F)) -
      (PowerSeries.X : PowerSeries F) • (P * D * Q).map (PowerSeries.C : F →+* PowerSeries F) =
      P.map PowerSeries.C * ((1 : Matrix (Fin n) (Fin n) (PowerSeries F)) -
        (PowerSeries.X : PowerSeries F) • D.map (PowerSeries.C : F →+* PowerSeries F)) *
        Q.map PowerSeries.C := by
    rw [Matrix.map_mul, Matrix.map_mul, Matrix.mul_sub, Matrix.sub_mul, Matrix.mul_one, hPQ',
      Matrix.mul_smul, Matrix.smul_mul]
  rw [molDet, molDet, h, Matrix.det_mul, Matrix.det_mul, mul_comm, ← mul_assoc,
    ← Matrix.det_mul, Matrix.det_mul (Q.map _), mul_comm (Q.map _).det, ← Matrix.det_mul, hPQ',
    Matrix.det_one, one_mul]

theorem molDet_diagonal (μ : Fin n → F) :
    molDet (Matrix.diagonal μ) = ∏ i, (1 - PowerSeries.X * PowerSeries.C (μ i)) := by
  have h : (1 : Matrix (Fin n) (Fin n) (PowerSeries F)) -
      (PowerSeries.X : PowerSeries F) •
        (Matrix.diagonal μ).map (PowerSeries.C : F →+* PowerSeries F) =
      Matrix.diagonal fun i => 1 - PowerSeries.X * PowerSeries.C (μ i) := by
    ext i j
    by_cases hij : i = j
    · subst hij; simp
    · simp [hij, Matrix.one_apply_ne hij]
  rw [molDet, h, Matrix.det_diagonal]

theorem geom_mul (c : F) :
    PowerSeries.mk (fun m => c ^ m) * (1 - PowerSeries.X * PowerSeries.C c) = 1 := by
  ext m
  rw [mul_sub, mul_one, map_sub, mul_left_comm, PowerSeries.coeff_one]
  rcases m with _ | m
  · simp
  · rw [PowerSeries.coeff_succ_X_mul, mul_comm, PowerSeries.coeff_C_mul, PowerSeries.coeff_mk,
      PowerSeries.coeff_mk, pow_succ]
    simp [mul_comm]

theorem series_diagonal (μ : Fin n → F) :
    PowerSeries.mk (fun d => ∑ a ∈ degSet n d, ∏ i, μ i ^ a i) *
      ∏ i, (1 - PowerSeries.X * PowerSeries.C (μ i)) = 1 := by
  classical
  have : PowerSeries.mk (fun d => ∑ a ∈ degSet n d, ∏ i, μ i ^ a i) =
      ∏ i, PowerSeries.mk (fun m => μ i ^ m) := by
    ext d
    rw [PowerSeries.coeff_prod, PowerSeries.coeff_mk]
    simp [degSet, PowerSeries.coeff_mk]
  rw [this, ← Finset.prod_mul_distrib]
  exact Finset.prod_eq_one fun i _ => geom_mul (μ i)

theorem exists_diag {K : Type*} [Field K] [IsAlgClosed K] [CharZero K]
    (g : Matrix (Fin n) (Fin n) K) {m : ℕ} (hm : 0 < m) (hg : g ^ m = 1) :
    ∃ P Q : Matrix (Fin n) (Fin n) K, ∃ μ : Fin n → K,
      P * Q = 1 ∧ Q * P = 1 ∧ g = P * Matrix.diagonal μ * Q := by
  classical
  set f : Module.End K (Fin n → K) := Matrix.toLin' g with hfdef
  have hf : f.IsSemisimple := by
    apply Module.End.isSemisimple_of_squarefree_aeval_eq_zero (p := Polynomial.X ^ m - 1)
    · exact (Polynomial.separable_X_pow_sub_C (1 : K) (by exact_mod_cast hm.ne')
        one_ne_zero).squarefree
    · simp [f, ← Matrix.toLin'_pow, hg]
      exact sub_eq_zero.mpr rfl
  have htop := hf.iSup_eigenspace_eq_top
  rw [Submodule.iSup_eq_span] at htop
  obtain ⟨t, hts, hspan, hli⟩ := exists_linearIndependent K
    (⋃ μ : K, (f.eigenspace μ : Set (Fin n → K)))
  let b0 : Module.Basis t K (Fin n → K) :=
    Module.Basis.mk hli (by rw [Subtype.range_coe, hspan, htop])
  let _ : Fintype t := FiniteDimensional.fintypeBasisIndex b0
  have hcard : Fintype.card t = n := by
    rw [← Module.finrank_eq_card_basis b0, Module.finrank_fin_fun]
  let b : Module.Basis (Fin n) K (Fin n → K) := b0.reindex (Fintype.equivFinOfCardEq hcard)
  have hb : ∀ i, ∃ c : K, f (b i) = c • b i := by
    intro i
    have hmem : b i ∈ ⋃ μ : K, (f.eigenspace μ : Set (Fin n → K)) := by
      apply hts
      simp [b, b0]
    obtain ⟨c, hc⟩ := Set.mem_iUnion.mp hmem
    exact ⟨c, Module.End.mem_eigenspace_iff.mp hc⟩
  choose μ hμ using hb
  set P := (Pi.basisFun K (Fin n)).toMatrix b with hP
  set Q := b.toMatrix (Pi.basisFun K (Fin n)) with hQ
  have hPQ : P * Q = 1 := Module.Basis.toMatrix_mul_toMatrix_flip _ _
  have hQP : Q * P = 1 := Module.Basis.toMatrix_mul_toMatrix_flip _ _
  have hgP : g * P = P * Matrix.diagonal μ := by
    ext i j
    rw [Matrix.mul_diagonal, hP, Module.Basis.toMatrix_apply, Pi.basisFun_repr]
    have := congrFun (hμ j) i
    simp only [f, Matrix.toLin'_apply, Pi.smul_apply, smul_eq_mul] at this
    rw [mul_comm, ← this, Matrix.mul_apply, Matrix.mulVec, dotProduct]
    simp [Module.Basis.toMatrix_apply, Pi.basisFun_repr]
  refine ⟨P, Q, μ, hPQ, hQP, ?_⟩
  calc g = g * (P * Q) := by rw [hPQ, Matrix.mul_one]
    _ = P * Matrix.diagonal μ * Q := by rw [← Matrix.mul_assoc, hgP]

theorem series_mul_molDet_alg {K : Type*} [Field K] [IsAlgClosed K] [CharZero K]
    (g : Matrix (Fin n) (Fin n) K) {m : ℕ} (hm : 0 < m) (hg : g ^ m = 1) :
    PowerSeries.mk (fun d => LinearMap.trace K _ (homAct g d)) * molDet g = 1 := by
  obtain ⟨P, Q, μ, hPQ, hQP, rfl⟩ := exists_diag g hm hg
  have h1 : (fun d => LinearMap.trace K _ (homAct (P * Matrix.diagonal μ * Q) d)) =
      fun d => ∑ a ∈ degSet n d, ∏ i, μ i ^ a i := by
    funext d
    rw [trace_homAct_conj P _ Q hQP, trace_homAct]
    refine Finset.sum_congr rfl fun a _ => ?_
    rw [linSubst_diagonal_monomial, MvPolynomial.coeff_monomial, ite_eq_left rfl]
  rw [h1, molDet_conj P _ Q hPQ, molDet_diagonal]
  exact series_diagonal μ

theorem series_mul_molDet [CharZero F] (g : Matrix (Fin n) (Fin n) F) {m : ℕ} (hm : 0 < m)
    (hg : g ^ m = 1) :
    PowerSeries.mk (fun d => LinearMap.trace F _ (homAct g d)) * molDet g = 1 := by
  let φ := algebraMap F (AlgebraicClosure F)
  apply PowerSeries.map_injective φ φ.injective
  rw [map_mul, map_one, molDet_map]
  have h1 : PowerSeries.map φ (PowerSeries.mk (fun d => LinearMap.trace F _ (homAct g d))) =
      PowerSeries.mk (fun d => LinearMap.trace _ _ (homAct (g.map φ) d)) := by
    ext d
    simp [trace_homAct_map]
  rw [h1]
  refine series_mul_molDet_alg (g.map φ) hm ?_
  rw [← Matrix.map_pow, hg, Matrix.map_one _ (map_zero φ) (map_one φ)]

theorem finrank_invariants_hom [CharZero k] (G : Subgroup (GL (Fin n) k)) [Fintype G] (d : ℕ) :
    (Module.finrank k
        ↥(Subalgebra.toSubmodule (invariantRing G) ⊓ homogeneousSubmodule (Fin n) k d) : k) =
      (Fintype.card G : k)⁻¹ * ∑ g : G, LinearMap.trace k _
        (homAct ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) d) := by
  classical
  have hG : (Fintype.card G : k) ≠ 0 := Nat.cast_ne_zero.mpr Fintype.card_ne_zero
  obtain ⟨h1, h2, -⟩ := reynolds_props G hG
  set W := homogeneousSubmodule (Fin n) k d with hW
  set R : Module.End k W := (Fintype.card G : k)⁻¹ •
    ∑ g : G, homAct ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) d with hR
  have hRx : ∀ x : W, ((R x : W) : MvPolynomial (Fin n) k) = reynolds G x := by
    intro x
    rw [hR, LinearMap.smul_apply, Submodule.coe_smul, LinearMap.sum_apply, Submodule.coe_sum]
    rfl
  let p : Submodule k W := (Subalgebra.toSubmodule (invariantRing G) ⊓ W).comap W.subtype
  have hproj : LinearMap.IsProj p R := by
    constructor
    · intro x
      simp only [p, Submodule.mem_comap, Submodule.subtype_apply, Submodule.mem_inf]
      exact ⟨by rw [hRx]; exact h1 _, (R x).2⟩
    · intro x hx
      simp only [p, Submodule.mem_comap, Submodule.subtype_apply, Submodule.mem_inf] at hx
      apply Subtype.ext
      rw [hRx]
      exact h2 _ hx.1
  have : FiniteDimensional k W := homFinite d
  have : Module.Free k p := Module.Free.of_divisionRing k p
  have : Module.Free k (LinearMap.ker R) :=
    Module.Free.of_basis (Module.Basis.ofVectorSpace k (LinearMap.ker R))
  have htr := hproj.trace
  rw [(Submodule.comapSubtypeEquivOfLe inf_le_right).finrank_eq] at htr
  rw [← htr, hR, map_smul, map_sum, smul_eq_mul]

end Helpers

/-- Hilbert's finiteness theorem for a finite group: if `G` is a finite group of
invertible matrices acting on `k[x_1, …, x_n]` by linear substitution, over a field `k`
in which the group's size `|G|` is not 0, then the ring of invariants `k[x_1, …, x_n]^G`
is generated, as a `k`-algebra, by finitely many invariants. -/
theorem invariant_ring_finitely_generated (G : Subgroup (GL (Fin n) k)) [Finite G]
    (hG : (Nat.card G : k) ≠ 0) : (invariantRing G).FG := by
  classical
  let ρ : G →* (MvPolynomial (Fin n) k ≃ₐ[k] MvPolynomial (Fin n) k) :=
    { toFun := fun g => AlgEquiv.ofAlgHom
        (linSubst (((g⁻¹ : G) : GL (Fin n) k) : Matrix (Fin n) (Fin n) k))
        (linSubst (((g : G) : GL (Fin n) k) : Matrix (Fin n) (Fin n) k))
        (by rw [← linSubst_mul]; simp [linSubst_one])
        (by rw [← linSubst_mul]; simp [linSubst_one])
      map_one' := by ext1 f; simp [linSubst_one]
      map_mul' := by
        intro a b; ext1 f
        simp [AlgEquiv.mul_apply, mul_inv_rev, linSubst_mul] }
  let _ : MulSemiringAction G (MvPolynomial (Fin n) k) :=
    MulSemiringAction.compHom (MvPolynomial (Fin n) k) ρ
  have : Algebra.IsInvariant (invariantRing G) (MvPolynomial (Fin n) k) G := by
    refine ⟨fun b hb => ⟨⟨b, ?_⟩, rfl⟩⟩
    rw [mem_invariantRing]
    intro g
    have h1 : ρ g⁻¹ b = b := hb g⁻¹
    simpa [ρ] using h1
  have : Algebra.IsIntegral (invariantRing G) (MvPolynomial (Fin n) k) :=
    Algebra.IsInvariant.isIntegral (invariantRing G) (MvPolynomial (Fin n) k) G
  have : Algebra.FiniteType (invariantRing G) (MvPolynomial (Fin n) k) :=
    Algebra.FiniteType.of_restrictScalars_finiteType k (invariantRing G) _
  have : Module.Finite (invariantRing G) (MvPolynomial (Fin n) k) := Algebra.IsIntegral.finite
  have h := fg_of_fg_of_fg k (invariantRing G) (MvPolynomial (Fin n) k)
    (Algebra.FiniteType.out) (Module.Finite.fg_top) Subtype.val_injective
  exact (Subalgebra.fg_top _).mp h

/-- The Reynolds operator, for a finite matrix group `G` over a field where `|G|` is not 0:
(1) `R(f)` is invariant for every polynomial `f`; (2) `R(f) = f` when `f` is already
invariant; (3) `R(p f) = R(p) f` when `f` is invariant and `p` is any polynomial. -/
theorem reynolds_makes_and_keeps_invariants (G : Subgroup (GL (Fin n) k)) [Fintype G]
    (hG : (Fintype.card G : k) ≠ 0) :
    (∀ f, reynolds G f ∈ invariantRing G) ∧
    (∀ f ∈ invariantRing G, reynolds G f = f) ∧
    (∀ p, ∀ f ∈ invariantRing G, reynolds G (p * f) = reynolds G p * f) := by
  exact reynolds_props G hG

/-- Molien's formula, over a field of characteristic 0: for a finite matrix group `G`,
let `a_d` be the number of independent invariants of degree `d` (the dimension of the
homogeneous invariants of degree `d`). Then `∑_d a_d t^d = (1/|G|) ∑_{g ∈ G} 1/det(I - t g)`
as power series in `t`. -/
theorem molien_formula [CharZero k] (G : Subgroup (GL (Fin n) k)) [Fintype G] :
    PowerSeries.mk (fun d => (Module.finrank k
        ↥(Subalgebra.toSubmodule (invariantRing G) ⊓ homogeneousSubmodule (Fin n) k d) : k)) =
      (Fintype.card G : k)⁻¹ • ∑ g : G,
        (Matrix.det ((1 : Matrix (Fin n) (Fin n) (PowerSeries k)) -
          (PowerSeries.X : PowerSeries k) • ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k).map
            (PowerSeries.C : k →+* PowerSeries k)))⁻¹ := by
  classical
  have hser : ∀ g : G,
      PowerSeries.mk (fun d => LinearMap.trace k _
        (homAct ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k) d)) =
      (molDet ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k))⁻¹ := by
    intro g
    rw [PowerSeries.eq_inv_iff_mul_eq_one (by rw [constantCoeff_molDet]; exact one_ne_zero)]
    refine series_mul_molDet _ (m := Fintype.card G) Fintype.card_pos ?_
    have : g ^ Fintype.card G = 1 := pow_card_eq_one
    rw [← Units.val_pow_eq_pow_val, ← Subgroup.coe_pow, this]
    simp
  change _ = (Fintype.card G : k)⁻¹ • ∑ g : G,
    (molDet ((g : GL (Fin n) k) : Matrix (Fin n) (Fin n) k))⁻¹
  simp_rw [← hser]
  ext d
  simp [finrank_invariants_hom, PowerSeries.coeff_mk, map_sum]

/-! Worked numbers from the card: the quarter turn `(x, y) ↦ (-y, x)` over `ℚ`. -/

-- the quarter turn A = [[0, -1], [1, 0]] has order 4: A^2 = -I and A^4 = I
example : !![(0 : ℤ), -1; 1, 0] ^ 2 = -1 := by decide
example : !![(0 : ℤ), -1; 1, 0] ^ 4 = 1 := by decide

-- u = x^2 + y^2, v = x^2 y^2 and w = x^3 y - x y^3 are unchanged when (x, y) becomes (-y, x)
example (x y : ℚ) : (-y) ^ 2 + x ^ 2 = x ^ 2 + y ^ 2 := by ring
example (x y : ℚ) : (-y) ^ 2 * x ^ 2 = x ^ 2 * y ^ 2 := by ring
example (x y : ℚ) : (-y) ^ 3 * x - (-y) * x ^ 3 = x ^ 3 * y - x * y ^ 3 := by ring

-- the one relation: w^2 = v (u^2 - 4 v)
example (x y : ℚ) : (x ^ 3 * y - x * y ^ 3) ^ 2 =
    x ^ 2 * y ^ 2 * ((x ^ 2 + y ^ 2) ^ 2 - 4 * (x ^ 2 * y ^ 2)) := by ring

-- round the orbit (3, 1), (-1, 3), (-3, -1), (1, -3): u, v, w = 10, 9, 24 each time
example : ∀ p ∈ [((3 : ℤ), (1 : ℤ)), (-1, 3), (-3, -1), (1, -3)],
    p.1 ^ 2 + p.2 ^ 2 = 10 ∧ p.1 ^ 2 * p.2 ^ 2 = 9 ∧ p.1 ^ 3 * p.2 - p.1 * p.2 ^ 3 = 24 := by
  decide

-- the relation at (3, 1): w^2 = 576 = 9 × (100 - 36)
example : (24 : ℤ) ^ 2 = 576 ∧ (9 : ℤ) * (10 ^ 2 - 4 * 9) = 576 := by norm_num

-- the four determinants det(I - t g): (1 - t)^2, 1 + t^2, (1 + t)^2, 1 + t^2
example (t : ℚ) : Matrix.det (1 - t • !![(1 : ℚ), 0; 0, 1]) = (1 - t) ^ 2 := by
  rw [Matrix.det_fin_two]; simp; ring
example (t : ℚ) : Matrix.det (1 - t • !![(0 : ℚ), -1; 1, 0]) = 1 + t ^ 2 := by
  rw [Matrix.det_fin_two]; simp; ring
example (t : ℚ) : Matrix.det (1 - t • !![(-1 : ℚ), 0; 0, -1]) = (1 + t) ^ 2 := by
  rw [Matrix.det_fin_two]; simp; ring
example (t : ℚ) : Matrix.det (1 - t • !![(0 : ℚ), 1; -1, 0]) = 1 + t ^ 2 := by
  rw [Matrix.det_fin_two]; simp; ring

-- Molien's average simplifies to (1 + t^4) / ((1 - t^2)(1 - t^4))
example (t : ℚ) (h1 : 1 - t ≠ 0) (h2 : 1 + t ≠ 0) (h3 : 1 + t ^ 2 ≠ 0) :
    (1 / 4 : ℚ) * (1 / (1 - t) ^ 2 + 2 / (1 + t ^ 2) + 1 / (1 + t) ^ 2) =
      (1 + t ^ 4) / ((1 - t ^ 2) * (1 - t ^ 4)) := by
  have h4 : 1 - t ^ 2 ≠ 0 := by
    have : 1 - t ^ 2 = (1 - t) * (1 + t) := by ring
    rw [this]; exact mul_ne_zero h1 h2
  have h5 : 1 - t ^ 4 ≠ 0 := by
    have : 1 - t ^ 4 = (1 - t ^ 2) * (1 + t ^ 2) := by ring
    rw [this]; exact mul_ne_zero h4 h3
  field_simp
  ring

-- the products u^i v^j w^k with k = 0 or 1 in degrees 0 .. 12 (degree 2i + 4j + 4k):
-- 1, 0, 1, 0, 3, 0, 3, 0, 5, 0, 5, 0, 7, the Molien counts
example : (List.range 13).map (fun d =>
    (((List.range 7).flatMap fun i => (List.range 4).flatMap fun j =>
      (List.range 2).map fun k => 2 * i + 4 * j + 4 * k).count d)) =
    [1, 0, 1, 0, 3, 0, 3, 0, 5, 0, 5, 0, 7] := by
  decide

-- mistake 2: u, v, w taken as free give 6 products of degree 8, not 5
example : ((List.range 5).flatMap fun i => (List.range 3).flatMap fun j =>
    (List.range 3).map fun k => 2 * i + 4 * j + 4 * k).count 8 = 6 := by
  decide

-- mistake 1: all monomials x^a y^b of degree 4 number 5, not 3
example : ((Finset.range 5 ×ˢ Finset.range 5).filter (fun p => p.1 + p.2 = 4)).card = 5 := by
  decide

-- mistake 4: over F_2 the swap group's size 2 is 0, so no average exists
example : ((2 : ℕ) : ZMod 2) = 0 := by decide

#print axioms linSubst_mul
#print axioms linSubst_one
#print axioms mem_invariantRing
#print axioms linSubst_reynolds
#print axioms reynolds_props
#print axioms mem_degSet
#print axioms homogeneousSubmodule_eq_supported
#print axioms homBasis_repr
#print axioms homBasis_apply
#print axioms linSubst_mem_hom
#print axioms homAct_apply
#print axioms homAct_mul
#print axioms homAct_one
#print axioms trace_homAct
#print axioms trace_homAct_conj
#print axioms linSubst_diagonal_monomial
#print axioms linSubst_map
#print axioms trace_homAct_map
#print axioms constantCoeff_molDet
#print axioms molDet_map
#print axioms molDet_conj
#print axioms molDet_diagonal
#print axioms geom_mul
#print axioms series_diagonal
#print axioms exists_diag
#print axioms series_mul_molDet_alg
#print axioms series_mul_molDet
#print axioms finrank_invariants_hom
#print axioms invariant_ring_finitely_generated
#print axioms reynolds_makes_and_keeps_invariants
#print axioms molien_formula
