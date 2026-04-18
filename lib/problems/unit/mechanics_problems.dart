import 'symbol.dart';
import 'unit_expr_problem.dart';

/// チュートリアルで使う「重力加速度 g」の問題（本編の問題プールと共有する）
///
/// - チュートリアル側でこのIDを使って学習履歴を保存しているため、IDは固定。
/// - shortExplanation は表示箇所によって TeX として描画されるため、`\text{}` 形式に統一。
const String tutorialGravityProblemId = "03A1F9C9-41FF-4784-A00A-8A7817753859";

const UnitProblem tutorialGravityUnitProblem = UnitProblem(
  id: tutorialGravityProblemId,
  // shortExplanation: r"g\text{（重力加速度）の単位は }m \cdot s^{-2}\text{。}",
  // shortExplanationEn: r"g\text{ (gravitational acceleration) has unit } m \cdot s^{-2} \text{.}",
  // UnitCalculatorService / NormalizedUnit は空白区切りも扱える想定
  answer: "m s^-2",
  // チュートリアルの操作説明（m と s^-1 を押す）に合わせて含めておく
  units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
);

final UnitExprProblem gravityAccelerationExprProblem = UnitExprProblem(
  expr: "g",
  meaning: "重力加速度",
  meaningEn: "Gravitational acceleration",
  category: UnitCategory.mechanics,
  defs: [
    SymbolDef(
      symbol: "g",
      nameJa: "重力加速度",
      meaning: "重力による加速度",
      unitSymbol: "m/s^2",
      baseUnits: "m·s^-2",
      dimension: "LT^-2",
    ),
  ],
  unitProblems: [tutorialGravityUnitProblem],
);

// 力学の問題（expr単位で集約・category/defs内包）
final mechanicsExprProblems = <UnitExprProblem>[
  gravityAccelerationExprProblem,
  UnitExprProblem(
    expr: r"-\frac{GMm}{r}",
    meaning: "重力の位置エネルギー",
    meaningEn: "gravitational potential energy",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "G", nameJa: "万有引力定数", meaning: "万有引力の比例定数", unitSymbol: "N·m^2/kg^2", baseUnits: "m^3·kg^-1·s^-2", dimension: "L^3M^-1T^-2"),
        SymbolDef(symbol: "M", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "r", nameJa: "距離", meaning: "中心距離", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "486C2D1F-FAC0-4AED-B0F9-B745CFC33426",
        shortExplanation: r"-\frac{GMm}{r}\text{は位置エネルギー。単位は}J\text{(ジュール)。}",
        shortExplanationEn: r"-\frac{GMm}{r}\text{ is gravitational potential energy}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"2\pi\sqrt{\frac{l}{g}}",
    meaning: "単振り子の周期",
    meaningEn: "period of simple pendulum",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "l", nameJa: "長さ", meaning: "振り子の長さ", unitSymbol: "m", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "g", nameJa: "重力加速度", meaning: "重力による加速度", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "20E4D00C-2016-41C4-A85E-3ABF2D9EF6B8",
        shortExplanation: r"2\pi\sqrt{\frac{l}{g}}\text{は単振り子の周期。単位は}s\text{(秒)。}",
        shortExplanationEn: r"2\pi\sqrt{\frac{l}{g}}\text{ is period of simple pendulum}",
        answer: "s",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"2\pi\sqrt{\frac{m}{k}}",
    meaning: "ばね振動の周期",
    meaningEn: "period of spring oscillation",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "k", nameJa: "ばね定数", meaning: "ばねの硬さ", unitSymbol: "N/m", baseUnits: "kg·s^-2", dimension: "MT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "3EA7D151-2CFE-4B96-A643-04564200FE4D",
        shortExplanation: r"2\pi\sqrt{\frac{m}{k}}\text{はばね振動の周期。単位は}s\text{(秒)。}",
        shortExplanationEn: r"2\pi\sqrt{\frac{m}{k}}\text{ is period of spring oscillation}",
        answer: "s",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "F",
    meaning: "力",
    meaningEn: "force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "F", nameJa: "力", meaning: "物体に働く力", unitSymbol: "N", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "E8DD2227-985F-471D-8735-61E940AAC1E1",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "7C053ABE-B54B-4F2C-B529-6381C3E466F4",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "Ft",
    meaning: "力積",
    meaningEn: "impulse",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "F", nameJa: "力", meaning: "物体に働く力", unitSymbol: "N", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "力が働く時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "D5E347EC-4368-42D2-972C-DEFFC3695D96",
        shortExplanation: r"Ft\text{は力積。}",
        shortExplanationEn: r"Ft\text{ is impulse. Unit in base units: }kg \cdot m \cdot s^{-1}\text{.}",
        answer: "N s",
        units: ["m", "kg", "s", "N", "Pa^-1", "J"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"Fx \cos \theta",
    meaning: "力のモーメント",
    meaningEn: "torque",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "F", nameJa: "力", meaning: "物体に働く力", unitSymbol: "N", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
        SymbolDef(symbol: "x", nameJa: "距離", meaning: "回転軸からの距離", unitSymbol: "m", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "θ", nameJa: "角度", meaning: "力と距離のなす角", unitSymbol: "rad", baseUnits: "1", dimension: "1", texSymbol: r"\theta"),
      ],
    unitProblems: [
      UnitProblem(
        id: "DCDF76D4-96BB-4050-A95A-06CE34ABFC53",
        answer: "N m",
        units: ["kg^-1", "Pa^-1", "W", "m", "s^-1", "N"],
      ),
      UnitProblem(
        id: "5A05B29F-3ACE-4D36-9B88-3C931D572A6C",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "G",
    meaning: "万有引力定数",
    meaningEn: "gravitational constant",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "G", nameJa: "万有引力定数", meaning: "万有引力の比例定数", unitSymbol: "N·m^2/kg^2", baseUnits: "m^3·kg^-1·s^-2", dimension: "L^3M^-1T^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "FA94334D-DCDE-42AB-B231-AE69A8478B1B",
        point:
            r"\text{万有引力 }F=\frac{GMm}{r^2}"
            "\n"
            r"\left[\frac{GMm}{r^2}\right]=[F]=N"
            "\n"
            r"\therefore\ \left[G\right]=N\cdot\left[\frac{r^2}{Mm}\right]=N\cdot m^2\cdot kg^{-2}",
        pointEn:
            r"\text{From }F=\frac{GMm}{r^2}"
            "\n"
            r"\left[\frac{GMm}{r^2}\right]=[F]=N"
            "\n"
            r"\therefore\ \left[G\right]=N\cdot\left[\frac{r^2}{Mm}\right]=N\cdot m^2\cdot kg^{-2}",
        answer: "N m^2 kg^-2",
        units: ["m", "m^-1", "kg","kg^-1", "N", "1"],
      ),
      UnitProblem(
        id: "F04D70CD-0A3B-4B01-8FDF-8E9ADC35B95A",
        point:
            r"\text{万有引力 }F=\frac{GMm}{r^2}"
            "\n"
            r"\left[\frac{GMm}{r^2}\right]=[F]=N\ \Rightarrow\ \left[G\right]=N\cdot\left[\frac{r^2}{Mm}\right]=N\cdot m^2\cdot kg^{-2}"
            "\n"
            r"N=kg\cdot m\cdot s^{-2}\ \Rightarrow\ \left[G\right]=m^3\cdot kg^{-1}\cdot s^{-2}",
        pointEn:
            r"\text{From }F=\frac{GMm}{r^2}"
            "\n"
            r"\left[\frac{GMm}{r^2}\right]=[F]=N\ \Rightarrow\ \left[G\right]=N\cdot\left[\frac{r^2}{Mm}\right]=N\cdot m^2\cdot kg^{-2}"
            "\n"
            r"N=kg\cdot m\cdot s^{-2}\ \Rightarrow\ \left[G\right]=m^3\cdot kg^{-1}\cdot s^{-2}",
        answer: "m^3 kg^-1 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "N",
    meaning: "垂直抗力",
    meaningEn: "normal force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "N", nameJa: "垂直抗力", meaning: "接触面に垂直な力", unitSymbol: "N", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "A8AA235D-700B-40A5-A90A-61857A5A0BB0",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "DFEBA1E9-4D2C-4BDE-9A25-B8941D7AE61F",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "P",
    meaning: "電力",
    meaningEn: "power",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "P", nameJa: "電力", meaning: "単位時間あたりのエネルギー", unitSymbol: "W", baseUnits: "kg·m^2·s^-3", dimension: "ML^2T^-3"),
      ],
    unitProblems: [
      UnitProblem(
        id: "F91239CA-8C30-4EDA-BD1D-A43AE2B67096",
        answer: "W",
        units: ["Pa", "kg", "J", "W", "s", "m^-1", "N"],
      ),
      UnitProblem(
        id: "6F5A1AA7-C27A-4E39-9C8B-07607F9C8037",
        answer: "J s^-1",
        units: ["Pa", "kg", "J", "m^-1", "s^-1", "s", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "Pt",
    meaning: "仕事",
    meaningEn: "work",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "P", nameJa: "電力", meaning: "単位時間あたりのエネルギー", unitSymbol: "W", baseUnits: "kg·m^2·s^-3", dimension: "ML^2T^-3"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "経過時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "51EB1258-D006-4BDB-8534-4E59EEBB3D73",
        shortExplanation: r"Pt\text{は仕事。}",
        shortExplanationEn: r"Pt\text{ is work}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "W",
    meaning: "仕事",
    meaningEn: "work",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "W", nameJa: "仕事", meaning: "力と距離の積", unitSymbol: "J", baseUnits: "kg·m^2·s^-2", dimension: "ML^2T^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "7A6BA7C1-AE86-47D1-AB6A-9DD2EF933031",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
      UnitProblem(
        id: "CB33DCFD-9764-46EC-AB99-DCCC2BE4D6D5",
        answer: "N m",
        units: ["kg^-1", "Pa^-1", "W", "m", "s^-1", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}gt^2",
    meaning: "自由落下の変位",
    meaningEn: "displacement of free fall",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "g", nameJa: "重力加速度", meaning: "重力による加速度", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "経過時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "2AC51123-283E-4D00-9CCE-4BE9487DB6A9",
        shortExplanation: r"\frac{1}{2}gt^2\text{は自由落下の変位。単位は}m\text{(メートル)。}",
        shortExplanationEn: r"\frac{1}{2}gt^2\text{ is displacement of free fall}",
        answer: "m",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}kx^2",
    meaning: "ばねの弾性エネルギー",
    meaningEn: "elastic potential energy",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "k", nameJa: "ばね定数", meaning: "ばねの硬さ", unitSymbol: "N/m", baseUnits: "kg·s^-2", dimension: "MT^-2"),
        SymbolDef(symbol: "x", nameJa: "変位", meaning: "ばねの伸び", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
        shortExplanation: r"\frac{1}{2}kx^2\text{はばねの弾性エネルギー。}",
        shortExplanationEn: r"\frac{1}{2}kx^2\text{ is elastic potential energy}",
        answer: "N m",
        units: ["kg^-1", "Pa^-1", "W", "m", "s^-1", "N"],
      ),
      UnitProblem(
        id: "D89E4782-B0A4-4C2F-8B85-4D9837FA763D",
        shortExplanation: r"\frac{1}{2}kx^2\text{はばねの弾性エネルギー。}",
        shortExplanationEn: r"\frac{1}{2}kx^2\text{ is elastic potential energy}",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}m\omega^2 A^2",
    meaning: "調和振動のエネルギー",
    meaningEn: "energy of harmonic oscillation",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "ω", nameJa: "角速度", meaning: "回転の角速度", unitSymbol: "rad/s", baseUnits: "s^-1", dimension: "T^-1", texSymbol: r"\omega"),
        SymbolDef(symbol: "A", nameJa: "振幅", meaning: "振動の振幅", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "DE17FB35-98AA-4079-AE75-25777C5876B2",
        shortExplanation: r"\frac{1}{2}m\omega^2 A^2\text{は調和振動のエネルギー。}",
        shortExplanationEn: r"\frac{1}{2}m\omega^2 A^2\text{ is energy of harmonic oscillation}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}mv^2",
    meaning: "運動エネルギー",
    meaningEn: "kinetic energy",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "v", nameJa: "速度", meaning: "位置の時間変化", unitSymbol: "m/s", baseUnits: "m·s^-1", dimension: "LT^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "183F1AAE-43C4-4A75-BC0D-834B6D597998",
        shortExplanation: r"\frac{1}{2}mv^2\text{は運動エネルギー。}",
        shortExplanationEn: r"\frac{1}{2}mv^2\text{ is kinetic energy}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
      UnitProblem(
        id: "BEE7EC0E-8869-4659-9C77-B9201FE14EBE",
        shortExplanation: r"\frac{1}{2}mv^2\text{は運動エネルギー。}",
        shortExplanationEn: r"\frac{1}{2}mv^2\text{ is kinetic energy}",
        answer: "N m",
        units: ["kg^-1", "Pa^-1", "W", "m", "s^-1", "N"],
      ),
      UnitProblem(
        id: "89C78FB8-2ABD-4AA6-B3BD-219DE6D808CA",
        shortExplanation: r"\frac{1}{2}mv^2\text{は運動エネルギー。}",
        shortExplanationEn: r"\frac{1}{2}mv^2\text{ is kinetic energy}",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{F}{S}",
    meaning: "圧力",
    meaningEn: "pressure",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "F", nameJa: "力", meaning: "物体に働く力", unitSymbol: "N", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
        SymbolDef(symbol: "S", nameJa: "面積", meaning: "力が働く面積", unitSymbol: "m^2", baseUnits: "m^2", dimension: "L^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "1EBA6B4A-9EA3-4F96-986B-06BDE21DD3E4",
        shortExplanation: r"\frac{F}{S}\text{は圧力。}",
        shortExplanationEn: r"\frac{F}{S}\text{ is pressure}",
        answer: "Pa",
        units: ["m", "kg", "J", "W", "s^-1", "N", "Pa"],
      ),
      UnitProblem(
        id: "A261DFEF-D353-44B5-B9D7-E1A642D40CE2",
        shortExplanation: r"\frac{F}{S}\text{は圧力。}",
        shortExplanationEn: r"\frac{F}{S}\text{ is pressure}",
        answer: "N m^-2",
        units: ["m^-1", "kg^-1", "s^-1", "W", "m", "N"],
      ),
      UnitProblem(
        id: "DE0C70D4-069D-4D94-A261-69B6112B113F",
        shortExplanation: r"\frac{F}{S}\text{は圧力。}",
        shortExplanationEn: r"\frac{F}{S}\text{ is pressure}",
        answer: "kg m^-1 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{GMm}{r^2}",
    meaning: "万有引力",
    meaningEn: "gravitational force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "G", nameJa: "万有引力定数", meaning: "万有引力の比例定数", unitSymbol: "m^3·kg^-1·s^-2", baseUnits: "m^3·kg^-1·s^-2", dimension: "L^3M^-1T^-2"),
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "M", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "r", nameJa: "距離", meaning: "2物体間の距離", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "54918CA1-6750-43C3-990B-F2E499FB863E",
        shortExplanation: r"\frac{G m M}{r^2}\text{は万有引力。}",
        shortExplanationEn: r"\frac{G m M}{r^2}\text{ is gravitational force}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "7D817325-96B8-4F3F-8792-88801279A8A9",
        shortExplanation: r"\frac{G m M}{r^2}\text{は万有引力。}",
        shortExplanationEn: r"\frac{G m M}{r^2}\text{ is gravitational force}",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{GM}{4\pi^2}",
    meaning: "ケプラーの定数",
    meaningEn: "Kepler's constant",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "G", nameJa: "万有引力定数", meaning: "万有引力の比例定数", unitSymbol: "m^3·kg^-1·s^-2", baseUnits: "m^3·kg^-1·s^-2", dimension: "L^3M^-1T^-2"),
        SymbolDef(symbol: "M", nameJa: "質量", meaning: "中心天体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
      ],
    unitProblems: [
      UnitProblem(
        id: "0D9204EB-2A76-4A1B-9D29-11028AFE5B7E",
        shortExplanation: r"\frac{G M}{4\pi^2}\text{はケプラーの定数。}",
        shortExplanationEn: r"\frac{G M}{4\pi^2}\text{ is Kepler's constant}",
        answer: "m^3 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{W}{t}",
    meaning: "電力",
    meaningEn: "power",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "W", nameJa: "仕事", meaning: "力と距離の積", unitSymbol: "J", baseUnits: "kg·m^2·s^-2", dimension: "ML^2T^-2"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "経過時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "35439608-B005-4E18-BEA9-9E29B1CD9F1D",
        shortExplanation: r"\frac{W}{t}\text{は電力。}",
        shortExplanationEn: r"\frac{W}{t}\text{ is power}",
        answer: "W",
        units: ["Pa", "kg", "J", "W", "s", "m^-1", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}rv\sin\theta",
    meaning: "面積速度",
    meaningEn: "areal velocity",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "r", nameJa: "距離", meaning: "中心からの距離", unitSymbol: "m", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "v", nameJa: "速度", meaning: "速度", unitSymbol: "m/s", baseUnits: "m·s^-1", dimension: "LT^-1"),
        SymbolDef(symbol: "θ", nameJa: "角度", meaning: "rとvのなす角", unitSymbol: "rad", baseUnits: "1", dimension: "1", texSymbol: r"\theta"),
      ],
    unitProblems: [
      UnitProblem(
        id: "062A257B-11DB-44F3-91A1-3F0F1D01BF38",
        shortExplanation: r"\frac{1}{2}rv\sin\theta\text{は面積速度。}",
        shortExplanationEn: r"\frac{1}{2}rv\sin\theta\text{ is areal velocity}",
        answer: "m^2 s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{mg}{k}",
    meaning: "ばねの平衡位置",
    meaningEn: "equilibrium position of spring",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "g", nameJa: "重力加速度", meaning: "重力による加速度", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
        SymbolDef(symbol: "k", nameJa: "ばね定数", meaning: "ばねの硬さ", unitSymbol: "N/m", baseUnits: "kg·s^-2", dimension: "MT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "09DE8FDF-438D-4AA7-A235-8BD0182C7ADF",
        shortExplanation: r"\frac{mg}{k}\text{はばねの平衡位置。単位は}m\text{(メートル)。}",
        shortExplanationEn: r"\frac{mg}{k}\text{ is equilibrium position of spring}",
        answer: "m",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{mv^2}{r}",
    meaning: "円運動の向心力",
    meaningEn: "centripetal force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "v", nameJa: "速度", meaning: "接線方向の速度", unitSymbol: "m/s", baseUnits: "m·s^-1", dimension: "LT^-1"),
        SymbolDef(symbol: "r", nameJa: "半径", meaning: "円運動の半径", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "920EB060-409D-487A-A66A-01E8BB635B95",
        shortExplanation: r"\frac{mv^2}{r}\text{は円運動の向心力。}",
        shortExplanationEn: r"\frac{mv^2}{r}\text{ is centripetal force}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "D3D95D88-1BA3-4EE5-A8F5-89B07DDD4C63",
        shortExplanation: r"\frac{mv^2}{r}\text{は円運動の向心力。}",
        shortExplanationEn: r"\frac{mv^2}{r}\text{ is centripetal force}",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\mu N",
    meaning: "動摩擦力",
    meaningEn: "kinetic friction force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "μ", nameJa: "動摩擦係数", meaning: "摩擦の比例定数", unitSymbol: "無次元", baseUnits: "1", dimension: "無次元", texSymbol: r"\mu"),
        SymbolDef(symbol: "N", nameJa: "垂直抗力", meaning: "接触面に垂直な力", unitSymbol: "N", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "BB03DCD1-636F-4396-9E03-7B43C4FFAE2B",
        shortExplanation: r"\mu N\text{は動摩擦力。}",
        shortExplanationEn: r"\mu N\text{ is kinetic friction force}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "8C5B482B-CED1-4C87-9131-5C05C02ADFBF",
        shortExplanation: r"\mu N\text{は動摩擦力。}",
        shortExplanationEn: r"\mu N\text{ is kinetic friction force}",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\mu_{s} N",
    meaning: "最大静止摩擦力",
    meaningEn: "maximum static friction force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "μs", nameJa: "静止摩擦係数", meaning: "静止摩擦の比例定数", unitSymbol: "無次元", baseUnits: "1", dimension: "無次元", texSymbol: r"\mu_{s}"),
        SymbolDef(symbol: "N", nameJa: "垂直抗力", meaning: "接触面に垂直な力", unitSymbol: "N", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "DAEFCB52-3357-4313-B01E-B9BDCEF10857",
        shortExplanation: r"\mu_{s} N\text{は最大静止摩擦力。}",
        shortExplanationEn: r"\mu_{s} N\text{ is maximum static friction force}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "FFA645F1-EE40-4902-B5B4-33654E8611BD",
        shortExplanation: r"\mu_{s} N\text{は最大静止摩擦力。}",
        shortExplanationEn: r"\mu_{s} N\text{ is maximum static friction force}",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  // UnitExprProblem(
  //   expr: r"\mu_{s} N",
  //   meaning: "静止摩擦力",
  //   meaningEn: "static friction force",
  //   category: UnitCategory.mechanics,
  //   defs: [
  //       SymbolDef(symbol: "μs", nameJa: "静止摩擦係数", meaning: "静止摩擦の比例定数", unitSymbol: "無次元", baseUnits: "1", dimension: "無次元", texSymbol: r"\mu_{s}"),
  //       SymbolDef(symbol: "N", nameJa: "垂直抗力", meaning: "接触面に垂直な力", unitSymbol: "N", baseUnits: "kg·m·s^-2", dimension: "MLT^-2"),
  //     ],
  //   unitProblems: [
  //     UnitProblem(
  //       id: "10C071E8-425A-4489-B7BD-121DB42EF04B",
  //       shortExplanation: r"\mu_s N\text{は静止摩擦力。}",
  //       shortExplanationEn: r"\mu_s N\text{ is static friction force}",
  //       answer: "N",
  //       units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
  //     ),
  //     UnitProblem(
  //       id: "2B9A9355-E80D-4256-AA1F-4F088A56E3DD",
  //       shortExplanation: r"\mu_s N\text{は静止摩擦力。}",
  //       shortExplanationEn: r"\mu_s N\text{ is static friction force}",
  //       answer: "kg m s^-2",
  //       units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
  //     ),
  //   ],
  // ),
  UnitExprProblem(
    expr: r"\omega t",
    meaning: "角度",
    meaningEn: "angle",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "ω", nameJa: "角速度", meaning: "回転の角速度", unitSymbol: "rad/s", baseUnits: "s^-1", dimension: "T^-1", texSymbol: r"\omega"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "経過時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "2901DE4A-64E5-4D0F-A828-43D523342AFC",
        shortExplanation: r"\omega t\text{は角度。}",
        shortExplanationEn: r"\omega t\text{ is angle}",
        answer: "1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\rho h g",
    meaning: "流体の圧力",
    meaningEn: "fluid pressure",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "ρ", nameJa: "密度", meaning: "流体の密度", unitSymbol: "kg/m^3", baseUnits: "kg·m^-3", dimension: "ML^-3", texSymbol: r"\rho"),
        SymbolDef(symbol: "h", nameJa: "高さ", meaning: "深さ", unitSymbol: "m", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "g", nameJa: "重力加速度", meaning: "重力による加速度", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "0678A38A-01F5-45AC-9659-E304BCFC4F3C",
        shortExplanation: r"\rho h g\text{は流体の圧力。}",
        shortExplanationEn: r"\rho h g\text{ is fluid pressure}",
        answer: "Pa",
        units: ["m", "kg", "J", "W", "s^-1", "N", "Pa"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\sqrt{\frac{2GM}{r}}",
    meaning: "第二宇宙速度",
    meaningEn: "second cosmic velocity (escape velocity)",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "G", nameJa: "万有引力定数", meaning: "万有引力の比例定数", unitSymbol: "m^3·kg^-1·s^-2", baseUnits: "m^3·kg^-1·s^-2", dimension: "L^3M^-1T^-2"),
        SymbolDef(symbol: "M", nameJa: "質量", meaning: "中心天体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "r", nameJa: "半径", meaning: "軌道半径", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "D77AA956-CEE1-4461-8AE8-01554DE13196",
        shortExplanation: r"\sqrt{\frac{2GM}{r}}\text{は第二宇宙速度。}",
        shortExplanationEn: r"\sqrt{\frac{2GM}{r}}\text{ is second cosmic velocity (escape velocity)}",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\sqrt{\frac{GM}{R}}",
    meaning: "万有引力の場合の等速円運動の速度",
    meaningEn: "velocity of uniform circular motion under gravitational force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "G", nameJa: "万有引力定数", meaning: "万有引力の比例定数", unitSymbol: "m^3·kg^-1·s^-2", baseUnits: "m^3·kg^-1·s^-2", dimension: "L^3M^-1T^-2"),
        SymbolDef(symbol: "M", nameJa: "質量", meaning: "中心天体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "R", nameJa: "半径", meaning: "軌道半径", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "0813B05A-109E-4ACC-9F71-3B5A3EBEBEC6",
        shortExplanation: r"\sqrt{\frac{GM}{R}}\text{は万有引力の場合の等速円運動の速度。}",
        shortExplanationEn: r"\sqrt{\frac{GM}{R}}\text{ is velocity of uniform circular motion under gravitational force}",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\sqrt{\frac{GM}{r}}",
    meaning: "第一宇宙速度",
    meaningEn: "first cosmic velocity (circular orbital velocity)",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "G", nameJa: "万有引力定数", meaning: "万有引力の比例定数", unitSymbol: "m^3·kg^-1·s^-2", baseUnits: "m^3·kg^-1·s^-2", dimension: "L^3M^-1T^-2"),
        SymbolDef(symbol: "M", nameJa: "質量", meaning: "中心天体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "r", nameJa: "半径", meaning: "軌道半径", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "1B0565BF-F519-49C4-B1CE-329BA496CF50",
        shortExplanation: r"\sqrt{\frac{GM}{r}}\text{は第一宇宙速度。}",
        shortExplanationEn: r"\sqrt{\frac{GM}{r}}\text{ is first cosmic velocity (circular orbital velocity)}",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "a",
    meaning: "加速度",
    meaningEn: "acceleration",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "a", nameJa: "加速度", meaning: "速度の時間変化", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "436B028F-0641-4F2D-8A1B-3C9F8630FBC4",
        answer: "m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "e",
    meaning: "反発係数",
    meaningEn: "coefficient of restitution",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "e", nameJa: "反発係数", meaning: "衝突の反発係数", unitSymbol: "1", baseUnits: "1", dimension: "1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "0C21FA26-A3D2-4A99-B6E9-7E6F1FF096D0",
        shortExplanationEn: r"e\text{ is coefficient of restitution}",
        answer: "1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "f",
    meaning: "周波数",
    meaningEn: "frequency",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "f", nameJa: "周波数", meaning: "単位時間あたりの振動数", unitSymbol: "Hz", baseUnits: "s^-1", dimension: "T^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "63F5F5E5-D15A-4080-8BF3-DC6339B0F398",
        answer: "s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "gt",
    meaning: "自由落下の速度",
    meaningEn: "velocity of free fall",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "g", nameJa: "重力加速度", meaning: "重力による加速度", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "経過時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "06EFFA0D-A12B-42AD-9A59-96772F781AD4",
        shortExplanation: r"gt\text{は自由落下の速度。}",
        shortExplanationEn: r"gt\text{ is velocity of free fall}",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "k",
    meaning: "ばね定数",
    meaningEn: "spring constant",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "k", nameJa: "ばね定数", meaning: "ばねの硬さ", unitSymbol: "N/m", baseUnits: "kg·s^-2", dimension: "MT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "3002D5E0-C319-4931-9349-E123886B7B40",
        point:
            r"\text{フックの法則 }F=kx"
            "\n"
            r"\left[kx\right]=[F]=N"
            "\n"
            r"\therefore\ \left[k\right]=N\cdot\left[\frac{1}{x}\right]=N\cdot m^{-1}",
        pointEn:
            r"\text{Hooke's law }F=kx"
            "\n"
            r"\left[kx\right]=[F]=N"
            "\n"
            r"\therefore\ \left[k\right]=N\cdot\left[\frac{1}{x}\right]=N\cdot m^{-1}",
        answer: "N m^-1",
        units: ["m^-1", "kg^-1", "s^-1", "W", "m", "N"],
      ),
      UnitProblem(
        id: "465CA6F9-05F3-4A2F-A2CA-D5881880668C",
        point:
            r"\text{フックの法則 }F=kx\ \Rightarrow\ \left[k\right]=N\cdot m^{-1}"
            "\n"
            r"N=kg\cdot m\cdot s^{-2}"
            "\n"
            r"\therefore\ \left[k\right]=kg\cdot s^{-2}",
        pointEn:
            r"\text{Hooke's law }F=kx\ \Rightarrow\ \left[k\right]=N\cdot m^{-1}"
            "\n"
            r"N=kg\cdot m\cdot s^{-2}"
            "\n"
            r"\therefore\ \left[k\right]=kg\cdot s^{-2}",
        answer: "kg s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "kv",
    meaning: "空気抵抗",
    meaningEn: "air resistance",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "k", nameJa: "抵抗係数", meaning: "空気抵抗の比例定数", unitSymbol: "N·s/m", baseUnits: "kg·s^-1", dimension: "MT^-1"),
        SymbolDef(symbol: "v", nameJa: "速度", meaning: "位置の時間変化", unitSymbol: "m/s", baseUnits: "m·s^-1", dimension: "LT^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "E3110F62-71F2-4710-BA28-42630D447878",
        shortExplanation: r"kv\text{は空気抵抗。}",
        shortExplanationEn: r"kv\text{ is air resistance}",
        answer: "N",
        units: ["m", "kg", "s", "N", "Pa^-1", "J"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "kx",
    meaning: "ばねの力",
    meaningEn: "spring force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "k", nameJa: "ばね定数", meaning: "ばねの硬さ", unitSymbol: "N/m", baseUnits: "kg·s^-2", dimension: "MT^-2"),
        SymbolDef(symbol: "x", nameJa: "変位", meaning: "ばねの伸び", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "4792AEF8-6DD2-4504-B550-65AFBDD2E0E1",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
      UnitProblem(
        id: "A05EAE6D-7CAD-4407-B2CF-5D3B8E0CB056",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "m",
    meaning: "質量",
    meaningEn: "mass",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
      ],
    unitProblems: [
      UnitProblem(
        id: "42D9CE51-6E4C-42AE-A94A-65B29B485ADB",
        answer: "kg",
        units: ["m", "N", "kg", "s", "J", "W", "Pa"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ma",
    meaning: "力",
    meaningEn: "force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "a", nameJa: "加速度", meaning: "物体の加速度", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "2E0559B2-8231-45EE-87D1-1DB444F31DA4",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "5D3AE492-27BE-4CBE-B35B-E1CD67ED3919",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "mg",
    meaning: "重力",
    meaningEn: "gravitational force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "g", nameJa: "重力加速度", meaning: "地表付近で約9.8 m/s^2", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "69194DA4-4B17-4131-AFBE-E92D8EBF92CD",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "47946B54-173E-4941-B5B8-213E2035930C",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "mgh",
    meaning: "重力の位置エネルギー",
    meaningEn: "gravitational potential energy",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "g", nameJa: "重力加速度", meaning: "地表付近で約9.8 m/s^2", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
        SymbolDef(symbol: "h", nameJa: "高さ", meaning: "基準面からの高さ", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "ADDFEBBD-7F25-4CA1-85F5-C1600EC5683C",
        shortExplanation: r"mgh\text{は位置エネルギー。}",
        shortExplanationEn: r"mgh\text{ is gravitational potential energy}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
      UnitProblem(
        id: "7A0C5FB5-6D68-40DD-870D-6D99362A5F86",
        shortExplanation: r"mgh\text{は位置エネルギー。}",
        shortExplanationEn: r"mgh\text{ is gravitational potential energy}",
        answer: "N m",
        units: ["kg^-1", "Pa^-1", "W", "m", "s^-1", "N"],
      ),
      UnitProblem(
        id: "52EDC78C-968A-404E-84DF-A8FC32800B4E",
        shortExplanation: r"mgh\text{は位置エネルギー。}",
        shortExplanationEn: r"mgh\text{ is gravitational potential energy}",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "mrω^2",
    meaning: "向心力",
    meaningEn: "centripetal force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", unitSymbol: "kg", meaning: "質量", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "r", nameJa: "半径", unitSymbol: "m", meaning: "半径", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "ω", nameJa: "角速度", unitSymbol: "rad/s", meaning: "角速度", baseUnits: "s^-1", dimension: "T^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "D64891E4-9671-48D4-BD48-544E8C9074E8",
        shortExplanation: r"mr\omega^2\text{は向心力。単位は}N\text{(ニュートン)。}",
        shortExplanationEn: r"mr\omega^2\text{ is centripetal force}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "mv",
    meaning: "運動量",
    meaningEn: "momentum",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "m", nameJa: "質量", meaning: "物体の質量", unitSymbol: "kg", baseUnits: "kg", dimension: "M"),
        SymbolDef(symbol: "v", nameJa: "速度", meaning: "位置の時間変化", unitSymbol: "m/s", baseUnits: "m·s^-1", dimension: "LT^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "34F46FE4-8A15-4A60-A99D-F26C18EE0A2A",
        shortExplanation: r"mv\text{は運動量。}",
        shortExplanationEn: r"mv\text{ is momentum. Unit in base units: }kg \cdot m \cdot s^{-1}\text{.}",
        answer: "kg m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
      UnitProblem(
        id: "9170E02F-E99F-41A7-B7DA-1D8CA613A383",
        shortExplanation: r"mv\text{は運動量。力積と同じ単位。}",
        shortExplanationEn: r"mv\text{ is momentum. Same unit as impulse.}",
        point: r"\text{力積 }J=\int F\,dt=\Delta p=\Delta(mv)\ \Rightarrow\ [mv]=[F][t]=N\cdot s\ (=kg\cdot m\cdot s^{-1})",
        pointEn: r"\text{Impulse }J=\int F\,dt=\Delta p=\Delta(mv)\ \Rightarrow\ [mv]=[F][t]=N\cdot s\ (=kg\cdot m\cdot s^{-1})",
        answer: "N s",
        units: ["m", "kg", "s", "N", "Pa^-1", "J"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"r\omega^2",
    meaning: "遠心力加速度",
    meaningEn: "centrifugal acceleration",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "r", nameJa: "半径", meaning: "回転半径", unitSymbol: "m", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "ω", nameJa: "角速度", meaning: "回転の角速度", unitSymbol: "rad/s", baseUnits: "s^-1", dimension: "T^-1", texSymbol: r"\omega"),
      ],
    unitProblems: [
      UnitProblem(
        id: "905D6F74-EA41-4AB1-AACE-403A53873499",
        shortExplanation: r"r\omega^2\text{は遠心力加速度。}",
        shortExplanationEn: r"r\omega^2\text{ is centrifugal acceleration}",
        answer: "m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "v",
    meaning: "速度",
    meaningEn: "velocity",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "v", nameJa: "速度", meaning: "位置の時間変化", unitSymbol: "m/s", baseUnits: "m·s^-1", dimension: "LT^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "738431A5-4CCE-4DE7-A415-2BE480EA292C",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "x",
    meaning: "変位",
    meaningEn: "displacement",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "x", nameJa: "変位", meaning: "位置の変化", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "2D3BB982-74C5-4A5A-B056-5B2CC49750BE",
        answer: "m",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "μ",
    meaning: "動摩擦係数",
    meaningEn: "kinetic friction coefficient",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "μ", nameJa: "動摩擦係数", meaning: "摩擦の比例定数", unitSymbol: "無次元", baseUnits: "1", dimension: "無次元", texSymbol: r"\mu"),
      ],
    unitProblems: [
      UnitProblem(
        id: "121A7F9E-7B21-49B0-A038-787D870761FD",
        answer: "無次元",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
      // UnitProblem(
      //   id: "43DC5EC4-61B0-4570-BA05-EFF557E3AF92",
      //   answer: "1 (無次元)",
      //   units: ["m", "kg", "s", "1", "m^-1", "kg^-1", "s^-1"],
      // ),
    ],
  ),
  UnitExprProblem(
    expr: "ρVg",
    meaning: "浮力",
    meaningEn: "buoyant force",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "ρ", nameJa: "密度", meaning: "流体の密度", unitSymbol: "kg/m^3", baseUnits: "kg·m^-3", dimension: "ML^-3", texSymbol: r"\rho"),
        SymbolDef(symbol: "g", nameJa: "重力加速度", meaning: "地表付近で約9.8 m/s^2", unitSymbol: "m/s^2", baseUnits: "m·s^-2", dimension: "LT^-2"),
        SymbolDef(symbol: "V", nameJa: "体積", meaning: "物体の体積", unitSymbol: "m^3", baseUnits: "m^3", dimension: "L^3"),
      ],
    unitProblems: [
      UnitProblem(
        id: "6E2FEC3C-1B18-4D24-99DA-DF7F77BFAE96",
        shortExplanation: r"\rho Vg\text{は浮力。}",
        shortExplanationEn: r"\rho Vg\text{ is buoyant force}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "F14299B7-353E-47D9-A9B1-707EACBBA80F",
        shortExplanation: r"\rho Vg\text{は浮力。}",
        shortExplanationEn: r"\rho Vg\text{ is buoyant force}",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "τ",
    meaning: "力のモーメント",
    meaningEn: "torque",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "τ", nameJa: "力のモーメント", meaning: "回転させる力", unitSymbol: "N·m", baseUnits: "kg·m^2·s^-2", dimension: "ML^2T^-2", texSymbol: r"\tau"),
      ],
    unitProblems: [
      UnitProblem(
        id: "7B4F0645-05B8-4768-8E9E-1E6BB9E664F0",
        answer: "N m",
        units: ["kg^-1", "Pa^-1", "W", "m", "s^-1", "N"],
      ),
      UnitProblem(
        id: "230ABF22-A1B7-43DE-AE3C-1F2912757F28",
        answer: "kg m^2 s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "mrv",
    meaning: "角運動量",
    meaningEn: "Angular momentum",
    category: UnitCategory.mechanics,
    defs: [
      SymbolDef(
        symbol: "m",
        nameJa: "質量",
        meaning: "物体の質量",
        unitSymbol: "kg",
        baseUnits: "kg",
        dimension: "M",
      ),
      SymbolDef(
        symbol: "r",
        nameJa: "半径",
        meaning: "回転半径",
        unitSymbol: "m",
        baseUnits: "m",
        dimension: "L",
      ),
      SymbolDef(
        symbol: "v",
        nameJa: "速度",
        meaning: "物体の速度",
        unitSymbol: "m/s",
        baseUnits: "m·s^-1",
        dimension: "LT^-1",
      ),
    ],
    unitProblems: [
      UnitProblem(
        id: "90A489C3-5946-43CA-AFA9-B61A84D74F6C",
        shortExplanation: r"mrv\text{は角運動量。}",
        shortExplanationEn: r"mrv\text{ is angular momentum.}",
        answer: "J s",
        units: ["J", "m", "s", "A", "J^-1", "m^-1", "s^-1", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ω",
    meaning: "角速度",
    meaningEn: "angular velocity",
    category: UnitCategory.mechanics,
    defs: [
        SymbolDef(symbol: "ω", nameJa: "角速度", meaning: "回転の速さ", unitSymbol: "rad/s", baseUnits: "s^-1", dimension: "T^-1", texSymbol: r"\omega"),
      ],
    unitProblems: [
      UnitProblem(
        id: "8D4494A7-AB62-47C0-A6B0-6429F4AFE986",
        answer: "s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
];
