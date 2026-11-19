-- Adding points by formula: the Jacobian doubling and mixed-addition formulas on y^2 = x^3 + b give exactly the chord-and-tangent sum, and double-and-add reaches nP with (digits - 1) doublings and (ones - 1) additions.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.Data.Nat.Digits.Defs
import Mathlib.Data.Nat.Digits.Lemmas
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum

open WeierstrassCurve.Affine

/-- The short Weierstrass curve `y^2 = x^3 + b`, that is `y^2 = x^3 + a x + b` with `a = 0`. -/
abbrev shortCurve {F : Type*} [Field F] (b : F) : WeierstrassCurve.Affine F :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := 0, a₆ := b }

/-- Doubling in Jacobian coordinates, for `a = 0`, as on the card. -/
def jacDouble {F : Type*} [CommRing F] (X Y Z : F) : F × F × F :=
  let S := 4 * X * Y ^ 2
  let T := 3 * X ^ 2
  let X₃ := T ^ 2 - 2 * S
  (X₃, T * (S - X₃) - 8 * Y ^ 4, 2 * Y * Z)

/-- Mixed addition: the Jacobian point `(X : Y : Z)` plus the affine point `(x₂, y₂)`. -/
def jacAddMixed {F : Type*} [CommRing F] (X Y Z x₂ y₂ : F) : F × F × F :=
  let H := x₂ * Z ^ 2 - X
  let R := y₂ * Z ^ 3 - Y
  let X₃ := R ^ 2 - H ^ 3 - 2 * X * H ^ 2
  (X₃, R * (X * H ^ 2 - X₃) - Y * H ^ 3, Z * H)

/-- Equal coordinates give equal points. -/
theorem point_some_eq_of_coords {F : Type*} [Field F] {W : WeierstrassCurve.Affine F}
    {x y x' y' : F} (h : W.Nonsingular x y) (hx : x = x') (hy : y = y') :
    ∃ h' : W.Nonsingular x' y', Point.some _ _ h = Point.some _ _ h' :=
  ⟨hx ▸ hy ▸ h, by subst hx hy; rfl⟩

#print axioms point_some_eq_of_coords

/-- Every positive number has a binary digit equal to 1. -/
theorem one_mem_digits_two {m : ℕ} (hm : m ≠ 0) : 1 ∈ Nat.digits 2 m := by
  have hne : Nat.digits 2 m ≠ [] := Nat.digits_ne_nil_iff_ne_zero.mpr hm
  have hmem := List.getLast_mem hne
  have hlt := Nat.digits_lt_base (by norm_num) hmem
  have h0 := Nat.getLast_digit_ne_zero 2 hm
  have : (Nat.digits 2 m).getLast hne = 1 := by omega
  rw [← this]; exact hmem

#print axioms one_mem_digits_two

/-- Doubling in Jacobian coordinates is correct. On `y^2 = x^3 + b` over a field where `2 ≠ 0` and
`3 ≠ 0`, let `P` be the point with Jacobian coordinates `(X : Y : Z)`, `Z ≠ 0`, that is
`x = X/Z^2`, `y = Y/Z^3`. Put `S = 4XY^2`, `T = 3X^2`, `X₃ = T^2 - 2S`, `Y₃ = T(S - X₃) - 8Y^4`,
`Z₃ = 2YZ`. If `Z₃ = 0` then `2P = O`; otherwise `2P` is the affine point `(X₃/Z₃^2, Y₃/Z₃^3)`. -/
theorem jacobian_doubling_eq_two_smul {F : Type*} [Field F] [DecidableEq F]
    (h2 : (2 : F) ≠ 0) (h3 : (3 : F) ≠ 0) (b X Y Z : F) (hZ : Z ≠ 0)
    (hP : (shortCurve b).Nonsingular (X / Z ^ 2) (Y / Z ^ 3)) :
    let J := jacDouble X Y Z
    (J.2.2 = 0 → Point.some _ _ hP + Point.some _ _ hP = 0) ∧
    (J.2.2 ≠ 0 → ∃ h₃ : (shortCurve b).Nonsingular (J.1 / J.2.2 ^ 2) (J.2.1 / J.2.2 ^ 3),
      Point.some _ _ hP + Point.some _ _ hP = Point.some _ _ h₃) := by
  intro J
  simp only [J, jacDouble]
  constructor
  · intro h0
    have hY : Y = 0 := by
      rcases mul_eq_zero.mp h0 with h | h
      · rcases mul_eq_zero.mp h with h | h
        · exact absurd h h2
        · exact h
      · exact absurd h hZ
    apply Point.add_self_of_Y_eq
    simp [WeierstrassCurve.Affine.negY, hY]
  · intro h0
    have hY : Y ≠ 0 := by
      intro hY; apply h0; simp [hY]
    have hy : Y / Z ^ 3 ≠ (shortCurve b).negY (X / Z ^ 2) (Y / Z ^ 3) := by
      simp only [WeierstrassCurve.Affine.negY]
      intro h
      have : 2 * (Y / Z ^ 3) = 0 := by simp at h; linear_combination h
      simp [h2, hY, hZ] at this
    rw [Point.add_self_of_Y_ne hy]
    have hl : (shortCurve b).slope (X / Z ^ 2) (X / Z ^ 2) (Y / Z ^ 3) (Y / Z ^ 3) =
        3 * X ^ 2 / (2 * Y * Z) := by
      rw [WeierstrassCurve.Affine.slope_of_Y_ne rfl hy]
      simp only [WeierstrassCurve.Affine.negY]
      rw [div_eq_div_iff]
      · field_simp; ring
      · intro h; apply hy; simp only [WeierstrassCurve.Affine.negY]; linear_combination h
      · exact h0
    apply point_some_eq_of_coords
    · rw [hl]
      simp only [WeierstrassCurve.Affine.addX]
      field_simp
      ring
    · rw [hl]
      simp only [WeierstrassCurve.Affine.addY, WeierstrassCurve.Affine.negAddY,
        WeierstrassCurve.Affine.addX, WeierstrassCurve.Affine.negY]
      field_simp
      ring

/-- Mixed addition in Jacobian coordinates is correct. On `y^2 = x^3 + b` over a field where
`2 ≠ 0` and `3 ≠ 0`, let `P` have Jacobian coordinates `(X : Y : Z)`, `Z ≠ 0`, and let `Q = (x₂, y₂)`
be affine, with `P ≠ Q`. Put `H = x₂Z^2 - X`, `R = y₂Z^3 - Y`, `X₃ = R^2 - H^3 - 2XH^2`,
`Y₃ = R(XH^2 - X₃) - YH^3`, `Z₃ = ZH`. If `Z₃ = 0` then `P + Q = O`; otherwise `P + Q` is the affine
point `(X₃/Z₃^2, Y₃/Z₃^3)`. -/
theorem jacobian_mixed_addition_eq_add {F : Type*} [Field F] [DecidableEq F]
    (h2 : (2 : F) ≠ 0) (h3 : (3 : F) ≠ 0) (b X Y Z x₂ y₂ : F) (hZ : Z ≠ 0)
    (hP : (shortCurve b).Nonsingular (X / Z ^ 2) (Y / Z ^ 3))
    (hQ : (shortCurve b).Nonsingular x₂ y₂) (hne : Point.some _ _ hP ≠ Point.some _ _ hQ) :
    let J := jacAddMixed X Y Z x₂ y₂
    (J.2.2 = 0 → Point.some _ _ hP + Point.some _ _ hQ = 0) ∧
    (J.2.2 ≠ 0 → ∃ h₃ : (shortCurve b).Nonsingular (J.1 / J.2.2 ^ 2) (J.2.1 / J.2.2 ^ 3),
      Point.some _ _ hP + Point.some _ _ hQ = Point.some _ _ h₃) := by
  intro J
  simp only [J, jacAddMixed]
  constructor
  · intro h0
    have hH : x₂ * Z ^ 2 - X = 0 := by
      rcases mul_eq_zero.mp h0 with h | h
      · exact absurd h hZ
      · exact h
    have hx : X / Z ^ 2 = x₂ := by
      field_simp; linear_combination -hH
    rcases WeierstrassCurve.Affine.Y_eq_of_X_eq hP.1 hQ.1 hx with hy | hy
    · exact absurd (by subst hx hy; rfl) hne
    · exact Point.add_of_Y_eq hx hy
  · intro h0
    have hH : x₂ * Z ^ 2 - X ≠ 0 := by
      intro h; apply h0; simp [h]
    have hx : X / Z ^ 2 ≠ x₂ := by
      intro h; apply hH; rw [← h]; field_simp; ring
    rw [Point.add_of_X_ne hx]
    have hl : (shortCurve b).slope (X / Z ^ 2) x₂ (Y / Z ^ 3) y₂ =
        (y₂ * Z ^ 3 - Y) / (Z * (x₂ * Z ^ 2 - X)) := by
      rw [WeierstrassCurve.Affine.slope_of_X_ne hx]
      rw [div_eq_div_iff (sub_ne_zero.mpr hx) h0]
      field_simp; ring
    apply point_some_eq_of_coords
    all_goals
      rw [hl]
      simp only [WeierstrassCurve.Affine.addY, WeierstrassCurve.Affine.negAddY,
        WeierstrassCurve.Affine.addX, WeierstrassCurve.Affine.negY]
      clear hl hne hP hQ h0 hx
      obtain ⟨H, hHdef⟩ : ∃ H, H = x₂ * Z ^ 2 - X := ⟨_, rfl⟩
      have hx2 : x₂ = (X + H) / Z ^ 2 := by rw [hHdef]; field_simp; ring
      rw [← hHdef] at hH
      subst hx2
      have e : (X + H) / Z ^ 2 * Z ^ 2 - X = H := by field_simp; ring
      simp only [e]
      field_simp
      ring

/-- One step of double-and-add: double the running point, and add `P` if the digit is 1.
The state also counts doublings and additions. -/
def dblAddStep {G : Type*} [AddMonoid G] (P : G) (s : G × ℕ × ℕ) (d : ℕ) : G × ℕ × ℕ :=
  if d = 1 then (s.1 + s.1 + P, s.2.1 + 1, s.2.2 + 1) else (s.1 + s.1, s.2.1 + 1, s.2.2)

/-- Double-and-add: read the binary digits of `n` from the top, start at `P` on the top digit,
and run one step for each later digit. Returns the point, the doublings and the additions. -/
def doubleAndAdd {G : Type*} [AddMonoid G] (P : G) (n : ℕ) : G × ℕ × ℕ :=
  ((Nat.digits 2 n).reverse.tail).foldl (dblAddStep P) (P, 0, 0)

/-- Double-and-add reaches `nP` for every `n ≥ 1`, using one doubling for every binary digit after
the first and one addition for every 1 after the first. -/
theorem double_and_add_eq_nsmul {G : Type*} [AddMonoid G] (P : G) (n : ℕ) (hn : 1 ≤ n) :
    doubleAndAdd P n = (n • P, (Nat.digits 2 n).length - 1, (Nat.digits 2 n).count 1 - 1) := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    rcases Nat.lt_or_ge n 2 with hlt | hge
    · obtain rfl : n = 1 := by omega
      simp [doubleAndAdd]
    · have hm : 1 ≤ n / 2 := by omega
      have ih' := ih (n / 2) (by omega) hm
      have hd : Nat.digits 2 n = n % 2 :: Nat.digits 2 (n / 2) :=
        Nat.digits_def' (by norm_num) (by omega)
      have hne : Nat.digits 2 (n / 2) ≠ [] := Nat.digits_ne_nil_iff_ne_zero.mpr (by omega)
      have hlen : 1 ≤ (Nat.digits 2 (n / 2)).length := by
        rcases h : Nat.digits 2 (n / 2) with _ | ⟨a, l⟩
        · exact absurd h hne
        · simp
      have hcnt : 1 ≤ (Nat.digits 2 (n / 2)).count 1 :=
        List.count_pos_iff.mpr (one_mem_digits_two (by omega))
      have htail : (Nat.digits 2 n).reverse.tail =
          (Nat.digits 2 (n / 2)).reverse.tail ++ [n % 2] := by
        rw [hd, List.reverse_cons]
        rcases h : (Nat.digits 2 (n / 2)).reverse with _ | ⟨a, l⟩
        · simp at h; exact absurd h hne
        · simp
      unfold doubleAndAdd at ih' ⊢
      rw [htail, List.foldl_append, ih', hd]
      simp only [List.foldl_cons, List.foldl_nil, dblAddStep, List.length_cons, List.count_cons]
      rcases Nat.mod_two_eq_zero_or_one n with h | h
      · have hn2 : n = 2 * (n / 2) := by omega
        rw [h]
        simp only [zero_ne_one, ite_false, beq_iff_eq, add_zero]
        refine Prod.ext ?_ (Prod.ext ?_ ?_)
        · simp only
          conv_rhs => rw [hn2]
          rw [two_mul, add_nsmul]
        · simp only; omega
        · simp only
      · have hn2 : n = 2 * (n / 2) + 1 := by omega
        rw [h]
        simp only [ite_true, beq_self_eq_true]
        refine Prod.ext ?_ (Prod.ext ?_ ?_)
        · simp only
          conv_rhs => rw [hn2]
          rw [two_mul, add_nsmul, add_nsmul, one_nsmul]
        · simp only; omega
        · simp only; omega

-- P = (3, 5) is on y^2 = x^3 - 2.
example : (5 : ℤ) ^ 2 = 3 ^ 3 - 2 := by norm_num

-- Jacobian doubling of (3 : 5 : 1) over the fractions gives (129 : -383 : 10).
example : jacDouble (3 : ℚ) 5 1 = (129, -383, 10) := by norm_num [jacDouble]

-- The tangent rule over the fractions: slope 27/10 and 2P = (129/100, -383/1000).
example : (3 * 3 ^ 2 : ℚ) / (2 * 5) = 27 / 10 ∧ (27 / 10 : ℚ) ^ 2 - 2 * 3 = 129 / 100 ∧
    (27 / 10 : ℚ) * (3 - 129 / 100) - 5 = -383 / 1000 := by norm_num

-- Mixed addition 2P + P from (129 : -383 : 10): 3P = (16432300 : -66234835000 : 1710).
example : jacAddMixed (129 : ℚ) (-383) 10 3 5 = (16432300, -66234835000, 1710) := by
  norm_num [jacAddMixed]

-- 3P in lowest terms: x = 164323/29241, y = -66234835/5000211.
example : (16432300 : ℚ) / 1710 ^ 2 = 164323 / 29241 ∧
    (-66234835000 : ℚ) / 1710 ^ 3 = -66234835 / 5000211 := by norm_num

-- 1000 = 1111101000 in binary: 9 doublings + 5 additions = 14 curve operations.
example : Nat.digits 2 1000 = [0, 0, 0, 1, 0, 1, 1, 1, 1, 1] := by norm_num
example : doubleAndAdd (1 : ℕ) 1000 = (1000, 9, 5) := by decide

-- Modulo 1087, the Jacobian run ends at (1003 : 151 : 244).
example : (List.foldl (fun (J : ZMod 1087 × ZMod 1087 × ZMod 1087) (d : ℕ) =>
    let D := jacDouble J.1 J.2.1 J.2.2
    if d = 1 then jacAddMixed D.1 D.2.1 D.2.2 3 5 else D)
    (3, 5, 1) (Nat.digits 2 1000).reverse.tail) = (1003, 151, 244) := by decide

-- (1003 : 151 : 244) is the affine point (498, 929), and that point is on the curve mod 1087.
example : (498 : ZMod 1087) * 244 ^ 2 = 1003 ∧ (929 : ZMod 1087) * 244 ^ 3 = 151 := by decide
example : (929 : ZMod 1087) ^ 2 = 498 ^ 3 - 2 := by decide

-- 33P = (498, 158) is the mirror image of 1000P = (498, 929), so 1000P = -33P.
example : (158 : ZMod 1087) = -929 := by decide

-- 2P mod 1087 is (360, 879), the reduction of (129/100, -383/1000).
example : (360 : ZMod 1087) * 100 = 129 ∧ (879 : ZMod 1087) * 1000 = -383 := by decide

-- 1033 points sit inside Hasse's window: (1033 - 1088)^2 ≤ 4 * 1087.
example : ((1033 : ℤ) - 1088) ^ 2 ≤ 4 * 1087 := by norm_num

-- One inversion: p - 2 = 1085 = 10000111101, so 10 squarings + 5 multiplications = 15.
example : (Nat.digits 2 1085).length - 1 = 10 ∧ (Nat.digits 2 1085).count 1 - 1 = 5 := by
  norm_num

#print axioms jacobian_doubling_eq_two_smul
#print axioms jacobian_mixed_addition_eq_add
#print axioms double_and_add_eq_nsmul
