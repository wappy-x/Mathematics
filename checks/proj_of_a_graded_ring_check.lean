-- Proj: Proj of a graded ring is covered by the open sets D₊(f), one for each homogeneous f of positive degree, each isomorphic to Spec of the degree-zero fractions S_(f).
import Mathlib.AlgebraicGeometry.ProjectiveSpectrum.Basic
import Mathlib.RingTheory.MvPolynomial.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.MvPolynomial.Expand

open AlgebraicGeometry CategoryTheory MvPolynomial

universe u

/-- Proj of a graded ring `S` (its homogeneous prime ideals that do not contain the irrelevant
ideal `S₊`) is covered by the basic open sets `D₊(f)`, for `f` homogeneous of positive degree;
and each such `D₊(f)` is an affine scheme, isomorphic to `Spec S_(f)`, where `S_(f)` is the ring
of fractions `g / f ^ n` whose top and bottom have the same degree. -/
theorem proj_covered_by_spec_of_degree_zero_fractions
    {σ : Type*} {A : Type u} [CommRing A] [SetLike σ A] [AddSubgroupClass σ A]
    (𝒜 : ℕ → σ) [GradedRing 𝒜] :
    (∀ x : Proj 𝒜, ∃ (f : A) (m : ℕ), f ∈ 𝒜 m ∧ 0 < m ∧ x ∈ Proj.basicOpen 𝒜 f) ∧
    ∀ (f : A) (m : ℕ), f ∈ 𝒜 m → 0 < m →
      Nonempty ((Proj.basicOpen 𝒜 f).toScheme ≅
        Spec (CommRingCat.of (HomogeneousLocalization.Away 𝒜 f))) := by
  refine ⟨fun x => ?_, fun f m hf hm => ⟨Proj.basicOpenIsoSpec 𝒜 f hf hm⟩⟩
  have hcov := Proj.iSup_basicOpen_eq_top 𝒜 (ι := Σ i : PNat, 𝒜 i) (fun i ↦ (i.2 : A)) (by
    classical
    intro z hz
    rw [← DirectSum.sum_support_decompose 𝒜 z]
    refine Ideal.sum_mem _ fun c hc ↦ if hc0 : c = 0 then ?_ else
      Ideal.subset_span ⟨⟨⟨c, Nat.pos_iff_ne_zero.mpr hc0⟩, _⟩, rfl⟩
    convert Ideal.zero_mem _
    subst hc0
    exact hz)
  have hx : x ∈ (⊤ : (Proj 𝒜).Opens) := trivial
  rw [← hcov, TopologicalSpace.Opens.mem_iSup] at hx
  obtain ⟨i, hi⟩ := hx
  exact ⟨i.2, i.1, i.2.2, i.1.2, hi⟩

/-- The points of `D₊(f)` match the prime ideals of `S_(f)` one for one, and closed sets to closed
sets, when `f` is homogeneous of positive degree: the match sends a homogeneous prime `𝔭` to its
degree-zero fractions, so a fraction `g / f ^ n` lies in the image of `𝔭` exactly when `g ∈ 𝔭`. -/
theorem points_of_basicOpen_match_primes_of_degree_zero_fractions
    {σ : Type*} {A : Type*} [CommRing A] [SetLike σ A] [AddSubgroupClass σ A]
    (𝒜 : ℕ → σ) [GradedRing 𝒜] (f : A) {m : ℕ} (f_deg : f ∈ 𝒜 m) (hm : 0 < m) :
    ∃ e : {x : ProjectiveSpectrum 𝒜 // f ∉ x.asHomogeneousIdeal} ≃ₜ
        PrimeSpectrum (HomogeneousLocalization.Away 𝒜 f),
      ∀ (x : {x : ProjectiveSpectrum 𝒜 // f ∉ x.asHomogeneousIdeal})
        (z : HomogeneousLocalization.NumDenSameDeg 𝒜 (Submonoid.powers f)),
        HomogeneousLocalization.mk z ∈ (e x).asIdeal ↔
          (z.num : A) ∈ x.1.asHomogeneousIdeal := by
  exact ⟨TopCat.homeoOfIso (projIsoSpecTopComponent f_deg hm), fun x z =>
    ProjIsoSpecTopComponent.ToSpec.mk_mem_carrier x z⟩

/-- Every polynomial in `x, y, z` is, modulo `x * z - y ^ 2`, of the form `a(x, z) + y * b(x, z)`. -/
lemma conic_normal_form {k : Type*} [Field k] (p : MvPolynomial (Fin 3) k) :
    ∃ (q : MvPolynomial (Fin 3) k) (a b : MvPolynomial (Fin 2) k),
      p = q * (X 0 * X 2 - X 1 ^ 2) + rename ![(0 : Fin 3), 2] a +
        X 1 * rename ![(0 : Fin 3), 2] b := by
  induction p using MvPolynomial.induction_on with
  | C c => exact ⟨0, C c, 0, by simp⟩
  | add p₁ p₂ h₁ h₂ =>
    obtain ⟨q₁, a₁, b₁, e₁⟩ := h₁
    obtain ⟨q₂, a₂, b₂, e₂⟩ := h₂
    exact ⟨q₁ + q₂, a₁ + a₂, b₁ + b₂, by rw [e₁, e₂]; simp only [map_add]; ring⟩
  | mul_X p n h =>
    obtain ⟨q, a, b, e⟩ := h
    fin_cases n
    · refine ⟨q * X 0, a * X 0, b * X 0, ?_⟩
      simp only [map_mul, rename_X]
      simp only [Fin.isValue, Matrix.cons_val_zero, Fin.zero_eta]
      rw [e]; ring
    · refine ⟨q * X 1 - rename ![(0 : Fin 3), 2] b, X 0 * X 1 * b, a, ?_⟩
      simp only [map_mul, rename_X]
      simp only [Fin.isValue, Matrix.cons_val_zero, Matrix.cons_val_one, Fin.mk_one]
      rw [e]; ring
    · refine ⟨q * X 2, a * X 1, b * X 1, ?_⟩
      show p * X 2 = _
      simp only [map_mul, rename_X]
      rw [show (![(0 : Fin 3), 2] : Fin 2 → Fin 3) 1 = 2 from rfl, e]; ring

/-- Under `x ↦ s ^ 2, y ↦ s * t, z ↦ t ^ 2`, the polynomial `a(x, z)` goes to `a(s ^ 2, t ^ 2)`. -/
lemma conic_aeval_rename {k : Type*} [Field k] (a : MvPolynomial (Fin 2) k) :
    MvPolynomial.aeval (R := k)
        (![X 0 ^ 2, X 0 * X 1, X 1 ^ 2] : Fin 3 → MvPolynomial (Fin 2) k)
        (rename ![(0 : Fin 3), 2] a) = expand 2 a := by
  rw [aeval_rename]
  have : (![X 0 ^ 2, X 0 * X 1, X 1 ^ 2] : Fin 3 → MvPolynomial (Fin 2) k) ∘
      ![(0 : Fin 3), 2] = fun i => X i ^ 2 := by
    funext i; fin_cases i <;> rfl
  rw [this]
  rfl

/-- If `a(s ^ 2, t ^ 2) + s * t * b(s ^ 2, t ^ 2) = 0` then `a = 0` and `b = 0`. -/
lemma conic_parity {k : Type*} [Field k] (a b : MvPolynomial (Fin 2) k)
    (h : expand 2 a + X 0 * X 1 * expand 2 b = 0) : a = 0 ∧ b = 0 := by
  classical
  have hm : (X 0 * X 1 : MvPolynomial (Fin 2) k) =
      monomial (Finsupp.single 0 1 + Finsupp.single 1 1) 1 := by
    rw [X, X, monomial_mul_monomial, one_mul]
  have ha : a = 0 := by
    ext m
    have h1 := congrArg (fun p => p.coeff (2 • m)) h
    simp only [AddMonoidAlgebra.coeff_add, Finsupp.add_apply] at h1
    rw [hm, coeff_monomial_mul', coeff_expand_smul 2 two_ne_zero] at h1
    split_ifs at h1 with hle
    · rw [coeff_expand_of_not_dvd (i := 0)] at h1
      · simpa using h1
      · intro hd
        have h0 := hle 0
        simp only [Finsupp.coe_add, Pi.add_apply, Finsupp.single_eq_same,
          Finsupp.smul_apply, smul_eq_mul, Finsupp.coe_tsub, Pi.sub_apply] at h0 hd ⊢
        simp only [Finsupp.single_apply, Fin.isValue, one_ne_zero, ↓reduceIte, add_zero] at h0 hd
        omega
    · simpa using h1
  subst ha
  rw [map_zero, zero_add, mul_eq_zero] at h
  refine ⟨rfl, ?_⟩
  rcases h with h | h
  · exfalso
    exact mul_ne_zero (X_ne_zero 0) (X_ne_zero 1) h
  · exact (expand_eq_zero two_pos).mp h

#print axioms conic_normal_form
#print axioms conic_aeval_rename
#print axioms conic_parity

/-- The conic is the projective line: over a field `k`, the ring map
`x ↦ s ^ 2, y ↦ s * t, z ↦ t ^ 2` from `k[x, y, z]` to `k[s, t]` has kernel exactly the ideal
`(x * z - y ^ 2)`, so the conic's ring is the even-degree (Veronese) part of `k[s, t]`. -/
theorem kernel_of_conic_parametrisation_is_conic_ideal (k : Type*) [Field k] :
    RingHom.ker
        (MvPolynomial.aeval (R := k)
          (![X 0 ^ 2, X 0 * X 1, X 1 ^ 2] : Fin 3 → MvPolynomial (Fin 2) k)).toRingHom =
      Ideal.span {(X 0 * X 2 - X 1 ^ 2 : MvPolynomial (Fin 3) k)} := by
  have hg : MvPolynomial.aeval (R := k)
      (![X 0 ^ 2, X 0 * X 1, X 1 ^ 2] : Fin 3 → MvPolynomial (Fin 2) k)
      (X 0 * X 2 - X 1 ^ 2 : MvPolynomial (Fin 3) k) = 0 := by
    simp only [map_sub, map_mul, map_pow, aeval_X]
    change (X 0 ^ 2) * (X 1 ^ 2) - (X 0 * X 1) ^ 2 = (0 : MvPolynomial (Fin 2) k)
    ring
  ext p
  rw [RingHom.mem_ker, Ideal.mem_span_singleton']
  constructor
  · intro hp
    obtain ⟨q, a, b, e⟩ := conic_normal_form p
    change MvPolynomial.aeval _ p = 0 at hp
    rw [e, map_add, map_add, map_mul, map_mul, hg, mul_zero, zero_add, conic_aeval_rename,
      conic_aeval_rename, aeval_X] at hp
    have hX : (![X 0 ^ 2, X 0 * X 1, X 1 ^ 2] : Fin 3 → MvPolynomial (Fin 2) k) 1 = X 0 * X 1 :=
      rfl
    rw [hX] at hp
    obtain ⟨rfl, rfl⟩ := conic_parity a b hp
    exact ⟨q, by rw [e]; simp⟩
  · rintro ⟨c, rfl⟩
    change MvPolynomial.aeval _ (c * _) = 0
    rw [map_mul, hg, mul_zero]

/- The card's worked numbers over F_7. -/

-- The affine cone xz = y² in F_7³ has 49 points: the tip plus 48 nonzero ones.
example : (Finset.univ.filter
    (fun v : ZMod 7 × ZMod 7 × ZMod 7 => v.1 * v.2.2 = v.2.1 ^ 2)).card = 49 := by
  decide

-- Each line through the tip holds 6 nonzero points, so the conic has (49 - 1)/6 = 8 points.
example : (49 - 1) / 6 = 8 := by norm_num

-- The chart D₊(x) of the conic is v = u²: 7 points over F_7.
example : (Finset.univ.filter (fun v : ZMod 7 × ZMod 7 => v.2 = v.1 ^ 2)).card = 7 := by
  decide

-- The chart ring D₊(x) ∩ D₊(z) is ce = 1: 6 points, and 7 + 7 - 6 = 8.
example : (Finset.univ.filter (fun v : ZMod 7 × ZMod 7 => v.1 * v.2 = 1)).card = 6 := by
  decide

example : 7 + 7 - 6 = 8 := by norm_num

-- The whole localisation F_7[x, y, 1/x]: 42 points, not 7.
example : (Finset.univ.filter (fun v : ZMod 7 × ZMod 7 => v.1 ≠ 0)).card = 42 := by
  decide

-- (1 : 2) ↦ (1² : 1 · 2 : 2²) = (1 : 2 : 4).
example : ((1 : ℕ) ^ 2, 1 * 2, (2 : ℕ) ^ 2) = (1, 2, 4) := by norm_num

-- dim S_3 of the conic: C(5, 2) - C(3, 2) = 10 - 3 = 7 = 2 · 3 + 1.
example : Nat.choose 5 2 - Nat.choose 3 2 = 2 * 3 + 1 := by decide

-- The closed points of degree 2 of P¹ over F_7: forms ax² + bxy + cy² with no root on the line,
-- 126 of them, which is 21 up to the 6 nonzero scalars; and 8 + 2 · 21 = 7² + 1.
set_option maxRecDepth 100000 in
example : (Finset.univ.filter (fun v : ZMod 7 × ZMod 7 × ZMod 7 =>
    v.2.2 ≠ 0 ∧ ∀ t : ZMod 7, v.1 + v.2.1 * t + v.2.2 * t ^ 2 ≠ 0)).card = 6 * 21 := by
  decide

example : 8 + 2 * 21 = 7 ^ 2 + 1 := by norm_num

example : 8 + 3 * 112 = 7 ^ 3 + 1 := by norm_num

-- The rational point (3 : 5) lands on (1 : 4) over 7: 3⁻¹ = 5 mod 7, and 5 · 5 = 25 = 4 mod 7.
example : (3 : ZMod 7) * 5 = 1 ∧ (5 : ZMod 7) * 5 = 4 := by decide

#print axioms proj_covered_by_spec_of_degree_zero_fractions
#print axioms points_of_basicOpen_match_primes_of_degree_zero_fractions
#print axioms kernel_of_conic_parametrisation_is_conic_ideal
