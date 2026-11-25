-- Projective, injective and flat: projective modules are the direct summands of free modules, Baer's ideal test detects injective modules, and over the whole numbers injective means divisible and flat means torsion-free.
import Mathlib.Algebra.Module.Projective
import Mathlib.Algebra.Module.Injective
import Mathlib.RingTheory.Flat.Basic
import Mathlib.Algebra.Exact.Basic
import Mathlib.Algebra.Category.Grp.Injective
import Mathlib.RingTheory.Flat.TorsionFree
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.GCDMonoid.Finset
import Mathlib.Algebra.GCDMonoid.Nat

universe u

/-- Over a commutative ring R, a module P is projective exactly when some module Q fills it
out to a free module: P ⊕ Q ≅ R^(S) for some set S. -/
theorem projective_iff_direct_summand_of_free (R : Type u) [CommRing R]
    (P : Type u) [AddCommGroup P] [Module R P] :
    Module.Projective R P ↔
      ∃ (Q : Type u) (_ : AddCommGroup Q) (_ : Module R Q) (S : Type u),
        Nonempty ((P × Q) ≃ₗ[R] (S →₀ R)) := by
  constructor
  · intro hP
    let π : (P →₀ R) →ₗ[R] P := Finsupp.linearCombination R id
    have hπ : Function.Surjective π := fun x => ⟨Finsupp.single x 1, by simp [π]⟩
    obtain ⟨l, hl⟩ := Module.projective_lifting_property π LinearMap.id hπ
    have hex : Function.Exact (LinearMap.ker π).subtype π := LinearMap.exact_subtype_ker_map π
    let e := (hex.splitSurjectiveEquiv (Submodule.injective_subtype _) ⟨l, hl⟩).1
    exact ⟨LinearMap.ker π, inferInstance, inferInstance, P,
      ⟨(LinearEquiv.prodComm R P (LinearMap.ker π)).trans e.symm⟩⟩
  · rintro ⟨Q, _, _, S, ⟨e⟩⟩
    exact Module.Projective.of_split (e.toLinearMap ∘ₗ LinearMap.inl R P Q)
      (LinearMap.fst R P Q ∘ₗ e.symm.toLinearMap) (by ext x; simp)

/-- Baer's criterion: over a commutative ring R, a module I is injective exactly when every
module map from an ideal J of R into I extends to a module map from all of R into I. -/
theorem injective_iff_maps_from_ideals_extend (R : Type u) [CommRing R]
    (I : Type u) [AddCommGroup I] [Module R I] :
    Module.Injective R I ↔
      ∀ (J : Ideal R) (g : J →ₗ[R] I),
        ∃ g' : R →ₗ[R] I, ∀ (x : R) (hx : x ∈ J), g' x = g ⟨x, hx⟩ := by
  exact Module.Baer.iff_injective.symm

/-- Over the whole numbers, a module is injective exactly when it is divisible (n y = x always
has an answer y for n ≠ 0), and flat exactly when it is torsion-free (n x = 0 with n ≠ 0
forces x = 0). -/
theorem int_injective_iff_divisible_and_flat_iff_torsion_free
    (M : Type u) [AddCommGroup M] :
    (Module.Injective ℤ M ↔ ∀ n : ℤ, n ≠ 0 → ∀ x : M, ∃ y : M, n • y = x) ∧
      (Module.Flat ℤ M ↔ ∀ n : ℤ, n ≠ 0 → ∀ x : M, n • x = 0 → x = 0) := by
  constructor
  · constructor
    · intro hM n hn x
      obtain ⟨h, hh⟩ := Module.Injective.extension_property ℤ M ℤ ℤ
        (n • LinearMap.id) (fun a b hab => by
          simpa [hn] using hab) (LinearMap.toSpanSingleton ℤ M x)
      refine ⟨h 1, ?_⟩
      have := LinearMap.congr_fun hh 1
      rw [← map_zsmul, smul_eq_mul, mul_one]
      simpa using this
    · intro hdiv
      let _ : DivisibleBy M ℤ := divisibleByOfSMulRightSurj M ℤ (fun hn x => hdiv _ hn x)
      exact (Module.Baer.of_divisible M).injective
  · rw [Module.Flat.flat_iff_torsion_eq_bot_of_isBezout]
    constructor
    · intro h n hn x hx
      have : x ∈ Submodule.torsion ℤ M :=
        ⟨⟨n, mem_nonZeroDivisors_of_ne_zero hn⟩, hx⟩
      rw [h] at this
      simpa using this
    · intro h
      rw [eq_bot_iff]
      rintro x ⟨⟨n, hn⟩, hx⟩
      exact h n (nonZeroDivisors.ne_zero hn) x hx

-- Z/6 = Z/2 × Z/3: reading x mod 2 and mod 3 hits all six pairs exactly once.
example : Function.Injective (fun x : ZMod 6 => (x.val % 2, x.val % 3)) := by decide
-- The idempotents of Z/6 are 0, 1, 3 and 4, and 3 + 4 = 1.
example : (Finset.univ.filter fun e : ZMod 6 => e * e = e) = {0, 1, 3, 4} := by decide
example : (3 : ZMod 6) + 4 = 1 := by decide
-- Sections of Z/6 → Z/2: s(1) must have 2 s(1) = 0 and read 1 mod 2; only s(1) = 3 works.
example : ∀ s : ZMod 6, (2 * s = 0 ∧ s.val % 2 = 1) ↔ s = 3 := by decide
-- Z/4 → Z/2 has no section.
example : ∀ s : ZMod 4, ¬ (2 * s = 0 ∧ s.val % 2 = 1) := by decide
-- Z/2 is not injective over Z/4: 2 y = 1 has no answer in Z/2.
example : ∀ y : ZMod 2, 2 * y ≠ 1 := by decide
-- The gcd test for Z/2 over Z/6 and over Z/4.
example : Nat.gcd 2 (6 / 2) = 1 ∧ Nat.gcd 2 (4 / 2) = 2 := by decide
-- A map Q → Z sends 1 to a multiple of 1, ..., 20, whose lcm is 232792560.
example : (Finset.Icc 1 20).lcm id = 232792560 := by decide
-- House example: times 4 on Z/6 has kernel {0, 3} (Tor) and leaves 6 / 3 = 2 classes (Ext).
example : (Finset.univ.filter fun x : ZMod 6 => 4 * x = 0) = {0, 3} := by decide
example : (Finset.univ.image fun x : ZMod 6 => 4 * x).card = 3 := by decide

#print axioms projective_iff_direct_summand_of_free
#print axioms injective_iff_maps_from_ideals_extend
#print axioms int_injective_iff_divisible_and_flat_iff_torsion_free
