import 'symbol.dart';
import 'unit_expr_problem.dart';

// 波動の問題（expr単位で集約・category/defs内包）
final wavesExprProblems = <UnitExprProblem>[
  UnitExprProblem(
    expr: "T",
    meaning: "周期",
    meaningEn: "period",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "T", nameJa: "周期", meaning: "1回の振動にかかる時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "B75FD5A5-42A8-4BFE-A87E-1121778AF44E",
        answer: "s",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\sqrt{\frac{T}{\rho}}",
    meaning: "波の速さ",
    meaningEn: "wave speed",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "T", nameJa: "張力", unitSymbol: "N", meaning: "弦を張る力", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
        SymbolDef(symbol: "ρ", nameJa: "線密度", unitSymbol: "kg/m", meaning: "単位長さあたりの質量", baseUnits: "kg·m^-1", dimension: "ML^-1", texSymbol: r"\rho"),
      ],
    unitProblems: [
      UnitProblem(
        id: "F5374EF5-C50F-4996-A97F-D20DFC644D61",
        shortExplanation: r"\sqrt{T/\rho}\text{は波の速さ。}",
        shortExplanationEn: r"\sqrt{T/\rho}\text{ is wave speed",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "fλ",
    meaning: "波の速さ",
    meaningEn: "wave speed",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "f", nameJa: "周波数", meaning: "単位時間あたりの振動数", unitSymbol: "Hz", baseUnits: "s^-1", dimension: "T^-1"),
        SymbolDef(symbol: "λ", nameJa: "波長", meaning: "波の1周期の長さ", unitSymbol: "m", baseUnits: "m", dimension: "L", texSymbol: r"\lambda"),
      ],
    unitProblems: [
      UnitProblem(
        id: "2C459295-C25F-430D-B7AA-C1B7D9B13B20",
        shortExplanation: r"f\lambda\text{は波の速さ。}",
        shortExplanationEn: r"f\lambda\text{ is wave speed",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "k",
    meaning: "波数(1mあたりどれだけ位相が変わるか)",
    meaningEn: "wave number (phase change per meter)",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "k", nameJa: "波数", meaning: "2π/λ", unitSymbol: "m^-1", baseUnits: "m^-1", dimension: "L^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "4658AF67-8EFC-4B8D-AAD1-EAB05F6481DD",
        answer: "m^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "v",
    meaning: "波の速さ",
    meaningEn: "wave speed",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "v", nameJa: "波の速さ", meaning: "波の伝播速度", unitSymbol: "m/s", baseUnits: "m·s^-1", dimension: "LT^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "98F6B45A-F31E-4F3E-A862-57EB0C5B7C21",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "λ",
    meaning: "波長",
    meaningEn: "wavelength",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "λ", nameJa: "波長", meaning: "波の1周期の長さ", unitSymbol: "m", baseUnits: "m", dimension: "L", texSymbol: r"\lambda"),
      ],
    unitProblems: [
      UnitProblem(
        id: "3CDBD4E9-8CDC-45C1-8BEA-65802A092052",
        answer: "m",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ρ",
    meaning: "質量線密度",
    meaningEn: "linear mass density",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "ρ", nameJa: "線密度", meaning: "単位長さあたりの質量", unitSymbol: "kg/m", baseUnits: "kg·m^-1", dimension: "ML^-1", texSymbol: r"\rho"),
      ],
    unitProblems: [
      UnitProblem(
        id: "69B453B1-F8F3-4FD5-8EB6-CE1402DCECAA",
        answer: "kg m^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ω",
    meaning: "角周波数",
    meaningEn: "angular frequency",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "ω", nameJa: "角周波数", meaning: "2πf", unitSymbol: "rad/s", baseUnits: "s^-1", dimension: "T^-1", texSymbol: r"\omega"),
      ],
    unitProblems: [
      UnitProblem(
        id: "EA2F05A4-621A-4328-BF4F-9EC07AD4364D",
        answer: "rad s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "rad", "rad^-1"],
      ),
      UnitProblem(
        id: "C05F39C2-E7BD-47D7-8A5E-CD9889E8487D",
        answer: "s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),

  UnitExprProblem(
    expr: "mLλ/d",
    meaning: "ヤングの実験（同位相2スリット）の明線の位置",
    meaningEn: "Bright fringe position (Young's double slit, in-phase)",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "m", nameJa: "明線の次数", meaning: "明線の番号（0,1,2,...）", nameEn: "Fringe order", meaningEn: "Order number of bright fringe (0, 1, 2, ...)", unitSymbol: "無次元", baseUnits: "1", dimension: "無次元"),
        SymbolDef(symbol: "L", nameJa: "スクリーンまでの距離", meaning: "スリットからスクリーンまでの距離", nameEn: "Distance to screen", meaningEn: "Distance from slits to the screen", unitSymbol: "m", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "λ", nameJa: "波長", meaning: "波の1周期の長さ", nameEn: "Wavelength", meaningEn: "Wavelength of light", unitSymbol: "m", baseUnits: "m", dimension: "L", texSymbol: r"\lambda"),
        SymbolDef(symbol: "d", nameJa: "スリット間隔", meaning: "2つのスリットの間隔", nameEn: "Slit separation", meaningEn: "Distance between the two slits", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "A17A6078-37C9-43B3-BB85-B41EB759FE5F",
        shortExplanation: r"mL\lambda/d\text{ はスクリーン上の位置（長さ）。}",
        shortExplanationEn: r"mL\lambda/d\text{ is a length (position on screen).}",
        answer: "m",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\sqrt{m\lambda R}",
    meaning: "ニュートンリング（暗線）の半径",
    meaningEn: "Dark ring radius (Newton's rings)",
    category: UnitCategory.waves,
    defs: [
        SymbolDef(symbol: "m", nameJa: "暗線の次数", meaning: "暗線の番号（1,2,3,...）", nameEn: "Ring order", meaningEn: "Order number of dark ring (1, 2, 3, ...)", unitSymbol: "無次元", baseUnits: "1", dimension: "無次元"),
        SymbolDef(symbol: "λ", nameJa: "波長", meaning: "波の1周期の長さ", nameEn: "Wavelength", meaningEn: "Wavelength of light", unitSymbol: "m", baseUnits: "m", dimension: "L", texSymbol: r"\lambda"),
        SymbolDef(symbol: "R", nameJa: "曲率半径", meaning: "レンズの曲率半径", nameEn: "Radius of curvature", meaningEn: "Radius of curvature of the lens", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "34BA19A2-6F9E-4ED1-9E25-4ECB924353A5",
        shortExplanation: r"\sqrt{m\lambda R}\text{ は半径（長さ）。}",
        shortExplanationEn: r"\sqrt{m\lambda R}\text{ is a length (radius).}",
        answer: "m",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"2nd \cos r",
    meaning: "薄膜（斜入射）の光路差",
    meaningEn: "Optical path difference (thin film, oblique incidence)",
    category: UnitCategory.waves,
    defs: [
      SymbolDef(
        symbol: "n",
        nameJa: "屈折率",
        meaning: "薄膜の屈折率",
        nameEn: "Refractive index",
        meaningEn: "Refractive index of the thin film",
        unitSymbol: "無次元",
        baseUnits: "1",
        dimension: "無次元",
      ),
      SymbolDef(
        symbol: "d",
        nameJa: "厚さ",
        meaning: "薄膜の厚さ",
        nameEn: "Thickness",
        meaningEn: "Thickness of the thin film",
        unitSymbol: "m",
        baseUnits: "m",
        dimension: "L",
      ),
      SymbolDef(
        symbol: "r",
        nameJa: "屈折角",
        meaning: "薄膜内での屈折角",
        nameEn: "Refraction angle",
        meaningEn: "Refraction angle inside the thin film",
        unitSymbol: "rad",
        baseUnits: "1",
        dimension: "1",
      ),
    ],
    unitProblems: [
      UnitProblem(
        id: "24C13067-9DAB-4FF3-A19B-BC948ECEC7A7",
        shortExplanation: r"2nd\cos r\text{ は光路差（長さ）。}",
        shortExplanationEn: r"2nd\cos r\text{ is a length (optical path difference).}",
        answer: "m",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
];
