-- The spectrum of a ring: the points of Spec Z are (0) and one closed point (p) for each prime p, with (0) a generic point in every non-empty open set; the closed sets are the sets V(I) and obey the closed-set rules; and an element vanishes at every point exactly when it is nilpotent.
import Mathlib.RingTheory.Spectrum.Prime.Topology
import Mathlib.RingTheory.Nilpotent.Lemmas
import Mathlib.RingTheory.Int.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.NumberTheory.Divisors

open PrimeSpectrum

/-- The spectrum of the whole numbers: every prime ideal of ℤ is (0) or the multiples (p) of a
prime p; each (p) is a point that is closed; and (0) is a point whose closure is the whole space,
so it lies in every non-empty open set (the generic point). -/
theorem spec_int_closed_points_and_generic_point :
    (∀ x : PrimeSpectrum ℤ, x.asIdeal = ⊥ ∨ ∃ p : ℕ, p.Prime ∧ x.asIdeal = Ideal.span {(p : ℤ)}) ∧
    (∀ p : ℕ, p.Prime → ∃ x : PrimeSpectrum ℤ,
      x.asIdeal = Ideal.span {(p : ℤ)} ∧ IsClosed ({x} : Set (PrimeSpectrum ℤ))) ∧
    (∃ η : PrimeSpectrum ℤ, η.asIdeal = ⊥ ∧ closure ({η} : Set (PrimeSpectrum ℤ)) = Set.univ ∧
      ∀ U : Set (PrimeSpectrum ℤ), IsOpen U → U.Nonempty → η ∈ U) := by
  refine ⟨?_, ?_, ?_⟩
  · intro x
    obtain ⟨n, hn⟩ := (inferInstance : Submodule.IsPrincipal x.asIdeal)
    have hn' : x.asIdeal = Ideal.span {n} := by simpa using hn
    by_cases h0 : n = 0
    · left; rw [hn', h0, Ideal.span_singleton_eq_bot.mpr rfl]
    · right
      refine ⟨n.natAbs, ?_, ?_⟩
      · have hp : (Ideal.span ({n} : Set ℤ)).IsPrime := hn' ▸ x.2
        exact Int.prime_iff_natAbs_prime.mp ((Ideal.span_singleton_prime h0).mp hp)
      · rw [hn', Int.span_natAbs]
  · intro p hp
    have hpr : Prime (p : ℤ) := Int.prime_iff_natAbs_prime.mpr (by simpa using hp)
    have hmax : (Ideal.span ({(p : ℤ)} : Set ℤ)).IsMaximal :=
      PrincipalIdealRing.isMaximal_of_irreducible hpr.irreducible
    refine ⟨⟨_, hmax.isPrime⟩, rfl, ?_⟩
    exact (PrimeSpectrum.isClosed_singleton_iff_isMaximal _).mpr hmax
  · refine ⟨⟨⊥, Ideal.isPrime_bot⟩, rfl, ?_, ?_⟩
    · rw [PrimeSpectrum.closure_singleton]; exact zeroLocus_bot
    · intro U hU ⟨y, hy⟩
      have hcl : y ∈ closure ({⟨⊥, Ideal.isPrime_bot⟩} : Set (PrimeSpectrum ℤ)) := by
        rw [PrimeSpectrum.closure_singleton]; simp
      obtain ⟨z, hzU, hz⟩ := mem_closure_iff.mp hcl U hU hy
      rw [Set.mem_singleton_iff] at hz
      exact hz ▸ hzU

/-- The Zariski topology on Spec R, for a commutative ring R with 1: the closed sets are exactly
the sets V(I) of primes containing an ideal I; V(1) is empty and V(0) is everything; an
intersection of closed sets is V of the sum of the ideals; and V(I) ∪ V(J) = V(IJ). -/
theorem zariski_closed_sets_rules {R : Type*} [CommRing R] (I J : Ideal R)
    {ι : Type*} (K : ι → Ideal R) :
    (∀ Z : Set (PrimeSpectrum R), IsClosed Z ↔ ∃ L : Ideal R, Z = zeroLocus (L : Set R)) ∧
    zeroLocus ((⊤ : Ideal R) : Set R) = ∅ ∧
    zeroLocus ((⊥ : Ideal R) : Set R) = Set.univ ∧
    (⋂ j, zeroLocus (K j : Set R)) = zeroLocus ((⨆ j, K j : Ideal R) : Set R) ∧
    zeroLocus (I : Set R) ∪ zeroLocus (J : Set R) = zeroLocus ((I * J : Ideal R) : Set R) := by
  refine ⟨fun Z => isClosed_iff_zeroLocus_ideal Z, ?_, zeroLocus_bot, ?_, ?_⟩
  · exact zeroLocus_empty_of_one_mem (by simp)
  · exact (zeroLocus_iSup K).symm
  · exact (zeroLocus_mul I J).symm

/-- In a commutative ring with 1, an element vanishes at every point of the spectrum (lies in
every prime ideal) exactly when some power of it is zero. -/
theorem vanishes_at_every_point_iff_nilpotent {R : Type*} [CommRing R] (f : R) :
    (∀ x : PrimeSpectrum R, f ∈ x.asIdeal) ↔ IsNilpotent f := by
  rw [nilpotent_iff_mem_prime]
  exact ⟨fun h J hJ => h ⟨J, hJ⟩, fun h x => h x.asIdeal x.2⟩

-- 60 read at the points (2), (3), (5), (7), (11), (13): its remainders.
example : (60 % 2, 60 % 3, 60 % 5, 60 % 7, 60 % 11, 60 % 13) = (0, 0, 0, 4, 5, 8) := by decide

-- V(60) = {(2), (3), (5)}: the primes up to 60 that divide 60.
example : (Finset.range 61).filter (fun p => p.Prime ∧ p ∣ 60) = {2, 3, 5} := by decide

-- V(12) ∪ V(10) = V(120) and V(12) ∩ V(10) = V(gcd(12, 10)) = V(2), on the primes up to 120.
example : (Finset.range 121).filter (fun p => p.Prime ∧ (p ∣ 12 ∨ p ∣ 10)) =
    (Finset.range 121).filter (fun p => p.Prime ∧ p ∣ 120) := by decide
example : Nat.gcd 12 10 = 2 ∧ (Finset.range 121).filter (fun p => p.Prime ∧ p ∣ 12 ∧ p ∣ 10) = {2} := by
  decide

-- Z/60 has 12 ideals, one per divisor of 60, and 3 of them are prime.
example : (Nat.divisors 60).card = 12 ∧ ((Nat.divisors 60).filter Nat.Prime).card = 3 := by decide

-- In Z/60 the class 30 is not 0 but 30^2 = 900 = 15 × 60 is; the classes vanishing at
-- (2), (3), (5) are 0 and 30, and so are the classes whose square is 0.
example : (30 : ZMod 60) ≠ 0 ∧ (30 : ZMod 60) ^ 2 = 0 := by decide
example : (Finset.range 60).filter (fun a => 2 ∣ a ∧ 3 ∣ a ∧ 5 ∣ a) = {0, 30} := by decide
example : (Finset.range 60).filter (fun a => a ^ 2 % 60 = 0) = {0, 30} := by decide

-- In Z/30 the only class with a zero power is 0.
example : (Finset.range 30).filter (fun a => a ^ 30 % 30 = 0) = {0} := by decide

-- The ideal of the set V(60) is (30): the least positive n divisible by 2, 3 and 5 is 30.
example : (Finset.range 61).filter (fun n => 0 < n ∧ 2 ∣ n ∧ 3 ∣ n ∧ 5 ∣ n) = {30, 60} := by decide

-- Spec F_2[x]: points of degree 1 to 8 number 2, 1, 2, 3, 6, 9, 18, 30, and they satisfy
-- Gauss's identity: the sum of e × N_e over e dividing d is 2^d (shown for d = 4, 6, 8).
example : 1 * 2 + 2 * 1 + 4 * 3 = 2 ^ 4 ∧ 1 * 2 + 2 * 1 + 3 * 2 + 6 * 9 = 2 ^ 6 ∧
    1 * 2 + 2 * 1 + 4 * 3 + 8 * 30 = 2 ^ 8 ∧ 2 + 1 + 2 + 3 = 8 := by norm_num

-- The curve x^2 + 1 above (5): roots 2 and 3; above (3) and (7): no root.
example : (Finset.range 5).filter (fun x => (x * x + 1) % 5 = 0) = {2, 3} := by decide
example : (Finset.range 3).filter (fun x => (x * x + 1) % 3 = 0) = ∅ ∧
    (Finset.range 7).filter (fun x => (x * x + 1) % 7 = 0) = ∅ := by decide

-- The curve y^2 = x^3 - 2: it holds (3, 5), and over (7) it has 6 affine points.
example : (5 : ℤ) ^ 2 = 3 ^ 3 - 2 := by norm_num
example : ((Finset.range 7 ×ˢ Finset.range 7).filter
    (fun q : ℕ × ℕ => (q.2 ^ 2 + 2) % 7 = q.1 ^ 3 % 7)).card = 6 := by decide

#print axioms spec_int_closed_points_and_generic_point
#print axioms zariski_closed_sets_rules
#print axioms vanishes_at_every_point_iff_nilpotent
