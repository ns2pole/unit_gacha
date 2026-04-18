import '../../models/step_item.dart';

/// 記号の定義（問題ごとに必ず添える）
class SymbolDef {
  final String symbol; // 例: "m"
  final String nameJa; // 例: "質量"
  final String meaning; // 例: "物体の質量"
  final String? nameEn; // 例: "mass"
  final String? meaningEn; // 例: "mass of the object"
  final String? unitSymbol; // 例: "kg" (不要なら null)
  final String? baseUnits; // 例: "kg" / "kg·m·s^-2" など
  final String? dimension; // 例: "M", "MLT^-2" など（任意）
  final String? texSymbol; // 例: r"\omega", r"\tau", r"m" (TeX形式、オプショナル)

  SymbolDef({
    required this.symbol,
    required this.nameJa,
    required this.meaning,
    String? nameEn,
    String? meaningEn,
    this.unitSymbol,
    this.baseUnits,
    this.dimension,
    this.texSymbol,
  }) : nameEn = nameEn ?? _symbolNameTranslations[nameJa],
       meaningEn = meaningEn ?? _symbolMeaningTranslations[meaning];

  String localizedName(String languageCode) {
    if (languageCode == 'en' && (nameEn ?? '').isNotEmpty) {
      return nameEn!;
    }
    return nameJa;
  }

  String localizedMeaning(String languageCode) {
    if (languageCode == 'en' && (meaningEn ?? '').isNotEmpty) {
      return meaningEn!;
    }
    return meaning;
  }

  String? localizedUnitSymbol(String languageCode) {
    if (unitSymbol == null) return null;
    if (languageCode == 'en') {
      // 「無次元」を「dimensionless」に翻訳
      if (unitSymbol == '無次元') {
        return 'dimensionless';
      }
    }
    return unitSymbol;
  }

  String? localizedDimension(String languageCode) {
    if (dimension == null) return null;
    if (languageCode == 'en') {
      // 「無次元」を「dimensionless」に翻訳
      if (dimension == '無次元') {
        return 'dimensionless';
      }
    }
    return dimension;
  }
}

/// カテゴリー
enum UnitCategory {
  mechanics, // 力学
  electromagnetism, // 電磁気学
  thermodynamics, // 熱力学
  waves, // 波動
  atom, // 原子
}

/// 単位解答（解答文字列と電卓ボタン群のペア）
class UnitProblem {
  final String id; // 問題ID（UUID）
  final String? shortExplanation; // ワンフレーズ解説（日本語）
  final String? shortExplanationEn; // ワンフレーズ解説（英語）
  final String? point; // 追加の注記（例: ポイント表示、オプショナル）
  final String? pointEn; // 追加の注記（英語）
  final String answer; // 解答文字列（例: "J", "N m", "kg m^2 s^-2"）
  final List<String> units; // 電卓ボタン群の単位リスト（例: ["J", "Pa", "Hz", "N"]）

  const UnitProblem({
    required this.id,
    this.shortExplanation,
    this.shortExplanationEn,
    this.point,
    this.pointEn,
    required this.answer,
    required this.units,
  });

  /// 言語コードに応じたshortExplanationを返す
  String? localizedShortExplanation(String languageCode) {
    if (languageCode == 'en' &&
        shortExplanationEn != null &&
        shortExplanationEn!.isNotEmpty) {
      return shortExplanationEn;
    }
    return shortExplanation;
  }

  /// 言語コードに応じたpointを返す
  String? localizedPoint(String languageCode) {
    if (languageCode == 'en' && pointEn != null && pointEn!.isNotEmpty) {
      return pointEn;
    }
    return point;
  }

  /// 言語コードに応じたanswerを返す（「(無次元)」を「(dimensionless)」に翻訳、「無次元」を「dimensionless」に翻訳）
  String localizedAnswer(String languageCode) {
    if (languageCode == 'en') {
      return answer.replaceAll('(無次元)', '(dimensionless)').replaceAll('無次元', 'dimensionless');
    }
    return answer;
  }
}

// 手動翻訳テーブル（日本語→英語）
const Map<String, String> _symbolNameTranslations = {
  'ばね定数': 'Spring constant',
  'インダクタンス': 'Inductance',
  'インピーダンス': 'Impedance',
  'クーロン定数': 'Coulomb constant',
  '一次側巻数': 'Primary coil turns',
  '万有引力定数': 'Gravitational constant',
  '二次側巻数': 'Secondary coil turns',
  '仕事': 'Work',
  '体積': 'Volume',
  '円周率': 'Pi',
  '運動量': 'Momentum',
  '光速': 'Speed of light',
  '力': 'Force',
  '力のモーメント': 'Torque',
  '加速度': 'Acceleration',
  '動摩擦係数': 'Kinetic friction coefficient',
  '半径': 'Radius',
  '周期': 'Period',
  '周波数': 'Frequency',
  '振動数': 'Frequency',
  '圧力': 'Pressure',
  '垂直抗力': 'Normal force',
  '変位': 'Displacement',
  '定積モル比熱': 'Molar heat capacity (constant volume)',
  '密度': 'Density',
  '巻き数密度': 'Turn density',
  '巻数': 'Number of turns',
  '張力': 'Tension',
  '抵抗': 'Resistance',
  '抵抗率': 'Resistivity',
  '時間': 'Time',
  '比熱': 'Specific heat',
  '比熱比': 'Heat capacity ratio',
  '気体定数': 'Gas constant',
  '波の速さ': 'Wave speed',
  '波数': 'Wave number',
  '波長': 'Wavelength',
  '温度': 'Temperature',
  '熱容量': 'Heat capacity',
  '物質量': 'Amount of substance',
  '真空の誘電率': 'Vacuum permittivity',
  '真空の透磁率': 'Vacuum permeability',
  '磁場': 'Magnetic field',
  '磁束': 'Magnetic flux',
  '磁束密度': 'Magnetic flux density',
  '磁荷': 'Magnetic charge',
  '線密度': 'Linear density',
  '角周波数': 'Angular frequency',
  '角度': 'Angle',
  '角速度': 'Angular velocity',
  '角運動量': 'Angular momentum',
  '質量': 'Mass',
  '距離': 'Distance',
  '速度': 'Speed',
  '重力加速度': 'Gravitational acceleration',
  '長さ': 'Length',
  '電力': 'Electric power',
  '電圧': 'Voltage',
  '電束': 'Electric flux',
  '電流': 'Electric current',
  '電界': 'Electric field',
  '電荷': 'Electric charge',
  '電荷面密度': 'Surface charge density',
  '静止摩擦係数': 'Static friction coefficient',
  '静電容量': 'Capacitance',
  '面積': 'Area',
  '高さ': 'Height',
  'プランク定数': 'Planck constant',
  'リュードベリ定数': 'Rydberg constant',
  '反発係数': 'Coefficient of restitution',
  '熱効率': 'Thermal efficiency',
  '内部エネルギー変化': 'Change in internal energy',
  '静止エネルギー': 'Rest energy',
  '光の運動量': 'Momentum of light',
  '電場': 'Electric field',
  '抵抗係数': 'Drag coefficient',
  'ドブロイ波長': 'de Broglie wavelength',
  '相互誘導係数': 'Mutual inductance',
  '単位長さあたりの巻数': 'Turns per unit length',
  '振幅': 'Amplitude',
  '熱量': 'Heat',
  '電気素量': 'Elementary charge',
};

const Map<String, String> _symbolMeaningTranslations = {
  '1mあたりの巻き数': 'Turns per meter',
  '1回の振動にかかる時間': 'Time per oscillation',
  '2π/λ': '2π/λ',
  '2πf': '2πf',
  '2物体間の距離': 'Distance between two bodies',
  'ばねの伸び': 'Extension of the spring',
  'ばねの硬さ': 'Spring stiffness',
  'インダクタンス': 'Inductance',
  'コイルの共通断面積': 'Common cross-sectional area of the coil',
  'コイルの巻数': 'Number of turns of the coil',
  'コイルの断面積': 'Cross-sectional area of the coil',
  'コイルの長さ': 'Length of the coil',
  'コンデンサの容量': 'Capacitance of the capacitor',
  'モル数': 'Number of moles',
  '一次コイルの巻数': 'Primary coil turns',
  '万有引力の比例定数': 'Gravitational proportionality constant',
  '中心天体の質量': 'Mass of the central body',
  '中心距離': 'Distance from the center',
  '二次コイルの巻数': 'Secondary coil turns',
  '交流回路の総抵抗': 'Total impedance of the AC circuit',
  '位置の変化': 'Change in position',
  '位置の時間変化': 'Time derivative of position',
  '体積': 'Volume',
  '円周率': 'Pi',
  '円運動の半径': 'Radius of circular motion',
  '光の振動数': 'Frequency of light',
  '光の伝播速度': 'Propagation speed of light',
  '光の波長': 'Wavelength of light',
  '光速': 'Speed of light',
  '力が働く時間': 'Time during which the force acts',
  '力が働く面積': 'Area on which the force acts',
  '力と距離のなす角': 'Angle between force and distance',
  '力と距離の積': 'Product of force and distance',
  '半径': 'Radius',
  '回転の角速度': 'Angular velocity of rotation',
  '回転半径': 'Radius of rotation',
  '単位時間あたりのエネルギー': 'Energy per unit time',
  '単位時間あたりの振動数': 'Oscillations per unit time',
  '単位質量あたりの熱容量': 'Heat capacity per unit mass',
  '単位長さあたりの質量': 'Mass per unit length',
  '単位面積あたりの力': 'Force per unit area',
  '単位面積あたりの電荷': 'Charge per unit area',
  '回転させる力': 'Force causing rotation',
  '回転の速さ': 'Rate of rotation',
  '回転周期': 'Rotation period',
  '回転軸からの距離': 'Distance from the rotation axis',
  '中心からの距離': 'Distance from the center',
  '圧力': 'Pressure',
  '深さ': 'Depth',
  '振り子の長さ': 'Length of the pendulum',
  '振動の振幅': 'Oscillation amplitude',
  '空気抵抗の比例定数': 'Proportionality constant for air resistance',
  '重力による加速度': 'Acceleration due to gravity',
  '物体の速度': 'Speed of the object',
  '電子の電荷の大きさ': 'Magnitude of the electron charge',
  'rとvのなす角': 'Angle between r and v',
  '地表付近で約9.8 m/s^2': 'About 9.8 m/s^2 near Earth surface',
  '基準面からの高さ': 'Height from the reference plane',
  '定圧比熱/定積比熱': 'Ratio of specific heats (Cp/Cv)',
  '定積過程のモル比熱': 'Molar heat capacity at constant volume',
  '導体の断面積': 'Conductor cross-sectional area',
  '導体の有効長': 'Effective length of the conductor',
  '導体の速度': 'Velocity of the conductor',
  '導体の長さ': 'Length of the conductor',
  '弦を張る力': 'Tension applied to the string',
  '抵抗': 'Resistance',
  '接線方向の速度': 'Tangential velocity',
  '接触面に垂直な力': 'Force perpendicular to the contact surface',
  '摩擦の比例定数': 'Proportional constant of friction',
  '時間': 'Time',
  '極板間距離': 'Distance between plates',
  '極板面積': 'Plate area',
  '気体定数': 'Gas constant',
  '波の1周期の長さ': 'Length of one wave period',
  '波の伝播速度': 'Wave propagation speed',
  '流体の密度': 'Fluid density',
  '熱力学的温度': 'Thermodynamic temperature',
  '物体に働く力': 'Force acting on the object',
  '物体の体積': 'Volume of the object',
  '物体の加速度': 'Acceleration of the object',
  '物体の運動量': 'Momentum of the object',
  '物体の質量': 'Mass of the object',
  '物体全体の熱容量': 'Total heat capacity of the object',
  '物質固有の抵抗': 'Material resistivity',
  '理想気体の定数': 'Ideal gas constant',
  '磁場が貫く量': 'Amount of magnetic field passing through',
  '磁場の定数': 'Magnetic constant',
  '磁場の密度': 'Density of the magnetic field',
  '磁場の強さ': 'Magnetic field strength',
  '磁束': 'Magnetic flux',
  '磁束が貫く面積': 'Area penetrated by magnetic flux',
  '磁束密度': 'Magnetic flux density',
  '磁気量': 'Magnetic quantity',
  '積分路の長さ': 'Length of the integration path',
  '空間の大きさ': 'Size of space',
  '経過時間': 'Elapsed time',
  '絶対温度': 'Absolute temperature',
  '角速度': 'Angular velocity',
  '誘電率': 'Permittivity',
  '質量': 'Mass',
  '起電力=−L di/dt の比例係数': 'Proportionality constant in emf = −L di/dt',
  '距離': 'Distance',
  '軸方向の速度': 'Axial velocity',
  '透磁率': 'Permeability',
  '速度': 'Speed',
  '速度と磁束密度のなす角': 'Angle between speed and magnetic flux density',
  '速度の時間変化': 'Time derivative of speed',
  '電位差': 'Electric potential difference',
  '電場の強さ': 'Electric field strength',
  '電束': 'Electric flux',
  '電束が貫く面積': 'Area penetrated by electric flux',
  '電極間距離など': 'Electrode separation distance',
  '電子の質量': 'Mass of electron',
  '軌道半径': 'Orbital radius',
  '電子の速度': 'Velocity of electron',
  '電気量': 'Electric charge',
  '電流': 'Electric current',
  '電流からの距離': 'Distance from the current',
  '電流の流れにくさ': 'Resistance to current flow',
  '電界': 'Electric field',
  '電界が貫く面積': 'Area penetrated by electric field',
  '電荷': 'Electric charge',
  '電荷の流れ': 'Flow of electric charge',
  '静止摩擦の比例定数': 'Proportional constant of static friction',
  '静電気力の定数': 'Constant of electrostatic force',
  'プランク定数': 'Planck constant',
  'リュードベリ定数の比例係数': 'Proportionality constant for the wavelength of light emitted from an atom',
  '面積': 'Area',
  '衝突の反発係数': 'Coefficient of restitution in collision',
  '熱機関の効率': 'Efficiency of heat engine',
  '内部エネルギーの変化': 'Change in internal energy',
  '電場が貫く面積': 'Area penetrated by electric field',
  '系に加えられた熱量': 'Heat added to the system',
  '系が外部にした仕事': 'Work done by the system on the surroundings',
};

/// 単位問題
class PhysicalFormula {
  final String? id; // 問題ID（UUIDなど、オプショナル）
  final String expr; // 計算対象の式（例: "m*g"）
  final String promptJa; // 出題文
  final List<SymbolDef> defs; // 記号の定義（必須）
  final UnitCategory category; // カテゴリー
  final bool isBaseUnitSystem; // 基本単位系かどうか
  final String?
  shortExplanation; // ワンフレーズ解説（例：「1/2mv^2は運動エネルギー。単位は1文字でJ(ジュール)だよ。」）
  final String? description; // 物理量の説明（例：「Mの磁極が磁場Hから受ける力」）
  final String? hint; // ヒント（オプショナル）
  final List<StepItem>? detailedExplanation; // 詳細解説（StepItemの配列、オプショナル）
  final List<UnitProblem>? answers; // 解答方法のリスト（解答文字列と電卓ボタン群のペア）

  const PhysicalFormula({
    this.id,
    required this.expr,
    required this.promptJa,
    required this.defs,
    this.category = UnitCategory.mechanics,
    this.isBaseUnitSystem = false,
    this.shortExplanation,
    this.description,
    this.hint,
    this.detailedExplanation,
    this.answers,
  });
}
