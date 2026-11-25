-- Local fields: the different of a number field whose integers are Z[α] is the ideal (f'(α)), its norm is the size of the discriminant, and a prime's exponent in it is e - 1 when p does not divide e and at least e when it does.
import Mathlib.NumberTheory.NumberField.Discriminant.Different
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.NumberTheory.Zsqrtd.GaussianInt
import Mathlib.RingTheory.Etale.Field
import Mathlib.NumberTheory.RamificationInertia.Basic

open NumberField Polynomial

/-- Helper: over a field `F`, if a finite algebra `R` maps onto a finite separable field
extension `k` with nilpotent kernel, the trace on `R` is `n` times the trace on `k`, where
`[R : F] = n [k : F]`. -/
theorem trace_eq_mul_of_nilpotent_ker {F k R : Type*} [Field F] [Field k] [CommRing R]
    [Algebra F k] [Algebra F R] [Module.Finite F R] [Module.Finite F k] [Algebra.IsSeparable F k]
    (g : R →ₐ[F] k) (hg : Function.Surjective g) (hnil : IsNilpotent (RingHom.ker g))
    (n : ℕ) (hn : Module.finrank F R = n * Module.finrank F k) (y : R) :
    Algebra.trace F R y = n * Algebra.trace F k (g y) := by
  have : Algebra.FormallyEtale F k := Algebra.FormallyEtale.of_isSeparable F k
  let s : k →ₐ[F] R := Algebra.FormallySmooth.liftOfSurjective (AlgHom.id F k) g hg hnil
  have hs : ∀ c, g (s c) = c := fun c ↦ Algebra.FormallySmooth.liftOfSurjective_apply _ g hg hnil c
  let : Algebra k R := s.toRingHom.toAlgebra
  have : IsScalarTower F k R := IsScalarTower.of_algebraMap_eq fun c ↦ (s.commutes c).symm
  have : Module.Finite k R := Module.Finite.of_restrictScalars_finite F k R
  have hk : 0 < Module.finrank F k := Module.finrank_pos
  have hfr : Module.finrank k R = n := by
    have := Module.finrank_mul_finrank F k R
    rw [hn, mul_comm n] at this
    exact Nat.eq_of_mul_eq_mul_left hk this
  have hnilp : IsNilpotent (y - s (g y)) := by
    obtain ⟨m, hm⟩ := hnil
    refine ⟨m, ?_⟩
    have hmem : y - s (g y) ∈ RingHom.ker g := by
      simp [RingHom.mem_ker, hs]
    have := Ideal.pow_mem_pow hmem m
    rw [hm] at this
    simpa using this
  have h0 : Algebra.trace k R (y - s (g y)) = 0 := by
    rw [← isNilpotent_iff_eq_zero, Algebra.trace_apply]
    apply LinearMap.isNilpotent_trace_of_isNilpotent
    exact hnilp.map (Algebra.lmul k R)
  have h1 : Algebra.trace k R y = n • g y := by
    have : Algebra.trace k R y = Algebra.trace k R (algebraMap k R (g y))
        + Algebra.trace k R (y - s (g y)) := by
      rw [← map_add]; congr 1; simp [RingHom.algebraMap_toAlgebra]
    rw [this, h0, add_zero, Algebra.trace_algebraMap, hfr]
  rw [← Algebra.trace_trace (S := k), h1, map_nsmul, nsmul_eq_mul]

#print axioms trace_eq_mul_of_nilpotent_ker

/-- The different is the derivative: if the ring of integers of a number field `K` is
`Z[α]` (that is, `α` generates `𝓞 K` as a ring over `Z`) and `f` is the polynomial of `α`,
then the different of `K` is the principal ideal `(f'(α))`. -/
theorem differentIdeal_eq_span_derivative_of_adjoin_eq_top
    {K : Type*} [Field K] [NumberField K] (α : 𝓞 K)
    (hα : Algebra.adjoin ℤ {α} = ⊤) :
    differentIdeal ℤ (𝓞 K) = Ideal.span {aeval α (derivative (minpoly ℤ α))} := by
  have hx : Algebra.adjoin ℚ {algebraMap (𝓞 K) K α} = ⊤ := by
    have h1 : ∀ a : 𝓞 K, algebraMap (𝓞 K) K a ∈ Algebra.adjoin ℚ {algebraMap (𝓞 K) K α} := by
      intro a
      have ha : a ∈ Algebra.adjoin ℤ {α} := hα ▸ Algebra.mem_top
      induction ha using Algebra.adjoin_induction with
      | mem x hx =>
        rw [Set.mem_singleton_iff.mp hx]
        exact Algebra.subset_adjoin rfl
      | algebraMap r => simpa using Subalgebra.intCast_mem _ r
      | add x y _ _ hx hy => simpa using add_mem hx hy
      | mul x y _ _ hx hy => simpa using mul_mem hx hy
    refine eq_top_iff.mpr fun y _ ↦ ?_
    obtain ⟨a, b, -, rfl⟩ := IsFractionRing.div_surjective (A := 𝓞 K) y
    rw [div_eq_mul_inv]
    refine mul_mem (h1 a) ?_
    exact (Algebra.adjoin ℚ {algebraMap (𝓞 K) K α}).inv_mem_of_algebraic (x := ⟨_, h1 b⟩)
      (Algebra.IsAlgebraic.isAlgebraic _)
  rw [← conductor_mul_differentIdeal ℤ ℚ K α hx, conductor_eq_top_of_adjoin_eq_top hα,
    Ideal.top_mul]

/-- The norm of the different is the size of the discriminant: for every number field `K`,
the number of remainders modulo the different `𝔇_K` is `|d_K|`. -/
theorem absNorm_differentIdeal_eq_natAbs_discr
    (K : Type*) [Field K] [NumberField K] :
    (differentIdeal ℤ (𝓞 K)).absNorm = (discr K).natAbs := by
  exact absNorm_differentIdeal K (𝓞 K)

/-- Tame and wild: let `P` be a nonzero prime ideal of `𝓞 K` dividing the prime `p`, with
ramification index `e`. If `p` does not divide `e`, `P` divides the different exactly
`e - 1` times; if `p` divides `e`, `P` divides it at least `e` times. -/
theorem differentIdeal_exponent_tame_wild
    {K : Type*} [Field K] [NumberField K] {p : ℕ} (hp : p.Prime)
    (P : Ideal (𝓞 K)) [P.IsPrime] (hP : P ≠ ⊥) (hpP : (p : 𝓞 K) ∈ P) :
    (¬ p ∣ Ideal.ramificationIdx' (Ideal.span {(p : ℤ)}) P →
        P ^ (Ideal.ramificationIdx' (Ideal.span {(p : ℤ)}) P - 1) ∣ differentIdeal ℤ (𝓞 K) ∧
        ¬ P ^ Ideal.ramificationIdx' (Ideal.span {(p : ℤ)}) P ∣ differentIdeal ℤ (𝓞 K)) ∧
    (p ∣ Ideal.ramificationIdx' (Ideal.span {(p : ℤ)}) P →
        P ^ Ideal.ramificationIdx' (Ideal.span {(p : ℤ)}) P ∣ differentIdeal ℤ (𝓞 K)) := by
  classical
  set p0 : Ideal ℤ := Ideal.span {(p : ℤ)} with hp0def
  have hpZ : Prime (p : ℤ) := Nat.prime_iff_prime_int.mp hp
  have hp0max : p0.IsMaximal := PrincipalIdealRing.isMaximal_of_irreducible hpZ.irreducible
  have hp0ne : p0 ≠ ⊥ := by simp [p0, hp.ne_zero]
  have hmapne : p0.map (algebraMap ℤ (𝓞 K)) ≠ ⊥ :=
    (Ideal.map_eq_bot_iff_of_injective (FaithfulSMul.algebraMap_injective ℤ (𝓞 K))).not.mpr hp0ne
  have hle : p0.map (algebraMap ℤ (𝓞 K)) ≤ P := by
    rw [Ideal.map_span, Ideal.span_le]; simpa using hpP
  set e := Ideal.ramificationIdx' p0 P with he_def
  have he : e ≠ 0 := Ideal.IsDedekindDomain.ramificationIdx'_ne_zero hmapne inferInstance hle
  have : P.IsMaximal := Ideal.IsPrime.isMaximal inferInstance hP
  obtain ⟨Q, hPQ, hQ⟩ := Ideal.eq_prime_pow_mul_coprime hmapne P
  rw [← Ideal.IsDedekindDomain.ramificationIdx'_eq_normalizedFactors_count hmapne inferInstance hP]
    at hQ
  rw [← he_def] at hQ
  have hcop : IsCoprime (P ^ e) Q := (Ideal.isCoprime_iff_sup_eq.mpr hPQ).pow_left
  let : Field (ℤ ⧸ p0) := Ideal.Quotient.field p0
  let : Field (𝓞 K ⧸ P) := Ideal.Quotient.field P
  have : NeZero e := ⟨he⟩
  let : Algebra (ℤ ⧸ p0) (𝓞 K ⧸ P) := Ideal.Quotient.algebraQuotientOfRamificationIdxNeZero p0 P
  have : IsScalarTower ℤ (ℤ ⧸ p0) (𝓞 K ⧸ P) := .of_algebraMap_eq' rfl
  have : Module.Finite (ℤ ⧸ p0) (𝓞 K ⧸ P) := Module.Finite.of_restrictScalars_finite ℤ _ _
  have : IsScalarTower ℤ (ℤ ⧸ p0) (𝓞 K ⧸ P ^ e) := .of_algebraMap_eq' rfl
  have : Module.Finite (ℤ ⧸ p0) (𝓞 K ⧸ P ^ e) := Module.Finite.of_restrictScalars_finite ℤ _ _
  have : NeZero p := ⟨hp.ne_zero⟩
  have : Finite (ℤ ⧸ p0) := Finite.of_equiv _ (Int.quotientSpanNatEquivZMod p).symm.toEquiv
  have : Algebra.IsSeparable (ℤ ⧸ p0) (𝓞 K ⧸ P) := inferInstance
  -- the trace on `𝓞 K ⧸ P ^ e` is `e` times the trace on the residue field
  have htr : ∀ x : 𝓞 K, Algebra.trace (ℤ ⧸ p0) (𝓞 K ⧸ P ^ e) (Ideal.Quotient.mk _ x) =
      (e : ℤ ⧸ p0) * Algebra.trace (ℤ ⧸ p0) (𝓞 K ⧸ P) (Ideal.Quotient.mk P x) := by
    intro x
    let g : (𝓞 K ⧸ P ^ e) →ₐ[ℤ ⧸ p0] (𝓞 K ⧸ P) :=
      { Ideal.Quotient.factor (Ideal.pow_le_self he) with
        commutes' := fun r ↦ by
          obtain ⟨r, rfl⟩ := Ideal.Quotient.mk_surjective r
          rfl }
    have hg : Function.Surjective g := Ideal.Quotient.factor_surjective (Ideal.pow_le_self he)
    have hnil : IsNilpotent (RingHom.ker g) := by
      refine ⟨e, ?_⟩
      have : RingHom.ker g = RingHom.ker (Ideal.Quotient.factor (Ideal.pow_le_self he)) := rfl
      rw [this, Ideal.Quotient.factor_ker, ← Ideal.map_pow, Ideal.map_quotient_self,
        Ideal.zero_eq_bot]
    exact trace_eq_mul_of_nilpotent_ker g hg hnil e
      (Ideal.finrank_prime_pow_ramificationIdx p0 P hP he) _
  -- the trace of an element of `Q`, reduced mod `p`
  have key : ∀ x ∈ Q, Ideal.Quotient.mk p0 (Algebra.intTrace ℤ (𝓞 K) x) =
      (e : ℤ ⧸ p0) * Algebra.trace (ℤ ⧸ p0) (𝓞 K ⧸ P) (Ideal.Quotient.mk P x) := by
    intro x hx
    let : Algebra (ℤ ⧸ p0) (𝓞 K ⧸ Q) := Ideal.Quotient.algebraQuotientOfLEComap (by
      rw [← Ideal.map_le_iff_le_comap, hQ]; exact Ideal.mul_le_right)
    have : IsScalarTower ℤ (ℤ ⧸ p0) (𝓞 K ⧸ Q) := .of_algebraMap_eq' rfl
    have : Module.Finite (ℤ ⧸ p0) (𝓞 K ⧸ Q) := Module.Finite.of_restrictScalars_finite ℤ _ _
    let E : (𝓞 K ⧸ p0.map (algebraMap ℤ (𝓞 K))) ≃ₐ[ℤ ⧸ p0] ((𝓞 K ⧸ P ^ e) × 𝓞 K ⧸ Q) :=
      { __ := (Ideal.quotEquivOfEq hQ).trans (Ideal.quotientMulEquivQuotientProd (P ^ e) Q hcop),
        commutes' := Quotient.ind fun _ ↦ rfl }
    rw [← Algebra.trace_quotient_eq_of_isDedekindDomain, ← Algebra.trace_eq_of_algEquiv E,
      Algebra.trace_prod_apply]
    have h2 : (E (Ideal.Quotient.mk _ x)).2 = 0 := by
      change Ideal.Quotient.mk Q x = 0
      exact Ideal.Quotient.eq_zero_iff_mem.mpr hx
    have h1 : (E (Ideal.Quotient.mk _ x)).1 = Ideal.Quotient.mk (P ^ e) x := rfl
    rw [h2, map_zero, add_zero, h1, htr]
  have hcast : ((e : ℤ ⧸ p0) = 0) ↔ p ∣ e := by
    rw [← map_natCast (Ideal.Quotient.mk p0) e, Ideal.Quotient.eq_zero_iff_mem,
      Ideal.mem_span_singleton, Int.natCast_dvd_natCast]
  refine ⟨fun hpe ↦ ⟨?_, ?_⟩, fun hpe ↦ ?_⟩
  · exact pow_sub_one_dvd_differentIdeal ℤ P e hp0ne
      (Ideal.dvd_iff_le.mpr Ideal.le_pow_ramificationIdx')
  · obtain ⟨y, hy⟩ := Algebra.trace_surjective (ℤ ⧸ p0) (𝓞 K ⧸ P) 1
    obtain ⟨x', rfl⟩ := Ideal.Quotient.mk_surjective y
    obtain ⟨a, ha, b, hb, hab⟩ := Submodule.mem_sup.mp (hPQ ▸ Submodule.mem_top : (1 : 𝓞 K) ∈ P ⊔ Q)
    have hbx : b * x' ∈ Q := Ideal.mul_mem_right _ _ hb
    refine not_dvd_differentIdeal_of_intTrace_notMem ℤ (P ^ e) Q hQ.symm (b * x') hbx ?_
    rw [← Ideal.Quotient.eq_zero_iff_mem, key _ hbx]
    have : Ideal.Quotient.mk P (b * x') = Ideal.Quotient.mk P x' := by
      rw [map_mul, eq_sub_of_add_eq' hab, map_sub, map_one,
        Ideal.Quotient.eq_zero_iff_mem.mpr ha, sub_zero, one_mul]
    rw [this, hy, mul_one]
    exact mt hcast.mp hpe
  · have hzero : ∀ x ∈ Q, Algebra.intTrace ℤ (𝓞 K) x ∈ p0 := by
      intro x hx
      rw [← Ideal.Quotient.eq_zero_iff_mem, key x hx, hcast.mpr hpe, zero_mul]
    have hQbot : Q ≠ ⊥ := by
      rintro rfl
      exact hmapne (by rw [hQ, Ideal.mul_bot])
    have hPebot : P ^ e ≠ ⊥ := pow_ne_zero _ hP
    have hP' : (((P ^ e : Ideal (𝓞 K)) : FractionalIdeal (nonZeroDivisors (𝓞 K)) K)⁻¹) =
        Q / p0.map (algebraMap ℤ (𝓞 K)) := by
      apply inv_involutive.injective
      simp only [hQ, FractionalIdeal.coeIdeal_mul, inv_div, mul_div_assoc]
      rw [div_self (by simpa using hQbot), mul_one, inv_inv]
    rw [Ideal.dvd_iff_le, differentialIdeal_le_iff (K := ℚ) (L := K) hPebot, hP',
      Submodule.map_le_iff_le_comap]
    intro x hx
    rw [Submodule.restrictScalars_mem, FractionalIdeal.mem_coe,
      FractionalIdeal.mem_div_iff_of_ne_zero (by simpa using hmapne)] at hx
    rw [Submodule.mem_comap, LinearMap.coe_restrictScalars, ← FractionalIdeal.coe_one,
      ← div_self (G₀ := FractionalIdeal (nonZeroDivisors ℤ) ℚ) (a := p0) (by simpa using hp0ne),
      FractionalIdeal.mem_coe, FractionalIdeal.mem_div_iff_of_ne_zero (by simpa using hp0ne)]
    simp only [FractionalIdeal.mem_coeIdeal, forall_exists_index, and_imp,
      forall_apply_eq_imp_iff₂] at hx
    intro y hy'
    obtain ⟨y, hy, rfl : algebraMap ℤ ℚ _ = _⟩ := (FractionalIdeal.mem_coeIdeal _).mp hy'
    obtain ⟨z, hz, hz'⟩ := hx _ (Ideal.mem_map_of_mem _ hy)
    have : Algebra.trace ℚ K (algebraMap (𝓞 K) K z) ∈ (p0 : FractionalIdeal (nonZeroDivisors ℤ) ℚ) := by
      rw [← Algebra.algebraMap_intTrace (A := ℤ)]
      exact ⟨Algebra.intTrace ℤ (𝓞 K) z, hzero z hz, rfl⟩
    rwa [mul_comm, ← smul_eq_mul, ← map_smul, Algebra.smul_def, mul_comm,
      ← IsScalarTower.algebraMap_apply, IsScalarTower.algebraMap_apply ℤ (𝓞 K) K, ← hz']

/-! The card's whole-number worked examples. -/

-- At 5: 2 is a root of x^2 + 1 mod 5, and Hensel's chain 2, 7, 57, 182, 2057, 14557.
example : (2 ^ 2 + 1) % 5 = 0 := by norm_num
example : (7 ^ 2 + 1) % 5 ^ 2 = 0 ∧ (57 ^ 2 + 1) % 5 ^ 3 = 0 ∧ (182 ^ 2 + 1) % 5 ^ 4 = 0 ∧
    (2057 ^ 2 + 1) % 5 ^ 5 = 0 ∧ (14557 ^ 2 + 1) % 5 ^ 6 = 0 := by norm_num
-- At 3: no root of x^2 + 1 mod 3 (inert). At 2: the root 1 mod 2 dies mod 4.
example : ∀ x : ZMod 3, x ^ 2 + 1 ≠ 0 := by decide
example : ∀ x : ZMod 2, x ^ 2 + 1 = 0 ↔ x = 1 := by decide
example : ∀ x : ZMod 4, x ^ 2 + 1 ≠ 0 := by decide
-- Z[i] mod 3: (1 + i)^4 = -4, which is not 1 mod 3, and (1 + i)^8 = 16, which is 1 mod 3,
-- so 1 + i has order 8 among the 8 nonzero remainders.
example : (⟨1, 1⟩ : GaussianInt) ^ 4 = ⟨-4, 0⟩ ∧ (⟨1, 1⟩ : GaussianInt) ^ 8 = ⟨16, 0⟩ ∧
    (-4 : ℤ) % 3 ≠ 1 ∧ (16 : ℤ) % 3 = 1 := by decide
-- (1 + i)^2 = 2i in Z[i], and N(2i) = 4.
example : (⟨1, 1⟩ : GaussianInt) ^ 2 = ⟨0, 2⟩ := by decide
example : Zsqrtd.norm (⟨0, 2⟩ : GaussianInt) = 4 := by decide
-- 1 + i is a root of x^2 - 2x + 2, which is Eisenstein at 2.
example : (⟨1, 1⟩ : GaussianInt) ^ 2 - 2 * ⟨1, 1⟩ + 2 = 0 := by decide
example : (-2 : ℤ) % 2 = 0 ∧ (2 : ℤ) % 2 = 0 ∧ (2 : ℤ) % 4 ≠ 0 := by decide
-- The trace tables and their determinants: -4, -20, 5, -108.
example : Matrix.det !![(2 : ℤ), 0; 0, -2] = -4 := by simp [Matrix.det_fin_two]
example : Matrix.det !![(2 : ℤ), 0; 0, -10] = -20 := by simp [Matrix.det_fin_two]
example : Matrix.det !![(2 : ℤ), 1; 1, 3] = 5 := by simp [Matrix.det_fin_two]
example : Matrix.det !![(3 : ℤ), 0, 0; 0, 0, 6; 0, 6, 0] = -108 := by
  simp [Matrix.det_fin_three]
-- Prime powers multiply back to the norms of the different.
example : 2 ^ 2 = 4 ∧ 2 ^ 2 * 5 = 20 ∧ 2 ^ 2 * 3 ^ 3 = 108 := by norm_num
-- Z[√5] is too small: N(2√5) = -20, not d_K = 5.
example : Zsqrtd.norm (⟨0, 2⟩ : ℤ√5) = -20 := by decide

#print axioms differentIdeal_eq_span_derivative_of_adjoin_eq_top
#print axioms absNorm_differentIdeal_eq_natAbs_discr
#print axioms differentIdeal_exponent_tame_wild
