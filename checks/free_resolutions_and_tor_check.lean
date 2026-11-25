-- Free resolutions and Tor: reading the free resolution 0 → ℤ → ℤ → ℤ/m (first map times m) mod n gives Tor₀ and Tor₁ both equal to ℤ/gcd(m, n), a wasteful second resolution gives the same Tor₁, and over k[x] Tor₁ is k[x]/(gcd(f, g)).
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Polynomial.FieldDivision
import Mathlib.RingTheory.Ideal.Quotient.Operations
import Mathlib.Algebra.Algebra.Bilinear
import Mathlib.GroupTheory.SpecificGroups.Cyclic
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring
import Mathlib.LinearAlgebra.Isomorphisms

open Polynomial

/-- Helper: multiplication by m on ZMod n is the same map as adding an element to itself m times. -/
theorem mulLeft_eq_nsmul (m n : ℕ) :
    AddMonoidHom.mulLeft (m : ZMod n) = nsmulAddMonoidHom m := by
  ext x; simp [nsmul_eq_mul]

#print axioms mulLeft_eq_nsmul

/-- The gcd rule over ℤ (Step 5). Resolve ℤ/m by `0 → ℤ --×m--> ℤ → ℤ/m → 0` and tensor with ℤ/n:
the tensored resolution is "times m" on ℤ/n. For m, n ≥ 1, its kernel, Tor₁(ℤ/m, ℤ/n), and its
cokernel, Tor₀(ℤ/m, ℤ/n) = ℤ/m ⊗ ℤ/n, are both cyclic of order gcd(m, n). -/
theorem tor_zmod_eq_zmod_gcd (m n : ℕ) (hm : 1 ≤ m) (hn : 1 ≤ n) :
    Nonempty ((AddMonoidHom.mulLeft (m : ZMod n)).ker ≃+ ZMod (Nat.gcd m n)) ∧
    Nonempty ((ZMod n ⧸ (AddMonoidHom.mulLeft (m : ZMod n)).range) ≃+ ZMod (Nat.gcd m n)) := by
  have : NeZero n := ⟨by omega⟩
  rw [mulLeft_eq_nsmul]
  constructor
  · have h := IsAddCyclic.card_nsmulAddMonoidHom_ker (ZMod n) m
    rw [Nat.card_zmod, Nat.gcd_comm] at h
    rw [← h]
    exact ⟨(zmodAddCyclicAddEquiv inferInstance).symm⟩
  · have h := IsAddCyclic.index_nsmulAddMonoidHom_range (ZMod n) m
    rw [Nat.card_zmod, Nat.gcd_comm, AddSubgroup.index] at h
    rw [← h]
    exact ⟨(zmodAddCyclicAddEquiv (isAddCyclic_of_surjective (QuotientAddGroup.mk' _)
      (QuotientAddGroup.mk'_surjective _))).symm⟩

/-- Tor does not depend on the resolution, on the card's own second resolution (Steps 1 and 2).
Resolve ℤ/m wastefully by `0 → ℤ --(1, -1)--> ℤ² --(m m)--> ℤ → ℤ/m → 0` and tensor with ℤ/n.
For m, n ≥ 1, Tor₁ = ker (m m) / im (1, -1) is again ℤ/gcd(m, n), and Tor₂ = ker (1, -1) is 0. -/
theorem tor_wasteful_resolution_agrees (m n : ℕ) (hm : 1 ≤ m) (hn : 1 ≤ n) :
    Nonempty (((AddMonoidHom.mulLeft (m : ZMod n)).comp
        (AddMonoidHom.coprod (AddMonoidHom.id (ZMod n)) (AddMonoidHom.id (ZMod n)))).ker ⧸
      ((AddMonoidHom.prod (AddMonoidHom.id (ZMod n)) (-AddMonoidHom.id (ZMod n))).range.addSubgroupOf
        ((AddMonoidHom.mulLeft (m : ZMod n)).comp
          (AddMonoidHom.coprod (AddMonoidHom.id (ZMod n)) (AddMonoidHom.id (ZMod n)))).ker)
      ≃+ ZMod (Nat.gcd m n)) ∧
    (AddMonoidHom.prod (AddMonoidHom.id (ZMod n)) (-AddMonoidHom.id (ZMod n))).ker = ⊥ := by
  set K := ((AddMonoidHom.mulLeft (m : ZMod n)).comp
        (AddMonoidHom.coprod (AddMonoidHom.id (ZMod n)) (AddMonoidHom.id (ZMod n)))).ker with hK
  set φ : K →+ (AddMonoidHom.mulLeft (m : ZMod n)).ker :=
    ((AddMonoidHom.coprod (AddMonoidHom.id (ZMod n)) (AddMonoidHom.id (ZMod n))).comp
      K.subtype).codRestrict _ (fun x => x.2) with hφ
  have hφa : ∀ x : K, (φ x : ZMod n) = (x : ZMod n × ZMod n).1 + (x : ZMod n × ZMod n).2 :=
    fun _ => rfl
  have hsurj : Function.Surjective φ := by
    rintro ⟨a, ha⟩
    refine ⟨⟨(a, 0), ?_⟩, ?_⟩
    · simpa [hK] using ha
    · ext; simp [hφa]
  have hker : φ.ker = (AddMonoidHom.prod (AddMonoidHom.id (ZMod n))
      (-AddMonoidHom.id (ZMod n))).range.addSubgroupOf K := by
    ext ⟨⟨a, b⟩, hab⟩
    simp only [AddMonoidHom.mem_ker, AddSubgroup.mem_addSubgroupOf, AddMonoidHom.mem_range]
    constructor
    · intro h
      have h' : a + b = 0 := by
        have := congrArg Subtype.val h
        simpa [hφa] using this
      refine ⟨a, ?_⟩
      simp [eq_neg_of_add_eq_zero_right h']
    · rintro ⟨c, hc⟩
      simp only [AddMonoidHom.prod_apply, AddMonoidHom.id_apply, AddMonoidHom.neg_apply,
        Prod.mk.injEq] at hc
      ext
      simp [hφa, ← hc.1, ← hc.2]
  refine ⟨?_, ?_⟩
  · obtain ⟨e⟩ := (tor_zmod_eq_zmod_gcd m n hm hn).1
    exact ⟨(QuotientAddGroup.quotientAddEquivOfEq hker.symm).trans
      ((QuotientAddGroup.quotientKerEquivOfSurjective φ hsurj).trans e)⟩
  · ext c
    simp

open scoped Classical in
/-- The gcd rule over k[x] (Step 5). Over a field k, with f and g nonzero, Tor₁(k[x]/(f), k[x]/(g)),
the kernel of multiplication by f on k[x]/(g), is isomorphic as a k[x]-module to k[x]/(gcd(f, g)). -/
theorem tor_polynomial_eq_quotient_gcd {k : Type*} [Field k] (f g : k[X]) (hf : f ≠ 0) (hg : g ≠ 0) :
    Nonempty (LinearMap.ker (LinearMap.mulLeft k[X] (Ideal.Quotient.mk (Ideal.span {g}) f))
      ≃ₗ[k[X]] k[X] ⧸ Ideal.span {EuclideanDomain.gcd f g}) := by
  set d := EuclideanDomain.gcd f g with hd
  have hd0 : d ≠ 0 := fun h => hf (EuclideanDomain.gcd_eq_zero_iff.mp h).1
  obtain ⟨a, b, hab⟩ : ∃ a b, d = f * a + g * b := ⟨_, _, EuclideanDomain.gcd_eq_gcd_ab f g⟩
  obtain ⟨f', hf'⟩ : d ∣ f := EuclideanDomain.gcd_dvd_left f g
  obtain ⟨g', hg'⟩ : d ∣ g := EuclideanDomain.gcd_dvd_right f g
  have hg'0 : g' ≠ 0 := by rintro rfl; exact hg (by simpa using hg')
  have hcop : f' * a + g' * b = 1 := by
    apply mul_left_cancel₀ hd0
    rw [mul_one]
    conv_rhs => rw [hab, hf', hg']
    ring
  set I := Ideal.span {g} with hI
  set L := LinearMap.mulLeft k[X] (Ideal.Quotient.mk I f) with hL
  have hsm : ∀ c x : k[X], c • Ideal.Quotient.mk I x = Ideal.Quotient.mk I (c * x) :=
    fun _ _ => rfl
  have hmem : ∀ c : k[X], c • Ideal.Quotient.mk I g' ∈ LinearMap.ker L := by
    intro c
    rw [LinearMap.mem_ker, hL, LinearMap.mulLeft_apply, hsm, ← map_mul, Ideal.Quotient.eq_zero_iff_mem, hI,
      Ideal.mem_span_singleton]
    exact ⟨f' * c, by rw [hf', hg']; ring⟩
  set ψ : k[X] →ₗ[k[X]] LinearMap.ker L :=
    LinearMap.codRestrict (LinearMap.ker L)
      (LinearMap.toSpanSingleton k[X] _ (Ideal.Quotient.mk I g')) hmem with hψ
  have hψa : ∀ c : k[X], (ψ c : k[X] ⧸ I) = Ideal.Quotient.mk I (c * g') := by
    intro c
    exact hsm c g'
  have hsurj : Function.Surjective ψ := by
    rintro ⟨x, hx⟩
    obtain ⟨h, rfl⟩ := Ideal.Quotient.mk_surjective x
    rw [LinearMap.mem_ker, hL, LinearMap.mulLeft_apply, ← map_mul,
      Ideal.Quotient.eq_zero_iff_mem, hI, Ideal.mem_span_singleton] at hx
    obtain ⟨t, ht⟩ := hx
    have ht' : f' * h = g' * t := by
      apply mul_left_cancel₀ hd0
      rw [← mul_assoc, ← hf', ht, hg', mul_assoc]
    refine ⟨t * a + h * b, ?_⟩
    apply Subtype.ext
    rw [hψa]
    congr 1
    linear_combination h * hcop - a * ht'
  have hker : LinearMap.ker ψ = Ideal.span {d} := by
    ext p
    rw [LinearMap.mem_ker, Ideal.mem_span_singleton, ← Subtype.coe_inj, hψa,
      Submodule.coe_zero, Ideal.Quotient.eq_zero_iff_mem, hI, Ideal.mem_span_singleton, hg']
    constructor
    · rintro ⟨s, hs⟩
      refine ⟨s, ?_⟩
      apply mul_right_cancel₀ hg'0
      rw [hs]; ring
    · rintro ⟨s, rfl⟩
      exact ⟨s, by ring⟩
  exact ⟨((Submodule.quotEquivOfEq _ _ hker).symm.trans
    (LinearMap.quotKerEquivOfSurjective ψ hsurj)).symm⟩

-- Resolution A tensored with ℤ/6: times 4 on ℤ/6 kills exactly 0 and 3, and hits exactly 0, 2, 4.
example : Finset.univ.filter (fun x : ZMod 6 => 4 * x = 0) = {0, 3} := by decide
example : Finset.univ.image (fun x : ZMod 6 => 4 * x) = {0, 2, 4} := by decide
-- So Tor₀ = ℤ/6 mod {0, 2, 4} has 6 / 3 = 2 elements, not 24, and gcd(4, 6) = 2.
example : Fintype.card (ZMod 6) / (Finset.univ.image (fun x : ZMod 6 => 4 * x)).card = 2 := by decide
example : Nat.gcd 4 6 = 2 := by decide
-- Resolution B tensored with ℤ/6: 12 pairs in the kernel of (4 4), 6 pairs (c, -c) in the image of (1, -1).
example : (Finset.univ.filter (fun p : ZMod 6 × ZMod 6 => 4 * (p.1 + p.2) = 0)).card = 12 := by decide
example : (Finset.univ.image (fun c : ZMod 6 => (c, -c))).card = 6 := by decide
-- Tor₂ from B is 0: (c, -c) = 0 only for c = 0.
example : Finset.univ.filter (fun c : ZMod 6 => ((c, -c) : ZMod 6 × ZMod 6) = 0) = {0} := by decide
-- The other side: resolve ℤ/6 by times 6 and tensor with ℤ/4; the kernel is 0 and 2.
example : Finset.univ.filter (fun x : ZMod 4 => 6 * x = 0) = {0, 2} := by decide
-- The non-free "resolution" 0 → ℤ/3 → ℤ/12, read mod 6, loses nothing: times 4 kills only 0.
example : (Finset.range 3).filter (fun a => 4 * a % 6 = 0) = {0} := by decide
-- Klein bottle mod 2: the triangle chains U, L with zero rim (rows a, b, c of the boundary) are 0 and U + L.
example : (Finset.univ.filter (fun p : ZMod 2 × ZMod 2 =>
    p.1 + p.2 = 0 ∧ p.1 - p.2 = 0 ∧ -p.1 - p.2 = 0)).card = 2 := by decide
-- Tor₁(ℤ/2, ℤ/2): times 2 on ℤ/2 kills both elements.
example : (Finset.univ.filter (fun x : ZMod 2 => 2 * x = 0)).card = 2 := by decide
-- Over ℚ[x]: x - 2 times f = x² - 1 is a multiple of g = x² - 3x + 2, and x - 1 divides both f and g.
example : ((X - 2) * (X ^ 2 - 1) : ℚ[X]) = (X ^ 2 - 3 * X + 2) * (X + 1) := by ring
example : ((X ^ 2 - 1 : ℚ[X]) = (X - 1) * (X + 1)) ∧ ((X ^ 2 - 3 * X + 2 : ℚ[X]) = (X - 1) * (X - 2)) := by
  constructor <;> ring

#print axioms tor_zmod_eq_zmod_gcd
#print axioms tor_wasteful_resolution_agrees
#print axioms tor_polynomial_eq_quotient_gcd
