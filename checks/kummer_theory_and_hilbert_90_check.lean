-- Kummer and Artin-Schreier: in a cyclic Galois extension an element has norm 1 exactly when it is β/σ(β) and trace 0 exactly when it is β − σ(β), so with the nth roots of 1 in the base field the extension is made by one nth root, and in characteristic p a cyclic extension of degree p is made by one root of x^p − x − a.
import Mathlib.RepresentationTheory.Homological.GroupCohomology.Hilbert90
import Mathlib.FieldTheory.KummerExtension
import Mathlib.RingTheory.Trace.Basic
import Mathlib.Basic.Complex.Basic

open IntermediateField

/-- An element fixed by a generator of a cyclic Galois group lies in the base field. -/
theorem kh90_mem_range_of_fixed {K L : Type*} [Field K] [Field L] [Algebra K L]
    [FiniteDimensional K L] [IsGalois K L] (σ : Gal(L/K))
    (hσ : ∀ τ : Gal(L/K), τ ∈ Subgroup.zpowers σ) {x : L} (hx : σ x = x) :
    x ∈ Set.range (algebraMap K L) := by
  rw [IsGalois.mem_range_algebraMap_iff_fixed]
  intro τ
  obtain ⟨k, rfl : σ ^ k = τ⟩ := mem_powers_iff_mem_zpowers.mpr (hσ τ)
  induction k with
  | zero => simp
  | succ k ih => rw [pow_succ, AlgEquiv.mul_apply, hx, ih]

/-- A product over the powers σ^0, ..., σ^(m-1), m the order of a generator σ, runs over the
whole Galois group once. -/
theorem kh90_prod_range_pow {K L : Type*} [Field K] [Field L] [Algebra K L]
    [FiniteDimensional K L] (σ : Gal(L/K))
    (hσ : ∀ τ : Gal(L/K), τ ∈ Subgroup.zpowers σ) {M : Type*} [CommMonoid M]
    (F : Gal(L/K) → M) :
    ∏ i ∈ Finset.range (orderOf σ), F (σ ^ i) = ∏ τ, F τ := by
  classical
  rw [← Finset.prod_image (f := F) (g := fun i => σ ^ i)]
  · congr 1
    ext τ
    simp only [Finset.mem_image, Finset.mem_range, Finset.mem_univ, iff_true]
    obtain ⟨k, rfl : σ ^ k = τ⟩ := mem_powers_iff_mem_zpowers.mpr (hσ τ)
    exact ⟨k % orderOf σ, Nat.mod_lt _ (orderOf_pos σ), pow_mod_orderOf σ k⟩
  · intro x hx y hy h
    exact pow_injOn_Iio_orderOf (by simpa using hx) (by simpa using hy) h

/-- If no nontrivial power of a generator fixes b, then b generates the extension. -/
theorem kh90_adjoin_eq_top {K L : Type*} [Field K] [Field L] [Algebra K L]
    [FiniteDimensional K L] [IsGalois K L] (σ : Gal(L/K))
    (hσ : ∀ τ : Gal(L/K), τ ∈ Subgroup.zpowers σ) (b : L)
    (hb : ∀ k : ℕ, (σ ^ k) b = b → σ ^ k = 1) : K⟮b⟯ = ⊤ := by
  apply IsGalois.intermediateFieldEquivSubgroup.injective
  rw [map_top, eq_top_iff]
  intro τ hτ
  obtain ⟨k, rfl : σ ^ k = τ⟩ := mem_powers_iff_mem_zpowers.mpr (hσ τ)
  have := hτ ⟨b, IntermediateField.mem_adjoin_simple_self K b⟩
  simp only [AlgEquiv.smul_def] at this
  rw [hb k this]
  exact one_mem _


/-- Hilbert's Theorem 90, both forms. Let L/K be a finite Galois extension whose symmetries
are all repeats of one symmetry σ (a cyclic extension). Then an element α of L has norm 1
exactly when α = β/σ(β) for some nonzero β in L, and α has trace 0 exactly when
α = β − σ(β) for some β in L. -/
theorem hilbert_90 {K L : Type*} [Field K] [Field L] [Algebra K L] [FiniteDimensional K L]
    [IsGalois K L] (σ : Gal(L/K)) (hσ : ∀ τ : Gal(L/K), τ ∈ Subgroup.zpowers σ) (α : L) :
    (Algebra.norm K α = 1 ↔ ∃ β : L, β ≠ 0 ∧ α = β / σ β) ∧
      (Algebra.trace K L α = 0 ↔ ∃ β : L, α = β - σ β) := by
  refine ⟨⟨fun h => ?_, ?_⟩, ⟨fun h => ?_, ?_⟩⟩
  · set n := orderOf σ with hn
    have hn0 : 0 < n := orderOf_pos σ
    let c : ℕ → L := fun i => ∏ j ∈ Finset.range i, (σ ^ j) α
    have hc0 : c 0 = 1 := by simp [c]
    have hcn : c n = 1 := by
      simp only [c]
      rw [kh90_prod_range_pow σ hσ (fun τ => τ α), ← Algebra.norm_eq_prod_automorphisms, h,
        map_one]
    have hcs : ∀ i, α * σ (c i) = c (i + 1) := by
      intro i
      simp only [c]
      rw [map_prod, Finset.prod_range_succ']
      simp_rw [← AlgEquiv.mul_apply, ← pow_succ', pow_zero, AlgEquiv.one_apply]
      ring
    have hinj : Function.Injective
        (fun i : Fin n => ((σ ^ (i : ℕ) : Gal(L/K)) : L →* L)) := by
      intro i j hij
      have h1 : σ ^ (i : ℕ) = σ ^ (j : ℕ) := by
        ext x
        exact DFunLike.ext_iff.1 hij x
      exact Fin.ext (pow_injOn_Iio_orderOf (Set.mem_Iio.2 i.2) (Set.mem_Iio.2 j.2) h1)
    have hli : LinearIndependent L
        (fun i : Fin n => (((σ ^ (i : ℕ) : Gal(L/K)) : L →* L) : L → L)) :=
      (linearIndependent_monoidHom L L).comp _ hinj
    obtain ⟨x, hx⟩ : ∃ x, ∑ i ∈ Finset.range n, c i * (σ ^ i) x ≠ 0 := by
      by_contra hcon
      push Not at hcon
      have hsum : ∑ i : Fin n, c i • (((σ ^ (i : ℕ) : Gal(L/K)) : L →* L) : L → L) = 0 := by
        funext x
        simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply]
        have hco : ∀ i : Fin n, (((σ ^ (i : ℕ) : Gal(L/K)) : L →* L) x) = (σ ^ (i : ℕ)) x :=
          fun i => rfl
        simp_rw [hco]
        rw [Fin.sum_univ_eq_sum_range (fun i => c i * (σ ^ i) x)]
        exact hcon x
      have := Fintype.linearIndependent_iff.1 hli (fun i => c i) hsum ⟨0, hn0⟩
      simp [hc0] at this
    set β := ∑ i ∈ Finset.range n, c i * (σ ^ i) x with hβdef
    have hσβ : α * σ β = β := by
      have e1 : α * σ β = ∑ i ∈ Finset.range n, c (i + 1) * (σ ^ (i + 1)) x := by
        rw [hβdef, map_sum, Finset.mul_sum]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [map_mul, ← mul_assoc, hcs, ← AlgEquiv.mul_apply, ← pow_succ']
      have e2 := Finset.sum_range_succ' (fun i => c i * (σ ^ i) x) n
      have e3 := Finset.sum_range_succ (fun i => c i * (σ ^ i) x) n
      have e4 : c n * (σ ^ n) x = c 0 * (σ ^ 0) x := by
        rw [hcn, hc0, hn, pow_orderOf_eq_one, pow_zero]
      rw [e1, hβdef]
      rw [e3, e4] at e2
      linear_combination e2.symm
    have hσβ0 : σ β ≠ 0 := by simpa using hx
    refine ⟨β, hx, ?_⟩
    rw [eq_div_iff hσβ0]
    exact hσβ
  · rintro ⟨β, hβ, rfl⟩
    rw [div_eq_mul_inv, map_mul, Algebra.norm_inv, Algebra.norm_eq_of_algEquiv,
      mul_inv_cancel₀ (Algebra.norm_ne_zero_iff.mpr hβ)]
  · let f : L →ₗ[K] L := LinearMap.id - σ.toLinearMap
    have hrange : LinearMap.range f = LinearMap.ker (Algebra.trace K L) := by
      apply Submodule.eq_of_le_of_finrank_le
      · rintro _ ⟨β, rfl⟩
        simp [f, LinearMap.mem_ker, Algebra.trace_eq_of_algEquiv]
      · have h1 := LinearMap.finrank_range_add_finrank_ker f
        have h2 := LinearMap.finrank_range_add_finrank_ker (Algebra.trace K L)
        have h3 : Module.finrank K (LinearMap.range (Algebra.trace K L)) = 1 := by
          rw [LinearMap.range_eq_top.mpr (Algebra.trace_surjective K L), finrank_top,
            Module.finrank_self]
        have h4 : Module.finrank K (LinearMap.ker f) ≤ 1 := by
          have hle : LinearMap.ker f ≤ LinearMap.range (Algebra.linearMap K L) := by
            intro x hx
            have hx' : σ x = x := by
              simp [f, sub_eq_zero] at hx
              exact hx.symm
            obtain ⟨a, ha⟩ := kh90_mem_range_of_fixed σ hσ hx'
            exact ⟨a, ha⟩
          calc Module.finrank K (LinearMap.ker f)
              ≤ Module.finrank K (LinearMap.range (Algebra.linearMap K L)) :=
                Submodule.finrank_mono hle
            _ ≤ Module.finrank K K := LinearMap.finrank_range_le _
            _ = 1 := Module.finrank_self K
        omega
    have hα : α ∈ LinearMap.range f := hrange ▸ h
    obtain ⟨β, hβ⟩ := hα
    exact ⟨β, hβ.symm⟩
  · rintro ⟨β, rfl⟩
    rw [map_sub, Algebra.trace_eq_of_algEquiv, sub_self]

/-- Kummer: let K hold a primitive nth root of 1, ζ, with the characteristic of K not
dividing n, and let L/K be a cyclic Galois extension of degree n with generator σ. Then
L = K(b) for some b that σ multiplies by ζ, and bⁿ lies in K. -/
theorem kummer_cyclic_extension_eq_adjoin_root {K L : Type*} [Field K] [Field L] [Algebra K L]
    [FiniteDimensional K L] [IsGalois K L] {n : ℕ} (hn : Module.finrank K L = n)
    (σ : Gal(L/K)) (hσ : ∀ τ : Gal(L/K), τ ∈ Subgroup.zpowers σ)
    {ζ : K} (hζ : IsPrimitiveRoot ζ n) (hchar : (n : K) ≠ 0) :
    ∃ b : L, σ b = algebraMap K L ζ * b ∧ b ^ n ∈ Set.range (algebraMap K L) ∧ K⟮b⟯ = ⊤ := by
  have hn0 : 0 < n := hn ▸ Module.finrank_pos
  have hord : orderOf σ = n := by
    rw [orderOf_eq_card_of_forall_mem_zpowers hσ, IsGalois.card_aut_eq_finrank, hn]
  have hnorm : Algebra.norm K (algebraMap K L ζ⁻¹) = 1 := by
    rw [Algebra.norm_algebraMap, hn, inv_pow, hζ.pow_eq_one, inv_one]
  obtain ⟨b, hb0, hb⟩ := (hilbert_90 σ hσ _).1.1 hnorm
  have hζ0 : algebraMap K L ζ ≠ 0 := by
    simpa using hζ.ne_zero hn0.ne'
  have hσb0 : σ b ≠ 0 := by simpa using hb0
  have hσb : σ b = algebraMap K L ζ * b := by
    rw [map_inv₀, eq_div_iff hσb0] at hb
    calc σ b = algebraMap K L ζ * ((algebraMap K L ζ)⁻¹ * σ b) := by field_simp
      _ = algebraMap K L ζ * b := by rw [hb]
  have hpow : ∀ k : ℕ, (σ ^ k) b = algebraMap K L ζ ^ k * b := by
    intro k
    induction k with
    | zero => simp
    | succ k ih => rw [pow_succ, AlgEquiv.mul_apply, hσb, map_mul, AlgEquiv.commutes, ih]; ring
  refine ⟨b, hσb, ?_, ?_⟩
  · apply kh90_mem_range_of_fixed σ hσ
    rw [map_pow, hσb, mul_pow, ← map_pow, hζ.pow_eq_one, map_one, one_mul]
  · apply kh90_adjoin_eq_top σ hσ b
    intro k hk
    rw [hpow k] at hk
    have h1 : algebraMap K L (ζ ^ k) = algebraMap K L 1 := by
      rw [map_pow, map_one]
      exact (mul_eq_right₀ hb0).mp hk
    have h2 : ζ ^ k = 1 := (algebraMap K L).injective h1
    rw [← orderOf_dvd_iff_pow_eq_one, hord]
    exact hζ.dvd_of_pow_eq_one k h2

/-- Artin-Schreier: let K have characteristic p, a prime, and let L/K be a cyclic Galois
extension of degree p with generator σ. Then L = K(b) for some b that σ moves to b + 1,
and bᵖ − b lies in K, so b is a root of x^p − x − a with a in K. -/
theorem artin_schreier_cyclic_extension_eq_adjoin_root {K L : Type*} [Field K] [Field L]
    [Algebra K L] [FiniteDimensional K L] [IsGalois K L] {p : ℕ} (hp : p.Prime) [CharP K p]
    (hdeg : Module.finrank K L = p)
    (σ : Gal(L/K)) (hσ : ∀ τ : Gal(L/K), τ ∈ Subgroup.zpowers σ) :
    ∃ b : L, σ b = b + 1 ∧ b ^ p - b ∈ Set.range (algebraMap K L) ∧ K⟮b⟯ = ⊤ := by
  have : CharP L p := charP_of_injective_algebraMap (algebraMap K L).injective p
  have : Fact p.Prime := ⟨hp⟩
  have hord : orderOf σ = p := by
    rw [orderOf_eq_card_of_forall_mem_zpowers hσ, IsGalois.card_aut_eq_finrank, hdeg]
  have htr : Algebra.trace K L (-1) = 0 := by
    have h1 : (1 : L) = algebraMap K L 1 := (map_one _).symm
    rw [map_neg, h1, Algebra.trace_algebraMap, hdeg, nsmul_eq_mul, mul_one,
      CharP.cast_eq_zero, neg_zero]
  obtain ⟨b, hb⟩ := (hilbert_90 σ hσ (-1)).2.1 htr
  have hσb : σ b = b + 1 := by linear_combination hb
  have hpow : ∀ k : ℕ, (σ ^ k) b = b + k := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      rw [pow_succ, AlgEquiv.mul_apply, hσb, map_add, map_one, ih]
      push_cast; ring
  refine ⟨b, hσb, ?_, ?_⟩
  · apply kh90_mem_range_of_fixed σ hσ
    rw [map_sub, map_pow, hσb, add_pow_char, one_pow]
    ring
  · apply kh90_adjoin_eq_top σ hσ b
    intro k hk
    rw [hpow k] at hk
    have h1 : (k : L) = 0 := by linear_combination hk
    rw [CharP.cast_eq_zero_iff L p] at h1
    rw [← orderOf_dvd_iff_pow_eq_one, hord]
    exact h1

-- Hilbert 90 in Q(i)/Q: 3/5 + 4i/5 has norm 1, and it equals (2 + i)/(2 − i);
-- (2 + i)^2 = 3 + 4i and 2^2 + 1^2 = 5 give the triple 3, 4, 5.
example : (3 / 5 : ℚ) ^ 2 + (4 / 5) ^ 2 = 1 := by norm_num
example : ((2 : ℂ) + Complex.I) / (2 - Complex.I) = 3 / 5 + 4 / 5 * Complex.I := by
  have h : (2 : ℂ) - Complex.I ≠ 0 := by
    intro h; have := congrArg Complex.re h; norm_num at this
  rw [div_eq_iff h]
  ring_nf
  rw [Complex.I_sq]
  ring
example : ((2 : ℂ) + Complex.I) ^ 2 = 3 + 4 * Complex.I := by
  ring_nf; rw [Complex.I_sq]; ring
example : (2 ^ 2 - 1 ^ 2, 2 * 2 * 1, 2 ^ 2 + 1 ^ 2) = (3, 4, 5) ∧ 3 ^ 2 + 4 ^ 2 = 5 ^ 2 := by
  decide

-- The resolvent of x^3 − 3x + 1 over Q(ω): b = (2 + 4ω) + (1 − ω)t + (−1 − 2ω)t^2
-- has b^3 = −27 − 27ω = 27ω^2, wherever ω^2 + ω + 1 = 0 and t^3 − 3t + 1 = 0.
example {R : Type*} [CommRing R] (ω t : R) (hω : ω ^ 2 + ω + 1 = 0)
    (ht : t ^ 3 - 3 * t + 1 = 0) :
    ((2 + 4 * ω) + (1 - ω) * t + (-1 - 2 * ω) * t ^ 2) ^ 3 = -27 - 27 * ω ∧
      -27 - 27 * ω = 27 * ω ^ 2 := by
  grind

-- Over F_3: x^3 − x − 1 has no root, so it is irreducible.
example : ∀ x : ZMod 3, x ^ 3 - x - 1 ≠ 0 := by decide
-- x^3 − x − a has 3, 0, 0 roots in F_3 for a = 0, 1, 2.
example : ((Finset.univ : Finset (ZMod 3)).filter (fun x => x ^ 3 - x - 0 = 0)).card = 3 ∧
    ((Finset.univ : Finset (ZMod 3)).filter (fun x => x ^ 3 - x - 1 = 0)).card = 0 ∧
    ((Finset.univ : Finset (ZMod 3)).filter (fun x => x ^ 3 - x - 2 = 0)).card = 0 := by
  decide
-- In characteristic 3, (x − c)^3 = x^3 − c for c in F_3: cube roots build nothing.
example : ∀ x c : ZMod 3, (x - c) ^ 3 = x ^ 3 - c := by decide

#print axioms kh90_mem_range_of_fixed
#print axioms kh90_prod_range_pow
#print axioms kh90_adjoin_eq_top
#print axioms hilbert_90
#print axioms kummer_cyclic_extension_eq_adjoin_root
#print axioms artin_schreier_cyclic_extension_eq_adjoin_root
