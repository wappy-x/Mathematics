-- Degree: every plane meets the twisted cubic in exactly 3 points counted over ℂ, at infinity and with multiplicity, its Hilbert function is 3t + 1, and slicing a variety by a plane subtracts one step of its Hilbert function.
import Mathlib.RingTheory.MvPolynomial.Homogeneous
import Mathlib.RingTheory.Ideal.Span
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Algebra.Polynomial.Basis
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.Tactic.ComputeDegree
import Mathlib.Tactic.LinearCombination

/-! The field is `K` (the card's k). Polynomials in the variables `σ` are `MvPolynomial σ K`;
the degree-t forms are Mathlib's `homogeneousSubmodule σ K t`. For the twisted cubic the
variables are `Fin 4`, with `X 0, X 1, X 2, X 3` the card's x, y, z, w. -/

open MvPolynomial

namespace DegreeCard

/-- The card's Hilbert function `HF(t)`: the dimension over K of the degree-t forms, with two
counted as equal when they differ by a member of the ideal `I` (that is, of `I_t`). -/
noncomputable def hilbertFn {σ K : Type*} [Field K] (I : Ideal (MvPolynomial σ K)) (t : ℕ) : ℕ :=
  Module.finrank K (homogeneousSubmodule σ K t ⧸
    (I.restrictScalars K).comap (homogeneousSubmodule σ K t).subtype)

/-- The twisted cubic's ideal ⟨x² − yw, xy − zw, y² − xz⟩ in K[x, y, z, w]. -/
noncomputable def twistedCubicIdeal (K : Type*) [Field K] : Ideal (MvPolynomial (Fin 4) K) :=
  Ideal.span {X 0 ^ 2 - X 1 * X 3, X 0 * X 1 - X 2 * X 3, X 1 ^ 2 - X 0 * X 2}

/-- The monomial x^i y^j z^k w^l. -/
noncomputable def cubicMon (K : Type*) [Field K] (i j k l : ℕ) : MvPolynomial (Fin 4) K :=
  X 0 ^ i * X 1 ^ j * X 2 ^ k * X 3 ^ l

/-- The standard monomial of degree t whose image on the curve (w = 1) is u^n. -/
noncomputable def cubicStd (K : Type*) [Field K] (t n : ℕ) : MvPolynomial (Fin 4) K :=
  if n % 3 = 0 then X 2 ^ (n / 3) * X 3 ^ (t - n / 3)
  else if n % 3 = 1 then X 0 * X 2 ^ (n / 3) * X 3 ^ (t - n / 3 - 1)
  else X 1 * X 2 ^ (n / 3) * X 3 ^ (t - n / 3 - 1)

theorem cubicMon_eq_std_of_le_one (K : Type*) [Field K] (i j k l t n : ℕ) (hij : i + j ≤ 1)
    (ht : t = i + j + k + l) (hn : n = i + 2 * j + 3 * k) :
    cubicMon K i j k l = cubicStd K t n := by
  rcases (show (i = 0 ∧ j = 0) ∨ (i = 1 ∧ j = 0) ∨ (i = 0 ∧ j = 1) by omega) with
    ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
  · have h1 : n % 3 = 0 := by omega
    have h2 : n / 3 = k := by omega
    have h3 : t - k = l := by omega
    simp [cubicStd, cubicMon, h1, h2, h3]
  · have h1 : n % 3 = 1 := by omega
    have h2 : n / 3 = k := by omega
    have h3 : t - k - 1 = l := by omega
    simp [cubicStd, cubicMon, h1, h2, h3]
  · have h1 : n % 3 = 2 := by omega
    have h2 : n / 3 = k := by omega
    have h3 : t - k - 1 = l := by omega
    simp [cubicStd, cubicMon, h1, h2, h3]

#print axioms cubicMon_eq_std_of_le_one

theorem cubicMon_sub_std_mem (K : Type*) [Field K] (s : ℕ) :
    ∀ i j k l t n : ℕ, i + j ≤ s → t = i + j + k + l → n = i + 2 * j + 3 * k →
      cubicMon K i j k l - cubicStd K t n ∈ twistedCubicIdeal K := by
  induction s with
  | zero =>
    intro i j k l t n hs ht hn
    rw [cubicMon_eq_std_of_le_one K i j k l t n (by omega) ht hn, sub_self]
    exact Ideal.zero_mem _
  | succ s ih =>
    intro i j k l t n hs ht hn
    have gen : ∀ g ∈ ({X 0 ^ 2 - X 1 * X 3, X 0 * X 1 - X 2 * X 3, X 1 ^ 2 - X 0 * X 2} :
        Set (MvPolynomial (Fin 4) K)), ∀ m, m * g ∈ twistedCubicIdeal K :=
      fun g hg m => Ideal.mul_mem_left _ m (Ideal.subset_span hg)
    by_cases h1 : i + j ≤ 1
    · rw [cubicMon_eq_std_of_le_one K i j k l t n h1 ht hn, sub_self]
      exact Ideal.zero_mem _
    by_cases hi : 2 ≤ i
    · obtain ⟨i, rfl⟩ : ∃ i', i = i' + 2 := ⟨i - 2, by omega⟩
      have e : cubicMon K (i + 2) j k l - cubicStd K t n =
          cubicMon K i j k l * (X 0 ^ 2 - X 1 * X 3) +
            (cubicMon K i (j + 1) k (l + 1) - cubicStd K t n) := by
        simp only [cubicMon]; ring
      rw [e]
      exact Ideal.add_mem _ (gen _ (by simp) _) (ih _ _ _ _ _ _ (by omega) (by omega) (by omega))
    by_cases hj : 2 ≤ j
    · obtain ⟨j, rfl⟩ : ∃ j', j = j' + 2 := ⟨j - 2, by omega⟩
      have e : cubicMon K i (j + 2) k l - cubicStd K t n =
          cubicMon K i j k l * (X 1 ^ 2 - X 0 * X 2) +
            (cubicMon K (i + 1) j (k + 1) l - cubicStd K t n) := by
        simp only [cubicMon]; ring
      rw [e]
      exact Ideal.add_mem _ (gen _ (by simp) _) (ih _ _ _ _ _ _ (by omega) (by omega) (by omega))
    obtain ⟨rfl, rfl⟩ : i = 1 ∧ j = 1 := by omega
    have e : cubicMon K 1 1 k l - cubicStd K t n =
        cubicMon K 0 0 k l * (X 0 * X 1 - X 2 * X 3) +
          (cubicMon K 0 0 (k + 1) (l + 1) - cubicStd K t n) := by
      simp only [cubicMon]; ring
    rw [e]
    exact Ideal.add_mem _ (gen _ (by simp) _) (ih _ _ _ _ _ _ (by omega) (by omega) (by omega))

#print axioms cubicMon_sub_std_mem

theorem cubicStd_mem (K : Type*) [Field K] (t n : ℕ) (hn : n ≤ 3 * t) :
    cubicStd K t n ∈ homogeneousSubmodule (Fin 4) K t := by
  rw [mem_homogeneousSubmodule]
  unfold cubicStd
  split_ifs with h0 h1
  · have := (isHomogeneous_X_pow (R := K) (2 : Fin 4) (n / 3)).mul
      (isHomogeneous_X_pow (R := K) (3 : Fin 4) (t - n / 3))
    rwa [show n / 3 + (t - n / 3) = t by omega] at this
  · have := ((isHomogeneous_X (R := K) (0 : Fin 4)).mul
      (isHomogeneous_X_pow (R := K) (2 : Fin 4) (n / 3))).mul
      (isHomogeneous_X_pow (R := K) (3 : Fin 4) (t - n / 3 - 1))
    rwa [show 1 + n / 3 + (t - n / 3 - 1) = t by omega] at this
  · have := ((isHomogeneous_X (R := K) (1 : Fin 4)).mul
      (isHomogeneous_X_pow (R := K) (2 : Fin 4) (n / 3))).mul
      (isHomogeneous_X_pow (R := K) (3 : Fin 4) (t - n / 3 - 1))
    rwa [show 1 + n / 3 + (t - n / 3 - 1) = t by omega] at this

#print axioms cubicStd_mem

/-- The curve's parametrization with w = 1: x ↦ u, y ↦ u², z ↦ u³, w ↦ 1. -/
noncomputable def cubicParam (K : Type*) [Field K] : MvPolynomial (Fin 4) K →ₐ[K] Polynomial K :=
  aeval ![Polynomial.X, Polynomial.X ^ 2, Polynomial.X ^ 3, 1]

theorem cubicParam_std (K : Type*) [Field K] (t n : ℕ) :
    cubicParam K (cubicStd K t n) = Polynomial.X ^ n := by
  unfold cubicStd
  split_ifs with h0 h1
  · simp [cubicParam, ← pow_mul]
    congr 1; omega
  · simp [cubicParam, ← pow_mul, ← pow_succ']
    congr 1; omega
  · simp [cubicParam, ← pow_mul, ← pow_add]
    congr 1; omega

#print axioms cubicParam_std

theorem cubicParam_ideal (K : Type*) [Field K] (p : MvPolynomial (Fin 4) K)
    (hp : p ∈ twistedCubicIdeal K) : cubicParam K p = 0 := by
  have : twistedCubicIdeal K ≤ RingHom.ker (cubicParam K) := by
    apply Ideal.span_le.mpr
    intro g hg
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hg
    rcases hg with rfl | rfl | rfl <;> simp [cubicParam, RingHom.mem_ker] <;> ring
  exact this hp

#print axioms cubicParam_ideal

theorem homogeneousComponent_mul_linear {σ K : Type*} [Field K]
    (h : MvPolynomial σ K) (hlin : h.IsHomogeneous 1) (a : MvPolynomial σ K) (n : ℕ) :
    homogeneousComponent (n + 1) (a * h) = homogeneousComponent n a * h := by
  induction a using MvPolynomial.induction_on' with
  | monomial d c =>
    have h1 : monomial d c * h ∈ homogeneousSubmodule σ K (d.degree + 1) :=
      (isHomogeneous_monomial c rfl).mul hlin
    rw [homogeneousComponent_of_mem h1,
      homogeneousComponent_of_mem (isHomogeneous_monomial (R := K) c (d := d) rfl)]
    by_cases hn : n = d.degree
    · simp [hn]
    · simp [hn]
  | add p q hp hq => simp [add_mul, hp, hq]

#print axioms homogeneousComponent_mul_linear

theorem finite_homogeneousSubmodule {σ K : Type*} [Fintype σ] [Field K] (n : ℕ) :
    Module.Finite K (homogeneousSubmodule σ K n) :=
  Module.Finite.iff_fg.mpr (homogeneousSubmodule_fg σ K n)

#print axioms finite_homogeneousSubmodule

/-- Degree 3 as a slice count. Over ℂ, take any plane αx + βy + γz + δw = 0 (not all four
coefficients zero). Put the curve's points (u, u², u³), u = b/a, into it: the plane holds the
point exactly when u is a root of the cubic δ + αu + βu² + γu³. Counted over ℂ, with each root
taken as often as it repeats, and with the missing degree 3 − (degree of the cubic) counted at
the curve's point at infinity (0 : 0 : 1 : 0), the plane meets the curve exactly 3 times. -/
theorem twisted_cubic_meets_every_plane_three_times (α β γ δ : ℂ)
    (hplane : ¬(α = 0 ∧ β = 0 ∧ γ = 0 ∧ δ = 0)) :
    let p : Polynomial ℂ := Polynomial.C δ + Polynomial.C α * Polynomial.X +
      Polynomial.C β * Polynomial.X ^ 2 + Polynomial.C γ * Polynomial.X ^ 3
    (∀ u : ℂ, α * u + β * u ^ 2 + γ * u ^ 3 + δ = 0 ↔ p.IsRoot u) ∧
      Multiset.card p.roots + (3 - p.natDegree) = 3 := by
  intro p
  refine ⟨fun u => ?_, ?_⟩
  · simp only [p, Polynomial.IsRoot.def, Polynomial.eval_add, Polynomial.eval_mul,
      Polynomial.eval_C, Polynomial.eval_X, Polynomial.eval_pow]
    constructor <;> intro h <;> linear_combination h
  · have hdeg : p.natDegree ≤ 3 := by
      simp only [p]; compute_degree
    rw [IsAlgClosed.card_roots_eq_natDegree]
    omega

/-- The twisted cubic's Hilbert function. Over any field, the degree-t forms in x, y, z, w,
taken modulo the ideal ⟨x² − yw, xy − zw, y² − xz⟩, number exactly 3t + 1 for every t ≥ 0.
So the Hilbert polynomial is 3t + 1: dimension 1 (the power of t) and degree 3 × 1! = 3. -/
theorem twisted_cubic_hilbert_function (K : Type*) [Field K] (t : ℕ) :
    hilbertFn (twistedCubicIdeal K) t = 3 * t + 1 := by
  unfold hilbertFn
  set W := ((twistedCubicIdeal K).restrictScalars K).comap
    (homogeneousSubmodule (Fin 4) K t).subtype with hWdef
  have hW : ∀ v : homogeneousSubmodule (Fin 4) K t,
      v ∈ W ↔ (v : MvPolynomial (Fin 4) K) ∈ twistedCubicIdeal K := fun v => Iff.rfl
  let f : Fin (3 * t + 1) → homogeneousSubmodule (Fin 4) K t ⧸ W := fun n =>
    Submodule.Quotient.mk ⟨cubicStd K t n, cubicStd_mem K t n (by omega)⟩
  let ψ : (homogeneousSubmodule (Fin 4) K t ⧸ W) →ₗ[K] Polynomial K :=
    W.liftQ ((cubicParam K).toLinearMap ∘ₗ (homogeneousSubmodule (Fin 4) K t).subtype)
      (fun v hv => by
        rw [LinearMap.mem_ker]
        exact cubicParam_ideal K _ ((hW v).mp hv))
  have hψf : ψ ∘ f = fun n : Fin (3 * t + 1) => (Polynomial.X : Polynomial K) ^ (n : ℕ) := by
    funext n
    simp [ψ, f, cubicParam_std]
  have hli : LinearIndependent K f := by
    apply LinearIndependent.of_comp ψ
    rw [hψf]
    have := (Polynomial.basisMonomials K).linearIndependent.comp
      (fun n : Fin (3 * t + 1) => (n : ℕ)) Fin.val_injective
    convert this using 1
    funext n
    simp [Polynomial.coe_basisMonomials, Polynomial.X_pow_eq_monomial]
  have hsp : ⊤ ≤ Submodule.span K (Set.range f) := by
    set S := Submodule.span K (Set.range f)
    let T : Submodule K (MvPolynomial (Fin 4) K) :=
      (S.comap W.mkQ).map (homogeneousSubmodule (Fin 4) K t).subtype
    have hVT : homogeneousSubmodule (Fin 4) K t ≤ T := by
      rw [homogeneousSubmodule_eq_finsupp_supported, AddMonoidAlgebra.supported_eq_span_single,
        Submodule.span_le]
      rintro _ ⟨d, hd, rfl⟩
      replace hd : d.degree = t := hd
      have hdeg : d 0 + d 1 + d 2 + d 3 = t := by
        rw [← hd, Finsupp.degree_eq_sum, Fin.sum_univ_four]
      have hmon : (AddMonoidAlgebra.single d 1 : MvPolynomial (Fin 4) K) =
          cubicMon K (d 0) (d 1) (d 2) (d 3) := by
        rw [single_eq_monomial, monomial_eq, Finsupp.prod_fintype _ _ (by simp),
          Fin.prod_univ_four]
        simp [cubicMon]
      have hmem : (AddMonoidAlgebra.single d 1 : MvPolynomial (Fin 4) K) ∈
          homogeneousSubmodule (Fin 4) K t := isHomogeneous_monomial _ hd
      refine ⟨⟨_, hmem⟩, ?_, rfl⟩
      have hn : d 0 + 2 * d 1 + 3 * d 2 < 3 * t + 1 := by omega
      have : Submodule.Quotient.mk (p := W) ⟨_, hmem⟩ = f ⟨d 0 + 2 * d 1 + 3 * d 2, hn⟩ := by
        apply (Submodule.Quotient.eq W).mpr
        rw [hW]
        simp only [Submodule.coe_sub]
        rw [hmon]
        exact cubicMon_sub_std_mem K _ _ _ _ _ _ _ le_rfl hdeg.symm rfl
      show W.mkQ _ ∈ S
      rw [Submodule.mkQ_apply, this]
      exact Submodule.subset_span ⟨_, rfl⟩
    intro q _
    obtain ⟨v, rfl⟩ := Submodule.Quotient.mk_surjective W q
    obtain ⟨v', hv', hvv⟩ := hVT v.2
    have : v' = v := Subtype.ext hvv
    subst this
    exact hv'
  rw [Module.finrank_eq_card_basis (Module.Basis.mk hli hsp), Fintype.card_fin]

/-- Slicing by a plane takes one difference of the count. Let `I` be the full ideal of an
irreducible projective variety V (a prime ideal, generated by homogeneous equations: every
homogeneous piece of a member is again a member), and `h` a linear form (a plane) that does not
vanish on all of V (`h ∉ I`). Then the Hilbert function of V's equations with h added is V's
Hilbert function minus its value one degree lower:
HF_{I + ⟨h⟩}(t + 1) = HF_V(t + 1) − HF_V(t). -/
theorem slice_subtracts_one_step {σ K : Type*} [Fintype σ] [Field K]
    (I : Ideal (MvPolynomial σ K)) (hprime : I.IsPrime)
    (hhom : ∀ p ∈ I, ∀ n : ℕ, homogeneousComponent n p ∈ I)
    (h : MvPolynomial σ K) (hlin : h.IsHomogeneous 1) (hnot : h ∉ I) (t : ℕ) :
    hilbertFn (I ⊔ Ideal.span {h}) (t + 1) + hilbertFn I t = hilbertFn I (t + 1) := by
  have := fun n => finite_homogeneousSubmodule (σ := σ) (K := K) n
  have hh0 : h ≠ 0 := fun h0 => hnot (h0 ▸ I.zero_mem)
  let μ : homogeneousSubmodule σ K t →ₗ[K] homogeneousSubmodule σ K (t + 1) :=
    (LinearMap.mulLeft K h).restrict (fun x hx => by
      have := hlin.mul hx
      rw [add_comm] at this
      exact this)
  have hμ : ∀ u, (μ u : MvPolynomial σ K) = h * u := fun u => rfl
  have hinj : Function.Injective μ := by
    intro u v huv
    apply Subtype.ext
    have := congrArg Subtype.val huv
    rw [hμ, hμ] at this
    exact mul_left_cancel₀ hh0 this
  let W : Ideal (MvPolynomial σ K) → (n : ℕ) → Submodule K (homogeneousSubmodule σ K n) :=
    fun J n => (J.restrictScalars K).comap (homogeneousSubmodule σ K n).subtype
  have hW : ∀ J n (v : homogeneousSubmodule σ K n), v ∈ W J n ↔ (v : MvPolynomial σ K) ∈ J :=
    fun J n v => Iff.rfl
  have key : ∀ J n, hilbertFn J n + Module.finrank K (W J n) =
      Module.finrank K (homogeneousSubmodule σ K n) :=
    fun J n => Submodule.finrank_quotient_add_finrank _
  have hA : W (I ⊔ Ideal.span {h}) (t + 1) = W I (t + 1) ⊔ LinearMap.range μ := by
    apply le_antisymm
    · intro v hv
      rw [hW] at hv
      obtain ⟨y, hy, z, hz, hyz⟩ := Submodule.mem_sup.mp hv
      obtain ⟨a, rfl⟩ := Ideal.mem_span_singleton'.mp hz
      rw [Submodule.mem_sup]
      refine ⟨⟨homogeneousComponent (t + 1) y, homogeneousComponent_mem _ _⟩,
        (hW _ _ _).mpr (hhom y hy _),
        μ ⟨homogeneousComponent t a, homogeneousComponent_mem _ _⟩, ⟨_, rfl⟩, ?_⟩
      apply Subtype.ext
      simp only [Submodule.coe_add, hμ]
      have hv' : (v : MvPolynomial σ K) = homogeneousComponent (t + 1) v :=
        (homogeneousComponent_eq_self v.2).symm
      rw [hv', ← hyz, map_add, homogeneousComponent_mul_linear h hlin, mul_comm]
    · apply sup_le
      · intro v hv
        rw [hW] at hv ⊢
        exact Ideal.mem_sup_left hv
      · rintro _ ⟨u, rfl⟩
        rw [hW, hμ]
        exact Ideal.mem_sup_right (Ideal.mul_mem_right _ _ (Ideal.mem_span_singleton_self h))
  have hB : W I (t + 1) ⊓ LinearMap.range μ = (W I t).map μ := by
    apply le_antisymm
    · rintro v ⟨hv1, ⟨u, rfl⟩⟩
      rw [SetLike.mem_coe, hW, hμ] at hv1
      rcases hprime.mem_or_mem hv1 with h' | h'
      · exact absurd h' hnot
      · exact ⟨u, (hW _ _ _).mpr h', rfl⟩
    · rintro _ ⟨u, hu, rfl⟩
      refine ⟨?_, ⟨u, rfl⟩⟩
      rw [SetLike.mem_coe, hW, hμ]
      exact I.mul_mem_left h ((hW _ _ _).mp hu)
  have hrange : Module.finrank K (LinearMap.range μ) =
      Module.finrank K (homogeneousSubmodule σ K t) := LinearMap.finrank_range_of_inj hinj
  have hmap : Module.finrank K ((W I t).map μ) = Module.finrank K (W I t) :=
    (Submodule.equivMapOfInjective μ hinj _).finrank_eq.symm
  have hsi := Submodule.finrank_sup_add_finrank_inf_eq (W I (t + 1)) (LinearMap.range μ)
  rw [← hA, hB, hmap, hrange] at hsi
  have k1 := key (I ⊔ Ideal.span {h}) (t + 1)
  have k2 := key I t
  have k3 := key I (t + 1)
  have hle : Module.finrank K (W I t) ≤ Module.finrank K (homogeneousSubmodule σ K t) :=
    Submodule.finrank_le _
  omega

/-! The card's worked numbers. -/

-- Monomials of degree t in x, y, z, w number C(t + 3, 3), for t = 0..7.
example : (List.range 8).map (fun t => Nat.choose (t + 3) 3) = [1, 4, 10, 20, 35, 56, 84, 120] := by
  decide

-- HF = monomials − ideal, for t = 0..7: 1, 4, 7, …, 22, which is 3t + 1.
example : List.zipWith (· - ·) [1, 4, 10, 20, 35, 56, 84, 120] [0, 0, 3, 10, 22, 40, 65, 98] =
    (List.range 8).map (fun t => 3 * t + 1) := by
  decide

-- By hand: C(5, 3) − 3 = 7 at t = 2, and C(6, 3) − 10 = 10 at t = 3; slope 3, and 10 = 3 × 3 + 1.
example : Nat.choose 5 3 - 3 = 7 ∧ Nat.choose 6 3 - 10 = 10 ∧ 10 - 7 = 3 ∧ 3 * 3 + 1 = 10 := by
  decide

-- Degree = leading coefficient × d!: 3 × 1! = 3 for the twisted cubic, 1 × 2! = 2 for the cone,
-- and (1/6) × 3! = 1 for all of P³.
example : 3 * Nat.factorial 1 = 3 ∧ 1 * Nat.factorial 2 = 2 ∧ (1 / 6 : ℚ) * (Nat.factorial 3 : ℚ) = 1 := by
  norm_num [Nat.factorial]

-- The plane 11x − 6y + z = 6 holds (1, 1, 1), (2, 4, 8) and (3, 9, 27).
example : 11 * 1 - 6 * 1 + 1 = (6 : ℤ) ∧ 11 * 2 - 6 * 4 + 8 = (6 : ℤ) ∧ 11 * 3 - 6 * 9 + 27 = (6 : ℤ) := by
  norm_num

-- u³ − 6u² + 11u − 6 = (u − 1)(u − 2)(u − 3).
example (u : ℤ) : u ^ 3 - 6 * u ^ 2 + 11 * u - 6 = (u - 1) * (u - 2) * (u - 3) := by
  ring

-- The tangent plane 5x − 4y + z = 2 gives u³ − 4u² + 5u − 2 = (u − 1)²(u − 2).
example (u : ℤ) : u ^ 3 - 4 * u ^ 2 + 5 * u - 2 = (u - 1) ^ 2 * (u - 2) := by
  ring

-- The plane z = 8: u³ − 8 = (u − 2)(u² + 2u + 4), and u² + 2u + 4 has discriminant −12.
example (u : ℤ) : u ^ 3 - 8 = (u - 2) * (u ^ 2 + 2 * u + 4) := by
  ring

example : (2 : ℤ) ^ 2 - 4 * 1 * 4 = -12 := by
  norm_num

-- x²zw becomes a⁴b² · b³ · a³ = a⁷b⁵ on the curve.
example : 2 * 2 + 0 + 3 * 1 = 7 ∧ 2 * 1 + 3 * 1 = 5 := by
  norm_num

-- The cone's slice: (t + 1)² − t² = 2t + 1.
example (t : ℕ) : (t + 1) ^ 2 = t ^ 2 + (2 * t + 1) := by
  ring

-- The plane cubic's genus (3 − 1)(3 − 2)/2 = 1.
example : (3 - 1) * (3 - 2) / 2 = 1 := by
  decide

#print axioms twisted_cubic_meets_every_plane_three_times
#print axioms twisted_cubic_hilbert_function
#print axioms slice_subtracts_one_step

end DegreeCard
