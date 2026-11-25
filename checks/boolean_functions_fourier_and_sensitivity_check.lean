-- Boolean functions: every yes-or-no rule on n votes has sensitivity at least the square root of its Fourier degree (Huang's theorem), with the signed cube matrix and the crowded-corner bound behind it.
import Mathlib
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Powerset
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Finset

namespace BooleanSensitivity

variable {n : ℕ}

/-- A vote pattern is a corner of the cube: `x i = true` means voter `i` says yes (`+1`),
`false` means no (`-1`). `flip x i` is `x^(i)`, the pattern with vote `i` changed. -/
def flip (x : Fin n → Bool) (i : Fin n) : Fin n → Bool :=
  Function.update x i (!x i)

/-- A yes-or-no value read as a number: `+1` for yes, `-1` for no. -/
def pm (b : Bool) : ℚ := if b then 1 else -1

/-- The Fourier coefficient `f̂(S)`: the average over all `2^n` patterns of
`f(x) · χ_S(x)`, where `χ_S(x)` is the product of the votes in `S`. -/
def fourierCoeff (f : (Fin n → Bool) → Bool) (S : Finset (Fin n)) : ℚ :=
  (∑ x : Fin n → Bool, pm (f x) * ∏ i ∈ S, pm (x i)) / 2 ^ n

/-- The degree `deg(f)`: the size of the largest set `S` with `f̂(S) ≠ 0`. -/
def degree (f : (Fin n → Bool) → Bool) : ℕ :=
  (univ.filter fun S : Finset (Fin n) => fourierCoeff f S ≠ 0).sup Finset.card

/-- The sensitivity `s(f, x)` at a pattern: the number of voters `i` with `f(x^(i)) ≠ f(x)`. -/
def sensitivityAt (f : (Fin n → Bool) → Bool) (x : Fin n → Bool) : ℕ :=
  (univ.filter fun i : Fin n => f (flip x i) ≠ f x).card

/-- The sensitivity `s(f)`: the largest `s(f, x)` over all patterns `x`. -/
def sensitivity (f : (Fin n → Bool) → Bool) : ℕ :=
  univ.sup (sensitivityAt f)

/-- The influence `Inf_i(f)`: the share of all patterns at which changing vote `i` alone
changes the answer. -/
def influence (f : (Fin n → Bool) → Bool) (i : Fin n) : ℚ :=
  ((univ.filter fun x : Fin n → Bool => f (flip x i) ≠ f x).card : ℚ) / 2 ^ n

/-- Huang's signed cube matrix `A_n`, indexed by corners. The entry for two patterns one vote
apart (vote `i` changed) is `-1` when an odd number of the voters numbered after `i` say yes,
and `+1` otherwise; every other entry is `0`. This is the matrix built by the recursion
`A_1 = [[0, 1], [1, 0]]`, `A_n = [[A_{n-1}, I], [I, -A_{n-1}]]`. -/
def huangMatrix (n : ℕ) : Matrix (Fin n → Bool) (Fin n → Bool) ℤ := fun x y =>
  ∑ i : Fin n, if y = flip x i then
    (-1) ^ (univ.filter fun j : Fin n => i < j ∧ x j = true).card else 0

/-- The number of corners next to `x` (one vote apart) that lie in the set `H`. -/
def chosenNeighbours (H : Finset (Fin n → Bool)) (x : Fin n → Bool) : ℕ :=
  (univ.filter fun i : Fin n => flip x i ∈ H).card

section General

open Matrix

set_option linter.unusedSectionVars false
set_option linter.unusedSimpArgs false

variable {ι : Type*} [Fintype ι] [LinearOrder ι]

def gflip (x : ι → Bool) (i : ι) : ι → Bool := Function.update x i (!x i)

lemma gflip_gflip (x : ι → Bool) (i : ι) : gflip (gflip x i) i = x := by
  funext j; by_cases h : j = i
  · subst h; simp [gflip]
  · simp [gflip, Function.update_of_ne h]

#print axioms gflip_gflip

lemma gflip_comm (x : ι → Bool) {i k : ι} (h : i ≠ k) :
    gflip (gflip x i) k = gflip (gflip x k) i := by
  funext j
  by_cases hj : j = i
  · subst hj; simp [gflip, Function.update_of_ne h, Function.update_of_ne (Ne.symm h)]
  · by_cases hk : j = k
    · subst hk; simp [gflip, Function.update_of_ne h, Function.update_of_ne (Ne.symm h)]
    · simp [gflip, Function.update_of_ne hj, Function.update_of_ne hk]

#print axioms gflip_comm

lemma filter_gflip_not (p : ι → Prop) [DecidablePred p] (x : ι → Bool) {k : ι} (hk : ¬ p k) :
    (univ.filter fun j => p j ∧ gflip x k j = true) = univ.filter fun j => p j ∧ x j = true := by
  ext j
  simp only [mem_filter, mem_univ, true_and]
  by_cases hj : j = k
  · subst hj; simp [hk]
  · simp [gflip, Function.update_of_ne hj]

#print axioms filter_gflip_not

lemma sign_gflip_mem {R : Type*} [CommRing R] (p : ι → Prop) [DecidablePred p] (x : ι → Bool)
    {k : ι} (hk : p k) :
    ((-1 : R) ^ (univ.filter fun j => p j ∧ gflip x k j = true).card) =
      -(-1 : R) ^ (univ.filter fun j => p j ∧ x j = true).card := by
  cases hx : x k
  · have : (univ.filter fun j => p j ∧ gflip x k j = true) =
        insert k (univ.filter fun j => p j ∧ x j = true) := by
      ext j
      simp only [mem_filter, mem_univ, true_and, mem_insert]
      by_cases hj : j = k
      · subst hj; simp [gflip, hk, hx]
      · simp [gflip, Function.update_of_ne hj, hj]
    rw [this, card_insert_of_notMem (by simp [hx]), pow_succ]; ring
  · have : (univ.filter fun j => p j ∧ x j = true) =
        insert k (univ.filter fun j => p j ∧ gflip x k j = true) := by
      ext j
      simp only [mem_filter, mem_univ, true_and, mem_insert]
      by_cases hj : j = k
      · subst hj; simp [gflip, hk, hx]
      · simp [gflip, Function.update_of_ne hj, hj]
    rw [this, card_insert_of_notMem (by simp [gflip, hx]), pow_succ]; ring

#print axioms sign_gflip_mem

/-- The sign attached to the edge from `x` in direction `i`. -/
def csign (R : Type*) [CommRing R] (x : ι → Bool) (i : ι) : R :=
  (-1) ^ (univ.filter fun j : ι => i < j ∧ x j = true).card

lemma csign_sq {R : Type*} [CommRing R] (x : ι → Bool) (i : ι) :
    csign R x i * csign R x i = 1 := by
  unfold csign; rw [← mul_pow]; simp

#print axioms csign_sq

lemma csign_gflip_le {R : Type*} [CommRing R] (x : ι → Bool) {i k : ι} (h : i ≤ k) :
    csign R (gflip x i) k = csign R x k := by
  unfold csign; rw [filter_gflip_not (fun j => k < j) x (not_lt.2 h)]

#print axioms csign_gflip_le

lemma csign_gflip_lt {R : Type*} [CommRing R] (x : ι → Bool) {i k : ι} (h : i < k) :
    csign R (gflip x k) i = - csign R x i := by
  unfold csign; exact sign_gflip_mem (fun j => i < j) x h

#print axioms csign_gflip_lt

lemma double_sum {R : Type*} [CommRing R] (F : (ι → Bool) → R) (x : ι → Bool) :
    ∑ i, csign R x i * ∑ k, csign R (gflip x i) k * F (gflip (gflip x i) k) =
      (Fintype.card ι : R) * F x := by
  set G : ι → ι → R := fun i k => csign R x i * (csign R (gflip x i) k * F (gflip (gflip x i) k))
    with hG
  have hsplit : ∀ i k, G i k = (if i = k then G i k else 0) + (if i < k then G i k else 0) +
      (if k < i then G i k else 0) := by
    intro i k
    rcases lt_trichotomy i k with h | h | h
    · simp [h, h.ne, not_lt.2 h.le]
    · simp [h]
    · simp [h, h.ne', not_lt.2 h.le]
  have hpair : ∀ i k, i < k → G i k + G k i = 0 := by
    intro i k h
    simp only [hG, csign_gflip_le x h.le, csign_gflip_lt x h, gflip_comm x h.ne]
    ring
  have hdiag : ∀ i, G i i = F x := by
    intro i
    simp only [hG, csign_gflip_le x le_rfl, gflip_gflip]
    rw [← mul_assoc, csign_sq, one_mul]
  calc ∑ i, csign R x i * ∑ k, csign R (gflip x i) k * F (gflip (gflip x i) k)
      = ∑ i, ∑ k, G i k := by simp only [hG, Finset.mul_sum]
    _ = ∑ i, G i i + (∑ i, ∑ k, (if i < k then G i k else 0) +
          ∑ i, ∑ k, (if k < i then G i k else 0)) := by
        rw [← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
        refine Finset.sum_congr rfl fun i _ => ?_
        conv_lhs => rw [Finset.sum_congr rfl fun k _ => hsplit i k]
        rw [Finset.sum_add_distrib, Finset.sum_add_distrib, Finset.sum_ite_eq]
        simp [add_assoc]
    _ = ∑ i, G i i + ∑ i, ∑ k, (if i < k then G i k + G k i else 0) := by
        congr 1
        rw [Finset.sum_comm (f := fun i k => if k < i then G i k else 0),
          ← Finset.sum_add_distrib]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [← Finset.sum_add_distrib]
        refine Finset.sum_congr rfl fun k _ => ?_
        split_ifs <;> simp
    _ = (Fintype.card ι : R) * F x := by
        rw [Finset.sum_eq_zero (fun i _ => Finset.sum_eq_zero fun k _ => by
          split_ifs with h
          · exact hpair i k h
          · rfl)]
        simp [hdiag, Finset.card_univ]

#print axioms double_sum

/-- Huang's signed matrix on the cube with coordinates `ι`, over a ring `R`. -/
def hM (R : Type*) [CommRing R] (ι : Type*) [Fintype ι] [LinearOrder ι] :
    Matrix (ι → Bool) (ι → Bool) R := fun x y =>
  ∑ i : ι, if y = gflip x i then csign R x i else 0

lemma hM_mulVec {R : Type*} [CommRing R] (v : (ι → Bool) → R) (x : ι → Bool) :
    (hM R ι *ᵥ v) x = ∑ i, csign R x i * v (gflip x i) := by
  simp only [Matrix.mulVec, dotProduct, hM, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun i _ => ?_
  simp [ite_mul]

#print axioms hM_mulVec

lemma hM_mulVec_mulVec {R : Type*} [CommRing R] (v : (ι → Bool) → R) :
    hM R ι *ᵥ (hM R ι *ᵥ v) = (Fintype.card ι : R) • v := by
  funext x
  rw [hM_mulVec]
  simp only [hM_mulVec, Pi.smul_apply, smul_eq_mul]
  exact double_sum v x

#print axioms hM_mulVec_mulVec

lemma hM_sq (R : Type*) [CommRing R] :
    hM R ι * hM R ι = (Fintype.card ι : R) • (1 : Matrix _ _ R) := by
  ext x y
  have h1 := congrFun (hM_mulVec_mulVec (R := R) (ι := ι) (Pi.single y 1)) x
  rw [Matrix.mulVec_mulVec, Matrix.mulVec_single_one] at h1
  rw [show ((hM R ι * hM R ι) x y) = (hM R ι * hM R ι).col y x from rfl, h1]
  simp [Matrix.one_apply, Pi.single_apply, eq_comm]

#print axioms hM_sq

/-- The parity sign of a corner. -/
def dsign (x : ι → Bool) : ℝ := (-1) ^ (univ.filter fun j : ι => True ∧ x j = true).card

lemma dsign_gflip (x : ι → Bool) (i : ι) : dsign (gflip x i) = - dsign x := by
  unfold dsign; exact sign_gflip_mem (fun _ => True) x trivial

#print axioms dsign_gflip

lemma dsign_sq (x : ι → Bool) : dsign x * dsign x = 1 := by
  unfold dsign; rw [← mul_pow]; simp

#print axioms dsign_sq

/-- Extension by zero from `H` to the whole cube, as a linear map. -/
def extH (H : Finset (ι → Bool)) : (H → ℝ) →ₗ[ℝ] ((ι → Bool) → ℝ) where
  toFun u x := if h : x ∈ H then u ⟨x, h⟩ else 0
  map_add' u w := by funext x; simp only [Pi.add_apply]; split_ifs <;> simp
  map_smul' c u := by funext x; simp only [Pi.smul_apply, smul_eq_mul, RingHom.id_apply]; split_ifs <;> simp

/-- Multiplication by the parity sign, as a linear map. -/
def dmap : ((ι → Bool) → ℝ) →ₗ[ℝ] ((ι → Bool) → ℝ) where
  toFun v x := dsign x * v x
  map_add' u w := by funext x; simp [mul_add]
  map_smul' c u := by funext x; simp only [Pi.smul_apply, smul_eq_mul, RingHom.id_apply]; ring

lemma dmap_dmap (v : (ι → Bool) → ℝ) : dmap (dmap v) = v := by
  funext x; simp only [dmap, LinearMap.coe_mk, AddHom.coe_mk]
  rw [← mul_assoc, dsign_sq, one_mul]

#print axioms dmap_dmap

lemma hM_dmap (v : (ι → Bool) → ℝ) :
    hM ℝ ι *ᵥ dmap v = - dmap (hM ℝ ι *ᵥ v) := by
  funext x
  simp only [hM_mulVec, dmap, LinearMap.coe_mk, AddHom.coe_mk, Pi.neg_apply, dsign_gflip,
    Finset.mul_sum]
  rw [← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  ring

#print axioms hM_dmap

lemma crowded (H : Finset (ι → Bool)) (hH : 2 ^ (Fintype.card ι - 1) + 1 ≤ H.card) :
    ∃ x ∈ H, Real.sqrt (Fintype.card ι) ≤
      ((univ.filter fun i : ι => gflip x i ∈ H).card : ℝ) := by
  set n := Fintype.card ι with hn
  have hHle : H.card ≤ 2 ^ n := by
    have := Finset.card_le_univ H
    simpa [Fintype.card_fun, Fintype.card_bool] using this
  have hn1 : 1 ≤ n := by
    rcases Nat.eq_zero_or_pos n with h | h
    · rw [h] at hH hHle; simp at hH hHle; omega
    · exact h
  set s := Real.sqrt n with hs
  have hspos : 0 < s := Real.sqrt_pos.2 (by exact_mod_cast hn1)
  have hss : s * s = n := Real.mul_self_sqrt (Nat.cast_nonneg _)
  set L : ((ι → Bool) → ℝ) →ₗ[ℝ] ((ι → Bool) → ℝ) := Matrix.mulVecLin (hM ℝ ι) with hL
  have hLL : ∀ v, L (L v) = (n : ℝ) • v := fun v => hM_mulVec_mulVec v
  have hLD : ∀ v, L (dmap v) = - dmap (L v) := fun v => hM_dmap v
  set T : (H → ℝ) →ₗ[ℝ] ((ι → Bool) → ℝ) := (L - s • LinearMap.id) ∘ₗ extH H with hT
  have hLT : ∀ u, L (T u) = -s • T u := by
    intro u
    simp only [hT, LinearMap.comp_apply, LinearMap.sub_apply, LinearMap.smul_apply,
      LinearMap.id_apply, map_sub, map_smul, hLL]
    rw [smul_sub, smul_smul, neg_mul, hss]
    module
  have hker : ∃ u, u ≠ 0 ∧ T u = 0 := by
    by_contra hcon
    push Not at hcon
    have hTinj : Function.Injective T := by
      rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
      intro u hu; by_contra h; exact hcon u h hu
    set Ψ := T.coprod (dmap ∘ₗ T) with hΨ
    have hΨinj : Function.Injective Ψ := by
      rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
      rintro ⟨u, w⟩ huw
      simp only [hΨ, LinearMap.coprod_apply, LinearMap.comp_apply] at huw
      have hb : L (dmap (T w)) = s • dmap (T w) := by
        rw [hLD, hLT, map_smul]; simp
      have ha : T u = - dmap (T w) := eq_neg_of_add_eq_zero_left huw
      have h2 : (2 * s) • dmap (T w) = 0 := by
        have e1 := hLT u
        rw [ha, map_neg, hb] at e1
        have : (2 * s) • dmap (T w) = s • dmap (T w) - -(s • dmap (T w)) := by module
        rw [this, e1]; module
      have hw : T w = 0 := by
        rcases smul_eq_zero.1 h2 with h | h
        · exfalso; linarith
        · rw [← dmap_dmap (T w), h, map_zero]
      have hu : T u = 0 := by rw [ha, hw, map_zero, neg_zero]
      have : u = 0 := hTinj (by rw [hu, map_zero])
      have : w = 0 := hTinj (by rw [hw, map_zero])
      simp [*]
    have hfr := LinearMap.finrank_le_finrank_of_injective hΨinj
    rw [Module.finrank_prod, Module.finrank_fintype_fun_eq_card,
      Module.finrank_fintype_fun_eq_card, Fintype.card_coe, Fintype.card_fun,
      Fintype.card_bool, ← hn] at hfr
    have : 2 ^ n = 2 * 2 ^ (n - 1) := by
      rw [← pow_succ']; congr 1; omega
    omega
  obtain ⟨u, hu0, hTu⟩ := hker
  set v := extH H u with hv
  have hLv : L v = s • v := by
    have := hTu
    simp only [hT, LinearMap.comp_apply, LinearMap.sub_apply, LinearMap.smul_apply,
      LinearMap.id_apply] at this
    exact sub_eq_zero.1 this
  have hv0 : ∃ y, v y ≠ 0 := by
    obtain ⟨⟨y, hy⟩, hy0⟩ := Function.ne_iff.1 hu0
    exact ⟨y, by simpa [hv, extH, hy] using hy0⟩
  obtain ⟨x, -, hxmax⟩ := Finset.exists_max_image univ (fun x => |v x|) univ_nonempty
  obtain ⟨y, hy⟩ := hv0
  have hxpos : 0 < |v x| := lt_of_lt_of_le (abs_pos.2 hy) (hxmax y (mem_univ _))
  have hvH : ∀ z, z ∉ H → v z = 0 := fun z hz => by simp [hv, extH, hz]
  have hxH : x ∈ H := by
    by_contra h; rw [hvH x h] at hxpos; simp at hxpos
  refine ⟨x, hxH, ?_⟩
  have key : s * |v x| ≤ ((univ.filter fun i : ι => gflip x i ∈ H).card : ℝ) * |v x| := by
    have e : L v x = s * v x := by rw [hLv]; rfl
    have e2 : L v x = ∑ i, csign ℝ x i * v (gflip x i) := hM_mulVec v x
    calc s * |v x| = |L v x| := by rw [e, abs_mul, abs_of_pos hspos]
      _ = |∑ i, csign ℝ x i * v (gflip x i)| := by rw [e2]
      _ ≤ ∑ i, |csign ℝ x i * v (gflip x i)| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ i, (if gflip x i ∈ H then |v x| else 0) := by
          refine Finset.sum_le_sum fun i _ => ?_
          have hc : |csign ℝ x i| = 1 := by simp [csign]
          rw [abs_mul, hc, one_mul]
          split_ifs with h
          · exact hxmax _ (mem_univ _)
          · rw [hvH _ h]; simp
      _ = ((univ.filter fun i : ι => gflip x i ∈ H).card : ℝ) * |v x| := by
          rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul]
  exact le_of_mul_le_mul_right key hxpos

#print axioms crowded

end General

section Main

lemma pm_not (b : Bool) : pm (!b) = - pm b := by cases b <;> simp [pm]

#print axioms pm_not

lemma pm_cases (b : Bool) : pm b = 1 ∨ pm b = -1 := by cases b <;> simp [pm]

#print axioms pm_cases

lemma prod_pm_cases (S : Finset (Fin n)) (x : Fin n → Bool) :
    (∏ i ∈ S, pm (x i)) = 1 ∨ (∏ i ∈ S, pm (x i)) = -1 := by
  refine Finset.prod_induction _ (fun a => a = 1 ∨ a = -1) ?_ (Or.inl rfl) (fun i _ => pm_cases _)
  rintro a b (rfl | rfl) (rfl | rfl) <;> norm_num

#print axioms prod_pm_cases

lemma prod_pm_flip (S : Finset (Fin n)) (x : Fin n → Bool) {j : Fin n} (hj : j ∈ S) :
    (∏ i ∈ S, pm (flip x j i)) = - ∏ i ∈ S, pm (x i) := by
  rw [← Finset.mul_prod_erase S _ hj, ← Finset.mul_prod_erase S (fun i => pm (x i)) hj]
  have : (∏ i ∈ S.erase j, pm (flip x j i)) = ∏ i ∈ S.erase j, pm (x i) :=
    Finset.prod_congr rfl fun i hi => by
      rw [flip, Function.update_of_ne (Finset.ne_of_mem_erase hi)]
  rw [this, flip, Function.update_self, pm_not]; ring

#print axioms prod_pm_flip

lemma glue_gflip (S : Finset (Fin n)) (y : {i // i ∈ S} → Bool) (w : {i // i ∉ S} → Bool)
    (i : {i // i ∈ S}) :
    (Equiv.piEquivPiSubtypeProd (fun i => i ∈ S) (fun _ => Bool)).symm (gflip y i, w) =
      flip ((Equiv.piEquivPiSubtypeProd (fun i => i ∈ S) (fun _ => Bool)).symm (y, w)) i.1 := by
  funext j
  simp only [Equiv.piEquivPiSubtypeProd, Equiv.coe_fn_symm_mk, flip, gflip]
  by_cases hj : j = i.1
  · subst hj; simp [i.2]
  · rw [Function.update_of_ne hj]
    split_ifs with h
    · have hne : (⟨j, h⟩ : {i // i ∈ S}) ≠ i := fun e => hj (congrArg Subtype.val e)
      simp only [Function.update, hne, dite_false]
    · rfl

#print axioms glue_gflip

lemma exists_sensitive (f : (Fin n → Bool) → Bool) (S : Finset (Fin n))
    (hS : fourierCoeff f S ≠ 0) : ∃ x, Real.sqrt S.card ≤ (sensitivityAt f x : ℝ) := by
  by_cases hS0 : S.card = 0
  · exact ⟨fun _ => false, by simp [hS0]⟩
  set h : (Fin n → Bool) → ℚ := fun x => pm (f x) * ∏ i ∈ S, pm (x i) with hh
  have hsum : (∑ x, h x) ≠ 0 := by
    intro h0; apply hS; simp only [fourierCoeff]; rw [show (∑ x, pm (f x) * ∏ i ∈ S, pm (x i))
      = ∑ x, h x from rfl, h0, zero_div]
  set e := Equiv.piEquivPiSubtypeProd (fun i : Fin n => i ∈ S) (fun _ => Bool) with he
  rw [← Equiv.sum_comp e.symm, Fintype.sum_prod_type_right] at hsum
  obtain ⟨w, -, hw⟩ := Finset.exists_ne_zero_of_sum_ne_zero hsum
  set g : ({i // i ∈ S} → Bool) → (Fin n → Bool) := fun y => e.symm (y, w) with hg
  have hcard : Fintype.card {i // i ∈ S} = S.card := Fintype.card_coe S
  have hval : ∀ x, h x = 1 ∨ h x = -1 := by
    intro x
    rcases pm_cases (f x) with h1 | h1 <;> rcases prod_pm_cases S x with h2 | h2 <;>
      simp [hh, h1, h2]
  -- flipping a vote in `S` keeps `h` only if it changes `f`
  have hflip : ∀ y (i : {i // i ∈ S}), h (g (gflip y i)) = h (g y) →
      f (flip (g y) i.1) ≠ f (g y) := by
    intro y i heq hfe
    have e1 : g (gflip y i) = flip (g y) i.1 := glue_gflip S y w i
    rw [e1] at heq
    simp only [hh, prod_pm_flip S _ i.2, hfe] at heq
    rcases prod_pm_cases S (g y) with h2 | h2 <;> rcases pm_cases (f (g y)) with h1 | h1 <;>
      simp [h1, h2] at heq <;> norm_num at heq
  -- a large set on which `h ∘ g` is constant
  have hbig : ∃ H : Finset ({i // i ∈ S} → Bool),
      2 ^ (S.card - 1) + 1 ≤ H.card ∧ ∀ y ∈ H, ∀ y' ∈ H, h (g y) = h (g y') := by
    set H1 := univ.filter fun y : {i // i ∈ S} → Bool => h (g y) = 1
    set H2 := univ.filter fun y : {i // i ∈ S} → Bool => ¬ h (g y) = 1
    have htot : H1.card + H2.card = 2 ^ S.card := by
      rw [Finset.card_filter_add_card_filter_not, card_univ, Fintype.card_fun,
        Fintype.card_bool, hcard]
    have hdiff : (∑ y, h (g y)) = (H1.card : ℚ) - H2.card := by
      rw [← Finset.sum_filter_add_sum_filter_not univ (fun y => h (g y) = 1)]
      rw [Finset.sum_congr rfl (fun y hy => (Finset.mem_filter.1 hy).2),
        Finset.sum_congr rfl (fun y hy => (hval (g y)).resolve_left (Finset.mem_filter.1 hy).2)]
      simp [H1, H2, sub_eq_add_neg]
    have hne : H1.card ≠ H2.card := by
      intro hc; apply hw; rw [show (∑ y, h (e.symm (y, w))) = ∑ y, h (g y) from rfl, hdiff, hc,
        sub_self]
    have hpow : S.card = 0 ∨ 2 ^ S.card = 2 * 2 ^ (S.card - 1) := by
      rcases Nat.eq_zero_or_pos S.card with h0 | h0
      · exact Or.inl h0
      · right; rw [← pow_succ']; congr 1; omega
    rcases hpow with h0 | h0
    · exact absurd h0 hS0
    · rcases Nat.lt_or_gt_of_ne hne with hc | hc
      · refine ⟨H2, by omega, fun y hy y' hy' => ?_⟩
        rw [(hval (g y)).resolve_left (Finset.mem_filter.1 hy).2,
          (hval (g y')).resolve_left (Finset.mem_filter.1 hy').2]
      · refine ⟨H1, by omega, fun y hy y' hy' => ?_⟩
        rw [(Finset.mem_filter.1 hy).2, (Finset.mem_filter.1 hy').2]
  obtain ⟨H, hHc, hHconst⟩ := hbig
  rw [← hcard] at hHc
  obtain ⟨y, hyH, hy⟩ := crowded H hHc
  refine ⟨g y, ?_⟩
  rw [hcard] at hy
  refine hy.trans ?_
  have : (univ.filter fun i : {i // i ∈ S} => gflip y i ∈ H).card ≤ sensitivityAt f (g y) := by
    unfold sensitivityAt
    refine Finset.card_le_card_of_injOn (fun i => i.1) ?_ ?_
    · intro i hi
      have hi' := (Finset.mem_filter.1 hi).2
      simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq]
      exact hflip y i (hHconst _ hi' _ hyH)
    · intro i _ j _ hij; exact Subtype.ext hij
  exact_mod_cast this

#print axioms exists_sensitive

end Main



section Compute

/-- `pm` with integer values, for exact computation. -/
def pmZ (b : Bool) : ℤ := if b then 1 else -1

/-- The integer sum behind a Fourier coefficient. -/
def fourierSumZ (f : (Fin n → Bool) → Bool) (S : Finset (Fin n)) : ℤ :=
  ∑ x : Fin n → Bool, pmZ (f x) * ∏ i ∈ S, pmZ (x i)

lemma fourierCoeff_eq (f : (Fin n → Bool) → Bool) (S : Finset (Fin n)) :
    fourierCoeff f S = (fourierSumZ f S : ℚ) / 2 ^ n := by
  have hp : ∀ b, pm b = (pmZ b : ℚ) := fun b => by cases b <;> simp [pm, pmZ]
  simp [fourierCoeff, fourierSumZ, hp]

#print axioms fourierCoeff_eq

lemma degree_eq (f : (Fin n → Bool) → Bool) :
    degree f = (univ.filter fun S : Finset (Fin n) => fourierSumZ f S ≠ 0).sup Finset.card := by
  unfold degree
  congr 1
  refine Finset.filter_congr fun S _ => ?_
  rw [fourierCoeff_eq]
  simp

#print axioms degree_eq

end Compute

/-- Huang's sensitivity theorem (2019): for every Boolean function `f` of `n` votes,
defined on every pattern, the square root of its degree is at most its sensitivity,
`√deg(f) ≤ s(f)`. -/
theorem sqrt_degree_le_sensitivity (f : (Fin n → Bool) → Bool) :
    Real.sqrt (degree f) ≤ (sensitivity f : ℝ) := by
  rcases Finset.eq_empty_or_nonempty (univ.filter fun S : Finset (Fin n) => fourierCoeff f S ≠ 0)
    with h | h
  · simp [degree, h]
  · obtain ⟨S, hS, hdeg⟩ := Finset.exists_mem_eq_sup _ h Finset.card
    obtain ⟨x, hx⟩ := exists_sensitive f S (Finset.mem_filter.1 hS).2
    have h1 : degree f = S.card := hdeg
    rw [h1]
    refine hx.trans ?_
    exact_mod_cast Finset.le_sup (f := sensitivityAt f) (mem_univ x)

/-- The signed cube matrix squares to `n` times the identity: `A_n^2 = n I`. -/
theorem huangMatrix_sq (n : ℕ) : huangMatrix n * huangMatrix n = (n : ℤ) • (1 : Matrix _ _ ℤ) := by
  have := hM_sq (ι := Fin n) ℤ
  rw [Fintype.card_fin] at this
  exact this

/-- More than half the corners forces a crowded corner: any set `H` of at least
`2^(n-1) + 1` corners of the `n`-cube contains a corner with at least `√n` neighbours in `H`. -/
theorem exists_crowded_corner (H : Finset (Fin n → Bool)) (hH : 2 ^ (n - 1) + 1 ≤ H.card) :
    ∃ x ∈ H, Real.sqrt n ≤ (chosenNeighbours H x : ℝ) := by
  have := crowded (ι := Fin n) H (by rw [Fintype.card_fin]; exact hH)
  rw [Fintype.card_fin] at this
  exact this

/-- Majority of 3 supervisors: the rota passes when at least 2 say yes. -/
def maj3 (x : Fin 3 → Bool) : Bool := (x 0 && x 1) || (x 0 && x 2) || (x 1 && x 2)

/-- OR of 4 relief staff: the gap is covered when anyone says yes. -/
def or4 (x : Fin 4 → Bool) : Bool := x 0 || x 1 || x 2 || x 3

-- Majority: sensitivity 2 at (+,+,-), 0 at (+,+,+), 2 overall.
example : sensitivityAt maj3 ![true, true, false] = 2 := by decide
example : sensitivityAt maj3 ![true, true, true] = 0 := by decide
example : sensitivity maj3 = 2 := by decide
-- Majority's Fourier amounts: 1/2 on each single vote, -1/2 on all three; degree 3.
example : fourierCoeff maj3 {0} = 1 / 2 := by
  rw [fourierCoeff_eq, show fourierSumZ maj3 {0} = 4 by decide]; norm_num
example : fourierCoeff maj3 univ = -1 / 2 := by
  rw [fourierCoeff_eq, show fourierSumZ maj3 univ = -4 by decide]; norm_num
example : degree maj3 = 3 := by rw [degree_eq]; decide
-- Majority's influences: 1/2 each, 3/2 in total.
example : influence maj3 0 = 1 / 2 := by
  rw [influence, show (univ.filter fun x : Fin 3 → Bool => maj3 (flip x 0) ≠ maj3 x).card = 4 by
    decide]; norm_num
example : ∑ i, influence maj3 i = 3 / 2 := by
  simp only [influence]
  rw [← Finset.sum_div, ← Nat.cast_sum, show (∑ i : Fin 3,
    (univ.filter fun x : Fin 3 → Bool => maj3 (flip x i) ≠ maj3 x).card) = 12 by decide]
  norm_num
-- OR of 4: sensitivity 4 at all-no, degree 4, influence 1/8 each.
example : sensitivityAt or4 (fun _ => false) = 4 := by decide
example : sensitivity or4 = 4 := by decide
example : degree or4 = 4 := by rw [degree_eq]; decide
example : influence or4 0 = 1 / 8 := by
  rw [influence, show (univ.filter fun x : Fin 4 → Bool => or4 (flip x 0) ≠ or4 x).card = 2 by
    decide]; norm_num
-- The signed 3-cube matrix squares to 3I.
example : huangMatrix 3 * huangMatrix 3 = (3 : ℤ) • (1 : Matrix _ _ ℤ) := by
  exact_mod_cast huangMatrix_sq 3
-- Any 5 of the 8 corners include one with at least 2 chosen neighbours.
example : ∀ H : Finset (Fin 3 → Bool), H.card = 5 → ∃ x ∈ H, 2 ≤ chosenNeighbours H x := by
  intro H hH
  obtain ⟨x, hx, h⟩ := exists_crowded_corner H (by rw [hH]; norm_num)
  refine ⟨x, hx, ?_⟩
  by_contra hlt
  have h1 : (chosenNeighbours H x : ℝ) ≤ 1 := by exact_mod_cast Nat.le_of_lt_succ (not_le.1 hlt)
  have h3 : (1 : ℝ) < Real.sqrt ((3 : ℕ) : ℝ) := by
    rw [Real.lt_sqrt (by norm_num)]; norm_num
  linarith
-- Exactly half is not enough: the 4 patterns with an even number of yes votes have no chosen neighbours.
example : ∃ H : Finset (Fin 3 → Bool), H.card = 4 ∧ ∀ x ∈ H, chosenNeighbours H x = 0 :=
  ⟨{![false, false, false], ![true, true, false], ![true, false, true], ![false, true, true]},
    by decide⟩

#print axioms sqrt_degree_le_sensitivity
#print axioms huangMatrix_sq
#print axioms exists_crowded_corner

end BooleanSensitivity
