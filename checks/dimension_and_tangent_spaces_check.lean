-- Dimension and tangent space: the dimension of an irreducible affine variety, the longest chain of prime ideals in its coordinate ring, equals the transcendence degree of its function field, and at every point the tangent space (the kernel of the Jacobian matrix of generators of the ideal) has dimension n minus the Jacobian's rank, never below that dimension; for the cone x² + y² = z² this is 2, 2 at (3, 4, 5) and 3 at the apex.
import Mathlib.RingTheory.KrullDimension.Basic
import Mathlib.RingTheory.AlgebraicIndependent.TranscendenceBasis
import Mathlib.RingTheory.Localization.FractionRing
import Mathlib.RingTheory.Ideal.Quotient.Basic
import Mathlib.Algebra.MvPolynomial.PDeriv
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.SetTheory.Cardinal.ENat
import Mathlib.Basic.Real.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.LinearCombination
import Mathlib.RingTheory.NoetherNormalization
import Mathlib.RingTheory.KrullDimension.Field
import Mathlib.RingTheory.KrullDimension.Polynomial
import Mathlib.RingTheory.Ideal.HasGoingUp
import Mathlib.RingTheory.IntegralClosure.GoingDown
import Mathlib.RingTheory.Ideal.KrullsHeightTheorem
import Mathlib.RingTheory.Polynomial.UniqueFactorization
import Mathlib.RingTheory.Polynomial.RationalRoot
import Mathlib.RingTheory.AlgebraicIndependent.Transcendental

open MvPolynomial

/-- The Jacobian matrix `J(P)` of equations `f₁, …, f_s` in `n` coordinates over `k`:
row `i`, column `j` is the partial derivative `∂fᵢ/∂x_j` evaluated at the point `P`. -/
noncomputable def jacobianAt {k : Type*} [Field k] {n s : ℕ}
    (f : Fin s → MvPolynomial (Fin n) k) (P : Fin n → k) : Matrix (Fin s) (Fin n) k :=
  Matrix.of fun i j => eval P (pderiv j (f i))

/-- The tangent space `T_P V`: every direction `v ∈ kⁿ` that the Jacobian matrix `J(P)`
sends to zero. -/
noncomputable def tangentSpace {k : Type*} [Field k] {n s : ℕ}
    (f : Fin s → MvPolynomial (Fin n) k) (P : Fin n → k) : Submodule k (Fin n → k) :=
  LinearMap.ker (jacobianAt f P).mulVecLin

/-- The cone `x² + y² - z²` over the reals, coordinates `x = X 0`, `y = X 1`, `z = X 2`. -/
noncomputable def cone : MvPolynomial (Fin 3) ℝ := X 0 ^ 2 + X 1 ^ 2 - X 2 ^ 2

theorem ringKrullDim_eq_of_isIntegral_of_injective {B A : Type*} [CommRing B] [CommRing A]
    [Algebra B A] [Algebra.IsIntegral B A] (hinj : Function.Injective (algebraMap B A)) :
    ringKrullDim A = ringKrullDim B := by
  apply le_antisymm
  · apply Order.krullDim_le_of_strictMono (PrimeSpectrum.comap (algebraMap B A))
    intro p q hpq
    have := Ideal.IsIntegral.under_lt_under (R := B) (A := A) (I := p.asIdeal) (J := q.asIdeal) hpq
    exact this
  · rw [ringKrullDim, Order.krullDim]
    refine iSup_le fun l => ?_
    obtain ⟨Q, -, hQ, hQl⟩ := Ideal.exists_ideal_over_prime_of_isIntegral (S := A)
      l.head.asIdeal ⊥ (by
        intro x hx
        simp only [Ideal.under, Ideal.mem_comap, Ideal.mem_bot] at hx
        rw [← map_zero (algebraMap B A)] at hx
        rw [hinj hx]; exact zero_mem _)
    have : Q.LiesOver l.head.asIdeal := ⟨hQl.symm⟩
    obtain ⟨L, hL, -, -⟩ := Ideal.exists_ltSeries_of_hasGoingUp l Q
    rw [← hL]
    exact le_iSup (fun p : LTSeries (PrimeSpectrum A) => (p.length : WithBot ℕ∞)) L

theorem height_ker_algHom_mvPolynomial {k : Type*} [Field k] :
    ∀ (s : ℕ) (φ : MvPolynomial (Fin s) k →ₐ[k] k), (RingHom.ker φ).height = s := by
  intro s
  induction s with
  | zero =>
    intro φ
    have : RingHom.ker φ = ⊥ := by
      ext p
      simp only [RingHom.mem_ker, Ideal.mem_bot]
      constructor
      · intro hp
        rw [MvPolynomial.eq_C_of_isEmpty p] at hp ⊢
        rw [MvPolynomial.algHom_C, Algebra.algebraMap_self, RingHom.id_apply] at hp
        rw [hp, map_zero]
      · rintro rfl; exact map_zero _
    rw [this, Ideal.height_bot]; rfl
  | succ s ih =>
    intro φ
    set e := MvPolynomial.finSuccEquiv k s
    set φ' : Polynomial (MvPolynomial (Fin s) k) →ₐ[k] k := φ.comp e.symm.toAlgHom
    set ψ : MvPolynomial (Fin s) k →ₐ[k] k :=
      φ'.comp (IsScalarTower.toAlgHom k (MvPolynomial (Fin s) k) (Polynomial (MvPolynomial (Fin s) k)))
    have hker : RingHom.ker φ = Ideal.comap (e : MvPolynomial (Fin (s+1)) k ≃+* _) (RingHom.ker φ') := by
      ext x
      simp [φ']
    have hsurj : Function.Surjective φ' := fun a => ⟨algebraMap k _ a, by
      simp only [φ', AlgHom.commutes, Algebra.algebraMap_self, RingHom.id_apply]⟩
    have hmax : (RingHom.ker φ').IsMaximal := RingHom.ker_isMaximal_of_surjective _ hsurj
    have hlo : (RingHom.ker φ').LiesOver (RingHom.ker ψ) := by
      constructor
      ext x
      simp [ψ, Ideal.under, Ideal.mem_comap]
    rw [hker, RingEquiv.height_comap, Polynomial.height_eq_height_add_one (RingHom.ker ψ), ih ψ]
    push_cast; rfl

theorem quotient_noether_data {k : Type*} [Field k] {n : ℕ}
    (I : Ideal (MvPolynomial (Fin n) k)) [I.IsPrime] :
    ∃ s, ∃ g : MvPolynomial (Fin s) k →ₐ[k] (MvPolynomial (Fin n) k ⧸ I),
      Function.Injective g ∧ g.IsIntegral ∧
      ringKrullDim (MvPolynomial (Fin n) k ⧸ I) = s := by
  obtain ⟨s, -, g, hinj, hint⟩ :=
    exists_integral_inj_algHom_of_quotient I (Ideal.IsPrime.ne_top ‹_›)
  refine ⟨s, g, hinj, hint, ?_⟩
  let _ : Algebra (MvPolynomial (Fin s) k) (MvPolynomial (Fin n) k ⧸ I) := g.toRingHom.toAlgebra
  have : Algebra.IsIntegral (MvPolynomial (Fin s) k) (MvPolynomial (Fin n) k ⧸ I) := ⟨hint⟩
  rw [ringKrullDim_eq_of_isIntegral_of_injective (B := MvPolynomial (Fin s) k) hinj,
    MvPolynomial.ringKrullDim_of_isNoetherianRing_of_finite, ringKrullDim_eq_zero_of_field]
  simp

theorem taylor_sub_mem_ker_sq {k : Type*} [Field k] {n : ℕ} (P : Fin n → k)
    (g : MvPolynomial (Fin n) k) :
    g - C (eval P g) - ∑ j, eval P (pderiv j g) • (X j - C (P j)) ∈
      RingHom.ker (eval P) ^ 2 := by
  classical
  have hy : ∀ j, (X j - C (P j) : MvPolynomial (Fin n) k) ∈ RingHom.ker (eval P) := by
    intro j; simp [RingHom.mem_ker]
  induction g using MvPolynomial.induction_on with
  | C a => simp
  | add p q hp hq =>
    have : (p + q) - C (eval P (p + q)) - ∑ j, eval P (pderiv j (p + q)) • (X j - C (P j)) =
        (p - C (eval P p) - ∑ j, eval P (pderiv j p) • (X j - C (P j))) +
        (q - C (eval P q) - ∑ j, eval P (pderiv j q) • (X j - C (P j))) := by
      simp only [map_add, add_smul, Finset.sum_add_distrib]; ring
    rw [this]; exact add_mem hp hq
  | mul_X p i hp =>
    have : p * X i - C (eval P (p * X i)) - ∑ j, eval P (pderiv j (p * X i)) • (X j - C (P j)) =
        (X i - C (P i)) * (p - C (eval P p)) +
        C (P i) * (p - C (eval P p) - ∑ j, eval P (pderiv j p) • (X j - C (P j))) := by
      simp only [Derivation.leibniz, pderiv_X, smul_eq_mul, map_add, map_mul, eval_X,
        add_smul, Finset.sum_add_distrib, Pi.single_apply]
      simp only [mul_smul]
      simp [MvPolynomial.smul_eq_C_mul]
      rw [← Finset.mul_sum]
      ring
    rw [this, pow_two]
    exact add_mem (Ideal.mul_mem_mul (hy i) (by simp [RingHom.mem_ker]))
      (Ideal.mul_mem_left _ _ (by rw [← pow_two]; exact hp))

theorem finrank_tangentSpace_eq {k : Type*} [Field k] {n s : ℕ}
    (f : Fin s → MvPolynomial (Fin n) k) (P : Fin n → k) :
    Module.finrank k (tangentSpace f P) = n - (jacobianAt f P).rank := by
  have := LinearMap.finrank_range_add_finrank_ker (jacobianAt f P).mulVecLin
  rw [Module.finrank_fin_fun] at this
  unfold tangentSpace Matrix.rank
  omega

#print axioms ringKrullDim_eq_of_isIntegral_of_injective
#print axioms height_ker_algHom_mvPolynomial
#print axioms quotient_noether_data
#print axioms taylor_sub_mem_ker_sq
#print axioms finrank_tangentSpace_eq

/-- **The two counts of dimension agree.** Let `V` be an irreducible affine variety over a
field `k`, so its vanishing ideal `I = I(V)` in `k[x₁, …, xₙ]` is prime and its coordinate
ring is `k[V] = k[x₁, …, xₙ] / I`. Then the length of the longest chain of prime ideals
`𝔭₀ ⊊ 𝔭₁ ⊊ … ⊊ 𝔭_d` in `k[V]` (Mathlib's `ringKrullDim`) equals the transcendence degree
over `k` of the function field `k(V)`, the fraction field of `k[V]`: the largest number of
functions on `V` that obey no polynomial equation together. -/
theorem ringKrullDim_eq_trdeg_functionField {k : Type*} [Field k] {n : ℕ}
    (I : Ideal (MvPolynomial (Fin n) k)) [I.IsPrime] :
    ringKrullDim (MvPolynomial (Fin n) k ⧸ I) =
      ((Cardinal.toENat (Algebra.trdeg k (FractionRing (MvPolynomial (Fin n) k ⧸ I))) : ℕ∞) :
        WithBot ℕ∞) := by
  obtain ⟨s, g, hinj, hint, hdim⟩ := quotient_noether_data I
  rw [hdim]
  set A := MvPolynomial (Fin n) k ⧸ I
  set B := MvPolynomial (Fin s) k
  let _ : Algebra B A := g.toRingHom.toAlgebra
  have : Algebra.IsIntegral B A := ⟨hint⟩
  have : IsScalarTower k B A := IsScalarTower.of_algebraMap_eq (fun x => (g.commutes x).symm)
  have : FaithfulSMul B A := (faithfulSMul_iff_algebraMap_injective B A).mpr hinj
  have : FaithfulSMul A (FractionRing A) :=
    (faithfulSMul_iff_algebraMap_injective A (FractionRing A)).mpr (IsFractionRing.injective _ _)
  have h1 : Algebra.trdeg k A + Algebra.trdeg A (FractionRing A) =
      Algebra.trdeg k (FractionRing A) := trdeg_add_eq k A (A := FractionRing A)
  have h2 : Algebra.trdeg k B + Algebra.trdeg B A = Algebra.trdeg k A :=
    trdeg_add_eq k B (A := A)
  have : Algebra.IsAlgebraic A (FractionRing A) := IsLocalization.isAlgebraic _ (nonZeroDivisors A)
  have : Algebra.IsAlgebraic B A := Algebra.IsIntegral.isAlgebraic
  rw [trdeg_eq_zero (R := A) (A := FractionRing A), add_zero] at h1
  rw [trdeg_eq_zero (R := B) (A := A), add_zero] at h2
  rw [← h1, ← h2, MvPolynomial.trdeg_of_isDomain]
  simp

/-- **The tangent space is never smaller than the dimension.** Let `V` be irreducible, with
prime vanishing ideal `I`, and let the equations `f₁, …, f_s` generate `I`. At every point
`P` of `V` (every `fᵢ` is zero at `P`), the tangent space `T_P V = ker J(P)` has dimension
`n - rank J(P)`, and that number is at least `dim V`. -/
theorem dim_le_finrank_tangentSpace {k : Type*} [Field k] {n s : ℕ}
    (I : Ideal (MvPolynomial (Fin n) k)) [I.IsPrime]
    (f : Fin s → MvPolynomial (Fin n) k) (hf : Ideal.span (Set.range f) = I)
    (P : Fin n → k) (hP : ∀ i, eval P (f i) = 0) :
    Module.finrank k (tangentSpace f P) = n - (jacobianAt f P).rank ∧
      ringKrullDim (MvPolynomial (Fin n) k ⧸ I) ≤ (Module.finrank k (tangentSpace f P) : WithBot ℕ∞) := by
  classical
  refine ⟨finrank_tangentSpace_eq f P, ?_⟩
  rw [finrank_tangentSpace_eq f P]
  -- the maximal ideal of the point `P` in the coordinate ring
  have hIM : I ≤ RingHom.ker (aeval P) := by
    rw [← hf, Ideal.span_le]
    rintro _ ⟨i, rfl⟩
    simpa [RingHom.mem_ker, coe_aeval_eq_eval] using hP i
  let ψ : (MvPolynomial (Fin n) k ⧸ I) →ₐ[k] k := Ideal.Quotient.liftₐ I (aeval P) hIM
  have hψ : ∀ g, ψ (Ideal.Quotient.mk I g) = eval P g := fun g => by
    change (aeval P) g = eval P g
    rfl
  set m := RingHom.ker ψ with hm
  have hψsurj : Function.Surjective ψ := fun a => ⟨Ideal.Quotient.mk I (C a), by simp [hψ]⟩
  have hmmax : m.IsMaximal := RingHom.ker_isMaximal_of_surjective _ hψsurj
  -- Step A: `dim k[V] ≤ ht m` (Noether normalization and going down)
  have hA : ringKrullDim (MvPolynomial (Fin n) k ⧸ I) ≤ (m.height : WithBot ℕ∞) := by
    obtain ⟨s, g, hinj, hint, hdim⟩ := quotient_noether_data I
    rw [hdim]
    let _ : Algebra (MvPolynomial (Fin s) k) (MvPolynomial (Fin n) k ⧸ I) :=
      g.toRingHom.toAlgebra
    have : Algebra.IsIntegral (MvPolynomial (Fin s) k) (MvPolynomial (Fin n) k ⧸ I) := ⟨hint⟩
    have : FaithfulSMul (MvPolynomial (Fin s) k) (MvPolynomial (Fin n) k ⧸ I) :=
      (faithfulSMul_iff_algebraMap_injective _ _).mpr hinj
    have : m.LiesOver (RingHom.ker (ψ.comp g)) := by
      constructor
      ext x
      simp [Ideal.under, m, RingHom.algebraMap_toAlgebra]
    have : (RingHom.ker (ψ.comp g)).IsPrime := RingHom.ker_isPrime _
    have h := Ideal.height_eq_height_add_of_liesOver_of_hasGoingDown (RingHom.ker (ψ.comp g)) m
    rw [height_ker_algHom_mvPolynomial] at h
    rw [h]
    exact_mod_cast le_self_add
  -- Step B: `ht m ≤ n - rank J(P)` (Nakayama's lemma and Krull's height theorem)
  set r := (jacobianAt f P).rank
  let D : MvPolynomial (Fin n) k → (Fin n → k) := fun g j => eval P (pderiv j g)
  let ℓ : (Fin n → k) →ₗ[k] MvPolynomial (Fin n) k :=
    ∑ j, (LinearMap.proj j : (Fin n → k) →ₗ[k] k).smulRight (X j - C (P j))
  have hℓ : ∀ v, ℓ v = ∑ j, v j • (X j - C (P j)) := fun v => by simp [ℓ]
  have hℓM : ∀ v, ℓ v ∈ RingHom.ker (eval P) := fun v => by
    rw [hℓ]
    exact Ideal.sum_mem _ fun j _ =>
      Submodule.smul_of_tower_mem _ _ (by simp [RingHom.mem_ker])
  have htaylor : ∀ g, g - C (eval P g) - ℓ (D g) ∈ RingHom.ker (eval P) ^ 2 := fun g => by
    rw [hℓ]; exact taylor_sub_mem_ker_sq P g
  let W : Submodule k (Fin n → k) := Submodule.span k (Set.range fun i => D (f i))
  have hW : Module.finrank k W = r := by
    have : W = LinearMap.range (jacobianAt f P).transpose.mulVecLin := by
      rw [Matrix.range_mulVecLin]; rfl
    rw [this]; exact Matrix.rank_transpose (jacobianAt f P)
  obtain ⟨U, hU⟩ := Submodule.exists_isCompl W
  have hUdim : Module.finrank k U = n - r := by
    have := Submodule.finrank_add_eq_of_isCompl hU
    rw [Module.finrank_fin_fun, hW] at this; omega
  let b := Module.finBasis k U
  let gens : Fin (Module.finrank k U) → MvPolynomial (Fin n) k ⧸ I :=
    fun t => Ideal.Quotient.mk I (ℓ (b t))
  let J : Ideal (MvPolynomial (Fin n) k ⧸ I) := Ideal.span (Set.range gens)
  have hmapM : ∀ x ∈ RingHom.ker (eval P), Ideal.Quotient.mk I x ∈ m := fun x hx => by
    simp only [m, RingHom.mem_ker, hψ]; exact hx
  have hJm : J ≤ m := by
    rw [Ideal.span_le]; rintro _ ⟨t, rfl⟩
    exact hmapM _ (hℓM _)
  have hmapM2 : ∀ x ∈ RingHom.ker (eval P) ^ 2, Ideal.Quotient.mk I x ∈ m ^ 2 := fun x hx => by
    have : Ideal.map (Ideal.Quotient.mk I) (RingHom.ker (eval P) ^ 2) ≤ m ^ 2 := by
      rw [Ideal.map_pow]; exact Ideal.pow_right_mono (Ideal.map_le_iff_le_comap.mpr hmapM) 2
    exact this (Ideal.mem_map_of_mem _ hx)
  have hsq : ∀ a ∈ m, a ∈ J ⊔ m ^ 2 := by
    intro a ha
    obtain ⟨g, rfl⟩ := Ideal.Quotient.mk_surjective a
    have hg : eval P g = 0 := by rw [← hψ]; exact ha
    have hDg : D g ∈ W ⊔ U := by rw [hU.sup_eq_top]; exact Submodule.mem_top
    obtain ⟨w, hw, u, hu, hwu⟩ := Submodule.mem_sup.mp hDg
    obtain ⟨c, hc⟩ := (Submodule.mem_span_range_iff_exists_fun k).mp hw
    have key : g = (g - C (eval P g) - ℓ (D g)) + ℓ u +
        (∑ i, c i • (ℓ (D (f i)) - f i)) + ∑ i, c i • f i := by
      rw [← hwu, map_add, ← hc, map_sum, hg, map_zero]
      simp only [map_smul, smul_sub, Finset.sum_sub_distrib]
      abel
    rw [key, map_add, map_add, map_add]
    refine add_mem (add_mem (add_mem ?_ ?_) ?_) ?_
    · exact Ideal.mem_sup_right (hmapM2 _ (htaylor g))
    · apply Ideal.mem_sup_left
      have hu' : u = ∑ t, (b.repr ⟨u, hu⟩ t) • (b t : Fin n → k) := by
        have := congrArg Subtype.val (b.sum_repr ⟨u, hu⟩)
        simp only [Submodule.coe_sum, Submodule.coe_smul] at this
        exact this.symm
      rw [hu', map_sum, map_sum]
      refine Ideal.sum_mem _ fun t _ => ?_
      rw [map_smul, MvPolynomial.smul_eq_C_mul, map_mul]
      exact Ideal.mul_mem_left _ _ (Ideal.subset_span ⟨t, rfl⟩)
    · apply Ideal.mem_sup_right
      rw [map_sum]
      refine Ideal.sum_mem _ fun i _ => ?_
      rw [MvPolynomial.smul_eq_C_mul, map_mul]
      refine Ideal.mul_mem_left _ _ (hmapM2 _ ?_)
      have := neg_mem (htaylor (f i))
      rwa [hP i, map_zero, sub_zero, neg_sub] at this
    · have : Ideal.Quotient.mk I (∑ i, c i • f i) = 0 := by
        rw [Ideal.Quotient.eq_zero_iff_mem, ← hf]
        exact Ideal.sum_mem _ fun i _ =>
          Submodule.smul_of_tower_mem _ _ (Ideal.subset_span ⟨i, rfl⟩)
      rw [this]; exact zero_mem _
  have hfg : (m : Submodule (MvPolynomial (Fin n) k ⧸ I) (MvPolynomial (Fin n) k ⧸ I)).FG :=
    IsNoetherian.noetherian m
  obtain ⟨r0, hr0, hr0N⟩ := Submodule.exists_sub_one_mem_and_smul_eq_zero_of_fg_of_le_smul m
    (Submodule.map J.mkQ m) (Submodule.FG.map _ hfg) (by
      intro y hy
      obtain ⟨x, hx, rfl⟩ := Submodule.mem_map.mp hy
      obtain ⟨j, hj, z, hz, rfl⟩ := Submodule.mem_sup.mp (hsq x hx)
      rw [map_add, Submodule.mkQ_apply J j, (Submodule.Quotient.mk_eq_zero J).mpr hj, zero_add,
        ← Submodule.map_smul'']
      rw [pow_two] at hz
      exact Submodule.mem_map_of_mem hz)
  have hrx : ∀ x ∈ m, r0 * x ∈ J := fun x hx => by
    have := hr0N _ (Submodule.mem_map_of_mem (f := J.mkQ) hx)
    rw [← map_smul, Submodule.mkQ_apply] at this
    exact (Submodule.Quotient.mk_eq_zero J).mp this
  have hmin : m ∈ J.minimalPrimes := by
    refine ⟨⟨hmmax.isPrime, hJm⟩, fun p ⟨hp, hJp⟩ hpm => ?_⟩
    intro x hx
    rcases hp.mem_or_mem (hJp (hrx x hx)) with h | h
    · exfalso
      have h1 : (1 : MvPolynomial (Fin n) k ⧸ I) ∈ m := by
        have := sub_mem (hpm h) hr0; simpa using this
      exact hmmax.ne_top ((Ideal.eq_top_iff_one _).mpr h1)
    · exact h
  have hht : m.height ≤ (Module.finrank k U : ℕ∞) := by
    have := Ideal.height_le_card_of_mem_minimalPrimes_span_finset (s := Finset.univ.image gens)
      (by rw [Finset.coe_image, Finset.coe_univ, Set.image_univ]; exact hmin)
    refine this.trans ?_
    exact_mod_cast (Finset.card_image_le.trans (by simp))
  calc ringKrullDim (MvPolynomial (Fin n) k ⧸ I) ≤ (m.height : WithBot ℕ∞) := hA
    _ ≤ ((Module.finrank k U : ℕ∞) : WithBot ℕ∞) := WithBot.coe_le_coe.mpr hht
    _ = _ := by rw [hUdim]; rfl

/-- **The cone's numbers.** Over the reals, the cone `x² + y² = z²` is two-dimensional (its
coordinate ring `ℝ[x, y, z] / ⟨x² + y² - z²⟩` has Krull dimension 2); its tangent space at
`(3, 4, 5)` has dimension 2 (the plane `3x + 4y - 5z = 0`), and at the apex `(0, 0, 0)`,
where the Jacobian matrix is zero, it has dimension 3: all of space. -/
theorem cone_dim_two_tangent_two_and_apex_three :
    ringKrullDim (MvPolynomial (Fin 3) ℝ ⧸ Ideal.span {cone}) = 2 ∧
      Module.finrank ℝ (tangentSpace ![cone] ![3, 4, 5]) = 2 ∧
      Module.finrank ℝ (tangentSpace ![cone] ![0, 0, 0]) = 3 := by
  have hJ : ∀ Q : Fin 3 → ℝ, jacobianAt ![cone] Q = !![2 * Q 0, 2 * Q 1, -(2 * Q 2)] := by
    intro Q
    ext i j
    fin_cases i
    fin_cases j <;> simp [jacobianAt, cone, Derivation.leibniz_pow, pderiv_X, Pi.single_apply]
  -- the Krull dimension of the coordinate ring
  have hcone0 : cone ≠ 0 := by
    intro h
    have := congrArg (eval ![1, 0, 0]) h
    simp [cone] at this
  have hdimR : ringKrullDim (MvPolynomial (Fin 3) ℝ) = 3 := by
    rw [MvPolynomial.ringKrullDim_of_isNoetherianRing_of_finite, ringKrullDim_eq_zero_of_field]
    simp
  have hup : ringKrullDim (MvPolynomial (Fin 3) ℝ ⧸ Ideal.span {cone}) + 1 ≤ 3 := by
    rw [← hdimR]
    exact ringKrullDim_quotient_succ_le_of_nonZeroDivisor (mem_nonZeroDivisors_of_ne_zero hcone0)
  have hlow : (3 : WithBot ℕ∞) ≤ ringKrullDim (MvPolynomial (Fin 3) ℝ ⧸ Ideal.span {cone}) + 1 := by
    have hmem : cone ∈ RingHom.ker (aeval (R := ℝ) (![0, 0, 0] : Fin 3 → ℝ)) := by
      simp [RingHom.mem_ker, cone]
    have : (RingHom.ker (aeval (R := ℝ) (![0, 0, 0] : Fin 3 → ℝ))).IsPrime := RingHom.ker_isPrime _
    have := Ideal.height_le_ringKrullDim_quotient_add_one hmem
    rw [height_ker_algHom_mvPolynomial] at this
    exact_mod_cast this
  have hd : ringKrullDim (MvPolynomial (Fin 3) ℝ ⧸ Ideal.span {cone}) = 2 := by
    have h3 := le_antisymm hup hlow
    generalize ringKrullDim (MvPolynomial (Fin 3) ℝ ⧸ Ideal.span {cone}) = d at h3 ⊢
    induction d using WithBot.recBotCoe with
    | bot => simp at h3
    | coe e =>
      induction e using ENat.recTopCoe with
      | top =>
        exfalso
        have h4 : ((⊤ : ℕ∞) : WithBot ℕ∞) = ((3 : ℕ∞) : WithBot ℕ∞) := h3
        exact ENat.top_ne_ofNat 3 (WithBot.coe_injective h4)
      | coe a =>
        have h4 : (((a + 1 : ℕ) : ℕ∞) : WithBot ℕ∞) = (((3 : ℕ) : ℕ∞) : WithBot ℕ∞) := h3
        have h5 : a + 1 = 3 := by exact_mod_cast WithBot.coe_injective h4
        have : a = 2 := by omega
        subst this; rfl
  refine ⟨hd, ?_, ?_⟩
  · rw [finrank_tangentSpace_eq]
    have hrank : (jacobianAt ![cone] ![3, 4, 5]).rank = 1 := by
      apply le_antisymm (Matrix.rank_le_height _)
      rw [Nat.one_le_iff_ne_zero]
      intro h
      unfold Matrix.rank at h
      rw [Submodule.finrank_eq_zero] at h
      have hv := LinearMap.mem_range_self (jacobianAt ![cone] ![3, 4, 5]).mulVecLin (Pi.single 0 1)
      rw [h, Submodule.mem_bot] at hv
      have := congrFun hv 0
      rw [hJ] at this
      simp [Matrix.mulVec, dotProduct, Fin.sum_univ_three] at this
    rw [hrank]
  · rw [finrank_tangentSpace_eq]
    have hzero : jacobianAt ![cone] ![0, 0, 0] = 0 := by
      rw [hJ]; ext i j; fin_cases i; fin_cases j <;> simp
    rw [hzero, Matrix.rank_zero]

-- The line through the apex and (3, 4, 5) lies on the cone:
-- 9f = (g₁ - 8x) g₁ + (10x - g₂) g₂ with g₁ = 4x - 3y, g₂ = 5x - 3z.
example (x y z : ℤ) :
    9 * (x ^ 2 + y ^ 2 - z ^ 2) =
      ((4 * x - 3 * y) - 8 * x) * (4 * x - 3 * y) + (10 * x - (5 * x - 3 * z)) * (5 * x - 3 * z) := by
  ring

-- Witnesses for the strict steps of the chain: (4, 3, 5) is on the cone with g₁ = 7;
-- (6, 8, 10) is on the line (g₁ = g₂ = 0) with x - 3 = 3.
example : (4 : ℤ) ^ 2 + 3 ^ 2 - 5 ^ 2 = 0 ∧ (4 * 4 - 3 * 3 : ℤ) = 7 := by norm_num
example : (4 * 6 - 3 * 8 : ℤ) = 0 ∧ (5 * 6 - 3 * 10 : ℤ) = 0 ∧ (6 - 3 : ℤ) = 3 := by norm_num

-- (3, 4, 5) and (-3, 4, 5) are both on the cone: x takes two values above one (y, z).
example : (3 : ℤ) ^ 2 + 4 ^ 2 - 5 ^ 2 = 0 ∧ (-3 : ℤ) ^ 2 + 4 ^ 2 - 5 ^ 2 = 0 := by norm_num

-- Points of the cone over 𝔽_p: 9, 25, 49, 121, 169 = p² for p = 3, 5, 7, 11, 13.
example : (Finset.univ.filter (fun v : ZMod 3 × ZMod 3 × ZMod 3 =>
    v.1 ^ 2 + v.2.1 ^ 2 - v.2.2 ^ 2 = 0)).card = 9 := by decide
example : (Finset.univ.filter (fun v : ZMod 5 × ZMod 5 × ZMod 5 =>
    v.1 ^ 2 + v.2.1 ^ 2 - v.2.2 ^ 2 = 0)).card = 25 := by decide
example : (Finset.univ.filter (fun v : ZMod 7 × ZMod 7 × ZMod 7 =>
    v.1 ^ 2 + v.2.1 ^ 2 - v.2.2 ^ 2 = 0)).card = 49 := by decide
example : (Finset.univ.filter (fun v : ZMod 11 × ZMod 11 × ZMod 11 =>
    v.1 ^ 2 + v.2.1 ^ 2 - v.2.2 ^ 2 = 0)).card = 121 := by decide +kernel
example : (Finset.univ.filter (fun v : ZMod 13 × ZMod 13 × ZMod 13 =>
    v.1 ^ 2 + v.2.1 ^ 2 - v.2.2 ^ 2 = 0)).card = 169 := by decide +kernel

-- The circle x² + y² = 25 cut by z = 5 has 8 points over 𝔽_7.
example : (Finset.univ.filter (fun v : ZMod 7 × ZMod 7 =>
    v.1 ^ 2 + v.2 ^ 2 = 25)).card = 8 := by decide

-- The Jacobian row at (3, 4, 5) is (2·3, 2·4, -2·5) = (6, 8, -10); the row of z·f there is
-- 5 times it, (30, 40, -50), so f and z·f together still have rank 1.
example : ((2 * 3, 2 * 4, -2 * 5) : ℤ × ℤ × ℤ) = (6, 8, -10) := by norm_num
example : ((5 * 6, 5 * 8, 5 * -10) : ℤ × ℤ × ℤ) = (30, 40, -50) := by norm_num

-- First-order directions over 𝔽_7: 49 = 7² at (3, 4, 5), where 6a + 8b - 10c = 0,
-- and all 343 = 7³ at the apex, where the Jacobian row is zero.
example : (Finset.univ.filter (fun v : ZMod 7 × ZMod 7 × ZMod 7 =>
    6 * v.1 + 8 * v.2.1 - 10 * v.2.2 = 0)).card = 49 := by decide
example : (Finset.univ.filter (fun v : ZMod 7 × ZMod 7 × ZMod 7 =>
    0 * v.1 + 0 * v.2.1 - 0 * v.2.2 = 0)).card = 343 := by
  simp [Finset.filter_true_of_mem, Finset.card_univ, Fintype.card_prod, ZMod.card]

-- Over 𝔽_11 the exponents stay the tangent dimensions: 121 = 11² directions at (3, 4, 5).
example : (Finset.univ.filter (fun v : ZMod 11 × ZMod 11 × ZMod 11 =>
    6 * v.1 + 8 * v.2.1 - 10 * v.2.2 = 0)).card = 121 := by decide +kernel

-- The exact secant identity: for every cone point Q = (a, b, c),
-- ∇f(3, 4, 5) · (Q - P) = -f(Q - P).
example (a b c : ℤ) (h : a ^ 2 + b ^ 2 = c ^ 2) :
    6 * (a - 3) + 8 * (b - 4) - 10 * (c - 5) =
      -((a - 3) ^ 2 + (b - 4) ^ 2 - (c - 5) ^ 2) := by
  linear_combination h

-- The rulings through (3, 4, 5), (4, 3, 5), (-3, 4, 5) have determinant -30, not 0.
example : Matrix.det !![(3 : ℤ), 4, 5; 4, 3, 5; -3, 4, 5] = -30 := by
  rw [Matrix.det_fin_three]; norm_num

#print axioms ringKrullDim_eq_trdeg_functionField
#print axioms dim_le_finrank_tangentSpace
#print axioms cone_dim_two_tangent_two_and_apex_three
