import 'symbol.dart';
import 'unit_expr_problem.dart';

// 電磁気学の問題（expr単位で集約・category/defs内包）
final electromagnetismExprProblems = <UnitExprProblem>[
  UnitExprProblem(
    expr: "B",
    meaning: "磁束密度",
    meaningEn: "magnetic flux density",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "B", nameJa: "磁束密度", meaning: "磁場の密度", unitSymbol: "T", baseUnits: "kg·s^-2·A^-1", dimension: "MT^-2I^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "5BDE51F0-0FD4-4691-A5EF-F03548C58133",
        answer: "T",
        units: ["Wb", "H", "A", "T", "F", "V"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "BS",
    meaning: "磁束",
    meaningEn: "magnetic flux",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "B", nameJa: "磁束密度", meaning: "磁場の密度", unitSymbol: "T", baseUnits: "kg·s^-2·A^-1", dimension: "MT^-2I^-1"),
        SymbolDef(symbol: "S", nameJa: "面積", meaning: "磁束が貫く面積", unitSymbol: "m^2", baseUnits: "m^2", dimension: "L^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "72D8490C-79B2-4B7E-A7B3-03D8F0C8DB84",
        shortExplanation: r"BS\text{は磁束。}",
        shortExplanationEn: r"BS\text{ is magnetic flux}",
        answer: "T m^2",
        units: ["T", "m", "A^-1", "H", "W", "s^-1", "Ω"],
      ),
      UnitProblem(
        id: "E4CF5C99-B002-4A8F-B055-F307AE05ABC8",
        shortExplanation: r"BS\text{は磁束。}",
        shortExplanationEn: r"BS\text{ is magnetic flux}",
        answer: "Wb",
        units: ["Wb", "T", "H", "V", "W", "J", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "C",
    meaning: "静電容量",
    meaningEn: "capacitance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "C", nameJa: "静電容量", meaning: "コンデンサの容量", unitSymbol: "F", baseUnits: "kg^-1·m^-2·s^4·A^2", dimension: "M^-1L^-2T^4I^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "35439608-B005-4E18-BEA9-9E29B1CD9F1D",
        answer: "F",
        units: ["F", "C", "V", "W", "A", "Ω", "s", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "CV",
    meaning: "電荷",
    meaningEn: "electric charge",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "C", nameJa: "静電容量", meaning: "コンデンサの容量", unitSymbol: "F", baseUnits: "kg^-1·m^-2·s^4·A^2", dimension: "M^-1L^-2T^4I^2"),
        SymbolDef(symbol: "V", nameJa: "電圧", meaning: "電位差", unitSymbol: "V", baseUnits: "kg·m^2·s^-3·A^-1", dimension: "ML^2T^-3I^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "9D3ED011-9CC0-4A76-9B15-AEEEBF12D8ED",
        shortExplanation: r"CV\text{は電荷。}",
        shortExplanationEn: r"CV\text{ is electric charge}",
        answer: "C",
        units: ["C", "s^-1", "Ω", "A", "V", "m^-1", "J"],
      ),
      UnitProblem(
        id: "DD0A14E2-E0FE-4F51-9053-287A642CCD9B",
        point:
            r"Q=It\ \Rightarrow\ [Q]=[I]\cdot[t]=A\cdot s",
        pointEn:
            r"Q=It\ \Rightarrow\ [Q]=[I]\cdot[t]=A\cdot s",
        shortExplanation: r"CV\text{は電荷。}",
        shortExplanationEn: r"CV\text{ is electric charge}",
        answer: "A s",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "E",
    meaning: "電場",
    meaningEn: "electric field",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "E", nameJa: "電界", meaning: "電場の強さ", unitSymbol: "N/C", baseUnits: "kg·m·s^-3·A^-1", dimension: "MLT^-3I^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "35397F41-E94A-4DD6-8C5B-D98A20550F3E",
        answer: "N C^-1",
        units: ["C^-1", "W", "J", "N", "V", "Ω", "A^-1"],
      ),
      UnitProblem(
        id: "E07A3193-7CCF-4D91-B63B-B6E319459E4E",
        point:
            r"V=Ed\ \Rightarrow\ [E]=\left[\frac{V}{d}\right]=V\cdot m^{-1}",
        pointEn:
            r"V=Ed\ \Rightarrow\ [E]=\left[\frac{V}{d}\right]=V\cdot m^{-1}",
        answer: "V m^-1",
        units: ["V", "J", "C", "W", "F", "A", "kg", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ES",
    meaning: "電場フラックス",
    meaningEn: "electric field flux",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "E", nameJa: "電場", meaning: "電場の強さ", unitSymbol: "V/m", baseUnits: "kg·m·s^-3·A^-1", dimension: "MLT^-3I^-1"),
        SymbolDef(symbol: "S", nameJa: "面積", meaning: "電束が貫く面積", unitSymbol: "m^2", baseUnits: "m^2", dimension: "L^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "03C0EE84-F868-43DC-90A7-1FA8DDB0A3D0",
        point:
            r"\text{ガウスの法則 }\displaystyle \oint \vec{E}\cdot d\vec{S}=\frac{Q}{\epsilon_{0}}"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=\left[\frac{Q}{\epsilon_{0}}\right]"
            "\n"
            r"\text{また }V=Ed\ \Rightarrow\ [Ed]=[E]\cdot m=V"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=V\cdot m\ \Rightarrow\ [ES]=V\cdot m",
        pointEn:
            r"\text{Gauss's law }\displaystyle \oint \vec{E}\cdot d\vec{S}=\frac{Q}{\epsilon_{0}}"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=\left[\frac{Q}{\epsilon_{0}}\right]"
            "\n"
            r"\text{Also }V=Ed\ \Rightarrow\ [Ed]=[E]\cdot m=V"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=V\cdot m\ \therefore\ [ES]=V\cdot m",
        shortExplanation: r"ES\text{は電場フラックス（電場の面積積）。単位は}V\cdot m\text{（あるいは }kg\cdot m^3\cdot s^{-3}\cdot A^{-1}\text{）。}",
        shortExplanationEn: r"ES\text{ is electric field flux (field area product)}",
        answer: "V m",
        units: ["V", "m", "W", "s^-1", "C", "J", "A"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "Ed",
    meaning: "起電力(電圧)",
    meaningEn: "electromotive force (voltage)",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "E", nameJa: "電場", unitSymbol: "V/m", meaning: "電場", baseUnits: "kg·m·s^-3·A^-1", dimension: "MLT^-3I^-1"),
        SymbolDef(symbol: "d", nameJa: "長さ", unitSymbol: "m", meaning: "積分路の長さ", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "AFD97460-8D70-466C-8612-7481B1B140F3",
        shortExplanation: r"Ed\text{は起電力(電圧)。}",
        shortExplanationEn: r"Ed\text{ is electromotive force (voltage)}",
        answer: "V",
        units: ["V", "J", "C", "W", "F", "A", "kg"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "H",
    meaning: "磁場の強さ",
    meaningEn: "magnetic field strength",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "H", nameJa: "磁場", meaning: "磁場の強さ", unitSymbol: "A/m", baseUnits: "A·m^-1", dimension: "IL^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "832E011A-37A7-42E0-A4D2-F952FA27AF8B",
        answer: "A m^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "I",
    meaning: "電流",
    meaningEn: "electric current",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "FA94334D-DCDE-42AB-B231-AE69A8478B1B",
        answer: "A",
        units: ["V", "C", "W", "A", "V^-1", "C^-1", "W^-1", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "IBℓ",
    meaning: "導体に働く力",
    meaningEn: "force on conductor",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "B", nameJa: "磁束密度", meaning: "磁場の密度", unitSymbol: "T", baseUnits: "kg·s^-2·A^-1", dimension: "MT^-2I^-1"),
        SymbolDef(symbol: "ℓ", nameJa: "長さ", meaning: "導体の有効長", unitSymbol: "m", baseUnits: "m", dimension: "L", texSymbol: r"\ell"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "51BBB464-AAE2-4E69-96D1-32D7C9ED8B40",
        shortExplanation: r"B\ell I\text{は導体に働く力。}",
        shortExplanationEn: r"B\ell I\text{ is force on conductor}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "FB0FD76E-9440-42C1-B59E-74CFCFFF9BD5",
        shortExplanation: r"B\ell I\text{は導体に働く力。}",
        shortExplanationEn: r"B\ell I\text{ is force on conductor}",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "It",
    meaning: "電荷",
    meaningEn: "electric charge",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "経過時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "34E39F5C-AAA2-4950-8D62-9B017C74937B",
        shortExplanation: r"It\text{は電荷。}",
        shortExplanationEn: r"It\text{ is electric charge}",
        answer: "C",
        units: ["C", "s^-1", "Ω", "A", "V", "m^-1", "J"],
      ),
      UnitProblem(
        id: "E4FA610A-95CC-4145-BCE8-1905D0AECC32",
        shortExplanation: r"It\text{は電荷。}",
        shortExplanationEn: r"It\text{ is electric charge}",
        answer: "A s",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "L",
    meaning: "インダクタンス",
    meaningEn: "inductance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "L", nameJa: "インダクタンス", meaning: "起電力=−L di/dt の比例係数", unitSymbol: "H", baseUnits: "kg·m^2·s^-2·A^-2", dimension: "ML^2T^-2I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "51EB1258-D006-4BDB-8534-4E59EEBB3D73",
        answer: "H",
        units: ["H", "m^-1", "Wb", "A", "T", "F", "s"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "LI",
    meaning: "コイルを貫く全磁束",
    meaningEn: "total magnetic flux through coil",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "L", nameJa: "インダクタンス", meaning: "起電力=−L di/dt の比例係数", unitSymbol: "H", baseUnits: "kg·m^2·s^-2·A^-2", dimension: "ML^2T^-2I^-2"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "0ACA4D18-F206-46CB-8CEF-FACC1EC7B13B",
        shortExplanation: r"LI\text{はコイルを貫く全磁束。}",
        shortExplanationEn: r"LI\text{ is total magnetic flux through coil}",
        answer: "Wb",
        units: ["Wb", "T", "H", "V", "W", "J", "m^-1"],
      ),
      UnitProblem(
        id: "D5C43D85-0E0D-45AD-8A41-F0DD4DA64EAF",
        shortExplanation: r"LI\text{はコイルを貫く全磁束。}",
        shortExplanationEn: r"LI\text{ is total magnetic flux through coil}",
        answer: "V s",
        units: ["V", "m", "W", "s", "C", "J", "A"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "MI",
    meaning: "2次コイルを貫く全磁束",
    meaningEn: "total magnetic flux through secondary coil",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "M", nameJa: "相互誘導係数", meaning: "相互誘導係数", unitSymbol: "H", baseUnits: "kg·m^2·s^-2·A^-2", dimension: "ML^2T^-2I^-2"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "BF0B33BD-1B85-4B20-9836-4E0C04591A4D",
        shortExplanation: r"MI\text{は2次コイルを貫く全磁束。}",
        shortExplanationEn: r"MI\text{ is total magnetic flux through secondary coil}",
        answer: "Wb",
        units: ["Wb", "T", "H", "V", "W", "J", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"M\frac{dI}{dt}",
    meaning: "相互誘導起電力",
    meaningEn: "electromotive force due to mutual induction",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "M", nameJa: "相互誘導係数", meaning: "相互誘導係数", unitSymbol: "H", baseUnits: "kg·m^2·s^-2·A^-2", dimension: "ML^2T^-2I^-2"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "経過時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "DC45A331-87DE-405B-B4AD-033A822EAD9B",
        shortExplanation: r"M\frac{dI}{dt}\text{は相互誘導起電力。}",
        shortExplanationEn: r"M\frac{dI}{dt}\text{ is electromotive force due to mutual induction}",
        answer: "V",
        units: ["V", "J", "C", "W", "F", "A", "kg"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "Q",
    meaning: "電荷",
    meaningEn: "electric charge",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Q", nameJa: "電荷", meaning: "電気量", unitSymbol: "C", baseUnits: "A·s", dimension: "TI"),
      ],
    unitProblems: [
      UnitProblem(
        id: "9AABAE69-6F39-42C7-BD74-D0D2E094F347",
        answer: "C",
        units: ["C", "s^-1", "Ω", "A", "V", "m^-1", "J"],
      ),
      UnitProblem(
        id: "C38EA3D8-41C0-43FE-B60D-B016B57E7E71",
        answer: "A s",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "R",
    meaning: "抵抗",
    meaningEn: "resistance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "R", nameJa: "抵抗", meaning: "電流の流れにくさ", unitSymbol: "Ω", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "0D9204EB-2A76-4A1B-9D29-11028AFE5B7E",
        answer: "Ω",
        units: ["Ω", "V", "A", "C", "J", "s", "m", "V^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "RC",
    meaning: "時定数",
    meaningEn: "time constant",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "R", nameJa: "抵抗", meaning: "電流の流れにくさ", unitSymbol: "Ω", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
        SymbolDef(symbol: "C", nameJa: "静電容量", meaning: "コンデンサの容量", unitSymbol: "F", baseUnits: "kg^-1·m^-2·s^4·A^2", dimension: "M^-1L^-2T^4I^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "6EAB4450-B81A-46E7-A4C6-F303923DADF7",
        shortExplanation: r"RC\text{は時定数。}",
        shortExplanationEn: r"RC\text{ is time constant}",
        answer: "s",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "RI",
    meaning: "抵抗による電圧降下",
    meaningEn: "voltage drop across a resistor",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "R", nameJa: "抵抗", meaning: "電流の流れにくさ", unitSymbol: "Ω", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "F02BFAC8-C113-48D4-84B4-CC7F6E76150F",
        shortExplanation: r"RI\text{は抵抗による電圧降下。}",
        shortExplanationEn: r"RI\text{ is the voltage drop across a resistor}",
        answer: "V",
        units: ["V", "J", "C", "W", "F", "A", "kg"],
      ),
      UnitProblem(
        id: "8C4243BF-1110-4EB8-A1E9-D63955860CEF",
        shortExplanation: r"RI\text{は抵抗による電圧降下。}",
        shortExplanationEn: r"RI\text{ is the voltage drop across a resistor}",
        answer: "J C^-1",
        units: ["J", "C^-1", "Ω", "s^-1", "m", "W"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "RI^2",
    meaning: "消費電力",
    meaningEn: "power consumption",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "I", nameJa: "電流", unitSymbol: "A", meaning: "電流", baseUnits: "A", dimension: "I"),
        SymbolDef(symbol: "R", nameJa: "抵抗", unitSymbol: "Ω", meaning: "抵抗", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "1448A467-397C-4B96-9B30-EB980574347B",
        point:
            r"V=RI\ \Rightarrow\ [RI]=[V]"
            "\n"
            r"\therefore\ [RI^{2}]=[RI]\cdot[I]=[V]\cdot A"
            "\n"
            r"[V]=\frac{J}{C},\ C=A\cdot s\ \Rightarrow\ [RI^{2}]=\frac{J}{C}\cdot A=\frac{J}{s}"
            "\n"
            r"=W",
        pointEn:
            r"V=RI\ \Rightarrow\ [RI]=[V]"
            "\n"
            r"\therefore\ [RI^{2}]=[RI]\cdot[I]=[V]\cdot A"
            "\n"
            r"[V]=\frac{J}{C},\ C=A\cdot s\ \Rightarrow\ [RI^{2}]=\frac{J}{C}\cdot A=\frac{J}{s}"
            "\n"
            r"=W",
        shortExplanation: r"RI^2\text{は消費電力。}",
        shortExplanationEn: r"RI^2\text{ is power consumption}",
        answer: "W",
        units: ["Pa", "kg", "J", "W", "s", "m^-1", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "RI^2t",
    meaning: "ジュール熱",
    meaningEn: "Joule heat",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "I", nameJa: "電流", unitSymbol: "A", meaning: "電流", baseUnits: "A", dimension: "I"),
        SymbolDef(symbol: "R", nameJa: "抵抗", unitSymbol: "Ω", meaning: "抵抗", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
        SymbolDef(symbol: "t", nameJa: "時間", unitSymbol: "s", meaning: "時間", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "DACD9E56-875B-4D7C-9B60-17AFA191E2E1",
        point:
            r"RI^{2}\text{は抵抗での消費電力 }P"
            "\n"
            r"\therefore\ [RI^{2}]=[P]=W=\frac{J}{s}"
            "\n"
            r"[RI^{2}t]=\frac{J}{s}\cdot s=J",
        pointEn:
            r"RI^{2}\text{ is power dissipated in a resistor }P"
            "\n"
            r"\therefore\ [RI^{2}]=[P]=W=\frac{J}{s}"
            "\n"
            r"[RI^{2}t]=\frac{J}{s}\cdot s=J",
        shortExplanation: r"R I^2 t\text{はジュール熱。}",
        shortExplanationEn: r"R I^2 t\text{ is Joule heat}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "V",
    meaning: "電圧",
    meaningEn: "voltage",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "V", nameJa: "電圧", meaning: "電位差", unitSymbol: "V", baseUnits: "kg·m^2·s^-3·A^-1", dimension: "ML^2T^-3I^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "F04D70CD-0A3B-4B01-8FDF-8E9ADC35B95A",
        answer: "V",
        units: ["V", "J", "C", "W", "F", "A", "kg"],
      ),
      UnitProblem(
        id: "D64891E4-9671-48D4-BD48-544E8C9074E8",
        answer: "J C^-1",
        units: ["J", "C^-1", "Ω", "s^-1", "m", "W"],
      ),
      // UnitProblem(
      //   id: "062A257B-11DB-44F3-91A1-3F0F1D01BF38",
      //   answer: "kg m^2 s^-3 A^-1",
      //   units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      // ),
    ],
  ),
  UnitExprProblem(
    expr: "VI",
    meaning: "電力",
    meaningEn: "electric power",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "V", nameJa: "電圧", meaning: "電位差", unitSymbol: "V", baseUnits: "kg·m^2·s^-3·A^-1", dimension: "ML^2T^-3I^-1"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "4847A62B-EA8E-480F-A40F-95B9A5E3F75F",
        point:
            r"[VI]=[V]\cdot[I]"
            "\n"
            r"[V]=\frac{J}{C},\ C=A\cdot s\ \Rightarrow\ [V]=\frac{J}{A\cdot s}"
            "\n"
            r"\therefore\ [VI]=\frac{J}{A\cdot s}\cdot A=\frac{J}{s}=W",
        pointEn:
            r"[VI]=[V]\cdot[I]"
            "\n"
            r"[V]=\frac{J}{C},\ C=A\cdot s\ \Rightarrow\ [V]=\frac{J}{A\cdot s}"
            "\n"
            r"\therefore\ [VI]=\frac{J}{A\cdot s}\cdot A=\frac{J}{s}=W",
        shortExplanation: r"VI\text{は電力。}",
        shortExplanationEn: r"VI\text{ is electric power}",
        answer: "W",
        units: ["Pa", "kg", "J", "W", "s", "m^-1", "N"],
      ),
      UnitProblem(
        id: "2DAFB67E-C8DB-4010-A1E1-9A38DB5FB0B4",
        point:
            r"[VI]=[V]\cdot[I]"
            "\n"
            r"[V]=\frac{J}{C},\ C=A\cdot s\ \Rightarrow\ [V]=\frac{J}{A\cdot s}"
            "\n"
            r"\therefore\ [VI]=\frac{J}{A\cdot s}\cdot A=\frac{J}{s}",
        pointEn:
            r"[VI]=[V]\cdot[I]"
            "\n"
            r"[V]=\frac{J}{C},\ C=A\cdot s\ \Rightarrow\ [V]=\frac{J}{A\cdot s}"
            "\n"
            r"\therefore\ [VI]=\frac{J}{A\cdot s}\cdot A=\frac{J}{s}",
        shortExplanation: r"VI\text{は電力。}",
        shortExplanationEn: r"VI\text{ is electric power}",
        answer: "J s^-1",
        units: ["Pa", "kg", "J", "m^-1", "s^-1", "s", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "Z",
    meaning: "インピーダンス",
    meaningEn: "impedance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Z", nameJa: "インピーダンス", meaning: "交流回路の総抵抗", unitSymbol: "Ω", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "8696A1E5-827F-4808-B57F-E700F70B8766",
        answer: "Ω",
        units: ["Ω", "V", "A", "C", "J", "s", "m", "V^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\epsilon_0 \frac{ d\Phi_E}{dt}",
    meaning: "変位電流",
    meaningEn: "displacement current",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ε0", nameJa: "真空の誘電率", unitSymbol: "F/m", meaning: "誘電率", baseUnits: "kg^-1·m^-3·s^4·A^2", dimension: "M^-1L^-3T^4I^2", texSymbol: r"\epsilon_{0}"),
        SymbolDef(symbol: "Φ_E", nameJa: "電束", unitSymbol: "V·m", meaning: "電束", baseUnits: "kg·m^3·s^-3·A^-1", dimension: "ML^3T^-3I^-1", texSymbol: r"\Phi_{E}"),
        SymbolDef(symbol: "t", nameJa: "時間", unitSymbol: "s", meaning: "時間", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "D9540752-F5CA-40E3-90CB-89CD8B3B2948",
        shortExplanation: r"\epsilon_0\frac{d\Phi_E}{dt}\text{は変位電流。}",
        shortExplanationEn: r"\epsilon_0\frac{d\Phi_E}{dt}\text{ is displacement current}",
        answer: "A",
        units: ["V", "C", "W", "A", "V^-1", "C^-1", "W^-1", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}CV^2",
    meaning: "静電エネルギー",
    meaningEn: "electrostatic energy",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "C", nameJa: "静電容量", unitSymbol: "F", meaning: "コンデンサの容量", baseUnits: "kg^-1·m^-2·s^4·A^2", dimension: "M^-1L^-2T^4I^2"),
        SymbolDef(symbol: "V", nameJa: "電圧", unitSymbol: "V", meaning: "電位差", baseUnits: "kg·m^2·s^-3·A^-1", dimension: "ML^2T^-3I^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "E194D0D0-8707-419D-BD85-8992CC7127A0",
        shortExplanation: r"\frac{1}{2}CV^2\text{は静電エネルギー。}",
        shortExplanationEn: r"\frac{1}{2}CV^2\text{ is electrostatic energy}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}LI^2",
    meaning: "コイルの磁気エネルギー",
    meaningEn: "coil magnetic energy",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "L", nameJa: "インダクタンス", unitSymbol: "H", meaning: "インダクタンス", baseUnits: "kg·m^2·s^-2·A^-2", dimension: "ML^2T^-2I^-2"),
        SymbolDef(symbol: "I", nameJa: "電流", unitSymbol: "A", meaning: "電流", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "C84409CC-FF2F-4802-8D75-23BE3583A740",
        shortExplanation: r"\frac{1}{2}LI^2\text{はコイルの磁気エネルギー。}",
        shortExplanationEn: r"\frac{1}{2}LI^2\text{ is magnetic energy}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}QV",
    meaning: "静電エネルギー",
    meaningEn: "electrostatic energy",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Q", nameJa: "電荷", meaning: "電気量", unitSymbol: "C", baseUnits: "A·s", dimension: "TI"),
        SymbolDef(symbol: "V", nameJa: "電圧", meaning: "電位差", unitSymbol: "V", baseUnits: "kg·m^2·s^-3·A^-1", dimension: "ML^2T^-3I^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "973FEE2A-026A-49D4-ADFC-79401F642427",
        shortExplanation: r"\frac{1}{2}QV\text{は静電エネルギー。}",
        shortExplanationEn: r"\frac{1}{2}QV\text{ is electrostatic energy}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{2}\epsilon_0E^2",
    meaning: "エネルギー密度",
    meaningEn: "energy density",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ε0", nameJa: "真空の誘電率", unitSymbol: "F/m", meaning: "誘電率", baseUnits: "kg^-1·m^-3·s^4·A^2", dimension: "M^-1L^-3T^4I^2", texSymbol: r"\epsilon_{0}"),
        SymbolDef(symbol: "E", nameJa: "電場", unitSymbol: "V/m", meaning: "電場", baseUnits: "kg·m·s^-3·A^-1", dimension: "MLT^-3I^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "768C5DC0-F7C2-42C8-89BE-21954CD4D175",
        shortExplanation: r"\frac{1}{2}\epsilon_0 E^2\text{はエネルギー密度。}",
        shortExplanationEn: r"\frac{1}{2}\epsilon_0 E^2\text{ is energy density}",
        answer: "J m^-3",
        units: ["J", "m^-1", "W", "s^-1", "A", "C^-1", "V"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{\omega C}",
    meaning: "容量性リアクタンス",
    meaningEn: "capacitive reactance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ω", nameJa: "角周波数", meaning: "2πf", unitSymbol: "rad/s", baseUnits: "s^-1", dimension: "T^-1", texSymbol: r"\omega"),
        SymbolDef(symbol: "C", nameJa: "静電容量", meaning: "コンデンサの容量", unitSymbol: "F", baseUnits: "kg^-1·m^-2·s^4·A^2", dimension: "M^-1L^-2T^4I^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "3DC3ABFD-DD0F-4F8D-BF75-9645C1296517",
        shortExplanation: r"\frac{1}{\omega C}\text{は容量性リアクタンス。}",
        shortExplanationEn: r"\frac{1}{\omega C}\text{ is capacitive reactance}",
        answer: "Ω",
        units: ["Ω", "V", "A", "C", "J", "s", "m", "V^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{\sqrt{LC}}",
    meaning: "LC共振周波数",
    meaningEn: "LC resonance frequency",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "L", nameJa: "インダクタンス", meaning: "起電力=−L di/dt の比例係数", unitSymbol: "H", baseUnits: "kg·m^2·s^-2·A^-2", dimension: "ML^2T^-2I^-2"),
        SymbolDef(symbol: "C", nameJa: "静電容量", meaning: "コンデンサの容量", unitSymbol: "F", baseUnits: "kg^-1·m^-2·s^4·A^2", dimension: "M^-1L^-2T^4I^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "47E1D0F8-0876-4A0B-B246-A82A9FF62400",
        shortExplanation: r"\frac{1}{\sqrt{LC}}\text{はLC共振周波数。}",
        shortExplanationEn: r"\frac{1}{\sqrt{LC}}\text{ is LC resonance frequency}",
        answer: "Hz",
        units: ["Hz", "s^-1", "rad/s", "m^-1", "kg^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{1}{\sqrt{\epsilon_0\mu_0}}",
    meaning: "光速",
    meaningEn: "speed of light",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ε0", nameJa: "真空の誘電率", unitSymbol: "F/m", meaning: "誘電率", baseUnits: "kg^-1·m^-3·s^4·A^2", dimension: "M^-1L^-3T^4I^2", texSymbol: r"\epsilon_{0}"),
        SymbolDef(symbol: "μ0", nameJa: "真空の透磁率", unitSymbol: "H/m", meaning: "透磁率", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu_{0}"),
      ],
    unitProblems: [
      UnitProblem(
        id: "196A69E4-817D-4C53-BF27-581B6D171A1B",
        shortExplanation: r"\frac{1}{\sqrt{\epsilon_0\mu_0}}\text{は光速。}",
        shortExplanationEn: r"\frac{1}{\sqrt{\epsilon_0\mu_0}}\text{ is speed of light}",
        answer: "m s^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{B^2}{2\mu_0}",
    meaning: "磁場のエネルギー密度",
    meaningEn: "magnetic field energy density",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "B", nameJa: "磁束密度", meaning: "磁束密度", unitSymbol: "T", baseUnits: "kg·s^-2·A^-1", dimension: "MT^-2I^-1"),
        SymbolDef(symbol: "μ0", nameJa: "真空の透磁率", meaning: "透磁率", unitSymbol: "H/m", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu_{0}"),
      ],
    unitProblems: [
      UnitProblem(
        id: "C0DB4912-4B6E-4398-B025-D3C9F9530357",
        shortExplanation: r"\frac{B^2}{2\mu_0}\text{は磁場のエネルギー密度。}",
        shortExplanationEn: r"\frac{B^2}{2\mu_0}\text{ is magnetic field energy density}",
        answer: "J m^-3",
        units: ["J", "m^-1", "W", "s^-1", "A", "C^-1", "V"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{I}{2\pi r}",
    meaning: "磁場の強さ",
    meaningEn: "magnetic field strength",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "I", nameJa: "電流", unitSymbol: "A", meaning: "電流", baseUnits: "A", dimension: "I"),
        SymbolDef(symbol: "r", nameJa: "距離", unitSymbol: "m", meaning: "距離", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "8BD9C2C4-3AFC-4475-841B-81D58E71CDC7",
        shortExplanation: r"\frac{I}{2\pi r}\text{は磁場の強さ。}",
        shortExplanationEn: r"\frac{I}{2\pi r}\text{ is magnetic field strength}",
        answer: "A m^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{I}{2r}",
    meaning: "回転電流による磁場の強さ",
    meaningEn: "magnetic field strength due to circular current",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
        SymbolDef(symbol: "r", nameJa: "半径", meaning: "回転電流の半径", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "6D5DEBAE-10EF-4309-8256-C8B96881980F",
        shortExplanation: r"\frac{I}{2r}\text{は回転電流による磁場の強さ。}",
        shortExplanationEn: r"\frac{I}{2r}\text{ is magnetic field strength due to circular current}",
        answer: "A m^-1",
        units: ["A", "m^-1", "H", "T", "Wb", "V"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{L}{R}",
    meaning: "時定数",
    meaningEn: "time constant",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "L", nameJa: "インダクタンス", meaning: "起電力=−L di/dt の比例係数", unitSymbol: "H", baseUnits: "kg·m^2·s^-2·A^-2", dimension: "ML^2T^-2I^-2"),
        SymbolDef(symbol: "R", nameJa: "抵抗", meaning: "電流の流れにくさ", unitSymbol: "Ω", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "552F3745-F931-4433-BAFD-C2583F85DF6D",
        shortExplanation: r"\frac{L}{R}\text{は時定数。}",
        shortExplanationEn: r"\frac{L}{R}\text{ is time constant}",
        answer: "s",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{Q^2}{2C}",
    meaning: "静電エネルギー",
    meaningEn: "electrostatic energy",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Q", nameJa: "電荷", meaning: "電気量", unitSymbol: "C", baseUnits: "A·s", dimension: "TI"),
        SymbolDef(symbol: "C", nameJa: "静電容量", meaning: "コンデンサの容量", unitSymbol: "F", baseUnits: "kg^-1·m^-2·s^4·A^2", dimension: "M^-1L^-2T^4I^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "B8EE9732-9908-424E-A0EA-93EC37D3B1F0",
        shortExplanation: r"\frac{Q^2}{2C}\text{は静電エネルギー。}",
        shortExplanationEn: r"\frac{Q^2}{2C}\text{ is electrostatic energy}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{Q^2}{2\epsilon_{0} S}",
    meaning: "コンデンサ極板間引力",
    meaningEn: "force between capacitor plates",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Q", nameJa: "電荷", meaning: "電気量", unitSymbol: "C", baseUnits: "A·s", dimension: "TI"),
        SymbolDef(symbol: "ε0", nameJa: "真空の誘電率", unitSymbol: "F/m", meaning: "誘電率", baseUnits: "kg^-1·m^-3·s^4·A^2", dimension: "M^-1L^-3T^4I^2", texSymbol: r"\epsilon_{0}"),
        SymbolDef(symbol: "S", nameJa: "面積", unitSymbol: "m^2", meaning: "極板面積", baseUnits: "m^2", dimension: "L^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "0C973003-2ABA-4FBD-BE24-CB0AD53CFEC9",
        point:
            r"\text{係数 }2\text{ は無次元。}"
            "\n"
            r"\text{また点電荷間のクーロン力 }F=\frac{1}{4\pi\epsilon_{0}}\frac{q_{1}q_{2}}{r^{2}}\text{ も}"
            "\n"
            r"\text{電荷}^{2}/(\epsilon_{0}\times\text{面積})\text{ の形（}4\pi\text{も無次元）}"
            "\n"
            r"\Rightarrow\ \left[\frac{Q^{2}}{\epsilon_{0}S}\right]=\left[\frac{q_{1}q_{2}}{\epsilon_{0}r^{2}}\right]=[F]=N",
        pointEn:
            r"\text{The factor }2\text{ is dimensionless.}"
            "\n"
            r"\text{Similarly, as a comparable form, Coulomb's law }F=\frac{1}{4\pi\epsilon_{0}}\frac{q_{1}q_{2}}{r^{2}}\text{ has the same form:}"
            "\n"
            r"\text{charge}^{2}/(\epsilon_{0}\times\text{area})\text{ (}4\pi\text{ is dimensionless)}"
            "\n"
            r"\Rightarrow\ \left[\frac{Q^{2}}{\epsilon_{0}S}\right]=\left[\frac{q_{1}q_{2}}{\epsilon_{0}r^{2}}\right]=[F]=N",
        shortExplanation: r"\frac{Q^2}{2\epsilon_{0} S}\text{はコンデンサ極板間引力。}",
        shortExplanationEn: r"\frac{Q^2}{2\epsilon_{0} S}\text{ is force between capacitor plates}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
      UnitProblem(
        id: "A1626504-93CD-4666-ABE8-45819C3E3CE8",
        point:
            r"\text{係数 }2\text{ は無次元。}"
            "\n"
            r"\text{また、類似の形としては点電荷間のクーロン力 }F=\frac{1}{4\pi\epsilon_{0}}\frac{q_{1}q_{2}}{r^{2}}\text{ も}"
            "\n"
            r"\text{電荷}^{2}/(\epsilon_{0}\times\text{面積})\text{ の形（}4\pi\text{も無次元）}"
            "\n"
            r"\Rightarrow\ \left[\frac{Q^{2}}{\epsilon_{0}S}\right]=\left[\frac{q_{1}q_{2}}{\epsilon_{0}r^{2}}\right]=[F]=N",
        pointEn:
            r"\text{The factor }2\text{ is dimensionless.}"
            "\n"
            r"\text{Similarly, as a comparable form, Coulomb's law }F=\frac{1}{4\pi\epsilon_{0}}\frac{q_{1}q_{2}}{r^{2}}\text{ has the same form:}"
            "\n"
            r"\text{charge}^{2}/(\epsilon_{0}\times\text{area})\text{ (}4\pi\text{ is dimensionless)}"
            "\n"
            r"\Rightarrow\ \left[\frac{Q^{2}}{\epsilon_{0}S}\right]=\left[\frac{q_{1}q_{2}}{\epsilon_{0}r^{2}}\right]=[F]=N",
        shortExplanation: r"\frac{Q^2}{2\epsilon_{0} S}\text{はコンデンサ極板間引力。}",
        shortExplanationEn: r"\frac{Q^2}{2\epsilon_{0} S}\text{ is force between capacitor plates. Unit in base units: }kg \cdot m \cdot s^{-2}\text{.}}",
        answer: "kg m s^-2",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{Q}{\epsilon_0}",
    meaning: "電場フラックス",
    meaningEn: "electric field flux",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Q", nameJa: "電荷", unitSymbol: "C", meaning: "電荷", baseUnits: "A·s", dimension: "TI"),
        SymbolDef(symbol: "ε0", nameJa: "真空の誘電率", unitSymbol: "F/m", meaning: "誘電率", baseUnits: "kg^-1·m^-3·s^4·A^2", dimension: "M^-1L^-3T^4I^2", texSymbol: r"\epsilon_{0}"),
      ],
    unitProblems: [
      UnitProblem(
        id: "2225EF21-B8FE-43A6-9765-7606C2994AAD",
        point:
            r"\text{ガウスの法則 }\displaystyle \oint \vec{E}\cdot d\vec{S}=\frac{Q}{\epsilon_{0}}"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=\left[\frac{Q}{\epsilon_{0}}\right]"
            "\n"
            r"\text{また }V=Ed\ \Rightarrow\ [Ed]=[E]\cdot m=V"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=V\cdot m\ \Rightarrow\ \left[\frac{Q}{\epsilon_{0}}\right]=V\cdot m",
        pointEn:
            r"\text{Gauss's law }\displaystyle \oint \vec{E}\cdot d\vec{S}=\frac{Q}{\epsilon_{0}}"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=\left[\frac{Q}{\epsilon_{0}}\right]"
            "\n"
            r"\text{Also }V=Ed\ \Rightarrow\ [Ed]=[E]\cdot m=V"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=V\cdot m\ \Rightarrow\ \left[\frac{Q}{\epsilon_{0}}\right]=V\cdot m",
        shortExplanation: r"\frac{Q}{\epsilon_0}\text{は電場フラックス（ガウスの法則）。}",
        shortExplanationEn: r"\frac{Q}{\epsilon_0}\text{ is electric field flux (Gauss's law)}",
        answer: "V m",
        units: ["V", "m", "W", "s^-1", "C", "J", "A"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{Q}{t}",
    meaning: "電流",
    meaningEn: "electric current",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Q", nameJa: "電荷", meaning: "電気量", unitSymbol: "C", baseUnits: "A·s", dimension: "TI"),
        SymbolDef(symbol: "t", nameJa: "時間", meaning: "経過時間", unitSymbol: "s", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "33DA1989-33BD-42D3-8FB6-9E7DA4E6D621",
        shortExplanation: r"\frac{Q}{t}\text{は電流。}",
        shortExplanationEn: r"\frac{Q}{t}\text{ is electric current}",
        answer: "A",
        units: ["C", "s", "V", "A", "C^-1", "s^-1", "V^-1", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{V^2}{R}",
    meaning: "電力",
    meaningEn: "power",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "V", nameJa: "電圧", meaning: "電位差", unitSymbol: "V", baseUnits: "kg·m^2·s^-3·A^-1", dimension: "ML^2T^-3I^-1"),
        SymbolDef(symbol: "R", nameJa: "抵抗", meaning: "電流の流れにくさ", unitSymbol: "Ω", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "2A4786C0-AB4C-483F-B608-E7BB85944DBC",
        point:
            r"\text{オームの法則 }V=IR\ \Rightarrow\ I=\frac{V}{R}"
            "\n"
            r"\therefore\ [I]=\left[\frac{V}{R}\right]=A"
            "\n"
            r"\therefore\ \left[\frac{V^{2}}{R}\right]=[V]\left[\frac{V}{R}\right]=[V]\cdot A"
            "\n"
            r"[V]=\frac{J}{C}\ \Rightarrow\ [V]\cdot A=\frac{J}{C}\cdot A=\frac{J}{A\cdot s}\cdot A=\frac{J}{s}"
            "\n"
            r"=W",
        pointEn:
            r"\text{Ohm's law }V=IR\ \Rightarrow\ I=\frac{V}{R}"
            "\n"
            r"\therefore\ [I]=\left[\frac{V}{R}\right]=A"
            "\n"
            r"\therefore\ \left[\frac{V^{2}}{R}\right]=[V]\left[\frac{V}{R}\right]=[V]\cdot A"
            "\n"
            r"[V]=\frac{J}{C}\ \Rightarrow\ [V]\cdot A=\frac{J}{C}\cdot A=\frac{J}{A\cdot s}\cdot A=\frac{J}{s}"
            "\n"
            r"=W",
        shortExplanation: r"\frac{V^2}{R}\text{は電力。}",
        shortExplanationEn: r"\frac{V^2}{R}\text{ is power}",
        answer: "W",
        units: ["Pa", "kg", "J", "W", "s", "m^-1", "N"],
      ),
      UnitProblem(
        id: "9C05C1A0-23FF-47DD-AD9E-2E7EF32C3DB2",
        point:
            r"\text{オームの法則 }V=IR\ \Rightarrow\ I=\frac{V}{R}"
            "\n"
            r"\therefore\ [I]=\left[\frac{V}{R}\right]=A"
            "\n"
            r"\therefore\ \left[\frac{V^{2}}{R}\right]=[V]\left[\frac{V}{R}\right]=[V]\cdot A"
            "\n"
            r"[V]=\frac{J}{C}\ \Rightarrow\ [V]\cdot A=\frac{J}{C}\cdot A=\frac{J}{A\cdot s}\cdot A=\frac{J}{s}"
            "\n"
            r"=W",
        pointEn:
            r"\text{Ohm's law }V=IR\ \Rightarrow\ I=\frac{V}{R}"
            "\n"
            r"\therefore\ [I]=\left[\frac{V}{R}\right]=A"
            "\n"
            r"\therefore\ \left[\frac{V^{2}}{R}\right]=[V]\left[\frac{V}{R}\right]=[V]\cdot A"
            "\n"
            r"[V]=\frac{J}{C}\ \Rightarrow\ [V]\cdot A=\frac{J}{C}\cdot A=\frac{J}{A\cdot s}\cdot A=\frac{J}{s}"
            "\n"
            r"=W",
        shortExplanation: r"\frac{V^2}{R}\text{は電力。}",
        shortExplanationEn: r"\frac{V^2}{R}\text{ is power}",
        answer: "J s^-1",
        units: ["Pa", "kg", "J", "m^-1", "s^-1", "s", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{V}{R}",
    meaning: "電流",
    meaningEn: "electric current",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "V", nameJa: "電圧", meaning: "電位差", unitSymbol: "V", baseUnits: "kg·m^2·s^-3·A^-1", dimension: "ML^2T^-3I^-1"),
        SymbolDef(symbol: "R", nameJa: "抵抗", meaning: "電流の流れにくさ", unitSymbol: "Ω", baseUnits: "kg·m^2·s^-3·A^-2", dimension: "ML^2T^-3I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "13313A23-7AE3-4441-A82C-FF077FB76E46",
        shortExplanation: r"\frac{V}{R}\text{は電流。}",
        shortExplanationEn: r"\frac{V}{R}\text{ is electric current}",
        answer: "A",
        units: ["V", "C", "W", "A", "V^-1", "C^-1", "W^-1", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{V}{d}",
    meaning: "電場",
    meaningEn: "electric field",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "V", nameJa: "電圧", meaning: "電位差", unitSymbol: "V", baseUnits: "kg·m^2·s^-3·A^-1", dimension: "ML^2T^-3I^-1"),
        SymbolDef(symbol: "d", nameJa: "距離", meaning: "電極間距離など", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "62DEDCF4-F593-484B-A2BA-207193D16709",
        shortExplanation: r"\frac{V}{d}\text{は電場。}",
        shortExplanationEn: r"\frac{V}{d}\text{ is electric field}",
        answer: "V m^-1",
        units: ["V", "J", "C", "W", "F", "A", "kg", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{\epsilon_0 S}{d}",
    meaning: "静電容量",
    meaningEn: "capacitance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ε0", nameJa: "真空の誘電率", unitSymbol: "F/m", meaning: "誘電率", baseUnits: "kg^-1·m^-3·s^4·A^2", dimension: "M^-1L^-3T^4I^2", texSymbol: r"\epsilon_{0}"),
        SymbolDef(symbol: "S", nameJa: "面積", unitSymbol: "m^2", meaning: "極板面積", baseUnits: "m^2", dimension: "L^2"),
        SymbolDef(symbol: "d", nameJa: "距離", unitSymbol: "m", meaning: "極板間距離", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "FA70DDAC-1326-4141-ABD5-01862C22332A",
        shortExplanation: r"\frac{\epsilon_0 S}{d}\text{は静電容量。}",
        shortExplanationEn: r"\frac{\epsilon_0 S}{d}\text{ is capacitance}",
        answer: "F",
        units: ["F", "C", "V", "W", "A", "Ω", "s", "m^-1"],
      ),
      UnitProblem(
        id: "AE09CB93-E5AA-4DE4-8472-8529E4888C4D",
        point:
            r"\text{静電容量 }C\text{ の単位は }F\text{（前提）}"
            "\n"
            r"Q=CV\ \Rightarrow\ [C]=\left[\frac{Q}{V}\right]=C\cdot V^{-1}",
        pointEn:
            r"\text{Capacitance }C\text{ has unit }F\text{ (given)}"
            "\n"
            r"Q=CV\ \Rightarrow\ [C]=\left[\frac{Q}{V}\right]=C\cdot V^{-1}",
        shortExplanation: r"\frac{\epsilon_0 S}{d}\text{は静電容量。}",
        shortExplanationEn: r"\frac{\epsilon_0 S}{d}\text{ is capacitance}",
        answer: "C V^-1",
        units: ["C", "V^-1", "A^-1", "s", "kg", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{\mu_0 I}{2\pi r}",
    meaning: "直線電流による磁束密度",
    meaningEn: "magnetic flux density due to straight current",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "μ0", nameJa: "真空の透磁率", meaning: "磁場の定数", unitSymbol: "H/m", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu_{0}"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
        SymbolDef(symbol: "r", nameJa: "距離", meaning: "電流からの距離", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "B0B5FC9D-A839-4876-B989-668D2A5CA17E",
        point:
            r"\text{アンペールの法則より }\displaystyle \oint \vec{B}\cdot d\vec{l}=\mu_{0}I"
            "\n"
            r"\therefore\ [B]\cdot m=[\mu_{0}I]"
            "\n"
            r"\Rightarrow\ \left[\frac{\mu_{0}I}{r}\right]=[B]=T",
        pointEn:
            r"\text{From Amp\`ere's law }\displaystyle \oint \vec{B}\cdot d\vec{l}=\mu_{0}I"
            "\n"
            r"\therefore\ [B]\cdot m=[\mu_{0}I]"
            "\n"
            r"\Rightarrow\ \left[\frac{\mu_{0}I}{r}\right]=[B]=T",
        shortExplanation: r"\frac{\mu_0 I}{2\pi r}\text{は直線電流による磁束密度。}",
        shortExplanationEn: r"\frac{\mu_0 I}{2\pi r}\text{ is magnetic flux density due to straight current}",
        answer: "T",
        units: ["Wb", "H", "A", "T", "F", "V"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{\mu_0 I}{2r}",
    meaning: "回転電流による磁束密度",
    meaningEn: "magnetic flux density due to circular current",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "μ0", nameJa: "真空の透磁率", meaning: "透磁率", unitSymbol: "H/m", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu_{0}"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
        SymbolDef(symbol: "r", nameJa: "半径", meaning: "回転電流の半径", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "BC2A3F24-549D-4BC1-A53D-CEA1522D06A5",
        point:
            r"\text{アンペールの法則より }\displaystyle \oint \vec{B}\cdot d\vec{l}=\mu_{0}I"
            "\n"
            r"\therefore\ [B]\cdot m=[\mu_{0}I]"
            "\n"
            r"\Rightarrow\ \left[\frac{\mu_{0}I}{r}\right]=[B]=T",
        pointEn:
            r"\text{From Amp\`ere's law }\displaystyle \oint \vec{B}\cdot d\vec{l}=\mu_{0}I"
            "\n"
            r"\therefore\ [B]\cdot m=[\mu_{0}I]"
            "\n"
            r"\Rightarrow\ \left[\frac{\mu_{0}I}{r}\right]=[B]=T",
        shortExplanation: r"\frac{\mu_0 I}{2r}\text{は回転電流による磁束密度。}",
        shortExplanationEn: r"\frac{\mu_0 I}{2r}\text{ is magnetic flux density due to circular current}",
        answer: "T",
        units: ["Wb", "H", "A", "T", "F", "V"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{\mu_0 N^2 S}{L}",
    meaning: "ソレノイドコイルの自己インダクタンス",
    meaningEn: "self-inductance of solenoid coil",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "μ0", nameJa: "真空の透磁率", meaning: "透磁率", unitSymbol: "H/m", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu_{0}"),
        SymbolDef(symbol: "N", nameJa: "巻数", meaning: "コイルの巻数", unitSymbol: "1", baseUnits: "1", dimension: "1"),
        SymbolDef(symbol: "S", nameJa: "面積", meaning: "コイルの断面積", unitSymbol: "m^2", baseUnits: "m^2", dimension: "L^2"),
        SymbolDef(symbol: "L", nameJa: "長さ", meaning: "コイルの長さ", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "C8F56A4B-C0ED-4900-BD75-D71D11C0A4F2",
        shortExplanation: r"\frac{\mu_0 N^2 S}{L}\text{はソレノイドコイルの自己インダクタンス。}",
        shortExplanationEn: r"\frac{\mu_0 N^2 S}{L}\text{ is self-inductance of solenoid coil}",
        answer: "H",
        units: ["H", "m^-1", "Wb", "A", "T", "F", "s"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{\mu_0 N_1 N_2 S}{L}",
    meaning: "相互インダクタンス",
    meaningEn: "mutual inductance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "μ0", nameJa: "真空の透磁率", meaning: "透磁率", unitSymbol: "H/m", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu_{0}"),
        SymbolDef(symbol: "N1", nameJa: "一次側巻数", meaning: "一次コイルの巻数", unitSymbol: "1", baseUnits: "1", dimension: "1"),
        SymbolDef(symbol: "N2", nameJa: "二次側巻数", meaning: "二次コイルの巻数", unitSymbol: "1", baseUnits: "1", dimension: "1"),
        SymbolDef(symbol: "S", nameJa: "面積", meaning: "コイルの共通断面積", unitSymbol: "m^2", baseUnits: "m^2", dimension: "L^2"),
        SymbolDef(symbol: "L", nameJa: "長さ", meaning: "コイルの長さ", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "17621272-58BD-4125-A4EC-119D800F75BD",
        shortExplanation: r"\frac{\mu_0 N_1 N_2 S}{L}\text{はソレノイドコイル同士の相互インダクタンス。}",
        shortExplanationEn: r"\frac{\mu_0 N_1 N_2 S}{L}\text{ is mutual inductance between solenoid coils}",
        answer: "H",
        units: ["H", "m^-1", "Wb", "A", "T", "F", "s"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{\rho L}{S}",
    meaning: "抵抗",
    meaningEn: "resistance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ρ", nameJa: "抵抗率", meaning: "物質固有の抵抗", unitSymbol: "Ω·m", baseUnits: "kg·m^3·s^-3·A^-2", dimension: "ML^3T^-3I^-2", texSymbol: r"\rho"),
        SymbolDef(symbol: "L", nameJa: "長さ", meaning: "導体の長さ", unitSymbol: "m", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "S", nameJa: "面積", meaning: "導体の断面積", unitSymbol: "m^2", baseUnits: "m^2", dimension: "L^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "21E3A8AD-9E42-4907-B765-F3B570F3CA96",
        shortExplanation: r"\frac{\rho L}{S}\text{は抵抗を表す。}",
        shortExplanationEn: r"\frac{\rho L}{S}\text{ represents resistance}",
        answer: "Ω",
        units: ["Ω", "V", "A", "C", "J", "s", "m", "V^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\frac{d\Phi}{dt}",
    meaning: "誘導起電力",
    meaningEn: "induced electromotive force",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Φ", nameJa: "磁束", unitSymbol: "Wb", meaning: "磁束", baseUnits: "kg·m^2·s^-2·A^-1", dimension: "ML^2T^-2I^-1", texSymbol: r"\Phi"),
        SymbolDef(symbol: "t", nameJa: "時間", unitSymbol: "s", meaning: "時間", baseUnits: "s", dimension: "T"),
      ],
    unitProblems: [
      UnitProblem(
        id: "811CAEA4-7E8F-4773-BB46-08AB59B23D63",
        shortExplanation: r"\frac{d\Phi}{dt}\text{は誘導起電力。}",
        shortExplanationEn: r"\frac{d\Phi}{dt}\text{ is induced electromotive force}",
        answer: "V",
        units: ["V", "J", "C", "W", "F", "A", "kg"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\mu n^2 l S",
    meaning: "ソレノイドのインダクタンス",
    meaningEn: "inductance of solenoid",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "μ", nameJa: "透磁率", meaning: "透磁率", unitSymbol: "H/m", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu"),
        SymbolDef(symbol: "n", nameJa: "単位長さあたりの巻数", meaning: "ソレノイドの巻数密度", unitSymbol: "1/m", baseUnits: "m^-1", dimension: "L^-1"),
        SymbolDef(symbol: "l", nameJa: "長さ", meaning: "ソレノイドの長さ", unitSymbol: "m", baseUnits: "m", dimension: "L"),
        SymbolDef(symbol: "S", nameJa: "面積", meaning: "ソレノイドの断面積", unitSymbol: "m^2", baseUnits: "m^2", dimension: "L^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "8C32E545-71D8-44CE-BA2F-548FBF9C38A7",
        shortExplanation: r"\mu n^2 l S\text{はソレノイドのインダクタンス。}",
        shortExplanationEn: r"\mu n^2 l S\text{ is inductance of solenoid}",
        answer: "H",
        units: ["H", "m^-1", "Wb", "A", "T", "F", "s"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"\mu_0 n I",
    meaning: "ソレノイドによる磁束密度",
    meaningEn: "magnetic flux density due to solenoid",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "μ0", nameJa: "真空の透磁率", meaning: "透磁率", unitSymbol: "H/m", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu_{0}"),
        SymbolDef(symbol: "n", nameJa: "単位長さあたりの巻数", meaning: "ソレノイドの巻数密度", unitSymbol: "1/m", baseUnits: "m^-1", dimension: "L^-1"),
        SymbolDef(symbol: "I", nameJa: "電流", meaning: "電荷の流れ", unitSymbol: "A", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "0D08FC42-2252-4D00-B09F-7A649CA8000E",
        point:
            r"\text{アンペールの法則より }\displaystyle \oint \vec{B}\cdot d\vec{l}=\mu_{0}I"
            "\n"
            r"\text{ソレノイドでは }B=\mu_{0}nI (n:\ \text{単位長さあたり巻数})"
            "\n"
            r"[n]=m^{-1}\ \Rightarrow\ [\mu_{0}nI]=\left[\frac{\mu_{0}I}{m}\right]=[B]=T",
        pointEn:
            r"\text{From Amp\`ere's law }\displaystyle \oint \vec{B}\cdot d\vec{l}=\mu_{0}I"
            "\n"
            r"\text{For a solenoid }B=\mu_{0}nI\ (n:\ \text{turns per unit length})"
            "\n"
            r"[n]=m^{-1}\ \Rightarrow\ [\mu_{0}nI]=\left[\frac{\mu_{0}I}{m}\right]=[B]=T",
        shortExplanation: r"\mu_0 n I\text{はソレノイドによる磁束密度。}",
        shortExplanationEn: r"\mu_0 n I\text{ is magnetic flux density due to solenoid}",
        answer: "T",
        units: ["Wb", "H", "A", "T", "F", "V"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "k_0",
    meaning: "クーロン定数",
    meaningEn: "Coulomb constant",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "k_0", nameJa: "クーロン定数", meaning: "静電気力の定数", unitSymbol: "N·m^2/C^2", baseUnits: "kg·m^3·s^-4·A^-2", dimension: "ML^3T^-4I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "E2F7C836-64DF-4860-BA89-7FDCF060F5D2",
        point:
            r"\text{クーロンの法則 }F=\frac{k_0 q_{1}q_{2}}{r^2}"
            "\n"
            r"\left[\frac{k_0 q_{1}q_{2}}{r^2}\right]=[F]=N"
            "\n"
            r"\therefore\ \left[k_0\right]=N\cdot\left[\frac{r^2}{q_{1}q_{2}}\right]=N\cdot m^2\cdot C^{-2}",
        pointEn:
            r"\text{From Coulomb's law }F=\frac{k_0 q_{1}q_{2}}{r^2}"
            "\n"
            r"\left[\frac{k_0 q_{1}q_{2}}{r^2}\right]=[F]=N"
            "\n"
            r"\therefore\ \left[k_0\right]=N\cdot\left[\frac{r^2}{q_{1}q_{2}}\right]=N\cdot m^2\cdot C^{-2}",
        shortExplanationEn: r"k_0\text{ is Coulomb constant}",
        answer: "N m^2 C^-2",
        units: ["N", "m", "C^-1", "A^-1", "s", "kg", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "m",
    meaning: "磁荷",
    meaningEn: "magnetic charge",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "m", nameJa: "磁荷", meaning: "磁気量", unitSymbol: "Wb", baseUnits: "kg·m^2·s^-2·A^-1", dimension: "ML^2T^-2I^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "4EAB751D-4560-4E60-B4D5-08F19D87F0E6",
        answer: "Wb",
        units: ["Wb", "T", "H", "V", "W", "J", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "mH",
    meaning: "磁気力",
    meaningEn: "magnetic force",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "m", nameJa: "磁荷", unitSymbol: "Wb", meaning: "磁気量", baseUnits: "kg·m^2·s^-2·A^-1", dimension: "ML^2T^-2I^-1"),
        SymbolDef(symbol: "H", nameJa: "磁場", unitSymbol: "A/m", meaning: "磁場の強さ", baseUnits: "A·m^-1", dimension: "IL^-1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "5B8E36CB-548F-41A4-97F6-F8AD6A386429",
        shortExplanation: r"mH\text{は磁気力。}",
        shortExplanationEn: r"mH\text{ is magnetic force}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "nI",
    meaning: "磁場の強さ",
    meaningEn: "magnetic field strength",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "n", nameJa: "巻き数密度", meaning: "1mあたりの巻き数", unitSymbol: "m^-1", baseUnits: "m^-1", dimension: "L^-1"),
        SymbolDef(symbol: "I", nameJa: "電流", unitSymbol: "A", meaning: "電流", baseUnits: "A", dimension: "I"),
      ],
    unitProblems: [
      UnitProblem(
        id: "CC055704-D92C-42F6-8E65-111514D2409C",
        shortExplanation: r"nI\text{は磁場の強さ。}",
        shortExplanationEn: r"nI\text{ is magnetic field strength}",
        answer: "A m^-1",
        units: ["m", "m^-1", "s", "s^-1", "kg", "kg^-1", "A", "A^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "qEd",
    meaning: "電場による仕事",
    meaningEn: "work done by electric field",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "q", nameJa: "電荷", meaning: "電荷量", unitSymbol: "C", baseUnits: "A·s", dimension: "TI"),
        SymbolDef(symbol: "E", nameJa: "電場", meaning: "電場の強さ", unitSymbol: "V/m", baseUnits: "kg·m·s^-3·A^-1", dimension: "MLT^-3I^-1"),
        SymbolDef(symbol: "d", nameJa: "距離", meaning: "移動距離", unitSymbol: "m", baseUnits: "m", dimension: "L"),
      ],
    unitProblems: [
      UnitProblem(
        id: "62BCDCC0-7806-4E5B-A0F2-BA7852EE202B",
        point:
            r"\text{電場中の力 }F=qE"
            "\n"
            r"\therefore\ [qE]=[F]=N"
            "\n"
            r"[qEd]=N\cdot m=J",
        pointEn:
            r"\text{Force in an electric field }F=qE"
            "\n"
            r"\therefore\ [qE]=[F]=N"
            "\n"
            r"[qEd]=N\cdot m=J",
        shortExplanation: r"qEd\text{は電場による仕事。}",
        shortExplanationEn: r"qEd\text{ is work done by electric field}",
        answer: "J",
        units: ["kg", "J", "W", "m^-1", "s^-1", "Pa", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: r"qvB \sin \theta",
    meaning: "ローレンツ力",
    meaningEn: "Lorentz force",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "q", nameJa: "電荷", unitSymbol: "C", meaning: "電荷", baseUnits: "A·s", dimension: "TI"),
        SymbolDef(symbol: "v", nameJa: "速度", unitSymbol: "m/s", meaning: "速度", baseUnits: "m·s^-1", dimension: "LT^-1"),
        SymbolDef(symbol: "B", nameJa: "磁束密度", unitSymbol: "T", meaning: "磁束密度", baseUnits: "kg·s^-2·A^-1", dimension: "MT^-2I^-1"),
        SymbolDef(symbol: "θ", nameJa: "角度", meaning: "速度と磁束密度のなす角", unitSymbol: "rad", baseUnits: "1", dimension: "1"),
      ],
    unitProblems: [
      UnitProblem(
        id: "E9C4A87E-41A0-4982-8F81-CAF2E2D57C53",
        shortExplanation: r"qvB \sin \theta\text{はローレンツ力。}",
        shortExplanationEn: r"qvB \sin \theta\text{ is Lorentz force}",
        answer: "N",
        units: ["Pa", "kg", "s", "m^-1", "J^-1", "W^-1", "N"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "vBℓ",
    meaning: "誘導起電力",
    meaningEn: "induced electromotive force",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "v", nameJa: "速度", unitSymbol: "m/s", meaning: "導体の速度", baseUnits: "m·s^-1", dimension: "LT^-1"),
        SymbolDef(symbol: "B", nameJa: "磁束密度", unitSymbol: "T", meaning: "磁束密度", baseUnits: "kg·s^-2·A^-1", dimension: "MT^-2I^-1"),
        SymbolDef(symbol: "ℓ", nameJa: "長さ", unitSymbol: "m", meaning: "導体の長さ", baseUnits: "m", dimension: "L", texSymbol: r"\ell"),
      ],
    unitProblems: [
      UnitProblem(
        id: "8C141CEC-E944-472D-A452-3416896B40A5",
        shortExplanation: r"vB\ell\text{は誘導起電力。}",
        shortExplanationEn: r"vB\ell\text{ is induced electromotive force}",
        answer: "V",
        units: ["V", "J", "C", "W", "F", "A", "kg"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "Φ",
    meaning: "磁束",
    meaningEn: "magnetic flux",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "Φ", nameJa: "磁束", meaning: "磁場が貫く量", unitSymbol: "Wb", baseUnits: "kg·m^2·s^-2·A^-1", dimension: "ML^2T^-2I^-1", texSymbol: r"\Phi"),
      ],
    unitProblems: [
      UnitProblem(
        id: "64A3C141-1542-4D76-9AA8-5A7C9430C0C7",
        answer: "Wb",
        units: ["Wb", "T", "H", "V", "W", "J", "m^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ε0",
    meaning: "真空の誘電率",
    meaningEn: "vacuum permittivity",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ε0", nameJa: "真空の誘電率", meaning: "誘電率", unitSymbol: "F/m", baseUnits: "kg^-1·m^-3·s^4·A^2", dimension: "M^-1L^-3T^4I^2", texSymbol: r"\epsilon_{0}"),
      ],
    unitProblems: [
      UnitProblem(
        id: "81A3B5CA-70EA-46AC-8ED9-B958D6D9EB00",
        point:
            r"\text{平行板コンデンサの電気容量 }C=\frac{\epsilon_{0}S}{d}"
            "\n"
            r"\therefore\ \epsilon_{0}=\frac{Cd}{S}"
            "\n"
            r"[C]=F,\ [d]=m,\ [S]=m^{2}"
            "\n"
            r"\therefore\ [\epsilon_{0}]=\left[\frac{F\cdot m}{m^{2}}\right]=F\cdot m^{-1}",
        pointEn:
            r"\text{Capacitance of a parallel-plate capacitor }C=\frac{\epsilon_{0}S}{d}"
            "\n"
            r"\therefore\ \epsilon_{0}=\frac{Cd}{S}"
            "\n"
            r"[C]=F,\ [d]=m,\ [S]=m^{2}"
            "\n"
            r"\therefore\ [\epsilon_{0}]=\left[\frac{F\cdot m}{m^{2}}\right]=F\cdot m^{-1}",
        answer: "F m^-1",
        units: ["F", "m^-1", "C", "V", "W", "A", "Ω"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ε0ES",
    meaning: "電束",
    meaningEn: "electric displacement flux",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ε0", nameJa: "真空の誘電率", meaning: "誘電率", unitSymbol: "F/m", baseUnits: "kg^-1·m^-3·s^4·A^2", dimension: "M^-1L^-3T^4I^2", texSymbol: r"\epsilon_{0}"),
        SymbolDef(symbol: "E", nameJa: "電場", meaning: "電場", unitSymbol: "V/m", baseUnits: "kg·m·s^-3·A^-1", dimension: "MLT^-3I^-1"),
        SymbolDef(symbol: "S", nameJa: "面積", meaning: "電場が貫く面積", unitSymbol: "m^2", baseUnits: "m^2", dimension: "L^2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "3CD18159-0947-45A5-98C5-96BC236C0463",
        point:
            r"\text{ガウスの法則 }\displaystyle \int \vec{E}\cdot d\vec{S}=\frac{Q}{\epsilon_{0}}"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=\left[\frac{Q}{\epsilon_{0}}\right]"
            "\n"
            r"\Rightarrow\ [\epsilon_{0}ES]=[Q]=C",
        pointEn:
            r"\text{Gauss's law }\displaystyle \int \vec{E}\cdot d\vec{S}=\frac{Q}{\epsilon_{0}}"
            "\n"
            r"\therefore\ [E]\cdot m^{2}=\left[\frac{Q}{\epsilon_{0}}\right] \Rightarrow [\epsilon_{0}E]\cdot m^2 = [Q]"
            "\n"
            r"\therefore\ [\epsilon_{0}ES]=[\epsilon_{0}E]\cdot m^2=[Q]=C",
        shortExplanation: r"\epsilon_0 ES\text{は電束（}D=\epsilon_0E\text{のフラックス）。}",
        shortExplanationEn: r"\epsilon_0 ES\text{ is electric displacement flux}",
        answer: "C",
        units: ["C", "s^-1", "Ω", "A", "V", "m^-1", "J"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "μ0",
    meaning: "真空の透磁率",
    meaningEn: "vacuum permeability",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "μ0", nameJa: "真空の透磁率", meaning: "透磁率", unitSymbol: "H/m", baseUnits: "kg·m·s^-2·A^-2", dimension: "MLT^-2I^-2", texSymbol: r"\mu_{0}"),
      ],
    unitProblems: [
      UnitProblem(
        id: "B3ECE16E-A60B-4EEF-BFA6-8CB485ABD459",
        point:
            r"\text{アンペールの法則（静磁場）}\ \displaystyle \oint \vec{B}\cdot d\vec{l}=\mu_{0}I"
            "\n"
            r"\text{左辺 }T\cdot m,\ \text{右辺 }[\mu_{0}]\cdot A"
            "\n"
            r"\therefore\ [\mu_{0}]=\frac{T\cdot m}{A}"
            "\n"
            r"1T=\frac{Wb}{m^{2}}\ \Rightarrow\ [\mu_{0}]=\frac{Wb}{A\cdot m}"
            "\n"
            r"\Phi=LI\ \Rightarrow\ [Wb]=[L]\cdot[I]=H\cdot A"
            "\n"
            r"Wb=H\cdot A\ \Rightarrow\ [\mu_{0}]=\frac{H}{m}",
        pointEn:
            r"\text{Amp\`ere's law (magnetostatics) }\ \displaystyle \oint \vec{B}\cdot d\vec{l}=\mu_{0}I"
            "\n"
            r"\text{LHS }T\cdot m,\ \text{RHS }[\mu_{0}]\cdot A"
            "\n"
            r"\therefore\ [\mu_{0}]=\frac{T\cdot m}{A}"
            "\n"
            r"1T=\frac{Wb}{m^{2}}\ \Rightarrow\ [\mu_{0}]=\frac{Wb}{A\cdot m}"
            "\n"
            r"\Phi=LI\ \Rightarrow\ [Wb]=[L]\cdot[I]=H\cdot A"
            "\n"
            r"Wb=H\cdot A\ \Rightarrow\ [\mu_{0}]=\frac{H}{m}",
        answer: "H m^-1",
        units: ["H", "m^-1", "Wb", "A", "T", "kg", "s"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ρ",
    meaning: "抵抗率",
    meaningEn: "resistivity",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ρ", nameJa: "抵抗率", meaning: "物質固有の抵抗", unitSymbol: "Ω·m", baseUnits: "kg·m^3·s^-3·A^-2", dimension: "ML^3T^-3I^-2", texSymbol: r"\rho"),
      ],
    unitProblems: [
      UnitProblem(
        id: "20C138CB-6C42-4DA6-BFFA-CC2C0DE29BB6",
        point:
            r"R=\frac{\rho l}{S}"
            "\n"
            r"\left[\frac{\rho l}{S}\right]=[R]=\Omega"
            "\n"
            r"\therefore\ [\rho]=\Omega\cdot\left[\frac{S}{l}\right]=\Omega\cdot m"
            "\n"
            r"\Omega=\frac{V}{A},\ V=kg\cdot m^{2}\cdot s^{-3}\cdot A^{-1}\ \Rightarrow\ [\rho]=kg\cdot m^{3}\cdot s^{-3}\cdot A^{-2}",
        pointEn:
            r"R=\frac{\rho l}{S}"
            "\n"
            r"\left[\frac{\rho l}{S}\right]=[R]=\Omega"
            "\n"
            r"\therefore\ [\rho]=\Omega\cdot\left[\frac{S}{l}\right]=\Omega\cdot m"
            "\n"
            r"\Omega=\frac{V}{A},\ V=kg\cdot m^{2}\cdot s^{-3}\cdot A^{-1}\ \Rightarrow\ [\rho]=kg\cdot m^{3}\cdot s^{-3}\cdot A^{-2}",
        answer: "Ω m",
        units: ["Ω", "V", "A", "C", "J", "s", "m", "V^-1"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "σ",
    meaning: "電荷面密度",
    meaningEn: "surface charge density",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "σ", nameJa: "電荷面密度", meaning: "単位面積あたりの電荷", unitSymbol: "C/m^2", baseUnits: "A·s·m^-2", dimension: "TIL^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "37707158-1FF3-41F7-B444-A692BEDFE194",
        answer: "C m^-2",
        units: ["C", "s^-1", "A", "V^-1", "W", "kg"],
      ),
    ],
  ),
  UnitExprProblem(
    expr: "ωL",
    meaning: "誘導性リアクタンス",
    meaningEn: "inductive reactance",
    category: UnitCategory.electromagnetism,
    defs: [
        SymbolDef(symbol: "ω", nameJa: "角周波数", meaning: "2πf", unitSymbol: "rad/s", baseUnits: "s^-1", dimension: "T^-1", texSymbol: r"\omega"),
        SymbolDef(symbol: "L", nameJa: "インダクタンス", meaning: "起電力=−L di/dt の比例係数", unitSymbol: "H", baseUnits: "kg·m^2·s^-2·A^-2", dimension: "ML^2T^-2I^-2"),
      ],
    unitProblems: [
      UnitProblem(
        id: "E4F721A9-1D2B-428A-967A-A0B6979EBEDC",
        shortExplanation: r"\omega L\text{は誘導性リアクタンス。}",
        shortExplanationEn: r"\omega L\text{ is inductive reactance}",
        answer: "Ω",
        units: ["Ω", "V", "A", "C", "J", "s", "m", "V^-1"],
      ),
    ],
  ),
];
