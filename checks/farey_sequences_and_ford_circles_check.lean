-- Farey fractions and Ford circles: neighbours a/b < c/d on a Farey list have b × c − a × d = 1, so their gap is 1/(b × d), their Ford circles of radius 1/(2b²) and 1/(2d²) touch, the first fraction between them is the mediant, and every irrational has infinitely many fractions p/q within 1/q².
import Mathlib.NumberTheory.DiophantineApproximation.Basic
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.LinearCombination

/-- The Farey fractions of order `N`: the fractions from 0 to 1 whose bottom, in lowest terms,
is at most `N`. A Lean rational `q` is always kept in lowest terms, with top `q.num` and
bottom `q.den`. -/
def fareySet (N : ℕ) : Set ℚ := {q | 0 ≤ q ∧ q ≤ 1 ∧ q.den ≤ N}

/-- `x` and `y` are neighbours on the Farey list of order `N`: both are on it, `x < y`, and no
fraction of the list lies strictly between them. -/
def FareyNeighbours (N : ℕ) (x y : ℚ) : Prop :=
  x ∈ fareySet N ∧ y ∈ fareySet N ∧ x < y ∧ ∀ z ∈ fareySet N, ¬ (x < z ∧ z < y)

theorem rat_eq_num_div_den' (q : ℚ) : q = (q.num : ℚ) / ((q.den : ℤ) : ℚ) := by
  rw [Int.cast_natCast]; exact (Rat.num_div_den q).symm

theorem farey_aux {N : ℕ} {x y : ℚ} (h : FareyNeighbours N x y) :
    (x.den : ℤ) * y.num - x.num * y.den = 1 := by
  obtain ⟨⟨hx0, hx1, hxN⟩, ⟨hy0, hy1, hyN⟩, hxy, hnone⟩ := h
  have hxq := rat_eq_num_div_den' x
  have hyq := rat_eq_num_div_den' y
  set a : ℤ := x.num with ha
  set b : ℤ := (x.den : ℤ) with hb
  set c : ℤ := y.num with hc
  set d : ℤ := (y.den : ℤ) with hd
  have hbpos : 0 < b := by simp [hb, x.den_pos]
  have hdpos : 0 < d := by simp [hd, y.den_pos]
  have hbq : (0 : ℚ) < (b : ℚ) := by exact_mod_cast hbpos
  have hdq : (0 : ℚ) < (d : ℚ) := by exact_mod_cast hdpos
  have hbN : b ≤ N := by simp only [hb]; exact_mod_cast hxN
  have hdN : d ≤ N := by simp only [hd]; exact_mod_cast hyN
  -- integer forms of order facts
  have ha0 : 0 ≤ a := by
    have : (0 : ℚ) ≤ (a : ℚ) / (b : ℚ) := hxq ▸ hx0
    have := (div_nonneg_iff.mp this)
    rcases this with ⟨h1, _⟩ | ⟨_, h2⟩
    · exact_mod_cast h1
    · linarith
  have hD1 : 1 ≤ b * c - a * d := by
    have : (a : ℚ) / (b : ℚ) < (c : ℚ) / (d : ℚ) := by rw [← hxq, ← hyq]; exact hxy
    rw [div_lt_div_iff₀ hbq hdq] at this
    have : a * d < c * b := by exact_mod_cast this
    linarith
  have hab : a < b := by
    have : (a : ℚ) / (b : ℚ) < 1 := by rw [← hxq]; exact lt_of_lt_of_le hxy hy1
    rw [div_lt_one hbq] at this
    exact_mod_cast this
  -- Bezout
  have hg : Int.gcd a b = 1 := by
    simpa [ha, hb, Int.gcd] using x.reduced
  have hbez := Int.gcd_eq_gcd_ab a b
  rw [hg] at hbez
  set s := Int.gcdA a b
  set t := Int.gcdB a b
  -- b * t - a * v = 1 with v = -s
  set v : ℤ := -s with hv
  set k : ℤ := ((N : ℤ) - v) / b with hk
  have hr0 : 0 ≤ ((N : ℤ) - v) % b := Int.emod_nonneg _ hbpos.ne'
  have hrb : ((N : ℤ) - v) % b < b := Int.emod_lt_of_pos _ hbpos
  have hrk : ((N : ℤ) - v) % b + b * k = (N : ℤ) - v := Int.emod_add_mul_ediv _ _
  set u' : ℤ := t + a * k with hu'
  set v' : ℤ := v + b * k with hv'
  have hbez' : b * u' - a * v' = 1 := by
    simp only [hu', hv', hv]; linear_combination hbez.symm
  have hv'N : v' ≤ N := by simp only [hv']; linarith
  have hv'lo : (N : ℤ) - b < v' := by simp only [hv']; linarith
  have hv'pos : 0 < v' := by
    have : (0 : ℤ) ≤ N - b := by linarith
    linarith
  have hu'pos : 0 < u' := by nlinarith
  have hu'v' : u' ≤ v' := by nlinarith
  have hv'q : (0 : ℚ) < (v' : ℚ) := by exact_mod_cast hv'pos
  set z : ℚ := (u' : ℚ) / (v' : ℚ) with hz
  have hzden : (z.den : ℤ) ≤ v' := by
    have h1 : ((Rat.divInt u' v').den : ℤ) ∣ v' := Rat.den_dvd u' v'
    rw [Rat.divInt_eq_div] at h1
    exact Int.le_of_dvd hv'pos h1
  have hzmem : z ∈ fareySet N := by
    refine ⟨?_, ?_, ?_⟩
    · exact div_nonneg (by exact_mod_cast hu'pos.le) hv'q.le
    · rw [div_le_one hv'q]; exact_mod_cast hu'v'
    · have : (z.den : ℤ) ≤ N := le_trans hzden hv'N
      exact_mod_cast this
  have hxz : x < z := by
    rw [hxq, hz, div_lt_div_iff₀ hbq hv'q]
    have : a * v' < u' * b := by linarith
    exact_mod_cast this
  have hyz : y ≤ z := by
    by_contra hcon
    exact hnone z hzmem ⟨hxz, lt_of_not_ge hcon⟩
  have hD2 : 0 ≤ u' * d - c * v' := by
    have : (c : ℚ) / (d : ℚ) ≤ (u' : ℚ) / (v' : ℚ) := by rw [← hyq]; exact hyz
    rw [div_le_div_iff₀ hdq hv'q] at this
    have : c * v' ≤ u' * d := by exact_mod_cast this
    linarith
  have hid : b * (u' * d - c * v') + v' * (b * c - a * d) = d := by
    linear_combination d * hbez'
  -- D2 = 0
  have hD2z : u' * d - c * v' = 0 := by
    by_contra hne
    have : 1 ≤ u' * d - c * v' := by omega
    nlinarith
  have hdv : d ∣ c * v' := ⟨u', by linarith⟩
  have hgcd : Int.gcd d c = 1 := by
    simpa [hc, hd, Int.gcd, Nat.coprime_comm] using y.reduced
  have hdv' : d ∣ v' := Int.dvd_of_dvd_mul_right_of_gcd_one hdv hgcd
  have hdle : d ≤ v' := Int.le_of_dvd hv'pos hdv'
  nlinarith

/-- Neighbours a/b < c/d on the Farey list of any order have b × c − a × d = 1, so their gap
is 1/(b × d), and their Ford circles (centre (a/b, 1/(2b²)) with radius 1/(2b²), and centre
(c/d, 1/(2d²)) with radius 1/(2d²)) just touch: the distance between the centres equals the
sum of the radii. -/
theorem farey_neighbours_cross_product_eq_one {N : ℕ} {x y : ℚ} (h : FareyNeighbours N x y) :
    (x.den : ℤ) * y.num - x.num * y.den = 1 ∧
    y - x = 1 / ((x.den : ℚ) * y.den) ∧
    Real.sqrt (((y : ℝ) - x) ^ 2 + (1 / (2 * (y.den : ℝ) ^ 2) - 1 / (2 * (x.den : ℝ) ^ 2)) ^ 2)
      = 1 / (2 * (x.den : ℝ) ^ 2) + 1 / (2 * (y.den : ℝ) ^ 2) := by
  have h1 := farey_aux h
  have hcast : (x.den : ℚ) * y.num - x.num * y.den = 1 := by exact_mod_cast h1
  have hbne : (x.den : ℚ) ≠ 0 := by exact_mod_cast x.den_ne_zero
  have hdne : (y.den : ℚ) ≠ 0 := by exact_mod_cast y.den_ne_zero
  have hgap : y - x = 1 / ((x.den : ℚ) * y.den) := by
    conv_lhs => rw [← Rat.num_div_den x, ← Rat.num_div_den y]
    rw [div_sub_div _ _ hdne hbne, ← hcast]
    field_simp
  refine ⟨h1, hgap, ?_⟩
  have hr : ((y : ℝ) - x) = 1 / ((x.den : ℝ) * y.den) := by
    have := congrArg (fun q : ℚ => (q : ℝ)) hgap
    push_cast at this
    exact this
  have hbR : (x.den : ℝ) ≠ 0 := by exact_mod_cast x.den_ne_zero
  have hdR : (y.den : ℝ) ≠ 0 := by exact_mod_cast y.den_ne_zero
  rw [hr]
  rw [show (1 / ((x.den : ℝ) * y.den)) ^ 2 + (1 / (2 * (y.den : ℝ) ^ 2) - 1 / (2 * (x.den : ℝ) ^ 2)) ^ 2
      = (1 / (2 * (x.den : ℝ) ^ 2) + 1 / (2 * (y.den : ℝ) ^ 2)) ^ 2 by field_simp; ring]
  exact Real.sqrt_sq (by positivity)

/-- The first fraction between Farey neighbours a/b < c/d is their mediant (a + c)/(b + d):
the mediant lies strictly between them with bottom exactly b + d, every fraction strictly
between them has bottom at least b + d, and the only one with bottom b + d is the mediant. -/
theorem farey_neighbours_mediant_first_between {N : ℕ} {x y : ℚ} (h : FareyNeighbours N x y) :
    let m : ℚ := ((x.num + y.num : ℤ) : ℚ) / ((x.den + y.den : ℕ) : ℚ)
    x < m ∧ m < y ∧ m.den = x.den + y.den ∧
    ∀ z : ℚ, x < z → z < y → x.den + y.den ≤ z.den ∧ (z.den = x.den + y.den → z = m) := by
  intro m
  have h1 := farey_aux h
  have hxq := rat_eq_num_div_den' x
  have hyq := rat_eq_num_div_den' y
  have hmq : m = ((x.num + y.num : ℤ) : ℚ) / (((x.den : ℤ) + (y.den : ℤ) : ℤ) : ℚ) := by
    simp only [m]; push_cast; rfl
  set a : ℤ := x.num with ha
  set b : ℤ := (x.den : ℤ) with hb
  set c : ℤ := y.num with hc
  set d : ℤ := (y.den : ℤ) with hd
  have hbpos : 0 < b := by simp [hb, x.den_pos]
  have hdpos : 0 < d := by simp [hd, y.den_pos]
  have hbq : (0 : ℚ) < (b : ℚ) := by exact_mod_cast hbpos
  have hdq : (0 : ℚ) < (d : ℚ) := by exact_mod_cast hdpos
  have hbdq : (0 : ℚ) < ((b + d : ℤ) : ℚ) := by exact_mod_cast (by linarith : 0 < b + d)
  have hcop : IsCoprime (a + c) (b + d) := ⟨b, -a, by linear_combination h1⟩
  have hmden : ((m.den : ℤ)) = b + d := by
    rw [hmq]
    exact Rat.den_div_eq_of_coprime (by linarith) (Int.isCoprime_iff_gcd_eq_one.mp hcop)
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [hxq, hmq, div_lt_div_iff₀ hbq hbdq]
    have : a * (b + d) < (a + c) * b := by nlinarith
    exact_mod_cast this
  · rw [hyq, hmq, div_lt_div_iff₀ hbdq hdq]
    have : (a + c) * d < c * (b + d) := by nlinarith
    exact_mod_cast this
  · have : (m.den : ℤ) = ((x.den + y.den : ℕ) : ℤ) := by rw [hmden]; push_cast; rfl
    exact_mod_cast this
  · intro z hxz hzy
    have hzq := rat_eq_num_div_den' z
    set p : ℤ := z.num with hp
    set q : ℤ := (z.den : ℤ) with hq
    have hqpos : 0 < q := by simp [hq, z.den_pos]
    have hqq : (0 : ℚ) < (q : ℚ) := by exact_mod_cast hqpos
    have hD1 : 1 ≤ b * p - a * q := by
      have h' : (a : ℚ) / (b : ℚ) < (p : ℚ) / (q : ℚ) := by rw [← hxq, ← hzq]; exact hxz
      rw [div_lt_div_iff₀ hbq hqq] at h'
      have : a * q < p * b := by exact_mod_cast h'
      linarith
    have hD2 : 1 ≤ c * q - d * p := by
      have h' : (p : ℚ) / (q : ℚ) < (c : ℚ) / (d : ℚ) := by rw [← hzq, ← hyq]; exact hzy
      rw [div_lt_div_iff₀ hqq hdq] at h'
      have : p * d < c * q := by exact_mod_cast h'
      linarith
    have hid : d * (b * p - a * q) + b * (c * q - d * p) = q := by
      linear_combination q * h1
    have hqge : b + d ≤ q := by nlinarith
    have hqge' : ((x.den + y.den : ℕ) : ℤ) ≤ (z.den : ℤ) := by push_cast; exact hqge
    refine ⟨by exact_mod_cast hqge', fun hzd => ?_⟩
    have hqeq : q = b + d := by simp only [hq, hb, hd]; exact_mod_cast hzd
    have hD1e : b * p - a * q = 1 := by nlinarith
    have hpeq : p = a + c := by
      have : b * p = b * (a + c) := by rw [hqeq] at hD1e; linear_combination hD1e - h1
      exact mul_left_cancel₀ hbpos.ne' this
    rw [hzq, hmq, hpeq, hqeq]

/-- Dirichlet's approximation theorem, the card's Step 4: every irrational `ξ` has infinitely
many fractions p/q in lowest terms with |ξ − p/q| < 1/q². -/
theorem irrational_infinitely_many_within_one_div_den_sq {ξ : ℝ} (hξ : Irrational ξ) :
    {q : ℚ | |ξ - q| < 1 / (q.den : ℝ) ^ 2}.Infinite := by
  exact Real.infinite_rat_abs_sub_lt_one_div_den_sq_of_irrational hξ

/-- The order-5 list from the card, as (top, bottom) pairs. -/
def order5 : List (ℕ × ℕ) :=
  [(0, 1), (1, 5), (1, 4), (1, 3), (2, 5), (1, 2), (3, 5), (2, 3), (3, 4), (4, 5), (1, 1)]

-- Order 5 has exactly 11 fractions from 0 to 1 in lowest terms with bottom at most 5.
example : ((Finset.range 6 ×ˢ Finset.Icc 1 5).filter
    (fun pq : ℕ × ℕ => pq.1 ≤ pq.2 ∧ Nat.gcd pq.1 pq.2 = 1)).card = 11 := by decide

-- Each listed fraction is in lowest terms with bottom at most 5.
example : ∀ pq ∈ order5, Nat.gcd pq.1 pq.2 = 1 ∧ pq.1 ≤ pq.2 ∧ pq.2 ≤ 5 := by decide

-- Every neighbouring pair a/b, c/d on the order-5 list has b × c − a × d = 1.
example : ∀ p ∈ order5.zip order5.tail,
    (p.1.2 * p.2.1 : ℤ) - p.1.1 * p.2.2 = 1 := by decide

-- Neighbours 1/3 and 2/5: 2 × 3 − 1 × 5 = 1, and their gap is 1/15.
example : (2 * 3 - 1 * 5 : ℤ) = 1 := by norm_num
example : (2 / 5 - 1 / 3 : ℚ) = 1 / (3 * 5) := by norm_num

-- The mediant of 1/3 and 1/2 is (1 + 1)/(3 + 2) = 2/5; the average is 5/12 and the sum is 5/6.
example : ((1 + 1) / (3 + 2) : ℚ) = 2 / 5 := by norm_num
example : ((1 / 3 + 1 / 2) / 2 : ℚ) = 5 / 12 ∧ (1 / 3 + 1 / 2 : ℚ) = 5 / 6 := by norm_num

-- Ford circles at 1/3 and 2/5 have radii 1/18 and 1/50; the squared distance between centres
-- equals the squared sum of radii, so they touch.
example : (1 / (2 * 3 ^ 2) : ℚ) = 1 / 18 ∧ (1 / (2 * 5 ^ 2) : ℚ) = 1 / 50 := by norm_num
example : ((2 / 5 - 1 / 3) ^ 2 + (1 / 18 - 1 / 50) ^ 2 : ℚ) = (1 / 18 + 1 / 50) ^ 2 := by norm_num

-- The touching point (13/34, 1/34) lies on both circles.
example : ((13 / 34 - 1 / 3) ^ 2 + (1 / 34 - 1 / 18) ^ 2 : ℚ) = (1 / 18) ^ 2 ∧
    ((13 / 34 - 2 / 5) ^ 2 + (1 / 34 - 1 / 50) ^ 2 : ℚ) = (1 / 50) ^ 2 := by norm_num

-- With radius 1/q² instead, the circles on 1/3 and 2/5 overlap: centres are closer than the radii's sum.
example : ((2 / 5 - 1 / 3) ^ 2 + (1 / 9 - 1 / 25) ^ 2 : ℚ) < (1 / 9 + 1 / 25) ^ 2 := by norm_num

-- Lowest terms only: 2/4 beside 1/2 gives 1 × 4 − 2 × 2 = 0.
example : (1 * 4 - 2 * 2 : ℤ) = 0 := by norm_num

#print axioms farey_neighbours_cross_product_eq_one
#print axioms farey_neighbours_mediant_first_between
#print axioms irrational_infinitely_many_within_one_div_den_sq
#print axioms rat_eq_num_div_den'
#print axioms farey_aux
