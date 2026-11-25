-- Andre-Oort and o-minimality: this file proves that the parabola y = x^2 on [0, 1] has 1 + phi(1) + ... + phi(floor(sqrt T)) rational points of height at most T, that y = 2^x on [0, 1] has only the rational points (0, 1) and (1, 2), and that special points give rational coordinates of height at most 2|D|.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Nat.Totient
import Mathlib.Data.Set.Card
import Mathlib.NumberTheory.Padics.PadicVal.Basic

/-- The height of a fraction in lowest terms: the larger of the size of its top and its bottom. -/
def height (x : ℚ) : ℕ := max x.num.natAbs x.den

/-- The level-2 modular polynomial `Φ₂(X, Y)`, which vanishes at every pair `(j(τ), j(2τ))`. -/
def phi2 (X Y : ℤ) : ℤ :=
  X ^ 3 + Y ^ 3 - X ^ 2 * Y ^ 2 + 1488 * (X ^ 2 * Y + X * Y ^ 2) - 162000 * (X ^ 2 + Y ^ 2)
    + 40773375 * X * Y + 8748000000 * (X + Y) - 157464000000000

lemma unit_height_max (x : ℚ) (h0 : 0 ≤ x) (h1 : x ≤ 1) :
    max (height x) (height (x ^ 2)) = x.den ^ 2 := by
  have hn : 0 ≤ x.num := Rat.num_nonneg.mpr h0
  have hle : x.num ≤ x.den := by
    have hq : x * (x.den : ℚ) = x.num := Rat.mul_den_eq_num x
    have hd : (0 : ℚ) < x.den := by exact_mod_cast x.den_pos
    have : (x.num : ℚ) ≤ x.den := by rw [← hq]; nlinarith
    exact_mod_cast this
  have h1' : x.num.natAbs ≤ x.den := by omega
  have h2' : (x.num ^ 2).natAbs ≤ x.den ^ 2 := by
    rw [Int.natAbs_pow]; exact Nat.pow_le_pow_left h1' 2
  unfold height
  rw [Rat.num_pow, Rat.den_pow, max_eq_right h1', max_eq_right h2']
  exact max_eq_right (by nlinarith [x.den_pos])

lemma coprime_div_num_den (b a : ℕ) (hb : 0 < b) (h : b.Coprime a) :
    ((a : ℚ) / (b : ℚ)).num = a ∧ ((a : ℚ) / (b : ℚ)).den = b := by
  have e : ((a : ℚ) / (b : ℚ)) = (((a : ℤ) : ℚ) / ((b : ℤ) : ℚ)) := by push_cast; rfl
  have hc : Nat.Coprime (a : ℤ).natAbs (b : ℤ).natAbs := by simpa using h.symm
  have hb' : (0 : ℤ) < b := by exact_mod_cast hb
  rw [e]
  refine ⟨Rat.num_div_eq_of_coprime hb' hc, ?_⟩
  have := Rat.den_div_eq_of_coprime hb' hc
  exact_mod_cast this

#print axioms unit_height_max
#print axioms coprime_div_num_den

lemma height_intDiv_le (n d : ℤ) (hd : 0 < d) :
    height ((n : ℚ) / (d : ℚ)) ≤ max n.natAbs d.natAbs := by
  rw [← Rat.divInt_eq_div]
  unfold height
  have h1 := Rat.num_dvd n hd.ne'
  have h2 := Rat.den_dvd n d
  apply max_le_max
  · rcases eq_or_ne n 0 with rfl | hn
    · simp
    · exact Nat.le_of_dvd (Int.natAbs_pos.mpr hn) (Int.natAbs_dvd_natAbs.mpr h1)
  · have := Int.le_of_dvd hd h2
    omega

#print axioms height_intDiv_le

lemma two_rpow_den_eq_one (x y : ℚ) (h0 : 0 ≤ x) (h : (2 : ℝ) ^ (x : ℝ) = (y : ℝ)) :
    x.den = 1 := by
  have hn : 0 ≤ x.num := Rat.num_nonneg.mpr h0
  have hq : x * (x.den : ℚ) = ((x.num.natAbs : ℕ) : ℚ) := by
    rw [Rat.mul_den_eq_num, Nat.cast_natAbs, abs_of_nonneg hn]
  have hr : (x : ℝ) * (x.den : ℝ) = ((x.num.natAbs : ℕ) : ℝ) := by exact_mod_cast hq
  have hyR : (y : ℝ) ^ x.den = (2 : ℝ) ^ x.num.natAbs := by
    rw [← h, ← Real.rpow_mul_natCast (by norm_num), hr, Real.rpow_natCast]
  have hyQ : y ^ x.den = (2 : ℚ) ^ x.num.natAbs := by exact_mod_cast hyR
  have hnum : y.num ^ x.den = (2 : ℤ) ^ x.num.natAbs := by
    have := congrArg Rat.num hyQ
    rw [Rat.num_pow] at this
    rw [this]
    have e : (2 : ℚ) ^ x.num.natAbs = ((2 ^ x.num.natAbs : ℤ) : ℚ) := by push_cast; rfl
    rw [e, Rat.num_intCast]
  have hnat : y.num.natAbs ^ x.den = 2 ^ x.num.natAbs := by
    have := congrArg Int.natAbs hnum
    simpa [Int.natAbs_pow] using this
  have hv := congrArg (padicValNat 2) hnat
  rw [padicValNat.pow, padicValNat.prime_pow] at hv
  have hdvd : x.den ∣ x.num.natAbs := ⟨_, hv.symm⟩
  exact Nat.Coprime.eq_one_of_dvd x.reduced.symm hdvd

#print axioms two_rpow_den_eq_one

/-- The algebraic part keeps a power of `T`: for every `T ≥ 1`, the parabola `y = x²` with
`0 ≤ x ≤ 1` has exactly `1 + φ(1) + φ(2) + ... + φ(⌊√T⌋)` rational points `(x, y)` of height
at most `T`, where `φ` is Euler's totient. -/
theorem parabola_rational_points_count (T : ℕ) (hT : 1 ≤ T) :
    Set.ncard {p : ℚ × ℚ | 0 ≤ p.1 ∧ p.1 ≤ 1 ∧ p.2 = p.1 ^ 2 ∧
        max (height p.1) (height p.2) ≤ T} =
      1 + ∑ b ∈ Finset.Icc 1 (Nat.sqrt T), b.totient := by
  set N := Nat.sqrt T
  let A : Set ℚ := {x | 0 ≤ x ∧ x ≤ 1 ∧ x.den ≤ N}
  have hS : {p : ℚ × ℚ | 0 ≤ p.1 ∧ p.1 ≤ 1 ∧ p.2 = p.1 ^ 2 ∧
        max (height p.1) (height p.2) ≤ T} = (fun x : ℚ => (x, x ^ 2)) '' A := by
    ext ⟨x, y⟩
    simp only [Set.mem_ofPred_eq, Set.mem_image, Prod.mk.injEq, A]
    constructor
    · rintro ⟨h0, h1, rfl, hT'⟩
      refine ⟨x, ⟨h0, h1, ?_⟩, rfl, rfl⟩
      rw [unit_height_max x h0 h1] at hT'
      exact Nat.le_sqrt'.mpr hT'
    · rintro ⟨z, ⟨h0, h1, hz⟩, rfl, rfl⟩
      refine ⟨h0, h1, rfl, ?_⟩
      rw [unit_height_max z h0 h1]
      exact Nat.le_sqrt'.mp hz
  let F : Finset (Σ _ : ℕ, ℕ) :=
    (Finset.Icc 1 N).sigma (fun b => (Finset.range b).filter (fun a => b.Coprime a))
  let g : (Σ _ : ℕ, ℕ) → ℚ := fun p => (p.2 : ℚ) / (p.1 : ℚ)
  have memF : ∀ p ∈ F, 1 ≤ p.1 ∧ p.1 ≤ N ∧ p.2 < p.1 ∧ p.1.Coprime p.2 := by
    intro p hp
    simp only [F, Finset.mem_sigma, Finset.mem_Icc, Finset.mem_filter, Finset.mem_range] at hp
    exact ⟨hp.1.1, hp.1.2, hp.2.1, hp.2.2⟩
  have hA : A = insert 1 (g '' (F : Set (Σ _ : ℕ, ℕ))) := by
    ext x
    simp only [Set.mem_insert_iff, Set.mem_image, Finset.mem_coe, A, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨h0, h1, hd⟩
      rcases eq_or_lt_of_le h1 with e | hlt
      · exact Or.inl e
      right
      have hn : 0 ≤ x.num := Rat.num_nonneg.mpr h0
      have hlt' : x.num < x.den := by
        have hq : x * (x.den : ℚ) = x.num := Rat.mul_den_eq_num x
        have hd : (0 : ℚ) < x.den := by exact_mod_cast x.den_pos
        have : (x.num : ℚ) < x.den := by rw [← hq]; nlinarith
        exact_mod_cast this
      refine ⟨⟨x.den, x.num.natAbs⟩, ?_, ?_⟩
      · simp only [F, Finset.mem_sigma, Finset.mem_Icc, Finset.mem_filter, Finset.mem_range]
        exact ⟨⟨x.den_pos, hd⟩, by omega, x.reduced.symm⟩
      · simp only [g]
        rw [Nat.cast_natAbs, abs_of_nonneg hn]
        exact Rat.num_div_den x
    · rintro (rfl | ⟨p, hp, rfl⟩)
      · refine ⟨zero_le_one, le_rfl, ?_⟩
        simpa using Nat.le_sqrt'.mpr (by simpa using hT)
      · obtain ⟨hb1, hbN, hab, hc⟩ := memF p hp
        have hb : 0 < p.1 := hb1
        have hbQ : (0 : ℚ) < p.1 := by exact_mod_cast hb
        refine ⟨by simp only [g]; positivity, ?_, ?_⟩
        · simp only [g]
          rw [div_le_one hbQ]
          exact_mod_cast hab.le
        · simp only [g]
          rw [(coprime_div_num_den p.1 p.2 hb hc).2]
          exact hbN
  have hinj : Set.InjOn g (F : Set (Σ _ : ℕ, ℕ)) := by
    rintro ⟨b, a⟩ hp ⟨b', a'⟩ hp' he
    obtain ⟨hb1, -, -, hc⟩ := memF _ hp
    obtain ⟨hb1', -, -, hc'⟩ := memF _ hp'
    simp only [g] at he
    have k := coprime_div_num_den b a hb1 hc
    have k' := coprime_div_num_den b' a' hb1' hc'
    rw [he] at k
    have e1 : b = b' := k.2.symm.trans k'.2
    have e2 : (a : ℤ) = a' := k.1.symm.trans k'.1
    have e2' : a = a' := by exact_mod_cast e2
    subst e1; subst e2'; rfl
  have h1 : (1 : ℚ) ∉ g '' (F : Set (Σ _ : ℕ, ℕ)) := by
    rintro ⟨p, hp, he⟩
    obtain ⟨hb1, -, hab, -⟩ := memF p hp
    simp only [g] at he
    have hbQ : (0 : ℚ) < p.1 := by exact_mod_cast hb1
    rw [div_eq_one_iff_eq hbQ.ne'] at he
    have : p.2 = p.1 := by exact_mod_cast he
    omega
  rw [hS, Set.ncard_image_of_injective _ (fun x y h => (Prod.mk.inj h).1), hA,
    Set.ncard_insert_of_notMem h1, hinj.ncard_image, Set.ncard_coe_finset,
    Finset.card_sigma, add_comm]
  rfl

/-- The graph of `y = 2^x` on `[0, 1]` has no algebraic piece, and its only rational points
are `(0, 1)` and `(1, 2)`: if `2^(a/b)` were a fraction, then `b` divides `a`. -/
theorem two_pow_rational_points :
    {p : ℚ × ℚ | 0 ≤ p.1 ∧ p.1 ≤ 1 ∧ (2 : ℝ) ^ (p.1 : ℝ) = (p.2 : ℝ)} = {(0, 1), (1, 2)} := by
  ext ⟨x, y⟩
  simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff, Prod.mk.injEq]
  constructor
  · rintro ⟨h0, h1, h⟩
    have hd := two_rpow_den_eq_one x y h0 h
    have hx : (x.num : ℚ) = x := (Rat.den_eq_one_iff x).mp hd
    have hn0 : 0 ≤ x.num := Rat.num_nonneg.mpr h0
    have hn1 : x.num ≤ 1 := by
      have : (x.num : ℚ) ≤ 1 := hx ▸ h1
      exact_mod_cast this
    have : x.num = 0 ∨ x.num = 1 := by omega
    rcases this with e | e
    · rw [e] at hx
      have hx0 : x = 0 := by rw [← hx]; simp
      subst hx0
      left
      refine ⟨rfl, ?_⟩
      simp at h
      exact_mod_cast h.symm
    · rw [e] at hx
      have hx1 : x = 1 := by rw [← hx]; simp
      subst hx1
      right
      refine ⟨rfl, ?_⟩
      simp at h
      exact_mod_cast h.symm
  · rintro (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩) <;> norm_num

/-- A special point with reduced form `(a, b, c)`, so `b² - 4ac = D < 0` and `|b| ≤ a ≤ c`,
gives the rational point `(x, y²) = (-b/(2a), |D|/(4a²))`, and both coordinates have height
at most `2|D|`. -/
theorem special_point_height_le (a b c D : ℤ) (hD : b ^ 2 - 4 * a * c = D) (hneg : D < 0)
    (hba : |b| ≤ a) (hac : a ≤ c) :
    height ((-b : ℚ) / (2 * a)) ≤ 2 * D.natAbs ∧
      height ((|D| : ℚ) / (4 * a ^ 2)) ≤ 2 * D.natAbs := by
  have hb0 : 0 ≤ |b| := abs_nonneg b
  have hb2 : b ^ 2 ≤ a ^ 2 := by
    rw [← sq_abs]; exact pow_le_pow_left₀ hb0 hba 2
  have ha : 0 < a := by
    rcases lt_or_ge 0 a with h | h
    · exact h
    · exfalso
      have : b = 0 := abs_nonpos_iff.mp (le_trans hba h)
      subst this
      have : a = 0 := le_antisymm h (by simpa using hba)
      subst this
      simp at hD; omega
  have hac' : a * a ≤ a * c := mul_le_mul_of_nonneg_left hac ha.le
  have hDabs : (D.natAbs : ℤ) = -D := by omega
  have h3 : 3 * a ^ 2 ≤ -D := by nlinarith
  have ha1 : a ≤ a ^ 2 := by nlinarith
  constructor
  · have e : ((-b : ℚ) / (2 * a)) = (((-b : ℤ) : ℚ) / ((2 * a : ℤ) : ℚ)) := by push_cast; ring
    rw [e]
    refine le_trans (height_intDiv_le _ _ (by omega)) (max_le ?_ ?_)
    · have : ((-b).natAbs : ℤ) = |b| := by simp
      omega
    · have : ((2 * a).natAbs : ℤ) = 2 * a := by omega
      omega
  · have e : ((|D| : ℚ) / (4 * a ^ 2)) = (((-D : ℤ) : ℚ) / ((4 * a ^ 2 : ℤ) : ℚ)) := by
      rw [abs_of_neg (by exact_mod_cast hneg)]; push_cast; ring
    rw [e]
    refine le_trans (height_intDiv_le _ _ (by positivity)) (max_le ?_ ?_)
    · omega
    · have : ((4 * a ^ 2).natAbs : ℤ) = 4 * a ^ 2 := by
        rw [Int.natAbs_of_nonneg (by positivity)]
      omega

/-! Worked examples from the card, checked exactly. -/

-- The parabola count: 33 points at T = 100 and 3045 at T = 10^4.
example : 1 + ∑ b ∈ Finset.Icc 1 (Nat.sqrt 100), b.totient = 33 := by decide +kernel
example : 1 + ∑ b ∈ Finset.Icc 1 (Nat.sqrt 10000), b.totient = 3045 := by decide +kernel

-- Special pairs on Φ₂ = 0: (j(i), j(2i)) = (1728, 287496), and others from the card.
example : phi2 1728 287496 = 0 := by decide
example : phi2 0 54000 = 0 := by decide
example : phi2 (-3375) 16581375 = 0 := by decide
example : phi2 1728 1728 = 0 := by decide
example : phi2 (-3375) (-3375) = 0 := by decide
example : phi2 8000 8000 = 0 := by decide

-- Among the 11 special values of size under 10^9, 9 ordered pairs lie on Φ₂ = 0,
-- and 2 lie on the line X + Y = 1728.
def smallSpecial : List ℤ :=
  [0, 1728, -3375, 8000, -32768, 54000, 287496, -884736, -12288000, 16581375, -884736000]

example : ((smallSpecial.product smallSpecial).filter (fun p => phi2 p.1 p.2 = 0)).length = 9 := by
  decide
example : ((smallSpecial.product smallSpecial).filter (fun p => p.1 + p.2 = 1728)).length = 2 := by
  decide

-- D = -15: the reduced form (2, 1, 2) gives (x, y²) = (-1/4, 15/16), of height 16.
example : height ((-1 : ℚ) / 4) = 4 ∧ height ((15 : ℚ) / 16) = 16 := by decide +kernel

#print axioms parabola_rational_points_count
#print axioms two_pow_rational_points
#print axioms special_point_height_le
