-- Presentations: von Dyck's theorem extends rule-respecting generator maps to homomorphisms, the tile presentation is the dihedral group of order 8, and the Q8 presentation has 8 members but is a different group.
import Mathlib.GroupTheory.PresentedGroup
import Mathlib.GroupTheory.SpecificGroups.Dihedral
import Mathlib.GroupTheory.SpecificGroups.Quaternion
import Mathlib.Algebra.BigOperators.Intervals

/-- The tile's two letters: a quarter turn `r` and a flip `f`. -/
inductive TileLetter
  | r
  | f
  deriving DecidableEq

/-- The quaternion presentation's two letters `i` and `j`. -/
inductive QuatLetter
  | i
  | j
  deriving DecidableEq

/-- The tile relations `r^4`, `f^2` and `f r f = r⁻¹`, the last written as `f r f r = 1`. -/
def tileRels : Set (FreeGroup TileLetter) :=
  let r := FreeGroup.of TileLetter.r
  let f := FreeGroup.of TileLetter.f
  {r ^ 4, f ^ 2, f * r * f * r}

/-- The quaternion relations `i^4`, `i^2 = j^2` and `j i j⁻¹ = i⁻¹`, each written as a word equal to `1`. -/
def quatRels : Set (FreeGroup QuatLetter) :=
  let i := FreeGroup.of QuatLetter.i
  let j := FreeGroup.of QuatLetter.j
  {i ^ 4, i ^ 2 * (j ^ 2)⁻¹, j * i * j⁻¹ * i}

/-- A homomorphism with a one-sided inverse function whose image is stable under left
multiplication by a generating set is a bijection. -/
theorem bijective_of_section_gen {P G : Type*} [Group P] [Group G] (φ : P →* G) (g : G → P)
    (hφg : ∀ x, φ (g x) = x) (s : Set P) (hs : Subgroup.closure s = ⊤) (h1 : g 1 = 1)
    (hg : ∀ a ∈ s, ∀ x, a * g x = g (φ a * x)) : Function.Bijective φ := by
  have key : ∀ p, g (φ p) = p := by
    intro p
    have hp : p ∈ Subgroup.closure s := hs ▸ Subgroup.mem_top p
    induction hp using Subgroup.closure_induction_left with
    | one => simp [h1]
    | mul_left a ha y _ ih => rw [map_mul, ← hg a ha, ih]
    | inv_mul_cancel a ha y _ ih =>
      have : a * g (φ (a⁻¹ * y)) = a * (a⁻¹ * y) := by
        rw [hg a ha, ← map_mul, mul_inv_cancel_left, ih]
      exact mul_left_cancel this
  exact ⟨fun p q h => by rw [← key p, ← key q, h], fun x => ⟨g x, hφg x⟩⟩

/-- The tile relation `r^4 = 1` holds in the presented group. -/
theorem tile_r_pow_four : (PresentedGroup.of TileLetter.r : PresentedGroup tileRels) ^ 4 = 1 := by
  have h := PresentedGroup.one_of_mem (rels := tileRels)
    (x := FreeGroup.of TileLetter.r ^ 4) (by simp [tileRels])
  rwa [map_pow] at h

/-- The tile relation `f^2 = 1` holds in the presented group. -/
theorem tile_f_sq : (PresentedGroup.of TileLetter.f : PresentedGroup tileRels) ^ 2 = 1 := by
  have h := PresentedGroup.one_of_mem (rels := tileRels)
    (x := FreeGroup.of TileLetter.f ^ 2) (by simp [tileRels])
  rwa [map_pow] at h

/-- The tile relation `f r f r = 1` holds in the presented group. -/
theorem tile_frfr : (PresentedGroup.of TileLetter.f * PresentedGroup.of TileLetter.r *
    PresentedGroup.of TileLetter.f * PresentedGroup.of TileLetter.r : PresentedGroup tileRels) = 1 := by
  have h := PresentedGroup.one_of_mem (rels := tileRels)
    (x := FreeGroup.of TileLetter.f * FreeGroup.of TileLetter.r * FreeGroup.of TileLetter.f *
      FreeGroup.of TileLetter.r) (by simp [tileRels])
  rwa [map_mul, map_mul, map_mul] at h

/-- In the tile group, `r f = f r^3`. -/
theorem tile_rf : (PresentedGroup.of TileLetter.r * PresentedGroup.of TileLetter.f :
    PresentedGroup tileRels) = PresentedGroup.of TileLetter.f * PresentedGroup.of TileLetter.r ^ 3 := by
  set R : PresentedGroup tileRels := PresentedGroup.of TileLetter.r
  set F : PresentedGroup tileRels := PresentedGroup.of TileLetter.f
  have hFF : F * F = 1 := by rw [← sq]; exact tile_f_sq
  have hRR3 : R * R ^ 3 = 1 := by rw [← pow_succ']; exact tile_r_pow_four
  calc
    R * F = F⁻¹ * (F * R * F * R) * R⁻¹ := by group
    _ = F * R ^ 3 := by
      rw [tile_frfr, mul_one, inv_eq_of_mul_eq_one_right hFF, inv_eq_of_mul_eq_one_right hRR3]

/-- The quaternion relation `i^4 = 1` holds in the presented group. -/
theorem quat_i_pow_four : (PresentedGroup.of QuatLetter.i : PresentedGroup quatRels) ^ 4 = 1 := by
  have h := PresentedGroup.one_of_mem (rels := quatRels)
    (x := FreeGroup.of QuatLetter.i ^ 4) (by simp [quatRels])
  rwa [map_pow] at h

/-- The quaternion relation `i^2 = j^2` holds in the presented group. -/
theorem quat_i_sq_eq_j_sq : (PresentedGroup.of QuatLetter.i : PresentedGroup quatRels) ^ 2 =
    PresentedGroup.of QuatLetter.j ^ 2 := by
  have h := PresentedGroup.one_of_mem (rels := quatRels)
    (x := FreeGroup.of QuatLetter.i ^ 2 * (FreeGroup.of QuatLetter.j ^ 2)⁻¹) (by simp [quatRels])
  rw [map_mul, map_inv, map_pow, map_pow] at h
  exact mul_inv_eq_one.mp h

/-- The quaternion relation `j i j⁻¹ i = 1` holds in the presented group. -/
theorem quat_jiji : (PresentedGroup.of QuatLetter.j * PresentedGroup.of QuatLetter.i *
    (PresentedGroup.of QuatLetter.j)⁻¹ * PresentedGroup.of QuatLetter.i :
      PresentedGroup quatRels) = 1 := by
  have h := PresentedGroup.one_of_mem (rels := quatRels)
    (x := FreeGroup.of QuatLetter.j * FreeGroup.of QuatLetter.i * (FreeGroup.of QuatLetter.j)⁻¹ *
      FreeGroup.of QuatLetter.i) (by simp [quatRels])
  rwa [map_mul, map_mul, map_mul, map_inv] at h

/-- Von Dyck's theorem: if members of a group `H` chosen for the letters obey every relation,
the choice extends to exactly one homomorphism from the presented group `⟨S | R⟩` to `H`. -/
theorem von_dyck {S : Type*} (R : Set (FreeGroup S)) {H : Type*} [Group H] (φ : S → H)
    (hR : ∀ w ∈ R, FreeGroup.lift φ w = 1) :
    ∃! φbar : PresentedGroup R →* H, ∀ s : S, φbar (PresentedGroup.of s) = φ s := by
  refine ⟨PresentedGroup.toGroup hR, fun s => PresentedGroup.toGroup.of hR, ?_⟩
  intro ψ hψ
  exact PresentedGroup.ext fun s => by rw [hψ s, PresentedGroup.toGroup.of hR]

/-- The tile group is `⟨r, f | r^4, f^2, f r f = r⁻¹⟩`: the presented group is isomorphic to the
square's 8 symmetries, with `r` sent to the quarter turn and `f` to a flip. -/
theorem tile_presentation_iso_dihedral :
    ∃ e : PresentedGroup tileRels ≃* DihedralGroup 4,
      e (PresentedGroup.of TileLetter.r) = DihedralGroup.r 1 ∧
      e (PresentedGroup.of TileLetter.f) = DihedralGroup.sr 0 := by
  set R : PresentedGroup tileRels := PresentedGroup.of TileLetter.r with hRdef
  set F : PresentedGroup tileRels := PresentedGroup.of TileLetter.f with hFdef
  let f₀ : TileLetter → DihedralGroup 4 := fun l => match l with
    | .r => DihedralGroup.r 1
    | .f => DihedralGroup.sr 0
  have hrel : ∀ w ∈ tileRels, FreeGroup.lift f₀ w = 1 := by
    intro w hw
    simp only [tileRels, Set.mem_insert_iff, Set.mem_singleton_iff] at hw
    rcases hw with rfl | rfl | rfl <;> simp [f₀] <;> decide
  let φ := PresentedGroup.toGroup hrel
  have hφR : φ R = DihedralGroup.r 1 := PresentedGroup.toGroup.of hrel
  have hφF : φ F = DihedralGroup.sr 0 := PresentedGroup.toGroup.of hrel
  have hR4 : R ^ 4 = 1 := tile_r_pow_four
  have hF2 : F ^ 2 = 1 := tile_f_sq
  have hpow : ∀ n, R ^ n = R ^ (n % 4) := fun n => pow_eq_pow_mod n hR4
  have hFF : F * F = 1 := by rw [← sq]; exact hF2
  have hRF : R * F = F * R ^ 3 := tile_rf
  let g : DihedralGroup 4 → PresentedGroup tileRels := fun d => match d with
    | .r k => R ^ k.val
    | .sr k => F * R ^ k.val
  have hφg : ∀ x, φ (g x) = x := by
    rintro (k | k) <;> simp only [g, map_mul, map_pow, hφR, hφF] <;> revert k <;> decide
  have h1 : g 1 = 1 := by
    show R ^ (0 : ZMod 4).val = 1
    simp
  have hbij := bijective_of_section_gen φ g hφg (Set.range PresentedGroup.of)
    (PresentedGroup.closure_range_of _) h1 ?_
  · exact ⟨MulEquiv.ofBijective φ hbij, hφR, hφF⟩
  · rintro a ⟨l, rfl⟩ (k | k) <;> cases l
    · show R * g (.r k) = g (φ R * .r k)
      rw [hφR, DihedralGroup.r_mul_r]
      simp only [g]
      rw [← pow_succ', hpow (k.val + 1), hpow ((1 + k).val)]
      congr 1
      revert k; decide
    · show F * g (.r k) = g (φ F * .r k)
      rw [hφF, DihedralGroup.sr_mul_r]
      simp only [g, zero_add]
    · show R * g (.sr k) = g (φ R * .sr k)
      rw [hφR, DihedralGroup.r_mul_sr]
      simp only [g]
      rw [← mul_assoc, hRF, mul_assoc, ← pow_add, hpow (3 + k.val), hpow ((k - 1).val)]
      congr 2
      revert k; decide
    · show F * g (.sr k) = g (φ F * .sr k)
      rw [hφF, DihedralGroup.sr_mul_sr]
      simp only [g, sub_zero]
      rw [← mul_assoc, hFF, one_mul]

/-- `Q8 = ⟨i, j | i^4, i^2 = j^2, j i j⁻¹ = i⁻¹⟩` has exactly 8 members, yet it is not the tile group. -/
theorem quaternion_presentation_card_eight_not_tile :
    Nat.card (PresentedGroup quatRels) = 8 ∧
      IsEmpty (PresentedGroup quatRels ≃* PresentedGroup tileRels) := by
  set I : PresentedGroup quatRels := PresentedGroup.of QuatLetter.i with hIdef
  set J : PresentedGroup quatRels := PresentedGroup.of QuatLetter.j with hJdef
  let f₀ : QuatLetter → QuaternionGroup 2 := fun l => match l with
    | .i => QuaternionGroup.a 1
    | .j => QuaternionGroup.xa 0
  have hrel : ∀ w ∈ quatRels, FreeGroup.lift f₀ w = 1 := by
    intro w hw
    simp only [quatRels, Set.mem_insert_iff, Set.mem_singleton_iff] at hw
    rcases hw with rfl | rfl | rfl <;> simp [f₀] <;> decide
  let φ := PresentedGroup.toGroup hrel
  have hφI : φ I = QuaternionGroup.a 1 := PresentedGroup.toGroup.of hrel
  have hφJ : φ J = QuaternionGroup.xa 0 := PresentedGroup.toGroup.of hrel
  have hI4 : I ^ 4 = 1 := quat_i_pow_four
  have hpow : ∀ n, I ^ n = I ^ (n % 4) := fun n => pow_eq_pow_mod n hI4
  have hII3 : I * I ^ 3 = 1 := by rw [← pow_succ']; exact hI4
  have hJJ : J * J = I ^ 2 := by rw [← sq]; exact quat_i_sq_eq_j_sq.symm
  have hIJ : I * J = J * I ^ 3 := calc
    I * J = J * I⁻¹ * (J⁻¹ * (J * I * J⁻¹ * I) * J) := by group
    _ = J * I ^ 3 := by
      rw [quat_jiji, mul_one, inv_mul_cancel, mul_one, inv_eq_of_mul_eq_one_right hII3]
  let g : QuaternionGroup 2 → PresentedGroup quatRels := fun d => match d with
    | .a k => I ^ k.val
    | .xa k => J * I ^ k.val
  have hφg : ∀ x, φ (g x) = x := by
    rintro (k | k) <;> simp only [g, map_mul, map_pow, hφI, hφJ] <;> revert k <;> decide
  have h1 : g 1 = 1 := by
    show I ^ (0 : ZMod (2 * 2)).val = 1
    simp
  have hbij := bijective_of_section_gen φ g hφg (Set.range PresentedGroup.of)
    (PresentedGroup.closure_range_of _) h1 ?_
  · let e := MulEquiv.ofBijective φ hbij
    refine ⟨?_, ?_⟩
    · rw [Nat.card_congr e.toEquiv, Nat.card_eq_fintype_card, QuaternionGroup.card]
    · obtain ⟨t, -, -⟩ := tile_presentation_iso_dihedral
      refine ⟨fun e' => ?_⟩
      let ψ : QuaternionGroup 2 ≃* DihedralGroup 4 := (e.symm.trans e').trans t
      have hu : ∀ q : QuaternionGroup 2, q ≠ 1 → q * q = 1 → q = QuaternionGroup.a 2 := by
        decide
      have hA : ψ.symm (DihedralGroup.r 2) = QuaternionGroup.a 2 := by
        apply hu
        · rw [Ne, MulEquiv.map_eq_one_iff]; decide
        · rw [← map_mul, show (DihedralGroup.r 2 * DihedralGroup.r 2 : DihedralGroup 4) = 1 by
            decide, map_one]
      have hB : ψ.symm (DihedralGroup.sr 0) = QuaternionGroup.a 2 := by
        apply hu
        · rw [Ne, MulEquiv.map_eq_one_iff]; decide
        · rw [← map_mul, show (DihedralGroup.sr 0 * DihedralGroup.sr 0 : DihedralGroup 4) = 1 by
            decide, map_one]
      have := ψ.symm.injective (hA.trans hB.symm)
      exact absurd this (by decide)
  · rintro a ⟨l, rfl⟩ (k | k) <;> cases l
    · show I * g (.a k) = g (φ I * .a k)
      rw [hφI, QuaternionGroup.a_mul_a]
      simp only [g]
      rw [← pow_succ', hpow (k.val + 1)]
      conv_rhs => rw [hpow]
      congr 1
      revert k; decide
    · show J * g (.a k) = g (φ J * .a k)
      rw [hφJ, QuaternionGroup.xa_mul_a]
      simp only [g, zero_add]
    · show I * g (.xa k) = g (φ I * .xa k)
      rw [hφI, QuaternionGroup.a_mul_xa]
      simp only [g]
      rw [← mul_assoc, hIJ, mul_assoc, ← pow_add, hpow (3 + k.val)]
      conv_rhs => rw [hpow]
      congr 2
      revert k; decide
    · show J * g (.xa k) = g (φ J * .xa k)
      rw [hφJ, QuaternionGroup.xa_mul_xa]
      simp only [g]
      rw [← mul_assoc, hJJ, ← pow_add, hpow (2 + k.val)]
      conv_rhs => rw [hpow]
      congr 1
      revert k; decide

-- Words of 1 to 8 letters in `r` and `f`: 510 of them.
example : ∑ k ∈ Finset.Icc 1 8, 2 ^ k = 510 := by decide

-- Short forms `r^a f^b`: at most 4 × 2 = 8.
example : 4 * 2 = 8 := by norm_num

-- The hand-reduced word: `f r r f = r r` in the tile group.
example :
    (PresentedGroup.of TileLetter.f * PresentedGroup.of TileLetter.r ^ 2 *
      PresentedGroup.of TileLetter.f : PresentedGroup tileRels) =
      PresentedGroup.of TileLetter.r ^ 2 := by
  set R : PresentedGroup tileRels := PresentedGroup.of TileLetter.r
  set F : PresentedGroup tileRels := PresentedGroup.of TileLetter.f
  have hRF : R * F = F * R ^ 3 := tile_rf
  have hFF : F * F = 1 := by rw [← sq]; exact tile_f_sq
  calc
    F * R ^ 2 * F = F * R * (R * F) := by rw [sq]; simp only [mul_assoc]
    _ = F * R * (F * R ^ 3) := by rw [hRF]
    _ = F * (R * F) * R ^ 3 := by simp only [mul_assoc]
    _ = F * (F * R ^ 3) * R ^ 3 := by rw [hRF]
    _ = F * F * (R ^ 3 * R ^ 3) := by simp only [mul_assoc]
    _ = R ^ 2 := by rw [hFF, one_mul, ← pow_add, pow_eq_pow_mod 6 tile_r_pow_four]

-- The quarter turn and a flip obey all three tile rules.
example : (DihedralGroup.r 1 : DihedralGroup 4) ^ 4 = 1 := by decide
example : (DihedralGroup.sr 0 : DihedralGroup 4) ^ 2 = 1 := by decide
example : (DihedralGroup.sr 0 * DihedralGroup.r 1 * DihedralGroup.sr 0 : DihedralGroup 4) =
    (DihedralGroup.r 1)⁻¹ := by decide

-- Sending `f` to the half turn breaks `f r f = r⁻¹`, so von Dyck gives no map.
example : (DihedralGroup.r 2 * DihedralGroup.r 1 * DihedralGroup.r 2 : DihedralGroup 4) ≠
    (DihedralGroup.r 1)⁻¹ := by decide

-- The quaternions `i` and `j` obey all three Q8 rules.
example : (QuaternionGroup.a 1 : QuaternionGroup 2) ^ 4 = 1 := by decide
example : (QuaternionGroup.a 1 : QuaternionGroup 2) ^ 2 = QuaternionGroup.xa 0 ^ 2 := by decide
example : (QuaternionGroup.xa 0 * QuaternionGroup.a 1 * (QuaternionGroup.xa 0)⁻¹ : QuaternionGroup 2) =
    (QuaternionGroup.a 1)⁻¹ := by decide

-- Members of order 2: five in the tile group, one in Q8.
example : (Finset.univ.filter fun g : DihedralGroup 4 => g ≠ 1 ∧ g * g = 1).card = 5 := by decide
example : (Finset.univ.filter fun g : QuaternionGroup 2 => g ≠ 1 ∧ g * g = 1).card = 1 := by decide

#print axioms bijective_of_section_gen
#print axioms tile_r_pow_four
#print axioms tile_f_sq
#print axioms tile_frfr
#print axioms tile_rf
#print axioms quat_i_pow_four
#print axioms quat_i_sq_eq_j_sq
#print axioms quat_jiji
#print axioms von_dyck
#print axioms tile_presentation_iso_dihedral
#print axioms quaternion_presentation_card_eight_not_tile
