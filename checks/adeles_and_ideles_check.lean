-- Adeles and ideles: the sizes of a nonzero fraction at all places multiply to 1, every adele of Q is exactly one fraction plus a remainder in [0, 1) times Z-hat, and Q is discrete in the adeles with compact quotient.
import Mathlib.NumberTheory.NumberField.AdeleRing
import Mathlib.NumberTheory.NumberField.Completion.InfinitePlace
import Mathlib.NumberTheory.Padics.PadicNorm
import Mathlib.Algebra.BigOperators.Finprod
import Mathlib.Topology.Algebra.Group.Quotient
import Mathlib.NumberTheory.Padics.HeightOneSpectrum
import Mathlib.NumberTheory.Padics.ProperSpace
import Mathlib.Tactic.NormNum.Prime

open NumberField IsDedekindDomain
open scoped AdeleRing

/-- The real entry of an adele of Q, read as a real number through the real place. -/
noncomputable def realEntry (a : 𝔸[ℤ, ℚ]) : ℝ :=
  InfinitePlace.Completion.extensionEmbeddingOfIsReal Rat.isReal_infinitePlace
    (a.1 Rat.infinitePlace)

theorem finite_mulSupport_padicNorm_nat {n : ℕ} (hn : n ≠ 0) :
    (Function.mulSupport fun p : Nat.Primes => padicNorm (p : ℕ) (n : ℚ)).Finite := by
  refine ((Set.finite_Iic n).preimage Subtype.val_injective.injOn).subset ?_
  intro p hp
  have : (p : ℕ) ∣ n := by
    by_contra h
    have : Fact (p : ℕ).Prime := ⟨p.2⟩
    exact hp ((padicNorm.nat_eq_one_iff n).2 h)
  exact Nat.le_of_dvd (Nat.pos_of_ne_zero hn) this
#print axioms finite_mulSupport_padicNorm_nat

theorem finprod_padicNorm_nat {n : ℕ} (hn : n ≠ 0) :
    ∏ᶠ p : Nat.Primes, padicNorm (p : ℕ) (n : ℚ) = (n : ℚ)⁻¹ := by
  induction n using Nat.recOnMul with
  | zero => exact absurd rfl hn
  | one => simp
  | prime q hq =>
    have : Fact q.Prime := ⟨hq⟩
    rw [finprod_eq_single (fun p : Nat.Primes => padicNorm (p : ℕ) (q : ℚ)) (⟨q, hq⟩ : Nat.Primes)]
    · exact padicNorm.padicNorm_p_of_prime
    · intro p hp
      have : Fact (p : ℕ).Prime := ⟨p.2⟩
      exact padicNorm.padicNorm_of_prime_of_ne (fun h => hp (Subtype.ext h))
  | mul a b ha hb =>
    have ha0 : a ≠ 0 := by rintro rfl; simp at hn
    have hb0 : b ≠ 0 := by rintro rfl; simp at hn
    have key : (fun p : Nat.Primes => padicNorm (p : ℕ) ((a * b : ℕ) : ℚ)) =
        fun p : Nat.Primes => padicNorm (p : ℕ) (a : ℚ) * padicNorm (p : ℕ) (b : ℚ) := by
      funext p; have : Fact (p : ℕ).Prime := ⟨p.2⟩; push_cast; exact padicNorm.mul _ _
    rw [key, finprod_mul_distrib (finite_mulSupport_padicNorm_nat ha0)
      (finite_mulSupport_padicNorm_nat hb0), ha ha0, hb hb0]
    push_cast; rw [mul_inv]
#print axioms finprod_padicNorm_nat

theorem padicNorm_prime_of_ne {p q : ℕ} (hp : p.Prime) (hq : q.Prime) (h : p ≠ q) :
    padicNorm p (q : ℚ) = 1 := by
  have : Fact p.Prime := ⟨hp⟩
  have : Fact q.Prime := ⟨hq⟩
  exact padicNorm.padicNorm_of_prime_of_ne h
#print axioms padicNorm_prime_of_ne

theorem padicNorm_prime_self {p : ℕ} (hp : p.Prime) : padicNorm p (p : ℚ) = (p : ℚ)⁻¹ := by
  have : Fact p.Prime := ⟨hp⟩
  exact padicNorm.padicNorm_p_of_prime
#print axioms padicNorm_prime_self

theorem snd_algebraMap (q : ℚ) (v : HeightOneSpectrum ℤ) :
    (algebraMap ℚ 𝔸[ℤ, ℚ] q).2 v = (q : v.adicCompletion ℚ) := by
  rw [AdeleRing.algebraMap_snd_apply, ← eq_ratCast (algebraMap ℚ (v.adicCompletion ℚ)) q,
    HeightOneSpectrum.algebraMap_adicCompletion, Function.comp_apply, Algebra.algebraMap_self_apply]
#print axioms snd_algebraMap

theorem valued_ratCast (v : HeightOneSpectrum ℤ) (q : ℚ) :
    Valued.v (q : v.adicCompletion ℚ) = v.valuation ℚ q := by
  rw [← snd_algebraMap q v, AdeleRing.algebraMap_snd_apply, HeightOneSpectrum.adicCompletion.valued_coe]
#print axioms valued_ratCast

theorem ratCast_mem_iff (v : HeightOneSpectrum ℤ) (r : ℚ) :
    (r : v.adicCompletion ℚ) ∈ v.adicCompletionIntegers ℚ ↔ ((r.den : ℤ)) ∉ v.asIdeal := by
  rw [HeightOneSpectrum.mem_adicCompletionIntegers, valued_ratCast, Rat.valuation_le_one_iff_den]
#print axioms ratCast_mem_iff

theorem intCast_mem_integers (v : HeightOneSpectrum ℤ) (n : ℤ) :
    (n : v.adicCompletion ℚ) ∈ v.adicCompletionIntegers ℚ := by
  have := (ratCast_mem_iff v (n : ℚ)).2
    (by simpa using fun h => v.isPrime.ne_top ((Ideal.eq_top_iff_one _).2 h))
  simp
#print axioms intCast_mem_integers

theorem compactSpace_integers (v : HeightOneSpectrum ℤ) : CompactSpace (v.adicCompletionIntegers ℚ) := by
  have : Fact (Rat.HeightOneSpectrum.primesEquiv v).1.Prime := ⟨(Rat.HeightOneSpectrum.primesEquiv v).2⟩
  let _ : Algebra ℤ (v.adicCompletionIntegers ℚ) := Ring.toIntAlgebra _
  exact (Rat.HeightOneSpectrum.adicCompletionIntegers.padicIntEquiv v).toHomeomorph.symm.compactSpace
#print axioms compactSpace_integers

instance charZero_adicCompletion (v : HeightOneSpectrum ℤ) : CharZero (v.adicCompletion ℚ) :=
  charZero_of_injective_algebraMap (algebraMap ℚ (v.adicCompletion ℚ)).injective

theorem realEntry_algebraMap (q : ℚ) : realEntry (algebraMap ℚ 𝔸[ℤ, ℚ] q) = q := by
  simp [realEntry]
#print axioms realEntry_algebraMap

theorem realEntry_sub (a b : 𝔸[ℤ, ℚ]) : realEntry (a - b) = realEntry a - realEntry b := by
  rw [realEntry, realEntry, realEntry, ← map_sub]; rfl
#print axioms realEntry_sub

/-- A height-one prime of `ℤ` is generated by a prime number. -/

theorem exists_prime_asIdeal (v : HeightOneSpectrum ℤ) :
    ∃ p : ℕ, p.Prime ∧ v.asIdeal = Ideal.span {(p : ℤ)} := by
  set g := Submodule.IsPrincipal.generator v.asIdeal
  have hg : v.asIdeal = Ideal.span {g} :=
    (Submodule.IsPrincipal.span_singleton_generator v.asIdeal).symm
  have hg0 : g ≠ 0 := by
    intro h; apply v.ne_bot; rw [hg, h, Ideal.span_singleton_eq_bot]
  have hprime : Prime g := by
    have := v.isPrime; rw [hg] at this
    exact (Ideal.span_singleton_prime hg0).1 this
  refine ⟨g.natAbs, Int.prime_iff_natAbs_prime.1 hprime, ?_⟩
  rw [Int.span_natAbs, hg]
#print axioms exists_prime_asIdeal

theorem alg_aux (s N A B P E : ℚ) (hP : P ≠ 0) (hE : E ≠ 0) (hs : N = s * (P * E))
    (h : A * E + B * P = 1) : s - N * A / P = N * B / E := by
  field_simp
  linear_combination -hs - N * h
#print axioms alg_aux

/-- Approximation at one prime: every local number is a fraction plus a local integer, where the
fraction is integral at every other prime. -/

theorem exists_rat_local (v : HeightOneSpectrum ℤ) (x : v.adicCompletion ℚ) :
    ∃ r : ℚ, x - (r : v.adicCompletion ℚ) ∈ v.adicCompletionIntegers ℚ ∧
      ∀ w : HeightOneSpectrum ℤ, w ≠ v → (r : w.adicCompletion ℚ) ∈ w.adicCompletionIntegers ℚ := by
  -- a nearby fraction `s`
  have hopen : IsOpen {y : v.adicCompletion ℚ | x - y ∈ v.adicCompletionIntegers ℚ} :=
    (Valued.isOpen_valuationSubring _).preimage (continuous_const.sub continuous_id)
  obtain ⟨s, hs⟩ := (HeightOneSpectrum.denseRange_algebraMap (R := ℤ) ℚ v).exists_mem_open hopen
    ⟨x, by simp⟩
  simp only [Set.mem_ofPred_eq, eq_ratCast] at hs
  obtain ⟨p, hp, hv⟩ := exists_prime_asIdeal v
  obtain ⟨k, e, hpe, hden⟩ := Nat.exists_eq_pow_mul_and_not_dvd s.den_nz p hp.one_lt.ne'
  have hcop : IsCoprime (e : ℤ) ((p ^ k : ℕ) : ℤ) :=
    Nat.isCoprime_iff_coprime.2
      (Nat.Coprime.pow_right k ((Nat.Prime.coprime_iff_not_dvd hp).2 hpe).symm)
  obtain ⟨α, β, hαβ⟩ := hcop
  have he0 : (e : ℚ) ≠ 0 := by
    have : e ≠ 0 := by rintro rfl; simp at hden
    exact_mod_cast this
  have hpk0 : ((p ^ k : ℕ) : ℚ) ≠ 0 := by
    have := hp.pos
    positivity
  set r : ℚ := ((s.num * α : ℤ) : ℚ) / ((p ^ k : ℕ) : ℚ) with hr
  have hsr : s - r = ((s.num * β : ℤ) : ℚ) / ((e : ℤ) : ℚ) := by
    have hs' : (s.num : ℚ) = s * (((p ^ k : ℕ) : ℚ) * (e : ℚ)) := by
      rw [← Nat.cast_mul, ← hden]; exact (Rat.mul_den_eq_num s).symm
    have hαβ' : (α : ℚ) * e + β * ((p ^ k : ℕ) : ℚ) = 1 := by exact_mod_cast hαβ
    rw [hr, Int.cast_mul, Int.cast_mul, Int.cast_natCast]
    exact alg_aux _ _ _ _ _ _ hpk0 he0 hs' hαβ'
  refine ⟨r, ?_, ?_⟩
  · have hmem : ((s - r : ℚ) : v.adicCompletion ℚ) ∈ v.adicCompletionIntegers ℚ := by
      rw [ratCast_mem_iff, hv, Ideal.mem_span_singleton]
      intro hdvd
      have h1 : ((s - r).den : ℤ) ∣ (e : ℤ) := by
        rw [hsr, ← Rat.divInt_eq_div]; exact Rat.den_dvd _ _
      exact hpe (Int.natCast_dvd_natCast.1 (hdvd.trans h1))
    have : x - (r : v.adicCompletion ℚ) = (x - s) + ((s - r : ℚ) : v.adicCompletion ℚ) := by
      push_cast; ring
    rw [this]
    exact add_mem hs hmem
  · intro w hw
    rw [ratCast_mem_iff]
    intro hmem
    have h1 : (r.den : ℤ) ∣ ((p ^ k : ℕ) : ℤ) := by
      have : r = ((s.num * α : ℤ) : ℚ) / (((p ^ k : ℕ) : ℤ) : ℚ) := by rw [hr]; push_cast; rfl
      rw [this, ← Rat.divInt_eq_div]; exact Rat.den_dvd _ _
    have h2 : ((p : ℤ)) ^ k ∈ w.asIdeal := by
      have := w.asIdeal.mem_of_dvd h1 hmem
      simpa using this
    have h3 : (p : ℤ) ∈ w.asIdeal := w.isPrime.mem_of_pow_mem k h2
    have h4 : v.asIdeal ≤ w.asIdeal := by
      rw [hv, Ideal.span_le, Set.singleton_subset_iff]; exact h3
    have h5 : v.asIdeal = w.asIdeal := v.isMaximal.eq_of_le w.isPrime.ne_top h4
    exact hw (HeightOneSpectrum.ext h5).symm
#print axioms exists_rat_local

/-- A family of local numbers, integral at all primes outside a finite set, is a single fraction
plus a family of local integers. -/

theorem exists_rat_sub_mem_of_finset (S : Finset (HeightOneSpectrum ℤ)) :
    ∀ f : (v : HeightOneSpectrum ℤ) → v.adicCompletion ℚ,
      (∀ v, v ∉ S → f v ∈ v.adicCompletionIntegers ℚ) →
      ∃ q : ℚ, ∀ v, f v - (q : v.adicCompletion ℚ) ∈ v.adicCompletionIntegers ℚ := by
  classical
  induction S using Finset.induction_on with
  | empty =>
    intro f hf
    exact ⟨0, fun v => by simpa using hf v (Finset.notMem_empty v)⟩
  | insert v S hvS ih =>
    intro f hf
    obtain ⟨r, hrv, hrw⟩ := exists_rat_local v (f v)
    obtain ⟨q, hq⟩ := ih (fun w => f w - (r : w.adicCompletion ℚ)) (by
      intro w hw
      by_cases hwv : w = v
      · subst hwv; exact hrv
      · exact sub_mem (hf w (by simp [hwv, hw])) (hrw w hwv))
    refine ⟨r + q, fun w => ?_⟩
    have := hq w
    push_cast
    rwa [← sub_sub]
#print axioms exists_rat_sub_mem_of_finset

theorem exists_rat_sub_mem_finite (b : FiniteAdeleRing ℤ ℚ) :
    ∃ q : ℚ, ∀ v, b v - (q : v.adicCompletion ℚ) ∈ v.adicCompletionIntegers ℚ := by
  have hfin := Filter.eventually_cofinite.1 (FiniteAdeleRing.cofinite_mem_adicCompletionIntegers b)
  exact exists_rat_sub_mem_of_finset hfin.toFinset (fun v => b v) (fun v hv => by
    by_contra h; exact hv (hfin.mem_toFinset.2 h))
#print axioms exists_rat_sub_mem_finite

/-- A fraction that is a local integer at every prime and has size below 1 is zero. -/

theorem rat_eq_zero_of_integral (d : ℚ)
    (hint : ∀ v : HeightOneSpectrum ℤ, (d : v.adicCompletion ℚ) ∈ v.adicCompletionIntegers ℚ)
    (hreal : |(d : ℝ)| < 1) : d = 0 := by
  have hden : d.den = 1 := by
    by_contra h
    obtain ⟨p, hp, hpd⟩ := Nat.exists_prime_and_dvd h
    let w : HeightOneSpectrum ℤ :=
      ⟨Ideal.span {(p : ℤ)}, (Ideal.span_singleton_prime (by exact_mod_cast hp.ne_zero)).2
        (Nat.prime_iff_prime_int.1 hp), by simp [hp.ne_zero]⟩
    have := (ratCast_mem_iff w d).1 (hint w)
    exact this (Ideal.mem_span_singleton.2 (Int.natCast_dvd_natCast.2 hpd))
  have hd : d = (d.num : ℚ) := (Rat.den_eq_one_iff d).1 hden |>.symm
  rw [hd] at hreal ⊢
  have : |d.num| < 1 := by
    have : ((|d.num| : ℤ) : ℝ) < 1 := by push_cast; exact_mod_cast hreal
    exact_mod_cast this
  have : d.num = 0 := Int.abs_lt_one_iff.1 this
  simp [this]
#print axioms rat_eq_zero_of_integral

theorem snd_sub_algebraMap (a : 𝔸[ℤ, ℚ]) (q : ℚ) (v : HeightOneSpectrum ℤ) :
    (a - algebraMap ℚ 𝔸[ℤ, ℚ] q).2 v = a.2 v - (q : v.adicCompletion ℚ) := by
  rw [← snd_algebraMap]; rfl
#print axioms snd_sub_algebraMap

/-- The box condition: real entry in [0, 1) and every p-adic entry a p-adic integer. -/

def InBox (b : 𝔸[ℤ, ℚ]) : Prop :=
  0 ≤ realEntry b ∧ realEntry b < 1 ∧ ∀ v : HeightOneSpectrum ℤ, b.2 v ∈ v.adicCompletionIntegers ℚ

theorem exists_inBox (a : 𝔸[ℤ, ℚ]) : ∃ q : ℚ, InBox (a - algebraMap ℚ 𝔸[ℤ, ℚ] q) := by
  obtain ⟨q0, hq0⟩ := exists_rat_sub_mem_finite a.2
  set n : ℤ := ⌊realEntry a - q0⌋
  refine ⟨q0 + n, ?_, ?_, ?_⟩
  · rw [realEntry_sub, realEntry_algebraMap]; push_cast
    have := Int.fract_nonneg (realEntry a - q0)
    rw [Int.fract] at this; linarith
  · rw [realEntry_sub, realEntry_algebraMap]; push_cast
    have := Int.fract_lt_one (realEntry a - q0)
    rw [Int.fract] at this; linarith
  · intro v
    rw [snd_sub_algebraMap]
    have : a.2 v - ((q0 + n : ℚ) : v.adicCompletion ℚ) =
        (a.2 v - (q0 : v.adicCompletion ℚ)) - (n : v.adicCompletion ℚ) := by
      push_cast; ring
    rw [this]
    exact sub_mem (hq0 v) (intCast_mem_integers v n)
#print axioms exists_inBox

theorem inBox_unique (a : 𝔸[ℤ, ℚ]) (q1 q2 : ℚ) (h1 : InBox (a - algebraMap ℚ 𝔸[ℤ, ℚ] q1))
    (h2 : InBox (a - algebraMap ℚ 𝔸[ℤ, ℚ] q2)) : q1 = q2 := by
  obtain ⟨a0, a1, af⟩ := h1
  obtain ⟨b0, b1, bf⟩ := h2
  have h := rat_eq_zero_of_integral (q1 - q2) ?_ ?_
  · exact sub_eq_zero.1 h
  · intro v
    have e1 := af v
    have e2 := bf v
    rw [snd_sub_algebraMap] at e1 e2
    have : ((q1 - q2 : ℚ) : v.adicCompletion ℚ) =
        (a.2 v - (q2 : v.adicCompletion ℚ)) - (a.2 v - (q1 : v.adicCompletion ℚ)) := by
      push_cast; ring
    rw [this]
    exact sub_mem e2 e1
  · rw [realEntry_sub, realEntry_algebraMap] at a0 a1 b0 b1
    push_cast
    rw [abs_lt]
    constructor <;> linarith
#print axioms inBox_unique

theorem isReal_rat (w : InfinitePlace ℚ) : w.IsReal := by
  rw [Subsingleton.elim w Rat.infinitePlace]; exact Rat.isReal_infinitePlace
#print axioms isReal_rat

/-- From a real number back to the infinite part of an adele of Q. -/

noncomputable def realToInf (t : ℝ) : InfiniteAdeleRing ℚ :=
  fun v => (InfinitePlace.Completion.isometryEquivRealOfIsReal (isReal_rat v)).symm t

theorem continuous_realToInf : Continuous realToInf :=
  continuous_pi fun v => (InfinitePlace.Completion.isometryEquivRealOfIsReal (isReal_rat v)).symm.continuous
#print axioms continuous_realToInf

theorem realToInf_realEntry (a : 𝔸[ℤ, ℚ]) : realToInf (realEntry a) = a.1 := by
  funext v
  obtain rfl : v = Rat.infinitePlace := Subsingleton.elim _ _
  exact (InfinitePlace.Completion.isometryEquivRealOfIsReal (isReal_rat _)).symm_apply_apply _
#print axioms realToInf_realEntry

theorem continuous_realEntry : Continuous realEntry :=
  (InfinitePlace.Completion.isometry_extensionEmbeddingOfIsReal _).continuous.comp
    ((continuous_apply _).comp continuous_fst)
#print axioms continuous_realEntry

theorem isOpen_integral_finite :
    IsOpen {b : FiniteAdeleRing ℤ ℚ | ∀ v, b v ∈ v.adicCompletionIntegers ℚ} :=
  RestrictedProduct.isOpen_forall_mem (fun _ => Valued.isOpen_valuationSubring _)
#print axioms isOpen_integral_finite

theorem isCompact_integral_finite :
    IsCompact {b : FiniteAdeleRing ℤ ℚ | ∀ v, b v ∈ v.adicCompletionIntegers ℚ} := by
  have : ∀ v : HeightOneSpectrum ℤ, CompactSpace (v.adicCompletionIntegers ℚ) :=
    compactSpace_integers
  have heq : {b : FiniteAdeleRing ℤ ℚ | ∀ v, b v ∈ v.adicCompletionIntegers ℚ} =
      (Set.range (RestrictedProduct.structureMap (fun v : HeightOneSpectrum ℤ => v.adicCompletion ℚ)
        (fun v => (v.adicCompletionIntegers ℚ : Set (v.adicCompletion ℚ))) Filter.cofinite) :
        Set (FiniteAdeleRing ℤ ℚ)) := by
    ext b
    constructor
    · intro hb
      exact ⟨fun v => ⟨b v, hb v⟩, rfl⟩
    · rintro ⟨x, rfl⟩ v
      exact (x v).2
  rw [heq]
  exact isCompact_range RestrictedProduct.isEmbedding_structureMap.continuous
#print axioms isCompact_integral_finite

/-- The product formula: for every nonzero fraction `x`, its ordinary size times its p-adic
sizes at all primes `p` multiply to exactly 1. -/
theorem prod_abs_mul_prod_padicNorm_eq_one {x : ℚ} (hx : x ≠ 0) :
    |x| * ∏ᶠ p : Nat.Primes, padicNorm (p : ℕ) x = 1 := by
  have hnum : x.num.natAbs ≠ 0 := by simpa using hx
  have key : (fun p : Nat.Primes => padicNorm (p : ℕ) x) =
      fun p : Nat.Primes => padicNorm (p : ℕ) ((x.num.natAbs : ℕ) : ℚ) / padicNorm (p : ℕ) ((x.den : ℕ) : ℚ) := by
    funext p
    have : Fact (p : ℕ).Prime := ⟨p.2⟩
    conv_lhs => rw [← Rat.num_div_den x]
    rw [padicNorm.div]
    congr 1
    rw [Nat.cast_natAbs, Int.cast_abs]
    rcases abs_choice ((x.num : ℚ)) with h | h <;> rw [h]
    rw [padicNorm.neg]
  rw [key, finprod_div_distrib (finite_mulSupport_padicNorm_nat hnum)
    (finite_mulSupport_padicNorm_nat x.den_nz), finprod_padicNorm_nat hnum,
    finprod_padicNorm_nat x.den_nz]
  have hxa : |x| = |(x.num : ℚ)| / (x.den : ℚ) := by
    conv_lhs => rw [← Rat.num_div_den x]
    rw [abs_div, abs_of_pos (by positivity : (0:ℚ) < x.den)]
  rw [hxa, Nat.cast_natAbs, Int.cast_abs]
  have h1 : |(x.num : ℚ)| ≠ 0 := by simpa using x.num_ne_zero.2 hx
  have h2 : ((x.den : ℕ) : ℚ) ≠ 0 := by simp
  field_simp

/-- Every adele of Q splits in exactly one way as a fraction plus a remainder whose real entry
lies in [0, 1) and whose p-adic entries are all p-adic integers: `𝔸_Q = Q + ([0, 1) × Ẑ)`. -/
theorem adele_eq_unique_rat_add_fundamental_box (a : 𝔸[ℤ, ℚ]) :
    ∃! q : ℚ,
      0 ≤ realEntry (a - algebraMap ℚ 𝔸[ℤ, ℚ] q) ∧
      realEntry (a - algebraMap ℚ 𝔸[ℤ, ℚ] q) < 1 ∧
      ∀ v : HeightOneSpectrum ℤ,
        (a - algebraMap ℚ 𝔸[ℤ, ℚ] q).2 v ∈ v.adicCompletionIntegers ℚ := by
  obtain ⟨q, hq⟩ := exists_inBox a
  exact ⟨q, hq, fun q' hq' => inBox_unique a q' q hq' hq⟩

/-- The fractions sit in the adeles of Q as a discrete subgroup, and the quotient `𝔸_Q / Q`
is compact. -/
theorem rat_discrete_in_adeles_and_compact_quotient :
    DiscreteTopology (AdeleRing.principalSubgroup ℤ ℚ) ∧
      CompactSpace (𝔸[ℤ, ℚ] ⧸ AdeleRing.principalSubgroup ℤ ℚ) := by
  constructor
  · rw [discreteTopology_iff_isOpen_singleton_zero, isOpen_induced_iff]
    refine ⟨{b | |realEntry b| < 1 ∧ ∀ v, b.2 v ∈ v.adicCompletionIntegers ℚ}, ?_, ?_⟩
    · exact (isOpen_lt (continuous_abs.comp continuous_realEntry) continuous_const).inter
        (isOpen_integral_finite.preimage continuous_snd)
    · ext ⟨x, hx⟩
      obtain ⟨q, rfl⟩ := RingHom.mem_range.1 hx
      simp only [Set.mem_preimage, Set.mem_ofPred_eq, Set.mem_singleton_iff, realEntry_algebraMap,
        snd_algebraMap]
      constructor
      · rintro ⟨h1, h2⟩
        have := rat_eq_zero_of_integral q h2 h1
        subst this
        ext; simp
      · intro h
        have hq : q = 0 := by
          have := congrArg Subtype.val h
          exact AdeleRing.algebraMap_injective ℤ ℚ (by simpa using this)
        subst hq
        simp
  · have hC : IsCompact ((realToInf '' Set.Icc 0 1) ×ˢ
        {b : FiniteAdeleRing ℤ ℚ | ∀ v, b v ∈ v.adicCompletionIntegers ℚ} : Set 𝔸[ℤ, ℚ]) :=
      (isCompact_Icc.image continuous_realToInf).prod isCompact_integral_finite
    refine ⟨?_⟩
    have hsurj : (QuotientAddGroup.mk '' ((realToInf '' Set.Icc 0 1) ×ˢ
        {b : FiniteAdeleRing ℤ ℚ | ∀ v, b v ∈ v.adicCompletionIntegers ℚ} : Set 𝔸[ℤ, ℚ]) :
        Set (𝔸[ℤ, ℚ] ⧸ AdeleRing.principalSubgroup ℤ ℚ)) = Set.univ := by
      refine Set.eq_univ_of_forall fun z => ?_
      obtain ⟨a, rfl⟩ := QuotientAddGroup.mk_surjective z
      obtain ⟨q, h0, h1, hf⟩ := exists_inBox a
      refine ⟨a - algebraMap ℚ 𝔸[ℤ, ℚ] q,
        ⟨⟨realEntry (a - algebraMap ℚ 𝔸[ℤ, ℚ] q), ⟨h0, h1.le⟩, realToInf_realEntry _⟩, hf⟩, ?_⟩
      rw [QuotientAddGroup.eq]
      exact ⟨q, by simp⟩
    rw [← hsurj]
    exact hC.image QuotientAddGroup.continuous_mk

-- The card's 7/12: sizes 4 at 2, 3 at 3, 1/7 at 7, and the four sizes multiply to 1.
example : padicNorm 2 (7 / 12 : ℚ) = 4 := by
  rw [show (7 / 12 : ℚ) = ((7 : ℕ) : ℚ) / ((2 : ℕ) * (2 : ℕ) * (3 : ℕ)) by norm_num,
    padicNorm.div, padicNorm.mul, padicNorm.mul,
    padicNorm_prime_of_ne Nat.prime_two (by norm_num) (by norm_num),
    padicNorm_prime_self Nat.prime_two,
    padicNorm_prime_of_ne Nat.prime_two Nat.prime_three (by norm_num)]
  norm_num
example : padicNorm 3 (7 / 12 : ℚ) = 3 := by
  rw [show (7 / 12 : ℚ) = ((7 : ℕ) : ℚ) / ((2 : ℕ) * (2 : ℕ) * (3 : ℕ)) by norm_num,
    padicNorm.div, padicNorm.mul, padicNorm.mul,
    padicNorm_prime_of_ne Nat.prime_three (by norm_num) (by norm_num),
    padicNorm_prime_self Nat.prime_three,
    padicNorm_prime_of_ne Nat.prime_three Nat.prime_two (by norm_num)]
  norm_num
example : padicNorm 7 (7 / 12 : ℚ) = 1 / 7 := by
  have : Fact (Nat.Prime 7) := ⟨by norm_num⟩
  rw [show (7 / 12 : ℚ) = ((7 : ℕ) : ℚ) / ((2 : ℕ) * (2 : ℕ) * (3 : ℕ)) by norm_num,
    padicNorm.div, padicNorm.mul, padicNorm.mul,
    padicNorm_prime_self (by norm_num : Nat.Prime 7),
    padicNorm_prime_of_ne (by norm_num : Nat.Prime 7) Nat.prime_two (by norm_num),
    padicNorm_prime_of_ne (by norm_num : Nat.Prime 7) Nat.prime_three (by norm_num)]
  norm_num
example : padicNorm 5 (7 / 12 : ℚ) = 1 := by
  have : Fact (Nat.Prime 5) := ⟨by norm_num⟩
  rw [show (7 / 12 : ℚ) = ((7 : ℕ) : ℚ) / ((2 : ℕ) * (2 : ℕ) * (3 : ℕ)) by norm_num,
    padicNorm.div, padicNorm.mul, padicNorm.mul,
    padicNorm_prime_of_ne (by norm_num : Nat.Prime 5) (by norm_num) (by norm_num),
    padicNorm_prime_of_ne (by norm_num : Nat.Prime 5) Nat.prime_two (by norm_num),
    padicNorm_prime_of_ne (by norm_num : Nat.Prime 5) Nat.prime_three (by norm_num)]
  norm_num
example : (4 : ℚ) * 3 * (1 / 7) * (7 / 12) = 1 := by norm_num
-- Without the real place the p-adic sizes of 7/12 multiply to 12/7, not 1.
example : (4 : ℚ) * 3 * (1 / 7) = 12 / 7 := by norm_num

-- The worked split: principal parts 1/4 and 2/3 sum to 11/12, the shift is 4, the fraction
-- is 59/12, and the remainder is 23/60 at the real place, -14/3 at 2 and -17/4 at 3.
example : (1 / 4 : ℚ) + 2 / 3 = 11 / 12 := by norm_num
example : (11 / 12 : ℚ) + 4 = 59 / 12 := by norm_num
example : (53 / 10 : ℚ) - 59 / 12 = 23 / 60 ∧ (0 : ℚ) ≤ 23 / 60 ∧ (23 / 60 : ℚ) < 1 := by norm_num
example : (1 / 4 : ℚ) - 59 / 12 = -14 / 3 ∧ (2 / 3 : ℚ) - 59 / 12 = -17 / 4 := by norm_num

-- What breaks: 10! = 2^8 * 3^4 * 5^2 * 7, and 1/p at every p up to 29 needs denominator
-- 6,469,693,230.
example : Nat.factorial 10 = 2 ^ 8 * 3 ^ 4 * 5 ^ 2 * 7 ∧ Nat.factorial 10 = 3628800 := by
  constructor <;> decide
example : 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 = 6469693230 := by norm_num

-- The idele with 5 at the real place, 12 at 2 and 1/3 at 3: fraction 4/3, real part 15/4,
-- and idele norm 5 * (1/4) * 3 = 15/4.
example : padicNorm 2 (12 : ℚ) = 1 / 4 ∧ padicNorm 3 (1 / 3 : ℚ) = 3 := by
  constructor
  · rw [show (12 : ℚ) = (2 : ℕ) * (2 : ℕ) * (3 : ℕ) by norm_num, padicNorm.mul, padicNorm.mul,
      padicNorm_prime_self Nat.prime_two,
      padicNorm_prime_of_ne Nat.prime_two Nat.prime_three (by norm_num)]
    norm_num
  · rw [show (1 / 3 : ℚ) = 1 / ((3 : ℕ) : ℚ) by norm_num, padicNorm.div, padicNorm.one,
      padicNorm_prime_self Nat.prime_three]
    norm_num
example : (5 : ℚ) / (4 / 3) = 15 / 4 ∧ (5 : ℚ) * (1 / 4) * 3 = 15 / 4 := by norm_num

-- Mod 20: the class of the idele with 3 in the 3-slot is 3⁻¹ = 7; there are 8 units mod 20,
-- and the subgroup {1, 9} has index 4.
example : (3 * 7 : ZMod 20) = 1 := by decide
example : Fintype.card (ZMod 20)ˣ = 8 := by
  rw [ZMod.card_units_eq_totient]; decide
example : (9 * 9 : ZMod 20) = 1 := by decide

#print axioms prod_abs_mul_prod_padicNorm_eq_one
#print axioms adele_eq_unique_rat_add_fundamental_box
#print axioms rat_discrete_in_adeles_and_compact_quotient
