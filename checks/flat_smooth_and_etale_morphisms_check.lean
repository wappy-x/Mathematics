-- Flat, smooth and etale: a ring A[x]/(h) with h monic is etale exactly at the primes where h' is nonzero, a family over a line is flat exactly when no function upstairs is killed by a nonzero polynomial, and smooth implies flat while etale means smooth with zero differentials.
import Mathlib.RingTheory.AdjoinRoot
import Mathlib.RingTheory.Etale.Locus
import Mathlib.RingTheory.Flat.TorsionFree
import Mathlib.RingTheory.Smooth.Flat
import Mathlib.Algebra.Polynomial.Derivative
import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.Etale.StandardEtale
import Mathlib.Algebra.DualNumber

open Polynomial

/-- One variable, one monic equation: for `B = A[x]/⟨h(x)⟩` with `h` monic, the map
`Spec B → Spec A` is etale at a point `P` of `Spec B` exactly when `h'(x)` is not zero at `P`,
that is, when `h'(x)` does not lie in the prime ideal `P`. -/
theorem etale_at_iff_derivative_ne_zero {A : Type*} [CommRing A] (h : A[X]) (hm : h.Monic)
    (P : Ideal (AdjoinRoot h)) [P.IsPrime] :
    Algebra.IsEtaleAt A P ↔ aeval (AdjoinRoot.root h) (derivative h) ∉ P := by
  constructor
  · intro hE hP
    let K := P.ResidueField
    let x : K := algebraMap (AdjoinRoot h) K (AdjoinRoot.root h)
    have key : aeval (TrivSqZeroExt.inl x + DualNumber.eps : DualNumber K) h = 0 := by
      have h0 : aeval x h = 0 := by
        simp only [x, aeval_algebraMap_apply, AdjoinRoot.aeval_eq, AdjoinRoot.mk_self, map_zero]
      have h1 : aeval x (derivative h) = 0 := by
        simp only [x, aeval_algebraMap_apply]
        exact Ideal.algebraMap_residueField_eq_zero.2 hP
      have hinl : ∀ p : A[X], aeval (TrivSqZeroExt.inl x : DualNumber K) p = TrivSqZeroExt.inl (aeval x p) :=
        fun p => (aeval_algHom_apply (TrivSqZeroExt.inlAlgHom A K K) x p)
      rw [aeval_def, ← eval_map, eval_add_of_sq_eq_zero _ _ _
        (by rw [sq]; exact DualNumber.eps_mul_eps), derivative_map, eval_map, eval_map,
        ← aeval_def, ← aeval_def, hinl, hinl, h0, h1]
      simp
    let φ : AdjoinRoot h →ₐ[A] DualNumber K := AdjoinRoot.liftAlgHom h (Algebra.ofId A (DualNumber K)) _ key
    have hfst' : (TrivSqZeroExt.fstHom A K K).comp φ = IsScalarTower.toAlgHom A (AdjoinRoot h) K := by
      apply AdjoinRoot.algHom_ext
      have hroot : φ (AdjoinRoot.root h) = TrivSqZeroExt.inl x + DualNumber.eps :=
        AdjoinRoot.liftAlgHom_root _ _ _ _
      simp only [AlgHom.comp_apply, hroot, TrivSqZeroExt.fstHom_apply, TrivSqZeroExt.fst_add,
        TrivSqZeroExt.fst_inl, DualNumber.fst_eps, add_zero, x, IsScalarTower.coe_toAlgHom']
    have hfst : ∀ b, (φ b).fst = algebraMap (AdjoinRoot h) K b := fun b =>
      AlgHom.congr_fun hfst' b
    have hunit : ∀ s : P.primeCompl, IsUnit (φ s) := by
      intro s
      rw [TrivSqZeroExt.isUnit_iff_isUnit_fst, hfst, isUnit_iff_ne_zero, Ne,
        Ideal.algebraMap_residueField_eq_zero]
      exact s.2
    let g2 : Localization.AtPrime P →ₐ[A] DualNumber K := IsLocalization.liftAlgHom hunit
    let g1 : Localization.AtPrime P →ₐ[A] DualNumber K :=
      (TrivSqZeroExt.inlAlgHom A K K).comp (IsScalarTower.toAlgHom A _ K)
    have hnil : IsNilpotent (RingHom.ker (TrivSqZeroExt.fstHom K K K : DualNumber K →+* K)) := by
      refine ⟨2, le_bot_iff.mp ?_⟩
      rw [Submodule.pow_succ, Submodule.pow_one]
      refine Ideal.mul_le.2 fun a ha b hb => ?_
      rw [RingHom.mem_ker] at ha hb
      rw [Ideal.mem_bot]
      change a.fst = 0 at ha
      change b.fst = 0 at hb
      ext <;> simp [ha, hb]
    have hfg : ((TrivSqZeroExt.fstHom K K K : DualNumber K →+* K).comp g1.toRingHom) =
        (TrivSqZeroExt.fstHom K K K : DualNumber K →+* K).comp g2.toRingHom := by
      apply IsLocalization.ringHom_ext P.primeCompl
      refine RingHom.ext fun b => ?_
      change (g1 (algebraMap _ _ b)).fst = (g2 (algebraMap _ _ b)).fst
      rw [show g2 (algebraMap _ _ b) = φ b from IsLocalization.lift_eq _ _, hfst]
      simp [g1, ← IsScalarTower.algebraMap_apply]
    have heq := Algebra.FormallyUnramified.ext' _ hnil g1 g2 (fun y => RingHom.congr_fun hfg y)
    have := congrArg TrivSqZeroExt.snd
      (AlgHom.congr_fun heq (algebraMap _ _ (AdjoinRoot.root h)))
    have hroot : φ (AdjoinRoot.root h) = TrivSqZeroExt.inl x + DualNumber.eps :=
      AdjoinRoot.liftAlgHom_root _ _ _ _
    simp only [g1, g2, AlgHom.comp_apply, TrivSqZeroExt.inlAlgHom_apply, TrivSqZeroExt.snd_inl,
      IsLocalization.coe_liftAlgHom, IsLocalization.lift_eq] at this
    rw [show φ.toRingHom (AdjoinRoot.root h) = _ from hroot, TrivSqZeroExt.snd_add,
      TrivSqZeroExt.snd_inl, DualNumber.snd_eps, zero_add] at this
    exact zero_ne_one this
  · intro hP
    let SP : StandardEtalePair A := ⟨h, hm, derivative h, 1, 0, 1, by simp⟩
    have e := SP.equivAwayAdjoinRoot
    have hE : Algebra.Etale A (Localization.Away (AdjoinRoot.mk h (derivative h))) :=
      Algebra.Etale.of_equiv e
    have hsub := (Algebra.basicOpen_subset_etaleLocus_iff (R := A)
      (f := AdjoinRoot.mk h (derivative h))).2 inferInstance
    have hmem : (⟨P, inferInstance⟩ : PrimeSpectrum (AdjoinRoot h)) ∈
        PrimeSpectrum.basicOpen (AdjoinRoot.mk h (derivative h)) := by
      simpa [AdjoinRoot.aeval_eq] using hP
    exact hsub hmem

/-- The Tor test over a line: a family over the line `Spec k[t]` (an algebra `B` over `k[t]`,
with `k` a field) is flat exactly when no nonzero function upstairs is killed by a nonzero
polynomial in `t`. -/
theorem flat_over_line_iff_no_function_killed {k B : Type*} [Field k] [CommRing B]
    [Algebra k[X] B] :
    Module.Flat k[X] B ↔ ∀ (c : k[X]) (b : B), c ≠ 0 → c • b = 0 → b = 0 := by
  rw [Module.Flat.flat_iff_torsion_eq_bot_of_isBezout]
  constructor
  · intro h c b hc hcb
    have : b ∈ Submodule.torsion k[X] B :=
      (Submodule.mem_torsion_iff b).2 ⟨⟨c, mem_nonZeroDivisors_of_ne_zero hc⟩, hcb⟩
    rw [h] at this
    exact (Submodule.mem_bot _).1 this
  · intro h
    rw [eq_bot_iff]
    intro b hb
    obtain ⟨⟨c, hc⟩, hcb⟩ := (Submodule.mem_torsion_iff b).1 hb
    exact (Submodule.mem_bot _).2 (h c b (nonZeroDivisors.ne_zero hc) hcb)

/-- Smooth maps are flat, and a map is etale exactly when it is smooth of relative dimension 0:
smooth with zero module of differentials `Ω_{B/A}`. -/
theorem smooth_flat_and_etale_iff_smooth_no_differentials {A B : Type*} [CommRing A] [CommRing B]
    [Algebra A B] :
    (Algebra.Smooth A B → Module.Flat A B) ∧
      (Algebra.Etale A B ↔ Algebra.Smooth A B ∧ Subsingleton Ω[B⁄A]) := by
  refine ⟨fun _ => inferInstance, ?_, ?_⟩
  · intro h
    exact ⟨inferInstance, inferInstance⟩
  · rintro ⟨h1, h2⟩
    have : Algebra.FormallyUnramified A B := ⟨h2⟩
    have : Algebra.FormallyEtale A B :=
      Algebra.FormallyEtale.iff_formallyUnramified_and_formallySmooth.2 ⟨inferInstance, inferInstance⟩
    exact ⟨inferInstance, inferInstance⟩

-- The fibre xy = t z^2 in P^2: HF(n) = C(n + 2, 2) - C(n, 2) = 2n + 1 for n = 0 to 6.
example : ∀ n ∈ Finset.range 7, (n + 2).choose 2 - n.choose 2 = 2 * n + 1 := by decide
-- Degree 3 by hand: 10 - 3 = 7.
example : Nat.choose 5 2 - Nat.choose 3 2 = 7 := by decide
-- Standard monomials of degree n not divisible by xy: z^n, x^a z^(n-a), y^b z^(n-b): 1 + n + n.
example : ∀ n ∈ Finset.range 7,
    ((Finset.range (n + 1) ×ˢ Finset.range (n + 1)).filter
      (fun ab : ℕ × ℕ => ab.1 + ab.2 ≤ n ∧ (ab.1 = 0 ∨ ab.2 = 0))).card = 2 * n + 1 := by decide
-- x ↦ x^2 over F_7: roots of x^2 = c for c = 0..6 number 1, 2, 2, 0, 2, 0, 0.
example : (List.range 7).map (fun c =>
    ((Finset.univ : Finset (ZMod 7)).filter (fun x => x ^ 2 = (c : ZMod 7))).card)
    = [1, 2, 2, 0, 2, 0, 0] := by decide
-- Etale points of x ↦ x^2 over F_7, where 2x ≠ 0: 6 of 7.
example : ((Finset.univ : Finset (ZMod 7)).filter (fun x => 2 * x ≠ 0)).card = 6 := by decide
-- Over F_2, 2x = 0 everywhere: 0 etale points of 2.
example : ((Finset.univ : Finset (ZMod 2)).filter (fun x => 2 * x ≠ 0)).card = 0 := by decide
-- Spec Z[i] → Spec Z: roots of x^2 + 1 mod 5, 13, 29 are 2 and 3, 5 and 8, 12 and 17.
example : ((Finset.range 5).filter (fun x => (x * x + 1) % 5 = 0)) = {2, 3} := by decide
example : ((Finset.range 13).filter (fun x => (x * x + 1) % 13 = 0)) = {5, 8} := by decide
example : ((Finset.range 29).filter (fun x => (x * x + 1) % 29 = 0)) = {12, 17} := by decide
-- Omega = Z[i]/(2i): multiplication by 2i has matrix with columns (0, 2), (-2, 0), determinant 4.
example : (0 : ℤ) * 0 - (-2) * 2 = 4 := by norm_num
-- Newton lifts of x^2 = -1 from 2 mod 5: 7, 57, 182, 2057, 14557 mod 5^2, ..., 5^6.
example : (7 ^ 2 + 1) % 5 ^ 2 = 0 ∧ (57 ^ 2 + 1) % 5 ^ 3 = 0 ∧ (182 ^ 2 + 1) % 5 ^ 4 = 0 ∧
    (2057 ^ 2 + 1) % 5 ^ 5 = 0 ∧ (14557 ^ 2 + 1) % 5 ^ 6 = 0 := by norm_num
-- Exactly 2 roots of x^2 + 1 mod 5^k for k = 1 to 3.
example : (List.range 3).map (fun k =>
    ((Finset.range (5 ^ (k + 1))).filter (fun y => (y * y + 1) % 5 ^ (k + 1) = 0)).card)
    = [2, 2, 2] := by decide
-- At 2 the root 1 does not lift: no roots of x^2 + 1 mod 4, 8 or 16.
example : (List.range 3).map (fun k =>
    ((Finset.range (2 ^ (k + 2))).filter (fun y => (y * y + 1) % 2 ^ (k + 2) = 0)).card)
    = [0, 0, 0] := by decide
-- Riemann–Hurwitz for y^2 = x^3 - x over the x-line: 2g - 2 = 2(2·0 - 2) + 4 gives g = 1,
-- matching (d - 1)(d - 2)/2 = 1 for d = 3.
example : (2 * 1 - 2 : ℤ) = 2 * (2 * 0 - 2) + 4 ∧ (3 - 1) * (3 - 2) / 2 = 1 := by norm_num

#print axioms etale_at_iff_derivative_ne_zero
#print axioms flat_over_line_iff_no_function_killed
#print axioms smooth_flat_and_etale_iff_smooth_no_differentials
