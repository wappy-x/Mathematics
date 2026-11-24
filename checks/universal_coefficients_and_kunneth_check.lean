-- Universal coefficients and Kunneth: the tensor and Tor of two twists Z/m and Z/n are both Z/gcd(m, n), a twist tensored with any group G is G/nG, and a pair of cells times a pair of cells has Z/gcd(m, n) in two dimensions.
import Mathlib.LinearAlgebra.TensorProduct.Basic
import Mathlib.LinearAlgebra.Quotient.Basic
import Mathlib.LinearAlgebra.Prod
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.LinearAlgebra.TensorProduct.Quotient
import Mathlib.Data.ZMod.QuotientRing
import Mathlib.Tactic.LinearCombination
import Mathlib.LinearAlgebra.Isomorphisms

open TensorProduct

theorem twist_tensor_quot_aux (n : ℕ) (G : Type*) [AddCommGroup G] :
    Nonempty ((ZMod n ⊗[ℤ] G) ≃+
      (G ⧸ LinearMap.range (n • LinearMap.id : G →ₗ[ℤ] G))) := by
  let e1 : ZMod n ≃ₗ[ℤ] ℤ ⧸ Ideal.span {(n : ℤ)} :=
    (Int.quotientSpanNatEquivZMod n).symm.toAddEquiv.toIntLinearEquiv
  have h : (Ideal.span {(n : ℤ)} • ⊤ : Submodule ℤ G) =
      LinearMap.range (n • LinearMap.id : G →ₗ[ℤ] G) := by
    rw [Submodule.ideal_span_singleton_smul]
    ext x
    simp [Submodule.mem_smul_pointwise_iff_exists]
  exact ⟨((TensorProduct.congr e1 (LinearEquiv.refl ℤ G)) ≪≫ₗ
    TensorProduct.quotTensorEquivQuotSMul G _ ≪≫ₗ Submodule.quotEquivOfEq _ _ h).toAddEquiv⟩

#print axioms twist_tensor_quot_aux

theorem zmod_quot_range_aux (m n : ℕ) (hn : 1 ≤ n) :
    Nonempty ((ZMod n ⧸ LinearMap.range (m • LinearMap.id : ZMod n →ₗ[ℤ] ZMod n)) ≃+
      ZMod (Nat.gcd m n)) := by
  have : NeZero n := ⟨by omega⟩
  have hsm : ∀ y : ZMod n, (m • LinearMap.id : ZMod n →ₗ[ℤ] ZMod n) y = (m : ZMod n) * y :=
    fun y => by rw [LinearMap.smul_apply, LinearMap.id_apply, nsmul_eq_mul]
  let f : ZMod n →ₗ[ℤ] ZMod (Nat.gcd m n) :=
    (ZMod.castHom (Nat.gcd_dvd_right m n) (ZMod (Nat.gcd m n))).toAddMonoidHom.toIntLinearMap
  have hf : ∀ k : ℤ, f (k : ZMod n) = (k : ZMod (Nat.gcd m n)) := fun k => by
    simp [f]
  have hsurj : Function.Surjective f := by
    intro z
    obtain ⟨k, rfl⟩ := ZMod.intCast_surjective z
    exact ⟨k, hf k⟩
  have hker : LinearMap.ker f = LinearMap.range (m • LinearMap.id : ZMod n →ₗ[ℤ] ZMod n) := by
    ext x
    obtain ⟨k, rfl⟩ := ZMod.intCast_surjective x
    rw [LinearMap.mem_ker, LinearMap.mem_range]
    constructor
    · intro hk
      rw [hf, ZMod.intCast_zmod_eq_zero_iff_dvd] at hk
      obtain ⟨c, hc⟩ := hk
      have hb := Int.gcd_eq_gcd_ab (m : ℤ) (n : ℤ)
      rw [Int.gcd_natCast_natCast] at hb
      refine ⟨((Int.gcdA (m : ℤ) n * c : ℤ) : ZMod n), ?_⟩
      rw [hsm, hc, hb]
      have h0 : ((n : ℕ) : ZMod n) = 0 := ZMod.natCast_self n
      push_cast
      rw [h0]
      ring
    · rintro ⟨y, hy⟩
      rw [← hy, LinearMap.smul_apply, map_nsmul, nsmul_eq_mul]
      have : ((m : ℕ) : ZMod (Nat.gcd m n)) = 0 :=
        (CharP.cast_eq_zero_iff (ZMod (Nat.gcd m n)) _ m).2 (Nat.gcd_dvd_left m n)
      rw [this, zero_mul]
  exact ⟨((Submodule.quotEquivOfEq _ _ hker.symm).trans
    (f.quotKerEquivOfSurjective hsurj)).toAddEquiv⟩

#print axioms zmod_quot_range_aux

theorem zmod_ker_smul_aux (m n : ℕ) (hm : 1 ≤ m) (hn : 1 ≤ n) :
    Nonempty (LinearMap.ker (m • LinearMap.id : ZMod n →ₗ[ℤ] ZMod n) ≃+ ZMod (Nat.gcd m n)) := by
  have hg0 : 0 < Nat.gcd m n := Nat.gcd_pos_of_pos_left n (by omega)
  obtain ⟨m', hm'⟩ := Nat.gcd_dvd_left m n
  obtain ⟨n', hn'⟩ := Nat.gcd_dvd_right m n
  have hcop : Nat.Coprime m' n' := by
    have h := Nat.coprime_div_gcd_div_gcd hg0
    rwa [Nat.div_eq_of_eq_mul_left hg0 (by rw [mul_comm]; exact hm'),
      Nat.div_eq_of_eq_mul_left hg0 (by rw [mul_comm]; exact hn')] at h
  generalize Nat.gcd m n = g at hg0 hm' hn' ⊢
  subst hm' hn'
  have : NeZero (g * n') := ⟨by omega⟩
  have : NeZero g := ⟨by omega⟩
  have hsm : ∀ y : ZMod (g * n'), (((g * m' : ℕ)) • LinearMap.id : ZMod (g * n') →ₗ[ℤ] ZMod (g * n')) y
      = ((g * m' : ℕ) : ZMod (g * n')) * y :=
    fun y => by rw [LinearMap.smul_apply, LinearMap.id_apply, nsmul_eq_mul]
  let f0 : ℤ →+ ZMod (g * n') :=
    (AddMonoidHom.mulLeft ((n' : ℕ) : ZMod (g * n'))).comp (Int.castAddHom (ZMod (g * n')))
  have hf0 : f0 g = 0 := by
    simp only [f0, AddMonoidHom.comp_apply, AddMonoidHom.coe_mulLeft, Int.coe_castAddHom]
    push_cast
    rw [← Nat.cast_mul, mul_comm, ZMod.natCast_self]
  let ψ : ZMod g →+ ZMod (g * n') := ZMod.lift _ ⟨f0, hf0⟩
  have hψ : ∀ c : ℤ, ψ (c : ZMod g) = ((n' : ℤ) * c : ℤ) := fun c => by
    simp [ψ, ZMod.lift_coe, f0]
  have hmem : ∀ x, ψ x ∈ LinearMap.ker
      (((g * m' : ℕ)) • LinearMap.id : ZMod (g * n') →ₗ[ℤ] ZMod (g * n')) := by
    intro x
    obtain ⟨c, rfl⟩ := ZMod.intCast_surjective x
    rw [LinearMap.mem_ker, hsm, hψ]
    have : ((g * m' : ℕ) : ZMod (g * n')) * (((n' : ℤ) * c : ℤ) : ZMod (g * n')) =
        (((m' * c : ℤ) * ((g * n' : ℕ) : ℤ) : ℤ) : ZMod (g * n')) := by
      push_cast; ring
    rw [this, Int.cast_mul, Int.cast_natCast, ZMod.natCast_self, mul_zero]
  let ψ' := ψ.codRestrict _ hmem
  have hn'0 : (n' : ℤ) ≠ 0 := by
    have : n' ≠ 0 := by rintro rfl; omega
    exact_mod_cast this
  have hg' : (g : ℤ) ≠ 0 := by exact_mod_cast hg0.ne'
  have hbij : Function.Bijective ψ' := by
    constructor
    · rw [injective_iff_map_eq_zero]
      intro x hx
      obtain ⟨c, rfl⟩ := ZMod.intCast_surjective x
      have hx' : ψ (c : ZMod g) = 0 := congrArg Subtype.val hx
      rw [hψ, ZMod.intCast_zmod_eq_zero_iff_dvd] at hx'
      rw [ZMod.intCast_zmod_eq_zero_iff_dvd]
      rw [Nat.cast_mul, mul_comm] at hx'
      exact (mul_dvd_mul_iff_left hn'0).1 hx'
    · rintro ⟨y, hy⟩
      obtain ⟨k, rfl⟩ := ZMod.intCast_surjective y
      rw [LinearMap.mem_ker, hsm] at hy
      have hy' : ((((g * m' : ℕ) : ℤ) * k : ℤ) : ZMod (g * n')) = 0 := by push_cast at hy ⊢; exact hy
      rw [ZMod.intCast_zmod_eq_zero_iff_dvd] at hy'
      push_cast at hy'
      rw [mul_assoc] at hy'
      have h2 : (n' : ℤ) ∣ (m' : ℤ) * k := (mul_dvd_mul_iff_left hg').1 hy'
      have h3 : (n' : ℤ) ∣ k :=
        (Nat.isCoprime_iff_coprime.2 hcop.symm).dvd_of_dvd_mul_left h2
      obtain ⟨c, rfl⟩ := h3
      refine ⟨(c : ZMod g), ?_⟩
      apply Subtype.ext
      show ψ _ = _
      rw [hψ]
  exact ⟨(AddEquiv.ofBijective ψ' hbij).symm⟩

#print axioms zmod_ker_smul_aux

/-- For two twists Z/m and Z/n with m, n ≥ 1, the tensor product Z/m ⊗ Z/n and
Tor(Z/m, Z/n), the m-torsion {g ∈ Z/n : m g = 0}, are both the cyclic group Z/gcd(m, n). -/
theorem twist_tensor_and_tor_are_zmod_gcd (m n : ℕ) (hm : 1 ≤ m) (hn : 1 ≤ n) :
    Nonempty ((ZMod m ⊗[ℤ] ZMod n) ≃+ ZMod (Nat.gcd m n)) ∧
    Nonempty (LinearMap.ker (m • LinearMap.id : ZMod n →ₗ[ℤ] ZMod n) ≃+ ZMod (Nat.gcd m n)) := by
  obtain ⟨e⟩ := twist_tensor_quot_aux m (ZMod n)
  obtain ⟨e'⟩ := zmod_quot_range_aux m n hn
  exact ⟨⟨e.trans e'⟩, zmod_ker_smul_aux m n hm hn⟩

/-- The tensor rule for a twist Z/n, n ≥ 1, and any abelian group G: Z/n ⊗ G is G/nG,
the cokernel of multiplication by n on G. -/
theorem twist_tensor_eq_quotient_by_multiples (n : ℕ) (hn : 1 ≤ n)
    (G : Type*) [AddCommGroup G] :
    Nonempty ((ZMod n ⊗[ℤ] G) ≃+
      (G ⧸ LinearMap.range (n • LinearMap.id : G →ₗ[ℤ] G))) := by
  exact twist_tensor_quot_aux n G

/-- A pair of cells e' ↦ m e times a pair f' ↦ n f (m, n ≥ 1, e in dimension a) gives four cells
with ∂(e' × f) = m (e × f), ∂(e × f') = s n (e × f) and ∂(e' × f') = m (e × f') − s n (e' × f),
where s = (−1)^a. Its homology is Z/gcd(m, n) in the bottom dimension (the tensor term),
Z/gcd(m, n) one dimension up (the Tor term), and 0 in the top dimension.
Coordinates (x, y) stand for x (e' × f) + y (e × f'). -/
theorem pair_times_pair_has_zmod_gcd_twice (m n a : ℕ) (hm : 1 ≤ m) (hn : 1 ≤ n) :
    let s : ℤ := (-1) ^ a
    let d₁ : ℤ × ℤ →ₗ[ℤ] ℤ := (m : ℤ) • LinearMap.fst ℤ ℤ ℤ + (s * n) • LinearMap.snd ℤ ℤ ℤ
    let d₂ : ℤ →ₗ[ℤ] ℤ × ℤ := LinearMap.prod (-(s * n) • LinearMap.id) ((m : ℤ) • LinearMap.id)
    Nonempty ((ℤ ⧸ LinearMap.range d₁) ≃+ ZMod (Nat.gcd m n)) ∧
    Nonempty ((LinearMap.ker d₁ ⧸ (LinearMap.range d₂).comap (LinearMap.ker d₁).subtype) ≃+
      ZMod (Nat.gcd m n)) ∧
    LinearMap.ker d₂ = ⊥ := by
  intro s d₁ d₂
  have hs : s * s = 1 := by
    simp only [s]; rw [← pow_add, ← two_mul, pow_mul]; norm_num
  have hd₁ : ∀ p : ℤ × ℤ, d₁ p = m * p.1 + s * n * p.2 := fun p => by simp [d₁]
  have hd₂ : ∀ t : ℤ, d₂ t = (-(s * n) * t, m * t) := fun t => by simp [d₂]; ring
  have hg0 : 0 < Nat.gcd m n := Nat.gcd_pos_of_pos_left n (by omega)
  have hb := Int.gcd_eq_gcd_ab (m : ℤ) (n : ℤ)
  rw [Int.gcd_natCast_natCast] at hb
  obtain ⟨m', hm'⟩ := Nat.gcd_dvd_left m n
  obtain ⟨n', hn'⟩ := Nat.gcd_dvd_right m n
  have hm'' : (m : ℤ) = (Nat.gcd m n : ℤ) * m' := by exact_mod_cast hm'
  have hn'' : (n : ℤ) = (Nat.gcd m n : ℤ) * n' := by exact_mod_cast hn'
  clear hm' hn'
  generalize Nat.gcd m n = g at hb hm'' hn'' hg0 ⊢
  generalize Int.gcdA (m : ℤ) n = A at hb
  generalize Int.gcdB (m : ℤ) n = B at hb
  have hg' : (g : ℤ) ≠ 0 := by exact_mod_cast hg0.ne'
  have : NeZero g := ⟨by omega⟩
  have h1 : A * m' + B * n' = 1 := by
    apply mul_left_cancel₀ hg'
    linear_combination -hb - A * hm'' - B * hn''
  refine ⟨?_, ?_, ?_⟩
  · -- the tensor term
    have hr : LinearMap.range d₁ = Ideal.span {(g : ℤ)} := by
      ext x
      rw [LinearMap.mem_range, Ideal.mem_span_singleton]
      constructor
      · rintro ⟨p, rfl⟩
        exact ⟨m' * p.1 + s * n' * p.2, by rw [hd₁, hm'', hn'']; ring⟩
      · rintro ⟨c, rfl⟩
        exact ⟨(A * c, s * B * c), by rw [hd₁]; linear_combination (-c) * hb + (c * n * B) * hs⟩
    exact ⟨((Submodule.quotEquivOfEq _ _ hr).toAddEquiv.trans
      (Int.quotientSpanNatEquivZMod g).toAddEquiv)⟩
  · -- the Tor term
    let φ : LinearMap.ker d₁ →ₗ[ℤ] ZMod g :=
      (Int.castAddHom (ZMod g)).toIntLinearMap ∘ₗ
        ((A • LinearMap.snd ℤ ℤ ℤ - (s * B) • LinearMap.fst ℤ ℤ ℤ) ∘ₗ (LinearMap.ker d₁).subtype)
    have hφ : ∀ p, φ p = ((A * p.1.2 - s * B * p.1.1 : ℤ) : ZMod g) := fun p => by
      simp [φ]
    have hsurj : Function.Surjective φ := by
      intro z
      obtain ⟨c, rfl⟩ := ZMod.intCast_surjective z
      have hv : ((-(s * n') * c, m' * c) : ℤ × ℤ) ∈ LinearMap.ker d₁ := by
        rw [LinearMap.mem_ker, hd₁]
        simp only
        rw [hm'', hn'']
        linear_combination (0 : ℤ) * hs
      refine ⟨⟨_, hv⟩, ?_⟩
      rw [hφ]
      congr 1
      simp only
      linear_combination c * h1 + (c * B * n') * hs
    have hker : LinearMap.ker φ = (LinearMap.range d₂).comap (LinearMap.ker d₁).subtype := by
      ext ⟨⟨x, y⟩, hp⟩
      have hp' : (m : ℤ) * x + s * n * y = 0 := by rw [LinearMap.mem_ker, hd₁] at hp; exact hp
      have hkey : (m' : ℤ) * x + s * n' * y = 0 := by
        apply mul_left_cancel₀ hg'
        linear_combination hp' - x * hm'' - s * y * hn''
      rw [LinearMap.mem_ker, hφ, Submodule.mem_comap, Submodule.coe_subtype, LinearMap.mem_range,
        ZMod.intCast_zmod_eq_zero_iff_dvd]
      simp only
      constructor
      · rintro ⟨c, hc⟩
        refine ⟨c, ?_⟩
        rw [hd₂]
        ext
        · simp only
          linear_combination -((s * c) * hn'' - (s * n') * hc - (n' * B * x) * hs - x * h1 + A * hkey)
        · simp only
          linear_combination -((-c) * hm'' + m' * hc - y * h1 + (B * s) * hkey - (B * n' * y) * hs)
      · rintro ⟨t, ht⟩
        rw [hd₂] at ht
        simp only [Prod.mk.injEq] at ht
        obtain ⟨hx, hy⟩ := ht
        refine ⟨t, ?_⟩
        rw [← hx, ← hy]
        linear_combination (-t) * hb + (B * n * t) * hs
    exact ⟨((Submodule.quotEquivOfEq _ _ hker.symm).trans
      (φ.quotKerEquivOfSurjective hsurj)).toAddEquiv⟩
  · -- nothing in the top dimension
    rw [LinearMap.ker_eq_bot']
    intro t ht
    have h2 := congrArg Prod.snd ht
    rw [hd₂] at h2
    simp only [Prod.snd_zero] at h2
    have hm0 : (m : ℤ) ≠ 0 := by exact_mod_cast (show m ≠ 0 by omega)
    exact (mul_eq_zero.1 h2).resolve_left hm0

-- RP²: Tor(Z/2, Z/2), the elements g of Z/2 with 2g = 0, has gcd(2, 2) = 2 elements.
example : ((Finset.range 2).filter (fun g => 2 * g % 2 = 0)).card = Nat.gcd 2 2 := by decide

-- Mod 3 the twist of RP² dies: gcd(2, 3) = 1.
example : Nat.gcd 2 3 = 1 := by decide

-- The brute-force check: Tor(Z/m, Z/n) has gcd(m, n) elements for all 144 pairs m, n = 1..12.
example : ∀ m ∈ Finset.Icc 1 12, ∀ n ∈ Finset.Icc 1 12,
    ((Finset.range n).filter (fun g => m * g % n = 0)).card = Nat.gcd m n := by decide

-- Mistake 1: mod 2 by tensoring only gives 1, 1, 0, alternating sum 0, but χ(RP²) = 1 − 1 + 1 = 1.
example : (1 : ℤ) - 1 + 0 ≠ 1 - 1 + 1 := by norm_num

-- RP² × RP²: 1, 2, 3, 2, 1 cells per dimension, so χ = 1 = χ(RP²)².
example : (1 : ℤ) - 2 + 3 - 2 + 1 = (1 - 1 + 1) ^ 2 := by norm_num

-- RP² × RP² mod 2 reads 1, 2, 3, 2, 1, the coefficients of (1 + t + t²)².
example : ((1 + Polynomial.X + Polynomial.X ^ 2) ^ 2 : Polynomial ℤ) =
    1 + 2 * Polynomial.X + 3 * Polynomial.X ^ 2 + 2 * Polynomial.X ^ 3 + Polynomial.X ^ 4 := by
  ring

-- Step 6 (m = n = 2, a = 1, s = −1): z = (e₂ × e₁) + (e₁ × e₂) is a cycle, 2·1 + (−1)·2·1 = 0,
-- and ∂(e₂ × e₂) = (2, 2) = 2z.
example : (2 : ℤ) * 1 + (-1) * 2 * 1 = 0 ∧ ((-((-1 : ℤ) * 2), (2 : ℤ)) = 2 • ((1 : ℤ), (1 : ℤ))) := by
  norm_num

#print axioms twist_tensor_and_tor_are_zmod_gcd
#print axioms twist_tensor_eq_quotient_by_multiples
#print axioms pair_times_pair_has_zmod_gcd_twice
