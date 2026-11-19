-- Solvable by radicals: a polynomial with rational coefficients has all its complex roots written by radicals exactly when its Galois group is solvable, and x^5 - x - 1 has all 120 shuffles of its roots as its group, which is not solvable, so none of its roots has a radical expression.
import Mathlib.FieldTheory.AbelRuffini
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.GroupTheory.Perm.Cycle.Concrete
import Mathlib.GroupTheory.Perm.Cycle.Type
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.FieldTheory.KummerExtension
import Mathlib.RingTheory.RootsOfUnity.Complex
import Mathlib.RingTheory.Frobenius
import Mathlib.RingTheory.Invariant.Galois
import Mathlib.NumberTheory.NumberField.Basic
import Mathlib.RingTheory.Polynomial.Selmer
import Mathlib.LinearAlgebra.FreeModule.IdealQuotient
import Mathlib.Data.ZMod.QuotientRing

open Polynomial Equiv

attribute [local instance] Polynomial.Gal.splits_ℚ_ℂ

open Module IntermediateField in
theorem kummer_step_aux {A B : Type} [Field A] [Field B] [Algebra A B] [FiniteDimensional A B]
    [IsGalois A B] [IsCyclic Gal(B/A)] (N : ℕ) (hN : 0 < N) (ι : B →+* ℂ)
    (hA : ∀ a : A, ι (algebraMap A B a) ∈ solvableByRad ℚ ℂ) (ζ : A) (hζ : IsPrimitiveRoot ζ N)
    (hd : finrank A B ∣ N) (b : B) : ι b ∈ solvableByRad ℚ ℂ := by
  have hd0 : finrank A B ≠ 0 := finrank_pos.ne'
  have hK : (primitiveRoots (finrank A B) A).Nonempty := by
    have := hζ.pow_of_dvd (Nat.div_pos (Nat.le_of_dvd hN hd) finrank_pos).ne'
      (Nat.div_dvd_of_dvd hd)
    rw [Nat.div_div_self hd hN.ne'] at this
    exact ⟨_, (mem_primitiveRoots finrank_pos).mpr this⟩
  obtain ⟨α, ⟨a, ha⟩, hα⟩ := exists_root_adjoin_eq_top_of_isCyclic A B hK
  have hια : ι α ∈ solvableByRad ℚ ℂ := by
    apply solvableByRad.rad_mem hd0
    rw [← map_pow, ← ha]
    exact hA a
  let T : Subalgebra A B :=
    { toSubsemiring := ((solvableByRad ℚ ℂ).toSubfield.comap ι).toSubring.toSubsemiring
      algebraMap_mem' := hA }
  have hαT : Algebra.adjoin A {α} ≤ T := by
    rw [Algebra.adjoin_le_iff, Set.singleton_subset_iff]
    exact hια
  have hb : b ∈ (A⟮α⟯).toSubalgebra := by rw [hα]; trivial
  rw [IntermediateField.adjoin_simple_toSubalgebra_of_isAlgebraic
    (Algebra.IsAlgebraic.isAlgebraic α)] at hb
  exact hαT hb

open Module IntermediateField in
theorem radical_tower_aux (N : ℕ) (hN : 0 < N) : ∀ (d : ℕ) (K L : Type) [Field K] [Field L]
    [Algebra K L] [FiniteDimensional K L] [IsGalois K L], finrank K L = d →
    Group.IsSolvable Gal(L/K) → ∀ ι : L →+* ℂ, (∀ a : K, ι (algebraMap K L a) ∈ solvableByRad ℚ ℂ) →
    ∀ ζ : K, IsPrimitiveRoot ζ N → d ∣ N → ∀ b : L, ι b ∈ solvableByRad ℚ ℂ := by
  intro d
  induction d using Nat.strong_induction_on with
  | _ d IH =>
  intro K L _ _ _ _ _ hdeg hsolv ι hA ζ hζ hdN b
  by_cases hd1 : d = 1
  · obtain ⟨a, rfl⟩ :=
      (Algebra.finrank_eq_one_iff_bijective_algebraMap.mp (hdeg.trans hd1)).2 b
    exact hA a
  have hcard : Nat.card Gal(L/K) = d := (IsGalois.card_aut_eq_finrank K L).trans hdeg
  have hd0 : 0 < d := hdeg ▸ finrank_pos
  -- the bottom step: a fixed field of a nontrivial normal subgroup lies in the radical field
  have bottom : ∀ (H : Subgroup Gal(L/K)) [H.Normal], H ≠ ⊥ →
      ∀ y : fixedField H, ι (y : L) ∈ solvableByRad ℚ ℂ := by
    intro H _ hH
    have hmul := Module.finrank_mul_finrank K (fixedField H) L
    rw [finrank_fixedField_eq_card, hdeg] at hmul
    have hH1 : 1 < Nat.card H := (Subgroup.one_lt_card_iff_ne_bot H).mpr hH
    have hlt : finrank K (fixedField H) < d := by
      rw [← hmul]; exact lt_mul_of_one_lt_right finrank_pos hH1
    refine IH _ hlt K (fixedField H) rfl
      (Group.isSolvable_of_surjective (AlgEquiv.restrictNormalHom_surjective (F := K) L))
      (ι.comp (fixedField H).val.toRingHom) (fun a => hA a) ζ hζ
      (dvd_trans (Dvd.intro _ hmul) hdN)
  -- facts about the top step `L / fixedField H`
  have top : ∀ (H : Subgroup Gal(L/K)), Gal(L/fixedField H) ≃* H := fun H =>
    (IntermediateField.fixingSubgroupEquiv (fixedField H)).symm.trans
      (MulEquiv.subgroupCongr (IntermediateField.fixingSubgroup_fixedField H))
  have topdeg : ∀ (H : Subgroup Gal(L/K)), finrank (fixedField H) L = Nat.card H := fun H =>
    finrank_fixedField_eq_card H
  have hζ' : ∀ (H : Subgroup Gal(L/K)),
      IsPrimitiveRoot (algebraMap K (fixedField H) ζ) N := fun H =>
    hζ.map_of_injective (algebraMap K (fixedField H)).injective
  have topdvd : ∀ (H : Subgroup Gal(L/K)), Nat.card H ∣ N := fun H =>
    dvd_trans (hcard ▸ Subgroup.card_subgroup_dvd_card H) hdN
  by_cases hC : commutator Gal(L/K) = ⊥
  · -- abelian case: one cyclic step on top
    have hcomm : ∀ a b : Gal(L/K), a * b = b * a := by
      intro a b
      have hC' : ⁅(⊤ : Subgroup Gal(L/K)), ⊤⁆ = ⊥ := hC
      have := (Subgroup.commutator_eq_bot_iff_le_centralizer.mp hC') (Subgroup.mem_top a)
      rw [Subgroup.mem_centralizer_iff] at this
      exact (this b (Subgroup.mem_top b)).symm
    have : Nontrivial Gal(L/K) := by
      rw [← Finite.one_lt_card_iff_nontrivial, hcard]; omega
    obtain ⟨g, hg⟩ := exists_ne (1 : Gal(L/K))
    let H := Subgroup.zpowers g
    have hHn : H.Normal := ⟨fun n _ g' => by rwa [hcomm g' n, mul_inv_cancel_right]⟩
    have hHb : H ≠ ⊥ := by
      intro h
      exact hg ((Subgroup.mem_bot).mp (h ▸ Subgroup.mem_zpowers g))
    have : IsCyclic Gal(L/fixedField H) := isCyclic_of_surjective (top H).symm.toMonoidHom
      (top H).symm.surjective
    exact kummer_step_aux N hN ι (bottom H hHb) _ (hζ' H) ((topdeg H).symm ▸ topdvd H) b
  · -- non-abelian case: the commutator subgroup splits the tower in two
    let H := commutator Gal(L/K)
    have hHt : H ≠ ⊤ := by
      intro h
      have hall : ∀ n, Subgroup.derivedSeries Gal(L/K) n = ⊤ := by
        intro n
        induction n with
        | zero => rfl
        | succ n ih => rw [Subgroup.derivedSeries_succ, ih]; exact h
      obtain ⟨n, hn⟩ := hsolv.solvable
      have : Nontrivial Gal(L/K) := by
        rw [← Finite.one_lt_card_iff_nontrivial, hcard]; omega
      exact bot_ne_top (hn ▸ hall n)
    have hlt : Nat.card H < d := by
      rw [← hcard]
      exact lt_of_le_of_ne (Subgroup.card_le_card_group H)
        (fun h => hHt (Subgroup.card_eq_iff_eq_top H |>.mp h))
    exact IH _ hlt (fixedField H) L (topdeg H) 
      (Group.isSolvable_of_surjective (f := (top H).symm.toMonoidHom) (top H).symm.surjective) ι
      (bottom H hC) _ (hζ' H) (topdvd H) b

open Module IntermediateField in
theorem roots_mem_solvableByRad_of_isSolvable (f : ℚ[X]) (hf : Group.IsSolvable f.Gal) :
    ∀ x ∈ f.rootSet ℂ, x ∈ solvableByRad ℚ ℂ := by
  by_cases hf0 : f = 0
  · simp [hf0]
  set N := Nat.card f.Gal with hNdef
  have hN : 0 < N := Nat.card_pos
  have : NeZero N := ⟨hN.ne'⟩
  set g : ℚ[X] := f * (X ^ N - 1) with hg
  have hcyc0 : (X ^ N - 1 : ℚ[X]) ≠ 0 := by
    simpa using X_pow_sub_C_ne_zero hN (1 : ℚ)
  have hg0 : g ≠ 0 := mul_ne_zero hf0 hcyc0
  have hgs : (g.map (algebraMap ℚ g.SplittingField)).Splits := SplittingField.splits g
  have hfs : (f.map (algebraMap ℚ g.SplittingField)).Splits :=
    hgs.of_dvd ((Polynomial.map_ne_zero_iff (algebraMap ℚ _).injective).mpr hg0)
      (Polynomial.map_dvd _ (dvd_mul_right f _))
  have : Fact ((f.map (algebraMap ℚ g.SplittingField)).Splits) := ⟨hfs⟩
  have : IsGalois ℚ g.SplittingField := ⟨⟩
  have hsolvL : Group.IsSolvable Gal(g.SplittingField/ℚ) :=
    gal_mul_isSolvable hf (gal_X_pow_sub_one_isSolvable N)
  let ι : g.SplittingField →ₐ[ℚ] ℂ := SplittingField.lift g (IsAlgClosed.splits _)
  have himg := hgs.image_rootSet ι
  -- a primitive root of unity in the splitting field
  have hζc := Complex.isPrimitiveRoot_exp N hN.ne'
  obtain ⟨ζ, -, hζι⟩ : Complex.exp (2 * Real.pi * Complex.I / N) ∈ ι '' g.rootSet g.SplittingField := by
    rw [himg, mem_rootSet_of_ne hg0, hg, map_mul, mul_eq_zero]
    right
    simp [hζc.pow_eq_one]
  have hζ : IsPrimitiveRoot ζ N := (hζι ▸ hζc).of_map_of_injective ι.injective
  let K : IntermediateField ℚ g.SplittingField := IntermediateField.adjoin ℚ {ζ}
  let ζK : K := ⟨ζ, IntermediateField.mem_adjoin_simple_self ℚ ζ⟩
  have hζK : IsPrimitiveRoot ζK N := hζ.of_map_of_injective (f := K.val) K.val.injective
  -- the base field lies in the radical field
  have hK : ∀ a : K, ι.toRingHom (algebraMap K g.SplittingField a) ∈ solvableByRad ℚ ℂ := by
    have hle : K ≤ (solvableByRad ℚ ℂ).comap ι := by
      rw [IntermediateField.adjoin_simple_le_iff]
      change ι ζ ∈ solvableByRad ℚ ℂ
      apply solvableByRad.rad_mem hN.ne'
      rw [← map_pow, hζ.pow_eq_one, map_one]
      exact one_mem _
    intro a
    exact hle a.2
  -- the group of `L / K` is solvable and its order divides `N`
  have hsolvK : Group.IsSolvable Gal(g.SplittingField/K) :=
    Group.isSolvable_of_surjective (f := (IntermediateField.fixingSubgroupEquiv K).toMonoidHom)
      (IntermediateField.fixingSubgroupEquiv K).surjective
  let φ : K.fixingSubgroup →* f.Gal := (Gal.restrict f g.SplittingField).comp K.fixingSubgroup.subtype
  have hφ : Function.Injective φ := by
    rw [injective_iff_map_eq_one]
    intro σ hσ
    apply Subtype.ext
    apply Polynomial.Gal.ext (p := g)
    intro x hx
    have hx2 : aeval x (f * (X ^ N - 1)) = 0 := (mem_rootSet_of_ne hg0).mp hx
    rw [map_mul, mul_eq_zero] at hx2
    clear hx
    rcases hx2 with hx | hx
    · have hx' : x ∈ f.rootSet g.SplittingField := (mem_rootSet_of_ne hf0).mpr hx
      have := Gal.galActionHom_restrict f g.SplittingField σ.1 ⟨x, hx'⟩
      simp only [φ, MonoidHom.comp_apply, Subgroup.coe_subtype] at hσ
      rw [hσ, map_one] at this
      exact this.symm
    · have hxN : x ^ N = 1 := by simpa [sub_eq_zero] using hx
      obtain ⟨i, -, rfl⟩ := hζ.eq_pow_of_pow_eq_one hxN
      have hσζ : σ.1 ζ = ζ := (IntermediateField.mem_fixingSubgroup_iff K σ.1).mp σ.2 ζ
        (IntermediateField.mem_adjoin_simple_self ℚ ζ)
      change (σ.1 : g.SplittingField ≃ₐ[ℚ] g.SplittingField) (ζ ^ i) = ζ ^ i
      rw [map_pow, hσζ]
  have hdvd : finrank K g.SplittingField ∣ N := by
    rw [← IsGalois.card_aut_eq_finrank, ← Nat.card_congr (IntermediateField.fixingSubgroupEquiv K).toEquiv]
    exact Subgroup.card_dvd_of_injective φ hφ
  -- finish
  intro x hx
  rw [← (hfs.image_rootSet ι)] at hx
  obtain ⟨y, -, rfl⟩ := hx
  exact radical_tower_aux N hN _ K g.SplittingField rfl hsolvK ι.toRingHom hK ζK hζK hdvd y

open Module IntermediateField in
theorem isSolvable_of_roots_mem_solvableByRad (f : ℚ[X])
    (h : ∀ x ∈ f.rootSet ℂ, x ∈ solvableByRad ℚ ℂ) : Group.IsSolvable f.Gal := by
  induction f using UniqueFactorizationMonoid.induction_on_prime with
  | h₁ => exact gal_zero_isSolvable
  | h₂ u hu =>
    obtain ⟨r, -, rfl⟩ := Polynomial.isUnit_iff.mp hu
    exact gal_C_isSolvable r
  | h₃ a p ha hp IH =>
    have hpa : p * a ≠ 0 := mul_ne_zero hp.ne_zero ha
    have hsub : ∀ q, q ∣ p * a → ∀ x ∈ q.rootSet ℂ, x ∈ solvableByRad ℚ ℂ := by
      intro q hq x hx
      apply h x
      rw [mem_rootSet_of_ne hpa]
      obtain ⟨c, hc⟩ := hq
      rw [hc, map_mul, (mem_rootSet.mp hx).2, zero_mul]
    refine gal_mul_isSolvable ?_ (IH (hsub a (dvd_mul_left a p)))
    have hirr : Irreducible p := hp.irreducible
    obtain ⟨x, hx⟩ := IsAlgClosed.exists_aeval_eq_zero ℂ p (degree_pos_of_irreducible hirr).ne'
    exact isSolvable_gal_of_irreducible
      (hsub p (dvd_mul_right p a) x ((mem_rootSet_of_ne hp.ne_zero).mpr hx)) hirr hx

open NumberField in
theorem quintic_reduction_mod_two {R : Type*} [CommRing R] [IsDomain R] (z : R)
    (hz : z ^ 5 - z - 1 = 0) (h2 : (2 : R) = 0) :
    (z ^ 2 + z + 1 = 0 ∧ z ^ 8 ≠ z) ∨ (z ^ 3 + z ^ 2 + 1 = 0 ∧ z ^ 8 = z) := by
  have hprod : (z ^ 2 + z + 1) * (z ^ 3 + z ^ 2 + 1) = 0 := by
    linear_combination hz + (z ^ 4 + z ^ 3 + z ^ 2 + z + 1) * h2
  rcases mul_eq_zero.mp hprod with hq | hc
  · refine Or.inl ⟨hq, fun h8 => one_ne_zero (α := R) ?_⟩
    linear_combination (z ^ 6 - z ^ 5 + z ^ 3 - z ^ 2 + 1) * hq - z * h2 - h8
  · refine Or.inr ⟨hc, ?_⟩
    linear_combination (z ^ 5 - z ^ 4 + z ^ 3 - 2 * z ^ 2 + 3 * z - 4) * hc +
      (3 * z ^ 2 - 2 * z + 2) * h2

open NumberField in
theorem card_rootSet_complex_of_irreducible {p : ℚ[X]} (hirr : Irreducible p) :
    Fintype.card (p.rootSet ℂ) = p.natDegree := by
  simp_rw [rootSet_def, Finset.coe_sort_coe, Fintype.card_coe]
  rw [Multiset.toFinset_card_of_nodup, ← Splits.natDegree_eq_card_roots, natDegree_map]
  · exact IsAlgClosed.splits _
  · exact nodup_roots ((separable_map (algebraMap ℚ ℂ)).mpr hirr.separable)

open NumberField in
theorem ringOfIntegers_isInvariant (L : Type) [Field L] [NumberField L] [IsGalois ℚ L] :
    Algebra.IsInvariant ℤ (𝓞 L) Gal(L/ℚ) := by
  refine ⟨fun b hb => ?_⟩
  have hfix : (b : L) ∈ (⊥ : IntermediateField ℚ L) := by
    rw [IsGalois.mem_bot_iff_fixed]
    intro σ
    have := congrArg (algebraMap (𝓞 L) L) (hb σ)
    rw [algebraMap.smul'] at this
    exact this
  rw [IntermediateField.mem_bot] at hfix
  obtain ⟨r, hr⟩ := hfix
  have hint : IsIntegral ℤ r := by
    have := b.isIntegral_coe
    rw [← RingOfIntegers.coe_eq_algebraMap, ← hr] at this
    exact isIntegral_algebraMap_iff.mp this
  obtain ⟨n, rfl⟩ := IsIntegrallyClosed.algebraMap_eq_of_integral hint
  refine ⟨n, ?_⟩
  ext
  rw [← hr]
  simp

open NumberField in
theorem selmer_five_exists_swap : ∃ g : (X ^ 5 - X - 1 : ℚ[X]).Gal,
    (Gal.galActionHom (X ^ 5 - X - 1 : ℚ[X]) ℂ g).IsSwap := by
  classical
  set f : ℚ[X] := X ^ 5 - X - 1 with hfdef
  let L := f.SplittingField
  have : NumberField L := {}
  have : IsGalois ℚ L := ⟨⟩
  have : Algebra.IsInvariant ℤ (𝓞 L) Gal(L/ℚ) := ringOfIntegers_isInvariant L
  -- a prime of `𝓞 L` over `2`
  have h2max : (Ideal.span {(2 : ℤ)}).IsMaximal :=
    ((Ideal.span_singleton_prime two_ne_zero).mpr Int.prime_two).isMaximal (by simp)
  obtain ⟨Q, hQmax, hQ⟩ := Ideal.exists_ideal_over_maximal_of_isIntegral (S := 𝓞 L)
    (Ideal.span {(2 : ℤ)}) (by
      rw [(RingHom.injective_iff_ker_eq_bot _).mp (algebraMap ℤ (𝓞 L)).injective_int]
      exact bot_le)
  have h2Q : (2 : 𝓞 L) ∈ Q := by
    have : (2 : ℤ) ∈ Q.under ℤ := hQ ▸ Ideal.subset_span rfl
    simpa using this
  have hQbot : Q ≠ ⊥ := by
    intro h
    rw [h, Ideal.mem_bot] at h2Q
    exact two_ne_zero h2Q
  have : Finite (𝓞 L ⧸ Q) := Ideal.finiteQuotientOfFreeOfNeBot Q hQbot
  have hq : Nat.card (ℤ ⧸ Q.under ℤ) = 2 := by
    rw [hQ, Nat.card_congr (Int.quotientSpanEquivZMod 2).toEquiv]
    simp
  obtain ⟨σ, hσ⟩ := IsArithFrobAt.exists_of_isInvariant ℤ Gal(L/ℚ) Q
  have hfrob : ∀ b : 𝓞 L, Ideal.Quotient.mk Q (σ • b) = (Ideal.Quotient.mk Q b) ^ 2 := by
    intro b
    have := AlgHom.IsArithFrobAt.mk_apply hσ b
    rw [hq] at this
    simpa using this
  set τ : Gal(L/ℚ) := σ ^ 3 with hτdef
  have hτ : ∀ b : 𝓞 L, Ideal.Quotient.mk Q (τ • b) = (Ideal.Quotient.mk Q b) ^ 8 := by
    intro b
    rw [hτdef, pow_succ, pow_succ, pow_one, mul_smul, mul_smul, hfrob, hfrob, hfrob]
    ring
  -- the roots, as algebraic integers
  have hintroot : ∀ y ∈ f.rootSet L, IsIntegral ℤ y := by
    intro y hy
    have hy0 : y ^ 5 - y - 1 = 0 := by simpa [hfdef] using (mem_rootSet.mp hy).2
    refine ⟨X ^ 5 - X - 1, by monicity!, ?_⟩
    simpa using hy0
  let e := Gal.rootsEquivRootsAux f ℂ
  let bOf : f.rootSet ℂ → 𝓞 L := fun x => ⟨((e.symm x : f.rootSet L) : L), hintroot _ (e.symm x).2⟩
  have hbroot : ∀ x, (bOf x) ^ 5 - bOf x - 1 = 0 := by
    intro x
    have h := (mem_rootSet.mp (e.symm x).2).2
    simp only [hfdef, map_sub, map_pow, aeval_X, map_one] at h
    ext
    simp only [bOf, map_sub, map_pow, map_one, map_zero, RingOfIntegers.map_mk]
    exact h
  have hbinj : Function.Injective bOf := by
    intro x x' h
    have := congrArg (algebraMap (𝓞 L) L) h
    simp only [bOf, RingOfIntegers.map_mk] at this
    exact e.symm.injective (Subtype.ext this)
  have hbsmul : ∀ (g : f.Gal) (x : f.rootSet ℂ),
      bOf (Gal.galActionHom f ℂ g x) = (show Gal(L/ℚ) from g) • bOf x := by
    intro g x
    apply RingOfIntegers.coe_injective
    rw [algebraMap.smul']
    simp only [bOf, e, Gal.galActionHom, MulAction.toPermHom_apply,
      MulAction.toPerm_apply, Gal.smul_def, Equiv.symm_apply_apply]
    rfl
  -- reduction modulo `Q`
  let r : f.rootSet ℂ → 𝓞 L ⧸ Q := fun x => Ideal.Quotient.mk Q (bOf x)
  have h2 : (2 : 𝓞 L ⧸ Q) = 0 := by
    rw [← map_ofNat (Ideal.Quotient.mk Q) 2]
    exact Ideal.Quotient.eq_zero_iff_mem.mpr h2Q
  have hrroot : ∀ x, (r x) ^ 5 - r x - 1 = 0 := by
    intro x
    have := congrArg (Ideal.Quotient.mk Q) (hbroot x)
    simpa only [map_sub, map_pow, map_one, map_zero] using this
  have hrinj : Function.Injective r := by
    intro x x' hxx'
    by_contra hne
    have hne' : bOf x - bOf x' ≠ 0 := sub_ne_zero.mpr (hbinj.ne hne)
    have hh : bOf x ^ 4 + bOf x ^ 3 * bOf x' + bOf x ^ 2 * bOf x' ^ 2 + bOf x * bOf x' ^ 3 +
        bOf x' ^ 4 - 1 = 0 := by
      have : (bOf x - bOf x') * (bOf x ^ 4 + bOf x ^ 3 * bOf x' + bOf x ^ 2 * bOf x' ^ 2 +
          bOf x * bOf x' ^ 3 + bOf x' ^ 4 - 1) = 0 := by
        linear_combination hbroot x - hbroot x'
      exact (mul_eq_zero.mp this).resolve_left hne'
    have hh' := congrArg (Ideal.Quotient.mk Q) hh
    simp only [map_sub, map_add, map_mul, map_pow, map_one, map_zero] at hh'
    change r x ^ 4 + r x ^ 3 * r x' + r x ^ 2 * r x' ^ 2 + r x * r x' ^ 3 + r x' ^ 4 - 1 = 0 at hh'
    rw [← hxx'] at hh'
    have : (1 : 𝓞 L ⧸ Q) = 0 := by
      linear_combination -hrroot x + r x * hh' - 2 * r x ^ 5 * h2
    exact one_ne_zero this
  let τf : f.Gal := τ
  -- `τ` moves exactly the roots that reduce to roots of `X ^ 2 + X + 1`
  have hmove : ∀ x, Gal.galActionHom f ℂ τf x ≠ x ↔ (r x) ^ 2 + r x + 1 = 0 := by
    intro x
    have key : r (Gal.galActionHom f ℂ τf x) = (r x) ^ 8 := by
      simp only [r]
      rw [hbsmul]
      exact hτ (bOf x)
    rcases quintic_reduction_mod_two (r x) (hrroot x) h2 with ⟨hq, h8⟩ | ⟨hc, h8⟩
    · exact ⟨fun _ => hq, fun _ h => h8 (key.symm.trans (congrArg r h))⟩
    · refine ⟨fun h => absurd (hrinj (key.trans h8)) h, fun hq => ?_⟩
      exfalso
      have : (1 : 𝓞 L ⧸ Q) = 0 := by
        linear_combination (1 - r x ^ 2 - 2 * r x) * hq + (r x + 2) * hc - h2
      exact one_ne_zero this
  -- counting: at most two roots reduce to roots of the quadratic, at most three to the cubic
  have hcount : ∀ (P : (𝓞 L ⧸ Q)[X]), P.Monic → ∀ (s : Finset (f.rootSet ℂ)),
      (∀ x ∈ s, P.IsRoot (r x)) → s.card ≤ P.natDegree := by
    intro P hP s hs
    rw [← Finset.card_image_of_injective s hrinj]
    apply Polynomial.card_le_degree_of_subset_roots
    intro z hz
    obtain ⟨x, hx, rfl⟩ := Finset.mem_image.mp hz
    exact (mem_roots hP.ne_zero).mpr (hs x hx)
  have hirr : Irreducible f := X_pow_sub_X_sub_one_irreducible_rat (by norm_num)
  have h5 : Fintype.card (f.rootSet ℂ) = 5 := by
    rw [card_rootSet_complex_of_irreducible hirr, hfdef]
    compute_degree!
  refine ⟨τf, ?_⟩
  rw [← Equiv.Perm.card_support_eq_two]
  have hsupp : (Gal.galActionHom f ℂ τf).support =
      Finset.univ.filter (fun x => (r x) ^ 2 + r x + 1 = 0) := by
    ext x
    simp [Equiv.Perm.mem_support, hmove]
  rw [hsupp]
  have hle2 := hcount (X ^ 2 + X + 1) (by monicity!)
    (Finset.univ.filter (fun x => (r x) ^ 2 + r x + 1 = 0)) (by
      intro x hx
      simpa using (Finset.mem_filter.mp hx).2)
  have hle3 := hcount (X ^ 3 + X ^ 2 + 1) (by monicity!)
    (Finset.univ.filter (fun x => ¬ (r x) ^ 2 + r x + 1 = 0)) (by
      intro x hx
      have hx' := (Finset.mem_filter.mp hx).2
      rcases quintic_reduction_mod_two (r x) (hrroot x) h2 with ⟨hq, -⟩ | ⟨hc, -⟩
      · exact absurd hq hx'
      · simpa using hc)
  have hd2 : (X ^ 2 + X + 1 : (𝓞 L ⧸ Q)[X]).natDegree = 2 := by compute_degree!
  have hd3 : (X ^ 3 + X ^ 2 + 1 : (𝓞 L ⧸ Q)[X]).natDegree = 3 := by compute_degree!
  have htot := Finset.card_filter_add_card_filter_not (s := Finset.univ)
    (fun x : f.rootSet ℂ => (r x) ^ 2 + r x + 1 = 0)
  rw [Finset.card_univ, h5] at htot
  omega

/-- Galois's theorem, for numbers inside the complex numbers. The roots of a polynomial `f` with
rational coefficients can all be written with radicals (each lies in `solvableByRad ℚ ℂ`, the
smallest field of complex numbers that holds the fractions and every `n`th root of each of its
members) exactly when the Galois group of `f` is solvable: it breaks down through a chain of
normal subgroups whose steps are all abelian. -/
theorem roots_solvable_by_radicals_iff_galois_group_solvable (f : ℚ[X]) :
    (∀ x ∈ f.rootSet ℂ, x ∈ solvableByRad ℚ ℂ) ↔ Group.IsSolvable f.Gal := by
  exact ⟨isSolvable_of_roots_mem_solvableByRad f, roots_mem_solvableByRad_of_isSolvable f⟩

/-- The group of `x^5 - x - 1` is all 120 shuffles of its roots. Its Galois group, acting on the
five complex roots, gives every permutation of them exactly once; it has 120 members; and it is
not solvable. -/
theorem galois_group_of_x5_sub_x_sub_one_is_all_120_shuffles :
    Function.Bijective (Gal.galActionHom (X ^ 5 - X - 1 : ℚ[X]) ℂ) ∧
      Fintype.card (X ^ 5 - X - 1 : ℚ[X]).Gal = 120 ∧
      ¬ Group.IsSolvable (X ^ 5 - X - 1 : ℚ[X]).Gal := by
  have hirr : Irreducible (X ^ 5 - X - 1 : ℚ[X]) :=
    X_pow_sub_X_sub_one_irreducible_rat (by norm_num)
  have hdeg : (X ^ 5 - X - 1 : ℚ[X]).natDegree = 5 := by compute_degree!
  have h1 := card_rootSet_complex_of_irreducible hirr
  rw [hdeg] at h1
  obtain ⟨g, hg⟩ := selmer_five_exists_swap
  have hbij : Function.Bijective (Gal.galActionHom (X ^ 5 - X - 1 : ℚ[X]) ℂ) := by
    classical
    refine ⟨Gal.galActionHom_injective _ ℂ, fun x =>
      congr(x ∈ $(show (Gal.galActionHom (X ^ 5 - X - 1 : ℚ[X]) ℂ).range = ⊤ from ?_)).mpr
        (Subgroup.mem_top x)⟩
    apply Equiv.Perm.subgroup_eq_top_of_swap_mem
    · rw [h1]; exact Nat.prime_five
    · rw [h1]
      have := Gal.prime_degree_dvd_card hirr (by rw [hdeg]; exact Nat.prime_five)
      rw [hdeg] at this
      simpa only [Fintype.card_eq_nat_card,
        Nat.card_congr (MonoidHom.ofInjective (Gal.galActionHom_injective _ ℂ)).toEquiv.symm]
        using this
    · exact ⟨g, rfl⟩
    · exact hg
  refine ⟨hbij, ?_, ?_⟩
  · rw [Fintype.card_of_bijective hbij, Fintype.card_perm, h1]
    rfl
  · intro hs
    have := Group.isSolvable_of_surjective (f := Gal.galActionHom (X ^ 5 - X - 1 : ℚ[X]) ℂ) hbij.2
    refine Equiv.Perm.not_isSolvable _ ?_ this
    rw [Cardinal.mk_fintype, h1]
    norm_num

/-- The verdict: no complex root of `x^5 - x - 1` has a radical expression. -/
theorem no_root_of_x5_sub_x_sub_one_is_solvable_by_radicals (x : ℂ)
    (hx : aeval x (X ^ 5 - X - 1 : ℚ[X]) = 0) : x ∉ solvableByRad ℚ ℂ := by
  intro hrad
  exact galois_group_of_x5_sub_x_sub_one_is_all_120_shuffles.2.2
    (isSolvable_gal_of_irreducible hrad (X_pow_sub_X_sub_one_irreducible_rat (by norm_num)) hx)

-- The card's whole-number worked examples.
-- Mod 5: the values of f at 0, 1, 2, 3, 4 are all 4, so f has no root mod 5.
example : ∀ a : ZMod 5, a ^ 5 - a - 1 = 4 := by decide
-- Mod 2: (x^2 + x + 1)(x^3 + x^2 + 1) = x^5 + x + 1, which is f mod 2.
example : ((X ^ 2 + X + 1) * (X ^ 3 + X ^ 2 + 1) : (ZMod 2)[X]) = X ^ 5 + X + 1 := by
  linear_combination (X ^ 4 + X ^ 3 + X ^ 2) * (CharTwo.two_eq_zero : (2 : (ZMod 2)[X]) = 0)
-- Neither factor has a root mod 2: each equals 1 at 0 and at 1.
example : ∀ a : ZMod 2, a ^ 2 + a + 1 = 1 ∧ a ^ 3 + a ^ 2 + 1 = 1 := by decide
-- The discriminant 5^5 b^4 + 4^4 a^5 at a = b = -1: 3125 - 256 = 2869 = 19 × 151.
example : (5 : ℤ) ^ 5 * (-1) ^ 4 + 4 ^ 4 * (-1) ^ 5 = 2869 ∧ (2869 : ℤ) = 19 * 151 := by norm_num
-- 2869 is not a square (it lies strictly between 53^2 and 54^2), and neither 2 nor 5 divides it.
example : 53 ^ 2 < 2869 ∧ 2869 < 54 ^ 2 ∧ ¬ 2 ∣ 2869 ∧ ¬ 5 ∣ 2869 := by norm_num
-- A (3, 2) shuffle cubed: the 3-cycle dies and one transposition is left.
example : ((swap (0 : Fin 5) 1) * c[2, 3, 4]) ^ 3 = swap 0 1 := by decide
-- All shuffles of five roots: 120 of them.
example : Fintype.card (Perm (Fin 5)) = 120 := by decide
-- The shares S5 predicts: 24 five-cycles, 30 of type (4, 1), 20 of (3, 1, 1), 20 of (3, 2),
-- 15 of (2, 2, 1), 10 transpositions and the identity.
example : (Finset.univ.filter (fun σ : Perm (Fin 5) => σ.cycleType = {5})).card = 24 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 5) => σ.cycleType = {4})).card = 30 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 5) => σ.cycleType = {3})).card = 20 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 5) => σ.cycleType = {3, 2})).card = 20 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 5) => σ.cycleType = {2, 2})).card = 15 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 5) => σ.cycleType = {2})).card = 10 ∧
    (Finset.univ.filter (fun σ : Perm (Fin 5) => σ.cycleType = 0)).card = 1 := by decide
-- What breaks mod 19: 13 is a root of f and of its slope 5x^4 - 1, so (x - 13)^2 divides f.
example : (13 : ZMod 19) ^ 5 - 13 - 1 = 0 ∧ 5 * (13 : ZMod 19) ^ 4 - 1 = 0 := by decide
-- The cubic x^3 - x - 1 by Cardano: q^2/4 + p^3/27 = 23/108 and its discriminant is -23.
example : (-1 : ℚ) ^ 2 / 4 + (-1) ^ 3 / 27 = 23 / 108 := by norm_num
example : -4 * (-1 : ℤ) ^ 3 - 27 * (-1) ^ 2 = -23 := by norm_num
-- The solvable quintic x^5 - 5x + 12: discriminant 64,000,000 = 8,000^2.
example : (5 : ℤ) ^ 5 * 12 ^ 4 + 4 ^ 4 * (-5) ^ 5 = 64000000 ∧ (64000000 : ℤ) = 8000 ^ 2 := by
  norm_num

#print axioms roots_solvable_by_radicals_iff_galois_group_solvable
#print axioms galois_group_of_x5_sub_x_sub_one_is_all_120_shuffles
#print axioms no_root_of_x5_sub_x_sub_one_is_solvable_by_radicals
#print axioms kummer_step_aux
#print axioms radical_tower_aux
#print axioms roots_mem_solvableByRad_of_isSolvable
#print axioms isSolvable_of_roots_mem_solvableByRad
#print axioms quintic_reduction_mod_two
#print axioms card_rootSet_complex_of_irreducible
#print axioms ringOfIntegers_isInvariant
#print axioms selmer_five_exists_swap
