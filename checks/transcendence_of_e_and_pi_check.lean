-- Transcendence of e and pi: e and π are each a root of no nonzero polynomial with whole-number coefficients, by Hermite's integral identity and his factorial-divisibility step.
import Mathlib.Algebra.Polynomial.SumIteratedDerivative
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.NumberTheory.Transcendental.Lindemann.AnalyticalPart
import Mathlib.RingTheory.Algebraic.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Topology.Algebra.Order.Floor
import Mathlib.RingTheory.Polynomial.Tower
import Mathlib.FieldTheory.Galois.Basic
import Mathlib.FieldTheory.SplittingField.Construction
import Mathlib.FieldTheory.IsAlgClosed.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.RingTheory.Polynomial.RationalRoot
import Mathlib.RingTheory.Polynomial.ScaleRoots
import Mathlib.RingTheory.Algebraic.Integral
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Polynomial

open Polynomial
open scoped Nat

/-- Hermite's auxiliary polynomial for a relation of degree n:
f(x) = x^(p-1) (x - 1)^p (x - 2)^p ... (x - n)^p, with whole-number coefficients. -/
noncomputable def hermitePoly (n p : ℕ) : ℤ[X] :=
  X ^ (p - 1) * ∏ k ∈ Finset.Icc 1 n, (X - C (k : ℤ)) ^ p

/-- The whole number N = a_0 F(0) + a_1 F(1) + ... + a_n F(n) for the supposed relation
a_0 + a_1 e + ... + a_n e^n = 0, where F = f + f' + f'' + ... is the sum of Hermite's
polynomial and all its derivatives (Mathlib's `sumIDeriv`). -/
noncomputable def hermiteN (n p : ℕ) (a : ℕ → ℤ) : ℤ :=
  ∑ k ∈ Finset.range (n + 1), a k * (sumIDeriv (hermitePoly n p)).eval (k : ℤ)

/-! Helper lemmas for the proofs below. -/

theorem lw_core (f : ℤ[X]) (hf0 : f.eval 0 ≠ 0) (m : Multiset (ℂ × ℤ))
    (hm : ∀ x ∈ m, x.1 ∈ f.aroots ℂ) (a0 : ℤ) (ha0 : a0 ≠ 0) (L : ℤ) (hL : L ≠ 0)
    (hint : ∀ g : ℤ[X], ∃ z : ℤ,
      (L : ℂ) ^ g.natDegree * (m.map (fun x => (x.2 : ℂ) * aeval x.1 g)).sum = z)
    (hrel : (a0 : ℂ) + (m.map (fun x => (x.2 : ℂ) * Complex.exp x.1)).sum = 0) : False := by
  obtain ⟨c, hc⟩ := LindemannWeierstrass.exp_polynomial_approx f hf0
  set M := f.natDegree
  set W : ℝ := (m.map (fun x => ‖(x.2 : ℂ)‖)).sum with hW
  set K : ℝ := |(L : ℝ)| ^ M * |c| with hK
  have ht := (FloorSemiring.tendsto_pow_div_factorial_atTop K).const_mul (W * K)
  rw [mul_zero] at ht
  obtain ⟨N0, hN0⟩ := Filter.eventually_atTop.mp (ht.eventually (gt_mem_nhds one_pos))
  obtain ⟨p, hpge, hp⟩ :=
    Nat.exists_infinite_primes (N0 + 1 + (f.eval 0).natAbs + a0.natAbs + L.natAbs)
  have hsmall := hN0 (p - 1) (by omega)
  obtain ⟨np, hnp, g, hgdeg, happ⟩ := hc p (by omega) hp
  obtain ⟨z, hz⟩ := hint g
  set E := M * p with hE
  have hgE : g.natDegree ≤ E := by
    have : p * M - 1 ≤ M * p := by rw [mul_comm]; omega
    omega
  set Nint : ℤ := L ^ E * np * a0 + p * (L ^ (E - g.natDegree) * z) with hNint
  set S' : ℂ := (m.map (fun x => (x.2 : ℂ) * ((np : ℂ) * Complex.exp x.1 -
    (p : ℂ) * aeval x.1 g))).sum with hS'
  have e1 : S' = (np : ℂ) * (m.map (fun x => (x.2 : ℂ) * Complex.exp x.1)).sum -
      (p : ℂ) * (m.map (fun x => (x.2 : ℂ) * aeval x.1 g)).sum := by
    rw [hS', ← Multiset.sum_map_mul_left, ← Multiset.sum_map_mul_left, ← Multiset.sum_map_sub]
    congr 1
    apply Multiset.map_congr rfl
    intros
    ring
  have key : (Nint : ℂ) = -((L : ℂ) ^ E * S') := by
    have hsum : (m.map (fun x => (x.2 : ℂ) * Complex.exp x.1)).sum = -(a0 : ℂ) := by
      linear_combination hrel
    rw [e1, hsum, hNint]
    have : (L : ℂ) ^ E = (L : ℂ) ^ (E - g.natDegree) * (L : ℂ) ^ g.natDegree := by
      rw [← pow_add, Nat.sub_add_cancel hgE]
    push_cast
    rw [← hz, this]
    ring
  -- lower bound
  have hNint0 : Nint ≠ 0 := by
    intro h0
    have hpZ : Prime (p : ℤ) := Nat.prime_iff_prime_int.mp hp
    have hdvd : (p : ℤ) ∣ L ^ E * np * a0 := by
      have : (p : ℤ) ∣ Nint := by rw [h0]; exact dvd_zero _
      rwa [hNint, dvd_add_left (dvd_mul_right _ _)] at this
    rcases hpZ.dvd_or_dvd hdvd with h1 | h1
    · rcases hpZ.dvd_or_dvd h1 with h2 | h2
      · have h3 := hpZ.dvd_of_dvd_pow h2
        have := Nat.le_of_dvd (Int.natAbs_pos.mpr hL)
          (by simpa using Int.natAbs_dvd_natAbs.mpr h3)
        omega
      · exact hnp h2
    · have := Nat.le_of_dvd (Int.natAbs_pos.mpr ha0) (by simpa using Int.natAbs_dvd_natAbs.mpr h1)
      omega
  have hlow : (1 : ℝ) ≤ ‖(Nint : ℂ)‖ := by
    rw [Complex.norm_intCast]
    exact_mod_cast Int.one_le_abs hNint0
  -- upper bound
  have hfac : (0 : ℝ) < ((p - 1)! : ℝ) := by exact_mod_cast Nat.factorial_pos _
  have hup : ‖S'‖ ≤ W * (|c| ^ p / (p - 1)!) := by
    rw [hS']
    refine (norm_multiset_sum_le (E := ℂ) _).trans ?_
    rw [Multiset.map_map, hW, ← Multiset.sum_map_mul_right]
    refine Multiset.sum_map_le_sum_map _ _ (fun x hx => ?_)
    simp only [Function.comp_apply, norm_mul]
    apply mul_le_mul_of_nonneg_left _ (norm_nonneg _)
    have := happ (hm x hx)
    simp only [zsmul_eq_mul, nsmul_eq_mul] at this
    exact this.trans (div_le_div_of_nonneg_right ((le_abs_self (c ^ p)).trans (abs_pow c p).le)
      hfac.le)
  have hfinal : ‖(Nint : ℂ)‖ ≤ W * K * (K ^ (p - 1) / (p - 1)!) := by
    rw [key, norm_neg, norm_mul, norm_pow, Complex.norm_intCast]
    have hKp : K * K ^ (p - 1) = |(L : ℝ)| ^ E * |c| ^ p := by
      rw [← pow_succ', Nat.sub_add_cancel hp.one_le, hK, mul_pow, ← pow_mul]
    calc |(L : ℝ)| ^ E * ‖S'‖ ≤ |(L : ℝ)| ^ E * (W * (|c| ^ p / (p - 1)!)) := by
          gcongr
      _ = W * K * (K ^ (p - 1) / (p - 1)!) := by
          rw [show W * K * (K ^ (p - 1) / ((p - 1)! : ℝ)) = W * (K * K ^ (p - 1)) / (p - 1)! by
            ring, hKp]
          ring
  have : W * K * (K ^ (p - 1) / ((p - 1)! : ℝ)) < 1 := hsmall
  linarith

theorem multiset_powerset_map {α β : Type*} (f : α → β) (s : Multiset α) :
    (s.map f).powerset = s.powerset.map (Multiset.map f) := by
  induction s using Multiset.induction_on with
  | empty => simp
  | cons a s ih => simp [Multiset.powerset_cons, ih, Multiset.map_map]

theorem ringHom_aeval_int {A B : Type*} [CommRing A] [CommRing B] [Algebra ℤ A] [Algebra ℤ B]
    (ψ : A →+* B) (x : A)
    (g : ℤ[X]) : ψ (aeval x g) = aeval (ψ x) g := by
  rw [aeval_def, aeval_def, hom_eval₂, RingHom.ext_int (ψ.comp (algebraMap ℤ A)) (algebraMap ℤ B)]

theorem aroots_map_of_card {K L : Type*} [Field K] [CharZero K] [CommRing L] [IsDomain L]
    (P : ℤ[X]) (hcard : Multiset.card (P.aroots K) = P.natDegree)
    (ψ : K →+* L) (hψ : Function.Injective ψ) :
    (P.aroots K).map ψ = P.aroots L := by
  have hinj : Function.Injective (algebraMap ℤ K) := (algebraMap ℤ K).injective_int
  rw [aroots_def, roots_map_of_injective_of_card_eq_natDegree hψ, Polynomial.map_map, aroots_def]
  · congr 2; exact RingHom.ext_int _ _
  · rw [natDegree_map_eq_of_injective hinj]; rw [aroots_def] at hcard; exact hcard

theorem powerset_sum_rat (P : ℤ[X]) (g : ℤ[X]) :
    ∃ r : ℚ, ((P.aroots ℂ).powerset.map (fun t => aeval t.sum g)).sum = (r : ℂ) := by
  set Pq : ℚ[X] := P.map (Int.castRingHom ℚ) with hPq
  let K := SplittingField Pq
  have : IsGalois ℚ K := IsGalois.mk
  have hcard : Multiset.card (P.aroots K) = P.natDegree := by
    have hs := SplittingField.splits Pq
    rw [splits_iff_card_roots, hPq, Polynomial.map_map] at hs
    rw [aroots_def, show algebraMap ℤ K = (algebraMap ℚ K).comp (Int.castRingHom ℚ) from
      RingHom.ext_int _ _, hs]
    exact natDegree_map_eq_of_injective (RingHom.injective_int _) P
  have key : ∀ {L : Type} [Field L] [CharZero L] (ψ : K →+* L),
      ψ (((P.aroots K).powerset.map (fun t => aeval t.sum g)).sum) =
        ((P.aroots L).powerset.map (fun t => aeval t.sum g)).sum := by
    intro L _ _ ψ
    rw [← aroots_map_of_card P hcard ψ ψ.injective, multiset_powerset_map, Multiset.map_map,
      map_multiset_sum, Multiset.map_map]
    congr 1
    apply Multiset.map_congr rfl
    intro t _
    simp only [Function.comp_apply]
    rw [ringHom_aeval_int, map_multiset_sum]
  set SK : K := ((P.aroots K).powerset.map (fun t => aeval t.sum g)).sum with hSK
  have hfix : ∀ σ : K ≃ₐ[ℚ] K, σ SK = SK := by
    intro σ
    have := key (σ : K →+* K)
    exact this
  have hbot : SK ∈ (⊥ : IntermediateField ℚ K) := (IsGalois.mem_bot_iff_fixed SK).mpr hfix
  obtain ⟨r, hr⟩ := IntermediateField.mem_bot.mp hbot
  let phi : K →ₐ[ℚ] ℂ := IsAlgClosed.lift
  refine ⟨r, ?_⟩
  rw [← key (phi : K →+* ℂ), ← hr]
  change phi (algebraMap ℚ K r) = _
  rw [AlgHom.commutes]
  simp

theorem exists_nonzero_const_root {A : Type*} [CommRing A] [IsDomain A] [Algebra ℤ A]
    (x : A) (hx : x ≠ 0) (P : ℤ[X]) (hP : P ≠ 0) (hPx : aeval x P = 0) :
    ∃ q : ℤ[X], q.eval 0 ≠ 0 ∧ aeval x q = 0 := by
  obtain ⟨q, hPq, hq⟩ := P.exists_eq_pow_rootMultiplicity_mul_and_not_dvd hP 0
  refine ⟨q, ?_, ?_⟩
  · rw [C_0, sub_zero, X_dvd_iff, coeff_zero_eq_eval_zero] at hq
    exact hq
  · rw [hPq, map_mul, map_pow, C_0, sub_zero, aeval_X] at hPx
    exact (mul_eq_zero.mp hPx).resolve_left (pow_ne_zero _ hx)

theorem exists_poly_with_roots (S : Multiset ℂ) (hS : ∀ b ∈ S, b ≠ 0 ∧ IsAlgebraic ℤ b) :
    ∃ f : ℤ[X], f.eval 0 ≠ 0 ∧ ∀ b ∈ S, b ∈ f.aroots ℂ := by
  induction S using Multiset.induction_on with
  | empty => exact ⟨1, by simp, by simp⟩
  | cons a S ih =>
    obtain ⟨f, hf0, hf⟩ := ih (fun b hb => hS b (Multiset.mem_cons_of_mem hb))
    obtain ⟨ha0, P, hP0, hPa⟩ := hS a (Multiset.mem_cons_self a S)
    obtain ⟨q, hq0, hqa⟩ := exists_nonzero_const_root a ha0 P hP0 hPa
    have hqf0 : (q * f).eval 0 ≠ 0 := by rw [eval_mul]; exact mul_ne_zero hq0 hf0
    refine ⟨q * f, hqf0, fun b hb => ?_⟩
    have hne : q * f ≠ 0 := fun h => hqf0 (by rw [h, eval_zero])
    rw [mem_aroots]
    refine ⟨hne, ?_⟩
    rcases Multiset.mem_cons.mp hb with rfl | hb
    · rw [map_mul, hqa, zero_mul]
    · rw [map_mul, (mem_aroots.mp (hf b hb)).2, mul_zero]

theorem isAlgebraic_multiset_sum (t : Multiset ℂ) (ht : ∀ x ∈ t, IsAlgebraic ℤ x) :
    IsAlgebraic ℤ t.sum := by
  induction t using Multiset.induction_on with
  | empty => simpa using isAlgebraic_zero
  | cons a t ih =>
    rw [Multiset.sum_cons]
    exact (ht a (Multiset.mem_cons_self a t)).add
      (ih (fun x hx => ht x (Multiset.mem_cons_of_mem hx)))

theorem isIntegral_scaled_aeval (L : ℤ) (b : ℂ) (hb : IsIntegral ℤ ((L : ℂ) * b)) (g : ℤ[X]) :
    IsIntegral ℤ ((L : ℂ) ^ g.natDegree * aeval b g) := by
  have h1 := scaleRoots_eval₂_mul (p := g) (algebraMap ℤ ℂ) b L
  rw [← aeval_def, ← aeval_def, algebraMap_int_eq, eq_intCast] at h1
  rw [← h1]
  let y : integralClosure ℤ ℂ := ⟨(L : ℂ) * b, hb⟩
  have := (aeval y (scaleRoots g L)).2
  rw [aeval_subalgebra_coe] at this
  exact this

theorem int_of_rat_integral (r : ℚ) (h : IsIntegral ℤ (r : ℂ)) : ∃ z : ℤ, (r : ℂ) = z := by
  have h' : IsIntegral ℤ r := by
    rw [← isIntegral_algebraMap_iff (A := ℚ) (B := ℂ)]
    simpa using h
  obtain ⟨z, hz⟩ := IsIntegrallyClosed.isIntegral_iff.mp h'
  refine ⟨z, ?_⟩
  rw [← hz]
  simp

theorem e_transcendental : Transcendental ℤ (Real.exp 1) := by
  rintro ⟨P, hP0, hPe⟩
  obtain ⟨q, hq0, hqe⟩ := exists_nonzero_const_root _ (Real.exp_pos 1).ne' P hP0 hPe
  set N := q.natDegree
  have hqc : aeval (Complex.exp 1) q = 0 := by
    have := congrArg (algebraMap ℝ ℂ) hqe
    rw [← aeval_algebraMap_apply, map_zero] at this
    have h1 : (algebraMap ℝ ℂ) (Real.exp 1) = Complex.exp 1 := by simp [Complex.ofReal_exp]
    rwa [h1] at this
  rw [aeval_eq_sum_range, Finset.sum_range_succ'] at hqc
  set f : ℤ[X] := ∏ j ∈ Finset.range N, (X - C (((j + 1 : ℕ) : ℤ))) with hf
  have hf0 : f.eval 0 ≠ 0 := by
    rw [hf, eval_prod, Finset.prod_ne_zero_iff]
    intro j _
    simp only [eval_sub, eval_X, eval_C, zero_sub, neg_ne_zero]
    omega
  set m : Multiset (ℂ × ℤ) := (Finset.range N).val.map
    (fun j => ((((j + 1 : ℕ) : ℤ) : ℂ), q.coeff (j + 1))) with hm
  refine lw_core f hf0 m ?_ (q.coeff 0) ?_ 1 one_ne_zero ?_ ?_
  · intro x hx
    rw [hm, Multiset.mem_map] at hx
    obtain ⟨j, hj, rfl⟩ := hx
    rw [mem_aroots]
    refine ⟨fun h => hf0 (by rw [h, eval_zero]), ?_⟩
    · rw [hf, map_prod]
      exact Finset.prod_eq_zero hj (by simp)
  · rwa [coeff_zero_eq_eval_zero]
  · intro g
    refine ⟨∑ j ∈ Finset.range N, q.coeff (j + 1) * g.eval (((j + 1 : ℕ) : ℤ)), ?_⟩
    rw [hm, Multiset.map_map]
    simp only [one_pow, Int.cast_one, one_mul, Int.cast_sum, Int.cast_mul]
    rw [Finset.sum_eq_multiset_sum]
    congr 1
    apply Multiset.map_congr rfl
    intro j _
    simp only [Function.comp_apply]
    congr 1
    rw [show ((((j + 1 : ℕ) : ℤ)) : ℂ) = algebraMap ℤ ℂ ((j + 1 : ℕ) : ℤ) by simp,
      aeval_algebraMap_apply_eq_algebraMap_eval]
    simp
  · have h2 : (m.map (fun x => (x.2 : ℂ) * Complex.exp x.1)).sum =
        ∑ k ∈ Finset.range N, q.coeff (k + 1) • Complex.exp 1 ^ (k + 1) := by
      rw [hm, Multiset.map_map, Finset.sum_eq_multiset_sum]
      congr 1
      apply Multiset.map_congr rfl
      intro j _
      rw [Function.comp_apply, zsmul_eq_mul, ← Complex.exp_nat_mul, mul_one]
      push_cast
      rfl
    rw [h2, ← hqc]
    simp [add_comm]
    rfl

theorem pi_transcendental : Transcendental ℤ Real.pi := by
  intro hpi
  have hI : IsAlgebraic ℤ Complex.I := by
    refine ⟨X ^ 2 + 1, fun h => ?_, by simp⟩
    have := congrArg (eval 0) h
    simp at this
  have hpiC : IsAlgebraic ℤ ((Real.pi : ℂ)) := hpi.algebraMap
  obtain ⟨P, hP0, hPz⟩ := hpiC.mul hI
  set α := P.aroots ℂ with hα
  have hzα : (Real.pi : ℂ) * Complex.I ∈ α := mem_aroots.mpr ⟨hP0, hPz⟩
  have hprod : (α.map (fun x => Complex.exp x + 1)).prod = 0 :=
    Multiset.prod_eq_zero (Multiset.mem_map.mpr ⟨_, hzα, by rw [Complex.exp_pi_mul_I]; ring⟩)
  rw [Multiset.prod_map_add] at hprod
  simp only [Multiset.map_const', Multiset.prod_replicate, one_pow, mul_one] at hprod
  have hB : ((α.powerset.map Multiset.sum).map Complex.exp).sum = 0 := by
    rw [← hprod, ← Multiset.antidiagonal_map_fst, Multiset.map_map, Multiset.map_map]
    congr 1
    apply Multiset.map_congr rfl
    intro x _
    simp [Complex.exp_multiset_sum]
  set B := α.powerset.map Multiset.sum with hBdef
  set B0 := B.filter (fun a => a = 0) with hB0
  set B' := B.filter (fun a => ¬ a = 0) with hB'
  have hsplit : B0 + B' = B := Multiset.filter_add_not _ B
  have h0B : (0 : ℂ) ∈ B0 := Multiset.mem_filter.mpr
    ⟨Multiset.mem_map.mpr ⟨0, Multiset.zero_mem_powerset α, Multiset.sum_zero⟩, rfl⟩
  set k := Multiset.card B0 with hkdef
  have hk : (k : ℤ) ≠ 0 := by
    have := Multiset.card_pos_iff_exists_mem.mpr ⟨0, h0B⟩
    omega
  have hB0const : ∀ h : ℂ → ℂ, B0.map h = Multiset.replicate k (h 0) := by
    intro h
    rw [Multiset.eq_replicate]
    refine ⟨by simp [hkdef], fun y hy => ?_⟩
    obtain ⟨b, hb, rfl⟩ := Multiset.mem_map.mp hy
    rw [(Multiset.mem_filter.mp hb).2]
  have hsumsplit : ∀ h : ℂ → ℂ, (B.map h).sum = k * h 0 + (B'.map h).sum := by
    intro h
    conv_lhs => rw [← hsplit]
    rw [Multiset.map_add, Multiset.sum_add, hB0const, Multiset.sum_replicate, nsmul_eq_mul]
  have hαalg : ∀ x ∈ α, IsAlgebraic ℤ x := fun x hx => ⟨P, hP0, (mem_aroots.mp hx).2⟩
  set L := P.leadingCoeff with hLdef
  have hL : L ≠ 0 := leadingCoeff_ne_zero.mpr hP0
  have hαint : ∀ x ∈ α, IsIntegral ℤ ((L : ℂ) * x) := fun x hx => by
    have := isIntegral_leadingCoeff_smul P x (mem_aroots.mp hx).2
    rwa [zsmul_eq_mul] at this
  have hBmem : ∀ b ∈ B, ∃ t ≤ α, t.sum = b := fun b hb => by
    obtain ⟨t, ht, rfl⟩ := Multiset.mem_map.mp hb
    exact ⟨t, Multiset.mem_powerset.mp ht, rfl⟩
  have hBalg : ∀ b ∈ B, IsAlgebraic ℤ b := fun b hb => by
    obtain ⟨t, ht, rfl⟩ := hBmem b hb
    exact isAlgebraic_multiset_sum t (fun x hx => hαalg x (Multiset.mem_of_le ht hx))
  have hBint : ∀ b ∈ B, IsIntegral ℤ ((L : ℂ) * b) := fun b hb => by
    obtain ⟨t, ht, rfl⟩ := hBmem b hb
    rw [show t.sum = (t.map id).sum by rw [Multiset.map_id], ← Multiset.sum_map_mul_left]
    exact IsIntegral.multiset_sum (fun y hy => by
      obtain ⟨x, hx, rfl⟩ := Multiset.mem_map.mp hy
      exact hαint x (Multiset.mem_of_le ht hx))
  have hB'B : ∀ b ∈ B', b ∈ B := fun b hb => (Multiset.mem_filter.mp hb).1
  obtain ⟨f, hf0, hfr⟩ := exists_poly_with_roots B'
    (fun b hb => ⟨(Multiset.mem_filter.mp hb).2, hBalg b (hB'B b hb)⟩)
  refine lw_core f hf0 (B'.map (fun b => (b, (1 : ℤ)))) ?_ (k : ℤ) hk L hL ?_ ?_
  · intro x hx
    obtain ⟨b, hb, rfl⟩ := Multiset.mem_map.mp hx
    exact hfr b hb
  · intro g
    obtain ⟨r, hr⟩ := powerset_sum_rat P g
    have h2 : (B.map (fun b => aeval b g)).sum = r := by
      rw [hBdef, Multiset.map_map]
      exact hr
    have h1 := hsumsplit (fun b => aeval b g)
    have hT : (B'.map (fun b => aeval b g)).sum = ((r - k * g.coeff 0 : ℚ) : ℂ) := by
      rw [← coeff_zero_eq_aeval_zero'] at h1
      push_cast
      rw [← h2, h1]
      simp
    have hInt : IsIntegral ℤ ((L : ℂ) ^ g.natDegree * (B'.map (fun b => aeval b g)).sum) := by
      rw [← Multiset.sum_map_mul_left]
      exact IsIntegral.multiset_sum (fun y hy => by
        obtain ⟨b, hb, rfl⟩ := Multiset.mem_map.mp hy
        exact isIntegral_scaled_aeval L b (hBint b (hB'B b hb)) g)
    rw [hT] at hInt
    obtain ⟨z, hz⟩ := int_of_rat_integral ((L : ℚ) ^ g.natDegree * (r - k * g.coeff 0))
      (by push_cast at hInt ⊢; exact hInt)
    refine ⟨z, ?_⟩
    rw [Multiset.map_map]
    simp only [Function.comp_apply, Int.cast_one, one_mul]
    rw [hT, ← hz]
    push_cast
    ring
  · rw [Multiset.map_map]
    simp only [Function.comp_apply, Int.cast_one, one_mul]
    have := hsumsplit Complex.exp
    rw [hB, Complex.exp_zero, mul_one] at this
    push_cast
    linear_combination -this

#print axioms lw_core
#print axioms multiset_powerset_map
#print axioms ringHom_aeval_int
#print axioms aroots_map_of_card
#print axioms powerset_sum_rat
#print axioms exists_nonzero_const_root
#print axioms exists_poly_with_roots
#print axioms isAlgebraic_multiset_sum
#print axioms isIntegral_scaled_aeval
#print axioms int_of_rat_integral
#print axioms e_transcendental
#print axioms pi_transcendental

/-- Hermite (1873) and Lindemann (1882): e and π are transcendental. Neither is a root of a
nonzero polynomial with whole-number coefficients: no whole numbers a_0, ..., a_n, not all 0,
make a_0 + a_1 e + ... + a_n e^n = 0, and the same holds with π in place of e. -/
theorem e_and_pi_are_transcendental :
    Transcendental ℤ (Real.exp 1) ∧ Transcendental ℤ Real.pi := by
  exact ⟨e_transcendental, pi_transcendental⟩

/-- Step 1, Hermite's integral identity: for a polynomial f with F = f + f' + f'' + ... the sum
of f and all its derivatives, the integral from 0 to k of e^(k - u) f(u) du equals
e^k F(0) - F(k). -/
theorem hermite_integral_eq (f : ℝ[X]) (k : ℝ) :
    ∫ u in (0 : ℝ)..k, Real.exp (k - u) * f.eval u =
      Real.exp k * (sumIDeriv f).eval 0 - (sumIDeriv f).eval k := by
  have hd : ∀ u : ℝ, HasDerivAt (fun u => -(Real.exp (k - u) * (sumIDeriv f).eval u))
      (Real.exp (k - u) * f.eval u) u := by
    intro u
    have h1 : HasDerivAt (fun u => Real.exp (k - u)) (Real.exp (k - u) * (-1)) u := by
      have := ((hasDerivAt_id u).const_sub k).exp
      simpa using this
    have h2 := (sumIDeriv f).hasDerivAt u
    convert (h1.mul h2).neg using 1
    rw [← sumIDeriv_derivative]
    conv_lhs => rw [eq_sub_of_add_eq (sumIDeriv_eq_self_add f).symm]
    rw [sumIDeriv_derivative, eval_sub]
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun u _ => hd u)
    (Continuous.intervalIntegrable (by fun_prop) _ _)]
  simp
  ring

/-- Step 3, the factorial step: take whole numbers a_0, ..., a_n with a nonzero constant term
a_0, and a prime p larger than n and than |a_0|. With Hermite's polynomial
f(x) = x^(p-1) (x - 1)^p ... (x - n)^p and F the sum of f and its derivatives, the whole number
N = a_0 F(0) + a_1 F(1) + ... + a_n F(n) is divisible by (p - 1)! but not by p!, so it is
nonzero and at least (p - 1)! in size. -/
theorem hermite_N_divisible_by_factorial_not_by_p (n p : ℕ) (a : ℕ → ℤ)
    (hp : p.Prime) (hpn : n < p) (ha0 : a 0 ≠ 0) (hpa : (a 0).natAbs < p) :
    ((p - 1)! : ℤ) ∣ hermiteN n p a ∧ ¬ ((p ! : ℤ) ∣ hermiteN n p a) := by
  set h := hermitePoly n p with hh
  set Q : ℤ[X] := ∏ k ∈ Finset.Icc 1 n, (X - C (k : ℤ)) ^ p with hQ
  obtain ⟨gp, -, hgp⟩ := aeval_sumIDeriv (A := ℤ) h p
  obtain ⟨gp', -, hgp'⟩ := eval_sumIDeriv_of_pos h hp.pos
  have hF0 : (sumIDeriv h).eval 0 = (p - 1)! * Q.eval 0 + p ! * gp'.eval 0 := by
    rw [hgp' 0 (p' := Q) (by rw [hh, hermitePoly, C_0, sub_zero])]
    simp
  have hFk : ∀ k ∈ Finset.range n, (sumIDeriv h).eval ((k + 1 : ℕ) : ℤ) =
      p ! * gp.eval ((k + 1 : ℕ) : ℤ) := by
    intro k hk
    have := hgp ((k + 1 : ℕ) : ℤ) (by
      rw [algebraMap_int_eq, show Int.castRingHom ℤ = RingHom.id ℤ from RingHom.ext_int _ _,
        Polynomial.map_id, hh, hermitePoly]
      apply dvd_mul_of_dvd_right
      exact Finset.dvd_prod_of_mem (fun k : ℕ => (X - C (k : ℤ)) ^ p)
        (Finset.mem_Icc.mpr ⟨by omega, by simp at hk; omega⟩))
    simpa using this
  have hN : hermiteN n p a = (p - 1)! * (a 0 * Q.eval 0 + p * (a 0 * gp'.eval 0 +
      ∑ k ∈ Finset.range n, a (k + 1) * gp.eval ((k + 1 : ℕ) : ℤ))) := by
    rw [hermiteN, Finset.sum_range_succ', Finset.sum_congr rfl (fun k hk => by rw [hFk k hk])]
    simp only [Nat.cast_zero]
    rw [show (sumIDeriv (hermitePoly n p)) = sumIDeriv h from rfl, hF0,
      ← Nat.mul_factorial_pred hp.ne_zero]
    push_cast
    have : ∀ x ∈ Finset.range n, a (x + 1) * (↑p * ↑(p - 1)! * eval ((x : ℤ) + 1) gp) =
        (↑p * ↑(p - 1)!) * (a (x + 1) * eval ((x : ℤ) + 1) gp) := fun _ _ => by ring
    rw [Finset.sum_congr rfl this, ← Finset.mul_sum]
    ring
  refine ⟨hN ▸ Dvd.intro _ rfl, ?_⟩
  rw [hN, ← Nat.mul_factorial_pred hp.ne_zero, Nat.cast_mul, mul_comm (p : ℤ)]
  intro hdvd
  have hfac : ((p - 1)! : ℤ) ≠ 0 := by exact_mod_cast (Nat.factorial_pos _).ne'
  have h2 := (mul_dvd_mul_iff_left hfac).mp hdvd
  rw [dvd_add_left (dvd_mul_right _ _)] at h2
  have hpZ : Prime (p : ℤ) := Nat.prime_iff_prime_int.mp hp
  rcases hpZ.dvd_or_dvd h2 with h3 | h3
  · have := Int.natAbs_dvd_natAbs.mpr h3
    simp only [Int.natAbs_natCast] at this
    have := Nat.le_of_dvd (Int.natAbs_pos.mpr ha0) this
    omega
  · rw [hQ, eval_prod] at h3
    obtain ⟨k, hk, hk2⟩ := (hpZ.dvd_finsetProd_iff _).mp h3
    rw [eval_pow] at hk2
    have h4 := hpZ.dvd_of_dvd_pow hk2
    simp only [eval_sub, eval_X, eval_C, zero_sub, dvd_neg] at h4
    have := Nat.le_of_dvd (by simp at hk; omega) (Int.natCast_dvd_natCast.mp h4)
    simp at hk
    omega

-- The card's whole-number worked examples, for the test relation e^2 - 7e + 12 = 0.
-- At p = 3, Hermite's polynomial x^2 (x - 1)^3 (x - 2)^3 has coefficients 0, 0, 8, -36, 66, -63, 33, -9, 1.
example : (X ^ 2 * (X - 1) ^ 3 * (X - 2) ^ 3 : ℤ[X]) =
    8 * X ^ 2 - 36 * X ^ 3 + 66 * X ^ 4 - 63 * X ^ 5 + 33 * X ^ 6 - 9 * X ^ 7 + X ^ 8 := by
  ring
-- F(0) is the sum of each coefficient times i!, which gives 12,544.
example : (8 * Nat.factorial 2 - 36 * Nat.factorial 3 + 66 * Nat.factorial 4 - 63 * Nat.factorial 5 +
    33 * Nat.factorial 6 - 9 * Nat.factorial 7 + Nat.factorial 8 : ℤ) = 12544 := by
  norm_num [Nat.factorial]
-- At p = 13: 12! = 479,001,600, 2^13 = 8,192, and N divided by 12! leaves remainder 0.
example : Nat.factorial 12 = 479001600 ∧ 2 ^ 13 = 8192 := by norm_num [Nat.factorial]
example : 67073474332490453793195606059293473636326400 =
    Nat.factorial 12 * 140027662397141165693800617908778329 := by
  norm_num [Nat.factorial]
-- N / 12! leaves 11 on division by 13, as Step 3 predicts: 12 * 2^13 = 24 mod 13, and 2^12 leaves 1.
example : 140027662397141165693800617908778329 % 13 = 11 ∧ (12 * 2 ^ 13) % 13 = 11 ∧
    2 ^ 12 % 13 = 1 := by norm_num
-- The predicted remainders 12 * 2^p mod p match the code's table at p = 5, 7, 11, 13, 17, 19, 23.
example : (12 * 2 ^ 5) % 5 = 4 ∧ (12 * 2 ^ 7) % 7 = 3 ∧ (12 * 2 ^ 11) % 11 = 2 ∧
    (12 * 2 ^ 13) % 13 = 11 ∧ (12 * 2 ^ 17) % 17 = 7 ∧ (12 * 2 ^ 19) % 19 = 5 ∧
    (12 * 2 ^ 23) % 23 = 1 := by norm_num
-- The crude bound 33.81 * 2^(2p - 1): still above 12! at p = 13, below 16! at p = 17.
example : Nat.factorial 12 < 33 * 2 ^ 25 ∧ 34 * 2 ^ 33 < Nat.factorial 16 := by norm_num [Nat.factorial]
-- The stand-in for π's conjugates: the six nonzero subset sums of the roots of x^3 - 2
-- solve (x^3 - 2)(x^3 + 2) = x^6 - 4.
example : ((X ^ 3 - 2) * (X ^ 3 + 2) : ℤ[X]) = X ^ 6 - 4 := by ring

#print axioms e_and_pi_are_transcendental
#print axioms hermite_integral_eq
#print axioms hermite_N_divisible_by_factorial_not_by_p
