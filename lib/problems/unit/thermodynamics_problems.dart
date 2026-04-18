import 'symbol.dart';
import 'unit_expr_problem.dart';

// 熱力学の問題（expr単位で集約・category/defs内包）
final thermodynamicsExprProblems = <UnitExprProblem>[
  UnitExprProblem(
    expr: "C",
    meaning: "熱容量",
    meaningEn: "heat capacity",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "C", nameJa: "熱容量", meaning: "物体全体の熱容量", unitSymbol: "J/K", baseUnits: "kg·m^2·s^-2·K^-1", dimension: "ML^2T^-2Θ^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "A2DE4AD2-DE74-4FA5-9CC0-A56B62C21EAF",
        answer: "J K^-1",
        units: ["K", "K^-1", "kg", "kg^-1", "J", "J^-1", "W", "W^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "C_v",
    meaning: "定積モル比熱",
    meaningEn: "molar heat capacity at constant volume",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "C_v", nameJa: "定積モル比熱", meaning: "定積過程のモル比熱", unitSymbol: "J/(mol·K)", baseUnits: "kg·m^2·s^-2·K^-1·mol^-1", dimension: "ML^2T^-2Θ^-1N^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "87A98152-3480-4445-BCE8-338CCB0DF2C0",
        shortExplanationEn: r"C_v\text{ is molar heat capacity at constant volume",
        answer: "J mol^-1 K^-1",
        units: ["mol", "K", "kg", "J", "mol^-1", "K^-1", "kg^-1", "J^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "Q",
    meaning: "熱量",
    meaningEn: "heat",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "Q", nameJa: "熱量", meaning: "系に加えられた熱量", unitSymbol: "J", baseUnits: "kg·m^2·s^-2", dimension: "ML^2T^-2"),
        // SymbolDef(symbol: "W", nameJa: "仕事", meaning: "系が外部にした仕事", unitSymbol: "J", baseUnits: "kg·m^2·s^-2", dimension: "ML^2T^-2"),
        // SymbolDef(symbol: "ΔU", nameJa: "内部エネルギー変化", meaning: "内部エネルギーの変化", unitSymbol: "J", baseUnits: "kg·m^2·s^-2", dimension: "ML^2T^-2", texSymbol: r"\Delta U"),
      ],
    unitProblems: [
      UnitProblem(
        id: "A81F3115-ACED-441B-9161-2D7D8AEBB8FE",
        shortExplanation: r"Q=W+\Delta U\text{は熱力学第一法則。}",
        shortExplanationEn: r"Q=W+\Delta U\text{ is the first law of thermodynamics. Unit of }Q\text{ is }J\text{ (Joule).}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "R",
    meaning: "気体定数",
    meaningEn: "gas constant",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "R", nameJa: "気体定数", meaning: "理想気体の定数", unitSymbol: "J/(mol·K)", baseUnits: "kg·m^2·s^-2·K^-1·mol^-1", dimension: "ML^2T^-2Θ^-1N^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "ED94AD91-E28F-4D99-9F26-2CB55E491E76",
        answer: "J mol^-1 K^-1",
        units: ["mol^-1", "K^-1", "kg", "J", "mol", "K", "kg^-1", "J^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "k",
    meaning: "ボルツマン定数",
    meaningEn: "Boltzmann constant",
    category: UnitCategory.thermodynamics,
    defs: [
      SymbolDef(
        symbol: "k",
        nameJa: "ボルツマン定数",
        meaning: "温度とエネルギーを結びつける比例定数",
        nameEn: "Boltzmann constant",
        meaningEn: "Proportionality constant relating temperature and energy",
        unitSymbol: "J/K",
        baseUnits: "kg·m^2·s^-2·K^-1",
        dimension: "ML^2T^-2Θ^-1",
      ),
    ],
    unitProblems: [
      UnitProblem(
        id: "2CB3BA00-9C4F-4623-90C7-82ACD639FF94",
        answer: "J K^-1",
        units: ["mol", "K", "kg", "J", "mol^-1", "K^-1", "kg^-1", "J^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "T",
    meaning: "温度",
    meaningEn: "temperature",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "T", nameJa: "温度", meaning: "熱力学的温度", unitSymbol: "K", baseUnits: "K", dimension: "Θ"),
      ],
    unitProblems: [
      UnitProblem(
        id: "68492DE2-6E8D-498E-BFB8-283D143EBA68",
        answer: "K",
        units: ["kg", "m", "K", "s", "kg^-1", "m^-1", "K^-1", "s^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "V",
    meaning: "体積",
    meaningEn: "volume",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "V", nameJa: "体積", meaning: "空間の大きさ", unitSymbol: "m^3", baseUnits: "m^3", dimension: "L^3"),
      ],
    unitProblems: [
      UnitProblem(
        id: "5A5DB714-65DA-4306-BEEC-7DD44CB82110",
        answer: "m^3",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\eta",
    meaning: "熱効率",
    meaningEn: "thermal efficiency",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "η", nameJa: "熱効率", meaning: "熱機関の効率", unitSymbol: "1", baseUnits: "1", dimension: "1", texSymbol: r"\eta"),
      ],
    unitProblems: [
      UnitProblem(
        id: "21C16E46-B31B-416A-B392-D5B7414FE479",
        answer: "1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{3}{2}nRT",
    meaning: "単原子分子理想気体の内部エネルギー",
    meaningEn: "internal energy of monatomic ideal gas",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "n", nameJa: "物質量", unitSymbol: "mol", meaning: "モル数", baseUnits: "mol", dimension: "N"),
        SymbolDef(symbol: "R", nameJa: "気体定数", unitSymbol: "J/(mol·K)", meaning: "気体定数", baseUnits: "kg·m^2·s^-2·K^-1·mol^-1", dimension: "ML^2T^-2Θ^-1N^-1"),
        SymbolDef(symbol: "T", nameJa: "温度", unitSymbol: "K", meaning: "絶対温度", baseUnits: "K", dimension: "Θ"),
      ],
    unitProblems: [
      UnitProblem(
        id: "A3556347-3E88-452E-A9D5-B1FE631252FB",
        shortExplanation: r"\frac{3}{2}nRT\text{は単原子分子理想気体の内部エネルギー。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"\frac{3}{2}nRT\text{ is internal energy of monatomic ideal gas",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
      UnitProblem(
        id: "77B41F66-CDE7-4971-9B89-D794EC73F8B5",
        shortExplanation: r"\frac{3}{2}nRT\text{は単原子分子理想気体の内部エネルギー。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"\frac{3}{2}nRT\text{ is internal energy of monatomic ideal gas",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{5}{2}nRT",
    meaning: "2原子分子理想気体の内部エネルギー",
    meaningEn: "internal energy of diatomic ideal gas",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "n", nameJa: "物質量", unitSymbol: "mol", meaning: "モル数", baseUnits: "mol", dimension: "N"),
        SymbolDef(symbol: "R", nameJa: "気体定数", unitSymbol: "J/(mol·K)", meaning: "気体定数", baseUnits: "kg·m^2·s^-2·K^-1·mol^-1", dimension: "ML^2T^-2Θ^-1N^-1"),
        SymbolDef(symbol: "T", nameJa: "温度", unitSymbol: "K", meaning: "絶対温度", baseUnits: "K", dimension: "Θ"),
      ],
    unitProblems: [
      UnitProblem(
        id: "99FEB51D-70D2-4AB6-8EA7-24FFC2D0A6F7",
        shortExplanation: r"\frac{5}{2}nRT\text{は2原子分子理想気体の内部エネルギー。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"\frac{5}{2}nRT\text{ is internal energy of diatomic ideal gas",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
      UnitProblem(
        id: "4002D20E-7FF1-400B-91BB-4352340ED545",
        shortExplanation: r"\frac{5}{2}nRT\text{は2原子分子理想気体の内部エネルギー。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"\frac{5}{2}nRT\text{ is internal energy of diatomic ideal gas",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "c",
    meaning: "比熱",
    meaningEn: "specific heat",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "c", nameJa: "比熱", meaning: "単位質量あたりの熱容量", unitSymbol: "J/(g·K)", baseUnits: "m^2·s^-2·K^-1", dimension: "L^2T^-2Θ^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "E5977CDA-7118-4673-A562-1DB2322F946F",
        answer: "J g^-1 K^-1",
        units: ["g", "g^-1", "K", "K^-1", "mol", "mol^-1", "J", "J^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "nRT",
    meaning: "エネルギー相当",
    meaningEn: "energy equivalent",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "n", nameJa: "物質量", unitSymbol: "mol", meaning: "モル数", baseUnits: "mol", dimension: "N"),
        SymbolDef(symbol: "R", nameJa: "気体定数", unitSymbol: "J/(mol·K)", meaning: "気体定数", baseUnits: "kg·m^2·s^-2·K^-1·mol^-1", dimension: "ML^2T^-2Θ^-1N^-1"),
        SymbolDef(symbol: "T", nameJa: "温度", unitSymbol: "K", meaning: "絶対温度", baseUnits: "K", dimension: "Θ"),
      ],
    unitProblems: [
      UnitProblem(
        id: "1E2C3B39-844B-4CE9-960A-D5F65815252C",
        shortExplanation: r"nRT\text{はエネルギー相当。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"nRT\text{ is energy equivalent",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
      UnitProblem(
        id: "5C0F610A-932D-4CD1-9714-F2F098249A08",
        shortExplanation: r"nRT\text{はエネルギー相当。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"nRT\text{ is energy equivalent",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "p",
    meaning: "圧力",
    meaningEn: "pressure",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "p", nameJa: "圧力", meaning: "単位面積あたりの力", unitSymbol: "Pa", baseUnits: "kg·m^-1·s^-2", dimension: "ML^-1T^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "C869EB51-7D33-43D6-9510-59C0B90676DA",
        answer: "Pa",
        units: ["m", "kg", "J", "W", "s^-1", "N", "Pa"],
      ),
      UnitProblem(
        id: "92568D78-4372-4042-A1B5-DDA45052DD87",
        answer: "N m^-2",
        units: ["m^-1", "kg^-1", "s^-1", "W", "m", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "pV",
    meaning: "エネルギー相当",
    meaningEn: "energy equivalent",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "p", nameJa: "圧力", unitSymbol: "Pa", meaning: "圧力", baseUnits: "kg·m^-1·s^-2", dimension: "ML^-1T^-2"),
        SymbolDef(symbol: "V", nameJa: "体積", unitSymbol: "m^3", meaning: "体積", baseUnits: "m^3", dimension: "L^3"),
      ],
    unitProblems: [
      UnitProblem(
        id: "C1888141-46B5-49FE-8EEF-F50D955A14A2",
        shortExplanation: r"pV\text{はエネルギー相当。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"pV\text{ is energy equivalent",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
      UnitProblem(
        id: "656B2288-873B-4E29-93ED-9C07148605D6",
        shortExplanation: r"pV\text{はエネルギー相当。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"pV\text{ is energy equivalent",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "γ",
    meaning: "比熱比",
    meaningEn: "heat capacity ratio",
    category: UnitCategory.thermodynamics,
    defs: [
        SymbolDef(symbol: "γ", nameJa: "比熱比", nameEn: "Heat capacity ratio", meaning: "定圧比熱/定積比熱", meaningEn: "Ratio of specific heats (Cp/Cv)", unitSymbol: "無次元", baseUnits: "1", dimension: "無次元", texSymbol: r"\gamma"),
      ],
    unitProblems: [
      UnitProblem(
        id: "F115BEE0-5B5D-4C10-822A-4AC8205A90B1",
        answer: "1 (無次元)",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
];
