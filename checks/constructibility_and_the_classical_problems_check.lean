-- Straightedge and compass: every constructible length has degree a power of 2, a regular n-gon is constructible exactly when φ(n) is a power of 2 (n a power of 2 times distinct Fermat primes), and doubling the cube, trisecting 60° and squaring the circle are impossible.
import Mathlib
import Mathlib.FieldTheory.IntermediateField.Adjoin.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Nat.Totient
import Mathlib.Data.ZMod.Basic
import Mathlib.NumberTheory.Fermat
import Mathlib.Tactic.NormNum.Prime

open IntermediateField Real

/-- The lengths that can be built from the length 1 with an unmarked straightedge and a compass,
in finitely many exact steps. Each step adds, subtracts, multiplies or divides two lengths
already built, or takes the square root of one: the crossing points of lines and circles have
coordinates `v + w √s` with `v`, `w`, `s` already built (the geometry wing's ruler-and-compass
card). Being an inductive definition, every member is reached in finitely many steps, and the
only starting length is 1. -/
inductive Constructible : ℝ → Prop
  | one : Constructible 1
  | add {x y : ℝ} : Constructible x → Constructible y → Constructible (x + y)
  | neg {x : ℝ} : Constructible x → Constructible (-x)
  | mul {x y : ℝ} : Constructible x → Constructible y → Constructible (x * y)
  | inv {x : ℝ} : Constructible x → Constructible x⁻¹
  | sqrt {x : ℝ} : Constructible x → 0 ≤ x → Constructible (√x)

section Helpers

open Polynomial

/-- Fields reached from the fractions by adjoining square roots one at a time. -/
inductive QTower {E : Type*} [Field E] [CharZero E] : IntermediateField ℚ E → Prop
  | base : QTower ⊥
  | step {K : IntermediateField ℚ E} {s : E} : QTower K → s ^ 2 ∈ K →
      QTower (IntermediateField.adjoin ℚ (insert s (K : Set E)))

theorem qtower_merge {E : Type*} [Field E] [CharZero E] {K1 K2 : IntermediateField ℚ E}
    (h1 : QTower K1) (h2 : QTower K2) : ∃ K, QTower K ∧ K1 ≤ K ∧ K2 ≤ K := by
  induction h2 with
  | base => exact ⟨K1, h1, le_rfl, bot_le⟩
  | @step K2 s _ hs ih =>
    obtain ⟨K, hK, h1K, h2K⟩ := ih
    refine ⟨_, QTower.step hK (h2K hs), ?_, ?_⟩
    · exact le_trans h1K (fun x hx => IntermediateField.subset_adjoin ℚ _
        (Set.mem_insert_of_mem _ hx))
    · exact IntermediateField.adjoin.mono ℚ _ _ (Set.insert_subset_insert h2K)

theorem qtower_step_finrank {E : Type*} [Field E] [CharZero E] (K : IntermediateField ℚ E)
    (s : E) :
    Module.finrank ℚ (IntermediateField.adjoin ℚ (insert s (K : Set E))) =
      Module.finrank ℚ K * Module.finrank K (IntermediateField.adjoin K {s}) := by
  have e : IntermediateField.adjoin ℚ (insert s (K : Set E)) =
      (IntermediateField.adjoin K {s}).restrictScalars ℚ := by
    rw [IntermediateField.restrictScalars_adjoin, Set.union_comm, Set.singleton_union]
  have : Module.Free K (IntermediateField.adjoin K {s}) := Module.Free.of_divisionRing _ _
  rw [e]
  exact (Module.finrank_mul_finrank ℚ K (IntermediateField.adjoin K {s})).symm

theorem qtower_rel_finrank {E : Type*} [Field E] [CharZero E] (K : IntermediateField ℚ E)
    (s : E) (hs : s ^ 2 ∈ K) :
    Module.finrank K (IntermediateField.adjoin K {s}) = 1 ∨
      Module.finrank K (IntermediateField.adjoin K {s}) = 2 := by
  set d : K := ⟨s ^ 2, hs⟩
  have hroot : Polynomial.aeval s (Polynomial.X ^ 2 - Polynomial.C d) = 0 := by
    simp [d]
  have hmon : (Polynomial.X ^ 2 - Polynomial.C d).Monic :=
    Polynomial.monic_X_pow_sub_C d two_ne_zero
  have hint : IsIntegral K s := ⟨_, hmon, by simpa [Polynomial.aeval_def] using hroot⟩
  rw [IntermediateField.adjoin.finrank hint]
  have hdvd := minpoly.dvd K s hroot
  have hle : (minpoly K s).natDegree ≤ 2 := by
    have := Polynomial.natDegree_le_of_dvd hdvd hmon.ne_zero
    rwa [Polynomial.natDegree_X_pow_sub_C] at this
  have hpos := minpoly.natDegree_pos hint
  omega

theorem qtower_finrank {E : Type*} [Field E] [CharZero E] {K : IntermediateField ℚ E}
    (h : QTower K) : ∃ k : ℕ, Module.finrank ℚ K = 2 ^ k := by
  induction h with
  | base => exact ⟨0, by simp⟩
  | @step K s _ hs ih =>
    obtain ⟨k, hk⟩ := ih
    rw [qtower_step_finrank K s, hk]
    rcases qtower_rel_finrank K s hs with h | h
    · exact ⟨k, by rw [h, mul_one]⟩
    · exact ⟨k + 1, by rw [h, pow_succ]⟩

theorem constructible_tower {E : Type*} [Field E] [CharZero E] (ι : ℝ →+* E) {x : ℝ}
    (h : Constructible x) : ∃ K : IntermediateField ℚ E, QTower K ∧ ι x ∈ K := by
  induction h with
  | one => exact ⟨⊥, QTower.base, by simp⟩
  | add _ _ ihx ihy =>
    obtain ⟨K1, h1, hx⟩ := ihx
    obtain ⟨K2, h2, hy⟩ := ihy
    obtain ⟨K, hK, l1, l2⟩ := qtower_merge h1 h2
    exact ⟨K, hK, by rw [map_add]; exact add_mem (l1 hx) (l2 hy)⟩
  | neg _ ihx =>
    obtain ⟨K, hK, hx⟩ := ihx
    exact ⟨K, hK, by rw [map_neg]; exact neg_mem hx⟩
  | mul _ _ ihx ihy =>
    obtain ⟨K1, h1, hx⟩ := ihx
    obtain ⟨K2, h2, hy⟩ := ihy
    obtain ⟨K, hK, l1, l2⟩ := qtower_merge h1 h2
    exact ⟨K, hK, by rw [map_mul]; exact mul_mem (l1 hx) (l2 hy)⟩
  | inv _ ihx =>
    obtain ⟨K, hK, hx⟩ := ihx
    exact ⟨K, hK, by rw [map_inv₀]; exact inv_mem hx⟩
  | @sqrt x _ hx0 ihx =>
    obtain ⟨K, hK, hx⟩ := ihx
    refine ⟨_, QTower.step (s := ι (√x)) hK ?_,
      IntermediateField.subset_adjoin ℚ _ (Set.mem_insert _ _)⟩
    rw [← map_pow, Real.sq_sqrt hx0]; exact hx

theorem qtower_mem_finrank {E : Type*} [Field E] [CharZero E] {K : IntermediateField ℚ E}
    (h : QTower K) {x : E} (hx : x ∈ K) : ∃ j : ℕ, Module.finrank ℚ ℚ⟮x⟯ = 2 ^ j := by
  obtain ⟨k, hk⟩ := qtower_finrank h
  have hd : Module.finrank ℚ ℚ⟮x⟯ ∣ Module.finrank ℚ K :=
    IntermediateField.finrank_dvd_of_le_right (IntermediateField.adjoin_simple_le_iff.mpr hx)
  rw [hk] at hd
  obtain ⟨j, -, hj⟩ := (Nat.dvd_prime_pow Nat.prime_two).1 hd
  exact ⟨j, hj⟩

theorem constructible_degree_pow_two {α : ℝ} (h : Constructible α) :
    ∃ k : ℕ, Module.finrank ℚ ℚ⟮α⟯ = 2 ^ k := by
  obtain ⟨K, hK, hα⟩ := constructible_tower (RingHom.id ℝ) h
  exact qtower_mem_finrank hK hα

theorem cons_zero : Constructible 0 := by
  simpa using Constructible.add Constructible.one (Constructible.neg Constructible.one)

theorem cons_sub {x y : ℝ} (hx : Constructible x) (hy : Constructible y) :
    Constructible (x - y) := by
  simpa [sub_eq_add_neg] using Constructible.add hx (Constructible.neg hy)

theorem cons_div {x y : ℝ} (hx : Constructible x) (hy : Constructible y) :
    Constructible (x / y) := by
  simpa [div_eq_mul_inv] using Constructible.mul hx (Constructible.inv hy)

theorem cons_nat (m : ℕ) : Constructible (m : ℝ) := by
  induction m with
  | zero => simpa using cons_zero
  | succ m ih => simpa using Constructible.add ih Constructible.one

theorem cons_int (m : ℤ) : Constructible (m : ℝ) := by
  rcases Int.eq_nat_or_neg m with ⟨k, rfl | rfl⟩
  · simpa using cons_nat k
  · simpa using Constructible.neg (cons_nat k)

theorem cons_rat (q : ℚ) : Constructible (q : ℝ) := by
  rw [Rat.cast_def]
  exact cons_div (cons_int _) (cons_nat _)

theorem cons_of_sq {x : ℝ} (h : Constructible (x ^ 2)) : Constructible x := by
  have hs : Constructible (√(x ^ 2)) := Constructible.sqrt h (sq_nonneg x)
  rw [Real.sqrt_sq_eq_abs] at hs
  rcases abs_choice x with h1 | h1
  · rwa [h1] at hs
  · have := Constructible.neg hs
    rwa [h1, neg_neg] at this

/-- A complex number whose two coordinates are constructible lengths. -/
def CCons (z : ℂ) : Prop := Constructible z.re ∧ Constructible z.im

theorem ccons_add {z w : ℂ} (hz : CCons z) (hw : CCons w) : CCons (z + w) :=
  ⟨by simpa using Constructible.add hz.1 hw.1, by simpa using Constructible.add hz.2 hw.2⟩

theorem ccons_neg {z : ℂ} (hz : CCons z) : CCons (-z) :=
  ⟨by simpa using Constructible.neg hz.1, by simpa using Constructible.neg hz.2⟩

theorem ccons_sub {z w : ℂ} (hz : CCons z) (hw : CCons w) : CCons (z - w) := by
  simpa [sub_eq_add_neg] using ccons_add hz (ccons_neg hw)

theorem ccons_mul {z w : ℂ} (hz : CCons z) (hw : CCons w) : CCons (z * w) :=
  ⟨by simpa using cons_sub (Constructible.mul hz.1 hw.1) (Constructible.mul hz.2 hw.2),
   by simpa using Constructible.add (Constructible.mul hz.1 hw.2) (Constructible.mul hz.2 hw.1)⟩

theorem ccons_inv {z : ℂ} (hz : CCons z) : CCons z⁻¹ := by
  have hn : Constructible (Complex.normSq z) := by
    rw [Complex.normSq_apply]
    exact Constructible.add (Constructible.mul hz.1 hz.1) (Constructible.mul hz.2 hz.2)
  exact ⟨by simpa using cons_div hz.1 hn, by simpa using cons_div (Constructible.neg hz.2) hn⟩

theorem ccons_rat (q : ℚ) : CCons (q : ℂ) :=
  ⟨by simpa using cons_rat q, by simpa using cons_zero⟩

theorem ccons_of_sq {z : ℂ} (h : CCons (z ^ 2)) : CCons z := by
  obtain ⟨h1, h2⟩ := h
  set a := z.re
  set b := z.im
  have hre : (z ^ 2).re = a ^ 2 - b ^ 2 := by simp [pow_two, a, b]
  have him : (z ^ 2).im = 2 * a * b := by simp [pow_two, a, b]; ring
  rw [hre] at h1
  rw [him] at h2
  have hN : Constructible (√((a ^ 2 - b ^ 2) ^ 2 + (2 * a * b) ^ 2)) := by
    refine Constructible.sqrt ?_ (by positivity)
    simpa [pow_two] using Constructible.add (Constructible.mul h1 h1) (Constructible.mul h2 h2)
  have hN' : √((a ^ 2 - b ^ 2) ^ 2 + (2 * a * b) ^ 2) = a ^ 2 + b ^ 2 := by
    rw [show (a ^ 2 - b ^ 2) ^ 2 + (2 * a * b) ^ 2 = (a ^ 2 + b ^ 2) ^ 2 by ring]
    exact Real.sqrt_sq (by positivity)
  rw [hN'] at hN
  have h2' : Constructible 2 := by simpa using cons_nat 2
  refine ⟨cons_of_sq ?_, cons_of_sq ?_⟩
  · have := cons_div (Constructible.add hN h1) h2'
    convert this using 1
    ring
  · have := cons_div (cons_sub hN h1) h2'
    convert this using 1
    ring

theorem cos_two_pi_div_eq (n : ℕ) :
    Complex.exp (2 * π * Complex.I / n) =
      (Real.cos (2 * π / n) : ℂ) + (Real.sin (2 * π / n) : ℂ) * Complex.I := by
  rw [show 2 * (π : ℂ) * Complex.I / n = ((2 * π / n : ℝ) : ℂ) * Complex.I by push_cast; ring,
    Complex.exp_mul_I]
  push_cast
  ring

theorem cyclo_finrank (n : ℕ) (hn : 0 < n) :
    Module.finrank ℚ ℚ⟮Complex.exp (2 * π * Complex.I / n)⟯ = n.totient := by
  have hζ := Complex.isPrimitiveRoot_exp n hn.ne'
  rw [IntermediateField.adjoin.finrank (hζ.isIntegral hn).tower_top, ← Polynomial.cyclotomic_eq_minpoly_rat hζ hn,
    Polynomial.natDegree_cyclotomic]

theorem totient_of_constructible_cos {n : ℕ} (hn : 0 < n)
    (h : Constructible (Real.cos (2 * π / n))) : ∃ k : ℕ, Nat.totient n = 2 ^ k := by
  obtain ⟨K, hK, hc⟩ := constructible_tower Complex.ofRealHom h
  set c : ℂ := (Real.cos (2 * π / n) : ℂ)
  set s : ℂ := (Real.sin (2 * π / n) : ℂ) * Complex.I
  have hs : s ^ 2 ∈ K := by
    have e : s ^ 2 = c ^ 2 - 1 := by
      simp only [s, c]
      rw [mul_pow, Complex.I_sq]
      have := Real.sin_sq_add_cos_sq (2 * π / n)
      have e2 : ((Real.sin (2 * π / n) : ℂ)) ^ 2 + (Real.cos (2 * π / n) : ℂ) ^ 2 = 1 := by
        exact_mod_cast this
      linear_combination -e2
    rw [e]
    exact sub_mem (pow_mem hc 2) (one_mem K)
  have hz : Complex.exp (2 * π * Complex.I / n) ∈
      IntermediateField.adjoin ℚ (insert s (K : Set ℂ)) := by
    rw [cos_two_pi_div_eq]
    exact add_mem (IntermediateField.subset_adjoin ℚ _ (Set.mem_insert_of_mem _ hc))
      (IntermediateField.subset_adjoin ℚ _ (Set.mem_insert _ _))
  obtain ⟨j, hj⟩ := qtower_mem_finrank (QTower.step hK hs) hz
  exact ⟨j, by rw [← cyclo_finrank n hn, hj]⟩

theorem cyclo_isCyclotomic (n : ℕ) [NeZero n] {ζ : ℂ} (hζ : IsPrimitiveRoot ζ n) :
    IsCyclotomicExtension {n} ℚ ℚ⟮ζ⟯ := by
  change IsCyclotomicExtension {n} ℚ (IntermediateField.adjoin ℚ {ζ}).toSubalgebra
  rw [IntermediateField.adjoin_simple_toSubalgebra_of_isAlgebraic
    (hζ.isIntegral (NeZero.pos n)).tower_top.isAlgebraic]
  exact hζ.adjoin_isCyclotomicExtension ℚ

/-- In a field whose automorphism group is a commutative 2-group, every element fixed by a
subgroup has constructible coordinates, by climbing through subgroups of index 2. -/
theorem ccons_of_fixed {L : IntermediateField ℚ ℂ} [IsGalois ℚ L] [FiniteDimensional ℚ L]
    (hcomm : ∀ σ τ : Gal(L/ℚ), σ * τ = τ * σ) {k : ℕ} (hcard : Nat.card Gal(L/ℚ) = 2 ^ k) :
    ∀ (H : Subgroup Gal(L/ℚ)) (x : L), (∀ h ∈ H, h x = x) → CCons (x : ℂ) := by
  suffices key : ∀ m : ℕ, ∀ (H : Subgroup Gal(L/ℚ)), Nat.card Gal(L/ℚ) - Nat.card H = m →
      ∀ x : L, (∀ h ∈ H, h x = x) → CCons (x : ℂ) from
    fun H x hx => key _ H rfl x hx
  intro m
  induction m using Nat.strong_induction_on with
  | _ m ih =>
  intro H hm x hx
  by_cases hH : ∀ g : Gal(L/ℚ), g ∈ H
  · have hbot : x ∈ (⊥ : IntermediateField ℚ L) :=
      (IsGalois.mem_bot_iff_fixed x).2 (fun g => hx g (hH g))
    obtain ⟨q, rfl⟩ := IntermediateField.mem_bot.1 hbot
    simpa using ccons_rat q
  push Not at hH
  obtain ⟨g, hg⟩ := hH
  have hex : ∃ j, g ^ (2 ^ j) ∈ H := ⟨k, by rw [← hcard, pow_card_eq_one']; exact H.one_mem⟩
  classical
  set j0 := Nat.find hex with hj0
  have hj0H : g ^ (2 ^ j0) ∈ H := Nat.find_spec hex
  have hj0pos : j0 ≠ 0 := by
    intro h0
    rw [h0, pow_zero, pow_one] at hj0H
    exact hg hj0H
  set σ := g ^ (2 ^ (j0 - 1)) with hσ
  have hσH : σ ∉ H := Nat.find_min hex (by omega)
  have hσ2 : σ * σ ∈ H := by
    rw [hσ, ← pow_add, ← two_mul, ← pow_succ', Nat.sub_add_cancel (Nat.one_le_iff_ne_zero.2 hj0pos)]
    exact hj0H
  set H' := H ⊔ Subgroup.zpowers σ with hH'
  have hlt : H < H' := by
    refine lt_of_le_of_ne le_sup_left ?_
    intro h
    apply hσH
    rw [h]
    exact Subgroup.mem_sup_right (Subgroup.mem_zpowers σ)
  have hcardlt : Nat.card H < Nat.card H' := Subgroup.card_lt_of_lt hlt
  have hcardle : Nat.card H' ≤ Nat.card Gal(L/ℚ) := Subgroup.card_le_card_group H'
  have hfix : ∀ z : L, (∀ h ∈ H, h z = z) → σ z = z → ∀ h ∈ H', h z = z := by
    intro z hzH hzσ
    have hle : H' ≤ MulAction.stabilizer Gal(L/ℚ) z := by
      refine sup_le (fun h hh => ?_) (Subgroup.zpowers_le.2 ?_)
      · rw [MulAction.mem_stabilizer_iff, AlgEquiv.smul_def]
        exact hzH h hh
      · rw [MulAction.mem_stabilizer_iff, AlgEquiv.smul_def]
        exact hzσ
    intro h hh
    have := hle hh
    rwa [MulAction.mem_stabilizer_iff, AlgEquiv.smul_def] at this
  have hτσ : ∀ τ ∈ H, τ (σ x) = σ x := by
    intro τ hτ
    rw [← AlgEquiv.mul_apply, hcomm τ σ, AlgEquiv.mul_apply, hx τ hτ]
  have hσσ : σ (σ x) = x := by
    rw [← AlgEquiv.mul_apply]
    exact hx _ hσ2
  have hb := ih (Nat.card Gal(L/ℚ) - Nat.card H') (by omega) H' rfl (x + σ x)
    (hfix _ (fun τ hτ => by rw [map_add, hx τ hτ, hτσ τ hτ]) (by rw [map_add, hσσ, add_comm]))
  have hc := ih (Nat.card Gal(L/ℚ) - Nat.card H') (by omega) H' rfl (x * σ x)
    (hfix _ (fun τ hτ => by rw [map_mul, hx τ hτ, hτσ τ hτ]) (by rw [map_mul, hσσ, mul_comm]))
  push_cast at hb hc
  have hd : CCons (((x : ℂ) - (σ x : ℂ)) ^ 2) := by
    have e : ((x : ℂ) - (σ x : ℂ)) ^ 2 = ((x : ℂ) + (σ x : ℂ)) ^ 2 - 4 * ((x : ℂ) * (σ x : ℂ)) := by
      ring
    rw [e]
    refine ccons_sub (by rw [pow_two]; exact ccons_mul hb hb) (ccons_mul ?_ hc)
    simpa using ccons_rat 4
  have hd' := ccons_of_sq hd
  have e2 : (x : ℂ) = (((x : ℂ) + (σ x : ℂ)) + ((x : ℂ) - (σ x : ℂ))) * (2 : ℂ)⁻¹ := by ring
  rw [e2]
  refine ccons_mul (ccons_add hb hd') (ccons_inv ?_)
  simpa using ccons_rat 2

theorem constructible_cos_of_totient {n : ℕ} (hn : 0 < n) {k : ℕ} (hk : Nat.totient n = 2 ^ k) :
    Constructible (Real.cos (2 * π / n)) := by
  have : NeZero n := ⟨hn.ne'⟩
  set ζ := Complex.exp (2 * π * Complex.I / n) with hζdef
  have hζ : IsPrimitiveRoot ζ n := Complex.isPrimitiveRoot_exp n hn.ne'
  have := cyclo_isCyclotomic n hζ
  have : IsGalois ℚ ℚ⟮ζ⟯ := IsCyclotomicExtension.isGalois {n} ℚ ℚ⟮ζ⟯
  have : FiniteDimensional ℚ ℚ⟮ζ⟯ :=
    IntermediateField.adjoin.finiteDimensional (hζ.isIntegral hn).tower_top
  have hcomm : ∀ σ τ : Gal(ℚ⟮ζ⟯/ℚ), σ * τ = τ * σ := by
    have := IsCyclotomicExtension.isMulCommutative {n} ℚ ℚ⟮ζ⟯
    exact fun σ τ => this.is_comm.comm σ τ
  have hcard : Nat.card Gal(ℚ⟮ζ⟯/ℚ) = 2 ^ k := by
    rw [IsGalois.card_aut_eq_finrank, cyclo_finrank n hn, hk]
  have h := ccons_of_fixed hcomm hcard ⊥ ⟨ζ, IntermediateField.mem_adjoin_simple_self ℚ ζ⟩
    (fun h hh => by rw [Subgroup.mem_bot.1 hh]; rfl)
  have h1 := h.1
  simp only at h1
  rwa [hζdef, cos_two_pi_div_eq, Complex.add_re, Complex.ofReal_re, Complex.mul_re,
    Complex.ofReal_re, Complex.ofReal_im, Complex.I_re, Complex.I_im, mul_zero, zero_mul,
    sub_zero, add_zero] at h1

theorem not_constructible_of_cubic (x : ℝ) (p : Polynomial ℚ) (hirr : Irreducible p)
    (hmon : p.Monic) (hdeg : p.natDegree = 3) (hroot : Polynomial.aeval x p = 0) :
    ¬ Constructible x := by
  intro h
  obtain ⟨k, hk⟩ := constructible_degree_pow_two h
  have hint : IsIntegral ℚ x := ⟨p, hmon, by rwa [Polynomial.aeval_def] at hroot⟩
  rw [IntermediateField.adjoin.finrank hint, ← minpoly.eq_of_irreducible_of_monic hirr hroot hmon,
    hdeg] at hk
  rcases k with _ | k
  · norm_num at hk
  · rw [pow_succ] at hk
    omega

theorem rat_cube_ne_two (b : ℚ) : b ^ 3 ≠ 2 := by
  intro hb
  have hmon : (Polynomial.X ^ 3 - Polynomial.C 2 : Polynomial ℤ).Monic :=
    Polynomial.monic_X_pow_sub_C 2 (by norm_num)
  obtain ⟨z, rfl, -⟩ := exists_integer_of_is_root_of_monic hmon (r := b)
    (by simp [hb, map_ofNat])
  rw [algebraMap_int_eq, eq_intCast] at hb
  have hz : z ^ 3 = 2 := by exact_mod_cast hb
  have h7 := congrArg (Int.cast : ℤ → ZMod 7) hz
  push_cast at h7
  generalize (z : ZMod 7) = w at h7
  revert w
  decide

theorem rat_trisect_ne (b : ℚ) : b ^ 3 - 3 * b - 1 ≠ 0 := by
  intro hb
  have hmon : (Polynomial.X ^ 3 - Polynomial.C 3 * Polynomial.X - 1 : Polynomial ℤ).Monic := by
    monicity!
  obtain ⟨z, rfl, -⟩ := exists_integer_of_is_root_of_monic hmon (r := b)
    (by simpa [map_ofNat] using hb)
  rw [algebraMap_int_eq, eq_intCast] at hb
  have hz : z ^ 3 - 3 * z - 1 = 0 := by exact_mod_cast hb
  have h2 := congrArg (Int.cast : ℤ → ZMod 2) hz
  push_cast at h2
  generalize (z : ZMod 2) = w at h2
  revert w
  decide

theorem cube_root_two_not_constructible (x : ℝ) (hx : x ^ 3 = 2) : ¬ Constructible x := by
  refine not_constructible_of_cubic x (Polynomial.X ^ 3 - Polynomial.C 2)
    (X_pow_sub_C_irreducible_of_prime Nat.prime_three rat_cube_ne_two)
    (Polynomial.monic_X_pow_sub_C 2 (by norm_num)) (by compute_degree!) ?_
  simp [hx]

theorem cos_twenty_not_constructible : ¬ Constructible (Real.cos (π / 9)) := by
  intro h
  have h2 : Constructible (2 * Real.cos (π / 9)) := by
    simpa [two_mul] using Constructible.add h h
  have hdeg : (Polynomial.X ^ 3 - Polynomial.C 3 * Polynomial.X - 1 : Polynomial ℚ).natDegree = 3 := by
    compute_degree!
  refine not_constructible_of_cubic _ (Polynomial.X ^ 3 - Polynomial.C 3 * Polynomial.X - 1)
    ?_ (by monicity!) hdeg ?_ h2
  · refine Polynomial.irreducible_of_degree_le_three_of_not_isRoot (by rw [hdeg]; decide) ?_
    intro b hb
    exact rat_trisect_ne b (by simpa using hb)
  · have h3 := Real.cos_three_mul (π / 9)
    rw [show 3 * (π / 9) = π / 3 by ring, Real.cos_pi_div_three] at h3
    simp only [map_sub, map_mul, Polynomial.aeval_X_pow, Polynomial.aeval_C, Polynomial.aeval_X,
      map_one]
    simp
    linear_combination (-2) * h3

theorem totient_fermat_prod (a : ℕ) (S : Finset ℕ)
    (hS : ∀ p ∈ S, p.Prime ∧ ∃ j : ℕ, p = Nat.fermatNumber j) :
    ∃ k : ℕ, Nat.totient (2 ^ a * ∏ p ∈ S, p) = 2 ^ k := by
  induction S using Finset.induction_on with
  | empty =>
    rcases Nat.eq_zero_or_pos a with rfl | ha
    · exact ⟨0, by simp⟩
    · exact ⟨a - 1, by rw [Finset.prod_empty, mul_one, Nat.totient_prime_pow Nat.prime_two ha]; simp⟩
  | @insert q S hqS ih =>
    obtain ⟨k, hk⟩ := ih (fun p hp => hS p (Finset.mem_insert_of_mem hp))
    obtain ⟨hq, j, rfl⟩ := hS _ (Finset.mem_insert_self _ _)
    have hq3 := Nat.three_le_fermatNumber j
    have hcop : (Nat.fermatNumber j).Coprime (2 ^ a * ∏ p ∈ S, p) := by
      refine Nat.Coprime.mul_right ?_ ?_
      · exact Nat.Coprime.pow_right _ ((Nat.coprime_primes hq Nat.prime_two).2 (by omega))
      · refine Nat.Coprime.prod_right (fun p hpS => ?_)
        obtain ⟨hp, -⟩ := hS p (Finset.mem_insert_of_mem hpS)
        exact (Nat.coprime_primes hq hp).2 (fun h => hqS (h ▸ hpS))
    refine ⟨2 ^ j + k, ?_⟩
    rw [Finset.prod_insert hqS, mul_left_comm, Nat.totient_mul hcop, Nat.totient_prime hq, hk,
      pow_add]
    simp [Nat.fermatNumber]

theorem fermat_of_totient {n k : ℕ} (h : Nat.totient n = 2 ^ k) :
    ∃ (a : ℕ) (S : Finset ℕ),
      (∀ p ∈ S, p.Prime ∧ ∃ j : ℕ, p = Nat.fermatNumber j) ∧ n = 2 ^ a * ∏ p ∈ S, p := by
  have hn : n ≠ 0 := by
    rintro rfl
    simp only [Nat.totient_zero] at h
    exact absurd h.symm (pow_ne_zero _ two_ne_zero)
  obtain ⟨a, m, hm, rfl⟩ := Nat.exists_eq_two_pow_mul_odd hn
  have hodd : ∀ p, p.Prime → p ∣ m → p ≠ 2 := by
    rintro p hp hpm rfl
    exact (Nat.not_even_iff_odd.2 hm) (even_iff_two_dvd.2 hpm)
  have hsq : Squarefree m := by
    rw [Nat.squarefree_iff_prime_squarefree]
    intro p hp hpp
    have hp' : p.Prime := hp
    have h1 : Nat.totient (p * p) ∣ 2 ^ k := h ▸ Nat.totient_dvd_of_dvd (Dvd.dvd.mul_left hpp _)
    rw [← pow_two, Nat.totient_prime_pow hp' (by norm_num), pow_one] at h1
    have h2 : p ∣ 2 ^ k := (Dvd.dvd.mul_right (dvd_refl p) _).trans h1
    have h3 : p ∣ 2 := hp'.dvd_of_dvd_pow h2
    have h4 : p = 2 := (Nat.prime_dvd_prime_iff_eq hp' Nat.prime_two).1 h3
    exact hodd p hp' (Dvd.dvd.trans (dvd_mul_right p p) hpp) h4
  refine ⟨a, m.primeFactors, fun p hpS => ?_, by rw [Nat.prod_primeFactors_of_squarefree hsq]⟩
  have hp := Nat.prime_of_mem_primeFactors hpS
  have hpm := Nat.dvd_of_mem_primeFactors hpS
  have h1 : Nat.totient p ∣ 2 ^ k := h ▸ Nat.totient_dvd_of_dvd (Dvd.dvd.mul_left hpm _)
  rw [Nat.totient_prime hp] at h1
  obtain ⟨e, -, he⟩ := (Nat.dvd_prime_pow Nat.prime_two).1 h1
  have hp2 := hodd p hp hpm
  have hp3 := hp.two_le
  have hpe : p = 2 ^ e + 1 := by omega
  have he0 : e ≠ 0 := by
    rintro rfl
    omega
  obtain ⟨j, rfl⟩ := Nat.pow_of_pow_add_prime (by norm_num) he0 (hpe ▸ hp)
  exact ⟨hp, j, hpe⟩

/-- The sums of all sub-multisets of a multiset. -/
noncomputable def subSums {α : Type*} [AddCommMonoid α] (s : Multiset α) : Multiset α :=
  s.powerset.map Multiset.sum

theorem subSums_cons {α : Type*} [AddCommMonoid α] (a : α) (s : Multiset α) :
    subSums (a ::ₘ s) = subSums s + (subSums s).map (fun x => a + x) := by
  simp [subSums, Multiset.powerset_cons, Multiset.map_map]

theorem subSums_map {α β F : Type*} [AddCommMonoid α] [AddCommMonoid β] [FunLike F α β]
    [AddMonoidHomClass F α β] (f : F) (s : Multiset α) :
    subSums (s.map f) = (subSums s).map f := by
  induction s using Multiset.induction_on with
  | empty => simp [subSums]
  | cons a s ih =>
    rw [Multiset.map_cons, subSums_cons, subSums_cons, ih, Multiset.map_add, Multiset.map_map,
      Multiset.map_map]
    congr 1
    apply Multiset.map_congr rfl
    intro x _
    simp [map_add]

theorem zero_mem_subSums {α : Type*} [AddCommMonoid α] (s : Multiset α) : 0 ∈ subSums s :=
  Multiset.mem_map.2 ⟨0, Multiset.zero_mem_powerset s, Multiset.sum_zero⟩

theorem sum_exp_subSums (A : Multiset ℂ) :
    ((subSums A).map Complex.exp).sum = (A.map (fun a => 1 + Complex.exp a)).prod := by
  induction A using Multiset.induction_on with
  | empty => simp [subSums]
  | cons a s ih =>
    rw [subSums_cons, Multiset.map_add, Multiset.sum_add, Multiset.map_map, Multiset.map_cons,
      Multiset.prod_cons, ← ih]
    have : ((subSums s).map (Complex.exp ∘ fun x => a + x)).sum =
        Complex.exp a * ((subSums s).map Complex.exp).sum := by
      rw [← Multiset.sum_map_mul_left]
      congr 1
      apply Multiset.map_congr rfl
      intro x _
      simp [Complex.exp_add]
    rw [this]
    ring

theorem galois_fixed_rat {K : Type*} [Field K] [Algebra ℚ K] [IsGalois ℚ K]
    [FiniteDimensional ℚ K] (x : K) (hx : ∀ σ : Gal(K/ℚ), σ x = x) :
    ∃ r : ℚ, x = algebraMap ℚ K r := by
  obtain ⟨r, hr⟩ := IntermediateField.mem_bot.1 ((IsGalois.mem_bot_iff_fixed x).2 hx)
  exact ⟨r, hr.symm⟩

theorem galois_prod_rat {K : Type*} [Field K] [Algebra ℚ K] [IsGalois ℚ K]
    [FiniteDimensional ℚ K] (M : Multiset K) (hM : ∀ σ : Gal(K/ℚ), M.map σ = M) :
    ∃ G : ℚ[X], G.map (algebraMap ℚ K) = (M.map (fun r => X - C r)).prod := by
  have hinv : ∀ σ : Gal(K/ℚ), ((M.map (fun r => X - C r)).prod).map (σ : K →+* K) =
      (M.map (fun r => X - C r)).prod := by
    intro σ
    rw [Polynomial.map_multiset_prod, Multiset.map_map]
    conv_rhs => rw [← hM σ, Multiset.map_map]
    congr 1
    apply Multiset.map_congr rfl
    intro x _
    simp
  have hl : (M.map (fun r => X - C r)).prod ∈ Polynomial.lifts (algebraMap ℚ K) := by
    rw [Polynomial.lifts_iff_coeff_lifts]
    intro n
    obtain ⟨r, hr⟩ := galois_fixed_rat ((M.map (fun r => X - C r)).prod.coeff n) (fun σ => by
      have := congrArg (fun p => Polynomial.coeff p n) (hinv σ)
      simpa [Polynomial.coeff_map] using this)
    exact ⟨r, hr.symm⟩
  exact (Polynomial.mem_lifts _).1 hl

theorem galois_sum_rat {K : Type*} [Field K] [Algebra ℚ K] [IsGalois ℚ K]
    [FiniteDimensional ℚ K] (M : Multiset K) (hM : ∀ σ : Gal(K/ℚ), M.map σ = M) (h : ℚ[X]) :
    ∃ r : ℚ, (M.map (fun x => aeval x h)).sum = algebraMap ℚ K r := by
  refine galois_fixed_rat _ (fun σ => ?_)
  rw [map_multiset_sum, Multiset.map_map]
  conv_rhs => rw [← hM σ, Multiset.map_map]
  congr 1
  apply Multiset.map_congr rfl
  intro x _
  simp [Polynomial.aeval_algHom_apply]

theorem int_sum_aeval (M : Multiset ℂ) (ℓ : ℤ)
    (hT : ∀ j : ℕ, ∃ z : ℤ, (M.map (fun r => ((ℓ : ℂ) * r) ^ j)).sum = z) (g : ℤ[X]) (L : ℕ)
    (hg : g.natDegree ≤ L) : ∃ z : ℤ, (ℓ : ℂ) ^ L * (M.map (fun r => aeval r g)).sum = z := by
  choose z hz using hT
  have e : ∀ r : ℂ, (ℓ : ℂ) ^ L * aeval r g = ∑ i ∈ Finset.range (L + 1),
      ((g.coeff i * ℓ ^ (L - i) : ℤ) : ℂ) * ((ℓ : ℂ) * r) ^ i := by
    intro r
    rw [aeval_eq_sum_range' (Nat.lt_succ_of_le hg), Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro i hi
    have hiL : i ≤ L := Nat.lt_succ_iff.1 (Finset.mem_range.1 hi)
    rw [zsmul_eq_mul, mul_pow]
    push_cast
    rw [show (ℓ : ℂ) ^ L = (ℓ : ℂ) ^ (L - i) * (ℓ : ℂ) ^ i by
      rw [← pow_add, Nat.sub_add_cancel hiL]]
    ring
  refine ⟨∑ i ∈ Finset.range (L + 1), g.coeff i * ℓ ^ (L - i) * z i, ?_⟩
  rw [← Multiset.sum_map_mul_left, Multiset.map_congr rfl (fun r _ => e r),
    Multiset.sum_map_sum]
  push_cast
  apply Finset.sum_congr rfl
  intro i _
  rw [Multiset.sum_map_mul_left, hz i]

theorem I_pi_not_integral : ¬ IsIntegral ℚ (Complex.I * (π : ℂ)) := by
  intro hint
  classical
  set q := minpoly ℚ (Complex.I * (π : ℂ)) with hq
  have hsep : q.Separable := (minpoly.irreducible hint).separable
  let K := q.SplittingField
  have : IsGalois ℚ K := IsGalois.of_separable_splitting_field hsep
  let φ : K →ₐ[ℚ] ℂ := Polynomial.SplittingField.lift q (IsAlgClosed.splits _)
  set AK : Multiset K := (q.map (algebraMap ℚ K)).roots with hAK
  have hsplit : (q.map (algebraMap ℚ K)).Splits := Polynomial.SplittingField.splits q
  have hAKinv : ∀ σ : Gal(K/ℚ), AK.map σ = AK := by
    intro σ
    have := hsplit.roots_map (σ : K →+* K)
    rw [Polynomial.map_map] at this
    rw [hAK]
    convert this.symm using 3
    all_goals first | rfl | exact RingHom.ext fun x => (σ.commutes x).symm
  have hA : q.aroots ℂ = AK.map φ := by
    rw [Polynomial.aroots_def, ← φ.comp_algebraMap, ← Polynomial.map_map]
    exact hsplit.roots_map (φ : K →+* ℂ)
  have hmem : Complex.I * (π : ℂ) ∈ q.aroots ℂ :=
    Polynomial.mem_aroots.2 ⟨minpoly.ne_zero hint, minpoly.aeval ℚ _⟩
  set SK := subSums AK with hSK
  have hSKinv : ∀ σ : Gal(K/ℚ), SK.map σ = SK := by
    intro σ
    rw [hSK, ← subSums_map, hAKinv]
  set M1K := SK.filter (fun x => x ≠ 0) with hM1K
  have hM1inv : ∀ σ : Gal(K/ℚ), M1K.map σ = M1K := by
    intro σ
    have h1 := Multiset.filter_map (p := fun x : K => x ≠ 0) (σ : K → K) SK
    rw [hSKinv σ] at h1
    rw [hM1K]
    conv_rhs => rw [h1]
    congr 1
    apply Multiset.filter_congr
    intro x _
    simp
  obtain ⟨G, hG⟩ := galois_prod_rat M1K hM1inv
  set M1 := M1K.map φ with hM1
  have hGC : G.map (algebraMap ℚ ℂ) = (M1.map (fun r => X - C r)).prod := by
    rw [← φ.comp_algebraMap, ← Polynomial.map_map, hG, Polynomial.map_multiset_prod,
      Multiset.map_map, hM1, Multiset.map_map]
    congr 1
    apply Multiset.map_congr rfl
    intro x _
    simp
  obtain ⟨b, hb, hf⟩ := IsLocalization.integerNormalization_spec (nonZeroDivisors ℤ) G
  set f := IsLocalization.integerNormalization (nonZeroDivisors ℤ) G with hfdef
  have hb0 : b ≠ 0 := nonZeroDivisors.ne_zero hb
  have hP0 : (M1.map (fun r => X - C r)).prod ≠ 0 :=
    (Polynomial.monic_multiset_prod_of_monic _ _ (fun r _ => Polynomial.monic_X_sub_C r)).ne_zero
  have hfC : f.map (algebraMap ℤ ℂ) = C (b : ℂ) * (M1.map (fun r => X - C r)).prod := by
    rw [show algebraMap ℤ ℂ = (algebraMap ℚ ℂ).comp (algebraMap ℤ ℚ) from
      RingHom.ext_int _ _, ← Polynomial.map_map, hf, zsmul_eq_mul, Polynomial.map_mul,
      Polynomial.map_intCast, hGC, ← Polynomial.C_eq_intCast]
  have hfmap0 : f.map (algebraMap ℤ ℂ) ≠ 0 := by
    rw [hfC]
    exact mul_ne_zero (by simpa using hb0) hP0
  have hroots : f.aroots ℂ = M1 := by
    rw [Polynomial.aroots_def, hfC, Polynomial.roots_C_mul _ (by simpa using hb0),
      Polynomial.roots_multiset_prod_X_sub_C]
  have hf0 : f.eval 0 ≠ 0 := by
    intro h0
    have h0' : (0 : ℂ) ∈ f.aroots ℂ := by
      refine Polynomial.mem_aroots.2 ⟨fun h => hfmap0 (by rw [h, Polynomial.map_zero]), ?_⟩
      rw [Polynomial.aeval_def, Polynomial.eval₂_at_zero, Polynomial.coeff_zero_eq_eval_zero, h0,
        map_zero]
    rw [hroots, hM1, Multiset.mem_map] at h0'
    obtain ⟨x, hx, hx0⟩ := h0'
    have : x = 0 := (map_eq_zero_iff φ φ.toRingHom.injective).1 hx0
    exact (Multiset.mem_filter.1 hx).2 this
  have hprod : ((q.aroots ℂ).map (fun a => 1 + Complex.exp a)).prod = 0 := by
    apply Multiset.prod_eq_zero
    refine Multiset.mem_map.2 ⟨_, hmem, ?_⟩
    rw [mul_comm, Complex.exp_pi_mul_I]
    ring
  have hsumS : ((SK.map φ).map Complex.exp).sum = 0 := by
    rw [hSK, ← subSums_map, ← hA, sum_exp_subSums, hprod]
  set m := Multiset.card (SK.filter (fun x => x = 0)) with hm
  have hm1 : 0 < m := Multiset.card_pos_iff_exists_mem.2
    ⟨0, Multiset.mem_filter.2 ⟨zero_mem_subSums AK, rfl⟩⟩
  have hsumM1 : (M1.map Complex.exp).sum = -(m : ℂ) := by
    have h := hsumS
    rw [← Multiset.filter_add_not (fun x => x = 0) SK, Multiset.map_add, Multiset.map_add,
      Multiset.sum_add] at h
    have h0 : (((SK.filter (fun x => x = 0)).map φ).map Complex.exp).sum = m := by
      rw [Multiset.map_map, Multiset.map_congr rfl (fun x hx => show (Complex.exp ∘ φ) x = 1 by
        rw [(Multiset.mem_filter.1 hx).2]; simp)]
      simp [hm]
    rw [h0] at h
    have e : SK.filter (fun a => ¬ (fun x => x = 0) a) = M1K := by
      rw [hM1K]
    rw [e] at h
    rw [hM1]
    linear_combination h
  set ℓ := f.leadingCoeff with hℓ
  have hf00 : f ≠ 0 := fun h => hfmap0 (by rw [h, Polynomial.map_zero])
  have hℓ0 : ℓ ≠ 0 := Polynomial.leadingCoeff_ne_zero.2 hf00
  have hintM1 : ∀ r ∈ M1, IsIntegral ℤ ((ℓ : ℂ) * r) := by
    intro r hr
    rw [← hroots] at hr
    have h1 := isIntegral_leadingCoeff_smul f r (Polynomial.mem_aroots.1 hr).2
    rwa [zsmul_eq_mul] at h1
  have hT : ∀ j : ℕ, ∃ z : ℤ, (M1.map (fun r => ((ℓ : ℂ) * r) ^ j)).sum = z := by
    intro j
    obtain ⟨r0, hr0⟩ := galois_sum_rat M1K hM1inv ((C (ℓ : ℚ) * X) ^ j)
    have e1 : (M1.map (fun r => ((ℓ : ℂ) * r) ^ j)).sum = algebraMap ℚ ℂ r0 := by
      rw [← φ.commutes r0, ← hr0, map_multiset_sum]
      simp only [hM1, Multiset.map_map]
      congr 1
      apply Multiset.map_congr rfl
      intro x _
      simp
    have hI : (M1.map (fun r => ((ℓ : ℂ) * r) ^ j)).sum ∈ integralClosure ℤ ℂ :=
      multiset_sum_mem _ (fun y hy => by
        obtain ⟨r, hr, rfl⟩ := Multiset.mem_map.1 hy
        exact pow_mem (show ((ℓ : ℂ) * r) ∈ integralClosure ℤ ℂ from hintM1 r hr) j)
    rw [e1] at hI
    have hI' : IsIntegral ℤ r0 :=
      (isIntegral_algHom_iff (IsScalarTower.toAlgHom ℤ ℚ ℂ)
        (IsScalarTower.toAlgHom ℤ ℚ ℂ).toRingHom.injective).1 hI
    obtain ⟨y, hy⟩ := IsIntegrallyClosed.isIntegral_iff.1 hI'
    exact ⟨y, by rw [e1, ← hy]; simp⟩
  obtain ⟨c, hc⟩ := LindemannWeierstrass.exp_polynomial_approx f hf0
  set D := f.natDegree with hD
  set N : ℝ := (Multiset.card M1 : ℝ) with hN
  set a : ℝ := |(ℓ : ℝ)| ^ D * |c| with ha
  have ha0 : 0 ≤ a := by positivity
  have hN0' : 0 ≤ N := by positivity
  have hε : (0 : ℝ) < 1 / (N * a + 1) := by positivity
  obtain ⟨N0, hN0⟩ := Filter.eventually_atTop.1
    ((FloorSemiring.tendsto_pow_div_factorial_atTop a).eventually (gt_mem_nhds hε))
  obtain ⟨p, hpge, hp⟩ :=
    Nat.exists_infinite_primes (N0 + (f.eval 0).natAbs + ℓ.natAbs + m + 2)
  obtain ⟨n, hn, g, hgdeg, hbound⟩ := hc p (by omega) hp
  obtain ⟨z, hz⟩ := int_sum_aeval M1 ℓ hT g (p * D - 1) hgdeg
  have hWC : ((-(ℓ ^ (p * D - 1) * n * m) - p * z : ℤ) : ℂ) = (ℓ : ℂ) ^ (p * D - 1) *
      (M1.map (fun r => n • Complex.exp r - p • aeval r g)).sum := by
    simp_rw [zsmul_eq_mul, nsmul_eq_mul]
    rw [Multiset.sum_map_sub, Multiset.sum_map_mul_left, Multiset.sum_map_mul_left, hsumM1]
    push_cast
    rw [← hz]
    ring
  have hpZ : Prime (p : ℤ) := Nat.prime_iff_prime_int.1 hp
  have hW0 : (-(ℓ ^ (p * D - 1) * n * m) - p * z : ℤ) ≠ 0 := by
    intro h0
    have hdvd : (p : ℤ) ∣ ℓ ^ (p * D - 1) * n * m := ⟨-z, by linear_combination -h0⟩
    rcases hpZ.dvd_or_dvd hdvd with h1 | h1
    · rcases hpZ.dvd_or_dvd h1 with h2 | h2
      · have h3 := Int.natCast_dvd.1 (hpZ.dvd_of_dvd_pow h2)
        have h4 := Nat.le_of_dvd (Int.natAbs_pos.2 hℓ0) h3
        omega
      · exact hn h2
    · have h3 := Nat.le_of_dvd hm1 (Int.natCast_dvd_natCast.1 h1)
      omega
  have hnorm1 : (1 : ℝ) ≤ ‖(((-(ℓ ^ (p * D - 1) * n * m) - p * z : ℤ)) : ℂ)‖ := by
    rw [Complex.norm_intCast]
    exact_mod_cast Int.one_le_abs hW0
  have hsum_le : ‖(M1.map (fun r => n • Complex.exp r - p • aeval r g)).sum‖ ≤
      N * (c ^ p / (Nat.factorial (p - 1))) := by
    refine (norm_multiset_sum_le _).trans ?_
    have := Multiset.sum_le_card_nsmul
      ((M1.map (fun r => n • Complex.exp r - p • aeval r g)).map norm) (c ^ p / (Nat.factorial (p - 1)))
      (fun y hy => by
        obtain ⟨y', hy', rfl⟩ := Multiset.mem_map.1 hy
        obtain ⟨r, hr, rfl⟩ := Multiset.mem_map.1 hy'
        exact hbound (by rw [hroots]; exact hr))
    simpa [hN, nsmul_eq_mul] using this
  have hℓ1 : (1 : ℝ) ≤ |(ℓ : ℝ)| := by exact_mod_cast Int.one_le_abs hℓ0
  have hcp : c ^ p ≤ |c| ^ p := (le_abs_self _).trans (abs_pow c p).le
  have hsmall := hN0 (p - 1) (by omega)
  have hX0 : (0 : ℝ) ≤ a ^ (p - 1) / ((Nat.factorial (p - 1)) : ℝ) := by positivity
  have hX : a ^ (p - 1) / ((Nat.factorial (p - 1)) : ℝ) * (N * a + 1) < 1 := by
    rwa [lt_div_iff₀ (by positivity)] at hsmall
  have hap : (|(ℓ : ℝ)| ^ D) ^ p * |c| ^ p = a * a ^ (p - 1) := by
    rw [← mul_pow, ← pow_succ', Nat.sub_add_cancel hp.one_le]
  have key : ‖(((-(ℓ ^ (p * D - 1) * n * m) - p * z : ℤ)) : ℂ)‖ < 1 := by
    rw [hWC, norm_mul, norm_pow, Complex.norm_intCast]
    calc |(ℓ : ℝ)| ^ (p * D - 1) * ‖(M1.map (fun r => n • Complex.exp r - p • aeval r g)).sum‖
        ≤ |(ℓ : ℝ)| ^ (p * D) * (N * (|c| ^ p / (Nat.factorial (p - 1)))) := by
          apply mul_le_mul (pow_le_pow_right₀ hℓ1 (Nat.sub_le _ _)) _ (norm_nonneg _)
            (by positivity)
          refine hsum_le.trans ?_
          gcongr
      _ = N * a * (a ^ (p - 1) / ((Nat.factorial (p - 1)) : ℝ)) := by
          rw [pow_mul', mul_div_assoc', mul_div_assoc', ← mul_assoc, mul_comm _ N, mul_assoc N,
            hap]
          ring
      _ < 1 := by nlinarith
  linarith

theorem sqrt_pi_not_constructible (x : ℝ) (hx : x ^ 2 = π) : ¬ Constructible x := by
  intro hc
  have hπ : Constructible π := by rw [← hx, pow_two]; exact Constructible.mul hc hc
  obtain ⟨K, hK, hπK⟩ := constructible_tower Complex.ofRealHom hπ
  have hI : Complex.I ^ 2 ∈ K := by rw [Complex.I_sq]; exact neg_mem (one_mem K)
  have hK' := QTower.step hK hI
  have hmem : Complex.I * (π : ℂ) ∈ IntermediateField.adjoin ℚ (insert Complex.I (K : Set ℂ)) :=
    mul_mem (IntermediateField.subset_adjoin ℚ _ (Set.mem_insert _ _))
      (IntermediateField.subset_adjoin ℚ _ (Set.mem_insert_of_mem _ hπK))
  obtain ⟨k, hk⟩ := qtower_finrank hK'
  have : FiniteDimensional ℚ (IntermediateField.adjoin ℚ (insert Complex.I (K : Set ℂ))) :=
    Module.finite_of_finrank_pos (by rw [hk]; positivity)
  have hint : IsIntegral ℚ
      (⟨_, hmem⟩ : IntermediateField.adjoin ℚ (insert Complex.I (K : Set ℂ))) :=
    Algebra.IsIntegral.isIntegral _
  exact I_pi_not_integral (IntermediateField.isIntegral_iff.1 hint)

end Helpers

#print axioms qtower_merge
#print axioms qtower_step_finrank
#print axioms qtower_rel_finrank
#print axioms qtower_finrank
#print axioms constructible_tower
#print axioms qtower_mem_finrank
#print axioms constructible_degree_pow_two
#print axioms cons_zero
#print axioms cons_sub
#print axioms cons_div
#print axioms cons_nat
#print axioms cons_int
#print axioms cons_rat
#print axioms cons_of_sq
#print axioms ccons_add
#print axioms ccons_neg
#print axioms ccons_sub
#print axioms ccons_mul
#print axioms ccons_inv
#print axioms ccons_rat
#print axioms ccons_of_sq
#print axioms cos_two_pi_div_eq
#print axioms cyclo_finrank
#print axioms totient_of_constructible_cos
#print axioms cyclo_isCyclotomic
#print axioms ccons_of_fixed
#print axioms constructible_cos_of_totient
#print axioms not_constructible_of_cubic
#print axioms rat_cube_ne_two
#print axioms rat_trisect_ne
#print axioms cube_root_two_not_constructible
#print axioms cos_twenty_not_constructible
#print axioms totient_fermat_prod
#print axioms fermat_of_totient
#print axioms subSums_cons
#print axioms subSums_map
#print axioms zero_mem_subSums
#print axioms sum_exp_subSums
#print axioms galois_fixed_rat
#print axioms galois_prod_rat
#print axioms galois_sum_rat
#print axioms int_sum_aeval
#print axioms I_pi_not_integral
#print axioms sqrt_pi_not_constructible

/-- A constructible length always has a degree that is a power of 2: the smallest field
holding it, `ℚ(α)`, has dimension `2 ^ k` over the fractions for some whole number `k`.
(In particular a constructible length is algebraic, since `2 ^ k ≥ 1`.) -/
theorem degree_of_constructible_is_pow_two (α : ℝ) (h : Constructible α) :
    ∃ k : ℕ, Module.finrank ℚ ℚ⟮α⟯ = 2 ^ k := by
  exact constructible_degree_pow_two h

/-- Gauss-Wantzel: for `n ≥ 3`, a regular n-gon is constructible (its first corner's cosine
`cos (360° / n)` can be built) exactly when `φ(n)` is a power of 2, and `φ(n)` is a power of 2
exactly when `n` is a power of 2 times distinct Fermat primes `2 ^ (2 ^ j) + 1`. -/
theorem regular_polygon_constructible_iff (n : ℕ) (hn : 3 ≤ n) :
    (Constructible (Real.cos (2 * π / n)) ↔ ∃ k : ℕ, Nat.totient n = 2 ^ k) ∧
    ((∃ k : ℕ, Nat.totient n = 2 ^ k) ↔
      ∃ (a : ℕ) (S : Finset ℕ),
        (∀ p ∈ S, p.Prime ∧ ∃ j : ℕ, p = Nat.fermatNumber j) ∧ n = 2 ^ a * ∏ p ∈ S, p) := by
  have hn0 : 0 < n := by omega
  refine ⟨⟨totient_of_constructible_cos hn0, fun ⟨k, hk⟩ => constructible_cos_of_totient hn0 hk⟩,
    ⟨fun ⟨k, hk⟩ => fermat_of_totient hk, fun ⟨a, S, hS, hnS⟩ => ?_⟩⟩
  subst hnS
  exact totient_fermat_prod a S hS

/-- The three classical problems fail. Doubling the cube: no side `x` with `x ^ 3 = 2` can be
built. Trisection: the angle 60° can be built (`cos 60° = 1/2`) but cutting it in three cannot,
since `cos 20°` cannot be built. Squaring the circle: no side `x` with `x ^ 2 = π` can be built
(this rests on Lindemann's 1882 theorem that π is transcendental). -/
theorem classical_problems_impossible :
    (∀ x : ℝ, x ^ 3 = 2 → ¬ Constructible x) ∧
    (Constructible (Real.cos (π / 3)) ∧ ¬ Constructible (Real.cos (π / 9))) ∧
    (∀ x : ℝ, x ^ 2 = π → ¬ Constructible x) := by
  refine ⟨cube_root_two_not_constructible, ⟨?_, cos_twenty_not_constructible⟩,
    sqrt_pi_not_constructible⟩
  rw [Real.cos_pi_div_three]
  have h := cons_rat (1 / 2)
  push_cast at h
  exact h

-- The card's whole-number worked examples.
-- φ(17) = 16, φ(7) = 6, φ(11) = 10, φ(9) = 6; the cosine degrees φ(n)/2 are 8, 3, 5, 3.
example : Nat.totient 17 = 16 ∧ Nat.totient 7 = 6 ∧ Nat.totient 11 = 10 ∧ Nat.totient 9 = 6 := by
  decide
example : Nat.totient 17 / 2 = 2 ^ 3 ∧ Nat.totient 7 / 2 = 3 ∧ Nat.totient 11 / 2 = 5 := by decide
-- The five known Fermat primes 3, 5, 17, 257, 65,537; 17 = F_2.
example : Nat.fermatNumber 0 = 3 ∧ Nat.fermatNumber 1 = 5 ∧ Nat.fermatNumber 2 = 17 ∧
    Nat.fermatNumber 3 = 257 ∧ Nat.fermatNumber 4 = 65537 := by norm_num [Nat.fermatNumber]
example : Nat.Prime 3 ∧ Nat.Prime 5 ∧ Nat.Prime 17 ∧ Nat.Prime 257 ∧ Nat.Prime 65537 := by
  norm_num
-- F_5 = 4,294,967,297 = 641 × 6,700,417 (Euler, 1732), and the five Fermat primes multiply to 2^32 - 1.
example : Nat.fermatNumber 5 = 4294967297 ∧ 4294967297 = 641 * 6700417 := by
  norm_num [Nat.fermatNumber]
example : 3 * 5 * 17 * 257 * 65537 = 4294967295 ∧ 4294967295 = 2 ^ 32 - 1 := by norm_num
-- From 3 to 20 the buildable polygons are 3, 4, 5, 6, 8, 10, 12, 15, 16, 17, 20.
example : (Finset.Icc 3 20).filter (fun n => ∃ k ∈ Finset.range 5, Nat.totient n = 2 ^ k) =
    {3, 4, 5, 6, 8, 10, 12, 15, 16, 17, 20} := by decide
-- The others carry cosine degrees 7 (3), 9 (3), 11 (5), 13 (6), 14 (3), 18 (3), 19 (9).
example : Nat.totient 13 / 2 = 6 ∧ Nat.totient 14 / 2 = 3 ∧ Nat.totient 18 / 2 = 3 ∧
    Nat.totient 19 / 2 = 9 := by decide
-- Up to 100 there are 24 buildable n-gons; up to 1,000 there are 52.
example : ((Finset.Icc 3 100).filter
    (fun n => ∃ k ∈ Finset.range 7, Nat.totient n = 2 ^ k)).card = 24 := by decide +kernel
example : ((Finset.Icc 3 1000).filter
    (fun n => ∃ k ∈ Finset.range 10, Nat.totient n = 2 ^ k)).card = 52 := by decide +kernel
-- Doubling the cube: 2 is no cube mod 7, so x^3 - 2 has no factor mod 7.
example : ∀ x : ZMod 7, x ^ 3 ≠ 2 := by decide
-- Trisecting 60°: x^3 - 3x - 1 has no root mod 2.
example : ∀ x : ZMod 2, x ^ 3 - 3 * x - 1 ≠ 0 := by decide
-- The 17-gon: powers of 3 mod 17 reach all 16 nonzero remainders, and the halving chain.
example : (Finset.range 16).image (fun k => 3 ^ k % 17) = (Finset.range 17).erase 0 := by decide
example : (Finset.range 8).image (fun k => 3 ^ (2 * k) % 17) = {1, 2, 4, 8, 9, 13, 15, 16} := by
  decide
example : (Finset.range 4).image (fun k => 3 ^ (4 * k) % 17) = {1, 4, 13, 16} := by decide
example : (Finset.range 2).image (fun k => 3 ^ (8 * k) % 17) = {1, 16} := by decide
-- The resolvent cubic u^3 - 8u - 16 of x^4 - 4x + 2 has no whole-number root.
example : ∀ u ∈ ({1, -1, 2, -2, 4, -4, 8, -8, 16, -16} : Finset ℤ), u ^ 3 - 8 * u - 16 ≠ 0 := by
  decide

#print axioms degree_of_constructible_is_pow_two
#print axioms regular_polygon_constructible_iff
#print axioms classical_problems_impossible
