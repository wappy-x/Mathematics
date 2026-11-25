-- Hilbert's syzygy theorem: every finitely generated module over a polynomial ring in n variables over a field has a finite free resolution of length at most n, and the twisted cubic's resolution has two syzygies and Hilbert function 3t + 1.
import Mathlib.RingTheory.MvPolynomial.Basic
import Mathlib.Algebra.Module.Submodule.Ker
import Mathlib.Algebra.Module.Submodule.Range
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib

open MvPolynomial

universe u v

namespace SyzygyProof

open Polynomial TensorProduct

/-- A finite free resolution of length at most `m`. -/
def FFR (A : Type*) [CommRing A] (M : Type*) [AddCommGroup M] [Module A M] (m : ℕ) : Prop :=
  ∃ (r : ℕ → ℕ) (ε : (Fin (r 0) → A) →ₗ[A] M)
    (d : ∀ i : ℕ, (Fin (r (i + 1)) → A) →ₗ[A] (Fin (r i) → A)),
    (∀ i, m < i → r i = 0) ∧ Function.Surjective ε ∧ LinearMap.ker ε = LinearMap.range (d 0) ∧
    ∀ i, LinearMap.ker (d i) = LinearMap.range (d (i + 1))

theorem ffr_of_complex {A : Type*} [CommRing A] {M : Type*} [AddCommGroup M] [Module A M]
    (m : ℕ) (r : ℕ → ℕ) (F : ℕ → Type*) [∀ i, AddCommGroup (F i)] [∀ i, Module A (F i)]
    (e : ∀ i, F i ≃ₗ[A] (Fin (r i) → A)) (ε : F 0 →ₗ[A] M) (d : ∀ i, F (i + 1) →ₗ[A] F i)
    (hr : ∀ i, m < i → r i = 0) (hε : Function.Surjective ε)
    (h0 : LinearMap.ker ε = LinearMap.range (d 0))
    (hd : ∀ i, LinearMap.ker (d i) = LinearMap.range (d (i + 1))) : FFR A M m := by
  refine ⟨r, ε ∘ₗ (e 0).symm.toLinearMap,
    fun i => (e i).toLinearMap ∘ₗ d i ∘ₗ (e (i + 1)).symm.toLinearMap, hr,
    hε.comp (e 0).symm.surjective, ?_, ?_⟩
  · ext x
    simp only [LinearMap.mem_ker, LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply,
      LinearMap.mem_range]
    constructor
    · intro hx
      have : (e 0).symm x ∈ LinearMap.ker ε := hx
      rw [h0] at this
      obtain ⟨y, hy⟩ := this
      exact ⟨e 1 y, by simp [hy]⟩
    · rintro ⟨y, hy⟩
      have : (e 0).symm x ∈ LinearMap.range (d 0) := ⟨(e 1).symm y, by rw [← hy]; simp⟩
      rw [← h0] at this
      exact this
  · intro i
    ext x
    simp only [LinearMap.mem_ker, LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply,
      LinearMap.mem_range, LinearEquiv.map_eq_zero_iff]
    constructor
    · intro hx
      have : (e (i + 1)).symm x ∈ LinearMap.ker (d i) := hx
      rw [hd] at this
      obtain ⟨y, hy⟩ := this
      exact ⟨e (i + 2) y, by simp [hy]⟩
    · rintro ⟨y, hy⟩
      have : (e (i + 1)).symm x ∈ LinearMap.range (d (i + 1)) :=
        ⟨(e (i + 2)).symm y, by rw [← hy]; simp⟩
      rw [← hd] at this
      exact this

theorem ffr_ring_transfer {A B : Type*} [CommRing A] [CommRing B] (e : A ≃+* B)
    {M : Type*} [AddCommGroup M] [Module A M] [Module B M]
    (he : ∀ (a : A) (x : M), a • x = e a • x) (m : ℕ) (h : FFR A M m) : FFR B M m := by
  obtain ⟨r, ε, d, hr, hε, h0, hd⟩ := h
  let ε' : (Fin (r 0) → B) →ₗ[B] M :=
    { toFun := fun v => ε (fun i => e.symm (v i))
      map_add' := fun v w => by
        rw [← map_add]; congr 1; funext i; simp
      map_smul' := fun b v => by
        have : (fun i => e.symm ((b • v) i)) = e.symm b • (fun i => e.symm (v i)) := by
          funext i; simp
        simp only [RingHom.id_apply]
        rw [this, map_smul, he]; simp }
  let d' : ∀ i, (Fin (r (i + 1)) → B) →ₗ[B] (Fin (r i) → B) := fun i =>
    { toFun := fun v k => e (d i (fun j => e.symm (v j)) k)
      map_add' := fun v w => by
        funext k
        have : (fun j => e.symm ((v + w) j)) = (fun j => e.symm (v j)) + (fun j => e.symm (w j)) := by
          funext j; simp
        show e (d i (fun j => e.symm ((v + w) j)) k) = e (d i _ k) + e (d i _ k)
        rw [this, map_add]; simp
      map_smul' := fun b v => by
        funext k
        have : (fun j => e.symm ((b • v) j)) = e.symm b • (fun j => e.symm (v j)) := by
          funext j; simp
        show e (d i (fun j => e.symm ((b • v) j)) k) = b * e (d i _ k)
        rw [this, map_smul]; simp }
  have hd'0 : ∀ i (v : Fin (r (i + 1)) → B), d' i v = 0 ↔ d i (fun j => e.symm (v j)) = 0 := by
    intro i v
    constructor
    · intro hv; funext k; have := congrFun hv k; simpa [d'] using this
    · intro hv; funext k; simp [d', hv]
  have hd'r : ∀ i (v : Fin (r (i + 1)) → B),
      v ∈ LinearMap.range (d' (i + 1)) ↔ (fun j => e.symm (v j)) ∈ LinearMap.range (d (i + 1)) := by
    intro i v
    constructor
    · rintro ⟨w, rfl⟩; exact ⟨fun j => e.symm (w j), by funext k; simp [d']⟩
    · rintro ⟨w, hw⟩
      refine ⟨fun j => e (w j), ?_⟩
      funext k
      have : (fun j => e.symm (e (w j))) = w := by funext j; simp
      simp only [d', LinearMap.coe_mk, AddHom.coe_mk, this, hw]; simp
  refine ⟨r, ε', d', hr, ?_, ?_, ?_⟩
  · intro x
    obtain ⟨v, hv⟩ := hε x
    exact ⟨fun i => e (v i), by simp [ε', hv]⟩
  · ext v
    simp only [LinearMap.mem_ker]
    change ε (fun i => e.symm (v i)) = 0 ↔ _
    rw [← LinearMap.mem_ker, h0]
    constructor
    · rintro ⟨w, hw⟩
      refine ⟨fun j => e (w j), ?_⟩
      funext k
      have : (fun j => e.symm (e (w j))) = w := by funext j; simp
      simp only [d', LinearMap.coe_mk, AddHom.coe_mk, this, hw]; simp
    · rintro ⟨w, rfl⟩; exact ⟨fun j => e.symm (w j), by funext k; simp [d']⟩
  · intro i
    ext v
    rw [LinearMap.mem_ker, hd'0, hd'r, ← LinearMap.mem_ker, hd]

theorem finite_ring_transfer {A B : Type*} [CommRing A] [CommRing B] (e : A ≃+* B)
    {M : Type*} [AddCommGroup M] [Module A M] [Module B M]
    (he : ∀ (a : A) (x : M), a • x = e a • x) [Module.Finite B M] : Module.Finite A M := by
  obtain ⟨S, hS⟩ := Module.Finite.fg_top (R := B) (M := M)
  refine ⟨⟨S, eq_top_iff.mpr fun x hx' => ?_⟩⟩
  have hx : x ∈ Submodule.span B (S : Set M) := by rw [hS]; trivial
  clear hx'
  induction hx using Submodule.span_induction with
  | mem y hy => exact Submodule.subset_span hy
  | zero => exact zero_mem _
  | add y z _ _ hy hz => exact add_mem hy hz
  | smul b y _ hy =>
    have : b • y = e.symm b • y := by rw [he]; simp
    rw [this]; exact Submodule.smul_mem _ _ hy

theorem ffr_field (k : Type*) [Field k] (M : Type*) [AddCommGroup M] [Module k M]
    [Module.Finite k M] : FFR k M 0 := by
  let r : ℕ → ℕ := fun i => Nat.casesOn i (Module.finrank k M) (fun _ => 0)
  have hsub : ∀ i, Subsingleton (Fin (r (i + 1)) → k) := fun i => by
    show Subsingleton (Fin 0 → k); infer_instance
  refine ⟨r, (Module.finBasis k M).equivFun.symm.toLinearMap, fun _ => 0, ?_, ?_, ?_, ?_⟩
  · intro i hi
    obtain ⟨j, rfl⟩ : ∃ j, i = j + 1 := ⟨i - 1, by omega⟩
    rfl
  · exact (Module.finBasis k M).equivFun.symm.surjective
  · rw [LinearEquiv.ker, LinearMap.range_zero]
  · intro i
    have := hsub i
    exact Subsingleton.elim _ _

theorem exists_lift {A : Type*} [CommRing A] {Y Z : Type*} [AddCommGroup Y] [Module A Y]
    [AddCommGroup Z] [Module A Z] {n : ℕ} (g : (Fin n → A) →ₗ[A] Y) (h : Z →ₗ[A] Y)
    (hgh : LinearMap.range g ≤ LinearMap.range h) : ∃ l : (Fin n → A) →ₗ[A] Z, h ∘ₗ l = g := by
  have : ∀ j, ∃ z, h z = g (Pi.single j 1) := fun j => hgh ⟨_, rfl⟩
  choose z hz using this
  refine ⟨(Pi.basisFun A (Fin n)).constr A z, ?_⟩
  apply (Pi.basisFun A (Fin n)).ext
  intro j
  simp [hz]

end SyzygyProof

namespace SyzygyProof

open Polynomial TensorProduct

theorem exists_comparison {A : Type*} [CommRing A] {X Y : Type*} [AddCommGroup X] [Module A X]
    [AddCommGroup Y] [Module A Y] (φ : X →ₗ[A] Y)
    (rA rB : ℕ → ℕ) (εA : (Fin (rA 0) → A) →ₗ[A] X)
    (dA : ∀ i : ℕ, (Fin (rA (i + 1)) → A) →ₗ[A] (Fin (rA i) → A))
    (εB : (Fin (rB 0) → A) →ₗ[A] Y)
    (dB : ∀ i : ℕ, (Fin (rB (i + 1)) → A) →ₗ[A] (Fin (rB i) → A))
    (h0A : LinearMap.ker εA = LinearMap.range (dA 0))
    (hdA : ∀ i, LinearMap.ker (dA i) = LinearMap.range (dA (i + 1)))
    (hεB : Function.Surjective εB) (h0B : LinearMap.ker εB = LinearMap.range (dB 0))
    (hdB : ∀ i, LinearMap.ker (dB i) = LinearMap.range (dB (i + 1))) :
    ∃ α : ∀ i, (Fin (rA i) → A) →ₗ[A] (Fin (rB i) → A),
      εB ∘ₗ α 0 = φ ∘ₗ εA ∧ ∀ i, dB i ∘ₗ α (i + 1) = α i ∘ₗ dA i := by
  obtain ⟨α0, hα0⟩ := exists_lift (φ ∘ₗ εA) εB (by rw [LinearMap.range_eq_top.mpr hεB]; exact le_top)
  have P0 : LinearMap.range (α0 ∘ₗ dA 0) ≤ LinearMap.range (dB 0) := by
    rintro _ ⟨x, rfl⟩
    rw [← h0B, LinearMap.mem_ker]
    have h1 := LinearMap.congr_fun hα0 (dA 0 x)
    simp only [LinearMap.coe_comp, Function.comp_apply] at h1 ⊢
    rw [h1]
    have : dA 0 x ∈ LinearMap.ker εA := by rw [h0A]; exact ⟨x, rfl⟩
    rw [LinearMap.mem_ker.mp this, map_zero]
  have key : ∀ i (β : (Fin (rA i) → A) →ₗ[A] (Fin (rB i) → A)),
      LinearMap.range (β ∘ₗ dA i) ≤ LinearMap.range (dB i) →
      ∃ β' : (Fin (rA (i + 1)) → A) →ₗ[A] (Fin (rB (i + 1)) → A),
        dB i ∘ₗ β' = β ∘ₗ dA i ∧
        LinearMap.range (β' ∘ₗ dA (i + 1)) ≤ LinearMap.range (dB (i + 1)) := by
    intro i β hβ
    obtain ⟨β', hβ'⟩ := exists_lift (β ∘ₗ dA i) (dB i) hβ
    refine ⟨β', hβ', ?_⟩
    rintro _ ⟨x, rfl⟩
    rw [← hdB, LinearMap.mem_ker]
    have h1 := LinearMap.congr_fun hβ' (dA (i + 1) x)
    simp only [LinearMap.coe_comp, Function.comp_apply] at h1 ⊢
    rw [h1]
    have : dA (i + 1) x ∈ LinearMap.ker (dA i) := by rw [hdA]; exact ⟨x, rfl⟩
    rw [LinearMap.mem_ker.mp this, map_zero]
  choose! next hnext1 hnext2 using key
  let seq : (i : ℕ) → {β : (Fin (rA i) → A) →ₗ[A] (Fin (rB i) → A) //
      LinearMap.range (β ∘ₗ dA i) ≤ LinearMap.range (dB i)} := fun i =>
    Nat.rec (motive := fun i => {β : (Fin (rA i) → A) →ₗ[A] (Fin (rB i) → A) //
      LinearMap.range (β ∘ₗ dA i) ≤ LinearMap.range (dB i)}) ⟨α0, P0⟩
      (fun i s => ⟨next i s.1, hnext2 i s.1 s.2⟩) i
  exact ⟨fun i => (seq i).1, hα0, fun i => hnext1 i (seq i).1 (seq i).2⟩

/-- Ranks with a separate rank in degree zero. -/
def joinRank (r0 : ℕ) (r : ℕ → ℕ) : ℕ → ℕ
  | 0 => r0
  | i + 1 => r i

/-- Differentials with a separate first map. -/
def joinDiff {A : Type*} [CommRing A] {r0 : ℕ} {r : ℕ → ℕ}
    (d0 : (Fin (r 0) → A) →ₗ[A] (Fin r0 → A))
    (d : ∀ i : ℕ, (Fin (r (i + 1)) → A) →ₗ[A] (Fin (r i) → A)) :
    ∀ i : ℕ, (Fin (joinRank r0 r (i + 1)) → A) →ₗ[A] (Fin (joinRank r0 r i) → A)
  | 0 => d0
  | i + 1 => d i

theorem ker_range_conj {A : Type*} [CommRing A] {U V W U' V' W' : Type*}
    [AddCommGroup U] [Module A U] [AddCommGroup V] [Module A V] [AddCommGroup W] [Module A W]
    [AddCommGroup U'] [Module A U'] [AddCommGroup V'] [Module A V'] [AddCommGroup W']
    [Module A W'] (f : U →ₗ[A] V) (g : V →ₗ[A] W) (eU : U ≃ₗ[A] U') (eV : V ≃ₗ[A] V')
    (eW : W ≃ₗ[A] W') (h : LinearMap.ker g = LinearMap.range f) :
    LinearMap.ker (eW.toLinearMap ∘ₗ g ∘ₗ eV.symm.toLinearMap) =
      LinearMap.range (eV.toLinearMap ∘ₗ f ∘ₗ eU.symm.toLinearMap) := by
  ext x
  simp only [LinearMap.mem_ker, LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply,
    LinearMap.mem_range, LinearEquiv.map_eq_zero_iff]
  constructor
  · intro hx
    have : eV.symm x ∈ LinearMap.ker g := hx
    rw [h] at this
    obtain ⟨y, hy⟩ := this
    exact ⟨eU y, by simp [hy]⟩
  · rintro ⟨y, hy⟩
    have : eV.symm x ∈ LinearMap.range f := ⟨eU.symm y, by rw [← hy]; simp⟩
    rw [← h] at this
    exact this

theorem ffr_of_complex2 {A : Type*} [CommRing A] {M : Type*} [AddCommGroup M] [Module A M]
    (m : ℕ) (r0 : ℕ) (r : ℕ → ℕ) (F0 : Type*) [AddCommGroup F0] [Module A F0]
    (F : ℕ → Type*) [∀ i, AddCommGroup (F i)] [∀ i, Module A (F i)]
    (e0 : F0 ≃ₗ[A] (Fin r0 → A)) (e : ∀ i, F i ≃ₗ[A] (Fin (r i) → A))
    (ε : F0 →ₗ[A] M) (d0 : F 0 →ₗ[A] F0) (d : ∀ i, F (i + 1) →ₗ[A] F i)
    (hr : ∀ i, m < i + 1 → r i = 0) (hε : Function.Surjective ε)
    (h0 : LinearMap.ker ε = LinearMap.range d0)
    (h1 : LinearMap.ker d0 = LinearMap.range (d 0))
    (hd : ∀ i, LinearMap.ker (d i) = LinearMap.range (d (i + 1))) : FFR A M m := by
  let ε' : (Fin r0 → A) →ₗ[A] M := ε ∘ₗ e0.symm.toLinearMap
  let d0' : (Fin (r 0) → A) →ₗ[A] (Fin r0 → A) :=
    e0.toLinearMap ∘ₗ d0 ∘ₗ (e 0).symm.toLinearMap
  let d' : ∀ i, (Fin (r (i + 1)) → A) →ₗ[A] (Fin (r i) → A) := fun i =>
    (e i).toLinearMap ∘ₗ d i ∘ₗ (e (i + 1)).symm.toLinearMap
  have h0' : LinearMap.ker ε' = LinearMap.range d0' := by
    have := ker_range_conj d0 ε (e 0) e0 (LinearEquiv.refl A M) h0
    simpa using this
  have h1' : LinearMap.ker d0' = LinearMap.range (d' 0) := ker_range_conj _ _ _ _ _ h1
  have hd' : ∀ i, LinearMap.ker (d' i) = LinearMap.range (d' (i + 1)) := fun i =>
    ker_range_conj _ _ _ _ _ (hd i)
  refine ⟨joinRank r0 r, ε', joinDiff d0' d', ?_, hε.comp e0.symm.surjective, h0', ?_⟩
  · intro i hi
    rcases i with _ | i
    · omega
    · exact hr i hi
  · intro i
    rcases i with _ | i
    · exact h1'
    · exact hd' i

theorem ffr_cone {A : Type*} [CommRing A] {X Y Z : Type*} [AddCommGroup X] [Module A X]
    [AddCommGroup Y] [Module A Y] [AddCommGroup Z] [Module A Z] (φ : X →ₗ[A] Y) (q : Y →ₗ[A] Z)
    (hφ : Function.Injective φ) (hq : Function.Surjective q)
    (hex : LinearMap.ker q = LinearMap.range φ) (m : ℕ) (hX : FFR A X m) (hY : FFR A Y m) :
    FFR A Z (m + 1) := by
  obtain ⟨rA, εA, dA, hrA, hεA, h0A, hdA⟩ := hX
  obtain ⟨rB, εB, dB, hrB, hεB, h0B, hdB⟩ := hY
  obtain ⟨α, hα0, hα⟩ := exists_comparison φ rA rB εA dA εB dB h0A hdA hεB h0B hdB
  have hα0' : ∀ x, εB (α 0 x) = φ (εA x) := fun x => LinearMap.congr_fun hα0 x
  have hα' : ∀ i x, dB i (α (i + 1) x) = α i (dA i x) := fun i x => LinearMap.congr_fun (hα i) x
  have hAA : ∀ i x, dA i (dA (i + 1) x) = 0 := fun i x => by
    rw [← LinearMap.mem_ker, hdA]; exact ⟨x, rfl⟩
  have hBB : ∀ i x, dB i (dB (i + 1) x) = 0 := fun i x => by
    rw [← LinearMap.mem_ker, hdB]; exact ⟨x, rfl⟩
  have hεBd : ∀ x, εB (dB 0 x) = 0 := fun x => by
    rw [← LinearMap.mem_ker, h0B]; exact ⟨x, rfl⟩
  let D0 : ((Fin (rB 1) → A) × (Fin (rA 0) → A)) →ₗ[A] (Fin (rB 0) → A) :=
    dB 0 ∘ₗ LinearMap.fst A _ _ + α 0 ∘ₗ LinearMap.snd A _ _
  have hD0 : ∀ g f, D0 (g, f) = dB 0 g + α 0 f := fun g f => rfl
  let D : ∀ i : ℕ, ((Fin (rB (i + 2)) → A) × (Fin (rA (i + 1)) → A)) →ₗ[A]
      ((Fin (rB (i + 1)) → A) × (Fin (rA i) → A)) := fun i =>
    (dB (i + 1) ∘ₗ LinearMap.fst A _ _ + α (i + 1) ∘ₗ LinearMap.snd A _ _).prod
      (-(dA i ∘ₗ LinearMap.snd A _ _))
  have hD : ∀ i g f, D i (g, f) = (dB (i + 1) g + α (i + 1) f, -(dA i f)) := fun i g f => rfl
  let eqv : ∀ i, ((Fin (rB (i + 1)) → A) × (Fin (rA i) → A)) ≃ₗ[A]
      (Fin (rB (i + 1) + rA i) → A) := fun i =>
    (LinearEquiv.sumArrowLequivProdArrow _ _ A A).symm ≪≫ₗ
      LinearEquiv.funCongrLeft A A finSumFinEquiv.symm
  refine ffr_of_complex2 (m + 1) (rB 0) (fun i => rB (i + 1) + rA i) (Fin (rB 0) → A)
    (fun i => (Fin (rB (i + 1)) → A) × (Fin (rA i) → A)) (LinearEquiv.refl A _) eqv
    (q ∘ₗ εB) D0 D ?_ ?_ ?_ ?_ ?_
  · intro i hi
    rw [hrB _ (by omega), hrA _ (by omega)]
  · intro z
    obtain ⟨y, rfl⟩ := hq z
    obtain ⟨x, rfl⟩ := hεB y
    exact ⟨x, rfl⟩
  · ext g
    simp only [LinearMap.mem_ker, LinearMap.coe_comp, Function.comp_apply, LinearMap.mem_range]
    constructor
    · intro h
      have : εB g ∈ LinearMap.range φ := by rw [← hex]; exact h
      obtain ⟨y, hy⟩ := this
      obtain ⟨f0, rfl⟩ := hεA y
      have : g - α 0 f0 ∈ LinearMap.ker εB := by
        rw [LinearMap.mem_ker, map_sub, hα0', hy, sub_self]
      rw [h0B] at this
      obtain ⟨g', hg'⟩ := this
      exact ⟨(g', f0), by rw [hD0, hg']; abel⟩
    · rintro ⟨⟨g', f0⟩, h⟩
      rw [hD0] at h
      rw [← h, map_add, hεBd, hα0', zero_add]
      have : φ (εA f0) ∈ LinearMap.range φ := ⟨_, rfl⟩
      rw [← hex] at this
      exact this
  · ext ⟨g, f⟩
    simp only [LinearMap.mem_ker, LinearMap.mem_range]
    constructor
    · intro h
      rw [hD0] at h
      have hf : εA f = 0 := by
        apply hφ
        rw [map_zero, ← hα0']
        have := congrArg εB h
        rw [map_add, hεBd, zero_add, map_zero] at this
        exact this
      have : f ∈ LinearMap.range (dA 0) := by rw [← h0A]; exact hf
      obtain ⟨f', rfl⟩ := this
      have : g + α 1 f' ∈ LinearMap.ker (dB 0) := by
        rw [LinearMap.mem_ker, map_add, hα', h]
      rw [hdB] at this
      obtain ⟨g', hg'⟩ := this
      refine ⟨(g', -f'), ?_⟩
      rw [hD, map_neg, hg', map_neg, neg_neg]
      simp
    · rintro ⟨⟨g', f'⟩, h⟩
      rw [← h, hD, hD0, map_add, hBB, hα', map_neg]
      abel
  · intro i
    ext ⟨g, f⟩
    simp only [LinearMap.mem_ker, LinearMap.mem_range]
    constructor
    · intro h
      rw [hD] at h
      have h1 : dB (i + 1) g + α (i + 1) f = 0 := congrArg Prod.fst h
      have h2 : dA i f = 0 := by
        have := congrArg Prod.snd h
        simpa using this
      have : f ∈ LinearMap.range (dA (i + 1)) := by rw [← hdA]; exact h2
      obtain ⟨f', rfl⟩ := this
      have : g + α (i + 2) f' ∈ LinearMap.ker (dB (i + 1)) := by
        rw [LinearMap.mem_ker, map_add, hα', h1]
      rw [hdB] at this
      obtain ⟨g', hg'⟩ := this
      refine ⟨(g', -f'), ?_⟩
      rw [hD, map_neg, hg', map_neg, neg_neg]
      simp
    · rintro ⟨⟨g', f'⟩, h⟩
      rw [← h, hD, hD, map_add, hBB, hα', map_neg, map_neg, hAA]
      simp

theorem ffr_baseChange {R : Type*} [CommRing R] (P : Type*) [CommRing P] [Algebra R P]
    [Module.Flat R P] {N : Type*} [AddCommGroup N] [Module R N] (m : ℕ) (h : FFR R N m) :
    FFR P (P ⊗[R] N) m := by
  obtain ⟨r, ε, d, hr, hε, h0, hd⟩ := h
  refine ffr_of_complex m r (fun i => P ⊗[R] (Fin (r i) → R))
    (fun i => TensorProduct.piScalarRight R P P (Fin (r i))) (ε.baseChange P)
    (fun i => (d i).baseChange P) hr (LinearMap.lTensor_surjective P hε) ?_ ?_
  · have hx : Function.Exact (d 0) ε := LinearMap.exact_iff.mpr h0
    exact LinearMap.exact_iff.mp (Module.Flat.lTensor_exact P hx)
  · intro i
    have hx : Function.Exact (d (i + 1)) (d i) := LinearMap.exact_iff.mpr (hd i)
    exact LinearMap.exact_iff.mp (Module.Flat.lTensor_exact P hx)

end SyzygyProof

namespace SyzygyProof

open Polynomial TensorProduct

theorem char_seq (R : Type*) [CommRing R] [IsNoetherianRing R] (M : Type*) [AddCommGroup M]
    [Module R[X] M] [Module R M] [IsScalarTower R R[X] M] [Module.Finite R[X] M] :
    ∃ (N₀ N₁ : Submodule R M) (ψ : R[X] ⊗[R] N₀ →ₗ[R[X]] R[X] ⊗[R] N₁)
      (π : R[X] ⊗[R] N₁ →ₗ[R[X]] M), N₀.FG ∧ N₁.FG ∧ Function.Injective ψ ∧
      Function.Surjective π ∧ LinearMap.ker π = LinearMap.range ψ := by
  obtain ⟨s, Γ, hΓ⟩ := Module.Finite.exists_fin' R[X] M
  set g : Fin s → M := fun j => Γ (Pi.single j 1) with hgdef
  have hΓsum : ∀ a, Γ a = ∑ j, a j • g j := by
    intro a
    have : a = ∑ j, a j • (Pi.single j 1 : Fin s → R[X]) := by
      funext i; simp [Finset.sum_apply, Pi.single_apply]
    conv_lhs => rw [this]
    simp [map_sum, map_smul, g]
  have hK : (LinearMap.ker Γ).FG := IsNoetherian.noetherian _
  obtain ⟨G, hG⟩ := hK
  set D : ℕ := (G.sup fun ρ => Finset.univ.sup fun j => (ρ j).natDegree) + 1 with hD
  have hdeg : ∀ ρ ∈ G, ∀ j, (ρ j).natDegree < D := by
    intro ρ hρ j
    have h1 : (ρ j).natDegree ≤ Finset.univ.sup fun j => (ρ j).natDegree :=
      Finset.le_sup (f := fun j => (ρ j).natDegree) (Finset.mem_univ j)
    have h2 := Finset.le_sup (f := fun ρ : Fin s → R[X] => Finset.univ.sup fun j => (ρ j).natDegree) hρ
    omega
  let gens : ℕ → Set M := fun b => Set.range (fun p : Fin s × Fin b => (Polynomial.X : R[X]) ^ (p.2 : ℕ) • g p.1)
  have hmem : ∀ b j (l : ℕ), l < b → (Polynomial.X : R[X]) ^ l • g j ∈ Submodule.span R (gens b) :=
    fun b j l hl => Submodule.subset_span ⟨(j, ⟨l, hl⟩), rfl⟩
  set N₀ := Submodule.span R (gens D) with hN₀
  set N₁ := Submodule.span R (gens (D + 1)) with hN₁
  have hle : N₀ ≤ N₁ := by
    apply Submodule.span_mono
    rintro _ ⟨⟨j, l⟩, rfl⟩
    exact ⟨(j, ⟨l, by omega⟩), rfl⟩
  have hg : ∀ j, g j ∈ N₁ := fun j => by
    simpa using hmem (D + 1) j 0 (by omega)
  have hXmem : ∀ x ∈ N₀, (Polynomial.X : R[X]) • x ∈ N₁ := by
    intro x hx
    induction hx using Submodule.span_induction with
    | mem y hy =>
      obtain ⟨⟨j, l⟩, rfl⟩ := hy
      simp only
      rw [smul_smul, ← pow_succ']
      exact hmem (D + 1) j (l + 1) (by omega)
    | zero => simp
    | add y z _ _ hy hz => rw [smul_add]; exact add_mem hy hz
    | smul r y _ hy => rw [smul_comm]; exact Submodule.smul_mem _ _ hy
  let ι : N₀ →ₗ[R] N₁ := Submodule.inclusion hle
  let τ : N₀ →ₗ[R] N₁ :=
    { toFun := fun x => ⟨(Polynomial.X : R[X]) • (x : M), hXmem x x.2⟩
      map_add' := fun x y => by ext; simp [smul_add]
      map_smul' := fun r x => by ext; exact smul_comm (Polynomial.X : R[X]) r (x : M) }
  let ψ : R[X] ⊗[R] N₀ →ₗ[R[X]] R[X] ⊗[R] N₁ :=
    (Polynomial.X : R[X]) • ι.baseChange R[X] - τ.baseChange R[X]
  have hψ : ∀ (f : R[X]) (x : N₀), ψ (f ⊗ₜ x) = (Polynomial.X * f) ⊗ₜ ι x - f ⊗ₜ τ x := by
    intro f x
    simp [ψ, smul_tmul', smul_eq_mul]
  let π : R[X] ⊗[R] N₁ →ₗ[R[X]] M := N₁.subtype.liftBaseChange R[X]
  have hπ : ∀ (f : R[X]) (y : N₁), π (f ⊗ₜ y) = f • (y : M) := fun f y => rfl
  let Φ : (Fin s → R[X]) →ₗ[R[X]] R[X] ⊗[R] N₁ :=
    ∑ j, (LinearMap.proj j : (Fin s → R[X]) →ₗ[R[X]] R[X]).smulRight
      ((1 : R[X]) ⊗ₜ[R] (⟨g j, hg j⟩ : N₁))
  have hΦ : ∀ a, Φ a = ∑ j, a j ⊗ₜ (⟨g j, hg j⟩ : N₁) := by
    intro a
    simp [Φ, smul_tmul']
  have hΦsingle : ∀ j c, Φ (Pi.single j c) = c ⊗ₜ (⟨g j, hg j⟩ : N₁) := by
    intro j c
    rw [hΦ, Finset.sum_eq_single j]
    · simp
    · intro b _ hb; simp [hb]
    · simp
  have hπΦ : ∀ a, π (Φ a) = Γ a := by
    intro a
    rw [hΦ, map_sum, hΓsum]
    rfl
  set W := LinearMap.range ψ with hW
  have hπψ : ∀ z, π (ψ z) = 0 := by
    intro z
    induction z using TensorProduct.inductionOn with
    | tmul f x =>
      rw [hψ, map_sub, hπ, hπ]
      simp only [ι, τ, Submodule.coe_inclusion, LinearMap.coe_mk, AddHom.coe_mk]
      rw [mul_smul, smul_comm (Polynomial.X : R[X]) f, sub_self]
    | add x y hx hy => rw [map_add, map_add, hx, hy, add_zero]
  have shift : ∀ (f : R[X]) (x : N₀), f ⊗ₜ τ x - (Polynomial.X * f) ⊗ₜ ι x ∈ W := by
    intro f x
    exact ⟨-(f ⊗ₜ x), by rw [map_neg, hψ, neg_sub]⟩
  have iter : ∀ j (l : ℕ) (hl : l ≤ D) (f : R[X]),
      f ⊗ₜ (⟨(Polynomial.X : R[X]) ^ l • g j, hmem (D + 1) j l (by omega)⟩ : N₁) -
        (Polynomial.X ^ l * f) ⊗ₜ (⟨g j, hg j⟩ : N₁) ∈ W := by
    intro j l
    induction l with
    | zero =>
      intro _ f
      have : (⟨(Polynomial.X : R[X]) ^ 0 • g j, hmem (D + 1) j 0 (by omega)⟩ : N₁) = ⟨g j, hg j⟩ :=
        Subtype.ext (by simp)
      rw [this, pow_zero, one_mul, sub_self]
      exact zero_mem _
    | succ l ih =>
      intro hl f
      let x : N₀ := ⟨(Polynomial.X : R[X]) ^ l • g j, hmem D j l (by omega)⟩
      have e1 : τ x = ⟨(Polynomial.X : R[X]) ^ (l + 1) • g j, hmem (D + 1) j (l + 1) (by omega)⟩ :=
        Subtype.ext (by simp [τ, x, smul_smul, pow_succ'])
      have e2 : ι x = ⟨(Polynomial.X : R[X]) ^ l • g j, hmem (D + 1) j l (by omega)⟩ := rfl
      have := add_mem (shift f x) (ih (by omega) (Polynomial.X * f))
      rw [e1, e2] at this
      have hp : (Polynomial.X : R[X]) ^ (l + 1) * f = Polynomial.X ^ l * (Polynomial.X * f) := by ring
      rw [hp]
      convert this using 1
      abel
  have key : ∀ (y : M) (hy : y ∈ N₁) (f : R[X]), ∃ a, f ⊗ₜ (⟨y, hy⟩ : N₁) - Φ a ∈ W := by
    intro y hy
    induction hy using Submodule.span_induction with
    | mem x hx =>
      obtain ⟨⟨j, l⟩, rfl⟩ := hx
      intro f
      refine ⟨Pi.single j ((Polynomial.X : R[X]) ^ (l : ℕ) * f), ?_⟩
      rw [hΦsingle]
      exact iter j l (by omega) f
    | zero =>
      intro f
      refine ⟨0, ?_⟩
      have : (⟨0, zero_mem _⟩ : N₁) = 0 := rfl
      rw [this, tmul_zero, map_zero, sub_zero]
      exact zero_mem _
    | add x y hx hy ihx ihy =>
      intro f
      obtain ⟨a, ha⟩ := ihx f
      obtain ⟨b, hb⟩ := ihy f
      refine ⟨a + b, ?_⟩
      have : (⟨x + y, add_mem hx hy⟩ : N₁) = ⟨x, hx⟩ + ⟨y, hy⟩ := rfl
      rw [this, tmul_add, map_add]
      convert add_mem ha hb using 1
      abel
    | smul r x hx ih =>
      intro f
      obtain ⟨a, ha⟩ := ih (r • f)
      refine ⟨a, ?_⟩
      have : (⟨r • x, Submodule.smul_mem _ r hx⟩ : N₁) = r • ⟨x, hx⟩ := rfl
      rw [this, ← smul_tmul]
      exact ha
  have reduce : ∀ z : R[X] ⊗[R] N₁, ∃ a, z - Φ a ∈ W := by
    intro z
    induction z using TensorProduct.inductionOn with
    | tmul f y => exact key y.1 y.2 f
    | add x y hx hy =>
      obtain ⟨a, ha⟩ := hx
      obtain ⟨b, hb⟩ := hy
      refine ⟨a + b, ?_⟩
      convert add_mem ha hb using 1
      rw [map_add]
      abel
  have hpoly : ∀ j (p : R[X]), p.natDegree < D + 1 →
      ∃ y : N₁, (y : M) = p • g j ∧ p ⊗ₜ (⟨g j, hg j⟩ : N₁) - (1 : R[X]) ⊗ₜ y ∈ W := by
    intro j p hp
    rw [p.as_sum_range' (D + 1) hp]
    apply Finset.sum_induction _
      (fun q : R[X] => ∃ y : N₁, (y : M) = q • g j ∧
        q ⊗ₜ (⟨g j, hg j⟩ : N₁) - (1 : R[X]) ⊗ₜ y ∈ W)
    · rintro a b ⟨ya, hya1, hya2⟩ ⟨yb, hyb1, hyb2⟩
      refine ⟨ya + yb, ?_, ?_⟩
      · simp [hya1, hyb1, add_smul]
      · rw [add_tmul, tmul_add]
        convert add_mem hya2 hyb2 using 1
        abel
    · exact ⟨0, by simp, by simp⟩
    · intro l hl
      rw [Finset.mem_range] at hl
      set c := p.coeff l
      refine ⟨c • ⟨(Polynomial.X : R[X]) ^ l • g j, hmem (D + 1) j l hl⟩, ?_, ?_⟩
      · simp only [SetLike.val_smul]
        rw [← Polynomial.C_mul_X_pow_eq_monomial, mul_smul, ← algebraMap_smul (A := R[X]) c]
        rfl
      · have h1 := iter j l (by omega) 1
        have h2 : -(c • ((1 : R[X]) ⊗ₜ (⟨(Polynomial.X : R[X]) ^ l • g j, hmem (D + 1) j l hl⟩ : N₁) -
            ((Polynomial.X : R[X]) ^ l * 1) ⊗ₜ (⟨g j, hg j⟩ : N₁))) ∈ W :=
          neg_mem (Submodule.smul_of_tower_mem W c h1)
        convert h2 using 1
        rw [smul_sub, neg_sub, tmul_smul, mul_one, smul_tmul', ← Polynomial.C_mul_X_pow_eq_monomial,
          ← Polynomial.smul_eq_C_mul]
        simp only [smul_tmul']
  have hΦρ : ∀ ρ ∈ G, Φ ρ ∈ W := by
    intro ρ hρ
    have hρK : ρ ∈ LinearMap.ker Γ := by rw [← hG]; exact Submodule.subset_span hρ
    choose y hy1 hy2 using fun j => hpoly j (ρ j) (by have := hdeg ρ hρ j; omega)
    have hsum : ∑ j, y j = 0 := by
      apply Subtype.ext
      rw [Submodule.coe_sum]
      simp only [hy1]
      rw [← hΓsum]
      exact hρK
    have : Φ ρ = ∑ j, (ρ j ⊗ₜ (⟨g j, hg j⟩ : N₁) - (1 : R[X]) ⊗ₜ y j) +
        (1 : R[X]) ⊗ₜ (∑ j, y j) := by
      rw [hΦ, tmul_sum, ← Finset.sum_add_distrib]
      simp
    rw [this, hsum, tmul_zero, add_zero]
    exact Submodule.sum_mem _ fun j _ => hy2 j
  have hKW : LinearMap.ker Γ ≤ W.comap Φ := by
    rw [← hG, Submodule.span_le]
    intro ρ hρ
    exact hΦρ ρ hρ
  -- injectivity of ψ
  have hinj : Function.Injective ψ := by
    let b := Polynomial.basisMonomials R
    let E₀ := TensorProduct.equivFinsuppOfBasisLeft b (N := N₀)
    let E₁ := TensorProduct.equivFinsuppOfBasisLeft b (N := N₁)
    let L : (ℕ →₀ N₀) →ₗ[R] (ℕ →₀ N₁) :=
      Finsupp.lmapDomain N₁ R (· + 1) ∘ₗ Finsupp.mapRange.linearMap ι -
        Finsupp.mapRange.linearMap τ
    have hcomm : E₁.toLinearMap ∘ₗ (ψ.restrictScalars R) ∘ₗ E₀.symm.toLinearMap = L := by
      apply Finsupp.lhom_ext
      intro i x
      have hb : ∀ k, b k = (Polynomial.X : R[X]) ^ k := fun k => by
        simp [b, Polynomial.coe_basisMonomials, Polynomial.X_pow_eq_monomial]
      have hE : ∀ k (y : N₁), E₁ (((Polynomial.X : R[X]) ^ k) ⊗ₜ y) = Finsupp.single k y := by
        intro k y
        rw [← hb, TensorProduct.equivFinsuppOfBasisLeft_apply_tmul, b.repr_self]
        simp
      have hE0 : E₀.symm (Finsupp.single i x) = ((Polynomial.X : R[X]) ^ i) ⊗ₜ x := by
        simp [E₀, hb]
      simp only [LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply,
        LinearMap.coe_restrictScalars]
      rw [hE0, hψ, map_sub, ← pow_succ', hE, hE]
      simp [L]
    have hL : Function.Injective L := by
      rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
      intro u hu
      by_contra hne
      have hsupp : u.support.Nonempty := Finsupp.support_nonempty_iff.mpr hne
      set e := u.support.max' hsupp
      have he : u e ≠ 0 := Finsupp.mem_support_iff.mp (u.support.max'_mem hsupp)
      have he1 : u (e + 1) = 0 := by
        by_contra h
        have := u.support.le_max' (e + 1) (Finsupp.mem_support_iff.mpr h)
        omega
      have := DFunLike.congr_fun hu (e + 1)
      simp only [L, LinearMap.sub_apply, LinearMap.coe_comp, Function.comp_apply,
        Finsupp.lmapDomain_apply, Finsupp.mapRange.linearMap_apply, Finsupp.coe_sub,
        Pi.sub_apply, Finsupp.coe_zero, Pi.zero_apply] at this
      rw [Finsupp.mapDomain_apply_of_injective (f := fun x : ℕ => x + 1)
          (fun a b h => by simpa using h),
        Finsupp.mapRange_apply,
        Finsupp.mapRange_apply, he1, map_zero, sub_zero] at this
      exact he (Submodule.inclusion_injective hle (by rw [this, map_zero]))
    intro z1 z2 h
    apply E₀.injective
    apply hL
    have h1 := LinearMap.congr_fun hcomm (E₀ z1)
    have h2 := LinearMap.congr_fun hcomm (E₀ z2)
    simp only [LinearMap.coe_comp, LinearEquiv.coe_coe, Function.comp_apply,
      LinearEquiv.symm_apply_apply, LinearMap.coe_restrictScalars] at h1 h2
    rw [← h1, ← h2, h]
  refine ⟨N₀, N₁, ψ, π, Submodule.fg_span (Set.finite_range _),
    Submodule.fg_span (Set.finite_range _), hinj, ?_, ?_⟩
  · intro y
    obtain ⟨a, rfl⟩ := hΓ y
    exact ⟨Φ a, hπΦ a⟩
  · ext z
    constructor
    · intro hz
      rw [LinearMap.mem_ker] at hz
      obtain ⟨a, ha⟩ := reduce z
      have h1 : π (z - Φ a) = 0 := by
        obtain ⟨w, hw⟩ := ha
        rw [← hw, hπψ]
      have h2 : Γ a = 0 := by
        rw [← hπΦ]
        rw [map_sub, hz, zero_sub, neg_eq_zero] at h1
        exact h1
      have h3 : Φ a ∈ W := hKW h2
      have : z = (z - Φ a) + Φ a := by abel
      rw [this]
      exact add_mem ha h3
    · rintro ⟨w, rfl⟩
      exact hπψ w

end SyzygyProof

namespace SyzygyProof

open Polynomial TensorProduct

theorem ffr_poly_step (R : Type u) [CommRing R] [IsNoetherianRing R] (m : ℕ)
    (IH : ∀ (N : Type v) [AddCommGroup N] [Module R N] [Module.Finite R N], FFR R N m)
    (M : Type v) [AddCommGroup M] [Module R[X] M] [Module.Finite R[X] M] :
    FFR R[X] M (m + 1) := by
  let _ : Module R M := Module.compHom M (algebraMap R R[X])
  have : IsScalarTower R R[X] M := ⟨fun r p x => by
    show (r • p) • x = algebraMap R R[X] r • (p • x)
    rw [Algebra.smul_def, mul_smul]⟩
  obtain ⟨N₀, N₁, ψ, π, h0, h1, hψ, hπ, hex⟩ := char_seq R M
  have := Module.Finite.iff_fg.mpr h0
  have := Module.Finite.iff_fg.mpr h1
  exact ffr_cone ψ π hψ hπ hex m (ffr_baseChange R[X] m (IH N₀)) (ffr_baseChange R[X] m (IH N₁))

theorem ffr_mvPolynomial (k : Type u) [Field k] (n : ℕ) :
    ∀ (M : Type v) [AddCommGroup M] [Module (MvPolynomial (Fin n) k) M]
      [Module.Finite (MvPolynomial (Fin n) k) M], FFR (MvPolynomial (Fin n) k) M n := by
  induction n with
  | zero =>
    intro M _ _ _
    let e : k ≃+* MvPolynomial (Fin 0) k :=
      (MvPolynomial.isEmptyAlgEquiv k (Fin 0)).symm.toRingEquiv
    let _ : Module k M := Module.compHom M e.toRingHom
    have he : ∀ (a : k) (x : M), a • x = e a • x := fun _ _ => rfl
    have := finite_ring_transfer e he
    exact ffr_ring_transfer e he 0 (ffr_field k M)
  | succ n ih =>
    intro M _ _ _
    let e : (MvPolynomial (Fin n) k)[X] ≃+* MvPolynomial (Fin (n + 1)) k :=
      (MvPolynomial.finSuccEquiv k n).symm.toRingEquiv
    let _ : Module (MvPolynomial (Fin n) k)[X] M := Module.compHom M e.toRingHom
    have he : ∀ (a : (MvPolynomial (Fin n) k)[X]) (x : M), a • x = e a • x := fun _ _ => rfl
    have := finite_ring_transfer e he
    exact ffr_ring_transfer e he (n + 1) (ffr_poly_step _ n ih M)

end SyzygyProof

namespace SyzygyProof

theorem choose_two_int (n : ℕ) : (Nat.choose n 2 : ℤ) * 2 = n * (n - 1) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Nat.choose_succ_succ', Nat.choose_one_right]; push_cast; linear_combination ih

theorem choose_three_int (n : ℕ) : (Nat.choose n 3 : ℤ) * 6 = n * (n - 1) * (n - 2) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Nat.choose_succ_succ']; push_cast; linear_combination ih + 3 * choose_two_int n

end SyzygyProof

namespace SyzygyProof

#print axioms ffr_of_complex
#print axioms ffr_ring_transfer
#print axioms finite_ring_transfer
#print axioms ffr_field
#print axioms exists_lift
#print axioms exists_comparison
#print axioms ker_range_conj
#print axioms ffr_of_complex2
#print axioms ffr_cone
#print axioms ffr_baseChange
#print axioms char_seq
#print axioms ffr_poly_step
#print axioms ffr_mvPolynomial
#print axioms choose_two_int
#print axioms choose_three_int

end SyzygyProof

/-- Hilbert's syzygy theorem. Let k be a field and S = k[x_1, ..., x_n] the polynomial ring in
n variables. Every finitely generated S-module M has a free resolution of length at most n:
there are free modules F_i = S^(r_i) of finite rank, with F_i = 0 for every i > n, and maps
ε : F_0 → M and d_i : F_(i+1) → F_i such that ε is onto, the kernel of ε is the image of d_0,
and the kernel of each d_i is the image of d_(i+1). Since F_(n+1) = 0, the map d_(n-1) is
one-to-one, so the chain 0 → F_n → ... → F_1 → F_0 → M → 0 is exact. -/
theorem hilbert_syzygy_theorem (k : Type u) [Field k] (n : ℕ)
    (M : Type v) [AddCommGroup M] [Module (MvPolynomial (Fin n) k) M]
    [Module.Finite (MvPolynomial (Fin n) k) M] :
    ∃ (r : ℕ → ℕ)
      (ε : (Fin (r 0) → MvPolynomial (Fin n) k) →ₗ[MvPolynomial (Fin n) k] M)
      (d : ∀ i : ℕ, (Fin (r (i + 1)) → MvPolynomial (Fin n) k) →ₗ[MvPolynomial (Fin n) k]
        (Fin (r i) → MvPolynomial (Fin n) k)),
      (∀ i, n < i → r i = 0) ∧
      Function.Surjective ε ∧
      LinearMap.ker ε = LinearMap.range (d 0) ∧
      ∀ i, LinearMap.ker (d i) = LinearMap.range (d (i + 1)) := by
  exact SyzygyProof.ffr_mvPolynomial k n M

/-- The twisted cubic's syzygies. In S = k[x, y, z, w] (variables X 0, X 1, X 2, X 3), with
f_1 = xz - y², f_2 = xw - yz, f_3 = yw - z², the row (f_1, f_2, f_3) times the matrix with
columns (w, -z, y) and (z, -y, x) is zero: w f_1 - z f_2 + y f_3 = 0 and
z f_1 - y f_2 + x f_3 = 0. Schreyer's third syzygy (yw - z², 0, y² - xz) is y times the first
column minus z times the second, so it is not needed. -/
theorem twisted_cubic_syzygies (k : Type u) [Field k] :
    let x : MvPolynomial (Fin 4) k := X 0
    let y : MvPolynomial (Fin 4) k := X 1
    let z : MvPolynomial (Fin 4) k := X 2
    let w : MvPolynomial (Fin 4) k := X 3
    (!![x * z - y ^ 2, x * w - y * z, y * w - z ^ 2] * !![w, z; -z, -y; y, x] = 0) ∧
    (![y * w - z ^ 2, 0, y ^ 2 - x * z] = y • ![w, -z, y] - z • ![z, -y, x]) := by
  intro x y z w
  constructor
  · refine Matrix.ext fun i j => ?_
    fin_cases i; fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_succ] <;> ring
  · funext i
    fin_cases i <;> simp <;> ring

/-- The twisted cubic's Hilbert function, read off its resolution
0 → S(-3)² → S(-2)³ → S → S/I → 0: for every degree t,
C(t + 3, 3) - 3 C(t + 1, 3) + 2 C(t, 3) = 3t + 1. -/
theorem twisted_cubic_hilbert_function (t : ℕ) :
    (Nat.choose (t + 3) 3 : ℤ) - 3 * Nat.choose (t + 1) 3 + 2 * Nat.choose t 3 = 3 * t + 1 := by
  have h1 := SyzygyProof.choose_three_int (t + 3)
  have h2 := SyzygyProof.choose_three_int (t + 1)
  have h3 := SyzygyProof.choose_three_int t
  push_cast at h1 h2 h3
  have h6 : (6 : ℤ) ≠ 0 := by norm_num
  apply mul_left_cancel₀ h6
  linear_combination h1 - 3 * h2 + 2 * h3

-- The Hilbert function gives 4, 7 and 10 in degrees 1, 2 and 3.
example : (Nat.choose 4 3 : ℤ) - 3 * Nat.choose 2 3 + 2 * Nat.choose 1 3 = 4 ∧
    (Nat.choose 5 3 : ℤ) - 3 * Nat.choose 3 3 + 2 * Nat.choose 2 3 = 7 ∧
    (Nat.choose 6 3 : ℤ) - 3 * Nat.choose 4 3 + 2 * Nat.choose 3 3 = 10 := by decide
-- HF(t) for t = 0..6, from the resolution: 1, 4, 7, 10, 13, 16, 19.
example : (List.range 7).map (fun t => (Nat.choose (t + 3) 3 : ℤ) - 3 * Nat.choose (t + 1) 3
    + 2 * Nat.choose t 3) = [1, 4, 7, 10, 13, 16, 19] := by decide
-- The chart: all monomials, first-step multiples 3C(t+1,3), relations 2C(t,3), t = 0..6.
example : (List.range 7).map (fun t => Nat.choose (t + 3) 3) = [1, 4, 10, 20, 35, 56, 84] ∧
    (List.range 7).map (fun t => 3 * Nat.choose (t + 1) 3) = [0, 0, 3, 12, 30, 60, 105] ∧
    (List.range 7).map (fun t => 2 * Nat.choose t 3) = [0, 0, 0, 2, 8, 20, 40] := by decide
-- Relations among the multiples in degrees d = 2..6: 2C(d,3) = 0, 2, 8, 20, 40.
example : (List.range' 2 5).map (fun d => 2 * Nat.choose d 3) = [0, 2, 8, 20, 40] := by decide
-- At t = 3 by hand: 20 cubic monomials, 3 × 4 = 12 multiples, 2 relations, 10 left.
example : Nat.choose 6 3 = 20 ∧ 3 * 4 = 12 ∧ 20 - 12 + 2 = 10 := by decide
-- At the point (1, 2, 3, 4): f = (-1, -2, -1), and both syzygies give 0.
example : ((1 : ℤ) * 3 - 2 ^ 2, (1 : ℤ) * 4 - 2 * 3, (2 : ℤ) * 4 - 3 ^ 2) = (-1, -2, -1) ∧
    (4 : ℤ) * (-1) - 3 * (-2) + 2 * (-1) = 0 ∧ (3 : ℤ) * (-1) - 2 * (-2) + 1 * (-1) = 0 := by
  norm_num
-- The field k = S/m needs all n = 4 steps: Koszul Betti numbers 1, 4, 6, 4, 1.
example : (List.range 5).map (fun i => Nat.choose 4 i) = [1, 4, 6, 4, 1] := by decide
-- Break: shifts dropped gives (1 - 3 + 2) × 20 = 0 at t = 3, not 10.
example : ((1 - 3 + 2) * 20 : ℤ) = 0 := by norm_num
-- Break: syzygies ignored (1, 3) gives HF(3) = 20 - 12 = 8 and HF(6) = 84 - 105 = -21.
example : (Nat.choose 6 3 : ℤ) - 3 * Nat.choose 4 3 = 8 ∧
    (Nat.choose 9 3 : ℤ) - 3 * Nat.choose 7 3 = -21 := by decide
-- Break: trivial syzygies only (1, 3, 3, 1) gives HF(3) = 8 and HF(6) = 8.
example : (Nat.choose 6 3 : ℤ) - 3 * Nat.choose 4 3 + 3 * Nat.choose 2 3 - Nat.choose 0 3 = 8 ∧
    (Nat.choose 9 3 : ℤ) - 3 * Nat.choose 7 3 + 3 * Nat.choose 5 3 - Nat.choose 3 3 = 8 := by
  decide
-- Break: Schreyer's three syzygies kept (shifts 3, 3, 4) gives HF(4) = 35 - 30 + 9 = 14, not 13.
example : (Nat.choose 7 3 : ℤ) - 3 * Nat.choose 5 3 + (2 * Nat.choose 4 3 + Nat.choose 3 3) = 14 := by
  decide
-- Break: f_3 dropped, resolution 1, 2, 1 (shifts 0; 2, 2; 4) gives HF(1..4) = 4, 8, 12, 16.
example : (List.range' 1 4).map (fun t => (Nat.choose (t + 3) 3 : ℤ) - 2 * Nat.choose (t + 1) 3
    + Nat.choose (t - 1) 3) = [4, 8, 12, 16] := by decide
-- Break: Z/2 over the ring Z/4: the kernel and the image of doubling are both {0, 2}.
example : (Finset.univ.filter (fun a : ZMod 4 => 2 * a = 0)) = {0, 2} ∧
    Finset.univ.image (fun a : ZMod 4 => 2 * a) = {0, 2} := by decide

#print axioms hilbert_syzygy_theorem
#print axioms twisted_cubic_syzygies
#print axioms twisted_cubic_hilbert_function
