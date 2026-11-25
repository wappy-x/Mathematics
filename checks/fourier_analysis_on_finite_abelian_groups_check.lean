-- Fourier analysis on a finite abelian group: the complex characters of a finite abelian group are as many as its members, match the group, and are orthonormal, so every function is the sum of its characters with energy kept, convolution turns into multiplication, and the supports of a nonzero function and of its transform multiply to at least the group's size.
import Mathlib.Analysis.Fourier.FiniteAbelian.PontryaginDuality
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum

/-! `G` is a finite abelian group, written additively. A character is Mathlib's `AddChar G ℂ`:
a map `χ : G → ℂ` with `χ 0 = 1` and `χ (x + y) = χ x * χ y`. The dual group `Ĝ` is
`AddChar G ℂ`; Mathlib writes its operation (pointwise multiplication) additively, so
`G ≃+ AddChar G ℂ` is a match between the group and its dual. The card's normalisation is used:
the transform `f̂(χ) = (1/|G|) ∑ₓ f(x) conj(χ(x))` and the convolution
`(f * g)(x) = (1/|G|) ∑_y f(y) g(x − y)`. The support of a function is Mathlib's
`Function.support`, the points where it is nonzero, and `Set.ncard` counts it. -/

open ComplexConjugate

variable {G : Type*} [AddCommGroup G] [Fintype G]

/-- The card's transform: the amount of the character `χ` in `f`,
`f̂(χ) = (1/|G|) ∑ₓ f(x) · conj (χ x)`. -/
noncomputable def charTransform (f : G → ℂ) (χ : AddChar G ℂ) : ℂ :=
  (Fintype.card G : ℂ)⁻¹ * ∑ x, f x * conj (χ x)

/-- The card's convolution: `(f * g)(x) = (1/|G|) ∑_y f(y) g(x − y)`. -/
noncomputable def charConv (f g : G → ℂ) (x : G) : ℂ :=
  (Fintype.card G : ℂ)⁻¹ * ∑ y, f y * g (x - y)

theorem fourier_sum_mul_conj (χ ψ : AddChar G ℂ) [Decidable (χ = ψ)] :
    ∑ x, χ x * conj (ψ x) = if χ = ψ then (Fintype.card G : ℂ) else 0 := by
  classical
  have h : ∀ x, χ x * conj (ψ x) = (χ - ψ) x := by
    intro x; rw [AddChar.sub_apply, AddChar.map_neg_eq_conj]
  simp_rw [h]
  rw [AddChar.sum_eq_ite]
  simp only [sub_eq_zero]

theorem fourier_inversion_aux (f : G → ℂ) (x : G) :
    f x = ∑ χ : AddChar G ℂ, charTransform f χ * χ x := by
  classical
  have hc : (Fintype.card G : ℂ) ≠ 0 := Nat.cast_ne_zero.2 Fintype.card_ne_zero
  have h1 : ∀ (χ : AddChar G ℂ) (y : G), conj (χ y) * χ x = χ (x - y) := by
    intro χ y
    rw [sub_eq_add_neg, AddChar.map_add_eq_mul, AddChar.map_neg_eq_conj, mul_comm]
  calc f x = (Fintype.card G : ℂ)⁻¹ * ∑ y, f y * ∑ χ : AddChar G ℂ, χ (x - y) := by
        simp_rw [AddChar.sum_apply_eq_ite, sub_eq_zero, mul_ite, mul_zero]
        rw [Finset.sum_ite_eq]
        simp only [Finset.mem_univ, ite_true]
        field_simp
    _ = ∑ χ : AddChar G ℂ, charTransform f χ * χ x := by
        simp_rw [charTransform, Finset.mul_sum, Finset.sum_mul]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun y _ => Finset.sum_congr rfl fun χ _ => ?_
        rw [← h1]; ring

theorem fourier_plancherel_aux (f : G → ℂ) :
    (Fintype.card G : ℝ)⁻¹ * ∑ x, ‖f x‖ ^ 2 = ∑ χ : AddChar G ℂ, ‖charTransform f χ‖ ^ 2 := by
  have hc : (Fintype.card G : ℂ) ≠ 0 := Nat.cast_ne_zero.2 Fintype.card_ne_zero
  apply Complex.ofReal_injective
  push_cast
  simp_rw [← Complex.mul_conj']
  have h1 : ∀ x, conj (f x) = ∑ χ : AddChar G ℂ, conj (charTransform f χ) * conj (χ x) := by
    intro x
    conv_lhs => rw [fourier_inversion_aux f x]
    simp [map_sum]
  have h2 : ∀ χ : AddChar G ℂ, ∑ x, f x * conj (χ x) = (Fintype.card G : ℂ) * charTransform f χ := by
    intro χ; rw [charTransform, ← mul_assoc, mul_inv_cancel₀ hc, one_mul]
  calc (Fintype.card G : ℂ)⁻¹ * ∑ x, f x * conj (f x)
      = (Fintype.card G : ℂ)⁻¹ * ∑ χ : AddChar G ℂ, conj (charTransform f χ) * ∑ x, f x * conj (χ x) := by
        congr 1
        simp_rw [h1, Finset.mul_sum]
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun χ _ => Finset.sum_congr rfl fun y _ => ?_
        ring
    _ = ∑ χ : AddChar G ℂ, charTransform f χ * conj (charTransform f χ) := by
        simp_rw [h2, Finset.mul_sum]
        refine Finset.sum_congr rfl fun χ _ => ?_
        field_simp

theorem fourier_exists_addEquiv : Nonempty (G ≃+ AddChar G ℂ) := by
  classical
  obtain ⟨ι, _, n, hn, ⟨e⟩⟩ := AddCommGroup.equiv_directSum_zmod_of_finite' G
  have hn' : ∀ i, NeZero (n i) := fun i => ⟨by have := hn i; omega⟩
  let e' : G ≃+ ((i : ι) → ZMod (n i)) := e.trans (DirectSum.addEquivProd _)
  let φ : ((i : ι) → ZMod (n i)) → AddChar ((i : ι) → ZMod (n i)) ℂ := fun u =>
    { toFun := fun x => ∏ i, AddChar.zmodAddEquiv (u i) (x i)
      map_zero_eq_one' := by simp
      map_add_eq_mul' := fun x y => by
        simp only [Pi.add_apply, AddChar.map_add_eq_mul, Finset.prod_mul_distrib] }
  let Ψ : G →+ AddChar G ℂ :=
    { toFun := fun g => (φ (e' g)).compAddMonoidHom e'.toAddMonoidHom
      map_zero' := by ext x; simp [φ, -AddChar.zmodAddEquiv_apply]
      map_add' := fun g h => by
        ext x; simp [φ, -AddChar.zmodAddEquiv_apply, Finset.prod_mul_distrib] }
  have hinj : Function.Injective Ψ := by
    rw [injective_iff_map_eq_zero]
    intro g hg
    apply e'.injective
    rw [map_zero]
    funext i
    have key : ∀ y : ZMod (n i), AddChar.zmodAddEquiv (e' g i) y = 1 := by
      intro y
      have := DFunLike.congr_fun hg (e'.symm (Pi.single i y))
      simp only [Ψ, φ, AddMonoidHom.coe_mk, ZeroHom.coe_mk, AddChar.compAddMonoidHom_apply,
        AddEquiv.coe_toAddMonoidHom, AddEquiv.apply_symm_apply, AddChar.coe_mk,
        AddChar.zero_apply] at this
      rw [Finset.prod_eq_single i] at this
      · simpa using this
      · intro j _ hj; simp [hj]
      · simp
    have : AddChar.zmodAddEquiv (e' g i) = 0 := AddChar.eq_zero_iff.2 key
    exact (map_eq_zero_iff _ AddChar.zmodAddEquiv.injective).1 this
  have hbij : Function.Bijective Ψ := by
    rw [Fintype.bijective_iff_injective_and_card]
    exact ⟨hinj, (AddChar.card_eq).symm⟩
  exact ⟨AddEquiv.ofBijective Ψ hbij⟩

theorem fourier_sum_norm_le_ncard_mul {α : Type*} [Fintype α] (φ : α → ℂ) (B : ℝ)
    (hB : ∀ a, ‖φ a‖ ≤ B) : ∑ a, ‖φ a‖ ≤ (Function.support φ).ncard * B := by
  classical
  have hs : (Function.support φ).ncard = (Finset.univ.filter (fun a => φ a ≠ 0)).card := by
    rw [← Set.ncard_coe_finset]; congr 1; ext a; simp
  rw [hs]
  calc ∑ a, ‖φ a‖ = ∑ a ∈ Finset.univ.filter (fun a => φ a ≠ 0), ‖φ a‖ := by
        rw [Finset.sum_filter]
        refine Finset.sum_congr rfl fun a _ => ?_
        split_ifs with h
        · rfl
        · simp only [not_not] at h; simp [h]
    _ ≤ (Finset.univ.filter (fun a => φ a ≠ 0)).card • B := Finset.sum_le_card_nsmul _ _ _ (fun a _ => hB a)
    _ = _ := by rw [nsmul_eq_mul]

/-- On a finite abelian group the characters take values of size 1; there are exactly as many
characters as members, and the dual group matches the group (by a match that needs a choice);
different characters are perpendicular and each has length 1 for the averaged inner product
`⟨f, g⟩ = (1/|G|) ∑ₓ f(x) conj(g(x))`; every function is the sum of its characters times their
amounts, `f = ∑_χ f̂(χ) χ`; and energy is kept (Plancherel):
`(1/|G|) ∑ₓ |f(x)|² = ∑_χ |f̂(χ)|²`. -/
theorem characters_orthonormal_basis_inversion_plancherel :
    (∀ (χ : AddChar G ℂ) (x : G), ‖χ x‖ = 1) ∧
    Fintype.card (AddChar G ℂ) = Fintype.card G ∧
    Nonempty (G ≃+ AddChar G ℂ) ∧
    (∀ χ : AddChar G ℂ, (Fintype.card G : ℂ)⁻¹ * ∑ x, χ x * conj (χ x) = 1) ∧
    (∀ χ ψ : AddChar G ℂ, χ ≠ ψ → (Fintype.card G : ℂ)⁻¹ * ∑ x, χ x * conj (ψ x) = 0) ∧
    (∀ (f : G → ℂ) (x : G), f x = ∑ χ : AddChar G ℂ, charTransform f χ * χ x) ∧
    (∀ f : G → ℂ,
      (Fintype.card G : ℝ)⁻¹ * ∑ x, ‖f x‖ ^ 2 = ∑ χ : AddChar G ℂ, ‖charTransform f χ‖ ^ 2) := by
  classical
  have hc : (Fintype.card G : ℂ) ≠ 0 := Nat.cast_ne_zero.2 Fintype.card_ne_zero
  refine ⟨fun χ x => AddChar.norm_apply χ x, AddChar.card_eq, fourier_exists_addEquiv,
    fun χ => ?_, fun χ ψ h => ?_, fourier_inversion_aux, fourier_plancherel_aux⟩
  · rw [fourier_sum_mul_conj, ite_eq_left_iff.2 (fun h => absurd rfl h), inv_mul_cancel₀ hc]
  · rw [fourier_sum_mul_conj, ite_eq_right_iff.2 (fun h' => absurd h' h), mul_zero]

/-- The convolution rule: the transform of a convolution is the product of the transforms,
character by character, `(f * g)^(χ) = f̂(χ) ĝ(χ)`. -/
theorem transform_conv (f g : G → ℂ) (χ : AddChar G ℂ) :
    charTransform (charConv f g) χ = charTransform f χ * charTransform g χ := by
  have h1 : ∀ y : G, ∑ x, f y * g (x - y) * conj (χ x) =
      ∑ z, f y * conj (χ y) * (g z * conj (χ z)) := by
    intro y
    refine Fintype.sum_equiv (Equiv.subRight y) _ _ fun x => ?_
    have : χ x = χ y * χ (x - y) := by
      rw [← AddChar.map_add_eq_mul]; congr 1; abel
    simp only [Equiv.subRight_apply]
    rw [this, map_mul]; ring
  have h3 : ∑ x, ((Fintype.card G : ℂ)⁻¹ * ∑ y, f y * g (x - y)) * conj (χ x) =
      (Fintype.card G : ℂ)⁻¹ * ∑ y, ∑ z, f y * conj (χ y) * (g z * conj (χ z)) := by
    simp_rw [← h1, Finset.mul_sum, Finset.sum_mul]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun y _ => Finset.sum_congr rfl fun x _ => ?_
    ring
  simp only [charTransform, charConv]
  rw [h3, mul_mul_mul_comm, Finset.sum_mul_sum]
  ring

/-- The uncertainty bound: a nonzero function and its transform cannot both be concentrated;
the number of members where `f` is nonzero times the number of characters where `f̂` is nonzero
is at least the size of the group, `|supp f| · |supp f̂| ≥ |G|`. -/
theorem card_le_support_mul_support_transform (f : G → ℂ) (hf : f ≠ 0) :
    Fintype.card G ≤ (Function.support f).ncard * (Function.support (charTransform f)).ncard := by
  classical
  have hcpos : (0 : ℝ) < Fintype.card G := Nat.cast_pos.2 Fintype.card_pos
  obtain ⟨x₀, -, hx₀⟩ := Finset.exists_max_image Finset.univ (fun x => ‖f x‖) Finset.univ_nonempty
  set M := ‖f x₀‖ with hM
  have hMpos : 0 < M := by
    by_contra h
    push Not at h
    apply hf; funext x
    have := hx₀ x (Finset.mem_univ x)
    have : ‖f x‖ = 0 := le_antisymm (this.trans h) (norm_nonneg _)
    simpa using this
  set S := (Function.support f).ncard
  set T := (Function.support (charTransform f)).ncard
  have hA : ∀ χ : AddChar G ℂ, ‖charTransform f χ‖ ≤ (Fintype.card G : ℝ)⁻¹ * (S * M) := by
    intro χ
    rw [charTransform, norm_mul, norm_inv, Complex.norm_natCast]
    gcongr
    calc ‖∑ x, f x * conj (χ x)‖ ≤ ∑ x, ‖f x * conj (χ x)‖ := norm_sum_le _ _
      _ = ∑ x, ‖f x‖ := by simp
      _ ≤ S * M := fourier_sum_norm_le_ncard_mul f M fun x => hx₀ x (Finset.mem_univ x)
  have hB : M ≤ T * ((Fintype.card G : ℝ)⁻¹ * (S * M)) := by
    calc M = ‖∑ χ : AddChar G ℂ, charTransform f χ * χ x₀‖ := by
          rw [hM, ← fourier_inversion_aux]
      _ ≤ ∑ χ : AddChar G ℂ, ‖charTransform f χ * χ x₀‖ := norm_sum_le _ _
      _ = ∑ χ : AddChar G ℂ, ‖charTransform f χ‖ := by simp
      _ ≤ T * ((Fintype.card G : ℝ)⁻¹ * (S * M)) := fourier_sum_norm_le_ncard_mul _ _ hA
  have : (Fintype.card G : ℝ) ≤ S * T := by
    have h3 : M * Fintype.card G ≤ M * (S * T) := by
      have := mul_le_mul_of_nonneg_right hB hcpos.le
      calc M * Fintype.card G ≤ T * ((Fintype.card G : ℝ)⁻¹ * (S * M)) * Fintype.card G := this
        _ = M * (S * T) := by field_simp
    exact le_of_mul_le_mul_left h3 hMpos
  exact_mod_cast this

/-! The card's whole-number worked examples. Votes are `Bool`, read as `+1` (true) and `−1`
(false); the product of two votes is `+1` exactly when they agree. -/

/-- A vote as `+1` or `−1`. -/
def vote (b : Bool) : ℤ := if b then 1 else -1

/-- Majority of three votes. -/
def maj (a b c : Bool) : ℤ := if vote a + vote b + vote c > 0 then 1 else -1

-- The expansion `Maj = ½x₁ + ½x₂ + ½x₃ − ½x₁x₂x₃` on all 8 inputs, cleared of the halves.
example : ∀ a b c : Bool,
    2 * maj a b c = vote a + vote b + vote c - vote a * vote b * vote c := by decide

-- Majority's amounts times 8: 4 on one judge (so 1/2), 0 on two judges, −4 on all three
-- (so −1/2), and 0 on no judge.
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, maj a b c * vote a) = 4 := by decide
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, maj a b c * (vote a * vote b)) = 0 := by decide
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool,
    maj a b c * (vote a * vote b * vote c)) = -4 := by decide
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, maj a b c) = 0 := by decide

-- Weights 3/4 on single judges and 1/4 on the triple, adding to the mean of Maj², which is 1.
example : (3 * (1 / 2 : ℚ) ^ 2, (-1 / 2 : ℚ) ^ 2) = (3 / 4, 1 / 4) := by norm_num
example : 3 * (1 / 2 : ℚ) ^ 2 + (-1 / 2 : ℚ) ^ 2 = 1 := by norm_num

-- One judge's influence: switching vote 1 alone changes the verdict on 4 of the 8 inputs (0.5).
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool,
    if maj a b c ≠ maj (!a) b c then (1 : ℕ) else 0) = 4 := by decide

-- Each vote misread with chance 1/10: counted over all inputs and misreadings, the verdict
-- flips with chance 1088 / 8000 = 0.136 (a misreading pattern with k misread votes has
-- weight 9^(3 − k) / 1000) ...
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, ∑ e₁ : Bool, ∑ e₂ : Bool, ∑ e₃ : Bool,
    if maj a b c ≠ maj (xor a e₁) (xor b e₂) (xor c e₃) then
      9 ^ ((if e₁ then 0 else 1) + (if e₂ then 0 else 1) + (if e₃ then 0 else 1))
    else (0 : ℕ)) = 1088 := by decide
-- ... and read off the weights, ½ − ½(¾ · 0.8 + ¼ · 0.8³) = 17/125 = 0.136.
example : (1 / 2 : ℚ) - 1 / 2 * (3 / 4 * (4 / 5) + 1 / 4 * (4 / 5) ^ 3) = 17 / 125 := by norm_num
example : (1088 : ℚ) / 8000 = 17 / 125 := by norm_num

-- The linearity test Maj(x)Maj(y) = Maj(xy) passes on 40 of the 64 pairs (0.625), and the
-- weights give ½ + ½(3 · (1/2)³ − (1/2)³) = 5/8.
example : (∑ a : Bool, ∑ b : Bool, ∑ c : Bool, ∑ a' : Bool, ∑ b' : Bool, ∑ c' : Bool,
    if maj a b c * maj a' b' c' = maj (a == a') (b == b') (c == c') then (1 : ℕ) else 0)
      = 40 := by decide
example : (1 / 2 : ℚ) + 1 / 2 * (3 * (1 / 2) ^ 3 - (1 / 2) ^ 3) = 5 / 8 := by norm_num
example : (40 : ℚ) / 64 = 5 / 8 := by norm_num

-- The clock ℤ/12 splits as ℤ/4 × ℤ/3: hour k comes back from (k mod 4, k mod 3)
-- as (9 k₁ + 4 k₂) mod 12.
example : ∀ k : Fin 12, (9 * (k.val % 4) + 4 * (k.val % 3)) % 12 = k.val := by decide

-- The labels j = (3a + 4b) mod 12, for a < 4 and b < 3, hit all 12 characters.
example : ((Finset.range 4 ×ˢ Finset.range 3).image
    (fun p : ℕ × ℕ => (3 * p.1 + 4 * p.2) % 12)) = Finset.range 12 := by decide

-- Four characters need all 12 steps (χ₁, χ₅, χ₇, χ₁₁): 4 ways to match ℤ/12 with its dual.
example : ((Finset.range 12).filter (fun j => Nat.Coprime j 12)) = {1, 5, 7, 11} := by decide

-- The quarter marks H = {0, 3, 6, 9}: the characters χ_j equal to 1 on H are those with
-- 3j ≡ 0 mod 12, namely j = 0, 4, 8, so the support product is 4 × 3 = 12.
example : ((Finset.univ : Finset (ZMod 12)).filter (fun k => 3 ∣ k.val)).card = 4 := by decide
example : ((Finset.univ : Finset (ZMod 12)).filter (fun j => 3 * j = 0)) = {0, 4, 8} := by decide

#print axioms fourier_sum_mul_conj
#print axioms fourier_inversion_aux
#print axioms fourier_plancherel_aux
#print axioms fourier_exists_addEquiv
#print axioms fourier_sum_norm_le_ncard_mul
#print axioms characters_orthonormal_basis_inversion_plancherel
#print axioms transform_conv
#print axioms card_le_support_mul_support_transform
